


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
#' @param collapse How to collapse "Name (Original Name)" and "Email" column
#' @param late_cutoff (Character) Cutoff time (input as "hh:mm:ss"), participants join after this time will be considered late.
#'
#' @return a summary tibble
#'
process_class_studentsID <- function(df_processed,
                                     id_regex = ".*",
                                     collapse = "; ",
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

  ## Split Rows
  df1_ID_has_chr <- df1 %>% dplyr::filter(!is.na(ID)) # Has Matched ID
  df1_ID_NAs <- df1 %>% dplyr::filter(is.na(ID)) # Not has matched ID
  ## Group by and Summarize (according to whether ID is `NA`)
  df2_ID_has_chr <- df1_ID_has_chr %>% process_summary_ID(id_type = "chr", collapse = collapse)
  df2_ID_NAs <- df1_ID_NAs %>% process_summary_ID(id_type ="NA", collapse = collapse)
  ## Bind Rows
  df2 <- rbind(df2_ID_has_chr, df2_ID_NAs)

  # Convert Zero to NA & Back to Period Objs
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


# Helper: Process Summary for Extracted ID data frame ---------------------

#' Process Summary for Extracted ID Data Frame
#'
#' @param df_extracted Extracted ID data frame
#' @param id_type Whether `df_extracted` has ID column as character (match) or `NA` (no match)
#' @param collapse How to collapse "Name (Original Name)" and "Email" column
#'
#' @return A data frame with column: "ID" (Chr or `NA`), "Name", "Email", etc.
#'
process_summary_ID <- function(df_extracted,
                               id_type = c("chr", "NA"),
                               collapse = "; "
) {

  id_type <- match.arg(id_type)
  period_vars <- c("Before_Class", "During_Class", "After_Class", "Total_Time")

  # Grouped By
  df_grp <- switch (id_type,
                    "chr" = { df_extracted %>% dplyr::group_by(ID)  },
                    "NA" = { df_extracted %>% dplyr::group_by(`Name (Original Name)`, Email) }
  )
  ## Summarize Args
  summarise_args <- switch(id_type,
                           "chr" = {
                             rlang::exprs(
                               # Combine Names (If multiple per ID)
                               Name = paste_unique_collapse_na.rm(`Name (Original Name)`,
                                                                  collapse = collapse),
                               Email = paste_unique_collapse_na.rm(Email,
                                                                   collapse = collapse)
                             )
                           },
                           "NA" = { NULL }
  )
  # Summarize
  df_sum <- df_grp %>%
    dplyr::summarise(
      # Unquote Summarize Args
      !!!summarise_args,
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

  if(id_type == "chr") return(df_sum)

  # Rename & Add ID = `NA`
  df_sum %>%
    dplyr::rename(Name = `Name (Original Name)`) %>%
    dplyr::mutate(ID = NA_character_, .before = Name)


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
