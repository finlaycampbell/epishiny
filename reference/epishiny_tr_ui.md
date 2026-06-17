# Translate text for live UI updating with shiny.i18n

Returns HTML span elements wired for
[`shiny.i18n::update_lang()`](https://appsilon.github.io/shiny.i18n/reference/update_lang.html).
Only use in UI contexts that accept HTML tags, not for `selectInput`
choices or other attributes requiring plain character strings.

## Usage

``` r
epishiny_tr_ui(text)
```

## Arguments

- text:

  Character vector of text to translate.

## Value

Translated UI tags or character vector.
