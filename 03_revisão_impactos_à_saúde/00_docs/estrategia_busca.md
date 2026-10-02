# Estratégias de busca

Referências metodológicas: PRISMA 2020 (Page MJ, et al. *BMJ*. 2021;372:n71), PRISMA-P
2015 (Moher D, et al. *Syst Rev*. 2015;4:1) e Cochrane Handbook (Higgins JPT, et al.,
2019). As buscas foram construídas em três blocos (População/Desfecho × Exposição),
combinados por `AND`. A escolha de vocabulário controlado (MeSH/Emtree/DeCS) e de texto
livre segue a recomendação de alta sensibilidade da Cochrane [Ref. 4].

- **Período:** `2020/01/01` a `2026/09/30`
- **Idiomas:** inglês, português, espanhol
- **Validação:** a estratégia foi testada contra um conjunto-semente de artigos
  conhecidos (ver `02_busca/validacao_sensibilidade.md`).

---

## Bloco 1 — Desfecho (CID-10 I60–I69)

### Vocabulário controlado (MeSH)
`"Cerebrovascular Disorders"[MeSH]`, `"Stroke"[MeSH]`, `"Brain Ischemia"[MeSH]`,
`"Cerebral Hemorrhage"[MeSH]`, `"Subarachnoid Hemorrhage"[MeSH]`,
`"Intracranial Hemorrhages"[MeSH]`, `"Brain Infarction"[MeSH]`,
`"Intracranial Arteriosclerosis"[MeSH]`, `"Carotid Stenosis"[MeSH]`,
`"Vasospasm, Intracranial"[MeSH]`

### Texto livre
`stroke*`, `cerebrovascular`, `"cerebral infarction"`, `"intracerebral h?emorrhage"`,
`"subarachnoid h?emorrhage"`, `"brain isch?emia"`, `"cerebral h?emorrhage"`,
`"cerebrovascular accident"`, `"ICD-10 I6"`, `"I60"`–`"I69"`

> **Fundamentação:** os termos refletem a definição da CID-10 [Ref. 35] e a taxonomia
> usada pelo GBD 2019 para AVC [Ref. 31]. A inclusão de termos amplos ("stroke",
> "cerebrovascular") evita perda de sensibilidade, dado que muitos estudos ambientais não
> indexam subtipos específicos.

---

## Bloco 2 — Exposição ambiental

### Clima / temperatura
MeSH: `"Weather"[MeSH]`, `"Climate"[MeSH]`, `"Climate Change"[MeSH]`,
`"Hot Temperature"[MeSH]`, `"Cold Temperature"[MeSH]`, `"Temperature"[MeSH]`,
`"Humidity"[MeSH]`, `"Extreme Weather"[MeSH]`, `"Heat Stress Disorders"[MeSH]`
Texto livre: `temperature`, `climate`, `humidity`, `"heat wave*"`, `"cold spell*"`,
`"extreme heat"`, `"extreme cold"`, `"diurnal temperature"`, `"heat index"`

> **Fundamentação:** uso de MeSH térmicos + definições operacionais de onda de calor
> (Perkins & Alexander, 2013 [Ref. 28]; OMM, 2018 [Ref. 29]) e modelos de defasagem
> distribuída para exposições agudas (Gasparrini, 2011; Gasparrini et al., 2015
> [Refs. 26–27]).

### Poluição do ar
MeSH: `"Air Pollution"[MeSH]`, `"Particulate Matter"[MeSH]`, `"Air Pollutants"[MeSH]`,
`"Ozone"[MeSH]`, `"Nitrogen Dioxide"[MeSH]`, `"Sulfur Dioxide"[MeSH]`,
`"Carbon Monoxide"[MeSH]`, `"Environmental Exposure"[MeSH]`
Texto livre: `"air pollution"`, `PM2.5`, `PM10`, `"fine particulate"`, `ozone`,
`"nitrogen dioxide"`, `"sulfur dioxide"`, `"carbon monoxide"`, `"black carbon"`

> **Fundamentação:** poluentes críticos segundo as diretrizes da OMS (WHO, 2021 [Ref. 30]).

### Água, solo, ruído, saneamento
MeSH: `"Water Pollution"[MeSH]`, `"Soil Pollutants"[MeSH]`, `"Noise"[MeSH]`,
`"Sanitation"[MeSH]`, `"Drinking Water"[MeSH]`, `"Water Supply"[MeSH]`
Texto livre: `sanitation`, `"drinking water"`, `"water quality"`, `"soil contamination"`,
`noise`, `"environmental noise"`, `"heavy metals"`, `pesticide*`

### Moradia / combustíveis sólidos
MeSH: `"Housing"[MeSH]`, `"Air Pollution, Indoor"[MeSH]`, `"Cooking"[MeSH]`,
`"Biomass"[MeSH]`, `"Environmental Health"[MeSH]`
Texto livre: `"solid fuel*"`, `"indoor air"`, `"household air pollution"`, `biomass`,
`"cooking fuel*"`, `"heating fuel*"`, `"housing quality"`, `overcrowding`

> **Fundamentação:** a OMS inclui poluição do ar doméstico entre os principais riscos
> ambientais (WHO, 2016 [Ref. 33]; Prüss-Ustün et al.).

### Catástrofes naturais
MeSH: `"Natural Disasters"[MeSH]`, `"Floods"[MeSH]`, `"Fires"[MeSH]`,
`"Cyclonic Storms"[MeSH]`, `"Earthquakes"[MeSH]`
Texto livre: `flood*`, `wildfire*`, `"forest fire*"`, `landslide*`, `hurricane*`,
`typhoon*`, `earthquake*`, `tsunami*`, `drought*`

### Ambiente construído
MeSH: `"Built Environment"[MeSH]`, `"City Planning"[MeSH]`, `"Urbanization"[MeSH]`,
`"Environment Design"[MeSH]`, `"Parks, Recreational"[MeSH]`, `"Residence Characteristics"[MeSH]`
Texto livre: `"built environment"`, `"heat island*"`, `"green space*"`, `"greenness"`,
`"urban design"`, `walkability`, `"land use"`

### Ocupacional de natureza ambiental
MeSH: `"Occupational Exposure"[MeSH]`, `"Occupational Diseases"[MeSH]`
Texto livre: `"occupational heat"`, `"occupational exposure"`, `"ambient dust"`

> **Fundamentação:** inclusão de exposições ocupacionais de natureza ambiental conforme
> o escopo do PICO; a OIT/OMS e a Comissão Lancet sobre poluição e saúde reforçam essa
> interface (Landrigan et al., 2018 [Ref. 34]).

---

## Strings completas por base

### PubMed / MEDLINE

```
("Cerebrovascular Disorders"[MeSH] OR "Stroke"[MeSH] OR "Brain Ischemia"[MeSH] OR
 "Cerebral Hemorrhage"[MeSH] OR "Subarachnoid Hemorrhage"[MeSH] OR
 "Intracranial Hemorrhages"[MeSH] OR "Brain Infarction"[MeSH] OR
 "Intracranial Arteriosclerosis"[MeSH] OR "Carotid Stenosis"[MeSH] OR
 "Vasospasm, Intracranial"[MeSH] OR stroke*[tiab] OR cerebrovascular[tiab] OR
 "cerebral infarction"[tiab] OR "intracerebral h?emorrhage"[tiab] OR
 "subarachnoid h?emorrhage"[tiab] OR "cerebral h?emorrhage"[tiab] OR
 "brain isch?emia"[tiab] OR "cerebrovascular accident"[tiab] OR "I60"[tiab] OR
 "I61"[tiab] OR "I62"[tiab] OR "I63"[tiab] OR "I64"[tiab] OR "I69"[tiab])
AND
("Weather"[MeSH] OR "Climate"[MeSH] OR "Climate Change"[MeSH] OR
 "Hot Temperature"[MeSH] OR "Cold Temperature"[MeSH] OR "Temperature"[MeSH] OR
 "Humidity"[MeSH] OR "Extreme Weather"[MeSH] OR "Heat Stress Disorders"[MeSH] OR
 "Air Pollution"[MeSH] OR "Particulate Matter"[MeSH] OR "Air Pollutants"[MeSH] OR
 "Ozone"[MeSH] OR "Nitrogen Dioxide"[MeSH] OR "Environmental Exposure"[MeSH] OR
 "Environmental Pollutants"[MeSH] OR "Water Pollution"[MeSH] OR "Sanitation"[MeSH] OR
 "Drinking Water"[MeSH] OR "Water Supply"[MeSH] OR "Soil Pollutants"[MeSH] OR
 "Noise"[MeSH] OR "Housing"[MeSH] OR "Air Pollution, Indoor"[MeSH] OR "Biomass"[MeSH] OR
 "Natural Disasters"[MeSH] OR "Floods"[MeSH] OR "Fires"[MeSH] OR "Cyclonic Storms"[MeSH] OR
 "Built Environment"[MeSH] OR "City Planning"[MeSH] OR "Urbanization"[MeSH] OR
 "Parks, Recreational"[MeSH] OR "Occupational Exposure"[MeSH] OR
 temperature[tiab] OR climate[tiab] OR humidity[tiab] OR "heat wave*"[tiab] OR
 "cold spell*"[tiab] OR "air pollution"[tiab] OR "PM2.5"[tiab] OR "PM10"[tiab] OR
 ozone[tiab] OR "nitrogen dioxide"[tiab] OR "particulate matter"[tiab] OR
 sanitation[tiab] OR "drinking water"[tiab] OR "solid fuel*"[tiab] OR
 "indoor air"[tiab] OR "heat island*"[tiab] OR flood*[tiab] OR wildfire*[tiab] OR
 "green space*"[tiab] OR "built environment"[tiab] OR noise[tiab])
```

Filtros: `("2020/01/01"[Date - Publication] : "2026/09/30"[Date - Publication])`
e `(english[Language] OR portuguese[Language] OR spanish[Language])`.

### Scopus

```
TITLE-ABS-KEY( (stroke OR cerebrovascular OR "cerebral infarction" OR
  "intracerebral h?emorrhage" OR "subarachnoid h?emorrhage" OR "brain isch?emia" OR
  "I60" OR "I61" OR "I63" OR "I64" OR "I69") 
 AND (temperature OR climate OR "heat wave*" OR "cold spell*" OR humidity OR
  "air pollution" OR "PM2.5" OR "PM10" OR ozone OR "nitrogen dioxide" OR
  "particulate matter" OR sanitation OR "drinking water" OR "solid fuel*" OR
  "indoor air" OR "heat island*" OR flood* OR wildfire* OR "green space*" OR
  "built environment" OR noise OR "occupational exposure") )
AND PUBYEAR > 2019 AND PUBYEAR < 2027
AND (LIMIT-TO(LANGUAGE,"English") OR LIMIT-TO(LANGUAGE,"Portuguese") OR
     LIMIT-TO(LANGUAGE,"Spanish"))
```

### SciELO

A SciELO indexa revistas de acesso aberto da América Latina, Caribe, Espanha e Portugal,
com forte cobertura em saúde nos idiomas português e espanhol. O endpoint de busca usa um
"bot-shield" que bloqueia requisições simples; a coleta é feita por **web scraping com
navegador headless** (Google Chrome/Edge), executando o JavaScript e extraindo o DOM
renderizado — implementação em `01_scripts/00_pipeline_revisao_sistematica.R (seção 5)`.

```
(stroke OR cerebrovascular OR "cerebral infarction" OR "intracerebral hemorrhage" OR
 "subarachnoid hemorrhage" OR "brain ischemia") AND
(temperature OR climate OR "heat wave" OR "cold spell" OR humidity OR "air pollution" OR
 "PM2.5" OR "PM10" OR ozone OR "nitrogen dioxide" OR "particulate matter" OR
 sanitation OR "drinking water" OR "solid fuel" OR "indoor air" OR "heat island" OR
 flood OR wildfire OR "green space" OR "built environment" OR noise OR
 "occupational exposure")
```

Filtros: ano 2020–2026; idiomas PT/EN/ES. A paginação é adaptativa (incrementa pelo
número real de itens retornados por página).

---

## Bases de dados do projeto

Este projeto utiliza **três bases**: **PubMed/MEDLINE**, **Scopus** e **SciELO**.

---

## Registro das buscas

Cada execução registra em `02_dados/brutos/`:
- a string exata (`*_query.txt`);
- a data/hora e o número de registros (`*_count.csv`);
- o arquivo normalizado (`*_records.csv`).

Tabela consolidada de hits: `03_resultados/tabelas/prisma_contagens.csv`.
