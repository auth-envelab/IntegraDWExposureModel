library(IntegraDWExposureModel)

model <- dw_model(
  start_age_years = 30,
  duration_years = 1 / 365.25,
  body_weight = body_weight_constant(70),
  water = water_eu_adult_sparse(mode = "deterministic"),
  chemicals = chemical("example_chemical", conc_fixed(0.01, unit = "mg/L"))
)

result <- run_exposure(
  model,
  mode = "deterministic",
  output = "summary"
)

print(result)
print(chemical_summary(result))
print(daily_summary(result))

# Expected approximate daily mass:
# 0.01 mg/L * 2 L/day = 0.02 mg/day
expected_daily_mass_mg <- 0.01 * 2

# Expected approximate normalized daily dose:
# 0.02 mg/day / 70 kg = 0.0002857143 mg/kg-day
expected_daily_dose_mg_kg_day <- expected_daily_mass_mg / 70

summary_table <- chemical_summary(result)
observed_mass_mg <- summary_table$mean[
  summary_table$chemical_id == "example_chemical" &
    summary_table$metric == "cumulative_ingested_mass"
]
observed_dose_mg_kg_day <- summary_table$mean[
  summary_table$chemical_id == "example_chemical" &
    summary_table$metric == "exposure_period_average_daily_dose"
]

stopifnot(isTRUE(all.equal(
  observed_mass_mg,
  expected_daily_mass_mg,
  tolerance = 1e-12
)))
stopifnot(isTRUE(all.equal(
  observed_dose_mg_kg_day,
  expected_daily_dose_mg_kg_day,
  tolerance = 1e-12
)))
