# Protocolo analítico do estudo

## Identificação e versão

- Título: Morbimortalidade por doenças cerebrovasculares no estado do Rio de Janeiro.
- Versão: 1.0, consolidada em 17 de julho de 2026.
- Natureza: protocolo retrospectivo, formalizado após a disponibilidade inicial
  dos dados. Não constitui pré-registro e não deve ser apresentado como tal.
- Diretriz de relato: STROBE com extensão RECORD.

## Pergunta e objetivos

Descrever internações financiadas pelo SIH/SUS e óbitos registrados no SIM por
doenças cerebrovasculares entre residentes do estado do Rio de Janeiro. Os
objetivos são quantificar eventos, descrever características, calcular indicadores
com denominadores compatíveis, examinar tendências e sazonalidade e comparar
regiões de saúde sem atribuir causalidade.

## Desenho, populações e período

Estudo observacional ecológico de séries temporais com dados rotineiramente
coletados. A população-fonte do SIH corresponde às internações financiadas pelo
SUS; a população da base corresponde aos arquivos SIH-RD do RJ; a população do
estudo inclui internações de residentes do RJ com diagnóstico principal I60-I69,
2010-2025. A população-fonte do SIM corresponde aos óbitos registrados; a
população da base corresponde aos arquivos definitivos do RJ; a população do
estudo inclui residentes do RJ com causa básica I60-I69, 2010-2024.

## Desfechos e seleção

A definição principal é CID-10 I60-I69. No SIH, aplica-se ao diagnóstico
principal; no SIM, à causa básica. G45 não é incluído. Diagnósticos secundários e
causas associadas são preservados para auditoria, mas não determinam elegibilidade.
I69 representa sequelas e deve ser apresentado separadamente em análise de
sensibilidade quando o objetivo for restrito a eventos agudos.

## Fontes independentes

SIH e SIM são analisados separadamente. Não há pareamento, junção, correlação ou
análise de defasagem entre registros ou agregados dos dois sistemas. A exibição
das duas séries em uma figura é apenas justaposição descritiva.

## Denominadores

Taxas por 100 mil habitantes usam o Censo Demográfico de 2010, estimativas
municipais oficiais nos anos disponíveis e o Censo 2022. Emenda de 17 de julho de
2026: por decisão do pesquisador, 2023 é interpolado linearmente em cada
município entre 2022 e 2024, com fração temporal 0,5 e arredondamento para pessoa
inteira. A fonte e o método permanecem rotulados. Taxas são brutas, sem
padronização etária.

## Plano estatístico

Contagens e proporções são descritivas. Tendências usam Mann-Kendall e inclinação
de Sen; séries mensais usam Mann-Kendall sazonal. Diferenças entre regiões usam
Kruskal-Wallis por ano e Dunn com Bonferroni. Associação bruta entre óbito
hospitalar e variáveis categóricas usa qui-quadrado de Pearson quando os valores
esperados são adequados ou Monte Carlo com semente fixa e 99.999 simulações em
tabelas esparsas. V de Cramér corrigido acompanha os valores de p. Multiplicidade
é relatada por BH ou Bonferroni conforme a família de hipóteses.

## Qualidade e reprodutibilidade

São avaliados cobertura temporal, cardinalidade bruto-processado, duplicidades,
ausência, domínios, CID, datas, idade, permanência, custos e mudanças abruptas.
Alertas não implicam exclusão automática. O ambiente é congelado por `renv`; cada
execução registra sessão, versões e logs. Microdados não são versionados.

## Alterações do protocolo

1. Em 17 de julho de 2026, qualquer combinação analítica entre SIH e SIM foi
   removida por não ser defensável para inferência sobre pessoas ou eventos.
2. Na mesma data, corrigiu-se a multiplicação de nove linhas do SIM causada por
   códigos duplicados na tabela de naturalidade usada pelo `microdatasus` 2.5.0.
   Um dos nove acréscimos afetava a seleção I60-I69. A função passou a preservar
   o código bruto de naturalidade e a interromper a execução se a cardinalidade
   for alterada.

## Status do protocolo

O protocolo é um artefato versionado do repositório e deve acompanhar o manuscrito
como material suplementar. Mudanças futuras devem ser registradas no
`CHANGELOG.md` com data, justificativa e impacto esperado.
