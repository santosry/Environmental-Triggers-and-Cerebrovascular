# Dicionário de variáveis

Os nomes “originais” devem ser confirmados no piloto e podem variar por ano. O pipeline preserva todas as colunas recebidas e acrescenta aliases padronizados.

No piloto SIH de janeiro de 2024, foram confirmados `ANO_CMPT`, `MES_CMPT`, `MUNIC_RES`, `MUNIC_MOV`, `SEXO`, `IDADE`, `RACA_COR`, `DIAG_PRINC`, `DIAG_SECUN`, `DIAGSEC1`–`DIAGSEC9`, `DIAS_PERM`, `VAL_TOT`, `CAR_INT`, `MORTE`, `N_AIH`, `DT_INTER` e `DT_SAIDA`, entre outras colunas preservadas.

| Base | Alias padronizado | Campo(s) esperado(s) após `microdatasus` | Uso |
|---|---|---|---|
| SIH | `ano`, `mes` | `ANO_CMPT`, `MES_CMPT` | competência |
| SIH | `municipio_residencia` | `MUNIC_RES` | residência, 6 dígitos |
| SIH | `municipio_internacao` | `MUNIC_MOV` ou `MUNICIPIO` | local da internação |
| SIH | `sexo` | `SEXO` | estratificação/qualidade |
| SIH | `idade_anos` | `IDADE` | idade informada |
| SIH | `raca_cor` | `RACA_COR` | raça/cor; avaliar completude |
| SIH | `diagnostico_principal` | `DIAG_PRINC` | definição principal I60–I69 |
| SIH | `diagnostico_secundario` | `DIAG_SECUN`/`DIAGSEC1` | auditoria, não seleção principal |
| SIH | `dias_permanencia` | `DIAS_PERM` | média/mediana e plausibilidade |
| SIH | `valor_internacao` | `VAL_TOT` | custo nominal faturado |
| SIH | `carater_atendimento` | `CAR_INT` | eletivo/urgência conforme rótulo |
| SIH | `obito_hospitalar` | `MORTE` | desfecho hospitalar |
| SIM | `data_obito`, `ano`, `mes` | `DTOBITO` | data/período do óbito |
| SIM | `municipio_residencia` | `CODMUNRES` | residência |
| SIM | `municipio_ocorrencia` | `CODMUNOCOR` | ocorrência |
| SIM | `sexo` | `SEXO` | estratificação/qualidade |
| SIM | `idade_anos` | `IDADEanos` derivada de `IDADE` | idade em anos |
| SIM | `raca_cor` | `RACACOR` | raça/cor |
| SIM | `escolaridade` | `ESC2010` ou `ESC` | escolaridade |
| SIM | `estado_civil` | `ESTCIV` | estado civil |
| SIM | `causa_basica` | `CAUSABAS` | definição principal I60–I69 |
| SIM | causas associadas | `LINHAA`–`LINHAD`, `LINHAII` | causas múltiplas preservadas |
| SIM | `local_ocorrencia` | `LOCOCOR` | local do óbito |
| População | `municipio`, `nome_municipio` | código IBGE de 6 dígitos e nome SIDRA | chave geográfica |
| População | `ano`, `populacao` | período e valor SIDRA | denominador validado |
| Derivada | `faixa_etaria` | `<1`, `1-19`, `20-39`, `40-59`, `60-79`, `80+` | estratificação descritiva |
| Derivada | `regiao_saude` | nove regiões da SES-RJ | agregação territorial por residência |
| Derivada | `taxa_100mil` | eventos / população × 100.000 | somente com denominador disponível |

O piloto gera os nomes observados e deve atualizar este documento caso algum alias não corresponda ao esquema real. Identificadores técnicos permanecem somente nos arquivos locais ignorados pelo Git.

Os valores de sexo, raça/cor, escolaridade e estado civil preservam a codificação
entregue pelo `microdatasus`; categorias ignoradas não são redistribuídas. Custos
do SIH são nominais e não corrigidos pela inflação.
