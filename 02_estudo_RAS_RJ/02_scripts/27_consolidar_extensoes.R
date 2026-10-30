# 27_consolidar_extensoes.R
# Reúne as extensões do GLMM ajustadas por 27_glmm_extensoes.R.
# Uso: após rodar os quatro modelos (ano, volume, volume_ano,
# interacao_regiao_ano), execute este script uma vez.

suppressWarnings({
  options(stringsAsFactors = FALSE)
  library(data.table)

  ROOT <- normalizePath(".")
  TAB <- file.path(ROOT, "05_tabelas")
  RES <- file.path(ROOT, "04_resultados")

  arquivos <- list.files(TAB, pattern = "^tab29_glmm_extensoes_.*\\.csv$",
                         full.names = TRUE)
  if (!length(arquivos)) stop("Nenhum tab29_glmm_extensoes_*.csv encontrado.")
  res <- rbindlist(lapply(arquivos, fread), fill = TRUE)
  ## Recupera convergência do RDS, inclusive para execuções antigas do tab29.
  res[, convergencia := NA_integer_]
  res[, pdHess := NA]
  for (i in seq_len(nrow(res))) {
    f <- file.path(ROOT, "01_dados", "processados",
                   paste0("modelo_glmm_extensao_", res$modelo[i], ".rds"))
    if (file.exists(f)) {
      m <- readRDS(f)
      res$convergencia[i] <- m$fit$convergence
      res$pdHess[i] <- isTRUE(m$sdr$pdHess)
    }
  }

  comp <- fread(file.path(TAB, "tab4_glmm_componentes.csv"))
  base_icc <- as.numeric(comp[metrica == "VPC / ICC"]$valor)
  res[, delta_ICC_pp := round(100 * (ICC - base_icc), 3)]
  setorder(res, convergencia, AIC, na.last = TRUE)

  fwrite(res, file.path(TAB, "tab29_glmm_extensoes.csv"), encoding = "UTF-8")

  logcon <- file(file.path(RES, "resultados_glmm_extensoes.txt"),
                 open = "wt", encoding = "UTF-8")
  say <- function(...) {
    m <- paste0(...); cat(m, "\n"); writeLines(m, logcon); flush(logcon)
  }
  say("=====================================================================")
  say("EXTENSOES DO GLMM PRINCIPAL - CONSOLIDADO")
  say("base: ICC = ", sprintf("%.3f%%", 100 * base_icc),
      " | AIC = ", comp[metrica == "AIC"]$valor)
  say("=====================================================================")
  for (i in seq_len(nrow(res)))
    say(sprintf("%-24s conv=%s n=%7s sigma2=%8.5f ICC=%7.3f%% delta=%+7.3f p.p. AIC=%10.2f LRT=%8.2f gl=%2d p=%s%s",
                res$modelo[i], res$convergencia[i], format(res$n[i], big.mark = "."),
                res$sigma2[i], 100 * res$ICC[i], res$delta_ICC_pp[i], res$AIC[i],
                res$LR_vs_base[i], res$gl_LR[i],
                ifelse(is.na(res$p_LR[i]), "NA",
                       formatC(res$p_LR[i], format = "e", digits = 2)),
                ifelse(!is.na(res$convergencia[i]) && res$convergencia[i] != 0,
                       "  <== NAO CONVERGIU", "")))

  coefs <- rbindlist(lapply(list.files(TAB, pattern = "^tab29b_glmm_coefs_.*\\.csv$",
                                       full.names = TRUE), fread), fill = TRUE)
  if (nrow(coefs)) {
    fwrite(coefs, file.path(TAB, "tab29b_glmm_coefs.csv"), encoding = "UTF-8")
    say("\n--- COEFICIENTES ADICIONADOS ---")
    for (i in seq_len(nrow(coefs)))
      say(sprintf("%-24s %-40s OR=%8.4f (IC95%% %8.4f-%8.4f) p=%s",
                  coefs$modelo[i], coefs$termo[i], coefs$or[i], coefs$lo[i],
                  coefs$hi[i], formatC(coefs$p[i], format = "e", digits = 2)))
  }
  say("\nfim: ", format(Sys.time()))
  close(logcon)
})
