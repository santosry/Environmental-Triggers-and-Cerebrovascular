# Dicionário de dados — extração e síntese

Define cada variável coletada dos estudos, sua unidade/categorias e a fundamentação.
Base do formulário `02_dados/extraidos/planilha_extracao.csv` (template gerado por
`01_scripts/00_pipeline_revisao_sistematica.R (seção 13)`). Segue a recomendação da Cochrane (Higgins JPT, et al.,
2019) e o PRISMA 2020, itens 10a–b e 17.

## 1. Identificação do estudo

| Variável | Descrição | Categorias/unidade |
|---|---|---|
| `id_estudo` | Identificador único | texto |
| `autor_ano` | Primeiro autor + ano | texto |
| `doi` | DOI | texto |
| `titulo` | Título | texto |
| `pais` | País do estudo | texto |
| `regiao_oms` | Região OMS | África, Américas, Mediterrâneo Oriental, Europa, Sudeste Asiático, Pacífico Ocidental |
| `renda_pais` | Classificação do Banco Mundial | alta, média-alta, média-baixa, baixa |
| `desenho` | Delineamento | coorte, caso_controle, caso_cruzado, serie_temporal, ecologico, transversal_analitico, quase_experimental, modelagem_validada |
| `periodo_inicio`, `periodo_fim` | Período de coleta | ano |
| `n_participantes` | Tamanho da amostra | contagem |

## 2. População

| Variável | Descrição | Unidade |
|---|---|---|
| `idade_media` | Idade média | anos |
| `idade_min`, `idade_max` | Extremos de idade | anos |
| `faixa_etaria` | Estrato | crianças (<18), adultos (18–64), idosos (65+), todas |
| `prop_masculino` | Proporção do sexo masculino | 0–1 |

## 3. Exposição

| Variável | Descrição | Categorias/unidade |
|---|---|---|
| `categoria_exposicao` | Categoria conforme PICO | temperatura, poluicao_ar, agua_solo_ruido, saneamento, moradia_combustivel, catastrofe, ambiente_construido, ocupacional |
| `exposicao_descricao` | Descrição operacional | texto |
| `metrica_exposicao` | Métrica | média diária, percentil, extremo, concentração anual, binária |
| `incremento_exposicao` | Incremento analisado | número (ex.: 1 °C; 10 µg/m³) |
| `unidade_exposicao` | Unidade | °C, µg/m³, ppb, índice, binário |
| `exposicao_aguda_cronica` | Natureza temporal | aguda, crônica, ambas |
| `metodo_avaliacao_exposicao` | Como a exposição foi medida | monitor, modelo, satélite, proxy |

> **Fundamentação:** exposições agudas (p. ex., temperatura diária) e crônicas
> (p. ex., poluição anual) têm mecanismos e escalas temporais distintos e não devem ser
> agrupadas indiscriminadamente (Gasparrini et al., 2015; WHO, 2021).

## 4. Comparador

| Variável | Descrição |
|---|---|
| `comparador_descricao` | Definição do grupo/estrato de referência (ex.: percentil 1–50; dia não extremo) |

## 5. Desfecho (CID-10 I60–I69)

| Variável | Descrição | Categorias |
|---|---|---|
| `desfecho_cid` | Código(s) CID-10 | I60–I69 |
| `desfecho_descricao` | Descrição | texto |
| `tipo_desfecho` | Subtipo agregado | I60, I61, I62, I63, I64, I65_I66, I67, I68, I69, I60_I69 (todos) |

**Definições (WHO, *ICD-10*, 1992):**

| Código | Descrição |
|---|---|
| I60 | Hemorragia subaracnóidea |
| I61 | Hemorragia intracerebral |
| I62 | Outras hemorragias intracranianas não traumáticas |
| I63 | Infarto cerebral |
| I64 | AVC não especificado como hemorrágico ou isquêmico |
| I65 | Oclusão e estenose de artérias pré-cerebrais, não causando infarto cerebral |
| I66 | Oclusão e estenose de artérias cerebrais, não causando infarto cerebral |
| I67 | Outras doenças cerebrovasculares |
| I68 | Transtornos cerebrovasculares em doenças classificadas em outra parte |
| I69 | Sequelas de doenças cerebrovasculares |

## 6. Medida de efeito

| Variável | Descrição | Unidade |
|---|---|---|
| `medida_efeito` | Tipo de medida | RR, OR, HR |
| `efeito` | Estimativa pontual | razão |
| `ic95_inf`, `ic95_sup` | Limites do IC 95% | razão |
| `se_reportado` | Erro-padrão, se reportado | log |
| `p_valor` | Valor de p | 0–1 |

**Cálculo:** `yi = log(efeito)` e
`vi = ((log(ic95_sup) − log(ic95_inf)) / (2·1,96))²` (Borenstein et al., 2021;
Viechtbauer, 2010). Alternativamente, a partir de tabelas 2×2, usa-se
`escalc(measure = "RR"|"OR")`.

## 7. Eventos (quando disponíveis)

| Variável | Descrição |
|---|---|
| `eventos_expostos`, `n_expostos` | Casos e total no grupo exposto |
| `eventos_nao_expostos`, `n_nao_expostos` | Casos e total no grupo não exposto |

## 8. Ajuste

| Variável | Descrição |
|---|---|
| `ajustado` | Estimativa ajustada? (sim/não) |
| `covariaveis_ajuste` | Lista de confundidores ajustados |
| `modelo_estatistico` | Modelo (Poisson, logística condicional, GAM, DLNM, etc.) |

## 9. Risco de viés (preenchido em `06_risco_de_vies.R`)

Domínios ROBINS-I (Sterne et al., 2016), julgamentos em
{Low, Moderate, Serious, Critical, No information}:
`robins_confundimento`, `robins_selecao`, `robins_classificacao_exposicao`,
`robins_desvio`, `robins_dados_faltantes`, `robins_desfecho`, `robins_relato`,
`robins_geral`.

## 10. Observações

`observacoes` — notas livres do extrator (ex.: dados estimados de figura via
`metaDigitise`; contato com autores).
