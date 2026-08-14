source("scripts/_bootstrap.R", encoding = "UTF-8")

if (!requireNamespace("sidrar", quietly = TRUE)) stop("Pacote 'sidrar' ausente.")

parse_population <- function(raw, source, method) {
  names(raw) <- standardize_names(names(raw))
  validate_required_columns(raw, c("municipio_codigo", "ano", "valor"), source)
  municipality_name <- if ("municipio" %in% names(raw)) {
    sub("[[:space:]]+-[[:space:]]+RJ$", "", as.character(raw$municipio))
  } else {
    rep(NA_character_, nrow(raw))
  }
  out <- data.frame(
    municipio = normalize_municipality_code(raw$municipio_codigo),
    nome_municipio = municipality_name,
    ano = as.integer(raw$ano),
    populacao = suppressWarnings(as.numeric(raw$valor)),
    fonte = source,
    metodo = method,
    stringsAsFactors = FALSE
  )
  out[startsWith(out$municipio, "33") & !is.na(out$populacao), ]
}

rows <- list()

# Censo 2010: população total, ambos os sexos e todas as situações do domicílio.
census_2010 <- sidrar::get_sidra(api = "/t/202/n6/all/v/93/p/2010/c1/0/c2/0")
rows[["2010"]] <- parse_population(
  census_2010,
  "IBGE/SIDRA tabela 202, variável 93",
  "censo_demografico_2010"
)

# Estimativas oficiais em 1º de julho. A tabela não disponibiliza 2022 ou 2023.
estimate_years <- c(2011:2021, 2024:2025)
for (year in estimate_years) {
  raw <- tryCatch(
    sidrar::get_sidra(
      x = 6579, variable = 9324, period = as.character(year), geo = "City"
    ),
    error = identity
  )
  if (inherits(raw, "error") || !nrow(raw)) {
    log_event(
      "ERROR", "population_unavailable", "Estimativa oficial não obtida",
      list(
        year = year, source = "SIDRA 6579/9324",
        error = if (inherits(raw, "error")) conditionMessage(raw) else "resposta vazia"
      )
    )
    next
  }
  rows[[as.character(year)]] <- parse_population(
    raw,
    "IBGE/SIDRA tabela 6579, variável 9324",
    "estimativa_1_julho"
  )
}

# Censo 2022: população residente total.
census_2022 <- sidrar::get_sidra(x = 4709, variable = 93, period = "2022", geo = "City")
rows[["2022"]] <- parse_population(
  census_2022,
  "IBGE/SIDRA tabela 4709, variável 93",
  "censo_demografico_2022"
)

population <- do.call(rbind, rows)
# Decisão analítica de 17/07/2026: estimar 2023 por interpolação linear
# municipal entre o Censo 2022 e a estimativa oficial de 2024. O método e a
# origem permanecem explícitos para impedir que o valor seja tratado como uma
# estimativa oficial publicada para 2023.
population <- rbind(
  population,
  interpolate_population_year(population, 2022L, 2024L, 2023L)
)
population <- population[order(population$ano, population$municipio), ]
if (any(duplicated(population[c("municipio", "ano")]))) {
  stop("Duplicidade município-ano na população.")
}
if (any(population$populacao <= 0, na.rm = TRUE)) {
  stop("Denominador populacional não positivo.")
}

expected_years <- validate_year_range(cfg$project$year_start, cfg$project$year_end)
coverage <- count_periods(population, "ano")
coverage$municipios <- vapply(coverage$ano, function(year) {
  length(unique(population$municipio[population$ano == year]))
}, integer(1))
write_csv_safe(population, project_path("data-raw", "populacao", "populacao_municipal_rj.csv"))
write_csv_safe(coverage, project_path("results", "audits", "cobertura_populacao.csv"))

missing_years <- setdiff(expected_years, unique(population$ano))
if (length(missing_years)) {
  log_event(
    "WARN", "population_gaps", "Taxas bloqueadas nos anos sem denominador oficial compatível",
    list(years = paste(missing_years, collapse = ","))
  )
}
if (any(coverage$municipios != 92L)) {
  stop("Cobertura populacional diferente de 92 municípios em um ou mais anos.")
}
record_session_info(project_path("results", "logs", "population-session-info.txt"))
