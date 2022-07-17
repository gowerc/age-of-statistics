
devtools::load_all()
library(dplyr)
library(tidyr)
library(data.table)
library(dtplyr)
library(assertthat)
library(lubridate)
library(arrow)
library(glue)
library(ggplot2)
library(ggrepel)
library(scales)
library(stringr)


classify_position <- function(x) {
    case_when(
        x == min(x) ~ "Flank",
        x == max(x) ~ "Flank",
        TRUE ~ "Pocket"
    )
}

classify_position(c(8, 4, 2, 6))

args <- get_args("p03_v07", "rm_team_open")
data_location <- get_data_location(args)
matchmeta_open <- read_parquet(file.path(data_location, "matchmeta.parquet"))
players_open <- read_parquet(file.path(data_location, "players.parquet"))


args <- get_args("p03_v07", "rm_team_closed")
data_location <- get_data_location(args)
matchmeta_closed <- read_parquet(file.path(data_location, "matchmeta.parquet"))
players_closed <- read_parquet(file.path(data_location, "players.parquet"))




get_plot <- function(matchmeta, players) {

    matches_selected <- matchmeta %>%
        filter(n_players %in% c(6, 8)) %>%
        select(match_id, rating_diff_mean)


    players_selected <- players %>%
        inner_join(matches_selected, by = "match_id") %>%
        as.data.table() %>%
        group_by(match_id, team) %>%
        mutate(position = classify_position(slot)) %>%
        arrange(match_id, team, slot) %>%
        as_tibble() %>% 
        mutate(civpos = paste0(civ, "-", position))


    mod <- glm(
        won ~ civpos + rating_diff_mean - 1,
        family = binomial(),
        data = players_selected
    )


    dat <- tibble(
        wr = plogis(coef(mod)) * 100,
        #se = sqrt(diag(vcov(mod))),
        civ = names(coef(mod))
    )


    dat2 <- dat %>%
        filter(str_detect(civ, "^civpos")) %>%
        mutate(civ = str_remove(civ, "^civpos")) %>%
        mutate(position = if_else(str_detect(civ, "Flank"), "Flank", "Pocket")) %>%
        mutate(civ = str_remove(civ, "-Flank$")) %>%
        mutate(civ = str_remove(civ, "-Pocket$")) %>%
        spread(position, wr)


    ggplot(dat2, aes(x = Flank, y = Pocket, label = civ)) +
        geom_point() +
        scale_x_continuous(breaks = pretty_breaks(10)) +
        scale_y_continuous(breaks = pretty_breaks(10)) +
        ylab("WR (Pocket)") +
        xlab("WR (Flank)") +
        theme_bw() +
        geom_abline(intercept = 0, slope = 1, col = "red") +
        geom_text_repel()
}



p_open <- get_plot(matchmeta_open, players_open)
p_closed <- get_plot(matchmeta_closed, players_closed)


dir.create(
    file.path("outputs", "exploratory"),
    showWarnings = FALSE
)

ggsave(
    plot = p_open,
    filename = file.path("outputs", "exploratory", "g_team_pocket_wr_OPEN.png"),
    height = 6.75,
    width =  9,
    units = "in",
    dpi = 150,
    scale = 1.2
)


ggsave(
    plot = p_closed,
    filename = file.path("outputs", "exploratory", "g_team_pocket_wr_CLOSED.png"),
    height = 6.75,
    width = 9,
    units = "in",
    dpi = 150,
    scale = 1.2
)



