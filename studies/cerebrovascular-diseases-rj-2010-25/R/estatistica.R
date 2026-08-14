# Métodos estatísticos para análises adicionais ---------------------------

wilson_interval <- function(events, total, conf_level = 0.95) {
  if (length(events) != length(total)) stop("'events' e 'total' devem ter o mesmo tamanho.")
  z <- stats::qnorm(1 - (1 - conf_level) / 2)
  proportion <- ifelse(total > 0, events / total, NA_real_)
  denominator <- 1 + z^2 / total
  center <- (proportion + z^2 / (2 * total)) / denominator
  half_width <- z * sqrt(
    proportion * (1 - proportion) / total + z^2 / (4 * total^2)
  ) / denominator
  data.frame(
    proportion = proportion,
    lower = ifelse(total > 0, pmax(0, center - half_width), NA_real_),
    upper = ifelse(total > 0, pmin(1, center + half_width), NA_real_)
  )
}

explicit_missing <- function(x, missing = "Ignorado/ausente") {
  out <- trimws(as.character(x))
  out[is.na(out) | out == ""] <- missing
  out
}

cramers_v <- function(table, statistic = NULL, bias_corrected = TRUE) {
  observed <- as.matrix(table)
  n <- sum(observed)
  if (n == 0L || min(dim(observed)) < 2L) {
    return(NA_real_)
  }
  if (is.null(statistic)) {
    statistic <- unname(suppressWarnings(stats::chisq.test(observed, correct = FALSE)$statistic))
  }
  phi2 <- statistic / n
  rows <- nrow(observed)
  columns <- ncol(observed)
  if (!bias_corrected || n <= 1L) {
    return(sqrt(phi2 / min(rows - 1, columns - 1)))
  }
  phi2_corrected <- max(0, phi2 - ((columns - 1) * (rows - 1)) / (n - 1))
  rows_corrected <- rows - ((rows - 1)^2) / (n - 1)
  columns_corrected <- columns - ((columns - 1)^2) / (n - 1)
  sqrt(phi2_corrected / min(rows_corrected - 1, columns_corrected - 1))
}

chi_square_association <- function(data, exposure, outcome = "obito_hospitalar",
                                   simulations = 99999L, seed = 20260717L) {
  validate_required_columns(data, c(exposure, outcome), "teste de associação")
  exposure_values <- explicit_missing(data[[exposure]])
  outcome_values <- explicit_missing(data[[outcome]])
  contingency <- table(exposure_values, outcome_values, useNA = "no")
  if (nrow(contingency) < 2L || ncol(contingency) < 2L) {
    return(list(
      summary = data.frame(
        variavel = exposure, n = sum(contingency), linhas = nrow(contingency),
        colunas = ncol(contingency), metodo = "não estimável",
        estatistica = NA_real_, graus_liberdade = NA_real_, p_valor = NA_real_,
        cramer_v_corrigido = NA_real_, expected_min = NA_real_,
        expected_below_5_pct = NA_real_, simulacoes = 0L
      ),
      residuals = data.frame(), table = contingency
    ))
  }
  asymptotic <- suppressWarnings(stats::chisq.test(contingency, correct = FALSE))
  expected <- asymptotic$expected
  sparse <- any(expected < 1) || mean(expected < 5) > 0.20
  if (sparse) {
    set.seed(seed)
    test <- suppressWarnings(stats::chisq.test(
      contingency,
      simulate.p.value = TRUE, B = simulations
    ))
    method <- "Qui-quadrado de Pearson com Monte Carlo"
    degrees_freedom <- NA_real_
    simulations_used <- simulations
  } else {
    test <- asymptotic
    method <- "Qui-quadrado de Pearson assintótico"
    degrees_freedom <- unname(test$parameter)
    simulations_used <- 0L
  }
  residuals <- as.data.frame(as.table(asymptotic$stdres), stringsAsFactors = FALSE)
  names(residuals) <- c("categoria", "desfecho", "residuo_padronizado")
  residuals$variavel <- exposure
  list(
    summary = data.frame(
      variavel = exposure,
      n = sum(contingency),
      linhas = nrow(contingency),
      colunas = ncol(contingency),
      metodo = method,
      estatistica = unname(asymptotic$statistic),
      graus_liberdade = degrees_freedom,
      p_valor = unname(test$p.value),
      cramer_v_corrigido = cramers_v(
        contingency, unname(asymptotic$statistic),
        bias_corrected = TRUE
      ),
      expected_min = min(expected),
      expected_below_5_pct = mean(expected < 5) * 100,
      simulacoes = simulations_used
    ),
    residuals = residuals,
    table = contingency
  )
}

mortality_by_category <- function(data, variable,
                                  outcome = "obito_hospitalar") {
  validate_required_columns(data, c(variable, outcome), "mortalidade por categoria")
  category <- explicit_missing(data[[variable]])
  outcome_values <- data[[outcome]] %in% TRUE
  split_outcome <- split(outcome_values, category)
  rows <- lapply(names(split_outcome), function(level) {
    x <- split_outcome[[level]]
    total <- length(x)
    deaths <- sum(x, na.rm = TRUE)
    interval <- wilson_interval(deaths, total)
    data.frame(
      variavel = variable, categoria = level, internacoes = total,
      obitos = deaths, mortalidade_pct = interval$proportion * 100,
      ic95_inferior_pct = interval$lower * 100,
      ic95_superior_pct = interval$upper * 100
    )
  })
  do.call(rbind, rows)
}

sen_slope <- function(time, values) {
  keep <- is.finite(time) & is.finite(values)
  time <- as.numeric(time[keep])
  values <- as.numeric(values[keep])
  if (length(values) < 2L || anyDuplicated(time)) {
    return(NA_real_)
  }
  pairs <- utils::combn(seq_along(values), 2L)
  slopes <- (values[pairs[2L, ]] - values[pairs[1L, ]]) /
    (time[pairs[2L, ]] - time[pairs[1L, ]])
  stats::median(slopes, na.rm = TRUE)
}

mann_kendall_result <- function(time, values, series, periodicity = "anual") {
  keep <- is.finite(time) & is.finite(values)
  time <- time[keep]
  values <- values[keep]
  if (length(values) < 4L) {
    return(data.frame(
      serie = series, periodicidade = periodicity, n = length(values),
      tau = NA_real_, p_valor = NA_real_, sen_slope = NA_real_
    ))
  }
  result <- Kendall::MannKendall(values)
  data.frame(
    serie = series, periodicidade = periodicity, n = length(values),
    tau = as.numeric(result$tau), p_valor = as.numeric(result$sl),
    sen_slope = sen_slope(time, values)
  )
}

seasonal_mann_kendall_result <- function(values, start_year, series,
                                         frequency = 12L) {
  if (length(values) < frequency * 2L || anyNA(values)) {
    return(data.frame(
      serie = series, periodicidade = "mensal sazonal", n = length(values),
      tau = NA_real_, p_valor = NA_real_
    ))
  }
  result <- Kendall::SeasonalMannKendall(stats::ts(
    values,
    start = c(start_year, 1L), frequency = frequency
  ))
  data.frame(
    serie = series, periodicidade = "mensal sazonal", n = length(values),
    tau = as.numeric(result$tau), p_valor = as.numeric(result$sl)
  )
}

kruskal_dunn_by_year <- function(data, value = "taxa_100mil",
                                 group = "regiao_saude", system) {
  validate_required_columns(data, c("ano", value, group), "comparação regional")
  years <- sort(unique(data$ano))
  kw_rows <- list()
  dunn_rows <- list()
  for (year in years) {
    current <- data[
      data$ano == year & is.finite(data[[value]]) & !is.na(data[[group]]), ,
      drop = FALSE
    ]
    if (nrow(current) < 3L || length(unique(current[[group]])) < 2L) next
    formula <- stats::reformulate(group, response = value)
    kw <- stats::kruskal.test(formula, data = current)
    kw_rows[[as.character(year)]] <- data.frame(
      sistema = system, ano = year, n = nrow(current),
      regioes = length(unique(current[[group]])),
      estatistica = unname(kw$statistic), graus_liberdade = unname(kw$parameter),
      p_valor = unname(kw$p.value)
    )
    dunn <- suppressMessages(invisible(capture.output(
      result <- dunn.test::dunn.test(
        current[[value]], current[[group]],
        method = "bonferroni",
        kw = FALSE, label = FALSE, table = FALSE, list = TRUE,
        altp = TRUE, interpret = FALSE
      )
    )))
    dunn_rows[[as.character(year)]] <- data.frame(
      sistema = system, ano = year, comparacao = result$comparisons,
      z = result$Z, p_valor = result$altP,
      p_bonferroni = result$altP.adjusted
    )
  }
  kw_table <- if (length(kw_rows)) do.call(rbind, kw_rows) else data.frame()
  if (nrow(kw_table)) {
    kw_table$p_bonferroni_entre_anos <- stats::p.adjust(
      kw_table$p_valor,
      method = "bonferroni"
    )
  }
  list(
    kruskal = kw_table,
    dunn = if (length(dunn_rows)) do.call(rbind, dunn_rows) else data.frame()
  )
}
