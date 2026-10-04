# 11_reprodutibilidade/manifest_sha256.R
# Gera o manifesto de integridade (SHA-256) de entradas, código e saídas, e o
# arquivo de proveniência com o commit do Git. Serve para auditoria e para
# verificação posterior (ver verificar_manifest.R).
#
# Saídas:
#   11_reprodutibilidade/manifest_sha256.csv
#   11_reprodutibilidade/PROVENANCE.json

suppressWarnings({
  library(jsonlite)
  args <- commandArgs(trailingOnly = FALSE)
  fa <- grep("^--file=", args, value = TRUE)
  this <- if (length(fa)) normalizePath(sub("^--file=", "", fa)) else normalizePath(".")
  ROOT <- normalizePath(file.path(dirname(this), ".."))
  OUT <- file.path(ROOT, "11_reprodutibilidade")
  dir.create(OUT, showWarnings = FALSE, recursive = TRUE)
  setwd(ROOT)

  sha <- function(p) tryCatch(digest::digest(file = p, algo = "sha256"),
                              error = function(e) NA_character_)
  entradas <- c(
    "01_dados/processados/sih_cid_estudo_2014_2024.csv",
    "01_dados/processados/sim_cid_estudo_2014_2024.csv",
    "01_dados/processados/coorte_glmm_2014_2024.csv",
    "../01_DLNMs_RJ_cerebrovascular/data_processed/populacao_sidra_municipio_rj_2010-2025.csv",
    "../01_DLNMs_RJ_cerebrovascular/data_processed/lookup_municipio_macrorregiao.csv")
  gerados <- c(
    "01_dados/processados/modelo_glmm_principal_glmmTMB.rds",
    "01_dados/processados/efeitos_hospital_glmm.csv",
    "01_dados/processados/previsoes_glmm.csv")
  saidas <- c(list.files("05_tabelas", pattern = "\\.csv$", full.names = TRUE),
              list.files("04_resultados", pattern = "\\.txt$", full.names = TRUE),
              list.files("06_figuras", pattern = "\\.(png|jpg|jpeg)$", recursive = TRUE, full.names = TRUE))
  codigo <- c(list.files("02_scripts", pattern = "\\.(R|py)$", full.names = TRUE),
              list.files("11_reprodutibilidade", pattern = "\\.R$", full.names = TRUE))

  mk <- function(papel, paths) {
    paths <- paths[file.exists(paths)]
    if (!length(paths)) return(NULL)
    data.frame(papel = papel, caminho = paths,
               bytes = file.info(paths)$size,
               sha256 = vapply(paths, sha, character(1)),
               mtime = format(file.info(paths)$mtime, "%Y-%m-%d %H:%M:%S"),
               row.names = NULL, stringsAsFactors = FALSE)
  }
  man <- rbind(mk("entrada", entradas), mk("gerado", gerados),
               mk("saida", saidas), mk("codigo", codigo))
  utils::write.csv(man, file.path(OUT, "manifest_sha256.csv"), row.names = FALSE, fileEncoding = "UTF-8")

  git <- function(...) {
    r <- tryCatch(system2("git", c(...), stdout = TRUE, stderr = FALSE), error = function(e) character(0))
    if (length(r)) paste(r, collapse = " ") else NA_character_
  }
  prov <- list(
    projeto = "Morbimortalidade cerebrovascular e RAS no Rio de Janeiro",
    periodo = "2014-2024",
    data_geracao = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
    git_commit = git("rev-parse", "HEAD"),
    git_commit_curto = git("rev-parse", "--short", "HEAD"),
    git_status_limpo = identical(git("status", "--porcelain"), NA_character_) ||
      !nzchar(git("status", "--porcelain")),
    R = R.version.string, plataforma = R.version$platform,
    n_entradas = sum(man$papel == "entrada"), n_saidas = sum(man$papel == "saida"),
    n_codigo = sum(man$papel == "codigo"))
  write_json(prov, file.path(OUT, "PROVENANCE.json"), pretty = TRUE, auto_unbox = TRUE,
             encoding = "UTF-8")

  cat("manifesto:", nrow(man), "arquivos |", sum(man$papel == "entrada"), "entradas,",
      sum(man$papel == "saida"), "saidas,", sum(man$papel == "codigo"), "codigo\n")
  cat("PROVENANCE.json gerado | commit:", prov$git_commit_curto, "\n")
})
