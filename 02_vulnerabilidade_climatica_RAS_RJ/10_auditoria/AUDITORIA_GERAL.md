# AUDITORIA GERAL DO REPOSITORIO

**Data da execucao:** 2026-10-03 14:26:31
**Ambiente:** R version 4.6.1 (2026-06-24 ucrt)
**Script:** `02_scripts/12_auditoria_geral.R`

Complementa a auditoria de consistencia (`07_auditoria_consistencia.R`), cobrindo
aquisicao, recorte CID versionado, coerencia entre artefatos, tabelas, codigo e higiene do repositorio.

## Resumo

| Classificacao | Verificacoes |
|---|---:|
| ATENCAO | 1 |
| INFO | 8 |
| OK | 75 |

## Verificacoes que exigem atencao

### ATENCAO

- **1** | Competicoes SIH ausentes | `1` — sih_rd_rj_2025_12.rds

## Todas as verificacoes

| Bloco | Item | Valor | Classificacao | Nota |
|---|---|---|---|---|
| 1 | Competicoes SIH-RD presentes | 191 | OK | esperado 191 |
| 1 | Competicoes SIH ausentes | 1 | ATENCAO | sih_rd_rj_2025_12.rds |
| 1 | Arquivos SIM-DO presentes | 15 | OK | esperado 15 (2010-2024) |
| 1 | Anos do SIM ausentes | 0 | OK |  |
| 1 | Tamanho bruto SIH (MB) | 479.3 | INFO |  |
| 1 | Tamanho bruto SIM (MB) | 98.1 | INFO |  |
| 1 | Arquivos com tamanho zero | 0 | OK |  |
| 2 | Falhas de leitura dos .rds do SIH | 0 | OK |  |
| 2 | Registros brutos SIH relidos | 11947354 | OK | referencia: 11.947.354 |
| 2 | Registros do estudo nos brutos (antes de RJ/periodo) | 321911 | INFO |  |
| 2 | Recorte SIH versionado existe | sim | OK |  |
| 2 | Linhas no recorte SIH (CSV) | 295673 | OK | re-derivado: 295.673 |
| 2 | Recorte SIH bate com a re-derivacao | 295673 | OK |  |
| 2 | Linhas do recorte fora dos CIDs do estudo | 0 | OK |  |
| 2 | Linhas do recorte fora do RJ (MUNIC_RES) | 0 | OK |  |
| 2 | Linhas do recorte fora do periodo 2010-2024 | 0 | OK |  |
| 2 | N_AIH ausente no recorte | 0 | OK |  |
| 2 | Linhas integralmente duplicadas no recorte | 0 | OK | se >0, ha duplicacao exata no CSV |
| 2 | Diferenca de n por ano entre re-derivacao e CSV | 0 | OK |  |
| 2 | Diferenca de obitos por ano entre re-derivacao e CSV | 0 | OK |  |
| 2 | Diferenca de n por CID3 (re-derivacao x CSV) | 0 | OK |  |
| 2 | Todos os 12 CID3 do estudo presentes no recorte | 0 | OK | CID3 ausentes:  |
| 2 | Falhas de leitura dos .rds do SIM | 0 | OK |  |
| 2 | Recorte SIM versionado existe | sim | OK |  |
| 2 | Linhas no recorte SIM (CSV) | 147611 | OK | re-derivado: 147.611 |
| 2 | Recorte SIM bate com a re-derivacao | 147611 | OK |  |
| 2 | Linhas do recorte SIM fora de I60-I69 e G45/G46 | 0 | OK |  |
| 2 | Linhas do recorte SIM fora do RJ | 0 | OK |  |
| 2 | DTOBITO invalida no recorte SIM | 0 | OK |  |
| 2 | Diferenca de obitos por ano (SIM re-derivacao x CSV) | 0 | OK |  |
| 3 | Coorte analitica existe | sim | OK |  |
| 3 | Linhas na coorte | 295673 | OK |  |
| 3 | Obitos na coorte | 55827 | OK |  |
| 3 | Tamanho da coorte igual ao recorte SIH | 295673 | OK | ambos devem ter 295.673 |
| 3 | Obitos da coorte iguais aos do recorte SIH | 55827 | OK |  |
| 3 | Registros do recorte localizados na coorte por chave | 295673 | OK | nao localizados: 0 |
| 3 | tab1: soma das coortes = n da coorte | 295673 | OK |  |
| 3 | tab1: soma dos obitos = obitos da coorte | 55827 | OK |  |
| 3 | tab2: soma das internacoes por regiao | 295673 | OK |  |
| 3 | tab2: soma dos obitos por regiao | 55827 | OK |  |
| 3 | tab2: numero de regioes de saude | 9 | OK | esperado 9 |
| 4 | tab4: ICC = s2/(s2+pi^2/3) | 0.14945 | OK |  |
| 4 | tab4: MOR = exp(sqrt(2 s2) Phi^-1(0,75)) | 2.0652 | OK |  |
| 4 | tab3: or = exp(beta) | 5.33e-15 | OK |  |
| 4 | tab3: z = beta/ep | 1.14e-13 | OK |  |
| 4 | tab3: p bicaudal reproduzido | 1.44e-15 | OK |  |
| 4 | tab3: IC95% inferior = exp(beta-1,96*ep) | 7.55e-15 | OK |  |
| 4 | tab3: IC95% superior = exp(beta+1,96*ep) | 4.00e-15 | OK |  |
| 4 | tab3: q_bh >= p | 0 | OK |  |
| 4 | tab3: q_bh reproduz p.adjust(BH) | 5.55e-16 | OK |  |
| 4 | tab5: soma de n na calibracao (marginal) | 295673 | OK |  |
| 4 | tab5: soma de n na calibracao (condicional) | 295673 | OK |  |
| 4 | tab5: razao esperado/observado condicional proxima de 1 | 0.9999 | OK |  |
| 4 | tab6: soma regional = total estadual | 147611 | OK |  |
| 4 | tab6: ISU = 100*50+/total | 4.90e-03 | OK |  |
| 4 | tab6: total do ISU igual ao recorte SIM (I60-I69 + G45/G46) | 147611 | OK |  |
| 4 | tab8: S0 reproduz o modelo principal | 0.57805 | OK |  |
| 4 | tab8: todos os cenarios convergidos | 18 de 18 | OK |  |
| 4 | tab19: nenhuma verificacao classificada como ERRO | 0 | OK |  |
| 4 | README contem '295.673' | sim | OK |  |
| 4 | README contem '55.827' | sim | OK |  |
| 4 | README contem '14,95%' | sim | OK |  |
| 4 | README contem '2,065' | sim | OK |  |
| 4 | README contem '92,39%' | sim | OK |  |
| 4 | README contem '267.746' | sim | OK |  |
| 4 | README contem '27.927' | sim | OK |  |
| 4 | README contem '252.992' | sim | OK |  |
| 5 | Scripts R no diretorio de scripts | 20 | INFO |  |
| 5 | Scripts Python no diretorio de scripts | 4 | INFO |  |
| 5 | Scripts R com erro de sintaxe | 0 | OK |  |
| 5 | Scripts Python com erro de sintaxe | 0 | OK |  |
| 5 | Linhas de codigo R com caminho absoluto | 0 | OK |  |
| 5 | Ocorrencias de setwd() no codigo R | 0 | OK | quebra a portabilidade; usar normalizePath/caminho relativo |
| 5 | Pacotes R exigidos pelo codigo | 12 | INFO | data.table, ggplot2, jsonlite, lme4, microdatasus, patchwork, pROC, ragg, scales, splines, trend, viridisLite |
| 5 | Pacotes R exigidos e nao instalados | 0 | OK |  |
| 5 | Scripts do diretorio ausentes do README | 0 | OK |  |
| 6 | Arquivos versionados nesta frente | 167 | INFO |  |
| 6 | CSVs versionados com campo identificavel direto | 0 | OK |  |
| 6 | Arquivos versionados maiores que 50 MB | 0 | OK |  |
| 6 | Maior arquivo versionado (MB) | 37.36 | INFO |  |
| 6 | Recorte versionado e nao ignorado: sih_cid_estudo_2010_2024.csv | sim | OK |  |
| 6 | Recorte versionado e nao ignorado: sim_cid_estudo_2010_2024.csv | sim | OK |  |
| 6 | Microdados .rds brutos ignorados pelo Git | sim | OK |  |
| 6 | Arquivos .rds brutos rastreados no Git | 0 | OK |  |
