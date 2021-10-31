

data_pr <- function(matchmeta, players){
    players2 <- players %>% semi_join(matchmeta, by= "match_id")
    players2 %>%
        mutate(bign = n()) %>% 
        group_by(civ_name) %>% 
        summarise(
            n = n(),
            bign = unique(bign),
            pr = n/bign * 100,
            pr_format = sprintf("%5.2f %%", pr)
        )
}



plot_pr <- function(dat) {
    footnotes <- c(
        "The red line represents the hypothetical play rate if civs were picked at random"
    ) %>%
        as_footnote()

    prdat <- dat %>%
        arrange(desc(n)) %>%
        mutate(civ_name = fct_inorder(civ_name)) %>%
        select(civ = civ_name, pr)

    p <- ggplot(data = prdat, aes(y = pr, x = civ)) +
        geom_bar(stat = "identity") +
        geom_hline(yintercept = 1 / nrow(prdat) * 100, col = "red") +
        theme_bw() +
        scale_y_continuous(breaks = pretty_breaks(10), expand = expansion(c(0, 0.06))) +
        theme(
            axis.text.x = element_text(angle = 50, hjust = 1),
            plot.caption = element_text(hjust = 0)
        ) +
        labs(caption = footnotes) +
            ylab("Play Rate (%)") +
            xlab("")

    output$new(plot = p, data = prdat)
}


plot_pr_wr <- function(wr, pr) {
    assert_that(
        nrow(wr) == nrow(pr)
    )

    pdat <- wr %>%
        inner_join(select(pr, civ_name, pr), by = "civ_name") %>%
        select(civ = civ_name, wr, pr)

    footnotes <- c(
        ""
    ) %>%
        as_footnote()

    p <- ggplot(data = pdat, aes(y = pr, x = wr, label = civ)) +
        geom_point() +
        theme_bw() +
        scale_y_continuous(breaks = pretty_breaks(10)) +
        scale_x_continuous(breaks = pretty_breaks(10)) +
        theme(
            plot.caption = element_text(hjust = 0)
        ) +
        geom_text_repel(min.segment.length = unit(0.1, "lines"), alpha = 0.7) +
        labs(caption = footnotes) +
        ylab("Play Rate (%)") +
        xlab("Win Rate (%)") +
        geom_vline(xintercept = 50, col = "red", alpha = 0.65) +
        geom_hline(yintercept = 1 / nrow(pr) * 100, col = "red", alpha = 0.65)
    
    output$new(plot = p, data = pdat)
}



plot_pr_civ1 <- function(matchmeta, players, lower_limit = 30) {

    players2 <- players %>% semi_join(matchmeta, by= "match_id")

    n_total_players <- length(unique(players2$profile_id))

    play_counts <- players2 %>%
        group_by(profile_id) %>%
        tally() %>%
        filter(n >= lower_limit)

    play_counts_civ <- players2 %>%
        semi_join(play_counts, by = "profile_id") %>%
        group_by(profile_id, civ_name) %>%
        tally() %>%
        group_by(profile_id) %>%
        mutate(bign = sum(n)) %>%
        ungroup() %>%
        mutate(pcent = n / bign * 100)


    pdat <- play_counts_civ %>%
        arrange(profile_id, desc(pcent)) %>%
        group_by(profile_id) %>%
        filter(row_number() == 1) %>%
        mutate(pcent_cat = cut(pcent, seq(0, 100, 10))) %>%
        group_by(pcent_cat) %>%
        tally() %>%
        ungroup() %>%
        mutate(p = sprintf("%4.1f%%", n / sum(n) * 100)) %>%
        mutate(yadj = n + max(n) / 50)


    footnotes <- c(
        sprintf(
            "Only includes %s / %s players who have played more than %s games", 
            nrow(play_counts),
            n_total_players,
            lower_limit
        )
    ) %>%
        as_footnote()


    p <- ggplot(data = pdat, aes(x = pcent_cat, y = n)) +
        geom_bar(stat = "identity") +
        geom_text(aes(label = p, y = yadj)) +
        theme_bw() +
        scale_y_continuous(breaks = pretty_breaks(8), expand = expansion(c(0, 0.05))) +
        xlab("Play Rate of Most Used Civ") +
        ylab("Number of Players") +
        theme(
            plot.caption = element_text(hjust = 0),
            axis.text.x = element_text(hjust = 1, angle = 35)
        ) +
        labs(caption = footnotes)

    pdat2 <- pdat %>% select(percent_group = pcent_cat, count = n, percent = p)

    output$new(plot = p, data = pdat2)
}





plot_wr_ewr <- function(wr, pr) {

    assert_that(
        nrow(wr) == nrow(pr)
    )

    boxtrans <- function(x, y) {
        box_cox_num <- MASS::boxcox(x ~ y, data = data.frame(x = x, y = y), plotit = FALSE)
        lambda <- box_cox_num$x[which.max(box_cox_num$y)]
        if (lambda == 0) {
            return(log(x))
        } else {
            return(((x^lambda) - 1) / lambda)
        }
    }


    dat <- wr %>%
        inner_join(select(pr, civ_name, pr), by = "civ_name") %>%
        mutate(box_pr = boxtrans(pr, wr))


    mod <- MASS::rlm(wr ~ box_pr, data = dat, psi = MASS::psi.huber)

    dat2 <- dat %>%
        mutate(preds = predict(mod)) %>%
        mutate(bias = preds - wr) %>%
        arrange(bias) %>%
        mutate(civ_name = fct_inorder(civ_name))


    footnotes <- c(
        "Negative values indicate that a civilisation is 'underestimated'<br/>",
        "Positive values indicate that a civilisation is 'overestimated'<br/>",
        "Expected win rates are calculated by fitting a robust linear model with",
        "box-cox transformed play rates as the predcitor <br/>",
        "The reference lines are arbitrarily set at -2.5 and 2.5 to provide a visual aid"
    ) %>%
        as_footnote()


    p1 <- ggplot(data = dat2, aes(y = bias, x = civ_name)) +
        geom_bar(stat = "identity") +
        theme_bw() +
        scale_y_continuous(breaks = pretty_breaks(10)) +
        geom_hline(yintercept = c(-2.5, 2.5), col = "blue", alpha = 0.65) +
        theme(
            axis.text.x = element_text(angle = 50, hjust = 1),
            plot.caption = element_text(hjust = 0)
        ) +
        labs(caption = footnotes) +
        ylab("Difference in Expected Win Rate and Observed Win Rate") +
        xlab("")


    footnotes <- c(
        "Expected win rates are calculated by fitting a robust linear model with",
        "box-cox transformed play rates as the predcitor"
    ) %>%
        as_footnote()


    p2 <- ggplot(data = dat2, aes(y = wr, x = preds, label = civ_name)) +
        geom_point() +
        theme_bw() +
        scale_y_continuous(breaks = pretty_breaks(10)) +
        labs(caption = footnotes) +
        ylab("Observed Win Rate") +
        xlab("Expected Win Rate") +
        geom_text_repel(min.segment.length = unit(0.1, "lines"), alpha = 0.7) +
        geom_abline(slope = 1, intercept = 0, col = "red", alpha = 0.65) +
        geom_vline(xintercept = 50, col = "blue", alpha = 0.4) +
        geom_hline(yintercept = 50, col = "blue", alpha = 0.4) +
        theme(plot.caption = element_text(hjust = 0))

    dat_p1 <- dat2 %>% select(civ = civ_name, wr, bias)
    dat_p2 <- dat2 %>% select(civ = civ_name, wr, pred_wr = preds)

    list(
        output$new(plot = p1, data = dat_p1),
        output$new(plot = p2, data = dat_p2)
    )

}


