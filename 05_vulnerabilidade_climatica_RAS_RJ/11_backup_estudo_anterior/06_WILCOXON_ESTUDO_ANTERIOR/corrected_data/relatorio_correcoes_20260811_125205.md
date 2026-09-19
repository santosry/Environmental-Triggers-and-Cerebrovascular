================================================================================
RELATÓRIO DE CORREÇÕES APLICADAS — 20260811_125205
================================================================================

1. IDADE SIM: convertida de centenas para anos
   - Fórmula: idade_anos = idade % 100 (para código 4xx)
   - 999 → NA (ignorado)
   - 146,800 convertidos, 751 ignorados

2. SEXO: padronizado para M/F
   - SIH: 1→M, 3→F
   - SIM: 1→M, 2→F, 0/9→NA

3. SIH: deduplicação
   - Removidos 29,564 registros duplicados (10.3%)
   - Estratégia: manter primeira ocorrência por data+cid+ibge+sexo+idade

4. PANDEMIA: adicionada variável pandemia_restrita (2020-03 a 2022-02)
   - Original: 9324 dias-linha (até 2022-12-31)
   - Restrita: 6570 dias-linha

5. influenza_lag7: documentada como NÃO populada (flag adicionada)

6. SIM sem macro_regiao: 292 eventos documentados com flag exclusão

7. heat_index: documentado em °F

NOTA: Óbitos 2025 permanecem com fonte=SIH_AIHS_MORTE (óbitos intra-hospitalares).
      Esta é uma decisão consciente: são eventos distintos dos óbitos SIM (causa básica).
      O artigo deve refletir esta distinção com precisão.
