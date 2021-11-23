


# Process: Class Student ID -----------------------------------------------


#' Process Class Student ID
#'
#' Extract student IDs from `Name (Original Name)` column using regular expression (`id_regex`) into `ID` column.
#' Then, compute summary of each IDs in terms of:
#' `Name` (a combination of `Name (Original Name)` of each IDs),
#' `Email` (a combination of `Email` of each IDs),
#' `Session_Count` (total sessions of each student),
#' `First_Join_Time`, `Last_Leave_Time`, `Duration_Minutes`, `Multi_Device`.
#' Has an option to check whether student joined class later than specific time cutoff
#' and the late period will be include in `Late_Time` column.
#'
#'
#' @param df_processed time-processed tibble
#' @param id_regex (Character) regular expression used to extract student's ID from `Name (Original Name)` to `ID` column
#' @param late_cutoff (Character) Cutoff time (input as "hh:mm:ss"), participants join after this time will be considered late.
#'
#' @return a summary tibble
#'
process_class_studentsID <- function(df_processed,
                                     id_regex = ".*",
                                     late_cutoff = NULL
) {

  period_vars <- c("Before_Class", "During_Class", "After_Class", "Total_Time")


  df1 <- df_processed %>%
    # Convert Period Obj to Seconds
    dplyr::mutate(dplyr::across(dplyr::all_of(period_vars), lubridate::period_to_seconds)) %>%
    # Extract ID
    dplyr::mutate(
      ID = stringr::str_extract(`Name (Original Name)`, id_regex),
      .before = `Name (Original Name)`)

  # Summarize
  df2 <- df1 %>%
    dplyr::group_by(ID) %>%
    dplyr::summarise(
      # Combine Names (If multiple per ID)
      Name = paste_unique_collapse_na.rm(`Name (Original Name)`,
                                         collapse = "; "),
      Email = paste_unique_collapse_na.rm(Email,
                                          collapse = "; "),
      # Count Sessions
      Session_Count = max(Session),
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

# Helper: Paste Collapse with Unique value & NA removed --------------------------------------


#' Paste Collapse with with Unique value & NA removed
#'
#' @param x A vector to paste and collapse
#' @param collapse an optional character string to separate the results.
#'
#' @return A character vector
#'
paste_unique_collapse_na.rm <- function(x, collapse = NULL) {

  if(all(is.na(x))) return(NA_character_)

  x_na.rm <- stats::na.omit(x)
  x_unique <- unique(x_na.rm)
  paste(x_unique, collapse = collapse)

}
