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

players2 <- players %>%
    semi_join(matchmeta, by = "match_id")

dat <- players2 %>%
    mutate(bign = n()) %>% 
    group_by(civ_name) %>% 
    summarise(
        n = n(),
        bign = unique(bign),
        pr = n/bign * 100,
        pr_format = sprintf("%5.2f %%", pr)
    )

write_parquet(
    dat,
    file.path(data_location, "pr.parquet")
)
