#' Count Zoom Chat Message
#'
#' Count how many times each participants replies in the Zoom chat box and also group messages entries per participants.
#'
#' @param data a tibble with class "zoom_chat".
#' @param collapse (Character) deliminator character to separate each entries of participants
#' @param extract_id (Character) Whether to extract ID number from `Name` column or not.
#' @param id_regex (Character) If `extract_id = TRUE`, This would specify regular expression (`{stringr}`'s style) to extract ID.
#'
#' @return A tibble with the following columns:
#' * \strong{ID}: If `extract_id = TRUE`, this is the ID of the participants.
#' * \strong{Name}: Name of each participants
#' * \strong{Message_Count}: Counts of how many times each participants replies
#' * \strong{Content}: All replies of each participants, separated by `collapse` argument.
#' @export
#'
#' @examples
zoom_chat_count <- function(data,
                            collapse = " ~ ",
                            extract_id = FALSE,
                            id_regex = "[:digit:]+"
){

  if( !is_zoom_chat(data)) stop("`data` must be a 'zoom_chat' data frame.")

  df1 <- data %>%
    dplyr::group_by(Name) %>%
    dplyr::summarise(
      Message_Count = length(Content),
      Content = paste(Content, collapse = collapse),
      .groups = "drop"
    )
  ## Not Extract ID return
  if( !extract_id) return(df1)

  ## Extract ID
  df1 %>%
    dplyr::mutate(ID = stringr::str_extract(Name, id_regex),
                  .before = Name)

}
