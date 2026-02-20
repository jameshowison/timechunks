setup_semester <- function() use_chunk_preset("us_semester")

# time_chunk() dispatcher -------------------------------------------------

test_that("time_chunk() returns empty vector for length-0 input", {
  setup_semester()
  expect_length(time_chunk(character(0)), 0L)
  expect_length(time_chunk(integer(0)),   0L)
})

test_that("time_chunk() dispatches code format", {
  setup_semester()
  x <- time_chunk("fa26")
  expect_s3_class(x, "time_chunk")
  expect_equal(vctrs::field(x, "name"), "Fall")
})

test_that("time_chunk() dispatches text format", {
  setup_semester()
  x <- time_chunk("Fall 2026")
  expect_equal(vctrs::field(x, "name"), "Fall")
})

test_that("time_chunk() dispatches YYYYM numeric", {
  setup_semester()
  x <- time_chunk(20268L)
  expect_equal(vctrs::field(x, "name"), "Fall")
})

test_that("time_chunk() dispatches YYYYM as numeric (not integer)", {
  setup_semester()
  x <- time_chunk(20268)
  expect_equal(vctrs::field(x, "name"), "Fall")
})

test_that("time_chunk() dispatches composite key", {
  setup_semester()
  x <- time_chunk("2026-27_1_08_Fall")
  expect_equal(vctrs::field(x, "name"), "Fall")
})

test_that("time_chunk() vectorizes over character input", {
  setup_semester()
  x <- time_chunk(c("fa26", "sp27", "su27"))
  expect_length(x, 3L)
  expect_equal(vctrs::field(x, "name"), c("Fall", "Spring", "Summer"))
})

test_that("time_chunk() handles NA input", {
  setup_semester()
  x <- time_chunk(NA_character_)
  expect_length(x, 1L)
  expect_true(is.na(vctrs::field(x, "name")))
})

test_that("time_chunk() errors on unsupported type", {
  setup_semester()
  expect_error(time_chunk(TRUE), class = "timechunks_parse_error")
})


# parse_chunk_code() -------------------------------------------------------

test_that("parse_chunk_code() parses lowercase code", {
  setup_semester()
  x <- parse_chunk_code("fa26")
  expect_equal(vctrs::field(x, "name"),         "Fall")
  expect_equal(vctrs::field(x, "code"),         "fa")
  expect_equal(vctrs::field(x, "year"),         2026L)
  expect_equal(vctrs::field(x, "start_date"),   as.Date("2026-08-23"))
  expect_equal(vctrs::field(x, "end_date"),     as.Date("2027-01-14"))
  expect_equal(vctrs::field(x, "ay"),           "2026-27")
  expect_equal(vctrs::field(x, "period_index"), 1L)
})

test_that("parse_chunk_code() is case-insensitive", {
  setup_semester()
  x1 <- parse_chunk_code("FA26")
  x2 <- parse_chunk_code("fa26")
  expect_equal(vctrs::field(x1, "name"), vctrs::field(x2, "name"))
})

test_that("parse_chunk_code() 2-digit year: 00-49 -> 2000-2049", {
  setup_semester()
  expect_equal(vctrs::field(parse_chunk_code("fa00"), "year"), 2000L)
  expect_equal(vctrs::field(parse_chunk_code("fa49"), "year"), 2049L)
})

test_that("parse_chunk_code() 2-digit year: 50-99 -> 1950-1999", {
  setup_semester()
  expect_equal(vctrs::field(parse_chunk_code("fa50"), "year"), 1950L)
  expect_equal(vctrs::field(parse_chunk_code("fa99"), "year"), 1999L)
})

test_that("parse_chunk_code() parses spring and summer", {
  setup_semester()
  sp <- parse_chunk_code("sp27")
  expect_equal(vctrs::field(sp, "name"),       "Spring")
  expect_equal(vctrs::field(sp, "start_date"), as.Date("2027-01-15"))
  expect_equal(vctrs::field(sp, "ay"),         "2026-27")

  su <- parse_chunk_code("su27")
  expect_equal(vctrs::field(su, "name"),       "Summer")
  expect_equal(vctrs::field(su, "start_date"), as.Date("2027-06-01"))
  expect_equal(vctrs::field(su, "ay"),         "2026-27")
})

test_that("parse_chunk_code() errors on unknown code", {
  setup_semester()
  expect_error(parse_chunk_code("wi26"), class = "timechunks_unknown_code")
})

test_that("parse_chunk_code() vectorizes", {
  setup_semester()
  x <- parse_chunk_code(c("fa26", "sp27"))
  expect_length(x, 2L)
})


# parse_chunk_text() -------------------------------------------------------

test_that("parse_chunk_text() parses 'Name Year' format", {
  setup_semester()
  x <- parse_chunk_text("Fall 2026")
  expect_equal(vctrs::field(x, "name"), "Fall")
  expect_equal(vctrs::field(x, "year"), 2026L)
})

test_that("parse_chunk_text() parses 'Year Name' format", {
  setup_semester()
  x <- parse_chunk_text("2026 Fall")
  expect_equal(vctrs::field(x, "name"), "Fall")
  expect_equal(vctrs::field(x, "year"), 2026L)
})

test_that("parse_chunk_text() is case-insensitive", {
  setup_semester()
  x <- parse_chunk_text("fall 2026")
  expect_equal(vctrs::field(x, "name"), "Fall")
})

test_that("parse_chunk_text() trims whitespace", {
  setup_semester()
  x <- parse_chunk_text("  Fall 2026  ")
  expect_equal(vctrs::field(x, "name"), "Fall")
})

test_that("parse_chunk_text() errors on unknown name", {
  setup_semester()
  expect_error(parse_chunk_text("Winter 2026"), class = "timechunks_parse_error")
})

test_that("parse_chunk_text() and parse_chunk_code() produce same result", {
  setup_semester()
  x1 <- parse_chunk_code("fa26")
  x2 <- parse_chunk_text("Fall 2026")
  expect_equal(vctrs::field(x1, "start_date"), vctrs::field(x2, "start_date"))
  expect_equal(vctrs::field(x1, "ay"),         vctrs::field(x2, "ay"))
})


# parse_chunk_numeric() ----------------------------------------------------

test_that("parse_chunk_numeric() maps August -> Fall (5-digit)", {
  setup_semester()
  x <- parse_chunk_numeric(20268L)
  expect_equal(vctrs::field(x, "name"), "Fall")
  expect_equal(vctrs::field(x, "year"), 2026L)
})

test_that("parse_chunk_numeric() maps November -> Fall (6-digit)", {
  setup_semester()
  x <- parse_chunk_numeric(202611L)
  expect_equal(vctrs::field(x, "name"), "Fall")
  expect_equal(vctrs::field(x, "year"), 2026L)
})

test_that("parse_chunk_numeric() maps January -> Spring", {
  setup_semester()
  x <- parse_chunk_numeric(202701L)
  expect_equal(vctrs::field(x, "name"), "Spring")
  expect_equal(vctrs::field(x, "year"), 2027L)
})

test_that("parse_chunk_numeric() maps June -> Summer", {
  setup_semester()
  x <- parse_chunk_numeric(202706L)
  expect_equal(vctrs::field(x, "name"), "Summer")
  expect_equal(vctrs::field(x, "year"), 2027L)
})

test_that("parse_chunk_numeric() errors on wrong digit count", {
  setup_semester()
  expect_error(parse_chunk_numeric(2026L),   class = "timechunks_parse_error")
  expect_error(parse_chunk_numeric(2026011L), class = "timechunks_parse_error")
})

test_that("parse_chunk_numeric() strict mode errors on ambiguous month", {
  set_chunk_calendar(
    periods = list(
      list(name = "Fall",   code = "fa", start_mmdd = "08-01"),
      list(name = "Spring", code = "sp", start_mmdd = "01-01"),
      list(name = "Summer", code = "su", start_mmdd = "05-01")
    ),
    year_start_period = "Fall",
    yyyym_strict = TRUE
  )
  # August maps to both Fall (08) — actually only Fall here since Summer=05
  # For strict to trigger we need genuinely same month.
  # Use January: Spring starts 01 and only Spring maps to 01, so no ambiguity.
  # Test the no-ambiguity case first:
  expect_no_error(parse_chunk_numeric(202701L))

  # Now create a calendar with two periods starting in the same month
  set_chunk_calendar(
    periods = list(
      list(name = "A", code = "aa", start_mmdd = "01-01"),
      list(name = "B", code = "bb", start_mmdd = "01-15")
    ),
    year_start_period = "A",
    yyyym_strict = TRUE
  )
  expect_error(parse_chunk_numeric(20261L), class = "timechunks_ambiguous_month")
  use_chunk_preset("us_semester")  # restore
})

test_that("parse_chunk_numeric() uses yyyym_map when provided", {
  set_chunk_calendar(
    periods = list(
      list(name = "Fall",   code = "fa", start_mmdd = "08-23"),
      list(name = "Spring", code = "sp", start_mmdd = "01-15"),
      list(name = "Summer", code = "su", start_mmdd = "06-01")
    ),
    year_start_period = "Fall",
    yyyym_map = list("08" = "Fall", "01" = "Spring")
  )
  x <- parse_chunk_numeric(20268L)
  expect_equal(vctrs::field(x, "name"), "Fall")
  use_chunk_preset("us_semester")  # restore
})


# Composite key ------------------------------------------------------------

test_that("composite key round-trips correctly", {
  setup_semester()
  x    <- time_chunk("fa26")
  key  <- format(x, style = "key")
  expect_equal(key, "2026-27_1_08_Fall")
  x2   <- time_chunk(key)
  expect_equal(vctrs::field(x, "start_date"), vctrs::field(x2, "start_date"))
  expect_equal(vctrs::field(x, "ay"),         vctrs::field(x2, "ay"))
})

test_that("composite key errors on unknown period name", {
  setup_semester()
  expect_error(
    time_chunk("2026-27_1_08_Winter"),
    class = "timechunks_parse_error"
  )
})


# End date computation ----------------------------------------------------

test_that("end date = day before next period start for non-final period", {
  setup_semester()
  # Fall 2026: next period is Spring, starting 2027-01-15
  x <- time_chunk("fa26")
  expect_equal(vctrs::field(x, "end_date"), as.Date("2027-01-14"))
})

test_that("end date of final period = day before year-start period restarts", {
  setup_semester()
  # Summer 2027: last period; year-start is Fall (Aug-23).
  # Fall 2027 starts Aug-23 > Jun-01, so end = Aug-22, 2027.
  x <- time_chunk("su27")
  expect_equal(vctrs::field(x, "end_date"), as.Date("2027-08-22"))
})
