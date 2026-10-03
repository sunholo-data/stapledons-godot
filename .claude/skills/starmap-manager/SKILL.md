---
name: Starmap Manager
description: Manage starmap data for the Stapledon's Voyage Godot rebuild (data/raw → data/starmap). Use when downloading star catalogs (CNS5, GCNS/Gaia), galactic backgrounds or exoplanets, or when (re)processing catalogue data. (project)
---

# Starmap Manager

Download, process, and manage astronomical data for the game's 3D starmap. Handles real star catalogs (Gaia), exoplanet data (NASA), and galactic background imagery (NOIRLab all-sky panorama).

## Quick Start

**Most common usage:**
```bash
# Catalogue inputs into data/raw (public bucket first, else VizieR + sim/tools/extract.ail; pin-checked)
make catalogue-inputs AILANG=$A

# Build a tier (VM; quick ~1 s, medium/large ~80 s)
make catalogue TIER=quick|medium|large AILANG=$A

# Stats (AC2/AC3) on the committed tiers, and the byte-identical rebuild check
make catalogue-stats            # every tier present; TIER=medium judges only medium
make catalogue-verify AILANG=$A # prints "quick identical", "medium identical"

# Check what's installed
.claude/skills/starmap-manager/scripts/status.sh
```

## When to Use This Skill

Invoke this skill when:
- User wants to download real star data for the game
- User asks about Gaia, exoplanet, or astronomical data sources
- User wants galactic background images/textures
- Setting up starmap assets for the first time
- Upgrading from quick to medium/large dataset

## Data Tiers

Tiers are binary: `data/starmap/stars_<tier>.bin`, 24-byte little-endian F32 records
`x, y, z` (ly, galactic), `teff` (K), `v` (mag), `flags`, plus a `stars_<tier>.json` sidecar
(`count`, `count_excluded`, `format_version` 1, `record_bytes` 24, `fields`, the AILANG version,
the `sunholo/relativity` pin, and sha256 of the raw download, the CSV and the bin). Godot reads them
through `sky/star_catalogue.gd` (`StarCatalogue.load_tier`), which refuses a pair whose sidecar or
sha256 does not match.

| Tier | Source (VizieR) | Rows | Bin | In git |
|------|-----------------|------|-----|--------|
| **quick** | CNS5, J/A+A/670/A19 `cns5.dat` (all rows with a parallax) | 5,908 | 141,792 B | yes (D-3) |
| **medium** | GCNS, J/A+A/649/A6 `table1c.dat.gz` (50,000 nearest with complete photometry; 965 missing-photometry rows passed over) | 50,000 | 1,200,000 B | yes (D-3) |
| **large** | GCNS, J/A+A/649/A6 `table1c.dat.gz` (all rows) | 331,312 | 7,951,488 B | no (gitignored; build on demand) |

Pipeline (all AILANG, no Python): `download_stars.sh` → `data/raw/{cns5.dat,table1c.dat.gz}`;
`sim/tools/extract.ail` → `data/raw/{cns5,gcns}.csv`; `sim/tools/catalogue.ail` (photometry from
`sunholo/relativity`) + `sim/tools/catalogue_main.ail` (encode, sha256, atomic write) →
`make catalogue TIER=…`. All four inputs are pinned in `data/sky/SHA256SUMS`.
The quick and medium tiers are committed with `git add -f` (`.gitignore` ignores `stars_*`);
after a rebuild, `make catalogue-verify` must still print `identical` for both.

`data/starmap/stars.json` is the galaxy map catalogue (M1.7, Q7): the quick + bright tier rows
within 25 pc, float64, one star per line, ids `Gaia DR3 n` / `CNS5:n` / `HIP n`. `make starmap`
writes it (sim/tools/starmap.ail via bright_main.ail `mapMain`); `make catalogue-verify` rebuilds
and cmp-checks it. `data/starmap/names.json` names entries by those ids (D-17), verified by
`tools/check_star_names.py`. The starfield draws the binary tiers, not this file.

## Available Scripts

### `scripts/download_stars.sh <tier>`
Download a raw catalogue into `data/raw/` (prints size + sha256). `quick` = CNS5 `cns5.dat`;
`medium` and `large` = the same GCNS `table1c.dat.gz` (the tier is chosen by `make catalogue`);
`hip` = Hipparcos V < 7.5 for the sky-background star removal.

```bash
.claude/skills/starmap-manager/scripts/download_stars.sh quick
.claude/skills/starmap-manager/scripts/download_stars.sh medium
```

### `scripts/download_exoplanets.sh`
Download NASA Exoplanet Archive confirmed planets (~3MB).

```bash
.claude/skills/starmap-manager/scripts/download_exoplanets.sh
```

### `scripts/download_background.sh [resolution]`
Download NOIRLab all-sky panorama (noirlab2430b) for galactic background.

```bash
# 4K version (4000x2000, ~3.5MB) - default
.claude/skills/starmap-manager/scripts/download_background.sh 4k

# 10K version (10000x5000, ~27MB JPEG) - HD/4K displays
.claude/skills/starmap-manager/scripts/download_background.sh 10k
```

### Sky background textures (M1.4, D-10): `make sky-assets`

The in-game Milky Way is two generated 10000×5000 PNGs in `data/raw/background/`
(gitignored): `noirlab_10k_destarred.png` and `noirlab_10k_skymodel.png`.
`make sky-assets` rebuilds them byte for byte:

1. `make sky-inputs`: the public bucket first (`tools/sky_assets.sh fetch inputs`), then
   `download_background.sh raw` (NOIRLab TIF), `download_stars.sh hip` (exact VizieR request in
   `resources/data_sources.md`), `download_stars.sh medium` / `quick` + `sim/tools/extract.ail`
   (gcns.csv, cns5.csv); skipped when present, then pin-checked.
2. `make destar`: catalogue-matched stars out of the photo (`sim/tools/destar.ail`, Godot I/O in
   `tools/destar_io.gd`; HIP V<7.5, GCNS, CNS5).
3. `make sky-model`: AILANG per-texel colour-temperature fit.
4. `make sky-verify`: every input and output against `data/sky/SHA256SUMS`.

`make export-macos` packs both textures into the .pck (`include_filter` `data/*`). Without
them the sky renders black.

### `scripts/status.sh`
Show raw inputs, each tier's sidecar (count, excluded, bin sha256) and the background textures.

```bash
.claude/skills/starmap-manager/scripts/status.sh
```

## Workflow

```bash
make catalogue-inputs AILANG=$A          # or: download_stars.sh quick / medium, then make extract
make catalogue TIER=medium AILANG=$A     # rebuild a tier
make catalogue-stats TIER=medium         # AC3: M-dwarf share >= 60 %, 0 defaulted-photometry rows
make catalogue-verify AILANG=$A          # rebuilt quick + medium == committed bytes
make catalogue-parity AILANG=$A          # interpreter vs VM x5 on the medium tier
```

## Resources

- [`resources/data_sources.md`](resources/data_sources.md): sources, URLs, schemas, licences.
- [`resources/processing.md`](resources/processing.md): coordinate and photometry notes.

## Notes

- **Licensing**: star data CC BY-SA 3.0, background imagery CC BY 4.0 (NOIRLab).
- **Determinism**: same inputs, same AILANG version and package pin → byte-identical tiers.
- **Dependencies**: `curl`, `shasum`, Godot and AILANG (pinned in the Makefile). No Python.
