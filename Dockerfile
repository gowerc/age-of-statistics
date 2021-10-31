FROM rocker/r-ver:4.1.1

## Required system dependencies
RUN apt-get update && apt-get install -y \
    apt-utils \
    libssl-dev \
    libsasl2-dev \
    curl \
    wget \
    libz-dev \
    libxml2-dev \
    libcurl4-openssl-dev \
    unixodbc-dev \
    libpq-dev \
    gnupg2 \
    jq \
    git \
    libv8-dev \
    vim \
    pandoc \
    libxt-dev\
    libglpk-dev\
    python3-pip \
    libicu-dev \
    htop \
    python3.9-dev

RUN python3 -m pip install snakemake

## Install postgressql-cleint 13 (to communicate with db from the command line)
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" | tee  /etc/apt/sources.list.d/pgdg.list
RUN apt-get update && apt-get -y install postgresql-client-13


# Fix Rstudio package manager to use a specific date cutoff
RUN sed -i "s/latest/2021-09-14\+Y3JhbiwyOjQ1MjYyMTU7MjQ1QUQ0RA/g" /usr/local/lib/R/etc/Rprofile.site

# Install required libraries
RUN Rscript -e "options(warn=2);\
    install.packages(c(\
        'tidyverse',\
        'dplyr',\
        'tidyr',\
        'tibble',\
        'stringr',\
        'assertthat',\
        'lubridate',\
        'httr',\
        'glue',\
        'languageserver',\
        'devtools',\
        'RPostgres',\
        'DBI',\
        'rmarkdown',\
        'knitr',\
        'DT',\
        'dbplyr',\
        'forcats',\
        'HyRiM',\
        'ggdendro',\
        'jsonlite',\
        'kableExtra',\
        'ggrepel',\
        'googlesheets4',\
        'lsa',\
        'mvtnorm'\
    ))"

COPY requirements.txt /
RUN python3.9 -m pip install -r /requirements.txt
ENV PYTHONPATH=/app/analysis

RUN mkdir /app
WORKDIR /app


