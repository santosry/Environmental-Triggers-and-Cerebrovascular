# Gatilhos Ambientais e Doenças Cerebrovasculares no Rio de Janeiro

**Environmental Triggers and Cerebrovascular Diseases in Rio de Janeiro, Brazil**

[![Licença](https://img.shields.io/badge/licença-MIT-blue.svg)](LICENSE)
[![Idiomas](https://img.shields.io/badge/linguagens-R%20%7C%20Python-276DC3.svg)](#)
[![Dados](https://img.shields.io/badge/dados-datasets%20públicos%20(DATASUS)-green.svg)](#fontes-de-dados)
[![Status](https://img.shields.io/badge/status-em%20andamento-yellow.svg)](#estado-atual)

> **Repositório de pesquisa** — compêndio analítico e de resultados de um programa de
> estudo sobre a associação entre exposições ambientais (temperatura, umidade, índice de
> calor e material particulado fino — PM2,5) e a morbimortalidade por doenças
> cerebrovasculares (DCV/AVC, CID-10 **I60–I69**) no estado do Rio de Janeiro, Brasil,
> no período de **2010 a 2024**.

---

## Sumário

- [Resumo](#resumo)
- [Estado atual](#estado-atual)
- [Principais resultados](#principais-resultados)
- [Estrutura do repositório](#estrutura-do-repositório)
- [Fontes de dados](#fontes-de-dados)
- [Métodos](#métodos)
- [Reprodutibilidade](#reprodutibilidade)
- [Como citar](#como-citar)
- [Licença](#licença)
- [Limitações e ressalvas](#limitações-e-ressalvas)
- [Contato](#contato)

---

## Resumo

Este repositório reúne os dados processados, as auditorias de qualidade e os resultados
de duas frentes analíticas complementares:

1. **Modelos de defasagem distribuída não-linear (DLNM)** — quantificação da associação
   entre variáveis climáticas (temperatura média, umidade relativa e índice de calor) e
   internações/óbitos cerebrovasculares, com defasagens de exposição, análise de
   sensibilidade e validação bayesiana.
2. **Estudo ecológico de séries temporais e organização da Rede de Atenção à Saúde
   (RAS)** — descrição da morbimortalidade por DCV no Rio de Janeiro (SIH-RD e SIM),
   tendências temporais, diferenças regionais, permanência, custo, fluxo assistencial e
   concentração por estabelecimento (CNES), integrando a exposição ambiental na
   narrativa de vulnerabilidade climática.

### English abstract

*This repository contains the processed data, quality audits and analytical outputs of
a research program on the association between environmental exposures (temperature,
humidity, heat index and fine particulate matter — PM2.5) and cerebrovascular morbidity
and mortality (ICD-10 I60–I69) in the state of Rio de Janeiro, Brazil (2010–2024). Two
complementary approaches are presented: (i) distributed lag non-linear models (DLNM)
quantifying climate–cerebrovascular associations, and (ii) an ecological time-series
study describing hospitalizations (SIH-RD), deaths (SIM), temporal trends, regional
heterogeneity and the territorial organization of care within the Brazilian public
health system (SUS/RAS).*

---

## Estado atual

| Frente | Status |
|---|---|
| 01 — DLNM (clima × DCV) | ✅ Modelos estimados (128 modelos), priorização robusta e figuras geradas |
| 02 — Extração de PM2,5 | ✅ Séries mensais por município/macrorregião (2010–2025) |
| 03 — Auditoria de dados | ✅ Checklists de qualidade, diagnósticos e relatórios |
| 05 — Vulnerabilidade climática e RAS | ✅ Análises concluídas; manuscrito em revisão pelos autores |

> ⚠️ **Aviso:** trata-se de material de pesquisa **em andamento e ainda não revisado por
> pares**. Os resultados não devem ser usados para tomada de decisão clínica ou
> assistencial sem validação independente.

---

## Principais resultados

### Frente 1 — DLNM (clima × DCV)

- **128 modelos** DLNM avaliados, priorizados por significância estatística (FDR),
  magnitude do risco relativo (RR), AUC de excesso de RR e robustez em análises de
  sensibilidade.
- Achados principais robustos: **2** · achados principais com cautela: **8** ·
  achados exploratórios por magnitude: **9**.
- Saídas incluem superfícies 3D interativas de RR (temperatura/umidade × defasagem),
  florestas bayesianas, sensibilidade de lags e análises estratificadas por sexo,
  idade e subtipo CID.

**Figuras principais** (`01_DLNMs_RJ_cerebrovascular/outputs/figures/`):

| Figura | Conteúdo |
|---|---|
| `Fig01_daily_climate.png` | Clima diário por macrorregião |
| `Fig02_exposure_lag.png` | Associação exposição–defasagem |
| `Fig03_auc_ranking.png` | Ranqueamento por AUC de excesso de RR |
| `Fig04_bayesian_forest.png` | Validação bayesiana (forest plot) |
| `Fig05_priority_models.png` | Modelos prioritários |
| `Fig06_climate_extremes.png` | Extremos climáticos |
| `Fig07_lag_sensitivity.png` | Sensibilidade de defasagens |
| `FigS1_*`, `FigS3_*` | Material suplementar |

### Frente 2 — Vulnerabilidade climática e RAS (2010–2024)

Principais números (detalhes em `05_vulnerabilidade_climatica_RAS_RJ/`):

| Indicador | Valor |
|---|---|
| Internações por DCV (SIH-RD, I60–I69) | **267.774** |
| Óbitos por DCV (SIM, causa básica I60–I69) | **147.551** |
| Taxa de internação estadual (2010 → 2024) | 94,76 → **125,97**/100.000 |
| Tendência de internação (Mann-Kendall) | τ = +0,657 (p = 0,0008) |
| Taxa de mortalidade estadual (2010 → 2024) | 65,66 → 58,33/100.000 |
| Tendência de mortalidade (Mann-Kendall) | τ = −0,371 (p = 0,060) |
| Mortalidade hospitalar (SIH) | 19,6% |
| Permanência mediana | 7 dias (IIQ 3–16) |
| Custo total do período (valores correntes) | **R$ 535.221.745** |
| Internações fora do município de residência | 17,7% |
| Concentração nos 10 maiores estabelecimentos (CNES) | **33,6%** |

**Destaques:**

- **Heterogeneidade regional** de taxas de internação > 3× (Médio Paraíba 284/100 mil
  vs. Metropolitana I 87/100 mil, em 2024).
- **Crescimento das internações** concomitante à **queda da mortalidade** populacional,
  sugerindo possível melhora de acesso e sobrevivência (hipótese não confirmada pelo
  desenho ecológico).
- **Concentração assistencial** expressiva e fluxo interregional relevante, com
  implicações diretas para o planejamento da Rede de Atenção à Saúde.
- Correlações ecológicas diárias temperatura × internações **fracas** (ρ −0,08 a +0,26),
  indicando a necessidade de modelagem DLNM (Frente 1) para estimativas não enviesadas
  de defasagem e sazonalidade.

---

## Estrutura do repositório

```
DLNM/
├── 01_DLNMs_RJ_cerebrovascular/      # Dados processados e resultados da modelagem DLNM
│   ├── data_raw/                     # Dados brutos (INMET, população, SIH/SIM)
│   ├── data_interim/                 # Séries individuais e climáticas intermediárias
│   ├── data_processed/               # Datasets analíticos (macrorregião/município)
│   └── outputs/                      # Figuras, tabelas, relatórios e auditorias
│       ├── figures/                  # Fig01–Fig07 + suplementares + 3D interativos
│       ├── tables/                   # Tabelas de RR, AUC, sensibilidade, priorização
│       ├── reports/                  # Sumários executivos da priorização robusta
│       └── audits/                   # Auditorias de dados e diagnósticos de modelos
│
├── 02_MP25_RJ_exposicao/             # Extração e agregação de PM2,5 (MonitorAr/VIGIAR)
│   ├── scripts/                      # extrair_mp25_rj.py
│   ├── data_raw/ · data_interim/ · data_processed/
│   └── outputs/
│
├── 03_AUDITORIA/                     # Auditorias de qualidade de dados
│   ├── *.csv                         # Checklists e diagnósticos (INMET, SIM, SIH, DLNM)
│   └── relatorios/                   # Relatórios de qualidade, reprodutibilidade e
│                                     # validação bayesiana
│
├── 05_vulnerabilidade_climatica_RAS_RJ/   # Estudo ecológico + organização da RAS
│   ├── 01_dados/                     # Dados consolidados e inventário de variáveis
│   ├── 02_scripts/                   # Pipeline Python/R (consolidação e análises)
│   ├── 03_analises/                  # Logs e análises
│   ├── 04_resultados/                # Resultados e dicionário de variáveis
│   ├── 05_tabelas/                   # Tabelas (perfil, tendência, custo, CNES, clima)
│   ├── 06_figuras/                   # fig1–fig5
│   ├── 07_literatura/                # Matriz de literatura (referências verificadas)
│   ├── 08_manuscrito/                # Manuscrito (manuscrito.md)
│   ├── 09_documentos_submissao/      # Modelos de documentos para submissão
│   ├── 10_auditoria/                 # Auditorias de dados e metodológica
│   ├── 11_backup_estudo_anterior/    # Backup íntegro do estudo anterior (WILCOXON)
│   ├── 12_relatorios/                # Relatórios finais e comparação antigo×novo
│   └── HANDOFF.md                    # Documento de continuidade do projeto
│
├── logs/                             # Logs do pipeline integrado
├── .gitignore                        # Regras de exclusão (dados grandes/binários)
├── LICENSE                           # Licença MIT
└── README.md                         # Este documento
```

> **Nota:** a numeração não inclui `04_` — a antiga pasta `04_publicacao_github`
> (compêndio de modelagem DLNM, com os scripts `run_dlnm_analysis.R`,
> `phaseB_corrections.R` etc.) foi separada em repositório próprio:
> **<https://github.com/santosry/dlnm-gam-cerebrovascular-rj>**. Neste repositório
> permanecem os **dados processados e os resultados** daquela fase.

---

## Fontes de dados

| Dado | Fonte | Período | Observações |
|---|---|---|---|
| Internações por DCV (I60–I69) | **SIH-RD/SUS** (via `microdatasus`) | 2010–2024 | 192 arquivos mensais; diagnóstico principal |
| Óbitos por DCV (I60–I69) | **SIM** (via `microdatasus`) | 2010–2024 | Causa básica; 15 arquivos anuais |
| População residente | **IBGE/SIDRA** (tabela 6579 + Censo 2022) | 2010–2025 | Denominadores por município |
| Clima (temperatura, umidade) | **INMET** | 2010–2025 | Agregado por estação e macrorregião |
| PM2,5 | **MonitorAr/VIGIAR** | 2010–2025 | Agregado por município/macrorregião |
| Estabelecimentos de saúde | **CNES** | — | Concentração assistencial |

> Os arquivos brutos (`.rds`, `.zip`, `.parquet`) **não** são versionados neste
> repositório por limitação de tamanho do GitHub — ver [`.gitignore`](.gitignore). Os
> dados são **públicos e anonimizados** (DATASUS/IBGE/INMET).

---

## Métodos

### Frente 1 — DLNM

- Modelos de defasagem distribuída não-linear para associações **clima–DCV**, com
  controle de sazonalidade, tendência e dia da semana.
- Priorização por **FDR**, magnitude de RR, AUC de excesso de RR e robustez em análises
  de sensibilidade (lags, priors bayesianos, splines, exclusão da pandemia, análise
  estratificada por sexo/idade/subtipo CID).
- Validação adicional por modelos **bayesianos hierárquicos** e *case-crossover*.

### Frente 2 — Estudo ecológico e RAS

- **Desenho:** estudo ecológico de séries temporais, retrospectivo (01/01/2010 a
  31/12/2024).
- **Unidades de análise:** município → 9 regiões de saúde → 3 macrorregiões
  (Metropolitana; Centro-Sul; Norte e Noroeste).
- **Análises:** taxas por 100.000 hab.; tendência por **Mann-Kendall**;
  proporção anual por **Cochran-Armitage**; diferenças regionais por
  **Kruskal-Wallis/Dunn**; associações por **qui-quadrado** (com simulação de Monte
  Carlo quando necessário); indicadores de permanência, custo, fluxo
  residência→internação e concentração por CNES; índice de Swaroop-Uemura.
- **Ética:** dados secundários, agregados e anonimizados de domínio público
  (Resolução CNS 510/2016 — dispensa de CEP), em conformidade com a LGPD.

---

## Reprodutibilidade

### Requisitos

- **Python ≥ 3.10** — pacotes principais: `pandas`, `numpy`, `scipy`, `rdata`
  (leitura de `.rds`), `pymannkendall` (tendência), `matplotlib`.
- **R ≥ 4.2** — para os scripts auxiliares (auditoria, Swaroop-Uemura/IPCA, SIDRA).

### Execução (Frente 2)

```bash
# 1) Consolidar os dados SIH (cache por parquet; retomável)
cd 05_vulnerabilidade_climatica_RAS_RJ
python 02_scripts/01_consolidar_dados.py > 03_analises/log_consolidacao.txt 2>&1

# 2) Análises principais (SIH) e mortalidade (SIM)
python 02_scripts/02_analises_principais.py 2>&1 | tail -80
python 02_scripts/02b_analises_sim.py

# 3) Exposição climática e PM2,5
python 02_scripts/03_analises_clima.py

# 4) Índice de Swaroop-Uemura + IPCA (R)
Rscript 02_scripts/03_swaroop_ipca.R
```

> **Nota de ambiente:** em algumas versões de R (ex.: R 4.6.1) `readRDS`/`saveRDS`
> apresentou falha de segmentação; por isso a leitura dos `.rds` do SIH/SIM é feita em
> Python com o pacote `rdata` (decodificação Latin-1). Ver `HANDOFF.md` para detalhes.

---

## Como citar

O estudo está em fase de finalização. Sugere-se, provisoriamente, a seguinte citação:

> Santos, R. P. **Gatilhos ambientais e doenças cerebrovasculares no Rio de Janeiro e
> suas implicações para a organização da Rede de Atenção à Saúde.** Repositório de
> pesquisa, 2026. Disponível em:
> <https://github.com/santosry/Environmental-Triggers-and-Cerebrovascular>.

---

## Licença

O código, a documentação e os resultados deste repositório estão licenciados sob a
**Licença MIT** — ver [`LICENSE`](LICENSE).

> Os **dados** subjacentes são públicos (DATASUS/IBGE/INMET) e não estão cobertos por
> esta licença; cite as fontes originais ao reutilizá-los.

---

## Limitações e ressalvas

- Delineamento **ecológico**: sem inferência causal ou individual.
- Taxas **não padronizadas por idade** diretamente; denominadores com interpolação em
  anos sem estimativa oficial.
- Predomínio de **I64 (AVC não especificado)** — 62,5% no SIH e 37,6% no SIM — indicando
  viés de codificação diagnóstica.
- Raça/cor com ~25,4% de ausência; escolaridade (INSTRU) inválida para inferência
  (>99,9% sem informação).
- Custos em **valores correntes**; comparabilidade intertemporal requer deflação por
  IPCA.
- PM2,5 com granularidade **mensal** derivada (não diária).
- Baixo poder de testes espaciais (9 unidades de análise).

---

## Contato

**Ryan de Paulo Santos** — <ryandpaulosantos@gmail.com>

Para dúvidas, sugestões ou colaboração, abra uma *issue* neste repositório.
