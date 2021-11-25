


# Process: Class Students --------------------------------------------------


#' Process Class Students
#'
#' Compute summary of each student in terms of: `Session_Count` (total sessions of each student),
#' `First_Join_Time`, `Last_Leave_Time`, `Duration_Minutes`, `Multi_Device`.
#' Has an option to check whether student joined class later than specific time cutoff
#' and the late period will be include in `Late_Time` column.
#'
#' @param df_processed time-processed tibble
#' @param late_cutoff (Character) Cutoff time (input as "hh:mm:ss"), participants join after this time will be considered late.
#'
#'
#' @return a summary tibble
#'
process_class_students <- function(df_processed, late_cutoff = NULL) {

  period_vars <- c("Before_Class", "During_Class", "After_Class", "Total_Time")

  ## Convert Period Obj to Secounds
  df1 <- df_processed %>%
    dplyr::mutate(dplyr::across(dplyr::all_of(period_vars), lubridate::period_to_seconds))
  # Summarize
  df2 <- df1 %>%
    dplyr::group_by(`Name (Original Name)`, Name, Name_Original, Email) %>%
    dplyr::summarise(Session_Count = max(Session),
                     # Class Start & End (unique to prevent vector recycling)
                     dplyr::across(c(Class_Start, Class_End), unique),
                     # POSIXct
                     First_Join_Time = min(Join_Time),
                     Last_Leave_Time = max(Leave_Time),
                     # Period Objects -> Sum all time
                     dplyr::across(dplyr::all_of(period_vars), ~sum(.x, na.rm = TRUE)),
                     # Numeric
                     Duration_Minutes = sum(Duration_Minutes, na.rm = TRUE),
                     # Logical -> Any Multiple Device ?
                     Multi_Device = any(Multi_Device),
                     .groups = "drop")
  ## Convert Zero to NA & Back to Period Objs
  df3 <- df2 %>%
    dplyr::mutate(
      dplyr::across(dplyr::all_of(period_vars),
                    ~lubridate::seconds_to_period(dplyr::na_if(.x, 0)))
    )

  # Late Time
  ## For No late Time return
  if(is.null(late_cutoff)) return(df3)

  ## Input `late_cutoff` as hh:mm:ss
  # late_cutoff <- lubridate::date(df3[["First_Join_Time"]]) +
  #   lubridate::hms(late_cutoff, quiet = T)
  late_cutoff <- late_cutoff_POSIXct(df3[["First_Join_Time"]], late_cutoff)
  ## Perform add Late_Time
  df3 %>%
    dplyr::mutate(
      #Late_Cutoff = late_cutoff,
      Late_Time = get_late_time(First_Join_Time, late_cutoff = late_cutoff)
    )
}

# Helper: Late Cutoff as POSIXct ------------------------------------------



#' Get Late Cutoff as POSIXct
#'
#' @param join_POSIXct (POSIXct) Join time
#' @param late_cutoff (Character) Late Cutoff as "hh:mm:ss"
#'
#' @return `late_cutoff` as POSIXct
#'
late_cutoff_POSIXct <- function(join_POSIXct,
                                late_cutoff = NULL
) {

  if(is.null(late_cutoff)) return(as.POSIXct(NA))
  ## In case of meeting was joined span 2 or more days
  first_date <- min(lubridate::date(join_POSIXct))
  late_cutoff_POSIXct <- first_date + lubridate::hms(late_cutoff, quiet = T)
  late_cutoff_POSIXct

}


# Helper: Late Time -------------------------------------------------------



#' Get Late Time
#'
#' Get late time if joined after `late_cutoff`, otherwise `NA` is returned.
#'
#' @param join (POSIXct) Join Time
#' @param late_cutoff (POSIXct) Cutoff time, after this time will be considered late.
#'
#' @return Period vector
#'
get_late_time <- function(join, late_cutoff) {

  has.Na <- is.na(join) | is.na(late_cutoff)

  out <- lubridate::as.period(numeric(length(join)))
  ### Must Convert to POSIXct first
  diff <- as.POSIXct(join) - as.POSIXct(late_cutoff)
  pos_lgl <- diff > 0
  pos_lgl[is.na(pos_lgl)] <- FALSE # Replace NA with FALSE

  out[has.Na] <- lubridate::as.period(NA) # Input has NA assign NA
  out[pos_lgl] <-  lubridate::as.period(diff[pos_lgl]) # Assign Positive Diff
  out[!pos_lgl] <- lubridate::as.period(NA) # Negative Diff as `NA`

  out
}
