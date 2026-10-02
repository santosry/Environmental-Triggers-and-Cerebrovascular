# =====================================================================
# 07_auditoria_consistencia.R
# ---------------------------------------------------------------------
# Auditoria de incongruencias e inconsistencias, em quatro blocos:
#
#   A. coerencia interna dos registros brutos do SIH-RD (191 competicoes,
#      em varredura, sem carregar tudo em memoria);
#   B. coerencia da coorte analitica e das derivadas;
#   C. triangulacao entre SIH (internacoes) e SIM (obitos), que sao fontes
#      independentes;
#   D. coerencia do modelo ajustado, da correcao de FDR e das tabelas
#      publicadas.
#
# Cada verificacao recebe uma classificacao:
#   OK       valor dentro do esperado
#   ATENCAO  valor que exige leitura, mas tem explicacao conhecida
#   ERRO     valor que indica defeito e precisa de correcao
#
# Saidas:
#   04_resultados/auditoria_consistencia.txt
#   05_tabelas/tab19_auditoria.csv
# =====================================================================

suppressWarnings({
  options(stringsAsFactors = FALSE)
  library(data.table)

  ROOT <- normalizePath(".")
  DIR_SIH <- file.path(ROOT, "01_dados", "brutos_sih")
  DIR_SIM <- file.path(ROOT, "01_dados", "brutos_sim")
  PROC <- file.path(ROOT, "01_dados", "processados")
  RES <- file.path(ROOT, "04_resultados")
  TAB <- file.path(ROOT, "05_tabelas")

  logcon <- file(file.path(RES, "auditoria_consistencia.txt"), open = "wt", encoding = "UTF-8")
  say <- function(...) { m <- paste0(...); cat(m, "\n"); writeLines(m, logcon); flush(logcon) }

  res <- list()
  reg <- function(bloco, item, valor, classe, nota = "") {
    res[[length(res) + 1]] <<- data.table(bloco = bloco, item = item,
                                          valor = as.character(valor),
                                          classificacao = classe, nota = nota)
    say(sprintf("  [%-7s] %-56s %s %s", classe, item, format(valor, big.mark = "."), nota))
  }

  say("=====================================================================")
  say("AUDITORIA DE INCONGRUENCIAS E INCONSISTENCIAS")
  say("R ", R.version.string, " | inicio: ", format(Sys.time()))
  say("=====================================================================")

  ## ==================================================================
  ## A. COERENCIA INTERNA DOS REGISTROS BRUTOS DO SIH-RD
  ## ==================================================================
  say("\n=========== A. REGISTROS BRUTOS DO SIH-RD ===========")
  fs <- sort(list.files(DIR_SIH, pattern = "^sih_rd_rj_[0-9]{4}_[0-9]{2}\\.rds$",
                        full.names = TRUE))
  say("competicoes lidas em varredura: ", length(fs))

  n <- 0L
  a <- list(dt_saida_antes = 0L, perman_mismatch = 0L, uti_maior_perman = 0L,
            morte_dias_zero = 0L, nasc_idade_inc = 0L, cnes_invalido = 0L,
            val_tot_neg = 0L, car_int_invalido = 0L, sexo_invalido = 0L,
            cod_idade_invalido = 0L, diag_invalido = 0L, morte_sem_data_saida = 0L,
            idade_extremo = 0L, ai_repetida_competencia = 0L)

  t0 <- Sys.time()
  for (i in seq_along(fs)) {
    d <- readRDS(fs[i])
    n <- n + nrow(d)
    g <- function(x) as.character(d[[x]])

    dt_i <- suppressWarnings(as.Date(g("DT_INTER"), format = "%Y%m%d"))
    dt_s <- suppressWarnings(as.Date(g("DT_SAIDA"), format = "%Y%m%d"))
    dp <- suppressWarnings(as.numeric(g("DIAS_PERM")))
    mo <- suppressWarnings(as.numeric(g("MORTE")))
    ut <- suppressWarnings(as.numeric(g("UTI_MES_TO")))

    a$dt_saida_antes <- a$dt_saida_antes + sum(!is.na(dt_i) & !is.na(dt_s) & dt_s < dt_i)
    esperado <- as.numeric(dt_s - dt_i) + 1
    a$perman_mismatch <- a$perman_mismatch +
      sum(!is.na(esperado) & !is.na(dp) & abs(dp - esperado) > 1)
    a$uti_maior_perman <- a$uti_maior_perman + sum(!is.na(ut) & !is.na(dp) & ut > dp)
    a$morte_dias_zero <- a$morte_dias_zero + sum(mo == 1 & !is.na(dp) & dp == 0)
    a$morte_sem_data_saida <- a$morte_sem_data_saida + sum(mo == 1 & is.na(dt_s))

    nasc <- suppressWarnings(as.Date(g("NASC"), format = "%Y%m%d"))
    idade <- suppressWarnings(as.numeric(g("IDADE")))
    cod <- g("COD_IDADE")
    idade_anos <- idade
    idade_anos[cod == "3"] <- idade_anos[cod == "3"] / 12
    idade_anos[cod == "2"] <- idade_anos[cod == "2"] / 365
    idade_anos[cod == "1"] <- idade_anos[cod == "1"] / (365 * 24)
    idade_nasc <- as.numeric(dt_i - nasc) / 365.25
    a$nasc_idade_inc <- a$nasc_idade_inc +
      sum(!is.na(idade_nasc) & !is.na(idade_anos) & abs(idade_nasc - idade_anos) > 2)
    a$idade_extremo <- a$idade_extremo + sum(!is.na(idade_anos) &
                                               (idade_anos < 0 | idade_anos > 120))

    cn <- trimws(g("CNES"))
    a$cnes_invalido <- a$cnes_invalido + sum(!grepl("^[0-9]{7}$", cn))
    vt <- suppressWarnings(as.numeric(g("VAL_TOT")))
    a$val_tot_neg <- a$val_tot_neg + sum(!is.na(vt) & vt < 0)
    a$car_int_invalido <- a$car_int_invalido +
      sum(!g("CAR_INT") %in% c("01","02","03","04","05","06","07"))
    a$sexo_invalido <- a$sexo_invalido + sum(!g("SEXO") %in% c("1","3"))
    a$cod_idade_invalido <- a$cod_idade_invalido + sum(!cod %in% c("1","2","3","4"))
    di <- toupper(trimws(g("DIAG_PRINC")))
    a$diag_invalido <- a$diag_invalido + sum(!grepl("^[A-Z][0-9]{2}", di))
    a$ai_repetida_competencia <- a$ai_repetida_competencia + sum(duplicated(g("N_AIH")))

    if (i %% 48 == 0 || i == length(fs))
      say(sprintf("    %3d/%d competicoes | %.1f min", i, length(fs),
                  as.numeric(difftime(Sys.time(), t0, units = "mins"))))
  }

  reg("A", "Registros brutos lidos", n, "OK")
  reg("A", "DT_SAIDA anterior a DT_INTER", a$dt_saida_antes,
      if (a$dt_saida_antes / n < 0.001) "OK" else "ATENCAO")
  reg("A", "DIAS_PERM divergente das datas (>1 dia)",
      a$perman_mismatch, if (a$perman_mismatch / n < 0.02) "OK" else "ATENCAO",
      sprintf("%.2f%%", 100 * a$perman_mismatch / n))
  reg("A", "UTI_MES_TO maior que DIAS_PERM", a$uti_maior_perman,
      if (a$uti_maior_perman / n < 0.02) "ATENCAO" else "ERRO",
      sprintf("%.2f%%", 100 * a$uti_maior_perman / n))
  reg("A", "Obito com zero dia de permanencia", a$morte_dias_zero, "ATENCAO",
      "obito no dia da internacao e possivel")
  reg("A", "Obito sem data de saida", a$morte_sem_data_saida,
      if (a$morte_sem_data_saida == 0) "OK" else "ATENCAO")
  reg("A", "Idade divergente da data de nascimento (>2 anos)",
      a$nasc_idade_inc, if (a$nasc_idade_inc / n < 0.01) "OK" else "ATENCAO",
      sprintf("%.3f%%", 100 * a$nasc_idade_inc / n))
  reg("A", "Idade fora de 0 a 120 anos", a$idade_extremo,
      if (a$idade_extremo == 0) "OK" else "ATENCAO")
  reg("A", "CNES fora do padrao de 7 digitos", a$cnes_invalido,
      if (a$cnes_invalido == 0) "OK" else "ATENCAO")
  reg("A", "VAL_TOT negativo", a$val_tot_neg,
      if (a$val_tot_neg == 0) "OK" else "ATENCAO", "erro de entrada")
  reg("A", "CAR_INT fora de 01 a 07", a$car_int_invalido,
      if (a$car_int_invalido == 0) "OK" else "ATENCAO")
  reg("A", "SEXO fora de 1 ou 3", a$sexo_invalido,
      if (a$sexo_invalido == 0) "OK" else "ATENCAO")
  reg("A", "COD_IDADE fora de 1 a 4", a$cod_idade_invalido,
      if (a$cod_idade_invalido == 0) "OK" else "ATENCAO")
  reg("A", "DIAG_PRINC fora do padrao CID-10", a$diag_invalido,
      if (a$diag_invalido == 0) "OK" else "ATENCAO")
  reg("A", "N_AIH repetida na mesma competencia", a$ai_repetida_competencia, "ATENCAO",
      "esperado: a mesma AIH aparece em linhas de procedimentos")

  ## --- fronteira dezembro/janeiro: risco de duplicacao entre competicoes ---
  say("\n  verificacao da fronteira dezembro/janeiro (risco de duplicacao entre competicoes):")
  borda <- character(0)
  for (ano in 2010:2024)
    borda <- c(borda, sprintf("sih_rd_rj_%d_12.rds", ano), sprintf("sih_rd_rj_%d_01.rds", ano + 1))
  borda <- intersect(borda, basename(fs))
  ai <- rbindlist(lapply(file.path(DIR_SIH, borda), function(f) {
    d <- readRDS(f); data.table(aih = as.character(d[["N_AIH"]]), comp = basename(f)) }))
  repr <- ai[, .N, by = aih][N > 1]
  cruz <- ai[aih %in% repr$aih]
  cruz <- cruz[, .(comps = paste(sort(unique(comp)), collapse = " | ")), by = aih]
  entre <- cruz[grepl("\\|", comps)]
  say("    arquivos de fronteira analisados: ", length(borda))
  say("    AIH em mais de uma competencia: ", nrow(entre))
  reg("A", "AIH repetida em competicoes diferentes na fronteira",
      nrow(entre), if (nrow(entre) == 0) "OK" else "ATENCAO",
      "justifica ler 2025 e deduplicar")

  ## ==================================================================
  ## B. COERENCIA DA COORTE
  ## ==================================================================
  say("\n=========== B. COORTE ANALITICA ===========")
  d <- fread(file.path(PROC, "coorte_glmm_2010_2024.csv"), encoding = "UTF-8")
  reg("B", "Internacoes na coorte", nrow(d), "OK")
  reg("B", "Obitos na coorte", sum(d$obito_hospitalar), "OK")
  reg("B", "Media de idade_z (deve ser 0)", sprintf("%.8f", mean(d$idade_z)),
      if (abs(mean(d$idade_z)) < 1e-6) "OK" else "ERRO")
  reg("B", "Desvio-padrao de idade_z (deve ser 1)",
      sprintf("%.8f", sd(d$idade_z)), if (abs(sd(d$idade_z) - 1) < 1e-6) "OK" else "ERRO")
  reg("B", "Anos distintos (deve ser 15)", uniqueN(d$ano),
      if (uniqueN(d$ano) == 15) "OK" else "ERRO",
      paste(range(d$ano), collapse = " a "))
  reg("B", "Regioes de saude distintas (deve ser 9)", uniqueN(d$regiao_saude),
      if (uniqueN(d$regiao_saude) == 9) "OK" else "ERRO")
  reg("B", "Hospitais distintos", uniqueN(d$CNES), "OK")

  ## regra de derivacao do subtipo, verificada de forma direta
  viol <- d[, sum(
    (cid3 %in% c("I60","I61","I62") & subtipo != "Hemorragico (I60-I62)") |
    (cid3 == "I63" & subtipo != "Isquemico (I63)") |
    (cid3 == "I64" & subtipo != "Nao especificado (I64)") |
    (cid3 %in% c("I65","I66","I67","I68") & subtipo != "Oclusao e outras (I65-I68)") |
    (cid3 == "I69" & subtipo != "Sequelas (I69)") |
    (cid3 == "G45" & subtipo != "AIT (G45)") |
    (cid3 == "G46" & subtipo != "Sindromes vasculares (G46)"))]
  reg("B", "Linhas com subtipo incoerente com o CID de 3 digitos", viol,
      if (viol == 0) "OK" else "ERRO")

  dup_full <- sum(duplicated(d, by = c("CNES","idade_anos","sexo","car_int","subtipo",
                                       "uti","fluxo_inter","regiao_saude","ano",
                                       "obito_hospitalar")))
  reg("B", "Linhas identicas em todas as covariaveis", dup_full,
      if (dup_full == 0) "OK" else "ATENCAO", "esperado: nenhuma")

  reg("B", "Ausentes em qualquer covariavel do modelo",
      sum(is.na(d[, .(idade_z, sexo, subtipo, car_int, uti, fluxo_inter,
                      regiao_saude, CNES, obito_hospitalar)])),
      if (sum(is.na(d[, .(idade_z, sexo, subtipo, car_int, uti, fluxo_inter,
                          regiao_saude, CNES, obito_hospitalar)])) == 0) "OK" else "ERRO")

  ## conferencia contra o inventario de codigos do script 02
  vc <- file.path(TAB, "tab_verificacao_cid.csv")
  if (file.exists(vc)) {
    v <- fread(vc, encoding = "UTF-8")
    soma_i <- sum(sapply(sprintf("I_I6%d", 0:9), function(c) sum(v[[c]])))
    reg("B", "I60-I69 nos arquivos brutos (antes de filtros)", soma_i, "OK")
    reg("B", "Razao coorte / registros brutos I60-I69",
        sprintf("%.4f", sum(d$coorte == "I60-I69") / soma_i), "ATENCAO",
        "diferenca explica-se por residencia fora do RJ, duplicatas e periodo")
    soma_g <- sum(v$G_bloco)
    reg("B", "Bloco G45/G46 nos arquivos brutos", soma_g, "OK")
  }

  ## ==================================================================
  ## C. TRIANGULACAO SIH x SIM
  ## ==================================================================
  say("\n=========== C. TRIANGULACAO SIH x SIM ===========")
  t1 <- Sys.time()
  sim <- rbindlist(lapply(sort(list.files(DIR_SIM, pattern = "^sim_do_rj_[0-9]{4}\\.rds$",
                                          full.names = TRUE)), function(f) {
    x <- readRDS(f)
    cb <- toupper(trimws(as.character(x[["CAUSABAS"]])))
    muni <- sprintf("%06s", as.character(x[["CODMUNRES"]]))
    sel <- substr(cb, 1, 3) %in% sprintf("I6%d", 0:9) & substr(muni, 1, 2) == "33"
    if (!any(sel)) return(NULL)
    data.table(DTOBITO = as.character(x[["DTOBITO"]])[sel],
               IDADE = x[["IDADE"]][sel], LOCOCOR = as.character(x[["LOCOCOR"]])[sel])
  }), fill = TRUE)
  dt <- suppressWarnings(as.Date(sim$DTOBITO, format = "%d%m%Y"))
  sim <- sim[!is.na(dt) & dt >= as.Date("2010-01-01") & dt <= as.Date("2024-12-31")]
  say("  obitos I60-I69 no SIM, residentes no RJ, 2010-2024: ",
      format(nrow(sim), big.mark = "."))
  sim_hosp <- sum(sim$LOCOCOR == "1", na.rm = TRUE)
  say("  desses, com local de ocorrencia hospitalar: ", format(sim_hosp, big.mark = "."))
  say("  obitos intra-hospitalares no SIH (SUS): ", format(sum(d$obito_hospitalar), big.mark = "."))
  razao <- sum(d$obito_hospitalar) / sim_hosp
  reg("C", "Obitos hospitalares SIM (todas as fontes)", sim_hosp, "OK")
  reg("C", "Obitos intra-hospitalares SIH (somente SUS)", sum(d$obito_hospitalar), "OK")
  reg("C", "Razao SIH / SIM hospitalar", sprintf("%.3f", razao),
      if (razao > 0.5 && razao < 1.2) "OK" else "ATENCAO",
      "SIH cobre apenas internacoes SUS; SIM cobre toda a mortalidade")
  reg("C", "Obitos no SIM com local ignorado",
      sum(sim$LOCOCOR %in% c("9", "", NA), na.rm = TRUE), "ATENCAO",
      "afeta a comparacao entre fontes")
  say("  tempo da leitura do SIM: ",
      sprintf("%.1f min", as.numeric(difftime(Sys.time(), t1, units = "mins"))))

  ## ==================================================================
  ## D. COERENCIA DO MODELO E DAS TABELAS
  ## ==================================================================
  say("\n=========== D. MODELO E TABELAS ===========")
  comp <- fread(file.path(TAB, "tab4_glmm_componentes.csv"), encoding = "UTF-8")
  gv <- function(m) as.numeric(comp[metrica == m, valor][1])
  s2 <- gv("Variancia hospitalar (s2_hosp)"); icc <- gv("VPC / ICC"); mor <- gv("MOR")
  icc_calc <- s2 / (s2 + pi^2 / 3)
  mor_calc <- exp(sqrt(2 * s2) * qnorm(0.75))
  reg("D", "ICC da tabela coerente com sigma^2/(sigma^2+pi^2/3)",
      sprintf("%.5f vs %.5f", icc, icc_calc),
      if (abs(icc - icc_calc) < 1e-4) "OK" else "ERRO")
  reg("D", "MOR coerente com exp(sqrt(2 s2) Phi^-1(0,75))",
      sprintf("%.4f vs %.4f", mor, mor_calc),
      if (abs(mor - mor_calc) < 1e-3) "OK" else "ERRO")

  or <- fread(file.path(TAB, "tab3_glmm_or.csv"), encoding = "UTF-8")
  reg("D", "Coeficientes na tabela de OR", nrow(or), "OK")
  q_ok <- all(is.na(or$q_bh) | or$q_bh >= or$p - 1e-12)
  reg("D", "q-valor sempre maior ou igual ao p-valor", if (q_ok) "sim" else "nao",
      if (q_ok) "OK" else "ERRO")
  bonf <- p.adjust(or$p[!is.na(or$q_bh)], method = "BH")
  reg("D", "q-valor reproduz p.adjust(BH)",
      sprintf("%.6f", max(abs(bonf - or$q_bh[!is.na(or$q_bh)]))),
      if (max(abs(bonf - or$q_bh[!is.na(or$q_bh)])) < 1e-9) "OK" else "ERRO")

  cal <- fread(file.path(TAB, "tab5_calibracao.csv"), encoding = "UTF-8")
  for (tp in unique(cal$tipo)) {
    soma <- sum(cal[tipo == tp]$n)
    reg("D", paste0("Soma de n na calibracao (", tp, ")"), soma,
        if (soma == nrow(d)) "OK" else "ERRO", paste("coorte:", format(nrow(d), big.mark = ".")))
  }
  reg("D", "Obitos esperados / observados (marginal)",
      sprintf("%.4f", sum(cal[tipo == "marginal"]$esp) / sum(cal[tipo == "marginal"]$obs)),
      "ATENCAO", "marginal subestima por desigualdade de Jensen")
  reg("D", "Obitos esperados / observados (condicional)",
      sprintf("%.4f", sum(cal[tipo == "condicional"]$esp) / sum(cal[tipo == "condicional"]$obs)),
      "OK", "previsao condicional e a calibrada")

  isu <- fread(file.path(TAB, "tab6_isu_regiao_saude.csv"), encoding = "UTF-8")
  reg_isu <- isu[regiao_saude != "ESTADO DO RJ" &
                   regiao_saude != "SEM MUNICIPIO CORRESPONDENTE"]
  total_est <- isu[regiao_saude == "ESTADO DO RJ"]$obitos_total
  soma_reg <- sum(reg_isu$obitos_total) + isu[regiao_saude == "SEM MUNICIPIO CORRESPONDENTE"]$obitos_total
  reg("D", "Soma dos obitos regionais igual ao total estadual do ISU",
      sprintf("%s vs %s", format(soma_reg, big.mark = "."), format(total_est, big.mark = ".")),
      if (soma_reg == total_est) "OK" else "ERRO")

  rob <- fread(file.path(TAB, "tab8_robustez_componentes.csv"), encoding = "UTF-8")
  s0 <- rob[cenario == "S0_principal"]$sigma2
  reg("D", "Robustez reproduz o modelo principal (sigma^2)",
      sprintf("%.5f vs %.5f", s0, s2), if (abs(s0 - s2) < 1e-4) "OK" else "ERRO")
  reg("D", "Cenarios de robustez convergidos",
      sprintf("%d de %d", sum(rob$convergiu), nrow(rob)),
      if (all(rob$convergiu)) "OK" else "ATENCAO")

  ## ---------------- consolidacao ----------------
  r <- rbindlist(res)
  fwrite(r, file.path(TAB, "tab19_auditoria.csv"), encoding = "UTF-8")
  say("\n=========== RESUMO DA AUDITORIA ===========")
  tb <- r[, .N, by = classificacao][order(classificacao)]
  for (i in seq_len(nrow(tb)))
    say(sprintf("  %-8s %2d verificacoes", tb$classificacao[i], tb$N[i]))
  erros <- r[classificacao == "ERRO"]
  if (nrow(erros)) {
    say("\n  VERIFICACOES CLASSIFICADAS COMO ERRO:")
    for (i in seq_len(nrow(erros)))
      say("    - ", erros$bloco[i], " | ", erros$item[i], " | ", erros$valor[i])
  } else say("\n  nenhuma verificacao classificada como ERRO")

  at <- r[classificacao == "ATENCAO"]
  if (nrow(at)) {
    say("\n  VERIFICACOES QUE EXIGEM LEITURA:")
    for (i in seq_len(nrow(at)))
      say("    - ", at$bloco[i], " | ", at$item[i], " | ", at$valor[i],
          if (nzchar(at$nota[i])) paste0(" (", at$nota[i], ")") else "")
  }

  say("\nfim: ", format(Sys.time()))
  close(logcon)
})
