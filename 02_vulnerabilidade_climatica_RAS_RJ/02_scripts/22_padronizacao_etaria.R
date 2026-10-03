# 22_padronizacao_etaria.R
# Padronizacao etaria direta das taxas de internacao (SIH) e de mortalidade (SIM)
# por doencas cerebrovasculares, por regiao de saude e para o estado.
#
# Método: referencia = estrutura etaria do RJ no Censo 2010 (IBGE/SIDRA tabela 200,
# variavel 93, grupos de idade 1140-1155 e 2503), por municipio, agregada as nove
# regioes. Como nao ha denominador etario anual, a populacao de cada regiao-ano e
# obtida aplicando a estrutura etaria de 2010 (da propria regiao) ao total do ano.
# Taxa padronizada: ASR = sum_i (eventos_i / pop_i * w_i) / sum_i w_i.
#
# Entradas: coorte_glmm_2010_2024.csv, sim_cid_estudo_2010_2024.csv,
#           populacao_sidra..., lookup_municipio_macrorregiao.csv, API SIDRA.
# Saidas:   05_tabelas/tab28_padronizacao_etaria.csv
#           06_figuras/exploratorias/fig_ex26_padronizacao_etaria.png
#           04_resultados/resultados_padronizacao_etaria.txt

suppressWarnings({
  options(stringsAsFactors = FALSE)
  library(data.table)
  library(ggplot2)
  library(viridisLite)
  library(jsonlite)
  library(ragg)

  ROOT <- local({
    d <- normalizePath(".")
    for (i in 1:6) {
      if (dir.exists(file.path(d, "01_dados")) && dir.exists(file.path(d, "02_scripts"))) break
      sub <- file.path(d, "02_vulnerabilidade_climatica_RAS_RJ")
      if (dir.exists(file.path(sub, "01_dados"))) { d <- sub; break }
      pai <- dirname(d); if (pai == d) break; d <- pai
    }
    d
  })
  PROC <- file.path(ROOT, "01_dados", "processados")
  TAB <- file.path(ROOT, "05_tabelas")
  RES <- file.path(ROOT, "04_resultados")
  FIG <- file.path(ROOT, "06_figuras", "exploratorias")
  DLNM <- file.path(dirname(ROOT), "01_DLNMs_RJ_cerebrovascular", "data_processed")
  dir.create(FIG, showWarnings = FALSE, recursive = TRUE)
  dir.create(RES, showWarnings = FALSE, recursive = TRUE)

  logcon <- file(file.path(RES, "resultados_padronizacao_etaria.txt"), open = "wt", encoding = "UTF-8")
  say <- function(...) { m <- paste0(...); cat(m, "\n"); writeLines(m, logcon); flush(logcon) }

  say("PADRONIZACAO ETARIA DAS TAXAS | inicio: ", format(Sys.time()))

  GRUPOS <- c("1140"="0-4","1141"="5-9","1142"="10-14","1143"="15-19","1144"="20-24",
              "1145"="25-29","1146"="30-34","1147"="35-39","1148"="40-44","1149"="45-49",
              "1150"="50-54","1151"="55-59","1152"="60-64","1153"="65-69","1154"="70-74",
              "1155"="75-79",
              ## o agregado "80 anos ou mais" (2503) vem suprimido no SIDRA; usam-se
              ## os grupos individuais 80-84, 85-89, 90-94, 95-99 e 100+
              "6802"="80+","6803"="80+","92963"="80+","92964"="80+","92965"="80+",
              "2503"="80+")
  ROTULOS <- unique(unname(GRUPOS))
  CORTES <- c(0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,Inf)

  lk <- fread(file.path(DLNM, "lookup_municipio_macrorregiao.csv"), colClasses="character", encoding="UTF-8")
  lk[, ibge6 := sprintf("%06s", ibge6)][, ibge7 := sprintf("%07s", ibge7)]

  ## ---------------- 1. populacao por idade (Censo 2010) ----------------
  cods <- paste(lk$ibge7, collapse=",")
  url <- paste0("https://apisidra.ibge.gov.br/values/t/200/n6/", cods, "/v/93/p/2010/c58/all")
  fetch_sidra <- function(u, tries = 5) {
    for (k in seq_len(tries)) {
      r <- tryCatch(fromJSON(u), error = function(e) NULL)
      if (!is.null(r) && "D1C" %in% names(r)) return(as.data.table(r))
      Sys.sleep(5 * k)
    }
    stop("falha ao obter a estrutura etaria do SIDRA (tabela 200)")
  }
  raw <- fetch_sidra(url)
  raw <- raw[grepl("^[0-9]{7}$", D1C) & D5C == "0" & D6C == "0" & D4C %in% names(GRUPOS)]
  pop10 <- raw[, .(ibge7 = sprintf("%07s", as.character(D1C)),
                   grupo = unname(GRUPOS[as.character(D4C)]),
                   pop = suppressWarnings(as.numeric(V)))]
  pop10[is.na(pop), pop := 0]
  pop10 <- merge(pop10, lk[, .(ibge7, regiao_saude = macro_regiao)], by="ibge7", all.x=TRUE)
  pop_reg10 <- pop10[, .(pop = sum(pop, na.rm=TRUE)), by=.(regiao_saude, grupo)]
  ## estado como pseudo-regiao
  pop_reg10 <- rbind(pop_reg10,
                     pop_reg10[, .(regiao_saude = "ESTADO DO RJ", pop = sum(pop)), by=grupo])
  pop_reg10[, grupo := factor(grupo, levels=ROTULOS)]

  ## totais populacionais anuais (fonte auditada)
  pop <- fread(file.path(DLNM, "populacao_sidra_municipio_rj_2010-2025.csv"), encoding="UTF-8")
  pop[, ano := as.integer(ano)][, populacao := as.numeric(populacao)]
  pop[, ibge6 := sprintf("%06s", as.character(ibge6))]
  pop <- merge(pop, lk[, .(ibge6, regiao_saude = macro_regiao)], by="ibge6", all.x=TRUE)
  pop_tot <- pop[ano %in% 2010:2024, .(pop_total = sum(populacao, na.rm=TRUE)), by=.(regiao_saude, ano)]
  pop_tot <- rbind(pop_tot, pop[ano %in% 2010:2024,
                 .(regiao_saude = "ESTADO DO RJ", pop_total = sum(populacao, na.rm=TRUE)), by=ano])
  base10 <- pop_reg10[, .(pop_total_2010 = sum(pop)), by=regiao_saude]
  ref <- pop_reg10[regiao_saude == "ESTADO DO RJ", .(grupo, w = pop)]

  den <- CJ(regiao_saude = unique(pop_reg10$regiao_saude), ano = 2010:2024)
  den <- merge(den, pop_reg10, by="regiao_saude", allow.cartesian=TRUE)
  den <- merge(den, pop_tot, by=c("regiao_saude","ano"))
  den <- merge(den, base10, by="regiao_saude")
  den[, pop_i := pop * pop_total / pop_total_2010]

  ## ---------------- 2. eventos por idade ----------------
  co <- fread(file.path(PROC, "coorte_glmm_2010_2024.csv"), encoding="UTF-8",
              na.strings=c("NA",""), select=c("ano","regiao_saude","idade_anos","coorte"))
  ## coorte completa: I60-I69 + G45/G46 (ambas as classes)
  co <- co[!is.na(idade_anos)]
  co[, grupo := cut(idade_anos, breaks=CORTES, right=FALSE, labels=ROTULOS)]
  ev_sih <- co[, .(n = .N), by=.(regiao_saude, ano, grupo)]
  ev_sih <- rbind(ev_sih, co[, .(regiao_saude="ESTADO DO RJ", n=.N), by=.(ano, grupo)])

  sim <- fread(file.path(PROC, "sim_cid_estudo_2010_2024.csv"), encoding="UTF-8",
               colClasses="character", na.strings=c("NA",""))
  sim[, dto := as.Date(DTOBITO, format="%d%m%Y")]
  sim[, ano := as.integer(format(dto, "%Y"))]
  sim[, v := suppressWarnings(as.numeric(IDADE))]
  sim[, `:=`(cent = v %/% 100, rest = v %% 100)]
  sim[, idade_anos := NA_real_]
  sim[cent == 4, idade_anos := rest]
  sim[cent == 5, idade_anos := 100 + rest]
  sim[v == 999, idade_anos := NA_real_]
  sim <- merge(sim, lk[, .(ibge6, regiao = macro_regiao)], by.x="CODMUNRES", by.y="ibge6",
               all.x=TRUE, sort=FALSE)
  sim <- sim[!is.na(regiao) & !is.na(idade_anos)]
  sim[, grupo := cut(idade_anos, breaks=CORTES, right=FALSE, labels=ROTULOS)]
  ev_sim <- sim[, .(n = .N), by=.(regiao_saude = regiao, ano, grupo)]
  ev_sim <- rbind(ev_sim, sim[, .(regiao_saude="ESTADO DO RJ", n=.N), by=.(ano, grupo)])

  ## ---------------- 3. taxas padronizadas ----------------
  padroniza <- function(ev, rotulo) {
    d <- merge(den, ev, by=c("regiao_saude","ano","grupo"), all.x=TRUE)
    d[is.na(n), n := 0L]
    d <- merge(d, ref, by="grupo")
    out <- d[, .(casos = sum(n), pop = sum(pop_i),
                 taxa_bruta = 100000 * sum(n) / sum(pop_i),
                 taxa_padronizada = 100000 * sum(n / pop_i * w) / sum(w)),
             by=.(regiao_saude, ano)]
    out[, tipo := rotulo]
    out
  }
  tp <- rbind(padroniza(ev_sih, "Internação"), padroniza(ev_sim, "Mortalidade"))
  fwrite(tp, file.path(TAB, "tab28_padronizacao_etaria.csv"), encoding="UTF-8")
  say("linhas da tabela de padronizacao: ", nrow(tp))

  ## ---------------- 4. figura ----------------
  dd <- tp[ano %in% c(2010, 2024)]
  dd[, ano := factor(ano)]
  g <- ggplot(dd, aes(x = taxa_bruta, y = taxa_padronizada, colour = ano, shape = tipo)) +
    geom_abline(slope = 1, intercept = 0, linetype = 2, colour = "grey55") +
    geom_point(size = 2.2) +
    scale_colour_viridis_d(option = "D", end = 0.8) +
    labs(title = "Taxas brutas e padronizadas por idade",
         subtitle = "Internação e mortalidade por DCV por região de saúde; referência = estrutura etária do RJ (Censo 2010)",
         x = "Taxa bruta (/100.000)", y = "Taxa padronizada (/100.000)",
         colour = "Ano", shape = "Desfecho") +
    theme_minimal(base_size = 10) +
    theme(legend.position = "top")
  ggsave(file.path(FIG, "fig_ex26_padronizacao_etaria.png"), g, width = 8, height = 5,
         dpi = 300, device = ragg::agg_png)
  say("figura gravada: fig_ex26_padronizacao_etaria.png")

  rr <- tp[regiao_saude == "ESTADO DO RJ" & ano %in% c(2010, 2024)]
  for (tp_ in unique(rr$tipo)) {
    x <- rr[tipo == tp_][order(ano)]
    say(sprintf("  %s - estado: bruta %.2f -> %.2f; padronizada %.2f -> %.2f",
                tp_, x$taxa_bruta[1], x$taxa_bruta[2],
                x$taxa_padronizada[1], x$taxa_padronizada[2]))
  }
  say("fim: ", format(Sys.time()))
  close(logcon)
})
