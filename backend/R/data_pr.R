

data_pr <- function(matchmeta, players) {

    players2 <- players %>%
        semi_join(matchmeta, by = "match_id")

    dat <- players2 %>%
        mutate(bign = n()) %>%
        group_by(civ) %>%
        summarise(
            n = n(),
            bign = unique(bign),
            pr = n/bign * 100,
            pr_format = sprintf("%5.2f %%", pr)
        )
    return(dat)
}