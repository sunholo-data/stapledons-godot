# Star-truth audit: every catalogue disagreement, resolved

**Design:** [starmap-single-truth.md](../../planned/r1/starmap-single-truth.md) (goal 4, AC4). **Sprint:** R1-STARMAP-TRUTH.
**Table:** `data/starmap/truth/positions.csv` (rule `truth-1`; inputs and digests in `positions.json`).
**Check:** `make starmap-truth-audit` fails if any marked row lacks a resolution or its Gaia id is missing from this document.
**Date:** 2026-10-07, AILANG v0.52.0.

## What was compared

There are 5,212 truth rows:

- **5,203 stars that CNS5 and GCNS both list** under the same Gaia id;
- **8 CNS5 stars with no Gaia id** that GCNS lists under one (cross-identifications from the companion table): `relabel`;
- **1 bright Hipparcos star** that GCNS also lists (HIP 27890 = Gaia 4756622820871136640): `drop`. The bright tier renders it, so the GCNS duplicate is removed.

The rendered sky before this work disagreed with navigation in two ways: the GCNS tier placed these stars at raw-EDR3 parallaxes, and 26 destinations with photometry were not drawn at all. Measured over the 5,132 destinations the medium stack drew, the offsets were:

| | Median | 90th percentile | Maximum |
|---|---|---|---|
| Before (main, 2026-10-07) | 0.020 ly (1,270 AU) | 0.088 ly | 8.71 ly (Gaia 816649002967779584) |
| After | 0 (float64 restore) | 0 | 4.2 × 10⁻⁶ ly in the float32 tier copy, before the restore |

Every difference is radial: the two catalogues' directions agree to within 0.033 arcsec for all 5,203 shared stars, and to within 0.39 arcsec for the cross-identifications. **No cross-match errors were found.**

## Why the 5,134 Gaia-EDR3 stars differ at all

CNS5 publishes EDR3 parallaxes with the Lindegren et al. (2021) zero-point correction applied; GCNS publishes them raw. CNS5 − GCNS is +0.028 mas at the median and +0.083 mas at most. That is far inside 3σ for every star, so none is marked; the table adopts the corrected value. It is the 0.042 ly TRAPPIST-1 offset that hid the star at the stand-off (RT4).

## The 14 disagreements over max(3σ, 1 %): all "better parallax"

In each case CNS5's evaluation rejected the EDR3 solution and adopted Hipparcos (van Leeuwen 2007) or Gaia DR2 instead. The EDR3 solution has RUWE ≥ 1.68 in every case (≥ 1.4 marks a poor single-star fit, typically an unresolved binary), and these are bright stars or known doubles. The adopted value is CNS5's in every case, so **navigation (`stars.json`) does not move; the GCNS tiers move onto it.**

| Gaia DR3 | Star (CNS5 GJ, HIP) | Adopted ϖ (mas) | EDR3 ϖ (mas), RUWE | Adopted d (ly) | Old sky d (ly) | Resolution |
|---|---|---|---|---|---|---|
| 816649002967779584 | GJ 332 AB, HIP 44248 | 62.23 ± 0.68 Hipparcos | 53.362 ± 0.809, 8.01 | 52.41 | 61.12 | better parallax |
| 2940211607277084672 | GJ 10940 | 50.0 ± 0.4 DR2 | 55.078 ± 0.704, 10.27 | 65.23 | 59.22 | better parallax |
| 6187779556809793024 | GJ 11892 | 53.8 ± 0.7 DR2 | 49.046 ± 0.725, 2.35 | 60.62 | 66.50 | better parallax |
| 1502523188143833088 | GJ 12000 | 50.0 ± 0.6 DR2 | 46.296 ± 0.581, 11.01 | 65.23 | 70.45 | better parallax |
| 5182151481717042944 | GJ 10462 | 49.9 ± 0.5 DR2 | 47.602 ± 0.498, 3.07 | 65.36 | 68.52 | better parallax |
| 2183807118443409536 | GJ 802 | 58.32 ± 0.14 DR2 | 60.962 ± 0.397, 7.73 | 55.93 | 53.50 | better parallax |
| 2996171698248699904 | GJ 9190, HIP 27288 | 46.28 ± 0.16 Hipparcos | 44.794 ± 0.247, 4.32 | 70.47 | 72.81 | better parallax |
| 4269932382607207040 | GJ 711, HIP 89962 | 53.93 ± 0.18 Hipparcos | 52.441 ± 0.204, 3.71 | 60.48 | 62.19 | better parallax |
| 3352485999058854912 | GJ 242, HIP 32362 | 55.56 ± 0.19 Hipparcos | 54.189 ± 0.237, 1.85 | 58.70 | 60.19 | better parallax |
| 4426032591025363200 | GJ 3921, HIP 77622 | 46.30 ± 0.19 Hipparcos | 45.329 ± 0.250, 4.19 | 70.44 | 71.95 | better parallax |
| 1623289903206300928 | GJ 609.1, HIP 78527 | 47.54 ± 0.12 Hipparcos | 46.466 ± 0.136, 2.18 | 68.61 | 70.19 | better parallax |
| 4573412435280434560 | GJ 3995, HIP 84379 | 43.41 ± 0.15 Hipparcos | 42.481 ± 0.222, 3.07 | 75.13 | 76.78 | better parallax |
| 4076915349846977664 | GJ 713.1, HIP 90496 | 41.72 ± 0.16 Hipparcos | 42.920 ± 0.213, 1.68 | 78.18 | 75.99 | better parallax |
| 6838311796136238976 | GJ 837, HIP 107556 | 84.27 ± 0.19 Hipparcos | 85.941 ± 0.333, 3.92 | 38.70 | 37.95 | better parallax |

The other 55 stars where CNS5 adopted Hipparcos or DR2 differ by less than max(3σ, 1 %). They take CNS5's value too, and the table records both parallaxes.

**Genuinely uncertain distances: none.** No marked row has a good EDR3 solution (RUWE < 1.4) as well, so nothing is labelled "distance uncertain" for star inspection. Open question 2 of the design is moot for this data, but the mechanism remains: the `resolution` would read `uncertain: ...`, and `make starmap-truth-audit` lists it.

## Cross-identifications (8 relabel, 1 drop)

CNS5 lists these stars without a Gaia id, so it never evaluated their EDR3 solutions. Under `truth-1`, Gaia comes first when the solution is good (ϖ/σ ≥ 10 and RUWE < 1.4):

| CNS5 | Gaia DR3 | CNS5 ϖ (source) | EDR3 ϖ, RUWE | Adopted |
|---|---|---|---|---|
| CNS5:252 (GJ 10136) | 2371519626175864960 | 34.0 ± 6.6 (Kirkpatrick+2021) | 29.813 ± 1.258, 1.10 | EDR3 |
| CNS5:4157 | 1412657697622625536 | 33.4 ± 3.4 (Kirkpatrick+2021) | 31.124 ± 0.533, 1.17 | EDR3 |
| CNS5:65 | 2361294885296927488 | 36.8 ± 2.0 (DR2) | 38.045 ± 1.577, 1.01 | EDR3 |
| CNS5:138 | 2800081221135505536 | 41.4 ± 2.0 (DR2) | 42.888 ± 1.645, 1.21 | EDR3 |
| CNS5:898 | 3264130653394056320 | 38.7 ± 3.4 (Kirkpatrick+2021) | 35.503 ± 0.859, 1.14 | EDR3 |
| CNS5:2934 | 3896357089270247168 | 39.2 ± 6.2 (Kirkpatrick+2021) | 37.317 ± 2.656, 1.22 | EDR3 |
| CNS5:528 | 5151358868307074432 | 53.7 ± 1.1 (2017AJ 154 147D) | 49.346 ± 1.628, 1.63 | CNS5 (EDR3 RUWE ≥ 1.4) |
| CNS5:2733 | 761918578311083264 | 42.9 ± 1.1 (DR2) | 42.245 ± 1.058, 1.61 | CNS5 (EDR3 RUWE ≥ 1.4) |
| HIP 27890 (bright tier) | 4756622820871136640 | — | 36.598 ± 0.092, 2.21 | bright row; GCNS copy dropped |

None of these pairs is over the threshold, because the CNS5 errors are large. The only navigation change is CNS5:138 (no photometry, not drawn), which moves from 78.78 to 76.05 ly. The other five are beyond the 25 pc map. In the GCNS tiers these rows now carry the CNS5 identity, so a star is never drawn under two names.

## Re-running (Gaia DR4, expected December 2026)

```sh
make catalogue-inputs                 # new pins in data/sky/SHA256SUMS first
make companions starmap-truth         # table + sidecar
make starmap-truth-audit              # lists the new marked rows; add each to this document
make catalogue TIER=quick && make catalogue TIER=medium && make starmap && make starmap-consistency
git diff --stat data/starmap          # the audit diff
```
