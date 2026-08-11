# Makefile — Automated workflow orchestration for the DLNM compendium
# =============================================================================
# Usage:
#   make setup         — First-time setup: renv + R packages (no Python needed)
#   make setup-python   — Optional: install Python + Playwright for PM2.5 re-extraction
#   make all            — Run the complete pipeline (download → process → models → validate → reports → audit)
#   make download       — Download raw data: SIH, SIM, INMET (DATASUS + BrazilMet APIs)
#   make download-pm25  — Optional: re-extract PM2.5 from INEA/MonitorAr Power BI
#   make process        — Build analytic dataset with PM2.5 join
#   make models         — Fit DLNM models (144+ combinations)
#   make validate       — Bayesian hierarchical validation + sensitivity analyses
#   make reports        — Generate figures, tables, and manuscript
#   make audit          — Run benchmark, quality control, centralize audits
#   make test           — Run unit tests (testthat)
#   make lint           — Lint R code
#   make docker-build   — Build Docker image
#   make docker-run     — Run pipeline in Docker
#   make clean          — Remove derived outputs (preserves PM2.5 tables)
#   make clean-all      — Full reset (removes all data including PM2.5)
#   make renv-snapshot  — Update renv.lock
#   make renv-restore   — Restore R packages from renv.lock
#   make help           — Show this help
#
# Environment variables:
#   DLNM_PROJECT_ROOT         — Absolute path to project (required)
#   DLNM_ENABLE_AIR_QUALITY   — "true" to activate PM2.5 sensitivity
#   DLNM_FORCE_RAW_DOWNLOAD   — "true" to re-download all raw data
#   RUN_PIPELINE_ON_SOURCE    — "true" to auto-run run_pipeline.R on source()

.PHONY: all setup setup-python download download-pm25 process models validate reports audit clean clean-all \
        docker-build docker-run test lint help renv-snapshot renv-restore

RSCRIPT = Rscript --vanilla
PYTHON = python3

# ── First-time setup ──
setup:
	@echo "=== Setting up R environment (renv) ==="
	$(RSCRIPT) -e "install.packages('renv', repos='https://cloud.r-project.org')"
	$(RSCRIPT) -e "renv::restore()"
	@echo "=== Setup complete! ==="
	@echo ""
	@echo "💡 PM2.5 tables are pre-packaged in data/processed/pm25/ — no Python needed."
	@echo "   To enable PM2.5 sensitivity: Sys.setenv(DLNM_ENABLE_AIR_QUALITY = 'true')"

# ── Optional: Python setup for PM2.5 re-extraction ──
setup-python:
	@echo "=== Setting up Python environment (OPTIONAL) ==="
	$(PYTHON) -m pip install -r python/requirements.txt
	$(PYTHON) -m playwright install chromium
	@echo "=== Python setup complete! ==="

# ── Main targets ──
all: download process models validate reports audit

# ── Data acquisition ──
# PM2.5 monthly tables are PRE-PACKAGED in data/processed/pm25/.
# The download-pm25 target is OPTIONAL — only needed if you want to
# re-extract from the INEA/MonitorAr Power BI dashboard de novo.
download-pm25:
	$(PYTHON) python/extrair_mp25_rj.py

download:
	$(RSCRIPT) -e "source('config/config.R'); source('R/download.R'); download_sih(); download_sim(); download_inmet()"

# ── Data processing ──
process:
	$(RSCRIPT) -e "source('config/config.R'); source('R/utils.R'); source('R/download.R'); source('R/exposure_processing.R'); source('R/preprocessing.R'); outcomes <- process_outcomes(); meteo <- process_inmet(); population <- download_population_sidra(); dat_macro <- make_analytic_dataset(outcomes, meteo, population)"

# ── DLNM modeling ──
models:
	$(RSCRIPT) -e "source('config/config.R'); source('R/utils.R'); source('R/dlnm_models.R'); dat_macro <- readRDS('data/processed/dataset_dlnm_macrorregiao.rds'); run_dlnm(dat_macro)"

# ── Bayesian validation ──
validate:
	$(RSCRIPT) -e "source('config/config.R'); source('R/utils.R'); source('R/bayesian_models.R'); rr_tbl <- readr::read_csv('outputs/tables/tabela_rr_dlnm_macrorregiao.csv', show=F); auc_tbl <- readr::read_csv('outputs/tables/tabela_auc_rr_dlnm_macrorregiao.csv', show=F); run_bayesian_hierarchical_validation(rr_tbl, auc_tbl)"

# ── Reports and visualizations ──
reports:
	$(RSCRIPT) -e "source('config/config.R'); source('R/utils.R'); source('R/visualization.R'); source('R/reporting.R'); dat_macro <- readRDS('data/processed/dataset_dlnm_macrorregiao.rds'); dlnm_results <- readRDS('data/processed/modelos_dlnm_macrorregiao.rds'); plot_monthly_admissions(dat_macro); plot_daily_climate_seasonality(dat_macro); write_final_reports_epidemiologicos(dat_macro, dlnm_results); render_bsb_outputs()"

# ── Audit and benchmark ──
audit:
	$(RSCRIPT) -e "source('config/config.R'); source('R/utils.R'); source('R/reporting.R'); run_benchmark_validation(); centralize_audits()"

# ── Testing ──
test:
	@echo "=== Running unit tests (testthat) ==="
	$(RSCRIPT) -e "source('renv/activate.R'); testthat::test_dir('tests/testthat', reporter='summary')"
	@echo "=== Tests complete ==="

lint:
	@echo "=== Linting R code ==="
	$(RSCRIPT) -e "lintr::lint_dir('R/')"

# ── Docker ──
docker-build:
	docker build -t dlnm-cerebrovascular-rj -f docker/Dockerfile .

docker-run:
	docker run --rm \
		-v $(shell pwd)/outputs:/home/rstudio/dlnm-compendium/outputs \
		-v $(shell pwd)/data:/home/rstudio/dlnm-compendium/data \
		-v $(shell pwd)/audit:/home/rstudio/dlnm-compendium/audit \
		-v $(shell pwd)/logs:/home/rstudio/dlnm-compendium/logs \
		dlnm-cerebrovascular-rj

# ── Renv ──
renv-snapshot:
	$(RSCRIPT) -e "renv::snapshot()"

renv-restore:
	$(RSCRIPT) -e "renv::restore()"

# ── Cleaning ──
clean:
	rm -rf outputs/figures/* outputs/tables/* logs/*.log
	rm -rf data/interim/*
	# Preserve pre-packaged PM2.5 tables in data/processed/pm25/
	find data/processed -mindepth 1 ! -path 'data/processed/pm25*' -exec rm -rf {} +

clean-all: clean
	rm -rf data/raw/*
	# Also remove PM2.5 tables (full reset)
	rm -rf data/processed/pm25

# ── Help ──
help:
	@echo "============================================"
	@echo "  DLNM Cerebrovascular RJ (2010-2025)"
	@echo "  Research Compendium"
	@echo "============================================"
	@echo ""
	@echo "QUICK START:"
	@echo "  make setup && make all"
	@echo ""
	@echo "PREREQUISITES:"
	@echo "  R >= 4.4.0, Git >= 2.30, Git LFS >= 3.0, Make"
	@echo "  PM2.5 tables PRE-PACKAGED -- no Python required"
	@echo ""
	@echo "ENVIRONMENT VARIABLES:"
	@echo "  DLNM_PROJECT_ROOT         Absolute path to project (required)"
	@echo "  DLNM_ENABLE_AIR_QUALITY   \"true\" to activate PM2.5 sensitivity"
	@echo "  DLNM_FORCE_RAW_DOWNLOAD   \"true\" to re-download all raw data"
	@echo ""
	@echo "TARGETS:"
	@echo "  setup             Install renv + restore 151 R packages"
	@echo "  setup-python      Optional: install Python + Playwright"
	@echo "  all               Full pipeline: download process models validate reports audit"
	@echo "  download          Download SIH, SIM, INMET from public APIs"
	@echo "  download-pm25     Optional: re-extract PM2.5 from Power BI"
	@echo "  process           Build analytic dataset + join PM2.5"
	@echo "  models            Fit 144+ DLNM models"
	@echo "  validate          Bayesian validation + sensitivity + FDR"
	@echo "  reports           Generate 16 figures + 129 interactive HTMLs + 34 tables"
	@echo "  audit             Benchmark, QC, centralize audit trail (59+ files)"
	@echo "  test              Run unit tests (testthat)"
	@echo "  lint              Lint R code"
	@echo "  docker-build      Build Docker image"
	@echo "  docker-run        Run full pipeline in Docker"
	@echo "  clean             Remove derived outputs (preserves PM2.5)"
	@echo "  clean-all         Full reset (removes everything)"
	@echo "  renv-snapshot     Update renv.lock"
	@echo "  renv-restore      Restore packages from renv.lock"
	@echo "  help              Show this help"
	@echo ""
	@echo "FOR AUTOMATED EXECUTION (CI/CD, code agents):"
	@echo "  export DLNM_PROJECT_ROOT=\$$(pwd)"
	@echo "  export DLNM_ENABLE_AIR_QUALITY=true"
	@echo "  make setup && make all && make test"
