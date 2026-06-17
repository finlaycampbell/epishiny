library(shiny)
library(bslib)
library(epishiny)

# French UI by default; use init_epishiny_i18n("en") for English
init_epishiny_i18n("fr")

options(
  "epishiny.na.label" = getOption("epishiny.na.label"),
  "epishiny.count.label" = getOption("epishiny.count.label"),
  "epishiny.week.letter" = "W",
  "epishiny.week.start" = 1
)

app_title <- epishiny_tr("epishiny modules")
app_font <- "Roboto Mono"

# example package data
data("df_ll") # linelist
data("sf_yem") # sf geo boundaries for Yemen admin 1 & 2

# setup geo data for adm1 and adm2 in the format
# required for epishiny map module
geo_data <- list(
  geo_layer(
    layer_name = epishiny_tr("Governorate"),
    sf = sf_yem$adm1,
    name_var = "adm1_name",
    pop_var = "adm1_pop",
    join_by = c("pcode" = "adm1_pcode")
  ),
  geo_layer(
    layer_name = epishiny_tr("District"),
    sf = sf_yem$adm2,
    name_var = "adm2_name",
    pop_var = "adm2_pop",
    join_by = c("pcode" = "adm2_pcode")
  )
)

# range of dates used in filter module to filter time period
date_range <- range(df_ll$date_notification, na.rm = TRUE)

# define date variables in data as named list to be used in app
date_vars <- epishiny_tr_names(c(
  "Date of notification" = "date_notification",
  "Date of onset" = "date_symptom_start",
  "Date of hospitalisation" = "date_hospitalisation_start",
  "Date of outcome" = "date_hospitalisation_end"
))

# define categorical grouping variables
# in data as named list to be used in app
group_vars <- epishiny_tr_names(c(
  "Governorate" = "adm1_origin",
  "Sex" = "sex_id",
  "Hospitalised" = "hospitalised_yn",
  "Vaccinated measles" = "vacci_measles_yn",
  "Outcome" = "outcome"
))

