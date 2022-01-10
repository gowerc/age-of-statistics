


output <- R6::R6Class(
    classname = "output",
    public = list(
        plot = NULL,
        data = NULL,
        style = NULL,
        initialize = function(plot, data) {
            self$plot <- plot
            self$data <- data
        }
    )
)



outputManager <- R6::R6Class(
    classname = "outputManager",
    public = list(
        outputs = list(),
        add_output = function(output, id, style = "standard") {
            assert_that("output" %in% class(output))
            output$style <- style
            self$outputs[[id]] <- output
        },
        write_json = function(path) {
            dat_list <- purrr::map(self$outputs, "data")
            names(dat_list) <- names(self$outputs)
            jsonlite::write_json(
                x = map(dat_list, function(x) mutate(x, across(where(is.array), as.numeric))),
                path = path
            )
        },
        save_all = function(location, opts = opts_default) {
            outputs <- self$outputs
            for (id in names(outputs)) {
                opts_output <- opts[[outputs[[id]]$style]]
                ggsave(
                    plot = outputs[[id]]$plot,
                    filename = file.path(location, paste0(id, ".", opts_output$ext)),
                    height = opts_output$height,
                    width = opts_output$width,
                    units = opts_output$units,
                    dpi = opts_output$dpi,
                    scale = opts_output$scale
                )
            }
            # self$write_json(file.path(location, "cohort_data.json"))
            jsonlite::write_json(
                path = file.path(location, "cohort_data.json"),
                x = list(finished = TRUE)
            )
        }
    )
)


opts_default <- list(
    standard = list(
        height = 5,
        width = 9,
        units = "in",
        dpi = 150,
        scale = 1.2,
        ext = "png"
    ),
    square = list(
        height = 6.75,
        width = 9,
        units = "in",
        dpi = 150,
        scale = 1.2,
        ext = "png"
    )
)



