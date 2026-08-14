source("scripts/_bootstrap.R", encoding = "UTF-8")
years <- validate_year_range(cfg$project$year_start, cfg$project$year_end)
sih_files <- list.files(project_path("data", "processed"), pattern = "^sih_.*_cvd[.]rds$", full.names = TRUE)
sim_files <- list.files(project_path("data", "processed"), pattern = "^sim_.*_cvd[.]rds$", full.names = TRUE)

if (length(sih_files)) {
  sih <- read_rds_bind(sih_files)
  audit_dataset(sih, "sih_cerebrovascular", "ano", "mes", "diagnostico_principal",
    "idade_anos", "sexo", "raca_cor", "municipio_residencia", NULL,
    "dias_permanencia", "valor_internacao",
    keys = intersect(c("N_AIH", "ANO_CMPT", "MES_CMPT"), names(sih)),
    expected_years = years
  )
  residence_hospital <- data.frame(
    residente_rj = startsWith(sih$municipio_residencia, "33"),
    internacao_rj = startsWith(sih$municipio_internacao, "33")
  )
  write_csv_safe(
    as.data.frame(table(residence_hospital, useNA = "ifany")),
    project_path("results", "audits", "sih_residencia_internacao.csv")
  )
  write_csv_safe(
    as.data.frame(table(
      cid = substr(sih$diagnostico_principal, 1, 3),
      obito = sih$obito_hospitalar, useNA = "ifany"
    )),
    project_path("results", "audits", "sih_diagnostico_obito.csv")
  )
}
if (length(sim_files)) {
  sim <- read_rds_bind(sim_files)
  audit_dataset(sim, "sim_cerebrovascular", "ano", "mes", "causa_basica",
    "idade_anos", "sexo", "raca_cor", "municipio_residencia", "data_obito",
    keys = intersect(c("DTOBITO", "HORAOBITO", "CODMUNRES", "SEXO", "IDADE", "CAUSABAS"), names(sim)),
    expected_years = years
  )
  residence_occurrence <- data.frame(
    mesma_uf = substr(sim$municipio_residencia, 1, 2) == substr(sim$municipio_ocorrencia, 1, 2),
    mesmo_municipio = sim$municipio_residencia == sim$municipio_ocorrencia
  )
  write_csv_safe(
    as.data.frame(table(residence_occurrence, useNA = "ifany")),
    project_path("results", "audits", "sim_residencia_ocorrencia.csv")
  )
}
panel_path <- project_path("data", "processed", "painel_mensal_integrado.rds")
if (file.exists(panel_path)) {
  panel <- readRDS(panel_path)
  breaks <- lapply(split(panel, panel$sistema), function(x) {
    x <- x[order(x$ano, x$mes), ]
    detect_temporal_breaks(x, "eventos", cfg$quality$abrupt_change_threshold)
  })
  write_csv_safe(
    do.call(rbind, breaks),
    project_path("results", "audits", "quebras_temporais_painel.csv")
  )
}
record_session_info()
