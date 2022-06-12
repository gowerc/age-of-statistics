pkgload::load_all()
library(dplyr)
library(stringr)
library(jsonlite)
library(arrow)

# args <- get_args("p02_v02", "rm_solo_all")
args <- get_args()

data_location <- get_data_location(args)

mcoef <- readRDS(file.path(data_location, "cvc.Rds"))

civ_split <- str_split_fixed(names(mcoef$coefs), "_", n = 2)

dat_orig <- tibble(
    civ_a = civ_split[, 1],
    civ_b = civ_split[, 2],
    lp = mcoef$coefs,
    se = sqrt(diag(mcoef$vcov))
)

dat_rev <- tibble(
    civ_a = civ_split[, 2],
    civ_b = civ_split[, 1],
    lp = - mcoef$coefs,
    se = sqrt(diag(mcoef$vcov))
)



dat <- bind_rows(dat_orig, dat_rev) %>%
    filter(civ_a != "rating", civ_a != "diff_mean") %>%
    mutate(
        est = invlogit(lp) * 100,
        lci = invlogit(lp - 1.96 * se) * 100,
        uci = invlogit(lp + 1.96 * se) * 100,
        wr = est
    ) %>%
    select(civ_a, civ = civ_b, wr, lci, uci) %>%
    arrange(civ_a, desc(wr), lci, uci)


check_1 <- dat %>%
    filter(civ_a == "Aztecs", civ == "Franks")

check_2 <- dat %>%
    filter(civ == "Aztecs", civ_a == "Franks")

assert_that(
    round(check_1$wr, 2) == round((100 - check_2$wr), 2)
)


results <- split(select(dat, -civ_a), dat$civ_a)

filepath <- file.path(
    get_output_location(args),
    "cvc.json"
)


sink(filepath)
toJSON(results)
sink()


write_parquet(
    x = dat,
    sink = file.path(data_location, "cvc.parquet")
)

