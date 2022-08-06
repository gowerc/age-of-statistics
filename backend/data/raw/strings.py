import requests
import json


def get_strings(game="aoe2de", language="en"):
    params = {
        "game": game,
        "language": language
    }
    resp = requests.get("https://aoe2.net/api/strings", params)
    resp.raise_for_status()
    return resp.json()


meta = get_strings()

with open("./data/raw/strings.json", "w") as fi:
    json.dump(meta, fi, indent=4)
