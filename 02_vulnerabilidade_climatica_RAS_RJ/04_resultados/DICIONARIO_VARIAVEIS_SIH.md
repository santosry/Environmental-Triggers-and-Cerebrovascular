# DICIONÁRIO DE VARIÁVEIS — SIH-RD (e SIM)

Inventário das variáveis utilizadas/avaliadas na nova fase. Os nomes seguem o
layout oficial do SIH-RD (DATASUS, "AIH reduzida") e do SIM (declaração de óbito).
O inventário automático por arquivo está em
`01_dados/inventario_colunas/sih_colunas_por_arquivo.json`.

> **Atenção (auditoria longitudinal):** o esquema do SIH-RD **não é estável** no
> tempo — 87 colunas em 2010, 96 em 2013 e 114 em 2024. Variáveis adicionadas ao
> longo dos anos (ex.: `NAT_JUR`, `AUD_JUST`, `SIS_JUST`, `VAL_UCI`, `VAL_SH_FED`,
> `VAL_SP_FED`) **não existem em todos os anos** e foram tratadas como ausentes nos
> anos iniciais.

## SIH-RD — variáveis utilizadas na nova fase

| Nome técnico | Descrição | Tipo | Anos disponíveis | Completude | Categorias/observações | Utilidade |
|---|---|---|---|---|---|---|
| `DIAG_PRINC` | Diagnóstico principal (CID-10) | texto | todos | ~100% | I60–I69 (capítulo DCV); 4 dígitos | Desfecho principal / subtipo |
| `DIAG_SECUN` | Diagnóstico secundário | texto | todos | variável | Comorbidades | Avaliar (não usado no estudo-base) |
| `MUNIC_RES` | Município de residência (6 díg.) | texto | todos | ~100% | Inicia com 33 (RJ) | Unidade territorial (numerador) |
| `MUNIC_MOV` | Município de internação | texto | todos | alta | 6 dígitos | Fluxo residência→internação; polo assistencial |
| `CNES` | Estabelecimento de saúde | texto | todos | alta | — | Concentração assistencial |
| `NATUREZA`/`NAT_JUR` | Natureza jurídica do estabelecimento | texto | NATUREZA: todos; NAT_JUR: 2013+ | média | 20/40/50/60/61… | Caracterização da oferta |
| `SEXO` | Sexo (SIH: 1=M, 3=F) | texto | todos | ~100% | recodificado M/F | Perfil |
| `IDADE` + `COD_IDADE` | Idade (SIH: anos, com unidade) | num | todos | ~100% | COD_IDADE: 1=h, 2=d, 3=m, 4=a | Perfil / faixa etária |
| `RACA_COR` | Raça/cor (SIH: 01–05, 99) | texto | todos | ~75% (25% "sem info.") | 01 branca…99 sem informação | Perfil (com cautela) |
| `INSTRU` | Escolaridade | texto | todos | ~99,6% com valor 0 | 0=sem instrução/não informado | **Excluir de inferência** |
| `CAR_INT` | Caráter da internação | texto | todos | alta | 01 eletiva, 02 urgência… | Perfil assistencial |
| `DT_INTER` / `DT_SAIDA` | Datas (AAAAMMDD) | texto | todos | ~100% | — | Período / permanência |
| `DIAS_PERM` | Dias de permanência | num | todos | ~100% | assimétrica | Desfecho assistencial |
| `MORTE` | Óbito hospitalar (0/1) | num | todos | ~100% | — | Desfecho (mortalidade hospitalar) |
| `VAL_TOT` | Valor total (reais correntes) | num | todos | ~100% (negativos = erro) | — | Custo |
| `VAL_SH` / `VAL_SP` | Valor serviços hospitalares / profissionais | num | todos | alta | — | Decomposição de custo |
| `VAL_UTI` / `UTI_MES_TO` | Valor UTI / dias UTI | num | todos | — | — | Complexidade |
| `PROC_REA` / `PROC_SOLIC` | Procedimento realizado/solicitado | texto | todos | alta | tabela SIGTAP | Não explorado no estudo-base |
| `COMPLEX` | Complexidade | texto | todos | média | — | Oferta assistencial |
| `FINANC` | Tipo de financiamento | texto | todos | média | — | Oferta assistencial |
| `N_AIH` + `IDENT` | Número AIH + identificador | texto | todos | ~100% | — | Chave de deduplicação |

## Variáveis problemáticas (auditadas)

| Variável | Problema | Decisão |
|---|---|---|
| `INSTRU` | ~99,6% com valor 0 (não informativo) | Documentar; excluir de inferência |
| `RACA_COR` | ~25% "sem informação" | Apresentar incompletude; não inferir desigualdade sem cautela |
| `AUD_JUST`/`SIS_JUST`/`CID_NOTIF` | Texto livre com codificação não-UTF-8 | Não utilizados nas análises |
| `VAL_TOT` negativo | Erros de entrada | Excluir da análise financeira |

## SIM — variáveis utilizadas

| Nome | Descrição | Observação |
|---|---|---|
| `CAUSABAS` | Causa básica (CID-10) | I60–I69; 4 dígitos |
| `LINHAA`–`LINHAD`/`LINHAII` | Causas múltiplas | Avaliar uso (não no estudo-base) |
| `DTOBITO` | Data do óbito | DDMMAAAA |
| `CODMUNRES` | Município de residência | 6 dígitos (33…) |
| `CODMUNOCOR` | Município de ocorrência | Fluxo do óbito |
| `LOCOCOR` | Local de ocorrência | 1 hospital…3 domicílio…9 ignorado |
| `IDADE` | Idade (DATASUS 3 díg.) | 4xx=anos, 3xx=meses, 2xx=horas, 1xx=min; 999=ignorada |
| `SEXO` | Sexo (1=M, 2=F) | 0/9→ignorado |
| `RACACOR` | Raça/cor | 1–5, 9 ignorado |
| `ESC` | Escolaridade | 1–5, 9 ignorado |
| `TIPOBITO` | Tipo de óbito | — |

## Observação sobre a idade no SIM (correção aplicada)

O campo `IDADE` do SIM usa centena = unidade de tempo. A conversão correta:
`4xx` = xx anos; `5xx` = 100+xx anos; `3xx` = meses; `2xx` = horas; `1xx` = minutos.
O estudo-base (texto DLNM) citava "228 = 28 anos" — **incorreto** (228 = 28 horas).
A nova fase aplica a conversão correta e exclui `999` (ignorada).
