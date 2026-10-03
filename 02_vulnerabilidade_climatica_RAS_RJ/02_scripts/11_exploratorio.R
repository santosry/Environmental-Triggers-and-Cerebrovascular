# 11_exploratorio.R
# Exploração das variáveis que o modelo principal não usa.
#
# O modelo principal (script 05) usa: idade, sexo, subtipo diagnóstico,
# caráter da internação, uso de UTI, fluxo intermunicipal e região de saúde.
# Ficaram de fora, disponíveis nos microdados, raça/cor, escolaridade,
# comorbidade, complexidade, natureza jurídica do estabelecimento,
# permanência, procedimento e intensidade de uso.
#
# O QUE ESTE SCRIPT RESPONDE
#   A. as variáveis tem preenchimento e variabilidade suficientes?
#   B. como se associam a mortalidade intra-hospitalar?
#   C. ajustar por elas muda o VPC/ICC hospitalar?
#   D. ha interação entre sexo e idade, entre raça e região, entre subtipo e UTI?
#   E. o que a permanência hospitalar mostra?
#
# A RESPOSTA EM A E TANTO OU MAIS IMPORTANTE QUE AS DEMAIS. A auditoria
# mostrou que boa parte das variáveis "disponíveis" não e utilizável:
#
#   INFEHOSP   100% vazio em todos os anos.
#   CID_ASSO   traz apenas o valor 0000.
#   NATUREZA   um único valor distinto no arquivo estadual.
#   INSTRU     preenchido em 100% dos registros e CONSTANTE ("sem instrução"
#              em 295.672 de 295.673). Ausencia zero não significa campo útil.
#   DIAGSEC    inexistente até 2013 e, de 2014 em diante, preenchido em no
#              máximo 17% dos registros. Mede codificação, não doença.
#   NAT_JUR    só existe a partir de 2013.
#   RACA_COR   tem registros ausentes que variam de 35,4% (2010) a 0,0% (2024)
#              informativa, com mortalidade bem acima da dos demais.
#              todas. A ausencia e informativa, o que limita a leitura racial.
#
# Saídas:
#   04_resultados/resultados_exploratorio.txt
#   05_tabelas/tab20_preenchimento.csv
#   05_tabelas/tab20b_preenchimento_ano.csv
#   05_tabelas/tab21_exploratorio_bruto.csv
#   05_tabelas/tab22_exploratorio_modelos.csv
#   05_tabelas/tab22b_comorbidade.csv
#   05_tabelas/tab23_exploratorio_or.csv
#   06_figuras/fig_exploratorio.png

suppressWarnings({
  options(stringsAsFactors = FALSE)
  library(data.table)
  library(ggplot2)
  library(ragg)
  source("02_scripts/00_glmm_utils.R")

  ENGINE <- Sys.getenv("GLMM_ENGINE", "glmmTMB")
  ROOT <- normalizePath(".")
  PROC <- file.path(ROOT, "01_dados", "processados")
  RES <- file.path(ROOT, "04_resultados")
  TAB <- file.path(ROOT, "05_tabelas")
  FIG <- file.path(ROOT, "06_figuras", "suplementares")
  dir.create(FIG, showWarnings = FALSE, recursive = TRUE)

  logcon <- file(file.path(RES, "resultados_exploratorio.txt"), open = "wt", encoding = "UTF-8")
  say <- function(...) { m <- paste0(...); cat(m, "\n"); writeLines(m, logcon); flush(logcon) }
  ## print() escreve só no console; este helper leva a tabela também ao log,
  ## para que o arquivo de resultados fique completo.
  mostrar <- function(x) {
    for (l in capture.output(print(x))) say(l)
    invisible(x)
  }

  say("=====================================================================")
  say("EXPLORACAO DAS VARIAVEIS NAO USADAS NO MODELO PRINCIPAL")
  say("R ", R.version.string, " | motor: ", ENGINE, " | inicio: ", format(Sys.time()))
  say("=====================================================================")

  d <- fread(file.path(PROC, "coorte_glmm_2010_2024.csv"), encoding = "UTF-8", na.strings = c("NA",""))
  NEC <- c("raca_cor","instru","n_diag_sec","diagsec_disp","complex_lab","nat_jur_lab",
           "DIAS_PERM","US_TOT","VAL_UTI","obito_hospitalar","idade_anos","idade_z",
           "sexo","subtipo","car_int","uti","fluxo_inter","regiao_saude","CNES","ano")
  falta <- setdiff(NEC, names(d))
  if (length(falta))
    stop("a coorte nao tem as colunas: ", paste(falta, collapse = ", "),
         " -- rode antes o script 02_montar_coorte.R")
  say("internacoes: ", format(nrow(d), big.mark = "."),
      " | obitos: ", format(sum(d$obito_hospitalar), big.mark = "."),
      " | hospitais: ", uniqueN(d$CNES))

  d[, sexo := droplevels(factor(sexo, levels = c("F","M","I")))]
  d[, subtipo := droplevels(factor(subtipo, levels = c(
    "Nao especificado (I64)","Hemorragico (I60-I62)","Isquemico (I63)",
    "Oclusao e outras (I65-I68)","Sequelas (I69)","AIT (G45)",
    "Sindromes vasculares (G46)","Outros")))]
  d[, regiao_saude := droplevels(factor(regiao_saude, levels = c(
    "Metropolitana I","Metropolitana II","Baixada Litoranea","Norte","Noroeste",
    "Serrana","Centro-Sul","Medio Paraiba","Baia da Ilha Grande")))]
  d[, car_int := droplevels(factor(as.character(car_int)))]
  ## Branca como referência, e não Amarela (ordem alfabetica), porque e o
  ## comparador usual em estudos brasileiros de equidade racial.
  d[, raca_cor := droplevels(factor(raca_cor, levels = c("Branca","Preta","Parda",
                                                          "Amarela","Indigena")))]
  d[, instru := droplevels(factor(instru))]
  d[, complex_lab := droplevels(factor(complex_lab))]
  d[, nat_jur_lab := droplevels(factor(nat_jur_lab))]
  d[, faixa_idade := cut(idade_anos, c(-1, 40, 50, 60, 70, 80, 200),
                         labels = c("<40","40-49","50-59","60-69","70-79","80+"))]

  ## A. PREENCHIMENTO E VARIABILIDADE
  say("\n=========== A. PREENCHIMENTO E VARIABILIDADE ===========")
  say("  A verificacao de ausencia NAO basta: um campo pode estar 100%")
  say("  preenchido e ser inutil por ser constante. Foi o caso de INSTRU.")
  VARS <- c("raca_cor","instru","n_diag_sec","complex_lab","nat_jur_lab",
            "DIAS_PERM","US_TOT","VAL_UTI")
  ROT <- c("Raca/cor","Escolaridade","Diagnosticos secundarios","Complexidade",
           "Natureza juridica","Permanencia","Total de servicos","Valor de UTI")
  prop <- rbindlist(lapply(seq_along(VARS), function(i) {
    v <- VARS[i]; x <- d[[v]]
    ## Ausente e NA, como o R representa. Não ha rótulo substituto para
    ## ausencia: um código que a fonte usa para "sem informação" vira NA.
    aus <- mean(is.na(x))
    t <- d[!is.na(x), .N, by = v][order(-N)]
    data.table(variavel = ROT[i], coluna = v, pct_ausente = round(100 * aus, 2),
               n_niveis = uniqueN(x[!is.na(x)]),
               nivel_dominante = if (nrow(t)) sprintf("%s (%.1f%%)",
                                         substr(as.character(t[[1]][1]), 1, 20),
                                         100 * t$N[1] / sum(t$N)) else "sem nivel")
  }))
  prop[, utilizavel := n_niveis > 1 & pct_ausente < 40 &
         !grepl("\\((9[0-9]|100)\\.", nivel_dominante)]
  fwrite(prop, file.path(TAB, "tab20_preenchimento.csv"), encoding = "UTF-8")
  say(sprintf("\n  %-24s %9s %7s %-26s %s", "variavel", "ausente%", "niveis",
              "nivel dominante", "utilizavel"))
  for (i in seq_len(nrow(prop)))
    say(sprintf("  %-24s %8.2f%% %7d %-26s %s", prop$variavel[i], prop$pct_ausente[i],
                prop$n_niveis[i], prop$nivel_dominante[i],
                if (prop$utilizavel[i]) "sim" else "NAO"))

  say("\n  VARIAVEIS INUTILIZAVEIS, VERIFICADAS NOS ARQUIVOS BRUTOS:")
  say("    INFEHOSP  infeccao hospitalar: 100% vazio em 2010 a 2024.")
  say("    CID_ASSO  causa associada: apenas o valor 0000.")
  say("    NATUREZA  um unico valor distinto no arquivo estadual.")
  say("    INSTRU    preenchido em 100% e constante: 295.672 de 295.673")
  say("              registros como 'sem instrucao', o que nao e plausivel e")
  say("              indica campo nao utilizado na pratica. Escolaridade fica fora.")
  say("    ESPEC     varia, mas sem a tabela oficial do DATASUS a interpretacao")
  say("              seria suposicao. Fica registrado, nao interpretado.")

  say("\n  DISPONIBILIDADE AO LONGO DO TEMPO:")
  por_ano <- d[, .(n = .N,
                   sem_sec = sprintf("%.1f%%", 100 * mean(n_diag_sec == 0)),
                   media_sec = sprintf("%.2f", mean(n_diag_sec)),
                   raca_aus = sprintf("%.1f%%", 100 * mean(is.na(raca_cor))),
                   natjur_aus = sprintf("%.1f%%", 100 * mean(is.na(nat_jur_lab))),
                   instru_aus = sprintf("%.1f%%", 100 * mean(is.na(instru)))),
               by = ano][order(ano)]
  mostrar(por_ano)
  fwrite(por_ano, file.path(TAB, "tab20b_preenchimento_ano.csv"), encoding = "UTF-8")
  say("\n  Leitura: DIAGSEC inexiste ate 2013 e, de 2014 em diante, esta")
  say("  preenchido em no maximo 17% dos registros. NAT_JUR so existe a partir")
  say("  de 2013. RACA_COR tem ausencia decrescente, de 35,4% em 2010 a 0,0% em")
  say("  2024, o que por si so ja cria gradiente temporal na variavel.")
  say("  Os ausentes sao NA; nao existe rotulo substituto para ausencia.")

  ## ---- a mortalidade de quem tem ausencia: a ausencia e informativa? ----
  say("\n  A AUSENCIA E INFORMATIVA? Mortalidade de quem tem NA contra quem tem valor:")
  for (v in c("raca_cor","instru","nat_jur_lab")) {
    x <- d[[v]]
    if (all(is.na(x)) || !any(is.na(x))) {
      say(sprintf("    %-14s sem NA ou todo NA; nao se aplica", v)); next
    }
    m_na <- 100 * mean(d$obito_hospitalar[is.na(x)])
    m_ok <- 100 * mean(d$obito_hospitalar[!is.na(x)])
    say(sprintf("    %-14s com NA: %6.2f%% (n=%s) | sem NA: %6.2f%% (n=%s) | diferenca %+.2f p.p.",
                v, m_na, format(sum(is.na(x)), big.mark = "."),
                m_ok, format(sum(!is.na(x)), big.mark = "."), m_na - m_ok))
  }

  ## B. ASSOCIAÇÃO BRUTA
  say("\n=========== B. ASSOCIACAO BRUTA COM A MORTALIDADE ===========")
  bruto <- list()
  addb <- function(var, rot) {
    t <- d[, .(n = .N, obitos = sum(obito_hospitalar),
               mortalidade_pct = round(100 * mean(obito_hospitalar), 2)), by = var]
    setnames(t, var, "nivel")
    t[, `:=`(variavel = rot, nivel = as.character(nivel))]
    bruto[[length(bruto) + 1]] <<- t[n >= 500]
  }
  addb("raca_cor", "Raca/cor")
  addb("complex_lab", "Complexidade")
  addb("nat_jur_lab", "Natureza juridica")
  addb("n_diag_sec", "Diagnosticos secundarios")
  dd <- rbindlist(bruto)[order(variavel, -mortalidade_pct)]
  fwrite(dd, file.path(TAB, "tab21_exploratorio_bruto.csv"), encoding = "UTF-8")
  for (v in unique(dd$variavel)) {
    say("   ", v, ":")
    sub <- dd[variavel == v]
    for (i in seq_len(nrow(sub)))
      say(sprintf("      %-34s n=%9s  mortalidade=%6.2f%%",
                  substr(sub$nivel[i], 1, 34),
                  format(sub$n[i], big.mark = "."), sub$mortalidade_pct[i]))
  }
  say("\n  A mortalidade de quem tem raca/cor ausente e reportada acima.")
  say("  de todas as categorias. A ausencia nao e aleatoria.")

  ## C. OS MODELOS ESTENDIDOS MUDAM O VPC/ICC?
  say("\n=========== C. IMPACTO NO COMPONENTE HOSPITALAR ===========")
  BASE <- obito_hospitalar ~ idade_z + sexo + subtipo + car_int + uti + fluxo_inter +
    regiao_saude + (1 | CNES)

  ## A base tem 52 colunas. Converter a tabela inteira para data.frame a cada
  ## ajuste multiplica o tempo e a memória sem necessidade: aqui se constroi UMA
  ## vez o data.frame enxuto, só com as colunas que os modelos usam.
  COLS_MOD <- c("obito_hospitalar","idade_z","sexo","subtipo","car_int","uti",
                "fluxo_inter","regiao_saude","CNES","raca_cor","nat_jur_lab",
                "complex_lab","n_diag_sec","faixa_idade","ano")
  dm <- as.data.frame(d[, ..COLS_MOD])
  dm14 <- dm[dm$ano >= 2014, ]
  say("  data.frame enxuto para os ajustes: ", nrow(dm), " linhas x ",
      ncol(dm), " colunas (", format(object.size(dm), units = "MB"), ")")

  ## Ausente e NA. Em vez de criar um nível falso para ausencia, cada modelo e
  ## ajustado nos casos completos das variáveis que ele usa, e o n resultante e
  ## reportado. E o comportamento nativo do R.
  dm_completo <- function(fml, dd = dm) {
    vars <- intersect(all.vars(fml), names(dd))
    dd[complete.cases(dd[, vars, drop = FALSE]), , drop = FALSE]
  }
  say("  casos completos por modelo (ausentes sao NA e sao omitidos):")
  for (e in list(BASE, update(BASE, . ~ . + raca_cor),
                 update(BASE, . ~ . + nat_jur_lab),
                 update(BASE, . ~ . + complex_lab),
                 update(BASE, . ~ . + raca_cor + nat_jur_lab + complex_lab)))
    say(sprintf("    n = %9s", format(nrow(dm_completo(e)), big.mark = ".")))

  espec <- list(
    list(rot = "M0 principal (script 05)", fml = BASE),
    list(rot = "M1 + raca/cor",            fml = update(BASE, . ~ . + raca_cor)),
    list(rot = "M2 + natureza juridica",   fml = update(BASE, . ~ . + nat_jur_lab)),
    list(rot = "M3 + complexidade",        fml = update(BASE, . ~ . + complex_lab)),
    list(rot = "M4 completo",              fml = update(BASE, . ~ . + raca_cor +
                                                          nat_jur_lab + complex_lab)))
  ## ATENÇÃO METODOLÓGICA. Como ausente e NA, cada modelo estendido e ajustado em
  ## um conjunto diferente de casos completos. Comparar o sigma^2 de um modelo
  ## estendido com o do modelo principal ajustado em OUTRA amostra confundiria o
  ## efeito da variável com o efeito da mudanca de amostra. Por isso, para cada
  ## modelo estendido, o modelo BASE e reajustado na MESMA amostra, e a
  ## comparação e feita contra essa base.
  mods <- list(); ors <- list(); compar <- list()
  for (e in espec) {
    dados <- dm_completo(e$fml)
    usa_extras <- length(all.vars(e$fml)) > length(all.vars(BASE))
    fit_base <- if (usa_extras) fit_glmm(BASE, dados, engine = ENGINE) else NULL
    fit <- fit_glmm(e$fml, dados, engine = ENGINE)
    s2m <- fit$vc$vcov[fit$vc$grp == "CNES"][1]
    im <- icc_mor(s2m)
    s2b <- if (usa_extras) fit_base$vc$vcov[fit_base$vc$grp == "CNES"][1] else s2m
    mods[[e$rot]] <- data.table(
      modelo = e$rot, n = fit$n, sigma2 = round(s2m, 5), ICC = round(im$icc, 5),
      MOR = round(im$mor, 4), AIC = round(fit$AIC, 1), tempo_min = round(fit$tempo_min, 2))
    compar[[e$rot]] <- data.table(
      modelo = e$rot, n = fit$n,
      sigma2_base_mesma_amostra = round(s2b, 5),
      ICC_base_mesma_amostra = round(icc_mor(s2b)$icc, 5),
      sigma2_modelo = round(s2m, 5), ICC_modelo = round(im$icc, 5),
      delta_ICC_pp = round(100 * (im$icc - icc_mor(s2b)$icc), 3),
      var_hosp_explicada_pct = round(100 * (s2b - s2m) / s2b, 1))
    ors[[e$rot]] <- data.table(modelo = e$rot, termo = fit$coef$termo,
                               or = fit$coef$or, lo = fit$coef$lo, hi = fit$coef$hi,
                               p = fit$coef$p)
    say(sprintf("\n### %-30s sigma2=%.5f ICC=%.5f MOR=%.4f AIC=%.1f (%.1f min)",
                e$rot, s2m, im$icc, im$mor, fit$AIC, fit$tempo_min))
    if (usa_extras)
      say(sprintf("      base na MESMA amostra (n=%s): sigma2=%.5f ICC=%.5f -> variacao %+.3f p.p.",
                  format(fit$n, big.mark = "."), s2b, icc_mor(s2b)$icc,
                  100 * (im$icc - icc_mor(s2b)$icc)))
    novos <- fit$coef[grepl("^(raca_cor|nat_jur_lab|complex_lab|instru|n_diag_sec)", termo)]
    for (i in seq_len(nrow(novos)))
      say(sprintf("      %-40s OR=%7.3f (IC95%% %6.3f-%7.3f) p=%s",
                  novos$termo[i], novos$or[i], novos$lo[i], novos$hi[i],
                  p_cient(novos$p[i])))
  }
  md <- rbindlist(mods)
  cmp <- rbindlist(compar)
  md <- merge(md, cmp[, .(modelo, ICC_base_mesma_amostra, delta_ICC_pp,
                          var_hosp_explicada_pct)], by = "modelo", all.x = TRUE)
  fwrite(md, file.path(TAB, "tab22_exploratorio_modelos.csv"), encoding = "UTF-8")
  fwrite(cmp, file.path(TAB, "tab22c_comparacao_mesma_amostra.csv"), encoding = "UTF-8")
  fwrite(rbindlist(ors), file.path(TAB, "tab23_exploratorio_or.csv"), encoding = "UTF-8")

  say("\n  IMPACTO NO VPC/ICC, SEMPRE CONTRA A BASE NA MESMA AMOSTRA:")
  say(sprintf("    %-30s %9s %9s %9s %10s %11s", "modelo", "n", "ICC base",
              "ICC mod.", "delta pp", "var expl."))
  for (i in seq_len(nrow(cmp)))
    say(sprintf("    %-30s %9s %8.2f%% %8.2f%% %+9.3f %10.1f%%", cmp$modelo[i],
                format(cmp$n[i], big.mark = "."), 100 * cmp$ICC_base_mesma_amostra[i],
                100 * cmp$ICC_modelo[i], cmp$delta_ICC_pp[i],
                cmp$var_hosp_explicada_pct[i]))

  ## ---- comorbidade: só onde o campo existe ----
  say("\n  COMORBIDADE (DIAGSEC), restrita a 2014-2024, unico periodo com o campo:")
  d14 <- d[ano >= 2014]
  fml_c <- update(BASE, . ~ . + n_diag_sec)
  d14c <- dm_completo(fml_c, dm14)
  f_b <- fit_glmm(BASE, d14c, engine = ENGINE)
  f_c <- fit_glmm(fml_c, d14c, engine = ENGINE)
  s_b <- f_b$vc$vcov[f_b$vc$grp == "CNES"][1]
  s_c <- f_c$vc$vcov[f_c$vc$grp == "CNES"][1]
  say(sprintf("    sem comorbidade: n=%s | sigma2=%.5f | ICC=%.2f%% | AIC=%.1f",
              format(f_b$n, big.mark = "."), s_b, 100 * icc_mor(s_b)$icc, f_b$AIC))
  say(sprintf("    com comorbidade: n=%s | sigma2=%.5f | ICC=%.2f%% | AIC=%.1f",
              format(f_c$n, big.mark = "."), s_c, 100 * icc_mor(s_c)$icc, f_c$AIC))
  orc <- f_c$coef[termo == "n_diag_sec"]
  if (nrow(orc))
    say(sprintf("    OR por diagnostico secundario adicional: %.4f (IC95%% %.4f-%.4f) p=%s",
                orc$or, orc$lo, orc$hi, p_cient(orc$p)))
  say(sprintf("    a comorbidade explica %.1f%% da variancia hospitalar nesse periodo",
              100 * (s_b - s_c) / s_b))
  say("    leitura: o campo mede quantidade de codificacao tanto quanto doenca, e a")
  say("    associacao bruta nao e monotonica (0 codigos 16,95%; 1 codigo 41,41%;")
  say("    2 codigos 23,23%; 3 codigos 31,94%). O OR e indicativo, nao efeito.")
  fwrite(data.table(
    modelo = c("2014-2024 sem comorbidade", "2014-2024 com comorbidade"),
    n = c(f_b$n, f_c$n), sigma2 = round(c(s_b, s_c), 5),
    ICC = round(c(icc_mor(s_b)$icc, icc_mor(s_c)$icc), 5),
    MOR = round(c(icc_mor(s_b)$mor, icc_mor(s_c)$mor), 4),
    AIC = round(c(f_b$AIC, f_c$AIC), 1)),
    file.path(TAB, "tab22b_comorbidade.csv"), encoding = "UTF-8")

  ## D. INTERAÇÕES
  say("\n=========== D. INTERACOES ===========")
  ## o modelo base e ajustado UMA vez e reaproveitado nas três comparacoes
  f0 <- fit_glmm(BASE, dm_completo(BASE), engine = ENGINE)
  inter <- list(
    list(rot = "sexo x faixa de idade", fml = update(BASE, . ~ . - sexo + sexo:faixa_idade)),
    list(rot = "subtipo x UTI",         fml = update(BASE, . ~ . + subtipo:uti)),
    list(rot = "raca x regiao",         fml = update(BASE, . ~ . + raca_cor:regiao_saude)))
  ## A interação raça x região acrescenta 45 termos e domina o tempo de execucao.
  ## Fica desligada por padrão e pode ser ligada com GLMM_INTER_RACA=1.
  if (Sys.getenv("GLMM_INTER_RACA", "0") != "1") {
    inter <- inter[!vapply(inter, function(z) z$rot == "raca x regiao", logical(1))]
    say("  (interacao raca x regiao desativada; use GLMM_INTER_RACA=1 para incluir)")
  }
  ## Os graus de liberdade de um teste de razão de verossimilhança são a
  ## diferenca de parâmetros ESTIMADOS, que não se le no vetor de coeficientes
  ## fixos (foi o erro da primeira versão, que devolvia gl = 0). O número de
  ## parâmetros e estrutural, então pode ser contado em uma subamostra pequena,
  ## sem depender do tamanho da amostra completa.
  dm_sub <- dm[sample(nrow(dm), 20000), ]
  npar <- function(fml) attr(logLik(fit_glmm(fml, dm_sub, engine = ENGINE)$model), "df")
  k0 <- npar(BASE)
  say("  parametros estimados no modelo base: ", k0)

  intr <- list()
  for (it in inter) {
    f1 <- fit_glmm(it$fml, dm_completo(it$fml), engine = ENGINE)
    gl <- npar(it$fml) - k0
    dif <- 2 * (f1$logLik - f0$logLik)
    pv <- if (gl > 0) pchisq(dif, gl, lower.tail = FALSE) else NA_real_
    intr[[it$rot]] <- data.table(interacao = it$rot, gl = gl, LR = round(dif, 1),
                                 p = pv, AIC_base = round(f0$AIC, 1),
                                 AIC_com = round(f1$AIC, 1))
    say(sprintf("  %-24s gl=%3d | LR=%8.1f | p=%s | AIC %.0f -> %.0f",
                it$rot, gl, dif, p_cient(pv), f0$AIC, f1$AIC))
  }
  fwrite(rbindlist(intr), file.path(TAB, "tab24_interacoes.csv"), encoding = "UTF-8")

  ## E. PERMANÊNCIA
  say("\n=========== E. PERMANENCIA HOSPITALAR ===========")
  d[, obito_lab := fifelse(obito_hospitalar == 1, "Obito", "Alta")]
  d[, uti_lab := fifelse(uti == 1, "Com UTI", "Sem UTI")]
  perm <- d[!is.na(DIAS_PERM) & DIAS_PERM >= 0 & DIAS_PERM <= 365,
            .(n = .N, media = round(mean(DIAS_PERM), 2),
              p25 = as.numeric(quantile(DIAS_PERM, .25)), mediana = as.numeric(median(DIAS_PERM)),
              p75 = as.numeric(quantile(DIAS_PERM, .75)), p90 = as.numeric(quantile(DIAS_PERM, .90))),
            by = .(desfecho = obito_lab, uti = uti_lab)]
  mostrar(perm)
  fwrite(perm, file.path(TAB, "tab25_permanencia.csv"), encoding = "UTF-8")
  say("\n  permanencia mediana por subtipo:")
  print(d[!is.na(DIAS_PERM), .(n = .N, mediana = median(DIAS_PERM)), by = subtipo][order(-n)])
  say("\n  permanencia mediana e mortalidade por regiao de saude:")
  print(d[!is.na(DIAS_PERM), .(n = .N, mediana_permanencia = median(DIAS_PERM),
                               mortalidade = sprintf("%.2f%%", 100 * mean(obito_hospitalar))),
          by = regiao_saude][order(-n)])
  ## F. FIGURAS
  ## A figura-painel e produzida pelo script 19, que le os resultados
  ## já cacheados em 05_tabelas e dispensa o reajuste dos modelos.
  source("02_scripts/19_figura_exploratorio.R", local = new.env())

  say("\nfim: ", format(Sys.time()))
  close(logcon)
})
