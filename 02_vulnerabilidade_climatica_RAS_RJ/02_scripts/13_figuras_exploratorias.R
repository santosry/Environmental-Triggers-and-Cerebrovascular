# 13_figuras_exploratorias.R
# Banco de figuras exploratorias da análise atual (morbimortalidade
# cerebrovascular e RAS no RJ, 2010-2024). Produz 25 figuras em
# 06_figuras/exploratorias/ e as figuras finais do manuscrito em
# 06_figuras/manuscrito/ (JPEG, 300 dpi, requisito do edital).
#
# Todas as figuras usam rótulos acentuados (UTF-8) e, quando ha teste
# estatístico, trazem o p-valor ou o q-valor (FDR) no rótulo ou na legenda.
# Dispositivo ragg (PNG/JPEG) para garantir a acentuacao no Windows.
#
# Fontes (todas da análise atual):
#   coorte_glmm_2010_2024.csv, sih/sim_cid_estudo_2010_2024.csv,
#   população SIDRA, lookup município->região,
#   tabelas 03/04/05/06/08/10/11/12/18/22/23/25 e resultados de custos.

suppressWarnings({
  options(stringsAsFactors = FALSE)
  library(data.table)
  library(ggplot2)
  library(viridisLite)
  library(scales)
  library(pROC)
  library(trend)
  library(ragg)

  ROOT <- normalizePath(".")
  PROC <- file.path(ROOT, "01_dados", "processados")
  TAB <- file.path(ROOT, "05_tabelas")
  FIG <- file.path(ROOT, "06_figuras")
  FIG_EX <- file.path(FIG, "exploratorias")
  FIG_MAN <- file.path(FIG, "manuscrito")
  DLNM <- file.path(dirname(ROOT), "01_DLNMs_RJ_cerebrovascular", "data_processed")
  dir.create(FIG_EX, showWarnings = FALSE, recursive = TRUE)
  dir.create(FIG_MAN, showWarnings = FALSE, recursive = TRUE)

  logcon <- file(file.path(ROOT, "04_resultados", "resultados_figuras_exploratorias.txt"),
                 open = "wt", encoding = "UTF-8")
  say <- function(...) { m <- paste0(...); cat(m, "\n"); writeLines(m, logcon); flush(logcon) }

  say("=====================================================================")
  say("BANCO DE FIGURAS EXPLORATORIAS")
  say("R ", R.version.string, " | inicio: ", format(Sys.time()))
  say("=====================================================================")

  theme_set(theme_minimal(base_size = 11) +
              theme(plot.title = element_text(face = "bold"),
                    panel.grid.minor = element_blank()))

  salvar <- function(g, nome, w = 8, h = 5) {
    ok <- tryCatch({
      ggsave(file.path(FIG_EX, nome), g, width = w, height = h, dpi = 300,
             device = ragg::agg_png)
      TRUE
    }, error = function(e) { say("  ERRO ao gravar ", nome, ": ", conditionMessage(e)); FALSE })
    if (ok) say("  gravada ", nome)
    invisible(ok)
  }
  salvar_jpg <- function(g, nome, w = 8, h = 5) {
    ok <- tryCatch({
      ggsave(file.path(FIG_MAN, nome), g, width = w, height = h, dpi = 300,
             device = ragg::agg_jpeg, quality = 95)
      TRUE
    }, error = function(e) { say("  ERRO ao gravar ", nome, ": ", conditionMessage(e)); FALSE })
    if (ok) say("  gravada (manuscrito) ", nome)
    invisible(ok)
  }

  ## teste de Cochran-Armitage (tendência de proporção)
  cochran_armitage <- function(k, n, score) {
    N <- sum(n); if (N == 0) return(NA_real_)
    pbar <- sum(k) / N; xbar <- sum(n * score) / N
    num <- sum((k - n * pbar) * (score - xbar))
    den <- sqrt(pbar * (1 - pbar) * sum(n * (score - xbar)^2))
    z <- if (den > 0) num / den else 0
    2 * pnorm(-abs(z))
  }

  ## ---------------- dados ----------------
  COLS <- c("DT_INTER_d", "ano", "sexo", "idade_anos", "cid3", "subtipo", "car_int",
            "regiao_saude", "mun_nome", "mun_nome_mov", "MUNIC_RES6", "MUNIC_MOV6",
            "CNES", "obito_hospitalar", "uti", "DIAS_PERM", "VAL_TOT",
            "n_diag_sec", "diagsec_disp", "raca_cor", "instru", "coorte")
  co <- fread(file.path(PROC, "coorte_glmm_2010_2024.csv"), encoding = "UTF-8",
              na.strings = c("NA", ""), select = COLS)
  co[, ano := as.integer(ano)]
  co[, faixa := cut(idade_anos, breaks = c(-Inf, 15, 30, 45, 60, 75, 90, Inf),
                    labels = c("<15", "15-29", "30-44", "45-59", "60-74", "75-89", "90+"),
                    right = FALSE)]

  sim <- fread(file.path(PROC, "sim_cid_estudo_2010_2024.csv"), encoding = "UTF-8",
              colClasses = "character", na.strings = c("NA", ""))
  sim[, dto := as.Date(DTOBITO, format = "%d%m%Y")]
  sim[, ano := as.integer(format(dto, "%Y"))]

  pop <- fread(file.path(DLNM, "populacao_sidra_municipio_rj_2010-2025.csv"),
               encoding = "UTF-8")
  pop[, ano := as.integer(ano)][, populacao := as.numeric(populacao)]
  pop[, ibge6 := sprintf("%06s", as.character(ibge6))]
  pop_reg <- pop[ano %in% 2010:2024, .(pop = sum(populacao, na.rm = TRUE)),
                 by = .(regiao_saude = macro_regiao, ano)]

  lk <- fread(file.path(DLNM, "lookup_municipio_macrorregiao.csv"),
              colClasses = "character", encoding = "UTF-8")
  lk[, ibge6 := sprintf("%06s", ibge6)]
  sim <- merge(sim, lk[, .(ibge6, regiao = macro_regiao)], by.x = "CODMUNRES",
               by.y = "ibge6", all.x = TRUE, sort = FALSE)

  MACRO_MAP <- c("Metropolitana I" = "Metropolitana", "Metropolitana II" = "Metropolitana",
                 "Serrana" = "Centro-Sul", "Medio Paraiba" = "Centro-Sul",
                 "Centro-Sul" = "Centro-Sul", "Baia da Ilha Grande" = "Centro-Sul",
                 "Norte" = "Norte e Noroeste", "Noroeste" = "Norte e Noroeste",
                 "Baixada Litoranea" = "Norte e Noroeste")
  co[, macro3 := unname(MACRO_MAP[as.character(regiao_saude)])]
  pop[, macro3 := unname(MACRO_MAP[as.character(macro_regiao)])]
  pop_macro <- pop[ano %in% 2010:2024, .(pop = sum(populacao, na.rm = TRUE)),
                   by = .(macro3, ano)]
  pop_est <- pop[ano %in% 2010:2024, .(pop = sum(populacao, na.rm = TRUE)), by = ano]

  co_i <- co[coorte == "I60-I69"]

  ## taxas de internação
  n_reg <- co_i[, .(n = .N), by = .(regiao_saude, ano)]
  tx_reg <- merge(n_reg, pop_reg, by = c("regiao_saude", "ano"))
  tx_reg[, taxa := n / pop * 1e5]
  n_est <- co_i[, .(n = .N), by = ano]
  tx_est <- merge(n_est, pop_est, by = "ano"); tx_est[, taxa := n / pop * 1e5]
  n_macro <- co_i[, .(n = .N), by = .(macro3, ano)]
  tx_macro <- merge(n_macro, pop_macro, by = c("macro3", "ano")); tx_macro[, taxa := n / pop * 1e5]

  ## taxas de mortalidade SIM
  n_sim_reg <- sim[!is.na(regiao) & !is.na(dto), .(n = .N), by = .(regiao_saude = regiao, ano)]
  tx_sim_reg <- merge(n_sim_reg, pop_reg, by = c("regiao_saude", "ano"), all.x = TRUE)
  tx_sim_reg[, taxa := n / pop * 1e5]

  ROT <- function(x) factor(x, levels = c("Metropolitana I", "Metropolitana II",
      "Baixada Litoranea", "Norte", "Noroeste", "Serrana", "Centro-Sul",
      "Medio Paraiba", "Baia da Ilha Grande"))
  CORES9 <- viridis(9, option = "D")

  ## ================= 1. série estadual de internação =================
  mkt <- trend::mk.test(tx_est[order(ano)]$taxa)
  g <- ggplot(tx_est, aes(ano, taxa)) +
    geom_line(colour = viridis(1, begin = 0.25), linewidth = 0.9) +
    geom_point(colour = viridis(1, begin = 0.25), size = 2) +
    geom_smooth(method = "lm", se = TRUE, colour = viridis(1, begin = 0.8),
                fill = viridis(1, begin = 0.8), alpha = 0.15, linewidth = 0.6) +
    labs(title = "Internações por DCV no Rio de Janeiro, 2010–2024",
         subtitle = sprintf("Taxa por 100.000 habitantes (I60–I69). Tendência de Mann–Kendall: τ = %+.3f; p = %.4f",
                            mkt$estimate, mkt$p.value),
         x = NULL, y = "Internações por 100.000") +
    scale_x_continuous(breaks = seq(2010, 2024, 2))
  salvar(g, "fig_ex01_taxa_internacao_estado.png")

  ## ================= 2. internação x mortalidade estadual =================
  ob_ano <- co_i[, .(obitos = sum(obito_hospitalar), n = .N), by = ano][order(ano)][, pct := 100 * obitos / n]
  p_ca <- cochran_armitage(ob_ano$obitos, ob_ano$n, seq_len(nrow(ob_ano)))
  d2 <- merge(tx_est[, .(ano, taxa)], ob_ano[, .(ano, pct)], by = "ano")
  g <- ggplot(d2, aes(ano)) +
    geom_line(aes(y = taxa, colour = "Internações/100 mil"), linewidth = 0.9) +
    geom_point(aes(y = taxa, colour = "Internações/100 mil"), size = 2) +
    geom_line(aes(y = pct * 3, colour = "% óbito hospitalar"), linewidth = 0.9, linetype = 2) +
    geom_point(aes(y = pct * 3, colour = "% óbito hospitalar"), size = 2, shape = 17) +
    scale_y_continuous(name = "Internações por 100.000",
                       sec.axis = sec_axis(~ . / 3, name = "% óbito hospitalar")) +
    scale_colour_viridis_d(option = "D", end = 0.85) +
    labs(title = "Internação e letalidade hospitalar por DCV",
         subtitle = sprintf("RJ, 2010–2024. Tendência da letalidade (Cochran–Armitage): p = %.4f. Eixos em escalas distintas",
                            p_ca),
         x = NULL, colour = NULL) +
    theme(legend.position = "top") +
    scale_x_continuous(breaks = seq(2010, 2024, 2))
  salvar(g, "fig_ex02_internacao_letalidade.png")
  salvar_jpg(g, "figura1_taxa_internacao_letalidade.jpg")

  ## ================= 3. taxas de internação por região =================
  tx_reg[, regiao_saude := ROT(regiao_saude)]
  g <- ggplot(tx_reg, aes(ano, taxa, colour = regiao_saude, group = regiao_saude)) +
    geom_line(linewidth = 0.7) + geom_point(size = 1.3) +
    scale_colour_manual(values = CORES9) +
    labs(title = "Taxa de internação por DCV nas regiões de saúde",
         subtitle = "RJ, 2010–2024 (I60–I69, por 100.000 habitantes)",
         x = NULL, y = "Internações por 100.000", colour = NULL) +
    scale_x_continuous(breaks = seq(2010, 2024, 2)) +
    theme(legend.position = "right", legend.text = element_text(size = 7))
  salvar(g, "fig_ex03_taxa_internacao_regiao.png", w = 9.5, h = 5.5)

  ## ================= 4. heatmap internação região x ano =================
  g <- ggplot(tx_reg, aes(ano, regiao_saude, fill = taxa)) +
    geom_tile(colour = "white", linewidth = 0.3) +
    scale_fill_viridis_c(option = "D", name = "Taxa/100 mil") +
    scale_x_continuous(breaks = seq(2010, 2024, 2)) +
    labs(title = "Mapa de calor da taxa de internação por DCV",
         subtitle = "Regiões de saúde × ano, RJ, 2010–2024", x = NULL, y = NULL)
  salvar(g, "fig_ex04_heatmap_internacao_regiao.png", w = 9, h = 4.8)

  ## ================= 5. mortalidade SIM por região =================
  tx_sim_reg[, regiao_saude := ROT(regiao_saude)]
  g <- ggplot(tx_sim_reg[!is.na(taxa)], aes(ano, taxa, colour = regiao_saude, group = regiao_saude)) +
    geom_line(linewidth = 0.7) + geom_point(size = 1.3) +
    scale_colour_manual(values = CORES9) +
    labs(title = "Taxa de mortalidade por DCV nas regiões de saúde",
         subtitle = "Causa básica I60–I69 (SIM), RJ, 2010–2024, por 100.000",
         x = NULL, y = "Óbitos por 100.000", colour = NULL) +
    scale_x_continuous(breaks = seq(2010, 2024, 2)) +
    theme(legend.position = "right", legend.text = element_text(size = 7))
  salvar(g, "fig_ex05_mortalidade_sim_regiao.png", w = 9.5, h = 5.5)

  ## ================= 6. piramide etária =================
  pir <- co_i[!is.na(faixa), .(n = .N), by = .(faixa, sexo)][sexo %in% c("M", "F")]
  pir[, n := ifelse(sexo == "M", -n, n)]
  g <- ggplot(pir, aes(faixa, n, fill = sexo)) +
    geom_col(width = 0.8) + coord_flip() +
    scale_y_continuous(labels = abs, name = "Internações") +
    scale_fill_viridis_d(option = "D", end = 0.75, labels = c("Feminino", "Masculino")) +
    labs(title = "Pirâmide etária das internações por DCV",
         subtitle = "RJ, 2010–2024 (I60–I69)", x = "Faixa etária", fill = NULL) +
    theme(legend.position = "top")
  salvar(g, "fig_ex06_piramide_etaria.png", w = 8, h = 4.5)

  ## ================= 7. letalidade por faixa e sexo =================
  let <- co_i[!is.na(faixa), .(obitos = sum(obito_hospitalar), n = .N), by = .(faixa, sexo)][sexo %in% c("M", "F")]
  let[, `:=`(pct = 100 * obitos / n)]
  let[, lo := 100 * (qbeta(0.025, obitos + 0.5, n - obitos + 0.5))]
  let[, hi := 100 * (qbeta(0.975, obitos + 0.5, n - obitos + 0.5))]
  chisq_fx <- suppressWarnings(chisq.test(as.matrix(let[, .(obitos, vivos = n - obitos)]))$p.value)
  g <- ggplot(let, aes(faixa, pct, colour = sexo, group = sexo)) +
    geom_pointrange(aes(ymin = lo, ymax = hi), position = position_dodge(0.4), size = 0.3) +
    geom_line(position = position_dodge(0.4)) +
    scale_colour_viridis_d(option = "D", end = 0.75, labels = c("Feminino", "Masculino")) +
    labs(title = "Letalidade hospitalar por faixa etária e sexo",
         subtitle = sprintf("Internações por DCV, RJ, 2010–2024 (IC95%% de Wilson; interação faixa × sexo: p %s)",
                            ifelse(chisq_fx < 0.001, "< 0,001", sprintf("= %.3f", chisq_fx))),
         x = "Faixa etária", y = "Óbito hospitalar (%)", colour = NULL) +
    theme(legend.position = "top")
  salvar(g, "fig_ex07_letalidade_faixa_sexo.png")

  ## ================= 8. letalidade por subtipo =================
  st <- co[, .(obitos = sum(obito_hospitalar), n = .N), by = subtipo]
  st[, `:=`(pct = 100 * obitos / n)]
  st[, lo := 100 * qbeta(0.025, obitos + 0.5, n - obitos + 0.5)]
  st[, hi := 100 * qbeta(0.975, obitos + 0.5, n - obitos + 0.5)]
  p_sub <- suppressWarnings(chisq.test(as.matrix(st[, .(obitos, vivos = n - obitos)]))$p.value)
  g <- ggplot(st, aes(reorder(subtipo, pct), pct, fill = pct)) +
    geom_col(width = 0.7) +
    geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.25, colour = "grey30", linewidth = 0.3) +
    coord_flip() + scale_fill_viridis_c(option = "D", guide = "none") +
    labs(title = "Letalidade hospitalar por subtipo diagnóstico",
         subtitle = sprintf("Toda a coorte (I60–I69 + G45/G46), RJ, 2010–2024, com IC95%%; χ²: p %s",
                            ifelse(p_sub < 0.001, "< 0,001", sprintf("= %.3f", p_sub))),
         x = NULL, y = "Óbito hospitalar (%)")
  salvar(g, "fig_ex08_letalidade_subtipo.png", w = 9, h = 5)

  ## ================= 9. permanência por subtipo =================
  kw_perm <- kruskal.test(DIAS_PERM ~ subtipo,
                          data = co[!is.na(DIAS_PERM) & !is.na(subtipo)])
  g <- ggplot(co[!is.na(DIAS_PERM) & DIAS_PERM <= 60 & !is.na(subtipo)],
              aes(subtipo, DIAS_PERM, fill = subtipo)) +
    geom_boxplot(outlier.size = 0.2, width = 0.7, show.legend = FALSE) +
    coord_flip() + scale_y_continuous(limits = c(0, 60)) +
    scale_fill_viridis_d(option = "D") +
    labs(title = "Permanência hospitalar por subtipo diagnóstico",
         subtitle = sprintf("Dias de permanência (limite visual 60 dias), RJ, 2010–2024; Kruskal–Wallis: p %s",
                            ifelse(kw_perm$p.value < 0.001, "< 0,001", sprintf("= %.3f", kw_perm$p.value))),
         x = NULL, y = "Dias de permanência")
  salvar(g, "fig_ex09_permanencia_subtipo.png", w = 9, h = 5)

  ## ================= 10. custo por região =================
  custo <- co_i[!is.na(VAL_TOT) & VAL_TOT > 0]
  custo[, regiao_saude := ROT(regiao_saude)]
  kw_custo <- kruskal.test(VAL_TOT ~ regiao_saude, data = custo)
  g <- ggplot(custo, aes(reorder(regiao_saude, VAL_TOT, FUN = median), VAL_TOT)) +
    geom_boxplot(fill = viridis(1, begin = 0.25), outlier.size = 0.2, width = 0.6) +
    coord_flip() + scale_y_log10(labels = label_number(big.mark = ".")) +
    labs(title = "Custo por internação segundo a região de saúde",
         subtitle = sprintf("Valores correntes (R$), escala logarítmica, RJ, 2010–2024; Kruskal–Wallis: p %s",
                            ifelse(kw_custo$p.value < 0.001, "< 0,001", sprintf("= %.3f", kw_custo$p.value))),
         x = NULL, y = "Valor total da internação (R$)")
  salvar(g, "fig_ex10_custo_regiao.png", w = 9, h = 5)

  ## ================= 11. fluxo residência -> internação =================
  co[, regiao_mov := lk$macro_regiao[match(sprintf("%06s", as.character(MUNIC_MOV6)), lk$ibge6)]]
  fluxo <- co[!is.na(regiao_saude) & !is.na(regiao_mov), .N, by = .(origem = regiao_saude, destino = regiao_mov)]
  fluxo[, pct := 100 * N / sum(N)]
  g <- ggplot(fluxo, aes(origem, destino, fill = pct)) +
    geom_tile(colour = "white", linewidth = 0.3) +
    geom_text(aes(label = ifelse(pct >= 1, sprintf("%.1f", pct), "")), size = 2.4) +
    scale_fill_viridis_c(option = "D", name = "% do total") +
    labs(title = "Fluxo de pacientes entre regiões de residência e de atendimento",
         subtitle = "Percentual das internações por DCV, RJ, 2010–2024 (associação origem × destino: p < 0,001)",
         x = "Região de residência", y = "Região de internação") +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  salvar(g, "fig_ex11_fluxo_regioes.png", w = 9, h = 6)

  ## ================= 12. concentracao por CNES (Lorenz) =================
  h <- fread(file.path(TAB, "tab_hospitais.csv"), encoding = "UTF-8")[order(-n)]
  h[, cum := cumsum(n) / sum(n)]
  h[, prop := seq_len(.N) / .N]
  gini <- 1 - sum((h$cum + data.table::shift(h$cum, fill = 0)) * diff(c(0, h$prop)))
  g <- ggplot(h, aes(prop, cum)) +
    geom_abline(slope = 1, intercept = 0, linetype = 2, colour = "grey50") +
    geom_line(colour = viridis(1, begin = 0.25), linewidth = 1) +
    scale_x_continuous(labels = percent) + scale_y_continuous(labels = percent) +
    labs(title = "Concentração das internações por estabelecimento",
         subtitle = sprintf("Curva de Lorenz entre hospitais; índice de Gini = %.2f", gini),
         x = "Proporção acumulada de hospitais", y = "Proporção acumulada de internações")
  salvar(g, "fig_ex12_concentracao_cnes.png")

  ## ================= 13. volume x mortalidade por hospital =================
  h2 <- copy(h)
  corr_vm <- suppressWarnings(cor.test(log10(h2[n >= 30]$n), h2[n >= 30]$mortalidade, method = "spearman"))
  g <- ggplot(h2[n >= 30], aes(n, mortalidade)) +
    geom_point(aes(size = obitos), colour = viridis(1, begin = 0.3), alpha = 0.6) +
    scale_x_log10(labels = label_number(big.mark = ".")) +
    scale_size_continuous(range = c(0.5, 6), guide = "none") +
    labs(title = "Volume e letalidade hospitalar por estabelecimento",
         subtitle = sprintf("Cada ponto é um hospital (≥ 30 internações); área = nº de óbitos. Correlação de Spearman: p %s",
                            ifelse(corr_vm$p.value < 0.001, "< 0,001", sprintf("= %.3f", corr_vm$p.value))),
         x = "Internações (escala log)", y = "Mortalidade hospitalar (%)")
  salvar(g, "fig_ex13_volume_mortalidade_hospital.png")

  ## ================= 14. caterpillar dos efeitos hospitalares =================
  ef <- fread(file.path(PROC, "efeitos_hospital_glmm.csv"), encoding = "UTF-8")
  ef <- ef[order(u_j)]
  ef[, ordem := .I]
  selec <- ef[ordem %in% c(1:3, (.N - 2):.N)]
  g <- ggplot(ef, aes(ordem, u_j)) +
    geom_hline(yintercept = 0, linetype = 2, colour = "grey50") +
    geom_point(aes(colour = n), size = 0.9) +
    geom_point(data = selec, colour = "firebrick", size = 2) +
    scale_colour_viridis_c(option = "D", trans = "log10", name = "Internações") +
    labs(title = "Efeito aleatório de cada hospital sobre a letalidade",
         subtitle = "Intercepto aleatório (escala logit), ordenado; vermelho = extremos. Modelo principal (script 05)",
         x = "Hospitais (ordenados)", y = "Efeito do hospital (u_j)")
  salvar(g, "fig_ex14_caterpillar_hospitais.png", w = 9, h = 5)

  ## ================= 15. forest dos OR (modelo principal) =================
  or <- fread(file.path(TAB, "tab3_glmm_or.csv"), encoding = "UTF-8")
  or <- or[!is.na(or) & termo != "(Intercept)"]
  n_sig <- sum(!is.na(or$q_bh) & or$q_bh < 0.05)
  or[, sig := ifelse(!is.na(q_bh) & q_bh < 0.05, "q < 0,05 (FDR)", "Não significativo")]
  g <- ggplot(or, aes(or, reorder(termo, or), colour = sig)) +
    geom_vline(xintercept = 1, linetype = 2, colour = "grey50") +
    geom_pointrange(aes(xmin = lo, xmax = hi), size = 0.35) +
    scale_x_log10() + scale_colour_manual(values = c("grey55", viridis(1, begin = 0.25))) +
    labs(title = "Razões de chance ajustadas da mortalidade intra-hospitalar",
         subtitle = sprintf("Modelo multinível principal; IC95%%. Significativos após FDR (Benjamini–Hochberg): %d de %d",
                            n_sig, nrow(or)),
         x = "OR (escala log)", y = NULL, colour = NULL) +
    theme(legend.position = "top")
  salvar(g, "fig_ex15_forest_or_principal.png", w = 9, h = 6)

  ## ================= 16. ICC nos cenários de robustez =================
  rob <- fread(file.path(TAB, "tab8_robustez_componentes.csv"), encoding = "UTF-8")
  rob[, ICC_pct := 100 * ICC]
  icc0 <- rob[cenario == "S0_principal", ICC_pct]
  g <- ggplot(rob, aes(reorder(cenario, ICC_pct), ICC_pct)) +
    geom_col(fill = viridis(1, begin = 0.3), width = 0.7) +
    geom_hline(yintercept = icc0, linetype = 2, colour = "firebrick") +
    coord_flip() +
    labs(title = "Heterogeneidade entre hospitais nos 18 cenários de robustez",
         subtitle = sprintf("VPC/ICC (%%); linha vermelha = cenário principal (%.2f%%)", icc0),
         x = NULL, y = "VPC/ICC (%)")
  salvar(g, "fig_ex16_icc_robustez.png", w = 9, h = 6)

  ## ================= 17. ICC nos modelos sequenciais M0-M4 =================
  m <- fread(file.path(TAB, "tab22c_comparacao_mesma_amostra.csv"), encoding = "UTF-8")
  ml <- melt(m[, .(modelo, `VPC/ICC base` = ICC_base_mesma_amostra,
                   `VPC/ICC modelo` = ICC_modelo)],
             id.vars = "modelo", variable.name = "serie", value.name = "ICC")
  ml[, ICC := 100 * ICC]
  delta_lab <- m[, .(modelo, delta_ICC_pp)]
  g <- ggplot(ml, aes(reorder(modelo, ICC), ICC, fill = serie)) +
    geom_col(position = position_dodge(0.7), width = 0.65) +
    geom_text(data = delta_lab, aes(x = modelo, y = 1, label = sprintf("ΔICC = %+.2f p.p.", delta_ICC_pp)),
              inherit.aes = FALSE, hjust = -0.05, size = 2.6, colour = "grey20") +
    coord_flip() + scale_fill_viridis_d(option = "D", end = 0.8) +
    labs(title = "Quanto da heterogeneidade hospitalar as variáveis explicam",
         subtitle = "VPC/ICC na mesma amostra, antes e depois de cada bloco de variáveis",
         x = NULL, y = "VPC/ICC (%)", fill = NULL) +
    theme(legend.position = "top")
  salvar(g, "fig_ex17_icc_modelos.png", w = 9, h = 5)

  ## ================= 18. uso de UTI por hospital =================
  uti_h <- fread(file.path(TAB, "tab18_uti_hospital.csv"), encoding = "UTF-8")
  g <- ggplot(uti_h, aes(uti_pct)) +
    geom_histogram(bins = 30, fill = viridis(1, begin = 0.3), colour = "white") +
    geom_vline(xintercept = 10, linetype = 2, colour = "firebrick") +
    labs(title = "Distribuição do registro de UTI entre estabelecimentos",
         subtitle = "Percentual de internações com UTI por hospital; linha = 10%",
         x = "Internações com UTI (%)", y = "Número de hospitais")
  salvar(g, "fig_ex18_uti_hospital.png")

  ## ================= 19. curva ROC =================
  pv <- fread(file.path(PROC, "previsoes_glmm.csv"), encoding = "UTF-8",
              select = c("obito_hospitalar", "p_marg", "p_cond"))
  r_cond <- roc(pv$obito_hospitalar, pv$p_cond, quiet = TRUE)
  r_marg <- roc(pv$obito_hospitalar, pv$p_marg, quiet = TRUE)
  rocdf <- rbind(
    data.table(fpr = 1 - r_cond$specificities, tpr = r_cond$sensitivities,
               modelo = sprintf("Condicional (AUC = %.3f)", auc(r_cond))),
    data.table(fpr = 1 - r_marg$specificities, tpr = r_marg$sensitivities,
               modelo = sprintf("Marginal (AUC = %.3f)", auc(r_marg))))
  g <- ggplot(rocdf, aes(fpr, tpr, colour = modelo)) +
    geom_abline(slope = 1, intercept = 0, linetype = 2, colour = "grey50") +
    geom_line(linewidth = 1) +
    scale_colour_viridis_d(option = "D", end = 0.8) +
    labs(title = "Capacidade discriminante do modelo multinível",
         subtitle = "Curva ROC da previsão condicional e marginal do óbito hospitalar",
         x = "1 − especificidade", y = "Sensibilidade", colour = NULL) +
    theme(legend.position = "bottom")
  salvar(g, "fig_ex19_roc.png")

  ## ================= 20. calibração =================
  cal <- fread(file.path(TAB, "tab5_calibracao.csv"), encoding = "UTF-8")
  g <- ggplot(cal, aes(esp_pct, obs_pct, colour = tipo)) +
    geom_abline(slope = 1, intercept = 0, linetype = 2, colour = "grey50") +
    geom_line(linewidth = 0.9) + geom_point(size = 2) +
    scale_colour_viridis_d(option = "D", end = 0.8) +
    labs(title = "Calibração do modelo por decil de risco previsto",
         subtitle = "Óbito observado versus esperado (%), previsão marginal e condicional",
         x = "Óbito esperado (%)", y = "Óbito observado (%)", colour = NULL) +
    theme(legend.position = "top")
  salvar(g, "fig_ex20_calibracao.png")

  ## ================= 21. ISU por região e ano =================
  isu <- fread(file.path(TAB, "tab7_isu_regiao_ano.csv"), encoding = "UTF-8")
  g <- ggplot(isu, aes(ano, regiao_saude, fill = ISU)) +
    geom_tile(colour = "white", linewidth = 0.3) +
    scale_fill_viridis_c(option = "D", name = "ISU (%)") +
    scale_x_continuous(breaks = seq(2010, 2024, 2)) +
    labs(title = "Índice de Swaroop–Uemura por região de saúde",
         subtitle = "Percentual de óbitos por DCV em pessoas de 50 anos ou mais, 2010–2024",
         x = NULL, y = NULL)
  salvar(g, "fig_ex21_isu_heatmap.png", w = 9, h = 4.8)

  ## ================= 22. razão óbito/internação por região =================
  rz <- fread(file.path(TAB, "razao_obito_internacao_regiao.csv"), encoding = "UTF-8")
  setnames(rz, 1, "regiao_saude")
  g <- ggplot(rz, aes(reorder(regiao_saude, razao_pct), razao_pct, fill = razao_pct)) +
    geom_col(width = 0.7) + coord_flip() +
    scale_fill_viridis_c(option = "D", guide = "none") +
    labs(title = "Razão entre óbitos (SIM) e internações (SIH) por região",
         subtitle = "Óbitos por causa básica I60–I69 por 100 internações, RJ, 2010–2024",
         x = NULL, y = "Óbitos por 100 internações")
  salvar(g, "fig_ex22_razao_obito_internacao.png", w = 8, h = 5)

  ## ================= 23. custo deflacionado por ano =================
  ca <- fread(file.path(TAB, "custos_deflacionados_ipca_ano.csv"), encoding = "UTF-8")
  g <- ggplot(ca, aes(ano, custo_deflacionado_dez2024 / 1e6)) +
    geom_col(fill = viridis(1, begin = 0.3), width = 0.7) +
    geom_line(aes(y = custo_corrente / 1e6), colour = viridis(1, begin = 0.85),
              linewidth = 0.8) +
    scale_x_continuous(breaks = seq(2010, 2024, 2)) +
    labs(title = "Custo das internações por DCV, corrente e deflacionado",
         subtitle = "Milhões de R$; barras = deflacionado a dez/2024, linha = corrente (IPCA/SIDRA 1737)",
         x = NULL, y = "Milhões de R$")
  salvar(g, "fig_ex23_custo_ano.png")

  ## ================= 24. tendência Mann-Kendall por região =================
  te <- fread(file.path(TAB, "tendencia_mann_kendall.csv"), encoding = "UTF-8")
  te <- te[unidade == "regiao_saude"]
  te[, sig := ifelse(p < 0.05, "p < 0,05", "p ≥ 0,05")]
  g <- ggplot(te, aes(reorder(grupo, taxa_2024), taxa_2024, fill = sig)) +
    geom_col(width = 0.7) +
    geom_point(aes(y = taxa_2010), shape = 18, colour = "grey20", size = 2) +
    geom_text(aes(label = sprintf("p = %.3f", p)), hjust = -0.08, size = 2.5, colour = "grey25") +
    coord_flip() + scale_fill_viridis_d(option = "D", end = 0.8) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.18))) +
    labs(title = "Taxa de internação em 2010 e 2024 por região de saúde",
         subtitle = "Barras = 2024; losangos = 2010; cor e rótulo = p do teste de Mann–Kendall",
         x = NULL, y = "Internações por 100.000", fill = NULL) +
    theme(legend.position = "top")
  salvar(g, "fig_ex24_tendencia_regiao.png", w = 9, h = 5)

  ## ================= 25. cobertura de comorbidade por ano =================
  cc <- co[, .(pct_com_diag = 100 * mean(n_diag_sec > 0)), by = ano]
  g <- ggplot(cc, aes(ano, pct_com_diag)) +
    geom_col(fill = viridis(1, begin = 0.3), width = 0.7) +
    scale_x_continuous(breaks = seq(2010, 2024, 2)) +
    labs(title = "Registro de diagnósticos secundários nas internações",
         subtitle = "Percentual de internações com ao menos um diagnóstico secundário (mede codificação, não comorbidade)",
         x = NULL, y = "% com diagnóstico secundário")
  salvar(g, "fig_ex25_cobertura_comorbidade.png")

  say("\nfim: ", format(Sys.time()), " | figuras em ", FIG_EX)
  close(logcon)
})
