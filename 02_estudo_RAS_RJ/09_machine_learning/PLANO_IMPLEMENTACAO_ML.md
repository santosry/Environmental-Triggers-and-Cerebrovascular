# Plano de implementação de machine learning

**Projeto:** predição de óbito intra-hospitalar por doenças cerebrovasculares no
Rio de Janeiro
**Base:** SIH-RD/SUS, 2014–2024, internações por I60–I69 e blocos G45/G46
**Unidade de análise:** internação
**Unidade de validação:** estabelecimento de saúde (CNES)
**Documento:** plano metodológico e operacional
**Status:** planejado — ainda não executado

> **Regra central:** este é um estudo de **predição**, não de inferência causal.
> O GLMM do estudo principal responde “quais fatores se associam ao óbito e
> quanto da variação é hospitalar”. O ML responde “quão bem conseguimos prever o
> óbito em pacientes e hospitais novos, com calibração e utilidade clínica
> aceitáveis”. As duas perguntas não devem ser misturadas no mesmo artigo.

---

## 1. Objetivo

Desenvolver, validar temporalmente e reportar modelos de machine learning para
predição de óbito intra-hospitalar em pacientes internados por DCV no SUS do Rio
de Janeiro, comparando-os com o modelo logístico multinível (GLMM) já construído.

### Objetivos específicos

1. Construir uma base analítica preditiva com variáveis disponíveis no momento
   da internação (cenário A) e, separadamente, com variáveis precoces de
   internação (cenário B).
2. Comparar modelos lineares regularizados, random forest e gradient boosting.
3. Avaliar discriminação, calibração, utilidade clínica e estabilidade temporal.
4. Comparar o melhor modelo de ML com o GLMM principal em termos de AUC,
   calibração e net benefit.
5. Identificar preditores e padrões, sem interpretação causal.
6. Produzir um model card, código reprodutível e relatório no padrão TRIPOD+AI.

### Perguntas secundárias

- O ML melhora a predição em relação ao GLMM?
- O ganho, se existir, é clinicamente relevante ou apenas estatístico?
- O desempenho se mantém em 2022–2024?
- O desempenho é semelhante entre regiões, sexos, faixas etárias e volumes
  hospitalares?
- Quais variáveis dominam a predição e quais são apenas proxies de codificação?

---

## 2. Princípios metodológicos

### 2.1. Predição ≠ explicação

- Nenhuma afirmação causal será feita a partir de importância de variáveis,
  SHAP, PDP ou coeficientes.
- O objetivo é estimar risco predito, não efeito de exposição.
- O GLMM continua sendo o modelo inferencial do projeto.

### 2.2. Prevenção de vazamento de informação

Vazamento é o maior risco deste estudo. Serão adotadas duas especificações
separadas:

| Cenário | Momento da predição | Variáveis permitidas |
|---|---|---|
| **A — admissão** | antes ou no momento da internação | idade, sexo, raça/cor, região/município de residência, caráter, CID principal, tipo de financiamento, complexidade, natureza jurídica, características históricas do hospital e da região |
| **B — precoce** | primeiras 24–48 h (se os dados permitirem) | cenário A + UTI, procedimentos, dias de UTI, exames/recursos registrados após admissão |

**Nunca usar no cenário A:**

- `DIAS_PERM` (ocorre depois);
- `VAL_TOT`, `VAL_UTI`, `VAL_SH`, `VAL_SP` (custo é consequência);
- `UTI_MES_TO`, `UTI_INT_TO` (uso de UTI é posterior);
- `PROC_REA`, `DIAR_ACOM` (procedimento/intensidade podem ser posteriores);
- `MORTE` ou qualquer variável derivada do desfecho;
- `DT_SAIDA` (data de saída);
- identificadores de desfecho ou de óbito.

**Sobre o CNES:** o identificador do hospital não entra como feature no modelo
principal. Ele é usado como **grupo de validação**. Codificar CNES como variável
faria o modelo memorizar hospitais e não generalizar para serviços novos. Em
sensibilidade, características do hospital podem entrar como variáveis
históricas, desde que calculadas apenas com anos anteriores.

### 2.3. Validação

- **Desenvolvimento:** 2014–2021.
- **Teste temporal:** 2022–2024, tocado uma única vez após o congelamento do
  modelo.
- **Validação cruzada interna:** 5 folds agrupados por CNES; repetir 5 vezes se
  o custo permitir.
- **Nunca** dividir internações aleatoriamente sem agrupar por hospital.
- **Nunca** usar o teste temporal para escolher hiperparâmetros, variáveis ou
  ponto de corte.
- **Validação externa:** não disponível nesta fase; será declarada como
  limitação. Trabalhos futuros podem aplicar o modelo a outros estados.

### 2.4. Registro completo

Todo experimento entra em `04_resultados/registro_experimentos.csv`, com:

- id do experimento;
- cenário A/B;
- algoritmo;
- variáveis;
- hiperparâmetros;
- folds;
- métricas de validação;
- métricas do teste temporal;
- calibração;
- status (convergiu, falhou, instável);
- observações.

Resultados nulos, modelos piores que o baseline e falhas de treinamento também
são resultados.

### 2.5. Congelamento do protocolo

Antes de olhar o teste temporal:

1. congelar variáveis;
2. congelar algoritmos e grades de hiperparâmetros;
3. congelar métrica primária e critérios de escolha;
4. versionar o protocolo;
5. só então avaliar 2022–2024.

---

## 3. Coorte e desfecho

### 3.1. População

- Internações com diagnóstico principal I60–I69 ou blocos G45/G46;
- residentes no Rio de Janeiro;
- `DT_INTER` entre 2014 e 2024;
- exclusão de registros com desfecho ausente e de duplicatas já tratadas na
  coorte principal.

**n esperado:** 222.832 internações; 42.426 óbitos (19,04%).

### 3.2. Desfecho primário

`obito_hospitalar` (0/1), derivado de `MORTE`.

### 3.3. Desfechos secundários exploratórios

| Desfecho | Definição | Observação |
|---|---|---|
| Permanência prolongada | `DIAS_PERM` ≥ p75 ou ≥ 30 dias | não usar como preditor do óbito |
| Custo elevado | `VAL_TOT` > p75, deflacionado | desfecho separado |
| Uso de UTI | `uti` ou `uti_marca` | cenário B; não usar no cenário A |
| Óbito + permanência prolongada | desfecho composto | apenas exploratório |

O artigo principal de ML será sobre **óbito intra-hospitalar**. Os desfechos
secundários podem compor um apêndice ou um terceiro artigo.

---

## 4. Variáveis candidatas

### 4.1. Cenário A — disponíveis na admissão

| Bloco | Variável | Transformação | Justificativa |
|---|---|---|---|
| Demografia | idade | spline natural, categorias e valor contínuo | principal preditor |
| Demografia | sexo | F/M | perfil |
| Demografia | raça/cor | categorias + indicador de ausência | equidade e codificação |
| Residência | região de saúde | 9 categorias | contexto |
| Residência | macrorregião | 3 categorias | sensibilidade |
| Residência | município | target encoding apenas dentro dos folds; ou região | evitar vazamento |
| Admissão | caráter (`car_int`) | eletiva/urgência/outros | gravidade de acesso |
| Diagnóstico | subtipo | 7 categorias | fenótipo |
| Diagnóstico | `cid3` | 12 grupos | sensibilidade |
| Diagnóstico | `cid4` | 4º dígito | apenas se suporte |
| Diagnóstico | `cid3` + `cid4` | categoria combinada | avaliar |
| Hospital | natureza jurídica | categorias | oferta |
| Hospital | complexidade | categorias | oferta |
| Hospital | volume histórico | média de internações em anos anteriores | porte; calcular sem o ano corrente |
| Hospital | case-mix histórico | idade média, % hemorrágico, % urgência em anos anteriores | gravidade estrutural |
| Hospital | taxa histórica de UTI | proporção de UTI em anos anteriores | capacidade |
| Território | população e oferta regional | dados SIDRA/CNES/SIA de anos anteriores | contexto |
| Tempo | ano | linear/spline | tendência; avaliar drift |
| Tempo | mês/estação | categorias | sazonalidade |

> **Regra temporal:** toda variável hospitalar ou regional derivada de dados
> agregados deve usar apenas informação disponível **antes** do ano da
> internação. Para 2014, usar 2013 ou o primeiro ano disponível, declarando a
> limitação.

### 4.2. Cenário B — variáveis precoces

Somente se houver marcação temporal confiável:

- uso de UTI;
- procedimentos realizados;
- dias de UTI;
- recursos/exames registrados;
- complicações registradas.

Se não for possível separar o que ocorreu nas primeiras 24–48 h, o cenário B
não será implementado. Não se deve fingir um landmark temporal que o dado não
permite.

### 4.3. Variáveis excluídas

| Variável | Motivo |
|---|---|
| `INSTRU` | constante/inutilizável |
| `INFEHOSP` | 100% vazio |
| `CID_ASSO` | apenas `0000` |
| `NATUREZA` | valor único |
| `ESPEC` | sem dicionário oficial |
| `DIAS_PERM` | desfecho ou pós-admissão |
| `VAL_TOT` e derivados | desfecho/custo |
| `UTI_MES_TO`, `UTI_INT_TO` | pós-admissão no cenário A |
| `PROC_REA` | pós-admissão no cenário A; alta cardinalidade |
| `MORTE` e derivados | desfecho |
| CNES como feature | identificador de hospital; usar como grupo |

---

## 5. Preparação dos dados

### 5.1. Missing data

- Para árvores: permitir `NA` nativo quando o algoritmo suportar.
- Para modelos lineares: imputação por mediana/moda dentro do fold de treino,
  com indicador de ausência para variáveis com > 5% de missing.
- Nunca imputar usando o conjunto de teste.
- Raça/cor: manter categoria `Não informado` e indicador de ausência; comparar
  com análise de casos completos.
- Variáveis com > 50% de missing: excluir do modelo principal e registrar.

### 5.2. Categorias raras

- Agrupar níveis com < 1% ou < 50 observações em “Outros”.
- Não agrupar com base no desfecho.
- Para CID, manter I60–I69 e G45/G46; agrupar 4º dígito raro.

### 5.3. Escalonamento

- Modelos lineares: padronização das contínuas.
- Árvores: não é necessário.
- Usar o mesmo pipeline em treino e teste.

### 5.4. Desbalanceamento

- Prevalência esperada: ~19%.
- Não usar SMOTE no conjunto de teste.
- Preferir `class_weight`/`scale_pos_weight` ou ajuste de limiar por utilidade
  clínica.
- Otimizar métricas adequadas: AUC, AUPRC, Brier, calibração e net benefit.
- Acurácia não será métrica principal.

### 5.5. Data leakage checklist

Antes de cada treino, verificar:

- [ ] nenhuma variável de desfecho;
- [ ] nenhuma variável de pós-admissão no cenário A;
- [ ] nenhuma variável calculada com o ano corrente;
- [ ] nenhum target encoding feito fora do fold;
- [ ] nenhuma imputação feita com dados de teste;
- [ ] nenhum CNES como feature;
- [ ] nenhuma seleção de variável feita no teste temporal.

---

## 6. Modelos

### 6.1. Baseline

1. **GLMM principal** (script 05), usado como referência inferencial e
   preditiva.
2. **Regressão logística simples** com as variáveis do GLMM, sem efeito
   aleatório, para separar o ganho do ML do ganho do modelo multinível.
3. **Regressão logística com elastic net**, com tuning de `alpha` e `lambda`.

### 6.2. Modelos de ML

| Família | Implementação R | Papel |
|---|---|---|
| Regressão penalizada | `glmnet`/`tidymodels` | baseline regularizado interpretável |
| Random forest | `ranger` | não linearidade e interações |
| Gradient boosting | `xgboost` | desempenho e interações |
| Gradient boosting leve | `lightgbm` | alternativa e estabilidade |
| Histogram gradient boosting | `histogram`/`bonsai` | opcional |
| Stacking | `stacks` | apenas se houver ganho consistente |

### 6.3. Tuning

- Busca aleatória ou bayesiana, dentro do treino de desenvolvimento.
- Validação cruzada agrupada por CNES.
- Número de combinações pré-especificado.
- Registrar todas as combinações testadas e métricas.
- Critério de seleção: AUC média nos folds + calibração + simplicidade.
- Não escolher modelo apenas pelo melhor AUC.

### 6.4. Interpretabilidade

- Importância por permutação (global).
- SHAP global e local, com cautela.
- PDP/ALE para variáveis contínuas.
- Comparar importâncias com os OR do GLMM.
- Não interpretar importância como efeito causal.

---

## 7. Avaliação

### 7.1. Métricas primárias

- **AUC-ROC** com IC95% por bootstrap agrupado por hospital.
- **AUPRC** (prevalência ~19%).
- **Brier score**.
- **Calibração:** intercepto, inclinação, curva de calibração e
  calibration-in-the-large.
- **Net benefit:** curva de decisão em limiares clinicamente plausíveis
  (ex.: 5%, 10%, 15%, 20%, 30%).

### 7.2. Métricas secundárias

- Sensibilidade, especificidade, VPP, VPN em limiares selecionados.
- F1 e balanced accuracy.
- Número necessário para avaliar (NNE) em limiares.
- AUC por ano, região, sexo, faixa etária e volume hospitalar.

### 7.3. Comparação com GLMM

- AUC do ML vs AUC do GLMM (bootstrap pareado ou DeLong quando aplicável).
- Calibração do ML vs GLMM.
- Net benefit do ML vs GLMM.
- Diferença de Brier.
- Comparação no mesmo conjunto de teste temporal.
- Reportar também o desempenho do GLMM marginal e condicional.

### 7.4. Estabilidade e drift

- Performance por ano de teste (2022, 2023, 2024).
- Performance por região.
- Performance por volume hospitalar.
- Performance por presença de UTI.
- Teste de calibração ao longo do tempo.

### 7.5. Subgrupos e equidade

- Sexo.
- Faixa etária.
- Raça/cor (com cautela pela missing).
- Região de saúde.
- Natureza jurídica.
- Porte hospitalar.
- Comparar AUC, calibração e net benefit entre subgrupos; não usar apenas AUC.

### 7.6. O que não será feito

- Não será escolhido um ponto de corte “ótimo” sem justificativa clínica.
- Não será reportado apenas o melhor resultado.
- Não será usado o teste temporal para ajuste de hiperparâmetros.
- Não será feita inferência causal a partir de SHAP.

---

## 8. Estrutura de scripts

| Script | Função |
|---|---|
| `00_config.R` | caminhos, sementes, versões, funções comuns |
| `01_construir_base_ml.R` | coorte, variáveis, cenários A/B, dicionário |
| `02_auditar_leakage.R` | checagem automática de variáveis proibidas e temporais |
| `03_split_temporal.R` | desenvolvimento 2014–2021 e teste 2022–2024 |
| `04_baseline_glmm.R` | predições do GLMM e logística simples |
| `05_modelos_lineares.R` | elastic net e tuning |
| `06_modelos_arvores.R` | random forest, xgboost, lightgbm |
| `07_avaliacao.R` | AUC, AUPRC, Brier, calibração, DCA, subgrupos |
| `08_explicabilidade.R` | permutação, SHAP, PDP/ALE |
| `09_tabelas_figuras.R` | tabelas e figuras do artigo |
| `10_relatorio_model_card.R` | relatório e model card |
| `11_consolidar_registro.R` | registro único de experimentos |

### 8.1. Pastas

```
09_machine_learning/
├── 01_dados/
│   ├── base_ml_cenario_A.csv
│   ├── base_ml_cenario_B.csv
│   └── dicionario_ml.csv
├── 02_scripts/
├── 03_modelos/
├── 04_resultados/
│   ├── registro_experimentos.csv
│   ├── log_treinos.txt
│   └── resultados_ml.txt
├── 05_tabelas/
├── 06_figuras/
└── 07_relatorios/
```

Dados pesados e objetos de modelo não serão versionados. Tabelas, figuras,
scripts, logs e model card serão versionados.

---

## 9. Entregáveis

### 9.1. Tabelas

1. Características da coorte de desenvolvimento e teste.
2. Dicionário de variáveis e decisão de inclusão.
3. Desempenho dos modelos na validação cruzada.
4. Desempenho no teste temporal.
5. Calibração por modelo.
6. Comparação ML vs GLMM.
7. Desempenho por subgrupo.
8. Importância de variáveis.

### 9.2. Figuras

1. Fluxograma da coorte.
2. Curvas ROC no teste temporal.
3. Curvas de calibração.
4. Curvas de decisão (net benefit).
5. Performance por ano.
6. Importância por permutação/SHAP global.
7. Calibração por subgrupo.

### 9.3. Relatórios

- `07_relatorios/RELATORIO_ML.md`.
- `07_relatorios/MODEL_CARD.md`.
- `04_resultados/registro_experimentos.csv`.
- Checklist TRIPOD+AI preenchido.
- Avaliação PROBAST.

---

## 10. Critérios de sucesso

O artigo de ML será considerado bem-sucedido se:

1. o pipeline for reprodutível e livre de vazamento;
2. o desempenho for reportado com calibração e utilidade clínica, não só AUC;
3. a validação temporal for honesta;
4. o ML for comparado ao GLMM no mesmo teste;
5. os resultados negativos ou modestos forem reportados;
6. o model card e as limitações forem claros.

**Não é necessário** que o ML “ganhe” do GLMM. Um resultado do tipo “o ML não
melhora a predição ou a calibração de forma clinicamente relevante” é um achado
válido e publicável, desde que bem conduzido.

---

## 11. Cronograma sugerido

| Etapa | Duração | Produto |
|---|---|---|
| 1. Base ML e dicionário | 1–2 semanas | `base_ml_cenario_A.csv`, dicionário |
| 2. Auditoria de leakage | 2–3 dias | relatório de leakage |
| 3. Baseline GLMM/logística | 1 semana | predições e métricas |
| 4. Modelos lineares e árvores | 2–3 semanas | modelos e tuning |
| 5. Avaliação e calibração | 1–2 semanas | tabelas e figuras |
| 6. Explicabilidade | 1 semana | SHAP/PDP |
| 7. Validação temporal final | 2–3 dias | resultados congelados |
| 8. Relatório e model card | 1–2 semanas | manuscrito |
| 9. Revisão e submissão | 1–2 semanas | versão final |

---

## 12. Riscos e mitigação

| Risco | Mitigação |
|---|---|
| Vazamento de dados | checklist automático e revisão manual |
| Overfitting | CV agrupada, teste temporal, regularização |
| Memorização de hospital | CNES fora das features; validação agrupada |
| Drift temporal | teste 2022–2024 e performance por ano |
| Desbalanceamento | métricas adequadas, class weights, sem SMOTE no teste |
| Missing informativo | indicador de ausência e análise de sensibilidade |
| Multicolinearidade | remoção conceitual, VIF, importância estável |
| Interpretação causal indevida | linguagem preditiva e aviso explícito |
| Muitos experimentos | registro completo e FDR não usado como seleção de modelo |
| Custo computacional | começar por modelos simples; tuning limitado e registrado |
| Ausência de validação externa | declarar limitação e propor replicação |

---

## 13. Ética, dados e reprodutibilidade

- Dados secundários, públicos e anonimizados; Resolução CNS 510/2016 e LGPD.
- Nenhum identificador pessoal será usado.
- Código versionado, sementes explícitas, versões de pacotes registradas.
- Dados pesados e modelos não versionados; tabelas, logs e scripts versionados.
- Model card com uso pretendido, população, limitações e contraindicações.
- Nenhuma implantação clínica a partir deste estudo; trata-se de pesquisa.

---

## 14. Relação com o artigo principal

| Artigo 1 — GLMM | Artigo 2 — ML |
|---|---|
| Heterogeneidade hospitalar e fatores associados | Predição e validação temporal |
| Inferência/associação | Predição/calibração |
| ICC, MOR, OR | AUC, AUPRC, Brier, DCA |
| Modelo explicativo | Modelo preditivo |
| Submissão a revista de saúde coletiva/epidemiologia | Submissão a revista de epidemiologia clínica, informática médica ou métodos |

O artigo 1 não precisa esperar o artigo 2. O artigo 2 deve citar o artigo 1 como
referência conceitual e usar o GLMM como baseline.

---

## 15. Checklist de aceitação

- [ ] Protocolo congelado antes do teste temporal.
- [ ] Base A e B documentadas.
- [ ] Checklist de leakage aprovado.
- [ ] Split temporal e CV agrupada implementados.
- [ ] Baseline GLMM/logística reportado.
- [ ] Pelo menos dois algoritmos de ML comparados.
- [ ] AUC, AUPRC, Brier, calibração e DCA reportados.
- [ ] Comparação ML vs GLMM no mesmo teste.
- [ ] Subgrupos e performance por ano reportados.
- [ ] Importância de variáveis com cautela.
- [ ] Registro completo de experimentos.
- [ ] Model card e TRIPOD+AI.
- [ ] Código reprodutível e versionado.
- [ ] Limitações e ausência de validação externa declaradas.

> **Regra final:** o ML só entra no artigo se a pergunta preditiva for clara,
> a validação for honesta e o resultado — inclusive negativo — for reportado por
> inteiro. O objetivo é prever melhor, não “ganhar” do GLMM.
