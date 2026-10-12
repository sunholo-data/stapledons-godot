### Fixed

- Sky background rebuilt with the corrected `stars.json` (M1.4d, after #37): the destar step no
  longer removes photo stars at the mirrored catalogue positions (118 V<4.5 discs, 0.32% of the
  panorama, are back as photo pixels); every V<6 `stars.json` star is drawn where its photo star
  was removed (474/475).
- Exported builds now carry the sky textures (`make export-macos` stages them via `make sky-bundle`);
  before, every build rendered a black sky.

### Added

- `make sky-assets` (`sky-inputs` -> `destar` -> `sky-model` -> `sky-verify`): rebuilds the two
  generated textures byte for byte from pinned downloads; `data/sky/SHA256SUMS` pins inputs and textures.
- `download_background.sh raw` (the untouched NOIRLab TIF) and `download_stars.sh hip` (the exact
  VizieR request behind `data/raw/hip_v7.tsv`, pinned on its data rows).
