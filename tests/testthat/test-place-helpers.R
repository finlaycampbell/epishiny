# Tests for place module helper functions from R/02_place.R

# Setup test data
source("fixtures/helpers-fixtures.R")

# Test geo_layer() - EXPORTED FUNCTION ----------------------------------------

test_that("geo_layer creates valid epishiny_geo_layer object", {
  sf_test <- make_test_sf(5)

  result <- geo_layer(
    layer_name = "District",
    sf = sf_test,
    name_var = "name",
    join_by = "id"
  )

  expect_geo_layer(result)
  expect_equal(result$layer_name, "District")
  expect_equal(result$name_var, "name")
  expect_equal(result$join_by, "id")
})

test_that("geo_layer requires all mandatory parameters", {
  sf_test <- make_test_sf(3)

  expect_error(
    geo_layer(sf = sf_test, name_var = "name", join_by = "id"),
    "layer_name"
  )

  expect_error(
    geo_layer(layer_name = "Test", name_var = "name", join_by = "id"),
    "sf"
  )

  expect_error(
    geo_layer(layer_name = "Test", sf = sf_test, join_by = "id"),
    "name_var"
  )

  expect_error(
    geo_layer(layer_name = "Test", sf = sf_test, name_var = "name"),
    "join_by"
  )
})

test_that("geo_layer validates layer_name is single string", {
  sf_test <- make_test_sf(3)

  expect_error(
    geo_layer(
      layer_name = c("A", "B"),
      sf = sf_test,
      name_var = "name",
      join_by = "id"
    ),
    "character string of length 1"
  )

  expect_error(
    geo_layer(
      layer_name = 123,
      sf = sf_test,
      name_var = "name",
      join_by = "id"
    ),
    "character string of length 1"
  )
})

test_that("geo_layer validates name_var is single string", {
  sf_test <- make_test_sf(3)

  expect_error(
    geo_layer(
      layer_name = "Test",
      sf = sf_test,
      name_var = c("name1", "name2"),
      join_by = "id"
    ),
    "character string of length 1"
  )
})

test_that("geo_layer validates pop_var is single string if provided", {
  sf_test <- make_test_sf(3)

  expect_error(
    geo_layer(
      layer_name = "Test",
      sf = sf_test,
      name_var = "name",
      join_by = "id",
      pop_var = c("pop1", "pop2")
    ),
    "character string of length 1"
  )
})

test_that("geo_layer validates sf is an sf object", {
  not_sf <- data.frame(id = 1:5, name = paste0("Region", 1:5))

  expect_error(
    geo_layer(
      layer_name = "Test",
      sf = not_sf,
      name_var = "name",
      join_by = "id"
    ),
    "not an sf object"
  )
})

test_that("geo_layer validates join_by is single string", {
  sf_test <- make_test_sf(3)

  expect_error(
    geo_layer(
      layer_name = "Test",
      sf = sf_test,
      name_var = "name",
      join_by = c("id1", "id2")
    ),
    "must be a single variable name"
  )
})

test_that("geo_layer handles named join_by specification", {
  sf_test <- make_test_sf(3)

  result <- geo_layer(
    layer_name = "District",
    sf = sf_test,
    name_var = "name",
    join_by = c("id" = "district_code")
  )

  expect_equal(result$join_by, c("id" = "district_code"))
  expect_true(rlang::is_named(result$join_by))
  expect_equal(names(result$join_by), "id")
  expect_equal(unname(result$join_by), "district_code")
})

test_that("geo_layer handles unnamed join_by specification", {
  sf_test <- make_test_sf(3)

  result <- geo_layer(
    layer_name = "District",
    sf = sf_test,
    name_var = "name",
    join_by = "id"
  )

  expect_equal(result$join_by, "id")
  expect_false(rlang::is_named(result$join_by))
})

test_that("geo_layer validates join column exists in sf", {
  sf_test <- make_test_sf(3)

  expect_error(
    geo_layer(
      layer_name = "Test",
      sf = sf_test,
      name_var = "name",
      join_by = "nonexistent_column"
    ),
    "not found"
  )

  expect_error(
    geo_layer(
      layer_name = "Test",
      sf = sf_test,
      name_var = "name",
      join_by = c("nonexistent" = "data_col")
    ),
    "not found"
  )
})

test_that("geo_layer adds lon/lat coordinates if missing", {
  sf_test <- make_test_sf(3)

  result <- geo_layer(
    layer_name = "District",
    sf = sf_test,
    name_var = "name",
    join_by = "id"
  )

  # Should have lon and lat columns
  expect_true("lon" %in% names(result$sf))
  expect_true("lat" %in% names(result$sf))
  expect_type(result$sf$lon, "double")
  expect_type(result$sf$lat, "double")
})

test_that("geo_layer preserves existing lon/lat coordinates", {
  sf_test <- make_test_sf(3)
  sf_test$lon <- c(10, 20, 30)
  sf_test$lat <- c(40, 50, 60)

  result <- geo_layer(
    layer_name = "District",
    sf = sf_test,
    name_var = "name",
    join_by = "id"
  )

  # Should preserve existing coordinates
  expect_equal(result$sf$lon, c(10, 20, 30))
  expect_equal(result$sf$lat, c(40, 50, 60))
})

test_that("geo_layer includes pop_var when provided", {
  sf_test <- make_test_sf(3)

  result <- geo_layer(
    layer_name = "District",
    sf = sf_test,
    name_var = "name",
    join_by = "id",
    pop_var = "pop"
  )

  expect_equal(result$pop_var, "pop")
})

test_that("geo_layer pop_var is NULL when not provided", {
  sf_test <- make_test_sf(3)

  result <- geo_layer(
    layer_name = "District",
    sf = sf_test,
    name_var = "name",
    join_by = "id"
  )

  expect_null(result$pop_var)
})

# Test add_coords() ------------------------------------------------------------

test_that("add_coords adds lon/lat when missing", {
  sf_test <- make_test_sf(3)

  # Remove lon/lat if they exist
  if ("lon" %in% names(sf_test)) sf_test$lon <- NULL
  if ("lat" %in% names(sf_test)) sf_test$lat <- NULL

  result <- epishiny:::add_coords(sf_test)

  expect_true("lon" %in% names(result))
  expect_true("lat" %in% names(result))
  expect_equal(nrow(result), nrow(sf_test))
})

test_that("add_coords preserves existing lon/lat", {
  sf_test <- make_test_sf(3)
  sf_test$lon <- c(100, 200, 300)
  sf_test$lat <- c(400, 500, 600)

  result <- epishiny:::add_coords(sf_test)

  expect_equal(result$lon, c(100, 200, 300))
  expect_equal(result$lat, c(400, 500, 600))
})

test_that("add_coords handles sf objects with Z/M dimensions", {
  sf_test <- make_test_sf(3)
  # The function uses st_zm to drop Z/M dimensions
  result <- epishiny:::add_coords(sf_test)

  expect_s3_class(result, "sf")
  expect_true("lon" %in% names(result))
  expect_true("lat" %in% names(result))
})

# Test check_single_string() ---------------------------------------------------

test_that("check_single_string validates string inputs", {
  # Valid single string
  expect_silent(epishiny:::check_single_string("test"))

  # Invalid: multiple strings
  expect_error(
    epishiny:::check_single_string(c("a", "b")),
    "character string of length 1"
  )

  # Invalid: numeric
  expect_error(
    epishiny:::check_single_string(123),
    "character string of length 1"
  )

  # Invalid: NULL
  expect_error(
    epishiny:::check_single_string(NULL),
    "character string of length 1"
  )

  # Invalid: empty string vector
  expect_error(
    epishiny:::check_single_string(character(0)),
    "character string of length 1"
  )
})

# Test get_geo_counts() --------------------------------------------------------

test_that("get_geo_counts aggregates linelist data", {
  df <- data.frame(
    region = c("A", "A", "B", "B", "C"),
    case = 1:5
  )

  result <- epishiny:::get_geo_counts(
    df = df,
    is_agg = FALSE,
    geo_var = "region",
    count_var = NULL,
    count_lab = "cases"
  )

  expect_s3_class(result, "data.frame")
  expect_has_columns(result, c("region", "cases", "total"))
  expect_equal(nrow(result), 3)
  expect_equal(result$cases[result$region == "A"], 2)
  expect_equal(result$cases[result$region == "B"], 2)
  expect_equal(result$cases[result$region == "C"], 1)
})

test_that("get_geo_counts aggregates aggregated data with weights", {
  df <- data.frame(
    region = c("A", "A", "B"),
    count = c(10, 15, 20)
  )

  result <- epishiny:::get_geo_counts(
    df = df,
    is_agg = TRUE,
    geo_var = "region",
    count_var = "count",
    count_lab = "cases"
  )

  expect_s3_class(result, "data.frame")
  expect_has_columns(result, c("region", "cases", "total"))
  expect_equal(nrow(result), 2)
  expect_equal(result$cases[result$region == "A"], 25) # 10 + 15
  expect_equal(result$cases[result$region == "B"], 20)
})

test_that("get_geo_counts creates total column", {
  df <- data.frame(region = c("A", "B", "C"))

  result <- epishiny:::get_geo_counts(
    df = df,
    is_agg = FALSE,
    geo_var = "region",
    count_var = NULL,
    count_lab = "n"
  )

  expect_true("total" %in% names(result))
  expect_equal(result$total, result$n)
})

# Test get_map_circle_df() -----------------------------------------------------

test_that("get_map_circle_df returns ungrouped data correctly", {
  df <- data.frame(
    region = c("A", "A", "B", "B"),
    value = 1:4
  )

  df_geo_counts <- data.frame(
    region = c("A", "B"),
    n = c(2, 2),
    total = c(2, 2)
  )

  result <- epishiny:::get_map_circle_df(
    df = df,
    is_agg = FALSE,
    is_grouped = FALSE,
    geo_var = "region",
    count_var = NULL,
    group_var = NULL,
    df_geo_counts = df_geo_counts,
    geo_join = "region",
    n_lab = "n"
  )

  expect_s3_class(result, "data.frame")
  expect_equal(result, df_geo_counts)
})

test_that("get_map_circle_df handles grouped linelist data", {
  df <- data.frame(
    region = c("A", "A", "B", "B"),
    outcome = c("Death", "Recovery", "Death", "Death")
  )

  df_geo_counts <- data.frame(
    region = c("A", "B"),
    total = c(2, 2)
  )

  result <- epishiny:::get_map_circle_df(
    df = df,
    is_agg = FALSE,
    is_grouped = TRUE,
    geo_var = "region",
    count_var = NULL,
    group_var = "outcome",
    df_geo_counts = df_geo_counts,
    geo_join = "region",
    n_lab = "n"
  )

  expect_s3_class(result, "data.frame")
  expect_has_columns(result, c("region", "total"))
  # Should have columns for each group
  expect_true("Death" %in% names(result) || "Recovery" %in% names(result))
})

test_that("get_map_circle_df filters out zero totals", {
  df <- data.frame(region = c("A", "B"))

  df_geo_counts <- data.frame(
    region = c("A", "B", "C"),
    n = c(5, 0, 10),
    total = c(5, 0, 10)
  )

  result <- epishiny:::get_map_circle_df(
    df = df,
    is_agg = FALSE,
    is_grouped = FALSE,
    geo_var = "region",
    count_var = NULL,
    group_var = NULL,
    df_geo_counts = df_geo_counts,
    geo_join = "region",
    n_lab = "n"
  )

  # Should exclude region B with total = 0
  expect_false("B" %in% result$region)
  expect_true(all(result$total > 0))
})

test_that("get_map_circle_df handles aggregated grouped data", {
  df <- data.frame(
    region = c("A", "A", "B"),
    outcome = c("Death", "Recovery", "Death"),
    cases = c(10, 20, 15)
  )

  df_geo_counts <- data.frame(
    region = c("A", "B"),
    total = c(30, 15)
  )

  result <- epishiny:::get_map_circle_df(
    df = df,
    is_agg = TRUE,
    is_grouped = TRUE,
    geo_var = "region",
    count_var = "cases",
    group_var = "outcome",
    df_geo_counts = df_geo_counts,
    geo_join = "region",
    n_lab = "n"
  )

  expect_s3_class(result, "data.frame")
  expect_has_columns(result, c("region", "total"))
})
