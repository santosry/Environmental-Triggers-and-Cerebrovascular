# 05_glmm_principal.R
# Bloco 2 do PLANO_METODOLOGICO_GLMM_COX.md
# Modelo logístico multinível (GLMM) do óbito intra-hospitalar:
#
#   logit(P(Obito_ijk = 1)) = b0 + b'X_ijk + u_j + g_k
#
#   Nível 1 (paciente): idade padronizada, sexo, subtipo diagnóstico
#                       (I60-I69 e G45/G46), caráter da internação,
#                       uso de UTI, fluxo intermunicipal
#   Nível 2 (hospital): intercepto aleatório por CNES, u_j ~ N(0, s2_hosp)
#   Nível 3 (região):   efeito fixo da região de saúde (9 regiões)
#
# Metricas: OR ajustado com IC95% e p, variância hospitalar, VPC/ICC e MOR.
# Não se aplica regressão logistica simples univariada, Cox ou Moran/LISA.
#
# Motor: glmmTMB (principal). lme4 na mesma especificacao e conferido pelo
# script 09. Variável de ambiente GLMM_ENGINE permite trocar o motor.
#
# Saídas:
#   04_resultados/resultados_glmm_principal.txt
#   05_tabelas/tab3_glmm_or.csv
#   05_tabelas/tab4_glmm_componentes.csv
#   05_tabelas/tab5_calibracao.csv
#   01_dados/processados/previsoes_glmm.csv
#   01_dados/processados/efeitos_hospital_glmm.csv
#   01_dados/processados/modelo_glmm_principal.rds

suppressWarnings({
  options(stringsAsFactors = FALSE)
  library(data.table)
  source("02_scripts/00_glmm_utils.R")

  ENGINE <- Sys.getenv("GLMM_ENGINE", "glmmTMB")

  ROOT <- normalizePath(".")
  PROC <- file.path(ROOT, "01_dados", "processados")
  RES <- file.path(ROOT, "04_resultados")
  TAB <- file.path(ROOT, "05_tabelas")
  dir.create(RES, showWarnings = FALSE, recursive = TRUE)
  dir.create(TAB, showWarnings = FALSE, recursive = TRUE)

  logcon <- file(file.path(RES, "resultados_glmm_principal.txt"), open = "wt", encoding = "UTF-8")
  say <- function(...) {
    m <- paste0(...); cat(m, "\n"); writeLines(m, logcon); flush(logcon)
  }

  say("=====================================================================")
  say("GLMM PRINCIPAL - OBITO INTRA-HOSPITALAR")
  say("R ", R.version.string, " | motor: ", ENGINE,
      " | glmmTMB ", if (requireNamespace("glmmTMB", quietly = TRUE))
        as.character(packageVersion("glmmTMB")) else "n/d",
      " | lme4 ", if (requireNamespace("lme4", quietly = TRUE))
        as.character(packageVersion("lme4")) else "n/d")
  say("inicio: ", format(Sys.time()))
  say("=====================================================================")

  ## ================= 1. dados =================
  d <- fread(file.path(PROC, "coorte_glmm_2014_2024.csv"),
             select = c("CNES", "obito_hospitalar", "idade_anos", "idade_z", "sexo",
                        "subtipo", "cid3", "car_int", "uti", "uti_marca", "fluxo_inter",
                        "regiao_saude", "ano"),
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

  say("n = ", format(nrow(d), big.mark = "."),
      " | obitos = ", format(sum(d$obito_hospitalar), big.mark = "."),
      sprintf(" (%.2f%%)", 100 * mean(d$obito_hospitalar)))
  say("hospitais (CNES) = ", uniqueN(d$CNES), " | regioes = ", uniqueN(d$regiao_saude))
  say("\ncar_int:"); print(d[, .N, by = car_int][order(-N)])
  say("sexo:"); print(d[, .N, by = sexo][order(-N)])
  say("subtipo:"); print(d[, .N, by = subtipo][order(-N)])
  say("fluxo_inter:"); print(d[, .N, by = fluxo_inter][order(-N)])
  say("uti:"); print(d[, .N, by = uti][order(-N)])
  say("\nniveis de referencia: subtipo=", levels(d$subtipo)[1],
      " | sexo=", levels(d$sexo)[1], " | car_int=", levels(d$car_int)[1],
      " | regiao=", levels(d$regiao_saude)[1])

  ## trava de seguranca
  crit <- c("obito_hospitalar", "idade_z", "sexo", "subtipo", "car_int", "uti",
            "fluxo_inter", "regiao_saude", "CNES")
  say("\n--- TRAVA DE SEGURANCA (covariaveis do modelo) ---")
  falha <- FALSE
  for (v in crit) {
    na <- sum(is.na(d[[v]])); pct <- 100 * na / nrow(d)
    if (pct > 0.1) falha <- TRUE
    say(sprintf("  %-18s NA=%7d (%6.3f%%)%s", v, na, pct,
                if (pct > 0.1) "   <== FALHA" else ""))
  }
  if (falha) stop("Covariavel do modelo com perda acima de 0,1%. Nao ajustar o modelo.")
  say("  OK")

  ## ================= 2. ajuste =================
  fml <- obito_hospitalar ~ idade_z + sexo + subtipo + car_int + uti + fluxo_inter +
    regiao_saude + (1 | CNES)

  say("\n--- AJUSTE DO MODELO ---")
  say("formula: ", paste(deparse(fml), collapse = " "))
  fit <- fit_glmm(fml, as.data.frame(d), engine = ENGINE)

  say("tempo de ajuste (min): ", round(fit$tempo_min, 2))
  say("convergiu: ", fit$convergiu, " | mensagem: ", fit$mensagem)
  say("singular: ", fit$singular)
  say("log-verossimilhanca: ", round(fit$logLik, 2), " | AIC: ", round(fit$AIC, 2))

  ## ================= 3. componentes =================
  say("\n--- VARIANCIA DOS EFEITOS ALEATORIOS ---")
  print(fit$vc)
  s2 <- fit$vc$vcov[fit$vc$grp == "CNES"][1]
  im <- icc_mor(s2)
  ci_sd <- varcov_ci(fit, grp = "CNES")

  say(sprintf("\nVariancia hospitalar (s2_hosp) = %.5f", s2))
  say(sprintf("Desvio-padrao hospitalar (s_hosp)  = %.5f", sqrt(s2)))
  say(sprintf("VPC / ICC (latente, pi^2/3) = %.5f  (%.2f%%)", im$icc, 100 * im$icc))
  say(sprintf("MOR (median odds ratio) = %.4f", im$mor))
  say(sprintf("Proporcao da variancia da mortalidade atribuivel ao hospital = %.1f%%",
              100 * im$icc))
  if (!is.null(ci_sd)) {
    lo <- ci_sd[1]; hi <- ci_sd[2]
    say(sprintf("DP hospitalar IC95%% (Wald): %.5f a %.5f", lo, hi))
    say(sprintf("VPC/ICC IC95%%: %.5f a %.5f",
                lo^2 / (lo^2 + pi^2 / 3), hi^2 / (hi^2 + pi^2 / 3)))
    say(sprintf("MOR IC95%%: %.4f a %.4f",
                exp(sqrt(2 * lo^2) * qnorm(0.75)), exp(sqrt(2 * hi^2) * qnorm(0.75))))
  } else say("IC do componente de variancia indisponivel")
  say("ICC performance::icc: ",
      tryCatch(paste(round(performance::icc(fit$modelo)$ICC_adjusted, 5), collapse = " "),
               error = function(e) "erro"))

  ## ================= 4. tabela de OR com correção de FDR =================
  ## Correção de Benjamini-Hochberg (taxa de falsas descobertas).
  ## O intercepto fica fora da familia de testes. A familia global reune
  ## todos os coeficientes; as familias por bloco separam as covariáveis de
  ## paciente das regiões de saúde, porque as perguntas são distintas.
  tab <- copy(fit$coef)
  tab[, bloco := fifelse(grepl("^regiao_saude", termo), "Regiao de saude",
                  fifelse(termo == "(Intercept)", "Intercepto", "Paciente"))]
  tab[, q_bh := NA_real_]
  testes <- tab$bloco != "Intercepto"
  tab[testes, q_bh := p.adjust(p, method = "BH")]
  tab[, q_bh_bloco := NA_real_]
  for (b in c("Paciente", "Regiao de saude")) {
    idx <- tab$bloco == b
    if (any(idx)) tab[idx, q_bh_bloco := p.adjust(p, method = "BH")]
  }
  tab[, p_cient := p_cient(p)]
  tab[, q_cient := fifelse(is.na(q_bh), "NA", p_cient(q_bh))]
  tab[, signific := fifelse(is.na(q_bh), "ns",
                     fifelse(q_bh < 0.001, "***", fifelse(q_bh < 0.01, "**",
                      fifelse(q_bh < 0.05, "*", "ns"))))]

  say("\n--- OR AJUSTADO (IC95%), p e FDR ---")
  say("  significancia marcada pela q-valor de Benjamini-Hochberg, nao pelo p bruto")
  for (i in seq_len(nrow(tab)))
    say(sprintf("  %-42s OR=%7.3f (IC95%% %6.3f-%7.3f)  p=%s  q=%s %s",
                tab$termo[i], tab$or[i], tab$lo[i], tab$hi[i],
                tab$p_cient[i], tab$q_cient[i], tab$signific[i]))

  say("\n--- RESUMO DA CORRECAO DE FDR ---")
  say(sprintf("  familia global  : %d testes | p<0,05: %d | q<0,05: %d",
              sum(testes), sum(tab$p[testes] < 0.05),
              sum(tab$q_bh[testes] < 0.05, na.rm = TRUE)))
  for (b in c("Paciente", "Regiao de saude")) {
    idx <- tab$bloco == b
    if (any(idx))
      say(sprintf("  familia %-16s: %d testes | p<0,05: %d | q<0,05: %d",
                  b, sum(idx), sum(tab$p[idx] < 0.05),
                  sum(tab$q_bh_bloco[idx] < 0.05, na.rm = TRUE)))
  }
  perdem <- tab[testes & p < 0.05 & (is.na(q_bh) | q_bh >= 0.05)]
  say("  coeficientes que perdem significancia apos FDR: ",
      if (nrow(perdem) == 0) "nenhum" else "")
  if (nrow(perdem)) for (i in seq_len(nrow(perdem)))
    say(sprintf("    %-42s p=%s  q=%s", perdem$termo[i],
                perdem$p_cient[i], perdem$q_cient[i]))
  fwrite(tab, file.path(TAB, "tab3_glmm_or.csv"), encoding = "UTF-8")

  ## ================= 5. componentes consolidados =================
  comp <- data.table(
    metrica = c("Motor", "N (internacoes)", "Obitos", "Taxa de obito (%)",
                "Hospitais (CNES)", "Regioes de saude",
                "Variancia hospitalar (s2_hosp)", "DP hospitalar (s_hosp)",
                "VPC / ICC", "VPC / ICC (%)", "MOR",
                "Log-verossimilhanca", "AIC", "Tempo de ajuste (min)"),
    valor = c(ENGINE, nrow(d), sum(d$obito_hospitalar),
              round(100 * mean(d$obito_hospitalar), 3), uniqueN(d$CNES),
              uniqueN(d$regiao_saude), round(s2, 5), round(sqrt(s2), 5),
              round(im$icc, 5), round(100 * im$icc, 3), round(im$mor, 4),
              round(fit$logLik, 2), round(fit$AIC, 2), round(fit$tempo_min, 2)))
  if (!is.null(ci_sd)) {
    lo <- ci_sd[1]; hi <- ci_sd[2]
    comp <- rbind(comp, data.table(
      metrica = c("DP hospitalar IC95% inf", "DP hospitalar IC95% sup",
                  "VPC/ICC IC95% inf", "VPC/ICC IC95% sup",
                  "MOR IC95% inf", "MOR IC95% sup"),
      valor = c(round(lo, 5), round(hi, 5),
                round(lo^2 / (lo^2 + pi^2 / 3), 5), round(hi^2 / (hi^2 + pi^2 / 3), 5),
                round(exp(sqrt(2 * lo^2) * qnorm(0.75)), 4),
                round(exp(sqrt(2 * hi^2) * qnorm(0.75)), 4))))
  }
  fwrite(comp, file.path(TAB, "tab4_glmm_componentes.csv"), encoding = "UTF-8")

  ## ================= 6. discriminação e calibração =================
  d[, p_cond := fit$fitted]
  d[, lp_marg := fit$lp_marg]
  d[, p_marg := plogis(lp_marg)]

  auc_cond <- as.numeric(pROC::auc(pROC::roc(d$obito_hospitalar, d$p_cond, quiet = TRUE)))
  auc_marg <- as.numeric(pROC::auc(pROC::roc(d$obito_hospitalar, d$p_marg, quiet = TRUE)))
  say("\n--- DISCRIMINACAO ---")
  say(sprintf("  AUC condicional (com efeito aleatorio de hospital): %.4f", auc_cond))
  say(sprintf("  AUC marginal (apenas efeitos fixos):                %.4f", auc_marg))

  H <- hosmer_lemeshow(d$obito_hospitalar, d$p_marg)
  say("\n--- CALIBRACAO (decis de risco) ---")
  say("  Previsao MARGINAL (apenas efeitos fixos): por desigualdade de Jensen a")
  say("  probabilidade media prevista fica abaixo da media observada, e a")
  say("  calibracao deve ser lida com essa ressalva.")
  say("  grupo       n     obs    esperado    obs%    esp%")
  for (i in seq_len(nrow(H$tab)))
    say(sprintf("  %5d %7d %7d %11.1f %7.2f %7.2f", H$tab$g[i], H$tab$n[i], H$tab$obs[i],
                H$tab$esp[i], 100 * H$tab$obs[i] / H$tab$n[i],
                100 * H$tab$esp[i] / H$tab$n[i]))
  say(sprintf("  Hosmer-Lemeshow: X2=%.2f  gl=%d  p=%s", H$stat, H$gl, p_cient(H$p)))
  say("  Nota: com n desta ordem o teste de Hosmer-Lemeshow tem poder excessivo e")
  say("  rejeita quase qualquer modelo. A calibracao deve ser lida pela tabela acima,")
  say("  pela inclinacao e pelo intercepto de calibracao.")
  H$tab[, `:=`(obs_pct = round(100 * obs / n, 2), esp_pct = round(100 * esp / n, 2),
               tipo = "marginal")]
  fwrite(H$tab, file.path(TAB, "tab5_calibracao.csv"), encoding = "UTF-8")

  lp <- qlogis(pmin(pmax(d$p_marg, 1e-9), 1 - 1e-9))
  cs <- glm(d$obito_hospitalar ~ lp, family = binomial)
  say(sprintf("  MARGINAL   intercepto (in-the-large) = %.4f (EP %.4f) | inclinacao = %.4f (EP %.4f)",
              coef(cs)[1], summary(cs)$coefficients[1, 2],
              coef(cs)[2], summary(cs)$coefficients[2, 2]))

  Hc <- hosmer_lemeshow(d$obito_hospitalar, d$p_cond)
  lp2 <- qlogis(pmin(pmax(d$p_cond, 1e-9), 1 - 1e-9))
  cs2 <- glm(d$obito_hospitalar ~ lp2, family = binomial)
  say(sprintf("  CONDICIONAL intercepto (in-the-large) = %.4f (EP %.4f) | inclinacao = %.4f (EP %.4f)",
              coef(cs2)[1], summary(cs2)$coefficients[1, 2],
              coef(cs2)[2], summary(cs2)$coefficients[2, 2]))
  say("  A previsao condicional e a que reproduz os riscos estimados por hospital.")
  Hc$tab[, `:=`(obs_pct = round(100 * obs / n, 2), esp_pct = round(100 * esp / n, 2),
                tipo = "condicional")]
  fwrite(rbind(H$tab, Hc$tab), file.path(TAB, "tab5_calibracao.csv"), encoding = "UTF-8")
  say("\n--- R2 ---")
  say("  marginal: ", tryCatch(round(performance::r2(fit$modelo)$R2_marginal, 4),
                                error = function(e) "erro"))
  say("  condicional: ", tryCatch(round(performance::r2(fit$modelo)$R2_conditional, 4),
                                   error = function(e) "erro"))

  ## ================= 7. efeitos por hospital =================
  re <- fit$ranef[grp == "CNES", .(CNES = nivel, u_j = u)]
  re[, CNES := factor(CNES, levels = levels(d$CNES))]
  eh <- merge(re, d[, .(n = .N, obitos = sum(obito_hospitalar),
                        mortalidade_obs = 100 * mean(obito_hospitalar),
                        esperado = sum(p_marg)), by = CNES],
              by = "CNES", all.x = TRUE)
  eh[, mortalidade_esp := 100 * esperado / n]
  eh[, razao_oe := (obitos / n) / (esperado / n)]
  setorder(eh, -u_j)

  say("\n--- HOSPITAIS: 10 MAIORES E 10 MENORES EFEITOS ALEATORIOS ---")
  top <- rbind(head(eh, 10), tail(eh, 10))
  for (i in seq_len(nrow(top)))
    say(sprintf("  CNES %-10s n=%6d obitos=%5d obs=%5.1f%% esp=%5.1f%% O/E=%.2f u_j=%+.3f",
                as.character(top$CNES[i]), top$n[i], top$obitos[i],
                top$mortalidade_obs[i], top$mortalidade_esp[i],
                top$razao_oe[i], top$u_j[i]))
  fwrite(eh, file.path(PROC, "efeitos_hospital_glmm.csv"), encoding = "UTF-8")

  fwrite(d[, .(CNES, regiao_saude, subtipo, ano, obito_hospitalar, p_marg, p_cond, lp_marg)],
         file.path(PROC, "previsoes_glmm.csv"), encoding = "UTF-8")

  ## ================= 8. serializacao =================
  fmod <- file.path(PROC, paste0("modelo_glmm_principal_", ENGINE, ".rds"))
  ok <- tryCatch({ saveRDS(fit$modelo, fmod); TRUE },
                 error = function(e) { say("\nsaveRDS FALHOU: ", conditionMessage(e)); FALSE })
  if (ok) {
    say("\nmodelo gravado: ", fmod)
    say("teste de releitura: ", tryCatch({ readRDS(fmod); "ok" },
                                         error = function(e) paste("ERRO:", conditionMessage(e))))
  }

  say("\nfim: ", format(Sys.time()))
  close(logcon)
})
