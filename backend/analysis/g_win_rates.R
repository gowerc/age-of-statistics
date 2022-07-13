devtools::load_all()
library(dplyr)
library(ggplot2)
library(scales)
library(lubridate)
library(arrow)

# args <- get_args("p02_v03", "rm_team_open")
args <- get_args()

config <- get_config(args)
data_location <- get_data_location(args)

pr <- read_parquet(file.path(data_location, "pr.parquet"))


ref_map <- list(
    "1v1 Random Map" = c(45, 55),
    "Team Random Map" = c(47, 53)
)

assert_that(
    config$filter$leaderboard %in% names(ref_map),
    msg = "Leaderboard doesn't have a reference value defined"
)

reference_lines <- ref_map[[config$filter$leaderboard]]




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

wrbt <- read_parquet(file.path(data_location, "wr_boot_raw.parquet"))

abs_point_est <- mean(abs(50 - wr$wr))

abs_ci <- wrbt %>%
    mutate(abdiff = abs(50 - wr * 100)) %>%
    group_by(id) %>%
    summarise(mad = mean(abdiff), .groups = "drop") %>%
    summarise(
        lci = quantile(mad, 0.025),
        uci = quantile(mad, 0.975)
    )


abs_string <- sprintf(
    "Abs Mean Diff: %5.2f%% [%5.2f%%, %5.2f%%]",
    round(abs_point_est, 4),
    round(abs_ci$lci, 4),
    round(abs_ci$uci, 4)
)

pdat <- wr %>%
    arrange(desc(est)) %>%
    mutate(civ = fct_inorder(civ)) %>%
    select(civ, lci, uci, wr = est)


OUTPUT_ID <- "civ_wrNaive"


p <- ggplot(data = pdat, aes(x = civ, group = civ, ymin = lci, ymax = uci, y = wr)) +
    geom_hline(yintercept = 50, col = "red", alpha = 0.65) +
    geom_hline(yintercept = reference_lines, col = "blue", alpha = 0.65, lty = 2) +
    geom_errorbar(width = 0.3) +
    geom_point() +
    theme_bw() +
    theme(
        axis.text.x = element_text(angle = 50, hjust = 1),
        plot.caption = element_text(hjust = 0)
    ) +
    annotate("text", y = max(wr$wr) * 1.03, x = Inf, label = abs_string, hjust = 1.05, size = 3) +
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



###############################
#
# Naive Win Rates vs Play Rates
#
###############################



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
    geom_hline(yintercept = reference_lines, col = "blue", alpha = 0.65, lty = 2) +
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



###############################
#
# Averaged Win Rates vs Play Rates
#
###############################




OUTPUT_ID <- "civ_wrAvg_playrate"

p2 <- plot_pr_wr(wr, pr, OUTPUT_ID)

save_plot(
    args = args,
    p = p2,
    id = OUTPUT_ID,
    type = "standard"
)


set_log(get_output_location(args), "win_rates")



