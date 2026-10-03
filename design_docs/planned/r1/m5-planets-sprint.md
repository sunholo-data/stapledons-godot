# Sprint plan: R1-M5-PLANETS, planets and flybys

**Status:** **Approved** by Mark at ⏸ P0 (attended, 2026-10-03), with
Q1–Q6 answered (see [§Questions](#questions-for-mark-answered-at--p0-attended-2026-10-03)):
the 15-milestone split (Q6); `sunholo/celestial` 0.1.0 publishes under the
relativity rule, so ⏸ P-pkg-a no longer needs Mark (Q1); the defaults for
Q2–Q5. Proposed the same day by sprint-planner. **Nothing executed yet**;
execution starts with wave 1 (M5.0a1 ∥ M5.0b) through the sprint-executor.

## Summary

Put Sol's system in the sim and let the player fly through it. The Sun,
8 planets, 11 moons and 4 ring systems come from published elements in a new
pure package, `sunholo/celestial`. Godot lights them in cd/m² through
M1.5a's single exposure. Fast passes are drawn exactly by per-pixel inverse
aberration of the rest-frame image. In-system legs are M2 journeys to
bodies: intercept, stop or flyby, gravity held off by the drive and costed,
and N1's lighter confirm for legs of 24 h or less. The α Cen arrival shows
its worlds with their status and never draws a guess as a disc.

**Design doc:** [m5-planets.md](m5-planets.md). Mark approved it, attended,
on 2026-10-03, with N1–N3 answered. It has AC1–AC20 plus AC19a.
**Sprint ID:** `R1-M5-PLANETS` · **Progress file:**
`.ailang/state/sprints/sprint_R1-M5-PLANETS.json`.
**Duration:** the design doc's 10 sub-milestones become **15 milestones in
10 waves** (F1 explains the splits). That is **about 25–30 h of attended
execution (3.5–4 days)**, or **about 5–7 days on the 6-hourly loop** (15
items plus 3 contingency iterations). Add Mark's review time at the
⏸ stops and the external wait for M4.6a's relativity release.
**Estimate:** **4,040 counted LOC planned** (2,230 code + 1,810 tests).
Calibrated at 1.6× (see [Velocity](#velocity-calibrated-on-this-repos-actuals)),
expect **about 6,400 changed lines** in the end.
**Risk level:** **Medium-high.** The physics is well pinned: every number
becomes a package value before any test asserts it. The risks are size (the
largest R1 milestone so far), a new package with no release history, the
protocol, Makefile and `main.gd` hotspots shared with M4 (F4), and four GPU
gates that CI can't run.

**Command legend** (the same as M4's plan).
- `$A` = `/Users/voightkampff/dev/sunholo-data/stapledons-godot/runtime/bin/ailang`,
  AILANG **v0.52.0** (on main since PR #73; Makefile `AILANG_RELEASE`). Every `make` line passes `AILANG=$A` (and
  `AILANG_BIN=$A` where Godot drives the sim). A fresh clone runs
  `make runtime` first.
- `$PKG` = a **fresh clone** of `sunholo-data/ailang-packages` at
  `origin/main`. `$PKG/packages/celestial` is new; `$PKG/packages/relativity`
  already exists. Never use the dirty local copy.
- `$D` = the sibling checkout `../stapledons-design`.
- GPU gates (`make golden`, `make capture-m5`, `make bench SCENE=flyby`) run
  in the Studio's GPU window, not in CI. Their logs and renders go into the
  sprint notes for the evaluator.
- **All new M5 make targets live in `mk/m5.mk`**, added to the Makefile by
  one `include mk/m5.mk` line, on the `mk/ai.mk` precedent. This keeps M5
  out of the Makefile hunks that M4 edits (F4).

## Current status (verified 2026-10-03 against `origin/main` `3e17257`, which includes PR #84 (this design) and PR #79 (M1.8))

| Item | State | Evidence |
|---|---|---|
| M2 journey core (protocol v2, planner, commit rule, replay, galaxy map) | ✅ landed | `sprint_R1-M2-JOURNEY.json`: all 10 have `passes: true` |
| `sunholo/relativity` 0.5.2 pinned | ✅ | `sim/ailang.toml` `"sunholo/relativity" = "0.5.2"` |
| `hover_power` (HB-90) in relativity | ❌ **not released**. M3 has a design doc only (`hoverPowerPerKg`, specific to black holes), with no sprint | `grep -i hover ~/.ailang/cache/registry/sunholo/relativity/0.5.2/*.ail` finds no hits. **It ships in M5.0b** (design §M5.0b fallback) |
| M1.5a photometric exposure | ✅ merged (PR #80) | `git log origin/main` `7f3158b` |
| M1.2d bright tier (α Cen A/B astrometry) | ✅ merged (PR #69) | `9bf55ce` |
| M1.3 star rendering v2 | ✅ merged (PR #67) | `0a9c2a8` |
| **M1.8 forward CMB + centre-weighted eye meter** | ✅ **merged (PR #79, `28fd310`) during planning** | It added `sky/sky_meter.gd` and edited `sky/exposure.gd`, `sky/starfield.gd`, `main.gd` and `tests/test_physics.gd`. **M5.4 builds on its meter** (F3) |
| M4 sprint `R1-M4-JOURNEY` | Plan on main, `status: planned`; the mission loop is running **wave 1 (M4.6a, M4.0, M4.1)**, and no branch has been pushed yet | `sprint_R1-M4-JOURNEY.json`; `git ls-remote origin` |
| M4.3a HUD and `DisplayBinding`, M4.1 stand-off, M4.7 lore-check, M4.6 `lint-precision` | ❌ not started (M4 waves 2–4) | `ls ui/display_binding.gd sim/consequence.ail sim/tools/lore_check.ail`: none exists |
| AILANG v0.52.0 | ✅ **merged (PR #73)**; main pins v0.52.0 with relativity 0.5.2 | `git show origin/main:Makefile | grep AILANG_RELEASE` = v0.52.0. R7 retired |
| Planet, orbit or celestial code in the game | none | V1 in the design doc |
| Registry: orbit, ephemeris or reflected-light package | **none** | [Registry reuse gate](#registry-reuse-gate) |

### What can start now and what has to wait

**Can start now:** M5.0a1 (the new package, which depends on nothing) and
M5.0b's code and tests. **M5.0b's publish waits** for M4.6a's relativity
release, because both bump the same package and M4.6a goes first (design
§M5.0b). Everything in the sim waits for both publishes (M5.1a pins them).
M5.4 builds on M1.8's meter (PR #79, merged during planning); its golden
needs a planet from M5.2a. M5.6 can build on M4.3a's `DisplayBinding` if M4.3a has landed;
otherwise it builds a minimal one and M4 adopts it (design §Depends, soft).
**M5.7's AC12** needs M4.7's `make lore-check`, and M5.7's stand-off placement
falls back to a scenario setting until M4.1 lands.

## Velocity, calibrated on this repo's actuals

Counted LOC means non-blank, non-comment code + test + config lines.
Fixtures, goldens, data blobs, renders and docs don't count.

| Milestone | Estimate | Actual | Ratio | Source |
|---|---|---|---|---|
| M1.2d bright tier | 560 | 805 | 1.44 | `sprint_R1-M1-SKY-2.json` `actual_loc` |
| M1.7 catalogue switch | 520 | 623 | 1.20 | same |
| AI.2 protocol 2.1 module | 430 | 733 | 1.70 | `sprint_R1-AI-FOUNDATION.json` (code + tests) |
| AI.3 record validation | 400 | 697 | 1.74 | same |
| AI.4 service stub | 550 | 850 | 1.55 | same |
| AI.5 adapters and spend | 460 | 830 | 1.80 | same |
| AI.6 AiBridge supervision | 340 | 826 | 2.43 | same |
| AI.7 relay and cache e2e | 390 | 1,001 | 2.57 | same |
| AI.8 core layer | 160 | 317 | 1.98 | same |
| AI.9 key and cost UX | 340 | 924 | 2.72 | same |
| R1-M2-JOURNEY (10 milestones) | 3,420 | ~5,000 | ~1.46 | M4 plan's velocity table |

**What the data says.** The ratios run from 1.2× to 2.7× (median 1.77×).
They split cleanly by kind:
- **Pure package or sim physics** (M1.2d, M1.7, M2) ran **1.2–1.5×**, the
  "30–80 % over" figure.
- **Godot supervision, UI and harness work** (AI.6, AI.7, AI.9) ran
  **2.4–2.7×**. Tests overran most: they came out roughly 1:1 with code,
  against the plans' ~0.7:1. The evaluators' must-fix rounds (mutants,
  extra goldens, guard cases) account for most of the extra test lines.

**Planning figures for M5:**
- **Ratio:** 1.4× for the package and sim milestones (M5.0a1, M5.0a2, M5.0b,
  M5.1a, M5.1b, M5.5a, M5.5b) and 1.8× for the Godot milestones (M5.2a to
  M5.4, M5.6a, M5.6b, M5.7, M5.8). Blended, that is **about 1.6×** on
  4,040, so **about 6,400 lines**.
- **Cap:** 650 counted LOC per milestone. **Every M5 milestone is planned at
  ≤ 400** so that 1.6× still lands inside 650. The design doc rows that went
  over that figure are split (F1). No waiver is requested.
- **Pace:** about 2.5 h per milestone including the independent evaluation
  (M1.2d took 2 h 20 min, M1.5a 5 h, M2 averaged 1.35 h). The **critical path is
  10 serial milestones** (the navigation track), so about 25 h. The render
  track has one wave of slack.
- **Contingency:** one evaluator round 2 per ~5 milestones has been the
  pattern (M1.3, M1.2d, AI.2, AI.3 corrections), so plan **3 contingency
  iterations**.
- **Throughput:** about 1,150 planned LOC (about 1,850 actual) per attended
  day.

## Findings made while planning

**F1. Five design rows are split to respect the cap, given the calibration.**

| Design row | Design LOC | × ratio | Split into |
|---|---|---|---|
| M5.0a celestial 0.1.0 | 760 (**over 650 even before calibration**) | 1,060 | **M5.0a1** orbits (`kepler`, `ephemeris`, `frames`; scaffold) 400 · **M5.0a2** light and gravity (`lighttime`, `gravity`, `reflect`, `rings`; quality, eval, publish) 360 |
| M5.1 sim data and `systemAt` | 550 | 770 | **M5.1a** data + pins 280 · **M5.1b** `celestial.ail` + `system` change set 270 |
| M5.2 lit planets and rings | 520 | 940 | **M5.2a** globes, photometry, point/disc, textures 360 · **M5.2b** rings, shadows, atmosphere 270 |
| M5.5 in-system navigation | 700 (**over 650**) | 980 | **M5.5a** body targets, geometry, intercept, refusals 350 · **M5.5b** gravity hold, holding state, confirm class, Sol tour 380 |
| M5.6 in-system UX | 450 | 810 | **M5.6a** system map, planning panel, confirm dialogs 300 · **M5.6b** transit: window view, HUD, in-system warp 130 |

Each split follows a seam the design doc itself draws: module groups, data
versus logic, globe versus ring shader, plan geometry versus hold physics,
planning versus transit. No new scope.

**F2. Gate 2 forbids holding all the goldens until M5.8.** The design puts
G-M5-1 to G-M5-9 in M5.8. CLAUDE.md gate 2 needs each SR or photometric
visual's GPU golden **before it merges**. So the goldens move to the
milestone whose visual they gate: G-M5-4 and G-M5-6 to M5.2a, G-M5-5 to
M5.2b, G-M5-1, -2 and -3 to M5.3, G-M5-7 to M5.4, G-M5-8 to M5.7, and G-M5-9
stays in M5.8. The design's 130 test LOC for nine goldens was thin, and
this plan sizes them at about 35 LOC each. With `hover_power` added (+40)
that makes **+290 LOC over the design's 3,750, so 4,040.**

**F3. M5.4 must change M1.8's meter, not M1.5a's.** PR #79 (M1.8, merged
to main as `28fd310` while this plan was written) replaced the eye's log-average meter with a **centre-weighted eye meter
that includes the stars and the CMB** (`sky/sky_meter.gd`). The design's
EV_meter = max(log-average EV, EV(P99.5/headroom)) was written against
M1.5a. M5.4 applies the P99.5 highlight term to whichever meter is live
now (centre-weighted for EYE, log-average for CAMERA). G-M5-7 asserts
that M1.5a's **and M1.8's** exposure goldens pass unchanged.

**F4. Files shared with M4 and M1.8 (the conflict map).** The full
per-milestone file list is in each milestone and in the JSON. The hotspots:

| File | M5 milestones | Also touched by | Mitigation |
|---|---|---|---|
| `sim/protocol.ail`, `sim/protocol_test.ail` | M5.1b (`system`), M5.5a (plan fields), M5.5b (`hold`, `confirm`) | **M4.1** (consequence fields), AI.* landed 2.1 | Additive only. **The minor version is taken at merge time**: whichever lands second takes the next minor. M5's tests assert fields, never a hard-coded minor. M2's old-message tests stay unmodified |
| `sim/ship.ail` | M5.1b, M5.5b | **M4.1** | M5 adds one emit call per tick and the scenario epoch; it rebases on M4.1 if M4.1 merges first |
| `sim/core.ail` (446 lines) | M5.1b (epoch and system in state), M5.5a (`Target` body form, `planIntent`), M5.5b (holding phase, `hold_j`) | **M3** (GrState, no sprint yet); M4.1 lists no `core.ail` edit (`consequence.ail` is separate) | Body-target logic goes in a **new `sim/navigation.ail`**; `core.ail` only dispatches to it (≤ 40 changed lines per milestone) |
| `sim/ailang.toml`, `sim/ailang.lock`, bundled cache | M5.1a (pins celestial and the new relativity) | **M4.6a** (relativity pin), M4.1/M4.7 (exports) | The pin bump lands **in its own commit, after M4.6a's pin commit**. Export lists are unions |
| `bridge/sim_bridge.gd` | M5.1b (parse `system`), M5.5a/b (plan and hold fields) | **M4.3a** (warp/dtau wiring), **M4.4** (AI relay wiring) | Parse-only additions in a separate function block |
| `main.gd` (829 lines; goldens live there) | M5.2a (instance `SystemView`, ≤ 10 lines), M5.8 (`--golden-m5`, `--capture-m5`, `--bench` scene switch) | **M4.2** (interior wiring), M1.8 #79 (merged) | **M5 goldens go in `tools/m5_golden.gd`** (the M1.8 `tools/cmb_golden.gd` pattern); `main.gd` gains only flag dispatch lines |
| `Makefile` | every milestone | **M4.0, M4.1, M4.3a, M4.5, M4.6, M4.7**, M1.8 | `mk/m5.mk` plus one `include` line, and `test:` gains M5's sub-targets in one hunk |
| `sky/exposure.gd`, `sky/sky_meter.gd` | M5.4 | M1.8 #79 (now merged) | M5.4 builds on the merged meter |
| `sky/starfield.gd` | M5.2a (point-source handoff API) | M1.8 #79 (merged) | One public method `add_point_sources(arr)` |
| `tests/test_physics.gd` | M5.2a, M5.3, M5.5b, M5.8 | **M4.6**, M1.8 | M5 checks go in a `_m5_*` function block called from one line |
| `ui/journey_hud.tscn`, `ui/display_binding.gd` | M5.6a/b (additions) | **M4.3a** creates them | Extend if M4.3a has landed. If not, M5.6a creates `ui/display_binding.gd` with M4.3a's planned API and M4.3a adopts it (design §Depends). Q4 |
| journey core (`planBurnCoastBurn` composition, commit rule, ledger) | M5.5a/b | **M4.1** reads the ledger and adds `drag_energy_j` | The ledger gains `hold_j` alongside the existing scopes, and M4's `drag_energy_j` is untouched |

**F5. AC9's `jq` path is adjusted to this repo's sprint JSON schema.** The
design writes `.milestones[] | select(.id=="M5.8").review`. This repo's
sprint JSONs (and the sprint-executor validator) use `features[]` with ids
like `M5.8_GATES_CAPTURE_BENCH`. AC9's command becomes
`jq '.features[] | select(.id | startswith("M5.8")) | .review' .ailang/state/sprints/sprint_R1-M5-PLANETS.json`.

**F6. AC10's paths are reconciled.** The design keeps pins in
`data/planets/SHA256SUMS` (the sky pattern, `data/sky/SHA256SUMS`), while
AC10 greps `assets/planets`. Plan: pins and `CREDITS` are tracked in
`data/planets/`, the fetched textures land in `assets/planets/` (gitignored),
and AC10 becomes
`make planet-assets && test -z "$(git ls-files assets/planets)" && grep -q 'CC BY 4.0' data/planets/CREDITS`.

**F7. `hover_power` naming.** M3's design names a black-hole-specific
`hoverPowerPerKg(mSun, r)`. M5 needs the general HB-90 form P = m_eff·|g|·c.
This plan puts **`medium.hoverPower(mEffKg, gMs2)`** in relativity's
bubble-energetics module (`medium`), so M3's function can later compose it.
That module is the one M4.6a edits, which is one more reason M5.0b rebases
after M4.6a. **Mark approved this (Q5).**

**F8. AC12 needs PL-n rows in the design repo before M5.7, not at
landing.** `make lore-check`'s cross-repo half resolves `PL-n` ids in
`$D/physics/planets-spec.md`. The design doc says M5 doesn't edit the design
repo until landing ("or earlier, if Mark wants the spec first"). M5.7's
AC12 can't pass without at least the PL-n check-value rows. Plan: a
docs-only PR to `stapledons-design` opens alongside M5.7 with
`planets-spec.md` (PL-1…) and RS-24 to RS-29, and its values are copied from
the package probes. **Mark approved this (Q3).**

**F9. No new Python.** The sol tour is a hand-written NDJSON input log
replayed by the existing `tools/replay.py` harness (role: harness). The
texture fetch and publish extend the shell glue `tools/sky_assets.sh`, and
texture normalisation is a Godot headless `--script`
(`tools/planet_textures.gd`). `make python-guard` stays green with zero new
`*.py` (AC20).

## Registry reuse gate

Searches run 2026-10-03 with the main checkout's `runtime/bin/ailang` (v0.51.0 at the time; the registry is server-side, so the result holds on v0.52.0):
`ailang search {orbit, orbits, ephemeris, kepler, celestial, astronomy,
albedo, planet, gravity}` → **No packages found** for every term.
`ailang pkg search {orbit, ephemeris, kepler, celestial}` → **No packages
found.** `ailang search physics` → only `sunholo/relativity@0.5.2`, which has
no Kepler, albedo, phase-law or ring functions (design V3). The full listing
(46 packages) has nothing astronomical apart from relativity.

| Milestone | Package | Action | Reason |
|---|---|---|---|
| M5.0a1 | `sunholo/celestial` (new) | **none → new package** | No orbit, ephemeris or Kepler package in the registry. Mark ruled (Q5) that the code goes in a new package and relativity stays relativity-only |
| M5.0a2 | `sunholo/celestial` (new) | **none → new package** | No reflected-light, ring-scattering, light-time or Newtonian-gravity package exists |
| M5.0b | `sunholo/relativity` | **contribute** | `apparentDisc` is pure aberration optics built on `cosSeen`; `hoverPower` is bubble energetics (HB-90). Gate 3 |
| M5.1a | `sunholo/celestial@0.1.0`, `sunholo/relativity@(M5.0b release)` | **depend** | The sim pins both; the data uses celestial's element and pole record types |
| M5.1b | both | **depend** | `stateFromElements`, `eclipticToGalactic`, `retardedTime`, `discIlluminance`, `poleAndSpin`; `illuminanceFromV` from relativity |
| M5.2a | both | **depend** (mirror) | `physics/planets.gd` and `planet.gdshader` mirror `minnaertRadiance`, `lambertPhase` and `discIlluminance`; check values are copied from package probes |
| M5.2b | `sunholo/celestial` | **depend** (mirror) | `ring.gdshader` mirrors `ringLitRadiance`, `ringUnlitRadiance` and `ringTransmission` |
| M5.3 | `sunholo/relativity` | **depend** (mirror) | `deaberrate`, `dopplerApparent`, `apparentDisc`, `gammaOf`, `oneMinusBeta`; the `bb_lut` from M1 |
| M5.4 | none | **none** | Exposure-meter statistics (a histogram percentile) are presentation, not physics maths; M1.5a's model is already GDScript |
| M5.5a | both | **depend** | `bodyAt` ∘ `planBurnCoastBurn` intercept; the composition is game logic (design §M5.5) |
| M5.5b | both | **depend** | `accelerationAt`, `hoverPower`, `motionAt` |
| M5.6a | none | **none** | Godot UI bound to sim fields; no arithmetic |
| M5.6b | none | **none** | Godot UI, warp stepping (logged `dtau`) |
| M5.7 | `sunholo/celestial` (+ relativity for the codex values) | **depend** | The α Cen AB orbit via `stateFromElements`; codex check values through lore-check |
| M5.8 | both | **depend** | Every golden reference value comes from a package probe |

## Waves and milestones

```
W1  M5.0a1 ─┐            M5.0b ── (waits for M4.6a's publish) ── ⏸ P-pkg-b
W2  M5.0a2 ─┴─ ⏸ P-pkg-a (independent eval ≥ 70, publish celestial 0.1.0; no Mark action, Q1)
W3  M5.1a  (pins both, data)                                     needs P-pkg-a + P-pkg-b
W4  M5.1b  (systemAt, `system` change set)
      ├── RENDER track ───────────────────┐   ├── NAVIGATION track ─────────┐
W5  M5.2a ── ⏸ L-tex                      │   M5.5a                         │
W6  M5.2b  ∥  M5.4                         │   M5.5b                         │
      ⏸ R-m5a (planet renders)            │                                 │
W7  M5.3 ── ⏸ R-m5b (flyby warp renders)  │   M5.6a                         │
W8                                         │   M5.6b ── ⏸ R-m5c (nav UX)    │
W9  M5.7 (joins: M5.3 + M5.6a's widget) ── ⏸ R-m5d (α Cen arrival + codex)
W10 M5.8 (G-M5-9, capture-m5, bench, report) ── ⏸ S-M5 ── ⏸ P-land
```

**Critical path:** M5.0a1 → M5.0a2 → M5.1a → M5.1b → M5.5a → M5.5b → M5.6a →
M5.6b → M5.7 → M5.8 (10 serial). **Acceleration options** (the design
allows both): M5.2a may start in W4 against a fixture `system` message once
M5.1b's first commit fixes the schema, and M5.6a may start against fixture
plans before M5.5b lands.

**Branching** (the M4 precedent, adapted). Sim milestones (M5.1a, M5.1b,
M5.5a, M5.5b) land as their own PRs to main: they carry no visual, and gate 1
plus the sim tests gate them. The **render train** (M5.2a → M5.2b → M5.3)
lands as stacked PRs into the integration branch **`m5-render`**, and the
**nav-UI train** (M5.6a → M5.6b) into **`m5-nav-ui`**. Each integration
branch merges to main as one merge after its ⏸ review. M5.4 is its own PR. M5.7 and M5.8 branch from main after both trains merge.

| Wave | Milestone | LOC (code + tests) | Depends on (internal) | External / soft | Stop |
|---|---|---|---|---|---|
| 1 | **M5.0a1** celestial orbits | 210 + 190 = **400** | none | none | |
| 1 | **M5.0b** relativity `apparentDisc` + `hoverPower` | 60 + 80 = **140** | none | **M4.6a's relativity release published** (hard, for the publish only) | ⏸ P-pkg-b |
| 2 | **M5.0a2** celestial light, gravity, rings, publish 0.1.0 | 190 + 170 = **360** | M5.0a1 | none | ⏸ P-pkg-a |
| 3 | **M5.1a** Sol and α Cen data, package pins | 190 + 90 = **280** | M5.0a2, M5.0b | M4.6a pin commit merged first | |
| 4 | **M5.1b** `systemAt` and the `system` change set | 140 + 130 = **270** | M5.1a | M4.1 protocol (soft; rebase) | |
| 5 | **M5.2a** globes, photometry, point/disc, textures | 210 + 150 = **360** | M5.1b | M1.5a, M1.8 (landed) | ⏸ L-tex |
| 5 | **M5.5a** body targets, geometry, intercept, refusals | 190 + 160 = **350** | M5.1b | M2 (landed) | |
| 6 | **M5.2b** rings, shadows, atmosphere | 170 + 100 = **270** | M5.2a | | ⏸ R-m5a |
| 6 | **M5.4** highlight-protecting meter | 40 + 60 = **100** | M5.2a | M1.8 (landed) | |
| 6 | **M5.5b** gravity hold, holding, confirm class, Sol tour | 210 + 170 = **380** | M5.5a, M5.0b | **celestial 0.1.1** (Earth-Moon barycentre split; the start holds 50,000 km above Earth) | |
| 7 | **M5.3** rest-frame tiles + exact warp | 160 + 220 = **380** | M5.2b | | ⏸ R-m5b |
| 7 | **M5.6a** system map, planning panel, confirm dialogs | 210 + 90 = **300** | M5.5b | M4.3a `DisplayBinding` (soft) | |
| 8 | **M5.6b** transit: window view, HUD, in-system warp | 90 + 40 = **130** | M5.6a | M4.3a HUD (soft), M4.2 bridge (soft) | ⏸ R-m5c |
| 9 | **M5.7** α Cen arrival, inset, codex; start at Earth | 100 + 80 = **180** | M5.3, M5.6a, M5.5b | **celestial 0.1.1** (Earth-Moon barycentre split, for the start-at-Earth view), M1.2d (landed), M4.1 stand-off (soft), **M4.7 lore-check (for AC12)**, design-repo PL-n PR (F8) | ⏸ R-m5d |
| 10 | **M5.8** G-M5-9, `capture-m5`, bench, report | 60 + 80 = **140** | all | M4.6 `lint-precision` (soft) | ⏸ S-M5 |
| | **Total** | **2,230 + 1,810 = 4,040** | | | |

---

### Wave 1

#### M5.0a1: `sunholo/celestial` orbits (new package, part 1)
**Status:** ✅ published in `sunholo/celestial@0.1.0` (ailang-packages PR #91); independent eval 89/100 (`eval_R1-M5-PLANETS-M5.0a_round_1.json`, covers M5.0a1 + M5.0a2).
**Scope (in `$PKG/packages/celestial`):** `ailang pkg init` with the package
manifest, `[release] kind`, a README that cites the design repo's
`physics/planets-spec.md` (as relativity cites its spec), and an AGENT.md.
Modules:
- **`kepler`**: `solveKepler(M, e)` uses Newton with a fixed 8 iterations from
  E₀ = M + e sin M (deterministic iteration count, safe on the strict VM);
  `stateFromElements(el)` goes perifocal → ecliptic J2000, AU and AU/d.
- **`ephemeris`**: `elementsAt(el, rates, jdTDB)` uses Standish Table 2a
  with the b, c, s, f terms, and freezes the secular rates at the window
  edge outside 3000 BC–3000 AD, returning a `mean-orbit` flag;
  `satelliteAt(el, jdTDB)` handles the Laplace-plane mean elements with
  node and periapsis rates.
- **`frames`**: `eclipticToGalactic(v)` (the obliquity 84381.406″ composed
  with the Hipparcos 1997 matrix, the starfield's frame) and
  `poleAndSpin(body, jdTDB)` (IAU WGCCRE 2015).

The package has **no dependency on relativity**. Units are AU, days (TDB),
km and radians, all float64.

**Files:** `$PKG/packages/celestial/{ailang.toml, README.md, AGENT.md,
kepler.ail, kepler_test.ail, ephemeris.ail, ephemeris_test.ail, frames.ail,
frames_test.ail}` (all new). **No game-repo file.**

**Estimated:** 210 + 190 = 400 · **Deps:** none · **Registry:** none, new
package (searches above).

**Acceptance (commands):**
- `cd $PKG && $A test --package celestial` passes. It includes: the Kepler
  residual < 1e-14 for e ≤ 0.97; e = 0 gives E = M exactly; the radius of a
  circular orbit equals a exactly; vis-viva holds to 1e-12; Jupiter at
  opposition on 2023-11-03 (elongation 180° within ±2 d); Mars at
  opposition on 2020-10-13 (±2 d); the Moon's distance inside the published
  perigee–apogee range; Io's period 1.769 d within 1e-4 d; the north
  ecliptic pole maps to galactic (96.38°, 29.81°) within 1e-4°; Saturn's
  ring-plane crossings on 2009-08-11 and 2025-05-06 within ±10 d (the pole
  and the JPL elements together); `elementsAt` at JD 3000 AD + 1 yr returns
  the `mean-orbit` flag.
- VM equals interpreter: `$A run --bytecode --strict-bytecode` probes of
  `solveKepler` and `stateFromElements` are byte-identical to the interpreter
  (`cmp`).
- `$A pkg quality` in `$PKG/packages/celestial` lists no gates (it is
  re-run at M5.0a2).

**Test-first:** all the checks above, written before each function. The
oracle numbers in the design doc are targets only, and **each test's
expected value is the published reference date or constant, not the
oracle's output.**

#### M5.0b: `sunholo/relativity`: `optics.apparentDisc` and `medium.hoverPower`
**Status:** ✅ published in `sunholo/relativity@0.7.0` after M4.6a's 0.6.0; independent eval 93/100 (`eval_R1-M5-PLANETS-M5.0b_round_1.json`).
**Scope (in `$PKG/packages/relativity`):**
`optics.apparentDisc(cosTheta, alpha, phi)` returns the apparent centre and
apparent radius of a sphere of angular radius α at rest angle θ. It
aberrates θ ± α along the meridian with the existing `cosSeen`, and its
near-c branch uses `oneMinusBeta(phi)`, never `1 - beta`.
`medium.hoverPower(mEffKg, gMs2)` = m_eff·|g|·c in W (HB-90; F7). It comes
with a CHANGELOG entry, `[release] kind = minor` and the version bump.
**Code and tests can start in W1. The branch is rebased onto M4.6a's merged
release, then published** (⏸ P-pkg-b).

**Files:** `$PKG/packages/relativity/{optics.ail, optics_test.ail,
medium.ail, medium_test.ail, CHANGELOG.md, ailang.toml}`. **M4.6a also
touches `medium.ail` and `medium_test.ail`, CHANGELOG and the version line,
so M5.0b is strictly sequenced after it.**

**Estimated:** 60 + 80 = 140 · **Deps:** none internal; it publishes after
M4.6a's release · **Registry:** contribute `sunholo/relativity`.

**Acceptance (commands):**
- `cd $PKG && $A test --package relativity`: `apparentDisc` at β 0.9, θ 90°,
  α 5° gives the centre and radius **in the oracle's neighbourhood**
  (25.928°, 2.184°), with the aberrated centre 25.842° pinned as *different*
  from the apparent centre; at β 0.99, (8.140°, 0.707°); at β 0.9, θ 150°,
  (82.021°, 9.940°); at β 0 it is the identity to 1e-15; the radius is finite
  over a φ sweep to the 0.999999c cap. `hoverPower(1, 0.1254)` = 0.1254·c
  to 1e-15 relative. The package value replaces the oracle wherever they
  differ in the last digits, and that is recorded in the notes.
- `$A pkg quality` lists no gates, and `$A pkg publish --dry-run` is clean.
- Independent evaluation (a different agent or model from the author)
  ≥ 70/100, saved as
  `.ailang/state/evaluations/eval_R1-M5-PLANETS-M5.0b_round_N.json`.
- The published version's exports:
  `grep -n 'apparentDisc\|hoverPower' ~/.ailang/cache/registry/sunholo/relativity/<new>/{optics,medium}.ail`.

**Test-first:** the three geometries, identity at rest, finiteness at the
cap, `hoverPower` linearity.

### Wave 2

#### M5.0a2: `sunholo/celestial` light, gravity and rings; publish 0.1.0
**Status:** ✅ `sunholo/celestial@0.1.0` published after the independent eval (89/100, B1 fixed first); ⏸ P-pkg-a needed no Mark action (Q1).
**Scope:**
- **`lighttime`**: `retardedTime(srcFn, obs, t)`, a fixed-point iteration
  run exactly 4 times.
- **`gravity`**: `accelerationAt(bodies, x, jdTDB)`, using IAU 2015 nominal
  GM and returning `inside` within any body's radius.
- **`reflect`**: `starIlluminanceAt`, `lambertPhase`, `lambertRadiance`,
  `minnaertRadiance`, `rhoFromGeometricAlbedo` and `discIlluminance`.
- **`rings`**: `ringLitRadiance`, `ringUnlitRadiance` (with the finite
  μ → μ0 limit) and `ringTransmission`.

Then the CHANGELOG, `[release] kind`, quality with no gates, an
**independent evaluation of the whole package** (both parts), a dry run
and publishing **0.1.0** (⏸ P-pkg-a).

**Files:** `$PKG/packages/celestial/{lighttime, gravity, reflect,
rings}{.ail, _test.ail}`, `CHANGELOG.md`, `ailang.toml` (exports).

**Estimated:** 190 + 170 = 360 · **Deps:** M5.0a1 · **Registry:** none, new
package.

**Acceptance (commands):**
- `cd $PKG && $A test --package celestial` covers both parts. For this part:
  Jupiter's lag at opposition from Earth is about 2,094 s, with the
  27,400 km displacement (both re-derived as package values); g at 50,000 km
  above Earth is about 0.1254 m/s² and at 1.5 R♃ about 11.0 m/s²; `inside`
  within R; E☉(1 AU) = 1.261 × 10⁵ lux for e1AU from relativity's
  `illuminanceFromV(-26.74)`, passed in as a literal so there is no import;
  Φ(0) = 1, Φ(π/2) = 1/π, Φ(π) = 0; Minnaert with k = 1 equals Lambert to
  1e-15; the ρ ↔ p round trip holds to 1e-12; Jupiter at opposition has
  V ≈ −2.77 (r 5.20, Δ 4.20, p_V 0.538); the ring lit face at τ → ∞ equals
  Lommel–Seeliger; at τ → 0 both faces go to 0; the unlit face is finite at
  μ → μ0; transmission(0, μ) = 1 and transmission(τ, 1) = e^(−τ).
- `$A pkg quality` lists no gates; the CHANGELOG has `[release] kind`;
  `$A pkg publish --dry-run` is clean.
- **AC1:** an independent evaluation ≥ 70/100 is saved **before publishing**:
  `ls .ailang/state/evaluations/eval_R1-M5-PLANETS-M5.0a_*`.
- After the publish: `$A search celestial` lists `sunholo/celestial@0.1.0`.

**Test-first:** every row of the design's M5.0a table that falls in these
modules.

### Wave 3

#### M5.1a: Sol and α Cen data, and the package pins
**Status:** ✅ executed on `sprint/m5.1a-system-data` (2026-10-03); independent eval PASS 89/100, round-1 follow-ups applied.
- [x] Pins in their own commit: relativity 0.7.0, celestial 0.1.0; lockfile relocked; bundled cache refreshed.
- [x] `sim/data/sol.ail`, `sim/data/acen.ail` with citation keys and per-field provenance; `sim/celestial_test.ail` (22 checks).
- [x] AC6 via `make sim` (test blocks) and `make strict-m5` (strict VM = interpreter).
- [x] Mutants (dropped citation key, unknown key, retracted row, upgraded candidate, provenance without a note, moon P misread, ring edge) fail.
- [x] Deviations recorded in the sprint JSON: design §M5.1 names **12** moons (it says 11); the design-repo ring table's Uranus row is wrong (published 1.637-2.002 R); its other differences are scope or definition (tested as published edges); Uranus/Neptune Minnaert k assumed 1 (no citable value).
**Scope:**
- **`sim/data/sol.ail`**, every row with a citation key: the Standish
  Table 2a elements and rates for the 8 planets; the IAU 2015 poles, W₀ and
  Ẇ; radius and flattening; GM; Mallama 2017 p_V; Minnaert k for the giants;
  the 11 moons' JPL SSD mean elements; the ring profiles for all four giants
  as `[(r_in_km, r_out_km, tau, w0)]` plus a tint.
- **`sim/data/acen.ail`**: the AB binary orbit (Akeson 2021 / Pourbaix &
  Boffin 2016); Proxima b, d and c; A b as one published fit; per-field
  provenance `measured | inferred(relation) | assumed(value)`; `status`;
  no retracted row. The exoplanet snapshot is fetched by `starmap-manager`
  and pinned by sha256 in `data/raw/` (gitignored, with the pin tracked).
- **The pins:** `sim/ailang.toml` adds `sunholo/celestial = "0.1.0"`, bumps
  relativity to the M5.0b release and adds the new module exports;
  `make deps` relocks; the bundled cache moves with them (gate 3).
- The provenance half of `sim/celestial_test.ail`.

**Files:** `sim/data/sol.ail`, `sim/data/acen.ail`, `sim/celestial_test.ail`
(new), `sim/ailang.toml`, `sim/ailang.lock`, `mk/m5.mk` (new) and **one**
`include mk/m5.mk` line in `Makefile`, `data/planets/EXOPLANETS.SHA256`
(the snapshot pin). **Conflicts:** `sim/ailang.toml` and the lock with
M4.6a, M4.1 and M4.7 (F4).

**Estimated:** 190 + 90 = 280 · **Deps:** M5.0a2, M5.0b · **Registry:** depend
on both.

**Acceptance (commands):**
- **AC3:** `make deps test AILANG=$A`. `grep -n 'celestial\|relativity'
  sim/ailang.toml` shows 0.1.0 and the M5.0b version; the lockfile and the
  bundled cache agree (ignore `generated_at`).
- **AC6:** `make sim AILANG=$A` (`celestial_test.ail`): every body row has a
  citation key; every α Cen body has `status` and per-field provenance; no
  `retracted` row is loaded; ring radii match the design repo's ring table
  within 1 % of R (Saturn 1.11–2.27, Jupiter 1.29–1.81, Uranus 1.49–1.95,
  Neptune 1.69–2.54).
- `make strict AILANG=$A`: the data modules load under `--strict-bytecode`.

**Test-first:** the provenance and ring-table checks. A mutant that drops
one citation key, or adds a retracted row, must fail.

### Wave 4

#### M5.1b: `sim/celestial.ail` and the `system` change set
**Status:** ✅ executed on `sprint/m5.1b-system-at` (2026-10-03); protocol **2.3** (main was at 2.2). Independent eval pending.
- [x] AC5 in `make sim` (`celestial_test.ail`): positions = `stateFromElements` ∘ `eclipticToGalactic` to 1e-12 AU (8 planets at 4 epochs, 12 moons on their hosts); Jupiter's lag from Earth at the 2023-11-03 opposition = `lightTimeDays` within 1e-6 s (1,986 s); `mean-orbit` outside the window (agrees with `elementsAt`'s flag).
- [x] AC4 system half: `make strict-m5` runs `systemVm` (strict VM = interpreter, byte for byte); `make parity-v2-system` checks the 2.3 tail of `v2_session.ndjson` (VM = interpreter via `parity-v2`).
- [x] `git diff origin/main -- sim/protocol_test.ail` is additions only.
- [x] `make test` green.
- [x] Deviations (sprint JSON notes): `ship.ail` unchanged (the pure server already builds every reply; ship.ail prints it); the bridge keeps the section in `SimBridge.system` (`state` is the raw message) and opts in via `want_minor`; `kind` is star | planet | moon with `ring_id` naming a ring host; α Cen's system waits for M5.7 (its AB orbit is M5.7's registry row); the Earth-Moon barycentre split is a celestial 0.1.1 follow-up (gate 3).
**Scope:** pure functions with no I/O, clean under `--strict-bytecode`:
- `bodyAt(sys, id, jd)` returns position and velocity in the galactic frame
  (km, km/s, float64) plus the pole and W.
- `systemAt(sys, t, ship)` returns a `[BodyView]` with every field from
  design §M5.1: `rel_km` at the retarded time, `sun_dir`, `r_au`,
  `phase_deg`, `e_v_lux`, `light_age_s`, `visitable` and `source`.
- The time base is `system.jd` = scenario epoch + Earth time; outside the
  window `ephemeris` is `"mean-orbit"`, otherwise `"jpl-approx"`.
- The protocol gains an additive `system{jd, ephemeris, frame: "galactic",
  bodies}` change set, a minor bump taken at merge time (F4).
- `ship.ail` emits it each tick, and `sim_bridge.gd` parses it into
  `state.system`.
- A `make strict` entry `systemVm`, and a `parity-v2` fixture extension.

**Files:** `sim/celestial.ail` (new), `sim/celestial_test.ail`,
`sim/protocol.ail`, `sim/protocol_test.ail`, `sim/ship.ail`, `sim/core.ail`
(state gains the epoch and system handle, ≤ 40 lines),
`bridge/sim_bridge.gd`, `tests/test_sim_bridge.gd`,
`tests/fixtures/v2_session.ndjson` (+ system lines),
`tests/fixtures/system_sol.ndjson` (new; the fixture for M5.2a's early
start), `mk/m5.mk`. **Conflicts:** `protocol.ail`, `ship.ail` with M4.1;
`sim_bridge.gd` with M4.3a and M4.4; `core.ail` with M3 (F4).

**Estimated:** 140 + 130 = 270 · **Deps:** M5.1a · **Registry:** depend on
both.

**Acceptance (commands):**
- **AC5:** `make sim AILANG=$A`: sim positions equal
  `stateFromElements` ∘ `eclipticToGalactic` to 1e-12 AU; Jupiter's retarded
  lag from Earth at opposition equals the package value within 1e-6 s;
  outside 3000 BC–3000 AD `ephemeris` is `"mean-orbit"`.
- **AC4 (system half):** `make strict parity-v2 AILANG=$A`: `systemVm` runs
  on the strict VM; the `system` lines of the v2 session are byte-identical
  on the VM and the interpreter.
- M2's old-message tests in `protocol_test.ail` pass **unmodified**:
  `git diff origin/main -- sim/protocol_test.ail` shows additions only.
- `make test AILANG=$A AILANG_BIN=$A` is green (AC20 holds for every
  milestone).

**Test-first:** AC5's three checks, the encoder's round trip,
old-message compatibility.

### Wave 5 to 7, RENDER track (stacked into `m5-render`)

#### M5.2a: physically lit globes, point/disc handoff, textures
**Scope:**
- **`planets/system_view.gd`** is fed only by `state.system` and renders
  into M4's (today: M1's) sky SubViewport, pre-exposed. Placement: float64
  direction and asin(R/d), each group scaled by 1/d, and no raw km in a
  `Vector3` (gate 5).
- **Point or disc:** below 2 px a body goes to the starfield instancer
  (`add_point_sources`, with e_v_lux and T 5,772 K); at 2 px or more it is a
  disc.
- **`planets/planet.gdshader`:** Minnaert/Lambert radiance mirroring the
  package; albedo textures normalised to p_V; the shared system pole; the
  Sun as a limb-darkened disc (u = 0.6, flux-normalised), clipped until
  row 6b.
- **`physics/planets.gd`:** the CPU mirror.
- **Textures:** `make planet-assets` and `make planet-publish` (shell glue
  in `tools/sky_assets.sh`, or a sibling `tools/planet_assets.sh`) fetch
  Solar System Scope 2k CC BY 4.0 (about 25 MB) by sha256 from
  `gs://stapledons-voyage-assets/planets/`. Pins and CREDITS live in
  `data/planets/`, and `infra/gcp/setup.sh` gets the prefix noted.
  `tools/planet_textures.gd` (Godot headless) normalises each texture to the
  disc-integrated p_V.
- **Goldens G-M5-4 and G-M5-6** in `tools/m5_golden.gd`.

**Files:** `planets/system_view.gd`, `planets/planet.gdshader`,
`physics/planets.gd`, `tools/m5_golden.gd`, `tools/planet_textures.gd`,
`tools/planet_assets.sh`, `tests/test_planets.gd` (new); `sky/starfield.gd`
(handoff method); `main.gd` (instance `SystemView`, ≤ 10
lines; **M4.2 conflict**); `data/planets/{SHA256SUMS, CREDITS}`;
`.gitignore` (`assets/planets/`); `infra/gcp/setup.sh`; `mk/m5.mk`;
`tests/test_physics.gd` (`_m5_photometry` block).

**Estimated:** 210 + 150 = 360 · **Deps:** M5.1b (or its fixture) · **Registry:**
depend (mirror).

**Acceptance (commands):**
- **AC7 (photometry half):** `make physics lint-precision AILANG=$A`:
  `physics/planets.gd` matches the package values for `lambertPhase`,
  `minnaertRadiance`, `discIlluminance` and `starIlluminanceAt` within 1e-12
  relative. There is no hand-computed γ or 1 − β, and `lint-precision`
  covers `planets/`. If M4.6's `lint-precision` hasn't landed, M5.2a adds a
  `planets/`-only grep target to `mk/m5.mk`, which M4.6 later absorbs.
- **AC8 (part):** `make golden` (GPU): **G-M5-4**, Jupiter at opposition,
  where the integrated disc illuminance equals `discIlluminance` within 2 %;
  **G-M5-6**, integrated flux at 1.9 and 2.1 px diameter agrees within 2 %.
  M1's existing golden counts are unchanged.
- **AC10:** `make planet-assets && test -z "$(git ls-files assets/planets)"
  && grep -q 'CC BY 4.0' data/planets/CREDITS` (F6).
- ⏸ **L-tex** is recorded (see the pause points) before `make planet-publish`
  uploads anything.

**Test-first:** CPU mirror values against package probes; the flux
continuity of the point/disc crossover on the CPU; a texture normalisation
check (the disc-integrated albedo of each normalised texture equals p_V
within 1 %).

#### M5.2b: rings, shadows and atmospheres
**Scope:**
- **`planets/ring.gdshader`:** the τ(r) lookup from `system` data; lit and
  unlit faces from the signs of the sun and view elevations; alpha =
  1 − transmission; Neptune's arcs as an azimuthal factor.
- **Analytic shadows:** the ring shadow on the globe and the globe's shadow
  on the rings (ray–plane and ray–sphere toward the Sun, transmission
  e^(−τ/μ0), penumbra from the Sun's angular radius), plus up to 4 moon
  shadows on their planet in the same code.
- **`planets/atmosphere.gdshader`:** single-scattering Rayleigh + Mie with
  exponential density for Earth, Venus and Titan, labelled in code and
  codex as an approximation.
- The CPU mirror of the ring functions; **golden G-M5-5**.

**Files:** `planets/ring.gdshader`, `planets/atmosphere.gdshader`,
`planets/shadows.gdshaderinc` (new), `physics/planets.gd`,
`tools/m5_golden.gd`, `tests/test_planets.gd`, `planets/system_view.gd`.

**Estimated:** 170 + 100 = 270 · **Deps:** M5.2a · **Registry:** depend
(mirror).

**Acceptance (commands):**
- **AC7 (rings half):** `make physics`: the CPU ring functions match
  `ringLitRadiance`, `ringUnlitRadiance` and `ringTransmission` within 1e-12
  relative, including the τ → ∞, τ → 0 and μ → μ0 limits.
- **AC8 (part):** `make golden`: **G-M5-5**, Saturn at a fixed epoch, where
  the globe's shadow edge on the B ring and the ring shadow on the globe lie
  within 0.75 px of the analytic CPU position, and transmission through the
  shadow equals e^(−τ/μ0) within 2 %.
- `make capture-m5 SET=rest` writes `renders/m5/rest/`: the start at Earth
  (EYE and fixed EV), Jupiter at opposition with a Galilean shadow, Saturn
  with ring shadows, a ring close-up and the crossover pair. Then ⏸
  **R-m5a**.

**Test-first:** the ring limits, and the CPU shadow-edge geometry at the
fixed epoch.

#### M5.4: the highlight-protecting meter
**Scope:** in the meter that is live after #79 (F3), EV_meter = max(the
current meter's EV, EV(P99.5 luminance / AgX headroom)) for both EYE and
CAMERA. EYE stays EV = max(EV_dark, EV_meter). **Golden G-M5-7.**

**Files:** `sky/exposure.gd`, `sky/sky_meter.gd` (from #79),
`tools/m5_golden.gd`, `tests/test_physics.gd` (`_m5_meter` block).
No open conflict (#79 merged).

**Estimated:** 40 + 60 = 100 · **Deps:** M5.2a (a planet to meter) · **Registry:** none.

**Acceptance (commands):**
- `make physics`: with no bright object the P99.5 term is below the meter's
  EV, so the output is identical to the pre-M5.4 meter on M1.5a's and
  M1.8's test skies; with Saturn covering 25 % of the frame, its centre
  maps below the AgX white point.
- **AC8 (part):** `make golden`: **G-M5-7** passes (a sky-only pixel next to
  a planet equals the SubViewport's within 1/255; the Saturn 25 % case is
  below white), and **M1.5a's and M1.8's exposure golden lines pass
  unchanged**, comparing the golden log's exposure lines before and after.

**Test-first:** the dark-sky invariance case written first. It must pass
before and after the change.

#### M5.3: the relativistic view: rest-frame tiles and the exact warp
**Scope:**
- **Rest-frame tiles:** one per resolved body group, aimed at the group,
  with resolution scaled by 1/D at the centre and capped at 4,096².
- **`planets/flyby_warp.gdshader`:** in the sky SubViewport, before the
  single tonemap, n = `deaberrate`(n′) per pixel, then a tile sample.
- **Doppler:** D = 1/(γ(1 − β cos θ′)), with 1 − β cos θ′ rewritten as
  (1 − β) + β(1 − cos θ′); γ and 1 − β come from the sim as float64
  uniforms. The radiance and chromaticity at D·T come from M1's `bb_lut`.
- Composited far to near; at β = 0 the warp is the identity.
- **Goldens G-M5-1, G-M5-2 and G-M5-3.**

**Files:** `planets/flyby_warp.gdshader`, `planets/tile_renderer.gd` (new),
`planets/system_view.gd`, `physics/planets.gd` (CPU warp reference),
`tools/m5_golden.gd`, `tests/test_physics.gd` (`_m5_apparent_disc` block),
`mk/m5.mk`.

**Estimated:** 160 + 220 = 380 · **Deps:** M5.2b · **Registry:** depend
(mirror relativity).

**Acceptance (commands):**
- **AC7 (SR half):** `make physics lint-precision`: `apparentDisc` at the
  three geometries and D at the disc centre (2.2871, 7.0623, 0.4981 as
  package values) are copied from the probe and not computed in GDScript;
  the CPU warp reference matches within 1e-9 for angles in degrees; the lint
  finds no `1.0 - beta`.
- **AC8 (part):** `make golden`: **G-M5-1**, a uniform sphere at
  β ∈ {0, 0.5, 0.9, 0.99} × θ ∈ {30°, 90°, 150°}, where the fitted limb
  circle's centre and radius match `apparentDisc` within 0.75 px;
  **G-M5-2**, where at β 0.9, θ 90° the RMS of the limb's distance from the
  fitted centre is < 0.5 px; **G-M5-3**, where linear radiance at the
  leading edge, centre and trailing edge matches the CPU blackbody at
  D(θ′)·5,772 K within 1 % in the debug linear target.
- `make capture-m5 SET=flyby` writes `renders/m5/flyby/`: Saturn at β 0,
  0.5, 0.9 and 0.99, forward, sideways and astern. Then ⏸ **R-m5b**.
- `make bench SCENE=flyby` is run once and its result recorded (AC13 is
  asserted at M5.8). If p99 is over 16.7 ms here, the tile cap is revisited
  before M5.8.

**Test-first:** the CPU warp reference against `apparentDisc` and against
`deaberrate` on 1,000 random directions; β = 0 identity.

### Wave 5 to 8, NAVIGATION track

#### M5.5a: body targets, stop and flyby geometry, intercept, refusals
**Status:** ✅ executed on `sprint/m5.5a-body-targets` (2026-10-03); protocol **2.4** (main was at 2.3). Independent eval pending.
- [x] AC14 in `make sim` (`navigation_test.ail`): the sim computes a body's target (a bogus client `index`/`pos` gives the same intent and byte-identical replies); stop and flyby trips = `planBurnCoastBurn` on the independently computed leg to 1e-9; the Moon at 0.99c falls back to flip-and-burn exactly as M2.
- [x] AC15: `collision`, `ring_crossing`, `too_close`, `not_visitable` and `committed` each have a triggering fixture and a passing one (too_close and ring_crossing at ±1 km / ±10 km of the threshold), plus `out_of_range` and `no_converge`.
- [x] AC17 residual half: < 1e-9 of the leg for the Saturn flyby at 0.5c, the Io stop at 0.001c and a Mercury chase (contraction about 0.17).
- [x] AC4 planner half: `make strict-m5` runs `navigationVm` (18 checks plus a 2.4 session); strict VM = interpreter, byte for byte.
- [x] Mutants: each dropped refusal, a client `pos` honoured, 11 iterations (two ways), no_converge off, stale commit allowed, the minor gate off, M4 stand-off applied to a body leg, no 0.1 AU clamp, the clock sign, the pass tilt, the run-out margin: all 18 killed.
- [x] M5.1b evaluator findings folded in: the star's zero `sun_dir` documented; a retarded `sun_dir`/`r_au`/`phase_deg` test (kills mutant M7); the four 2.3 checks in `protocolVm`; design §M5.1 updated; the hello reports relativity 0.7.0 from minor 4 (`make hello-pin`); celestial 0.1.1 named as a dependency of M5.5b and M5.7.
- [x] M4.2 finding: home is the target id `"Sol"`, not catalogue index 0 (Proxima), in `standoffFor`, the arrival point and the news `return` entry.
- [x] `make test` green.
**Scope:** in a new **`sim/navigation.ail`** (pure), with `core.ail`
dispatching to it:
- `Target` gains the body form `{kind: "body", id}`, and **for a body the
  client's `pos` is ignored**.
- **Stop:** `standoff_km` is the default max(10 R, 1.5 × outer ring), and the
  player's range is clamped to the safety minimum … 0.1 AU.
- **Flyby:** `b_km`, `clock_deg` and `run_out_km` (default: braking distance
  + 10⁶ km), with one burn-coast-burn along the line through the pass point.
- **Intercept:** 12 fixed iterations of t_a ← t₀ +
  `planBurnCoastBurn`(‖aim(t_a) − x₀‖).galaxyTime, asserting the residual.
- **Refusals:** `collision`, `ring_crossing`, `too_close`, `not_visitable`,
  `committed`, plus `no_converge` (design §Risks: "a non-converging plan is
  refused").
- **Protocol:** `journey.plan` gains `target_kind`, `intercept{t, pos}`
  and `pass{t, b_km, beta, d_at_pass}`.

**Files:** `sim/navigation.ail`, `sim/navigation_test.ail` (new),
`sim/core.ail` (dispatch, ≤ 40 lines), `sim/protocol.ail`,
`sim/protocol_test.ail`, `bridge/sim_bridge.gd` (plan fields),
`sim/ailang.toml` (export), `mk/m5.mk` (strict entry `navigationVm`).

**Estimated:** 190 + 160 = 350 · **Deps:** M5.1b · **Registry:** depend.

**Acceptance (commands):**
- **AC14:** `make sim` (`navigation_test.ail`): the sim computes the target
  for `kind: "body"` (a fixture with a bogus client `pos` gives the same
  plan); stop and flyby plans equal `planBurnCoastBurn` on the computed leg
  length to 1e-9; short legs fall back to flip-and-burn exactly as M2 does.
- **AC15:** `make sim`: `collision`, `ring_crossing`, `too_close`,
  `not_visitable` and `committed` each have one fixture that triggers them
  and one that just passes.
- **AC17 (residual half):** `make sim`: the intercept residual is < 1e-9 of
  the leg for the Saturn flyby at 0.5c and for an Io stop at 0.001c (the
  worst contraction).
- **AC4 (planner half):** `make strict`: `navigationVm` runs on the strict
  VM, and the output equals the interpreter's.

**Test-first:** AC14, AC15 and AC17 fixtures, then mutants: drop one
refusal, use the client `pos`, or run 11 iterations. Each must fail.

#### M5.5b: gravity hold, holding state, confirm class, the Sol tour

**Carried in from the M5.5a evaluation** (`.ailang/state/evaluations/eval_R1-M5-PLANETS-M5.5a_round_1.json`, 95/100; do these in M5.5b, before the Sol tour golden freezes the news stream):
- **`stale_plan` vs D-12** (`sim/navigation.ail:267`): the host clock runs on every planning tick and the commit is a 1.5 s hold, so every body plan would be refused. Keep the `BodyReq` in `NavPlan`, re-run `planBody` at commit time, commit the fresh plan, and refuse only if that is refused.
- **In-plane ring legs** (`sim/navigation.ail:183-189`): a leg lying in the ring plane (for example after a Titan stop) is accepted through the rings. Also refuse when the host's nearest approach is inside `ringKm` and the height above the plane is below a ring half-thickness.
- **Body arrivals fire M4 consequence news** (`sim/core.ail:446-460`): decide and gate this before the tour golden.
- **Test gaps:** four mutants survived. Assert Io's index (10); add collision fixtures at R + bubble ± 1 km and a D ≈ 2b flyby fixture; check the Doppler sign with a short run-out pass.
- Low, later: the hello relativity string differs by minor (`sim/protocol.ail:49-57`); unify it when the x86_64 goldens are next regenerated.

**Scope:**
- **Gravity hold:** during cruise and at holds the drive cancels
  `accelerationAt`; the ledger gains `hold_j` += `hoverPower`(m_eff, |g|) dτ
  per tick; matching velocity on arrival is applied in one tick and
  ledgered.
- **Holding state:** the `docked` phase becomes holding at a body; `ship`
  gains `hold{body, offset_km, g_m_s2, hold_w}`; **the game starts holding
  50,000 km above Earth.**
- **Confirm class (N1, sim side):** every plan carries `confirm ∈ {"full",
  "light"}` (light means a body target with Earth time ≤
  `light_confirm_max_earth_s` = 86,400, a scenario parameter). Commit
  validity is unchanged.
- **The Sol tour:** `tests/replays/sol_tour.ndjson`, a hand-written input
  log: Earth → Moon stop at 0.01c → Saturn flyby at 0.5c, b = 3 R♄, north
  → Jupiter stop at 0.1c → α Cen plan and commit, with logged `dtau`
  including the step-down. A `make strict` entry `solTourRoundTrip`, and
  per-arch goldens until ailang#1465.

**Files:** `sim/navigation.ail`, `sim/navigation_test.ail`, `sim/core.ail`
(phase, ledger, start state, ≤ 40 lines), `sim/ship.ail` (scenario params),
`sim/protocol.ail`, `sim/protocol_test.ail`, `bridge/sim_bridge.gd`,
`tests/replays/sol_tour.ndjson` + per-arch goldens (new), `mk/m5.mk`.
**Conflicts:** `ship.ail` and `protocol.ail` with M4.1; the ledger with
M4.1's `drag_energy_j` reader (F4).

**Estimated:** 210 + 170 = 380 · **Deps:** M5.5a, M5.0b (`hoverPower`),
**`sunholo/celestial` 0.1.1** (the Earth-Moon barycentre split: Standish's
Earth row is the EMB, so Earth and the Moon are each 4,671 km off; the ship
starts 50,000 km above Earth, where that is 4.7°. Package first, gate 3; added
after M5.1b's evaluation) · **Registry:** depend.

**Acceptance (commands):**
- **AC16:** `make sim`: during cruise and holds the ship stays on the
  planned line or offset to 1e-6 km; the leg's `hold_j` equals the tick sum
  of `hoverPower(m_eff, ‖accelerationAt‖)` dτ to 1e-9 relative; at the start
  position ‖g‖ equals the package value (about 0.1254 m/s²).
- **AC19a (sim half):** `make sim`: boundary fixtures at 86,399 s, 86,400 s
  and 86,401 s give light, light and full; every star target is `full`; a
  commit is accepted or refused only for M2's reasons, whatever the class.
- **AC17:** `make sim && make replay SESSION=tests/replays/sol_tour.ndjson`:
  at the Saturn pass tick the ship–Saturn distance equals the planned `b_km`
  within 1 km.
- **AC18 (sim half):** `make replay SESSION=tests/replays/sol_tour.ndjson
  journey-replay`: byte-identical on the VM, the interpreter and this
  arch's golden; the log has no camera input
  (`! grep -q '"camera"' tests/replays/sol_tour.ndjson`).
- **AC4:** `make strict parity-v2`, including `solTourRoundTrip`.
- M2's α Cen replay (`make journey-replay`) is unchanged.

**Test-first:** the hold-ledger sum, the line-holding residual and the
confirm boundary fixtures; then the Sol tour golden recorded **once**
through `make replay-record LOG=tests/replays/sol_tour.ndjson` as a
reviewed diff.

#### M5.6a: system map, planning panel and the two confirm dialogs (stacked into `m5-nav-ui`)
**Scope:**
- **`ui/system_map.tscn`/`.gd`:** a zoom level of M2's galaxy map, reached
  by selecting Sol. An orrery at the current Earth time, with the "log
  scale" toggle; name, distance, light age and status badge per body. It
  never draws into the sky. The same widget appears in view-only mode for
  M5.7.
- **Planning panel:** Stop (stand-off slider) or Fly by (b slider with
  greyed minimum, clock dial with a preview); a log speed slider from
  0.001c to 0.99c; the plan readout through `DisplayBinding`; refusal
  phrases from a fixed table.
- **Commit:** with `confirm == "light"` a one-line strip ("No cancel once
  committed", one press, Esc to go back); with `"full"` M4's D-12 dialog
  unchanged. Both emit the same `commit{plan_id}`.

**Files:** `ui/system_map.tscn`, `ui/system_map.gd`, `ui/plan_panel_body.gd`,
`ui/light_confirm.tscn` (new), `ui/galaxy_map.gd` (Sol → system zoom hook),
`ui/display_binding.gd` (**extended if M4.3a has landed, otherwise created
with M4.3a's planned API**, Mark Q4), `tests/test_system_map.gd` (new),
`mk/m5.mk` (`ui` gains the test). **Conflict:** `ui/galaxy_map.gd`
(M2-owned; M4 doesn't list it), `ui/display_binding.gd` with M4.3a.

**Estimated:** 210 + 90 = 300 · **Deps:** M5.5b (or fixture plans) ·
**Registry:** none.

**Acceptance (commands):**
- **AC19 (map and panel):** `make ui AILANG_BIN=$A`: every number on the
  system map and the planning panel is a formatted sim field (the
  `DisplayBinding` audit).
- **AC19a (UI half):** `make ui`: the dialog audit shows a light plan opens
  the strip and a full plan opens the D-12 dialog, and both emit the
  identical `commit{plan_id}` line (byte-compared).
- **AC11 (refusal half):** `make ui`: selecting an α Cen planet in view-only
  mode offers no Plan button, and a forced plan shows the
  `not_visitable` phrase.

**Test-first:** the display audit fixture (a hand-typed number must
fail), both dialog paths, log/linear toggle positions.

#### M5.6b: transit (window view, HUD additions, in-system warp)
**Scope:**
- **Window view (V):** the sky camera full screen with
  `ui/free_look_camera.gd`.
- **HUD additions:** target distance, time to pass or arrival, β, D at the
  target, apparent size and `hold_j`.
- **In-system warp levels:** 1, 10, 10², 10³, 10⁴ and 10⁵ ship-seconds per
  real second; an automatic step-down to 1× from 30 s of ship time before
  the pass, and back up after it. Each step is a logged `dtau`.
- **At a stop:** warp runs the hold; the galaxy map is available.

**Files:** `ui/window_view.gd` (new), `ui/journey_hud.tscn` (additions;
**M4.3a**), `ui/insystem_warp.gd` (new), `main.gd` (V key dispatch, ≤ 5
lines; **M4.2**), `tests/test_system_map.gd`.

**Estimated:** 90 + 40 = 130 · **Deps:** M5.6a · **Registry:** none.

**Acceptance (commands):**
- **AC19 (HUD):** `make ui`: the in-system HUD passes the display audit.
- **AC18 (UI half):** `make ui` records a scripted pass through the
  harness, and the emitted `dtau` sequence includes the step-down and equals
  the sol tour log's; `make replay SESSION=tests/replays/sol_tour.ndjson`
  stays green.
- `make capture-m5 SET=nav` writes `renders/m5/nav/`: the system map
  (linear and log), the planning panel (stop and flyby), the light strip
  next to the full dialog, the transit HUD, and the window view at the
  Saturn pass. Then ⏸ **R-m5c**.

**Test-first:** the step-down schedule as a pure function of
time-to-pass; HUD fields bound to sim fields.

### Wave 9 and 10, JOIN

#### M5.7: the α Cen arrival scene, inset, codex; the start at Earth
**Scope:**
- **The α Cen arrival:** A and B placed from the AB orbit at the arrival
  epoch; Proxima from the starfield; planets only as points from
  `systemAt`, and none drawn as a disc.
- **Navigation inset:** M5.6a's widget in view-only mode, labelled
  "schematic, not to scale", with badges, provenance and `last_light`.
- **Codex entry** "The worlds of α Centauri", with PL-n `checks:` through
  M4.7's lore pipeline.
- **The start-at-Earth view:** EYE light-adapted, stars out.
- **Golden G-M5-8.**
- Ship placement at the stand-off uses M4.1's `consequence.ail` if it has
  landed, otherwise a scenario setting.

**Files:** `ui/arrival_inset.tscn` (new; reuses `ui/system_map.gd`),
`ui/arrival_card.tscn` (**M4.3a**; additions only), `data/lore/` entry (via
M4.7's importer), `tools/m5_golden.gd`, `planets/system_view.gd` (α Cen
case), `mk/m5.mk`. Outside this repo: a docs PR to `$D` adding
`physics/planets-spec.md` PL-n rows and relativity-spec RS-24 to RS-29 (F8).

**Estimated:** 100 + 80 = 180 · **Deps:** M5.3, M5.6a, M5.5b, **`sunholo/celestial`
0.1.1** (the Earth-Moon barycentre split, for the start-at-Earth view; added
after M5.1b's evaluation) · **Registry:** depend.

**Acceptance (commands):**
- **AC11:** `make ui` (inset audit: every loaded α Cen body is listed with
  its badge and provenance) and `make sim` (the refusal fixture
  `not_visitable` for every α Cen planet).
- **AC12:** `make lore-check AILANG=$A`: the codex entry's numbers match
  their PL-n values. This needs M4.7 and the `$D` PL-n rows (Q3).
- **AC8 (part):** `make golden`: **G-M5-8**, where in EYE mode no candidate
  planet is above the display floor, and A and B are separated by the
  orbit's value at the arrival epoch within 0.75 px.
- `make capture-m5 SET=acen` writes `renders/m5/acen/`: the arrival in EYE
  and CAMERA (fixed long exposure) with the inset, and the codex page. Then
  ⏸ **R-m5d**.

**Test-first:** the inset audit fixture (drop a badge and it must fail);
G-M5-8's CPU separation from the orbit.

#### M5.8: G-M5-9, the full capture, bench and the report
**Scope:**
- **G-M5-9:** at the sim's Saturn pass tick in the Sol tour, the rendered
  centre is within 0.75 px of the CPU projection of `pass.b_km` through
  the ship basis.
- **`make capture-m5`** (all sets) writes `renders/m5/` and a contact
  sheet.
- **`make bench SCENE=flyby`:** Saturn plus 6 moons at β 0.9, medium tier,
  2560×1440, recording the host load.
- **`make physics` sweep:** every body is finite at every tick of the Sol
  tour.
- **`make lint-precision`** covers `planets/` and `ui/system_map*`.
- **The report draft:** `design_docs/implemented/r1/m5-report.md`.

**Files:** `tools/m5_golden.gd`, `main.gd` (`--golden-m5`, `--capture-m5`,
the bench scene flag, ≤ 15 lines), `mk/m5.mk` (`capture-m5`, the
`bench SCENE=` passthrough, the `golden` hook), `tests/test_physics.gd`
(the Sol tour sweep), `design_docs/implemented/r1/m5-report.md` (draft).

**Estimated:** 60 + 80 = 140 · **Deps:** all · **Registry:** depend.

**Acceptance (commands):**
- **AC8:** `make golden`: G-M5-1 to G-M5-9 all pass (a line count of
  `^ok +G-M5-` equals the case count) and the existing M1/M4 cases are
  unchanged.
- **AC9:** `make capture-m5` writes the contact sheet;
  `jq '.features[] | select(.id | startswith("M5.8")) | .review'
  .ailang/state/sprints/sprint_R1-M5-PLANETS.json` shows Mark's S-M5
  approval (F5).
- **AC13:** `make bench SCENE=flyby` gives p99 < 16.7 ms at 2560×1440. The
  host load is logged; under load the A/B run against `origin/main` is
  repeated (the M1.8 precedent).
- **AC7 (sweep):** `make physics lint-precision`: finite values for every
  body at every Sol tour tick, and no NaN near a body.
- **AC20:** `make test AILANG=$A AILANG_BIN=$A` is green locally and in CI;
  `make python-guard` passes with no new `*.py`.

**Test-first:** G-M5-9's CPU projection; the finiteness sweep.

## Mark's stops (pause points)

| Id | After | What Mark does | Blocks |
|---|---|---|---|
| **⏸ P0** | now | **DONE: approved by Mark (attended 2026-10-03), Q1–Q6 answered** | (nothing; satisfied) |
| **⏸ P-pkg-b** | M5.0b, after M4.6a's release is published | The controller publishes relativity under the **standing publish grant (relativity only)**, after an independent eval ≥ 70, quality with no gates and a dry run. Mark is told the version; no action needed unless the eval fails | M5.1a |
| **⏸ P-pkg-a** | M5.0a2 | The controller publishes the new package `sunholo/celestial` 0.1.0 under **the relativity rule (Mark, Q1, P0 2026-10-03)**: an independent eval ≥ 70 (AC1), `pkg quality` with no gates, a dry run. **No Mark action needed**; he is told the version | M5.1a |
| **⏸ L-tex** | M5.2a, before `make planet-publish` | **The texture licence check:** the Solar System Scope source URL and its CC BY 4.0 terms as of the download date, the exact attribution text in `data/planets/CREDITS` and on the in-game credits screen, the file list with sha256s, and confirmation that no unlicensed texture (the Go build's `earth.jpg` and `alien/*`) is included. The upload is a maintainer action (gcloud) | the M5.2a merge (AC10) |
| **⏸ R-m5a** | M5.2b (`renders/m5/rest/`) | **Gate-2 review of the rest-frame planet renders:** Earth start (EYE and fixed EV), Jupiter at opposition with a moon shadow, Saturn with ring shadows, a ring close-up, the point/disc crossover | the `m5-render` merge |
| **⏸ R-m5b** | M5.3 (`renders/m5/flyby/` + the G-M5-1..3 log) | **Gate-2 review of the flyby aberration warp:** Saturn at β 0, 0.5, 0.9 and 0.99, forward, sideways and astern; the outline stays a circle, the leading edge goes violet, you see round the far side | the `m5-render` merge to main |
| **⏸ R-m5c** | M5.6b (`renders/m5/nav/`) | **Navigation UX review:** the system map, the planning panel, the light strip next to the full dialog, the transit HUD, the window view at the pass. Includes a review build (`make publish-dev`) so Mark can fly the tour | the `m5-nav-ui` merge |
| **⏸ R-m5d** | M5.7 (`renders/m5/acen/` + codex page) | **α Cen arrival review** (EYE and CAMERA, inset, badges) and the codex copy, which must state facts only (Pillar 2; the M4 S4 pattern) | the M5.7 merge |
| **⏸ S-M5** | M5.8 (`make capture-m5` contact sheet) | **The final gate-2 sign-off on the whole contact sheet**, recorded in the sprint JSON `review` field of M5.8 (AC9) | landing |
| **⏸ P-land** | S-M5 | The report, the design doc moved to `implemented/`, the design-repo changes (roadmap M5 section, spec amendments if not already made under F8, planets-spec, higgs-bubble note, supersede notes, lore entries, D-26 in decisions), the changelog | none |
| RB (non-blocking) | after M5.3 and M5.6b | Review builds (`make publish-dev`; `tools/install_review_build.sh --dev`), the D-16 "something up to review" pattern | none |

## Risks

| # | Risk | Likelihood | Mitigation |
|---|---|---|---|
| R1 | **Overrun.** At 1.6×, 4,040 becomes about 6,400 lines; the Godot milestones may run 2.4× like AI.6/7/9 | High | Every milestone planned at ≤ 400. Named seams inside the larger milestones: M5.3 can cut the far-to-near multi-tile compositor into M5.3b; M5.5b can cut the Sol tour into M5.5c; M5.2a can cut the texture tooling into M5.2c. 3 contingency iterations |
| R2 | **M4 conflicts** on `protocol.ail`, `ship.ail`, `sim_bridge.gd`, `main.gd`, the Makefile and `test_physics.gd` | High (M4 wave 1 is running now) | The F4 table: `mk/m5.mk`, `tools/m5_golden.gd`, `sim/navigation.ail`, function-block additions, the minor version taken at merge time, M5 rebasing on whatever M4 merged |
| R3 | **M4.6a's relativity release slips**, holding M5.0b's publish and so M5.1a and the whole sim spine | Medium | M5.0a1 and M5.0a2 proceed regardless. Mark ruled (Q2): M5.0b waits for M4.6a's release and publishes after it |
| R4 | **The first release of a new package** finds gaps in the quality gates or the registry publish | Medium | Precedent: M1.P and M2.0 published relativity cleanly. The independent eval runs on the whole package before publish. A dry run first |
| R5 | **Saturn's equinox check misses ±10 d** with JPL elements plus IAU poles | Low-medium | As in the design: use the IAU model's higher-order pole terms (data, not code) |
| R6 | **GPU gates** (G-M5-1..9, capture, bench) can't run in CI, and the bench is sensitive to host load (M1.8's p99 missed under load) | Medium | Run in the Studio GPU window, logs in notes; the bench records `uptime` load and an A/B against `origin/main` |
| R7 | ~~AILANG v0.52.0 lands mid-sprint~~: **retired**. The bump already merged (PR #73), so main is on **v0.52.0** with relativity 0.5.2 and the sprint runs on it from the start. A *later* bump during the sprint follows CLAUDE.md (CI, the bundled runtime and the lockfile move together; the `sol_tour` per-arch goldens are re-recorded as a reviewed diff) | none | none |
| R8 | **VM vs interpreter gaps** in new sim code (ailang#1478 pattern constructors, #1473 bare variable arms, #1419 NaN) | Medium | Strict entries for `systemVm`, `navigationVm` and `solTourRoundTrip` from the first commit; every disagreement shrunk and reported with `ailang messages` |
| R9 | **The soft dependencies on M4 haven't landed** by M5.6 and M5.7 (`DisplayBinding`, the HUD, the arrival card, lore-check, the stand-off) | Medium-high | M5.6a creates `DisplayBinding` with M4.3a's planned API (Mark, Q4); M5.7 uses a scenario stand-off; **AC12 is the one hard blocker** (M4.7 lore-check, plus the design-repo PL-n PR that goes up alongside M5.7, Mark Q3) |
| R10 | ~~PR #79 waits at R-e~~: **retired**, #79 merged during planning | none | none |
| R11 | **The tile budget astern at 0.99c** (14× magnification) | Low-medium | The cap at 4,096², a bench run already at M5.3, tiles only for resolved groups |
| R12 | **Exoplanet status changes** before M5.1a (Proxima d, α Cen A b) | Low | Status comes from the pinned snapshot, never hard-coded |

## Questions for Mark (answered at ⏸ P0, attended 2026-10-03)

1. **Publishing a new package (P-pkg-a).** May the controller publish
   `sunholo/celestial` 0.1.0 under the same rule as relativity?
   **ANSWERED: yes.** It publishes after an independent eval ≥ 70,
   `pkg quality` with no gates and a dry run (AC1), the same rule as
   relativity. ⏸ P-pkg-a no longer needs Mark.
2. **If M4.6a's relativity release slips.** **ANSWERED: the default.**
   M5.0b waits for M4.6a's release and publishes after it.
3. **The design-repo spec timing (F8).** **ANSWERED: the default.** A
   docs-only `stapledons-design` PR with `planets-spec.md` (PL-1…) and
   RS-24 to RS-29 goes up alongside M5.7, so AC12's lore-check can resolve
   the PL-n ids.
4. **Who creates `DisplayBinding`** if M4.3a hasn't landed when M5.6a
   starts? **ANSWERED: the default.** M5.6a creates `ui/display_binding.gd`
   with M4.3a's planned API, and M4.3a adopts it.
5. **The `hover_power` name and home (F7).** **ANSWERED: the default.**
   `medium.hoverPower(mEffKg, gMs2)` lives in relativity; M3's
   `hoverPowerPerKg` can compose it later.
6. **The 15-milestone split (F1).** **ANSWERED: accepted.** The five design
   rows are split as planned.
