# =====================================================================
# 08_glmm_robustez.R
# ---------------------------------------------------------------------
# Analises de robustez do Bloco 2 do PLANO_METODOLOGICO_GLMM_COX.md.
#
# Cada cenario reajusta o MESMO GLMM logistico multinivel alterando um
# unico aspecto: covariavel sob suspeita, periodo, recorte diagnostico,
# conjunto de hospitais, estrutura de efeitos aleatorios, forma funcional
# da idade ou configuracao numerica do ajuste.
#
# A comparacao entre motores (glmmTMB x lme4) fica no script 09.
# Nao se aplica regressao logistica simples univariada, Cox ou Moran/LISA.
# O cenario S12 (modelo agrupado) existe apenas para dimensionar o ganho da
# estrutura multinivel; nao e um modelo univariado.
#
# Saidas:
#   04_resultados/resultados_glmm_robustez.txt
#   05_tabelas/tab8_robustez_componentes.csv
#   05_tabelas/tab9_robustez_or.csv
#   05_tabelas/tab10_robustez_or_largo.csv
# =====================================================================

suppressWarnings({
  options(stringsAsFactors = FALSE)
  library(data.table)
  library(splines)
  source("02_scripts/00_glmm_utils.R")

  ENGINE <- Sys.getenv("GLMM_ENGINE", "glmmTMB")

  ROOT <- normalizePath(".")
  PROC <- file.path(ROOT, "01_dados", "processados")
  RES <- file.path(ROOT, "04_resultados")
  TAB <- file.path(ROOT, "05_tabelas")

  logcon <- file(file.path(RES, "resultados_glmm_robustez.txt"), open = "wt", encoding = "UTF-8")
  say <- function(...) { m <- paste0(...); cat(m, "\n"); writeLines(m, logcon); flush(logcon) }

  say("=====================================================================")
  say("ROBUSTEZ DO GLMM")
  say("R ", R.version.string, " | motor principal: ", ENGINE)
  say("inicio: ", format(Sys.time()))
  say("=====================================================================")

  ## ================= dados =================
  d <- fread(file.path(PROC, "coorte_glmm_2010_2024.csv"),
             select = c("CNES", "obito_hospitalar", "idade_anos", "idade_z", "sexo",
                        "subtipo", "cid3", "cid4", "car_int", "uti", "uti_marca",
                        "fluxo_inter", "regiao_saude", "ano", "coorte"),
             na.strings = c("", "NA"), encoding = "UTF-8")
  d[, CNES := factor(CNES)]
  d[, sexo := factor(sexo, levels = c("F", "M", "I"))]
  d[, subtipo := factor(subtipo, levels = c(
    "Nao especificado (I64)", "Hemorragico (I60-I62)", "Isquemico (I63)",
    "Oclusao e outras (I65-I68)", "Sequelas (I69)", "AIT (G45)",
    "Sindromes vasculares (G46)", "Outros"))]
  d[, regiao_saude := factor(regiao_saude, levels = c(
    "Metropolitana I", "Metropolitana II", "Baixada Litoranea", "Norte", "Noroeste",
    "Serrana", "Centro-Sul", "Medio Paraiba", "Baia da Ilha Grande"))]
  d[, car_int := factor(as.character(car_int))]
  for (v in c("CNES", "sexo", "subtipo", "regiao_saude", "car_int"))
    d[, (v) := droplevels(get(v))]
  say("base: ", format(nrow(d), big.mark = "."), " internacoes | ",
      uniqueN(d$CNES), " hospitais | ", uniqueN(d$regiao_saude), " regioes")

  TERMOS <- c("idade_z", "sexoM", "subtipoHemorragico (I60-I62)", "subtipoIsquemico (I63)",
              "subtipoOclusao e outras (I65-I68)", "subtipoSequelas (I69)",
              "subtipoAIT (G45)", "subtipoSindromes vasculares (G46)",
              "car_intUrgencia", "uti", "fluxo_inter",
              "regiao_saudeMetropolitana II", "regiao_saudeBaixada Litoranea",
              "regiao_saudeNorte", "regiao_saudeNoroeste", "regiao_saudeSerrana",
              "regiao_saudeCentro-Sul", "regiao_saudeMedio Paraiba",
              "regiao_saudeBaia da Ilha Grande")

  res <- list()
  prep_sub <- function(x) {
    for (v in c("CNES", "sexo", "subtipo", "regiao_saude", "car_int"))
      if (v %in% names(x)) x[, (v) := droplevels(get(v))]
    x
  }
  add_fit <- function(dat, fml, label, ...) {
    dat <- prep_sub(dat)
    fit <- tryCatch(fit_glmm(fml, as.data.frame(dat), engine = ENGINE, ...),
                    error = function(e) { say(sprintf("\n### %-30s ERRO: %s", label,
                                                      conditionMessage(e))); NULL })
    if (is.null(fit)) return(invisible(NULL))
    s2 <- if ("CNES" %in% fit$vc$grp) fit$vc$vcov[fit$vc$grp == "CNES"][1] else NA_real_
    im <- if (is.na(s2)) list(icc = NA_real_, mor = NA_real_) else icc_mor(s2)
    comp <- data.table(
      cenario = label, n = fit$n, obitos = sum(dat$obito_hospitalar),
      hospitais = uniqueN(dat$CNES), efeitos_aleatorios = paste(fit$vc$grp, collapse = "+"),
      s2 = round(s2, 5), sd = round(sqrt(s2), 5), ICC = round(im$icc, 5),
      MOR = round(im$mor, 4), logLik = round(fit$logLik, 1), AIC = round(fit$AIC, 1),
      convergiu = fit$convergiu, singular = fit$singular, tempo_min = round(fit$tempo_min, 2))
    say(sprintf("\n### %-30s n=%7s | s2=%7s | ICC=%7s | MOR=%6s | AIC=%9s | conv=%s | %.2f min",
                label, format(fit$n, big.mark = "."), as.character(comp$s2),
                as.character(comp$ICC), as.character(comp$MOR), as.character(comp$AIC),
                comp$convergiu, fit$tempo_min))
    res[[length(res) + 1]] <<- list(
      comp = comp,
      or = data.table(cenario = label, termo = fit$coef$termo, or = fit$coef$or,
                      lo = fit$coef$lo, hi = fit$coef$hi, p = fit$coef$p))
  }

  add_pooled <- function(dat, label) {
    t0 <- Sys.time()
    m <- glm(obito_hospitalar ~ idade_z + sexo + subtipo + car_int + uti + fluxo_inter +
               regiao_saude, data = dat, family = binomial)
    cf <- summary(m)$coefficients
    res[[length(res) + 1]] <<- list(
      comp = data.table(cenario = label, n = nrow(dat), obitos = sum(dat$obito_hospitalar),
                        hospitais = uniqueN(dat$CNES), efeitos_aleatorios = "nenhum",
                        s2 = NA_real_, sd = NA_real_, ICC = NA_real_, MOR = NA_real_,
                        logLik = round(as.numeric(logLik(m)), 1), AIC = round(AIC(m), 1),
                        convergiu = m$converged, singular = NA, 
                        tempo_min = round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 2)),
      or = data.table(cenario = label, termo = rownames(cf), or = exp(cf[, 1]),
                      lo = exp(cf[, 1] - 1.96 * cf[, 2]), hi = exp(cf[, 1] + 1.96 * cf[, 2]),
                      p = cf[, 4]))
    say(sprintf("\n### %-30s n=%7s | sem efeito aleatorio | AIC=%9s",
                label, format(nrow(dat), big.mark = "."), as.character(round(AIC(m), 1))))
  }

  BASE <- obito_hospitalar ~ idade_z + sexo + subtipo + car_int + uti + fluxo_inter +
    regiao_saude + (1 | CNES)

  ## ================= cenarios =================
  say("\n\n================ CENARIOS ================")

  ## S0 principal
  add_fit(d, BASE, "S0_principal")

  ## --- papel da UTI (mediador potencial) ---
  add_fit(d, obito_hospitalar ~ idade_z + sexo + subtipo + car_int + fluxo_inter +
            regiao_saude + (1 | CNES), "S1_sem_UTI")
  add_fit(d, obito_hospitalar ~ idade_z + sexo + subtipo + car_int + uti_marca +
            fluxo_inter + regiao_saude + (1 | CNES), "S2_UTI_por_MARCA_UTI")

  ## --- periodo ---
  add_fit(d[ano >= 2015], BASE, "S3_periodo_2015_2024")
  add_fit(d[ano <= 2014], BASE, "S4_periodo_2010_2014")

  ## --- recorte diagnostico ---
  add_fit(d[cid3 != "I69"], BASE, "S5_sem_I69")
  add_fit(d[coorte == "I60-I69"], BASE, "S6_somente_I60_I69")
  add_fit(d[coorte == "G45/G46"], BASE, "S7_somente_G45_G46")

  ## --- categoria diagnostica sem quarto digito ---
  ## Praticamente todos os diagnosticos de 3 caracteres sao I64, que e uma
  ## categoria completa da CID-10 (AVC nao especificado quanto a hemorragia ou
  ## infarto) e responde por 56,6% da coorte. O cenario remove essa categoria.
  add_fit(d[nchar(as.character(cid4)) == 4], BASE, "S8_sem_categoria_I64")

  ## --- influencia de hospitais ---
  hb <- d[, .(n = .N, ob = sum(obito_hospitalar)), by = CNES]
  add_fit(d[CNES %in% hb[n >= 100]$CNES], BASE, "S9_hospitais_100mais")
  add_fit(d[CNES %in% hb[ob > 0]$CNES], BASE, "S10_sem_hospitais_sem_obito")
  add_fit(d[CNES %in% hb[ob >= 10]$CNES], BASE, "S11_hospitais_10mais_obitos")

  ## --- estrutura de efeitos aleatorios ---
  add_fit(d, obito_hospitalar ~ idade_z + sexo + subtipo + car_int + uti + fluxo_inter +
            (1 | CNES) + (1 | regiao_saude), "S12_regiao_aleatoria")
  add_pooled(d, "S13_sem_efeito_aleatorio")

  ## --- forma funcional e tendencia ---
  add_fit(d, obito_hospitalar ~ ns(idade_anos, 3) + sexo + subtipo + car_int + uti +
            fluxo_inter + regiao_saude + (1 | CNES), "S14_idade_spline_ns3")
  add_fit(d, obito_hospitalar ~ idade_z + sexo + subtipo + car_int + uti + fluxo_inter +
            regiao_saude + ano + (1 | CNES), "S15_com_tendencia_ano")

  ## --- configuracao numerica e forma funcional alternativa da idade ---
  ## S16 e S18 nao existem: o glmmTMB nao aceita os argumentos nAGQ nem rel.tol.
  ## A adequacao da aproximacao de Laplace e verificada por quadratura de
  ## Gauss-Hermite no lme4, no script 09, e a robustez numerica fica coberta
  ## pelo otimizador alternativo S17. A numeracao abaixo foi mantida igual a da
  ## execucao registrada em 04_resultados/resultados_glmm_robustez.txt.
  add_fit(d, BASE, "S17_otimizador_optim_BFGS", optimizer = optim,
          optArgs = list(method = "BFGS"))
  d[, faixa5 := cut(idade_anos, breaks = c(-1, 45, 60, 75, 200),
                    labels = c("<45", "45-59", "60-74", "75+"))]
  add_fit(d, obito_hospitalar ~ faixa5 + sexo + subtipo + car_int + uti + fluxo_inter +
            regiao_saude + (1 | CNES), "S19_idade_categorica")

  ## ================= consolidacao =================
  comp <- rbindlist(lapply(res, function(x) x$comp), fill = TRUE)
  fwrite(comp, file.path(TAB, "tab8_robustez_componentes.csv"), encoding = "UTF-8")

  orl <- rbindlist(lapply(res, function(x) x$or), fill = TRUE)
  fwrite(orl, file.path(TAB, "tab9_robustez_or.csv"), encoding = "UTF-8")
  w <- dcast(orl[termo %in% TERMOS], termo ~ cenario, value.var = "or")
  fwrite(w, file.path(TAB, "tab10_robustez_or_largo.csv"), encoding = "UTF-8")

  say("\n\n================ ESTABILIDADE DOS COMPONENTES ================")
  for (i in seq_len(nrow(comp)))
    say(sprintf("  %-30s n=%8s s2=%8s ICC=%8s MOR=%7s AIC=%10s conv=%s",
                comp$cenario[i], format(comp$n[i], big.mark = "."),
                as.character(comp$s2[i]), as.character(comp$ICC[i]),
                as.character(comp$MOR[i]), as.character(comp$AIC[i]),
                as.character(comp$convergiu[i])))

  say("\n\n================ OR POR CENARIO (termos centrais) ================")
  for (t in TERMOS) {
    sub <- orl[termo == t]
    if (nrow(sub) == 0) next
    say(sprintf("\n%s", t))
    for (i in seq_len(nrow(sub)))
      say(sprintf("   %-30s OR=%7.3f (IC95%% %6.3f-%7.3f) p=%s",
                  sub$cenario[i], sub$or[i], sub$lo[i], sub$hi[i], p_cient(sub$p[i])))
  }

  say("\nfim: ", format(Sys.time()))
  close(logcon)
})
