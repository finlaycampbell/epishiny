# Yemen Governorate (adm1) and District (adm2) Administrative Boundaries

A list of length 2 containing geographic administrative boundary data
for Yemen, stored as simple features (sf) objects.

## Usage

``` r
sf_yem
```

## Format

named list of sf objects

## Details

Each admin level can be joined to the example
[`df_ll`](https://epicentre-msf.github.io/epishiny/reference/df_ll.md)
dataset with a join by specification of `c("pcode" = "adm1_pcode")` and
`c("pcode" = "adm2_pcode")` respectively. These should be passed as the
`join_by` field in each `geo_data` specification passed to
[place_ui](https://epicentre-msf.github.io/epishiny/reference/place.md)
and
[place_server](https://epicentre-msf.github.io/epishiny/reference/place.md).

## Examples

``` r
sf_yem$adm1
#> Simple feature collection with 22 features and 5 fields
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
#>                          geometry
#> 1  MULTIPOLYGON (((44.08076 14...
#> 2  MULTIPOLYGON (((46.29563 14...
#> 3  MULTIPOLYGON (((44.3338 15....
#> 4  MULTIPOLYGON (((44.72676 14...
#> 5  MULTIPOLYGON (((43.41111 12...
#> 6  MULTIPOLYGON (((46.34001 17...
#> 7  MULTIPOLYGON (((42.80233 15...
#> 8  MULTIPOLYGON (((42.6918 13....
#> 9  MULTIPOLYGON (((50.83766 16...
#> 10 MULTIPOLYGON (((44.70527 14...
sf_yem$adm2
#> Simple feature collection with 335 features and 6 fields
#> Geometry type: MULTIPOLYGON
#> Dimension:     XY
#> Bounding box:  xmin: 41.81479 ymin: 12.10665 xmax: 54.5382 ymax: 19
#> Geodetic CRS:  WGS 84
#> First 10 features:
#>    adm0_iso3     adm0_name adm1_name                  adm2_name  pcode adm2_pop
#> 1        YEM Yemen / اليمن  Ibb / اب            Al Qafr / القفر YE1101   152248
#> 2        YEM Yemen / اليمن  Ibb / اب               Yarim / يريم YE1102   257878
#> 3        YEM Yemen / اليمن  Ibb / اب         Ar Radmah / الرضمه YE1103   111778
#> 4        YEM Yemen / اليمن  Ibb / اب       An Nadirah / النادره YE1104   108243
#> 5        YEM Yemen / اليمن  Ibb / اب         Ash Sha'ir / الشعر YE1105    58233
#> 6        YEM Yemen / اليمن  Ibb / اب          As Saddah / السده YE1106   119880
#> 7        YEM Yemen / اليمن  Ibb / اب      Al Makhadir / المخادر YE1107   166083
#> 8        YEM Yemen / اليمن  Ibb / اب             Hobeish / حبيش YE1108   152918
#> 9        YEM Yemen / اليمن  Ibb / اب Hazm Al Odayn / حزم العدين YE1109   115630
#> 10       YEM Yemen / اليمن  Ibb / اب Far' Al Odayn / فرع العدين YE1110   130477
#>                          geometry
#> 1  MULTIPOLYGON (((43.82405 14...
#> 2  MULTIPOLYGON (((44.2682 14....
#> 3  MULTIPOLYGON (((44.4855 14....
#> 4  MULTIPOLYGON (((44.4946 14....
#> 5  MULTIPOLYGON (((44.307 14.0...
#> 6  MULTIPOLYGON (((44.44934 14...
#> 7  MULTIPOLYGON (((44.22156 14...
#> 8  MULTIPOLYGON (((44.01363 14...
#> 9  MULTIPOLYGON (((44.05006 14...
#> 10 MULTIPOLYGON (((43.80641 14...
```
