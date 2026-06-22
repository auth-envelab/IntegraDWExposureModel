# Validation Report

This report summarizes validation for `IntegraDWExposureModel` version 1.0.0 in the tested Windows x86-64 and R 4.3.0 environment. It is not independent third-party validation, a public release certificate, regulatory certification, or validation for untested operating systems or R versions.

## Validated Scope

The package calculates exposure to independently reported chemicals through direct drinking-water ingestion for one specified individual over a user-selected exposure period. Probabilistic runs produce alternative chronological trajectories for that same individual and may optionally include a separate outer concentration-scale uncertainty layer.

Excluded from this validation: synthetic cohorts, population distributions, between-person variability, toxicity values, risk calculations, mixture aggregation, and PBPK kinetic calculations.

## Equations

For chemical `j`, trajectory `r`, day `d`, and drinking event `k`:

```text
ingested_mass_mg = concentration_mg_L * water_volume_L
dose_mg_kg = ingested_mass_mg / body_weight_kg
daily_dose_mg_kg_day = sum(event dose_mg_kg within day)
exposure_period_average_daily_dose =
  sum(event dose_mg_kg over exposure period) / simulated_days
```

Hourly rows use half-open bins `[elapsed_hours, elapsed_hours + 1)`. For a one-hour bin, `dose_rate_mg_kg_h = dose_mg_kg`.

## Units

Canonical internal units are mg/L concentration, L water volume, kg body weight, mg ingested mass, mg/kg event dose amount, mg/kg-day daily dose, and hours/days elapsed time. Unit conversion tests cover mg/L, ug/L, g/L, L, and mL.

## Deterministic Fixture

The required one-day deterministic fixture passed through event output, hourly output, daily summary, exposure-period summary, reopened disk-backed result, PBPK event export, and PBPK hourly export.

```text
body weight = 50 kg
events = 0.25 L and 0.75 L
A concentration = 0.010 mg/L
B concentration = 2.000 mg/L
A masses = 0.0025 mg, 0.0075 mg
A doses = 0.00005 mg/kg, 0.00015 mg/kg
A daily and exposure-period average daily dose = 0.00020 mg/kg-day
B masses = 0.500 mg, 1.500 mg
B doses = 0.010 mg/kg, 0.030 mg/kg
B daily and exposure-period average daily dose = 0.040 mg/kg-day
```

## Seeded Stochastic Fixtures

Seed validation passed for explicit replay, different explicit seeds in a nondegenerate model, consecutive `seed = NULL` effective seed uniqueness, replay from recorded effective seed, output-selection invariance, chunk-size invariance, and unchanged global R RNG state. Deterministic mode remained seed-invariant.

Replay is scoped to the recorded package, engine, RNG, seed-derivation, distribution-transform, platform, and build information. Universal cross-platform bit-for-bit equality is not claimed.

## Reference Comparisons

Independent reference calculations matched native output for deterministic and RNG-degenerate stochastic fixtures. Exact nondegenerate stochastic native/reference equality is not claimed because the reference and production RNG versions differ. Native nondegenerate stochastic behavior is covered by seed replay, distribution support, output/chunk invariance, and mass-balance validation.

## Mass Balance And Aggregation

Validation passed event/hour/day/exposure-period identities. The maximum observed residual in the stochastic matrix fixture was `2.775558e-17`.

The 80-year full-hourly disk-backed validation passed with 3,506,400 hourly rows, 81 registered shards, successful reopening, checksum verification, first/middle/final hour filtering, PBPK hourly export, no raw table retained in the result object, and maximum summary/hourly residual `9.322321e-12`.

## Output Schemas

Raw event output contains the required identifiers, elapsed time, body weight, water volume, chemical identifier, concentration, ingested mass, and dose. Raw hourly output contains the required regular-grid identifiers, water, mass, dose, dose rate, and volume-weighted concentration. No-intake hours have zero volume/mass/dose/rate and `NA` concentration.

Run stores use the `rds_shards_v1` backend with relative manifest paths, schema versions, row counts, file sizes, MD5 checksums, and complete/failed status handling.

## Distribution Validation

Controlled validation covered support and rough moments for daily-water truncated lognormal sampling, concentration lognormal, concentration gamma, and concentration truncated normal. Fixed concentration exactness and degenerate lognormal behavior are covered by automated tests.

## Performance And Memory Observations

- Main validation matrix: passed.
- Baseline 1/5/10-year fixtures were retained before optimization checks. Post-optimization comparison returned maximum numerical difference 0 for daily summary, chemical summary, uncertainty summary, and uncertainty parameter tables; warnings and metadata version fields were identical.
- Optimized summary-only scaling with 20 trajectories, three uncertainty realizations, and five chemicals passed through 20 years: 1y 2.70s, 2y 6.66s, 5y 15.96s, 10y 32.20s, 20y 65.31s.
- Required 80-year summary-only validation with the same dimensions passed: first run 257.39 seconds, replay 259.92 seconds, result object 96,502,008 bytes, 964,260 daily-summary rows, 45 chemical-summary rows, 75 uncertainty-summary rows, 15 uncertainty-parameter rows, no output store, no raw event/hourly tables, and unchanged global R RNG state.
- Rerun 80-year full-hourly disk-backed validation passed in 22.35 seconds, with 3,506,400 hourly rows, store size 50,271,819 bytes before cleanup, and maximum summary/hourly residual `9.322321e-12`.

## Tested Matrix

```text
OS: Windows 11 x64
R: 4.3.0, x86_64-w64-mingw32
Compiler: GCC 12.2.0 as reported by R CMD check
Rcpp: 1.0.11
Package: IntegraDWExposureModel 1.0.0
Native engine: native-cpp-v1
RNG: integra-indexed-splitmix64 / native-rng-v1
Seed derivation: seed-derivation-v2
Distribution transform: inverse-cdf-rmath-v1
Quantile algorithm: R-type-7
```

No macOS, Linux, or other R 4.x binary is validated.

## Binary Archive Boundary

The Windows binary archive was audited as a compiled package deliverable. The archive contains the compiled DLL and installed package metadata and contains no `src/`, C/C++ source files, tests, source archives, private validation files, or reference calculation files. The DLL export table contains only `R_init_IntegraDWExposureModel`.

A source package or public source repository would expose readable implementation files. The Windows binary is the validated source-obscuring deliverable, but compiled binaries can still be reverse engineered and are not absolute secrecy.

## Release Gate

All listed local checks passed in the tested Windows x86-64 / R 4.3.0 environment, including the 80-year full-hourly disk-backed validation and the required 80-year summary-only validation.

This report does not represent independent third-party validation, independent regulatory certification, or validation for untested operating systems/R versions.
