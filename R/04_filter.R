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
#' @param missing_dates_lab The label for the include missing dates switch (only shown for single date variable).
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
  date_vars = NULL,
  group_vars = NULL,
  title = tags$span(bsicons::bs_icon("filter"), "Filters"),
  date_filters_lab = "Date filters",
  missing_dates_lab = "Include patients with missing dates?",
  group_filters_lab = "Group filters",
  filter_btn_lab = "update",
  filter_btn_tooltip = "Click here to apply filters and update the graphics",
  reset_btn_lab = "Reset",
  bg = "#fff",
  wrapper = \(...) bslib::sidebar(..., id = id, bg = bg)
) {
  ns <- NS(id)

  if (is.null(date_vars) && is.null(group_vars)) {
    cli::cli_abort("At least one of date_vars or group_vars must be provided to use the filter module.")
  }

  # Ensure date_vars has names (use values as names if missing)
  if (!is.null(date_vars) && !rlang::is_named(date_vars)) {
    date_vars <- rlang::set_names(date_vars)
  }

  single_date <- length(date_vars) == 1
  date_accordion <- if (length(date_vars)) {
    bslib::accordion_panel(
      title = date_filters_lab,
      # Single date variable: show without toggle, with quick select buttons
      purrr::map2(
        date_vars,
        names(date_vars),
        ~ setup_date_filter(.x, .y, ns, single_date = single_date, missing_dates_lab = missing_dates_lab)
      )
    )
  } else {
    NULL
  }

  group_accordion <- if (length(group_vars)) {
    bslib::accordion_panel(
      title = group_filters_lab,
      select_group_ui(
        id = ns("group-filters"),
        params = group_vars_to_params(group_vars),
        vs_args = list(showValueAsTags = FALSE, search = TRUE, disableSelectAll = TRUE), # , updateOn = "close"
        inline = FALSE
        # btn_reset_label = NULL
      )
    )
  } else {
    NULL
  }

  panels <- list(date_accordion, group_accordion) |> purrr::compact()

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
      open = length(panels) == 1,
      multiple = FALSE,
      !!!panels
    ),
    uiOutput(ns("filter_info"))
  )
}


#' @param df Data frame or tibble of patient level or aggregated data. Can be either a shiny reactive or static dataset.
#' @param date_vars named character vector of date variables in the data frame to be filtered on. Names are used as labels, values as column names.
#' @param time_filter supply the output of [time_server()] here to add
#'  its filter information to the filter sidebar
#' @param place_filter supply the output of [place_server()] here to add
#'  its filter information to the filter sidebar
#'
#' @return The server function returns a list containing reactive functions named `df`
#'   and `filter_info`. Access these as `app_data$df` and `app_data$filter_info`
#'   (not `app_data()$df`). These can be passed directly to the time, place,
#'   and person modules.
#'
#'
#' @rdname filter
#' @export
filter_server <- function(
  id,
  df,
  date_vars = NULL,
  group_vars = NULL,
  time_filter = shiny::reactiveVal(),
  place_filter = shiny::reactiveVal()
) {
  moduleServer(
    id,
    function(input, output, session) {
      ns <- session$ns

      if (is.null(date_vars) && is.null(group_vars)) {
        cli::cli_abort("At least one of date_vars or group_vars must be provided to use the filter module.")
      }

      # ==========================================================================
      # DYNAMIC INPUTS
      # ==========================================================================

      # Update group select inputs from data for each group variable
      # observe({
      #   purrr::walk(group_vars, ~ update_group_filter(session, .x, df_mod()))
      # }) |>
      #   shiny::bindEvent(df_mod())

      # Update date range inputs from data for each date variable
      observe({
        if (length(date_vars)) {
          purrr::walk(date_vars, ~ update_date_filter(session, .x, df_mod()))
        }
      }) |>
        shiny::bindEvent(df_mod())

      # Quick select buttons (only for single date variable)
      if (length(date_vars) == 1) {
        var <- unname(date_vars)[1]

        # Past 30 days button
        observeEvent(input[[paste0(var, "_30days")]], {
          date_range <- range(df_mod()[[var]], na.rm = TRUE)
          start_date <- max(date_range[2] - 29, date_range[1])
          shiny::updateDateRangeInput(
            session,
            var,
            start = start_date,
            end = date_range[2]
          )
        })

        # Past 3 months button
        observeEvent(input[[paste0(var, "_3months")]], {
          date_range <- range(df_mod()[[var]], na.rm = TRUE)
          start_date <- max(date_range[2] - 90, date_range[1])
          shiny::updateDateRangeInput(
            session,
            var,
            start = start_date,
            end = date_range[2]
          )
        })

        # Year to date button
        observeEvent(input[[paste0(var, "_ytd")]], {
          date_range <- range(df_mod()[[var]], na.rm = TRUE)
          start_date <- as.Date(paste0(format(date_range[2], "%Y"), "-01-01"))
          start_date <- max(start_date, date_range[1])
          shiny::updateDateRangeInput(
            session,
            var,
            start = start_date,
            end = date_range[2]
          )
        })

        # Full period button
        observeEvent(input[[paste0(var, "_full")]], {
          date_range <- range(df_mod()[[var]], na.rm = TRUE)
          shiny::updateDateRangeInput(
            session,
            var,
            start = date_range[1],
            end = date_range[2]
          )
        })
      }

      # ==========================================================================
      # DATA
      # ==========================================================================

      rv <- reactiveValues(
        df = NULL,
        filter_info = NULL,
        filter_reset = NULL
      )

      df_mod <- reactive({
        df_out <- force_reactive(df)
        # Only mutate group vars if they exist
        if (length(group_vars)) {
          df_out <- df_out |>
            dplyr::mutate(
              dplyr::across(
                unname(group_vars),
                \(x) forcats::fct_na_value_to_level(x, level = getOption("epishiny.na.label", "(Missing)"))
              )
            )
        }
        df_out
      })

      observe({
        rv$df <- df_mod()
      })

      # reset sidebar inputs when button clicked
      # observeEvent(input$reset, {
      #   shinyjs::reset("sb")
      #   shinyjs::delay(500, shinyjs::click("go"))
      # })

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
      # }) |> shiny::bindEvent(df_mod(), input$reset)

      # ==========================================================================
      # FILTER DATA
      # ==========================================================================

      # Date filtering (only if date_vars provided)
      df_date_filtered <- reactive({
        # Start with full dataset
        df_out <- df_mod()

        # Apply date filters only for enabled date variables
        if (length(date_vars)) {
          # Single date variable: always enabled (no toggle)
          # Multiple date variables: check which are enabled
          if (length(date_vars) == 1) {
            enabled_dates <- date_vars
          } else {
            enabled_dates <- purrr::keep(date_vars, ~ isolate(input[[paste0(.x, "_enabled")]]))
          }

          if (length(enabled_dates)) {
            # Create filter for each enabled date variable
            date_filters <- purrr::map(
              enabled_dates,
              ~ {
                date_range <- input[[.x]]
                # Only filter if date input is initialized
                if (is.null(date_range) || length(date_range) != 2) {
                  return(rep(TRUE, nrow(df_out)))
                }
                # Create logical vector for this date filter
                date_match <- (df_out[[.x]] >= as.Date(date_range[1]) & df_out[[.x]] <= as.Date(date_range[2]))
                # For single date variable, check include_na switch
                # For multiple date variables, missing dates are excluded
                if (length(date_vars) == 1) {
                  include_na <- isolate(input[[paste0(.x, "_include_na")]])
                  if (isTruthy(include_na)) {
                    date_match <- date_match | is.na(df_out[[.x]])
                  }
                }
                date_match
              }
            )
            # Combine all date filters with AND logic
            combined_date_filter <- purrr::reduce(date_filters, ~ .x & .y)
            df_out <- df_out |> dplyr::filter(combined_date_filter)
          }
        }
        df_out
      })

      # Group filtering (only if group_vars provided)
      # Choose input based on whether date filtering is available
      df_group_filtered <- if (length(group_vars)) {
        select_group_server(
          id = "group-filters",
          data_r = df_date_filtered,
          vars_r = unname(group_vars)
        )
      } else {
        # No group filtering, return date-filtered data
        df_date_filtered
      }

      # Update the reactive value when filter button is clicked
      observe({
        rv$df <- df_group_filtered()
      }) |>
        bindEvent(input$go, ignoreNULL = TRUE, ignoreInit = TRUE)

      # ==========================================================================
      # FILTER INFORMATION TEXT OUTPUT
      # ==========================================================================
      observe({
        # Generate filter info for enabled date variables
        date_filters <- NULL
        if (length(date_vars)) {
          # Single date variable: always enabled (no toggle)
          # Multiple date variables: check which are enabled
          if (length(date_vars) == 1) {
            enabled_dates <- date_vars
          } else {
            enabled_dates <- purrr::keep(date_vars, ~ isolate(input[[paste0(.x, "_enabled")]]))
          }

          if (length(enabled_dates)) {
            date_filters <- purrr::map2(
              unname(enabled_dates),
              names(enabled_dates),
              ~ {
                date_range <- input[[.x]]
                if (length(date_range) == 2) {
                  # Get full date range from data
                  full_range <- range(df_mod()[[.x]], na.rm = TRUE)
                  # Only show filter info if selected range differs from full range
                  if (as.Date(date_range[1]) != full_range[1] || as.Date(date_range[2]) != full_range[2]) {
                    glue::glue(
                      "{.y}: {format(date_range[1], '%d/%b/%y')} - {format(date_range[2], '%d/%b/%y')}"
                    )
                  }
                }
              }
            ) |>
              purrr::compact() |>
              purrr::list_simplify()
          }
        }

        # Generate filter info for group filters
        group_filters <- NULL
        if (length(group_vars)) {
          group_inputs <- attr(df_group_filtered(), "inputs")
          group_filters <- purrr::map2(
            unname(group_vars),
            names(group_vars),
            ~ {
              if (length(group_inputs[[.x]])) {
                glue::glue("{.y}: {glue::glue_collapse(group_inputs[[.x]], sep = ', ')}")
              }
            }
          ) |>
            purrr::compact() |>
            purrr::list_simplify()
        }

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
      }) |>
        shiny::bindEvent(input$go, ignoreNULL = FALSE, ignoreInit = TRUE)

      output$filter_info <- renderUI({
        fi <- rv$filter_info
        tf <- time_filter()
        pf <- place_filter()
        fi <- format_filter_info(fi, tf, pf)
        shiny::helpText(shiny::HTML(fi))
      })

      # return data to main app ===========================
      list(
        df = shiny::reactive(rv$df),
        filter_info = shiny::reactive(rv$filter_info),
        filter_reset = shiny::reactive(rv$filter_reset)
      )
    }
  )
}

# =============================================================================
# FILTER MODULE HELPER FUNCTIONS
# =============================================================================

#' @title Select Group Input Module
#'
#' @description Group of mutually dependent select menus for filtering `data.frame`'s columns (like in Excel).
#'
#' @details
#' This is an adaptation of the select_group module from the 'datamods' package. Full credit to the original authors.
#'
#' @param id Module's id.
#' @param params A list of parameters passed to each [shinyWidgets::virtualSelectInput()],
#'  you can use :
#'   * `inputId`: mandatory, must correspond to variable name.
#'   * `label`: Display label for the control.
#'   * `placeholder`: Text to show when no options selected.
#' @param label Character, global label on top of all labels.
#' @param btn_reset_label Character, reset button label. If `NULL` no button is added.
#' @param inline If `TRUE` (the default),
#'  select menus are horizontally positioned, otherwise vertically.
#' @param vs_args Arguments passed to all [shinyWidgets::virtualSelectInput()] created.
#'
#' @return A [shiny::reactive()] function containing data filtered with an attribute `inputs` containing a named list of selected inputs.
#'
#' @noRd
#'
#' @importFrom utils modifyList
#' @importFrom htmltools tagList tags css
#' @importFrom shiny NS actionLink icon singleton
#' @importFrom shinyWidgets virtualSelectInput
select_group_ui <- function(
  id,
  params,
  label = NULL,
  btn_reset_label = "Reset group filters",
  inline = TRUE,
  vs_args = list()
) {
  ns <- NS(id)

  button_reset <- if (!is.null(btn_reset_label)) {
    actionLink(
      inputId = ns("reset_all"),
      label = btn_reset_label,
      icon = shiny::icon("x"),
      class = "link-danger fs-6"
    )
  }
  label_tag <- if (!is.null(label)) tags$b(label, class = "select-group-label")

  sel_tag <- lapply(
    X = seq_along(params),
    FUN = function(x) {
      input <- params[[x]]
      vs_args <- modifyList(
        x = vs_args,
        val = list(
          inputId = ns(input$inputId),
          label = input$label,
          placeholder = input$placeholder,
          choices = input$selected,
          selected = input$selected,
          multiple = ifelse(is.null(input$multiple), TRUE, input$multiple),
          width = "100%"
        ),
        keep.null = TRUE
      )
      if (is.null(vs_args$showValueAsTags)) {
        vs_args$showValueAsTags <- TRUE
      }
      if (is.null(vs_args$zIndex)) {
        vs_args$zIndex <- 10
      }
      if (is.null(vs_args$disableSelectAll)) {
        vs_args$disableSelectAll <- TRUE
      }
      tags$div(
        class = "select-group-item",
        id = ns(paste0("container-", input$inputId)),
        do.call(shinyWidgets::virtualSelectInput, vs_args)
      )
    }
  )

  if (isTRUE(inline)) {
    sel_tag <- tags$div(
      class = "select-group-container",
      style = htmltools::css(
        display = "grid",
        gridTemplateColumns = sprintf("repeat(%s, 1fr)", length(params)),
        gridColumnGap = "5px"
      ),
      sel_tag
    )
  }

  tags$div(
    class = "select-group",
    label_tag,
    sel_tag,
    tags$div(class = "d-flex justify-content-end", button_reset)
  )
}


#' @param data_r Either a [data.frame()] or a [shiny::reactive()]
#'  function returning a `data.frame` (do not use parentheses).
#' @param vars_r character, columns to use to create filters,
#'  must correspond to variables listed in `params`. Can be a
#'  [shiny::reactive()] function, but values must be included in the initial ones (in `params`).
#' @param selected_r [shiny::reactive()] function returning a named list with selected values to set.
#'
#' @noRd
#' @importFrom shiny observeEvent observe reactiveValues reactive is.reactive isolate isTruthy
#' @importFrom shinyWidgets updateVirtualSelect
#' @importFrom rlang %||%
select_group_server <- function(id, data_r, vars_r, selected_r = reactive(list())) {
  moduleServer(
    id = id,
    module = function(input, output, session) {
      # Namespace
      ns <- session$ns
      shinyjs::hide(selector = paste0("#", ns("reset_all")))

      # data <- as.data.frame(data)
      rv <- reactiveValues(data = NULL, vars = NULL)
      observe({
        if (is.reactive(data_r)) {
          rv$data <- data_r()
        } else {
          rv$data <- as.data.frame(data_r)
        }
        if (is.reactive(vars_r)) {
          rv$vars <- vars_r()
        } else {
          rv$vars <- vars_r
        }
        for (var in names(rv$data)) {
          if (var %in% rv$vars) {
            shinyjs::show(id = paste0("container-", var))
          } else {
            shinyjs::hide(id = paste0("container-", var))
          }
        }
      })

      observe({
        selected <- selected_r()
        if (!is.list(selected)) {
          selected <- list()
        }
        lapply(
          X = rv$vars,
          FUN = function(x) {
            vals <- sort(unique(rv$data[[x]]))
            shinyWidgets::updateVirtualSelect(
              session = session,
              inputId = x,
              choices = vals,
              selected = selected[[x]] %||% isolate(input[[x]])
            )
          }
        )
      })

      observe({
        req(rv$data, rv$vars)

        # Check if any inputs have initial selections
        has_selections <- any(sapply(rv$vars, function(x) {
          val <- input[[x]]
          !is.null(val) && length(val) > 0
        }))

        if (has_selections) {
          data <- rv$data
          vars <- rv$vars

          # Update choices for each input based on OTHER selections
          lapply(
            X = vars,
            FUN = function(x) {
              # Get all vars except current one
              ovars <- vars[vars != x]

              # Filter data based on OTHER selections only
              indicator <- lapply(
                X = ovars,
                FUN = function(ovar) {
                  val <- input[[ovar]]
                  if (is.null(val) || length(val) == 0) {
                    rep(TRUE, nrow(data))
                  } else {
                    data[[ovar]] %inT% val
                  }
                }
              )
              indicator <- Reduce(f = `&`, x = indicator)
              filtered_data <- data[indicator, ]

              # Update with available choices and current selection
              shinyWidgets::updateVirtualSelect(
                session = session,
                inputId = x,
                choices = sort(unique(filtered_data[[x]])),
                selected = input[[x]]
              )
            }
          )

          # Show reset button if any data is filtered
          indicator_all <- lapply(
            X = vars,
            FUN = function(x) {
              data[[x]] %inT% input[[x]]
            }
          )
          indicator_all <- Reduce(f = `&`, x = indicator_all)

          if (!all(indicator_all)) {
            shinyjs::show(selector = paste0("#", ns("reset_all")))
          }
        }
      }) |>
        bindEvent(rv$data, rv$vars, once = TRUE)

      observeEvent(input$reset_all, {
        lapply(
          X = rv$vars,
          FUN = function(x) {
            vals <- sort(unique(rv$data[[x]]))
            shinyWidgets::updateVirtualSelect(
              session = session,
              inputId = x,
              choices = vals
            )
          }
        )
      })

      observe({
        vars <- rv$vars
        lapply(
          X = vars,
          FUN = function(x) {
            ovars <- vars[vars != x]

            observeEvent(
              input[[x]],
              {
                data <- rv$data

                indicator <- lapply(
                  X = vars,
                  FUN = function(x) {
                    data[[x]] %inT% input[[x]]
                  }
                )
                indicator <- Reduce(f = `&`, x = indicator)
                data <- data[indicator, ]

                if (all(indicator)) {
                  shinyjs::hide(selector = paste0("#", ns("reset_all")))
                } else {
                  shinyjs::show(selector = paste0("#", ns("reset_all")))
                }

                for (i in ovars) {
                  if (!isTruthy(input[[i]])) {
                    shinyWidgets::updateVirtualSelect(
                      session = session,
                      inputId = i,
                      choices = sort(unique(data[[i]]))
                    )
                  }
                }

                if (!isTruthy(input[[x]])) {
                  shinyWidgets::updateVirtualSelect(
                    session = session,
                    inputId = x,
                    choices = sort(unique(data[[x]]))
                  )
                }
              },
              ignoreNULL = FALSE,
              ignoreInit = TRUE
            )
          }
        )
      })

      return(reactive({
        data <- rv$data
        vars <- rv$vars
        indicator <- lapply(
          X = vars,
          FUN = function(x) {
            data[[x]] %inT% input[[x]]
          }
        )
        indicator <- Reduce(f = `&`, x = indicator)
        data <- data[indicator, ]
        attr(data, "inputs") <- lapply(
          X = stats::setNames(vars, vars),
          FUN = function(x) input[[x]]
        )
        return(data)
      }))
    }
  )
}

`%inT%` <- function(x, table) {
  if (!is.null(table) && !"" %in% table) {
    x %in% table
  } else {
    rep_len(TRUE, length(x))
  }
}

#' @noRd
group_vars_to_params <- function(group_vars, selected = "", placeholder = "All") {
  if (!rlang::is_named(group_vars)) {
    group_vars <- rlang::set_names(group_vars)
  }
  out <- purrr::pmap(
    list(unname(group_vars), names(group_vars), selected),
    \(id, label, selected) {
      list(
        inputId = id,
        label = label,
        selected = if (selected == "") NULL else selected,
        placeholder = placeholder
      )
    }
  )
  unname(out)
}

#' Setup date filter UI
#' @noRd
setup_date_filter <- function(var, lab, ns, single_date = FALSE, ...) {
  if (is.null(lab)) {
    lab <- var
  }

  if (single_date) {
    # Single date variable: show date input without toggle
    div(
      dateRangeInput(
        inputId = ns(var),
        label = lab,
        min = NULL,
        max = NULL,
        start = NULL,
        end = NULL,
        weekstart = getOption("epishiny.week.start", 1),
        format = "d/m/yy"
      ),
      # Quick select buttons as button group
      helpText("Quick select:"),
      div(
        class = "btn-group w-100",
        role = "group",
        style = "margin-top: 10px;",
        actionButton(
          ns(paste0(var, "_30days")),
          "30d",
          class = "btn-sm btn-light",
          style = "flex: 1;"
        ),
        actionButton(
          ns(paste0(var, "_3months")),
          "3m",
          class = "btn-sm btn-light",
          style = "flex: 1;"
        ),
        actionButton(
          ns(paste0(var, "_ytd")),
          "YTD",
          class = "btn-sm btn-light",
          style = "flex: 1;"
        ),
        actionButton(
          ns(paste0(var, "_full")),
          "All",
          class = "btn-sm btn-light",
          style = "flex: 1;"
        )
      )
    )
  } else {
    # Multiple date variables: show toggle switch
    div(
      # Enable/disable switch (OFF by default)
      div(
        style = "padding-bottom: 0;",
        bslib::input_switch(
          id = ns(paste0(var, "_enabled")),
          label = lab,
          value = FALSE
        )
      ),
      # Date range input (shown only when enabled)
      shiny::conditionalPanel(
        condition = sprintf("input['%s']", paste0(var, "_enabled")),
        ns = ns,
        dateRangeInput(
          inputId = ns(var),
          label = NULL,
          min = NULL,
          max = NULL,
          start = NULL,
          end = NULL,
          weekstart = getOption("epishiny.week.start", 1),
          format = "d/m/yy"
        )
      )
    )
  }
}

#' Update date filter input with data
#' @noRd
update_date_filter <- function(session, var, df) {
  vec <- df[[var]]
  if (lubridate::is.Date(vec) || lubridate::is.POSIXt(vec)) {
    if (length(vec) && any(!is.na(vec))) {
      date_range <- range(vec, na.rm = TRUE)
    } else {
      date_range <- c(Sys.Date(), Sys.Date())
    }
    shiny::updateDateRangeInput(
      session,
      var,
      min = date_range[1],
      max = date_range[2],
      start = date_range[1],
      end = date_range[2]
    )
  } else {
    warning(sprintf("Date variable '%s' is not a Date or POSIXt class", var))
  }
}
