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
# FILTRAGEM POR CID DO ESTUDO (CSV versionado):
#   Depois do download, os .rds sao varridos uma unica vez para extrair
#   apenas os codigos CID de interesse do estudo, gravando um recorte leve
#   em CSV. Os .rds brutos sao volumosos (~480 MB) e nao entram no Git;
#   o CSV filtrado entra no repositorio para que as contagens possam ser
#   conferidas sem reprocessar os microdados completos.
#     SIH: DIAG_PRINC em I60-I69, G45 ou G46, residentes no RJ (33),
#          DT_INTER de 2010 a 2024.
#     SIM: CAUSABAS em I60-I69, residentes no RJ (33),
#          DTOBITO de 2010 a 2024.
#
# Saidas:
#   01_dados/brutos_sih/sih_rd_rj_{ano}_{mes}.rds
#   01_dados/brutos_sim/sim_do_rj_{ano}.rds
#   01_dados/processados/sih_cid_estudo_2010_2024.csv
#   01_dados/processados/sim_cid_estudo_2010_2024.csv
#   03_analises/log_microdatasus.txt
# =====================================================================

suppressWarnings({
  library(microdatasus)
  library(data.table)

  ROOT <- normalizePath(".")
  DIR_SIH <- file.path(ROOT, "01_dados", "brutos_sih")
  DIR_SIM <- file.path(ROOT, "01_dados", "brutos_sim")
  DIR_PROC <- file.path(ROOT, "01_dados", "processados")
  dir.create(DIR_SIH, showWarnings = FALSE, recursive = TRUE)
  dir.create(DIR_SIM, showWarnings = FALSE, recursive = TRUE)
  dir.create(DIR_PROC, showWarnings = FALSE, recursive = TRUE)

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

  ## ---------------- filtragem por CID do estudo (CSV) ----------------
  ## Recorte versionavel: apenas os diagnosticos do estudo, residentes no RJ e
  ## dentro do periodo analitico. As colunas essenciais do estudo sao mantidas;
  ## os nove diagnosticos secundarios e demais campos exploratorios permanecem
  ## nos .rds brutos, que sao a fonte para o script 02.
  say("\n=========== FILTRAGEM POR CID DO ESTUDO (CSV) ===========")

  CODIGOS_I <- sprintf("I6%d", 0:9)
  G_BLOCO <- c("G45", "G46")

  SIH_KEEP <- c("N_AIH", "IDENT", "DT_INTER", "DT_SAIDA", "DIAG_PRINC",
                "MUNIC_RES", "MUNIC_MOV", "SEXO", "IDADE", "COD_IDADE",
                "CNES", "MORTE", "CAR_INT", "RACA_COR", "INSTRU",
                "UTI_MES_TO", "MARCA_UTI", "DIAS_PERM", "VAL_TOT",
                "COMPLEX", "NAT_JUR")
  SIM_KEEP <- c("DTOBITO", "IDADE", "SEXO", "RACACOR", "LOCOCOR",
                "CODMUNRES", "CAUSABAS")

  dest_sih <- file.path(DIR_PROC, "sih_cid_estudo_2010_2024.csv")
  dest_sim <- file.path(DIR_PROC, "sim_cid_estudo_2010_2024.csv")

  ## Refaz o recorte se o CSV nao existir ou se algum .rds for mais novo.
  precisa_refazer <- function(destino, fontes) {
    if (!file.exists(destino)) return(TRUE)
    if (!length(fontes)) return(FALSE)
    any(file.info(fontes)$mtime > file.info(destino)$mtime, na.rm = TRUE)
  }

  ## ---------------- SIH ----------------
  fs_sih <- sort(list.files(DIR_SIH, pattern = "^sih_rd_rj_[0-9]{4}_[0-9]{2}\\.rds$",
                            full.names = TRUE))
  if (precisa_refazer(dest_sih, fs_sih)) {
    acc <- vector("list", length(fs_sih)); n_bruto <- 0L; n_cid <- 0L; n_rj <- 0L
    for (i in seq_along(fs_sih)) {
      d <- readRDS(fs_sih[i])
      n_bruto <- n_bruto + nrow(d)
      cid <- toupper(trimws(as.character(d[["DIAG_PRINC"]])))
      cid3 <- substr(cid, 1, 3)
      sel <- cid3 %in% CODIGOS_I | cid3 %in% G_BLOCO
      n_cid <- n_cid + sum(sel)
      dd <- d[sel, intersect(SIH_KEEP, names(d)), drop = FALSE]
      muni_res <- sprintf("%06s", as.character(dd[["MUNIC_RES"]]))
      dd <- dd[substr(muni_res, 1, 2) == "33", , drop = FALSE]
      dt_i <- suppressWarnings(as.Date(as.character(dd[["DT_INTER"]]), format = "%Y%m%d"))
      dd <- dd[!is.na(dt_i) & dt_i >= as.Date("2010-01-01") & dt_i <= as.Date("2024-12-31"), , drop = FALSE]
      n_rj <- n_rj + nrow(dd)
      if (nrow(dd)) acc[[i]] <- dd
      if (i %% 40 == 0 || i == length(fs_sih))
        say(sprintf("  SIH %3d/%d | brutos=%s | CID estudo=%s | recorte final=%s",
                    i, length(fs_sih), format(n_bruto, big.mark = "."),
                    format(n_cid, big.mark = "."), format(n_rj, big.mark = ".")))
    }
    sih_f <- rbindlist(acc[!vapply(acc, is.null, logical(1))], use.names = TRUE, fill = TRUE)
    fwrite(sih_f, dest_sih, encoding = "UTF-8", na = "NA")
    say("  gravado: ", dest_sih, " | linhas: ", format(nrow(sih_f), big.mark = "."),
        " | colunas: ", ncol(sih_f), " | ", round(file.info(dest_sih)$size / 1024^2, 1), " MB")
    say("  criterios: DIAG_PRINC I60-I69/G45/G46 + MUNIC_RES RJ + DT_INTER 2010-2024")
  } else say("  SIH ja atualizado: ", dest_sih)

  ## ---------------- SIM ----------------
  fs_sim <- sort(list.files(DIR_SIM, pattern = "^sim_do_rj_[0-9]{4}\\.rds$",
                            full.names = TRUE))
  if (precisa_refazer(dest_sim, fs_sim)) {
    acc <- vector("list", length(fs_sim)); n_bruto2 <- 0L; n_cid2 <- 0L
    for (i in seq_along(fs_sim)) {
      d <- readRDS(fs_sim[i])
      n_bruto2 <- n_bruto2 + nrow(d)
      cb <- toupper(trimws(as.character(d[["CAUSABAS"]])))
      cb3 <- substr(cb, 1, 3)
      muni <- sprintf("%06s", as.character(d[["CODMUNRES"]]))
      sel <- cb3 %in% CODIGOS_I & substr(muni, 1, 2) == "33"
      n_cid2 <- n_cid2 + sum(sel)
      if (any(sel)) {
        dd <- d[sel, intersect(SIM_KEEP, names(d)), drop = FALSE]
        dt_o <- suppressWarnings(as.Date(as.character(dd[["DTOBITO"]]), format = "%d%m%Y"))
        dd <- dd[!is.na(dt_o) & dt_o >= as.Date("2010-01-01") & dt_o <= as.Date("2024-12-31"), , drop = FALSE]
        if (nrow(dd)) acc[[i]] <- dd
      }
    }
    sim_f <- rbindlist(acc[!vapply(acc, is.null, logical(1))], use.names = TRUE, fill = TRUE)
    fwrite(sim_f, dest_sim, encoding = "UTF-8", na = "NA")
    say("  gravado: ", dest_sim, " | linhas: ", format(nrow(sim_f), big.mark = "."),
        " | colunas: ", ncol(sim_f), " | ", round(file.info(dest_sim)$size / 1024^2, 1), " MB")
    say("  criterios: CAUSABAS I60-I69 + CODMUNRES RJ + DTOBITO 2010-2024")
  } else say("  SIM ja atualizado: ", dest_sim)

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
