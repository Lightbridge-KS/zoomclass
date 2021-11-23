
# Student Summary ---------------------------------------------------------



#' Zoom Class Students Summary
#'
#' [class_students()] was designed to retrieve time information about each students
#' in Zoom's classroom at given time period. Input of this function (`data`) is a `zoom_participants` object as
#' returned by [read_participants()].
#'
#' By providing time of class started (`class_start`) and ended (`class_end`),
#' this function will compute time spent before, during, and after class of each students.
#' Furthermore, Late time period can be calculated from students who joined Zoom class later than certain cutoff time (`late_cutoff`).
#' If each students joined the classroom using multiple device in any sessions, `TRUE` will be placed in the "Multi_Device"
#' column of the output.
#'
#' The result will be displayed one row per student.
#' "Session_Count" will counts how many times each students join or leave the Zoom class.
#'
#' @param data A data frame (tibble) with class `zoom_participants`
#' @param class_start (Character) The time of class started, input as "hh:mm:ss".
#' If `NULL` (default) and `zoom_participants` has `meeting_overview` attribute, "Start_Time" of the attribute will be used.
#' @param class_end (Character) The time of class ended, input as "hh:mm:ss".
#' If `NULL` (default) and `zoom_participants` has `meeting_overview` attribute, "End_Time" of the attribute will be used.
#' @param late_cutoff (Character) Late time cutoff (input as "hh:mm:ss"). If provided, "Late_Time" will be included in the output columns.
#' @param period_to (Character) Indicate the units of "Before_Class", "During_Class", "After_Class" and "Total_Time" in the output.
#' Must be one of:
#' * \strong{"period"} (default): return as `lubridate::period` object
#' * \strong{"second"}: return as seconds (numeric)
#' * \strong{"minute"}: return as minute (numeric)
#' * \strong{"hour"}: return as hour (numeric)
#' @param round_digits (Integer) significant digits to round the numeric columns. If `NULL` (default), no round.
#'
#' @return A data frame (tibble) with class `zoom_class`. It has the following columns:
#' * \strong{"Name (Original Name)"}: the same column "Name (Original Name)" as input file
#' * \strong{"Name"}: Current name displayed in Zoom meeting of the participants.
#' * \strong{"Name_Original"}: Original name of the participants.
#'   It was extracted from the contents within the last balanced parentheses of "Name (Original Name)".
#' * \strong{"Email"}: from original "User Email" column
#' * \strong{"Session_Count"}: Show counts of how many session that each students joined or leaved Zoom class.
#' * \strong{"Class_Start"} (POSIXct): Compute from date of "Join_Time" with time specified by `class_start` argument.
#' * \strong{"Class_End"} (POSIXct): Compute from date of "Leave_Time" with time specified by `class_end` argument.
#' * \strong{"First_Join_Time"}: First join time of each students
#' * \strong{"Last_Leave_Time"}: Last leave time of each students
#' * \strong{"Before_Class"}: Time spent before `class_start` of each student.
#' * \strong{"During_Class"}: Time spent during class (between `class_start` and `class_end`) of each student.
#' * \strong{"After_Class"}: Time spent after `class_end` of each student.
#' * \strong{"Total_Time"}: "Before_Class" + "During_Class" + "After_Class"
#' * \strong{"Duration_Minutes"}: Sum of "Duration (Minutes)" for each students.
#'  **Notice:** `Total_Time` is likely to be less than original `Duration_Minutes` because the latter round the decimal down.
#'  This difference will be more pronounced when summed with multiple sessions.
#' * \strong{"Multi_Device"}: `TRUE` if students joined Zoom with multiple devices in any session.
#' * \strong{"Late_Time"} (Optional): If provide `late_cutoff` as "hh:mm:ss", "Late_Time" period is computed by `Join_Time` - `late_cutoff`.
#'
#' @seealso Checkout [class_studentsID()] for summary by extracted student's ID, and [class_session()] for summary of each session.
#'
#' @export
#'
#' @examples
class_students <- function(data,
                           class_start = NULL,
                           class_end = NULL,
                           late_cutoff = NULL,
                           period_to = c("period", "second", "minute", "hour"),
                           round_digits = NULL
) {

  period_to <- match.arg(period_to)
  ## Check Class
  if(!is_zoom_participants(data)) stop("`data` must inherit 'zoom_participants' class.")

  ## Get Attributes
  meta_df <- attr(data, "meeting_overview")

  # Process
  ## Process: Time
  df_timed <- process_class_time(data,
                                 class_start = class_start,
                                 class_end = class_end)
  # Get Attributes
  meta_df <- attr(df_timed, "meeting_overview")
  class_overview <- attr(df_timed, "class_overview")

  ## Process: Session & Multi Device
  df_processed <- process_class_session_device(df_timed) %>%
    ## Process: Class Summary
    process_class_students(late_cutoff = late_cutoff)

  ## Convert Period object to "second", "minute", "hour"
  if(period_to != "period"){
    df_processed <- vars_period_to_dbl(df_processed, unit = period_to,
                                       round_digits = round_digits)
  }

  # Set Class & Attributes
  df_out <-
    # "zoom_participants" class with "meeting_overview" attribute
    create_zoom_participants(df_processed, meta_df) %>%
    # "zoom_class" class with "class_overview" attribute
    create_zoom_class(class_start = class_overview[["class_start"]],
                      class_end = class_overview[["class_end"]],
                      late_cutoff = late_cutoff_POSIXct(
                        df_processed[["First_Join_Time"]], late_cutoff
                      ))
  df_out

}
