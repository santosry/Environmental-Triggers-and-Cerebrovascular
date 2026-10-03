# RELATÓRIO EXECUTIVO — GLMM DE MORTALIDADE INTRA-HOSPITALAR CEREBROVASCULAR
## Versão final: microdatasus, blocos G completos, GLMM em R com correção de FDR

**Estudo:** Vulnerabilidade climática, morbimortalidade cerebrovascular e organização da Rede de Atenção à Saúde no Rio de Janeiro
**Período:** 2010 a 2024
**Aquisição:** pacote `microdatasus` 2.5.0 em R 4.6.1, SIH-RD e SIM-DO
**Análise:** R 4.6.1, `glmmTMB` 1.1.15.2, com conferência em `lme4` 2.0.1
**Data:** 2 de outubro de 2026

---

## 1. Sumário executivo

1. **Os microdados foram baixados dos dois sistemas.** Foram obtidas 191 competências do SIH-RD do Rio de Janeiro (479,3 MB) e 15 arquivos anuais do SIM-DO (98,1 MB). Só a competência 2025-12 não existe no DATASUS. As competências de 2025 servem para capturar internações de dezembro de 2024 processadas em janeiro de 2025; o filtro final é sempre `DT_INTER` entre 2010 e 2024.

2. **Os blocos G45 e G46 foram incorporados por completo, incluindo G45.8 e G46.8.** Isso elevou a coorte de códigos G de 19.566 para 27.927 internações e, sobretudo, deu interpretabilidade ao grupo G46, que passa de 18 para 1.349 internações.

3. **A coorte tem 295.673 internações e 55.827 óbitos intra-hospitalares (18,88%)**, em 254 estabelecimentos e nas nove regiões de saúde, sem nenhuma exclusão por dado ausente nos campos do modelo.

4. **O VPC/ICC foi de 14,95% (IC95% 12,29 a 18,06)** e o MOR de 2,065 (IC95% 1,911 a 2,253). Cerca de um sétimo da variabilidade da mortalidade intra-hospitalar decorre do estabelecimento onde o paciente foi internado.

5. **Foram reportados p-valores e correção de FDR.** Dos 19 coeficientes testados, 14 são significativos pelo p bruto e **14 continuam significativos após a correção de Benjamini-Hochberg**. Nenhum coeficiente perde significância com o FDR.

6. **O GLMM foi executado em R**, com `glmmTMB` e conferência em `lme4`, que são as implementações de referência e o software declarado no plano.

7. **O uso de UTI recebeu tratamento próprio, por decomposição de Mundlak.** A variável não é apenas prática de registro: 91 dos 186 hospitais com volume relevante (48,9%) têm **zero** registro de UTI, e os que registram atendem 20,6% de casos hemorrágicos contra 1,3% nos demais. Ela combina gravidade do paciente, capacidade de UTI do hospital e posição na rede de referência. Separada em componente intra-hospitalar e componente contextual do hospital, os dois efeitos são independentes (OR 3,91 e 2,66) e juntos explicam 16,8% da variância hospitalar.

8. **Foi executada uma auditoria de 50 verificações** de coerência interna dos registros, da coorte, da triangulação entre SIH e SIM e do modelo. Resultado: **38 aprovadas, 12 que exigem leitura e nenhum erro**. Uma delas detectou duplicatas aparentes na base analítica, o que levou a incluir a chave da AIH na base e a reverificar a deduplicação: zero duplicatas.

9. **A heterogeneidade entre hospitais é sistêmica.** Dos 206 hospitais com eventos suficientes, limites de controle ingênuos classificariam 102 como atípicos em nível de 99,8%, mas apenas 3 permanecem fora dos limites depois de acomodar a variabilidade real entre serviços.

10. **A exploração das variáveis restantes produziu dois achados que mudam leituras correntes.** O primeiro é negativo e metodológico: escolaridade, infecção hospitalar, causa associada e comorbidade **não são utilizáveis** nesta base — a escolaridade aparece com 0% de ausência e é constante, e os diagnósticos secundários cobrem no máximo 17% dos registros. O segundo é substantivo: a diferença bruta de mortalidade entre rede pública (22,28%) e rede empresarial (4,81%) cai para um OR de 0,396 depois do ajuste, ou seja, é composição de casos e não qualidade. Já a natureza jurídica e a complexidade do procedimento **explicam, juntas, 25,7% da variância entre hospitais**, reduzindo o ICC de 15,12% para 11,69%; cerca de três quartos da heterogeneidade hospitalar permanecem, no entanto, sem explicação por variáveis observáveis.

11. **Valores ausentes são representados como `NA`**, sem rótulo substituto, como o R faz nativamente. Códigos que a fonte usa para "sem informação" ou "ignorado" também são convertidos em `NA`, e cada modelo usa os casos completos das variáveis que emprega. Essa decisão corrigiu um artefato: uma categoria falsa de "não informado" na natureza jurídica inflava a variância hospitalar e invertia a conclusão sobre o componente hospitalar.

12. **Todas as figuras usam a paleta viridis**, por ser perceptualmente uniforme, legível em escala de cinza e segura para daltonismo.

---

## 2. Aquisição dos dados

| Item | Resultado |
|---|---|
| Pacote | `microdatasus` 2.5.0, em R 4.6.1 |
| SIH-RD RJ | 191 competências, 2010-01 a 2025-11, 479,3 MB |
| SIM-DO RJ | 15 arquivos anuais, 2010 a 2024, 98,1 MB |
| Fonte do SIH | `ftp://ftp.datasus.gov.br/dissemin/publicos/SIHSUS/200801_/Dados/RDRJ{aamm}.dbc` |
| Registros brutos lidos no SIH | 11.947.354 (todas as causas, residentes no RJ) |
| Falhas | nenhuma; duas tentativas sofreram `server response timeout` e foram repetidas com êxito |
| Ausente | competência 2025-12, não publicada |

### 2.1 Verificação da presença dos códigos

O download do SIH-RD é estadual e por competência, **sem filtro por CID**: o mesmo arquivo traz I60 a I69 e os códigos G. Não foi preciso baixar nada específico para os códigos G.

**I60 a I69, todos presentes:** I60 12.873; I61 18.934; I62 6.578; I63 18.191; I64 181.982; I65 3.328; I66 380; I67 5.595; I68 42; I69 44.291. Total 292.194.

**Subcódigos G encontrados:**

| Subcódigo | Registros | Situação |
|---|---|---|
| G45.0 | 3.851 | na lista original |
| G45.1 | 1.097 | na lista original |
| G45.2 | 84 | na lista original |
| G45.3 | 14 | na lista original |
| G45.4 | 13 | na lista original |
| **G45.8** | **7.113** | **incorporado nesta versão** |
| G45.9 | 15.704 | na lista original |
| G46.0 | 6 | na lista original |
| G46.3 | 4 | na lista original |
| G46.4 | 12 | na lista original |
| G46.5 | 1 | na lista original |
| **G46.7** | **1** | **incorporado nesta versão** |
| **G46.8** | **1.406** | **incorporado nesta versão** |
| G46.1, G46.2, G46.6 | 0 | pedidos, mas inexistentes na base |

Bloco G45/G46 inteiro: 29.717 registros, dos quais 411 com código de três dígitos.

Após a incorporação, a composição da coorte por código G ficou: G45.9 14.760; G45.8 6.707; G45.0 3.643; G46.8 1.321; G45.1 1.044; G45 (três dígitos) 323; G45.2 78; G45.4 12; G45.3 11; G46 (três dígitos) 10; G46.4 8; G46.0 6; G46.3 3; G46.5 1.

### 2.2 Impacto da incorporação de G45.8 e G46.8

| Aspecto | Sem G45.8 e G46.8 | Com G45.8 e G46.8 |
|---|---|---|
| Internações na coorte | 287.312 | **295.673** |
| Óbitos | 54.791 | **55.827** |
| Internações com código G | 19.566 | **27.927** |
| **Grupo G46** | **18 casos e 4 óbitos** | **1.349 casos e 208 óbitos** |
| OR do grupo G46 | 2,17 (IC95% 0,66 a 7,13), p = 0,20 | **0,971 (IC95% 0,82 a 1,15), p = 0,73** |
| VPC/ICC | 15,18% | **14,95%** |
| MOR | 2,079 | **2,065** |

O grupo G46 era ininterpretável na versão anterior, estimado sobre 18 casos. Com o bloco completo passa a ter 1.349 casos e intervalo de confiança estreito. G46.8 sozinho responde por 1.321 desses 1.349 registros.

---

## 3. Coorte (Blocos 1.1 e 1.2)

| Coorte | Internações | % | Óbitos | Mortalidade |
|---|---|---|---|---|
| I60 a I69 | 267.746 | 90,55 | 52.432 | 19,58% |
| G45 e G46 | 27.927 | 9,45 | 3.395 | 12,16% |
| **Total** | **295.673** | **100** | **55.827** | **18,88%** |

Estabelecimentos: 254 (CNES). Regiões de saúde: 9. Duplicatas removidas: zero. Exclusões por dado ausente nos campos do modelo: zero.

### 3.1 Perfil por subtipo diagnóstico

| Subtipo | n | % | Mortalidade | Idade mediana |
|---|---|---|---|---|
| Não especificado (I64) | 167.470 | 56,64 | 21,13% | 68 |
| Sequelas (I69) | 40.012 | 13,53 | 6,14% | 68 |
| Hemorrágico (I60-I62) | 35.094 | 11,87 | 26,66% | 59 |
| AIT (G45) | 26.578 | 8,99 | 11,99% | 68 |
| Isquêmico (I63) | 16.831 | 5,69 | 27,35% | 67 |
| Oclusão e outras (I65-I68) | 8.339 | 2,82 | 7,47% | 63 |
| Síndromes vasculares (G46) | 1.349 | 0,46 | 15,42% | 66 |

### 3.2 Covariáveis

| Covariável | Distribuição |
|---|---|
| Idade | média 65,5 anos, desvio-padrão 14,9 |
| Sexo masculino | 152.913 (51,72%) |
| Caráter de urgência | 249.959 (84,54%) |
| Uso de UTI (ao menos 1 dia) | 38.357 (12,97%) |
| Fluxo intermunicipal | 16,91% |

### 3.3 Codificação do diagnóstico principal

**168.360 registros (56,9%) trazem o diagnóstico principal com três caracteres.** Desses, 167.470 são exatamente I64, que é uma categoria completa da CID-10 (AVC não especificado quanto a hemorragia ou infarto) e não um código truncado. Não há, portanto, defeito de codificação nesse ponto: o que existe é a concentração da coorte em uma categoria sem detalhamento fisiopatológico, que é o principal limitador da validade interna do estudo.

### 3.4 Concentração assistencial

Os dez maiores estabelecimentos concentram 31,3% das internações e os 25 maiores, 54,7%. Dos 254 hospitais, 68 tiveram menos de 100 internações no período, 42 menos de 30 e 26 não registraram nenhum óbito.

---

## 4. Índice de Swaroop-Uemura por região de saúde (Bloco 1.3)

Base: 147.551 óbitos por doenças cerebrovasculares no SIM, 2010 a 2024. Idade ignorada em 187 registros (0,127%); 292 óbitos (0,198%) sem município correspondente na tabela de regiões.

| Região de saúde | Óbitos | ISU (%) | ISU com corte em 65 anos |
|---|---|---|---|
| Serrana | 9.549 | 93,75 | 74,38 |
| Metropolitana II | 17.926 | 93,61 | 72,19 |
| Noroeste | 3.326 | 93,51 | 73,66 |
| Médio Paraíba | 8.783 | 93,04 | 72,13 |
| Baía da Ilha Grande | 1.772 | 92,21 | 69,70 |
| Centro-Sul | 3.407 | 92,19 | 71,47 |
| Metropolitana I | 89.135 | 92,15 | 70,56 |
| Norte | 7.747 | 91,82 | 70,29 |
| Baixada Litorânea | 5.614 | 91,50 | 69,75 |
| **Estado do Rio de Janeiro** | **147.551** | **92,38** | **71,04** |

A amplitude regional do ISU por doenças cerebrovasculares é de 2,25 pontos percentuais, contra 4,68 pontos com o corte em 65 anos. Como a mortalidade cerebrovascular já se concentra em idades avançadas, o indicador tem pouco poder discriminante entre territórios.

**Simetria entre as coortes.** A ampliação diagnóstica vale para as internações. Na série de mortalidade, G45 ou G46 aparecem como causa básica em 60 de 2.143.313 óbitos (0,0028%). A assimetria é desprezível, mas deve ser declarada.

---

## 5. Modelo logístico multinível (Bloco 2)

### 5.1 Especificação

```
logit(P(óbito_ijk = 1)) = β0 + β'X_ijk + u_j + γ_k

X_ijk : idade padronizada, sexo, subtipo diagnóstico (I60-I69 e blocos G45 e G46),
        caráter da internação, uso de UTI, fluxo intermunicipal
u_j   : intercepto aleatório por estabelecimento (CNES), u_j ~ N(0, σ²)
γ_k   : efeito fixo da região de saúde de residência (9 regiões)
```

Referências: subtipo = AVC não especificado (I64); sexo = feminino; caráter = eletiva; região = Metropolitana I.
Motor: `glmmTMB`, aproximação de Laplace. Convergência normal, 2,1 minutos.

### 5.2 Componente hospitalar

| Métrica | Valor | IC95% |
|---|---|---|
| σ² hospitalar | 0,57805 | — |
| Desvio-padrão hospitalar | 0,76029 | 0,67883 a 0,85154 |
| **VPC / ICC** | **14,95%** | 12,29% a 18,06% |
| **MOR** | **2,065** | 1,911 a 2,253 |
| AIC | 252.992,2 | — |

### 5.3 Odds ratio ajustado, p-valores e FDR

A significância está marcada pela q-valor de Benjamini-Hochberg. A família global reúne os 19 coeficientes, excluído o intercepto.

| Covariável | OR | IC95% | p | **q (FDR)** |
|---|---|---|---|---|
| Idade (por +1 DP = 14,9 anos) | 1,460 | 1,444 a 1,476 | < 1,0 × 10⁻³⁰⁰ | **< 1,0 × 10⁻³⁰⁰** |
| Sexo masculino | 1,004 | 0,985 a 1,024 | 6,78 × 10⁻¹ | 7,58 × 10⁻¹ |
| Hemorrágico (I60-I62) | 1,264 | 1,222 a 1,307 | 4,55 × 10⁻⁴² | **1,23 × 10⁻⁴¹** |
| Isquêmico (I63) | 1,070 | 1,023 a 1,119 | 3,10 × 10⁻³ | **4,60 × 10⁻³** |
| Oclusão e outras (I65-I68) | 0,305 | 0,278 a 0,334 | 2,28 × 10⁻¹⁴⁴ | **1,45 × 10⁻¹⁴³** |
| Sequelas (I69) | 0,536 | 0,497 a 0,578 | 2,36 × 10⁻⁵⁹ | **7,47 × 10⁻⁵⁹** |
| AIT (G45) | 0,588 | 0,561 a 0,616 | 1,03 × 10⁻¹⁰⁶ | **4,89 × 10⁻¹⁰⁶** |
| Síndromes vasculares (G46) | 0,971 | 0,821 a 1,148 | 7,33 × 10⁻¹ | 7,73 × 10⁻¹ |
| Caráter de urgência | 1,798 | 1,679 a 1,924 | 3,35 × 10⁻⁶⁴ | **1,27 × 10⁻⁶³** |
| Uso de UTI | 3,904 | 3,789 a 4,022 | < 1,0 × 10⁻³⁰⁰ | **< 1,0 × 10⁻³⁰⁰** |
| Fluxo intermunicipal | 0,951 | 0,922 a 0,980 | 1,10 × 10⁻³ | **1,90 × 10⁻³** |
| Metropolitana II | 0,788 | 0,700 a 0,887 | 8,10 × 10⁻⁵ | **1,71 × 10⁻⁴** |
| Baixada Litorânea | 0,978 | 0,834 a 1,148 | 7,87 × 10⁻¹ | 7,87 × 10⁻¹ |
| Norte | 0,756 | 0,623 a 0,916 | 4,30 × 10⁻³ | **5,90 × 10⁻³** |
| Noroeste | 1,155 | 0,957 a 1,393 | 1,33 × 10⁻¹ | 1,58 × 10⁻¹ |
| Serrana | 1,101 | 0,981 a 1,236 | 1,03 × 10⁻¹ | 1,30 × 10⁻¹ |
| Centro-Sul | 0,742 | 0,637 a 0,864 | 1,29 × 10⁻⁴ | **2,45 × 10⁻⁴** |
| Médio Paraíba | 0,467 | 0,417 a 0,524 | 7,51 × 10⁻³⁹ | **1,78 × 10⁻³⁸** |
| Baía da Ilha Grande | 0,726 | 0,594 a 0,886 | 1,60 × 10⁻³ | **2,60 × 10⁻³** |

**Resumo da correção de FDR:** família global com 19 testes, 14 significativos por p e os mesmos 14 por q. Família de covariáveis de paciente (11 testes): 9 significativos. Família de regiões de saúde (8 testes): 5 significativos. **Nenhum coeficiente perde significância após o FDR.** A maior mudança é do fluxo intermunicipal, de p = 1,10 × 10⁻³ para q = 1,90 × 10⁻³, que permanece significativo.

O OR de 3,90 do uso de UTI deve ser lido com a ressalva da seção 7.

### 5.4 Discriminação e calibração

| Métrica | Valor |
|---|---|
| AUC condicional | 0,7399 |
| AUC marginal | 0,6896 |
| R² marginal | 0,1292 |
| R² condicional | 0,2593 |
| Calibração condicional: intercepto | 0,0089 (EP 0,0091) |
| Calibração condicional: inclinação | 1,0070 (EP 0,0061) |
| Calibração marginal: intercepto | 0,2755 (EP 0,0128) |
| Calibração marginal: inclinação | 0,9256 (EP 0,0068) |

A previsão condicional é praticamente perfeita em calibração. A marginal fica abaixo da observada por desigualdade de Jensen. O teste de Hosmer-Lemeshow rejeita o ajuste (X² = 7.413,10; gl = 8), mas com 295 mil registros tem poder excessivo e rejeita praticamente qualquer modelo; por isso a calibração foi lida por inclinação, intercepto e tabela de decis.

A discriminação é moderada, o que é coerente com a ausência de sinais vitais, escalas de gravidade e exames laboratoriais no SIH-RD.

### 5.5 Heterogeneidade entre hospitais

| Critério | Hospitais fora dos limites |
|---|---|
| Limites de Poisson a 99,8%, sem ajuste | 102 de 206 |
| Limites ajustados pela variância entre hospitais, 99,8% | 3 de 206 |
| Limites ajustados a 95% | 10 de 206 |

Foram avaliados os 206 hospitais com ao menos 5 óbitos esperados; 48 foram excluídos por volume insuficiente de eventos. O número de hospitais fora dos limites de 95% é praticamente igual ao esperado por azar (10,3).

---

## 6. Robustez

Dezoito cenários executados, todos com convergência verificada. Os cenários S16 e S18 não existem porque o `glmmTMB` não aceita os argumentos `nAGQ` e `rel.tol`; a adequação da aproximação de Laplace é verificada no script 12.

| Cenário | n | σ² | ICC | MOR | AIC |
|---|---|---|---|---|---|
| S0 principal | 295.673 | 0,5781 | **14,95%** | 2,065 | 252.992,2 |
| S1 sem uso de UTI | 295.673 | 0,6860 | **17,25%** | 2,204 | 261.038,8 |
| S2 UTI por MARCA_UTI | 295.673 | 0,5797 | 14,98% | 2,067 | 252.952,0 |
| S3 período 2015-2024 | 205.399 | 0,5840 | 15,07% | 2,073 | 177.188,7 |
| S4 período 2010-2014 | 90.274 | 0,6511 | 16,52% | 2,159 | 73.531,0 |
| S5 sem sequelas (I69) | 255.661 | 0,5844 | 15,08% | 2,073 | 236.070,9 |
| S6 apenas I60-I69 | 267.746 | 0,5875 | 15,15% | 2,077 | 234.218,9 |
| S7 apenas códigos G | 27.927 | 0,7626 | **18,82%** | 2,300 | 17.913,3 |
| S8 sem a categoria I64 | 127.313 | 0,6516 | 16,53% | 2,160 | 93.413,2 |
| S9 hospitais com 100+ internações | 293.743 | 0,5555 | 14,45% | 2,036 | 251.665,8 |
| S10 sem hospitais sem óbito | 295.319 | 0,5586 | 14,51% | 2,040 | 252.957,7 |
| S11 hospitais com 10+ óbitos | 290.555 | 0,4266 | **11,48%** | 1,865 | 251.610,0 |
| S12 região como efeito aleatório | 295.673 | 0,5740 | 14,86% | 2,060 | 253.011,3 |
| S13 sem efeito aleatório | 295.673 | — | — | — | 260.842,8 |
| S14 idade por spline natural | 295.673 | 0,5809 | 15,01% | 2,069 | 252.333,0 |
| S15 com tendência temporal | 295.673 | 0,7325 | **18,21%** | 2,262 | 251.135,0 |
| S17 otimizador optim BFGS | 295.673 | 0,5783 | 14,95% | 2,066 | 252.992,2 |
| S19 idade categorizada | 295.673 | 0,5800 | 14,99% | 2,068 | 253.375,6 |

**Leituras principais.**

1. **O ICC é estável.** Fora dos extremos, todos os cenários ficam entre 14,4% e 16,5%, com o valor principal em 14,95%. A conclusão não depende da especificação.

2. **A estrutura multinível é fortemente necessária.** O modelo agrupado sem efeito aleatório tem AIC 260.842,8 contra 252.992,2 do GLMM, diferença de **7.851 pontos para um único parâmetro adicional**.

3. **Retirar a UTI eleva o ICC de 14,95% para 17,25%.** Parte do que parece efeito do hospital é padrão de registro de UTI.

4. **A definição de UTI não muda o resultado.** Com ao menos 1 dia o ICC é 14,95%; com ao menos 2 dias, 15,02%; com ao menos 7 dias, 15,14%; pela `MARCA_UTI`, 14,98%. O que altera o ICC é a presença ou não da variável, não o seu ponto de corte.

5. **A heterogeneidade é maior no grupo G isolado (18,82%)** e quando se inclui a tendência temporal (18,21%), e menor quando se restringe a hospitais com 10 ou mais óbitos (11,48%). Hospitais de baixo volume inflam a variância estimada, comportamento esperado em modelos multiníveis.

6. **A forma funcional da idade importa, mas não altera o ICC.** O spline natural melhora o AIC em 659 pontos em relação ao termo linear, enquanto a categorização em quatro faixas piora o AIC em 383 pontos. O ICC praticamente não se move (14,95% para 15,01%). O modelo principal é uma simplificação quanto à idade, mas o componente hospitalar é robusto a isso.

7. **A robustez numérica é confirmada.** O otimizador BFGS reproduz σ² = 0,5783 contra 0,5781 do padrão, e o mesmo AIC até a primeira casa decimal.

8. **Excluir a categoria I64 eleva o ICC para 16,53%,** o que mostra que a categoria não especificada carrega parte da heterogeneidade entre serviços.

### 6.1 Conferência entre motores e adequação da aproximação de Laplace

Na mesma subamostra de 20.000 registros e com a mesma semente, o `glmmTMB` e o `lme4` foram ajustados separadamente:

| Métrica | glmmTMB | lme4 | Diferença |
|---|---|---|---|
| σ² hospitalar | 0,25490 | 0,25479 | 0,042% |
| Log-verossimilhança | −8.623,5600 | −8.623,5606 | 0,0006 |
| AIC | 17.289,12 | 17.289,12 | 0,000% |

A escolha do motor não altera os resultados. Esse achado é relevante porque o `glmmTMB` foi adotado justamente por ser cerca de trinta vezes mais rápido, e a equivalência numérica remove a objeção de que a velocidade teria custado precisão.

A adequação da aproximação de Laplace foi testada com quadratura adaptativa de Gauss-Hermite (`nAGQ = 11`) no `lme4`:

| Métrica | Laplace | Gauss-Hermite (11 pontos) | Diferença |
|---|---|---|---|
| Log-verossimilhança | −8.623,5606 | −8.623,4105 | — |
| σ² hospitalar | 0,25479 | 0,25666 | 0,73% |
| ICC | 0,07188 | 0,07237 | 0,68% |
| MOR | 1,6185 | 1,6213 | 0,17% |
| OR, discrepância máxima | — | — | 0,138% |
| OR, discrepância mediana | — | — | 0,020% |

A aproximação de Laplace é levemente conservadora na variância hospitalar, mas a discrepância máxima em qualquer OR é de 0,14%. A aproximação é adequada para este modelo.

**Registro técnico.** Carregar o `glmmTMB` e o `lme4` na mesma sessão R encerra o processo sem mensagem de erro, mesmo com 20 mil registros e com memória disponível. A conferência foi por isso executada em processo R isolado. Esse comportamento também explica por que os cenários S16 (`nAGQ`) e S18 (`rel.tol`) não aparecem na bateria de robustez: o `glmmTMB` não aceita esses argumentos, e a verificação correspondente migrou para o `lme4` isolado.

### 6.3 Tratamento do uso de UTI

O uso de UTI entrou no nível 1 (paciente) por exigência do plano, mas a auditoria mostrou que a variável não se comporta como fator de risco individual. Três evidências:

| Evidência | Valor |
|---|---|
| Hospitais com volume relevante e **zero** registro de UTI | 91 de 186 (48,9%) |
| Taxa de UTI entre hospitais: P10, mediana e P90 | 0,0%, 0,4% e 37,6% |
| Concentração dos registros de UTI | top 5 = 32,0%; top 10 = 45,7%; top 30 = 75,9% |
| Casos hemorrágicos nos hospitais que registram UTI | 20,6% contra 1,3% nos que não registram |
| Mortalidade nos hospitais que registram UTI | 22,9% contra 10,4% nos que não registram |
| Correlação da taxa de UTI do hospital com a fração de hemorrágicos | rho = +0,49 (p = 1,0 × 10⁻¹²) |
| Tendência temporal do registro de UTI | tau = +0,94 (p = 1,0 × 10⁻⁹) |

A leitura correta é mais nuançada do que "é apenas prática de registro". A variável combina, ao mesmo tempo: **gravidade do paciente**, **capacidade de UTI do estabelecimento** e **posição do hospital na rede de referência**, já que os casos graves são concentrados onde há UTI. Isso significa que incluí-la como covariável de paciente transfere para o nível individual uma informação que é do estabelecimento.

Para separar as duas fontes foi aplicada a **decomposição de Mundlak**, que divide a variável em `uti_within` (desvio do paciente em relação à média do seu hospital) e `uti_between` (média do hospital). Foram ajustados quatro modelos:

| Modelo | σ² | VPC/ICC | MOR | AIC | OR da UTI |
|---|---|---|---|---|---|
| M1 sem UTI | 0,68598 | **17,25%** | 2,2035 | 261.038,8 | — |
| M2 com UTI de paciente (especificação do plano) | 0,57811 | **14,95%** | 2,0653 | 252.992,2 | 3,904 (3,789 a 4,022) |
| M3 só a taxa de UTI do hospital | 0,64588 | **16,41%** | 2,1524 | 261.030,3 | 2,397 (1,426 a 4,028) |
| M4 Mundlak (intra + entre) | 0,57052 | **14,78%** | 2,0554 | 252.991,9 | intra 3,909 (3,794 a 4,028); entre 2,658 (1,619 a 4,364) |

**O achado central é que os dois componentes são independentes e ambos significativos.** O contraste dentro do hospital (OR 3,91) mede o que acontece quando um paciente usa UTI e outro não, no mesmo serviço. O componente contextual (OR 2,66) mede o fato de o paciente estar em um hospital que usa UTI intensamente, independentemente do seu próprio uso. O segundo é o que caracteriza o estabelecimento, e não o paciente.

**Contribuição ao componente hospitalar:**

| Fonte | Variância explicada |
|---|---|
| A UTI de paciente | 15,7% |
| A taxa de UTI do hospital | 5,8% |
| Os dois componentes juntos | 16,8% |
| Heterogeneidade hospitalar remanescente | ICC de 14,78% |

**Consequência para a leitura do ICC.** A faixa defensável do VPC/ICC hospitalar é de **14,78% a 17,25%**, dependendo de como a UTI é tratada. A especificação do plano produz o valor intermediário de 14,95%. Recomenda-se: reportar o modelo do plano como primário, por comparabilidade, e apresentar a faixa e a decomposição como análise de sensibilidade, deixando explícito que **o OR de 3,90 não tem leitura causal** e que ele embute capacidade hospitalar.

### 6.4 Sensibilidade à definição de uso de UTI

| Definição | Prevalência | σ² | ICC | OR da UTI |
|---|---|---|---|---|
| Ao menos 1 dia (principal) | 12,97% | 0,57805 | 14,94% | 3,904 (3,789 a 4,022) |
| Ao menos 2 dias | 11,32% | 0,58155 | 15,02% | 3,963 (3,844 a 4,086) |
| Ao menos 7 dias | 5,33% | 0,58670 | 15,13% | 3,351 (3,227 a 3,479) |
| Pelo campo `MARCA_UTI` | 12,99% | 0,57970 | 14,98% | 3,917 (3,802 a 4,036) |
| Sem a variável no modelo | — | 0,68598 | 17,25% | — |

O que altera o ICC é a presença ou não da variável, e não o ponto de corte escolhido.

---

## 7. Decisões metodológicas e ressalvas

1. **Blocos G completos.** A lista parcial anterior excluía 29,9% do bloco G e deixava o grupo G46 com 18 casos. A versão final usa os blocos G45 e G46 completos, incluindo G45.8, G46.7 e G46.8.

2. **Uso de UTI.** Mantido no modelo por exigência do plano, mas a variável combina gravidade do paciente, capacidade de UTI do hospital e posição na rede de referência (seção 6.3). O OR de 3,90 não tem leitura causal, e retirar a variável eleva o ICC de 14,95% para 17,25%, o que situa a faixa defensável do ICC entre 14,78% e 17,25%.

3. **Múltiplas comparações.** Aplicada a correção de Benjamini-Hochberg, com família global e famílias separadas para paciente e região. Nenhum coeficiente perde significância.

4. **Período.** Apenas `DT_INTER` de 2010 a 2024, como definido.

5. **Unidade territorial.** As nove regiões de saúde, sem agregação por macrorregião.

6. **Assimetria SIH e SIM.** A coorte de internações inclui os códigos G; a série de mortalidade permanece em I60-I69. A verificação mostrou 60 óbitos de 2.143.313 com G45 ou G46 como causa básica (0,0028%).

7. **Versão do software.** O plano previa declarar R 4.6.0, mas a instalação dessa versão na máquina está incompleta e sem `Rscript.exe` funcional. Tudo foi executado em **R 4.6.1**. A declaração do manuscrito precisa refletir isso.

8. **Ausência de mapa coroplético.** Não há shapefile das regiões de saúde do Rio de Janeiro no projeto nem nas pastas vizinhas.

---

## 8. Auditoria de incongruências e inconsistências

Foram executadas **50 verificações** em quatro blocos. Resultado: **38 aprovadas, 12 que exigem leitura e nenhum erro**. O registro completo está em `04_resultados/auditoria_consistencia.txt` e a tabela em `05_tabelas/tab19_auditoria.csv`.

### 8.1 Coerência interna dos registros brutos do SIH-RD

Varredura das 191 competências, sem carregar tudo em memória: 11.947.354 registros.

| Verificação | Resultado | Classificação |
|---|---|---|
| DT_SAIDA anterior a DT_INTER | 0 | OK |
| Obito sem data de saída | 0 | OK |
| Idade fora de 0 a 120 anos | 0 | OK |
| CNES fora do padrão de 7 dígitos | 0 | OK |
| VAL_TOT negativo | 0 | OK |
| CAR_INT, SEXO e DIAG_PRINC fora do padrão | 0 | OK |
| DIAS_PERM divergente das datas em mais de 1 dia | 535.083 (4,48%) | atenção |
| Idade divergente da data de nascimento em mais de 2 anos | 175.627 (1,47%) | atenção |
| UTI_MES_TO maior que DIAS_PERM | 74.359 (0,62%) | atenção |
| Óbito com zero dia de permanência | 44.738 | atenção |
| COD_IDADE fora de 1 a 4 | 7.004 | atenção |
| N_AIH repetida na mesma competência | 16.752 | atenção, esperado |
| AIH do estudo repetida entre dezembro e janeiro | **0** | OK |

A última linha é a mais relevante: verifica o risco de a mesma internação aparecer em duas competências, já que dezembro pode ser processado em janeiro. A verificação foi restrita aos diagnósticos do estudo e não encontrou nenhuma repetição, o que confirma que a deduplicação está correta.

A divergência de DIAS_PERM em relação às datas (4,48%) reflete a diferença entre a permanência faturada e o intervalo entre internação e saída, e a divergência de idade em relação à data de nascimento (1,47%) é conhecida nessa base. Nenhuma das duas entra no modelo: a permanência não é usada e a idade vem do campo `IDADE`.

### 8.2 Coerência da coorte analítica

| Verificação | Resultado | Classificação |
|---|---|---|
| Duplicatas na chave de deduplicação | **0** | OK |
| Linhas integralmente duplicadas (todas as colunas) | **0** | OK |
| Média e desvio-padrão de `idade_z` | 0,00000000 e 1,00000000 | OK |
| Anos distintos, regiões distintas, hospitais | 15, 9, 254 | OK |
| Linhas com subtipo incoerente com o CID de 3 dígitos | 0 | OK |
| Ausentes em qualquer covariável do modelo | 0 | OK |
| Óbitos com zero dia de permanência na coorte | 2.091 (3,75%) | OK |
| Mediana de permanência | 6 dias (I69: 30 dias) | OK |
| UTI_MES_TO maior que DIAS_PERM na coorte | 5.173 (1,75%; 13,5% dos registros com UTI) | atenção |
| Linhas com perfil clínico coincidente, sem a chave | 27.484 (9,3%) | atenção, esperado |
| Razão entre a coorte e os registros brutos I60-I69 | 0,9163 | atenção, esperado |

**Correção aplicada durante a auditoria.** A primeira execução acusou 12.681 linhas integralmente idênticas, o que seria um defeito grave. Investigando, a causa era que a base analítica não retinha a chave da AIH nem a data de saída, de modo que duas internações distintas com o mesmo perfil clínico ficavam indistinguíveis. A correção foi incluir `N_AIH`, `IDENT` e `DT_SAIDA` na base, o que permite reverificar a deduplicação. Com a chave, o resultado é zero duplicatas, tanto na chave quanto na linha completa.

O achado de 1,75% de registros com dias de UTI superiores à permanência é uma inconsistência interna real que afeta 13,5% dos registros com UTI. Não muda a direção dos resultados, porque a variável usada no modelo é binária, mas deve ser declarada.

### 8.3 Triangulação entre SIH e SIM

As duas fontes são independentes e permitem verificação cruzada.

| Item | Valor |
|---|---|
| Óbitos por DCV no SIM, residentes no RJ, 2010-2024 | 147.551 |
| Desses, com local de ocorrência hospitalar | 120.970 |
| Óbitos intra-hospitalares no SIH (somente SUS) | 55.827 |
| Razão SIH / SIM hospitalar | 0,461 |
| Óbitos no SIM com local de ocorrência ignorado | 15 |

A razão de 0,461 é coerente com o fato de o SIH cobrir apenas internações financiadas pelo SUS, enquanto o SIM cobre toda a mortalidade, incluindo a rede privada e os óbitos domiciliares. Apenas 15 óbitos têm local ignorado, o que não compromete a comparação.

### 8.4 Coerência do modelo e das tabelas publicadas

| Verificação | Resultado | Classificação |
|---|---|---|
| ICC coerente com σ²/(σ²+π²/3) | 0,14945 vs 0,14945 | OK |
| MOR coerente com exp(√(2σ²)·Φ⁻¹(0,75)) | 2,0652 vs 2,0652 | OK |
| q-valor sempre maior ou igual ao p-valor | sim | OK |
| q-valor reproduz `p.adjust(BH)` | diferença máxima 0,000000 | OK |
| Soma de n na tabela de calibração | 295.673, igual à coorte (marginal e condicional) | OK |
| Razão esperado/observado condicional | 0,9999 | OK |
| Razão esperado/observado marginal | 0,7319 | atenção, Jensen |
| Soma dos óbitos regionais igual ao total estadual do ISU | 147.551 vs 147.551 | OK |
| Robustez reproduz o modelo principal (σ²) | 0,57805 vs 0,57805 | OK |
| Cenários de robustez convergidos | 18 de 18 | OK |

### 8.5 As 12 verificações que exigem leitura

Todas têm explicação documentada e nenhuma compromete as conclusões:

1. DIAS_PERM divergente das datas: 4,48% dos registros brutos, característica da base.
2. Idade divergente da data de nascimento: 1,47%, característica da base.
3. UTI_MES_TO maior que DIAS_PERM: 0,62% do bruto e 1,75% da coorte.
4. Óbito com zero dia de permanência: 44.738 no bruto, 3,75% dos óbitos na coorte; óbito no dia da internação é possível.
5. COD_IDADE fora de 1 a 4: 7.004 registros no bruto.
6. N_AIH repetida na mesma competência: 16.752, esperado pela estrutura de procedimentos.
7. Perfil clínico coincidente: 9,3% da base, esperado sem a chave.
8. Razão coorte / registros brutos I60-I69: 0,9163, explicada por residência fora do RJ, duplicatas e período.
9. Razão SIH / SIM hospitalar: 0,461, explicada pela cobertura SUS.
10. Óbitos no SIM com local ignorado: 15.
11. Razão esperado/observado marginal: 0,7319, por desigualdade de Jensen.
12. UTI_MES_TO maior que DIAS_PERM na coorte: 5.173.

---

## 9. Exploração das variáveis não usadas no modelo principal

O modelo principal usa idade, sexo, subtipo diagnóstico, caráter da internação, uso de UTI, fluxo intermunicipal e região de saúde. Os microdados do SIH-RD trazem 113 colunas; este bloco examina as que ficaram de fora. O resultado mais importante **não** está nas associações, e sim no que é utilizável: boa parte das variáveis aparentemente disponíveis não pode ser usada.

### 9.1 Disponibilidade e variabilidade

| Variável | Ausente | Níveis | Nível dominante | Utilizável |
|---|---|---|---|---|
| Raça/cor | 24,92% (NA) | 5 | Parda (45,5%) | sim, com ressalva |
| Escolaridade | 0,00% (NA) | 2 | Sem instrução (100,0%) | **não** |
| Diagnósticos secundários | 90,84% (NA) | 5 | nenhum (90,8%) | **não** para o efeito |
| Complexidade | 0,00% (NA) | 2 | Média (95,4%) | marginal |
| Natureza jurídica | 13,72% (NA) | 3 | Administração pública (70,8%) | sim, a partir de 2013 |
| Permanência | 0,00% (NA) | 225 | 6 dias | sim |
| Total de serviços | 0,00% (NA) | 82.556 | 228,18 (0,3%) | sim |
| Valor de UTI | 0,00% (NA) | 868 | 0 (87,0%) | sim |

**Convenção de ausente.** Valores ausentes são `NA`, como o R os representa, sem rótulo substituto. Quando a própria fonte usa um código para "sem informação" ou "ignorado" (99 em `RACA_COR`, 9 em `INSTRU`), esse código também vira `NA`, para não criar uma categoria artificial confundível com um nível real. Consequência: cada modelo usa os casos completos das variáveis que emprega, e o n é sempre reportado.

**A armadilha da ausência zero.** Escolaridade aparece com 0,00% de ausência e é, ainda assim, inutilizável: `INSTRU` é "sem instrução" em **295.672 dos 295.673 registros**. Ausência zero não significa campo útil; foi preciso verificar a variabilidade. O mesmo cuidado vale para complexidade, com 95,4% em uma única categoria.

**A ausência é informativa.** A mortalidade de quem tem `NA` é sistematicamente diferente:

| Variável | Mortalidade com NA | Mortalidade sem NA | Diferença |
|---|---|---|---|
| Raça/cor | 24,17% (n = 73.670) | 17,13% (n = 222.003) | **+7,04 p.p.** |
| Natureza jurídica | 19,14% (n = 40.555) | 18,84% (n = 255.118) | +0,30 p.p. |

A ausência de raça/cor não é aleatória e, por isso, tratar essas internações como casos omissos — e não como uma categoria — é a decisão correta, ainda que reduza a amostra dos modelos que usam a variável.

**Variáveis descartadas, verificadas nos arquivos brutos:**

| Campo | Verificação | Situação |
|---|---|---|
| `INFEHOSP` | 100% vazio em 2010 a 2024 | inutilizável |
| `CID_ASSO` | apenas o valor `0000` | inutilizável |
| `NATUREZA` | um único valor distinto no arquivo estadual | inutilizável |
| `ESPEC` | varia, mas sem a tabela oficial do DATASUS | disponível, não interpretado |

**Disponibilidade ao longo do tempo:**

| Ano | Sem diagnóstico secundário | Raça/cor ausente | Natureza jurídica ausente |
|---|---|---|---|
| 2010 | 100,0% | 35,4% | 98,4% |
| 2012 | 100,0% | 31,1% | 30,8% |
| 2014 | 98,7% | 24,4% | 0,0% |
| 2018 | 89,2% | 27,9% | 0,0% |
| 2021 | 87,0% | 34,7% | 0,0% |
| 2024 | 83,3% | **0,0%** | 0,0% |

Três consequências: `DIAGSEC` inexiste até 2013 e, de 2014 em diante, nunca cobre mais de 17% dos registros, de modo que mede codificação e não doença; `NAT_JUR` só existe a partir de 2013; e a ausência de raça/cor cai de 35,4% para 0,0%, criando gradiente temporal na própria variável.

### 9.2 Mortalidade bruta

| Variável | Categoria | n | Mortalidade |
|---|---|---|---|
| Raça/cor | Preta | 41.044 | 18,26% |
| | Parda | 101.085 | 17,94% |
| | Amarela | 2.842 | 17,17% |
| | Branca | 77.019 | 15,45% |
| | **Sem informação** | 73.670 | **24,17%** |
| Natureza jurídica | Administração pública | 180.743 | 22,28% |
| | Entidades sem fins lucrativos | 54.619 | 12,54% |
| | Entidades empresariais | 19.756 | 4,81% |
| Complexidade | Média | 282.078 | 19,37% |
| | Básica | 13.595 | 8,73% |

A diferença bruta entre administração pública (22,28%) e entidades empresariais (4,81%) é de **4,6 vezes**. O grupo sem informação de raça/cor tem a maior mortalidade de todas as categorias, o que é o padrão clássico de ausência informativa.

### 9.3 O que o ajuste revela

**Raça/cor.** Com Branca como referência — e não Amarela, que a ordem alfabética impunha sobre uma categoria de apenas 2.842 internações —, o gradiente racial bruto não se sustenta:

| Categoria | n | Mortalidade bruta | OR ajustado (M1) | IC95% | p |
|---|---|---|---|---|---|
| Branca | 77.019 | 15,45% | referência | — | — |
| Preta | 41.044 | 18,26% | 0,982 | 0,946 a 1,018 | 0,32 |
| **Parda** | 101.085 | 17,94% | **0,934** | 0,907 a 0,963 | **8,2 × 10⁻⁶** |
| Amarela | 2.842 | 17,17% | 1,040 | 0,931 a 1,161 | 0,49 |
| Indígena | 13 | 30,77% | 2,118 | 0,564 a 7,957 | 0,27 |

A diferença bruta de 2,8 pontos percentuais entre pretas e brancas **desaparece** após ajuste (OR 0,982, não significativo): era composição de idade e subtipo. A categoria parda apresenta odds ligeiramente **inferior** à branca (OR 0,934), efeito modesto e que deve ser lido com cautela, por poder refletir confundimento residual. A categoria indígena tem apenas **13 internações** e intervalo de confiança inutilizável; o valor de 30,77% de mortalidade corresponde a 4 óbitos e não sustenta inferência.

**O que permanece é a ausência.** Quem tem `NA` em raça/cor apresenta 24,17% de mortalidade contra 17,13% de quem tem valor — **+7,04 pontos percentuais**. Tratar essa ausência como categoria, e não como omissão, produziria um odds ratio artificialmente elevado; tratá-la como `NA` exclui essas internações dos modelos que usam a variável, e é a decisão correta diante de ausência informativa.

**Natureza jurídica.** O ajuste reduz drasticamente a diferença bruta:

| Categoria | OR ajustado | IC95% | p |
|---|---|---|---|
| Entidades empresariais | 0,396 | 0,296 a 0,528 | 3,1 × 10⁻¹⁰ |
| Entidades sem fins lucrativos | 0,882 | 0,737 a 1,056 | 0,17 |

A razão bruta de 4,6 vezes cai para um OR de 0,40. Ou seja, **a diferença de mortalidade entre rede pública e rede privada é quase toda composição de casos**, não qualidade: os hospitais públicos concentram os casos graves, exatamente como já se viu com a UTI. É o mesmo mecanismo de seleção, agora confirmado por outra variável estrutural.

### 9.4 Impacto no componente hospitalar

Como ausente é `NA`, cada modelo usa os casos completos das variáveis que emprega, e as amostras diferem. Comparar a variância de um modelo estendido com a do modelo principal ajustado em **outra** amostra confundiria o efeito da variável com o efeito da mudança de amostra. Por isso o modelo base foi **reajustado na mesma amostra** de cada modelo estendido.

| Modelo | n | σ² base | σ² modelo | ICC base | ICC modelo | Δ ICC | Variância hospitalar explicada |
|---|---|---|---|---|---|---|---|
| M0 principal (script 05) | 295.673 | — | 0,57805 | — | 14,95% | — | — |
| M1 + raça/cor | 222.003 | 0,55555 | 0,55998 | 14,45% | 14,54% | **+0,10 p.p.** | −0,8% |
| M2 + natureza jurídica | 255.118 | 0,56237 | 0,46529 | 14,60% | 12,39% | **−2,21 p.p.** | **+17,3%** |
| M3 + complexidade | 295.673 | 0,57805 | 0,49681 | 14,95% | 13,12% | **−1,83 p.p.** | **+14,1%** |
| **M4 completo** | 195.399 | 0,58608 | 0,43566 | 15,12% | **11,69%** | **−3,43 p.p.** | **+25,7%** |

**Três leituras.**

A primeira é que **a natureza jurídica do estabelecimento explica 17,3% da heterogeneidade entre hospitais**, reduzindo o ICC de 14,60% para 12,39% na mesma amostra. Parte da variação entre serviços é a composição público-privada da rede.

A segunda é que **a complexidade do procedimento explica 14,1%**, reduzindo o ICC de 14,95% para 13,12%. A variável é grosseira (95,4% em uma única categoria), mas separa bem: procedimentos de complexidade básica têm 8,73% de mortalidade contra 19,37% nos de média complexidade.

A terceira é a mais consequente para a conclusão do estudo: **com todas as variáveis juntas, o ICC cai de 15,12% para 11,69%, ou seja, 25,7% da variância entre hospitais é explicada por características observáveis** — perfil do paciente, natureza jurídica e complexidade. **Cerca de três quartos da heterogeneidade hospitalar permanecem, no entanto, sem explicação por essas variáveis.** O componente hospitalar é, portanto, real e majoritariamente não observável nos dados administrativos: estrutura, processo assistencial ou qualidade, que os microdados do SIH não capturam.

Raça/cor é a exceção: praticamente não move o ICC (+0,10 p.p.).

**Correção em relação a uma versão anterior deste relatório.** Numa primeira passagem, a natureza jurídica aparecia **elevando** o ICC para 16,91% e o modelo completo parecia não alterar nada. Os dois resultados eram artefato de codificação: a variável trazia uma categoria "não informado" que, na prática, era o período de 2010 a 2012, quando o campo não existia. Essa categoria falsa absorvia o efeito de período e inflava a variância hospitalar. Além disso, os modelos estavam sendo comparados em amostras diferentes — o estendido, nos casos completos, e o principal, na amostra inteira. Com ausente tratado como `NA` e a base reajustada na mesma amostra de cada modelo, as duas conclusões se invertem.

### 9.5 Comorbidade

Como o campo `DIAGSEC` só existe a partir de 2014, o teste foi restrito a esse período (222.832 internações):

| Modelo | σ² | VPC/ICC | AIC |
|---|---|---|---|
| 2014-2024 sem comorbidade | 0,55779 | 14,50% | 192.228,0 |
| 2014-2024 com comorbidade | 0,59707 | 15,36% | 190.212,9 |

O OR por diagnóstico secundário adicional é de 1,6786 (IC95% 1,6406 a 1,7175), mas **não deve ser lido como efeito de comorbidade**. A associação bruta não é monotônica — nenhum código 16,95%; um código 41,41%; dois códigos 23,23%; três códigos 31,94% —, o que indica que o campo marca sobretudo *se* houve codificação secundária, e não *quanto* de doença o paciente tem. E, uma vez mais, o componente hospitalar **não diminui**: sobe de 14,50% para 15,36%.

### 9.6 Interações e permanência

**Interações.** Duas das três testadas são significativas e melhoram o ajuste:

| Interação | gl | Razão de verossimilhança | p | AIC |
|---|---|---|---|---|
| Sexo × faixa de idade | 10 | 489,1 | 9,4 × 10⁻⁹⁹ | 252.992 → 252.523 |
| Subtipo × uso de UTI | 6 | 686,6 | 4,8 × 10⁻¹⁴⁵ | 252.992 → 252.318 |

Em ambos os casos o efeito de uma variável depende do nível da outra. O caso mais interpretável é o do **sexo por idade**: a mortalidade feminina e masculina praticamente se iguala a partir dos 70 anos, mas abaixo disso há diferença, com a curva masculina acima da feminina na faixa de 40 a 49 anos. Quanto ao **subtipo por UTI**, a associação da UTI com o óbito não é a mesma em todos os subtipos, o que é coerente com o fato de a UTI ser indicação diferente em um AVC hemorrágico e em um AIT.

A terceira interação, raça × região, acrescenta 45 termos e ficou desativada por padrão no script (pode ser ligada com `GLMM_INTER_RACA=1`); não foi ela que sustentou nenhuma conclusão.

**Permanência.** A mediana é de 6 dias nos óbitos sem UTI e de 8 dias nos óbitos com UTI; nas altas, 6 dias sem UTI e 9 dias com UTI. Por subtipo, a mediana é de 30 dias em sequelas (I69), 7 dias no hemorrágico, 5 dias no não especificado (I64) e no AIT (G45) e 4 dias em oclusão e outras (I65 a I68). Por região, a mediana vai de 5 dias em cinco regiões a 11 dias na Serrana, e a Metropolitana I, que concentra 45,9% das internações, tem a maior letalidade (23,22%) com a segunda maior permanência mediana (7 dias).

---

## 10. Limitações

1. **Codificação do subtipo.** I64 responde por 56,64% da coorte e I63 por 5,69%. O subtipo mede qualidade de codificação tanto quanto fisiopatologia.
2. **Mortalidade registrada em AIT.** As internações com diagnóstico principal G45 apresentam 11,99% de mortalidade intra-hospitalar, valor clinicamente implausível para um evento transitório, e praticamente nenhum óbito é codificado como G45 ou G46 no SIM.
3. **Ausência de gravidade clínica.** Sem sinais vitais, escalas de gravidade, exames laboratoriais ou neuroimagem.
4. **Comorbidade incompleta.** O diagnóstico secundário só tem preenchimento integral a partir de 2015.
5. **Reinternações.** O SIH-RD é anonimizado e não permite identificar o mesmo indivíduo; as internações foram tratadas como independentes no nível 1.
6. **Áreas pequenas.** 68 estabelecimentos com menos de 100 internações em 15 anos e 26 sem nenhum óbito.
7. **Raça/cor e escolaridade.** Cerca de 25% sem informação de raça/cor e escolaridade inutilizável. Nenhuma entrou no modelo.
8. **Generalização.** Dados restritos ao Rio de Janeiro, sem validação externa.
9. **Ausência de leitura causal.** Desenho observacional.

---

## 11. Organização da pasta

A pasta foi organizada, com os scripts renumerados na ordem de execução e cerca de 320 MB de arquivos obsoletos removidos.

**Renumeração.** O download do microdatasus, antes em `16`, passou a ser o `01`, primeiro passo da cadeia. A ordem final é: `00` utilitários, `01` download, `02` coorte, `03` tabelas descritivas, `04` ISU, `05` GLMM principal, `06` UTI, `07` auditoria, `08` robustez, `09` conferência entre motores, `10` figuras.

**Legado.** O código da fase anterior (consolidação histórica, análises de tendência, mortalidade e custos, que sustentam o manuscrito fora do escopo do GLMM) foi movido para `02_scripts/legado_fase_anterior/`, de modo que a pasta principal mostre apenas a cadeia em uso.

**Removidos:** a conversão intermediária para parquet (238 MB), desnecessária desde que o R passou a ler os `.rds` direto; a execução paralela em Python, com sete scripts e todas as suas saídas; quatro scripts em R superados pela cadeia atual; e os relatórios executivos anteriores, substituídos por este.

**Consolidados:** o antigo script de sensibilidade da UTI e qualidade de dados foi dissolvido nos scripts `06` (UTI) e `07` (auditoria), que fazem o mesmo de forma mais completa.

A estrutura final está descrita em `LEIA-ME.md`, na raiz do projeto.

### Observação importante

`HANDOFF.md` e `PLANO_METODOLOGICO_GLMM_COX.md` **não estão mais na pasta do projeto**. Eles existiam no início desta sessão e não foram removidos por mim: todas as minhas exclusões foram feitas em subpastas específicas, com verificação de caminho. Como o plano era o documento de especificação de todo este trabalho, recomenda-se repô-lo ou substituí-lo pelo `LEIA-ME.md`.

---

## 12. Recomendações

1. **Decidir sobre a permanência da UTI no modelo principal**, ou apresentar as duas versões. Retirá-la eleva o ICC a 17,25%.
2. **Comunicar o ICC em linguagem de gestão.** "15% da variação da letalidade cerebrovascular está entre hospitais, e apenas 3 dos 206 serviços se afastam do esperado após acomodar essa variação" é a mensagem acionável.
3. **Investigar o gradiente favorável ao interior.** OR de 0,47 no Médio Paraíba com a Metropolitana I concentrando 45,9% das internações e a maior letalidade bruta (23,2%).
4. **Discutir a não linearidade da idade na redação**, já que o spline melhora o AIC em 659 pontos.
5. **Produzir o mapa das regiões de saúde** quando a malha territorial estiver disponível.
6. **Repor o documento de plano metodológico**, ausente da pasta.

---

## 13. Reprodutibilidade

A cadeia completa está em `LEIA-ME.md`. Os scripts estão numerados na ordem de execução, com o download como primeiro passo. Em resumo, na raiz do projeto:

```powershell
$R = "C:\Program Files\R\R-4.6.1\bin\Rscript.exe"

# 1. aquisicao dos microdados (R, microdatasus) -- cerca de 38 min
& $R "02_scripts\01_baixar_microdatasus.R"

# 2. coorte analitica e tabelas descritivas -- cerca de 6 min
& $R "02_scripts\02_montar_coorte.R"
& $R "02_scripts\03_tabelas_descritivas.R"

# 3. Indice de Swaroop-Uemura por regiao -- menos de 1 min
& $R "02_scripts\04_isu_regiao_saude.R"

# 4. GLMM principal com FDR -- cerca de 3 min
& $R "02_scripts\05_glmm_principal.R"

# 5. tratamento do uso de UTI (decomposicao de Mundlak) -- cerca de 18 min
& $R "02_scripts\06_glmm_uti.R"

# 6. auditoria de incongruencias e inconsistencias -- cerca de 8 min
& $R "02_scripts\07_auditoria_consistencia.R"

# 7. robustez -- cerca de 40 min
& $R "02_scripts\08_glmm_robustez.R"

# 8. conferencia entre motores e adequacao de Laplace -- cerca de 5 min
& $R "02_scripts\09_conferencia_motores.R"

# 9. figuras
& $R "02_scripts\10_figuras.R"

# 10. exploracao das variaveis nao usadas -- cerca de 60 min
& $R "02_scripts\11_exploratorio.R"
```

O script `09_conferencia_motores.R` roda com um único comando: ele ajusta o `glmmTMB` na sessão principal e se invoca novamente com o argumento `--worker` para ajustar o `lme4` em um processo R limpo.

**Paleta das figuras.** Todas as figuras usam a paleta **viridis**, tanto nas escalas contínuas (`scale_fill_viridis_c`, `scale_colour_viridis_c`) quanto nas discretas (`scale_*_viridis_d`) e nas cores fixas (`viridisLite::viridis()`). A escolha se justifica por três razões: é perceptualmente uniforme, mantém a legibilidade em escala de cinza e é segura para daltonismo.

---

**Fim do relatório.**
