

logit <- function(x) {
    log(x / (1 - x))
}


invlogit <- function(x) {
    exp(x) / (1 + exp(x))
}


as_footnote <- function(x, width = 140, add_Filter = TRUE) {

    args <- get_args()

    if (add_Filter) {
        x <- c(
            glue::glue(
                "Filter: {filter}, Period: {period}<br/>",
                filter = args$filter,
                period = args$period
            ),
            x
        )
    }

    x %>%
        paste(collapse = " ") %>%
        stringr::str_split("<br/>") %>%
        purrr::flatten_chr() %>%
        stringr::str_trim() %>%
        stringr::str_wrap(width = width) %>%
        paste(collapse = "\n")
}


get_map_class <- function(game) {
    x <- yaml::read_yaml("./data/raw/maps.json")[[game]]
    dplyr::tibble(
        map_name = names(unlist(x)),
        map_class = unlist(x)
    )
}


get_config <- function(key = NULL) {
    x <- yaml::read_yaml("./data/raw/config.yml")
    return(x)
}


lgl_to_char <- function(x){
    ifelse(x, "True", "False")
}


get_data_location <- function(nofilter=FALSE) {
    args <- get_args()

    if (nofilter) {
        string <- "./data/processed/{game}/{period}"
    } else {
        string <- "./data/processed/{game}/{period}/{filter}"
    }

    location <- glue::glue(
        string,
        game = args$game,
        period = args$period,
        filter = args$filter
    )
    if (!dir.exists(location)) {
        dir.create(location, recursive = TRUE)
    }
    return(location)
}


get_output_location <- function() {
    args <- get_args()
    LOCATION <- glue::glue(
        "./outputs/{game}/{period}/{filter}/",
        game = args$game,
        period = args$period,
        filter = args$filter
    )
    if (!dir.exists(LOCATION)) {
        dir.create(LOCATION, recursive = TRUE)
    }
    return(LOCATION)
}


get_args <- function() {
    ARGS <- commandArgs(trailingOnly = TRUE)
    if (length(ARGS) == 0) {
        GAME <- "aoe2"
        PERIOD <- "p02_v01"
        FILTER <- "rm_solo_open"
    } else {
        GAME <- ARGS[[1]]
        PERIOD <- ARGS[[2]]
        FILTER <- ARGS[[3]]
    }
    args <- list(
        game = GAME,
        period = PERIOD,
        filter = FILTER
    )
    return(args)
}


get_config_all <- function() {
    jsonlite::read_json("config.json")
}


get_config <- function() {
    args <- get_args()
    config <- get_config_all()
    list(
        filter = config[[args$game]][["filters"]][[args$filter]],
        period = config[[args$game]][["periods"]][[args$period]],
        game = args$game
    )
}



set_log <- function(path, id) {
    logpath <- file.path(path, paste0(id, ".log"))
    sink(logpath)
    cat("complete")
    sink()
}