# =====================================================================
# 06_glmm_uti.R
# ---------------------------------------------------------------------
# Tratamento metodologico do uso de UTI no modelo.
#
# O PROBLEMA. O uso de UTI entrou no nivel 1 (paciente) por exigencia do
# plano, mas ele nao se comporta como fator de risco:
#   (i)  e marcador de gravidade e, em boa medida, mediador entre gravidade e
#        obito, de modo que o seu OR nao tem leitura causal;
#   (ii) o REGISTRO varia enormemente entre hospitais (9,5% na Serrana a
#        31,7% no Noroeste) e cresce no tempo (8,2% em 2010 a 20,8% em 2024),
#        o que indica pratica de registro e faturamento, nao apenas gravidade.
# Como o registro e uma caracteristica do estabelecimento, incluir a UTI como
# covariavel de paciente transfere para o nivel do paciente uma informacao que
# e do hospital, e isso enviesa o VPC/ICC para baixo.
#
# A SOLUCAO APLICADA. Decomposicao de Mundlak: a variavel e separada em
#   uti_within  = uti - media do hospital   (contraste entre pacientes do
#                                            MESMO hospital)
#   uti_between = media do hospital         (pratica de registro do hospital)
# Com os dois termos no modelo, o coeficiente de uti_within estima o contraste
# dentro do hospital e o de uti_between captura o efeito contextual. O sigma^2
# remanescente e a heterogeneidade entre hospitais que NAO se explica por
# pratica de UTI.
#
# Sao ajustados cinco modelos para isolar a contribuicao da UTI ao ICC.
#
# Saidas:
#   04_resultados/resultados_uti.txt
#   05_tabelas/tab17_uti_modelos.csv
#   05_tabelas/tab18_uti_hospital.csv
#   06_figuras/fig_uti.png
# =====================================================================

suppressWarnings({
  options(stringsAsFactors = FALSE)
  library(data.table)
  library(ggplot2)
  source("02_scripts/00_glmm_utils.R")

  ENGINE <- Sys.getenv("GLMM_ENGINE", "glmmTMB")
  ROOT <- normalizePath(".")
  PROC <- file.path(ROOT, "01_dados", "processados")
  RES <- file.path(ROOT, "04_resultados")
  TAB <- file.path(ROOT, "05_tabelas")
  FIG <- file.path(ROOT, "06_figuras")

  logcon <- file(file.path(RES, "resultados_uti.txt"), open = "wt", encoding = "UTF-8")
  say <- function(...) { m <- paste0(...); cat(m, "\n"); writeLines(m, logcon); flush(logcon) }

  say("=====================================================================")
  say("TRATAMENTO DO USO DE UTI: DECOMPOSICAO INTRA E ENTRE HOSPITAIS")
  say("R ", R.version.string, " | motor: ", ENGINE, " | inicio: ", format(Sys.time()))
  say("=====================================================================")

  ## ---------------- dados ----------------
  d <- fread(file.path(PROC, "coorte_glmm_2010_2024.csv"),
             select = c("CNES","obito_hospitalar","idade_anos","idade_z","sexo","subtipo",
                        "car_int","uti","fluxo_inter","regiao_saude","ano"),
             encoding = "UTF-8")
  d[, CNES := factor(CNES)]
  d[, sexo := droplevels(factor(sexo, levels = c("F","M","I")))]
  d[, subtipo := droplevels(factor(subtipo, levels = c(
    "Nao especificado (I64)","Hemorragico (I60-I62)","Isquemico (I63)",
    "Oclusao e outras (I65-I68)","Sequelas (I69)","AIT (G45)",
    "Sindromes vasculares (G46)","Outros")))]
  d[, regiao_saude := droplevels(factor(regiao_saude, levels = c(
    "Metropolitana I","Metropolitana II","Baixada Litoranea","Norte","Noroeste",
    "Serrana","Centro-Sul","Medio Paraiba","Baia da Ilha Grande")))]
  d[, car_int := droplevels(factor(as.character(car_int)))]

  say("internacoes: ", format(nrow(d), big.mark = "."),
      " | obitos: ", format(sum(d$obito_hospitalar), big.mark = "."),
      " | hospitais: ", uniqueN(d$CNES))

  ## ---------------- 1. o registro de UTI e pratica ou gravidade? ----------------
  say("\n--- O REGISTRO DE UTI E PRATICA INSTITUCIONAL? ---")
  say("prevalencia global: ", sprintf("%.2f%%", 100 * mean(d$uti)))

  hp <- d[, .(n = .N, uti_pct = 100 * mean(uti),
              idade_media = mean(idade_anos),
              hemorragico_pct = 100 * mean(subtipo == "Hemorragico (I60-I62)"),
              eletiva_pct = 100 * mean(car_int == "Eletiva"),
              obito_pct = 100 * mean(obito_hospitalar)), by = CNES][order(-n)]
  hp <- hp[n >= 100]   # hospitais com volume para a taxa ser estavel
  say("hospitais com 100 ou mais internacoes: ", nrow(hp))
  say(sprintf("  taxa de UTI entre hospitais: P10=%.1f%% mediana=%.1f%% P90=%.1f%% (amplitude %.1f p.p.)",
              quantile(hp$uti_pct, .10), median(hp$uti_pct), quantile(hp$uti_pct, .90),
              max(hp$uti_pct) - min(hp$uti_pct)))

  say("\n  correlacao da taxa de UTI do hospital com o perfil de casos (Spearman):")
  for (v in c("idade_media","hemorragico_pct","eletiva_pct","obito_pct","n")) {
    ct <- suppressWarnings(cor.test(hp$uti_pct, hp[[v]], method = "spearman"))
    say(sprintf("    %-18s rho=%+.3f  p=%s", v, ct$estimate, p_cient(ct$p.value)))
  }
  say("  Se a taxa de UTI fosse so gravidade, ela acompanharia a mortalidade e a")
  say("  composicao de casos. Correlacao fraca com o perfil sustenta a leitura de")
  say("  pratica de registro.")

  say("\n  evolucao temporal da prevalencia de UTI:")
  tr <- d[, .(uti_pct = 100 * mean(uti)), by = ano][order(ano)]
  for (i in seq_len(nrow(tr))) say(sprintf("    %d  %5.2f%%", tr$ano[i], tr$uti_pct[i]))
  mk <- suppressWarnings(cor.test(tr$ano, tr$uti_pct, method = "kendall"))
  say(sprintf("  tendencia de Mann-Kendall: tau=%+.3f  p=%s", mk$estimate, p_cient(mk$p.value)))

  say("\n  taxa de UTI por regiao de saude:")
  rg <- d[, .(uti_pct = 100 * mean(uti), n = .N), by = regiao_saude][order(-uti_pct)]
  for (i in seq_len(nrow(rg)))
    say(sprintf("    %-22s %5.2f%%  (n=%s)", as.character(rg$regiao_saude[i]),
                rg$uti_pct[i], format(rg$n[i], big.mark = ".")))
  fwrite(hp, file.path(TAB, "tab18_uti_hospital.csv"), encoding = "UTF-8")

  ## ---------------- 2. decomposicao de Mundlak ----------------
  d[, uti_between := mean(uti), by = CNES]
  d[, uti_within := uti - uti_between]

  BASE <- obito_hospitalar ~ idade_z + sexo + subtipo + car_int + fluxo_inter +
    regiao_saude + (1 | CNES)
  F_UTI <- update(BASE, . ~ . + uti)
  F_SEM <- BASE
  F_ENTRE <- update(BASE, . ~ . + uti_between)
  F_MUNDLAK <- update(BASE, . ~ . + uti_within + uti_between)

  modelos <- list(
    list(rot = "M1 sem UTI",                    fml = F_SEM),
    list(rot = "M2 com UTI (especificacao do plano)", fml = F_UTI),
    list(rot = "M3 so componente do hospital",  fml = F_ENTRE),
    list(rot = "M4 Mundlak (intra + entre)",    fml = F_MUNDLAK))

  comps <- list(); coefs <- list()
  for (mm in modelos) {
    fit <- fit_glmm(mm$fml, as.data.frame(d), engine = ENGINE)
    s2 <- fit$vc$vcov[fit$vc$grp == "CNES"][1]
    im <- icc_mor(s2)
    ut <- fit$coef[grepl("^uti", termo)]
    comps[[mm$rot]] <- data.table(
      modelo = mm$rot, n = fit$n, sigma2 = round(s2, 5), ICC = round(im$icc, 5),
      MOR = round(im$mor, 4), AIC = round(fit$AIC, 1),
      OR_uti_within = if ("uti_within" %in% ut$termo) round(ut[termo == "uti_within"]$or, 3) else NA_real_,
      OR_uti_between = if ("uti_between" %in% ut$termo) round(ut[termo == "uti_between"]$or, 3) else NA_real_,
      OR_uti = if ("uti" %in% ut$termo) round(ut[termo == "uti"]$or, 3) else NA_real_,
      tempo_min = round(fit$tempo_min, 2))
    coefs[[mm$rot]] <- data.table(modelo = mm$rot, termo = fit$coef$termo,
                                  or = fit$coef$or, lo = fit$coef$lo,
                                  hi = fit$coef$hi, p = fit$coef$p)
    say(sprintf("\n### %-42s sigma2=%.5f ICC=%.5f MOR=%.4f AIC=%.1f",
                mm$rot, s2, im$icc, im$mor, fit$AIC))
    for (i in seq_len(nrow(ut)))
      say(sprintf("      %-16s OR=%7.3f (IC95%% %6.3f-%7.3f) p=%s",
                  ut$termo[i], ut$or[i], ut$lo[i], ut$hi[i], p_cient(ut$p[i])))
  }
  cdf <- rbindlist(comps)
  fwrite(cdf, file.path(TAB, "tab17_uti_modelos.csv"), encoding = "UTF-8")

  say("\n--- CONTRIBUICAO DA UTI AO COMPONENTE HOSPITALAR ---")
  s_sem <- cdf[modelo == "M1 sem UTI"]$sigma2
  s_com <- cdf[modelo == "M2 com UTI (especificacao do plano)"]$sigma2
  s_ent <- cdf[modelo == "M3 so componente do hospital"]$sigma2
  s_mun <- cdf[modelo == "M4 Mundlak (intra + entre)"]$sigma2
  say(sprintf("  sigma2 sem UTI ............................... %.5f (ICC %.2f%%)",
              s_sem, 100 * cdf[modelo == "M1 sem UTI"]$ICC))
  say(sprintf("  sigma2 com UTI de paciente ................... %.5f (ICC %.2f%%)",
              s_com, 100 * cdf[modelo == "M2 com UTI (especificacao do plano)"]$ICC))
  say(sprintf("  sigma2 so com a taxa de UTI do hospital ...... %.5f (ICC %.2f%%)",
              s_ent, 100 * cdf[modelo == "M3 so componente do hospital"]$ICC))
  say(sprintf("  sigma2 na decomposicao de Mundlak ............ %.5f (ICC %.2f%%)",
              s_mun, 100 * cdf[modelo == "M4 Mundlak (intra + entre)"]$ICC))
  say(sprintf("\n  a UTI de paciente explica %.1f%% da variancia hospitalar",
              100 * (s_sem - s_com) / s_sem))
  say(sprintf("  a taxa de UTI do hospital explica %.1f%% da variancia hospitalar",
              100 * (s_sem - s_ent) / s_sem))
  say(sprintf("  os dois componentes juntos explicam %.1f%%",
              100 * (s_sem - s_mun) / s_sem))
  say(sprintf("  heterogeneidade hospitalar remanescente: ICC %.2f%%",
              100 * cdf[modelo == "M4 Mundlak (intra + entre)"]$ICC))

  ## ---------------- 3. sensibilidade a definicao de UTI ----------------
  ## A UTI foi definida como ao menos um dia registrado. Aqui a definicao e
  ## variada para mostrar que o ICC nao depende do ponto de corte, apenas da
  ## presenca ou nao da variavel no modelo.
  say("\n--- SENSIBILIDADE A DEFINICAO DE UTI ---")
  defs <- list(
    list(rot = "ao menos 1 dia (principal)", expr = quote(uti)),
    list(rot = "ao menos 2 dias",            expr = quote(as.integer(UTI_MES_TO >= 2))),
    list(rot = "ao menos 7 dias",            expr = quote(as.integer(UTI_MES_TO >= 7))),
    list(rot = "pelo campo MARCA_UTI",       expr = quote(uti_marca)))

  dl <- fread(file.path(PROC, "coorte_glmm_2010_2024.csv"),
              select = c("CNES","obito_hospitalar","idade_anos","idade_z","sexo","subtipo",
                         "car_int","uti","uti_marca","UTI_MES_TO","fluxo_inter",
                         "regiao_saude"),
              encoding = "UTF-8")
  dl[, sexo := droplevels(factor(sexo, levels = c("F","M","I")))]
  dl[, subtipo := droplevels(factor(subtipo, levels = c(
    "Nao especificado (I64)","Hemorragico (I60-I62)","Isquemico (I63)",
    "Oclusao e outras (I65-I68)","Sequelas (I69)","AIT (G45)",
    "Sindromes vasculares (G46)","Outros")))]
  dl[, regiao_saude := droplevels(factor(regiao_saude, levels = c(
    "Metropolitana I","Metropolitana II","Baixada Litoranea","Norte","Noroeste",
    "Serrana","Centro-Sul","Medio Paraiba","Baia da Ilha Grande")))]
  dl[, car_int := droplevels(factor(as.character(car_int)))]

  sdf <- list()
  for (dd in defs) {
    dl[, uti_def := eval(dd$expr)]
    fit <- fit_glmm(obito_hospitalar ~ idade_z + sexo + subtipo + car_int + uti_def +
                      fluxo_inter + regiao_saude + (1 | CNES),
                    as.data.frame(dl), engine = ENGINE)
    s2d <- fit$vc$vcov[fit$vc$grp == "CNES"][1]
    imd <- icc_mor(s2d)
    ud <- fit$coef[termo == "uti_def"]
    sdf[[dd$rot]] <- data.table(
      definicao = dd$rot, prevalencia_pct = round(100 * mean(dl$uti_def), 2),
      sigma2 = round(s2d, 5), ICC = round(imd$icc, 5), MOR = round(imd$mor, 4),
      AIC = round(fit$AIC, 1), OR_uti = round(ud$or, 3),
      OR_lo = round(ud$lo, 3), OR_hi = round(ud$hi, 3), p_uti = p_cient(ud$p))
    say(sprintf("  %-26s prevalencia=%5.2f%% | sigma2=%.5f | ICC=%6.2f%% | OR=%6.3f (%.3f-%.3f)",
                dd$rot, 100 * mean(dl$uti_def), s2d, 100 * imd$icc, ud$or, ud$lo, ud$hi))
  }
  sdf <- rbindlist(sdf)
  fwrite(sdf, file.path(TAB, "tab13_sensibilidade_uti.csv"), encoding = "UTF-8")
  say(sprintf("  %-26s %s | sigma2=%.5f | ICC=%6.2f%%",
              "sem a variavel no modelo", "(referencia)", s_sem, 100 * cdf[modelo == "M1 sem UTI"]$ICC))

  ## ---------------- 4. figura ----------------
  f1 <- rbind(
    data.table(serie = "Por ano", x = tr$ano, y = tr$uti_pct),
    fill = TRUE)
  g1 <- ggplot(tr, aes(x = ano, y = uti_pct)) +
    geom_line(colour = "#08519c", linewidth = 0.9) +
    geom_point(colour = "#08519c", size = 1.9) +
    labs(title = "Registro de uso de UTI ao longo do tempo",
         subtitle = sprintf("Percentual de internações com dias de UTI registrados (Mann-Kendall tau=%+.3f, p=%s)",
                            mk$estimate, p_cient(mk$p.value)),
         x = NULL, y = "Internações com UTI (%)") +
    theme_minimal(base_size = 10) +
    theme(plot.title = element_text(face = "bold"))

  g2 <- ggplot(rg, aes(x = uti_pct, y = reorder(as.character(regiao_saude), uti_pct))) +
    geom_col(fill = "#08519c", width = 0.68) +
    geom_text(aes(label = sprintf("%.1f%%", uti_pct)), hjust = -0.1, size = 3) +
    scale_x_continuous(expand = expansion(mult = c(0, 0.18))) +
    labs(title = "Registro de uso de UTI por região de saúde",
         subtitle = "Percentual de internações com dias de UTI, 2010-2024",
         x = "Internações com UTI (%)", y = NULL) +
    theme_minimal(base_size = 10) +
    theme(plot.title = element_text(face = "bold"),
          panel.grid.major.y = element_blank())

  g3 <- ggplot(cdf, aes(x = ICC, y = reorder(modelo, ICC))) +
    geom_col(fill = "#238b45", width = 0.6) +
    geom_text(aes(label = sprintf("%.2f%%", 100 * ICC)), hjust = -0.12, size = 3.2) +
    scale_x_continuous(labels = function(v) sprintf("%.0f%%", 100 * v),
                       expand = expansion(mult = c(0, 0.22))) +
    labs(title = "VPC/ICC hospitalar conforme o tratamento dado à UTI",
         subtitle = "A UTI de paciente absorve variância do hospital; a decomposição de Mundlak separa as duas fontes",
         x = "VPC / ICC", y = NULL) +
    theme_minimal(base_size = 10) +
    theme(plot.title = element_text(face = "bold"),
          panel.grid.major.y = element_blank())

  library(patchwork)
  ggsave(file.path(FIG, "fig_uti.png"),
         (g1 / g3) | g2, width = 13, height = 7, dpi = 300)
  say("\nfigura gravada: 06_figuras/fig_uti.png")

  say("\nfim: ", format(Sys.time()))
  close(logcon)
})
