#' Launch a single 'epishiny' module as a standalone shiny app
#'
#' Use this function to quickly launch any of the 3 'epishiny' interactive
#' visualisation modules (time, place, person) independently, allowing for
#' incorporation into exploratory data analysis workflows in R.
#'
#' @param module Name of the module to launch. Current options are
#'  "time", "place" or "person".
#' @param ... Other named arguments passed to the relevant module
#'  UI and Server functions. See each module's documentation for details
#'  of the arguments required.
#'
#' @return No return value, a shiny app is launched.
#' @example inst/examples/docs/launch-module.R
#' @export
launch_module <- function(module = c("time", "place", "person"), ...) {
  module <- match.arg(module, several.ok = FALSE)
  mod_ui <- paste0(module, "_ui")
  mod_server <- paste0(module, "_server")
  # prepare arguments for ui and server
  args = tibble::lst(
    id = "epimod",
    full_screen = FALSE,
    ...
  )
  ui_args <- match.arg(
    names(args),
    names(as.list(args(mod_ui))),
    several.ok = TRUE
  )
  server_args <- match.arg(
    names(args),
    names(as.list(args(mod_server))),
    several.ok = TRUE
  )
  ui <- bslib::page_fillable(
    padding = 0,
    use_epishiny(),
    do.call(mod_ui, args[ui_args]),
    waiter::waiter_preloader(html = waiter::spin_3())
  )
  server <- function(input, output, session) {
    do.call(mod_server, args[server_args])
  }
  # runGadget will launch in RStudio's pane viewer if available
  shiny::runGadget(ui, server)
}

#' Create a custom epishiny dashboard
#'
#' Build a complete epishiny dashboard with your choice of modules (time, place, person, filter).
#' This function generates a shiny app with the selected modules and handles all the
#' boilerplate UI and server code.
#'
#' @param df Data frame or tibble of patient level or aggregated data.
#' @param modules Character vector specifying which modules to include and their order in the layout.
#'   Valid values are `"time"`, `"place"`, and `"person"`. Default is `c("place", "time", "person")`.
#'   The order of the vector determines both which modules appear and their layout order.
#'   Examples:
#'   - `c("time", "place", "person")` - All modules with time first
#'   - `c("place", "time")` - Only map and time series (no demographics)
#'   - `c("time")` - Only time series module
#' @param include_filter Logical. Include the filter sidebar? Default TRUE.
#' @param title Character. Title for the dashboard. Default "epishiny dashboard".
#' @param theme A bslib theme object to customize the appearance of the dashboard. Default is [bslib::bs_theme()].
#' @param col_widths Numeric vector specifying the column widths for the layout. If NULL (default),
#'   widths are automatically assigned based on number of modules. Use in combination with `modules`
#'   to control layout. Example: `col_widths = c(12, 7, 5)` with `modules = c("time", "place", "person")`
#'   puts time on full width row, then place (7 cols) and person (5 cols) on second row.
#' @param row_heights Numeric vector specifying the row heights for the layout. Default is 1 (equal heights).
#' @param ... Named arguments to pass to the individual module UI and server functions.
#'   Arguments will be matched to their appropriate modules. See [time_ui()], [time_server()],
#'   [place_ui()], [place_server()], [person_ui()], [person_server()], [filter_ui()], [filter_server()]
#'   for details on available arguments.
#'
#' @return A shiny app object that can be passed to [shiny::runApp()] or run directly if in interactive mode.
#'
#' @examples
#' \dontrun{
#' library(epishiny)
#' data("df_ll")
#' data("sf_yem")
#'
#' # Setup geo data
#' geo_data <- geo_layer(
#'   layer_name = "Governorate",
#'   sf = sf_yem$adm1,
#'   name_var = "adm1_name",
#'   pop_var = "adm1_pop",
#'   join_by = c("pcode" = "adm1_pcode")
#' )
#'
#' # Create dashboard with all modules (default)
#' app <- dashboard(
#'   df = df_ll,
#'   date_vars = c("Date of notification" = "date_notification"),
#'   group_vars = c("Sex" = "sex_id"),
#'   geo_data = geo_data,
#'   age_var = "age_years",
#'   sex_var = "sex_id",
#'   male_level = "Male",
#'   female_level = "Female"
#' )
#'
#' # Time on top row, place and person below
#' app_time_focus <- dashboard(
#'   df = df_ll,
#'   title = "Time Series Focus",
#'   modules = c("time", "place", "person"),
#'   col_widths = c(12, 7, 5),
#'   date_vars = c("Date of notification" = "date_notification"),
#'   group_vars = c("Sex" = "sex_id"),
#'   geo_data = geo_data,
#'   age_var = "age_years",
#'   sex_var = "sex_id",
#'   male_level = "Male",
#'   female_level = "Female"
#' )
#'
#' # Only time and person modules (no map)
#' app_simple <- dashboard(
#'   df = df_ll,
#'   title = "Time & Demographics",
#'   modules = c("time", "person"),
#'   date_vars = c("Date of notification" = "date_notification"),
#'   age_var = "age_years",
#'   sex_var = "sex_id",
#'   male_level = "Male",
#'   female_level = "Female"
#' )
#'
#' # Run the dashboard
#' if (interactive()) {
#'   shiny::runApp(app_time_focus)
#' }
#' }
#'
#' @export
epi_dashboard <- function(
  df,
  modules = c("place", "time", "person"),
  include_filter = TRUE,
  title = "epishiny dashboard",
  theme = bslib::bs_theme(),
  col_widths = NULL,
  row_heights = 1,
  ...
) {
  # Validate modules parameter
  valid_modules <- c("time", "place", "person")
  if (!all(modules %in% valid_modules)) {
    invalid <- setdiff(modules, valid_modules)
    cli::cli_abort(c(
      "Invalid module(s): {.val {invalid}}",
      "i" = "Valid modules are: {.val {valid_modules}}"
    ))
  }

  # Check that at least one module is included
  if (length(modules) == 0) {
    cli::cli_abort("At least one module must be specified in {.arg modules}.")
  }

  # Determine which modules are included based on the modules parameter
  include_time <- "time" %in% modules
  include_place <- "place" %in% modules
  include_person <- "person" %in% modules

  # Capture all additional arguments
  args <- list(...)

  # Helper function to safely match arguments
  match_args_safe <- function(arg_names, fn_args) {
    if (length(arg_names) == 0) {
      return(character(0))
    }
    intersect(arg_names, fn_args)
  }

  # Extract filter module arguments
  filter_ui_args <- if (include_filter) {
    match_args_safe(names(args), names(as.list(args(filter_ui))))
  } else {
    character(0)
  }

  filter_server_args <- if (include_filter) {
    match_args_safe(names(args), names(as.list(args(filter_server))))
  } else {
    character(0)
  }

  # Extract time module arguments
  time_ui_args <- if (include_time) {
    match_args_safe(names(args), names(as.list(args(time_ui))))
  } else {
    character(0)
  }

  time_server_args <- if (include_time) {
    match_args_safe(names(args), names(as.list(args(time_server))))
  } else {
    character(0)
  }

  # Extract place module arguments
  place_ui_args <- if (include_place) {
    match_args_safe(names(args), names(as.list(args(place_ui))))
  } else {
    character(0)
  }

  place_server_args <- if (include_place) {
    match_args_safe(names(args), names(as.list(args(place_server))))
  } else {
    character(0)
  }

  # Extract person module arguments
  person_ui_args <- if (include_person) {
    match_args_safe(names(args), names(as.list(args(person_ui))))
  } else {
    character(0)
  }

  person_server_args <- if (include_person) {
    match_args_safe(names(args), names(as.list(args(person_server))))
  } else {
    character(0)
  }

  # Create a list of module UI elements in the order specified by modules parameter
  module_uis <- lapply(modules, function(mod) {
    switch(
      mod,
      "place" = do.call(place_ui, c(list(id = "place"), args[place_ui_args])),
      "time" = do.call(time_ui, c(list(id = "time"), args[time_ui_args])),
      "person" = do.call(person_ui, c(list(id = "person"), args[person_ui_args]))
    )
  })

  # Build UI
  ui <- if (include_filter) {
    bslib::page_sidebar(
      shiny::useBusyIndicators(),
      class = "bslib-page-dashboard",
      title = title,
      theme = theme,
      sidebar = do.call(
        filter_ui,
        c(list(id = "filter"), args[filter_ui_args])
      ),
      do.call(
        bslib::layout_columns,
        c(
          list(
            col_widths = if (!is.null(col_widths)) {
              col_widths
            } else if (include_place && include_time && include_person) {
              c(12, 7, 5)
            } else if (include_place && (include_time || include_person)) {
              c(12, 12)
            } else {
              12
            },
            row_heights = row_heights,
            gap = 10
          ),
          module_uis
        )
      )
    )
  } else {
    bslib::page_fillable(
      gap = 10,
      shiny::useBusyIndicators(),
      class = "bslib-page-dashboard",
      title = title,
      theme = theme,
      tags$div(tags$h4(title, class = "fw-bold")),
      do.call(
        bslib::layout_columns,
        c(
          list(
            col_widths = if (!is.null(col_widths)) {
              col_widths
            } else if (include_place && include_time && include_person) {
              c(12, 7, 5)
            } else if (include_place && (include_time || include_person)) {
              c(12, 12)
            } else {
              12
            },
            row_heights = row_heights,
            gap = 10
          ),
          module_uis
        )
      )
    )
  }

  # Build server
  server <- function(input, output, session) {
    # Initialize reactiveVals for cross-module filtering
    time_filter <- shiny::reactiveVal()
    place_filter <- shiny::reactiveVal()

    # Filter module (if included)
    if (include_filter) {
      app_data <- do.call(
        filter_server,
        c(
          list(
            id = "filter",
            df = df,
            time_filter = time_filter,
            place_filter = place_filter
          ),
          args[filter_server_args]
        )
      )
      data_source <- app_data$df
      filter_info <- app_data$filter_info
    } else {
      data_source <- df
      filter_info <- shiny::reactiveVal()
    }

    # Place module
    if (include_place) {
      place_click <- do.call(
        place_server,
        c(
          list(
            id = "place",
            df = data_source,
            filter_info = filter_info,
            time_filter = time_filter
          ),
          args[place_server_args]
        )
      )
      # Update place_filter when place is clicked
      shiny::observe({
        place_filter(place_click())
      })
    }

    # Time module
    if (include_time) {
      time_click <- do.call(
        time_server,
        c(
          list(
            id = "time",
            df = data_source,
            filter_info = filter_info,
            place_filter = place_filter
          ),
          args[time_server_args]
        )
      )
      # Update time_filter when time is clicked
      shiny::observe({
        time_filter(time_click())
      })
    }

    # Person module
    if (include_person) {
      do.call(
        person_server,
        c(
          list(
            id = "person",
            df = data_source,
            filter_info = filter_info,
            time_filter = time_filter,
            place_filter = place_filter
          ),
          args[person_server_args]
        )
      )
    }
  }

  # Return shiny app object
  shiny::shinyApp(ui = ui, server = server)
}

#' Launch epishiny demo dashboard
#'
#' See an example of the type of dashboard you can build
#' using `epishiny` modules within a `bslib` UI.
#'
#' @param disease name of disease demo dashboard to launch. Current options are "ebola" and "measles".
#'
#' @return No return value, a shiny app is launched.
#' @examples
#' ## Only run this example in interactive R sessions
#' if (interactive()) {
#'   library(epishiny)
#'   launch_demo_dashboard("ebola")
#' }
#' @export
launch_demo_dashboard <- function(disease = "ebola") {
  rlang::arg_match0(disease, c("ebola", "measles"))
  app_dir <- system.file("examples", paste0(disease, "-linelist-dash"), package = "epishiny")
  if (app_dir == "") {
    stop("Could not find example directory. Try re-installing `epishiny`.", call. = FALSE)
  }
  shiny::runApp(app_dir, display.mode = "normal")
}
