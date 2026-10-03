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
by rule a), **one record per star**:
- a GCNS row whose Gaia id is a CNS5 row is that row;
- **cross-identifications** (round-1 evaluation, finding 3): a GCNS source that is not in CNS5 but lies
  within 2″ of a CNS5 row *without* a Gaia id, or of a bright (HIP) row, with the pair test's parallax and
  motion agreement (and |G − V| < 0.5 for a HIP row), is that same star under another name. Its GCNS record
  is dropped before pairing, so a star is never "its own companion". 9 today: CNS5:138, 252 (GJ 10136, 0.024″;
  it no longer moves 95.9 → 109.4 ly), 2733 (GJ 417 BC), 2934, 4157, 528, 65, 898, and HIP 27890 (HD 40409,
  1.03″ from its Gaia source, which rule (a)'s 1″ GCNS match missed: its Hipparcos and Gaia motions differ
  by 36 mas/yr. Widening rule (a) would change ruling D-5, so that is left for Mark). They are listed in the
  table's `# same:` lines. The other sub-0.2″ links of round 1 stay companions: CNS5 lists them as a "B"
  component on its primary's position (CNS5:136, 191, 2708, 3192, 3259, 4333, 5630), and their partner is a
  CNS5 row.

Positions are compared at J2016.0, each star moved by its own proper motion from its own epoch. Star *q*
is a companion of *p* when *p* outranks *q* (brighter: G, or Hipparcos V for bright rows, a mixed scale
that is harmless for today's 4 bright links; ties: smaller parallax error, then id) and

| # | Test | Value | Why |
|---|---|---|---|
| 1 | angular separation | **N = 60″** | covers the CNS5 systems that matter (Sirius 7″ at J2016, α Cen 12″, GJ 667C 34″, GJ 166 BC 8″). **Inside 33 pc this cap binds before the AU cap** (600 AU at 10 pc, 300 AU at 5 pc), so in the 25 pc map the limit is angular: ε Ind A–B (402″) and 40 Eri A–BC (83″) stay outside, harmlessly since their parallaxes already agree |
| 2 | projected separation at *p*'s distance | **≤ 2,000 AU** | binds beyond 33 pc, where chance alignments grow (GCNS, 100 pc) |
| 3 | parallax agreement | **\|Δϖ\| ≤ 0.20 ϖ_p, and (≤ 0.05 ϖ_p or ≤ 3σ)**, σ = √(σ_p²+σ_q²) | 3σ alone rejects the very pairs to fix (Luyten 726-8 6.3σ, Wolf 424 9.8σ); 5% admits them; 20% is a hard cap so a chance background star can never be pulled in |
| 4 | proper-motion agreement | **\|Δμ\| ≤ max(0.44 ϖ_p^1.5 θ^-0.5 mas/yr, 0.2 \|μ_p\|)** | orbital-motion bound (El-Badry, Rix & Heintz 2021, MNRAS 506, 2269), or a fifth of the primary's motion for unresolved Hipparcos primaries |

Each star's parent is its brightest qualifying neighbour; its **root** is the end of the parent chain. A
companion takes the **root's parallax**, along its own direction (CNS5/GCNS rows: scaled from the catalogue
position; bright rows: the HIP2 direction moved to the root's epoch, exactly rule (c)'s arithmetic).

**Every tier puts the root row with its companions** (round-1 finding 1). In quick and bright the root's row
is the root's own record. In the GCNS tiers (medium, large) a root whose record is a CNS5 row also has a
GCNS row at its EDR3 parallax; that row moves to the root record's parallax too (488 such roots in medium,
e.g. Luyten 726-8 A 367.7 → 369.9 mas). Every tier build, and the map, then refuses unless each companion
whose root is a row of that tier is at the root's distance within 1e-5 ly (`checkTier`).

**Why the root, not a weighted mean, and not the most precise member.** Mark ruled system distance. A
weighted mean would move the primaries (α Cen A, Sirius A: the replay goldens' targets) and would be
dominated by the corrupted companion astrometry the rule exists to discard. "Most precise wins" fails on the
motivating case: Sirius B's Gaia parallax (374.51 ± 0.26 mas) is formally five times more precise than
Sirius A's Hipparcos value (379.21 ± 1.58) but is biased by A's glare, 1.2% low (2.9σ of the combined error);
α Cen B (Hipparcos 796.92 ± 25.9) is the same story the other way. **The cost, stated:** of the 20,462
CNS5/GCNS links, **4,396 (21%) give the companion a less precise parallax than its own**, and in **114** the
root's error is over 3× the companion's and the move is over 5%: listed in
[m1-companion-parallax-precision.csv](m1-companion-parallax-precision.csv) (`tools/check_companions.py
--precision`). Example: CNS5:3950 (GJ 12312 A, Hipparcos 43.67 ± 2.14) moves two clean Gaia companions
(40.68 ± 0.07, 40.84 ± 0.20) from 80.0 to 74.7 ly. Follow-up for Mark: for wide pairs whose members all have
clean Gaia solutions, a precision-weighted system parallax that moves the root too (Sirius and α Cen have
Hipparcos roots and would be untouched).

**Pinned:** every tier build refuses a table in which Sirius B → CNS5:1676, α Cen B (HIP 71681) →
CNS5:3627, Luyten 726-8 B → A, Wolf 424 B → A does not hold.

## Counts (inputs as pinned in `data/sky/SHA256SUMS`)

| | |
|---|---|
| Companions, all catalogues | **20,515** (+ 9 cross-identifications dropped as the same star) |
| in the quick tier (CNS5) | 517 (516 records change; one moves below float32 resolution) |
| in the 25 pc map | 505 rows change; 3 leave the map (moved past 25 pc), 1 joins |
| in the medium tier | 3,371 companions + 488 CNS5-record roots moved; 45 companions move out past the 50,000 cut and 45 rows move in |
| in the bright tier | 4 (α Cen B bytes unchanged; 3 rows move) |
| Chance alignments (`tools/check_companions.py`, evaluator's method) | **0 per sky** at both rotations |

**Chance alignments, method:** a CRC32-selected half of all 332,017 candidate stars is rotated in RA by 0.7°
and by 1.9°; a pair whose members fall in different halves and pass the rule can only be a chance alignment
(×2 for the whole sky). Both rotations give 0, i.e. fewer than about 6 per sky at 95%. The oracle runs this
in `make catalogue-verify` and fails above 10 per sky.

Shape exploration (Python spike, not tracked): N 30/60/120″ × 1,000/2,000/5,000/10,000 AU. 60″/2,000 AU kept
530 of 544 CNS5 pairs within 60″; 10,000 AU never binds inside 100 pc at 60″.

**False pairs rejected (examples, all real lines):** GJ 604 and a GCNS star 43″ away at 307 ly vs 48 ly
(parallaxes 84% apart, `tools/fixtures/table1c_companions.dat`); GJ 13207/13208 (102″, 87% apart); about
30 CNS5 stars with a background GCNS star inside 60″ at 120–360 ly (e.g. GJ 3995, 75 ly, and a G 8.6 star at
324 ly, 13″); CNS5 rows without a Gaia id that coincide with a GCNS source at another parallax (CNS5:5853,
3492, 5793, 1904).
**Known misses (real pairs the tolerances reject), all beyond 38 ly:** GJ 428 B (17%, 5σ), GJ 1294 B, GJ
11385 B, GJ 3332 B and 13235 B and 9257 C (proper motion), GJ 11665 B, 12447 B, 11869 C/11871 B, 818.1 C,
3431 B, 55.3 B, 894.2 B (13%, proper motion). Within 25 ly every pair the M1.7 evaluation listed is captured.

## Where it runs

`make companions` (VM, ~70 s, 5.8 GB peak) writes `data/starmap/companions/companions.csv` (2.4 MB, in a
`.gdignore` folder so Godot does not import the CSV as a translation or ship it; one line per companion
with its root's catalogue, floats in shortest round-trip form, input digests and the cross-identifications
in `#` lines). `std/gzip` stops at 100 MB, so the Makefile gunzips `table1c.dat.gz` into the scratch dir
(glue) and both digests are recorded. Every tier (`quick`, `medium`, `large`, `bright`) and `stars.json`
read the table, refuse it unless the pinned outcomes hold, apply it before the tier selection, refuse a
split pair, and record its sha256 plus `companions` (and `companion_roots` in the GCNS tiers) counts.
`bright_overrides.json` is retired.

## Acceptance criteria

| Criterion | Command |
|---|---|
| thresholds, Sirius B, α Cen B bytes unchanged, Luyten 726-8 B, Wolf 424 B, false pairs, cross-identifications (GJ 10136, HD 40409), GCNS-tier root move and tier check, order independence, table round trip; strict VM = interpreter | `make companions-test` |
| bright tier without rule (c) | `make bright-test` |
| table, tiers and map rebuild byte-identically; Python oracle agrees on every non-HIP row and on the cross-identifications, map pairs sit together, chance alignments ≤ 10 per sky | `make catalogue-verify` |
| map, names, goldens | `make starmap-test`, `make test`, `make replay`, `make golden` |
