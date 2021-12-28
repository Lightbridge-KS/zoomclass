
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
#' @return A data frame (tibble) with class "zoom_participants". It has the following new columns:
#' * \strong{"Name (Original Name)"}: the same column "Name (Original Name)" as input file
#' * \strong{"Name"}: Current name displayed in Zoom meeting of the participants.
#' * \strong{"Name_Original"}: Original name of the participants.
#'   It was extracted from the contents within the last balanced parentheses of "Name (Original Name)".
#' * \strong{"Email"}: from original "User Email" column
#' * \strong{"Join_Time"}: from original "Join Time" column
#' * \strong{"Leave_Time"}: from original "Leave Time" column
#' * \strong{"Duration_Minutes"}: from original "Duration (Minutes)" column
#' * \strong{"Rec_Consent"}: from original "Recording Consent" column
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
    df <- readr::read_csv(file = file, skip = 3, #col_select = 1:7,
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
      Duration_Minutes = "Duration (Minutes)"
    ) %>%
    ## Rename column if present (this technique works)
    dplyr::rename_with(.fn = ~paste0("Rec_Consent"),
                       .cols = tidyselect::contains("Recording Consent")) %>%
    # Date-Time Formatting: `mm/dd/yy hh:mm:ss AM/PM`
    dplyr::mutate(
      dplyr::across(
        tidyselect::contains("Time"), parse_pp_datetime
      )) %>%
    # Extract Original and Current Name
    dplyr::mutate(
      Name = nm_df[["current"]],
      Name_Original = nm_df[["original"]],
      .after = `Name (Original Name)`
    )
  # Set Meta Data as Attribute
  #attr(df_cleaned, "meeting_overview") <- meta_df
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
#' @noRd
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


# Helper: Parse Date-Time Formatting --------------------------------------


#' Parse Date-Time formatting Using Lubridate Function
#'
#' @param chr Character vector of date-time
#'
#' @return A POSIXct
#' @noRd
#'
parse_pp_datetime <- function(chr){

  ## Whether "AM" or "PM" is at the end or not (Test the first one)
  has_am_pm <- stringr::str_detect(chr[[1]], "(A|P)M$")

  dt <- if (has_am_pm) {
    ## If has "AM" or "PM", assume `mm/dd/yyyy hh:mm:ss AM/PM`
    lubridate::mdy_hms(chr, quiet = T)
  } else {
    ## If not, assume `dd/mm/yyyy hh:mm:ss`
    lubridate::dmy_hms(chr, quiet = T)
  }
  # Success -> return
  if( !is.na(dt[[1]])) return(dt)

  ## If all fail
  parse_funs <- list(
    "a" = lubridate::ymd_hms,
    "b" = lubridate::ydm_hms
  )
  ### Find the first function that Not return `NA` (Test the first one)
  usable_fun_lgl <-
    purrr::map_lgl(names(parse_funs),
                   ~!is.na(parse_funs[[.x]]( chr[[1]], quiet = T)))

  ### Not Found Any Funs: Error
  if(all(!usable_fun_lgl)) stop("All lubridate functions fail to parse date-time.")

  # If found, Execute !
  first_usable_fun <- parse_funs[[ which(usable_fun_lgl)[1] ]]

  first_usable_fun(chr)

}

# Helper: Extract Current & Original Names --------------------------------


#' Extract Current and Original name to a Data.frame
#'
#' @param string Character vector
#'
#' @return A tibble with `current` and `original` column names
#' @noRd
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

