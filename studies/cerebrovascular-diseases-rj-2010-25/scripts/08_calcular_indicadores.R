source("scripts/_bootstrap.R", encoding = "UTF-8")

sih_files <- list.files(
  project_path("data", "processed"),
  pattern = "^sih_.*_cvd[.]rds$",
  full.names = TRUE
)
sim_files <- list.files(
  project_path("data", "processed"),
  pattern = "^sim_.*_cvd[.]rds$",
  full.names = TRUE
)
population_path <- project_path(
  "data-raw", "populacao", "populacao_municipal_rj.csv"
)
regions_path <- project_path("config", "regioes_saude_rj.csv")

if (!file.exists(population_path)) {
  stop("Execute scripts/05_baixar_populacao.R antes dos indicadores.")
}
population <- utils::read.csv(
  population_path,
  stringsAsFactors = FALSE, check.names = FALSE,
  fileEncoding = "UTF-8"
)
regions <- utils::read.csv(
  regions_path,
  stringsAsFactors = FALSE, check.names = FALSE,
  fileEncoding = "UTF-8"
)
if (nrow(regions) != 92L || anyDuplicated(regions$nome_municipio)) {
  stop("A configuração deve conter os 92 municípios do RJ, sem duplicidades.")
}

municipality_reference <- unique(population[c("municipio", "nome_municipio")])
municipality_reference <- municipality_reference[!is.na(
  municipality_reference$nome_municipio
), ]
municipality_reference <- merge(
  municipality_reference, regions,
  by = "nome_municipio", all.x = TRUE
)
if (nrow(municipality_reference) != 92L || anyNA(
  municipality_reference$regiao_saude
)) {
  stop("Falha ao associar os 92 municípios do IBGE às regiões de saúde.")
}

add_geography <- function(data, municipality_column) {
  validate_required_columns(data, municipality_column, "base de eventos")
  names(municipality_reference)[names(municipality_reference) == "municipio"] <-
    municipality_column
  out <- merge(
    data, municipality_reference,
    by = municipality_column, all.x = TRUE
  )
  names(municipality_reference)[names(municipality_reference) == municipality_column] <-
    "municipio"
  out
}

save_distributions <- function(data, system) {
  data$faixa_etaria <- as.character(age_group(data$idade_anos))
  variables <- intersect(
    c("sexo", "faixa_etaria", "raca_cor", "nome_municipio", "regiao_saude"),
    names(data)
  )
  for (variable in variables) {
    save_table(
      count_by(data, c("ano", variable)),
      paste0("distribuicao_", system, "_", variable, ".csv")
    )
  }
}

if (length(sih_files)) {
  sih <- read_rds_bind(sih_files)
  # A população principal inclui somente residentes do RJ em todos os
  # indicadores; internações de não residentes permanecem apenas na auditoria.
  sih_residents <- sih[startsWith(sih$municipio_residencia, "33"), ]
  save_table(
    annual_sih_indicators(sih_residents),
    "indicadores_anuais_sih.csv"
  )
  sih_residents <- add_geography(sih_residents, "municipio_residencia")
  save_distributions(sih_residents, "sih")
  events <- count_by(
    sih_residents, c("ano", "municipio_residencia"), "internacoes"
  )
  names(events)[names(events) == "municipio_residencia"] <- "municipio"
  rates <- complete_population_rates(
    events, population,
    count = "internacoes"
  )
  save_table(rates, "taxas_municipais_sih.csv")
  save_table(
    state_rates(rates, "internacoes"), "taxas_estaduais_sih.csv"
  )
}

if (length(sim_files)) {
  sim <- read_rds_bind(sim_files)
  deaths <- count_by(sim, "ano", "obitos_causa_basica_cerebrovascular")
  save_table(deaths, "obitos_anuais_sim.csv")

  sim_residents <- sim[startsWith(sim$municipio_residencia, "33"), ]
  sim_residents <- add_geography(sim_residents, "municipio_residencia")
  save_distributions(sim_residents, "sim")
  events <- count_by(
    sim_residents, c("ano", "municipio_residencia"),
    "obitos_causa_basica_cerebrovascular"
  )
  names(events)[names(events) == "municipio_residencia"] <- "municipio"
  rates <- complete_population_rates(
    events, population,
    count = "obitos_causa_basica_cerebrovascular"
  )
  save_table(rates, "taxas_municipais_sim.csv")
  save_table(
    state_rates(rates, "obitos_causa_basica_cerebrovascular"),
    "taxas_estaduais_sim.csv"
  )
}

record_session_info(project_path("results", "logs", "indicators-session-info.txt"))
