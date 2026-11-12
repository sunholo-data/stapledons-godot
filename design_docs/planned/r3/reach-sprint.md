# Sprint R3-REACH: plan (RE0 and RE1)

**Design:** [reach.md](reach.md), approved by Mark 2026-11-12 ("ok good yes this looks great") with OQ1–OQ6 as recommended.
**Status:** Approved by Mark, attended 2026-11-12 ("ok good yes we can go with these"); executing. RE0 first; the three stops stand.
**Scope:** RE0 (measurements) and RE1 (the measured 100 pc tier: registry, plan by id, the imaging and radio queries, protocol 2.20, the map to 326 ly). RE2 (cells to 1,000 ly) and RE3 (3,000 ly) get their own plans after RE1's dev build.
**Progress file:** `.ailang/state/sprints/sprint_R3-REACH.json`
**Branches:** this plan on `design/r3-reach` (draft PR #437). Execution in a fresh full clone `../stapledons-godot-reach-exec`, never the main checkout; one PR per milestone group (RE0, RE1a, RE1b, RE1c, RE1d).
**AILANG:** pin v0.56.1 (`runtime/bin/ailang`, staged by `make runtime`). AILANG prompt version loaded: **v0.16.11** (`runtime/bin/ailang prompt --version-active`, 2026-11-12; the prompt itself was loaded for this plan). Reload with `ailang prompt` before the first `.ail` edit of each session.

## What the player gets at the end

The map zooms out to 326 ly. About 295,000 real stars can be chosen as destinations. A star the dish can hear at 100 to 168 ly now exists in the game, with planets and a history, and can be flown to. Signals themselves appear only when the evidence ledger lands (see Dependencies).

## Rulings carried in (not gates)

- OQ1: RE1 alone goes to a dev build before RE2 is planned.
- OQ2: decided by RE0b's Gaia count (full sample to 1,000 ly if it fits 200 MB, else brightness-limited). It affects RE2 only.
- OQ3: the 48,860 RUWE-only failures are destinations, flagged "probable binary". The 1,385 poor-parallax and 5,929 no-colour stars are hosts, not destinations, but become selectable if they ever carry an evidence record.
- OQ4, OQ5: RE2 matters only.
- OQ6: a leg beyond the modelled ISM is allowed with the label; RE1b1 adds the sim field, RE1d4 shows it.
- **The calibration caution** (design, Problem 3): the density of technological worlds will change. No budget here depends on 8 × 10⁻⁴ per star; RE0a and RE1b3 run every query budget at that density **and at ten times it**.

## Dependencies on other work

- **Protocol minor.** 2.19 is reserved by R3-REASONS RT2b. This sprint takes **2.20**; RE1c1 re-reads `SimBridge.SESSION_MINOR` first. If RT2b has not landed, 2.20 still follows 2.19's reserved number and the two merge in either order.
- **Used in play only with the evidence ledger.** RE1b2's queries are called by R3-REASONS RT2 (`sim/evidence.ail`), which waits on `sunholo/observe` 0.2.0, built but unpublished (ailang#2277). Until then RE1 delivers destinations and worlds, tested queries, and no marks.
- **The preset ruling is pending.** Nothing in RE1 reads a preset's values.
- **One playable dev build** (CLAUDE.md, 2026-11-09): the landing build is combined with current main and whatever else is in the shared `--dev` channel.

## Registry reuse (searched 2026-11-12 with the pinned binary: `ailang pkg search` for `catalogue`, `starmap`, `spatial index`, `octree`, `gaia`, `binary`)

No package offers a star catalogue, a spatial index or a binary reader. The two hits (`sunholo/relativity` for "gaia", `sunholo/duckdb` for "binary") are unrelated matches.

| Milestone | Package | Action | Reason |
|---|---|---|---|
| RE0a, RE1b2, RE1b3 | `sunholo/worlds` 0.2.0 | depend | Histories and the one-draw gate already exist; RE1 adds no science. (The cell density and selection function are RE2's contribution, 0.3.0) |
| RE1b1 | `sunholo/relativity` 0.12.0 | depend | `planBurnCoastBurn` for the long-leg check rows |
| RE1a1, RE1a2 | none | none | Game data pipeline over this repo's truth table; `sim/tools/catalogue_bytes.ail` (in-repo) is reused for the float bytes |
| RE0b, RE1b1, RE1c1, RE1c2, RE1d0–RE1d4 | none | none | Game sim, protocol and Godot code |

A grid index over points is generic, but it is 60 lines here and has one user. It stays in the sim; RE2's plan revisits it when the cell generator needs it too.

## Milestones

Each is sized for one executor run (60–90 min). Gates are targeted and headless. **No `make test`, no `make golden`, no rig run and no GPU run is a merge gate.** Every new Godot `--script` target is written through `$(SCRIPT_GATE)` (the fast tier's `script-gate-lint` rejects a bare one), and every new `.gd` is committed with its `.uid`.

| ID | What | LOC | Routing | Depends | Gates |
|---|---|---|---|---|---|
| RE0a | VM probes on the pinned runtime, as `sim/tools/reach_probe.ail` and `make reach-probe`: the keyed-draw rate; the one-draw gate over 43,887 and 302,239 rows; full `systemFrom` over 1,900 rows; the cost of returning 34 and 340 rare worlds from the radio sphere (the ten-times case). Three runs each, host load recorded | 80 | loop | — | `make reach-probe` writes `data/reach/probe.json`; counts identical across runs and VM = interpreter on a 5,000-row subset |
| RE0b | A probe that reads and decodes a 13 MB float64 binary in `ship.ail`-style FS code (time, peak RSS), and the per-leaf read as the fallback. The Gaia DR3 count beyond 100 pc: one archive `COUNT` per distance band (to 1,000 and 3,000 ly) at ϖ/σ ≥ 5 and at G < 14, by a shell script with a generic client. The leaf size (40 ly) confirmed or changed, with the numbers | 70 | loop | — | `make reach-probe-io`; `tools/gaia_count.sh` output pinned in `data/reach/gaia_counts.json` with the query text and date |
| ⏸ 1 | **Stop for Mark: RE0's measurements.** The budgets that become gates, the ten-times result, the Gaia sizes (which settles OQ2's branch), the frozen leaf size. If a budget fails at ten times, the plan changes here, before any feature code | — | attended | RE0a, RE0b | — |
| RE1a1 | The registry builder, pure part (`sim/tools/reach_registry.ail` + test): rows from the truth table with parallax ≥ 10 mas, minus ids already in `stars.json`; quality flags (destination, RUWE-fail, parallax-fail, no-colour) read from `table1c.dat` because `gcns.csv` does not carry them; the leaf sort; the 44-byte row encoding | 200 | loop | ⏸ 1 | `make reach-registry-test` (named checks on fixtures: counts by flag, a duplicate, a 25 pc star excluded, byte layout); strict VM = interpreter |
| RE1a2 | The FS entry and targets: `make reach-registry` (bin + sidecar with the leaf index and input shas), `reach-registry-parity`, the pin in `data/starmap/SHA256SUMS`, the fetch in `starmap-assets`, `starmap-consistency TIER=reach`. **Publishing to the public bucket is attended** | 150 | loop, then attended publish | RE1a1 | `make reach-registry` reports 302,239 minus the `stars.json` overlap, 295,010 destination flags in total with `stars.json`'s; `make reach-registry-parity`; `make starmap-consistency TIER=reach`; after the publish, `rm data/starmap/reach_100pc.*; make starmap-assets` |
| RE1b1 | `sim/reach.ail` (pure): the leaf index over registry rows, a star by id, plan by id with refusals (`unknown_star`, `not_a_destination` unless it has an evidence record); the `beyond_surveyed_medium` plan field (OQ6); the registry read in `sim/ship.ail`, refusing a missing or mismatched file | 250 | loop | RE1a2 | `make reach-test` (AC5: position equals the truth table to 1e-9 ly; legs of 326, 1,000 and 3,000 ly equal the package's closed form; refusals); `make strict` |
| RE1b2 | The two queries over tier A: imaging (every system in a 59 ly ball, in full) and radio (the one-draw gate, then histories for the hits), for any observer position; `make reach-agree` | 220 | loop | RE1b1 | `make reach-agree` (AC6: the rare list equals the filter of full generation, byte for byte, four presets, VM = interpreter on a 2,000-row subset); `make strict` |
| RE1b3 | `make reach-budget` with ⏸ 1's figures as ceilings, at the calibrated density and at ten times it (a fixture threshold, not a preset change); the unchanged-universe check | 130 | loop | RE1b2 | `make reach-budget` (AC7); `make census` still prints digest `39482d0d…6517851` (AC3); `git diff --exit-code origin/main -- data/starmap/stars.json` |
| RE1c1 | Protocol 2.20 in the sim: `reach.meta`, `worlds.hosts` for every measured host inside 100 pc, the plan-by-id intent and its echo; `sim/protocol_test.ail` cases; hosts derived from the registry and the exoplanet table at session start, not from a larger generated literal | 200 | loop | RE1b1 | `make sim` cases named in the milestone (`protocol_worlds_test`, `protocol_test`); `make strict`; `make parity-v2` |
| RE1c2 | The bridge constant (`SESSION_MINOR` 20, one line), new replay cases recorded for both architectures, `worlds-leak` extended to 2.20, old goldens untouched | 100 | loop | RE1c1 | `make replay` (every stream below 2.20 equals today's golden, AC4); `make worlds-leak`; `make session-minor-guard`; `make replay-map-index` |
| RE1d0 | `make bench-map`: the scripted pan and zoom, the pick timer, the load timer; its headless half (`map-bench-headless`: load and pick, CPU only). Run once on today's map with the registry forced in, to record the baseline | 120 | loop (the frame-time half runs once, only if the GPU is free; never a gate) | RE1a2 | `make map-bench-headless` through `$(SCRIPT_GATE)`; the baseline numbers in the sprint JSON |
| RE1d1 | `ui/reach_registry.gd` (+ `.uid`): the binary loader (float64 positions kept, float32 copies for drawing), the id index, points grouped by leaf; sha checked against the sidecar | 220 | loop | RE1d0 | `make map-registry-test` (headless, `$(SCRIPT_GATE)`): row count, three known stars at their truth positions, a corrupt file refused, load ≤ 1 s |
| RE1d2 | `ui/map_lod.gd` (+ `.uid`): the level-of-detail rules as pure functions of view width, cell picking, search by name or id, marks never culled | 220 | loop | RE1d1 | `make map-lod-test` (AC9: rules table; picking equals the exhaustive search on 10⁴ random clicks; pick ≤ 2 ms; a mark survives every width) |
| RE1d3 | The level-of-detail mock-up on the real registry with fixture marks: stills at 30, 100 and 326 ly, provenance flags shown, and a plain-language review page. No copy, no polish | 100 | attended | RE1d2 | captures opened and described; `make reach-capture` through `$(SCRIPT_GATE)` |
| ⏸ 2 | **Stop for Mark: the mock-up.** What the map shows at each width and how "probable binary" reads, before copy or polish | — | attended | RE1d3 | — |
| RE1d4 | Wire it into `ui/galaxy_map.gd`: leaf-grouped points, zoom and rings to 326 ly, the labels and flags as agreed at ⏸ 2, plan by id, the unsurveyed-medium label from its sim field; a golden case added only if a shader changes (left to the nightly) | 280 | attended | ⏸ 2, RE1c2 | `make ui`; `make map-lod-test`; `make map-registry-test`; `make display-audit-worlds`; `make reach-capture` |
| Land | The combined dev build (`make publish-dev` after merging current main, the export smoke checking the registry ships); cross-family evaluation; changelog fragment; report with the measured counts and budgets; starmap-large-tier's L3 marked landed | — | attended | all | `make ci-fast`; evaluation ≥ 70 |
| ⏸ 3 | **Stop for Mark: the dev build.** His OK on the map at 326 ly closes RE1 and opens RE2's plan | — | attended | Land | — |

**Total:** about 2,340 LOC in 14 milestones and three stops.

## Critical path and parallel work

`RE0a → ⏸ 1 → RE1a1 → RE1a2 → RE1b1 → RE1c1 → RE1c2 → RE1d4 → Land → ⏸ 3`.
- RE0a and RE0b run side by side.
- RE1d0 → RE1d1 → RE1d2 → RE1d3 need only the registry file (RE1a2), so the map line runs beside RE1b and RE1c, and ⏸ 2 can be reached while the protocol work is still in review.
- RE1b2 and RE1b3 are off the critical path: the map does not need the queries.

## AILANG syntax checklist for new modules

| Module | Contracts | Effects | Inline tests |
|---|---|---|---|
| `sim/tools/reach_registry` (pure part) | include: `ensures` the encoded length is 44 × rows; `requires` parallax > 0 | skip: pure; the FS entry is a separate `! {IO, FS}` function | include: `sim/tools/reach_registry_test.ail`, named checks |
| `sim/reach` | include: `ensures` a leaf address round-trips for a position inside it; `requires` radius ≥ 0 on both queries | skip: pure (the registry read stays in `sim/ship.ail`, `! {IO, FS}`) | include: `sim/reach_test.ail`, plus `tests [...]` on the leaf-address function |
| `sim/tools/reach_probe` | skip: a measurement tool, not shipped logic | include: `! {IO, FS}` on `main` only | skip: its output is the evidence; determinism is its gate |

`ailang check --package sim` runs beside `ailang test --package sim` for every `.ail` milestone (STRICT_FALLBACK_001 is only enforced by `check`).

## Risks

- **A budget fails on the pinned runtime, or at ten times the density.** Seen at ⏸ 1 with numbers. The fallback inside this sprint is slicing the radio query over ticks; anything deeper re-plans RE1b.
- **Reading 13 MB of binary in AILANG is slow.** RE0b measures it and the per-leaf read. A real VM cost is reported upstream with a repro, not worked around.
- **A larger generated hosts table hits the compiler's memory growth on nested record literals** (worlds execution report, v0.56.0). RE1c1 derives hosts at session start instead of generating a longer literal.
- **The quality columns need `table1c.dat`,** which the builder must gunzip into the scratch directory, as `make companions` does. `gcns.csv` and its pin are not changed.
- **`stars.json` overlap by identity.** A registry row that is the same star as a `stars.json` row under another id would appear twice. The truth table's identity rule decides; RE1a1's test carries a known cross-identified pair, and `starmap-consistency TIER=reach` fails on any identity seen twice.
- **Protocol drift.** Another branch may take 2.20; the minor is re-read at RE1c1's start.
- **The host is busy** (load near 90 during planning). Budget gates state the load they ran under and use CPU time, not wall time.
- **The map with 300,000 points looks like noise.** That is what ⏸ 2 is for; nothing is polished before it.
- **RE1 lands before the evidence ledger.** Then the dev build shows a wider map without marks. Stated on the review page so it is not read as a regression.

## Duration

Recent pace: the last seven days on main hold 214 commits and about 33,000 inserted lines across every track, and R3-WORLDS and R3-COMMS-V2 each landed in two to three days of sessions. R3-REASONS planned 3,080 LOC at five to seven days.

This sprint is about 2,340 LOC in 14 runs of 60 to 90 minutes: **14 to 21 hours of executor time, four to six working days**, not counting the wait at each of the three stops or the attended publish. RE0 to ⏸ 1 is half a day. The map line (RE1d0 to ⏸ 2) is about a day and a half and overlaps the sim line. The estimate assumes the budgets pass at ⏸ 1; if the radio query must be sliced, add a day.

## Stop conditions

Stop and report rather than continue if: RE0's measurements are ready (⏸ 1); a budget fails at either density; the registry is ready to publish; the mock-up is ready (⏸ 2); a replay golden below 2.20 or the census digest changes; a VM and interpreter result differ (report upstream with a minimal repro); the dev build is ready (⏸ 3).
