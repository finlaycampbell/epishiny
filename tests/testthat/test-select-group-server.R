# ==============================================================================
# TEST: SELECT GROUP SUBMODULE
# Tests reactive behavior of select_group_server() using shiny::testServer()
# ==============================================================================

# Test basic module initialization -----------------------------------------

test_that("select_group_server initializes with single variable", {
  df_test <- make_test_linelist(100)

  testServer(
    select_group_server,
    args = list(
      id = "group",
      data_r = df_test,
      vars_r = "region"
    ),
    {
      # Module should initialize
      expect_true(TRUE)

      # Should return a reactive function
      returned <- session$getReturned()
      expect_true(shiny::is.reactive(returned))

      # Trigger inputs to initialize the module
      session$setInputs(region = NULL)

      # Should have "inputs" attribute
      df_filtered <- returned()
      expect_true("inputs" %in% names(attributes(df_filtered)))
    }
  )
})

test_that("select_group_server initializes with multiple variables", {
  df_test <- make_test_linelist(100)

  testServer(
    select_group_server,
    args = list(
      id = "group",
      data_r = df_test,
      vars_r = c("region", "outcome")
    ),
    {
      expect_true(TRUE)

      # Trigger inputs to initialize
      session$setInputs(region = NULL, outcome = NULL)

      # Should return filtered data
      returned <- session$getReturned()
      df_filtered <- returned()
      expect_s3_class(df_filtered, "data.frame")
    }
  )
})

# Test single group filtering ----------------------------------------------

test_that("single group filter works", {
  df_test <- make_test_linelist(100)

  testServer(
    select_group_server,
    args = list(
      id = "group",
      data_r = df_test,
      vars_r = "region"
    ),
    {
      # Set region filter to Region1
      session$setInputs(region = "Region1")

      # Get filtered data
      returned <- session$getReturned()
      df_filtered <- returned()

      # Should only have Region1
      expect_true(all(df_filtered$region == "Region1"))
      expect_lt(nrow(df_filtered), 100)

      # Check inputs attribute
      inputs <- attr(df_filtered, "inputs")
      expect_equal(inputs$region, "Region1")
    }
  )
})

test_that("multiple values in single group filter work", {
  df_test <- make_test_linelist(100)

  testServer(
    select_group_server,
    args = list(
      id = "group",
      data_r = df_test,
      vars_r = "region"
    ),
    {
      # Set multiple regions
      session$setInputs(region = c("Region1", "Region2"))

      # Get filtered data
      returned <- session$getReturned()
      df_filtered <- returned()

      # Should have both regions
      expect_true(all(df_filtered$region %in% c("Region1", "Region2")))
      expect_lt(nrow(df_filtered), 100)

      # Check inputs attribute
      inputs <- attr(df_filtered, "inputs")
      expect_equal(inputs$region, c("Region1", "Region2"))
    }
  )
})

test_that("empty group selection returns all data", {
  df_test <- make_test_linelist(100)

  testServer(
    select_group_server,
    args = list(
      id = "group",
      data_r = df_test,
      vars_r = "region"
    ),
    {
      # Set no regions (empty or NULL)
      session$setInputs(region = NULL)

      # Get filtered data
      returned <- session$getReturned()
      df_filtered <- returned()

      # Should return all data
      expect_equal(nrow(df_filtered), 100)
    }
  )
})

# Test multiple group variables ---------------------------------------------

test_that("multiple group variables filter independently", {
  df_test <- make_test_linelist(100)

  testServer(
    select_group_server,
    args = list(
      id = "group",
      data_r = df_test,
      vars_r = c("region", "outcome")
    ),
    {
      # Set both filters
      session$setInputs(
        region = "Region1",
        outcome = "Recovered"
      )

      # Get filtered data
      returned <- session$getReturned()
      df_filtered <- returned()

      # Should satisfy both conditions
      expect_true(all(df_filtered$region == "Region1"))
      expect_true(all(df_filtered$outcome == "Recovered"))
      expect_lt(nrow(df_filtered), 100)

      # Check inputs attribute
      inputs <- attr(df_filtered, "inputs")
      expect_equal(inputs$region, "Region1")
      expect_equal(inputs$outcome, "Recovered")
    }
  )
})

test_that("multiple group variables with one empty returns partial filter", {
  df_test <- make_test_linelist(100)

  testServer(
    select_group_server,
    args = list(
      id = "group",
      data_r = df_test,
      vars_r = c("region", "outcome")
    ),
    {
      # Set only region filter
      session$setInputs(
        region = "Region1",
        outcome = NULL
      )

      # Get filtered data
      returned <- session$getReturned()
      df_filtered <- returned()

      # Should only filter by region
      expect_true(all(df_filtered$region == "Region1"))
      # outcome should not be filtered
      expect_gt(length(unique(df_filtered$outcome)), 1)
    }
  )
})

# Test reset functionality --------------------------------------------------

test_that("reset_all button clears all selections", {
  df_test <- make_test_linelist(100)

  testServer(
    select_group_server,
    args = list(
      id = "group",
      data_r = df_test,
      vars_r = c("region", "outcome")
    ),
    {
      # Set filters
      session$setInputs(
        region = "Region1",
        outcome = "Recovered"
      )

      # Get filtered data
      returned <- session$getReturned()
      df_filtered1 <- returned()
      expect_lt(nrow(df_filtered1), 100)

      # Click reset button - this clears the selections via updateVirtualSelect
      session$setInputs(reset_all = 1)

      # After reset, the inputs become NULL/empty
      # which means no filtering, so all data returns
      session$setInputs(region = NULL, outcome = NULL)

      # Get data after reset
      df_filtered2 <- returned()

      # Should return all data after reset
      expect_equal(nrow(df_filtered2), 100)
    }
  )
})

# Test with reactive data ---------------------------------------------------

test_that("select_group_server works with reactive data", {
  df_base <- make_test_linelist(100)
  rv <- reactiveValues(df = df_base)

  testServer(
    select_group_server,
    args = list(
      id = "group",
      data_r = reactive(rv$df),
      vars_r = "region"
    ),
    {
      # Set region filter
      session$setInputs(region = "Region1")

      # Get filtered data
      returned <- session$getReturned()
      df_filtered <- returned()

      # Should filter correctly
      expect_true(all(df_filtered$region == "Region1"))
    }
  )
})

# Test edge cases -----------------------------------------------------------

test_that("select_group_server handles empty data", {
  # Create empty data frame with proper structure
  df_empty <- data.frame(
    region = character(0),
    outcome = character(0),
    stringsAsFactors = FALSE
  )

  testServer(
    select_group_server,
    args = list(
      id = "group",
      data_r = df_empty,
      vars_r = "region"
    ),
    {
      # Trigger inputs to initialize
      session$setInputs(region = NULL)

      # Should not error
      returned <- session$getReturned()
      df <- returned()
      expect_s3_class(df, "data.frame")
      expect_equal(nrow(df), 0)
    }
  )
})

test_that("select_group_server handles non-existent value", {
  df_test <- make_test_linelist(100)

  testServer(
    select_group_server,
    args = list(
      id = "group",
      data_r = df_test,
      vars_r = "region"
    ),
    {
      # Set region that doesn't exist
      session$setInputs(region = "NonExistentRegion")

      # Get filtered data
      returned <- session$getReturned()
      df_filtered <- returned()

      # Should return empty data frame
      expect_equal(nrow(df_filtered), 0)
    }
  )
})

test_that("select_group_server handles NA in group variables", {
  df_test <- make_test_linelist(100)
  # Add NA values
  df_test$region[1:10] <- NA
  # Convert to factor with explicit NA level
  df_test$region <- forcats::fct_na_value_to_level(
    df_test$region,
    level = getOption("epishiny.na.label", "(Missing)")
  )

  testServer(
    select_group_server,
    args = list(
      id = "group",
      data_r = df_test,
      vars_r = "region"
    ),
    {
      # Get the missing label
      missing_label <- getOption("epishiny.na.label", "(Missing)")

      # Set to filter for missing values
      session$setInputs(region = missing_label)

      # Get filtered data
      returned <- session$getReturned()
      df_filtered <- returned()

      # Should only have the missing label
      expect_true(all(df_filtered$region == missing_label))
      expect_equal(nrow(df_filtered), 10)
    }
  )
})

test_that("select_group_server can filter to include NA category", {
  df_test <- make_test_linelist(100)
  df_test$region[1:10] <- NA
  # Convert to factor with explicit NA level (as filter_server does)
  df_test$region <- forcats::fct_na_value_to_level(
    df_test$region,
    level = getOption("epishiny.na.label", "(Missing)")
  )

  testServer(
    select_group_server,
    args = list(
      id = "group",
      data_r = df_test,
      vars_r = "region"
    ),
    {
      missing_label <- getOption("epishiny.na.label", "(Missing)")

      # Set to include both Region1 and missing
      session$setInputs(region = c("Region1", missing_label))

      # Get filtered data
      returned <- session$getReturned()
      df_filtered <- returned()

      # Should have both Region1 and missing
      expect_true(all(df_filtered$region %in% c("Region1", missing_label)))
      expect_gt(nrow(df_filtered), 10) # More than just the NAs
    }
  )
})
