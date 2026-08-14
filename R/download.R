# Download controlado e disponibilidade ----------------------------------

fetch_datasus_checked <- function(year_start, year_end = year_start,
                                  month_start = NULL, month_end = NULL,
                                  uf = "RJ", information_system,
                                  attempts = 3L, wait_seconds = 10,
                                  timeout = 600) {
  if (!requireNamespace("microdatasus", quietly = TRUE)) stop("Pacote microdatasus ausente.")
  label <- sprintf("%s %s %s-%s", information_system, uf, year_start, year_end)
  result <- with_retries(
    function() {
      data <- microdatasus::fetch_datasus(
        year_start = year_start, month_start = month_start,
        year_end = year_end, month_end = month_end, uf = uf,
        information_system = information_system, stop_on_error = FALSE,
        timeout = timeout, track_source = TRUE
      )
      if (is.null(data) || !is.data.frame(data) || nrow(data) == 0L) {
        stop("DATASUS retornou resposta vazia para ", label, call. = FALSE)
      }
      data
    },
    attempts = attempts, wait_seconds = wait_seconds, label = label
  )
  result
}

ftp_listing <- function(url, timeout = 60) {
  if (!requireNamespace("RCurl", quietly = TRUE)) stop("Pacote RCurl ausente.")
  text <- RCurl::getURL(url,
    ftp.use.epsv = TRUE, dirlistonly = TRUE,
    .opts = list(timeout = timeout)
  )
  trimws(unlist(strsplit(text, "\n", fixed = TRUE)))
}

sim_availability <- function(years, uf = "RJ") {
  definitive_url <- "ftp://ftp.datasus.gov.br/dissemin/publicos/SIM/CID10/DORES/"
  preliminary_url <- "ftp://ftp.datasus.gov.br/dissemin/publicos/SIM/PRELIM/DORES/"
  definitive <- tryCatch(ftp_listing(definitive_url), error = function(e) character())
  preliminary <- tryCatch(ftp_listing(preliminary_url), error = function(e) character())
  definitive_years <- as.integer(sub(
    sprintf("^DO%s([0-9]{4})[.]DBC$", uf), "\\1",
    toupper(definitive[grepl(sprintf("^DO%s[0-9]{4}[.]DBC$", uf), toupper(definitive))])
  ))
  preliminary_years <- as.integer(sub(
    sprintf("^DO%s([0-9]{4})[.]DBC$", uf), "\\1",
    toupper(preliminary[grepl(sprintf("^DO%s[0-9]{4}[.]DBC$", uf), toupper(preliminary))])
  ))
  status <- ifelse(years %in% definitive_years, "definitivo",
    ifelse(years %in% preliminary_years, "preliminar", "indisponivel")
  )
  data.frame(
    year = as.integer(years), uf = uf, status = status,
    checked_at_utc = timestamp_utc(), stringsAsFactors = FALSE
  )
}

sih_availability <- function(years, months = 1:12, uf = "RJ") {
  url <- "ftp://ftp.datasus.gov.br/dissemin/publicos/SIHSUS/200801_/Dados/"
  listing <- toupper(tryCatch(ftp_listing(url), error = function(e) character()))
  grid <- expand.grid(year = as.integer(years), month = as.integer(months))
  grid$filename <- sprintf("RD%s%02d%02d.DBC", uf, grid$year %% 100, grid$month)
  grid$status <- ifelse(grid$filename %in% listing, "disponivel", "indisponivel")
  grid$checked_at_utc <- timestamp_utc()
  grid
}
