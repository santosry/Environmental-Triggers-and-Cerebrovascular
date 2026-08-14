# Gráficos ----------------------------------------------------------------

plot_time_series <- function(data, x, y, title, y_label = NULL) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) stop("Pacote 'ggplot2' não instalado.")
  ggplot2::ggplot(data, ggplot2::aes(x = .data[[x]], y = .data[[y]])) +
    ggplot2::geom_line(linewidth = 0.8, colour = "#176B87") +
    ggplot2::geom_point(size = 1.8, colour = "#176B87") +
    ggplot2::labs(title = title, x = NULL, y = y_label) +
    ggplot2::theme_minimal(base_size = 11)
}

save_figure <- function(plot, filename, width = 8, height = 5, dpi = 300) {
  path <- project_path("results", "figures", filename)
  ensure_dir(dirname(path))
  ggplot2::ggsave(path, plot = plot, width = width, height = height, dpi = dpi)
  invisible(path)
}
