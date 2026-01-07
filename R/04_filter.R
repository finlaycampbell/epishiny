#' Filter module
#'
#' Filter linelist data using a sidebar with shiny inputs.
#'
#' @rdname filter
#'
#' @param id Module id. Must be the same in both the UI and server function to link the two.
#' @param date_vars named character vector of date variables for filtering. Names are used as variable labels in the UI.
#' @param group_vars named character vector of categorical variables for the data grouping input. Names are used as variable labels.
#' @param title The title of the sidebar.
#' @param date_filters_lab The label for the date filters accordion panel.
#' @param group_filters_lab The label for the group filters accordion panel.
#' @param filter_btn_lab The label for the filter data button.
#' @param filter_btn_tooltip The tooltip for the filter data button.
#' @param reset_btn_lab The label for the reset filters button.
#' @param bg The background color of the sidebar.
#' @param wrapper A function that wraps the sidebar UI elements. Defaults to [bslib::sidebar].
#'   Change if you don't want the filter UI to be a sidebar.
#'
#' @return A UI `wrapper` with date filters, group filters, and action buttons.
#'
#' @import shiny
#' @export
#' @example inst/examples/docs/app.R
filter_ui <- function(
  id,
  date_vars,
  group_vars,
  title = tags$span(bsicons::bs_icon("filter"), "Filters"),
  date_filters_lab = "Date filters",
  group_filters_lab = "Group filters",
  filter_btn_lab = "update",
  filter_btn_tooltip = "Click here to apply filters and update the graphics",
  reset_btn_lab = "Reset",
  bg = "#fff",
  wrapper = \(...) bslib::sidebar(..., id = id, bg = bg)
) {
  ns <- NS(id)

  wrapper(
    div(
      class = "d-flex justify-content-between align-items-center",
      tags$h5(title),
      bslib::input_task_button(
        id = ns("go"),
        label = filter_btn_lab,
        icon = icon("refresh"),
        label_busy = "processing",
        class = "btn-sm",
        type = "link"
      ) |>
        bslib::tooltip(
          filter_btn_tooltip,
          id = ns("tt-filter"),
          placement = "bottom"
        )
    ),

    bslib::accordion(
      open = FALSE,
      multiple = FALSE,
      bslib::accordion_panel(
        date_filters_lab,
        if (length(date_vars)) {
          purrr::map2(date_vars, names(date_vars), setup_date_filter, ns)
        } else {
          shiny::helpText("No date variables configured")
        }
      ),
      bslib::accordion_panel(
        group_filters_lab,
        purrr::map2(group_vars, names(group_vars), setup_group_filter, ns)
      )
    ),
    # bslib::layout_columns(
    #   col_widths = 6,
    #   bslib::input_task_button(
    #     ns("go"),
    #     filter_btn_lab,
    #     icon = icon("filter"),
    #     # type = "primary"
    #     class = "btn-sm btn-primary"
    #   ),
    #   actionButton(
    #     ns("reset"),
    #     reset_btn_lab,
    #     icon = icon("arrows-rotate"),
    #     # type = "light"
    #     class = "btn-sm btn-light"
    #   )
    # ),
    uiOutput(ns("filter_info"))
  )
}


#' @param df Data frame or tibble of patient level or aggregated data. Can be either a shiny reactive or static dataset.
#' @param date_vars named character vector of date variables in the data frame to be filtered on. Names are used as labels, values as column names.
#' @param time_filter supply the output of [time_server()] wrapped in a [shiny::reactive()] here to add
#'  its filter information to the filter sidebar
#' @param place_filter supply the output of [place_server()] wrapped in a [shiny::reactive()] here to add
#'  its filter information to the filter sidebar
#'
#' @return The server function returns both the filtered data and a formatted text string with filter information
#'   named `df` and `filter_info` respectively in a reactive list. These should be passed as arguments
#'   of the same name in the time, place and person modules wrapped in a [`shiny::reactive()`]
#'
#'
#' @rdname filter
#' @export
filter_server <- function(
  id,
  df,
  date_vars,
  group_vars,
  time_filter = shiny::reactiveVal(),
  place_filter = shiny::reactiveVal()
) {
  moduleServer(
    id,
    function(input, output, session) {
      ns <- session$ns

      # ==========================================================================
      # DYNAMIC INPUTS
      # ==========================================================================

      # output$group_filters <- shiny::renderUI({
      #   purrr::map2(group_vars, names(group_vars), make_select_filter, ns, df_mod())
      # }) %>% shiny::bindEvent(df_mod())

      observe({
        purrr::walk(group_vars, ~ update_group_filter(session, .x, df_mod()))
      }) %>%
        shiny::bindEvent(df_mod())

      # Update date range inputs from data for each date variable
      observe({
        if (length(date_vars)) {
          purrr::walk(date_vars, ~ update_date_filter(session, .x, df_mod()))
        }
      }) %>%
        shiny::bindEvent(df_mod())

      # ==========================================================================
      # DATA
      # ==========================================================================

      rv <- reactiveValues(
        df = NULL,
        filter_info = NULL,
        filter_reset = NULL
      )

      df_mod <- reactive({
        force_reactive(df) %>%
          dplyr::mutate(dplyr::across(
            unname(group_vars),
            \(x) forcats::fct_na_value_to_level(x, level = getOption("epishiny.na.label", "(Missing)"))
          ))
      })

      observe({
        rv$df <- df_mod()
      })

      # reset sidebar inputs when button clicked
      observeEvent(input$reset, {
        shinyjs::reset("sb")
        shinyjs::delay(500, shinyjs::click("go"))
      })

      # also send back to main app to reset module click filters
      # if they have been applied
      # observe({
      #   rv$filter_reset <- input$reset
      # })

      # observe({
      #   date_range <- range(df_mod()[[date_var]], na.rm = TRUE)
      #   shiny::updateDateRangeInput(
      #     session,
      #     "date",
      #     min = date_range[1],
      #     max = date_range[2],
      #     start = date_range[1],
      #     end = date_range[2]
      #   )
      # }) %>% shiny::bindEvent(df_mod(), input$reset)

      # ==========================================================================
      # OBSERVERS
      # ==========================================================================

      # observeEvent(input$days_all, {
      #   date_range <- range(df_data[[date_var]], na.rm = TRUE)
      #   updateSliderInput(
      #     session,
      #     "date",
      #     value = c(date_range[1], date_range[2]),
      #     timeFormat = "%d %b",
      #     step = 1
      #   )
      # })
      #
      # observeEvent(input$days_14, {
      #   date_range <- range(df_data[[date_var]], na.rm = TRUE)
      #   date_range[1] <- date_range[2] - 13
      #   updateSliderInput(
      #     session,
      #     "date",
      #     value = c(date_range[1], date_range[2]),
      #     timeFormat = "%d %b",
      #     step = 1
      #   )
      # })
      #
      # observeEvent(input$days_7, {
      #   date_range <- range(df_data[[date_var]], na.rm = TRUE)
      #   date_range[1] <- date_range[2] - 6
      #   updateSliderInput(
      #     session,
      #     "date",
      #     value = c(date_range[1], date_range[2]),
      #     timeFormat = "%d %b",
      #     step = 1
      #   )
      # })
      #
      # observeEvent(input$days_1, {
      #   date_range <- range(df_data[[date_var]], na.rm = TRUE)
      #   date_range[1] <- date_range[2]
      #   updateSliderInput(
      #     session,
      #     "date",
      #     value = c(date_range[1], date_range[2]),
      #     timeFormat = "%d %b",
      #     step = 1
      #   )
      # })

      # ==========================================================================
      # FILTER DATA
      # ==========================================================================

      observe({
        # Start with full dataset
        df_out <- df_mod()

        # Apply date filters only for enabled date variables
        if (length(date_vars)) {
          # Get enabled date variables
          enabled_dates <- purrr::keep(date_vars, ~ isolate(input[[paste0(.x, "_enabled")]]))

          if (length(enabled_dates)) {
            # Create filter for each enabled date variable
            date_filters <- purrr::map(
              enabled_dates,
              ~ {
                date_range <- input[[.x]]
                # Create logical vector for this date filter
                # Missing dates are excluded when filter is enabled
                date_match <- c(
                  df_out[[.x]] >= as.Date(date_range[1]) & df_out[[.x]] <= as.Date(date_range[2])
                )
                date_match
              }
            )
            # Combine all date filters with AND logic
            combined_date_filter <- purrr::reduce(date_filters, ~ .x & .y)
            df_out <- df_out %>% dplyr::filter(combined_date_filter)
          }
        }

        # Then filter over all group picker inputs
        each_var <- purrr::map(group_vars, ~ filter_var(df_out[[.x]], input[[.x]]))
        selected <- purrr::reduce(each_var, ~ .x & .y)
        df_out <- df_out %>% dplyr::filter(selected)

        rv$df <- df_out
      }) %>%
        shiny::bindEvent(input$go, ignoreNULL = TRUE, ignoreInit = TRUE)

      # ==========================================================================
      # FILTER INFORMATION TEXT OUTPUT
      # ==========================================================================
      observe({
        # Generate filter info for enabled date variables
        date_filters <- NULL
        if (length(date_vars)) {
          enabled_dates <- purrr::keep(date_vars, ~ isolate(input[[paste0(.x, "_enabled")]]))

          if (length(enabled_dates)) {
            date_filters <- purrr::map2(
              unname(enabled_dates),
              names(enabled_dates),
              ~ {
                date_range <- input[[.x]]
                if (length(date_range) == 2) {
                  glue::glue(
                    "{.y}: {format(date_range[1], '%d/%b/%y')} - {format(date_range[2], '%d/%b/%y')}"
                  )
                }
              }
            ) %>%
              purrr::compact() %>%
              purrr::list_simplify()
          }
        }

        # Generate filter info for group filters
        group_filters <- purrr::map2(
          unname(group_vars),
          names(group_vars),
          ~ {
            if (length(input[[.x]])) {
              glue::glue("{.y}: {glue::glue_collapse(input[[.x]], sep = ', ')}")
            }
          }
        ) %>%
          purrr::compact() %>%
          purrr::list_simplify()

        # Build final filter info string
        if (!is.null(date_filters) || !is.null(group_filters)) {
          fi_out <- "<b>Filters applied</b>"

          if (!is.null(date_filters)) {
            fi_out <- glue::glue("{fi_out}</br>{glue::glue_collapse(date_filters, sep = '</br>')}")
          }

          if (!is.null(group_filters)) {
            fi_out <- glue::glue("{fi_out}</br>{glue::glue_collapse(group_filters, sep = '</br>')}")
          }

          rv$filter_info <- fi_out
        } else {
          rv$filter_info <- NULL
        }
      }) %>%
        shiny::bindEvent(input$go, ignoreNULL = FALSE, ignoreInit = FALSE)

      output$filter_info <- renderUI({
        fi <- rv$filter_info
        tf <- time_filter()
        pf <- place_filter()
        fi <- format_filter_info(fi, tf, pf)
        shiny::helpText(shiny::HTML(fi))
      })

      # return data to main app ===========================
      shiny::reactive({
        shiny::reactiveValuesToList(rv)
      })
    }
  )
}
