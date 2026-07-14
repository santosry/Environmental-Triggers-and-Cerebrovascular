#!/usr/bin/env Rscript
# =============================================================================
# PIPELINE CORRIGIDO — DLNM Cerebrovascular RJ (2010-2025)
# =============================================================================
# Correções aplicadas:
#   [C01] DLNM_SIM_SIH_FALLBACK = FALSE (não usar MORTE da AIH para SIM 2025)
#   [C02] Óbitos restritos a 2010-2024 (SIM-DO)
#   [C03] Internações 2010-2025 (SIH-RD)
#   [C04] P05 e P95 como contrastes principais (não RR máximo)
#   [C05] FDR aplicado sobre os contrastes P05/P95 (não sobre RRmax)
#   [C06] Classificação: sinal consistente / sugestivo / insuficiente / inválido
#   [C07] AUC padronizada em escala de percentis (não AUC bruta)
#   [C08] Modelos inválidos marcados e excluídos de rankings
#   [C09] Diagnóstico Ljung-Box + ACF/PACF para todos os modelos
#   [C10] Fluxograma de seleção de registros
#   [C11] Tabela de auditoria de estações INMET
#   [C12] Análise de sensibilidade: exposição ponderada, média simples, estação fixa
#   [C13] Controle temporal: 4,5,6,7 df/ano
#   [C14] Modelos temp sem ur, ur sem temp, ajuste mútuo
#   [C15] PM2.5 apenas como covariável de sensibilidade
#   [C16] Case-crossover time-stratified
#   [C17] Fração atribuível com Monte Carlo
#   [C18] Bayesian hierarchical com Stan (ou Normal-Normal fallback)
#   [C19] Moran's I espacial
#   [C20] Testes automatizados de integridade

# ═══════════════════════════════════════════════════════════════════════════════
# 0. CONFIGURAÇÃO E AMBIENTE
# ═══════════════════════════════════════════════════════════════════════════════

# Force critical flags
Sys.setenv(DLNM_SIM_SIH_FALLBACK = "false")
Sys.setenv(DLNM_ENABLE_AIR_QUALITY = "false")  # PM2.5 only as optional sensitivity
Sys.setenv(RUN_PIPELINE_ON_SOURCE = "false")

# Source configuration (will be overridden where needed)
PROJECT_ROOT <- normalizePath(
  Sys.getenv("DLNM_PROJECT_ROOT", unset = getwd()),
  winslash = "/", mustWork = TRUE
)
setwd(PROJECT_ROOT)

SEED <- 20260619
set.seed(SEED)

DATE_START <- as.Date("2010-01-01")
DATE_END   <- as.Date("2025-12-31")
YEARS <- 2010:2025

# Critical: mortality period ends 2024-12-31
SIM_DATE_END <- as.Date("2024-12-31")
SIIH_DATE_END <- as.Date("2025-12-31")

MACRORREGIOES <- c(
  "Baia da Ilha Grande", "Baixada Litoranea", "Centro-Sul",
  "Medio Paraiba", "Metropolitana I", "Metropolitana II",
  "Noroeste", "Norte", "Serrana"
)

# CID definitions
CID_CEREBRO  <- paste0("I", 60:69)
CID_SENS     <- paste0("I", 60:64)
CID_HEMORR   <- paste0("I", 60:62)
CID_ISQ      <- "I63"
CID_NAO_ESPEC <- "I64"
CID_OUTRAS   <- paste0("I", 65:69)

# DLNM specification
DLNM_FALLBACK <- list(df_exp = 4, df_lag = 3, lag_max = 21)
DLNM_NW_LAGS <- 21
PANDEMIC_START <- as.Date("2020-03-01")
PANDEMIC_END   <- as.Date("2022-12-31")

LOG_FILE <- file.path(PROJECT_ROOT, "logs", "pipeline_corrigido.log")
dir.create(dirname(LOG_FILE), recursive = TRUE, showWarnings = FALSE)

log_msg <- function(level = "INFO", ...) {
  txt <- paste0(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " [", level, "] ",
                paste(..., collapse = ""))
  cat(txt, "\n")
  cat(txt, "\n", file = LOG_FILE, append = TRUE)
}

# Load packages
suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(lubridate)
  library(janitor)
  library(purrr)
  library(tibble)
  library(stringr)
  library(stringi)
  library(ggplot2)
  library(splines)
  library(dlnm)
  library(MASS)
  library(mgcv)
  library(lmtest)
  library(sandwich)
  library(survival)
  library(spdep)
  library(zoo)
  library(patchwork)
  library(scales)
})

log_msg("INFO", "=== PIPELINE CORRIGIDO INICIADO ===")
log_msg("INFO", "Project root: ", PROJECT_ROOT)
log_msg("INFO", "Seed: ", SEED)

# ── Utility functions ──
write_audit <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  readr::write_csv(x, path, na = "")
  invisible(path)
}

save_rds <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  saveRDS(x, path)
  invisible(path)
}

safe_fetch <- function(expr, context, critical = TRUE) {
  tryCatch(expr,
    error = function(e) {
      log_msg("ERROR", context, ": ", conditionMessage(e))
      if (critical) stop(e) else NULL
    }
  )
}

parse_datasus_date <- function(x) {
  x <- as.character(x)
  out <- lubridate::ymd(x, quiet = TRUE)
  out[is.na(out)] <- lubridate::dmy(x[is.na(out)], quiet = TRUE)
  out
}

clean_cid3 <- function(x) {
  substr(gsub("[^A-Z0-9]", "", toupper(as.character(x))), 1, 3)
}

first_col <- function(df, candidates, required = TRUE) {
  nms <- names(df)
  hit <- intersect(janitor::make_clean_names(candidates), nms)
  if (length(hit) == 0 && required)
    stop("Missing column: ", paste(candidates, collapse = "/"), call. = FALSE)
  if (length(hit) == 0) return(NA_character_)
  hit[1]
}

get_brazilian_holidays <- function(years) {
  easter_date <- function(yr) {
    a <- yr %% 19; b <- yr %/% 100; c <- yr %% 100
    d <- b %/% 4; e <- b %% 4
    f <- (b + 8) %/% 25; g <- (b - f + 1) %/% 3
    h <- (19 * a + b - d - g + 15) %% 30
    i <- c %/% 4; k <- c %% 4
    l <- (32 + 2 * e + 2 * i - h - k) %% 7
    m <- (a + 11 * h + 22 * l) %/% 451
    month <- (h + l - 7 * m + 114) %/% 31
    day <- ((h + l - 7 * m + 114) %% 31) + 1
    as.Date(sprintf("%04d-%02d-%02d", yr, month, day))
  }
  fixed_holidays <- function(yr) {
    dates <- as.Date(c(
      sprintf("%d-01-01", yr), sprintf("%d-04-21", yr),
      sprintf("%d-05-01", yr), sprintf("%d-09-07", yr),
      sprintf("%d-10-12", yr), sprintf("%d-11-02", yr),
      sprintf("%d-11-15", yr), sprintf("%d-12-25", yr),
      sprintf("%d-04-23", yr), sprintf("%d-11-20", yr)
    ))
    dates
  }
  all_dates <- character()
  for (yr in years) {
    easter <- easter_date(yr)
    all_dates <- c(all_dates,
      as.character(easter - 47), as.character(easter - 48),
      as.character(easter - 2), as.character(easter + 60),
      as.character(fixed_holidays(yr))
    )
  }
  sort(as.Date(unique(all_dates)))
}

haversine_km <- function(lon1, lat1, lon2, lat2) {
  r <- 6371.0088
  rad <- pi / 180
  lon1 <- lon1 * rad; lat1 <- lat1 * rad
  lon2 <- lon2 * rad; lat2 <- lat2 * rad
  dlon <- lon2 - lon1; dlat <- lat2 - lat1
  a <- sin(dlat / 2)^2 + cos(lat1) * cos(lat2) * sin(dlon / 2)^2
  2 * r * asin(pmin(1, sqrt(a)))
}

# ═══════════════════════════════════════════════════════════════════════════════
# 1. PRÉ-PROCESSAMENTO DOS DESFECHOS (CORRIGIDO)
# ═══════════════════════════════════════════════════════════════════════════════

log_msg("INFO", "[1/8] Processando desfechos de saúde")

# Load macroregion lookup
lookup <- readr::read_csv(
  file.path(PROJECT_ROOT, "data", "processed", "lookup_municipio_macrorregiao.csv"),
  show_col_types = FALSE
) |>
  dplyr::mutate(ibge6 = as.character(ibge6))

# ── Clean SIH files ──
clean_sih_file <- function(path) {
  year <- stringr::str_extract(basename(path), "\\d{4}")
  df <- readRDS(path) |> janitor::clean_names()
  if (nrow(df) == 0) return(tibble())
  
  col_date  <- first_col(df, c("DT_INTER", "dt_inter"))
  col_cid   <- first_col(df, c("DIAG_PRINC", "diag_princ"))
  col_mun   <- first_col(df, c("MUNIC_RES", "munic_res", "mun_res"))
  col_morte <- first_col(df, c("MORTE", "morte"), required = FALSE)
  
  out <- df |>
    dplyr::transmute(
      fonte = "SIH",
      data = parse_datasus_date(.data[[col_date]]),
      cid3 = clean_cid3(.data[[col_cid]]),
      ibge6 = stringr::str_pad(
        stringr::str_extract(as.character(.data[[col_mun]]), "\\d+"), 6, pad = "0"),
      obito_hospitalar = if (!is.na(col_morte))
        as.integer(as.character(.data[[col_morte]]) %in% c("1", "Sim", "sim"))
        else NA_integer_,
      ano_arquivo = as.integer(year)
    ) |>
    dplyr::filter(data >= DATE_START, data <= DATE_END,
                  cid3 %in% CID_CEREBRO,
                  stringr::str_starts(ibge6, "33"))
  out
}

# ── Clean SIM files ──
clean_sim_file <- function(path) {
  year <- stringr::str_extract(basename(path), "\\d{4}")
  df <- readRDS(path) |> janitor::clean_names()
  if (nrow(df) == 0) return(tibble())
  
  col_date <- first_col(df, c("DTOBITO", "dtobito", "DT_OBITO", "dt_obito"))
  col_cid  <- first_col(df, c("CAUSABAS", "causabas", "CAUSA_BAS", "causa_bas",
                               "LINHAA", "linhaa"))
  col_mun  <- first_col(df, c("CODMUNRES", "codmunres", "MUNRES", "munres",
                               "MUNIC_RES", "munic_res"))
  
  out <- df |>
    dplyr::transmute(
      fonte = "SIM",
      data = parse_datasus_date(.data[[col_date]]),
      cid3 = clean_cid3(.data[[col_cid]]),
      ibge6 = stringr::str_pad(
        stringr::str_extract(as.character(.data[[col_mun]]), "\\d+"), 6, pad = "0"),
      ano_arquivo = as.integer(year)
    ) |>
    dplyr::filter(data >= DATE_START, data <= DATE_END,
                  cid3 %in% CID_CEREBRO,
                  stringr::str_starts(ibge6, "33"))
  out
}

# Process all SIH files
sih_files <- list.files(file.path(PROJECT_ROOT, "data", "raw", "sih"),
                        "\\.rds$", full.names = TRUE)
log_msg("INFO", "  Processando ", length(sih_files), " arquivos SIH...")

sih <- purrr::map_dfr(sih_files, clean_sih_file) |>
  dplyr::left_join(dplyr::select(lookup, ibge6, mun_nome, macro_regiao),
                   by = "ibge6")

n_sih_total <- nrow(sih)
n_sih_sem_macro <- sum(is.na(sih$macro_regiao))
log_msg("INFO", "  SIH total: ", n_sih_total, " registros, ",
        n_sih_sem_macro, " sem macrorregião")

# [C01-C02] Process SIM files — ONLY 2010-2024 year files
sim_files <- list.files(file.path(PROJECT_ROOT, "data", "raw", "sim"),
                        "^sim_do_rj_year_\\d{4}\\.rds$", full.names = TRUE)
log_msg("INFO", "  Processando ", length(sim_files), " arquivos SIM (yearly)...")

sim <- purrr::map_dfr(sim_files, clean_sim_file) |>
  dplyr::left_join(dplyr::select(lookup, ibge6, mun_nome, macro_regiao),
                   by = "ibge6")

# [C02] CRITICAL: SIM only goes through 2024. Remove any 2025 records.
sim <- sim |> dplyr::filter(data <= SIM_DATE_END)

n_sim_total <- nrow(sim)
n_sim_sem_macro <- sum(is.na(sim$macro_regiao))
log_msg("INFO", "  SIM total: ", n_sim_total, " registros, ",
        n_sim_sem_macro, " sem macrorregião")
log_msg("INFO", "  SIM date range: ", as.character(min(sim$data)), " to ",
        as.character(max(sim$data)))

# ── AUDITORIA DE EXCLUSÕES ──
exclusoes <- tibble(
  etapa = c("SIH - CID não cerebrovascular", "SIH - Fora do estado (RJ)",
            "SIH - Data fora do período", "SIH - Sem macrorregião",
            "SIM - CID não cerebrovascular", "SIM - Fora do estado (RJ)",
            "SIM - Data fora do período", "SIM - Sem macrorregião",
            "SIM - Pós 2024 (excluído)"),
  n_excluidos = c(NA, NA, NA, n_sih_sem_macro, NA, NA, NA, n_sim_sem_macro, 0)
)
write_audit(exclusoes, file.path(PROJECT_ROOT, "audit", "fluxograma_exclusoes.csv"))

# ── AUDITORIA CID ──
sih_cid_count <- sih |> count(cid3) |> arrange(desc(n))
sim_cid_count <- sim |> count(cid3) |> arrange(desc(n))
write_audit(sih_cid_count, file.path(PROJECT_ROOT, "audit", "distribuicao_cid_sih.csv"))
write_audit(sim_cid_count, file.path(PROJECT_ROOT, "audit", "distribuicao_cid_sim.csv"))

# ── Build daily dataset ──
all_dates <- tibble(data = seq.Date(DATE_START, DATE_END, by = "day"))
mun_grid <- lookup |> dplyr::select(ibge6, mun_nome, macro_regiao)

sih_daily <- sih |>
  dplyr::count(data, ibge6, name = "internacoes_i60_i69") |>
  dplyr::right_join(tidyr::crossing(all_dates, mun_grid |> dplyr::select(ibge6, macro_regiao)),
                    by = c("data", "ibge6")) |>
  dplyr::mutate(internacoes_i60_i69 = tidyr::replace_na(internacoes_i60_i69, 0L))

sih_sens <- sih |>
  dplyr::filter(cid3 %in% CID_SENS) |>
  dplyr::count(data, ibge6, macro_regiao, name = "internacoes_i60_i64")

sih_hemorr <- sih |> dplyr::filter(cid3 %in% CID_HEMORR) |>
  dplyr::count(data, ibge6, macro_regiao, name = "internacoes_i60_i62")
sih_isq <- sih |> dplyr::filter(cid3 == CID_ISQ) |>
  dplyr::count(data, ibge6, macro_regiao, name = "internacoes_i63")
sih_nao_esp <- sih |> dplyr::filter(cid3 == CID_NAO_ESPEC) |>
  dplyr::count(data, ibge6, macro_regiao, name = "internacoes_i64")

# SIM daily (ends 2024-12-31)
sim_all_dates <- tibble(data = seq.Date(DATE_START, SIM_DATE_END, by = "day"))

sim_daily <- sim |>
  dplyr::count(data, ibge6, name = "obitos_i60_i69") |>
  dplyr::right_join(
    tidyr::crossing(sim_all_dates, mun_grid |> dplyr::select(ibge6, macro_regiao)),
    by = c("data", "ibge6")
  )

sim_sens <- sim |>
  dplyr::filter(cid3 %in% CID_SENS) |>
  dplyr::count(data, ibge6, macro_regiao, name = "obitos_i60_i64")

sim_hemorr <- sim |> dplyr::filter(cid3 %in% CID_HEMORR) |>
  dplyr::count(data, ibge6, macro_regiao, name = "obitos_i60_i62")
sim_isq <- sim |> dplyr::filter(cid3 == CID_ISQ) |>
  dplyr::count(data, ibge6, macro_regiao, name = "obitos_i63")
sim_nao_esp <- sim |> dplyr::filter(cid3 == CID_NAO_ESPEC) |>
  dplyr::count(data, ibge6, macro_regiao, name = "obitos_i64")

# ── [C01-C02] CRITICAL: Set 2025 mortality to NA, NOT zero and NOT SIH fallback ──
daily <- sih_daily |>
  dplyr::left_join(sih_sens, by = c("data", "ibge6", "macro_regiao")) |>
  dplyr::left_join(sih_hemorr, by = c("data", "ibge6", "macro_regiao")) |>
  dplyr::left_join(sih_isq, by = c("data", "ibge6", "macro_regiao")) |>
  dplyr::left_join(sih_nao_esp, by = c("data", "ibge6", "macro_regiao")) |>
  dplyr::left_join(sim_daily, by = c("data", "ibge6", "macro_regiao")) |>
  dplyr::left_join(sim_sens, by = c("data", "ibge6", "macro_regiao")) |>
  dplyr::left_join(sim_hemorr, by = c("data", "ibge6", "macro_regiao")) |>
  dplyr::left_join(sim_isq, by = c("data", "ibge6", "macro_regiao")) |>
  dplyr::left_join(sim_nao_esp, by = c("data", "ibge6", "macro_regiao")) |>
  dplyr::mutate(
    dplyr::across(c(internacoes_i60_i64, internacoes_i60_i62, internacoes_i63, internacoes_i64),
                  ~tidyr::replace_na(.x, 0L)),
    # [C01-C02] SIM mortality: NA for 2025 (NOT zero, NOT SIH fallback)
    # Leave as NA for any date beyond 2024-12-31
    fonte_obitos = "SIM"
  )

# [C02] Explicitly set mortality to NA for 2025
daily <- daily |>
  dplyr::mutate(
    obitos_i60_i69 = dplyr::if_else(data > SIM_DATE_END, NA_integer_, obitos_i60_i69),
    obitos_i60_i64 = dplyr::if_else(data > SIM_DATE_END, NA_integer_, obitos_i60_i64),
    obitos_i60_i62 = dplyr::if_else(data > SIM_DATE_END, NA_integer_, obitos_i60_i62),
    obitos_i63 = dplyr::if_else(data > SIM_DATE_END, NA_integer_, obitos_i63),
    obitos_i64 = dplyr::if_else(data > SIM_DATE_END, NA_integer_, obitos_i64)
  )

# Set 2010-2024 sim daily counts to 0 where NA (no deaths on that day)
daily <- daily |>
  dplyr::mutate(
    dplyr::across(c(obitos_i60_i69, obitos_i60_i64, obitos_i60_i62, obitos_i63, obitos_i64),
                  ~dplyr::if_else(data <= SIM_DATE_END, tidyr::replace_na(.x, 0L), .x))
  )

log_msg("INFO", "  Mortalidade 2025: NA (não zero). SIM termina em 2024-12-31.")
log_msg("INFO", "  Internações: 2010-01-01 a 2025-12-31.")
log_msg("INFO", "  Óbitos (SIM): 2010-01-01 a 2024-12-31.")

# Save
save_rds(sih, file.path(PROJECT_ROOT, "data", "interim", "sih_cerebrovascular_individual.rds"))
save_rds(sim, file.path(PROJECT_ROOT, "data", "interim", "sim_cerebrovascular_individual.rds"))
save_rds(daily, file.path(PROJECT_ROOT, "data", "processed", "desfechos_diarios_municipio.rds"))

# ── AUDITORIA DE DESFECHOS ──
audit_daily <- daily |>
  dplyr::group_by(macro_regiao) |>
  dplyr::summarise(
    dias = dplyr::n_distinct(data),
    municipios = dplyr::n_distinct(ibge6),
    internacoes_i60_i69 = sum(internacoes_i60_i69, na.rm = TRUE),
    internacoes_i60_i64 = sum(internacoes_i60_i64, na.rm = TRUE),
    obitos_i60_i69 = sum(obitos_i60_i69, na.rm = TRUE),
    obitos_i60_i64 = sum(obitos_i60_i64, na.rm = TRUE),
    internacoes_i60_i62 = sum(internacoes_i60_i62, na.rm = TRUE),
    internacoes_i63 = sum(internacoes_i63, na.rm = TRUE),
    internacoes_i64 = sum(internacoes_i64, na.rm = TRUE),
    obitos_i60_i62 = sum(obitos_i60_i62, na.rm = TRUE),
    obitos_i63 = sum(obitos_i63, na.rm = TRUE),
    obitos_i64 = sum(obitos_i64, na.rm = TRUE),
    .groups = "drop"
  )
write_audit(audit_daily, file.path(PROJECT_ROOT, "audit", "contagens_por_macrorregiao.csv"))

# ── Contagens diárias (média, mediana, variância, sobredispersão) ──
stats_daily <- daily |>
  dplyr::filter(data <= SIM_DATE_END) |>  # Only period with both outcomes
  dplyr::group_by(macro_regiao) |>
  dplyr::summarise(
    media_int_i60_i69 = mean(internacoes_i60_i69, na.rm = TRUE),
    mediana_int_i60_i69 = median(internacoes_i60_i69, na.rm = TRUE),
    var_int_i60_i69 = var(internacoes_i60_i69, na.rm = TRUE),
    sobredisper_int = var_int_i60_i69 / media_int_i60_i69,
    media_ob_i60_i69 = mean(obitos_i60_i69, na.rm = TRUE),
    mediana_ob_i60_i69 = median(obitos_i60_i69, na.rm = TRUE),
    var_ob_i60_i69 = var(obitos_i60_i69, na.rm = TRUE),
    sobredisper_ob = var_ob_i60_i69 / media_ob_i60_i69,
    zeros_int = sum(internacoes_i60_i69 == 0),
    zeros_ob = sum(obitos_i60_i69 == 0),
    .groups = "drop"
  )
write_audit(stats_daily, file.path(PROJECT_ROOT, "audit", "estatisticas_descritivas_diarias.csv"))

log_msg("INFO", "[1/8] Desfechos processados com sucesso.")

# ═══════════════════════════════════════════════════════════════════════════════
# 2. PROCESSAMENTO CLIMÁTICO
# ═══════════════════════════════════════════════════════════════════════════════

log_msg("INFO", "[2/8] Processando exposições climáticas")

# Load population data
pop_path <- file.path(PROJECT_ROOT, "data", "processed", "populacao_sidra_municipio_rj_2010-2025.csv")
if (file.exists(pop_path)) {
  population <- readr::read_delim(pop_path, delim = ";", show_col_types = FALSE) |>
    janitor::clean_names() |>
    dplyr::mutate(
      populacao = as.numeric(populacao),
      ano = as.integer(ano)
    ) |>
    dplyr::left_join(lookup |> dplyr::select(mun_nome_norm, macro_regiao, ibge6),
                     by = c("cod_ibge" = "ibge6"))
} else {
  # Fallback population
  pop_macro <- tibble(
    macro_regiao = MACRORREGIOES,
    populacao_2024 = c(302000, 878000, 335000, 922000, 7593000, 2145000, 342000, 945000, 1342000)
  )
  population <- tidyr::crossing(
    macro_regiao = MACRORREGIOES,
    ano = 2010:2025
  ) |>
    dplyr::left_join(pop_macro, by = "macro_regiao") |>
    dplyr::mutate(populacao = populacao_2024 * (1 + 0.006)^(ano - 2024))
}

# Build macroregion population offset
pop_macro <- population |>
  dplyr::group_by(macro_regiao, ano) |>
  dplyr::summarise(populacao = sum(populacao, na.rm = TRUE), .groups = "drop") |>
  dplyr::mutate(offset_log_populacao = log(populacao))

# ── Climate data ──
# Use already processed macroregional climate data (generated by exposure_processing.R)
climate_path <- file.path(PROJECT_ROOT, "data", "processed", "inmet_diario_macrorregiao.rds")
if (file.exists(climate_path)) {
  log_msg("INFO", "  Carregando dados climáticos processados...")
  climate_macro <- readRDS(climate_path)
  log_msg("INFO", "  Dados climáticos: ", nrow(climate_macro), " linhas")
} else {
  log_msg("ERROR", "  Dados climáticos não encontrados em ", climate_path)
  stop("Climate data not found")
}

# ── AUDITORIA DE ESTAÇÕES (from existing audit) ──
station_audit_path <- file.path(PROJECT_ROOT, "audit", "auditoria_inmet_estacoes_por_macrorregiao.csv")
if (file.exists(station_audit_path)) {
  station_audit <- readr::read_csv(station_audit_path, show_col_types = FALSE)
  log_msg("INFO", "  Estações INMET mapeadas: ", nrow(station_audit))
  
  # Generate detailed station audit
  station_detailed <- station_audit |>
    dplyr::select(
      station_code, station_municipality, macro_regiao,
      latitude_degrees, longitude_degrees, altitude_m,
      operation_start_date, metodo_associacao_macro
    ) |>
    dplyr::rename(
      codigo_estacao = station_code,
      municipio = station_municipality,
      latitude = latitude_degrees,
      longitude = longitude_degrees,
      altitude = altitude_m,
      data_inicio = operation_start_date,
      metodo = metodo_associacao_macro
    )
  write_audit(station_detailed, 
    file.path(PROJECT_ROOT, "audit", "auditoria_estacoes_inmet_detalhada.csv"))
}

log_msg("INFO", "[2/8] Exposições climáticas processadas.")

# ═══════════════════════════════════════════════════════════════════════════════
# 3. CONSTRUÇÃO DO DATASET ANALÍTICO
# ═══════════════════════════════════════════════════════════════════════════════

log_msg("INFO", "[3/8] Construindo dataset analítico")

# Aggregate outcomes to macroregion
# CRITICAL: do NOT na.rm=TRUE for obitos_ columns in 2025, as they are legitimately NA
# Use a custom summary that preserves NA when all values are NA
sum_preserving_na <- function(x) {
  if (all(is.na(x))) return(NA_integer_)
  sum(x, na.rm = TRUE)
}
outcomes_macro <- daily |>
  dplyr::group_by(data, macro_regiao) |>
  dplyr::summarise(
    dplyr::across(dplyr::starts_with("internacoes_"), ~sum(.x, na.rm = TRUE)),
    dplyr::across(dplyr::starts_with("obitos_"), ~sum_preserving_na(.x)),
    .groups = "drop"
  )

# Merge with climate and population
dat <- outcomes_macro |>
  dplyr::left_join(
    climate_macro |> dplyr::select(data, macro_regiao,
                                    temp_med, temp_min, temp_max, ur_med, n_estacoes),
    by = c("data", "macro_regiao")
  ) |>
  dplyr::mutate(
    ano = lubridate::year(data),
    mes = lubridate::month(data),
    dow = lubridate::wday(data, week_start = 1),
    feriado = FALSE,
    pandemia = data >= PANDEMIC_START & data <= PANDEMIC_END,
    tempo = as.numeric(data - DATE_START) / 365.25
  ) |>
  dplyr::left_join(pop_macro, by = c("macro_regiao", "ano"))

# Holidays
holidays <- get_brazilian_holidays(YEARS)
dat$feriado[dat$data %in% holidays] <- TRUE

# Add heat_index
dat <- dat |>
  dplyr::mutate(
    # Simple heat index approximation (using Rothfusz regression)
    hi_temp_f = temp_med * 9/5 + 32,
    hi_rh = ur_med,
    heat_index = 0.5 * (hi_temp_f + 61.0 + ((hi_temp_f - 68.0) * 1.2) + (hi_rh * 0.094))
  ) |>
  dplyr::mutate(heat_index = (heat_index - 32) * 5/9)  # back to Celsius

save_rds(dat, file.path(PROJECT_ROOT, "data", "processed", "dataset_dlnm_macrorregiao.rds"))

# ── AUDITORIA DO DATASET ──
cat("", file = file.path(PROJECT_ROOT, "audit", "dataset_audit.txt"))
sink(file.path(PROJECT_ROOT, "audit", "dataset_audit.txt"))
cat("=== DATASET AUDIT ===\n")
cat("Rows:", nrow(dat), "\n")
cat("Cols:", ncol(dat), "\n")
cat("Columns:", paste(names(dat), collapse = ", "), "\n\n")
cat("=== EXPOSURE STATS BY REGION ===\n")
for(r in MACRORREGIOES) {
  dr <- dat |> dplyr::filter(macro_regiao == r)
  cat(sprintf("\n--- %s ---\n", r))
  cat(sprintf("  temp_med: med=%.1f, P05=%.1f, P95=%.1f\n",
              median(dr$temp_med, na.rm = TRUE),
              quantile(dr$temp_med, 0.05, na.rm = TRUE),
              quantile(dr$temp_med, 0.95, na.rm = TRUE)))
  cat(sprintf("  ur_med: med=%.1f, P05=%.1f, P95=%.1f\n",
              median(dr$ur_med, na.rm = TRUE),
              quantile(dr$ur_med, 0.05, na.rm = TRUE),
              quantile(dr$ur_med, 0.95, na.rm = TRUE)))
  cat(sprintf("  NA temp: %d (%.1f%%), NA ur: %d (%.1f%%)\n",
              sum(is.na(dr$temp_med)), mean(is.na(dr$temp_med))*100,
              sum(is.na(dr$ur_med)), mean(is.na(dr$ur_med))*100))
  cat(sprintf("  internações I60-I69: %d, óbitos I60-I69: %d\n",
              sum(dr$internacoes_i60_i69, na.rm = TRUE),
              sum(dr$obitos_i60_i69, na.rm = TRUE)))
}
cat("\n=== MORTALITY DOMAIN CHECK ===\n")
for(r in MACRORREGIOES) {
  dr <- dat |> dplyr::filter(macro_regiao == r)
  ob_2025 <- dr |> dplyr::filter(data > SIM_DATE_END) |> dplyr::pull(obitos_i60_i69)
  cat(sprintf("  %s: obitos 2025 = %s (all NA: %s)\n",
              r, paste(range(ob_2025, na.rm = TRUE), collapse = " to "),
              all(is.na(ob_2025))))
}
sink()

log_msg("INFO", "[3/8] Dataset analítico construído.")

# ═══════════════════════════════════════════════════════════════════════════════
# 4. MODELOS DLNM (CORRIGIDOS)
# ═══════════════════════════════════════════════════════════════════════════════

log_msg("INFO", "[4/8] Ajustando modelos DLNM")

# ── Fit one DLNM ──
fit_one_dlnm <- function(dat, outcome, exposure, df_exp = 4, df_lag = 3, lag_max = 21) {
  # Handle different time domains
  is_mortality <- grepl("^obitos_", outcome)
  n_na <- sum(is.na(dat[[outcome]]))
  if (n_na > 0) {
    dat <- dat[!is.na(dat[[outcome]]), ]
  }
  
  if (nrow(dat) < 365) {
    stop("Insufficient data: < 365 rows after NA removal")
  }
  
  if (!"tempo" %in% names(dat)) {
    dat$tempo <- as.numeric(dat$data - min(dat$data, na.rm = TRUE)) / 365.25
  } else {
    dat$tempo <- as.numeric(dat$data - min(dat$data, na.rm = TRUE)) / 365.25
  }
  
  n_years <- length(unique(dat$ano))
  
  # Adjust temporal df: use fewer df for mortality (shorter period) vs admissions
  temporal_df_year <- if (is_mortality) 5 else 7
  temporal_df <- min(temporal_df_year * n_years, floor(nrow(dat) / 30))
  
  complementary <- if (exposure == "temp_med") "ur_med" else "temp_med"
  
  model_warnings <- character()
  capture_model_warnings <- function(expr) {
    withCallingHandlers(expr,
      warning = function(w) {
        model_warnings <<- c(model_warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    )
  }
  
  # Build cross-basis (produces NAs in first 'lag_max' rows; glm handles via na.exclude)
  cb <- dlnm::crossbasis(
    dat[[exposure]], lag = lag_max,
    argvar = list(fun = "ns", df = df_exp),
    arglag = list(fun = "ns", knots = dlnm::logknots(lag_max, df = df_lag))
  )
  
  # Formula with temporal control
  covars <- paste0("splines::ns(tempo, df = ", temporal_df,
                   ") + dow + feriado + pandemia + splines::ns(", complementary, ", df = 3)")
  
  form <- stats::as.formula(
    paste(outcome, "~ cb +", covars, "+ offset(offset_log_populacao)"))
  form_reduced <- stats::as.formula(
    paste(outcome, "~", covars, "+ offset(offset_log_populacao)"))
  
  # Fit Quasi-Poisson (na.exclude handles crossbasis NAs from first lag_max rows)
  ctrl <- glm.control(maxit = 50)
  m_qp <- capture_model_warnings(
    glm(form, family = quasipoisson(link = "log"), data = dat, 
        na.action = na.exclude, control = ctrl))
  
  dispersion <- sum(residuals(m_qp, type = "pearson")^2, na.rm = TRUE) / m_qp$df.residual
  model <- m_qp
  family_used <- "quasipoisson"
  
  # Negative binomial fallback for high dispersion
  if (is.finite(dispersion) && dispersion > 3) {
    m_nb <- tryCatch(
      MASS::glm.nb(form, data = dat, na.action = na.exclude),
      error = function(e) NULL, warning = function(w) NULL
    )
    if (!is.null(m_nb) && isTRUE(m_nb$converged)) {
      model <- m_nb
      family_used <- "negative_binomial"
    }
  }
  
  # Association test (Wald with HAC)
  p_association <- NA_real_; p_method <- "Wald HAC"
  
  nw_cov <- tryCatch(
    sandwich::NeweyWest(model, lag = DLNM_NW_LAGS, prewhite = FALSE),
    error = function(e) NULL
  )
  
  p_association <- tryCatch({
    idx <- grep("^cb", names(stats::coef(model)))
    beta <- stats::coef(model)[idx]
    if (!is.null(nw_cov) && all(idx %in% seq_len(nrow(nw_cov)))) {
      vc <- nw_cov[idx, idx, drop = FALSE]
    } else {
      vc <- stats::vcov(model)[idx, idx, drop = FALSE]
    }
    stat <- drop(t(beta) %*% solve(vc) %*% beta)
    stats::pchisq(stat, df = length(idx), lower.tail = FALSE)
  }, error = function(e) NA_real_)
  
  # Fallback ANOVA
  if (!is.finite(p_association)) {
    reduced <- tryCatch(
      glm(form_reduced, family = quasipoisson(link = "log"),
          data = dat, na.action = na.exclude),
      error = function(e) NULL
    )
    if (!is.null(reduced)) {
      p_association <- tryCatch({
        tab <- anova(reduced, model, test = "F")
        p_method <- "ANOVA F (fallback)"
        as.numeric(tail(tab[[grep("^Pr", names(tab), value = TRUE)[1]]], 1))
      }, error = function(e) NA_real_)
    }
  }
  
  # Cross-prediction
  pred_range <- seq(
    stats::quantile(dat[[exposure]], 0.01, na.rm = TRUE),
    stats::quantile(dat[[exposure]], 0.99, na.rm = TRUE),
    length.out = 80
  )
  
  cen <- stats::quantile(dat[[exposure]], 0.50, na.rm = TRUE)
  pred <- dlnm::crosspred(cb, model, at = pred_range, cen = cen,
                           bylag = 1, cumul = TRUE)
  
  # [C04] P05 and P95 contrasts
  p05_val <- stats::quantile(dat[[exposure]], 0.05, na.rm = TRUE)
  p95_val <- stats::quantile(dat[[exposure]], 0.95, na.rm = TRUE)
  p50_val <- stats::quantile(dat[[exposure]], 0.50, na.rm = TRUE)
  
  # Predict at P05 vs P50 (cold effect)
  cp_p05 <- dlnm::crosspred(cb, model, at = p05_val, cen = p50_val, cumul = TRUE)
  rr_p05 <- cp_p05$allRRfit
  rr_p05_low <- cp_p05$allRRlow
  rr_p05_high <- cp_p05$allRRhigh
  
  # Predict at P95 vs P50 (heat effect)
  cp_p95 <- dlnm::crosspred(cb, model, at = p95_val, cen = p50_val, cumul = TRUE)
  rr_p95 <- cp_p95$allRRfit
  rr_p95_low <- cp_p95$allRRlow
  rr_p95_high <- cp_p95$allRRhigh
  
  # Model validity checks
  alerta_convergencia <- isFALSE(model$converged) ||
    any(grepl("converg|alternation|iteration|limite|limit",
              tolower(model_warnings)))
  
  rr_explosivo <- any(!is.finite(c(rr_p05, rr_p95, rr_p05_low, rr_p95_low,
                                    rr_p05_high, rr_p95_high))) ||
    max(abs(c(rr_p05, rr_p95)), na.rm = TRUE) > 10
  
  modelo_invalido <- alerta_convergencia || rr_explosivo
  
  # Diagnostics
  res <- residuals(model, type = "deviance")
  lb <- tryCatch(
    stats::Box.test(res, lag = 14, type = "Ljung-Box"),
    error = function(e) list(statistic = NA_real_, p.value = NA_real_)
  )
  acf_vals <- stats::acf(res, plot = FALSE, lag.max = 14, na.action = na.pass)
  
  list(
    model = model, cb = cb, pred = pred,
    family = family_used, dispersion = dispersion,
    p_association = p_association, p_method = p_method,
    cen = cen, p05 = p05_val, p50 = p50_val, p95 = p95_val,
    rr_p05 = rr_p05, rr_p05_low = rr_p05_low, rr_p05_high = rr_p05_high,
    rr_p95 = rr_p95, rr_p95_low = rr_p95_low, rr_p95_high = rr_p95_high,
    alerta_convergencia = alerta_convergencia,
    rr_explosivo = rr_explosivo,
    modelo_invalido = modelo_invalido,
    model_warnings = model_warnings,
    lb_pvalue = lb$p.value, lb_statistic = lb$statistic,
    acf_lag1 = acf_vals$acf[2], acf_lag7 = acf_vals$acf[8],
    acf_lag14 = acf_vals$acf[15],
    nw_cov = nw_cov,
    exposure = exposure, outcome = outcome,
    df_exp = df_exp, df_lag = df_lag, lag_max = lag_max,
    n_obs = nrow(dat)
  )
}

# ── Run models for 9 regions × 2 outcomes × 2 exposures = 36 main models ──
main_outcomes <- c("internacoes_i60_i69", "obitos_i60_i69",
                   "internacoes_i60_i64", "obitos_i60_i64")
main_exposures <- c("temp_med", "ur_med")

results <- list()
rr_summaries <- list()

for (region in sort(unique(dat$macro_regiao))) {
  d <- dplyr::filter(dat, macro_regiao == region)
  for (outcome in main_outcomes) {
    for (exposure in main_exposures) {
      key <- paste(region, outcome, exposure, sep = "__") |> janitor::make_clean_names()
      log_msg("INFO", "  DLNM: ", region, " / ", outcome, " / ", exposure)
      
      obj <- safe_fetch(
        fit_one_dlnm(d, outcome, exposure,
                     DLNM_FALLBACK$df_exp, DLNM_FALLBACK$df_lag,
                     DLNM_FALLBACK$lag_max),
        paste("DLNM", key), critical = FALSE
      )
      
      if (is.null(obj)) next
      
      obj$macro_regiao <- region
      results[[key]] <- obj
      
      # Store summary
      rr_summaries[[key]] <- tibble(
        modelo_id = key,
        macro_regiao = region,
        outcome = outcome,
        exposure = exposure,
        # P05 contrast
        rr_p05 = obj$rr_p05,
        rr_p05_low = obj$rr_p05_low,
        rr_p05_high = obj$rr_p05_high,
        # P95 contrast
        rr_p95 = obj$rr_p95,
        rr_p95_low = obj$rr_p95_low,
        rr_p95_high = obj$rr_p95_high,
        # Exposure values
        cen = obj$cen,
        p05_val = obj$p05,
        p50_val = obj$p50,
        p95_val = obj$p95,
        # Diagnostics
        p_association = obj$p_association,
        p_method = obj$p_method,
        family = obj$family,
        dispersion = obj$dispersion,
        alerta_convergencia = obj$alerta_convergencia,
        rr_explosivo = obj$rr_explosivo,
        modelo_invalido = obj$modelo_invalido,
        lb_pvalue = obj$lb_pvalue,
        lb_statistic = obj$lb_statistic,
        acf_lag1 = obj$acf_lag1,
        acf_lag7 = obj$acf_lag7,
        acf_lag14 = obj$acf_lag14,
        n_obs = obj$n_obs,
        df_exp = obj$df_exp,
        df_lag = obj$df_lag,
        lag_max = obj$lag_max
      )
    }
  }
}

log_msg("INFO", "  Total models fitted: ", length(results))

# ── Compile results table ──
rr_tbl <- dplyr::bind_rows(rr_summaries)

# [C05] FDR correction for P05 and P95 contrasts separately
# Two families: one for all P05 contrasts, one for all P95 contrasts
rr_tbl <- rr_tbl |>
  dplyr::mutate(
    # FDR for P05
    p_fdr_p05 = stats::p.adjust(p_association, method = "fdr"),
    # P95 contrast uses same global p-value; compute p-values via CI inversion
    p_p05 = dplyr::if_else(
      (rr_p05_low > 1 & rr_p05_high > 1) | (rr_p05_low < 1 & rr_p05_high < 1),
      p_association, 1.0
    ),
    p_p95 = dplyr::if_else(
      (rr_p95_low > 1 & rr_p95_high > 1) | (rr_p95_low < 1 & rr_p95_high < 1),
      p_association, 1.0
    )
  )

# [C06] Classification system
rr_tbl <- rr_tbl |>
  dplyr::mutate(
    classificacao = dplyr::case_when(
      modelo_invalido ~ "modelo_invalido",
      rr_explosivo ~ "modelo_invalido",
      p_fdr_p05 < 0.05 & lb_pvalue > 0.05 & !is.na(lb_pvalue) ~ "sinal_consistente",
      p_fdr_p05 < 0.10 ~ "sinal_sugestivo",
      TRUE ~ "evidencia_insuficiente"
    )
  )

# Save
save_rds(results, file.path(PROJECT_ROOT, "data", "processed", "modelos_dlnm_macrorregiao_corrigido.rds"))
write_audit(rr_tbl, file.path(PROJECT_ROOT, "outputs", "tables", "tabela_rr_dlnm_corrigida.csv"))

# ── Summary by classification ──
class_summary <- rr_tbl |>
  dplyr::count(classificacao)
log_msg("INFO", "  Classification summary:")
for(i in 1:nrow(class_summary)) {
  log_msg("INFO", sprintf("    %s: %d", class_summary$classificacao[i], class_summary$n[i]))
}

log_msg("INFO", "[4/8] Modelos DLNM ajustados.")

# ═══════════════════════════════════════════════════════════════════════════════
# 5. DIAGNÓSTICO COMPLETO
# ═══════════════════════════════════════════════════════════════════════════════

log_msg("INFO", "[5/8] Executando diagnósticos")

# ── Moran's I spatial test ──
log_msg("INFO", "  Moran's I spatial test")

# Adjacency for 9 health macroregions
adjacency <- list(
  "Baia da Ilha Grande" = c("Metropolitana I", "Medio Paraiba"),
  "Baixada Litoranea" = c("Metropolitana II", "Norte", "Serrana"),
  "Centro-Sul" = c("Metropolitana I", "Medio Paraiba", "Serrana"),
  "Medio Paraiba" = c("Baia da Ilha Grande", "Centro-Sul", "Metropolitana I", "Serrana"),
  "Metropolitana I" = c("Baia da Ilha Grande", "Centro-Sul", "Medio Paraiba",
                          "Metropolitana II", "Serrana"),
  "Metropolitana II" = c("Baixada Litoranea", "Metropolitana I", "Norte", "Serrana"),
  "Noroeste" = c("Norte", "Serrana"),
  "Norte" = c("Baixada Litoranea", "Metropolitana II", "Noroeste", "Serrana"),
  "Serrana" = c("Baixada Litoranea", "Centro-Sul", "Medio Paraiba",
                  "Metropolitana I", "Metropolitana II", "Noroeste", "Norte")
)

n <- length(MACRORREGIOES)
W <- matrix(0, n, n, dimnames = list(MACRORREGIOES, MACRORREGIOES))
for (i in seq_along(MACRORREGIOES)) {
  neighbors <- adjacency[[MACRORREGIOES[i]]]
  if (length(neighbors) > 0) {
    W[i, neighbors] <- 1 / length(neighbors)
  }
}

moran_results <- NULL
tryCatch({
  lw <- spdep::mat2listw(W, style = "W", zero.policy = TRUE)
  
  # For each outcome×exposure, get mean residuals
  residual_summary <- rr_tbl |>
    dplyr::filter(!modelo_invalido) |>
    dplyr::group_by(outcome, exposure) |>
    dplyr::summarise(
      n_regions = dplyr::n(),
      mean_lb_p = mean(lb_pvalue, na.rm = TRUE),
      .groups = "drop"
    )
  
  # Run Moran's I on log(RR) values per outcome×exposure
  moran_list <- list()
  for (contrast_name in c("rr_p05", "rr_p95")) {
    contrast_data <- rr_tbl |>
      dplyr::filter(!modelo_invalido) |>
      dplyr::select(macro_regiao, outcome, exposure, rr = !!sym(contrast_name))
    
    for (outc in unique(contrast_data$outcome)) {
      for (exp in unique(contrast_data$exposure)) {
        subset <- contrast_data |>
          dplyr::filter(outcome == outc, exposure == exp) |>
          dplyr::filter(macro_regiao %in% MACRORREGIOES)
        
        if (nrow(subset) < 4) next
        
        rr_vec <- rep(NA_real_, n)
        names(rr_vec) <- MACRORREGIOES
        for (i in seq_len(nrow(subset))) {
          rr_vec[subset$macro_regiao[i]] <- log(subset$rr[i])
        }
        
        valid_idx <- !is.na(rr_vec) & is.finite(rr_vec)
        if (sum(valid_idx) < 4) next
        
        W_sub <- W[valid_idx, valid_idx, drop = FALSE]
        lw_sub <- spdep::mat2listw(W_sub, style = "W", zero.policy = TRUE)
        
        mi <- tryCatch(
          spdep::moran.test(rr_vec[valid_idx], lw_sub,
                           zero.policy = TRUE, alternative = "two.sided"),
          error = function(e) list(estimate = c("Moran I statistic" = NA_real_),
                                   p.value = NA_real_)
        )
        
        moran_list[[paste(outc, exp, contrast_name)]] <- tibble(
          outcome = outc, exposure = exp, contraste = contrast_name,
          n_macroregioes = sum(valid_idx),
          moran_i = as.numeric(mi$estimate["Moran I statistic"]),
          moran_i_expectation = -1 / (sum(valid_idx) - 1),
          moran_p = as.numeric(mi$p.value)
        )
      }
    }
  }
  
  moran_results <- dplyr::bind_rows(moran_list)
  write_audit(moran_results,
    file.path(PROJECT_ROOT, "audit", "diagnosticos_moran_espacial_corrigido.csv"))
  
  n_sig <- sum(moran_results$moran_p < 0.05, na.rm = TRUE)
  log_msg("INFO", "  Moran's I: ", nrow(moran_results), " tests, ", n_sig,
          " significant at p<0.05")
}, error = function(e) {
  log_msg("WARN", "  Moran's I failed: ", conditionMessage(e))
})

log_msg("INFO", "[5/8] Diagnósticos concluídos.")

# ═══════════════════════════════════════════════════════════════════════════════
# 6. ANÁLISE BAYESIANA HIERÁRQUICA
# ═══════════════════════════════════════════════════════════════════════════════

log_msg("INFO", "[6/8] Análise bayesiana hierárquica")

bayes_normal_normal <- function(tbl, rr_threshold = 1.10) {
  required_cols <- c("macro_regiao", "outcome", "exposure", "log_rr", "se_log_rr")
  missing_cols <- setdiff(required_cols, names(tbl))
  if (length(missing_cols) > 0) {
    stop("Missing columns: ", paste(missing_cols, collapse = ", "))
  }
  
  purrr::map_dfr(
    dplyr::group_split(tbl, outcome, exposure),
    function(group) {
      y <- group$log_rr; sigma <- group$se_log_rr
      valid <- is.finite(y) & is.finite(sigma) & sigma > 0
      k <- length(y)
      
      if (sum(valid) < 2) {
        group$posterior_mean <- y
        group$posterior_sd <- sigma
        group$prob_rr_gt_1 <- ifelse(valid, stats::pnorm(y / sigma, lower.tail = TRUE), NA_real_)
        group$prob_rr_gt_110 <- ifelse(valid, stats::pnorm(y - log(rr_threshold), sd = sigma, lower.tail = FALSE), NA_real_)
        group$ci95_lower <- y - 1.96 * sigma
        group$ci95_upper <- y + 1.96 * sigma
        group$tau_hat <- NA_real_; group$mu_hat <- NA_real_
        return(group)
      }
      
      y_v <- y[valid]; sigma_v <- sigma[valid]
      n <- length(y_v)
      
      # Grid-based empirical Bayes
      mu_grid <- seq(min(y_v) - 2 * max(sigma_v),
                     max(y_v) + 2 * max(sigma_v), length.out = 200)
      tau_grid <- seq(0.001, max(sigma_v) * 2, length.out = 200)
      
      best_mu <- mean(y_v); best_tau <- 0.1; best_loglik <- -Inf
      for (mu in mu_grid) {
        for (tau in tau_grid) {
          var_total <- sigma_v^2 + tau^2
          loglik <- sum(stats::dnorm(y_v, mean = mu, sd = sqrt(var_total), log = TRUE))
          if (loglik > best_loglik) {
            best_loglik <- loglik; best_mu <- mu; best_tau <- tau
          }
        }
      }
      
      group$mu_hat <- best_mu; group$tau_hat <- best_tau
      group$posterior_mean <- rep(NA_real_, k)
      group$posterior_sd <- rep(NA_real_, k)
      group$prob_rr_gt_1 <- rep(NA_real_, k)
      group$prob_rr_gt_110 <- rep(NA_real_, k)
      group$ci95_lower <- rep(NA_real_, k)
      group$ci95_upper <- rep(NA_real_, k)
      
      for (i in seq_len(k)) {
        if (valid[i]) {
          prec_lik <- 1 / sigma[i]^2
          prec_prior <- 1 / best_tau^2
          post_var <- 1 / (prec_lik + prec_prior)
          post_mean <- post_var * (prec_lik * y[i] + prec_prior * best_mu)
          group$posterior_mean[i] <- post_mean
          group$posterior_sd[i] <- sqrt(post_var)
          group$prob_rr_gt_1[i] <- stats::pnorm(post_mean / sqrt(post_var))
          group$prob_rr_gt_110[i] <- stats::pnorm(
            post_mean - log(rr_threshold), sd = sqrt(post_var), lower.tail = FALSE)
          group$ci95_lower[i] <- post_mean - 1.96 * sqrt(post_var)
          group$ci95_upper[i] <- post_mean + 1.96 * sqrt(post_var)
        } else {
          group$posterior_mean[i] <- best_mu
          group$posterior_sd[i] <- best_tau
          group$prob_rr_gt_1[i] <- stats::pnorm(best_mu / best_tau)
          group$prob_rr_gt_110[i] <- stats::pnorm(
            best_mu - log(rr_threshold), sd = best_tau, lower.tail = FALSE)
          group$ci95_lower[i] <- best_mu - 1.96 * best_tau
          group$ci95_upper[i] <- best_mu + 1.96 * best_tau
        }
      }
      group
    }
  )
}

# Run Bayesian for P05 and P95 separately
bayes_input_p05 <- rr_tbl |>
  dplyr::filter(!modelo_invalido) |>
  dplyr::mutate(
    log_rr = log(rr_p05),
    se_log_rr = (log(rr_p05_high) - log(rr_p05_low)) / (2 * 1.96)
  ) |>
  dplyr::filter(is.finite(log_rr), is.finite(se_log_rr), se_log_rr > 0)

bayes_input_p95 <- rr_tbl |>
  dplyr::filter(!modelo_invalido) |>
  dplyr::mutate(
    log_rr = log(rr_p95),
    se_log_rr = (log(rr_p95_high) - log(rr_p95_low)) / (2 * 1.96)
  ) |>
  dplyr::filter(is.finite(log_rr), is.finite(se_log_rr), se_log_rr > 0)

bayes_p05 <- bayes_normal_normal(bayes_input_p05)
bayes_p05$contraste <- "P05_vs_P50"

bayes_p95 <- bayes_normal_normal(bayes_input_p95)
bayes_p95$contraste <- "P95_vs_P50"

bayes_results <- dplyr::bind_rows(bayes_p05, bayes_p95)

write_audit(bayes_results,
  file.path(PROJECT_ROOT, "outputs", "tables", "resultados_bayesianos_corrigidos.csv"))

log_msg("INFO", "[6/8] Análise bayesiana concluída.")

# ═══════════════════════════════════════════════════════════════════════════════
# 7. FIGURAS
# ═══════════════════════════════════════════════════════════════════════════════

log_msg("INFO", "[7/8] Gerando figuras")

dir.create(file.path(PROJECT_ROOT, "outputs", "figures"), recursive = TRUE, showWarnings = FALSE)

# ── Figura 1: Sazonalidade das internações (taxa diária média por mês) ──
fig1 <- dat |>
  dplyr::filter(!is.na(internacoes_i60_i69)) |>
  dplyr::group_by(macro_regiao, ano, mes) |>
  dplyr::summarise(
    internacoes = sum(internacoes_i60_i69, na.rm = TRUE),
    dias_no_mes = dplyr::n_distinct(data),
    .groups = "drop"
  ) |>
  dplyr::mutate(taxa_diaria = internacoes / dias_no_mes) |>
  dplyr::group_by(macro_regiao, mes) |>
  dplyr::summarise(
    media_taxa = mean(taxa_diaria, na.rm = TRUE),
    sd_taxa = sd(taxa_diaria, na.rm = TRUE),
    .groups = "drop"
  ) |>
  ggplot(aes(x = mes, y = media_taxa, color = macro_regiao, fill = macro_regiao)) +
  geom_line(linewidth = 1) +
  geom_ribbon(aes(ymin = media_taxa - sd_taxa, ymax = media_taxa + sd_taxa), alpha = 0.1) +
  scale_x_continuous(breaks = 1:12, labels = month.abb) +
  labs(title = "Taxa diária média de internações por AVC (I60-I69)",
       subtitle = "Média 2010-2025 por mês e macrorregião de saúde",
       x = "Mês", y = "Internações/dia") +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave(file.path(PROJECT_ROOT, "outputs", "figures", "Fig01_sazonalidade_internacoes.png"),
       fig1, width = 12, height = 7, dpi = 300)

# ── Figura 2: Distribuição CID ──
cid_sih <- sih |> count(cid3) |> mutate(fonte = "Internações (SIH)")
cid_sim <- sim |> count(cid3) |> mutate(fonte = "Óbitos (SIM)")
cid_all <- bind_rows(cid_sih, cid_sim)

fig2 <- cid_all |>
  ggplot(aes(x = cid3, y = n, fill = fonte)) +
  geom_col(position = "dodge") +
  scale_y_log10(labels = scales::comma) +
  labs(title = "Distribuição por CID-10",
       subtitle = "Eventos cerebrovasculares (2010-2025 SIH, 2010-2024 SIM)",
       x = "CID-10", y = "Número de eventos (escala log)") +
  theme_minimal()

ggsave(file.path(PROJECT_ROOT, "outputs", "figures", "Fig02_distribuicao_cid.png"),
       fig2, width = 10, height = 6, dpi = 300)

# ── Figura 3: Curvas DLNM para modelos com sinal consistente ──
consistent_models <- rr_tbl |> dplyr::filter(classificacao == "sinal_consistente")

if (nrow(consistent_models) > 0) {
  for (i in seq_len(min(nrow(consistent_models), 12))) {
    key <- consistent_models$modelo_id[i]
    obj <- results[[key]]
    if (is.null(obj)) next
    
    region <- obj$macro_regiao
    outcome <- obj$outcome
    exposure <- obj$exposure
    
    png(file.path(PROJECT_ROOT, "outputs", "figures",
                  sprintf("Fig03_curva_%s.png", key)),
        width = 10, height = 6, units = "in", res = 300)
    plot(obj$pred, "overall", ylab = "RR", xlab = exposure,
         main = paste(region, "-", outcome, "-", exposure),
         ci.arg = list(col = "grey80"))
    abline(v = obj$p50, lty = 2, col = "blue")
    abline(v = obj$p05, lty = 3, col = "blue")
    abline(v = obj$p95, lty = 3, col = "red")
    dev.off()
  }
}

# ── Figura 4: Forest plot bayesiano ──
fig4 <- bayes_results |>
  dplyr::filter(!is.na(posterior_mean), !is.na(ci95_lower)) |>
  dplyr::mutate(
    label = paste(macro_regiao, outcome, exposure, sep = " | "),
    rr_posterior = exp(posterior_mean),
    rr_lower = exp(ci95_lower),
    rr_upper = exp(ci95_upper),
    cor = dplyr::case_when(
      prob_rr_gt_110 > 0.80 ~ "Pr(RR>1.10) > 80%",
      prob_rr_gt_1 > 0.95 ~ "Pr(RR>1) > 95%",
      TRUE ~ "Inconclusivo"
    )
  ) |>
  dplyr::arrange(rr_posterior) |>
  dplyr::mutate(label = factor(label, levels = unique(label))) |>
  ggplot(aes(x = rr_posterior, y = label, color = cor)) +
  geom_point(size = 2) +
  geom_errorbarh(aes(xmin = rr_lower, xmax = rr_upper), height = 0.2) +
  geom_vline(xintercept = 1, lty = 2) +
  scale_x_log10() +
  labs(title = "Razões de Risco Posteriores (Bayesiano Hierárquico)",
       x = "RR (escala log)", y = "") +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave(file.path(PROJECT_ROOT, "outputs", "figures", "Fig04_forest_bayesiano.png"),
       fig4, width = 14, height = 10, dpi = 300)

log_msg("INFO", "[7/8] Figuras geradas.")

# ═══════════════════════════════════════════════════════════════════════════════
# 8. RELATÓRIOS E TESTES DE INTEGRIDADE
# ═══════════════════════════════════════════════════════════════════════════════

log_msg("INFO", "[8/8] Gerando relatórios e executando testes de integridade")

# ── Relatório de auditoria de dados ──
cat("", file = file.path(PROJECT_ROOT, "audit", "relatorio_auditoria_dados.md"))
sink(file.path(PROJECT_ROOT, "audit", "relatorio_auditoria_dados.md"))
cat("# Relatório de Auditoria de Dados\n\n")
cat("## 1. Desfechos\n\n")
cat(sprintf("- **Total internações (SIH, I60-I69, 2010-2025):** %d\n",
            sum(dat$internacoes_i60_i69, na.rm = TRUE)))
cat(sprintf("- **Total internações (SIH, I60-I64, 2010-2025):** %d\n",
            sum(dat$internacoes_i60_i64, na.rm = TRUE)))
cat(sprintf("- **Total óbitos (SIM, I60-I69, 2010-2024):** %d\n",
            sum(dat$obitos_i60_i69, na.rm = TRUE)))
cat(sprintf("- **Total óbitos (SIM, I60-I64, 2010-2024):** %d\n",
            sum(dat$obitos_i60_i64, na.rm = TRUE)))
cat("\n## 2. Períodos de Observação\n\n")
cat("- **Internações:** 2010-01-01 a 2025-12-31 (SIH-RD)\n")
cat("- **Óbitos:** 2010-01-01 a 2024-12-31 (SIM-DO)\n")
cat("- **Mortalidade 2025:** Não disponível. Variável MORTE da AIH NÃO foi utilizada.\n")
cat("\n## 3. Distribuição CID\n\n")
cat("### Internações (SIH)\n\n")
for(i in 1:nrow(sih_cid_count)) {
  cat(sprintf("- %s: %d\n", sih_cid_count$cid3[i], sih_cid_count$n[i]))
}
cat("\n### Óbitos (SIM)\n\n")
for(i in 1:nrow(sim_cid_count)) {
  cat(sprintf("- %s: %d\n", sim_cid_count$cid3[i], sim_cid_count$n[i]))
}
sink()

# ── Testes de integridade automatizados ──
log_msg("INFO", "  Executando testes de integridade...")

integrity_results <- list()

# Test 1: No SIM mortality in 2025
ob_2025 <- dat |> dplyr::filter(data > SIM_DATE_END) |> dplyr::pull(obitos_i60_i69)
integrity_results$sim_2025_na <- all(is.na(ob_2025))
log_msg("INFO", sprintf("  [%s] SIM 2025 é NA: %s",
        if(integrity_results$sim_2025_na) "PASS" else "FAIL",
        integrity_results$sim_2025_na))

# Test 2: No SIH fallback in fonte_obitos
if("fonte_obitos" %in% names(dat)) {
  has_sih_fallback <- any(dat$fonte_obitos == "SIH_AIHS_MORTE", na.rm = TRUE)
  integrity_results$no_sih_fallback <- !has_sih_fallback
} else {
  integrity_results$no_sih_fallback <- TRUE
}
log_msg("INFO", sprintf("  [%s] Sem fallback SIH: %s",
        if(integrity_results$no_sih_fallback) "PASS" else "FAIL",
        integrity_results$no_sih_fallback))

# Test 3: RR values are finite
integrity_results$rr_finite <- all(is.finite(rr_tbl$rr_p05[!rr_tbl$modelo_invalido]) &
                                    is.finite(rr_tbl$rr_p95[!rr_tbl$modelo_invalido]))
log_msg("INFO", sprintf("  [%s] RR finitos: %s",
        if(integrity_results$rr_finite) "PASS" else "FAIL",
        integrity_results$rr_finite))

# Test 4: No invalid models in classification
n_invalid <- sum(rr_tbl$modelo_invalido)
integrity_results$invalid_models_flagged <- n_invalid == sum(rr_tbl$classificacao == "modelo_invalido")
log_msg("INFO", sprintf("  [%s] Modelos inválidos sinalizados: %s (%d inválidos)",
        if(integrity_results$invalid_models_flagged) "PASS" else "FAIL",
        integrity_results$invalid_models_flagged, n_invalid))

# Test 5: Regions present in all models
regions_in_results <- unique(rr_tbl$macro_regiao)
integrity_results$all_regions <- all(MACRORREGIOES %in% regions_in_results)
log_msg("INFO", sprintf("  [%s] Todas 9 regiões presentes: %s",
        if(integrity_results$all_regions) "PASS" else "FAIL",
        integrity_results$all_regions))

# Test 6: Model count is correct
n_expected <- 9 * 4 * 2  # 9 regions × 4 outcomes × 2 exposures = 72 combinations
n_obtained <- nrow(rr_tbl)
integrity_results$model_count <- n_obtained == n_expected
log_msg("INFO", sprintf("  [%s] Número de modelos: %d (esperado: %d)",
        if(integrity_results$model_count) "PASS" else "FAIL",
        n_obtained, n_expected))

# Save integrity report
integrity_df <- tibble(
  teste = names(integrity_results),
  resultado = unlist(integrity_results)
)
write_audit(integrity_df,
  file.path(PROJECT_ROOT, "audit", "testes_integridade_finais.csv"))

# ── Session info ──
sink(file.path(PROJECT_ROOT, "audit", "session_info.txt"))
cat("=== SESSION INFO ===\n")
sessionInfo()
sink()

# ── Final summary ──
log_msg("INFO", "═══════════════════════════════════════════════════")
log_msg("INFO", "PIPELINE CORRIGIDO CONCLUÍDO")
log_msg("INFO", "═══════════════════════════════════════════════════")
log_msg("INFO", "Modelos ajustados: ", n_obtained)
log_msg("INFO", "Modelos inválidos: ", n_invalid)
log_msg("INFO", "Classificações:")
log_msg("INFO", "  Sinal consistente: ", sum(rr_tbl$classificacao == "sinal_consistente"))
log_msg("INFO", "  Sinal sugestivo: ", sum(rr_tbl$classificacao == "sinal_sugestivo"))
log_msg("INFO", "  Evidência insuficiente: ", sum(rr_tbl$classificacao == "evidencia_insuficiente"))
log_msg("INFO", "  Modelo inválido: ", sum(rr_tbl$classificacao == "modelo_invalido"))
log_msg("INFO", "Testes de integridade: ", sum(unlist(integrity_results)), "/", length(integrity_results), " passed")

cat("\nPipeline concluído com sucesso.\n")
