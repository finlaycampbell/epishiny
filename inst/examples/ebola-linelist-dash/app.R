library(shiny)
library(bslib)
library(sf)
if (basename(getwd()) == "epishiny") {
  pkgload::load_all()
} else {
  library(epishiny)
}

geo_data <- list(
  geo_layer(
    layer_name = "Admin 3",
    sf = sf_sle$adm3,
    name_var = "adm3_name",
    pop_var = "adm3_pop",
    join_by = c("pcode" = "adm3_pcode") # geo to data join vars: LHS = sf, RHS = data
  ),
  geo_layer(
    layer_name = "Admin 4",
    sf = sf_sle$adm4,
    name_var = "adm4_name",
    pop_var = "adm4_pop",
    join_by = c("pcode" = "adm4_pcode") # geo to data join vars: LHS = sf, RHS = data
  )
)

# define date variables in data as named list to be used in app
date_vars <- c(
  "Date of hospitalisation" = "date_of_hospitalisation",
  "Date of infection" = "date_of_infection",
  "Date of onset" = "date_of_onset",
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
  useBusyIndicators(),
  class = "bslib-page-dashboard",
  title = "epishiny",
  # sidebar
  sidebar = filter_ui(
    id = "filter",
    date_vars = date_vars,
    group_vars = group_vars
  ),
  # main content
  layout_columns(
    col_widths = c(12, 7, 5),
    row_heights = c(2, 3),
    gap = 10,
    time_ui(
      id = "time",
      title = "Time",
      date_vars = date_vars,
      group_vars = group_vars,
      ratio_line_lab = "Show CFR line?",
      use_sidebar = TRUE
    ),
    place_ui(
      id = "place",
      geo_data = geo_data,
      group_vars = group_vars,
      use_sidebar = TRUE
    ),
    person_ui(
      id = "person",
      use_sidebar = FALSE
    )
  )
)

# app server
server <- function(input, output, session) {
  app_data <- filter_server(
    id = "filter",
    df = df_ll_ebola,
    date_vars = date_vars,
    group_vars = group_vars,
    time_filter = bar_click,
    place_filter = map_click
  )
  map_click <- place_server(
    id = "place",
    df = app_data$df,
    geo_data = geo_data,
    group_vars = group_vars,
    time_filter = bar_click,
    filter_info = app_data$filter_info
  )
  bar_click <- time_server(
    id = "time",
    df = app_data$df,
    date_vars = date_vars,
    group_vars = group_vars,
    show_ratio = TRUE,
    ratio_var = "outcome",
    ratio_lab = "CFR",
    ratio_numer = "Death",
    ratio_denom = c("Death", "Recover"),
    place_filter = map_click,
    filter_info = app_data$filter_info
  )
  person_server(
    id = "person",
    df = app_data$df,
    age_var = "age",
    # age_breaks = c(seq(0, 50, by = 5), Inf), # 5 year intervals
    sex_var = "gender",
    male_level = "m",
    female_level = "f",
    time_filter = bar_click,
    place_filter = map_click,
    filter_info = app_data$filter_info
  )
}

# launch app
shinyApp(ui, server)
