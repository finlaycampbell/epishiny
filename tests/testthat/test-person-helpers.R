# Tests for person module helper functions from R/03_person.R

# Setup test data
source("fixtures/helpers-fixtures.R")

# Test bin_ages() --------------------------------------------------------------

test_that("bin_ages creates age groups correctly", {
  df <- data.frame(
    id = 1:10,
    age = c(2, 6, 10, 20, 30, 40, 55, 70, 85, 1)
  )

  result <- bin_ages(df, "age")

  expect_s3_class(result, "data.frame")
  expect_true("age_group" %in% names(result))
  expect_s3_class(result$age_group, "factor")
  # Check that age groups were assigned
  expect_false(any(is.na(result$age_group)))
})

test_that("bin_ages uses custom breaks and labels", {
  df <- data.frame(age = c(5, 15, 25, 35))

  result <- bin_ages(
    df,
    "age",
    age_breaks = c(0, 10, 20, 30, Inf),
    age_labels = c("0-9", "10-19", "20-29", "30+")
  )

  expect_equal(levels(result$age_group), c("0-9", "10-19", "20-29", "30+"))
  expect_equal(as.character(result$age_group), c("0-9", "10-19", "20-29", "30+"))
})

test_that("bin_ages handles boundary values correctly", {
  # right = FALSE means [0, 5), [5, 18), etc.
  # include.lowest = TRUE means first interval includes its lower bound
  df <- data.frame(age = c(0, 5, 17, 18, 49, 50))

  result <- bin_ages(
    df,
    "age",
    age_breaks = c(0, 5, 18, 50, Inf),
    age_labels = c("<5", "5-17", "18-49", "50+")
  )

  # Check boundary behavior
  expect_equal(as.character(result$age_group[1]), "<5") # 0 in [0, 5)
  expect_equal(as.character(result$age_group[2]), "5-17") # 5 in [5, 18)
  expect_equal(as.character(result$age_group[3]), "5-17") # 17 in [5, 18)
  expect_equal(as.character(result$age_group[4]), "18-49") # 18 in [18, 50)
  expect_equal(as.character(result$age_group[6]), "50+") # 50 in [50, Inf)
})

test_that("bin_ages handles Inf upper bound", {
  df <- data.frame(age = c(60, 75, 90, 100))

  result <- bin_ages(df, "age")

  # All should be in the 50+ category
  expect_true(all(as.character(result$age_group) == "50+"))
})

# Test parse_age_breaks() ------------------------------------------------------

test_that("parse_age_breaks parses valid comma-separated numbers", {
  result <- parse_age_breaks("0, 5, 18, 50")

  expect_true(result$valid)
  expect_equal(result$breaks, c(0, 5, 18, 50, Inf))
  expect_equal(result$message, "")
})

test_that("parse_age_breaks adds Inf automatically", {
  result <- parse_age_breaks("0, 10, 20")

  expect_true(result$valid)
  expect_equal(result$breaks[length(result$breaks)], Inf)
})

test_that("parse_age_breaks rejects non-numeric input", {
  result <- parse_age_breaks("0, five, 10")

  expect_false(result$valid)
  expect_null(result$breaks)
  expect_match(result$message, "Invalid format")
})

test_that("parse_age_breaks rejects non-increasing sequences", {
  result <- parse_age_breaks("10, 5, 0")

  expect_false(result$valid)
  expect_null(result$breaks)
  expect_match(result$message, "strictly increasing")
})

test_that("parse_age_breaks rejects equal consecutive values", {
  result <- parse_age_breaks("0, 5, 5, 10")

  expect_false(result$valid)
  expect_match(result$message, "strictly increasing")
})

test_that("parse_age_breaks requires at least 2 breaks", {
  result <- parse_age_breaks("5")

  expect_false(result$valid)
  expect_match(result$message, "At least 2 breaks")
})

test_that("parse_age_breaks warns when not starting with 0", {
  result <- parse_age_breaks("5, 10, 20")

  expect_true(result$valid)
  expect_equal(result$breaks, c(5, 10, 20, Inf))
  expect_match(result$message, "Warning.*0")
})

test_that("parse_age_breaks handles whitespace correctly", {
  result <- parse_age_breaks("  0 ,  5  , 18 , 50  ")

  expect_true(result$valid)
  expect_equal(result$breaks, c(0, 5, 18, 50, Inf))
})

test_that("parse_age_breaks filters out user-provided Inf", {
  # Users shouldn't type Inf, but if they do, we filter it and add it ourselves
  result <- parse_age_breaks("0, 5, 18, Inf")

  expect_true(result$valid)
  # Should have one Inf at the end, not duplicated
  expect_equal(sum(is.infinite(result$breaks)), 1)
  expect_equal(result$breaks[length(result$breaks)], Inf)
})

test_that("parse_age_breaks handles decimal numbers", {
  result <- parse_age_breaks("0, 2.5, 5.5, 10")

  expect_true(result$valid)
  expect_equal(result$breaks, c(0, 2.5, 5.5, 10, Inf))
})

# Test get_as_df() -------------------------------------------------------------

test_that("get_as_df creates population pyramid data structure", {
  df <- data.frame(
    sex = factor(c(rep("M", 5), rep("F", 5))),
    age = c(5, 15, 25, 35, 45, 10, 20, 30, 40, 50)
  )

  df <- bin_ages(df, "age")

  result <- get_as_df(
    df = df,
    sex_var = "sex",
    male_level = "M",
    female_level = "F",
    age_group_var = "age_group",
    age_var = "age"
  )

  expect_type(result, "list")
  expect_named(result, c("df_age_sex", "missing_age", "missing_sex"))
  expect_s3_class(result$df_age_sex, "data.frame")
  expect_type(result$missing_age, "integer")
  expect_type(result$missing_sex, "integer")
})

test_that("get_as_df makes male counts negative for pyramid", {
  df <- data.frame(
    sex = factor(c(rep("M", 3), rep("F", 3))),
    age = c(10, 20, 30, 10, 20, 30)
  )

  df <- bin_ages(df, "age")

  result <- get_as_df(
    df = df,
    sex_var = "sex",
    male_level = "M",
    female_level = "F",
    age_group_var = "age_group",
    age_var = "age"
  )

  df_as <- result$df_age_sex
  male_counts <- df_as$n[df_as$sex == "M"]
  female_counts <- df_as$n[df_as$sex == "F"]

  # Male counts should be negative
  expect_true(all(male_counts <= 0))
  # Female counts should be positive
  expect_true(all(female_counts >= 0))
})

test_that("get_as_df calculates proportions correctly", {
  df <- data.frame(
    sex = factor(c(rep("M", 10), rep("F", 10))),
    age = rep(c(5, 15, 25, 35, 45), 4)
  )

  df <- bin_ages(df, "age")

  result <- get_as_df(
    df = df,
    sex_var = "sex",
    male_level = "M",
    female_level = "F",
    age_group_var = "age_group",
    age_var = "age"
  )

  df_as <- result$df_age_sex
  # Sum of absolute proportions should be 100%
  expect_equal(sum(abs(df_as$n_prop)), 100, tolerance = 0.01)
})

test_that("get_as_df counts missing sex correctly", {
  df <- data.frame(
    sex = factor(c("M", "F", NA, "Unknown", "M")),
    age = c(10, 20, 30, 40, 50)
  )

  df <- bin_ages(df, "age")

  result <- get_as_df(
    df = df,
    sex_var = "sex",
    male_level = "M",
    female_level = "F",
    age_group_var = "age_group",
    age_var = "age"
  )

  # Should count 2 missing: NA and "Unknown"
  expect_equal(result$missing_sex, 2)
})

test_that("get_as_df counts missing age correctly", {
  df <- data.frame(
    sex = factor(c("M", "M", "F", "F")),
    age = c(10, NA, 20, NA)
  )

  df <- bin_ages(df, "age")
  # After binning, NAs in age become NA in age_group

  result <- get_as_df(
    df = df,
    sex_var = "sex",
    male_level = "M",
    female_level = "F",
    age_group_var = "age_group",
    age_var = "age"
  )

  # Should count 2 missing ages
  expect_equal(result$missing_age, 2)
})

test_that("get_as_df works with aggregated data", {
  df <- data.frame(
    sex = factor(c("M", "M", "F", "F")),
    age_group = factor(c("<5", "5-17", "<5", "5-17")),
    cases = c(10, 20, 15, 25)
  )

  result <- get_as_df(
    df = df,
    sex_var = "sex",
    male_level = "M",
    female_level = "F",
    age_group_var = "age_group",
    age_var = NULL,
    count_var = "cases"
  )

  df_as <- result$df_age_sex
  # Check that counts were weighted by cases variable
  expect_true(any(abs(df_as$n) > 1))
})

test_that("get_as_df handles missing age_group with option label", {
  withr::with_options(
    list(epishiny.na.label = "(Missing)"),
    {
      df <- data.frame(
        sex = factor(c("M", "F", "M", "F")),
        age_group = factor(c("<5", "<5", "(Missing)", "(Missing)")),
        cases = c(10, 10, 5, 5)
      )

      result <- get_as_df(
        df = df,
        sex_var = "sex",
        male_level = "M",
        female_level = "F",
        age_group_var = "age_group",
        age_var = NULL,
        count_var = "cases"
      )

      # Should count 10 missing (5 + 5)
      expect_equal(result$missing_age, 10)
    }
  )
})

test_that("get_as_df completes all sex/age combinations", {
  # Data with only some combinations present
  df <- data.frame(
    sex = factor(c("M", "M")),
    age = c(10, 20)
  )

  df <- bin_ages(df, "age", age_breaks = c(0, 15, 30, Inf), age_labels = c("0-14", "15-29", "30+"))

  result <- get_as_df(
    df = df,
    sex_var = "sex",
    male_level = "M",
    female_level = "F",
    age_group_var = "age_group",
    age_var = "age",
    age_breaks = c(0, 15, 30, Inf),
    age_labels = c("0-14", "15-29", "30+")
  )

  df_as <- result$df_age_sex
  # Should have data for both sexes and all age groups
  expect_equal(nrow(df_as), 6) # 2 sexes * 3 age groups
  # Female counts should be 0 (completed with fill)
  expect_true(all(df_as$n[df_as$sex == "F"] == 0))
})
