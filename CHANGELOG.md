# Changelog

## v1.1.0 — 20260811_173331 (Correções de qualidade de dados)

### Dados
- **SIM**: idade convertida do formato DATASUS (centenas → anos); 187 registros com idade=999 tratados como NA
- **SIH**: 29.564 duplicatas removidas (10.3%); total de internações únicas: 258.831
- **Sexo**: padronizado para M/F entre bases SIH (1/3) e SIM (1/2)
- **Pandemia**: adicionada variável  (2020-03 a 2022-02) além da original
- **Dataset macro**: adicionadas flags de auditoria (, )

### Documentação
- Artigo atualizado: deduplicação, idade SIM, pandemia restrita, I67, heat_index, influenza_lag7
- README atualizado: data quality row na tabela de atributos
- Adicionado relatório completo de auditoria (32 issues mapeadas)
- Adicionada seção "Notas sobre qualidade e processamento dos dados" no artigo

### Novos arquivos
- 
- 
- 
- 
- 
-  (resultados Wilcoxon)

## v1.0.0 — 2026-06-21 (Release inicial)
- Pipeline DLNM completo
- 72 modelos principais
- 88+ arquivos de auditoria
