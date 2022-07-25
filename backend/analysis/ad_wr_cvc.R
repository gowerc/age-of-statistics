devtools::load_all()
library(dplyr)
library(assertthat)
library(arrow)
library(purrr)
library(tidyr)
library(fastglm)
library(parallel)
library(jsonlite)
library(stringr)

# args <- get_args("p02_v03", "rm_team_open")
args <- get_args()
data_location <- get_data_location(args)



matchmeta <- read_parquet(
    file.path(data_location, "matchmeta.parquet")
)

players <- read_parquet(
    file.path(data_location, "players.parquet")
)


get_wr_df <- function(civ1, combos2) {

    df <- combos2 %>%
        filter(civ == civ1)

    modc <- fastglm(
        x = model.matrix(~ 0 + civ_op, data = df),
        y = df$won * 1,
        offset = pre_res_coef * df$rating_diff_mean,
        method = 2,
        family = binomial()
    )

    name_coef <- str_replace(names(modc$coefficients), "^civ_op", "")

    tibble(
        civ1 = civ1,
        civ2 = name_coef,
        lp = modc$coefficients
    )
}


get_boot_res <- function(id) {
    results_boot <- results %>%
        select(match_id) %>%
        sample_frac(1, replace = TRUE) %>%
        arrange(match_id) %>%
        mutate(match_id_new = row_number())

    combos2 <- combos %>%
        inner_join(results_boot, by = "match_id") %>%
        mutate(match_id = match_id_new) %>%
        bind_rows(ridge)

    map_df(unique_civs, get_wr_df, combos = combos2) %>%
        mutate(id = id) %>%
        mutate(est = plogis(lp) * 100) %>%
        select(-lp)
}

pre_res <- matchmeta %>% 
    mutate(won = if_else(winning_team == 1, 1, 0)) %>%
    select(won, rating_diff_mean)


pre_res_mod <- fastglm(
    x = model.matrix(~ 1 + rating_diff_mean, data = pre_res),
    y = pre_res$won,
    method = 2,
    family = binomial()
)

pre_res_coef <- pre_res_mod$coefficients["rating_diff_mean"]


unique_civs <- players %>%
    distinct(civ) %>%
    arrange(civ) %>%
    pull(civ) %>%
    unique()


### A ridge data frame to bias the results towards 50%
### Helps stabalise results in cases where we have very few samples
pre_ridge <- cross_df(list(civ = unique_civs, civ_op = unique_civs)) %>%
    mutate(rating_diff_mean = 0) %>%
    filter(civ != civ_op)

ridge <- bind_rows(
    pre_ridge %>% mutate(won = TRUE),
    pre_ridge %>% mutate(won = FALSE)
)


results <- matchmeta %>%
    select(match_id, rating_diff_mean)


opponents <- players %>%
    mutate(team = ifelse(team == 1, 2, 1)) %>%
    select(civ_op = civ, match_id, team)


combos <- players %>%
    select(match_id, won, team, civ) %>%
    left_join(opponents, by = c("match_id", "team")) %>%
    filter(civ != civ_op) %>%
    inner_join(results, by = "match_id") %>%
    mutate(rating_diff_mean = if_else(
        team == 1,
        rating_diff_mean,
        -rating_diff_mean
    ))





cl <- makeCluster(4)
clusterExport(cl, c("results", "combos", "get_wr_df", "pre_res_coef", "unique_civs", "ridge"))
clusterEvalQ(cl, {
    library(dplyr)
    library(fastglm)
    library(purrr)
    library(stringr)
})
#start <- Sys.time()
clusterSetRNGStream(cl, iseed = 1320)
res_samples <- clusterApply(cl, seq_len(150), get_boot_res) %>% bind_rows()
#stop <- Sys.time()
#difftime(stop, start, units = "sec")
stopCluster(cl)




wr_avg <- res_samples %>%
    rename(civ = civ1) %>%
    group_by(id, civ) %>%
    summarise(m = mean(est), .groups = "drop") %>%
    group_by(civ) %>%
    summarise(
        mean = mean(m),
        med = median(m),
        lci = quantile(m, 0.025),
        uci = quantile(m, 0.975)
    )


wr_civ <- res_samples %>%
    group_by(civ1, civ2) %>%
    summarise(
        mean = mean(est),
        med = median(est),
        lci = quantile(est, 0.025),
        uci = quantile(est, 0.975),
        .groups = "drop"
    )



## Simple sanity check
check_1 <- wr_civ %>% filter(civ1 == "Aztecs", civ2 == "Franks")
check_2 <- wr_civ %>% filter(civ2 == "Aztecs", civ1 == "Franks")
assert_that( round(check_1$med, 2) == round((100 - check_2$med), 2))



write_parquet(
    res_samples,
    file.path(data_location, "wr_cvc_RAW.parquet")
)


write_parquet(
    wr_civ,
    file.path(data_location, "wr_cvc_CIV.parquet")
)


write_parquet(
    wr_avg,
    file.path(data_location, "wr_cvc_AVG.parquet")
)


wr_civ_j <- wr_civ %>%
    rename(civ_a = civ1, civ = civ2, wr = med) %>%
    select(-mean)

results <- split(select(wr_civ_j, -civ_a), wr_civ_j$civ_a)

filepath <- file.path(
    get_output_location(args),
    "cvc.json"
)


sink(filepath)
toJSON(results)
sink()

