
data_wr_naive <- function(matchmeta, players){

    players2 <- players %>% semi_join(matchmeta, by = "match_id")

    results <- players2 %>% 
        left_join(select(matchmeta, match_id, winning_team, rating_diff_mean), by = "match_id") %>%
        mutate(rating_diff_mean = if_else(team == 1, rating_diff_mean, -rating_diff_mean)) %>%
        mutate(won = (team == winning_team) * 1)


    mod <- glm(
        won ~ 0 + civ_name + rating_diff_mean,
        data = results,
        family = binomial()
    )


    moddat <- tibble(
        coef = names(coef(mod)),
        lp = coef(mod),
        se = sqrt(diag(vcov(mod)))
    )

    moddat2 <- moddat %>%
        filter(coef != "rating_diff_mean") %>% 
        mutate(coef = str_remove(coef, "^civ_name")) %>% 
        mutate(
            est = invlogit(lp) * 100,
            lci = invlogit(lp - 1.96 * se) * 100,
            uci = invlogit(lp + 1.96 * se) * 100,
            wr = est
        ) %>% 
        rename(civ_name = coef)

    return(moddat2)
}




plot_wr_naive <- function(dat) {

    pdat <- dat %>%
        arrange(desc(est)) %>%
        mutate(civ = fct_inorder(civ_name)) %>%
        select(civ, lci, uci, wr = est)


    footnotes <- c(
        "Win rates have been calculated as the # of wins / # of games.<br/>",
        "Win rates have been adjusted for difference in mean Elo.<br/>",
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
