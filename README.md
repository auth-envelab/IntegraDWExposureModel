# IntegraDWExposureModel

`IntegraDWExposureModel` is an R package for deterministic and probabilistic
assessment of chemical exposure from direct drinking-water ingestion for one
specified individual over a user-selected exposure period. It calculates water
intake, ingested chemical mass, and body-weight-normalized external oral dose.

## Validated Environment

- Package: `IntegraDWExposureModel` 1.0.0
- Distributed package file: `IntegraDWExposureModel_1.0.0.zip`
- Validated platform: Windows x86-64
- Validated R version: R 4.3.0
- Runtime dependency: `Rcpp`

## Installation

Use only the compiled Windows ZIP package for `IntegraDWExposureModel`.

In RStudio:

1. Download `IntegraDWExposureModel_1.0.0.zip` from the latest GitHub Release.
2. Select Tools -> Install Packages.
3. Select Package Archive File (.zip).
4. Select the downloaded ZIP file.
5. Restart R.
6. Load the package:

```r
library(IntegraDWExposureModel)
```

If `Rcpp` is not already installed in the target R library, install it first:

```r
if (!requireNamespace("Rcpp", quietly = TRUE)) {
  install.packages("Rcpp")
}
```

Install the downloaded package ZIP from R:

```r
install.packages(
  "path/to/IntegraDWExposureModel_1.0.0.zip",
  repos = NULL,
  type = "win.binary"
)
```

## Deterministic Example

This three-day screening example uses one adult, a constant body weight in kg,
the built-in deterministic adult sparse drinking-water schedule, and one fixed
chemical concentration in mg/L.

```r
library(IntegraDWExposureModel)

det_model <- dw_model(
  start_age_years = 30,
  duration_years = 3 / 365.25,
  body_weight = body_weight_constant(70),
  water = water_eu_adult_sparse(mode = "deterministic"),
  chemicals = chemical("chemical_A", conc_fixed(0.010, unit = "mg/L"))
)

det_result <- run_exposure(
  det_model,
  mode = "deterministic",
  output = "summary"
)

chemical_summary(det_result)
daily_summary(det_result)
```

A simple deterministic plot can be written to a temporary PDF:

```r
det_daily <- daily_summary(det_result)
det_dose <- det_daily[det_daily$metric == "daily_dose", ]

det_plot_file <- tempfile(fileext = ".pdf")
grDevices::pdf(det_plot_file, width = 7, height = 4)
plot(
  det_dose$day_index,
  det_dose$mean,
  type = "b",
  xlab = "Day",
  ylab = "Daily dose (mg/kg-day)"
)
grDevices::dev.off()

det_plot_file
```

## Probabilistic Example

Probabilistic trajectories are alternative possible chronological histories for
the same specified individual. They are not different people.

This seven-day example uses the built-in probabilistic synthetic adult sparse
water model, one fixed concentration, one stochastic lognormal concentration
resampled by day, five trajectories, one uncertainty realization, and an
explicit seed.

```r
prob_model <- dw_model(
  start_age_years = 30,
  duration_years = 7 / 365.25,
  body_weight = body_weight_constant(70),
  water = water_eu_adult_sparse(mode = "probabilistic"),
  chemicals = list(
    chemical("fixed_A", conc_fixed(0.010, unit = "mg/L")),
    chemical(
      "variable_B",
      conc_lognormal(
        meanlog = log(0.003),
        sdlog = 0.25,
        unit = "mg/L",
        resample = "day"
      )
    )
  )
)

prob_result <- run_exposure(
  prob_model,
  mode = "probabilistic",
  n_trajectories = 5,
  n_uncertainty = 1,
  seed = 202603,
  output = "summary"
)

chemical_summary(prob_result)
daily_summary(prob_result)
run_metadata(prob_result)[c(
  "requested_seed",
  "effective_seed",
  "rng_name",
  "rng_version",
  "engine_version"
)]
result_warnings(prob_result)
```

## Sparse Drinking Events

Event output is the sparse drinking chronology. Event rows repeat by chemical
because chemical-specific concentration, mass, and dose are calculated for the
same shared water event. When inspecting water intake, deduplicate shared event
rows before summing water volume.

```r
event_store <- tempfile("dw-events-")

event_result <- run_exposure(
  prob_model,
  mode = "probabilistic",
  n_trajectories = 3,
  seed = 202603,
  output = "summary_and_events",
  output_path = event_store,
  chunk_days = 1
)

events <- event_data(
  event_result,
  trajectory_id = 1,
  day_from = 1,
  day_to = 1
)

event_keys <- c("uncertainty_id", "trajectory_id", "day_index", "event_id")
water_events <- events[!duplicated(events[event_keys]), ]
water_events$event_time <- sprintf(
  "%02d:%02d",
  water_events$event_time_minute %/% 60,
  water_events$event_time_minute %% 60
)

water_events[, c("day_index", "event_id", "event_time", "water_volume_L")]
sum(water_events$water_volume_L)
sum(events$water_volume_L)

unlink(event_store, recursive = TRUE, force = TRUE)
```

The first sum counts each shared drinking event once. The second sum is larger
when multiple chemicals are present because it counts the same water event once
per chemical row.

## Hourly Output And Plots

Hourly output is a regular one-hour grid. Most hours should have zero intake.
Full hourly output can be large, so request it only when needed and provide a
temporary or user-selected output store.

```r
hourly_store <- tempfile("dw-hourly-")

hourly_result <- run_exposure(
  prob_model,
  mode = "probabilistic",
  n_trajectories = 5,
  seed = 202604,
  output = "summary_and_hourly",
  output_path = hourly_store,
  chunk_days = 1,
  summarize_hourly = TRUE
)

hourly_one <- hourly_data(
  hourly_result,
  chemical_id = "fixed_A",
  trajectory_id = 1
)

intake_hours <- hourly_one[hourly_one$water_volume_L > 0, ]
intake_hours[, c(
  "hour_index",
  "water_volume_L",
  "ingested_mass_mg",
  "dose_rate_mg_kg_h"
)]
```

Write hourly water, mass, dose-rate, and intake-probability plots to a
temporary PDF:

```r
hourly_all <- hourly_data(hourly_result, chemical_id = "fixed_A")
intake_probability <- aggregate(
  list(probability = hourly_all$water_volume_L > 0),
  by = list(hour_index = hourly_all$hour_index),
  FUN = mean
)

hourly_plot_file <- tempfile(fileext = ".pdf")
grDevices::pdf(hourly_plot_file, width = 8, height = 7)
old_par <- par(mfrow = c(2, 2), mar = c(4, 4, 2, 1))

plot(
  hourly_one$hour_index,
  hourly_one$water_volume_L,
  type = "h",
  xlab = "Hour",
  ylab = "Water (L)",
  main = "Water intake"
)
plot(
  hourly_one$hour_index,
  hourly_one$ingested_mass_mg,
  type = "h",
  xlab = "Hour",
  ylab = "Mass (mg)",
  main = "Chemical mass"
)
plot(
  hourly_one$hour_index,
  hourly_one$dose_rate_mg_kg_h,
  type = "h",
  xlab = "Hour",
  ylab = "Dose rate (mg/kg-h)",
  main = "Dose rate"
)
plot(
  intake_probability$hour_index,
  intake_probability$probability,
  type = "h",
  xlab = "Hour",
  ylab = "Probability",
  main = "Probability of intake"
)

par(old_par)
grDevices::dev.off()

hourly_dose_summary <- hourly_summary(
  hourly_result,
  chemical_id = "fixed_A",
  metric = "hourly_dose"
)
hourly_dose_summary
hourly_plot_file

unlink(hourly_store, recursive = TRUE, force = TRUE)
```

## Seed Behavior

Use an explicit seed to reproduce the same result for the same validated
package, calculation engine, model configuration, and platform. `seed = NULL`
creates a newly randomized run and records the generated effective seed in run
metadata. The recorded effective seed can be supplied to reproduce that run.
Universal cross-platform bit-for-bit equality is not claimed.

```r
replay_result <- run_exposure(
  prob_model,
  mode = "probabilistic",
  n_trajectories = 5,
  n_uncertainty = 1,
  seed = run_metadata(prob_result)$effective_seed,
  output = "summary"
)

identical(chemical_summary(prob_result), chemical_summary(replay_result))

new_result <- run_exposure(
  prob_model,
  mode = "probabilistic",
  n_trajectories = 5,
  n_uncertainty = 1,
  seed = NULL,
  output = "summary"
)

run_metadata(new_result)$effective_seed

new_replay <- run_exposure(
  prob_model,
  mode = "probabilistic",
  n_trajectories = 5,
  n_uncertainty = 1,
  seed = run_metadata(new_result)$effective_seed,
  output = "summary"
)

identical(chemical_summary(new_result), chemical_summary(new_replay))
```

## Outputs

- `summary`: exposure-period chemical summaries and daily summaries.
- `events`: sparse event-level records only.
- `hourly`: regular hourly trajectory records only.
- `summary_and_events`: summaries plus sparse event records.
- `summary_and_hourly`: summaries plus regular hourly trajectory records.
- `all`: summaries, event records, and hourly records.

Raw event and hourly outputs are disk-backed and require `output_path`. Full
hourly output can be large. Hourly statistical summaries are written when
`summarize_hourly = TRUE` and are read with `hourly_summary()`.

## Scientific Scope

- The model simulates one specified individual only.
- Probabilistic trajectories are alternative possible histories for that
  individual, not population percentiles or different people.
- The exposure route is direct oral ingestion of drinking water only.
- Multiple chemicals are evaluated independently while sharing the same water
  events in each trajectory.
- The package calculates external exposure, ingested chemical mass, and
  body-weight-normalized dose.
- It does not calculate toxicity, hazard quotients, cancer risk, mixture risk,
  health outcomes, or PBPK kinetics.
- PBPK exports are external oral-exposure histories, not PBPK calculations.

## Important Limitations

- `eu_adult_sparse_synthetic_v1` is a synthetic and provisional adult sparse
  consumption model.
- The 2 L/day value is an adult screening assumption.
- The hourly drinking pattern is not an empirically established EU-wide
  consumption distribution.
- The adult profile is rejected below age 18 unless the caller explicitly sets
  `explicit_minor_override = TRUE`.
- Body weight is supplied by the user and is constant in the current model.
- Temporal concentration draws are independent under the current stochastic
  concentration process.
- Concentration autocorrelation and seasonality are not implemented.
- Chemicals are evaluated independently; no mixture calculation is performed.
- Parameter uncertainty is currently limited to concentration-scale uncertainty.
- The currently validated binary environment is Windows x86-64 with R 4.3.0.

## Validation And Limitations Documents

- [Validation Report](docs/VALIDATION_REPORT.md)
- [Known Limitations](docs/KNOWN_LIMITATIONS.md)
