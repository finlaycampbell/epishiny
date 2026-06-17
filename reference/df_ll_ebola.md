# Example Ebola Linelist Data

A 'linelist' is a (tidy) data format used in public health data
collection with each row representing an individual (patient,
participant, etc) and each column representing a variable associated
with said individual.

## Usage

``` r
df_ll_ebola
```

## Format

a tibble dataframe

## Details

outbreaks::ebola_sim_clean similated ebola outbreak in Freetown, Sierra
Leone. Ages and admin boundary pcodes were added by the epishiny author.

## Examples

``` r
df_ll_ebola
#> # A tibble: 5,829 × 14
#>    case_id generation date_of_infection date_of_onset date_of_hospitalisation
#>    <chr>        <int> <date>            <date>        <date>                 
#>  1 d1fafd           0 NA                2014-04-07    2014-04-17             
#>  2 f5c3d8           1 2014-04-18        2014-04-21    2014-04-25             
#>  3 6c286a           2 NA                2014-04-27    2014-04-27             
#>  4 0f58c4           2 2014-04-22        2014-04-26    2014-04-29             
#>  5 49731d           0 2014-03-19        2014-04-25    2014-05-02             
#>  6 f9149b           3 NA                2014-05-03    2014-05-04             
#>  7 881bd4           3 2014-04-26        2014-05-01    2014-05-05             
#>  8 40ae5f           4 2014-05-04        2014-05-07    2014-05-08             
#>  9 f547d6           3 2014-05-02        2014-05-07    2014-05-08             
#> 10 f1f60f           4 NA                2014-05-04    2014-05-09             
#> # ℹ 5,819 more rows
#> # ℹ 9 more variables: date_of_outcome <date>, outcome <fct>, age <dbl>,
#> #   gender <fct>, hospital <fct>, lon <dbl>, lat <dbl>, adm3_pcode <chr>,
#> #   adm4_pcode <chr>
```
