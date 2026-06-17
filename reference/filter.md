# Filter module

Filter linelist data using a sidebar with shiny inputs.

## Usage

``` r
filter_ui(
  id,
  date_vars = NULL,
  group_vars = NULL,
  title = "Filters",
  date_filters_lab = "Date filters",
  missing_dates_lab = "Include patients with missing dates?",
  group_filters_lab = "Group filters",
  filter_btn_lab = "update",
  filter_btn_tooltip = "Click here to apply filters and update the graphics",
  reset_btn_lab = "Reset",
  bg = "#fff",
  wrapper = function(...) bslib::sidebar(..., id = id, bg = bg)
)

filter_server(
  id,
  df,
  date_vars = NULL,
  group_vars = NULL,
  time_filter = shiny::reactiveVal(),
  place_filter = shiny::reactiveVal(),
  reset = shiny::reactiveVal()
)
```

## Arguments

- id:

  Module id. Must be the same in both the UI and server function to link
  the two.

- date_vars:

  named character vector of date variables in the data frame to be
  filtered on. Names are used as labels, values as column names.

- group_vars:

  named character vector of categorical variables for the data grouping
  input. Names are used as variable labels.

- title:

  The title of the sidebar.

- date_filters_lab:

  The label for the date filters accordion panel.

- missing_dates_lab:

  The label for the include missing dates switch (only shown for single
  date variable).

- group_filters_lab:

  The label for the group filters accordion panel.

- filter_btn_lab:

  The label for the filter data button.

- filter_btn_tooltip:

  The tooltip for the filter data button.

- reset_btn_lab:

  The label for the reset filters button.

- bg:

  The background color of the sidebar.

- wrapper:

  A function that wraps the sidebar UI elements. Defaults to
  [bslib::sidebar](https://rstudio.github.io/bslib/reference/sidebar.html).
  Change if you don't want the filter UI to be a sidebar.

- df:

  Data frame or tibble of patient level or aggregated data. Can be
  either a shiny reactive or static dataset.

- time_filter:

  supply the output of
  [`time_server()`](https://epicentre-msf.github.io/epishiny/reference/time.md)
  here to add its filter information to the filter sidebar

- place_filter:

  supply the output of
  [`place_server()`](https://epicentre-msf.github.io/epishiny/reference/place.md)
  here to add its filter information to the filter sidebar

- reset:

  A [`shiny::reactive()`](https://rdrr.io/pkg/shiny/man/reactive.html)
  or
  [`shiny::reactiveVal()`](https://rdrr.io/pkg/shiny/man/reactiveVal.html)
  used as an external trigger to reset all filter inputs to their
  initial values, clear the displayed filter info, and return the
  unfiltered dataset. The reset fires whenever the reactive emits a
  non-`NULL` value (e.g. update it with
  [`Sys.time()`](https://rdrr.io/r/base/Sys.time.html) or an
  incrementing counter from an `actionButton`). The same value is
  propagated to the returned `filter_reset` reactive so that connected
  modules (time, place) can clear their own click filters.

## Value

A UI `wrapper` with date filters, group filters, and action buttons.

The server function returns a list containing reactive functions named
`df` and `filter_info`. Access these as `app_data$df` and
`app_data$filter_info` (not `app_data()$df`). These can be passed
directly to the time, place, and person modules.

## Examples

``` r
library(shiny)
library(bslib)
#> 
#> Attaching package: ‘bslib’
#> The following object is masked from ‘package:utils’:
#> 
#>     page
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
