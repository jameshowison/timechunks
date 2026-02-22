#' Built-in calendar presets
#'
#' @description
#' A list of named calendar configurations available via [use_chunk_preset()].
#' Each preset defines periods, their start dates, and the period that begins
#' the academic/fiscal year.
#'
#' @keywords internal
.chunk_presets <- list(

  us_semester = list(
    periods = list(
      list(name = "Fall",   code = "fa", start_mmdd = "08-23"),
      list(name = "Spring", code = "sp", start_mmdd = "01-15"),
      list(name = "Summer", code = "su", start_mmdd = "06-01")
    ),
    year_start_period = "Fall",
    yyyym_strict = FALSE,
    name = "us_semester"
  ),

  us_quarter = list(
    periods = list(
      list(name = "Fall",   code = "fa", start_mmdd = "09-20"),
      list(name = "Winter", code = "wi", start_mmdd = "01-05"),
      list(name = "Spring", code = "sp", start_mmdd = "03-30"),
      list(name = "Summer", code = "su", start_mmdd = "06-20")
    ),
    year_start_period = "Fall",
    yyyym_strict = FALSE,
    name = "us_quarter"
  ),

  uk_terms = list(
    periods = list(
      list(name = "Michaelmas", code = "mi", start_mmdd = "10-01"),
      list(name = "Lent",       code = "le", start_mmdd = "01-15"),
      list(name = "Easter",     code = "ea", start_mmdd = "04-22")
    ),
    year_start_period = "Michaelmas",
    yyyym_strict = FALSE,
    name = "uk_terms"
  ),

  trimester = list(
    periods = list(
      list(name = "Fall",   code = "fa", start_mmdd = "09-01"),
      list(name = "Winter", code = "wi", start_mmdd = "01-10"),
      list(name = "Spring", code = "sp", start_mmdd = "04-01")
    ),
    year_start_period = "Fall",
    yyyym_strict = FALSE,
    name = "trimester"
  ),

  us_federal_fy = list(
    periods = list(
      list(name = "Q1", code = "q1fy", start_mmdd = "10-01"),
      list(name = "Q2", code = "q2fy", start_mmdd = "01-01"),
      list(name = "Q3", code = "q3fy", start_mmdd = "04-01"),
      list(name = "Q4", code = "q4fy", start_mmdd = "07-01")
    ),
    year_start_period = "Q1",
    yyyym_strict = FALSE,
    name = "us_federal_fy"
  ),

  australia_semester = list(
    periods = list(
      list(name = "Semester 1", code = "s1", start_mmdd = "02-22"),
      list(name = "Semester 2", code = "s2", start_mmdd = "07-22")
    ),
    year_start_period = "Semester 1",
    yyyym_strict = FALSE,
    single_year_ay = TRUE,   # ay = "2026" not "2026-27"
    name = "australia_semester"
  )
)
