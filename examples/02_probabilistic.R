library(IntegraDWExposureModel)

# Probabilistic trajectories are alternative possible histories for the same
# specified individual, not different people.
model <- dw_model(
  start_age_years = 30,
  duration_years = 7 / 365.25,
  body_weight = body_weight_constant(70),
  water = water_eu_adult_sparse(mode = "probabilistic"),
  chemicals = list(
    chemical("fixed_chemical", conc_fixed(0.01, unit = "mg/L")),
    chemical(
      "daily_lognormal_chemical",
      conc_lognormal(
        meanlog = log(0.003),
        sdlog = 0.25,
        unit = "mg/L",
        resample = "day"
      )
    )
  )
)

result <- run_exposure(
  model,
  mode = "probabilistic",
  n_trajectories = 20,
  n_uncertainty = 1,
  seed = 12345,
  output = "summary",
  summarize_hourly = FALSE
)

print(chemical_summary(result))
print(head(daily_summary(result)))
print(run_metadata(result)[c(
  "requested_seed",
  "effective_seed",
  "rng_name",
  "rng_version",
  "engine_version"
)])
print(result_warnings(result))

replay <- run_exposure(
  model,
  mode = "probabilistic",
  n_trajectories = 20,
  n_uncertainty = 1,
  seed = 12345,
  output = "summary",
  summarize_hourly = FALSE
)

stopifnot(identical(chemical_summary(result), chemical_summary(replay)))
stopifnot(identical(daily_summary(result), daily_summary(replay)))
