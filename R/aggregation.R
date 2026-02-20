#' Roll up a data frame to academic/fiscal year totals
#'
#' @description
#' Aggregates a numeric column by academic/fiscal year, using [chunk_ay()] to
#' group the periods. Returns a data frame with one row per unique academic year.
#'
#' @param df A data frame containing at least the columns named by `chunk_col`
#'   and `value_col`.
#' @param value_col Character scalar. Name of the numeric column to aggregate.
#' @param chunk_col Character scalar. Name of the `time_chunk` column used for
#'   grouping. Defaults to `"semester"`.
#' @param fn A function used to aggregate values within each academic year.
#'   Defaults to `sum`. Common alternatives: `mean`, `median`, `max`, `min`.
#' @param na.rm Logical. Passed to `fn`. If `TRUE`, `NA` values are removed
#'   before aggregation. Default `TRUE`.
#'
#' @return A data frame with columns:
#'   - `ay`: character — academic/fiscal year string (e.g. `"2026-27"`)
#'   - one column named after `value_col` — the aggregated value
#'
#'   Rows are sorted chronologically by the earliest period start date within
#'   each academic year.
#'
#' @export
#'
#' @examples
#' use_chunk_preset("us_semester")
#'
#' df <- data.frame(
#'   semester   = time_chunk(c("fa26", "sp27", "su27", "fa27", "sp28")),
#'   enrollment = c(8200L, 7100L, 3400L, 8500L, 7300L)
#' )
#'
#' rollup_to_ay(df, value_col = "enrollment", chunk_col = "semester")
#' #   ay      enrollment
#' # 1 2026-27      18700
#' # 2 2027-28      15800
#'
#' rollup_to_ay(df, value_col = "enrollment", chunk_col = "semester", fn = mean)
rollup_to_ay <- function(df,
                          value_col,
                          chunk_col = "semester",
                          fn        = sum,
                          na.rm     = TRUE) {
  if (!is.data.frame(df)) {
    rlang::abort("`df` must be a data frame.", class = "timechunks_rollup_error")
  }
  if (!value_col %in% names(df)) {
    rlang::abort(
      glue::glue(
        "Column '{value_col}' not found in `df`. ",
        "Available columns: {paste(names(df), collapse = ', ')}"
      ),
      class = "timechunks_rollup_error"
    )
  }
  if (!chunk_col %in% names(df)) {
    rlang::abort(
      glue::glue(
        "Column '{chunk_col}' not found in `df`. ",
        "Available columns: {paste(names(df), collapse = ', ')}"
      ),
      class = "timechunks_rollup_error"
    )
  }
  chunk_vec <- df[[chunk_col]]
  if (!is_time_chunk(chunk_vec)) {
    rlang::abort(
      glue::glue(
        "Column '{chunk_col}' must be a `time_chunk` vector, ",
        "not {class(chunk_vec)[1]}."
      ),
      class = "timechunks_rollup_error"
    )
  }

  values <- df[[value_col]]
  ay_vec <- chunk_ay(chunk_vec)

  # Sort key: minimum start_date within each AY (for row ordering)
  starts <- start_date(chunk_vec)

  unique_ays <- unique(ay_vec[!is.na(ay_vec)])

  # Compute min start date per AY for ordering
  ay_min_start <- vapply(unique_ays, function(ay) {
    min(as.integer(starts[!is.na(ay_vec) & ay_vec == ay]), na.rm = TRUE)
  }, integer(1L))

  order_idx  <- order(ay_min_start)
  ordered_ays <- unique_ays[order_idx]

  agg_values <- vapply(ordered_ays, function(ay) {
    mask <- !is.na(ay_vec) & ay_vec == ay
    fn(values[mask], na.rm = na.rm)
  }, numeric(1L))

  result        <- data.frame(ay = ordered_ays, stringsAsFactors = FALSE)
  result[[value_col]] <- agg_values
  result
}
