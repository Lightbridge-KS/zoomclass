
# Read Participant --------------------------------------------------------


#' Read Zoom's Participant File
#'
#' This function read Zoom's participant file from CSV to a tibble with sensible formatting and cleaner
#' column names. `readr::read_csv` will be used to read the data. `Join Time` and `Leave Time` will be formatted as POSIXct object.
#' Two new columns, `Name` and `Name_Original`, will be extracted from `Name (Original Name)`.
#' Every column names will be cleaned so that it easier to type in `R`.
#' If Zoom's participant file has meeting details such as "Meeting ID", "Topic", etc. at the first row,
#' it will be assign to "meeting_overview" attributes.
#'
#' @param file A path to a Zoom's participant file
#'
#' @return An tibble with class "zoom_participants" added
#' @export
#'
#' @examples
read_participants <- function(file) {

  # Read Meta
  meta_df <- read_meeting_overview(file = file)

  if (is.null(meta_df)) {
    # No Meta Data; read normally
    df <-  readr::read_csv(file = file, show_col_types = FALSE)
  } else {
    # Has Metadata at first row; skip first 3 rows
    df <- readr::read_csv(file = file, skip = 3, col_select = 1:7,
                          show_col_types = FALSE)
  }


  # Extract: Current & Original Name
  nm_df <- extract_CurrOrig_name(df[["Name (Original Name)"]])

  # Rename & Process
  df_cleaned <- df %>%
    # Add Row Number
    #dplyr::mutate(No = dplyr::row_number(), .before = `Name (Original Name)`) %>%
    # Rename Columns
    dplyr::rename(
      Email = "User Email",
      Join_Time = "Join Time", Leave_Time = "Leave Time",
      Duration_Minutes = "Duration (Minutes)", Rec_Consent = "Recording Consent"
    ) %>%
    # Date-Time Formatting: `mm/dd/yy hh:mm:ss AM/PM`
    dplyr::mutate(
      dplyr::across(
        tidyselect::contains("Time"), ~lubridate::parse_date_time(.x, "%m/%d/%Y %H:%M:%S %p")
      )) %>%
    # Extract Original and Current Name
    dplyr::mutate(
      Name = nm_df[["current"]],
      Name_Original = nm_df[["original"]],
      .after = `Name (Original Name)`
    )
  # Set Meta Data as Attribute
  df_cleaned <- create_zoom_participants(df_cleaned, meta_df)
  df_cleaned
}



# Helper: Read Meeting Overview -------------------------------------------


#' Read Meeting Details from Zoom's Participant File
#'
#' If "Meeting ID" was detected in the column names, read only 1 row (and column names) into a tibble and clean column names.
#' If not, return `NULL`.
#'
#' @param file A path to a Zoom's participant file
#'
#' @return a tibble or `NULL`
#'
read_meeting_overview <- function(file) {

  df <- readr::read_csv(
    file = file,
    n_max = 1,
    col_select = 1:7,
    show_col_types = FALSE # Silence Message
  )
  # Not Meta return `NULL`
  if( !c("Meeting ID" %in% names(df))) return(NULL)

  df %>%
    dplyr::rename(Meeting_ID = "Meeting ID",
                  Start_Time = "Start Time", End_Time = "End Time",
                  Email = "User Email", Duration_Minute = "Duration (Minutes)") %>%
    dplyr::mutate(
      dplyr::across(
        tidyselect::contains("Time"), ~lubridate::parse_date_time(.x, "%m/%d/%Y %H:%M:%S %p")
      )) %>%
    dplyr::mutate(Meeting_ID = as.character(Meeting_ID))



}

# Helper: Extract Current & Original Names --------------------------------


#' Extract Current and Original name to a Data.frame
#'
#' @param string Character vector
#'
#' @return A tibble with `current` and `original` column names
#'
extract_CurrOrig_name <- function(string) {

  # Regex that matched balanced parentheses
  ## https://stackoverflow.com/questions/546433/regular-expression-to-match-balanced-parentheses
  regex_parens <- "\\((?:[^)(]*(?R)?)*+\\)"

  ext_CurrOrig_nm <- function(string) {

    ## Matched Character Index
    m <- gregexpr(regex_parens, string, perl = TRUE)

    matches_parens <- regmatches(string, m)[[1]]
    last_paren_i <- length(matches_parens)

    ## If not found last `)` or has no matching parenthesis
    if (stringr::str_detect(string, "\\)$", negate = TRUE) || last_paren_i == 0) {
      orig_nm <- NA_character_
      cur_nm <- trimws(string)
    } else {
      # Original Name
      orig_nm <- matches_parens[[last_paren_i]] %>%
        stringr::str_remove_all("^\\(|\\)$")

      # Current Name
      cur_nm <- trimws(substr(string, 1, m[[1]][[last_paren_i]] - 1))
    }

    list(current = cur_nm, original = orig_nm)

  }

  purrr::map_dfr(string, ext_CurrOrig_nm)

}

