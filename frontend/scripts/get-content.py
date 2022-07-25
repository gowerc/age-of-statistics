import shutil
import pathlib
import os

outloc = pathlib.Path("./public/outputs")

if outloc.exists():
    shutil.rmtree(outloc)

shutil.copytree("../backend/outputs", outloc)


def remove_then_copy(from_loc, to_loc):
    from_loc = pathlib.Path(from_loc)
    to_loc = pathlib.Path(to_loc)
    if to_loc.exists():
        to_loc.unlink()
    os.makedirs(os.path.dirname(to_loc), exist_ok=True)
    shutil.copy2(from_loc, to_loc)


remove_then_copy(
    "../backend/data/raw/config.json",
    "./src/components/json/config.json"
)


remove_then_copy(
    "../backend/data/raw/footnotes.json",
    "./src/components/json/footnotes.json"
)
