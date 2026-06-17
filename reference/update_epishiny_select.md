# Update a selectInput after a language change

Update a selectInput after a language change

## Usage

``` r
update_epishiny_select(
  session,
  inputId,
  choices_named,
  label = NULL,
  selected = NULL
)
```

## Arguments

- session:

  Shiny session.

- inputId:

  Namespaced input id.

- choices_named:

  Named vector with English display names.

- label:

  Optional English label key.

- selected:

  Optional selected value(s).
