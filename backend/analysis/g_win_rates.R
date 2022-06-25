devtools::load_all()
library(dplyr)
library(ggplot2)
library(scales)
library(lubridate)
library(arrow)

# args <- get_args("p02_v02", "rm_solo_all")
args <- get_args()
data_location <- get_data_location(args)

pr <- read_parquet(file.path(data_location, "pr.parquet"))


plot_pr_wr <- function(wr, pr, id) {
    assert_that(
        nrow(wr) == nrow(pr)
    )

    pdat <- wr %>%
        inner_join(select(pr, civ, pr), by = "civ") %>%
        select(civ = civ, wr, pr)


    p <- ggplot(data = pdat, aes(y = wr, x = pr, label = civ)) +
        geom_point() +
        theme_bw() +
        scale_y_continuous(breaks = pretty_breaks(10)) +
        scale_x_continuous(breaks = pretty_breaks(10)) +
        theme(
            plot.caption = element_text(hjust = 0)
        ) +
        geom_text_repel(min.segment.length = unit(0.1, "lines"), alpha = 0.7) +
        labs(caption = get_footnotes(id, args)) +
        xlab("Play Rate (%)") +
        ylab("Win Rate (%)") +
        geom_hline(yintercept = 50, col = "red", alpha = 0.65) +
        geom_vline(xintercept = 1 / nrow(pr) * 100, col = "red", alpha = 0.65)

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


OUTPUT_ID <- "civ_wrNaive"


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
    labs(caption = get_footnotes(OUTPUT_ID, args)) +
    ylab("Win Rate (%)") +
    xlab("") +
    scale_y_continuous(breaks = pretty_breaks(10))


save_plot(
    args = args,
    p = p,
    id = OUTPUT_ID,
    type = "standard"
)




OUTPUT_ID <-  "civ_wrNaive_playrate"

p2 <- plot_pr_wr(wr, pr, OUTPUT_ID)

save_plot(
    args = args,
    p = p2,
    id = OUTPUT_ID,
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


OUTPUT_ID <-  "civ_wrAvg"

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
    labs(caption = get_footnotes(OUTPUT_ID, args)) +
    ylab("Win Rate (%)") +
    xlab("") +
    scale_y_continuous(breaks = pretty_breaks(10))

save_plot(
    args = args,
    p = p,
    id = OUTPUT_ID,
    type = "standard"
)




OUTPUT_ID <- "civ_wrAvg_playrate"

p2 <- plot_pr_wr(wr, pr, OUTPUT_ID)

save_plot(
    args = args,
    p = p2,
    id = OUTPUT_ID,
    type = "standard"
)


set_log(get_output_location(args), "win_rates")



