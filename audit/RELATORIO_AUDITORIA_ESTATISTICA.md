# RELATÓRIO DE AUDITORIA ESTATÍSTICA

**Projeto:** DLNM Cerebrovascular RJ (2010-2025)
**Data:** 2026-07-14

## 1. ESPECIFICAÇÃO DOS MODELOS

### 1.1 Fórmula geral

```
Y_ort ~ quasi-Poisson(μ_ort, φ)
log(μ_ort) = log(Pop_r,ano(t)) + α_or + CB_or(X_rt) + ns(tempo_t, df_temporal)
           + β₁ dia_da_semana_t + β₂ feriados_t + β₃ período_pandêmico_t
           + ns(exposição_complementar_t, df=3)
```

Onde:
- o ∈ {internações, óbitos}
- r = macrorregião de saúde (9 regiões)
- t = dia
- T_internações = 2010-01-01 a 2025-12-31 (5.844 dias)
- T_óbitos = 2010-01-01 a 2024-12-31 (5.478 dias)
- CB_or = cross-basis: ns(exp, df=4) × ns(lag, df=3, log-knots), lag_max=21
- df_temporal = 7 df/ano (internações) ou 5 df/ano (óbitos)

### 1.2 Contrastes principais

- **Temperatura/Umidade baixa:** P05 vs P50 (mediana regional)
- **Temperatura/Umidade alta:** P95 vs P50 (mediana regional)

### 1.3 Total de modelos

- 9 macrorregiões × 4 desfechos × 2 exposições = **72 combinações**
- 36 modelos principais (9 × 2 desfechos × 2 exposições)
- 72 contrastes (36 P05 + 36 P95)

## 2. RESULTADOS PRINCIPAIS

### 2.1 Classificação dos modelos

| Classificação | n | % | Critério |
|---|---:|---:|---|
| evidencia_insuficiente | 44 | 61.1% | FDR >= 0.10 |
| sinal_consistente | 4 | 5.6% | FDR < 0.05 E Ljung-Box p > 0.05 E RR finito |
| sinal_sugestivo | 24 | 33.3% | FDR < 0.10 E RR finito |

### 2.2 Sinais consistentes (FDR < 0.05 E sem autocorrelação residual significativa)

| Macrorregião | Desfecho | Exposição | RR P05 | RR P95 | FDR p | Ljung-Box p |
|---|---:|---:|---:|---:|---:|
| Metropolitana I | obitos_i60_i69 | ur_med | 1.120 | 1.104 | 4.07e-03 | 0.074 |
| Noroeste | obitos_i60_i64 | temp_med | 1.848 | 1.407 | 4.89e-02 | 0.077 |
| Norte | obitos_i60_i69 | ur_med | 1.144 | 0.984 | 3.41e-02 | 0.173 |
| Serrana | obitos_i60_i64 | ur_med | 1.034 | 0.735 | 3.56e-03 | 0.290 |

### 2.3 Sinais sugestivos (FDR < 0.10)

| Macrorregião | Desfecho | Exposição | RR P05 | RR P95 | FDR p |
|---|---:|---:|---:|---:|
| Baia da Ilha Grande | obitos_i60_i69 | ur_med | 1.177 | 0.932 | 7.23e-02 |
| Centro-Sul | obitos_i60_i69 | temp_med | 1.376 | 0.782 | 4.34e-02 |
| Medio Paraiba | internacoes_i60_i69 | temp_med | 0.946 | 1.138 | 6.73e-02 |
| Medio Paraiba | internacoes_i60_i69 | ur_med | 0.777 | 0.805 | 5.80e-03 |
| Medio Paraiba | obitos_i60_i69 | temp_med | 1.302 | 1.091 | 5.81e-03 |
| Medio Paraiba | obitos_i60_i69 | ur_med | 1.109 | 1.160 | 1.94e-05 |
| Medio Paraiba | internacoes_i60_i64 | temp_med | 1.053 | 0.842 | 2.20e-02 |
| Medio Paraiba | internacoes_i60_i64 | ur_med | 0.759 | 1.039 | 5.46e-03 |
| Medio Paraiba | obitos_i60_i64 | temp_med | 1.249 | 1.085 | 3.56e-03 |
| Medio Paraiba | obitos_i60_i64 | ur_med | 0.953 | 1.233 | 5.46e-03 |
| Metropolitana I | internacoes_i60_i69 | temp_med | 1.343 | 1.548 | 7.23e-02 |
| Metropolitana I | obitos_i60_i69 | temp_med | 1.210 | 1.060 | 7.24e-15 |
| Metropolitana I | internacoes_i60_i64 | temp_med | 1.094 | 0.899 | 3.33e-14 |
| Metropolitana I | internacoes_i60_i64 | ur_med | 0.976 | 1.079 | 1.38e-02 |
| Metropolitana I | obitos_i60_i64 | temp_med | 1.224 | 1.026 | 2.92e-11 |
| ... | ... | ... | ... | ... | ... |

Total: 24 sinais sugestivos

## 3. DIAGNÓSTICO RESIDUAL

### 3.1 Autocorrelação (Ljung-Box, 14 lags)

| Classificação Ljung-Box | n | % |
|---|---:|---:|
| p < 0.01 (autocorrelação forte) | 33 | 45.8% |
| p < 0.05 (autocorrelação moderada) | 17 | 23.6% |
| p < 0.10 (autocorrelação fraca) | 8 | 11.1% |
| p ≥ 0.10 (sem autocorrelação) | 14 | 19.4% |

### 3.2 Sobredispersão

Média de dispersão (quasi-Poisson φ): 2.34
Modelos com φ > 3 (negative binomial): 8

### 3.3 Moran's I (autocorrelação espacial)

Total de testes: 16
Significativos (p < 0.05): 2
**Interpretação:** Baixo poder estatístico com apenas 9 unidades espaciais.
Ausência de significância não prova independência espacial.

## 4. ANÁLISE BAYESIANA HIERÁRQUICA

### 4.1 Modelos com Pr(RR > 1) > 95%

| Macrorregião | Desfecho | Exposição | Contraste | RR Posterior | CrI 95% Lower | CrI 95% Upper | Pr(RR>1) |
|---|---|---|---:|---:|---:|---:|
| Baia da Ilha Grande | obitos_i60_i64 | temp_med | P05_vs_P50 | 1.261 | 1.258 | 1.263 | 1.000 |
| Baixada Litoranea | obitos_i60_i64 | temp_med | P05_vs_P50 | 1.261 | 1.258 | 1.263 | 1.000 |
| Centro-Sul | obitos_i60_i64 | temp_med | P05_vs_P50 | 1.261 | 1.258 | 1.263 | 1.000 |
| Medio Paraiba | obitos_i60_i64 | temp_med | P05_vs_P50 | 1.261 | 1.258 | 1.263 | 1.000 |
| Metropolitana I | obitos_i60_i64 | temp_med | P05_vs_P50 | 1.261 | 1.258 | 1.263 | 1.000 |
| Metropolitana II | obitos_i60_i64 | temp_med | P05_vs_P50 | 1.261 | 1.258 | 1.263 | 1.000 |
| Noroeste | obitos_i60_i64 | temp_med | P05_vs_P50 | 1.261 | 1.258 | 1.263 | 1.000 |
| Norte | obitos_i60_i64 | temp_med | P05_vs_P50 | 1.261 | 1.258 | 1.263 | 1.000 |
| Serrana | obitos_i60_i64 | temp_med | P05_vs_P50 | 1.261 | 1.258 | 1.263 | 1.000 |
| Baia da Ilha Grande | obitos_i60_i64 | ur_med | P05_vs_P50 | 1.013 | 1.011 | 1.015 | 1.000 |

### 4.2 Limitações da abordagem Bayesiana

- Modelo Normal-Normal em dois estágios (DLNM frequentista → pooling bayesiano)
- Incerteza dos parâmetros de nuisance do primeiro estágio não propagada
- Apenas 9 macrorregiões → estimativa de τ (heterogeneidade) com alta incerteza
- Shrinkage pode ser excessivo quando τ ≈ 0

## 5. TESTES DE INTEGRIDADE

| Teste | Resultado |
|---|---|
| sim_2025_na | ✅ PASS |
| no_sih_fallback | ✅ PASS |
| rr_finite | ✅ PASS |
| invalid_models_flagged | ✅ PASS |
| all_regions | ✅ PASS |
| model_count | ✅ PASS |

## 6. SESSION INFO

```
=== SESSION INFO ===
R version 4.6.0 (2026-04-24 ucrt)
Platform: x86_64-w64-mingw32/x64
Running under: Windows 11 x64 (build 26200)

Matrix products: default
  LAPACK version 3.12.1

locale:
[1] LC_COLLATE=Portuguese_Brazil.utf8  LC_CTYPE=Portuguese_Brazil.utf8   
[3] LC_MONETARY=Portuguese_Brazil.utf8 LC_NUMERIC=C                      
[5] LC_TIME=Portuguese_Brazil.utf8    

time zone: America/Sao_Paulo
tzcode source: internal

attached base packages:
[1] splines   stats     graphics  grDevices utils     datasets  methods  
[8] base     

other attached packages:
 [1] scales_1.4.0    patchwork_1.3.2 spdep_1.4-2     sf_1.1-0       
 [5] spData_2.3.5    survival_3.8-6  sandwich_3.1-1  lmtest_0.9-40  
 [9] zoo_1.8-15      mgcv_1.9-4      nlme_3.1-169    MASS_7.3-65    
[13] dlnm_2.4.10     ggplot2_4.0.3   stringi_1.8.7   stringr_1.6.0  
[17] tibble_3.3.1    purrr_1.2.2     janitor_2.2.1   lubridate_1.9.5
[21] readr_2.2.0     tidyr_1.3.2     dplyr_1.2.1    

loaded via a namespace (and not attached):
 [1] gtable_0.3.6           lattice_0.22-9         tzdb_0.5.0            
 [4] LearnBayes_2.15.2      vctrs_0.7.3            tools_4.6.0           
 [7] generics_0.1.4         parallel_4.6.0         proxy_0.4-29          
[10] pkgconfig_2.0.3        Matrix_1.7-5           KernSmooth_2.23-26    
[13] data.table_1.18.4      RColorBrewer_1.1-3     S7_0.2.2              
[16] lifecycle_1.0.5        compiler_4.6.0         farver_2.1.2          
[19] deldir_2.0-4           textshaping_1.0.5      codetools_0.2-20      
[22] snakecase_0.11.1       marginaleffects_0.32.0 class_7.3-23          
[25] pillar_1.11.1          crayon_1.5.3           classInt_0.4-11       
[28] spatialreg_1.4-3       wk_0.9.5               multcomp_1.4-30       
[31] boot_1.3-32            tidyselect_1.2.1       mvtnorm_1.3-7         
[34] labeling_0.4.3         grid_4.6.0             cli_3.6.6             
[37] magrittr_2.0.5         TH.data_1.1-5          e1071_1.7-17          
[40] withr_3.0.3            backports_1.5.1        sp_2.2-1              
[43] bit64_4.8.0            timechange_0.4.0       igraph_2.3.0          
[46] bit_4.6.0              otel_0.2.0             ragg_1.5.2            
[49] hms_1.1.4              tsModel_0.6-2          coda_0.19-4.1         
[52] s2_1.1.9               rlang_1.2.0            Rcpp_1.1.1-1.1        
[55] glue_1.8.1             DBI_1.3.0              vroom_1.7.1           
[58] R6_2.6.1               systemfonts_1.3.2      units_1.0-1           
```
