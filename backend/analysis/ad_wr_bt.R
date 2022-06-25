library(arrow)
library(dplyr)
library(fastglm)
pkgload::load_all()


# args <- get_args("p02_v02", "rm_solo_open")
args <- get_args()
data_location <- get_data_location(args)

matchmeta <- read_parquet(
    file.path(data_location, "matchmeta.parquet")
)

players <- read_parquet(
    file.path(data_location, "players.parquet")
)



team_1 <- players %>%
    filter(team == 1) %>%
    select(match_id, civ) %>%
    mutate(val = 1)



team_2 <- players %>%
    filter(team == 2) %>%
    select(match_id, civ) %>%
    mutate(val = -1)


assert_that(
    nrow(team_1) == nrow(players) / 2,
    nrow(team_2) == nrow(players) / 2
)



civs <- bind_rows(team_1, team_2) %>%
    group_by(match_id, civ) %>%
    summarise(val = sum(val), .groups = "drop") %>%
    spread(civ, val, fill = 0)


dat_check <- civs %>%
    gather(key, val, -match_id) %>%
    group_by(match_id) %>%
    summarise(x = sum(val))

assert_that(
    all(dat_check$x == 0)
)

match_result <- matchmeta %>%
    mutate(result = if_else(winning_team == 1, 1, 0)) %>%
    select(match_id, rating_diff_mean, result)

mod_dat <- civs %>%
    left_join(match_result, by = "match_id") %>%
    select(-match_id, -Vikings)


mod_matrix <- mod_dat %>%
    select(-result) %>%
    as.matrix()


mod <- fastglm(
    x = mod_matrix,
    y = mod_dat$result,
    method = 2,
    family = binomial()
)

dat <- tibble(
    civ = names(mod$coefficients),
    est = mod$coefficients,
    se = mod$se
) %>%
    filter(civ != "rating_diff_mean")

add_vikings <- tibble(
    civ = "Vikings",
    est = 0,
    se = 0
)

ret <- bind_rows(dat, add_vikings) %>%
    mutate(lci = est - 1.96 * se) %>%
    mutate(uci = est + 1.96 * se)


write_parquet(
    ret,
    file.path(data_location, "wr_bt.parquet")
)
