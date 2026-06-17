# Using epishiny with aggregated data

Epidemiological surveillance data is often reported in an aggregated
form by ministries of health. A typical aggregation would be by a
geographical and time unit, cases and deaths by health area and week for
example.

You can use `epishiny` to visualise data in this form by declaring one
or more `count_vars` in the data (numeric columns containing the
aggregation count totals).

Let’s run through an example using [WHO’s COVID-19 daily cases and
deaths dataset](https://covid19.who.int/data). The data contains daily
case and death totals per country, so we can visualise both the time and
place component using `epishiny`.

## Load libraries

``` r

suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(rnaturalearth))
suppressPackageStartupMessages(library(sf))
suppressPackageStartupMessages(library(epishiny))
```

## Import aggregated COVID-19 data from WHO

``` r

df_who_covid <- read_csv("https://covid19.who.int/WHO-COVID-19-global-data.csv")
#> Warning: One or more parsing issues, call `problems()` on your data frame for details,
#> e.g.:
#>   dat <- vroom(...)
#>   problems(dat)
#> Rows: 1351 Columns: 3
#> ── Column specification ────────────────────────────────────────────────────────
#> Delimiter: ","
#> chr (3): <!DOCTYPE html> <html lang="en" dir="ltr"> <head> <!-- head to scra...
#> 
#> ℹ Use `spec()` to retrieve the full column specification for this data.
#> ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.

glimpse(df_who_covid)
#> Rows: 1,351
#> Columns: 3
#> $ `<!DOCTYPE html> <html lang="en" dir="ltr"> <head> <!-- head to scrape:on --> <meta http-equiv="X-UA-Compatible" content="IE=edge` <chr> …
#> $ `chrome=1" /> <meta charset="utf-8" /><meta name="viewport" content="width=device-width`                                           <chr> …
#> $ `initial-scale=1"><meta name="format-detection" content="telephone=no"><title>`                                                    <chr> …
```

## Import country boundaries with rnaturalearth

``` r

world_map <- ne_countries(scale = "small", type = "countries", returnclass = "sf") %>%
  st_transform(crs = 4326) %>%
  select(iso_a2_eh, name, pop_est)

# setup the geo layer for epishiny
geo_data <- geo_layer(
  layer_name = "Country",
  sf = world_map,
  name_var = "name",
  pop_var = "pop_est",
  join_by = c("iso_a2_eh" = "Country_code")
)

geo_data
#> $layer_name
#> [1] "Country"
#> 
#> $sf
#> Simple feature collection with 177 features and 5 fields
#> Geometry type: MULTIPOLYGON
#> Dimension:     XY
#> Bounding box:  xmin: -180 ymin: -90 xmax: 180 ymax: 83.64513
#> Geodetic CRS:  WGS 84
#> First 10 features:
#>    iso_a2_eh                     name   pop_est                       geometry
#> 1         FJ                     Fiji    889953 MULTIPOLYGON (((180 -16.067...
#> 2         TZ                 Tanzania  58005463 MULTIPOLYGON (((33.90371 -0...
#> 3         EH                W. Sahara    603253 MULTIPOLYGON (((-8.66559 27...
#> 4         CA                   Canada  37589262 MULTIPOLYGON (((-122.84 49,...
#> 5         US United States of America 328239523 MULTIPOLYGON (((-122.84 49,...
#> 6         KZ               Kazakhstan  18513930 MULTIPOLYGON (((87.35997 49...
#> 7         UZ               Uzbekistan  33580650 MULTIPOLYGON (((55.96819 41...
#> 8         PG         Papua New Guinea   8776109 MULTIPOLYGON (((141.0002 -2...
#> 9         ID                Indonesia 270625568 MULTIPOLYGON (((141.0002 -2...
#> 10        AR                Argentina  44938712 MULTIPOLYGON (((-68.63401 -...
#>           lon         lat
#> 1   177.97595 -17.9376200
#> 2    34.14207  -6.2078294
#> 3   -12.57202  24.2305626
#> 4  -110.24381  56.7019200
#> 5   -99.31483  37.2367450
#> 6    66.31159  48.0689612
#> 7    63.44288  41.3532772
#> 8   144.22612  -6.6678356
#> 9   113.26946  -0.1785159
#> 10  -64.08055 -37.2391995
#> 
#> $name_var
#> [1] "name"
#> 
#> $pop_var
#> [1] "pop_est"
#> 
#> $join_by
#>      iso_a2_eh 
#> "Country_code" 
#> 
#> attr(,"class")
#> [1] "epishiny_geo_layer"
```

## Define count variables in the data

We are only insterested in the new case and death variables, since the
time module will handle calculating cumulative numbers for us. Here we
supply a named vector to show different variable labels in the module’s
indicator select input.

``` r

count_vars <- c("Cases" = "New_cases", "Deaths" = "New_deaths")
```

## Launch time module

``` r

launch_module(
  module = "time",
  df = df_who_covid,
  date_vars = "Date_reported",
  group_vars = "WHO_region",
  count_vars = count_vars,
  show_ratio = TRUE,
  ratio_lab = "CFR",
  ratio_numer = "New_deaths",
  ratio_denom = "New_cases",
  date_intervals = c("week", "month", "year")
)
```

## Launch place module

``` r

# filter to data in ongoing year for more relevant attack rate estimates
map_data_filter <- df_who_covid %>%
  filter(between(Date_reported, as.Date("2023-01-01"), as.Date("2023-12-31")))

launch_module(
  module = "place",
  df = map_data_filter,
  geo_data = geo_data,
  count_vars = count_vars
)
```

## Launch person module

The COVID-19 data has no age or sex variables so we can’t use the person
module, but for demonstation purposes we will show this can also be used
with an aggregated data set below.

``` r

# create a data set with case and death counts aggregated by age group and sex
age_levels <- c("<5", "5-17", "18-24", "25-34", "35-49", "50+")
sex_levels <- c("Male", "Female")

df_as <- tibble(
  sex = factor(c(rep(sex_levels[1], 6), rep(sex_levels[2], 6))),
  age_group = factor(rep(age_levels, 2), levels = age_levels),
  cases = round(runif(12, 20, 100)),
  deaths = round(runif(12, 0, 20)),
)

df_as
#> # A tibble: 12 × 4
#>    sex    age_group cases deaths
#>    <fct>  <fct>     <dbl>  <dbl>
#>  1 Male   <5           26      1
#>  2 Male   5-17         87      6
#>  3 Male   18-24        68      8
#>  4 Male   25-34        33      4
#>  5 Male   35-49        21      8
#>  6 Male   50+          57      1
#>  7 Female <5           60      8
#>  8 Female 5-17         43     20
#>  9 Female 18-24        79      6
#> 10 Female 25-34        82     14
#> 11 Female 35-49        90     15
#> 12 Female 50+          34      4
```

``` r

# launch the module passing age, sex and count_var info
launch_module(
  module = "person",
  df = df_as,
  age_group_var = "age_group",
  sex_var = "sex",
  male_level = "Male",
  female_level = "Female",
  count_vars = c("cases", "deaths")
)
```
