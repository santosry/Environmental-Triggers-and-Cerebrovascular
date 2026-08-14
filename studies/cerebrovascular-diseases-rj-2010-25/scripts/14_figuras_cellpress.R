source("scripts/_bootstrap.R", encoding = "UTF-8")

required_packages <- c("geobr", "sf", "ggplot2", "viridisLite")
missing_packages <- required_packages[!vapply(
  required_packages, requireNamespace, logical(1),
  quietly = TRUE
)]
if (length(missing_packages)) {
  stop("Pacotes ausentes: ", paste(missing_packages, collapse = ", "))
}

read_table <- function(name) {
  path <- project_path("results", "tables", name)
  if (!file.exists(path)) stop("Tabela ausente: ", path)
  utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
}

bind_figure_metadata <- function(...) {
  do.call(rbind, list(...))
}

palette <- publication_palette()
options(
  duckdb.extension_directory = project_path(
    "data-raw", "geobr", "duckdb_extensions"
  )
)
ensure_dir(getOption("duckdb.extension_directory"))
municipalities <- geobr::read_municipality(
  year = 2020, code_muni = 33, simplified = TRUE, output = "sf",
  showProgress = FALSE, cache = TRUE, verbose = FALSE
)
if (nrow(municipalities) != 92L || sf::st_crs(municipalities)$epsg != 4674) {
  stop("Malha municipal geobr inválida: esperados 92 municípios em SIRGAS 2000.")
}
municipality_codes <- unique(normalize_municipality_code(municipalities$code_muni))

complete_map_rates <- function(rates, years) {
  template <- expand.grid(
    municipio = municipality_codes, ano = years, stringsAsFactors = FALSE
  )
  selected <- rates[c("municipio", "ano", "taxa_100mil")]
  selected$municipio <- normalize_municipality_code(selected$municipio)
  merge(template, selected, by = c("municipio", "ano"), all.x = TRUE)
}

# FIG1 e FIG2: evolução espacial -----------------------------------------
sih_rates <- read_table("taxas_municipais_sih.csv")
sim_rates <- read_table("taxas_municipais_sim.csv")
sih_map_data <- complete_map_rates(sih_rates, 2010:2025)
sim_map_data <- complete_map_rates(sim_rates, 2010:2024)

figure_1 <- map_evolution_plot(municipalities, sih_map_data, NULL)
metadata_1 <- save_publication_figure(
  figure_1, "FIG1_mapa_evolucao_taxas_sih",
  width = 7.5, height = 9,
  dpi = cfg$figures$publication_dpi
)
figure_2 <- map_evolution_plot(municipalities, sim_map_data, NULL)
metadata_2 <- save_publication_figure(
  figure_2, "FIG2_mapa_evolucao_taxas_sim",
  width = 7.5, height = 8.5,
  dpi = cfg$figures$publication_dpi
)

# FIG3: sazonalidade ------------------------------------------------------
monthly <- utils::read.csv(
  project_path("data", "processed", "painel_mensal_integrado.csv"),
  stringsAsFactors = FALSE
)
monthly$sistema <- factor(
  monthly$sistema,
  levels = c("SIH_internacoes", "SIM_obitos_causa_basica"),
  labels = c("A  SIH — internações", "B  SIM — óbitos")
)
monthly$intensidade_relativa <- ave(
  monthly$eventos, monthly$sistema,
  FUN = function(x) x / mean(x, na.rm = TRUE)
)
figure_3 <- ggplot2::ggplot(
  monthly,
  ggplot2::aes(
    x = factor(mes), y = factor(ano), fill = intensidade_relativa
  )
) +
  ggplot2::geom_tile(colour = "white", linewidth = 0.15) +
  ggplot2::facet_wrap(~sistema, ncol = 1, scales = "free_y") +
  ggplot2::scale_fill_viridis_c(
    option = "C", name = "Razão em relação\nà média do sistema"
  ) +
  ggplot2::labs(x = "Mês", y = "Ano") +
  theme_cellpress() +
  ggplot2::theme(
    panel.grid = ggplot2::element_blank(),
    axis.ticks = ggplot2::element_blank()
  )
metadata_3 <- save_publication_figure(
  figure_3, "FIG3_mapa_calor_sazonalidade_mensal",
  width = 7.5, height = 6.5
)

# FIG4: séries anuais -----------------------------------------------------
sih_annual <- read_table("indicadores_anuais_sih.csv")
sim_annual <- read_table("obitos_anuais_sim.csv")
annual_counts <- rbind(
  data.frame(
    ano = sih_annual$ano, eventos = sih_annual$internacoes,
    sistema = "A  SIH — internações"
  ),
  data.frame(
    ano = sim_annual$ano,
    eventos = sim_annual$obitos_causa_basica_cerebrovascular,
    sistema = "B  SIM — óbitos"
  )
)
figure_4 <- ggplot2::ggplot(
  annual_counts, ggplot2::aes(x = ano, y = eventos)
) +
  ggplot2::geom_line(colour = palette[["blue"]], linewidth = 0.75) +
  ggplot2::geom_point(
    colour = palette[["blue"]], fill = "white", shape = 21, size = 2
  ) +
  ggplot2::facet_wrap(~sistema, ncol = 1, scales = "free_y") +
  ggplot2::scale_x_continuous(breaks = seq(2010, 2025, 3)) +
  ggplot2::scale_y_continuous(
    labels = scales::label_number(big.mark = ".", decimal.mark = ",")
  ) +
  ggplot2::labs(x = "Ano", y = "Eventos") +
  theme_cellpress()
metadata_4 <- save_publication_figure(
  figure_4, "FIG4_series_anuais_sih_sim",
  width = 7.5, height = 5.5
)

# FIG5: padrões regionais, calculados separadamente por sistema -----------
regions <- utils::read.csv(
  project_path("config", "regioes_saude_rj.csv"),
  stringsAsFactors = FALSE, check.names = FALSE, fileEncoding = "UTF-8"
)
aggregate_region_rate <- function(data, event_column, system) {
  data <- merge(data, regions, by = "nome_municipio", all.x = TRUE)
  if (anyNA(data$regiao_saude)) {
    stop("Município sem região de saúde na série ", system, ".")
  }
  formula <- stats::as.formula(paste0(
    "cbind(", event_column, ", populacao) ~ ano + regiao_saude"
  ))
  out <- stats::aggregate(formula, data = data, FUN = sum, na.rm = TRUE)
  out$taxa <- safe_rate(out[[event_column]], out$populacao)
  out$sistema <- system
  out[c("ano", "regiao_saude", "taxa", "sistema")]
}
regional_long <- rbind(
  aggregate_region_rate(sih_rates, "internacoes", "SIH"),
  aggregate_region_rate(
    sim_rates, "obitos_causa_basica_cerebrovascular", "SIM"
  )
)
regional_template <- expand.grid(
  ano = 2010:2025,
  regiao_saude = unique(regional_long$regiao_saude),
  sistema = unique(regional_long$sistema),
  stringsAsFactors = FALSE
)
regional_long <- merge(
  regional_template, regional_long,
  by = c("ano", "regiao_saude", "sistema"), all.x = TRUE
)
figure_5 <- ggplot2::ggplot(
  regional_long,
  ggplot2::aes(x = ano, y = taxa, colour = sistema, linetype = sistema)
) +
  ggplot2::geom_line(linewidth = 0.65) +
  ggplot2::facet_wrap(~regiao_saude, ncol = 3, scales = "free_y") +
  ggplot2::scale_colour_manual(values = c(SIH = palette[["blue"]], SIM = palette[["orange"]])) +
  ggplot2::scale_linetype_manual(values = c(SIH = "solid", SIM = "22")) +
  ggplot2::scale_x_continuous(breaks = c(2010, 2017, 2024)) +
  ggplot2::labs(x = "Ano", y = "Taxa por 100 mil", colour = NULL, linetype = NULL) +
  theme_cellpress(base_size = 8)
metadata_5 <- save_publication_figure(
  figure_5, "FIG5_series_regioes_saude",
  width = 7.5, height = 7
)

# FIG6: mortalidade hospitalar por categoria -----------------------------
mortality <- read_table("mortalidade_hospitalar_por_categoria.csv")
display_variables <- c(
  sexo = "Sexo", faixa_etaria = "Faixa etária",
  raca_cor_rotulo = "Raça/cor", carater_rotulo = "Caráter",
  regiao_saude = "Região de saúde", subgrupo_cid = "CID-10"
)
mortality <- mortality[mortality$variavel %in% names(display_variables), ]
mortality$variavel_rotulo <- unname(display_variables[mortality$variavel])
mortality$categoria <- factor(
  mortality$categoria,
  levels = rev(unique(mortality$categoria[order(mortality$mortalidade_pct)]))
)
figure_6 <- ggplot2::ggplot(
  mortality,
  ggplot2::aes(x = mortalidade_pct, y = categoria)
) +
  ggplot2::geom_errorbar(
    ggplot2::aes(xmin = ic95_inferior_pct, xmax = ic95_superior_pct),
    width = 0, orientation = "y", colour = "#555555", linewidth = 0.45
  ) +
  ggplot2::geom_point(
    colour = palette[["blue"]], fill = "white", shape = 21, size = 2
  ) +
  ggplot2::facet_grid(
    variavel_rotulo ~ .,
    scales = "free_y", space = "free_y"
  ) +
  ggplot2::labs(x = "Mortalidade hospitalar (%) e IC95% de Wilson", y = NULL) +
  theme_cellpress(base_size = 8) +
  ggplot2::theme(strip.text.y = ggplot2::element_text(angle = 0))
metadata_6 <- save_publication_figure(
  figure_6, "FIG6_mortalidade_hospitalar_categorias",
  width = 7.5, height = 10
)

# FIG7: resíduos das associações -----------------------------------------
residuals <- read_table("residuos_padronizados_associacao_obito.csv")
residual_labels <- c(display_variables, periodo = "Período")
residuals$variavel_categoria <- paste(
  unname(residual_labels[residuals$variavel]), residuals$categoria,
  sep = ": "
)
residuals$desfecho <- ifelse(
  residuals$desfecho == "TRUE", "Óbito", "Não óbito"
)
figure_7 <- ggplot2::ggplot(
  residuals,
  ggplot2::aes(x = desfecho, y = variavel_categoria, fill = residuo_padronizado)
) +
  ggplot2::geom_tile(colour = "white", linewidth = 0.15) +
  ggplot2::scale_fill_gradient2(
    low = palette[["blue"]], mid = "white", high = palette[["vermillion"]],
    midpoint = 0, name = "Resíduo\npadronizado"
  ) +
  ggplot2::labs(x = NULL, y = NULL) +
  theme_cellpress(base_size = 7) +
  ggplot2::theme(axis.ticks = ggplot2::element_blank())
metadata_7 <- save_publication_figure(
  figure_7, "FIG7_residuos_associacao_obito",
  width = 7.5, height = 10
)

# FIG8: composição por subgrupo CID --------------------------------------
cid_sih <- read_table("cid_subgrupos_anuais_sih.csv")
cid_sim <- read_table("cid_subgrupos_anuais_sim.csv")
cid_long <- rbind(
  data.frame(
    ano = cid_sih$ano, cid = cid_sih$subgrupo_cid,
    eventos = cid_sih$internacoes, sistema = "A  SIH — internações"
  ),
  data.frame(
    ano = cid_sim$ano, cid = cid_sim$subgrupo_cid,
    eventos = cid_sim$obitos_causa_basica, sistema = "B  SIM — óbitos"
  )
)
figure_8 <- ggplot2::ggplot(
  cid_long, ggplot2::aes(x = factor(ano), y = cid, fill = eventos)
) +
  ggplot2::geom_tile(colour = "white", linewidth = 0.15) +
  ggplot2::facet_wrap(~sistema, ncol = 1) +
  ggplot2::scale_fill_viridis_c(
    option = "C", trans = "sqrt", name = "Eventos",
    breaks = c(0, 5000, 10000, 15000),
    labels = scales::label_number(big.mark = ".", decimal.mark = ","),
    guide = ggplot2::guide_colourbar(barwidth = grid::unit(65, "pt"))
  ) +
  ggplot2::labs(x = "Ano", y = "Subgrupo CID-10") +
  theme_cellpress(base_size = 8) +
  ggplot2::theme(
    axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
    axis.ticks = ggplot2::element_blank()
  )
metadata_8 <- save_publication_figure(
  figure_8, "FIG8_heatmap_subgrupos_cid",
  width = 7.5, height = 6
)

# FIG9: intensidade das associações --------------------------------------
associations <- read_table("associacao_obito_hospitalar.csv")
associations$variavel <- factor(
  associations$variavel,
  levels = associations$variavel[order(associations$cramer_v_corrigido)]
)
figure_9 <- ggplot2::ggplot(
  associations,
  ggplot2::aes(x = cramer_v_corrigido, y = variavel)
) +
  ggplot2::geom_segment(
    ggplot2::aes(x = 0, xend = cramer_v_corrigido, yend = variavel),
    colour = "#777777", linewidth = 0.45
  ) +
  ggplot2::geom_point(
    colour = palette[["vermillion"]], fill = "white", shape = 21, size = 2.5
  ) +
  ggplot2::labs(x = "V de Cramér corrigido", y = NULL) +
  theme_cellpress()
metadata_9 <- save_publication_figure(
  figure_9, "FIG9_tamanho_efeito_associacoes",
  width = 5.5, height = 4
)

metadata <- bind_figure_metadata(
  metadata_1, metadata_2, metadata_3, metadata_4, metadata_5,
  metadata_6, metadata_7, metadata_8, metadata_9
)
write_csv_safe(
  metadata,
  project_path("results", "audits", "auditoria_figuras_publicacao.csv")
)

captions <- data.frame(
  figura = paste0("FIG", 1:9),
  legenda = c(
    paste0(
      "Evolução municipal das taxas de internação por doenças cerebrovasculares ",
      "no SIH/SUS. A escala é comum entre painéis; 2023 usa população ",
      "municipal interpolada linearmente entre 2022 e 2024."
    ),
    paste0(
      "Evolução municipal das taxas de mortalidade por causa básica ",
      "cerebrovascular no SIM. A escala é comum entre painéis; 2023 usa ",
      "população municipal interpolada linearmente entre 2022 e 2024."
    ),
    paste0(
      "Distribuição mensal das internações SIH/SUS e óbitos SIM por ",
      "ano-calendário. Cores representam a razão entre a contagem mensal e a ",
      "média do respectivo sistema, permitindo comparar padrões sem confundir ",
      "as escalas distintas."
    ),
    "Séries anuais de internações SIH/SUS e óbitos por causa básica no SIM. Os sistemas representam eventos distintos.",
    paste0(
      "Taxas anuais de internação SIH/SUS e mortalidade SIM segundo região ",
      "de saúde de residência, calculadas separadamente para cada sistema."
    ),
    paste0(
      "Mortalidade hospitalar no SIH/SUS por características selecionadas. ",
      "Pontos são proporções e barras são intervalos de 95% de Wilson."
    ),
    paste0(
      "Resíduos padronizados dos testes de associação com óbito hospitalar. ",
      "Valores positivos indicam frequência observada acima da esperada sob ",
      "independência."
    ),
    paste0(
      "Distribuição anual dos eventos segundo subgrupo CID-10 I60-I69 no ",
      "SIH/SUS e SIM. Escala de cor transformada pela raiz quadrada."
    ),
    paste0(
      "Magnitude das associações entre características categóricas e óbito ",
      "hospitalar, expressa pelo V de Cramér corrigido."
    )
  ),
  stringsAsFactors = FALSE
)
write_csv_safe(
  captions,
  project_path("results", "figures", "publication", "legendas_figuras.csv")
)
log_event(
  "INFO", "publication_figures_complete",
  "Nove figuras de publicação geradas em PNG, TIFF e PDF",
  list(files = nrow(metadata), municipalities = nrow(municipalities))
)
record_session_info(
  project_path("results", "logs", "figures-session-info.txt")
)
