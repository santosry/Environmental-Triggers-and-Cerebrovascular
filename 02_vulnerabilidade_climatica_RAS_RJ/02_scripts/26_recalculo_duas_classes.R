# 26_recalculo_duas_classes.R
# Recálculo dos indicadores descritivos do manuscrito com a coorte COMPLETA
# (I60-I69 + G45/G46), garantindo que as duas classes de códigos estejam em
# todas as análises. Substitui recortes anteriores restritos a I60-I69.
#
# Saídas:
#   04_resultados/recalculo_duas_classes.txt
#   05_tabelas/tab1b_perfil_macro_duas_classes.csv  (Tabela 1 do manuscrito)

suppressWarnings({
  options(stringsAsFactors = FALSE)
  library(data.table)
  library(trend)

  ROOT <- normalizePath(".")
  PROC <- file.path(ROOT, "01_dados", "processados")
  TAB <- file.path(ROOT, "05_tabelas")
  RES <- file.path(ROOT, "04_resultados")
  DLNM <- file.path(dirname(ROOT), "01_DLNM_RJ_cerebrovascular", "data_processed")
  if (!dir.exists(DLNM)) DLNM <- file.path(dirname(ROOT), "01_DLNMs_RJ_cerebrovascular", "data_processed")

  logcon <- file(file.path(RES, "recalculo_duas_classes.txt"), open = "wt", encoding = "UTF-8")
  say <- function(...) { m <- paste0(...); cat(m, "\n"); writeLines(m, logcon); flush(logcon) }

  say("RECALCULO COM AS DUAS CLASSES (I60-I69 + G45/G46) | ", format(Sys.time()))

  co <- fread(file.path(PROC, "coorte_glmm_2010_2024.csv"),
              encoding = "UTF-8", na.strings = c("NA", ""))
  co[, ano := as.integer(ano)]
  co[, VAL_TOT := suppressWarnings(as.numeric(VAL_TOT))]

  MACRO_MAP <- c(
    "Metropolitana I" = "Metropolitana", "Metropolitana II" = "Metropolitana",
    "Serrana" = "Centro-Sul", "Medio Paraiba" = "Centro-Sul",
    "Centro-Sul" = "Centro-Sul", "Baia da Ilha Grande" = "Centro-Sul",
    "Norte" = "Norte e Noroeste", "Noroeste" = "Norte e Noroeste",
    "Baixada Litoranea" = "Norte e Noroeste")
  co[, macro3 := unname(MACRO_MAP[as.character(regiao_saude)])]
  co[, masculino := sexo == "M"]
  co[, fluxo := fluxo_inter == 1]

  say("coorte completa: ", format(nrow(co), big.mark = "."), " internacoes")
  say("  I60-I69: ", format(sum(co$coorte == "I60-I69"), big.mark = "."),
      " | G45/G46: ", format(sum(co$coorte == "G45/G46"), big.mark = "."))
  say("  obitos intra-hospitalares: ", format(sum(co$obito_hospitalar), big.mark = "."),
      " (", sprintf("%.2f", 100 * mean(co$obito_hospitalar)), "%)")

  ## Tabela 1: perfil por macrorregiao (ambas as classes)
  t1b <- co[, .(
    Internações = .N,
    `Óbito hospitalar (%)` = sprintf("%.2f", 100 * mean(obito_hospitalar)),
    `Permanência mediana (dias)` = as.numeric(median(DIAS_PERM, na.rm = TRUE)),
    `Custo mediano (R$)` = sprintf("%.2f", median(VAL_TOT, na.rm = TRUE)),
    `Idade mediana (anos)` = as.numeric(median(idade_anos, na.rm = TRUE)),
    `Sexo masculino (%)` = sprintf("%.2f", 100 * mean(masculino, na.rm = TRUE))
  ), by = macro3]
  setcolorder(t1b, c("macro3", setdiff(names(t1b), "macro3")))
  setnames(t1b, "macro3", "Macrorregião")
  fwrite(t1b, file.path(TAB, "tab1b_perfil_macro_duas_classes.csv"), encoding = "UTF-8")
  say("\n--- Tabela 1 (macrorregiao, ambas as classes) ---")
  print(t1b)

  ## composicao diagnostica
  say("\n--- composicao diagnostica (%) ---")
  comp <- co[, .(n = .N), by = cid3][order(-n)]
  comp[, pct := sprintf("%.2f", 100 * n / nrow(co))]
  print(comp)

  ## fluxo intermunicipal
  say("\n--- fluxo intermunicipal ---")
  say("  ambas as classes: ", sprintf("%.2f%%", 100 * mean(co$fluxo, na.rm = TRUE)),
      " (", sum(co$fluxo, na.rm = TRUE), " internacoes)")
  say("  I60-I69 apenas:   ", sprintf("%.2f%%", 100 * mean(co[coorte == "I60-I69"]$fluxo, na.rm = TRUE)))

  ## municipios de residencia
  say("\n--- principais municipios de residencia ---")
  mm <- co[, .(n = .N), by = mun_nome][order(-n)][1:6]
  print(mm)

  ## concentracao por estabelecimento
  say("\n--- concentracao por estabelecimento (CNES) ---")
  he <- co[, .(n = .N), by = CNES][order(-n)]
  he[, pct_acum := 100 * cumsum(n) / nrow(co)]
  say("  10 maiores: ", sprintf("%.2f%%", he[10]$pct_acum),
      " | 20 maiores: ", sprintf("%.2f%%", he[20]$pct_acum),
      " | n estabelecimentos: ", nrow(he))

  ## custos totais (corrente e deflacionado)
  fat <- fread(file.path(TAB, "fatores_deflacao_ipca.csv"), encoding = "UTF-8")
  co <- merge(co, fat[, .(ano, fator = fator_para_dez2024_media)], by = "ano", all.x = TRUE)
  say("\n--- custos ---")
  say("  corrente:      R$ ", format(round(sum(co$VAL_TOT, na.rm = TRUE)), big.mark = "."))
  say("  deflacionado:  R$ ", format(round(sum(co$VAL_TOT * co$fator, na.rm = TRUE)), big.mark = "."))
  say("  medio corrente: R$ ", sprintf("%.2f", mean(co$VAL_TOT, na.rm = TRUE)))

  ## serie estadual de taxa de internacao (ambas as classes)
  pop <- fread(file.path(DLNM, "populacao_sidra_municipio_rj_2010-2025.csv"), encoding = "UTF-8")
  pop[, ano := as.integer(ano)][, populacao := as.numeric(populacao)]
  pop_est <- pop[ano <= 2024, .(pop = sum(populacao, na.rm = TRUE)), by = ano]
  ne <- co[, .(n = .N, obitos = sum(obito_hospitalar)), by = ano]
  se <- merge(ne, pop_est, by = "ano")[order(ano)]
  se[, taxa := 1e5 * n / pop]
  se[, letal := 100 * obitos / n]
  mk <- mk.test(se$taxa)
  say("\n--- serie estadual de internacao (ambas as classes) ---")
  say("  2010: ", sprintf("%.2f", se[ano == 2010]$taxa),
      "/100 mil | 2024: ", sprintf("%.2f", se[ano == 2024]$taxa), "/100 mil")
  say("  Mann-Kendall tau = ", sprintf("%.3f", mk$estimates[["tau"]]),
      " | p = ", sprintf("%.4f", mk$p.value))
  say("  letalidade 2010: ", sprintf("%.2f", se[ano == 2010]$letal),
      "% | 2024: ", sprintf("%.2f", se[ano == 2024]$letal), "%")

  ## taxas regionais 2024
  pop_reg <- pop[ano == 2024, .(pop = sum(populacao, na.rm = TRUE)), by = .(regiao_saude = macro_regiao)]
  nr <- co[ano == 2024, .(n = .N), by = regiao_saude]
  rr <- merge(nr, pop_reg, by = "regiao_saude"); rr[, taxa := 1e5 * n / pop]
  setorder(rr, taxa)
  say("\n--- taxas de internacao regionais 2024 (ambas as classes) ---")
  print(rr[, .(regiao_saude, n, pop, taxa = round(taxa, 1))])
  say("  faixa: ", sprintf("%.1f", min(rr$taxa)), " a ", sprintf("%.1f", max(rr$taxa)), "/100 mil")

  say("\nfim: ", format(Sys.time()))
  close(logcon)
})
