# 11_reprodutibilidade/run_all.R
# Executa o pipeline na ordem canônica, mede o tempo de cada etapa
# (benchmark), registra status e grava um log. Pode ser chamado de qualquer
# diretório; o diretório de trabalho é fixado na raiz do projeto.
#
# Uso:
#   Rscript 11_reprodutibilidade/run_all.R                 # tudo
#   Rscript 11_reprodutibilidade/run_all.R --rapido        # exclui etapas pesadas
#   Rscript 11_reprodutibilidade/run_all.R --somente=03,04,05
#   Rscript 11_reprodutibilidade/run_all.R --continuar     # não para no 1o erro
#
# Saídas:
#   11_reprodutibilidade/benchmarks_execucao.csv
#   11_reprodutibilidade/run_all.log

suppressWarnings({
  args <- commandArgs(trailingOnly = TRUE)
  getarg <- function(nome) {
    i <- grep(paste0("^--", nome, "($|=)"), args)
    if (!length(i)) return(NA)
    a <- args[i[1]]
    if (grepl("=", a)) sub("^[^=]+=", "", a) else TRUE
  }
  args_script <- commandArgs(trailingOnly = FALSE)
  fa <- grep("^--file=", args_script, value = TRUE)
  this <- if (length(fa)) normalizePath(sub("^--file=", "", fa)) else normalizePath(".")
  ROOT <- normalizePath(file.path(dirname(this), ".."))
  OUT <- file.path(ROOT, "11_reprodutibilidade")
  dir.create(OUT, showWarnings = FALSE, recursive = TRUE)
  setwd(ROOT)

  ## ordem canônica do pipeline (R e Python)
  PIPELINE <- c(
    "00_migrar_2014_2024.R",
    "02_montar_coorte.R",
    "03_tabelas_descritivas.R",
    "04_isu_regiao_saude.R",
    "05_glmm_principal.R",
    "06_glmm_uti.R",
    "07_auditoria_consistencia.R",
    "08_glmm_robustez.R",
    "09_conferencia_motores.R",
    "10_figuras.R",
    "11_exploratorio.R",
    "12_auditoria_geral.R",
    "13_figuras_exploratorias.R",
    "14_verificacao_sidra.R",
    "15_deflacao_ipca.R",
    "19_figura_exploratorio.R",
    "22_padronizacao_etaria.R",
    "24_mapa_regioes_saude.R",
    "26_recalculo_duas_classes.R",
    "16_consolidar_dados.py",
    "17_analises_territoriais.py",
    "18_mortalidade_sim.py")

  PESADOS <- c("02_montar_coorte.R", "05_glmm_principal.R", "06_glmm_uti.R",
               "07_auditoria_consistencia.R", "08_glmm_robustez.R",
               "11_exploratorio.R", "16_consolidar_dados.py")

  somente <- getarg("somente")
  if (!is.na(somente)) {
    sel <- trimws(strsplit(somente, ",")[[1]])
    num <- sub("^([0-9]+).*", "\\1", PIPELINE)
    scripts <- PIPELINE[num %in% sel | PIPELINE %in% sel]
  } else if (isTRUE(getarg("rapido"))) {
    scripts <- setdiff(PIPELINE, PESADOS)
  } else {
    scripts <- PIPELINE
  }
  continuar <- isTRUE(getarg("continuar"))

  logcon <- file(file.path(OUT, "run_all.log"), open = "wt", encoding = "UTF-8")
  say <- function(...) { m <- paste0(...); cat(m, "\n"); writeLines(m, logcon); flush(logcon) }

  rscript <- file.path(R.home("bin"), "Rscript")
  ## no Windows o R.home("bin") traz Rscript.exe
  if (.Platform$OS.type == "windows" && !file.exists(rscript)) rscript <- file.path(R.home("bin"), "Rscript.exe")

  say("PIPELINE | inicio: ", format(Sys.time()), " | scripts: ", length(scripts))
  say("R: ", R.version.string, " | wd: ", getwd())

  bench <- data.frame(ordem = integer(0), script = character(0), inicio = character(0),
                      fim = character(0), segundos = numeric(0), status = character(0),
                      stringsAsFactors = FALSE)

  for (i in seq_along(scripts)) {
    s <- scripts[i]
    path <- file.path("02_scripts", s)
    t0 <- Sys.time()
    if (!file.exists(path)) {
      status <- "AUSENTE"
      say(sprintf("[%2d/%2d] %-30s AUSENTE", i, length(scripts), s))
    } else {
      cmd <- if (grepl("\\.py$", s)) {
        py <- Sys.which("python"); if (!nzchar(py)) py <- Sys.which("python3")
        paste(shQuote(py), shQuote(path))
      } else paste(shQuote(rscript), "--vanilla", shQuote(path))
      rc <- tryCatch(system(cmd, ignore.stdout = TRUE, ignore.stderr = TRUE), error = function(e) 1L)
      status <- if (rc == 0) "OK" else paste0("ERRO(", rc, ")")
      say(sprintf("[%2d/%2d] %-30s %-8s %.1f s", i, length(scripts), s, status,
                  as.numeric(difftime(Sys.time(), t0, units = "secs"))))
      if (rc != 0 && !continuar) {
        bench <- rbind(bench, data.frame(ordem = i, script = s,
          inicio = format(t0), fim = format(Sys.time()),
          segundos = round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1),
          status = status))
        say("interrompido no primeiro erro (use --continuar para seguir)")
        break
      }
    }
    bench <- rbind(bench, data.frame(ordem = i, script = s, inicio = format(t0),
      fim = format(Sys.time()),
      segundos = round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1),
      status = status))
  }

  bench_path <- file.path(OUT, "benchmarks_execucao.csv")
  if (file.exists(bench_path)) {
    antigo <- tryCatch(utils::read.csv(bench_path, stringsAsFactors = FALSE, fileEncoding = "UTF-8"),
                       error = function(e) NULL)
    if (!is.null(antigo) && nrow(antigo)) {
      antigo <- antigo[!antigo$script %in% bench$script, , drop = FALSE]
      bench <- rbind(antigo[intersect(names(antigo), names(bench))], bench)
    }
  }
  bench$ordem <- match(bench$script, PIPELINE)
  bench <- bench[order(bench$ordem), , drop = FALSE]
  row.names(bench) <- NULL
  utils::write.csv(bench, bench_path, row.names = FALSE, fileEncoding = "UTF-8")
  say("benchmark gravado: benchmarks_execucao.csv | total ",
      round(sum(bench$segundos) / 60, 1), " min")
  say("fim: ", format(Sys.time()))
  close(logcon)
})
