---
name: Starmap Manager
description: Manage starmap data for the Stapledon's Voyage Godot rebuild (data/raw → data/starmap). Use when downloading star catalogs (CNS5, GCNS/Gaia), galactic backgrounds or exoplanets, or when (re)processing catalogue data. (project)
---

# Starmap Manager

Download, process, and manage astronomical data for the game's 3D starmap. Handles real star catalogs (Gaia), exoplanet data (NASA), and galactic background imagery (NOIRLab all-sky panorama).

## Quick Start

**Most common usage:**
```bash
# Download quick dataset (~2MB total, fastest start)
.claude/skills/starmap-manager/scripts/download_stars.sh quick

# Download medium dataset (~15MB, richer local bubble)
.claude/skills/starmap-manager/scripts/download_stars.sh medium

# Download galactic background
.claude/skills/starmap-manager/scripts/download_background.sh

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

| Tier | Stars | Exoplanets | Size | Use Case |
|------|-------|------------|------|----------|
| **Quick** | 5,930 (CNS5) | ~6,000 | ~2 MB | Rapid prototyping |
| **Medium** | ~50,000 (filtered GCNS) | ~6,000 | ~15 MB | Release candidate |
| **Large** | 331,312 (full GCNS) | ~6,000 | ~75 MB | HD/DLC option |

## Available Scripts

### `scripts/download_stars.sh <tier>`
Download star catalog for specified tier (quick/medium/large).

```bash
# Quick: CNS5 nearby stars (~1.2MB)
.claude/skills/starmap-manager/scripts/download_stars.sh quick

# Medium: Filtered GCNS G/K/M dwarfs (~10MB)
.claude/skills/starmap-manager/scripts/download_stars.sh medium

# Large: Full GCNS 100pc catalog (~72MB compressed)
.claude/skills/starmap-manager/scripts/download_stars.sh large
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

### `scripts/process_stars.sh`
Convert downloaded star catalogs to game-ready format.

```bash
# Process all downloaded catalogs
.claude/skills/starmap-manager/scripts/process_stars.sh
```

### `scripts/status.sh`
Show current starmap asset status.

```bash
.claude/skills/starmap-manager/scripts/status.sh
```

## Workflow

### 1. Initial Setup (Quick Start)

```bash
# Download minimal dataset for development
.claude/skills/starmap-manager/scripts/download_stars.sh quick
.claude/skills/starmap-manager/scripts/download_exoplanets.sh
.claude/skills/starmap-manager/scripts/download_background.sh
.claude/skills/starmap-manager/scripts/process_stars.sh
```

### 2. Upgrade to Medium (Pre-Release)

```bash
# Get richer dataset for release
.claude/skills/starmap-manager/scripts/download_stars.sh medium
.claude/skills/starmap-manager/scripts/process_stars.sh
```

### 3. HD Assets (Optional DLC)

```bash
# Full catalog + high-res background
.claude/skills/starmap-manager/scripts/download_stars.sh large
.claude/skills/starmap-manager/scripts/download_background.sh 10k
.claude/skills/starmap-manager/scripts/process_stars.sh
```

## Output Files

All processed data goes to `data/starmap/`:

```
data/starmap/
├── stars.json          # Combined star catalog (positions, types, etc.)
├── exoplanets.json     # Confirmed exoplanets with orbital data
├── habitable.json      # Pre-filtered habitable zone candidates
└── background/
    └── galaxy_4k.png   # All-sky galactic panorama
```

## Resources

### Data Sources
See [`resources/data_sources.md`](resources/data_sources.md) for:
- Complete data source documentation
- API endpoints and download URLs
- Data schemas and column descriptions
- Licensing information (all CC BY-SA 3.0 compatible)

### Processing Pipeline
See [`resources/processing.md`](resources/processing.md) for:
- Coordinate conversion (RA/Dec to galactic XYZ)
- Filtering criteria for each tier
- JSON schema for game integration
- Habitable zone calculations

## Notes

- **Licensing**: Star data CC BY-SA 3.0, background imagery CC BY 4.0 (NOIRLab)
- **Updates**: Star positions don't change; exoplanets update quarterly
- **Determinism**: Same processing produces identical output
- **Dependencies**: Requires `curl`, `jq`, `python3` (for coordinate conversion)
