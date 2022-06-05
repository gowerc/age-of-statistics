devtools::load_all()
library(dplyr)
library(assertthat)
library(lubridate)
library(arrow)
library(purrr)
library(tidyr)


data_location <- get_data_location()
#data_location <- "./data/processed/p02_v02/rm_solo_all"

matchmeta <- read_parquet(
    file.path(data_location, "matchmeta.parquet")
)

players <- read_parquet(
    file.path(data_location, "players.parquet")
)

dat <- data_wr_naive(matchmeta, players)

write_parquet(
    dat,
    file.path(data_location, "wr_naive.parquet")
)





