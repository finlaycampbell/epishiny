# Tests for time module helper functions from R/01_time.R

# Setup test data
source("fixtures/helpers-fixtures.R")

# Test get_time_df() -----------------------------------------------------------

test_that("get_time_df works for ungrouped linelist data", {
  df <- make_test_linelist(50)
  result <- get_time_df(
    df = df,
    is_agg = FALSE,
    is_grouped = FALSE,
    date_var = "date_onset",
    count_var = NULL,
    group_var = NULL,
    date_interval = "day"
  )

  expect_s3_class(result, "data.frame")
  expect_has_columns(result, c("date_onset", "n", "n_c"))
  expect_true(all(result$n >= 0))
  expect_true(all(result$n_c >= 0))
  # Cumulative should be monotonic increasing
  expect_true(all(diff(result$n_c) >= 0))
})

test_that("get_time_df handles empty data", {
  df <- make_test_linelist(0)
  result <- get_time_df(
    df = df,
    is_agg = FALSE,
    is_grouped = FALSE,
    date_var = "date_onset",
    count_var = NULL,
    group_var = NULL,
    date_interval = "day"
  )

  expect_s3_class(result, "data.frame")
  expect_has_columns(result, c("date_onset", "n", "n_c"))
})

test_that("get_time_df fills date gaps correctly", {
  df <- data.frame(
    date = as.Date(c("2024-01-01", "2024-01-05", "2024-01-10")),
    value = c(10, 15, 20)
  )

  result <- get_time_df(
    df = df,
    is_agg = FALSE,
    is_grouped = FALSE,
    date_var = "date",
    count_var = NULL,
    group_var = NULL,
    date_interval = "day"
  )

  # Should fill in missing dates with 0
  expect_equal(nrow(result), 10) # From 2024-01-01 to 2024-01-10
  # Days with no data should have n = 0
  expect_true(any(result$n == 0))
})

test_that("get_time_df works for grouped linelist data", {
  df <- make_test_linelist(50)
  result <- get_time_df(
    df = df,
    is_agg = FALSE,
    is_grouped = TRUE,
    date_var = "date",
    count_var = NULL,
    group_var = "region",
    date_interval = "day"
  )

  expect_s3_class(result, "data.frame")
  expect_has_columns(result, c("date", "region", "n", "n_c"))
  expect_true(all(result$n >= 0))
  # Check cumulative is correct for each group
  for (reg in unique(result$region)) {
    reg_data <- result[result$region == reg, ]
    expect_true(all(diff(reg_data$n_c) >= 0))
  }
})

test_that("get_time_df works for ungrouped aggregated data", {
  df <- data.frame(
    date = seq(as.Date("2024-01-01"), by = "day", length.out = 10),
    cases = sample(5:20, 10, replace = TRUE)
  )

  result <- get_time_df(
    df = df,
    is_agg = TRUE,
    is_grouped = FALSE,
    date_var = "date",
    count_var = "cases",
    group_var = NULL,
    date_interval = "day"
  )

  expect_s3_class(result, "data.frame")
  expect_has_columns(result, c("date", "n", "n_c"))
  expect_equal(sum(result$n), sum(df$cases))
})

test_that("get_time_df works for grouped aggregated data", {
  df <- expand.grid(
    date = seq(as.Date("2024-01-01"), by = "day", length.out = 5),
    region = c("A", "B")
  )
  df$cases <- sample(1:10, nrow(df), replace = TRUE)

  result <- get_time_df(
    df = df,
    is_agg = TRUE,
    is_grouped = TRUE,
    date_var = "date",
    count_var = "cases",
    group_var = "region",
    date_interval = "day"
  )

  expect_s3_class(result, "data.frame")
  expect_has_columns(result, c("date", "region", "n", "n_c"))
})

test_that("get_time_df errors when count_var missing for aggregated data", {
  df <- make_test_aggregated(10, 3)
  expect_error(
    get_time_df(
      df = df,
      is_agg = TRUE,
      is_grouped = FALSE,
      date_var = "date",
      count_var = NULL,
      group_var = NULL,
      date_interval = "day"
    ),
    "count_var"
  )
})

test_that("get_time_df handles week intervals", {
  # Create data with specific dates to test weekly aggregation
  df <- data.frame(
    date = seq(as.Date("2024-01-01"), by = "week", length.out = 5)
  )

  result <- get_time_df(
    df = df,
    is_agg = FALSE,
    is_grouped = FALSE,
    date_var = "date",
    count_var = NULL,
    group_var = NULL,
    date_interval = "week"
  )

  expect_s3_class(result, "data.frame")
  expect_has_columns(result, c("date", "n", "n_c"))
  # Should have data aggregated by week interval
  expect_true(nrow(result) >= 5)
  # Cumulative should be increasing
  expect_true(all(diff(result$n_c) >= 0))
})

# Test get_ratio_df() ----------------------------------------------------------

test_that("get_ratio_df calculates CFR from linelist correctly", {
  df <- data.frame(
    date = seq(as.Date("2024-01-01"), by = "day", length.out = 10),
    outcome = sample(c("Death", "Recovery"), 10, replace = TRUE, prob = c(0.2, 0.8))
  )

  result <- get_ratio_df(
    df = df,
    date_var = "date",
    is_agg = FALSE,
    ratio_var = "outcome",
    ratio_lab = "CFR",
    ratio_numer = "Death",
    ratio_denom = c("Death", "Recovery")
  )

  expect_s3_class(result, "data.frame")
  expect_has_columns(result, c("date", "ratio", "ratio_c"))
  # Ratio should be percentage
  expect_true(all(result$ratio >= 0 & result$ratio <= 100, na.rm = TRUE))
  expect_true(all(result$ratio_c >= 0 & result$ratio_c <= 100, na.rm = TRUE))
})

test_that("get_ratio_df cumulative ratio is monotonic with consistent outcomes", {
  # Create data where all outcomes are deaths, so cumulative CFR should stay at 100%
  df <- data.frame(
    date = seq(as.Date("2024-01-01"), by = "day", length.out = 10),
    outcome = rep("Death", 10)
  )

  result <- get_ratio_df(
    df = df,
    date_var = "date",
    is_agg = FALSE,
    ratio_var = "outcome",
    ratio_lab = "CFR",
    ratio_numer = "Death",
    ratio_denom = c("Death", "Recovery")
  )

  # All cumulative should be 100%
  expect_true(all(result$ratio_c == 100))
})

test_that("get_ratio_df works with aggregated data", {
  df <- data.frame(
    date = seq(as.Date("2024-01-01"), by = "day", length.out = 10),
    deaths = sample(1:5, 10, replace = TRUE),
    cases = sample(10:20, 10, replace = TRUE)
  )

  result <- get_ratio_df(
    df = df,
    date_var = "date",
    is_agg = TRUE,
    ratio_var = NULL,
    ratio_lab = "CFR",
    ratio_numer = "deaths",
    ratio_denom = "cases"
  )

  expect_s3_class(result, "data.frame")
  expect_has_columns(result, c("date", "ratio", "ratio_c"))
  expect_true(all(result$ratio >= 0, na.rm = TRUE))
})

test_that("get_ratio_df errors when missing required linelist params", {
  df <- make_test_linelist(50)
  expect_error(
    get_ratio_df(
      df = df,
      date_var = "date",
      is_agg = FALSE,
      ratio_var = NULL,
      ratio_lab = NULL,
      ratio_numer = NULL,
      ratio_denom = NULL
    ),
    "ratio_var"
  )
})

test_that("get_ratio_df errors when missing required aggregated params", {
  df <- make_test_aggregated(10, 2)
  expect_error(
    get_ratio_df(
      df = df,
      date_var = "date",
      is_agg = TRUE,
      ratio_var = NULL,
      ratio_lab = NULL,
      ratio_numer = NULL,
      ratio_denom = NULL
    ),
    "ratio_numer"
  )
})

# Test get_epi_week() and get_epi_year() ---------------------------------------

test_that("get_epi_week returns integer week numbers", {
  dates <- seq(as.Date("2024-01-01"), by = "week", length.out = 10)
  weeks <- get_epi_week(dates)

  # Returns double type, but values are integers
  expect_type(weeks, "double")
  expect_true(all(weeks >= 1 & weeks <= 53))
  expect_true(all(weeks == floor(weeks))) # All should be whole numbers
})

test_that("get_epi_year returns correct years", {
  dates <- as.Date(c("2024-01-01", "2024-12-31", "2025-01-01"))
  years <- get_epi_year(dates)

  expect_type(years, "double")
  expect_true(all(years %in% c(2024, 2025)))
})

test_that("get_epi_week handles week_start parameter", {
  date <- as.Date("2024-01-15")

  week_mon <- get_epi_week(date, week_start = 1) # Monday
  week_sun <- get_epi_week(date, week_start = 7) # Sunday

  # Both should be valid week numbers
  expect_true(week_mon >= 1 && week_mon <= 53)
  expect_true(week_sun >= 1 && week_sun <= 53)
})

# Test format_week() -----------------------------------------------------------

test_that("format_week returns correct format", {
  date <- as.Date("2024-03-15")
  formatted <- format_week(date)

  expect_type(formatted, "character")
  expect_epi_week_format(formatted)
})

test_that("format_week uses custom week letter option", {
  date <- as.Date("2024-03-15")
  withr::with_options(
    list(epishiny.week.letter = "S"),
    {
      formatted <- format_week(date)
      expect_match(formatted, "^\\d{4}-S\\d{1,2}$")
    }
  )
})

test_that("format_week respects week_start parameter", {
  date <- as.Date("2024-01-01")

  # Both should produce valid week formats
  fmt_mon <- format_week(date, week_start = 1)
  fmt_sun <- format_week(date, week_start = 7)

  expect_epi_week_format(fmt_mon)
  expect_epi_week_format(fmt_sun)
})

# Test get_plot_band_limits() --------------------------------------------------

test_that("get_plot_band_limits calculates correct padding for days", {
  tf <- list(
    interval = "day",
    from = as.Date("2024-01-15"),
    to = as.Date("2024-01-15")
  )

  limits <- get_plot_band_limits(tf)

  expect_named(limits, c("from", "to"))
  # Function returns POSIXct dates
  expect_true(inherits(limits$from, "POSIXct") || inherits(limits$from, "Date"))
  expect_true(inherits(limits$to, "POSIXct") || inherits(limits$to, "Date"))
  # Should pad by 12 hours (rounded to nearest day)
  expect_true(as.numeric(limits$to - limits$from) >= 0.5)
})

test_that("get_plot_band_limits calculates padding for weeks", {
  tf <- list(
    interval = "week",
    from = as.Date("2024-01-01"),
    to = as.Date("2024-01-07")
  )

  limits <- get_plot_band_limits(tf)

  expect_named(limits, c("from", "to"))
  # Function returns POSIXct dates
  expect_true(inherits(limits$from, "POSIXct") || inherits(limits$from, "Date"))
  expect_true(inherits(limits$to, "POSIXct") || inherits(limits$to, "Date"))
  # Should pad by half the interval
  expect_true(as.numeric(limits$to - limits$from) >= 2)
})

# Test format_period() ---------------------------------------------------------

test_that("format_period formats days correctly", {
  date <- as.Date("2024-03-15")
  result <- format_period(date, "day")

  expect_type(result, "character")
  expect_match(result, "Mar")
  expect_match(result, "2024")
})

test_that("format_period formats weeks correctly", {
  date <- as.Date("2024-03-15")
  result <- format_period(date, "week")

  expect_type(result, "character")
  expect_epi_week_format(result)
})

test_that("format_period formats months correctly", {
  date <- as.Date("2024-03-15")
  result <- format_period(date, "month")

  expect_type(result, "character")
  expect_match(result, "March 2024")
})

test_that("format_period formats years correctly", {
  date <- as.Date("2024-03-15")
  result <- format_period(date, "year")

  expect_type(result, "character")
  expect_equal(result, "2024")
})

test_that("format_period handles unknown intervals", {
  dates <- as.Date(c("2024-01-01", "2024-01-31"))
  result <- format_period(dates, "unknown")

  expect_type(result, "character")
  expect_match(result, "-")
})
