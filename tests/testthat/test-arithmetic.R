setup_semester <- function() use_chunk_preset("us_semester")

# Addition ----------------------------------------------------------------

test_that("time_chunk + 1L advances one period", {
  setup_semester()
  x <- time_chunk("fa26")
  expect_equal(chunk_name(x + 1L), "Spring")
  expect_equal(chunk_year(x + 1L), 2027L)
})

test_that("time_chunk + 2L advances two periods", {
  setup_semester()
  x <- time_chunk("fa26")
  result <- x + 2L
  expect_equal(chunk_name(result), "Summer")
  expect_equal(chunk_year(result), 2027L)
})

test_that("time_chunk + 3L wraps to next academic year", {
  setup_semester()
  x <- time_chunk("fa26")
  result <- x + 3L
  expect_equal(chunk_name(result), "Fall")
  expect_equal(chunk_year(result), 2027L)
})

test_that("time_chunk + 6L advances two full academic years", {
  setup_semester()
  x <- time_chunk("fa26")
  result <- x + 6L
  expect_equal(chunk_name(result), "Fall")
  expect_equal(chunk_year(result), 2028L)
})

test_that("integer + time_chunk works (commutative)", {
  setup_semester()
  x <- time_chunk("fa26")
  expect_equal(format(1L + x, style = "name"), format(x + 1L, style = "name"))
})

test_that("addition from Spring advances correctly", {
  setup_semester()
  x <- time_chunk("sp27")
  expect_equal(chunk_name(x + 1L), "Summer")
  expect_equal(chunk_year(x + 1L), 2027L)
  expect_equal(chunk_name(x + 2L), "Fall")
  expect_equal(chunk_year(x + 2L), 2027L)
})

test_that("addition from Summer wraps to Fall next year", {
  setup_semester()
  x <- time_chunk("su27")
  result <- x + 1L
  expect_equal(chunk_name(result), "Fall")
  expect_equal(chunk_year(result), 2027L)
})

test_that("+ errors on unsupported types", {
  setup_semester()
  x <- time_chunk("fa26")
  expect_error(x + "1", class = "timechunks_arithmetic_error")
})

test_that("addition preserves ay correctly", {
  setup_semester()
  expect_equal(chunk_ay(time_chunk("fa26") + 1L), "2026-27")
  expect_equal(chunk_ay(time_chunk("fa26") + 2L), "2026-27")
  expect_equal(chunk_ay(time_chunk("fa26") + 3L), "2027-28")
})


# Subtraction (shift) -----------------------------------------------------

test_that("time_chunk - 1L goes back one period", {
  setup_semester()
  x <- time_chunk("sp27")
  result <- x - 1L
  expect_equal(chunk_name(result), "Fall")
  expect_equal(chunk_year(result), 2026L)
})

test_that("time_chunk - 2L goes back two periods across year boundary", {
  setup_semester()
  x <- time_chunk("sp27")
  result <- x - 2L
  expect_equal(chunk_name(result), "Summer")
  expect_equal(chunk_year(result), 2026L)
})

test_that("subtraction is inverse of addition", {
  setup_semester()
  x <- time_chunk("fa26")
  expect_equal(
    format((x + 5L) - 5L, style = "name"),
    format(x, style = "name")
  )
})


# Distance (time_chunk - time_chunk) --------------------------------------

test_that("distance sp27 - fa26 = 1L", {
  setup_semester()
  d <- time_chunk("sp27") - time_chunk("fa26")
  expect_equal(d, 1L)
})

test_that("distance su27 - fa26 = 2L", {
  setup_semester()
  d <- time_chunk("su27") - time_chunk("fa26")
  expect_equal(d, 2L)
})

test_that("distance fa27 - fa26 = 3L", {
  setup_semester()
  d <- time_chunk("fa27") - time_chunk("fa26")
  expect_equal(d, 3L)
})

test_that("distance is negative going backward", {
  setup_semester()
  d <- time_chunk("fa26") - time_chunk("sp27")
  expect_equal(d, -1L)
})

test_that("distance of identical period is 0L", {
  setup_semester()
  d <- time_chunk("fa26") - time_chunk("fa26")
  expect_equal(d, 0L)
})

test_that("distance errors on length mismatch", {
  setup_semester()
  x <- time_chunk(c("fa26", "sp27"))
  y <- time_chunk("su27")
  expect_error(x - y, class = "timechunks_arithmetic_error")
})

test_that("vectorized distance works", {
  setup_semester()
  x <- time_chunk(c("sp27", "su27"))
  y <- time_chunk(c("fa26", "fa26"))
  expect_equal(x - y, c(1L, 2L))
})


# seq.time_chunk ----------------------------------------------------------

test_that("seq generates correct 4-period sequence", {
  setup_semester()
  s <- seq(time_chunk("fa26"), time_chunk("fa27"), by = 1L)
  expect_length(s, 4L)
  expect_equal(chunk_name(s), c("Fall", "Spring", "Summer", "Fall"))
  expect_equal(chunk_year(s), c(2026L, 2027L, 2027L, 2027L))
})

test_that("seq with from == to returns length-1 vector", {
  setup_semester()
  s <- seq(time_chunk("fa26"), time_chunk("fa26"), by = 1L)
  expect_length(s, 1L)
  expect_equal(chunk_name(s), "Fall")
})

test_that("seq with by = 2L skips every other period", {
  setup_semester()
  s <- seq(time_chunk("fa26"), time_chunk("fa27"), by = 2L)
  expect_length(s, 2L)
  expect_equal(chunk_name(s), c("Fall", "Summer"))
})

test_that("seq with by = 3L (one full year step)", {
  setup_semester()
  s <- seq(time_chunk("fa26"), time_chunk("fa28"), by = 3L)
  expect_length(s, 3L)
  expect_equal(chunk_name(s), c("Fall", "Fall", "Fall"))
  expect_equal(chunk_year(s), c(2026L, 2027L, 2028L))
})

test_that("seq errors when direction and by sign mismatch", {
  setup_semester()
  expect_error(
    seq(time_chunk("fa27"), time_chunk("fa26"), by = 1L),
    class = "timechunks_arithmetic_error"
  )
})

test_that("seq errors when by = 0", {
  setup_semester()
  expect_error(
    seq(time_chunk("fa26"), time_chunk("fa27"), by = 0L),
    class = "timechunks_arithmetic_error"
  )
})

test_that("seq works with us_federal_fy (4-period calendar)", {
  use_chunk_preset("us_federal_fy")
  s <- seq(time_chunk("q126"), time_chunk("q127"), by = 1L)
  expect_length(s, 5L)
  expect_equal(chunk_name(s), c("Q1", "Q2", "Q3", "Q4", "Q1"))
  use_chunk_preset("us_semester")
})
