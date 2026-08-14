# Figuras para publicação -------------------------------------------------

publication_palette <- function() {
  c(
    blue = "#0072B2", orange = "#E69F00", green = "#009E73",
    vermillion = "#D55E00", purple = "#CC79A7", sky = "#56B4E9",
    yellow = "#F0E442", black = "#000000"
  )
}

theme_cellpress <- function(base_size = 9, base_family = "sans") {
  ggplot2::theme_classic(base_size = base_size, base_family = base_family) +
    ggplot2::theme(
      axis.text = ggplot2::element_text(colour = "#222222"),
      axis.title = ggplot2::element_text(colour = "#222222"),
      strip.background = ggplot2::element_blank(),
      strip.text = ggplot2::element_text(face = "bold", colour = "#222222"),
      legend.position = "bottom",
      legend.title = ggplot2::element_text(face = "bold"),
      panel.spacing = grid::unit(5, "pt"),
      plot.margin = ggplot2::margin(5, 5, 5, 5)
    )
}

save_publication_figure <- function(plot, stem, width = 7.5, height = 5,
                                    dpi = 500) {
  directory <- project_path("results", "figures", "publication")
  ensure_dir(directory)
  paths <- c(
    png = file.path(directory, paste0(stem, ".png")),
    tiff = file.path(directory, paste0(stem, ".tiff")),
    pdf = file.path(directory, paste0(stem, ".pdf"))
  )
  ggplot2::ggsave(
    paths[["png"]], plot,
    width = width, height = height, dpi = dpi,
    units = "in", bg = "white"
  )
  ggplot2::ggsave(
    paths[["tiff"]], plot,
    width = width, height = height, dpi = dpi,
    units = "in", bg = "white", compression = "lzw"
  )
  ggplot2::ggsave(
    paths[["pdf"]], plot,
    width = width, height = height,
    units = "in", bg = "white", device = grDevices::cairo_pdf
  )
  metadata <- do.call(rbind, lapply(names(paths), function(format) {
    info <- file.info(paths[[format]])
    data.frame(
      figura = stem, formato = format, caminho = paths[[format]],
      largura_pol = width, altura_pol = height,
      dpi = if (format == "pdf") NA_integer_ else dpi,
      espaco_cor = if (format == "pdf") "vetorial/RGB" else "RGB",
      bytes = unname(info$size), md5 = unname(tools::md5sum(paths[[format]]))
    )
  }))
  metadata
}

map_evolution_plot <- function(geometry, rates, title_label) {
  rates$municipio <- normalize_municipality_code(rates$municipio)
  geometry$municipio <- normalize_municipality_code(geometry$code_muni)
  map_data <- merge(geometry, rates, by = "municipio", all.y = TRUE)
  upper <- stats::quantile(map_data$taxa_100mil, 0.98, na.rm = TRUE)
  ggplot2::ggplot(map_data) +
    ggplot2::geom_sf(
      ggplot2::aes(fill = taxa_100mil),
      colour = "#FFFFFF", linewidth = 0.08
    ) +
    ggplot2::facet_wrap(~ano, ncol = 4) +
    ggplot2::scale_fill_viridis_c(
      option = "C", limits = c(0, upper), oob = scales::squish,
      na.value = "#D9D9D9", name = "Taxa por\n100 mil"
    ) +
    ggplot2::coord_sf(datum = NA) +
    ggplot2::labs(title = title_label) +
    theme_cellpress(base_size = 8) +
    ggplot2::theme(
      axis.line = ggplot2::element_blank(), axis.text = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank(), axis.title = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(face = "bold", size = 10),
      legend.key.height = grid::unit(8, "pt"),
      panel.border = ggplot2::element_rect(
        colour = "#B0B0B0", fill = NA, linewidth = 0.25
      )
    )
}

monthly_heatmap_plot <- function(data) {
  ggplot2::ggplot(data, ggplot2::aes(x = factor(mes), y = factor(ano), fill = eventos)) +
    ggplot2::geom_tile(colour = "white", linewidth = 0.15) +
    ggplot2::facet_wrap(~sistema, ncol = 1, scales = "free_y") +
    ggplot2::scale_fill_viridis_c(option = "C", name = "Eventos") +
    ggplot2::labs(x = "Mês", y = "Ano") +
    theme_cellpress() +
    ggplot2::theme(
      panel.grid = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank()
    )
}
