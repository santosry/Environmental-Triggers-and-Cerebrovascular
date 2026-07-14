# Climate Exposure and Cerebrovascular Outcomes in Rio de Janeiro, Brazil (2010–2025)

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.0000000.svg)](https://doi.org/10.5281/zenodo.0000000)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![R 4.4+](https://img.shields.io/badge/R-%E2%89%A54.4.0-blue.svg)](https://www.r-project.org/)

**Research Compendium — Environmental Epidemiology with Distributed Lag Non-linear Models (DLNM) and Hierarchical Bayesian Inference**

---

## Abstract

This repository investigates non-linear and delayed associations between daily mean temperature, daily relative humidity, and hospital admissions/deaths from acute cerebrovascular diseases (ICD-10 I60–I64) across the nine health macroregions of Rio de Janeiro state, Brazil.

**Study design:** Ecological daily time series  
**Outcomes:** ICD-10 I60–I64 (acute cerebrovascular events): I60–I62 hemorrhagic, I63 ischemic, I64 unspecified  
**Period:** Admissions (SIH-RD) 2010-01-01 to 2025-12-31; Mortality (SIM-DO, cause of death) 2010-01-01 to 2024-12-31  
**Methods:** Distributed Lag Non-linear Models (DLNMs) with natural spline cross-bases, Quasi-Poisson/Negative Binomial regression, hierarchical Bayesian stabilization (Stan/Normal-Normal), Newey-West HAC standard errors with delta-method propagation, FDR-corrected P05/P95 contrasts, time-stratified case-crossover sensitivity, and Monte Carlo attributable fraction estimation  
**Data:** DATASUS (SIH-RD, SIM-DO), INMET (26 weather stations), INEA/MonitorAr (PM2.5, optional sensitivity only), SIDRA/IBGE population denominators

> ⚠️ **Important:** This is an ecological, associational study. Estimates reflect macroregional-level associations. No individual-level, causal, or forecasting claims are made. Mortality data for 2025 is NOT available — SIM-DO ends at 2024-12-31.

---

## Key Results

| Metric | Value |
|---|---|
| **Models fitted** | 72/72 (100% success) |
| **Integrity tests** | 15/15 passed |
| **Consistent signals** (FDR < 0.05, no residual autocorrelation) | 4 |
| **Suggestive signals** (FDR < 0.10) | 24 |
| **Insufficient evidence** | 44 |
| **Numerically invalid models** | 0 |

### Consistent Signals (P05/P95 contrasts)

| Macroregion | Outcome | Exposure | RR P05 | RR P95 | FDR p |
|---|---|---|---|---|---|
| Metropolitana I | Deaths I60–I69 | Humidity | 1.12 | 1.10 | 0.004 |
| Noroeste | Deaths I60–I64 | Temperature | 1.85 | 1.41 | 0.049 |
| Norte | Deaths I60–I69 | Humidity | 1.14 | 0.98 | 0.034 |
| Serrana | Deaths I60–I64 | Humidity | 1.03 | 0.74 | 0.004 |

**Total events:** 288,395 admissions (2010–2025), 147,551 deaths (2010–2024)

---

## Quick Start

> **Requirements:** R ≥ 4.4.0, Git ≥ 2.30, Git LFS ≥ 3.0, Make  
> **Platforms:** Windows, Linux, macOS (Docker recommended for cross-platform reproducibility)

### Option 1: Corrected Pipeline (single command)

```bash
git clone https://github.com/santosry/exposome-cerebrovascular-rj.git
cd exposome-cerebrovascular-rj
export DLNM_PROJECT_ROOT=$(pwd)
export DLNM_SIM_SIH_FALLBACK=false
Rscript pipeline_corrigido.R
```

### Option 2: Docker (zero setup, any OS)

```bash
git clone https://github.com/santosry/exposome-cerebrovascular-rj.git
cd exposome-cerebrovascular-rj
make docker-build
make docker-run
```

### Option 3: Makefile (granular control)

```bash
git clone https://github.com/santosry/exposome-cerebrovascular-rj.git
cd exposome-cerebrovascular-rj
make setup        # Install R packages via renv (151 packages)
make download     # Download raw data from DATASUS, INMET
make process      # Build analytic dataset
make models       # Fit 72 DLNM models
make validate     # Bayesian validation + sensitivity
make reports      # Generate figures, tables
make audit        # Quality control, benchmarks
make test         # Run unit tests (testthat)
make all          # Full pipeline end-to-end
```

---

## Methods at a Glance

### DLNM Specification

| Parameter | Value |
|---|---|
| Cross-basis | `ns(temp/ur, df=4) × ns(lag, df=3, log-knots)`, lag max = 21 days |
| Model family | Quasi-Poisson (Negative Binomial fallback if φ > 3) |
| Temporal control | 7 df/year (admissions), 5 df/year (mortality) |
| Calendar adjustment | Day-of-week + Brazilian holidays (fixed + movable: Carnival, Easter, Corpus Christi) |
| Pandemic control | Binary indicator: 2020-03-01 to 2022-12-31 |
| Complementary exposure | `ns(complementary_var, df=3)` — mutual adjustment for temperature and humidity |
| Offset | `log(population)` from SIDRA/IBGE |
| Centering | P50 (median) regional exposure value |
| Primary contrasts | P05 vs P50 (low exposure), P95 vs P50 (high exposure) |
| Standard errors | Newey-West HAC (21 lags) with delta-method propagation |
| Multiple testing | Benjamini-Hochberg FDR across 72 contrasts |

### Model Equation

$$
Y^{o}_{rt} \sim \text{quasi-Poisson}(\mu^{o}_{rt}, \phi^{o}), \quad t \in \mathcal{T}^{o}
$$

$$
\log(\mu^{o}_{rt}) = \log(\text{Pop}_{r, \text{year}(t)}) + \alpha^{o}_{r} + \text{CB}^{o}_{r}(X_{rt}) + \text{ns}(\text{time}_t, \text{df}_{\text{temporal}}) + \beta_1 \text{dow}_t + \beta_2 \text{holiday}_t + \beta_3 \text{pandemic}_t + \beta_4 \text{ns}(Z_{rt}, 3)
$$

Where:
- $o \in \{\text{admissions}, \text{deaths}\}$
- $\mathcal{T}^{\text{admissions}} = [\text{2010-01-01}, \text{2025-12-31}]$ (5,844 days)
- $\mathcal{T}^{\text{deaths}} = [\text{2010-01-01}, \text{2024-12-31}]$ (5,479 days)
- $r =$ macroregion (1 of 9)
- $\text{CB}^{o}_{r}(X_{rt}) =$ cross-basis of exposure $X_{rt}$

### Classification Framework

| Level | Criteria |
|---|---|
| **Consistent signal** | FDR < 0.05 AND Ljung-Box p > 0.05 AND finite RR AND stable across ≥3 sensitivities |
| **Suggestive signal** | FDR < 0.10 AND finite RR |
| **Insufficient evidence** | FDR ≥ 0.10 or unstable across specifications |
| **Invalid model** | Convergence failure, explosive RR, non-finite SE, or prediction beyond observed range |

### Sensitivity Analyses

| Analysis | Description |
|---|---|
| Lag grid | 7, 14, 21 days |
| Temporal df | 4, 5, 6, 7 df/year |
| Pandemic exclusion | Models without 2020-03-01 to 2022-12-31 |
| Mutual adjustment | Temperature alone, humidity alone, mutually adjusted |
| Outcome definition | I60–I64 (acute) vs I60–I69 (extended, includes I69 sequelae) |
| Climate exposure | Simple mean vs population-weighted mean |
| Bayesian priors | Skeptical, optimistic, flat specifications |
| Case-crossover | Time-stratified (year-month-dow) |
| Attributable fraction | Monte Carlo simulation (500 iterations) |

---

## Repository Structure

```
.
├── README.md                          # This file
├── LICENSE                            # MIT License
├── CITATION.cff                       # Citation metadata (CFF format)
├── COMPENDIUM_MANIFEST.yml            # Research compendium manifest
├── REPRODUCIBILITY_CHECKLIST.md       # Reproducibility compliance
├── Makefile                           # Automated workflow (all targets)
├── pipeline_corrigido.R               # ★ CORRECTED MASTER PIPELINE
├── run_pipeline.R                     # Original pipeline entry point
├── _targets.R                         # Incremental pipeline (targets)
├── renv.lock                          # 151 R packages at exact versions
├── .gitignore                         # Git ignore rules
├── .gitattributes                     # Git LFS tracking rules
│
├── config/
│   └── config.R                       # Global parameters, env vars, directories
│
├── R/
│   ├── utils.R                        # Logging, encoding, holidays, math helpers
│   ├── download.R                     # DATASUS, INMET, SIDRA/IBGE acquisition
│   ├── exposure_processing.R          # INMET station mapping, climate imputation
│   ├── preprocessing.R                # SIH/SIM cleaning, PM2.5, population offset
│   ├── dlnm_models.R                  # DLNM fitting, HAC SE, diagnostics
│   ├── bayesian_models.R              # Hierarchical Bayesian stabilization
│   ├── visualization.R                # Figures, 3D surfaces, interactive plots
│   └── reporting.R                    # Reports, benchmarks, quality control
│
├── python/
│   ├── extrair_mp25_rj.py             # PM2.5 extraction (OPTIONAL, pre-packaged)
│   └── requirements.txt               # Python deps (OPTIONAL)
│
├── data/
│   ├── raw/                           # Downloaded source data (regenerated by pipeline)
│   │   ├── sih/                       # 192 SIH-RD monthly files (2010–2025)
│   │   ├── sim/                       # 15 SIM-DO yearly files (2010–2024)
│   │   └── inmet/                     # 26+ INMET station daily files
│   ├── interim/                       # Intermediate cleaned files
│   └── processed/                     # Analytical datasets and model objects
│       ├── pm25/                      # Pre-packaged PM2.5 tables (4 CSVs)
│       ├── dataset_dlnm_macrorregiao.rds         # Analytic dataset
│       ├── desfechos_diarios_municipio.rds       # Daily municipality-level outcomes
│       ├── inmet_diario_macrorregiao.rds         # Macroregional climate data
│       └── modelos_dlnm_macrorregiao_corrigido.rds  # 72 fitted DLNM models
│
├── outputs/
│   ├── figures/                       # 19 static PNGs (300 DPI) + interactive HTML
│   │   ├── Fig01_sazonalidade_internacoes.png
│   │   ├── Fig02_distribuicao_cid.png
│   │   ├── Fig03_curva_*.png          # DLNM curves for consistent-signal models
│   │   └── Fig04_forest_bayesiano.png # Bayesian forest plot
│   └── tables/                        # 42 analytical CSV tables
│       ├── tabela_rr_dlnm_corrigida.csv           # Primary RR results (all 72 models)
│       ├── estimativas_completas_corrigidas.csv   # Full estimates with Bayesian
│       ├── resultados_bayesianos_corrigidos.csv   # Bayesian posterior summaries
│       ├── case_crossover_time_stratified.csv     # Case-crossover estimates
│       ├── fracao_atribuivel_monte_carlo.csv      # Attributable fraction
│       ├── stan_bayesian_multivariate.csv         # Stan hierarchical model
│       └── tabela_exposicao_por_regiao.csv        # Exposure statistics by region
│
├── audit/                             # 88+ audit trail files
│   ├── AUDIT_EXECUTIVE_SUMMARY.md     # Executive audit summary
│   ├── AUDIT_FINDINGS.csv             # All audit findings
│   ├── FILE_MANIFEST.csv              # Complete file inventory
│   ├── OUTCOME_TESTS.csv              # Outcome integrity tests (15/15)
│   ├── CLIMATE_COVERAGE.md            # Climate data coverage report
│   ├── WEATHER_STATIONS_AUDIT.csv     # Station catalog with coordinates
│   ├── DLNM_SPECIFICATION.csv         # Model specification documentation
│   ├── MODEL_NUMERICAL_STABILITY.csv  # Numerical stability per model
│   ├── I63_ANOMALY_REPORT.md          # I63 coding anomaly investigation
│   ├── PM25_SENSITIVITY_CONFIG.md     # PM2.5 sensitivity configuration
│   ├── CHANGELOG_AUDIT.md             # Complete change log
│   ├── UNRESOLVED_ISSUES.md           # Remaining limitations
│   └── tests/                         # Automated integrity tests
│
├── tests/
│   └── testthat/
│       ├── test_utils.R
│       ├── test_preprocessing.R
│       ├── test_dlnm_models.R
│       └── test_bayesian.R
│
├── logs/                              # Pipeline execution logs
├── docs/                              # Extended documentation
├── docker/                            # Docker configuration
│   ├── Dockerfile
│   └── docker-compose.yml
├── metadata/                          # FAIR metadata
└── .github/
    └── workflows/                     # CI/CD (GitHub Actions)
```

---

## Data Sources

| Source | System | Period | Variables | Access Method |
|---|---|---|---|---|
| **DATASUS** | SIH-RD | 2010–2025 | Hospital admissions (DIAG_PRINC) | `microdatasus` R package |
| **DATASUS** | SIM-DO | 2010–2024 | Mortality (CAUSABAS) | `microdatasus` R package |
| **INMET** | Weather stations | 2010–2025 | Temperature, humidity (26 stations) | `BrazilMet` R package |
| **SIDRA/IBGE** | Population | 2010–2025 | Resident population (Census + estimates) | `sidrar` R package |
| **INEA/MonitorAr** | PM2.5 | 2010–2025 | Monthly derived (74 municipalities) | Python/Playwright (optional) |

> **Detailed station coverage:** See `docs/data_sources/station_coverage.md` — complete catalog of 26 INMET stations (codes, coordinates, operation dates, imputation methods). PM2.5 monthly tables are pre-packaged in `data/processed/pm25/`.

---

## Critical Methodological Decisions

### 1. Mortality Period: 2010–2024 (NOT 2025)

SIM-DO 2025 data was not available at extraction time. The pipeline:

- **DOES NOT** use the SIH `MORTE` field (in-hospital death) to substitute missing SIM data
- **DOES NOT** set 2025 deaths to zero
- **DOES NOT** impute 2025 mortality

**Rationale:** Hospital death during a cerebrovascular admission (SIH `MORTE=1`) is epidemiologically distinct from cerebrovascular disease as the underlying cause of death in the population (SIM `CAUSABAS`). Mixing these would: (i) exclude out-of-hospital and pre-hospital deaths, (ii) exclude deaths in non-SUS facilities, and (iii) create an artificial break in the 2025 mortality series.

Set `DLNM_SIM_SIH_FALLBACK=true` only to reproduce earlier versions of this work.

### 2. Primary Outcome: I60–I64 (Acute Events)

The primary analysis uses ICD-10 codes I60 through I64:

- I60–I62: Hemorrhagic stroke
- I63: Ischemic stroke (cerebral infarction)
- I64: Stroke, not specified as hemorrhagic or ischemic

I69 (sequelae of cerebrovascular diseases) is excluded from the primary analysis because sequelae represent chronic conditions without a plausible short-term temporal relationship with acute climate exposures. I65–I66 (occlusion/stenosis without infarction) are also excluded from the primary outcome.

A sensitivity analysis using I60–I69 is provided for comparability with earlier versions.

### 3. I63 Coding Anomaly in SIM

The SIM-DO dataset shows an unusually low count of I63 (ischemic stroke) deaths: 1,235 compared to I61 (intracerebral hemorrhage) at 27,452 — a ratio of ~22:1 in the opposite direction from international patterns. This likely reflects coding bias in Brazilian death certificates, where ischemic strokes may be classified as I64 (unspecified) or I69 (sequelae). See `audit/I63_ANOMALY_REPORT.md`.

### 4. PM2.5: Sensitivity Covariate Only

PM2.5 data is **monthly** and derived from annual municipality means plus a national seasonal profile. It is **NOT** a daily exposure and **NOT** used in a cross-basis. When enabled via `DLNM_ENABLE_AIR_QUALITY=true`, PM2.5 enters models as a linear monthly covariate in sensitivity analyses only. The manuscript abstract and conclusions do not claim PM2.5 effects.

---

## Execution Guide

### Prerequisites

| Requirement | Version | Check |
|---|---|---|
| R | ≥ 4.4.0 | `R --version` |
| Git | ≥ 2.30 | `git --version` |
| Git LFS | ≥ 3.0 | `git lfs version` |
| Make | any | `make --version` |
| Python (optional) | ≥ 3.9 | `python3 --version` |
| Docker (optional) | ≥ 24 | `docker --version` |

### Environment Variables

```bash
# REQUIRED
export DLNM_PROJECT_ROOT="/absolute/path/to/exposome-cerebrovascular-rj"

# CRITICAL: Do NOT substitute SIH deaths for missing SIM data
export DLNM_SIM_SIH_FALLBACK="false"

# OPTIONAL: Enable PM2.5 monthly sensitivity covariate
export DLNM_ENABLE_AIR_QUALITY="false"

# OPTIONAL: Force re-download of raw data
export DLNM_FORCE_RAW_DOWNLOAD="false"
```

### One-Command Full Execution

```bash
export DLNM_PROJECT_ROOT="$(pwd)"
export DLNM_SIM_SIH_FALLBACK="false"
Rscript pipeline_corrigido.R
```

### Step-by-Step

```bash
# Step 1: Setup R environment
make setup

# Step 2: Download raw data (skip if already cached)
make download

# Step 3: Process data and build analytic dataset
make process

# Step 4: Fit DLNM models (72 models, ~30 minutes)
make models

# Step 5: Bayesian validation + sensitivity analyses
make validate

# Step 6: Generate figures and tables
make reports

# Step 7: Quality control and benchmarks
make audit

# Step 8: Run unit tests
make test

# Or: one command
make setup && make all && make test
```

### Verification Checklist

After execution, verify:

| Item | Expected | Check |
|---|---|---|
| Analytic dataset | 52,596 rows | `wc -l data/processed/dataset_dlnm_macrorregiao.rds` |
| DLNM models | 72 models | Check `outputs/tables/tabela_rr_dlnm_corrigida.csv` |
| RR table | 72 rows, all finite | `grep -c "Inf\|NaN" outputs/tables/tabela_rr_dlnm_corrigida.csv` |
| Integrity tests | 15/15 passed | Check `audit/testes_integridade_finais.csv` |
| Figures | 19 PNGs | `ls outputs/figures/*.png | wc -l` |
| No SIH fallback | TRUE | Check `audit/OUTCOME_TESTS.csv` |
| SIM 2025 is NA | TRUE | All 2025 deaths are `NA`, not `0` |
| Unit tests | All passed | `make test` |

### Troubleshooting

| Problem | Cause | Solution |
|---|---|---|
| `renv::restore()` fails | Missing system library | Install: `libcurl4-openssl-dev libssl-dev libxml2-dev libgdal-dev` |
| DATASUS download fails | API timeout | Re-run `make download` later |
| INMET API fails | Server instability | Local zip fallback in `data/raw/inmet_zip/` |
| "No SIH files found" | Download skipped | Run `make download` first |
| Memory exhausted | Models need RAM | Ensure ≥8 GB; Docker: `--memory=16g` |
| Test failures | Package mismatch | `make renv-restore` to sync versions |

---

## R Environment

R version 4.6.0 (2026-04-24). 151 packages at exact versions in `renv.lock`.

| Package | Version | Purpose |
|---|---|---|
| `dlnm` | 2.4.10 | Distributed lag non-linear models |
| `mgcv` | 1.9.4 | GAM for temporal trend |
| `MASS` | 7.3-65 | Negative binomial GLM |
| `sandwich` | 3.1-1 | Newey-West HAC standard errors |
| `rstan` | 2.32.7 | Bayesian hierarchical modeling |
| `microdatasus` | 2.5.0 | DATASUS data acquisition |
| `BrazilMet` | 0.4.0 | INMET weather data |
| `geobr` | 1.9.1 | Municipality geometries |
| `sf` | 1.1-0 | Spatial operations |
| `sidrar` | 0.2.9 | SIDRA/IBGE population |
| `tidyverse` | 2.0.0 | Data manipulation and plotting |
| `plotly` | 4.12.0 | Interactive 3D surfaces |
| `targets` | 1.12.0 | Reproducible pipeline with caching |
| `renv` | 1.2.2 | Package version management |

---

## Reproducibility

| Component | Status |
|---|---|
| Package versions | `renv.lock` (151 packages at exact versions) |
| Computational environment | Docker (`rocker/geospatial:latest`) |
| Random seed | `set.seed(20260619)` |
| Raw data | Public APIs (DATASUS, INMET, SIDRA, INEA) |
| Audit trail | 88+ audit CSV/MD files |
| Unit tests | `testthat` (utils, preprocessing, DLNM, Bayesian) |
| CI/CD | GitHub Actions |
| FAIR metadata | Data dictionary + lineage + CITATION.cff |

---

## Limitations

1. **Ecological design** — associations at macroregional level; no individual-level inference
2. **SIM-DO 2025 unavailable** — mortality restricted to 2010–2024; SIH hospital deaths NOT substituted
3. **I63 underreporting in SIM** — anomalous I61:I63 ratio likely reflects death certificate coding bias
4. **PM2.5 granularity** — monthly derived, not daily; sensitivity covariate only
5. **Climate aggregation** — simple mean across stations within macroregion; not population-weighted
6. **Noroeste macroregion** — only 1 INMET station (no spatial redundancy)
7. **Two-stage Bayesian** — uncertainty from DLNM specification not fully propagated
8. **Intercensal population** — 2023–2025 based on post-Census 2022 projections
9. **Multiple comparisons** — FDR correction applied; exploratory nature documented
10. **No external validation** — models fitted and evaluated on full period without out-of-sample holdout

---

## Citation

```bibtex
@software{santos2026dlnm,
  title = {Climate Exposure and Cerebrovascular Outcomes in Rio de Janeiro (2010–2025):
           A Reproducible DLNM-Bayesian Framework},
  author = {Santos, Ryan de Paulo and Nunes, Camila Henriques and
            Ribeiro, Karla Rangel and Medina-Acosta, Enrique},
  year = {2026},
  doi = {10.5281/zenodo.0000000},
  url = {https://github.com/santosry/exposome-cerebrovascular-rj}
}
```

## Author Contributions (CRediT)

| Role | Authors |
|---|---|
| Conceptualization | Ryan de Paulo Santos, Camila Henriques Nunes, Enrique Medina-Acosta |
| Data curation, analysis, interpretation | Ryan de Paulo Santos, Enrique Medina-Acosta |
| Software and methodology | Ryan de Paulo Santos |
| Writing — original draft and critical revision | Ryan de Paulo Santos, Enrique Medina-Acosta |
| Final approval | Ryan de Paulo Santos, Camila Henriques Nunes, Karla Rangel Ribeiro, Enrique Medina-Acosta |

---

## AI Usage Declaration

This project used AI technologies as technical assistants for code refactoring, documentation, CI/CD pipelines, and research compendium structure. All scientific decisions (model selection, parameters, result interpretation) were made exclusively by human researchers. Full declaration: `docs/AI_DECLARATION.md`.

---

## License

MIT License. Data sources are publicly available from Brazilian government agencies (DATASUS, INMET, IBGE, INEA).

---

Languages: R, Python, Stan
