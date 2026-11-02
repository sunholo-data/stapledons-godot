# Sprint R3-WORLDS: plan

**Design:** [worlds.md](worlds.md) (R3 W1 and W2).
**Status:** Proposed 2026-11-02, **waiting for Mark's approval**; nothing executes before it. OQ1–OQ9 are open; OQ1 (presets) and OQ5 (the baseline's transcription choices) gate W1.4 and W1.0 respectively.
**Progress file:** `.ailang/state/sprints/sprint_R3-WORLDS.json`
**Branches:**
- this plan: `design/r3-worlds`;
- execution: `feat/worlds-w1` (W1.0–W1.4) and `feat/worlds-w2` (W2.0–W2.5) in the game, each from a fresh full clone `../stapledons-godot-<topic>` (no worktrees);
- the packages: `feat/celestial-habitability` and `feat/worlds` in a fresh `sunholo-data/ailang-packages` clone at origin/main;
- the design repo: `feat/life-and-worlds` (W1.0, W1.4's recorded offsets, W2.5's Archive entries), a fresh clone; never the main checkout.

**AILANG:**
- Pin v0.54.18: every gate runs with `AILANG=runtime/bin/ailang` (`make runtime` first).
- AILANG prompt version loaded: **v0.16.7** (`runtime/bin/ailang prompt`, 2026-11-02).

## Summary

| | |
|---|---|
| Goal | The cited baseline and the dial as offsets, a calibration that finds each preset's offsets, and a galaxy whose every system has planets and a seeded history, with measured planets kept and nothing secret on the wire |
| Milestones | W1.0–W1.4, W2.0–W2.5 (11), about 4,500 LOC (about 1,050 in two packages) |
| Duration | About 15 working days attended at about 300 counted LOC a day (R3-EARTH-LINK, R3-SUNHOLO-AUDIO-REALISM), or about 4 weeks for the loop's share at its recent rate (about 150 a day, R2-SIMILAR-S0), plus `rig/full` runs (66–77 min) and two rulings |
| Risk | Medium-high: the first statistical calibration, the VM budget, two package publishes, and bands that may conflict |
| Critical path | W1.0 → W1.1 → W1.2 → W1.3 → W1.4 → W2.2; W2.0 beside W1; W2.1 and W2.3 after W1.2; W2.4 after W2.3 |

## Registry reuse (planner step 0, 2026-11-02)

`runtime/bin/ailang pkg search` for drake, habitable, "habitable zone", exoplanet, occurrence, "monte carlo", population, worlds, astrobiology, galaxy, poisson, random and hash.

| Milestone | Package | Action | Reason |
|---|---|---|---|
| W1.1 | `sunholo/celestial` 0.5.0 → 0.6.0 | contribute | No package has the habitable zone, Teq, RV amplitude, transit probability or Hill spacing. They are planetary physics, and celestial (orbits, reflected light, Kepler's third law) is their home; it stays dependency-free |
| W1.2 | `sunholo/worlds` 0.1.0 | contribute (new) | No Drake, occurrence or history package exists. The baseline, the dial algebra, the disc counts and the history sampler are reusable science, so gate 3 puts them in a package; it takes uniforms, so it owns no RNG |
| W1.2 | `sunholo/celestial` 0.5.0 `ism` Poisson draw | depend | "a Poisson draw from two uniforms" already exists |
| W1.3 | `sunholo/relativity` 0.12.0 | depend | `journey.planBurnCoastBurn` for the strategies' leg times; `photometry` for luminosity from V |
| W1.3, W1.4 | `sunholo/observe` 0.1.0, 0.2.0 (S2) | depend | `lightcone.seenAt`; 0.2's photon budgets for the detection model (OQ4) |
| W1.3 | `sim/rng.ail` | none (extend in the sim) | SplitMix64 and its oracle live in the sim; `keyed` and `idHash` join them. No registry hash package fits (`sunholo/auth` is SHA-256 key checks) |
| W2.0–W2.3 | — | none | Game data, the census and the protocol are the sim's |
| W2.4, W2.5 | — | none | Godot UI and lore |

## AILANG syntax gate

New `.ail` modules: `celestial/habitability.ail` (+ tests); `worlds/{baseline, dial, disc, occurrence, history}.ail` (+ tests); `sim/calibrate.ail`, `sim/worlds.ail`, `sim/census.ail`, `sim/protocol_worlds.ail`, `sim/data/{presets, detect, exoplanets}.ail`, `sim/tools/{calibrate_main, census_main, exoplanets}.ail`, and their `_test.ail`. None is a showcase module; the rows are recorded:

| Module | Contracts | Effects | Inline tests |
|---|---|---|---|
| `celestial/habitability` | **include:** `hzDistanceAu(l, s)` `requires { l > 0.0, s > 0.0 } ensures { result > 0.0 }`; `transitProbability(r, a)` `requires { r > 0.0, a > r }` `ensures { result > 0.0 && result < 1.0 }`; checked with `ailang verify` where the float theory allows, else kept as tests and recorded | **include:** pure, `! {}` | **include:** `test` blocks in `habitability_test.ail` (the package's convention) for the LW rows |
| `worlds/dial`, `worlds/disc` | **include:** `applyDial` `ensures` every fraction in (0, 1]; `starsWithin` `requires { rLy >= 0.0 } ensures { result >= 0.0 }`; `radiusQuantile` `requires { u >= 0.0 && u < 1.0 }` | **include:** pure | **include:** `test` blocks reproducing every table cell |
| `worlds/history` | skip: the invariants (state order, `endT >= techT`) are properties over uniforms, tested over 10⁴ cases | **include:** pure | **include:** property tests in `history_test.ail` |
| `sim/calibrate`, `sim/worlds`, `sim/census`, `sim/protocol_worlds` | skip: the sim's pure modules use `_test.ail` checks plus strict-VM entries (`sim/earth_link.ail` precedent) | **include:** pure; FS only in `sim/tools/*_main.ail` (gate 4) | skip: `_test.ail` plus `calibVm`, `worldsVm` |

## Milestones

### W1.0. The baseline registry, about 60 LOC plus the registry (design repo; attended)

- **Files:** stapledons-design `physics/life-and-worlds.md` (the factor table of design W1.0, the reference cases, and the `LW-n` index); the game's lore import picks it up; `sim/tools/lore_values.ail` and `tools/lore_check.sh` read the LW registry beside HB and RS.
- **Work:** transcribe each prior from its source with table or page references; replace or confirm every "verify" value in the design (η⊕(M), the type mix, f_i, f_c, L, the HZ fluxes); record the OQ5 choices.
- **Acceptance:** design AC1. `git grep -c '^| LW-' physics/life-and-worlds.md` ≥ 20 on design main; `make lore-values` lists the LW rows; a mutant LW value fails `make lore-check`.
- **Pause:** Mark reviews the registry (canon) before W1.1 publishes anything that cites it.

### W1.1. `sunholo/celestial` 0.6.0, about 240 LOC (110 code, 130 tests)

- **Files:** `celestial/habitability.ail`, `habitability_test.ail`, `CHANGELOG.md`, `AGENT.md` (the new "When to use" bullet), `ailang.toml` `[release] kind = "minor"`.
- **Functions:** `hzFluxes`, `hzDistanceAu`, `insolationEarth`, `equilibriumK`, `rvSemiAmplitude`, `transitProbability`, `mutualHillSpacing` (design W1.1).
- **Tests, first:** the LW rows (the Sun's zone, Earth's Teq 255 K, Jupiter 12.5 m/s, Earth 0.0895 m/s, transit 0.0047); Kopparapu's validity range clamped and flagged; Proxima b and TRAPPIST-1 e insolation against the archive's values to 2 %.
- **Gates:** `ailang test`, `ailang pkg quality` with no gates, then **stop**: the publish is an attended hand-off (`! cd <pkg> && ailang-publish`), then the sim pins it (`ailang install`, `ailang lock`, `make deps`).
- **Acceptance:** design AC2.

### W1.2. `sunholo/worlds` 0.1.0, about 800 LOC (450 code, 350 tests)

- **Files:** `packages/worlds/{ailang.toml, baseline.ail, dial.ail, disc.ail, occurrence.ail, history.ail, *_test.ail, CHANGELOG.md, AGENT.md, README.md}`; depends on `sunholo/celestial` 0.6.0.
- **Tests, first:**
  - `disc_test.ail`: N(R) for 500, 1,000, 3,000, 5,000 and 10,000 ly (9.92 × 10⁵, 6.70 × 10⁶, 1.04 × 10⁸, 3.24 × 10⁸, 1.37 × 10⁹); **every cell** of the feature doc's two tables from the ref-2026-10-06 point at printed figures; the optimistic (1.07, 220) and pessimistic (1.07 × 10⁻⁸) lines; `radiusQuantile` inverts the CDF to 1e-12;
  - `dial_test.ail`: zero offsets give the medians; fractions clamp at 1; `luckDex` equals the sum of offsets until a clamp, and the clamped gain after;
  - `history_test.ail`: over 10⁴ uniform vectors, state order is Complex → PreTech → Technological → ending, `endT − techT = L`, the share of each state at t = 0 matches its closed form within 4σ;
  - `occurrence_test.ail`: SAG13's expected counts at the published Γ, α, β (transcribed at W1.0) and the sampler's histogram against them.
- **Gates:** `ailang test`, `ailang pkg quality` with no gates; **stop** for the attended publish; the sim pins it.
- **Acceptance:** design AC3 (and AC3's game half in `worlds_test.ail` through `make sim`).

### W1.3. The calibration in the sim, about 950 LOC (600 code, 350 tests)

- **Start with the budget probe** (half a day): one seed, one preset, the cautious strategy, on the strict VM and the interpreter; record the time per seed in the sprint JSON and fix the seed counts so `calib-smoke` stays ≤ 60 s. A VM slowdown is reported upstream (`ailang messages`), never worked around.
- **Files:**
  - `sim/rng.ail`: `idHash`, `keyed`, `unit53`; `tools/rng_ref.py` (oracle) gains them; `make rng-ref` covers 10⁴ cases;
  - `sim/data/presets.ail`: the four presets (ids, names, offsets; Lonely at zero, the others filled by W1.4);
  - `sim/data/detect.ail`: the detection model's instrument table (provisional 10 m class; OQ4);
  - `sim/calibrate.ail`: the thinned marked process, the strategies, the encounter rules, the per-row record; `sim/calibrate_test.ail`;
  - `sim/tools/calibrate_main.ail`: the FS shell writing `data/worlds/calibration.json` (rows, medians, 10–90 % ranges, the input digest);
  - Makefile: `calib-smoke` (a `make test` prerequisite), `calibrate` (rig only), `calibVm` in `strict` and `parity`.
- **Tests, first:** realised counts against Λ (AC4) on the cases with 1 ≤ Λ ≤ 10⁴; strategies use only detected candidates (a mutant reading the truth fails); `seenAt` decides what light shows; the same row on rerun, VM and interpreter (AC5); a literal reach in the detection model fails (AC8, once observe 0.2 is pinned).
- **Acceptance:** design AC4, AC5, AC7 (smoke), AC8.

### W1.4. Choosing the presets, about 150 LOC plus data (rig run; Mark rules)

- **Depends on** W1.3 and, per OQ4's recommendation, S2 (`sunholo/observe` 0.2.0 pinned).
- **Work:** the grid search (0.25 dex over life, minds-and-tech, lifetime); `make calibrate` on the rig; the pinned `data/worlds/calibration.json` (sha256 in `data/worlds/SHA256SUMS`); `sim/data/presets.ail` filled from it; a short table for Mark: per preset, the offsets, the luck number, each band's median and range per strategy, and any conflict.
- **Pause:** **Mark rules the presets** (OQ1, OQ2). Then the design repo gets the offsets and luck numbers in life-and-intelligence-parameters, and decision 4's one figure ("civilisations alive within 1,000 ly at the default preset"), from the output.
- **Acceptance:** design AC6, AC7 (full run).

### W2.0. The measured exoplanets, about 400 LOC plus generated data (beside W1)

- **Files:** the download through the `starmap-manager` skill (shell); `data/planets/EXOPLANETS.SHA256` (the ≤ 100 pc `ps` snapshot); the raw CSV in the public bucket (D-18, standing approval); `sim/tools/exoplanets.ail` (AILANG pipeline: parse, cross-match by Gaia DR3 id else 1″, curated systems win); generated `sim/data/exoplanets.ail` and `data/planets/exoplanets.json`; `make exoplanets` (regenerate) and `make exoplanets-check` (in `make test`).
- **Tests:** every snapshot planet with a host in the registry is in the table, values bit-equal; the α Cen and TRAPPIST-1 rows equal the curated modules; hosts not in the 25 pc registry are kept and flagged for L3; counts recorded (hosts, planets, inside 25 pc).
- **Acceptance:** design AC9 (the data half).

### W2.1. World population, about 700 LOC (400 code, 300 tests)

- **Files:** `sim/worlds.ail`, `sim/worlds_test.ail`; `worldsVm` in `make strict` and `make parity`.
- **Tests, first:** a measured host keeps its planets exactly (AC9); M-dwarf zone planets are HabitabilityDebated, no habitable planet around giants, white or brown dwarfs (AC14); a measured constraint forbids a biosphere in every seed; the survey veto (AC15); histories from `keyed` only (a shuffled registry gives the same systems).
- **Acceptance:** design AC9, AC14, AC15, and AC10's VM half.

### W2.2. The census, about 400 LOC (250 code, 150 tests)

- **Files:** `sim/census.ail`, `sim/tools/census_main.ail`, `sim/census_test.ail`; `make census` (25 pc, in `make test`), `make census-large` (GCNS 100 pc, rig only, ≤ 15 min).
- **Tests:** W1's expectation for the same star list against the realised counts over 64 seeds (AC13); nesting across presets (AC12); growth stability on a 1,000-system sub-registry and with appended synthetic rows (AC11); the digest on rerun (AC10).
- **Acceptance:** design AC10–AC13, AC15.

### W2.3. Protocol 2.17, about 400 LOC (220 code, 180 tests)

- **Files:** `sim/protocol_worlds.ail` (the `worlds` section), `sim/protocol.ail` (`worldsMinor()`, `helloFor`, `sessionMinor`, `new_game` `preset`), `sim/core.ail` (World `preset`, `dataVersion`; after adding them, run `make replay` and stop if any pre-2.17 golden moves), `bridge/sim_bridge.gd` `WORLDS_MINOR := 17`; `make worlds-leak` (a `make test` prerequisite).
- **The free minor:** check `git grep -n 'Minor() =' sim/protocol.ail` against open PRs at execution; if 2.17 is taken, take the next and record it.
- **Tests, first:** the dial-blind wire (four presets, one seed, 10k ticks, byte-identical) and the import lint (AC16); below 2.17 unchanged (AC16b); `target` measured only, `system` within 0.1 ly only, `hosts` exactly the registry's measured hosts (AC17); α Cen's `worlds.system` ids equal the system section's planet ids.
- **Acceptance:** design AC16, AC17.

### W2.4. The map and the system card, about 350 LOC (attended)

- **Mock-up first** (visual first, words last): an artifact of the map's host layer and the system strip, reviewed by Mark before any copy.
- **Files:** `ui/planet_hosts.gd` (a map layer on the `ui/ism_layer.gd` pattern: rings per known planet, dashed for candidates, green in the zone, "?" for debated), the system card, the filter row toggle (on by default), `tests/test_planet_hosts.gd`, `make display-audit-worlds`, `make capture-worlds` (the map at 25 ly and 81 ly, TRAPPIST-1's and α Cen's cards, a synthesised system at a stop).
- **Acceptance:** design AC18; Mark has looked at the renders (recorded in the report).

### W2.5. Archive and landing, about 50 LOC plus prose (attended)

- **Files:** stapledons-design `lore/archive/{drake-factors, habitable-zone, red-dwarf-worlds}.md` and the new unlock hints in its README; the game's hint map; `make lore-import`; `design_docs/implemented/r3/worlds-report.md`; the doc moves to `implemented/r3/`; the design repo's roadmap marks W1 and W2 done; a changelog entry.
- **Acceptance:** design AC19, AC20.

## Pause points

1. **The plan** (now): Mark approves it and rules OQ1–OQ9 (or at least OQ5, which W1.0 needs).
2. **After W1.0:** Mark reviews the transcribed baseline (canon).
3. **Before each publish** (W1.1, W1.2): an attended `ailang-publish`.
4. **After W1.4:** Mark rules the presets from the calibration's table.
5. **After W2.3, only if the free minor is not 2.17 or a pre-2.17 golden moves:** stop and report.
6. **W2.4:** the mock-up before copy; the renders before merge.

## Loop routing (mission-loop routing)

| Loop-suitable (headless) | Attended |
|---|---|
| W1.1 and W1.2 up to the publish; W1.3; W1.4's rig run; W2.0–W2.3 | W1.0 (canon), both publishes, the W1.4 ruling, W2.4 (visible), W2.5 (lore) |

## Validation

Per milestone, the targeted gates named above (`make sim`, `make strict`, `make parity`, `make replay`, `make calib-smoke`, `make census`, `make exoplanets-check`, `make worlds-leak`, `make lore-check`, `make ui`). The definition of done is `make test` on the rig: `tools/rig_check.sh <PR>` posts `rig/full`; the GitHub fast tier must be green too.
