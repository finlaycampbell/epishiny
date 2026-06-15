# ==============================================================================
# TEST: TIME MODULE SERVER FUNCTION
# Tests reactive behavior of time_server() using shiny::testServer()
# ==============================================================================

# Test basic module initialization -----------------------------------------

test_that("time_server initializes with linelist data", {
  df_test <- make_test_linelist(100)

  testServer(
    time_server,
    args = list(
      df = df_test,
      date_vars = c("Date" = "date"),
      count_vars = NULL,
      group_vars = NULL
    ),
    {
      # Module should initialize
      expect_true(TRUE)
    }
  )
})

test_that("time_server initializes with aggregated data", {
  df_agg <- data.frame(
    date = seq(as.Date("2024-01-01"), by = "day", length.out = 30),
    cases = sample(5:20, 30, replace = TRUE)
  )

  testServer(
    time_server,
    args = list(
      df = df_agg,
      date_vars = c("Date" = "date"),
      count_vars = c("Cases" = "cases"),
      group_vars = NULL
    ),
    {
      expect_true(TRUE)
    }
  )
})

# Test reactive data processing --------------------------------------------

test_that("df_mod reactive responds to place_filter", {
  df_test <- make_test_linelist(100)

  testServer(
    time_server,
    args = list(
      df = df_test,
      date_vars = c("Date" = "date"),
      count_vars = NULL,
      place_filter = reactive({
        list(geo_col = "region", region_select = "Region1")
      })
    ),
    {
      # Get filtered data
      df_filtered <- df_mod()

      # Should only contain Region1
      expect_true(all(df_filtered$region == "Region1"))
      expect_lt(nrow(df_filtered), 100)
    }
  )
})

test_that("df_curve reactive creates time aggregation", {
  df_test <- make_test_linelist(50)

  testServer(
    time_server,
    args = list(
      df = df_test,
      date_vars = c("Date" = "date"),
      count_vars = NULL,
      group_vars = NULL
    ),
    {
      # Set inputs
      session$setInputs(
        date = "date",
        date_interval = "day",
        count_var = NULL,
        group = "n",
        cumulative = FALSE,
        bar_stacking = "normal",
        show_ratio_line = FALSE,
        add_zoom_control = FALSE
      )

      # Get curve data
      df <- df_curve()

      # Should have required columns
      expect_s3_class(df, "data.frame")
      expect_has_columns(df, c("date", "n", "n_c"))

      # Cumulative should be monotonic
      expect_true(all(diff(df$n_c) >= 0))
    }
  )
})

# Test date interval changes -----------------------------------------------

test_that("date_interval input changes aggregation", {
  df_test <- make_test_linelist(100)

  testServer(
    time_server,
    args = list(
      df = df_test,
      date_vars = c("Date" = "date"),
      count_vars = NULL
    ),
    {
      # Set to day interval
      session$setInputs(
        date = "date",
        date_interval = "day",
        count_var = NULL,
        group = "n"
      )
      df_day <- df_curve()
      n_days <- nrow(df_day)

      # Set to week interval
      session$setInputs(date_interval = "week")
      df_week <- df_curve()
      n_weeks <- nrow(df_week)

      # Week aggregation should have fewer rows than day
      expect_lt(n_weeks, n_days)
    }
  )
})

test_that("month interval aggregation works", {
  df_test <- data.frame(
    date = seq(as.Date("2024-01-01"), by = "day", length.out = 90)
  )

  testServer(
    time_server,
    args = list(
      df = df_test,
      date_vars = c("Date" = "date"),
      count_vars = NULL
    ),
    {
      session$setInputs(
        date = "date",
        date_interval = "month",
        count_var = NULL,
        group = "n"
      )

      df <- df_curve()

      # 90 days should aggregate to ~3 months
      expect_lte(nrow(df), 4)
      expect_gte(nrow(df), 2)
    }
  )
})

# Test grouping functionality ----------------------------------------------

test_that("grouping by variable works with linelist data", {
  df_test <- make_test_linelist(100)

  testServer(
    time_server,
    args = list(
      df = df_test,
      date_vars = c("Date" = "date"),
      count_vars = NULL,
      group_vars = c("Region" = "region")
    ),
    {
      # Set inputs with grouping
      session$setInputs(
        date = "date",
        date_interval = "week",
        count_var = NULL,
        group = "region"
      )

      df <- df_curve()

      # Should have region column
      expect_true("region" %in% names(df))

      # Should have multiple regions
      expect_gt(length(unique(df$region)), 1)
    }
  )
})

test_that("switching between grouped and ungrouped works", {
  df_test <- make_test_linelist(100)

  testServer(
    time_server,
    args = list(
      df = df_test,
      date_vars = c("Date" = "date"),
      count_vars = NULL,
      group_vars = c("Region" = "region")
    ),
    {
      # Start ungrouped
      session$setInputs(
        date = "date",
        date_interval = "week",
        count_var = NULL,
        group = "n"
      )
      df_ungrouped <- df_curve()

      # Switch to grouped
      session$setInputs(group = "region")
      df_grouped <- df_curve()

      # Grouped should have more rows (one per date per region)
      expect_gte(nrow(df_grouped), nrow(df_ungrouped))

      # Ungrouped should not have region column
      expect_false("region" %in% names(df_ungrouped))

      # Grouped should have region column
      expect_true("region" %in% names(df_grouped))
    }
  )
})

# Test cumulative calculation ----------------------------------------------

test_that("cumulative flag produces cumulative counts", {
  df_test <- make_test_linelist(50)

  testServer(
    time_server,
    args = list(
      df = df_test,
      date_vars = c("Date" = "date"),
      count_vars = NULL
    ),
    {
      session$setInputs(
        date = "date",
        date_interval = "day",
        count_var = NULL,
        group = "n",
        cumulative = FALSE
      )

      df <- df_curve()

      # n_c should be cumulative
      expect_equal(df$n_c, cumsum(df$n))

      # n_c should be monotonically increasing
      expect_true(all(diff(df$n_c) >= 0))
    }
  )
})

# Test ratio line calculation ----------------------------------------------

test_that("ratio line calculation works with linelist data", {
  df_test <- make_test_linelist(100)
  # Add outcome variable for ratio
  df_test$outcome <- sample(c("Death", "Recovery"), 100, replace = TRUE, prob = c(0.2, 0.8))

  testServer(
    time_server,
    args = list(
      df = df_test,
      date_vars = c("Date" = "date"),
      count_vars = NULL,
      show_ratio = TRUE,
      ratio_var = "outcome",
      ratio_lab = "CFR",
      ratio_numer = "Death",
      ratio_denom = c("Death", "Recovery")
    ),
    {
      session$setInputs(
        date = "date",
        date_interval = "week",
        count_var = NULL,
        group = "n",
        show_ratio_line = TRUE
      )

      df <- df_curve()

      # Should have ratio columns
      expect_has_columns(df, c("ratio", "ratio_c"))

      # Ratio should be between 0 and 100 (%)
      expect_true(all(df$ratio >= 0 & df$ratio <= 100, na.rm = TRUE))
      expect_true(all(df$ratio_c >= 0 & df$ratio_c <= 100, na.rm = TRUE))
    }
  )
})

test_that("ratio line calculation works with aggregated data", {
  df_agg <- data.frame(
    date = seq(as.Date("2024-01-01"), by = "week", length.out = 20),
    cases = sample(10:50, 20, replace = TRUE),
    deaths = sample(1:10, 20, replace = TRUE)
  )

  testServer(
    time_server,
    args = list(
      df = df_agg,
      date_vars = c("Date" = "date"),
      count_vars = c("Cases" = "cases"),
      show_ratio = TRUE,
      ratio_numer = "deaths",
      ratio_denom = "cases",
      ratio_lab = "CFR"
    ),
    {
      session$setInputs(
        date = "date",
        date_interval = "week",
        count_var = "cases",
        group = "n",
        show_ratio_line = TRUE
      )

      df <- df_curve()

      # Should have ratio columns
      expect_has_columns(df, c("ratio", "ratio_c"))

      # Ratio should be reasonable (deaths <= cases)
      expect_true(all(df$ratio >= 0 & df$ratio <= 100, na.rm = TRUE))
    }
  )
})

# Test filter_info reactive ------------------------------------------------

test_that("filter_info_out reactive formats filter info", {
  df_test <- make_test_linelist(100)

  testServer(
    time_server,
    args = list(
      df = df_test,
      date_vars = c("Date" = "date"),
      filter_info = reactive("<b>Filters applied</b></br>Period: 2024-01-01 - 2024-01-31")
    ),
    {
      fi <- filter_info_out()

      # Should return the filter info
      expect_type(fi, "character")
      expect_match(fi, "Filters applied")
    }
  )
})

test_that("filter_info_out combines place filter info", {
  df_test <- make_test_linelist(100)

  testServer(
    time_server,
    args = list(
      df = df_test,
      date_vars = c("Date" = "date"),
      filter_info = reactive("<b>Filters applied</b></br>Period: 2024-01-01 - 2024-01-31"),
      place_filter = reactive({
        list(
          geo_col = "region",
          region_select = "Region1",
          level_name = "Region",
          region_name = "Region1"
        )
      })
    ),
    {
      fi <- filter_info_out()

      # Should include both period and place info
      expect_match(fi, "Period")
      expect_match(fi, "Region")
      expect_match(fi, "Region1")
    }
  )
})

# Test multiple date variables ---------------------------------------------

test_that("multiple date variables can be selected", {
  df_test <- make_test_linelist(100)
  df_test$date_onset <- df_test$date - sample(1:5, 100, replace = TRUE)

  testServer(
    time_server,
    args = list(
      df = df_test,
      date_vars = c("Report Date" = "date", "Onset Date" = "date_onset"),
      count_vars = NULL
    ),
    {
      # Test with first date
      session$setInputs(
        date = "date",
        date_interval = "week",
        count_var = NULL,
        group = "n"
      )
      df1 <- df_curve()

      # Test with second date
      session$setInputs(date = "date_onset")
      df2 <- df_curve()

      # Both should work
      expect_s3_class(df1, "data.frame")
      expect_s3_class(df2, "data.frame")

      # Counts might differ due to different date distributions
      expect_true(sum(df1$n) >= 0)
      expect_true(sum(df2$n) >= 0)
    }
  )
})

# Test multiple count variables --------------------------------------------

test_that("multiple count variables can be selected with aggregated data", {
  df_agg <- data.frame(
    date = seq(as.Date("2024-01-01"), by = "week", length.out = 20),
    cases = sample(10:50, 20, replace = TRUE),
    hospitalizations = sample(5:20, 20, replace = TRUE),
    deaths = sample(1:10, 20, replace = TRUE)
  )

  testServer(
    time_server,
    args = list(
      df = df_agg,
      date_vars = c("Date" = "date"),
      count_vars = c("Cases" = "cases", "Hospitalizations" = "hospitalizations", "Deaths" = "deaths")
    ),
    {
      # Test with cases
      session$setInputs(
        date = "date",
        date_interval = "week",
        count_var = "cases",
        group = "n"
      )
      df_cases <- df_curve()

      # Test with deaths
      session$setInputs(count_var = "deaths")
      df_deaths <- df_curve()

      # Both should work
      expect_s3_class(df_cases, "data.frame")
      expect_s3_class(df_deaths, "data.frame")

      # Counts should differ
      expect_false(identical(sum(df_cases$n), sum(df_deaths$n)))
    }
  )
})

# Test edge cases ----------------------------------------------------------

test_that("time_server handles empty data gracefully", {
  df_empty <- make_test_linelist(0)

  testServer(
    time_server,
    args = list(
      df = df_empty,
      date_vars = c("Date" = "date"),
      count_vars = NULL
    ),
    {
      session$setInputs(
        date = "date",
        date_interval = "day",
        count_var = NULL,
        group = "n"
      )

      # Should not error, should return empty data frame
      df <- df_curve()
      expect_s3_class(df, "data.frame")
      expect_equal(nrow(df), 0)
    }
  )
})

test_that("time_server handles all NA dates", {
  df_test <- make_test_linelist(50)
  df_test$date <- NA

  testServer(
    time_server,
    args = list(
      df = df_test,
      date_vars = c("Date" = "date"),
      count_vars = NULL
    ),
    {
      session$setInputs(
        date = "date",
        date_interval = "day",
        count_var = NULL,
        group = "n"
      )

      # Should handle gracefully
      df <- df_curve()
      expect_s3_class(df, "data.frame")
    }
  )
})

test_that("time_server handles single date observation", {
  df_test <- make_test_linelist(1)

  testServer(
    time_server,
    args = list(
      df = df_test,
      date_vars = c("Date" = "date"),
      count_vars = NULL
    ),
    {
      session$setInputs(
        date = "date",
        date_interval = "day",
        count_var = NULL,
        group = "n"
      )

      df <- df_curve()
      expect_s3_class(df, "data.frame")
      expect_equal(nrow(df), 1)
      expect_equal(df$n, 1)
      expect_equal(df$n_c, 1)
    }
  )
})
