


prep_wr_naive <- function(matchmeta, players) {
    matchmeta_slim <- matchmeta %>%
        select(match_id, winning_team, rating_diff_mean, rating_mean, match_length_igm)

    results <- players %>%
        inner_join(matchmeta_slim, by = "match_id") %>%
        mutate(rating_diff_mean = if_else(team == 1, rating_diff_mean, -rating_diff_mean)) %>%
        mutate(won = (team == winning_team) * 1)

    return(results)
}


#' @import fastglm
data_wr_naive <- function(results) {

    design <- model.matrix(
        ~ 0 + civ + rating_diff_mean,
        data = results
    )

    outcome <- results$won

    mod <- fastglm(
        x = design,
        y = outcome,
        method = 2,
        family = binomial()
    )


    moddat <- tibble(
        coef = names(coef(mod)),
        lp = coef(mod),
        se = mod$se
    )

    moddat2 <- moddat %>%
        filter(coef != "rating_diff_mean") %>%
        mutate(coef = str_remove(coef, "^civ")) %>%
        mutate(
            est = invlogit(lp) * 100,
            lci = invlogit(lp - 1.96 * se) * 100,
            uci = invlogit(lp + 1.96 * se) * 100,
            wr = est
        ) %>% 
        rename(civ = coef)

    return(moddat2)
}
