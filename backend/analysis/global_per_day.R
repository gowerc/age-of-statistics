pkgload::load_all()
library(dplyr)
library(lubridate)
library(ggplot2)
library(scales)
library(arrow)
library(dtplyr)
library(data.table)
library(parallel)

# args <- get_args("p02_v02", "rm_solo_all")
args <- get_args()
dir.create(
    file.path("outputs", "global"),
    recursive = TRUE,
    showWarnings = FALSE
)



get_day_summary <- function(day, games2, WINDOW) {
    cat(paste("Starting day", day, "\n"))
    games_selected <- games2 |>
        filter(start > (day - days(WINDOW))) |>
        filter(start <= day)

    valid_days <- games_selected |>
        group_by(start, leaderboard) |>
        tally() |>
        spread(leaderboard, n) |>
        drop_na()

    games_selected2 <- games_selected |>
        semi_join(valid_days, by = "start")

    players_rating <- games_selected2 |>
        as.data.table() |>
        group_by(profile_id, leaderboard) |>
        slice(1) |>
        select(match_id, profile_id, leaderboard, rating) |>
        group_by(leaderboard) |>
        summarise(avg_rating = mean(rating)) |>
        as_tibble()

    players_n <- games_selected2 |>
        as.data.table() |>
        group_by(start, leaderboard) |>
        summarise(
            n_players = length(unique(profile_id)),
            n_games = length(unique(match_id)),
            .groups = "drop"
        ) |>
        group_by(leaderboard) |>
        summarise(
            n_players = mean(n_players),
            n_games = mean(n_games),
            .groups = "drop"
        ) |>
        as_tibble()

    inner_join(players_n, players_rating, by = "leaderboard") |>
        mutate(day = day)
}


matches <- read_parquet(
    file.path("data", "processed", "matches.parquet")
)

players <- read_parquet(
    file.path("data", "processed", "players.parquet")
)



matches2 <- matches |>
    mutate(start = as.Date(start_dt)) |>
    mutate(stop = as.Date(stop_dt)) |>
    select(match_id, start, stop, leaderboard, start_dt)



games <- players |>
    inner_join(matches2, by = "match_id") |>
    select(match_id, start, stop, profile_id, rating, leaderboard, start_dt) |>
    arrange(desc(start_dt))


rm("matches", "players", "matches2")
gc()

games2 <- bind_rows(
    games,
    games |> mutate(leaderboard = "All Ladders")
)


WINDOW <- 14
STEP_SIZE <- 4
DAY_START <- min(games$start) + days(WINDOW)
DAY_STOP <- max(games$stop) - days(2)


res <- map_df(
    seq(DAY_START, DAY_STOP, by = STEP_SIZE),
    get_day_summary,
    games2,
    WINDOW
)


res_no_all <- res  |> filter(leaderboard != "All Ladders")

elo_limits <- c(
    min(1000, res_no_all$avg_rating),
    max(res_no_all$avg_rating)
)


# games2 |>
#     filter(profile_id == "179973") |>
#     filter(leaderboard == "Team Random Map") |>
#     print(n = 120)

# games3 <- games2 |>
#     as.data.table() |>
#     filter(leaderboard == "Team Random Map") |>
#     group_by(profile_id) |>
#     mutate(celo = cummean(rating)) |>
#     mutate(ediff = abs(rating - celo)) |>
#     as_tibble()

# games3 |> filter(ediff > 300) |> print(n = 50)
# games3 |>
#     filter(start > ymd("2022-07-08")) |>
#     filter(ediff > 300) |>
#     group_by(start) |>
#     tally() |>
#     print(n = 99)


OUTPUT_ID <- "global_elo_time_AVG"

p1 <- ggplot(res_no_all, aes(x = day, y = avg_rating, group = leaderboard, col = leaderboard)) +
    theme_bw() +
    geom_point() +
    geom_line() +
    scale_y_continuous(breaks = pretty_breaks(10), limits = elo_limits) +
    scale_x_date(date_breaks = "1 month", date_labels =  "%b %Y") +
    ylab("Average player Elo") +
    xlab("Date") +
    theme(
        legend.position = "bottom",
        plot.caption = element_text(hjust = 0),
        axis.text.x = element_text(angle = 45, hjust = 1)
    ) +
    scale_color_discrete(name = "") +
    labs(caption = get_footnotes(OUTPUT_ID, args, FALSE))

save_plot_no_arg(
    p1,
    OUTPUT_ID,
    file.path("outputs", "global")
)






OUTPUT_ID <- "global_elo_time_NGAME"

p2 <- ggplot(res, aes(x = day, y = n_games, group = leaderboard, col = leaderboard)) +
    theme_bw() +
    geom_point() +
    geom_line() +
    scale_y_continuous(breaks = pretty_breaks(10), limits = c(0, max(res$n_games))) +
    scale_x_date(date_breaks = "1 month", date_labels =  "%b %Y") +
    ylab("Total number of games played per day") +
    xlab("Date") +
    theme(
        legend.position = "bottom",
        plot.caption = element_text(hjust = 0),
        axis.text.x = element_text(angle = 45, hjust = 1)
    ) +
    scale_color_discrete(name = "") +
    labs(caption = get_footnotes(OUTPUT_ID, args, FALSE))

save_plot_no_arg(
    p2,
    OUTPUT_ID,
    file.path("outputs", "global")
)






OUTPUT_ID <- "global_elo_time_NPLAYER"

p3 <- ggplot(res, aes(x = day, y = n_players, group = leaderboard, col = leaderboard)) +
    theme_bw() +
    geom_point() +
    geom_line() +
    scale_y_continuous(breaks = pretty_breaks(10), limits = c(0, max(res$n_players))) +
    scale_x_date(date_breaks = "1 month", date_labels =  "%b %Y") +
    ylab("Number of unique players per day") +
    xlab("Date") +
    theme(
        legend.position = "bottom",
        plot.caption = element_text(hjust = 0),
        axis.text.x = element_text(angle = 45, hjust = 1)
    ) +
    scale_color_discrete(name = "") +
    labs(caption = get_footnotes(OUTPUT_ID, args, FALSE))

save_plot_no_arg(
    p3,
    OUTPUT_ID,
    file.path("outputs", "global")
)


