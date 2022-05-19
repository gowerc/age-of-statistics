

devtools::load_all()
library(dplyr)
library(assertthat)
library(lubridate)
library(arrow)
library(dtplyr)
library(data.table)


## determine which cohort we are building
config <- get_config()

# config_all <- jsonlite::read_json("config.json")
# config <- list(
#     filter = config_all[["aoe2"]][["filters"]][["rm_solo_closed_pro"]],
#     period = config_all[["aoe2"]][["periods"]][["p03_v02"]],
#     game = "aoe2"
# )


#########################
#
#  Prep Data
#
#

matchmeta_all <- arrow::read_parquet(
    file.path("data", "processed", "aoe2", "matches.parquet")
)

players_all <- arrow::read_parquet(
    file.path("data", "processed", "aoe2", "players.parquet")
)


DATE_LIMIT_LOWER <- paste0(config$period$lower, " 00:00:01") %>%
    ymd_hms()


DATE_LIMIT_UPPER <- paste0(config$period$upper, " 23:59:59") %>%
    ymd_hms()


map_filter <- ifelse(
    config$filter$mapclass != "All",
    function(x) filter(x, map_class == config$filter$mapclass),
    identity
)

matchmeta_core <- matchmeta_all %>%
    filter(!is_mirror) %>%
    filter(start_dt >= DATE_LIMIT_LOWER) %>%
    filter(start_dt <= DATE_LIMIT_UPPER) %>%
    filter(leaderboard == config$filter$leaderboard) %>%
    filter(match_length_igm >= config$filter$length_limit_lower) %>%
    filter(match_length_igm <= config$filter$length_limit_upper) %>%
    map_filter()

matchmeta <- matchmeta_core %>%
    filter(rating_min >= config$filter$elo_limit_lower)

matchmeta_slice <- matchmeta_core %>%
    filter(rating_min >= config$filter$elo_limit_lower_slide)



if (config$filter$rm_single_pick) {

    matchmeta_gm <- matchmeta_all %>%
        filter(start_dt >= (DATE_LIMIT_LOWER - days(20))) %>%
        filter(start_dt <= DATE_LIMIT_UPPER) %>%
        filter(leaderboard == config$filter$leaderboard)

    players_to_remove <- players_all %>%
        semi_join(matchmeta_gm, by = "match_id") %>%
        as.data.table() %>%
        group_by(profile_id, civ) %>%
        tally() %>%
        as_tibble() %>%
        as.data.table() %>%
        group_by(profile_id) %>%
        mutate(bign = sum(n)) %>%
        ungroup() %>%
        as_tibble() %>%
        mutate(pcent = n / bign * 100) %>%
        filter(bign >= 10, pcent >= 40) %>%
        distinct(profile_id)

    matches_to_remove <- players_all %>%
        semi_join(players_to_remove, by = "profile_id") %>%
        distinct(match_id)

    matchmeta_slice <- matchmeta_slice %>%
        anti_join(matches_to_remove, by = "match_id")

    matchmeta <- matchmeta %>%
        anti_join(matches_to_remove, by = "match_id")
}


players <- players_all %>%
    semi_join(matchmeta, by = "match_id")

players_broad <- players_all %>%
    semi_join(matchmeta_slice, by = "match_id")



### Sample size sanity check
civ_count <- players %>%
    group_by(civ) %>%
    tally() %>%
    pull(n)

assert_that(
    all(civ_count > 30),
    msg = "At least one civ has less than 30 games"
)



write_parquet(
    players,
    file.path(get_data_location(), "players.parquet")
)

write_parquet(
    players_broad,
    file.path(get_data_location(), "players_broad.parquet")
)

write_parquet(
    matchmeta,
    file.path(get_data_location(), "matchmeta.parquet")
)

write_parquet(
    matchmeta_slice,
    file.path(get_data_location(), "matchmeta_broad.parquet")
)

set_log(get_data_location(), "matchmeta_filter")
