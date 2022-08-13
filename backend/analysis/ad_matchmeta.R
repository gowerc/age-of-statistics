
pkgload::load_all()
library(dplyr)
library(tidyr)
library(lubridate)
library(data.table)
library(dtplyr)
library(logger)
library(arrow)


log_n_removed_df <- function(dset, df, msg, keep=TRUE) {
    ndset <- length(unique(dset$match_id))
    ndf <- length(unique(df$match_id))
    if (keep) {
        nrm <- ndset - ndf
    } else {
        nrm <- ndf
    }
    log_n_removed(ndset, nrm, msg)
}


log_n_removed <- function(n1, n2, msg) {
    m <- sprintf(
        "Removing %s (%s%%) matches due to %s\n",
        n2,
        round((n2 / n1) * 1000) / 10,
        msg
    )
    log_info(m)
}


meta <- get_strings()


boards <- c(
    "1v1 Random Map",
    "Team Random Map",
    "1v1 Empire Wars"
)

log_info('Reading Metadata')

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



###################################
#
# Matches
#
#

log_info('Reading Matches from filesystem')


match_files <- list.files(
    path = "./data/source/matches",
    pattern = "*.parquet",
    full.names = TRUE
)


matches_slim_all <- open_dataset(match_files) |>
    filter(leaderboard_id %in% local(board_ids$leaderboard_id)) |>
    select(match_id, started, match_uuid, version, leaderboard_id, finished, map_type)

keep_all <- matches_slim_all |> nrow()
drop_valid_version <- matches_slim_all |> filter(is.na(version)) |> nrow()
drop_valid_maps <- matches_slim_all |> filter(!map_type %in% local(map_ids$map_type)) |> nrow()
drop_valid_start_stop <- matches_slim_all |> filter((is.na(started) | is.na(finished))) |> nrow()
drop_valid_game_length <- matches_slim_all |> filter(finished - started >= (180 * 60)) |> nrow()


log_n_removed(keep_all, drop_valid_version, "invalid version")
log_n_removed(keep_all, drop_valid_maps, "invalid maps")
log_n_removed(keep_all, drop_valid_start_stop, "invalid start/stop time")
log_n_removed(keep_all, drop_valid_game_length, "invalid game length")

matches_slim <- matches_slim_all |>
    filter(!is.na(version)) |>
    filter(map_type %in% local(map_ids$map_type)) |>
    filter(!(is.na(started) | is.na(finished))) |>
    filter(finished - started < (180 * 60)) |>
    arrange(started) |>
    collect()



###################################
#
# Players
#
#

log_info('Reading Players from filesystem')

player_files <- list.files(
    path = "./data/source/players",
    pattern = "*.parquet",
    full.names = TRUE
)

players_slim_all <- open_dataset(player_files) |>
    select(match_id, rating, civ, won, slot, profile_id, team, color) |>
    filter(match_id %in% local(matches_slim$match_id)) |>
    mutate(
        cond1 = is.na(profile_id),
        cond2 = is.na(rating),
        cond3 = is.na(won),
        cond4 = is.na(slot),
        cond5 = !civ %in% local(civ_ids$civ),
        cond6 = !team %in% c(1, 2) | is.na(team)
    )


keep_all <- players_slim_all |> nrow()
drop_valid_profile <- players_slim_all |> filter(cond1) |> nrow()
drop_valid_rating <- players_slim_all |> filter(cond2) |> nrow()
drop_valid_won <- players_slim_all |> filter(cond3) |> nrow()
drop_valid_slot <- players_slim_all |> filter(cond4) |> nrow()
drop_valid_civ <- players_slim_all |> filter(cond5) |> nrow()
drop_valid_team <- players_slim_all |> filter(cond6) |> nrow()

log_n_removed(keep_all, drop_valid_profile, "invalid profile")
log_n_removed(keep_all, drop_valid_rating, "invalid rating")
log_n_removed(keep_all, drop_valid_won, "invalid won")
log_n_removed(keep_all, drop_valid_slot, "invalid slot")
log_n_removed(keep_all, drop_valid_civ, "invalid civ")
log_n_removed(keep_all, drop_valid_team, "invalid team")


players_slim <- players_slim_all |>
    filter(!cond1, !cond2, !cond3, !cond4, !cond5, !cond6) |>
    select(-cond1, -cond2, -cond3, -cond4, -cond5, -cond6) |>
    collect()



###################################
#
# Combining
#
#


players <- players_slim |>
    semi_join(matches_slim, by = "match_id") |>
    distinct()


matches <- matches_slim %>%
    semi_join(players_slim, by = "match_id") |>
    distinct()


log_info('Starting Map classification and valid teams')



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


log_n_removed_df(matches, keep_valid_teams, msg = "unequal team numbers")


# players |>
#     anti_join(keep_valid_teams, by = "match_id") |>
#     arrange(match_id, profile_id) |>
#     print(n = 50)


# Check that we have agreement on which team actually won
# within team n unique = 1
# across teams n unique = 2

assert_that(
    !any(is.na(players$won)),
    msg = "Assumption that no 'won' is missing is FALSE"
)

n_unique_won_match <- players %>%
    as.data.table() %>%
    group_by(match_id) %>%
    summarise(n_unique_match = length(unique(won)), .groups = "drop") %>%
    as_tibble()

n_unique_won_team <- players %>%
    as.data.table() %>%
    group_by(match_id, team) %>%
    summarise(n_unique_match = length(unique(won)), .groups = "drop") %>%
    as_tibble()

keep_correct_won_within <- n_unique_won_team %>%
    mutate(team = paste0("team_", team)) %>%
    spread(team, n_unique_match) %>%
    filter(team_1 == 1, team_2 == 1) %>%
    select(match_id)

keep_correct_won_between <- n_unique_won_match %>%
    filter(n_unique_match == 2) %>%
    select(match_id)

log_n_removed_df(
    matches, keep_correct_won_within,
    msg = "inconsistent result within team"
)
log_n_removed_df(
    matches, keep_correct_won_between,
    msg = "inconsistent result between teams"
)


keep_correct_colors <- players %>%
    select(match_id, color) %>%
    data.table() %>%
    filter(!is.na(color)) %>%
    mutate(unknown_color = !color %in% c(1:8)) |>
    group_by(match_id) %>%
    summarise(
        n_color = length(color),
        n_color_unique = length(unique(color)),
        unknown_color = any(unknown_color),
        .groups = "drop"
    ) %>%
    filter(n_color == n_color_unique) %>%
    filter(!unknown_color) %>%
    as_tibble()

log_n_removed_df(
    matches, keep_correct_colors,
    msg = "invalid colours"
)


log_info("Starting ad_matches / ad_players")

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
    semi_join(keep_correct_won_between, by = "match_id") %>%
    semi_join(keep_correct_colors, by = "match_id")


log_n_removed_df(
    matches, ad_matches,
    msg = "Not meeting the above keep requirements"
)


ad_players <- players %>%
    inner_join(civ_ids, by = "civ") %>%
    select(-civ, civ = civ_string) %>%
    semi_join(keep_valid_teams, by = "match_id") %>%
    semi_join(keep_correct_won_within, by = "match_id") %>%
    semi_join(keep_correct_won_between, by = "match_id") %>%
    semi_join(keep_correct_colors, by = "match_id")




########################
#
# Fix Elo for update
#

log_info("Fixing Elo")

remove_elo_change <- ad_matches %>%
    select(match_id, leaderboard, start_dt) %>%
    filter(leaderboard == "Team Random Map") %>%
    filter(start_dt >= ymd_hms("2022-07-12 23:00:00")) %>%
    filter(start_dt <= ymd_hms("2022-07-16 23:59:00"))

adjust_for_elo_change <- ad_matches %>%
    select(match_id, leaderboard, start_dt) %>%
    filter(leaderboard == "Team Random Map") %>%
    filter(start_dt <= ymd_hms("2022-07-13 23:00:00"))

adjust_players <- ad_players %>%
    semi_join(adjust_for_elo_change, by = "match_id") %>%
    mutate(rating = 0.46134453057734565 * rating + 433.32528079864903)

ad_players_adj <- ad_players %>%
    anti_join(remove_elo_change, by = "match_id") %>%
    anti_join(adjust_players, by = "match_id") %>%
    bind_rows(adjust_players)

ad_matches_adj <- ad_matches %>%
    anti_join(remove_elo_change, by = "match_id")





########################
#
# Calculate team rating stats
#

log_info("Calculating team rating stats")

team_meta <- ad_players_adj %>%
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



n_players_df <- ad_players_adj %>%
    as.data.table() %>%
    group_by(match_id) %>%
    summarise(n_players2 = max(slot)) %>%
    as_tibble()


# Check that the slot numbers (theoretical players) is equal to the number of actual players
keep_consistant_nplayers <- team_meta %>%
    left_join(n_players_df, by = "match_id") %>%
    filter(n_players == n_players2)


log_n_removed_df(
    ad_matches_adj, keep_consistant_nplayers,
    msg = "number of players not equalling number of slots"
)


LEADERBOARDS_1v1 <- c("1v1 Random Map", "1v1 Empire Wars")

ad_matches2 <- ad_matches_adj %>%
    semi_join(keep_consistant_nplayers, by = "match_id") %>%
    inner_join(team_meta, by = "match_id") %>%
    mutate(is_mirror = leaderboard %in% LEADERBOARDS_1v1 & n_unique_civ != 2)


ad_players2 <- ad_players_adj %>%
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

log_info("Calculating rolling civ play rates")

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

log_info("Data integrety checks")

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
    "max_civ_pr" = is.numeric,
    "color" = is.numeric
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


log_n_removed_df(
    matches, ad_matches2,
    msg = "not passing all of the checks (final %)"
)


############################################
#
# Save Data
#
#
#

log_info("Saving Data")

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
