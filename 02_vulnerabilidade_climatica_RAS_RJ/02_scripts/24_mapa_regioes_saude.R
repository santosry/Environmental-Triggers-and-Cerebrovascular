# 24_mapa_regioes_saude.R
# Mapas coropleticos das nove regioes de saude do Rio de Janeiro, com malha
# municipal do geobr dissolvida por regiao de saude.
#
# Indicadores mapeados (2024):
#   - taxa de internacao por DCV (I60 a I69) por 100.000 habitantes (SIH);
#   - taxa de mortalidade por DCV (causa basica I60 a I69 e G45/G46) por 100.000 (SIM).
# A Figura 1 do manuscrito combina a serie temporal (painel A) e o mapa da taxa de
# internacao 2024 (painel B).
#
# Entradas: geobr (malha RJ), lookup municipio->regiao, populacao SIDRA,
#           coorte_glmm_2010_2024.csv, sim_cid_estudo_2010_2024.csv.
# Saidas:   06_figuras/exploratorias/fig_ex28_mapa_internacao.png
#           06_figuras/exploratorias/fig_ex29_mapa_mortalidade.png
#           06_figuras/manuscrito/figura1_taxa_internacao_mapa.jpg
#           04_resultados/resultados_mapa_regioes.txt

suppressWarnings({
  options(stringsAsFactors = FALSE)
  library(data.table)
  library(ggplot2)
  library(viridisLite)
  library(geobr)
  library(sf)
  library(dplyr)
  library(patchwork)
  library(ragg)

  ROOT <- local({
    d <- normalizePath(".")
    for (i in 1:6) {
      if (dir.exists(file.path(d, "01_dados")) && dir.exists(file.path(d, "02_scripts"))) break
      sub <- file.path(d, "02_vulnerabilidade_climatica_RAS_RJ")
      if (dir.exists(file.path(sub, "01_dados"))) { d <- sub; break }
      pai <- dirname(d); if (pai == d) break; d <- pai
    }
    d
  })
  PROC <- file.path(ROOT, "01_dados", "processados")
  TAB <- file.path(ROOT, "05_tabelas")
  RES <- file.path(ROOT, "04_resultados")
  FIG_EX <- file.path(ROOT, "06_figuras", "exploratorias")
  FIG_MAN <- file.path(ROOT, "06_figuras", "manuscrito")
  DLNM <- file.path(dirname(ROOT), "01_DLNMs_RJ_cerebrovascular", "data_processed")
  dir.create(FIG_EX, showWarnings = FALSE, recursive = TRUE)
  dir.create(FIG_MAN, showWarnings = FALSE, recursive = TRUE)

  logcon <- file(file.path(RES, "resultados_mapa_regioes.txt"), open = "wt", encoding = "UTF-8")
  say <- function(...) { m <- paste0(...); cat(m, "\n"); writeLines(m, logcon); flush(logcon) }

  say("MAPAS POR REGIAO DE SAUDE | inicio: ", format(Sys.time()))

  ## ---------------- malha municipal -> regiao de saude ----------------
  malha <- read_municipality(code_muni = "RJ", year = 2020, showProgress = FALSE)
  malha$ibge6 <- sprintf("%06s", substr(as.character(malha$code_muni), 1, 6))

  lk <- fread(file.path(DLNM, "lookup_municipio_macrorregiao.csv"),
              colClasses = "character", encoding = "UTF-8")
  lk[, ibge6 := sprintf("%06s", ibge6)]
  malha <- left_join(malha, as.data.frame(lk[, .(ibge6, regiao_saude = macro_regiao)]),
                     by = "ibge6")
  say("municipios na malha: ", nrow(malha),
      " | sem regiao: ", sum(is.na(malha$regiao_saude)))
  reg <- malha[!is.na(malha$regiao_saude), ] |>
    group_by(regiao_saude) |>
    summarise(geometry = st_union(geometry), .groups = "drop")
  reg <- st_make_valid(reg)

  ## ---------------- indicadores 2024 ----------------
  pop <- fread(file.path(DLNM, "populacao_sidra_municipio_rj_2010-2025.csv"), encoding = "UTF-8")
  pop[, ano := as.integer(ano)][, populacao := as.numeric(populacao)]
  pop[, ibge6 := sprintf("%06s", as.character(ibge6))]
  pop <- merge(pop, lk[, .(ibge6, regiao_saude = macro_regiao)], by = "ibge6", all.x = TRUE)
  pop24 <- pop[ano == 2024, .(pop = sum(populacao, na.rm = TRUE)), by = regiao_saude]

  co <- fread(file.path(PROC, "coorte_glmm_2010_2024.csv"), encoding = "UTF-8",
              na.strings = c("NA", ""), select = c("ano", "regiao_saude", "coorte"))
  co <- co[coorte == "I60-I69" & ano == 2024, .(int = .N), by = regiao_saude]

  sim <- fread(file.path(PROC, "sim_cid_estudo_2010_2024.csv"), encoding = "UTF-8",
               colClasses = "character", na.strings = c("NA", ""))
  sim[, ano := as.integer(substr(DTOBITO, 5, 8))]
  sim <- merge(sim, lk[, .(ibge6, regiao_saude = macro_regiao)],
               by.x = "CODMUNRES", by.y = "ibge6", all.x = TRUE, sort = FALSE)
  sim24 <- sim[ano == 2024 & !is.na(regiao_saude), .(ob = .N), by = regiao_saude]

  ind <- reg |>
    left_join(as.data.frame(pop24), by = "regiao_saude") |>
    left_join(as.data.frame(co), by = "regiao_saude") |>
    left_join(as.data.frame(sim24), by = "regiao_saude")
  ind$int[is.na(ind$int)] <- 0L
  ind$ob[is.na(ind$ob)] <- 0L
  ind$taxa_int <- 1e5 * ind$int / ind$pop
  ind$taxa_mor <- 1e5 * ind$ob / ind$pop
  ind$rotulo <- gsub(" ", "\n", ind$regiao_saude)
  cen <- st_point_on_surface(ind)

  say("indicadores 2024 por regiao:")
  il <- as.data.table(st_drop_geometry(ind))
  for (i in seq_len(nrow(il)))
    say(sprintf("  %-20s pop=%9s | int=%6d (%.1f/100k) | ob=%6d (%.1f/100k)",
                il$regiao_saude[i], format(round(il$pop[i]), big.mark = "."),
                il$int[i], il$taxa_int[i], il$ob[i], il$taxa_mor[i]))

  ## ---------------- mapas ----------------
  mapa <- function(var, titulo, subtitulo, nome) {
    g <- ggplot(ind) +
      geom_sf(aes(fill = .data[[var]]), colour = "white", linewidth = 0.3) +
      geom_sf_text(data = cen, aes(label = rotulo), size = 2.3, colour = "grey15",
                   lineheight = 0.85) +
      scale_fill_viridis_c(option = "D", name = NULL,
                           labels = function(x) format(x, big.mark = ".")) +
      labs(title = titulo, subtitle = subtitulo) +
      theme_void(base_size = 11) +
      theme(plot.title = element_text(face = "bold"),
            plot.subtitle = element_text(size = 8.5),
            plot.margin = margin(4, 4, 4, 4))
    ggsave(file.path(FIG_EX, nome), g, width = 8, height = 6, dpi = 300,
           device = ragg::agg_png)
    g
  }
  g_int <- mapa("taxa_int", "Taxa de internação por DCV em 2024",
                "Por 100.000 habitantes (I60 a I69), por região de saúde do Rio de Janeiro",
                "fig_ex28_mapa_internacao.png")
  g_mor <- mapa("taxa_mor", "Taxa de mortalidade por DCV em 2024",
                "Por 100.000 habitantes (SIM, I60 a I69 e G45/G46), por região de saúde",
                "fig_ex29_mapa_mortalidade.png")

  ## ---------------- Figura 1 do manuscrito (serie + mapa) ----------------
  # serie temporal estadual
  pop_est <- pop[ano <= 2024, .(pop = sum(populacao, na.rm = TRUE)), by = ano]
  co2 <- fread(file.path(PROC, "coorte_glmm_2010_2024.csv"), encoding = "UTF-8",
               na.strings = c("NA", ""), select = c("ano", "coorte", "obito_hospitalar"))
  co2[, ano := as.integer(ano)]
  n_est <- co2[coorte == "I60-I69", .(n = .N, obitos = sum(obito_hospitalar)), by = ano]
  tx <- merge(n_est, pop_est, by = "ano"); tx[, taxa := 1e5 * n / pop]
  tx[, letal := 100 * obitos / n]
  painelA <- ggplot(tx, aes(ano)) +
    geom_line(aes(y = taxa, colour = "Internações/100 mil"), linewidth = 0.9) +
    geom_point(aes(y = taxa, colour = "Internações/100 mil"), size = 2) +
    geom_line(aes(y = letal * 3, colour = "% óbito hospitalar"), linewidth = 0.9, linetype = 2) +
    geom_point(aes(y = letal * 3, colour = "% óbito hospitalar"), size = 2, shape = 17) +
    scale_y_continuous(name = "Internações por 100.000",
                       sec.axis = sec_axis(~ . / 3, name = "% óbito hospitalar")) +
    scale_colour_viridis_d(option = "D", end = 0.85) +
    labs(title = "A. Internação e letalidade hospitalar por DCV, 2010-2024",
         x = NULL, colour = NULL) +
    theme_minimal(base_size = 10) +
    theme(legend.position = "top", plot.title = element_text(face = "bold"))

  painelB <- g_int + labs(title = "B. Taxa de internação por DCV em 2024")
  fig1 <- painelA / painelB
  ggsave(file.path(FIG_MAN, "figura1_taxa_internacao_mapa.jpg"), fig1,
         width = 8.5, height = 11, dpi = 300, device = ragg::agg_jpeg, quality = 95)
  say("gravada figura1_taxa_internacao_mapa.jpg (serie + mapa)")
  say("fim: ", format(Sys.time()))
  close(logcon)
})
