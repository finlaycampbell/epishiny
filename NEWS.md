# epishiny 0.1.0

## Major new features

* **New `epi_dashboard()` function** (#) - A high-level function to quickly build complete epishiny dashboards with your choice of modules (time, place, person, filter). This function handles all the boilerplate UI and server code, making it much easier to create custom dashboards. See `?epi_dashboard` for details and examples.

* **New `launch_module()` function** (#) - Launch individual epishiny modules (time, place, or person) as standalone Shiny apps for quick exploratory data analysis in R.

* **Sidebar layout option** (#) - All visualization modules (time, place, person) now support a `use_sidebar` parameter to display chart options in a sidebar panel instead of a popover button. This provides better UX for complex dashboards with many options.

* **Comprehensive test suite** (#) - Added extensive testthat tests covering all module server functions, helper functions, and utilities, significantly improving code reliability and maintainability.

* **CI/CD workflows** (#) - Added GitHub Actions workflows for automated R CMD check and test coverage reporting.

## Breaking changes

### Filter module API changes

* **`date_var` → `date_vars`** - The filter module now supports multiple date variables. The parameter name has changed from `date_var` (singular) to `date_vars` (plural, named character vector). This allows users to select which date variable to filter on.

  ```r
  # Old (v0.0.x)
  filter_ui("filter", date_var = "date_onset", ...)
  filter_server("filter", date_var = "date_onset", ...)

  # New (v0.1.0)
  filter_ui("filter", date_vars = c("Onset date" = "date_onset"), ...)
  filter_server("filter", date_vars = c("Onset date" = "date_onset"), ...)
  ```

* **Filter module return structure** - The filter module now returns a standard list with reactive components (`$df` and `$filter_info`) rather than a reactive list. This avoids the need to evaluate the reactive function with `()` when passing the outputs to other modules. The modules will evaluate the reactive components as necessary internally. 

The outputs of the time and place server functions can also be passed directly to `time_filter` and `place_filter` arguments without the need for wrapping in a `reactive()` and evaluating.

See below for examples.

  ```r
  app_data <- filter_server(...)
  bar_click <- time_server(...)

  # Old (v0.0.x)
  place_server(
    ...,
    df = reactive(app_data()$df)
    time_filter = reactive(bar_click()),
    filter_info = reactive(app_data()$filter_info)
  )

  # New (v0.1.0)
  place_server(
    ...,
    df = app_data$df,
    time_filter = bar_click,
    filter_info = app_data$filter_info
  )
  ```

### System requirements

* **R version requirement increased** - Minimum R version is now 4.1.0 (previously 2.10). This enables use of the native pipe operator and other modern R features.

### Dependencies

* **Removed dependencies**: `mapsf` (replaced with custom implementation)
* **Added dependencies**: `htmltools`, `classInt`
* **Added suggested packages**: `testthat`, `shinytest2`, `withr`, `mockery`, `covr`

## Improvements

### Filter module

* **Improved date filtering logic** (#) - Better handling when a single date is provided, using a different filtering method for single-date scenarios.

* **Enhanced missing dates handling** (#) - The missing dates checkbox has been converted to a switch and is now only shown when filtering on a single date variable.

* **Customizable wrapper function** (#) - Added `wrapper` parameter to `filter_ui()` allowing you to use a different wrapper function if you don't want the filter UI to be a sidebar.

### Time module

* **Increased chart axis label font sizes** (#) - Default highchart axis label font sizes are now larger for better readability.

* **Improved date interval options** (#) - Better handling and display of date aggregation intervals.

### Place module

* **Independent layer count variable selection** (#) - The choropleth and symbols layers can now display different count variables simultaneously. For example, you can display death rates in the choropleth while showing case counts as symbols, enabling direct comparison of case-fatality patterns. The choropleth layer now has separate "Indicator" and "Display" inputs when multiple count variables are provided.

* **Optimized data preparation** (#) - The `get_geo_counts()` function now calculates sums for ALL count variables upfront when working with aggregated data, improving performance when switching between indicators. Attack rates are also calculated for all count variables when population data is available.

* **Major refactor** (#) - Significant internal restructuring for improved maintainability and performance.

* **Enhanced choropleth options** (#) - Added `choro_pal_default` parameter to set the default color palette for choropleth layers.

* **Improved tooltips** (#) - Better formatted tooltips displaying name, patient counts, population, and attack rates.

### Person module

* **Interactive age breaks** (#) - Users can now modify age breaks directly in the UI when working with numeric age data. Added new UI controls (`age_breaks_lab`, `age_breaks_help`, `age_breaks_apply_lab`) for this feature.

* **Enhanced age breaks handling** (#) - The `age_breaks` parameter now serves as the default, which users can modify through the options menu.

## Bug fixes

* Fixed various edge cases in date filtering logic
* Improved handling of aggregated vs. linelist data across all modules
* Better error messages and validation throughout the package

## New example data

* **`df_ll_measles`** - Measles linelist example dataset
* **`sf_tcd`** - Chad (Tchad) administrative boundary spatial data

## Documentation

* Updated all function documentation with new parameters and clearer examples
* Improved vignettes with updated code examples reflecting API changes
* Updated README with modernized examples
* Enhanced package documentation at https://epicentre-msf.github.io/epishiny/

## Migration guide

To migrate your existing epishiny apps to v0.1.0:

1. **Update filter module calls**:
   - Change `date_var =` to `date_vars =` (make it a named vector)
   - Change `app_data()$df` to `app_data$df`
   - Change `app_data()$filter_info` to `app_data$filter_info`

2. **Remove `reactive()` wrapping**:
   - Change `reactive(bar_click())` to just `bar_click`
   - Change `reactive(map_click())` to just `map_click`
   - Change `reactive(app_data()$filter_info)` to `app_data$filter_info`

3. **Check R version**: Ensure you're using R >= 4.1.0

4. **Optional - Try the new dashboard function**: Consider using `epi_dashboard()` for simpler dashboard creation

See the updated examples in `inst/examples/` for complete working examples with the new API.
