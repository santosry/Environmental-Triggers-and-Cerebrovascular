# 19_figura_exploratorio.R
# Regenera a figura-painel do script 11 (06_figuras/suplementares/
# fig_exploratorio.png) a partir dos resultados já cacheados em 05_tabelas
# e da coorte. Existe para permitir refazer a figura (rótulos acentuados e
# p-valores) sem reajustar os modelos exploratorios, que levam mais de uma
# hora. O script 11 chama este arquivo ao final.
#
# Entradas: coorte_glmm_2010_2024.csv, tab22_exploratorio_modelos.csv,
#           tab24_interacoes.csv, tab25_permanencia.csv
# Saída:    06_figuras/suplementares/fig_exploratorio.png

suppressWarnings({
  options(stringsAsFactors = FALSE)
  library(data.table)
  library(ggplot2)
  library(ragg)
  library(patchwork)

  ROOT <- normalizePath(".")
  PROC <- file.path(ROOT, "01_dados", "processados")
  TAB <- file.path(ROOT, "05_tabelas")
  FIG <- file.path(ROOT, "06_figuras", "suplementares")
  dir.create(FIG, showWarnings = FALSE, recursive = TRUE)

  d <- fread(file.path(PROC, "coorte_glmm_2010_2024.csv"), encoding = "UTF-8",
             na.strings = c("NA", ""),
             select = c("obito_hospitalar", "sexo", "idade_anos", "raca_cor",
                        "n_diag_sec", "nat_jur_lab", "DIAS_PERM", "uti"))
  d[, faixa_idade := cut(idade_anos, c(-1, 40, 50, 60, 70, 80, 200),
                         labels = c("<40", "40-49", "50-59", "60-69", "70-79", "80+"))]

  fmt_p <- function(p) ifelse(is.na(p), "n/d", ifelse(p < 0.001, "< 0,001", sprintf("= %.3f", p)))

  ## ---- painel 1: raça/cor ----
  r1 <- d[, .(n = .N, mort = 100 * mean(obito_hospitalar)), by = raca_cor][order(-mort)]
  p_raca <- suppressWarnings(chisq.test(table(d$raca_cor, d$obito_hospitalar))$p.value)
  g1 <- ggplot(r1, aes(x = mort, y = reorder(raca_cor, mort), fill = mort)) +
    geom_col(width = 0.65) +
    geom_text(aes(label = sprintf("%.2f%%  (n=%s)", mort, format(n, big.mark = "."))),
              hjust = -0.06, size = 3.1, colour = "grey20") +
    scale_fill_viridis_c(option = "D", guide = "none") +
    scale_x_continuous(expand = expansion(mult = c(0, 0.34))) +
    labs(title = "Mortalidade intra-hospitalar por raça/cor",
         subtitle = sprintf("Inclui o grupo com raça/cor ausente (NA), de maior mortalidade; χ²: p %s",
                            fmt_p(p_raca)),
         x = "%", y = NULL) +
    theme_minimal(base_size = 10) +
    theme(plot.title = element_text(face = "bold"),
          plot.subtitle = element_text(size = 7.5),
          panel.grid.major.y = element_blank())

  ## ---- painel 2: faixa de idade x sexo ----
  r2 <- d[sexo %in% c("F", "M"), .(n = .N, mort = 100 * mean(obito_hospitalar)),
          by = .(faixa_idade, sexo)]
  ti <- fread(file.path(TAB, "tab24_interacoes.csv"), encoding = "UTF-8")
  p_int_sexo <- ti[interacao == "sexo x faixa de idade", p]
  g2 <- ggplot(r2, aes(x = faixa_idade, y = mort, colour = sexo, group = sexo)) +
    geom_line(linewidth = 0.9) + geom_point(size = 2.2) +
    scale_colour_viridis_d(option = "D", end = 0.72, name = "Sexo") +
    labs(title = "Mortalidade por faixa de idade e sexo",
         subtitle = sprintf("Interação sexo × faixa de idade (razão de verossimilhança): p %s",
                            fmt_p(p_int_sexo)),
         x = "Faixa de idade (anos)", y = "Mortalidade (%)") +
    theme_minimal(base_size = 10) +
    theme(plot.title = element_text(face = "bold"),
          plot.subtitle = element_text(size = 7.5), legend.position = "bottom")

  ## ---- painel 3: diagnósticos secundários ----
  r3 <- d[n_diag_sec <= 5, .(n = .N, mort = 100 * mean(obito_hospitalar)),
          by = n_diag_sec][order(n_diag_sec)]
  p_diag <- suppressWarnings(chisq.test(table(d$n_diag_sec, d$obito_hospitalar))$p.value)
  g3 <- ggplot(r3, aes(x = factor(n_diag_sec), y = mort, fill = mort)) +
    geom_col(width = 0.7) +
    geom_text(aes(label = sprintf("%.1f", mort)), vjust = -0.5, size = 3, colour = "grey20") +
    scale_fill_viridis_c(option = "D", guide = "none") +
    scale_y_continuous(expand = expansion(mult = c(0, 0.16))) +
    labs(title = "Mortalidade por número de diagnósticos secundários",
         subtitle = sprintf("Relação não monotônica; o campo mede codificação (χ²: p %s)", fmt_p(p_diag)),
         x = "Diagnósticos secundários preenchidos", y = "Mortalidade (%)") +
    theme_minimal(base_size = 10) +
    theme(plot.title = element_text(face = "bold"),
          plot.subtitle = element_text(size = 7.5), panel.grid.major.x = element_blank())

  ## ---- painel 4: natureza jurídica ----
  r4 <- d[, .(n = .N, mort = 100 * mean(obito_hospitalar)), by = nat_jur_lab][n >= 500][order(-mort)]
  p_nat <- suppressWarnings(chisq.test(table(d$nat_jur_lab, d$obito_hospitalar))$p.value)
  g4 <- ggplot(r4, aes(x = mort, y = reorder(nat_jur_lab, mort), fill = mort)) +
    geom_col(width = 0.65) +
    geom_text(aes(label = sprintf("%.2f%%  (n=%s)", mort, format(n, big.mark = "."))),
              hjust = -0.06, size = 3.1, colour = "grey20") +
    scale_fill_viridis_c(option = "D", guide = "none") +
    scale_x_continuous(expand = expansion(mult = c(0, 0.36))) +
    labs(title = "Mortalidade por natureza jurídica do estabelecimento",
         subtitle = sprintf("Diferença bruta de composição de casos (χ²: p %s)", fmt_p(p_nat)),
         x = "%", y = NULL) +
    theme_minimal(base_size = 10) +
    theme(plot.title = element_text(face = "bold"),
          plot.subtitle = element_text(size = 7.5), panel.grid.major.y = element_blank())

  ## ---- painel 5: VPC/ICC pelos modelos ----
  md <- fread(file.path(TAB, "tab22_exploratorio_modelos.csv"), encoding = "UTF-8")
  g5 <- ggplot(md, aes(x = 100 * ICC, y = reorder(modelo, ICC), fill = ICC)) +
    geom_col(width = 0.62) +
    geom_text(aes(label = sprintf("%.2f%%", 100 * ICC)), hjust = -0.12, size = 3.1,
              colour = "grey20") +
    scale_fill_viridis_c(option = "D", direction = -1, guide = "none") +
    scale_x_continuous(expand = expansion(mult = c(0, 0.22))) +
    labs(title = "VPC/ICC hospitalar conforme as covariáveis incluídas",
         subtitle = "Se o ICC cai muito ao incluir uma variável, ela era, em parte, o hospital",
         x = "VPC / ICC (%)", y = NULL) +
    theme_minimal(base_size = 10) +
    theme(plot.title = element_text(face = "bold"),
          plot.subtitle = element_text(size = 7.5), panel.grid.major.y = element_blank())

  ## ---- painel 6: permanência por desfecho e UTI ----
  perm <- fread(file.path(TAB, "tab25_permanencia.csv"), encoding = "UTF-8")
  d[, grp_p := interaction(fifelse(obito_hospitalar == 1, "Óbito", "Alta"),
                           fifelse(uti == 1, "Com UTI", "Sem UTI"), sep = " / ")]
  kw_perm <- suppressWarnings(kruskal.test(DIAS_PERM ~ grp_p, data = d[!is.na(DIAS_PERM)])$p.value)
  g6 <- ggplot(perm, aes(x = uti, y = mediana, fill = uti)) +
    geom_col(width = 0.6) +
    geom_text(aes(label = sprintf("%.0f dias", mediana)), vjust = -0.5, size = 3,
              colour = "grey20") +
    facet_wrap(~ desfecho) +
    scale_fill_viridis_d(option = "D", end = 0.75, guide = "none") +
    scale_y_continuous(expand = expansion(mult = c(0, 0.18))) +
    labs(title = "Permanência mediana por desfecho e uso de UTI",
         subtitle = sprintf("Permanência faturável, em dias (Kruskal–Wallis: p %s)", fmt_p(kw_perm)),
         x = NULL, y = "Dias") +
    theme_minimal(base_size = 10) +
    theme(plot.title = element_text(face = "bold"),
          plot.subtitle = element_text(size = 7.5), panel.grid.major.x = element_blank())

  ggsave(file.path(FIG, "fig_exploratorio.png"),
         (g1 | g2) / (g3 | g4) / (g5 | g6),
         width = 15, height = 14, dpi = 300, device = ragg::agg_png)
  message("figura gravada: 06_figuras/suplementares/fig_exploratorio.png")
})
