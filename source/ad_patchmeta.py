
import json
import support.api

meta = support.api.get_meta()

# Add map correction (can be deleted once API has been updated)
correction = [
    {"id": 172, "string": "Land Madness"},
    {"id": 174, "string": "Wade"},
    {"id": 169, "string": "Enclosed"},
    {"id": 168, "string": "Aftermath"},
    {"id": 170, "string": "Haboob"},
    {"id": 171, "string": "Kawasan"},
    {"id": 173, "string": "Sacred Springs"}
]

if "Wade" not in [i["string"] for i in meta["map_type"]]:
    meta["map_type"] = meta["map_type"] + correction
else:
    print("Wade is in meta, correction can be removed!")

with open("./data/ad_patchmeta.json", "w") as fi:
    json.dump(meta, fi)



