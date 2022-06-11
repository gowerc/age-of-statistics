
library(dplyr)
library(scales)
library(forcats)
library(ggplot2)
library(arrow)
pkgload::load_all()


data_location <- get_data_location()
# data_location <- "./data/processed/p02_v02/rm_solo_all"
dat <- read_parquet(file.path(data_location, "wr_boot.parquet"))



pdat <- dat %>%
    arrange(rank) %>%
    mutate(civ = fct_inorder(civ))

footnotes <- c(
    "Win rates have been adjusted for difference in mean Elo.<br/>",
    "The error bars represent the 95% confidence interval.<br/>",
    "Confidence intervals were calculated by bootstrap resampling"
) %>%
    as_footnote()



get_breaks_0to1 <- function(...) {
    breaks <- breaks_pretty(10)(...)
    breaks[breaks == 0] <- 1
    return(breaks)
}

p <- ggplot(data = pdat, aes(x = civ, group = civ, ymin = lci_rank, ymax = uci_rank, y = rank)) +
    geom_errorbar(width = 0.3) +
    geom_point() +
    theme_bw() +
    theme(
        axis.text.x = element_text(angle = 50, hjust = 1),
        plot.caption = element_text(hjust = 0)
    ) +
    labs(caption = footnotes) +
    ylab("Win Rate (Rank)") +
    xlab("") +  
    scale_y_reverse(breaks = get_breaks_0to1)



save_plot(
    p = p,
    id = "civ_wr_rank",
    type = "standard"
)


