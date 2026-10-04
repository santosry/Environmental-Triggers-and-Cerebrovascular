# 11_reprodutibilidade/verificar_manifest.R
# Verifica a integridade das saídas contra o manifesto SHA-256 previamente
# gravado. Retorna status por arquivo (OK, DIVERGENTE, AUSENTE) e um resumo.
# Sai com código diferente de zero se houver divergência ou ausência.
#
# Uso: Rscript 11_reprodutibilidade/verificar_manifest.R

suppressWarnings({
  args <- commandArgs(trailingOnly = FALSE)
  fa <- grep("^--file=", args, value = TRUE)
  this <- if (length(fa)) normalizePath(sub("^--file=", "", fa)) else normalizePath(".")
  ROOT <- normalizePath(file.path(dirname(this), ".."))
  OUT <- file.path(ROOT, "11_reprodutibilidade")
  setwd(ROOT)

  man_path <- file.path(OUT, "manifest_sha256.csv")
  if (!file.exists(man_path)) stop("manifest_sha256.csv ausente: rode manifest_sha256.R antes.")
  man <- utils::read.csv(man_path, stringsAsFactors = FALSE, fileEncoding = "UTF-8")

  sha <- function(p) tryCatch(digest::digest(file = p, algo = "sha256"),
                              error = function(e) NA_character_)
  atual <- vapply(man$caminho, sha, character(1))
  man$status <- ifelse(is.na(atual), "AUSENTE",
                ifelse(atual == man$sha256, "OK", "DIVERGENTE"))
  utils::write.csv(man, file.path(OUT, "manifest_verificacao.csv"),
                   row.names = FALSE, fileEncoding = "UTF-8")

  tab <- table(man$status)
  cat("verificação do manifesto:\n")
  for (nm in names(tab)) cat(sprintf("  %-12s %d\n", nm, tab[[nm]]))
  div <- man[man$status != "OK", ]
  if (nrow(div)) {
    cat("\narquivos com problema:\n")
    for (i in seq_len(nrow(div))) cat("  ", div$status[i], "-", div$caminho[i], "\n")
    quit(status = 1)
  }
  cat("todos os arquivos conferem.\n")
})
