

devtools::load_all()
library(dplyr)
library(assertthat)
library(lubridate)
library(arrow)



## determine which cohort we are building

data_location <- get_data_location(nofilter = TRUE)
data_location_flt <- get_data_location()
config <- get_config()


#########################
#
#  Prep Data
#
#


map_filter <- ifelse(
    config$filter$mapclass != "All",
    function(x) filter(x, map_class == config$filter$mapclass),
    identity
)

players_all <- read_parquet(file.path(data_location, "players.parquet"))
matchmeta_all <- read_parquet(file.path(data_location, "matchmeta.parquet"))


matchmeta_core <- matchmeta_all %>%
    filter(!is_mirror) %>%
    filter(start_dt >= ymd_hms(paste(config$period$lower, "00:00:01"))) %>%
    filter(start_dt <= ymd_hms(paste(config$period$upper, "23:59:59"))) %>%
    filter(leaderboard_name == config$filter$leaderboard) %>%
    filter(match_length_igm >= config$filter$length_limit_lower) %>%
    filter(match_length_igm <= config$filter$length_limit_upper) %>%
    map_filter()

matchmeta <- matchmeta_core %>%
    filter(rating_min >= config$filter$elo_limit_lower)

matchmeta_slice <- matchmeta_core %>%
    filter(rating_min >= config$filter$elo_limit_lower_slide)



if (config$filter$rm_single_pick) {

    matchmeta_gm <- matchmeta_all %>%
        filter(leaderboard_name == config$filter$leaderboard)

    players_to_remove <- players_all %>%
        semi_join(matchmeta_gm, by = "match_id") %>%
        group_by(profile_id, civ_name) %>%
        tally() %>%
        group_by(profile_id) %>%
        mutate(bign = sum(n)) %>%
        ungroup() %>%
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


players <- players_all %>% semi_join(matchmeta, by = "match_id")


write_parquet(
    players,
    file.path(data_location_flt, "players.parquet")
)

write_parquet(
    matchmeta,
    file.path(data_location_flt, "matchmeta.parquet")
)

write_parquet(
    matchmeta_slice,
    file.path(data_location_flt, "matchmeta_broad.parquet")
)

set_log(get_data_location(), "matchmeta_filter")
