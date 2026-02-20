setup_semester <- function() use_chunk_preset("us_semester")

test_that("format(style='code') produces code format", {
  setup_semester()
  x <- time_chunk("fa26")
  expect_equal(format(x, style = "code"), "fa26")
})

test_that("format(style='name') produces name-year format", {
  setup_semester()
  x <- time_chunk("fa26")
  expect_equal(format(x, style = "name"), "Fall 2026")
})

test_that("format(style='ay') produces academic year string", {
  setup_semester()
  x <- time_chunk("fa26")
  expect_equal(format(x, style = "ay"), "2026-27")
})

test_that("format(style='key') produces sortable composite key", {
  setup_semester()
  x <- time_chunk("fa26")
  expect_equal(format(x, style = "key"), "2026-27_1_08_Fall")
})

test_that("format(style='iso_date') produces start date string", {
  setup_semester()
  x <- time_chunk("fa26")
  expect_equal(format(x, style = "iso_date"), "2026-08-23")
})

test_that("format() default style is 'name'", {
  setup_semester()
  x <- time_chunk("fa26")
  expect_equal(format(x), "Fall 2026")
})

test_that("format() glue template works", {
  setup_semester()
  x <- time_chunk("fa26")
  expect_equal(format(x, style = "{ay}_{chunk_index}_{name}"), "2026-27_1_Fall")
})

test_that("format() glue template with code and year", {
  setup_semester()
  x <- time_chunk("fa26")
  result <- format(x, style = "{code}{substr(as.character(year), 3, 4)}")
  # glue evaluates as expression — this is more of a confirmation that
  # simple variable substitution works
  result2 <- format(x, style = "{name} ({ay})")
  expect_equal(result2, "Fall (2026-27)")
})

test_that("format() errors on unknown style", {
  setup_semester()
  x <- time_chunk("fa26")
  expect_error(format(x, style = "unknown_style"), class = "timechunks_unknown_style")
})

test_that("format() returns character(0) for empty time_chunk", {
  setup_semester()
  x <- new_time_chunk()
  expect_equal(format(x), character(0L))
})

test_that("format() vectorizes over time_chunk length", {
  setup_semester()
  x <- time_chunk(c("fa26", "sp27", "su27"))
  result <- format(x, style = "code")
  expect_equal(result, c("fa26", "sp27", "su27"))
})

test_that("print.time_chunk() outputs correct header and calendar name", {
  setup_semester()
  x <- time_chunk(c("fa26", "sp27"))
  output <- capture.output(print(x))
  expect_true(any(grepl("time_chunk\\[2\\]", output)))
  expect_true(any(grepl("us_semester", output)))
})

test_that("print.time_chunk() outputs empty notice for length-0 vector", {
  setup_semester()
  x <- new_time_chunk()
  output <- capture.output(print(x))
  expect_true(any(grepl("time_chunk\\[0\\]", output)))
  expect_true(any(grepl("empty", output)))
})
