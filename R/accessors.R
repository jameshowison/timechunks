#' Accessor functions for time_chunk fields
#'
#' @description
#' Extract individual fields from a `time_chunk` vector. All functions return
#' an atomic vector of the same length as the input.
#'
#' @param x A `time_chunk` vector.
#'
#' @name time_chunk_accessors
NULL


#' @rdname time_chunk_accessors
#' @return `chunk_name()`: character vector of period names (e.g. `"Fall"`).
#' @export
#'
#' @examples
#' use_chunk_preset("us_semester")
#' x <- time_chunk(c("fa26", "sp27"))
#' chunk_name(x)   # "Fall"   "Spring"
chunk_name <- function(x) {
  .check_time_chunk(x, "chunk_name")
  vctrs::field(x, "name")
}


#' @rdname time_chunk_accessors
#' @return `chunk_code()`: character vector of period codes (e.g. `"fa"`).
#' @export
#'
#' @examples
#' chunk_code(x)   # "fa" "sp"
chunk_code <- function(x) {
  .check_time_chunk(x, "chunk_code")
  vctrs::field(x, "code")
}


#' @rdname time_chunk_accessors
#' @return `chunk_year()`: integer vector of calendar years (e.g. `2026L`).
#' @export
#'
#' @examples
#' chunk_year(x)   # 2026 2027
chunk_year <- function(x) {
  .check_time_chunk(x, "chunk_year")
  vctrs::field(x, "year")
}


#' @rdname time_chunk_accessors
#' @return `chunk_ay()`: character vector of academic/fiscal year strings
#'   (e.g. `"2026-27"`).
#' @export
#'
#' @examples
#' chunk_ay(x)     # "2026-27" "2026-27"
chunk_ay <- function(x) {
  .check_time_chunk(x, "chunk_ay")
  vctrs::field(x, "ay")
}


#' @rdname time_chunk_accessors
#' @return `chunk_index()`: integer vector of period positions within the year.
#' @export
#'
#' @examples
#' chunk_index(x)  # 1 2
chunk_index <- function(x) {
  .check_time_chunk(x, "chunk_index")
  vctrs::field(x, "period_index")
}


#' @rdname time_chunk_accessors
#' @return `start_date()`: Date vector of period start dates.
#' @export
#'
#' @examples
#' start_date(x)   # "2026-08-23" "2027-01-15"
start_date <- function(x) {
  .check_time_chunk(x, "start_date")
  vctrs::field(x, "start_date")
}


#' @rdname time_chunk_accessors
#' @return `end_date()`: Date vector of period end dates.
#' @export
#'
#' @examples
#' end_date(x)     # "2027-01-14" "2027-05-31"
end_date <- function(x) {
  .check_time_chunk(x, "end_date")
  vctrs::field(x, "end_date")
}


#' @rdname time_chunk_accessors
#' @return `mid_date()`: Date vector of midpoints between start and end dates.
#' @export
#'
#' @examples
#' mid_date(x)
mid_date <- function(x) {
  .check_time_chunk(x, "mid_date")
  s <- vctrs::field(x, "start_date")
  e <- vctrs::field(x, "end_date")
  as.Date(
    (as.integer(s) + as.integer(e)) %/% 2L,
    origin = "1970-01-01"
  )
}


# Internal ----------------------------------------------------------------

#' Validate that x is a time_chunk
#' @keywords internal
.check_time_chunk <- function(x, fn_name) {
  if (!is_time_chunk(x)) {
    rlang::abort(
      glue::glue("`{fn_name}()` requires a `time_chunk` vector, not {class(x)[1]}."),
      class = "timechunks_type_error"
    )
  }
  invisible(x)
}
