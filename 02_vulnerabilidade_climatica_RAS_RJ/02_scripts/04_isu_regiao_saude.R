# =====================================================================
# 04_isu_regiao_saude.R
# ---------------------------------------------------------------------
# Bloco 1.3 do PLANO_METODOLOGICO_GLMM_COX.md
# Indice de Swaroop-Uemura (ISU) estratificado por REGIAO DE SAUDE,
# a partir dos microdados do SIM-DO baixados pelo microdatasus (script 01).
#
#   ISU = (obitos com 50 anos ou mais / total de obitos por DCV) * 100
#
# Etapas:
#   1. Le os .rds anuais do SIM e mantem causa basica em I60 a I69 e
#      residentes no estado do Rio de Janeiro.
#   2. Decodifica o campo IDADE, que usa a centena como unidade de tempo:
#      4xx = anos, 5xx = 100+xx anos, 3xx = meses, 2xx = horas,
#      1xx = minutos, 999 = ignorada.
#   3. Filtra DTOBITO entre 2010 e 2024.
#   4. Calcula o ISU por regiao de saude, com sensibilidades.
#   5. Quantifica G45 e G46 como causa basica, para declarar a assimetria
#      entre a coorte de internacoes (SIH) e a serie de mortalidade (SIM).
#
# Saidas:
#   05_tabelas/tab6_isu_regiao_saude.csv
#   05_tabelas/tab7_isu_regiao_ano.csv
#   04_resultados/resultados_isu.txt
#   06_figuras/fig_isu_regiao.png
# =====================================================================

suppressWarnings({
  options(stringsAsFactors = FALSE)
  library(data.table)
  library(ggplot2)

  ROOT <- normalizePath(".")
  DIR_SIM <- file.path(ROOT, "01_dados", "brutos_sim")
  RES <- file.path(ROOT, "04_resultados")
  TAB <- file.path(ROOT, "05_tabelas")
  FIG <- file.path(ROOT, "06_figuras", "suplementares")
  LOOKUP <- file.path(dirname(ROOT), "01_DLNMs_RJ_cerebrovascular", "data_processed",
                      "lookup_municipio_macrorregiao.csv")
  for (d in c(RES, TAB, FIG)) dir.create(d, showWarnings = FALSE, recursive = TRUE)

  logcon <- file(file.path(RES, "resultados_isu.txt"), open = "wt", encoding = "UTF-8")
  say <- function(...) { m <- paste0(...); cat(m, "\n"); writeLines(m, logcon); flush(logcon) }

  say("=====================================================================")
  say("INDICE DE SWAROOP-UEMURA POR REGIAO DE SAUDE")
  say("fonte: microdados do SIM-DO baixados pelo microdatasus")
  say("R ", R.version.string, " | inicio: ", format(Sys.time()))
  say("=====================================================================")

  CODIGOS_I <- sprintf("I6%d", 0:9)

  ## ---------------- 1. leitura dos .rds do SIM ----------------
  fs <- sort(list.files(DIR_SIM, pattern = "^sim_do_rj_[0-9]{4}\\.rds$", full.names = TRUE))
  say("arquivos anuais do SIM-DO: ", length(fs))
  if (!length(fs)) stop("nenhum arquivo do SIM em ", DIR_SIM)

  decod_idade <- function(v) {
    v <- suppressWarnings(as.numeric(v))
    out <- rep(NA_real_, length(v))
    cent <- v %/% 100; resto <- v %% 100
    out[cent == 4] <- resto[cent == 4]
    out[cent == 5] <- 100 + resto[cent == 5]
    out[cent == 3] <- resto[cent == 3] / 12
    out[cent == 2] <- resto[cent == 2] / (365 * 24)
    out[cent == 1] <- resto[cent == 1] / (365 * 24 * 60)
    out[v == 999] <- NA_real_
    out
  }

  partes <- list(); verif <- list()
  for (f in fs) {
    d <- readRDS(f)
    cb <- toupper(trimws(as.character(d[["CAUSABAS"]])))
    cb3 <- substr(cb, 1, 3)
    muni <- sprintf("%06s", as.character(d[["CODMUNRES"]]))
    sel_rj <- substr(muni, 1, 2) == "33"
    verif[[basename(f)]] <- data.table(
      arquivo = basename(f), n_total = nrow(d),
      n_I60_I69_RJ = sum(cb3 %in% CODIGOS_I & sel_rj),
      n_G45_G46_RJ = sum(cb3 %in% c("G45", "G46") & sel_rj))
    sel <- cb3 %in% CODIGOS_I & sel_rj
    if (any(sel)) {
      x <- as.data.table(d[sel, intersect(c("DTOBITO", "IDADE", "SEXO", "RACACOR",
                                            "LOCOCOR", "CODMUNRES"),
                                          names(d)), drop = FALSE])
      x[, cid3 := cb3[sel]]
      x[, cid4 := substr(cb[sel], 1, 4)]
      x[, MUNIC_RES6 := muni[sel]]
      partes[[length(partes) + 1]] <- x
    }
  }
  sim <- rbindlist(partes, use.names = TRUE, fill = TRUE)
  vd <- rbindlist(verif)
  say("obitos por DCV I60-I69, residentes no RJ (todas as competicoes): ",
      format(nrow(sim), big.mark = "."))

  ## ---------------- 2. derivadas e periodo ----------------
  sim[, idade_anos := decod_idade(IDADE)]
  dt <- as.Date(as.character(sim$DTOBITO), format = "%d%m%Y")
  say("DTOBITO invalida: ", sum(is.na(dt)))
  sim[, ano := as.integer(format(dt, "%Y"))]
  sim <- sim[!is.na(dt) & dt >= as.Date("2010-01-01") & dt <= as.Date("2024-12-31")]
  say("apos filtro DTOBITO 2010-2024: ", format(nrow(sim), big.mark = "."))
  say("idade ignorada (codigo 999): ", format(sum(is.na(sim$idade_anos)), big.mark = "."),
      sprintf(" (%.3f%%)", 100 * mean(is.na(sim$idade_anos))))

  lk <- fread(LOOKUP, colClasses = "character", encoding = "UTF-8")
  lk[, ibge6 := sprintf("%06s", ibge6)]
  sim <- merge(sim, lk[, .(ibge6, regiao_saude = macro_regiao)],
               by.x = "MUNIC_RES6", by.y = "ibge6", all.x = TRUE, sort = FALSE)
  say("obitos sem municipio correspondente no lookup: ",
      format(sum(is.na(sim$regiao_saude)), big.mark = "."),
      sprintf(" (%.3f%%)", 100 * mean(is.na(sim$regiao_saude))))

  ## ---------------- 3. ISU por regiao de saude ----------------
  sim[, regiao_rot := fifelse(is.na(regiao_saude), "SEM MUNICIPIO CORRESPONDENTE",
                              regiao_saude)]
  isu_reg <- sim[, .(
    obitos_total = .N,
    obitos_idade_conhecida = sum(!is.na(idade_anos)),
    obitos_50mais = sum(idade_anos >= 50, na.rm = TRUE),
    obitos_65mais = sum(idade_anos >= 65, na.rm = TRUE),
    obitos_sem_i69 = sum(cid3 != "I69"),
    obitos_50mais_sem_i69 = sum(idade_anos >= 50 & cid3 != "I69", na.rm = TRUE),
    idade_mediana = median(idade_anos, na.rm = TRUE)), by = regiao_rot]
  setnames(isu_reg, "regiao_rot", "regiao_saude")
  isu_reg[, `:=`(
    ISU = round(100 * obitos_50mais / obitos_total, 2),
    ISU_idade_conhecida = round(100 * obitos_50mais / obitos_idade_conhecida, 2),
    ISU_corte65 = round(100 * obitos_65mais / obitos_total, 2),
    ISU_sem_I69 = round(100 * obitos_50mais_sem_i69 / obitos_sem_i69, 2))]
  setorder(isu_reg, -ISU)

  isu_geral <- data.table(
    regiao_saude = "ESTADO DO RJ",
    obitos_total = nrow(sim),
    obitos_idade_conhecida = sum(!is.na(sim$idade_anos)),
    obitos_50mais = sum(sim$idade_anos >= 50, na.rm = TRUE),
    obitos_65mais = sum(sim$idade_anos >= 65, na.rm = TRUE),
    obitos_sem_i69 = sum(sim$cid3 != "I69"),
    obitos_50mais_sem_i69 = sum(sim$idade_anos >= 50 & sim$cid3 != "I69", na.rm = TRUE),
    idade_mediana = median(sim$idade_anos, na.rm = TRUE))
  isu_geral[, `:=`(
    ISU = round(100 * obitos_50mais / obitos_total, 2),
    ISU_idade_conhecida = round(100 * obitos_50mais / obitos_idade_conhecida, 2),
    ISU_corte65 = round(100 * obitos_65mais / obitos_total, 2),
    ISU_sem_I69 = round(100 * obitos_50mais_sem_i69 / obitos_sem_i69, 2))]

  say("\n--- ISU POR REGIAO DE SAUDE ---")
  say(sprintf("  %-34s %9s %8s %9s %10s", "regiao", "obitos", "ISU(%)", "ISU>=65", "ISU s/I69"))
  for (i in seq_len(nrow(isu_reg)))
    say(sprintf("  %-34s %9s %8.2f %9.2f %10.2f", isu_reg$regiao_saude[i],
                format(isu_reg$obitos_total[i], big.mark = "."), isu_reg$ISU[i],
                isu_reg$ISU_corte65[i], isu_reg$ISU_sem_I69[i]))
  say(sprintf("  %-34s %9s %8.2f %9.2f %10.2f", "ESTADO DO RJ",
              format(isu_geral$obitos_total, big.mark = "."), isu_geral$ISU,
              isu_geral$ISU_corte65, isu_geral$ISU_sem_I69))

  ok <- isu_reg[regiao_saude != "SEM MUNICIPIO CORRESPONDENTE"]
  say(sprintf("\namplitude regional do ISU: %.2f pontos percentuais (maximo %.2f em %s; minimo %.2f em %s)",
              max(ok$ISU) - min(ok$ISU), max(ok$ISU),
              ok$regiao_saude[which.max(ok$ISU)], min(ok$ISU),
              ok$regiao_saude[which.min(ok$ISU)]))
  say(sprintf("amplitude com corte em 65 anos: %.2f pontos percentuais",
              max(ok$ISU_corte65) - min(ok$ISU_corte65)))
  say("O ISU por DCV tem faixa estreita por construcao, porque a mortalidade")
  say("cerebrovascular ja se concentra em idades avancadas. O corte em 65 anos")
  say("separa melhor os territorios.")

  fwrite(rbind(isu_reg, isu_geral, fill = TRUE),
         file.path(TAB, "tab6_isu_regiao_saude.csv"), encoding = "UTF-8")

  ## ---------------- 4. ISU por regiao e ano ----------------
  ra <- sim[!is.na(regiao_saude), .(obitos = .N,
                                    obitos_50mais = sum(idade_anos >= 50, na.rm = TRUE)),
            by = .(regiao_saude, ano)]
  ra[, ISU := round(100 * obitos_50mais / obitos, 2)]
  setorder(ra, regiao_saude, ano)
  fwrite(ra, file.path(TAB, "tab7_isu_regiao_ano.csv"), encoding = "UTF-8")

  say("\n--- ISU POR REGIAO E ANO (2010, 2015, 2020, 2024) ---")
  sel <- ra[ano %in% c(2010, 2015, 2020, 2024)]
  for (rg in unique(sel$regiao_saude)) {
    v <- sel[regiao_saude == rg]
    say(sprintf("  %-24s %s", rg,
                paste(sprintf("%d=%.1f", v$ano, v$ISU), collapse = "  ")))
  }

  ## ---------------- 5. assimetria SIH x SIM ----------------
  say("\n--- SIMETRIA ENTRE AS COORTES: G45/G46 COMO CAUSA BASICA ---")
  tot_g <- sum(vd$n_G45_G46_RJ); tot_all <- sum(vd$n_total)
  say("  obitos com G45/G46 como causa basica (residentes RJ): ",
      format(tot_g, big.mark = "."), " de ", format(tot_all, big.mark = "."),
      sprintf(" (%.4f%%)", 100 * tot_g / tot_all))
  say("  A ampliacao diagnostica do Bloco 1.1 vale para a coorte de internacoes.")
  say("  A serie de mortalidade permanece em I60-I69 e a assimetria e desprezivel,")
  say("  mas precisa ser declarada como limitacao.")

  ## ---------------- 6. figura ----------------
  ## Paleta viridis: as barras sao coloridas pelo proprio valor do ISU, de modo
  ## que a cor tambem carrega a informacao; a linha de referencia do estado usa
  ## a extremidade escura da mesma paleta para manter o contraste.
  isu_plot <- isu_reg[regiao_saude != "SEM MUNICIPIO CORRESPONDENTE"]
  COR_REF <- viridisLite::viridis(1, begin = 0.0)
  g <- ggplot(isu_plot, aes(x = reorder(regiao_saude, ISU), y = ISU, fill = ISU)) +
    geom_col(width = 0.7) +
    geom_text(aes(label = sprintf("%.1f", ISU)), hjust = -0.15, size = 3.4,
              colour = "grey20") +
    geom_hline(yintercept = isu_geral$ISU, linetype = "dashed", colour = COR_REF,
               linewidth = 0.6) +
    annotate("text", x = 0.7, y = isu_geral$ISU + 0.6,
             label = sprintf("Estado: %.1f", isu_geral$ISU), hjust = 0, size = 3.2,
             colour = COR_REF) +
    scale_fill_viridis_c(option = "D", name = "ISU (%)") +
    coord_flip(ylim = c(min(isu_plot$ISU) - 3, max(isu_plot$ISU) + 3)) +
    labs(title = "Indice de Swaroop-Uemura por regiao de saude",
         subtitle = "Obitos por doencas cerebrovasculares em pessoas de 50 anos ou mais (%) - RJ, 2010-2024",
         x = NULL, y = "ISU (%)") +
    theme_minimal(base_size = 11) +
    theme(plot.title = element_text(face = "bold"),
          panel.grid.major.y = element_blank())
  ggsave(file.path(FIG, "fig_isu_regiao.png"), g, width = 8, height = 5, dpi = 300)
  say("\nfigura gravada: 06_figuras/fig_isu_regiao.png")

  say("\nfim: ", format(Sys.time()))
  close(logcon)
})
