# AUDITORIA DO ESTUDO ANTERIOR

**Estudo-base auditado:** "Morbimortalidade por Afecções Cerebrovasculares no Estado do
Rio de Janeiro: Análise de Tendência Temporal e Disparidades Regionais (2010-2024)"
(`artigo_morbimortalidade_avc_rbn_2026.docx`).

**Data da auditoria:** 2026-09-19
**Responsável:** nova fase do projeto (reanálise e ampliação)
**Objetivo:** inventariar integralmente o estudo anterior antes de qualquer decisão
metodológica da nova fase — nenhum resultado foi aceito sem verificação.

---

## 1. O que existe (inventário)

### 1.1 Bases de dados

| Base | Localização | Período | Formato | Variáveis |
|---|---|---|---|---|
| SIH-RD bruto (internações) | `05_publicacao_github/data/raw/sih/*.rds` | 2010–2025 (192 arquivos mensais) | RDS (microdatasus) | 87 a 114 colunas (esquema evolui no tempo) |
| SIM bruto (óbitos) | `05_publicacao_github/data/raw/sim/*.rds` | 2010–2024 (15 anuais + 96 mensais 2017–2024) | RDS (microdatasus) | 60 colunas |
| SIH individual (extração antiga) | `06_WILCOXON/corrected_data/sih_individual_CORRIGIDO_*.csv` | 2010–2024 | CSV | **apenas 11 colunas** |
| SIM individual (extração antiga) | `06_WILCOXON/corrected_data/sim_individual_CORRIGIDO_*.csv` | 2010–2024 | CSV | **apenas 14 colunas** |
| Dataset macro diário | `06_WILCOXON/corrected_data/dataset_macro_CORRIGIDO_*.csv` | 2010–2024 | CSV | 36 colunas (agregado macro diário) |
| Lookup município→região | `05_publicacao_github/data/processed/lookup_municipio_macrorregiao.csv` | — | CSV | 92 municípios |

### 1.2 Scripts

| Script | Função | Observação |
|---|---|---|
| `06_WILCOXON/wilcoxon_analysis.py` | Análise Wilcoxon v1 | 37,5 KB |
| `06_WILCOXON/wilcoxon_analysis_v2.py` | Análise Wilcoxon v2 (expandida) | 47,8 KB |
| `06_WILCOXON/correct_data.py` | Correção dos dados (idade SIM, sexo, dedup, pandemia) | 13,2 KB |
| `05_publicacao_github/R/*.R` | Pipeline DLNM original (R) | 8 arquivos |

### 1.3 Resultados / tabelas / figuras produzidas

- `06_WILCOXON/outputs/` — 17 arquivos (resultados Wilcoxon, testes estratificados, sensibilidades, resumos executivos).
- `06_WILCOXON/audit/` — 12 arquivos de auditoria.
- `06_WILCOXON/corrected_data/relatorio_correcoes_*.md` — 7 correções documentadas.
- Artigo-base com Tabela 1 (indicadores assistenciais por macrorregião) e Figuras 1–2.

### 1.4 Fontes de dados do estudo-base

SIH-RD/SUS (microdatasus), IBGE/SIDRA (tabela 6579 — população), 9 regiões de saúde e
3 macrorregiões do RJ.

---

## 2. Limitações identificadas no estudo anterior (críticas)

| # | Limitação | Gravidade |
|---|---|---|
| L1 | **Inconsistência de período**: o método declara 2010–2024, mas os Resultados citam "123,38 em 2025", "14% em 2025", "232,56 em 2025" e "158,31 em 2025". | ALTA |
| L2 | **Escolaridade (INSTRU)**: o artigo afirma "incompletude de 100%"; os dados brutos mostram INSTRU=0 (sem instrução/não informado) em ~99,6% dos registros — imprecisão conceitual. | MÉDIA |
| L3 | **População**: 2010 interpolado e 2022–2024 replicados de 2021 ("proxy"), sem série pós-Censo 2022. Denominador impreciso. | MÉDIA |
| L4 | **Ausência de padronização etária direta** nas taxas regionais. | MÉDIA |
| L5 | **Falácia de polo assistencial** (Barra do Piraí) — taxa municipal distorcida por município de residência vs. internação, não decomposta. | MÉDIA |
| L6 | **Extração individual incompleta**: os CSVs corrigidos não contêm raça/cor, caráter, permanência, custo ou CNES — as análises dessas variáveis do artigo não são reprodutíveis a partir dos arquivos salvos. | ALTA |
| L7 | Custos em reais correntes, sem correção inflacionária. | MÉDIA |
| L8 | Declaração de uso de IA (Copilot, Claude) na elaboração — incompatível com edital-alvo. | ALTA (para submissão) |
| L9 | Conversão de idade SIM incorreta no texto do estudo DLNM ("228 = 28 anos"; correto: 228 = 28 horas). | BAIXA (documental) |
| L10 | Referências majoritariamente internacionais; ausência de base brasileira de regionalização/RAS. | MÉDIA |

---

## 3. Comparação ANÁLISE ANTERIOR → NOVA ANÁLISE → MOTIVO → RESULTADO

| Análise anterior | Nova análise | Motivo da reanálise | Resultado (status) |
|---|---|---|---|
| N=269.751 internações (I60–I69, 2010–2024) | Recontagem a partir do SIH-RD bruto (dedup + filtro DT_INTER) | Verificar completude e dedup | *em execução* |
| Taxa estadual 98,87→123,38; Mann-Kendall tau=0,62 p=0,002 | Mann-Kendall (pymannkendall) sobre série 2010–2024 | Reprovar período (o texto citava 2025) | *a refazer* |
| I64=61,8%; I69=15,9%; I63=9,2%; I60–I62=7,1% | Distribuição CID-10 (I60 a I69, com I69 não eliminado) | Verificar; avaliar I69 separadamente | *a refazer* |
| Mortalidade hospitalar 19,4% (pico 22% em 2021) | Reanálise + **incorporação do SIM** (mortalidade populacional) | O SIH capta só óbito hospitalar; SIM capta causa básica | *a ampliar* |
| INSTRU 100% incompleto → excluído | Inventário de completude por ano/categoria | Corrigir imprecisão | *a corrigir* |
| Raça/cor 25,5% ausente | Completude por ano e região | Documentar viés de informação | *a reproduzir* |
| Kruskal-Wallis + Dunn + qui-quadrado/Monte Carlo | Reprodução + avaliação de Cochran-Armitage, Spearman, binomial negativa, logística, Joinpoint, Moran/LISA | Ampliar validade estatística (apenas se justificável) | *a ampliar* |
| Permanência (mediana 6 d; IIQ 3–11) | Mediana/IIQ + outliers por região/subtipo/desfecho | Distribuição assimétrica | *a reproduzir* |
| Custo por macrorregião (reais correntes) | Reanálise + IPCA (valores corrigidos e correntes) | Comparabilidade intertemporal | *a corrigir* |
| Taxas por 100.000 (SIDRA 6579) | Denominadores com projeções pós-Censo 2022 quando disponíveis | L3 | *a avaliar* |
| Município de residência (polo assistencial) | Fluxo residência × internação (MUNIC_RES × MUNIC_MOV) + CNES | L5 | *a ampliar (novo)* |
| — (não havia SIM) | Mortalidade SIM: taxa/100k, local de ocorrência, razão óbito/internação | Ampliar escopo (exigência da nova fase) | *novo* |
| — (não havia clima) | Integração temperatura/umidade/PM2,5 por região | Conectar dimensão ambiental × territorial | *novo* |

---

## 4. O que pode ser reproduzido vs. corrigido vs. ampliado

**Reproduzível (com novos dados):** perfil por sexo e idade, distribuição CID, mortalidade
hospitalar, permanência, custos, taxas por região.

**Precisa correção:** período (2010–2024, sem "2025"); escolaridade; custos (IPCA);
conversão de idade SIM; denominador populacional.

**Precisa ampliação:** SIM (mortalidade populacional e local de ocorrência); CNES e
fluxo residência→internação; variáveis do SIH ainda não exploradas (diagnóstico
secundário, procedimentos, UTI, natureza jurídica); análise espacial; integração
ambiental.

---

## 5. Decisões metodológicas da nova fase

1. **Período:** 2010-01-01 a 2024-12-31 (15 anos). Não usar 2025 em nenhum resultado.
2. **SIH:** ler arquivos mensais 2010–2025 (para capturar internações de 2024 com alta
   em 2025), deduplicar e filtrar `DT_INTER` 2010–2024.
3. **SIM:** arquivos anuais 2010–2024; causa básica I60–I69; **não misturar** óbito SIM
   com óbito hospitalar do SIH (análises separadas; integração apenas quando
   metodologicamente justificável).
4. **I69:** NÃO eliminado; avaliado separadamente (sequelas).
5. **Escolaridade:** documentar padrão real (INSTRU=0 dominante) e excluir de
   inferência apenas se não informativa.
6. **Raça/cor:** apresentar incompletude explicitamente; não inferir desigualdade onde a
   qualidade não permitir.
7. **Custos:** valores correntes + valores deflacionados (IPCA), quando viável.
8. **Ambiente:** R 4.6.1 indisponível para leitura (readRDS com falha de segmentação);
   leitura dos `.rds` via Python (`rdata` com decodificação Latin-1). Re-download via
   microdatasus inviabilizado no ambiente; dados brutos originais do microdatasus
   (pré-empacotados) usados como fonte, com verificação de completude.
