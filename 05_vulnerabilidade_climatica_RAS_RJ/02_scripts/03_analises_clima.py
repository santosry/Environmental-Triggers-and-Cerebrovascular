# -*- coding: utf-8 -*-
"""
03_analises_clima.py
====================
Integração da dimensão ambiental (temperatura, umidade, PM2,5) à análise
territorial e assistencial. Produz exposição ambiental por região de saúde e
estatísticas descritivas de associação ecológica (sem inferência causal).

Fontes (já processadas no projeto, formato CSV):
  - dataset_dlnm_macrorregiao_CORRIGIDO.csv  (diário, temp/umidade + desfechos)
  - pm25/mp25_macroregiao_mensal_2010_2025.csv (PM2,5 mensal por macrorregião)
"""

import os
import warnings
import numpy as np
import pandas as pd
from scipy import stats
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

warnings.filterwarnings("ignore")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DLNM_ROOT = os.path.dirname(ROOT)
TAB = os.path.join(ROOT, "05_tabelas")
FIG = os.path.join(ROOT, "06_figuras")
RES = os.path.join(ROOT, "04_resultados")
os.makedirs(TAB, exist_ok=True)
os.makedirs(FIG, exist_ok=True)
os.makedirs(RES, exist_ok=True)

clima_path = os.path.join(DLNM_ROOT, "05_publicacao_github", "data_processed",
                          "dataset_dlnm_macrorregiao_CORRIGIDO.csv")
pm_path = os.path.join(DLNM_ROOT, "05_publicacao_github", "data", "processed",
                       "pm25", "mp25_macroregiao_mensal_2010_2025.csv")

clima = pd.read_csv(clima_path, low_memory=False)
clima["data"] = pd.to_datetime(clima["data"], errors="coerce")
clima = clima[(clima["data"] >= "2010-01-01") & (clima["data"] <= "2024-12-31")]
clima["ano"] = clima["data"].dt.year

# PM2.5 (semicolon-delimited)
pm = pd.read_csv(pm_path, sep=";", engine="python")
pm.columns = [c.strip() for c in pm.columns]
pm = pm[(pm["Ano"] >= 2010) & (pm["Ano"] <= 2024)]

resumo = []
def log(*a):
    line = " ".join(str(x) for x in a)
    resumo.append(line)
    print(line, flush=True)

log("=" * 70)
log("EXPOSIÇÃO AMBIENTAL POR MACRORREGIÃO DE SAÚDE (2010-2024)")
log("=" * 70)

# estatísticas de exposição climática por região
clima_stats = clima.groupby("macro_regiao").agg(
    temp_media=("temp_med", "mean"),
    temp_p05=("temp_med", lambda x: x.quantile(.05)),
    temp_p95=("temp_med", lambda x: x.quantile(.95)),
    temp_min_abs=("temp_med", "min"),
    temp_max_abs=("temp_med", "max"),
    ur_media=("ur_med", "mean"),
    ur_p05=("ur_med", lambda x: x.quantile(.05)),
    n_dias=("temp_med", "count"),
).round(2)
clima_stats.to_csv(os.path.join(TAB, "exposicao_climatica_regiao.csv"))
log(clima_stats.to_string())

# PM2.5 médio por região
pm.columns = [c.strip() for c in pm.columns]
pm["PM25"] = pd.to_numeric(pm["PM25"], errors="coerce")
pm_reg = pm.groupby("Macroregiao")["PM25"].mean().round(2)
log("PM2.5 médio (µg/m³) por macrorregião:")
log(pm_reg.to_string())

# correlação ecológica descritiva: dias frios (temp<P05) vs internações (por região)
log("")
log("Associação ecológica descritiva (correlação de Spearman, diária):")
for reg, sub in clima.groupby("macro_regiao"):
    sub = sub.dropna(subset=["temp_med", "internacoes_i60_i69"])
    if len(sub) > 100:
        rho, p = stats.spearmanr(sub["temp_med"], sub["internacoes_i60_i69"])
        log(f"  {reg}: rho(temp, internações) = {rho:.3f} (p={p:.3f})")

# figura: exposição climática por região (boxplot temperatura)
fig, ax = plt.subplots(figsize=(9, 4))
regs = sorted(clima["macro_regiao"].unique())
data = [clima.loc[clima["macro_regiao"] == r, "temp_med"].dropna() for r in regs]
ax.boxplot(data, tick_labels=regs, vert=False, showfliers=False)
ax.set_xlabel("Temperatura média diária (°C)")
ax.set_title("Exposição térmica por macrorregião de saúde, RJ 2010-2024")
fig.tight_layout()
fig.savefig(os.path.join(FIG, "fig4_exposicao_termica_regiao.png"))
plt.close(fig)

# figura: PM2.5 por região
fig, ax = plt.subplots(figsize=(8, 4))
pm_reg_sorted = pm_reg.sort_values()
pm_reg_sorted.plot(kind="barh", ax=ax, color="tab:orange")
ax.set_xlabel("PM2,5 médio (µg/m³)")
ax.set_title("Exposição média a PM2,5 por macrorregião, 2010-2024")
fig.tight_layout()
fig.savefig(os.path.join(FIG, "fig5_pm25_regiao.png"))
plt.close(fig)

with open(os.path.join(RES, "resultados_clima.txt"), "w", encoding="utf-8") as f:
    f.write("\n".join(resumo))
log("=" * 70)
log("FIM — resultados em 05_tabelas/exposicao_climatica_regiao.csv e 06_figuras")
