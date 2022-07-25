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




###############################
#
# Averaged Win Rates
#
###############################

wr <- read_parquet(file.path(data_location, "wr_cvc_AVG.parquet")) %>%
    rename(est = med) %>%
    mutate(wr = est) %>%
    arrange(desc(est))


pdat <- wr  %>%
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

p2 <- plot_pr_wr(wr, pr, OUTPUT_ID, args)

save_plot(
    args = args,
    p = p2,
    id = OUTPUT_ID,
    type = "standard"
)


