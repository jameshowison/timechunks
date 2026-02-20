#' Format time_chunk vectors as strings
#'
#' @description
#' Formats a `time_chunk` vector using one of the built-in styles or a
#' glue-style template string.
#'
#' **Named styles:**
#' - `"code"` — `"fa26"`
#' - `"name"` — `"Fall 2026"`
#' - `"ay"` — `"2026-27"`
#' - `"key"` — `"2026-27_1_08_Fall"` (sortable composite, round-trips via parsing)
#' - `"iso_date"` — `"2026-08-23"` (start date)
#'
#' **Glue templates** (any string containing `{`):
#' - Variables available: `name`, `code`, `year`, `ay`, `chunk_index`,
#'   `start_date`, `end_date`, `mid_date`.
#' - Example: `"{ay}_{chunk_index}_{name}"` → `"2026-27_1_Fall"`
#'
#' @param x A `time_chunk` vector.
#' @param style Character scalar. A named style or a glue template string.
#'   Default `"name"`.
#' @param ... Ignored (required by S3 generic).
#'
#' @return A character vector of the same length as `x`.
#' @export
#'
#' @examples
#' use_chunk_preset("us_semester")
#' x <- time_chunk("fa26")
#'
#' format(x, style = "code")      # "fa26"
#' format(x, style = "name")      # "Fall 2026"
#' format(x, style = "ay")        # "2026-27"
#' format(x, style = "key")       # "2026-27_1_08_Fall"
#' format(x, style = "iso_date")  # "2026-08-23"
#' format(x, style = "{ay}_{chunk_index}_{name}")  # "2026-27_1_Fall"
format.time_chunk <- function(x, style = "name", ...) {
  n <- length(x)
  if (n == 0L) return(character(0L))

  name         <- vctrs::field(x, "name")
  code         <- vctrs::field(x, "code")
  year         <- vctrs::field(x, "year")
  ay           <- vctrs::field(x, "ay")
  chunk_index  <- vctrs::field(x, "period_index")
  start_date   <- vctrs::field(x, "start_date")
  end_date     <- vctrs::field(x, "end_date")
  mid_date     <- as.Date(
    (as.integer(start_date) + as.integer(end_date)) %/% 2L,
    origin = "1970-01-01"
  )

  # Detect glue template
  if (grepl("{", style, fixed = TRUE)) {
    env <- list(
      name        = name,
      code        = code,
      year        = year,
      ay          = ay,
      chunk_index = chunk_index,
      start_date  = start_date,
      end_date    = end_date,
      mid_date    = mid_date
    )
    return(glue::glue_data(env, style, .na = NA_character_))
  }

  # Named styles
  start_mm <- sprintf("%02d", as.integer(format(start_date, "%m")))

  switch(
    style,
    code     = paste0(code, substr(as.character(year), 3L, 4L)),
    name     = paste(name, year),
    ay       = ay,
    key      = paste0(ay, "_", chunk_index, "_", start_mm, "_", name),
    iso_date = format(start_date, "%Y-%m-%d"),
    rlang::abort(
      glue::glue(
        "Unknown style '{style}'. ",
        "Valid styles: code, name, ay, key, iso_date. ",
        "Or use a glue template containing '{{'."
      ),
      class = "timechunks_unknown_style"
    )
  )
}


#' Print method for time_chunk vectors
#'
#' @param x A `time_chunk` vector.
#' @param ... Ignored.
#' @export
print.time_chunk <- function(x, ...) {
  n <- length(x)
  cal <- tryCatch(default_chunk_calendar(), error = function(e) NULL)
  cal_name <- if (!is.null(cal)) cal$name else "unknown"

  cat(glue::glue("<time_chunk[{n}]>"), "\n")

  if (n == 0L) {
    cat("[1] (empty)\n")
  } else {
    labels <- format(x, style = "name")
    # Use default print formatting for the values
    print(labels, quote = FALSE)
  }

  cat("Calendar:", cal_name, "\n")
  invisible(x)
}
