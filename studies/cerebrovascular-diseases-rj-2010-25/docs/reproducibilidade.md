# Reprodutibilidade

- R e pacotes são congelados em `renv.lock`.
- O cache por links do `renv` foi desativado neste projeto para manter compatibilidade com a pasta sincronizada pelo OneDrive; `renv::restore()` instala cópias locais.
- Caminhos são relativos ao projeto via `here`.
- A semente 42 é usada apenas em amostras de benchmark/teste.
- Extratos brutos são imutáveis, ignorados pelo Git e acompanhados de hash/metadados.
- Logs registram UTC, evento, nível, contexto e sessão.
- CI usa dados sintéticos e não acessa DATASUS.
- Artefatos publicados devem ser regeneráveis a partir de scripts numerados.
- Denominadores municipais têm fonte e método por ano; 2023 é identificado como interpolação linear municipal entre 2022 e 2024, nunca como estimativa oficial publicada.

Para reproduzir, restaure o ambiente, execute primeiro o piloto e confira `results/audits`. Só então execute o período completo. A disponibilidade do DATASUS muda; por isso o status observado faz parte do resultado de cada execução.
