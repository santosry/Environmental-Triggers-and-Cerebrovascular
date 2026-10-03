# HANDOFF — Frente 02 (vulnerabilidade climática, RAS/RJ)

> Documento de continuidade. Escrito em **3 de outubro de 2026** para retomar o
> trabalho depois da sessão de aquisição + auditoria. Substitui o antigo
> `HANDOFF.md` citado como pendente no `README.md`.

---

## 1. O que foi pedido nesta sessão

1. Rodar uma **bateria de auditorias robustas** na pasta
   `02_vulnerabilidade_climatica_RAS_RJ/`.
2. Alterar `02_scripts/01_baixar_microdatasus.R` para que, **depois de baixar os
   `.rds`**, faça a **filtragem pelos CIDs do estudo** e grave um **CSV**, com o
   arquivo **versionado no repositório** (se já estivesse feito, ignorar).

---

## 2. O que foi feito

### 2.1 Filtragem por CID no script 01

`02_scripts/01_baixar_microdatasus.R` foi estendido com um bloco novo
(**“FILTRAGEM POR CID DO ESTUDO (CSV)”**), executado após os downloads e antes do
inventário. O bloco:

- Varre os `.rds` já baixados (não rebaixa nada existente) e produz dois recortes:
  - **SIH** (`DIAG_PRINC` em I60–I69, G45 ou G46), residentes no RJ (`MUNIC_RES`
    começando por `33`), `DT_INTER` entre 2010-01-01 e 2024-12-31.
  - **SIM** (`CAUSABAS` em I60–I69), `CODMUNRES` do RJ, `DTOBITO` entre 2010 e 2024.
- Mantém apenas colunas essenciais do estudo (o bruto completo de 113 colunas
  continua nos `.rds`, que são volumosos e não versionados).
- É idempotente: só regenera se o CSV não existir ou se algum `.rds` for mais
  novo que o CSV (`precisa_refazer()`).

**Saídas versionadas (novas):**

| Arquivo | Linhas | Colunas | Tamanho |
|---|---:|---:|---:|
| `01_dados/processados/sih_cid_estudo_2010_2024.csv` | 295.673 | 21 | ~37,4 MB |
| `01_dados/processados/sim_cid_estudo_2010_2024.csv` | 147.551 | 7 | ~6,4 MB |

Colunas do recorte SIH: `N_AIH, IDENT, DT_INTER, DT_SAIDA, DIAG_PRINC, MUNIC_RES,
MUNIC_MOV, SEXO, IDADE, COD_IDADE, CNES, MORTE, CAR_INT, RACA_COR, INSTRU,
UTI_MES_TO, MARCA_UTI, DIAS_PERM, VAL_TOT, COMPLEX, NAT_JUR`.

Colunas do recorte SIM: `DTOBITO, IDADE, SEXO, RACACOR, LOCOCOR, CODMUNRES, CAUSABAS`.

> ⚠️ `DTOBITO` e `DT_INTER` são strings numéricas no CSV. Ao reler com
> `data.table::fread`/pandas, **leia como caractere** para não perder zeros à
> esquerda (o `DTOBITO` é `DDMMYYYY`).

O `.gitignore` da frente recebeu as duas exceções (`!.../sih_cid_estudo...`,
`!.../sim_cid_estudo...`); sem elas, a regra `/01_dados/processados/*.csv`
bloquearia o versionamento.

### 2.2 Bateria de auditoria

Criado o script novo `02_scripts/12_auditoria_geral.R` (532 linhas), que audita o
que o `07_auditoria_consistencia.R` não cobre. Executados os **dois** scripts:

| Script | Foco | Resultado |
|---|---|---|
| `07_auditoria_consistencia.R` | bruto SIH/SIM, coorte, triangulação SIH×SIM, modelo/tabelas | **0 ERRO**, 12 ATENÇÃO (conhecidas), 38 OK |
| `12_auditoria_geral.R` | aquisição, recorte CID, artefatos, numérico, código, Git/LGPD | **0 ERRO**, 1 ATENÇÃO (esperada), 8 INFO, 75 OK |

Destaques do `12`:

- **Re-derivação independente** do recorte CID a partir dos 191 `.rds`: 11.947.354
  registros brutos relidos; recorte SIH = **295.673** e SIM = **147.551**, idênticos
  aos CSVs; zero linhas fora de CID/RJ/período; marginais por ano e por CID3
  conferidas (diferença 0).
- O recorte SIH **bate 1:1 com a coorte** `coorte_glmm_2010_2024.csv` (mesmos
  295.673 e 55.827 óbitos; 295.673 chaves localizadas, 0 não localizadas).
- Fórmulas conferidas: `or = exp(beta)`, `z = beta/ep`, `p` bicaudal, IC95%,
  FDR `BH`, ICC, MOR, calibração e ISU — todas OK.
- Afirmações-chave do `README.md` presentes (295.673; 55.827; 14,95%; 2,065;
  92,38%; 267.746; 27.927; 252.992).
- 15 scripts R e 4 Python **sem erro de sintaxe**; 0 caminhos absolutos e 0 `setwd`;
  10 pacotes exigidos, todos instalados.
- 97 arquivos versionados na frente, **nenhum campo identificável direto** em CSV,
  nenhum arquivo rastreado > 50 MB; `.rds` brutos continuam ignorados.

**Artefatos de auditoria gerados:**

- `10_auditoria/AUDITORIA_GERAL.md`
- `05_tabelas/tab26_auditoria_geral.csv`
- `04_resultados/resultados_auditoria_geral.txt`
- `04_resultados/auditoria_consistencia.txt` e `05_tabelas/tab19_auditoria.csv`
  (regerados pelo script 07)

A única ATENÇÃO do `12` é a ausência esperada de `sih_rd_rj_2025_12.rds`
(competência ainda não publicada no DATASUS).

---

## 3. Estado do Git (ponto exato para retomar)

Foram **preparados/commitados** (ver `git status`) apenas os arquivos desta tarefa:

- `02_scripts/01_baixar_microdatasus.R` (modificado)
- `02_scripts/12_auditoria_geral.R` (novo)
- os **dois CSVs** de recorte CID (novos)
- `.gitignore`, `README.md`, `LEIA-ME.md` (modificados)
- artefatos de auditoria listados acima

A frente já tinha **~30 arquivos modificados/não rastreados de sessões
anteriores** (scripts, resultados, figuras). Eles **não** foram mexidos nem
commitados nesta sessão — decidir depois se entram num commit próprio.

> Os `.rds` (~580 MB) e as bases pesadas de `01_dados/processados/`
> (`coorte_glmm_2010_2024.csv`, modelo, previsões) **permanecem fora do Git**
> por tamanho. Só os recortes CID são versionados.

---

## 4. Como reproduzir a sessão

```powershell
$R = "C:\Program Files\R\R-4.6.1\bin\Rscript.exe"

# 1. aquisição + filtragem CID (só rede para o que faltar; ~9 min, sendo ~4 min
#    tentando a competência 2025-12, que não existe)
& $R "02_scripts\01_baixar_microdatasus.R"

# 2. auditorias
& $R "02_scripts\07_auditoria_consistencia.R"   # ~10 min
& $R "02_scripts\12_auditoria_geral.R"          # ~6 min
```

Observações de ambiente:

- `Rscript.exe` está em `C:\Program Files\R\R-4.6.1\bin` e **não** está no PATH.
- Neste ambiente, chamadas curtas de `Rscript` **sem** `--vanilla` sofreram
  `segfault` intermitente; com `--vanilla` rodou estável. Os scripts foram
  executados com `--vanilla` durante a auditoria. Vale investigar o arquivo de
  sítio (`R_HOME/etc/Rprofile.site`) antes de considerar isso um problema do código.
- O script 01 gasta ~4 min tentando baixar `2025-12` a cada execução (4 tentativas
  × 20 s + timeouts). **Otimização pendente**: pular competências futuras/ausentes
  conhecidas sem tentar rede.

---

## 5. Pendências e próximos passos

1. **Commit/push**: confirmar se o commit escopado desta sessão deve ser feito e
   enviado ao remoto (`origin/main` =
   `santosry/Environmental-Triggers-and-Cerebrovascular`).
2. **Commit dos ~30 arquivos anteriores**: separar em um commit coerente
   (scripts 02–11 e resultados) ou descartar o que for obsoleto.
3. **Otimizar o script 01**: evitar a tentativa de rede para `2025-12`.
4. **`HANDOFF.md`**: este arquivo repõe a pendência 1 do `README.md`. Ainda falta
   o `PLANO_METODOLOGICO_GLMM_COX.md` (pendência 2) ou atualizar o README para
   assumir que o plano foi absorvido.
5. **Arquivos legados volumosos ainda no disco** (não versionados):
   `sih_cerebrovascular_2010_2024.csv` (~172 MB) e `sih_g45_g46_2010_2024.csv`
   (~8,8 MB) em `01_dados/processados/`. Avaliar remoção ou marcar como legado.
6. **Decisão da UTI no modelo principal** (mantida como marcador de gravidade;
   retirá-la eleva o ICC a ~17%) — ver pendência 3 do `README.md`.
7. **Mapa coroplético das 9 regiões** continua sem shapefile (pendência 4).

---

## 6. Números de referência (para conferência rápida)

| Indicador | Valor |
|---|---|
| Registros brutos SIH-RD (191 competências) | 11.947.354 |
| Internações da coorte | 295.673 |
| Óbitos intra-hospitalares | 55.827 (18,88%) |
| Óbitos I60–I69 no SIM (RJ, 2010–2024) | 147.551 |
| Estabelecimentos / regiões | 254 / 9 |
| ICC hospitalar / MOR | 14,95% / 2,065 |
| ISU estadual por DCV | 92,38% |
| Cenários de robustez convergidos | 18 de 18 |

---

## 7. Arquivos-chave desta sessão

| Item | Caminho |
|---|---|
| Script de aquisição + filtro CID | `02_scripts/01_baixar_microdatasus.R` |
| Script de auditoria geral | `02_scripts/12_auditoria_geral.R` |
| Auditoria de consistência (pré-existente) | `02_scripts/07_auditoria_consistencia.R` |
| Relatório de auditoria geral | `10_auditoria/AUDITORIA_GERAL.md` |
| Log da auditoria geral | `04_resultados/resultados_auditoria_geral.txt` |
| Tabela consolidada da auditoria | `05_tabelas/tab26_auditoria_geral.csv` |
| Recorte SIH versionado | `01_dados/processados/sih_cid_estudo_2010_2024.csv` |
| Recorte SIM versionado | `01_dados/processados/sim_cid_estudo_2010_2024.csv` |

⬅️ [Voltar ao README](README.md)
