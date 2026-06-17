# Build a geo layer to be used in the 'place' module

Build a geo layer to be used in the 'place' module

## Usage

``` r
geo_layer(layer_name, sf, name_var, join_by, pop_var = NULL)
```

## Arguments

- layer_name:

  the name of the geo layer, for example 'State', 'Department', 'Admin2'
  etc. If providing multiple layers, layer names must be unique.

- sf:

  geographical data of class 'sf' (simple features).

- name_var:

  character string of the variable name in `sf` containing the names of
  each geographical feature.

- join_by:

  data join specification to join geo layer to a dataset. Should be
  either a single variable name present in both datasets or a named
  vector where the name is the geo layer join variable and the value is
  the join variable of the dataset. i.e. `c("pcode" = "place_code")` LHS
  = geo, RHS = data.

- pop_var:

  character string of the variable name in `sf` containing population
  data for each feature. If provided, attack rates will be shown on the
  map as a choropleth.

## Value

named list of class "epishiny_geo_layer"

## Examples

``` r
geo_layer(
  layer_name = "Governorate",
  sf = sf_yem$adm1,
  name_var = "adm1_name",
  pop_var = "adm1_pop",
  join_by = c("pcode" = "adm1_pcode")
)
#> $layer_name
#> [1] "Governorate"
#> 
#> $sf
#> Simple feature collection with 22 features and 7 fields
#> Geometry type: MULTIPOLYGON
#> Dimension:     XY
#> Bounding box:  xmin: 41.81479 ymin: 12.10665 xmax: 54.5382 ymax: 19
#> Geodetic CRS:  WGS 84
#> First 10 features:
#>    adm0_iso3     adm0_name                   adm1_name pcode adm1_pop
#> 1        YEM Yemen / اليمن                    Ibb / اب  YE11  3117999
#> 2        YEM Yemen / اليمن                Abyan / ابين  YE12   619003
#> 3        YEM Yemen / اليمن Sana'a City / امانة العاصمه  YE13  3981000
#> 4        YEM Yemen / اليمن          Al Bayda / البيضاء  YE14   830001
#> 5        YEM Yemen / اليمن                 Ta'iz / تعز  YE15  3487612
#> 6        YEM Yemen / اليمن             Al Jawf / الجوف  YE16   645000
#> 7        YEM Yemen / اليمن                Hajjah / حجه  YE17  2415001
#> 8        YEM Yemen / اليمن       Al Hodeidah / الحديده  YE18  3653999
#> 9        YEM Yemen / اليمن          Hadramawt / حضرموت  YE19  1618329
#> 10       YEM Yemen / اليمن               Dhamar / ذمار  YE20  2170000
#>                          geometry      lon      lat
#> 1  MULTIPOLYGON (((44.08076 14... 44.18040 14.08362
#> 2  MULTIPOLYGON (((46.29563 14... 46.23681 13.63099
#> 3  MULTIPOLYGON (((44.3338 15.... 44.17556 15.40928
#> 4  MULTIPOLYGON (((44.72676 14... 45.27953 14.32562
#> 5  MULTIPOLYGON (((43.41111 12... 43.78494 13.29334
#> 6  MULTIPOLYGON (((46.34001 17... 45.59372 16.59384
#> 7  MULTIPOLYGON (((42.80233 15... 43.20314 16.09100
#> 8  MULTIPOLYGON (((42.6918 13.... 43.21762 14.78216
#> 9  MULTIPOLYGON (((50.83766 16... 48.63126 16.52279
#> 10 MULTIPOLYGON (((44.70527 14... 44.30275 14.54205
#> 
#> $name_var
#> [1] "adm1_name"
#> 
#> $pop_var
#> [1] "adm1_pop"
#> 
#> $join_by
#>        pcode 
#> "adm1_pcode" 
#> 
#> attr(,"class")
#> [1] "epishiny_geo_layer"
```
