library(shiny)
library(bslib)
library(epishiny)

# example package data
data("df_ll_ebola") # linelist
data("sf_sle") # sf geo boundaries for Sierra Leone admin 3 & 4

# setup geo data for admin 3 and admin 4 using the
# geo_layer function to be passed to the place module
# if population variable is provided, attack rates
# will be shown on the map as a choropleth
geo_data <- list(
  geo_layer(
    layer_name = "Admin 3", # name of the boundary level
    sf = sf_sle$adm3, # sf object with boundary polygons
    name_var = "adm3_name", # column with place names
    pop_var = "adm3_pop", # column with population data (optional)
    join_by = c("pcode" = "adm3_pcode") # geo to data join vars: LHS = sf, RHS = data
  ),
  geo_layer(
    layer_name = "Admin 4",
    sf = sf_sle$adm4,
    name_var = "adm4_name",
    join_by = c("pcode" = "adm4_pcode")
  )
)

# define date variables in data as named list to be used in app
date_vars <- c(
  "Date of onset" = "date_of_onset",
  "Date of hospitalisation" = "date_of_hospitalisation",
  "Date of infection" = "date_of_infection",
  "Date of outcome" = "date_of_outcome"
)

# define categorical grouping variables
# in data as named list to be used in app
group_vars <- c(
  "Hospital" = "hospital",
  "Gender" = "gender",
  "Outcome" = "outcome"
)

# user interface
ui <- page_sidebar(
  title = "epishiny",
  # sidebar
  sidebar = filter_ui(
    "filter",
    date_vars = date_vars,
    group_vars = group_vars
  ),
  # main content
  layout_columns(
    col_widths = c(12, 7, 5),
    place_ui(
      id = "map",
      geo_data = geo_data,
      group_vars = group_vars
    ),
    time_ui(
      id = "curve",
      title = "Time",
      date_vars = date_vars,
      group_vars = group_vars,
      ratio_line_lab = "Show CFR line?"
    ),
    person_ui(id = "age_sex")
  )
)

# app server
server <- function(input, output, session) {
  app_data <- filter_server(
    id = "filter",
    df = df_ll_ebola,
    date_vars = date_vars,
    group_vars = group_vars
  )
  place_server(
    id = "map",
    df = app_data$df,
    geo_data = geo_data,
    group_vars = group_vars,
    filter_info = app_data$filter_info
  )
  time_server(
    id = "curve",
    df = app_data$df,
    date_vars = date_vars,
    group_vars = group_vars,
    show_ratio = TRUE,
    ratio_var = "outcome",
    ratio_lab = "CFR",
    ratio_numer = "Death",
    ratio_denom = c("Death", "Recover"),
    filter_info = app_data$filter_info
  )
  person_server(
    id = "age_sex",
    df = app_data$df,
    age_var = "age",
    sex_var = "gender",
    male_level = "m",
    female_level = "f",
    filter_info = app_data$filter_info
  )
}

# launch app
if (interactive()) {
  shinyApp(ui, server)
}
