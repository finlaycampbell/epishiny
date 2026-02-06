pkgload::load_all()

# example package data
data("df_ll_ebola")

# launch person age/sex pyramid module
launch_module(
  module = "person",
  df = df_ll_ebola,
  age_var = "age",
  sex_var = "gender",
  male_level = "m",
  female_level = "f"
)
