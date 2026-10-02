# Revisão sistemática e meta-análise — Determinaantes ambientais das doenças cerebrovasculares (CID-10 I60–I69)

**Título do projeto**
> Environmental determinants of cerebrovascular diseases (ICD-10 I60–I69) across the
> lifespan: a global systematic review and meta-analysis

**Pergunta (PICO)**
- **P** Populações humanas, todas as idades, escala global
- **I** Exposições ambientais modificáveis (clima/temperatura, poluição do ar/água/solo/
  sonora, saneamento, moradia/combustíveis sólidos, catástrofes naturais, ambiente
  construído, ocupacional de natureza ambiental)
- **C** Ausência, baixa exposição ou referência
- **O** Incidência, mortalidade, hospitalizações e gravidade de DCV (CID-10 I60–I69)

**Período:** 2020-01-01 a 2026-09-30 · **Idiomas:** inglês, português, espanhol
**Relato:** PRISMA 2020 (Page et al., 2021; doi:10.1136/bmj.n71)

---

## Estrutura do projeto

```
03_revisão_impactos_à_saúde/
├── 00_docs/
│   ├── protocolo_PROSPERO.md          Protocolo (formato PROSPERO)
│   ├── prisma_checklist.md            Checklist PRISMA-P 2015
│   ├── prisma_2020_checklist.md       Checklist PRISMA 2020 (27 itens) — NOVO
│   ├── prisma_2020_conformidade.md    Documento de conformidade PRISMA 2020 — NOVO
│   ├── prisma_flow_diagram.md         Especificação do diagrama de fluxo
│   ├── criterios_inclusao_exclusao.md Critérios de elegibilidade
│   ├── dicionario_dados.md            Dicionário das variáveis de extração
│   ├── estrategia_busca.md            Strings por base + MeSH/DeCS/Emtree
│   ├── triagem_titulo_resumo.md       Método da triagem assistida por tópicos — NOVO
│   ├── como_rodar_triagem.md          Passo a passo da triagem — NOVO
│   └── relatorio_final.md             Relatório (estrutura PRISMA)
├── 01_scripts/
│   └── 00_pipeline_revisao_sistematica.R   SCRIPT ÚNICO (todas as etapas, por seções)
├── 02_dados/{brutos,processados,extraidos}/
├── 03_resultados/{figuras,tabelas,bibliometria,logs}/
├── 04_referencias/{referencias.bib,protocolo_referencias.md,session_info.txt}
├── README.md
└── sumario_execucao.md
```

> **Todo o pipeline está em um único script:**
> [`01_scripts/00_pipeline_revisao_sistematica.R`](01_scripts/00_pipeline_revisao_sistematica.R),
> organizado em **20 seções** numeradas e comentadas, com um **painel de controle**
> (`EXEC`) para ligar/desligar cada etapa. As etapas de rede pesada (buscas,
> enriquecimento) e o app interativo de triagem ficam desligados por padrão.

## PRISMA 2020

O projeto segue integralmente o **PRISMA 2020** (Page MJ, et al. *BMJ*. 2021;372:n71):

- Checklist dos 27 itens: [`00_docs/prisma_2020_checklist.md`](00_docs/prisma_2020_checklist.md)
- Documento de conformidade: [`00_docs/prisma_2020_conformidade.md`](00_docs/prisma_2020_conformidade.md)
- Diagrama de fluxo: [`00_docs/prisma_flow_diagram.md`](00_docs/prisma_flow_diagram.md)
  e seção 18 do script único (`01_scripts/00_pipeline_revisao_sistematica.R`)
  (pacote `PRISMA2020`; Haddaway et al., 2022; doi:10.1002/cl2.1230)
- Resultado do diagrama: `03_resultados/figuras/prisma_flow_diagram.png`

## Como executar (script único)

Todas as etapas estão no arquivo
[`01_scripts/00_pipeline_revisao_sistematica.R`](01_scripts/00_pipeline_revisao_sistematica.R).
Edite o **painel `EXEC`** no topo do arquivo (TRUE/FALSE por etapa) e rode o
arquivo inteiro — ou apenas a seção desejada.

```bash
# rodar o pipeline (respeitando o painel EXEC)
Rscript 01_scripts/00_pipeline_revisao_sistematica.R

# alguns parâmetros podem ser passados por linha de comando
Rscript 01_scripts/00_pipeline_revisao_sistematica.R --n_topics=10 --iterations=800
Rscript 01_scripts/00_pipeline_revisao_sistematica.R --limite=500   # enriquecimento
Rscript 01_scripts/00_pipeline_revisao_sistematica.R --teste        # lotes com 300 registros
Rscript 01_scripts/00_pipeline_revisao_sistematica.R --forcar       # refaz lotes de tópicos
```

> A **seção 10** (app `revtools::screen_topics`) é interativa e **exige o RStudio**:
> abra `revisao_sistematica.Rproj`, rode o script com `topicos_app = TRUE` e use
> `status_lotes()`, `triar_lote("lote_01")` e `triar_pendentes()`.
>
> Passo a passo detalhado da triagem: [`00_docs/como_rodar_triagem.md`](00_docs/como_rodar_triagem.md).

## Reprodutibilidade (FAIR)

- O script único registra a sessão em `04_referencias/session_info.txt` e o log
  em `03_resultados/logs/pipeline.log`.
- Semente fixa (`set.seed(20202026)`), caminhos relativos (`here::here()`).
- Dados brutos preservados em `02_dados/brutos/`; nenhum dado bruto é editado.
- Saídas em formatos abertos (CSV, RDS, PNG, BibTeX).

## Fundamentação

Todas as decisões metodológicas estão referenciadas em
[`04_referencias/protocolo_referencias.md`](04_referencias/protocolo_referencias.md) e em
[`04_referencias/referencias.bib`](04_referencias/referencias.bib), com DOIs verificáveis.

## Status de execução (27/09/2026)

- **PubMed:** 5.093 · **Scopus:** 13.908 (API key) · **SciELO:** 26 (web scraping
  headless; 69 no total, 26 no período 2020–2026).
- **Deduplicação:** 3.505 duplicatas removidas → **14.978 registros** para triagem.
- **Bibliometria:** 18.708 registros analisados (`03_resultados/bibliometria/`).
- **Diagrama PRISMA 2020:** `03_resultados/figuras/prisma_flow_diagram.png`.
- **Triagem por título/resumo:** implementada no script único (seções 8–12) e
  testada; **aguardando a execução dos lotes** (passo a passo em
  [`00_docs/como_rodar_triagem.md`](00_docs/como_rodar_triagem.md)).
- Detalhes completos em [`sumario_execucao.md`](sumario_execucao.md).

> Bases do projeto: **PubMed, Scopus e SciELO**.

## Handoff

Estado do projeto, decisões técnicas e **próximo passo** (triagem por título/resumo
com `revtools::screen_topics`, em lotes) estão em [`HANDOFF.md`](HANDOFF.md).
