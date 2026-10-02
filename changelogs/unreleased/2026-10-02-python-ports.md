### Changed

- Star removal for the sky background is AILANG (`sim/tools/destar.ail`, `make destar`) with Godot headless
  image I/O (`tools/destar_io.gd`), replacing the Python spike. Catalogue-driven and local; all 49 stars
  brighter than V 2 are removed; `make destar-test` (in `make test`) runs a synthetic panorama on the strict VM
  and the interpreter.
- Merged with M1.4d (#45): `make destar` in the sky-assets pipeline is the AILANG destar; its catalogue
  list is HIP V<7.5 + GCNS + CNS5 (`data/raw/cns5.csv`, now pinned) instead of `stars.json`. A bright
  catalogue star (V < 4.5) whose core rolls off at 245-253 instead of clipping now counts as detected:
  eps Sco, alpha Ara, lambda Cen, zeta Ara, eta Sco and alpha Lac were left in the photo on the Milky
  Way band. Every HIP star brighter than V 4.5 is removed. New texture pins in `data/sky/SHA256SUMS`;
  `sky-inputs` falls back to `sim/tools/extract.ail` for gcns.csv/cns5.csv.

### Removed

- `tools/m14a_destar.py`, `tools/m14a_register.py`, `tools/m14a_crops.py`. With `tools/extract.py` gone too,
  no Python pipeline step remains (`make python-guard`: 0 awaiting port).
