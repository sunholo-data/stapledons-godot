### Added

- The quick (5,908 stars) and medium (50,000 stars) catalogue tiers and their
  sidecars are committed under `data/starmap/` (D-3). The large tier stays a
  local build.
- `sky/star_catalogue.gd` (`StarCatalogue`) loads a binary tier. It refuses any
  pair whose sidecar `format_version`, `record_bytes`, `fields` or `count`, or
  whose sha256 of the bin, does not match. M1.3 renders from it.
- `make catalogue-stats` (Godot headless, part of `make test`) reports each
  tier's count, excluded count, M-dwarf share and white dwarfs, and checks the
  defaulted-photometry invariant on every record. Medium: 74.4 % M dwarfs, 0
  violations (AC3; AC2's clause).
- `make catalogue-verify` rebuilds quick and medium from the pinned inputs and
  checks them byte for byte against the committed files.
- `make catalogue-inputs` fetches the four catalogue inputs from the bucket,
  falls back to VizieR and `extract.ail`, then checks their pins.

### Fixed

- `data/raw/cns5.dat`, the raw input of the quick tier, is now pinned in
  `data/sky/SHA256SUMS` (sha256 `7e8c1a2c…`). `tools/sky_assets.sh fetch` now
  tries every pin before it exits 1, so `make` falls back only for the files the
  bucket lacks. It also takes an optional path filter.

### Removed

- `process_stars.sh`. The starmap-manager skill now documents the binary tiers
  and `make catalogue`, and `status.sh` reads the tier sidecars.
