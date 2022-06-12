###############################
#
# Sliding Win Rate by ELO
#
###############################

devtools::load_all()
library(dplyr)
library(lubridate)
library(arrow)
library(parallel)
library(jsonlite)


# args <- get_args("p02_v02", "rm_solo_all")
args <- get_args()
data_location <- get_data_location(args)


matchmeta <- read_parquet(
    file.path(data_location, "matchmeta_broad.parquet")
)

players <- read_parquet(
    file.path(data_location, "players_broad.parquet")
)



get_slide_wr_elo <- function(y, lb, ub) {
    results2 <- results %>%
        filter(rating_mean >= lb, rating_mean <= ub)

    data_wr_naive(results2) %>%
        mutate(y = y) %>%
        mutate(limit_upper = ub, limit_lower = lb)
}



cuts <- tibble(
    cy = seq(0, 1, by = 0.01),
    clb = cy - 0.1,
    cub = cy + 0.1,
) %>%
    filter(clb >= 0, cub <= 1) %>%
    mutate(
        lb = quantile(matchmeta$rating_mean, clb),
        y = quantile(matchmeta$rating_mean, cy),
        ub = quantile(matchmeta$rating_mean, cub)
    )


results <- prep_wr_naive(matchmeta, players)

cl <- get_cluster(2)
clusterExport(cl, c("results"))
clusterEvalQ(cl, {
    library(fastglm)
    library(dplyr)
})

res_list <- parallel::clusterMap(
    cl = cl,
    get_slide_wr_elo,
    y = cuts$y,
    lb = cuts$lb,
    ub = cuts$ub
)

stopCluster(cl)
res <- bind_rows(res_list)


civlist <- res %>%
    arrange(civ) %>%
    pull(civ) %>%
    unique()


pdat <- map_df(civlist, get_slide_smoothed, res) %>%
    select(civ, med, lci, uci, elo = y)



arrow::write_parquet(
    x = pdat,
    sink = file.path(data_location, "ad_slide_WR_ELO.parquet")
)



results <- split(
    select(pdat, -civ) %>% as.data.frame(),
    pdat$civ
)

filepath <- file.path(
    get_output_location(args),
    "slide_WR_ELO.json"
)


sink(filepath)
toJSON(results, dataframe = "columns")
sink()
