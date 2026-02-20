setup_semester <- function() use_chunk_preset("us_semester")

test_that("rollup_to_ay() sums correctly across two academic years", {
  setup_semester()
  df <- data.frame(
    semester   = time_chunk(c("fa26", "sp27", "su27", "fa27", "sp28")),
    enrollment = c(8200L, 7100L, 3400L, 8500L, 7300L)
  )
  result <- rollup_to_ay(df, value_col = "enrollment", chunk_col = "semester")
  expect_equal(nrow(result), 2L)
  expect_equal(result$ay,         c("2026-27", "2027-28"))
  expect_equal(result$enrollment, c(18700L, 15800L))
})

test_that("rollup_to_ay() rows are sorted chronologically", {
  setup_semester()
  # Insert rows out of order
  df <- data.frame(
    semester   = time_chunk(c("fa27", "fa26", "sp27")),
    enrollment = c(8500L, 8200L, 7100L)
  )
  result <- rollup_to_ay(df, value_col = "enrollment", chunk_col = "semester")
  expect_equal(result$ay[1L], "2026-27")
  expect_equal(result$ay[2L], "2027-28")
})

test_that("rollup_to_ay() default chunk_col is 'semester'", {
  setup_semester()
  df <- data.frame(
    semester   = time_chunk(c("fa26", "sp27")),
    enrollment = c(8200L, 7100L)
  )
  result <- rollup_to_ay(df, value_col = "enrollment")
  expect_equal(nrow(result), 1L)
  expect_equal(result$ay, "2026-27")
})

test_that("rollup_to_ay() fn = mean computes means", {
  setup_semester()
  df <- data.frame(
    semester   = time_chunk(c("fa26", "sp27", "su27")),
    enrollment = c(9000L, 6000L, 3000L)
  )
  result <- rollup_to_ay(df, value_col = "enrollment", fn = mean)
  expect_equal(result$enrollment, 6000)
})

test_that("rollup_to_ay() fn = max computes max", {
  setup_semester()
  df <- data.frame(
    semester   = time_chunk(c("fa26", "sp27", "su27")),
    enrollment = c(9000L, 6000L, 3000L)
  )
  result <- rollup_to_ay(df, "enrollment", fn = max)
  expect_equal(result$enrollment, 9000L)
})

test_that("rollup_to_ay() single AY returns one row", {
  setup_semester()
  df <- data.frame(
    semester   = time_chunk(c("fa26", "sp27", "su27")),
    enrollment = c(8200L, 7100L, 3400L)
  )
  result <- rollup_to_ay(df, "enrollment", "semester")
  expect_equal(nrow(result), 1L)
  expect_equal(result$enrollment, 18700L)
})

test_that("rollup_to_ay() handles NA values with na.rm = TRUE", {
  setup_semester()
  df <- data.frame(
    semester   = time_chunk(c("fa26", "sp27")),
    enrollment = c(NA_integer_, 7100L)
  )
  result <- rollup_to_ay(df, "enrollment", na.rm = TRUE)
  expect_equal(result$enrollment, 7100L)
})

test_that("rollup_to_ay() errors on non-data-frame input", {
  setup_semester()
  expect_error(
    rollup_to_ay(list(a = 1), "a"),
    class = "timechunks_rollup_error"
  )
})

test_that("rollup_to_ay() errors on missing value_col", {
  setup_semester()
  df <- data.frame(semester = time_chunk("fa26"), n = 1L)
  expect_error(
    rollup_to_ay(df, "nonexistent"),
    class = "timechunks_rollup_error"
  )
})

test_that("rollup_to_ay() errors on missing chunk_col", {
  setup_semester()
  df <- data.frame(semester = time_chunk("fa26"), n = 1L)
  expect_error(
    rollup_to_ay(df, "n", chunk_col = "nonexistent"),
    class = "timechunks_rollup_error"
  )
})

test_that("rollup_to_ay() errors when chunk_col is not a time_chunk", {
  setup_semester()
  df <- data.frame(semester = "fa26", n = 1L, stringsAsFactors = FALSE)
  expect_error(
    rollup_to_ay(df, "n", "semester"),
    class = "timechunks_rollup_error"
  )
})
