import shutil
import pathlib

outloc = pathlib.Path("./public/outputs")

if outloc.exists():
    shutil.rmtree(outloc)

shutil.copytree("../backend/outputs", outloc)


configloc = pathlib.Path("./public/config.json")
if configloc.exists():
    configloc.unlink()

shutil.copy2("../backend/data/raw/config.json", configloc)
