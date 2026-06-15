#' Create a mock reactive context for testing
#'
#' @param value Value to wrap in reactive
#' @return A reactive expression
mock_reactive <- function(value) {
  shiny::reactiveVal(value)
}

#' Create a mock reactive values list
#'
#' @param ... Named values to include
#' @return A reactiveValues object
mock_reactive_values <- function(...) {
  shiny::reactiveValues(...)
}

#' Run code in a reactive context
#'
#' @param expr Expression to evaluate
with_reactive_context <- function(expr) {
  shiny::isolate(expr)
}
