# M1.4a background spike: which all-sky panorama?

Attended spike, 2026-10-01. **Decided: NOIRLab, Option A** (D-10, ledger commit `e9d35c5`).
Raw sources live in `data/raw/background/` (gitignored). The comparison crops were cut with a throwaway script, since deleted under the Python policy.
Every crop uses the same galactic window: 40° × 20°, with l increasing to the left.

| Candidate | Source | Native size | Licence | Read |
|---|---|---|---|---|
| **NOIRLab** `noirlab2430b` (E. Slawik) | photo mosaic | 10000×5000 (TIF) | CC BY 4.0 | Rich colour, H-α (Barnard's Loop), strong star halos. This is what the old Go repo used. |
| **ESO** `eso0932a` (S. Brunier) | photo mosaic | 6000×3000 here; 18000×9000 original TIF | CC BY 4.0 | Most natural and closest to the naked eye; small star profiles; weak H-α. Registration is a few degrees off l=0, which needs a fit. |
| **Gaia EDR3** flux map | built from 1.8 billion Gaia stars, not a photo | 16000×8000 | CC BY-SA 3.0 IGO | No nebulae and noisy. It is made of stars, so masking is meaningless. Share-alike. **Not recommended.** |

## Images

| Region | NOIRLab | ESO | Gaia |
|---|---|---|---|
| Full sky | [noirlab_full](noirlab_full.jpg) | [eso_full](eso_full.jpg) | [gaia_full](gaia_full.jpg) |
| Galactic centre | [noirlab](noirlab_galactic_centre.jpg) | [eso](eso_galactic_centre.jpg) | [gaia](gaia_galactic_centre.jpg) |
| Crux / Carina / Coalsack | [noirlab](noirlab_crux_carina.jpg) | [eso](eso_crux_carina.jpg) | [gaia](gaia_crux_carina.jpg) |
| Orion | [noirlab](noirlab_orion.jpg) | [eso](eso_orion.jpg) | [gaia](gaia_orion.jpg) |

## Star removal (Option A)

**Now AILANG** (`sim/tools/destar.ail`, `make destar`, 2026-10-02), with Godot headless doing the image I/O
(`tools/destar_io.gd`). It replaces the Python spike, whose numbers are kept below for comparison. The AILANG version is
catalogue-driven and local, where the spike was whole-image:
- detection, background and noise come from samples around each catalogue star (≥ 1.5 halo radii out);
- a clipped core (any channel ≥ 254) counts as a detection;
- masks use the same per-V halo table;
- the fill is inverse-distance interpolation from the clean ring plus donor grain;
- each pixel belongs to the largest disc that contains it.

| | Spike (Python, whole-image) | `destar.ail` |
|---|---|---|
| Matched V < 2 | 100% | 49/49 |
| Matched V 2–6 | about 95% | 97–99% |
| Matched V 6–7 / 7–8 | 94% / 74% | 96% / 74% |
| Masked | 7.8% of pixels | 8.3% (24,444 sources) |
| Runtime | about 1 min | 13–16 min on the VM |

The figures come from `data/sky/destar_report.json`. Before/after crops (top: original; bottom: `destar.ail`):
[α Cen / Hadar](destar_ailang_alpha_cen.jpg) · [Sirius](destar_ailang_sirius.jpg) · [Orion](destar_ailang_orion.jpg). Known residual: fills in the dense band are smoother than the spike's,
because fewer donor patches there are clean enough to lend grain.

Spike method, for reference:
- **Registration:** the panorama is plain galactic equirectangular (l=0 at centre, l increasing to the left).
  The 25 brightest Hipparcos stars land within a median of 0.3/0.5 px (MAD 1.5/1.1 px) of their catalogue
  positions, so no fit is needed.
- **Detection:** 904,494 point sources above 5σ, measured against a 30th-percentile background.
- **Match:** catalogue = HIP V<7.5 + GCNS (G→V, Riello) + CNS5, matched by position and magnitude.
  31,982 catalogue stars matched 25,895 panorama sources.
- **Mask:** radius from a per-V halo table (isolated-star medians); 7.8% of pixels masked.
- **Fill:** normalized-convolution background plus clipped donor grain, with a feathered edge.

| View | File |
|---|---|
| Destarred full sky | [noirlab_destarred_full.jpg](noirlab_destarred_full.jpg) |
| Galactic centre: original / mask (green) / destarred | [destar_galactic_centre.jpg](destar_galactic_centre.jpg) |
| Crux–Carina | [destar_crux_carina.jpg](destar_crux_carina.jpg) |
| Orion | [destar_orion.jpg](destar_orion.jpg) |
| 1:1 pixels, α Cen / Hadar (top original, bottom destarred) | [destar_1to1_alpha_cen.jpg](destar_1to1_alpha_cen.jpg) |
| 1:1 Sirius | [destar_1to1_sirius.jpg](destar_1to1_sirius.jpg) |
| 1:1 Canopus | [destar_1to1_canopus.jpg](destar_1to1_canopus.jpg) |

**Known residuals (for M1.4b to fix or accept):**
- The Sirius hole is still faintly visible at 1:1 as a flatter patch. In-game, 1 panorama px is about 1 screen px at a 90° FOV.
- M42's core is softened, because the Trapezium stars are catalogue stars and must go.
- The panorama's 8-bit, tone-mapped pixels are not linear radiance. M1.4b's blackbody fit needs an inverse tone curve
  (or a linear source) before the per-texel T_c fit means anything.
- Spike code, not gated: no tests, and the outputs live in gitignored `data/raw/background/`.

## In-game (production shader, M1.4b/c)

The renders now come from the production `sky/background.gdshader`. It uses a per-texel T_c from the AILANG
fitter (`make sky-model`), not the spike's single 4600 K. `spike/panorama.tscn` is `main.gd` plus the removed
HIP stars as points, and stays until M1.2d ships the bright tier.

```sh
make sky-model    # once: destarred photo -> data/raw/background/noirlab_10k_skymodel.png (~12 min)
AILANG_BIN=$PWD/runtime/bin/ailang godot --path . --resolution 1920x1080 res://spike/panorama.tscn -- --capture=/abs/out
```

| | |
|---|---|
| **Forward at β = 0 / 0.5 / 0.9 / 0.99** | [forward_0_05_09_099.jpg](preview/forward_0_05_09_099.jpg) |
| **Astern at β = 0 / 0.5 / 0.9 / 0.99** | [astern_0_05_09_099.jpg](preview/astern_0_05_09_099.jpg) |
| Contact sheet (rows β; columns forward / starboard / astern) | [contact_sheet.jpg](preview/contact_sheet.jpg) |
| T_c map (red = cool, blue = hot) and emission-line flags (red overlay) | [skymodel_tc_and_lineflags.jpg](skymodel_tc_and_lineflags.jpg) |

Still open, each owned by a later milestone:
- **Emission nebulae.** H-α leaves the visible band at D ≳ 1.7. Flagged texels (4.7% of the light) still Doppler as if they
  were thermal; modelling the line needs new package maths first.
- **Exposure is hand-set:** background 0.6 against stars 40 in the review scene; 0.075 against 5 in `main.gd`. M1.5 calibrates both.
- **The bright stars removed from the photo** show in `make capture` only once M1.2d (HIP2 tier) lands.

## Next

1. Star removal is ported to AILANG (`make destar`, above). Open: grain in the dense-band fills.
2. M1.5: photometric exposure calibration of the background against the stars.

## Does travel change the background? (parallax)

A move of d light-years shifts a feature at distance D by about d/D radians.
On the 10k panorama, 1 px = 0.036°.

| Trip | Nearest dust clouds (~450 ly: Taurus, Ophiuchus, Coalsack) | Milky Way band (~3,000 ly and beyond) | Galactic centre (26,000 ly) |
|---|---|---|---|
| α Cen, 4.4 ly (R1) | 0.56° (~15 px) | 0.08° (~2 px) | 0.01° |
| 50 ly | 6° | 1° | 0.1° |
| 500 ly | you are inside or past them | 10° | 1.1° |
| 3,000 ly+ | wrong | the band visibly reshapes | 7° |

- **R1 (α Cen) is fine.** The worst shift is half a degree on the nearest clouds, and during the voyage
  aberration moves everything by tens of degrees.
- **The full game is not.** The design repo says "thousands of light-years reachable", so a single
  panorama is valid only out to about 50 ly from Sol. Beyond that the game needs either a parallax
  guard (fade or cross-fade) or a 3D diffuse model. That is a post-R1 item, and it should be recorded
  as a stated limit in the M1 design doc.
