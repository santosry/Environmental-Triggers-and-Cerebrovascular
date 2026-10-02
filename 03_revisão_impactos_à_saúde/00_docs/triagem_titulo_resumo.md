# Triagem por título/resumo assistida por tópicos

**Projeto:** Determinantes ambientais das doenças cerebrovasculares (CID-10 I60–I69)
**Etapa:** seleção de estudos — fase 1 (título/resumo)
**Data de criação:** 27/09/2026

---

## 1. Por que usar modelos de tópicos

A triagem por título/resumo de **14.978 registros** é inviável de forma puramente manual
no tempo disponível. Os modelos de tópicos agrupam registros com vocabulário semelhante,
de modo que o revisor pode decidir um tópico inteiro (vários artigos) de uma só vez,
voltando a casos individuais quando necessário.

> **Importante:** a triagem assistida por tópicos **não substitui** a triagem manual.
> Ela é uma ferramenta de **priorização/agrupamento**; a decisão final de inclusão é
> humana e registrada individualmente (Cochrane Handbook, cap. 4; PRISMA 2020, item 8).

## 2. Fundamentação metodológica

| Referência | Uso no projeto |
|---|---|
| Westgate MJ. *revtools*: An R package to support article screening for evidence synthesis. **Res Synth Methods**. 2019;10(4):606-614. [doi:10.1002/jrsm.1374](https://doi.org/10.1002/jrsm.1374) | Ferramenta (`screen_topics`), base metodológica do agrupamento |
| Westgate MJ, Lindenmayer DB. Accepted or rejected? Assessing the utility of machine learning for… **Conserv Biol**. 2017;31(5):1096-1106. [doi:10.1111/cobi.12863](https://doi.org/10.1111/cobi.12863) | Avaliação da triagem assistida por aprendizado de máquina |
| Cochrane Handbook for Systematic Reviews of Interventions, cap. 4. Higgins JPT, et al., 2019. [doi:10.1002/9781119536604](https://doi.org/10.1002/9781119536604) | Triagem por dois revisores independentes |
| PRISMA 2020. Page MJ, et al. **BMJ**. 2021;372:n71. [doi:10.1136/bmj.n71](https://doi.org/10.1136/bmj.n71) | Itens 8, 16a–b (processo de seleção e motivos) |
| Ouzzani M, et al. Rayyan. **Syst Rev**. 2016;5:210. [doi:10.1186/s13643-016-0384-4](https://doi.org/10.1186/s13643-016-0384-4) | Concordância entre revisores (κ) |
| Cohen J. **Educ Psychol Meas**. 1960;20(1):37-46. [doi:10.1177/001316446002000104](https://doi.org/10.1177/001316446002000104) | Cálculo do kappa |

## 3. Desenho da triagem

- **Unidade de agrupamento:** um registro = um documento (o app usa `label` único).
  O modelo de tópicos (LDA, `topicmodels`, via Gibbs) agrupa os documentos.
- **Estratégia em LOTES (obrigatória):** o modelo no conjunto completo (14.978 registros,
  ~70% sem resumo) **não terminou em 25 min** no teste de 26/09/2026. A solução é dividir
  em lotes por **base × ano** (PubMed e Scopus) e tratar os pequenos lotes (SciELO)
  em conjunto. Cada lote gera um objeto `screen_topics_progress` (`.rds`) já com o
  modelo pré-calculado, o que faz o app abrir instantaneamente.
- **Palavras a remover do DTM (`remove_words`):** `study`, `results`, `conclusion`,
  `background`, `objective`, `methods`, `conclusions`, `method`, `aim`, `aims`
  (marcadores de seção em resumos estruturados; Westgate, 2019).
- **Parâmetros do modelo (padrão):** `n_topics = 12`, `iterations = 1000`,
  `min_freq = 0.02`, `max_freq = 0.90`, **sem bigramas** (`bigram_check = FALSE`)
  para reduzir o custo computacional. O número de tópicos é reduzido automaticamente
  em lotes pequenos (`k = min(n_topics, floor(n_docs/8))`, mínimo 2).
- **Rastreabilidade:** cada registro recebe `id` (= ordem em
  `registros_deduplicados.csv`, igual ao das planilhas de triagem) e `label`
  (`ref_XXXXX`). As decisões do app usam o `label`/`id`, permitindo consolidar com as
  planilhas de revisores.

## 4. Comandos

```bash
# 1) preparar os lotes (EXEC$topicos_preparar = TRUE; seção 9) — retomável
Rscript 01_scripts/00_pipeline_revisao_sistematica.R

# 2) triar cada lote no RStudio (EXEC$topicos_app = TRUE; seção 10), salvando as decisões
#    (veja o passo a passo em 00_docs/como_rodar_triagem.md)
```

## 5. Fundamentos éticos e de reprodutibilidade

- Semente fixa (`set.seed(20202026)`); scripts versionados; saídas em formato aberto.
- As decisões do app são salvas por lote em CSV e em RDS (retomável).
- O app não altera os dados de origem; escreve somente em
  `02_dados/processados/topicos/decisoes/`.

---

## 6. Lotes gerados

<!-- INICIO_LOTES -->
(Esta seção é preenchida automaticamente pela seção 9 do script único.)
<!-- FIM_LOTES -->
