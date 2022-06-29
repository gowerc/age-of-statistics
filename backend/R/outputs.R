


save_plot <- function(p, id, args, type = "standard") {
    opts <- list(
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
    )[[type]]

    filepath <- file.path(
        get_output_location(args),
        paste0(id, ".", opts$ext)
    )

    ggsave(
        plot = p,
        filename = filepath,
        height = opts$height,
        width = opts$width,
        units = opts$units,
        dpi = opts$dpi,
        scale = opts$scale
    )
}


save_plot_no_arg <- function(p, id, path, type = "standard") {
    opts <- list(
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
    )[[type]]

    filepath <- file.path(
        path,
        paste0(id, ".", opts$ext)
    )

    ggsave(
        plot = p,
        filename = filepath,
        height = opts$height,
        width = opts$width,
        units = opts$units,
        dpi = opts$dpi,
        scale = opts$scale
    )
}





