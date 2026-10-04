# AUDITORIA DE REVISÃO CIENTÍFICA (LOCK) — FRENTE 02

**Data:** 3 de outubro de 2026
**Revisor:** revisão científica sênior (epidemiologia, saúde pública e doenças cerebrovasculares)
**Backup da versão original:** `BACKUP_LOCK_2026-10-03_1651/`

---

## 1. Arquivos analisados

| Arquivo | Papel |
|---|---|
| Documento principal do manuscrito (local, não versionado) | **Artigo original** |
| Documentos locais de submissão (não versionados) | Folha de rosto, carta de apresentação, declaração de ética/LGPD e termo de autoria |
| `README.md`, `LEIA-ME.md` | Documentação técnica |
| `07_literatura/MATRIZ_LITERATURA.md` | Matriz de referências |
| `12_relatorios/RELATORIO_EXECUTIVO_AVALIACAO.md`, `RELATORIO_FINAL.md`, `RELATORIO_EXECUTIVO_FINAL.md`, `COMPARACAO_ANALISE_ANTIGA_NOVA.md` | Relatórios |
| `04_resultados/DICIONARIO_VARIAVEIS_SIH.md` | Dicionário de variáveis |
| `10_auditoria/*.md` | Auditorias anteriores |

## 2. Volume

- **285 parágrafos** analisados no conjunto (61 no manuscrito principal).
- **25 parágrafos/segmentos modificados**, quase todos no manuscrito principal.
- Nenhuma alteração em números, efeitos, IC, p-valores ou resultados do estudo.

## 3. Principais problemas científicos encontrados

1. **Ambiguidade epidemiológica no resumo:** “295.673 internações e 147.611 óbitos” podia
   ser lida como se 147 mil tivessem morrido entre as 295 mil internações. Corrigido para
   distinguir **55.827 óbitos intra-hospitalares (SIH)** de **147.611 óbitos por causa
   básica (SIM)**, nos três idiomas.
2. **DCV tratado como sinônimo de AVC.** A coorte inclui I60–I69 e G45/G46, não apenas
   AVC. A Introdução passou a usar “doenças cerebrovasculares (DCV)” para a carga e o
   estudo, reservando “AVC” para a linha de cuidado priorizada no Plano.
3. **Causalidade indevida:** verbos como “produzir”, “tende a ampliar”, “depende de”,
   “confirma” e “revelou-se” foram substituídos por “pode estar associada”, “pode
   contribuir”, “é consistente com”, “está associado” e “é compatível com”.
4. **Excesso de certeza na codificação:** “não descreve a realidade clínica e reflete a
   qualidade do registro” → “não corresponde à distribuição esperada na prática clínica e
   é consistente com limitações de codificação diagnóstica”.
5. **Generalização temporal:** “séries nacionais recentes” para a referência 9 (dados até
   2015) → “análises nacionais anteriores”.
6. **Afirmação de capacidade não medida:** “capacidade tempo-dependente está concentrada”
   → “a concentração de internações e o fluxo observados sugerem oferta especializada
   concentrada”.
7. **Inventário diagnóstico G46:** “passou de 18 para 1.349 internações” podia sugerir
   mudança temporal; reformulado como comparação com uma lista parcial anterior de códigos.
8. **Transições e tópicos frasais:** inserção de conectivos (“Nesse sentido”, “Ademais”,
   “Além disso”, “Nesse contexto”, “Posto isso”, “Portanto”, “Quanto a…”).

## 4. Principais problemas de referências encontrados

1. **Referência 13 (Nilson et al.) usada para reabilitação/linha de cuidado pós-AVC** — não
   sustenta a afirmação. Trocada para **referência 8 (Souto et al., reabilitação após
   AVC)**. A referência 13 passou a apoiar o enunciado sobre custos no SUS.
2. **Referências 1 e 10 usadas para “desigualdades de oferta, acesso e organização em
   rede”** — reatribuídas: a **10** apoia a codificação diagnóstica e as **3 e 11**
   (regionalização e atenção especializada/transporte) apoiam oferta e acesso.
3. **Referências 6, 7 e 11 na Introdução** — sustentam o contexto geral de planejamento e
   acesso no SUS, mas **não** demonstram, isoladamente, a concentração do cuidado
   cerebrovascular no Rio de Janeiro. **Resolvido:** o enunciado passou a afirmar
   desigualdade geral de oferta no SUS (compatível com as três referências), e a
   especificidade do Rio de Janeiro ficou ancorada na prioridade pactuada na CIB
   (`<sup>14</sup>`, pág. 330) e nos achados do próprio estudo.

Nenhuma referência, DOI, autor ou número foi inventado; a lista de 17 itens foi preservada
e todas as referências são citadas no texto.

## 5. Principais alterações conceituais

- Separação explícita das duas fontes e dos dois desfechos (óbito hospitalar no SIH ×
  óbito por causa básica no SIM).
- Distinção rigorosa entre **DCV** (população do estudo) e **AVC** (subconjunto e linha de
  cuidado).
- Rebaixamento do grau de certeza das afirmações de mecanismo (acesso, fluxo,
  porta-agulha, qualidade assistencial) para o terreno da associação e da hipótese.
- Registro de que a padronização etária foi aplicada **como análise de sensibilidade**.
- Alinhamento dos relatórios correntes ao recorte SIM com G45/G46 (147.611; 65,68→58,38).

## 6. Pontos de parecerista: resolução robusta

| Ponto | Tratamento |
|---|---|
| **Codificação (I64 ≈ 56,6%)** | Declarada como limitação e verificada por **análise de sensibilidade que exclui a categoria I64** (ICC 16,53%; MOR 2,160), incorporada aos Resultados e às Limitações. A heterogeneidade hospitalar permanece. |
| **Padronização etária** | Aplicada como **sensibilidade** com a estrutura do Censo 2010; o padrão e a ordenação regional foram preservados. Declarada explicitamente nos Métodos e nas Limitações. |
| **UTI como marcador não causal** | OR reportado sem leitura causal; **decomposição de Mundlak** (intra-hospitalar e contextual); modelo sem UTI como sensibilidade (ICC 17,25%); ICC apresentado como **faixa** (14,78%–17,25%). |
| **Componente hospitalar residual (~¾)** | Declarado que variáveis de estrutura e processo (ensino, volume, habilitações) **não estavam disponíveis**, de modo que a natureza da variação residual não é identificável com dados administrativos. |
| **Fluxo como descrição ecológica** | Explicitado que a análise de fluxos é **descritiva** e não permite inferir barreiras individuais de acesso nem causalidade. |
| **Custo sensível ao deflator** | Custos apresentados em **valores correntes e deflacionados pelo IPCA**; declarado que a magnitude absoluta é sensível ao índice, permanecendo descritivo o padrão regional. |
| **Ausência de mapa** | Declarado que **não foi produzido mapa coroplético por ausência de malha territorial**; a análise territorial usou agregados regionais e matrizes de fluxo. |

## 7. Pendências resolvidas

1. **Referências 6, 7 e 11:** enunciado reformulado para não atribuir ao Rio de Janeiro
   uma concentração que essas referências não demonstram (ver item 4.3).
2. **Relatórios históricos:** `RELATORIO_FINAL.md` recebeu **nota de versão** informando
   que se refere à série **I60–I69 apenas** (147.551 óbitos; ISU 92,38%) e que os números
   correntes (147.611; 65,68→58,38; 92,39%) constam do manuscrito. Os relatórios
   executivos foram removidos.
3. **Rigor do manuscrito:** analisado parágrafo a parágrafo, com reforço de tópico frasal,
   conectivos, precisão terminológica e nível de certeza.

## 8. Verificação final

- Números coerentes entre resumo, resultados e conclusão
  (295.673; 55.827; 147.611; 14,95%; 11,69%; 25,7%; 16,9%; 31,3%; 65,68→58,38),
  recalculados com as **duas classes** (I60-I69 + G45/G46) em todas as análises (seção 10).
- Sem travessões; citações em `<sup>` sem espaço anterior; tabelas/figuras na ordem
  Tabela 1 → Figura 1 → Tabela 2 → Tabela 3 → Figura 2.
- Todas as 17 referências citadas.
- Resumos: PT 247, EN 246, ES 246 palavras.
- A ideia, o argumento e a intenção originais foram preservados.

## 9. Observação final

Todas as afirmações numéricas foram confrontadas com os resultados, as tabelas e os
scripts do próprio repositório do estudo. Não foi criada nenhuma evidência, referência ou
estimativa. Os pontos que dependiam de documentação externa ao repositório foram
reformulados para o nível de certeza compatível com a evidência disponível.

## 10. Duas classes de códigos em todas as análises (revisão de 2026-10-03)

Toda a análise passou a usar explicitamente as **duas classes de códigos** de doenças
cerebrovasculares, tanto para internações (SIH) quanto para óbitos (SIM): **I60–I69 e os
blocos G45/G46**. As análises principais (GLMM de letalidade, tabelas descritivas e
séries de mortalidade) já usavam a coorte completa; os pontos que ainda restringiam a
I60–I69 foram corrigidos e reexecutados: taxas de internação (`13`), custos (`15`),
padronização etária (`22`) e o mapa (`24`). Novo script `26_recalculo_duas_classes.R`
recalcula Tabela 1 (macrorregião), fluxo, concentração, custos e taxas com a coorte
completa.

| Indicador | Antes (só I60-I69) | Agora (I60-I69 + G45/G46) |
|---|---:|---:|
| Taxa de internação estadual, 2010 → 2024 | 94,76 → 125,97 | 112,46 → 136,79 |
| Tendência de Mann-Kendall (tau; p) | +0,657; 0,0008 | +0,448; 0,0228 |
| Faixa regional, 2024 | 87,1 a 284,1 | 90,6 a 319,5 |
| Fluxo intermunicipal | 17,7% | 16,9% |
| Dez maiores estabelecimentos | 33,6% | 31,3% |
| Custo total (corrente / deflacionado) | R$ 535 mi / R$ 790,6 mi | R$ 565,5 mi / R$ 836,9 mi |
| Tabela 1, Metropolitana (internações; óbito) | 164.761; 22,84% | 174.127; 22,25% |
| Tabela 1, Centro-Sul (internações; óbito) | 70.598; 13,35% | 83.127; 13,32% |
| Tabela 1, Norte e Noroeste (internações; óbito) | 32.415; 16,57% | 38.419; 15,63% |

Principais municípios (ambas as classes): Rio de Janeiro 82.017, São Gonçalo 21.470,
Petrópolis 16.266 e Duque de Caxias 15.781. A letalidade hospitalar permaneceu estável
(18,88%; pico de 21,7% em 2021; Cochran-Armitage p=0,5577). Como a Tabela 1 passa a
referir-se à coorte completa, ela foi substituída pelos valores das duas classes.

Além disso, o mapa coroplético das nove regiões de saúde foi produzido com a malha
municipal do `geobr` (IBGE/IPEA) dissolvida por região (`24_mapa_regioes_saude.R`), e a
Figura 1 passou a combinar a série temporal (painel A) e o mapa de 2024 (painel B). Os
rótulos das figuras do manuscrito (Figuras 1 e 2) foram ampliados para leitura em
tamanho final de publicação.

## 11. Reformulação da janela de estudo para 2014–2024 (2026-10-03)

O estudo foi integralmente reformulado para a janela de **2014 a 2024** (11 anos), em
dados e análises. Os recortes e a coorte foram refiltrados (`00_migrar_2014_2024.R`, com
`01` e `02` atualizados) e todo o pipeline foi reexecutado. As sub-janelas de robustez
passaram a ser 2014–2019 e 2020–2024. A estrutura etária de referência da padronização
permanece a do Censo 2010.

| Indicador | 2010–2024 | 2014–2024 |
|---|---:|---:|
| Internações (SIH) | 295.673 | 222.832 |
| Óbitos intra-hospitalares | 55.827 | 42.426 |
| Óbitos por causa básica (SIM) | 147.611 | 106.799 |
| Taxa de internação, início → fim | 94,76 → 125,97 | 105,90 → 136,79 |
| Mortalidade populacional, início → fim | 65,68 → 58,38 | 58,47 → 58,38 |
| ICC (MOR) | 14,95% (2,065) | 14,50% (2,039) |
| Fluxo intermunicipal | 17,7% | 18,4% |
| Dez maiores estabelecimentos | 33,6% | 34,2% |
| Custo (corrente / deflacionado) | R$ 535 mi / R$ 790,6 mi | R$ 440,4 mi / R$ 576,4 mi |

Auditorias na nova janela: 84 verificações gerais, 75 aprovadas, 8 informativas, 1
ressalva esperada (competência SIH ainda não publicada) e **nenhum erro**; 50 verificações
de consistência interna, nenhuma classificada como erro.

## 12. Camada de reprodutibilidade, portabilidade e auditabilidade (2026-10-03)

Foi adicionada a pasta `11_reprodutibilidade/`, com: execução instrumentada do pipeline e
benchmarks (`run_all.R`, `benchmarks_execucao.csv`); captura de versões de R e Python
(`versoes_ambiente.R`); teste de regressão por valores-síntese (`teste_regressao.R`, 13
indicadores, todos aprovados); manifesto de integridade SHA-256 de entradas, código e
saídas (`manifest_sha256.R`; 146 arquivos verificados, todos OK) e proveniência com o
commit do Git (`PROVENANCE.json`); além de `Dockerfile`, `requirements.txt`, `CITATION.cff`
e `.gitattributes` para portabilidade.
