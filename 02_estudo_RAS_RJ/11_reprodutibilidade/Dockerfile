# 11_reprodutibilidade/Dockerfile
# Ambiente reprodutível e portável para o pipeline (R + Python).
#
# Build (a partir da raiz do projeto):
#   docker build -f 11_reprodutibilidade/Dockerfile -t dlnm-cerebrovascular:2014-2024 .
# Execução:
#   docker run --rm -v "$PWD":/projeto dlnm-cerebrovascular:2014-2024 \
#     Rscript 11_reprodutibilidade/run_all.R --rapido
#
# Observação: os microdados brutos (.rds) e as bases pesadas não são
# versionados; monte o volume do projeto para reaproveitá-los.

FROM rocker/r-ver:4.6.1

# Dependências de sistema (sf/geobr, ragg/systemfonts, microdatasus, Python)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev libssl-dev libxml2-dev libsodium-dev libgit2-dev \
    libgdal-dev libgeos-dev libproj-dev libudunits2-dev \
    libpng-dev libtiff5-dev libjpeg-dev libfreetype6-dev \
    libharfbuzz-dev libfribidi-dev \
    python3 python3-pip python3-venv \
    git ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Pacotes R fixados (espelha 11_reprodutibilidade/versoes_pacotes_R.csv)
RUN R -q -e 'install.packages(c(\
    "data.table","jsonlite","digest","openssl","sessioninfo",\
    "microdatasus","lme4","performance","trend","pROC",\
    "ggplot2","viridisLite","scales","patchwork","ragg",\
    "sf","dplyr","geobr"), repos="https://cloud.r-project.org")'
RUN R -q -e 'install.packages("glmmTMB", repos="https://cloud.r-project.org")'

# Dependências Python fixadas
COPY 11_reprodutibilidade/requirements.txt /tmp/requirements.txt
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt

WORKDIR /projeto
COPY . /projeto

CMD ["Rscript", "11_reprodutibilidade/run_all.R", "--rapido"]
