# library(arrow)
# library(forcats)
# library(ggplot2)


# dat <- read_parquet(file.path(data_location, "cvc.parquet"))

# x <- read_parquet(file.path(data_location, "pr.parquet"))


# matchmeta <- x

# pdat <- dat %>%
#     filter(civ_a == "Franks") %>%
#     left_join(x, by = "civ") %>%
#     mutate(wr = (wr - 50) * (pr/100)) %>%
#     mutate(lci = (lci - 50) * (pr/100)) %>%
#     mutate(uci = (uci - 50) * (pr/100)) %>%
#     arrange(desc(wr)) %>%
#     mutate(civ = fct_inorder(civ))



# p <- ggplot(data = pdat, aes(x = civ, group = civ, ymin = lci, ymax = uci, y = wr)) +
#     geom_hline(yintercept = 0, col = "red", alpha = 0.65) +
#     #geom_hline(yintercept = c(45, 55), col = "blue", alpha = 0.65, lty = 2) +
#     geom_errorbar(width = 0.3) +
#     geom_point() +
#     theme_bw() +
#     theme(
#         axis.text.x = element_text(angle = 50, hjust = 1),
#         plot.caption = element_text(hjust = 0)
#     ) +
#     #labs(caption = footnotes) +
#     ylab("Win Rate Contribution(%)") +
#     xlab("") +
#     scale_y_continuous(breaks = pretty_breaks(10))

# p


# sum(pdat$wr) + 50
