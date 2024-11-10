FROM rocker/r-ver:4.2.3



## Required system dependencies
RUN apt-get update && apt-get install -y \
    apt-utils \
    zlib1g-dev \
    make \
    libjpeg-dev \
    libtiff-dev \
    libfreetype6-dev \
    libgit2-dev \
    libssl-dev \
    libsasl2-dev \
    imagemagick \
    uuid-dev \
    libmagick++-dev \
    curl \
    gsfonts \
    wget \
    libz-dev \
    libxml2-dev \
    libcurl4-openssl-dev \
    libfontconfig1-dev \
    unixodbc-dev \
    libfribidi-dev \
    libpq-dev \
    gnupg2 \
    jq \
    git \
    libv8-dev \
    libharfbuzz-dev \
    vim \
    pandoc \
    libxt-dev\
    libglpk-dev\
    libpng-dev \
    python3-pip \
    libicu-dev \
    htop \
    python3.10-dev


# Fix Rstudio package manager to use a specific date cutoff
COPY Rprofile.site /usr/local/lib/R/etc/Rprofile.site


# Install required R libraries
COPY install.R /install.R
RUN Rscript /install.R


# Install required Python libraries
COPY requirements.txt /
RUN python3.10 -m pip install -r /requirements.txt
ENV PYTHONPATH=/app/analysis


# Get container to run as user 1000 to stop files being
# created as root on host machine
ARG USER=docker
ARG UID=1000
ARG GID=1000
RUN useradd -m ${USER} --uid=${UID}
USER ${UID}:${GID}


# Get dev containers to use bash by default
ENV SHELL /bin/bash

