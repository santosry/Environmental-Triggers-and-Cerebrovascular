source("scripts/_bootstrap.R", encoding = "UTF-8")

required_packages <- c("Kendall", "dunn.test")
missing_packages <- required_packages[!vapply(
  required_packages, requireNamespace, logical(1),
  quietly = TRUE
)]
if (length(missing_packages)) {
  stop("Pacotes ausentes: ", paste(missing_packages, collapse = ", "))
}

read_result <- function(name, folder = "tables") {
  path <- project_path("results", folder, name)
  if (!file.exists(path)) stop("Resultado necessário ausente: ", path)
  utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
}

population <- utils::read.csv(
  project_path("data-raw", "populacao", "populacao_municipal_rj.csv"),
  stringsAsFactors = FALSE, check.names = FALSE, fileEncoding = "UTF-8"
)
regions <- utils::read.csv(
  project_path("config", "regioes_saude_rj.csv"),
  stringsAsFactors = FALSE, check.names = FALSE, fileEncoding = "UTF-8"
)
geography <- unique(population[c("municipio", "nome_municipio")])
geography <- geography[!is.na(geography$nome_municipio), ]
geography <- merge(geography, regions, by = "nome_municipio", all.x = TRUE)
if (nrow(geography) != 92L || anyNA(geography$regiao_saude)) {
  stop("Referência geográfica incompleta para as regiões de saúde.")
}

add_region <- function(data, municipality_column = "municipio") {
  reference <- geography[c("municipio", "regiao_saude")]
  names(reference)[names(reference) == "municipio"] <- municipality_column
  merge(data, reference, by = municipality_column, all.x = TRUE)
}

# Tendências anuais e sazonais --------------------------------------------
sih_annual <- read_result("indicadores_anuais_sih.csv")
sim_annual <- read_result("obitos_anuais_sim.csv")
sih_state_rates <- read_result("taxas_estaduais_sih.csv")
sim_state_rates <- read_result("taxas_estaduais_sim.csv")

annual_series <- list(
  list(sih_annual$ano, sih_annual$internacoes, "SIH: internações"),
  list(sih_annual$ano, sih_annual$obitos_hospitalares, "SIH: óbitos hospitalares"),
  list(sih_annual$ano, sih_annual$mortalidade_hospitalar_pct, "SIH: mortalidade hospitalar (%)"),
  list(sih_annual$ano, sih_annual$permanencia_media, "SIH: permanência média"),
  list(sih_annual$ano, sih_annual$custo_medio, "SIH: custo médio nominal"),
  list(sim_annual$ano, sim_annual$obitos_causa_basica_cerebrovascular, "SIM: óbitos"),
  list(sih_state_rates$ano, sih_state_rates$taxa_100mil, "SIH: taxa de internação"),
  list(sim_state_rates$ano, sim_state_rates$taxa_100mil, "SIM: taxa de mortalidade")
)
mk_annual <- do.call(rbind, lapply(annual_series, function(x) {
  mann_kendall_result(x[[1]], x[[2]], x[[3]])
}))
mk_annual$p_bh <- stats::p.adjust(mk_annual$p_valor, method = "BH")
save_table(mk_annual, "mann_kendall_tendencias_anuais.csv")

monthly_panel <- utils::read.csv(
  project_path("data", "processed", "painel_mensal_integrado.csv"),
  stringsAsFactors = FALSE
)
seasonal_rows <- lapply(split(monthly_panel, monthly_panel$sistema), function(x) {
  x <- x[order(x$ano, x$mes), ]
  expected <- expand.grid(
    ano = seq(min(x$ano), max(x$ano)), mes = 1:12
  )
  completed <- merge(expected, x[c("ano", "mes", "eventos")],
    by = c("ano", "mes"), all.x = TRUE
  )
  seasonal_mann_kendall_result(
    completed$eventos, min(completed$ano), unique(x$sistema)
  )
})
mk_seasonal <- do.call(rbind, seasonal_rows)
mk_seasonal$p_bonferroni <- stats::p.adjust(
  mk_seasonal$p_valor,
  method = "bonferroni"
)
save_table(mk_seasonal, "mann_kendall_sazonal_mensal.csv")

# Diferenças inter-regionais ----------------------------------------------
sih_municipal <- add_region(read_result("taxas_municipais_sih.csv"))
sim_municipal <- add_region(read_result("taxas_municipais_sim.csv"))
regional_sih <- kruskal_dunn_by_year(sih_municipal, system = "SIH")
regional_sim <- kruskal_dunn_by_year(sim_municipal, system = "SIM")
kruskal_results <- rbind(regional_sih$kruskal, regional_sim$kruskal)
dunn_results <- rbind(regional_sih$dunn, regional_sim$dunn)
dunn_results$p_bonferroni_global <- stats::p.adjust(
  dunn_results$p_valor,
  method = "bonferroni"
)
save_table(kruskal_results, "kruskal_wallis_regioes.csv")
save_table(dunn_results, "dunn_bonferroni_regioes.csv")

# Associação com óbito hospitalar ----------------------------------------
sih_files <- list.files(
  project_path("data", "processed"),
  pattern = "^sih_.*_cvd[.]rds$",
  full.names = TRUE
)
sih <- read_rds_bind(sih_files)
sih <- sih[startsWith(sih$municipio_residencia, "33"), ]
sih <- add_region(sih, "municipio_residencia")
sih$faixa_etaria <- as.character(age_group(sih$idade_anos))
sih$subgrupo_cid <- substr(sih$diagnostico_principal, 1L, 3L)
sih$periodo <- cut(
  sih$ano,
  breaks = c(2009, 2014, 2019, 2022, 2025),
  labels = c("2010-2014", "2015-2019", "2020-2022", "2023-2025")
)
sih$raca_cor_rotulo <- unname(c(
  "01" = "Branca", "02" = "Preta", "03" = "Parda",
  "04" = "Amarela", "05" = "Indígena", "99" = "Ignorado"
)[as.character(sih$raca_cor)])
sih$carater_rotulo <- unname(c(
  "01" = "Eletivo", "02" = "Urgência",
  "03" = "Acidente no trabalho", "04" = "Outras lesões",
  "05" = "Outros acidentes"
)[as.character(sih$carater_atendimento)])

association_variables <- c(
  "sexo", "faixa_etaria", "raca_cor_rotulo", "carater_rotulo",
  "regiao_saude", "subgrupo_cid", "periodo"
)
association_objects <- lapply(seq_along(association_variables), function(index) {
  chi_square_association(
    sih, association_variables[[index]],
    simulations = as.integer(cfg$inference$monte_carlo_simulations),
    seed = as.integer(cfg$inference$random_seed) + index
  )
})
association_summary <- do.call(rbind, lapply(
  association_objects, `[[`, "summary"
))
association_summary$p_bh <- stats::p.adjust(
  association_summary$p_valor,
  method = "BH"
)
association_summary$p_bonferroni <- stats::p.adjust(
  association_summary$p_valor,
  method = "bonferroni"
)
association_residuals <- do.call(rbind, lapply(
  association_objects, `[[`, "residuals"
))
mortality_categories <- do.call(rbind, lapply(
  association_variables,
  function(variable) mortality_by_category(sih, variable)
))
save_table(association_summary, "associacao_obito_hospitalar.csv")
save_table(
  association_residuals, "residuos_padronizados_associacao_obito.csv"
)
save_table(
  mortality_categories, "mortalidade_hospitalar_por_categoria.csv"
)

sih$contagem_evento <- 1L
sih$contagem_obito <- as.integer(sih$obito_hospitalar %in% TRUE)
cid_sih <- aggregate(
  cbind(contagem_evento, contagem_obito) ~ ano + subgrupo_cid,
  data = sih, FUN = sum
)
names(cid_sih)[names(cid_sih) == "contagem_evento"] <- "internacoes"
names(cid_sih)[names(cid_sih) == "contagem_obito"] <- "obitos_hospitalares"
cid_sih$mortalidade_hospitalar_pct <- hospital_mortality_rate(
  cid_sih$obitos_hospitalares, cid_sih$internacoes
)
save_table(cid_sih, "cid_subgrupos_anuais_sih.csv")

sim_files <- list.files(
  project_path("data", "processed"),
  pattern = "^sim_.*_cvd[.]rds$",
  full.names = TRUE
)
sim <- read_rds_bind(sim_files)
sim$subgrupo_cid <- substr(sim$causa_basica, 1L, 3L)
cid_sim <- count_by(
  sim, c("ano", "subgrupo_cid"), "obitos_causa_basica"
)
save_table(cid_sim, "cid_subgrupos_anuais_sim.csv")

# Auditoria da camada inferencial -----------------------------------------
audit <- data.frame(
  verificacao = c(
    "internacoes_sih_residentes_rj", "municipios_georreferenciados",
    "anos_mann_kendall_anual", "series_mann_kendall_sazonal",
    "testes_kruskal_wallis", "comparacoes_dunn",
    "testes_associacao_obito", "testes_monte_carlo"
  ),
  valor = c(
    nrow(sih), nrow(geography), nrow(mk_annual), nrow(mk_seasonal),
    nrow(kruskal_results), nrow(dunn_results), nrow(association_summary),
    sum(association_summary$simulacoes > 0)
  ),
  esperado = c(
    "> 0", "92", "8 séries", "2 séries", "> 0", "> 0",
    paste(length(association_variables), "testes"), ">= 0"
  ),
  status = "OK"
)
if (nrow(geography) != 92L) audit$status <- "REVISAR"
write_csv_safe(
  audit,
  project_path("results", "audits", "auditoria_analises_inferenciais.csv")
)
log_event(
  "INFO", "advanced_analysis_complete",
  "Camada inferencial concluída; SIH e SIM analisados separadamente",
  list(
    sih_records = nrow(sih), association_tests = nrow(association_summary)
  )
)
record_session_info(
  project_path("results", "logs", "advanced-analysis-session-info.txt")
)
