# Indicadores epidemiológicos --------------------------------------------

safe_rate <- function(numerator, denominator, multiplier = 100000) {
  ifelse(is.na(denominator) | denominator <= 0, NA_real_, numerator / denominator * multiplier)
}

interpolate_population_year <- function(population, start_year, end_year,
                                        target_year) {
  validate_required_columns(
    population,
    c("municipio", "nome_municipio", "ano", "populacao"),
    "denominadores populacionais"
  )
  if (!(start_year < target_year && target_year < end_year)) {
    stop("O ano interpolado deve estar estritamente entre os anos de referência.")
  }
  start <- population[population$ano == start_year, , drop = FALSE]
  end <- population[population$ano == end_year, , drop = FALSE]
  if (!nrow(start) || !nrow(end)) {
    stop("Anos de referência ausentes para interpolação populacional.")
  }
  if (anyDuplicated(start$municipio) || anyDuplicated(end$municipio)) {
    stop("Duplicidade municipal nos anos usados na interpolação.")
  }
  paired <- merge(
    start[c("municipio", "nome_municipio", "populacao")],
    end[c("municipio", "nome_municipio", "populacao")],
    by = "municipio", suffixes = c("_inicio", "_fim"), all = TRUE
  )
  if (anyNA(paired$populacao_inicio) || anyNA(paired$populacao_fim)) {
    stop("Municípios não correspondentes entre os anos de referência.")
  }
  fraction <- (target_year - start_year) / (end_year - start_year)
  data.frame(
    municipio = paired$municipio,
    nome_municipio = ifelse(
      is.na(paired$nome_municipio_fim),
      paired$nome_municipio_inicio,
      paired$nome_municipio_fim
    ),
    ano = as.integer(target_year),
    populacao = as.integer(round(
      paired$populacao_inicio +
        fraction * (paired$populacao_fim - paired$populacao_inicio)
    )),
    fonte = paste0(
      "Interpolação linear municipal entre IBGE ",
      start_year, " e ", end_year
    ),
    metodo = paste0(
      "interpolacao_linear_", start_year, "_", end_year
    ),
    stringsAsFactors = FALSE
  )
}

hospital_mortality_rate <- function(deaths, admissions, multiplier = 100) {
  safe_rate(deaths, admissions, multiplier)
}

age_group <- function(age) {
  cut(age,
    breaks = c(-Inf, 0, 19, 39, 59, 79, Inf), right = TRUE,
    labels = c("<1", "1-19", "20-39", "40-59", "60-79", "80+")
  )
}

count_by <- function(data, variables, count_name = "n") {
  validate_required_columns(data, variables, "base para agregação")
  key <- lapply(data[variables], function(x) {
    x <- as.character(x)
    x[is.na(x) | x == ""] <- "Ignorado/ausente"
    x
  })
  out <- aggregate(rep(1L, nrow(data)), key, sum)
  names(out)[ncol(out)] <- count_name
  out
}

state_rates <- function(municipal_rates, count, denominator = "populacao") {
  validate_required_columns(
    municipal_rates, c("ano", count, denominator), "taxas municipais"
  )
  years <- sort(unique(municipal_rates$ano))
  rows <- lapply(years, function(year) {
    x <- municipal_rates[municipal_rates$ano == year, , drop = FALSE]
    data.frame(
      ano = year,
      eventos = sum(x[[count]], na.rm = TRUE),
      populacao = if (all(is.na(x[[denominator]]))) {
        NA_real_
      } else {
        sum(x[[denominator]], na.rm = TRUE)
      }
    )
  })
  out <- do.call(rbind, rows)
  names(out)[names(out) == "eventos"] <- count
  out$taxa_100mil <- safe_rate(out[[count]], out$populacao)
  out
}

annual_sih_indicators <- function(data, year = "ano", death = "obito_hospitalar",
                                  days = "dias_permanencia", cost = "valor_internacao") {
  validate_required_columns(data, c(year, death, days, cost), "SIH processado")
  split_data <- split(data, data[[year]])
  rows <- lapply(split_data, function(x) {
    data.frame(
      ano = x[[year]][1], internacoes = nrow(x),
      obitos_hospitalares = sum(x[[death]] %in% TRUE, na.rm = TRUE),
      mortalidade_hospitalar_pct = hospital_mortality_rate(sum(x[[death]] %in% TRUE, na.rm = TRUE), nrow(x)),
      permanencia_media = mean(x[[days]], na.rm = TRUE), permanencia_mediana = median(x[[days]], na.rm = TRUE),
      custo_total = sum(x[[cost]], na.rm = TRUE), custo_medio = mean(x[[cost]], na.rm = TRUE)
    )
  })
  do.call(rbind, rows)
}

join_population_and_rate <- function(events, population, by, count, denominator = "populacao",
                                     multiplier = 100000) {
  validate_required_columns(events, c(by, count), "eventos")
  validate_required_columns(population, c(by, denominator), "população")
  out <- merge(events, population, by = by, all.x = TRUE)
  out$taxa_100mil <- safe_rate(out[[count]], out[[denominator]], multiplier)
  out
}

complete_population_rates <- function(events, population, municipality = "municipio",
                                      count, multiplier = 100000) {
  validate_required_columns(events, c("ano", municipality, count), "eventos")
  validate_required_columns(
    population, c("ano", municipality, "populacao"), "população"
  )
  event_years <- unique(events$ano)
  denominators <- population[population$ano %in% event_years, , drop = FALSE]
  out <- merge(
    denominators, events,
    by = c("ano", municipality), all.x = TRUE
  )
  out[[count]][is.na(out[[count]])] <- 0L
  out$taxa_100mil <- safe_rate(out[[count]], out$populacao, multiplier)
  out
}
