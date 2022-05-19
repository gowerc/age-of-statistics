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


# data_location <- "./data/processed/aoe2/p03_v02/rm_solo_open"
# data_location <- "./data/processed/aoe2/p02_v02/ew_solo_any"
data_location <- get_data_location()


matchmeta <- read_parquet(file.path(data_location, "matchmeta_broad.parquet"))
players <- read_parquet(file.path(data_location, "players_broad.parquet"))



get_slide_wr_gamelength <- function(y, lb, ub) {
    matchmeta2 <- matchmeta %>%
        filter(match_length_igm >= lb, match_length_igm <= ub)

    data_wr_naive(matchmeta2, players) %>%
        mutate(y = y) %>%
        mutate(limit_upper = ub, limit_lower = lb)
}


glen <- matchmeta$match_length_igm
lower_limit <- floor(quantile(glen, 0.1) / 5) * 5
upper_limit <- ceiling(quantile(glen, 0.85) / 5) * 5

y <- seq(lower_limit, upper_limit, by = 1)


cl <- get_cluster(2)
clusterExport(cl, c("matchmeta", "players"))

res_list <- parallel::clusterMap(
    cl = cl,
    get_slide_wr_gamelength,
    y = y,
    lb = y - 5,
    ub = y + 5
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
    sink = file.path(data_location, "ad_slide_WR_GL.parquet")
)



results <- split(select(pdat, -civ), pdat$civ)

filepath <- file.path(
    get_output_location(),
    "slide_WR_GL.json"
)


sink(filepath)
toJSON(results, dataframe = "columns")
sink()
