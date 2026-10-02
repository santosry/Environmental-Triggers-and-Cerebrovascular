# Checklist PRISMA 2020 — preenchido

**Referência:** Page MJ, McKenzie JE, Bossuyt PM, Boutron I, Hoffmann TC, Mulrow CD,
et al. The PRISMA 2020 statement: an updated guideline for reporting systematic reviews.
*BMJ*. 2021;372:n71. doi:10.1136/bmj.n71
(e também Page MJ, et al. PRISMA 2020 explanation and elaboration. *BMJ*.
2021;372:n160. doi:10.1136/bmj.n160).

**Legenda de status:**
- ✅ **Reportado** — informação presente em arquivo do projeto;
- 🟡 **Parcialmente reportado** — parcialmente descrito, pendente de detalhe;
- ⬜ **Não reportado** — depende de execução (fase de resultados) ou de preenchimento
  pelos autores.

> Nota: o projeto encontra-se na fase de **protocolo/busca**. Itens de Métodos estão
> reportados nos documentos e scripts; itens de Resultados serão preenchidos após a
> execução das buscas, triagem e síntese.

| Seção/Tópico | Item | Descrição (PRISMA 2020) | Onde no projeto | Status |
|---|---|---|---|---|
| **TITLE** | 1 | Identificar o relatório como revisão sistemática. | Título (README/PROTOCOLO); título do manuscrito em `08`→`00_docs` | ✅ |
| **ABSTRACT** | 2 | Resumo estruturado conforme o checklist PRISMA 2020 for Abstracts. | `00_docs/relatorio_final.md` (a preencher com resultados) | 🟡 |
| **INTRODUCTION** | 3 | Justificativa da revisão no contexto do conhecimento existente. | `00_docs/protocolo_PROSPERO.md` §12; `09`→Introdução | ✅ |
| **INTRODUCTION** | 4 | Objetivos explícitos (questão/PICO). | `00_docs/protocolo_PROSPERO.md` §9 | ✅ |
| **METHODS** | 5 | Critérios de elegibilidade e agrupamento para síntese. | `00_docs/criterios_inclusao_exclusao.md` | ✅ |
| **METHODS** | 6 | Fontes de informação, com datas de última busca. | `00_docs/estrategia_busca.md`; `01_scripts/00_pipeline_revisao_sistematica.R (seção 3)` | 🟡 |
| **METHODS** | 7 | Estratégias de busca completas, filtros e limites. | `00_docs/estrategia_busca.md` | ✅ |
| **METHODS** | 8 | Processo de seleção (nº de revisores, independência, automação). | `01_scripts/00_pipeline_revisao_sistematica.R (seção 6)`; Protocolo §20 | ✅ |
| **METHODS** | 9 | Processo de coleta de dados (revisores, independência, automação). | `01_scripts/00_pipeline_revisao_sistematica.R (seção 13)`; Protocolo §20 | ✅ |
| **METHODS** | 10a | Desfechos buscados; todos os resultados compatíveis por domínio. | `00_docs/dicionario_dados.md`; `01_scripts/00_pipeline_revisao_sistematica.R (seção 13)` | ✅ |
| **METHODS** | 10b | Demais variáveis buscadas (exposição, confundidores, ajuste). | `00_docs/dicionario_dados.md` | ✅ |
| **METHODS** | 11 | Avaliação do risco de viés (ferramentas, nº de revisores). | `01_scripts/00_pipeline_revisao_sistematica.R (seção 14)`; Protocolo §21 | ✅ |
| **METHODS** | 12 | Medidas de efeito por desfecho. | `01_scripts/00_pipeline_revisao_sistematica.R (seção 13)`; Protocolo §12 | ✅ |
| **METHODS** | 13a | Processo de decisão de elegibilidade para cada síntese. | `01_scripts/00_pipeline_revisao_sistematica.R (seção 15)`; `00_docs/relatorio_final.md` | ✅ |
| **METHODS** | 13b | Métodos de preparação dos dados para síntese. | `01_scripts/00_pipeline_revisao_sistematica.R (seção 13)` | ✅ |
| **METHODS** | 13c | Métodos de síntese e justificativa (efeitos aleatórios/REML). | `01_scripts/00_pipeline_revisao_sistematica.R (seção 15)`; Protocolo §22 | ✅ |
| **METHODS** | 13d | Métodos de exploração da heterogeneidade (subgrupos/metarregressão). | `01_scripts/00_pipeline_revisao_sistematica.R (seção 17)`; Protocolo §23 | ✅ |
| **METHODS** | 13e | Análises de sensibilidade. | `01_scripts/00_pipeline_revisao_sistematica.R (seção 17)` | ✅ |
| **METHODS** | 13f | Métodos para risco de viés por resultados faltantes (viés de relato). | `01_scripts/00_pipeline_revisao_sistematica.R (seção 15)` (Egger/trim-and-fill) | ✅ |
| **METHODS** | 14 | Avaliações de risco de viés por resultados faltantes por síntese. | `01_scripts/00_pipeline_revisao_sistematica.R (seção 15)` | 🟡 |
| **METHODS** | 15 | Avaliação de certeza da evidência (GRADE). | `00_docs/relatorio_final.md`; `04_referencias` (GRADE) | 🟡 |
| **RESULTS** | 16a | Resultados da busca e seleção (números por etapa). | `03_resultados/tabelas/prisma_contagens.csv` | ⬜ |
| **RESULTS** | 16b | Citar estudos que aparentam atender, mas foram excluídos. | `08`→listas de exclusão | ⬜ |
| **RESULTS** | 17 | Citar cada estudo incluído e apresentar características. | `02_dados/extraidos/planilha_extracao.csv` | ⬜ |
| **RESULTS** | 18 | Apresentar risco de viés de cada estudo incluído. | `03_resultados/figuras/rob_*.png` | ⬜ |
| **RESULTS** | 19 | Resultados individuais dos estudos (estatísticas e estimativas). | `03_resultados/tabelas/` (forest) | ⬜ |
| **RESULTS** | 20a | Sumarizar características/risco de viés dos estudos contribuintes. | `00_docs/relatorio_final.md` | ⬜ |
| **RESULTS** | 20b | Resultados de todas as sínteses estatísticas. | `03_resultados/tabelas/meta_analise_geral.csv` | ⬜ |
| **RESULTS** | 20c | Investigações de causas de heterogeneidade. | `03_resultados/tabelas/subgrupos.csv`, `metarregressao.csv` | ⬜ |
| **RESULTS** | 20d | Resultados das análises de sensibilidade. | `03_resultados/tabelas/leave_one_out.csv` | ⬜ |
| **RESULTS** | 21 | Avaliação de risco de viés por resultados faltantes por síntese. | `03_resultados/tabelas/vies_publicacao.txt` | ⬜ |
| **RESULTS** | 22 | Avaliação de certeza por desfecho. | `00_docs/relatorio_final.md` | ⬜ |
| **DISCUSSION** | 23a | Interpretação geral no contexto de outras evidências. | `00_docs/relatorio_final.md` | ⬜ |
| **DISCUSSION** | 23b | Limitações das evidências incluídas. | `00_docs/relatorio_final.md` | ⬜ |
| **DISCUSSION** | 23c | Limitações dos processos da revisão. | `00_docs/relatorio_final.md` | ⬜ |
| **DISCUSSION** | 23d | Implicações para prática, política e pesquisa futura. | `00_docs/relatorio_final.md` | ⬜ |
| **OTHER** | 24a | Registro da revisão (nome e número) ou declaração de não registro. | `00_docs/protocolo_PROSPERO.md` §4 | 🟡 |
| **OTHER** | 24b | Onde o protocolo pode ser acessado. | `00_docs/protocolo_PROSPERO.md` | ✅ |
| **OTHER** | 24c | Emendas ao protocolo/registro. | `00_docs/relatorio_final.md` (controle de versões) | ⬜ |
| **OTHER** | 25 | Fontes de apoio financeiro/não financeiro. | `00_docs/protocolo_PROSPERO.md` §7 | 🟡 |
| **OTHER** | 26 | Declaração de conflitos de interesse. | `00_docs/protocolo_PROSPERO.md` §6 | ✅ |
| **OTHER** | 27 | Disponibilidade de dados, código e materiais. | `README.md`; `01_scripts/`; `02_dados/` | ✅ |

**Resumo do status:** Métodos majoritariamente ✅; Resultados e Discussão ⬜ (serão
preenchidos após execução). Itens 🟡 exigem detalhes finais dos autores.
