# 15_deflacao_ipca.R
# Deflação dos custos assistenciais (SIH-RD, VAL_TOT) para reais de
# dezembro de 2024 pelo IPCA (IBGE), a partir da série de número-índice
# mensal (SIDRA tabela 1737, variável 2266).
#
# Faz parte da ANÁLISE ATUAL: le a coorte analítica já consolidada
# (01_dados/processados/coorte_glmm_2010_2024.csv) e não depende mais do
# antigo arquivo de consolidacao (sih_cerebrovascular_2010_2024.csv).
# O recorte de custo e I60-I69, para manter a mesma base histórica dos
# indicadores de custo do manuscrito; os blocos G45/G46 (AIT e sindromes
# vasculares) ficam fora dos custos, como nas demais séries descritivas.
#
# Método
#   1. Série mensal do número-índice do IPCA (base: dez/1993 = 100).
#   2. Fator de correção para dez/2024 de cada ano t (fluxo anual):
#        fator(t) = indice_dez2024 / indice_medio_anual(t).
#   3. Custo deflacionado = VAL_TOT * fator(ano).
#
# Entradas:
#   01_dados/processados/coorte_glmm_2010_2024.csv
#   01_dados/tmp_ipca/ipca_1737_2266.json
#
# Saídas:
#   05_tabelas/fatores_deflacao_ipca.csv
#   05_tabelas/custos_deflacionados_ipca_macro.csv
#   05_tabelas/custos_deflacionados_ipca_regiao.csv
#   05_tabelas/custos_deflacionados_ipca_ano.csv
#   04_resultados/resultados_deflacao_ipca.txt

suppressWarnings({
  options(stringsAsFactors = FALSE)
  library(data.table)
  library(jsonlite)

  ROOT <- normalizePath(".")
  PROC <- file.path(ROOT, "01_dados", "processados")
  IPCA_JSON <- file.path(ROOT, "01_dados", "tmp_ipca", "ipca_1737_2266.json")
  TAB <- file.path(ROOT, "05_tabelas")
  RES <- file.path(ROOT, "04_resultados")
  BASE_YM <- "202412"  # referência: dezembro de 2024

  logcon <- file(file.path(RES, "resultados_deflacao_ipca.txt"),
                 open = "wt", encoding = "UTF-8")
  say <- function(...) { m <- paste0(...); cat(m, "\n"); writeLines(m, logcon); flush(logcon) }

  say("=====================================================================")
  say("DEFLACAO DOS CUSTOS PELO IPCA (base: dezembro/2024)")
  say("Fonte: IBGE/SIDRA tabela 1737, variavel 2266 (numero-indice mensal)")
  say("Fator: indice_dez2024 / indice_medio_anual(t)  [fluxo anual -> dez/2024]")
  say("R ", R.version.string, " | inicio: ", format(Sys.time()))
  say("=====================================================================")

  ## ---------------- 1. IPCA ----------------
  raw <- fromJSON(IPCA_JSON, simplifyDataFrame = TRUE)
  raw <- as.data.table(raw)
  raw <- raw[D3C != "Mês (Código)" & grepl("^[0-9]{6}$", D3C)]
  raw[, `:=`(ym = as.character(D3C), indice = as.numeric(V))]
  setorder(raw, ym)
  say("meses do IPCA lidos: ", nrow(raw), " | de ", raw$ym[1], " a ", raw$ym[nrow(raw)])
  base_index <- raw[ym == BASE_YM, indice]
  if (!length(base_index)) stop("mes de referencia ausente na serie do IPCA: ", BASE_YM)

  fat <- raw[, .(indice_medio_ano = mean(indice),
                 indice_dez_ano = indice[which.max(ym)]), by = .(ano = as.integer(substr(ym, 1, 4)))]
  fat[, fator_para_dez2024_media := base_index / indice_medio_ano]
  fat[, fator_para_dez2024_dez_dez := base_index / indice_dez_ano]
  setorder(fat, ano)

  ## ---------------- 2. coorte ----------------
  co <- fread(file.path(PROC, "coorte_glmm_2010_2024.csv"),
              encoding = "UTF-8", na.strings = c("NA", ""),
              select = c("ano", "regiao_saude", "coorte", "cid3", "VAL_TOT"))
  co <- co[coorte == "I60-I69"]

  MACRO_MAP <- c(
    "Metropolitana I" = "Metropolitana", "Metropolitana II" = "Metropolitana",
    "Serrana" = "Centro-Sul", "Medio Paraiba" = "Centro-Sul",
    "Centro-Sul" = "Centro-Sul", "Baia da Ilha Grande" = "Centro-Sul",
    "Norte" = "Norte e Noroeste", "Noroeste" = "Norte e Noroeste",
    "Baixada Litoranea" = "Norte e Noroeste")
  co[, macro3 := unname(MACRO_MAP[as.character(regiao_saude)])]
  co[, VAL_TOT := suppressWarnings(as.numeric(VAL_TOT))]
  co[, ano := as.integer(ano)]
  co <- merge(co, fat[, .(ano, fator_para_dez2024_media)], by = "ano", all.x = TRUE)
  co[, custo_deflacionado := VAL_TOT * fator_para_dez2024_media]

  ## ---------------- 3. agregacoes ----------------
  agg <- function(key) {
    out <- co[, .(n_internacoes = .N,
                  custo_corrente = sum(VAL_TOT, na.rm = TRUE),
                  custo_deflacionado_dez2024 = sum(custo_deflacionado, na.rm = TRUE)),
              by = key]
    out[, custo_medio_deflacionado := custo_deflacionado_dez2024 / n_internacoes]
    setorderv(out, "custo_deflacionado_dez2024", order = -1L)
    out
  }
  por_macro <- agg("macro3")
  por_regiao <- agg("regiao_saude")
  por_ano <- co[, .(custo_corrente = sum(VAL_TOT, na.rm = TRUE),
                    custo_deflacionado_dez2024 = sum(custo_deflacionado, na.rm = TRUE)),
                by = .(ano)][order(ano)]

  total_corrente <- sum(co$VAL_TOT, na.rm = TRUE)
  total_defl <- sum(co$custo_deflacionado, na.rm = TRUE)

  fwrite(fat, file.path(TAB, "fatores_deflacao_ipca.csv"), encoding = "UTF-8")
  fwrite(por_macro, file.path(TAB, "custos_deflacionados_ipca_macro.csv"), encoding = "UTF-8")
  fwrite(por_regiao, file.path(TAB, "custos_deflacionados_ipca_regiao.csv"), encoding = "UTF-8")
  fwrite(por_ano, file.path(TAB, "custos_deflacionados_ipca_ano.csv"), encoding = "UTF-8")

  ## ---------------- 4. relatório ----------------
  say("")
  say(sprintf("Custo total corrente (2010-2024):        R$ %s", format(round(total_corrente, 2), big.mark = ".", decimal.mark = ",")))
  say(sprintf("Custo total deflacionado (dez/2024):     R$ %s", format(round(total_defl, 2), big.mark = ".", decimal.mark = ",")))
  say(sprintf("Inflacao acumulada implicita 2010-2024:  %.1f%%",
              100 * (fat[ano == 2010, fator_para_dez2024_media] - 1)))
  say("")
  say("Fatores de deflacao por ano:")
  for (i in seq_len(nrow(fat)))
    say(sprintf("  %d  indice_medio=%10.4f  fator_media=%6.4f  fator_dez=%6.4f",
                fat$ano[i], fat$indice_medio_ano[i],
                fat$fator_para_dez2024_media[i], fat$fator_para_dez2024_dez_dez[i]))
  say("")
  say("Custo por macrorregiao (corrente e deflacionado a dez/2024):")
  for (i in seq_len(nrow(por_macro)))
    say(sprintf("  %-18s n=%9s corrente=R$ %14s deflac=R$ %14s",
                por_macro$macro3[i], format(por_macro$n_internacoes[i], big.mark = "."),
                format(round(por_macro$custo_corrente[i]), big.mark = "."),
                format(round(por_macro$custo_deflacionado_dez2024[i]), big.mark = ".")))
  say("")
  say("Custo por regiao de saude (corrente e deflacionado a dez/2024):")
  for (i in seq_len(nrow(por_regiao)))
    say(sprintf("  %-22s n=%9s corrente=R$ %14s deflac=R$ %14s",
                por_regiao$regiao_saude[i], format(por_regiao$n_internacoes[i], big.mark = "."),
                format(round(por_regiao$custo_corrente[i]), big.mark = "."),
                format(round(por_regiao$custo_deflacionado_dez2024[i]), big.mark = ".")))
  say("")
  say("Nota: recorte I60-I69 da coorte (mesma base dos indicadores de custo do")
  say("      manuscrito). Serie do IPCA em cache local; fatores pelo indice medio anual.")
  say("fim: ", format(Sys.time()))
  close(logcon)
})
