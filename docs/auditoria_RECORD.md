# Auditoria final de completude RECORD–STROBE

## Conclusão executiva

O relato reprodutível foi revisado item a item contra os 22 requisitos STROBE e
as 13 extensões RECORD. Na versão de 17 de julho de 2026, os 22 itens STROBE e os
10 requisitos RECORD aplicáveis estão atendidos. RECORD 1.3, 6.3 e 12.3 são
corretamente classificados como **não aplicáveis**, porque nenhum linkage,
pareamento, junção ou correlação entre SIH e SIM foi realizado.

Essa conclusão significa completude do **relato** segundo a diretriz. Não implica
validade clínica dos códigos, ausência de viés, qualidade causal, aprovação ética
ou aceitação editorial.

## Resultado

| Diretriz | Atendido | Não aplicável | Parcial | Não atendido |
|---|---:|---:|---:|---:|
| STROBE | 22 | 0 | 0 | 0 |
| RECORD | 10 | 3 | 0 | 0 |

A matriz verificável está em `docs/checklist_STROBE_RECORD.csv`. O checklist
RECORD produzido pelo pipeline está em
`results/audits/checklist_record_preenchido.csv` e também integra o Apêndice A do
manuscrito.

## Evidências incorporadas

1. Título e resumos identificam os tipos de dados, os nomes SIH/SUS e SIM, o Rio
   de Janeiro e os períodos específicos por sistema.
2. População-fonte, unidade observacional, elegibilidade, campos determinantes e
   lista I60–I69 estão descritos separadamente.
3. G45 está explicitamente excluído e I69 é discutido como fonte de
   heterogeneidade clínica.
4. Acesso, cobertura, data de extração, status definitivo do SIM e
   indisponibilidade de 2025 são relatados.
5. Fluxos reais apresentam base bruta, processamento, filtro CID, residência e
   disponibilidade geográfica.
6. Limpeza, domínios, ausentes, duplicidades, datas, valores, quebras temporais e
   controle de cardinalidade estão documentados.
7. Uma revisão de validade de códigos administrativos foi citada; a ausência de
   validação clínica local foi declarada sem confundi-la com auditoria técnica.
8. Métodos estatísticos, pressupostos, multiplicidade, ausência de ajuste e
   caráter exploratório foram explicitados.
9. A discussão informa finalidade administrativa, cobertura, classificação,
   temporalidade, denominadores, confundimento e generalização.
10. Protocolo, código, testes, suplementos e instruções de reconstrução estão
    identificados; a ausência atual de URL ou DOI público é transparente.

## Achados técnicos que alteraram o relato

- O `process_sim()` do `microdatasus` 2.5.0 podia expandir linhas ao associar
  naturalidade a uma tabela interna com três chaves duplicadas. A rotina foi
  corrigida para preservar NATURAL bruto e interromper qualquer mudança de
  cardinalidade. Todo o SIM foi reprocessado: 2.143.313 registros brutos e
  processados, com 147.551 óbitos I60–I69.
- O SIH contém 294.060 internações I60–I69 nos arquivos do RJ; 292.952 são de
  residentes e compõem a população principal. As 1.108 internações de não
  residentes permanecem apenas na auditoria.
- No SIM, 292 registros usam o código territorial genérico 330000. Eles integram
  os totais estaduais, mas não mapas, taxas ou testes municipais; o subconjunto
  geográfico tem 147.259 registros.

## Linkage

Não há linkage individual ou ecológico. SIH e SIM seguem trilhas independentes,
e seus eventos não são somados nem tratados como medidas intercambiáveis. Logs
históricos registram que uma versão anterior foi removida; não existem tabelas,
figuras, funções ou resultados correntes dessa análise.

## Pendências externas ao checklist

Antes da submissão, os pesquisadores ainda precisam confirmar atribuições CRediT,
ORCID, conflitos, financiamento e enquadramento ético; escolher o periódico e
adaptar seu formato; definir política de células pequenas; e publicar uma release
com URL/DOI. Essas decisões não foram inventadas para produzir aparência de
completude.

## Referência normativa

Benchimol EI et al. The REporting of studies Conducted using Observational
Routinely-collected health Data (RECORD) Statement. *PLoS Medicine*.
2015;12(10):e1001885. doi:10.1371/journal.pmed.1001885.
