# Age of Statistics

Small project to calculate AOE2 civilisation performance statistics

## Build Instructions

The only dependencies for this project are `docker`, `docker-compose` and an internet connection. In theory the project is OS agnostic however the file system mounting has caused issues on windows in the past (I have not tested this recently). That being said, if you are using windows the recommendation is to run the project from WSL2 Ubuntu 20.04.

Instructions to re-run the analysis

- Clone down the project and navigate to it via the terminal
- Build the images by running `docker-compose build`
- Enable the containers by running `docker-compose up -d`
- Enter the analytic container via `docker-compose exec analysis bash`
- Build the database by running `snakemake -j1 db` (this will take a long time to run)
- Remove prior analysis files via `snakemake -j1 clean`
- Re-run the analysis via `snakemake -j1 all` 

Finally once done we can clean up by:
- exiting the analytic container by running `exit`
- closing down the containers via running `docker-compose down`


## Data Source

Match data is sourced from aoe2.net. A data dictionary for this api can be found [here](https://docs.google.com/spreadsheets/d/19fbY3NV1lvlrtPvul8roxvV7KpEJzCYzzOJzwU0Z464/edit#gid=0)
