source("scripts/_bootstrap.R", encoding = "UTF-8")
panel <- readRDS(project_path("data", "processed", "painel_mensal_integrado.rds"))
panel <- panel[order(panel$sistema, panel$ano, panel$mes), ]
panel$variacao_percentual <- ave(
  panel$eventos, panel$sistema,
  FUN = function(x) c(NA_real_, diff(x) / head(x, -1L) * 100)
)
panel$tempo <- as.Date(sprintf("%04d-%02d-01", panel$ano, panel$mes))
write_csv_safe(panel, project_path("results", "tables", "serie_mensal_variacao.csv"))

models <- lapply(split(panel, panel$sistema), function(x) {
  if (nrow(x) < 24L) {
    return(NULL)
  }
  fit <- stats::glm(eventos ~ seq_len(nrow(x)) + factor(mes), family = quasipoisson(), data = x)
  data.frame(
    term = names(stats::coef(fit)), estimate = unname(stats::coef(fit)),
    standard_error = sqrt(diag(stats::vcov(fit))), model = "quasi-Poisson descritivo"
  )
})
models <- models[!vapply(models, is.null, logical(1))]
if (length(models)) {
  write_csv_safe(
    do.call(rbind, models),
    project_path("results", "tables", "modelos_temporais_exploratorios.csv")
  )
}
log_event("INFO", "temporal_analysis", "Análise exploratória concluída; não implica causalidade")
