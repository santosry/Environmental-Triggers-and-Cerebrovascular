#!/usr/bin/env python3
"""
================================================================================
CORREÇÃO DE DADOS — DLNM Cerebrovascular RJ
Implementa todas as melhorias identificadas na auditoria de 2026-08-11
================================================================================

Correções aplicadas:
  1. IDADE SIM: converter de centenas (228=28a) para anos, 999→NA
  2. SEXO: padronizar SIH(1/3) e SIM(1/2) → 1=M, 2=F
  3. SIH: deduplicar registros repetidos
  4. influenza_lag7: popular com dados reais se disponíveis, ou documentar
  5. Pandemia: criar variável pandemia_restrita (2020-03 a 2022-02)
  6. SIM sem macro_regiao: documentar exclusão
  7. Documentar heat_index em °F

NÃO implementado:
  - Substituição SIM 2025 por óbitos SIH (decisão consciente de manter separação)
================================================================================
"""

import os, sys, warnings, hashlib, json
from datetime import datetime
from pathlib import Path

import numpy as np
import pandas as pd

warnings.filterwarnings("ignore")

ROOT = Path(r"C:/Users/oorie/OneDrive/Documentos/TRABALHOS/DLNM")
CORRECTED_DIR = ROOT / "06_WILCOXON" / "corrected_data"
AUDIT_DIR = ROOT / "06_WILCOXON" / "audit"
CORRECTED_DIR.mkdir(parents=True, exist_ok=True)

RUN_TS = datetime.now().strftime("%Y%m%d_%H%M%S")
print(f"[{RUN_TS}] CORREÇÃO DE DADOS — INÍCIO")

try:
    import pyreadr
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pyreadr", "-q"])
    import pyreadr

# ==============================================================================
# 1. CARREGAMENTO
# ==============================================================================
print("\n[1] Carregando datasets originais...")

macro = pyreadr.read_r(
    str(ROOT / "01_DLNMs_RJ_cerebrovascular/data_processed/dataset_dlnm_macrorregiao.rds")
)[None]
macro['data'] = pd.to_datetime(macro['data'])

sih_ind = pyreadr.read_r(
    str(ROOT / "01_DLNMs_RJ_cerebrovascular/data_interim/sih_cerebrovascular_individual.rds")
)[None]
sih_ind['data'] = pd.to_datetime(sih_ind['data'])

sim_ind = pyreadr.read_r(
    str(ROOT / "01_DLNMs_RJ_cerebrovascular/data_interim/sim_cerebrovascular_individual.rds")
)[None]
sim_ind['data'] = pd.to_datetime(sim_ind['data'])

munic = pyreadr.read_r(
    str(ROOT / "01_DLNMs_RJ_cerebrovascular/data_processed/desfechos_diarios_municipio.rds")
)[None]
munic['data'] = pd.to_datetime(munic['data'])

print(f"  Macro: {macro.shape}")
print(f"  SIH ind: {sih_ind.shape}")
print(f"  SIM ind: {sim_ind.shape}")
print(f"  Munic: {munic.shape}")

# ==============================================================================
# 2. CORREÇÃO: IDADE SIM (centenas → anos)
# ==============================================================================
print("\n[2] CORREÇÃO: IDADE SIM (centenas → anos)...")

sim_ind_original_idade = sim_ind['idade'].copy()

def converter_idade_sim(x):
    """Converte idade SIM de centenas para anos. 999→NA, 0xx→xx meses(≈0), 4xx→xx anos."""
    if pd.isna(x):
        return np.nan
    x = int(x)
    if x == 999:
        return np.nan  # Ignorado
    if x >= 900:
        return np.nan  # Outros ignorados
    codigo = x // 100  # 2=minutos(ignorar), 3=horas(ignorar), 4=anos
    valor = x % 100
    if codigo == 4:  # Anos
        return float(valor)
    elif codigo == 2 or codigo == 3:  # Minutos/horas → ~0 anos
        return 0.0
    elif codigo == 0:  # Meses (menos de 1 ano)
        return round(valor / 12, 1)
    else:
        return np.nan

sim_ind['idade_corrigida'] = sim_ind['idade'].apply(converter_idade_sim)

n_convertidos = sim_ind['idade_corrigida'].notna().sum()
n_ignorados = sim_ind['idade_corrigida'].isna().sum()
n_999 = (sim_ind['idade'] == 999).sum()

print(f"  Convertidos: {n_convertidos:,}")
print(f"  Ignorados (NA): {n_ignorados:,} (dos quais idade=999: {n_999})")
print(f"  Idade corrigida: min={sim_ind['idade_corrigida'].min():.0f}, "
      f"max={sim_ind['idade_corrigida'].max():.0f}, "
      f"median={sim_ind['idade_corrigida'].median():.0f}")

# Distribuição por faixa etária corrigida
bins = [0, 40, 60, 80, 150]
labels = ['<40', '40-59', '60-79', '80+']
sim_ind['faixa_etaria_corrigida'] = pd.cut(
    sim_ind['idade_corrigida'], bins=bins, labels=labels, right=False
)
print(f"  Faixas etárias corrigidas: {sim_ind['faixa_etaria_corrigida'].value_counts().to_dict()}")

# ==============================================================================
# 3. CORREÇÃO: SEXO padronizado (1=M, 2=F)
# ==============================================================================
print("\n[3] CORREÇÃO: SEXO padronizado...")

# SIH: 1=M, 3=F → 1=M, 2=F
sih_ind['sexo_corrigido'] = sih_ind['sexo'].map({'1': 'M', '3': 'F'})
# SIM: 1=M, 2=F, 0=NA, 9=NA
sim_ind['sexo_corrigido'] = sim_ind['sexo'].map({'1': 'M', '2': 'F', '0': np.nan, '9': np.nan})

print(f"  SIH sexo corrigido: {sih_ind['sexo_corrigido'].value_counts().to_dict()}")
print(f"  SIM sexo corrigido: {sim_ind['sexo_corrigido'].value_counts().to_dict()}")

# ==============================================================================
# 4. CORREÇÃO: SIH deduplicação
# ==============================================================================
print("\n[4] CORREÇÃO: SIH deduplicação...")

# Estratégia: para cada combinação única (data, cid3, ibge6, sexo, idade, macro_regiao),
# manter apenas 1 registro por ano_arquivo (priorizando o primeiro mês em que aparece)
n_antes = len(sih_ind)

# Identificar duplicatas: mesmo paciente no mesmo dia com mesmo CID
sih_dedup = sih_ind.drop_duplicates(
    subset=['data', 'cid3', 'ibge6', 'sexo', 'idade', 'macro_regiao', 'ano_arquivo'],
    keep='first'
)

# Remover duplicatas entre meses diferentes (mesmo evento repetido em múltiplos arquivos mensais)
# Ordenar por ano_arquivo e data, manter apenas a primeira ocorrência de cada chave
key_cols = ['cid3', 'ibge6', 'sexo', 'idade', 'data']
sih_dedup = sih_dedup.sort_values(['ano_arquivo', 'data']).drop_duplicates(
    subset=key_cols, keep='first'
)

n_depois = len(sih_dedup)
print(f"  Antes: {n_antes:,} | Depois: {n_depois:,} | Removidos: {n_antes - n_depois:,} ({(n_antes-n_depois)/n_antes*100:.1f}%)")

# Verificar impacto nas contagens diárias agregadas
sih_agg_antes = sih_ind.groupby([sih_ind['data'].dt.date, 'macro_regiao']).size().reset_index(name='n')
sih_agg_depois = sih_dedup.groupby([sih_dedup['data'].dt.date, 'macro_regiao']).size().reset_index(name='n')

# ==============================================================================
# 5. CORREÇÃO: Pandemia com período restrito
# ==============================================================================
print("\n[5] CORREÇÃO: Pandemia restrita (2020-03 a 2022-02)...")

macro['pandemia_original'] = macro['pandemia'].copy()
macro['pandemia_restrita'] = (
    (macro['data'] >= '2020-03-01') & (macro['data'] <= '2022-02-28')
).astype(int)

n_original = macro['pandemia_original'].astype(bool).sum()
n_restrita = macro['pandemia_restrita'].astype(bool).sum()
print(f"  Pandemia original: {n_original} dias-linha")
print(f"  Pandemia restrita: {n_restrita} dias-linha (mar/2020 a fev/2022)")

# ==============================================================================
# 6. CORREÇÃO: Documentar influenza_lag7 zerada
# ==============================================================================
print("\n[6] DOCUMENTAÇÃO: influenza_lag7...")

influenza_sum = macro['influenza_lag7'].sum()
influenza_nas = macro['influenza_lag7'].isna().sum()
print(f"  Soma: {influenza_sum:.1f} | NAs: {influenza_nas}")
print(f"  >> Variável permanece zerada. Flag documentada para o artigo.")

# Criar flag de auditoria
macro['influenza_lag7_audit_flag'] = 'ZERADA_NAO_POPULADA'

# ==============================================================================
# 7. CORREÇÃO: SIM sem macro_regiao — documentar
# ==============================================================================
print("\n[7] DOCUMENTAÇÃO: SIM sem macro_regiao...")

sim_sem_macro = sim_ind[sim_ind['macro_regiao'].isna()]
print(f"  Total sem macro: {len(sim_sem_macro)}")
print(f"  I60-I64 sem macro: {sim_sem_macro['cid3'].isin(['I60','I61','I62','I63','I64']).sum()}")
print(f"  I60-I69 sem macro: {len(sim_sem_macro)}")

# Flag no dataset
sim_ind['excluido_sem_macro'] = sim_ind['macro_regiao'].isna()

# ==============================================================================
# 8. DOCUMENTAÇÃO: Heat index em °F
# ==============================================================================
print("\n[8] DOCUMENTAÇÃO: heat_index em °F...")
print(f"  heat_index: min={macro['heat_index'].min():.1f}, "
      f"median={macro['heat_index'].median():.1f}, max={macro['heat_index'].max():.1f}")
print(f"  >> Unidade: Fahrenheit (°F). Documentado.")

# ==============================================================================
# 9. SALVAR DATASETS CORRIGIDOS
# ==============================================================================
print("\n[9] Salvando datasets corrigidos...")

# 9a. Dataset macro corrigido (adiciona pandemia_restrita, flag influenza)
macro_out = CORRECTED_DIR / f"dataset_macro_CORRIGIDO_{RUN_TS}.csv"
macro.to_csv(macro_out, index=False)
print(f"  Macro corrigido: {macro_out} ({len(macro):,} linhas)")

# 9b. SIH individual corrigido (deduplicado + sexo padronizado)
sih_out = CORRECTED_DIR / f"sih_individual_CORRIGIDO_{RUN_TS}.csv"
sih_dedup.to_csv(sih_out, index=False)
print(f"  SIH corrigido: {sih_out} ({len(sih_dedup):,} linhas)")

# 9c. SIM individual corrigido (idade convertida + sexo padronizado + flag exclusão)
sim_out = CORRECTED_DIR / f"sim_individual_CORRIGIDO_{RUN_TS}.csv"
sim_ind.to_csv(sim_out, index=False)
print(f"  SIM corrigido: {sim_out} ({len(sim_ind):,} linhas)")

# ==============================================================================
# 10. RELATÓRIO DE CORREÇÕES
# ==============================================================================
print("\n[10] Gerando relatório de correções...")

relatorio = f"""================================================================================
RELATÓRIO DE CORREÇÕES APLICADAS — {RUN_TS}
================================================================================

1. IDADE SIM: convertida de centenas para anos
   - Fórmula: idade_anos = idade % 100 (para código 4xx)
   - 999 → NA (ignorado)
   - {n_convertidos:,} convertidos, {n_ignorados:,} ignorados

2. SEXO: padronizado para M/F
   - SIH: 1→M, 3→F
   - SIM: 1→M, 2→F, 0/9→NA

3. SIH: deduplicação
   - Removidos {n_antes - n_depois:,} registros duplicados ({(n_antes-n_depois)/n_antes*100:.1f}%)
   - Estratégia: manter primeira ocorrência por data+cid+ibge+sexo+idade

4. PANDEMIA: adicionada variável pandemia_restrita (2020-03 a 2022-02)
   - Original: {n_original} dias-linha (até 2022-12-31)
   - Restrita: {n_restrita} dias-linha

5. influenza_lag7: documentada como NÃO populada (flag adicionada)

6. SIM sem macro_regiao: {len(sim_sem_macro)} eventos documentados com flag exclusão

7. heat_index: documentado em °F

NOTA: Óbitos 2025 permanecem com fonte=SIH_AIHS_MORTE (óbitos intra-hospitalares).
      Esta é uma decisão consciente: são eventos distintos dos óbitos SIM (causa básica).
      O artigo deve refletir esta distinção com precisão.
"""

with open(CORRECTED_DIR / f"relatorio_correcoes_{RUN_TS}.md", 'w', encoding='utf-8') as f:
    f.write(relatorio)

print(f"  Relatório: {CORRECTED_DIR}/relatorio_correcoes_{RUN_TS}.md")

# ==============================================================================
# 11. VERIFICAÇÃO FINAL
# ==============================================================================
print("\n[11] Verificação final...")

checks = []

# Check 1: SIH dedup não perdeu eventos únicos
sih_unique_dates_before = sih_ind.groupby(sih_ind['data'].dt.date).size()
sih_unique_dates_after = sih_dedup.groupby(sih_dedup['data'].dt.date).size()
checks.append(('SIH datas únicas', len(sih_unique_dates_before) == len(sih_unique_dates_after)))

# Check 2: SIM idade corrigida sem valores absurdos
idade_ok = sim_ind['idade_corrigida'].dropna()
checks.append(('SIM idade 0-120', (idade_ok >= 0).all() and (idade_ok <= 120).all()))

# Check 3: Sexo padronizado
sih_sexo_ok = set(sih_dedup['sexo_corrigido'].dropna().unique()) == {'M', 'F'}
sim_sexo_ok = set(sim_ind['sexo_corrigido'].dropna().unique()) == {'M', 'F'}
checks.append(('SIH sexo M/F', sih_sexo_ok))
checks.append(('SIM sexo M/F', sim_sexo_ok))

# Check 4: Pandemia restrita tem período correto
pand_restrita_dates = macro[macro['pandemia_restrita'].astype(bool)]['data']
checks.append(('Pandemia restrita início', pand_restrita_dates.min() == pd.Timestamp('2020-03-01')))
checks.append(('Pandemia restrita fim', pand_restrita_dates.max() == pd.Timestamp('2022-02-28')))

for name, result in checks:
    status = '✓' if result else '✗ FALHA'
    print(f"  [{status}] {name}")

print(f"\n[{datetime.now().strftime('%Y%m%d_%H%M%S')}] CORREÇÃO DE DADOS CONCLUÍDA")
print(f"  Datasets corrigidos em: {CORRECTED_DIR}")
