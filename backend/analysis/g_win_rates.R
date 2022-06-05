devtools::load_all()
library(dplyr)
library(ggplot2)
library(scales)
library(lubridate)
library(arrow)


data_location <- get_data_location()

pr <- read_parquet(file.path(data_location, "pr.parquet"))


plot_pr_wr <- function(wr, pr) {
    assert_that(
        nrow(wr) == nrow(pr)
    )

    pdat <- wr %>%
        inner_join(select(pr, civ, pr), by = "civ") %>%
        select(civ = civ, wr, pr)

    footnotes <- c(
        ""
    ) %>%
        as_footnote()

    p <- ggplot(data = pdat, aes(y = pr, x = wr, label = civ)) +
        geom_point() +
        theme_bw() +
        scale_y_continuous(breaks = pretty_breaks(10)) +
        scale_x_continuous(breaks = pretty_breaks(10)) +
        theme(
            plot.caption = element_text(hjust = 0)
        ) +
        geom_text_repel(min.segment.length = unit(0.1, "lines"), alpha = 0.7) +
        labs(caption = footnotes) +
        ylab("Play Rate (%)") +
        xlab("Win Rate (%)") +
        geom_vline(xintercept = 50, col = "red", alpha = 0.65) +
        geom_hline(yintercept = 1 / nrow(pr) * 100, col = "red", alpha = 0.65)

    return(p)
}

###############################
#
# Naive Win Rates
#
###############################



wr <- read_parquet(file.path(data_location, "wr_naive.parquet"))

pdat <- wr %>%
    arrange(desc(est)) %>%
    mutate(civ = fct_inorder(civ)) %>%
    select(civ, lci, uci, wr = est)


footnotes <- c(
    "Win rates have been adjusted for difference in mean Elo.<br/>",
    "The error bars represent the 95% confidence interval.",
    "The dashed blue lines represent an arbitrary region that could be considered as 'balanced'"
) %>%
    as_footnote()

p <- ggplot(data = pdat, aes(x = civ, group = civ, ymin = lci, ymax = uci, y = wr)) +
    geom_hline(yintercept = 50, col = "red", alpha = 0.65) +
    geom_hline(yintercept = c(45, 55), col = "blue", alpha = 0.65, lty = 2) +
    geom_errorbar(width = 0.3) +
    geom_point() +
    theme_bw() +
    theme(
        axis.text.x = element_text(angle = 50, hjust = 1),
        plot.caption = element_text(hjust = 0)
    ) +
    labs(caption = footnotes) +
    ylab("Win Rate (%)") +
    xlab("") +
    scale_y_continuous(breaks = pretty_breaks(10))


save_plot(
    p = p,
    id = "civ_wrNaive",
    type = "standard"
)

p2 <- plot_pr_wr(wr, pr)

save_plot(
    p = p2,
    id = "civ_wrNaive_playrate",
    type = "standard"
)



###############################
#
# Averaged Win Rates
#
###############################

wr <- read_parquet(file.path(data_location, "wr_avg.parquet"))


pdat <- wr %>%
    arrange(desc(est)) %>%
    mutate(coef = fct_inorder(civ)) %>%
    select(civ = coef, wr = est, lci, uci)


footnotes <- c(
    "Win rates have been calculated as the mean of each separate civ x civ win rate.<br/>",
    "Win rates have been adjusted for difference in mean Elo.<br/>",
    "See methods section for more details.<br/>",
    "The error bars represent the 95% confidence interval."
) %>%
    as_footnote()


p <- ggplot(data = pdat, aes(x = civ, group = civ, ymin = lci, ymax = uci, y = wr)) +
    geom_hline(yintercept = 50, col = "red", alpha = 0.65) +
    geom_hline(yintercept = c(45,55), col = "blue", alpha = 0.65, lty = 2) +
    geom_errorbar(width = 0.3) +
    geom_point() +
    theme_bw() +
    theme(
        axis.text.x = element_text(angle = 50, hjust = 1),
        plot.caption = element_text(hjust = 0)
    ) +
    labs(caption = footnotes) +
        ylab("Win Rate (%)") +
        xlab("") +
        scale_y_continuous(breaks = pretty_breaks(10))


save_plot(
    p = p,
    id = "civ_wrAvg",
    type = "standard"
)

p2 <- plot_pr_wr(wr, pr)

save_plot(
    p = p2,
    id = "civ_wrAvg_playrate",
    type = "standard"
)


set_log(get_output_location(), "win_rates")



