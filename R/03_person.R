#' Person module
#'
#' Visualise age and sex demographics in a population pyramid chart and summary table.
#'
#' @rdname person
#'
#' @param id Module id. Must be the same in both the UI and server function to link the two.
#' @param count_vars If data is aggregated, variable name(s) of count variable(s) in data. If more than one variable is provided,
#'  a select input will appear in the options menu. If named, names are used as variable labels.
#' @param title The title for the card.
#' @param icon The icon to display next to the title.
#' @param opts_btn_lab The label for the options button.
#' @param count_vars_lab text label for the aggregate count variables input.
#' @param full_screen Add button to card to with the option to enter full screen mode?
#' @param age_breaks_lab The label for the age breaks input.
#' @param age_breaks_help Help text for the age breaks input.
#' @param age_breaks_apply_lab The label for the apply breaks button.
#' @param use_sidebar Logical. If TRUE, displays options in a sidebar instead of popover button. Default FALSE.
#' @param sidebar_title String. Title for the sidebar. Only used if use_sidebar = TRUE. Default NULL.
#' @param sidebar_width Numeric. Width of sidebar in pixels. Only used if use_sidebar = TRUE. Default 250.
#'
#' @return A [bslib::navset_card_tab] UI element with chart and table tabs.
#' @export
#' @example inst/examples/docs/app.R
person_ui <- function(
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
) {
  ns <- shiny::NS(id)
  prime_epishiny_i18n()

  # Translate UI labels (spans for live language switching)
  title <- epishiny_tr_ui(title)
  opts_btn_lab <- epishiny_tr_ui(opts_btn_lab)
  count_vars_lab <- epishiny_tr_ui(count_vars_lab)
  age_breaks_lab <- epishiny_tr_ui(age_breaks_lab)
  age_breaks_help <- epishiny_tr_ui(age_breaks_help)
  age_breaks_apply_lab <- epishiny_tr_ui(age_breaks_apply_lab)
  if (is.null(sidebar_title)) {
    sidebar_title <- epishiny_tr_ui("Options")
  } else {
    sidebar_title <- epishiny_tr_ui(sidebar_title)
  }

  # check deps are installed
  pkg_deps <- c("highcharter", "gt", "gtsummary")
  if (!rlang::is_installed(pkg_deps)) {
    rlang::check_installed(pkg_deps, reason = "to use the epishiny person module.")
  }

  inputs_ui <- person_options_ui(
    ns = ns,
    count_vars = count_vars,
    count_vars_lab = count_vars_lab,
    age_breaks_lab = age_breaks_lab,
    age_breaks_help = age_breaks_help,
    age_breaks_apply_lab = age_breaks_apply_lab
  )

  bslib::layout_columns(
    id = "person-container",
    bslib::navset_card_tab(
      full_screen = full_screen,
      id = ns("tabs"),
      sidebar = if (!use_sidebar) {
        NULL
      } else {
        bslib::sidebar(
          id = ns("person_sidebar"),
          title = sidebar_title,
          width = sidebar_width,
          position = "right",
          open = "closed",
          inputs_ui
        )
      },
      wrapper = function(...) {
        bslib::card_body(..., padding = if (!use_sidebar) 0 else c(0, 35, 0, 0))
      },
      title = tags$div(
        # removes unwanted padding around nav_panels if using sidebar
        tags$style(HTML(
          "#person-container .bslib-sidebar-layout > .main {
          padding: 0 !important;
        }"
        )),
        class = "d-flex align-items-center",
        tags$span(icon, title, class = "pe-2"),
        # options button - popover or sidebar toggle (only if options are needed)
        if (!use_sidebar) {
          # Popover mode
          bslib::popover(
            title = opts_btn_lab,
            id = ns("popover"),
            placement = "left",
            trigger = bsicons::bs_icon(
              "gear",
              title = opts_btn_lab,
              class = "ms-auto ms-2 text-primary",
              size = "1.2em"
            ),
            inputs_ui
          )
        } else {
          # Sidebar mode - gear icon toggles sidebar
          actionLink(
            ns("toggle_sidebar"),
            label = bsicons::bs_icon("gear", size = "1.2em"),
            class = "ms-auto ms-2 text-primary"
          ) |>
            bslib::tooltip(opts_btn_lab)
        }
      ),
      bslib::nav_panel(
        title = shiny::icon("chart-bar") |> bslib::tooltip(epishiny_tr("Chart")),
        class = "p-0",
        highcharter::highchartOutput(ns("as_pyramid"))
      ),
      bslib::nav_panel(
        title = bsicons::bs_icon("table") |> bslib::tooltip(epishiny_tr("Table")),
        class = "p-0",
        tags$div(
          id = ns("as_tbl_container"),
          style = "min-height: 300px;",
          gt::gt_output(ns("as_tbl"))
        )
      )
    )
  )
}

#' @param df Data frame or tibble of patient level or aggregated data. Can be either a shiny reactive or static dataset.
#' @param age_var The name of a numeric age variable in the data.
#'  If ages have already been binned into groups, use `age_group_var` instead.
#' @param age_group_var The name of a character/factor variable in the data with age groups.
#'  If specified, `age_var` is ignored.
#' @param sex_var The name of the sex variable in the data.
#' @param male_level The level representing males in the sex variable.
#' @param female_level The level representing females in the sex variable.
#' @param age_breaks A numeric vector specifying default age breaks for age groups.
#'   Users can modify these via the options menu when using numeric age data.
#' @param age_labels Labels corresponding to the age breaks.
#' @param age_var_lab The label for the age variable.
#' @param age_group_lab The label for the age group variable.
#' @param colours Vector of 2 colours to represent male and female, respectively.
#' @param filter_info If contained within an app using [filter_server()], supply the `filter_info` object
#'   returned by that function here to add filter information to chart exports.
#' @param time_filter supply the output of [time_server()] here to filter
#'   the data by click events on the time module bar chart (clicking a bar
#'   will filter the data to the period the bar represents)
#' @param place_filter supply the output of [place_server()] here to filter
#'   the data by click events on the place module map (clicking a polygon
#'   will filter the data to the clicked region)
#'
#' @rdname person
#'
#' @export
person_server <- function(
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
  # age_labels = c("<5", "5-17", "18-24", "25-34", "35-49", "50+"),
  age_var_lab = "Age (years)",
  age_group_lab = "Age group",
  # colours = c("#19a0aa", "#f15f36"),
  colours = epi_pals()$frost[1:2],
  filter_info = shiny::reactiveVal(),
  time_filter = shiny::reactiveVal(),
  place_filter = shiny::reactiveVal()
) {
  shiny::moduleServer(
    id,
    function(input, output, session) {
      ns <- session$ns

      if (length(count_vars) < 2) {
        # shinyjs::hide("dropdown")
        shinyjs::hide("count_var")
      }

      # loading spinner for summary table
      w_tbl <- waiter::Waiter$new(
        id = ns("as_tbl_container"),
        html = waiter::spin_3(),
        color = waiter::transparent(alpha = 0)
      )

      # Toggle sidebar when gear icon clicked
      observeEvent(input$toggle_sidebar, {
        bslib::sidebar_toggle("person_sidebar")
      })

      age_labels <- reactiveVal(age_labels)

      # Make age_breaks reactive
      age_breaks_current <- reactiveVal(age_breaks)

      # Initialize text input with server's age_breaks (without Inf)
      updateTextInput(
        session,
        "age_breaks_text",
        value = paste(age_breaks[!is.infinite(age_breaks)], collapse = ", ")
      )

      # Parse and validate text input in real-time
      parsed_breaks <- reactive({
        req(input$age_breaks_text)
        parse_age_breaks(input$age_breaks_text)
      })

      # Enable/disable apply button based on validation
      observe({
        result <- parsed_breaks()
        if (result$valid) {
          shinyjs::enable("age_breaks_apply")
        } else {
          shinyjs::disable("age_breaks_apply")
        }
      })

      # Render validation message
      output$age_breaks_validation <- renderUI({
        result <- parsed_breaks()
        if (result$message != "") {
          class <- if (result$valid) "text-muted" else "text-danger"
          tags$small(class = class, result$message)
        }
      })

      # Apply breaks when button clicked
      observeEvent(input$age_breaks_apply, {
        result <- parsed_breaks()
        if (result$valid) {
          age_breaks_current(result$breaks)
          # Auto-generate labels from breaks
          new_labels <- label_breaks(result$breaks, lab_accuracy = 1)
          age_labels(new_labels)
        }
      })

      # Hide age breaks input if using pre-binned age_group_var
      if (!is.null(age_group_var)) {
        shinyjs::hide("age_breaks_text")
        shinyjs::hide("age_breaks_apply")
        shinyjs::hide("age_breaks_validation")
      }

      df_prep <- reactive({
        df <- force_reactive(df)
        df$sex <- df[[sex_var]]
        # ensure sex var is factor
        if (!is.factor(df$sex)) {
          df$sex <- forcats::fct_na_value_to_level(
            factor(df$sex, c(male_level, female_level)),
            getOption("epishiny.na.label", "(Missing)")
          )
        }
        # bin ages if we're working with a numeric variable
        if (is.null(age_group_var)) {
          if (is.null(age_var)) {
            cli::cli_abort("if {.arg age_group_var} if not provided then {.arg age_var} must be.", call = NULL)
          }
          if (!is.numeric(df[[age_var]])) {
            cli::cli_abort(
              "{.arg age_var} must be numeric. Use {.arg age_group_var} instead if ages have already been binned into groups.",
              call = NULL
            )
          }
          df <- df %>% bin_ages(age_var, age_breaks_current(), age_labels())
        } else {
          # ensure age_group is a factor
          df$age_group <- df[[age_group_var]]
          if (!is.factor(df$age_group)) {
            if (!is.character(df$age_group)) {
              cli::cli_abort("{.arg age_group_var} must be a factor or character variable of age groups.", call = NULL)
            }
            cli::cli_warn(
              "{.arg age_group_var} should be a factor. Coercing to factor but levels may not be in the desired order.",
              call = "person_server()"
            )
            df$age_group <- forcats::fct_na_value_to_level(
              df$age_group,
              getOption("epishiny.na.label", "(Missing)")
            )
          }
          labs <- levels(df$age_group)
          labs <- labs[labs != getOption("epishiny.na.label", "(Missing)")]
          age_labels(labs)
        }
        df
      })

      # filter by time and place click events if and when they occur
      df_mod <- reactive({
        df_out <- df_prep()
        pf <- place_filter()
        if (length(pf)) {
          df_out <- df_out %>% dplyr::filter(.data[[pf$geo_col]] == pf$region_select)
        }
        tf <- time_filter()
        if (length(tf)) {
          df_out <- df_out %>% dplyr::filter(dplyr::between(.data[[tf$date_var]], tf$from, tf$to))
        }
        df_out
      })

      # adjust filter info if click event filtering has taken place
      filter_info_out <- reactive({
        fi <- filter_info()
        tf <- time_filter()
        pf <- place_filter()
        format_filter_info(fi, tf, pf)
      })

      hc_dat <- reactive({
        get_as_df(
          df = df_mod(),
          count_var = input$count_var,
          age_group_var = age_group_var,
          age_var = age_var,
          sex_var = sex_var,
          male_level = male_level,
          female_level = female_level,
          age_breaks = age_breaks_current(),
          age_labels = age_labels()
        )
      })

      output$as_pyramid <- highcharter::renderHighchart({
        shiny::validate(shiny::need(nrow(df_mod()) > 0, epishiny_tr("No data to display")))

        # prepare data for pyramid chart
        hc_dat <- hc_dat()

        # build the chart
        hc_as_pyramid(
          df_age_sex = hc_dat$df_age_sex,
          missing_age = hc_dat$missing_age,
          missing_sex = hc_dat$missing_sex,
          colours = colours,
          ylab = epishiny_tr(age_group_lab),
          value_name = get_label_tr(input$count_var, count_vars),
          filter_info = filter_info_out()
        )
      }) %>%
        bindEvent(NULL, ignoreNULL = FALSE) # only run once then update via proxy

      observe({
        hc_dat <- hc_dat()
        df_age_sex <- hc_dat$df_age_sex

        if (nrow(df_age_sex) == 0) {
          highcharter::highchartProxy(ns("as_pyramid")) %>%
            highcharter::hcpxy_update_series(
              id = male_level,
              data = 0
            ) %>%
            highcharter::hcpxy_update_series(
              id = female_level,
              data = 0
            )
        } else {
          var_select <- input$cnt_pcnt
          max_value <- max(abs(df_age_sex[[var_select]]))
          x_levels <- levels(df_age_sex$age_group)
          x_levels <- x_levels[x_levels != getOption("epishiny.na.label", "(Missing)")]
          xaxis <- list(
            categories = x_levels,
            reversed = FALSE,
            title = list(text = epishiny_tr(age_group_lab))
          )
          value_lab <- paste(
            get_label_tr(input$count_var, count_vars),
            ifelse(var_select == "n", "", "(%)")
          )
          value_suffix <- ifelse(var_select == "n", "", "%")

          series <- df_age_sex %>%
            dplyr::group_by(sex) %>%
            dplyr::arrange(age_group) %>%
            dplyr::do(data = .data[[var_select]]) %>%
            dplyr::ungroup() %>%
            dplyr::rename(id = sex) %>%
            dplyr::mutate(name = paste(epishiny_tr(as.character(.data$id)), value_suffix)) %>%
            highcharter::list_parse()

          highcharter::highchartProxy(ns("as_pyramid")) |>
            highcharter::hcpxy_update(
              xAxis = list(
                xaxis,
                purrr::list_modify(xaxis, opposite = TRUE, linkedTo = 0)
              ),
              yAxis = list(
                title = list(text = value_lab),
                min = -max_value,
                max = max_value
              ),
              exporting = list(
                chartOptions = list(caption = list(text = filter_info_out()))
              )
            ) |>
            highcharter::hcpxy_update_series(
              id = series[[1]]$id,
              name = series[[1]]$name,
              data = series[[1]]$data
            ) |>
            highcharter::hcpxy_update_series(
              id = series[[2]]$id,
              name = series[[2]]$name,
              data = series[[2]]$data
            )
        }

        n_used <- sum(abs(hc_dat$df_age_sex$n), na.rm = TRUE)
        credit_lines <- c(
          if (sum(hc_dat$missing_age, hc_dat$missing_sex, na.rm = TRUE) > 0) {
            format_missing_demographics(
              hc_dat$missing_age,
              hc_dat$missing_sex
            )
          },
          format_plot_n(n_used, get_label_tr(input$count_var, count_vars))
        )
        txt <- glue::glue_collapse(credit_lines, sep = " | ")
        highcharter::highchartProxy(ns("as_pyramid")) %>%
          highcharter::hcpxy_update(
            credits = list(enabled = TRUE, text = txt),
            exporting = list(
              chartOptions = list(credits = list(text = txt))
            )
          )
      }) %>%
        bindEvent(hc_dat(), input$cnt_pcnt, ignoreInit = TRUE)

      output$as_tbl <- gt::render_gt({
        # show loading spinner
        shiny::validate(shiny::need(nrow(df_mod()) > 0, epishiny_tr("No data to display")))
        w_tbl$show()
        on.exit(w_tbl$hide())

        df_gt <- df_mod()

        if (length(count_vars)) {
          df_gt <- df_gt %>%
            dplyr::select(dplyr::all_of(c("sex", "age_group", input$count_var))) |>
            tidyr::uncount(.data[[input$count_var]])
        }

        df_gt %>%
          dplyr::select(dplyr::all_of(c("sex", "age_group"))) |>
          dplyr::mutate(
            sex = factor(
              epishiny_tr(as.character(.data$sex)),
              levels = epishiny_tr(c(male_level, female_level, getOption("epishiny.na.label", "(Missing)")))
            )
          ) |>
          gtsummary::tbl_summary(
            by = "sex",
            label = list(
              # age_var ~ age_var_lab,
              "age_group" ~ epishiny_tr(age_group_lab)
            ),
            missing_text = epishiny_tr(getOption("epishiny.na.label", "(Missing)")),
            # type = list(age_var ~ "continuous2"),
            # digits = list(age_var ~ c(2, 0, 0, 0, 0, 0)),
            # statistic = gtsummary::all_continuous() ~ c("{mean}",
            #                                             "{median} ({p25}, {p75})",
            #                                             "{min}, {max}")
          ) %>%
          gtsummary::modify_header(
            gtsummary::all_stat_cols() ~ "**{level}**, N = {n} ({gtsummary::style_percent(p, digits = 1)}%)"
          ) %>%
          gtsummary::add_overall(
            col_label = paste0("**", epishiny_tr("Total"), "**, N = {N}")
          ) %>%
          gtsummary::italicize_levels() %>%
          gtsummary::remove_footnote_header(columns = gtsummary::all_stat_cols()) %>%
          # gtsummary::modify_footnote_header(update = gtsummary::everything() ~ NA) %>%
          gtsummary::bold_labels() %>%
          gtsummary::as_gt()
      })
    }
  )
}

#' @noRd
hc_as_pyramid <- function(
  df_age_sex,
  missing_age,
  missing_sex,
  value_name = "Patients",
  value_digit = 0,
  value_unit = "",
  title = NULL,
  xlab = value_name,
  ylab = "Age group",
  colours = c("#f15f36", "#19a0aa"),
  filter_info = NULL
) {
  max_value <- max(abs(df_age_sex$n))
  x_levels <- levels(df_age_sex$age_group)
  x_levels <- x_levels[x_levels != getOption("epishiny.na.label", "(Missing)")]
  xaxis <- list(categories = x_levels, reversed = FALSE, title = list(text = ylab))

  series <- df_age_sex %>%
    dplyr::group_by(sex) %>%
    dplyr::arrange(age_group) %>%
    dplyr::do(data = .data$n) %>%
    dplyr::ungroup() %>%
    dplyr::rename(id = sex) %>%
    dplyr::mutate(name = epishiny_tr(as.character(.data$id))) %>%
    highcharter::list_parse()

  hc_out <- highcharter::highchart() %>%
    highcharter::hc_chart(type = "bar") %>%
    highcharter::hc_add_series_list(series) %>%
    highcharter::hc_plotOptions(
      bar = list(
        stacking = "normal",
        groupPadding = 0.05,
        pointPadding = 0.05,
        borderWidth = 0.05,
        dataLabels = list(
          enabled = FALSE,
          formatter = highcharter::JS("function(){ return Math.abs(this.y); }")
        )
      )
    ) %>%
    highcharter::hc_yAxis(
      title = list(text = xlab),
      labels = list(
        formatter = highcharter::JS("function(){ return Math.abs(this.value); }")
      ),
      plotBands = list(
        list(color = "black", width = 1, value = 0, zIndex = 10)
      ),
      min = -max_value,
      max = max_value,
      allowDecimals = FALSE
    ) %>%
    highcharter::hc_xAxis(
      xaxis,
      purrr::list_modify(xaxis, opposite = TRUE, linkedTo = 0)
    ) %>%
    highcharter::hc_colors(colours) %>%
    highcharter::hc_tooltip(
      shared = FALSE,
      formatter = hc_as_tooltip(age_lab = epishiny_tr("Age"))
    ) %>%
    highcharter::hc_legend(
      enabled = TRUE,
      reversed = FALSE,
      verticalAlign = "top",
      align = "center"
    ) %>%
    highcharter::hc_title(text = NULL)

  n_used <- sum(abs(df_age_sex$n), na.rm = TRUE)
  credit_lines <- c(
    if (sum(missing_age, missing_sex) > 0) {
      format_missing_demographics(missing_age, missing_sex)
    },
    format_plot_n(n_used, value_name)
  )
  hc_out <- hc_out %>%
    highcharter::hc_credits(
      enabled = TRUE,
      text = glue::glue_collapse(credit_lines, sep = " | ")
    )

  hc_out %>% my_hc_export(caption = filter_info, width = 700)
}

hc_as_tooltip <- function(age_lab = "Age") {
  highcharter::JS(
    sprintf(
      "function () { 
      var isProp = this.series.name.endsWith('%%'); 
      var decimals = isProp ? 1 : 0; 
      var unit = isProp ? '%%' : ''; 
      var name_clean = this.series.name.replace(' %%', '').replace('%%', '');
      return '<b>' + name_clean + ', %s ' + this.point.category + '</b><br/>' + Highcharts.numberFormat(Math.abs(this.point.y), decimals) + unit; 
    }",
      tolower(age_lab)
    )
  )
}

#' @noRd
get_as_df <- function(
  df,
  sex_var,
  male_level,
  female_level,
  age_group_var,
  age_var,
  age_breaks = c(0, 5, 18, 25, 35, 50, Inf),
  age_labels = c("<5", "5-17", "18-24", "25-34", "35-49", "50+"),
  count_var = NULL
) {
  sex_levels <- c(male_level, female_level)
  # get missing data numbers depending on whether data is pre-aggregated or not
  if (length(count_var)) {
    missing_sex <- df %>%
      dplyr::filter(!sex %in% sex_levels | is.na(sex)) %>%
      dplyr::pull(.data[[count_var]]) %>%
      sum(na.rm = TRUE)
    missing_age <- df %>%
      dplyr::filter(is.na(age_group) | age_group == getOption("epishiny.na.label", "(Missing)")) %>%
      dplyr::pull(.data[[count_var]]) %>%
      sum(na.rm = TRUE)
  } else {
    missing_sex <- nrow(dplyr::filter(df, !sex %in% sex_levels | is.na(sex)))
    missing_age <- sum(is.na(df$age_group) | df$age_group == getOption("epishiny.na.label", "(Missing)"))
  }

  df_age_sex <- df %>%
    dplyr::filter(sex %in% sex_levels) %>%
    dplyr::mutate(sex = droplevels(sex))
  # if data is pre-aggregated add the count_var weight to the count function
  if (length(count_var)) {
    df_age_sex <- df_age_sex %>%
      dplyr::count(sex, age_group, wt = .data[[count_var]]) %>%
      tidyr::complete(
        sex = factor(sex_levels, sex_levels),
        age_group,
        fill = list(n = 0)
      )
  } else {
    df_age_sex <- df_age_sex %>%
      dplyr::count(sex, age_group) %>%
      tidyr::complete(
        sex = factor(sex_levels, sex_levels),
        age_group = factor(age_labels, age_labels),
        fill = list(n = 0)
      )
  }
  df_age_sex <- df_age_sex %>%
    dplyr::mutate(
      n_prop = (.data$n / sum(.data$n)) * 100,
      n = dplyr::if_else(sex == male_level, -.data$n, .data$n),
      n_prop = dplyr::if_else(sex == male_level, -.data$n_prop, .data$n_prop)
    ) %>%
    dplyr::filter(!is.na(sex), !is.na(age_group)) %>%
    dplyr::arrange(sex, age_group)

  tibble::lst(df_age_sex, missing_age, missing_sex)
}


#' @noRd
bin_ages <- function(
  df,
  age_var,
  age_breaks = c(0, 5, 18, 25, 35, 50, Inf),
  age_labels = c("<5", "5-17", "18-24", "25-34", "35-49", "50+")
) {
  dplyr::mutate(
    df,
    age_group = cut(
      .data[[age_var]],
      breaks = age_breaks,
      labels = age_labels,
      include.lowest = TRUE,
      right = FALSE
    )
  )
}

#' Parse and validate age breaks from text input
#' @return List with breaks (numeric vector or NULL), valid (logical), message (string)
#' @noRd
parse_age_breaks <- function(text) {
  result <- list(breaks = NULL, valid = FALSE, message = "")

  # Parse text to numeric
  breaks <- tryCatch(
    {
      vals <- strsplit(trimws(text), "\\s*,\\s*")[[1]]
      nums <- suppressWarnings(as.numeric(vals))
      if (any(is.na(nums))) {
        stop("Non-numeric")
      }
      nums
    },
    error = function(e) {
      result$message <<- epishiny_tr(
        "Invalid format. Use numbers separated by commas."
      )
      return(NULL)
    }
  )

  if (is.null(breaks)) {
    return(result)
  }

  # Filter out any Inf values user might have typed (we add it ourselves)
  breaks <- breaks[!is.infinite(breaks)]

  # Validation checks
  if (length(breaks) < 2) {
    result$message <- epishiny_tr("At least 2 breaks required")
    return(result)
  }

  # Check strictly increasing
  if (any(diff(breaks) <= 0)) {
    result$message <- epishiny_tr("Breaks must be strictly increasing")
    return(result)
  }

  # Warn if doesn't start with 0
  if (breaks[1] != 0) {
    result$message <- epishiny_tr("Warning: Recommended to start with 0")
  }

  # Always add Inf at the end
  breaks <- c(breaks, Inf)

  result$breaks <- breaks
  result$valid <- TRUE
  result
}

# =============================================================================
# HELPER FUNCTION FOR OPTIONS UI
# =============================================================================

#' Generate person module options UI
#' @noRd
person_options_ui <- function(
  ns,
  count_vars,
  count_vars_lab,
  age_breaks_lab,
  age_breaks_help,
  age_breaks_apply_lab
) {
  tagList(
    if (length(count_vars)) {
      shinyWidgets::radioGroupButtons(
        ns("count_var"),
        label = count_vars_lab,
        choices = count_vars,
        size = "sm",
        status = "outline-primary"
      )
    },
    shinyWidgets::radioGroupButtons(
      ns("cnt_pcnt"),
      label = epishiny_tr("Display"),
      choices = stats::setNames(
        c("n", "n_prop"),
        c(epishiny_tr("Counts"), epishiny_tr("Percentages"))
      ),
      size = "sm",
      status = "outline-primary"
    ),
    textInput(
      ns("age_breaks_text"),
      label = tags$span(
        age_breaks_lab,
        bslib::tooltip(
          bsicons::bs_icon("info-circle"),
          age_breaks_help
        )
      ),
      # Default value - will be updated from server
      value = ""
    ),
    # tags$small(class = "text-muted", age_breaks_help),
    actionButton(
      ns("age_breaks_apply"),
      label = age_breaks_apply_lab,
      class = "btn-sm btn-primary w-100 mt-2"
    ),
    uiOutput(ns("age_breaks_validation"))
  )
}

# =============================================================================
# PERSON MODULE HELPER FUNCTIONS
# =============================================================================

#' Format break labels
#'
#' @param breaks numeric vector of breaks
#' @param lab_accuracy accuracy of labels, passed to [`scales::number`]
#' @param replace_Inf if `Inf` is your final break, replace with a + sign in the label?
#'
#' @noRd
label_breaks <- function(breaks, lab_accuracy = .1, replace_Inf = TRUE) {
  labs <- sprintf(
    "%s-%s",
    frmt_num(breaks[1:length(breaks) - 1], accuracy = lab_accuracy),
    frmt_num(breaks[2:length(breaks)] - 1, accuracy = lab_accuracy)
  )
  if (replace_Inf) {
    labs <- gsub("-Inf", "+", labs)
  }
  return(labs)
}

#' Format numbers with scale units when large
#'
#' @param x a number to format
#' @param accuracy accuracy of labels, passed to [`scales::number`]
#'
#' @noRd
frmt_num <- function(x, accuracy = .1) {
  n <- scales::number(x, accuracy = accuracy, scale_cut = scales::cut_short_scale())
  n <- stringr::str_remove(n, "\\.0+(?=[a-zA-Z])")
  n <- stringr::str_remove(n, "\\.0+$")
  n
}

# to avoid warnings during R CMD check
utils::globalVariables(c("sex", "age_group", "n"))
