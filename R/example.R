#' Get path to raw zoomclass example
#'
#' zoomclass comes bundled with a number of sample files in its `inst/extdata`
#' directory. This function make them easy to access
#'
#' @param file Name of file. If `NULL`, the example files will be listed.
#' @export
#' @examples
#' library(zoomclass)
#' zoomclass_example()
#' zoomclass_example("participants_heroes.csv")
zoomclass_example <- function(file = NULL) {

  if (is.null(file)) {
    dir(system.file("extdata", package = "zoomclass"))

  } else {
    system.file("extdata", file, package = "zoomclass", mustWork = TRUE)
  }

}
