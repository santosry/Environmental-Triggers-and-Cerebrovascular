# HANDOFF — Revisão sistemática "Determinantes ambientais das DCV (CID-10 I60–I69)"

**Data do handoff:** 26/09/2026 (fim do dia)
**Pasta:** `C:\Users\oorie\OneDrive\Documentos\TRABALHOS\DLNM\03_revisão_impactos_à_saúde`
**Estado:** ✅ Buscas concluídas (PubMed + Scopus + SciELO), deduplicação e documentação
prontas; figuras simples geradas. ✅ **Todo o pipeline foi consolidado em um único
script em 27/09/2026** (`01_scripts/00_pipeline_revisao_sistematica.R`, 20 seções) e
validado — **falta apenas executar a triagem em lotes** (passo a passo em
`00_docs/como_rodar_triagem.md`).

---

## 0. Situação em uma frase

Temos 19.027 registros identificados → **14.978 únicos** prontos para triagem, com
planilhas e documentação; falta implementar/rodar a **triagem por título e resumo**
(`revtools::screen_topics`), que precisa de estratégia em **lotes** (o modelo de tópicos
no conjunto completo estourou o tempo — ver §5).

---

## 1. Números atuais (reais)

| Etapa | N |
|---|---|
| PubMed/MEDLINE | 5.093 |
| Scopus | 13.908 |
| SciELO | 26 (69 no total; 26 no período 2020–2026) |
| **Identificados** | **19.027** |
| Após filtro 2020–2026 | 18.483 |
| Duplicatas removidas (DOI + título normalizado) | 3.505 |
| **Após deduplicação (triagem)** | **14.978** |

**Cobertura de resumos (importante):** dos 14.978,
- PubMed: 4.445 com resumo (93 sem);
- **Scopus: 10.422 sem resumo** (a extração do Scopus não trouxe abstracts);
- SciELO: 18 sem resumo.
→ ~70% dos registros têm **apenas título**; isso enfraquece o modelo de tópicos e exige
triagem manual cuidadosa.

---

## 2. O que já está pronto

### Script único (`01_scripts/00_pipeline_revisao_sistematica.R`)

Todo o pipeline está consolidado em **um único script** (20 seções comentadas, com
painel de controle `EXEC`). Ele reúne, na ordem, o que antes eram os 21 scripts
individuais (`00_setup.R` … `16_enriquecer_abstracts.R`); estes foram removidos.

| Seção | Etapa | Status |
|---|---|---|
| 1 | ambiente, pastas, sessão, kappa, PRISMA | ✅ |
| 2 | termos de busca (915 termos; 482 keywords) | ✅ |
| 3 | busca PubMed | ✅ 5.093 |
| 4 | busca Scopus (API key) | ✅ 13.908 |
| 5 | busca SciELO por **web scraping** (Chrome headless + processx) | ✅ 26 |
| 6 | deduplicação + planilhas de triagem | ✅ |
| 7 | bibliometria | ✅ |
| 8 | enriquecimento de resumos (PubMed por DOI) | ✅ testado |
| 9 | preparação dos lotes do LDA (offline) | ✅ testado |
| 10 | app `screen_topics` (RStudio) | ✅ testado |
| 11 | consenso + kappa da fase 1 | ✅ testado |
| 12 | triagem de texto completo | ✅ testado |
| 13 | template + `escalc()` | ✅ (demonstração) |
| 14 | ROBINS-I/NOS/OHAT + robvis | ✅ (demonstração) |
| 15 | meta-análise REML + viés | ✅ (demonstração) |
| 16 | forest plots (PNG) | ✅ |
| 17 | subgrupos/metarregressão/sensibilidade | ✅ |
| 18 | diagrama PRISMA 2020 (PNG) | ✅ |
| 19 | figuras simples (PNG 300 dpi) | ✅ |
| 20 | relatório R Markdown | pronto (render exige pandoc) |

### Documentos (`00_docs/`, 9)
protocolo_PROSPERO, prisma_checklist (PRISMA-P), prisma_2020_checklist (27 itens),
prisma_2020_conformidade, prisma_flow_diagram, criterios_inclusao_exclusao,
dicionario_dados, estrategia_busca, relatorio_final.

### Dados
- `02_dados/brutos/`: `pubmed_records.csv`, `scopus_records.csv`, `scielo_records.csv`,
  queries e contagens.
- `02_dados/processados/`:
  - **`registros_deduplicados.csv`** (14.978) — colunas:
    `title, abstract, doi, year, author, journal, base_origem, ano`.
  - `triagem_titulo_abstrato_revisor1.csv` e `..._revisor2.csv` (planilhas para 2 revisores;
    colunas de decisão/motivo em branco).
  - `duplicatas_removidas.csv`, `efeitos_calculados.rds` (demo), `metafor_modelo*.rds` (demo),
    `litsearchr_termos.csv`, `litsearchr_rede.png`.
- `02_dados/extraidos/planilha_extracao.csv` (template vazio — a preencher).

### Resultados
- `03_resultados/figuras/`: **9 PNG** (01–08 simples + `prisma_flow_diagram`) + `LEIA-ME.md`.
- `03_resultados/tabelas/`: `prisma_contagens.csv` e outras (meta-análise demo).
- `03_resultados/bibliometria/`: produção anual, Bradford, autores, sumário.
- `03_resultados/logs/`: logs de execução.

### Referências
- `04_referencias/referencias.bib`, `protocolo_referencias.md`, `session_info.txt`,
  `litsearchr_keywords.csv`, `api_keys.txt` (gitignored — contém a chave Scopus).

---

## 3. Decisões técnicas e peculiaridades do ambiente (IMPORTANTE ao retomar)

1. **R 4.6.1** em `C:/Program Files/R/R-4.6.1/bin/Rscript.exe` (**não está no PATH do
   bash**; usar caminho completo ou `export PATH=...`). R 4.6.1 tem segfaults conhecidos
   (ex.: `print()` de certos data.frames, `easyScieloPack`); evitar `print()` de objetos
   grandes.
2. **`here::here()`**: ancorado pelo arquivo vazio **`.here`** na raiz do projeto. Se o
   `.here` desaparecer (OneDrive), recriar (`touch .here`) — senão os caminhos apontam
   para a raiz do repositório DLNM.
3. **SciELO**: `search.scielo.org` tem bot-shield (Bunny). Resolvido com **Chrome headless**
   (`--dump-dom`) chamado via **`processx::run()`** (o `system()` do Windows quebrava por
   causa do `cmd.exe`). Paginação do SciELO é irregular → incrementar `from` pelo nº real
   de itens retornados. O perfil temporário `.chrome_scielo` é criado/removido em
   `02_dados/processados/`.
4. **Scopus**: API funcionou com a chave em `04_referencias/api_keys.txt`
   (`SCOPUS_API_KEY=...`). Limite de 5.000/consulta → o script particiona por ano.
   **A extração não trouxe abstracts.**
5. **Bases do projeto: somente PubMed, Scopus e SciELO.** (Redalyc/LILACS/Embase/WoS foram
   removidos do código e dos documentos.)
6. **Deduplicação fuzzy do revtools é O(n²)** → omitida para n>5.000; usados DOI exato +
   título normalizado. Pode ser rodada em subconjuntos.
7. **`PRISMA_save()`/pandoc**: sem pandoc, o diagrama é salvo via navegador headless.
   `rmarkdown::render()` também exige pandoc (não instalado).
8. **revtools — assinaturas reais** (verificadas):
   - `make_dtm(x, stop_words, min_freq = 0.01, max_freq = 0.85, bigram_check = TRUE, ...)`
     → **não existe** argumento `remove_words` aqui (é `stop_words`).
   - `run_topic_model(dtm, type = "lda", n_topics = 5, iterations = 2000)`
     → retorna objeto `LDA_Gibbs` (pacote `topicmodels`), **não** um data.frame com tópicos.
   - `screen_topics(x = NULL, remove_words = NULL, max_file_size)` → **`max_file_size` é
     obrigatório**; abre app Shiny (interativo; não roda no terminal headless).
9. **Meta-análise**: as seções 13–17 do script único já rodam, mas com **dados de
   demonstração** (6 estudos) até a extração real. `08_forest_plot_simples` (seção 19)
   usa esses dados demo.

---

## 4. PRÓXIMO PASSO (retomar por aqui)

### Triagem por título/resumo — no script único (seções 8–12)

> As etapas abaixo estão no script único, ligadas pelo painel `EXEC`. Guia de
> execução: `00_docs/como_rodar_triagem.md`.
>
> | Seção | Função |
> |---|---|
> | 8 (`enriquecer_abstracts`) | recupera resumos ausentes via PubMed (por DOI); incremental |
> | 9 (`topicos_preparar`) | prepara os lotes do LDA **offline** (por base × ano); retomável |
> | 10 (`topicos_app`) | abre o app `screen_topics` por lote (RStudio) e salva decisões |
> | 11 (`consolidar_triagem`) | consenso dos 2 revisores + kappa de Cohen |
> | 12 (`texto_completo`) | templates/kappa/motivos de exclusão (fase 2) |
> | 1 (setup) | funções comuns (kappa, normalização, PRISMA) |

### Requisitos originais (atendidos)

Requisitos já definidos pelo usuário:
- Usar `revtools::screen_topics()`; documentar que **não substitui** a triagem manual,
  apenas agrupa registros similares (LDA) para acelerar.
- `remove_words` = "study","results","conclusion","background","objective","methods",
  "conclusions","method","aim","aims" (stopwords de seções).
- `max_file_size = 100`.
- Fundamentação: Westgate & Lindenmayer 2017 (doi:10.1111/cobi.12863); Westgate 2019
  (doi:10.1002/jrsm.1374); Cochrane Handbook cap. 4; PRISMA 2020 (doi:10.1136/bmj.n71).
- Saídas: `02_dados/processados/incluidos_titulo_resumo.rds`,
  `03_resultados/logs/pipeline.log`,
  `00_docs/triagem_titulo_resumo.md`; atualizar `sumario_execucao.md` e `README.md`.

### ⚠️ Estratégia em LOTES (implementada na seção 9 do script único)

O modelo no conjunto completo (14.978 registros) não terminou em ~25 min. A solução
implementada: lotes por **base × ano** (PubMed e Scopus), lotes pequenos agrupados
(SciELO), DTM `min_freq = 0.02`, `max_freq = 0.90`, **sem bigramas** e LDA com
`n_topics` adaptativo. Cada lote é salvo como `screen_topics_progress` em `.rds`
(modelo pré-calculado) — o app abre instantaneamente. Teste com 227 registros:
~3 s por lote.

**Recomendações (a opção 1+3 foi implementada na seção 9; opção 4 continua válida):**
1. **Rodar em lotes** e chamar `screen_topics()` por lote: por base (PubMed 4.538;
   Scopus 10.422; SciELO 18) e/ou por ano. Para o Scopus, subdividir em lotes de
   ~1.000–2.000 (ex.: por ano). Salvar um `.rds` por lote.
2. **Pré-filtrar por palavras-chave** (título) para reduzir o conjunto antes do LDA
   (exigência mínima de exposição ambiental no título), triando manualmente o restante.
3. **Reduzir custo do LDA**: `n_topics = 10–15`, `iterations = 1000–2000`; construir o DTM
   sem bigramas (`bigram_check = FALSE`) e com `min_freq` maior para cortar o vocabulário.
4. Rodar `screen_topics()` **no RStudio** (não no terminal), salvando o progresso com o
   botão "Save Data" periodicamente (evita perda de trabalho em app longo).

### Após a triagem (sequência)
1. Consolidar decisões dos 2 revisores e calcular **kappa de Cohen** na seção 11
   (implementa `kappa_cohen()`; não requer `irr`/`psych`); resolver discordâncias
   (`discordancias_titulo_resumo.csv`).
2. Triagem de **texto completo** e registro dos motivos de exclusão na seção 12
   (alimenta o item 16b do PRISMA).
3. Preencher `02_dados/extraidos/planilha_extracao.csv` e rodar as seções 13→17
   (meta-análise real).
4. Preencher domínios ROBINS-I/OHAT e rodar a seção 14.
5. Atualizar o diagrama PRISMA (seção 18) com os números reais da triagem.
6. Ligar `EXEC$relatorio` (seção 20) para gerar/renderizar o R Markdown final e
   submeter o protocolo ao PROSPERO.

---

## 5. Como retomar (comandos)

```bash
# 1. ambiente R (Rscript não está no PATH do bash)
export PATH="/c/Program Files/R/R-4.6.1/bin:$PATH"
cd "C:/Users/oorie/OneDrive/Documentos/TRABALHOS/DLNM/03_revisão_impactos_à_saúde"

# 2. garantir âncora do here
touch .here

# 3. reexecutar o que for necessário: ative as seções no painel EXEC do script único
#    (ex.: dedup=seção 6, PRISMA=seção 18, figuras=seção 19)
Rscript 01_scripts/00_pipeline_revisao_sistematica.R

# 4. triagem por título/resumo (seções 8-12; ver 00_docs/como_rodar_triagem.md)
#    ligue EXEC$enriquecer_abstracts / topicos_preparar / consolidar_triagem / texto_completo
Rscript 01_scripts/00_pipeline_revisao_sistematica.R --limite=500
#    para o app (seção 10) use o RStudio: EXEC$topicos_app = TRUE e, no console,
#    status_lotes(); triar_lote("lote_01"); triar_pendentes()
```

**Antes de rodar:** fechar Chrome/Rscript residuais, se houver
(`ps -W | grep -iE "Rscript|chrome"` → `taskkill //PID <WINPID> //F`).

---

## 6. Pendências conhecidas / limitações

- **Scopus sem abstracts** (10.422) → considerar enriquecer via *Scopus Abstract Retrieval
  API* (mesma chave) apenas para os registros que passarem na triagem, ou aceitar triagem
  por título.
- **Triagem por um único revisor** (se não houver 2º revisor): documentar como limitação e
  planejar verificação por amostra; se houver 2 revisores, calcular kappa.
- **Modelo de tópicos lento** no conjunto completo (ver §4) → usar lotes.
- `write_search()` do litsearchr exige sessão interativa; a estratégia final já está
  versionada em `00_docs/estrategia_busca.md`.
- Meta-análise/risco de viés atuais são **demonstração** (dados fictícios de 6 estudos).
- `10_relatorio_final.Rmd` não renderiza sem pandoc.
- Chave Scopus em `04_referencias/api_keys.txt` (no `.gitignore` — **não comitar**).

---

## 7. Inventário rápido de caminhos

| Item | Caminho |
|---|---|
| Registros deduplicados | `02_dados/processados/registros_deduplicados.csv` |
| Planilhas de triagem | `02_dados/processados/triagem_titulo_abstrato_revisor{1,2}.csv` |
| Brutos por base | `02_dados/brutos/{pubmed,scopus,scielo}_records.csv` |
| Template de extração | `02_dados/extraidos/planilha_extracao.csv` |
| Figuras (PNG) | `03_resultados/figuras/` |
| Contagens PRISMA | `03_resultados/tabelas/prisma_contagens.csv` |
| Referências | `04_referencias/referencias.bib` |
| Protocolo | `00_docs/protocolo_PROSPERO.md` |
| Estratégia de busca | `00_docs/estrategia_busca.md` |

**Tamanho da pasta:** ~64 MB. **Nenhum processo em execução** ao encerrar.
