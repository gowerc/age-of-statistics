
import yaml

with open('data-raw/cohort.yml', "r") as stream:
    cohort_meta = yaml.safe_load(stream)

cohorts = [i["id"] for i in cohort_meta]



rule all:
    input:
        expand("outputs/cohort_{cohort}/cohort_data.json", cohort=cohorts)


rule db:
    shell: "python3.9 ./source/db_update.py"


rule clean:
    shell:
        """
        rm -rf data/*
        rm -rf outputs/*
        """


rule killr:
    shell:
        """
        kill -9 $(ps -u root | awk '$4=="R" {{ printf "%s ", $1 }}')
        """

rule site:
    shell:
        """
        python3.9 ./source/build_site.py --clean
        """

###### VAD
rule matchmeta_players:
    output: "data/ad_matchmeta.parquet", "data/ad_players.parquet"
    input: "source/ad_ana.R", "data/ad_patchmeta.json"
    shell: "Rscript {input[0]}"


rule patchmeta:
    output: "data/ad_patchmeta.json"
    input: "source/ad_patchmeta.py"
    shell: "python3.9 {input[0]}"


rule:
    output: "outputs/cohort_{cohort}/cohort_data.json"
    input: "source/out_cohort.R", "data/ad_matchmeta.parquet"
    shell: "Rscript {input[0]} {wildcards.cohort}"

