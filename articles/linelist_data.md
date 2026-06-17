# Using epishiny with linelist data

The *epishiny* package can work with pre-aggregated data or with line
lists, i.e. data sets in the form of tables that contain cases as one
line per individual.

The package provides a range of visualisations of different aggregations
of the data that can either be launched as individual modules or as part
of a shiny dashboard that can be run locally or deployed on a server.

In this demonstation we will walk throught the steps of preparing
external data then visualise it by launching individual modules from
within an R script.

## Load in data

The package comes with a built in example line list `df_ll`, but a user
can also bring their own data. Here we will use a line list of Ebola in
Sierra Leone published in Fang et al. ([2016](#ref-Fang2016)).

``` r

suppressPackageStartupMessages(library("readr"))
suppressPackageStartupMessages(library("dplyr"))
suppressPackageStartupMessages(library("purrr"))
suppressPackageStartupMessages(library("sf"))
suppressPackageStartupMessages(library("epishiny"))

url <- paste(
  "https://raw.githubusercontent.com/parksw3/epidist-paper/main/data-raw/",
  "pnas.1518587113.sd02.csv",
  sep = "/"
)
df <- read_csv(url)
#> Rows: 8358 Columns: 8
#> ── Column specification ────────────────────────────────────────────────────────
#> Delimiter: ","
#> chr (6): Name, Sex, Date of symptom onset, Date of sample tested, District, ...
#> dbl (2): ID, Age
#> 
#> ℹ Use `spec()` to retrieve the full column specification for this data.
#> ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.
glimpse(df)
#> Rows: 8,358
#> Columns: 8
#> $ ID                      <dbl> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,…
#> $ Name                    <chr> "*****", "*****", "*****", "*****", "*****", "…
#> $ Age                     <dbl> 20, 42, 45, 15, 19, 55, 50, 8, 54, 57, 50, 27,…
#> $ Sex                     <chr> "F", "F", "F", "F", "F", "F", "F", "F", "F", "…
#> $ `Date of symptom onset` <chr> "18-May-14", "20-May-14", "20-May-14", "21-May…
#> $ `Date of sample tested` <chr> "23-May-14", "25-May-14", "25-May-14", "26-May…
#> $ District                <chr> "Kailahun", "Kailahun", "Kailahun", "Kailahun"…
#> $ Chiefdom                <chr> "Kissi Teng", "Kissi Teng", "Kissi Tonge", "Ki…
```

## Set up geo data

We next need geological data if we want to show maps.

[geoBoundaries](https://www.geoboundaries.org/) host sub-national
administrative boundary shapefiles in various formats for every country
in the world on github.

The line list contains Districts (admin 2 level) and Chiefdoms (admin 3
level). We can download the corresponding data sets from geoBoundaries
via the following URLs.

``` r

shape_paths <- list(
  adm2 = "https://github.com/wmgeolab/geoBoundaries/raw/905b0ba/releaseData/gbHumanitarian/SLE/ADM2/geoBoundaries-SLE-ADM2_simplified.geojson",
  adm3 = "https://github.com/wmgeolab/geoBoundaries/raw/905b0ba/releaseData/gbHumanitarian/SLE/ADM3/geoBoundaries-SLE-ADM3_simplified.geojson"
)

shapes <- map(shape_paths, st_read)
#> Reading layer `geoBoundaries-SLE-ADM2_simplified' from data source 
#>   `https://github.com/wmgeolab/geoBoundaries/raw/905b0ba/releaseData/gbHumanitarian/SLE/ADM2/geoBoundaries-SLE-ADM2_simplified.geojson' 
#>   using driver `GeoJSON'
#> Simple feature collection with 14 features and 5 fields
#> Geometry type: MULTIPOLYGON
#> Dimension:     XY
#> Bounding box:  xmin: -13.30893 ymin: 6.923379 xmax: -10.27056 ymax: 9.999253
#> Geodetic CRS:  WGS 84
#> Reading layer `geoBoundaries-SLE-ADM3_simplified' from data source 
#>   `https://github.com/wmgeolab/geoBoundaries/raw/905b0ba/releaseData/gbHumanitarian/SLE/ADM3/geoBoundaries-SLE-ADM3_simplified.geojson' 
#>   using driver `GeoJSON'
#> Simple feature collection with 167 features and 5 fields
#> Geometry type: MULTIPOLYGON
#> Dimension:     XY
#> Bounding box:  xmin: -13.30901 ymin: 6.923379 xmax: -10.27056 ymax: 9.999253
#> Geodetic CRS:  WGS 84

# little bit of cleaning on district names to match with data
shapes$adm2$shapeName <- gsub("Area ", "", shapes$adm2$shapeName)

map(shapes, head)
#> $adm2
#> Simple feature collection with 6 features and 5 fields
#> Geometry type: MULTIPOLYGON
#> Dimension:     XY
#> Bounding box:  xmin: -13.30893 ymin: 7.340922 xmax: -10.27056 ymax: 9.999253
#> Geodetic CRS:  WGS 84
#>   shapeName shapeISO                 shapeID shapeGroup shapeType
#> 1  Kailahun          92492822B20773800307824        SLE      ADM2
#> 2    Kenema          92492822B72931932323564        SLE      ADM2
#> 3      Kono          92492822B77765797687755        SLE      ADM2
#> 4   Bombali          92492822B76753077936535        SLE      ADM2
#> 5    Kambia          92492822B57757993837772        SLE      ADM2
#> 6 Koinadugu          92492822B53659457212824        SLE      ADM2
#>                         geometry
#> 1 MULTIPOLYGON (((-10.80489 7...
#> 2 MULTIPOLYGON (((-10.85505 8...
#> 3 MULTIPOLYGON (((-10.64344 8...
#> 4 MULTIPOLYGON (((-12.32046 8...
#> 5 MULTIPOLYGON (((-13.2635 8....
#> 6 MULTIPOLYGON (((-10.58741 9...
#> 
#> $adm3
#> Simple feature collection with 6 features and 5 fields
#> Geometry type: MULTIPOLYGON
#> Dimension:     XY
#> Bounding box:  xmin: -11.02525 ymin: 7.758386 xmax: -10.27056 ymax: 8.505881
#> Geodetic CRS:  WGS 84
#>      shapeName shapeISO                 shapeID shapeGroup shapeType
#> 1          Dea          93885176B88884577288656        SLE      ADM3
#> 2        Jawie          93885176B40623889028536        SLE      ADM3
#> 3   Kissi Kama          93885176B21354692554384        SLE      ADM3
#> 4   Kissi Teng          93885176B65469407152324        SLE      ADM3
#> 5  Kissi Tongi          93885176B56250152587449        SLE      ADM3
#> 6 Kpeje Bongre          93885176B52534318264914        SLE      ADM3
#>                         geometry
#> 1 MULTIPOLYGON (((-10.60592 7...
#> 2 MULTIPOLYGON (((-10.91103 7...
#> 3 MULTIPOLYGON (((-10.43962 8...
#> 4 MULTIPOLYGON (((-10.43962 8...
#> 5 MULTIPOLYGON (((-10.39938 8...
#> 6 MULTIPOLYGON (((-10.8119 8....
```

## Launch Modules

Before we launch the modules we can define some grouping variables. If
passed to the `time` or `place` modules, a select input will appear in
the ‘options’ dropdown allowing you to group the data by the variables
you select.

If you want a more readable variable label to appear in the module
rather than the variable name itself, pass a named vector where the name
is the label and the value is the variable name.

In our example we use sex and district as a variable, but since they are
already formatted as labels there is no need to pass names:

``` r

group_vars <- c("Sex", "District")
```

### Place module

Now that we have the shapefiles we can collate the information contained
in the format that *epishiny* expects using the
[`geo_layer()`](https://epicentre-msf.github.io/epishiny/reference/geo_layer.md)
function. Since we are using more than one geo layer, we combine them in
a list:

``` r

geo_data <- list(
  geo_layer(
    layer_name = "District",
    sf = shapes$adm2,
    name_var = "shapeName",
    join_by = c("shapeName" = "District")
  ),
  geo_layer(
    layer_name = "Chiefdom",
    sf = shapes$adm3,
    name_var = "shapeName",
    join_by = c("shapeName" = "Chiefdom")
  )
)
```

We use this to launch the place module:

``` r

launch_module(
  module = "place",
  df = df,
  geo_data = geo_data,
  group_vars = group_vars[1] # only pass sex variable since district is already visualised on map
)
```

If you select the Chiefdom admin 3 level from the options dropdown menu
you will see a warning meassage informing you that more that 50% of the
cases could not be matched to the shapefile, so some matching of
disparate place names would be required in this case. We won’t do that
here but if you need help with this task check out our [hmatch
package](https://epicentre-msf.github.io/hmatch/).

### Time module

To launch the time module, we need to pass the date variable(s) in the
line list we want to use for the x-axis.

Notice that the date variables are of character class in the data but
they are automatically parsed to date class in the time module via the
lubridate::as_date function.

``` r

launch_module(
  module = "time",
  df = df,
  date_vars = c("Date of symptom onset", "Date of sample tested"),
  group_vars = group_vars
)
```

### Person module

Finally, we can plot an age/sex pyramid using the person module, passing
age and sex variable names and the levels in the sex variable to encode
male and female:

``` r

launch_module(
  module = "person",
  df = df,
  age_var = "Age",
  sex_var = "Sex",
  male_level = "M",
  female_level = "F"
)
```

## References

Fang, Li-Qun, Yang Yang, Jia-Fu Jiang, et al. 2016. “Transmission
Dynamics of Ebola Virus Disease and Intervention Effectiveness in Sierra
Leone.” *Proceedings of the National Academy of Sciences* 113 (16):
4488–93. <https://doi.org/10.1073/pnas.1518587113>.
