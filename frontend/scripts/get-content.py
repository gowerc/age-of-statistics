import shutil
import pathlib

outloc = pathlib.Path("./public/outputs")

if outloc.exists():
    shutil.rmtree(outloc)

shutil.copytree("../backend/outputs", outloc)


configloc = pathlib.Path("./src/components/json/config.json")
if configloc.exists():
    configloc.unlink()

shutil.copy2("../backend/data/raw/config.json", configloc)



footnotesloc =  pathlib.Path("./src/components/json/footnotes.json")
if footnotesloc.exists():
    footnotesloc.unlink()
shutil.copy2("../backend/data/raw/footnotes.json", footnotesloc)

