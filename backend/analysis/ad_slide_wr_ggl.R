###############################
#
# Sliding Win Rate by Game Length
#
###############################

devtools::load_all()
library(dplyr)
library(lubridate)
library(arrow)
library(parallel)
library(jsonlite)
library(fastglm)


# args <- get_args("p02_v02", "rm_solo_all")
args <- get_args()
data_location <- get_data_location(args)


matchmeta <- read_parquet(file.path(data_location, "matchmeta_broad.parquet"))
players <- read_parquet(file.path(data_location, "players_broad.parquet"))



get_slide_wr_gt_gamelength <- function(y) {
    results2 <- results %>%
        filter(match_length_igm >= y)

    data_wr_naive(results2) %>%
        mutate(y = y)
}


glen <- matchmeta$match_length_igm
lower_limit <- floor(min(glen) / 5) * 5
upper_limit <- ceiling(quantile(glen, 0.90) / 5) * 5

y <- seq(lower_limit, upper_limit, length.out = 40)


results <- prep_wr_naive(matchmeta, players)

cl <- get_cluster(2)
clusterExport(cl, c("results"))
clusterEvalQ(cl, {
    library(fastglm)
    library(dplyr)
})


res_list <- parallel::clusterMap(
    cl = cl,
    get_slide_wr_gt_gamelength,
    y = y
)

stopCluster(cl)


res <- bind_rows(res_list)


civlist <- res %>%
    arrange(civ) %>%
    pull(civ) %>%
    unique()


pdat <- map(civlist, get_slide_smoothed, res) %>%
    bind_rows() %>%
    select(civ, med, lci, uci, len = y)



arrow::write_parquet(
    x = pdat,
    sink = file.path(data_location, "ad_slide_WR_GGL.parquet")
)



results <- split(select(pdat, -civ), pdat$civ)

filepath <- file.path(
    get_output_location(args),
    "slide_WR_GGL.json"
)


sink(filepath)
toJSON(results, dataframe = "columns")
sink()
