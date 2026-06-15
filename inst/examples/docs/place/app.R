pkgload::load_all()

# example package data
data("df_ll_ebola")
data("sf_sle")

# setup geo data for admin 3 and admin 4 using the
# geo_layer function to be passed to the place module
# if population variable is provided, attack rates
# will be shown on the map as a choropleth
geo_data <- list(
  geo_layer(
    layer_name = "Admin 3", # name of the boundary level
    sf = sf_sle$adm3, # sf object with boundary polygons
    name_var = "adm3_name", # column with place names
    pop_var = "adm3_pop", # column with population data (optional)
    join_by = c("pcode" = "adm3_pcode") # geo to data join vars: LHS = sf, RHS = data
  ),
  geo_layer(
    layer_name = "Admin 4",
    sf = sf_sle$adm4,
    name_var = "adm4_name",
    join_by = c("pcode" = "adm4_pcode")
  )
)

# define categorical grouping variables
# in data as named list to be used in app
group_vars <- c(
  "Hospital" = "hospital",
  "Gender" = "gender",
  "Outcome" = "outcome"
)

# launch place map module
launch_module(
  module = "place",
  df = df_ll_ebola,
  geo_data = geo_data,
  group_vars = group_vars
)
