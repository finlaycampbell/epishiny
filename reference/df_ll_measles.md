# Example Measles Linelist Data for Chad

A 'linelist' is a (tidy) data format used in public health data
collection with each row representing an individual (patient,
participant, etc) and each column representing a variable associated
with said individual.

## Usage

``` r
df_ll_measles
```

## Format

a tibble dataframe

## Details

`df_ll_measles` contains simulated measles outbreak data for the Mandoul
region of Chad. The data is derived from
episimdata::moissala_linelist_clean_EN and includes temporal,
demographic, and geographic information for each patient, with
administrative boundary pcodes added for spatial analysis.

## Examples

``` r
df_ll_measles
#> # A tibble: 5,080 × 31
#>       id full_name         sex     age age_unit age_group  region sub_prefecture
#>    <int> <chr>             <chr> <int> <chr>    <fct>      <chr>  <chr>         
#>  1     1 Khadija Idriss    f         3 years    1 - 4 yea… Mando… Moissala      
#>  2     2 Amina Ngardou     f         5 months   < 6 months Mando… Moissala      
#>  3     3 Zeinab Youssouf   f        13 years    5 - 14 ye… Mando… Moissala      
#>  4     6 Djamal Djerassem  m         8 months   6 - 8 mon… Mando… Moissala      
#>  5     7 Idriss Djamal     m         7 months   6 - 8 mon… Mando… Moissala      
#>  6    10 Mahamat Beassem   m         4 months   < 6 months Mando… Moissala      
#>  7    11 Brahim Abakar     m         2 months   < 6 months Mando… Moissala      
#>  8    12 Safia Ngarlem     f         4 years    1 - 4 yea… Mando… Moissala      
#>  9    13 Leila Ngarmbatina f        13 years    5 - 14 ye… Mando… Moissala      
#> 10    14 Nadja Issa        f        29 years    15+ years  Mando… Moissala      
#> # ℹ 5,070 more rows
#> # ℹ 23 more variables: village_commune <chr>, date_onset <date>,
#> #   date_consultation <date>, hospitalisation <chr>, date_admission <date>,
#> #   health_facility_name <chr>, malaria_rdt <chr>, fever <int>, rash <int>,
#> #   cough <int>, red_eye <int>, pneumonia <int>, encephalitis <int>,
#> #   muac <int>, muac_cat <chr>, vacc_status <chr>, vacc_doses <chr>,
#> #   outcome <chr>, date_outcome <date>, epi_classification <chr>, …
```
