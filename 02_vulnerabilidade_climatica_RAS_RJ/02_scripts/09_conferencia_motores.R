# 09_conferencia_motores.R
# Conferência entre motores e adequação da aproximação de Laplace, em UM
# único comando.
#
# POR QUE ESTE SCRIPT E AUTOORQUESTRADO. Carregar o glmmTMB e o lme4 na
# mesma sessão R encerra o processo sem mensagem de erro, mesmo com 20 mil
# registros e memória disponível (verificado em três tentativas). A solução
# adotada e este script se invocar a si mesmo com o argumento --worker, de
# modo que o lme4 roda em um processo R limpo, sem o glmmTMB carregado.
#
# O QUE E VERIFICADO.
#   [A] glmmTMB contra lme4 na MESMA subamostra, com a mesma semente. Se os
#       dois motores concordam, o resultado não e artefato de implementação.
#   [B] dentro do lme4, aproximação de Laplace (nAGQ = 1) contra quadratura
#       adaptativa de Gauss-Hermite (nAGQ = 11). Se os OR coincidem, a
#       aproximação de Laplace e suficiente, que e a premissa do modelo
#       principal.
#
# A subamostra e gravada em arquivo temporario para que os dois processos
# usem exatamente as mesmas linhas.
#
# Saídas:
#   04_resultados/resultados_conferencia_motores.txt
#   05_tabelas/tab11_conferencia_motores.csv
#   05_tabelas/tab16_conferencia_aghq.csv

suppressWarnings({
  options(stringsAsFactors = FALSE)

  ROOT <- normalizePath(".")
  PROC <- file.path(ROOT, "01_dados", "processados")
  RES <- file.path(ROOT, "04_resultados")
  TAB <- file.path(ROOT, "05_tabelas")
  UTILS <- file.path(ROOT, "02_scripts", "00_glmm_utils.R")

  FML <- obito_hospitalar ~ idade_z + sexo + subtipo + car_int + uti + fluxo_inter +
    regiao_saude + (1 | CNES)
  N_SUB <- as.integer(Sys.getenv("GLMM_N", "20000"))
  SEMENTE <- 20261001L

  args <- commandArgs(trailingOnly = TRUE)

  ## MODO TRABALHADOR: roda o lme4 em processo limpo
  if (length(args) >= 1 && args[1] == "--worker") {
    library(data.table)
    library(lme4)
    sub <- readRDS(args[2])
    s2_ref <- as.numeric(args[3]); ll_ref <- as.numeric(args[4])
    say <- function(...) cat(paste0(...), "\n")
    q75 <- qnorm(0.75)

    say(sprintf("[A] lme4 Laplace (nAGQ = 1) | %s registros | %d hospitais | %d obitos",
                format(nrow(sub), big.mark = "."), nlevels(sub$CNES),
                sum(sub$obito_hospitalar)))
    t0 <- Sys.time()
    m <- glmer(FML, data = sub, family = binomial,
               control = glmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 1e4)))
    vc <- as.data.frame(VarCorr(m)); s2 <- vc$vcov[1]
    icc <- s2 / (s2 + pi^2 / 3); mor <- exp(sqrt(2 * s2) * q75)
    ll <- as.numeric(logLik(m))
    say(sprintf("    tempo=%.2f min | logLik=%.4f | AIC=%.2f | s2=%.5f | ICC=%.5f | MOR=%.4f",
                as.numeric(difftime(Sys.time(), t0, units = "mins")), ll, AIC(m),
                s2, icc, mor))
    say(sprintf("    glmmTMB na mesma subamostra: s2=%.5f | diferenca relativa=%.3f%%",
                s2_ref, 100 * abs(s2 - s2_ref) / s2_ref))
    say(sprintf("    log-verossimilhanca glmmTMB=%.4f | diferenca absoluta=%.4f",
                ll_ref, abs(ll - ll_ref)))
    cf <- summary(m)$coefficients
    fwrite(data.table(termo = rownames(cf), or = exp(cf[, 1]),
                      lo = exp(cf[, 1] - 1.96 * cf[, 2]),
                      hi = exp(cf[, 1] + 1.96 * cf[, 2]), p = cf[, 4]),
           file.path(TAB, "tab11_conferencia_motores.csv"), encoding = "UTF-8")

    say("\n[B] adequacao da aproximacao de Laplace: nAGQ = 11")
    t1 <- Sys.time()
    m11 <- tryCatch(glmer(FML, data = sub, family = binomial, nAGQ = 11,
                          control = glmerControl(optimizer = "bobyqa",
                                                 optCtrl = list(maxfun = 1e4))),
                   error = function(e) { say("    ERRO: ", conditionMessage(e)); NULL })
    if (!is.null(m11)) {
      vc11 <- as.data.frame(VarCorr(m11)); s2_11 <- vc11$vcov[1]
      cf11 <- summary(m11)$coefficients
      say(sprintf("    tempo=%.2f min | logLik=%.4f | AIC=%.2f",
                  as.numeric(difftime(Sys.time(), t1, units = "mins")),
                  as.numeric(logLik(m11)), AIC(m11)))
      say(sprintf("    s2=%.5f (Laplace %.5f, diferenca relativa %.3f%%)",
                  s2_11, s2, 100 * abs(s2_11 - s2) / s2))
      say(sprintf("    ICC=%.5f (Laplace %.5f) | MOR=%.4f (Laplace %.4f)",
                  s2_11 / (s2_11 + pi^2 / 3), icc, exp(sqrt(2 * s2_11) * q75), mor))
      cmp <- data.table(termo = rownames(cf), or_lap = exp(cf[, 1]),
                        or_aghq = exp(cf11[, 1]))
      cmp[, dif_rel_pct := round(100 * abs(or_lap - or_aghq) / or_lap, 4)]
      setorder(cmp, -dif_rel_pct)
      say(sprintf("    OR: diferenca relativa maxima %.4f%% | mediana %.4f%%",
                  max(cmp$dif_rel_pct), median(cmp$dif_rel_pct)))
      say("    maiores divergencias:")
      for (i in seq_len(min(5, nrow(cmp))))
        say(sprintf("      %-42s Laplace=%.4f AGHQ=%.4f dif=%.4f%%",
                    cmp$termo[i], cmp$or_lap[i], cmp$or_aghq[i], cmp$dif_rel_pct[i]))
      fwrite(cmp, file.path(TAB, "tab16_conferencia_aghq.csv"), encoding = "UTF-8")
    }
    quit(save = "no", status = 0)
  }

  ## MODO ORQUESTRADOR
  library(data.table)
  source(UTILS)

  logcon <- file(file.path(RES, "resultados_conferencia_motores.txt"), open = "wt",
                 encoding = "UTF-8")
  say <- function(...) { m <- paste0(...); cat(m, "\n"); writeLines(m, logcon); flush(logcon) }

  say("=====================================================================")
  say("CONFERENCIA ENTRE MOTORES E ADEQUACAO DA APROXIMACAO DE LAPLACE")
  say("R ", R.version.string, " | glmmTMB ", as.character(packageVersion("glmmTMB")),
      " | lme4 ", as.character(packageVersion("lme4")))
  say("inicio: ", format(Sys.time()))
  say("=====================================================================")
  say("O lme4 roda em processo R separado, porque carregar glmmTMB e lme4 na")
  say("mesma sessao encerra o processo sem mensagem de erro.")

  SUBTIPO_ORDEM <- c("Nao especificado (I64)", "Hemorragico (I60-I62)",
                     "Isquemico (I63)", "Oclusao e outras (I65-I68)",
                     "Sequelas (I69)", "AIT (G45)", "Sindromes vasculares (G46)",
                     "Outros")
  REGIAO_ORDEM <- c("Metropolitana I", "Metropolitana II", "Baixada Litoranea",
                    "Norte", "Noroeste", "Serrana", "Centro-Sul", "Medio Paraiba",
                    "Baia da Ilha Grande")
  CAR_ORDEM <- c("Eletiva", "Urgencia", "Acidente trabalho", "Acidente trajeto",
                 "Outros acidentes", "Outras lesoes", "Outros")
  COLS <- c("CNES", "obito_hospitalar", "idade_z", "sexo", "subtipo", "car_int",
            "uti", "fluxo_inter", "regiao_saude")

  prep <- function(x) {
    x[, CNES := factor(CNES)]
    x[, sexo := factor(sexo, levels = c("F", "M", "I"))]
    x[, subtipo := factor(subtipo, levels = SUBTIPO_ORDEM)]
    x[, regiao_saude := factor(regiao_saude, levels = REGIAO_ORDEM)]
    x[, car_int := factor(as.character(car_int), levels = CAR_ORDEM)]
    for (v in c("CNES", "sexo", "subtipo", "regiao_saude", "car_int"))
      x[, (v) := droplevels(get(v))]
    x
  }

  D <- prep(fread(file.path(PROC, "coorte_glmm_2010_2024.csv"), select = COLS,
                  encoding = "UTF-8"))
  set.seed(SEMENTE)
  sub <- as.data.frame(prep(copy(D)[sample(.N, min(N_SUB, .N))]))
  say("\nsubamostra: ", format(nrow(sub), big.mark = "."), " registros | ",
      nlevels(sub$CNES), " hospitais | ", sum(sub$obito_hospitalar),
      " obitos | semente ", SEMENTE)

  ## ---------------- [A] glmmTMB ----------------
  say("\n[A] glmmTMB")
  ft <- fit_glmm(FML, sub, engine = "glmmTMB")
  s2_t <- ft$vc$vcov[ft$vc$grp == "CNES"][1]
  say(sprintf("    tempo=%.2f min | logLik=%.4f | AIC=%.2f | s2=%.5f | ICC=%.5f | MOR=%.4f",
              ft$tempo_min, ft$logLik, ft$AIC, s2_t, icc_mor(s2_t)$icc,
              icc_mor(s2_t)$mor))

  ## ---------------- trabalhador em processo separado ----------------
  tmp <- tempfile(fileext = ".rds")
  saveRDS(sub, tmp)
  script <- sub("^--file=", "",
                grep("^--file=", commandArgs(FALSE), value = TRUE)[1])
  rscript <- file.path(R.home("bin"), "Rscript.exe")
  if (!file.exists(rscript)) rscript <- file.path(R.home("bin"), "Rscript")
  say("\ndisparando o lme4 em processo separado...")
  saida <- system2(rscript,
                   c(shQuote(script), "--worker", shQuote(tmp),
                     format(s2_t, digits = 10), format(ft$logLik, digits = 10)),
                   stdout = TRUE, stderr = TRUE)
  for (l in saida) { cat(l, "\n"); writeLines(l, logcon) }
  flush(logcon)
  unlink(tmp)

  say("\nfim: ", format(Sys.time()))
  close(logcon)
})
