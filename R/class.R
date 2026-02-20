#' Internal constructor for time_chunk vectors
#'
#' @description
#' Low-level constructor. Use [time_chunk()] for the public API.
#' All arguments must be pre-validated atomic vectors of equal length.
#'
#' @param start_date Date vector. Period start dates.
#' @param end_date Date vector. Period end dates.
#' @param name Character vector. Period names (e.g. `"Fall"`).
#' @param code Character vector. Period codes (e.g. `"fa"`).
#' @param year Integer vector. Calendar year of the period start.
#' @param period_index Integer vector. Position of the period within the year.
#' @param ay Character vector. Academic/fiscal year string (e.g. `"2026-27"`).
#'
#' @return A `time_chunk` vctrs record vector.
#' @keywords internal
new_time_chunk <- function(start_date   = as.Date(character()),
                            end_date     = as.Date(character()),
                            name         = character(),
                            code         = character(),
                            year         = integer(),
                            period_index = integer(),
                            ay           = character()) {
  vctrs::new_rcrd(
    fields = list(
      start_date   = start_date,
      end_date     = end_date,
      name         = name,
      code         = code,
      year         = year,
      period_index = period_index,
      ay           = ay
    ),
    class = "time_chunk"
  )
}


#' Validate a time_chunk object
#'
#' @param x A `time_chunk` object.
#' @return `x` invisibly, or errors with a descriptive message.
#' @keywords internal
validate_time_chunk <- function(x) {
  start <- vctrs::field(x, "start_date")
  end   <- vctrs::field(x, "end_date")
  name  <- vctrs::field(x, "name")
  code  <- vctrs::field(x, "code")
  year  <- vctrs::field(x, "year")
  idx   <- vctrs::field(x, "period_index")
  ay    <- vctrs::field(x, "ay")

  if (!inherits(start, "Date")) {
    rlang::abort("Field `start_date` must be a Date vector.",
                 class = "timechunks_invalid_object")
  }
  if (!inherits(end, "Date")) {
    rlang::abort("Field `end_date` must be a Date vector.",
                 class = "timechunks_invalid_object")
  }
  if (!is.character(name)) {
    rlang::abort("Field `name` must be a character vector.",
                 class = "timechunks_invalid_object")
  }
  if (!is.character(code)) {
    rlang::abort("Field `code` must be a character vector.",
                 class = "timechunks_invalid_object")
  }
  if (!is.integer(year)) {
    rlang::abort("Field `year` must be an integer vector.",
                 class = "timechunks_invalid_object")
  }
  if (!is.integer(idx)) {
    rlang::abort("Field `period_index` must be an integer vector.",
                 class = "timechunks_invalid_object")
  }
  if (!is.character(ay)) {
    rlang::abort("Field `ay` must be a character vector.",
                 class = "timechunks_invalid_object")
  }

  bad_order <- which(!is.na(start) & !is.na(end) & end < start)
  if (length(bad_order) > 0) {
    rlang::abort(
      glue::glue(
        "end_date is before start_date at position(s): ",
        "{paste(bad_order, collapse = ', ')}"
      ),
      class = "timechunks_invalid_object"
    )
  }

  invisible(x)
}


#' Test if an object is a time_chunk
#'
#' @param x An object to test.
#' @return `TRUE` if `x` is a `time_chunk`, `FALSE` otherwise.
#' @export
#'
#' @examples
#' use_chunk_preset("us_semester")
#' is_time_chunk(time_chunk("fa26"))  # TRUE
#' is_time_chunk("fa26")              # FALSE
is_time_chunk <- function(x) {
  inherits(x, "time_chunk")
}
