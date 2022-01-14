


# Zoom Chat ---------------------------------------------------------------


#' New zoom_chat object
#'
#' @param x a data frame
#'
#' @return a data frame with class "zoom_chat" appended
#' @noRd
new_zoom_chat <- function(x = data.frame()){

  stopifnot(is.data.frame(x)) # Check DF

  if(inherits(x, "zoom_chat")) return(x) # Already inherits: return

  # Assign "zoom_chat" as child
  class(x) <- c("zoom_chat", class(x))
  x
}

# Zoom Participant --------------------------------------------------------



#' Create zoom_participants
#'
#' Create "zoom_participants" class and add "meeting_overview" attribute.
#'
#' @param x object
#' @param meeting_overview attribute to add
#'
#' @return a "zoom_participants" object with "meeting_overview" attribute
#' @noRd
create_zoom_participants <- function(x, meeting_overview) {

  x <- new_zoom_participants(x)
  attr(x, "meeting_overview") <- meeting_overview
  x
}

#' New zoom_participants
#'
#' Construct "zoom_participants" class (must be data.frame)
#'
#' @param x object
#'
#' @return a "zoom_participants" object
#' @noRd
new_zoom_participants <- function(x = data.frame()) {

  stopifnot(is.data.frame(x)) # Check DF

  if(inherits(x, "zoom_participants")) return(x) # Already inherits: return

  # Assign "zoom_participants" as child
  class(x) <- c("zoom_participants", class(x))
  x
}

#' Is zoom_participants
#'
#' Check whether an object inherits "zoom_participants" class.
#'
#' @param x object
#'
#' @return Logical
#' @noRd
is_zoom_participants <- function(x){
  is(x, "zoom_participants")
}


# Zoom Class --------------------------------------------------------------



#' Create zoom_class
#'
#' Create "zoom_class" object with "class_overview" attribute.
#'
#' @param x a "zoom_participants" object
#' @param class_start Vector included in "class_overview" attribute.
#' @param class_end Vector included in "class_overview" attribute.
#' @param late_cutoff Vector included in "class_overview" attribute.
#'
#' @return a "zoom_class" object with "class_overview" attribute.
#' @noRd
create_zoom_class <- function(x,
                              class_start, class_end, late_cutoff = NA
) {

  x <- new_zoom_class(x)
  class_overview <- c(class_start = class_start,
                      class_end = class_end,
                      late_cutoff = late_cutoff)
  attr(x, "class_overview") <- class_overview
  x
}

#' New zoom_class
#'
#' Add "zoom_class" class to "zoom_participants" object
#'
#' @param x "zoom_participants" object
#'
#' @return "zoom_class" object
#' @noRd
new_zoom_class <- function(x) {

  # Check Class: must be data.frame and "zoom_participants" class
  stopifnot(is.data.frame(x), inherits(x, "zoom_participants"))
  if(inherits(x, "zoom_class")) return(x) # Already inherits: return
  # Assign "zoom_class" as child
  class(x) <- c("zoom_class", class(x))
  x

}

#' Is zoom_class
#'
#' Check whether an object inherits "zoom_class" class.
#'
#' @param x object
#'
#' @return Logical
#' @noRd
is_zoom_class <- function(x){
  is(x, "zoom_class")
}

