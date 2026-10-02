# Frente 01 — Modelagem DLNM: clima, PM2,5 e doenças cerebrovasculares no Rio de Janeiro

📁 **Parte do monorepo** [Gatilhos Ambientais e Doenças Cerebrovasculares](../README.md)

Esta pasta reúne **dados processados, resultados e auditorias** da frente de
**modelagem de defasagem distribuída não-linear (DLNM)** que quantifica a associação
entre exposições ambientais e a morbimortalidade cerebrovascular (CID-10 **I60–I69**,
além dos blocos **G45–G46**) no estado do Rio de Janeiro.

> ⚙️ Os **scripts de modelagem DLNM** (R) ficam em repositório próprio:
> **[santosry/dlnm-gam-cerebrovascular-rj](https://github.com/santosry/dlnm-gam-cerebrovascular-rj)**.
> Aqui permanecem os **dados processados e os resultados** daquela fase, além da
> extração de PM2,5 e das auditorias de qualidade.

---

## Sumário

- [O que esta frente faz](#o-que-esta-frente-faz)
- [Estrutura](#estrutura)
- [Dados](#dados)
- [Métodos](#métodos)
- [Resultados](#resultados)
- [Auditoria](#auditoria)
- [Reprodutibilidade](#reprodutibilidade)
- [Limitações](#limitações)

---

## O que esta frente faz

1. **Constrói os datasets analíticos diários** por **município** e por **macrorregião
   de saúde**, cruzando desfechos (SIH-RD/SIM) com exposições climáticas (INMET) e
   PM2,5, com denominadores populacionais e malha territorial.
2. **Ajusta modelos DLNM** para estimar o **risco relativo (RR)** de internação/óbito
   em função de temperatura média, umidade relativa e índice de calor, ao longo de
   defasagens de exposição.
3. **Prioriza achados** por significância (FDR), magnitude de RR, AUC de excesso de RR,
   resíduos e **robustez** em análises de sensibilidade.
4. **Valida** os achados com modelos **bayesianos hierárquicos** (normal-normal por
   desfecho/exposição/percentil) e com desenho **case-crossover**.
5. **Extrai e agrega PM2,5** (MonitorAr/VIGIAR) em escala municipal e mensal
   (`02_MP25_RJ_exposicao/`).
6. **Audita** cobertura, granularidade, duplicações e consistência dos dados
   (`03_AUDITORIA/` e `outputs/audits/`).

---

## Estrutura

```
01_DLNMs_RJ_cerebrovascular/
├── data_raw/                      # Dados brutos originais (preservados, nunca editados)
│   ├── inmet/                     #   .rds mensais por estação (2010–2025)
│   ├── inmet_zip/                 #   arquivos ZIP anuais do INMET
│   ├── sih/                       #   microdados SIH-RD
│   ├── sim/                       #   microdados SIM-DO
│   ├── inmet_estacoes_rj.csv      # catálogo de estações do RJ
│   ├── municipios_rj.csv          # lista de municípios
│   └── populacao_sidra_*.csv      # população IBGE/SIDRA
│
├── data_interim/                  # Séries individuais/intermediárias (.rds)
│   ├── inmet_diario_estacoes.rds
│   ├── sih_cerebrovascular_individual.rds
│   └── sim_cerebrovascular_individual.rds
│
├── data_processed/                # Datasets analíticos prontos para modelagem
│   ├── dataset_dlnm_macrorregiao.rds
│   ├── dataset_dlnm_municipio.rds
│   ├── desfechos_diarios_municipio.rds
│   ├── inmet_diario_macrorregiao.{csv,rds}
│   ├── lookup_municipio_macrorregiao.csv
│   ├── municipios_rj_centroides_geobr.csv
│   ├── populacao_sidra_municipio_rj_2010-2025.csv
│   ├── modelos_dlnm_macrorregiao.rds
│   └── modelos_dlnm_heat_index.rds
│
├── 02_MP25_RJ_exposicao/          # Extração e agregação de PM2,5 (MonitorAr/VIGIAR)
│   ├── scripts/extrair_mp25_rj.py
│   ├── data_raw/powerbi_api_cache.json
│   ├── data_processed/            # séries municipais/macrorregionais mensais
│   └── outputs/auditoria/         # logs e relatórios de auditoria da extração
│
├── 03_AUDITORIA/                  # Auditorias de qualidade de dados
│   ├── auditoria_*.csv            # checklists: INMET, SIH, SIM, PM2,5, espacial
│   ├── validacao_*.csv            # validação de saídas e figuras
│   ├── diagnosticos_*.csv         # autocorrelação e Moran espacial
│   ├── especificacao_modelos_dlnm.csv
│   ├── nota_metodologica_formula_dlnm.csv
│   ├── nota_validacao_bayesiana_dlnm.csv
│   └── relatorios/                # relatórios técnicos em Markdown
│
└── outputs/
    ├── figures/                   # Fig01–Fig07, suplementares e superfícies 3D interativas
    ├── tables/                    # RR, AUC, sensibilidade, priorização, estratificações
    ├── reports/                   # sumários executivos da priorização robusta
    ├── audits/                    # auditorias consolidadas
    └── logs/                      # logs do pipeline
```

---

## Dados

| Fonte | Conteúdo | Escala | Observações |
|---|---|---|---|
| **SIH-RD/SUS** | Internações por DCV (I60–I69 + G45/G46) | diária, município/macrorregião | Desfecho primário de morbidade |
| **SIM-DO** | Óbitos por DCV (causa básica I60–I69) | diária, município/macrorregião | Óbitos hospitalares do SIH usados quando o SIM anual não estava válido |
| **INMET** | Temperatura média, umidade relativa, índice de calor | diária, macrorregião | Preenchimento por estação mais próxima quando necessário |
| **MonitorAr/VIGIAR** | PM2,5 | mensal, município/macrorregião | Extraído via API do Power BI (`extrair_mp25_rj.py`) |
| **IBGE/SIDRA** | População residente | anual, município | Offset/denominador |
| **geobr/IBGE** | Centróides e malha municipal | — | Geoprocessamento e análises espaciais |

> Os arquivos `.rds`/`.zip` volumosos estão no [`.gitignore`](../.gitignore) e **não são
> versionados**.

---

## Métodos

- **DLNM** (distributed lag non-linear models) com *cross-basis* de exposição ×
  defasagem, controlando **sazonalidade**, **tendência temporal** e **dia da semana**.
- Estratificação por **desfecho** (internações/óbitos), **macrorregião**, **tipo de
  exposição** (temperatura média, umidade média, índice de calor) e **subtipo CID**.
- **Priorização robusta dos 128 modelos** por:
  1. **FDR** (Benjamini-Hochberg) como critério primário de credibilidade;
  2. magnitude do **RR** e **AUC de excesso de RR**;
  3. **robustez** nas análises de sensibilidade (defasagens, priors, splines,
     exclusão da pandemia, estratificações).
- **Análises de sensibilidade:** lags, graus de liberdade do spline, sazonalidade,
  exclusão da pandemia e priors bayesianos.
- **Validação bayesiana hierárquica** (normal-normal; integração em grade, sem MCMC)
  e **case-crossover**.
- **Diagnósticos:** resíduos, autocorrelação e **Moran espacial**.

---

## Resultados

Extraídos de `outputs/reports/sumario_priorizacao_robusta_dlnm.md`:

| Indicador | Valor |
|---|---|
| Modelos avaliados | **128** |
| Achados principais robustos | **2** |
| Achados principais com cautela | **8** |
| Exploratórios por magnitude alta | **9** |
| Validação bayesiana — linhas geradas | 72 |
| Probabilidades posteriores para RR > 1,10 | 72 |

**Relatório técnico** (`03_AUDITORIA/relatorios/relatorio_tecnico_completo.md`):
período 2010–2025, 9 macrorregiões, 5.844 dias por macrorregião, 128 modelos DLNM.

### Figuras principais (`outputs/figures/`)

| Arquivo | Conteúdo |
|---|---|
| `Fig01_daily_climate.png` | Clima diário por macrorregião |
| `Fig02_exposure_lag.png` | Associação exposição–defasagem |
| `Fig03_auc_ranking.png` | Ranqueamento por AUC de excesso de RR |
| `Fig04_bayesian_forest.png` | Validação bayesiana (forest plot) |
| `Fig05_priority_models.png` | Modelos prioritários |
| `Fig06_climate_extremes.png` | Extremos climáticos |
| `Fig07_lag_sensitivity.png` | Sensibilidade de defasagens |
| `FigS1_*`, `FigS3_*` | Material suplementar |
| `interactive/rr_surface_3d_*.html` | **Superfícies 3D interativas de RR** (por macrorregião/desfecho) |
| `diagnosticos_residuos/*.png` | Diagnósticos de resíduos dos modelos prioritários |

### Tabelas principais (`outputs/tables/`)

- `ranking_modelos_rr_ic95_auc_residuos_bayes.csv`
- `priorizacao_robusta_todos_modelos.csv`, `priorizacao_ranking_final_narrativo.csv`
- `tabela_rr_dlnm_macrorregiao.csv`, `tabela_auc_rr_dlnm_macrorregiao.csv`
- `tabela_auc_rr_dlnm_heat_index.csv`
- `sensibilidade_lags_dlnm.csv`, `sensibilidade_priors_bayesianos.csv`,
  `sensibilidade_sazonal_dlnm.csv`, `sensibilidade_sem_pandemia_dlnm.csv`
- `validacao_bayesiana_hierarquica_dlnm.csv`, `validacao_case_crossover.csv`
- `dlnm_estratificado_sexo_idade.csv`, `contagens_descritivas_sexo_idade_cid.csv`

---

## Auditoria

Em `03_AUDITORIA/` e `outputs/audits/`:

- **Cobertura e granularidade:** `auditoria_cobertura_territorial_final.csv`,
  `auditoria_granularidade_exposicoes_clima_pm25.csv`,
  `auditoria_inmet_cobertura_temporal_macrorregiao.csv`.
- **INMET:** downloads por ano, qualidade (QC), estações históricas, aliases
  municipais, séries compartilhadas e métodos de preenchimento por macrorregião.
- **SIH/SIM:** campos de estratificação, óbitos ausentes, AIH substitutas,
  download do SIM, decisão metodológica sobre PM2,5.
- **Espacial:** centróides macrorregionais/municipais, Moran espacial, autocorrelação.
- **Modelos:** especificação, qualidade, família de modelos, validação de saídas e de
  figuras.
- **Relatórios:** `relatorio_controle_qualidade.md`, `relatorio_reprodutibilidade.md`,
  `relatorio_tecnico_completo.md`, `relatorio_validacao_bayesiana.md`.

---

## Reprodutibilidade

Os scripts de modelagem estão no repositório
**[dlnm-gam-cerebrovascular-rj](https://github.com/santosry/dlnm-gam-cerebrovascular-rj)**
(arquivos como `run_dlnm_analysis.R`, `phaseB_corrections.R`).

A extração de PM2,5 é reproduzível localmente:

```bash
cd 02_MP25_RJ_exposicao
python scripts/extrair_mp25_rj.py
```

Requisitos: **Python ≥ 3.10** (`pandas`, `numpy`, `requests`) e **R ≥ 4.2**
(modelagem DLNM). Os dados brutos são públicos (DATASUS/IBGE/INMET).

---

## Limitações

- PM2,5 com granularidade **mensal derivada** (não diária).
- Óbitos hospitalares do SIH usados como substitutos quando o SIM anual não estava
  validamente disponível.
- Predomínio de **I64** (AVC não especificado), limitando a validade por subtipo.
- 9 macrorregiões como unidade espacial → poder limitado para testes espaciais.
- Resultados **não revisados por pares** e sujeitos a atualização.

---

⬅️ [Voltar ao README do monorepo](../README.md)
