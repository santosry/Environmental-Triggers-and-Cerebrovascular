# Exploração de variáveis com machine learning

Esta pasta é um **anexo metodológico** do monorepo, separado da Frente 02.

**Objetivo:** explorar a estrutura, os padrões e as associações entre as variáveis
disponíveis na coorte de DCV do Rio de Janeiro, usando técnicas de aprendizado
não supervisionado e mineração de padrões.

**Não é um estudo de predição.** Não haverá divisão treino/teste, AUC, calibração,
curva de decisão, model card ou afirmação de que um modelo “prevê” desfechos.

- Dados de entrada: `02_estudo_RAS_RJ/01_dados/processados/coorte_glmm_2014_2024.csv`.
- O anexo **não altera** a coorte, os scripts ou os resultados da Frente 02.
- Todo resultado exploratório — inclusive associações fracas, clusters instáveis e
  análises que falharem — deve ser registrado.

**Plano completo:** [`PLANO_EXPLORACAO_ML.md`](PLANO_EXPLORACAO_ML.md)

## Estrutura

```
04_machine_learning_exploratorio/
├── README.md
├── PLANO_EXPLORACAO_ML.md
├── 01_dados/          # bases derivadas para exploração (não versionar dados pesados)
├── 02_scripts/        # pipeline exploratório em R
├── 03_resultados/     # logs e registro de análises
├── 04_tabelas/        # tabelas de associações, clusters e regras
├── 05_figuras/        # MCA/FAMD, mapas, heatmaps, perfis
└── 06_relatorios/     # relatório narrativo
```
