devtools::load_all()
library(dplyr)
library(ggplot2)
library(scales)
library(purrr)
library(lubridate)
library(arrow)

# args <- get_args("p02_v02", "rm_solo_all")
args <- get_args()
data_location <- get_data_location(args)

pr <- read_parquet(file.path(data_location, "pr.parquet"))
matchmeta <- read_parquet(file.path(data_location, "matchmeta.parquet"))
players <- read_parquet(file.path(data_location, "players.parquet"))


###############################
#
# Play Rate
#
###############################


footnotes <- c(
    "The red line represents the hypothetical play rate if civs were picked at random"
) %>%
    as_footnote(args)


prdat <- pr %>%
    arrange(desc(n)) %>%
    mutate(civ = fct_inorder(civ)) %>%
    select(civ, pr) %>%
    mutate(y_label = pr + max(pr) * 0.015) %>%
    mutate(pr_txt = sprintf("%4.1f %%", pr))


p <- ggplot(data = prdat, aes(y = pr, x = civ)) +
    geom_bar(stat = "identity") +
    geom_hline(yintercept = 1 / nrow(prdat) * 100, col = "red") +
    geom_text(aes(y = y_label, label = pr_txt), hjust = 0, angle = 90) +
    theme_bw() +
    scale_y_continuous(breaks = pretty_breaks(10), expand = expansion(c(0, 0.13))) +
    theme(
        axis.text.x = element_text(angle = 50, hjust = 1),
        plot.caption = element_text(hjust = 0)
    ) +
    labs(caption = footnotes) +
    ylab("Play Rate (%)") +
    xlab("")


save_plot(
    p = p,
    id = "civ_playrate",
    type = "standard"
)



###############################
#
# Distribution of Players Highest Picked Civilisation's Play Rate
#
###############################

lower_limit <- 20

players2 <- players %>%
    semi_join(matchmeta, by = "match_id")


n_total_players <- length(unique(players2$profile_id))


play_counts <- players2 %>%
    group_by(profile_id) %>%
    tally() %>%
    filter(n >= lower_limit)

play_counts_civ <- players2 %>%
    semi_join(play_counts, by = "profile_id") %>%
    group_by(profile_id, civ) %>%
    tally() %>%
    group_by(profile_id) %>%
    mutate(bign = sum(n)) %>%
    ungroup() %>%
    mutate(pcent = n / bign * 100)


pdat <- play_counts_civ %>%
    arrange(profile_id, desc(pcent)) %>%
    group_by(profile_id) %>%
    filter(row_number() == 1) %>%
    mutate(pcent_cat = cut(pcent, seq(0, 100, 10))) %>%
    group_by(pcent_cat) %>%
    tally() %>%
    ungroup() %>%
    mutate(p = sprintf("%4.1f%%", n / sum(n) * 100)) %>%
    mutate(yadj = n + max(n) / 50)


footnotes <- c(
    sprintf(
        "Only includes %s / %s players who have played more than %s games", 
        nrow(play_counts),
        n_total_players,
        lower_limit
    )
) %>%
    as_footnote(args)


p <- ggplot(data = pdat, aes(x = pcent_cat, y = n)) +
    geom_bar(stat = "identity") +
    geom_text(aes(label = p, y = yadj)) +
    theme_bw() +
    scale_y_continuous(breaks = pretty_breaks(8), expand = expansion(c(0, 0.05))) +
    xlab("Play Rate of Most Used Civ") +
    ylab("Number of Players") +
    theme(
        plot.caption = element_text(hjust = 0),
        axis.text.x = element_text(hjust = 1, angle = 35)
    ) +
    labs(caption = footnotes)


pdat2 <- pdat %>%
    select(percent_group = pcent_cat, count = n, percent = p)


save_plot(
    p = p,
    id = "dist_civpick",
    type = "standard"
)

set_log(get_output_location(args), "play_rates")

