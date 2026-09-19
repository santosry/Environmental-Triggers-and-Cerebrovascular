# -*- coding: utf-8 -*-
"""
02_analises_principais.py
=========================
Reanálise e ampliação do estudo-base sobre morbimortalidade cerebrovascular no RJ.

Executa: perfil sociodemográfico/clínico, taxas por 100 mil, tendência temporal,
mortalidade (SIH e SIM), permanência, custos, fluxo territorial, CNES e testes
estatísticos. Produz tabelas (05_tabelas) e figuras (06_figuras) e um resumo
(04_resultados/resultados_principais.txt).

Requer os CSVs gerados por 01_consolidar_dados.py.
"""

import os
import warnings
import numpy as np
import pandas as pd
from scipy import stats
import pymannkendall as mk
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

warnings.filterwarnings("ignore")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DLNM_ROOT = os.path.dirname(ROOT)
DATA = os.path.join(ROOT, "01_dados", "processados")
TAB = os.path.join(ROOT, "05_tabelas")
FIG = os.path.join(ROOT, "06_figuras")
RES = os.path.join(ROOT, "04_resultados")
os.makedirs(TAB, exist_ok=True)
os.makedirs(FIG, exist_ok=True)
os.makedirs(RES, exist_ok=True)

POP_PATH = os.path.join(DLNM_ROOT, "01_DLNMs_RJ_cerebrovascular", "data_processed",
                        "populacao_sidra_municipio_rj_2010-2025.csv")

plt.rcParams.update({"font.size": 9, "axes.titlesize": 10, "figure.dpi": 200})

# ----------------------------------------------------------------------------
# Carregamento
# ----------------------------------------------------------------------------
sih = pd.read_csv(os.path.join(DATA, "sih_cerebrovascular_2010_2024.csv"),
                  low_memory=False)
sim = pd.read_csv(os.path.join(DATA, "sim_cerebrovascular_2010_2024.csv"),
                  low_memory=False)
pop = pd.read_csv(POP_PATH)

# normaliza tipos
for c in ["VAL_TOT", "VAL_SH", "VAL_SP", "VAL_UTI", "DIAS_PERM", "idade_anos"]:
    if c in sih.columns:
        sih[c] = pd.to_numeric(sih[c], errors="coerce")
for c in ["idade_anos"]:
    sim[c] = pd.to_numeric(sim[c], errors="coerce")

sih["ano"] = pd.to_numeric(sih["ano"], errors="coerce")
sim["ano"] = pd.to_numeric(sim["ano"], errors="coerce")

REGIOES = ["Metropolitana I", "Metropolitana II", "Baia da Ilha Grande",
           "Baixada Litoranea", "Centro-Sul", "Medio Paraiba", "Norte",
           "Noroeste", "Serrana"]
MACRO3 = ["Metropolitana", "Centro-Sul", "Norte e Noroeste"]

# população por região/ano (denominador)
pop["ano"] = pd.to_numeric(pop["ano"], errors="coerce")
pop["macro3"] = pop["macro_regiao"].map({
    "Metropolitana I": "Metropolitana", "Metropolitana II": "Metropolitana",
    "Serrana": "Centro-Sul", "Medio Paraiba": "Centro-Sul",
    "Centro-Sul": "Centro-Sul", "Baia da Ilha Grande": "Centro-Sul",
    "Norte": "Norte e Noroeste", "Noroeste": "Norte e Noroeste",
    "Baixada Litoranea": "Norte e Noroeste"})
pop_reg = pop.groupby(["macro_regiao", "ano"], as_index=False)["populacao"].sum().rename(
    columns={"macro_regiao": "regiao_saude"})
pop_macro3 = pop.groupby(["macro3", "ano"], as_index=False)["populacao"].sum()
pop_estado = pop.groupby("ano", as_index=False)["populacao"].sum()

resumo = []  # linhas de texto do resumo


def _cochran_armitage(k, n, score):
    """Teste de tendência de Cochran-Armitage."""
    N = n.sum()
    if N == 0:
        return np.nan
    pbar = k.sum() / N
    xbar = (n * score).sum() / N
    num = (k - n * pbar).dot(score - xbar)
    den = pbar * (1 - pbar) * (n * (score - xbar) ** 2).sum()
    z = num / np.sqrt(den) if den > 0 else 0
    return 2 * (1 - stats.norm.cdf(abs(z)))


def log(*args):
    line = " ".join(str(a) for a in args)
    resumo.append(line)
    print(line, flush=True)


# ----------------------------------------------------------------------------
# 1. PERFIL
# ----------------------------------------------------------------------------
log("=" * 72)
log("1. PERFIL SOCIODEMOGRÁFICO E CLÍNICO-ASSISTENCIAL")
log("=" * 72)

n_sih = len(sih)
log(f"Internações I60-I69 (2010-2024): {n_sih:,}")
log(f"Sexo M: {int((sih['sexo']=='M').sum()):,} ({(sih['sexo']=='M').mean()*100:.1f}%) | "
    f"F: {int((sih['sexo']=='F').sum()):,} ({(sih['sexo']=='F').mean()*100:.1f}%)")
log(f"Idade: mediana {sih['idade_anos'].median():.0f} (IIQ {sih['idade_anos'].quantile(.25):.0f}-"
    f"{sih['idade_anos'].quantile(.75):.0f})")
log("Faixa etária:")
log(sih["faixa_etaria"].value_counts().sort_index().to_string())
log("CID-10 (subtipo):")
cid_dist = sih["cid3"].value_counts().sort_index()
log(cid_dist.to_string())
log(f"I64 (%): {cid_dist.get('I64',0)/n_sih*100:.1f} | "
    f"I69 (%): {cid_dist.get('I69',0)/n_sih*100:.1f} | "
    f"I63 (%): {cid_dist.get('I63',0)/n_sih*100:.1f} | "
    f"I60-I62 (%): {sum(cid_dist.get(c,0) for c in ['I60','I61','I62'])/n_sih*100:.1f}")
log("Raça/cor:")
log(sih["raca_cor"].value_counts(dropna=False).to_string())
log(f"Raça/cor 'Sem informação' (%): {(sih['raca_cor'].isin(['Sem informação','Ignorado'])).mean()*100:.1f}")
log("Caráter da internação:")
log(sih["car_int"].value_counts(dropna=False).to_string())
log("Escolaridade (INSTRU) — categorias brutas:")
log(sih["instru"].value_counts(dropna=False).to_string())

# completude das variáveis-chave
completude = pd.DataFrame({
    "variavel": ["RACA_COR", "INSTRU", "CAR_INT", "DIAS_PERM", "VAL_TOT", "CNES",
                 "MUNIC_MOV", "DIAG_SECUN"],
    "n_na": [sih["RACA_COR"].isna().sum() if "RACA_COR" in sih else np.nan,
             sih["INSTRU"].isna().sum() if "INSTRU" in sih else np.nan,
             sih["CAR_INT"].isna().sum() if "CAR_INT" in sih else np.nan,
             sih["DIAS_PERM"].isna().sum(),
             sih["VAL_TOT"].isna().sum(),
             sih["CNES"].isna().sum() if "CNES" in sih else np.nan,
             sih["MUNIC_MOV"].isna().sum() if "MUNIC_MOV" in sih else np.nan,
             sih["DIAG_SECUN"].isna().sum() if "DIAG_SECUN" in sih else np.nan],
})
completude["pct_na"] = completude["n_na"] / n_sih * 100
completude.to_csv(os.path.join(TAB, "completude_variaveis_sih.csv"), index=False)

# perfil por macrorregião (tabela 1 da nova fase)
perfil_macro = pd.DataFrame({
    "n_internacoes": sih.groupby("macro3").size(),
    "obito_hospitalar_pct": sih.groupby("macro3")["obito_hospitalar"].mean() * 100,
    "permanencia_mediana": sih.groupby("macro3")["DIAS_PERM"].median(),
    "permanencia_iiq": sih.groupby("macro3")["DIAS_PERM"].apply(
        lambda x: f"{x.quantile(.25):.0f}-{x.quantile(.75):.0f}"),
    "custo_mediano": sih.groupby("macro3")["VAL_TOT"].median(),
    "idade_mediana": sih.groupby("macro3")["idade_anos"].median(),
    "sexo_m_pct": sih.groupby("macro3").apply(lambda d: (d["sexo"] == "M").mean() * 100,
                                              include_groups=False),
})
perfil_macro.to_csv(os.path.join(TAB, "tabela_perfil_macrorregiao.csv"))

# ----------------------------------------------------------------------------
# 2. TAXAS POR 100 MIL E TENDÊNCIA
# ----------------------------------------------------------------------------
log("=" * 72)
log("2. TAXAS POR 100 MIL E TENDÊNCIA TEMPORAL")
log("=" * 72)

def calc_taxas(df, popdf, key):
    num = df.groupby([key, "ano"]).size().rename("n").reset_index()
    t = num.merge(popdf, left_on=[key, "ano"], right_on=[key, "ano"], how="left")
    t["taxa"] = t["n"] / t["populacao"] * 100000
    return t

taxas_reg = calc_taxas(sih, pop_reg, "regiao_saude")
taxas_macro = calc_taxas(sih, pop_macro3, "macro3")
taxas_estado = calc_taxas(sih.assign(uf="RJ"), pop_estado.assign(uf="RJ"), "uf")

def mk_trend(series):
    s = series.dropna().reset_index(drop=True)
    if len(s) < 4 or s.nunique() < 2:
        return np.nan, np.nan, "n/a"
    try:
        r = mk.original_test(s)
        return r.Tau, r.p, r.trend
    except Exception:
        return np.nan, np.nan, "erro"

# tendência estadual
serie_estado = taxas_estado.sort_values("ano")["taxa"]
tau, p, _ = mk_trend(serie_estado)
log(f"Taxa estadual 2010: {serie_estado.iloc[0]:.2f} | 2024: {serie_estado.iloc[-1]:.2f} /100k")
log(f"Mann-Kendall estadual: tau={tau:.3f} p={p:.4f}")
log("Taxa estadual por ano:")
log(serie_estado.round(2).to_string())

tendencia_rows = []
for key, taxas in [("regiao_saude", taxas_reg), ("macro3", taxas_macro)]:
    for grp, sub in taxas.groupby(key):
        sub = sub.sort_values("ano")
        tau, p, _ = mk_trend(sub["taxa"])
        tendencia_rows.append({"unidade": key, "grupo": grp, "tau": tau, "p": p,
                               "taxa_2010": sub["taxa"].iloc[0],
                               "taxa_2024": sub["taxa"].iloc[-1]})
tendencia = pd.DataFrame(tendencia_rows)
tendencia.to_csv(os.path.join(TAB, "tendencia_mann_kendall.csv"), index=False)
log("Tendência por região/macrorregião:")
log(tendencia.round(3).to_string(index=False))

# proporção anual de óbito hospitalar + Cochran-Armitage
obito_ano = sih.groupby("ano")["obito_hospitalar"].agg(["sum", "count"])
obito_ano["pct"] = obito_ano["sum"] / obito_ano["count"] * 100
log(f"Mortalidade hospitalar global: {obito_ano['sum'].sum()/obito_ano['count'].sum()*100:.1f}%")
log(f"Pico anual: {obito_ano['pct'].max():.1f}% em {obito_ano['pct'].idxmax()}")
# Cochran-Armitage
k = obito_ano["sum"].values.astype(float)
n = obito_ano["count"].values.astype(float)
score = np.arange(len(k))
p_ca = _cochran_armitage(k, n, score)
log(f"Cochran-Armitage (proporção de óbito por ano): p={p_ca:.4f}")

# figura 1: taxa estadual + proporção de óbito
fig, ax1 = plt.subplots(figsize=(8, 4))
anos = taxas_estado.sort_values("ano")["ano"]
ax1.plot(anos, taxas_estado.sort_values("ano")["taxa"], "o-", color="tab:blue", label="Taxa/100k")
ax1.set_xlabel("Ano"); ax1.set_ylabel("Taxa / 100.000", color="tab:blue")
ax2 = ax1.twinx()
ax2.plot(obito_ano.index, obito_ano["pct"], "s--", color="tab:red", label="% óbito hospitalar")
ax2.set_ylabel("% óbito hospitalar", color="tab:red")
ax1.set_title("Internações por DCV (I60-I69), RJ 2010-2024")
fig.tight_layout()
fig.savefig(os.path.join(FIG, "fig1_taxa_obito.png"))
plt.close(fig)

# ----------------------------------------------------------------------------
# 3. MORTALIDADE — SIM
# ----------------------------------------------------------------------------
log("=" * 72)
log("3. MORTALIDADE (SIM, causa básica I60-I69)")
log("=" * 72)
n_sim = len(sim)
log(f"Óbitos I60-I69 (SIM, 2010-2024): {n_sim:,}")
log("Local de ocorrência:")
log(sim["local_ocorrencia"].value_counts(dropna=False).to_string())
log("Óbitos por CID3 (SIM):")
log(sim["cid3"].value_counts().sort_index().to_string())

taxas_obito = calc_taxas(sim, pop_reg, "regiao_saude")
taxas_obito_macro = calc_taxas(sim, pop_macro3, "macro3")
# taxa de mortalidade por região (média 2010-2024)
mort_reg = taxas_obito.groupby("regiao_saude")["taxa"].mean().sort_values(ascending=False)
log("Taxa média de mortalidade/100k por região (2010-2024):")
log(mort_reg.round(2).to_string())

# razão óbito/internação por região
obitos_reg = sim.groupby("regiao_saude").size()
int_reg = sih.groupby("regiao_saude").size()
razao = (obitos_reg / int_reg * 100).rename("razao_obito_internacao_pct")
razao_df = pd.DataFrame({"obitos_sim": obitos_reg, "internacoes_sih": int_reg,
                         "razao_pct": razao}).sort_values("razao_pct", ascending=False)
razao_df.to_csv(os.path.join(TAB, "razao_obito_internacao_regiao.csv"))
log("Razão óbito SIM / internação SIH por região (%):")
log(razao_df.round(2).to_string())

# mortalidade hospitalar por região (SIH)
obito_hosp_reg = sih.groupby("regiao_saude")["obito_hospitalar"].mean() * 100
log("Mortalidade hospitalar por região (%):")
log(obito_hosp_reg.sort_values(ascending=False).round(2).to_string())

# ----------------------------------------------------------------------------
# 4. PERMANÊNCIA E CUSTO
# ----------------------------------------------------------------------------
log("=" * 72)
log("4. PERMANÊNCIA E CUSTO")
log("=" * 72)
log(f"Permanência: mediana {sih['DIAS_PERM'].median():.0f} dias (IIQ "
    f"{sih['DIAS_PERM'].quantile(.25):.0f}-{sih['DIAS_PERM'].quantile(.75):.0f})")
log("Permanência por subtipo CID (mediana/IIQ):")
perm_cid = sih.groupby("cid3")["DIAS_PERM"].agg(
    mediana="median", q1=lambda x: x.quantile(.25), q3=lambda x: x.quantile(.75))
log(perm_cid.round(1).to_string())
log(f"Permanência I69 (sequelas): mediana {sih.loc[sih['cid3']=='I69','DIAS_PERM'].median():.0f}")

log(f"Custo total (correntes): R$ {sih['VAL_TOT'].sum():,.0f}")
log(f"Custo mediano por internação: R$ {sih['VAL_TOT'].median():,.2f}")
custo_reg = sih.groupby("regiao_saude")["VAL_TOT"].agg(
    mediana="median", total="sum", n="count")
custo_reg["medio"] = custo_reg["total"] / custo_reg["n"]
log("Custo por região (mediana e total correntes):")
log(custo_reg.round(2).to_string())

perm_custo_reg = sih.groupby("regiao_saude").agg(
    permanencia_mediana=("DIAS_PERM", "median"),
    custo_mediano=("VAL_TOT", "median"),
    obito_pct=("obito_hospitalar", "mean"),
    n=("obito_hospitalar", "size"))
perm_custo_reg["obito_pct"] *= 100
perm_custo_reg.to_csv(os.path.join(TAB, "permanencia_custo_regiao.csv"))

# Kruskal-Wallis (permanência e custo por região)
groups_p = [g["DIAS_PERM"].dropna().values for _, g in sih.groupby("regiao_saude")]
H_p, p_p = stats.kruskal(*groups_p)
groups_c = [g["VAL_TOT"].dropna().values for _, g in sih.groupby("regiao_saude")]
H_c, p_c = stats.kruskal(*groups_c)
log(f"Kruskal-Wallis permanência × região: H={H_p:.1f} p={p_p:.2e}")
log(f"Kruskal-Wallis custo × região: H={H_c:.1f} p={p_c:.2e}")

# ----------------------------------------------------------------------------
# 5. TESTES DE ASSOCIAÇÃO (qui-quadrado)
# ----------------------------------------------------------------------------
log("=" * 72)
log("5. ASSOCIAÇÕES (qui-quadrado)")
log("=" * 72)

def chi2_test(df, col):
    tab = pd.crosstab(df[col], df["obito_hospitalar"])
    tab = tab.loc[:, [c for c in [0, 1] if c in tab.columns]]
    if tab.shape[0] < 2:
        return None, None
    try:
        chi2, p, dof, _ = stats.chi2_contingency(tab)
    except Exception:
        return None, None
    return chi2, p

for col in ["regiao_saude", "macro3", "sexo", "faixa_etaria", "car_int", "cid3"]:
    if col in sih.columns:
        chi2, p = chi2_test(sih, col)
        if chi2 is not None:
            log(f"Óbito hospitalar × {col}: chi2={chi2:.1f} p={p:.2e}")

# ----------------------------------------------------------------------------
# 6. FLUXO TERRITORIAL E CNES
# ----------------------------------------------------------------------------
log("=" * 72)
log("6. FLUXO RESIDÊNCIA × INTERNAÇÃO E CNES")
log("=" * 72)

# município de residência != município de internação
sih["fluxo_diferente"] = (sih["MUNIC_RES6"] != sih["MUNIC_MOV"])
log(f"Internações fora do município de residência: {sih['fluxo_diferente'].mean()*100:.1f}%")

# top municípios de internação (polo assistencial)
top_mov = sih.groupby("mun_nome_mov").size().sort_values(ascending=False).head(15)
log("Top 15 municípios de internação (polo assistencial):")
log(top_mov.to_string())

# top CNES (estabelecimentos que concentram internações)
if "CNES" in sih.columns:
    top_cnes = sih.groupby("CNES").size().sort_values(ascending=False).head(10)
    # % de concentração
    top10_share = top_cnes.sum() / n_sih * 100
    log(f"Top 10 estabelecimentos (CNES) concentram: {top10_share:.1f}% das internações")
    top_cnes_df = top_cnes.rename("n").reset_index()
    top_cnes_df.to_csv(os.path.join(TAB, "top_cnes_concentracao.csv"), index=False)

# fluxo por macrorregião (origem residência → destino internação)
fluxo = pd.crosstab(sih["regiao_saude"], sih["mun_nome_mov"]).reset_index()
# (fluxo detalhado computado na etapa territorial)

# ----------------------------------------------------------------------------
# 7. FIGURAS ADICIONAIS
# ----------------------------------------------------------------------------
# figura 2: taxas por macrorregião ao longo do tempo
fig, ax = plt.subplots(figsize=(8, 4))
for grp, sub in taxas_macro.groupby("macro3"):
    sub = sub.sort_values("ano")
    ax.plot(sub["ano"], sub["taxa"], "o-", label=grp)
ax.set_xlabel("Ano"); ax.set_ylabel("Taxa / 100.000")
ax.set_title("Taxa de internação por DCV por macrorregião, RJ 2010-2024")
ax.legend(); fig.tight_layout()
fig.savefig(os.path.join(FIG, "fig2_taxa_macro.png"))
plt.close(fig)

# figura 3: mortalidade — hospitalar (SIH) vs SIM por região
fig, ax = plt.subplots(figsize=(8, 4))
comp = pd.DataFrame({"obito_hosp_pct": obito_hosp_reg,
                     "taxa_mort_100k": taxas_obito.groupby("regiao_saude")["taxa"].mean()})
comp.plot(kind="bar", ax=ax, secondary_y="taxa_mort_100k")
ax.set_title("Mortalidade por região: % óbito hospitalar (SIH) × taxa SIM/100k")
fig.tight_layout()
fig.savefig(os.path.join(FIG, "fig3_mortalidade_regiao.png"))
plt.close(fig)

# ----------------------------------------------------------------------------
# Resumo em arquivo
# ----------------------------------------------------------------------------
with open(os.path.join(RES, "resultados_principais.txt"), "w", encoding="utf-8") as f:
    f.write("\n".join(resumo))
log("=" * 72)
log(f"FIM — {n_sih:,} internações | {n_sim:,} óbitos SIM | tabelas em 05_tabelas | "
    f"figuras em 06_figuras")
