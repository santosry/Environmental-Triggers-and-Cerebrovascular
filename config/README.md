# config/README.md — Configuration Guide

This file documents the master configuration for the DLNM research compendium.

## Entry point

All tunable parameters, paths, feature flags, and constants are defined in
`config/config.R`. No hardcoded values exist in analysis code.

## Key parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `SEED` | `20260619` | Random seed for reproducibility |
| `DATE_START` | `2010-01-01` | Start of study period |
| `DATE_END` | `2025-12-31` | End of study period |
| `DLNM_LAG_GRID` | `c(7, 14, 21)` | Lag horizons tested |
| `DLNM_FALLBACK` | `df_exp=4, df_lag=3, lag_max=14` | Default DLNM specification |
| `DLNM_NW_HAC_ENABLE` | `TRUE` | Newey-West HAC standard errors |
| `DLNM_NW_LAGS` | `21` | HAC lag truncation parameter |
| `DLNM_MMT_ENABLE` | `TRUE` | Minimum Morbidity/Mortality Temperature centering |
| `MORAN_ENABLE` | `TRUE` | Moran's I spatial autocorrelation test |

## Feature flags (environment variables)

| Variable | Default | Effect |
|----------|---------|--------|
| `DLNM_ENABLE_AIR_QUALITY` | `"false"` | Include monthly PM2.5 as linear covariate (sensitivity only) |
| `DLNM_FORCE_RAW_DOWNLOAD` | `"false"` | Re-download all raw data (skip cache) |
| `DLNM_SIM_SIH_FALLBACK` | `"false"` | Fill missing SIM years with SIH hospital deaths (not recommended) |
| `DLNM_PROJECT_ROOT` | `getwd()` | Absolute path to project root |
| `RUN_PIPELINE_ON_SOURCE` | `"true"` | Auto-run `run_pipeline()` on `source()` |

## Directory structure

```
config/
  ├── config.R      # Master configuration (sourced by all modules)
  └── README.md     # This file
```

## How to modify configuration

1. Edit `config/config.R` to change parameters.
2. Set environment variables before running the pipeline to toggle feature flags.
3. All changes propagate automatically — no need to edit individual R modules.
