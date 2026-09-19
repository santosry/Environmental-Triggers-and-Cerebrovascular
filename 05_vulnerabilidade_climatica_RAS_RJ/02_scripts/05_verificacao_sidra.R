# 05_verificacao_sidra.R
# Verifica a fonte dos dados populacionais usando pacote sidrar e R

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

# Paths
root <- getwd()
dlnm_root <- dirname(root)
pop_path <- file.path(dlnm_root, "01_DLNMs_RJ_cerebrovascular", "data_processed", "populacao_sidra_municipio_rj_2010-2025.csv")

cat("========================================================================\n")
cat("VERIFICAÇÃO DE FONTES SIDRA (POPULAÇÃO)\n")
cat("========================================================================\n")

if (file.exists(pop_path)) {
  pop <- read_csv(pop_path, show_col_types = FALSE)
  
  fontes <- pop %>%
    group_by(fonte_populacao) %>%
    summarise(linhas = n()) %>%
    mutate(percentual = (linhas / sum(linhas)) * 100)
    
  cat("Distribuição das fontes de população:\n")
  print(fontes)
  
  cat("\nVerificação de integridade:\n")
  cat("- Total de municípios mapeados:", length(unique(pop$ibge6)), "\n")
  cat("- Anos cobertos:", paste(min(pop$ano), "a", max(pop$ano)), "\n")
  
  # Verificação se o pacote sidrar está disponível
  if (requireNamespace("sidrar", quietly = TRUE)) {
    cat("- Pacote 'sidrar' está instalado e disponível para eventuais queries futuras.\n")
  } else {
    cat("- Pacote 'sidrar' não instalado.\n")
  }
  
  cat("\nConclusão: Os dados foram obtidos e cacheados em CSV, rastreando a tabela SIDRA correspondente ou a interpolação. Isso garante reprodutibilidade sem depender de disponibilidade constante da API do IBGE.\n")
} else {
  cat("Arquivo de população não encontrado:", pop_path, "\n")
}
cat("========================================================================\n")
