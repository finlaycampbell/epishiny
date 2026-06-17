# Example Measles Linelist Data

A 'linelist' is a (tidy) data format used in public health data
collection with each row representing an individual (patient,
participant, etc) and each column representing a variable associated
with said individual.

## Usage

``` r
df_ll
```

## Format

a tibble dataframe

## Details

`df_ll` is an example linelist dataset containing data for a fake
measles outbreak in Yemen. The data contains temporal, demographic, and
geographic information for each patient, as well as other medical
indicators.

## Examples

``` r
df_ll
#> # A tibble: 1,000 × 30
#>    case_id date_notification date_symptom_start date_hospitalisation_start
#>    <chr>   <date>            <date>             <date>                    
#>  1 P0001   2022-10-07        2022-10-03         NA                        
#>  2 P0002   2022-09-18        2022-09-12         NA                        
#>  3 P0003   2022-04-11        2022-04-01         2022-04-14                
#>  4 P0004   2022-04-16        2022-04-11         2022-04-20                
#>  5 P0005   2022-08-05        2022-07-29         2022-08-09                
#>  6 P0006   2022-10-06        2022-09-30         NA                        
#>  7 P0007   2022-08-01        2022-07-29         NA                        
#>  8 P0008   2022-08-06        2022-07-30         2022-08-11                
#>  9 P0009   2022-05-06        2022-04-30         2022-05-09                
#> 10 P0010   2022-10-13        2022-10-11         NA                        
#> # ℹ 990 more rows
#> # ℹ 26 more variables: date_sample_occurred <date>,
#> #   date_sample_lab_result_occurred <date>, date_hospitalisation_end <date>,
#> #   sex_id <chr>, age_years <dbl>, age_group <fct>, adm1_origin <chr>,
#> #   adm2_origin <chr>, adm3_origin <chr>, adm4_origin <chr>, adm1_pcode <chr>,
#> #   adm2_pcode <chr>, fever <chr>, rash <chr>, cough <chr>, oral_lesions <chr>,
#> #   muac <chr>, oedema <chr>, hospitalised_yn <chr>, measles_stage <chr>, …
```
