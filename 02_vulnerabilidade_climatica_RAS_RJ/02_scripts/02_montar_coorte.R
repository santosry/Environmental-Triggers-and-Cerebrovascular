# 02_montar_coorte.R
# Monta a coorte analítica a partir dos microdados baixados pelo
# microdatasus (script 01), lendo os .rds direto, sem conversão de formato.
#
# COBERTURA DIAGNÓSTICA:
#   I60 a I69 completos.
#   Bloco G45 completo: G45.0, G45.1, G45.2, G45.3, G45.4, G45.8 e G45.9
#     (G45.5, G45.6 e G45.7 não existem na CID-10).
#   Bloco G46 completo: G46.0, G46.1, G46.2, G46.3, G46.4, G46.5, G46.6,
#     G46.7 e G46.8 (G46.9 não existe).
#   A definição é por bloco de três dígitos, de modo que também entram os
#   registros truncados (G45/G46 sem quarto caractere): 411 no período.
# Os códigos G45.8, G46.7 e G46.8 foram incorporados na revisão pedida; o
# bloco completo passa a ser a definição única, o que também dá
# interpretabilidade ao grupo G46 (a lista parcial anterior deixava G46 com 18
# internações).
#
# PERÍODO: DT_INTER de 2010 a 2024. As competições de 2025 são lidas
# porque o SIH-RD e organizado por competência de processamento e
# internações de dezembro de 2024 podem cair em janeiro de 2025.
#
# Entradas:
#   01_dados/brutos_sih/sih_rd_rj_{ano}_{mes}.rds   (191 competições)
#   ../01_DLNMs_RJ_cerebrovascular/data_processed/lookup_municipio_macrorregiao.csv
#
# Saídas:
#   01_dados/processados/coorte_glmm_2010_2024.csv
#   05_tabelas/tab_verificacao_cid.csv
#   04_resultados/resultados_coorte_glmm.txt

suppressWarnings({
  options(stringsAsFactors = FALSE)
  library(data.table)

  ROOT <- normalizePath(".")
  DIR_SIH <- file.path(ROOT, "01_dados", "brutos_sih")
  PROC <- file.path(ROOT, "01_dados", "processados")
  RES <- file.path(ROOT, "04_resultados")
  TAB <- file.path(ROOT, "05_tabelas")
  LOOKUP <- file.path(dirname(ROOT), "01_DLNMs_RJ_cerebrovascular", "data_processed",
                      "lookup_municipio_macrorregiao.csv")
  dir.create(PROC, showWarnings = FALSE, recursive = TRUE)

  logcon <- file(file.path(RES, "resultados_coorte_glmm.txt"), open = "wt", encoding = "UTF-8")
  say <- function(...) { m <- paste0(...); cat(m, "\n"); writeLines(m, logcon); flush(logcon) }

  say("=====================================================================")
  say("COORTE A PARTIR DOS MICRODADOS DO microdatasus")
  say("R ", R.version.string, " | data.table ", as.character(packageVersion("data.table")))
  say("inicio: ", format(Sys.time()))
  say("=====================================================================")

  CODIGOS_I <- sprintf("I6%d", 0:9)
  G_BLOCO <- c("G45", "G46")

  ## ---------------- 1. varredura dos .rds ----------------
  fs <- sort(list.files(DIR_SIH, pattern = "^sih_rd_rj_[0-9]{4}_[0-9]{2}\\.rds$",
                        full.names = TRUE))
  say("competencias do SIH-RD encontradas: ", length(fs))
  if (!length(fs)) stop("nenhum arquivo em ", DIR_SIH, "; rode 01_baixar_microdatasus.R")

  ## KEEP carrega também as variáveis ainda não exploradas: os nove diagnósticos
  ## secundários (DIAGSEC1 a DIAGSEC9), a complexidade do procedimento, a
  ## natureza jurídica do estabelecimento, a infeccao hospitalar, o
  ## procedimento realizado e a intensidade de uso. São elas que sustentam a
  ## análise exploratoria do script 11.
  KEEP <- c("N_AIH", "IDENT", "DT_INTER", "DT_SAIDA", "DIAG_PRINC", "MUNIC_RES",
            "MUNIC_MOV", "SEXO", "IDADE", "COD_IDADE", "CNES", "MORTE", "CAR_INT",
            "RACA_COR", "INSTRU", "UTI_MES_TO", "MARCA_UTI", "DIAS_PERM", "VAL_TOT",
            "COMPLEX", "NATUREZA", "NAT_JUR", "INFEHOSP", "PROC_REA", "CID_ASSO",
            "US_TOT", "ESPEC", "DIAR_ACOM", "UTI_INT_TO", "VAL_UTI", "ANO_CMPT",
            paste0("DIAGSEC", 1:9), paste0("TPDISEC", 1:9))

  t0 <- Sys.time()
  acc <- vector("list", length(fs))
  verif <- vector("list", length(fs))
  n_bruto <- 0L

  for (i in seq_along(fs)) {
    d <- readRDS(fs[i])
    n_bruto <- n_bruto + nrow(d)
    cid <- toupper(trimws(as.character(d[["DIAG_PRINC"]])))
    cid3 <- substr(cid, 1, 3); cid4 <- substr(cid, 1, 4)

    ## verificação de presenca, arquivo por arquivo
    v <- data.table(arquivo = basename(fs[i]), n_total = nrow(d))
    for (c in CODIGOS_I) v[[paste0("I_", c)]] <- sum(cid3 == c)
    for (c in c("G450","G451","G452","G453","G454","G458","G459",
                "G460","G461","G462","G463","G464","G465","G466","G467","G468"))
      v[[paste0("G_", c)]] <- sum(cid4 == c)
    v[["G_bloco"]] <- sum(cid3 %in% G_BLOCO)
    verif[[i]] <- v

    sel <- cid3 %in% CODIGOS_I | cid3 %in% G_BLOCO
    if (any(sel)) {
      dd <- d[sel, intersect(KEEP, names(d)), drop = FALSE]
      dd$cid3 <- cid3[sel]
      dd$cid4 <- cid4[sel]
      dd$MUNIC_RES6 <- sprintf("%06s", as.character(dd[["MUNIC_RES"]]))
      dd <- dd[substr(dd$MUNIC_RES6, 1, 2) == "33", , drop = FALSE]
      if (nrow(dd)) acc[[i]] <- dd
    }
    if (i %% 40 == 0 || i == length(fs))
      say(sprintf("  %3d/%d competencias | brutos=%s | acumulado=%s | %.1f min",
                  i, length(fs), format(n_bruto, big.mark = "."),
                  format(sum(vapply(acc, function(x) if (is.null(x)) 0L else nrow(x), 0L)),
                         big.mark = "."),
                  as.numeric(difftime(Sys.time(), t0, units = "mins"))))
  }

  vd <- rbindlist(verif, fill = TRUE)
  fwrite(vd, file.path(TAB, "tab_verificacao_cid.csv"), encoding = "UTF-8", na = "NA")

  say("\n--- VERIFICACAO DE PRESENCA DOS CODIGOS ---")
  say("registros brutos lidos (todas as causas, RJ): ", format(n_bruto, big.mark = "."))
  say("I60 a I69 por codigo:")
  for (c in CODIGOS_I)
    say(sprintf("  %-5s %9s", c, format(sum(vd[[paste0("I_", c)]]), big.mark = ".")))
  say("  TOTAL ", format(sum(sapply(CODIGOS_I, function(c) sum(vd[[paste0("I_", c)]]))),
                          big.mark = "."))
  say("\nsubcodigos G encontrados:")
  for (c in c("G450","G451","G452","G453","G454","G458","G459",
              "G460","G461","G462","G463","G464","G465","G466","G467","G468")) {
    n <- sum(vd[[paste0("G_", c)]])
    if (n > 0) say(sprintf("  %-5s %9s%s", c, format(n, big.mark = "."),
                           if (c %in% c("G458", "G467", "G468")) "   <== incorporado nesta revisao" else ""))
  }
  say("subcodigos G46 sem nenhum registro na base: ",
      paste(c("G460","G461","G462","G463","G464","G465","G466","G467","G468")[
        sapply(c("G460","G461","G462","G463","G464","G465","G466","G467","G468"),
               function(c) sum(vd[[paste0("G_", c)]]) == 0)], collapse = ", "))
  soma4 <- sum(sapply(c("G450","G451","G452","G453","G454","G458","G459",
                        "G460","G461","G462","G463","G464","G465","G466","G467","G468"),
                      function(c) sum(vd[[paste0("G_", c)]])))
  say("bloco G45/G46 inteiro: ", format(sum(vd$G_bloco), big.mark = "."),
      " | soma dos subcodigos de 4 digitos: ", format(soma4, big.mark = "."),
      " | truncados em 3 digitos: ", format(sum(vd$G_bloco) - soma4, big.mark = "."))

  ## ---------------- 2. união, deduplicacao e período ----------------
  d <- rbindlist(acc[!vapply(acc, is.null, logical(1))], use.names = TRUE, fill = TRUE)
  rm(acc); invisible(gc())
  say("\napos filtro de CID e residencia no RJ: ", format(nrow(d), big.mark = "."))

  DEDUP_KEY <- c("N_AIH", "IDENT", "DT_INTER", "DT_SAIDA", "DIAG_PRINC",
                 "MUNIC_RES6", "SEXO", "IDADE")
  dup <- duplicated(d[, intersect(DEDUP_KEY, names(d)), with = FALSE])
  say("duplicatas removidas: ", format(sum(dup), big.mark = "."))
  d <- d[!dup]

  d[, DT_INTER_d := as.Date(as.character(DT_INTER), format = "%Y%m%d")]
  say("DT_INTER invalida: ", sum(is.na(d$DT_INTER_d)))
  d <- d[!is.na(DT_INTER_d) & DT_INTER_d >= as.Date("2010-01-01") &
           DT_INTER_d <= as.Date("2024-12-31")]
  say("apos filtro DT_INTER 2010-2024: ", format(nrow(d), big.mark = "."))

  ## ---------------- 3. derivadas a partir do código bruto ----------------
  cod2 <- function(x) sprintf("%02d", suppressWarnings(as.integer(as.character(x))))
  cod1 <- function(x) as.character(suppressWarnings(as.integer(as.character(x))))

  CAR_MAP <- c("01"="Eletiva","02"="Urgencia","03"="Acidente trabalho",
               "04"="Acidente trajeto","05"="Outros acidentes","06"="Outras lesoes",
               "07"="Outros")
  ## Ausente e representado por NA, como o R faz nativamente. Os códigos que a
  ## propria fonte usa para "sem informação" ou "ignorado" (99 em RACA_COR,
  ## 9 em INSTRU) NÃO recebem rótulo: viram NA, para não criar uma categoria
  ## falsa que se confundiria com um nível real da variável.
  RACA_MAP <- c("01"="Branca","02"="Preta","03"="Parda","04"="Amarela",
                "05"="Indigena")
  INSTRU_MAP <- c("0"="Sem instrucao","1"="Fundamental I incompleto",
                  "2"="Fundamental I completo","3"="Fundamental II incompleto",
                  "4"="Fundamental II completo","5"="Medio completo",
                  "6"="Superior incompleto","7"="Superior completo")

  d[, sexo := unname(c("1"="M","3"="F")[as.character(SEXO)])]
  d[is.na(sexo), sexo := "I"]
  d[, idade_anos := suppressWarnings(as.numeric(as.character(IDADE)))]
  cod <- as.character(d$COD_IDADE)
  d[cod == "3", idade_anos := idade_anos / 12]
  d[cod == "2", idade_anos := idade_anos / 365]
  d[cod == "1", idade_anos := idade_anos / (365 * 24)]

  ## Ausente permanece NA: não se cria rótulo para ausencia.
  d[, car_int := unname(CAR_MAP[cod2(CAR_INT)])]
  d[, raca_cor := unname(RACA_MAP[cod2(RACA_COR)])]
  d[, instru := unname(INSTRU_MAP[cod1(INSTRU)])]
  d[, obito_hospitalar := as.integer(as.character(MORTE) == "1")]
  d[, UTI_MES_TO := suppressWarnings(as.numeric(as.character(UTI_MES_TO)))]
  d[, DIAS_PERM := suppressWarnings(as.numeric(as.character(DIAS_PERM)))]
  d[, VAL_TOT := suppressWarnings(as.numeric(as.character(VAL_TOT)))]
  d[, uti := as.integer(!is.na(UTI_MES_TO) & UTI_MES_TO > 0)]
  d[, uti_marca := as.integer(!is.na(MARCA_UTI) & cod2(MARCA_UTI) != "00")]
  d[, UTI_INT_TO := suppressWarnings(as.numeric(as.character(UTI_INT_TO)))]
  d[, VAL_UTI := suppressWarnings(as.numeric(as.character(VAL_UTI)))]
  d[, US_TOT := suppressWarnings(as.numeric(as.character(US_TOT)))]

  ## ---- variáveis de complexidade e comorbidade ----
  ## ATENÇÃO, verificado nos arquivos brutos antes de derivar:
  ##   DIAGSEC1 a DIAGSEC9 NÃO EXISTEM antes de 2016 e, mesmo depois, estão
  ##     preenchidos em apenas 18% a 22% dos registros (DIAGSEC1) e menos de
  ##     4% (DIAGSEC2). A carga de comorbidade e, portanto, fraca e só pode ser
  ##     usada como sensibilidade no período de 2016 a 2024.
  ##   INFEHOSP esta 100% vazio em todos os anos: inutilizavel.
  ##   CID_ASSO só traz "0000": inutilizavel.
  ##   NAT_JUR e um código de 4 digitos (1015, 1023, ...). O primeiro digito
  ##     indica a categoria ampla, que e o que se usa aqui.
  ##   COMPLEX só assume 02 (média) e 03 (básica) nesta base.
  SEC <- intersect(paste0("DIAGSEC", 1:9), names(d))
  for (v in SEC) d[[v]] <- toupper(trimws(as.character(d[[v]])))
  d[, n_diag_sec := Reduce(`+`, lapply(SEC, function(v)
    as.integer(!is.na(d[[v]]) & d[[v]] != "" & d[[v]] != "0000")))]
  d[, diagsec_disp := as.integer(as.integer(as.character(ANO_CMPT)) >= 2016)]
  d[, complex_lab := unname(c("01" = "Alta complexidade", "02" = "Media complexidade",
                              "03" = "Basica")[cod2(COMPLEX)])]
  NAT_MAP <- c("1" = "Administracao publica", "2" = "Entidades empresariais",
               "3" = "Entidades sem fins lucrativos", "4" = "Pessoas fisicas",
               "5" = "Organizacoes internacionais")
  d[, nat_jur_lab := unname(NAT_MAP[substr(as.character(NAT_JUR), 1, 1)])]
  d[, MUNIC_MOV6 := sprintf("%06s", as.character(MUNIC_MOV))]
  d[, fluxo_inter := fifelse(is.na(MUNIC_MOV6), NA_integer_,
                             as.integer(MUNIC_RES6 != MUNIC_MOV6))]
  d[, ano := as.integer(format(DT_INTER_d, "%Y"))]

  d[, subtipo := fcase(
    cid3 %in% c("I60","I61","I62"), "Hemorragico (I60-I62)",
    cid3 == "I63", "Isquemico (I63)",
    cid3 == "I64", "Nao especificado (I64)",
    cid3 %in% c("I65","I66","I67","I68"), "Oclusao e outras (I65-I68)",
    cid3 == "I69", "Sequelas (I69)",
    cid3 == "G45", "AIT (G45)",
    cid3 == "G46", "Sindromes vasculares (G46)",
    default = "Outros")]
  d[, subtipo := factor(subtipo, levels = c(
    "Nao especificado (I64)", "Hemorragico (I60-I62)", "Isquemico (I63)",
    "Oclusao e outras (I65-I68)", "Sequelas (I69)", "AIT (G45)",
    "Sindromes vasculares (G46)", "Outros"))]
  d[, coorte := fifelse(cid3 %in% CODIGOS_I, "I60-I69", "G45/G46")]

  ## idade padronizada: o Bloco 2 pede idade continua padronizada, de modo que
  ## o OR seja lido por aumento de um desvio-padrão
  d[, idade_z := (idade_anos - mean(idade_anos, na.rm = TRUE)) /
        sd(idade_anos, na.rm = TRUE)]
  say("\nidade: media=", round(mean(d$idade_anos, na.rm = TRUE), 2),
      " | DP=", round(sd(d$idade_anos, na.rm = TRUE), 2),
      " (OR por +1 DP de idade)")

  ## ---------------- 4. região de saúde ----------------
  lk <- fread(LOOKUP, colClasses = "character", encoding = "UTF-8")
  lk[, ibge6 := sprintf("%06s", ibge6)]
  d <- merge(d, lk[, .(ibge6, mun_nome, regiao_saude = macro_regiao)],
             by.x = "MUNIC_RES6", by.y = "ibge6", all.x = TRUE, sort = FALSE)
  d <- merge(d, lk[, .(ibge6, mun_nome_mov = mun_nome)],
             by.x = "MUNIC_MOV6", by.y = "ibge6", all.x = TRUE, sort = FALSE)

  d[, sexo := factor(sexo, levels = c("F","M","I"))]
  d[, car_int := factor(car_int, levels = c("Eletiva","Urgencia","Acidente trabalho",
                                            "Acidente trajeto","Outros acidentes",
                                            "Outras lesoes","Outros"))]
  d[, regiao_saude := factor(regiao_saude, levels = c(
    "Metropolitana I","Metropolitana II","Baixada Litoranea","Norte","Noroeste",
    "Serrana","Centro-Sul","Medio Paraiba","Baia da Ilha Grande"))]
  d[, CNES := factor(trimws(as.character(CNES)))]
  for (v in c("sexo","subtipo","car_int","regiao_saude","CNES"))
    d[, (v) := droplevels(get(v))]

  ## ---------------- 5. trava de seguranca ----------------
  crit <- c("obito_hospitalar","idade_anos","sexo","subtipo","car_int","uti",
            "fluxo_inter","regiao_saude","CNES")
  say("\n--- TRAVA DE SEGURANCA (covariaveis do modelo) ---")
  falha <- FALSE
  for (v in crit) {
    na <- sum(is.na(d[[v]])); pct <- 100 * na / nrow(d)
    if (pct > 0.1) falha <- TRUE
    say(sprintf("  %-18s ausentes=%7d (%6.3f%%)%s", v, na, pct,
                if (pct > 0.1) "   <== FALHA" else ""))
  }
  if (falha) stop("covariavel do modelo com perda acima de 0,1%")
  say("  OK: nenhuma covariavel com perda acima de 0,1%")

  ## ---------------- 6. composicao ----------------
  say("\n--- COMPOSICAO ---")
  say("internacoes: ", format(nrow(d), big.mark = "."),
      " | obitos: ", format(sum(d$obito_hospitalar), big.mark = "."),
      sprintf(" (%.2f%%)", 100 * mean(d$obito_hospitalar)))
  say("estabelecimentos (CNES): ", uniqueN(d$CNES),
      " | regioes de saude: ", uniqueN(d$regiao_saude))

  blocos <- list("Por coorte" = "coorte", "Por subtipo" = "subtipo",
                 "Por regiao de saude" = "regiao_saude", "Por carater" = "car_int",
                 "Por sexo" = "sexo")
  for (nm in names(blocos)) {
    v <- blocos[[nm]]
    say("\n", nm, ":")
    t <- d[, .(n = .N, obitos = sum(obito_hospitalar),
               mortalidade = round(100 * mean(obito_hospitalar), 2),
               idade_mediana = median(idade_anos)), by = v][order(-n)]
    for (i in seq_len(nrow(t)))
      say(sprintf("  %-30s n=%8s obitos=%7s mortalidade=%6.2f%% idade_mediana=%3.0f",
                  as.character(t[[v]][i]), format(t$n[i], big.mark = "."),
                  format(t$obitos[i], big.mark = "."), t$mortalidade[i],
                  t$idade_mediana[i]))
  }

  say("\ncomposicao dos codigos G (subtipo G45 e G46):")
  t <- d[cid3 %in% G_BLOCO, .N, by = cid4][order(-N)]
  for (i in seq_len(nrow(t))) say(sprintf("  %-6s %7s", t$cid4[i],
                                          format(t$N[i], big.mark = ".")))

  say("\nPor ano:")
  t <- d[, .(n = .N, obitos = sum(obito_hospitalar),
             mortalidade = round(100 * mean(obito_hospitalar), 2),
             uti_pct = round(100 * mean(uti), 2)), by = ano][order(ano)]
  for (i in seq_len(nrow(t)))
    say(sprintf("  %d  n=%8s obitos=%7s mortalidade=%6.2f%% UTI=%6.2f%%",
                t$ano[i], format(t$n[i], big.mark = "."),
                format(t$obitos[i], big.mark = "."), t$mortalidade[i], t$uti_pct[i]))

  h <- d[, .(n = .N, obitos = sum(obito_hospitalar),
             mortalidade = round(100 * mean(obito_hospitalar), 3)), by = CNES][order(-n)]
  say("\nHospitais: ", nrow(h))
  for (k in c(1,5,10,25,50,100)) if (k <= nrow(h))
    say(sprintf("  top %3d concentram %8s (%5.1f%%)", k,
                format(sum(h$n[1:k]), big.mark = "."), 100 * sum(h$n[1:k]) / nrow(d)))
  say("  hospitais com menos de 100 internacoes: ", sum(h$n < 100))
  say("  hospitais com menos de 30 internacoes:  ", sum(h$n < 30))
  say("  hospitais sem nenhum obito:             ", sum(h$obitos == 0))
  fwrite(h, file.path(TAB, "tab_hospitais.csv"), encoding = "UTF-8", na = "NA")

  ## ---------------- 7. gravacao ----------------
  ## N_AIH, IDENT e DT_SAIDA ficam na base de análise por rastreabilidade e
  ## para que a auditoria (script 07) possa reverificar a deduplicacao, que só
  ## e checavel com a chave completa.
  OUT <- c("N_AIH","IDENT","DT_INTER_d","DT_SAIDA","CNES","coorte","obito_hospitalar",
           "idade_anos","idade_z","sexo","car_int","subtipo","cid3","cid4","uti",
           "uti_marca","fluxo_inter","regiao_saude","mun_nome","mun_nome_mov","ano",
           "UTI_MES_TO","DIAS_PERM","VAL_TOT","raca_cor","instru","MUNIC_RES6",
           "MUNIC_MOV6","UTI_INT_TO","VAL_UTI","US_TOT","n_diag_sec","diagsec_disp",
           "complex_lab","nat_jur_lab","PROC_REA","DIAR_ACOM","ESPEC","NATUREZA",
           "COMPLEX","NAT_JUR","INFEHOSP","CID_ASSO",
           intersect(paste0("DIAGSEC", 1:9), names(d)))
  f <- file.path(PROC, "coorte_glmm_2010_2024.csv")
  ## na = "NA": sem isso o fwrite grava ausente como string vazia e o NA
  say("\ngravado: ", f)
  say("  linhas: ", format(nrow(d), big.mark = "."), " | colunas: ", length(OUT))
  say("fim: ", format(Sys.time()))
  close(logcon)
})
