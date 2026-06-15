#' Expect valid epishiny color palette
#'
#' @param pal Character vector of color codes
#' @param n Expected number of colors
expect_valid_palette <- function(pal, n) {
  expect_type(pal, "character")
  expect_length(pal, n)
  expect_true(all(grepl("^#[0-9A-F]{6}[0-9A-F]{2}?$", pal, ignore.case = TRUE)))
}

#' Expect valid geo_layer structure
#'
#' @param obj Object to test
expect_geo_layer <- function(obj) {
  expect_s3_class(obj, "epishiny_geo_layer")
  expect_named(obj, c("layer_name", "sf", "name_var", "pop_var", "join_by"))
  expect_s3_class(obj$sf, "sf")
}

#' Expect epi week format (e.g., "2024-W15")
#'
#' @param string String to test
expect_epi_week_format <- function(string) {
  expect_match(string, "^\\d{4}-[A-Z]\\d{1,2}$")
}

#' Expect data frame has required columns
#'
#' @param df Data frame to test
#' @param cols Character vector of required column names
expect_has_columns <- function(df, cols) {
  expect_s3_class(df, "data.frame")
  missing_cols <- setdiff(cols, names(df))
  expect_true(
    length(missing_cols) == 0,
    info = paste("Missing columns:", paste(missing_cols, collapse = ", "))
  )
}
