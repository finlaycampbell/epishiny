# Chad Mandoul Region Administrative Boundaries

A list of length 3 containing geographic administrative boundary data
for the Mandoul region of Chad, stored as simple features (sf) objects.
Includes administrative levels 1, 2, and 4 (Region, Sub-Prefecture and
Village/Commune, respectively).

## Usage

``` r
sf_tcd
```

## Format

named list of sf objects

## Details

Each admin level can be joined to the example
[`df_ll_measles`](https://epicentre-msf.github.io/epishiny/reference/df_ll_measles.md)
dataset with a join by specification of `c("pcode" = "adm1_pcode")`,
`c("pcode" = "adm2_pcode")`, and `c("pcode" = "adm4_pcode")`
respectively. These should be passed as the `join_by` field in each
`geo_data` specification passed to
[place_ui](https://epicentre-msf.github.io/epishiny/reference/place.md)
and
[place_server](https://epicentre-msf.github.io/epishiny/reference/place.md).

## Examples

``` r
sf_tcd$adm1
#> Simple feature collection with 1 feature and 9 fields
#> Geometry type: MULTIPOLYGON
#> Dimension:     XY
#> Bounding box:  xmin: 17.03512 ymin: 7.784145 xmax: 18.22466 ymax: 9.650972
#> Geodetic CRS:  WGS 84
#> # A tibble: 1 × 10
#>   adm0_iso3 adm0_sub adm0_name adm1_name pcode       adm1_pop source   lon   lat
#> * <chr>     <chr>    <chr>     <chr>     <chr>          <int> <chr>  <dbl> <dbl>
#> 1 TCD       ALL      Chad      Mandoul   TDDSR201910  1192469 NA      17.6  8.72
#> # ℹ 1 more variable: geometry <MULTIPOLYGON [°]>
sf_tcd$adm2
#> Simple feature collection with 7 features and 10 fields
#> Geometry type: MULTIPOLYGON
#> Dimension:     XY
#> Bounding box:  xmin: 17.03512 ymin: 7.784145 xmax: 18.22466 ymax: 9.650972
#> Geodetic CRS:  WGS 84
#> # A tibble: 7 × 11
#>   adm0_iso3 adm0_sub adm0_name adm1_name adm2_name pcode   adm2_pop source   lon
#> * <chr>     <chr>    <chr>     <chr>     <chr>     <chr>      <int> <chr>  <dbl>
#> 1 TCD       ALL      Chad      Mandoul   Bedaya    TDDSR2…    81183 NA      17.8
#> 2 TCD       ALL      Chad      Mandoul   Bedjondo  TDDSR2…   188196 NA      17.2
#> 3 TCD       ALL      Chad      Mandoul   Bekourou  TDDSR2…    68281 NA      17.4
#> 4 TCD       ALL      Chad      Mandoul   Bouna     TDDSR2…   120721 NA      17.5
#> 5 TCD       ALL      Chad      Mandoul   Goundi    TDDSR2…   232776 NA      17.5
#> 6 TCD       ALL      Chad      Mandoul   Koumra    TDDSR2…   184139 NA      17.5
#> 7 TCD       ALL      Chad      Mandoul   Moissala  TDDSR2…   129855 NA      17.9
#> # ℹ 2 more variables: lat <dbl>, geometry <MULTIPOLYGON [°]>
sf_tcd$adm4
#> Simple feature collection with 1193 features and 12 fields
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: 17.0567 ymin: 7.833333 xmax: 18.14093 ymax: 9.570679
#> Geodetic CRS:  WGS 84
#> # A tibble: 1,193 × 13
#>    adm0_iso3 adm0_sub adm0_name adm1_name adm2_name adm3_name adm4_name pcode   
#>  * <chr>     <chr>    <chr>     <chr>     <chr>     <chr>     <chr>     <chr>   
#>  1 TCD       ALL      Chad      Mandoul   Bedaya    Bedaya    Badbo     TDDSR20…
#>  2 TCD       ALL      Chad      Mandoul   Bedaya    Bedaya    Balemani  TDDSR20…
#>  3 TCD       ALL      Chad      Mandoul   Bedaya    Bedaya    Bateba    TDDSR20…
#>  4 TCD       ALL      Chad      Mandoul   Bedaya    Bedaya    Bedaya    TDDSR20…
#>  5 TCD       ALL      Chad      Mandoul   Bedaya    Bedaya    Begosso   TDDSR20…
#>  6 TCD       ALL      Chad      Mandoul   Bedaya    Bedaya    Beko      TDDSR20…
#>  7 TCD       ALL      Chad      Mandoul   Bedaya    Bedaya    Bendana   TDDSR20…
#>  8 TCD       ALL      Chad      Mandoul   Bedaya    Bedaya    Benguebe  TDDSR20…
#>  9 TCD       ALL      Chad      Mandoul   Bedaya    Bedaya    Bessada   TDDSR20…
#> 10 TCD       ALL      Chad      Mandoul   Bedaya    Bedaya    Boubo     TDDSR20…
#> # ℹ 1,183 more rows
#> # ℹ 5 more variables: adm4_type <chr>, adm4_pop <int>, lon <dbl>, lat <dbl>,
#> #   geometry <POINT [°]>
```
