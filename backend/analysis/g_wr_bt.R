library(arrow)
library(dplyr)
library(ggplot2)
library(scales)
library(forcats)
pkgload::load_all()


# args <- get_args("p02_v02", "rm_solo_open")
args <- get_args()
data_location <- get_data_location(args)


dat <- read_parquet(
    file.path(data_location, "wr_bt.parquet")
)

pr <- read_parquet(
    file.path(data_location, "pr.parquet")
)


assert_that(
    nrow(dat) == nrow(pr)
)


pdat <- dat %>%
    arrange(desc(est)) %>%
    mutate(civ = fct_inorder(civ))

refline_med <- median(pdat$est)
refline_margin <- refline_med + qlogis(c(0.45, 0.55))




####################################
#
# Win rate (bradly-terry) by Civ
#
#


OUTPUT_ID <- "civ_wr_bt"


p <- ggplot(data = pdat, aes(x = civ, group = civ, ymin = lci, ymax = uci, y = est)) +
    geom_errorbar(width = 0.3) +
    geom_point() +
    geom_hline(yintercept = refline_med, col = "red", alpha = 0.65) +
    geom_hline(yintercept = refline_margin, col = "blue", alpha = 0.65, lty = 2) +
    theme_bw() +
    theme(
        axis.text.x = element_text(angle = 50, hjust = 1),
        plot.caption = element_text(hjust = 0)
    ) +
    labs(caption = get_footnotes(OUTPUT_ID, args)) +
    scale_y_continuous(breaks = pretty_breaks(10)) +
    ylab("Bradley-Terry Score") +
    xlab("")


save_plot(
    args = args,
    p = p,
    id = OUTPUT_ID,
    type = "standard"
)






####################################
#
#  Win rate (bradly-terry) by play rate
#
#


OUTPUT_ID <- "civ_wr_pr_bt"


pdat <- dat %>%
    select(wr = est, civ) %>%
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
    labs(caption = get_footnotes(OUTPUT_ID, args)) +
    ylab("Bradley-Terry Score") +
    xlab("Play Rate (%)") +
    geom_hline(yintercept = refline_med, col = "red", alpha = 0.65) +
    geom_vline(xintercept = 1 / nrow(pr) * 100, col = "red", alpha = 0.65)


save_plot(
    args = args,
    p = p,
    id = OUTPUT_ID,
    type = "standard"
)



