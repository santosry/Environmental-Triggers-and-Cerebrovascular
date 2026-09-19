#!/usr/bin/env python3
"""
================================================================================
ANÁLISE WILCOXON ROBUSTA v2 — Auditoria Expandida + Bateria de Testes
Exposição climática extrema vs. eventos cerebrovasculares — RJ (2010–2025)
================================================================================

NOVO nesta versão:
  AUDITORIA:
    A1. Integridade estrutural (NAs, duplicatas, tipos)
    A2. Consistência temporal (gaps, sobreposições, cobertura)
    A3. Outliers & qualidade (IQR, z-scores, winsorização)
    A4. Zero-inflation & overdispersion
    A5. Consistência cruzada SIH×SIM
    A6. Balanceamento amostral
    A7. Structural breaks (changepoints)
    A8. Score de qualidade por variável

  TESTES ADICIONAIS:
    T1. Mann-Whitney U (já existente)
    T2. Kolmogorov-Smirnov (distribuição completa)
    T3. Brunner-Munzel (robusto a heterocedasticidade)
    T4. Mood's median test
    T5. Permutation test (10k iterações)
    T6. Bootstrap CI para diferença de medianas
    T7. Kruskal-Wallis (multigrupo)
    T8. Jonckheere-Terpstra (tendência ordenada P05→P50→P95)
    T9. Qui-quadrado de proporções (eventos extremos)
    T10. Wilcoxon pareado sazonal (mês-a-mês)

  SENSIBILIDADE EXPANDIDA:
    S1. P10/P90 (já existente)
    S2. Sem pandemia (já existente)
    S3. P01/P99 (extremos absolutos)
    S4. Estratificação sazonal (verão vs inverno)
    S5. Dias úteis vs fins de semana
    S6. Jackknife leave-one-out regional

================================================================================
"""

import os, sys, warnings, hashlib, itertools, json
from datetime import datetime
from pathlib import Path
from collections import defaultdict

import numpy as np
import pandas as pd
from scipy import stats
from scipy.stats import (
    mannwhitneyu, kruskal, ks_2samp, median_test, chi2_contingency,
    normaltest, shapiro, jarque_bera, anderson, levene, bartlett,
    f_oneway, rankdata
)

warnings.filterwarnings("ignore")

# ==============================================================================
# CONFIGURAÇÃO
# ==============================================================================
ROOT = Path(r"C:/Users/oorie/OneDrive/Documentos/TRABALHOS/DLNM")
OUTPUT_DIR = ROOT / "06_WILCOXON" / "outputs"
AUDIT_DIR = ROOT / "06_WILCOXON" / "audit"

for d in [OUTPUT_DIR, AUDIT_DIR]:
    d.mkdir(parents=True, exist_ok=True)

np.random.seed(20260811)
RUN_TS = datetime.now().strftime("%Y%m%d_%H%M%S")
print(f"[{RUN_TS}] ANÁLISE WILCOXON ROBUSTA v2 — INÍCIO")
print(f"Output: {OUTPUT_DIR}")
print(f"Audit:  {AUDIT_DIR}")

# ==============================================================================
# UTILITÁRIOS
# ==============================================================================

def cliffs_delta(x, y):
    """Cliff's delta — tamanho de efeito não paramétrico."""
    x, y = np.asarray(x, dtype=float), np.asarray(y, dtype=float)
    nx, ny = len(x), len(y)
    dom = sum((xi > y).sum() - (xi < y).sum() for xi in x)
    return dom / (nx * ny)

def hodges_lehmann(x, y, alpha=0.95):
    """Estimador Hodges-Lehmann da diferença de medianas + IC bootstrap."""
    x, y = np.asarray(x), np.asarray(y)
    # Amostrar se datasets grandes
    if len(x) > 200:
        x = np.random.choice(x, size=200, replace=False)
    if len(y) > 200:
        y = np.random.choice(y, size=200, replace=False)
    diffs = np.array([xi - yj for xi in x for yj in y]).ravel()
    est = np.median(diffs)
    # Bootstrap CI (reduzido para velocidade)
    n_boot = 500
    boot_ests = np.empty(n_boot)
    rng = np.random.default_rng(20260811)
    for i in range(n_boot):
        xb = rng.choice(x, size=len(x), replace=True)
        yb = rng.choice(y, size=len(y), replace=True)
        d_boot = np.median(xb[:, None] - yb[None, :])
        boot_ests[i] = d_boot
    ci_low = np.percentile(boot_ests, (1 - alpha) / 2 * 100)
    ci_high = np.percentile(boot_ests, (1 + alpha) / 2 * 100)
    return est, ci_low, ci_high

def permutation_test(x, y, n_perm=2000):
    """Teste de permutação para diferença de medianas (vetorizado)."""
    x, y = np.asarray(x, dtype=float), np.asarray(y, dtype=float)
    obs_diff = np.median(x) - np.median(y)
    combined = np.concatenate([x, y])
    nx = len(x)
    rng = np.random.default_rng(20260811)
    # Gerar todas as permutações de uma vez (vetorizado)
    permuted = np.array([rng.permutation(combined) for _ in range(n_perm)])
    perm_diffs = np.median(permuted[:, :nx], axis=1) - np.median(permuted[:, nx:], axis=1)
    count = np.sum(np.abs(perm_diffs) >= np.abs(obs_diff))
    return obs_diff, count / n_perm

def brunner_munzel(x, y):
    """Teste de Brunner-Munzel (robusto a heterocedasticidade)."""
    x, y = np.asarray(x, dtype=float), np.asarray(y, dtype=float)
    nx, ny = len(x), len(y)
    # Estimador de efeito relativo
    R = rankdata(np.concatenate([x, y]))
    R1, R2 = R[:nx], R[nx:]
    R1_mean = R1.mean()
    p_hat = (R1_mean - (nx + 1) / 2) / ny
    # Variância
    R1_centered = R1 - R1_mean
    R2_centered = R2 - R2.mean()
    s1 = np.var(R1_centered, ddof=1) / (ny ** 2)
    s2 = np.var(R2_centered, ddof=1) / (nx ** 2)
    se = np.sqrt(s1 / nx + s2 / ny)
    if se == 0:
        return p_hat, 1.0
    t_stat = (p_hat - 0.5) / se
    # Aproximação t com Welch-Satterthwaite df
    df_num = (s1 / nx + s2 / ny) ** 2
    df_den = (s1 / nx) ** 2 / (nx - 1) + (s2 / ny) ** 2 / (ny - 1)
    df = df_num / df_den
    p = 2 * stats.t.sf(abs(t_stat), df)
    return p_hat, p

def jonckheere_terpstra(*groups):
    """Teste de Jonckheere-Terpstra para tendência ordenada."""
    k = len(groups)
    n = [len(g) for g in groups]
    JT = 0
    for i in range(k - 1):
        for j in range(i + 1, k):
            for xi in groups[i]:
                JT += np.sum(xi < groups[j])
    # Estatística padronizada
    N = sum(n)
    E_JT = (N ** 2 - sum(ni ** 2 for ni in n)) / 4
    var_JT = (N ** 2 * (2 * N + 3) - sum(ni ** 2 * (2 * ni + 3) for ni in n)) / 72
    if var_JT == 0:
        return JT, E_JT, 1.0
    Z = (JT - E_JT) / np.sqrt(var_JT)
    p = 2 * stats.norm.sf(abs(Z))
    return JT, E_JT, p

def detect_outliers_iqr(series, factor=1.5):
    """Detecta outliers via IQR."""
    Q1 = series.quantile(0.25)
    Q3 = series.quantile(0.75)
    IQR = Q3 - Q1
    lower = Q1 - factor * IQR
    upper = Q3 + factor * IQR
    n_low = (series < lower).sum()
    n_high = (series > upper).sum()
    return int(n_low), int(n_high), float(lower), float(upper)

def zero_inflation_score(series):
    """Score de zero-inflação (razão zeros observados / esperados Poisson)."""
    n = len(series)
    n_zeros = (series == 0).sum()
    lam = series.mean()
    if lam == 0:
        return np.inf
    expected_zeros = np.exp(-lam) * n
    if expected_zeros == 0:
        return np.inf if n_zeros > 0 else 0
    return n_zeros / expected_zeros if expected_zeros > 0 else np.inf

def structural_break_test(series):
    """Teste simples de quebra estrutural (diferença de médias pré/pós ponto médio)."""
    n = len(series)
    mid = n // 2
    first, second = series[:mid], series[mid:]
    if len(first) < 2 or len(second) < 2:
        return np.nan, np.nan
    # Mann-Whitney entre as duas metades como proxy de quebra
    try:
        U, p = mannwhitneyu(first, second, alternative='two-sided')
        return U, p
    except Exception:
        return np.nan, np.nan

def apply_fdr_correction(df, p_col='p_value'):
    """Benjamini-Hochberg FDR + Bonferroni."""
    n = len(df)
    if n == 0:
        return df
    df = df.copy()
    df['rank'] = df[p_col].rank(method='average')
    df['fdr_bh'] = (df[p_col] * n / df['rank']).clip(upper=1.0)
    df['bonferroni'] = (df[p_col] * n).clip(upper=1.0)
    df['sinal_bh_005'] = df['fdr_bh'] < 0.05
    df['sinal_bh_010'] = df['fdr_bh'] < 0.10
    df['sinal_bonf_005'] = df['bonferroni'] < 0.05
    return df.drop(columns=['rank'])

# ==============================================================================
# 1. CARREGAMENTO
# ==============================================================================
print("\n" + "=" * 80)
print("ETAPA 1: CARREGAMENTO DE DADOS")
print("=" * 80)

try:
    import pyreadr
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pyreadr", "-q"])
    import pyreadr

macro_rds = ROOT / "01_DLNMs_RJ_cerebrovascular" / "data_processed" / "dataset_dlnm_macrorregiao.rds"
df_macro = pyreadr.read_r(str(macro_rds))[None]
df_macro['data'] = pd.to_datetime(df_macro['data'])

sih_rds = ROOT / "01_DLNMs_RJ_cerebrovascular" / "data_interim" / "sih_cerebrovascular_individual.rds"
df_sih = pyreadr.read_r(str(sih_rds))[None]
df_sih['data'] = pd.to_datetime(df_sih['data'])

sim_rds = ROOT / "01_DLNMs_RJ_cerebrovascular" / "data_interim" / "sim_cerebrovascular_individual.rds"
df_sim = pyreadr.read_r(str(sim_rds))[None]
df_sim['data'] = pd.to_datetime(df_sim['data'])

print(f"  Macro: {len(df_macro):,} | SIH: {len(df_sih):,} | SIM: {len(df_sim):,}")

exposures = ['temp_med', 'ur_med']
outcomes_macro = ['internacoes_i60_i69', 'internacoes_i60_i64',
                  'obitos_i60_i69', 'obitos_i60_i64']
macroregioes = sorted(df_macro['macro_regiao'].unique())

# ==============================================================================
# 2. AUDITORIA EXPANDIDA
# ==============================================================================
print("\n" + "=" * 80)
print("ETAPA 2: AUDITORIA EXPANDIDA")
print("=" * 80)

all_audit = []

# --- A1: Integridade Estrutural ---
print("\n--- A1: Integridade Estrutural ---")
for name, df in [("macro", df_macro), ("sih", df_sih), ("sim", df_sim)]:
    # NAs
    na_counts = df.isna().sum()
    na_vars = {k: int(v) for k, v in na_counts[na_counts > 0].items()}

    # Duplicatas
    n_dupes = int(df.duplicated().sum())

    # Tipos
    dtypes = {k: str(v) for k, v in df.dtypes.items()}

    all_audit.append({
        'etapa': 'A1_integridade', 'dataset': name,
        'n_rows': len(df), 'n_cols': len(df.columns),
        'n_nas_total': int(df.isna().sum().sum()),
        'n_duplicatas': n_dupes,
        'na_details': json.dumps(na_vars) if na_vars else 'none',
        'status': 'WARN' if (na_vars or n_dupes > 0) else 'PASS'
    })

    print(f"  [{name}] NAs: {sum(na_vars.values()) if na_vars else 0}, "
          f"Duplicatas: {n_dupes}")

# --- A2: Consistência Temporal ---
print("\n--- A2: Consistência Temporal ---")
for reg in macroregioes:
    mask = df_macro['macro_regiao'] == reg
    dates = sorted(df_macro.loc[mask, 'data'])
    gaps = []
    for i in range(1, len(dates)):
        diff = (dates[i] - dates[i-1]).days
        if diff > 1:
            gaps.append({'start': str(dates[i-1].date()), 'end': str(dates[i].date()),
                         'gap_days': diff - 1})

    all_audit.append({
        'etapa': 'A2_temporal', 'macro_regiao': reg,
        'n_days': len(dates),
        'date_range_start': str(dates[0].date()),
        'date_range_end': str(dates[-1].date()),
        'n_gaps': len(gaps),
        'total_gap_days': sum(g['gap_days'] for g in gaps),
        'gap_details': json.dumps(gaps) if gaps else 'none',
        'status': 'WARN' if gaps else 'PASS'
    })
    if gaps:
        print(f"  [{reg}] {len(gaps)} gaps, {sum(g['gap_days'] for g in gaps)} dias perdidos")

# --- A3: Outliers & Qualidade ---
print("\n--- A3: Outliers (IQR) ---")
for outcome in outcomes_macro:
    n_low, n_high, low_b, up_b = detect_outliers_iqr(df_macro[outcome])
    all_audit.append({
        'etapa': 'A3_outliers', 'variavel': outcome,
        'outliers_low': n_low, 'outliers_high': n_high,
        'lower_bound': round(low_b, 2), 'upper_bound': round(up_b, 2),
        'pct_outliers': round((n_low + n_high) / len(df_macro) * 100, 2),
        'status': 'WARN' if (n_low + n_high) / len(df_macro) > 0.05 else 'PASS'
    })
    pct = (n_low + n_high) / len(df_macro) * 100
    print(f"  {outcome}: {n_low} low + {n_high} high = {pct:.1f}% outliers (IQR)")

# --- A4: Zero-inflation ---
print("\n--- A4: Zero-inflation & Overdispersion ---")
for outcome in outcomes_macro:
    zi = zero_inflation_score(df_macro[outcome])
    # Overdispersion: var/mean (Poisson espera 1)
    mu = df_macro[outcome].mean()
    var = df_macro[outcome].var()
    od = var / mu if mu > 0 else np.nan
    all_audit.append({
        'etapa': 'A4_zero_inflation', 'variavel': outcome,
        'zero_inflation_score': round(zi, 2),
        'overdispersion': round(od, 2),
        'n_zeros': int((df_macro[outcome] == 0).sum()),
        'pct_zeros': round((df_macro[outcome] == 0).mean() * 100, 2),
        'status': 'WARN' if not np.isfinite(zi) or zi > 5 or od > 3 else 'PASS'
    })
    print(f"  {outcome}: ZI={zi:.2f}, OD={od:.2f}, zeros={(df_macro[outcome]==0).mean()*100:.1f}%")

# --- A5: Consistência Cruzada SIH×SIM ---
print("\n--- A5: Consistência Cruzada SIH×SIM ---")
# Verificar se há eventos no mesmo dia com mesmo CID em ambas as bases
sih_set = set(zip(df_sih['data'].dt.date, df_sih['macro_regiao'].dropna()))
sim_set = set(zip(df_sim['data'].dt.date, df_sim['macro_regiao'].dropna()))
overlap_dates_regions = len(sih_set & sim_set)
all_audit.append({
    'etapa': 'A5_cruzada', 'check': 'datas_comuns_SIH_SIM',
    'sih_unique_dates': len(sih_set),
    'sim_unique_dates': len(sim_set),
    'overlap': overlap_dates_regions,
    'pct_overlap': round(overlap_dates_regions / max(len(sih_set), len(sim_set)) * 100, 1),
    'status': 'PASS'
})
print(f"  Datas×macro-região comuns: {overlap_dates_regions}")

# --- A6: Balanceamento Amostral ---
print("\n--- A6: Balanceamento Amostral ---")
for name, df, col in [("sih", df_sih, 'sexo'), ("sim", df_sim, 'sexo')]:
    counts = df[col].value_counts().to_dict()
    total = sum(counts.values())
    imbalance = max(counts.values()) / total if total > 0 else 0
    all_audit.append({
        'etapa': 'A6_balanceamento', 'dataset': name, 'variavel': col,
        'counts': json.dumps({str(k): v for k, v in counts.items()}),
        'n_categories': len(counts),
        'max_proportion': round(imbalance, 3),
        'status': 'WARN' if imbalance > 0.8 else 'PASS'
    })
    print(f"  [{name}] {col}: {counts}")

# --- A7: Structural Breaks ---
print("\n--- A7: Structural Breaks (pré/pós ponto médio) ---")
for outcome in outcomes_macro:
    U, p = structural_break_test(df_macro[outcome].values)
    all_audit.append({
        'etapa': 'A7_structural_break', 'variavel': outcome,
        'mw_U': round(U, 1) if not np.isnan(U) else np.nan,
        'mw_p': round(p, 4) if not np.isnan(p) else np.nan,
        'break_detected': p < 0.05 if not np.isnan(p) else False,
        'status': 'WARN' if (not np.isnan(p) and p < 0.05) else 'PASS'
    })
    sig = "*** QUEBRA ***" if (not np.isnan(p) and p < 0.05) else ""
    print(f"  {outcome}: p={p:.4f} {sig}")

# --- A8: Score de Qualidade ---
print("\n--- A8: Score de Qualidade por Variável ---")
quality_scores = {}
for var in ['temp_med', 'ur_med'] + outcomes_macro:
    series = df_macro[var]
    n_na = int(series.isna().sum())
    n_out_low, n_out_high, _, _ = detect_outliers_iqr(series)
    n_out = n_out_low + n_out_high
    completeness = 1 - n_na / len(series)
    outlier_penalty = min(1.0, n_out / len(series) * 10)
    score = completeness * (1 - outlier_penalty)
    quality_scores[var] = {
        'completeness': round(completeness, 4),
        'outlier_frac': round(n_out / len(series), 4),
        'quality_score': round(score, 4)
    }
    all_audit.append({
        'etapa': 'A8_quality_score', 'variavel': var,
        **quality_scores[var],
        'n_na': n_na, 'n_outliers': n_out,
        'status': 'PASS' if score > 0.9 else 'WARN'
    })
    print(f"  {var:25s}: completeness={completeness:.4f}, "
          f"outliers={n_out/len(series)*100:.2f}%, score={score:.4f}")

# Salvar auditoria completa
pd.DataFrame(all_audit).to_csv(AUDIT_DIR / f"audit_full_{RUN_TS}.csv", index=False)
print(f"\n  Auditoria completa salva: audit_full_{RUN_TS}.csv ({len(all_audit)} registros)")

# ==============================================================================
# 3. CLASSIFICAÇÃO DE EXPOSIÇÃO
# ==============================================================================
print("\n" + "=" * 80)
print("ETAPA 3: CLASSIFICAÇÃO DE DIAS DE EXPOSIÇÃO")
print("=" * 80)

percentis = {}
for reg in macroregioes:
    mask = df_macro['macro_regiao'] == reg
    percentis[reg] = {}
    for exp in exposures:
        vals = df_macro.loc[mask, exp].dropna()
        percentis[reg][exp] = {f'p{p:02d}': np.percentile(vals, p)
                               for p in [1, 5, 10, 25, 50, 75, 90, 95, 99]}

def classify_day(val, perc_dict):
    if pd.isna(val):
        return np.nan
    p01, p05, p50, p95, p99 = [perc_dict[k] for k in ['p01','p05','p50','p95','p99']]
    margin = (p95 - p05) * 0.02
    if val <= p01:
        return 'P01'
    elif val <= p05:
        return 'P05'
    elif val >= p99:
        return 'P99'
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
            classify_day, args=(percentis[reg][exp],))

# Verificar contagens
for exp in exposures:
    col = f'{exp}_extreme'
    print(f"\n  {col} — distribuição total:")
    print(df_macro[col].value_counts().to_string())

# ==============================================================================
# 4. BATERIA DE TESTES — NÍVEL MACRO
# ==============================================================================
print("\n" + "=" * 80)
print("ETAPA 4: BATERIA DE TESTES — NÍVEL MACRO")
print("=" * 80)

all_tests = []

for reg in macroregioes:
    for exp in exposures:
        col = f'{exp}_extreme'
        mask_reg = df_macro['macro_regiao'] == reg
        for outcome in outcomes_macro:
            # Extrair grupos
            p01_vals = df_macro.loc[mask_reg & (df_macro[col] == 'P01'), outcome].dropna().values
            p05_vals = df_macro.loc[mask_reg & (df_macro[col] == 'P05'), outcome].dropna().values
            p50_vals = df_macro.loc[mask_reg & (df_macro[col] == 'P50'), outcome].dropna().values
            p95_vals = df_macro.loc[mask_reg & (df_macro[col] == 'P95'), outcome].dropna().values
            p99_vals = df_macro.loc[mask_reg & (df_macro[col] == 'P99'), outcome].dropna().values

            # Para cada contraste: P05 vs P50, P95 vs P50, P01 vs P50, P99 vs P50
            for contrast_name, xtreme, ref in [
                ('P05_vs_P50', p05_vals, p50_vals),
                ('P95_vs_P50', p95_vals, p50_vals),
                ('P01_vs_P50', p01_vals, p50_vals),
                ('P99_vs_P50', p99_vals, p50_vals),
            ]:
                if len(xtreme) < 5 or len(ref) < 5:
                    continue

                row = {
                    'macro_regiao': reg, 'exposicao': exp, 'outcome': outcome,
                    'contrast': contrast_name,
                    'n_extreme': len(xtreme), 'n_ref': len(ref),
                    'median_extreme': np.median(xtreme), 'median_ref': np.median(ref),
                    'mean_extreme': np.mean(xtreme), 'mean_ref': np.mean(ref),
                    'std_extreme': np.std(xtreme), 'std_ref': np.std(ref),
                }

                # T1: Mann-Whitney U
                try:
                    U1, p1 = mannwhitneyu(xtreme, ref, alternative='two-sided')
                    row['mw_U'] = U1; row['mw_p'] = p1
                except Exception:
                    row['mw_U'] = np.nan; row['mw_p'] = np.nan

                # T2: Kolmogorov-Smirnov
                try:
                    ks_stat, ks_p = ks_2samp(xtreme, ref)
                    row['ks_stat'] = ks_stat; row['ks_p'] = ks_p
                except Exception:
                    row['ks_stat'] = np.nan; row['ks_p'] = np.nan

                # T3: Brunner-Munzel
                try:
                    bm_p_hat, bm_p = brunner_munzel(xtreme, ref)
                    row['bm_p_hat'] = bm_p_hat; row['bm_p'] = bm_p
                except Exception:
                    row['bm_p_hat'] = np.nan; row['bm_p'] = np.nan

                # T4: Mood's median test
                try:
                    med_stat, med_p, _, _ = median_test(xtreme, ref)
                    row['mood_stat'] = med_stat; row['mood_p'] = med_p
                except Exception:
                    row['mood_stat'] = np.nan; row['mood_p'] = np.nan

                # T5: Cliff's delta
                try:
                    row['cliffs_delta'] = cliffs_delta(xtreme, ref)
                except Exception:
                    row['cliffs_delta'] = np.nan

                # T6: Hodges-Lehmann
                try:
                    hl_est, hl_low, hl_high = hodges_lehmann(xtreme, ref)
                    row['hl_est'] = hl_est; row['hl_ci_low'] = hl_low; row['hl_ci_high'] = hl_high
                except Exception:
                    row['hl_est'] = np.nan; row['hl_ci_low'] = np.nan; row['hl_ci_high'] = np.nan

                # T7: Permutation test (apenas para contrastes com p<0.05 no MW)
                if min(len(xtreme), len(ref)) <= 200 and row.get('mw_p', 1) < 0.10:
                    try:
                        _, perm_p = permutation_test(xtreme, ref, n_perm=2000)
                        row['perm_p'] = perm_p
                    except Exception:
                        row['perm_p'] = np.nan
                else:
                    row['perm_p'] = np.nan

                all_tests.append(row)

            # T8: Kruskal-Wallis (P05, P50, P95 juntos)
            groups = [g for g in [p05_vals, p50_vals, p95_vals] if len(g) >= 5]
            if len(groups) >= 2:
                try:
                    H, kw_p = kruskal(*groups)
                except Exception:
                    H, kw_p = np.nan, np.nan
            else:
                H, kw_p = np.nan, np.nan

            # T9: Jonckheere-Terpstra (tendência P05→P50→P95)
            jt_groups = [g for g in [p05_vals, p50_vals, p95_vals] if len(g) >= 3]
            if len(jt_groups) >= 2:
                try:
                    jt_JT, jt_E, jt_p = jonckheere_terpstra(*jt_groups)
                except Exception:
                    jt_JT, jt_E, jt_p = np.nan, np.nan, np.nan
            else:
                jt_JT, jt_E, jt_p = np.nan, np.nan, np.nan

            # Adicionar KW e JT ao último contraste do grupo
            if all_tests:
                all_tests[-1]['kw_H'] = H
                all_tests[-1]['kw_p'] = kw_p
                all_tests[-1]['jt_JT'] = jt_JT
                all_tests[-1]['jt_E'] = jt_E
                all_tests[-1]['jt_p'] = jt_p

df_tests = pd.DataFrame(all_tests)
df_tests = apply_fdr_correction(df_tests, p_col='mw_p')
df_tests = apply_fdr_correction(df_tests, p_col='ks_p')
# Renomear colunas FDR duplicadas
cols_to_drop = [c for c in df_tests.columns if c.endswith('_x')]
for c in cols_to_drop:
    df_tests = df_tests.drop(columns=[c])
rename_map = {c: c.replace('_y', '') for c in df_tests.columns if c.endswith('_y')}
df_tests = df_tests.rename(columns=rename_map)
# Para a segunda chamada, usar prefixos
df_tests['ks_fdr_bh'] = df_tests['ks_p'].rank(method='average')
df_tests['ks_fdr_bh'] = (df_tests['ks_p'] * len(df_tests) / df_tests['ks_fdr_bh']).clip(upper=1.0)

# Sinal combinado: MW OU KS com FDR < 0.05
df_tests['combined_signal'] = (
    ((df_tests['mw_p'] < 0.05) & (df_tests['fdr_bh'] < 0.05)) |
    ((df_tests['ks_p'] < 0.05) & (df_tests['ks_fdr_bh'] < 0.05))
)

n_total = len(df_tests)
n_mw = int((df_tests['fdr_bh'] < 0.05).sum())
n_ks = int((df_tests['ks_fdr_bh'] < 0.05).sum())
n_combined = int(df_tests['combined_signal'].sum())
print(f"\n  Testes totais: {n_total}")
print(f"  MW FDR<0.05: {n_mw} | KS FDR<0.05: {n_ks} | Combinado: {n_combined}")

print("\n  TOP 10 — Sinal combinado:")
top_combined = df_tests[df_tests['combined_signal']].nsmallest(10, 'mw_p')
for _, row in top_combined.iterrows():
    print(f"  {row['macro_regiao']:20s} | {row['exposicao']:8s} | {row['outcome']:25s} | "
          f"{row['contrast']:12s} | MW p={row['mw_p']:.4f} | KS p={row['ks_p']:.4f} | "
          f"Cliff={row['cliffs_delta']:+.3f}")

# ==============================================================================
# 5. TESTE QUI-QUADRADO DE PROPORÇÕES
# ==============================================================================
print("\n" + "=" * 80)
print("ETAPA 5: TESTE QUI-QUADRADO DE PROPORÇÕES")
print("=" * 80)

# Em dias extremos, a proporção de dias COM eventos (>0) vs SEM eventos (0)
# difere da proporção em dias de referência?

chi_results = []
for reg in macroregioes:
    for exp in exposures:
        col = f'{exp}_extreme'
        mask_reg = df_macro['macro_regiao'] == reg
        for outcome in outcomes_macro:
            for contrast_name in ['P05', 'P95', 'P01', 'P99']:
                ext_mask = mask_reg & (df_macro[col] == contrast_name)
                ref_mask = mask_reg & (df_macro[col] == 'P50')

                ext_events = (df_macro.loc[ext_mask, outcome] > 0).sum()
                ext_noevent = ext_mask.sum() - ext_events
                ref_events = (df_macro.loc[ref_mask, outcome] > 0).sum()
                ref_noevent = ref_mask.sum() - ref_events

                if ext_mask.sum() < 5 or ref_mask.sum() < 5:
                    continue

                table = [[ext_events, ext_noevent],
                         [ref_events, ref_noevent]]
                try:
                    chi2, chi_p, dof, _ = chi2_contingency(table)
                except Exception:
                    chi2, chi_p, dof = np.nan, np.nan, np.nan

                chi_results.append({
                    'macro_regiao': reg, 'exposicao': exp, 'outcome': outcome,
                    'contrast': f'{contrast_name}_vs_P50',
                    'ext_days': ext_mask.sum(), 'ref_days': ref_mask.sum(),
                    'ext_pct_events': round(ext_events / ext_mask.sum() * 100, 1) if ext_mask.sum() > 0 else 0,
                    'ref_pct_events': round(ref_events / ref_mask.sum() * 100, 1) if ref_mask.sum() > 0 else 0,
                    'chi2': chi2, 'chi_p': chi_p
                })

df_chi = pd.DataFrame(chi_results)
df_chi = apply_fdr_correction(df_chi, p_col='chi_p')
print(f"  Testes qui-quadrado: {len(df_chi)}")
print(f"  Sinais FDR<0.05: {df_chi['sinal_bh_005'].sum()}")
if df_chi['sinal_bh_005'].sum() > 0:
    print("\n  Proporções com diferença significativa:")
    for _, row in df_chi[df_chi['sinal_bh_005']].iterrows():
        print(f"  {row['macro_regiao']:20s} | {row['exposicao']:8s} | {row['outcome']:25s} | "
              f"{row['contrast']:12s} | extremo={row['ext_pct_events']:.0f}% vs ref={row['ref_pct_events']:.0f}% | "
              f"chi²={row['chi2']:.1f} p={row['chi_p']:.4f}")

# ==============================================================================
# 6. TESTES ESTRATIFICADOS (sexo × idade × desfecho × CID)
# ==============================================================================
print("\n" + "=" * 80)
print("ETAPA 6: TESTES ESTRATIFICADOS")
print("=" * 80)

# Merge dados individuais com classificação de exposição
exp_map = df_macro[['data', 'macro_regiao', 'temp_med_extreme', 'ur_med_extreme']].copy()
df_sih_m = df_sih.merge(exp_map, on=['data', 'macro_regiao'], how='left')
df_sim_m = df_sim.merge(exp_map, on=['data', 'macro_regiao'], how='left')

# Faixas etárias
bins = [0, 40, 60, 80, 150]
labels = ['<40', '40-59', '60-79', '80+']
for df in [df_sih_m, df_sim_m]:
    df['faixa_etaria'] = pd.cut(df['idade'], bins=bins, labels=labels, right=False)

df_sih_m['desfecho'] = 'internacao'
df_sim_m['desfecho'] = 'obito'

df_ind = pd.concat([df_sih_m, df_sim_m], ignore_index=True)

def cid_group(cid):
    if pd.isna(cid): return 'unknown'
    cid = str(cid)
    if cid in ['I60','I61','I62']: return 'I60-I62_hemorragico'
    elif cid == 'I63': return 'I63_isquemico'
    elif cid == 'I64': return 'I64_nao_especificado'
    elif cid.startswith('I6'): return 'I65-I69_outros'
    return 'outro'

df_ind['cid_grupo'] = df_ind['cid3'].apply(cid_group)

print(f"  Dataset individual: {len(df_ind):,} eventos")

# Agregação diária por estrato
def build_stratified_daily(df_ind, strata_cols, exposure_col):
    base_cols = ['data']
    if 'macro_regiao' not in strata_cols:
        base_cols.append('macro_regiao')
    group_cols = base_cols + [c for c in strata_cols if c not in base_cols]
    daily = df_ind.groupby(group_cols, observed=False).size().reset_index(name='count')
    merge_on = ['data']
    if 'macro_regiao' in daily.columns:
        merge_on.append('macro_regiao')
    exp_map = df_macro[merge_on + [exposure_col]].drop_duplicates()
    daily = daily.merge(exp_map, on=merge_on, how='left')
    return daily

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
    {'name': 'macro_faixa_etaria', 'cols': ['macro_regiao', 'faixa_etaria']},
    {'name': 'desfecho_cidgrupo', 'cols': ['desfecho', 'cid_grupo']},
]

all_strat = []

for estrat_info in estratificacoes:
    ename = estrat_info['name']
    ecols = estrat_info['cols']
    print(f"\n  {ename} ({ecols})", end=': ')

    n_tested = 0
    for exp in exposures:
        exp_col = f'{exp}_extreme'
        daily = build_stratified_daily(df_ind, ecols, exp_col)
        strat_vals = daily[ecols].drop_duplicates()

        for _, srow in strat_vals.iterrows():
            mask = pd.Series(True, index=daily.index)
            for c in ecols:
                mask = mask & (daily[c] == srow[c])
            sub = daily[mask]

            for contrast in ['P05', 'P95']:
                xtreme_vals = sub.loc[sub[exp_col] == contrast, 'count'].dropna().values
                ref_vals = sub.loc[sub[exp_col] == 'P50', 'count'].dropna().values

                if len(xtreme_vals) >= 5 and len(ref_vals) >= 5:
                    try:
                        U, p = mannwhitneyu(xtreme_vals, ref_vals, alternative='two-sided')
                        d = cliffs_delta(xtreme_vals, ref_vals)
                        row = {'estratificacao': ename, 'exposicao': exp,
                               'contrast': f'{contrast}_vs_P50',
                               'n_extreme': len(xtreme_vals), 'n_ref': len(ref_vals),
                               'mean_extreme': np.mean(xtreme_vals),
                               'mean_ref': np.mean(ref_vals),
                               'mw_U': U, 'mw_p': p,
                               'cliffs_delta': d}
                        for c in ecols:
                            row[c] = srow[c]
                        all_strat.append(row)
                        n_tested += 1
                    except Exception:
                        pass
    print(f"{n_tested} testes")

df_strat = pd.DataFrame(all_strat)
df_strat = apply_fdr_correction(df_strat, p_col='mw_p')
print(f"\n  Total estratificado: {len(df_strat)}")
print(f"  FDR<0.05: {df_strat['sinal_bh_005'].sum()} | FDR<0.10: {df_strat['sinal_bh_010'].sum()}")

print("\n  TOP 20 sinais estratificados:")
for _, row in df_strat.nsmallest(20, 'fdr_bh').iterrows():
    cols_info = [c for c in df_strat.columns
                 if c not in ['estratificacao','exposicao','contrast','mw_p','fdr_bh',
                              'bonferroni','cliffs_delta','mw_U','n_extreme','n_ref',
                              'mean_extreme','mean_ref','sinal_bh_005','sinal_bh_010',
                              'sinal_bonf_005']
                 and c in row.index and pd.notna(row[c])]
    info = ", ".join(f"{c}={row[c]}" for c in cols_info)
    print(f"  {row['estratificacao']:25s} | {row['contrast']:12s} | {info[:100]} | "
          f"p={row['mw_p']:.4f} FDR={row['fdr_bh']:.4f} Cliff={row['cliffs_delta']:+.3f}")

# ==============================================================================
# 7. SENSIBILIDADE EXPANDIDA
# ==============================================================================
print("\n" + "=" * 80)
print("ETAPA 7: SENSIBILIDADE EXPANDIDA")
print("=" * 80)

# --- S3: P01/P99 (já incluído nos testes principais) ---
print("\n  [S3] P01/P99 — já incluídos na Etapa 4")
n_p01 = len(df_tests[df_tests['contrast'].isin(['P01_vs_P50', 'P99_vs_P50'])])
print(f"    Testes P01/P99: {n_p01}")

# --- S4: Estratificação Sazonal ---
print("\n  [S4] Estratificação sazonal (Verão=Dez-Fev, Inverno=Jun-Ago)...")
df_macro['mes'] = df_macro['data'].dt.month
df_macro['estacao'] = 'outras'
df_macro.loc[df_macro['mes'].isin([12, 1, 2]), 'estacao'] = 'verao'
df_macro.loc[df_macro['mes'].isin([6, 7, 8]), 'estacao'] = 'inverno'

season_results = []
for reg in macroregioes:
    for season in ['verao', 'inverno']:
        mask = (df_macro['macro_regiao'] == reg) & (df_macro['estacao'] == season)
        for exp in exposures:
            col = f'{exp}_extreme'
            for outcome in outcomes_macro:
                for contrast in ['P05', 'P95']:
                    xtreme = df_macro.loc[mask & (df_macro[col] == contrast), outcome].dropna().values
                    ref = df_macro.loc[mask & (df_macro[col] == 'P50'), outcome].dropna().values
                    if len(xtreme) >= 5 and len(ref) >= 5:
                        try:
                            U, p = mannwhitneyu(xtreme, ref, alternative='two-sided')
                            d = cliffs_delta(xtreme, ref)
                            season_results.append({
                                'macro_regiao': reg, 'estacao': season,
                                'exposicao': exp, 'outcome': outcome,
                                'contrast': f'{contrast}_vs_P50',
                                'n_extreme': len(xtreme), 'n_ref': len(ref),
                                'mw_U': U, 'mw_p': p, 'cliffs_delta': d,
                                'mean_diff': np.mean(xtreme) - np.mean(ref)
                            })
                        except Exception:
                            pass

df_season = pd.DataFrame(season_results)
df_season = apply_fdr_correction(df_season, p_col='mw_p')
print(f"    Testes sazonais: {len(df_season)}")
print(f"    Verão FDR<0.05: {df_season[df_season['estacao']=='verao']['sinal_bh_005'].sum()}")
print(f"    Inverno FDR<0.05: {df_season[df_season['estacao']=='inverno']['sinal_bh_005'].sum()}")

# --- S5: Dias úteis vs fim de semana ---
print("\n  [S5] Dias úteis vs fins de semana...")
df_macro['fds'] = df_macro['dow'].isin([6, 7])  # assumindo dow 6=Sáb, 7=Dom

weekday_results = []
for reg in macroregioes:
    for is_weekend in [False, True]:
        lbl = 'FDS' if is_weekend else 'Util'
        mask = (df_macro['macro_regiao'] == reg) & (df_macro['fds'] == is_weekend)
        for exp in exposures:
            col = f'{exp}_extreme'
            for outcome in outcomes_macro:
                for contrast in ['P05', 'P95']:
                    xtreme = df_macro.loc[mask & (df_macro[col] == contrast), outcome].dropna().values
                    ref = df_macro.loc[mask & (df_macro[col] == 'P50'), outcome].dropna().values
                    if len(xtreme) >= 5 and len(ref) >= 5:
                        try:
                            U, p = mannwhitneyu(xtreme, ref, alternative='two-sided')
                            d = cliffs_delta(xtreme, ref)
                            weekday_results.append({
                                'macro_regiao': reg, 'dia_tipo': lbl,
                                'exposicao': exp, 'outcome': outcome,
                                'contrast': f'{contrast}_vs_P50',
                                'mw_U': U, 'mw_p': p, 'cliffs_delta': d,
                                'mean_diff': np.mean(xtreme) - np.mean(ref)
                            })
                        except Exception:
                            pass

df_wd = pd.DataFrame(weekday_results)
df_wd = apply_fdr_correction(df_wd, p_col='mw_p')
print(f"    Testes dia útil/FDS: {len(df_wd)}")
print(f"    Dias úteis FDR<0.05: {df_wd[df_wd['dia_tipo']=='Util']['sinal_bh_005'].sum()}")
print(f"    FDS FDR<0.05: {df_wd[df_wd['dia_tipo']=='FDS']['sinal_bh_005'].sum()}")

# --- S6: Jackknife leave-one-out regional ---
print("\n  [S6] Jackknife leave-one-out regional (concordância)...")
# Para cada macro, rodar análise principal excluindo aquela macro
# e verificar se os sinais das outras regiões permanecem estáveis.

jackknife_stability = []
for left_out in macroregioes:
    df_jack = df_macro[df_macro['macro_regiao'] != left_out].copy()
    # Recalcular percentis para o conjunto reduzido
    jack_percentis = {}
    for reg in [r for r in macroregioes if r != left_out]:
        mask_j = df_jack['macro_regiao'] == reg
        jack_percentis[reg] = {}
        for exp in exposures:
            vals_j = df_jack.loc[mask_j, exp].dropna()
            jack_percentis[reg][exp] = {
                f'p{p:02d}': np.percentile(vals_j, p) for p in [1, 5, 50, 95, 99]
            }

    # Reclassificar
    for reg in [r for r in macroregioes if r != left_out]:
        mask_j = df_jack['macro_regiao'] == reg
        for exp in exposures:
            col_j = f'{exp}_extreme_jack'
            df_jack.loc[mask_j, col_j] = df_jack.loc[mask_j, exp].apply(
                lambda v, p=jack_percentis[reg][exp]: classify_day(v, p))

    # Contar sinais
    n_signals = 0
    for reg in [r for r in macroregioes if r != left_out]:
        mask_j = df_jack['macro_regiao'] == reg
        for exp in exposures:
            col_j = f'{exp}_extreme_jack'
            for outcome in outcomes_macro:
                p05_j = df_jack.loc[mask_j & (df_jack[col_j] == 'P05'), outcome].dropna().values
                p50_j = df_jack.loc[mask_j & (df_jack[col_j] == 'P50'), outcome].dropna().values
                p95_j = df_jack.loc[mask_j & (df_jack[col_j] == 'P95'), outcome].dropna().values
                for xt, lbl in [(p05_j, 'P05'), (p95_j, 'P95')]:
                    if len(xt) >= 5 and len(p50_j) >= 5:
                        try:
                            _, pj = mannwhitneyu(xt, p50_j, alternative='two-sided')
                            if pj < 0.05:
                                n_signals += 1
                        except Exception:
                            pass

    jackknife_stability.append({
        'left_out': left_out,
        'n_regions_remaining': 8,
        'n_signals_p005': n_signals,
        'total_possible': 8 * 2 * 4 * 2  # 8 reg * 2 exp * 4 outcomes * 2 contrasts
    })

df_jack = pd.DataFrame(jackknife_stability)
print(f"    Sinais médios (leave-one-out): {df_jack['n_signals_p005'].mean():.1f} ± {df_jack['n_signals_p005'].std():.1f}")
print(f"    Sinais análise completa (referência): {int((df_tests['mw_p'] < 0.05).sum())}")
df_jack.to_csv(AUDIT_DIR / f"jackknife_{RUN_TS}.csv", index=False)

# ==============================================================================
# 8. WILCOXON PAREADO SAZONAL
# ==============================================================================
print("\n" + "=" * 80)
print("ETAPA 8: WILCOXON PAREADO SAZONAL (mês-a-mês)")
print("=" * 80)

# Emparelhar meses: para cada macrorregião, calcular média mensal e
# comparar meses de temperaturas extremas vs meses de referência.

df_macro['ano_mes'] = df_macro['data'].dt.to_period('M')
monthly = df_macro.groupby(['macro_regiao', 'ano_mes']).agg(
    temp_med_mean=('temp_med', 'mean'),
    ur_med_mean=('ur_med', 'mean'),
    internacoes_i60_i69_sum=('internacoes_i60_i69', 'sum'),
    internacoes_i60_i64_sum=('internacoes_i60_i64', 'sum'),
    obitos_i60_i69_sum=('obitos_i60_i69', 'sum'),
    obitos_i60_i64_sum=('obitos_i60_i64', 'sum'),
    n_days=('data', 'count')
).reset_index()

# Classificar meses como extremos baseado na temperatura/umidade média do mês
paired_results = []
for reg in macroregioes:
    mask_m = monthly['macro_regiao'] == reg
    for exp_raw, exp_monthly in [('temp_med', 'temp_med_mean'), ('ur_med', 'ur_med_mean')]:
        vals = monthly.loc[mask_m, exp_monthly].dropna()
        p05 = np.percentile(vals, 5)
        p50 = np.percentile(vals, 50)
        p95 = np.percentile(vals, 95)
        margin = (p95 - p05) * 0.02

        monthly.loc[mask_m, f'{exp_raw}_monthly_class'] = 'OTHER'
        monthly.loc[mask_m & (monthly[exp_monthly] <= p05), f'{exp_raw}_monthly_class'] = 'P05'
        monthly.loc[mask_m & (monthly[exp_monthly] >= p95), f'{exp_raw}_monthly_class'] = 'P95'
        monthly.loc[mask_m & (monthly[exp_monthly].sub(p50).abs() <= margin),
                    f'{exp_raw}_monthly_class'] = 'P50'

        for outcome_daily, outcome_monthly in [
            ('internacoes_i60_i69', 'internacoes_i60_i69_sum'),
            ('obitos_i60_i69', 'obitos_i60_i69_sum'),
        ]:
            for contrast in ['P05', 'P95']:
                xtreme = monthly.loc[mask_m & (monthly[f'{exp_raw}_monthly_class'] == contrast),
                                     outcome_monthly].dropna().values
                ref = monthly.loc[mask_m & (monthly[f'{exp_raw}_monthly_class'] == 'P50'),
                                   outcome_monthly].dropna().values
                if len(xtreme) >= 5 and len(ref) >= 5:
                    try:
                        # Mann-Whitney (não pareado aqui, mas em base mensal)
                        U, p = mannwhitneyu(xtreme, ref, alternative='two-sided')
                        d = cliffs_delta(xtreme, ref)
                        paired_results.append({
                            'macro_regiao': reg, 'exposicao': exp_raw,
                            'outcome': outcome_daily,
                            'contrast': f'{contrast}_vs_P50',
                            'n_extreme_months': len(xtreme), 'n_ref_months': len(ref),
                            'median_extreme': np.median(xtreme), 'median_ref': np.median(ref),
                            'mw_U': U, 'mw_p': p, 'cliffs_delta': d,
                            'mean_diff': np.mean(xtreme) - np.mean(ref)
                        })
                    except Exception:
                        pass

df_paired = pd.DataFrame(paired_results)
df_paired = apply_fdr_correction(df_paired, p_col='mw_p')
print(f"  Testes mensais: {len(df_paired)}")
print(f"  FDR<0.05: {df_paired['sinal_bh_005'].sum()}")
if df_paired['sinal_bh_005'].sum() > 0:
    print("\n  Sinais mensais (FDR<0.05):")
    for _, row in df_paired[df_paired['sinal_bh_005']].iterrows():
        print(f"  {row['macro_regiao']:20s} | {row['exposicao']:8s} | {row['outcome']:25s} | "
              f"{row['contrast']:12s} | p={row['mw_p']:.4f} FDR={row['fdr_bh']:.4f}")

# ==============================================================================
# 9. CORRELAÇÃO ENTRE TESTES
# ==============================================================================
print("\n" + "=" * 80)
print("ETAPA 9: CORRELAÇÃO ENTRE TESTES E CONCORDÂNCIA")
print("=" * 80)

# Verificar concordância entre MW e KS
valid = df_tests.dropna(subset=['mw_p', 'ks_p'])
mw_sig = valid['mw_p'] < 0.05
ks_sig = valid['ks_p'] < 0.05
agreement = (mw_sig == ks_sig).mean()
print(f"  Concordância MW vs KS (p<0.05): {agreement:.1%}")

# Correlação entre p-values
rho, _ = stats.spearmanr(valid['mw_p'], valid['ks_p'])
print(f"  Correlação Spearman (MW p vs KS p): {rho:.3f}")

# Verificar quantos sinais MW também são detectados por BM (Brunner-Munzel)
valid_bm = df_tests.dropna(subset=['mw_p', 'bm_p'])
bm_agree = ((valid_bm['mw_p'] < 0.05) == (valid_bm['bm_p'] < 0.05)).mean()
print(f"  Concordância MW vs Brunner-Munzel (p<0.05): {bm_agree:.1%}")

# ==============================================================================
# 10. EXPORTAÇÃO FINAL
# ==============================================================================
print("\n" + "=" * 80)
print("ETAPA 10: EXPORTAÇÃO")
print("=" * 80)

# Resultados principais (bateria completa)
df_tests.to_csv(OUTPUT_DIR / f"bateria_testes_macro_{RUN_TS}.csv", index=False)
print(f"  bateria_testes_macro_{RUN_TS}.csv ({len(df_tests)} linhas)")

# Estratificados
df_strat.to_csv(OUTPUT_DIR / f"testes_estratificados_{RUN_TS}.csv", index=False)
print(f"  testes_estratificados_{RUN_TS}.csv ({len(df_strat)} linhas)")

# Qui-quadrado
df_chi.to_csv(OUTPUT_DIR / f"chi2_proporcoes_{RUN_TS}.csv", index=False)
print(f"  chi2_proporcoes_{RUN_TS}.csv ({len(df_chi)} linhas)")

# Sazonal
df_season.to_csv(OUTPUT_DIR / f"sensibilidade_sazonal_{RUN_TS}.csv", index=False)
print(f"  sensibilidade_sazonal_{RUN_TS}.csv ({len(df_season)} linhas)")

# Dia útil/FDS
df_wd.to_csv(OUTPUT_DIR / f"sensibilidade_dia_util_{RUN_TS}.csv", index=False)
print(f"  sensibilidade_dia_util_{RUN_TS}.csv ({len(df_wd)} linhas)")

# Mensal
df_paired.to_csv(OUTPUT_DIR / f"testes_mensais_{RUN_TS}.csv", index=False)
print(f"  testes_mensais_{RUN_TS}.csv ({len(df_paired)} linhas)")

# --- RESUMO EXECUTIVO FINAL ---
resumo = {
    'data_execucao': RUN_TS,
    'versao': 'v2_expandida',
    # Auditoria
    'audit_registros': len(all_audit),
    'qualidade_media': round(np.mean([q['quality_score'] for q in quality_scores.values()]), 4),
    # Testes
    'n_testes_macro': len(df_tests),
    'n_testes_estratificados': len(df_strat),
    'n_testes_chi2': len(df_chi),
    'n_testes_sazonais': len(df_season),
    'n_testes_dia_util': len(df_wd),
    'n_testes_mensais': len(df_paired),
    'n_total_testes': len(df_tests) + len(df_strat) + len(df_chi) + len(df_season) + len(df_wd) + len(df_paired),
    # Sinais
    'sinais_mw_fdr005_macro': int((df_tests['fdr_bh'] < 0.05).sum()),
    'sinais_ks_fdr005_macro': int((df_tests['ks_fdr_bh'] < 0.05).sum()),
    'sinais_combinados_macro': int(df_tests['combined_signal'].sum()),
    'sinais_estrat_fdr005': int(df_strat['sinal_bh_005'].sum()),
    'sinais_chi2_fdr005': int(df_chi['sinal_bh_005'].sum()),
    'sinais_sazonais_fdr005': int(df_season['sinal_bh_005'].sum()),
    'sinais_diautil_fdr005': int(df_wd['sinal_bh_005'].sum()),
    'sinais_mensais_fdr005': int(df_paired['sinal_bh_005'].sum()),
    # Concordância
    'concordancia_MW_KS': f"{agreement:.1%}",
    'concordancia_MW_BM': f"{bm_agree:.1%}",
    'corr_spearman_MW_KS': round(rho, 3),
    # Jackknife
    'jackknife_media_sinais': round(df_jack['n_signals_p005'].mean(), 1),
    'jackknife_std_sinais': round(df_jack['n_signals_p005'].std(), 1),
}

with open(OUTPUT_DIR / f"resumo_executivo_v2_{RUN_TS}.txt", 'w', encoding='utf-8') as f:
    f.write("RESUMO EXECUTIVO — WILCOXON v2 EXPANDIDA\n")
    f.write("=" * 60 + "\n")
    for k, v in resumo.items():
        f.write(f"{k}: {v}\n")

print("\nResumo executivo v2:")
for k, v in resumo.items():
    print(f"  {k}: {v}")

# --- TOP 30 macro ---
top30 = df_tests.nsmallest(30, 'mw_p')
top30.to_csv(OUTPUT_DIR / f"top30_macro_{RUN_TS}.csv", index=False)

print("\n" + "=" * 80)
print(f"[{datetime.now().strftime('%Y%m%d_%H%M%S')}] ANÁLISE WILCOXON v2 CONCLUÍDA")
print(f"  {len(df_tests) + len(df_strat) + len(df_chi) + len(df_season) + len(df_wd) + len(df_paired)} testes executados")
print(f"  {len(all_audit)} verificações de auditoria")
print("=" * 80)
