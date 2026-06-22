library(IntegraDWExposureModel)

cleanup_store <- function(path) {
  if (dir.exists(path)) {
    unlink(path, recursive = TRUE, force = TRUE)
  }
  stopifnot(!dir.exists(path))
}

hourly_statistics <- function(data, value_column) {
  by_hour <- split(data[[value_column]], data$hour_index)
  values <- do.call(rbind, lapply(by_hour, function(x) {
    c(
      mean = mean(x),
      median = median(x),
      p25 = as.numeric(quantile(x, 0.25, type = 7, names = FALSE)),
      p75 = as.numeric(quantile(x, 0.75, type = 7, names = FALSE)),
      p95 = as.numeric(quantile(x, 0.95, type = 7, names = FALSE))
    )
  }))
  data.frame(
    hour_index = as.integer(names(by_hour)),
    values,
    row.names = NULL
  )
}

plot_quantile_summary <- function(stats, ylab, main) {
  y_limit <- range(c(0, stats$p25, stats$p75, stats$p95), na.rm = TRUE)
  plot(
    stats$hour_index,
    stats$median,
    type = "n",
    xlab = "Hour",
    ylab = ylab,
    ylim = y_limit,
    main = main
  )
  polygon(
    c(stats$hour_index, rev(stats$hour_index)),
    c(stats$p25, rev(stats$p75)),
    col = "gray90",
    border = NA
  )
  lines(stats$hour_index, stats$p95, col = "gray50", lty = 2)
  lines(stats$hour_index, stats$median, lwd = 2)
}

plot_chemical_id <- "plot_chemical"
deterministic_store <- tempfile("IntegraDWExposureModel-hourly-det-")
probabilistic_store <- tempfile("IntegraDWExposureModel-hourly-prob-")
plot_file <- NULL
opened_pdf <- FALSE

on.exit({
  if (isTRUE(opened_pdf) && names(dev.cur()) != "null device") {
    dev.off()
  }
  if (!is.null(plot_file) && file.exists(plot_file)) {
    unlink(plot_file)
  }
  cleanup_store(deterministic_store)
  cleanup_store(probabilistic_store)
}, add = TRUE)

deterministic_model <- dw_model(
  start_age_years = 30,
  duration_years = 2 / 365.25,
  body_weight = body_weight_constant(70),
  water = water_eu_adult_sparse(mode = "deterministic"),
  chemicals = chemical(plot_chemical_id, conc_fixed(0.01, unit = "mg/L"))
)

deterministic_result <- run_exposure(
  deterministic_model,
  mode = "deterministic",
  output = "summary_and_hourly",
  output_path = deterministic_store,
  chunk_days = 1
)

deterministic_hourly <- hourly_data(
  deterministic_result,
  chemical_id = plot_chemical_id,
  trajectory_id = 1,
  uncertainty_id = 1
)

probabilistic_model <- dw_model(
  start_age_years = 30,
  duration_years = 3 / 365.25,
  body_weight = body_weight_constant(70),
  water = water_eu_adult_sparse(mode = "probabilistic"),
  chemicals = chemical(plot_chemical_id, conc_fixed(0.01, unit = "mg/L"))
)

probabilistic_result <- run_exposure(
  probabilistic_model,
  mode = "probabilistic",
  n_trajectories = 5,
  n_uncertainty = 1,
  seed = 12345,
  output = "summary_and_hourly",
  output_path = probabilistic_store,
  chunk_days = 1
)

probabilistic_hourly <- hourly_data(
  probabilistic_result,
  chemical_id = plot_chemical_id,
  uncertainty_id = 1
)
probabilistic_hourly$water_mL <- 1000 * probabilistic_hourly$water_volume_L

water_stats <- hourly_statistics(probabilistic_hourly, "water_mL")
mass_stats <- hourly_statistics(probabilistic_hourly, "ingested_mass_mg")
intake_probability <- aggregate(
  list(probability = probabilistic_hourly$water_volume_L > 0),
  by = list(hour_index = probabilistic_hourly$hour_index),
  FUN = mean
)

if (!interactive()) {
  plot_file <- tempfile(fileext = ".pdf")
  pdf(plot_file, width = 8, height = 9)
  opened_pdf <- TRUE
}

old_par <- par(no.readonly = TRUE)
on.exit({
  if (names(dev.cur()) != "null device") {
    par(old_par)
  }
}, add = TRUE)
par(mfrow = c(3, 2), mar = c(4, 4, 2, 1))

plot(
  deterministic_hourly$hour_index,
  1000 * deterministic_hourly$water_volume_L,
  type = "h",
  xlab = "Hour",
  ylab = "Water (mL/hour)",
  main = "Deterministic water"
)
plot(
  deterministic_hourly$hour_index,
  deterministic_hourly$ingested_mass_mg,
  type = "h",
  xlab = "Hour",
  ylab = "Mass (mg/hour)",
  main = "Deterministic mass"
)
plot(
  deterministic_hourly$hour_index,
  deterministic_hourly$dose_rate_mg_kg_h,
  type = "h",
  xlab = "Hour",
  ylab = "Dose rate (mg/kg/hour)",
  main = "Deterministic dose rate"
)
plot_quantile_summary(
  water_stats,
  ylab = "Water (mL/hour)",
  main = "Probabilistic water"
)
plot_quantile_summary(
  mass_stats,
  ylab = "Mass (mg/hour)",
  main = "Probabilistic mass"
)
plot(
  intake_probability$hour_index,
  intake_probability$probability,
  type = "h",
  xlab = "Hour",
  ylab = "Probability",
  ylim = c(0, 1),
  main = "Probability of intake"
)

par(old_par)

if (isTRUE(opened_pdf)) {
  dev.off()
  opened_pdf <- FALSE
  message("Temporary plot PDF created: ", plot_file)
  stopifnot(file.exists(plot_file))
  stopifnot(file.info(plot_file)$size > 0)
  unlink(plot_file)
  stopifnot(!file.exists(plot_file))
}

cleanup_store(deterministic_store)
cleanup_store(probabilistic_store)
