# 10_figuras.R
# Figuras do Bloco 4, por região de saúde.
#
#   06_figuras/fig_or_forest.png            OR ajustado do GLMM, com FDR
#   06_figuras/fig_regioes_ajustado.png     OR ajustado por região de saúde
#   06_figuras/fig_funnel_hospitais.png     mortalidade observada/esperada por hospital
#   06_figuras/fig_mortalidade_subtipo.png  mortalidade por subtipo diagnóstico
#
# A figura do Índice de Swaroop-Uemura e produzida pelo script 04 e a do uso
# de UTI pelo script 06.
#
# O mapa coroplático das regiões de saúde (malha municipal do geobr dissolvida)
# e a Figura 1 do manuscrito são gerados pelo script 24_mapa_regioes_saude.R.
# As demais figuras usam barras e intervalos de confiança.

suppressWarnings({
  options(stringsAsFactors = FALSE)
  library(data.table)
  library(ggplot2)
  library(ragg)

  ROOT <- normalizePath(".")
  PROC <- file.path(ROOT, "01_dados", "processados")
  TAB <- file.path(ROOT, "05_tabelas")
  FIG <- file.path(ROOT, "06_figuras", "manuscrito")
  FIG_SUP <- file.path(ROOT, "06_figuras", "suplementares")
  RES <- file.path(ROOT, "04_resultados")
  dir.create(FIG, showWarnings = FALSE, recursive = TRUE)
  dir.create(FIG_SUP, showWarnings = FALSE, recursive = TRUE)

  logcon <- file(file.path(RES, "resultados_figuras_glmm.txt"), open = "wt", encoding = "UTF-8")
  say <- function(...) { m <- paste0(...); cat(m, "\n"); writeLines(m, logcon); flush(logcon) }

  say("FIGURAS DO GLMM | inicio: ", format(Sys.time()))

  or <- fread(file.path(TAB, "tab3_glmm_or.csv"), encoding = "UTF-8")
  eh <- fread(file.path(PROC, "efeitos_hospital_glmm.csv"), encoding = "UTF-8")
  pv <- fread(file.path(PROC, "previsoes_glmm.csv"), encoding = "UTF-8")

  ## ---- paleta viridis, única em todas as figuras deste script ----
  COR_LINHA <- viridisLite::viridis(1, begin = 0.30)
  CORES_BLOCO <- viridisLite::viridis(3, option = "D", begin = 0.15, end = 0.85)
  names(CORES_BLOCO) <- c("Paciente", "Subtipo diagnostico", "Regiao de saude")
  CORES_FORA <- viridisLite::viridis(3, option = "D", begin = 0.25, end = 0.95)
  names(CORES_FORA) <- c("Dentro do esperado",
                         "Fora dos limites ajustados 95%",
                         "Fora dos limites ajustados 99,8%")

  ## ================= 1. forest plot geral =================
  o <- or[termo != "(Intercept)"]
  o[, bloco := fifelse(grepl("^regiao_saude", termo), "Regiao de saude",
                fifelse(grepl("^subtipo", termo), "Subtipo diagnostico", "Paciente"))]
  o[, rotulo := gsub("^regiao_saude", "", termo)]
  o[, rotulo := gsub("^subtipo", "", rotulo)]
  o[, rotulo := gsub("^car_int", "Car\u00e1ter: ", rotulo)]
  o[, rotulo := gsub("^sexo", "Sexo: ", rotulo)]
  o[, rotulo := gsub("idade_z", "Idade (+1 DP)", rotulo)]
  o[, rotulo := gsub("^uti$", "Uso de UTI", rotulo)]
  o[, rotulo := gsub("fluxo_inter", "Fluxo intermunicipal", rotulo)]
  o[, rotulo := factor(rotulo, levels = rev(rotulo[order(bloco, or)]))]
  ## a significância e marcada pela q-valor de Benjamini-Hochberg (FDR)
  o[, sig_fdr := fifelse(!is.na(q_bh) & q_bh < 0.05,
                         "q < 0,05 (FDR)", "nao significativo apos FDR")]

  g1 <- ggplot(o, aes(x = or, y = rotulo, colour = bloco)) +
    geom_vline(xintercept = 1, linetype = "dashed", colour = "grey40") +
    geom_errorbar(aes(xmin = lo, xmax = hi), orientation = "y", width = 0.22) +
    geom_point(aes(shape = sig_fdr), size = 2.6, fill = "white") +
    scale_shape_manual(values = c("q < 0,05 (FDR)" = 16,
                                  "nao significativo apos FDR" = 1)) +
    scale_x_log10() +
    scale_colour_viridis_d(option = "D", end = 0.85, name = NULL) +
    labs(title = "Odds ratio ajustado de \u00f3bito intra-hospitalar",
         subtitle = paste0("Modelo log\u00edstico multin\u00edvel com intercepto aleat\u00f3rio por ",
                           "hospital (CNES) - RJ, 2014-2024\n",
                           "Pontos cheios: significativos ap\u00f3s corre\u00e7\u00e3o de FDR ",
                           "(Benjamini-Hochberg); pontos vazios: n\u00e3o significativos"),
         x = "OR ajustado (escala logar\u00edtmica, IC95%)", y = NULL,
         colour = NULL, shape = NULL) +
    theme_minimal(base_size = 13) +
    theme(plot.title = element_text(face = "bold"),
          plot.subtitle = element_text(size = 11),
          legend.position = "bottom",
          panel.grid.minor = element_blank())
  ggsave(file.path(FIG, "fig_or_forest.png"), g1, width = 9.5, height = 7.5, dpi = 300)
  say("gravada fig_or_forest.png")

  ## ================= 2. regiões isoladas =================
  r <- o[bloco == "Regiao de saude"]
  r[, regiao := gsub("^regiao_saude", "", termo)]
  r <- rbind(r[, .(regiao, or, lo, hi)],
             data.table(regiao = "Metropolitana I", or = 1, lo = 1, hi = 1))
  r[, regiao := factor(regiao, levels = regiao[order(or)])]

  g2 <- ggplot(r, aes(x = or, y = regiao)) +
    geom_vline(xintercept = 1, linetype = "dashed", colour = "grey40") +
    geom_errorbar(aes(xmin = lo, xmax = hi), orientation = "y", width = 0.2,
                  colour = COR_LINHA) +
    geom_point(size = 2.8, colour = COR_LINHA) +
    geom_text(aes(label = sprintf("%.2f", or)), vjust = -0.9, size = 3.8) +
    scale_x_log10() +
    labs(title = "Efeito ajustado da regi\u00e3o de sa\u00fade de resid\u00eancia",
         subtitle = paste0("OR de \u00f3bito intra-hospitalar em rela\u00e7\u00e3o \u00e0 Metropolitana I, ",
                           "ap\u00f3s ajuste por perfil do paciente e efeito aleat\u00f3rio do hospital"),
         x = "OR ajustado (IC95%)", y = NULL) +
    theme_minimal(base_size = 14) +
    theme(plot.title = element_text(face = "bold"),
          plot.subtitle = element_text(size = 11),
          panel.grid.minor = element_blank())
  ggsave(file.path(FIG, "fig_regioes_ajustado.png"), g2, width = 9, height = 5.5, dpi = 300)
  say("gravada fig_regioes_ajustado.png")

  ## ================= 3. funnel plot observado/esperado =================
  ## Limites ingenuos (Poisson) e limites ajustados pela variância entre
  ## hospitais (s2 do GLMM). Sem o ajuste, a heterogeneidade real entre
  ## hospitais e interpretada como desempenho atipico de cada um.
  comp_tab <- fread(file.path(TAB, "tab4_glmm_componentes.csv"), encoding = "UTF-8")
  s2_hosp <- as.numeric(comp_tab[metrica == "Variancia hospitalar (s2_hosp)", valor])
  say("variancia entre hospitais usada no funnel: s2 = ", s2_hosp)

  f <- copy(eh)
  f <- f[n > 0]
  f[, esperado := as.numeric(esperado)]
  f <- f[esperado > 0]
  MIN_ESP <- 5
  n_todos <- nrow(f)
  f <- f[esperado >= MIN_ESP]
  f[, oe := obitos / esperado]
  f[, `:=`(
    l998_pois_sup = qpois(0.999, esperado) / esperado,
    l998_pois_inf = qpois(0.001, esperado) / esperado,
    l95_aj_sup = exp(1.96 * sqrt(1 / esperado + s2_hosp)),
    l95_aj_inf = exp(-1.96 * sqrt(1 / esperado + s2_hosp)),
    l998_aj_sup = exp(3.09 * sqrt(1 / esperado + s2_hosp)),
    l998_aj_inf = exp(-3.09 * sqrt(1 / esperado + s2_hosp)))]
  f[, fora := fifelse(oe > l998_aj_sup | oe < l998_aj_inf, "Fora dos limites ajustados 99,8%",
              fifelse(oe > l95_aj_sup | oe < l95_aj_inf, "Fora dos limites ajustados 95%",
                      "Dentro do esperado"))]
  setorder(f, esperado)
  say("hospitais com obito esperado > 0: ", n_todos)
  say("hospitais no funnel (esperado >= ", MIN_ESP, " obitos): ", nrow(f),
      " | excluidos por baixo volume de eventos: ", n_todos - nrow(f))
  say("  fora dos limites de Poisson 99,8%: ",
      sum(f$oe > f$l998_pois_sup | f$oe < f$l998_pois_inf))
  say("  fora dos limites AJUSTADOS 99,8%:  ",
      sum(f$fora == "Fora dos limites ajustados 99,8%"))
  say("  fora dos limites AJUSTADOS 95% (total): ",
      sum(f$fora != "Dentro do esperado"))

  g3 <- ggplot(f, aes(x = esperado, y = oe)) +
    geom_hline(yintercept = 1, colour = "grey25") +
    geom_line(aes(y = l998_pois_sup), linetype = "dotted", colour = COR_LINHA) +
    geom_line(aes(y = l998_pois_inf), linetype = "dotted", colour = COR_LINHA) +
    geom_line(aes(y = l998_aj_sup), linetype = "longdash", colour = CORES_FORA[[1]]) +
    geom_line(aes(y = l998_aj_inf), linetype = "longdash", colour = CORES_FORA[[1]]) +
    geom_point(aes(colour = fora, size = fora, alpha = fora)) +
    scale_x_log10() +
    scale_y_log10(limits = c(0.04, 25)) +
    scale_colour_manual(values = CORES_FORA) +
    scale_size_manual(values = c("Dentro do esperado" = 1.5,
                                 "Fora dos limites ajustados 95%" = 2.2,
                                 "Fora dos limites ajustados 99,8%" = 2.9),
                      guide = "none") +
    scale_alpha_manual(values = c("Dentro do esperado" = 0.45,
                                  "Fora dos limites ajustados 95%" = 0.95,
                                  "Fora dos limites ajustados 99,8%" = 1),
                       guide = "none") +
    labs(title = "Mortalidade observada em rela\u00e7\u00e3o \u00e0 esperada, por hospital",
         subtitle = paste0("Hospitais com pelo menos ", MIN_ESP,
                           " \u00f3bitos esperados; esperado obtido pelo GLMM (perfil do paciente).\n",
                           "Pontilhado: limites de Poisson; linha longa: limites ajustados pela vari\u00e2ncia entre hospitais"),
         x = "\u00d3bitos esperados (escala logar\u00edtmica)",
         y = "Raz\u00e3o observado/esperado (escala logar\u00edtmica)",
         colour = NULL) +
    theme_minimal(base_size = 14) +
    theme(plot.title = element_text(face = "bold"),
          plot.subtitle = element_text(size = 10.5),
          legend.position = "bottom",
          panel.grid.minor = element_blank())
  ggsave(file.path(FIG_SUP, "fig_funnel_hospitais.png"), g3, width = 9, height = 6, dpi = 300,
         device = ragg::agg_png)
  ## Figura 2 do manuscrito: mesma figura, em JPEG 300 dpi (requisito do edital).
  ggsave(file.path(FIG, "figura2_funnel_hospitais.jpg"), g3, width = 9, height = 6, dpi = 300,
         device = ragg::agg_jpeg, quality = 95)
  say("gravada fig_funnel_hospitais.png (suplementares) e figura2_funnel_hospitais.jpg (manuscrito)")
  fwrite(f[, .(CNES, n, obitos, esperado = round(esperado, 1), oe = round(oe, 3),
               fora_poisson_998 = oe > l998_pois_sup | oe < l998_pois_inf,
               fora_ajustado_998 = fora == "Fora dos limites ajustados 99,8%",
               fora_ajustado_95 = fora != "Dentro do esperado")],
         file.path(TAB, "tab12_funnel_hospitais.csv"), encoding = "UTF-8")

  ## ================= 4. mortalidade por subtipo =================
  s <- pv[, .(n = .N, obitos = sum(obito_hospitalar),
              mortalidade = 100 * mean(obito_hospitalar)), by = subtipo]
  s <- s[!is.na(subtipo)]
  s[, subtipo := factor(subtipo, levels = subtipo[order(mortalidade)])]

  g4 <- ggplot(s, aes(x = mortalidade, y = subtipo, fill = mortalidade)) +
    geom_col(width = 0.68) +
    geom_text(aes(label = sprintf("%.1f%%  (n=%s)", mortalidade,
                                  format(n, big.mark = "."))),
              hjust = -0.06, size = 3.1, colour = "grey20") +
    scale_fill_viridis_c(option = "D", direction = -1, guide = "none") +
    scale_x_continuous(expand = expansion(mult = c(0, 0.28))) +
    labs(title = "Mortalidade intra-hospitalar por subtipo diagn\u00f3stico",
         subtitle = "Coorte I60-I69 e c\u00f3digos G45 e G46, RJ, 2014-2024",
         x = "Mortalidade intra-hospitalar (%)", y = NULL) +
    theme_minimal(base_size = 11) +
    theme(plot.title = element_text(face = "bold"),
          panel.grid.major.y = element_blank())
  ggsave(file.path(FIG, "fig_mortalidade_subtipo.png"), g4, width = 9, height = 5, dpi = 300)
  say("gravada fig_mortalidade_subtipo.png")

  say("fim: ", format(Sys.time()))
  close(logcon)
})
