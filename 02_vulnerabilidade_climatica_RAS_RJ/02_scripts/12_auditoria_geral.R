# 12_auditoria_geral.R
# Bateria de auditoria do repositório, complementar ao script 07 (que
# audita a coerência interna dos microdados SIH/SIM, da coorte e do
# modelo). Este script cobre o que o 07 não cobre:
#
#   1. ESTRUTURA E AQUISIÇÃO: completude e integridade dos .rds brutos.
#   2. RECORTE CID VERSIONADO: re-derivação independente do recorte
#      produzido pelo script 01 (sih/sim_cid_estudo_2010_2024.csv) a
#      partir dos .rds e conferência linha a linha de totais e marginais.
#   3. COERÊNCIA ENTRE ARTEFATOS: coorte x recorte x tabelas publicadas.
#   4. CONSISTÊNCIA NUMERICA DAS TABELAS: formulas de OR, ICC, MOR, FDR,
#      calibração e ISU; aderencia das principais afirmacoes do README.
#   5. CÓDIGO E REPRODUTIBILIDADE: sintaxe de todos os scripts R e Python,
#      caminhos relativos, ausencia de setwd/absolutos, pacotes exigidos.
#   6. PRIVACIDADE E HIGIENE DO REPOSITÓRIO: campos identificaveis nos
#      arquivos versionados, arquivos grandes rastreados e regras de
#      .gitignore.
#
# Cada verificação recebe: OK | ATENÇÃO | ERRO | INFO.
#
# Saídas:
#   04_resultados/resultados_auditoria_geral.txt
#   05_tabelas/tab26_auditoria_geral.csv
#   10_auditoria/AUDITORIA_GERAL.md

suppressWarnings({
  options(stringsAsFactors = FALSE)
  library(data.table)

  ROOT <- normalizePath(".")
  REPO <- dirname(ROOT)
  DIR_SIH <- file.path(ROOT, "01_dados", "brutos_sih")
  DIR_SIM <- file.path(ROOT, "01_dados", "brutos_sim")
  PROC <- file.path(ROOT, "01_dados", "processados")
  RES <- file.path(ROOT, "04_resultados")
  TAB <- file.path(ROOT, "05_tabelas")
  AUD <- file.path(ROOT, "10_auditoria")
  SCR <- file.path(ROOT, "02_scripts")
  dir.create(AUD, showWarnings = FALSE, recursive = TRUE)

  logcon <- file(file.path(RES, "resultados_auditoria_geral.txt"),
                 open = "wt", encoding = "UTF-8")
  say <- function(...) { m <- paste0(...); cat(m, "\n"); writeLines(m, logcon); flush(logcon) }

  res <- list()
  reg <- function(bloco, item, valor, classe, nota = "") {
    res[[length(res) + 1]] <<- data.table(
      bloco = bloco, item = item, valor = as.character(valor),
      classificacao = classe, nota = nota)
    say(sprintf("  [%-7s] %-58s %s %s", classe, item,
                format(valor, big.mark = "."), nota))
  }
  chk <- function(cond, bloco, item, valor, bad = "ERRO", nota = "")
    reg(bloco, item, valor, if (isTRUE(cond)) "OK" else bad, nota)

  say("=====================================================================")
  say("BATERIA DE AUDITORIA GERAL DO REPOSITORIO")
  say("R ", R.version.string, " | data.table ", as.character(packageVersion("data.table")))
  say("inicio: ", format(Sys.time()))
  say("repo: ", REPO)
  say("=====================================================================")

  ESTUDO_I <- sprintf("I6%d", 0:9)
  ESTUDO_G <- c("G45", "G46")
  ESTUDO <- c(ESTUDO_I, ESTUDO_G)

  ## 1. ESTRUTURA E AQUISIÇÃO
  say("\n=========== 1. ESTRUTURA E AQUISICAO ===========")
  fs_sih <- sort(list.files(DIR_SIH, pattern = "^sih_rd_rj_[0-9]{4}_[0-9]{2}\\.rds$",
                            full.names = TRUE))
  fs_sim <- sort(list.files(DIR_SIM, pattern = "^sim_do_rj_[0-9]{4}\\.rds$",
                            full.names = TRUE))

  comps_desejadas <- as.vector(outer(2010:2025, 1:12,
                                     function(a, m) sprintf("sih_rd_rj_%d_%02d.rds", a, m)))
  faltantes_sih <- setdiff(comps_desejadas, basename(fs_sih))
  reg("1", "Competicoes SIH-RD presentes", length(fs_sih),
      if (length(fs_sih) == 191) "OK" else "ERRO", "esperado 191")
  reg("1", "Competicoes SIH ausentes", length(faltantes_sih),
      if (identical(sort(faltantes_sih), "sih_rd_rj_2025_12.rds")) "ATENCAO" else "ERRO",
      if (length(faltantes_sih)) paste(faltantes_sih, collapse = ", ") else "nenhuma")
  reg("1", "Arquivos SIM-DO presentes", length(fs_sim),
      if (length(fs_sim) == 15) "OK" else "ERRO", "esperado 15 (2010-2024)")
  anos_sim_esperados <- sprintf("sim_do_rj_%d.rds", 2010:2024)
  reg("1", "Anos do SIM ausentes", length(setdiff(anos_sim_esperados, basename(fs_sim))),
      if (length(setdiff(anos_sim_esperados, basename(fs_sim))) == 0) "OK" else "ERRO")
  reg("1", "Tamanho bruto SIH (MB)", round(sum(file.info(fs_sih)$size) / 1024^2, 1), "INFO")
  reg("1", "Tamanho bruto SIM (MB)", round(sum(file.info(fs_sim)$size) / 1024^2, 1), "INFO")
  reg("1", "Arquivos com tamanho zero", sum(file.info(c(fs_sih, fs_sim))$size == 0),
      if (sum(file.info(c(fs_sih, fs_sim))$size == 0) == 0) "OK" else "ERRO")

  ## 2. RECORTE CID VERSIONADO (re-derivação a partir dos .rds)
  say("\n=========== 2. RECORTE CID VERSIONADO ===========")
  say("  lendo os microdados brute para re-derivar o recorte...")
  t0 <- Sys.time()

  acc_ano <- list(); acc_cid <- list(); acc_mun <- list()
  n_bruto <- 0L; n_estudo <- 0L; n_recorte <- 0L; falhas_leitura <- 0L
  for (i in seq_along(fs_sih)) {
    d <- tryCatch(readRDS(fs_sih[i]), error = function(e) NULL)
    if (is.null(d)) { falhas_leitura <- falhas_leitura + 1L; next }
    n_bruto <- n_bruto + nrow(d)
    cid <- toupper(trimws(as.character(d[["DIAG_PRINC"]])))
    cid3 <- substr(cid, 1, 3)
    sel <- cid3 %in% ESTUDO
    n_estudo <- n_estudo + sum(sel)
    muni <- sprintf("%06s", as.character(d[["MUNIC_RES"]]))
    dt <- suppressWarnings(as.Date(as.character(d[["DT_INTER"]]), format = "%Y%m%d"))
    sel <- sel & substr(muni, 1, 2) == "33" &
      !is.na(dt) & dt >= as.Date("2010-01-01") & dt <= as.Date("2024-12-31")
    if (any(sel)) {
      n_recorte <- n_recorte + sum(sel)
      acc_ano[[length(acc_ano) + 1L]] <- data.table(
        ano = format(dt[sel], "%Y"),
        morte = as.integer(as.character(d[["MORTE"]][sel]) == "1"))
      acc_cid[[length(acc_cid) + 1L]] <- data.table(cid3 = cid3[sel])
      acc_mun[[length(acc_mun) + 1L]] <- data.table(muni = muni[sel])
    }
    if (i %% 40 == 0L || i == length(fs_sih))
      say(sprintf("    %3d/%d | %.1f min", i, length(fs_sih),
                  as.numeric(difftime(Sys.time(), t0, units = "mins"))))
  }
  chk(falhas_leitura == 0, "2", "Falhas de leitura dos .rds do SIH", falhas_leitura)
  reg("2", "Registros brutos SIH relidos", n_bruto,
      if (n_bruto == 11947354) "OK" else "ATENCAO", "referencia: 11.947.354")
  reg("2", "Registros do estudo nos brutos (antes de RJ/periodo)", n_estudo, "INFO")

  exp_ano <- rbindlist(acc_ano)[, .(n = .N, obitos = sum(morte)), by = ano][order(ano)]
  exp_cid <- rbindlist(acc_cid)[, .N, by = cid3][order(cid3)]
  exp_mun <- rbindlist(acc_mun)[, .N, by = muni][order(-N)]

  f_sih_csv <- file.path(PROC, "sih_cid_estudo_2010_2024.csv")
  chk(file.exists(f_sih_csv), "2", "Recorte SIH versionado existe", if (file.exists(f_sih_csv)) "sim" else "nao")
  if (file.exists(f_sih_csv)) {
    s <- fread(f_sih_csv, encoding = "UTF-8", na.strings = c("NA", ""), colClasses = "character")
    reg("2", "Linhas no recorte SIH (CSV)", nrow(s),
        if (nrow(s) == n_recorte) "OK" else "ERRO",
        paste("re-derivado:", format(n_recorte, big.mark = ".")))
    chk(n_recorte == nrow(s), "2", "Recorte SIH bate com a re-derivacao", nrow(s))

    ## integridade interna do CSV
    cid3s <- substr(toupper(trimws(as.character(s$DIAG_PRINC))), 1, 3)
    chk(all(cid3s %in% ESTUDO), "2", "Linhas do recorte fora dos CIDs do estudo",
        sum(!cid3s %in% ESTUDO))
    chk(all(substr(sprintf("%06s", as.character(s$MUNIC_RES)), 1, 2) == "33"),
        "2", "Linhas do recorte fora do RJ (MUNIC_RES)",
        sum(substr(sprintf("%06s", as.character(s$MUNIC_RES)), 1, 2) != "33"))
    dts <- suppressWarnings(as.Date(as.character(s$DT_INTER), format = "%Y%m%d"))
    fora <- sum(is.na(dts) | dts < as.Date("2010-01-01") | dts > as.Date("2024-12-31"))
    chk(fora == 0, "2", "Linhas do recorte fora do periodo 2010-2024", fora)
    chk(!any(is.na(s$N_AIH) | s$N_AIH == ""), "2", "N_AIH ausente no recorte",
        sum(is.na(s$N_AIH) | s$N_AIH == ""))
    chk(!anyDuplicated(s), "2", "Linhas integralmente duplicadas no recorte", sum(duplicated(s)),
        nota = "se >0, ha duplicacao exata no CSV")

    ## marginais por ano, CID3 e município
    csv_ano <- s[, .(n = .N, obitos = sum(as.integer(as.character(MORTE) == "1"), na.rm = TRUE)),
                 by = .(ano = format(dts, "%Y"))][order(ano)]
    cmp <- merge(exp_ano, csv_ano, by = "ano", suffixes = c("_exp", "_csv"), all = TRUE)
    dif_n <- sum(abs(cmp$n_exp - cmp$n_csv), na.rm = TRUE)
    dif_o <- sum(abs(cmp$obitos_exp - cmp$obitos_csv), na.rm = TRUE)
    chk(dif_n == 0, "2", "Diferenca de n por ano entre re-derivacao e CSV", dif_n)
    chk(dif_o == 0, "2", "Diferenca de obitos por ano entre re-derivacao e CSV", dif_o)

    csv_cid <- s[, .(n_csv = .N), by = .(cid3 = substr(toupper(trimws(as.character(DIAG_PRINC))), 1, 3))]
    cmp_cid <- merge(exp_cid, csv_cid, by = "cid3", all = TRUE)
    chk(sum(abs(cmp_cid$N - cmp_cid$n_csv), na.rm = TRUE) == 0,
        "2", "Diferenca de n por CID3 (re-derivacao x CSV)",
        sum(abs(cmp_cid$N - cmp_cid$n_csv), na.rm = TRUE))
    chk(nrow(cmp_cid) == length(ESTUDO) || all(ESTUDO %in% cmp_cid$cid3),
        "2", "Todos os 12 CID3 do estudo presentes no recorte",
        sum(!ESTUDO %in% cmp_cid$cid3),
        nota = paste("CID3 ausentes:", paste(setdiff(ESTUDO, cmp_cid$cid3), collapse = ",")))
  }

  ## ---- SIM: recorte re-derivado ----
  n_sim_bruto <- 0L; n_sim_rec <- 0L; sim_ano <- list(); falhas_sim <- 0L
  for (f in fs_sim) {
    d <- tryCatch(readRDS(f), error = function(e) NULL)
    if (is.null(d)) { falhas_sim <- falhas_sim + 1L; next }
    n_sim_bruto <- n_sim_bruto + nrow(d)
    cb <- toupper(trimws(as.character(d[["CAUSABAS"]])))
    muni <- sprintf("%06s", as.character(d[["CODMUNRES"]]))
    dt <- suppressWarnings(as.Date(as.character(d[["DTOBITO"]]), format = "%d%m%Y"))
    sel <- (substr(cb, 1, 3) %in% ESTUDO_I | substr(cb, 1, 3) %in% ESTUDO_G) &
      substr(muni, 1, 2) == "33" &
      !is.na(dt) & dt >= as.Date("2010-01-01") & dt <= as.Date("2024-12-31")
    if (any(sel)) {
      n_sim_rec <- n_sim_rec + sum(sel)
      sim_ano[[length(sim_ano) + 1L]] <- data.table(ano = format(dt[sel], "%Y"))
    }
  }
  chk(falhas_sim == 0, "2", "Falhas de leitura dos .rds do SIM", falhas_sim)
  exp_sim_ano <- rbindlist(sim_ano)[, .N, by = ano][order(ano)]
  f_sim_csv <- file.path(PROC, "sim_cid_estudo_2010_2024.csv")
  chk(file.exists(f_sim_csv), "2", "Recorte SIM versionado existe",
      if (file.exists(f_sim_csv)) "sim" else "nao")
  if (file.exists(f_sim_csv)) {
    sm <- fread(f_sim_csv, encoding = "UTF-8", na.strings = c("NA", ""), colClasses = "character")
    reg("2", "Linhas no recorte SIM (CSV)", nrow(sm),
        if (nrow(sm) == n_sim_rec) "OK" else "ERRO",
        paste("re-derivado:", format(n_sim_rec, big.mark = ".")))
    chk(n_sim_rec == nrow(sm), "2", "Recorte SIM bate com a re-derivacao", nrow(sm))
    cbs <- substr(toupper(trimws(as.character(sm$CAUSABAS))), 1, 3)
    chk(all(cbs %in% ESTUDO), "2", "Linhas do recorte SIM fora de I60-I69 e G45/G46", sum(!cbs %in% ESTUDO))
    chk(all(substr(sprintf("%06s", as.character(sm$CODMUNRES)), 1, 2) == "33"),
        "2", "Linhas do recorte SIM fora do RJ", sum(substr(sprintf("%06s", as.character(sm$CODMUNRES)), 1, 2) != "33"))
    dtos <- suppressWarnings(as.Date(as.character(sm$DTOBITO), format = "%d%m%Y"))
    chk(sum(is.na(dtos)) == 0, "2", "DTOBITO invalida no recorte SIM", sum(is.na(dtos)))
    csv_sim_ano <- sm[, .(n_csv = .N), by = .(ano = format(dtos, "%Y"))][order(ano)]
    cmp_sim <- merge(exp_sim_ano, csv_sim_ano, by = "ano", all = TRUE)
    chk(sum(abs(cmp_sim$N - cmp_sim$n_csv), na.rm = TRUE) == 0,
        "2", "Diferenca de obitos por ano (SIM re-derivacao x CSV)",
        sum(abs(cmp_sim$N - cmp_sim$n_csv), na.rm = TRUE))
  }
  say(sprintf("  tempo da re-derivacao: %.1f min",
              as.numeric(difftime(Sys.time(), t0, units = "mins"))))

  ## 3. COERÊNCIA ENTRE ARTEFATOS (coorte x recorte x tabelas)
  say("\n=========== 3. COERENCIA ENTRE ARTEFATOS ===========")
  f_coorte <- file.path(PROC, "coorte_glmm_2010_2024.csv")
  chk(file.exists(f_coorte), "3", "Coorte analitica existe", if (file.exists(f_coorte)) "sim" else "nao")
  if (file.exists(f_coorte)) {
    co <- fread(f_coorte, encoding = "UTF-8", na.strings = c("NA", ""))
    reg("3", "Linhas na coorte", nrow(co), if (nrow(co) == 295673) "OK" else "ERRO")
    reg("3", "Obitos na coorte", sum(co$obito_hospitalar),
        if (sum(co$obito_hospitalar) == 55827) "OK" else "ERRO")
    if (file.exists(f_sih_csv)) {
      chk(nrow(co) == nrow(s), "3", "Tamanho da coorte igual ao recorte SIH", nrow(co),
          nota = "ambos devem ter 295.673")
      chk(sum(co$obito_hospitalar) ==
            sum(as.integer(as.character(s$MORTE) == "1"), na.rm = TRUE),
          "3", "Obitos da coorte iguais aos do recorte SIH", sum(co$obito_hospitalar))
      ## conferência por chave
      k1 <- paste(co$N_AIH, co$IDENT, format(co$DT_INTER_d, "%Y%m%d"), co$DT_SAIDA)
      k2 <- paste(s$N_AIH, s$IDENT, s$DT_INTER, s$DT_SAIDA)
      casam <- sum(k2 %in% k1)
      chk(casam == nrow(s), "3", "Registros do recorte localizados na coorte por chave", casam,
          nota = sprintf("nao localizados: %d", nrow(s) - casam))
    }
    ## tabelas derivadas da coorte
    t1 <- fread(file.path(TAB, "tab1_perfil_coorte.csv"), encoding = "UTF-8")
    chk(sum(t1[variavel == "Coorte diagnostica"]$n) == nrow(co),
        "3", "tab1: soma das coortes = n da coorte",
        sum(t1[variavel == "Coorte diagnostica"]$n))
    chk(sum(t1[variavel == "Coorte diagnostica"]$n_obito) == sum(co$obito_hospitalar),
        "3", "tab1: soma dos obitos = obitos da coorte",
        sum(t1[variavel == "Coorte diagnostica"]$n_obito))
    t2 <- fread(file.path(TAB, "tab2_coorte_por_regiao.csv"), encoding = "UTF-8")
    chk(sum(t2$internacoes) == nrow(co), "3", "tab2: soma das internacoes por regiao", sum(t2$internacoes))
    chk(sum(t2$obitos) == sum(co$obito_hospitalar), "3", "tab2: soma dos obitos por regiao", sum(t2$obitos))
    chk(nrow(t2) == 9, "3", "tab2: numero de regioes de saude", nrow(t2),
        nota = "esperado 9")
  }

  ## 4. CONSISTÊNCIA NUMERICA DAS TABELAS
  say("\n=========== 4. CONSISTENCIA NUMERICA DAS TABELAS ===========")

  ## tab4: componentes
  comp <- fread(file.path(TAB, "tab4_glmm_componentes.csv"), encoding = "UTF-8")
  gv <- function(m) as.numeric(comp[metrica == m, valor][1])
  s2 <- gv("Variancia hospitalar (s2_hosp)"); icc <- gv("VPC / ICC"); mor <- gv("MOR")
  chk(abs(icc - s2 / (s2 + pi^2 / 3)) < 1e-4, "4", "tab4: ICC = s2/(s2+pi^2/3)",
      sprintf("%.5f", icc))
  chk(abs(mor - exp(sqrt(2 * s2) * qnorm(0.75))) < 1e-3, "4",
      "tab4: MOR = exp(sqrt(2 s2) Phi^-1(0,75))", sprintf("%.4f", mor))

  ## tab3: OR
  or <- fread(file.path(TAB, "tab3_glmm_or.csv"), encoding = "UTF-8")
  chk(max(abs(exp(or$beta) - or$or)) < 1e-6, "4", "tab3: or = exp(beta)",
      sprintf("%.2e", max(abs(exp(or$beta) - or$or))))
  chk(max(abs(or$beta / or$ep - or$z)) < 1e-6, "4", "tab3: z = beta/ep",
      sprintf("%.2e", max(abs(or$beta / or$ep - or$z))))
  p_calc <- 2 * pnorm(-abs(or$z))
  chk(max(abs(p_calc - or$p)) < 1e-8, "4", "tab3: p bicaudal reproduzido",
      sprintf("%.2e", max(abs(p_calc - or$p))))
  chk(max(abs(or$lo - exp(or$beta - 1.96 * or$ep))) < 1e-6, "4",
      "tab3: IC95% inferior = exp(beta-1,96*ep)",
      sprintf("%.2e", max(abs(or$lo - exp(or$beta - 1.96 * or$ep)))))
  chk(max(abs(or$hi - exp(or$beta + 1.96 * or$ep))) < 1e-6, "4",
      "tab3: IC95% superior = exp(beta+1,96*ep)",
      sprintf("%.2e", max(abs(or$hi - exp(or$beta + 1.96 * or$ep)))))
  ok_q <- !is.na(or$q_bh)
  chk(all(or$q_bh[ok_q] >= or$p[ok_q] - 1e-12), "4", "tab3: q_bh >= p",
      sum(or$q_bh[ok_q] < or$p[ok_q] - 1e-12))
  chk(max(abs(p.adjust(or$p[ok_q], "BH") - or$q_bh[ok_q])) < 1e-9, "4",
      "tab3: q_bh reproduz p.adjust(BH)",
      sprintf("%.2e", max(abs(p.adjust(or$p[ok_q], "BH") - or$q_bh[ok_q]))))

  ## tab5: calibração
  cal <- fread(file.path(TAB, "tab5_calibracao.csv"), encoding = "UTF-8")
  for (tp in unique(cal$tipo))
    chk(sum(cal[tipo == tp]$n) == nrow(co), "4",
        paste0("tab5: soma de n na calibracao (", tp, ")"), sum(cal[tipo == tp]$n))
  raz_cond <- sum(cal[tipo == "condicional"]$esp) / sum(cal[tipo == "condicional"]$obs)
  chk(abs(raz_cond - 1) < 0.01, "4",
      "tab5: razao esperado/observado condicional proxima de 1", sprintf("%.4f", raz_cond))

  ## tab6: ISU
  isu <- fread(file.path(TAB, "tab6_isu_regiao_saude.csv"), encoding = "UTF-8")
  reg_isu <- isu[!regiao_saude %in% c("ESTADO DO RJ", "SEM MUNICIPIO CORRESPONDENTE")]
  chk(sum(reg_isu$obitos_total) + isu[regiao_saude == "SEM MUNICIPIO CORRESPONDENTE"]$obitos_total ==
        isu[regiao_saude == "ESTADO DO RJ"]$obitos_total,
      "4", "tab6: soma regional = total estadual", isu[regiao_saude == "ESTADO DO RJ"]$obitos_total)
  isu_calc <- 100 * isu$obitos_50mais / isu$obitos_total
  chk(max(abs(isu_calc - isu$ISU)) < 0.01, "4", "tab6: ISU = 100*50+/total",
      sprintf("%.2e", max(abs(isu_calc - isu$ISU))))
  if (file.exists(f_sim_csv)) {
    n_sim_i69 <- sum(substr(toupper(trimws(as.character(sm$CAUSABAS))), 1, 3) %in% ESTUDO_I)
    chk(n_sim_i69 == isu[regiao_saude == "ESTADO DO RJ"]$obitos_total,
        "4", "tab6: obitos I60-I69 do recorte SIM iguais ao total do ISU", n_sim_i69,
        nota = sprintf("recorte SIM completo (com G45/G46): %d", nrow(sm)))
  }

  ## tab8: robustez
  rob <- fread(file.path(TAB, "tab8_robustez_componentes.csv"), encoding = "UTF-8")
  s0 <- rob[cenario == "S0_principal"]$s2
  chk(length(s0) == 1 && abs(s0 - s2) < 1e-4, "4",
      "tab8: S0 reproduz o modelo principal", sprintf("%.5f", s2))
  chk(all(rob$convergiu), "4", "tab8: todos os cenarios convergidos",
      paste(sum(rob$convergiu), "de", nrow(rob)))

  ## tab19: auditoria de consistência sem ERRO
  if (file.exists(file.path(TAB, "tab19_auditoria.csv"))) {
    a19 <- fread(file.path(TAB, "tab19_auditoria.csv"), encoding = "UTF-8")
    chk(sum(a19$classificacao == "ERRO") == 0, "4",
        "tab19: nenhuma verificacao classificada como ERRO",
        sum(a19$classificacao == "ERRO"))
  }

  ## README: afirmacoes-chave presentes
  rd <- paste(readLines(file.path(ROOT, "README.md"), encoding = "UTF-8", warn = FALSE),
              collapse = " ")
  for (af in c("295.673", "55.827", "14,95%", "2,065", "92,38%", "267.746", "27.927", "252.992")) {
    chk(grepl(af, rd, fixed = TRUE), "4", paste0("README contem '", af, "'"),
        if (grepl(af, rd, fixed = TRUE)) "sim" else "nao")
  }

  ## 5. CÓDIGO E REPRODUTIBILIDADE
  say("\n=========== 5. CODIGO E REPRODUTIBILIDADE ===========")
  fs_r <- list.files(SCR, pattern = "\\.R$", recursive = TRUE, full.names = TRUE)
  fs_py <- list.files(SCR, pattern = "\\.py$", recursive = TRUE, full.names = TRUE)
  reg("5", "Scripts R no diretorio de scripts", length(fs_r), "INFO")
  reg("5", "Scripts Python no diretorio de scripts", length(fs_py), "INFO")

  erros_parse <- character(0)
  for (f in fs_r) {
    ok <- tryCatch({ parse(f); TRUE }, error = function(e) FALSE)
    if (!ok) erros_parse <- c(erros_parse, basename(f))
  }
  chk(length(erros_parse) == 0, "5", "Scripts R com erro de sintaxe", length(erros_parse),
      nota = paste(erros_parse, collapse = ", "))

  py <- Sys.which("python")
  if (nzchar(py)) {
    erros_py <- character(0)
    for (f in fs_py) {
      st <- suppressWarnings(system2(py, c("-m", "py_compile", shQuote(f)),
                                     stdout = FALSE, stderr = FALSE))
      if (!is.null(st) && st != 0) erros_py <- c(erros_py, basename(f))
    }
    chk(length(erros_py) == 0, "5", "Scripts Python com erro de sintaxe", length(erros_py),
        nota = paste(erros_py, collapse = ", "))
  } else reg("5", "Python disponivel para checagem", "nao", "ATENCAO")

  ## caminhos absolutos e setwd (o proprio script de auditoria contem os padrões)
  fs_scan <- fs_r[basename(fs_r) != "12_auditoria_geral.R"]
  linhas <- unlist(lapply(fs_scan, readLines, warn = FALSE), use.names = FALSE)
  linhas <- linhas[!grepl("^\\s*#", linhas)]
  abs_pat <- "([A-Z]:[/\\\\]|/Users/|/home/|OneDrive)"
  n_abs <- sum(grepl(abs_pat, linhas))
  chk(n_abs == 0, "5", "Linhas de codigo R com caminho absoluto", n_abs)
  n_setwd <- sum(grepl("setwd\\s*\\(", linhas))
  chk(n_setwd == 0, "5", "Ocorrencias de setwd() no codigo R", n_setwd,
      nota = "quebra a portabilidade; usar normalizePath/caminho relativo")

  ## pacotes exigidos x instalados
  txt <- paste(linhas, collapse = " ")
  pkgs <- unique(unlist(regmatches(txt, gregexpr("(?:library|require)\\s*\\(\\s*[\"']?([A-Za-z0-9._]+)", txt,
                                                  perl = TRUE))))
  pkgs <- unique(sub(".*\\(\\s*[\"']?", "", pkgs))
  pkgs <- unique(sub("[\"']?\\).*", "", pkgs))
  pkgs <- setdiff(pkgs, "")
  inst <- rownames(installed.packages())
  faltam <- setdiff(pkgs, inst)
  reg("5", "Pacotes R exigidos pelo codigo", length(pkgs), "INFO",
      paste(sort(pkgs), collapse = ", "))
  chk(length(faltam) == 0, "5", "Pacotes R exigidos e nao instalados", length(faltam),
      nota = paste(faltam, collapse = ", "))

  ## scripts do diretório mencionados no README
  scripts_existentes <- c(basename(fs_r), basename(fs_py))
  nao_citados <- scripts_existentes[!vapply(scripts_existentes,
                                            function(x) grepl(x, rd, fixed = TRUE), logical(1))]
  chk(length(nao_citados) == 0, "5", "Scripts do diretorio ausentes do README",
      length(nao_citados), bad = "ATENCAO", nota = paste(nao_citados, collapse = ", "))

  ## 6. PRIVACIDADE E HIGIENE DO REPOSITÓRIO
  say("\n=========== 6. PRIVACIDADE E HIGIENE DO REPOSITORIO ===========")
  git_ok <- nzchar(Sys.which("git")) &&
    length(suppressWarnings(system2("git", c("-C", shQuote(REPO), "rev-parse", "--show-toplevel"),
                                    stdout = TRUE, stderr = FALSE))) > 0
  if (git_ok) {
    ## arquivos versionados desta frente
    tracked <- suppressWarnings(system2("git", c("-C", shQuote(REPO), "ls-files",
                                                 paste0(basename(ROOT), "/")),
                                        stdout = TRUE, stderr = FALSE))
    tracked <- sub(paste0("^", basename(ROOT), "/"), "", tracked)
    reg("6", "Arquivos versionados nesta frente", length(tracked), "INFO")

    ## campos potencialmente identificaveis nos CSVs versionados
    csvs <- tracked[grepl("\\.csv$", tracked)]
    PII <- c("NOME", "CPF", "CNS", "NASC", "MAE", "PAI", "ENDERECO", "CEP",
             "TELEFONE", "DOCUMENTO", "RG")
    achados_pii <- character(0)
    for (cf in csvs) {
      p <- file.path(ROOT, cf)
      if (!file.exists(p)) next
      h <- tryCatch(names(fread(p, nrows = 0)), error = function(e) character(0))
      hit <- intersect(toupper(h), PII)
      if (length(hit)) achados_pii <- c(achados_pii, paste0(cf, ":", paste(hit, collapse = "/")))
    }
    chk(length(achados_pii) == 0, "6", "CSVs versionados com campo identificavel direto",
        length(achados_pii), nota = paste(achados_pii, collapse = "; "))

    ## arquivos versionados grandes
    info <- file.info(file.path(ROOT, tracked))
    grandes <- tracked[which(info$size > 50 * 1024^2)]
    chk(length(grandes) == 0, "6", "Arquivos versionados maiores que 50 MB", length(grandes),
        bad = "ATENCAO", nota = paste(grandes, collapse = ", "))
    reg("6", "Maior arquivo versionado (MB)",
        round(max(info$size, na.rm = TRUE) / 1024^2, 2), "INFO")

    ## os recortes CID não estão ignorados
    for (f in c("01_dados/processados/sih_cid_estudo_2010_2024.csv",
                "01_dados/processados/sim_cid_estudo_2010_2024.csv")) {
      out <- suppressWarnings(system2("git", c("-C", shQuote(REPO), "check-ignore",
                                               file.path(basename(ROOT), f)),
                                      stdout = TRUE, stderr = FALSE))
      chk(length(out) == 0, "6", paste0("Recorte versionado e nao ignorado: ", basename(f)),
          if (length(out) == 0) "sim" else "nao")
    }

    ## .rds brutos e modelos não versionados
    out_rds <- suppressWarnings(system2("git", c("-C", shQuote(REPO), "check-ignore",
                                                 file.path(basename(ROOT), "01_dados/brutos_sih/sih_rd_rj_2010_01.rds")),
                                        stdout = TRUE, stderr = FALSE))
    chk(length(out_rds) > 0, "6", "Microdados .rds brutos ignorados pelo Git",
        if (length(out_rds) > 0) "sim" else "nao")
    rds_tracked <- tracked[grepl("\\.rds$", tracked) & !grepl("processados", tracked)]
    chk(length(rds_tracked) == 0, "6", "Arquivos .rds brutos rastreados no Git", length(rds_tracked),
        bad = "ATENCAO", nota = paste(rds_tracked, collapse = ", "))
  } else reg("6", "Git disponivel", "nao", "ATENCAO")

  ## 7. CONSOLIDACAO
  say("\n=========== 7. CONSOLIDACAO ===========")
  r <- rbindlist(res, fill = TRUE)
  fwrite(r, file.path(TAB, "tab26_auditoria_geral.csv"), encoding = "UTF-8", na = "NA")

  tb <- r[, .N, by = classificacao][order(classificacao)]
  say("  verificacoes registradas: ", nrow(r))
  for (i in seq_len(nrow(tb))) say(sprintf("  %-8s %2d", tb$classificacao[i], tb$N[i]))
  erros <- r[classificacao == "ERRO"]
  if (nrow(erros)) {
    say("\n  ERROS:")
    for (i in seq_len(nrow(erros))) say("    - ", erros$bloco[i], " | ", erros$item[i], " | ", erros$valor[i])
  }
  at <- r[classificacao == "ATENCAO"]
  if (nrow(at)) {
    say("\n  ATENCAO:")
    for (i in seq_len(nrow(at))) say("    - ", at$bloco[i], " | ", at$item[i], " | ", at$valor[i])
  }

  ## relatório markdown
  md <- c(
    "# AUDITORIA GERAL DO REPOSITORIO",
    "",
    paste0("**Data da execucao:** ", format(Sys.time())),
    paste0("**Ambiente:** ", R.version.string),
    paste0("**Script:** `02_scripts/12_auditoria_geral.R`"),
    "",
    "Complementa a auditoria de consistencia (`07_auditoria_consistencia.R`), cobrindo",
    "aquisicao, recorte CID versionado, coerencia entre artefatos, tabelas, codigo e higiene do repositorio.",
    "",
    "## Resumo",
    "",
    "| Classificacao | Verificacoes |",
    "|---|---:|")
  for (i in seq_len(nrow(tb)))
    md <- c(md, paste0("| ", tb$classificacao[i], " | ", tb$N[i], " |"))
  md <- c(md, "", "## Verificacoes que exigem atencao", "")
  if (nrow(erros)) {
    md <- c(md, "### ERRO", "")
    for (i in seq_len(nrow(erros)))
      md <- c(md, paste0("- **", erros$bloco[i], "** | ", erros$item[i], " | `", erros$valor[i], "`"))
    md <- c(md, "")
  }
  if (nrow(at)) {
    md <- c(md, "### ATENCAO", "")
    for (i in seq_len(nrow(at)))
      md <- c(md, paste0("- **", at$bloco[i], "** | ", at$item[i], " | `", at$valor[i], "`",
                         if (nzchar(at$nota[i])) paste0(" — ", at$nota[i]) else ""))
    md <- c(md, "")
  }
  md <- c(md, "## Todas as verificacoes", "",
          "| Bloco | Item | Valor | Classificacao | Nota |",
          "|---|---|---|---|---|")
  for (i in seq_len(nrow(r)))
    md <- c(md, paste0("| ", r$bloco[i], " | ", r$item[i], " | ", r$valor[i], " | ",
                       r$classificacao[i], " | ", r$nota[i], " |"))
  writeLines(md, file.path(AUD, "AUDITORIA_GERAL.md"), useBytes = TRUE)

  say("\nrelatorios gravados:")
  say("  10_auditoria/AUDITORIA_GERAL.md")
  say("  05_tabelas/tab26_auditoria_geral.csv")
  say("fim: ", format(Sys.time()))
  close(logcon)
})
