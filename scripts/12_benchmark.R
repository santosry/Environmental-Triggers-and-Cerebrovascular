source("scripts/_bootstrap.R", encoding = "UTF-8")
files <- list.files(project_path("data", "processed"), pattern = "_cvd[.]rds$", full.names = TRUE)
if (!length(files)) stop("Benchmark requer ao menos uma base processada.")
set.seed(42)
target_rows <- 100000L
rows_per_file <- max(1L, ceiling(target_rows / length(files)))
pieces <- lapply(files, function(path) {
  x <- readRDS(path)
  x[sample.int(nrow(x), min(nrow(x), rows_per_file)), , drop = FALSE]
})
sample <- as.data.frame(data.table::rbindlist(pieces, use.names = TRUE, fill = TRUE))
if (nrow(sample) > target_rows) sample <- sample[sample.int(nrow(sample), target_rows), , drop = FALSE]
bench_dir <- project_path("work", "benchmark")
ensure_dir(bench_dir)
paths <- c(
  rds = file.path(bench_dir, "sample.rds"),
  csv_gz = file.path(bench_dir, "sample.csv.gz"),
  parquet = file.path(bench_dir, "sample.parquet")
)

timings <- list()
timings$rds_write <- system.time(saveRDS(sample, paths[["rds"]]))[["elapsed"]]
timings$readr_write <- system.time(readr::write_csv(sample, paths[["csv_gz"]]))[["elapsed"]]
if (requireNamespace("arrow", quietly = TRUE)) {
  timings$parquet_write <- system.time(
    arrow::write_parquet(sample, paths[["parquet"]])
  )[["elapsed"]]
}
timings$rds_read <- system.time(rds_read <- readRDS(paths[["rds"]]))[["elapsed"]]
timings$readr_read <- system.time(
  readr_read <- suppressWarnings(readr::read_csv(paths[["csv_gz"]], show_col_types = FALSE))
)[["elapsed"]]
timings$data_table_read <- system.time(
  data_table_read <- data.table::fread(paths[["csv_gz"]], showProgress = FALSE)
)[["elapsed"]]
if (file.exists(paths[["parquet"]])) {
  timings$parquet_read <- system.time(
    parquet_read <- arrow::read_parquet(paths[["parquet"]])
  )[["elapsed"]]
}
result <- data.frame(
  operation = names(timings), elapsed_seconds = unlist(timings),
  sample_rows = nrow(sample), sample_memory_bytes = as.numeric(object.size(sample)),
  source_files = length(files)
)
write_csv_safe(result, project_path("results", "audits", "benchmark_tempo_memoria.csv"))
sizes <- data.frame(
  format = names(paths), path = unname(paths),
  bytes = vapply(paths, function(p) if (file.exists(p)) file.info(p)$size else NA_real_, numeric(1))
)
write_csv_safe(sizes, project_path("results", "audits", "benchmark_tamanho_arquivos.csv"))
integrity <- data.frame(
  format = c("rds", "csv_gz_readr", "csv_gz_data_table", "parquet"),
  rows = c(nrow(rds_read), nrow(readr_read), nrow(data_table_read), nrow(parquet_read)),
  columns = c(ncol(rds_read), ncol(readr_read), ncol(data_table_read), ncol(parquet_read)),
  parsing_problems = c(0L, nrow(readr::problems(readr_read)), NA_integer_, NA_integer_),
  exact_r_identity = c(identical(sample, rds_read), FALSE, FALSE, FALSE)
)
write_csv_safe(integrity, project_path("results", "audits", "benchmark_integridade.csv"))
record_session_info(project_path("results", "logs", "benchmark-session-info.txt"))
