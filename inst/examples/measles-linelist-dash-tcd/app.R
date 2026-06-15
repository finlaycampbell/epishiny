library(shiny)
library(bslib)
library(querychat)
# library(epishiny)
pkgload::load_all()

greeting <- paste(readLines(here::here("inst/examples/measles-linelist-dash-tcd/greeting.md")), collapse = "\n")
data_description <- paste(readLines(here::here("inst/examples/measles-linelist-dash-tcd/data-description.md")), collapse = "\n")

querychat_config <- querychat_init(
  df_ll_measles,
  greeting = greeting,
  data_description = data_description,
  extra_instructions = "Use British English spelling when responding in English.",
  create_chat_func = purrr::partial(ellmer::chat_anthropic, model = "claude-sonnet-4-20250514")
)

geo_data <- list(
  # geo_layer(
  #   layer_name = "Region",
  #   sf = sf_tcd$adm1,
  #   name_var = "adm1_name",
  #   pop_var = "adm1_pop",
  #   join_by = c("pcode" = "adm1_pcode") # geo to data join vars: LHS = sf, RHS = data
  # ),
  geo_layer(
    layer_name = "Sub Prefecture",
    sf = sf_tcd$adm2,
    name_var = "adm2_name",
    pop_var = "adm2_pop",
    join_by = c("pcode" = "adm2_pcode") # geo to data join vars: LHS = sf, RHS = data
  ),
  geo_layer(
    layer_name = "Village/Commune",
    sf = sf_tcd$adm4,
    name_var = "adm4_name",
    pop_var = NULL, # no population for this layer
    join_by = c("pcode" = "adm4_pcode") # geo to data join vars: LHS = sf, RHS = data
  )
)

# define date variables in data as named list to be used in app
date_vars <- c(
  "Date of onset" = "date_onset",
  "Date of consultation" = "date_consultation",
  "Date of hospitalisation" = "date_admission",
  "Date of exit" = "date_outcome"
)

# define categorical grouping variables
# in data as named list to be used in app
group_vars <- c(
  "Hospital" = "health_facility_name",
  "Gender" = "sex",
  "Age Group" = "age_group",
  "Classification" = "epi_classification",
  "Vaccination Status" = "vacc_status",
  "MUAC Category" = "muac_cat",
  "Malaria RDT" = "malaria_rdt",
  "Outcome" = "outcome"
)

# user interface
ui <- tagList(
  page_navbar(
    title = tags$span(
      tags$img(
        src = "epishiny/img/logo.png",
        alt = "Epishiny Hex Logo",
        height = "35px"
      ),
      "{epishiny}"
    ),
    window_title = "epishiny",
    id = "tabs",
    navbar_options = navbar_options(collapsible = TRUE, underline = FALSE),
    # theme = bs_theme(
    #   preset = "shiny",
    #   font_scale = .8,
    #   primary = "#4682B4",
    #   secondary = "#D37331",
    #   success = "#94BA3B"
    # ),

    # nav pages
    nav_panel(
      class = "bslib-page-dashboard",
      tags$span(shiny::icon("chart-column"), "Demo"),
      layout_sidebar(
        padding = 10,
        # sidebar
        sidebar = sidebar(
          width = 400,
          bg = "#fff",
          bslib::navset_tab(
            bslib::nav_panel(
              "AI Assistant",
              icon = bsicons::bs_icon("robot"),
              querychat_ui("chat")
            ),
            bslib::nav_panel(
              "Manual Inputs",
              icon = bsicons::bs_icon("sliders2"),
              filter_ui(
                "filter",
                date_vars = date_vars,
                group_vars = group_vars,
                wrapper = \(...) div(class = "mt-2", ...)
              )
            )
          )
        ),
        # sidebar = filter_ui(
        #   "filter",
        #   group_vars = group_vars,
        #   # date_range = date_range,
        #   period_lab = "Onset period"
        # ),
        # main content
        layout_column_wrap(
          width = 1 / 2,
          gap = 10,
          place_ui(
            id = "place",
            tooltip = "Click on a polygon to filter other graphics to this region",
            geo_data = geo_data,
            group_vars = group_vars
          ),
          layout_column_wrap(
            width = 1,
            gap = 10,
            time_ui(
              id = "time",
              tooltip = "Click on a bar to filter other graphics to this period",
              date_vars = date_vars,
              group_vars = group_vars,
              ratio_line_lab = "Show CFR line?"
            ),
            person_ui(id = "person")
          )
        )
      )
    ),
    nav_item(
      tags$a(
        tags$span(shiny::icon("info"), "About"),
        href = "https://epicentre-msf.github.io/epishiny/",
        target = "_blank"
      )
    ),

    # nav images and links
    nav_spacer(),
    nav_item(
      tags$a(
        tags$img(
          src = "epishiny/img/epicentre_logo.png",
          alt = "Epicentre Logo",
          height = "35px"
        ),
        class = "py-0 d-none d-lg-block",
        title = "Epicentre",
        href = "https://epicentre.msf.org/en",
        target = "_blank"
      )
    )
  ),
  # start up loading spinner
  waiter::waiter_preloader(
    html = tagList(
      tags$img(
        src = "epishiny/img/logo.png",
        width = 300,
        style = "padding: 20px;"
      ),
      tags$br(),
      waiter::spin_3()
    ),
    color = "#FFFFFF"
  )
)


# app server
server <- function(input, output, session) {
  app_data <- reactiveVal()

  llm_data <- querychat_server("chat", querychat_config)

  filter_data <- filter_server(
    id = "filter",
    df = df_ll_measles,
    date_vars = date_vars,
    group_vars = group_vars,
    time_filter = bar_click,
    place_filter = map_click
  )

  observe({
    app_data(list(df = llm_data$df()))
  })

  observe({
    app_data(filter_data())
  }) |>
    bindEvent(filter_data(), ignoreInit = TRUE)

  map_click <- place_server(
    id = "place",
    df = app_data$df,
    geo_data = geo_data,
    group_vars = group_vars,
    choro_lab = "Attack rate</br>/100 000",
    choro_pal = hrbrthemes::flexoki_extended$red[1:10],
    show_parent_borders = TRUE,
    time_filter = bar_click
    # filter_info = app_data$filter_info
  )
  bar_click <- time_server(
    id = "time",
    df = app_data$df,
    date_vars = date_vars,
    group_vars = group_vars,
    show_ratio = TRUE,
    ratio_var = "outcome",
    ratio_lab = "CFR",
    ratio_numer = "dead",
    ratio_denom = c("dead", "recovered", "left against medical advice"),
    place_filter = map_click
    # filter_info = app_data$filter_info
  )
  person_server(
    id = "person",
    df = app_data$df,
    age_group_var = "age_group",
    # age_var = "age",
    # age_breaks = c(seq(0, 50, by = 5), Inf), # 5 year intervals
    sex_var = "sex",
    male_level = "m",
    female_level = "f",
    time_filter = bar_click,
    place_filter = map_click
    # filter_info = app_data$filter_info
  )
}

# launch app
if (interactive()) {
  shinyApp(ui, server)
}
