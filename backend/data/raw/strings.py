
import json
import support.api

meta = support.api.get_strings()

with open("./data/raw/strings.json", "w") as fi:
    json.dump(meta, fi, indent=4)
