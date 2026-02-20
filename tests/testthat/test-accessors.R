setup_semester <- function() use_chunk_preset("us_semester")

test_that("chunk_name() returns period names", {
  setup_semester()
  x <- time_chunk(c("fa26", "sp27", "su27"))
  expect_equal(chunk_name(x), c("Fall", "Spring", "Summer"))
})

test_that("chunk_code() returns period codes", {
  setup_semester()
  x <- time_chunk(c("fa26", "sp27", "su27"))
  expect_equal(chunk_code(x), c("fa", "sp", "su"))
})

test_that("chunk_year() returns calendar years", {
  setup_semester()
  x <- time_chunk(c("fa26", "sp27", "su27"))
  expect_equal(chunk_year(x), c(2026L, 2027L, 2027L))
})

test_that("chunk_ay() returns academic year strings", {
  setup_semester()
  x <- time_chunk(c("fa26", "sp27", "su27"))
  expect_equal(chunk_ay(x), c("2026-27", "2026-27", "2026-27"))
})

test_that("chunk_index() returns period positions", {
  setup_semester()
  x <- time_chunk(c("fa26", "sp27", "su27"))
  expect_equal(chunk_index(x), c(1L, 2L, 3L))
})

test_that("start_date() returns Date vector", {
  setup_semester()
  x <- time_chunk("fa26")
  s <- start_date(x)
  expect_s3_class(s, "Date")
  expect_equal(s, as.Date("2026-08-23"))
})

test_that("end_date() returns Date vector", {
  setup_semester()
  x <- time_chunk("fa26")
  e <- end_date(x)
  expect_s3_class(e, "Date")
  expect_equal(e, as.Date("2027-01-14"))
})

test_that("mid_date() returns midpoint between start and end", {
  setup_semester()
  x <- time_chunk("fa26")
  s <- as.integer(as.Date("2026-08-23"))
  e <- as.integer(as.Date("2027-01-14"))
  expected <- as.Date((s + e) %/% 2L, origin = "1970-01-01")
  expect_equal(mid_date(x), expected)
})

test_that("mid_date() is between start_date and end_date", {
  setup_semester()
  x <- time_chunk(c("fa26", "sp27", "su27"))
  expect_true(all(mid_date(x) >= start_date(x)))
  expect_true(all(mid_date(x) <= end_date(x)))
})

test_that("all accessors return same length as input", {
  setup_semester()
  x <- time_chunk(c("fa26", "sp27", "su27"))
  n <- 3L
  expect_length(chunk_name(x),  n)
  expect_length(chunk_code(x),  n)
  expect_length(chunk_year(x),  n)
  expect_length(chunk_ay(x),    n)
  expect_length(chunk_index(x), n)
  expect_length(start_date(x),  n)
  expect_length(end_date(x),    n)
  expect_length(mid_date(x),    n)
})

test_that("accessors error on non-time_chunk input", {
  setup_semester()
  expect_error(chunk_name("fa26"),   class = "timechunks_type_error")
  expect_error(start_date("fa26"),   class = "timechunks_type_error")
  expect_error(end_date("fa26"),     class = "timechunks_type_error")
  expect_error(mid_date("fa26"),     class = "timechunks_type_error")
  expect_error(chunk_ay("fa26"),     class = "timechunks_type_error")
  expect_error(chunk_code("fa26"),   class = "timechunks_type_error")
  expect_error(chunk_year("fa26"),   class = "timechunks_type_error")
  expect_error(chunk_index("fa26"),  class = "timechunks_type_error")
})

test_that("accessors handle NA values gracefully", {
  setup_semester()
  x <- time_chunk(NA_character_)
  expect_true(is.na(chunk_name(x)))
  expect_true(is.na(start_date(x)))
  expect_true(is.na(end_date(x)))
})
