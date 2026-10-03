# 25_baixar_cnes_sia_api.R
# Download dos dados de CNES (e uma tentativa de SIA) pela API oficial de Dados
# Abertos do Ministerio da Saude, que funciona por HTTPS e contorna o bloqueio
# do canal de dados do FTP do DATASUS.
#
#   Base: https://apidadosabertos.saude.gov.br/assistencia-a-saude
#   Endpoints: cnes-leitos, cnes-equipamentos, cnes-servicos-especializados,
#              cnes-estabelecimentos, cnes-profissionais, sia-procedimentos-ambulatoriais
#
# Estrategia: a API devolve o historico completo de um estabelecimento quando
# filtrada por `co_cnes` (o filtro por municipio devolve apenas 1 registro).
# Por isso, percorremos a lista de CNES da coorte de DCV (05_tabelas/tab_hospitais.csv)
# e gravamos um .rds por endpoint.
#
# Configuracao por variaveis de ambiente:
#   CNES_API_MAX=0     limita o numero de CNES (0 = todos); util para teste
#   CNES_API_ENDPOINTS=... lista separada por virgula (default: todos os CNES)
#   CNES_API_SLEEP=0.15 pausa entre requisicoes
#
# Saida: 01_dados/brutos_cnes_sia/api_{endpoint}.rds
#        03_analises/log_cnes_sia_api.txt

suppressWarnings({
  library(data.table)
  library(jsonlite)

  acha_root <- function() {
    d <- normalizePath(".")
    for (i in 1:6) {
      if (dir.exists(file.path(d, "01_dados")) && dir.exists(file.path(d, "02_scripts"))) return(d)
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

  logcon <- file(file.path(DIR_LOG, "log_cnes_sia_api.txt"), open = "wt", encoding = "UTF-8")
  say <- function(...) { m <- paste0(...); cat(m, "\n"); writeLines(m, logcon); flush(logcon) }

  BASE <- "https://apidadosabertos.saude.gov.br/assistencia-a-saude"
  ENDPOINTS <- c("cnes-leitos", "cnes-equipamentos", "cnes-servicos-especializados",
                 "cnes-estabelecimentos", "cnes-profissionais")
  eps_env <- Sys.getenv("CNES_API_ENDPOINTS", "")
  if (nzchar(eps_env)) ENDPOINTS <- trimws(strsplit(eps_env, ",")[[1]])
  SLEEP <- as.numeric(Sys.getenv("CNES_API_SLEEP", "0.15"))
  MAX <- as.integer(Sys.getenv("CNES_API_MAX", "0"))

  ## lista de CNES (coorte de DCV), padronizada em 7 digitos
  hosp <- fread(file.path(ROOT, "05_tabelas", "tab_hospitais.csv"), encoding = "UTF-8")
  cnes <- unique(sprintf("%07d", as.integer(gsub("[^0-9]", "", as.character(hosp$CNES)))))
  cnes <- cnes[!is.na(cnes) & cnes != "0000000"]
  if (MAX > 0) cnes <- head(cnes, MAX)

  say("DOWNLOAD CNES VIA API DE DADOS ABERTOS")
  say("raiz: ", ROOT, " | CNES: ", length(cnes), " | endpoints: ", paste(ENDPOINTS, collapse = ", "))
  say("inicio: ", format(Sys.time()))

  get_json <- function(url, tentativas = 4) {
    for (k in seq_len(tentativas)) {
      r <- tryCatch({
        txt <- paste(readLines(url, warn = FALSE, encoding = "UTF-8"), collapse = "")
        fromJSON(txt)
      }, error = function(e) e)
      if (!inherits(r, "error")) return(r)
      if (k < tentativas) Sys.sleep(1.5 * k)
    }
    NULL
  }

  for (ep in ENDPOINTS) {
    dest <- file.path(DIR, paste0("api_", gsub("-", "_", ep), ".rds"))
    if (file.exists(dest)) { say("ja existe: ", basename(dest)); next }
    say("\n--- ", ep, " ---")
    partes <- list(); ok <- 0L; falhas <- 0L
    for (i in seq_along(cnes)) {
      u <- sprintf("%s/%s?co_cnes=%s", BASE, ep, cnes[i])
      j <- get_json(u)
      if (!is.null(j) && length(j)) {
        key <- names(j)[1]
        d <- as.data.table(j[[key]])
        if (nrow(d)) { d[, co_cnes := cnes[i]]; partes[[length(partes) + 1L]] <- d; ok <- ok + 1L }
      } else falhas <- falhas + 1L
      if (i %% 25 == 0 || i == length(cnes))
        say(sprintf("  %3d/%d CNES | com dados=%d | falhas=%d", i, length(cnes), ok, falhas))
      Sys.sleep(SLEEP)
    }
    if (length(partes)) {
      out <- rbindlist(partes, fill = TRUE)
      saveRDS(out, dest)
      say("  gravado ", basename(dest), " | linhas=", nrow(out), " | colunas=", ncol(out))
    } else say("  sem dados para ", ep)
  }

  ## SIA: a API so devolve poucos registros por municipio; grava o que houver.
  dest_sia <- file.path(DIR, "api_sia_procedimentos_ambulatoriais.rds")
  if (!file.exists(dest_sia)) {
    say("\n--- sia-procedimentos-ambulatoriais (por municipio) ---")
    lk <- fread(file.path(dirname(ROOT), "01_DLNMs_RJ_cerebrovascular", "data_processed",
                          "lookup_municipio_macrorregiao.csv"),
                colClasses = "character", encoding = "UTF-8")
    munis <- unique(sprintf("%06d", as.integer(gsub("[^0-9]", "", lk$ibge6))))
    partes <- list(); ok <- 0L
    for (i in seq_along(munis)) {
      u <- sprintf("%s/sia-procedimentos-ambulatoriais?co_ibge=%s&nu_ano=2024", BASE, munis[i])
      j <- get_json(u)
      if (!is.null(j) && length(j)) {
        key <- names(j)[1]; d <- as.data.table(j[[key]])
        if (nrow(d)) { d[, co_ibge := munis[i]]; partes[[length(partes) + 1L]] <- d; ok <- ok + 1L }
      }
      Sys.sleep(SLEEP)
    }
    if (length(partes)) { out <- rbindlist(partes, fill = TRUE); saveRDS(out, dest_sia)
      say("  gravado ", basename(dest_sia), " | linhas=", nrow(out)) } else say("  sem dados de SIA")
  }

  say("\nfim: ", format(Sys.time()))
  close(logcon)
})
