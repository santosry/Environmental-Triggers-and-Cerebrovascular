# 00_migrar_2014_2024.R
# Migração da janela de estudo de 2010-2024 para 2014-2024.
#
# Os recortes e a coorte de 2010-2024 são superconjuntos; como todas as
# variáveis são de nível de registro (linha), a restrição a 2014-2024 é obtida
# por filtro temporal, produzindo exatamente o mesmo conteúdo que os scripts
# 01 e 02 geram quando o período é fixado em 2014-2024.
#
# As colunas de data são lidas como texto e normalizadas para 8 dígitos, para
# não perder os zeros à esquerda (ex.: DTOBITO "03032010").
#
# Entradas:  sih_cid_estudo_2010_2024.csv, sim_cid_estudo_2010_2024.csv,
#            coorte_glmm_2010_2024.csv
# Saídas:    sih_cid_estudo_2014_2024.csv, sim_cid_estudo_2014_2024.csv,
#            coorte_glmm_2014_2024.csv

suppressWarnings({
  library(data.table)
  PROC <- file.path(normalizePath("."), "01_dados", "processados")
  ANO_INI <- 2014L; ANO_FIM <- 2024L
  D0 <- as.Date("2014-01-01"); D1 <- as.Date("2024-12-31")

  mig_data <- function(entrada, saida, date_col, fmt) {
    p_in <- file.path(PROC, entrada); p_out <- file.path(PROC, saida)
    if (!file.exists(p_in)) { cat("ausente:", entrada, "\n"); return(invisible()) }
    d <- fread(p_in, encoding = "UTF-8", na.strings = c("NA", ""), colClasses = "character")
    n0 <- nrow(d)
    x <- trimws(as.character(d[[date_col]]))
    if (fmt == "%d%m%Y") x <- sprintf("%08s", x)   # DTOBITO: DDMMYYYY
    dt <- suppressWarnings(as.Date(x, format = fmt))
    d <- d[!is.na(dt) & dt >= D0 & dt <= D1]
    fwrite(d, p_out, encoding = "UTF-8", na = "NA")
    cat(sprintf("  %-36s %9s -> %9s linhas\n", saida,
                format(n0, big.mark = "."), format(nrow(d), big.mark = ".")))
  }

  mig_ano <- function(entrada, saida) {
    p_in <- file.path(PROC, entrada); p_out <- file.path(PROC, saida)
    if (!file.exists(p_in)) { cat("ausente:", entrada, "\n"); return(invisible()) }
    d <- fread(p_in, encoding = "UTF-8", na.strings = c("NA", ""))
    n0 <- nrow(d); a <- as.integer(d$ano)
    d <- d[!is.na(a) & a >= ANO_INI & a <= ANO_FIM]
    fwrite(d, p_out, encoding = "UTF-8", na = "NA")
    cat(sprintf("  %-36s %9s -> %9s linhas\n", saida,
                format(n0, big.mark = "."), format(nrow(d), big.mark = ".")))
  }

  mig_data("sih_cid_estudo_2010_2024.csv", "sih_cid_estudo_2014_2024.csv", "DT_INTER", "%Y%m%d")
  mig_data("sim_cid_estudo_2010_2024.csv", "sim_cid_estudo_2014_2024.csv", "DTOBITO", "%d%m%Y")
  mig_ano("coorte_glmm_2010_2024.csv", "coorte_glmm_2014_2024.csv")
})
