# 11_reprodutibilidade/teste_regressao.R
# Teste de regressão: recomputa um conjunto de valores-síntese ("golden values")
# a partir dos artefatos correntes e compara com o esperado. Funciona como
# benchmark de corretude a cada execução do pipeline.
#
# Uso: Rscript 11_reprodutibilidade/teste_regressao.R
# Saída: 11_reprodutibilidade/teste_regressao_resultado.csv
#        códigos de saída: 0 = todos passam; 1 = alguma divergência.

suppressWarnings({
  library(data.table)
  args <- commandArgs(trailingOnly = FALSE)
  fa <- grep("^--file=", args, value = TRUE)
  this <- if (length(fa)) normalizePath(sub("^--file=", "", fa)) else normalizePath(".")
  ROOT <- normalizePath(file.path(dirname(this), ".."))
  OUT <- file.path(ROOT, "11_reprodutibilidade")
  setwd(ROOT)

  calc <- list()
  co <- fread("01_dados/processados/coorte_glmm_2014_2024.csv",
              encoding = "UTF-8", na.strings = c("NA", ""), select = c("obito_hospitalar", "CNES"))
  calc$n_internacoes <- nrow(co)
  calc$obitos_intra_hospitalares <- sum(co$obito_hospitalar, na.rm = TRUE)
  h <- co[, .N, by = CNES][order(-N)]
  calc$concentracao_10_hospitais_pct <- round(100 * sum(head(h$N, 10)) / nrow(co), 2)

  sim <- fread("01_dados/processados/sim_cid_estudo_2014_2024.csv",
               encoding = "UTF-8", colClasses = "character", select = c("DTOBITO"))
  calc$obitos_sim <- nrow(sim)

  t8 <- fread("05_tabelas/tab8_robustez_componentes.csv", encoding = "UTF-8")
  g <- function(cen, col) as.numeric(t8[cenario == cen][[col]][1])
  calc$icc_principal <- g("S0_principal", "ICC"); calc$mor_principal <- g("S0_principal", "MOR")
  calc$icc_sem_uti <- g("S1_sem_UTI", "ICC"); calc$icc_sem_i64 <- g("S8_sem_categoria_I64", "ICC")

  t28 <- fread("05_tabelas/tab28_padronizacao_etaria.csv", encoding = "UTF-8")
  taxa <- function(a) as.numeric(t28[regiao_saude == "ESTADO DO RJ" & tipo == "Internação" &
                                        ano == a]$taxa_bruta[1])
  calc$taxa_internacao_2014 <- taxa(2014); calc$taxa_internacao_2024 <- taxa(2024)

  t1 <- fread("05_tabelas/tab1_perfil_coorte.csv", encoding = "UTF-8")
  calc$fluxo_intermunicipal_pct <- as.numeric(t1[variavel == "Fluxo intermunicipal" & categoria == "1"]$pct)

  ta <- fread("05_tabelas/custos_deflacionados_ipca_ano.csv", encoding = "UTF-8")
  calc$custo_corrente_total <- sum(ta$custo_corrente)
  calc$custo_deflacionado_total <- sum(ta$custo_deflacionado_dez2024)

  gold <- fread(file.path(OUT, "golden_values.csv"), encoding = "UTF-8")
  res <- data.frame(indicador = gold$indicador, esperado = gold$valor_esperado,
                    obtido = NA_real_, diferenca = NA_real_, tolerancia = gold$tolerancia,
                    status = NA_character_, stringsAsFactors = FALSE)
  for (i in seq_len(nrow(res))) {
    v <- calc[[res$indicador[i]]]
    res$obtido[i] <- v
    res$diferenca[i] <- abs(v - res$esperado[i])
    res$status[i] <- if (is.null(v) || is.na(v) || is.na(res$diferenca[i])) "AUSENTE"
                     else if (res$diferenca[i] <= res$tolerancia[i]) "PASS" else "FAIL"
  }
  fwrite(res, file.path(OUT, "teste_regressao_resultado.csv"), encoding = "UTF-8")

  cat("\nTESTE DE REGRESSÃO (golden values)\n")
  for (i in seq_len(nrow(res)))
    cat(sprintf("  %-30s esperado=%15s obtido=%15s %s\n", res$indicador[i],
                format(res$esperado[i], big.mark = "."), format(round(res$obtido[i], 5), big.mark = "."),
                res$status[i]))
  nfail <- sum(res$status != "PASS")
  cat("\n", nrow(res), "indicadores |", sum(res$status == "PASS"), "PASS |", nfail, "FAIL/AUSENTE\n")
  quit(status = if (nfail > 0) 1 else 0)
})
