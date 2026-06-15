#' Create test linelist data
#'
#' @param n Number of rows to generate
#' @param seed Random seed for reproducibility
#' @return A data.frame with linelist structure
make_test_linelist <- function(n = 100, seed = 123) {
  set.seed(seed)
  if (n == 0) {
    data.frame(
      id = integer(0),
      date = as.Date(character(0)),
      date_onset = as.Date(character(0)),
      age = integer(0),
      sex = character(0),
      region = character(0),
      outcome = character(0),
      adm1_pcode = character(0),
      stringsAsFactors = FALSE
    )
  } else {
    data.frame(
      id = 1:n,
      date = seq(as.Date("2024-01-01"), by = "day", length.out = n),
      date_onset = as.Date("2024-01-01") + sample(0:n, n, replace = TRUE) - sample(0:5, n, replace = TRUE),
      age = sample(0:80, n, replace = TRUE),
      sex = sample(c("M", "F", NA), n, replace = TRUE, prob = c(0.48, 0.48, 0.04)),
      region = sample(paste0("Region", 1:5), n, replace = TRUE),
      outcome = sample(c("Death", "Recovery", "Unknown"), n, replace = TRUE, prob = c(0.1, 0.8, 0.1)),
      adm1_pcode = sample(paste0("YE", 1:5), n, replace = TRUE),
      stringsAsFactors = FALSE
    )
  }
}

#' Create test aggregated data
#'
#' @param n_dates Number of dates
#' @param n_regions Number of regions
#' @return A data.frame with aggregated case counts
make_test_aggregated <- function(n_dates = 30, n_regions = 5) {
  expand.grid(
    date = seq(as.Date("2024-01-01"), by = "day", length.out = n_dates),
    region = paste0("Region", 1:n_regions),
    stringsAsFactors = FALSE
  ) |>
    dplyr::mutate(
      cases = sample(0:20, dplyr::n(), replace = TRUE),
      deaths = purrr::map_int(cases, ~ sample(0:.x, 1))
    )
}

#' Create simple sf polygon data for testing
#'
#' @param n Number of polygons
#' @param crs Coordinate reference system
#' @return An sf object with simple square polygons
make_test_sf <- function(n = 5, crs = 4326) {
  # Create list of polygon coordinates (each polygon needs a list of matrices)
  coords <- lapply(1:n, function(i) {
    # Create a square polygon: x and y coordinates
    list(matrix(c(i, i, i + 1, i + 1, i, i, i + 1, i + 1, i, i), ncol = 2))
  })

  sf::st_sf(
    id = paste0("R", 1:n),
    name = paste0("Region", 1:n),
    pop = sample(1000:5000, n),
    geometry = sf::st_sfc(lapply(coords, sf::st_polygon)),
    crs = crs
  )
}
