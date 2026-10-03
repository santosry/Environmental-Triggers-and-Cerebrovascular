# Frente 02 — Morbimortalidade cerebrovascular e RAS no Rio de Janeiro

📁 **Parte do monorepo** [Gatilhos Ambientais e Doenças Cerebrovasculares](../README.md)

Estudo ecológico de séries temporais (2010–2024) sobre a morbimortalidade por doenças
cerebrovasculares (**CID-10 I60–I69**, além dos blocos **G45–G46**) no estado do Rio de
Janeiro, com **modelagem logística multinível (GLMM)** da mortalidade intra-hospitalar
e análise territorial pelas **nove regiões de saúde**. Última atualização: 2 de outubro
de 2026.

---

## Sumário

- [Enquadramento](#enquadramento)
- [Estrutura das pastas](#estrutura-das-pastas)
- [Detalhamento de `01_dados/`](#detalhamento-de-01_dados)
- [Cadeia de execução](#cadeia-de-execução)
- [Função de cada script](#função-de-cada-script)
- [Decisões metodológicas registradas](#decisões-metodológicas-registradas)
- [Resultados principais](#resultados-principais)
- [Robustez e conferência entre motores](#robustez-e-conferência-entre-motores)
- [Limitações](#limitações)
- [Limpeza realizada](#limpeza-realizada)
- [Pendências](#pendências)

---

## Enquadramento

- **Desenho:** estudo ecológico de séries temporais, retrospectivo (01/01/2010 a
  31/12/2024).
- **Unidades de análise:** município → **9 regiões de saúde** → macrorregiões.
- **Aquisição:** pacote **`microdatasus` 2.5.0** em R 4.6.1 (SIH-RD e SIM-DO).
- **Análise:** **R 4.6.1**, `glmmTMB` 1.1.15.2, com conferência em `lme4` 2.0.1.
- **Ética:** dados secundários, agregados e anonimizados de domínio público
  (Resolução CNS 510/2016 — dispensa de CEP), em conformidade com a LGPD.

---

## Estrutura das pastas

| Pasta | Conteúdo |
|---|---|
| `01_dados/` | Dados brutos e processados. Ver [detalhamento](#detalhamento-de-01_dados). |
| `02_scripts/` | Todo o código, em R e Python. Ver a [cadeia de execução](#cadeia-de-execução). |
| `03_analises/` | Logs de aquisição e consolidação. |
| `04_resultados/` | Resultados em texto, um arquivo por etapa. |
| `05_tabelas/` | Tabelas em CSV, numeradas na ordem em que entram no manuscrito. |
| `06_figuras/` | Figuras em `manuscrito/` (Figuras 1–2 finais em `.jpg` 300 dpi), `exploratorias/` (banco de ~25) e `suplementares/` (demais). PNG/JPEG a 300 dpi. |
| `07_literatura/` | Matriz de literatura com autoria verificada e 13 artigos completos em PDF (texto livre, via DOI/SciELO/Europe PMC). |
| `08_manuscrito/` | Manuscrito em Markdown. |
| `09_documentos_submissao/` | Modelos de documentos exigidos pelo edital. |
| `10_auditoria/` | Auditorias do estudo anterior, dos dados e da metodologia. |
| `12_relatorios/` | Relatórios executivo e final, e comparação antigo×novo. |
| `13_documentos_referencia/` | PDFs de referência (edital e plano estadual de saúde). |

### Detalhamento de `01_dados/`

| Caminho | Conteúdo |
|---|---|
| `brutos_sih/` | 191 competências do SIH-RD do RJ, 2010-01 a 2025-11, baixadas pelo `microdatasus` (~479 MB). |
| `brutos_sim/` | 15 arquivos anuais do SIM-DO do RJ, 2010 a 2024, baixados pelo `microdatasus` (~98 MB). |
| `processados/` | Bases consolidadas e derivadas. Os recortes por CID do estudo (`sih_cid_estudo_2010_2024.csv`, `sim_cid_estudo_2010_2024.csv`) são **leves e versionados**, gerados pelo script 01; os demais (`coorte_glmm_2010_2024.csv`, `modelo_glmm_principal_glmmTMB.rds`, previsões e efeitos hospitalares) são pesados e não versionados. |
| `inventario_colunas/` | Inventário de colunas por arquivo do SIH-RD. |
| `tmp_ipca/` | Cache da série do IPCA (SIDRA/IBGE, tabela 1737). |
| `tmp_parquet/` | Intermediário da consolidação histórica (pode ser refeito). |

> A competência 2025-12 não está publicada no DATASUS. As competências de 2025 existem
> apenas para capturar internações de dezembro de 2024, que podem ser processadas em
> janeiro de 2025. O filtro final é sempre `DT_INTER` entre **2010 e 2024**.

---

## Cadeia de execução

Executar a partir da raiz desta frente:

```powershell
$R = "C:\Program Files\R\R-4.6.1\bin\Rscript.exe"

# 1. aquisicao dos microdados (R, microdatasus) -- cerca de 38 min
& $R "02_scripts\01_baixar_microdatasus.R"

# 2. coorte analitica e tabelas descritivas
& $R "02_scripts\02_montar_coorte.R"
& $R "02_scripts\03_tabelas_descritivas.R"

# 3. Indice de Swaroop-Uemura por regiao de saude
& $R "02_scripts\04_isu_regiao_saude.R"

# 4. GLMM principal com FDR -- cerca de 3 min
& $R "02_scripts\05_glmm_principal.R"

# 5. tratamento da UTI (decomposicao de Mundlak)
& $R "02_scripts\06_glmm_uti.R"

# 6. auditoria de consistencia (SIH x SIM x modelo)
& $R "02_scripts\07_auditoria_consistencia.R"
& $R "02_scripts\12_auditoria_geral.R"        # aquisicao, recorte CID, codigo e repo

# 7. robustez -- cerca de 40 min
& $R "02_scripts\08_glmm_robustez.R"

# 8. conferencia entre motores (invoca a si mesmo em processo isolado)
& $R "02_scripts\09_conferencia_motores.R"

# 9. figuras
& $R "02_scripts\10_figuras.R"
& $R "02_scripts\11_exploratorio.R"          # modelos exploratorios (~60 min)
& $R "02_scripts\13_figuras_exploratorias.R" # banco de ~25 figuras
& $R "02_scripts\19_figura_exploratorio.R"   # refaz a figura do script 11 (rapido)

# 10. denominadores populacionais e custos (analise atual)
& $R "02_scripts\14_verificacao_sidra.R"
& $R "02_scripts\15_deflacao_ipca.R"

# 11. analises territoriais historicas (tabelas de tendencia e mortalidade)
& python "02_scripts\16_consolidar_dados.py"
& python "02_scripts\18_mortalidade_sim.py"
& python "02_scripts\17_analises_territoriais.py"
```

### Organizacao dos scripts

Nao ha mais subpasta de scripts: todos ficam em `02_scripts/`. Os
scripts 14 (SIDRA) e 15 (IPCA) foram promovidos a **analise atual** e usam a coorte
consolidada (`coorte_glmm_2010_2024.csv`). Os scripts 16, 17 e 18 mantem, de forma
explicita e identificada, a reconstrucao historica das tabelas descritivas de
tendencia, mortalidade (SIM) e fluxo que ainda alimentam alguns indicadores do
manuscrito.

---

## Função de cada script

| Script | Função |
|---|---|
| `00_glmm_utils.R` | Utilitários compartilhados do GLMM (ajuste, ICC, MOR, calibração). Normaliza a interface entre `lme4::glmer` e `glmmTMB::glmmTMB`. |
| `01_baixar_microdatasus.R` | Download do SIH-RD (191 competências) e do SIM-DO (15 anos) pelo `microdatasus` e, em seguida, filtragem dos códigos CID do estudo (I60–I69 **e** blocos G45/G46, em ambas as fontes; residentes no RJ; 2010–2024) com gravação dos recortes leves em CSV versionado. |
| `02_montar_coorte.R` | Coorte analítica a partir dos `.rds` baixados (I60–I69 + G45/G46 completos). |
| `03_tabelas_descritivas.R` | Tabelas descritivas da coorte. |
| `04_isu_regiao_saude.R` | Índice de Swaroop-Uemura por região de saúde. |
| `05_glmm_principal.R` | GLMM principal, OR, IC95%, p-valores e FDR. |
| `06_glmm_uti.R` | Tratamento do uso de UTI (marcador de gravidade; decomposição *within/between* de Mundlak). |
| `07_auditoria_consistencia.R` | Auditoria de incongruências (SIH bruto, coorte, triangulação SIH×SIM, modelo). |
| `08_glmm_robustez.R` | Bateria de 18 cenários de robustez. |
| `09_conferencia_motores.R` | Conferência `glmmTMB` × `lme4` e adequação da aproximação de Laplace (processo isolado, `--worker`). |
| `10_figuras.R` | Figuras do Bloco 4 (OR, regiões, funnel, subtipos, UTI). |
| `11_exploratorio.R` | Exploração das variáveis não usadas no modelo principal: raça/cor, escolaridade, comorbidade, natureza jurídica, complexidade e permanência. |
| `12_auditoria_geral.R` | Bateria de auditoria do repositório: aquisição e integridade dos `.rds`, re-derivação do recorte CID versionado, coerência entre coorte e tabelas, consistência numérica, sintaxe/paths dos scripts e higiene/LGPD do Git. |
| `13_figuras_exploratorias.R` | Banco de ~25 figuras exploratórias da análise atual (séries, pirâmide, fluxo, concentração, caterpilar hospitalar, ROC, calibração, ISU, comorbidade), em `06_figuras/exploratorias/`. |
| `14_verificacao_sidra.R` | Verificação dos denominadores populacionais do IBGE/SIDRA (cobertura, fontes, interpolação, consistência com o lookup). |
| `15_deflacao_ipca.R` | Deflação dos custos do SIH para dez/2024 pelo IPCA (SIDRA 1737), lendo a coorte atual e I60–I69. |
| `16_consolidar_dados.py` | Consolidação dos microdados brutos de SIH e SIM nos CSVs largos usados pelas análises territoriais. |
| `17_analises_territoriais.py` | Tendências, taxas, fluxo, permanência e custo. |
| `18_mortalidade_sim.py` | Mortalidade populacional no SIM. |
| `19_figura_exploratorio.R` | Regenera a figura-painel do script 11 a partir dos resultados cacheados, sem reajustar os modelos (rápido). |
| `22_padronizacao_etaria.R` | Padronização etária direta das taxas de internação e mortalidade (referência: Censo 2010, IBGE/SIDRA), por região de saúde e estado. |
| `23_gerar_docx.py` | Converte o manuscrito e os documentos de submissão de Markdown para `.docx` (Word). |

**Paleta:** todas as figuras usam a paleta **viridis** (`scale_*_viridis_*` e `viridisLite::viridis()`), escolhida por ser perceptualmente uniforme, legível em escala de cinza e segura para daltonismo.

---

## Decisões metodológicas registradas

1. **Cobertura diagnóstica:** I60 a I69 completos mais os blocos completos **G45 e G46**.
   Códigos exatos: **G45.0, G45.1, G45.2, G45.3, G45.4, G45.8, G45.9** e
   **G46.0, G46.1, G46.2, G46.3, G46.4, G46.5, G46.6, G46.7, G46.8** (G45.5–G45.7 e
   G46.9 não existem na CID-10), além dos registros truncados em três dígitos (G45/G46).
   Contagens no período: G45.8 = 7.113, G46.7 = 1 e G46.8 = 1.406. A lista parcial
   anterior deixava o grupo G46 com apenas 18 internações e um OR ininterpretável.
2. **Período:** `DT_INTER` de 2010 a 2024.
3. **Unidade territorial:** as nove regiões de saúde, sem agregação por macrorregião.
4. **Motor do GLMM:** `glmmTMB` (principal), com conferência em `lme4` — ambas
   implementações de referência da aproximação de Laplace.
5. **Múltiplas comparações:** q-valores de Benjamini-Hochberg (FDR), com família global
   e famílias separadas para covariáveis de paciente e para regiões de saúde.
6. **Uso de UTI:** mantido no modelo por exigência do plano, mas tratado como
   **marcador de gravidade** e não como fator de risco. O registro cresce de 8,2% (2010)
   para 20,8% (2024) e varia de 9,5% (Serrana) a 31,7% (Noroeste), o que indica prática
   de registro.
7. **Assimetria SIH × SIM:** a coorte de internações inclui G45/G46, mas a série de
   mortalidade permanece em I60–I69. G45/G46 aparecem como causa básica em 60 de
   2.143.313 óbitos (0,0028%) — assimetria desprezível, declarada como limitação.

---

## Resultados principais

| Indicador | Valor |
|---|---|
| Internações na coorte | **295.673** |
| Óbitos intra-hospitalares | **55.827 (18,88%)** |
| Estabelecimentos (CNES) | 254 |
| Regiões de saúde | 9 |
| VPC / ICC hospitalar | **14,95%** (IC95% 12,29–18,06) |
| MOR | **2,065** (IC95% 1,911–2,253) |
| AUC condicional | 0,740 |
| Coeficientes significativos após FDR | **14 de 19** |
| ISU estadual por DCV* | **92,39%** |

**Composição:** I60–I69 = 267.746 internações (90,55%; mortalidade 19,58%);
G45/G46 = 27.927 (9,45%; 12,16%). Subtipos com maior letalidade: isquêmico (I63,
27,35%), hemorrágico (I60–I62, 26,66%) e não especificado (I64, 21,13%).

**Componente hospitalar:** σ² = 0,578; desvio-padrão hospitalar = 0,760; AIC =
252.992. Dos 206 hospitais com eventos suficientes, limites ingênuos classificariam
102 como atípicos, mas apenas **3** permanecem fora dos limites após acomodar a
variabilidade real entre serviços.

### Odds ratios ajustados (destaques)

| Covariável | OR (IC95%) | q (FDR) |
|---|---|---|
| Idade (+1 DP = 14,9 anos) | 1,460 (1,444–1,476) | < 1,0 × 10⁻³⁰⁰ |
| Hemorrágico (I60–I62) | 1,264 (1,222–1,307) | 1,23 × 10⁻⁴¹ |
| Isquêmico (I63) | 1,070 (1,023–1,119) | 4,60 × 10⁻³ |
| Caráter de urgência | 1,798 (1,679–1,924) | 1,27 × 10⁻⁶³ |
| Uso de UTI* | 3,904 (3,789–4,022) | < 1,0 × 10⁻³⁰⁰ |
| Fluxo intermunicipal | 0,951 (0,922–0,980) | 1,90 × 10⁻³ |
| Médio Paraíba (vs. Metropolitana I) | 0,467 (0,417–0,524) | 1,78 × 10⁻³⁸ |

\* OR sem leitura causal (marcador de gravidade/registro). Referências: subtipo = I64,
sexo = feminino, caráter = eletiva, região = Metropolitana I.

### Índice de Swaroop-Uemura (topo)

| Região de saúde | ISU (%) |
|---|---|
| Serrana | 93,75 |
| Metropolitana II | 93,61 |
| Noroeste | 93,51 |
| … | … |
| Baixada Litorânea | 91,50 |
| **Estado do Rio de Janeiro** | **92,39** |

*A série de mortalidade do ISU passou a incluir I60–I69 e os blocos G45/G46 (147.611 óbitos).*

A amplitude regional do ISU por DCV é de apenas 2,25 p.p. (4,68 p.p. com corte em 65
anos): a mortalidade cerebrovascular já se concentra em idades avançadas, e o
indicador tem pouco poder discriminante entre territórios.

---

## Exploração das variáveis restantes

Os microdados do SIH-RD trazem **113 colunas**; o modelo principal usa oito. A exploração
das demais (script `11`) produziu dois achados que mudam leituras correntes.

### O que não é utilizável

| Campo | Verificação | Situação |
|---|---|---|
| `INSTRU` (escolaridade) | 0% de ausência, mas **constante**: "sem instrução" em 295.672 de 295.673 | inutilizável |
| `DIAGSEC1`–`9` (comorbidade) | inexiste até 2013; de 2014 em diante cobre no máximo 17% | mede codificação, não doença |
| `INFEHOSP` | 100% vazio em 2010–2024 | inutilizável |
| `CID_ASSO` | apenas o valor `0000` | inutilizável |
| `NATUREZA` | um único valor distinto | inutilizável |
| `ESPEC` | varia, mas sem tabela oficial do DATASUS | não interpretado |
| `RACA_COR` | ausência cai de 35,4% (2010) a **0,0%** (2024) | utilizável, com ressalva |
| `NAT_JUR` | só existe a partir de 2013 | utilizável nesse período |

> **Armadilha registrada:** ausência zero não significa campo útil. `INSTRU` aparece com
> 0,00% de ausência e é perfeitamente inútil. Por isso a verificação passou a incluir o
> número de níveis e a proporção do nível dominante, não apenas o percentual de ausentes.

> **Convenção de ausente:** valores ausentes são `NA`, como o R os representa, sem rótulo
> substituto. Códigos que a fonte usa para "sem informação" ou "ignorado" (99 em
> `RACA_COR`, 9 em `INSTRU`) também viram `NA`. Cada modelo usa os casos completos das
> variáveis que emprega, e o n é reportado. As comparações de variância são feitas contra
> o modelo base **reajustado na mesma amostra**.

### O que os ajustes revelaram

**Raça/cor.** Com Branca como referência, o gradiente bruto (preta 18,26%, parda 17,94%,
branca 15,45%) **não se sustenta**: preta OR 0,982 (0,946–1,018; ns) e parda OR 0,934
(0,907–0,963; **p = 8,2 × 10⁻⁶**). A diferença bruta entre pretas e brancas era composição
de idade e subtipo. O que permanece é a **ausência**: quem tem `NA` em raça/cor apresenta
24,17% de mortalidade contra 17,13% de quem tem valor — **+7,04 p.p.**, padrão clássico de
ausência informativa.

**Natureza jurídica.** A diferença bruta é de **4,6 vezes** (administração pública 22,28%
contra entidades empresariais 4,81%). Depois do ajuste pelo perfil do paciente, o OR das
empresariais fica em **0,396** (IC95% 0,296–0,528). Ou seja, a diferença é essencialmente
**composição de casos**, não qualidade: os hospitais públicos concentram os casos graves,
o mesmo mecanismo de seleção já visto com a UTI.

**Impacto no componente hospitalar (base reajustada na mesma amostra):**

| Modelo | n | ICC base | ICC modelo | Δ ICC | Variância hospitalar explicada |
|---|---|---|---|---|---|
| M0 principal | 295.673 | — | 14,95% | — | — |
| M1 + raça/cor | 222.003 | 14,45% | 14,54% | +0,10 p.p. | −0,8% |
| M2 + natureza jurídica | 255.118 | 14,60% | 12,39% | **−2,21 p.p.** | **17,3%** |
| M3 + complexidade | 295.673 | 14,95% | 13,12% | **−1,83 p.p.** | **14,1%** |
| **M4 completo** | 195.399 | 15,12% | **11,69%** | **−3,43 p.p.** | **25,7%** |

**Natureza jurídica e complexidade do procedimento explicam, juntas, 25,7% da
heterogeneidade entre hospitais.** Cerca de **três quartos** da variação entre serviços
permanecem sem explicação por variáveis observáveis — o componente hospitalar é real e
majoritariamente não capturado pelos dados administrativos. Raça/cor praticamente não move
o ICC (+0,10 p.p.).

> **Correção registrada.** Numa primeira passagem, a natureza jurídica aparecia
> **elevando** o ICC para 16,91% e o modelo completo parecia não alterar nada. Os dois
> resultados eram artefato: a variável trazia uma categoria "não informado" que era, na
> prática, o período de 2010–2012, quando o campo não existia, e que inflava a variância
> hospitalar. Além disso, os modelos eram comparados em amostras diferentes. Com ausente
> tratado como `NA` e a base reajustada na mesma amostra, as duas conclusões se invertem.

---

## Robustez e conferência entre motores

- **18 cenários** de robustez, todos convergidos. Fora dos extremos, o ICC fica entre
  14,4% e 16,5% (principal: 14,95%). Retirar a UTI eleva o ICC para 17,25%; restringir
  a hospitais com 10+ óbitos reduz para 11,48%.
- **Estrutura multinível é necessária:** o modelo agrupado sem efeito aleatório tem
  ΔAIC ≈ **7.851** pior que o GLMM, com um único parâmetro adicional.
- **Conferência `glmmTMB` × `lme4`** (subamostra de 20.000): σ² = 0,25490 vs 0,25479
  (0,042%); log-verossimilhanças diferem em 0,0006. Quadratura de Gauss-Hermite
  (`nAGQ = 11`) altera OR em no máximo 0,14% → aproximação de Laplace adequada.

> ⚠️ Carregar `glmmTMB` e `lme4` na mesma sessão R encerra o processo sem mensagem de
> erro, mesmo com 20 mil registros. Por isso a conferência roda em processo isolado
> (`09_conferencia_motores.R --worker`).

---

## Limitações

1. **Codificação do subtipo:** I64 responde por 56,6% da coorte — mede qualidade de
   codificação tanto quanto fisiopatologia.
2. **Mortalidade registrada em AIT:** G45 tem 11,99% de mortalidade intra-hospitalar,
   valor clinicamente implausível para evento transitório.
3. **Ausência de gravidade clínica:** sem sinais vitais, escalas, exames ou neuroimagem.
4. **Comorbidade incompleta:** o diagnóstico secundário inexiste até 2013 e, de 2014 em
   diante, cobre no máximo 17% dos registros — mede completude de codificação, não doença.
5. **Reinternações:** o SIH-RD é anonimizado; internações tratadas como independentes.
6. **Áreas pequenas:** 68 estabelecimentos com <100 internações em 15 anos e 26 sem
   nenhum óbito.
7. **Raça/cor e escolaridade:** escolaridade é inutilizável (campo constante); raça/cor tem
   24,9% de ausência **informativa** (quem tem `NA` apresenta 24,17% de mortalidade contra
   17,13% de quem tem valor) e ausência decrescente no tempo, de 35,4% (2010) a 0,0%
   (2024). Valores ausentes são `NA`, sem rótulo substituto, e os modelos usam casos
   completos. Nenhuma das duas entrou no modelo principal.
8. **Generalização:** restrito ao Rio de Janeiro, sem validação externa.
9. **Sem leitura causal:** desenho observacional.
10. **Sem mapa coroplético:** não há shapefile das regiões de saúde do RJ no projeto.

---

## Limpeza realizada

Em 2 de outubro de 2026 foram removidos cerca de 320 MB de arquivos obsoletos:

Em **3 de outubro de 2026** os scripts foram reorganizados e todos passaram a residir em
`02_scripts/`. A verificação de SIDRA e a deflação
pelo IPCA foram promovidas a análise atual (`14_verificacao_sidra.R` e
`15_deflacao_ipca.R`, este último reescrito em R sobre a coorte); as análises territoriais
de apoio foram renomeadas sem sufixo (`16_consolidar_dados.py`,
`17_analises_territoriais.py` e `18_mortalidade_sim.py`). A pasta
de figuras foi organizada em `manuscrito/`, `exploratorias/` e `suplementares/`, e o
banco de ~25 figuras exploratórias foi gerado pelo script `13_figuras_exploratorias.R`.

Também em 3 de outubro de 2026 foram removidos os **arquivos volumosos antigos** de
`01_dados/processados/` (`sih_cerebrovascular_2010_2024.csv`, ~172 MB;
`sim_cerebrovascular_2010_2024.csv`, ~62 MB; `sih_g45_g46_2010_2024.csv`). Eles são
**regeneráveis** pela cadeia de apoio (`16_consolidar_dados.py` →
`18_mortalidade_sim.py` → `17_analises_territoriais.py`), mas não são
mais armazenados. O script `11_exploratorio.R` ganhou o atalho
`GLMM_SO_FIGURAS=1`, que refaz apenas a figura-painel a partir dos resultados cacheados
(sem reajustar os modelos, que levam mais de uma hora).

> `13_documentos_referencia/` e `08_manuscrito/manuscrito.md` **não são versionados**
> a pedido; permanecem apenas no disco local.

---

## Especificação do modelo multinível

O modelo logístico multinível da mortalidade intra-hospitalar é especificado por:

```
logit P(óbito) = β₀ + β'X + u_j

X   : idade padronizada, sexo, subtipo diagnóstico, caráter da internação,
      uso de UTI, fluxo intermunicipal e região de saúde de residência
u_j : intercepto aleatório por estabelecimento, u_j ~ N(0, σ²)
```

O ajuste usa `glmmTMB` (aproximação de Laplace), com conferência em `lme4` e quadratura
adaptativa de Gauss-Hermite. A heterogeneidade hospitalar é resumida pelo VPC/ICC =
σ²/(σ²+π²/3) e pela MOR = exp(√(2σ²)·Φ⁻¹(0,75)).

---

## Pendências

**Concluído nesta fase:** padronização etária direta (script 22; `tab28`),
ISU alinhado a I60–I69 + G45/G46, consistência dos custos conferida, sensibilidade a I64
já existente na robustez (S8), `sessionInfo`/lista de pacotes, backup do manuscrito,
otimização do script 01 (não tenta mais a competência 2025-12) e do script 11
(`GLMM_SO_FIGURAS=1`).

**Documentos de submissão** gerados em `08_manuscrito/` (não versionados): folha de
rosto, carta de apresentação, declaração de ética/LGPD, termo de autoria e as versões
`.docx` do manuscrito e dos documentos.

⬅️ [Voltar ao README do monorepo](../README.md)
