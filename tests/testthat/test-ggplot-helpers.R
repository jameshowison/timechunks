setup_semester <- function() use_chunk_preset("us_semester")

test_that("as_chunk_factor() returns an ordered factor", {
  setup_semester()
  x <- time_chunk(c("sp27", "fa26", "su27"))
  f <- as_chunk_factor(x, labels = "code")
  expect_s3_class(f, "factor")
  expect_true(is.ordered(f))
})

test_that("as_chunk_factor() levels are in chronological order", {
  setup_semester()
  x <- time_chunk(c("su27", "fa26", "sp27"))
  f <- as_chunk_factor(x, labels = "code")
  expect_equal(levels(f), c("fa26", "sp27", "su27"))
})

test_that("as_chunk_factor() values match input order", {
  setup_semester()
  x <- time_chunk(c("su27", "fa26", "sp27"))
  f <- as_chunk_factor(x, labels = "code")
  expect_equal(as.character(f), c("su27", "fa26", "sp27"))
})

test_that("as_chunk_factor() labels = 'name' produces name-year labels", {
  setup_semester()
  x <- time_chunk(c("fa26", "sp27"))
  f <- as_chunk_factor(x, labels = "name")
  expect_equal(levels(f), c("Fall 2026", "Spring 2027"))
})

test_that("as_chunk_factor() labels = 'ay' is allowed (may repeat)", {
  setup_semester()
  x <- time_chunk(c("fa26", "sp27", "su27"))
  f <- as_chunk_factor(x, labels = "ay")
  # All three periods have the same ay, so only one unique level
  expect_length(levels(f), 1L)
  expect_equal(levels(f), "2026-27")
})

test_that("as_chunk_factor() preserves NA values", {
  setup_semester()
  x <- time_chunk(c("fa26", NA_character_, "sp27"))
  f <- as_chunk_factor(x, labels = "code")
  expect_true(is.na(f[2L]))
  expect_equal(as.character(f[1L]), "fa26")
  expect_equal(as.character(f[3L]), "sp27")
})

test_that("as_chunk_factor() returns empty ordered factor for length-0 input", {
  setup_semester()
  x <- new_time_chunk()
  f <- as_chunk_factor(x)
  expect_length(f, 0L)
  expect_true(is.ordered(f))
})

test_that("as_chunk_factor() works with glue template labels", {
  setup_semester()
  x <- time_chunk(c("fa26", "sp27"))
  f <- as_chunk_factor(x, labels = "{name} ({ay})")
  expect_equal(levels(f), c("Fall (2026-27)", "Spring (2026-27)"))
})

test_that("as_chunk_factor() errors on non-time_chunk input", {
  setup_semester()
  expect_error(as_chunk_factor("fa26"), class = "timechunks_type_error")
})

test_that("as_chunk_factor() works correctly in dplyr::mutate()", {
  skip_if_not_installed("dplyr")
  setup_semester()
  df <- data.frame(
    sem = c("su27", "fa26", "sp27"),
    n   = c(150L, 100L, 200L),
    stringsAsFactors = FALSE
  ) |>
    dplyr::mutate(
      sem_tc  = time_chunk(sem),
      sem_fct = as_chunk_factor(sem_tc, labels = "code")
    )
  expect_true(is.ordered(df$sem_fct))
  expect_equal(levels(df$sem_fct), c("fa26", "sp27", "su27"))
})

test_that("as_chunk_factor() works correctly before group_by() (not inside grouped mutate)", {
  # Regression: calling as_chunk_factor() inside a grouped mutate() caused a
  # vctrs incompatible combine error because dplyr processes each group
  # separately and then tries to combine factors with differing levels.
  # The fix is to call as_chunk_factor() before group_by().
  skip_if_not_installed("dplyr")
  use_chunk_preset("us_federal_fy")
  df <- data.frame(
    quarter   = time_chunk(c("q126", "q227", "q327", "q427",
                              "q127", "q228", "q328", "q428")),
    obligated = c(12.4, 18.1, 22.7, 9.8, 14.2, 19.5, 24.1, 11.3)
  )
  result <- df |>
    dplyr::arrange(quarter) |>
    dplyr::mutate(quarter_fct = as_chunk_factor(quarter, labels = "code")) |>
    dplyr::group_by(ay = chunk_ay(quarter)) |>
    dplyr::mutate(cumulative = cumsum(obligated)) |>
    dplyr::ungroup()
  expect_true(is.ordered(result$quarter_fct))
  expect_equal(nrow(result), 8L)
  expect_equal(levels(result$quarter_fct), c("q126", "q227", "q327", "q427",
                                              "q127", "q228", "q328", "q428"))
})
