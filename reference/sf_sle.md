# Sierra Leone Western Area Administrative Boundaries

A list of length 2 containing geographic administrative boundary data
for Sierra Leone, stored as simple features (sf) objects.

## Usage

``` r
sf_sle
```

## Format

named list of sf objects

## Details

Each admin level can be joined to the example
[`df_ll_ebola`](https://epicentre-msf.github.io/epishiny/reference/df_ll_ebola.md)
dataset with a join by specification of `c("pcode" = "adm3_pcode")` and
`c("pcode" = "adm4_pcode")` respectively. These should be passed as the
`join_by` field in each `geo_data` specification passed to
[place_ui](https://epicentre-msf.github.io/epishiny/reference/place.md)
and
[place_server](https://epicentre-msf.github.io/epishiny/reference/place.md).

## Examples

``` r
sf_sle$adm1
#> NULL
sf_sle$adm2
#> NULL
```
