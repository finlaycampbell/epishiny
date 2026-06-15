pkgload::load_all()

# example package data
data("df_ll_ebola")

# define date variables in data as named list to be used in app
date_vars <- c(
  "Date of onset" = "date_of_onset",
  "Date of hospitalisation" = "date_of_hospitalisation",
  "Date of infection" = "date_of_infection",
  "Date of outcome" = "date_of_outcome"
)

# define categorical grouping variables
# in data as named list to be used in app
group_vars <- c(
  "Hospital" = "hospital",
  "Gender" = "gender",
  "Outcome" = "outcome"
)

launch_module(
  module = "time",
  df = df_ll_ebola,
  date_vars = date_vars,
  group_vars = group_vars,
  show_ratio = TRUE,
  ratio_line_lab = "Show CFR line?",
  ratio_var = "outcome",
  ratio_lab = "CFR",
  ratio_numer = "Death",
  ratio_denom = c("Death", "Recover")
)
