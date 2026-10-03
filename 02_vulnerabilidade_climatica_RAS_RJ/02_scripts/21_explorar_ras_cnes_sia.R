# 21_explorar_ras_cnes_sia.R
# Exploracao dos subsistemas do CNES e do SIA baixados pelo script 20, com foco
# na capacidade instalada e na producao da RAS relevantes ao cuidado do AVC:
#   - CNES-LT: leitos, com destaque para UTI adulto/neonatal/pediatrica.
#   - CNES-EQ: equipamentos de imagem (tomografia, ressonancia, angiografia).
#   - CNES-SR: servicos especializados habilitados por estabelecimento.
#   - CNES-HB: habilitacoes de alta complexidade.
#   - CNES-PF: profissionais (busca por CBO de neurologia/neurocirurgia).
#   - CNES-ST: estabelecimentos por tipo e natureza juridica.
#   - SIA-*: producao ambulatorial (procedimentos, quantidade e valor).
#
# Entradas: 01_dados/brutos_cnes_sia/*.rds (script 20)
# Saidas:   05_tabelas/tab29_ras_capacidade.csv
#           04_resultados/resultados_ras_cnes_sia.txt

suppressWarnings({
  options(stringsAsFactors = FALSE)
  library(data.table)

  ROOT <- normalizePath(".")
  DIR <- file.path(ROOT, "01_dados", "brutos_cnes_sia")
  TAB <- file.path(ROOT, "05_tabelas")
  RES <- file.path(ROOT, "04_resultados")
  dir.create(TAB, showWarnings = FALSE, recursive = TRUE)

  logcon <- file(file.path(RES, "resultados_ras_cnes_sia.txt"), open = "wt", encoding = "UTF-8")
  say <- function(...) { m <- paste0(...); cat(m, "\n"); writeLines(m, logcon); flush(logcon) }

  say("EXPLORACAO CNES/SIA - CAPACIDADE E PRODUCAO DA RAS | inicio: ", format(Sys.time()))
  fs <- sort(list.files(DIR, pattern = "[.]rds$", full.names = TRUE))
  say("arquivos encontrados: ", length(fs))
  if (!length(fs)) {
    say("Nenhum arquivo em ", DIR, ".")
    say("Rode 02_scripts/20_baixar_cnes_sia.R em rede com acesso ao FTP do DATASUS.")
    close(logcon); quit(save = "no")
  }

  ## agrupa por sistema e carrega
  carrega <- function(sis) {
    f <- fs[grepl(paste0("^", gsub("-", "_", sis), "_"), basename(fs))]
    if (!length(f)) return(NULL)
    rbindlist(lapply(f, function(x) as.data.table(readRDS(x))), fill = TRUE)
  }
  SIS <- unique(sub("_[0-9]{4}_[0-9]{2}\\.rds$", "", basename(fs)))

  res <- list()
  reg <- function(item, valor, nota = "") {
    res[[length(res) + 1]] <<- data.table(item = item, valor = as.character(valor), nota = nota)
    say(sprintf("  %-46s %s %s", item, format(valor, big.mark = "."), nota))
  }

  for (sis in SIS) {
    d <- carrega(sis)
    if (is.null(d) || !nrow(d)) next
    say("\n--- ", sis, " (", nrow(d), " registros) ---")
    say("colunas: ", paste(names(d), collapse = ", "))
    reg(paste0(sis, " - registros"), nrow(d))

    num <- function(v) suppressWarnings(as.numeric(as.character(v)))

    if (sis == "CNES_LT") {
      for (col in intersect(c("TP_LEITO", "CODLEITO", "COD_LEITO"), names(d)))
        say("  leitos por ", col, ": ", paste(capture.output(print(head(sort(table(d[[col]]), decreasing = TRUE), 10))), collapse = " | "))
      qcol <- intersect(c("QT_EXIST", "QT_SUS", "QT_LEITOS"), names(d))[1]
      if (!is.na(qcol)) reg("CNES-LT - leitos totais", sum(num(d[[qcol]]), na.rm = TRUE))
    }
    if (sis == "CNES_EQ") {
      for (col in intersect(c("TP_EQUIP", "COD_EQUIP"), names(d)))
        say("  equipamentos por ", col, ": ", paste(names(head(sort(table(d[[col]]), decreasing = TRUE), 10)), collapse = ", "))
      qcol <- intersect(c("QT_EXIST", "QT_USO"), names(d))[1]
      if (!is.na(qcol)) reg("CNES-EQ - equipamentos (quantidade)", sum(num(d[[qcol]]), na.rm = TRUE))
    }
    if (sis == "CNES_SR") {
      for (col in intersect(c("SERV_ESP", "CLASS_SR", "COD_SERV"), names(d)))
        say("  servicos por ", col, ": ", paste(names(head(sort(table(d[[col]]), decreasing = TRUE), 10)), collapse = ", "))
      reg("CNES-SR - registros de servico", nrow(d))
    }
    if (sis == "CNES_HB") {
      hcol <- intersect(c("CO_HABILITACAO", "COD_HABILITACAO"), names(d))[1]
      if (!is.na(hcol)) say("  habilitacoes: ", paste(names(head(sort(table(d[[hcol]]), decreasing = TRUE), 12)), collapse = ", "))
      reg("CNES-HB - habilitacoes", nrow(d))
    }
    if (sis == "CNES_PF") {
      ccol <- intersect(c("CBO", "CO_CBO", "CBO_2002"), names(d))[1]
      if (!is.na(ccol)) {
        cb <- head(sort(table(d[[ccol]]), decreasing = TRUE), 15)
        say("  CBO mais frequentes: ", paste(names(cb), collapse = ", "))
      }
      reg("CNES-PF - profissionais", uniqueN(d[[intersect(c("CNS_PROF","CNS"), names(d))[1]]]))
    }
    if (sis == "CNES_ST") {
      for (col in intersect(c("TP_UNID", "NAT_JUR", "TP_GESTAO"), names(d)))
        say("  ", col, ": ", paste(names(head(sort(table(d[[col]]), decreasing = TRUE), 8)), collapse = ", "))
      reg("CNES-ST - estabelecimentos", uniqueN(d[[intersect(c("CNES", "COD_CNES"), names(d))[1]]]))
    }
    if (grepl("^SIA_", sis)) {
      pcol <- intersect(c("PA_PROC_ID", "PROC_ID", "PA_PROC"), names(d))[1]
      if (!is.na(pcol)) say("  procedimentos mais frequentes: ", paste(names(head(sort(table(d[[pcol]]), decreasing = TRUE), 12)), collapse = ", "))
      qcol <- intersect(c("PA_QTDPRO", "QTDPRO"), names(d))[1]
      vcol <- intersect(c("PA_VALPRO", "VALPRO"), names(d))[1]
      if (!is.na(qcol)) reg(paste0(sis, " - producao (quantidade)"), sum(num(d[[qcol]]), na.rm = TRUE))
      if (!is.na(vcol)) reg(paste0(sis, " - producao (valor R$)"), round(sum(num(d[[vcol]]), na.rm = TRUE), 2))
    }
  }

  out <- rbindlist(res, fill = TRUE)
  fwrite(out, file.path(TAB, "tab29_ras_capacidade.csv"), encoding = "UTF-8")
  say("\nresumo gravado em 05_tabelas/tab29_ras_capacidade.csv")
  say("fim: ", format(Sys.time()))
  close(logcon)
})
