# Time module

Visualise data over time with an interactive 'epicurve'.

## Usage

``` r
time_ui(
  id,
  date_vars,
  count_vars = NULL,
  group_vars = NULL,
  group_var_default = NULL,
  title = "Time",
  icon = bsicons::bs_icon("calendar2-week"),
  tooltip = NULL,
  opts_btn_lab = "Chart options",
  date_lab = "Date axis",
  date_int_lab = "Date interval",
  date_intervals = c(Day = "day", Week = "week", Month = "month"),
  date_interval_default = ifelse("week" %in% date_intervals, "week", date_intervals[1]),
  count_vars_lab = "Indicator",
  groups_lab = "Group data by",
  no_grouping_lab = "No grouping",
  bar_stacking_lab = "Bar stacking",
  cumul_data_lab = "Show cumulative data?",
  ratio_line_lab = "Show ratio line?",
  zoom_control_lab = "Add zoom control slider?",
  full_screen = TRUE,
  use_sidebar = TRUE,
  sidebar_title = NULL,
  sidebar_width = 250
)

time_server(
  id,
  df,
  date_vars,
  count_vars = NULL,
  group_vars = NULL,
  show_ratio = FALSE,
  ratio_var = NULL,
  ratio_lab = NULL,
  ratio_numer = NULL,
  ratio_denom = NULL,
  group_pal = epi_pals()$frost,
  na_colour = "#666666",
  place_filter = shiny::reactiveVal(),
  filter_info = shiny::reactiveVal(),
  filter_reset = shiny::reactiveVal()
)
```

## Arguments

- id:

  Module id. Must be the same in both the UI and server function to link
  the two.

- date_vars:

  Character vector of date variable(s) for the date axis. If named,
  names are used as variable labels.

- count_vars:

  If data is aggregated, variable name(s) of count variable(s) in data.
  If more than one variable provided, a select input will appear in the
  options dropdown. If named, names are used as variable labels.

- group_vars:

  Character vector of categorical variable names. If provided, a select
  input will appear in the options dropdown allowing for data groups to
  be visualised as stacked bars on the epicurve. If named, names are
  used as variable labels.

- group_var_default:

  Character string of variable name in `group_vars` to use as default
  grouping variable. If NULL, no default is set and "No grouping" option
  will be selected by default.

- title:

  Header title for the card.

- icon:

  The icon to display next to the title.

- tooltip:

  additional title hover text information

- opts_btn_lab:

  text label for the dropdown menu button.

- date_lab:

  text label for the date variable input.

- date_int_lab:

  text label for the date interval input.

- date_intervals:

  Character vector with choices for date aggregation intervals passed to
  the `unit` argument of
  [lubridate::floor_date](https://lubridate.tidyverse.org/reference/round_date.html).
  If named, names are used as labels. Default is c('day', 'week',
  'year').

- date_interval_default:

  Character string of default date interval to use. Must be one of the
  values provided in `date_intervals`. Defaults to "week" if available,
  otherwise the first value in `date_intervals`.

- count_vars_lab:

  text label for the aggregate count variables input.

- groups_lab:

  text label for the grouping variable input.

- no_grouping_lab:

  text label for the no grouping option in the grouping input.

- bar_stacking_lab:

  text label for bar stacking option.

- cumul_data_lab:

  text label for cumulative data option.

- ratio_line_lab:

  text label for the ratio line input. This input will only be visable
  if `show_ratio` is TRUE in time_server

- zoom_control_lab:

  text label for the zoom control option.

- full_screen:

  Add button to card to with the option to enter full screen mode?

- use_sidebar:

  Logical. If TRUE, displays options in a sidebar instead of popover
  button. Default TRUE.

- sidebar_title:

  String. Title for the sidebar. Only used if use_sidebar = TRUE.
  Default "Chart options".

- sidebar_width:

  Numeric. Width of sidebar in pixels. Only used if use_sidebar = TRUE.
  Default 250.

- df:

  Data frame or tibble of patient level or aggregated data. Can be
  either a shiny reactive or static dataset.

- show_ratio:

  Display a ratio line on the epicurve?

- ratio_var:

  For patient level data, character string of variable name to use for
  ratio calculation.

- ratio_lab:

  The label to describe the computed ratio i.e. 'CFR' for case fatality
  ratio.

- ratio_numer:

  For patient level data, Value(s) in `ratio_var` to be used for the
  ratio numerator i.e. 'Death'. For aggregated data, character string of
  numeric count column to use of ratio numerator i.e. 'deaths'.

- ratio_denom:

  For patient level data, values in `ratio_var` to be used for the ratio
  denominator i.e. `c('Death', 'Recovery')`. For aggregated data,
  character string of numeric count column to use of ratio denominator
  i.e. 'cases'.

- group_pal:

  Colour palette used for groups.

- na_colour:

  Colour used for missing data.

- place_filter:

  supply the output of
  [`place_server()`](https://epicentre-msf.github.io/epishiny/reference/place.md)
  here to filter the data by click events on the place module map
  (clicking a polygon will filter the data to the clicked region)

- filter_info:

  If contained within an app using
  [`filter_server()`](https://epicentre-msf.github.io/epishiny/reference/filter.md),
  supply the `filter_info` object returned by that function here to add
  filter information to chart exports.

- filter_reset:

  If contained within an app using
  [`filter_server()`](https://epicentre-msf.github.io/epishiny/reference/filter.md),
  supply the `filter_reset` object returned by that function here to
  reset any click event filters that have been set from by module.

## Value

the module server function returns any point click event data of the
highchart. see
[highcharter::hc_add_event_point](https://jkunst.com/highcharter/reference/hc_add_event_point.html)
for details.
