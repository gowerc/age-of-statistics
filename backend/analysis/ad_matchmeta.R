
pkgload::load_all()
library(dplyr)
library(tidyr)
library(lubridate)
library(data.table)
library(dtplyr)
library(logger)
library(arrow)


DATACUT <- ymd_hms("2022-12-01 00:00:00")

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


map2map <- jsonlite::read_json(
    "./data/raw/rename_maps.json"
) |> unlist()

board2board <- jsonlite::read_json(
    "./data/raw/rename_leaderboards.json"
) |> unlist()

civ2civ <- jsonlite::read_json(
    "./data/raw/rename_civs.json"
) |> unlist()


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
    filter(started_timestamp >= DATACUT) |>
    select(
        match_id = game_id,
        started = started_timestamp,
        version = patch,
        leaderboard,
        duration,
        map,
        num_players
    ) |>
    collect() |>
    mutate(duration = as.numeric(duration)) |>
    mutate(version = as.character(version))


assert_that(
    all(!is.na(matches_slim_all$match_id)),
    all(!is.na(matches_slim_all$started)),
    all(!is.na(matches_slim_all$version)),
    all(!is.na(matches_slim_all$leaderboard)),
    all(!is.na(matches_slim_all$duration)),
    all(!is.na(matches_slim_all$num_players)),
    all(!is.na(matches_slim_all$map))
)



n_total <- nrow(matches_slim_all) 

log_n_removed(
    n_total,
    sum(matches_slim_all$num_players %% 2),
    "odd number of players"
)
log_n_removed(
    n_total,
    matches_slim_all |> filter(duration > (180 * 60)) |> nrow(),
    "game duration too long"
)
log_n_removed(
    n_total,
    matches_slim_all |> filter(str_detect(leaderboard, "^co_")) |> nrow(),
    "being the controller only leaderboard"
)


matches_slim <- matches_slim_all |>
    filter(!num_players %% 2) |>
    filter(!str_detect(leaderboard, "^co_")) |>
    filter(duration < (180 * 60)) |>
    arrange(started)

assert_that(
    all(matches_slim$map %in% names(map2map)),
    all(matches_slim$leaderboard %in% names(board2board))
)

matches_slim_rename <- matches_slim |>
    mutate(leaderboard = board2board[leaderboard]) |>
    mutate(map = map2map[map])


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
    select(
        match_id = game_id,
        rating = old_rating,
        new_rating,
        civ,
        won = winner,
        profile_id,
        team
    ) |>
    mutate(team = team + 1) |>
    collect()


assert_that(
    all(!is.na(players_slim_all$match_id)),
    all(!is.na(players_slim_all$rating)),
    all(!is.na(players_slim_all$new_rating)),
    all(!is.na(players_slim_all$won)),
    all(!is.na(players_slim_all$civ)),
    all(!is.na(players_slim_all$team)),
    all(players_slim_all$team %in% c(1,2))
)


n_total <- nrow(players_slim_all)


log_n_removed(
    n_total,
    sum(is.na(players_slim_all$profile_id)),
    "missing profile_id"
)


players_slim <- players_slim_all |>
    filter(!is.na(profile_id))



assert_that(
    all(players_slim$civ %in% names(civ2civ))
)

players_slim_rename <- players_slim |>
    mutate(civ = civ2civ[civ])




###################################
#
# Combining
#
#


players <- players_slim_rename |>
    semi_join(matches_slim_rename, by = "match_id")



matches <- matches_slim_rename |>
    semi_join(players_slim_rename, by = "match_id")


assert_that(
    length(unique(matches$match_id)) == length(unique(players$match_id)),
    nrow(matches) == nrow(matches |> distinct()), 
    nrow(players) == nrow(players |> distinct())
)

rm(players_slim, matches_slim, matches_slim_rename, players_slim_rename)
rm(players_slim_all, player_files, matches_slim_all, match_files)
devnull <- gc()






###################################
#
# Reducing to make processing easier for testing
#
#

# matches <- matches |> sample_frac(0.3)
# players <- players |> semi_join(matches, by = "match_id")
# gc()





###################################
#
# Check that all maps have a classification
#
#


log_info('Starting Map classification')


mapclass <- get_map_class()
u_mapname <- unique(matches$map)
no_class <- u_mapname[!u_mapname %in% mapclass$map_name]
assert_that(
    length(no_class) == 0,
    msg = sprintf(
        "The following maps do not have a classification:\n%s",
        paste0(no_class, collapse = "\n")
    )
)
devnull <- gc()




###################################
#
# Check that each team has the same number of players
#
#


log_info('Starting team n validation')


## calculate n players per team and make sure each team has the same number of players
team_counts <- players |>
    as.data.table() |>
    group_by(match_id, team) |>
    tally()

all_matches <- tidyr::expand_grid(
    match_id = matches$match_id,
    team = c(1, 2)
)

team_counts_compare <- all_matches |>
    left_join(team_counts, by = c("match_id", "team")) |>
    as_tibble() |>
    mutate(team = paste0("team_", team)) |>
    mutate(n = replace_na(n, 0)) |>
    spread(team, n) |>
    left_join(matches |> select(match_id, num_players), by = "match_id")


assert_that(
    nrow(matches) == nrow(team_counts_compare),
    all(!is.na(team_counts_compare$team_1)),
    all(!is.na(team_counts_compare$team_2)),
    all(!is.na(team_counts_compare$num_players))
)
    
keep_valid_teams <- team_counts_compare |>
    filter(team_1 == team_2) |>
    filter(team_1 !=0) |>
    filter(team_2 != 0) |>
    filter((team_1 + team_2) == num_players) |>
    ungroup()


log_n_removed_df(matches, keep_valid_teams, msg = "unequal team numbers")


# players |>
#     anti_join(keep_valid_teams, by = "match_id") |>
#     arrange(match_id, profile_id) |>
#     print(n = 50)





###################################
#
# Check that we have agreement on who actually won
#
#


log_info('Starting who-won validation')


# Check that we have agreement on which team actually won
# within team n unique = 1
# across teams n unique = 2

assert_that(
    !any(is.na(players$won)),
    msg = "Assumption that no 'won' is missing is FALSE"
)


n_unique_won_match <- players |>
    as.data.table() |>
    group_by(match_id) |>
    summarise(n_unique_match = length(unique(won)), .groups = "drop") |>
    as_tibble()


n_unique_won_team <- players |>
    as.data.table() |>
    group_by(match_id, team) |>
    summarise(n_unique_match = length(unique(won)), .groups = "drop") |>
    as_tibble()


keep_correct_won_within <- n_unique_won_team |>
    mutate(team = paste0("team_", team)) |>
    spread(team, n_unique_match) |>
    filter(team_1 == 1, team_2 == 1) |>
    select(match_id)


keep_correct_won_between <- n_unique_won_match |>
    filter(n_unique_match == 2) |>
    select(match_id)


log_n_removed_df(
    matches, keep_correct_won_within,
    msg = "inconsistent result within team"
)


log_n_removed_df(
    matches, keep_correct_won_between,
    msg = "inconsistent result between teams"
)


rm(n_unique_won_match, n_unique_won_team) 
devnull <- gc()




# keep_correct_colors <- players |>
#     select(match_id, color) |>
#     data.table() |>
#     mutate(unknown_color = !color %in% c(1:8)) |>
#     group_by(match_id) |>
#     summarise(
#         has_missing_color = any(is.na(color)),
#         n_color = length(color),
#         n_color_unique = length(unique(color)),
#         unknown_color = any(unknown_color),
#         .groups = "drop"
#     ) |>
#     filter(n_color == n_color_unique) |>
#     filter(!unknown_color) |>
#     filter(!has_missing_color) |>
#     as_tibble()


# log_n_removed_df(
#     matches, keep_correct_colors,
#     msg = "invalid colours"
# )


log_info("Starting ad_matches / ad_players")


ad_matches <- matches |>
    inner_join(mapclass, by = c("map" = "map_name")) |>
    rename(match_length_igm = duration) |>
    mutate(start_dt = started) |>
    mutate(stop_dt = started + seconds(match_length_igm/1.7)) |>
    mutate(match_length_igm = match_length_igm / 60) |>
    mutate(match_length_irl = as.numeric(difftime(stop_dt, start_dt, units = "mins"))) |>
    mutate(version = replace_na(version, "Unknown")) |>
    select(-started) |>
    semi_join(keep_valid_teams, by = "match_id") |>
    semi_join(keep_correct_won_within, by = "match_id") |>
    semi_join(keep_correct_won_between, by = "match_id")



log_n_removed_df(
    matches, ad_matches,
    msg = "Not meeting the above keep requirements"
)


ad_players <- players |>
    semi_join(ad_matches, by = "match_id") |>
    semi_join(keep_valid_teams, by = "match_id") |>
    semi_join(keep_correct_won_within, by = "match_id") |>
    semi_join(keep_correct_won_between, by = "match_id")


ad_matches <- ad_matches |>
    semi_join(ad_players, by = "match_id")


assert_that(
    length(ad_matches$match_id) == length(unique(ad_players$match_id))
)

rm(players, matches_maps)
rm(list = ls(pattern = "keep_"))
devnull <- gc()


########################
#
# Fix Elo for update
#

# log_info("Fixing Elo")

# remove_elo_change <- ad_matches |>
#     select(match_id, leaderboard, start_dt) |>
#     filter(leaderboard == "Team Random Map") |>
#     filter(start_dt >= ymd_hms("2022-07-12 23:59:59")) |>
#     filter(start_dt <= ymd_hms("2022-07-18 00:00:00"))


# adjust_for_elo_change <- ad_matches |>
#     select(match_id, leaderboard, start_dt) |>
#     filter(leaderboard == "Team Random Map") |>
#     filter(start_dt <= ymd_hms("2022-07-13 23:00:00"))


# adjust_players <- ad_players |>
#     semi_join(adjust_for_elo_change, by = "match_id") |>
#     mutate(rating = 0.46134453057734565 * rating + 433.32528079864903)


# ad_players_adj <- ad_players |>
#     anti_join(remove_elo_change, by = "match_id") |>
#     anti_join(adjust_players, by = "match_id") |>
#     bind_rows(adjust_players)


# ad_matches_adj <- ad_matches |>
#     semi_join(ad_players_adj, by = "match_id") |>
#     anti_join(remove_elo_change, by = "match_id")


# ad_players_adj <- ad_players_adj |>
#     semi_join(ad_matches_adj, by = "match_id")


# rm(remove_elo_change, adjust_for_elo_change, adjust_players)
# devnull <- gc()



########################
#
# Impute missing ratings
#

# log_info('Imputing missing ratings')


# locf <- function(x) {
#     ind <- seq_along(x)
#     ind[is.na(x)] <- 1
#     x[cummax(ind)]
# }


# assert_that(
#     identical(locf(c(5, 3, NA, NA, 2, 6, NA, 9)), c(5, 3, 3, 3, 2, 6, 6, 9)),
#     identical(locf(c(NA, NA, NA, NA, 2, 6, NA, NA)), c(NA, NA, NA, NA, 2, 6, 6, 6))
# )


# match_board <- ad_matches_adj |>
#     select(match_id, leaderboard, start_dt)


# ad_players_imp <- ad_players_adj |>
#     as.data.table() |>
#     left_join(match_board, by = "match_id") |>
#     arrange(profile_id, leaderboard, desc(start_dt)) |>
#     group_by(profile_id, leaderboard) |>
#     mutate(rating = locf(rating)) |>
#     as_tibble()


# rm(ad_players, match_board, ad_players_adj)
# devnull <- gc()



# matches_with_missing_elo <- ad_players_imp |>
#     filter(is.na(rating)) |>
#     distinct(match_id)



# ad_players_imputed <- ad_players_imp |>
#     anti_join(matches_with_missing_elo, by = "match_id") |>
#     select(-leaderboard, -start_dt)


# ad_matches_imputed <- ad_matches_adj |>
#     semi_join(ad_players_imputed, by = "match_id")


# log_n_removed_df(
#     ad_matches_adj, ad_matches_imputed,
#     msg = "Not having a valid rating"
# )


###### Older code to deal with imputation - left encase I change my mind

# players_with_missing <- ad_players_imp |>
#     filter(is.na(rating)) |>
#     distinct(profile_id)


# mean_rating <- ad_players_imp |>
#     semi_join(players_with_missing, by = "profile_id") |>
#     filter(!is.na(rating)) |>
#     as.data.table() |>
#     group_by(profile_id) |>
#     summarise(mrating = mean(rating, na.rm = TRUE))|>
#     as_tibble()


# ad_players_imp2 <- ad_players_imp |>
#     left_join(mean_rating, by = "profile_id") |>
#     mutate(rating = if_else(is.na(rating), mrating, rating)) |>
#     select(-mrating)


# missing_elo <- ad_players_imp2 |>
#     filter(is.na(rating)) |>
#     distinct(match_id)


# mean_rating_match <- ad_players_imp2 |>
#     semi_join(missing_elo, by = "match_id")  |>
#     group_by(match_id) |>
#     summarise(mrating = mean(rating, na.rm = TRUE))


# ad_players_imp3 <- ad_players_imp2 |>
#     left_join(mean_rating_match, by = "match_id") |>
#     mutate(rating = if_else(is.na(rating), mrating, rating)) |>
#     select(-mrating)


# remove_missing_elos <- ad_players_imp3 |>
#     filter(is.na(rating)) |>
#     distinct(match_id)


# ad_matches_imputed <- ad_matches_adj |>
#     anti_join(remove_missing_elos, by = "match_id") |>
#     semi_join(ad_players_imp3, by = "match_id")


# ad_players_imputed <- ad_players_imp3 |>
#     anti_join(remove_missing_elos, by = "match_id") |>
#     select(-leaderboard, -start_dt) |>
#     semi_join(ad_matches_imputed, by = "match_id")


# rm(ad_players_imp, ad_players_imp2, ad_players_imp3)
# rm(mean_rating, mean_rating_match, remove_missing_elos)
# rm(ad_matches_adj, players_with_missing, missing_elo)
# devnull <- gc()

########################
#
# Calculate team rating stats
#

log_info("Calculating team rating stats")


team_meta <- ad_players |>
    as.data.table() |>
    group_by(match_id) |>
    summarise(
        n_players = n(),
        rating_min = min(rating),
        rating_max = max(rating),
        rating_mean = mean(rating),
        rating_diff_mean = mean(rating[team == 1]) - mean(rating[team == 2]),
        winning_team = unique(team[won]),
        n_unique_civ = length(unique(civ)),
        .groups = "drop"
    ) |>
    as_tibble() |>
    mutate(n_players_team = n_players / 2)



assert_that(
    all(team_meta$n_players_team %in% c(1,2,3,4)),
    all(!is.na(team_meta$n_players)),
    all(!is.na(team_meta$rating_min)),
    all(!is.na(team_meta$rating_max)),
    all(!is.na(team_meta$rating_mean)),
    all(!is.na(team_meta$rating_diff_mean)),
    all(!is.na(team_meta$winning_team)),
    all(!is.na(team_meta$n_unique_civ)),
    all(!is.na(team_meta$n_players_team)),
    length(unique(team_meta$match_id)) == length(unique(ad_matches$match_id))
)





LEADERBOARDS_1v1 <- c("1v1 Random Map", "1v1 Empire Wars")


ad_matches2 <- ad_matches |>
    inner_join(team_meta, by = "match_id") |>
    mutate(is_mirror = leaderboard %in% LEADERBOARDS_1v1 & n_unique_civ != 2)


assert_that(
    all(ad_matches2$num_players == ad_matches2$n_players)
)

ad_matches2 <- ad_matches2 |> select(-num_players)


ad_players2 <- ad_players |>
    semi_join(ad_matches2, by = "match_id")


rm(n_players_df, team_meta, keep_consistant_nplayers)
devnull <- gc()





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



#' @param civ numeric civ index e.g.  1, 1, 1, 3, 3, 2, 5, 2, 5, 1
#' @param n_civs Total number of civs
civ_percent_rolling <- function(civs, n_civs) {
    assert_that(
        all(civs %in% seq(1, n_civs))
    )
    results <- vector(mode = "numeric", length = length(civs))  # Defaults to 0 for all values
    hold <- vector(mode = "numeric", length = n_civs)
    for (index in seq_along(civs)) {
        civ_index <- civs[[index]]
        hold[civ_index] <- hold[civ_index] + 1
        if (index > 40) {
            ind_decrement <- civs[[index - 40]]
            hold[ind_decrement] <- hold[ind_decrement] - 1
        }
        results[[index]] <- (max(hold) + 1) / (sum(hold) + 2) # include smoother
    }
    return(results)
}

assert_that(
    civ_percent_rolling(c(rep(1, 40), rep(2, 40)), length(civs_unique))[60] == 0.5
)


matches_1v1 <- ad_matches2 |>
    filter(leaderboard %in% LEADERBOARDS_1v1) |>
    select(match_id, leaderboard, start_dt)


players_1v1 <- ad_players2 |>
    inner_join(matches_1v1, by = "match_id") |>
    select(profile_id, leaderboard, civ, start_dt, match_id) |>
    arrange(leaderboard, profile_id, start_dt) |>
    mutate(civ_ind = as.numeric(factor(civ, levels = civs_unique)))


players_roll <- players_1v1 |>
    as.data.table() |>
    group_by(profile_id, leaderboard) |>
    mutate(max_civ_pr = civ_percent_rolling(civ_ind, length(civs_unique))) |>
    as_tibble()


players_roll_slim <- players_roll |>
    select(profile_id, match_id, max_civ_pr)


ad_players3 <- ad_players2 |>
    left_join(players_roll_slim, by = c("profile_id", "match_id")) |>
    mutate(max_civ_pr = replace_na(max_civ_pr, 0))


rm(matches_1v1, players_1v1, players_roll, players_roll_slim, ad_players2)
devnull <- gc()





############################################
#
# Basic Data integrety checks
#
#
#

log_info("Data integrety checks")

extra_matches_1 <- ad_matches2 |>
    anti_join(ad_players3, by = "match_id") |>
    nrow()


extra_matches_2 <- ad_players3 |>
    anti_join(ad_matches2, by = "match_id") |>
    nrow()


is.team <- function(x) {
    is.numeric(x) & all(x %in% c(1, 2))
}


meta_players <- list(
    "match_id" = is.character,
    "rating" = is.numeric,
    "new_rating" = is.numeric,
    "civ" = is.character,
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
    "match_length_irl" = is.numeric,
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







###### Looking into ELO stability


# fix_new_rating <- function(rating, lag_rating) {
#     lag_rating[1] <- rating[1]
#     return(lag_rating)
# }


# x <- ad_players3 |>
#     left_join(select(ad_matches2, match_id, start_dt, leaderboard), by = "match_id") |>
#     arrange(profile_id, start_dt) |>
#     group_by(profile_id, leaderboard) |>
#     select(match_id, profile_id, rating, leaderboard) |>
#     mutate( r2 = lag(rating)) |>
#     mutate( r2 = fix_new_rating(rating, r2)) |>
#     mutate( delta = r2 - rating)


# x |> filter(delta > 150) |> pull(profile_id) |>unique() |> length()

# ad_players3 |>
#     filter(profile_id == 5589) |>
#     select(match_id, profile_id, rating, new_rating) |>
#     left_join(select(ad_matches2, match_id, leaderboard, start_dt), by = "match_id") |>
#     arrange(leaderboard, match_id) |>
#     print(n=999)




