

logit <- function(x) {
    log(x / (1 - x))
}


invlogit <- function(x) {
    exp(x) / (1 + exp(x))
}


as_footnote <- function(x, args, width = 140, add_Filter = TRUE) {

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


get_data_location <- function(args, nofilter=FALSE) {
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


get_output_location <- function(args) {
    LOCATION <- glue::glue(
        "./outputs/{period}/{filter}",
        period = args$period,
        filter = args$filter
    )
    if (!dir.exists(LOCATION)) {
        dir.create(LOCATION, recursive = TRUE)
    }
    return(LOCATION)
}


get_args <- function(period = NULL, filter = NULL) {
    args <- commandArgs(trailingOnly = TRUE)
    if (length(args) == 0) {
        config <- get_config_all()
        if (is.null(period) || is.null(filter)) {
            period <- config$default$period
            filter <- config$default$filter
        } else {
            assert_that(
                period %in% names(config$periods),
                filter %in% names(config$filter)
            )
        }
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
    jsonlite::read_json(
        file.path("data", "raw", "config.json")
    )
}


get_config <- function(args) {
    config <- get_config_all()
    list(
        filter = config[["filters"]][[args$filter]],
        period = config[["periods"]][[args$period]]
    )
}



get_footnotes <- function(id, args, add_Filter = TRUE) {
    footnotes <- jsonlite::read_json(
        file.path("data", "raw", "footnotes.json")
    )
    footnotes2 <- footnotes[[id]] %>% as_footnote(args, add_Filter = add_Filter)
    return(footnotes2)
}
