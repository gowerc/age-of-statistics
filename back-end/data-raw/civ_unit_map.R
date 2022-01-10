
library(googlesheets4)
library(dplyr)
library(readr)

gs4_auth(cache = ".gsauth")

read_sheet(
    ss = "https://docs.google.com/spreadsheets/d/1SFPZlTfP38foj9oy_gYviUK2k9_neIjwle6PKi1YCoA/edit#gid=1597095642",
    sheet = "Civ-Unit Mapping"
) %>%
    select(-`General Rules`) %>%
    write_csv("./data-raw/civ_unit_map.csv")


