#' Parse strings or numbers into time_chunk vectors
#'
#' @description
#' The main entry point for creating `time_chunk` vectors. Dispatches
#' automatically based on the format of the input:
#'
#' - **Code format**: `"fa26"`, `"sp27"` (`{code}{2-digit-year}`)
#' - **Text format**: `"Fall 2026"`, `"2026 Fall"` (`{name} {4-digit-year}`)
#' - **YYYYM numeric**: `20268` (5-digit) or `202611` (6-digit)
#' - **Composite key**: `"2026-27_1_08_Fall"` (from `format(x, style = "key")`)
#'
#' @param x Character or numeric vector to parse.
#' @param calendar A calendar config list. Defaults to [default_chunk_calendar()].
#'
#' @return A `time_chunk` vector of the same length as `x`.
#' @export
#'
#' @examples
#' use_chunk_preset("us_semester")
#'
#' time_chunk("fa26")
#' time_chunk("Fall 2026")
#' time_chunk(20268)
#' time_chunk("2026-27_1_08_Fall")
#' time_chunk(c("fa26", "sp27", "su27"))
time_chunk <- function(x, calendar = default_chunk_calendar()) {
  if (length(x) == 0) {
    return(new_time_chunk())
  }

  if (is.numeric(x) || is.integer(x)) {
    return(parse_chunk_numeric(x, calendar))
  }

  if (!is.character(x)) {
    rlang::abort(
      glue::glue(
        "`x` must be character or numeric, not {class(x)[1]}."
      ),
      class = "timechunks_parse_error"
    )
  }

  # Dispatch per element; collect results and concatenate
  results <- lapply(x, function(val) .parse_single(val, calendar))
  do.call(vctrs::vec_c, results)
}


# Dispatch for a single character string ----------------------------------

.parse_single <- function(x, calendar) {
  if (is.na(x)) {
    return(.make_na_chunk())
  }

  x_trimmed <- trimws(x)

  # Composite key: "2026-27_1_08_Fall"
  if (grepl("^\\d{4}-\\d{2}_\\d+_\\d{2}_", x_trimmed)) {
    return(.parse_composite_key(x_trimmed, calendar))
  }

  # YYYYM numeric passed as string (e.g. "20268") — treat as numeric
  if (grepl("^\\d{5,6}$", x_trimmed)) {
    return(parse_chunk_numeric(as.integer(x_trimmed), calendar))
  }

  # Text format: "Fall 2026" or "2026 Fall"
  if (grepl("\\d{4}", x_trimmed)) {
    return(parse_chunk_text(x_trimmed, calendar))
  }

  # Code format: "fa26"
  parse_chunk_code(x_trimmed, calendar)
}


#' Parse code-format period strings
#'
#' @description
#' Parses strings of the form `{code}{2-digit-year}`, e.g. `"fa26"`.
#'
#' - Codes are matched case-insensitively.
#' - Two-digit years: 00–49 → 2000–2049; 50–99 → 1950–1999.
#'
#' @param x Character vector of code-format strings.
#' @param calendar A calendar config list. Defaults to [default_chunk_calendar()].
#'
#' @return A `time_chunk` vector.
#' @export
#'
#' @examples
#' use_chunk_preset("us_semester")
#' parse_chunk_code("fa26")
#' parse_chunk_code(c("fa26", "sp27"))
parse_chunk_code <- function(x, calendar = default_chunk_calendar()) {
  results <- lapply(x, function(val) {
    if (is.na(val)) return(.make_na_chunk())

    val <- trimws(val)
    codes <- tolower(vapply(calendar$periods, `[[`, character(1), "code"))
    pattern <- paste0("(?i)^(", paste(codes, collapse = "|"), ")(\\d{2})$")
    m <- regmatches(val, regexpr(pattern, val, perl = TRUE))

    if (length(m) == 0 || nchar(m) == 0) {
      available <- paste(codes, collapse = ", ")
      rlang::abort(
        glue::glue(
          "Could not parse '{val}' as a period code. ",
          "Available codes: {available}"
        ),
        class = "timechunks_unknown_code"
      )
    }

    # Split code from 2-digit year
    code_lengths <- nchar(codes)
    matched_code <- NULL
    matched_idx  <- NULL
    for (i in seq_along(codes)) {
      prefix <- substr(tolower(val), 1, code_lengths[i])
      if (prefix == codes[i] && nchar(val) == code_lengths[i] + 2L) {
        matched_code <- codes[i]
        matched_idx  <- i
        break
      }
    }

    if (is.null(matched_code)) {
      available <- paste(codes, collapse = ", ")
      rlang::abort(
        glue::glue(
          "Could not parse '{val}' as a period code. ",
          "Available codes: {available}"
        ),
        class = "timechunks_unknown_code"
      )
    }

    yy <- as.integer(substr(val, nchar(matched_code) + 1L, nchar(val)))
    year <- .two_digit_year(yy)

    .build_time_chunk(
      period_idx = matched_idx,
      cal_year   = year,
      calendar   = calendar
    )
  })

  do.call(vctrs::vec_c, results)
}


#' Parse text-format period strings
#'
#' @description
#' Parses strings of the form `"Fall 2026"` or `"2026 Fall"`.
#' Period names are matched case-insensitively.
#'
#' @param x Character vector of text-format strings.
#' @param calendar A calendar config list. Defaults to [default_chunk_calendar()].
#'
#' @return A `time_chunk` vector.
#' @export
#'
#' @examples
#' use_chunk_preset("us_semester")
#' parse_chunk_text("Fall 2026")
#' parse_chunk_text("2026 Fall")
parse_chunk_text <- function(x, calendar = default_chunk_calendar()) {
  results <- lapply(x, function(val) {
    if (is.na(val)) return(.make_na_chunk())

    val <- trimws(val)
    names_lc <- tolower(vapply(calendar$periods, `[[`, character(1), "name"))

    # Try "{name} {year}"
    m <- regmatches(
      val,
      regexpr(
        paste0("(?i)^(", paste(names_lc, collapse = "|"), ")\\s+(\\d{4})$"),
        val, perl = TRUE
      )
    )

    year_str  <- NULL
    name_str  <- NULL

    if (length(m) > 0 && nchar(m) > 0) {
      parts    <- strsplit(trimws(m), "\\s+")[[1]]
      name_str <- parts[1]
      year_str <- parts[length(parts)]
    } else {
      # Try "{year} {name}"
      m2 <- regmatches(
        val,
        regexpr(
          paste0("(?i)^(\\d{4})\\s+(", paste(names_lc, collapse = "|"), ")$"),
          val, perl = TRUE
        )
      )
      if (length(m2) > 0 && nchar(m2) > 0) {
        parts    <- strsplit(trimws(m2), "\\s+")[[1]]
        year_str <- parts[1]
        name_str <- parts[length(parts)]
      }
    }

    if (is.null(name_str)) {
      available <- paste(vapply(calendar$periods, `[[`, character(1), "name"),
                         collapse = ", ")
      rlang::abort(
        glue::glue(
          "Could not parse '{val}' as a text-format period. ",
          "Expected '{'{'}Name Year{'}'}'  or '{'{'}Year Name{'}'}'. ",
          "Available names: {available}"
        ),
        class = "timechunks_parse_error"
      )
    }

    period_idx <- which(names_lc == tolower(name_str))
    year       <- as.integer(year_str)

    .build_time_chunk(
      period_idx = period_idx,
      cal_year   = year,
      calendar   = calendar
    )
  })

  do.call(vctrs::vec_c, results)
}


#' Parse YYYYM numeric period values
#'
#' @description
#' Parses 5- or 6-digit integers encoding year and month:
#' - 5 digits: months 1–9 (e.g. `20268` = August 2026)
#' - 6 digits: months 10–12 (e.g. `202611` = November 2026)
#'
#' The month is mapped to a period using the calendar's month mapping.
#' Set `yyyym_strict = TRUE` in [set_chunk_calendar()] to error on
#' ambiguous mappings.
#'
#' @param x Integer or numeric vector of YYYYM values.
#' @param calendar A calendar config list. Defaults to [default_chunk_calendar()].
#'
#' @return A `time_chunk` vector.
#' @export
#'
#' @examples
#' use_chunk_preset("us_semester")
#' parse_chunk_numeric(20268)   # August 2026 -> Fall 2026
#' parse_chunk_numeric(202701)  # January 2027 -> Spring 2027
parse_chunk_numeric <- function(x, calendar = default_chunk_calendar()) {
  x <- as.integer(x)

  results <- lapply(x, function(val) {
    if (is.na(val)) return(.make_na_chunk())

    n_digits <- nchar(as.character(abs(val)))
    if (!n_digits %in% c(5L, 6L)) {
      rlang::abort(
        glue::glue(
          "YYYYM value {val} has {n_digits} digit(s); expected 5 (months 1-9) or 6 (months 10-12)."
        ),
        class = "timechunks_parse_error"
      )
    }

    year  <- as.integer(substr(as.character(val), 1L, 4L))
    month <- as.integer(substr(as.character(val), 5L, n_digits))

    if (month < 1L || month > 12L) {
      rlang::abort(
        glue::glue("Invalid month {month} in YYYYM value {val}."),
        class = "timechunks_parse_error"
      )
    }

    mm_str <- sprintf("%02d", month)
    period_idx <- .resolve_month_to_period(mm_str, year, calendar)

    .build_time_chunk(
      period_idx = period_idx,
      cal_year   = year,
      calendar   = calendar
    )
  })

  do.call(vctrs::vec_c, results)
}


# Internal helpers --------------------------------------------------------

#' Resolve a two-digit month string to a period index
#'
#' YYYYM month resolution compares month numbers, not exact dates. This means
#' August maps to Fall even though Fall starts Aug-23 (not Aug-01). This
#' matches institutional practice where month codes denote the term.
#'
#' Resolution order:
#' 1. Explicit yyyym_map override
#' 2. Find all periods whose start month (MM) <= given month; pick highest
#' 3. If none qualify (given month is before the earliest start month in the
#'    year), pick the last period (wraps to the period that crosses into this
#'    month from the previous year)
#'
#' @keywords internal
.resolve_month_to_period <- function(mm_str, year, calendar) {
  period_names <- vapply(calendar$periods, `[[`, character(1), "name")

  # Explicit yyyym_map takes priority
  if (!is.null(calendar$yyyym_map) && mm_str %in% names(calendar$yyyym_map)) {
    target_name <- calendar$yyyym_map[[mm_str]]
    idx <- which(period_names == target_name)
    if (length(idx) == 0) {
      rlang::abort(
        glue::glue(
          "yyyym_map maps month '{mm_str}' to unknown period '{target_name}'."
        ),
        class = "timechunks_parse_error"
      )
    }
    return(idx)
  }

  month_int   <- as.integer(mm_str)
  starts_mmdd <- vapply(calendar$periods, `[[`, character(1), "start_mmdd")
  start_months <- as.integer(substr(starts_mmdd, 1L, 2L))

  # Candidates: periods whose start month <= given month
  candidates <- which(start_months <= month_int)

  if (length(candidates) == 0L) {
    # All periods start after this month — this month belongs to the last
    # period of the previous year (e.g. September before an October-start FY).
    candidates <- seq_along(calendar$periods)
  }

  if (length(candidates) > 1L && isTRUE(calendar$yyyym_strict)) {
    period_names_cands <- paste(period_names[candidates], collapse = ", ")
    rlang::abort(
      glue::glue(
        "Month '{mm_str}' maps ambiguously to periods: {period_names_cands}. ",
        "Set yyyym_strict = FALSE or provide an explicit yyyym_map."
      ),
      class = "timechunks_ambiguous_month"
    )
  }

  # Non-strict: pick the period with the highest (most recent) start month
  candidates[which.max(start_months[candidates])]
}


#' Build a time_chunk from a period index and calendar year
#' @keywords internal
.build_time_chunk <- function(period_idx, cal_year, calendar) {
  period    <- calendar$periods[[period_idx]]
  start_mmdd <- period$start_mmdd

  start_date <- as.Date(paste0(cal_year, "-", start_mmdd))

  # Compute end date
  n <- length(calendar$periods)
  if (!is.null(period$end_mmdd)) {
    end_candidate <- as.Date(paste0(cal_year, "-", period$end_mmdd))
    if (end_candidate < start_date) {
      end_candidate <- as.Date(paste0(cal_year + 1L, "-", period$end_mmdd))
    }
    end_date <- end_candidate
  } else if (period_idx < n) {
    next_period    <- calendar$periods[[period_idx + 1L]]
    next_start_mmdd <- next_period$start_mmdd
    next_year <- cal_year
    next_start <- as.Date(paste0(next_year, "-", next_start_mmdd))
    # If the next period starts before this one, it must be in the next year
    if (next_start <= start_date) {
      next_start <- as.Date(paste0(next_year + 1L, "-", next_start_mmdd))
    }
    end_date <- next_start - 1L
  } else {
    end_date <- as.Date(paste0(cal_year, "-12-31"))
  }

  ay <- .compute_ay(calendar, period$name, cal_year)

  new_time_chunk(
    start_date   = start_date,
    end_date     = end_date,
    name         = period$name,
    code         = period$code,
    year         = cal_year,
    period_index = period_idx,
    ay           = ay
  )
}


#' Parse a composite key string "2026-27_1_08_Fall"
#' @keywords internal
.parse_composite_key <- function(x, calendar) {
  parts <- strsplit(x, "_")[[1]]
  if (length(parts) < 4L) {
    rlang::abort(
      glue::glue(
        "Could not parse '{x}' as a composite key. ",
        "Expected format: 'YYYY-YY_index_MM_Name' (e.g. '2026-27_1_08_Fall')."
      ),
      class = "timechunks_parse_error"
    )
  }

  # ay = parts[1], index = parts[2], mm = parts[3], name = parts[4..n]
  name_str <- paste(parts[4:length(parts)], collapse = "_")
  mm_str   <- parts[3]
  year_str <- substr(parts[1], 1L, 4L)
  cal_year <- as.integer(year_str)

  period_names <- vapply(calendar$periods, `[[`, character(1), "name")
  period_idx   <- which(period_names == name_str)

  if (length(period_idx) == 0L) {
    available <- paste(period_names, collapse = ", ")
    rlang::abort(
      glue::glue(
        "Composite key contains unknown period name '{name_str}'. ",
        "Available names: {available}"
      ),
      class = "timechunks_parse_error"
    )
  }

  # Validate mm matches the period's start month
  period    <- calendar$periods[[period_idx]]
  expected_mm <- substr(period$start_mmdd, 1L, 2L)
  if (mm_str != expected_mm) {
    # mm encodes the start month; if mismatched, warn but proceed
    rlang::warn(
      glue::glue(
        "Composite key month '{mm_str}' does not match period '{name_str}' ",
        "start month '{expected_mm}'. Using the period's configured start."
      )
    )
  }

  .build_time_chunk(
    period_idx = period_idx,
    cal_year   = cal_year,
    calendar   = calendar
  )
}


#' Convert a 2-digit year to a 4-digit year
#'
#' Follows standard R convention: 00-49 -> 2000-2049, 50-99 -> 1950-1999.
#' @keywords internal
.two_digit_year <- function(yy) {
  stopifnot(is.integer(yy) || is.numeric(yy))
  yy <- as.integer(yy)
  ifelse(yy <= 49L, 2000L + yy, 1900L + yy)
}


#' Return a length-1 NA time_chunk
#' @keywords internal
.make_na_chunk <- function() {
  new_time_chunk(
    start_date   = as.Date(NA),
    end_date     = as.Date(NA),
    name         = NA_character_,
    code         = NA_character_,
    year         = NA_integer_,
    period_index = NA_integer_,
    ay           = NA_character_
  )
}
