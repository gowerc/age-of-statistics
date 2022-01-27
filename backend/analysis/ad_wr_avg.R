devtools::load_all()
library(dplyr)
library(assertthat)
library(lubridate)
library(arrow)
library(purrr)
library(tidyr)


data_location <- get_data_location()


mcoef <- readRds(file.path(data_location, "cvc_mod.Rds"))

civlist <- mcoef$civlist
coefs <- mcoef$coefs
coefs_names <- names(coefs)
covmat <- mcoef$vcov

trans <- matrix(nrow = length(civlist), ncol = length(coefs))
rownames(trans) <- civlist

for (i in seq_along(civlist)) {
    civ <- civlist[i]
    v1 <- stringr::str_detect(coefs_names, paste0("^", civ, "_")) * 1
    v2 <- stringr::str_detect(coefs_names, paste0("_", civ, "$")) * 1
    trans[i, ] <- v1 - v2
}

trans <- trans / length(civlist)

dat <- tibble(
    civ_name = civlist,
    lp = as.vector(trans %*% matrix(ncol = 1, coefs)),
    se = sqrt(diag(trans %*% covmat %*% t(trans))),
) %>%
    mutate(
        lci = invlogit(lp - 1.96 * se) * 100,
        est = invlogit(lp) * 100,
        uci = invlogit(lp + 1.96 * se) * 100,
        wr = est
    )

write_parquet(
    dat,
    file.path(data_location, "wr_avg.parquet")
)
