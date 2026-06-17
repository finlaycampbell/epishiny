# Contributing

`epishiny` welcomes new module contributions to the package as well as
feature improvements to existing modules. Contributors will require a
solid understanding of how the R
[`shiny`](https://shiny.posit.co/r/getstarted/shiny-basics/lesson1/index.html)
web-framework works and the ability to program with reactive objects, as
well as knowledge of how to organise your code as a composable shiny
‘module’. See the [Mastering Shiny
book](https://mastering-shiny.org/index.html) and the [modules
chapter](https://mastering-shiny.org/index.html) to learn more.

An understanding of how an R package is structured is also required and
how to prepare functions for exportation with appropriate documentation
using the
[`roxygen2`](https://cran.r-project.org/web/packages/roxygen2/vignettes/roxygen2.html)
package.

## Workflow

Contributions should be made as pull-requests on github from your own
fork of the source package, which will then be reviewed by package
maintainers.

## Package Structure

Below is the current package structure at 2 levels of recursion:

    .
    ├── DESCRIPTION
    ├── LICENSE
    ├── LICENSE.md
    ├── NAMESPACE
    ├── R
    │   ├── 01_time.R
    │   ├── 02_place.R
    │   ├── 03_person.R
    │   ├── 04_filter.R
    │   ├── 05_launch.R
    │   ├── utils.R
    │   └── zzz.R
    ├── README.Rmd
    ├── README.md
    ├── _pkgdown.yml
    ├── data
    │   ├── df_ll.rda
    │   └── sf_yem.rda
    ├── data-raw
    │   ├── data.R
    │   └── linelist-example.xlsx
    ├── epishiny.Rproj
    ├── inst
    │   ├── assets
    │   │   ├── img
    │   │   └── js
    │   └── examples
    │       ├── demo
    │       └── docs
    ├── man
    │   ├── figures
    │   │   ├── dashboard.png
    │   │   ├── person.png
    │   │   ├── place.png
    │   │   └── time.png
    │   ├── filter.Rd
    │   ├── launch_demo_dashboard.Rd
    │   ├── launch_module.Rd
    │   ├── person.Rd
    │   ├── place.Rd
    │   └── time.Rd
    └── vignettes
        └── contributing.Rmd

The important directory is the `R` directory. This is the source code of
the package and where any code contributions must live. To contribute a
new module, create a new R script inside this directory with a number
and concise, informative name. Add your module UI and server functions
to this script as well as any helper functions specific to this module.
More general utility functions can be added to the `R/utils.R` script.

## Standards

New modules will need to meet certain criteria to be able to work in
harmony with the other modules in the package.

### User Interface

The primary requirement is to use UI components from the [`bslib`
package](https://rstudio.github.io/bslib/index.html). `bslib` provides a
modern UI toolkit for Shiny and R Markdown based on Bootstrap. Default
shiny UI uses an old version of Bootstrap (v3) but `bslib` provides
access to newer versions (latest currently v5). The package is
maintained by Posit, the authors of shiny, and is now their recommended
shiny UI framework. See the [package
website](https://rstudio.github.io/bslib/index.html) for documentation
on all of the available components.

If your module will produce a single graphic or table output, it is
recommended to use a
[`bslib::card()`](https://rstudio.github.io/bslib/reference/card.html)
as the module UI wrapper. If you need multiple tabs within the module
use
[`bslib::navset_card_tab()`](https://rstudio.github.io/bslib/reference/navset.html).
See the package’s [card
article](https://rstudio.github.io/bslib/articles/cards/index.html#multiple-tabs)
for more details and features.

**Don’t forget to wrap any input IDs in your module UI in the `ns()`
namespace function. See an existing module UI function for examples.**

### Server

There are no specific requirements for the module server code to meet
other than to try to be as efficienct and fast as possible.

### Outputs

The package currently uses the
[highcharter](https://jkunst.com/highcharter/index.html) package for
interactive graphics, [leaflet](https://rstudio.github.io/leaflet/) for
interactive maps and
[reactable](https://glin.github.io/reactable/index.html) and
[gtsummary](https://www.danieldsjoberg.com/gtsummary/) packages for
tables. It is recommended to use one of these packages for your outputs,
if possible, to maintain style and functionality across modules, and to
reduce the number of dependencies (more below).

### Dependencies

Due to the large scope of this package the number of dependencies is
already large with multiple htmlwidget libraries being used. Efforts
should be made to keep only include essential dependencies in your
contribution. For example, if you import a library to use a single
simple function, it is recommended to code this as your own utility
function within the package and avoid importing the external package.

### Code style

Please follow the [Tidyverse style
guide](https://style.tidyverse.org/index.html) as much as possible. Use
the [styler](https://styler.r-lib.org/) package to restyle code before
submitting a pull-request.
