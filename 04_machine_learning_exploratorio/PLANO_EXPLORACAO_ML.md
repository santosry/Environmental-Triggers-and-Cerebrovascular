# Plano de exploração de variáveis com machine learning

**Projeto:** morbimortalidade cerebrovascular e RAS no Rio de Janeiro
**Base:** SIH-RD/SUS, 2014–2024, I60–I69 e blocos G45/G46
**Unidade principal:** internação (nível 1), com agregações por CNES, região e ano
**Natureza:** exploração de dados e padrões
**Documento:** plano metodológico e operacional
**Status:** planejado — ainda não executado

> **Este plano não é de predição.** Não há desfecho-alvo, treino/teste, AUC,
> calibração, curva de decisão ou promessa de generalização. O objetivo é
> **entender a estrutura das variáveis**, descrever perfis, encontrar padrões e
> associações, e documentar tudo — inclusive o que não deu certo.
>
> Machine learning aqui significa **aprendizado não supervisionado** e
> **mineração de padrões**: redução de dimensionalidade, agrupamento, regras de
> associação e análise de estabilidade. Se no futuro surgir uma pergunta
> preditiva, ela exigirá protocolo próprio e não será misturada a este anexo.

---

## 1. Objetivo

Explorar as variáveis disponíveis na coorte de DCV do Rio de Janeiro para
responder perguntas descritivas e estruturais, sem compromisso com predição:

1. Quais variáveis têm qualidade suficiente para análise?
2. Como as variáveis se organizam entre si (correlação, associação, redundância)?
3. Existem perfis/grupos naturais de pacientes, hospitais e territórios?
4. Quais combinações de características aparecem com mais frequência?
5. Os padrões são estáveis sob diferentes codificações, subamostras e algoritmos?
6. O que os dados **não** permitem concluir?

### Perguntas exploratórias

- A coorte se divide em perfis clínicos/assistenciais distintos?
- Hospitais se agrupam por porte, case-mix, natureza jurídica e uso de UTI?
- Regiões de saúde têm perfis assistenciais distintos?
- Quais diagnósticos, procedimentos e características aparecem juntos?
- Há padrões de ausência de dados que revelam época, serviço ou tipo de registro?
- Quais variáveis são redundantes e podem ser resumidas?
- Quais variáveis são apenas proxies de codificação ou de época?

### O que este plano não fará

- Não vai prever óbito, permanência ou custo.
- Não vai separar treino e teste.
- Não vai otimizar AUC, acurácia, F1, Brier ou calibração.
- Não vai produzir model card ou seguir TRIPOD+AI.
- Não vai afirmar causalidade.
- Não vai escolher variáveis por p-valor.
- Não vai descartar resultados desfavoráveis.

---

## 2. Princípios

### 2.1. Exploração declarada

- O plano é exploratório por definição.
- Nenhum resultado será apresentado como confirmação de hipótese.
- Associações serão descritas como padrões, não como efeitos.
- A interpretação será sempre condicionada ao desenho e à qualidade do dado.

### 2.2. Tudo é resultado

- Toda análise executada entra no registro `03_resultados/registro_analises.csv`.
- Inclui análises com resultado nulo, clusters instáveis, regras com baixo suporte e
  algoritmos que não convergiram.
- Nenhum resultado será removido por ser inconveniente.
- O relatório deve mostrar o que foi tentado, não apenas o que funcionou.

### 2.3. Sem seleção por p-valor

- O objetivo não é “achar significância”.
- Associações serão reportadas com tamanho de efeito e incerteza.
- O p-valor, quando usado, será coadjuvante.
- FDR pode ser aplicado em famílias de testes, mas não será usado para esconder
  resultados.

### 2.4. Estabilidade antes de interpretação

- Clusters e componentes só serão interpretados se forem minimamente estáveis.
- Instabilidade será reportada como resultado, não como falha a ser omitida.
- Toda escolha de `k`, número de componentes ou limiar de regra será registrada.

---

## 3. Dados e variáveis

### 3.1. Fonte principal

`02_estudo_RAS_RJ/01_dados/processados/coorte_glmm_2014_2024.csv`

- 222.832 internações;
- 42.426 óbitos intra-hospitalares;
- 222 estabelecimentos;
- 9 regiões de saúde;
- 2014–2024.

### 3.2. Fonte auxiliar

- `02_estudo_RAS_RJ/01_dados/processados/sih_cid_estudo_2014_2024.csv`;
- `02_estudo_RAS_RJ/01_dados/processados/sim_cid_estudo_2014_2024.csv`;
- população IBGE/SIDRA e lookup municipal;
- resultados CNES/SIA já consolidados;
- dicionário de variáveis da Frente 02.

### 3.3. Blocos de variáveis

| Bloco | Exemplos | Uso exploratório |
|---|---|---|
| Demografia | idade, sexo, raça/cor | perfis, associação, agrupamento |
| Episódio | caráter, CID principal, CID secundário, permanência | perfis clínicos e assistenciais |
| Utilização | UTI, dias de UTI, procedimentos, custo | padrões de intensidade |
| Estabelecimento | CNES, natureza jurídica, complexidade, volume | perfis de hospital |
| Território | região, macrorregião, município, fluxo | perfis territoriais |
| Tempo | ano, mês/estação | padrões temporais |
| Qualidade | missing, códigos ignorados, campos constantes | padrões de registro |

### 3.4. Variáveis que devem ser tratadas com cautela

| Variável | Cautela |
|---|---|
| `INSTRU` | constante/inutilizável; não interpretar |
| `INFEHOSP` | 100% vazio |
| `CID_ASSO` | apenas `0000` |
| `NATUREZA` | valor único |
| `ESPEC` | sem dicionário oficial |
| `RACA_COR` | ausência informativa e queda ao longo do tempo |
| `n_diag_sec` / `DIAGSEC1–9` | medem codificação tanto quanto comorbidade |
| `PROC_REA` | alta cardinalidade; agrupar por capítulo/top procedimentos |
| `DIAS_PERM`, `VAL_TOT`, `VAL_UTI` | desfechos/mediadores; usar como descrição, não como causa |
| `UTI` / `UTI_MES_TO` | gravidade, capacidade e registro; não ler como risco causal |

### 3.5. Preparação

- Manter ausentes como `NA`; não criar rótulo falso de “sem informação” quando o
  código já significa ausência.
- Criar indicador de ausência apenas quando a ausência for informativa.
- Agrupar categorias raras com critério prévio (ex.: < 1% ou < 50 registros).
- Padronizar contínuas apenas para métodos que exigem escala.
- Não imputar para clustering principal; usar casos completos ou tratar `NA`
  nativamente. Imputação, se usada, entra como sensibilidade.
- Registrar toda transformação.

---

## 4. Estratégia analítica

### Onda 0 — auditoria e dicionário

1. Listar todas as variáveis da coorte.
2. Calcular completude, número de níveis, nível dominante, tipo e estabilidade
   temporal.
3. Classificar cada variável como:
   - `explorar`;
   - `explorar com cautela`;
   - `apenas descrever`;
   - `não usar`.
4. Produzir matriz de missingness por ano e por hospital.
5. Congelar o grid de análise antes de começar.

**Saídas:**

- `04_tabelas/tab01_dicionario_exploracao.csv`;
- `04_tabelas/tab02_missingness.csv`;
- `05_figuras/fig01_missingness.png`.

### Onda 1 — associações e redundância

1. Matriz de associação entre variáveis:
   - Cramér's V para categóricas;
   - Spearman para contínuas/ordinais;
   - correlação biserial ou ponto-biserial para binárias;
   - informação mútua quando útil.
2. Heatmap de associação.
3. Identificação de blocos redundantes.
4. Associação descritiva com óbito, permanência e custo — sem modelo preditivo.
5. Tabelas de contingência para combinações frequentes.

**Saídas:**

- `04_tabelas/tab03_associacoes.csv`;
- `05_figuras/fig02_heatmap_associacoes.png`;
- `04_tabelas/tab04_associacoes_desfechos.csv`.

### Onda 2 — redução de dimensionalidade

Métodos:

- **FAMD** (factor analysis of mixed data) para o conjunto misto;
- **MCA** para o bloco categórico;
- **PCA** para o bloco contínuo;
- **UMAP** apenas para visualização, não para inferência.

Procedimentos:

- analisar eigenvalues e variância explicada;
- interpretar loadings/contribuições;
- verificar estabilidade por bootstrap;
- comparar soluções com e sem variáveis de qualidade duvidosa;
- não rotular componentes como “fatores causais”.

**Saídas:**

- `04_tabelas/tab05_componentes.csv`;
- `04_tabelas/tab06_loadings.csv`;
- `05_figuras/fig03_famd_individuos.png`;
- `05_figuras/fig04_loadings.png`.

### Onda 3 — agrupamento de pacientes

Objetivo: encontrar perfis clínicos/assistenciais, não prever desfecho.

Métodos:

- **k-prototypes** para dados mistos;
- **hierarchical clustering** com distância de Gower;
- **latent class analysis** para variáveis categóricas;
- **consensus clustering** para estabilidade.

Procedimentos:

- escolher `k` por silhouette, BIC, interpretabilidade e estabilidade;
- testar `k` pré-especificados (ex.: 2 a 10);
- validar estabilidade por bootstrap (ARI);
- descrever clusters por idade, sexo, CID, caráter, UTI, permanência, custo e
  mortalidade — sem usar o desfecho para construir os clusters;
- comparar clusters com e sem variáveis de codificação duvidosa.

**Saídas:**

- `04_tabelas/tab07_clusters_pacientes.csv`;
- `04_tabelas/tab08_perfil_clusters.csv`;
- `04_tabelas/tab09_estabilidade_clusters.csv`;
- `05_figuras/fig05_perfis_clusters.png`.

### Onda 4 — agrupamento de hospitais e territórios

Objetivo: descrever tipos de estabelecimento e de região, sem ranking de qualidade.

Variáveis por CNES:

- volume;
- taxa de UTI;
- case-mix etário;
- proporção de hemorrágicos;
- proporção de urgência;
- natureza jurídica;
- complexidade;
- mortalidade observada.

Procedimentos:

- clustering hierárquico com Gower;
- k-prototypes;
- descrever perfis;
- comparar com a classificação jurídica/complexidade existente;
- não transformar clusters em ranking punitivo.

**Saídas:**

- `04_tabelas/tab10_clusters_hospitais.csv`;
- `04_tabelas/tab11_perfil_hospitais.csv`;
- `05_figuras/fig06_mapa_clusters.png`.

### Onda 5 — regras de associação

Objetivo: encontrar combinações frequentes de diagnósticos, procedimentos,
características e desfechos.

Métodos:

- Apriori/FP-growth;
- suporte, confiança e lift;
- regras por bloco (diagnóstico, utilização, hospital, território);
- limite mínimo de suporte definido antes da execução;
- controle de regras triviais e redundantes.

Procedimentos:

- não usar regras para afirmar causalidade;
- separar regras descritivas de regras com desfecho;
- reportar regras com suporte baixo como instáveis;
- comparar regras entre períodos.

**Saídas:**

- `04_tabelas/tab12_regras_associacao.csv`;
- `05_figuras/fig07_regras_rede.png`.

### Onda 6 — estabilidade e sensibilidade

- Bootstrap por hospital.
- Variação de `k` e de hiperparâmetros.
- Exclusão de I64.
- Exclusão de hospitais com baixo volume.
- Casos completos vs indicador de ausência.
- Codificação alternativa de CID e raça/cor.
- Comparação de clusters entre 2014–2019 e 2020–2024.
- Registro de todas as variações.

**Saídas:**

- `04_tabelas/tab13_estabilidade_global.csv`;
- `03_resultados/registro_analises.csv`.

### Onda 7 — relatório

- Relatório narrativo com todos os resultados.
- Tabelas de perfis.
- Figuras de associação, componentes, clusters e regras.
- Seção de instabilidade e resultados nulos.
- Seção “o que não foi possível explorar e por quê”.

---

## 5. Métodos de ML exploratório

| Método | Para que serve | O que não é |
|---|---|---|
| FAMD/MCA/PCA | resumir estrutura e redundância | não é modelo causal |
| UMAP/t-SNE | visualizar proximidade | não é agrupamento definitivo |
| k-prototypes | agrupar dados mistos | não é classificação supervisionada |
| Hierarchical/Gower | agrupar com distâncias robustas | não é ranking de qualidade |
| LCA | perfis latentes categóricos | não é diagnóstico clínico |
| Apriori/FP-growth | combinações frequentes | não é relação causal |
| Consensus clustering | testar estabilidade | não é validação externa |
| Random forest não supervisionado | proximidade/outliers | não é predição |
| Boruta/importância por permutação | ranking exploratório de variáveis | não é efeito nem predição |

> Se alguma técnica supervisionada for usada apenas para ranking exploratório, ela
> será rotulada como **exploratória** e não produzirá métricas de predição no
> relatório. O foco permanece descrever padrões, não generalizar para novos casos.

---

## 6. Registro de análises

`03_resultados/registro_analises.csv` deve conter uma linha por análise:

| Coluna | Conteúdo |
|---|---|
| `id_analise` | identificador único |
| `onda` | 0–7 |
| `objetivo` | associação, componentes, clustering, regras, estabilidade |
| `variaveis` | blocos/variáveis usados |
| `metodo` | FAMD, k-prototypes, Apriori etc. |
| `parametros` | `k`, suporte, distância, semente |
| `n` | observações |
| `resultado` | síntese numérica |
| `estabilidade` | ARI, silhouette, bootstrap etc. |
| `status` | concluído, instável, falhou |
| `observacao` | nota obrigatória |

Nenhuma linha será apagada. Se uma análise for refeita, cria-se nova linha com
versão/data.

---

## 7. Estrutura de scripts proposta

| Script | Função |
|---|---|
| `00_config.R` | caminhos, sementes, bibliotecas e funções comuns |
| `01_auditar_variaveis.R` | dicionário, missingness e classificação |
| `02_associacoes.R` | matriz de associação e tabelas de contingência |
| `03_reducao_dimensional.R` | FAMD/MCA/PCA/UMAP |
| `04_clusters_pacientes.R` | k-prototypes, Gower, LCA, consensus |
| `05_clusters_hospitais.R` | perfis de CNES e territórios |
| `06_regras_associacao.R` | Apriori/FP-growth |
| `07_estabilidade.R` | bootstrap, sensibilidade e comparação |
| `08_relatorio.R` | tabelas, figuras e relatório final |
| `09_consolidar_registro.R` | registro único e checagem de integridade |

### Saídas

```
04_machine_learning_exploratorio/
├── 01_dados/
├── 02_scripts/
├── 03_resultados/
│   ├── registro_analises.csv
│   ├── log_exploracao.txt
│   └── resultados_exploracao.txt
├── 04_tabelas/
├── 05_figuras/
└── 06_relatorios/
    └── RELATORIO_EXPLORACAO_ML.md
```

---

## 8. Critérios de qualidade

### 8.1. Associações

- Reportar tamanho de efeito e IC quando possível.
- Não usar apenas p-valor.
- Distinguir associação descritiva de associação ajustada.
- Não interpretar associação como causa.

### 8.2. Componentes

- Reportar variância explicada.
- Interpretar apenas loadings com contribuição relevante.
- Testar estabilidade por bootstrap.
- Comparar soluções com diferentes blocos de variáveis.

### 8.3. Clusters

- Reportar `k` testados e critério de escolha.
- Reportar silhouette, Dunn e estabilidade ARI.
- Não interpretar clusters com ARI baixo.
- Descrever clusters com tamanho e perfil.
- Não transformar cluster em ranking.

### 8.4. Regras

- Reportar suporte, confiança e lift.
- Remover regras triviais.
- Reportar regras instáveis.
- Não confundir coocorrência com causalidade.

### 8.5. Missingness

- Descrever padrões por ano, hospital e região.
- Não tratar ausência como categoria sem justificativa.
- Testar sensibilidade com e sem indicador de ausência.

---

## 9. Riscos e mitigação

| Risco | Mitigação |
|---|---|
| Interpretar cluster como diagnóstico | linguagem descritiva e validação por estabilidade |
| Overfitting narrativo | registro completo e critérios prévios |
| Muitas análises | plano congelado, registro e foco por ondas |
| Variáveis redundantes | matriz de associação e FAMD |
| Missing informativo | análise de padrões e sensibilidade |
| Codificação heterogênea | estratificação por período e hospital |
| Cluster instável | bootstrap, consensus e relato explícito |
| Regras triviais | suporte mínimo e filtro de redundância |
| Confusão com predição | nenhuma métrica preditiva será reportada |
| Causalidade implícita | aviso em todas as seções |

---

## 10. Relação com a Frente 02

| Frente 02 | Este anexo |
|---|---|
| Estudo ecológico + GLMM | Exploração de estrutura e padrões |
| Inferência/associação ajustada | Descrição/agrupamento |
| ICC, MOR, OR | Associações, componentes, clusters, regras |
| Modelo confirmatório | Exploração declarada |
| Artigo principal | Anexo metodológico ou artigo separado de análise exploratória |

Este anexo **não altera** a coorte, os scripts, as tabelas ou as conclusões da
Frente 02. Ele lê a base processada e grava apenas em sua própria pasta.

---

## 11. Cronograma sugerido

| Etapa | Duração | Produto |
|---|---|---|
| 1. Auditoria e dicionário | 1 semana | `tab01`, `tab02` |
| 2. Associações e missingness | 1 semana | `tab03`, `tab04`, heatmaps |
| 3. FAMD/MCA e visualização | 1–2 semanas | componentes e figuras |
| 4. Clusters de pacientes | 2 semanas | perfis e estabilidade |
| 5. Clusters de hospitais | 1 semana | perfis de CNES |
| 6. Regras de associação | 1 semana | regras e rede |
| 7. Estabilidade e sensibilidade | 1–2 semanas | `tab13` |
| 8. Relatório | 1 semana | relatório final |

---

## 12. Checklist de aceitação

- [ ] Grid de variáveis congelado.
- [ ] Dicionário e missingness concluídos.
- [ ] Matriz de associação e heatmap.
- [ ] FAMD/MCA com variância explicada e loadings.
- [ ] Clusters de pacientes com `k` testados e estabilidade.
- [ ] Clusters de hospitais com perfis descritos.
- [ ] Regras de associação com suporte/confiança/lift.
- [ ] Análise de estabilidade e sensibilidade.
- [ ] Registro completo de análises, inclusive falhas.
- [ ] Relatório com resultados nulos e limitações.
- [ ] Nenhuma métrica de predição.
- [ ] Nenhuma afirmação causal.
- [ ] Código reprodutível e versionado.
- [ ] Pasta e resultados separados da Frente 02.

> **Regra final:** o objetivo é entender o que as variáveis mostram e o que não
> mostram. Se um padrão for instável, ele continua no relatório como instável.
> Explorar não é prever; é mapear o terreno com honestidade.
