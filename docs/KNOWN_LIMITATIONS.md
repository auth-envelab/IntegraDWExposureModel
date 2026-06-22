# Known Limitations

This package has been validated locally for the stated Windows x86-64 and R 4.3.0 environment. It has not received independent scientific, regulatory, or cross-platform validation.

## Scientific Scope

- The model simulates one specified individual only.
- Probabilistic trajectories are alternative chronological histories for that individual, not population members.
- Exposure is limited to direct oral ingestion of drinking water.
- No dermal, inhalation, food, tea, coffee, formula, or household exposure is included.
- Outputs are exposure metrics only. No toxicity values, hazard quotients, cancer risk, mixture risk, PBPK kinetics, or internal dose are calculated.
- Body weight is currently a required positive scalar. Age-varying body weight is deferred.

## Scientific Defaults

- `eu_adult_sparse_synthetic_v1` is a synthetic adult screening assumption. It is not an empirically established EU-wide drinking-event distribution.
- The central 2 L/day adult volume and sparse within-day pattern require scientific review before broader use.
- The adult synthetic water profile is rejected for starting age below 18 unless the user explicitly overrides the guard.
- Concentration distributions are supplied directly by the user. The package does not fit hidden distributions from Mean, Median, P25, P75, or P95.
- Stochastic concentration draws are independent between selected resampling units. No autocorrelation, seasonality, spatial variation, measurement-error model, or cross-chemical correlation is implemented.
- Parameter uncertainty is limited to concentration-scale uncertainty.

## Validation Gaps

- The 80-year summary-only target with 20 trajectories, three uncertainty realizations, five chemicals, and active concentration-scale uncertainty passed locally after summary-only performance remediation.
- Expanded native/reference parity is version-limited. Deterministic and RNG-degenerate stochastic native/reference parity pass; nondegenerate native stochastic behavior is validated through seed replay, distribution, and mass-balance checks rather than exact reference equality.
- Validation has been performed locally on Windows x86-64 with R 4.3.0. macOS, Linux, and other R 4.x binaries are not yet validated.

## Source Boundary

- Source packages and public source repositories can expose readable implementation files.
- The source-obscuring deliverable is a platform-specific binary package.
- Compiled binaries can still be reverse engineered; this is not absolute secrecy.
