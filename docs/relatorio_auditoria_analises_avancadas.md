# Relatório de auditoria das análises avançadas

## Conclusão

A camada inferencial foi executada sobre 292.952 internações de residentes do
estado do Rio de Janeiro e sobre painéis municipais e regionais de cada sistema.
Foram validados 92 municípios, 29 testes anuais de Kruskal–Wallis, 1.044
comparações de Dunn e sete testes de associação com óbito hospitalar.

SIH e SIM são analisados separadamente. Foram removidos todos os pareamentos,
junções, correlações e análises de defasagem entre registros ou agregados dos dois
sistemas. A justaposição de séries em painéis gráficos tem finalidade descritiva
e não constitui integração das bases.

## Tendências de Mann–Kendall

Após correção BH das oito séries anuais:

- internações SIH apresentaram tendência monotônica crescente: tau = 0,767,
  `p_BH = 0,000164`, inclinação de Sen = 517,4 internações/ano;
- óbitos hospitalares SIH apresentaram tendência crescente: tau = 0,750,
  `p_BH = 0,000164`;
- permanência média apresentou tendência decrescente: tau = -0,933,
  `p_BH = 0,00000465`;
- custo médio nominal apresentou tendência crescente: tau = 0,650,
  `p_BH = 0,000851`; não se trata de custo real corrigido pela inflação;
- taxa estadual de internação apresentou tendência crescente: tau = 0,676,
  `p_BH = 0,000851`;
- taxa de mortalidade SIM apresentou tendência decrescente: tau = -0,451,
  `p_BH = 0,0381`;
- mortalidade hospitalar percentual e número anual de óbitos SIM não mostraram
  tendência monotônica após correção.

O Mann–Kendall sazonal mensal foi significativo para internações SIH
(`tau = 0,705`) e não significativo para óbitos SIM
(`p_Bonferroni = 0,358`). Esses resultados não identificam causalidade nem pontos
de quebra e podem ser afetados por autocorrelação.

## Diferenças entre regiões de saúde

Kruskal–Wallis foi aplicado separadamente em cada ano, com município como unidade
de observação. Após Bonferroni entre anos, houve evidência de heterogeneidade em
13 dos 15 anos com denominador no SIH e em quatro dos 14 anos com denominador no
SIM, de 2011 a 2014.

O Dunn com Bonferroni dentro de cada ano reteve oito contrastes. Com a correção
adicional sobre as 1.044 comparações, apenas Médio Paraíba versus Norte no SIH em
2013 permaneceu significativo (`p_Bonferroni_global = 0,00440`). Os testes
globais não significam que todos os pares regionais diferem.

## Associação com óbito hospitalar

Todas as sete tabelas atenderam ao critério predefinido para qui-quadrado
assintótico; a base real não exigiu Monte Carlo. O caminho de Monte Carlo com
99.999 simulações e semente fixa foi testado em tabela sintética esparsa.

| Variável | V de Cramér corrigido |
|---|---:|
| Subgrupo CID-10 | 0,174 |
| Região de saúde | 0,125 |
| Caráter do atendimento | 0,114 |
| Faixa etária | 0,103 |
| Raça/cor, incluindo ausência | 0,086 |
| Período | 0,021 |
| Sexo | 0,016 |

Os testes são brutos, não ajustam confundimento e não estimam efeitos causais.
Categorias ausentes foram mantidas para auditar a associação entre falta de
informação e desfecho.

## Auditoria das figuras

Foram geradas nove figuras, cada uma em PDF vetorial, TIFF RGB a 500 dpi e PNG
RGB a 500 dpi. Tamanho e hash MD5 são registrados em
`results/audits/auditoria_figuras_publicacao.csv`. As figuras usam escalas
viridis ou paleta Okabe–Ito, alto contraste e redundância por tipo de linha.

## Riscos e limitações remanescentes

1. Não há ajuste por idade, sexo, oferta hospitalar ou cobertura do SUS nas
   comparações territoriais.
2. Dependência espacial entre municípios não é modelada pelo Kruskal–Wallis.
3. Autocorrelação pode alterar a variância do Mann–Kendall.
4. O grande tamanho do SIH torna valores de *p* pouco informativos sem tamanho
   de efeito e intervalos de confiança.
5. O denominador de 2023 é interpolado linearmente por município entre 2022 e
   2024 e deve ser interpretado como modelado; o SIM 2025 está indisponível.
6. I69 inclui sequelas e deve ser avaliado separadamente em sensibilidade.
7. Resultados inferenciais permanecem exploratórios até definição de protocolo
   analítico e hipóteses primárias pelo pesquisador.

## Arquivos de rastreabilidade

- `results/audits/auditoria_analises_inferenciais.csv`;
- `results/audits/auditoria_figuras_publicacao.csv`;
- `results/logs/advanced-analysis-session-info.txt`;
- `results/logs/figures-session-info.txt`;
- `results/tables/mann_kendall_tendencias_anuais.csv`;
- `results/tables/kruskal_wallis_regioes.csv`;
- `results/tables/dunn_bonferroni_regioes.csv`;
- `results/tables/associacao_obito_hospitalar.csv`.
