# Prime the translator for span-wrapped UI strings

Call before constructing module UI so
[`epishiny_tr_ui()`](https://epicentre-msf.github.io/epishiny/reference/epishiny_tr_ui.md)
returns shiny.i18n spans that
[`shiny.i18n::update_lang()`](https://appsilon.github.io/shiny.i18n/reference/update_lang.html)
can update in the browser. Pair with
[`use_epishiny_i18n()`](https://epicentre-msf.github.io/epishiny/reference/use_epishiny_i18n.md)
once in the app root UI.

## Usage

``` r
prime_epishiny_i18n()
```
