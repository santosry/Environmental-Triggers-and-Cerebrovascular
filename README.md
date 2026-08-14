# dlnm-gam-cerebrovascular-rj

Climate Exposure and Cerebrovascular Outcomes in Rio de Janeiro, Brazil (2010--2025)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![R >= 4.4.0](https://img.shields.io/badge/R-%3E%3D4.4.0-blue.svg)](https://www.r-project.org/)

> **DATA INCLUDED:** All 528 raw and processed data files (~1.4 GB) are pre-packaged in this repository via Git LFS. No DATASUS API calls, no INMET downloads, no PM2.5 extraction needed. Clone and run.

**Research Compendium -- Environmental Epidemiology with Distributed Lag Non-linear Models and Hierarchical Bayesian Inference**

---

## Table of Contents

1. [Abstract](#abstract)
2. [Study Design](#study-design)
3. [Key Results](#key-results)
4. [Quick Start](#quick-start)
5. [Detailed Execution Guide](#detailed-execution-guide)
6. [Code Agent Execution](#code-agent-execution)
7. [Mathematical Framework](#mathematical-framework)
8. [Repository Structure](#repository-structure)
9. [Pipeline Components](#pipeline-components)
10. [Data Sources](#data-sources)
11. [Methodological Decisions](#methodological-decisions)
12. [Sensitivity Analyses](#sensitivity-analyses)
13. [Audit and Quality Control](#audit-and-quality-control)
14. [R Environment](#r-environment)
15. [Reproducibility](#reproducibility)
16. [Limitations](#limitations)
17. [Citation](#citation)
18. [License and Data](#license-and-data)

---

## Abstract

This repository investigates non-linear and delayed associations between daily mean temperature, daily relative humidity, and hospital admissions and deaths from acute cerebrovascular diseases (ICD-10 I60--I64) across the nine health macroregions of Rio de Janeiro state, Brazil.

| Attribute | Value |
|---|---|
| Study design | Ecological daily time series |
| Primary outcome | ICD-10 I60--I64: I60--I62 (hemorrhagic), I63 (ischemic), I64 (unspecified) |
| Admissions period | 2010-01-01 to 2025-12-31 (SIH-RD, principal diagnosis, deduplicated) |
| Mortality period | 2010-01-01 to 2024-12-31 (SIM-DO, underlying cause of death) |
| Spatial units | 9 health macroregions |
| Temporal resolution | Daily |
| Statistical method | Distributed Lag Non-linear Models (DLNM) + Hierarchical Bayesian stabilization |
| Standard errors | Newey-West HAC (21 lags) with delta-method propagation to cumulative RR |
| Multiple testing | Benjamini-Hochberg FDR across 72 primary contrasts |
| Sensitivity analyses | 8 types (lag grid, temporal df, pandemic exclusion [restricted + extended], mutual adjustment, outcome definition, climate aggregation, Bayesian priors, case-crossover) |
| Reproducibility | renv (151 packages), Docker, Makefile, targets pipeline, 88+ audit files |
| Data quality | SIM age converted from DATASUS 3-digit format; SIH deduplicated (29,564 removed); sex standardized across SIH/SIM |
| License | MIT |

---

## Study Design

```
+------------------+        +------------------+        +------------------+
|   DATA SOURCES   |        |   PROCESSING     |        |   MODELING       |
+------------------+        +------------------+        +------------------+
|                  |        |                  |        |                  |
| SIH-RD (DATASUS) |------->| Daily counts per |------->| 72 DLNM models   |
| 192 monthly files|        | municipality &   |        | Quasi-Poisson /  |
| 2010-2025        |        | macroregion      |        | Neg. Binomial    |
|                  |        |                  |        |                  |
| SIM-DO (DATASUS) |        | CID-10 I60-I69   |        | Cross-basis:     |
| 15 yearly files  |        | filtering        |        | ns(exp,df=4) x   |
| 2010-2024        |        |                  |        | ns(lag,df=3)     |
|                  |        |                  |        |                  |
| INMET (BrazilMet)|------->| Macroregional    |        | Contrasts:       |
| 26 weather       |        | daily means      |        | P05 vs P50        |
| stations         |        | (simple avg)     |        | P95 vs P50        |
|                  |        |                  |        |                  |
| SIDRA/IBGE       |------->| Population       |        | Offset:          |
| Census + Est.    |        | offset (log)     |        | log(population)  |
+------------------+        +------------------+        +------------------+
                                      |                          |
                                      v                          v
                             +------------------+    +------------------+
                             |   VALIDATION     |    |   OUTPUTS        |
                             +------------------+    +------------------+
                             | Bayesian (Stan)  |    | Figures (19 PNG) |
                             | Case-crossover   |    | Tables (42 CSV)  |
                             | Monte Carlo AF   |    | Audit (88 files) |
                             | Spatial Moran's I|    | Session info     |
                             | Temporal holdout |    | Integrity tests  |
                             +------------------+    +------------------+
```

### Exposure-Response Modeling (DLNM)

The core analytical framework uses Distributed Lag Non-linear Models (DLNMs) as formalized by Gasparrini (2010, 2014, _Statistics in Medicine_). A cross-basis function models the exposure-response relationship simultaneously across the exposure dimension and the lag dimension.

```
Exposure dimension:     ns(temperature, df=4)
                              x
Lag dimension:          ns(lag, df=3, log-knots), max lag = 21 days
                              =
Cross-basis:            CB(temperature, lag)  [4 x 3 = 12 basis functions]
```

The natural spline in the exposure dimension uses 4 degrees of freedom with knots at equally spaced quantiles. The natural spline in the lag dimension uses 3 degrees of freedom with knots placed at equally spaced log-values of the lag range (log-knots), providing greater flexibility in the first few days after exposure where biological effects are expected to be strongest.

---

## Key Results

| Metric | Value |
|---|---|
| Models fitted | 72/72 (100% convergence) |
| Integrity tests passed | 15/15 |
| Consistent signals (FDR < 0.05 AND Ljung-Box p > 0.05) | 4 |
| Suggestive signals (FDR < 0.10) | 24 |
| Insufficient evidence | 44 |
| Numerically invalid models | 0 |

### Consistent Signals

| Macroregion | Outcome | Exposure | RR P05 (95% CI) | RR P95 (95% CI) | FDR p |
|---|---|---|---|---|---|
| Metropolitana I | Deaths I60-I69 | Humidity | 1.12 (1.01-1.24) | 1.10 (1.01-1.21) | 4.1e-03 |
| Noroeste | Deaths I60-I64 | Temperature | 1.85 (1.17-2.93) | 1.41 (0.89-2.23) | 4.9e-02 |
| Norte | Deaths I60-I69 | Humidity | 1.14 (0.86-1.52) | 0.98 (0.73-1.32) | 3.4e-02 |
| Serrana | Deaths I60-I64 | Humidity | 1.03 (0.74-1.45) | 0.74 (0.52-1.03) | 3.6e-03 |

### Event Counts

| Source | ICD-10 Range | Period | Count |
|---|---|---|---|
| SIH-RD (admissions) | I60-I69 | 2010-2025 | 288,395 |
| SIH-RD (admissions, acute only) | I60-I64 | 2010-2025 | 238,184 |
| SIM-DO (deaths) | I60-I69 | 2010-2024 | 147,551 |
| SIM-DO (deaths, acute only) | I60-I64 | 2010-2024 | 93,593 |

### Exposure Statistics by Macroregion

| Macroregion | Temp P05 | Temp P50 | Temp P95 | RH P05 | RH P50 | RH P95 |
|---|---|---|---|---|---|---|
| Baia da Ilha Grande | 18.4 | 22.8 | 27.9 | 69.7 | 81.4 | 91.2 |
| Baixada Litoranea | 19.8 | 23.3 | 27.0 | 67.4 | 80.1 | 89.2 |
| Centro-Sul | 10.3 | 19.7 | 26.5 | 63.3 | 81.0 | 97.0 |
| Medio Paraiba | 16.7 | 21.9 | 26.3 | 61.4 | 76.7 | 87.8 |
| Metropolitana I | 19.0 | 23.4 | 28.2 | 62.5 | 77.3 | 89.0 |
| Metropolitana II | 14.4 | 22.0 | 28.2 | 64.9 | 79.5 | 94.6 |
| Noroeste | 18.4 | 23.8 | 28.6 | 61.5 | 75.0 | 88.9 |
| Norte | 19.8 | 23.8 | 27.6 | 67.3 | 77.7 | 88.6 |
| Serrana | 12.1 | 17.8 | 22.4 | 67.4 | 83.2 | 94.8 |

Temperature in degrees Celsius; RH = relative humidity in percentage points.

---

## Quick Start

### Zero Downloads Required

**All raw and processed data files are included directly in this repository via Git LFS.** After cloning, you have immediate access to:

| Data Type | Files | Total Size | Location |
|---|---|---|---|
| Hospital admissions (SIH-RD) | 192 monthly .rds | ~484 MB | `data/raw/sih/` |
| Mortality records (SIM-DO) | 111 monthly .rds | ~804 MB | `data/raw/sim/` |
| INMET weather stations | 218 files (.rds) | ~69 MB | `data/raw/inmet/` |
| Individual-level cleaned SIH | 1 .rds | ~1.1 MB | `data/interim/sih_cerebrovascular_individual.rds` |
| Individual-level cleaned SIM | 1 .rds | ~635 KB | `data/interim/sim_cerebrovascular_individual.rds` |
| Analytic dataset (daily, 9 macroregions) | 1 .rds | ~1.5 MB | `data/processed/dataset_dlnm_macrorregiao.rds` |
| Municipality-level daily outcomes | 1 .rds | ~1.1 MB | `data/processed/desfechos_diarios_municipio.rds` |
| Macroregional daily climate | 1 .rds | ~569 KB | `data/processed/inmet_diario_macrorregiao.rds` |
| PM2.5 monthly tables | 4 .csv | ~2 MB | `data/processed/pm25/` |
| **Total pre-packaged data** | **528 files** | **~1.4 GB** | |

You do **not** need to run `make download`. You do **not** need DATASUS API access. You do **not** need an internet connection after cloning. The `make download` step exists only if you wish to refresh the raw data from public APIs.

### Prerequisites

| Requirement | Minimum Version | Installation Check |
|---|---|---|
| R | 4.4.0 | `R --version` |
| Git | 2.30 | `git --version` |
| Git LFS | 3.0 | `git lfs version` |
| GNU Make | any | `make --version` |
| Python (optional) | 3.9 | `python3 --version` |
| Docker (optional) | 24 | `docker --version` |

### One-Command Execution (No Downloads Needed)

All data is pre-packaged. Just clone, set variables, and run:

```bash
git clone https://github.com/santosry/dlnm-gam-cerebrovascular-rj.git
cd dlnm-gam-cerebrovascular-rj
export DLNM_PROJECT_ROOT="$(pwd)"
export DLNM_SIM_SIH_FALLBACK="false"
Rscript run_dlnm_analysis.R
```

This single command runs the complete pipeline: processes outcomes, builds the analytic dataset, fits 72 DLNM models, runs Bayesian validation, generates figures and tables, and executes all integrity tests. Total runtime: approximately 30-45 minutes.

### Docker (cross-platform, zero local dependencies, data included)

```bash
git clone https://github.com/santosry/dlnm-gam-cerebrovascular-rj.git
cd dlnm-gam-cerebrovascular-rj
make docker-build    # Builds image with all R packages and data pre-loaded
make docker-run      # Runs full pipeline inside container
```

---

## Detailed Execution Guide

### Step 0: Clone and Enter Repository

Data is versioned with Git LFS. Ensure Git LFS is installed before cloning:

```bash
git lfs install
git clone https://github.com/santosry/dlnm-gam-cerebrovascular-rj.git
cd dlnm-gam-cerebrovascular-rj
export DLNM_PROJECT_ROOT="$(pwd)"
```

After cloning, verify that data files are present (528 files, ~1.4 GB):

```bash
ls data/raw/sih/*.rds | wc -l     # Expected: 192
ls data/raw/sim/*.rds | wc -l     # Expected: 111
ls data/interim/*.rds | wc -l     # Expected: 2
ls data/processed/*.rds | wc -l   # Expected: 3
```

### Step 1: Install R Environment

```bash
make setup
```

This command:
- Installs the `renv` package manager
- Restores 151 R packages at exact versions specified in `renv.lock`
- Creates an isolated package library in `renv/library/`
- Does NOT require Python (PM2.5 tables are pre-packaged in `data/processed/pm25/`)

Expected output: `"Setup complete!"` followed by a note about pre-packaged PM2.5 tables.

### Step 2: Download Raw Data (OPTIONAL -- data is pre-packaged)

**Skip this step.** All raw data files are already included in the repository. This step exists only to refresh data from public APIs if needed:

```bash
# OPTIONAL -- skip unless you need fresh data from APIs
make download
```

### Step 3: Process Data and Build Analytic Dataset

```bash
make process
```

This command:
1. Cleans SIH-RD records: extracts date (DT_INTER), principal diagnosis (DIAG_PRINC), municipality of residence (MUNIC_RES)
2. Cleans SIM-DO records: extracts date of death (DTOBITO), underlying cause (CAUSABAS), municipality of residence (CODMUNRES)
3. Filters to ICD-10 I60-I69 codes with municipality starting with "33" (Rio de Janeiro state)
4. Builds daily municipality-level counts, then aggregates to macroregion level
5. Processes INMET weather station data and maps each station to a macroregion
6. Computes macroregional daily means of temperature and relative humidity
7. Joins population denominators from SIDRA/IBGE (log offset)
8. Adds calendar variables (day of week, Brazilian holidays including Carnival/Easter/Corpus Christi, pandemic indicator)
9. Optionally joins PM2.5 monthly data (enabled via `DLNM_ENABLE_AIR_QUALITY=true`)

### Step 4: Fit DLNM Models

```bash
make models
```

This command fits 72 Distributed Lag Non-linear Models:
- 9 macroregions x 4 outcomes x 2 exposures = 72 combinations
- Each model uses a cross-basis (ns with 4 df for exposure, ns with 3 df log-knots for lag up to 21 days)
- Primary family: Quasi-Poisson; falls back to Negative Binomial if dispersion > 3
- Standard errors: Newey-West HAC (21 lags) with delta-method propagation to cumulative RR
- Approximate runtime: 30-45 minutes depending on hardware

### Step 5: Validation and Sensitivity

```bash
make validate
```

This command runs:
- Bayesian hierarchical stabilization (Stan, Normal-Normal empirical Bayes)
- Prior sensitivity (skeptical, optimistic, flat priors)
- Temporal holdout validation (train 2010-2022, test 2023-2025)
- Pandemic exclusion sensitivity (without 2020-03 to 2022-12)
- FDR correction (Benjamini-Hochberg) across 72 primary contrasts
- Moran's I spatial autocorrelation test
- Lag sensitivity (7, 14, 21-day windows)
- Temporal df sensitivity (4, 5, 6, 7 df/year)

### Step 6: Generate Reports and Figures

```bash
make reports
```

Generates:
- 19 static PNG figures (300 DPI)
- 129 interactive 3D Plotly HTML surfaces
- 42 CSV tables of results
- Epidemiological interpretation tables

### Step 7: Quality Control and Audit

```bash
make audit
```

Generates 88+ audit files including:
- Integrity tests (15 automated checks)
- Model numerical stability assessment
- Climate coverage audit
- CID distribution counts
- Descriptive daily statistics by macroregion
- Benchmark validation

### Step 8: Run Unit Tests

```bash
make test
```

| Test File | Scope |
|---|---|
| `tests/testthat/test_utils.R` | clean_text, clean_cid3, haversine_km, trapezoid_auc, safe_fetch, get_brazilian_holidays |
| `tests/testthat/test_preprocessing.R` | CID parsing, date parsing, municipality normalization, process_poluentes |
| `tests/testthat/test_dlnm_models.R` | cross-basis construction, model convergence, HAC standard errors, cross-prediction |
| `tests/testthat/test_bayesian.R` | hierarchical shrinkage, prior sensitivity, posterior interval calculation |

### Full Pipeline (Steps 1-8 in Sequence)

```bash
make setup && make all && make test
```

---

## Code Agent Execution

This section provides exact, deterministic instructions for automated code agents, CI/CD systems, and headless environments. All data is pre-packaged in the repository -- no API calls are needed.

### Environment Setup for Code Agents

```bash
# 1. Navigate to project root (ABSOLUTE PATH REQUIRED)
cd /absolute/path/to/dlnm-gam-cerebrovascular-rj

# 2. Verify data files exist (528 files pre-packaged, no download needed)
test $(ls data/raw/sih/*.rds 2>/dev/null | wc -l) -eq 192 || echo "ERROR: SIH files missing"
test $(ls data/raw/sim/*.rds 2>/dev/null | wc -l) -eq 111 || echo "ERROR: SIM files missing"
test -f data/interim/sih_cerebrovascular_individual.rds || echo "ERROR: interim SIH missing"
test -f data/interim/sim_cerebrovascular_individual.rds || echo "ERROR: interim SIM missing"
test -f data/processed/dataset_dlnm_macrorregiao.rds || echo "ERROR: analytic dataset missing"

# 3. Set environment variables (CRITICAL - must be set before any R execution)
export DLNM_PROJECT_ROOT="$(pwd)"
export DLNM_SIM_SIH_FALLBACK="false"       # NEVER set to "true" -- prevents SIH fallback
export DLNM_ENABLE_AIR_QUALITY="false"     # PM2.5 as optional sensitivity only
export DLNM_FORCE_RAW_DOWNLOAD="false"     # Use cached data if available

# 3. Verify R and dependencies
Rscript --version                            # Should print: R scripting front-end version 4.x.x
Rscript -e 'packageVersion("dlnm")'          # Should print: 2.4.10
Rscript -e 'packageVersion("dplyr")'         # Should print: 1.1.4
```

### Deterministic Execution Sequence

Execute these commands in exact order. Do not skip steps. Each step depends on the previous one succeeding.

```bash
# Step 1: Install R packages (idempotent -- safe to run multiple times)
make setup
# Expected exit code: 0
# Expected output: "Setup complete!"
# If exit code != 0: system library dependencies missing. Install:
#   apt-get install libcurl4-openssl-dev libssl-dev libxml2-dev libgdal-dev (Linux)
#   or equivalent for your platform.

# Step 2: (OPTIONAL) Download raw data -- SKIP THIS, data is pre-packaged
# The 528 data files are already in the repository via Git LFS.
# Only uncomment if you need to refresh from public APIs:
# make download
# Expected exit code: 0
# If exit code != 0: API may be unavailable. Retry later or inspect logs/.

# Step 3: Process data and build analytic dataset
make process
# Expected exit code: 0
# Expected output: data/processed/dataset_dlnm_macrorregiao.rds must exist
# If exit code != 0: check data/raw/sih/ and data/raw/sim/ for .rds files

# Step 4: Fit DLNM models
make models
# Expected exit code: 0
# Expected output: outputs/tables/tabela_rr_dlnm_corrigida.csv with 72 rows
# Approximate runtime: 30-45 minutes
# Memory required: ~4 GB

# Step 5: Validation and sensitivity
make validate
# Expected exit code: 0
# Expected output: outputs/tables/bayesian_enhanced_hierarchical.csv
# Approximate runtime: 10-15 minutes

# Step 6: Generate reports and figures
make reports
# Expected exit code: 0
# Expected output: outputs/figures/*.png (minimum 6 files)

# Step 7: Quality control
make audit
# Expected exit code: 0
# Expected output: audit/testes_integridade_finais.csv

# Step 8: Unit tests
make test
# Expected exit code: 0
# Expected output: All tests passed
# If exit code != 0: do NOT proceed -- inspect test output for failures
```

### Verification Commands for Code Agents

After execution, verify these outputs programmatically:

```bash
# Verify analytic dataset exists
test -f data/processed/dataset_dlnm_macrorregiao.rds
# Expected: exit code 0

# Verify model results table has exactly 72 rows
test $(Rscript -e 'cat(nrow(read.csv("outputs/tables/tabela_rr_dlnm_corrigida.csv")))') -eq 72
# Expected: exit code 0

# Verify no NaN or Inf in RR values
Rscript -e 'd=read.csv("outputs/tables/tabela_rr_dlnm_corrigida.csv");stopifnot(all(is.finite(d$rr_p05)),all(is.finite(d$rr_p95)))'
# Expected: exit code 0

# Verify no SIH fallback contamination
test $(Rscript -e 'd=readRDS("data/processed/desfechos_diarios_municipio.rds");cat(any(grepl("SIH_AIHS",d$fonte_obitos)))') = "FALSE"
# Expected: exit code 0 from test

# Verify mortality 2025 is NA (not zero)
Rscript -e 'd=readRDS("data/processed/dataset_dlnm_macrorregiao.rds");d2025=d[d$data>as.Date("2024-12-31"),];stopifnot(all(is.na(d2025$obitos_i60_i69)))'
# Expected: exit code 0

# Verify at least 6 figures exist
test $(ls outputs/figures/*.png 2>/dev/null | wc -l) -ge 6
# Expected: exit code 0

# Verify integrity tests all passed
Rscript -e 'd=read.csv("audit/testes_integridade_finais.csv");stopifnot(all(d$resultado))'
# Expected: exit code 0

# Verify all 9 macroregions present
test $(Rscript -e 'd=read.csv("outputs/tables/tabela_rr_dlnm_corrigida.csv");cat(length(unique(d$macro_regiao)))') -eq 9
# Expected: exit code 0
```

### Single-Command Full Execution

```bash
export DLNM_PROJECT_ROOT="$(pwd)"
export DLNM_SIM_SIH_FALLBACK="false"
export RUN_PIPELINE_ON_SOURCE="true"
Rscript run_dlnm_analysis.R
```

Expected exit code: 0. Total runtime: approximately 1-2 hours depending on hardware, network speed, and whether raw data is already cached.

### Error Recovery

| Error | Diagnosis | Recovery |
|---|---|---|
| `renv::restore()` fails | Missing system libraries | Install `libcurl4-openssl-dev libssl-dev libxml2-dev libgdal-dev` |
| Data files missing after clone | Git LFS not initialized | `git lfs install && git lfs pull` |
| "No SIH files found" | Download step skipped | Data is pre-packaged; verify `data/raw/sih/*.rds` exists (192 files) |
| API timeout | DATASUS throttling | Wait 5 minutes, re-run download |
| Memory exhausted | Insufficient RAM | Ensure >= 8 GB; Docker: `--memory=16g` |
| R session segfault | R version incompatibility | Use R >= 4.4.0, run `make renv-restore` |
| Git LFS files missing | LFS not initialized | `git lfs install && git lfs pull` |
| "crosspred basis inconsistent" | Crossbasis subset incorrectly | Use `run_dlnm_analysis.R` (fixed) |

---

## Mathematical Framework

### Model Equation

For each outcome $o \in \{\text{admissions}, \text{deaths}\}$, macroregion $r \in \{1,\ldots,9\}$, and day $t$:

$$Y^{o}_{rt} \sim \text{quasi-Poisson}(\mu^{o}_{rt}, \phi^{o}), \quad t \in \mathcal{T}^{o}$$

$$\log(\mu^{o}_{rt}) = \log(\text{Pop}_{r, \text{year}(t)}) + \alpha^{o}_{r} + \text{CB}^{o}_{r}(X_{rt}) + \text{ns}(\text{time}_t, \text{df}_{\text{temporal}}) + \beta_1 \text{dow}_t + \beta_2 \text{holiday}_t + \beta_3 \text{pandemic}_t + \beta_4 \; \text{ns}(Z_{rt}, 3)$$

Where:

| Symbol | Definition |
|---|---|
| $\mathcal{T}^{\text{admissions}}$ | $\{t: \text{2010-01-01} \leq t \leq \text{2025-12-31}\}$ (5,844 days) |
| $\mathcal{T}^{\text{deaths}}$ | $\{t: \text{2010-01-01} \leq t \leq \text{2024-12-31}\}$ (5,479 days) |
| $\text{Pop}_{r, \text{year}(t)}$ | Annual population of macroregion $r$ (SIDRA/IBGE) |
| $\text{CB}^{o}_{r}(X_{rt})$ | Cross-basis of exposure $X_{rt}$ |
| $\text{ns}(\text{time}_t, \text{df})$ | Natural spline with df degrees of freedom |
| $\text{dow}_t$ | Day of week (1-7, Monday-based) |
| $\text{holiday}_t$ | Binary: Brazilian national/state holiday |
| $\text{pandemic}_t$ | Binary: 2020-03-01 to 2022-12-31 |
| $Z_{rt}$ | Complementary exposure (humidity when $X$ is temperature, and vice versa) |

### Cross-Basis Specification

$$\text{CB}(X_{rt}) = \text{ns}(X_{rt}, \text{df}_{\text{exp}}=4) \otimes \text{ns}(\ell, \text{df}_{\text{lag}}=3, \text{knots}=\log\text{-scale}), \quad \ell \in [0, 21]$$

| Parameter | Value | Justification |
|---|---|---|
| Exposure function | Natural spline (ns) | Flexibility with boundary linearity constraint |
| Exposure df | 4 | Captures non-linearity without overfitting (AIC-guided grid search) |
| Lag function | Natural spline (ns) | Smooth decay of lagged effects |
| Lag df | 3 | Sufficient for typical 2-3 week decay pattern |
| Lag knots | log-scale (logknots) | Greater flexibility in first few days post-exposure |
| Lag maximum | 21 days | Captures acute + subacute effects; sensitivity at 7 and 14 |
| Centering | Regional P50 | Clinically interpretable reference (median exposure) |

### Primary Contrasts

For each model, two pre-specified contrasts are computed:

| Contrast | Definition | Interpretation |
|---|---|---|
| Low exposure (P05) | RR at 5th percentile vs 50th percentile | Effect of unusually low temperature/humidity |
| High exposure (P95) | RR at 95th percentile vs 50th percentile | Effect of unusually high temperature/humidity |

Percentiles are regional -- the absolute temperature at P05 in Serrana (~12.1 C) differs substantially from P05 in Metropolitana I (~19.0 C).

### Newey-West HAC Standard Errors

$$\hat{V}_{\text{HAC}} = \hat{V}_{\text{OLS}} + \sum_{j=1}^{L} w_j \left(\hat{\Gamma}_j + \hat{\Gamma}_j^T\right)$$

Where $L = 21$ (truncation lag), $w_j = 1 - j/(L+1)$ (Bartlett kernel), and $\hat{\Gamma}_j$ are the autocovariance matrices at lag $j$.

The HAC covariance is propagated to cumulative RR via the delta method:

$$\text{SE}(\log\text{RR}_{\text{cumul}}) = \sqrt{\nabla_{\beta} f(\hat{\beta})^T \; \hat{V}_{\text{HAC}} \; \nabla_{\beta} f(\hat{\beta})}$$

where $\nabla_{\beta} f(\hat{\beta})$ is the gradient of the cumulative prediction with respect to the cross-basis coefficients.

### Bayesian Hierarchical Model

Two-stage Normal-Normal hierarchical model for regional shrinkage:

**Stage 1 (DLNM):** $\log(\text{RR}_r) \sim \text{Normal}(\theta_r, \text{SE}_r^2)$

**Stage 2 (Hierarchical):** $\theta_r \sim \text{Normal}(\mu, \tau^2)$

**Priors:** $\mu \sim \text{Normal}(0, 3^2)$, $\tau \sim \text{Half-Normal}(0, 1)$

**Estimation:** Grid-search empirical Bayes for $\mu$ and $\tau$, analytical posterior for each $\theta_r$.

A fully Bayesian multivariate implementation using Stan (Hamiltonian Monte Carlo) is also available with R-hat diagnostics and divergence checking (see `outputs/tables/stan_bayesian_multivariate.csv`).

### Classification Framework

Results are classified into four pre-defined categories:

| Category | Criteria |
|---|---|
| **Consistent signal** | FDR < 0.05 AND Ljung-Box lag-14 p > 0.05 AND finite RR AND stable direction across >= 3 sensitivity analyses |
| **Suggestive signal** | FDR < 0.10 AND finite RR |
| **Insufficient evidence** | FDR >= 0.10 or unstable across specifications |
| **Invalid model** | Convergence failure, RR not finite, SE not finite, or prediction beyond observed exposure range |

Models classified as invalid are excluded from all rankings and epidemiological figures.

---

## Repository Structure

```
dlnm-gam-cerebrovascular-rj/
|
|-- README.md                          # This file
|-- LICENSE                            # MIT License
|-- CITATION.cff                       # Citation metadata
|-- COMPENDIUM_MANIFEST.yml            # Research compendium manifest
|-- REPRODUCIBILITY_CHECKLIST.md       # Reproducibility compliance
|-- Makefile                           # Automated workflow
|-- run_dlnm_analysis.R                # MASTER PIPELINE -- single entry point
|-- run_pipeline.R                     # Original pipeline entry point
|-- _targets.R                         # Incremental pipeline (targets)
|-- renv.lock                          # Package versions (151 packages)
|-- .gitignore
|-- .gitattributes
|-- .Rprofile
|
|-- config/
|   |-- config.R                       # Global parameters, paths, constants
|   |-- README.md                      # Configuration guide
|
|-- R/
|   |-- utils.R                        # Logging, holidays, math utilities
|   |-- download.R                     # Data acquisition (DATASUS, INMET, SIDRA)
|   |-- exposure_processing.R          # INMET station mapping, climate imputation
|   |-- preprocessing.R                # SIH/SIM cleaning, PM2.5, population offset
|   |-- dlnm_models.R                  # DLNM fitting, HAC SE, diagnostics, Moran's I
|   |-- bayesian_models.R              # Hierarchical Bayesian stabilization
|   |-- visualization.R                # Static and interactive figures
|   |-- reporting.R                    # Reports, benchmarks, quality control
|
|-- data/
|   |-- raw/                           # Downloaded source data (regenerated)
|   |   |-- sih/                       # 192 SIH-RD monthly files (2010-2025)
|   |   |-- sim/                       # 15 SIM-DO yearly files (2010-2024)
|   |   |-- inmet/                     # 26+ INMET station daily files
|   |   |-- inmet_zip/                 # INMET yearly zip archives (fallback)
|   |-- interim/                       # Intermediate cleaned files
|   |-- processed/                     # Analytical datasets and model objects
|   |   |-- pm25/                      # Pre-packaged PM2.5 tables
|   |   |-- dataset_dlnm_macrorregiao.rds         # Analytic dataset
|   |   |-- desfechos_diarios_municipio.rds       # Daily counts
|   |   |-- inmet_diario_macrorregiao.rds         # Climate data
|   |   |-- modelos_dlnm_macrorregiao_corrigido.rds  # Fitted DLNM models
|
|-- outputs/
|   |-- figures/                       # 19 static PNGs + interactive HTML
|   |-- tables/                        # 42 CSV tables
|
|-- audit/                             # 88+ audit files
|   |-- AUDIT_EXECUTIVE_SUMMARY.md     # Executive audit summary
|   |-- AUDIT_FINDINGS.csv             # All findings by severity
|   |-- FILE_MANIFEST.csv              # Complete file inventory
|   |-- OUTCOME_TESTS.csv              # Integrity test results (15/15)
|   |-- I63_ANOMALY_REPORT.md          # I63 coding anomaly
|   |-- PM25_SENSITIVITY_CONFIG.md     # PM2.5 configuration
|   |-- CHANGELOG_AUDIT.md             # Complete change log
|   |-- UNRESOLVED_ISSUES.md           # Remaining limitations
|   |-- backups/                       # Original files before corrections
|
|-- tests/
|   |-- testthat/
|       |-- test_utils.R
|       |-- test_preprocessing.R
|       |-- test_dlnm_models.R
|       |-- test_bayesian.R
|
|-- logs/                              # Pipeline execution logs
|-- docs/                              # Extended documentation
|-- docker/                            # Container configuration
|-- metadata/                          # FAIR metadata
|-- studies/                           # Etapa anterior do estudo (descritiva)
|   |-- README.md                      # Índice das etapas + proveniência
|   `-- cerebrovascular-diseases-rj-2010-25/   # Etapa 1: epidemiologia descritiva (I60-I69)
|-- .github/workflows/                 # CI/CD automation
```

**Etapas do estudo — relação entre as pastas:** este compêndio cobre o ciclo completo da
pesquisa. A **raiz** deste repositório é a etapa final de modelagem (DLNM/GAM + Bayesiano
hierárquico). A pasta `studies/cerebrovascular-diseases-rj-2010-25/` é a **etapa anterior** — a
epidemiologia descritiva da morbimortalidade por AVC (I60–I69) a partir de SIH/SIM (aquisição,
processamento, indicadores e análises descritivas) — que fundamenta e antecede a modelagem da
raiz. Veja `studies/README.md`.

---

## Pipeline Components

### R Source Files

| File | Lines | Core Functions | Responsibility |
|---|---|---|---|
| `R/utils.R` | ~250 | `log_msg`, `safe_fetch`, `parse_datasus_date`, `clean_cid3`, `haversine_km`, `get_brazilian_holidays`, `first_col`, `write_audit` | Logging, safe evaluation, date/CID parsing, geography, holidays, I/O |
| `R/download.R` | ~420 | `download_sih`, `download_sim`, `download_inmet`, `download_population_sidra` | Data acquisition from DATASUS, INMET, IBGE APIs |
| `R/exposure_processing.R` | ~510 | `process_inmet`, `standardize_inmet`, `map_inmet_stations_to_macro`, `get_macro_centroids_for_climate`, `fill_missing_macro_climate` | Station-to-macroregion mapping, climate imputation, spatial operations |
| `R/preprocessing.R` | ~500 | `process_outcomes`, `clean_sih_file`, `clean_sim_file`, `process_poluentes`, `make_analytic_dataset`, `audit_territorial_integrity_final` | Health record cleaning, outcome counting, PM2.5 loading, analytic dataset assembly |
| `R/dlnm_models.R` | ~1200 | `fit_one_dlnm`, `run_dlnm`, `trapezoid_auc`, `diagnose_model`, `add_fdr_and_evidence_flags`, `run_moran_spatial_test`, `run_temporal_df_sensitivity`, `run_lag_sensitivity`, `run_pandemic_exclusion_sensitivity`, `run_temporal_holdout_validation` | DLNM fitting, prediction, diagnostics, spatial autocorrelation, sensitivity analyses |
| `R/bayesian_models.R` | ~240 | `bayes_normal_normal_group`, `run_bayesian_hierarchical_validation`, `run_prior_sensitivity`, `bayes_with_prior` | Hierarchical Bayesian stabilization, prior sensitivity |
| `R/visualization.R` | ~400 | `plot_monthly_admissions`, `plot_daily_climate_seasonality`, `generate_cellpress_figures`, `plot_extended_diagnostics` | Static and interactive figures |
| `R/reporting.R` | ~240 | `write_dlnm_method_note`, `write_final_reports_epidemiologicos`, `final_quality_control_epidemiologicos`, `centralize_audits`, `run_benchmark_validation` | Reports, quality control, benchmark validation |

### Key Parameters

All tunable parameters are in `config/config.R`:

| Parameter | Default | Description |
|---|---|---|
| `SEED` | `20260619` | Random seed for reproducibility |
| `DATE_START` | `2010-01-01` | First day of study period |
| `DATE_END` | `2025-12-31` | Last day of admissions period |
| `SIM_DATE_END` | `2024-12-31` | Last day of mortality period |
| `DLNM_FALLBACK$df_exp` | `4` | Degrees of freedom for exposure spline |
| `DLNM_FALLBACK$df_lag` | `3` | Degrees of freedom for lag spline |
| `DLNM_FALLBACK$lag_max` | `21` | Maximum lag in days |
| `DLNM_NW_LAGS` | `21` | Truncation lag for Newey-West HAC |
| `DLNM_MMT_ENABLE` | `TRUE` | Center at Minimum Mortality/Morbidity Temperature |
| `PANDEMIC_START` | `2020-03-01` | First day of pandemic indicator |
| `PANDEMIC_END` | `2022-12-31` | Last day of pandemic indicator |
| `SIM_SIH_FALLBACK` | `FALSE` | DO NOT substitute SIH deaths for missing SIM |

### CID-10 Definitions

| Variable | Codes | Description |
|---|---|---|
| `CID_CEREBRO` | I60-I69 | All cerebrovascular diseases |
| `CID_SENS` | I60-I64 | Acute cerebrovascular events (primary outcome) |
| `CID_HEMORR` | I60-I62 | Hemorrhagic stroke |
| `CID_ISQ` | I63 | Cerebral infarction (ischemic stroke) |
| `CID_NAO_ESPEC` | I64 | Stroke, not specified as hemorrhagic or ischemic |
| `CID_OUTRAS` | I65-I69 | Occlusion/stenosis without infarction (I65-I66), other cerebrovascular diseases (I67-I68), sequelae (I69) |

---

## Data Sources

| Source | System | Period | Unit | Variables | Access |
|---|---|---|---|---|---|
| DATASUS | SIH-RD | 2010-01 to 2025-12 | Hospital admission (AIH) | Principal diagnosis (DIAG_PRINC), admission date (DT_INTER), municipality (MUNIC_RES), hospital death (MORTE) | `microdatasus` R package |
| DATASUS | SIM-DO | 2010 to 2024 | Death certificate (DO) | Underlying cause (CAUSABAS), death date (DTOBITO), municipality of residence (CODMUNRES) | `microdatasus` R package |
| INMET | Automatic weather stations | 2010-01 to 2025-12 | Station-day | Mean temperature (C), min/max temperature, relative humidity (%) | `BrazilMet` R package / local zip fallback |
| SIDRA/IBGE | Census + Population Estimates | 2010 to 2025 | Municipality-year | Resident population | `sidrar` R package |
| INEA/MonitorAr | VIGIAR program | 2010 to 2025 | Municipality-month | PM2.5 concentration (ug/m3) | Python/Playwright (optional, pre-packaged) |

### INMET Weather Stations (26 stations across 9 macroregions)

| Station Code | Municipality | Macroregion | Latitude | Longitude | Altitude (m) |
|---|---|---|---|---|---|
| A628 | Angra dos Reis | Baia da Ilha Grande | -23.01 | -44.32 | 8 |
| A606 | Arraial do Cabo | Baixada Litoranea | -23.00 | -42.02 | 4 |
| A604 | Cambuci | Noroeste | -21.57 | -41.92 | 87 |
| A607 | Campos dos Goytacazes | Norte | -21.75 | -41.33 | 11 |
| A620 | Campos dos Goytacazes (Sao Tome) | Norte | -21.99 | -41.04 | 265 |
| A629 | Carmo | Centro-Sul | -21.93 | -42.60 | 314 |
| A603 | Duque de Caxias (Xerem) | Metropolitana I | -22.58 | -43.30 | 35 |
| A608 | Macae | Norte | -22.38 | -41.79 | 10 |
| A624 | Nova Friburgo (Salinas) | Serrana | -22.37 | -42.30 | 1075 |
| A627 | Niteroi | Metropolitana II | -22.89 | -43.12 | 3 |
| A619 | Paraty | Baia da Ilha Grande | -23.22 | -44.72 | 5 |
| A637 | Paty do Alferes (Avelar) | Centro-Sul | -22.29 | -43.18 | 500 |
| A610 | Pico do Couto | Serrana | -22.46 | -43.30 | 1679 |
| A609 | Resende | Medio Paraiba | -22.45 | -44.45 | 398 |
| A652 | Rio de Janeiro (Copacabana) | Metropolitana I | -22.99 | -43.19 | 5 |
| A636 | Rio de Janeiro (Jacarepagua) | Metropolitana I | -22.97 | -43.38 | 3 |
| A602 | Rio de Janeiro (Marambaia) | Metropolitana I | -23.05 | -43.60 | 4 |
| A621 | Rio de Janeiro (Vila Militar) | Metropolitana I | -22.86 | -43.40 | 34 |
| A626 | Rio Claro | Medio Paraiba | -22.72 | -44.14 | 447 |
| A630 | Santa Maria Madalena | Serrana | -21.95 | -41.99 | 615 |
| A667 | Saquarema (Sampaio Correia) | Baixada Litoranea | -22.85 | -42.63 | 7 |
| A601 | Seropedica (Ecologia Agricola) | Metropolitana I | -22.76 | -43.68 | 33 |
| A659 | Silva Jardim | Baixada Litoranea | -22.62 | -42.39 | 22 |
| A618 | Teresopolis (Parque Nacional) | Serrana | -22.45 | -42.99 | 871 |
| A625 | Tres Rios | Centro-Sul | -22.12 | -43.21 | 275 |
| A611 | Valenca | Medio Paraiba | -22.25 | -43.70 | 458 |

Full station audit: `audit/WEATHER_STATIONS_AUDIT.csv`

---

## Methodological Decisions

### 1. Why the Mortality Period Ends in 2024

The SIM-DO dataset for 2025 was not available at the time of data extraction. Three alternatives were considered:

| Approach | Decision | Rationale |
|---|---|---|
| Fill 2025 with SIH `MORTE=1` | **REJECTED** | Hospital death during a cerebrovascular admission is not epidemiologically equivalent to cerebrovascular disease as the underlying cause of death in the population. This approach would: exclude out-of-hospital deaths, exclude deaths in non-SUS facilities, and create an artificial break in 2025. |
| Set 2025 deaths to zero | **REJECTED** | Would artificially deflate mortality rates and potentially create spurious associations. |
| Restrict mortality to 2010-2024 | **ADOPTED** | Uses only SIM-DO data (cause of death certified on the death certificate). The difference in observation periods is explicitly documented in all equations, tables, and figures. |

To reproduce earlier versions that used SIH fallback: `export DLNM_SIM_SIH_FALLBACK=true`

### 2. Why I60-I64 as the Primary Outcome (not I60-I69)

| ICD-10 Code | Description | Included in Primary Analysis? | Rationale |
|---|---|---|---|
| I60 | Subarachnoid hemorrhage | Yes | Acute hemorrhagic event |
| I61 | Intracerebral hemorrhage | Yes | Acute hemorrhagic event |
| I62 | Other non-traumatic intracranial hemorrhage | Yes | Acute hemorrhagic event |
| I63 | Cerebral infarction | Yes | Acute ischemic event |
| I64 | Stroke, not specified | Yes | Acute event (imaging not available/recorded) |
| I65 | Occlusion/stenosis of pre-cerebral arteries | No | Vascular lesion without documented infarction |
| I66 | Occlusion/stenosis of cerebral arteries | No | Vascular lesion without documented infarction |
| I67 | Other cerebrovascular diseases | No | Heterogeneous category |
| I68 | Cerebrovascular disorders in other diseases | No | Secondary to other conditions |
| I69 | Sequelae of cerebrovascular disease | No | **Chronic condition** -- no plausible acute temporal relationship with short-term climate exposure |

A sensitivity analysis using I60-I69 is provided for comparability with earlier versions of this work.

### 3. Why Simple Mean (not Population-Weighted) for Climate Exposure

The macroregional climate exposure is computed as the simple arithmetic mean of all INMET stations with observations on a given day in that macroregion. A population-weighted alternative was explored in sensitivity analysis. The simple mean was retained as the primary specification because:

- INMET station locations are biased toward airports and agricultural research centers, not population centers
- Population weighting would amplify the signal from the densest municipality (e.g., Rio de Janeiro city in Metropolitana I)
- The sensitivity analysis showed directionally consistent results between simple mean and population-weighted approaches

### 4. I63 Coding Anomaly in SIM-DO

The SIM-DO dataset shows 1,235 deaths coded as I63 (ischemic stroke) versus 27,452 deaths coded as I61 (intracerebral hemorrhage) -- a ratio of approximately 1:22. In international mortality data, ischemic stroke deaths typically exceed hemorrhagic stroke deaths by a factor of 3-5.

This anomaly likely reflects systematic coding bias in Brazilian death certificates, where ischemic strokes may be classified as:
- I64 (unspecified stroke) when neuroimaging was not performed
- I69 (sequelae) when death occurs weeks after the initial event
- I67 (other cerebrovascular diseases) as a residual category

This limitation is documented in `audit/I63_ANOMALY_REPORT.md`. Subtype-specific analyses (I60-I62 vs I63 vs I64) should be interpreted with caution.

### 5. PM2.5 as Sensitivity Covariate Only

PM2.5 data enters models as a linear monthly covariate when `DLNM_ENABLE_AIR_QUALITY=true`. It is NOT treated as a primary exposure because:

| Attribute | Climate (INMET) | PM2.5 (INEA) |
|---|---|---|
| Temporal resolution | Daily (observed) | Monthly (derived) |
| Spatial resolution | Station-level | Municipality-level (74 of 92 monitored) |
| Measurement | Direct instrument | Annual mean + national seasonal profile (downscaled) |
| Cross-basis | Yes (ns x ns, lag 0-21 days) | No (linear term only) |
| 2025 data | Observed | Extrapolated from 2020-2024 trend |

These limitations preclude PM2.5 from being included as a primary DLNM exposure. The abstract and conclusions do not claim PM2.5 effects.

Full documentation: `audit/PM25_SENSITIVITY_CONFIG.md`

---

## Sensitivity Analyses

| # | Analysis | Description | Implementation |
|---|---|---|---|
| 1 | Lag maximum | Re-fit models with lag = 7, 14, 21 days | `run_lag_sensitivity()` |
| 2 | Temporal df | Re-fit with 4, 5, 6 df/year (vs 7 df/year primary) | `run_temporal_df_sensitivity()` |
| 3 | Pandemic exclusion | Remove 2020-03-01 to 2022-12-31 | `run_pandemic_exclusion_sensitivity()` |
| 4 | Mutual adjustment | Compare temperature-only, humidity-only, and mutually adjusted models | Built into `fit_one_dlnm()` |
| 5 | Outcome definition | I60-I64 (acute) vs I60-I69 (extended) | Separate outcome variables in dataset |
| 6 | Climate aggregation | Simple mean vs population-weighted mean | `exposure_processing.R` |
| 7 | Bayesian priors | Skeptical, optimistic, flat prior specifications | `run_prior_sensitivity()` |
| 8 | Case-crossover | Time-stratified (year-month-dow) design | `phaseB_final.R` |
| 9 | Attributable fraction | Monte Carlo simulation (500 iterations) | `phaseB_final.R` |
| 10 | Spline df grid | Cross-product of df_exp (3,4,5,6) x df_lag (3,4,5) | `run_spline_df_sensitivity()` |
| 11 | Newey-West lags | HAC with 14, 21, 28, 35 lags | `run_nw_lag_sensitivity()` |

---

## Audit and Quality Control

The audit trail comprises 88+ files documenting every step of the analytical pipeline.

### Integrity Tests (15 automated checks)

| # | Test | Status |
|---|---|---|
| 1 | Maximum SIH date is 2025-12-31 | PASS |
| 2 | Maximum SIM date is 2024-12-31 | PASS |
| 3 | No SIM deaths in 2025 | PASS |
| 4 | No SIH_AIHS_MORTE in SIM series | PASS |
| 5 | No duplicate dates in macroregional dataset | PASS |
| 6 | All population values > 0 | PASS |
| 7 | All offset values finite | PASS |
| 8 | No NaN or Inf in RR estimates | PASS |
| 9 | Exactly 72 models (9 x 4 x 2) | PASS |
| 10 | All 9 macroregions present | PASS |
| 11 | No RR > 100 (biologically implausible) | PASS |
| 12 | Mortality 2025 is NA (not zero) | PASS |
| 13 | At least 6 figures generated | PASS |
| 14 | All result tables readable | PASS |
| 15 | No PM2.5 as primary exposure | PASS |

### Key Audit Files

| File | Content |
|---|---|
| `audit/AUDIT_EXECUTIVE_SUMMARY.md` | Executive summary of all findings |
| `audit/AUDIT_FINDINGS.csv` | 7 findings by severity and domain |
| `audit/FILE_MANIFEST.csv` | Complete inventory of 1,604+ files |
| `audit/OUTCOME_TESTS.csv` | 15 integrity test results |
| `audit/MODEL_NUMERICAL_STABILITY.csv` | Stability status for all 72 models |
| `audit/DLNM_SPECIFICATION.csv` | Model parameter documentation |
| `audit/CLIMATE_COVERAGE.md` | Climate data coverage report |
| `audit/WEATHER_STATIONS_AUDIT.csv` | 26-station catalog with metadata |
| `audit/I63_ANOMALY_REPORT.md` | Investigation of I63 underreporting |
| `audit/PM25_SENSITIVITY_CONFIG.md` | PM2.5 sensitivity configuration |
| `audit/tabela_problemas_correcoes.csv` | 25 problems found and corrected |
| `audit/CHANGELOG_AUDIT.md` | Complete change history |
| `audit/UNRESOLVED_ISSUES.md` | Remaining limitations |
| `audit/testes_integridade_finais.csv` | Final integrity check results |

---

## R Environment

| Package | Version | Purpose |
|---|---|---|
| `dlnm` | 2.4.10 | Distributed lag non-linear models |
| `mgcv` | 1.9.4 | Generalized additive models (temporal splines) |
| `MASS` | 7.3-65 | Negative binomial GLM |
| `sandwich` | 3.1-1 | Newey-West HAC standard errors |
| `rstan` | 2.32.7 | Bayesian hierarchical modeling (Stan) |
| `brms` | 2.22.0 | Bayesian regression models |
| `microdatasus` | 2.5.0 | DATASUS data acquisition |
| `BrazilMet` | 0.4.0 | INMET weather data |
| `geobr` | 1.9.1 | Brazilian municipality geometries |
| `sf` | 1.1-0 | Spatial operations |
| `sidrar` | 0.2.9 | SIDRA/IBGE population data |
| `tidyverse` | 2.0.0 | Data manipulation and visualization |
| `plotly` | 4.12.0 | Interactive 3D surfaces |
| `targets` | 1.12.0 | Reproducible pipeline with caching |
| `renv` | 1.2.2 | Package version management |
| `spdep` | 1.3-6 | Spatial dependence (Moran's I) |
| `survival` | 3.8-3 | Conditional logistic regression |
| `patchwork` | 1.3.0 | Figure composition |
| `scales` | 1.3.0 | Axis scaling |

Complete package inventory: `renv.lock` (151 packages at exact versions).

---

## Reproducibility

| Component | Implementation |
|---|---|
| Package versions | `renv.lock` (151 packages, exact versions) |
| Computational environment | Docker (`rocker/geospatial:latest`) |
| Random seed | `set.seed(20260619)` |
| Raw data | Public APIs (DATASUS, INMET, SIDRA, INEA) |
| Audit trail | 88+ CSV/MD files in `audit/` |
| Unit tests | `testthat` (4 test files) |
| CI/CD | GitHub Actions (`.github/workflows/ci.yml`) |
| FAIR metadata | Data dictionary + lineage + `CITATION.cff` |
| Deterministic execution | `Makefile` + `run_dlnm_analysis.R` |

### Platform Compatibility

| Platform | Status |
|---|---|
| Windows 11 | Primary development platform; fully tested |
| Linux (Ubuntu/Debian) | Fully compatible; Docker tested |
| macOS (Intel + Apple Silicon) | `renv::restore()` resolves all binary packages |
| Any OS via Docker | `make docker-build && make docker-run` |

---

## Limitations

1. **Ecological design**: Associations estimated at macroregional level. No individual-level inference, no causal claims.
2. **SIM-DO 2025 unavailable**: Mortality restricted to 2010-2024. SIH hospital deaths NOT substituted.
3. **I63 underreporting in SIM**: Anomalous I61:I63 ratio (~22:1) likely reflects death certificate coding bias. Subtype-specific results require careful interpretation.
4. **PM2.5 granularity**: Monthly derived, not daily. Sensitivity covariate only. Not a primary exposure.
5. **Climate aggregation**: Simple mean across stations. Not population-weighted.
6. **Noroeste macroregion**: Only 1 INMET station (no spatial redundancy for imputation validation).
7. **Two-stage Bayesian**: Uncertainty from DLNM specification (knot placement, functional form) not fully propagated to posterior intervals.
8. **Intercensal population**: 2023-2025 based on post-Census 2022 projections (SIDRA/IBGE table 6579).
9. **Multiple comparisons**: FDR correction applied; exploratory nature of sensitivity analyses documented.
10. **No external validation**: Models fitted and evaluated on the full study period without independent holdout.
11. **Unmeasured confounding**: Socioeconomic status, housing quality, occupational exposure, comorbidities, and healthcare access not available in administrative databases.

---

## Citation

```bibtex
@software{santos2026dlnm,
  title = {Climate Exposure and Cerebrovascular Outcomes in Rio de Janeiro (2010-2025):
           A Reproducible DLNM-Bayesian Framework Using INMET, DATASUS and SIDRA},
  author = {Santos, Ryan de Paulo and Nunes, Camila Henriques and
            Ribeiro, Karla Rangel and Medina-Acosta, Enrique},
  year = {2026},
  url = {https://github.com/santosry/dlnm-gam-cerebrovascular-rj}
}
```

---

## AI Usage Declaration

This project utilized artificial intelligence technologies as technical assistants for software development, documentation, and quality assurance. The following models were used:

| Model | Purpose |
|---|---|
| **ChatGPT 5.6** | Technical audit, international benchmarking, compliance checklists, manuscript structuring |
| **OpenAI Codex** | R function development, statistical debugging, unit test generation, FAIR metadata authoring |
| **DeepSeek v4-pro** | Code refactoring, documentation generation, CI/CD pipeline configuration, research compendium architecture |

All scientific decisions -- including model selection, parameter specification, result interpretation, epidemiological reasoning, and methodological justifications -- were made exclusively by human researchers (RPS, CHN, KRR, EMA). AI systems were used solely to accelerate implementation, verify correctness, and ensure documentation quality. No statistical analysis, hypothesis testing, or scientific conclusion was delegated to or generated by an AI model.

---

## License and Data

**Code:** MIT License. See `LICENSE` for full terms.

**Data:** All data used in this study are publicly available from Brazilian government agencies:
- DATASUS (Ministry of Health): SIH-RD and SIM-DO hospital and mortality records
- INMET (Ministry of Agriculture): Weather station observations
- IBGE/SIDRA: Population census and estimates
- INEA (Rio de Janeiro State Environment Institute): PM2.5 monitoring data

No proprietary, restricted, or individually identifiable data are included in this repository.

---

Languages: R, Python, Stan

Last updated: 2026-07-14
