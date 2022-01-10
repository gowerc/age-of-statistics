
#' @import DBI
#' @import RPostgres
#' @export
get_connection <- function() {
    DBI::dbConnect(
        RPostgres::Postgres(),
        dbname = Sys.getenv("APP_DB"),
        host = Sys.getenv("APP_HOST"),
        port = 5432,
        user = Sys.getenv("APP_USER"),
        password = Sys.getenv("APP_PASSWORD")
    )
}



#' @importFrom jsonlite read_json
#' @import tibble
#' @importFrom purrr map2_df map_chr map_dbl
#' @export
get_patchmeta <- function() {
    meta_raw <- read_json("./data/ad_patchmeta.json")

    meta_raw2 <- meta_raw[!names(meta_raw) %in% "language"]

    map2_df(
        meta_raw2,
        names(meta_raw2),
        function(x, nam) {
            tibble(
                string = map_chr(x, "string"),
                id = map_dbl(x, "id"),
                type = nam
            )
        }
    )
}


