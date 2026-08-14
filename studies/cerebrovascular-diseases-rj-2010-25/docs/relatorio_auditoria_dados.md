# Relatório de auditoria dos dados

Este arquivo descreve o protocolo e não contém números simulados. Resultados reais são gerados em `results/audits/` após os downloads e o processamento.

## Resultado integral

- SIH 2025: 12 arquivos mensais listados no servidor em 2026-07-16.
- SIM definitivo: arquivos do RJ listados até 2024 em 2026-07-16.
- SIM preliminar 2025: não listado na consulta de 2026-07-16.
- SIH: 192 meses de 2010–2025, sem lacuna mensal; 294.060 internações com diagnóstico principal I60–I69.
- SIM: 15 anos definitivos de 2010–2024; 147.552 óbitos com causa básica I60–I69. Os 12 meses ausentes correspondem a 2025 indisponível.
- Não houve perda entre bruto e processado; as exclusões correspondem ao filtro do desfecho.
- Não foram encontrados CID inválidos nem duplicidades exatas nas bases filtradas.
- Foram sinalizados 1.053 registros SIH em duplicidades potenciais pela chave AIH–ano–mês e 14 registros SIM por chave composta quase-identificadora; eles não foram excluídos automaticamente.
- Foram observadas 1.108 internações no RJ de residentes de outras UFs; 292.952 eram de residentes do RJ.
- No SIM filtrado, 120.243 óbitos ocorreram no município de residência, 26.808 em outro município da mesma UF e 501 em outra UF.
- O limiar de 30% não sinalizou quebra mensal abrupta nas séries agregadas. Isso não substitui análise formal de pontos de mudança.

Custos do SIH são nominais e não foram deflacionados; comparações temporais de valores monetários exigem índice de preços e decisão metodológica adicional.
