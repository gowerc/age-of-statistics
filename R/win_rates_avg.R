

data_wr_avg <- function(mcoef) {

    civlist <- mcoef$civlist
    coefs <- mcoef$coefs
    coefs_names <- names(coefs)
    covmat <- mcoef$vcov

    trans <- matrix(nrow = length(civlist), ncol = length(coefs))
    rownames(trans) <- civlist

    for (i in seq_along(civlist)) {
        civ <- civlist[i]
        v1 <- stringr::str_detect(coefs_names, paste0("^", civ, "_")) * 1
        v2 <- stringr::str_detect(coefs_names, paste0("_", civ, "$")) * 1
        trans[i, ] <- v1 - v2
    }

    trans <- trans / length(civlist)

    tibble(
        civ_name = civlist,
        lp = as.vector(trans %*% matrix(ncol = 1, coefs)),
        se = sqrt(diag(trans %*% covmat %*% t(trans))),
    ) %>%
        mutate(
            lci = invlogit(lp - 1.96 * se) * 100,
            est = invlogit(lp) * 100,
            uci = invlogit(lp + 1.96 * se) * 100,
            wr = est
        )
}



plot_wr_avg <- function(dat) {

    pdat <- dat %>%
        arrange(desc(est)) %>%
        mutate(coef = fct_inorder(civ_name)) %>%
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

    output$new(plot = p, data = pdat)
}
