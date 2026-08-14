source("scripts/_bootstrap.R", encoding = "UTF-8")
args <- commandArgs(trailingOnly = TRUE)
pilot <- "--pilot" %in% args
years <- if (pilot) cfg$project$pilot_year_sih else validate_year_range(cfg$project$year_start, cfg$project$year_end)
files <- list.files(project_path("data-raw", "SIH"), pattern = "_raw[.]rds$", full.names = TRUE)
files <- files[grepl(paste(years, collapse = "|"), basename(files))]
shard_arg <- grep("^--shard=", args, value = TRUE)
if (length(shard_arg)) {
  shard <- as.integer(strsplit(sub("^--shard=", "", shard_arg[[1]]), "/", fixed = TRUE)[[1]])
  if (length(shard) != 2L || anyNA(shard) || shard[1] < 1L || shard[1] > shard[2]) {
    stop("Partição inválida; use --shard=N/TOTAL.")
  }
  files <- files[(seq_along(files) - 1L) %% shard[2] + 1L == shard[1]]
}
if (!length(files)) stop("Nenhum SIH bruto disponível. Execute 01_baixar_sih.R.")

for (path in files) {
  out <- project_path("data", "intermediate", sub("_raw[.]rds$", "_processed.rds", basename(path)))
  if (file.exists(out)) next
  raw <- readRDS(path)
  processed <- process_sih_extract(raw)
  flow <- compare_stage_totals(
    raw = raw, processed = processed,
    cid_i60_i69 = filter_cerebrovascular(processed, "diagnostico_principal")
  )
  filtered <- filter_cerebrovascular(processed, "diagnostico_principal")
  save_atomic_rds(processed, out)
  save_atomic_rds(filtered, project_path("data", "processed", sub("_raw[.]rds$", "_cvd.rds", basename(path))))
  write_csv_safe(flow, project_path("results", "audits", sub("_raw[.]rds$", "_flow.csv", basename(path))))
  log_event(
    "INFO", "sih_processed", "SIH processado e filtrado",
    list(source = path, n_raw = nrow(raw), n_filtered = nrow(filtered))
  )
  rm(raw, processed, filtered)
  gc()
}
