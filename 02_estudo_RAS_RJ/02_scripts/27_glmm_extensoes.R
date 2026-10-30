# 27_glmm_extensoes.R
# Extensões de sensibilidade do GLMM principal (script 05).
#
# Testa se variáveis adicionais disponíveis na coorte melhoram o ajuste e/ou
# explicam a heterogeneidade hospitalar. Cada execução ajusta UM modelo,
# porque um ajuste com ~223 mil internações leva cerca de 10 minutos:
#
#   Rscript 02_scripts/27_glmm_extensoes.R ano
#   Rscript 02_scripts/27_glmm_extensoes.R volume
#   Rscript 02_scripts/27_glmm_extensoes.R volume_ano
#   Rscript 02_scripts/27_glmm_extensoes.R interacao_regiao_ano
#
# O modelo base é lido do RDS gravado pelo script 05 e atualizado com update(),
# o que preserva a mesma amostra e a mesma especificação de referência.
#
# Saídas por modelo:
#   04_resultados/resultados_glmm_extensoes_<modelo>.txt
#   05_tabelas/tab29_glmm_extensoes_<modelo>.csv
#   01_dados/processados/modelo_glmm_extensao_<modelo>.rds
# Depois, 27_consolidar_extensoes.R reúne os resultados.

suppressWarnings({
  options(stringsAsFactors = FALSE)
  library(data.table)
  library(glmmTMB)

  args <- commandArgs(trailingOnly = TRUE)
  if (!length(args)) stop("Informe o modelo: ano, volume, volume_ano ou interacao_regiao_ano")
  MODELO <- args[1]

  ROOT <- normalizePath(".")
  PROC <- file.path(ROOT, "01_dados", "processados")
  RES <- file.path(ROOT, "04_resultados")
  TAB <- file.path(ROOT, "05_tabelas")
  source(file.path(ROOT, "02_scripts", "00_glmm_utils.R"))

  logcon <- file(file.path(RES, paste0("resultados_glmm_extensoes_", MODELO, ".txt")),
                 open = "wt", encoding = "UTF-8")
  say <- function(...) {
    m <- paste0(...); cat(m, "\n"); writeLines(m, logcon); flush(logcon)
  }

  say("=====================================================================")
  say("EXTENSAO DO GLMM PRINCIPAL: ", MODELO)
  say("R ", R.version.string, " | glmmTMB ", as.character(packageVersion("glmmTMB")))
  say("inicio: ", format(Sys.time()))
  say("=====================================================================")

  d <- fread(file.path(PROC, "coorte_glmm_2014_2024.csv"),
             select = c("CNES", "obito_hospitalar", "idade_z", "sexo", "subtipo",
                        "car_int", "uti", "fluxo_inter", "regiao_saude", "ano"),
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

  ## Volume hospitalar é variável de nível 2 (um valor por CNES).
  d[, vol_hosp := .N, by = CNES]
  d[, vol_hosp_1000 := vol_hosp / 1000]

  m0 <- readRDS(file.path(PROC, "modelo_glmm_principal_glmmTMB.rds"))
  say("modelo base: AIC=", round(AIC(m0), 2), " logLik=", round(as.numeric(logLik(m0)), 2),
      " df=", attr(logLik(m0), "df"), " n=", nobs(m0))

  fml <- switch(MODELO,
    ano = update(formula(m0), . ~ . + ano),
    volume = update(formula(m0), . ~ . + vol_hosp_1000),
    volume_ano = update(formula(m0), . ~ . + vol_hosp_1000 + ano),
    interacao_regiao_ano = update(formula(m0), . ~ . + regiao_saude:ano),
    stop("Modelo desconhecido: ", MODELO)
  )

  say("formula: ", paste(deparse(fml), collapse = " "))
  t0 <- Sys.time()
  m <- update(m0, fml, data = d)
  tempo <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
  say("tempo (min): ", round(tempo, 2))
  say("convergencia: ", m$fit$convergence, " | pdHess: ", isTRUE(m$sdr$pdHess))

  vc <- VarCorr(m)$cond
  s2 <- as.numeric(vc$CNES[1, 1])
  im <- icc_mor(s2)
  ll <- as.numeric(logLik(m)); aic <- AIC(m)
  df_m <- attr(logLik(m), "df"); df_0 <- attr(logLik(m0), "df")
  lr <- 2 * (ll - as.numeric(logLik(m0)))
  p_lr <- if (df_m > df_0) pchisq(lr, df_m - df_0, lower.tail = FALSE) else NA_real_

  say("AIC=", round(aic, 2), " | logLik=", round(ll, 2),
      " | sigma2=", round(s2, 5), " | ICC=", round(100 * im$icc, 3), "%",
      " | MOR=", round(im$mor, 4))
  say("LRT vs base: LR=", round(lr, 2), " gl=", df_m - df_0,
      " p=", p_cient(p_lr))

  cf <- summary(m)$coefficients$cond
  termos_novos <- switch(MODELO,
    ano = "ano",
    volume = "vol_hosp_1000",
    volume_ano = c("vol_hosp_1000", "ano"),
    interacao_regiao_ano = grep(":ano$", rownames(cf), value = TRUE)
  )
  coefs <- data.table(
    modelo = MODELO, termo = rownames(cf), beta = cf[, 1], ep = cf[, 2],
    z = cf[, 3], p = cf[, 4], or = exp(cf[, 1]),
    lo = exp(cf[, 1] - 1.96 * cf[, 2]), hi = exp(cf[, 1] + 1.96 * cf[, 2]))
  say("\n--- COEFICIENTES DOS TERMOS ADICIONADOS ---")
  for (i in which(coefs$termo %in% termos_novos))
    say(sprintf("  %-55s OR=%8.4f (IC95%% %8.4f-%8.4f) p=%s",
                coefs$termo[i], coefs$or[i], coefs$lo[i], coefs$hi[i],
                p_cient(coefs$p[i])))

  res <- data.table(
    modelo = MODELO, n = nobs(m), obitos = sum(d$obito_hospitalar),
    sigma2 = round(s2, 6), ICC = round(im$icc, 6), MOR = round(im$mor, 5),
    logLik = round(ll, 3), AIC = round(aic, 3), df = df_m,
    LR_vs_base = round(lr, 2), gl_LR = df_m - df_0, p_LR = p_lr,
    convergencia = m$fit$convergence, pdHess = isTRUE(m$sdr$pdHess),
    tempo_min = round(tempo, 2))
  fwrite(res, file.path(TAB, paste0("tab29_glmm_extensoes_", MODELO, ".csv")),
         encoding = "UTF-8")
  fwrite(coefs[termo %in% termos_novos],
         file.path(TAB, paste0("tab29b_glmm_coefs_", MODELO, ".csv")),
         encoding = "UTF-8")
  saveRDS(m, file.path(PROC, paste0("modelo_glmm_extensao_", MODELO, ".rds")))

  say("\nfim: ", format(Sys.time()))
  close(logcon)
})
