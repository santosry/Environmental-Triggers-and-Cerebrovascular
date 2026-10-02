# =====================================================================
# 01_baixar_microdatasus.R
# ---------------------------------------------------------------------
# PRIMEIRO PASSO DA CADEIA. Aquisicao dos microdados direto da fonte, com
# o pacote microdatasus.
#
# SIH-RD: competicoes 2010-01 a 2025-12 do estado do RJ (192 arquivos).
#   Os arquivos do SIH-RD sao estaduais e por competencia: NAO existe
#   filtro por CID no download. O arquivo traz todos os capitulos da
#   CID-10, incluindo G45 e G46 e tambem I60 a I69, que sao filtrados
#   depois, no script 02. Baixar 2025 e necessario porque a competencia de
#   processamento pode deslocar internacoes de dezembro de 2024 para
#   janeiro de 2025; o filtro final do estudo continua sendo DT_INTER
#   entre 2010 e 2024.
#
# SIM-DO: obitos por residencia no RJ, 2010 a 2024 (15 arquivos), usado
#   para o Indice de Swaroop-Uemura no script 04.
#
# Fonte registrada no log (padrao confirmado):
#   ftp://ftp.datasus.gov.br/dissemin/publicos/SIHSUS/200801_/Dados/RDRJ{aamm}.dbc
#
# Saidas:
#   01_dados/brutos_sih/sih_rd_rj_{ano}_{mes}.rds
#   01_dados/brutos_sim/sim_do_rj_{ano}.rds
#   03_analises/log_microdatasus.txt
# =====================================================================

suppressWarnings({
  library(microdatasus)

  ROOT <- normalizePath(".")
  DIR_SIH <- file.path(ROOT, "01_dados", "brutos_sih")
  DIR_SIM <- file.path(ROOT, "01_dados", "brutos_sim")
  dir.create(DIR_SIH, showWarnings = FALSE, recursive = TRUE)
  dir.create(DIR_SIM, showWarnings = FALSE, recursive = TRUE)

  logcon <- file(file.path(ROOT, "03_analises", "log_microdatasus.txt"),
                 open = "wt", encoding = "UTF-8")
  say <- function(...) { m <- paste0(...); cat(m, "\n"); writeLines(m, logcon); flush(logcon) }

  say("=====================================================================")
  say("AQUISICAO VIA microdatasus ", as.character(packageVersion("microdatasus")))
  say("R ", R.version.string)
  say("inicio: ", format(Sys.time()))
  say("SIH-RD RJ: competicoes 2010-01 a 2025-12")
  say("SIM-DO RJ: 2010 a 2024")
  say("fonte SIH-RD: ftp://ftp.datasus.gov.br/dissemin/publicos/SIHSUS/200801_/Dados/RDRJ{aamm}.dbc")
  say("=====================================================================")

  baixar <- function(expr, tentativas = 4, pausa = 20) {
    for (k in seq_len(tentativas)) {
      r <- tryCatch(expr(), error = function(e) e)
      if (!inherits(r, "error")) return(r)
      say("    tentativa ", k, " falhou: ", conditionMessage(r))
      Sys.sleep(pausa)
    }
    NULL
  }

  ## ---------------- SIH-RD ----------------
  say("\n=========== SIH-RD ===========")
  t0 <- Sys.time()
  ok <- 0L; falhas <- character(0); pulados <- 0L
  comps <- expand.grid(ano = 2010:2025, mes = 1:12)
  comps <- comps[order(comps$ano, comps$mes), ]

  for (i in seq_len(nrow(comps))) {
    ano <- comps$ano[i]; mes <- comps$mes[i]
    dest <- file.path(DIR_SIH, sprintf("sih_rd_rj_%d_%02d.rds", ano, mes))
    if (file.exists(dest)) { pulados <- pulados + 1L; next }
    d <- baixar(function() microdatasus::fetch_datasus(
      year_start = ano, month_start = mes, year_end = ano, month_end = mes,
      uf = "RJ", information_system = "SIH-RD"))
    if (is.null(d)) {
      falhas <- c(falhas, sprintf("%d-%02d", ano, mes))
      say("  FALHA ", ano, "-", sprintf("%02d", mes))
      next
    }
    saveRDS(d, dest)
    ok <- ok + 1L
    if (ok %% 12 == 0 || i == nrow(comps))
      say(sprintf("  %3d/%d | baixados=%d | pulados=%d | falhas=%d | %.1f min",
                  i, nrow(comps), ok, pulados, length(falhas),
                  as.numeric(difftime(Sys.time(), t0, units = "mins"))))
  }
  say(sprintf("\nSIH-RD concluido: %d baixados, %d ja existiam, %d falhas (%.1f min)",
              ok, pulados, length(falhas),
              as.numeric(difftime(Sys.time(), t0, units = "mins"))))
  if (length(falhas)) say("competencias com falha: ", paste(falhas, collapse = ", "))

  ## ---------------- SIM-DO ----------------
  say("\n=========== SIM-DO ===========")
  t1 <- Sys.time()
  ok2 <- 0L; falhas2 <- character(0); pulados2 <- 0L
  for (ano in 2010:2024) {
    dest <- file.path(DIR_SIM, sprintf("sim_do_rj_%d.rds", ano))
    if (file.exists(dest)) { pulados2 <- pulados2 + 1L; next }
    d <- baixar(function() microdatasus::fetch_datasus(
      year_start = ano, year_end = ano, uf = "RJ", information_system = "SIM-DO"))
    if (is.null(d)) { falhas2 <- c(falhas2, as.character(ano)); say("  FALHA ", ano); next }
    saveRDS(d, dest)
    ok2 <- ok2 + 1L
    say(sprintf("  %d baixado (%d linhas)", ano, nrow(d)))
  }
  say(sprintf("\nSIM-DO concluido: %d baixados, %d ja existiam, %d falhas (%.1f min)",
              ok2, pulados2, length(falhas2),
              as.numeric(difftime(Sys.time(), t1, units = "mins"))))
  if (length(falhas2)) say("anos com falha: ", paste(falhas2, collapse = ", "))

  ## ---------------- inventario ----------------
  say("\n=========== INVENTARIO ===========")
  fs <- list.files(DIR_SIH, pattern = "\\.rds$", full.names = TRUE)
  say("arquivos SIH-RD: ", length(fs))
  say("tamanho total (MB): ", round(sum(file.info(fs)$size) / 1024^2, 1))
  fm <- list.files(DIR_SIM, pattern = "\\.rds$", full.names = TRUE)
  say("arquivos SIM-DO: ", length(fm), " | tamanho (MB): ",
      round(sum(file.info(fm)$size) / 1024^2, 1))

  say("\nfim: ", format(Sys.time()))
  close(logcon)
})
