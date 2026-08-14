# Relatório final de implementação

## Correção metodológica de 17 de julho de 2026

Foram removidos todos os produtos que combinavam SIH e SIM por chaves
territoriais ou temporais. As duas fontes são analisadas separadamente. As
figuras foram renumeradas e reexportadas, e as auditorias foram regeneradas.

O protocolo de relato foi aplicado integralmente: os 22 itens STROBE e os dez
requisitos RECORD aplicáveis estão atendidos; três itens condicionais a linkage
estão corretamente classificados como não aplicáveis. O diagnóstico e a matriz
item a item estão em `docs/auditoria_RECORD.md` e
`docs/checklist_STROBE_RECORD.csv`.

## Escopo concluído

Foi criado, em pasta separada, um repositório científico modular para SIH/SUS,
SIM e população. A pasta original permaneceu intacta e recebeu cópia de segurança
integral antes do início. O manifesto de arquivos e hashes está em
`docs/manifesto_originais.csv`.

Foram baixados e preservados 192 extratos mensais brutos do SIH (2010–2025) e
15 extratos anuais definitivos do SIM (2010–2024). O SIM 2025 foi procurado nas
fontes definitiva e preliminar e registrado como indisponível em 16 de julho de
2026. Nenhum registro foi fabricado para preencher essa lacuna.

## Resultados técnicos da execução

- SIH filtrado por diagnóstico principal I60–I69: 294.060 internações; 292.952
  de residentes formam a população principal.
- SIM filtrado por causa básica I60–I69: 147.551 óbitos; 147.259 com município
  específico formam o subconjunto geográfico.
- SIH: 192 de 192 meses-alvo presentes; SIM: 12 meses de 2025 ausentes.
- Duplicidades exatas: zero nas duas bases filtradas.
- Duplicidades potenciais: 1.053 no SIH e 12 no SIM; permanecem sinalizadas,
  sem exclusão automática.
- Códigos CID inválidos após o filtro: zero.
- Mudanças mensais superiores ao limiar exploratório de 30%: zero.
- Residência fora do RJ em internações realizadas no RJ: 1.108 registros.
- SIM: 26.808 óbitos com residência e ocorrência em municípios distintos dentro
  do RJ e 501 com ocorrência em outra UF.

As tabelas anuais, municipais, por sexo, faixa etária, raça/cor e região de saúde
estão em `results/tables`. As taxas usam apenas residentes do RJ. Por emenda de
17 de julho de 2026, 2023 usa população municipal interpolada linearmente entre o
Censo 2022 e a estimativa oficial de 2024, com método explicitamente rotulado.

## Desempenho e escolha de formato

Em amostra controlada de 100.000 registros e 236 colunas, Parquet apresentou a
menor leitura (1,06 s) e arquivo (8.838.772 bytes); RDS preservou identidade exata
e permaneceu como cache canônico em R. CSV compactado apresentou 194 problemas
de análise de tipos e não foi escolhido como formato canônico. O processamento
particionado do SIH atingiu aproximadamente 3,9 vezes a vazão do piloto
sequencial, sem mudar filtros ou resultados.

## Criado ou alterado

- configuração única para CID-10 I60–I69 e regiões de saúde;
- downloads retomáveis, tentativas, hashes, metadados e logs;
- processamento modular e preservação das colunas originais;
- auditorias de cobertura, perdas, completude, domínios, datas, valores,
  duplicidades, geografia e quebras temporais;
- indicadores, taxas, séries, figuras, artigo HTML e benchmarks;
- manuscrito RECORD em DOCX/HTML, fluxos separados, checklist integral e matriz
  de vieses;
- nove casos de teste automatizados (21 verificações), lint sem achados e
  workflow GitHub Actions;
- `renv.lock`, licença MIT, `CITATION.cff`, README e documentação técnica.

O `renv.lock` foi restaurado do zero em uma biblioteca local sem cache; o estado
final foi verificado por `renv::status()` como consistente. O repositório Git
local foi inicializado, sem commit ou publicação remota.

## Preservado

Nenhum arquivo da pasta original foi sobrescrito ou excluído. Microdados brutos,
intermediários e processados permanecem locais e são bloqueados pelo `.gitignore`.
O código antigo foi auditado, mas não reutilizado como fonte de códigos municipais
devido a inconsistências encontradas.

## Decisões ainda necessárias do pesquisador

- confirmar autoria, ORCID, contribuições CRediT e declarações do manuscrito;
- decidir se I69 será apresentado junto a eventos agudos ou em análise de
  sensibilidade;
- aprovar a comparação de níveis antes/depois do Censo 2022;
- definir política de supressão de células pequenas antes da publicação;
- escolher qualquer modelo inferencial adicional somente após avaliação formal
  de pressupostos; as regressões atuais são exploratórias e não causais;
- revisar interpretação epidemiológica e texto final do manuscrito.
