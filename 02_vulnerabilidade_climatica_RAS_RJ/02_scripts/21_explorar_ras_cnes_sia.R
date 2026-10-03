# 21_explorar_ras_cnes_sia.R
# Exploracao dos dados de CNES/SIA uteis a analise, baixados pela API de Dados
# Abertos do Ministerio da Saude (script 20). Foca na CAPACIDADE INSTALADA
# relevante ao cuidado cerebrovascular e a organizacao da RAS:
#   - leitos: destaque para UTI/UCI;
#   - equipamentos: tomografia, ressonancia magnetica e hemodinamica (angiografia);
#   - servicos especializados: diagnostico por imagem, urgencia/emergencia e
#     atencao em neurologia/neurocirurgia e terapia intensiva;
#   - profissionais: neurologistas, neurocirurgioes e intensivistas (CBO);
#   - SIA: producao ambulatorial (reabilitacao/fisioterapia) disponivel.
#
# Entradas: 01_dados/brutos_cnes_sia/api_*.rds (script 20)
# Saidas:   05_tabelas/tab29_ras_capacidade.csv
#           05_tabelas/tab29b_ras_cnes_hospital.csv
#           06_figuras/exploratorias/fig_ex27_ras_capacidade.png
#           04_resultados/resultados_ras_cnes_sia.txt

suppressWarnings({
  options(stringsAsFactors = FALSE)
  library(data.table)
  library(ggplot2)
  library(viridisLite)
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
  DIR <- file.path(ROOT, "01_dados", "brutos_cnes_sia")
  TAB <- file.path(ROOT, "05_tabelas")
  RES <- file.path(ROOT, "04_resultados")
  FIG <- file.path(ROOT, "06_figuras", "exploratorias")
  DLNM <- file.path(dirname(ROOT), "01_DLNMs_RJ_cerebrovascular", "data_processed")
  dir.create(FIG, showWarnings = FALSE, recursive = TRUE)

  logcon <- file(file.path(RES, "resultados_ras_cnes_sia.txt"), open = "wt", encoding = "UTF-8")
  say <- function(...) { m <- paste0(...); cat(m, "\n"); writeLines(m, logcon); flush(logcon) }

  say("CAPACIDADE INSTALADA DA RAS (CNES/SIA) | inicio: ", format(Sys.time()))
  fs <- list.files(DIR, pattern = "^api_.*[.]rds$", full.names = TRUE)
  say("arquivos da API: ", length(fs), " (", paste(basename(fs), collapse = ", "), ")")
  if (!length(fs)) { say("Nada em ", DIR, "; rode o script 20."); close(logcon); quit(save = "no") }

  lk <- fread(file.path(DLNM, "lookup_municipio_macrorregiao.csv"), colClasses = "character", encoding = "UTF-8")
  lk[, ibge6 := sprintf("%06d", as.integer(gsub("[^0-9]", "", ibge6)))]
  reg_de <- function(x) lk$macro_regiao[match(sprintf("%06d", as.integer(gsub("[^0-9]", "", x))), lk$ibge6)]
  ult_cnes <- function(d) {
    d <- copy(d); d[, .mx := max(nu_comp, na.rm = TRUE), by = co_cnes]
    d <- d[nu_comp == .mx]; d[, .mx := NULL]; d
  }

  ## ---------------- leitos: UTI/UCI ----------------
  le <- as.data.table(readRDS(file.path(DIR, "api_cnes_leitos.rds")))
  le[, uti := grepl("UTI|UCI|CUIDADOS INTENSIV", ignore.case = TRUE, ds_leito)]
  le[, neuro := grepl("NEUROLOG|NEUROCIRURG", ignore.case = TRUE, ds_leito)]

  ## ---------------- equipamentos de imagem ----------------
  eq <- as.data.table(readRDS(file.path(DIR, "api_cnes_equipamentos.rds")))
  eq[, tc   := grepl("Tom.grafo", ignore.case = TRUE, ds_equipamento)]
  eq[, rm   := grepl("Ressonancia Magnetica", ignore.case = TRUE, ds_equipamento)]
  eq[, hemo := grepl("Hemodinamica", ignore.case = TRUE, ds_equipamento)]

  ## ---------------- servicos especializados ----------------
  se <- as.data.table(readRDS(file.path(DIR, "api_cnes_servicos_especializados.rds")))
  se[, imagem := grepl("DIAGNOSTICO POR IMAGEM", ignore.case = TRUE, ds_servico)]
  se[, urgencia := grepl("URGENCIA E EMERGENCIA", ignore.case = TRUE, ds_servico)]
  se[, neuro := grepl("NEUROLOGIA", ignore.case = TRUE, ds_servico)]
  se[, uti_serv := grepl("TERAPIA INTENSIVA", ignore.case = TRUE, ds_servico)]

  ## ---------------- profissionais (CBO) ----------------
  pr <- as.data.table(readRDS(file.path(DIR, "api_cnes_profissionais.rds")))
  pr[, neuro := grepl("NEUROLOG|NEUROCIRURG", ignore.case = TRUE, ds_cbo)]
  pr[, intens := grepl("MEDICINA INTENSIVA|TERAPIA INTENSIVA", ignore.case = TRUE, ds_cbo)]

  ## selecoes por CNES
  le_u <- ult_cnes(le[uti == TRUE])
  le_n <- ult_cnes(le[neuro == TRUE])
  eq_u <- eq   # presenca em qualquer competencia
  se_u <- se   # presenca em qualquer competencia
  pr_u <- pr  # todas as competencias (dados esparsos); conta profissionais distintos

  ## ---------------- consolidacao por hospital (CNES) ----------------
  norm7 <- function(x) sprintf("%07d", as.integer(gsub("[^0-9]", "", as.character(x))))
  norm6 <- function(x) sprintf("%06d", as.integer(gsub("[^0-9]", "", as.character(x))))
  le_u[, cnes := norm7(co_cnes)]; le_n[, cnes := norm7(co_cnes)]
  eq_u[, cnes := norm7(co_cnes)]; se_u[, cnes := norm7(co_cnes)]
  pr_u[, cnes := norm7(co_cnes)]

  base <- data.table(cnes = unique(c(le_u$cnes, eq_u$cnes, se_u$cnes, pr_u$cnes)))
  ib <- unique(rbind(
    le_u[, .(cnes, ibge = norm6(co_ibge))],
    eq_u[, .(cnes, ibge = norm6(co_ibge))],
    se_u[, .(cnes, ibge = norm6(co_ibge))],
    pr_u[, .(cnes, ibge = norm6(co_ibge))]))
  ib <- ib[!is.na(ibge)][!duplicated(cnes)]
  base <- merge(base, ib, by = "cnes", all.x = TRUE)
  base[, regiao_saude := reg_de(ibge)]

  base <- merge(base, le_u[, .(uti_leitos = sum(qt_existente, na.rm = TRUE)), by = cnes], by = "cnes", all.x = TRUE)
  base <- merge(base, le_n[, .(neuro_leitos = sum(qt_existente, na.rm = TRUE)), by = cnes], by = "cnes", all.x = TRUE)
  base <- merge(base, eq_u[, .(tem_tc = any(tc), tem_rm = any(rm), tem_hemo = any(hemo)), by = cnes], by = "cnes", all.x = TRUE)
  base <- merge(base, se_u[, .(serv_imagem = any(imagem), serv_urgencia = any(urgencia),
                               serv_neuro = any(neuro), serv_uti = any(uti_serv)), by = cnes], by = "cnes", all.x = TRUE)
  base <- merge(base, pr_u[neuro == TRUE & !is.na(no_profissional),
                           .(n_neuro = uniqueN(no_profissional)), by = cnes],
                by = "cnes", all.x = TRUE)
  fwrite(base, file.path(TAB, "tab29b_ras_cnes_hospital.csv"), encoding = "UTF-8")

  ## ---------------- consolidacao por regiao ----------------
  por_reg <- base[!is.na(regiao_saude), .(
    hospitais = .N,
    leitos_uti = sum(uti_leitos, na.rm = TRUE),
    leitos_neuro = sum(neuro_leitos, na.rm = TRUE),
    hosp_com_tomografia = sum(tem_tc, na.rm = TRUE),
    hosp_com_ressonancia = sum(tem_rm, na.rm = TRUE),
    hosp_com_hemodinamica = sum(tem_hemo, na.rm = TRUE),
    hosp_com_serv_imagem = sum(serv_imagem, na.rm = TRUE),
    hosp_com_serv_neuro = sum(serv_neuro, na.rm = TRUE),
    hosp_com_serv_urgencia = sum(serv_urgencia, na.rm = TRUE),
    profissionais_neuro = sum(n_neuro, na.rm = TRUE)), by = regiao_saude]
  fwrite(por_reg, file.path(TAB, "tab29_ras_capacidade.csv"), encoding = "UTF-8")

  say("\n--- CAPACIDADE POR REGIAO DE SAUDE ---")
  for (i in seq_len(nrow(por_reg))) {
    r <- por_reg[i]
    say(sprintf("  %-20s hosp=%2d | UTI=%4d | TC=%2d | RM=%2d | hemo=%2d | neuro=%2d | prof.neuro=%2d",
                r$regiao_saude, r$hospitais, r$leitos_uti, r$hosp_com_tomografia,
                r$hosp_com_ressonancia, r$hosp_com_hemodinamica, r$hosp_com_serv_neuro,
                r$profissionais_neuro))
  }
  say("\n  TOTAL: hospitais=", nrow(base),
      " | UTI=", sum(base$uti_leitos, na.rm = TRUE),
      " | tomografia=", sum(base$tem_tc, na.rm = TRUE),
      " | ressonancia=", sum(base$tem_rm, na.rm = TRUE),
      " | hemodinamica=", sum(base$tem_hemo, na.rm = TRUE),
      " | serviço neuro=", sum(base$serv_neuro, na.rm = TRUE),
      " | neurologistas=", sum(base$n_neuro, na.rm = TRUE))

  ## ---------------- figura ----------------
  m <- melt(por_reg, id.vars = c("regiao_saude", "hospitais"),
            measure.vars = c("hosp_com_tomografia", "hosp_com_ressonancia",
                             "hosp_com_hemodinamica", "hosp_com_serv_neuro"))
  m[, variavel := factor(variable, levels = c("hosp_com_tomografia", "hosp_com_ressonancia",
        "hosp_com_hemodinamica", "hosp_com_serv_neuro"),
        labels = c("Tomografia", "Ressonância", "Hemodinâmica", "Serviço de neurologia"))]
  g <- ggplot(m, aes(reorder(regiao_saude, value), value, fill = variavel)) +
    geom_col(position = position_dodge(0.75), width = 0.68) +
    coord_flip() + scale_fill_viridis_d(option = "D", end = 0.85) +
    labs(title = "Capacidade hospitalar para o cuidado cerebrovascular",
         subtitle = "Número de hospitais com cada recurso, por região de saúde (RJ)",
         x = NULL, y = "Número de hospitais", fill = NULL) +
    theme_minimal(base_size = 10) + theme(legend.position = "top")
  ggsave(file.path(FIG, "fig_ex27_ras_capacidade.png"), g, width = 9, height = 5.5,
         dpi = 300, device = ragg::agg_png)
  say("figura gravada: fig_ex27_ras_capacidade.png")
  say("fim: ", format(Sys.time()))
  close(logcon)
})
