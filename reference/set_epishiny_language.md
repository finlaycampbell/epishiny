# Set the active translation language

Updates the Translator and synchronises package display options (e.g.
missing-value labels) with the selected language.

## Usage

``` r
set_epishiny_language(lang)
```

## Arguments

- lang:

  Two-letter language code (e.g. `"en"`, `"fr"`).

## Value

The
[shiny.i18n::Translator](https://appsilon.github.io/shiny.i18n/reference/Translator.html)
object (invisibly).
