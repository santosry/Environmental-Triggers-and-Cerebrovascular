# =====================================================================
# 14_verificacao_sidra.R
# ---------------------------------------------------------------------
# Verificacao dos denominadores populacionais usados nas taxas por
# 100.000 habitantes (IBGE/SIDRA). Antes o script apenas checava a
# existencia do arquivo; agora audita a serie usada na ANALISE ATUAL:
# cobertura municipal, anos, duplicatas, populacao positiva, fontes
# (estimativa oficial, Censo 2022 e interpolacao) e consistencia com o
# lookup de municipios do RJ.
#
# Entradas:
#   ../01_DLNMs_RJ_cerebrovascular/data_processed/
#       populacao_sidra_municipio_rj_2010-2025.csv
#   ../01_DLNMs_RJ_cerebrovascular/data_processed/
#       lookup_municipio_macrorregiao.csv
#
# Saidas:
#   04_resultados/resultados_verificacao_sidra.txt
#   05_tabelas/tab27_verificacao_populacao.csv
# =====================================================================

suppressWarnings({
  options(stringsAsFactors = FALSE)
  library(data.table)

  ROOT <- normalizePath(".")
  DLNM <- file.path(dirname(ROOT), "01_DLNMs_RJ_cerebrovascular", "data_processed")
  POP_PATH <- file.path(DLNM, "populacao_sidra_municipio_rj_2010-2025.csv")
  LOOKUP <- file.path(DLNM, "lookup_municipio_macrorregiao.csv")
  RES <- file.path(ROOT, "04_resultados")
  TAB <- file.path(ROOT, "05_tabelas")

  logcon <- file(file.path(RES, "resultados_verificacao_sidra.txt"),
                 open = "wt", encoding = "UTF-8")
  say <- function(...) { m <- paste0(...); cat(m, "\n"); writeLines(m, logcon); flush(logcon) }

  res <- list()
  reg <- function(item, valor, classe, nota = "") {
    res[[length(res) + 1]] <<- data.table(item = item, valor = as.character(valor),
                                          classificacao = classe, nota = nota)
    say(sprintf("  [%-7s] %-52s %s %s", classe, item, format(valor, big.mark = "."), nota))
  }
  chk <- function(cond, item, valor, bad = "ERRO", nota = "")
    reg(item, valor, if (isTRUE(cond)) "OK" else bad, nota)

  say("=====================================================================")
  say("VERIFICACAO DOS DENOMINADORES POPULACIONAIS (IBGE/SIDRA)")
  say("R ", R.version.string, " | inicio: ", format(Sys.time()))
  say("=====================================================================")

  chk(file.exists(POP_PATH), "Arquivo de populacao existe",
      if (file.exists(POP_PATH)) "sim" else "nao")
  if (!file.exists(POP_PATH)) { close(logcon); quit(status = 1) }

  pop <- fread(POP_PATH, encoding = "UTF-8", na.strings = c("NA", ""))
  pop[, ibge6 := sprintf("%06s", as.character(ibge6))]
  pop[, ano := as.integer(ano)]
  pop[, populacao := suppressWarnings(as.numeric(populacao))]

  reg("Linhas na serie populacional", nrow(pop), "INFO")
  reg("Municipios distintos", uniqueN(pop$ibge6), "INFO")
  reg("Anos cobertos", paste(range(pop$ano), collapse = " a "), "INFO")
  chk(uniqueN(pop$ibge6) == 92, "Municipios esperados (92 do RJ)", uniqueN(pop$ibge6),
      bad = "ATENCAO")
  chk(nrow(pop) == 92L * 16L && uniqueN(pop$ano) == 16L,
      "Cobertura completa municipio x ano (92 x 16)", nrow(pop),
      nota = "esperado 1.472 linhas")
  chk(sum(is.na(pop$populacao)) == 0, "Populacao ausente", sum(is.na(pop$populacao)))
  chk(sum(pop$populacao <= 0, na.rm = TRUE) == 0, "Populacao nao positiva",
      sum(pop$populacao <= 0, na.rm = TRUE))
  dup <- sum(duplicated(pop[, .(ibge6, ano)]))
  chk(dup == 0, "Pares municipio x ano duplicados", dup)

  ## fontes e interpolacao
  if ("fonte_populacao" %in% names(pop)) {
    f <- pop[, .N, by = fonte_populacao][order(-N)]
    for (i in seq_len(nrow(f)))
      say(sprintf("      %-64s %5d", substr(f$fonte_populacao[i], 1, 64), f$N[i]))
    n_int <- sum(grepl("nterpol", pop$fonte_populacao))
    pct_int <- round(100 * n_int / nrow(pop), 2)
    reg("Registros por interpolacao linear", sprintf("%d (%.2f%%)", n_int, pct_int),
        if (pct_int < 20) "OK" else "ATENCAO",
        "anos sem estimativa oficial do IBGE")
  }

  ## consistencia com o lookup
  if (file.exists(LOOKUP)) {
    lk <- fread(LOOKUP, colClasses = "character", encoding = "UTF-8")
    lk[, ibge6 := sprintf("%06s", ibge6)]
    faltam <- setdiff(lk$ibge6, pop$ibge6)
    chk(length(faltam) == 0, "Municipios do lookup ausentes na populacao",
        length(faltam), bad = "ATENCAO", nota = paste(faltam, collapse = ", "))
    chk(length(setdiff(pop$ibge6, lk$ibge6)) == 0,
        "Municipios da populacao ausentes no lookup", length(setdiff(pop$ibge6, lk$ibge6)),
        bad = "ATENCAO")
  }

  ## populacao estadual por ano (checagem de plausibilidade)
  est <- pop[ano <= 2024, .(populacao = sum(populacao, na.rm = TRUE)), by = ano][order(ano)]
  reg("Populacao do RJ em 2010", round(est[ano == 2010, populacao]), "INFO")
  reg("Populacao do RJ em 2024", round(est[ano == 2024, populacao]), "INFO")
  va <- est[, .(ano, pop = populacao)]
  va[, cresc := c(NA, diff(pop) / head(pop, -1) * 100)]
  chk(all(abs(va$cresc[-1]) < 3), "Variacao anual da populacao abaixo de 3%",
      sprintf("max %.2f%%", max(abs(va$cresc), na.rm = TRUE)), bad = "ATENCAO")

  ## tabela de verificacao
  verif <- data.table(
    metrica = c("linhas", "municipios", "ano_min", "ano_max", "pop_2010", "pop_2024",
                "n_interpolados", "pct_interpolados", "duplicatas", "populacao_ausente"),
    valor = c(nrow(pop), uniqueN(pop$ibge6), min(pop$ano), max(pop$ano),
              round(est[ano == 2010, populacao]), round(est[ano == 2024, populacao]),
              if ("fonte_populacao" %in% names(pop)) sum(grepl("nterpol", pop$fonte_populacao)) else NA,
              if ("fonte_populacao" %in% names(pop)) round(pct_int, 2) else NA,
              dup, sum(is.na(pop$populacao))))
  fwrite(verif, file.path(TAB, "tab27_verificacao_populacao.csv"), encoding = "UTF-8")

  r <- rbindlist(res, fill = TRUE)
  say("\nresumo: ", paste(r[, .N, by = classificacao][, paste(classificacao, N, sep = "=")],
                          collapse = " | "))
  fwrite(r, file.path(TAB, "tab27_verificacao_populacao_itens.csv"), encoding = "UTF-8")
  say("fim: ", format(Sys.time()))
  close(logcon)
})
