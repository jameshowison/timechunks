test_that("new_time_chunk() creates an empty time_chunk", {
  x <- new_time_chunk()
  expect_s3_class(x, "time_chunk")
  expect_length(x, 0L)
})

test_that("new_time_chunk() creates a length-1 time_chunk", {
  x <- new_time_chunk(
    start_date   = as.Date("2026-08-23"),
    end_date     = as.Date("2027-01-14"),
    name         = "Fall",
    code         = "fa",
    year         = 2026L,
    period_index = 1L,
    ay           = "2026-27"
  )
  expect_s3_class(x, "time_chunk")
  expect_length(x, 1L)
})

test_that("is_time_chunk() returns TRUE for time_chunk", {
  use_chunk_preset("us_semester")
  x <- time_chunk("fa26")
  expect_true(is_time_chunk(x))
})

test_that("is_time_chunk() returns FALSE for non-time_chunk", {
  expect_false(is_time_chunk("fa26"))
  expect_false(is_time_chunk(42L))
  expect_false(is_time_chunk(list()))
})

test_that("validate_time_chunk() passes for valid object", {
  x <- new_time_chunk(
    start_date   = as.Date("2026-08-23"),
    end_date     = as.Date("2027-01-14"),
    name         = "Fall",
    code         = "fa",
    year         = 2026L,
    period_index = 1L,
    ay           = "2026-27"
  )
  expect_no_error(validate_time_chunk(x))
})

test_that("validate_time_chunk() errors when end_date < start_date", {
  x <- new_time_chunk(
    start_date   = as.Date("2027-01-14"),
    end_date     = as.Date("2026-08-23"),
    name         = "Fall",
    code         = "fa",
    year         = 2026L,
    period_index = 1L,
    ay           = "2026-27"
  )
  expect_error(validate_time_chunk(x), class = "timechunks_invalid_object")
})
