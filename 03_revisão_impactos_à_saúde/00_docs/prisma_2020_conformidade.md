# Conformidade com o PRISMA 2020

**Referência principal:** Page MJ, McKenzie JE, Bossuyt PM, Boutron I, Hoffmann TC,
Mulrow CD, et al. The PRISMA 2020 statement: an updated guideline for reporting
systematic reviews. *BMJ*. 2021;372:n71. doi:10.1136/bmj.n71
**Elaboração:** Page MJ, Moher D, Bossuyt PM, et al. PRISMA 2020 explanation and
elaboration. *BMJ*. 2021;372:n160. doi:10.1136/bmj.n160
**Ferramenta de fluxo:** Haddaway NR, Page MJ, Pritchard CC, McGuinness LA. PRISMA2020:
An R package and Shiny app for producing PRISMA 2020-compliant flow diagrams.
*Campbell Syst Rev*. 2021;17(2):e1142. doi:10.1002/cl2.1142

Este documento demonstra **como cada etapa do projeto** atende aos requisitos do
PRISMA 2020. O checklist item a item está em `prisma_2020_checklist.md`.

---

## 1. Título e resumo (itens 1–2)

- O projeto identifica-se explicitamente como "systematic review and meta-analysis" no
  `README.md` e no `00_docs/protocolo_PROSPERO.md`.
- O resumo estruturado do relatório (`01_scripts/00_pipeline_revisao_sistematica.R (seção 20)`) seguirá o
  *PRISMA 2020 for Abstracts*: antecedentes, objetivos, métodos (elegibilidade, fontes,
  risco de viés, síntese), resultados (estudos incluídos, síntese, heterogeneidade,
  certeza) e limitações.

## 2. Introdução (itens 3–4)

- **Justificativa:** contexto da carga global de AVC e dos determinantes ambientais
  (Feigin et al., 2021; Landrigan et al., 2018; WHO, 2021).
- **Objetivos:** formulados em PICO explícito (`protocolo_PROSPERO.md` §9 e
  `criterios_inclusao_exclusao.md`).

## 3. Métodos (itens 5–15)

| Requisito PRISMA 2020 | Como é atendido | Evidência |
|---|---|---|
| 5. Critérios de elegibilidade | Critérios detalhados e ordem de aplicação | `criterios_inclusao_exclusao.md` |
| 6. Fontes de informação | 3 bases (PubMed, Scopus, SciELO) + literatura cinzenta + citação em cadeia | `estrategia_busca.md` |
| 7. Estratégia completa | Strings por base, com filtros e limites; busca validada por litsearchr | `estrategia_busca.md`; `01_busca_litsearchr.R`; `02_busca_pubmedR.R` |
| 8. Processo de seleção | Dois revisores independentes; dedup com revtools; kappa | `03_triagem_revtools.R` |
| 9. Coleta de dados | Formulário padronizado, piloto, dupla extração parcial | `05_extracao_dados.R`; `dicionario_dados.md` |
| 10a–b. Dados buscados | Lista de desfechos e covariáveis | `dicionario_dados.md` |
| 11. Risco de viés | ROBINS-I + NOS + OHAT (adaptado) | `06_risco_de_vies.R` |
| 12. Medidas de efeito | RR/OR/HR em escala log | `05_extracao_dados.R` |
| 13a–f. Métodos de síntese | Efeitos aleatórios REML, I²/τ², predição, subgrupos, sensibilidade, viés de relato | `07_meta_analise_metafor.R`; `09_analises_subgrupo.R` |
| 14. Viés por resultados faltantes | Funnel/Egger/trim-and-fill (k ≥ 10) | `07_meta_analise_metafor.R` |
| 15. Certeza | GRADE | `relatorio_final.md` |

## 4. Resultados (itens 16–22)

Estrutura pronta para receber os resultados:
- Fluxo PRISMA (16a–b): script único `01_scripts/00_pipeline_revisao_sistematica.R`
  (seção 18) + `prisma_contagens.csv`.
- Características dos estudos (17): `02_dados/extraidos/planilha_extracao.csv`.
- Risco de viés (18): `robvis` → `03_resultados/figuras/rob_*.png`.
- Resultados individuais e sínteses (19–20): `forest_*.png`, `meta_analise_geral.csv`,
  `subgrupos.csv`, `metarregressao.csv`, `leave_one_out.csv`.
- Viés de relato (21) e certeza (22): `vies_publicacao.txt`; GRADE.

> **Observação:** os itens 16–22 permanecem ⬜ no checklist porque dependem da execução
> das buscas, triagem e extração (etapas humanas). A infraestrutura de geração está
> completa.

## 5. Discussão e informação adicional (itens 23–27)

- Interpretação, limitações das evidências e do processo, e implicações: seção de
  Discussão de `10_relatorio_final.Rmd` e `relatorio_final.md`.
- Registro (24a–c): PROSPERO (protocolo em `protocolo_PROSPERO.md`).
- Apoio e conflitos (25–26): §7 e §6 do protocolo.
- Disponibilidade de dados/código (27): repositório com scripts e dados derivados
  (princípios FAIR), conforme `README.md`.

## 6. Reprodutibilidade e transparência

- `01_scripts/00_pipeline_revisao_sistematica.R (seção 1)` registra `sessionInfo()` em
  `04_referencias/session_info.txt`.
- Semente aleatória fixa (`set.seed(20202026)`) em todos os scripts com estocasticidade.
- Caminhos relativos via `here::here()`.
- Logs e saídas em formatos abertos (CSV, RDS, PNG).

## 7. Desvios e emendas

Qualquer alteração ao protocolo registrado será documentada aqui, com data e
justificativa (PRISMA 2020, item 24c).

| Data | Emenda | Justificativa |
|---|---|---|
| [preencher] | [preencher] | [preencher] |
