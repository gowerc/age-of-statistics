


pkgload::load_all()
library(dplyr)
library(dbplyr)
library(DBI)
library(lubridate)
library(ggplot2)
library(scales)


con <- get_connection()


date_limits <- tbl(con, "match_meta") %>%
    summarise(
        min = min(started, na.rm = TRUE),
        max = max(started, na.rm = TRUE)
    ) %>%
    collect()


DATE_LIMIT_LOWER <- date_limits$min
DATE_LIMIT_UPPER <- date_limits$max


matches_time_limit <- tbl(con, "match_meta") %>%
    filter(started >= DATE_LIMIT_LOWER) %>%
    filter(started <= DATE_LIMIT_UPPER) %>%
    filter(leaderboard_id == 3) %>%
    select(match_id)


matches_all <- tbl(con, "match_meta") %>%
    select(match_id, started) %>%
    inner_join(matches_time_limit, by = "match_id") %>%
    collect() %>%
    mutate(start = as.Date(ymd("1970-01-01") + seconds(started)))


players_all <- tbl(con, "match_players") %>%
    select(match_id, rating, profile_id) %>%
    filter(!is.na(rating)) %>%
    inner_join(matches_time_limit, by = "match_id") %>%
    collect()


STEP_SIZE <- 10
DAY_START <- as.Date(ymd("1970-01-01") + seconds(DATE_LIMIT_LOWER)) + days(STEP_SIZE)
DAY_STOP <- as.Date(ymd("1970-01-01") + seconds(DATE_LIMIT_UPPER)) - days(STEP_SIZE)


get_day_summary <- function(day) {
    matches_selected <- matches_all %>%
        filter(start > day - days(STEP_SIZE)) %>%
        filter(start < day + days(STEP_SIZE))


    players_selected <- players_all %>%
        semi_join(matches_selected, by = "match_id") %>%
        group_by(profile_id) %>%
        summarise(
            n = n(),
            rating = mean(rating)
        )

    tibble(
        day = day,
        avg_rating = mean(players_selected$rating),
        n_games = sum(players_selected$n),
        n_players = nrow(players_selected)
    )
}


res <- map_df(
    seq(DAY_START, DAY_STOP, by = 4),
    get_day_summary
)




p1 <- ggplot(res, aes(x = day, y = avg_rating)) +
    theme_bw() +
    geom_point() +
    geom_line() +
    scale_y_continuous(breaks = pretty_breaks(10)) +
    scale_x_date(breaks = pretty_breaks(10)) +
    ylab("Average Player Elo") +
    xlab("Date")


p2 <- ggplot(res, aes(x = day, y = n_games)) +
    theme_bw() +
    geom_point() +
    geom_line() +
    scale_y_continuous(breaks = pretty_breaks(10)) +
    scale_x_date(breaks = pretty_breaks(10)) +
    ylab("Total Number of Games Played") +
    xlab("Date")


p3 <- ggplot(res, aes(x = day, y = n_players)) +
    theme_bw() +
    geom_point() +
    geom_line() +
    scale_y_continuous(breaks = pretty_breaks(10)) +
    scale_x_date(breaks = pretty_breaks(10)) +
    ylab("Number of Unique Players") +
    xlab("Date")


ggsave(
    plot = p1,
    filename = "./outputs/misc/exp_elo_time_AVG.png",
    width = 8,
    height = 6,
    dpi = 200
)

ggsave(
    plot = p2,
    filename = "./outputs/misc/exp_elo_time_NGAME.png",
    width = 8,
    height = 6,
    dpi = 200
)

ggsave(
    plot = p3,
    filename = "./outputs/misc/exp_elo_time_NPLAYER.png",
    width = 8,
    height = 6,
    dpi = 200
)
