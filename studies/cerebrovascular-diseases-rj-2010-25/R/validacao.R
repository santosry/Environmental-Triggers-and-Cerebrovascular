# Validação e coerção ------------------------------------------------------

validate_year_range <- function(year_start, year_end, lower = 1996L,
                                upper = as.integer(format(Sys.Date(), "%Y"))) {
  years <- as.integer(c(year_start, year_end))
  invalid <- anyNA(years) ||
    length(years) != 2L ||
    years[1] > years[2] ||
    years[1] < lower ||
    years[2] > upper
  if (invalid) {
    stop("Intervalo de anos inválido.")
  }
  seq.int(years[1], years[2])
}

validate_month <- function(x) {
  x <- suppressWarnings(as.integer(x))
  !is.na(x) & x >= 1L & x <= 12L
}

validate_dates <- function(x) {
  parsed <- suppressWarnings(as.Date(x))
  data.frame(
    value = as.character(x), parsed = parsed,
    valid = is.na(x) | !is.na(parsed), stringsAsFactors = FALSE
  )
}

convert_types <- function(data, integer = character(), numeric = character(),
                          character = character(), date = character()) {
  present <- function(x) intersect(x, names(data))
  for (nm in present(integer)) data[[nm]] <- suppressWarnings(as.integer(data[[nm]]))
  for (nm in present(numeric)) data[[nm]] <- suppressWarnings(as.numeric(data[[nm]]))
  for (nm in present(character)) data[[nm]] <- as.character(data[[nm]])
  for (nm in present(date)) data[[nm]] <- suppressWarnings(as.Date(data[[nm]]))
  data
}

duplicate_flags <- function(data, keys = NULL) {
  exact <- duplicated(data) | duplicated(data, fromLast = TRUE)
  potential <- rep(FALSE, nrow(data))
  if (!is.null(keys)) {
    missing <- setdiff(keys, names(data))
    if (length(missing)) stop("Chaves ausentes: ", paste(missing, collapse = ", "))
    key_data <- data[keys]
    potential <- duplicated(key_data) | duplicated(key_data, fromLast = TRUE)
  }
  data.frame(exact = exact, potential = potential)
}

missingness <- function(data) {
  data.frame(
    variable = names(data), n_missing = vapply(data, function(x) sum(is.na(x)), integer(1)),
    proportion_missing = vapply(data, function(x) mean(is.na(x)), numeric(1)),
    stringsAsFactors = FALSE
  )
}

check_impossible_values <- function(data, age = NULL, days = NULL, cost = NULL,
                                    max_age = 120, max_days = 3650) {
  out <- list()
  if (!is.null(age) && age %in% names(data)) {
    out$age <- which(
      !is.na(data[[age]]) & (data[[age]] < 0 | data[[age]] > max_age)
    )
  }
  if (!is.null(days) && days %in% names(data)) {
    out$days <- which(
      !is.na(data[[days]]) & (data[[days]] < 0 | data[[days]] > max_days)
    )
  }
  if (!is.null(cost) && cost %in% names(data)) out$cost_negative <- which(!is.na(data[[cost]]) & data[[cost]] < 0)
  out
}

validate_municipality_code <- function(x, uf_prefix = "33") {
  x <- gsub("[^0-9]", "", as.character(x))
  nchar(x) %in% c(6L, 7L) & startsWith(x, uf_prefix)
}

normalize_municipality_code <- function(x) substr(gsub("[^0-9]", "", as.character(x)), 1L, 6L)

validate_required_columns <- function(data, required, dataset) {
  missing <- setdiff(required, names(data))
  if (length(missing)) stop(dataset, " sem colunas obrigatórias: ", paste(missing, collapse = ", "))
  invisible(TRUE)
}
