# check additional deps are installed
pkg_deps <- c("rnaturalearth", "readr")
if (!rlang::is_installed(pkg_deps)) {
  rlang::check_installed(pkg_deps, reason = "to run this example.")
}

library(shiny)
library(bslib)
library(dplyr)
library(rnaturalearth)
library(sf)
# library(epishiny)
pkgload::load_all()

# weekly covid cases and deaths by country from WHO
url_covid <- "https://srhdpeuwpubsa.blob.core.windows.net/whdh/COVID/WHO-COVID-19-global-data.csv"
df_covid <- readr::read_csv(url_covid)

# get world map data as sf object
world_map <- rnaturalearth::ne_countries(
  scale = "small",
  type = "countries",
  returnclass = "sf"
) |>
  st_transform(crs = 4326) %>%
  select(iso_a2 = iso_a2_eh, name, pop_est)

# setup the geo layer for epishiny
geo_data <- geo_layer(
  layer_name = "Country",
  sf = world_map,
  name_var = "name",
  pop_var = "pop_est",
  join_by = c("iso_a2" = "Country_code") # iso_a2 in map joins to Country_code in covid data
)

# setup variables for app
count_vars <- c("Cases" = "New_cases", "Deaths" = "New_deaths")
date_vars <- c("Date" = "Date_reported")
group_vars <- c("WHO Region" = "WHO_region")
date_intervals <- c("Week", "Month", "Year")

# quick version using epi_dashboard() - see below for more customisable version using modules
app <- epi_dashboard(
  title = "{epishiny} COVID-19 dashboard",
  modules = c("time", "place"),
  df = df_covid,
  geo_data = geo_data,
  date_vars = date_vars,
  group_vars = group_vars,
  count_vars = count_vars,
  date_intervals = date_intervals,
  col_widths = 12,
  row_heights = c(2, 3)
)
# run the app
shiny::runApp(app)

# ui <- page_sidebar(
#   tags$head(
#     useBusyIndicators(),
#     tags$style(".bslib-page-main {gap: 10px !important;}")
#   ),
#   title = "epishiny covid19 dashboard",
#   class = "bslib-page-dashboard",
#   gap = 0,
#   sidebar = filter_ui(
#     id = "filter",
#     date_vars = date_vars,
#     group_vars = group_vars
#   ),
#   div(
#     class = "alert alert-primary p-1 m-0",
#     role = "alert",
#     paste(
#       "This dashboard visualises aggregate covid19",
#       "case and death data for the 19 countries with 100 000",
#       "or more deaths from 2020-2022."
#     )
#   ),
#   layout_columns(
#     col_widths = 12,
#     row_heights = c(2, 3),
#     gap = 10,
#     time_ui(
#       id = "time",
#       date_vars = date_vars,
#       count_vars = count_vars,
#       group_vars = group_vars,
#       date_intervals = c("week", "month", "year"),
#       use_sidebar = TRUE
#     ),
#     place_ui(
#       id = "place",
#       geo_data = geo_data,
#       count_vars = count_vars,
#       use_sidebar = TRUE
#     )
#   )
# )

# server <- function(input, output, session) {
#   app_data <- filter_server(
#     id = "filter",
#     df = df_covid,
#     date_vars = date_vars,
#     group_vars = group_vars,
#     place_filter = map_click,
#     time_filter = bar_click
#   )

#   bar_click <- time_server(
#     id = "time",
#     df = app_data$df,
#     date_vars = date_vars,
#     count_vars = count_vars,
#     group_vars = group_vars,
#     show_ratio = TRUE,
#     ratio_lab = "CFR",
#     ratio_numer = "deaths",
#     ratio_denom = "cases",
#     place_filter = map_click,
#     filter_info = app_data$filter_info
#   )

#   map_click <- place_server(
#     id = "place",
#     df = app_data$df,
#     geo_data = geo_data,
#     count_vars = count_vars,
#     time_filter = bar_click,
#     filter_info = app_data$filter_info
#   )
# }

# if (interactive()) {
#   shinyApp(ui, server)
# }
