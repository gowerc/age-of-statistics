
data_wr_naive <- function(matchmeta, players){

    players2 <- players %>%
        semi_join(matchmeta, by = "match_id")

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