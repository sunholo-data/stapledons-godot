# Sprint R1-ISM-DUST: the real interstellar medium and dust-grain impacts

**Design doc:** [ism-structure-and-dust.md](ism-structure-and-dust.md) (ledger D-60).
**Status:** Planned 2026-10-09. **Awaiting Mark's approval and answers to Q1–Q7** (design doc §13). Nothing is executed and no package is published before approval.
**Branch (on approval):** `sprint/ism-dust`, from `origin/main`. Package work happens in `sunholo-data/ailang-packages` on its own branches; the spec in `sunholo-data/stapledons-design`.
**Estimate:** about 3,840 LOC in two PRs: **PR A** about 3,320 LOC (pin bump 20, oracle 180, packages 960, LISM tables 220, sim 720, renderer 400, map 360, HUD 180, captures 220, docs 60) in **13 working days**; **PR B** (Edenhofer clouds and the LLCC) about 520 LOC in **3 days**; **16 working days** in all. Recent pace is about 400 LOC/day (R1-SHIP-STAR-LIGHT: 600 LOC in 1.5 days; free-nav-stops: about 600 LOC in a day). 3,840 LOC is 9.6 days at that pace; the rest (about 65 %) covers what LOC does not measure (plan review F6): two package releases with oracles, the spec-PR gate before publishing, transcribing and verifying about 100 table values, digitising the LLCC from figures, a 3.25 GB fetch, a protocol bump with re-recorded baselines, and three review sheets.
**Risk:** medium-high. New physics in two packages, a new external dataset, and a protocol change; the renderer part is small and follows the glow's pattern.

## Registry reuse

| Milestone | Package | Action | Reason |
|---|---|---|---|
| I1 | `sunholo/celestial` | contribute | New `ism` module (medium geometry, HEALPix, grain size distribution, Poisson draw). It is astrophysics, not relativity, and celestial already holds the galactic frames |
| I2 | `sunholo/relativity` | contribute | `medium` additions (column drag, mass-equivalent density, drive-hold limit) and a new `dust` module (grain kinetic energy, rates, the wall afterglow) next to the existing glow functions |
| I3a, I3b | none | none | One-off data tooling in the game repo (AILANG tool plus Godot headless file reading); no reusable package capability |
| I4–I9 | `sunholo/relativity`, `sunholo/celestial` | depend | The sim, renderer, map and HUD consume the released functions; GDScript mirrors only shapes, tested against package values |

## Current status (evidence)

- `sim/core.ail`: `Params.ismNCm3 = 0.1` (HB-3) is the only density; `ismPerM3` feeds `ledgerAfter`, `pieceLedger`, `brakeHoldsAgainstDrag` and `journeyView`'s `Ism` rows; `ismNow` → `consequence.ismAt` gives `ship.ism` (protocol 2.2 and up).
- `interior/glow_overlay.gdshader` and `interior/forward_glow.gd` draw the sim's `glow_pole_w_m2` and `glow_pole_k`; they need no change for the density field to show in the glow.
- `ui/galaxy_map.gd` (1,033 lines) has the ISM rows `journey.plan.ism.*`; no medium layer. R1-SHIP-UI (approved D-57, not executed) will split it into chart and helm modes.
- Positions are heliocentric galactic Cartesian light years (`data/starmap/stars.json`), the frame of Linsky 2019 and Edenhofer 2024.
- Pins: `sunholo/relativity` 0.10.0 (0.11.0 on main), `sunholo/celestial` 0.1.0 (0.3.0 on main). Protocol: highest minor 6 (`grMinor`).
- `data/lore/archive/ism-glow.md` states one density everywhere.

## Milestones

| ID | Work | LOC | Depends | PR | Acceptance (design AC) |
|---|---|---:|---|---|---|
| **I-1** | **Pin bump.** Move `sim/ailang.toml` to the latest published `sunholo/relativity` and `sunholo/celestial` (no new functions), `ailang lock`, `make test`, `make parity`, own commit, so the later pins only add (plan review F11). | 20 | approval | A | `make test`, `make parity` |
| **I0** | **Spec PR and sources.** `tools/ism_dust_ref.py` (role oracle) computes every value. **Source verification:** each quoted number (Linsky 2019 Table 3 centre and coefficients, the 0.40 pc median, RL08 Tables 16/18, Slavin & Frisch model 26, Snowden 2014, Krüger 2015's density and fluxes, Peek 2011 distances, the Zenodo file list and size, Bohlin's ratio) is checked against the paper and recorded with table and page; anything not reproduced is flagged (plan review F7). The δ calibration (dust mass per H nucleon) and the fitted q are fixed here, before package work (F3). Design-repo PR: new `physics/ism-structure.md` (IS-n) and `higgs-bubble.md` amendments (HB-3 = the `uniform` value; column drag; the drive-hold limit and its whole-cruise rule; §6b grain impacts and the wall afterglow G-AG, labelled; HB-113+). Its number goes into the sprint JSON `spec_pr`. | 180 | I-1 | A | AC3, AC20 |
| **I1** | **`sunholo/celestial` `ism`** (tests first): real Y_lm and the LIC surface (both conventions tried; the one that reproduces Linsky 2019 Table 2 stays), segment chords (star-shaped surface, ellipsoid, cone shell, slab), `nHFromExtinction`, `healpixRingVec`, `grainDist` / `grainsAbove` / `grainRadiusAt`, `poissonDraw`. Oracle rows (healpy, NumPy). CHANGELOG, release kind minor, `ailang pkg quality` with no gates, publish after P1. | 520 | I0 | A | AC1 |
| **I2** | **`sunholo/relativity` `dust` and `medium` additions** (tests first): `massEquivalentDensity(nH, muH, deltaDust)`, `columnDragEnergy`, `tripEnergyColumn`, `driveHoldMaxPhi`; `grainKinetic`, `sweptCount`, `grainRate`, `afterglowTemperature`, `afterglowEmittance`, `afterglowLuminance`, `visibleRadius`. Uniform-medium identities to 1e-12; NaN guards; oracle; publish after P1. | 440 | I0 | A | AC2 |
| **I3a** | **LISM tables.** `sim/tools/ism_build.ail`: the cited tables (RL08 Tables 16/18 and the medians of Tables 1–15, Linsky 2019 Table 3, Slavin & Frisch, Snowden, δ values) as `Field`s with provenance → `sim/data/ism.ail`, `data/ism/ism.json`; `make ism-data`, `make ism-data-verify`. | 220 | I1 | A | AC4 |
| **I4** | **Sim** (tests first in `sim/ism_test.ail`, `sim/core_test.ail`). `sim/ism.ail` (pure): `mediumAt`, `profile`, `column`. `Params.ismModel` (`uniform` / `lism-1`). Ledger by column per flown piece; plan: profile, medium list, peak n, `driveHoldMaxPhi` over the whole cruise, refusal, highest accepted speed; `scenarioError` under `lism-1` against the hot-gas floor; impacts: exact totals per piece, bright events in the display window (stride 1,024, fixed draw layout, ≤ 32 per window, dropped count), glitter descriptor; `ship.ism` gains `medium`, `n_h_cm3`, `impacts`, `glitter`; `journey.plan.medium[]`, `hold_max_phi`, `grains`, `visible_flashes`. Protocol: next free minor. Strict VM, parity, determinism; `uniform` streams byte-identical; `lism-1` baselines re-recorded and listed in the JSON `rerecorded`. Guided itinerary checked under `lism-1` (AC10b; Q8 if it fails). | 720 | I2, I3a | A | AC6(a,b), AC7–AC13, AC10b |
| **I5** | **Renderer.** `interior/dust_flash.gd` (CPU reference: afterglow emittance and temperature over time, the glitter and disc samplers mirroring the package), `interior/dust_flash.gdshader` (additive, sky SubViewport, before the tonemap, ≤ 64 sprites plus a hashed glitter field, `Blackbody` lookup, `Exposure.k()`). Goldens G-ISM-1 (peak and decay), G-ISM-2 (colour ramp), G-ISM-3 (glitter count). LUT finiteness test. | 400 | I4 | A | AC14, AC15 |
| **I6** | **Galaxy map.** `ui/ism_layer.gd`: LIC mesh (GDScript mirror tested against `starSurfaceRadius`), cloud cone shells, one log colour scale, labels, legend with sources and the labelled assumptions; route segments coloured by medium; plan rows from sim fields; `D` toggles the layer (display control); hook lines only in `galaxy_map.gd`. `make map-ism-test` (headless). | 360 | I3a, I4 | A | AC16 |
| **I7** | **HUD** (on R1-SHIP-UI's `ShipHud`): transit-card rows (medium, density, dust impacts), medium notice card on each boundary, interlude-card media summary, Tab details, the I card on empty sky. New cases in `make ship-ui-test`; `make no-twitch-test` green. | 180 | I4, R1-SHIP-UI U2 | A (or follow-up) | AC17 |
| **I8** | **Renders and sheets.** `tools/ism_capture.gd` → `renders/ism/`: flight frames (hot gas, LIC/G, the Hyades leg; the n_H 10 cloud via a synthetic region until PR B) at 0.99c, 0.999c, 0.9999c, 0.999999c; a flash close-up; the afterglow sheet (r_s 0.25/0.5/1 m × τ 0.1/0.2/0.4 s); the **sensitivity sheet** (a_max 5/10/20 µm, hot-gas δ 0.0051/0.002, MRN-only; F4); the ε sheet per medium; map views. Uniform/NaN frame check. Inspect every frame. `make ism-bench`. | 220 | I5, I6 | A | AC18, AC19 |
| **I9** | **Docs.** Archive drafts (corrected `ism-glow`, "Weather between the stars", with the labelled assumptions); CHANGELOG; index row; design-repo roadmap status; python allowlist. | 60 | I8 | A | AC20–AC22 |
| **I3b** | **Dense clouds (PR B).** `make ism-raw` (curl Edenhofer `mean_and_std_healpix.fits`, Zenodo 8187943, CC BY 4.0, sha256 pin in `data/ism/SHA256SUMS`); `tools/fits_slice.gd` (Godot headless: read the header, handle either axis order, seek, write the shells inside 160 pc as little-endian float32); HEALPix → 2 pc grid → Bohlin n_H → threshold → sparse union-find clumps → ellipsoids in `ism_build.ail`; the LLCC digitised from Peek 2011 / Meyer 2012 (figure and page); their map shapes, tests and renders; credits line. | 520 | PR A | B | AC5, AC6(c) |

**Total:** about 3,840 LOC.

## Order and days

```
PR A
Day 1   I-1 pin bump; I0 oracle + source verification starts
Day 2   I0 source verification, δ and q fixed, spec PR opened          ── P1: spec PR to Mark
Day 3   I1 tests red → green (LIC convention settled first)
Day 4   I1 finish; I2 tests red → green
Day 5   I2 finish; both publish once P1 has merged; I3a tables
Day 6   I3a finish + verify; I4 sim/ism.ail, params
Day 7   I4 ledger by column, plan profile, hold limit, guided check (AC10b)
Day 8   I4 impacts, protocol, determinism, parity, re-recorded baselines
Day 9   I5 renderer + goldens         │  I6 map layer (parallel; different files)
Day 10  I5/I6 finish
Day 11  I7 HUD (if R1-SHIP-UI U2 has merged; else follow-up PR)
Day 12  I8 captures, sheets, inspection, bench
Day 13  I9 docs; make test green locally and in CI; PR A          ── P2: Mark's review
PR B
Day 14  I3b fetch (background) + fits_slice.gd (synthetic FITS test)
Day 15  I3b clumps, LLCC digitisation, AC5/AC6(c)
Day 16  I3b map shapes, renders (the dense-cloud frames, a refused route), PR B
```

Critical path: I-1 → I0 → P1 → I1 → I3a → I4 → I5 → I8 → P2. I2 runs beside I1 (different package). I5 and I6 run in parallel after I4. I7 is off the critical path: if R1-SHIP-UI's U2 has not merged by day 11, I7 becomes a follow-up PR (the glow and the flashes already show the medium in flight). PR B can be dropped or deferred without touching PR A.

## Pause points

- **P0 (now, blocking):** Mark approves the plan and answers Q1–Q7.
- **P1 (day 2, blocking for the publishes, not for I1/I2 test work):** the design-repo spec PR (I0) is merged before either package publishes, so every check value has a registered ID.
- **P2 (before PR A merges, blocking):** Mark looks at `renders/ism/` and the dev build (`make publish-dev`): picks the afterglow shape (Q2), looks at the sensitivity sheet (Q3 and the hot-gas δ), confirms the per-medium glow and the re-recorded baselines (Q4), and reads the Archive drafts (Q7). His notes are fixed before landing.
- **P3 (before PR B merges, non-blocking for PR A):** the dense-cloud renders and a refused route through a cloud.

## Tests and evidence per milestone

| Milestone | Tests | Evidence |
|---|---|---|
| I0 | Oracle self-consistency (uniform identities, quadrature normalisation) | Spec PR with IS-n and HB-113+ tables |
| I1 | `ism_test.ail`: Table 2 reproduction, chords vs oracle, healpy rows, distribution normalisation, Poisson χ² | `ailang pkg quality` output, publish log |
| I2 | `dust_test.ail`, `medium_test.ail`: every §9 check; NaN propagation | As I1 |
| I3a | `ism_build_test.ail`: table parsing, provenance on every Field | Two-run byte identity |
| I3b | Synthetic FITS (both axis orders), clump count stable, `make ism-oracle` anchors | Pins; dense-cloud renders |
| I4 | `ism_test.ail`, `core_test.ail`, `protocol_test.ail`: AC6–AC12; `make strict`, `make parity`, `make replay` | Determinism log; a refused LLCC plan in the stream |
| I5 | `tests/test_dust_flash.gd` (CPU), `make golden` G-ISM-1…3 | Golden diffs |
| I6 | `tests/test_ism_layer.gd`, `make map-ism-test` | Map renders |
| I7 | `make ship-ui-test` new cases; `make no-twitch-test` | HUD renders |
| I8 | Capture tool's uniform-frame check | `renders/ism/` contact sheet, notes on each frame |

## Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| The LIC harmonic convention is unstated | medium | AC1 decides it against Table 2; if neither convention reaches 0.40 pc, stop and report (the cone fallback for the LIC is ready) |
| Zenodo download slow or the file layout differs | medium | Fetch in the background on day 14 (PR B); `fits_slice.gd` reads the header instead of assuming offsets; if the layout differs, the 2 kpc validation map or Leike et al. 2020 is the fallback (both CC BY) |
| AILANG lacks a big-endian float decode, or the clump pass is slow | medium | Godot converts to little-endian; sparse union-find; interpreter for the offline tool, VM parity on a small crop; gaps reported with `ailang messages` |
| Package publish blocked by quality gates | low | Run `ailang pkg quality` early (day 2) |
| VM/interpreter divergence in the new sim code (e.g. #1576-style recursion) | medium | Tail-recursive profile building; bounded lists (≤ 32 events); `make parity` on day 8; shrink and report any divergence |
| Replays and goldens churn | high (expected) | `uniform` keeps old streams; `lism-1` streams are recorded fresh and pinned |
| R1-SHIP-UI late | medium | I7 deferrable (see Order, day 11) |
| Free-nav PRs (#171, #182) move plan code in `sim/core.ail` / `sim/navigation.ail` | medium | Rebase I4 onto them on day 6; the ISM code lives in `sim/ism.ail` with small call sites |
| Flash rates or looks surprise Mark | medium | P2 sheet with alternatives; ε, r_s, τ, a_max and the MRN-only switch are scenario parameters |

## Coordination

- **R1-SHIP-UI (D-57):** I7 builds on `ShipHud` cards; I6 keeps its map code in `ui/ism_layer.gd` so the chart/helm split in `galaxy_map.gd` is not touched beyond hook lines.
- **Free navigation (#171, #182):** routes from any position and "via a star" detours (Q6) use their stops; I4 rebases on them.
- **Package pins:** other branches may bump `sunholo/relativity` / `sunholo/celestial` first; I1/I2 take the next free minor and the sim pins the newest (CLAUDE.md: CI, the bundled runtime and the lockfile move together).
- **Mission charter:** this sprint is attended work from D-60. It does not edit the decision ledger; an attended session records Mark's answers.

## Plan review

Round 1 (independent Sonnet reviewer, `sprint-evaluator` plan review): **78/100, pass**, 0 blocking, 6 major, 5 minor (`.ailang/state/evaluations/eval_R1-ISM-DUST-plan_round_1.json`). All findings addressed in this revision:

| Finding | Fix |
|---|---|
| F1 guided demos vs the hold limit | Computed: the guided brake (10 kg, 3 × 10⁶ g) holds to γ ≈ 13,300 in the warm clouds; the 1,000 AU hops peak at γ ≈ 7,500, so they plan. `scenarioError` checks the cap against the hot-gas floor under `lism-1`. New AC10b (every guided plan accepted) and Q8 if it fails (design §5) |
| F2 RNG stride and the event cap under compression | Stride 1,024 with a fixed draw layout (≤ 130 slots); exact totals per piece, events only in a real-time display window; AC12 split into real-time (0 dropped) and compressed (window ≤ 32, totals within 3σ) (design §6.5) |
| F3 dust normalisation | One calibration: dust mass per H nucleon δ (0.0051 in the local warm clouds and hot gas from Krüger's density over Slavin & Frisch's n_H; 0.010 elsewhere), fixed in I0 before package work (design §4.1, §6.1, §9) |
| F4 the a_max cutoff and hot-gas dust | Both are scenario parameters and labelled assumptions; the I8 sensitivity sheet shows a_max 5/10/20 µm and hot-gas δ 0.0051/0.002 for Mark at P2 |
| F5 circular or missing ACs | AC6 now tests cloud membership and a second paper's α Cen column; AC5 uses independent anchors (Zucker cloud distances, Leike 2020, a synthetic FITS in both axis orders); LLCC criteria added (AC6c); AC3 reads `spec_pr` from the JSON; AC1/AC2 name the package clone; this section fills the stub |
| F6 estimate | 16 days in two PRs (PR A 13 days, PR B 3 days: the Edenhofer clouds and the LLCC) |
| F7 source verification | An explicit I0 task with table and page for every number |
| F8 dust double count, exposure | The ≤ 0.4 % double count is stated and accepted; thresholds are physical and the exposure setting only maps the light (design §4.1, §6.4) |
| F9 re-recorded baselines | AC8 names them (`rerecorded` in the JSON), approved at P2; AC9 runs on the whole guided tour under `lism-1` |
| F10 hold-limit rule | Stated: the whole-cruise peak, because holding cruise speed needs thrust equal to drag everywhere; the plan shows the highest accepted speed (design §5) |
| F11 pin jump | New I-1 pin bump with `make test` and `make parity` as its own commit |
