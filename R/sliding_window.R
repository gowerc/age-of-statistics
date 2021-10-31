

get_slide_smoothed <- function(CIV, dat) {
    dat2 <- dat %>%
        filter(civ_name == CIV)


    # fit GAM model
    lci_m <- mgcv::gam(lci ~ s(y), data = dat2)
    med_m <- mgcv::gam(est ~ s(y), data = dat2)
    uci_m <- mgcv::gam(uci ~ s(y), data = dat2)

    pdat <- tibble(
        y = dat2$y,
        civ = dat2$civ_name,
        lci = predict(lci_m, newdata = data.frame(y = y)),
        med = predict(med_m, newdata = data.frame(y = y)),
        uci = predict(uci_m, newdata = data.frame(y = y)),
    )
    return(pdat)
}



get_slide_wr_elo <- function(y, lb, ub, matchmeta, players) {
    matchmeta2 <- matchmeta %>%
        filter(rating_mean >= lb, rating_mean <= ub)

    data_wr_naive(matchmeta2, players) %>%
        mutate(y = y) %>%
        mutate(limit_upper = ub, limit_lower = lb)
}



plot_slide_wr_elo <- function(matchmeta, players) {

    cuts <- tibble(
        cy = seq(0, 1, by = 0.01),
        clb = cy - 0.1,
        cub = cy + 0.1,
    ) %>%
        filter(clb >= 0, cub <= 1) %>% 
        mutate(
            lb = quantile(matchmeta$rating_mean, clb),
            y = quantile(matchmeta$rating_mean, cy),
            ub = quantile(matchmeta$rating_mean, cub)
        )


    res <- pmap_df(
        list(
            y = cuts$y,
            lb = cuts$lb,
            ub = cuts$ub
        ),
        get_slide_wr_elo,
         matchmeta = matchmeta,
         players = players
    )

    civlist <- res %>%
        arrange(civ_name) %>%
        pull(civ_name) %>%
        unique()


    pdat <- map_df(civlist, get_slide_smoothed, res) %>%
        select(civ, med, lci, uci, elo = y)

    footnotes <- c(
        "Win rates are calculated at each point X after filtering the data to",
        "only include matches where mean Elo is within +- 0.1 percentiles of X.<br/>",
        "Win rates have been calculated as the # of wins / # of games. ",
        "Win rates have been adjusted for difference in mean Elo.<br/>",
        "The error bars represent the 95% confidence interval. ",
        "All lines have been smoothed using a GAM."
    ) %>%
        as_footnote()

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
        labs(caption = footnotes)

    output$new(plot = p, data = pdat)
}




get_slide_wr_gamelength <- function(y, lb, ub, matchmeta, players) {
    matchmeta2 <- matchmeta %>%
        filter(match_length_igm >= lb, match_length_igm <= ub)

    data_wr_naive(matchmeta2, players) %>%
        mutate(y = y) %>%
        mutate(limit_upper = ub, limit_lower = lb)
}


plot_slide_wr_gamelength <- function(matchmeta, players) {
    glen <- matchmeta$match_length_igm
    lower_limit <- floor(quantile(glen, 0.1) / 5) * 5
    upper_limit <- ceiling(quantile(glen, 0.85) / 5) * 5

    y <- seq(lower_limit, upper_limit, by = 1)

    res <- pmap_df(
        list(y = y, lb = y - 5, ub = y + 5),
        get_slide_wr_gamelength,
        matchmeta = matchmeta,
        players = players
    )


    civlist <- res %>%
        arrange(civ_name) %>%
        pull(civ_name) %>%
        unique()


    pdat <- map(civlist, get_slide_smoothed, res) %>%
        bind_rows() %>%
        select(civ, med, lci, uci, len = y)

    footnotes <- c(
        "Win rates are calculated at each point X after filtering the data to",
        "only include matches where the game length was within +- 5  in-game minutes of X.<br/>",
        "Win rates have been calculated as the # of wins / # of games. ",
        "Win rates have been adjusted for difference in mean Elo.<br/>",
        "The error bars represent the 95% confidence interval.",
        "All lines have been smoothed using a GAM."
    ) %>%
        as_footnote()

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
        labs(caption = footnotes)

    output$new(plot = p, data = pdat)
}





get_slide_pr_elo <- function(y, lb, ub, matchmeta, players) {
    matchmeta2 <- matchmeta %>%
        filter(rating_mean >= lb, rating_mean <= ub)

    data_pr(matchmeta2, players) %>%
        mutate(y = y) %>%
        mutate(limit_upper = ub, limit_lower = lb)
}



plot_slide_pr_elo <- function(matchmeta, players) {

    cuts <- tibble(
        cy = seq(0, 1, by = 0.01),
        clb = cy - 0.1,
        cub = cy + 0.1,
    ) %>%
        filter(clb >= 0, cub <= 1) %>% 
        mutate(
            lb = quantile(matchmeta$rating_mean, clb),
            y = quantile(matchmeta$rating_mean, cy),
            ub = quantile(matchmeta$rating_mean, cub)
        )


    res <- pmap_df(
        list(
            y = cuts$y,
            lb = cuts$lb,
            ub = cuts$ub
        ),
        get_slide_pr_elo,
         matchmeta = matchmeta,
         players = players
    )

    civlist <- res %>%
        arrange(civ_name) %>%
        pull(civ_name) %>%
        unique()


    footnotes <- c(
        "Play rates are calculated at each point X after filtering the data to",
        "only include matches where mean Elo is within +- 0.1 percentiles of X.<br/>"
    ) %>%
        as_footnote()

    p <- ggplot(data = res, aes(x = y, group = civ_name, y = pr)) +
        geom_line(col = "#383838") +
        theme_bw() +
        scale_y_continuous(breaks = pretty_breaks(5)) +
        scale_x_continuous(breaks = pretty_breaks(5)) +
        geom_hline(yintercept = 1/length(civlist) * 100, col = "red", alpha = 0.8) +
        ylab("Play Rate (%)") +
        xlab("Elo") +
        facet_wrap(~civ_name) +
        theme(
            legend.position = "none",
            axis.text.x = element_text(angle = 50, hjust = 1),
            plot.caption = element_text(hjust = 0)
        ) +
        labs(caption = footnotes)

    output$new(
        plot = p,
        data = res %>% select(civ = civ_name, elo = y, pr, n)
    )
}
