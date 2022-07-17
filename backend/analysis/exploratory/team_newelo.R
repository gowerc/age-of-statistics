
devtools::load_all()
library(dplyr)
library(tidyr)
library(data.table)
library(dtplyr)
library(assertthat)
library(lubridate)
library(arrow)
library(glue)


args <- get_args("p03_v07", "rm_team_all")
data_location <- get_data_location(args)


matchmeta <- read_parquet(file.path(data_location, "matchmeta.parquet"))
players <- read_parquet(file.path(data_location, "players.parquet"))




elo_sd <- players %>%
    as.data.table() %>%
    group_by(match_id, team) %>%
    summarise(
        n = n(),
        team_elo = sd(rating),
        .groups = "drop"
    ) %>%
    mutate(team = paste0("team_", team)) %>%
    as_tibble() %>%
    spread(team, team_elo) %>%
    mutate(elo_sd_diff = team_1 - team_2)


get_pval <- function(players, matchmeta, get_team_elo, id) {

    elo_diff <- players %>%
        group_by(match_id, team) %>%
        summarise(team_elo = get_team_elo(rating), .groups = "drop") %>%
        mutate(team = paste0("team_", team)) %>%
        as_tibble() %>%
        spread(team, team_elo) %>%
        mutate(elo_diff = team_1 - team_2)

    mdat <- matchmeta %>%
        select(match_id, winning_team) %>%
        inner_join(elo_diff %>% select(match_id, elo_diff), by = "match_id") %>%
        inner_join(elo_sd %>% select(match_id, elo_sd_diff), by = "match_id") %>%
        mutate(won = winning_team == 1)

    mod <- glm(
        data = mdat,
        formula = won ~ elo_diff + elo_sd_diff,
        family = binomial()
    )

    broom::tidy(mod) %>%
        mutate(name = id)

}


get_pval(
    players = players,
    matchmeta = matchmeta,
    get_team_elo = mean,
    id = "mean"
)


get_pval(
    players = players,
    matchmeta = matchmeta %>% filter(rating_mean <= 2200),
    get_team_elo = mean,
    id = "mean"
)

get_pval(
    players = players,
    matchmeta =  matchmeta %>% filter(rating_mean > 2200),
    get_team_elo = mean,
    id = "mean"
)






encap_get_rating_skew <- function(k) {
    function(rating) {
        scale <- 400
        srate <- rating / scale
        log(mean(k^srate), base = k) * scale
    }
}





get_res <- function(k, matchmeta) {
    get_rating_skew <- encap_get_rating_skew(k)
    x <- get_pval(
        players = players,
        matchmeta = matchmeta,
        get_team_elo = get_rating_skew,
        id = "get_rating_skew"
    ) %>%
        filter(term == "elo_sd_diff") %>%
            pull(p.value)
    -x
}


r_all <- optimise(
    f = get_res,
    interval = c(1.001, 6),
    matchmeta = matchmeta
)

r_up <- optimise(
    f = get_res,
    interval = c(1.001, 6),
    matchmeta = matchmeta %>% filter(rating_mean > 2200)
)

r_low <- optimise(
    f = get_res,
    interval = c(1.001, 6),
    matchmeta = matchmeta %>% filter(rating_mean <= 2200)
)







encap_get_rating_mercy <- function(k) {
    function(rating) {
        k * log(mean(2 ^ (rating / k)), base = 2)
    }
}

get_res_mercy <- function(k, matchmeta) {
    get_rating_skew <- encap_get_rating_mercy(k)
    x <- get_pval(
        players = players,
        matchmeta = matchmeta,
        get_team_elo = get_rating_skew,
        id = "get_rating_skew"
    ) %>%
        filter(term == "elo_sd_diff") %>%
            pull(p.value)
    -x
}


r_all_mercy <- optimise(
    f = get_res_mercy,
    interval = c(300, 2000),
    matchmeta = matchmeta
)

r_up_mercy <- optimise(
    f = get_res_mercy,
    interval = c(300, 2000),
    matchmeta = matchmeta %>% filter(rating_mean > 2200)
)

r_low_mercy <- optimise(
    f = get_res_mercy,
    interval = c(300, 2000),
    matchmeta = matchmeta %>% filter(rating_mean <= 2200)
)





get_team_rating <- encap_get_rating_skew(1.282039)
get_team_rating_mercy <- encap_get_rating_mercy(1116.01)

sumit <- function(n_rating) {
    tibble(
        rating = paste0(n_rating, collapse = ", "),
        mean_elo = mean(n_rating),
        new_elo_mine = get_team_rating(n_rating),
        new_elo_mercy = get_team_rating_mercy(n_rating)
    )
}


map_df(
    list(
        c(1000, 1000, 1000),
        c(1200, 1000, 800),
        c(2200, 2000, 1800),
        c(1400, 1000, 600),
        c(3000, 500, 400)
    ),
    sumit
)
