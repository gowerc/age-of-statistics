




cross_wr_naive <- function(wr1, wr2, wr1_lb = "", wr2_lb = "") {

    pdat <- left_join(
        select(wr1$dat, civ_name, wr1 = est),
        select(wr2$dat, civ_name, wr2 = est),
        by = "civ_name"
    )

    footnotes <- c(
        "Win rates have been calculated as the # of wins / # of games.<br/>",
        "Win rates have been adjusted for difference in mean Elo."
    ) %>%
        as_footnote(add_cohort = FALSE)

    p <- ggplot(data = pdat, aes(y = wr2, x = wr1, label = civ_name)) +
        geom_point() +
        theme_bw() +
        scale_y_continuous(breaks = pretty_breaks(10)) +
        scale_x_continuous(breaks = pretty_breaks(10)) +
        theme(plot.caption = element_text(hjust = 0)) +
        labs(caption = footnotes) +
        ylab(wr2$lab) +
        xlab(wr1$lab) +
        geom_vline(xintercept = 50, col = "blue", alpha = 0.3) +
        geom_hline(yintercept = 50, col = "blue", alpha = 0.3) +
        geom_abline(intercept = 0 , slope = 1, col = "red", alpha = 0.65) +
        geom_text_repel(min.segment.length = unit(0.1, "lines"), alpha = 0.7)

    output$new(
        plot = p,
        data = pdat %>% select(civ = civ_name, y_wr = wr2, x_wr = wr1)
    )
}
