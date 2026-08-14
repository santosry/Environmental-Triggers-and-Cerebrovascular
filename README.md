# Morbimortalidade por doenças cerebrovasculares no Rio de Janeiro

Repositório científico para um estudo ecológico descritivo da morbimortalidade por doenças cerebrovasculares no estado do Rio de Janeiro, entre 2010 e 2025. As fontes são o Sistema de Informações Hospitalares do SUS (SIH/SUS), para internações, e o Sistema de Informações sobre Mortalidade (SIM), para óbitos.

## Definição dos desfechos

A definição principal é CID-10 **I60–I69** no diagnóstico principal do SIH e na causa básica do SIM. Ela está centralizada em `config/config.yml`. O código G45 (ataques isquêmicos transitórios) não integra a definição principal. Diagnósticos secundários e causas associadas são preservados para auditoria, mas não definem o desfecho principal.

## Período, área e disponibilidade

- Área: estado do Rio de Janeiro (UF RJ), segundo residência e, quando aplicável, ocorrência/internação.
- Período-alvo: 2010–2025.
- SIH: arquivos mensais; a disponibilidade é consultada antes de cada execução.
- SIM: arquivos anuais. Em 16 de julho de 2026, o DATASUS apresentava dados definitivos até 2024; o SIM 2025 não estava disponível no diretório definitivo nem no preliminar. O script sempre revalida e registra `definitivo`, `preliminar` ou `indisponivel`.

Dados preliminares nunca são rotulados como definitivos. Anos indisponíveis permanecem como lacunas documentadas, não como zero.

## Estrutura

- `config/`: período, UF, CID e parâmetros de qualidade.
- `data-raw/`: extratos brutos locais (ignorados pelo Git).
- `data/intermediate/` e `data/processed/`: artefatos regeneráveis (ignorados pelo Git).
- `R/`: funções reutilizáveis.
- `scripts/`: pipeline numerado.
- `results/`: tabelas agregadas, figuras, logs e auditorias.
- `tests/`: testes apenas com dados sintéticos.
- `docs/`: protocolo, dicionário, fluxo e relatórios técnicos.

## Requisitos e instalação

Requer R 4.4 ou superior, acesso ao DATASUS e compiladores adequados aos pacotes usados. Em uma instalação limpa:

```r
install.packages("renv", repos = "https://cloud.r-project.org")
renv::restore()
```

Se o `renv.lock` ainda não estiver disponível, execute `Rscript scripts/00_instalar_dependencias.R` e depois `renv::snapshot()`.

## Ordem de execução

Comece pelo piloto de um ano:

```text
Rscript scripts/00_instalar_dependencias.R
Rscript scripts/01_baixar_sih.R --pilot
Rscript scripts/02_processar_sih.R --pilot
Rscript scripts/03_baixar_sim.R --pilot
Rscript scripts/04_processar_sim.R --pilot
Rscript scripts/05_baixar_populacao.R
Rscript scripts/06_integrar_bases.R
Rscript scripts/07_auditar_dados.R
Rscript scripts/08_calcular_indicadores.R
Rscript scripts/09_analise_descritiva.R
Rscript scripts/10_analise_temporal.R
Rscript scripts/12_benchmark.R
Rscript -e "testthat::test_dir('tests/testthat')"
```

Após validar o piloto, repita `01` a `04` sem `--pilot` para 2010–2025. O download tem retomada: arquivos existentes são verificados e não baixados novamente.

Em máquinas com memória suficiente, `02` e `04` aceitam partições independentes como `--shard=1/4` até `--shard=4/4`. Cada arquivo pertence a uma única partição; execute todas antes da integração. O modo padrão permanece sequencial e mais conservador.

## População e taxas

`scripts/05_baixar_populacao.R` combina fontes municipais oficiais: Censo 2010
(SIDRA 202/93), estimativas de 1º de julho para 2011–2021 e 2024–2025 (SIDRA
6579/9324) e Censo 2022 (SIDRA 4709/93). Como não há valor oficial de 2023 nessa
estratégia, o projeto interpola linearmente cada município entre 2022 e 2024. A
coluna `metodo` identifica `interpolacao_linear_2022_2024`; esse denominador não
deve ser apresentado como estimativa oficial publicada. A descontinuidade entre
Censo e estimativas exige cautela na interpretação de tendências.

As regiões de saúde estão centralizadas em `config/regioes_saude_rj.csv`. A tabela
usa as [nove regiões da SES-RJ](https://www.saude.rj.gov.br/assessoria-de-regionalizacao/sobre-a-regionalizacao/2017/04/regionalizacao)
e é validada contra os 92 nomes municipais obtidos do IBGE; códigos legados do
script original não são reutilizados.

## Resultados gerados

O pipeline produz fluxos de inclusão/exclusão, cobertura temporal, completude, duplicidades, valores inválidos, quebras temporais, indicadores de internação/mortalidade hospitalar, óbitos por causa básica, séries e benchmarks de formatos. Modelos temporais exploratórios não autorizam interpretação causal. O manuscrito do artigo (DOCX) é mantido fora do rastreamento Git e não é publicado no repositório; o código, as auditorias e as tabelas agregadas o são.

Na execução concluída em 16 de julho de 2026, foram processados 192 extratos
mensais do SIH (2010–2025) e 15 extratos anuais definitivos do SIM (2010–2024).
O filtro CID identificou 294.060 internações; 292.952 internações de residentes
compõem a população principal. O SIM contém 147.551 óbitos elegíveis, dos quais
147.259 possuem município específico para análises geográficas. Esses totais são
resultados desta extração, sujeitos a revisão das fontes, e não estimativas da
morbidade ou mortalidade total da população.

## Execução limpa no Windows PowerShell

```powershell
Set-Location 'C:\Users\oorie\OneDrive\Documentos\TRABALHOS\artigo-morbimortalidade-avc-rj'
$R = 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe'
& $R -e "install.packages('renv', repos='https://cloud.r-project.org'); renv::restore(prompt=FALSE)"
& $R scripts/01_baixar_sih.R --pilot
& $R scripts/02_processar_sih.R --pilot
& $R scripts/03_baixar_sim.R --pilot
& $R scripts/04_processar_sim.R --pilot
& $R scripts/05_baixar_populacao.R
& $R scripts/01_baixar_sih.R
& $R scripts/02_processar_sih.R
& $R scripts/03_baixar_sim.R
& $R scripts/04_processar_sim.R
& $R scripts/06_integrar_bases.R
& $R scripts/07_auditar_dados.R
& $R scripts/08_calcular_indicadores.R
& $R scripts/09_analise_descritiva.R
& $R scripts/10_analise_temporal.R
& $R scripts/12_benchmark.R
& $R scripts/13_analises_inferenciais.R
& $R scripts/14_figuras_cellpress.R
& $R -e "testthat::test_dir('tests/testthat', reporter='summary')"
```

## Política de dados

Microdados brutos ou processados do DATASUS, caches, credenciais e arquivos grandes **não devem ser enviados ao GitHub**. O repositório público deve conter código, documentação, dados sintéticos de teste, tabelas agregadas permitidas e figuras principais. Revise risco de reidentificação mesmo em agregados de pequenas células.

## Limitações

SIH representa internações financiadas pelo SUS, não pessoas únicas nem toda a morbidade. Uma pessoa pode ter várias AIH. SIM está sujeito a atraso, revisão e qualidade variável de preenchimento. Diferenças entre residência e ocorrência são descritivas. O ano de 2025 pode estar incompleto ou indisponível. Não se infere causalidade.

## Licença e citação

O código é licenciado sob MIT (`LICENSE`). Os dados permanecem sujeitos às regras de suas fontes; o texto científico e figuras exigem definição autoral própria. Consulte `CITATION.cff` para citar o repositório.

## Análises inferenciais adicionais

`scripts/13_analises_inferenciais.R` executa Mann–Kendall anual e sazonal,
inclinação de Sen, Kruskal–Wallis por ano, Dunn–Bonferroni, associações com óbito
hospitalar, V de Cramér e intervalos de Wilson.
`scripts/14_figuras_cellpress.R` gera nove figuras em PDF, TIFF e PNG.

SIH e SIM são analisados separadamente; não há pareamento, junção ou correlação
entre registros ou agregados dos sistemas. Consulte
`docs/relatorio_auditoria_analises_avancadas.md` para pressupostos e limitações.

## Conformidade RECORD–STROBE

O relato foi auditado contra os 22 itens STROBE e as 13 extensões RECORD. Os 22
itens STROBE e os dez requisitos RECORD aplicáveis estão atendidos; os três itens
condicionais a linkage estão corretamente classificados como não aplicáveis.
Isso representa completude do relato, não validação clínica ou causal. Consulte
`docs/auditoria_RECORD.md` e `docs/checklist_STROBE_RECORD.csv`.
