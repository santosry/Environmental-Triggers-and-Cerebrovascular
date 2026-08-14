source("scripts/_bootstrap.R", encoding = "UTF-8")
sih_files <- list.files(project_path("data", "processed"), pattern = "^sih_.*_cvd[.]rds$", full.names = TRUE)
sim_files <- list.files(project_path("data", "processed"), pattern = "^sim_.*_cvd[.]rds$", full.names = TRUE)
if (!length(sih_files) && !length(sim_files)) stop("Não há bases processadas para integrar.")

aggregate_events <- function(files, system) {
  if (!length(files)) {
    return(data.frame())
  }
  rows <- lapply(files, function(path) {
    x <- readRDS(path)
    if (identical(system, "SIH_internacoes")) {
      x <- x[startsWith(x$municipio_residencia, "33"), ]
    }
    aggregate(rep(1L, nrow(x)), list(ano = x$ano, mes = x$mes), sum)
  })
  out <- aggregate(x ~ ano + mes, do.call(rbind, rows), sum)
  names(out)[3] <- "eventos"
  out$sistema <- system
  out
}
panel <- rbind(
  aggregate_events(sih_files, "SIH_internacoes"),
  aggregate_events(sim_files, "SIM_obitos_causa_basica")
)
panel <- panel[order(panel$ano, panel$mes, panel$sistema), ]
save_atomic_rds(panel, project_path("data", "processed", "painel_mensal_integrado.rds"))
write_csv_safe(panel, project_path("data", "processed", "painel_mensal_integrado.csv"))
log_event(
  "INFO", "independent_series_complete",
  "Séries independentes empilhadas em formato longo",
  list(records = nrow(panel))
)
