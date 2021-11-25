


# Process: Class Time -----------------------------------------------------


#' Process Class Time
#'
#' By providing `class_start` and `class_end`, the function compute time period before, during, and after class of
#' each sessions.
#'
#' @param df_cleaned A "zoom_participants" object (cleaned tibble)
#' @param class_start (Character) Time of class start (input as "hh:mm:ss" or "hh:mm"). If `NULL`, use "Start_Time" from "meeting_overview" attribute.
#' @param class_end (Character) Time of class end (input as "hh:mm:ss" or "hh:mm"). If `NULL`, use "End_Time" from "meeting_overview" attribute.
#'
#' @return A tibble with class "zoom_class" with the following columns added:
#' * \strong{"Class_Start"}: POSIXct of `class_start`
#' * \strong{"Class_End"}: POSIXct of `class_end`
#' * \strong{"Before_Class"}: Period before class started of each session
#' * \strong{"During_Class"}: Period during class of each session
#' * \strong{"After_Class"}: Period after class ended of each session
#'
#'
process_class_time <- function(df_cleaned,
                               class_start = NULL,
                               class_end = NULL
) {

  # If Not provide `class_start` or `class_end`
  if (is.null(class_start) || is.null(class_end)) {
    # AND has `meeting_overview` attributes
    meta_df <- attr(df_cleaned, "meeting_overview")
    if (!is.null(meta_df)) {
      # Set Default to that of Zoom Host
      class_start <- meta_df[["Start_Time"]]
      class_end <- meta_df[["End_Time"]]
      class_start_chr <- format(class_start, "%H:%M:%S")
      class_end_chr <- format(class_end, "%H:%M:%S")
      message("Set default:","\n",
              "`class_start` = ", class_start_chr, "\n`class_end` = ", class_end_chr)
    } else {
      stop("Must provide `class_start` and `class_end`.", call. = F)
    }
  } else {
    class_start <- lubridate::date(df_cleaned[["Join_Time"]]) +
      parse_time_flex(class_start)
    #lubridate::hms(class_start, quiet = T)
    class_end <- lubridate::date(df_cleaned[["Leave_Time"]]) +
      parse_time_flex(class_end)
    #lubridate::hms(class_end, quiet = T)
  }

  df_processed <- df_cleaned %>%
    # Add POSIXct for Class Start/End from Base Date
    dplyr::mutate(
      Class_Start = class_start,
      Class_End = class_end,
      .before = Join_Time
    ) %>%
    dplyr::mutate(
      Before_Class = get_before_class_time(Class_Start, Join_Time, Leave_Time),
      During_Class = get_during_class_time(Class_Start, Class_End,
                                           Join_Time, Leave_Time),
      After_Class = get_after_class_time(Class_End, Join_Time, Leave_Time),
      Total_Time = lubridate::as.period(Leave_Time - Join_Time),
      .after = Leave_Time
    )
  # Add Class: "zoom_class"
  df_processed <- create_zoom_class(df_processed,
                                    class_start = class_start[[1]], # Avoid recycled vector
                                    class_end = class_end[[1]])
  df_processed

}


# Flexible Parse Time -----------------------------------------------------



#' Flexible Parse Time
#'
#'
#'
#' @param chr Input can be "hh:mm:ss" or "hh:mm"
#'
#' @return A period object
#'
parse_time_flex <- function(chr) {

  parse_funs <- list(
    "a" = lubridate::hm,
    "b" = lubridate::hms
  )
  ### Find the first function that Not return `NA` (Test the first one)
  usable_fun_lgl <-
    purrr::map_lgl(names(parse_funs),
                   ~!is.na(parse_funs[[.x]]( chr[[1]], quiet = TRUE)))
  ### Not Found Any Funs: Error
  if(all(!usable_fun_lgl)) stop("All lubridate functions fail to parse time.")

  # If found, Execute !
  first_usable_fun <- parse_funs[[ which(usable_fun_lgl)[1] ]]
  first_usable_fun(chr)
}


# Before Class Time -------------------------------------------------------


#' Get time before class
#'
#' Get time before class as a period objects.
#' Compute from time after joined class to class start time or leave time, depending
#' on which comes earlier.
#'
#' @param start (POSIXct) class start time
#' @param join (POSIXct) join time
#' @param leave (POSIXct) leave time
#'
#' @return Period vector
#'
get_before_class_time <- function(start, join, leave) {

  out <- lubridate::as.period(numeric(length(start)))
  # Check NA
  has.Na <- is.na(start) | is.na(join) | is.na(leave)
  # Convert to POSIXct
  start <- as.POSIXct(start)
  leave <- as.POSIXct(leave)
  join <- as.POSIXct(join)
  # Time Diff
  diff <-   pmin(start, leave) - join
  pos_lgl <- diff > 0
  pos_lgl[is.na(pos_lgl)] <- FALSE # Replace NA with FALSE

  out[has.Na] <- lubridate::as.period(NA) # Input has NA assign NA
  out[pos_lgl] <- lubridate::as.period(diff[pos_lgl]) # Assign Positive Diff
  out[!pos_lgl] <- lubridate::as.period(NA) # Negative Diff as `NA`

  out

}


# After Class Time --------------------------------------------------------


#' Get time after class
#'
#' Get time after class as a period objects.
#' Compute time period from class end time or joined time, depending on which comes later, to
#' leave time.
#'
#' @param end (POSIXct) class end time
#' @param join (POSIXct) class join time
#' @param leave (POSIXct) class leave time
#'
#' @return Period Vector
#'
get_after_class_time <- function(end, join, leave) {

  has.Na <- is.na(end) | is.na(join) | is.na(leave)

  out <- lubridate::as.period(numeric(length(end)))
  # Convert to POSIXct
  end <- as.POSIXct(end)
  join <- as.POSIXct(join)
  leave <- as.POSIXct(leave)
  # Diff
  diff <-  leave - pmax(end,join)
  pos_lgl <- diff > 0
  pos_lgl[is.na(pos_lgl)] <- FALSE # Replace NA with FALSE

  out[has.Na] <- lubridate::as.period(NA) # Input has NA assign NA
  out[pos_lgl] <- lubridate::as.period(diff[pos_lgl]) # Assign Positive Diff
  out[!pos_lgl] <- lubridate::as.period(NA) # Negative Diff as `NA`

  out

}


# During Class Time -------------------------------------------------------



#' Get time during class
#'
#' Get time during class as a period objects.
#' Compute time period after class start or joined time (choose the later time) to class end time
#' or class leave time (choose the earlier time).
#'
#' @param start (POSIXct) Class start time
#' @param end (POSIXct) Class end time
#' @param join (POSIXct) Class join time
#' @param leave (POSIXct) Class leave time
#'
#' @return Period Vector
#'
get_during_class_time <- function(start, end, join, leave) {

  # Check NA
  has.Na <- is.na(start) | is.na(end) | is.na(join) | is.na(leave)

  out <- lubridate::as.period(numeric(length(start)))
  # Convert to POSICxt
  start <- as.POSIXct(start)
  end <- as.POSIXct(end)
  join <- as.POSIXct(join)
  leave <- as.POSIXct(leave)
  # Compute Diff
  diff <-  pmin(end, leave) - pmax(start, join)

  pos_lgl <- diff > 0
  pos_lgl[is.na(pos_lgl)] <- FALSE # Replace NA with FALSE

  out[has.Na] <- lubridate::as.period(NA) # Input has NA assign NA
  out[pos_lgl] <- lubridate::as.period(diff[pos_lgl]) # Assign Positive Diff
  out[!pos_lgl] <- lubridate::as.period(NA) # Negative Diff as `NA`

  out

}

