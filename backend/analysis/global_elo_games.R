library(arrow)
library(dplyr)
library(scales)
library(lubridate)
library(ggplot2)
library(glue)
devtools::load_all()


matches <- read_parquet(
    file.path("data", "processed", "matches.parquet")
)


players <- read_parquet(
    file.path("data", "processed", "players.parquet")
)



id_map <- list(
    "global_elo_games_SOLO" = "1v1 Random Map",
    "global_elo_games_SOLO_EW" = "Team Random Map",
    "global_elo_games_TEAM" = "1v1 Empire Wars"
)


get_plot <- function(p_matches, p_players, OUTPUT_ID) {

    Leaderboard <- id_map[[OUTPUT_ID]]

    matches_valid <- p_matches %>%
        filter(leaderboard == Leaderboard)


    players_valid <- p_players %>%
        inner_join(matches_valid, by = "match_id")


    latest_elo <- players_valid %>%
        arrange(profile_id, desc(start_dt)) %>%
        select(match_id, profile_id, rating, start_dt) %>%
        group_by(profile_id) %>%
        slice(1)


    ngames <- players_valid %>%
        group_by(profile_id) %>%
        tally()


    qpoints <- seq(0, 1, by = 0.05)
    cuts <- quantile(latest_elo$rating, qpoints)
    labels <- paste0("Q", sprintf("%1.0f", qpoints * 100))
    labels_upd <- paste0(labels[-length(labels)], " - ", labels[-1])


    pdat <- ngames %>%
        left_join(latest_elo, by = "profile_id") %>%
        mutate(grp = cut(rating, breaks = cuts, labels = labels_upd, dig.lab = 4)) %>%
        group_by(grp) %>%
        summarise(n = median(n)) %>%
        filter(!is.na(grp))

    footnotes <- glue(
        get_footnotes(OUTPUT_ID, get_args(), FALSE),
        date_high = MAX_DATE,
        date_low = MIN_DATE
    )

    ggplot(data = pdat) +
        geom_bar(aes(y = n, x = grp), stat = "identity") +
        theme_bw() +
        theme(
            axis.text.x = element_text(angle = 55, hjust = 1),
            plot.caption = element_text(hjust = 0)
        ) +
        scale_y_continuous(breaks = pretty_breaks(10), expand = expansion(mult = c(0, 0.03))) +
        xlab("Elo Quantile") +
        ylab("Median number of games played per player") +
        labs(caption = footnotes)
}


MAX_DATE <- as.Date(max(matches$start_dt))
MIN_DATE <- MAX_DATE - days(45)


matches_valid <- matches %>%
    mutate(start_day = as.Date(start_dt)) %>%
    filter(start_day <= MAX_DATE) %>%
    filter(start_day >= MIN_DATE) %>%
    select(match_id, start_dt, leaderboard)





OUTPUT_ID <- "global_elo_games_SOLO"

p <- get_plot(
    matches_valid,
    players,
    OUTPUT_ID
)

save_plot_no_arg(
    p,
    OUTPUT_ID,
    file.path("outputs", "global")
)





OUTPUT_ID <- "global_elo_games_SOLO_EW"

p <- get_plot(
    matches_valid,
    players,
    OUTPUT_ID
)

save_plot_no_arg(
    p,
    OUTPUT_ID,
    file.path("outputs", "global")
)





OUTPUT_ID <- "global_elo_games_TEAM"

p <- get_plot(
    matches_valid,
    players,
    OUTPUT_ID
)

save_plot_no_arg(
    p,
    OUTPUT_ID,
    file.path("outputs", "global")
)

