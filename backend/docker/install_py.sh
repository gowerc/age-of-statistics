
# This file is not used by the docker build
# it is just a log of what are the main modules
# that the project needs to install
# The purpose is to rerun this manually if we want to do a complete
# refresh / update of the module versions or remove dependencies
# that are no longer required

pip3 install \
    flake8 \
    requests \
    snakemake \
    numpy \
    pandas \
    pyarrow


