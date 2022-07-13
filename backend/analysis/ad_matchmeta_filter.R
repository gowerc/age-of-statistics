
devtools::load_all()
library(dplyr)
library(assertthat)
library(lubridate)
library(arrow)
library(glue)


# args <- get_args("p03_v06", "rm_solo_open_avg")
args <- get_args()

config <- get_config(args)



#########################
#
#  Prep Data
#
#

matchmeta_all <- arrow::read_parquet(
    file.path("data", "processed", "matches.parquet")
)

players_all <- arrow::read_parquet(
    file.path("data", "processed", "players.parquet")
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


remove_civ_pickers <- players_all %>%
    semi_join(matchmeta_core, by = "match_id") %>%
    filter(max_civ_pr >= 0.70) %>%
    distinct(match_id)


matchmeta_with_pick <- matchmeta_core %>%
    filter(rating_min >= config$filter$elo_limit_lower) %>%
    filter(rating_max <= config$filter$elo_limit_upper)


matchmeta_slice_with_pick <- matchmeta_core %>%
    filter(rating_min >= config$filter$elo_limit_lower_slide)


matchmeta <- matchmeta_with_pick %>%
    anti_join(remove_civ_pickers, by = "match_id")

matchmeta_slice <- matchmeta_slice_with_pick %>%
    anti_join(remove_civ_pickers, by = "match_id")



nbefore <- nrow(matchmeta_with_pick)
nafter <-  nrow(matchmeta)
ndiff <- nbefore - nafter

glue(
    "I have removed {n1} matches out of {n2} ({n3}%)",
    n1 = ndiff,
    n2 = nbefore,
    n3 = round((1 - (nafter / nbefore)) * 100)
)




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
    file.path(get_data_location(args), "players.parquet")
)

write_parquet(
    players_broad,
    file.path(get_data_location(args), "players_broad.parquet")
)

write_parquet(
    matchmeta,
    file.path(get_data_location(args), "matchmeta.parquet")
)

write_parquet(
    matchmeta_slice,
    file.path(get_data_location(args), "matchmeta_broad.parquet")
)

set_log(get_data_location(args), "matchmeta_filter")
