###############################
#
# Sliding Play Rate by Elo
#
###############################

devtools::load_all()
library(dplyr)
library(lubridate)
library(arrow)
library(jsonlite)


# data_location <- "./data/processed/aoe2/p03_v02/rm_solo_open"
# data_location <- "./data/processed/aoe2/p02_v02/ew_solo_any"
data_location <- get_data_location()


matchmeta <- read_parquet(
    file.path(data_location, "matchmeta_broad.parquet")
)

players <- read_parquet(
    file.path(data_location, "players_broad.parquet")
)




get_slide_pr_elo <- function(y, lb, ub, matchmeta, players) {
    matchmeta2 <- matchmeta %>%
        filter(rating_mean >= lb, rating_mean <= ub)

    data_pr(matchmeta2, players) %>%
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


res <- pmap_df(
    list(
        y = cuts$y,
        lb = cuts$lb,
        ub = cuts$ub
    ),
    get_slide_pr_elo,
    matchmeta = matchmeta,
    players = players
) %>%
    arrange(civ, y) %>%
    select(civ, pr, y)



arrow::write_parquet(
    x = res,
    sink = file.path(data_location, "ad_slide_PR_ELO.parquet")
)


results <- split(select(res, -civ), res$civ)

filepath <- file.path(
    get_output_location(),
    "slide_PR_ELO.json"
)


sink(filepath)
toJSON(results, dataframe = "columns")
sink()

