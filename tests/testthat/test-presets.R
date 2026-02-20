# Tests for all 6 calendar presets.
# Each test block: activate the preset, verify parsing + dates + AY + arithmetic.

restore <- function() use_chunk_preset("us_semester")

# us_quarter --------------------------------------------------------------

test_that("us_quarter: 4 periods, year starts Fall", {
  use_chunk_preset("us_quarter")
  cal <- default_chunk_calendar()
  expect_equal(cal$name, "us_quarter")
  expect_length(cal$periods, 4L)
  expect_equal(cal$year_start_period, "Fall")
  restore()
})

test_that("us_quarter: Fall 2026 start/end dates", {
  use_chunk_preset("us_quarter")
  x <- time_chunk("fa26")
  expect_equal(chunk_name(x),      "Fall")
  expect_equal(start_date(x),      as.Date("2026-09-20"))
  expect_equal(end_date(x),        as.Date("2027-01-04"))  # day before Winter Jan-05
  expect_equal(chunk_ay(x),        "2026-27")
  restore()
})

test_that("us_quarter: Winter 2027 (crosses year boundary)", {
  use_chunk_preset("us_quarter")
  x <- time_chunk("wi27")
  expect_equal(chunk_name(x),      "Winter")
  expect_equal(start_date(x),      as.Date("2027-01-05"))
  expect_equal(end_date(x),        as.Date("2027-03-29"))  # day before Spring Mar-30
  expect_equal(chunk_ay(x),        "2026-27")
  restore()
})

test_that("us_quarter: Spring 2027", {
  use_chunk_preset("us_quarter")
  x <- time_chunk("sp27")
  expect_equal(chunk_name(x),      "Spring")
  expect_equal(start_date(x),      as.Date("2027-03-30"))
  expect_equal(end_date(x),        as.Date("2027-06-19"))  # day before Summer Jun-20
  expect_equal(chunk_ay(x),        "2026-27")
  restore()
})

test_that("us_quarter: Summer 2027", {
  use_chunk_preset("us_quarter")
  x <- time_chunk("su27")
  expect_equal(chunk_name(x),      "Summer")
  expect_equal(start_date(x),      as.Date("2027-06-20"))
  expect_equal(end_date(x),        as.Date("2027-09-19"))  # day before Fall Sep-20
  expect_equal(chunk_ay(x),        "2026-27")
  restore()
})

test_that("us_quarter: arithmetic spans 4 periods per AY", {
  use_chunk_preset("us_quarter")
  x <- time_chunk("fa26")
  expect_equal(chunk_name(x + 1L), "Winter")
  expect_equal(chunk_name(x + 2L), "Spring")
  expect_equal(chunk_name(x + 3L), "Summer")
  expect_equal(chunk_name(x + 4L), "Fall")
  expect_equal(chunk_year(x + 4L), 2027L)
  d <- time_chunk("su27") - time_chunk("fa26")
  expect_equal(d, 3L)
  restore()
})

test_that("us_quarter: seq produces correct 5-period sequence", {
  use_chunk_preset("us_quarter")
  s <- seq(time_chunk("fa26"), time_chunk("fa27"))
  expect_length(s, 5L)
  expect_equal(chunk_name(s), c("Fall", "Winter", "Spring", "Summer", "Fall"))
  restore()
})

test_that("us_quarter: YYYYM month mapping", {
  use_chunk_preset("us_quarter")
  # September (09) -> Fall (starts Sep 20)
  expect_equal(chunk_name(time_chunk(20269L)), "Fall")
  # January (01) -> Winter (starts Jan 05)
  expect_equal(chunk_name(time_chunk(202701L)), "Winter")
  # March (03) -> Winter (03 < 06, so closest is Jan=01)...
  # actually Mar(03) >= Jan(01) so Winter is a candidate
  # and Spring starts Mar(03) so Spring is also a candidate — most recent wins
  expect_equal(chunk_name(time_chunk(202703L)), "Spring")
  # July (07) -> Summer (starts Jun 20)
  expect_equal(chunk_name(time_chunk(202707L)), "Summer")
  restore()
})


# uk_terms ----------------------------------------------------------------

test_that("uk_terms: 3 periods, year starts Michaelmas", {
  use_chunk_preset("uk_terms")
  cal <- default_chunk_calendar()
  expect_equal(cal$name, "uk_terms")
  expect_length(cal$periods, 3L)
  expect_equal(cal$year_start_period, "Michaelmas")
  restore()
})

test_that("uk_terms: Michaelmas 2026 dates and AY", {
  use_chunk_preset("uk_terms")
  x <- time_chunk("mi26")
  expect_equal(chunk_name(x),   "Michaelmas")
  expect_equal(start_date(x),   as.Date("2026-10-01"))
  expect_equal(end_date(x),     as.Date("2027-01-14"))  # day before Lent Jan-15
  expect_equal(chunk_ay(x),     "2026-27")
  restore()
})

test_that("uk_terms: Lent 2027 AY stays 2026-27", {
  use_chunk_preset("uk_terms")
  x <- time_chunk("le27")
  expect_equal(chunk_name(x),   "Lent")
  expect_equal(start_date(x),   as.Date("2027-01-15"))
  expect_equal(end_date(x),     as.Date("2027-04-21"))  # day before Easter Apr-22
  expect_equal(chunk_ay(x),     "2026-27")
  restore()
})

test_that("uk_terms: Easter 2027 AY stays 2026-27", {
  use_chunk_preset("uk_terms")
  x <- time_chunk("ea27")
  expect_equal(chunk_name(x),   "Easter")
  expect_equal(start_date(x),   as.Date("2027-04-22"))
  expect_equal(end_date(x),     as.Date("2027-09-30"))  # day before Michaelmas Oct-01
  expect_equal(chunk_ay(x),     "2026-27")
  restore()
})

test_that("uk_terms: arithmetic across year boundary", {
  use_chunk_preset("uk_terms")
  x <- time_chunk("mi26")
  expect_equal(chunk_name(x + 1L), "Lent")
  expect_equal(chunk_name(x + 2L), "Easter")
  expect_equal(chunk_name(x + 3L), "Michaelmas")
  expect_equal(chunk_year(x + 3L), 2027L)
  expect_equal(chunk_ay(x + 3L),   "2027-28")
  restore()
})


# trimester ---------------------------------------------------------------

test_that("trimester: 3 periods, year starts Fall", {
  use_chunk_preset("trimester")
  cal <- default_chunk_calendar()
  expect_equal(cal$name, "trimester")
  expect_length(cal$periods, 3L)
  restore()
})

test_that("trimester: Fall 2026 dates", {
  use_chunk_preset("trimester")
  x <- time_chunk("fa26")
  expect_equal(chunk_name(x),   "Fall")
  expect_equal(start_date(x),   as.Date("2026-09-01"))
  expect_equal(end_date(x),     as.Date("2027-01-09"))  # day before Winter Jan-10
  expect_equal(chunk_ay(x),     "2026-27")
  restore()
})

test_that("trimester: Winter 2027 AY", {
  use_chunk_preset("trimester")
  x <- time_chunk("wi27")
  expect_equal(chunk_ay(x), "2026-27")
  restore()
})

test_that("trimester: Spring 2027 AY", {
  use_chunk_preset("trimester")
  x <- time_chunk("sp27")
  expect_equal(chunk_name(x),   "Spring")
  expect_equal(start_date(x),   as.Date("2027-04-01"))
  expect_equal(end_date(x),     as.Date("2027-08-31"))  # day before Fall Sep-01
  expect_equal(chunk_ay(x),     "2026-27")
  restore()
})


# us_federal_fy -----------------------------------------------------------

test_that("us_federal_fy: 4 quarters, year starts Q1", {
  use_chunk_preset("us_federal_fy")
  cal <- default_chunk_calendar()
  expect_equal(cal$name, "us_federal_fy")
  expect_length(cal$periods, 4L)
  expect_equal(cal$year_start_period, "Q1")
  restore()
})

test_that("us_federal_fy: Q1 2026 dates (Oct 2026 start)", {
  use_chunk_preset("us_federal_fy")
  x <- time_chunk("q126")
  expect_equal(chunk_name(x),   "Q1")
  expect_equal(start_date(x),   as.Date("2026-10-01"))
  expect_equal(end_date(x),     as.Date("2026-12-31"))  # day before Q2 Jan-01
  expect_equal(chunk_ay(x),     "2026-27")
  restore()
})

test_that("us_federal_fy: Q2 through Q4 share AY 2026-27", {
  use_chunk_preset("us_federal_fy")
  expect_equal(chunk_ay(time_chunk("q227")), "2026-27")  # Jan 2027
  expect_equal(chunk_ay(time_chunk("q327")), "2026-27")  # Apr 2027
  expect_equal(chunk_ay(time_chunk("q427")), "2026-27")  # Jul 2027
  restore()
})

test_that("us_federal_fy: arithmetic 4 quarters per year", {
  use_chunk_preset("us_federal_fy")
  x <- time_chunk("q126")
  expect_equal(chunk_name(x + 1L), "Q2")
  expect_equal(chunk_name(x + 2L), "Q3")
  expect_equal(chunk_name(x + 3L), "Q4")
  expect_equal(chunk_name(x + 4L), "Q1")
  expect_equal(chunk_year(x + 4L), 2027L)
  restore()
})

test_that("us_federal_fy: YYYYM maps October -> Q1", {
  use_chunk_preset("us_federal_fy")
  expect_equal(chunk_name(time_chunk(202610L)), "Q1")
  expect_equal(chunk_name(time_chunk(202701L)), "Q2")
  expect_equal(chunk_name(time_chunk(202704L)), "Q3")
  expect_equal(chunk_name(time_chunk(202707L)), "Q4")
  restore()
})


# australia_semester ------------------------------------------------------

test_that("australia_semester: 2 periods, single_year_ay = TRUE", {
  use_chunk_preset("australia_semester")
  cal <- default_chunk_calendar()
  expect_equal(cal$name, "australia_semester")
  expect_true(isTRUE(cal$single_year_ay))
  restore()
})

test_that("australia_semester: Semester 1 2026 AY is '2026'", {
  use_chunk_preset("australia_semester")
  x <- time_chunk("s126")
  expect_equal(chunk_name(x),   "Semester 1")
  expect_equal(start_date(x),   as.Date("2026-02-22"))
  expect_equal(end_date(x),     as.Date("2026-07-21"))  # day before Semester 2 Jul-22
  expect_equal(chunk_ay(x),     "2026")
  restore()
})

test_that("australia_semester: Semester 2 2026 AY is '2026'", {
  use_chunk_preset("australia_semester")
  x <- time_chunk("s226")
  expect_equal(chunk_name(x),   "Semester 2")
  expect_equal(start_date(x),   as.Date("2026-07-22"))
  expect_equal(end_date(x),     as.Date("2027-02-21"))  # day before Semester 1 Feb-22
  expect_equal(chunk_ay(x),     "2026")
  restore()
})

test_that("australia_semester: Semester 1 and 2 same year share AY", {
  use_chunk_preset("australia_semester")
  x <- time_chunk(c("s126", "s226"))
  expect_equal(chunk_ay(x), c("2026", "2026"))
  restore()
})

test_that("australia_semester: different years have different AYs", {
  use_chunk_preset("australia_semester")
  x <- time_chunk(c("s126", "s127"))
  expect_equal(chunk_ay(x), c("2026", "2027"))
  restore()
})

test_that("australia_semester: arithmetic wraps correctly", {
  use_chunk_preset("australia_semester")
  x <- time_chunk("s126")
  expect_equal(chunk_name(x + 1L), "Semester 2")
  expect_equal(chunk_year(x + 1L), 2026L)
  expect_equal(chunk_name(x + 2L), "Semester 1")
  expect_equal(chunk_year(x + 2L), 2027L)
  restore()
})

test_that("australia_semester: seq produces correct sequence", {
  use_chunk_preset("australia_semester")
  s <- seq(time_chunk("s126"), time_chunk("s127"))
  expect_length(s, 3L)
  expect_equal(chunk_name(s), c("Semester 1", "Semester 2", "Semester 1"))
  expect_equal(chunk_year(s), c(2026L, 2026L, 2027L))
  restore()
})


# Non-overlap property ----------------------------------------------------
# For every preset, generate a multi-year sequence and assert that no period's
# end_date >= the following period's start_date. This is the property that was
# violated before the last-period end-date fix (Summer ended Dec-31, overlapping
# with the next Fall that started Aug-23 of the same year).

.check_no_overlap <- function(preset) {
  use_chunk_preset(preset)
  cal  <- default_chunk_calendar()
  # Build the first-period code for the year-start period
  ys_code <- tolower(vapply(cal$periods, `[[`, character(1), "code")[
    vapply(cal$periods, `[[`, character(1), "name") == cal$year_start_period
  ])
  from <- time_chunk(paste0(ys_code, "25"))
  to   <- time_chunk(paste0(ys_code, "28"))
  s    <- seq(from, to)
  starts <- start_date(s)
  ends   <- end_date(s)
  n      <- length(s)
  # Every end must be strictly before the next period's start
  overlapping <- which(ends[-n] >= starts[-1])
  if (length(overlapping) > 0) {
    bad <- overlapping[1]
    stop(glue::glue(
      "Overlap in preset '{preset}': period {bad} ",
      "({format(ends[bad])}) >= period {bad+1} start ({format(starts[bad+1])})"
    ))
  }
  invisible(TRUE)
}

test_that("no period overlaps in us_semester across 3 academic years", {
  expect_no_error(.check_no_overlap("us_semester"))
  restore()
})

test_that("no period overlaps in us_quarter across 3 academic years", {
  expect_no_error(.check_no_overlap("us_quarter"))
  restore()
})

test_that("no period overlaps in uk_terms across 3 academic years", {
  expect_no_error(.check_no_overlap("uk_terms"))
  restore()
})

test_that("no period overlaps in trimester across 3 academic years", {
  expect_no_error(.check_no_overlap("trimester"))
  restore()
})

test_that("no period overlaps in us_federal_fy across 3 academic years", {
  expect_no_error(.check_no_overlap("us_federal_fy"))
  restore()
})

test_that("no period overlaps in australia_semester across 3 academic years", {
  expect_no_error(.check_no_overlap("australia_semester"))
  restore()
})

test_that("no period overlaps in custom calendar", {
  set_chunk_calendar(
    periods = list(
      list(name = "Q1", code = "q1", start_mmdd = "03-01"),
      list(name = "Q2", code = "q2", start_mmdd = "06-01"),
      list(name = "Q3", code = "q3", start_mmdd = "09-01"),
      list(name = "Q4", code = "q4", start_mmdd = "12-01")
    ),
    year_start_period = "Q1"
  )
  from <- time_chunk("q125"); to <- time_chunk("q128")
  s <- seq(from, to)
  starts <- start_date(s); ends <- end_date(s); n <- length(s)
  expect_true(all(ends[-n] < starts[-1]))
  restore()
})

# yyyym_map explicit override ---------------------------------------------

test_that("yyyym_map overrides automatic month resolution", {
  set_chunk_calendar(
    periods = list(
      list(name = "Fall",   code = "fa", start_mmdd = "08-23"),
      list(name = "Spring", code = "sp", start_mmdd = "01-15"),
      list(name = "Summer", code = "su", start_mmdd = "06-01")
    ),
    year_start_period = "Fall",
    yyyym_map = list("08" = "Fall", "09" = "Fall",
                     "10" = "Fall", "11" = "Fall", "12" = "Fall",
                     "01" = "Spring", "02" = "Spring", "03" = "Spring",
                     "04" = "Spring", "05" = "Spring",
                     "06" = "Summer", "07" = "Summer")
  )
  expect_equal(chunk_name(time_chunk(20268L)), "Fall")
  expect_equal(chunk_name(time_chunk(202701L)), "Spring")
  expect_equal(chunk_name(time_chunk(202707L)), "Summer")
  restore()
})
