# Suplemento de métodos RECORD

## Acesso às bases

Os pesquisadores tiveram acesso aos arquivos públicos disponibilizados pelo
DATASUS para os sistemas e períodos selecionados, não a prontuários clínicos nem
a bases internas do Ministério da Saúde. O SIH-RD foi obtido mês a mês para o RJ,
2010-2025. O SIM definitivo foi obtido ano a ano para residentes do RJ,
2010-2024. Em 16 de julho de 2026, SIM 2025 não estava disponível em versão
definitiva ou preliminar e não foi tratado como zero.

Os arquivos foram obtidos com `microdatasus::fetch_datasus()` e processados com
`process_sih()` ou `process_sim()`. Cada arquivo bruto foi preservado localmente
em RDS, com metadados e hash. Falhas, tentativas e decisões automatizadas foram
registradas em logs. Dados brutos e processados permanecem fora do Git.

## Códigos e algoritmos de seleção

| Sistema | Campo | Regra executável | Interpretação |
|---|---|---|---|
| SIH/SUS | `DIAG_PRINC` | normalizar maiúsculas e remover pontuação; selecionar prefixos I60-I69 | internação com diagnóstico principal cerebrovascular |
| SIM | `CAUSABAS` | normalizar maiúsculas e remover pontuação; selecionar prefixos I60-I69 | óbito com causa básica cerebrovascular |
| Ambos | município de residência | normalizar para seis dígitos e exigir prefixo 33 | residente do estado do Rio de Janeiro |
| Ambos | período | SIH 2010-2025; SIM definitivo 2010-2024 | cobertura observada na data de extração |

G45 não integra a definição principal. I60-I62 abrangem hemorragias não
traumáticas; I63, infarto cerebral; I64, acidente vascular cerebral não
especificado; I65-I66, oclusões/estenoses sem infarto; I67-I68, outras doenças
cerebrovasculares; I69, sequelas.

## Variáveis derivadas

- `ano` e `mes`: competência do SIH ou data do óbito no SIM;
- `faixa_etaria`: menor de 1, 1-19, 20-39, 40-59, 60-79 e 80 anos ou mais;
- `obito_hospitalar`: verdadeiro para códigos equivalentes a 1, sim ou óbito no
  campo MORTE; falso nos demais valores válidos;
- `regiao_saude`: associação determinística dos 92 municípios de residência à
  configuração territorial versionada em `config/regioes_saude_rj.csv`;
- `taxa_100mil`: eventos divididos pela população compatível e multiplicados por
  100.000; permanece ausente quando o denominador não existe ou é inválido;
- categorias ignoradas/ausentes: mantidas explicitamente e não redistribuídas.

## Limpeza e qualidade

1. nomes e tipos são padronizados, preservando todas as colunas recebidas;
2. datas são convertidas com regras específicas do sistema;
3. códigos municipais são normalizados sem imputação;
4. CID é normalizado antes do filtro;
5. cardinalidade bruto-processado é comparada por arquivo;
6. duplicidades exatas e potenciais são sinalizadas, sem exclusão automática;
7. idades fora de 0-120 anos, permanência fora de 0-3.650 dias e custos negativos
   são sinalizados;
8. ausência, domínios e cobertura mensal/anual são tabulados;
9. mudanças mensais absolutas de 30% ou mais são alertas de triagem;
10. totais são comparados em cada etapa do fluxo.

O `microdatasus` 2.5.0 fazia associação da variável NATURAL a uma tabela com
três códigos duplicados, criando nove linhas adicionais no SIM de 2010-2012. A
rotina corrigida impede essa associação, restaura o código bruto de naturalidade
e exige igualdade de linhas antes e depois do processamento. A correção reduziu
o conjunto I60-I69 de 147.552 para 147.551 óbitos.

## Validade dos códigos

Não houve revisão de prontuários nem validação clínica local. Uma revisão
sistemática internacional de bases administrativas encontrou desempenho razoável
de I60-I69 para doença cerebrovascular ampla, mas desempenho inferior quando o
alvo é AVC agudo; por isso, o estudo não interpreta I60-I69 como sinônimo de
incidência de primeiro AVC. A qualidade geral do SIM brasileiro melhorou ao longo
do tempo, mas desigualdades e problemas de classificação permanecem. Essas
evidências apoiam transparência sobre erro de classificação, não validam
automaticamente os códigos no RJ.

## Ausência de ligação entre bases

Não foi realizado nenhum tipo de ligação em nível individual, institucional,
municipal, regional ou temporal. Os itens RECORD condicionais a esse procedimento
são classificados como não aplicáveis.
