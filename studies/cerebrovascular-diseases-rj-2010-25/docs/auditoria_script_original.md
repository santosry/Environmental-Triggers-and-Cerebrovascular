# Auditoria técnica e epidemiológica do `script.R` original

Data da auditoria: 2026-07-16. Arquivo auditado somente para leitura: `DESCRITIVO AVC/script.R` (2.418 linhas; parse sintático bem-sucedido; SHA-256 iniciado por `DB6BD9783973CC`).

## Síntese

O arquivo é um protótipo amplo de análise do SIH-RD para 2010–2024, com população, mapas e testes inferenciais. Ele não atende ao objetivo atual porque não contém SIM, não cobre 2025, mistura aquisição e publicação em uma única execução e depende de estado global. Há 24 funções, 243 expressões de nível superior, pelo menos 32 operações de escrita e 12 ocorrências textuais semelhantes a caminhos/URLs; o caminho absoluto efetivo está na linha 23.

## Achados críticos

1. **Objetivo incompleto (linhas 1–8 e 73–160).** O cabeçalho e a aquisição cobrem apenas internações SIH-RD, 2010–2024. Não há download, processamento ou análise do SIM, embora o estudo atual seja de morbimortalidade.
2. **Caminho absoluto e incorreto (linha 23).** `setwd(".../AVC")` torna a execução dependente da máquina e diverge da pasta real `DESCRITIVO AVC`.
3. **Ambiente mutável (linhas 35–69).** O script instala pacotes e os anexa durante a análise. Isso impede um ambiente congelado, mascara dependências transitivas e produz resultados diferentes conforme a data.
4. **Bruto não preservado (linhas 97–131).** `fetch_datasus()` é seguido por `process_sih()`, filtro CID e cache apenas do resultado filtrado. Não existe uma cópia imutável do extrato retornado antes do processamento, nem metadados/hash por arquivo.
5. **Retomada insuficiente (linhas 82–156).** O loop é anual, reúne 12 meses em memória, não tem tentativas com espera progressiva e trata falhas com aviso. Um ano parcialmente obtido pode não ser distinguido de um ano completo.
6. **População metodologicamente incompatível (linhas 303–425).** O ano 2010 é interpolado entre 2009 e 2011 sem análise de sensibilidade. Mais grave, 2022–2024 usam população de 2021 como proxy. Isso altera denominadores e pode enviesar tendências; a refatoração bloqueia taxas sem denominador publicado compatível.
7. **Dependência de nomes presumidos.** O código usa campos como `DIAG_PRINC`, `ANO_CMPT`, `MUNIC_RES`, `IDADE`, `RACA_COR` e `MORTE` sem gerar um contrato de esquema por versão/ano. Alterações no DATASUS podem falhar tarde ou silenciosamente.
8. **Monólito e efeitos colaterais.** Downloads, joins geográficos, recodificação, testes, gráficos e exportações rodam no carregamento do arquivo. Não há interface por etapas nem isolamento de falhas.
9. **Inferência misturada à descrição (linhas 2028–2407).** Mann-Kendall, Cochran-Armitage, Kruskal-Wallis, Dunn e qui-quadrado aparecem no mesmo pipeline descritivo, com múltiplas comparações e pressupostos não sistematicamente documentados. Esses resultados não devem sustentar causalidade.
10. **Reprodutibilidade apenas declarativa (linhas 16–17 e 2410–2414).** `renv::snapshot()` está comentado; `sessionInfo()` só ocorre ao final, que não é alcançado quando uma etapa anterior falha.

## Achados importantes

- A lista de pacotes contém dependências pesadas para uma execução única; funções não são importadas explicitamente e `library(trend)` reaparece na linha 2036.
- A função `instalar_pacote_se_necessario()` (linhas 57–61) não é necessária porque a instalação é repetida vetorialmente nas linhas 64–67.
- `exportar_bruto()` (linhas 165–168) chama um objeto filtrado de “bruto”, criando ambiguidade de linhagem.
- A classificação por CID I60–I69 é apropriada para o desfecho principal, mas deve ser centralizada; no original, os rótulos são repetidos em recodificações posteriores.
- Há validações úteis de chaves e cobertura populacional, porém elas são executadas depois de decisões de interpolação/proxy que deveriam ser bloqueantes.
- Categorias de sexo, raça/cor e óbito dependem dos rótulos produzidos pela versão instalada do `microdatasus`; o script tenta aceitar diversos rótulos, mas não registra o esquema observado.
- A escrita repetida de CSV sem uma política única de tipos, locale e atomicidade aumenta risco de artefatos parciais.
- Não há testes automatizados para CID, taxas, municípios, cobertura ou perdas entre etapas.
- Não há auditoria completa de duplicidades, datas, domínios, valores extremos, quebras mensais e comparação bruto–processado–filtrado.
- O arquivo contém comentários e títulos com forte acoplamento a 2010–2024, exigindo atualização manual em muitos pontos.

## Código obsoleto, duplicações e desempenho

- Instalação duplicada de pacotes e carregamento adicional de `trend`.
- Funções de formatação muito pequenas são aceitáveis, mas ficam misturadas com aquisição e inferência.
- Diversos `write.csv()`, `ggsave()` e `saveRDS()` repetem convenções de caminho e não usam gravação atômica.
- Objetos anuais são acumulados em memória e depois recombinados; o processamento mensal reduz pico de memória e permite retomada granular.
- Shapefiles e população são baixados na mesma execução analítica. Devem ser artefatos versionados por metadados e independentes da geração de resultados.
- A análise recalcula agregações semelhantes para município, região, macrorregião e estado; funções parametrizadas evitam duplicação.

## Refatoração adotada

O novo repositório separa aquisição, processamento, auditoria, indicadores e apresentação; preserva extratos antes do processamento; centraliza CID e período; registra disponibilidade do SIM; gera fluxo de registros; impede taxas sem denominador; usa dados sintéticos na CI; e mantém análises inferenciais como exploratórias e separadas.

