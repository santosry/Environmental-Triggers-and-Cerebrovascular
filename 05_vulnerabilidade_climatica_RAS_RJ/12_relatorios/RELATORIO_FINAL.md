# RELATÓRIO FINAL — Nova fase

**Título de trabalho:** Vulnerabilidade climática e eventos cerebrovasculares no Rio de
Janeiro e suas implicações para a organização da Rede de Atenção à Saúde

**Período de estudo:** 2010-01-01 a 2024-12-31 (15 anos)
**Estado:** ✅ Análises concluídas — aguardando revisão pelos autores (autoria, IPCA, DeCS, conversão Word)
**Atualizado em:** 2026-09-19

---

## 1. O que foi reaproveitado

- Arquivos brutos do SIH-RD (192 mensais, 2010–2025) e SIM (15 anuais, 2010–2024)
  extraídos via pacote microdatasus e preservados no compêndio de pesquisa.
- Lookup município → região de saúde/macrorregião (92 municípios).
- Denominadores populacionais IBGE/SIDRA (tabela 6579 + Censo 2022), 2010–2025.
- Dados ambientais já processados (INMET temperatura/umidade diária por macrorregião;
  MonitorAr/VIGIAR PM2,5 mensal).
- Artigo-base (morbimortalidade cerebrovascular) como referência metodológica e de
  comparação.

## 2. O que foi refeito

- Contagem e deduplicação das internações I60–I69 (SIH) a partir do bruto.
- Perfil sociodemográfico (sexo, idade, raça/cor, escolaridade, caráter).
- Distribuição por subtipo CID-10 (I60–I69, sem eliminar I69).
- Taxas por 100.000 e tendência (Mann-Kendall; Cochran-Armitage).
- Mortalidade hospitalar, permanência e custo.
- Testes de diferenças regionais (Kruskal-Wallis/Dunn) e associações (qui-quadrado).

## 3. O que foi corrigido

| Correção | Detalhe |
|---|---|
| Período | Resultados do estudo-base citavam "2025" apesar do período 2010–2024 declarado → reanálise restrita a 2010–2024 |
| Escolaridade (INSTRU) | Não é "100% incompleta"; é ~99,6% com valor 0 (sem instrução/não informado) → documentado e excluído de inferência |
| Idade do SIM | Conversão correta (4xx=anos, 3xx=meses, 2xx=horas, 1xx=min; 999=ignorada); o texto anterior citava "228 = 28 anos" (incorreto) |
| Leitura de dados | R 4.6.1 com falha de segmentação em readRDS → leitura via Python (`rdata`, decodificação Latin-1) |
| Custos | Valores correntes mantidos; documentada a necessidade de deflação por IPCA para comparabilidade intertemporal |

## 4. O que foi acrescentado

- **SIM (mortalidade populacional)**: óbitos por causa básica I60–I69, taxa por 100.000,
  local de ocorrência, razão óbito/internação por região.
- **Fluxo residência→internação** (MUNIC_RES × MUNIC_MOV): identificação de polos
  assistenciais.
- **CNES**: concentração de internações por estabelecimento.
- **Exposição ambiental**: temperatura, umidade e PM2,5 por região, integradas à
  narrativa de vulnerabilidade.
- **Inventário longitudinal de variáveis** do SIH (esquema evolui de 87 a 114 colunas).
- **Literatura brasileira** (13 artigos, matriz bibliográfica).

## 5. Novas variáveis utilizadas

`MUNIC_MOV`, `CNES`, `NATUREZA`/`NAT_JUR`, `CAR_INT`, `RACA_COR`, `INSTRU`,
`DIAS_PERM`, `VAL_TOT`/`VAL_SH`/`VAL_SP`, `DIAG_SECUN`, `PROC_REA`, `UTI_MES_TO`,
`COMPLEX`, `FINANC`, e, no SIM, `LOCOCOR`, `CODMUNOCOR`, `RACACOR`, `ESC`, `LINHAA–D`.

## 6. Análises adicionadas

- Mortalidade populacional (SIM) e sua relação com a mortalidade hospitalar (SIH).
- Análise territorial de fluxos e concentração assistencial.
- Integração ambiental (temperatura/umidade/PM2,5).
- Avaliação de métodos adicionais (binomial negativa, logística, espacial), aplicados
  somente quando justificáveis.

## 7. Resultados que mudaram

| Item | Antes | Novo | Causa |
|---|---|---|---|
| N internações | 269.751 | 267.774 | Deduplicação + filtro período correto |
| Taxa 2010 /100k | 98,87 | 94,76 | Denominadores atualizados |
| Idade mediana | 68 (56–77) | 66 (57–76) | Idem |
| I63 % | 9,2% | 6,3% | Período 2010-2024 estrito |
| Permanência mediana | 6 dias (3–11) | 7 dias (3–16) | Inclusão de I69 e período ampliado |

## 8. Resultados que permaneceram

- Sexo masculino: 51,9% (idêntico).
- Mortalidade hospitalar global: 19,4% → 19,6% (confirmada).
- Pico de mortalidade hospitalar: 22,0% vs. 22,5% em 2021 (confirmado, diferença mínima).
- Raça/cor sem informação: 25,5% → 25,4% (confirmada).
- Predomínio de I64 (AVC NE): 61,8% → 62,5% (confirmado, viés de codificação).
- Tendência crescente de internações: tau=0,62 → tau=0,657 (confirmada e significativa, p=0,0008).
- Heterogeneidade regional de taxas, mortalidade e permanência: confirmada e aprofundada.

## 9. Limitações que permanecem

1. Desenho ecológico (sem inferência causal ou individual).
2. Falta de padronização etária direta nas taxas regionais.
3. Denominador populacional com interpolação em anos sem estimativa oficial.
4. I64 predominante (62,5%) e viés de codificação diagnóstica — no SIM, I64=37,6% e I67=25,0%.
5. Raça/cor com ~25,4% de ausência; escolaridade (INSTRU) inválida para inferência.
6. Custos em valores correntes (deflação por IPCA recomendada; API BCB indisponível).
7. PM2,5 com granularidade mensal derivada (não diária).
8. Baixo poder de testes espaciais com 9 unidades de análise.

## 10. Achados que sustentam a discussão sobre regionalização e RAS

- **Heterogeneidade de taxas de internação:** Médio Paraíba 284/100k (2024) vs. Met. I 87/100k — gradiente >3×.
- **Heterogeneidade de mortalidade (SIM):** Centro-Sul 68,8/100k vs. Baía da Ilha Grande 43,7/100k.
- **Razão óbito/internação:** Metropolitana I 68,9% vs. Serrana 31,0% — diferença de 2×, sugerindo fluxo de óbitos mais graves para o polo.
- **Fluxo residência→internação:** 17,7% internados fora do município; Rio de Janeiro absorve 82.300 internações (polo dominante).
- **Concentração assistencial:** top 10 CNES = 33,6% das internações.
- **Custo e permanência heterogêneos:** Kruskal-Wallis p<0,001 para ambos; Serrana com maior custo mediano (R$ 1.418,20/internação).
- **I69 (sequelas) com permanência de 30 dias** — impacto assistencial desproporcional.
- **Tendência crescente de internações (tau=+0,657, p=0,0008) com tendência decrescente de mortalidade (tau=−0,371, p=0,060)** — possível melhora de acesso e sobrevivência.

## 11. Achados que NÃO sustentam essa interpretação (limitações analíticas)

- Cochran-Armitage para proporção anual de óbito hospitalar: **p=0,9747** — sem tendência linear temporal na letalidade hospitalar. A tendência decrescente no SIM pode refletir mudança de codificação ou envelhecimento da pirâmide etária, não necessariamente melhora assistencial.
- Correlações ecológicas diárias temperatura×internações são **fracas** (rho −0,08 a +0,26) — não há associação robusta clima-DCV em análise bivariada simples; análise DLNM seria necessária para inferência mais precisa.
- Serrana e Noroeste mostram **tendência decrescente de internação** (tau<0), ao contrário do estado — possível envelhecimento relativo ou melhora de codificação, a investigar.
- Apenas 9 unidades de análise para testes espaciais — insuficiente para LISA/Moran robusto.

## 12. Critério de conclusão (checklist)

- [x] Pasta antiga preservada (`11_backup_estudo_anterior/`)
- [x] Nova pasta criada e organizada (12 subpastas)
- [x] Estudo anterior auditado (`10_auditoria/`)
- [x] ~~Análises anteriores refeitas (aguardando dados)~~ → **CONCLUÍDO**
- [x] ~~SIH-RD reprocessado (em andamento)~~ → **CONCLUÍDO** — 267.774 internações (192 arquivos)
- [x] SIM incorporado (147.551 óbitos, 15 arquivos anuais 2010–2024)
- [x] Variáveis inventariadas (`DICIONARIO_VARIAVEIS_SIH.md`)
- [x] ~~Variáveis sociodemográficas exploradas (aguardando dados)~~ → **CONCLUÍDO**
- [x] ~~CNES explorado (aguardando dados)~~ → **CONCLUÍDO** — top 10 = 33,6%
- [x] ~~Caráter da internação analisado (aguardando dados)~~ → **CONCLUÍDO** — 84% urgência
- [x] ~~Mortalidade analisada (aguardando dados)~~ → **CONCLUÍDO** — SIH 19,6% + SIM 147.551
- [x] ~~Permanência e custo analisados (aguardando dados)~~ → **CONCLUÍDO** — mediana 7d; R$ 535 M
- [x] ~~Regiões e macrorregiões analisadas (aguardando dados)~~ → **CONCLUÍDO**
- [x] ~~Fluxos residência/internação avaliados (aguardando dados)~~ → **CONCLUÍDO** — 17,7% fora
- [x] Variáveis ambientais integradas (temperatura/umidade/PM2,5)
- [x] ~~Resultados anteriores × novos comparados (aguardando dados)~~ → **CONCLUÍDO** (`COMPARACAO_ANALISE_ANTIGA_NOVA.md`)
- [x] Inconsistências corrigidas (período, escolaridade, idade SIM, dtype pandas)
- [x] Literatura brasileira revisada (13 artigos, ≤15)
- [ ] **Manuscrito: preencher RESULTADOS SIH + DISCUSSÃO + CONCLUSÃO** (próximo passo)
- [ ] Autoria completa (campos "[Autores — verificar DOI]" na matriz)
- [ ] Tabelas e figuras selecionadas (máx. 5; geradas em `06_figuras/`)
- [ ] Revisão científica pelos autores
- [ ] Custos deflacionados por IPCA (valores oficiais IBGE — autores devem aplicar)
- [ ] Conversão Word + Vancouver + DeCS + resumo PT/EN/ES
