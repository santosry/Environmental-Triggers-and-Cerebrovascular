# Tabelas -----------------------------------------------------------------

frequency_table <- function(data, variable) {
  if (!variable %in% names(data)) stop("Variável ausente: ", variable)
  x <- as.character(data[[variable]])
  x[is.na(x) | x == ""] <- "Ignorado/ausente"
  n <- sort(table(x), decreasing = TRUE)
  data.frame(category = names(n), n = as.integer(n), proportion = as.integer(n) / sum(n))
}

save_table <- function(data, filename) write_csv_safe(data, project_path("results", "tables", filename))
