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


matches2 <- matches %>%
    mutate(start = as.Date(start_dt)) %>%
    mutate(stop = as.Date(stop_dt))


DATE_UPPER <- max(matches2$start)
DATE_LOWER <- DATE_UPPER - days(45)


valid_matches <- matches2 %>%
    ungroup() %>%
    filter(start >= DATE_LOWER, start <= DATE_UPPER) %>%
    select(match_id, leaderboard, start_dt)


dat <- players %>%
    inner_join(valid_matches, by = "match_id") %>%
    group_by(profile_id, leaderboard) %>%
    arrange(desc(start_dt)) %>%
    slice(1)


quant <- dat %>%
    as_tibble() %>%
    group_by(leaderboard) %>%
    summarise(
        percentile = 0:100,
        elo = quantile(rating, percentile / 100),
        .groups = "drop"
    )




get_elo_plot <- function(board, OUTPUT_ID) {

    dat_ind <- dat %>%
        filter(leaderboard == board)


    quant_ind <- quant %>%
        filter(leaderboard == board)


    q_target <- c(0, 1:9 / 10, 0.95, 0.98, 0.99, 1)  * 100


    qvals <- quant_ind %>%
        filter(percentile %in% q_target) %>%
        pull(elo)


    labels <- sprintf("Q%02.0f", q_target)
    labels[1] <- "Min"
    labels[length(q_target)] <- "Max"


    corner_string <- paste0(
        paste0(labels, " = ", sprintf("%5.0f", qvals)),
        collapse = "\n"
    )


    pdat <- dat_ind %>%
        ungroup() %>%
        filter(rating > quantile(rating, 0.001) - sd(rating)) %>% 
        filter(rating < quantile(rating, 0.999) + sd(rating))


    footnotes <- glue(
        get_footnotes(OUTPUT_ID, get_args(), FALSE),
        date_high = DATE_UPPER,
        date_low = DATE_LOWER
    )

    p <- ggplot(pdat, aes(x = rating, y = ..density..)) +
        geom_density(fill = "#888888") +
        ylab("Density") +
        xlab("Elo") +
        scale_x_continuous(breaks = pretty_breaks(10)) +
        scale_y_continuous(expand = expansion(mult = c(0, 0.05)), breaks = pretty_breaks(10)) +
        annotate(
            "text",
            x = Inf,
            y = Inf,
            label = corner_string,
            hjust = 1.1,
            vjust = 1.1,
            family = "Courier"
        ) +
        theme_bw() +
        labs(caption = footnotes) +
        theme(
            legend.position = "bottom",
            plot.caption = element_text(hjust = 0),
            axis.text.x = element_text(angle = 45, hjust = 1)
        )

    save_plot_no_arg(
        p,
        OUTPUT_ID,
        file.path("outputs", "global")
    )
}




get_elo_plot("1v1 Random Map", "global_elo_dist_solo")
get_elo_plot("1v1 Empire Wars", "global_elo_dist_solo_ew")
get_elo_plot("Team Random Map", "global_elo_dist_team")




