# Person module

Visualise age and sex demographics in a population pyramid chart and
summary table.

## Usage

``` r
person_ui(
  id,
  count_vars = NULL,
  title = "Person",
  icon = bsicons::bs_icon("people-fill"),
  opts_btn_lab = "Options",
  count_vars_lab = "Indicator",
  full_screen = TRUE,
  age_breaks_lab = "Age breaks",
  age_breaks_help = "Comma-separated values (e.g., 0, 5, 18, 25, 35, 50)",
  age_breaks_apply_lab = "Apply breaks",
  use_sidebar = FALSE,
  sidebar_title = NULL,
  sidebar_width = 250
)

person_server(
  id,
  df,
  sex_var,
  male_level,
  female_level,
  age_group_var = NULL,
  age_var = NULL,
  count_vars = NULL,
  age_breaks = c(0, 5, 18, 25, 35, 50, Inf),
  age_labels = label_breaks(age_breaks, lab_accuracy = 1),
  age_var_lab = "Age (years)",
  age_group_lab = "Age group",
  colours = epi_pals()$frost[1:2],
  filter_info = shiny::reactiveVal(),
  time_filter = shiny::reactiveVal(),
  place_filter = shiny::reactiveVal()
)
```

## Arguments

- id:

  Module id. Must be the same in both the UI and server function to link
  the two.

- count_vars:

  If data is aggregated, variable name(s) of count variable(s) in data.
  If more than one variable is provided, a select input will appear in
  the options menu. If named, names are used as variable labels.

- title:

  The title for the card.

- icon:

  The icon to display next to the title.

- opts_btn_lab:

  The label for the options button.

- count_vars_lab:

  text label for the aggregate count variables input.

- full_screen:

  Add button to card to with the option to enter full screen mode?

- age_breaks_lab:

  The label for the age breaks input.

- age_breaks_help:

  Help text for the age breaks input.

- age_breaks_apply_lab:

  The label for the apply breaks button.

- use_sidebar:

  Logical. If TRUE, displays options in a sidebar instead of popover
  button. Default FALSE.

- sidebar_title:

  String. Title for the sidebar. Only used if use_sidebar = TRUE.
  Default NULL.

- sidebar_width:

  Numeric. Width of sidebar in pixels. Only used if use_sidebar = TRUE.
  Default 250.

- df:

  Data frame or tibble of patient level or aggregated data. Can be
  either a shiny reactive or static dataset.

- sex_var:

  The name of the sex variable in the data.

- male_level:

  The level representing males in the sex variable.

- female_level:

  The level representing females in the sex variable.

- age_group_var:

  The name of a character/factor variable in the data with age groups.
  If specified, `age_var` is ignored.

- age_var:

  The name of a numeric age variable in the data. If ages have already
  been binned into groups, use `age_group_var` instead.

- age_breaks:

  A numeric vector specifying default age breaks for age groups. Users
  can modify these via the options menu when using numeric age data.

- age_labels:

  Labels corresponding to the age breaks.

- age_var_lab:

  The label for the age variable.

- age_group_lab:

  The label for the age group variable.

- colours:

  Vector of 2 colours to represent male and female, respectively.

- filter_info:

  If contained within an app using
  [`filter_server()`](https://epicentre-msf.github.io/epishiny/reference/filter.md),
  supply the `filter_info` object returned by that function here to add
  filter information to chart exports.

- time_filter:

  supply the output of
  [`time_server()`](https://epicentre-msf.github.io/epishiny/reference/time.md)
  here to filter the data by click events on the time module bar chart
  (clicking a bar will filter the data to the period the bar represents)

- place_filter:

  supply the output of
  [`place_server()`](https://epicentre-msf.github.io/epishiny/reference/place.md)
  here to filter the data by click events on the place module map
  (clicking a polygon will filter the data to the clicked region)

## Value

A
[bslib::navset_card_tab](https://rstudio.github.io/bslib/reference/navset.html)
UI element with chart and table tabs.

## Examples

``` r
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
```
