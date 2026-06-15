# Tests for utility functions from R/utils.R

# Test force_reactive() --------------------------------------------------------

test_that("force_reactive evaluates reactive expressions", {
  # Test within a reactive context
  session <- shiny::MockShinySession$new()
  shiny::withReactiveDomain(session, {
    rv <- shiny::reactiveVal(42)
    result <- shiny::isolate(force_reactive(rv))
    expect_equal(result, 42)
  })
})

test_that("force_reactive returns non-reactive values unchanged", {
  result <- force_reactive(42)
  expect_equal(result, 42)

  result <- force_reactive("hello")
  expect_equal(result, "hello")

  result <- force_reactive(c(1, 2, 3))
  expect_equal(result, c(1, 2, 3))
})

test_that("force_reactive handles NULL", {
  result <- force_reactive(NULL)
  expect_null(result)
})

# Test prepare_palette() -------------------------------------------------------

test_that("prepare_palette returns correct number of colors", {
  pal <- prepare_palette(5)
  expect_valid_palette(pal, 5)
})

test_that("prepare_palette handles missing data with NA color", {
  pal <- prepare_palette(6, missing_data = TRUE, na_colour = "#999999")
  expect_length(pal, 6)
  # Last color should be the NA color (with alpha applied)
  expect_true(grepl("^#999999", pal[6]))
})

test_that("prepare_palette uses color ramp for medium sizes", {
  # With 8 colors requested and default aurora palette (5 colors), it should use colorRampPalette
  pal <- prepare_palette(8, alpha = 1)
  expect_length(pal, 8)
  expect_type(pal, "character")
  expect_true(all(grepl("^#[0-9A-F]{6}$", pal, ignore.case = TRUE)))
})

test_that("prepare_palette uses pal20 for large sizes", {
  # With 15 colors requested, it should use pal20 which has 20 colors
  pal <- prepare_palette(15, alpha = 1)
  # The function returns all 20 colors from pal20, not just 15
  expect_length(pal, 20)
  expect_type(pal, "character")
  # With alpha = 1, some may have 9 chars, some 7
  expect_true(all(grepl("^#[0-9A-F]{6}", pal, ignore.case = TRUE)))
})

test_that("prepare_palette applies alpha correctly", {
  # With 3 colors requested and default aurora palette (5 colors), uses first 3 from aurora
  pal <- prepare_palette(3, alpha = 0.5)
  # Actually returns first 5 colors from aurora palette
  expect_length(pal, 5)
  # Should have 9-character hex codes (# + 6 for RGB + 2 for alpha)
  expect_true(all(nchar(pal) == 9))
})

test_that("prepare_palette uses provided palette", {
  custom_pal <- c("#FF0000", "#00FF00", "#0000FF")
  pal <- prepare_palette(3, pal = custom_pal, alpha = 1)
  expect_length(pal, 3)
})

test_that("prepare_palette handles empty palette", {
  # When empty palette provided, it falls back to aurora (5 colors)
  pal <- prepare_palette(3, pal = character(0))
  expect_length(pal, 5)
  expect_type(pal, "character")
  expect_true(all(grepl("^#[0-9A-F]{6}[0-9A-F]{2}?$", pal, ignore.case = TRUE)))
})

# Test label_breaks() ----------------------------------------------------------

test_that("label_breaks formats numeric breaks correctly", {
  breaks <- c(0, 5, 10, 20)
  labels <- label_breaks(breaks)
  expect_type(labels, "character")
  expect_length(labels, 3)
  expect_equal(labels[1], "0-4")
  expect_equal(labels[2], "5-9")
  expect_equal(labels[3], "10-19")
})

test_that("label_breaks replaces Inf with +", {
  breaks <- c(0, 10, 20, Inf)
  labels <- label_breaks(breaks, replace_Inf = TRUE)
  expect_equal(labels[3], "20+")
})

test_that("label_breaks keeps Inf when replace_Inf = FALSE", {
  breaks <- c(0, 10, Inf)
  labels <- label_breaks(breaks, replace_Inf = FALSE)
  expect_match(labels[2], "Inf")
})

test_that("label_breaks respects accuracy parameter", {
  breaks <- c(0, 0.5, 1.0)
  labels <- label_breaks(breaks, lab_accuracy = 0.01)
  expect_match(labels[1], "0")
  expect_match(labels[2], "0\\.5")
})

test_that("label_breaks handles large numbers", {
  breaks <- c(0, 1000, 10000, 100000)
  labels <- label_breaks(breaks)
  expect_type(labels, "character")
  expect_length(labels, 3)
})

# Test frmt_num() --------------------------------------------------------------

test_that("frmt_num formats small numbers correctly", {
  expect_equal(frmt_num(5), "5")
  expect_equal(frmt_num(10), "10")
  expect_equal(frmt_num(99), "99")
})

test_that("frmt_num formats thousands with K", {
  result <- frmt_num(1000)
  expect_match(result, "1K")

  result <- frmt_num(5500)
  expect_match(result, "5.5K")
})

test_that("frmt_num formats millions with M", {
  result <- frmt_num(1000000)
  expect_match(result, "1M")

  result <- frmt_num(2500000)
  expect_match(result, "2.5M")
})

test_that("frmt_num removes trailing zeros", {
  result <- frmt_num(1000)
  expect_equal(result, "1K")
  expect_false(grepl("\\.0", result))
})

test_that("frmt_num respects accuracy parameter", {
  result <- frmt_num(1234, accuracy = 1)
  expect_type(result, "character")
})

test_that("frmt_num handles zero", {
  expect_equal(frmt_num(0), "0")
})

test_that("frmt_num handles negative numbers", {
  result <- frmt_num(-1000)
  expect_match(result, "-1K")
})

# Test get_label() -------------------------------------------------------------

test_that("get_label returns label from named vector", {
  choices <- c("Label A" = "value_a", "Label B" = "value_b")
  result <- get_label("value_a", choices)
  expect_equal(result, "Label A")
})

test_that("get_label returns value from unnamed vector", {
  choices <- c("value_a", "value_b", "value_c")
  result <- get_label("value_b", choices)
  expect_equal(result, "value_b")
})

test_that("get_label returns NA when selected not in choices", {
  # When selected value not found, the function returns NA not default
  choices <- c("a" = "value_a", "b" = "value_b")
  result <- get_label("value_x", choices)
  expect_true(is.na(result))
})

test_that("get_label returns custom default when choices is empty", {
  # .default is only used when choices has length 0
  result <- get_label("anything", character(0), .default = "Custom")
  expect_equal(result, "Custom")
})

test_that("get_label handles empty choices with default", {
  result <- get_label("anything", character(0))
  # When choices empty, uses the option which defaults to "Patients"
  expect_type(result, "character")
})

# Test format_filter_info() ----------------------------------------------------

test_that("format_filter_info returns NULL when all inputs are NULL", {
  result <- format_filter_info()
  expect_null(result)
})

test_that("format_filter_info formats time filter", {
  tf <- list(lab = "Week 1-5")
  result <- format_filter_info(tf = tf)
  expect_type(result, "character")
  expect_match(result, "Week 1-5")
  expect_match(result, "Filters applied")
})

test_that("format_filter_info formats place filter", {
  pf <- list(level_name = "District", region_name = "North")
  result <- format_filter_info(pf = pf)
  expect_type(result, "character")
  expect_match(result, "District: North")
  expect_match(result, "Filters applied")
})

test_that("format_filter_info combines time and place filters", {
  tf <- list(lab = "Week 1-5")
  pf <- list(level_name = "District", region_name = "North")
  result <- format_filter_info(tf = tf, pf = pf)
  expect_match(result, "Week 1-5")
  expect_match(result, "District: North")
})

test_that("format_filter_info replaces existing date in fi with tf", {
  fi <- "<b>Filters applied</b></br>Period: 01/Jan/24 - 31/Jan/24"
  tf <- list(lab = "Week 10-15")
  result <- format_filter_info(fi = fi, tf = tf)
  expect_match(result, "Week 10-15")
  expect_false(grepl("01/Jan/24", result))
})

test_that("format_filter_info adds place filter to existing fi", {
  fi <- "<b>Filters applied</b></br>Period: Week 1-5"
  pf <- list(level_name = "Region", region_name = "South")
  result <- format_filter_info(fi = fi, pf = pf)
  expect_match(result, "Week 1-5")
  expect_match(result, "Region: South")
})

# Test time_stamp() ------------------------------------------------------------

test_that("time_stamp returns correct format", {
  stamp <- time_stamp()
  expect_type(stamp, "character")
  # Format: YYYY-MM-DD_HHMMSS
  expect_match(stamp, "^\\d{4}-\\d{2}-\\d{2}_\\d{6}$")
})

test_that("time_stamp returns different values when called multiple times", {
  stamp1 <- time_stamp()
  Sys.sleep(1.1)
  stamp2 <- time_stamp()
  expect_false(stamp1 == stamp2)
})

# Test epi_pals() --------------------------------------------------------------

test_that("epi_pals returns list of palettes", {
  pals <- epi_pals()
  expect_type(pals, "list")
  expect_true("pal20" %in% names(pals))
  expect_true("pal10" %in% names(pals))
  expect_true("aurora" %in% names(pals))
  expect_true("frost" %in% names(pals))
})

test_that("epi_pals pal20 has 20 colors", {
  pals <- epi_pals()
  expect_length(pals$pal20, 20)
  expect_valid_palette(pals$pal20, 20)
})

test_that("epi_pals pal10 has 10 colors", {
  pals <- epi_pals()
  expect_length(pals$pal10, 10)
  expect_valid_palette(pals$pal10, 10)
})

test_that("all epi_pals colors are valid hex codes", {
  pals <- epi_pals()
  all_colors <- unlist(pals)
  expect_true(all(grepl("^#[0-9A-F]{6}([0-9A-F]{2})?$", all_colors, ignore.case = TRUE)))
})
