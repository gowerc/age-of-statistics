

data_cvc <- function(matchmeta, players) {
    result <- matchmeta %>%
        select(match_id, winning_team, rating_diff_mean) %>%
        mutate(rating_diff_mean = if_else(winning_team == 1, rating_diff_mean, -rating_diff_mean))


    players2 <- players %>%
        inner_join(result, by = "match_id")


    civlist <- players$civ_name %>% unique
    civlist <- civlist[order(civlist)]

    ridge <- cross_df(list(civ_win = civlist, civ_lose = civlist)) %>%
        mutate(match_id = paste0("ridge", 1:n()))


    team_win <- players2 %>%
        filter(team == winning_team) %>%
        select(match_id, civ_win = civ_name)


    team_lose <- players2 %>%
        filter(team != winning_team) %>%
        select(match_id, civ_lose = civ_name)


    assert_that(
        nrow(team_win) == nrow(team_lose)
    )


    res <- team_win %>%
        left_join(team_lose, by = "match_id") %>%
        bind_rows(ridge) %>%
        filter(civ_win != civ_lose) %>%
        mutate(civ_win = factor(civ_win, levels = civlist)) %>%
        mutate(civ_lose = factor(civ_lose, levels = civlist)) %>%
        mutate(swap = as.numeric(civ_win) > as.numeric(civ_lose)) %>%
        mutate(civ1 = if_else(swap, civ_lose, civ_win)) %>%
        mutate(civ2 = if_else(swap, civ_win, civ_lose)) %>%
        mutate(term = sprintf("%s_%s", civ1, civ2)) %>%
        mutate(val = if_else(swap, -1, 1)) %>%
        group_by(match_id) %>%
        mutate(val = val / n()) %>%
        ungroup() %>%
        group_by(match_id, term) %>%
        summarise(val = sum(val), .groups = "drop")

    res2 <- res %>%
        select(match_id, term, val) %>%
        spread(term, val, fill = 0) %>%
        left_join(select(result, match_id, rating_diff_mean), by = "match_id") %>%
        mutate(rating_diff_mean = if_else(is.na(rating_diff_mean), 0, rating_diff_mean)) %>%
        select(-match_id) %>%
        mutate(result = 1)


    mod <- glm(
        data = res2,
        formula = result ~ 0 + .
    )

    list(
        coefs = coef(mod),
        vcov = vcov(mod),
        civlist = civlist
    )
}


data_cvc_matrix <- function(mcoef) {
    civlist <- mcoef$civlist
    coefs <- mcoef$coefs
    coefs2 <- coefs[names(coefs) != "rating_diff_mean"]
    coefs_names <- names(coefs2)

    cvc <- matrix(nrow = length(civlist), ncol = length(civlist))
    rownames(cvc) <- civlist
    colnames(cvc) <- civlist

    cvc[lower.tri(cvc)] <- 1 - invlogit(coefs2)
    tcvc <- t(cvc)
    tcvc[lower.tri(tcvc)] <- invlogit(coefs2)
    cvc <- t(tcvc)
    diag(cvc) <- 0.5
    return(cvc)
}



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



plot_dendro_wr <- function(cvc_mat) {

    # hmod <- hclust(
    #     as.dist(1 - lsa::cosine(cvc_mat - 0.5)),
    #     method = "ward.D2"
    # )

    hmod <- hclust(
        as.dist(1 - lsa::cosine(cvc_mat - 0.5)),
        method = "complete"
    )

    # hmod <- hclust(
    #     dist(cvc_mat - 0.5, method = "euclidean"),
    #     method = "ward.D2"
    # )

    # hmod <- hclust(
    #     dist(cvc_mat - 0.5, method = "manhattan"),
    #     method = "ward.D2"
    # )

    dhc <- as.dendrogram(hmod)

    ddata <- ggdendro::dendro_data(dhc, type = "rectangle") %>%
        ggdendro::segment() %>%
        as_tibble() %>%
        mutate(nyend = if_else(yend == 0, y - 0.1, yend))

    ldata <- ddata %>%
        filter(yend == 0) %>%
        mutate(labs = hmod$labels[hmod$order])


    recursive_get_group <- function(start, start_is_y, dat, grpdat = NULL) {
        if (is.null(grpdat)) grpdat <- tibble::tibble(id = numeric(), grp = numeric())

        if(start_is_y) {
            next_start <- dat %>%
                filter(x != xend) %>%
                left_join( select(start, yend, grp, yx = x), by = "yend") %>%
                filter( x == yx | xend == yx) %>%
                filter(!is.na(grp))
        } else {
            next_start <- dat %>%
                filter(y != yend) %>%
                left_join(select(start, xend, grp, xy = y), by = "xend") %>%
                filter( y == xy | yend == xy) %>%
                filter(!is.na(grp))
        }
        if (nrow(next_start) == 0) {
            return(grpdat)
        }

        grpdat <- grpdat %>%
            bind_rows(select(next_start, id, grp))

        return(recursive_get_group(next_start, !start_is_y, dat, grpdat))
    }

    ddata2 <- ddata %>%
        mutate(id = row_number())

    cut <- 0.01
    ngroups <- 99
    while (ngroups > 8) {
        init_grp <- ddata2 %>%
            filter(x == xend) %>%
            filter(y >= cut) %>%
            filter(!yend %in% y) %>%
            mutate(grp = row_number())
        ngroups <- length(unique(init_grp$grp))
        cut <- cut + 0.005
    }

    grpclass <- recursive_get_group(init_grp, TRUE, ddata2)

    ddata3 <- ddata2 %>%
        left_join(grpclass, by = "id") %>%
        mutate(grp = factor(grp))


    footnotes <- c(
        "Clusters are formed using complete linkage on the cosine distance between civilisation v civilisation win rates.<br/>",
        "Civilisations are coloured based upon their group.<br/>",
        "Groups are formed by applying an arbitrary cutoff that ensures there are no more than 8 unique groups."
    ) %>%
        as_footnote()

    p <- ggplot(ddata3, aes(x = x, y = y, xend = xend, yend = nyend, col = grp)) +
        geom_segment() +
        theme_bw() +
        scale_x_continuous(breaks = c(), labels = c()) +
        scale_y_continuous(expand = expansion(mult = c(0.25, 0.05)), breaks = pretty_breaks(10)) +
        xlab("") +
        ylab("Cosine Distance") +
        geom_text(
            aes(label = labs, y = nyend, x = x),
            inherit.aes = FALSE,
            data = ldata,
            hjust = 1.1,
            angle = 90
        ) +
        theme(
            legend.position = "none",
            axis.text.x = element_text(angle = 50, hjust = 1),
            plot.caption = element_text(hjust = 0)
        ) +
        labs(caption = footnotes)

    cvc_dat <- as_tibble(cvc_mat)
    cvc_dat$civ <- rownames(cvc_mat)
    output$new(
        plot = p,
        data = cvc_dat
    )
}
