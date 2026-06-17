# Language selector UI

Renders a select input for live language switching. Requires
[`shiny.i18n::usei18n()`](https://appsilon.github.io/shiny.i18n/reference/usei18n.html)
in the UI and
[`language_selector_server()`](https://epicentre-msf.github.io/epishiny/reference/language_selector_server.md)
in the server.

## Usage

``` r
language_selector_ui(
  id = "epishiny_lang",
  label = "Change language",
  position = c("navbar", "inline")
)
```

## Arguments

- id:

  Module id.

- label:

  Label for the select input. Default `"Change language"`.

- position:

  Where to place the selector: `"navbar"` or `"inline"`.

## Value

A Shiny UI element.
