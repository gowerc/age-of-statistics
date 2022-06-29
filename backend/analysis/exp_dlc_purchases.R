pkgload::load_all()
library(dplyr)
library(lubridate)
library(ggplot2)
library(arrow)


matches <- read_parquet("./data/processed/matches.parquet")
players <- read_parquet("./data/processed/players.parquet")


valid_matches <- matches %>% 
    filter(start_dt >= ymd_hms("2022-05-01 00:00:00"))


players_valid <- players %>% 
    semi_join(valid_matches, by = "match_id")

target_civs_doi <- c("Bengalis", "Dravidians", "Gurjaras")
target_civs_lotw <- c("Sicilians", "Burgundians")
target_civs_dod <- c("Poles", "Bohemians")



players_valid %>%
    filter(civ %in% target_civs_doi) %>% 
    distinct(profile_id) %>% 
    nrow()

players_valid %>% 
    filter(civ %in% target_civs_lotw) %>% 
    distinct(profile_id) %>% 
    nrow()

players_valid %>% 
    filter(civ %in% target_civs_dod) %>% 
    distinct(profile_id) %>% 
    nrow()


players_valid %>% 
    distinct(profile_id) %>% 
    nrow()
