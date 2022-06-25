devtools::load_all()
library(dplyr)
library(ggplot2)
library(scales)
library(arrow)


# args <- get_args("p02_v02", "rm_solo_all")
args <- get_args()
data_location <- get_data_location(args)


pdat <- arrow::read_parquet(
    file = file.path(data_location, "ad_slide_WR_ELO.parquet")
)


OUTPUT_ID <- "slide_wrNaive_elo"


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
    labs(caption = get_footnotes(OUTPUT_ID, args))


save_plot(
    args = args,
    p = p,
    id = OUTPUT_ID,
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


OUTPUT_ID <- "slide_wrNaive_gamelength"

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
    labs(caption = get_footnotes(OUTPUT_ID, args))



save_plot(
    args = args,
    p = p,
    id = OUTPUT_ID,
    type = "square"
)




###############################
#
# Sliding Win Rate by greater than Game Length
#
###############################



pdat <- arrow::read_parquet(
    file = file.path(data_location, "ad_slide_WR_GGL.parquet")
)

OUTPUT_ID <- "slide_wrNaive_greatergamelength"

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
    labs(caption = get_footnotes(OUTPUT_ID, args))



save_plot(
    args = args,
    p = p,
    id = OUTPUT_ID,
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


OUTPUT_ID <- "slide_playrate_elo"

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
    labs(caption = get_footnotes(OUTPUT_ID, args))


save_plot(
    args = args,
    p = p,
    id = OUTPUT_ID,
    type = "square"
)

set_log(get_output_location(args), "sliding_window")
