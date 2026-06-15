#' Create test linelist data
#'
#' @param n Number of rows to generate
#' @param seed Random seed for reproducibility
#' @return A data.frame with linelist structure
make_test_linelist <- function(n = 100, seed = 123) {
  set.seed(seed)

  # Handle n=0 case - return empty data frame with correct structure
  if (n == 0) {
    return(data.frame(
      id = integer(),
      date = as.Date(character()),
      date_onset = as.Date(character()),
      age = integer(),
      sex = character(),
      region = character(),
      outcome = character(),
      adm1_pcode = character(),
      stringsAsFactors = FALSE
    ))
  }

  data.frame(
    id = seq_len(n),
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
#' @param join_col Optional join column name to add (e.g., "region", "district")
#' @return An sf object with simple square polygons
make_test_sf <- function(n = 5, crs = 4326, join_col = NULL) {
  # Create list of polygon coordinates (each polygon needs a list of matrices)
  coords <- lapply(1:n, function(i) {
    # Create a square polygon: x and y coordinates
    list(matrix(c(i, i, i+1, i+1, i, i, i+1, i+1, i, i), ncol = 2))
  })

  sf_df <- data.frame(
    id = paste0("R", 1:n),
    name = paste0("Region", 1:n),
    pop = sample(1000:5000, n),
    stringsAsFactors = FALSE
  )

  # Add optional join column if requested
  if (!is.null(join_col)) {
    sf_df[[join_col]] <- paste0("Region", 1:n)
  }

  sf::st_sf(
    sf_df,
    geometry = sf::st_sfc(lapply(coords, sf::st_polygon)),
    crs = crs
  )
}
