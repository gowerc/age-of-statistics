import shutil
import os
import jinja2
import yaml
import argparse
import pathlib


DIR_SITE = "_site"
DIR_OUTPUTS = "outputs"
DIR_WWW = "www"
BUILD_ID = "004"


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--clean",
        dest="clean",
        default=False,
        action="store_true"
    )
    args = parser.parse_args()
    return args


def build_page_simple(page, cohort_meta):
    PAGE = os.path.join(DIR_SITE, f"{page}.html")
    print(f"Building {PAGE}....")
    content = env.get_template(f"{page}.html").render(
        cohorts=cohort_meta
    )
    with open(PAGE, "w") as fi:
        fi.write(content)


def build_page_cohort(cohort, cohort_meta):
    PAGE = os.path.join(DIR_SITE, f"cohort_{cohort['id']}.html")
    print(f"Building {PAGE} ....")
    content = env.get_template("cohort.html").render(
        cohort=cohort["id"],
        meta=cohort,
        cohorts=cohort_meta,
        build_id=BUILD_ID
    )
    with open(PAGE, "w") as fi:
        fi.write(content)


def get_cohort_meta():
    with open('data-raw/cohort.yml', "r") as stream:
        cohort_meta = yaml.safe_load(stream)
    return cohort_meta


def refresh():
    print("Refreshing full site directory")
    if os.path.isdir(DIR_SITE):
        shutil.rmtree(DIR_SITE)
    os.mkdir(DIR_SITE)
    shutil.copytree(
        DIR_OUTPUTS,
        os.path.join(DIR_SITE, DIR_OUTPUTS)
    )
    shutil.copytree(
        DIR_WWW,
        os.path.join(DIR_SITE, DIR_WWW)
    )



if __name__ == "__main__":

    args = get_args()
    if args.clean:
        refresh()

    cohort_meta = get_cohort_meta()

    env = jinja2.Environment(
        loader=jinja2.FileSystemLoader("templates"),
        autoescape=False
    )

    for page in ["index", "methods", "faq"]:
        build_page_simple(page, cohort_meta)

    for cohort in cohort_meta:
        build_page_cohort(cohort, cohort_meta)

    for folder, subfolders, files in os.walk(DIR_SITE):
        for file in files:
            x = pathlib.Path(os.path.join(folder, file))
            if x.suffix in [".png"]:
                x.rename(x.parent.joinpath(x.stem + "_" + BUILD_ID + x.suffix))
    
    # Clean up
    shutil.move(
        os.path.join(DIR_SITE, "www", "favicon.ico"),
        os.path.join(DIR_SITE, "favicon.ico")
    )
    shutil.move(
        os.path.join(DIR_SITE, "www", "netlify.toml"),
        os.path.join(DIR_SITE, "netlify.toml")
    )
