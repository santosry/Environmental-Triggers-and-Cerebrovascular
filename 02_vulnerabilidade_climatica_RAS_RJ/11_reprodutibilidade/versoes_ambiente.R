# 11_reprodutibilidade/versoes_ambiente.R
# Captura as versões do ambiente de execução (R, pacotes, Python) para
# reprodutibilidade e auditoria. Gera:
#   11_reprodutibilidade/versoes_pacotes_R.csv
#   11_reprodutibilidade/sessionInfo.txt
#   11_reprodutibilidade/versoes_python.csv
#   11_reprodutibilidade/requirements.txt

suppressWarnings({
  library(jsonlite)

  args <- commandArgs(trailingOnly = FALSE)
  fa <- grep("^--file=", args, value = TRUE)
  this <- if (length(fa)) normalizePath(sub("^--file=", "", fa)) else normalizePath(".")
  ROOT <- normalizePath(file.path(dirname(this), ".."))
  OUT <- file.path(ROOT, "11_reprodutibilidade")
  dir.create(OUT, showWarnings = FALSE, recursive = TRUE)

  PACOTES <- c(
    "microdatasus", "data.table", "glmmTMB", "lme4", "performance", "splines",
    "trend", "pROC", "ggplot2", "viridisLite", "scales", "patchwork", "ragg",
    "sf", "dplyr", "geobr", "jsonlite", "digest", "openssl", "sessioninfo")

  vs <- data.frame(
    pacote = PACOTES,
    versao = vapply(PACOTES, function(p)
      tryCatch(as.character(utils::packageVersion(p)), error = function(e) "ausente"),
      character(1)),
    stringsAsFactors = FALSE)
  utils::write.csv(vs, file.path(OUT, "versoes_pacotes_R.csv"), row.names = FALSE, fileEncoding = "UTF-8")

  con <- file(file.path(OUT, "sessionInfo.txt"), open = "wt", encoding = "UTF-8")
  writeLines(c(paste("R:", R.version.string),
               paste("Plataforma:", R.version$platform),
               paste("Capturado em:", format(Sys.time())),
               "", capture.output(utils::sessionInfo())), con)
  close(con)

  ## ---------------- Python ----------------
  py <- Sys.which("python")
  if (!nzchar(py)) py <- Sys.which("python3")
  versoes_py <- data.frame(pacote = character(0), versao = character(0))
  if (nzchar(py)) {
    code <- paste0(
      "import importlib.metadata as m\n",
      "for p in ['pandas','numpy','scipy','matplotlib','pymannkendall','pyreadr','python-docx','rdata']:\n",
      "    try: print(f'{p}\\t{m.version(p)}')\n",
      "    except Exception: print(f'{p}\\tausente')\n",
      "print('__PYTHON__\\t' + __import__('platform').python_version())\n")
    res <- tryCatch(system2(py, c("-c", shQuote(code)), stdout = TRUE, stderr = FALSE),
                    error = function(e) character(0))
    for (ln in res) {
      kv <- strsplit(ln, "\t", fixed = TRUE)[[1]]
      if (length(kv) == 2 && kv[1] != "__PYTHON__")
        versoes_py <- rbind(versoes_py, data.frame(pacote = kv[1], versao = kv[2],
                                                   stringsAsFactors = FALSE))
      if (length(kv) == 2 && kv[1] == "__PYTHON__")
        writeLines(paste("python", kv[2]), file.path(OUT, "versao_python.txt"))
    }
  }
  utils::write.csv(versoes_py, file.path(OUT, "versoes_python.csv"), row.names = FALSE, fileEncoding = "UTF-8")

  ## requirements.txt com versões exatas (portabilidade)
  req <- if (nrow(versoes_py))
    paste0(versoes_py$pacote, "==", versoes_py$versao) else character(0)
  writeLines(req, file.path(OUT, "requirements.txt"))

  cat("ambiente capturado em", OUT, "\n")
  cat("R", R.version.string, "| pacotes:", nrow(vs), "| python:", nrow(versoes_py), "pacotes\n")
})
