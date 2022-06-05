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
#data_location <- "./data/processed/p02_v02/rm_solo_all"

matchmeta <- read_parquet(
    file.path(data_location, "matchmeta.parquet")
)

players <- read_parquet(
    file.path(data_location, "players.parquet")
)



get_ranks <- function(i, rand = TRUE) {
    
    if (rand) {
        matchmeta2 <- matchmeta
    } else {
        matchmeta2 <- matchmeta %>%
            sample_frac(1, replace = TRUE)
    }

    players2 <- players %>%
        semi_join(matchmeta2, by = "match_id")

    results <- players2 %>% 
        left_join(select(matchmeta, match_id, winning_team, rating_diff_mean), by = "match_id") %>%
        mutate(rating_diff_mean = if_else(team == 1, rating_diff_mean, -rating_diff_mean)) %>%
        mutate(won = (team == winning_team) * 1)


    x <- model.matrix(
        ~ 0 + civ + rating_diff_mean,
        data = results
    )
    y <- results$won

    mod <- fastglm(x = x, y = y, family = binomial())

    moddat <- tibble(
        coef = names(coef(mod)),
        lp = coef(mod),
        index = i
    ) %>%
        filter(coef != "rating_diff_mean") %>%
        mutate(rank = rank(-lp)) %>%
        arrange(rank)
    
    return(moddat)
}


cl <- makeCluster(8)
clusterSetRNGStream(cl, 1053)

devnull <- clusterEvalQ(cl, {
    library(dplyr)
    library(fastglm)
})

devnull <- clusterExport(cl, c("matchmeta", "players", "get_ranks"))

res <- clusterApply(cl, 1:30, get_ranks)

stopCluster(cl)


moddat2 <- res %>%
    bind_rows() %>%
    mutate(coef = str_remove(coef, "^civ")) %>%
    group_by(coef) %>%
    mutate(
        est = median(rank),
        lci = quantile(rank, 0.025),
        uci = quantile(rank, 0.975)
    ) %>%
    rename(civ = coef)




write_parquet(
    dat,
    file.path(data_location, "wr_naive.parquet")
)