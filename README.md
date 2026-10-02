# Gatilhos Ambientais e Doenças Cerebrovasculares no Rio de Janeiro

**Environmental Triggers and Cerebrovascular Diseases in Rio de Janeiro, Brazil**

[![Licença](https://img.shields.io/badge/licença-MIT-blue.svg)](LICENSE)
[![Linguagens](https://img.shields.io/badge/linguagens-R%20%7C%20Python-276DC3.svg)](#)
[![Dados](https://img.shields.io/badge/dados-fontes%20públicas%20(DATASUS%2FIBGE%2FINMET)-green.svg)](#fontes-de-dados)
[![Status](https://img.shields.io/badge/status-em%20andamento-yellow.svg)](#estado-atual)

> **Repositório de pesquisa** — compêndio analítico de um programa de estudo sobre a
> associação entre exposições ambientais (temperatura, umidade, índice de calor e
> material particulado fino — PM2,5) e a morbimortalidade por doenças
> cerebrovasculares (DCV/AVC, CID-10 **I60–I69**, além dos blocos **G45–G46**) no
> estado do Rio de Janeiro, Brasil.

---

## Sumário

- [O grande projeto](#o-grande-projeto)
- [As três frentes](#as-três-frentes)
  - [01 — Modelagem DLNM](#01--modelagem-dlnm-clima--dcv)
  - [02 — Vulnerabilidade climática e RAS](#02--vulnerabilidade-climática-e-ras)
  - [03 — Revisão sistemática e meta-análise](#03--revisão-sistemática-e-meta-análise)
- [Estrutura do repositório](#estrutura-do-repositório)
- [Resultados principais](#resultados-principais)
- [Fontes de dados](#fontes-de-dados)
- [Métodos (panorama)](#métodos-panorama)
- [Reprodutibilidade](#reprodutibilidade)
- [Como citar](#como-citar)
- [Licença](#licença)
- [Limitações e ressalvas](#limitações-e-ressalvas)
- [Contato](#contato)

---

## O grande projeto

Este repositório reúne, em um único *monorepo*, **três frentes complementares** de um
programa de pesquisa sobre determinantes ambientais das doenças cerebrovasculares no
Rio de Janeiro. A pergunta central é:

> **Como exposições ambientais modificáveis — clima (temperatura, umidade, índice de
> calor) e poluição do ar (PM2,5) — se associam à morbimortalidade por DCV, e o que
> isso implica para a organização da Rede de Atenção à Saúde (RAS) do SUS no estado?**

Cada frente ataca a pergunta com um desenho próprio: a Frente **01** quantifica a
associação exposição–desfecho com **modelos de defasagem distribuída não-linear
(DLNM)**; a Frente **02** descreve a **morbimortalidade e a rede assistencial**
(estudo ecológico + modelo logístico multinível); a Frente **03** **sintetiza a
evidência global** por revisão sistemática e meta-análise.

### English abstract

*This monorepo hosts three complementary research fronts on environmental
determinants of cerebrovascular diseases (ICD-10 I60–I69) in Rio de Janeiro, Brazil:
(01) distributed lag non-linear models (DLNM) linking climate and PM2.5 to
hospitalizations and deaths; (02) an ecological time-series study with multilevel
modelling of in-hospital mortality and analysis of the health-care network (SUS/RAS);
and (03) a global PRISMA 2020 systematic review and meta-analysis of environmental
determinants of cerebrovascular diseases.*

---

## As três frentes

### 01 — Modelagem DLNM (clima × DCV)

📁 **[`01_DLNMs_RJ_cerebrovascular/`](01_DLNMs_RJ_cerebrovascular/README.md)**

Quantifica a associação entre variáveis climáticas diárias (temperatura média, umidade
relativa e índice de calor) e internações/óbitos cerebrovasculares, com defasagens de
exposição, usando DLNM.

- **128 modelos** DLNM ajustados por macrorregião, desfecho (internações/óbitos),
  exposição e subtipo CID.
- Priorização por **FDR**, magnitude de RR, AUC de excesso de RR, resíduos e robustez.
- Validação por **modelos bayesianos hierárquicos** (normal-normal) e *case-crossover*.
- Inclui a extração das séries de **PM2,5** (MonitorAr/VIGIAR) e toda a **auditoria de
  qualidade de dados** (INMET, SIH, SIM).
- Saídas: figuras 1–7 (+ suplementares), **superfícies 3D interativas** de RR, tabelas
  de RR/AUC/sensibilidade e relatórios.

> Os **scripts de modelagem DLNM** ficam em repositório próprio:
> <https://github.com/santosry/dlnm-gam-cerebrovascular-rj>. Aqui permanecem os
> **dados processados e os resultados**.

### 02 — Vulnerabilidade climática e RAS

📁 **[`02_vulnerabilidade_climatica_RAS_RJ/`](02_vulnerabilidade_climatica_RAS_RJ/README.md)**

Estudo ecológico de séries temporais (2010–2024) com modelagem logística multinível.

- **Coorte:** 295.673 internações por DCV (I60–I69 + G45/G46) e 55.827 óbitos
  intra-hospitalares (18,88%), em 254 hospitais e 9 regiões de saúde.
- **GLMM logístico de 3 níveis** (`glmmTMB`, conferido em `lme4`) da mortalidade
  intra-hospitalar: VPC/ICC hospitalar = **14,95%**; MOR = **2,065**.
- Correção de múltiplas comparações por **Benjamini-Hochberg (FDR)** — 14 de 19
  coeficientes significativos — e **18 cenários de robustez**.
- Índice de **Swaroop-Uemura**, tendências de **Mann-Kendall**, custos deflacionados
  pelo **IPCA** e concentração assistencial por **CNES**.
- Manuscrito, matriz de literatura, auditorias e relatórios executivos.

### 03 — Revisão sistemática e meta-análise

📁 **[`03_revisão_impactos_à_saúde/`](03_revisão_impactos_à_saúde/README.md)**

*Environmental determinants of cerebrovascular diseases (ICD-10 I60–I69) across the
lifespan: a global systematic review and meta-analysis.*

- Protocolo no formato **PROSPERO**, conduzido e relatado conforme **PRISMA 2020**.
- Bases: **PubMed/MEDLINE, Scopus e SciELO** (2020–2026).
- **19.027 registros identificados → 14.978 únicos** após deduplicação (3.505
  duplicatas removidas) prontos para triagem.
- Pipeline único em R (**20 seções**), cobrindo busca, deduplicação, bibliometria,
  triagem por tópicos (`revtools`), risco de viés (ROBINS-I/NOS/OHAT), meta-análise
  (`metafor`) e diagrama PRISMA.
- Status: buscas, deduplicação, bibliometria e diagrama concluídos; **triagem por
  título/resumo em execução**.

---

## Estrutura do repositório

```
DLNM/                                    # raiz do monorepo
├── 01_DLNMs_RJ_cerebrovascular/         # Frente 1 — modelagem DLNM + PM2,5 + auditoria
│   ├── README.md                        # visão da frente
│   ├── data_raw/                         # INMET (estações/zip), SIH, SIM, população, malha
│   ├── data_interim/                     # séries individuais intermediárias (.rds)
│   ├── data_processed/                   # datasets analíticos DLNM (macrorregião/município)
│   ├── 02_MP25_RJ_exposicao/             # extração e agregação de PM2,5 (MonitorAr/VIGIAR)
│   │   ├── scripts/                      # extrair_mp25_rj.py
│   │   ├── data_raw/ · data_processed/
│   │   └── outputs/auditoria/
│   ├── 03_AUDITORIA/                     # auditorias de qualidade de dados (INMET/SIH/SIM/DLNM)
│   │   └── relatorios/                   # qualidade, reprodutibilidade, validação bayesiana
│   └── outputs/
│       ├── figures/                      # Fig01–Fig07 + suplementares + 3D interativos
│       ├── tables/                       # RR, AUC, sensibilidade, priorização
│       ├── reports/                      # sumários da priorização robusta
│       ├── audits/                       # auditorias consolidadas
│       └── logs/                         # logs de execução
│
├── 02_vulnerabilidade_climatica_RAS_RJ/ # Frente 2 — estudo ecológico + GLMM + RAS
│   ├── README.md                         # visão da frente (LEIA-ME.md = atalho)
│   ├── 01_dados/                         # SIH/SIM brutos, processados, inventário, IPCA
│   ├── 02_scripts/                       # pipeline R (00_glmm_utils … 10_figuras) + legado
│   ├── 03_analises/                      # logs de aquisição/consolidação
│   ├── 04_resultados/                    # resultados textuais por etapa
│   ├── 05_tabelas/                       # tabelas numeradas (tab1…tab16, tendências, custos)
│   ├── 06_figuras/                       # figuras do GLMM e séries
│   ├── 07_literatura/                    # matriz de literatura verificada
│   ├── 08_manuscrito/                    # manuscrito.md
│   ├── 09_documentos_submissao/          # modelos de documentos do edital
│   ├── 10_auditoria/                     # auditorias de dados e metodológica
│   ├── 12_relatorios/                    # relatórios executivo e final
│   └── 13_documentos_referencia/         # edital e plano estadual de saúde (PDF)
│
├── 03_revisão_impactos_à_saúde/         # Frente 3 — revisão sistemática + meta-análise
│   ├── README.md                         # visão da frente
│   ├── 00_docs/                          # protocolo PROSPERO, PRISMA, critérios, busca
│   ├── 01_scripts/                       # 00_pipeline_revisao_sistematica.R (pipeline único)
│   ├── 02_dados/                         # brutos, processados, extraídos
│   ├── 03_resultados/                    # figuras, tabelas, bibliometria, logs
│   ├── 04_referencias/                   # referencias.bib, protocolo, session_info
│   ├── HANDOFF.md                        # continuidade do projeto
│   └── sumario_execucao.md               # o que foi executado e próximos passos
│
├── .gitignore                            # exclusões (dados grandes/binários)
├── LICENSE                               # licença MIT
└── README.md                             # este documento (visão do grande projeto)
```

> **Nota:** a numeração das frentes é local a cada pasta; a antiga pasta
> `04_publicacao_github` (scripts de DLNM) foi separada em repositório próprio:
> **<https://github.com/santosry/dlnm-gam-cerebrovascular-rj>**.

---

## Resultados principais

### Frente 01 — DLNM (clima × DCV)

| Indicador | Valor |
|---|---|
| Modelos DLNM ajustados | **128** |
| Achados principais robustos | 2 |
| Achados principais com cautela | 8 |
| Exploratórios por magnitude | 9 |
| Validação bayesiana (linhas) | 72 (posteriores para RR > 1,10) |

Saídas em `01_DLNMs_RJ_cerebrovascular/outputs/` (figuras 3D interativas de RR
temperatura/umidade × defasagem).

### Frente 02 — Vulnerabilidade climática e RAS (2010–2024)

| Indicador | Valor |
|---|---|
| Internações por DCV (SIH-RD; I60–I69 + G45/G46) | **295.673** |
| Óbitos intra-hospitalares | **55.827 (18,88%)** |
| Óbitos por DCV (SIM, causa básica I60–I69) | **147.551** |
| Estabelecimentos (CNES) | 254 |
| VPC / ICC hospitalar | **14,95%** (IC95% 12,29–18,06) |
| MOR | **2,065** (IC95% 1,911–2,253) |
| AUC condicional | 0,740 |
| Coeficientes significativos após FDR | **14 de 19** |
| Índice de Swaroop-Uemura estadual (DCV) | **92,38%** |
| Concentração nos 10 maiores estabelecimentos | 31,3% |

**Destaques:** ~15% da variação da letalidade cerebrovascular está **entre hospitais**
(ao acomodar essa variabilidade, apenas 3 de 206 serviços permanecem atípicos); o
modelo multinível é fortemente necessário (ΔAIC ≈ 7.851 vs. modelo agrupado); e há um
gradiente regional favorável ao interior (ex.: OR ajustado 0,467 no Médio Paraíba).

### Frente 03 — Revisão sistemática e meta-análise

| Indicador | Valor |
|---|---|
| Identificados (PubMed 5.093 + Scopus 13.908 + SciELO 26) | **19.027** |
| Após filtro de período (2020–2026) | 18.483 |
| Duplicatas removidas | 3.505 |
| **Únicos para triagem** | **14.978** |
| Registros na bibliometria | 18.708 |

---

## Fontes de dados

| Dado | Fonte | Período | Frentes |
|---|---|---|---|
| Internações por DCV (I60–I69; G45–G46) | **SIH-RD/SUS** (via `microdatasus`) | 2010–2024 | 01, 02 |
| Óbitos por DCV (I60–I69) | **SIM-DO** (via `microdatasus`) | 2010–2024 | 01, 02 |
| População residente | **IBGE/SIDRA** (tab. 6579 + Censo 2022) | 2010–2025 | 01, 02 |
| Clima (temperatura, umidade) | **INMET** | 2010–2025 | 01 |
| PM2,5 | **MonitorAr/VIGIAR** (via Power BI API) | 2010–2025 | 01 |
| Malha e centróides municipais | **geobr/IBGE** | — | 01, 02 |
| Estabelecimentos de saúde | **CNES/DATASUS** | — | 02 |
| Literatura científica | **PubMed, Scopus, SciELO** | 2020–2026 | 03 |
| Custos hospitalares | SIH-RD + **IPCA/IBGE** (tab. 1737) | 2010–2024 | 02 |

> Os arquivos brutos volumosos (`.rds`, `.zip`, `.parquet`, planilhas grandes) **não**
> são versionados por limitação de tamanho do GitHub — ver [`.gitignore`](.gitignore).
> Os dados são **públicos e anonimizados** (DATASUS/IBGE/INMET); as chaves de API
> (`api_keys.txt`) são ignoradas e não devem ser comitadas.

---

## Métodos (panorama)

| Frente | Desenho | Métodos-chave |
|---|---|---|
| 01 | Modelagem de séries temporais | **DLNM** (clima × DCV), defasagens, FDR, AUC de excesso de RR, validação bayesiana hierárquica, *case-crossover* |
| 02 | Estudo ecológico (2010–2024) | **GLMM logístico de 3 níveis** (`glmmTMB`, conferido em `lme4`), VPC/ICC, MOR, **FDR (BH)**, 18 cenários de robustez, **Mann-Kendall**, **Cochran-Armitage**, **Kruskal-Wallis/Dunn**, **Swaroop-Uemura**, deflação por **IPCA**, concentração por CNES |
| 03 | Revisão sistemática + meta-análise | **PRISMA 2020 / PRISMA-P**, PROSPERO, triagem por tópicos (`revtools`), **ROBINS-I/NOS/OHAT**, meta-análise **REML** (`metafor`), metarregressão, *leave-one-out*, viés de publicação (Egger/trim-and-fill) |

**Ética:** dados secundários, agregados/anonimizados e de domínio público
(Resolução CNS 510/2016 — dispensa de CEP), em conformidade com a LGPD.

---

## Reprodutibilidade

Cada frente traz o seu próprio README com a cadeia de execução. Resumo:

- **Python ≥ 3.10** — `pandas`, `numpy`, `scipy`, `rdata`, `pymannkendall`,
  `matplotlib`, `requests`.
- **R ≥ 4.2** (executado em **R 4.6.1**) — `glmmTMB`, `lme4`, `metafor`, `revtools`,
  `bibliometrix`, `microdatasus`, `tidyverse`, `here`.

```bash
# Frente 01 — dados/resultados (scripts de modelagem no repo dlnm-gam-cerebrovascular-rj)
# Frente 02 — pipeline GLMM (executar na raiz da frente)
cd 02_vulnerabilidade_climatica_RAS_RJ
Rscript 02_scripts/01_baixar_microdatasus.R   # aquisição (~38 min)
Rscript 02_scripts/02_montar_coorte.R         # coorte
Rscript 02_scripts/05_glmm_principal.R        # GLMM + FDR (~3 min)
Rscript 02_scripts/08_glmm_robustez.R         # 18 cenários (~40 min)

# Frente 03 — pipeline único (painel EXEC no topo do script)
cd ../03_revisão_impactos_à_saúde
Rscript 01_scripts/00_pipeline_revisao_sistematica.R
```

> **Nota de ambiente:** carregar `glmmTMB` e `lme4` na mesma sessão R encerra o
> processo; a conferência entre motores roda em processo isolado (script
> `09_conferencia_motores.R`).

---

## Como citar

O estudo está em fase de finalização. Sugere-se, provisoriamente:

> Santos, R. P. **Gatilhos ambientais e doenças cerebrovasculares no Rio de Janeiro e
> suas implicações para a organização da Rede de Atenção à Saúde.** Repositório de
> pesquisa, 2026. Disponível em:
> <https://github.com/santosry/Environmental-Triggers-and-Cerebrovascular>.

---

## Licença

O código, a documentação e os resultados deste repositório estão licenciados sob a
**Licença MIT** — ver [`LICENSE`](LICENSE).

> Os **dados** subjacentes são públicos (DATASUS/IBGE/INMET) e não estão cobertos pela
> licença; cite as fontes originais ao reutilizá-los.

---

## Limitações e ressalvas

- ⚠️ Material de pesquisa **em andamento e ainda não revisado por pares**. Não usar
  para decisão clínica ou assistencial sem validação independente.
- Delineamentos **ecológico/observacionais**: sem inferência causal individual.
- Predomínio de **I64 (AVC não especificado)** — ~57% no SIH e ~38% no SIM — indicando
  viés/baixo detalhamento de codificação diagnóstica.
- Taxas **não padronizadas por idade** diretamente; escolaridade e raça/cor com
  preenchimento limitado no SIH.
- Custos em **valores correntes** na fonte original; comparabilidade intertemporal
  requer deflação por IPCA (já aplicada nos produtos da Frente 02).
- PM2,5 com granularidade **mensal derivada** (não diária) na Frente 01.
- Na Frente 03, a meta-análise/risco de viés atuais usam **dados de demonstração** até
  a extração real.

---

## Contato

**Ryan de Paulo Santos** — <ryandpaulosantos@gmail.com>

Para dúvidas, sugestões ou colaboração, abra uma *issue* neste repositório.
