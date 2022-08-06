

pkgload::load_all()
library(dplyr)
library(dbplyr)
library(tidyr)
library(lubridate)
library(data.table)
library(dtplyr)
library(logger)
library(arrow)


con <- get_connection()


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
    select(match_id, rating, civ, won, slot, profile_id, team, color)


log_info('Reading data from database')

players <- players_slim %>%
    collect()


matches <- matches_slim %>%
    semi_join(players_slim, by = "match_id") %>%
    collect()




















players_all <- tbl(con, "match_players") %>% collect()

save_me <- function(date, data) {
    devnull <- write_parquet(data, sink = sprintf("./data/source/players/players_%s.parquet", date))
    return(invisible(NULL))
}

matches_numeric <- as.numeric(players_all$match_id)

ngroup <- 200000
low <- 0
high <- ceiling(max(matches_numeric) / ngroup) * ngroup
cut_points <- seq(low, high, by = ngroup)

x <- players_all |>
    mutate(save_group = cut(as.numeric(match_id), breaks = cut_points, labels = cut_points[-length(cut_points)])) |>
    nest(data = -save_group)

devnull <- map2(x$save_group, x$data, save_me)






matches_all <- tbl(con, "match_meta") %>% collect()

save_me <- function(date, data) {
    devnull <- write_parquet(data, sink = sprintf("./data/source/matches/matches_%s.parquet", date))
    return(invisible(NULL))
}

matches_numeric <- as.numeric(matches_all$match_id)

ngroup <- 200000
low <- 0
high <- ceiling(max(matches_numeric) / ngroup) * ngroup
cut_points <- seq(low, high, by = ngroup)

x <- matches_all |>
    mutate(save_group = cut(as.numeric(match_id), breaks = cut_points, labels = cut_points[-length(cut_points)])) |>
    nest(data = -save_group)

devnull <- map2(x$save_group, x$data, save_me)










start <- Sys.time()
dat <- map_df(list.files("./temp", full.names = TRUE), read_parquet)
stop <- Sys.time()
difftime(stop, start, units = "secs")
# Time difference of 211.5579 secs





get_p_df <- function(file) {
    read_parquet(file = file, as_data_frame = FALSE) |>
        filter(leaderboard_id %in% local(board_ids$leaderboard_id)) %>%
        filter(!is.na(version)) %>%
        filter(map_type %in% local(map_ids$map_type)) %>%
        filter(!(is.na(started) | is.na(finished))) %>%
        filter(finished - started < (180 * 60)) |>
        select(match_id, started, version, leaderboard_id, finished, map_type) |>
        collect()
}

get_p_df2 <- function(file) {
    read_parquet(file = file, as_data_frame = FALSE) |>
        select(match_id, started, version, leaderboard_id, finished, map_type) |>
        collect()
}

start <- Sys.time()
dat1 <- map_df(list.files("./temp", full.names = TRUE), get_p_df)
stop <- Sys.time()
difftime(stop, start, units = "secs")
# Time difference of 62.96249 secs


start <- Sys.time()
dat2 <- map(list.files("./temp", full.names = TRUE), get_p_df)
stop <- Sys.time()
difftime(stop, start, units = "secs")
# Time difference of 36.01666 secs


start <- Sys.time()
dat3 <- map_df(list.files("./temp", full.names = TRUE), get_p_df2)
stop <- Sys.time()
difftime(stop, start, units = "secs")
# Time difference of 66.27489 secs






start <- Sys.time()
pfiles <- list.files("./temp", full.names = TRUE)
ox <- open_dataset(pfiles)
d3 <- ox |>
    filter(leaderboard_id %in% local(board_ids$leaderboard_id)) %>%
    filter(!is.na(version)) %>%
    filter(map_type %in% local(map_ids$map_type)) %>%
    filter(!(is.na(started) | is.na(finished))) %>%
    filter(finished - started < (180 * 60)) |>
    select(match_id, started, version, leaderboard_id, finished, map_type) |>
    collect()
d4 <- as.data.frame(d3)
head(d4)
stop <- Sys.time()
difftime(stop, start, units = "secs")





matches_slim <- tbl(con, "match_meta") %>%
    filter(leaderboard_id %in% local(board_ids$leaderboard_id)) %>%
    filter(!is.na(version)) %>%
    filter(map_type %in% local(map_ids$map_type)) %>%
    filter(!(is.na(started) | is.na(finished))) %>%
    filter(finished - started < (180 * 60)) %>%
    select(match_id, started, version, leaderboard_id, finished, map_type)


start <- Sys.time()
matches <- matches_slim |> collect()
stop <- Sys.time()
difftime(stop, start, units = "secs")
# Time difference of 7.770235 secs






players_slim <- tbl(con, "match_players") %>%
    #semi_join(matches_slim, by = "match_id") %>%
    filter(!is.na(profile_id)) %>%
    filter(!is.na(rating)) %>%
    filter(!is.na(won)) %>%
    filter(!is.na(slot)) %>%
    filter(civ %in% local(civ_ids$civ)) %>%
    filter(team %in% c(1, 2), !is.na(team)) %>%
    select(match_id, rating, civ, won, slot, profile_id, team, color)
    
    
start <- Sys.time()
players <- players_slim |> collect()
stop <- Sys.time()
difftime(stop, start, units = "secs")
# Time difference of 77.08652 secs




players |>
    semi_join(matches, by = "match_id")





match_files <- list.files(
    "./data/source/matches",
    full.names = TRUE,
    pattern = "*.parquet"
)
match_con <- open_dataset(match_files)
matches <- match_con |>
    filter(leaderboard_id %in% local(board_ids$leaderboard_id)) %>%
    filter(!is.na(version)) %>%
    filter(map_type %in% local(map_ids$map_type)) %>%
    filter(!(is.na(started) | is.na(finished))) %>%
    filter(finished - started < (180 * 60)) %>%
    select(match_id, started, version, leaderboard_id, finished, map_type) |>
    collect()


player_files <- list.files(
    "./data/source/players",
    full.names = TRUE,
    pattern = "*.parquet"
)
player_con <- open_dataset(player_files)
players_slim <- player_con %>%
    filter(!is.na(profile_id)) %>%
    filter(!is.na(rating)) %>%
    filter(!is.na(won)) %>%
    filter(!is.na(slot)) %>%
    filter(civ %in% local(civ_ids$civ)) %>%
    filter(team %in% c(1, 2), !is.na(team)) %>%
    select(match_id, rating, civ, won, slot, profile_id, team, color) |>
    collect()

players_slim
