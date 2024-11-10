
import requests
import pathlib

APIROOT = "https://aoestats.io/"


HEADERS = {
    'User-Agent': 'Discord: Coolio9876 #3863',
}


def get_manifest():
    manifest_req = requests.get(
        APIROOT + "api/db_dumps",
        headers=HEADERS
    )
    manifest_req.raise_for_status()
    manifest = manifest_req.json()
    return manifest


def download_week_data(week_meta):
    
    player_path = "data/source/players/players_{start}_{end}.parquet".format(
        start=week_meta["start_date"],
        end=week_meta["end_date"]
    )
    if pathlib.Path(player_path).is_file():
        print("Players already downloaded; skipping")
    else:
        players_req = requests.get(
            APIROOT + week_meta["players_url"],
            headers=HEADERS
        )
        with open(player_path, "wb") as fi:
            fi.write(players_req.content)
    
    match_path = "data/source/matches/matches_{start}_{end}.parquet".format(
        start=week_meta["start_date"],
        end=week_meta["end_date"]
    )
    if pathlib.Path(match_path).is_file():
        print("Matches already downloaded; skipping")
    else:
        matches_req = requests.get(
            APIROOT + week_meta["matches_url"],
            headers=HEADERS
        )
        with open(match_path, "wb") as fi:
            fi.write(matches_req.content)


manifest = get_manifest()


for week_meta in manifest["db_dumps"]:
    print("\n\n----------------")
    print("Downloading week start {}".format(week_meta["start_date"]))
    print("----------------")
    download_week_data(week_meta)
