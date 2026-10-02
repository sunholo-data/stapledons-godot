### Changed

- Star removal for the sky background is AILANG (`sim/tools/destar.ail`, `make destar`) with Godot headless
  image I/O (`tools/destar_io.gd`), replacing the Python spike. Catalogue-driven and local; all 49 stars
  brighter than V 2 are removed; `make destar-test` (in `make test`) runs a synthetic panorama on the strict VM
  and the interpreter.

### Removed

- `tools/m14a_destar.py`, `tools/m14a_register.py`, `tools/m14a_crops.py`. With `tools/extract.py` gone too,
  no Python pipeline step remains (`make python-guard`: 0 awaiting port).
