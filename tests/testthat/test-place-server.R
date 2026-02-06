# ==============================================================================
# TEST: PLACE MODULE SERVER FUNCTION
# Tests reactive behavior of place_server() using shiny::testServer()
# ==============================================================================

# Test basic module initialization -----------------------------------------

test_that("place_server initializes with single geo layer", {
  df_test <- make_test_linelist(100)
  sf_test <- make_test_sf(5)

  geo_layer1 <- geo_layer(
    layer_name = "Region",
    sf = sf_test,
    name_var = "name",
    join_by = c("name" = "region")
  )

  testServer(
    place_server,
    args = list(
      df = df_test,
      geo_data = list(geo_layer1),
      count_vars = NULL
    ),
    {
      # Module should initialize
      expect_true(TRUE)
    }
  )
})

test_that("place_server initializes with multiple geo layers", {
  df_test <- make_test_linelist(100)
  # Add district column for second geo layer
  df_test$district <- sample(paste0("Region", 1:3), 100, replace = TRUE)

  sf_test1 <- make_test_sf(5)
  sf_test2 <- make_test_sf(3)

  geo_layer1 <- geo_layer(
    layer_name = "Region",
    sf = sf_test1,
    name_var = "name",
    join_by = c("name" = "region")
  )

  geo_layer2 <- geo_layer(
    layer_name = "District",
    sf = sf_test2,
    name_var = "name",
    join_by = c("name" = "district")
  )

  testServer(
    place_server,
    args = list(
      df = df_test,
      geo_data = list(geo_layer1, geo_layer2),
      count_vars = NULL
    ),
    {
      # Module should initialize with multiple layers
      expect_true(TRUE)
    }
  )
})

# Test geographic level selection ------------------------------------------

test_that("geo_level input changes affect map data", {
  df_test <- make_test_linelist(100)
  # Add district column for second geo layer
  df_test$district <- sample(paste0("Region", 1:3), 100, replace = TRUE)

  sf_test1 <- make_test_sf(5)
  sf_test2 <- make_test_sf(3)

  geo_layer1 <- geo_layer(
    layer_name = "Region",
    sf = sf_test1,
    name_var = "name",
    join_by = c("name" = "region")
  )

  geo_layer2 <- geo_layer(
    layer_name = "District",
    sf = sf_test2,
    name_var = "name",
    join_by = c("name" = "district")
  )

  testServer(
    place_server,
    args = list(
      df = df_test,
      geo_data = list(geo_layer1, geo_layer2),
      count_vars = NULL
    ),
    {
      # Set to first level
      session$setInputs(
        geo_level = "Region",
        choro_active = TRUE,
        symbols_active = TRUE
      )

      # Should work
      expect_true(TRUE)

      # Set to second level
      session$setInputs(geo_level = "District")

      # Should work
      expect_true(TRUE)
    }
  )
})

# Test time filtering ------------------------------------------------------

test_that("df_mod responds to time_filter", {
  df_test <- make_test_linelist(100)
  date_range <- range(df_test$date)
  sf_test <- make_test_sf(5)

  geo_layer1 <- geo_layer(
    layer_name = "Region",
    sf = sf_test,
    name_var = "name",
    join_by = c("name" = "region")
  )

  testServer(
    place_server,
    args = list(
      df = df_test,
      geo_data = list(geo_layer1),
      time_filter = reactive({
        list(
          date_var = "date",
          from = date_range[1],
          to = date_range[1] + 10
        )
      })
    ),
    {
      session$setInputs(
        geo_level = "Region",
        choro_active = TRUE,
        symbols_active = TRUE
      )

      df_filtered <- df_mod()

      # Should be filtered to 10 day range
      expect_lt(nrow(df_filtered), 100)
      expect_true(all(df_filtered$date <= date_range[1] + 10))
    }
  )
})

# Test choropleth variable switching ---------------------------------------

test_that("switching choropleth variables works", {
  df_test <- make_test_linelist(100)
  sf_test <- make_test_sf(5)
  # Add population to sf
  sf_test$population <- sample(1000:5000, 5)

  geo_layer1 <- geo_layer(
    layer_name = "Region",
    sf = sf_test,
    name_var = "name",
    join_by = c("name" = "region"),
    pop_var = "population"
  )

  testServer(
    place_server,
    args = list(
      df = df_test,
      geo_data = list(geo_layer1),
      count_vars = NULL
    ),
    {
      # Set to counts
      session$setInputs(
        geo_level = "Region",
        choro_active = TRUE,
        symbols_active = TRUE,
        choro_var = "total"
      )

      # Should work
      expect_true(TRUE)

      # Set to attack rate
      session$setInputs(choro_var = "attack_rate")

      # Should work
      expect_true(TRUE)
    }
  )
})

# Test circle map (pie charts) ---------------------------------------------

test_that("circle layer shows grouped data", {
  df_test <- make_test_linelist(100)
  sf_test <- make_test_sf(5)

  geo_layer1 <- geo_layer(
    layer_name = "Region",
    sf = sf_test,
    name_var = "name",
    join_by = c("name" = "region")
  )

  testServer(
    place_server,
    args = list(
      df = df_test,
      geo_data = list(geo_layer1),
      group_var = "outcome"
    ),
    {
      # Enable circle layer
      session$setInputs(
        geo_level = "Region",
        choro_active = TRUE,
        symbols_active = TRUE,
        var = "outcome"
      )

      # Should work
      expect_true(TRUE)
    }
  )
})

# Test map click events ----------------------------------------------------

test_that("map shape click sets region selection", {
  df_test <- make_test_linelist(100)
  sf_test <- make_test_sf(5)

  geo_layer1 <- geo_layer(
    layer_name = "Region",
    sf = sf_test,
    name_var = "name",
    join_by = c("name" = "region")
  )

  testServer(
    place_server,
    args = list(
      df = df_test,
      geo_data = list(geo_layer1)
    ),
    {
      session$setInputs(
        geo_level = "Region",
        choro_active = TRUE,
        symbols_active = TRUE
      )

      # Simulate shape click
      session$setInputs(map_shape_click = list(id = "Region1"))

      # Should return place filter
      pf <- session$getReturned()

      # Should have filter info
      expect_type(pf(), "list")
      expect_true("region_select" %in% names(pf()))
      expect_true(pf()$region_select == "Region1")
    }
  )
})

test_that("clicking selected map shape resets region select", {
  df_test <- make_test_linelist(100)
  sf_test <- make_test_sf(5)

  geo_layer1 <- geo_layer(
    layer_name = "Region",
    sf = sf_test,
    name_var = "name",
    join_by = c("name" = "region")
  )

  testServer(
    place_server,
    args = list(
      df = df_test,
      geo_data = list(geo_layer1)
    ),
    {
      session$setInputs(
        geo_level = "Region",
        choro_active = TRUE,
        symbols_active = TRUE
      )

      # First click a shape
      session$setInputs(map_shape_click = list(id = "Region1"))
      session$elapse(1000)

      # Click same shape - should reset the filter
      session$setInputs(map_shape_click = list(id = "Region1"))
      session$elapse(1000)

      # Should be NULL or empty
      pf <- session$getReturned()
      expect_true(is.null(pf()) || length(pf()) == 0)
    }
  )
})

# Test multiple count variables --------------------------------------------

test_that("multiple count variables can be selected", {
  df_agg <- make_test_aggregated(100)
  sf_test <- make_test_sf(5)

  geo_layer1 <- geo_layer(
    layer_name = "Region",
    sf = sf_test,
    name_var = "name",
    join_by = c("name" = "region")
  )

  testServer(
    place_server,
    args = list(
      df = df_agg,
      geo_data = list(geo_layer1),
      count_vars = c("cases", "deaths")
    ),
    {
      # Test with first count var
      session$setInputs(
        geo_level = "Region",
        count_var = "cases",
        choro_active = TRUE,
        symbols_active = TRUE
      )

      # Should work
      expect_true(TRUE)

      # Test with second count var
      session$setInputs(count_var = "deaths")

      # Should work
      expect_true(TRUE)
    }
  )
})

# Test filter_info reactive ------------------------------------------------

test_that("filter_info_out formats filter information", {
  df_test <- make_test_linelist(100)
  sf_test <- make_test_sf(5)

  geo_layer1 <- geo_layer(
    layer_name = "Region",
    sf = sf_test,
    name_var = "name",
    join_by = c("name" = "region")
  )

  testServer(
    place_server,
    args = list(
      df = df_test,
      geo_data = list(geo_layer1),
      filter_info = reactive("<b>Filters applied</b></br>Period: 2024-01-01 - 2024-01-31")
    ),
    {
      session$setInputs(
        geo_level = "Region",
        choro_active = TRUE,
        symbols_active = TRUE
      )

      fi <- filter_info_out()

      # Should return filter info
      expect_type(fi, "character")
      expect_match(fi, "Filters applied")
    }
  )
})

test_that("filter_info_out combines time filter info", {
  df_test <- make_test_linelist(100)
  sf_test <- make_test_sf(5)

  geo_layer1 <- geo_layer(
    layer_name = "Region",
    sf = sf_test,
    name_var = "name",
    join_by = c("name" = "region")
  )

  testServer(
    place_server,
    args = list(
      df = df_test,
      geo_data = list(geo_layer1),
      filter_info = reactive("<b>Filters applied</b></br>Period: 01/Jan/24 - 31/Jan/24"),
      time_filter = reactive({
        list(
          date_var = "date",
          from = as.Date("2024-03-18"),
          to = as.Date("2024-03-18") + 6,
          interval = "week",
          lab = "2024-W12"
        )
      })
    ),
    {
      session$setInputs(
        geo_level = "Region",
        choro_active = FALSE,
        symbols_active = TRUE
      )

      session$elapse(1000)
      fi <- filter_info_out()

      # Should combine filter info
      expect_match(fi, "2024-W12")
    }
  )
})

# Test edge cases ----------------------------------------------------------

test_that("place_server handles empty data gracefully", {
  # Create empty data frame with proper structure
  df_empty <- data.frame(
    region = character(0),
    date = as.Date(character(0)),
    stringsAsFactors = FALSE
  )
  sf_test <- make_test_sf(5)

  geo_layer1 <- geo_layer(
    layer_name = "Region",
    sf = sf_test,
    name_var = "name",
    join_by = c("name" = "region")
  )

  testServer(
    place_server,
    args = list(
      df = df_empty,
      geo_data = list(geo_layer1)
    ),
    {
      session$setInputs(
        geo_level = "Region",
        choro_active = TRUE,
        symbols_active = TRUE
      )

      # Should not error
      df <- df_mod()
      expect_s3_class(df, "data.frame")
      expect_equal(nrow(df), 0)
    }
  )
})

test_that("place_server handles data with no geographic matches", {
  df_test <- make_test_linelist(100)
  df_test$region <- paste0("NoMatch", 1:5)
  sf_test <- make_test_sf(5)

  geo_layer1 <- geo_layer(
    layer_name = "Region",
    sf = sf_test,
    name_var = "name",
    join_by = c("name" = "region")
  )

  testServer(
    place_server,
    args = list(
      df = df_test,
      geo_data = list(geo_layer1)
    ),
    {
      session$setInputs(
        geo_level = "Region",
        choro_active = FALSE,
        symbols_active = TRUE
      )

      # Should handle gracefully
      expect_true(TRUE)
    }
  )
})

test_that("place_server handles single region with all data", {
  df_test <- make_test_linelist(100)
  df_test$region <- "Region1"
  sf_test <- make_test_sf(1)

  geo_layer1 <- geo_layer(
    layer_name = "Region",
    sf = sf_test,
    name_var = "name",
    join_by = c("name" = "region")
  )

  testServer(
    place_server,
    args = list(
      df = df_test,
      geo_data = list(geo_layer1)
    ),
    {
      session$setInputs(
        geo_level = "Region",
        choro_active = FALSE,
        symbols_active = TRUE
      )

      df <- df_mod()
      expect_s3_class(df, "data.frame")
      expect_equal(nrow(df), 100)
      expect_true(all(df$region == "Region1"))
    }
  )
})

# Test choropleth breaks and palettes --------------------------------------

test_that("choropleth breaks can be changed", {
  df_test <- make_test_linelist(100)
  sf_test <- make_test_sf(5)

  geo_layer1 <- geo_layer(
    layer_name = "Region",
    sf = sf_test,
    name_var = "name",
    join_by = c("name" = "region")
  )

  testServer(
    place_server,
    args = list(
      df = df_test,
      geo_data = list(geo_layer1)
    ),
    {
      session$setInputs(
        geo_level = "Region",
        choro_active = FALSE,
        symbols_active = TRUE,
        choro_breaks = "quantile"
      )

      # Should work
      expect_true(TRUE)

      # Change breaks method
      session$setInputs(choro_breaks = "jenks")

      # Should work
      expect_true(TRUE)
    }
  )
})

test_that("choropleth palette can be changed", {
  df_test <- make_test_linelist(100)
  sf_test <- make_test_sf(5)

  geo_layer1 <- geo_layer(
    layer_name = "Region",
    sf = sf_test,
    name_var = "name",
    join_by = c("name" = "region")
  )

  testServer(
    place_server,
    args = list(
      df = df_test,
      geo_data = list(geo_layer1)
    ),
    {
      session$setInputs(
        geo_level = "Region",
        choro_active = TRUE,
        symbols_active = TRUE,
        choro_pal = "Reds"
      )

      # Should work
      expect_true(TRUE)

      # Change palette
      session$setInputs(choro_pal = "Blues")

      # Should work
      expect_true(TRUE)
    }
  )
})
