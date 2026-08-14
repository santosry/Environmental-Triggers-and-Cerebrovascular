# Plano de benchmarks

O benchmark usa amostra aleatória reproduzível de no máximo 100 mil registros de uma base processada. Compara escrita/leitura em RDS, CSV gzip e Parquet; leitura CSV com `readr` e `data.table`; tempo decorrido; tamanho em disco; memória do objeto; versão do R, sistema e pacotes.

O benchmark não modifica dados analíticos nem escolhe resultados epidemiológicos. RDS é o formato operacional básico por preservar tipos em R; Parquet deve ser preferido para leitura seletiva e interoperabilidade quando `arrow` estiver disponível; CSV gzip é um formato de intercâmbio, com possível perda de tipos.

## Processamento em lote observado

O piloto SIH sequencial processou 12 meses em 397,3 s (33,1 s/arquivo). A ampliação em quatro lotes processou os 180 meses restantes em 1.533,1 s de parede (8,5 s/arquivo), ganho de vazão aproximado de 3,9 vezes. A comparação é operacional, não um experimento perfeitamente controlado, pois os conjuntos de anos diferem.

O benchmark de formatos usou 100 mil linhas (208,6 MB em memória) distribuídas por 207 arquivos. Parquet ocupou 8,84 MB e leu em 1,06 s; RDS ocupou 9,65 MB e leu em 6,25 s; CSV gzip ocupou 12,44 MB e leu em 6,37 s com `readr` e 9,24 s com `data.table`. O `readr` registrou 194 problemas de inferência de tipos, quantificados em `benchmark_integridade.csv`.

Decisão: RDS permanece o cache operacional por preservar exatamente classes e atributos do R; Parquet é recomendado para leitura seletiva e intercâmbio analítico; CSV gzip não deve ser o cache canônico de bases largas e heterogêneas. Tempos variam por hardware e devem ser interpretados comparativamente nesta execução.
