setup_semester <- function() use_chunk_preset("us_semester")

test_that("sort() sorts chronologically via vec_proxy_compare", {
  setup_semester()
  x <- time_chunk(c("sp27", "fa26", "su27"))
  s <- sort(x)
  expect_equal(chunk_name(s), c("Fall", "Spring", "Summer"))
})

test_that("vec_ptype_abbr returns 'tchk'", {
  setup_semester()
  x <- time_chunk("fa26")
  expect_equal(vctrs::vec_ptype_abbr(x), "tchk")
})

test_that("vec_ptype_full returns 'time_chunk'", {
  setup_semester()
  x <- time_chunk("fa26")
  expect_equal(vctrs::vec_ptype_full(x), "time_chunk")
})

test_that("dplyr::mutate() preserves time_chunk class", {
  skip_if_not_installed("dplyr")
  setup_semester()
  df <- data.frame(
    raw = c("fa26", "sp27", "su27"),
    n   = c(100L, 200L, 150L),
    stringsAsFactors = FALSE
  )
  df2 <- dplyr::mutate(df, sem = time_chunk(raw))
  expect_s3_class(df2$sem, "time_chunk")
  expect_equal(chunk_name(df2$sem), c("Fall", "Spring", "Summer"))
})

test_that("tidyr::pivot_longer() preserves time_chunk", {
  skip_if_not_installed("tidyr")
  skip_if_not_installed("dplyr")
  setup_semester()
  df <- data.frame(
    id  = 1L,
    fa  = "fa26",
    sp  = "sp27",
    stringsAsFactors = FALSE
  )
  df_long <- tidyr::pivot_longer(df, cols = c(fa, sp), values_to = "raw") |>
    dplyr::mutate(sem = time_chunk(raw))
  expect_s3_class(df_long$sem, "time_chunk")
  expect_length(df_long$sem, 2L)
})

test_that("vec_cast time_chunk -> character uses 'code' style", {
  setup_semester()
  x <- time_chunk("fa26")
  result <- vctrs::vec_cast(x, character())
  expect_equal(result, "fa26")
})

test_that("vec_cast character -> time_chunk parses correctly", {
  setup_semester()
  result <- vctrs::vec_cast("fa26", new_time_chunk())
  expect_s3_class(result, "time_chunk")
  expect_equal(chunk_name(result), "Fall")
})

test_that("vec_cast time_chunk -> Date returns start_date", {
  setup_semester()
  x <- time_chunk("fa26")
  result <- vctrs::vec_cast(x, as.Date(NA))
  expect_equal(result, as.Date("2026-08-23"))
})
