pkgload::load_all()
library(dplyr)
library(dbplyr)
library(DBI)
library(tidyr)
library(stringr)
library(assertthat)
library(lubridate)
library(forcats)
library(glue)


## determine which cohort we are building


config <- get_config()
config_all <- get_config_all()


DATE_LIMIT_LOWER <- paste0(config$period$lower, " 00:00:01") %>%
    ymd_hms() %>%
    `-`(days(20)) %>%
    as.numeric()

DATE_LIMIT_UPPER <- paste0(config$period$upper, " 23:59:59") %>%
    ymd_hms() %>%
    as.numeric()


con <- get_connection()


meta <- get_patchmeta()


LEADERBOARDS <- vapply(
    config_all[[config$game]]$filters,
    function(x) x$leaderboard,
    character(1),
    USE.NAMES = FALSE
) %>%
    unique()


LEADERBOARDS_1v1 <- grep("^1v1", LEADERBOARDS, value = TRUE)


meta_civ <- meta %>%
    filter(type == "civ") %>%
    select(civ = id, civ_name = string)


meta_map <- meta %>%
    filter(type == "map_type") %>%
    select(map_type = id, map_name = string)


meta_board <- meta %>%
    filter(type == "leaderboard") %>%
    select(leaderboard_id = id, leaderboard_name = string) %>%
    filter(leaderboard_name %in% LEADERBOARDS)


matches_time_limit <- tbl(con, "match_meta") %>%
    filter(started >= DATE_LIMIT_LOWER, started <= DATE_LIMIT_UPPER) %>%
    filter(leaderboard_id %in% local(meta_board$leaderboard_id)) %>%
    select(match_id)


matches_all <- tbl(con, "match_meta") %>%
    select(match_id, started, version, leaderboard_id, finished, map_type, ranked) %>%
    inner_join(matches_time_limit, by = "match_id") %>%
    collect()


players_all <- tbl(con, "match_players") %>%
    select(match_id, rating, civ, won, slot, profile_id, team, name) %>%
    inner_join(matches_time_limit, by = "match_id") %>%
    collect()


remove_wrong_leaderboard <- matches_all %>%
    filter(!(leaderboard_id %in% meta_board$leaderboard_id & ranked)) %>%
    distinct(match_id)


remove_no_player_id <- players_all %>%
    filter(profile_id < 0) %>%
    distinct(match_id)


remove_no_elo <- players_all %>%
    select(match_id, rating) %>%
    filter(is.na(rating)) %>%
    distinct(match_id)


remove_no_result <- players_all %>%
    select(match_id, won) %>%
    filter(is.na(won)) %>%
    distinct(match_id)


remove_invalid_teams <- players_all %>%
    filter(!team %in% c(1, 2)) %>%
    distinct(match_id)


remove_unknown_times <- matches_all %>%
    filter(is.na(started) | is.na(finished)) %>%
    distinct(match_id)


remove_unknown_maps <- matches_all %>%
    filter(is.na(map_type)) %>%
    distinct(match_id)


remove_unknown_version <- matches_all %>%
    filter(is.na(version)) %>%
    distinct(match_id)


remove_me <- bind_rows(
    remove_wrong_leaderboard,
    remove_no_player_id,
    remove_no_elo,
    remove_no_result,
    remove_invalid_teams,
    remove_unknown_times,
    remove_unknown_maps,
    remove_unknown_version
) %>% 
    distinct(match_id)



valid_matches <- matches_all %>%
    arrange(match_id) %>%
    anti_join(remove_me, by = "match_id") %>%
    mutate(start_dt = ymd("1970-01-01") + seconds(started)) %>%
    mutate(stop_dt = ymd("1970-01-01") + seconds(finished)) %>%
    mutate(match_length = as.numeric(difftime(stop_dt, start_dt, units = "mins"))) %>%
    mutate(match_length_igm =  match_length * 1.7) %>%
    select(-started, - finished) %>%
    left_join(meta_map, by = "map_type") %>%
    left_join(meta_board, by = "leaderboard_id")


valid_players <- players_all %>%
    arrange(match_id, slot) %>%
    anti_join(remove_me, by = "match_id") %>%
    left_join(meta_civ, by = "civ")




invalid_player_counts <- valid_players %>%
    group_by(match_id, team) %>%
    tally() %>%
    mutate(team = paste0("team_", team)) %>%
    spread(team, n) %>%
    ungroup() %>%
    filter(is.na(team_1) | is.na(team_2) | team_1 != team_2) %>%
    distinct(match_id)


invalid_ratings <- valid_players %>%
    group_by(match_id) %>%
    summarise(n_na = sum(is.na(rating))) %>%
    filter(n_na != 0) %>%
    distinct(match_id)


invalid_winner <- valid_players %>%
    group_by(match_id, team) %>%
    summarise(
        n = n(),
        n_na = sum(is.na(won)),
        u_res = length(unique(won)),
        .groups = "drop"
    ) %>%
    filter(u_res != 1 | n_na != 0) %>%
    distinct(match_id)



remove_me2 <- bind_rows(
    invalid_player_counts,
    invalid_ratings,
    invalid_winner
) %>%
    distinct(match_id)


valid_matches2 <- valid_matches %>%
    anti_join(remove_me2, by = "match_id")


valid_players2 <- valid_players %>%
    anti_join(remove_me2, by = "match_id")



assert_that(
    all(!is.na(valid_players2$civ)),
    all(!is.na(valid_matches2$map_type)),
    all(!is.na(valid_matches2$leaderboard_id)),
    all(!is.na(valid_matches2$map_name))
)


mapclass <- get_map_class(config$game)
u_mapname <- unique(valid_matches2$map_name)
no_class <- u_mapname[!u_mapname %in% mapclass$map_name]
assert_that(
    length(no_class) == 0,
    msg = sprintf(
        "The following maps do not have a classification:\n%s",
        paste0(no_class, collapse = "\n")
    )
)


team_meta <- valid_players2 %>%
    group_by(match_id) %>%
    summarise(
        n_players = n(),
        n_players_team = n_players / 2,
        rating_min = min(rating),
        rating_max = max(rating),
        rating_mean = mean(rating),
        rating_diff_mean = mean(rating[team == 1]) - mean(rating[team == 2]),
        winning_team = unique(team[won]),
        n_unique_civ = length(unique(civ)),
        .groups = "drop"
    )


matchmeta <- valid_matches2 %>%
    inner_join(team_meta, by = "match_id") %>%
    left_join(mapclass, by = "map_name") %>%
    mutate(is_mirror = leaderboard_name %in% LEADERBOARDS_1v1 & n_unique_civ != 2)


players <- valid_players2 %>%
    semi_join(matchmeta, by = "match_id")


assert_that(
    all(team_meta$n_players %in% c(2, 4, 6, 8)),
    all(players$match_id %in% matchmeta$match_id),
    all(matchmeta$match_id %in% players$match_id),
    all(matchmeta$winning_team %in% c(1, 2)),
    all(!is.na(matchmeta$n_players)),
    all(!is.na(matchmeta$rating_mean)),
    all(!is.na(matchmeta$rating_max)),
    all(!is.na(matchmeta$rating_diff_mean)),
    all(!is.na(matchmeta$map_class)),
    all(!is.na(players$civ)),
    all(!is.na(players$civ_name)),
    all(!is.na(players$won)),
    all(!is.na(players$rating)),
    all(!is.na(matchmeta$is_mirror))
)


data_location <- get_data_location(nofilter = TRUE)

arrow::write_parquet(
    x = matchmeta,
    sink = file.path(data_location, "matchmeta.parquet")
)

arrow::write_parquet(
    x = players,
    sink = file.path(data_location, "players.parquet")
)

set_log(data_location, "matchmeta")