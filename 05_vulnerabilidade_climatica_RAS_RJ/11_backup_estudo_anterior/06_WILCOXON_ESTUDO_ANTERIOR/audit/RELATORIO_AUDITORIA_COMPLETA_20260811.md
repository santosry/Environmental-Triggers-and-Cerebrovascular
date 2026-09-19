================================================================================
RELATÓRIO DE AUDITORIA COMPLETA — DLNM Cerebrovascular RJ
Mapeamento de inconsistências, incongruências, erros e anomalias
Data: 2026-08-11
================================================================================

RESUMO: 32 issues identificadas. 4 CRÍTICAS, 8 MODERADAS, 12 MENORES, 8 RESOLVIDAS/OK.

================================================================================
🔴 CRÍTICAS (4) — Exigem correção imediata
================================================================================

[CRIT-1] CONTRADIÇÃO ARTIGO vs DADOS: Óbitos 2025 com AIH
  - O artigo (Métodos, linha ~115) afirma explicitamente:
    "Os óbitos de 2025 NÃO foram completados com a variável MORTE da AIH"
  - O dataset macro contém 3.758 óbitos em 2025, TODOS com fonte=SIH_AIHS_MORTE
  - Soma idêntica: obitos_i60_i69 (2025) = obitos_sih_i60_i69 (2025) = 3.758
  - fonte_obitos em 2025 = 'SIH_AIHS_MORTE' (100%)
  - AÇÃO: Corrigir o artigo OU remover óbitos 2025 do dataset macro

[CRIT-2] Pandemia codificada até 2022-12-31 (deveria ser 2022-02-28)
  - Artigo diz: "período pandêmico (1º mar 2020 a 31 dez 2022)" — OK, bate com variável
  - MAS a sensibilidade "exclusão da pandemia" usa o período TODO? Verificar.
  - A variável `pandemia` inclui mar/2020 a dez/2022 = 34 meses
  - 2022 teve redução drástica de mortalidade COVID vs 2020-2021
  - Incluir mar-dez/2022 como "pandemia" pode diluir o efeito
  - AÇÃO: Considerar análise de sensibilidade com pandemia restrita a 2020-03 a 2022-02

[CRIT-3] Influenza_lag7 = ZERO em todo o dataset
  - Artigo menciona: "controle de internações por influenza (J09-J18) com lag 7"
  - Soma da variável = 0.0 (totalmente zerada)
  - 54 NAs, mas todos os valores não-nulos são zero
  - Ou nunca foi populada, ou a extração falhou
  - AÇÃO: Popular a variável ou remover a menção no artigo

[CRIT-4] IDADE no SIM em centenas (formato DATASUS bruto, NÃO convertido)
  - SIM: idade min=228, max=999, mediana=473
  - 228 = 28 anos, 473 = 73 anos, 999 = ignorado
  - 187 registros com idade=999 (ignorado)
  - No dataset individual, idade NÃO foi convertida para anos
  - Isso afeta TODAS as análises estratificadas por idade
  - A estratificação por faixa etária (usada na análise Wilcoxon) usou 228 como idade!
  - AÇÃO: Converter idade_SIM = idade % 100, tratar 999 como NA

================================================================================
🟡 MODERADAS (8) — Impacto potencial nas análises
================================================================================

[MOD-1] Inconsistência SEXO SIH (1/3) vs SIM (1/2)
  - SIH: 1=M, 3=F. SIM: 1=M, 2=F, 0=ignorado, 9=ignorado
  - 10 registros SIM com sexo=0, 2 com sexo=9
  - Análises que unem as bases precisam padronizar sexo
  - AÇÃO: Padronizar para 1=M, 2=F

[MOD-2] SIM I60-I64: 189 eventos sem macro_regiao (excluídos)
  - Artigo reporta 93.593, dados têm 93.782 (diferença = 189)
  - Todos os 189 têm mun_nome ausente também
  - Idade varie (não são apenas idade=999)
  - Foram excluídos silenciosamente — isso deve ser documentado
  - AÇÃO: Documentar exclusão no fluxograma

[MOD-3] SIH: 25.764 duplicatas exatas (todas as colunas)
  - 8.446 combinações data+cid+ibge+sexo+idade duplicadas
  - Máximo 90 repetições do mesmo registro
  - 107.172 eventos repetidos em até 45 dias (DATASUS mensal sobreposto)
  - Causa: arquivos mensais do SIH contêm internações de meses anteriores
  - AÇÃO: Dependendo de como a agregação diária foi feita,
    essas duplicatas podem inflar as contagens. Verificar se o pipeline
    deduplica antes de agregar.

[MOD-4] I67 no SIM é 30× mais frequente que I63
  - I67 ("outras doenças cerebrovasculares"): 36.853 óbitos
  - I63 (infarto cerebral isquêmico): 1.235 óbitos
  - Razão I61/I63 = 22.2:1 — epidemiologicamente implausível
  - Artigo reconhece como "viés de codificação"
  - AÇÃO: Adicionar nota explícita sobre impacto nas conclusões

[MOD-5] obitos_sih existe como variável auxiliar em TODOS os anos
  - 2010-2024: obitos_sih = 52.432 (óbitos intra-hospitalares, NÃO usados no desfecho)
  - 2025: obitos_sih = 3.758 (USADOS como desfecho, pois SIM 2025 indisponível)
  - A documentação não explica claramente essa dualidade
  - AÇÃO: Documentar no README/data dictionary

[MOD-6] Feriados = 72/ano (8 feriados × 9 macros) — OK estruturalmente
  - Mas a variável é binária por linha (não por dia)
  - 128 dias únicos com feriado em 16 anos (~8/ano)
  - Inclui feriados nacionais + estaduais RJ
  - Validação: 9 macros × ~8 feriados/ano = 72 — CONSISTENTE ✓

[MOD-7] Dow (dia da semana) com labels em português
  - Valores: 'dom','seg','ter','qua','qui','sex','sáb'
  - Distribuição balanceada (todos ~7515)
  - Consistente com 16 anos de dados

[MOD-8] Heat index parece estar em Fahrenheit
  - Valores: 3.6 a 240.3 (mediana 203.2)
  - 240°F ≈ 115°C — valor extremo da fórmula de heat index
  - Provável cálculo correto, mas unidade não documentada
  - AÇÃO: Documentar que heat_index está em °F

================================================================================
🟢 MENORES (12) — Baixo impacto, mas documentar
================================================================================

[MEN-1] NAs em temp_min/temp_max (5 registros: Centro-Sul + Noroeste)
[MEN-2] 31/dez/2025 sem nenhum evento (dia extra, esperado)
[MEN-3] SIH individual termina em 2025-12-30 (macro vai até 2025-12-31)
[MEN-4] municípios cobrem todos os 92 do RJ ✓
[MEN-5] Estações INMET: Noroeste com apenas 1 estação (sem redundância)
[MEN-6] Modelo RDS pesa 3.9 GB — pode causar segfault em máquinas com pouca RAM
[MEN-7] 5844 dias únicos = 16 anos exatos (2010-2025) ✓
[MEN-8] População/offset consistentes (max diff = 0) ✓
[MEN-9] temp_med e ur_med sem NAs ✓
[MEN-10] Nenhuma data futura ou anômala ✓
[MEN-11] Dataset municipal bate perfeitamente com macro (0 divergências) ✓
[MEN-12] Concatenar todas as colunas do dataset macro (32 colunas) ✓

================================================================================
✅ CONSISTENTE / OK (8)
================================================================================

[OK-1] SIH I60-I64 = 238.184 (artigo) = 238.184 (dados) ✓
[OK-2] 9 macrorregiões × 5844 dias = 52.596 linhas ✓
[OK-3] 72 modelos principais (9×4×2) ✓
[OK-4] Total SIH I60-I69 = 288.395 ✓
[OK-5] Total SIM I60-I69 = 147.551 ✓
[OK-6] Período 2010-01-01 a 2025-12-31 = 5844 dias ✓
[OK-7] Cobertura INMET: 26 estações, todas com ≥1 estação/dia ✓
[OK-8] Concordância MW vs KS: 88.5%, correlação 0.869 ✓

================================================================================
AÇÕES RECOMENDADAS (por prioridade)
================================================================================

PRIORIDADE 1 (corrigir antes da publicação):
  1. Decidir se óbitos 2025 usam AIH ou não, e alinhar artigo com dados
  2. Converter idade SIM (idade % 100) no dataset individual
  3. Popular influenza_lag7 ou remover menção no artigo

PRIORIDADE 2 (antes da submissão):
  4. Padronizar sexo entre SIH (1/3) e SIM (1/2)
  5. Deduplicar SIH ou documentar que duplicatas são esperadas
  6. Documentar exclusão dos 189 eventos SIM sem macro
  7. Justificar pandemia até 2022-12-31 vs 2022-02-28

PRIORIDADE 3 (melhorias):
  8. Documentar que heat_index está em °F
  9. Explicar variável obitos_sih como auxiliar
  10. Adicionar nota sobre viés I63/I67 no SIM

================================================================================
