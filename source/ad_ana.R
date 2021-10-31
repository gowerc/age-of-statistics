pkgload::load_all()
library(dplyr)
library(dbplyr)
library(DBI)
library(tidyr)
library(stringr)
library(assertthat)
library(lubridate)
library(forcats)


con <- get_connection()


meta <- get_patchmeta()


meta_civ <- meta %>%
    filter(type == "civ") %>%
    select(civ = id, civ_name = string)


meta_map <- meta %>%
    filter(type == "map_type") %>%
    select(map_type = id, map_name = string)


meta_board <- meta %>%
    filter(type == "leaderboard") %>%
    select(leaderboard_id = id, leaderboard_name = string)


keep_matches <- tbl(con, "match_meta") %>%
    filter(leaderboard_id %in% c(3, 4, 13, 14), ranked) %>%
    select(match_id, map_type, version, started, leaderboard_id, finished)


dat <- tbl(con, "match_players") %>%
    filter(team %in% c(1, 2)) %>%
    inner_join(keep_matches, by = "match_id") %>%
    select(
        match_id, rating, civ, won, slot, profile_id, started, team,
        map_type, leaderboard_id, version, finished, profile_id, name
    ) %>%
    collect() %>%
    mutate(start_dt = ymd("1970-01-01") + seconds(started)) %>%
    mutate(stop_dt = ymd("1970-01-01") + seconds(finished)) %>%
    mutate(match_length = as.numeric(difftime(stop_dt, start_dt, units = "mins"))) %>%
    mutate(match_length_igm =  match_length * 1.7) %>%
    select(-started, - finished)


valid_player_counts <- dat %>%
    group_by(match_id, team) %>%
    tally() %>%
    mutate(team = paste0("team_", team)) %>%
    spread(team, n) %>%
    ungroup() %>%
    filter(!is.na(team_1), !is.na(team_2), team_1 == team_2) %>%
    distinct(match_id)


valid_rating <- dat %>%
    group_by(match_id) %>%
    summarise(n_na = sum(is.na(rating))) %>%
    filter(n_na == 0) %>%
    distinct(match_id)


valid_maptype <- dat %>%
    filter(!is.na(map_type)) %>%
    distinct(match_id)


valid_winner <- dat %>%
    group_by(match_id, team) %>%
    summarise(
        n = n(),
        n_na = sum(is.na(won)),
        u_res = length(unique(won)),
        .groups = "drop"
    ) %>%
    filter(u_res == 1, n_na == 0) %>%
    distinct(match_id)


invalid_version <- dat %>%
    filter(is.na(version)) %>%
    distinct(match_id)


dat2 <- dat %>%
    semi_join(valid_player_counts, by = "match_id") %>%
    semi_join(valid_rating, by = "match_id") %>%
    semi_join(valid_maptype, by = "match_id") %>%
    semi_join(valid_winner, by = "match_id") %>%
    anti_join(invalid_version, by = "match_id")


dat3 <- dat2 %>%
    left_join(meta_civ, by = "civ") %>%
    left_join(meta_map, by = "map_type") %>%
    left_join(meta_board, by = "leaderboard_id") %>%
    mutate(version = if_else(is.na(version), "Unknown", version))



assert_that(
    nrow(dat2) == nrow(dat3),
    all(!is.na(dat3$civ)),
    all(!is.na(dat3$map_type)),
    all(!is.na(dat3$leaderboard_id)),
    all(!is.na(dat3$map_name))
)


mapclass <- get_map_class()
u_mapname <- unique(dat3$map_name)
no_class <- u_mapname[!u_mapname %in% mapclass$map_name]
assert_that(
    length(no_class) == 0,
    msg = sprintf(
        "The following maps do not have a classification:\n%s",
        paste0(no_class, collapse = "\n")
    )
)



player_meta <- dat3 %>%
    group_by(match_id) %>%
    summarise(
        n_players = n(),
        n_players_team = n_players / 2,
        rating_min = min(rating),
        rating_max = max(rating),
        rating_mean = mean(rating),
        rating_diff_mean = mean(rating[team == 1]) - mean(rating[team == 2]),
        .groups = "drop"
    )


matchmeta_check <- dat3 %>%
    distinct(
        match_id, won, map_name, leaderboard_name, version, start_dt,
        stop_dt, match_length, match_length_igm
    )



matchmeta <- dat3 %>%
    filter(won) %>%
    distinct(
        match_id, team, map_name, leaderboard_name, version, start_dt,
        match_length, match_length_igm, stop_dt
    ) %>%
    rename(winning_team = team) %>%
    inner_join(player_meta, "match_id") %>%
    left_join(mapclass, by = "map_name") %>%
    filter(n_players %in% c(2, 4, 6, 8))


assert_that(
    nrow(matchmeta_check) == nrow(matchmeta) * 2
)


players <- dat3 %>%
    select(match_id, civ_name, rating, team, profile_id, name)



saveRDS(
    object = matchmeta,
    file = "./data/ad_matchmeta.Rds"
)

saveRDS(
    object = players,
    file = "./data/ad_players.Rds"
)




