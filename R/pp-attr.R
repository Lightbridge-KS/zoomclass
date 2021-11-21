

# Meeting Overview --------------------------------------------------------


#' Meeting Overview
#'
#' Retrieve "meeting_overview" information such as "Meeting_ID", "Topic", etc. from "zoom_participants" object.
#'
#' @param data "zoom_participants" object
#'
#' @return "meeting_overview" attributes:
#' * A tibble with following column names: "Meeting_ID", "Topic", "Start_Time", "End_Time", "Email", "Duration_Minute", "Participants"
#' @export
#'
#' @examples
meeting_overview <- function(data) {

  if(!is_zoom_participants(data)) stop("`data` must inherit 'zoom_participants' class.", call. = F)
  attr(data, "meeting_overview")

}


# Class Overview ----------------------------------------------------------


#' Class Overview
#'
#' @param data "zoom_class" object
#'
#' @return "class_overview" attributes:
#' * A tibble with following column names: "class_start", "class_end", "late_cutoff"
#' @export
#'
#' @examples
class_overview <- function(data) {

  if(!is_zoom_class(data)) stop("`data` must inherit 'zoom_class' class.", call. = F)
  attr(data, "class_overview")
}
