# Processamento de SIH e SIM ----------------------------------------------

first_existing <- function(data, candidates, required = TRUE, label = NULL) {
  hit <- intersect(candidates, names(data))
  if (length(hit)) {
    return(hit[[1]])
  }
  if (required) stop("Nenhuma coluna encontrada para ", label %||% paste(candidates, collapse = "/"))
  NULL
}

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0L) y else x

copy_alias <- function(data, target, candidates, transform = identity, required = FALSE) {
  source <- first_existing(data, candidates, required = required, label = target)
  if (!is.null(source)) data[[target]] <- transform(data[[source]])
  data
}

process_sih_extract <- function(raw) {
  if (!requireNamespace("microdatasus", quietly = TRUE)) stop("Pacote microdatasus ausente.")
  # microdatasus 2.5.0 consulta tabelas LazyData (por exemplo, tabCBO)
  # pelo search path; anexar o pacote evita o erro "tabCBO não encontrado".
  suppressPackageStartupMessages(require("microdatasus", character.only = TRUE))
  processed <- microdatasus::process_sih(raw, information_system = "SIH-RD", municipality_data = FALSE)
  processed <- copy_alias(processed, "ano", c("ANO_CMPT"), as.integer, TRUE)
  processed <- copy_alias(processed, "mes", c("MES_CMPT"), as.integer, TRUE)
  processed <- copy_alias(processed, "municipio_residencia", c("MUNIC_RES"), normalize_municipality_code)
  processed <- copy_alias(processed, "municipio_internacao", c("MUNIC_MOV", "MUNICIPIO"), normalize_municipality_code)
  processed <- copy_alias(processed, "sexo", c("SEXO"), as.character)
  processed <- copy_alias(processed, "idade_anos", c("IDADE"), as.numeric)
  processed <- copy_alias(processed, "raca_cor", c("RACA_COR"), as.character)
  processed <- copy_alias(processed, "diagnostico_principal", c("DIAG_PRINC"), normalize_cid10, TRUE)
  processed <- copy_alias(processed, "diagnostico_secundario", c("DIAG_SECUN", "DIAGSEC1"), normalize_cid10)
  processed <- copy_alias(processed, "dias_permanencia", c("DIAS_PERM"), as.numeric)
  processed <- copy_alias(processed, "valor_internacao", c("VAL_TOT"), as.numeric)
  processed <- copy_alias(processed, "carater_atendimento", c("CAR_INT"), as.character)
  processed <- copy_alias(processed, "obito_hospitalar", c("MORTE"), function(x) {
    y <- toupper(as.character(x))
    y %in% c("1", "SIM", "OBITO", "ÓBITO")
  })
  processed
}

process_sim_extract <- function(raw) {
  if (!requireNamespace("microdatasus", quietly = TRUE)) stop("Pacote microdatasus ausente.")
  suppressPackageStartupMessages(require("microdatasus", character.only = TRUE))
  # microdatasus 2.5.0 associa NATURAL a uma tabela que contém três códigos
  # duplicados. O left join pode multiplicar declarações de óbito. Preservamos o
  # código original e impedimos essa associação; as demais transformações do
  # pacote continuam sendo aplicadas.
  natural_raw <- if ("NATURAL" %in% names(raw)) raw$NATURAL else NULL
  raw_for_processing <- raw
  raw_for_processing$NATURAL <- NULL
  processed <- microdatasus::process_sim(
    raw_for_processing,
    municipality_data = FALSE
  )
  if (!is.null(natural_raw)) processed$NATURAL <- natural_raw
  if (nrow(processed) != nrow(raw)) {
    stop(
      "process_sim alterou a cardinalidade: ", nrow(raw), " -> ",
      nrow(processed), "."
    )
  }
  processed <- copy_alias(processed, "data_obito", c("DTOBITO"), as.Date, TRUE)
  processed$ano <- as.integer(format(processed$data_obito, "%Y"))
  processed$mes <- as.integer(format(processed$data_obito, "%m"))
  processed <- copy_alias(processed, "municipio_residencia", c("CODMUNRES"), normalize_municipality_code)
  processed <- copy_alias(processed, "municipio_ocorrencia", c("CODMUNOCOR"), normalize_municipality_code)
  processed <- copy_alias(processed, "sexo", c("SEXO"), as.character)
  processed <- copy_alias(processed, "idade_anos", c("IDADEanos", "IDADE"), as.numeric)
  processed <- copy_alias(processed, "raca_cor", c("RACACOR"), as.character)
  processed <- copy_alias(processed, "escolaridade", c("ESC2010", "ESC"), as.character)
  processed <- copy_alias(processed, "estado_civil", c("ESTCIV"), as.character)
  processed <- copy_alias(processed, "causa_basica", c("CAUSABAS"), normalize_cid10, TRUE)
  processed <- copy_alias(
    processed, "causas_associadas",
    c("LINHAA", "LINHAB", "LINHAC", "LINHAD", "LINHAII"),
    as.character
  )
  processed <- copy_alias(processed, "local_ocorrencia", c("LOCOCOR"), as.character)
  processed
}

select_preserving_available <- function(data, preferred) {
  data[, unique(c(intersect(preferred, names(data)), names(data))), drop = FALSE]
}
