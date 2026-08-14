source("scripts/_bootstrap.R", encoding = "UTF-8")
args <- commandArgs(trailingOnly = TRUE)
pilot <- "--pilot" %in% args
years <- if (pilot) cfg$project$pilot_year_sim else validate_year_range(cfg$project$year_start, cfg$project$year_end)
availability <- sim_availability(years, cfg$project$uf)
write_csv_safe(availability, project_path("results", "audits", "disponibilidade_sim.csv"))
failures <- integer()

for (year in years) {
  status <- availability$status[availability$year == year]
  if (!length(status) || status == "indisponivel") {
    log_event("WARN", "sim_unavailable", "SIM indisponível; nenhum dado criado", list(year = year))
    next
  }
  path <- project_path("data-raw", "SIM", sprintf("sim_do_rj_%04d_%s_raw.rds", year, status))
  if (file.exists(path)) next
  raw <- tryCatch(
    fetch_datasus_checked(year, year,
      uf = cfg$project$uf, information_system = "SIM-DO",
      attempts = cfg$download$retries, wait_seconds = cfg$download$wait_seconds,
      timeout = cfg$download$timeout_seconds
    ),
    error = identity
  )
  if (inherits(raw, "error")) {
    failures <- c(failures, year)
    log_event("ERROR", "sim_download_failed", conditionMessage(raw), list(year = year, status = status))
    next
  }
  save_atomic_rds(raw, path, compress = "gzip")
  meta <- cbind(file_metadata(path), records = nrow(raw), data_status = status)
  write_csv_safe(meta, sub("[.]rds$", "_metadata.csv", path))
  log_event(
    if (status == "preliminar") "WARN" else "INFO", "sim_downloaded",
    paste("SIM preservado com status", status), as.list(meta[1, ])
  )
  rm(raw)
  gc()
}
record_session_info()
if (length(failures)) stop("Falhas persistentes no SIM: ", paste(failures, collapse = ", "))
