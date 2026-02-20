# Arithmetic methods for time_chunk
#
# Strategy: represent each period as a "global index" based on academic year:
#
#   global_index = ay_offset * num_periods + (period_index - 1)
#
# where ay_offset is the calendar year in which the academic year begins.
# This gives a linear, gap-free integer sequence over all periods:
#
#   Fall 2026 (us_semester): ay_offset=2026, period_index=1 → 2026*3 + 0 = 6078
#   Spring 2027:             ay_offset=2026, period_index=2 → 2026*3 + 1 = 6079
#   Summer 2027:             ay_offset=2026, period_index=3 → 2026*3 + 2 = 6080
#   Fall 2027:               ay_offset=2027, period_index=1 → 2027*3 + 0 = 6081
#
# Addition/subtraction simply moves along this integer line, then maps back.


#' Add or subtract periods from a time_chunk
#'
#' @description
#' Move a `time_chunk` forward (`+`) or backward (`-`) by an integer number
#' of periods, using the active calendar.
#'
#' @param e1 A `time_chunk` vector (for `+`) or a `time_chunk` or integer.
#' @param e2 An integer scalar (number of periods to move).
#'
#' @return A `time_chunk` vector of the same length.
#' @export
#'
#' @examples
#' use_chunk_preset("us_semester")
#' time_chunk("fa26") + 1L   # Spring 2027
#' time_chunk("fa26") + 2L   # Summer 2027
#' time_chunk("fa26") + 3L   # Fall 2027
#' time_chunk("sp27") - 1L   # Fall 2026
"+.time_chunk" <- function(e1, e2) {
  if (is_time_chunk(e1) && is.numeric(e2)) {
    .shift_time_chunk(e1, as.integer(e2))
  } else if (is.numeric(e1) && is_time_chunk(e2)) {
    .shift_time_chunk(e2, as.integer(e1))
  } else {
    rlang::abort(
      "Unsupported operand types for `+` with `time_chunk`.",
      class = "timechunks_arithmetic_error"
    )
  }
}


#' @rdname +.time_chunk
#' @export
#'
#' @examples
#' # Distance between two time_chunks (integer)
#' time_chunk("sp27") - time_chunk("fa26")  # 1L
#' time_chunk("fa27") - time_chunk("fa26")  # 3L
"-.time_chunk" <- function(e1, e2) {
  if (is_time_chunk(e1) && is.numeric(e2)) {
    # time_chunk - integer: shift backward
    .shift_time_chunk(e1, -as.integer(e2))
  } else if (is_time_chunk(e1) && is_time_chunk(e2)) {
    # time_chunk - time_chunk: distance in periods
    .distance_time_chunks(e1, e2)
  } else {
    rlang::abort(
      "Unsupported operand types for `-` with `time_chunk`.",
      class = "timechunks_arithmetic_error"
    )
  }
}


#' Generate a sequence of time_chunks
#'
#' @description
#' Produces a sequence of `time_chunk` periods from `from` to `to`,
#' stepping by `by` periods. The sequence is inclusive of both endpoints.
#'
#' @param from A length-1 `time_chunk`. Start of the sequence.
#' @param to A length-1 `time_chunk`. End of the sequence.
#' @param by Integer. Step size in periods. Default `1L`.
#' @param ... Ignored.
#'
#' @return A `time_chunk` vector.
#' @export
#'
#' @examples
#' use_chunk_preset("us_semester")
#' seq(time_chunk("fa26"), time_chunk("fa27"), by = 1L)
#' # Fall 2026, Spring 2027, Summer 2027, Fall 2027
seq.time_chunk <- function(from, to, by = 1L, ...) {
  if (!is_time_chunk(from) || !is_time_chunk(to)) {
    rlang::abort("`from` and `to` must be `time_chunk` vectors.",
                 class = "timechunks_arithmetic_error")
  }
  if (length(from) != 1L || length(to) != 1L) {
    rlang::abort("`from` and `to` must each have length 1.",
                 class = "timechunks_arithmetic_error")
  }
  by <- as.integer(by)
  if (is.na(by) || by == 0L) {
    rlang::abort("`by` must be a non-zero integer.", class = "timechunks_arithmetic_error")
  }

  cal     <- default_chunk_calendar()
  g_from  <- .global_index(from, cal)
  g_to    <- .global_index(to,   cal)

  if (by > 0L && g_to < g_from) {
    rlang::abort(
      "`to` is before `from` with a positive `by`. Use a negative `by` to step backward.",
      class = "timechunks_arithmetic_error"
    )
  }
  if (by < 0L && g_to > g_from) {
    rlang::abort(
      "`to` is after `from` with a negative `by`. Use a positive `by` to step forward.",
      class = "timechunks_arithmetic_error"
    )
  }

  indices <- seq(g_from, g_to, by = by)
  chunks  <- lapply(indices, function(gi) .global_index_to_time_chunk(gi, cal))
  do.call(vctrs::vec_c, chunks)
}


# Internal helpers --------------------------------------------------------

#' Convert a time_chunk to its global period index
#' @keywords internal
.global_index <- function(x, cal) {
  stopifnot(length(x) == 1L)
  period_index <- vctrs::field(x, "period_index")
  cal_year     <- vctrs::field(x, "year")
  ay_offset    <- .ay_offset(period_index, cal_year, cal)
  ay_offset * length(cal$periods) + (period_index - 1L)
}

#' Extract the academic year offset (the year AY starts) from cal_year + period
#' @keywords internal
.ay_offset <- function(period_index, cal_year, cal) {
  period_names     <- vapply(cal$periods, `[[`, character(1), "name")
  starts_mmdd      <- vapply(cal$periods, `[[`, character(1), "start_mmdd")
  year_start_month <- as.integer(substr(
    starts_mmdd[period_names == cal$year_start_period], 1L, 2L
  ))
  this_month <- as.integer(substr(starts_mmdd[period_index], 1L, 2L))

  if (this_month >= year_start_month) cal_year else cal_year - 1L
}

#' Convert a global period index back to a time_chunk
#' @keywords internal
.global_index_to_time_chunk <- function(global_idx, cal) {
  n           <- length(cal$periods)
  period_idx_0 <- global_idx %% n
  if (period_idx_0 < 0L) period_idx_0 <- period_idx_0 + n
  ay_offset    <- (global_idx - period_idx_0) %/% n
  period_idx   <- period_idx_0 + 1L  # 1-indexed

  period_names     <- vapply(cal$periods, `[[`, character(1), "name")
  starts_mmdd      <- vapply(cal$periods, `[[`, character(1), "start_mmdd")
  year_start_month <- as.integer(substr(
    starts_mmdd[period_names == cal$year_start_period], 1L, 2L
  ))
  this_month <- as.integer(substr(starts_mmdd[period_idx], 1L, 2L))

  cal_year <- if (this_month >= year_start_month) ay_offset else ay_offset + 1L

  .build_time_chunk(period_idx, cal_year, cal)
}

#' Shift a time_chunk vector by n periods
#' @keywords internal
.shift_time_chunk <- function(x, n, cal = default_chunk_calendar()) {
  if (length(x) == 0L) return(new_time_chunk())
  chunks <- lapply(seq_along(x), function(i) {
    xi <- x[i]
    if (is.na(vctrs::field(xi, "name"))) return(.make_na_chunk())
    gi <- .global_index(xi, cal)
    .global_index_to_time_chunk(gi + n, cal)
  })
  do.call(vctrs::vec_c, chunks)
}

#' Compute the signed distance (in periods) between two time_chunks
#' @keywords internal
.distance_time_chunks <- function(x, y, cal = default_chunk_calendar()) {
  if (length(x) != length(y)) {
    rlang::abort(
      "Both `time_chunk` vectors must have the same length for subtraction.",
      class = "timechunks_arithmetic_error"
    )
  }
  vapply(seq_along(x), function(i) {
    xi <- x[i]; yi <- y[i]
    if (is.na(vctrs::field(xi, "name")) || is.na(vctrs::field(yi, "name"))) {
      return(NA_integer_)
    }
    as.integer(.global_index(xi, cal) - .global_index(yi, cal))
  }, integer(1L))
}
