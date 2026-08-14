# Changelog

## 2026-07-17 — artigo completo em DOCX, data lock e publicação no GitHub

- Repositório publicado em https://github.com/santosry/cerebrovascular-diseases-rj-2010-25
  (etiqueta data-lock-2026-07-17).
- O artigo acadêmico completo foi reescrito como DOCX nativo
  (`artigo_morbimortalidade_avc_rbn_2026.docx`) com linguagem 100%
  acadêmica, incorporando os 292.952 registros SIH (2010–2025) e os
  147.551 registros SIM (2010–2024), dez figuras, três tabelas e 21
  referências em estilo Vancouver.
- `analysis/artigo.Rmd` foi removido; seu conteúdo foi transferido para
  o manuscrito DOCX e o script 11 foi atualizado para renderizar apenas
  `analises_robustas.Rmd`.
- O DOCX do artigo foi excluído do rastreamento Git (`.gitignore`) para
  publicação apenas do código e dos resultados.

## 2026-07-17 — denominador populacional de 2023

- Adicionada interpolação linear municipal de 2023 entre o Censo 2022 e a
  estimativa oficial de 2024, conforme decisão do pesquisador.
- O denominador interpolado é arredondado para pessoa inteira e identificado por
  `metodo = interpolacao_linear_2022_2024`; não é tratado como estimativa oficial.
- Taxas, tendências, mapas, relatórios e manuscrito foram regenerados com a nova
  série completa.

## 2026-07-17 — aplicação integral do RECORD–STROBE

- Reescrito o manuscrito reprodutível com título e resumos informativos, fontes,
  acesso, elegibilidade, algoritmos, limpeza, vieses, fluxo, resultados,
  generalização, disponibilidade e declarações exigidas.
- Preenchidos os 22 itens STROBE e as 13 extensões RECORD: 22 STROBE atendidos,
  10 RECORD aplicáveis atendidos e 3 RECORD de linkage não aplicáveis.
- Adicionados protocolo retrospectivo versionado, suplemento de métodos, matriz
  de vieses, fluxos reais separados e checklist executável.
- Corrigida uma expansão de cardinalidade no SIM causada pela associação da
  naturalidade no `microdatasus` 2.5.0; toda a série foi reprocessada e o total
  I60–I69 corrigido para 147.551.
- Delimitada a população principal do SIH a 292.952 internações de residentes;
  1.108 não residentes permanecem somente na auditoria.
- Identificados 292 registros SIM com município genérico 330000, mantidos nos
  totais estaduais e excluídos apenas de mapas, taxas e testes municipais.
- Gerados `manuscrito_RECORD.docx` e `manuscrito_RECORD.html`; o DOCX de 28
  páginas foi inspecionado visualmente integralmente e não apresentou cortes.

## 2026-07-17 — correção metodológica

- Removidas integralmente as análises que combinavam SIH e SIM por
  município-ano ou região-ano, incluindo correlações, defasagens, tabelas,
  funções, testes e figura. Essa integração foi considerada indefensável para o
  objetivo do estudo.
- SIH e SIM passam a ser tratados exclusivamente como fontes independentes.
- O checklist RECORD foi reauditado segundo a numeração oficial das 13 extensões
  ao STROBE; os itens RECORD 1.3, 6.3 e 12.3 foram classificados como não
  aplicáveis, com
  justificativa explícita de ausência de ligação entre bases.

Todas as mudanças relevantes neste projeto serão documentadas aqui.

### Adicionado em 0.2.0

- Artigo acadêmico completo e autônomo em DOCX (dez figuras, três tabelas,
  21 referências).
- Data lock documentado em `docs/data_lock_2026-07-17.md`.
- Etiqueta Git `data-lock-2026-07-17`.

## [0.1.0] - 2026-07-16

### Preservado

- Pasta original `DESCRITIVO AVC` sem alterações.
- Cópia integral criada em `DESCRITIVO AVC_backup_20260716-190300` antes da construção do novo projeto.
- `script.R`, manuscrito, texto extraído e protocolo RECORD originais preservados na origem e no backup.

### Adicionado

- Repositório científico modular em pasta separada.
- Configuração central CID-10 I60-I69, excluindo G45 da definição principal.
- Rotinas SIH mensais e SIM anuais com disponibilidade, retomada, tentativas, metadados e logs.
- Classificação explícita do SIM em definitivo, preliminar ou indisponível.
- Processamento, validação, auditoria, indicadores, séries, benchmarks e relatório reprodutível.
- Testes sintéticos, workflow de CI, licença MIT, citação e política de dados.
- Piloto SIH 2024 baixado em 12 extratos mensais; esquema real confirmado no primeiro processamento.
- Compatibilidade adicionada para tabelas LazyData exigidas internamente por `microdatasus` 2.5.0 (`tabCBO`).
- Piloto SIM 2024 definitivo baixado e processado; auditorias, indicadores e benchmark reais gerados.
- Auditoria temporal corrigida para comparar períodos dentro de cada sistema, nunca alternando SIH e SIM.
- Tentativas de download corrigidas para reexecutar a operação e tratar respostas vazias do DATASUS como falhas recuperáveis.
- Processamento particionável adicionado (`--shard=N/TOTAL`) para lotes independentes sem alterar os filtros ou indicadores.
- Denominadores revistos para usar Censos 2010/2022 e estimativas oficiais disponíveis; proxy e interpolação removidos, com 2023 mantido ausente.
- União de arquivos anuais/mensais passou a harmonizar esquemas por nome e preencher colunas historicamente ausentes com `NA`.
- Série integral processada e auditada; benchmark de formatos ampliado para amostra distribuída por todos os arquivos.
- Regiões de saúde corrigidas e centralizadas em tabela validada contra os 92 municípios do IBGE; códigos legados inconsistentes não foram reutilizados.
- Indicadores ampliados por sexo, faixa etária, raça/cor, município e região de saúde para SIH e SIM.
- Taxas municipais e estaduais corrigidas para incluir municípios com zero eventos no denominador e usar somente residentes do RJ.
- Artigo HTML e relatório final atualizados com resultados reais e lacunas explícitas.
- Ambiente `renv` restaurado em biblioteca limpa com R 4.6; versões incompatíveis de `selectr`, `xml2` e `rlang` atualizadas para binários validados.
- Camada inferencial adicionada com Mann–Kendall, inclinação de Sen, Kruskal–Wallis, Dunn–Bonferroni, qui-quadrado/Monte Carlo, V de Cramér e correlações de Spearman.
- Linkage ecológico SIH–SIM implementado em município-ano e região-ano; linkage individual explicitamente bloqueado.
- Dez figuras de publicação adicionadas em PDF vetorial, TIFF RGB a 500 dpi e PNG RGB a 500 dpi, incluindo mapas municipais com `geobr`.
- Relatório reprodutível e auditoria específica das análises avançadas adicionados.

### Alterado em relação ao script original

- Eliminados `setwd()` e instalação de pacotes durante a análise.
- Separados aquisição, processamento, auditoria, indicadores e apresentação.
- Período-alvo ampliado para 2025 sem fabricar observações indisponíveis.
- SIM incluído como fonte distinta; integração apenas agregada.
- Proxies populacionais e interpolação automática desativados.
