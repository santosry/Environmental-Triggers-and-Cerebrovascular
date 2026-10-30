# 28_tamanhos_efeito.R
# Tamanhos de efeito para os testes que, com n muito grande, podem ser
# estatisticamente significativos sem relevância prática.
#
# 1. Qui-quadrado: V de Cramér com IC95% bootstrap (2.000 reamostragens
#    multinomiais sobre a tabela, preservando os marginais observados).
# 2. Mann-Kendall: inclinação de Sen com IC95%, além de tau e p. A série tem
#    apenas 11 pontos anuais (2014-2024); o IC da inclinação explicita a
#    incerteza que o p isolado não mostra.
#
# Saídas:
#   05_tabelas/tab30_tamanhos_efeito_qui2.csv
#   05_tabelas/tab30b_tendencias_sen.csv
#   04_resultados/resultados_tamanhos_efeito.txt

suppressWarnings({
  options(stringsAsFactors = FALSE)
  library(data.table)
  library(trend)

  ROOT <- normalizePath(".")
  PROC <- file.path(ROOT, "01_dados", "processados")
  TAB <- file.path(ROOT, "05_tabelas")
  RES <- file.path(ROOT, "04_resultados")
  DLNM <- file.path(dirname(ROOT), "01_DLNMs_RJ_cerebrovascular", "data_processed")
  if (!dir.exists(DLNM)) DLNM <- file.path(dirname(ROOT), "01_DLNM_RJ_cerebrovascular", "data_processed")

  p_cient <- function(p) ifelse(is.na(p), "NA",
    ifelse(p < 1e-3, formatC(p, format = "e", digits = 2),
           formatC(p, format = "f", digits = 4)))

  logcon <- file(file.path(RES, "resultados_tamanhos_efeito.txt"), open = "wt", encoding = "UTF-8")
  say <- function(...) {
    m <- paste0(...); cat(m, "\n"); writeLines(m, logcon); flush(logcon)
  }

  say("=====================================================================")
  say("TAMANHOS DE EFEITO E INCLINACAO DE SEN")
  say("inicio: ", format(Sys.time()))
  say("=====================================================================")

  ## ---------------- 1. qui-quadrado: V de Cramer ----------------
  d <- fread(file.path(PROC, "coorte_glmm_2014_2024.csv"),
             select = c("obito_hospitalar", "sexo", "idade_anos", "raca_cor",
                        "n_diag_sec", "nat_jur_lab", "complex_lab", "car_int",
                        "cid3", "subtipo", "regiao_saude", "ano"),
             na.strings = c("", "NA"), encoding = "UTF-8")
  d[, faixa_etaria := cut(idade_anos, c(-1, 40, 50, 60, 70, 80, 200),
                          labels = c("<40", "40-49", "50-59", "60-69", "70-79", "80+"))]
  d[, faixa_sexo := interaction(faixa_etaria, sexo, drop = TRUE)]
  d[, macro3 := fifelse(regiao_saude %in% c("Metropolitana I", "Metropolitana II"),
                        "Metropolitana",
                 fifelse(regiao_saude %in% c("Serrana", "Medio Paraiba",
                                             "Centro-Sul", "Baia da Ilha Grande"),
                         "Centro-Sul", "Norte e Noroeste"))]

  ## V de Cramer usa o chi2 de Pearson sem correcao de Yates. O p-reportado
  ## usa a correcao padrao do R para tabelas 2x2 (Yates), que e a mesma
  ## convencao dos scripts 13, 17 e 19.
  cramer_v <- function(tab) {
    chi <- suppressWarnings(chisq.test(tab, correct = FALSE)$statistic)
    n <- sum(tab)
    as.numeric(sqrt(chi / (n * (min(nrow(tab) - 1, ncol(tab) - 1)))))
  }
  cramer_ci <- function(tab, B = 2000, seed = 20261029) {
    set.seed(seed)
    n <- sum(tab); p <- as.vector(tab) / n
    vals <- replicate(B, {
      sim <- rmultinom(1, n, p)
      dim(sim) <- dim(tab)
      if (any(rowSums(sim) == 0) || any(colSums(sim) == 0)) return(NA_real_)
      cramer_v(sim)
    })
    stats::quantile(vals, c(0.025, 0.975), na.rm = TRUE)
  }

  vars <- c("regiao_saude", "macro3", "sexo", "faixa_etaria", "faixa_sexo",
            "car_int", "cid3", "subtipo", "raca_cor", "n_diag_sec",
            "nat_jur_lab", "complex_lab")
  out <- list()
  for (v in vars) {
    dd <- d[!is.na(get(v)) & !is.na(obito_hospitalar)]
    tab <- table(dd[[v]], dd$obito_hospitalar)
    tab <- tab[rowSums(tab) > 0, colSums(tab) > 0, drop = FALSE]
    if (nrow(tab) < 2 || ncol(tab) < 2) next
    ct <- suppressWarnings(chisq.test(tab))
    ci <- cramer_ci(tab)
    out[[v]] <- data.table(
      variavel = v, n = sum(tab), chi2 = as.numeric(ct$statistic),
      gl = as.numeric(ct$parameter), p = ct$p.value,
      cramer_v = cramer_v(tab), v_lo = as.numeric(ci[1]), v_hi = as.numeric(ci[2]),
      niveis = nrow(tab))
    say(sprintf("%-16s n=%7d chi2=%9.1f gl=%2d p=%s | V=%.3f (IC95%% %.3f-%.3f)",
                v, sum(tab), as.numeric(ct$statistic), as.numeric(ct$parameter),
                p_cient(ct$p.value), cramer_v(tab), ci[1], ci[2]))
  }
  efeitos <- rbindlist(out)
  fwrite(efeitos, file.path(TAB, "tab30_tamanhos_efeito_qui2.csv"), encoding = "UTF-8")

  ## ---------------- 2. Mann-Kendall + Sen ----------------
  pop <- fread(file.path(DLNM, "populacao_sidra_municipio_rj_2010-2025.csv"),
               select = c("macro_regiao", "ano", "populacao"))
  pop[, ano := as.integer(ano)]
  pop_reg <- pop[ano %in% 2014:2024, .(populacao = sum(populacao)), by = .(regiao_saude = macro_regiao, ano)]
  pop_est <- pop[ano %in% 2014:2024, .(populacao = sum(populacao)), by = .(ano)]

  d[, ano := as.integer(ano)]
  sih_reg <- d[, .(n = .N), by = .(regiao_saude, ano)]
  sih_est <- d[, .(n = .N), by = .(ano)]
  sih_reg <- merge(sih_reg, pop_reg, by = c("regiao_saude", "ano"), all.x = TRUE)
  sih_est <- merge(sih_est, pop_est, by = "ano", all.x = TRUE)
  sih_reg[, taxa := 100000 * n / populacao]
  sih_est[, taxa := 100000 * n / populacao]

  sim <- fread(file.path(PROC, "sim_cid_estudo_2014_2024.csv"),
               select = c("DTOBITO", "CODMUNRES"), encoding = "UTF-8")
  look <- fread(file.path(DLNM, "lookup_municipio_macrorregiao.csv"),
                select = c("ibge6", "macro_regiao"))
  look[, ibge6 := as.integer(ibge6)]
  sim[, `:=`(ano = as.integer(substr(sprintf("%08d", as.integer(DTOBITO)), 5, 8)),
             ibge6 = as.integer(sprintf("%06d", as.integer(CODMUNRES))))]
  sim <- merge(sim, look, by = "ibge6", all.x = TRUE)
  sim_reg <- sim[, .(n = .N), by = .(regiao_saude = macro_regiao, ano)]
  sim_est <- sim[, .(n = .N), by = .(ano)]
  sim_reg <- merge(sim_reg, pop_reg, by = c("regiao_saude", "ano"), all.x = TRUE)
  sim_est <- merge(sim_est, pop_est, by = "ano", all.x = TRUE)
  sim_reg[, taxa := 100000 * n / populacao]
  sim_est[, taxa := 100000 * n / populacao]

  mk_sen <- function(x) {
    x <- as.numeric(x[!is.na(x)])
    if (length(x) < 4 || length(unique(x)) < 2)
      return(list(tau = NA_real_, p = NA_real_, sen = NA_real_, lo = NA_real_, hi = NA_real_))
    m <- suppressWarnings(trend::mk.test(x))
    s <- suppressWarnings(trend::sens.slope(x))
    list(tau = as.numeric(m$estimates[["tau"]]), p = as.numeric(m$p.value),
         sen = as.numeric(s$estimates[1]),
         lo = as.numeric(s$conf.int[1]), hi = as.numeric(s$conf.int[2]))
  }

  tend <- list()
  add_tend <- function(dt, desfecho, unidade, grupo) {
    dt <- dt[order(ano)]
    r <- mk_sen(dt$taxa)
    tend[[length(tend) + 1]] <<- data.table(
      desfecho = desfecho, unidade = unidade, grupo = grupo,
      anos = nrow(dt), tau = r$tau, p = r$p,
      sen_slope = r$sen, sen_lo = r$lo, sen_hi = r$hi,
      taxa_2014 = dt$taxa[dt$ano == 2014][1], taxa_2024 = dt$taxa[dt$ano == 2024][1])
  }
  add_tend(sih_est, "Internacao", "estado", "RJ")
  for (g in sort(unique(sih_reg$regiao_saude)))
    add_tend(sih_reg[regiao_saude == g], "Internacao", "regiao_saude", g)
  add_tend(sim_est, "Mortalidade", "estado", "RJ")
  for (g in sort(unique(sim_reg$regiao_saude)))
    add_tend(sim_reg[regiao_saude == g], "Mortalidade", "regiao_saude", g)

  ## letalidade hospitalar anual: Mann-Kendall + Cochran-Armitage
  let <- d[, .(obitos = sum(obito_hospitalar), n = .N), by = ano][order(ano)]
  let[, taxa := 100 * obitos / n]
  r <- mk_sen(let$taxa)
  N <- sum(let$n); pbar <- sum(let$obitos) / N
  score <- let$ano - min(let$ano)
  num <- sum((let$obitos - let$n * pbar) * (score - weighted.mean(score, let$n)))
  den <- sqrt(pbar * (1 - pbar) * sum(let$n * (score - weighted.mean(score, let$n))^2))
  p_ca <- 2 * pnorm(-abs(num / den))
  tend[[length(tend) + 1]] <- data.table(
    desfecho = "Letalidade hospitalar", unidade = "estado", grupo = "RJ",
    anos = nrow(let), tau = r$tau, p = r$p, sen_slope = r$sen,
    sen_lo = r$lo, sen_hi = r$hi,
    taxa_2014 = let$taxa[1], taxa_2024 = let$taxa[.N])
  say(sprintf("Letalidade hospitalar: Cochran-Armitage p=%s | Sen=%.4f p.p./ano (IC95%% %.4f a %.4f)",
              p_cient(p_ca), r$sen, r$lo, r$hi))

  tend <- rbindlist(tend)
  fwrite(tend, file.path(TAB, "tab30b_tendencias_sen.csv"), encoding = "UTF-8")
  say("\nTendencias: tau, p e inclinacao de Sen (unidade: taxa por 100.000/ano;")
  say("letalidade em pontos percentuais/ano).")
  for (i in seq_len(nrow(tend)))
    say(sprintf("%-13s %-16s %-22s tau=%+.3f p=%s | Sen=%+.3f (IC95%% %+.3f a %+.3f)",
                tend$desfecho[i], tend$unidade[i], tend$grupo[i], tend$tau[i],
                p_cient(tend$p[i]), tend$sen_slope[i], tend$sen_lo[i], tend$sen_hi[i]))

  say("\nfim: ", format(Sys.time()))
  close(logcon)
})
