# Auditorias de dados ------------------------------------------------------

count_periods <- function(data, year, month = NULL) {
  validate_required_columns(data, c(year, month)[!is.null(c(year, month))], "base")
  cols <- if (is.null(month)) year else c(year, month)
  out <- aggregate(rep(1L, nrow(data)), data[cols], length)
  names(out)[ncol(out)] <- "n"
  out[do.call(order, out[cols]), , drop = FALSE]
}

missing_periods <- function(data, year, month = NULL, expected_years) {
  if (is.null(month)) {
    return(setdiff(expected_years, unique(data[[year]])))
  }
  expected <- expand.grid(year = expected_years, month = 1:12)
  observed <- unique(data.frame(year = data[[year]], month = data[[month]]))
  expected_key <- paste(expected$year, expected$month, sep = "-")
  observed_key <- paste(observed$year, observed$month, sep = "-")
  expected[!expected_key %in% observed_key, , drop = FALSE]
}

detect_temporal_breaks <- function(counts, value = "n", threshold = 0.30) {
  x <- counts[[value]]
  previous <- c(NA_real_, head(x, -1L))
  change <- ifelse(previous == 0, NA_real_, (x - previous) / previous)
  transform(counts,
    previous = previous, proportional_change = change,
    abrupt = !is.na(change) & abs(change) >= threshold
  )
}

compare_stage_totals <- function(...) {
  stages <- list(...)
  data.frame(
    stage = names(stages), n = vapply(stages, nrow, integer(1)),
    excluded_from_previous = c(NA_integer_, -diff(vapply(stages, nrow, integer(1)))),
    stringsAsFactors = FALSE
  )
}

audit_dataset <- function(data, dataset, year, month = NULL, cid = NULL,
                          age = NULL, sex = NULL, race = NULL, municipality = NULL,
                          date = NULL, days = NULL, cost = NULL, keys = NULL,
                          expected_years = NULL, output_dir = project_path("results", "audits")) {
  ensure_dir(output_dir)
  periods <- count_periods(data, year, month)
  dup <- duplicate_flags(data, keys)
  miss <- missingness(data)
  impossible <- check_impossible_values(data, age, days, cost)
  invalid_cid <- if (is.null(cid) || !cid %in% names(data)) {
    NA_integer_
  } else {
    sum(
      !grepl("^[A-Z][0-9]{2}[A-Z0-9]{0,4}$", normalize_cid10(data[[cid]])) &
        !is.na(data[[cid]])
    )
  }
  invalid_dates <- if (is.null(date) || !date %in% names(data)) {
    NA_integer_
  } else {
    sum(!validate_dates(data[[date]])$valid)
  }
  invalid_municipalities <- if (is.null(municipality) || !municipality %in% names(data)) {
    NA_integer_
  } else {
    sum(
      !validate_municipality_code(data[[municipality]]) &
        !is.na(data[[municipality]])
    )
  }
  summary <- data.frame(
    dataset = dataset, n_records = nrow(data), n_variables = ncol(data),
    exact_duplicates = sum(dup$exact), potential_duplicates = sum(dup$potential),
    invalid_cid = invalid_cid,
    invalid_dates = invalid_dates,
    outside_expected_uf = invalid_municipalities,
    stringsAsFactors = FALSE
  )
  write_csv_safe(summary, file.path(output_dir, paste0(dataset, "_resumo.csv")))
  write_csv_safe(periods, file.path(output_dir, paste0(dataset, "_periodos.csv")))
  write_csv_safe(miss, file.path(output_dir, paste0(dataset, "_ausencia.csv")))
  if (!is.null(expected_years)) {
    absent <- missing_periods(data, year, month, expected_years)
    write_csv_safe(as.data.frame(absent), file.path(output_dir, paste0(dataset, "_periodos_ausentes.csv")))
  }
  log_event("INFO", "audit_complete", paste("Auditoria concluída:", dataset), as.list(summary[1, ]))
  invisible(list(
    summary = summary, periods = periods, missingness = miss,
    duplicates = dup, impossible = impossible
  ))
}
