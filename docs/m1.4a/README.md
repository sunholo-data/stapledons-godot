# M1.4a background spike: which all-sky panorama?

Attended spike, 2026-10-01. The decision is Mark's; it will be recorded as a decision-ledger row.
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

## Next, once a source is picked (Option A)

1. Detect point sources and cross-match them to the shipped point layers (CNS5, GCNS, HIP2 V<7).
   Mask and inpaint **only** the matches; unmatched faint stars stay as pixels.
2. Produce before/after crops plus a residual map, then sky-shader renders at β = 0, 0.5 and 0.99.

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
