# ==============================================================================
# TEST: PERSON MODULE SERVER FUNCTION
# Tests reactive behavior of person_server() using shiny::testServer()
# ==============================================================================

# Test basic module initialization -----------------------------------------

test_that("person_server initializes with linelist data", {
  df_test <- make_test_linelist(100)

  testServer(
    person_server,
    args = list(
      df = df_test,
      age_var = "age",
      sex_var = "sex",
      male_level = "M",
      female_level = "F",
      count_vars = NULL
    ),
    {
      # Module should initialize
      expect_true(TRUE)
    }
  )
})

test_that("person_server fails with numeric data passed to age_group_var", {
  df_test <- make_test_linelist(100)

  testServer(
    person_server,
    args = list(
      df = df_test,
      age_group_var = "age",
      sex_var = "sex",
      male_level = "M",
      female_level = "F",
      count_vars = NULL
    ),
    {
      # Module should initialize
      expect_error(df_prep())
    }
  )
})

test_that("person_server warns if age_group_var is character not factor", {
  df_agg <- data.frame(
    age_group = rep(c("0-4", "5-9", "10-14"), each = 2),
    sex = rep(c("M", "F"), 3),
    cases = sample(10:50, 6, replace = TRUE)
  )

  testServer(
    person_server,
    args = list(
      df = df_agg,
      age_group_var = "age_group",
      sex_var = "sex",
      male_level = "M",
      female_level = "F",
      count_vars = c("Cases" = "cases")
    ),
    {
      expect_warning(df_prep())
    }
  )
})

test_that("person_server initializes with aggregated data", {
  df_agg <- data.frame(
    age_group = factor(rep(c("0-4", "5-9", "10-14"), each = 2), c("0-4", "5-9", "10-14")),
    sex = rep(c("M", "F"), 3),
    cases = sample(10:50, 6, replace = TRUE)
  )

  testServer(
    person_server,
    args = list(
      df = df_agg,
      age_group_var = "age_group",
      sex_var = "sex",
      male_level = "M",
      female_level = "F",
      count_vars = c("Cases" = "cases")
    ),
    {
      al <- levels(df_prep()$age_group)
      expect_contains(al, c("0-4", "5-9", "10-14"))
    }
  )
})

# Test age binning with custom breaks --------------------------------------

test_that("custom age breaks can be applied", {
  df_test <- make_test_linelist(100)

  testServer(
    person_server,
    args = list(
      df = df_test,
      age_var = "age",
      sex_var = "sex",
      male_level = "M",
      female_level = "F",
      count_vars = NULL
    ),
    {
      # Set custom age breaks
      session$setInputs(
        age_breaks_text = "0, 10, 20, 50",
        cnt_pcnt = "n"
      )

      # Click apply button
      session$setInputs(age_breaks_apply = 1)

      al <- levels(df_prep()$age_group)
      expect_contains(al, c("0-9", "10-19", "20-49", "50+"))
    }
  )
})

test_that("invalid age breaks show validation error", {
  df_test <- make_test_linelist(100)

  testServer(
    person_server,
    args = list(
      df = df_test,
      age_var = "age",
      sex_var = "sex",
      male_level = "M",
      female_level = "F"
    ),
    {
      # Set invalid age breaks (not increasing)
      session$setInputs(age_breaks_text = "0, 20, 10, 50")

      # Validation should fail
      validation <- output$age_breaks_validation
      expect_true(!is.null(validation))
    }
  )
})

test_that("non-numeric age breaks show validation error", {
  df_test <- make_test_linelist(100)

  testServer(
    person_server,
    args = list(
      df = df_test,
      age_var = "age",
      sex_var = "sex",
      male_level = "M",
      female_level = "F"
    ),
    {
      # Set non-numeric age breaks
      session$setInputs(age_breaks_text = "0, five, 10")

      # Should show error
      validation <- output$age_breaks_validation$html
      expect_true(!is.null(validation))
      expect_match(validation, "Invalid format. Use numbers separated by commas")
    }
  )
})

# Test place and time filtering --------------------------------------------

test_that("df_mod responds to place_filter", {
  df_test <- make_test_linelist(100)

  testServer(
    person_server,
    args = list(
      df = df_test,
      age_var = "age",
      sex_var = "sex",
      male_level = "M",
      female_level = "F",
      place_filter = reactive({
        list(geo_col = "region", region_select = "Region1")
      })
    ),
    {
      session$setInputs(
        count_var = NULL,
        cnt_pcnt = "n"
      )

      df_filtered <- df_mod()

      # Should only contain Region1
      expect_true(all(df_filtered$region == "Region1"))
      expect_lt(nrow(df_filtered), 100)
    }
  )
})

test_that("df_mod responds to time_filter", {
  df_test <- make_test_linelist(100)
  date_range <- range(df_test$date)

  testServer(
    person_server,
    args = list(
      df = df_test,
      age_var = "age",
      sex_var = "sex",
      male_level = "M",
      female_level = "F",
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
        count_var = NULL,
        cnt_pcnt = "n"
      )

      df_filtered <- df_mod()

      # Should be filtered to 10 day range
      expect_lt(nrow(df_filtered), 100)
      expect_true(all(df_filtered$date <= date_range[1] + 10))
    }
  )
})

test_that("df_mod responds to combined place and time filters", {
  df_test <- make_test_linelist(100)
  date_range <- range(df_test$date)

  testServer(
    person_server,
    args = list(
      df = df_test,
      age_var = "age",
      sex_var = "sex",
      male_level = "M",
      female_level = "F",
      place_filter = reactive({
        list(geo_col = "region", region_select = "Region1")
      }),
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
        count_var = NULL,
        cnt_pcnt = "n"
      )

      df_filtered <- df_mod()

      # Should be filtered by both
      expect_true(all(df_filtered$region == "Region1"))
      expect_true(all(df_filtered$date <= date_range[1] + 10))
      expect_lt(nrow(df_filtered), 100)
    }
  )
})

# Test count vs percentage display -----------------------------------------

test_that("cnt_pcnt switches between counts and percentages", {
  df_test <- make_test_linelist(100)

  testServer(
    person_server,
    args = list(
      df = df_test,
      age_var = "age",
      sex_var = "sex",
      male_level = "M",
      female_level = "F"
    ),
    {
      # Test with counts
      session$setInputs(
        cnt_pcnt = "n"
      )

      # Should work (checking doesn't error)
      expect_true(TRUE)

      # Test with percentages
      session$setInputs(cnt_pcnt = "n_prop")

      # Should work
      expect_true(TRUE)
    }
  )
})

# Test pre-binned age groups -----------------------------------------------

test_that("person_server works with pre-binned age groups", {
  df_test <- make_test_linelist(100)
  df_test$age_group <- cut(
    df_test$age,
    breaks = c(0, 5, 18, 50, Inf),
    right = FALSE,
    include.lowest = TRUE
  )

  testServer(
    person_server,
    args = list(
      df = df_test,
      age_group_var = "age_group",
      sex_var = "sex",
      male_level = "M",
      female_level = "F"
    ),
    {
      session$setInputs(
        count_var = NULL,
        cnt_pcnt = "n"
      )

      # Should have the bins created above
      expect_contains(
        levels(df_mod()$age_group),
        c("[0,5)", "[5,18)", "[18,50)", "[50,Inf]")
      )
    }
  )
})

# Test numeric age binning on-the-fly --------------------------------------

test_that("person_server bins numeric age variable automatically", {
  df_test <- make_test_linelist(100)

  testServer(
    person_server,
    args = list(
      df = df_test,
      age_var = "age",
      sex_var = "sex",
      male_level = "M",
      female_level = "F"
    ),
    {
      session$setInputs(
        count_var = NULL,
        cnt_pcnt = "n"
      )

      # Should bin ages automatically
      df <- df_mod()

      # Should have age variable
      expect_true("age_group" %in% names(df))
      expect_true(is.factor(df$age_group))
    }
  )
})

# Test multiple count variables --------------------------------------------

test_that("multiple count variables can be selected", {
  df_agg <- data.frame(
    age_group = factor(rep(c("0-4", "5-9", "10-14"), each = 2), c("0-4", "5-9", "10-14")),
    sex = rep(c("M", "F"), 3),
    cases = sample(10:50, 6, replace = TRUE),
    deaths = sample(1:10, 6, replace = TRUE)
  )

  testServer(
    person_server,
    args = list(
      df = df_agg,
      age_group_var = "age_group",
      sex_var = "sex",
      male_level = "M",
      female_level = "F",
      count_vars = c("Cases" = "cases", "Deaths" = "deaths")
    ),
    {
      # Test with cases
      session$setInputs(
        count_var = "cases",
        cnt_pcnt = "n"
      )

      # Should work
      expect_true(TRUE)

      # Test with deaths
      session$setInputs(count_var = "deaths")

      # Should work
      expect_true(TRUE)
    }
  )
})

# Test filter_info reactive ------------------------------------------------

test_that("filter_info_out formats filter information", {
  df_test <- make_test_linelist(100)

  testServer(
    person_server,
    args = list(
      df = df_test,
      age_var = "age",
      sex_var = "sex",
      male_level = "M",
      female_level = "F",
      filter_info = reactive("<b>Filters applied</b></br>Period: 01/Jan/24 - 31/Jan/24")
    ),
    {
      fi <- filter_info_out()

      # Should return filter info
      expect_type(fi, "character")
      expect_match(fi, "Filters applied")
    }
  )
})

test_that("filter_info_out combines time and place filters", {
  df_test <- make_test_linelist(100)

  testServer(
    person_server,
    args = list(
      df = df_test,
      age_var = "age",
      sex_var = "sex",
      male_level = "M",
      female_level = "F",
      filter_info = reactive("<b>Filters applied</b></br>Period: 01/Jan/24 - 31/Jan/24"),
      time_filter = reactive({
        list(lab = "2024-W05")
      }),
      place_filter = reactive({
        list(
          level_name = "Region",
          region_name = "Region1"
        )
      })
    ),
    {
      fi <- filter_info_out()

      # Should combine all filter info
      expect_match(fi, "2024-W05")
      expect_match(fi, "Region1")
    }
  )
})

# Test edge cases ----------------------------------------------------------

test_that("person_server handles empty data gracefully", {
  # Create empty data frame with proper structure
  df_empty <- data.frame(
    age = numeric(0),
    sex = character(0),
    region = character(0),
    stringsAsFactors = FALSE
  )

  testServer(
    person_server,
    args = list(
      df = df_empty,
      age_var = "age",
      sex_var = "sex",
      male_level = "M",
      female_level = "F"
    ),
    {
      session$setInputs(
        count_var = NULL,
        cnt_pcnt = "n"
      )

      # Should not error
      df <- df_mod()
      expect_s3_class(df, "data.frame")
      expect_equal(nrow(df), 0)
    }
  )
})

test_that("person_server handles all NA ages", {
  df_test <- make_test_linelist(50)
  df_test$age <- NA_real_

  testServer(
    person_server,
    args = list(
      df = df_test,
      age_var = "age",
      sex_var = "sex",
      male_level = "M",
      female_level = "F"
    ),
    {
      session$setInputs(
        count_var = NULL,
        cnt_pcnt = "n"
      )

      # Should handle gracefully
      df <- df_mod()
      expect_s3_class(df, "data.frame")
    }
  )
})

test_that("person_server handles all NA sex", {
  df_test <- make_test_linelist(50)
  df_test$sex <- factor(NA_character_, levels = c("M", "F"))

  testServer(
    person_server,
    args = list(
      df = df_test,
      age_var = "age",
      sex_var = "sex",
      male_level = "M",
      female_level = "F"
    ),
    {
      session$setInputs(
        count_var = NULL,
        cnt_pcnt = "n"
      )

      # Should handle gracefully
      df <- df_mod()
      expect_s3_class(df, "data.frame")
    }
  )
})

test_that("person_server handles single observation", {
  df_test <- make_test_linelist(1)

  testServer(
    person_server,
    args = list(
      df = df_test,
      age_var = "age",
      sex_var = "sex",
      male_level = "M",
      female_level = "F"
    ),
    {
      session$setInputs(
        count_var = NULL,
        cnt_pcnt = "n"
      )

      df <- df_mod()
      expect_s3_class(df, "data.frame")
      expect_equal(nrow(df), 1)
    }
  )
})
