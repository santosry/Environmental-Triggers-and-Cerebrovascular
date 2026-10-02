# 00_pipeline_revisao_sistematica.R
# PIPELINE COMPLETO da revisão sistemática e meta-análise:
#
#   "Environmental determinants of cerebrovascular diseases (ICD-10 I60–I69)
#    across the lifespan: a global systematic review and meta-analysis"
#
# Este é o ÚNICO script do projeto: todas as etapas foram consolidadas aqui,
# separadas por SEÇÕES numeradas. Cada seção pode ser ligada/desligada no
# PAINEL DE CONTROLE (logo abaixo) e cada uma é executada dentro de um
# tryCatch, de modo que um erro em uma etapa NÃO derruba as demais.
#
# COMO USAR
#   1) Abra este arquivo no RStudio (ou rode no terminal: Rscript).
#   2) Ajuste o PAINEL DE CONTROLE (EXEC) e os PARÂMETROS (CFG) abaixo.
#   3) Rode o arquivo inteiro OU apenas a seção desejada.
#
#   Para a triagem por tópicos, a SEÇÃO 10 abre um app Shiny e POR ISSO exige
#   o RStudio (não roda no terminal). As demais seções rodam em qualquer lugar.
#
#   Ordem recomendada de execução:
#     Ex. 1 (buscas, só se precisar refazer) ... SEÇÕES 2,3,4,5
#     Ex. 2 (processamento dos resultados) ..... SEÇÕES 6,7
#     Ex. 3 (triagem) .......................... SEÇÕES 8,9,10,11,12
#     Ex. 4 (síntese) .......................... SEÇÕES 13,14,15,16,17
#     Ex. 5 (relato) ........................... SEÇÕES 18,19,20
#
#   Guia narrativo: 00_docs/como_rodar_triagem.md
#
# BASE METODOLÓGICA (referências completas em 04_referencias/referencias.bib)
#   - PRISMA 2020: Page MJ, et al. BMJ. 2021;372:n71. doi:10.1136/bmj.n71
#   - PRISMA-P 2015: Moher D, et al. Syst Rev. 2015;4:1.
#   - Cochrane Handbook 2019: doi:10.1002/9781119536604
#   - revtools (triagem/dedup): Westgate MJ. Res Synth Methods.
#     2019;10(4):606-614. doi:10.1002/jrsm.1374
#   - litsearchr (busca): Grames EM, et al. J Open Source Softw. 2019;4(36):1160.
#   - bibliometrix: Aria M, Cuccurullo C. J Informetr. 2017;11(4):959-975.
#   - metafor: Viechtbauer W. J Stat Softw. 2010;36(3):1-48.
#   - robvis: McGuinness LA, Higgins JPT. Res Synth Methods. 2021;12(1):55-61.
#   - PRISMA2020 (diagrama): Haddaway NR, et al. Campbell Syst Rev.
#     2022;18(2):e1230.
#   - Cohen J. Educ Psychol Meas. 1960;20(1):37-46 (kappa).


# SEÇÃO 0 — PAINEL DE CONTROLE E PARÂMETROS
# Ligue (TRUE) ou desligue (FALSE) cada etapa. Por padrão, as etapas que já
# foram executadas e as que dependem de internet/ambiente interativo ficam
# DESLIGADAS, para que uma execução "de ponta a ponta" não refaça tudo.

EXEC <- list(
  setup                 = TRUE,   # ambiente, pastas, sessão, pacotes
  busca_litsearchr      = FALSE,  # estratégia de busca assistida (internet)
  busca_pubmed          = FALSE,  # PubMed (internet)
  busca_scopus          = FALSE,  # Scopus (internet + API key)
  busca_scielo          = FALSE,  # SciELO (internet + Chrome headless)
  deduplicacao          = FALSE,  # dedup + planilhas de triagem (rápido)
  bibliometria          = FALSE,  # bibliometrix (pode demorar)
  enriquecer_abstracts  = FALSE,  # recuperar resumos ausentes (internet, longo)
  topicos_preparar      = FALSE,  # preparar lotes do LDA (offline, demorado)
  topicos_app           = FALSE,  # app screen_topics (RStudio, interativo)
  consolidar_triagem    = TRUE,   # consenso + kappa da fase 1 (rápido)
  texto_completo        = TRUE,   # templates/consolidação da fase 2 (rápido)
  extracao              = TRUE,   # template de extração + escalc (demonstração)
  risco_vies            = TRUE,   # ROBINS-I/robustez (demonstração)
  meta_analise          = TRUE,   # REML + heterogeneidade (demonstração)
  forest_plots          = TRUE,   # forest plots estratificados
  subgrupos             = TRUE,   # subgrupos/metarregressão/sensibilidade
  prisma                = TRUE,   # diagrama de fluxo PRISMA 2020
  figuras               = TRUE,   # figuras simples do relatório
  relatorio             = FALSE   # gerar/ renderizar o R Markdown final
)

# Parâmetros numéricos e de rede (edite conforme necessário).
CFG <- list(
  # triagem por tópicos (SEÇÕES 9-11)
  estrategia_topicos = "base_ano", # "base_ano" | "base"
  n_topics           = 12,         # nº máximo de tópicos do LDA
  iterations         = 1000,       # iterações do Gibbs
  min_freq           = 0.02,       # frequência mínima global do termo
  max_freq           = 0.90,       # frequência máxima global do termo
  bigramas           = FALSE,      # TRUE aumenta muito o custo do LDA
  bigram_quantile    = 0.80,
  min_tam_lote       = 30,         # lotes menores que isso são agrupados
  teste_topicos      = FALSE,      # TRUE = usa 300 registros (teste rápido)
  forcar_topicos     = FALSE,      # TRUE = refaz lotes já existentes
  lotes_alvo         = "",         # ex.: "lote_01,lote_05" (vazio = todos)
  # enriquecimento de resumos (SEÇÃO 8)
  limite_enriquecer  = 300,        # 0 = todos (longo)
  so_incluidos_enriq = FALSE,      # TRUE = só os incluídos na fase 1
  pausa_enriquecer   = 0.40,       # segundos entre consultas (limite do NCBI)
  # texto completo (SEÇÃO 12)
  forcar_texto_completo = FALSE,   # TRUE = recria os templates (apaga decisões!)
  # credenciais (opcional; a Scopus também lê api_keys.txt)
  ncbi_api_key   = Sys.getenv("444d2ccbed001ce8839cae0c601dd719c509", unset = ""),
  scopus_api_key = NULL
)


# SEÇÃO 1 — AMBIENTE, PACOTES, CAMINHOS E FUNÇÕES AUXILIARES COMUNS
# Tudo o que é usado por várias seções fica aqui: semente, pastas, log,
# carregamento de pacotes, kappa de Cohen e atualização do PRISMA.

if (isTRUE(EXEC$setup)) {

  # reprodutibilidade
  set.seed(20202026)                     # semente fixa (data de referência)
  options(stringsAsFactors = FALSE)
  options(repos = c(CRAN = "https://cloud.r-project.org/"))
  options(timeout = 600)
  PROJETO <- "revisao_sistematica"

  # pacotes centrais
  # 'here' fica disponivel para o relatorio (Rmd); os caminhos do pipeline
  # usam raiz() (abaixo), que e mais robusto a pasta de trabalho errada.
  if (!requireNamespace("here", quietly = TRUE)) {
    stop("Pacote 'here' ausente. Instale manualmente: install.packages('here')")
  }
  suppressPackageStartupMessages(library(here))

  # Pasta oficial do projeto. Por decisao explicita, o pipeline le e escreve
  # SOMENTE aqui dentro — nunca em pastas vizinhas (ex.: raiz do repositorio
  # DLNM) nem no diretorio de trabalho atual. Se o projeto mudar de lugar,
  # atualize apenas a linha PASTA_PROJETO abaixo.
  PASTA_PROJETO <- "C:/Users/oorie/OneDrive/Documentos/TRABALHOS/DLNM/03_revisão_impactos_à_saúde"

  # trava de seguranca: aborta sem criar nada fora da pasta do projeto.
  if (!dir.exists(PASTA_PROJETO)) {
    stop("Pasta do projeto nao encontrada: ", PASTA_PROJETO,
         "\nEdite PASTA_PROJETO no inicio da SECAO 1.")
  }
  RAIZ_PROJETO <- normalizePath(PASTA_PROJETO, winslash = "/", mustWork = TRUE)
  if (!(dir.exists(file.path(RAIZ_PROJETO, "01_scripts")) &&
        dir.exists(file.path(RAIZ_PROJETO, "02_dados")))) {
    stop("A pasta indicada nao parece ser a do projeto: ", RAIZ_PROJETO)
  }

  setwd(RAIZ_PROJETO)
  raiz <- function(...) file.path(RAIZ_PROJETO, ...)

  # trava extra: bloqueia qualquer dir.create() fora da pasta do projeto.
  dir.create <- function(path, ...) {
    p <- normalizePath(path, winslash = "/", mustWork = FALSE)
    if (!startsWith(p, RAIZ_PROJETO)) {
      stop("Tentativa de criar pasta fora do projeto: ", p)
    }
    base::dir.create(p, ...)
  }

  if (!file.exists(file.path(RAIZ_PROJETO, ".here"))) {
    file.create(file.path(RAIZ_PROJETO, ".here"))
  }
  message("Projeto (tudo sera criado/lido apenas aqui): ", RAIZ_PROJETO)

  # helper: carrega os pacotes. NAO instala nada (para nao criar pastas fora
  # do projeto); se algum faltar, apenas avisa.
  carregar <- function(...) {
    for (p in c(...)) {
      if (requireNamespace(p, quietly = TRUE)) {
        suppressPackageStartupMessages(library(p, character.only = TRUE))
      } else {
        message("AVISO: pacote indisponivel: ", p,
                " — instale manualmente se necessario.")
      }
    }
  }
  carregar("tidyverse", "readr", "dplyr", "purrr", "ggplot2", "janitor",
           "countrycode")

  # estrutura de pastas
  dirs <- c(
    "00_docs", "01_scripts",
    "02_dados/brutos", "02_dados/processados", "02_dados/extraidos",
    "03_resultados/figuras", "03_resultados/tabelas", "03_resultados/bibliometria",
    "03_resultados/logs", "04_referencias"
  )
  for (d in dirs) dir.create(raiz(d), recursive = TRUE, showWarnings = FALSE)

  # caminhos centrais (usados por todas as seções)
  dir_brutos <- raiz("02_dados", "brutos")
  dir_proc   <- raiz("02_dados", "processados")
  dir_ext    <- raiz("02_dados", "extraidos")
  dir_fig    <- raiz("03_resultados", "figuras")
  dir_tab    <- raiz("03_resultados", "tabelas")
  dir_bib    <- raiz("03_resultados", "bibliometria")
  dir_log    <- raiz("03_resultados", "logs")
  dir_ref    <- raiz("04_referencias")
  dir_docs   <- raiz("00_docs")
  dir_top    <- file.path(dir_proc, "topicos")            # lotes do LDA
  dir_dec    <- file.path(dir_top, "decisoes")            # decisões da triagem
  dir.create(dir_top, showWarnings = FALSE, recursive = TRUE)
  dir.create(dir_dec, showWarnings = FALSE, recursive = TRUE)

  # log único do pipeline
  log_path <- file.path(dir_log, "pipeline.log")
  registrar <- function(...) {
    msg <- paste0("[", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "] ", paste0(...))
    cat(msg, "\n")
    cat(msg, "\n", file = log_path, append = TRUE)
  }

  # captura de erros por seção (não interrompe as demais)
  # 'tentar({ ... })' avalia o bloco NO AMBIENTE CHAMADOR (global) e captura
  # qualquer erro, registrando no log.
  tentar <- function(code) {
    expr <- substitute(code)
    tryCatch(
      eval(expr, envir = parent.frame()),
      error = function(e) {
        message(">> Seção interrompida: ", conditionMessage(e))
        registrar("ERRO: ", conditionMessage(e))
        NULL
      }
    )
  }

  registrar("=======================================================")
  registrar("PIPELINE iniciado — R ", R.version.string)
  registrar("Projeto: ", raiz())

  # registro da sessão (FAIR)
  sink(file.path(dir_ref, "session_info.txt"))
  cat("Sessão do pipeline — gerada em", format(Sys.time()), "\n\n")
  print(sessionInfo())
  sink()
}

# Funções compartilhadas (definidas FORA do if, para existirem sempre)

# normaliza rótulos de decisão para "incluido"/"excluido"/NA
normalizar_decisao <- function(x) {
  x <- tolower(trimws(as.character(x)))
  x <- gsub("[[:punct:]]+$", "", gsub("^[[:punct:]]+", "", x))
  incluir <- c("incluir", "incluido", "incluído", "include", "included",
               "selected", "selecionado", "sim", "s", "1", "yes", "y",
               "elegivel", "elegível", "elegible", "manter", "keep")
  excluir <- c("excluir", "excluido", "excluído", "exclude", "excluded",
               "nao", "não", "n", "0", "no", "inelegivel", "inelegível",
               "inelegible", "remover", "remove", "descartar")
  out <- rep(NA_character_, length(x))
  out[x %in% incluir] <- "incluido"
  out[x %in% excluir] <- "excluido"
  out
}

# classificação de Landis & Koch (1977) para o kappa
interpretar_kappa <- function(k) {
  if (length(k) == 0 || is.na(k)) return("indefinido (sem pares decididos)")
  if (k < 0)    return("pior que o acaso")
  if (k < 0.20) return("insignificante")
  if (k < 0.40) return("razoavel")
  if (k < 0.60) return("moderada")
  if (k < 0.80) return("substancial")
  return("quase perfeita")
}

# kappa de Cohen com IC95% por bootstrap (não requer 'irr'/'psych')
kappa_cohen <- function(a, b, conf.level = 0.95, bootstrap = 2000, seed = 20202026) {
  ok <- !is.na(a) & !is.na(b); a <- a[ok]; b <- b[ok]; n <- length(a)
  if (n < 2) {
    return(list(n = n, po = NA_real_, pe = NA_real_, kappa = NA_real_,
                ic95_inf = NA_real_, ic95_sup = NA_real_,
                interpretacao = interpretar_kappa(NA_real_), tabela = NULL))
  }
  labs <- sort(unique(c(a, b)))
  montar <- function(aa, bb) {
    tt <- table(factor(aa, levels = labs), factor(bb, levels = labs))
    nn <- length(aa); po <- sum(diag(tt)) / nn
    pe <- sum(rowSums(tt) / nn * colSums(tt) / nn)
    list(tab = tt, po = po, pe = pe, k = (po - pe) / (1 - pe))
  }
  base <- montar(a, b)
  set.seed(seed)
  ks <- replicate(bootstrap, {
    idx <- sample.int(n, replace = TRUE); montar(a[idx], b[idx])$k
  })
  ci <- suppressWarnings(stats::quantile(
    ks, c((1 - conf.level) / 2, 1 - (1 - conf.level) / 2), na.rm = TRUE))
  list(n = n, po = base$po, pe = base$pe, kappa = base$k,
       ic95_inf = unname(ci[1]), ic95_sup = unname(ci[2]),
       interpretacao = interpretar_kappa(base$k), tabela = base$tab)
}

# tabela de concordância entre dois revisores
resumo_acordo <- function(a, b) {
  ok <- !is.na(a) & !is.na(b)
  if (!any(ok)) return(tibble(r1 = character(), r2 = character(), n = integer(), pct = numeric()))
  as.data.frame(table(r1 = a[ok], r2 = b[ok])) |>
    rename(n = Freq) |>
    mutate(pct = round(100 * n / sum(n), 2)) |>
    arrange(desc(n))
}

# atualiza (ou cria) as contagens do fluxo PRISMA
atualizar_prisma <- function(excluidos_ta = NULL, pendentes_ta = NULL,
                             textos_avaliados = NULL, incluidos_sintese = NULL,
                             caminho = raiz("03_resultados", "tabelas",
                                            "prisma_contagens.csv")) {
  dir.create(dirname(caminho), showWarnings = FALSE, recursive = TRUE)
  tab <- if (file.exists(caminho)) readr::read_csv(caminho, show_col_types = FALSE) else
    tibble(etapa = character(), n = numeric())
  atualiza <- function(tab, etapa, valor) {
    if (is.null(valor)) return(tab)
    if (etapa %in% tab$etapa) tab$n[tab$etapa == etapa] <- valor
    else tab <- bind_rows(tab, tibble(etapa = etapa, n = valor))
    tab
  }
  tab <- atualiza(tab, "Registros excluídos na triagem de título/abstrato", excluidos_ta)
  tab <- atualiza(tab, "Triagem título/abstrato pendente", pendentes_ta)
  tab <- atualiza(tab, "Textos completos avaliados", textos_avaliados)
  tab <- atualiza(tab, "Estudos incluídos na síntese", incluidos_sintese)
  readr::write_csv(tab, caminho)
  invisible(tab)
}

# rótulos fixos da triagem por tópicos
REMOVE_WORDS <- c("study", "results", "conclusion", "background", "objective",
                  "methods", "conclusions", "method", "aim", "aims")

# leitura simples de argumentos de linha de comando "--nome=valor"
arg_val <- function(nome, default) {
  args <- commandArgs(trailingOnly = TRUE)
  m <- grep(paste0("^--", nome, "="), args, value = TRUE)
  if (length(m)) sub(paste0("^--", nome, "="), "", m[1]) else default
}
# permite sobrescrever alguns parâmetros pela linha de comando
if (nzchar(arg_val("n_topics", ""))) CFG$n_topics <- as.integer(arg_val("n_topics", CFG$n_topics))
if (nzchar(arg_val("iterations", ""))) CFG$iterations <- as.integer(arg_val("iterations", CFG$iterations))
if (nzchar(arg_val("limite", ""))) CFG$limite_enriquecer <- as.integer(arg_val("limite", CFG$limite_enriquecer))
if (any(grepl("^--teste", commandArgs(trailingOnly = TRUE)))) CFG$teste_topicos <- TRUE
if (any(grepl("^--forcar", commandArgs(trailingOnly = TRUE)))) CFG$forcar_topicos <- TRUE


# SEÇÃO 2 — ESTRATÉGIA DE BUSCA ASSISTIDA POR litsearchr
# Constrói/valida a estratégia de busca a partir de um corpus de treino extraído
# do PubMed: extração de termos (FAKERAKE), rede de coocorrência, ranqueamento
# por importância e geração das strings booleanas.
# Fundamentação: Grames et al. (2019); PRISMA 2020, itens 6-7; Cochrane (busca
# de alta sensibilidade); Bramer et al. (2017).
# Entrada:  02_dados/brutos/pubmed_records.csv
# Saída:    02_dados/processados/litsearchr_termos.csv, litsearchr_rede.png,
#           04_referencias/litsearchr_keywords.csv

if (isTRUE(EXEC$busca_litsearchr)) tentar({
  carregar("litsearchr", "rentrez", "xml2")
  registrar("SEÇÃO 2: estratégia de busca (litsearchr)")

  arq_corpus <- file.path(dir_brutos, "pubmed_records.csv")
  if (!file.exists(arq_corpus)) stop("pubmed_records.csv ausente (rode a SEÇÃO 3 antes).")
  d <- readr::read_csv(arq_corpus, show_col_types = FALSE)
  corpus_text <- paste(ifelse(is.na(d$TI), "", d$TI), ifelse(is.na(d$AB), "", d$AB), sep = " . ")
  corpus_text <- corpus_text[nchar(corpus_text) > 10]
  set.seed(20202026)
  corpus_text <- sample(corpus_text, min(1000, length(corpus_text)))

  sw <- tryCatch(litsearchr::get_stopwords("English"), error = function(e) character(0))
  termos <- tryCatch(
    litsearchr::extract_terms(corpus_text, method = "fakerake", min_freq = 5,
                              ngrams = TRUE, min_n = 2, max_n = 4,
                              stopwords = sw, language = "English"),
    error = function(e) { message("extract_terms: ", conditionMessage(e)); character(0) })
  termos <- unique(termos)

  keywords <- character(0)
  if (length(termos) > 0) {
    dfm <- litsearchr::create_dfm(elements = corpus_text, features = termos)
    net <- tryCatch(litsearchr::create_network(dfm, min_studies = 5, min_occ = 5),
                    error = function(e) NULL)
    if (!is.null(net)) {
      imp <- litsearchr::make_importance(net, imp_method = "strength")
      cutoff <- tryCatch(litsearchr::find_cutoff(net, method = "cumulative", percent = 0.8),
                         error = function(e) NA)
      if (!is.na(cutoff)) keywords <- litsearchr::get_keywords(litsearchr::reduce_graph(net, cutoff))
      write.csv(as.data.frame(imp), file.path(dir_proc, "litsearchr_termos.csv"))
      write.csv(data.frame(keyword = keywords),
                file.path(dir_ref, "litsearchr_keywords.csv"), row.names = FALSE)
      png(file.path(dir_proc, "litsearchr_rede.png"), width = 1800, height = 1400, res = 150)
      set.seed(20202026)
      plot(net, vertex.size = 3, vertex.label.cex = 0.4, vertex.color = "lightblue")
      dev.off()
    }
  }
  registrar("Termos extraídos: ", length(termos), " | palavras-chave: ", length(keywords))
})


# SEÇÃO 3 — BUSCA NO PUBMED/MEDLINE
# Executa a estratégia definitiva (blocos Desfecho × Exposição), recupera os
# registros completos e exporta CSV/RIS/BibTeX. Fundamentação: PRISMA 2020,
# itens 6-7; Bramer et al. (2017); E-utilities do NCBI.
# Saída: 02_dados/brutos/pubmed_records.csv, .ris, query.txt, count.csv

if (isTRUE(EXEC$busca_pubmed)) tentar({
  carregar("rentrez", "xml2")
  registrar("SEÇÃO 3: busca PubMed")

  query <- paste0(
    '("Cerebrovascular Disorders"[MeSH] OR "Stroke"[MeSH] OR "Brain Ischemia"[MeSH] OR ',
    '"Cerebral Hemorrhage"[MeSH] OR "Subarachnoid Hemorrhage"[MeSH] OR ',
    '"Intracranial Hemorrhages"[MeSH] OR "Brain Infarction"[MeSH] OR ',
    '"Intracranial Arteriosclerosis"[MeSH] OR "Carotid Stenosis"[MeSH] OR ',
    '"Vasospasm, Intracranial"[MeSH] OR stroke*[tiab] OR cerebrovascular[tiab] OR ',
    '"cerebral infarction"[tiab] OR "intracerebral h?emorrhage"[tiab] OR ',
    '"subarachnoid h?emorrhage"[tiab] OR "cerebral h?emorrhage"[tiab] OR ',
    '"brain isch?emia"[tiab] OR "cerebrovascular accident"[tiab] OR ',
    '"I60"[tiab] OR "I61"[tiab] OR "I62"[tiab] OR "I63"[tiab] OR "I64"[tiab] OR "I69"[tiab]) ',
    'AND ',
    '("Weather"[MeSH] OR "Climate"[MeSH] OR "Climate Change"[MeSH] OR ',
    '"Hot Temperature"[MeSH] OR "Cold Temperature"[MeSH] OR "Temperature"[MeSH] OR ',
    '"Humidity"[MeSH] OR "Extreme Weather"[MeSH] OR "Heat Stress Disorders"[MeSH] OR ',
    '"Air Pollution"[MeSH] OR "Particulate Matter"[MeSH] OR "Air Pollutants"[MeSH] OR ',
    '"Ozone"[MeSH] OR "Nitrogen Dioxide"[MeSH] OR "Environmental Exposure"[MeSH] OR ',
    '"Environmental Pollutants"[MeSH] OR "Water Pollution"[MeSH] OR "Sanitation"[MeSH] OR ',
    '"Drinking Water"[MeSH] OR "Water Supply"[MeSH] OR "Soil Pollutants"[MeSH] OR ',
    '"Noise"[MeSH] OR "Housing"[MeSH] OR "Air Pollution, Indoor"[MeSH] OR "Biomass"[MeSH] OR ',
    '"Natural Disasters"[MeSH] OR "Floods"[MeSH] OR "Fires"[MeSH] OR "Cyclonic Storms"[MeSH] OR ',
    '"Built Environment"[MeSH] OR "City Planning"[MeSH] OR "Urbanization"[MeSH] OR ',
    '"Parks, Recreational"[MeSH] OR "Occupational Exposure"[MeSH] OR ',
    'temperature[tiab] OR climate[tiab] OR humidity[tiab] OR "heat wave*"[tiab] OR ',
    '"cold spell*"[tiab] OR "air pollution"[tiab] OR "PM2.5"[tiab] OR "PM10"[tiab] OR ',
    'ozone[tiab] OR "nitrogen dioxide"[tiab] OR "particulate matter"[tiab] OR ',
    'sanitation[tiab] OR "drinking water"[tiab] OR "solid fuel*"[tiab] OR ',
    '"indoor air"[tiab] OR "heat island*"[tiab] OR flood*[tiab] OR wildfire*[tiab] OR ',
    '"green space*"[tiab] OR "built environment"[tiab] OR noise[tiab]) ',
    'AND ("2020/01/01"[Date - Publication] : "2026/09/30"[Date - Publication]) ',
    'AND (english[Language] OR portuguese[Language] OR spanish[Language])'
  )
  writeLines(query, file.path(dir_brutos, "pubmed_query.txt"))

  api_key <- if (nzchar(CFG$ncbi_api_key)) CFG$ncbi_api_key else NULL
  busca <- rentrez::entrez_search("pubmed", term = query, retmax = 0, api_key = api_key)
  n_hits <- busca$count
  write.csv(data.frame(base = "PubMed", data = format(Sys.time()), registros = n_hits),
            file.path(dir_brutos, "pubmed_count.csv"), row.names = FALSE)
  registrar("PubMed: ", n_hits, " registros.")

  if (requireNamespace("pubmedR", quietly = TRUE)) {
    M <- pubmedR::pmApiRequest(query = query, limit = 10000, api_key = api_key)
    df <- pubmedR::pmApi2df(M, format = "bibliometrix")
  } else {
    # fallback com rentrez (sem pular a etapa se pubmedR faltar)
    ids <- rentrez::entrez_search("pubmed", term = query, retmax = n_hits,
                                  use_history = TRUE, api_key = api_key)$ids
    recs <- rentrez::entrez_fetch("pubmed", id = ids, rettype = "xml", retmode = "text")
    xml <- xml2::read_xml(recs)
    artigos <- xml2::xml_find_all(xml, ".//PubmedArticle")
    extrair <- function(a) {
      txt <- function(xp) { v <- xml2::xml_text(xml2::xml_find_first(a, xp)); if (is.na(v)) "" else v }
      data.frame(PMID = txt(".//PMID"), TI = txt(".//ArticleTitle"),
                 AB = txt(".//Abstract/AbstractText"), PY = txt(".//PubDate/Year"),
                 SO = txt(".//Journal/Title"), DI = txt(".//ArticleId[@IdType='doi']"),
                 AU = paste(xml2::xml_text(xml2::xml_find_all(a, ".//Author/LastName")),
                            collapse = "; "), stringsAsFactors = FALSE)
    }
    df <- purrr::map_dfr(artigos, extrair)
  }
  write.csv(df, file.path(dir_brutos, "pubmed_records.csv"), row.names = FALSE)

  if (requireNamespace("bibliometrix", quietly = TRUE) && all(c("DI", "TI", "AB") %in% names(df))) {
    try(bibliometrix::df2bib(df, file = file.path(dir_brutos, "pubmed_records.bib")), silent = TRUE)
  }
  if (requireNamespace("revtools", quietly = TRUE)) {
    try(revtools::write_bibliography(df, file.path(dir_brutos, "pubmed_records.ris"),
                                     format = "ris"), silent = TRUE)
  }
  registrar("PubMed exportado: ", nrow(df), " registros.")
})


# SEÇÃO 4 — BUSCA NA SCOPUS (API Elsevier)
# A API limita a 5000 resultados por consulta → particiona por ANO (2020-2026).
# A chave vem de CFG$scopus_api_key, da variável SCOPUS_API_KEY ou de
# 04_referencias/api_keys.txt.
# Saída: 02_dados/brutos/scopus_records.csv (+ contagens)

if (isTRUE(EXEC$busca_scopus)) tentar({
  carregar("httr", "jsonlite")
  registrar("SEÇÃO 4: busca Scopus")

  api_key <- CFG$scopus_api_key
  if (is.null(api_key) || !nzchar(api_key)) api_key <- Sys.getenv("a781a18b7cbdc608a67a5ca3456ae394", unset = "")
  if (!nzchar(api_key)) {
    fk <- file.path(dir_ref, "api_keys.txt")
    if (file.exists(fk)) {
      ln <- grep("^SCOPUS_API_KEY=", readLines(fk), value = TRUE)
      if (length(ln)) api_key <- sub("^SCOPUS_API_KEY=", "", ln[1])
    }
  }
  if (!nzchar(api_key)) stop("Chave Scopus ausente (api_keys.txt / SCOPUS_API_KEY).")

  bloco <- paste0(
    'TITLE-ABS-KEY( (stroke OR cerebrovascular OR "cerebral infarction" OR ',
    '"intracerebral hemorrhage" OR "subarachnoid hemorrhage" OR "brain ischemia" OR ',
    '"I60" OR "I61" OR "I62" OR "I63" OR "I64" OR "I69") AND ',
    '(temperature OR climate OR "heat wave" OR "cold spell" OR humidity OR ',
    '"air pollution" OR "PM2.5" OR "PM10" OR ozone OR "nitrogen dioxide" OR ',
    '"particulate matter" OR sanitation OR "drinking water" OR "solid fuel" OR ',
    '"indoor air" OR "heat island" OR flood OR wildfire OR "green space" OR ',
    '"built environment" OR noise OR "occupational exposure") ) ',
    'AND (LIMIT-TO(LANGUAGE,"English") OR LIMIT-TO(LANGUAGE,"Portuguese") OR ',
    'LIMIT-TO(LANGUAGE,"Spanish"))'
  )
  writeLines(bloco, file.path(dir_brutos, "scopus_query.txt"))

  base_url <- "https://api.elsevier.com/content/search/scopus"
  coletar <- function(q, start, count = 25) {
    httr::GET(base_url, query = list(query = q, count = count, start = start, apiKey = api_key),
              httr::add_headers(Accept = "application/json"), httr::timeout(60))
  }
  r0 <- coletar(bloco, 0, 1)
  j0 <- jsonlite::fromJSON(httr::content(r0, "text", encoding = "UTF-8"), flatten = TRUE)
  n_total <- as.integer(j0$`search-results`$`opensearch:totalResults`)

  todos <- list(); contagens <- tibble()
  for (ano in 2020:2026) {
    q <- paste0(bloco, " AND PUBYEAR = ", ano)
    r <- coletar(q, 0, 1)
    if (httr::status_code(r) != 200) next
    j <- jsonlite::fromJSON(httr::content(r, "text", encoding = "UTF-8"), flatten = TRUE)
    n_ano <- as.integer(j$`search-results`$`opensearch:totalResults`)
    contagens <- bind_rows(contagens, tibble(ano = ano, registros = n_ano))
    if (n_ano == 0) next
    starts <- seq(0, min(n_ano, 5000) - 1, by = 25)
    for (i in seq_along(starts)) {
      if (i > 1) Sys.sleep(0.25)
      ri <- tryCatch(coletar(q, starts[i], 25), error = function(e) NULL)
      if (is.null(ri) || httr::status_code(ri) != 200) next
      ji <- jsonlite::fromJSON(httr::content(ri, "text", encoding = "UTF-8"), flatten = TRUE)
      ent <- ji$`search-results`$entry
      if (!is.null(ent) && length(ent) > 0) todos[[length(todos) + 1]] <- as_tibble(ent)
    }
  }
  dados <- bind_rows(todos)
  if (nrow(dados) > 0) {
    out <- tibble(
      AU = dados$`dc:creator`, TI = dados$`dc:title`, SO = dados$`prism:publicationName`,
      PY = substr(as.character(dados$`prism:coverDate`), 1, 4), DI = dados$`prism:doi`,
      AB = if ("dc:description" %in% names(dados)) dados$`dc:description` else NA_character_,
      EID = dados$eid, DB = "SCOPUS", LA = "English", TC = dados$`citedby-count`
    )
    out <- distinct(out, EID, .keep_all = TRUE)
    write.csv(out, file.path(dir_brutos, "scopus_records.csv"), row.names = FALSE)
  }
  write.csv(contagens, file.path(dir_brutos, "scopus_count_por_ano.csv"), row.names = FALSE)
  write.csv(data.frame(base = "Scopus", data = format(Sys.time()), total_api = n_total,
                       coletados = nrow(dados)),
            file.path(dir_brutos, "scopus_count.csv"), row.names = FALSE)
  registrar("Scopus: ", nrow(dados), " de ", n_total, " registros.")
})


# SEÇÃO 5 — BUSCA NO SciELO (web scraping com Chrome headless)
# O SciELO usa um bot-shield (HTTP 403). Solução: executar o JS no navegador
# headless (Chrome/Edge) via processx::run("--dump-dom") e extrair o DOM.
# Saída: 02_dados/brutos/scielo_records.csv (+ contagem e query)

if (isTRUE(EXEC$busca_scielo)) tentar({
  carregar("xml2", "processx")
  registrar("SEÇÃO 5: busca SciELO (web scraping)")

  achar_chrome <- function() {
    cands <- c(
      "C:/Program Files/Google/Chrome/Application/chrome.exe",
      "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe",
      "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe",
      "C:/Program Files/Microsoft/Edge/Application/msedge.exe",
      unname(Sys.which(c("chrome", "google-chrome", "msedge"))))
    cands[file.exists(cands)][1]
  }
  chrome <- achar_chrome()
  if (is.na(chrome)) stop("Nenhum navegador (Chrome/Edge) encontrado para o scraping.")
  ua <- paste0("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ",
               "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

  query <- paste0(
    '(stroke OR cerebrovascular OR "cerebral infarction" OR "intracerebral hemorrhage" ',
    'OR "subarachnoid hemorrhage" OR "brain ischemia") AND (temperature OR climate OR ',
    'humidity OR "heat wave" OR "air pollution" OR "particulate matter" OR sanitation OR ',
    '"drinking water" OR "solid fuel" OR "indoor air" OR "heat island" OR flood OR ',
    'wildfire OR "green space" OR "built environment" OR noise OR "occupational exposure")')
  writeLines(query, file.path(dir_brutos, "scielo_query.txt"))

  tmp_html <- file.path(dir_log, "scielo_tmp.html")
  prof_dir <- file.path(dir_proc, ".chrome_scielo")
  dir.create(prof_dir, showWarnings = FALSE, recursive = TRUE)
  baixar_pagina <- function(from, count = 50, tentativas = 2) {
    url <- paste0("https://search.scielo.org/?q=", utils::URLencode(query, reserved = TRUE),
                  "&lang=en&count=", count, "&from=", from, "&output=site")
    for (t in seq_len(tentativas)) {
      ok <- tryCatch({
        processx::run(chrome,
          args = c("--headless", "--disable-gpu", "--no-sandbox", "--no-first-run",
                   "--disable-extensions", "--disable-background-networking",
                   paste0("--user-data-dir=", prof_dir), paste0("--user-agent=", ua),
                   "--virtual-time-budget=20000", "--dump-dom", url),
          stdout = tmp_html, stderr = "|", timeout = 150)
        TRUE
      }, error = function(e) { message("Chrome: ", conditionMessage(e)); FALSE })
      if (ok && file.exists(tmp_html) && file.info(tmp_html)$size > 20000) return(tmp_html)
      Sys.sleep(2)
    }
    NULL
  }
  parsear <- function(html_file) {
    d <- xml2::read_html(html_file)
    itens <- xml2::xml_find_all(d, "//div[normalize-space(@class)='item']")
    if (length(itens) == 0) return(NULL)
    purrr::map_dfr(itens, function(it) {
      titulo  <- xml2::xml_text(xml2::xml_find_first(it, ".//strong[contains(@class,'title')]"))
      autores <- xml2::xml_text(xml2::xml_find_first(it, ".//div[contains(@class,'authors')]"))
      fonte   <- xml2::xml_text(xml2::xml_find_first(it, ".//div[contains(@class,'source')]"))
      doi     <- xml2::xml_text(xml2::xml_find_first(it, ".//span[contains(@class,'DOIResults')]"))
      pid     <- xml2::xml_attr(it, "id")
      ano     <- suppressWarnings(as.integer(stringr::str_extract(fonte, "(19|20)\\d{2}")))
      tibble(AU = stringr::str_squish(autores), TI = stringr::str_squish(titulo),
             SO = stringr::str_squish(stringr::str_remove(fonte, "\\b(19|20)\\d{2}.*$")),
             PY = ano, DI = stringr::str_remove(stringr::str_squish(doi),
             "^https?://(dx\\.)?doi\\.org/"), AB = NA_character_, DB = "SCIELO", PID = pid)
    })
  }

  # paginação adaptativa (a contagem exibida no SciELO é imprecisa)
  p0 <- baixar_pagina(0)
  if (is.null(p0)) stop("SciELO: falha ao capturar a primeira página.")
  todos <- list()
  d0 <- tryCatch(parsear(p0), error = function(e) NULL)
  if (!is.null(d0) && nrow(d0) > 0) todos[[1]] <- d0
  from <- if (is.null(d0)) 50 else nrow(d0)
  repetidos <- 0
  while (from <= 5000 && repetidos < 3) {
    f <- baixar_pagina(from)
    d <- if (is.null(f)) NULL else tryCatch(parsear(f), error = function(e) NULL)
    if (is.null(d) || nrow(d) == 0) { repetidos <- repetidos + 1; from <- from + 50; next }
    repetidos <- 0; todos[[length(todos) + 1]] <- d
    from <- from + nrow(d); Sys.sleep(1)
  }
  dados <- bind_rows(todos) |> distinct(PID, .keep_all = TRUE)
  dados <- dados |> filter(!is.na(PY), PY >= 2020, PY <= 2026) |>
    select(AU, TI, SO, PY, DI, AB, DB)
  write.csv(dados, file.path(dir_brutos, "scielo_records.csv"), row.names = FALSE)
  write.csv(data.frame(base = "SciELO", data = format(Sys.time()), coletados = nrow(dados)),
            file.path(dir_brutos, "scielo_count.csv"), row.names = FALSE)
  registrar("SciELO: ", nrow(dados), " registros (2020-2026).")
})


# SEÇÃO 6 — DEDUPLICAÇÃO E PLANILHAS DE TRIAGEM
# Importa as bases, padroniza colunas, remove duplicatas (DOI exato + título
# normalizado) e gera as planilhas de triagem para dois revisores.
# Saída: 02_dados/processados/registros_deduplicados.csv,
#        planilhas revisor1/revisor2, duplicatas_removidas.csv

if (isTRUE(EXEC$deduplicacao)) tentar({
  carregar("revtools")
  registrar("SEÇÃO 6: deduplicação e planilhas de triagem")

  arquivos <- list.files(dir_brutos, pattern = "\\.(csv|ris|bib|txt)$", full.names = TRUE)
  arquivos <- arquivos[!grepl("query|count|termos_mesh", basename(arquivos))]
  stopifnot(length(arquivos) > 0)

  importar <- function(f) {
    ext <- tolower(tools::file_ext(f))
    if (ext == "csv") {
      d <- tryCatch(readr::read_csv(f, show_col_types = FALSE), error = function(e) NULL)
      if (!is.null(d) && "TI" %in% names(d)) {
        return(tibble(
          title = d[["TI"]], abstract = if ("AB" %in% names(d)) d[["AB"]] else NA_character_,
          doi = if ("DI" %in% names(d)) d[["DI"]] else NA_character_,
          year = if ("PY" %in% names(d)) as.character(d[["PY"]]) else NA_character_,
          author = if ("AU" %in% names(d)) d[["AU"]] else NA_character_,
          journal = if ("SO" %in% names(d)) d[["SO"]] else NA_character_,
          base_origem = tools::file_path_sans_ext(basename(f))))
      }
      return(NULL)
    }
    tryCatch({ x <- revtools::read_bibliography(f)
               x$base_origem <- tools::file_path_sans_ext(basename(f)); x },
             error = function(e) { message("Falha ao ler ", f, ": ", conditionMessage(e)); NULL })
  }
  lista <- compact(purrr::map(arquivos, importar))
  dados <- bind_rows(lista)
  for (col in c("title", "abstract", "doi", "year", "author", "journal")) {
    if (!col %in% names(dados)) dados[[col]] <- NA_character_
  }
  dados <- dados |>
    mutate(title = stringr::str_squish(as.character(title)),
           abstract = stringr::str_squish(as.character(abstract)),
           doi = tolower(stringr::str_remove(as.character(doi), "^https?://(dx\\.)?doi\\.org/")),
           ano = suppressWarnings(as.integer(stringr::str_extract(as.character(year), "\\d{4}")))) |>
    filter(!is.na(title), title != "") |>
    filter(!is.na(ano), ano >= 2020, ano <= 2026)

  dup_doi <- duplicated(dados$doi) & !is.na(dados$doi) & dados$doi != ""
  norm_title <- gsub("[^a-z0-9]", "", tolower(dados$title))
  dup_titulo <- duplicated(norm_title)
  dados_exato <- dados[!(dup_doi | dup_titulo), ]
  duplicatas <- dados[dup_doi | dup_titulo, ]

  # similaridade fuzzy do revtools é O(n²): só para conjuntos pequenos
  matches <- NULL
  if (nrow(dados_exato) <= 5000) {
    matches <- tryCatch(revtools::find_duplicates(as.data.frame(dados_exato),
                          match_variable = "title", method = "osa", threshold = 5,
                          to_lower = TRUE, remove_punctuation = TRUE),
                        error = function(e) NULL)
  } else {
    registrar("n > 5000: dedup fuzzy (revtools) omitida; usados DOI + título.")
  }
  dados_dedup <- dados_exato
  if (!is.null(matches)) {
    dedup_fuzzy <- tryCatch(revtools::extract_unique_references(as.data.frame(dados_exato), matches),
                            error = function(e) NULL)
    if (!is.null(dedup_fuzzy) && nrow(dedup_fuzzy) > 0) dados_dedup <- dedup_fuzzy
  }
  write.csv(dados_dedup, file.path(dir_proc, "registros_deduplicados.csv"), row.names = FALSE)
  if (nrow(duplicatas) > 0) write.csv(duplicatas, file.path(dir_proc, "duplicatas_removidas.csv"), row.names = FALSE)

  planilha <- dados_dedup |>
    transmute(id = row_number(), titulo = title, resumo = abstract, doi, ano,
              autores = author, periodico = journal, base_origem,
              revisor1_decisao = "", revisor1_motivo = "",
              revisor2_decisao = "", revisor2_motivo = "", consenso = "")
  write.csv(planilha, file.path(dir_proc, "triagem_titulo_abstrato_revisor1.csv"), row.names = FALSE)
  write.csv(planilha, file.path(dir_proc, "triagem_titulo_abstrato_revisor2.csv"), row.names = FALSE)

  ident <- dados |> count(base_origem, name = "n_registros") |>
    bind_rows(tibble(base_origem = "TOTAL bruto", n_registros = nrow(dados))) |>
    bind_rows(tibble(base_origem = "Duplicatas removidas", n_registros = nrow(duplicatas))) |>
    bind_rows(tibble(base_origem = "Após deduplicação", n_registros = nrow(dados_dedup)))
  write.csv(ident, file.path(dir_tab, "prisma_identificacao.csv"), row.names = FALSE)

  # tabela-base do PRISMA (identificação/duplicação/triagem)
  readr::write_csv(tibble(
    etapa = c("Registros identificados nas bases (PubMed+Scopus+SciELO)",
              "Duplicatas removidas", "Registros triados (título/abstrato)"),
    n = c(nrow(dados), nrow(duplicatas), nrow(dados_dedup))),
    file.path(dir_tab, "prisma_contagens.csv"))
  registrar("Deduplicação: ", nrow(dados), " -> ", nrow(dados_dedup), " únicos.")
})


# SEÇÃO 7 — BIBLIOMETRIA (bibliometrix)
# Produção anual, Bradford, Lotka, países, mapa temático, estrutura conceitual
# e redes. Fundamentação: Aria & Cuccurullo (2017); Donthu et al. (2021).
# Saída: 03_resultados/bibliometria/

if (isTRUE(EXEC$bibliometria)) tentar({
  carregar("bibliometrix")
  registrar("SEÇÃO 7: bibliometria")

  ler_base <- function(f) {
    d <- tryCatch(readr::read_csv(f, show_col_types = FALSE), error = function(e) NULL)
    if (is.null(d) || !"TI" %in% names(d)) return(NULL)
    tibble(
      AU = if ("AU" %in% names(d)) d$AU else NA_character_, TI = d$TI,
      SO = if ("SO" %in% names(d)) d$SO else NA_character_,
      JI = if ("JI" %in% names(d)) d$JI else (if ("SO" %in% names(d)) d$SO else NA_character_),
      J9 = if ("J9" %in% names(d)) d$J9 else (if ("SO" %in% names(d)) d$SO else NA_character_),
      PY = if ("PY" %in% names(d)) as.character(d$PY) else NA_character_,
      DI = if ("DI" %in% names(d)) d$DI else NA_character_,
      AB = if ("AB" %in% names(d)) d$AB else NA_character_,
      TC = if ("TC" %in% names(d)) suppressWarnings(as.numeric(d$TC)) else NA_real_,
      CR = if ("CR" %in% names(d)) d$CR else NA_character_,
      DE = if ("DE" %in% names(d)) d$DE else NA_character_,
      ID = if ("ID" %in% names(d)) d$ID else NA_character_,
      AU_UN = if ("AU_UN" %in% names(d)) d$AU_UN else NA_character_,
      AU_CO = if ("AU_CO" %in% names(d)) d$AU_CO else NA_character_,
      DB = if ("DB" %in% names(d)) d$DB else tools::file_path_sans_ext(basename(f)),
      LA = if ("LA" %in% names(d)) d$LA else NA_character_)
  }
  arquivos <- list.files(dir_brutos, pattern = "_records\\.csv$", full.names = TRUE)
  M <- bind_rows(lapply(arquivos, ler_base)) |>
    filter(!is.na(TI), TI != "") |> distinct(TI, .keep_all = TRUE)

  if (nrow(M) == 0) {
    message("Sem registros em 02_dados/brutos/*_records.csv.")
  } else {
    M <- as.data.frame(M)
    saveRDS(M, file.path(dir_bib, "dados_bibliometricos.rds"))
    resultados <- bibliometrix::biblioAnalysis(M, sep = ";")
    sink(file.path(dir_bib, "sumario_bibliometria.txt"))
    print(summary(resultados, k = 15, pause = FALSE))
    sink()

    prod_ano <- as.data.frame(table(M$PY)); names(prod_ano) <- c("ano", "artigos")
    write.csv(prod_ano, file.path(dir_bib, "producao_anual.csv"), row.names = FALSE)
    g1 <- ggplot(prod_ano, aes(as.integer(ano), artigos)) + geom_col(fill = "#2c7fb8") +
      labs(x = "Ano", y = "Artigos", title = "Produção científica anual") + theme_minimal()
    ggsave(file.path(dir_bib, "producao_anual.png"), g1, width = 8, height = 5, dpi = 300)

    brad <- tryCatch(bibliometrix::bradford(M), error = function(e) NULL)
    if (!is.null(brad) && !is.null(brad$table))
      write.csv(brad$table, file.path(dir_bib, "bradford_periodicos.csv"), row.names = FALSE)
    if (!is.null(resultados$Authors))
      write.csv(resultados$Authors, file.path(dir_bib, "lotka_autores.csv"), row.names = FALSE)

    M_paises <- tryCatch(bibliometrix::metaTagExtraction(M, Field = "AU_CO", sep = ";"),
                         error = function(e) M)
    paises_tab <- table(M_paises$AU_CO, useNA = "no")
    if (length(paises_tab) > 0) {
      paises <- data.frame(pais = names(paises_tab), artigos = as.integer(paises_tab)) |>
        (\(x) x[order(-x$artigos), ])()
      write.csv(paises, file.path(dir_bib, "paises_producao.csv"), row.names = FALSE)
    }

    try({
      tm <- bibliometrix::thematicMap(M, field = "DE", n = 250, minfreq = 5)
      ggsave(file.path(dir_bib, "mapa_tematico.png"), tm$map, width = 8, height = 7, dpi = 300)
      if (!is.null(tm$words))
        write.csv(tm$words, file.path(dir_bib, "mapa_tematico_termos.csv"), row.names = FALSE)
    }, silent = TRUE)
    try({
      cs <- bibliometrix::conceptualStructure(M, field = "DE", method = "MCA", minfreq = 5, ngrams = 1)
      ggsave(file.path(dir_bib, "estrutura_conceitual.png"), cs$graph_terms,
             width = 9, height = 7, dpi = 300)
    }, silent = TRUE)
    try({
      NetMatrix <- bibliometrix::biblioNetwork(M, analysis = "co-occurrences",
                                               network = "keywords", sep = ";")
      png(file.path(dir_bib, "rede_palavras_chave.png"), width = 2000, height = 1600, res = 150)
      bibliometrix::networkPlot(NetMatrix, n = 50, Title = "Coocorrência de palavras-chave",
                                type = "fruchterman", size = 10, remove.multiple = FALSE,
                                labelsize = 0.8)
      dev.off()
    }, silent = TRUE)
    try({
      NetPais <- bibliometrix::biblioNetwork(M_paises, analysis = "collaboration",
                                             network = "countries", sep = ";")
      png(file.path(dir_bib, "rede_paises.png"), width = 2000, height = 1600, res = 150)
      bibliometrix::networkPlot(NetPais, n = 40, Title = "Colaboração entre países",
                                type = "fruchterman", size = 8, remove.multiple = FALSE,
                                labelsize = 0.7)
      dev.off()
    }, silent = TRUE)
    registrar("Bibliometria: ", nrow(M), " registros analisados.")
  }
})


# SEÇÃO 8 — ENRIQUECIMENTO DE RESUMOS AUSENTES (PubMed por DOI)
# ~70% dos registros (sobretudo Scopus) estão sem resumo. Este passo busca o
# resumo no PubMed pelo DOI (E-utilities/rentrez), de forma incremental e
# retomável. A chave Scopus do projeto não retorna resumos (Abstract Retrieval),
# por isso usamos o PubMed.
# Saída: 02_dados/processados/abstracts_enriquecidos.csv e
#        registros_deduplicados_enriquecidos.csv

if (isTRUE(EXEC$enriquecer_abstracts)) tentar({
  carregar("rentrez", "xml2")
  registrar("SEÇÃO 8: enriquecimento de resumos (PubMed)")

  dados <- readr::read_csv(file.path(dir_proc, "registros_deduplicados.csv"),
                           show_col_types = FALSE) |>
    mutate(id = row_number())
  sem_resumo <- is.na(dados$abstract) | trimws(as.character(dados$abstract)) == ""
  alvos <- dados[sem_resumo & !is.na(dados$doi) & dados$doi != "", ]

  if (isTRUE(CFG$so_incluidos_enriq)) {
    f_inc <- file.path(dir_proc, "incluidos_titulo_resumo.csv")
    if (file.exists(f_inc)) {
      ids_inc <- readr::read_csv(f_inc, show_col_types = FALSE)$id
      alvos <- alvos[alvos$id %in% ids_inc, ]
    }
  }

  arq_enriq <- file.path(dir_proc, "abstracts_enriquecidos.csv")
  ja_feitos <- if (file.exists(arq_enriq)) unique(readr::read_csv(arq_enriq, show_col_types = FALSE)$doi) else character(0)
  alvos <- alvos[!(alvos$doi %in% ja_feitos), ]
  if (CFG$limite_enriquecer > 0) alvos <- head(alvos, CFG$limite_enriquecer)

  buscar_pubmed <- function(doi, tentativas = 3) {
    for (t in seq_len(tentativas)) {
      r <- tryCatch({
        q <- rentrez::entrez_search(db = "pubmed", term = paste0('"', doi, '"[DOI]'), retmax = 1)
        if (length(q$ids) == 0) return(list(status = "sem_pmid", pmid = NA_character_, abstract = NA_character_))
        rec <- rentrez::entrez_fetch(db = "pubmed", id = q$ids[1], rettype = "abstract", retmode = "xml")
        x <- xml2::read_xml(rec)
        nodes <- xml2::xml_find_all(x, "//Abstract/AbstractText")
        txt <- vapply(nodes, function(n) {
          lab <- xml2::xml_attr(n, "Label"); tt <- xml2::xml_text(n)
          if (!is.na(lab)) paste0(lab, ": ", tt) else tt }, character(1))
        ab <- if (length(txt)) paste(txt, collapse = " ") else NA_character_
        list(status = if (is.null(ab) || is.na(ab) || ab == "") "sem_abstract" else "ok",
             pmid = q$ids[1], abstract = ab)
      }, error = function(e) { if (t < tentativas) Sys.sleep(2 * t)
        list(status = "erro", pmid = NA_character_, abstract = NA_character_) })
      return(r)
    }
  }

  if (nrow(alvos) > 0) {
    buffer <- list(); n_ok <- 0
    for (i in seq_len(nrow(alvos))) {
      res <- buscar_pubmed(alvos$doi[i])
      buffer[[length(buffer) + 1]] <- tibble(id = alvos$id[i], doi = alvos$doi[i],
        pmid = res$pmid, status = res$status, abstract = res$abstract,
        data = format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
      if (res$status == "ok") n_ok <- n_ok + 1
      if (i %% 25 == 0 || i == nrow(alvos)) {
        novo <- bind_rows(buffer)
        if (file.exists(arq_enriq)) novo <- bind_rows(readr::read_csv(arq_enriq, show_col_types = FALSE), novo)
        readr::write_csv(distinct(novo, doi, .keep_all = TRUE), arq_enriq)
        registrar("  enriquecimento ", i, "/", nrow(alvos), " (ok=", n_ok, ")")
        buffer <- list()
      }
      Sys.sleep(CFG$pausa_enriquecer)
    }
  }

  enriq <- if (file.exists(arq_enriq)) readr::read_csv(arq_enriq, show_col_types = FALSE) else
    tibble(id = integer(), doi = character(), status = character(), abstract = character())
  mapa <- enriq |> filter(status == "ok", !is.na(abstract), abstract != "") |>
    select(id, abstract_novo = abstract) |> distinct(id, .keep_all = TRUE)
  dados_enriq <- dados |> left_join(mapa, by = "id") |>
    mutate(abstract = ifelse(is.na(abstract) | trimws(as.character(abstract)) == "",
                             ifelse(is.na(abstract_novo), abstract, abstract_novo), abstract)) |>
    select(-abstract_novo)
  readr::write_csv(dados_enriq, file.path(dir_proc, "registros_deduplicados_enriquecidos.csv"))
  registrar("Enriquecimento: ausentes ", sum(sem_resumo), " -> ",
            sum(is.na(dados_enriq$abstract) | trimws(as.character(dados_enriq$abstract)) == ""))
})


# SEÇÃO 9 — PREPARAÇÃO DA TRIAGEM POR TÓPICOS (lotes do LDA)
# O modelo no conjunto completo (14.978 registros) não termina em tempo hábil.
# Solução: preparar, OFFLINE, um LDA por LOTE (base × ano; lotes pequenos
# agrupados) e salvar cada lote como objeto 'screen_topics_progress' já com o
# modelo pronto — assim o app da SEÇÃO 10 abre instantaneamente.
# Fundamentação: Westgate (2019); Westgate & Lindenmayer (2017); Cochrane cap. 4.
# Saída: 02_dados/processados/topicos/lote_XX.rds + lotes_indice.csv

if (isTRUE(EXEC$topicos_preparar)) tentar({
  carregar("revtools", "topicmodels")
  registrar("SEÇÃO 9: preparação dos lotes de tópicos")

  arq_enriq <- file.path(dir_proc, "registros_deduplicados_enriquecidos.csv")
  arq_dedup <- file.path(dir_proc, "registros_deduplicados.csv")
  arq_in <- if (file.exists(arq_enriq)) arq_enriq else arq_dedup
  dados <- readr::read_csv(arq_in, show_col_types = FALSE)
  if (!"abstract" %in% names(dados)) dados$abstract <- NA_character_
  dados <- dados |> mutate(id = row_number(), label = sprintf("ref_%05d", id))
  if (isTRUE(CFG$teste_topicos)) dados <- dplyr::slice_head(dados, n = 300)

  nome_base <- c(pubmed_records = "PubMed", scopus_records = "Scopus", scielo_records = "SciELO")
  dados$base_nome <- ifelse(dados$base_origem %in% names(nome_base),
                            nome_base[dados$base_origem], dados$base_origem)
  dados$chave <- if (CFG$estrategia_topicos == "base") dados$base_nome else
    paste(dados$base_nome, dados$ano, sep = "__")
  contagem <- dados |> count(chave)
  pequenas <- contagem$chave[contagem$n < CFG$min_tam_lote]
  dados$chave2 <- ifelse(dados$chave %in% pequenas,
                         paste0(dados$base_nome, "__pequenos"), dados$chave)
  lotes_list <- split(dados, dados$chave2)
  lotes_list <- lotes_list[order(names(lotes_list))]
  names(lotes_list) <- sprintf("lote_%02d", seq_along(lotes_list))
  so_lotes <- if (nzchar(CFG$lotes_alvo)) trimws(strsplit(CFG$lotes_alvo, ",")[[1]]) else character(0)

  preparar_lote <- function(df) {
    raw <- as.data.frame(df[, c("id", "label", "title", "abstract", "doi", "year",
                                "author", "journal", "base_origem", "ano")],
                          stringsAsFactors = FALSE)
    raw$title[is.na(raw$title)] <- ""; raw$abstract[is.na(raw$abstract)] <- ""
    colnames(raw) <- revtools:::clean_names(colnames(raw))
    raw <- revtools:::add_required_columns(raw)
    stop_words <- unique(c(revtools::revwords(), REMOVE_WORDS))
    grouped <- revtools:::create_grouped_dataframe(raw, "label", c("title", "abstract"))
    dtm <- revtools::make_dtm(grouped$text, stop_words = stop_words,
                              min_freq = CFG$min_freq, max_freq = CFG$max_freq,
                              bigram_check = CFG$bigramas, bigram_quantile = CFG$bigram_quantile)
    if (nrow(dtm) < nrow(grouped)) grouped <- grouped[as.numeric(dtm$dimnames$Docs), , drop = FALSE]
    k <- max(2L, min(as.integer(CFG$n_topics), max(2L, floor(nrow(grouped) / 8))))
    model <- revtools::run_topic_model(dtm, "lda", n_topics = k, iterations = CFG$iterations)
    plot_ready <- revtools:::build_plot_data(grouped, dtm, model, hide_names = FALSE)
    grouped$topic <- topicmodels::topics(model)
    raw$topic <- grouped$topic[match(raw$label, grouped$label)]
    obj <- list(raw = raw, stopwords = stop_words,
                columns = revtools:::get_topic_colnames(raw), grouped = grouped,
                dtm = dtm, model = model, plot_ready = plot_ready)
    class(obj) <- "screen_topics_progress"
    list(obj = obj, k = k, n_docs = nrow(dtm), n_termos = ncol(dtm))
  }

  arq_indice <- file.path(dir_top, "lotes_indice.csv")
  indice_antigo <- if (file.exists(arq_indice)) readr::read_csv(arq_indice, show_col_types = FALSE) else
    tibble(lote = character(), base = character(), anos = character(), n = integer(),
           k = integer(), n_termos = integer(), arquivo = character(), tempo_s = numeric())
  resultados <- list()
  for (i in seq_along(lotes_list)) {
    id_lote <- names(lotes_list)[i]; df <- lotes_list[[i]]
    if (length(so_lotes) && !(id_lote %in% so_lotes)) next
    f_out <- file.path(dir_top, paste0(id_lote, ".rds"))
    if (file.exists(f_out) && !CFG$forcar_topicos) {
      antigo <- indice_antigo[indice_antigo$lote == id_lote, ]
      if (nrow(antigo) == 1) resultados[[id_lote]] <- antigo
      next
    }
    registrar("  preparando ", id_lote, " [", unique(df$chave2), "] n=", nrow(df))
    t0 <- Sys.time()
    res <- tryCatch(preparar_lote(df), error = function(e) {
      registrar("  ERRO em ", id_lote, ": ", conditionMessage(e)); NULL })
    if (is.null(res)) next
    saveRDS(res$obj, f_out)
    resultados[[id_lote]] <- tibble(
      lote = id_lote, base = paste(sort(unique(df$base_nome)), collapse = "+"),
      anos = paste(range(df$ano, na.rm = TRUE), collapse = "-"), n = nrow(df),
      k = res$k, n_termos = res$n_termos, arquivo = basename(f_out),
      tempo_s = round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1))
  }
  indice_novo <- bind_rows(resultados)
  indice <- if (nrow(indice_novo) > 0)
    bind_rows(filter(indice_antigo, !(lote %in% indice_novo$lote)), indice_novo) |> arrange(lote)
  else indice_antigo
  if (nrow(indice) > 0) readr::write_csv(indice, arq_indice)
  registrar("Lotes no índice: ", nrow(indice))
})


# SEÇÃO 10 — APP DE TRIAGEM POR TÓPICOS (revtools::screen_topics) — RStudio
# Abre o app Shiny por lote. EXIGE sessão interativa (NÃO roda no terminal).
# As decisões são salvas por lote e é possível retomar. A triagem assistida NÃO
# substitui a manual (Cochrane cap. 4).
#
# Uso (no console do RStudio, após rodar a SEÇÃO 9):
#   status_lotes()
#   triar_lote("lote_01")
#   triar_pendentes()
#   consolidar_incluidos()

status_lotes <- function() {
  if (!file.exists(file.path(dir_top, "lotes_indice.csv")))
    stop("Índice de lotes ausente. Rode a SEÇÃO 9 (topicos_preparar).")
  ind <- readr::read_csv(file.path(dir_top, "lotes_indice.csv"), show_col_types = FALSE)
  ind$preparado <- file.exists(file.path(dir_top, paste0(ind$lote, ".rds")))
  ind$triado <- file.exists(file.path(dir_dec, paste0(ind$lote, ".rds")))
  ind$status <- ifelse(ind$triado, "triado", ifelse(ind$preparado, "pendente", "sem modelo"))
  ind |> select(lote, base, anos, n, k, status) |> arrange(lote) |> as.data.frame()
}

atualizar_master <- function(dec) {
  arq_master <- file.path(dir_proc, "triagem_topicos_decisoes.csv")
  m <- if (file.exists(arq_master)) {
    antigo <- readr::read_csv(arq_master, show_col_types = FALSE)
    bind_rows(antigo[!(antigo$lote %in% unique(dec$lote)), ], dec)
  } else dec
  m <- m[!duplicated(m$id, fromLast = TRUE), ]
  readr::write_csv(m, arq_master); invisible(m)
}

consolidar_incluidos <- function() {
  arq_master <- file.path(dir_proc, "triagem_topicos_decisoes.csv")
  if (!file.exists(arq_master)) { message("Sem decisões de triagem por tópicos."); return(invisible(NULL)) }
  m <- readr::read_csv(arq_master, show_col_types = FALSE)
  arq_dedup <- file.path(dir_proc, "registros_deduplicados.csv")
  if (file.exists(arq_dedup)) {
    meta <- readr::read_csv(arq_dedup, show_col_types = FALSE) |>
      mutate(id = row_number()) |> select(id, resumo = abstract, autores = author, periodico = journal)
    m <- m |> left_join(meta, by = "id")
  }
  inc <- m |> filter(decisao == "incluido") |> arrange(id)
  saveRDS(inc, file.path(dir_proc, "incluidos_titulo_resumo.rds"))
  readr::write_csv(inc, file.path(dir_proc, "incluidos_titulo_resumo.csv"))
  readr::write_csv(
    m |> group_by(lote) |> summarise(n = n(), incluidos = sum(decisao == "incluido", na.rm = TRUE),
      excluidos = sum(decisao == "excluido", na.rm = TRUE), sem_decisao = sum(is.na(decisao)),
      .groups = "drop"),
    file.path(dir_top, "resumo_decisoes_por_lote.csv"))
  registrar("Consolidado (tópicos): ", nrow(inc), " incluídos.")
  invisible(inc)
}

triar_lote <- function(lote) {
  ind <- status_lotes()
  if (!(lote %in% ind$lote)) stop("Lote '", lote, "' não existe.")
  if (ind$status[ind$lote == lote] == "sem modelo")
    stop("Lote '", lote, "' sem modelo. Rode a SEÇÃO 9 com lotes_alvo='", lote, "'.")
  f_dec <- file.path(dir_dec, paste0(lote, ".rds"))
  f_abrir <- if (file.exists(f_dec)) f_dec else file.path(dir_top, paste0(lote, ".rds"))
  obj <- readRDS(f_abrir)
  res <- revtools::screen_topics(x = obj, remove_words = REMOVE_WORDS, max_file_size = 100)
  if (is.null(res) || is.null(res$raw)) {
    warning("App encerrado sem retornar dados; use o botão 'Exit' para salvar.")
    return(invisible(NULL))
  }
  saveRDS(res, f_dec)
  dec <- res$raw |> transmute(lote = lote, id = as.integer(id), label = label,
    titulo = title, doi = doi, base_origem = base_origem, ano = ano,
    screened_topics = screened_topics, decisao = normalizar_decisao(screened_topics),
    observacoes = notes)
  readr::write_csv(dec, file.path(dir_dec, paste0(lote, ".csv")))
  atualizar_master(dec); consolidar_incluidos()
  cat("\nLote", lote, "salvo:", sum(dec$decisao == "incluido", na.rm = TRUE),
      "incluídos;", sum(dec$decisao == "excluido", na.rm = TRUE), "excluídos.\n")
  invisible(res)
}

triar_pendentes <- function() {
  ind <- status_lotes(); pend <- ind$lote[ind$status == "pendente"]
  if (!length(pend)) { cat("Nenhum lote pendente.\n"); return(invisible(NULL)) }
  for (l in pend) { cat("\n=== Lote ", l, " ===\n"); triar_lote(l) }
  invisible(status_lotes())
}

if (isTRUE(EXEC$topicos_app)) tentar({
  carregar("revtools", "shiny", "shinydashboard", "plotly", "viridis")
  if (!interactive()) {
    registrar("SEÇÃO 10 ignorada: o app exige RStudio (sessão interativa).")
    message("A SEÇÃO 10 (app de tópicos) exige o RStudio. Use: triar_pendentes()")
  } else {
    registrar("SEÇÃO 10: abrindo triagem por tópicos")
    triar_pendentes()
  }
})


# SEÇÃO 11 — CONSOLIDAÇÃO DA TRIAGEM TÍTULO/RESUMO + KAPPA DE COHEN
# Une as decisões dos dois revisores (planilhas) e da triagem assistida por
# tópicos, resolve o consenso, calcula o kappa e escreve a lista de incluídos.
# Saída: triagem_consenso_titulo_resumo.csv, discordancias_titulo_resumo.csv,
#        incluidos_titulo_resumo.rds/.csv, kappa_titulo_resumo.csv

if (isTRUE(EXEC$consolidar_triagem)) tentar({
  registrar("SEÇÃO 11: consolidação da triagem título/resumo")

  dados <- readr::read_csv(file.path(dir_proc, "registros_deduplicados.csv"),
                           show_col_types = FALSE) |>
    mutate(id = row_number()) |>
    select(id, titulo = title, resumo = abstract, doi, ano, autores = author,
           periodico = journal, base_origem)

  ler_revisor <- function(arquivo, coluna_preferida, nome) {
    if (!file.exists(arquivo)) return(tibble(id = integer(), decisao = character()))
    d <- readr::read_csv(arquivo, show_col_types = FALSE)
    col <- if (coluna_preferida %in% names(d)) coluna_preferida else {
      cand <- names(d)[grepl("decis", names(d), ignore.case = TRUE)]
      if (!length(cand)) return(tibble(id = as.integer(d$id), decisao = NA_character_))
      n_ok <- vapply(cand, function(c) sum(!is.na(d[[c]]) & trimws(as.character(d[[c]])) != ""), numeric(1))
      cand[which.max(n_ok)]
    }
    tibble(id = as.integer(d$id), decisao = normalizar_decisao(d[[col]])) |>
      distinct(id, .keep_all = TRUE)
  }
  r1 <- ler_revisor(file.path(dir_proc, "triagem_titulo_abstrato_revisor1.csv"),
                    "revisor1_decisao", "revisor 1")
  r2 <- ler_revisor(file.path(dir_proc, "triagem_titulo_abstrato_revisor2.csv"),
                    "revisor2_decisao", "revisor 2")

  arq_top <- file.path(dir_proc, "triagem_topicos_decisoes.csv")
  top <- if (file.exists(arq_top)) {
    tr <- readr::read_csv(arq_top, show_col_types = FALSE)
    ct <- if ("decisao" %in% names(tr)) "decisao" else "screened_topics"
    tr |> mutate(decisao_topico = normalizar_decisao(.data[[ct]])) |>
      select(id, decisao_topico) |> distinct(id, .keep_all = TRUE)
  } else tibble(id = integer(), decisao_topico = character())

  cons <- dados |>
    left_join(r1, by = "id") |> rename(r1 = decisao) |>
    left_join(r2, by = "id") |> rename(r2 = decisao) |>
    left_join(top, by = "id") |>
    mutate(consenso = case_when(
             !is.na(r1) & !is.na(r2) & r1 == r2 ~ r1,
             !is.na(r1) & !is.na(r2) & r1 != r2 ~ "discordancia",
             is.na(r1) & is.na(r2) & !is.na(decisao_topico) ~ decisao_topico,
             TRUE ~ "pendente"),
           origem = case_when(consenso == "discordancia" ~ "dois revisores (discordância)",
                              consenso == "pendente" ~ "sem decisão",
                              !is.na(r1) & !is.na(r2) ~ "dois revisores (concordância)",
                              TRUE ~ "triagem assistida por tópicos"))

  kk <- kappa_cohen(cons$r1, cons$r2)
  readr::write_csv(tibble(n_pares_decididos = kk$n, proporcao_observada = round(kk$po, 4),
    proporcao_esperada = round(kk$pe, 4), kappa = round(kk$kappa, 4),
    ic95_inf = round(kk$ic95_inf, 4), ic95_sup = round(kk$ic95_sup, 4),
    interpretacao = kk$interpretacao), file.path(dir_tab, "kappa_titulo_resumo.csv"))
  readr::write_csv(resumo_acordo(cons$r1, cons$r2), file.path(dir_tab, "acordo_titulo_resumo.csv"))
  readr::write_csv(cons, file.path(dir_proc, "triagem_consenso_titulo_resumo.csv"))
  readr::write_csv(cons |> filter(consenso == "discordancia"),
                   file.path(dir_proc, "discordancias_titulo_resumo.csv"))
  inc <- cons |> filter(consenso == "incluido") |> arrange(id)
  saveRDS(inc, file.path(dir_proc, "incluidos_titulo_resumo.rds"))
  readr::write_csv(inc, file.path(dir_proc, "incluidos_titulo_resumo.csv"))

  atualizar_prisma(excluidos_ta = sum(cons$consenso == "excluido"),
                   pendentes_ta = sum(cons$consenso == "pendente"),
                   textos_avaliados = nrow(inc))
  registrar("Triagem título/resumo: incluídos=", nrow(inc),
            " excluídos=", sum(cons$consenso == "excluido"),
            " discordâncias=", sum(cons$consenso == "discordancia"),
            " pendentes=", sum(cons$consenso == "pendente"),
            " | kappa=", round(kk$kappa, 3), " (", kk$interpretacao, ")")
})


# SEÇÃO 12 — TRIAGEM DE TEXTO COMPLETO (fase 2)
# Cria as planilhas de texto completo para dois revisores, consolida com kappa e
# tabula os motivos de exclusão (PRISMA 2020, item 16b).
# Saída: triagem_texto_completo_revisor{1,2}.csv,
#        incluidos_texto_completo.rds/.csv, kappa_texto_completo.csv,
#        motivos_exclusao_texto_completo.csv

if (isTRUE(EXEC$texto_completo)) tentar({
  registrar("SEÇÃO 12: triagem de texto completo")

  MOTIVOS <- c("populacao_inadequada", "exposicao_nao_ambiental", "desfecho_nao_dcv",
               "desenho_inadequado", "idioma_nao_elegivel", "dados_insuficientes",
               "texto_completo_indisponivel", "duplicata", "fora_do_periodo", "outro")

  f_inc_csv <- file.path(dir_proc, "incluidos_titulo_resumo.csv")
  f_inc_rds <- file.path(dir_proc, "incluidos_titulo_resumo.rds")
  inc <- if (file.exists(f_inc_csv)) readr::read_csv(f_inc_csv, show_col_types = FALSE)
         else if (file.exists(f_inc_rds)) as_tibble(readRDS(f_inc_rds))
         else stop("Lista de incluídos ausente. Rode a SEÇÃO 11 antes.")
  if (!"id" %in% names(inc)) stop("Lista de incluídos sem coluna 'id'.")

  pega <- function(d, opcoes, default = NA) {
    col <- intersect(opcoes, names(d)); if (length(col)) d[[col[1]]] else rep(default, nrow(d)) }
  base <- tibble(id = as.integer(inc$id), titulo = pega(inc, c("titulo", "title")),
    resumo = pega(inc, c("resumo", "abstract")), doi = pega(inc, "doi"),
    ano = pega(inc, c("ano", "year")), autores = pega(inc, c("autores", "author")),
    periodico = pega(inc, c("periodico", "journal")), base_origem = pega(inc, "base_origem"),
    link_texto_completo = ifelse(is.na(pega(inc, "doi")), NA_character_,
                                 paste0("https://doi.org/", pega(inc, "doi")))) |>
    distinct(id, .keep_all = TRUE)

  criar_template <- function(arquivo, nome_revisor) {
    if (file.exists(arquivo) && !isTRUE(CFG$forcar_texto_completo)) return(invisible(FALSE))
    readr::write_csv(base |> mutate(decisao = "",
      motivo_exclusao = paste0("(", paste(MOTIVOS, collapse = " | "), ")"),
      observacoes = ""), arquivo)
    invisible(TRUE)
  }
  f1 <- file.path(dir_proc, "triagem_texto_completo_revisor1.csv")
  f2 <- file.path(dir_proc, "triagem_texto_completo_revisor2.csv")
  criar_template(f1, "revisor 1"); criar_template(f2, "revisor 2")

  ler_decisoes <- function(arquivo) {
    if (!file.exists(arquivo)) return(tibble(id = integer(), decisao = character(), motivo = character()))
    d <- readr::read_csv(arquivo, show_col_types = FALSE)
    if (!"decisao" %in% names(d)) return(tibble(id = integer(), decisao = character(), motivo = character()))
    tibble(id = as.integer(d$id), decisao = normalizar_decisao(d$decisao),
           motivo = if ("motivo_exclusao" %in% names(d)) as.character(d$motivo_exclusao) else NA_character_) |>
      distinct(id, .keep_all = TRUE)
  }
  d1 <- ler_decisoes(f1); d2 <- ler_decisoes(f2)

  if (all(is.na(d1$decisao)) && all(is.na(d2$decisao))) {
    registrar("Texto completo: templates criados com ", nrow(base), " estudos; aguardando preenchimento.")
    message("Preencha 'decisao' e 'motivo_exclusao' em:\n  ", f1, "\n  ", f2,
            "\ne rode a SEÇÃO 12 novamente.")
  } else {
    cons <- base |>
      left_join(d1, by = "id") |> rename(r1 = decisao, motivo_r1 = motivo) |>
      left_join(d2, by = "id") |> rename(r2 = decisao, motivo_r2 = motivo) |>
      mutate(consenso = case_when(!is.na(r1) & !is.na(r2) & r1 == r2 ~ r1,
                                  !is.na(r1) & !is.na(r2) & r1 != r2 ~ "discordancia",
                                  TRUE ~ "pendente"),
             motivo_final = ifelse(consenso == "excluido", coalesce(motivo_r1, motivo_r2), NA_character_))
    kk <- kappa_cohen(cons$r1, cons$r2)
    readr::write_csv(cons, file.path(dir_proc, "triagem_texto_completo_consenso.csv"))
    readr::write_csv(tibble(n_pares_decididos = kk$n, kappa = round(kk$kappa, 4),
      ic95_inf = round(kk$ic95_inf, 4), ic95_sup = round(kk$ic95_sup, 4),
      interpretacao = kk$interpretacao), file.path(dir_tab, "kappa_texto_completo.csv"))
    readr::write_csv(cons |> filter(consenso == "excluido") |> count(motivo_final, name = "n", sort = TRUE),
                     file.path(dir_tab, "motivos_exclusao_texto_completo.csv"))
    inc_final <- cons |> filter(consenso == "incluido") |> arrange(id)
    saveRDS(inc_final, file.path(dir_proc, "incluidos_texto_completo.rds"))
    readr::write_csv(inc_final, file.path(dir_proc, "incluidos_texto_completo.csv"))
    atualizar_prisma(textos_avaliados = nrow(cons), incluidos_sintese = nrow(inc_final))
    registrar("Texto completo: incluídos=", nrow(inc_final), " kappa=", round(kk$kappa, 3))
  }
})


# SEÇÃO 13 — EXTRAÇÃO DE DADOS E CÁLCULO DE EFEITOS
# Cria/valida o template de extração e calcula log RR/OR/HR e variâncias com
# escalc(). Sem planilha preenchida, usa dados de DEMONSTRAÇÃO.
# Fundamentação: Cochrane caps. 5-6; Borenstein et al. (2021); Viechtbauer (2010).
# Saída: 02_dados/processados/efeitos_calculados.rds e validacao_extracao.csv

if (isTRUE(EXEC$extracao)) tentar({
  carregar("metafor")
  registrar("SEÇÃO 13: extração de dados e cálculo de efeitos")

  cols <- c("id_estudo", "autor_ano", "doi", "titulo", "pais", "regiao_oms", "renda_pais",
    "desenho", "periodo_inicio", "periodo_fim", "n_participantes", "idade_media",
    "idade_min", "idade_max", "faixa_etaria", "prop_masculino", "categoria_exposicao",
    "exposicao_descricao", "metrica_exposicao", "incremento_exposicao", "unidade_exposicao",
    "exposicao_aguda_cronica", "metodo_avaliacao_exposicao", "comparador_descricao",
    "desfecho_cid", "desfecho_descricao", "tipo_desfecho", "medida_efeito", "efeito",
    "ic95_inf", "ic95_sup", "se_reportado", "p_valor", "eventos_expostos", "n_expostos",
    "eventos_nao_expostos", "n_nao_expostos", "ajustado", "covariaveis_ajuste",
    "modelo_estatistico", "robins_confundimento", "robins_selecao",
    "robins_classificacao_exposicao", "robins_dados_faltantes", "robins_desfecho",
    "robins_relato", "robins_geral", "observacoes")
  arq_ext <- file.path(dir_ext, "planilha_extracao.csv")
  if (!file.exists(arq_ext)) {
    write.csv(as.data.frame(matrix("", nrow = 0, ncol = length(cols),
              dimnames = list(NULL, cols))), arq_ext, row.names = FALSE)
  }
  dados <- readr::read_csv(arq_ext, show_col_types = FALSE)
  if (nrow(dados) == 0) {
    message("Planilha vazia — usando dados de DEMONSTRAÇÃO (6 estudos).")
    dados <- tibble(
      id_estudo = paste0("exemplo_", 1:6),
      autor_ano = c("A 2021", "B 2021", "C 2022", "D 2023", "E 2024", "F 2025"),
      medida_efeito = "RR", efeito = c(1.05, 1.12, 0.98, 1.20, 1.03, 1.08),
      ic95_inf = c(1.01, 1.05, 0.95, 1.10, 0.99, 1.02),
      ic95_sup = c(1.09, 1.20, 1.02, 1.31, 1.07, 1.15),
      categoria_exposicao = c("temperatura", "temperatura", "poluicao_ar",
                              "poluicao_ar", "saneamento", "ambiente_construido"),
      tipo_desfecho = c("I63", "I64", "I60", "I61", "I63", "I64"),
      desenho = c("serie_temporal", "serie_temporal", "coorte", "coorte",
                  "ecologico", "caso_cruzado"))
  }
  validacao <- dados |> mutate(
    tem_efeito = !is.na(efeito), tem_ic = !is.na(ic95_inf) & !is.na(ic95_sup),
    medida_ok = medida_efeito %in% c("RR", "OR", "HR"),
    incremento_logico = ic95_inf < efeito & efeito < ic95_sup,
    problema = case_when(!tem_efeito ~ "sem_efeito", !tem_ic ~ "sem_ic",
      !medida_ok ~ "medida_invalida", !incremento_logico ~ "ic_inconsistente",
      TRUE ~ "ok")) |> count(problema, name = "n")
  write.csv(validacao, file.path(dir_tab, "validacao_extracao.csv"), row.names = FALSE)

  dados_val <- dados |> filter(!is.na(efeito), !is.na(ic95_inf), !is.na(ic95_sup))
  efeitos <- metafor::escalc(measure = "RR", yi = log(dados_val$efeito),
    vi = ((log(dados_val$ic95_sup) - log(dados_val$ic95_inf)) / (2 * qnorm(0.975)))^2,
    data = as.data.frame(dados_val))
  write.csv(efeitos, file.path(dir_proc, "efeitos_calculados.csv"), row.names = FALSE)
  saveRDS(efeitos, file.path(dir_proc, "efeitos_calculados.rds"))
  registrar("Efeitos calculados: ", nrow(efeitos), " estudos.")
})


# SEÇÃO 14 — RISCO DE VIÉS (ROBINS-I / NOS / OHAT) + robvis
# Estrutura a avaliação do risco de viés e gera figuras "traffic light" e
# "summary". Sem planilha preenchida, usa DEMONSTRAÇÃO.
# Fundamentação: Sterne et al. (2016); NOS (2000); OHAT/NTP (2015);
# McGuinness & Higgins (2021).
# Saída: risco_vies.csv, risco_vies_dominios.csv, rob_traffic_light.png, rob_summary.png

if (isTRUE(EXEC$risco_vies)) tentar({
  registrar("SEÇÃO 14: risco de viés")

  dominios_robins <- c("Confundimento" = "robins_confundimento",
    "Seleção dos participantes" = "robins_selecao",
    "Classificação da exposição" = "robins_classificacao_exposicao",
    "Desvios/cointervenções" = "robins_desvio", "Dados faltantes" = "robins_dados_faltantes",
    "Mensuração do desfecho" = "robins_desfecho", "Relato seletivo" = "robins_relato")
  niveis_robins <- c("Low", "Moderate", "Serious", "Critical", "No information")

  arq <- file.path(dir_ext, "planilha_extracao.csv")
  dados <- if (file.exists(arq)) readr::read_csv(arq, show_col_types = FALSE) else tibble()
  if (nrow(dados) == 0 || !all(unname(dominios_robins) %in% names(dados))) {
    message("Sem avaliações — usando DEMONSTRAÇÃO.")
    dados <- tibble(id_estudo = paste0("exemplo_", 1:6),
      desenho = c("serie_temporal", "serie_temporal", "coorte", "coorte", "ecologico", "caso_cruzado"),
      robins_confundimento = c("Moderate", "Low", "Serious", "Low", "Critical", "Moderate"),
      robins_selecao = "Low",
      robins_classificacao_exposicao = c("Moderate", "Low", "Moderate", "Low", "Serious", "Low"),
      robins_desvio = "Low",
      robins_dados_faltantes = c("Low", "Low", "Moderate", "Low", "Serious", "Low"),
      robins_desfecho = c("Low", "Low", "Low", "Moderate", "Serious", "Low"),
      robins_relato = "Low")
  }
  rv <- dados |>
    mutate(across(all_of(unname(dominios_robins)), ~ factor(.x, levels = niveis_robins, ordered = TRUE))) |>
    rowwise() |> mutate(pior = as.character(max(c_across(all_of(unname(dominios_robins))))),
                        robins_geral = pior) |> ungroup()
  write.csv(rv, file.path(dir_proc, "risco_vies.csv"), row.names = FALSE)

  freq_dom <- purrr::map_dfr(names(dominios_robins), function(d) {
    rv |> count(.data[[dominios_robins[[d]]]], name = "n") |>
      mutate(dominio = d, julgamento = .data[[dominios_robins[[d]]]]) |>
      select(dominio, julgamento, n) })
  write.csv(freq_dom, file.path(dir_tab, "risco_vies_dominios.csv"), row.names = FALSE)

  rob_tbl <- rv |> transmute(Study = id_estudo, D1 = robins_confundimento, D2 = robins_selecao,
    D3 = robins_classificacao_exposicao, D4 = robins_desvio, D5 = robins_dados_faltantes,
    D6 = robins_desfecho, D7 = robins_relato, Overall = robins_geral)
  if (requireNamespace("robvis", quietly = TRUE)) {
    try({
      ggplot2::ggsave(file.path(dir_fig, "rob_traffic_light.png"),
        robvis::rob_traffic_light(rob_tbl, tool = "ROBINS-I", colour = "cochrane"),
        width = 10, height = 6, dpi = 300)
      ggplot2::ggsave(file.path(dir_fig, "rob_summary.png"),
        robvis::rob_summary(rob_tbl, tool = "ROBINS-I", overall = TRUE),
        width = 9, height = 5, dpi = 300)
    }, silent = TRUE)
  }
  registrar("Risco de viés: ", nrow(rv), " estudos avaliados.")
})


# SEÇÃO 15 — META-ANÁLISE (efeitos aleatórios, REML)
# Modelo de efeitos aleatórios com tau² por REML, heterogeneidade (I², tau², Q),
# intervalo de predição, forest geral e diagnóstico de viés de publicação.
# Fundamentação: Viechtbauer (2005, 2010); Borenstein et al. (2021);
# Higgins & Thompson (2002); IntHout et al. (2016); Egger (1997); Duval & Tweedie (2000).
# Saída: meta_analise_geral.csv, forest_geral.png, funnel_egger.png, baujat.png

if (isTRUE(EXEC$meta_analise)) tentar({
  carregar("metafor")
  registrar("SEÇÃO 15: meta-análise (REML)")

  arq <- file.path(dir_proc, "efeitos_calculados.rds")
  if (!file.exists(arq)) stop("efeitos_calculados.rds ausente (rode a SEÇÃO 13).")
  dat <- as.data.frame(readRDS(arq))
  dat$estudo <- if ("autor_ano" %in% names(dat)) dat$autor_ano else dat$id_estudo

  m_reml <- metafor::rma(yi = yi, vi = vi, data = dat, method = "REML",
                         slab = estudo, test = if (nrow(dat) <= 10) "t" else "z")
  m_hk <- try(metafor::rma(yi = yi, vi = vi, data = dat, method = "REML", test = "knha"), silent = TRUE)

  het <- tibble(k = m_reml$k, tau2 = m_reml$tau2, I2 = m_reml$I2, H2 = m_reml$H2,
    Q = m_reml$QE, Q_df = m_reml$k - 1, Q_p = m_reml$QEp,
    pred_inf = predict(m_reml)$pi.lb, pred_sup = predict(m_reml)$pi.ub,
    efeito_RR = exp(m_reml$beta[1]), ic_inf = exp(m_reml$ci.lb),
    ic_sup = exp(m_reml$ci.ub), p = m_reml$pval)
  write.csv(het, file.path(dir_tab, "meta_analise_geral.csv"), row.names = FALSE)
  saveRDS(m_reml, file.path(dir_proc, "metafor_modelo.rds"))
  if (!inherits(m_hk, "try-error")) saveRDS(m_hk, file.path(dir_proc, "metafor_modelo_hk.rds"))

  png(file.path(dir_fig, "forest_geral.png"), width = 2000, height = 1600, res = 200)
  metafor::forest(m_reml, atransf = exp, at = log(c(0.8, 1, 1.25, 1.5)),
    xlab = "Risco relativo (escala log)", mlab = "Efeito médio (efeitos aleatórios)",
    header = c("Estudo", "RR [IC95%]"), cex = 0.9, addpred = TRUE, col = "navy", border = "darkgray")
  title("Associação entre determinantes ambientais e DCV (I60-I69)")
  dev.off()

  if (m_reml$k >= 10) {
    png(file.path(dir_fig, "funnel_egger.png"), width = 1500, height = 1300, res = 200)
    metafor::funnel(m_reml, level = c(90, 95, 99), shade = c("white", "gray55", "gray75"),
                    refline = 0, xlab = "log RR")
    egger <- metafor::regtest(m_reml, model = "lm", predictor = "sei")
    tf <- metafor::trimfill(m_reml)
    dev.off()
    capture.output(list(egger = egger, trimfill = tf), file = file.path(dir_tab, "vies_publicacao.txt"))
    png(file.path(dir_fig, "radial_plot.png"), width = 1400, height = 1200, res = 200)
    metafor::radial(m_reml); dev.off()
  } else {
    registrar("k < 10: Egger/trim-and-fill não recomendados (Sterne et al., 2011).")
  }
  png(file.path(dir_fig, "baujat.png"), width = 1500, height = 1300, res = 200)
  metafor::baujat(m_reml); dev.off()

  registrar("Meta-análise: k=", m_reml$k, " RR=", round(exp(m_reml$beta[1]), 3),
            " I2=", round(m_reml$I2, 1), "%")
})


# SEÇÃO 16 — FOREST PLOTS ESTRATIFICADOS (exposição / desfecho)
# Forest plots por categoria de exposição e por tipo de desfecho, e efeito
# agrupado por categoria. Fundamentação: Viechtbauer (2010); Cochrane cap. 10.
# Saída: forest_exposicao.png, forest_desfecho.png, efeitos_por_categoria.csv

if (isTRUE(EXEC$forest_plots)) tentar({
  carregar("metafor")
  registrar("SEÇÃO 16: forest plots estratificados")
  dat <- as.data.frame(readRDS(file.path(dir_proc, "efeitos_calculados.rds")))
  dat$estudo <- if ("autor_ano" %in% names(dat)) dat$autor_ano else dat$id_estudo

  if ("categoria_exposicao" %in% names(dat)) {
    cats <- sort(unique(dat$categoria_exposicao))
    m_cat <- metafor::rma(yi = yi, vi = vi, data = dat, method = "REML",
                          mods = ~ factor(categoria_exposicao) - 1, slab = estudo)
    png(file.path(dir_fig, "forest_exposicao.png"), width = 2200, height = 1700, res = 200)
    metafor::forest(m_cat, atransf = exp, xlab = "Risco relativo (escala log)",
                    header = c("Estudo", "RR [IC95%]"), cex = 0.85, addpred = FALSE)
    title("Efeitos por categoria de exposição ambiental"); dev.off()

    res_cat <- purrr::map_dfr(cats, function(cc) {
      d <- dat[dat$categoria_exposicao == cc, ]
      if (nrow(d) < 2) return(NULL)
      m <- metafor::rma(yi = yi, vi = vi, data = d, method = "REML")
      tibble(categoria = cc, k = m$k, RR = exp(m$beta[1]), ic_inf = exp(m$ci.lb),
             ic_sup = exp(m$ci.ub), I2 = m$I2, p = m$pval) })
    write.csv(res_cat, file.path(dir_tab, "efeitos_por_categoria.csv"), row.names = FALSE)
  }
  if ("tipo_desfecho" %in% names(dat)) {
    m_des <- metafor::rma(yi = yi, vi = vi, data = dat, method = "REML",
                          mods = ~ factor(tipo_desfecho) - 1, slab = estudo)
    png(file.path(dir_fig, "forest_desfecho.png"), width = 2200, height = 1700, res = 200)
    metafor::forest(m_des, atransf = exp, xlab = "Risco relativo (escala log)",
                    header = c("Estudo", "RR [IC95%]"), cex = 0.85)
    title("Efeitos por tipo de desfecho cerebrovascular (CID-10)"); dev.off()
  }
  registrar("Forest plots estratificados gerados.")
})


# SEÇÃO 17 — SUBGRUPOS, METARREGRESSÃO E SENSIBILIDADE
# Modificadores de efeito (subgrupos/metarregressão), leave-one-out, exclusão de
# alto risco de viés e E-value. Fundamentação: Cochrane caps. 10-11;
# Thompson & Higgins (2002); Sterne et al. (2016); VanderWeele & Ding (2017).
# Saída: subgrupos.csv, metarregressao.csv, leave_one_out.csv, sensibilidade_*.csv

if (isTRUE(EXEC$subgrupos)) tentar({
  carregar("metafor")
  registrar("SEÇÃO 17: subgrupos/metarregressão/sensibilidade")
  dat <- as.data.frame(readRDS(file.path(dir_proc, "efeitos_calculados.rds")))
  dat$estudo <- if ("autor_ano" %in% names(dat)) dat$autor_ano else dat$id_estudo

  subgrupo <- function(dat, var) {
    if (!var %in% names(dat)) return(NULL)
    m <- metafor::rma(yi = yi, vi = vi, data = dat, method = "REML",
                      mods = as.formula(paste0("~ factor(", var, ")")))
    res <- dat |> group_by(grupo = .data[[var]]) |> group_modify(~ {
      mm <- metafor::rma(yi = .x$yi, vi = .x$vi, method = "REML")
      tibble(k = mm$k, RR = exp(mm$beta[1]), ic_inf = exp(mm$ci.lb),
             ic_sup = exp(mm$ci.ub), I2 = mm$I2) }) |> ungroup() |> mutate(variavel = var)
    attr(res, "Q_between_p") <- m$QMp; res
  }
  vars_sub <- intersect(c("categoria_exposicao", "tipo_desfecho", "desenho",
                          "faixa_etaria", "regiao_oms", "renda_pais"), names(dat))
  write.csv(purrr::map_dfr(vars_sub, ~ subgrupo(dat, .x)),
            file.path(dir_tab, "subgrupos.csv"), row.names = FALSE)

  metareg_var <- function(dat, var) {
    if (!var %in% names(dat)) return(NULL)
    d <- dat[!is.na(dat[[var]]), ]
    if (nrow(d) < 3 || length(unique(d[[var]])) < 2) return(NULL)
    m <- metafor::rma(yi = yi, vi = vi, data = d, method = "REML",
                      mods = as.formula(paste0("~ ", var)))
    tibble(variavel = var, k = m$k, beta = m$beta[2], se = m$se[2], p = m$pval[2],
           R2 = m$R2, QM_p = m$QMp)
  }
  vars_reg <- intersect(c("ano", "idade_media", "prop_masculino"), names(dat))
  metareg <- purrr::map_dfr(vars_reg, ~ metareg_var(dat, .x))
  if (nrow(metareg)) write.csv(metareg, file.path(dir_tab, "metarregressao.csv"), row.names = FALSE)

  m <- metafor::rma(yi = yi, vi = vi, data = dat, method = "REML")
  loo <- purrr::map_dfr(seq_len(nrow(dat)), function(i) {
    mm <- metafor::rma(yi = yi, vi = vi, data = dat[-i, ], method = "REML")
    tibble(omitido = dat$estudo[i], k = mm$k, RR = exp(mm$beta[1]),
           ic_inf = exp(mm$ci.lb), ic_sup = exp(mm$ci.ub), I2 = mm$I2) })
  write.csv(loo, file.path(dir_tab, "leave_one_out.csv"), row.names = FALSE)

  rv_file <- file.path(dir_proc, "risco_vies.csv")
  if (file.exists(rv_file)) {
    rv <- readr::read_csv(rv_file, show_col_types = FALSE)
    if ("robins_geral" %in% names(rv)) {
      ruins <- rv$id_estudo[rv$robins_geral %in% c("Serious", "Critical")]
      d2 <- dat[!dat$estudo %in% ruins, ]
      if (nrow(d2) >= 2) {
        m2 <- metafor::rma(yi = yi, vi = vi, data = d2, method = "REML")
        write.csv(tibble(cenario = "exclui_alto_risco", k = m2$k, RR = exp(m2$beta[1]),
          ic_inf = exp(m2$ci.lb), ic_sup = exp(m2$ci.ub), I2 = m2$I2),
          file.path(dir_tab, "sensibilidade_alto_risco.csv"), row.names = FALSE)
      }
    }
  }
  rr <- exp(m$beta[1]); registrar("E-value (estimativa): ", round(rr + sqrt(rr * (rr - 1)), 2))
})


# SEÇÃO 18 — DIAGRAMA DE FLUXO PRISMA 2020
# Preenche o template oficial do PRISMA2020 com as contagens reais e exporta o
# diagrama em PNG (via PRISMA_save ou navegador headless).
# Fundamentação: Page et al. (2021); Haddaway et al. (2022).
# Saída: prisma_flow_diagram.png, prisma_contagens_preenchidas.csv

if (isTRUE(EXEC$prisma)) tentar({
  registrar("SEÇÃO 18: diagrama PRISMA")
  if (!requireNamespace("PRISMA2020", quietly = TRUE))
    stop("Pacote PRISMA2020 ausente (install.packages('PRISMA2020')).")
  suppressPackageStartupMessages(library(PRISMA2020))
  carregar("htmlwidgets", "tibble")

  template_path <- system.file("extdata", "PRISMA.csv", package = "PRISMA2020")
  dados <- read.csv(template_path, stringsAsFactors = FALSE, check.names = FALSE)

  ler_num <- function(f) {
    if (!file.exists(f)) return(0L)
    d <- read.csv(f); col <- intersect(c("coletados", "registros", "total"), names(d))
    if (length(col)) as.integer(d[[col[1]]][1]) else 0L
  }
  n_pubmed <- if (file.exists(file.path(dir_brutos, "pubmed_count.csv")))
    as.integer(read.csv(file.path(dir_brutos, "pubmed_count.csv"))$registros[1]) else 0L
  n_scopus <- ler_num(file.path(dir_brutos, "scopus_count.csv"))
  n_scielo <- ler_num(file.path(dir_brutos, "scielo_count.csv"))
  n_bases <- n_pubmed + n_scopus + n_scielo

  f_ident <- file.path(dir_tab, "prisma_identificacao.csv")
  n_dup <- 0L; n_pos_dedup <- 0L
  if (file.exists(f_ident)) {
    ii <- read.csv(f_ident)
    d <- ii$n_registros[ii$base_origem == "Duplicatas removidas"]
    a <- ii$n_registros[ii$base_origem == "Após deduplicação"]
    if (length(d)) n_dup <- as.integer(d[1]); if (length(a)) n_pos_dedup <- as.integer(a[1])
  }
  if (n_pos_dedup == 0) n_pos_dedup <- max(n_bases - n_dup, 0)

  # fases seguintes: lê o prisma_contagens.csv atualizado nas SEÇÕES 11-12
  f_cont <- file.path(dir_tab, "prisma_contagens.csv")
  get_etapa <- function(rot) {
    if (!file.exists(f_cont)) return(0L)
    tt <- read.csv(f_cont); v <- tt$n[tt$etapa == rot]
    if (length(v)) as.integer(v[1]) else 0L
  }
  n_screen_excl <- get_etapa("Registros excluídos na triagem de título/abstrato")
  n_assessed    <- get_etapa("Textos completos avaliados")
  n_incluidos   <- get_etapa("Estudos incluídos na síntese")
  n_sought <- n_assessed; n_notretr <- 0L

  set_n <- function(key, value, as_text = FALSE) {
    i <- which(dados$data == key)
    if (length(i)) dados$n[i] <<- if (as_text) as.character(value) else as.numeric(value)
  }
  set_n("database_results", n_bases)
  set_n("database_specific_results", paste0("PubMed/MEDLINE: ", n_pubmed,
        "; Scopus: ", n_scopus, "; SciELO: ", n_scielo), as_text = TRUE)
  set_n("register_results", 0); set_n("website_results", 0)
  set_n("organisation_results", 0); set_n("citations_results", 0)
  set_n("duplicates", n_dup); set_n("excluded_automatic", 0); set_n("excluded_other", 0)
  set_n("records_screened", n_pos_dedup); set_n("records_excluded", n_screen_excl)
  set_n("dbr_sought_reports", n_sought); set_n("dbr_notretrieved_reports", n_notretr)
  set_n("dbr_assessed", n_assessed); set_n("dbr_excluded", "Razão 1; Razão 2; Razão 3", as_text = TRUE)
  set_n("other_sought_reports", 0); set_n("other_notretrieved_reports", 0)
  set_n("other_assessed", 0); set_n("other_excluded", "", as_text = TRUE)
  set_n("new_studies", n_incluidos); set_n("new_reports", n_incluidos)
  set_n("total_studies", n_incluidos); set_n("total_reports", n_incluidos)
  set_n("previous_studies", 0)

  write.csv(dados[, c("data", "box", "n")],
            file.path(dir_tab, "prisma_contagens_preenchidas.csv"), row.names = FALSE)

  # tabela-resumo (preserva linhas extras, ex. 'pendente', criadas antes)
  tab_novo <- tibble(etapa = c(
      "Registros identificados nas bases (PubMed+Scopus+SciELO)", "Duplicatas removidas",
      "Registros triados (título/abstrato)", "Registros excluídos na triagem de título/abstrato",
      "Textos completos avaliados", "Estudos incluídos na síntese"),
    n = c(n_bases, n_dup, n_pos_dedup, n_screen_excl, n_assessed, n_incluidos))
  if (file.exists(f_cont)) {
    antigo <- readr::read_csv(f_cont, show_col_types = FALSE)
    tab_novo <- bind_rows(tab_novo, antigo[!(antigo$etapa %in% tab_novo$etapa), ])
  }
  readr::write_csv(tab_novo, f_cont)

  dados <- PRISMA_data(dados)
  diagrama <- tryCatch(PRISMA_flowdiagram(dados, interactive = FALSE, previous = FALSE,
                     other = TRUE, fontsize = 10), error = function(e) NULL)
  if (!is.null(diagrama)) {
    ok <- tryCatch({ PRISMA_save(diagrama, filename = file.path(dir_fig, "prisma_flow_diagram"),
                                 filetype = "png", overwrite = TRUE); TRUE },
                   error = function(e) FALSE)
    if (!ok) {
      html_file <- file.path(dir_fig, "prisma_flow_diagram.html")
      try(htmlwidgets::saveWidget(diagrama, html_file, selfcontained = FALSE), silent = TRUE)
      chrome <- c("C:/Program Files/Google/Chrome/Application/chrome.exe",
        "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe",
        "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe",
        Sys.which("chrome"), Sys.which("msedge"))
      chrome <- chrome[file.exists(chrome)][1]
      if (!is.na(chrome)) {
        url <- paste0("file:///", gsub("\\\\", "/", html_file))
        system2(chrome, c("--headless=new", "--disable-gpu", "--no-sandbox", "--hide-scrollbars",
          "--window-size=1300,2200", "--virtual-time-budget=12000",
          paste0("--screenshot=", shQuote(file.path(dir_fig, "prisma_flow_diagram.png"))),
          shQuote(url)), stdout = FALSE, stderr = FALSE)
      }
    }
  }
  registrar("PRISMA: bases=", n_bases, " dup=", n_dup, " triados=", n_pos_dedup)
})


# SEÇÃO 19 — FIGURAS SIMPLES DO RELATÓRIO
# 8 figuras diretas (PNG 300 dpi): produção anual, países, periódicos,
# palavras-chave, exposição, subtipo CID, mapa e forest simples.
# Fundamentação: Wickham (ggplot2); Viechtbauer (2010); Aria & Cuccurullo (2017).
# Saída: 03_resultados/figuras/01..08*.png + LEIA-ME.md

if (isTRUE(EXEC$figuras)) tentar({
  carregar("countrycode")
  registrar("SEÇÃO 19: figuras simples")
  salvar <- function(plot, nome, w = 8, h = 5) {
    ggsave(file.path(dir_fig, paste0(nome, ".png")), plot, width = w, height = h, dpi = 300)
  }
  dedup <- readr::read_csv(file.path(dir_proc, "registros_deduplicados.csv"),
                           show_col_types = FALSE) |>
    mutate(ano = suppressWarnings(as.integer(stringr::str_extract(as.character(year), "\\d{4}"))),
           texto = tolower(paste(title, abstract, sep = " ")),
           journal = stringr::str_squish(as.character(journal)))

  prod <- dedup |> filter(!is.na(ano), ano >= 2020, ano <= 2026) |> count(ano)
  salvar(ggplot(prod, aes(factor(ano), n)) + geom_col(fill = "#2c7fb8") +
    geom_text(aes(label = n), vjust = -0.4, size = 4) +
    labs(title = "Produção científica por ano", x = "Ano de publicação", y = "Número de artigos") +
    scale_y_continuous(expand = expansion(mult = c(0, 0.12))) + theme_minimal(base_size = 13),
    "01_producao_anual", 7, 5)

  extrair_paises <- function(c1) {
    if (is.na(c1) || c1 == "") return(character(0))
    affs <- unlist(strsplit(c1, ";")); toks <- vapply(affs, function(a) {
      p <- trimws(unlist(strsplit(a, ","))); toupper(gsub("[^A-Z ]", "", p[length(p)])) }, character(1))
    toks <- toks[nchar(toks) > 2]
    norm <- c("USA" = "United States", "UNITED STATES" = "United States",
      "UNITED STATES OF AMERICA" = "United States", "UK" = "United Kingdom",
      "UNITED KINGDOM" = "United Kingdom", "ENGLAND" = "United Kingdom",
      "SCOTLAND" = "United Kingdom", "WALES" = "United Kingdom", "CHINA" = "China",
      "TAIWAN" = "Taiwan", "JAPAN" = "Japan", "GERMANY" = "Germany", "FRANCE" = "France",
      "ITALY" = "Italy", "SPAIN" = "Spain", "BRAZIL" = "Brazil", "INDIA" = "India",
      "CANADA" = "Canada", "AUSTRALIA" = "Australia")
    out <- ifelse(toks %in% names(norm), norm[toks],
                  countrycode::countrycode(toks, "country.name", "country.name.en", warn = FALSE))
    unique(out[!is.na(out)])
  }
  pub <- tryCatch(readr::read_csv(file.path(dir_brutos, "pubmed_records.csv"), show_col_types = FALSE),
                  error = function(e) NULL)
  tab_pais <- if (!is.null(pub) && "C1" %in% names(pub)) {
    tibble(pais = unlist(purrr::map(pub$C1, extrair_paises))) |> count(pais, sort = TRUE)
  } else tibble(pais = "Dados de país indisponíveis", n = 0L)
  salvar(ggplot(head(tab_pais, 10), aes(n, fct_reorder(pais, n))) + geom_col(fill = "#41ab5d") +
    geom_text(aes(label = n), hjust = -0.25, size = 4) +
    labs(title = "Top 10 países com mais publicações", x = "Número de artigos", y = NULL) +
    scale_x_continuous(expand = expansion(mult = c(0, 0.15))) + theme_minimal(base_size = 13),
    "02_top_paises", 8, 5)

  top_per <- dedup |> filter(!is.na(journal), journal != "") |> count(journal, sort = TRUE) |> head(10)
  salvar(ggplot(top_per, aes(n, fct_reorder(journal, n))) + geom_col(fill = "#807dba") +
    geom_text(aes(label = n), hjust = -0.25, size = 4) +
    labs(title = "Top 10 periódicos com mais publicações", x = "Número de artigos", y = NULL) +
    scale_x_continuous(expand = expansion(mult = c(0, 0.15))) + theme_minimal(base_size = 12) +
    theme(axis.text.y = element_text(size = 8)), "03_top_periodicos", 9, 5.5)

  kw_de <- character(0)
  if (!is.null(pub) && "DE" %in% names(pub)) kw_de <- unlist(strsplit(paste(pub$DE, collapse = ";"), ";"))
  kw_de <- stringr::str_squish(tolower(kw_de)); kw_de <- kw_de[!is.na(kw_de) & nchar(kw_de) > 2]
  stop_pt <- c("the", "and", "of", "for", "with", "from", "study", "analysis", "review",
    "effect", "effects", "association", "risk", "health", "exposure", "based", "using",
    "among", "between", "stroke", "cerebrovascular", "patients", "a", "in", "on", "to", "by", "is")
  kw_tit <- dedup$title |> tolower() |> stringr::str_replace_all("[^a-z ]", " ") |>
    stringr::str_split(" ") |> unlist() |> (\(x) x[!x %in% stop_pt & nchar(x) > 3])()
  top_kw <- tibble(kw = c(kw_de, kw_tit)) |> filter(!kw %in% c("na", "")) |> count(kw, sort = TRUE) |> head(10)
  salvar(ggplot(top_kw, aes(n, fct_reorder(kw, n))) + geom_col(fill = "#e6550d") +
    geom_text(aes(label = n), hjust = -0.25, size = 4) +
    labs(title = "Top 10 palavras-chave mais frequentes",
         subtitle = "Palavras-chave de autor (PubMed) complementadas por termos dos títulos",
         x = "Frequência", y = NULL) + scale_x_continuous(expand = expansion(mult = c(0, 0.15))) +
    theme_minimal(base_size = 13), "04_top_palavras_chave", 9, 5.5)

  cats <- list(
    "Clima/temperatura" = "temperature|heat|cold|climate|humid|weather|thermal|seasonal",
    "Poluição do ar" = "air pollut|pm2\\.?5|pm10|particulate|ozone|nitrogen dioxide|no2|sulfur dioxide|carbon monoxide|black carbon",
    "Poluição da água/solo" = "water pollut|contaminat.*water|soil|heavy metal|arsenic|pesticide",
    "Saneamento" = "sanitation|sewage|sanitary|water supply|toilet",
    "Moradia/combustíveis" = "housing|indoor air|solid fuel|biomass|cooking fuel|household air",
    "Catástrofes" = "flood|wildfire|forest fire|landslide|hurricane|earthquake|disaster",
    "Ambiente construído" = "built environment|green space|greenness|heat island|urban|city planning|noise",
    "Ocupacional" = "occupational")
  exp_tab <- purrr::imap_dfr(cats, ~ tibble(categoria = .y, n = sum(stringr::str_detect(dedup$texto, .x))))
  salvar(ggplot(exp_tab, aes(n, fct_reorder(categoria, n), fill = categoria)) + geom_col(show.legend = FALSE) +
    geom_text(aes(label = n), hjust = -0.25, size = 4) +
    labs(title = "Estudos por tipo de exposição ambiental",
         subtitle = "Classificação por palavras-chave (um estudo pode ter mais de uma exposição)",
         x = "Número de estudos", y = NULL) + scale_x_continuous(expand = expansion(mult = c(0, 0.15))) +
    scale_fill_brewer(palette = "Set2") + theme_minimal(base_size = 12), "05_tipo_exposicao", 9, 5.5)

  sub <- list("I60 HSA" = "subarachnoid|sub-arachnoid|aneurysmal",
    "I61 HIC" = "intracerebral h|haemorrhagic stroke|hemorrhagic stroke|cerebral h",
    "I62 Outras HIC" = "subdural|epidural|extradural",
    "I63 Infarto" = "ischaemic|ischemic|cerebral infarction|brain infarction|brain ischemi",
    "I65-I66 Oclusão" = "carotid stenosis|arterial stenosis|cerebral.*stenosis|occlusion",
    "I67 Outras" = "moyamoya|aneurysm|arteriovenous malformation|vasospasm|other cerebrovascular",
    "I68 Em outras doenças" = "classified elsewhere",
    "I69 Sequelas" = "sequelae|post-?stroke|after stroke|survivor|rehabilitation")
  cid_tab <- purrr::imap_dfr(sub, ~ tibble(subtipo = .y, n = sum(stringr::str_detect(dedup$texto, .x))))
  generico <- stringr::str_detect(dedup$texto, "stroke|avc|acidente vascular") &
    !stringr::str_detect(dedup$texto, paste(unlist(sub), collapse = "|"))
  cid_tab <- bind_rows(cid_tab, tibble(subtipo = "I64 AVC não especificado", n = sum(generico))) |>
    mutate(subtipo = fct_reorder(subtipo, n))
  salvar(ggplot(cid_tab, aes(n, subtipo, fill = subtipo)) + geom_col(show.legend = FALSE) +
    geom_text(aes(label = n), hjust = -0.25, size = 4) +
    labs(title = "Estudos por subtipo de doença cerebrovascular (CID-10)",
      subtitle = "I60 HSA · I61 HIC · I62 outras HIC · I63 infarto · I64 AVC NE · I65-I66 oclusão/estenose · I67 outras · I68 em outras doenças · I69 sequelas",
      x = "Número de estudos", y = NULL) + scale_x_continuous(expand = expansion(mult = c(0, 0.15))) +
    scale_fill_brewer(palette = "Paired") + theme_minimal(base_size = 11) +
    theme(plot.subtitle = element_text(size = 8)), "06_subtipo_cid", 10, 5.5)

  if (requireNamespace("rnaturalearth", quietly = TRUE)) {
    tab_pais_iso <- tab_pais |> mutate(iso3 = countrycode::countrycode(pais, "country.name", "iso3c", warn = FALSE)) |>
      filter(!is.na(iso3)) |> count(iso3, wt = n, name = "n")
    mundo <- rnaturalearth::ne_countries(scale = 110, returnclass = "sf")
    mapa <- left_join(mundo, tab_pais_iso, by = c("iso_a3" = "iso3"))
    salvar(ggplot(mapa) + geom_sf(aes(fill = n), color = "white", linewidth = 0.1) +
      scale_fill_gradient(low = "#deebf7", high = "#08519c", na.value = "grey90", name = "Estudos") +
      labs(title = "Mapa mundial de publicações por país",
           subtitle = "Número de estudos por país (afiliação do primeiro autor/PubMed)") +
      theme_void(base_size = 12), "07_mapa_mundial", 10, 6)
  }

  arq_ef <- file.path(dir_proc, "efeitos_calculados.rds")
  if (file.exists(arq_ef)) {
    ef <- as.data.frame(readRDS(arq_ef))
    ef$RR <- exp(ef$yi); ef$lo <- exp(ef$yi - 1.96 * sqrt(ef$vi))
    ef$hi <- exp(ef$yi + 1.96 * sqrt(ef$vi)); ef$peso <- 1 / ef$vi
    ef$peso_rel <- round(100 * ef$peso / sum(ef$peso), 1)
    ef$estudo <- if ("autor_ano" %in% names(ef)) ef$autor_ano else ef$id_estudo
    ef <- ef[order(ef$RR), ]; ef$estudo <- factor(ef$estudo, levels = ef$estudo)
    salvar(ggplot(ef, aes(RR, estudo)) + geom_vline(xintercept = 1, linetype = "dashed", color = "grey40") +
      geom_errorbarh(aes(xmin = lo, xmax = hi), height = 0.15, color = "grey30") +
      geom_point(aes(size = peso_rel), color = "#08519c") +
      scale_size_continuous(range = c(2, 6), name = "Peso (%)") +
      labs(title = "Forest plot — associação exposição ambiental × DCV",
           subtitle = "Risco relativo por estudo (IC 95%); linha tracejada = RR 1,0",
           x = "Risco relativo (IC 95%)", y = NULL) + scale_x_log10() + theme_minimal(base_size = 12),
      "08_forest_plot_simples", 9, 5)
  }
  writeLines(c("# LEIA-ME — Figuras simples", "",
    "Geradas pela SEÇÃO 19 do script único `01_scripts/00_pipeline_revisao_sistematica.R` (PNG 300 dpi).",
    "Bases: PubMed, Scopus e SciELO.", "",
    "- **01_producao_anual** — artigos por ano (2020–2026).",
    "- **02_top_paises** — 10 países com mais publicações.",
    "- **03_top_periodicos** — 10 periódicos com mais publicações.",
    "- **04_top_palavras_chave** — termos/palavras-chave mais frequentes.",
    "- **05_tipo_exposicao** — estudos por categoria de exposição ambiental.",
    "- **06_subtipo_cid** — estudos por subtipo de DCV (I60–I69).",
    "- **07_mapa_mundial** — mapa coroplético por país.",
    "- **08_forest_plot_simples** — forest plot com RR, IC 95% e peso.",
    "", "Classificações por palavras-chave servem de triagem visual; a extração manual prevalece."),
    file.path(dir_fig, "LEIA-ME.md"))
  registrar("Figuras simples geradas.")
})


# SEÇÃO 20 — RELATÓRIO FINAL (R Markdown)
# Gera (e, se houver pandoc, renderiza) o relatório em R Markdown. O conteúdo do
# .Rmd fica embutido aqui — não há mais arquivo .Rmd separado no projeto.
# Saída: 03_resultados/relatorio_final.Rmd (+ .html se pandoc disponível)

gerar_relatorio_rmd <- function(renderizar = TRUE) {
  linhas <- c(
    "---",
    'title: "Revisão sistemática e meta-análise — Determinantes ambientais das doenças cerebrovasculares (CID-10 I60–I69)"',
    'author: "Ryan de Paulo Santos; Camila Henriques Nunes; [demais autores]"',
    'date: "`r Sys.Date()`"',
    "output:",
    "  html_document:",
    "    toc: true",
    "    toc_float: true",
    "    number_sections: true",
    "    theme: flatly",
    "  pdf_document:",
    "    toc: true",
    "    number_sections: true",
    "bibliography: ../04_referencias/referencias.bib",
    "csl: https://www.zotero.org/styles/vancouver",
    "---",
    "",
    "```{r setup, include=FALSE}",
    "knitr::opts_chunk$set(echo = FALSE, warning = FALSE, message = FALSE, fig.width = 8, fig.height = 5, dpi = 150)",
    "library(metafor); library(tidyverse)",
    "set.seed(20202026)",
    "```",
    "",
    "# Resumo",
    "",
    "Este relatório documenta a condução da revisão sistemática e meta-análise sobre determinantes ambientais das doenças cerebrovasculares (CID-10 I60–I69). O relato segue o PRISMA 2020 [@page2021prisma] e o protocolo PRISMA-P [@moher2015prisma]. A síntese utiliza modelos de efeitos aleatórios [@borenstein2021; @viechtbauer2010], com heterogeneidade por I² e τ² [@higgins2002] e intervalo de predição [@inthout2016].",
    "",
    "# Introdução",
    "",
    "As doenças cerebrovasculares estão entre as principais causas de mortalidade e incapacidade globais [@feigin2021]. Determinantes ambientais modificáveis — clima, poluição, saneamento, moradia, catástrofes e ambiente construído — têm sido associados a desfechos cardiovasculares [@landrigan2018; @who2021aqg].",
    "",
    "# Métodos",
    "",
    "Desenho, elegibilidade, fontes, estratégia de busca, seleção, extração e medidas de efeito seguem o protocolo (00_docs/protocolo_PROSPERO.md) e os itens 1–15 do PRISMA 2020 [@page2021prisma]. Síntese: efeitos aleatórios com REML [@viechtbauer2005]; heterogeneidade por I²/τ² [@higgins2002]; intervalo de predição [@inthout2016]; viés de publicação (funil, Egger, trim-and-fill) quando k ≥ 10 [@egger1997; @duval2000; @sterne2011]; risco de viés por ROBINS-I [@sterne2016] com robvis [@mcguinness2021].",
    "",
    "# Resultados",
    "",
    "## Busca e seleção",
    "",
    "```{r prisma}",
    'if (file.exists("tabelas/prisma_contagens.csv")) {',
    '  knitr::kable(read.csv("tabelas/prisma_contagens.csv"))',
    '} else { cat("Contagens PRISMA ainda não disponíveis.") }',
    "```",
    "",
    "## Meta-análise",
    "",
    "```{r meta}",
    'arq <- "../02_dados/processados/efeitos_calculados.rds"',
    "if (file.exists(arq)) {",
    "  dat <- as.data.frame(readRDS(arq))",
    '  m <- rma(yi = yi, vi = vi, data = dat, method = "REML")',
    "  knitr::kable(data.frame(k = m$k, RR = exp(m$beta[1]), IC_inf = exp(m$ci.lb), IC_sup = exp(m$ci.ub), I2 = round(m$I2,1), tau2 = round(m$tau2,4), p = m$pval))",
    '} else { cat("Nenhum efeito extraído ainda.") }',
    "```",
    "",
    "## Heterogeneidade e predição",
    "",
    "```{r het}",
    "if (exists(\"m\")) { pi <- predict(m); cat(\"Intervalo de predição (RR):\", round(exp(pi$pi.lb),3), \"a\", round(exp(pi$pi.ub),3)) }",
    "```",
    "",
    "## Viés de publicação",
    "",
    "```{r pub}",
    'if (exists("m") && m$k >= 10) { print(regtest(m)); print(trimfill(m)) } else cat("k < 10: testes de funil não recomendados [@sterne2011].")',
    "```",
    "",
    "# Discussão",
    "",
    "Sintetiza-se a magnitude e a consistência dos efeitos por categoria de exposição e subtipo de desfecho, discutindo heterogeneidade, risco de viés e certeza da evidência (GRADE [@guyatt2008]). Limitações e implicações para políticas de saúde ambiental seguem o PRISMA 2020, itens 20–23.",
    "",
    "# Conclusão",
    "",
    "A revisão fornece estimativas quantitativas da associação entre determinantes ambientais e DCV, com implicações para vigilância e políticas territoriais.",
    "",
    "# Referências",
    "",
    "::: {#refs}",
    ":::"
  )
  out <- raiz("03_resultados", "relatorio_final.Rmd")
  writeLines(linhas, out)
  registrar("Relatório Rmd gerado: ", out)
  if (renderizar) {
    if (rmarkdown::pandoc_available()) {
      try(rmarkdown::render(out), silent = TRUE)
    } else {
      message("pandoc não instalado — .Rmd gerado, mas não renderizado.")
    }
  }
  invisible(out)
}

if (isTRUE(EXEC$relatorio)) tentar({
  registrar("SEÇÃO 20: relatório final")
  gerar_relatorio_rmd(renderizar = TRUE)
})


# FIM DO PIPELINE
if (isTRUE(EXEC$setup)) {
  registrar("=======================================================")
  registrar("PIPELINE finalizado.")
  cat("\n=============================================================\n")
  cat(" Pipeline concluído. Log: ", log_path, "\n")
  cat(" Próximos passos possíveis:\n")
  cat("   - Triagem por tópicos (RStudio): ligue topicos_preparar e topicos_app\n")
  cat("   - Extração real: preencha 02_dados/extraidos/planilha_extracao.csv\n")
  cat("=============================================================\n")
}
