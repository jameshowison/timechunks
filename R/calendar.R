#' Set the active calendar configuration
#'
#' @description
#' Configures the global calendar used by [time_chunk()] and related functions.
#' The configuration is stored in `options(timechunks.calendar = ...)` and
#' persists for the duration of the R session.
#'
#' @param periods A list of period definitions. Each element must be a named
#'   list with fields `name` (character), `code` (character), and
#'   `start_mmdd` (character, format `"MM-DD"`). Optionally includes
#'   `end_mmdd` to override the computed end date.
#' @param year_start_period Character. The `name` of the period that begins
#'   the academic or fiscal year (e.g. `"Fall"`).
#' @param yyyym_strict Logical. If `TRUE`, [time_chunk()] errors on YYYYM
#'   inputs where the month maps ambiguously to multiple periods. Default `FALSE`.
#' @param yyyym_map Optional named list mapping two-digit month strings to
#'   period names, e.g. `list("08" = "Fall", "01" = "Spring")`. Overrides
#'   automatic month-to-period resolution.
#' @param name Optional character string naming this calendar (used in printing).
#'
#' @return Invisibly returns the calendar configuration list.
#' @export
#'
#' @examples
#' set_chunk_calendar(
#'   periods = list(
#'     list(name = "Fall",   code = "fa", start_mmdd = "08-23"),
#'     list(name = "Spring", code = "sp", start_mmdd = "01-15"),
#'     list(name = "Summer", code = "su", start_mmdd = "06-01")
#'   ),
#'   year_start_period = "Fall"
#' )
set_chunk_calendar <- function(periods,
                                year_start_period,
                                yyyym_strict = FALSE,
                                yyyym_map = NULL,
                                name = NULL) {
  # Validate periods
  if (!is.list(periods) || length(periods) == 0) {
    rlang::abort(
      "`periods` must be a non-empty list of period definitions.",
      class = "timechunks_invalid_calendar"
    )
  }

  for (i in seq_along(periods)) {
    p <- periods[[i]]
    required <- c("name", "code", "start_mmdd")
    missing_fields <- setdiff(required, names(p))
    if (length(missing_fields) > 0) {
      rlang::abort(
        glue::glue(
          "Period {i} is missing required fields: {paste(missing_fields, collapse = ', ')}"
        ),
        class = "timechunks_invalid_calendar"
      )
    }
    if (!grepl("^\\d{2}-\\d{2}$", p$start_mmdd)) {
      rlang::abort(
        glue::glue(
          "Period '{p$name}' has invalid start_mmdd '{p$start_mmdd}'. ",
          "Expected format: 'MM-DD' (e.g. '08-23')."
        ),
        class = "timechunks_invalid_calendar"
      )
    }
  }

  # Validate year_start_period
  period_names <- vapply(periods, `[[`, character(1), "name")
  if (!year_start_period %in% period_names) {
    rlang::abort(
      glue::glue(
        "`year_start_period` '{year_start_period}' not found in periods. ",
        "Available names: {paste(period_names, collapse = ', ')}"
      ),
      class = "timechunks_invalid_calendar"
    )
  }

  # Validate yyyym_map if provided
  if (!is.null(yyyym_map)) {
    valid_months <- sprintf("%02d", 1:12)
    bad_keys <- setdiff(names(yyyym_map), valid_months)
    if (length(bad_keys) > 0) {
      rlang::abort(
        glue::glue(
          "Invalid month keys in `yyyym_map`: {paste(bad_keys, collapse = ', ')}. ",
          "Keys must be two-digit month strings '01' through '12'."
        ),
        class = "timechunks_invalid_calendar"
      )
    }
    bad_values <- setdiff(unlist(yyyym_map), period_names)
    if (length(bad_values) > 0) {
      rlang::abort(
        glue::glue(
          "Invalid period names in `yyyym_map`: {paste(bad_values, collapse = ', ')}. ",
          "Available names: {paste(period_names, collapse = ', ')}"
        ),
        class = "timechunks_invalid_calendar"
      )
    }
  }

  cal <- list(
    periods           = periods,
    year_start_period = year_start_period,
    yyyym_strict      = yyyym_strict,
    yyyym_map         = yyyym_map,
    name              = name %||% "custom",
    single_year_ay    = FALSE
  )

  options(timechunks.calendar = cal)
  invisible(cal)
}


#' Activate a built-in calendar preset
#'
#' @description
#' Sets the global calendar to one of the built-in presets. Equivalent to
#' calling [set_chunk_calendar()] with predefined period definitions.
#'
#' @param preset Character. One of `"us_semester"`, `"us_quarter"`,
#'   `"uk_terms"`, `"trimester"`, `"us_federal_fy"`, `"australia_semester"`.
#'
#' @return Invisibly returns the calendar configuration list.
#' @export
#'
#' @examples
#' use_chunk_preset("us_semester")
use_chunk_preset <- function(preset) {
  if (!preset %in% names(.chunk_presets)) {
    rlang::abort(
      glue::glue(
        "Unknown preset '{preset}'. ",
        "Available presets: {paste(names(.chunk_presets), collapse = ', ')}"
      ),
      class = "timechunks_unknown_preset"
    )
  }
  cal <- .chunk_presets[[preset]]
  options(timechunks.calendar = cal)
  invisible(cal)
}


#' Get the active calendar configuration
#'
#' @description
#' Returns the calendar currently set via [set_chunk_calendar()] or
#' [use_chunk_preset()]. Errors if no calendar has been configured.
#'
#' @return A calendar configuration list.
#' @export
#'
#' @examples
#' use_chunk_preset("us_semester")
#' default_chunk_calendar()
default_chunk_calendar <- function() {
  cal <- getOption("timechunks.calendar")
  if (is.null(cal)) {
    rlang::abort(
      paste0(
        "No calendar configured. ",
        "Call `use_chunk_preset()` or `set_chunk_calendar()` first.\n",
        "Example: use_chunk_preset(\"us_semester\")"
      ),
      class = "timechunks_no_calendar"
    )
  }
  cal
}


# Internal helper ---------------------------------------------------------

#' Resolve end dates for all periods in a calendar
#'
#' Given a calendar config and a year, compute the start and end Date for
#' each period. Returns a data frame with columns: name, code, start_date,
#' end_date, period_index.
#'
#' @param cal A calendar config list from [default_chunk_calendar()].
#' @param year Integer. The calendar year for the period starts.
#' @keywords internal
.resolve_period_dates <- function(cal, year) {
  periods <- cal$periods
  n <- length(periods)

  # Build start dates
  starts <- vector("list", n)
  for (i in seq_len(n)) {
    mmdd <- periods[[i]]$start_mmdd
    starts[[i]] <- as.Date(paste0(year, "-", mmdd))
  }

  # Build end dates: day before next period's start (wrapping to year+1)
  ends <- vector("list", n)
  for (i in seq_len(n)) {
    if (!is.null(periods[[i]]$end_mmdd)) {
      # Explicit override: find the year for this end date
      end_mmdd <- periods[[i]]$end_mmdd
      # End date is in same year unless it wraps
      end_candidate <- as.Date(paste0(year, "-", end_mmdd))
      if (end_candidate < starts[[i]]) {
        end_candidate <- as.Date(paste0(year + 1L, "-", end_mmdd))
      }
      ends[[i]] <- end_candidate
    } else if (i < n) {
      # Day before next period start in the same year
      next_start <- starts[[i + 1L]]
      ends[[i]] <- next_start - 1L
    } else {
      # Last period: day before end of year
      ends[[i]] <- as.Date(paste0(year, "-12-31"))
    }
  }

  data.frame(
    name         = vapply(periods, `[[`, character(1), "name"),
    code         = vapply(periods, `[[`, character(1), "code"),
    start_date   = as.Date(unlist(starts), origin = "1970-01-01"),
    end_date     = as.Date(unlist(ends),   origin = "1970-01-01"),
    period_index = seq_len(n),
    stringsAsFactors = FALSE
  )
}


#' Compute the academic/fiscal year string for a given period and calendar year
#'
#' A period belongs to the academic year that started in `cal_year` if its
#' start month is >= the year-start period's start month (i.e. it falls in
#' the same part of the calendar). Otherwise it belongs to the academic year
#' that started in `cal_year - 1` (it crosses the calendar year boundary).
#'
#' Example (us_semester, year_start = Fall, start month = 08):
#'   - Fall 2026 (Aug): 08 >= 08 → ay_start = 2026 → "2026-27"
#'   - Spring 2027 (Jan): 01 < 08 → ay_start = 2026 → "2026-27"
#'   - Summer 2027 (Jun): 06 < 08 → ay_start = 2026 → "2026-27"
#'
#' @param cal Calendar config.
#' @param period_name Character. Name of the period.
#' @param cal_year Integer. Calendar year of the period's start date.
#' @keywords internal
.compute_ay <- function(cal, period_name, cal_year) {
  if (isTRUE(cal$single_year_ay)) {
    return(as.character(cal_year))
  }

  period_names  <- vapply(cal$periods, `[[`, character(1), "name")
  starts_mmdd   <- vapply(cal$periods, `[[`, character(1), "start_mmdd")

  year_start_month <- as.integer(substr(
    starts_mmdd[period_names == cal$year_start_period], 1L, 2L
  ))
  this_month <- as.integer(substr(
    starts_mmdd[period_names == period_name], 1L, 2L
  ))

  ay_start <- if (this_month >= year_start_month) cal_year else cal_year - 1L
  ay_end   <- ay_start + 1L
  paste0(ay_start, "-", substr(as.character(ay_end), 3L, 4L))
}


# Null-coalescing operator (rlang exports %||% but we define it for clarity)
`%||%` <- function(x, y) if (is.null(x)) y else x
