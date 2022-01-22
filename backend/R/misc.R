

logit <- function(x) {
    log(x / (1 - x))
}


invlogit <- function(x) {
    exp(x) / (1 + exp(x))
}


as_footnote <- function(x, width = 140, add_Filter = TRUE) {

    if (add_Filter) {
        x <- c(
            glue("Filter: {filter}<br/>", filter = get("FILTER", envir = .GlobalEnv)),
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
    tibble(
        map_name = names(unlist(x)),
        map_class = unlist(x)
    )
}


get_config <- function(key = NULL) {
    x <- yaml::read_yaml("./data/raw/config.yml")
    x
    # ids <- vapply(x, function(y) y$id, character(1))
    # names(x) <- ids
    # if(is.null(key)) return(x)
    # x2 <- x[[key]]
    # assertthat::assert_that(key %in% names(x))
    # x2$start_limit_lower <- lubridate::ymd_hms(x2$start_limit_lower)
    # x2$start_limit_upper <- lubridate::ymd_hms(x2$start_limit_upper)
    # x2
}


lgl_to_char <- function(x){
    ifelse(x, "True", "False")
}


get_data_location <- function(game, period) {
    ## Create output directory if not exsits
    LOCATION <- glue(
        "./data/processed/{game}/{period}/",
        game = game,
        period = period
    )
    if (!dir.exists(LOCATION)) {
        dir.create(LOCATION, recursive = TRUE)
    }
    return(LOCATION)
}

get_output_location <- function(game, period, filter) {
    ## Create output directory if not exsits
    LOCATION <- glue(
        "./outputs/{game}/{period}/{filter}/",
        game = game,
        period = period,
        filter = filter
    )
    if (!dir.exists(LOCATION)) {
        dir.create(LOCATION, recursive = TRUE)
    }
    return(LOCATION)
}
