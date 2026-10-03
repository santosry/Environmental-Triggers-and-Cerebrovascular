#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Baixa os PDFs (texto completo gratuito) dos 13 artigos da MATRIZ_LITERATURA.md.

Estrategia:
  1. Para cada referencia, obtem/confirma o DOI via Crossref (por DOI direto ou
     por busca bibliografica do titulo).
  2. Extrai o link de PDF do campo `link` do Crossref.
  3. Baixa seguindo redirecionamentos e confirma que o arquivo e PDF (%PDF).
  4. Se o Crossref nao trouxer PDF, resolve o DOI e procura `citation_pdf_url`
     na pagina de destino.

Saida: 07_literatura/art01..art13_<slug>.pdf
"""
import json
import os
import re
import time
import unicodedata
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "07_literatura")
os.makedirs(OUT, exist_ok=True)
UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) "
      "Chrome/124.0 Safari/537.36")

ARTIGOS = [
    ("ref01_lotufo_carga_DCV_2017", "Doença cerebrovascular no Brasil de 1990 a 2015: Global Burden of Disease 2015", None),
    ("ref02_mendes_redes_atencao", "As redes de atenção à saúde", "10.1590/s1413-81232010000500005"),
    ("ref03_regionalizacao_2019", "Por uma análise política dos impasses da regionalização do SUS", "10.1590/0102-311x00077019"),
    ("ref04_albuquerque_avaliacao", "Avaliação de desempenho da regionalização da vigilância em saúde em seis Regiões de Saúde brasileiras", "10.1590/0102-311x00065218"),
    ("ref05_albuquerque_desafios", "Desafios para regionalização da Vigilância em Saúde na percepção de gestores", "10.1590/0103-1104202112802"),
    ("ref06_planejamento_2024", "Política, Planejamento e Gestão em Saúde: reflexões a partir da experiência de CSP", "10.1590/0102-311xpt164524"),
    ("ref07_vulnerabilidade_2021", "Vulnerabilidade social e crise sanitária no Brasil", "10.1590/0102-311x00071721"),
    ("ref08_souto_iniquidades", "Iniquidades raciais no acesso à reabilitação após AVC", None),
    ("ref09_mortalidade_DCV_Brasil", "Tendência da Mortalidade por Doenças Cerebrovasculares no Brasil (1996-2015) e Associação com Desenvolvimento Humano e Vulnerabilidade Social", "10.36660/abc.20190532"),
    ("ref10_obitos_AVC_2019", "Perfil dos óbitos por acidente vascular cerebral não especificado após investigação de códigos garbage em 60 cidades do Brasil, 2017", "10.1590/1980-549720190013.supl.3"),
    ("ref11_atencao_especializada_2022", "Atenção Especializada e transporte sanitário na perspectiva de integração às Redes de Atenção à Saúde", "10.1590/1413-812320222710.07432022"),
    ("ref12_padilha_governanca", "Crise no Brasil e impactos na frágil governança regional e federativa da política de saúde", "10.1590/1413-812320182412.25392019"),
    ("ref13_nilson_custos", "Custos atribuíveis à obesidade, hipertensão e diabetes no Sistema Único de Saúde, Brasil, 2018", None),
]

# Fallback direto para itens cujo PDF não esta no Crossref ou cujo domínio bloqueia.
FALLBACK = {
    # PAHO/IRIS retorna 403 no link classico; este e o bitstream via API DSpace.
    "ref13_nilson_custos": "https://iris.paho.org/server/api/core/bitstreams/2f4bb3c1-cb7e-4979-9214-167d945f6b8a/content",
    # Arq Bras Cardiol: o Crossref so traz a pagina de destino; PDF direto:
    "ref09_mortalidade_DCV_Brasil": "https://abccardiol.org/wp-content/uploads/articles_xml/0066-782X-abc-116-01-0089/0066-782X-abc-116-01-0089.pdf",
}


def http(url, timeout=60, headers=None):
    h = {"User-Agent": UA, "Accept": "*/*"}
    if headers:
        h.update(headers)
    req = urllib.request.Request(url, headers=h)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read(), r.geturl(), dict(r.headers)


def crossref(url):
    data, _, _ = http(url, headers={"Accept": "application/json"})
    return json.loads(data.decode("utf-8", "replace"))


def acha_doi(titulo):
    q = urllib.parse.quote(titulo)
    j = crossref("https://api.crossref.org/works?query.bibliographic=" + q + "&rows=3")
    for item in j["message"]["items"]:
        t = (item.get("title") or [""])[0]
        if not t:
            continue
        # compara por sobreposicao de palavras significativas
        a = set(re.findall(r"\w{4,}", titulo.lower()))
        b = set(re.findall(r"\w{4,}", t.lower()))
        if len(a & b) >= max(3, len(a) // 2):
            return item.get("DOI")
    return None


def link_pdf_crossref(doi):
    j = crossref("https://api.crossref.org/works/" + urllib.parse.quote(doi))
    m = j["message"]
    cands = []
    for l in m.get("link", []):
        u = l.get("URL", "")
        if "pdf" in u.lower() or "pdf" in l.get("content-type", ""):
            cands.append(u)
    if not cands:
        u = m.get("URL", "")
        cands.append(u)
    return m, cands


def pdf_da_pagina(url):
    try:
        data, final, _ = http(url)
    except Exception:
        return None
    html = data.decode("utf-8", "replace")
    for pat in [r'citation_pdf_url"\s+content="([^"]+)"',
                r'href="([^"]+\.pdf[^"]*)"',
                r'href="([^"]+format=pdf[^"]*)"']:
        m = re.search(pat, html, flags=re.I)
        if m:
            return urllib.parse.urljoin(final, m.group(1).replace("&amp;", "&"))
    return None


def baixa(url, destino):
    data, final, headers = http(url)
    ct = headers.get("Content-Type", "")
    if data[:4] != b"%PDF" and "pdf" not in ct.lower():
        # talvez seja uma página com link para o PDF
        if b"<html" in data[:2000].lower():
            alt = pdf_da_pagina(final)
            if alt:
                data, final, headers = http(alt)
    if data[:4] != b"%PDF" and "pdf" not in headers.get("Content-Type", "").lower():
        raise ValueError("resposta nao e PDF (content-type=%s)" % ct)
    with open(destino, "wb") as fh:
        fh.write(data)
    return len(data)


def slug(t):
    t = unicodedata.normalize("NFKD", t).encode("ascii", "ignore").decode()
    t = re.sub(r"[^A-Za-z0-9]+", "_", t).strip("_")
    return t[:60]


def main():
    log = []
    for i, (nome, titulo, doi) in enumerate(ARTIGOS, start=1):
        dest = os.path.join(OUT, nome + ".pdf")
        linha = nome
        if os.path.exists(dest) and os.path.getsize(dest) > 20000:
            log.append(linha + " | JA EXISTE (%d KB)" % (os.path.getsize(dest) // 1024))
            print(log[-1], flush=True)
            continue
        try:
            if nome in FALLBACK:
                try:
                    n = baixa(FALLBACK[nome], dest)
                    log.append(linha + " | OK(fallback) %d KB" % (n // 1024))
                    print(log[-1], flush=True)
                    continue
                except Exception as e:
                    log.append(linha + " | fallback falhou: " + str(e)[:80])
            if not doi:
                doi = acha_doi(titulo)
            if not doi:
                log.append(linha + " | SEM DOI")
                print(log[-1], flush=True)
                continue
            meta, cands = link_pdf_crossref(doi)
            ok = False
            erros = []
            for u in cands:
                try:
                    n = baixa(u, dest)
                    log.append(linha + " | OK %d KB | %s" % (n // 1024, u))
                    print(log[-1], flush=True)
                    ok = True
                    break
                except Exception as e:
                    erros.append("%s: %s" % (u, str(e)[:70]))
            if not ok:
                # tenta a página do DOI
                alt = pdf_da_pagina("https://doi.org/" + urllib.parse.quote(doi))
                if alt:
                    try:
                        n = baixa(alt, dest)
                        log.append(linha + " | OK(pagina) %d KB | %s" % (n // 1024, alt))
                        print(log[-1], flush=True)
                        ok = True
                    except Exception as e:
                        erros.append("pagina: " + str(e)[:70])
            if not ok:
                log.append(linha + " | FALHA | " + " ; ".join(erros)[:200])
                print(log[-1], flush=True)
        except Exception as e:
            log.append(linha + " | ERRO | " + str(e)[:150])
            print(log[-1], flush=True)
        time.sleep(1.5)
    with open(os.path.join(OUT, "log_download.txt"), "w", encoding="utf-8") as fh:
        fh.write("\n".join(log) + "\n")


if __name__ == "__main__":
    main()
