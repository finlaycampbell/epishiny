# =============================================================================
# CROSS-MODULE UTILITY FUNCTIONS
# Functions used by multiple modules across the package
# =============================================================================

#' @noRd
use_epishiny <- function() {
  header <- shiny::tags$head(
    tags$script(src = "epishiny/js/main.js"),
    tags$link(rel = "stylesheet", type = "text/css", href = "epishiny/css/styles.css"),
    shinyjs::useShinyjs(),
    waiter::useWaiter()
  )
  shiny::singleton(header)
}

#' Pipe operator re-export
#' @importFrom magrittr %>%
#' @noRd
magrittr::`%>%`

#' Assignment pipe operator re-export
#' @importFrom magrittr %<>%
#' @noRd
magrittr::`%<>%`

#' Definition operator re-export
#' @importFrom rlang :=
#' @noRd
rlang::`:=`

#' Force evaluation of reactive expressions
#'
#' @description
#' Evaluates reactive expressions if the input is reactive, otherwise returns the input as-is
#'
#' @param x A reactive expression or regular value
#' @return The evaluated reactive expression or the original value
#' @noRd
force_reactive <- function(x) {
  if (shiny::is.reactive(x)) {
    x()
  } else {
    x
  }
}

#' Generate timestamp string
#'
#' @description
#' Creates a formatted timestamp string in "YYYY-MM-DD_HHMMSS" format
#'
#' @return Character string containing formatted current timestamp
#' @noRd
time_stamp <- function() {
  format(Sys.time(), "%Y-%m-%d_%H%M%S")
}

#' Generate color palettes
#'
#' @description
#' Returns a list containing predefined color palettes for epidemiological visualizations
#'
#' @return A list containing color palettes:
#'   \item{pal20}{A 20-color palette suitable for categorical data}
#' @noRd
epi_pals <- function() {
  x <- list()

  x$pal20 <- c(
    "#4E79A7FF",
    "#A0CBE8FF",
    "#F28E2BFF",
    "#FFBE7DFF",
    "#59A14FFF",
    "#8CD17DFF",
    "#B6992DFF",
    "#F1CE63FF",
    "#499894FF",
    "#86BCB6FF",
    "#E15759FF",
    "#FF9D9AFF",
    "#79706EFF",
    "#BAB0ACFF",
    "#D37295FF",
    "#FABFD2FF",
    "#B07AA1FF",
    "#D4A6C8FF",
    "#9D7660FF",
    "#D7B5A6FF"
  )

  x$pal10 <- c(
    "#4E79A7FF",
    "#F28E2BFF",
    "#E15759FF",
    "#76B7B2FF",
    "#59A14FFF",
    "#EDC948FF",
    "#B07AA1FF",
    "#FF9DA7FF",
    "#9C755FFF",
    "#BAB0ACFF"
  )

  x$dark2 <- c(
    "#4E79A7",
    "#1B9E77",
    "#D95F02",
    "#7570B3",
    "#E7298A",
    "#66A61E",
    "#E6AB02",
    "#A6761D",
    "#666666"
  )

  x$d310 <- c(
    "#1f77b4",
    "#ff7f0e",
    "#2ca02c",
    "#d62728",
    "#9467bd",
    "#8c564b",
    "#e377c2",
    "#7f7f7f",
    "#bcbd22",
    "#17becf"
  )

  x$vibrant <- c(
    "#0077BB",
    "#33BBEE",
    "#009988",
    "#EE7733",
    "#CC3311",
    "#EE3377"
  )

  x$muted <- c(
    "#332288",
    "#88CCEE",
    "#44AA99",
    "#117733",
    "#999933",
    "#DDCC77",
    "#CC6677",
    "#882255",
    "#AA4499"
  )

  x$aurora <- c("#BF616A", "#D08770", "#EBCB8B", "#A3BE8C", "#B48EAD")

  x$frost <- c("#5E81AC", "#81A1C1", "#88C0D0", "#8FBCBB")

  x
}

#' Get Label for Selected Choice
#'
#' This function retrieves the label for a selected choice from a list of choices.
#'
#' @param selected The selected choice for which the label is to be retrieved.
#' @param choices A named vector of choices from which the label is to be retrieved.
#' @param .default The default label to be used if the selected choice is not found in the choices. Defaults to the value of the "epishiny.count.label" option, or "N" if the option is not set.
#'
#' @return The label corresponding to the selected choice if found in the choices, otherwise the default label.
#'
#' @examples
#' choices <- c(a = "apple", b = "banana", c = "cherry")
#' get_label("b", choices) # Returns "banana"
#' get_label("d", choices) # Returns "N" (default)
#'
#' @noRd
get_label <- function(selected, choices, .default = getOption("epishiny.count.label", "N")) {
  if (length(choices)) {
    lab <- choices[choices == selected]
    ifelse(rlang::is_named(lab), names(lab), lab)
  } else {
    .default
  }
}

#' Format filter information text
#'
#' @description
#' Combines filter information from time, place, and filter modules into formatted HTML
#'
#' @param fi Existing filter info text
#' @param tf Time filter information (list with $lab)
#' @param pf Place filter information (list with $level_name, $region_name)
#'
#' @return HTML formatted filter information string
#' @noRd
format_filter_info <- function(fi = NULL, tf = NULL, pf = NULL) {
  if (length(tf)) {
    if (length(fi)) {
      # since we already have a period filter value from the date input, replace it with bar click period
      fi <- stringr::str_replace(
        fi,
        "\\d{2}/[A-Za-z]{3}/\\d{2} - \\d{2}/[A-Za-z]{3}/\\d{2}",
        tf$lab
      )
    } else {
      fi <- paste("<b>Filters applied</b></br>Period:", tf$lab)
    }
  }
  if (length(pf)) {
    pf_lab <- glue::glue("{pf$level_name}: {pf$region_name}")
    if (length(fi)) {
      fi <- glue::glue("{fi}</br>{pf_lab}")
    } else {
      fi <- paste0("<b>Filters applied</b></br>", pf_lab)
    }
  }
  fi
}

#' Configure highchart export options
#'
#' @description
#' Configures highchart export menu with custom options for download buttons,
#' file naming, and chart appearance. Used by time and person modules.
#'
#' @param hc A highchart object
#' @param title Chart title
#' @param subtitle Chart subtitle
#' @param credits Chart credits text
#' @param caption Chart caption
#' @param colors Chart colors
#' @param width Export width in pixels
#' @param height Export height in pixels
#' @param dl_buttons Vector of download button types
#' @param dl_text Download button text
#' @param filename Base filename for exports (timestamp will be appended)
#'
#' @return Modified highchart object with export configuration
#' @noRd
my_hc_export <- function(
  hc,
  title,
  subtitle,
  credits,
  caption,
  colors,
  width = 900,
  height = 450,
  dl_buttons = c("downloadPNG", "downloadJPEG", "downloadSVG", "separator", "downloadCSV", "downloadXLS"),
  dl_text = "Download",
  filename = "EPI-FIG-"
) {
  set_hc_val <- function(first, second) {
    if (!missing(first)) {
      out <- first
    } else if (!is.null(second)) {
      out <- second
    } else {
      out <- NULL
    }
    return(out)
  }

  title <- set_hc_val(title, hc$x$hc_opts$title$text)
  subtitle <- set_hc_val(subtitle, hc$x$hc_opts$subtitle$text)
  colors <- set_hc_val(colors, hc$x$hc_opts$colors)
  credits <- set_hc_val(credits, hc$x$hc_opts$credits$text)
  show_credits <- ifelse(length(credits), TRUE, FALSE)
  show_caption <- ifelse(length(caption), TRUE, FALSE)

  legend_title <- stringr::str_remove(hc$x$hc_opts$legend$title$text, "\\(click to filter\\)")

  highcharter::hc_exporting(
    hc,
    enabled = TRUE,
    sourceWidth = width,
    sourceHeight = height,
    buttons = list(contextButton = list(align = "right", menuItems = dl_buttons, text = dl_text)),
    filename = paste0(filename, time_stamp()),
    csv = list(dateFormat = "%d/%m/%Y"),
    tableCaption = "",
    useMultiLevelHeaders = FALSE,
    formAttributes = list(target = "_blank"),
    chartOptions = list(
      title = list(text = title),
      subtitle = list(text = subtitle),
      credits = list(enabled = show_credits, text = credits),
      caption = list(enabled = show_caption, text = caption),
      colors = colors,
      legend = list(title = list(text = legend_title)),
      xAxis = list(plotBands = list()), # remove plotbands
      rangeSelector = list(enabled = FALSE),
      navigator = list(enabled = FALSE),
      # plotOptions = list(series = list(dataLabels = list(enabled = TRUE, format="{point.y:,.0f}"))),
      chart = list(backgroundColor = "#fff")
    )
  )
}
