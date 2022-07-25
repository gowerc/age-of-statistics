
plot_pr_wr <- function(wr, pr, id, args) {
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
