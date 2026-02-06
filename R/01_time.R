#' Time module
#'
#' Visualise data over time with an interactive 'epicurve'.
#'
#' @rdname time
#'
#' @param id Module id. Must be the same in both the UI and server function to link the two.
#' @param date_vars Character vector of date variable(s) for the date axis. If named, names are used as variable labels.
#' @param count_vars If data is aggregated, variable name(s) of count variable(s) in data. If more than one variable provided,
#'  a select input will appear in the options dropdown. If named, names are used as variable labels.
#' @param group_vars Character vector of categorical variable names. If provided, a select input will appear
#'  in the options dropdown allowing for data groups to be visualised as stacked bars on the epicurve.
#'  If named, names are used as variable labels.
#' @param title Header title for the card.
#' @param icon The icon to display next to the title.
#' @param tooltip additional title hover text information
#' @param opts_btn_lab text label for the dropdown menu button.
#' @param date_lab text label for the date variable input.
#' @param date_int_lab text label for the date interval input.
#' @param date_intervals Character vector with choices for date aggregation intervals passed to the `unit`
#'  argument of [lubridate::floor_date]. If named, names are used as labels. Default is c('day', 'week', 'year').
#' @param count_vars_lab text label for the aggregate count variables input.
#' @param groups_lab text label for the grouping variable input.
#' @param no_grouping_lab text label for the no grouping option in the grouping input.
#' @param bar_stacking_lab text label for bar stacking option.
#' @param cumul_data_lab text label for cumulative data option.
#' @param ratio_line_lab text label for the ratio line input. This input will only be visable if
#'  `show_ratio` is TRUE in [time_server]
#' @param zoom_control_lab text label for the zoom control option.
#' @param full_screen Add button to card to with the option to enter full screen mode?
#' @param use_sidebar Logical. If TRUE, displays options in a sidebar instead of popover button. Default TRUE.
#' @param sidebar_title String. Title for the sidebar. Only used if use_sidebar = TRUE. Default "Chart options".
#' @param sidebar_width Numeric. Width of sidebar in pixels. Only used if use_sidebar = TRUE. Default 250.
#'
#' @return the module server function returns any point click event data of the highchart.
#'   see [highcharter::hc_add_event_point] for details.
#' @import shiny
#' @export

time_ui <- function(
  id,
  date_vars,
  count_vars = NULL,
  group_vars = NULL,
  title = "Time",
  icon = bsicons::bs_icon("calendar2-week"),
  tooltip = NULL,
  opts_btn_lab = "Chart options",
  date_lab = "Date axis",
  date_int_lab = "Date interval",
  date_intervals = c("Day" = "day", "Week" = "week", "Month" = "month"),
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
) {
  ns <- NS(id)

  # check deps are installed
  pkg_deps <- c("highcharter", "lubridate")
  if (!rlang::is_installed(pkg_deps)) {
    rlang::check_installed(pkg_deps, reason = "to use the epishiny time module.")
  }

  if (length(tooltip)) {
    tt <- bslib::tooltip(
      bsicons::bs_icon("info-circle", class = "ms-2 text-primary", size = "1.2em"),
      tooltip
    )
  } else {
    tt <- NULL
  }

  inputs_ui <- time_options_ui(
    ns = ns,
    date_vars = date_vars,
    date_lab = date_lab,
    date_int_lab = date_int_lab,
    date_intervals = date_intervals,
    count_vars = count_vars,
    count_vars_lab = count_vars_lab,
    group_vars = group_vars,
    groups_lab = groups_lab,
    no_grouping_lab = no_grouping_lab,
    bar_stacking_lab = bar_stacking_lab,
    cumul_data_lab = cumul_data_lab,
    ratio_line_lab = ratio_line_lab,
    zoom_control_lab = zoom_control_lab
  )

  tagList(
    use_epishiny(),
    bslib::card(
      # min_height = 300,
      full_screen = full_screen,
      bslib::card_header(
        class = "d-flex align-items-center",
        # title
        tags$span(icon, title, class = "me-auto pe-2"),
        # tooltip if provided
        tt,
        # options button - popover or sidebar toggle
        if (!use_sidebar) {
          # Popover mode
          bslib::popover(
            title = opts_btn_lab,
            id = ns("popover"),
            placement = "left",
            trigger = bsicons::bs_icon(
              "gear",
              title = opts_btn_lab,
              class = "ms-2 text-primary",
              size = "1.2em"
            ),
            inputs_ui
          )
        } else {
          # Sidebar mode - gear icon toggles sidebar
          actionLink(
            ns("toggle_sidebar"),
            label = bsicons::bs_icon("gear", size = "1.2em"),
            class = "ms-2 text-primary"
          ) |>
            bslib::tooltip(opts_btn_lab)
        }
      ),
      # Conditional card body based on layout mode
      if (use_sidebar) {
        # Sidebar layout
        bslib::card_body(
          padding = 0,
          bslib::layout_sidebar(
            padding = c(0, 35, 0, 0),
            gap = 0,
            sidebar = bslib::sidebar(
              id = ns("time_sidebar"),
              title = sidebar_title,
              width = sidebar_width,
              position = "right",
              open = "closed",
              inputs_ui
            ),
            highcharter::highchartOutput(ns("chart"))
          )
        )
      } else {
        # Popover layout - just chart in body
        bslib::card_body(
          padding = 0,
          highcharter::highchartOutput(ns("chart"))
        )
      }
    )
  )
}


#' @param df Data frame or tibble of patient level or aggregated data. Can be either a shiny reactive or static dataset.
#' @param show_ratio Display a ratio line on the epicurve?
#' @param ratio_var For patient level data, character string of variable name to use for ratio calculation.
#' @param ratio_lab The label to describe the computed ratio i.e. 'CFR' for case fatality ratio.
#' @param ratio_numer For patient level data, Value(s) in `ratio_var` to be used for the ratio numerator i.e. 'Death'.
#'  For aggregated data, character string of numeric count column to use of ratio numerator i.e. 'deaths'.
#' @param ratio_denom For patient level data, values in `ratio_var` to be used for the ratio denominator i.e. `c('Death', 'Recovery')`.
#'  For aggregated data, character string of numeric count column to use of ratio denominator i.e. 'cases'.
#' @param group_pal Colour palette used for groups.
#' @param na_colour Colour used for missing data.
#' @param filter_info If contained within an app using [filter_server()], supply the `filter_info` object
#'   returned by that function here to add filter information to chart exports.
#' @param filter_reset If contained within an app using [filter_server()], supply the `filter_reset` object
#'   returned by that function here to reset any click event filters that have been set from by module.
#' @param place_filter supply the output of [place_server()] here to filter
#'   the data by click events on the place module map (clicking a polygon
#'   will filter the data to the clicked region)
#'
#' @rdname time
#'
#' @importFrom dplyr .data
#' @export
time_server <- function(
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
) {
  shiny::moduleServer(
    id,
    function(input, output, session) {
      ns <- session$ns

      # Toggle sidebar when gear icon clicked
      observeEvent(input$toggle_sidebar, {
        bslib::sidebar_toggle("time_sidebar")
      })

      if (is.null(group_vars)) {
        shinyjs::hide("group")
      }

      if (length(date_vars) < 2) {
        shinyjs::hide("date")
      }

      if (length(count_vars) < 2) {
        shinyjs::hide("count_var")
      }

      if (!show_ratio) {
        shinyjs::hide("show_ratio_line")
      }

      observe({
        cond <- input$group != "n"
        if (!cond) {
          shinyWidgets::updateRadioGroupButtons(session, "bar_stacking", selected = "normal")
        }
        shinyjs::toggle("bar_stacking", condition = cond, anim = TRUE)
      })

      df_mod <- reactive({
        df_out <- force_reactive(df)
        pf <- place_filter()
        if (length(pf)) {
          df_out <- df_out %>% dplyr::filter(.data[[pf$geo_col]] == pf$region_select)
        }
        df_out
      })

      # adjust filter info if click event filtering has taken place
      filter_info_out <- reactive({
        fi <- filter_info()
        pf <- place_filter()
        format_filter_info(fi, pf = pf)
      })

      # variables and labels etc
      rv <- reactiveValues()

      observe({
        date <- input$date
        rv$date <- date
        rv$date_sym <- rlang::sym(date)
        count_var <- input$count_var
        rv$count_var <- count_var
        group <- input$group
        rv$group <- group
        rv$group_sym <- rlang::sym(group)
        is_agg <- as.logical(length(count_vars))
        rv$missing_dates <- if (!is_agg) {
          sum(is.na(df_mod()[[input$date]]))
        } else {
          df_mod() |>
            dplyr::filter(is.na(.data[[input$date]])) |>
            dplyr::summarise(n = sum(.data[[input$count_var]], na.rm = TRUE)) |>
            dplyr::pull(n)
        }
        n_lab <- get_label(count_var, count_vars)
        rv$n_lab <- n_lab
      })

      df_curve <- reactive({
        # aggregate dates based on input
        df_interval <- df_mod() %>%
          dplyr::mutate(
            !!rv$date_sym := lubridate::floor_date(
              lubridate::as_date(!!rv$date_sym),
              unit = input$date_interval,
              week_start = getOption("epishiny.week.start", 1)
            )
          )

        # is the data pre-aggregated
        is_agg <- as.logical(length(count_vars))
        # is a data grouping variable supplied
        is_grouped <- rv$group != "n"

        df_time <- get_time_df(
          df = df_interval,
          is_agg = is_agg,
          is_grouped = is_grouped,
          date_var = rv$date,
          count_var = rv$count_var,
          group_var = rv$group,
          date_interval = input$date_interval
        )

        if (show_ratio) {
          df_ratio <- get_ratio_df(
            df = df_interval,
            date_var = rv$date,
            is_agg = is_agg,
            ratio_var = ratio_var,
            ratio_lab = ratio_lab,
            ratio_numer = ratio_numer,
            ratio_denom = ratio_denom
          )
          df_time <- df_time %>% dplyr::left_join(df_ratio, by = rv$date)
        }

        return(df_time)
      })

      output$chart <- highcharter::renderHighchart({
        req(df_curve())
        df <- df_curve()
        date <- isolate(rv$date)
        group <- isolate(rv$group)
        date_sym <- isolate(rv$date_sym)
        group_sym <- isolate(rv$group_sym)
        missing_dates <- isolate(rv$missing_dates)
        y_lab <- isolate(rv$n_lab)
        n_var <- dplyr::if_else(
          isolate(input$cumulative),
          "n_c",
          "n"
        )

        shiny::validate(shiny::need(nrow(df) > 0, "No data to display"))

        date_lab <- get_label(date, date_vars)

        if (group == "n") {
          hc <- highcharter::hchart(
            df,
            "column",
            highcharter::hcaes(!!date_sym, !!rlang::sym(n_var)),
            id = "n_bars",
            name = rv$n_lab
          ) %>%
            highcharter::hc_tooltip(shared = TRUE)
        } else {
          group_lab <- get_label(group, group_vars)

          text_legend <- glue::glue(
            '{group_lab}<br/><span style="font-size: 9px; color: #666; font-weight: normal">(click to filter)</span>'
          )

          if (any(is.na(df[[group]]))) {
            df[[group]] <- forcats::fct_na_value_to_level(df[[group]], level = getOption("epishiny.na.label", "(Missing)"))
          }
          n_groups <- dplyr::n_distinct(df[[group]])
          missing_data <- getOption("epishiny.na.label", "(Missing)") %in% unique(df[[group]])
          pal <- prepare_palette(n_groups, missing_data, pal = group_pal, na_colour = na_colour)

          hc <- highcharter::hchart(
            df,
            "column",
            showInNavigator = TRUE,
            highcharter::hcaes(!!date_sym, !!n_var, group = !!group_sym)
          ) %>%
            highcharter::hc_legend(
              title = list(text = text_legend),
              layout = "vertical",
              align = "right",
              verticalAlign = "top",
              x = -10,
              y = 40,
              itemStyle = list(textOverflow = "ellipsis", width = 150)
            ) %>%
            highcharter::hc_colors(pal) %>%
            highcharter::hc_tooltip(
              shared = TRUE,
              pointFormat = '<span style="color:{point.color}">\u25CF</span> {series.name}: <b>{point.y} ({point.percentage:.1f}%)</b><br/>'
            )
        }

        click_js <- highcharter::JS(
          glue::glue(
            'function(event) {
            Shiny.setInputValue("{{ns("chart_click")}}", {x: event.point.x, y: event.point.y}, {priority: "event"});
          }',
            .open = "{{",
            .close = "}}"
          )
        )

        # if a click filter has previously been applied, re-add the plotBand highlight
        tf <- time_filter()
        if (length(tf)) {
          pb_limits <- get_plot_band_limits(tf)
          plot_bands = list(
            list(
              color = "#D3D3D350",
              zIndex = 1,
              from = highcharter::datetime_to_timestamp(pb_limits$from),
              to = highcharter::datetime_to_timestamp(pb_limits$to)
            )
          )
        } else {
          plot_bands = list()
        }

        hc <- hc %>%
          highcharter::hc_title(text = NULL) %>%
          highcharter::hc_chart(zoomType = "x", alignTicks = TRUE) %>%
          highcharter::hc_plotOptions(
            column = list(stacking = isolate(input$bar_stacking)),
            series = list(cursor = "pointer", stickyTracking = TRUE, events = list(click = click_js))
          ) %>%
          highcharter::hc_xAxis(
            title = list(text = date_lab),
            lineColor = "black",
            allowDecimals = FALSE,
            crosshair = TRUE,
            ordinal = TRUE,
            plotBands = plot_bands
          ) %>%
          highcharter::hc_yAxis_multiples(
            list(
              title = list(text = y_lab),
              allowDecimals = FALSE
            ),
            list(
              title = list(text = ""),
              labels = list(enabled = TRUE),
              opposite = TRUE,
              gridLineWidth = 0
            )
          ) %>%
          highcharter::hc_boost(enabled = TRUE) %>%
          my_hc_export(caption = isolate(filter_info_out()))

        if (isolate(input$date_interval == "week")) {
          hc <- hc %>%
            highcharter::hc_xAxis(
              title = list(text = date_lab),
              allowDecimals = FALSE,
              crosshair = TRUE,
              ordinal = TRUE,
              plotBands = plot_bands,
              labels = list(
                formatter = hc_week_labels()
              )
            )
        }

        if (input$add_zoom_control) {
          hc <- hc %>%
            highcharter::hc_rangeSelector(
              enabled = TRUE,
              inputEnabled = FALSE,
              allButtonsEnabled = FALSE,
              selected = 5
            ) %>%
            # add series for navigator
            highcharter::hc_navigator(
              enabled = TRUE,
              series = list(type = "area", stacking = "normal")
            )
        }

        if (isolate(isTruthy(input$show_ratio_line))) {
          r_var <- ifelse(
            isolate(input$cumulative),
            rlang::sym("ratio_c"),
            rlang::sym("ratio")
          )
          hc <- hc %>%
            highcharter::hc_yAxis_multiples(
              list(
                title = list(text = y_lab),
                allowDecimals = FALSE
              ),
              list(
                title = list(text = ratio_lab),
                labels = list(enabled = TRUE, format = "{value}%"),
                gridLineWidth = 1,
                opposite = TRUE
              )
            ) %>%
            highcharter::hc_add_series(
              data = df,
              "line",
              highcharter::hcaes(x = !!date, y = !!r_var),
              id = "ratio_line",
              name = ratio_lab,
              yAxis = 1,
              zIndex = 10,
              color = "black",
              tooltip = list(valueDecimals = 1, valueSuffix = "%")
            )
        }

        if (missing_dates > 0) {
          hc <- hc %>%
            highcharter::hc_credits(
              enabled = TRUE,
              text = glue::glue("Missing {tolower(date_lab)} for {scales::number(missing_dates)} {tolower(y_lab)}")
            )
        }

        hc
      }) %>%
        bindEvent(df_curve(), input$add_zoom_control)

      # update bar stacking type via proxy
      observe({
        highcharter::highchartProxy(ns("chart")) %>%
          highcharter::hcpxy_update(
            plotOptions = list(column = list(stacking = input$bar_stacking))
          )
      }) %>%
        bindEvent(input$bar_stacking, ignoreInit = TRUE)

      # update chart via proxy when cumul/non-cumul data is requested
      shiny::observe({
        df <- df_curve()
        date <- isolate(rv$date)
        group <- isolate(rv$group)
        date_sym <- isolate(rv$date_sym)
        group_sym <- isolate(rv$group_sym)

        if (input$cumulative) {
          n_var <- "n_c"
          r_var <- "ratio_c"
        } else {
          n_var <- "n"
          r_var <- "ratio"
        }

        if (group == "n") {
          highcharter::highchartProxy(ns("chart")) %>%
            highcharter::hcpxy_update_series(
              id = "n_bars",
              data = df[[n_var]]
            )
        } else {
          highcharter::highchartProxy(ns("chart")) %>%
            highcharter::hcpxy_set_data(
              type = "column",
              data = df,
              mapping = highcharter::hcaes(!!date_sym, !!rlang::sym(n_var), group = !!group_sym),
              redraw = TRUE
            )
        }

        if (isTruthy(input$show_ratio_line)) {
          highcharter::highchartProxy(ns("chart")) %>%
            highcharter::hcpxy_update_series(
              id = "ratio_line",
              data = df[[r_var]]
            )
        }
      }) %>%
        shiny::bindEvent(input$cumulative, ignoreInit = TRUE)

      # update chart via proxy when ratio line added or removed
      shiny::observe({
        if (isTruthy(input$show_ratio_line)) {
          df_line <- df_curve()
          r_var <- ifelse(
            input$cumulative,
            rlang::sym("ratio_c"),
            rlang::sym("ratio")
          )

          highcharter::highchartProxy(ns("chart")) %>%
            highcharter::hcpxy_remove_series(id = "ratio_line") %>%
            highcharter::hcpxy_update(
              yAxis = list(
                list(
                  title = list(text = rv$n_lab),
                  allowDecimals = FALSE
                ),
                list(
                  title = list(text = ratio_lab),
                  labels = list(enabled = TRUE, format = "{value}%"),
                  gridLineWidth = 1,
                  opposite = TRUE
                )
              )
            ) %>%
            highcharter::hcpxy_add_series(
              data = df_line,
              "line",
              highcharter::hcaes(x = !!rv$date_sym, y = !!r_var),
              id = "ratio_line",
              name = ratio_lab,
              yAxis = 1,
              zIndex = 10,
              color = "black",
              tooltip = list(valueDecimals = 1, valueSuffix = "%")
            )
        } else {
          highcharter::highchartProxy(ns("chart")) %>%
            highcharter::hcpxy_remove_series(id = "ratio_line") %>%
            highcharter::hcpxy_update(
              yAxis = list(
                list(
                  title = list(text = rv$n_lab),
                  allowDecimals = FALSE
                ),
                list(
                  title = list(text = ""),
                  labels = list(enabled = FALSE),
                  gridLineWidth = 0,
                  opposite = TRUE
                )
              )
            )
        }
      }) %>%
        shiny::bindEvent(input$show_ratio_line, ignoreInit = TRUE)

      # click event management ========================================
      bar_click <- reactiveVal(NULL)

      observe({
        new_click <- input$chart_click$x
        if (identical(bar_click(), new_click)) {
          bar_click(NULL)
        } else {
          bar_click(new_click)
        }
      }) %>%
        bindEvent(input$chart_click)

      # reset bar click if a filter reset is passed from filter module
      observe({
        bar_click(NULL)
      }) %>%
        bindEvent(filter_reset(), ignoreInit = TRUE)

      # reset bar click if date interval is changed
      observe({
        bar_click(NULL)
      }) %>%
        bindEvent(input$date_interval, ignoreInit = TRUE)

      # format chart click input values for filtering
      time_filter <- shiny::reactive({
        bc <- bar_click()
        if (length(bc)) {
          date_var <- input$date
          interval <- input$date_interval
          from <- lubridate::as_datetime(bc / 1000, origin = "1970-01-01")
          # this only makes sense if the interval is a full day or more
          to <- from + lubridate::period(1, input$date_interval) - lubridate::period(1, "day")
          lab <- format_period(c(from, to), interval)
          list(
            date_var = date_var,
            from = from,
            to = to,
            interval = interval,
            lab = lab
          )
        } else {
          return(NULL)
        }
      })

      # show clicked period on chart
      observe({
        tf <- time_filter()
        if (length(tf)) {
          pb_limits <- get_plot_band_limits(tf)
          highcharter::highchartProxy(ns("chart")) %>%
            highcharter::hcpxy_update(
              xAxis = list(
                plotBands = list(
                  list(
                    color = "#D3D3D350",
                    zIndex = 1,
                    from = highcharter::datetime_to_timestamp(pb_limits$from),
                    to = highcharter::datetime_to_timestamp(pb_limits$to)
                  )
                )
              )
            )
        } else {
          # remove plotBands
          highcharter::highchartProxy(ns("chart")) %>%
            highcharter::hcpxy_update(xAxis = list(plotBands = list()))
        }
      }) %>%
        bindEvent(time_filter(), ignoreNULL = FALSE)

      # return time click filter data to main app
      return(reactive(time_filter()))
    }
  )
}

#' @noRd
get_time_df <- function(
  df,
  is_agg,
  is_grouped,
  date_var,
  count_var,
  group_var,
  date_interval
) {
  if (is_agg && !length(count_var)) {
    cli::cli_abort(c(
      "x" = "You must supply a `count_var` variable name if data is aggregated"
    ))
  }

  # Count observations based on aggregation and grouping
  df_counts <- if (!is_grouped) {
    if (is_agg) {
      dplyr::count(df, .data[[date_var]], wt = .data[[count_var]])
    } else {
      dplyr::count(df, .data[[date_var]])
    }
  } else {
    if (is_agg) {
      dplyr::count(df, .data[[date_var]], .data[[group_var]], wt = .data[[count_var]])
    } else {
      dplyr::count(df, .data[[date_var]], .data[[group_var]])
    }
  }

  # Drop missing dates
  df_complete <- df_counts %>% tidyr::drop_na()

  # Handle edge cases: no data or all dates missing
  if (nrow(df_complete) == 0) {
    # Return empty data frame with correct structure
    if (!is_grouped) {
      return(
        dplyr::tibble(
          !!rlang::sym(date_var) := lubridate::Date(),
          n = integer(),
          n_c = integer()
        )
      )
    } else {
      return(
        dplyr::tibble(
          !!rlang::sym(date_var) := lubridate::Date(),
          !!rlang::sym(group_var) := character(),
          n = integer(),
          n_c = integer()
        )
      )
    }
  }

  # Generate complete date sequence
  date_seq <- seq.Date(
    min(df_complete[[date_var]], na.rm = TRUE),
    max(df_complete[[date_var]], na.rm = TRUE),
    by = date_interval
  )

  # Complete date sequence and calculate cumulative counts
  if (!is_grouped) {
    df_complete %>%
      tidyr::complete(
        !!rlang::sym(date_var) := date_seq,
        fill = list(n = 0)
      ) %>%
      dplyr::arrange(.data[[date_var]]) %>%
      dplyr::mutate(n_c = cumsum(.data$n))
  } else {
    df_complete %>%
      tidyr::complete(
        !!rlang::sym(date_var) := date_seq,
        tidyr::nesting(!!rlang::sym(group_var)),
        fill = list(n = 0)
      ) %>%
      dplyr::arrange(.data[[date_var]]) %>%
      dplyr::mutate(
        .by = {{ group_var }},
        n_c = cumsum(.data$n)
      )
  }
}

#' @noRd
get_ratio_df <- function(
  df,
  date_var,
  is_agg,
  ratio_var,
  ratio_lab,
  ratio_numer,
  ratio_denom
) {
  # Validate inputs based on data type
  if (!is_agg) {
    # Patient level data requires ratio_var and both numer/denom levels
    if (any(is.null(ratio_var), is.null(ratio_numer), is.null(ratio_denom), is.null(ratio_lab))) {
      cli::cli_abort(c(
        "x" = "to calculate a ratio from patient level data, the following must be provided:",
        "*" = "`ratio_var`: character string of variable name to use for ratio calculation i.e. 'outcome'",
        "*" = "`ratio_lab`: the axis label to be used for the ratio line i.e. 'CFR'",
        "*" = "`ratio_numer`: character vector of ratio calculation numerator levels(s) found in `ratio_var` i.e. 'death'",
        "*" = "`ratio_denom`: character vector of ratio calculation denominator levels(s) found in `ratio_var` i.e. c('death', 'recovery')",
        "i" = "See ?epishiny::time for details."
      ))
    }
  } else {
    # Aggregated data requires numer/denom column names
    if (any(is.null(ratio_numer), is.null(ratio_denom), is.null(ratio_lab))) {
      cli::cli_abort(c(
        "x" = "to calculate a ratio from aggregated data, the following must be provided in `time_server` module:",
        "*" = "`ratio_numer`: character string variable name of numeric column in data to use for the ratio numerator i.e. 'deaths'",
        "*" = "`ratio_denom`: character string variable name of numeric column in data to use for the ratio denominator i.e. 'cases'",
        "*" = "`ratio_lab`: the axis label to be used for the ratio line i.e. 'CFR'",
        "i" = "See ?epishiny::time for details."
      ))
    }
  }

  # Calculate numerator and denominator based on data type
  if (!is_agg) {
    # Patient level: count matching values in ratio_var
    denom_levels <- unique(c(ratio_numer, ratio_denom))

    df_ratio <- df %>%
      dplyr::summarise(
        .by = {{ date_var }},
        n1 = sum(.data[[ratio_var]] %in% ratio_numer),
        N = sum(.data[[ratio_var]] %in% denom_levels)
      )
  } else {
    # Aggregated: sum pre-aggregated count columns
    df_ratio <- df %>%
      dplyr::summarise(
        .by = {{ date_var }},
        n1 = sum(.data[[ratio_numer]], na.rm = TRUE),
        N = sum(.data[[ratio_denom]], na.rm = TRUE)
      )
  }

  # Common calculation pipeline for both data types
  df_ratio %>%
    dplyr::arrange(.data[[date_var]]) %>%
    dplyr::mutate(
      ratio = (.data$n1 / .data$N) * 100,
      ratio_c = cumsum(.data$n1) / cumsum(.data$N) * 100
    ) %>%
    dplyr::select(dplyr::all_of(c(date_var, "ratio", "ratio_c")))
}

#' @noRd
format_period <- function(date_times, unit) {
  dplyr::case_match(
    unit,
    "day" ~ format(date_times[1], "%a %d %b %Y"),
    "week" ~ format_week(date_times[1]),
    "month" ~ format(date_times[1], "%B %Y"),
    "year" ~ format(date_times[1], "%Y"),
    .default = paste(date_times[1], date_times[2], sep = " - ")
  )
}

#' Copy of internal lubridate:::.other_year funtion
#' Full credit to lubridate authors
#' @noRd
get_epi_year <- function(x, week_start = 1) {
  x <- as.POSIXlt(x)
  date <- lubridate::make_date(lubridate::year(x), lubridate::month(x), lubridate::day(x))
  isodate <- date + lubridate::ddays(4 - lubridate::wday(date, week_start = week_start))
  lubridate::year(isodate)
}

#' Copy of internal lubridate:::.other_week funtion
#' Full credit to lubridate authors
#' @noRd
get_epi_week <- function(x, week_start = 1) {
  x <- as.POSIXlt(x)
  date <- lubridate::make_date(lubridate::year(x), lubridate::month(x), lubridate::day(x))
  wday <- lubridate::wday(x, week_start = week_start)
  date <- date + (4 - wday)
  jan1 <- as.numeric(lubridate::make_date(lubridate::year(date), 1, 1))
  1L + (as.numeric(date) - jan1) %/% 7L
}

#' @noRd
format_week <- function(date, week_start = getOption("epishiny.week.start", 1)) {
  year <- get_epi_year(date, week_start)
  week <- get_epi_week(date, week_start)
  week_lab <- getOption("epishiny.week.letter", "W")
  paste0(year, "-", week_lab, week)
}

#' Calculate plotBand limits from time_filter information
#' @noRd
get_plot_band_limits <- function(tf) {
  if (tf$interval == "day") {
    pad <- lubridate::period(12, "hours")
  } else {
    pad <- lubridate::as.period(lubridate::interval(tf$from, tf$to))$day / 2
    pad <- lubridate::period(ceiling(pad), "day")
  }
  list(
    from = tf$from - pad,
    to = tf$from + pad
  )
}

# =============================================================================
# HELPER FUNCTION FOR OPTIONS UI
# =============================================================================

#' Generate time module options UI
#' @noRd
time_options_ui <- function(
  ns,
  date_vars,
  date_lab,
  date_int_lab,
  date_intervals,
  count_vars,
  count_vars_lab,
  group_vars,
  groups_lab,
  no_grouping_lab,
  bar_stacking_lab,
  cumul_data_lab,
  ratio_line_lab,
  zoom_control_lab
) {
  tagList(
    selectInput(
      ns("date"),
      label = date_lab,
      choices = date_vars,
      multiple = FALSE,
      selectize = FALSE,
      width = "100%"
    ),
    shinyWidgets::radioGroupButtons(
      ns("date_interval"),
      label = date_int_lab,
      size = "sm",
      status = "outline-primary",
      choices = date_intervals,
      selected = ifelse("week" %in% date_intervals, "week", date_intervals[1]),
      width = "100%"
    ),
    selectInput(
      ns("count_var"),
      label = count_vars_lab,
      choices = count_vars,
      multiple = FALSE,
      selectize = FALSE,
      width = "100%"
    ),
    selectInput(
      ns("group"),
      label = groups_lab,
      choices = c(purrr::set_names("n", no_grouping_lab), group_vars),
      multiple = FALSE,
      selectize = FALSE,
      width = "100%"
    ),
    shinyWidgets::radioGroupButtons(
      ns("bar_stacking"),
      label = bar_stacking_lab,
      size = "sm",
      status = "outline-primary",
      choices = c("Count" = "normal", "Percent" = "percent"),
      selected = "normal"
    ),
    bslib::input_switch(
      ns("cumulative"),
      cumul_data_lab,
      value = FALSE,
      width = "100%"
    ),
    bslib::input_switch(
      ns("show_ratio_line"),
      ratio_line_lab,
      value = FALSE,
      width = "100%"
    ),
    bslib::input_switch(
      ns("add_zoom_control"),
      zoom_control_lab,
      value = FALSE,
      width = "100%"
    )
  )
}

# =============================================================================
# TIME MODULE HELPER FUNCTIONS
# =============================================================================

#' Prepare color palette for time module
#' @noRd
prepare_palette <- function(
  n,
  missing_data = FALSE,
  na_colour = "#666666",
  pal = epi_pals()$aurora,
  alpha = 0.8
) {
  if (!length(pal)) {
    pal <- epi_pals()$aurora
  }
  n_pal <- length(pal)
  n_non_na <- ifelse(missing_data, n - 1, n)
  pal <- if (n_non_na > n_pal && n_non_na < 10) {
    grDevices::colorRampPalette(epi_pals()$aurora)(n_non_na)
  } else if (n_non_na > n_pal) {
    epi_pals()$pal20
  } else {
    pal
  }
  if (missing_data) {
    pal[n] <- na_colour
  }
  scales::alpha(pal, alpha)
}

#' Generate week labels for highcharts
#' @noRd
hc_week_labels <- function(week_letter = getOption("epishiny.week.letter", "W")) {
  highcharter::JS(
    glue::glue(
      "function () {
         var date = new Date(this.value);
         var year = date.getWeekYear();
         var week = date.getWeek();
         return year + '-{{week_letter}}' + week;
     }",
      .open = "{{",
      .close = "}}"
    )
  )
}
