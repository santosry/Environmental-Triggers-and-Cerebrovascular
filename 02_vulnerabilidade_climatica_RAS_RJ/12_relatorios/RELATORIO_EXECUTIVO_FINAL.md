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

7. **A heterogeneidade entre hospitais é sistêmica.** Dos 206 hospitais com eventos suficientes, limites de controle ingênuos classificariam 102 como atípicos em nível de 99,8%, mas apenas 3 permanecem fora dos limites depois de acomodar a variabilidade real entre serviços.

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

### 6.2 Sensibilidade à definição de uso de UTI

| Definição | Prevalência | σ² | ICC | OR da UTI |
|---|---|---|---|---|
| Ao menos 1 dia (principal) | 12,97% | 0,5781 | 14,95% | 3,904 (3,789 a 4,022) |
| Ao menos 2 dias | 11,32% | 0,5816 | 15,02% | 3,963 (3,844 a 4,086) |
| Ao menos 7 dias | 5,33% | 0,5867 | 15,14% | 3,351 (3,227 a 3,479) |
| Pelo campo `MARCA_UTI` | 12,99% | 0,5797 | 14,98% | 3,917 (3,802 a 4,036) |
| Sem a variável no modelo | — | 0,6860 | 17,25% | — |

O que altera o ICC é a presença ou não da variável, e não o ponto de corte escolhido. As quatro definições produzem ICC entre 14,95% e 15,14%.

---

## 7. Decisões metodológicas e ressalvas

1. **Blocos G completos.** A lista parcial anterior excluía 29,9% do bloco G e deixava o grupo G46 com 18 casos. A versão final usa os blocos G45 e G46 completos, incluindo G45.8, G46.7 e G46.8.

2. **Uso de UTI.** Mantido no modelo por exigência do plano, mas é marcador de gravidade e possivelmente mediador, não fator de risco. Duas evidências: o registro de UTI cresce de 8,2% em 2010 para 20,8% em 2024, e varia de 9,5% na Serrana a 31,7% no Noroeste. O OR de 3,90 não deve ser lido como efeito causal, e retirar a variável eleva o ICC a 17,25%.

3. **Múltiplas comparações.** Aplicada a correção de Benjamini-Hochberg, com família global e famílias separadas para paciente e região. Nenhum coeficiente perde significância.

4. **Período.** Apenas `DT_INTER` de 2010 a 2024, como definido.

5. **Unidade territorial.** As nove regiões de saúde, sem agregação por macrorregião.

6. **Assimetria SIH e SIM.** A coorte de internações inclui os códigos G; a série de mortalidade permanece em I60-I69. A verificação mostrou 60 óbitos de 2.143.313 com G45 ou G46 como causa básica (0,0028%).

7. **Versão do software.** O plano previa declarar R 4.6.0, mas a instalação dessa versão na máquina está incompleta e sem `Rscript.exe` funcional. Tudo foi executado em **R 4.6.1**. A declaração do manuscrito precisa refletir isso.

8. **Ausência de mapa coroplético.** Não há shapefile das regiões de saúde do Rio de Janeiro no projeto nem nas pastas vizinhas.

---

## 8. Auditoria de qualidade dos dados

| Item | Resultado |
|---|---|
| Idade ausente, acima de 120 anos ou negativa | 0 |
| Sexo, caráter, região de saúde ou CNES ausentes | 0 |
| Dias de permanência ausentes, negativos ou acima de 365 | 0 |
| Valor total negativo | 0 |
| Registros com dias de UTI superiores aos dias de permanência | 5.173 (1,75%) |
| Dias de UTI máximo registrado | 306 (valor implausível) |
| Óbitos entre as internações com código G | 3.395 (12,16%) |

As duas inconsistências de UTI não afetam o modelo, porque a variável usada é binária (ao menos um dia de UTI).

---

## 9. Limitações

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

## 10. Organização da pasta

A pasta foi organizada e cerca de 320 MB de arquivos obsoletos foram removidos.

**Removidos:** a conversão intermediária para parquet (`brutos_parquet` e `brutos_sim_parquet`, 238 MB), que deixou de ser necessária quando o R passou a ler os `.rds` do microdatasus direto; a execução paralela em Python, com sete scripts e todas as suas saídas; os scripts em R superados (`07_extrair_g45_g46.R`, `08_montar_coorte_glmm.R`, `15_robustez_cenarios_faltantes.R`, `19_rds_para_parquet.R` e `03_swaroop_ipca.R`); as tabelas descritivas da coorte antiga, regeradas; e os PDFs de referência foram movidos para `13_documentos_referencia/`.

**Mantidos:** os scripts 01, 02, 02b, 04, 05 e 06, que produzem os resultados de tendência, mortalidade e custos usados no manuscrito, fora do escopo do GLMM.

A estrutura final está descrita em `LEIA-ME.md`, na raiz do projeto.

### Observação importante

`HANDOFF.md` e `PLANO_METODOLOGICO_GLMM_COX.md` **não estão mais na pasta do projeto**. Eles existiam no início desta sessão e não foram removidos por mim: todas as minhas exclusões foram feitas em subpastas específicas, com verificação de caminho. Como o plano era o documento de especificação de todo este trabalho, recomenda-se repô-lo ou substituí-lo pelo `LEIA-ME.md`.

---

## 11. Recomendações

1. **Decidir sobre a permanência da UTI no modelo principal**, ou apresentar as duas versões. Retirá-la eleva o ICC a 17,25%.
2. **Comunicar o ICC em linguagem de gestão.** "15% da variação da letalidade cerebrovascular está entre hospitais, e apenas 3 dos 206 serviços se afastam do esperado após acomodar essa variação" é a mensagem acionável.
3. **Investigar o gradiente favorável ao interior.** OR de 0,47 no Médio Paraíba com a Metropolitana I concentrando 45,9% das internações e a maior letalidade bruta (23,2%).
4. **Discutir a não linearidade da idade na redação**, já que o spline melhora o AIC em 659 pontos.
5. **Produzir o mapa das regiões de saúde** quando a malha territorial estiver disponível.
6. **Repor o documento de plano metodológico**, ausente da pasta.

---

## 12. Reprodutibilidade

A cadeia completa está em `LEIA-ME.md`. Em resumo, na raiz do projeto:

```powershell
$R = "C:\Program Files\R\R-4.6.1\bin\Rscript.exe"
& $R "02_scripts\16_baixar_microdatasus.R"    # aquisicao, ~38 min
& $R "02_scripts\07_montar_coorte_microdatasus.R"  # coorte, ~6 min
& $R "02_scripts\08_tabelas_descritivas.R"
& $R "02_scripts\10_isu_regiao_saude.R"
& $R "02_scripts\09_glmm_principal.R"          # GLMM com FDR, ~3 min
& $R "02_scripts\11_glmm_robustez.R"           # robustez, ~40 min
& $R "02_scripts\12_glmm_conferencia_lme4.R"
& $R "02_scripts\14_sensibilidade_uti_qualidade.R"
& $R "02_scripts\13_figuras_glmm.R"
```

---

**Fim do relatório.**
