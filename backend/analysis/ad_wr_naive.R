devtools::load_all()
library(dplyr)
library(assertthat)
library(lubridate)
library(arrow)
library(purrr)
library(tidyr)
library(jsonlite)

# args <- get_args("p02_v02", "rm_solo_all")
args <- get_args()
data_location <- get_data_location(args)

matchmeta <- read_parquet(
    file.path(data_location, "matchmeta.parquet")
)

players <- read_parquet(
    file.path(data_location, "players.parquet")
)


results <- prep_wr_naive(matchmeta, players)
dat <- data_wr_naive(results)

write_parquet(
    dat,
    file.path(data_location, "wr_naive.parquet")
)



filepath <- file.path(
    get_output_location(args),
    "wr_naive.json"
)


sink(filepath)
dat %>%
    select(est, lci, uci) %>%
    split(dat$civ) %>%
    map(as.list) %>%
    toJSON(auto_unbox = TRUE)
sink()




