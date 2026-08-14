# Utilitários gerais -------------------------------------------------------

project_root <- function() {
  if (requireNamespace("here", quietly = TRUE)) {
    return(here::here())
  }
  normalizePath(getwd(), winslash = "/", mustWork = FALSE)
}

project_path <- function(...) file.path(project_root(), ...)

ensure_dir <- function(path) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  invisible(path)
}

timestamp_utc <- function() format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")

log_event <- function(level = "INFO", event, message, context = list(),
                      file = project_path("results", "logs", "pipeline.jsonl")) {
  ensure_dir(dirname(file))
  record <- c(list(
    timestamp_utc = timestamp_utc(), level = level,
    event = event, message = message
  ), context)
  line <- if (requireNamespace("jsonlite", quietly = TRUE)) {
    jsonlite::toJSON(record, auto_unbox = TRUE, null = "null", na = "null")
  } else {
    paste(capture.output(dput(record)), collapse = "")
  }
  cat(line, "\n", file = file, append = TRUE, sep = "")
  message(sprintf("[%s] %s: %s", level, event, message))
  invisible(record)
}

read_config <- function(path = project_path("config", "config.yml")) {
  if (!requireNamespace("yaml", quietly = TRUE)) stop("Pacote 'yaml' não instalado.")
  yaml::read_yaml(path)
}

load_project_functions <- function(path = project_path("R")) {
  files <- sort(list.files(path, pattern = "[.]R$", full.names = TRUE))
  invisible(lapply(files, source, local = .GlobalEnv, encoding = "UTF-8"))
}

standardize_names <- function(x) {
  x <- iconv(x, from = "", to = "ASCII//TRANSLIT")
  x <- tolower(gsub("[^A-Za-z0-9]+", "_", x))
  x <- gsub("^_|_$", "", x)
  make.unique(x, sep = "_")
}

normalize_cid10 <- function(x) gsub("[^A-Z0-9]", "", toupper(trimws(as.character(x))))

is_cerebrovascular_cid <- function(x, prefixes = read_config()$outcome$cid10_prefixes) {
  normalized <- normalize_cid10(x)
  included <- substr(normalized, 1L, 3L) %in% prefixes
  included[is.na(x) | is.na(normalized) | normalized == ""] <- FALSE
  included
}

filter_cerebrovascular <- function(data, column, prefixes = read_config()$outcome$cid10_prefixes) {
  if (!column %in% names(data)) stop("Coluna CID ausente: ", column)
  data[is_cerebrovascular_cid(data[[column]], prefixes), , drop = FALSE]
}

save_atomic_rds <- function(object, path, compress = "xz") {
  ensure_dir(dirname(path))
  tmp <- paste0(path, ".tmp-", Sys.getpid())
  saveRDS(object, tmp, compress = compress)
  if (!file.rename(tmp, path)) stop("Falha ao promover arquivo temporário: ", path)
  invisible(path)
}

write_csv_safe <- function(data, path) {
  ensure_dir(dirname(path))
  if (requireNamespace("readr", quietly = TRUE)) {
    readr::write_csv(data, path, na = "")
  } else {
    utils::write.csv(data, path, row.names = FALSE, fileEncoding = "UTF-8", na = "")
  }
  invisible(path)
}

with_retries <- function(operation, attempts = 3L, wait_seconds = 10, label = "operação") {
  if (!is.function(operation)) stop("'operation' deve ser uma função sem argumentos.")
  last_error <- NULL
  for (attempt in seq_len(attempts)) {
    result <- tryCatch(operation(), error = identity)
    if (!inherits(result, "error")) {
      return(result)
    }
    last_error <- result
    log_event(
      "WARN", "retry", conditionMessage(result),
      list(label = label, attempt = attempt, attempts = attempts)
    )
    if (attempt < attempts) Sys.sleep(wait_seconds * attempt)
  }
  stop(sprintf(
    "%s falhou após %d tentativas: %s", label, attempts,
    conditionMessage(last_error)
  ), call. = FALSE)
}

record_session_info <- function(path = project_path("results", "logs", "session-info.txt")) {
  ensure_dir(dirname(path))
  info <- if (requireNamespace("sessioninfo", quietly = TRUE)) {
    capture.output(sessioninfo::session_info())
  } else {
    capture.output(sessionInfo())
  }
  writeLines(c(paste("Gerado em UTC:", timestamp_utc()), info), path, useBytes = TRUE)
  invisible(path)
}

file_metadata <- function(path) {
  info <- file.info(path)
  data.frame(
    path = normalizePath(path, winslash = "/", mustWork = FALSE),
    bytes = unname(info$size), modified = as.character(info$mtime),
    md5 = unname(tools::md5sum(path)), stringsAsFactors = FALSE
  )
}

read_rds_bind <- function(files) {
  if (!length(files)) {
    return(data.frame())
  }
  objects <- lapply(files, readRDS)
  if (requireNamespace("data.table", quietly = TRUE)) {
    return(as.data.frame(data.table::rbindlist(objects, use.names = TRUE, fill = TRUE)))
  }
  all_names <- unique(unlist(lapply(objects, names)))
  objects <- lapply(objects, function(x) {
    missing <- setdiff(all_names, names(x))
    for (name in missing) x[[name]] <- NA
    x[all_names]
  })
  do.call(rbind, objects)
}
