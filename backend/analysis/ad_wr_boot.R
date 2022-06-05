devtools::load_all()
library(dplyr)
library(assertthat)
library(lubridate)
library(arrow)
library(purrr)
library(tidyr)
library(fastglm)
library(parallel)


data_location <- get_data_location()
# data_location <- "./data/processed/p02_v02/rm_solo_all"

matchmeta <- read_parquet(
    file.path(data_location, "matchmeta.parquet")
)

players <- read_parquet(
    file.path(data_location, "players.parquet")
)


get_boot_wr <- function(index, rand = TRUE, method = 2) {

    if (rand) {
        matchmeta2 <- matchmeta %>%
            sample_frac(1, replace = TRUE)
    } else {
        matchmeta2 <- matchmeta
    }

    players2 <- players %>%
        semi_join(matchmeta2, by = "match_id")

    results <- players2 %>%
        left_join(select(matchmeta, match_id, winning_team, rating_diff_mean), by = "match_id") %>%
        mutate(rating_diff_mean = if_else(team == 1, rating_diff_mean, -rating_diff_mean)) %>%
        mutate(won = (team == winning_team) * 1)


    design <- model.matrix(
        ~ 0 + civ + rating_diff_mean,
        data = results
    )
    outcome <- results$won

    mod <- fastglm(
        x = design,
        y = outcome,
        method = method,
        family = binomial()
    )

    moddat <- tibble(
        coef = as.character(names(coef(mod))),
        lp = round(as.numeric(coef(mod)), 5)
    ) %>%
        filter(coef != "rating_diff_mean") %>%
        mutate(rank = rank(-lp)) %>%
        mutate(wr = plogis(lp)) %>%
        mutate(coef = str_remove(coef, "^civ")) %>%
        as.data.frame()

    return(moddat)
}

ncores <- min(
    round(parallel::detectCores() / 2),
    4
)

cl <- makeCluster(ncores)
clusterSetRNGStream(cl, 1053)

devnull <- clusterEvalQ(cl, {
    library(dplyr)
    library(fastglm)
    library(stringr)
    RhpcBLASctl::omp_set_num_threads(1)
    RhpcBLASctl::blas_set_num_threads(1)
})

devnull <- clusterExport(cl, c("matchmeta", "players", "get_boot_wr"))

runtime <- system.time({
    res <- clusterApplyLB(cl, 1:120, get_boot_wr)
})

stopCluster(cl)




realdat <- get_boot_wr(rand = FALSE) %>%
    select(coef, rank, wr)


dat <- res %>%
    bind_rows() %>%
    group_by(coef) %>%
    summarise(
        lci_rank = quantile(rank, 0.025),
        uci_rank = quantile(rank, 0.975),
        lci_wr = quantile(wr, 0.025),
        uci_wr = quantile(wr, 0.975)
    ) %>%
    left_join(realdat, by = "coef") %>%
    rename(civ = coef)




write_parquet(
    dat,
    file.path(data_location, "wr_boot.parquet")
)


