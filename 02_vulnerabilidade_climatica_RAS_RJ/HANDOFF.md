# HANDOFF — Frente 02 (vulnerabilidade climática, RAS/RJ)

> Documento de continuidade. Atualizado em **3 de outubro de 2026**. Repõe o
> `HANDOFF.md` citado como pendente no `README.md`.

---

## 1. O que já está pronto

### Sessão 1 — aquisição, recorte CID e auditoria

- `02_scripts/01_baixar_microdatasus.R` baixa SIH-RD (191 competências, 2010-01 a
  2025-11) e SIM-DO (2010–2024) e, **depois do download**, filtra os CIDs do estudo e
  grava dois recortes leves **versionados**:
  - `01_dados/processados/sih_cid_estudo_2010_2024.csv` — 295.673 linhas, 21 colunas,
    ~37 MB (I60–I69, G45 e G46; residentes no RJ; `DT_INTER` 2010–2024).
  - `01_dados/processados/sim_cid_estudo_2010_2024.csv` — 147.551 linhas, 7 colunas,
    ~6 MB (causa básica I60–I69; residentes no RJ; `DTOBITO` 2010–2024).
  - `DTOBITO`/`DT_INTER` são strings numéricas: reler como caractere para não perder
    zeros à esquerda.
- Bateria de auditoria: `07_auditoria_consistencia.R` (0 erro) e
  `12_auditoria_geral.R` (84 verificações: 75 OK, 1 ATENÇÃO esperada, 0 erro).

### Sessão 2 — reorganização, manuscrito e figuras

- **Scripts todos em `02_scripts/`** (a pasta `legado_fase_anterior/` foi eliminada):
  - `13_figuras_exploratorias.R` (novo) — banco de 25 figuras.
  - `14_verificacao_sidra.R` (novo, análise atual) — auditoria dos denominadores
    populacionais do IBGE/SIDRA.
  - `15_deflacao_ipca.R` (novo, análise atual) — deflação dos custos, agora em R sobre
    a coorte (`coorte_glmm_2010_2024.csv`), recorte I60–I69.
  - `16_consolidar_dados_legado.py`, `17_analises_territoriais_legado.py` e
    `18_mortalidade_sim_legado.py` (históricos, movidos e com caminhos corrigidos).
  - `04_auditoria_completa.R` (obsoleto) foi removido.
- **`06_figuras/` organizada em subpastas:**
  - `manuscrito/` — `figura1_taxa_internacao_letalidade.jpg` e
    `figura2_funnel_hospitais.jpg` (300 dpi, < 2 MB, requisitos do edital), além dos
    PNGs-base do GLMM.
  - `exploratorias/` — 25 figuras (`fig_ex01` … `fig_ex25`).
  - `suplementares/` — figuras antigas (ISU, UTI, exploratório, fig1–fig3).
  - Os scripts `04`, `06`, `10`, `11` e `17` foram apontados para as subpastas certas.
- **`08_manuscrito/manuscrito.md` reescrito** (ver seção 3).

---

## 2. Como reproduzir

```powershell
$R = "C:\Program Files\R\R-4.6.1\bin\Rscript.exe"   # não está no PATH

# 1. aquisicao + recortes CID (rede so para o que faltar; ~9 min, 4 min dos quais
#    tentando a competencia 2025-12, que nao existe)
& $R "02_scripts\01_baixar_microdatasus.R"

# 2. coorte, descritivas, ISU, GLMM
& $R "02_scripts\02_montar_coorte.R"
& $R "02_scripts\03_tabelas_descritivas.R"
& $R "02_scripts\04_isu_regiao_saude.R"
& $R "02_scripts\05_glmm_principal.R"
& $R "02_scripts\06_glmm_uti.R"

# 3. auditorias
& $R "02_scripts\07_auditoria_consistencia.R"
& $R "02_scripts\12_auditoria_geral.R"

# 4. robustez e conferencia de motores
& $R "02_scripts\08_glmm_robustez.R"
& $R "02_scripts\09_conferencia_motores.R"

# 5. figuras e analises correntes
& $R "02_scripts\10_figuras.R"
& $R "02_scripts\11_exploratorio.R"
& $R "02_scripts\13_figuras_exploratorias.R"
& $R "02_scripts\14_verificacao_sidra.R"
& $R "02_scripts\15_deflacao_ipca.R"

# 6. tabelas historicas de tendencia/mortalidade
python "02_scripts\16_consolidar_dados_legado.py"
python "02_scripts\18_mortalidade_sim_legado.py"
python "02_scripts\17_analises_territoriais_legado.py"
```

Observações de ambiente:

- `Rscript.exe` em `C:\Program Files\R\R-4.6.1\bin`; usar `--vanilla` para evitar
  `segfault` intermitente observado com `-e` sem `--vanilla`.
- O script 01 gasta ~4 min tentando baixar `2025-12` a cada execução (pendência de
  otimização: pular competências futuras conhecidas sem tentar rede).

---

## 3. Manuscrito (Edital nº 02/2026)

O manuscrito foi reescrito no estilo de **interpretação científica aplicada em
linguagem simples**: apresenta o achado quantitativo, traduz o número, compara modelos,
explica a implicação e termina com a cautela metodológica. Exemplo do tratamento dado
ao achado central:

> “Cerca de **14,95% de toda a variação na chance de morrer** entre pacientes internados
> por DCV está relacionada a diferenças entre os hospitais, e não a características
> individuais. […] Quando o uso de UTI é retirado, o ICC sobe para 17,25%; quando a UTI
> entra, cai para 14,95%. […] Como um quarto dessa diferença é explicado por natureza
> jurídica e complexidade e três quartos permanecem sem explicação, […]. A cautela: o
> ICC deve ser lido como faixa (14,78% a 17,25%).”

Conformidade checada com o edital:

| Item do edital | Situação |
|---|---|
| Título ≤ 150 caracteres | 118 caracteres (PT); EN e ES traduzidos |
| Resumo estruturado ≤ 250 palavras | PT 244 · EN 240 · ES 249 |
| Palavras-chave (3–6, DeCS) | 6 por idioma |
| Eixos temáticos | 1 (Planejamento) e 3 (Regionalização/RAS) |
| 10–15 páginas de texto | ~14 páginas |
| Até 40 referências | 13 (Vancouver) |
| ≤ 5 tabelas + figuras | 3 tabelas + 2 figuras |
| Figuras `.jpg`, ≥300 dpi, ≤2 MB | `figura1` e `figura2` geradas a 300 dpi, < 0,4 MB |

**Seleção de tabelas/figuras do manuscrito:** Tabela 1 (perfil por macrorregião),
Tabela 2 (OR ajustados), Tabela 3 (efeito dos blocos sobre o ICC), Figura 1 (taxa de
internação e letalidade) e Figura 2 (funil hospitalar).

O banco de 25 figuras exploratórias consta no material suplementar
(`06_figuras/exploratorias/`), pronto para substituir qualquer seleção.

---

## 4. Números de referência

| Indicador | Valor |
|---|---|
| Registros brutos SIH-RD (191 competências) | 11.947.354 |
| Internações da coorte | 295.673 |
| Óbitos intra-hospitalares | 55.827 (18,88%) |
| Óbitos I60–I69 no SIM | 147.551 |
| Estabelecimentos / regiões | 254 / 9 |
| VPC/ICC / MOR | 14,95% (12,29–18,06) / 2,065 |
| Faixa do ICC (com/sem UTI) | 14,78% a 17,25% |
| Variância hospitalar explicada (M4) | 25,7% |
| Funil: 102 ingênuos → 3 ajustados | 206 avaliáveis |
| AUC condicional / marginal | 0,740 / 0,690 |
| Taxa de internação 2010 → 2024 | 94,76 → 125,97/100.000 |
| Mortalidade populacional 2010 → 2024 | 65,66 → 58,33/100.000 |
| Custo total corrente / deflacionado (dez/2024) | R$ 535,1 mi / R$ 790,6 mi |
| ISU estadual | 92,38% |

> **Nota:** a deflação agora roda em `15_deflacao_ipca.R` sobre a coorte. Os totais
> ficaram R$ 535.140.920 (corrente) e R$ 790.617.014 (dez/2024) — diferença de 0,015%
> em relação ao cálculo histórico, por redistribuição de ~10 registros entre regiões.
> O manuscrito usa valores arredondados (“cerca de R$ 535 milhões / R$ 790,6 milhões”).

---

## 5. Estado do Git

- Sessão 1 foi **commitada** (`16c955c`): recortes CID versionados, `12_auditoria_geral.R`,
  docs e artefatos de auditoria.
- Sessão 2 (reorganização dos scripts, manuscrito, 25 figuras, JPGs, docs) foi
  preparada e **pendente de commit** no momento da escrita deste handoff.
- Os `.rds` (~580 MB) e bases pesadas de `01_dados/processados/` continuam fora do Git.
- A frente ainda carrega outros arquivos modificados de sessões anteriores (scripts
  02–11 e resultados); decidir se entram em um commit próprio.

---

## 6. Pendências e próximos passos

1. **Revisar o manuscrito** com leitura clínica e, se possível, revisão ortográfica.
2. **Conferir os dois JPG** do manuscrito no Word e confirmar legendas/numeração finais.
3. **Decidir a seleção final** de figuras/tabelas (o banco tem 25; trocar é trivial).
4. **Otimizar o script 01** para não tentar baixar competências futuras.
5. **Commit/push** da sessão 2 e organização do commit dos arquivos anteriores.
6. **`PLANO_METODOLOGICO_GLMM_COX.md`** continua ausente; README e este handoff o
   substituem provisoriamente.
7. **Legados volumosos** (`sih_cerebrovascular_2010_2024.csv`, ~172 MB;
   `sih_g45_g46_2010_2024.csv`, ~8,8 MB) seguem no disco, não versionados — avaliar
   remoção.
8. **Mapa coroplético** das 9 regiões ainda sem shapefile.
9. **Declaração de software:** registrar R 4.6.1, `glmmTMB` 1.1.15.2, `microdatasus`
   2.5.0, IPCA/SIDRA 1737 e IBGE/SIDRA 6579.

---

## 7. Arquivos-chave

| Item | Caminho |
|---|---|
| Aquisição + filtro CID | `02_scripts/01_baixar_microdatasus.R` |
| Banco de figuras | `02_scripts/13_figuras_exploratorias.R` |
| Verificação SIDRA | `02_scripts/14_verificacao_sidra.R` |
| Deflação IPCA | `02_scripts/15_deflacao_ipca.R` |
| Auditoria geral | `02_scripts/12_auditoria_geral.R` |
| Manuscrito | `08_manuscrito/manuscrito.md` |
| Figuras do manuscrito | `06_figuras/manuscrito/` |
| Figuras exploratórias | `06_figuras/exploratorias/` |
| Recorte SIH / SIM versionado | `01_dados/processados/si{h,m}_cid_estudo_2010_2024.csv` |

⬅️ [Voltar ao README](README.md)
