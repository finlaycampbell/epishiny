# Launch epishiny demo dashboard

See an example of the type of dashboard you can build using `epishiny`
modules within a `bslib` UI.

## Usage

``` r
launch_demo_dashboard(disease = "ebola")
```

## Arguments

- disease:

  name of disease demo dashboard to launch. Current options are "ebola"
  and "measles".

## Value

No return value, a shiny app is launched.

## Examples

``` r
## Only run this example in interactive R sessions
if (interactive()) {
  library(epishiny)
  launch_demo_dashboard("ebola")
}
```
