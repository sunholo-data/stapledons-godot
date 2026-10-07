# Sprint R1-STARMAP-TRUTH: one position per star

**Design doc:** [starmap-single-truth.md](starmap-single-truth.md) (feature context: design repo PR sunholo-data/stapledons-design#9).
**Status:** Approved by Mark, attended 2026-10-07 (selected for dev.20).
**Estimate:** about 750 LOC, 2.5 days. Branch `sprint/starmap-single-truth`.
**Risk:** medium. Rebuilding the medium tier moves about 5,100 sky stars by up to 8.7 ly; the replay goldens and the guided tour must not move.

## What the data says (measured 2026-10-07, before planning)

The design's diagnosis needs one correction, and it changes the precedence rule's effect, not its intent.

- **No catalogue in the pipeline uses the GCNS posterior distance.** `sim/tools/extract.ail` writes both `cns5.csv` and `gcns.csv` at 1/ϖ. Every disagreement is between the two *parallaxes*, and it is purely radial: the directions agree.
- **5,203 stars are in both CNS5 and GCNS** (by Gaia id). CNS5's parallax source (`r_plx`) splits them:

| CNS5 adopted parallax | Stars | CNS5 − GCNS ϖ | Gaia EDR3 RUWE |
|---|---:|---|---|
| Gaia EDR3 (`2020yCat.1350`) | 5,134 | median +0.028 mas, at most 0.083 mas | any |
| Hipparcos, van Leeuwen 2007 | 50 | up to 8.9 mas | all ≥ 1.4 |
| Gaia DR2 | 19 | up to 4.8 mas | 15 of 19 ≥ 1.4 |

  The EDR3 offset is the Lindegren et al. (2021) zero-point correction, which CNS5 applies and GCNS does not. The several-light-year outliers are the 69 stars where CNS5 rejected a poor EDR3 solution (RUWE up to 16, unresolved binaries) for Hipparcos or DR2.
- Under the design's default ("Gaia DR3 first"), those 69 stars would move to their worst-measured parallax. The design's own precedence (Hipparcos for stars Gaia cannot measure) and its audit rule ("a better parallax") both point the other way.

**Rule `truth-1` (implemented; open question 1 stays open for Mark):** a star that CNS5 lists takes CNS5's adopted parallax and position everywhere. That is Gaia EDR3 with the zero-point correction for 5,134 stars, and Hipparcos or DR2 where CNS5's evaluation rejected EDR3. GCNS (raw EDR3) is used for stars CNS5 does not list. Every distance is 1/ϖ, and companions keep their system's distance. With this rule the navigation catalogue `stars.json` and the quick tier do not move; the GCNS tiers move onto them. The rule version is recorded in every sidecar, so changing it later is a re-run.

## Milestones

| ID | Work | LOC | Acceptance (design AC) |
|---|---|---|---|
| ST1 | `sim/tools/truth.ail`: parse CNS5 (`cns5.dat`, `cns5.csv`), GCNS (`table1c.dat`, `gcns.csv`), the companion table's cross-identifications; the join, rule `truth-1`, the disagreement test max(3σ, 1 %), the resolution, the CSV. `truth_test.ail` first: named checks, strict VM = interpreter | 320 | AC1, AC4 |
| ST2 | `truthMain` shell; `make starmap-truth` writes `data/starmap/truth/positions.csv` + `positions.json` (rule, counts, input sha256); `make starmap-truth-parity` (VM = interpreter, byte for byte) | 90 | AC1 |
| ST3 | Consumers: `gcnsMain` (medium, large) substitutes truth positions before the companion rule, relabels CNS5-only cross-identifications and drops GCNS duplicates of bright rows; quick and the map apply the same table (identity on rule `truth-1`); sidecars and `stars.json` gain `truth_sha256`; tiers rebuilt; `make catalogue-verify` | 110 | AC2 |
| ST4 | `Starfield`: on GCNS tiers stack every quick row whose identity the tier lacks (not only HIP-filled rows); restore float64 positions of destinations from `stars.json` (a precision step, refused beyond 1e-4 ly); an identity index; `pin_destination` becomes an assertion (no-op when the sky already agrees, warns and falls back otherwise); `test_destination_pin.gd` and `test_physics.gd` updated | 130 | AC3 |
| ST5 | `tools/starmap_consistency.gd` → `make starmap-consistency` (in `make test`); `make starmap-truth-audit` (every disagreement has a resolution and appears in the audit doc); `design_docs/implemented/r1/starmap-truth-audit.md` | 140 | AC3, AC4 |
| ST6 | Arrival renders (TRAPPIST-1 and the three worst outliers, before and after), opened; `make test`; CHANGELOG; sprint JSON; PR | 60 | AC5, AC6 |

## Acceptance by command

| AC | Command | Pass |
|---|---|---|
| AC1 | `make starmap-truth starmap-truth-parity AILANG=runtime/bin/ailang` | table rebuilt identical to the committed one; VM = interpreter |
| AC2 | `make catalogue-verify AILANG=runtime/bin/ailang` | every committed tier, `companions.csv` and `stars.json` rebuilt byte-identical |
| AC3 | `make starmap-consistency` | 0 offsets over 1e-9 ly, 0 missing drawable destinations, 0 duplicate identities, pins are no-ops |
| AC4 | `make starmap-truth-audit AILANG=runtime/bin/ailang` | every disagreement row resolved and listed in the audit doc |
| AC5 | arrival capture (`tools/starmap_arrival_capture.gd`) | star centred at the 1,000 AU stand-off; PNGs opened |
| AC6 | `make test AILANG=runtime/bin/ailang` | green |

## Risks and mitigations

- **Replays and the tour.** Navigation positions do not move under `truth-1`, so the replay goldens and the tour's pins do not change. `make replay` and `make test` confirm it.
- **Load time.** The identity index and the overlay add one pass over the stack. Measure `load_tiers` time on medium and large, and keep it under 0.5 s on large.
- **table1c.dat is 250 MB uncompressed.** Same pattern as `make companions`: gunzip into the scratch directory and parse only CNS5 ids.
