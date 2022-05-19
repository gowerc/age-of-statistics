devtools::load_all()
library(dplyr)
library(ggplot2)
library(scales)
library(arrow)


# data_location <- "./data/processed/aoe2/p03_v02/rm_solo_open"
# data_location <- "./data/processed/aoe2/p02_v02/ew_solo_any"
data_location <- get_data_location()


pdat <- arrow::read_parquet(
    file = file.path(data_location, "ad_slide_WR_ELO.parquet")
)


footnotes <- c(
    "Win rates are calculated at each point X after filtering the data to",
    "only include matches where mean Elo is within +- 0.1 percentiles of X.<br/>",
    "Win rates have been calculated as the # of wins / # of games. ",
    "Win rates have been adjusted for difference in mean Elo.<br/>",
    "The error bars represent the 95% confidence interval. ",
    "All lines have been smoothed using a GAM."
) %>%
    as_footnote()


p <- ggplot(data = pdat, aes(ymin = lci, ymax = uci, x = elo, group = civ, fill = civ, y = med)) +
    geom_ribbon(alpha = 0.9, col = NA) +
    geom_line(col = "#383838") +
    theme_bw() +
    scale_y_continuous(breaks = pretty_breaks(5)) +
    scale_x_continuous(breaks = pretty_breaks(5)) +
    geom_hline(yintercept = 50, col = "red", alpha = 0.8) +
    ylab("Win Rate (%)") +
    xlab("Elo") +
    facet_wrap(~civ) +
    theme(
        legend.position = "none",
        axis.text.x = element_text(angle = 50, hjust = 1),
        plot.caption = element_text(hjust = 0)
    ) +
    labs(caption = footnotes)


save_plot(
    p = p,
    id = "slide_wrNaive_elo",
    type = "square"
)



###############################
#
# Sliding Win Rate by Game Length
#
###############################



pdat <- arrow::read_parquet(
    file = file.path(data_location, "ad_slide_WR_GL.parquet")
)

footnotes <- c(
    "Win rates are calculated at each point X after filtering the data to",
    "only include matches where the game length was within +- 5  in-game minutes of X.<br/>",
    "Win rates have been calculated as the # of wins / # of games. ",
    "Win rates have been adjusted for difference in mean Elo.<br/>",
    "The error bars represent the 95% confidence interval.",
    "All lines have been smoothed using a GAM."
) %>%
    as_footnote()

p <- ggplot(data = pdat, aes(ymin = lci, ymax = uci, x = len, group = civ, fill = civ, y = med)) +
    geom_ribbon(alpha = 0.9, col = NA) +
    geom_line(col = "#383838") +
    theme_bw() +
    scale_y_continuous(breaks = pretty_breaks(5)) +
    scale_x_continuous(breaks = pretty_breaks(5)) +
    geom_hline(yintercept = 50, col = "red", alpha = 0.8) +
    ylab("Win Rate (%)") +
    xlab("Game Length (in-game minutes)") +
    facet_wrap(~civ) +
    theme(
        legend.position = "none",
        axis.text.x = element_text(angle = 50, hjust = 1),
        plot.caption = element_text(hjust = 0)
    ) +
    labs(caption = footnotes)



save_plot(
    p = p,
    id = "slide_wrNaive_gamelength",
    type = "square"
)



###############################
#
# Sliding Play Rate by Elo
#
###############################


res <- arrow::read_parquet(
    file = file.path(data_location, "ad_slide_PR_ELO.parquet")
)

civlist <- res %>%
    arrange(civ) %>%
    pull(civ) %>%
    unique()


footnotes <- c(
    "Play rates are calculated at each point X after filtering the data to",
    "only include matches where mean Elo is within +- 0.1 percentiles of X.<br/>"
) %>%
    as_footnote()

p <- ggplot(data = res, aes(x = y, group = civ, y = pr)) +
    geom_line(col = "#383838") +
    theme_bw() +
    scale_y_continuous(breaks = pretty_breaks(5)) +
    scale_x_continuous(breaks = pretty_breaks(5)) +
    geom_hline(yintercept = 1/length(civlist) * 100, col = "red", alpha = 0.8) +
    ylab("Play Rate (%)") +
    xlab("Elo") +
    facet_wrap(~civ) +
    theme(
        legend.position = "none",
        axis.text.x = element_text(angle = 50, hjust = 1),
        plot.caption = element_text(hjust = 0)
    ) +
    labs(caption = footnotes)


save_plot(
    p = p,
    id = "slide_playrate_elo",
    type = "square"
)

set_log(get_output_location(), "sliding_window")
