test_that("use_chunk_preset() sets the calendar", {
  use_chunk_preset("us_semester")
  cal <- default_chunk_calendar()
  expect_equal(cal$name, "us_semester")
  expect_length(cal$periods, 3L)
})

test_that("use_chunk_preset() errors on unknown preset", {
  expect_error(
    use_chunk_preset("made_up_preset"),
    class = "timechunks_unknown_preset"
  )
})

test_that("default_chunk_calendar() errors when no calendar is set", {
  old <- getOption("timechunks.calendar")
  on.exit(options(timechunks.calendar = old))
  options(timechunks.calendar = NULL)
  expect_error(default_chunk_calendar(), class = "timechunks_no_calendar")
})

test_that("set_chunk_calendar() sets a custom calendar", {
  set_chunk_calendar(
    periods = list(
      list(name = "Fall",   code = "fa", start_mmdd = "09-01"),
      list(name = "Spring", code = "sp", start_mmdd = "02-01")
    ),
    year_start_period = "Fall",
    name = "test_cal"
  )
  cal <- default_chunk_calendar()
  expect_equal(cal$name, "test_cal")
  expect_equal(cal$year_start_period, "Fall")
  use_chunk_preset("us_semester")  # restore
})

test_that("set_chunk_calendar() errors on empty periods", {
  expect_error(
    set_chunk_calendar(periods = list(), year_start_period = "Fall"),
    class = "timechunks_invalid_calendar"
  )
})

test_that("set_chunk_calendar() errors on missing period fields", {
  expect_error(
    set_chunk_calendar(
      periods = list(list(name = "Fall", code = "fa")),
      year_start_period = "Fall"
    ),
    class = "timechunks_invalid_calendar"
  )
})

test_that("set_chunk_calendar() errors on invalid start_mmdd format", {
  expect_error(
    set_chunk_calendar(
      periods = list(list(name = "Fall", code = "fa", start_mmdd = "823")),
      year_start_period = "Fall"
    ),
    class = "timechunks_invalid_calendar"
  )
})

test_that("set_chunk_calendar() errors when year_start_period not in periods", {
  expect_error(
    set_chunk_calendar(
      periods = list(list(name = "Fall", code = "fa", start_mmdd = "09-01")),
      year_start_period = "Spring"
    ),
    class = "timechunks_invalid_calendar"
  )
})

test_that("set_chunk_calendar() validates yyyym_map keys", {
  expect_error(
    set_chunk_calendar(
      periods = list(list(name = "Fall", code = "fa", start_mmdd = "09-01")),
      year_start_period = "Fall",
      yyyym_map = list("13" = "Fall")
    ),
    class = "timechunks_invalid_calendar"
  )
})

test_that("set_chunk_calendar() validates yyyym_map values", {
  expect_error(
    set_chunk_calendar(
      periods = list(list(name = "Fall", code = "fa", start_mmdd = "09-01")),
      year_start_period = "Fall",
      yyyym_map = list("09" = "UnknownPeriod")
    ),
    class = "timechunks_invalid_calendar"
  )
})

test_that(".compute_ay() returns correct ay for us_semester", {
  use_chunk_preset("us_semester")
  cal <- default_chunk_calendar()
  expect_equal(.compute_ay(cal, "Fall",   2026L), "2026-27")
  expect_equal(.compute_ay(cal, "Spring", 2027L), "2026-27")
  expect_equal(.compute_ay(cal, "Summer", 2027L), "2026-27")
  expect_equal(.compute_ay(cal, "Fall",   2027L), "2027-28")
})

test_that(".compute_ay() returns single year for australia_semester", {
  use_chunk_preset("australia_semester")
  cal <- default_chunk_calendar()
  expect_equal(.compute_ay(cal, "Semester 1", 2026L), "2026")
  expect_equal(.compute_ay(cal, "Semester 2", 2026L), "2026")
  use_chunk_preset("us_semester")  # restore
})
