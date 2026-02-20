# vctrs methods for time_chunk
# These are required for correct tidyverse integration.
# Use @exportS3Method so roxygen2 generates S3method() entries in NAMESPACE,
# which is required for vctrs double-dispatch to resolve correctly.

#' @importFrom vctrs vec_proxy_compare vec_ptype_abbr vec_ptype_full
#' @importFrom vctrs vec_cast vec_ptype2
NULL


# Proxy for comparison/sorting --------------------------------------------

#' @exportS3Method vctrs::vec_proxy_compare
vec_proxy_compare.time_chunk <- function(x, ...) {
  as.integer(vctrs::field(x, "start_date"))
}


# Type abbreviation -------------------------------------------------------

#' @exportS3Method vctrs::vec_ptype_abbr
vec_ptype_abbr.time_chunk <- function(x, ...) {
  "tchk"
}

#' @exportS3Method vctrs::vec_ptype_full
vec_ptype_full.time_chunk <- function(x, ...) {
  "time_chunk"
}


# Prototype (empty vector) ------------------------------------------------

#' @exportS3Method vctrs::vec_ptype2
vec_ptype2.time_chunk.time_chunk <- function(x, y, ...) {
  new_time_chunk()
}

#' @exportS3Method vctrs::vec_ptype2
vec_ptype2.time_chunk.character <- function(x, y, ...) {
  character()
}

#' @exportS3Method vctrs::vec_ptype2
vec_ptype2.character.time_chunk <- function(x, y, ...) {
  character()
}


# Casting -----------------------------------------------------------------

#' @exportS3Method vctrs::vec_cast
vec_cast.time_chunk.time_chunk <- function(x, to, ...) {
  x
}

#' @exportS3Method vctrs::vec_cast
vec_cast.character.time_chunk <- function(x, to, ...) {
  # Cast time_chunk -> character via "code" format
  format(x, style = "code")
}

#' @exportS3Method vctrs::vec_cast
vec_cast.time_chunk.character <- function(x, to, ...) {
  # Cast character -> time_chunk by parsing
  time_chunk(x)
}

#' @exportS3Method vctrs::vec_cast
vec_cast.Date.time_chunk <- function(x, to, ...) {
  # Cast time_chunk -> Date returns the start date
  vctrs::field(x, "start_date")
}
