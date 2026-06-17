# Translate text using the active epishiny language

Wrapper around the translation table for plain character output. Use
this for labels, choices, and options. For live browser-side translation
of visible UI fragments after
[`shiny.i18n::usei18n()`](https://appsilon.github.io/shiny.i18n/reference/usei18n.html)
is active, use
[`epishiny_tr_ui()`](https://epicentre-msf.github.io/epishiny/reference/epishiny_tr_ui.md)
instead.

## Usage

``` r
epishiny_tr(text)
```

## Arguments

- text:

  Character vector of text to translate.

## Value

Translated character vector.
