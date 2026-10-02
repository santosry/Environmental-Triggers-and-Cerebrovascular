# Sumário de execução

**Projeto:** Environmental determinants of cerebrovascular diseases (ICD-10 I60–I69)
across the lifespan: a global systematic review and meta-analysis
**Data:** 26/09/2026
**Ambiente:** R 4.6.1 (ucrt) · Windows · pasta `03_revisão_impactos_à_saúde/`

Este documento registra o que foi criado, o que foi executado e os próximos passos.
Todos os arquivos e saídas estão **dentro da pasta do projeto** (estrutura oficial).

---

## 1. Estrutura criada

```
03_revisão_impactos_à_saúde/
├── 00_docs/
│   ├── protocolo_PROSPERO.md
│   ├── prisma_checklist.md              (PRISMA-P 2015)
│   ├── prisma_2020_checklist.md         (27 itens PRISMA 2020 — preenchido)
│   ├── prisma_2020_conformidade.md
│   ├── prisma_flow_diagram.md
│   ├── criterios_inclusao_exclusao.md
│   ├── dicionario_dados.md
│   ├── estrategia_busca.md
│   └── relatorio_final.md
├── 01_scripts/                          1 script R (pipeline completo, 20 seções)
├── 02_dados/{brutos,processados,extraidos}/
├── 03_resultados/{figuras,tabelas,bibliometria,logs}/
├── 04_referencias/{referencias.bib,protocolo_referencias.md,session_info.txt,api_keys.txt*}
├── README.md
├── sumario_execucao.md
├── revisao_sistematica.Rproj
└── .here
```
`*` `api_keys.txt` está no `.gitignore` (não deve ser comitado).

## 2. Script único (consolidado)

Todo o pipeline foi reunido em **um único arquivo** —
`01_scripts/00_pipeline_revisao_sistematica.R` — organizado em **20 seções**
numeradas e comentadas, com um **painel de controle** (`EXEC`) para ligar/desligar
cada etapa. Corresponde à soma dos antigos scripts:

| Seção | Etapa | Equivale ao antigo script | Status |
|---|---|---|---|
| 1 | Ambiente, pastas, sessão, funções de apoio | `00_setup.R`, `_funcoes_triagem.R` | ✅ Executado |
| 2 | Estratégia de busca (litsearchr) | `01_busca_litsearchr.R` | ✅ Executado (915 termos; 482 keywords) |
| 3 | Busca PubMed | `02_busca_pubmedR.R` | ✅ Executado — **5.093** registros |
| 4 | Busca Scopus | `02b_busca_scopus.R` | ✅ Executado — **13.908** registros |
| 5 | Busca SciELO (web scraping) | `02c_busca_scielo.R` | ✅ Executado — 26 registros |
| 6 | Deduplicação/triagem | `03_triagem_revtools.R` | ✅ Executado — 3.505 duplicatas; 14.978 únicos |
| 7 | Bibliometria | `04_bibliometria_bibliometrix.R` | ✅ Executado — 18.708 registros |
| 8 | Enriquecimento de resumos (PubMed) | `16_enriquecer_abstracts.R` | ✅ Testado |
| 9 | Preparação dos lotes de tópicos | `13_triagem_titulo_resumo.R` | ✅ Testado |
| 10 | App de triagem por tópicos | `13b_triagem_app_topicos.R` | ✅ Testado (exige RStudio) |
| 11 | Consenso + kappa (fase 1) | `14_consolidar_triagem_titulo_resumo.R` | ✅ Testado |
| 12 | Triagem de texto completo | `15_triagem_texto_completo.R` | ✅ Testado |
| 13 | Extração + `escalc()` | `05_extracao_dados.R` | ✅ Executado (demonstração) |
| 14 | Risco de viés (ROBINS-I/NOS/OHAT) | `06_risco_de_vies.R` | ✅ Executado (demonstração) |
| 15 | Meta-análise REML + viés | `07_meta_analise_metafor.R` | ✅ Executado (demonstração) |
| 16 | Forest plots estratificados | `08_forest_plots.R` | ✅ Executado |
| 17 | Subgrupos/metarregressão/sensibilidade | `09_analises_subgrupo.R` | ✅ Executado |
| 18 | Diagrama PRISMA 2020 | `11_prisma_flow_diagram.R` | ✅ Executado — PNG gerado |
| 19 | Figuras simples (PNG 300 dpi) | `12_figuras_simples.R` | ✅ Executado |
| 20 | Relatório final (R Markdown) | `10_relatorio_final.Rmd` | Pronto (render exige pandoc) |

> Os antigos scripts individuais foram removidos; o pipeline único foi validado
> (parse + execução completa em sandbox, sem erros). Guia de execução:
> [`00_docs/como_rodar_triagem.md`](00_docs/como_rodar_triagem.md).

## 3. Bases de dados (conforme protocolo revisado)

| Base | Método | Registros |
|---|---|---|
| PubMed/MEDLINE | `rentrez`/`pubmedR` (API livre) | 5.093 |
| Scopus | API Elsevier (chave fornecida) | 13.908 (API total 13.914) |
| SciELO | web scraping (Chrome headless) | 26 (69 no total; 26 no período) |

> Bases do projeto: **PubMed, Scopus e SciELO**. Documentado em `00_docs/estrategia_busca.md`.

## 4. Resultados da execução (números reais)

- **Identificação:** 19.027 registros (PubMed 5.093 + Scopus 13.908 + SciELO 26).
- **Após filtro de período (2020–2026):** 18.483.
- **Duplicatas removidas (DOI exato + título normalizado):** 3.505.
- **Após deduplicação:** **14.978** registros para triagem por título/abstrato.
- **Bibliometria:** 18.708 registros (produção anual, Bradford, autores, países).
- **Diagrama PRISMA 2020:** `03_resultados/figuras/prisma_flow_diagram.png`.

## 5. Saídas geradas

- `02_dados/brutos/`: `pubmed_records.csv`, `scopus_records.csv`, contagens, queries.
- `02_dados/processados/`: `registros_deduplicados.csv`, planilhas de triagem,
  `efeitos_calculados.rds` (demonstração), `litsearchr_termos.csv`, `litsearchr_rede.png`.
- `03_resultados/tabelas/`: `prisma_contagens.csv`, `meta_analise_geral.csv`,
  `subgrupos.csv`, `leave_one_out.csv`, `validacao_extracao.csv`, etc.
- `03_resultados/figuras/`: 8 figuras simples `01..08*.png` + `LEIA-ME.md`
  e `prisma_flow_diagram.png`.
- `03_resultados/bibliometria/`: produção anual, Bradford, autores, países, sumário.
- `04_referencias/`: `referencias.bib`, `protocolo_referencias.md`, `session_info.txt`,
  `litsearchr_keywords.csv`.

## 6. Fundamentação

Todas as decisões metodológicas estão referenciadas em
`04_referencias/protocolo_referencias.md` e `04_referencias/referencias.bib`
(PRISMA 2020; PRISMA-P; Cochrane; Borenstein 2021; Viechtbauer 2005/2010;
Higgins & Thompson 2002; Egger 1997; Duval & Tweedie 2000; Sterne 2016 (ROBINS-I);
McGuinness & Higgins 2021 (robvis); Gasparrini 2011/2015; WHO 2021; Feigin 2021;
Aria & Cuccurullo 2017; Grames 2019; Haddaway 2022; entre outros).

## 7. Próximos passos

1. ~~SciELO~~ **concluído** por web scraping; reexecutar triagem/PRISMA já feito.
2. **Triagem por título/abstrato (fase 1):** passos 1–4 de
   [`00_docs/como_rodar_triagem.md`](00_docs/como_rodar_triagem.md), ligando no
   painel `EXEC` do script único as seções 8 (resumos), 9 (lotes), 10 (app no
   RStudio) e 11 (consenso + kappa).
3. **Texto completo (fase 2):** seção 12 do script único (templates, kappa,
   motivos de exclusão — alimenta o item 16b do PRISMA).
4. **Extração:** preencher `02_dados/extraidos/planilha_extracao.csv`; reexecutar
   `05`→`09` para resultados reais de meta-análise.
5. **Risco de viés:** preencher domínios ROBINS-I/OHAT; reexecutar `06`.
6. **Relatório:** renderizar `10_relatorio_final.Rmd` (instalar pandoc) ou converter.
7. **Registro PROSPERO:** submeter `00_docs/protocolo_PROSPERO.md`.

## 8. Pendências conhecidas / limitações

- SciELO exige web scraping (bot-shield); resolvido com Chrome headless + processx.
- Deduplicação fuzzy do `revtools` é O(n²): omitida para n > 5.000
  (usados DOI exato + título normalizado). Executável em subconjuntos.
- Triagem por tópicos em **lotes** (por base × ano): o modelo no conjunto completo
  (14.978 registros, ~70% sem resumo) não terminou em ~25 min. Cada lote vira um
  `.rds` com modelo pré-calculado, e o app abre instantaneamente.
- A chave Scopus do projeto **não retorna resumos** na Abstract Retrieval API
  (testado em 27/09/2026); o enriquecimento de resumos usa o **PubMed** por DOI.
- `write_search()` do litsearchr requer sessão interativa (`menu()`); a estratégia
  final está documentada e versionada em `00_docs/estrategia_busca.md`.
- `PRISMA_save()` requer pandoc; PNG gerado via navegador headless (Chrome/Edge).
- Meta-análise atual usa **dados de demonstração** até a extração real.
