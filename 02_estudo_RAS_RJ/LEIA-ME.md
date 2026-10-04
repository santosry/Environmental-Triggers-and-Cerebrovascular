# LEIA-ME (atalho) — Frente 02

> 📖 A documentação completa desta frente está em **[`README.md`](README.md)**.
> Este arquivo mantém apenas um atalho e a ordem de execução mais usada.

**Projeto:** Morbimortalidade cerebrovascular e RAS no Rio de
Janeiro — estudo ecológico 2010–2024 com GLMM logístico multinível da mortalidade
intra-hospitalar. Última atualização: 3 de outubro de 2026.

## Cadeia de execução (na raiz desta frente)

```powershell
$R = "C:\Program Files\R\R-4.6.1\bin\Rscript.exe"

& $R "02_scripts\01_baixar_microdatasus.R"   # aquisicao (~38 min)
& $R "02_scripts\02_montar_coorte.R"         # coorte analitica
& $R "02_scripts\03_tabelas_descritivas.R"
& $R "02_scripts\04_isu_regiao_saude.R"      # Swaroop-Uemura
& $R "02_scripts\05_glmm_principal.R"        # GLMM + FDR (~3 min)
& $R "02_scripts\06_glmm_uti.R"              # tratamento da UTI (Mundlak)
& $R "02_scripts\07_auditoria_consistencia.R"
& $R "02_scripts\12_auditoria_geral.R"         # auditoria do repositorio
& $R "02_scripts\08_glmm_robustez.R"         # 18 cenarios (~40 min)
& $R "02_scripts\09_conferencia_motores.R"   # glmmTMB x lme4 (processo isolado)
& $R "02_scripts\10_figuras.R"
& $R "02_scripts\11_exploratorio.R"         # raca/cor, comorbidade, natureza juridica
& $R "02_scripts\13_figuras_exploratorias.R" # banco de ~25 figuras
& $R "02_scripts\14_verificacao_sidra.R"     # denominadores IBGE/SIDRA
& $R "02_scripts\15_deflacao_ipca.R"         # custos deflacionados a dez/2024
```

> 🎨 Todas as figuras usam a paleta **viridis** (uniforme, legível em cinza e segura para
> daltonismo).

## Referências rápidas

| Item | Caminho |
|---|---|
| Documentação completa | [`README.md`](README.md) |
| Relatório executivo | [`12_relatorios/RELATORIO_EXECUTIVO_FINAL.md`](12_relatorios/RELATORIO_EXECUTIVO_FINAL.md) |
| OR ajustados | [`05_tabelas/tab3_glmm_or.csv`](05_tabelas/tab3_glmm_or.csv) |
| Scripts | [`02_scripts/`](02_scripts/) |

> ⚠️ Carregar `glmmTMB` e `lme4` na mesma sessão R encerra o processo; a conferência
> entre motores roda em processo isolado (`09_conferencia_motores.R --worker`).

⬅️ [Voltar ao README do monorepo](../README.md)
