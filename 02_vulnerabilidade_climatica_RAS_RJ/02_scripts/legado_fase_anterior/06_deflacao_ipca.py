#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
06_deflacao_ipca.py
-------------------
Deflação dos custos assistenciais (SIH-RD, VAL_TOT) para reais de dezembro de 2024
pelo IPCA (IBGE), usando a série de número-índice mensal (SIDRA tabela 1737,
variável 2266).

Método
------
1. Série mensal do número-índice do IPCA (base: dez/1993 = 100).
2. Fator de correção para dez/2024 de cada ano t (fluxo anual):
       fator(t) = indice_dez2024 / indice_medio_anual(t).
   (Fluxos anuais acumulam-se ao longo do ano; o índice médio é o padrão para
    deflacionar totais anuais a uma data de referência.)
3. Custo deflacionado = custo corrente (VAL_TOT) * fator(t).

Fontes: SIDRA/IBGE (API), arquivo em 01_dados/tmp_ipca/ipca_1737_2266.json.
Saídas: 05_tabelas/custos_deflacionados_ipca.csv
        04_resultados/resultados_deflacao_ipca.txt
"""
import json
import os
import statistics

import pandas as pd

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IPCA_JSON = os.path.join(ROOT, "01_dados", "tmp_ipca", "ipca_1737_2266.json")
SIH_CSV = os.path.join(ROOT, "01_dados", "processados", "sih_cerebrovascular_2010_2024.csv")
TAB_DIR = os.path.join(ROOT, "05_tabelas")
RES_DIR = os.path.join(ROOT, "04_resultados")
BASE_YM = "202412"  # base de referência: dezembro de 2024

os.makedirs(TAB_DIR, exist_ok=True)
os.makedirs(RES_DIR, exist_ok=True)

# --- 1. Ler IPCA (número-índice mensal) -------------------------------------
with open(IPCA_JSON, encoding="utf-8") as fh:
    raw = json.load(fh)
rows = raw[1:]
pts = sorted((r["D3C"], float(r["V"])) for r in rows)
index_by_ym = dict(pts)

by_year = {}
for ym, val in pts:
    by_year.setdefault(ym[:4], []).append((ym, val))

base_index = index_by_ym[BASE_YM]

# --- 2. Fatores --------------------------------------------------------------
fatores = []
for ano in sorted(by_year):
    vals = [v for _, v in by_year[ano]]
    media = statistics.mean(vals)
    dez = by_year[ano][-1][1]
    fatores.append(
        {
            "ano": int(ano),
            "indice_medio_ano": media,
            "indice_dez_ano": dez,
            "fator_para_dez2024_media": base_index / media,
            "fator_para_dez2024_dez_dez": base_index / dez,
        }
    )
fat = pd.DataFrame(fatores)

# --- 3. Ler SIH e deflacionar -------------------------------------------------
sih = pd.read_csv(
    SIH_CSV,
    usecols=["ano", "macro3", "regiao_saude", "VAL_TOT"],
    dtype={"ano": "int64", "VAL_TOT": "float64"},
)
sih["VAL_TOT"] = pd.to_numeric(sih["VAL_TOT"], errors="coerce").fillna(0.0)
sih = sih.merge(fat[["ano", "fator_para_dez2024_media", "fator_para_dez2024_dez_dez"]], on="ano", how="left")
sih["custo_deflacionado"] = sih["VAL_TOT"] * sih["fator_para_dez2024_media"]

por_macro = (
    sih.groupby("macro3", as_index=False)
    .agg(
        n_internacoes=("VAL_TOT", "size"),
        custo_corrente=("VAL_TOT", "sum"),
        custo_deflacionado_dez2024=("custo_deflacionado", "sum"),
    )
    .sort_values("custo_deflacionado_dez2024", ascending=False)
)
por_macro["custo_medio_deflacionado"] = por_macro["custo_deflacionado_dez2024"] / por_macro["n_internacoes"]

por_regiao = (
    sih.groupby("regiao_saude", as_index=False)
    .agg(
        n_internacoes=("VAL_TOT", "size"),
        custo_corrente=("VAL_TOT", "sum"),
        custo_deflacionado_dez2024=("custo_deflacionado", "sum"),
    )
    .sort_values("custo_deflacionado_dez2024", ascending=False)
)
por_regiao["custo_medio_deflacionado"] = por_regiao["custo_deflacionado_dez2024"] / por_regiao["n_internacoes"]

por_ano = (
    sih.groupby("ano", as_index=False)
    .agg(custo_corrente=("VAL_TOT", "sum"), custo_deflacionado_dez2024=("custo_deflacionado", "sum"))
)

total_corrente = sih["VAL_TOT"].sum()
total_defl = sih["custo_deflacionado"].sum()

# --- 4. Salvar -----------------------------------------------------------------
fat.to_csv(os.path.join(TAB_DIR, "fatores_deflacao_ipca.csv"), index=False)
por_macro.to_csv(os.path.join(TAB_DIR, "custos_deflacionados_ipca_macro.csv"), index=False)
por_regiao.to_csv(os.path.join(TAB_DIR, "custos_deflacionados_ipca_regiao.csv"), index=False)
por_ano.to_csv(os.path.join(TAB_DIR, "custos_deflacionados_ipca_ano.csv"), index=False)

linhas = []
linhas.append("=" * 72)
linhas.append("DEFLAÇÃO DOS CUSTOS PELO IPCA (base: dezembro/2024)")
linhas.append("Fonte: IBGE/SIDRA tabela 1737, variável 2266 (número-índice mensal)")
linhas.append("Fator: indice_dez2024 / indice_médio_anual(t)  [fluxo anual → dez/2024]")
linhas.append("=" * 72)
linhas.append("")
linhas.append("Custo total corrente (2010-2024):        R$ {:,.2f}".format(total_corrente))
linhas.append("Custo total deflacionado (dez/2024):     R$ {:,.2f}".format(total_defl))
linhas.append("Inflação acumulada implícita 2010-2024:  {:.1f}%".format(
    (fat.loc[fat["ano"] == 2010, "fator_para_dez2024_media"].iloc[0] - 1) * 100))
linhas.append("")
linhas.append("Fatores de deflação por ano:")
linhas.append(fat[["ano", "indice_medio_ano", "fator_para_dez2024_media", "fator_para_dez2024_dez_dez"]].to_string(index=False))
linhas.append("")
linhas.append("Custo por macrorregião (corrente e deflacionado a dez/2024):")
linhas.append(por_macro.to_string(index=False))
linhas.append("")
linhas.append("Custo por região de saúde (corrente e deflacionado a dez/2024):")
linhas.append(por_regiao.to_string(index=False))
linhas.append("")
linhas.append("Nota: série de número-índice obtida em 26/09/2025 via API SIDRA/IBGE;")
linhas.append("      fatores calculados pelo índice médio anual do IPCA.")

with open(os.path.join(RES_DIR, "resultados_deflacao_ipca.txt"), "w", encoding="utf-8") as fh:
    fh.write("\n".join(linhas) + "\n")

print("\n".join(linhas))
print("\n[OK] Tabelas e resultados salvos.")
