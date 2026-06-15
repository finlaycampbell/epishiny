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
    geo_var = "region",
    count_vars = NULL
  )

  expect_s3_class(result, "data.frame")
  expect_has_columns(result, c("region", "total"))
  expect_equal(nrow(result), 3)
  expect_equal(result$total[result$region == "A"], 2)
  expect_equal(result$total[result$region == "B"], 2)
  expect_equal(result$total[result$region == "C"], 1)
})

test_that("get_geo_counts aggregates aggregated data with weights", {
  df <- data.frame(
    region = c("A", "A", "B"),
    count = c(10, 15, 20)
  )

  result <- epishiny:::get_geo_counts(
    df = df,
    geo_var = "region",
    count_vars = "count"
  )

  expect_s3_class(result, "data.frame")
  expect_has_columns(result, c("region", "count", "total"))
  expect_equal(nrow(result), 2)
  expect_equal(result$count[result$region == "A"], 25) # 10 + 15
  expect_equal(result$count[result$region == "B"], 20)
})

test_that("get_geo_counts creates total column", {
  df <- data.frame(region = c("A", "B", "C"))

  result <- epishiny:::get_geo_counts(
    df = df,
    geo_var = "region",
    count_vars = NULL
  )

  expect_true("total" %in% names(result))
  expect_equal(result$total, c(1, 1, 1))
})

test_that("get_geo_counts handles multiple count variables", {
  df <- data.frame(
    region = c("A", "A", "B", "B"),
    cases = c(10, 15, 20, 5),
    deaths = c(1, 2, 3, 1)
  )

  result <- epishiny:::get_geo_counts(
    df = df,
    geo_var = "region",
    count_vars = c("cases", "deaths")
  )

  expect_true(all(c("region", "cases", "deaths", "total") %in% names(result)))
  expect_equal(result$cases[result$region == "A"], 25)  # 10 + 15
  expect_equal(result$deaths[result$region == "A"], 3)  # 1 + 2
  expect_equal(result$total, result$cases)  # total = first count_var
})

test_that("get_geo_counts maintains backward compatibility with single count_var", {
  df <- data.frame(
    region = c("A", "A", "B"),
    cases = c(10, 15, 20)
  )

  result <- epishiny:::get_geo_counts(
    df = df,
    geo_var = "region",
    count_vars = "cases"
  )

  expect_true(all(c("region", "cases", "total") %in% names(result)))
  expect_equal(result$total, result$cases)
})

test_that("get_geo_counts handles linelist data correctly", {
  df <- data.frame(region = c("A", "A", "B", "B", "C"))

  result <- epishiny:::get_geo_counts(
    df = df,
    geo_var = "region",
    count_vars = NULL
  )

  expect_has_columns(result, c("region", "total"))
  expect_false("n" %in% names(result))
  expect_equal(result$total[result$region == "A"], 2)
})

test_that("get_geo_counts handles named count_vars vector", {
  df <- data.frame(
    region = c("A", "A", "B", "B"),
    cases = c(10, 15, 20, 5),
    deaths = c(1, 2, 3, 1)
  )

  result <- epishiny:::get_geo_counts(
    df = df,
    geo_var = "region",
    count_vars = c("Cases" = "cases", "Deaths" = "deaths")
  )

  # Should use actual column names, not labels
  expect_true(all(c("region", "cases", "deaths", "total") %in% names(result)))
  expect_equal(result$cases[result$region == "A"], 25)
  expect_equal(result$deaths[result$region == "A"], 3)
})

# Test get_map_circle_df() -----------------------------------------------------

test_that("get_map_circle_df returns ungrouped linelist data correctly", {
  df <- data.frame(
    region = c("A", "A", "B", "B"),
    value = 1:4
  )

  # simulate sf-like df_geo (with geometry-like structure for st_drop_geometry)
  df_geo <- sf::st_sf(
    region = c("A", "B"),
    total = c(2, 2),
    geometry = sf::st_sfc(
      sf::st_polygon(list(matrix(c(0, 0, 1, 1, 0, 0, 1, 1, 0, 0), ncol = 2))),
      sf::st_polygon(list(matrix(c(1, 1, 2, 2, 1, 1, 2, 2, 1, 1), ncol = 2)))
    )
  )

  result <- epishiny:::get_map_circle_df(
    df_raw = df,
    df_geo = df_geo,
    geo_var = "region",
    geo_join = "region"
  )

  expect_s3_class(result, "data.frame")
  expect_true("n" %in% names(result))
  expect_equal(result$n, result$total)
  expect_equal(attr(result, "chart_cols"), "n")
})

test_that("get_map_circle_df handles grouped linelist data", {
  df <- data.frame(
    region = c("A", "A", "B", "B"),
    outcome = c("Death", "Recovery", "Death", "Death")
  )

  df_geo <- sf::st_sf(
    region = c("A", "B"),
    total = c(2, 2),
    geometry = sf::st_sfc(
      sf::st_polygon(list(matrix(c(0, 0, 1, 1, 0, 0, 1, 1, 0, 0), ncol = 2))),
      sf::st_polygon(list(matrix(c(1, 1, 2, 2, 1, 1, 2, 2, 1, 1), ncol = 2)))
    )
  )

  result <- epishiny:::get_map_circle_df(
    df_raw = df,
    df_geo = df_geo,
    geo_var = "region",
    geo_join = "region",
    group_var = "outcome"
  )

  expect_s3_class(result, "data.frame")
  expect_has_columns(result, c("region", "total"))
  expect_true("Death" %in% names(result))
  expect_true("Recovery" %in% names(result))
  chart_cols <- attr(result, "chart_cols")
  expect_true(all(c("Death", "Recovery") %in% chart_cols))
})

test_that("get_map_circle_df filters out zero totals", {
  df <- data.frame(region = c("A", "B"))

  df_geo <- sf::st_sf(
    region = c("A", "B", "C"),
    total = c(5, 0, 10),
    geometry = sf::st_sfc(
      sf::st_polygon(list(matrix(c(0, 0, 1, 1, 0, 0, 1, 1, 0, 0), ncol = 2))),
      sf::st_polygon(list(matrix(c(1, 1, 2, 2, 1, 1, 2, 2, 1, 1), ncol = 2))),
      sf::st_polygon(list(matrix(c(2, 2, 3, 3, 2, 2, 3, 3, 2, 2), ncol = 2)))
    )
  )

  result <- epishiny:::get_map_circle_df(
    df_raw = df,
    df_geo = df_geo,
    geo_var = "region",
    geo_join = "region"
  )

  # Should exclude region B with total = 0
  expect_false("B" %in% result$region)
  expect_true(all(result$total > 0))
})

test_that("get_map_circle_df handles aggregated ungrouped data", {
  df <- data.frame(
    region = c("A", "A", "B"),
    cases = c(10, 15, 20)
  )

  df_geo <- sf::st_sf(
    region = c("A", "B"),
    cases = c(25, 20),
    total = c(25, 20),
    geometry = sf::st_sfc(
      sf::st_polygon(list(matrix(c(0, 0, 1, 1, 0, 0, 1, 1, 0, 0), ncol = 2))),
      sf::st_polygon(list(matrix(c(1, 1, 2, 2, 1, 1, 2, 2, 1, 1), ncol = 2)))
    )
  )

  result <- epishiny:::get_map_circle_df(
    df_raw = df,
    df_geo = df_geo,
    geo_var = "region",
    geo_join = "region",
    count_var = "cases"
  )

  expect_s3_class(result, "data.frame")
  expect_true("n" %in% names(result))
  expect_equal(result$n, result$cases)
  expect_equal(attr(result, "chart_cols"), "n")
})

test_that("get_map_circle_df handles aggregated grouped data", {
  df <- data.frame(
    region = c("A", "A", "B"),
    outcome = c("Death", "Recovery", "Death"),
    cases = c(10, 20, 15)
  )

  df_geo <- sf::st_sf(
    region = c("A", "B"),
    cases = c(30, 15),
    total = c(30, 15),
    geometry = sf::st_sfc(
      sf::st_polygon(list(matrix(c(0, 0, 1, 1, 0, 0, 1, 1, 0, 0), ncol = 2))),
      sf::st_polygon(list(matrix(c(1, 1, 2, 2, 1, 1, 2, 2, 1, 1), ncol = 2)))
    )
  )

  result <- epishiny:::get_map_circle_df(
    df_raw = df,
    df_geo = df_geo,
    geo_var = "region",
    geo_join = "region",
    count_var = "cases",
    group_var = "outcome"
  )

  expect_s3_class(result, "data.frame")
  expect_has_columns(result, c("region", "total"))
  chart_cols <- attr(result, "chart_cols")
  expect_true(all(c("Death", "Recovery") %in% chart_cols))
})

test_that("calc_choro_breaks maps fixed to pretty intervals", {
  values <- c(1, 2, 3, 5, 10, 20, 50)

  brks <- epishiny:::calc_choro_breaks(values, n = 5, style = "fixed")

  expect_type(brks, "double")
  expect_equal(min(brks), 1)
  expect_equal(max(brks), 50)
  expect_true(all(brks == round(brks)))
})

test_that("calc_choro_breaks handles constant values", {
  brks <- epishiny:::calc_choro_breaks(rep(5, 4), n = 5, style = "fixed")

  expect_equal(brks, c(5, 6))
})

# Test prepare_geo_data() ------------------------------------------------------

test_that("prepare_geo_data returns sf with correct columns for linelist", {
  df <- data.frame(
    region = c("A", "A", "B", "B", "C"),
    case = 1:5
  )

  sf_test <- sf::st_sf(
    id = c("A", "B", "C"),
    name = c("Region A", "Region B", "Region C"),
    geometry = sf::st_sfc(
      sf::st_polygon(list(matrix(c(0, 0, 1, 1, 0, 0, 1, 1, 0, 0), ncol = 2))),
      sf::st_polygon(list(matrix(c(1, 1, 2, 2, 1, 1, 2, 2, 1, 1), ncol = 2))),
      sf::st_polygon(list(matrix(c(2, 2, 3, 3, 2, 2, 3, 3, 2, 2), ncol = 2)))
    )
  )
  sf_test <- epishiny:::add_coords(sf_test)

  result <- epishiny:::prepare_geo_data(
    df = df,
    sf = sf_test,
    geo_var = "region",
    geo_join = c("id" = "region"),
    join_cols = "id",
    geo_name_col = "name"
  )

  expect_s3_class(result, "sf")
  expect_has_columns(result, c("id", "name", "lon", "lat", "total"))
  expect_equal(nrow(result), 3)
  expect_equal(result$total[result$id == "A"], 2)
})

test_that("prepare_geo_data returns sf with correct columns for aggregated data", {
  df <- data.frame(
    region = c("A", "A", "B"),
    cases = c(10, 15, 20),
    deaths = c(1, 2, 3)
  )

  sf_test <- sf::st_sf(
    id = c("A", "B"),
    name = c("Region A", "Region B"),
    geometry = sf::st_sfc(
      sf::st_polygon(list(matrix(c(0, 0, 1, 1, 0, 0, 1, 1, 0, 0), ncol = 2))),
      sf::st_polygon(list(matrix(c(1, 1, 2, 2, 1, 1, 2, 2, 1, 1), ncol = 2)))
    )
  )
  sf_test <- epishiny:::add_coords(sf_test)

  result <- epishiny:::prepare_geo_data(
    df = df,
    sf = sf_test,
    geo_var = "region",
    geo_join = c("id" = "region"),
    join_cols = "id",
    geo_name_col = "name",
    count_vars = c("cases", "deaths")
  )

  expect_s3_class(result, "sf")
  expect_has_columns(result, c("id", "name", "cases", "deaths", "total"))
  expect_equal(result$cases[result$id == "A"], 25)
  expect_equal(result$deaths[result$id == "A"], 3)
  expect_equal(result$total, result$cases) # total = first count_var
})

test_that("prepare_geo_data computes attack rates with population data", {
  df <- data.frame(
    region = c("A", "B"),
    case = 1:2
  )

  sf_test <- sf::st_sf(
    id = c("A", "B"),
    name = c("Region A", "Region B"),
    pop = c(1000, 2000),
    geometry = sf::st_sfc(
      sf::st_polygon(list(matrix(c(0, 0, 1, 1, 0, 0, 1, 1, 0, 0), ncol = 2))),
      sf::st_polygon(list(matrix(c(1, 1, 2, 2, 1, 1, 2, 2, 1, 1), ncol = 2)))
    )
  )
  sf_test <- epishiny:::add_coords(sf_test)

  result <- epishiny:::prepare_geo_data(
    df = df,
    sf = sf_test,
    geo_var = "region",
    geo_join = c("id" = "region"),
    join_cols = "id",
    geo_name_col = "name",
    geo_pop_var = "pop"
  )

  expect_true("attack_rate" %in% names(result))
  # attack_rate = (total / pop) * 100000
  expect_equal(result$attack_rate[result$id == "A"], (1 / 1000) * 1e5)
})

test_that("prepare_geo_data computes per-variable attack rates for aggregated data", {
  df <- data.frame(
    region = c("A", "B"),
    cases = c(100, 200),
    deaths = c(10, 20)
  )

  sf_test <- sf::st_sf(
    id = c("A", "B"),
    name = c("Region A", "Region B"),
    pop = c(10000, 20000),
    geometry = sf::st_sfc(
      sf::st_polygon(list(matrix(c(0, 0, 1, 1, 0, 0, 1, 1, 0, 0), ncol = 2))),
      sf::st_polygon(list(matrix(c(1, 1, 2, 2, 1, 1, 2, 2, 1, 1), ncol = 2)))
    )
  )
  sf_test <- epishiny:::add_coords(sf_test)

  result <- epishiny:::prepare_geo_data(
    df = df,
    sf = sf_test,
    geo_var = "region",
    geo_join = c("id" = "region"),
    join_cols = "id",
    geo_name_col = "name",
    geo_pop_var = "pop",
    count_vars = c("cases", "deaths")
  )

  expect_true("attack_rate_cases" %in% names(result))
  expect_true("attack_rate_deaths" %in% names(result))
  expect_true("attack_rate" %in% names(result))
  # attack_rate = attack_rate of first count_var (cases)
  expect_equal(result$attack_rate, result$attack_rate_cases)
})
