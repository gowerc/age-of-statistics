
# TODO



plot_cvc <- function(mcoef) {

    civlist <- mcoef$civlist
    coefs <- mcoef$coefs
    ses <- sqrt(diag(mcoef$vcov))[names(coefs) != "rating_diff_mean"]
    coefs2 <- coefs[names(coefs) != "rating_diff_mean"]

    civdat_1 <- tibble(
        civ1 = str_match(names(coefs2), "(.+)_(.+)")[, 2],
        civ2 = str_match(names(coefs2), "(.+)_(.+)")[, 3],
        coef = coefs2,
        se = ses
    )

    civdat_2 <- civdat_1 %>%
        mutate(
            temp = civ1,
            civ1 = civ2,
            civ2 = temp,
            coef = -coef
        ) %>%
        select(-temp)

    civdat <- bind_rows(civdat_1, civdat_2) %>%
        mutate(
            lci = invlogit(coef - 1.96 * se) * 100,
            est = invlogit(coef) * 100,
            uci = invlogit(coef + 1.96 * se) * 100
        )

    plots <- map(civlist, plot_cvc_individual, civdat = civdat)
    names(plots) <- civlist
    return(plots)
}





plot_cvc_individual <- function(civ, civdat) {

    pdat <- civdat %>%
        filter(civ1 == civ) %>%
        arrange(desc(est)) %>%
        mutate(coef = fct_inorder(civ2))


    footnotes <- c(
        "See methods section for details on how the win rates have been calculated.<br/>",
        "Win rates have been adjusted for difference in mean Elo.<br/>",
        "The error bars represent the 95% confidence interval."
    ) %>%
        as_footnote()


    p <- ggplot(data = pdat, aes(x = coef, group = coef, ymin = lci, ymax = uci, y = est)) +
        geom_hline(yintercept = 50, col = "red", alpha = 0.65) +
        geom_errorbar(width = 0.3) +
        geom_point() +
        theme_bw() +
        theme(
            axis.text.x = element_text(angle = 50, hjust = 1),
            plot.caption = element_text(hjust = 0)
        ) +
        labs(caption = footnotes, subtitle = sprintf("Civilisation: %s", civ)) +
        ylab("Win Rate (%)") +
        xlab("") +
        scale_y_continuous(breaks = pretty_breaks(10))

    output$new(
        plot = p,
        data = pdat %>% select(civ = coef, wr = est, lci, uci)
    )
}



