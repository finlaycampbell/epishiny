# =============================================================================
# INTERNATIONALIZATION (shiny.i18n)
# =============================================================================

.pkg_i18n <- new.env(parent = emptyenv())
.pkg_i18n$primed <- FALSE

#' Get the epishiny Translator object
#'
#' Returns the package-level [shiny.i18n::Translator] instance, creating it on
#' first use from [inst/translations/translation.json](translations/translation.json).
#'
#' @return A [shiny.i18n::Translator] object.
#' @export
get_epishiny_i18n <- function() {
  if (is.null(.pkg_i18n$translator)) {
    init_epishiny_i18n()
  }
  .pkg_i18n$translator
}

#' Initialise or reset the epishiny Translator
#'
#' @param lang Two-letter language code (e.g. `"en"`, `"fr"`).
#' @return The [shiny.i18n::Translator] object (invisibly).
#' @export
init_epishiny_i18n <- function(lang = "en") {
  translation_path <- system.file(
    "translations",
    "translation.json",
    package = "epishiny"
  )
  if (!nzchar(translation_path)) {
    cli::cli_abort("Could not find translation file. Try re-installing {.pkg epishiny}.")
  }
  .pkg_i18n$translator <- shiny.i18n::Translator$new(
    translation_json_path = translation_path
  )
  set_epishiny_language(lang)
  invisible(.pkg_i18n$translator)
}

#' Set the active translation language
#'
#' Updates the Translator and synchronises package display options
#' (e.g. missing-value labels) with the selected language.
#'
#' @param lang Two-letter language code (e.g. `"en"`, `"fr"`).
#' @return The [shiny.i18n::Translator] object (invisibly).
#' @export
set_epishiny_language <- function(lang) {
  i18n <- get_epishiny_i18n()
  langs <- i18n$get_languages()
  if (!lang %in% langs) {
    cli::cli_abort(c(
      "Language {.val {lang}} is not available.",
      "i" = "Available languages: {.val {langs}}"
    ))
  }
  i18n$set_translation_language(lang)
  options(
    epishiny.na.label = epishiny_lookup("(Missing)"),
    epishiny.count.label = epishiny_lookup("Patients")
  )
  invisible(i18n)
}

#' Language selector UI
#'
#' Renders a select input for live language switching. Requires
#' [shiny.i18n::usei18n()] in the UI and [language_selector_server()] in the
#' server.
#'
#' @param id Module id.
#' @param label Label for the select input. Default `"Change language"`.
#' @param position Where to place the selector: `"navbar"` or `"inline"`.
#'
#' @return A Shiny UI element.
#' @export
language_selector_ui <- function(
  id = "epishiny_lang",
  label = "Change language",
  position = c("navbar", "inline")
) {
  position <- match.arg(position)
  i18n <- get_epishiny_i18n()
  ns <- shiny::NS(id)

  lang_labels <- stats::setNames(
    i18n$get_languages(),
    vapply(i18n$get_languages(), language_display_name, character(1))
  )

  input <- shiny::selectInput(
    ns("language"),
    label = if (position == "navbar") NULL else epishiny_tr_ui(label),
    choices = lang_labels,
    selected = i18n$get_translation_language(),
    width = if (position == "navbar") "150px" else "100%"
  )

  if (position == "navbar") {
    bslib::nav_item(
      tags$div(class = "epishiny-lang-selector py-1", input)
    )
  } else {
    tags$div(class = "epishiny-lang-selector", input)
  }
}

#' Prime the translator for span-wrapped UI strings
#'
#' Call before constructing module UI so [epishiny_tr_ui()] returns
#' shiny.i18n spans that [shiny.i18n::update_lang()] can update in the browser.
#' Pair with [use_epishiny_i18n()] once in the app root UI.
#'
#' @export
prime_epishiny_i18n <- function() {
  if (!isTRUE(.pkg_i18n$primed)) {
    get_epishiny_i18n()$use_js()
    .pkg_i18n$primed <- TRUE
  }
  invisible()
}

#' Include shiny.i18n assets in the app UI
#'
#' @return A Shiny UI tag (singleton).
#' @export
use_epishiny_i18n <- function() {
  shiny::singleton(shiny.i18n::usei18n(get_epishiny_i18n()))
}

#' Language selector server
#'
#' Wires the language select input to [shiny.i18n::update_lang()] for live
#' UI translation updates.
#'
#' @param id Module id (must match [language_selector_ui()]).
#' @param on_change Optional function `(lang, session)` called after the
#'   language changes. Use to refresh `selectInput` choices that cannot use
#'   shiny.i18n spans.
#' @export
language_selector_server <- function(id = "epishiny_lang", on_change = NULL) {
  shiny::moduleServer(id, function(input, output, session) {
    shiny::observeEvent(input$language, {
      shiny.i18n::update_lang(input$language, session = session)
      set_epishiny_language(input$language)
      if (is.function(on_change)) {
        on_change(input$language, session)
      }
    }, ignoreInit = TRUE)
  })
}

#' Update a selectInput after a language change
#'
#' @param session Shiny session.
#' @param inputId Namespaced input id.
#' @param choices_named Named vector with English display names.
#' @param label Optional English label key.
#' @param selected Optional selected value(s).
#' @export
update_epishiny_select <- function(
  session,
  inputId,
  choices_named,
  label = NULL,
  selected = NULL
) {
  args <- list(
    session = session,
    inputId = inputId,
    choices = epishiny_tr_names(choices_named)
  )
  if (!is.null(label)) {
    args$label <- epishiny_lookup(label)
  }
  if (!is.null(selected)) {
    args$selected <- selected
  }
  do.call(shiny::updateSelectInput, args)
}

#' Update a virtualSelectInput label after a language change
#'
#' @param session Shiny session.
#' @param inputId Namespaced input id.
#' @param label English label key.
#' @export
update_epishiny_virtual_select_label <- function(session, inputId, label) {
  shinyWidgets::updateVirtualSelect(
    session = session,
    inputId = inputId,
    label = epishiny_lookup(label)
  )
}

#' Look up plain-text translations (no HTML wrappers)
#'
#' Returns character strings suitable for select choices, options(), and
#' other contexts that require length-one character vectors. Unlike
#' [shiny.i18n::Translator]$`t`(), this never returns `shiny.tag` objects.
#'
#' @param text Character vector of English keys to translate.
#' @noRd
epishiny_lookup <- function(text) {
  if (!length(text)) {
    return(text)
  }
  if (!is.character(text)) {
    return(text)
  }
  i18n <- get_epishiny_i18n()
  lang <- i18n$get_translation_language()
  key_lang <- i18n$get_key_translation()

  # Source language strings are the translation keys (English)
  if (identical(lang, key_lang)) {
    return(text)
  }

  trans <- i18n$get_translations()
  if (!nrow(trans) || !ncol(trans)) {
    return(text)
  }
  col <- names(trans)[1]
  keys <- rownames(trans)
  vapply(
    text,
    function(key) {
      if (key %in% keys) {
        as.character(trans[key, col])
      } else {
        key
      }
    },
    character(1),
    USE.NAMES = FALSE
  )
}

#' Translate text using the active epishiny language
#'
#' Wrapper around the translation table for plain character output. Use this
#' for labels, choices, and options. For live browser-side translation of
#' visible UI fragments after [shiny.i18n::usei18n()] is active, use
#' [epishiny_tr_ui()] instead.
#'
#' @param text Character vector of text to translate.
#' @return Translated character vector.
#' @export
epishiny_tr <- function(text) {
  epishiny_lookup(text)
}

#' Translate text for live UI updating with shiny.i18n
#'
#' Returns HTML span elements wired for [shiny.i18n::update_lang()]. Only use
#' in UI contexts that accept HTML tags, not for `selectInput` choices or
#' other attributes requiring plain character strings.
#'
#' @param text Character vector of text to translate.
#' @return Translated UI tags or character vector.
#' @export
epishiny_tr_ui <- function(text) {
  if (!length(text)) {
    return(text)
  }
  if (!is.character(text)) {
    return(text)
  }
  get_epishiny_i18n()$t(text)
}

#' Translate the names of a named vector
#'
#' Useful for translating display labels in named vectors such as
#' `date_vars` and `group_vars` while preserving column names as values.
#'
#' @param x Named vector with display names.
#' @return A named vector with translated names.
#' @export
epishiny_tr_names <- function(x) {
  if (!length(x) || !rlang::is_named(x)) {
    return(x)
  }
  stats::setNames(x, epishiny_tr(names(x)))
}

#' Human-readable language name for selector labels
#' @param lang Two-letter language code.
#' @noRd
language_display_name <- function(lang) {
  switch(
    lang,
    "en" = "English",
    "fr" = "Français",
    lang
  )
}
