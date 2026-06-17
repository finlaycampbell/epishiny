# Create a custom epishiny dashboard

Build a complete epishiny dashboard with your choice of modules (time,
place, person, filter). This function generates a shiny app with the
selected modules and handles all the boilerplate UI and server code.

## Usage

``` r
epi_dashboard(
  df,
  modules = c("place", "time", "person"),
  include_filter = TRUE,
  title = "epishiny dashboard",
  theme = bslib::bs_theme(),
  col_widths = NULL,
  row_heights = 1,
  language = "en",
  include_language_selector = NULL,
  ...
)
```

## Arguments

- df:

  Data frame or tibble of patient level or aggregated data.

- modules:

  Character vector specifying which modules to include and their order
  in the layout. Valid values are `"time"`, `"place"`, and `"person"`.
  Default is `c("place", "time", "person")`. The order of the vector
  determines both which modules appear and their layout order. Examples:

  - `c("time", "place", "person")` - All modules with time first

  - `c("place", "time")` - Only map and time series (no demographics)

  - `c("time")` - Only time series module

- include_filter:

  Logical. Include the filter sidebar? Default TRUE.

- title:

  Character. Title for the dashboard. Default "epishiny dashboard".

- theme:

  A bslib theme object to customize the appearance of the dashboard.
  Default is
  [`bslib::bs_theme()`](https://rstudio.github.io/bslib/reference/bs_theme.html).

- col_widths:

  Numeric vector specifying the column widths for the layout. If NULL
  (default), widths are automatically assigned based on number of
  modules. Use in combination with `modules` to control layout. Example:
  `col_widths = c(12, 7, 5)` with
  `modules = c("time", "place", "person")` puts time on full width row,
  then place (7 cols) and person (5 cols) on second row.

- row_heights:

  Numeric vector specifying the row heights for the layout. Default is 1
  (equal heights).

- language:

  Two-letter language code for UI translations (e.g. `"en"`, `"fr"`).
  See
  [`init_epishiny_i18n()`](https://epicentre-msf.github.io/epishiny/reference/init_epishiny_i18n.md)
  and
  [`set_epishiny_language()`](https://epicentre-msf.github.io/epishiny/reference/set_epishiny_language.md).

- include_language_selector:

  Logical. Show a language selector in the dashboard header? Default
  `TRUE` when more than one language is available.

- ...:

  Named arguments to pass to the individual module UI and server
  functions. Arguments will be matched to their appropriate modules. See
  [`time_ui()`](https://epicentre-msf.github.io/epishiny/reference/time.md),
  [`time_server()`](https://epicentre-msf.github.io/epishiny/reference/time.md),
  [`place_ui()`](https://epicentre-msf.github.io/epishiny/reference/place.md),
  [`place_server()`](https://epicentre-msf.github.io/epishiny/reference/place.md),
  [`person_ui()`](https://epicentre-msf.github.io/epishiny/reference/person.md),
  [`person_server()`](https://epicentre-msf.github.io/epishiny/reference/person.md),
  [`filter_ui()`](https://epicentre-msf.github.io/epishiny/reference/filter.md),
  [`filter_server()`](https://epicentre-msf.github.io/epishiny/reference/filter.md)
  for details on available arguments.

## Value

A shiny app object that can be passed to
[`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html) or run
directly if in interactive mode.

## Examples

``` r
if (FALSE) { # \dontrun{
library(epishiny)
data("df_ll")
data("sf_yem")

# Setup geo data
geo_data <- geo_layer(
  layer_name = "Governorate",
  sf = sf_yem$adm1,
  name_var = "adm1_name",
  pop_var = "adm1_pop",
  join_by = c("pcode" = "adm1_pcode")
)

# Create dashboard with all modules (default)
app <- dashboard(
  df = df_ll,
  date_vars = c("Date of notification" = "date_notification"),
  group_vars = c("Sex" = "sex_id"),
  geo_data = geo_data,
  age_var = "age_years",
  sex_var = "sex_id",
  male_level = "Male",
  female_level = "Female"
)

# Time on top row, place and person below
app_time_focus <- dashboard(
  df = df_ll,
  title = "Time Series Focus",
  modules = c("time", "place", "person"),
  col_widths = c(12, 7, 5),
  date_vars = c("Date of notification" = "date_notification"),
  group_vars = c("Sex" = "sex_id"),
  geo_data = geo_data,
  age_var = "age_years",
  sex_var = "sex_id",
  male_level = "Male",
  female_level = "Female"
)

# Only time and person modules (no map)
app_simple <- dashboard(
  df = df_ll,
  title = "Time & Demographics",
  modules = c("time", "person"),
  date_vars = c("Date of notification" = "date_notification"),
  age_var = "age_years",
  sex_var = "sex_id",
  male_level = "Male",
  female_level = "Female"
)

# Run the dashboard
if (interactive()) {
  shiny::runApp(app_time_focus)
}
} # }
```
