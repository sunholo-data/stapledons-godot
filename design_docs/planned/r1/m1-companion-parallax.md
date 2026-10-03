# M1 follow-up: companion stars take their system's distance

**Status:** implemented on `fix/companion-parallax` (awaiting review). **Release:** R1, M1 (catalogue).
**Priority:** P1 (Sirius B is a named destination in the replay goldens' map).
**Ruling:** Mark, attended 2026-10-03: the general rule (any companion within N″ of a brighter star
takes that star's system distance, in the catalogue pipeline, for every tier). Folds in D-19 rule (c)
(α Cen B). The parameters below are this note's proposal under that ruling.
**Implements:** stapledons-design `features/galaxy-map` (catalogue distances, D-17), M1.2d rule (c)
generalised. No SR/GR maths: positions only; no `sunholo/relativity` change.
**Evidence:** `.ailang/state/evaluations/eval_R1-M1-SKY-2-M1.7_round_1.json` (finding 2, Sirius B recommendation).
**Code:** `sim/tools/companions.ail` (pure), `sim/tools/bright_main.ail` (shells), `data/starmap/companions/companions.csv`.

## Game vision alignment

| Pillar | Relevance | Score | Notes |
|---|---|---|---|
| Choices Are Final | 0 | 0 | |
| The Game Doesn't Judge | 0 | 0 | |
| Time Has Emotional Weight | 0 | 0 | |
| The Ship Is Home | 0 | 0 | |
| Grounded Strangeness | + | +1 | Binary systems read as systems; a player flying to Sirius finds B beside A, not 0.1 ly beyond |
| Hard sci-fi authenticity (spec) | ++ | +2 | Removes a catalogue artefact (a companion's corrupted parallax) with a cited, tested, oracle-checked rule |
| **Net** | | **+3** | **Go** |

## Problem

A companion row sits at its own parallax, which for a close pair is the worst-measured number in the
catalogue (the primary's glare and the orbit corrupt it, and Gaia's quoted errors on such pairs are too
small). Today: Sirius B 8.709 ly vs A 8.601 ly (a ~20 AU pair shown 6,800 AU apart in depth); Luyten 726-8
B 0.092 ly from A; Wolf 424 B 0.481 ly from A. M1.7 evaluation: 422 row pairs within 30″ in the 25 pc map,
269 differing by more than 0.05 ly. α Cen B had a one-star override (rule c).

## The rule

Candidates: every star of CNS5 (`cns5.dat`), GCNS (`table1c.dat.gz`) and the bright tier (HIP2 rows kept
by rule a), one record per star (a GCNS row whose Gaia id is a CNS5 row is that row). Positions compared
at J2016.0, each star moved by its own proper motion from its own epoch. Star *q* is a companion of *p* when
*p* outranks *q* (brighter: G, or Hipparcos V for bright rows; ties: smaller parallax error, then id) and

| # | Test | Value | Why |
|---|---|---|---|
| 1 | angular separation | **N = 60″** | covers the CNS5 systems that matter (Sirius 7″ at J2016, α Cen 12″, GJ 667C 34″, GJ 166 BC 8″) |
| 2 | projected separation at *p*'s distance | **≤ 2,000 AU** | binds beyond 33 pc, where chance alignments grow (GCNS, 100 pc) |
| 3 | parallax agreement | **\|Δϖ\| ≤ 0.20 ϖ_p, and (≤ 0.05 ϖ_p or ≤ 3σ)**, σ = √(σ_p²+σ_q²) | 3σ alone rejects the very pairs to fix (Luyten 726-8 6.3σ, Wolf 424 9.8σ); 5% admits them; 20% is a hard cap so a chance background star can never be pulled in |
| 4 | proper-motion agreement | **\|Δμ\| ≤ max(0.44 ϖ_p^1.5 θ^-0.5 mas/yr, 0.2 \|μ_p\|)** | orbital-motion bound (El-Badry, Rix & Heintz 2021, MNRAS 506, 2269), or a fifth of the primary's motion for unresolved Hipparcos primaries |

Each star's parent is its brightest qualifying neighbour; its **root** is the end of the parent chain. A
companion takes the **root's parallax** (the brightest star of the system, normally the best measured),
along its own direction (CNS5/GCNS rows: scaled from the catalogue position; bright rows: the HIP2
direction moved to the root's epoch, exactly rule (c)'s arithmetic). **Why not a weighted system
parallax:** it would move the primaries (α Cen A, Sirius A: the replay goldens' targets) and weight in the
corrupted companion astrometry the rule exists to discard. No primary row moves.

**Pinned:** every tier build refuses a table in which Sirius B → CNS5:1676, α Cen B (HIP 71681) →
CNS5:3627, Luyten 726-8 B → A, Wolf 424 B → A does not hold.

## Counts (inputs as pinned in `data/sky/SHA256SUMS`)

| | |
|---|---|
| Companions, all catalogues | **20,524** (20,460 with a Gaia root, 52 with a HIP root, 12 with a CNS5-only root) |
| in the quick tier (CNS5) | 525 (524 records change; one moves below float32 resolution) |
| in the 25 pc map | 508 rows change; 3 leave the map (moved past 25 pc), 1 joins |
| in the medium tier | 3,378 → 3,371 companions; 45 move out past the 50,000 cut and 45 rows move in |
| in the bright tier | 5 (α Cen B bytes unchanged; 4 rows move) |
| Chance-alignment estimate (sky rotated 0.5–2°, 4 trials) | 0.2 per sky in CNS5, ~15 per sky in GCNS against ~20,600 real (0.07%) |

Shape exploration (Python spike, not tracked): N 30/60/120″ × 1,000/2,000/5,000/10,000 AU; 60″/2,000 AU
keeps 530 of 544 CNS5 pairs within 60″ with no chance pairs, and keeps GCNS chance pairs under 0.1%.
10,000 AU (the brief's example) never binds inside 100 pc at 60″ and lets GCNS chance pairs reach ~1%.

**False pairs rejected (examples, all real lines):** GJ 604 and a GCNS star 43″ away at 307 ly vs 48 ly
(parallaxes 84% apart, `tools/fixtures/table1c_companions.dat`); GJ 13207/13208 (102″, 87% apart); about
30 CNS5 stars with a background GCNS star inside 60″ at 120–360 ly (e.g. GJ 3995, 75 ly, and a G 8.6 star at
324 ly, 13″); CNS5 rows without a Gaia id that coincide with a GCNS source at another parallax (CNS5:5853,
3492, 5793, 1904).
**Known misses (real pairs the tolerances reject), all beyond 38 ly:** GJ 428 B (17%, 5σ), GJ 1294 B, GJ
11385 B, GJ 3332 B and 13235 B and 9257 C (proper motion), GJ 11665 B, 12447 B, 11869 C/11871 B, 818.1 C,
3431 B, 55.3 B, 894.2 B (13%, proper motion). Within 25 ly every pair the M1.7 evaluation listed is captured.

## Where it runs

`make companions` (VM, ~70 s, 5.8 GB peak) writes `data/starmap/companions/companions.csv` (2.4 MB, in a `.gdignore` folder so Godot does not import the CSV as a translation or ship it; one line per
companion, floats in shortest round-trip form, input digests in `#` lines). `std/gzip` stops at 100 MB, so
the Makefile gunzips `table1c.dat.gz` into the scratch dir (glue) and both digests are recorded. Every
tier (`quick`, `medium`, `large`, `bright`) and `stars.json` read the table, refuse it unless the pinned
outcomes hold, apply it before the tier selection, and record its sha256 plus a `companions` count.
`bright_overrides.json` is retired.

## Acceptance criteria

| Criterion | Command |
|---|---|
| thresholds, Sirius B, α Cen B bytes unchanged, Luyten 726-8 B, Wolf 424 B, false pairs, order independence, table round trip; strict VM = interpreter | `make companions-test` |
| bright tier without rule (c) | `make bright-test` |
| table, tiers and map rebuild byte-identically; Python oracle agrees on every non-HIP row | `make catalogue-verify` |
| map, names, goldens | `make starmap-test`, `make test`, `make replay`, `make golden` |
