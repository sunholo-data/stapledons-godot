# One position per star: a star-truth table for navigation and the sky

| Pillar | Alignment | Reason |
|---|---:|---|
| Choices Are Final | +1 | A committed journey arrives where the player saw the star. |
| The Game Doesn't Judge | +1 | Each position carries its source and uncertainty; disagreements are reported, not hidden. |
| Time Has Emotional Weight | 0 | No change. |
| The Ship Is Home | 0 | No change. |
| Grounded Strangeness | +2 | Arrivals at real stars look right at a 1,000 AU stand-off, where catalogue disagreements become visible. |
| We Are Not Built For This | 0 | No change. |

Net +4: aligned.

**Status:** Approved by Mark, attended 2026-10-07 (selected for dev.20). Proposed 2026-10-06 (Mark, attended: "write them up as design docs").
**Release:** R1 follow-up, before map journeys to Gaia-only stars are promoted.
**Implements:** [starmap data model](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase1-data-models/starmap-data-model.md); the [relativity spec](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md) parallax and photometry sections.
**Depends on:** the M1.2b–M1.7 catalogue pipeline (`sim/tools/bright_main.ail`, `make catalogue`, `make starmap`) and the companion rule (`m1-companion-parallax.md`).
**Estimated scope:** about 700 LOC (AILANG pipeline and tests 450, Godot checks 150, audit report 100).

## Problem

Navigation and the sky use different catalogues for the same stars:

- **Navigation:** `data/starmap/stars.json` (5,685 destinations within 25 pc) is built from CNS5 plus the bright tier.
- **The ship's sky:** draws the GCNS **medium tier** (50,000 nearest), with CNS5 contributing only its HIP-filled rows.

Measured on 2026-10-06 over the **5,105 stars present in both** (matched by Gaia source id), the rendered and navigated positions differ by:

| Statistic | ly | AU |
|---|---|---|
| Median | 0.021 | 1,333 |
| 90th percentile | 0.090 | 5,685 |
| Maximum | 8.71 (a star at 61 ly) | 550,832 |

The median relative difference is 3.9 × 10⁻⁴. That's two distance estimators applied to the same Gaia astrometry: CNS5 inverts parallax, while GCNS table1c publishes a posterior distance. It's invisible from Earth. But the ship stops 1,000 AU short of its target, so it matters on arrival:

- **TRAPPIST-1** rendered 0.042 ly (about 2,700 AU) from where the ship stopped, and so did not appear ahead.
- The guided tour now pins its own destinations (`Starfield.pin_destination`), but **ordinary map journeys are still affected**, and so is any star the player inspects up close.
- The **outliers of several light-years (10–14 %)** are not estimator noise. They're either cross-match errors or a poor parallax in one source, and nobody has looked at them yet.

## Goals

1. **One identity, one position.** Every star that more than one source knows has a single position, used by navigation (`stars.json`), every render tier, inspection and the simulation.
2. **A source-of-truth table, `data/starmap/truth/`.** One committed CSV row per multi-source star:
   - identity and aliases (Gaia DR3 id, CNS5, HIP, name);
   - the chosen x, y, z (galactic, ly, float64);
   - the source of each field;
   - the distance uncertainty in ly.

   The pipeline reads it; nothing else decides positions. Updating a star means editing or regenerating its row with a citation, which is the "living data" rule of D-41 applied to stars.
3. **A stated precedence rule.** The default, open question 1, is:
   - Gaia DR3 astrometry with a single estimator everywhere: 1/ϖ when ϖ/σ_ϖ ≥ 10, otherwise the GCNS posterior median;
   - then Hipparcos (van Leeuwen 2007) for stars too bright for Gaia;
   - then CNS5's compiled value.

   Companions keep their system's distance (the existing ruling).
4. **An audit of every disagreement** above max(3σ, 1 %). Each case is resolved and written up in `design_docs/implemented/r1/starmap-truth-audit.md`, as one of:
   - a cross-match error;
   - a better parallax;
   - a genuinely uncertain distance, which stays labelled.
5. **Guarded.** `pin_destination` stays, but as an assertion: after this work it must be a no-op, with the pinned position equal to the tier position.
6. **Ready for Gaia DR4** (expected December 2026). A DR4 refresh is a re-run of the truth step plus the audit diff, with no code change.

## Non-goals

- New stars (see `starmap-large-tier-and-reach.md`).
- Proper motion over game time.
- Anything beyond 100 pc (see the design repo's galaxy-beyond-measurement feature).

## Design

- **T1. Truth step (AILANG, `sim/tools/truth.ail`).** Joins CNS5, GCNS and HIP by identity (Gaia id first, then the existing HIP/CNS5 cross-match), applies the precedence rule and writes `data/starmap/truth/positions.csv` plus a sidecar (counts, sha256 and the rule version). It's pure apart from file I/O in its `main`, and runs on the VM with strict-VM checks equal to the interpreter, as the other catalogue steps do.
- **T2. Consumers.** `make catalogue` (all tiers) and `make starmap` take positions from the truth table when a row exists. Tier sidecars gain `truth_sha256`.
- **T3. Audit.** `make starmap-truth-audit` lists every star over the threshold, with both sources, σ and the deciding reason. The resolved list is committed. Unresolved rows keep the precedence default and are flagged in inspection ("distance uncertain").
- **T4. Consistency gate.** `make starmap-consistency` (headless):
  - every `stars.json` destination is present in the sky stack under some alias, at a position equal to the navigation position within float64 round-off;
  - no identity is rendered twice;
  - `pin_destination` is a no-op for all 5,685 destinations.

## Acceptance criteria

| # | Criterion | Command |
|---|---|---|
| AC1 | The truth table is built on the VM, matches the interpreter byte for byte, and records every row's source | `make starmap-truth` + `make starmap-truth-parity` |
| AC2 | Rebuilt tiers and `stars.json` take truth positions; `catalogue-verify` is reproducible | `make catalogue-verify` |
| AC3 | All 5,685 destinations agree between navigation and sky (max offset ≤ 1e-9 ly); no duplicates; pins are no-ops | `make starmap-consistency` |
| AC4 | Every disagreement above max(3σ, 1 %) appears in the audit with a resolution | `make starmap-truth-audit` |
| AC5 | A map journey to TRAPPIST-1 and to the three worst outliers arrives with the star ahead at the stand-off (rendered, opened) | capture tool |
| AC6 | Gate 1 | `make test` |

## Risks

- **Changing positions moves arrival points and replays.** Mitigation: re-record replays with the reason, and diff the map before and after.
- **The GCNS posterior vs 1/ϖ choice shifts thousands of stars slightly.** Mitigation: the rule is versioned in the sidecar and the audit shows the distribution.

## Open questions for Mark

1. The precedence rule (goal 3). Default: Gaia DR3 with one estimator, Hipparcos for very bright stars, CNS5 last.
2. Should unresolved, genuinely uncertain distances be shown to the player ("± 3 ly")? Default: yes, in star inspection.
