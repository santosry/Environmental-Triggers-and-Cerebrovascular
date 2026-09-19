# 03_swaroop_ipca.R
# Calcula o Índice de Swaroop-Uemura por macrorregião (dados SIM)
# E calcula deflatores IPCA para os custos (dados SIH)

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(httr)
  library(jsonlite)
  library(lubridate)
})

# Paths
root <- getwd()
data_dir <- file.path(root, "01_dados", "processados")
tab_dir <- file.path(root, "05_tabelas")
dir.create(tab_dir, showWarnings = FALSE)

cat("========================================================================\n")
cat("1. ÍNDICE DE SWAROOP-UEMURA (MACRORREGIÃO)\n")
cat("========================================================================\n")

# Ler dados SIM
sim_path <- file.path(data_dir, "sim_cerebrovascular_2010_2024.csv")
if (!file.exists(sim_path)) {
  stop("Arquivo SIM não encontrado.")
}
sim <- read_csv(sim_path, show_col_types = FALSE)

# Calcular Swaroop-Uemura
# Fórmula: (Óbitos >= 50 anos) / (Total de óbitos com idade conhecida) * 100
sim_idade_valida <- sim %>% filter(!is.na(idade_anos))

su_macro <- sim_idade_valida %>%
  group_by(macro3) %>%
  summarise(
    total_obitos = n(),
    obitos_50_mais = sum(idade_anos >= 50),
    swaroop_uemura_pct = (obitos_50_mais / total_obitos) * 100
  ) %>%
  arrange(desc(swaroop_uemura_pct))

cat("Índice de Swaroop-Uemura por Macrorregião:\n")
print(su_macro)

write_csv(su_macro, file.path(tab_dir, "swaroop_uemura_macrorregiao.csv"))
cat("Salvo em: 05_tabelas/swaroop_uemura_macrorregiao.csv\n\n")

cat("========================================================================\n")
cat("2. DEFLAÇÃO DE CUSTOS PELO IPCA (SÉRIE 433) USANDO rbcb\n")
cat("========================================================================\n")

if (requireNamespace("rbcb", quietly = TRUE)) {
  ipca_dados <- tryCatch({
    rbcb::get_series(c(IPCA = 433))
  }, error = function(e) {
    cat("Timeout ou erro de conexão com a API do BCB ao usar rbcb.\n")
    return(NULL)
  })
  
  if (!is.null(ipca_dados)) {
    # Preparar a série de inflação anual
  ipca_anual <- ipca_dados %>%
    mutate(ano = year(date)) %>%
    filter(ano >= 2010 & ano <= 2024) %>%
    group_by(ano) %>%
    summarise(
      inflacao_anual_pct = (prod(1 + IPCA/100) - 1) * 100,
      .groups = 'drop'
    )
  
  ipca_fator <- ipca_anual %>%
    mutate(fator_correcao_2024 = NA_real_)
  
  for (i in 1:nrow(ipca_fator)) {
    ano_t <- ipca_fator$ano[i]
    if (ano_t == 2024) {
      ipca_fator$fator_correcao_2024[i] <- 1
    } else {
      inflacoes_futuras <- ipca_anual$inflacao_anual_pct[ipca_anual$ano > ano_t & ipca_anual$ano <= 2024]
      ipca_fator$fator_correcao_2024[i] <- prod(1 + inflacoes_futuras/100)
    }
  }
  
  cat("Fatores de correção IPCA (Base 2024):\n")
  print(ipca_fator)
  
  sih_path <- file.path(data_dir, "sih_cerebrovascular_2010_2024.csv")
  if (file.exists(sih_path)) {
    sih <- read_csv(sih_path, show_col_types = FALSE)
    sih_custos <- sih %>%
      group_by(ano, macro3) %>%
      summarise(
        custo_corrente = sum(VAL_TOT, na.rm = TRUE),
        .groups = 'drop'
      ) %>%
      left_join(ipca_fator, by = "ano") %>%
      mutate(
        custo_deflacionado_2024 = custo_corrente * fator_correcao_2024
      )
    
    resumo_custos <- sih_custos %>%
      group_by(macro3) %>%
      summarise(
        custo_total_corrente = sum(custo_corrente),
        custo_total_deflacionado = sum(custo_deflacionado_2024)
      )
    
    cat("\nCustos totais por Macrorregião:\n")
    print(resumo_custos)
    
    write_csv(sih_custos, file.path(tab_dir, "custos_deflacionados_ipca.csv"))
    cat("Salvo em: 05_tabelas/custos_deflacionados_ipca.csv\n")
  }
  }
} else {
  cat("Pacote rbcb não disponível. IPCA não calculado.\n")
}
cat("========================================================================\n")
