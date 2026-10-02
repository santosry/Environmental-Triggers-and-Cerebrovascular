# Relatório final — Revisão sistemática e meta-análise

**Título:** Environmental determinants of cerebrovascular diseases (ICD-10 I60–I69)
across the lifespan: a global systematic review and meta-analysis
**Versão:** 1.0 (protocolo/estrutura) — `r format(Sys.Date)`
**Relato:** PRISMA 2020 (Page et al., 2021; doi:10.1136/bmj.n71)

> Este relatório segue a estrutura do PRISMA 2020 (itens 1–27). As seções de resultados
> são preenchidas automaticamente pelos scripts; os campos numéricos refletem as saídas
> reais do pipeline quando executado.

---

## Resumo

**Antecedentes.** As doenças cerebrovasculares (CID-10 I60–I69) estão entre as principais
causas de morte e incapacidade no mundo, com carga crescente [Feigin et al., 2021]. Fatores
ambientais modificáveis — clima, poluição, saneamento, moradia, catástrofes e ambiente
construído — são determinantes relevantes e potencialmente modificáveis por políticas
públicas [Landrigan et al., 2018; WHO, 2021].

**Objetivos.** Sintetizar quantitativamente a associação entre exposições ambientais
modificáveis e desfechos cerebrovasculares (I60–I69) em todas as idades.

**Métodos.** Revisão sistemática (bases PubMed, Scopus e SciELO; 2020–2026; EN/PT/ES) com meta-análise de efeitos aleatórios (REML). Risco de viés por
ROBINS-I/NOS/OHAT; certeza por GRADE.

**Resultados.** [preencher após execução — ver §Resultados]

**Conclusões.** [preencher após execução]

---

## 1. Introdução

As doenças cerebrovasculares compreendem o AVC isquêmico (I63), as hemorragias
intracranianas (I60–I62), o AVC não especificado (I64), a doença oclusiva de artérias
cerebrais (I65–I66), outras doenças cerebrovasculares (I67–I68) e as sequelas (I69)
[WHO, 1992]. O GBD 2019 documentou carga global elevada e tendência heterogênea
[Feigin et al., 2021]. A exposição a determinantes ambientais — temperatura ambiente e
extremos térmicos [Gasparrini et al., 2015], poluição do ar [WHO, 2021], poluição da água
e do solo, ruído, condições de saneamento, moradia e combustíveis sólidos, catástrofes e
ambiente construído [Landrigan et al., 2018; Prüss-Ustün et al., 2016] — relaciona-se a
desfechos cardiovasculares, mas a evidência específica para DCV é fragmentada.

## 2. Métodos

### 2.1 Protocolo e registro
Protocolo em `00_docs/protocolo_PROSPERO.md`, estruturado conforme PRISMA-P 2015
[Moher et al., 2015]. Registro PROSPERO: [preencher].

### 2.2 Critérios de elegibilidade
Conforme `00_docs/criterios_inclusao_exclusao.md` (PICO; período 2020–2026;
EN/PT/ES; delineamentos observacionais e quase-experimentais).

### 2.3 Fontes de informação e estratégia de busca
Três bases (PubMed/MEDLINE, Scopus, SciELO) + literatura cinzenta + citação em cadeia; strings completas em `00_docs/estrategia_busca.md`;
construção assistida por `litsearchr` [Grames et al., 2019].

### 2.4 Seleção dos estudos
Deduplicação com `revtools` [Westgate, 2019]; triagem por dois revisores independentes
com medida de concordância (κ de Cohen); discordâncias por consenso/terceiro.

### 2.5 Extração de dados
Formulário `00_docs/dicionario_dados.md`; extração em duplicata (≥20%) e piloto
(≥10 estudos). Dados de figuras via `metaDigitise` [McGrath et al., 2019].

### 2.6 Medidas de efeito
RR/OR/HR em escala logarítmica [Rothman et al., 2008; Borenstein et al., 2021].

### 2.7 Risco de viés
ROBINS-I [Sterne et al., 2016], NOS [Wells et al., 2000] e OHAT [OHAT/NTP, 2015];
figuras com `robvis` [McGuinness & Higgins, 2021].

### 2.8 Síntese
Efeitos aleatórios com REML [Viechtbauer, 2005], I²/τ² [Higgins & Thompson, 2002],
intervalo de predição [IntHout et al., 2016], HK/SJ quando ≤10 estudos
[IntHout et al., 2014]. Viés de publicação: funil, Egger [Egger et al., 1997],
trim-and-fill [Duval & Tweedie, 2000], interpretados conforme [Sterne et al., 2011].

### 2.9 Subgrupos e sensibilidade
Categoria de exposição, subtipo de desfecho, desenho, região/renda, faixa etária;
`leave-one-out`, exclusão de alto risco de viés, E-value [VanderWeele & Ding, 2017].

### 2.10 Certeza da evidência
GRADE [Guyatt et al., 2008; Schünemann et al., 2013].

## 3. Resultados

> Preenchimento automático a partir das saídas do pipeline.

### 3.1 Seleção dos estudos
Ver `03_resultados/tabelas/prisma_identificacao.csv` e
`03_resultados/tabelas/prisma_contagens.csv`; diagrama em
`03_resultados/figuras/prisma_flow_diagram.png`.

### 3.2 Características dos estudos
Ver `02_dados/extraidos/planilha_extracao.csv`.

### 3.3 Risco de viés
Ver `03_resultados/figuras/rob_traffic_light.png` e `rob_summary.png`.

### 3.4 Síntese
Ver `03_resultados/tabelas/meta_analise_geral.csv` (efeito agrupado, I², τ², predição) e
`03_resultados/figuras/forest_geral.png`.

### 3.5 Subgrupos, metarregressão e sensibilidade
Ver `subgrupos.csv`, `metarregressao.csv`, `leave_one_out.csv`.

### 3.6 Viés de publicação e certeza
Ver `vies_publicacao.txt`; GRADE em §4.

## 4. Discussão

### 4.1 Interpretação
[preencher após execução, com base nas estimativas e na heterogeneidade]

### 4.2 Limitações das evidências
Dependem dos estudos incluídos: risco de confundimento temporal/sazonal, classificação da
exposição (dados agregados vs. individuais), variabilidade de definições de extremos
térmicos e de poluentes.

### 4.3 Limitações da revisão
Restrição de período (2020–2026) e idiomas (EN/PT/ES); possível viés de publicação;
heterogeneidade de medidas de efeito; dependência de dados publicados.

### 4.4 Implicações
Vigilância de base territorial, integração clima–poluição–saneamento nas políticas de
saúde, e agenda de pesquisa (ex.: modelos de defasagem distribuída, coortes com
exposição individual).

## 5. Conclusão

[preencher após execução]

## 6. Disponibilidade

- Código: `01_scripts/`
- Dados derivados: `02_dados/processados/`, `02_dados/extraidos/`
- Resultados: `03_resultados/`
- Sessão/versões: `04_referencias/session_info.txt`

## 7. Referências

Ver `04_referencias/referencias.bib` e `04_referencias/protocolo_referencias.md`.
