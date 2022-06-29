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




# TODO - Update snakemake to include the global plots

get_day_summary <- function(day, matches_set, players_set) {

    matches_selected <- matches_set %>%
        filter(start > day - days(STEP_SIZE)) %>%
        filter(start <= day) %>%
        select(match_id, start)


    players_selected <- players_set %>%
        inner_join(matches_selected, by = "match_id")


    players_rating <- players_selected %>%
        as.data.table() %>%
        group_by(profile_id, start) %>%
        summarise(rating_avg_plr = mean(rating), .groups = "drop") %>%
        group_by(start) %>%
        summarise(rating_avg = mean(rating_avg_plr)) %>%
        as_tibble()


    players_n <- players_selected %>%
        as.data.table() %>%
        group_by(start) %>%
        summarise(n = length(unique(profile_id)), .groups = "drop") %>%
        as_tibble()


    tibble(
        day = day,
        avg_rating = mean(players_rating$rating_avg),
        n_games = nrow(matches_selected) / STEP_SIZE,
        n_players = mean(players_n$n)
    )
}


matches <- read_parquet(
    file.path("data", "processed", "matches.parquet")
)

players <- read_parquet(
    file.path("data", "processed", "players.parquet")
)



matches2 <- matches %>%
    mutate(start = as.Date(start_dt)) %>%
    mutate(stop = as.Date(stop_dt))



players2 <- players %>%
    semi_join(matches2, by = "match_id")


rm("matches", "players")
gc()

matches_solo <- matches2 %>%
    filter(leaderboard == "1v1 Random Map") %>%
    mutate(start = as.Date(start_dt)) %>%
    mutate(stop = as.Date(stop_dt))

matches_solo_ew <- matches2 %>%
    filter(leaderboard == "1v1 Empire Wars") %>%
    mutate(start = as.Date(start_dt)) %>%
    mutate(stop = as.Date(stop_dt))

matches_team <- matches2 %>%
    filter(leaderboard == "Team Random Map") %>%
    mutate(start = as.Date(start_dt)) %>%
    mutate(stop = as.Date(stop_dt))



STEP_SIZE <- 10
DAY_START <- as.Date(min(matches2$start_dt)) + days(STEP_SIZE)
DAY_STOP <- as.Date(max(matches2$stop_dt))


res_all <- map_df(
    seq(DAY_START, DAY_STOP, by = 4),
    get_day_summary,
    matches2,
    players2
)


res_solo <- map_df(
    seq(DAY_START, DAY_STOP, by = 4),
    get_day_summary,
    matches_solo,
    players2
)


res_solo_ew <- map_df(
    seq(DAY_START, DAY_STOP, by = 4),
    get_day_summary,
    matches_solo_ew,
    players2
)


res_team <- map_df(
    seq(DAY_START, DAY_STOP, by = 4),
    get_day_summary,
    matches_team,
    players2
)



res <- bind_rows(
    res_all %>% mutate(group = "All Ladders"),
    res_solo %>% mutate(group = "RM 1v1 Ladder"),
    res_team %>% mutate(group = "RM Team Ladder"),
    res_solo_ew %>% mutate(group = "EW 1v1 Ladder")
)

res_no_all <- res %>% filter(group != "All Ladders")

elo_limits <- c(
    min(1000, res_no_all$avg_rating),
    max(res_no_all$avg_rating)
)






OUTPUT_ID <- "global_elo_time_AVG"

p1 <- ggplot(res_no_all, aes(x = day, y = avg_rating, group = group, col = group)) +
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

p2 <- ggplot(res, aes(x = day, y = n_games, group = group, col = group)) +
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

p3 <- ggplot(res, aes(x = day, y = n_players, group = group, col = group)) +
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




