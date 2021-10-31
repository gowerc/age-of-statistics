get_meta_version <- function(start_dt) {
    case_when(
        start_dt <= ymd_hms("2021-8-09T00-00-00") ~ "A",
        start_dt <= ymd_hms("2021-10-05T00-00-00") ~ "B",
        TRUE ~ "C"
    )
}


logit <- function(x) {
    log(x / (1 - x))
}


invlogit <- function(x) {
    exp(x) / (1 + exp(x))
}


as_footnote <- function(x, width = 140, add_cohort = TRUE) {

    if (add_cohort) {
        x <- c(
            glue("Cohort: {cohort}<br/>", cohort = get("COHORT", envir = .GlobalEnv)),
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
    x <- yaml::read_yaml("./data-raw/map_class.yml")
    tibble(
        map_name = names(unlist(x)),
        map_class = unlist(x)
    )
}


get_cohort_opts <- function(key = NULL) {
    x <- yaml::read_yaml("./data-raw/cohort.yml")
    ids <- vapply(x, function(y) y$id, character(1))
    names(x) <- ids
    if(is.null(key)) return(x)
    x2 <- x[[key]]
    assertthat::assert_that(key %in% names(x))
    x2$start_limit_lower <- lubridate::ymd_hms(x2$start_limit_lower)
    x2$start_limit_upper <- lubridate::ymd_hms(x2$start_limit_upper)
    x2
}


lgl_to_char <- function(x){
    ifelse(x, "True", "False")
}

