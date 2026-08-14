source("scripts/_bootstrap.R", encoding = "UTF-8")
args <- commandArgs(trailingOnly = TRUE)
pilot <- "--pilot" %in% args
years <- if (pilot) cfg$project$pilot_year_sih else validate_year_range(cfg$project$year_start, cfg$project$year_end)
availability <- sih_availability(years)
write_csv_safe(availability, project_path("results", "audits", "disponibilidade_sih.csv"))
failures <- character()

for (i in seq_len(nrow(availability))) {
  item <- availability[i, ]
  if (item$status != "disponivel") {
    log_event("WARN", "sih_unavailable", "Arquivo mensal indisponível", as.list(item))
    next
  }
  path <- project_path("data-raw", "SIH", sprintf("sih_rd_rj_%04d_%02d_raw.rds", item$year, item$month))
  if (file.exists(path)) {
    log_event("INFO", "sih_skip", "Arquivo bruto já existe", list(path = path))
    next
  }
  started <- Sys.time()
  raw <- tryCatch(
    fetch_datasus_checked(
      item$year, item$year, item$month, item$month,
      cfg$project$uf, "SIH-RD", cfg$download$retries,
      cfg$download$wait_seconds, cfg$download$timeout_seconds
    ),
    error = identity
  )
  if (inherits(raw, "error")) {
    period <- sprintf("%04d-%02d", item$year, item$month)
    failures <- c(failures, period)
    log_event("ERROR", "sih_download_failed", conditionMessage(raw), list(period = period))
    next
  }
  save_atomic_rds(raw, path, compress = "gzip")
  meta <- cbind(
    file_metadata(path),
    records = nrow(raw),
    elapsed_seconds = as.numeric(difftime(Sys.time(), started, units = "secs"))
  )
  write_csv_safe(meta, sub("[.]rds$", "_metadata.csv", path))
  log_event("INFO", "sih_downloaded", "Extrato mensal preservado", as.list(meta[1, ]))
  rm(raw)
  gc()
}
record_session_info()
if (length(failures)) stop("Falhas persistentes no SIH: ", paste(failures, collapse = ", "))
