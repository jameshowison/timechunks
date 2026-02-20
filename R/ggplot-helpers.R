#' Convert a time_chunk vector to an ordered factor
#'
#' @description
#' Creates an ordered factor suitable for use with `ggplot2` discrete scales.
#' Levels are ordered chronologically by start date, so ggplot2 will display
#' periods in the correct temporal order.
#'
#' For continuous scales, use [start_date()], [end_date()], or [mid_date()]
#' directly with `scale_x_date()`. See the ggplot2 vignette for examples.
#'
#' @param x A `time_chunk` vector.
#' @param labels Character scalar. Controls the level labels. One of:
#'   - `"code"` (default) — `"fa26"`, `"sp27"`, ...
#'   - `"name"` — `"Fall 2026"`, `"Spring 2027"`, ...
#'   - `"ay"` — `"2026-27"`, `"2026-27"`, ... (may repeat)
#'   - `"key"` — sortable composite key
#'   - `"iso_date"` — start date string
#'   - Any glue template string (e.g. `"{name} ({ay})"`)
#'
#' @return An ordered factor of the same length as `x`, with levels in
#'   chronological order.
#' @export
#'
#' @examples
#' use_chunk_preset("us_semester")
#' x <- time_chunk(c("su27", "fa26", "sp27"))
#'
#' as_chunk_factor(x, labels = "code")
#' # ordered factor: fa26 < sp27 < su27
#'
#' as_chunk_factor(x, labels = "name")
#' # ordered factor: Fall 2026 < Spring 2027 < Summer 2027
as_chunk_factor <- function(x, labels = "code") {
  .check_time_chunk(x, "as_chunk_factor")

  if (length(x) == 0L) {
    return(factor(character(0L), ordered = TRUE))
  }

  # Get start_date for each element (used for sorting unique periods)
  starts <- vctrs::field(x, "start_date")

  # Build the ordered set of unique periods by start_date
  unique_starts <- sort(unique(starts[!is.na(starts)]))

  # For each unique start date, find the first matching element to get labels,
  # then deduplicate while preserving chronological order (e.g. labels = "ay"
  # may produce the same string for multiple periods).
  level_labels <- vapply(unique_starts, function(sd) {
    idx <- which(starts == sd)[1L]
    format(x[idx], style = labels)
  }, character(1L))
  level_labels <- unique(level_labels)

  # Map each element to its label
  value_labels <- format(x, style = labels)
  # NA elements stay NA
  value_labels[is.na(starts)] <- NA_character_

  factor(value_labels, levels = level_labels, ordered = TRUE)
}
