
pkgload::load_all()
library(dplyr)
library(dbplyr)
library(tidyr)
library(lubridate)
library(data.table)
library(dtplyr)


con <- get_connection()


meta <- get_strings()


boards <- c(
    "1v1 Random Map",
    "Team Random Map",
    "1v1 Empire Wars"
)



civ_ids <- meta %>%
    filter(type == "civ") %>%
    select(civ = id, civ_string = string)


map_ids <- meta %>%
    filter(type == "map_type")  %>%
    select(map_type = id, map = string)


board_ids <- meta %>%
    filter(type == "leaderboard") %>%
    filter(string %in% boards) %>%
    select(leaderboard_id = id, leaderboard = string)


matches_slim <- tbl(con, "match_meta") %>%
    filter(leaderboard_id %in% local(board_ids$leaderboard_id)) %>%
    filter(!is.na(version)) %>%
    filter(map_type %in% local(map_ids$map_type)) %>%
    filter(!(is.na(started) | is.na(finished))) %>%
    filter(finished - started < (180 * 60)) %>%
    select(match_id, started, version, leaderboard_id, finished, map_type)



players_slim <- tbl(con, "match_players") %>%
    semi_join(matches_slim, by = "match_id") %>%
    filter(!is.na(profile_id)) %>%
    filter(!is.na(rating)) %>%
    filter(!is.na(won)) %>%
    filter(!is.na(slot)) %>%
    filter(civ %in% local(civ_ids$civ)) %>%
    filter(team %in% c(1, 2), !is.na(team)) %>%
    select(match_id, rating, civ, won, slot, profile_id, team)


players <- players_slim %>%
    collect()


matches <- matches_slim %>%
    semi_join(players_slim, by = "match_id") %>%
    collect()




### Check that all maps have been classified
matches_maps <- matches %>%
    inner_join(map_ids, by = "map_type") %>%
    select(-map_type)


mapclass <- get_map_class()
u_mapname <- unique(matches_maps$map)
no_class <- u_mapname[!u_mapname %in% mapclass$map_name]
assert_that(
    length(no_class) == 0,
    msg = sprintf(
        "The following maps do not have a classification:\n%s",
        paste0(no_class, collapse = "\n")
    )
)


## calculate n players per team and make sure each team has the same number of players
keep_valid_teams <- players %>%
    as.data.table() %>%
    group_by(match_id, team) %>%
    tally() %>%
    as_tibble() %>%
    mutate(team = paste0("team_", team)) %>%
    spread(team, n) %>%
    filter(!is.na(team_1), !is.na(team_2)) %>%
    filter(team_1 == team_2) %>%
    ungroup()




# Check that we have agreement on which team actually won
# within team n unique = 1
# across teams n unique = 2

assert_that(
    !any(is.na(players$won)),
    msg = "Assumption that no 'won' is missing is FALSE"
)

n_unique_won_match <- players %>%
    semi_join(keep_valid_teams, by = "match_id") %>%
    as.data.table() %>%
    group_by(match_id) %>%
    summarise(n_unique_match = length(unique(won)), .groups = "drop") %>%
    as_tibble()

n_unique_won_team <- players %>%
    semi_join(keep_valid_teams, by = "match_id") %>%
    as.data.table() %>%
    group_by(match_id, team) %>%
    summarise(n_unique_match = length(unique(won)), .groups = "drop") %>%
    as_tibble()

keep_correct_won_within <- n_unique_won_team %>%
    mutate(team = paste0("team_", team)) %>%
    spread(team, n_unique_match) %>% 
    filter( team_1==1, team_2 == 1) %>% 
    select(match_id)

keep_correct_won_between <- n_unique_won_match %>% 
    filter(n_unique_match == 2) %>%
    select(match_id)




ad_matches <- matches_maps %>%
    inner_join(mapclass, by = c("map" = "map_name")) %>%
    mutate(start_dt = ymd("1970-01-01") + seconds(started)) %>%
    mutate(stop_dt = ymd("1970-01-01") + seconds(finished)) %>%
    mutate(match_length = as.numeric(difftime(stop_dt, start_dt, units = "mins"))) %>%
    mutate(match_length_igm = match_length * 1.7) %>%
    select(-started, -finished) %>%
    inner_join(board_ids, by = "leaderboard_id") %>%
    select(-leaderboard_id) %>%
    semi_join(keep_valid_teams, by = "match_id") %>%
    semi_join(keep_correct_won_within, by = "match_id") %>% 
    semi_join(keep_correct_won_between, by = "match_id")



ad_players <- players %>%
    inner_join(civ_ids, by = "civ") %>%
    select(-civ, civ = civ_string) %>%
    semi_join(keep_valid_teams, by = "match_id") %>%
    semi_join(keep_correct_won_within, by = "match_id") %>% 
    semi_join(keep_correct_won_between, by = "match_id")



team_meta <- ad_players %>%
    as.data.table() %>%
    group_by(match_id) %>%
    summarise(
        n_players = n(),
        rating_min = min(rating),
        rating_max = max(rating),
        rating_mean = mean(rating),
        rating_diff_mean = mean(rating[team == 1]) - mean(rating[team == 2]),
        winning_team = unique(team[won]),
        n_unique_civ = length(unique(civ)),
        .groups = "drop"
    ) %>%
    as_tibble() %>%
    mutate(n_players_team = n_players / 2)



n_players_df <- ad_players %>%
    as.data.table() %>%
    group_by(match_id) %>%
    summarise(n_players2 = max(slot)) %>%
    as_tibble()


# Check that the slot numbers (theoretical players) is equal to the number of actual players
keep_consistant_nplayers <- team_meta %>%
    left_join(n_players_df, by = "match_id") %>%
    filter(n_players == n_players2)



LEADERBOARDS_1v1 <- c("1v1 Random Map", "1v1 Empire Wars")

ad_matches2 <- ad_matches %>%
    semi_join(keep_consistant_nplayers, by = "match_id") %>%
    inner_join(team_meta, by = "match_id") %>%
    mutate(is_mirror = leaderboard %in% LEADERBOARDS_1v1 & n_unique_civ != 2)


ad_players2 <- ad_players %>%
    semi_join(ad_matches2, by = "match_id")





############################################
#
# Rolling civ play rate
#
#   Calculate the max % of times played with a single civ per player
#   over their last 40 games
#   All matches under 20 games are given a 0%
#   Anything that isn't a 1v1 is given a 0%
#

civs_unique <- sort(unique(ad_players2$civ))


civ_percent_rolling <- function(civs, civs_unique) {
    res <- vector(mode = "numeric", length = length(civs))
    hold <- vector(mode = "numeric", length = length(civs_unique))
    for (i in seq_along(civs)) {
        ind <- civs[[i]]
        hold[ind] <- hold[ind] + 1
        if (i > 40) {
            ind_rem <- civs[[i - 40]]
            hold[ind_rem] <- hold[ind_rem] - 1
        }
        if (i >= 20) {
            res[[i]] <- max(hold) / sum(hold)
        }
    }
    return(res)
}

assert_that(
    civ_percent_rolling(c(rep(1, 40), rep(2, 20)), civs_unique)[60] == 0.5
)


matches_1v1 <- ad_matches2 %>%
    filter(leaderboard %in% LEADERBOARDS_1v1) %>%
    select(match_id, leaderboard, start_dt)


players_1v1 <- ad_players2 %>%
    inner_join(matches_1v1, by = "match_id") %>%
    select(profile_id, leaderboard, civ, start_dt, match_id) %>%
    arrange(leaderboard, profile_id, start_dt) %>%
    mutate(civ_ind = as.numeric(factor(civ, levels = civs_unique)))


players_roll <- players_1v1 %>%
    as.data.table() %>%
    group_by(profile_id, leaderboard) %>%
    mutate(max_civ_pr = civ_percent_rolling(civ_ind, civs_unique)) %>%
    as_tibble()


players_roll_slim <- players_roll %>%
    select(profile_id, match_id, max_civ_pr)


ad_players3 <- ad_players2 %>%
    left_join(players_roll_slim, by = c("profile_id", "match_id")) %>%
    mutate(max_civ_pr = replace_na(max_civ_pr, 0))




############################################
#
# Basic Data integrety checks
#
#
#


extra_matches_1 <- ad_matches2 %>%
    anti_join(ad_players3, by = "match_id") %>%
    nrow()


extra_matches_2 <- ad_players3 %>%
    anti_join(ad_matches2, by = "match_id") %>%
    nrow()


is.team <- function(x) {
    is.numeric(x) & all(x %in% c(1, 2))
}


meta_players <- list(
    "match_id" = is.character,
    "rating" = is.numeric,
    "civ" = is.character,
    "slot" = is.numeric,
    "won" = is.logical,
    "profile_id" = is.numeric,
    "team" = is.team,
    "max_civ_pr" = is.numeric
)


meta_matches <- list(
    "match_id" = is.character,
    "version" = is.character,
    "map_class" = is.character,
    "start_dt" = is.POSIXct,
    "stop_dt" = is.POSIXct,
    "match_length" = is.numeric,
    "match_length_igm" = is.numeric,
    "leaderboard" = is.character,
    "map" = is.character,
    "n_players" = is.numeric,
    "n_players_team" = is.numeric,
    "rating_min" = is.numeric,
    "rating_max" = is.numeric,
    "rating_mean" = is.numeric,
    "rating_diff_mean" = is.numeric,
    "winning_team" = is.numeric,
    "n_unique_civ" = is.numeric,
    "is_mirror" = is.logical
)



is_non_missing_type <- function(x, tp) {
    all(!is.na(x)) & tp(x)
}


assert_that(
    extra_matches_1 == 0,
    extra_matches_2 == 0,
    all(names(ad_players3) %in% names(meta_players)),
    all(names(meta_players) %in% names(ad_players3)),
    all(names(ad_matches2) %in% names(meta_matches)),
    all(names(meta_matches) %in% names(ad_matches2))
)

for (var in names(meta_players)) {
    assert_that(
        is_non_missing_type(
            ad_players3[[var]],
            meta_players[[var]]
        ),
        msg = sprintf("Variable `%s` failed validation", var)
    )
}


for (var in names(meta_matches)) {
    assert_that(
        is_non_missing_type(
            ad_matches2[[var]],
            meta_matches[[var]]
        ),
        msg = sprintf("Variable `%s` failed validation", var)
    )
}


############################################
#
# Save Data
#
#
#


dir.create(
    path = file.path("data", "processed"),
    recursive = TRUE,
    showWarnings = FALSE
)


arrow::write_parquet(
    x = ad_matches2,
    sink = file.path("data", "processed", "matches.parquet")
)


arrow::write_parquet(
    x = ad_players3,
    sink = file.path("data", "processed", "players.parquet")
)


set_log(file.path("data", "processed"), "matchmeta")



