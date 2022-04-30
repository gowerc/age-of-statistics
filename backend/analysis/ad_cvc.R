devtools::load_all()
library(dplyr)
library(assertthat)
library(lubridate)
library(arrow)
library(purrr)
library(tidyr)


data_location <- get_data_location()


matchmeta <- read_parquet(
    file.path(data_location, "matchmeta.parquet")
)

players <- read_parquet(
    file.path(data_location, "players.parquet")
)

result <- matchmeta %>%
    select(match_id, winning_team, rating_diff_mean) %>%
    mutate(rating_diff_mean = if_else(winning_team == 1, rating_diff_mean, -rating_diff_mean))


players2 <- players %>%
    inner_join(result, by = "match_id")


civlist <- players$civ %>% unique
civlist <- civlist[order(civlist)]

ridge <- cross_df(list(civ_win = civlist, civ_lose = civlist)) %>%
    mutate(match_id = paste0("ridge", 1:n()))


team_win <- players2 %>%
    filter(team == winning_team) %>%
    select(match_id, civ_win = civ)


team_lose <- players2 %>%
    filter(team != winning_team) %>%
    select(match_id, civ_lose = civ)


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


coefs <- coef(mod)


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



mcoef <- list(
    coefs = coefs,
    vcov = vcov(mod),
    civlist = civlist,
    cvc = cvc
)

saveRDS(mcoef, file.path(data_location, "cvc.Rds"))
