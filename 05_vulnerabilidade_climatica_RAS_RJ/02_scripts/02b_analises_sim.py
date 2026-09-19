# -*- coding: utf-8 -*-
"""
02b_analises_sim.py
===================
Consolida e analisa o SIM (óbitos por DCV, causa básica I60-I69) de forma
independente, via pyreadr (rápido), sem depender da consolidação lenta do SIH.

Produz tabelas de mortalidade populacional e indicadores territoriais.
"""

import os
import warnings
import numpy as np
import pandas as pd
import pyreadr
from scipy import stats

warnings.filterwarnings("ignore")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DLNM_ROOT = os.path.dirname(ROOT)
SRC_SIM = os.path.join(DLNM_ROOT, "05_publicacao_github", "data", "raw", "sim")
SRC_LOOKUP = os.path.join(DLNM_ROOT, "05_publicacao_github", "data", "processed",
                          "lookup_municipio_macrorregiao.csv")
TAB = os.path.join(ROOT, "05_tabelas")
FIG = os.path.join(ROOT, "06_figuras")
RES = os.path.join(ROOT, "04_resultados")
os.makedirs(TAB, exist_ok=True); os.makedirs(FIG, exist_ok=True)
os.makedirs(RES, exist_ok=True)

POP_PATH = os.path.join(DLNM_ROOT, "01_DLNMs_RJ_cerebrovascular", "data_processed",
                        "populacao_sidra_municipio_rj_2010-2025.csv")

lookup = pd.read_csv(SRC_LOOKUP, dtype=str)
lookup["ibge6"] = lookup["ibge6"].str.zfill(6)
def macro3(r):
    if r in ("Metropolitana I", "Metropolitana II"): return "Metropolitana"
    if r in ("Serrana", "Medio Paraiba", "Centro-Sul", "Baia da Ilha Grande"): return "Centro-Sul"
    if r in ("Norte", "Noroeste", "Baixada Litoranea"): return "Norte e Noroeste"
    return np.nan
lookup["regiao_saude"] = lookup["macro_regiao"]
lookup["macro3"] = lookup["regiao_saude"].map(macro3)

pop = pd.read_csv(POP_PATH)
pop["ano"] = pd.to_numeric(pop["ano"], errors="coerce")
pop["macro3"] = pop["macro_regiao"].map(macro3)
pop_reg = pop.groupby(["macro_regiao", "ano"], as_index=False)["populacao"].sum().rename(
    columns={"macro_regiao": "regiao_saude"})
pop_macro3 = pop.groupby(["macro3", "ano"], as_index=False)["populacao"].sum()
pop_estado = pop.groupby("ano", as_index=False)["populacao"].sum()

# ---------------------------------------------------------------------------
# Consolida SIM
# ---------------------------------------------------------------------------
chunks = []
for ano in range(2010, 2025):
    f = os.path.join(SRC_SIM, f"sim_do_rj_year_{ano}.rds")
    if not os.path.exists(f):
        continue
    df = list(pyreadr.read_r(f).values())[0]
    df.columns = [str(c) for c in df.columns]
    caus = df["CAUSABAS"].astype("string").str.slice(0, 3)
    df = df[caus.isin([f"I6{i}" for i in range(10)])].copy()
    mun = df["CODMUNRES"].astype("string").str.zfill(6)
    df["MUNIC_RES6"] = mun
    df = df[mun.str.startswith("33")]
    chunks.append(df)

sim = pd.concat(chunks, ignore_index=True)
sim["DTOBITO_d"] = pd.to_datetime(sim["DTOBITO"].astype("string"), format="%d%m%Y",
                                  errors="coerce")
sim = sim[(sim["DTOBITO_d"] >= "2010-01-01") & (sim["DTOBITO_d"] <= "2024-12-31")]

def idade_sim(v):
    if pd.isna(v) or v == 999: return np.nan
    v = int(v); c, r = v // 100, v % 100
    if c == 4: return float(r)
    if c == 5: return float(100 + r)
    if c == 3: return r / 12
    if c == 2: return r / (365 * 24)
    if c == 1: return r / (365 * 24 * 60)
    return np.nan
sim["idade_anos"] = pd.to_numeric(sim["IDADE"], errors="coerce").map(idade_sim)
sim["sexo"] = sim["SEXO"].astype("string").map({"1": "M", "2": "F"}).fillna("I")
sim["raca_cor"] = sim["RACACOR"].astype("string").map(
    {"1": "Branca", "2": "Preta", "3": "Amarela", "4": "Parda", "5": "Indígena",
     "9": "Ignorado"}).fillna("Ignorado")
sim["local_ocorrencia"] = sim["LOCOCOR"].astype("string").map(
    {"1": "Hospital", "2": "Outro estab. saúde", "3": "Domicílio", "4": "Via pública",
     "5": "Outros", "9": "Ignorado"}).fillna("Ignorado")
sim["cid3"] = sim["CAUSABAS"].astype("string").str.slice(0, 3)
sim = sim.merge(lookup[["ibge6", "mun_nome", "regiao_saude", "macro3"]],
                left_on="MUNIC_RES6", right_on="ibge6", how="left")
sim["ano"] = sim["DTOBITO_d"].dt.year
sim.to_csv(os.path.join(ROOT, "01_dados", "processados",
                        "sim_cerebrovascular_2010_2024.csv"), index=False)

resumo = []
def log(*a):
    line = " ".join(str(x) for x in a); resumo.append(line); print(line, flush=True)

log("=" * 70)
log("ANÁLISE DE MORTALIDADE — SIM (causa básica I60-I69, 2010-2024)")
log("=" * 70)
n = len(sim)
log(f"Óbitos totais: {n:,}")
log("Sexo:")
log(sim["sexo"].value_counts().to_string())
log(f"Idade mediana: {sim['idade_anos'].median():.0f} anos")
log("Local de ocorrência:")
log(sim["local_ocorrencia"].value_counts(dropna=False).to_string())
log("CID3:")
log(sim["cid3"].value_counts().sort_index().to_string())
log("Raça/cor:")
log(sim["raca_cor"].value_counts(dropna=False).to_string())

# taxas por região
def taxas(df, popdf, key):
    num = df.groupby([key, "ano"]).size().rename("n").reset_index()
    t = num.merge(popdf, on=[key, "ano"], how="left")
    t["taxa"] = t["n"] / t["populacao"] * 100000
    return t

t_reg = taxas(sim, pop_reg, "regiao_saude")
t_macro = taxas(sim, pop_macro3, "macro3")

log("Taxa média de mortalidade/100k por região (2010-2024):")
log(t_reg.groupby("regiao_saude")["taxa"].mean().sort_values(ascending=False).round(2).to_string())

log("Taxa média de mortalidade/100k por macrorregião:")
log(t_macro.groupby("macro3")["taxa"].mean().sort_values(ascending=False).round(2).to_string())

# tendência estadual
t_estado = taxas(sim.assign(uf="RJ"), pop_estado.assign(uf="RJ"), "uf")
serie = t_estado.sort_values("ano")["taxa"]
import pymannkendall as mk
r = mk.original_test(serie)
log(f"Taxa mortalidade estadual: 2010={serie.iloc[0]:.2f} | 2024={serie.iloc[-1]:.2f} /100k")
log(f"Mann-Kendall: tau={r.Tau:.3f} p={r.p:.4f}")

# mortalidade por local de ocorrência (hospital vs domicílio)
log("Óbitos por local de ocorrência e macrorregião (cross):")
log(pd.crosstab(sim["macro3"], sim["local_ocorrencia"], normalize="index").round(3).to_string())

t_reg.to_csv(os.path.join(TAB, "mortalidade_sim_regiao.csv"), index=False)
t_macro.to_csv(os.path.join(TAB, "mortalidade_sim_macro.csv"), index=False)

with open(os.path.join(RES, "resultados_mortalidade_sim.txt"), "w", encoding="utf-8") as f:
    f.write("\n".join(resumo))
log("FIM — tabelas em 05_tabelas/mortalidade_sim_*.csv")
