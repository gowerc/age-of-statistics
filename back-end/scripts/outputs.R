

devtools::load_all()
library(dplyr)
library(ggplot2)
library(scales)
library(tidyr)
library(lubridate)
library(assertthat)
library(glue)

# Prevent scientific notation in plots
options(scipen = 999)

## determine which cohort we are building
ARGS <- commandArgs(trailARGS <- commandArgs(trailingOnly = TRUE)
ingOnly = TRUE)
assert_that(length(ARGS) == 3)
if (length(ARGS) == 0) {
    GAME <- "aoe2"
    PERIOD <- "p2"
    FILTER <- "rm_solo_open"
} else {
    GAME <- ARGS[[1]]
    PERIOD <- ARGS[[2]]
    FILTER <- ARGS[[3]]
}


OUTPUT_LOCATION <- get_output_location(GAME, PERIOD, FILTER)
DATA_LOCATION <- get_data_location(GAME, PERIOD)

config <- jsonlite::read_json("./config.json")

config_filter <- config[[GAME]][["filters"]][[FILTER]]
config_period <- config[[GAME]][["periods"]][[PERIOD]]

assert_that(
    !is.null(config_filter),
    !is.null(config_period)
)

#########################
#
#  Prep Data
#
#


map_filter <- ifelse(
    config_filter$mapclass != "All",
    function(x) filter(x, map_class == config_filter$mapclass),
    identity
)

players_all <- arrow::read_parquet(paste0(DATA_LOCATION, "players.parquet"))
matchmeta_all <- arrow::read_parquet(paste0(DATA_LOCATION, "matchmeta.parquet"))


matchmeta_core <- matchmeta_all %>%
    filter(!is_mirror) %>%
    filter(start_dt >= ymd_hms(paste(config_period$lower, "00:00:01"))) %>%
    filter(start_dt <= ymd_hms(paste(config_period$upper, "23:59:59"))) %>%
    filter(leaderboard_name == config_filter$leaderboard) %>%
    filter(match_length_igm >= config_filter$length_limit_lower) %>%
    filter(match_length_igm <= config_filter$length_limit_upper) %>%
    map_filter()

matchmeta <- matchmeta_core %>%
    filter(rating_min >= config_filter$elo_limit_lower)

matchmeta_slice <- matchmeta_core %>%
    filter(rating_min >= config_filter$elo_limit_lower_slide)



if (config_filter$rm_single_pick) {

    matchmeta_gm <- matchmeta_all %>%
        filter(leaderboard_name == config_filter$leaderboard)

    players_to_remove <- players_all %>%
        semi_join(matchmeta_gm, by = "match_id") %>%
        group_by(profile_id, civ_name) %>%
        tally() %>%
        group_by(profile_id) %>%
        mutate(bign = sum(n)) %>%
        ungroup() %>%
        mutate(pcent = n / bign * 100) %>%
        filter(bign >= 10, pcent >= 40) %>%
        distinct(profile_id)

    matches_to_remove <- players_all %>%
        semi_join(players_to_remove, by = "profile_id") %>%
        distinct(match_id)

    matchmeta_slice <- matchmeta_slice %>% anti_join(matches_to_remove, by = "match_id")
    matchmeta <- matchmeta %>% anti_join(matches_to_remove, by = "match_id")
}


#########################
#
# Create Outputs
#
#

om <- outputManager$new()



# Distribution of Matches Played by Patch
om$add_output(
    output = plot_dist_patch(matchmeta),
    id = "dist_patch"
)



# Distribution of Matches Played by Map
om$add_output(
    output = plot_dist_map(matchmeta),
    id = "dist_map"
)

# Distribution of Matches Played by Map (normalised)
om$add_output(
    output = plot_dist_map_normal(matchmeta),
    id = "dist_map_normal"
)




# Distribution of Matches Played by Game Length
om$add_output(
    output = plot_dist_gamelength(matchmeta),
    id = "dist_gamelength"
)



# Distribution of Matches Played by Mean Team Elo
om$add_output(
    output = plot_dist_elo(matchmeta),
    id = "dist_elo"
)



# Play Rate by Civilisation
pr <- data_pr(matchmeta = matchmeta, players = players_all)
om$add_output(
    output = plot_pr(pr),
    id = "civ_playrate"
)



# Naive Win Rates by Civilisation
wr_naive <- data_wr_naive(matchmeta = matchmeta, players = players_all)
om$add_output(
    output = plot_wr_naive(wr_naive),
    id = "civ_wrNaive"
)



# Naive Win Rates vs Play Rate
om$add_output(
    output = plot_pr_wr(wr_naive, pr),
    id = "civ_wrNaive_playrate"
)



# Averaged Win Rates by Civilisation
wr_avg_coef <- data_cvc(matchmeta = matchmeta, players = players_all)
wr_avg <- data_wr_avg(wr_avg_coef)
om$add_output(
    output = plot_wr_avg(wr_avg),
    id = "civ_wrAvg"
)



# Averaged Win Rates vs Play Rate
om$add_output(
    output = plot_pr_wr(wr_avg, pr),
    id = "civ_wrAvg_playrate"
)



# Slide - Naive Win Rates by Elo
om$add_output(
    output = plot_slide_wr_elo(matchmeta = matchmeta_slice, players = players_all),
    id = "slide_wrNaive_elo",
    style = "square"
)



# Slide -  Naive Win Rates by Game Length
om$add_output(
    output = plot_slide_wr_gamelength(matchmeta = matchmeta, players = players_all),
    id = "slide_wrNaive_gamelength",
    style = "square"
)


# Slide - Play rate by Elo
om$add_output(
    output = plot_slide_pr_elo(matchmeta = matchmeta, players = players_all),
    id = "slide_playrate_elo",
    style = "square"
)




# Civilisation v Civilisation Win Rates
# cvc_plots <- plot_cvc(wr_avg_coef)
# for (civ in names(cvc_plots)) {
#     om$add_output(
#         output = cvc_plots[[civ]],
#         id = glue("cvc_wrNaive_{civ}", civ = civ)
#     )
# }



# Distribution of Players Highest Picked Civilisation's Play Rate
om$add_output(
    output = plot_pr_civ1(matchmeta, players_all, lower_limit = 20),
    id = "dist_civpick"
)


# Hierarchical Clustering Dendrogram
cvc_mat <- data_cvc_matrix(wr_avg_coef)
om$add_output(
    output = plot_dendro_wr(cvc_mat),
    id = "civ_dendro"
)



# Estimating how Overrated or Underrated each Civilisation is
p_wr_ewr <- plot_wr_ewr(wr_naive, pr)

om$add_output(
    output = p_wr_ewr[[1]],
    id = "civ_ewr_owr_diff"
)

om$add_output(
    output = p_wr_ewr[[2]],
    id = "civ_ewr_owr"
)


om$save_all(OUTPUT_LOCATION)


sink(paste0(OUTPUT_LOCATION, "output.log"))
cat("done")
sink()




##### Testing the affecting of different ploting options
#
#
# opts1 <- list(
#     height = 5,
#     width = 9,
#     units = "in",
#     dpi = 150,
#     scale = 1.2
# )
# opts2 <- list(
#     height = 5,
#     width = 9,
#     units = "in",
#     dpi = 600,
#     scale = 1.2
# )
# ggsave(
#     filename = "./outputs/test1.png",
#     plot = om$outputs[[53]]$plot,
#     height = opts1$height,
#     width = opts1$width,
#     units = opts1$units,
#     dpi = opts1$dpi,
#     scale = opts1$scale
# )
# ggsave(
#     filename = "./outputs/test2.png",
#     plot = om$outputs[[53]]$plot,
#     height = opts2$height,
#     width = opts2$width,
#     units = opts2$units,
#     dpi = opts2$dpi,
#     scale = opts2$scale
# )
