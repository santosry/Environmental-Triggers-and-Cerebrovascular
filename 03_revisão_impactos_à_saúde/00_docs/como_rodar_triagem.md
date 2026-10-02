# Como rodar a triagem (passo a passo)

Todo o pipeline vive em **um único script**:
[`../01_scripts/00_pipeline_revisao_sistematica.R`](../01_scripts/00_pipeline_revisao_sistematica.R).

Ele é organizado em **20 seções** numeradas e tem, no topo, um **painel de controle**
(`EXEC`, com `TRUE`/`FALSE`) para ligar/desligar cada etapa. Cada seção roda dentro de
um `tryCatch`: um erro em uma etapa **não** derruba as demais (e fica no log
`03_resultados/logs/pipeline.log`).

> Contexto metodológico: [`triagem_titulo_resumo.md`](triagem_titulo_resumo.md).
> Estado geral do projeto: [`../HANDOFF.md`](../HANDOFF.md).

---

## Preparação do ambiente (uma vez por sessão)

No **Git Bash**, a partir da pasta do projeto:

```bash
export PATH="/c/Program Files/R/R-4.6.1/bin:$PATH"
cd "C:/Users/oorie/OneDrive/Documentos/TRABALHOS/DLNM/03_revisão_impactos_à_saúde"
touch .here          # garante a âncora do here::here()

# (opcional) fechar R/Chrome residuais
ps -W | grep -iE "Rscript|chrome"
```

---

## Painel de controle (`EXEC`)

Abra o script no RStudio/editor e ajuste as linhas abaixo conforme a etapa.
**Deixe ligado** (`TRUE`) apenas o que você quer rodar; o resto fica `FALSE`.

| Etapa | Flag em `EXEC` | Seção | Observação |
|---|---|---|---|
| Ambiente/pastas/log | `setup` | 1 | sempre `TRUE` |
| Estratégia de busca | `busca_litsearchr` | 2 | internet |
| Busca PubMed | `busca_pubmed` | 3 | internet |
| Busca Scopus | `busca_scopus` | 4 | internet + API key |
| Busca SciELO | `busca_scielo` | 5 | Chrome headless |
| Deduplicação/planilhas | `deduplicacao` | 6 | rápido |
| Bibliometria | `bibliometria` | 7 | pode demorar |
| Resumos (PubMed) | `enriquecer_abstracts` | 8 | internet, retomável |
| Preparar lotes de tópicos | `topicos_preparar` | 9 | offline, demorado |
| App de triagem | `topicos_app` | 10 | **RStudio**, interativo |
| Consenso + kappa | `consolidar_triagem` | 11 | rápido |
| Texto completo | `texto_completo` | 12 | rápido |
| Extração/efeitos | `extracao` | 13 | |
| Risco de viés | `risco_vies` | 14 | |
| Meta-análise | `meta_analise` | 15 | |
| Forest plots | `forest_plots` | 16 | |
| Subgrupos | `subgrupos` | 17 | |
| Diagrama PRISMA | `prisma` | 18 | |
| Figuras simples | `figuras` | 19 | |
| Relatório final | `relatorio` | 20 | exige pandoc p/ renderizar |

Os parâmetros numéricos (nº de tópicos, iterações, limite de enriquecimento etc.)
ficam no bloco `CFG`, logo abaixo do `EXEC`.

```bash
# rodar o script (respeita o painel EXEC)
Rscript 01_scripts/00_pipeline_revisao_sistematica.R

# alguns parâmetros aceitam atalho por linha de comando
Rscript 01_scripts/00_pipeline_revisao_sistematica.R --teste           # lotes com 300 registros
Rscript 01_scripts/00_pipeline_revisao_sistematica.R --n_topics=10 --iterations=800
Rscript 01_scripts/00_pipeline_revisao_sistematica.R --limite=500      # enriquecimento
Rscript 01_scripts/00_pipeline_revisao_sistematica.R --forcar          # refazer lotes de tópicos
```

---

## Passo 1 (opcional, recomendado) — Recuperar resumos ausentes

`EXEC$enriquecer_abstracts = TRUE` (seção 8). Usa o **PubMed** por DOI, em blocos
retomáveis. ~70% dos registros (sobretudo Scopus) estão sem resumo.

```bash
Rscript 01_scripts/00_pipeline_revisao_sistematica.R --limite=500
# repetir aumentando o limite; --limite=0 processa todos (longo)
```

Saída: `02_dados/processados/registros_deduplicados_enriquecidos.csv`
(a partir daí, a seção 9 usa essa versão automaticamente).

---

## Passo 2 — Preparar os lotes do modelo de tópicos

`EXEC$topicos_preparar = TRUE` (seção 9). O LDA é ajustado **offline, por lotes**
(base × ano), e cada lote é salvo já com o modelo pronto — assim o app abre na hora.
É retomável (pula lotes já feitos, salvo `--forcar`).

```bash
Rscript 01_scripts/00_pipeline_revisao_sistematica.R
```

Saídas:
- `02_dados/processados/topicos/lote_XX.rds`
- `02_dados/processados/topicos/lotes_indice.csv`
- `03_resultados/logs/pipeline.log`

---

## Passo 3 — Triar os lotes no RStudio (app interativo)

A seção 10 usa `revtools::screen_topics()`, que **não roda no terminal**.
Abra o **RStudio**, abra o projeto `revisao_sistematica.Rproj` e:

1. Deixe `EXEC$topicos_app = TRUE` (e `setup = TRUE`).
2. Rode o script. Ele abrirá os lotes pendentes em sequência.
3. **Dentro do app:** clique num **tópico** (barra) ou num **ponto** (artigo) e use
   **“Select”** (incluir) / **“Exclude”** (excluir); clique num ponto para ler o
   resumo. Ao terminar o lote, clique em **“Exit”** — o script salva sozinho.

Comandos úteis no console do RStudio (após rodar o script):

```r
status_lotes()        # lotes, tamanho e estado (triado/pendente)
triar_lote("lote_01") # abre o app de um lote específico
triar_pendentes()     # abre todos os pendentes em sequência
consolidar_incluidos()# refaz a lista de incluídos da triagem assistida
```

Saídas:
- `02_dados/processados/topicos/decisoes/lote_XX.rds` e `.csv`
- `02_dados/processados/triagem_topicos_decisoes.csv` (mestre)
- `02_dados/processados/incluidos_titulo_resumo.rds` / `.csv`

> Se o RStudio travar, reabra e rode `triar_lote("lote_XX")`: ele **retoma** as
> decisões já salvas daquele lote.

---

## Passo 4 — Consolidar a triagem e calcular o kappa

`EXEC$consolidar_triagem = TRUE` (seção 11). Une as decisões dos **dois revisores**
(planilhas `triagem_titulo_abstrato_revisor{1,2}.csv`) e, se houver, da triagem
assistida por tópicos; calcula o **kappa de Cohen** e lista as discordâncias.

```bash
Rscript 01_scripts/00_pipeline_revisao_sistematica.R
```

Saídas:
- `02_dados/processados/triagem_consenso_titulo_resumo.csv`
- `02_dados/processados/discordancias_titulo_resumo.csv` (resolver manualmente)
- `02_dados/processados/incluidos_titulo_resumo.rds` / `.csv`
- `03_resultados/tabelas/kappa_titulo_resumo.csv` (kappa + IC95% + interpretação)
- `03_resultados/tabelas/acordo_titulo_resumo.csv`
- `03_resultados/tabelas/prisma_contagens.csv` (atualizado)

Enquanto houver **pendentes** ou **discordâncias**, resolva e rode de novo.

---

## Passo 5 — Triagem de texto completo

`EXEC$texto_completo = TRUE` (seção 12).

```bash
# 1ª execução: cria os templates
Rscript 01_scripts/00_pipeline_revisao_sistematica.R

# preencha 02_dados/processados/triagem_texto_completo_revisor{1,2}.csv
#   decisao = incluir/excluir ; motivo_exclusao = um dos motivos listados
#   (para recriar os templates: CFG$forcar_texto_completo <- TRUE)

# 2ª execução: consolida
Rscript 01_scripts/00_pipeline_revisao_sistematica.R
```

Saídas:
- `02_dados/processados/triagem_texto_completo_consenso.csv`
- `02_dados/processados/incluidos_texto_completo.rds` / `.csv`
- `03_resultados/tabelas/kappa_texto_completo.csv`
- `03_resultados/tabelas/motivos_exclusao_texto_completo.csv`
- `prisma_contagens.csv` atualizado

---

## Passo 6 — Diagrama PRISMA

`EXEC$prisma = TRUE` (seção 18). Regera o diagrama com os números reais.

```bash
Rscript 01_scripts/00_pipeline_revisao_sistematica.R
```

Saída: `03_resultados/figuras/prisma_flow_diagram.png`.

---

## Resumo dos comandos (ordem recomendada)

```bash
export PATH="/c/Program Files/R/R-4.6.1/bin:$PATH"
cd "C:/Users/oorie/OneDrive/Documentos/TRABALHOS/DLNM/03_revisão_impactos_à_saúde"
touch .here

# 1) (opcional) enriquecer resumos  -> EXEC$enriquecer_abstracts = TRUE
Rscript 01_scripts/00_pipeline_revisao_sistematica.R --limite=500
# 2) preparar lotes                -> EXEC$topicos_preparar = TRUE
Rscript 01_scripts/00_pipeline_revisao_sistematica.R
# 3) triar no RStudio              -> EXEC$topicos_app = TRUE
#      (abra revisao_sistematica.Rproj e rode o script)
# 4) consolidar + kappa            -> EXEC$consolidar_triagem = TRUE
Rscript 01_scripts/00_pipeline_revisao_sistematica.R
# 5) texto completo                -> EXEC$texto_completo = TRUE
Rscript 01_scripts/00_pipeline_revisao_sistematica.R
# 6) diagrama PRISMA               -> EXEC$prisma = TRUE
Rscript 01_scripts/00_pipeline_revisao_sistematica.R
```

## Se algo der errado

- **“Índice de lotes ausente”** → rode a seção 9 (`topicos_preparar = TRUE`).
- **App não abre no terminal** → é esperado; use o RStudio (seção 10).
- **R 4.6.1 fecha/segfault** em algum `print()` → evite imprimir objetos grandes
  (limitação conhecida do ambiente); o log registra o erro e o pipeline continua.
- **Muitos “sem_pmid”** no enriquecimento → normal para artigos não indexados no
  PubMed; siga com a triagem por título.
- **Quer rodar só uma seção?** Selecione as linhas da seção no RStudio e execute
  (Ctrl+Enter), garantindo que a **seção 1** (setup) já tenha rodado.
