# 20_baixar_cnes_sia.R
# Download dos subsistemas do CNES e do SIA pelo pacote microdatasus, para
# caracterizar a capacidade instalada e a producao ambulatorial da RAS no RJ
# (leitos, equipamentos, servicos especializados, habilitacoes, profissionais,
# equipes e producao ambulatorial por subsistema).
#
# Uso (a partir da raiz da frente):
#   Rscript 02_scripts/20_baixar_cnes_sia.R
# Configuracao por variaveis de ambiente:
#   CNES_ANOS=2024          anos (separados por virgula)
#   CNES_MESES=1:12         meses (ex.: "1,2,...,12" ou "6")
#   CNES_UFS=RJ             UF
# Obs.: os arquivos do DATASUS sao anuais/mensais e volumosos. Por padrao,
# baixa um ano (2024) completo. Ajuste CNES_MESES para um unico mes para um
# retrato rapido da capacidade instalada.
#
# Saida: 01_dados/brutos_cnes_sia/{sistema}_{ano}_{mes}.rds
#        03_analises/log_cnes_sia.txt

suppressWarnings({
  library(microdatasus)
  library(data.table)

  ## Encontra a raiz da frente (que contem 01_dados/ e 02_scripts/), mesmo se o
  ## script for chamado de outro diretorio ou pela raiz do monorepo.
  acha_root <- function() {
    d <- normalizePath(".")
    for (i in 1:6) {
      if (dir.exists(file.path(d, "01_dados")) && dir.exists(file.path(d, "02_scripts")))
        return(d)
      sub <- file.path(d, "02_vulnerabilidade_climatica_RAS_RJ")
      if (dir.exists(file.path(sub, "01_dados"))) return(sub)
      pai <- dirname(d); if (pai == d) break; d <- pai
    }
    normalizePath(".")
  }
  ROOT <- acha_root()
  DIR <- file.path(ROOT, "01_dados", "brutos_cnes_sia")
  DIR_LOG <- file.path(ROOT, "03_analises")
  dir.create(DIR, showWarnings = FALSE, recursive = TRUE)
  dir.create(DIR_LOG, showWarnings = FALSE, recursive = TRUE)

  logcon <- file(file.path(DIR_LOG, "log_cnes_sia.txt"), open = "wt", encoding = "UTF-8")
  say <- function(...) { m <- paste0(...); cat(m, "\n"); writeLines(m, logcon); flush(logcon) }

  SISTEMAS <- c("CNES-LT", "CNES-ST", "CNES-DC", "CNES-EQ", "CNES-SR", "CNES-HB",
                "CNES-PF", "CNES-EP", "CNES-RC", "CNES-IN", "CNES-EE", "CNES-EF",
                "CNES-GM", "SIA-AB", "SIA-ABO", "SIA-ACF", "SIA-AD", "SIA-AN",
                "SIA-AM", "SIA-AQ", "SIA-AR", "SIA-ATD", "SIA-PA", "SIA-PS",
                "SIA-SAD")
  anos <- as.integer(strsplit(Sys.getenv("CNES_ANOS", "2024"), ",")[[1]])
  meses <- suppressWarnings(as.integer(strsplit(Sys.getenv("CNES_MESES", "1:12"), ",")[[1]]))
  if (any(is.na(meses))) meses <- 1:12
  uf <- Sys.getenv("CNES_UFS", "RJ")

  say("=====================================================================")
  say("DOWNLOAD CNES/SIA via microdatasus ", as.character(packageVersion("microdatasus")))
  say("sistemas: ", length(SISTEMAS), " | anos: ", paste(anos, collapse = ","),
      " | meses: ", paste(meses, collapse = ","), " | uf: ", uf)
  say("inicio: ", format(Sys.time()))
  say("=====================================================================")

  say("raiz da frente: ", ROOT)
  if (Sys.getenv("CNES_DRYRUN", "0") == "1") {
    say("CNES_DRYRUN=1: apenas valida caminhos e lista os sistemas, sem baixar.")
    say("sistemas (", length(SISTEMAS), "): ", paste(SISTEMAS, collapse = ", "))
    say("fim: ", format(Sys.time())); close(logcon); quit(save = "no")
  }

  baixar <- function(expr, tentativas = 3, pausa = 20) {
    for (k in seq_len(tentativas)) {
      r <- tryCatch(expr(), error = function(e) e)
      if (!inherits(r, "error")) return(r)
      say("    tentativa ", k, " falhou: ", conditionMessage(r))
      Sys.sleep(pausa)
    }
    NULL
  }

  ok <- 0L; falhas <- character(0); pulados <- 0L
  for (sis in SISTEMAS) {
    for (ano in anos) {
      for (mes in meses) {
        dest <- file.path(DIR, sprintf("%s_%d_%02d.rds", gsub("-", "_", sis), ano, mes))
        if (file.exists(dest)) { pulados <- pulados + 1L; next }
        d <- baixar(function() microdatasus::fetch_datasus(
          year_start = ano, month_start = mes, year_end = ano, month_end = mes,
          uf = uf, information_system = sis))
        if (is.null(d)) { falhas <- c(falhas, sprintf("%s_%d_%02d", sis, ano, mes)); next }
        saveRDS(d, dest)
        ok <- ok + 1L
        say(sprintf("  %-9s %d-%02d | %d linhas", sis, ano, mes, nrow(d)))
      }
    }
  }
  say(sprintf("\nconcluido: %d baixados, %d ja existiam, %d falhas", ok, pulados, length(falhas)))
  if (length(falhas)) say("falhas: ", paste(falhas, collapse = ", "))
  say("Obs.: se houver falhas por timeout, o FTP do DATASUS bloqueia o canal de")
  say("      dados em algumas redes; rodar em rede institucional ou via espelho.")
  say("fim: ", format(Sys.time()))
  close(logcon)
})
