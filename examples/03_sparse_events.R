library(IntegraDWExposureModel)

cleanup_store <- function(path) {
  if (dir.exists(path)) {
    unlink(path, recursive = TRUE, force = TRUE)
  }
  stopifnot(!dir.exists(path))
}

event_store <- tempfile("IntegraDWExposureModel-events-")
on.exit(cleanup_store(event_store), add = TRUE)

model <- dw_model(
  start_age_years = 30,
  duration_years = 2 / 365.25,
  body_weight = body_weight_constant(70),
  water = water_eu_adult_sparse(mode = "probabilistic"),
  chemicals = list(
    chemical("chemical_A", conc_fixed(0.01, unit = "mg/L")),
    chemical("chemical_B", conc_fixed(0.02, unit = "mg/L"))
  )
)

result <- run_exposure(
  model,
  mode = "probabilistic",
  n_trajectories = 3,
  n_uncertainty = 1,
  seed = 12345,
  output = "summary_and_events",
  output_path = event_store,
  chunk_days = 1
)

events <- event_data(
  result,
  trajectory_id = 1,
  uncertainty_id = 1
)

# Drinking events are sparse. The same water event appears once for each
# chemical because concentration, mass, and dose are chemical-specific.
# Deduplicate water events before summing water volume across chemicals.
water_event_key <- c(
  "uncertainty_id",
  "trajectory_id",
  "day_index",
  "event_id",
  "event_time_minute",
  "elapsed_hours",
  "water_volume_L"
)
water_events <- events[!duplicated(events[water_event_key]), ]
water_events$time_of_day <- sprintf(
  "%02d:%02d",
  water_events$event_time_minute %/% 60,
  water_events$event_time_minute %% 60
)

print(water_events[, c(
  "day_index",
  "event_id",
  "time_of_day",
  "water_volume_L"
)])

deduplicated_daily_volume <- aggregate(
  water_volume_L ~ day_index,
  data = water_events,
  FUN = sum
)
reported_daily_volume <- aggregate(
  realized_daily_total_L ~ day_index,
  data = events,
  FUN = function(x) x[1]
)
volume_check <- merge(
  deduplicated_daily_volume,
  reported_daily_volume,
  by = "day_index",
  all = TRUE
)

tolerance <- run_metadata(result)$water_model_parameters$probabilistic$numerical_tolerance
stopifnot(all(abs(
  volume_check$water_volume_L - volume_check$realized_daily_total_L
) <= tolerance))

cleanup_store(event_store)
