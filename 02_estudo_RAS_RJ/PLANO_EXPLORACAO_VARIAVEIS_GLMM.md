# Plano de exploração de variáveis no GLMM

**Projeto:** Morbimortalidade cerebrovascular e RAS no Rio de Janeiro
**Janela:** 2014–2024
**Unidade de análise:** internação (nível 1) → estabelecimento/CNES (nível 2) → região de saúde e ano (contexto)
**Documento:** plano de trabalho exploratório
**Princípio central:** **tudo é resultado**

> Este plano organiza a exploração de variáveis disponíveis na coorte e nos
> arquivos auxiliares. O objetivo não é “encontrar significância”, mas medir e
> documentar associações, heterogeneidade, ajuste e limitações. Todos os modelos
> executados — inclusive os nulos, instáveis, singulares ou que não convergiram —
> devem ser registrados e reportados. Nenhum modelo será descartado por ter
> p-valor desfavorável.

---

## 1. Perguntas de exploração

1. Quais variáveis de paciente, estabelecimento, território e tempo se associam à
   mortalidade intra-hospitalar após o ajuste mínimo atual?
2. Quanto cada bloco de variáveis reduz — ou aumenta — a heterogeneidade
   hospitalar (ICC/VPC) e a MOR?
3. Quais variáveis explicam a variação entre hospitais sem serem apenas
   proxies de gravidade, codificação ou volume?
4. Há interações relevantes entre perfil do paciente, tipo de hospital,
   território e tempo?
5. Os achados se sustentam para desfechos secundários (permanência prolongada,
   custo elevado e uso de UTI)?
6. Quais variáveis são **inutilizáveis** por completude, variabilidade ou
   definição, e por quê?

## 2. Regras de inferência e de reporte

### 2.1. Tudo é resultado

- Todo modelo executado entra no registro `05_tabelas/tab31_modelos.csv`.
- Todo coeficiente testado entra em `05_tabelas/tab31b_coeficientes.csv`.
- Modelos com erro, singularidade, `pdHess = FALSE` ou convergência diferente de
  zero permanecem no registro com a respectiva situação.
- Resultados nulos, contrários à hipótese e não interpretáveis também são
  reportados.
- Nenhuma variável será removida do relatório por ter p > 0,05.
- A seleção de variáveis para o modelo final **não** será feita por stepwise,
  p-valor ou “melhor AIC” isolado. A entrada é por blocos pré-especificados.

### 2.2. Exploratório ≠ confirmatório

- O documento é explicitamente exploratório; não haverá afirmação causal.
- O modelo principal atual (script 05) permanece como referência confirmatória.
- As extensões serão descritas como análise exploratória/sensibilidade.
- Qualquer análise adicionada depois do início da execução será marcada como
  `post hoc` no registro.

### 2.3. Multiplicidade

- Famílias de testes definidas antes da execução:
  - bloco paciente;
  - bloco hospital;
  - bloco território/tempo;
  - interações;
  - desfechos secundários.
- Reportar p bruto e q de Benjamini–Hochberg (FDR) dentro de cada família.
- Não usar o q-valor para esconder resultados; ele é apenas uma coluna adicional.

### 2.4. Tamanho de efeito e incerteza

Para cada modelo/termo, reportar sempre que aplicável:

- OR com IC95%;
- ΔAIC em relação ao modelo de referência;
- LRT com gl e p;
- ICC/VPC, MOR e IC95%;
- AUC e métricas de calibração (intercepto e inclinação);
- n, número de eventos e número de hospitais;
- convergência, `pdHess`, singularidade e tempo de ajuste.

### 2.5. Regras de convergência

1. Primeiro ajuste com `glmmTMB` e controle padrão.
2. Se não convergir: tentar `optimizer = "optim"`, `method = "BFGS"`.
3. Se ainda não convergir: simplificar a estrutura de efeitos aleatórios.
4. Se persistir: registrar como **não convergido** e não usar para inferência,
   mantendo o resultado no relatório.
5. Nunca apresentar coeficientes de modelo não convergido como achado.

## 3. Dados e níveis de análise

| Nível | Unidade | Exemplos de variáveis |
|---|---|---|
| 1 | Internação/AIH | idade, sexo, raça/cor, caráter, CID, UTI, fluxo, permanência, custo |
| 2 | Estabelecimento/CNES | volume, taxa de UTI, natureza jurídica, complexidade, case-mix |
| 3 | Região de saúde | região, macrorregião, população, oferta, fluxo |
| 4 | Tempo | ano, período, mês/estação |

**Base principal:** `01_dados/processados/coorte_glmm_2014_2024.csv` (222.832
internações; 42.426 óbitos; 222 CNES).

**Bases auxiliares:**

- `01_dados/processados/sih_cid_estudo_2014_2024.csv`;
- `01_dados/processados/sim_cid_estudo_2014_2024.csv`;
- população IBGE/SIDRA e lookup municipal;
- resultados CNES/SIA já consolidados em `04_resultados/resultados_ras_cnes_sia.txt`;
- `04_resultados/DICIONARIO_VARIAVEIS_SIH.md`.

## 4. Inventário de variáveis candidatas

### 4.1. Bloco A — paciente e episódio

| Variável | Nível | Tipo | Disponibilidade | Transformação proposta | Papel | Decisão |
|---|---|---|---|---|---|---|
| `idade_anos` | 1 | contínua | ~100% | linear, spline natural e categorias | gravidade/base | testar as três formas |
| `sexo` | 1 | categórica | ~100% | F/M | perfil | manter |
| `raca_cor` | 1 | categórica | ~77% | categorias + indicador de ausência | perfil/equidade | testar com e sem `NA` explícito |
| `instru` | 1 | categórica | 100% nominal | — | perfil | **não usar**: constante/inútil |
| `car_int` | 1 | categórica | alta | eletiva/urgência/outros | gravidade de acesso | manter |
| `subtipo` | 1 | categórica | 100% | 7 categorias atuais | fenótipo | manter |
| `cid3` | 1 | categórica | 100% | 12 grupos | fenótipo detalhado | testar como sensibilidade |
| `cid4` | 1 | categórica | alta | 4º dígito ou agrupamento | fenótipo | testar apenas se houver suporte |
| `uti` | 1 | binária | alta | 0/1 | marcador de gravidade | manter; não ler como causa |
| `uti_marca` | 1 | categórica | alta | marcação alternativa | sensibilidade | testar |
| `UTI_MES_TO` | 1 | contagem | alta | dias de UTI | mediação/gravidade | **não usar como covariável principal**; testar como desfecho secundário |
| `n_diag_sec` | 1 | contagem | 100% | 0–9+ | codificação/comorbidade | testar com cautela |
| `diagsec_disp` | 1 | binária | 100% | disponível/não | codificação | testar como marcador de qualidade |
| `DIAGSEC1`–`9` | 1 | texto | ≤17% | agrupar por capítulo CID | comorbidade | testar apenas em subamostra |
| `PROC_REA` | 1 | categórica de alta cardinalidade | alta | agrupar por capítulo SIGTAP/top procedures | tratamento | testar em grupos, nunca 67 mil níveis |
| `DIAR_ACOM` | 1 | contagem | alta | dias de acompanhamento | intensidade | avaliar como mediação |
| `ESPEC` | 1 | categórica | alta | — | especialidade | **não interpretar** sem tabela oficial |
| `INFEHOSP` | 1 | binária | 0% | — | infecção | **não usar**: 100% vazio |
| `CID_ASSO` | 1 | texto | 100% | — | causa associada | **não usar**: apenas `0000` |
| `NATUREZA` | 1 | categórica | 100% | — | natureza jurídica | **não usar**: valor único |
| `fluxo_inter` | 1 | binária | alta | residência ≠ internação | acesso territorial | manter |
| `mun_nome`/`MUNIC_RES6` | 1 | categórica | alta | município ou região | território | testar efeito aleatório municipal |
| `ano` | 1/4 | contínua | 100% | linear e spline | tendência secular | testar |
| mês/estação | 1/4 | categórica | 100% | mês ou estação | sazonalidade | testar em análise secundária |

### 4.2. Bloco B — estabelecimento/CNES

| Variável | Nível | Construção | Papel | Decisão |
|---|---|---|---|---|
| Volume hospitalar | 2 | `N` de internações por CNES; por 1.000 | porte/experiência | testar (já testado: OR 1,082 por 1.000) |
| Taxa de UTI do hospital | 2 | proporção de `uti` por CNES | capacidade/gravidade | testar via Mundlak (já existe) |
| Case-mix etário | 2 | idade média por CNES | gravidade | testar |
| Case-mix hemorrágico | 2 | proporção de I60–I62 por CNES | gravidade | testar |
| Case-mix urgente | 2 | proporção de urgência por CNES | gravidade | testar |
| Proporção de raça/cor ausente | 2 | % `NA` por CNES | qualidade de registro | testar |
| Natureza jurídica | 2 | `nat_jur_lab` | tipo de oferta | testar |
| Complexidade | 2 | `complex_lab` | tipo de oferta | testar |
| Cobertura de UTI | 2 | UTI registrada vs não | capacidade | testar |
| Oferta CNES/SIA | 2/3 | leitos UTI, TC, RM, hemo, neuro | capacidade | testar se houver linkage por CNES |
| Ensino/pesquisa | 2 | não disponível diretamente | estrutura | avaliar via CNES se houver campo |
| Volume por ano | 2/4 | internações CNES × ano | tendência institucional | testar em modelo com slope aleatório |

### 4.3. Bloco C — território e tempo

| Variável | Nível | Construção | Papel | Decisão |
|---|---|---|---|---|
| `regiao_saude` | 3 | 9 regiões | contexto | manter como efeito fixo |
| `macro3` | 3 | 3 macrorregiões | contexto | sensibilidade |
| Município | 3 | 92 municípios | contexto local | testar efeito aleatório |
| Fluxo intermunicipal | 1/3 | residência ≠ internação | acesso | manter |
| Distância/tempo de viagem | 3 | não disponível | acesso | avaliar linkage externo |
| Oferta regional | 3 | CNES/SIA por região | capacidade | testar se disponível |
| `ano` | 4 | 2014–2024 | tendência | testar |
| Período COVID | 4 | 2020–2021 vs demais | choque | testar |
| Mês/estação | 4 | 12 meses/4 estações | sazonalidade | testar em desfecho secundário |

### 4.4. Desfechos secundários

| Desfecho | Definição | Modelo proposto |
|---|---|---|
| Permanência prolongada | `DIAS_PERM` > p75 ou ≥ 30 dias | GLMM binomial ou negativo-binomial |
| Custo elevado | `VAL_TOT` > p75, deflacionado | GLMM gama com log |
| Uso de UTI | `uti`/`uti_marca` | GLMM binomial |
| Óbito + permanência | desfecho composto exploratório | GLMM binomial |
| Transferência? | não disponível de forma confiável | não testar |

> `DIAS_PERM` e `VAL_TOT` **não entram como covariáveis** da mortalidade: são
> desfechos ou mediadores. `UTI` é marcador de gravidade e será tratado como tal.

## 5. Ondas de execução

### Onda 0 — auditoria e congelamento do grid

- Congelar a lista de variáveis e os modelos antes de executar.
- Rodar auditoria de completude, número de níveis e proporção do nível dominante.
- Registrar variáveis inutilizáveis e o motivo.
- Definir famílias de FDR.
- Produzir `05_tabelas/tab31_grid_variaveis.csv`.

**Critério de conclusão:** toda variável candidata classificada como “testar”,
“não usar” ou “avaliar linkage”.

### Onda 1 — modelos de bloco

Ordem pré-especificada, sempre com a mesma amostra de referência quando possível:

1. `M0`: modelo principal atual.
2. `M1`: M0 + idade spline/categorias.
3. `M2`: M0 + raça/cor (com indicador de ausência).
4. `M3`: M0 + comorbidade/codificação secundária.
5. `M4`: M0 + natureza jurídica + complexidade.
6. `M5`: M0 + volume + taxa de UTI do hospital.
7. `M6`: M0 + case-mix hospitalar.
8. `M7`: M0 + ano/período.
9. `M8`: modelo completo com todos os blocos disponíveis.

Para cada modelo:

- reportar n, eventos, hospitais, convergência;
- ΔAIC e LRT contra M0 na mesma amostra;
- ICC, MOR e ΔICC;
- OR/IC95%/p/q dos termos novos;
- AUC e calibração;
- observações sobre colinearidade e interpretação.

### Onda 2 — interações e estrutura multinível

Interações pré-especificadas:

- sexo × faixa de idade;
- subtipo × UTI;
- região × ano;
- volume × UTI do hospital;
- natureza jurídica × complexidade;
- raça/cor × região (apenas se houver suporte).

Estruturas alternativas:

- `(1 | CNES) + (1 | regiao_saude)`;
- `(1 | regiao_saude/CNES)`;
- `(1 + uti | CNES)`;
- `(1 + ano | CNES)`;
- `(1 + idade_z | CNES)`;
- `(1 | municipio)`.

Registrar convergência e, se não convergir, a tentativa com otimizador alternativo.

### Onda 3 — desfechos secundários

- Permanência prolongada: binomial e negativo-binomial.
- Custo elevado: gama log e duas partes (se necessário).
- Uso de UTI: binomial com e sem Mundlak.
- Comparar direção dos efeitos com o desfecho principal.
- Não usar os desfechos secundários para “validar” o modelo principal.

### Onda 4 — sensibilidade e robustez

- Excluir I64.
- Restringir a hospitais com ≥ 10 óbitos.
- Excluir hospitais sem óbito.
- Período pré vs pós-2020.
- Casos completos vs indicador de ausência vs imputação múltipla (raça/cor).
- Bootstrap por conglomerado hospitalar para ICC e AUC.
- Modelo penalizado (elastic net) com validação cruzada agrupada por CNES,
  usado apenas para ranking exploratório, não para inferência.

### Onda 5 — relatório

- Relatório narrativo com todos os resultados.
- Tabela de modelos e tabela de coeficientes.
- Forest plots por bloco.
- Curvas de ICC/ΔICC.
- Lista de modelos não convergidos.
- Seção “o que não foi possível testar e por quê”.

## 6. Registro obrigatório de resultados

### 6.1. `05_tabelas/tab31_modelos.csv`

Uma linha por modelo:

| Coluna | Conteúdo |
|---|---|
| `id_modelo` | identificador único |
| `onda` | 0–5 |
| `desfecho` | óbito, permanência, custo, UTI |
| `familia` | binomial, negativo-binomial, gama |
| `especificacao` | fórmula resumida |
| `n` | observações |
| `eventos` | eventos do desfecho |
| `hospitais` | CNES distintos |
| `convergencia` | código |
| `pdHess` | TRUE/FALSE |
| `singular` | TRUE/FALSE |
| `logLik` | log-verossimilhança |
| `AIC` | AIC |
| `ICC` | ICC/VPC |
| `MOR` | MOR |
| `AUC` | AUC quando aplicável |
| `cal_intercepto` | intercepto de calibração |
| `cal_inclinacao` | inclinação de calibração |
| `LR_vs_base` | LRT |
| `gl_LR` | graus de liberdade |
| `p_LR` | p do LRT |
| `status` | convergiu, não convergiu, erro, singular |
| `observacao` | nota obrigatória |

### 6.2. `05_tabelas/tab31b_coeficientes.csv`

Uma linha por termo:

| Coluna | Conteúdo |
|---|---|
| `id_modelo` | chave |
| `termo` | coeficiente |
| `beta` | estimativa |
| `ep` | erro-padrão |
| `z` | estatística |
| `p` | p bruto |
| `q_familia` | FDR dentro da família |
| `or` | exp(beta) |
| `or_lo` | IC95% inferior |
| `or_hi` | IC95% superior |
| `nivel` | paciente, hospital, território, tempo |
| `papel` | gravidade, oferta, acesso, codificação, contexto |
| `observacao` | nota |

### 6.3. Saídas auxiliares

- `04_resultados/resultados_exploracao_variaveis.txt` — log completo.
- `12_relatorios/RELATORIO_EXPLORACAO_VARIAVEIS.md` — síntese narrativa.
- `06_figuras/exploratorias/fig_ex30_forest_blocos.png`.
- `06_figuras/exploratorias/fig_ex31_icc_delta.png`.
- `06_figuras/exploratorias/fig_ex32_calibracao_comparada.png`.

## 7. Estrutura de scripts proposta

| Script | Função |
|---|---|
| `29_exploracao_variaveis.R` | Onda 0 e Onda 1: grid, auditoria, modelos de bloco e registro. |
| `29b_exploracao_interacoes.R` | Onda 2: interações e estruturas multinível alternativas. |
| `29c_exploracao_secundarios.R` | Onda 3: permanência, custo e UTI. |
| `29d_exploracao_sensibilidade.R` | Onda 4: recortes, imputação, bootstrap e elastic net. |
| `29e_relatorio_exploracao.R` | Onda 5: tabelas, figuras e relatório. |
| `29_consolidar_exploracao.R` | Consolida `tab31` e verifica integridade do registro. |

Cada script deve:

- gravar log em `04_resultados/`;
- nunca sobrescrever resultados sem registrar a versão anterior;
- usar `set.seed()` explícito nas etapas estocásticas;
- registrar a versão do R e dos pacotes.

## 8. Critérios de decisão

### 8.1. Quando uma variável “entra” no modelo final?

Nunca por p-valor isolado. Uma variável entra no modelo final exploratório se:

1. tiver suporte conceitual e completude mínima;
2. não for mediação ou consequência do desfecho;
3. melhorar o ajuste de forma interpretável (ΔAIC e LRT);
4. não gerar colinearidade grave;
5. mantiver a direção em pelo menos duas ondas de sensibilidade.

Mesmo assim, o modelo final é **exploratório**, não confirmatório.

### 8.2. Quando uma variável é marcada como “não usar”?

- completude < 50% sem possibilidade de imputação defensável;
- nível dominante > 95%;
- campo constante ou quase constante;
- codificação sem dicionário oficial;
- variável claramente posterior ao desfecho;
- colinearidade extrema com outra variável já incluída.

### 8.3. O que conta como “resultado” no relatório?

- OR e IC;
- ΔICC e ΔAIC;
- direção e magnitude;
- falha de convergência;
- instabilidade entre cenários;
- ausência de associação;
- impossibilidade de teste.

## 9. Riscos e mitigação

| Risco | Mitigação |
|---|---|
| p-hacking por muitas variáveis | grid congelado, FDR por família, registro completo |
| Overfitting | validação cruzada agrupada por CNES; modelo final parcimonioso |
| Colinearidade | VIF, matriz de correlação, remoção conceitual (não automática) |
| Missing informativo | indicador de ausência + imputação múltipla como sensibilidade |
| Não convergência | otimizador alternativo, simplificação, registro e exclusão da inferência |
| Heterogeneidade hospitalar não capturada | random slopes e efeitos de região/município |
| Leitura causal | linguagem explicitamente associativa |
| Mudança de codificação ao longo do tempo | ano/período como sensibilidade; não como ajuste principal |

## 10. Resultados de partida já conhecidos

Estes resultados já foram obtidos e servem de linha de base para o plano:

- Modelo principal: ICC **14,50%**; MOR **2,039**; AIC **192.228**.
- Inclusão de **ano**: OR **0,948** por ano (IC95% 0,945–0,952); AIC **191.478**;
  ICC **16,04%**.
- Inclusão de **volume hospitalar**: OR **1,082** por 1.000 internações
  (IC95% 1,023–1,143); AIC **192.222**; ICC **14,01%**.
- Volume + ano: OR 1,084 e 0,948; AIC **191.473**; ICC **15,56%**.
- Interação região × ano: **não convergiu**; não retida.
- Interações sexo × idade e subtipo × UTI: LRT p < 0,001.
- V de Cramér: região 0,124; CID-3 0,158; diagnósticos secundários 0,189;
  raça/cor 0,039; sexo 0,007.
- Mann–Kendall/Sen: internação +3,09/100.000 por ano; mortalidade +0,13;
  letalidade −0,15 p.p./ano.

## 11. Checklist de aceitação

- [ ] Grid de variáveis congelado e versionado.
- [ ] Auditoria de completude e níveis concluída.
- [ ] Todos os modelos das ondas 1–3 registrados em `tab31_modelos.csv`.
- [ ] Todos os coeficientes em `tab31b_coeficientes.csv`.
- [ ] Modelos não convergidos registrados com motivo.
- [ ] FDR aplicado por família.
- [ ] Calibração e AUC reportadas para os modelos principais.
- [ ] Relatório narrativo com resultados nulos e limitações.
- [ ] Scripts reprodutíveis e com log.
- [ ] Nenhuma conclusão causal.
- [ ] Commit e push do plano e dos resultados.

---

## 12. Ordem prática sugerida

1. Congelar este plano e o grid (Onda 0).
2. Rodar bloco paciente (Onda 1).
3. Rodar bloco hospital (Onda 1).
4. Rodar bloco território/tempo (Onda 1).
5. Rodar modelo completo e interações (Onda 2).
6. Rodar desfechos secundários (Onda 3).
7. Rodar sensibilidade e elastic net (Onda 4).
8. Consolidar `tab31`, escrever relatório e figuras (Onda 5).
9. Revisar interpretação com a mesma régua: associação, incerteza,
   heterogeneidade e limitação.

> **Regra final:** se um resultado é desconfortável, ele continua no relatório.
> O valor deste plano está menos em “achar” associações e mais em documentar,
> com transparência, o que os dados sustentam e o que não sustentam.
