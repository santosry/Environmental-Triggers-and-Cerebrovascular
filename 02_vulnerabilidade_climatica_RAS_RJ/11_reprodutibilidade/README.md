# 11_reprodutibilidade — benchmarks, reprodutibilidade, portabilidade e auditabilidade

Esta pasta concentra a camada de engenharia do estudo (janela **2014–2024**), sem
alterar resultados: permite **executar**, **medir**, **verificar** e **auditar** o
pipeline.

## Benchmarks
- `run_all.R` executa o pipeline na ordem canônica, mede o tempo de cada etapa e grava
  `benchmarks_execucao.csv` (ordem, script, início, fim, segundos, status).
- Modos: tudo, `--rapido` (exclui etapas pesadas), `--somente=03,04,05` e `--continuar`.
- Referência de custo das etapas pesadas (medida nesta máquina): `02` ~3 min,
  `05` ~3 min, `06` ~12 min, `08` ~44 min, `11` ~22 min.

```bash
Rscript 11_reprodutibilidade/run_all.R --rapido
```

## Reprodutibilidade
- `versoes_ambiente.R` grava `versoes_pacotes_R.csv`, `sessionInfo.txt`,
  `versoes_python.csv`, `versao_python.txt` e `requirements.txt` (versões exatas).
- Determinismo: modelos ajustados por `glmmTMB`/`lme4` com sementes e controles
  explícitos nos scripts do pipeline; estatística descritiva e taxas são determinísticas.
- `11_reprodutibilidade/teste_regressao.R` recomputa valores-síntese
  (`golden_values.csv`) a partir dos artefatos correntes e compara com tolerância.
  Saída: `teste_regressao_resultado.csv`; código de saída 0 = todos passam.

## Portabilidade
- `Dockerfile` fixa o ambiente (R 4.6.1 + Python) a partir de `rocker/r-ver`, com as
  dependências de sistema de `sf`, `geobr`, `ragg` e `microdatasus`.
- `requirements.txt` fixa as versões Python.
- Os scripts detectam a raiz do projeto a partir do próprio caminho; `run_all.R` fixa o
  diretório de trabalho, permitindo execução de qualquer pasta.
- `.gitattributes` normaliza fins de linha (LF) e marca binários.

## Auditabilidade
- `manifest_sha256.R` grava `manifest_sha256.csv` com o SHA-256 de **entradas**, **código**
  e **saídas**, e `PROVENANCE.json` com o commit do Git, versões e data de geração.
- `verificar_manifest.R` recomputa os hashes e aponta `OK`, `DIVERGENTE` ou `AUSENTE`,
  retornando código de saída 1 em caso de divergência.
- As auditorias do estudo permanecem em `10_auditoria/` e `04_resultados/` (84 verificações
  gerais, 75 aprovadas, 1 ressalva esperada, nenhum erro) e o diagnóstico científico em
  `10_auditoria/AUDITORIA_REVISAO_CIENTIFICA.md`.
- `CITATION.cff` fornece metadados de citação.

## Fluxo sugerido

```bash
# 1. ambiente
Rscript 11_reprodutibilidade/versoes_ambiente.R

# 2. pipeline (com benchmark)
Rscript 11_reprodutibilidade/run_all.R --rapido     # ou sem --rapido

# 3. verificação
Rscript 11_reprodutibilidade/teste_regressao.R      # golden values
Rscript 11_reprodutibilidade/manifest_sha256.R      # grava manifesto
Rscript 11_reprodutibilidade/verificar_manifest.R   # confere hashes
```

## Artefatos versionados
`benchmarks_execucao.csv`, `manifest_sha256.csv`, `PROVENANCE.json`,
`golden_values.csv`, `teste_regressao_resultado.csv`, `versoes_pacotes_R.csv`,
`sessionInfo.txt`, `versoes_python.csv`, `requirements.txt`.
