


# Convert Period variable in DF to double ---------------------------------


#' Convert Period Variable in DF to Double
#'
#' Suffix `*_unit` will be added to the converted column names.
#'
#' @param data a data.frame
#' @param unit (Character) specify unit of the converted numeric output
#' @param round_digits significant digits to round. If `NULL`, no round.
#'
#' @return A data.frame with period object vars converted to numeric with specified unit.
#' @noRd
vars_period_to_dbl <- function(data,
                               unit = c("second", "minute", "hour"),
                               round_digits = NULL
) {
  unit <- match.arg(unit)

  nm <- character(length(names(data))) # Empty
  ## IS Period Vars ?
  period_vars_lgl <- purrr::map_lgl(data, lubridate::is.period)
  ## Get Period var names and Modify add Suffix `*_unit`
  period_vars_nm <- names(data)[period_vars_lgl]
  period_vars_nm_mod <- paste0(period_vars_nm, "_" ,unit)
  ## Not Period var names
  not_period_vars_nm <- names(data)[!period_vars_lgl]
  # Assign
  nm[period_vars_lgl] <- period_vars_nm_mod
  nm[!period_vars_lgl] <- not_period_vars_nm

  data %>%
    dplyr::mutate(dplyr::across(
      which(period_vars_lgl),
      #tidyselect::vars_select_helpers$where(lubridate::is.period),
      ~period_to_dbl(.x, unit = unit, round_digits = round_digits)
    )) %>%
    stats::setNames(nm)


}

# Convert Period object to Double -----------------------------------------


#' Convert Period Object to Double
#'
#' @param x period object
#' @param unit (Character) specify unit of the converted numeric output
#' @param round_digits significant digits to round. If `NULL`, no round.
#'
#' @return a double vector
#' @noRd
period_to_dbl <- function(x,
                          unit = c("second", "minute", "hour"),
                          round_digits = NULL
) {

  unit <- match.arg(unit)
  sec <- lubridate::period_to_seconds(x)

  out <- switch (unit,
                 "second" = { sec },
                 "minute" = { sec/60 },
                 "hour" = { sec/3600 }
  )
  # round_digits = NULL -> Not Round
  if(is.null(round_digits)) return(out)
  ## Round
  round(out, digits = round_digits)

}
