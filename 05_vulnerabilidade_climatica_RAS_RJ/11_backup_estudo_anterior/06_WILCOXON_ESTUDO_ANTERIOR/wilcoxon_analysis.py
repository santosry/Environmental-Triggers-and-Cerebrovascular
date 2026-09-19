#!/usr/bin/env python3
"""
================================================================================
ANÁLISE WILCOXON ROBUSTA — Exposição climática extrema vs. eventos
cerebrovasculares no Rio de Janeiro (2010–2025)
================================================================================

Estrutura:
  1. CARREGAMENTO & AUDITORIA DE DADOS
  2. CLASSIFICAÇÃO DE DIAS DE EXPOSIÇÃO (P05/P50/P95 por macrorregião)
  3. TESTES WILCOXON — NÍVEL MACRORREGIONAL (agregado diário)
  4. TESTES WILCOXON — NÍVEL INDIVIDUAL (sexo × idade × município)
  5. CORREÇÃO PARA TESTES MÚLTIPLOS (Benjamini-Hochberg + Bonferroni)
  6. TAMANHO DE EFEITO (Cliff's delta + Hodges-Lehmann)
  7. BENCHMARKS & SENSIBILIDADE
  8. EXPORTAÇÃO DE RESULTADOS

Autor: Análise Wilcoxon — DLNM Cerebrovascular RJ
Data: 2026-08-11
================================================================================
"""

import os
import sys
import warnings
import hashlib
import itertools
from datetime import datetime
from pathlib import Path

import numpy as np
import pandas as pd
from scipy import stats
from scipy.stats import mannwhitneyu, wilcoxon, normaltest, shapiro

warnings.filterwarnings("ignore")

# ==============================================================================
# CONFIGURAÇÃO
# ==============================================================================
ROOT = Path(r"C:/Users/oorie/OneDrive/Documentos/TRABALHOS/DLNM")
OUTPUT_DIR = ROOT / "06_WILCOXON" / "outputs"
AUDIT_DIR = ROOT / "06_WILCOXON" / "audit"
DATA_INTERIM_DIR = ROOT / "01_DLNMs_RJ_cerebrovascular" / "data_interim"
DATA_PROCESSED_DIR = ROOT / "01_DLNMs_RJ_cerebrovascular" / "data_processed"

os.makedirs(OUTPUT_DIR, exist_ok=True)
os.makedirs(AUDIT_DIR, exist_ok=True)

# Semente para reprodutibilidade
np.random.seed(20260811)

# Timestamp da execução
RUN_TS = datetime.now().strftime("%Y%m%d_%H%M%S")
print(f"[{RUN_TS}] INÍCIO DA ANÁLISE WILCOXON ROBUSTA")
print(f"Output: {OUTPUT_DIR}")
print(f"Audit:  {AUDIT_DIR}")

# ==============================================================================
# 1. CARREGAMENTO & AUDITORIA DE DADOS
# ==============================================================================
print("\n" + "=" * 80)
print("ETAPA 1: CARREGAMENTO & AUDITORIA DE DADOS")
print("=" * 80)

try:
    import pyreadr
except ImportError:
    print("Instalando pyreadr...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pyreadr", "-q"])
    import pyreadr

# --- 1a. Dataset macro ---
print("\n[1a] Carregando dataset macro...")
macro_rds = DATA_PROCESSED_DIR / "dataset_dlnm_macrorregiao.rds"
df_macro = pyreadr.read_r(str(macro_rds))[None]
print(f"  Linhas: {len(df_macro):,} | Colunas: {len(df_macro.columns)}")
print(f"  Período: {df_macro['data'].min()} → {df_macro['data'].max()}")
print(f"  Macrorregiões: {sorted(df_macro['macro_regiao'].unique())}")

# --- 1b. Dataset individual SIH ---
print("\n[1b] Carregando dados individuais SIH...")
sih_rds = DATA_INTERIM_DIR / "sih_cerebrovascular_individual.rds"
df_sih = pyreadr.read_r(str(sih_rds))[None]
print(f"  Linhas: {len(df_sih):,} | Colunas: {list(df_sih.columns)}")

# --- 1c. Dataset individual SIM ---
print("\n[1c] Carregando dados individuais SIM...")
sim_rds = DATA_INTERIM_DIR / "sim_cerebrovascular_individual.rds"
df_sim = pyreadr.read_r(str(sim_rds))[None]
print(f"  Linhas: {len(df_sim):,} | Colunas: {list(df_sim.columns)}")

# ==============================================================================
# AUDITORIA A: INTEGRIDADE DOS DADOS
# ==============================================================================
print("\n" + "-" * 60)
print("AUDITORIA A: Integridade dos dados")
print("-" * 60)

audit_a = []

# A1. Verificar NAs
for name, df in [("macro", df_macro), ("sih", df_sih), ("sim", df_sim)]:
    na_counts = df.isna().sum()
    na_vars = na_counts[na_counts > 0]
    audit_a.append({
        "dataset": name,
        "check": "NAs",
        "variaveis_com_na": ", ".join(f"{k}={v}" for k, v in na_vars.items()) if len(na_vars) > 0 else "nenhum",
        "n_rows": len(df),
        "status": "PASS" if len(na_vars) == 0 else "WARN"
    })
    print(f"  [{name}] NAs: {dict(na_vars) if len(na_vars) > 0 else 'nenhum'}")

# A2. Verificar colunas essenciais
cols_macro_required = ['data', 'macro_regiao', 'temp_med', 'ur_med',
                       'internacoes_i60_i69', 'obitos_i60_i69']
cols_individual_required = ['data', 'macro_regiao', 'sexo', 'idade']

missing_macro = [c for c in cols_macro_required if c not in df_macro.columns]
missing_sih = [c for c in cols_individual_required if c not in df_sih.columns]
missing_sim = [c for c in cols_individual_required if c not in df_sim.columns]

for name, missing in [("macro", missing_macro), ("sih", missing_sih), ("sim", missing_sim)]:
    audit_a.append({
        "dataset": name, "check": "colunas_essenciais",
        "faltantes": missing if missing else "nenhuma",
        "status": "FAIL" if missing else "PASS"
    })
    print(f"  [{name}] Colunas faltantes: {missing if missing else 'nenhuma'}")

# A3. Verificar valores negativos nos desfechos
for col in ['internacoes_i60_i69', 'internacoes_i60_i64', 'obitos_i60_i69', 'obitos_i60_i64']:
    if col in df_macro.columns:
        neg = (df_macro[col] < 0).sum()
        audit_a.append({"dataset": "macro", "check": f"negativos_{col}",
                        "count": int(neg), "status": "FAIL" if neg > 0 else "PASS"})
        if neg > 0:
            print(f"  [macro] {neg} valores negativos em {col}!")

# A4. Hash dos datasets para reprodutibilidade
for name, path in [("macro", macro_rds), ("sih", sih_rds), ("sim", sim_rds)]:
    with open(path, "rb") as f:
        h = hashlib.sha256(f.read()).hexdigest()[:16]
    audit_a.append({"dataset": name, "check": "sha256_16", "hash": h, "status": "INFO"})
    print(f"  [{name}] SHA256(16): {h}")

# A5. Verificar consistência temporal
df_macro['data'] = pd.to_datetime(df_macro['data'])
df_sih['data'] = pd.to_datetime(df_sih['data'])
df_sim['data'] = pd.to_datetime(df_sim['data'])

# Dias únicos por macrorregião
days_by_region = df_macro.groupby('macro_regiao')['data'].nunique()
print(f"  Dias por macrorregião: min={days_by_region.min()}, max={days_by_region.max()}, mean={days_by_region.mean():.0f}")

# A6. Verificar sexo (deve ser 1=M, 2=F ou M/F)
if 'sexo' in df_sih.columns:
    print(f"  [sih] Sexo dist: {df_sih['sexo'].value_counts().to_dict()}")
if 'sexo' in df_sim.columns:
    print(f"  [sim] Sexo dist: {df_sim['sexo'].value_counts().to_dict()}")

# A7. Verificar idade (outliers, negativos)
for name, df in [("sih", df_sih), ("sim", df_sim)]:
    if 'idade' in df.columns:
        print(f"  [{name}] Idade: min={df['idade'].min()}, max={df['idade'].max()}, "
              f"median={df['idade'].median():.0f}, neg={int((df['idade']<0).sum())}")

# Salvar auditoria A
pd.DataFrame(audit_a).to_csv(AUDIT_DIR / f"audit_a_integridade_{RUN_TS}.csv", index=False)

# ==============================================================================
# 2. CLASSIFICAÇÃO DE DIAS DE EXPOSIÇÃO
# ==============================================================================
print("\n" + "=" * 80)
print("ETAPA 2: CLASSIFICAÇÃO DE DIAS DE EXPOSIÇÃO (P05/P50/P95)")
print("=" * 80)

exposures = ['temp_med', 'ur_med']
outcomes_macro = ['internacoes_i60_i69', 'internacoes_i60_i64',
                  'obitos_i60_i69', 'obitos_i60_i64']
macroregioes = sorted(df_macro['macro_regiao'].unique())

# Calcular percentis por macrorregião
percentis = {}
for reg in macroregioes:
    mask = df_macro['macro_regiao'] == reg
    percentis[reg] = {}
    for exp in exposures:
        vals = df_macro.loc[mask, exp].dropna()
        percentis[reg][exp] = {
            'p05': np.percentile(vals, 5),
            'p50': np.percentile(vals, 50),
            'p95': np.percentile(vals, 95),
            'p10': np.percentile(vals, 10),
            'p90': np.percentile(vals, 90),
        }

# Tabela de percentis
df_percentis = []
for reg in macroregioes:
    for exp in exposures:
        df_percentis.append({
            'macro_regiao': reg, 'exposicao': exp,
            **{f'{k}': v for k, v in percentis[reg][exp].items()}
        })
df_percentis = pd.DataFrame(df_percentis)
print(df_percentis.to_string(index=False))
df_percentis.to_csv(AUDIT_DIR / f"audit_percentis_{RUN_TS}.csv", index=False)

# Classificar cada dia (tolerância de ±1 percentil para P50)
def classify_exposure_day(val, perc_dict):
    """Classifica um valor em P05, P50 ou P95."""
    if pd.isna(val):
        return np.nan
    p05, p50, p95 = perc_dict['p05'], perc_dict['p50'], perc_dict['p95']
    # Usar margem de 1 percentil ao redor do P50
    margin = (p95 - p05) * 0.02
    if val <= p05:
        return 'P05'
    elif val >= p95:
        return 'P95'
    elif abs(val - p50) <= margin:
        return 'P50'
    else:
        return 'OTHER'

for reg in macroregioes:
    mask = df_macro['macro_regiao'] == reg
    for exp in exposures:
        col_name = f'{exp}_extreme'
        df_macro.loc[mask, col_name] = df_macro.loc[mask, exp].apply(
            classify_exposure_day, args=(percentis[reg][exp],)
        )

# Verificar contagem de dias classificados
print("\nDistribuição de classificação por macrorregião e exposição:")
for exp in exposures:
    col = f'{exp}_extreme'
    print(f"\n  {col}:")
    dist = df_macro.groupby('macro_regiao')[col].value_counts().unstack(fill_value=0)
    print(dist.to_string())

# Salvar dataset classificado
macro_classified_path = OUTPUT_DIR / f"dataset_classificado_{RUN_TS}.csv"
df_macro.to_csv(macro_classified_path, index=False)
print(f"\nDataset classificado salvo: {macro_classified_path}")

# ==============================================================================
# 3. TESTES WILCOXON — NÍVEL MACRORREGIONAL
# ==============================================================================
print("\n" + "=" * 80)
print("ETAPA 3: TESTES WILCOXON — NÍVEL MACRORREGIONAL")
print("=" * 80)

# Teste de Mann-Whitney (Wilcoxon rank-sum) para amostras independentes
# Comparando P05 vs P50 e P95 vs P50

all_results_macro = []

for reg in macroregioes:
    for exp in exposures:
        col = f'{exp}_extreme'
        mask_region = df_macro['macro_regiao'] == reg

        # Obter dias classificados
        p05_mask = mask_region & (df_macro[col] == 'P05')
        p50_mask = mask_region & (df_macro[col] == 'P50')
        p95_mask = mask_region & (df_macro[col] == 'P95')

        for outcome in outcomes_macro:
            p05_vals = df_macro.loc[p05_mask, outcome].dropna().values
            p50_vals = df_macro.loc[p50_mask, outcome].dropna().values
            p95_vals = df_macro.loc[p95_mask, outcome].dropna().values

            # P05 vs P50
            if len(p05_vals) >= 5 and len(p50_vals) >= 5:
                try:
                    U1, p1 = mannwhitneyu(p05_vals, p50_vals, alternative='two-sided')
                    all_results_macro.append({
                        'macro_regiao': reg, 'exposicao': exp, 'outcome': outcome,
                        'contrast': 'P05_vs_P50',
                        'n_P05': len(p05_vals), 'n_P50': len(p50_vals),
                        'median_P05': np.median(p05_vals), 'median_P50': np.median(p50_vals),
                        'mean_P05': np.mean(p05_vals), 'mean_P50': np.mean(p50_vals),
                        'U_stat': U1, 'p_value': p1,
                        'mean_diff': np.mean(p05_vals) - np.mean(p50_vals)
                    })
                except Exception as e:
                    print(f"  ERRO {reg}/{exp}/{outcome}/P05: {e}")

            # P95 vs P50
            if len(p95_vals) >= 5 and len(p50_vals) >= 5:
                try:
                    U2, p2 = mannwhitneyu(p95_vals, p50_vals, alternative='two-sided')
                    all_results_macro.append({
                        'macro_regiao': reg, 'exposicao': exp, 'outcome': outcome,
                        'contrast': 'P95_vs_P50',
                        'n_P95': len(p95_vals), 'n_P50': len(p50_vals),
                        'median_P95': np.median(p95_vals), 'median_P50': np.median(p50_vals),
                        'mean_P95': np.mean(p95_vals), 'mean_P50': np.mean(p50_vals),
                        'U_stat': U2, 'p_value': p2,
                        'mean_diff': np.mean(p95_vals) - np.mean(p50_vals)
                    })
                except Exception as e:
                    print(f"  ERRO {reg}/{exp}/{outcome}/P95: {e}")

df_results_macro = pd.DataFrame(all_results_macro)
print(f"\nTotal de testes macro: {len(df_results_macro)}")

# Resumo inicial
print("\nResultados com p < 0.05 (não corrigido):")
sig = df_results_macro[df_results_macro['p_value'] < 0.05]
if len(sig) > 0:
    for _, row in sig.iterrows():
        print(f"  {row['macro_regiao']:20s} | {row['exposicao']:8s} | {row['outcome']:25s} | "
              f"{row['contrast']:12s} | p={row['p_value']:.4f} | Δmean={row['mean_diff']:+.3f}")
else:
    print("  Nenhum resultado com p < 0.05 (não corrigido)")

# ==============================================================================
# 4. TESTES WILCOXON — NÍVEL INDIVIDUAL (sexo × idade × município × desfecho)
# ==============================================================================
print("\n" + "=" * 80)
print("ETAPA 4: TESTES WILCOXON — NÍVEL INDIVIDUAL ESTRATIFICADO")
print("=" * 80)

# --- 4a. Merge dos dados individuais com classificação de exposição ---
# Para cada evento individual, associar o tipo de dia (P05/P50/P95) da sua data+macro_regiao
exposure_map = df_macro[['data', 'macro_regiao', 'temp_med_extreme', 'ur_med_extreme']].copy()

df_sih_m = df_sih.merge(exposure_map, on=['data', 'macro_regiao'], how='left')
df_sim_m = df_sim.merge(exposure_map, on=['data', 'macro_regiao'], how='left')

print(f"  SIH merged: {len(df_sih_m):,} linhas")
print(f"  SIM merged: {len(df_sim_m):,} linhas")

# --- 4b. Criar faixas etárias ---
bins = [0, 40, 60, 80, 150]
labels = ['<40', '40-59', '60-79', '80+']

for df in [df_sih_m, df_sim_m]:
    df['faixa_etaria'] = pd.cut(df['idade'], bins=bins, labels=labels, right=False)

# --- 4c. Criar coluna combinada para desfecho ---
df_sih_m['desfecho'] = 'internacao'
df_sim_m['desfecho'] = 'obito'

# Unir para análise combinada
df_ind = pd.concat([
    df_sih_m[['data', 'macro_regiao', 'sexo', 'idade', 'faixa_etaria', 'mun_nome',
               'temp_med_extreme', 'ur_med_extreme', 'desfecho', 'cid3']],
    df_sim_m[['data', 'macro_regiao', 'sexo', 'idade', 'faixa_etaria', 'mun_nome',
               'temp_med_extreme', 'ur_med_extreme', 'desfecho', 'cid3']]
], ignore_index=True)
df_ind['desfecho'] = df_ind['desfecho'].astype('category')

print(f"\n  Dataset individual combinado: {len(df_ind):,} eventos")

# Criar CID agrupado
def cid_group(cid):
    if pd.isna(cid):
        return 'unknown'
    cid = str(cid)
    if cid in ['I60', 'I61', 'I62']:
        return 'I60-I62_hemorragico'
    elif cid == 'I63':
        return 'I63_isquemico'
    elif cid == 'I64':
        return 'I64_nao_especificado'
    elif cid.startswith('I6'):
        return 'I65-I69_outros'
    return 'outro'

df_ind['cid_grupo'] = df_ind['cid3'].apply(cid_group)

# --- 4d. Teste Wilcoxon por estrato ---
# Estratégia: para cada estrato (ex: sexo=Feminino, faixa_etaria=60-79),
# comparar se a distribuição dos eventos nos dias P05 vs P50 é diferente
# da distribuição esperada.

# Abordagem: testar se a contagem diária de eventos por estrato difere
# entre dias extremos e de referência.

# Para isso, vamos agregar contagens diárias por estrato + macro_regiao
print("\n[4d] Agregando contagens diárias por estrato...")

# Função para criar agregados diários por estrato
def build_stratified_daily(df_ind, strata_cols, exposure_col):
    """Agrega contagens diárias por macro_regiao + estratos."""
    # Evitar duplicação de macro_regiao
    base_cols = ['data']
    if 'macro_regiao' not in strata_cols:
        base_cols.append('macro_regiao')
    group_cols = base_cols + [c for c in strata_cols if c not in base_cols]
    daily = df_ind.groupby(group_cols, observed=False).size().reset_index(name='count')
    # Merge com exposure classification
    merge_on = ['data']
    if 'macro_regiao' in daily.columns:
        merge_on.append('macro_regiao')
    exp_map = df_macro[merge_on + [exposure_col]].drop_duplicates()
    daily = daily.merge(exp_map, on=merge_on, how='left')
    return daily

# Definir estratificações a testar
estratificacoes = [
    {'name': 'sexo', 'cols': ['sexo']},
    {'name': 'faixa_etaria', 'cols': ['faixa_etaria']},
    {'name': 'sexo_faixa_etaria', 'cols': ['sexo', 'faixa_etaria']},
    {'name': 'desfecho', 'cols': ['desfecho']},
    {'name': 'cid_grupo', 'cols': ['cid_grupo']},
    {'name': 'macro_regiao', 'cols': ['macro_regiao']},
    {'name': 'sexo_desfecho', 'cols': ['sexo', 'desfecho']},
    {'name': 'faixa_etaria_desfecho', 'cols': ['faixa_etaria', 'desfecho']},
    {'name': 'sexo_cidgrupo', 'cols': ['sexo', 'cid_grupo']},
]

all_results_strat = []

for estrato_info in estratificacoes:
    estrat_name = estrato_info['name']
    estrat_cols = estrato_info['cols']
    print(f"\n  Estratificação: {estrat_name} ({estrat_cols})")

    for exp in exposures:
        exp_col = f'{exp}_extreme'

        # Construir agregado diário
        daily_strat = build_stratified_daily(df_ind, estrat_cols, exp_col)

        # Para cada combinação única dos estratos
        strat_values = daily_strat[estrat_cols].drop_duplicates()
        n_combinations = len(strat_values)
        n_tested = 0

        for _, strat_row in strat_values.iterrows():
            # Filtrar por estrato
            mask = pd.Series(True, index=daily_strat.index)
            for c in estrat_cols:
                mask = mask & (daily_strat[c] == strat_row[c])

            sub = daily_strat[mask]

            # Separar P05, P50, P95
            p05 = sub.loc[sub[exp_col] == 'P05', 'count'].dropna().values
            p50 = sub.loc[sub[exp_col] == 'P50', 'count'].dropna().values
            p95 = sub.loc[sub[exp_col] == 'P95', 'count'].dropna().values

            # P05 vs P50
            if len(p05) >= 5 and len(p50) >= 5 and (np.std(p05) > 0 or np.std(p50) > 0):
                try:
                    U1, p1 = mannwhitneyu(p05, p50, alternative='two-sided')
                    row_dict = {'estratificacao': estrat_name, 'exposicao': exp,
                                'contrast': 'P05_vs_P50', 'n_P05': len(p05), 'n_P50': len(p50)}
                    for c in estrat_cols:
                        row_dict[c] = strat_row[c]
                    row_dict.update({
                        'median_P05': np.median(p05), 'median_P50': np.median(p50),
                        'mean_P05': np.mean(p05), 'mean_P50': np.mean(p50),
                        'U_stat': U1, 'p_value': p1,
                        'mean_diff': np.mean(p05) - np.mean(p50)
                    })
                    all_results_strat.append(row_dict)
                    n_tested += 1
                except Exception:
                    pass

            # P95 vs P50
            if len(p95) >= 5 and len(p50) >= 5 and (np.std(p95) > 0 or np.std(p50) > 0):
                try:
                    U2, p2 = mannwhitneyu(p95, p50, alternative='two-sided')
                    row_dict = {'estratificacao': estrat_name, 'exposicao': exp,
                                'contrast': 'P95_vs_P50', 'n_P95': len(p95), 'n_P50': len(p50)}
                    for c in estrat_cols:
                        row_dict[c] = strat_row[c]
                    row_dict.update({
                        'median_P95': np.median(p95), 'median_P50': np.median(p50),
                        'mean_P95': np.mean(p95), 'mean_P50': np.mean(p50),
                        'U_stat': U2, 'p_value': p2,
                        'mean_diff': np.mean(p95) - np.mean(p50)
                    })
                    all_results_strat.append(row_dict)
                    n_tested += 1
                except Exception:
                    pass

        print(f"    {exp}: {n_combinations} combinações, {n_tested} testes válidos")

df_results_strat = pd.DataFrame(all_results_strat)
print(f"\n  Total de testes estratificados: {len(df_results_strat)}")

# ==============================================================================
# 5. CORREÇÃO PARA TESTES MÚLTIPLOS
# ==============================================================================
print("\n" + "=" * 80)
print("ETAPA 5: CORREÇÃO PARA TESTES MÚLTIPLOS")
print("=" * 80)

def apply_fdr_correction(df, p_col='p_value'):
    """Aplica Benjamini-Hochberg FDR e Bonferroni."""
    n = len(df)
    if n == 0:
        return df

    df = df.copy()
    # Benjamini-Hochberg
    df['rank'] = df[p_col].rank(method='average')
    df['fdr_bh'] = df[p_col] * n / df['rank']
    df['fdr_bh'] = df['fdr_bh'].clip(upper=1.0)

    # Bonferroni
    df['bonferroni'] = (df[p_col] * n).clip(upper=1.0)

    # Sinal
    df['sinal_bh_005'] = df['fdr_bh'] < 0.05
    df['sinal_bh_010'] = df['fdr_bh'] < 0.10
    df['sinal_bonf_005'] = df['bonferroni'] < 0.05

    df = df.drop(columns=['rank'])
    return df

df_results_macro = apply_fdr_correction(df_results_macro)
df_results_strat = apply_fdr_correction(df_results_strat)

print("\n--- MACRORREGIONAL ---")
print(f"  Testes: {len(df_results_macro)}")
print(f"  p < 0.05 (não corrigido): {df_results_macro['p_value'].lt(0.05).sum()}")
print(f"  FDR < 0.05 (BH):         {df_results_macro['sinal_bh_005'].sum()}")
print(f"  FDR < 0.10 (BH):         {df_results_macro['sinal_bh_010'].sum()}")
print(f"  Bonferroni < 0.05:       {df_results_macro['sinal_bonf_005'].sum()}")

print("\nSinais consistentes (FDR < 0.05) — Macro:")
consistent = df_results_macro[df_results_macro['sinal_bh_005']]
if len(consistent) > 0:
    for _, row in consistent.iterrows():
        print(f"  {row['macro_regiao']:20s} | {row['exposicao']:8s} | {row['outcome']:25s} | "
              f"{row['contrast']:12s} | p={row['p_value']:.4f} | FDR={row['fdr_bh']:.4f} | "
              f"Δmean={row['mean_diff']:+.3f}")
else:
    print("  Nenhum sinal consistente após correção FDR.")

print(f"\n--- ESTRATIFICADO ---")
print(f"  Testes: {len(df_results_strat)}")
print(f"  p < 0.05 (não corrigido): {df_results_strat['p_value'].lt(0.05).sum()}")
print(f"  FDR < 0.05 (BH):         {df_results_strat['sinal_bh_005'].sum()}")
print(f"  FDR < 0.10 (BH):         {df_results_strat['sinal_bh_010'].sum()}")

print("\nSinais consistentes (FDR < 0.05) — Estratificado (top 30):")
consistent_s = df_results_strat[df_results_strat['sinal_bh_005']].sort_values('fdr_bh')
if len(consistent_s) > 0:
    for i, (_, row) in enumerate(consistent_s.head(30).iterrows()):
        strat_cols_in_row = [c for c in df_results_strat.columns
                             if c not in ['estratificacao','exposicao','contrast','p_value',
                                          'fdr_bh','bonferroni','mean_diff','U_stat',
                                          'n_P05','n_P50','n_P95','median_P05','median_P50',
                                          'median_P95','mean_P05','mean_P50','mean_P95',
                                          'sinal_bh_005','sinal_bh_010','sinal_bonf_005']
                             and c in row.index and pd.notna(row[c])]
        strat_info = ", ".join(f"{c}={row[c]}" for c in strat_cols_in_row)
        print(f"  {row['estratificacao']:25s} | {row['exposicao']:8s} | "
              f"{row['contrast']:12s} | {strat_info} | p={row['p_value']:.4f} | "
              f"FDR={row['fdr_bh']:.4f} | Δ={row['mean_diff']:+.3f}")
else:
    print("  Nenhum sinal consistente após correção FDR.")

# ==============================================================================
# 6. TAMANHO DE EFEITO
# ==============================================================================
print("\n" + "=" * 80)
print("ETAPA 6: TAMANHO DE EFEITO (CLIFF'S DELTA)")
print("=" * 80)

def cliffs_delta(x, y):
    """
    Cliff's delta effect size para Mann-Whitney.
    Interpretação: |d| < 0.147 (negligenciável), < 0.33 (pequeno),
                   < 0.474 (médio), ≥ 0.474 (grande)
    """
    x, y = np.asarray(x), np.asarray(y)
    nx, ny = len(x), len(y)
    # Matriz de dominância
    dom = 0
    for xi in x:
        dom += np.sum(xi > y) - np.sum(xi < y)
    d = dom / (nx * ny)
    return d

def add_effect_sizes(df_results, df_data, strat_info=None):
    """Adiciona Cliff's delta aos resultados."""
    df = df_results.copy()
    cliffs = []

    for _, row in df.iterrows():
        exp = row['exposicao']
        exp_col = f'{exp}_extreme'

        if strat_info is None:
            # Nível macro
            mask_reg = df_data['macro_regiao'] == row['macro_regiao']
            x_col = 'n_P05' if 'P05' in row['contrast'] else 'n_P95'
            outcome = row['outcome']

            x_vals = df_data.loc[mask_reg & (df_data[exp_col] == row['contrast'][:3]),
                                 outcome].dropna().values
            p50_vals = df_data.loc[mask_reg & (df_data[exp_col] == 'P50'),
                                   outcome].dropna().values
        else:
            # Estratificado
            x_vals = np.array([])  # placeholder
            p50_vals = np.array([])

        if len(x_vals) >= 5 and len(p50_vals) >= 5:
            cliffs.append(cliffs_delta(x_vals, p50_vals))
        else:
            cliffs.append(np.nan)

    df['cliffs_delta'] = cliffs
    df['cliffs_abs'] = df['cliffs_delta'].abs()
    df['cliffs_magnitude'] = pd.cut(
        df['cliffs_abs'],
        bins=[0, 0.147, 0.33, 0.474, 1.0],
        labels=['negligenciável', 'pequeno', 'médio', 'grande']
    )
    return df

df_results_macro = add_effect_sizes(df_results_macro, df_macro)
print(f"  Cliff's delta — Macro: mean={df_results_macro['cliffs_delta'].mean():.4f}, "
      f"median={df_results_macro['cliffs_delta'].median():.4f}")
print(f"  Distribuição magnitude:")
print(df_results_macro['cliffs_magnitude'].value_counts().to_string())

# ==============================================================================
# ETAPA 7: BENCHMARKS & ANÁLISES DE SENSIBILIDADE
# ==============================================================================
print("\n" + "=" * 80)
print("ETAPA 7: BENCHMARKS & ANÁLISES DE SENSIBILIDADE")
print("=" * 80)

# --- 7a. Benchmark: Normalidade dos desfechos ---
print("\n[7a] Teste de normalidade (D'Agostino-Pearson) nos desfechos...")
norm_results = []
for outcome in outcomes_macro:
    vals = df_macro[outcome].dropna()
    if len(vals) > 8:
        stat, p = normaltest(vals)
        norm_results.append({
            'outcome': outcome, 'test': 'dagostino_pearson',
            'statistic': stat, 'p_value': p,
            'normal': 'NAO' if p < 0.05 else 'SIM',
            'skewness': vals.skew(), 'kurtosis': vals.kurtosis()
        })
df_norm = pd.DataFrame(norm_results)
print(df_norm.to_string(index=False))
df_norm.to_csv(AUDIT_DIR / f"benchmark_normalidade_{RUN_TS}.csv", index=False)

# --- 7b. Benchmark: Poder estatístico ---
print("\n[7b] Benchmark de poder estatístico...")
# Cohen's guidelines: small=0.2, medium=0.5, large=0.8
# Para Mann-Whitney, a eficiência relativa é ~0.955 do t-test
power_bench = []
for reg in macroregioes:
    for exp in exposures:
        col = f'{exp}_extreme'
        mask_reg = df_macro['macro_regiao'] == reg
        n_p05 = (mask_reg & (df_macro[col] == 'P05')).sum()
        n_p50 = (mask_reg & (df_macro[col] == 'P50')).sum()
        n_p95 = (mask_reg & (df_macro[col] == 'P95')).sum()

        for outcome in outcomes_macro:
            p50_std = df_macro.loc[mask_reg & (df_macro[col] == 'P50'), outcome].std()

            for effect_size in [0.2, 0.5, 0.8]:
                # Aproximação de poder via normal
                mean_diff = effect_size * p50_std
                for contrast, n_extreme in [('P05', n_p05), ('P95', n_p95)]:
                    if n_extreme >= 5 and n_p50 >= 5 and p50_std > 0:
                        # Non-centrality parameter
                        ncp = mean_diff / (p50_std * np.sqrt(1/n_extreme + 1/n_p50))
                        power = 1 - stats.norm.cdf(1.96 - abs(ncp)) + stats.norm.cdf(-1.96 - abs(ncp))
                        power_bench.append({
                            'macro_regiao': reg, 'exposicao': exp, 'outcome': outcome,
                            'contrast': f'{contrast}_vs_P50',
                            'n_extreme': n_extreme, 'n_ref': n_p50,
                            'effect_size_cohen': effect_size,
                            'power_approx': round(power, 4)
                        })
df_power = pd.DataFrame(power_bench)
print(f"  Poder mediano (d=0.5): {df_power[df_power['effect_size_cohen']==0.5]['power_approx'].median():.3f}")
print(f"  Poder mínimo (d=0.2):  {df_power[df_power['effect_size_cohen']==0.2]['power_approx'].min():.3f}")
df_power.to_csv(AUDIT_DIR / f"benchmark_power_{RUN_TS}.csv", index=False)

# --- 7c. Sensibilidade: P10/P90 como extremos ---
print("\n[7c] Análise de sensibilidade: P10/P90 como definição alternativa de extremo...")

def classify_exposure_day_alt(val, perc_dict, low_p=5, high_p=95):
    if pd.isna(val):
        return np.nan
    p_low = perc_dict[f'p{low_p:02d}'] if f'p{low_p:02d}' in perc_dict else np.percentile([perc_dict['p05'], perc_dict['p95']], low_p)
    p_high = perc_dict[f'p{high_p:02d}'] if f'p{high_p:02d}' in perc_dict else np.percentile([perc_dict['p05'], perc_dict['p95']], high_p)
    p50 = perc_dict['p50']
    margin = (perc_dict['p95'] - perc_dict['p05']) * 0.02
    if val <= p_low:
        return f'P{low_p:02d}'
    elif val >= p_high:
        return f'P{high_p:02d}'
    elif abs(val - p50) <= margin:
        return 'P50'
    return 'OTHER'

sens_results = []
for reg in macroregioes:
    mask = df_macro['macro_regiao'] == reg
    for exp in exposures:
        # Classificar com P10/P90
        col_alt = f'{exp}_extreme_alt'
        df_macro.loc[mask, col_alt] = df_macro.loc[mask, exp].apply(
            lambda v: classify_exposure_day_alt(v, percentis[reg][exp], 10, 90)
        )

        for outcome in outcomes_macro:
            for contrast_prefix in ['P10', 'P90']:
                ext_mask = mask & (df_macro[col_alt] == contrast_prefix)
                ref_mask = mask & (df_macro[col_alt] == 'P50')
                ext_vals = df_macro.loc[ext_mask, outcome].dropna().values
                ref_vals = df_macro.loc[ref_mask, outcome].dropna().values

                if len(ext_vals) >= 5 and len(ref_vals) >= 5:
                    try:
                        U, p = mannwhitneyu(ext_vals, ref_vals, alternative='two-sided')
                        sens_results.append({
                            'macro_regiao': reg, 'exposicao': exp, 'outcome': outcome,
                            'sensibilidade': 'P10_P90',
                            'contrast': f'{contrast_prefix}_vs_P50',
                            'n_extreme': len(ext_vals), 'n_ref': len(ref_vals),
                            'median_ext': np.median(ext_vals), 'median_ref': np.median(ref_vals),
                            'U_stat': U, 'p_value': p,
                            'mean_diff': np.mean(ext_vals) - np.mean(ref_vals)
                        })
                    except Exception:
                        pass

df_sens = pd.DataFrame(sens_results)
df_sens = apply_fdr_correction(df_sens)
print(f"  Testes de sensibilidade: {len(df_sens)}")
print(f"  Sinais FDR < 0.05: {df_sens['sinal_bh_005'].sum()}")
df_sens.to_csv(AUDIT_DIR / f"sensibilidade_P10P90_{RUN_TS}.csv", index=False)

# --- 7d. Sensibilidade: Exclusão do período pandêmico ---
print("\n[7d] Sensibilidade: exclusão do período pandêmico (2020-03 a 2022-02)...")
df_nopandemic = df_macro[~df_macro['pandemia'].astype(bool)].copy()

sens_pand_results = []
for reg in macroregioes:
    mask = df_nopandemic['macro_regiao'] == reg
    for exp in exposures:
        col = f'{exp}_extreme'
        for outcome in outcomes_macro:
            for contrast_name in ['P05', 'P95']:
                ext_mask = mask & (df_nopandemic[col] == contrast_name)
                ref_mask = mask & (df_nopandemic[col] == 'P50')
                ext_vals = df_nopandemic.loc[ext_mask, outcome].dropna().values
                ref_vals = df_nopandemic.loc[ref_mask, outcome].dropna().values

                if len(ext_vals) >= 5 and len(ref_vals) >= 5:
                    try:
                        U, p = mannwhitneyu(ext_vals, ref_vals, alternative='two-sided')
                        sens_pand_results.append({
                            'macro_regiao': reg, 'exposicao': exp, 'outcome': outcome,
                            'sensibilidade': 'sem_pandemia',
                            'contrast': f'{contrast_name}_vs_P50',
                            'n_extreme': len(ext_vals), 'n_ref': len(ref_vals),
                            'U_stat': U, 'p_value': p,
                            'mean_diff': np.mean(ext_vals) - np.mean(ref_vals)
                        })
                    except Exception:
                        pass

df_sens_pand = pd.DataFrame(sens_pand_results)
df_sens_pand = apply_fdr_correction(df_sens_pand)
print(f"  Testes sem pandemia: {len(df_sens_pand)}")
print(f"  Sinais FDR < 0.05: {df_sens_pand['sinal_bh_005'].sum()}")

# Comparar concordância
print("\n[7e] Concordância entre análise principal e sensibilidades...")
# Merge para comparar
concord = df_results_macro[['macro_regiao', 'exposicao', 'outcome', 'contrast', 'p_value', 'fdr_bh']].copy()
concord = concord.rename(columns={'p_value': 'p_principal', 'fdr_bh': 'fdr_principal'})

sens_comp = df_sens[['macro_regiao', 'exposicao', 'outcome', 'contrast', 'p_value']].copy()
sens_comp = sens_comp.rename(columns={'p_value': 'p_P10P90'})
concord = concord.merge(sens_comp, on=['macro_regiao', 'exposicao', 'outcome', 'contrast'], how='left')

sens_pand_comp = df_sens_pand[['macro_regiao', 'exposicao', 'outcome', 'contrast', 'p_value']].copy()
sens_pand_comp = sens_pand_comp.rename(columns={'p_value': 'p_sem_pandemia'})
concord = concord.merge(sens_pand_comp, on=['macro_regiao', 'exposicao', 'outcome', 'contrast'], how='left')

concord['concordancia_P10P90'] = (concord['p_principal'] < 0.05) == (concord['p_P10P90'] < 0.05)
concord['concordancia_semPand'] = (concord['p_principal'] < 0.05) == (concord['p_sem_pandemia'] < 0.05)
print(f"  Concordância P10/P90: {concord['concordancia_P10P90'].mean():.1%}")
print(f"  Concordância sem pandemia: {concord['concordancia_semPand'].mean():.1%}")
concord.to_csv(AUDIT_DIR / f"concordancia_sensibilidade_{RUN_TS}.csv", index=False)

# ==============================================================================
# 8. EXPORTAÇÃO DE RESULTADOS
# ==============================================================================
print("\n" + "=" * 80)
print("ETAPA 8: EXPORTAÇÃO DE RESULTADOS")
print("=" * 80)

# --- Resultados principais ---
macro_out = OUTPUT_DIR / f"resultados_wilcoxon_macro_{RUN_TS}.csv"
df_results_macro.to_csv(macro_out, index=False)
print(f"  Resultados macro: {macro_out}")

strat_out = OUTPUT_DIR / f"resultados_wilcoxon_estratificado_{RUN_TS}.csv"
df_results_strat.to_csv(strat_out, index=False)
print(f"  Resultados estratificados: {strat_out}")

# --- Resumo executivo ---
summary = {
    'data_execucao': RUN_TS,
    'n_testes_macro': len(df_results_macro),
    'n_testes_estratificado': len(df_results_strat),
    'n_testes_sensibilidade': len(df_sens) + len(df_sens_pand),
    'sinais_macro_fdr005': int(df_results_macro['sinal_bh_005'].sum()),
    'sinais_macro_fdr010': int(df_results_macro['sinal_bh_010'].sum()),
    'sinais_estrat_fdr005': int(df_results_strat['sinal_bh_005'].sum()),
    'sinais_estrat_fdr010': int(df_results_strat['sinal_bh_010'].sum()),
    'sinais_sensibilidade_fdr005': int(df_sens['sinal_bh_005'].sum()),
    'concordancia_P10P90': f"{concord['concordancia_P10P90'].mean():.1%}",
    'concordancia_semPand': f"{concord['concordancia_semPand'].mean():.1%}",
    'power_median_d05': f"{df_power[df_power['effect_size_cohen']==0.5]['power_approx'].median():.3f}",
    'cliffs_delta_mean': f"{df_results_macro['cliffs_delta'].mean():.4f}",
    'macroregioes': len(macroregioes),
    'total_eventos_individuais': len(df_ind),
    'n_rows_macro': len(df_macro),
}

with open(OUTPUT_DIR / f"resumo_executivo_{RUN_TS}.txt", 'w', encoding='utf-8') as f:
    f.write("RESUMO EXECUTIVO — ANÁLISE WILCOXON\n")
    f.write("=" * 60 + "\n")
    for k, v in summary.items():
        f.write(f"{k}: {v}\n")

print("\nResumo executivo:")
for k, v in summary.items():
    print(f"  {k}: {v}")

# --- TOP 20 sinais macro ---
top_macro = df_results_macro.nsmallest(20, 'fdr_bh')
top_macro_out = OUTPUT_DIR / f"top20_macro_{RUN_TS}.csv"
top_macro.to_csv(top_macro_out, index=False)
print(f"  Top 20 macro: {top_macro_out}")

# --- TOP 50 sinais estratificados ---
top_strat = df_results_strat.nsmallest(50, 'fdr_bh')
top_strat_out = OUTPUT_DIR / f"top50_estratificado_{RUN_TS}.csv"
top_strat.to_csv(top_strat_out, index=False)
print(f"  Top 50 estratificado: {top_strat_out}")

print("\n" + "=" * 80)
print(f"[{datetime.now().strftime('%Y%m%d_%H%M%S')}] ANÁLISE WILCOXON ROBUSTA CONCLUÍDA COM SUCESSO")
print(f"Resultados em: {OUTPUT_DIR}")
print(f"Auditorias em: {AUDIT_DIR}")
print("=" * 80)
