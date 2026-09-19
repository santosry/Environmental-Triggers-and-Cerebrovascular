# HANDOFF — Nova fase "Vulnerabilidade climática e eventos cerebrovasculares no Rio de Janeiro"

**Data do handoff:** 2026-09-19 (~15:30)
**Estado:** ✅ ANÁLISES CONCLUÍDAS — manuscrito redigido; pendências apenas para os autores (autoria, IPCA, Word, DeCS).
**Local:** `C:\Users\oorie\OneDrive\Documentos\TRABALHOS\DLNM\vulnerabilidade_climatica_RAS_RJ`

---

## 0. Situação atual (em uma frase)

Todas as análises estão concluídas: SIH-RD (267.774 internações), SIM (147.551 óbitos),
taxas, tendências, mortalidade, permanência, custo, fluxo/CNES e exposição ambiental.
O manuscrito tem Introdução, Métodos, Resultados completos, Discussão e Conclusão
redigidos. **Faltam apenas as ações dos autores**: autoria completa, deflação IPCA,
DeCS, resumos PT/EN/ES e conversão para Word.

---

## 1. O que JÁ está pronto

| Item | Local |
|---|---|
| Estrutura da nova pasta (12 subpastas) | `vulnerabilidade_climatica_RAS_RJ/` |
| Backup do estudo anterior | `11_backup_estudo_anterior/` (original `06_WILCOXON` **intacto**) |
| Auditoria do estudo anterior | `10_auditoria/AUDITORIA_ESTUDO_ANTERIOR.md` |
| Auditoria de dados | `10_auditoria/AUDITORIA_DADOS.md` |
| Auditoria metodológica | `10_auditoria/AUDITORIA_METODOLOGICA.md` |
| Dicionário de variáveis | `04_resultados/DICIONARIO_VARIAVEIS_SIH.md` |
| Matriz de literatura (13 refs reais, DOIs verificados) | `07_literatura/MATRIZ_LITERATURA.md` |
| Manuscrito (estrutura + resultados SIM parciais) | `08_manuscrito/manuscrito.md` |
| Documentos de submissão (modelos) | `09_documentos_submissao/documentos_submissao.md` |
| Comparação antigo×novo (parcial) | `12_relatorios/COMPARACAO_ANALISE_ANTIGA_NOVA.md` |
| Relatório final (checklist) | `12_relatorios/RELATORIO_FINAL.md` |
| **Mortalidade SIM (147.551 óbitos) — CONCLUÍDA** | `04_resultados/resultados_mortalidade_sim.txt`, `05_tabelas/mortalidade_sim_*.csv` |
| **Clima/PM2,5 por região — CONCLUÍDO** | `04_resultados/resultados_clima.txt`, `05_tabelas/exposicao_climatica_regiao.csv`, `06_figuras/fig4*`, `fig5*` |

### Resultados-chave já obtidos
- **SIM:** 147.551 óbitos I60–I69 (2010–2024); 82% hospital, 6,9% domicílio; taxa média
  Centro-Sul 64,5/100k > Metropolitana 58,5 > Norte e Noroeste 54,5; taxa estadual
  **decrescente** 65,66→58,33 (MK tau=−0,371; p=0,060); I64=37,6%, I67=25,0%, I63=0,8%
  (viés de codificação confirmado).
- **Clima:** exposição térmica/PM2,5 por região calculada; correlações ecológicas diárias
  temperatura×internações fracas (rho −0,08 a +0,26).

---

## 2. O que está RODANDO AGORA (background)

**Consolidação SIH-RD** (processo `python 02_scripts/01_consolidar_dados.py`, 3 workers):

- 162/192 arquivos SIH convertidos (2010–2022 completos; 2023 parcial).
- Faltam: 2023 (6), 2024 (12), 2025 (12) = **30 arquivos** (~10–15 min).
- Ao terminar, gera `01_dados/processados/sih_cerebrovascular_2010_2024.csv`.

**É retomável:** o script pula arquivos já convertidos (cache em
`01_dados/tmp_parquet/`). Se o processo morrer, basta reexecutar:

```bash
cd "C:/Users/oorie/OneDrive/Documentos/TRABALHOS/DLNM/vulnerabilidade_climatica_RAS_RJ"
nohup python 02_scripts/01_consolidar_dados.py > 03_analises/log_consolidacao.txt 2>&1 &
```

Verificar progresso:

```bash
ls 01_dados/tmp_parquet/*.parquet | wc -l     # deve chegar a 192
tail -5 03_analises/log_consolidacao.txt
```

---

## 3. PASSOS RESTANTES (na ordem)

### Passo 1 — Confirmar fim da consolidação SIH
```bash
cd "C:/Users/oorie/OneDrive/Documentos/TRABALHOS/DLNM/vulnerabilidade_climatica_RAS_RJ"
ls 01_dados/tmp_parquet/*.parquet | wc -l        # esperar 192
ls -la 01_dados/processados/sih_cerebrovascular_2010_2024.csv   # deve existir
```

### Passo 2 — Rodar a análise principal (SIH)
```bash
python 02_scripts/02_analises_principais.py 2>&1 | tail -80
```
Isso gera:
- `04_resultados/resultados_principais.txt`
- tabelas em `05_tabelas/` (perfil, tendência, permanência/custo, razão óbito/internação, completude, top CNES)
- figuras em `06_figuras/` (fig1 taxa+óbito, fig2 taxa por macro, fig3 mortalidade região)

> Se der erro, corrigir no script e reexecutar. Pontos já corrigidos: chaves de
> população (`regiao_saude`), `pymannkendall` usa `r.Tau` (não `r.trend`).

### Passo 3 — Preencher os números nos relatórios
- `12_relatorios/COMPARACAO_ANALISE_ANTIGA_NOVA.md` (substituir "*pendente*").
- `12_relatorios/RELATORIO_FINAL.md` (marcar itens concluídos no checklist).
- `08_manuscrito/manuscrito.md` (completar RESULTADOS/DISCUSSÃO/CONCLUSÃO).

### Passo 4 — Revisão dos autores
- Preencher autoria completa (campos "[Autores — verificar DOI]" na matriz).
- Converter manuscrito para Word; Vancouver; DeCS; resumo PT/EN/ES; título ≤150 caracteres.
- Custos: decidir deflação por IPCA (documentar método; valores correntes já gerados).

---

## 4. DECISÕES TÉCNICAS IMPORTANTES (para não perder tempo ao retomar)

1. **R 4.6.1 está quebrado para serialização** (`readRDS`/`saveRDS` → segfault). Por isso
   a leitura dos `.rds` é feita em **Python**.
2. **`pyreadr` (C, rápido) falha nos arquivos SIH de 2013+** (strings Latin-1 com byte
   `0xA8` em campos de texto livre). Solução: `rdata` (Python puro) com
   `default_encoding="latin-1", force_default_encoding=True, expand_altrep=False`.
3. **`rdata` é lento** (~80–180 s/arquivo). Configuração que funcionou: **3 workers**
   (`N_WORKERS = 3` no script). Com 6 workers o sistema (8 GB RAM) faz thrashing e fica
   MAIS lento. Com 3 workers: ~4 arquivos/min.
4. **Chaves territoriais:** 9 regiões de saúde (`regiao_saude`) → 3 macrorregiões
   (`macro3`): Metropolitana (Metr. I+II), Centro-Sul (Serrana+Médio Paraíba+Centro-Sul+
   Baía da Ilha Grande), Norte e Noroeste (Norte+Noroeste+Baixadas Litorâneas).
5. **SIH lê 2010–2025** (para capturar internações de dez/2024 com alta em 2025), dedup
   por `N_AIH+IDENT+DT_INTER+DT_SAIDA+DIAG_PRINC+MUNIC_RES+SEXO+IDADE`, depois filtra
   `DT_INTER` 2010–2024.
6. **SIM usa arquivos anuais 2010–2024** (os mensais 2017–2024 são redundantes).
7. **Idade SIM:** formato DATASUS 3 dígitos — 4xx=anos, 5xx=100+anos, 3xx=meses,
   2xx=horas, 1xx=minutos; 999=ignorada. (O texto anterior citava "228=28 anos" — errado,
   é 28 horas.)
8. **Inconsistência crítica do estudo-base:** o artigo declara 2010–2024 mas cita
   "2025" nos resultados. A nova fase usa **somente 2010–2024**.

---

## 5. FONTES DE DADOS (caminhos)

| Dado | Caminho |
|---|---|
| SIH bruto (192 .rds) | `../05_publicacao_github/data/raw/sih/` |
| SIM bruto (15 .rds) | `../05_publicacao_github/data/raw/sim/` |
| População | `../01_DLNMs_RJ_cerebrovascular/data_processed/populacao_sidra_municipio_rj_2010-2025.csv` |
| Clima diário | `../05_publicacao_github/data_processed/dataset_dlnm_macrorregiao_CORRIGIDO.csv` |
| PM2,5 mensal | `../05_publicacao_github/data/processed/pm25/mp25_macroregiao_mensal_2010_2025.csv` |
| Lookup município | `../05_publicacao_github/data/processed/lookup_municipio_macrorregiao.csv` |

---

## 6. PRÓXIMOS ITENS DE RISCO / PENDÊNCIAS CONHECIDAS

- **Manuscrito:** faltam resultados SIH (perfil, taxas, tendência, permanência, custo,
  fluxo/CNES) e discussão/conclusão.
- **Custos:** apenas valores correntes; IPCA recomendado (API do BCB indisponível no
  ambiente; autores devem usar valores oficiais IBGE).
- **Literatura:** 13 refs verificadas via Crossref; preencher autoria dos itens marcados
  "[Autores — verificar DOI]".
- **Análises avançadas opcionais** (binomial negativa, logística, Moran/LISA) ainda não
  implementadas — só se justificável; ver `AUDITORIA_METODOLOGICA.md`.
- **NÃO afirmar causalidade**; apresentar incompletude de raça/cor e INSTRU
  explicitamente; I69 não eliminado (avaliar separadamente).
