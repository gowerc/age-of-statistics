
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
library(forcats)


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




get_pdat <- function(matchmeta, players) {
    matches_selected <- matchmeta %>%
        filter(n_players %in% c(6, 8)) %>%
        select(match_id, rating_diff_mean)


    players_selected <- players %>%
        inner_join(matches_selected, by = "match_id") %>%
        as.data.table() %>%
        group_by(match_id, team) %>%
        mutate(position = classify_position(color)) %>%
        arrange(match_id, team, color) %>%
        as_tibble() %>%
        mutate(civpos = paste0(civ, "-", position))


    mod <- glm(
        won ~ civpos + rating_diff_mean - 1,
        family = binomial(),
        data = players_selected
    )


    dat <- tibble(
        eta = coef(mod),
        wr = plogis(eta) * 100,
        se = sqrt(diag(vcov(mod))),
        civ = names(coef(mod)),
        lci = plogis(eta - 1.96 * se) * 100,
        uci = plogis(eta + 1.96 * se) * 100
    )


    dat %>%
        filter(str_detect(civ, "^civpos")) %>%
        mutate(civ = str_remove(civ, "^civpos")) %>%
        mutate(position = if_else(str_detect(civ, "Flank"), "Flank", "Pocket")) %>%
        mutate(civ = str_remove(civ, "-Flank$")) %>%
        mutate(civ = str_remove(civ, "-Pocket$"))
}


get_cross_plot <- function(pdat) {
    dat2 <- pdat %>%
        select(civ, wr, position) %>%
        spread(position, wr)


    ggplot(dat2, aes(x = Flank, y = Pocket, label = civ)) +
        geom_point() +
        scale_x_continuous(breaks = pretty_breaks(10)) +
        scale_y_continuous(breaks = pretty_breaks(10)) +
        ylab("WR (Pocket)") +
        xlab("WR (Flank)") +
        theme_bw() +
        geom_abline(intercept = 0, slope = 1, col = "red") +
        geom_vline(xintercept = 50, col = "blue", alpha = 0.7) +
        geom_hline(yintercept = 50, col = "blue", alpha = 0.7) +
        geom_text_repel()
}

get_ci_plot <- function(pdat) {
    dat2 <- pdat %>%
        select(civ, wr, position, lci, uci) %>%
        arrange(civ) %>%
        mutate(civ = fct_inorder(civ))


    ggplot(data = dat2, aes(x = civ, group = civ, ymin = lci, ymax = uci, y = wr)) +
        geom_hline(yintercept = 50, col = "red", alpha = 0.65) +
        geom_hline(yintercept = c(47,53), col = "blue", alpha = 0.65, lty = 2) +
        geom_errorbar(width = 0.3) +
        geom_point() +
        theme_bw() +
        theme(
            axis.text.x = element_text(angle = 50, hjust = 1),
            plot.caption = element_text(hjust = 0)
        ) +
        ylab("Win Rate (%)") +
        xlab("") +
        scale_y_continuous(breaks = pretty_breaks(10)) +
        facet_grid(position ~ .)
}



pdat_open <- get_pdat(matchmeta_open, players_open)
pdat_closed <- get_pdat(matchmeta_closed, players_closed)


p_open_cross <- get_cross_plot(pdat_open)
p_closed_cross <- get_cross_plot(pdat_closed)
p_open_ci <- get_ci_plot(pdat_open)
p_closed_ci <- get_ci_plot(pdat_closed)


dir.create(
    file.path("outputs", "exploratory"),
    showWarnings = FALSE
)

ggsave(
    plot = p_open_cross,
    filename = file.path("outputs", "exploratory", "g_team_pocket_wr_CROSS_OPEN.png"),
    height = 6.75,
    width =  9,
    units = "in",
    dpi = 150,
    scale = 1.2
)


ggsave(
    plot = p_closed_cross,
    filename = file.path("outputs", "exploratory", "g_team_pocket_wr_CROSS_CLOSED.png"),
    height = 6.75,
    width = 9,
    units = "in",
    dpi = 150,
    scale = 1.2
)


ggsave(
    plot = p_open_ci,
    filename = file.path("outputs", "exploratory", "g_team_pocket_wr_CI_OPEN.png"),
    height = 6.75,
    width =  9,
    units = "in",
    dpi = 150,
    scale = 1.2
)


ggsave(
    plot = p_closed_ci,
    filename = file.path("outputs", "exploratory", "g_team_pocket_wr_CI_CLOSED.png"),
    height = 6.75,
    width = 9,
    units = "in",
    dpi = 150,
    scale = 1.2
)
