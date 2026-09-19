# COMPARAÇÃO — ANÁLISE ANTIGA × NOVA

Comparação entre os resultados do estudo-base e os resultados reproduzidos/ampliados na
nova fase. Formato exigido: resultado anterior → resultado reproduzido → diferença →
possível causa → decisão metodológica.

> Os valores "reproduzidos" são preenchidos após a execução de
> `02_scripts/02_analises_principais.py`. Divergências são documentadas, nunca ocultadas.

---

## 1. Contagem de internações

| Campo | Resultado anterior | Resultado reproduzido | Diferença | Possível causa | Decisão |
|---|---|---|---|---|---|
| Internações I60–I69 (2010–2024) | 269.751 | **267.774** | −1.977 | Deduplicação e filtro correto DT_INTER 2010-2024 | Adotar a contagem reproduzida |

## 2. Período (inconsistência crítica)

| Item | Estudo-base | Auditoria |
|---|---|---|
| Período declarado | 2010–2024 | correto no título/método |
| Resultados citados | "123,38 em 2025", "14% em 2025", "232,56 em 2025", "158,31 em 2025" | **erro corrigido** — nova análise restrita a 2010–2024 |
| Decisão | — | ✅ Reanálise somente 2010–2024 — concluída |

## 3. Distribuição por subtipo CID-10

| Subtipo | Anterior | Reproduzido | Diferença | Causa | Decisão |
|---|---|---|---|---|---|
| I64 | 61,8% | **62,5%** | +0,7 pp | Período/deduplicação | Adotar |
| I69 | 15,9% | **15,0%** | −0,9 pp | Idem | **Manter I69; avaliar separadamente** |
| I63 | 9,2% | **6,3%** | −2,9 pp | Período 2010-2024 vs. anterior | Avaliar |
| I60–I62 | 7,1% | **13,1%** | +6,0 pp | Diferença metodológica / cobertura | Documentar |

## 4. Taxa estadual e tendência

| Item | Anterior | Reproduzido | Diferença | Decisão |
|---|---|---|---|---|
| Taxa 2010 /100k | 98,87 | **94,76** | −4,11 | Denominadores atualizados; adotar novo |
| Taxa 2024 /100k | (citava 123,38 em 2025) | **125,97** | — | Comparação indevida (anos distintos) |
| Tendência | crescente; tau=0,62 p=0,002 | **crescente; tau=0,657 p=0,0008** | Confirmada | ✅ Reproduzida |

> **⚠️ Inversão relevante:** o SIM mostrou tendência *decrescente* (mortalidade declina, tau=−0,371), enquanto o SIH mostra taxa de *internação crescente* (tau=+0,657). A interpretação mais provável — melhora na detecção/acesso com queda na letalidade — precisa ser sustentada na discussão sem afirmar causalidade.

## 5. Mortalidade

| Item | Anterior | Reproduzido/ampliado | Decisão |
|---|---|---|---|
| Mortalidade hospitalar global (SIH) | 19,4% | **19,6%** | ✅ Reproduzida (dif. −0,2 pp) |
| Pico anual (SIH) | 22,0% em 2021 | **22,5% em 2021** | ✅ Reproduzida |
| Cochran-Armitage (prop. óbito/ano) | não reportado | p=0,9747 (sem tendência linear) | **Nova** — sem tendência na proporção de óbito |
| Mortalidade populacional (SIM) | **não analisada** | **147.551 óbitos** I60–I69 (2010–2024) | **Nova** |
| Taxa mortalidade/100k (SIM, média por região) | **não analisada** | Centro-Sul 68,8; Serrana 67,6; Médio Paraíba 66,0; Noroeste 65,2; Met. II 59,0; Met. I 58,4; Norte 56,9; Baixada 47,1; Baía I.G. 43,7 | **Nova** |
| Tendência mortalidade (SIM) | **não analisada** | taxa estadual 65,66 (2010) → 58,33 (2024); MK tau=−0,371 p=0,060 | **Nova** |
| Local de ocorrência (SIM) | **não analisada** | Hospital 82,0%; outro estab. saúde 10,2%; domicílio 6,9% | **Nova** |
| Razão óbito SIM / internação SIH | **não analisada** | Met. I 68,9%; Baixada 67,9%; Norte 55,5%; Met. II 50,5%; Serrana 31,0% (menor) | **Nova** — indica heterogeneidade expressiva |

## 6. Permanência e custo

| Item | Anterior | Reproduzido | Diferença | Decisão |
|---|---|---|---|---|
| Permanência (mediana/IIQ) | 6 (3–11) | **7 dias (IIQ 3–16)** | +1 dia | Período ampliado; I69 puxa para cima (mediana 30 dias) |
| Permanência I69 (sequelas) | não reportado | **mediana 30 dias** | — | **Nova** — documenta impacto de sequelas |
| Custo total (correntes) | não reportado | **R$ 535.221.745** | — | **Nova** |
| Custo mediano/internação | não reportado | **R$ 731,28** | — | **Nova** |
| Custo médio maior (região) | não reportado | Noroeste R$ 3.511,89 | — | **Nova** |
| Kruskal-Wallis permanência × região | não reportado | H=10.027 p<0,001 | — | **Nova** — diferenças regionais significativas |
| Kruskal-Wallis custo × região | não reportado | H=11.158 p<0,001 | — | **Nova** |

## 7. Perfil sociodemográfico

| Item | Anterior | Reproduzido | Diferença | Decisão |
|---|---|---|---|---|
| Total internações | 269.751 | **267.774** | −1.977 | Adotar reproduzido |
| Sexo masculino | 51,9% | **51,9%** | 0 | ✅ Reproduzido |
| Idade mediana (IIQ) | 68 (56–77) | **66 (57–76)** | −2 anos | Documentar; deduplicação/período |
| Raça/cor "Sem informação" | 25,5% | **25,4%** | −0,1 pp | ✅ Reproduzida |
| Escolaridade (INSTRU) | "100% incompleto" | **99,99% "Sem instrução"** (campo inválido) | — | ✅ Corrigido — excluir de inferência |
| Urgência (caráter internação) | não reportado | **84,0%** | — | **Nova** |
| 60-74 anos (faixa etária dominante) | não reportado | **40,4%** (108.044) | — | **Nova** |

## 8. Fluxo e concentração assistencial — Novos achados

| Item | Anterior | Reproduzido | Decisão |
|---|---|---|---|
| Internações fora do município | não analisado | **17,7%** | **Nova** |
| Polo dominante | não analisado | Rio de Janeiro (82.300 intern.) | **Nova** |
| Top 10 CNES | não analisado | **33,6% das internações** | **Nova** — concentração expressiva |
| Qui-quadrado óbito × subtipo CID | não reportado | chi2=8.149 p<0,001 | **Nova** |

## 9. Divergências de método corrigidas

| Divergência | Correção |
|---|---|
| Idade SIM ("228 = 28 anos") | 228 = 28 horas (2xx = horas) — corrigido |
| SIM ausente no estudo-base | ✅ Incorporado na nova fase |
| Fluxo residência→internação ausente | ✅ Incorporado (MUNIC_RES × MUNIC_MOV) |
| CNES ausente | ✅ Incorporado (concentração assistencial) |
| Clima ausente | ✅ Integrado (temperatura/umidade/PM2,5) |
| INSTRU mal interpretado | ✅ Documentado como dado inválido; excluído de inferência |
| TypeError pandas Int32 nullable | ✅ Corrigido com `.astype("float64")` em `01_consolidar_dados.py` |

---

**Conclusão da comparação:** A reanálise **confirma** a direção geral do estudo-base —
carga crescente de internações e heterogeneidade regional. Contudo, **corrige** o erro
de período (2025→2024), **corrige** a escolaridade (campo inválido), **corrige** a
conversão de idade do SIM, e **amplia substancialmente** o escopo: mortalidade
populacional (SIM), fluxos assistenciais, concentração por CNES, custos e exposição
ambiental. O achado mais relevante para a discussão sobre RAS é a **inversão de
tendência entre internação (crescente) e mortalidade (decrescente)**, sugerindo melhora
na detecção/acesso com declínio de letalidade — hipótese a ser apresentada sem
afirmação causal.
