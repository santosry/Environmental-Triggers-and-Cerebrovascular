options(repos = c(CRAN = "https://cloud.r-project.org"))
required <- c(
  "arrow", "data.table", "dplyr", "dunn.test", "fs", "geobr", "ggplot2",
  "here", "jsonlite", "Kendall", "knitr", "lintr", "microbenchmark",
  "microdatasus", "rmarkdown", "readr", "renv", "sessioninfo", "sf",
  "sidrar", "styler", "testthat", "yaml"
)
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) install.packages(missing)
message("Dependências disponíveis: ", paste(required, collapse = ", "))
if (requireNamespace("renv", quietly = TRUE) && file.exists("renv.lock")) renv::restore(prompt = FALSE)
