

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


get_map_class <- function() {
    x <- yaml::read_yaml("./data/raw/maps.json")
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
        string <- "./data/processed/{period}"
    } else {
        string <- "./data/processed/{period}/{filter}"
    }

    location <- glue::glue(
        string,
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
        "./outputs/{period}/{filter}/",
        period = args$period,
        filter = args$filter
    )
    if (!dir.exists(LOCATION)) {
        dir.create(LOCATION, recursive = TRUE)
    }
    return(LOCATION)
}


get_args <- function() {
    args <- commandArgs(trailingOnly = TRUE)
    if (length(args) == 0) {
        cfg <- get_config_all()
        period <- cfg$default$period
        filter <- cfg$default$filter
    } else {
        period <- args[[1]]
        if (length(args) > 1) {
            filter <- args[[2]]
        } else {
            filter <- ""
        }
    }
    args <- list(
        period = period,
        filter = filter
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
        filter = config[["filters"]][[args$filter]],
        period = config[["periods"]][[args$period]]
    )
}



set_log <- function(path, id) {
    logpath <- file.path(path, paste0(id, ".log"))
    sink(logpath)
    cat("complete")
    sink()
}