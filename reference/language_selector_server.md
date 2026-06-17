# Language selector server

Wires the language select input to
[`shiny.i18n::update_lang()`](https://appsilon.github.io/shiny.i18n/reference/update_lang.html)
for live UI translation updates.

## Usage

``` r
language_selector_server(id = "epishiny_lang", on_change = NULL)
```

## Arguments

- id:

  Module id (must match
  [`language_selector_ui()`](https://epicentre-msf.github.io/epishiny/reference/language_selector_ui.md)).

- on_change:

  Optional function `(lang, session)` called after the language changes.
  Use to refresh `selectInput` choices that cannot use shiny.i18n spans.
