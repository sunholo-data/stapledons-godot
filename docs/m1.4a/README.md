# M1.4a background spike: which all-sky panorama?

Attended spike, 2026-10-01. **Decided: NOIRLab, Option A** (D-10, ledger commit `e9d35c5`).
Raw sources live in `data/raw/background/` (gitignored). The crops come from `tools/m14a_crops.py`.
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

## Star removal (Option A), spike result

`tools/m14a_destar.py` (`uv run --with pillow --with numpy --with scipy --with opencv-python-headless python tools/m14a_destar.py`)

- **Registration:** the panorama is plain galactic equirectangular (l=0 at centre, l increasing to the left).
  The 25 brightest Hipparcos stars land within a median of 0.3/0.5 px (MAD 1.5/1.1 px) of their catalogue
  positions, so no fit is needed (`tools/m14a_register.py`).
- **Detection:** 904,494 point sources above 5σ, measured against a 30th-percentile background.
- **Match:** catalogue = HIP V<7.5 + GCNS (G→V, Riello) + CNS5 (`data/starmap/stars.json`), matched by position
  (3 px, wider for bright stars) and magnitude (±1.5 mag against a fitted zero point). 31,982 catalogue stars
  matched 25,895 panorama sources. Completeness: V<2 100%, V 2–6 ~95%, V 6–7 94%, V 7–8 74%. Below V 8
  the panorama stops resolving them, so they are already part of the diffuse light.
- **Mask:** radius from a per-V halo table (isolated-star medians), not a per-star profile, because the profile
  test swallowed the Carina nebula and M42. For V<2 the radius is the larger of the table and the measured halo.
  7.8% of pixels are masked.
- **Fill:** normalized-convolution background from unmasked pixels only, plus faint-star grain borrowed from
  the nearest ≥80%-clean donor patch (clipped to ±18 DN so a donor can't carry in a star), with a feathered edge.
- **Kept as pixels:** 878,599 unmatched sources, i.e. the distant stars beyond the point layers.

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

## In-game preview (relativistic)

`spike/panorama.tscn` extends `main.gd` (the 1 g AILANG voyage, heading toward the galactic centre):
- Sky: the destarred panorama, sampled per pixel through inverse aberration, with blackbody Doppler
  (`spike/panorama_sky.gdshader`, same LUT as the stars). The mip level follows D, so the compressed forward cone doesn't sparkle.
- Points: CNS5 plus Hipparcos V<7.5 beyond 25 pc, i.e. the stars that were removed from the panorama, put back as relativistic splats.

```sh
AILANG_BIN=$PWD/runtime/bin/ailang godot --path . --resolution 1920x1080 res://spike/panorama.tscn -- --capture=/abs/out
```

| | |
|---|---|
| **Forward at β = 0 / 0.5 / 0.9 / 0.99** | [forward_0_05_09_099.jpg](preview/forward_0_05_09_099.jpg) |
| Contact sheet (rows β = 0, 0.5, 0.9, 0.99; columns forward / starboard / astern) | [contact_sheet.jpg](preview/contact_sheet.jpg) |
| Every frame at 1920×1080 | [preview/](preview/) |

Preview simplifications, each owned by a later milestone:
- **One colour temperature (4600 K) for every texel.** M1.4b fits T_c per texel.
- **Emission nebulae are not blackbodies.** H-α (656 nm) at D = 1.5 lands at 437 nm, and by D ≈ 1.7 it is ultraviolet,
  so the red nebulae should vanish from the forward view instead of brightening with the continuum. M1.4b needs a line component,
  or should at least flag line-dominated texels.
- **Exposure is hand-set:** background 0.6, stars 40, PSF σ 1.2 px. M1.5 calibrates both against a dark-sky reference.
- **The photo is tone-mapped 8-bit, not linear radiance** (see the residuals above).

## Next (M1.4b/c, routable to the loop)

1. Productionise `m14a_destar.py` into `tools/sky_model.py` with tests: registration, match completeness and a residual budget.
2. Fit (log T_c, log L_v) per texel; sky shader; renders at β = 0, 0.5 and 0.99.

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
