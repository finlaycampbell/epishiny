# ==============================================================================
# TEST: FILTER MODULE SERVER FUNCTION
# Tests reactive behavior of filter_server() using shiny::testServer()
# ==============================================================================

# Test basic module initialization -----------------------------------------

test_that("filter_server initializes with single date variable", {
  df_test <- make_test_linelist(100)

  testServer(
    filter_server,
    args = list(
      id = "filter",
      df = df_test,
      date_vars = c("Date" = "date"),
      group_vars = NULL
    ),
    {
      # Module should initialize
      expect_true(TRUE)

      # Should return a list with reactive functions
      returned <- session$getReturned()
      expect_type(returned, "list")
      expect_true("df" %in% names(returned))
      expect_true("filter_info" %in% names(returned))
      expect_true("filter_reset" %in% names(returned))

      # Each should be a reactive function
      expect_true(shiny::is.reactive(returned$df))
      expect_true(shiny::is.reactive(returned$filter_info))
    }
  )
})

test_that("filter_server initializes with multiple date variables", {
  df_test <- make_test_linelist(100)
  df_test$date_onset <- df_test$date - sample(1:5, 100, replace = TRUE)

  testServer(
    filter_server,
    args = list(
      id = "filter",
      df = df_test,
      date_vars = c("Report Date" = "date", "Onset Date" = "date_onset"),
      group_vars = NULL
    ),
    {
      expect_true(TRUE)
    }
  )
})

test_that("filter_server initializes with group variables", {
  df_test <- make_test_linelist(100)

  testServer(
    filter_server,
    args = list(
      id = "filter",
      df = df_test,
      date_vars = c("Date" = "date"),
      group_vars = c("Region" = "region", "Outcome" = "outcome")
    ),
    {
      expect_true(TRUE)
    }
  )
})

# Test single date filtering -----------------------------------------------

test_that("single date filter works correctly", {
  df_test <- make_test_linelist(100)
  date_range <- range(df_test$date)

  testServer(
    filter_server,
    args = list(
      id = "filter",
      df = df_test,
      date_vars = c("Date" = "date"),
      group_vars = NULL
    ),
    {
      # Set date filter
      session$setInputs(
        date = c(date_range[1], date_range[1] + 10)
      )

      # Click filter button
      session$setInputs(go = 1)

      # Get filtered data - returned list contains reactive functions
      returned_list <- session$getReturned()
      df_filtered <- returned_list$df()

      # Should be filtered to 10 day range
      expect_lt(nrow(df_filtered), 100)
      expect_true(all(df_filtered$date >= date_range[1]))
      expect_true(all(df_filtered$date <= date_range[1] + 10))
    }
  )
})

test_that("single date filter handles same start and end date", {
  df_test <- make_test_linelist(100)
  single_date <- df_test$date[50]

  testServer(
    filter_server,
    args = list(
      id = "filter",
      df = df_test,
      date_vars = c("Date" = "date"),
      group_vars = NULL
    ),
    {
      # Set same date for start and end
      session$setInputs(date = c(single_date, single_date))

      # Click filter button
      session$setInputs(go = 1)

      # Get filtered data
      returned_list <- session$getReturned()
      df_filtered <- returned_list$df()

      # Should only have that single date
      expect_true(all(df_filtered$date == single_date))
      expect_gt(nrow(df_filtered), 0)
    }
  )
})

# Test multiple date filtering with AND logic ------------------------------

test_that("multiple date filters use AND logic when both enabled", {
  df_test <- make_test_linelist(100)
  df_test$date_onset <- df_test$date - sample(1:5, 100, replace = TRUE)
  date_range1 <- range(df_test$date)
  date_range2 <- range(df_test$date_onset)

  testServer(
    filter_server,
    args = list(
      id = "filter",
      df = df_test,
      date_vars = c("Report" = "date", "Onset" = "date_onset"),
      group_vars = NULL
    ),
    {
      # Enable both date filters
      session$setInputs(
        date_enabled = TRUE,
        date = c(date_range1[1], date_range1[1] + 10),
        date_onset_enabled = TRUE,
        date_onset = c(date_range2[1], date_range2[1] + 10)
      )

      # Click filter button
      session$setInputs(go = 1)

      # Get filtered data
      returned_list <- session$getReturned()
      df_filtered <- returned_list$df()

      # Should satisfy both conditions
      expect_true(all(df_filtered$date >= date_range1[1] & df_filtered$date <= date_range1[1] + 10))
      expect_true(all(df_filtered$date_onset >= date_range2[1] & df_filtered$date_onset <= date_range2[1] + 10))
    }
  )
})

test_that("multiple date filters work with one disabled", {
  df_test <- make_test_linelist(100)
  df_test$date_onset <- df_test$date - sample(1:5, 100, replace = TRUE)
  date_range <- range(df_test$date)

  testServer(
    filter_server,
    args = list(
      id = "filter",
      df = df_test,
      date_vars = c("Report" = "date", "Onset" = "date_onset"),
      group_vars = NULL
    ),
    {
      # Enable only first date filter
      session$setInputs(
        date_enabled = TRUE,
        date = c(date_range[1], date_range[1] + 10),
        date_onset_enabled = FALSE
      )

      # Click filter button
      session$setInputs(go = 1)

      # Get filtered data
      returned_list <- session$getReturned()
      df_filtered <- returned_list$df()

      # Should only filter by enabled date
      expect_true(all(df_filtered$date >= date_range[1] & df_filtered$date <= date_range[1] + 10))
      # onset should not be filtered
      expect_lt(nrow(df_filtered), 100)
    }
  )
})

test_that("multiple date filters return all data when both disabled", {
  df_test <- make_test_linelist(100)
  df_test$date_onset <- df_test$date - sample(1:5, 100, replace = TRUE)

  testServer(
    filter_server,
    args = list(
      id = "filter",
      df = df_test,
      date_vars = c("Report" = "date", "Onset" = "date_onset"),
      group_vars = NULL
    ),
    {
      # Disable both date filters
      session$setInputs(
        date_enabled = FALSE,
        date_onset_enabled = FALSE
      )

      # Click filter button
      session$setInputs(go = 1)

      # Get filtered data
      returned_list <- session$getReturned()
      df_filtered <- returned_list$df()

      # Should return all data
      expect_equal(nrow(df_filtered), 100)
    }
  )
})

# Test group filtering integration -----------------------------------------
# Note: Detailed group filtering logic is tested in test-select-group-server.R
# These tests verify that filter_server properly integrates with select_group_server

test_that("filter_server integrates with group filtering", {
  df_test <- make_test_linelist(100)

  testServer(
    filter_server,
    args = list(
      id = "filter",
      df = df_test,
      date_vars = c("Date" = "date"),
      group_vars = c("Region" = "region")
    ),
    {
      # Group filtering is handled by the select_group submodule
      # Inputs are namespaced as "group-filters-{varname}"
      session$setInputs(`group-filters-region` = "Region1")

      # Click filter button
      session$setInputs(go = 1)

      # Get filtered data
      returned_list <- session$getReturned()
      df_filtered <- returned_list$df()

      # Should be filtered by group
      expect_true(all(df_filtered$region == "Region1"))
      expect_lt(nrow(df_filtered), 100)
    }
  )
})

# Test combined date and group filtering ----------------------------------

test_that("combined date and group filters work together", {
  df_test <- make_test_linelist(100)
  date_range <- range(df_test$date)

  testServer(
    filter_server,
    args = list(
      id = "filter",
      df = df_test,
      date_vars = c("Date" = "date"),
      group_vars = c("Region" = "region")
    ),
    {
      # Set both filters (group filter uses namespaced input)
      session$setInputs(
        date = c(date_range[1], date_range[1] + 10),
        `group-filters-region` = "Region1"
      )

      # Click filter button
      session$setInputs(go = 1)

      # Get filtered data
      returned_list <- session$getReturned()
      df_filtered <- returned_list$df()

      # Should satisfy both conditions
      expect_true(all(df_filtered$date >= date_range[1] & df_filtered$date <= date_range[1] + 10))
      expect_true(all(df_filtered$region == "Region1"))
      expect_lt(nrow(df_filtered), 100)
    }
  )
})

# Test filter reset functionality ------------------------------------------
# Note: Reset functionality is currently commented out in filter_server
# This test is kept for when/if reset functionality is re-enabled

# test_that("filter reset clears all filters", {
#   df_test <- make_test_linelist(100)
#   date_range <- range(df_test$date)
#
#   testServer(
#     filter_server,
#     args = list(
#       id = "filter",
#       df = df_test,
#       date_vars = c("Date" = "date"),
#       group_vars = c("Region" = "region")
#     ),
#     {
#       # Set filters
#       session$setInputs(
#         date = c(date_range[1], date_range[1] + 10),
#         `group-filters-region` = "Region1"
#       )
#
#       # Click filter button
#       session$setInputs(go = 1)
#
#       # Get filtered data
#       returned_list <- session$getReturned()
#       df_filtered1 <- returned_list$df()
#       expect_lt(nrow(df_filtered1), 100)
#
#       # Click reset button
#       session$setInputs(reset = 1)
#
#       # Get data again
#       df_filtered2 <- returned_list$df()
#
#       # Should return all data after reset
#       expect_equal(nrow(df_filtered2), 100)
#     }
#   )
# })

# Test filter info text generation -----------------------------------------

test_that("filter_info shows date range for single date", {
  df_test <- make_test_linelist(100)
  date_range <- range(df_test$date)

  testServer(
    filter_server,
    args = list(
      id = "filter",
      df = df_test,
      date_vars = c("Date" = "date"),
      group_vars = NULL
    ),
    {
      # Set date filter
      session$setInputs(date = c(date_range[1], date_range[1] + 10))

      # Click filter button
      session$setInputs(go = 1)

      # Get filter info
      returned_list <- session$getReturned()
      fi <- returned_list$filter_info()

      # Should contain filter info
      expect_type(fi, "character")
      expect_match(fi, "Filters applied")
    }
  )
})

test_that("filter_info is NULL when no filters applied", {
  df_test <- make_test_linelist(100)

  testServer(
    filter_server,
    args = list(
      id = "filter",
      df = df_test,
      date_vars = c("Date" = "date"),
      group_vars = NULL
    ),
    {
      # Don't set any filters, just click go
      session$setInputs(go = 1)

      # Get filter info
      returned_list <- session$getReturned()
      fi <- returned_list$filter_info()

      # Should be NULL or empty
      expect_true(is.null(fi) || length(fi) == 0 || fi == "")
    }
  )
})

# Test edge cases ----------------------------------------------------------

test_that("filter_server handles empty data", {
  # Create empty data frame with proper structure
  df_empty <- data.frame(
    date = as.Date(character(0)),
    region = character(0),
    stringsAsFactors = FALSE
  )

  testServer(
    filter_server,
    args = list(
      id = "filter",
      df = df_empty,
      date_vars = c("Date" = "date"),
      group_vars = NULL
    ),
    {
      session$setInputs(go = 1)

      # Should not error
      returned_list <- session$getReturned()
      df <- returned_list$df()
      expect_s3_class(df, "data.frame")
      expect_equal(nrow(df), 0)
    }
  )
})

test_that("filter_server handles all dates filtered out", {
  df_test <- make_test_linelist(100)
  future_date <- max(df_test$date) + 100

  testServer(
    filter_server,
    args = list(
      id = "filter",
      df = df_test,
      date_vars = c("Date" = "date"),
      group_vars = NULL
    ),
    {
      # Set date range that excludes all data
      session$setInputs(date = c(future_date, future_date + 10))

      # Click filter button
      session$setInputs(go = 1)

      # Get filtered data
      returned_list <- session$getReturned()
      df_filtered <- returned_list$df()

      # Should return empty data frame
      expect_equal(nrow(df_filtered), 0)
    }
  )
})

test_that("filter_server handles NA dates correctly", {
  df_test <- make_test_linelist(100)
  df_test$date[1:10] <- NA
  date_range <- range(df_test$date, na.rm = TRUE)

  testServer(
    filter_server,
    args = list(
      id = "filter",
      df = df_test,
      date_vars = c("Date" = "date"),
      group_vars = NULL
    ),
    {
      # Set date filter
      session$setInputs(date = c(date_range[1], date_range[1] + 10))

      # Click filter button
      session$setInputs(go = 1)

      # Get filtered data
      returned_list <- session$getReturned()
      df_filtered <- returned_list$df()

      # NA dates should be excluded
      expect_false(any(is.na(df_filtered$date)))
    }
  )
})

test_that("filter_server converts NA in group variables to factor levels", {
  df_test <- make_test_linelist(100)
  df_test$region[1:10] <- NA

  testServer(
    filter_server,
    args = list(
      id = "filter",
      df = df_test,
      date_vars = c("Date" = "date"),
      group_vars = c("Region" = "region")
    ),
    {
      # Click filter button to trigger data processing
      session$setInputs(go = 1)

      # Get filtered data
      returned_list <- session$getReturned()
      df_filtered <- returned_list$df()

      # NA values should be converted to "(Missing)" factor level
      missing_label <- getOption("epishiny.na.label", "(Missing)")
      expect_true(missing_label %in% levels(df_filtered$region))
      expect_equal(sum(df_filtered$region == missing_label), 10)
    }
  )
})
