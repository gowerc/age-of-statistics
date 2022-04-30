
devtools::load_all()
library(dplyr)
library(ggplot2)
library(scales)
library(purrr)
library(lubridate)
library(arrow)

data_location <- get_data_location()

wr <- read_parquet(file.path(data_location, "wr_naive.parquet"))
pr <- read_parquet(file.path(data_location, "pr.parquet"))




assert_that(
    nrow(wr) == nrow(pr)
)

boxtrans <- function(x, y) {
    box_cox_num <- MASS::boxcox(x ~ y, data = data.frame(x = x, y = y), plotit = FALSE)
    lambda <- box_cox_num$x[which.max(box_cox_num$y)]
    if (lambda == 0) {
        return(log(x))
    } else {
        return(((x^lambda) - 1) / lambda)
    }
}


dat <- wr %>%
    inner_join(select(pr, civ, pr), by = "civ") %>%
    mutate(box_pr = boxtrans(pr, wr))


mod <- MASS::rlm(wr ~ box_pr, data = dat, psi = MASS::psi.huber)

dat2 <- dat %>%
    mutate(preds = predict(mod)) %>%
    mutate(bias = preds - wr) %>%
    arrange(bias) %>%
    mutate(civ = fct_inorder(civ))


footnotes <- c(
    "Negative values indicate that a civilisation is 'underestimated'<br/>",
    "Positive values indicate that a civilisation is 'overestimated'<br/>",
    "Expected win rates are calculated by fitting a robust linear model with",
    "box-cox transformed play rates as the predcitor <br/>",
    "The reference lines are arbitrarily set at -2.5 and 2.5 to provide a visual aid"
) %>%
    as_footnote()


p1 <- ggplot(data = dat2, aes(y = bias, x = civ)) +
    geom_bar(stat = "identity") +
    theme_bw() +
    scale_y_continuous(breaks = pretty_breaks(10)) +
    geom_hline(yintercept = c(-2.5, 2.5), col = "blue", alpha = 0.65) +
    theme(
        axis.text.x = element_text(angle = 50, hjust = 1),
        plot.caption = element_text(hjust = 0)
    ) +
    labs(caption = footnotes) +
    ylab("Difference in Expected Win Rate and Observed Win Rate") +
    xlab("")


footnotes <- c(
    "Expected win rates are calculated by fitting a robust linear model with",
    "box-cox transformed play rates as the predcitor"
) %>%
    as_footnote()


p2 <- ggplot(data = dat2, aes(y = wr, x = preds, label = civ)) +
    geom_point() +
    theme_bw() +
    scale_y_continuous(breaks = pretty_breaks(10)) +
    labs(caption = footnotes) +
    ylab("Observed Win Rate") +
    xlab("Expected Win Rate") +
    geom_text_repel(min.segment.length = unit(0.1, "lines"), alpha = 0.7) +
    geom_abline(slope = 1, intercept = 0, col = "red", alpha = 0.65) +
    geom_vline(xintercept = 50, col = "blue", alpha = 0.4) +
    geom_hline(yintercept = 50, col = "blue", alpha = 0.4) +
    theme(plot.caption = element_text(hjust = 0))


save_plot(
    p = p1,
    id = "civ_ewr_owr_diff",
    type = "standard"
)


save_plot(
    p = p2,
    id = "civ_ewr_owr",
    type = "standard"
)


set_log(get_output_location(), "wr_estimated")

