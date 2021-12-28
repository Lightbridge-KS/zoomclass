

# Process: class session & device -----------------------------------------


#' Process Class Session & Multiple Device
#'
#' Add column `Session` for each grouping (`Name (Original Name)`, `Email`) by ranking `Join_Time`.
#' If `Join_Time` is exactly the same for each grouping, ranking will not increase.
#' Add column `Multi_Device` that check whether sessions of each grouping are overlapped with any others.
#' For overlapping sessions, `TRUE` will be placed at those sessions, otherwise `NA`.
#'
#' @param df_cleaned Cleaned data.frame
#'
#' @return A tibble with column "Session" and "Multi_Device" added.
#' @noRd
process_class_session_device <- function(df_cleaned){

  df_cleaned %>%
    # Grouping by Each Student (multiple devices with same name may interfere)
    dplyr::group_by(`Name (Original Name)`, Email) %>%
    # Session of each student
    dplyr::mutate(Session = dplyr::dense_rank(Join_Time), .after = "Email") %>%
    # Multi Device ?
    # If Overlap = must have more than 1 devices, If no overlap can't exclude multi device
    dplyr::mutate(
      Multi_Device = dplyr::if_else(is_overlap(Join_Time, Leave_Time), TRUE, NA)
    ) %>%
    dplyr::ungroup()

}

# Helper: Test Overlapping Intervals --------------------------------------


#' Is interval overlapping?
#'
#' Pairwise testing for each interval whether it is overlap with any others (exclusively).
#'
#' @param lwr (Numeric vector) Lower bound of the interval
#' @param upr (Numeric vector) Upper bound of the interval
#'
#' @return Logical vector corresponding to each elements of numeric vector
#' @noRd
is_overlap <- function(lwr, upr){

  # Sort both vector by `start` in ascending order
  lwr_ord <- order(lwr)
  lwr_ascend <- lwr[lwr_ord]
  upr_ascend <- upr[lwr_ord]
  last_i <- length(lwr)

  is.overlap <- logical(last_i)
  # Not Provide pair, just return FALSE
  if (length(lwr) == 1) {
    return(FALSE)
  }
  # first one
  if (any(upr_ascend[1] > lwr_ascend[-1])) {
    is.overlap[1] <- TRUE
  }
  # Last one
  if (any(lwr_ascend[last_i] < upr_ascend[-last_i] )) {
    is.overlap[last_i] <- TRUE
  }
  # Middle (if ≥ 3 pairs)
  if (last_i > 2) {
    for (i in 2:(last_i - 1)) {
      # Begin from No 2
      ## Is lower overlap with anyone before it
      is.lwr.overlap <- any(lwr_ascend[i] < upr_ascend[1:(i - 1)])
      ## Is upper overlap with anyone after it
      is.upr.overlap <- any(upr_ascend[i] > lwr_ascend[(i + 1):last_i])

      is.overlap[i] <- is.lwr.overlap || is.upr.overlap
    }
  }

  # Sort Back
  is.overlap[rank(lwr)]
  #data.frame(lwr = lwr_ascend[rank(lwr)], upr = upr_ascend[rank(lwr)])

}
