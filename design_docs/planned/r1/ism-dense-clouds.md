# Dense interstellar clouds and Local Leo Cold Cloud: PR B

| Pillar | Alignment | Reason |
|---|---:|---|
| Choices Are Final | +1 | Dense gas constrains a route before commitment through the existing drive-hold rule. |
| The Game Doesn't Judge | 0 | Scientific checks, not preferred routes, decide whether the dataset can ship. |
| Time Has Emotional Weight | 0 | No change to the existing clocks or compression. |
| The Ship Is Home | 0 | Uses the existing wall renderer and HUD. |
| Grounded Strangeness | +2 | Measured dust tomography and absorption sight lines must support the displayed clouds. |
| We Are Not Built For This | 0 | No weakened clearance or drive constraint. |

Net +3: aligned, go; scientific acceptance remains required.

**Status:** Deferred; runtime integration has not landed. **Release:** R1 follow-up. **Approval:** original PR B scope in D-60/D-61; this is tracking of that approved scope, not approval of a failed approximation. **Normative design and acceptance:** [ISM structure and dust, AC5 and AC6(c)](../../implemented/r1/ism-structure-and-dust.md). **Depends on:** PR A, published celestial/relativity packages, independently validated dense data. **Estimate:** retained original I3b estimate of 520 LOC/three days; not a fresh schedule commitment.

PR A ships only the LIC, fourteen local warm clouds and hot Local Bubble gas. This follow-up holds the Edenhofer et al. 2024 mean-map extraction and the Local Leo Cold Cloud. Nothing in PR A's evaluation waives the checks below.

## Current evidence

The isolated `finish/ism-dense-20261010` worktree extracts the real NEST mean FITS map, cropped to 151 shells below 160 pc, and passes 60 synthetic axis-order assertions and 120 independent pixel references. The proposed threshold-clump representation nevertheless passes only 1/20 independent extinction directions within the factor-two bound. Taurus and Ophiuchus near-side distances fail the 15 pc tolerance; Lupus passes. Raw Leike comparison passes 19/20 directions, so the clump representation remains suspect.

For the LLCC, five absorption/non-detection classifications pass, while the Na I-only HD 84937 sight line lies outside the adopted 21 cm outline. An outline change needs independent scientific support. No fixture fitting, geometric enlargement solely to pass a test, runtime integration or scientific waiver is accepted here.

## Required gates before integration

| Gate | Acceptance and check |
|---|---|
| AC5 | Taurus/Ophiuchus/Lupus near-side distances within 15 pc of the cited anchors; integrated extinction in 20 directions within factor two of Leike et al. 2020; synthetic FITS passes in both axis orders. In the isolated PR B worktree: `make fits-slice-test ism-dense-test` and `python3 tools/ism_dense_ref.py --sources FITS LEIKE_H5 CROP_PREFIX` (the oracle reads the pinned downloaded inputs). |
| AC6(c) | Supported LLCC outline contains absorption stars and excludes non-detections; a crossing route is refused at 0.999999c and accepted at 0.998c. Isolated sight lines: `python3 tools/ism_dense_ref.py`. Planned runtime hold checks must be added to `make ism-test` before integration. |
| Runtime/map | Generated fields retain provenance, every integrated medium draws, routes preserve ordered crossings, and frozen uniform replays remain unchanged: `make ism-data-verify map-ism-test ism-compat ism-determinism`. These existing targets must gain dense fixtures; a local-only PASS does not cover PR B. |
| Landing | `make test` locally and in matching CI, `make golden`, opened dense/refusal references from `make ism-capture`, source/license credits and independent evaluator PASS. |

The original combined design/sprint retains the exact acceptance criteria. Resolve the representation and LLCC evidence before proposing integration; the dataset may remain deferred without blocking PR A or the M4 journey audit.
