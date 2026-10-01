# M1.4a: background options (spike report)

**Status:** decided. **Decision:** Option A on NOIRLab `noirlab2430b`, D-10, attended 2026-10-01.
**Design:** [m1-relativistic-sky.md §M1.4](m1-relativistic-sky.md#m14-milky-way-background).
**Branch:** `m1.4a-background-spike`. Images and full method are in [`docs/m1.4a/README.md`](../../../docs/m1.4a/README.md).

## Candidates

| | Source | Licence | Verdict |
|---|---|---|---|
| A / NOIRLab | E. Slawik all-sky photo, 10000×5000 | CC BY 4.0 | **Chosen** |
| A / ESO | S. Brunier `eso0932a`, 18000×9000 original | CC BY 4.0 | Viable; more natural colour; registration is a few degrees off |
| B stand-in / Gaia EDR3 flux | built from 1.8 billion Gaia sources | CC BY-SA 3.0 IGO | Rejected: no nebulae, made of stars, share-alike |

Option B (a synthetic Gaia density map plus a dust map) wasn't built. Mark ruled for a real photograph
before it was needed.

## Acceptance criteria (sprint `M1.4a_BACKGROUND_SPIKE`)

| AC | Evidence |
|---|---|
| Renders at 0 / 0.9 / 0.99c | `docs/m1.4a/preview/` (also 0.5c), produced by `spike/panorama.tscn` running the AILANG 1 g voyage |
| Residual crops | `docs/m1.4a/destar_*.jpg` (original / mask / result), `destar_1to1_*.jpg` |
| Decision recorded in the design doc | Open question 1 and §M1.4 "M1.4a outcome"; ledger D-10 |

## Star-removal numbers (`tools/m14a_destar.py`)

- Registration: median offset 0.3/0.5 px over the 25 brightest HIP stars, with no fit.
- 904,494 sources detected; 31,982 catalogue stars (HIP V<7.5, GCNS, CNS5) matched to 25,895 sources.
- Match completeness: 100% at V<2, about 95% at V 2–7, 74% at V 7–8. Below about V 8 the panorama doesn't resolve stars.
- 7.8% of pixels masked; 878,599 unmatched sources kept as pixels.

## Carried into M1.4b/c

Registration, the sRGB-decode assumption, line-dominated texel flags and the 50 ly parallax limit
(design §M1.4 "M1.4a outcome"). Visible residuals: a faint flat patch at Sirius at 1:1, and a softened M42 core.
