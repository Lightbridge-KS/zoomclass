
# Class Session -----------------------------------------------------------



#' Zoom Class Session Summary
#'
#' [class_session()] was designed to retrieve time information about each student's session
#' in Zoom's classroom at given time period. Input of this function (`data`) is a `zoom_participants` object as
#' returned by [read_participants()].
#'
#' By providing time of class started (`class_start`) and ended (`class_end`),
#' this function will compute time spent before, during, and after class of each sessions.
#' If each student joined the classroom using multiple device, `TRUE` will be placed in the "Multi_Device"
#' column of the output.
#'
#' The output will displayed one row per session of each student.
#' (e.g., If student "A" joined more than one time, there will be multiple rows of "A").
#' Finally, rows will be arranged as specified by `arrange_by` with grouping by `arrange_group`.
#'
#' @param data A data frame (tibble) with class `zoom_participants`
#' @param class_start (Character) The time of class started, input as "hh:mm:ss" or "hh:mm".
#' If `NULL` (default) and `zoom_participants` has `meeting_overview` attribute, "Start_Time" of the attribute will be used.
#' @param class_end (Character) The time of class ended, input as "hh:mm:ss" or "hh:mm".
#' If `NULL` (default) and `zoom_participants` has `meeting_overview` attribute, "End_Time" of the attribute will be used.
#' @param arrange_by (Character) How to arrange rows, must be one of:
#' * \strong{"Join_Time"}: arrange by `Join_Time`, earliest first
#' * \strong{"Name"}: arrange by `Name (Original Name)`
#' * \strong{"None"}: no arrange, preserve rows as original Zoom's participant file
#' @param arrange_group (Character) Indicate group of `arrange_by` will be affected.
#' * \strong{"Name-Email"}: group by `Name (Original Name)` and `Email`
#' * \strong{"Session"}: group by `Session`
#' * \strong{"None"}: no grouping variable
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
#' * \strong{"Session"}: Indicate active session(s) in Zoom of each students.
#' Computed by ranking "Join_Time" in the grouping variables: "Name (Original Name)" and "Email".
#' * \strong{"Class_Start"} (POSIXct): Compute from date of "Join_Time" with time specified by `class_start` argument.
#' * \strong{"Class_End"} (POSIXct): Compute from date of "Leave_Time" with time specified by `class_end` argument.
#' * \strong{"Join_Time"}: from the original "Join Time" column
#' * \strong{"Leave_Time"}: from the original "Leave Time" column
#' * \strong{"Before_Class"}: Time spent before `class_start` of each session.
#' * \strong{"During_Class"}: Time spent during class (between `class_start` and `class_end`) of each session.
#' * \strong{"After_Class"}: Time spent after `class_end` of each session.
#' * \strong{"Total_Time"}: "Before_Class" + "During_Class" + "After_Class"
#' * \strong{"Duration_Minutes"}: from original "Duration (Minutes)" column
#' * \strong{"Rec_Consent"}: from the original "Recording Consent" column
#' * \strong{"Multi_Device"}: `TRUE` if any sessions of each student joined Zoom with multiple devices.
#' It is computed by checking whether "Join_Time" and "Leave_Time" was overlapped with other sessions within each students.
#' Otherwise, `NA` will be returned because there is no way to be certain that students joined with a single device.
#'
#' @seealso Checkout [class_students()] for summary of each students.
#' @export
#'
#' @examples
class_session <- function(data,
                          class_start = NULL,
                          class_end = NULL,
                          arrange_by = c("Join_Time", "Name", "None"),
                          arrange_group = c("Name-Email", "Session", "None"),
                          period_to = c("period", "second", "minute", "hour"),
                          round_digits = NULL
) {

  arrange_by <- match.arg(arrange_by)
  arrange_group <- match.arg(arrange_group)
  period_to <- match.arg(period_to)
  ## Check Class
  if(!is_zoom_participants(data)) stop("`data` must inherit 'zoom_participants' class.")

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
    ## Process: Arrange Rows
    process_class_arrange(arrange_by = arrange_by, arrange_group = arrange_group)

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
                      late_cutoff = as.POSIXct(NA))
  df_out

}
