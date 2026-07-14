# RELATÓRIO DE AUDITORIA DE DADOS

**Projeto:** Exposição Climática e Desfechos Cerebrovasculares no Rio de Janeiro (2010-2025)
**Data de execução:** 2026-07-14
**Versão do pipeline:** Corrigido (v2.0)

## 1. FONTES DE DADOS

| Fonte | Sistema | Período | Registros brutos | Registros utilizados |
|-------|---------|---------|------------------|---------------------|
| SIH-RD | DATASUS | 2010-2025 | 192 arquivos mensais | 288395 (I60-I69, diagnóstico principal) |
| SIM-DO | DATASUS | 2010-2024 | 15 arquivos anuais | 147551 (I60-I69, causa básica) |

## 2. PERÍODOS DE OBSERVAÇÃO

| Desfecho | Início | Fim | Dias | Fonte |
|----------|--------|-----|------|-------|
| Internações | 2010-01-01 | 2025-12-31 | 5.844 | SIH-RD |
| Óbitos | 2010-01-01 | 2024-12-31 | 5.478 | SIM-DO (causa básica) |

**NOTA CRÍTICA:** A variável MORTE da AIH NÃO foi utilizada para completar óbitos de 2025.
Os óbitos de 2025 estão como NA (não zero) no dataset. Os modelos de mortalidade
utilizam apenas o período com cobertura do SIM (2010-2024).

## 3. FLUXOGRAMA DE SELEÇÃO DE REGISTROS

### 3.1 Internações (SIH-RD)

- Total de registros brutos processados: 192 arquivos mensais
- CID-10 I60-I69 (cerebrovasculares): **288395 registros**
- Diagnóstico principal da AIH (DIAG_PRINC)
- Município de residência com código IBGE iniciando em '33' (RJ)
- 0 registros excluídos por código de município inválido

### 3.2 Óbitos (SIM-DO)

- Total de registros brutos processados: 15 arquivos anuais
- CID-10 I60-I69 (causa básica): **147551 registros**
- Causa básica do SIM (CAUSABAS)
- 292 registros excluídos sem macrorregião (município fora do RJ ou não mapeado)
- 0 registros de 2025 (SIM 2025 não disponível)

## 4. DISTRIBUIÇÃO POR CID-10

### 4.1 Internações (SIH-RD, 2010-2025)

| CID-10 | Descrição | n | % |
|--------|-----------|---|---|
| I64 | AVC não especificado (hemorrágico/isquêmico) | 181919 | 63.1% |
| I69 | Sequelas de doenças cerebrovasculares | 40920 | 14.2% |
| I61 | Hemorragia intracerebral | 18868 | 6.5% |
| I63 | Infarto cerebral | 18096 | 6.3% |
| I60 | Hemorragia subaracnóidea | 12735 | 4.4% |
| I62 | Outras hemorragias intracranianas não traumáticas | 6566 | 2.3% |
| I67 | Outras doenças cerebrovasculares | 5560 | 1.9% |
| I65 | Oclusão/estenose artérias pré-cerebrais | 3314 | 1.1% |
| I66 | Oclusão/estenose artérias cerebrais | 373 | 0.1% |
| I68 | Transtornos cerebrovasculares em outras doenças | 44 | 0.0% |

**Total:** 288395 internações I60-I69
**I60-I64 (agudos):** 238184 (82.6%)
**I60-I62 (hemorrágicos):** 38169
**I63 (isquêmico):** 18096
**I64 (não especificado):** 181919

### 4.2 Óbitos (SIM-DO, 2010-2024)

| CID-10 | Descrição | n | % |
|--------|-----------|---|---|
| I64 | AVC não especificado | 55523 | 37.6% |
| I67 | Outras doenças cerebrovasculares | 36853 | 25.0% |
| I61 | Hemorragia intracerebral | 27452 | 18.6% |
| I69 | Sequelas de doenças cerebrovasculares | 16916 | 11.5% |
| I60 | Hemorragia subaracnóidea | 6681 | 4.5% |
| I62 | Outras hemorragias intracranianas | 2891 | 2.0% |
| I63 | Infarto cerebral | 1235 | 0.8% |

**Total:** 147551 óbitos I60-I69
**I60-I64 (agudos):** 93782 (63.6%)

**OBSERVAÇÃO:** Baixo número de óbitos por I63 (infarto cerebral isquêmico) no SIM
em comparação com I61 (hemorragia intracerebral). Possível viés de codificação
da causa básica de óbito, com muitos AVC isquêmicos classificados como I64
(não especificado) ou I67/I69 (sequelas).

## 5. CONTAGENS POR MACRORREGIÃO

| Macrorregião | Internações I60-I69 | Internações I60-I64 | Óbitos I60-I69 | Óbitos I60-I64 |
|---|---:|---:|---:|---:|
| Baia da Ilha Grande | 4906 | 4632 | 1772 | 1107 |
| Baixada Litoranea | 9209 | 8695 | 5614 | 3507 |
| Centro-Sul | 11117 | 9980 | 3407 | 2294 |
| Medio Paraiba | 27386 | 20037 | 8783 | 5130 |
| Metropolitana I | 137856 | 115781 | 89135 | 58729 |
| Metropolitana II | 39357 | 37785 | 17926 | 10758 |
| Noroeste | 10756 | 9258 | 3326 | 1956 |
| Norte | 15473 | 14074 | 7747 | 4405 |
| Serrana | 32335 | 17942 | 9549 | 5707 |
| **Total** | **288395** | **238184** | **147259** | **93593** |

## 6. ESTATÍSTICAS DESCRITIVAS DIÁRIAS

### Internações (I60-I69)

| Macrorregião | Média | Mediana | Variância | Sobredispersão | Dias c/ zero |
|---|---:|---:|---:|---:|---:|
| Baia da Ilha Grande | 0.27 | 0 | 0.34 | 1.25 | 12933 |
| Baixada Litoranea | 0.17 | 0 | 0.19 | 1.14 | 42174 |
| Centro-Sul | 0.17 | 0 | 0.26 | 1.48 | 51402 |
| Medio Paraiba | 0.38 | 0 | 3.45 | 9.05 | 50876 |
| Metropolitana I | 1.97 | 0 | 188.52 | 95.89 | 35484 |
| Metropolitana II | 0.93 | 0 | 2.77 | 2.99 | 22282 |
| Noroeste | 0.13 | 0 | 1.22 | 9.21 | 68348 |
| Norte | 0.32 | 0 | 2.72 | 8.53 | 35354 |
| Serrana | 0.35 | 0 | 15.14 | 43.13 | 73548 |

### Óbitos (I60-I69, 2010-2024)

| Macrorregião | Média | Mediana | Variância | Sobredispersão | Dias c/ zero |
|---|---:|---:|---:|---:|---:|
| Baia da Ilha Grande | 0.11 | 0 | 0.11 | 1.05 | 14795 |
| Baixada Litoranea | 0.11 | 0 | 0.12 | 1.07 | 44169 |
| Centro-Sul | 0.06 | 0 | 0.06 | 1.04 | 57022 |
| Medio Paraiba | 0.13 | 0 | 0.15 | 1.16 | 58103 |
| Metropolitana I | 1.36 | 0 | 9.41 | 6.94 | 39113 |
| Metropolitana II | 0.47 | 0 | 0.78 | 1.67 | 27129 |
| Noroeste | 0.04 | 0 | 0.05 | 1.05 | 73528 |
| Norte | 0.18 | 0 | 0.26 | 1.46 | 37985 |
| Serrana | 0.11 | 0 | 0.14 | 1.30 | 79708 |

## 7. EXPOSIÇÕES CLIMÁTICAS

### 7.1 Temperatura Média e Umidade por Macrorregião

| Macrorregião | Temp P05 | Temp Mediana | Temp P95 | UR P05 | UR Mediana | UR P95 |
|---|---:|---:|---:|---:|---:|---:|
| Baia da Ilha Grande | 18.4 | 22.8 | 27.9 | 69.7 | 81.4 | 91.2 |
| Baixada Litoranea | 19.8 | 23.3 | 27.0 | 67.4 | 80.1 | 89.2 |
| Centro-Sul | 10.3 | 19.7 | 26.5 | 63.3 | 81.0 | 97.0 |
| Medio Paraiba | 16.7 | 21.9 | 26.3 | 61.4 | 76.7 | 87.8 |
| Metropolitana I | 19.0 | 23.4 | 28.2 | 62.5 | 77.3 | 89.0 |
| Metropolitana II | 14.4 | 22.0 | 28.2 | 64.9 | 79.5 | 94.6 |
| Noroeste | 18.4 | 23.8 | 28.6 | 61.5 | 75.0 | 88.9 |
| Norte | 19.8 | 23.8 | 27.6 | 67.3 | 77.7 | 88.6 |
| Serrana | 12.1 | 17.8 | 22.4 | 67.4 | 83.2 | 94.8 |

### 7.2 Estações INMET por Macrorregião

Total de estações: 26

| Código | Município | Macrorregião | Latitude | Longitude | Altitude (m) |
|---|---|---|---:|---:|---:|
| A628 | Angra Dos Reis | Baia da Ilha Grande | -22.98 | -44.30 | 6 |
| A606 | Arraial Do Cabo | Baixada Litoranea | -22.98 | -42.02 | 5 |
| A604 | Cambuci | Noroeste | -21.59 | -41.96 | 46 |
| A607 | Campos Dos Goytacazes | Norte | -21.71 | -41.34 | 17 |
| A620 | Campos Dos Goytacazes - Sao Tome | Norte | -22.04 | -41.05 | 7 |
| A629 | Carmo | Serrana | -21.94 | -42.60 | 293 |
| A603 | Duque De Caxias - Xerem | Metropolitana I | -22.59 | -43.28 | 22 |
| A608 | Macae | Norte | -22.38 | -41.81 | 28 |
| A627 | Niteroi | Metropolitana II | -22.87 | -43.10 | 6 |
| A624 | Nova Friburgo - Salinas | Serrana | -22.33 | -42.68 | 1070 |
| A619 | Paraty | Baia da Ilha Grande | -23.22 | -44.73 | 3 |
| A610 | Pico Do Couto | Serrana | -22.46 | -43.29 | 1777 |
| A637 | Paty Do Alferes - Avelar | Centro-Sul | -22.35 | -43.42 | 508 |
| A609 | Resende | Medio Paraiba | -22.45 | -44.44 | 439 |
| A626 | Rio Claro | Medio Paraiba | -22.65 | -44.04 | 516 |
| A652 | Rio De Janeiro - Forte De Copacabana | Metropolitana I | -22.99 | -43.19 | 26 |
| A636 | Rio De Janeiro - Jacarepagua | Metropolitana I | -22.94 | -43.40 | 20 |
| A621 | Rio De Janeiro - Vila Militar | Metropolitana I | -22.86 | -43.41 | 30 |
| A602 | Rio De Janeiro-Marambaia | Metropolitana I | -23.05 | -43.60 | 12 |
| A630 | Santa Maria Madalena | Serrana | -21.95 | -42.01 | 586 |
| A667 | Saquarema - Sampaio Correia | Baixada Litoranea | -22.87 | -42.61 | 26 |
| A601 | Seropedica-Ecologia Agricola | Metropolitana I | -22.76 | -43.68 | 35 |
| A659 | Silva Jardim | Metropolitana II | -22.65 | -42.42 | 19 |
| A618 | Teresopolis-Parque Nacional | Serrana | -22.45 | -42.99 | 981 |
| A625 | Tres Rios | Centro-Sul | -22.10 | -43.21 | 295 |
| A611 | Valenca | Medio Paraiba | -22.36 | -43.70 | 370 |
