# -*- coding: utf-8 -*-
"""
01_consolidar_dados.py  (versão paralela)
======================
Consolida SIH-RD (2010-2025, análise 2010-2024) e SIM (2010-2024) em arquivos
individuais padronizados.

Leitura robusta: tenta pyreadr (C, rápido) e, se falhar por codificação,
recorre a rdata (Python puro, tolerante a Latin-1) — com multiprocessing.

Grava resultados intermediários em 01_dados/tmp_parquet/ (retomável).
"""

import os
import sys
import glob
import json
import warnings
import multiprocessing as mp
import pandas as pd
import numpy as np

warnings.filterwarnings("ignore")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DLNM_ROOT = os.path.dirname(ROOT)
SRC_SIH = os.path.join(DLNM_ROOT, "05_publicacao_github", "data", "raw", "sih")
SRC_SIM = os.path.join(DLNM_ROOT, "05_publicacao_github", "data", "raw", "sim")
SRC_LOOKUP = os.path.join(DLNM_ROOT, "05_publicacao_github", "data", "processed",
                          "lookup_municipio_macrorregiao.csv")
OUT_DIR = os.path.join(ROOT, "01_dados", "processados")
INV_DIR = os.path.join(ROOT, "01_dados", "inventario_colunas")
TMP_DIR = os.path.join(ROOT, "01_dados", "tmp_parquet")
for d in (OUT_DIR, INV_DIR, TMP_DIR):
    os.makedirs(d, exist_ok=True)

CID6 = [f"I6{i}" for i in range(10)]
N_WORKERS = 3


def read_rds_robust(path):
    """Lê .rds: pyreadr (rápido) com fallback rdata (tolerante)."""
    try:
        import pyreadr
        res = pyreadr.read_r(path)
        df = list(res.values())[0]
        df.columns = [str(c) for c in df.columns]
        return df, "pyreadr"
    except Exception:
        import rdata
        df = rdata.read_rds(path, default_encoding="latin-1",
                            force_default_encoding=True, expand_altrep=False)
        if not isinstance(df, pd.DataFrame):
            raise TypeError(f"{path}: não é data.frame")
        df.columns = [str(c) for c in df.columns]
        return df, "rdata"


def _sih_worker(path):
    """Processa um arquivo SIH mensal -> (basename, DataFrame filtrado)."""
    try:
        df, src = read_rds_robust(path)
        diag = df["DIAG_PRINC"].astype("string").str.slice(0, 3)
        df = df[diag.isin(CID6)].copy()
        mun = df["MUNIC_RES"].astype("string").str.zfill(6)
        df["MUNIC_RES6"] = mun
        df = df[mun.str.startswith("33")]
        df["_src"] = src
        return os.path.basename(path), df
    except Exception as e:
        return os.path.basename(path), ("ERRO", str(e)[:120])


def _sim_worker(path):
    try:
        df, src = read_rds_robust(path)
        caus = df["CAUSABAS"].astype("string").str.slice(0, 3)
        df = df[caus.isin(CID6)].copy()
        mun = df["CODMUNRES"].astype("string").str.zfill(6)
        df["MUNIC_RES6"] = mun
        df = df[mun.str.startswith("33")]
        df["_src"] = src
        return os.path.basename(path), df
    except Exception as e:
        return os.path.basename(path), ("ERRO", str(e)[:120])


def _run_parallel(worker, paths, tag):
    """Processa arquivos em paralelo; grava parquet por arquivo (retomável)."""
    # pula arquivos já convertidos
    pending = []
    for p in paths:
        key = os.path.basename(p).replace(".rds", "")
        if not os.path.exists(os.path.join(TMP_DIR, f"{tag}_{key}.parquet")):
            pending.append(p)
    print(f"  {tag}: {len(paths) - len(pending)}/{len(paths)} já convertidos; "
          f"{len(pending)} pendentes", flush=True)
    if not pending:
        return [os.path.join(TMP_DIR, f"{tag}_{os.path.basename(p).replace('.rds','')}.parquet")
                for p in paths]

    out_files = []
    def save(job_result):
        if job_result is None:
            return None
        name, df = job_result
        if isinstance(df, tuple) and df and df[0] == "ERRO":
            print(f"  [ERRO] {name}: {df[1]}", flush=True)
            return None
        key = name.replace(".rds", "")
        out = os.path.join(TMP_DIR, f"{tag}_{key}.parquet")
        if not os.path.exists(out):
            df.to_parquet(out, index=False)
        return out

    done = 0
    with mp.Pool(N_WORKERS) as pool:
        for out in pool.imap_unordered(worker, pending):
            done += 1
            try:
                saved = save(out)
            except Exception as e:
                print(f"  [ERRO gravação] {str(e)[:80]}", flush=True)
                saved = None
            if saved:
                out_files.append(saved)
            if done % 10 == 0 or done == len(pending):
                print(f"  {tag}: {done}/{len(pending)} pendentes processados", flush=True)
    return out_files


def load_parquets(out_files):
    frames = []
    for f in out_files:
        if f and os.path.exists(f):
            frames.append(pd.read_parquet(f))
    return pd.concat(frames, ignore_index=True, sort=False) if frames else pd.DataFrame()


if __name__ == "__main__":
    print("=" * 70)
    print("CONSOLIDAÇÃO PARALELA — SIH-RD e SIM")
    print("=" * 70)

    sih_paths = []
    for ano in range(2010, 2026):
        for mes in range(1, 13):
            f = glob.glob(os.path.join(SRC_SIH, f"sih_rd_rj_{ano}_{mes:02d}.rds"))
            if f:
                sih_paths.append(f[0])
    print(f"Arquivos SIH encontrados: {len(sih_paths)}")

    sim_paths = []
    for ano in range(2010, 2025):
        f = glob.glob(os.path.join(SRC_SIM, f"sim_do_rj_year_{ano}.rds"))
        if f:
            sim_paths.append(f[0])
    print(f"Arquivos SIM encontrados: {len(sim_paths)}")

    print("Processando SIH...")
    sih_out = _run_parallel(_sih_worker, sih_paths, "sih")
    sih = load_parquets(sih_out)
    print(f"SIH bruto I60-I69 (residentes RJ): {len(sih):,}")

    print("Processando SIM...")
    sim_out = _run_parallel(_sim_worker, sim_paths, "sim")
    sim = load_parquets(sim_out)
    print(f"SIM bruto I60-I69 (residentes RJ): {len(sim):,}")

    # ------------------------------------------------------------------
    # Deduplicação SIH
    # ------------------------------------------------------------------
    DEDUP_KEY = ["N_AIH", "IDENT", "DT_INTER", "DT_SAIDA", "DIAG_PRINC",
                 "MUNIC_RES6", "SEXO", "IDADE"]
    sih["_dup"] = sih.duplicated(subset=[c for c in DEDUP_KEY if c in sih.columns],
                                 keep="first")
    n_dup = int(sih["_dup"].sum())
    sih = sih[~sih["_dup"]].drop(columns=["_dup"])
    print(f"Duplicatas SIH removidas: {n_dup:,}")
    print(f"SIH único (antes filtro período): {len(sih):,}")

    # ------------------------------------------------------------------
    # Datas e filtro de período
    # ------------------------------------------------------------------
    sih["DT_INTER_d"] = pd.to_datetime(sih["DT_INTER"].astype("string"),
                                       format="%Y%m%d", errors="coerce")
    sih["DT_SAIDA_d"] = pd.to_datetime(sih["DT_SAIDA"].astype("string"),
                                       format="%Y%m%d", errors="coerce")
    sih["NASC_d"] = pd.to_datetime(sih["NASC"].astype("string"),
                                   format="%Y%m%d", errors="coerce")
    sih = sih[(sih["DT_INTER_d"] >= "2010-01-01") & (sih["DT_INTER_d"] <= "2024-12-31")]
    print(f"SIH após filtro DT_INTER 2010-2024: {len(sih):,}")

    sim["DTOBITO_d"] = pd.to_datetime(sim["DTOBITO"].astype("string"),
                                      format="%d%m%Y", errors="coerce")
    sim = sim[(sim["DTOBITO_d"] >= "2010-01-01") & (sim["DTOBITO_d"] <= "2024-12-31")]
    print(f"SIM após filtro DTOBITO 2010-2024: {len(sim):,}")

    # ------------------------------------------------------------------
    # Lookup municipal
    # ------------------------------------------------------------------
    lookup = pd.read_csv(SRC_LOOKUP, dtype=str)
    lookup["ibge6"] = lookup["ibge6"].str.zfill(6)
    lookup["ibge7"] = lookup["ibge7"].str.zfill(7)
    def macro3(regiao):
        if regiao in ("Metropolitana I", "Metropolitana II"):
            return "Metropolitana"
        if regiao in ("Serrana", "Medio Paraiba", "Centro-Sul", "Baia da Ilha Grande"):
            return "Centro-Sul"
        if regiao in ("Norte", "Noroeste", "Baixada Litoranea"):
            return "Norte e Noroeste"
        return np.nan
    lookup["regiao_saude"] = lookup["macro_regiao"]
    lookup["macro3"] = lookup["regiao_saude"].map(macro3)

    # ------------------------------------------------------------------
    # Derivadas SIH
    # ------------------------------------------------------------------
    s = lambda df, c: df[c].astype("string").str.strip()
    sih["sexo"] = s(sih, "SEXO").map({"1": "M", "3": "F"}).fillna("I")
    # Forçar float64 para evitar TypeError ao atribuir frações em coluna Int32 nullable
    sih["idade_anos"] = pd.to_numeric(sih["IDADE"], errors="coerce").astype("float64")
    cod = s(sih, "COD_IDADE")
    sih.loc[cod == "3", "idade_anos"] = sih.loc[cod == "3", "idade_anos"] / 12
    sih.loc[cod == "2", "idade_anos"] = sih.loc[cod == "2", "idade_anos"] / 365
    sih.loc[cod == "1", "idade_anos"] = sih.loc[cod == "1", "idade_anos"] / (365 * 24)
    sih["cid3"] = s(sih, "DIAG_PRINC").str.slice(0, 3)
    sih["cid4"] = s(sih, "DIAG_PRINC").str.slice(0, 4)

    sih = sih.merge(lookup[["ibge6", "mun_nome", "regiao_saude", "macro3"]],
                    left_on="MUNIC_RES6", right_on="ibge6", how="left")
    sih = sih.merge(lookup[["ibge6", "mun_nome"]].rename(columns={"mun_nome": "mun_nome_mov"}),
                    left_on="MUNIC_MOV", right_on="ibge6", how="left")

    for c in ["DIAS_PERM", "VAL_TOT", "VAL_SH", "VAL_SP", "VAL_UTI", "UTI_MES_TO",
              "US_TOT", "IDADE"]:
        if c in sih.columns:
            sih[c] = pd.to_numeric(sih[c], errors="coerce")

    sih["obito_hospitalar"] = s(sih, "MORTE").map({"1": 1, "0": 0}).fillna(0).astype(int)

    CAR_INT = {"01": "Eletiva", "02": "Urgência", "03": "Acidente trabalho",
               "04": "Acidente trajeto", "05": "Outros acidentes",
               "06": "Outras lesões", "07": "Outros"}
    sih["car_int"] = s(sih, "CAR_INT").map(CAR_INT).fillna("Ignorado")

    RACA_SIH = {"01": "Branca", "02": "Preta", "03": "Parda", "04": "Amarela",
                "05": "Indígena", "99": "Sem informação"}
    sih["raca_cor"] = s(sih, "RACA_COR").map(RACA_SIH).fillna("Sem informação")

    INSTRU = {"0": "Sem instrução", "1": "Fundamental I incompleto",
              "2": "Fundamental I completo", "3": "Fundamental II incompleto",
              "4": "Fundamental II completo", "5": "Médio completo",
              "6": "Superior incompleto", "7": "Superior completo", "9": "Ignorado"}
    sih["instru"] = s(sih, "INSTRU").map(INSTRU).fillna("Ignorado")

    bins = [-1, 18, 45, 60, 75, 200]
    labels = ["<18", "18-44", "45-59", "60-74", "75+"]
    sih["faixa_etaria"] = pd.cut(sih["idade_anos"], bins=bins, labels=labels)
    sih["ano"] = sih["DT_INTER_d"].dt.year

    # ------------------------------------------------------------------
    # Derivadas SIM
    # ------------------------------------------------------------------
    sim["idade_bruta"] = pd.to_numeric(sim["IDADE"], errors="coerce")
    def idade_sim(v):
        if pd.isna(v) or v == 999:
            return np.nan
        v = int(v)
        centena, resto = v // 100, v % 100
        if centena == 4:
            return float(resto)
        if centena == 5:
            return float(100 + resto)
        if centena == 3:
            return resto / 12
        if centena == 2:
            return resto / (365 * 24)
        if centena == 1:
            return resto / (365 * 24 * 60)
        return np.nan
    sim["idade_anos"] = sim["idade_bruta"].map(idade_sim)
    sim["sexo"] = s(sim, "SEXO").map({"1": "M", "2": "F"}).fillna("I")
    RACA_SIM = {"1": "Branca", "2": "Preta", "3": "Amarela", "4": "Parda",
                "5": "Indígena", "9": "Ignorado"}
    sim["raca_cor"] = s(sim, "RACACOR").map(RACA_SIM).fillna("Ignorado")
    ESC_SIM = {"1": "Nenhuma", "2": "1-3 anos", "3": "4-7 anos", "4": "8-11 anos",
               "5": "12 anos ou mais", "9": "Ignorado"}
    sim["esc"] = s(sim, "ESC").map(ESC_SIM).fillna("Ignorado")
    LOCOCOR = {"1": "Hospital", "2": "Outro estab. saúde", "3": "Domicílio",
               "4": "Via pública", "5": "Outros", "9": "Ignorado"}
    sim["local_ocorrencia"] = s(sim, "LOCOCOR").map(LOCOCOR).fillna("Ignorado")
    sim["cid3"] = s(sim, "CAUSABAS").str.slice(0, 3)
    sim["cid4"] = s(sim, "CAUSABAS").str.slice(0, 4)

    sim = sim.merge(lookup[["ibge6", "mun_nome", "regiao_saude", "macro3"]],
                    left_on="MUNIC_RES6", right_on="ibge6", how="left")
    sim = sim.merge(lookup[["ibge6", "mun_nome"]].rename(columns={"mun_nome": "mun_nome_ocor"}),
                    left_on="CODMUNOCOR", right_on="ibge6", how="left")
    sim["faixa_etaria"] = pd.cut(sim["idade_anos"], bins=bins, labels=labels)
    sim["ano"] = sim["DTOBITO_d"].dt.year

    # ------------------------------------------------------------------
    # Gravação
    # ------------------------------------------------------------------
    sih.to_csv(os.path.join(OUT_DIR, "sih_cerebrovascular_2010_2024.csv"), index=False)
    sim.to_csv(os.path.join(OUT_DIR, "sim_cerebrovascular_2010_2024.csv"), index=False)
    print(f"Gravado SIH: {len(sih):,} linhas")
    print(f"Gravado SIM: {len(sim):,} linhas")

    # Inventário de colunas por arquivo (derivado dos parquets já gravados)
    inv = {}
    for f in sorted(glob.glob(os.path.join(TMP_DIR, "sih_*.parquet"))):
        try:
            cols = list(pd.read_parquet(f, columns=None).columns)
            inv[os.path.basename(f)] = [str(c) for c in cols]
        except Exception:
            pass
    with open(os.path.join(INV_DIR, "sih_colunas_por_arquivo.json"), "w",
              encoding="utf-8") as fp:
        json.dump(inv, fp, ensure_ascii=False, indent=0)

    print("=" * 70)
    print("RESUMO FINAL")
    print(f"SIH I60-I69 residentes RJ, DT_INTER 2010-2024: {len(sih):,}")
    print(f"SIM I60-I69 residentes RJ, DTOBITO 2010-2024: {len(sim):,}")
    print("SIH por CID3:")
    print(sih["cid3"].value_counts().sort_index().to_string())
    print("SIM por CID3:")
    print(sim["cid3"].value_counts().sort_index().to_string())
