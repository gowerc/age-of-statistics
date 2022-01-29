devtools::load_all()
library(dplyr)
library(ggplot2)
library(scales)
library(lubridate)
library(arrow)

data_location <- get_data_location()

cvc_mat <- readRDS(file.path(data_location, "cvc.Rds"))[["cvc"]]


hmod <- hclust(
    as.dist(1 - lsa::cosine(cvc_mat - 0.5)),
    method = "complete"
)

dhc <- as.dendrogram(hmod)

ddata <- ggdendro::dendro_data(dhc, type = "rectangle") %>%
    ggdendro::segment() %>%
    as_tibble() %>%
    mutate(nyend = if_else(yend == 0, y - 0.1, yend))

ldata <- ddata %>%
    filter(yend == 0) %>%
    mutate(labs = hmod$labels[hmod$order])


recursive_get_group <- function(start, start_is_y, dat, grpdat = NULL) {
    if (is.null(grpdat)) grpdat <- tibble::tibble(id = numeric(), grp = numeric())

    if(start_is_y) {
        next_start <- dat %>%
            filter(x != xend) %>%
            left_join( select(start, yend, grp, yx = x), by = "yend") %>%
            filter( x == yx | xend == yx) %>%
            filter(!is.na(grp))
    } else {
        next_start <- dat %>%
            filter(y != yend) %>%
            left_join(select(start, xend, grp, xy = y), by = "xend") %>%
            filter( y == xy | yend == xy) %>%
            filter(!is.na(grp))
    }
    if (nrow(next_start) == 0) {
        return(grpdat)
    }

    grpdat <- grpdat %>%
        bind_rows(select(next_start, id, grp))

    return(recursive_get_group(next_start, !start_is_y, dat, grpdat))
}

ddata2 <- ddata %>%
    mutate(id = row_number())

cut <- 0.01
ngroups <- 99
while (ngroups > 8) {
    init_grp <- ddata2 %>%
        filter(x == xend) %>%
        filter(y >= cut) %>%
        filter(!yend %in% y) %>%
        mutate(grp = row_number())
    ngroups <- length(unique(init_grp$grp))
    cut <- cut + 0.005
}

grpclass <- recursive_get_group(init_grp, TRUE, ddata2)

ddata3 <- ddata2 %>%
    left_join(grpclass, by = "id") %>%
    mutate(grp = factor(grp))


footnotes <- c(
    "Clusters are formed using complete linkage on the cosine distance between civilisation v civilisation win rates.<br/>",
    "Civilisations are coloured based upon their group.<br/>",
    "Groups are formed by applying an arbitrary cutoff that ensures there are no more than 8 unique groups."
) %>%
    as_footnote()


p <- ggplot(ddata3, aes(x = x, y = y, xend = xend, yend = nyend, col = grp)) +
    geom_segment() +
    theme_bw() +
    scale_x_continuous(breaks = c(), labels = c()) +
    scale_y_continuous(expand = expansion(mult = c(0.25, 0.05)), breaks = pretty_breaks(10)) +
    xlab("") +
    ylab("Cosine Distance") +
    geom_text(
        aes(label = labs, y = nyend, x = x),
        inherit.aes = FALSE,
        data = ldata,
        hjust = 1.1,
        angle = 90
    ) +
    theme(
        legend.position = "none",
        axis.text.x = element_text(angle = 50, hjust = 1),
        plot.caption = element_text(hjust = 0)
    ) +
    labs(caption = footnotes)



save_plot(
    p = p,
    id = "civ_dendro",
    type = "standard"
)


