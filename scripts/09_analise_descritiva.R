source("scripts/_bootstrap.R", encoding = "UTF-8")
panel <- readRDS(project_path("data", "processed", "painel_mensal_integrado.rds"))
annual <- aggregate(eventos ~ ano + sistema, panel, sum)
write_csv_safe(annual, project_path("results", "tables", "serie_anual_eventos.csv"))
if (requireNamespace("ggplot2", quietly = TRUE)) {
  for (system in unique(annual$sistema)) {
    x <- annual[annual$sistema == system, ]
    p <- plot_time_series(x, "ano", "eventos", paste("Série anual -", system), "Eventos")
    save_figure(p, paste0("serie_anual_", tolower(system), ".png"))
  }
}
