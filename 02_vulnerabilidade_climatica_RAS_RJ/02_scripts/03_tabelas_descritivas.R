# =====================================================================
# 03_tabelas_descritivas.R
# ---------------------------------------------------------------------
# Tabelas descritivas da coorte, para o manuscrito. Le a base analitica
# gerada pelo script 02 e nao ajusta nenhum modelo.
#
#   05_tabelas/tab1_perfil_coorte.csv      perfil por desfecho
#   05_tabelas/tab2_coorte_por_regiao.csv  coorte por regiao de saude
#   05_tabelas/tab_hospitais.csv           volume e mortalidade por hospital
#
# Saida:
#   04_resultados/resultados_descritivas.txt
# =====================================================================

suppressWarnings({
  options(stringsAsFactors = FALSE)
  library(data.table)

  ROOT <- normalizePath(".")
  PROC <- file.path(ROOT, "01_dados", "processados")
  RES <- file.path(ROOT, "04_resultados")
  TAB <- file.path(ROOT, "05_tabelas")

  logcon <- file(file.path(RES, "resultados_descritivas.txt"), open = "wt", encoding = "UTF-8")
  say <- function(...) { m <- paste0(...); cat(m, "\n"); writeLines(m, logcon); flush(logcon) }

  d <- fread(file.path(PROC, "coorte_glmm_2010_2024.csv"), encoding = "UTF-8", na.strings = c("NA",""))
  say("=====================================================================")
  say("TABELAS DESCRITIVAS DA COORTE")
  say("inicio: ", format(Sys.time()))
  say("=====================================================================")
  say("internacoes: ", format(nrow(d), big.mark = "."),
      " | obitos: ", format(sum(d$obito_hospitalar), big.mark = "."),
      sprintf(" (%.2f%%)", 100 * mean(d$obito_hospitalar)))

  ## ---------------- perfil por desfecho ----------------
  d[, desfecho := factor(ifelse(obito_hospitalar == 1, "Obito", "Alta"),
                         levels = c("Alta", "Obito"))]
  mk <- function(v, nome) {
    a <- d[, .(n = .N), by = c(v)]
    b <- d[obito_hospitalar == 1, .(n_obito = .N), by = c(v)]
    t <- merge(a, b, by = v, all.x = TRUE, sort = FALSE)
    t[is.na(n_obito), n_obito := 0L]
    t[, `:=`(pct = round(100 * n / sum(n), 2),
             pct_obito = round(100 * n_obito / sum(n_obito), 2),
             mortalidade = round(100 * n_obito / n, 2))]
    setnames(t, 1, "categoria")
    t[, variavel := nome]
    t[]
  }
  t1 <- rbindlist(list(
    mk("coorte", "Coorte diagnostica"),
    mk("subtipo", "Subtipo diagnostico"),
    mk("regiao_saude", "Regiao de saude"),
    mk("sexo", "Sexo"),
    mk("car_int", "Carater da internacao"),
    mk("uti", "Uso de UTI"),
    mk("fluxo_inter", "Fluxo intermunicipal")), fill = TRUE)
  setcolorder(t1, c("variavel","categoria","n","pct","n_obito","pct_obito","mortalidade"))
  fwrite(t1, file.path(TAB, "tab1_perfil_coorte.csv"), encoding = "UTF-8")

  ## idade por desfecho
  say("\n--- IDADE POR DESFECHO ---")
  it <- d[, .(n = .N, media = round(mean(idade_anos), 1),
              mediana = median(idade_anos),
              p25 = quantile(idade_anos, .25), p75 = quantile(idade_anos, .75)),
          by = desfecho]
  for (i in seq_len(nrow(it)))
    say(sprintf("  %-6s n=%8s media=%5.1f mediana=%3.0f (P25-P75: %.0f-%.0f)",
                as.character(it$desfecho[i]), format(it$n[i], big.mark = "."),
                it$media[i], it$mediana[i], it$p25[i], it$p75[i]))

  ## ---------------- por regiao ----------------
  t2 <- d[, .(internacoes = .N, obitos = sum(obito_hospitalar),
              mortalidade_pct = round(100 * mean(obito_hospitalar), 2),
              idade_mediana = median(idade_anos),
              uti_pct = round(100 * mean(uti), 2),
              fluxo_inter_pct = round(100 * mean(fluxo_inter, na.rm = TRUE), 2),
              hospitais = uniqueN(CNES)), by = regiao_saude][order(-internacoes)]
  fwrite(t2, file.path(TAB, "tab2_coorte_por_regiao.csv"), encoding = "UTF-8")
  say("\n--- POR REGIAO DE SAUDE ---")
  for (i in seq_len(nrow(t2)))
    say(sprintf("  %-20s n=%8s obitos=%7s mortalidade=%6.2f%% UTI=%6.2f%% fluxo=%6.2f%% hospitais=%3d",
                as.character(t2$regiao_saude[i]),
                format(t2$internacoes[i], big.mark = "."),
                format(t2$obitos[i], big.mark = "."), t2$mortalidade_pct[i],
                t2$uti_pct[i], t2$fluxo_inter_pct[i], t2$hospitais[i]))

  ## ---------------- hospitais ----------------
  h <- d[, .(n = .N, obitos = sum(obito_hospitalar),
             mortalidade = round(100 * mean(obito_hospitalar), 3)), by = CNES][order(-n)]
  fwrite(h, file.path(TAB, "tab_hospitais.csv"), encoding = "UTF-8")
  say("\n--- HOSPITAIS ---")
  say("  total de CNES: ", nrow(h))
  say(sprintf("  mortalidade por hospital: P10=%.2f%% mediana=%.2f%% P90=%.2f%%",
              quantile(h$mortalidade, .10), median(h$mortalidade),
              quantile(h$mortalidade, .90)))

  say("\nfim: ", format(Sys.time()))
  close(logcon)
})
