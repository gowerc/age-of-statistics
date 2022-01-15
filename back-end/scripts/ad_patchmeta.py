
import json
import support.api

meta = support.api.get_meta()

with open("./data/processed/ad_patchmeta.json", "w") as fi:
    json.dump(meta, fi)
