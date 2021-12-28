
# Process: Arrange --------------------------------------------------------



#' Arrange
#'
#' Arrange `zoom_participants`.
#' First, group by `arrange_group` then perform arrange in `arrange_by`.
#'
#' @param df_cleaned `zoom_participants` tibble
#' @param arrange_by (Character) How to arrange rows, must be one of:
#' * \strong{"Join_Time"}: arrange by `Join_Time`, earliest first
#' * \strong{"Name"}: arrange by `Name (Original Name)`
#' * \strong{"None"}: no arrange, preserve rows as original Zoom's participant file
#' @param arrange_group (Character) Indicate group of `arrange_by` will be affected.
#' * \strong{"Name-Email"}: group by `Name (Original Name)` and `Email`
#' * \strong{"Session"}: group by `Session`
#' * \strong{"None"}: no grouping variable
#'
#' @return An arranged tibble
#' @noRd
process_class_arrange <- function(df_cleaned,
                                  arrange_by = c("Join_Time", "Name", "None"),
                                  arrange_group = c("Name-Email", "Session", "None")
) {
  arrange_by <- match.arg(arrange_by)
  arrange_group <- match.arg(arrange_group)
  # No Arrange
  if (arrange_by == "None") return(df_cleaned)

  ## Arrange: Grouped by
  df_grouped <- switch(arrange_group,
                       "Name-Email" = {
                         dplyr::group_by(df_cleaned, `Name (Original Name)`, Email)
                       },
                       "Session" = {
                         dplyr::group_by(df_cleaned, Session)
                       },
                       "None" = {
                         df_cleaned
                       }
  )
  ## Arrange Expression
  arr_expr <- switch(arrange_by,
                     "Join_Time" = {
                       dplyr::expr(Join_Time)
                     },
                     "Name" = {
                       dplyr::expr(`Name (Original Name)`)
                     }
  )
  # Perform Arrange
  df_grouped %>%
    dplyr::arrange(!!arr_expr, .by_group = TRUE) %>%
    dplyr::ungroup()
}
