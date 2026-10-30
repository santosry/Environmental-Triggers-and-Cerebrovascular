# Machine learning — predição de óbito intra-hospitalar por DCV

Esta pasta é dedicada ao **segundo artigo**, separado do estudo principal de
heterogeneidade hospitalar com GLMM.

**Pergunta:** é possível prever óbito intra-hospitalar por doenças
cerebrovasculares no Rio de Janeiro com desempenho, calibração e utilidade
clínica superiores aos de um modelo logístico multinível?

**Documento principal:** [`PLANO_IMPLEMENTACAO_ML.md`](PLANO_IMPLEMENTACAO_ML.md)

## Escopo resumido

- **Não é** um artigo causal nem uma extensão inferencial do GLMM.
- **É** um estudo de desenvolvimento e validação temporal de modelos preditivos.
- Unidade de validação: **hospital/CNES**, nunca internação isolada.
- Separação temporal: desenvolvimento **2014–2021**; teste **2022–2024**.
- Métricas principais: AUC, AUPRC, calibração (intercepto, inclinação e Brier)
  e utilidade clínica (curva de decisão).
- Relato: **TRIPOD+AI**; risco de viés: **PROBAST**.
- Todo experimento, inclusive nulo ou com falha, entra no registro.

## Estrutura prevista

```
09_machine_learning/
├── README.md
├── PLANO_IMPLEMENTACAO_ML.md
├── 01_dados/          # base analítica derivada (não versionar dados pesados)
├── 02_scripts/        # pipeline R
├── 03_modelos/        # objetos de modelo (não versionar)
├── 04_resultados/     # logs e registro de experimentos
├── 05_tabelas/        # tabelas do artigo
├── 06_figuras/        # curvas ROC, calibração, DCA, importância
└── 07_relatorios/     # relatório metodológico e model card
```
