# M2: Simulation protocol and the journey core

**Status:** Planned (design, revised for Mark's attended rulings of 2026-10-01; awaiting sprint plan)
**Release:** r1 · **Milestone:** M2 of [R1 foundations](https://github.com/sunholo-data/stapledons-design/blob/main/roadmap/r1-foundations.md) · mission queue row 3, bar clause 2
**Priority:** P0: M4 (first journey) and the AI service's replay recording both sit on this protocol
**Implements:**
- [R1 roadmap §M2](https://github.com/sunholo-data/stapledons-design/blob/main/roadmap/r1-foundations.md) items 1–6 and its three acceptance bullets
- Ledger **D-11** (the Higgs bubble model and the journey model; resolves OQ1–OQ2) and **D-12** (calendar, manual flight and pausing, commit ritual; resolves OQ3–OQ5), `design_docs/stapledon-mission.md` §Decision ledger
- [higgs-bubble](https://github.com/sunholo-data/stapledons-design/blob/main/physics/higgs-bubble.md) (`../stapledons-design/physics/higgs-bubble.md`, normative): §2 the three properties, §3 journey profile, §4 photon drive, §5–6 ISM mirror, glow, §7 forward CMB, §8 closed mass budget, §12 proposed functions. Its check-value IDs (HB-n) are assigned there; this doc cites them and adds no IDs of its own
- [ADR 0001](https://github.com/sunholo-data/stapledons-design/blob/main/decisions/0001-engine-and-architecture.md) §Decision (NDJSON sidecar, fixed tick, state lives in AILANG) and §Constraints (pure hash PRNG, hand-written codecs)
- [journey-system](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase3-gameplay/journey-system.md) Parts 1–2 (planning, commit), **not** its maths: its `calculateJourneyTimes` is the instant-acceleration idealisation and is replaced by the package's boost–cruise–brake profile
- [journey-planning-ui](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/journey-planning-ui.md) §Journey Calculator Panel (numbers only; predictions and crew panels are M4+)
- [galaxy-map](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase2-core-views/galaxy-map.md) Phases 1–3 and 7 (starfield, pan/zoom, select, journey preview)
- [mass-budget](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/mass-budget.md) §AILANG Types, as an m_eff + energy-ledger **readout** (higgs-bubble §8; enforcement later)
- [relativity spec](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md) §1 (conventions: c = 1, rapidity integrated) and §2 "float64 for γ and 1−β". Trip times and bubble energetics are normative in higgs-bubble; the closed forms live in `sunholo/relativity`
- AILANG `design_docs/planned/v1_1_0/m-game-engine-effects.md` (`Render`/`Input`/`Clock` host effects)

**Depends on:** M0 spike (done). `sunholo/relativity` next free minor (M2.0, published here). Does **not** depend on M1 finishing, but M2.1 changes the bridge that M1's `make capture` and `make golden` use (see Risks).
**Estimated:** ~3,400 LOC committed (≈1,750 code + 1,650 tests/tools/fixtures), 7 sub-milestones. The charter row says ~2,000; the difference is the 10k-tick replay tooling, the galaxy map test harness and the bubble readouts.
**Evidence:** pinned to `e9d35c5`; probes in the [Verification log](#verification-log). The AILANG pin is now **v0.50.0** (CI, `runtime/VERSION`, lockfile; V8); V3–V5 ran on v0.47.2 and V3 also on v0.50.0.

## Game vision alignment

Scored against the six pillars (`stapledons-design/vision/core-pillars.md`), as in the M1.2b doc. Rescored for D-11/D-12.

| Pillar | Relevance | Score | Notes |
|---|---|---|---|
| Choices Are Final | ++ | +2 | The commit rule lives in the simulation, has no code path back, and is tested by enumerating every intent against a committed journey. The planner shows costs, not outcomes, so it is not a "branching preview" (excluded by the pillar). Manual thrust exists only in `diag` sessions (D-12) |
| The Game Doesn't Judge | 0 | 0 | Numbers only; no labels such as "safe" or "reckless" (the old presets' "Dangerous speed" text is dropped). The energy and ISM readouts are joules, watts and kelvin, not verdicts |
| Time Has Emotional Weight | ++ | +2 | Ship-years against Earth-years, the arrival year and the years of your 100 left lead the panel. Speed now has a real cost: ISM drag energy grows ~γ·d (HB-51…56) while boost energy grows only as ln γ (HB-35…37), so trading crew years for home years is a visible, physical trade, and the clock never pauses (D-12) |
| The Ship Is Home | 0 | 0 | No interior yet (M4). The felt 1 g is held by the generator, so cruising is never zero-g (D-11 property 3) |
| Grounded Strangeness | ++ | +2 | Exactly one declared hand-wave (the bubble, three properties); everything else is exact: photon-drive momentum, elastic-mirror ISM drag, the blueshifted forward CMB as a readout (HB-62) |
| We Are Not Built For This | 0 | 0 | Crew ages are placeholders; frailty arrives with crew simulation (R2) |
| Hard-science spec (constraint, not a pillar) | ++ | +2 | Planner = package closed forms to 1e-9; the stepped voyage is checked against them at every phase boundary; readouts equal HB-n check values |
| **Net** | | **+8** | **Go.** No pillar is at risk. The pausing tension (old OQ4) is resolved by D-12 |

## Problem

The spike has one ship, one command and no rules beyond "don't turn while moving":

1. **The protocol is an unversioned command echo.** `handle` dispatches on a
   `cmd` string (`sim/ship.ail:69-85`) and answers every line with the full
   ship report (`:16-23,64`). The version `"1.1"` (`:28`) is compared as a
   float (`bridge/sim_bridge.gd:49`), so "1.10" reads older than "1.2". Inputs
   carry no tick, so a dropped line is undetectable; the bridge infers success
   from `tick == before + 1` (`:125`). The sim prints a state line before
   `hello` (`sim/ship.ail:104`).
2. **Codecs are ad hoc and one-way.** Requests are parsed field by field
   (`sim/ship.ail:35-62`) with no decoder for the sim's output, so nothing
   proves encode∘decode is the identity. Godot calls `JSON.stringify` without
   `full_precision` (`bridge/sim_bridge.gd:121`); the only float round-trip
   test uses 0.6 and 0.8 (`tests/test_sim_bridge.gd:31-33`).
3. **There is no world clock, phase or journey.** `Ship` is
   `{tick, motion, heading, origin, x0}` (`sim/core.ail:11`); galaxy and ship
   time exist only as `motion.t` and `motion.tau`. `sim/` never imports
   `sunholo/relativity/journey`, although the package already ships
   `flipAndBurn`, `burnCoastBurn` and `coastAt`
   (`relativity/0.3.0/journey.ail:19,35,55`). Thrust is whatever Godot sends
   each tick (`main.gd:101-104`), and nothing stops a player reversing
   mid-voyage.
4. **The journey model was wrong for the canon.** The draft planned 1 g
   flip-and-burn, with gravity "from constant thrust" and weightless coasting.
   D-11 replaces it: the pocket's acceleration is not felt (property 3), so a
   journey is **boost (minutes of ship time) → cruise at the player's chosen
   speed (0.9c–0.999999c, bounded by the γ cap) → brake (minutes)**, no flip,
   with a felt 1 g held by the generator. Felt acceleration is independent of
   mass, so without property 3 reaching 0.999999c at 1 g would take 7.03
   ship-years (HB-23/24). The 1 g flip-and-burn α Cen numbers (3.582 ship-yr,
   6.003 yr, 0.9517c; HB-27…29) stay as package check values, not the gameplay
   profile.
5. **The package's trip functions are not enough to fly a trip.** They return
   totals (`Trip`, `journey.ail:10-16`) but not the phase boundaries or the
   closed-form motion at an arbitrary proper time, which the stepped voyage
   needs to split ticks at a boundary and to be checked against. `peakBeta` is
   `tanh(phiPeak)`; the rapidity itself is not returned, so `oneMinusBeta`
   cannot be called on it (spec §2). `burnCoastBurn` takes the cruise speed as
   β, which rounds badly at 0.999999c. There is no photon-drive energy, ISM
   drag, glow or forward-CMB function, so the costs D-11 makes canon have no
   single source of maths.
6. **There is no randomness and no replay.** No generator exists; ADR 0001
   rules out `std/rand`. The determinism gates are a 600-tick thrust script
   and a 5-line off-axis fixture (`Makefile:35-46`); no input log, no golden
   state. **Probe (V3, V4):** `^`, `&`, `<<`, `>>` work on the interpreter but
   are "not yet wired (Phase 2E)" on the VM, so SplitMix64 fails
   `--strict-bytecode`; integer `*`, `/`, `%` and wrap-around pass.
7. **There is no map or target selection.** The only UI is a HUD label
   (`main.gd:85-86`). The catalogue has 3,802 rows but 3,363 distinct `id`s
   (V6: α Cen A and B are both `"Gl 559"`). Star positions are float32
   `Vector3`s (`sky/starfield.gd:13,22`), which must not feed a planner.
8. **Toolchain.** The staged runtime now matches the v0.50.0 pin (V8; V7 is
   historical), but a PATH `ailang` that differs still rewrites the lockfile
   (queue row 6). M2's parity and replay gates must name the binary they ran.

## Goals and non-goals

**Goals**
- Protocol v2 (the roadmap's "protocol v1": the first versioned spec; the wire
  already says 1.1, so the integer major is 2) with a handshake, tick-numbered
  inputs of typed intents, and state change-sets. Hand-written AILANG codecs
  with round-trip tests; matching GDScript codec with the same fixtures.
- A pure `tick(world, input)` in `sim/core.ail` owning the clock, the ship's
  phases, the planner, the commit rule, the energy ledger and the PRNG,
  strict-VM clean.
- The gameplay journey is boost → cruise at a chosen rapidity → brake. For a
  chosen cruise speed the planner reports ship-years, Earth-years, arrival,
  crew age, years left, boost + brake energy 2·m_eff·c²·φ, ISM drag energy,
  the forward load and glow, and the forward CMB temperature. All equal
  package outputs to 1e-9; the stepped voyage lands within 1e-9 of them.
- `make replay`: recorded input logs re-run on VM and interpreter, diffed
  byte-for-byte against committed golden state, including a 10k-tick session.
- A Godot galaxy map: pick a star, choose a cruise speed (default 0.99c,
  D-14), see the sim's plan, commit through the D-12 ritual; cancel is
  visibly refused by the sim.
- An input record slot for AI results (D-7) so the AI service can be replayed
  without a protocol major bump.

**Non-goals**
- Crew simulation, crew vote, deaths and births (journey-system Part 1 crew
  projection): ages are `startAge + tau` placeholders.
- Journey events, arrival sequence, Earth-side consequences, the 1,000 AU
  stand-off (M4, D-14).
- An **enforced** energy or mass budget: the ledger is a readout in R1
  (D-11); `available_kg` is carried unchanged. Density is constant (no ISM
  map); tides and hover power are M3's.
- Native `Render`/`Input`/`Clock` effects: the messages are shaped for them;
  the pipe stays.
- Anything SR-visual, including the forward CMB disc (queue row 6a; M2 only
  reports its temperature). M2 adds no shader and no visual of SR, so physics
  gate 2 does not apply; `make golden` and `make capture` must keep passing.
- Multi-star target catalogues beyond what M1 has committed when M2.6 runs.

## Design

### M2.0 Trip phases and bubble energetics in `sunholo/relativity` (package first)

New in **0.4.0** (Mark, attended 2026-10-01: M2.0 takes 0.4.0; `teffFromBV` (M1.2d) and M3.1's geodesics take the next free minors (0.5.0/0.6.0, first to publish takes the lower); check numbers follow publish order, M3 doc §M3.1).
Additive only, so `Trip` and the three existing functions keep their signatures.
Names are AILANG camelCase; the snake_case names in higgs-bubble §12 map one to one.

**Module `journey` (c = 1, years, light-years), plus helpers in `hyper` and `kinematics`:**

| Function | Definition | Why |
|---|---|---|
| `hyper.acosh1p(u)` | acosh(1+u) = log1p(u + √(u(2+u))) | `flipAndBurn` forms `1 + a·d/2` and loses the low bits of short trips |
| `kinematics.rapidityOfOneMinusBeta(e)` | ½(log(2−e) − log e) | the γ cap is stated as 1−β = 1e-6; never form 1−e |
| `type TripPlan = { trip: Trip, a: float, phiPeak: float, tauBurn: float, tauCoast: float, tauTotal: float, dBurn: float, dCoast: float, fellBack: bool }` | phase boundaries in proper time and distance | the sim switches phase at exact τ |
| `planBurnCoastBurn(d, a, phiCruise) -> TripPlan` | **gameplay profile.** dBurn = 2 sinh²(φc/2)/a, τburn = φc/a, τcoast = dCoast/sinh φc, t = 2 sinh φc/a + dCoast/tanh φc; falls back to flip-and-burn (`fellBack`) when 2·dBurn ≥ d | φc given as rapidity; `a` is the boost proper acceleration |
| `planFlipAndBurn(d, a) -> TripPlan` | φp = acosh1p(a·d/2), τburn = φp/a, τcoast = 0 | package check profile (HB-27…29) and the fallback |
| `type TripPhase = Accelerating \| Coasting \| Decelerating \| Arrived` | | |
| `phaseAt(p, tau) -> TripPhase` | boundaries τburn, τburn+τcoast, τtotal; left-closed | one definition for sim and tests |
| `motionAt(p, tau) -> Motion` | closed form per phase, using 2 sinh²(φ/2)/a for (cosh φ − 1)/a; clamped to [0, τtotal] | reference for the stepped voyage |

**New module `medium` (SI in and out: n in m⁻³, R in m, d in ly, m_eff in kg; J, N, W, W/m², K).** Constants `cSI`, `protonMassKg` (CODATA, m_p c² = 1.50328e-10 J), `lightYearM`, `cmbTemperatureK = 2.725` (higgs-bubble §1). All forms are in rapidity (γβ = sinh φ, γ−1 = 2 sinh²(φ/2), γ(1+β) = e^φ), so nothing forms 1−β.

| Function | Formula | HB |
|---|---|---|
| `photonDriveEnergy(mEff, phi)` | m_eff c² φ, one boost or one brake (ship frame) | HB-35…37 |
| `mirrorDragForce(n, phi, r)` | n sinh²φ m_p c² πR² (specular sphere; a flat mirror would be 2×) | HB-47…50 |
| `mirrorDragPower(n, phi, r)` | F·c: drive power that holds cruise | — |
| `cruiseDragEnergy(n, phi, r, dCoast)` | n sinh φ m_p c² πR² dCoast (= F c τcoast) | HB-51…56 (with dCoast = d) |
| `loadScale(n, phi)` | n sinh²φ m_p c³ (W/m²) | HB-38…43 |
| `kineticFlux(n, phi)` | n sinh φ · 2 sinh²(φ/2) m_p c³ (W/m²) | HB-44…46 |
| `glowInwardFlux(n, phi, eps, fIn)` | ε f_in K / 4 (mean over the inner wall) | HB-61 |
| `tripEnergy(p, mEff, n, r) -> {boost, brake, drag, total}` | boost = brake = m_eff c² φc; drag = `cruiseDragEnergy(.., p.dCoast)`; total = 2 m_eff c² φc + drag | ledger |
| `brakeHoldsAgainstDrag(mEff, a, n, phi, r)` | m_eff·a ≥ F(φ) | precondition of `tripEnergy` |
| `optics.forwardDoppler(phi)`, `optics.cmbForwardTemperature(phi)` | e^φ; T_CMB e^φ | HB-62, HB-63 |

Why the boost/brake drag terms drop out of `tripEnergy`: during the boost the
drive supplies m_eff·a + F, during the brake m_eff·a − F, at the same φ(τ), so
the drag work cancels over the pair (exact when `brakeHoldsAgainstDrag`; V10
confirms by numeric integration). Proton energy and plume (HB-57…60, HB-57…60) and
the tidal and hover functions (HB-71…90) are higgs-bubble §12 items for M3/M4;
M2 does not need them.

Existing `flipAndBurn`/`burnCoastBurn` are reimplemented as `planX(...).trip`
so there is one formula. Tests (named `check…()` per the CLAUDE.md test-block
workaround): every row below to 1e-12 relative against `python3` references
committed in the package (`tools/journey_ref.py`); `motionAt(p, τtotal)` has
φ = 0 and x = d to 1e-12; continuity of t and x across each boundary;
`phaseAt` at each boundary; every `medium` function finite (no NaN/Inf) over a
10⁴-point φ sweep of [0, φcap]; HB-n values to their printed digits;
strict-VM equals interpreter on a digest entry, as AC-W5 did. Then
`CHANGELOG`, `[release] kind = "feature"`, `ailang pkg quality` with no gates,
dry run, publish (standing grant), and the game pins it.

**Boost acceleration.** A scenario parameter `boost_g` (proper acceleration in
g, unfelt by property 3), default **7.5 × 10⁵ g** (a = 774,221.4566651969 c/yr
= 7.355e6 m/s²): 1.00 ship-minute to 0.9c, 1.80 to 0.99c, 4.93 to 0.999999c.
The numerics stay finite in rapidity form: at φ = 7.2543, τburn = 9.37e-6 yr,
dBurn = 2 sinh²(φ/2)/a = 9.12e-4 ly (57.7 AU), galaxy time 8.0 h; no term
divides by 1−β. HB-30…34's duration-defined example (10 ship-minutes to 0.99c) is
the same function with a = φ/τ (row 5).

Check values, trip (d = 4.37 ly unless stated; a_B = 7.5e5 g):

| # | Trip | φ | Ship-yr | Earth-yr | HB |
|---|---|---|---|---|---|
| 1 | α Cen, cruise 0.9c | 1.4722194895832204 | 2.116489782091437 | 4.8555571747021204 | |
| 2 | α Cen, cruise 0.99c (slice default, D-14) | 2.6466524123622457 | 0.6226958707592057 | 4.414143655383168 | HB-16/17, HB-20…22 |
| 3 | α Cen, cruise at cap 1−β = 1e-6 (γ = 707.106957963309) | 7.254328619262047 | 0.006196277986522204 | 4.370006949593909 | HB-18/19, HB-25/26 |
| 4 | 0.001 ly at cap: falls back, φ reached 6.654436202069182 | — | 1.7190007186656455e-05 | 0.001002579912238613 | |
| 5 | α Cen 0.99c, a = φ/(600 s) = 1.3224e6 m/s² | 2.6466524123622457 | 0.6227168354229866 | 4.414153879485825 | HB-30…34 |
| 6 | α Cen, flip at 1 g (a = 1.032295275553596 c/yr; peak β 0.9516558449006334, γ 3.2555651770846072) | — | 3.5823937227478337 | 6.00250277725247 | HB-27…29 |
| 7 | `Gl 559` catalogue position, 4.35667304258651 ly, flip at 1 g (peak β 0.9514456743125428) | — | 3.5780871495240905 | 5.988497264963769 | |
| 8 | 100 ly, 1 g, cruise β = 0.99 (peak γ 7.088812050083355) | 2.6466524123622457 | 17.696001151818983 | 102.69103232505418 | |
| 9 | 1,000 ly, 1 g, cruise γ = 707.1 (unreachable, falls back; peak γ 517.147637776798) | — | 13.448622327743177 | 1001.9355569687548 | |

Check values, readouts (α Cen; n = 10⁵ m⁻³, R = 100 m, m_eff = 1 kg, ε = 1e-9, f_in = ½):

| Cruise | Boost = brake (J) | Drag over dCoast (J) | Total (J; kg of mass-energy) | Load (W/m²) | Glow in (W/m²) | Drag F (N) | Hold power (W) | T_fwd (K) |
|---|---|---|---|---|---|---|---|---|
| 0.9c | 1.3231648905001936e17 | 4.031443217698731e16 | 3.0494741027702605e17; 3.393 | 19212.82874513549 | 1.5052987296077217e-06 | 2.0133555741551197 | 603588816.4039646 | 11.877999621148337 |
| 0.99c | 2.3786925619268595e17 | 1.3702577394591198e17 | 6.127642863312838e17; 6.818 | 221961.27278927868 | 2.4071942179266308e-05 | 23.25982143207345 | 6973119039.76238 | 38.44085554458952 |
| cap | 6.519865414820472e17 | 1.380061797390603e19 | 1.5104591056870126e19; 168.06 | 2253353077.7286806 | 0.2812710757763286 | 236133.9415328578 | 70791174749363.73 | 3853.730994033574 |

These agree with HB-35…37, HB-38…43, HB-47…50, HB-51…56 and HB-62 to their printed digits
(V11). HB-51…56 uses the full d; the package uses dCoast, which is smaller by
2·dBurn (relative 3.6e-6 at 0.99c, 4.2e-4 at the cap), so the ledger closes
exactly at arrival. The brief's worked drag numbers (2.7e17 J at 0.99c, 2.8e19
J at the cap) are a flat face-on mirror, 2× the canon sphere (V11).

### M2.1 Protocol v2 and codecs

**Envelope.** Every line is one JSON object with `"v": 2` and a `"type"`.
Integers that must be exact (tick, seed, plan id) stay below 2^53 so Godot's
float JSON reader keeps them. Floats are written by `std/json` (shortest
round-trip; V5) and by Godot with `JSON.stringify(x, "", true, true)`
(`full_precision`).

| Direction | `type` | Body | Maps to (future host effect) |
|---|---|---|---|
| G→S | `hello` | `want: {major, minor}` | handshake |
| S→G | `hello` | `proto: {major: 2, minor: 0}`, `sim`, `relativity`, `rng` (algorithm id) | handshake |
| G→S | `new_game` | `seed` (0 ≤ seed < 2^53), `scenario` (`"sol"`), `diag` (bool), `params?` (overrides of the scenario's values, below) | world construction |
| G→S | `input` | `tick` (= world tick + 1), `dtau` (ship-years, 0 ≤ dtau ≤ 1), `intents: [...]` | `Clock` supplies (tick, dtau); `Input` supplies intents |
| S→G | `state` | `tick`, `status`, `changes: {clock?, ship?, journey?, ledger?, rng?, params?}`, `events: [...]`, `refused: [{i, reason}]`, `full` (bool) | `Render` receives game state, never draw calls |
| G→S | `quit` | | |

**Scenario parameters** (`"sol"` defaults; `params` may override any; the
first full `state` echoes the effective set, so golden logs record them):
`epoch` 0 (relative calendar, D-12), `start_age` 30, `boost_g` 7.5e5,
`m_eff_kg` 1.0 (open question 6), `ism_n_cm3` 0.1, `bubble_radius_m` 100,
`glow_eps` 1e-9, `glow_f_in` 0.5, `cruise_min_beta` 0.9, `cap_one_minus_beta`
1e-6. Out-of-range values are a schema error.

**Intents** (tagged by `k`; unknown `k` is a schema error):

| `k` | Fields | Accepted when |
|---|---|---|
| `plan` | `target: {index, id, pos: {x,y,z}}` (float64 ly, galactic Cartesian as `stars.json`), `cruise_phi` (rapidity), `flip_g?` | not committed; φ in [atanh(cruise_min_beta), rapidityOfOneMinusBeta(cap)] else refused `out_of_range`; `flip_g` (1 g flip-and-burn check profile, ignores `cruise_phi`) only in `diag`, else refused `diag_only` |
| `commit` | `plan_id` | a plan with that id exists, ship at rest, not committed |
| `cancel` | | never while committed (refused `committed`); clears an uncommitted plan |
| `thrust`, `heading` | as v1.1 | `diag` sessions only (refused `diag_only`, D-12), not committed |
| `record` | `source` (`"ai"`), `req`, `kind`, `sha256`, `body` | reserved in 2.0 (refused `unsupported`); the AI service adds it as 2.1 |
| `draw` | `stream` | `diag` only: draws one value, reported in `events` (exercises the PRNG in replays) |
| `echo` | as `plan` | `diag` only, test hook (M2.1b): the payload comes back as an `echo` event (see below) |

The old `profile.accel_g` is gone: the boost acceleration is a scenario
parameter, not a player choice, and the only player-facing speed control is
`cruise_phi`. The map's slider is uniform in φ (≈ ln 2γ, a natural log scale);
its labels are the sim's `cruise_beta`/`cruise_gamma`, so Godot never computes
a rapidity.

**Rejection model.** A *malformed* input (bad JSON, wrong `v`, `bad_tick`,
bad `dtau`, schema error) changes nothing and the tick does not advance
(`protocol_test.ail:47-51`). A *well-formed intent the rules refuse* is listed
in `refused` and the tick proceeds, so Cancel during transit never stalls the
clock.

**Reason codes** (as implemented in M2.1a/M2.1b; `sim/protocol_test.ail`
`checkDecodeCodes`, `checkHandshake`, `checkRefusedProceeds`, `checkEcho`).
Malformed codes go in `status` and leave the tick unchanged; refusal codes go
in `refused[i].reason` with `status: "ok"`.

| Code | Kind | When |
|---|---|---|
| `bad_json` | malformed | the line is not JSON (includes `NaN`) |
| `bad_v` | malformed | `v` missing or not the number 2 |
| `bad_cmd` | malformed | `type` missing or unknown; `hello` without integer `want.major/minor` |
| `bad_tick` | malformed | `tick` missing, not an integer in [0, 2^53), or ≠ world tick + 1 |
| `bad_step` | malformed | `dtau` missing, non-finite or outside [0, 1]; `thrust` missing or \|thrust\| > 1 |
| `bad_heading` | malformed | `heading` not three finite numbers with \|norm − 1\| ≤ 1e-9 |
| `bad_intent` | malformed | `intents` not an array; unknown or missing `k`; a field of `plan`/`echo`/`commit`/`record`/`draw` missing or mistyped |
| `bad_game` | malformed | `new_game`: `seed` not an integer in [0, 2^53), `scenario` ≠ `"sol"`, `diag` not a bool (**added by M2.1a**) |
| `bad_params` | malformed | `new_game.params` not an object, an unknown name, a non-number, or a value outside the range table below (**added by M2.1a**) |
| `no_hello` | malformed | `new_game` or `input` before the `hello` handshake (**added by M2.1a**) |
| `no_game` | malformed | `input` before `new_game` (**added by M2.1a**). The bridge never sends this: `send()` before `new_game` returns false without writing (`test_no_input_before_new_game`) |
| `moving` | refused | `heading` while the ship is not at rest; `commit` while the ship is not at rest (\|φ\| ≥ 1e-9) (**M2.3a**) |
| `diag_only` | refused | `thrust`, `heading` or `echo` in a non-diag session; `plan` with `flip_g` (**M2.3a**) |
| `committed` | refused | every intent kind while the journey is committed (**M2.3a**, AC7) |
| `out_of_range` | refused | `plan`: `cruise_phi` outside [rapidityOfBeta(cruise_min_beta), rapidityOfOneMinusBeta(cap)] (both ends accepted); a target at the ship's own position; diag `flip_g` not a positive finite number (**M2.3a**) |
| `stale_plan` | refused | `commit` whose `plan_id` is not the current plan (none, replaced, cancelled) or whose plan was made from another position (**M2.3a**) |
| `unsupported` | refused | `draw` (until M2.4), `record` (reserved for 2.1). Since M2.3a `cancel` with no plan is a no-op, not a refusal |

A malformed line's reply carries the current world tick (0 before
`new_game`); it never carries sections.

**Scenario-parameter ranges** (`protocol.ail` `inRange`; every bound pinned by
`checkParamBounds`, accepted at the bound and refused just past it). **These
ranges are executor-chosen (M2.1a), pending Mark's ratification.**

| Parameter | Default (`sol`) | Accepted range | Units |
|---|---|---|---|
| `epoch` | 0 | \|v\| ≤ 1e6 | years (relative calendar, D-12) |
| `start_age` | 30 | 0 ≤ v ≤ 1000 | years |
| `boost_g` | 7.5e5 | 0 < v ≤ 1e9 | g |
| `m_eff_kg` | 1.0 | 0 < v ≤ 1e30 | kg |
| `ism_n_cm3` | 0.1 | 0 ≤ v ≤ 1e6 | cm⁻³ |
| `bubble_radius_m` | 100 | 0 < v ≤ 1e6 | m |
| `glow_eps` | 1e-9 | 0 ≤ v ≤ 1 | — |
| `glow_f_in` | 0.5 | 0 ≤ v ≤ 1 | — |
| `cruise_min_beta` | 0.9 | 0 < v < 1 | c |
| `cap_one_minus_beta` | 1e-6 | 0 < v < 1 | — |

**Diag `echo` test hook (M2.1b, AC9).** Until M2.3a's planner can echo a real
plan, a diag session accepts `{"k": "echo", target, cruise_phi, flip_g?}`
(the `plan` payload) and reports it back unchanged as the event
`{"k": "echo", target, cruise_phi, flip_g?}`; outside diag it is refused
`diag_only`. The Godot bridge test sends the float fixtures through it.

**Float text in Godot (M2.1b findings, Godot 4.7.2).**
- *Writing.* `JSON.stringify(x, "", true, true)` gives shortest round-trip
  digits but prints −0.0 as `0.0`. std/json also reads `-0` as +0
  (ailang#1460). So `SimBridge.number` writes `-0.0` itself and uses
  `full_precision` for everything else (`1e+308`, `9.007199254740991e+15`,
  `0.9999999999999998`, which std/json reads exactly).
- *Reading.* `JSON.parse_string` reads `-0.0` and `1e308` exactly, but
  returns 0.0 for every \|x\| ≤ DBL_MIN, so 5e-324 and 2.2250738585072014e-308
  cannot reach Godot. The sim still receives them exactly (its reply prints
  their digits). The bridge test marks this **known-divergent** and asserts it
  either way. No game value is that small, so the `"0x…"` bit-string fallback
  is not adopted.
- *Literals.* The GDScript tokenizer misreads some float literals: `-0.0` is
  +0.0 and `9007199254740991.0` is …990. Tests build edge floats from their bit
  patterns.

**Cross-architecture floats (M2.1b finding).** The sim is bit-deterministic
per architecture (VM = interpreter on each), but not across them: `std/math`
`exp`/`log` differ by 1 ulp between arm64 (darwin and linux) and x86_64 on
v0.50.0. For example, `exp(0.2064590551107192)` is `1.229317398921793` on
arm64 and `1.2293173989217931` on x86_64 (glibc agrees with x86_64). So the
v1.1 off-axis golden exists once per architecture, and the off-axis v1.1 log
differs in one `beta`. **M2.5 must plan for this:** CI runs linux x86_64 and
development runs darwin arm64, so committed replay digests need either one
golden per architecture or an upstream fix (flagged for an AILANG report).

**Startup.** Since v1.1 was removed (M2.1b), `ship.ail` prints nothing until
its first input; its first output is the reply to that input, normally the
`hello` (`make parity-v2` checks both runtimes).

**Change-sets.** The first `state` after `new_game` is `full: true`. After that
a section appears only if a field in it changed, and carries the whole section.
- `clock: {tau, t, year, age}`
- `ship: {phase, beta, one_minus_beta, gamma, heading, pos, drag_n, load_w_m2,
  glow_w_m2, cmb_forward_k}` (`one_minus_beta` from `oneMinusBeta(phi)`, so
  Godot never subtracts; ISM and CMB values at the current φ, zero at rest)
- `journey: {state, plan_id, plan?}` with `plan: {target, distance, profile,
  fell_back, cruise_phi, cruise_beta, cruise_one_minus_beta, cruise_gamma,
  boost_minutes, ship_years, earth_years, arrive_year, age_on_arrival,
  years_left, energy: {boost_j, brake_j, drag_j, total_j, total_kg},
  ism: {drag_n, hold_w, load_w_m2, glow_w_m2}, cmb_forward_k}`
- `ledger: {m_eff_kg, available_kg, radiated_j, boost_j, drag_j}` (readout)
- *As implemented in M2.3a:* `journey.state` is `idle|planned|committed|arrived`;
  `plan_id` is 0 and `plan` absent while idle. `profile` is `burn_coast_burn`
  or (diag `flip_g`) `flip_and_burn`; `fell_back` reports the package's
  fallback. While planned, `arrive_year`, `age_on_arrival` and `years_left`
  are "if you commit now" (the clock runs, D-12), so the section is resent
  each tick time passes; once committed they are frozen at the commit
  instant (τ0, t0) and the section stops changing. ISM, glow and
  `cmb_forward_k` are at the plan's peak rapidity. Full states carry
  `journey` and `ledger`.
- `rng: {streams}`; `params: {...}` (full state only)

`events` include `phase` (from, to, tau), `committed`, `arrived` (with
residuals, below) and `draw`.
- *As implemented in M2.3b:* `{"k":"phase","from":"boosting","to":"cruising","tau":…}`
  (from/to are the ship phase names `at_rest|boosting|cruising|braking`; tau
  is the ship's proper time at the boundary) and
  `{"k":"arrived","residual_x":…,"residual_t":…,"residual_phi":…}` (the
  residuals before the snap; `residual_phi` = |φ_stepped| is an addition).
  The first piece flown after a commit emits `at_rest → boosting` at τ0, so
  the commit tick at dtau 0.01 carries `committed` and two `phase` events.

**Modules.** `sim/protocol.ail` (new, pure): `Input`, `Intent`, `StateMsg`,
`decodeInput : string -> Result[Input, string]`, `encodeState`, and the
inverse pair `encodeInput`/`decodeState` for round-trip tests and replay
tooling; it joins `make strict` (`std/json` is strict-clean, V5).
`sim/ship.ail` shrinks to the I/O loop (read → decode → `core.tick` → encode
→ print), the only code a native-effects port replaces.

**Godot.** `bridge/sim_bridge.gd` gains `hello()`, `new_game(seed, …)`,
`send(intents, dtau) -> bool`, an integer-major check, a mirrored `world`
that applies change-sets, and an optional `record_path` that tees every stdin
line byte for byte into an NDJSON log; timeouts and cleanup stay as tested
(`tests/test_sim_bridge.gd:65-92`). `main.gd` and the capture/golden paths
move to the new API in the same sub-milestone (diag session, `thrust`
intents). v1.1 is removed: the `parity`/`parity-offaxis` fixtures become v2
logs, and a one-time test asserts the v2 off-axis log reproduces v1.1's
`beta, gamma, tau, t, x, pos` at `e9d35c5` (`tests/fixtures/v11_offaxis.{arm64,x86_64}.golden`;
one per architecture, see *Cross-architecture floats* below).

**Round-trip tests.** `sim/protocol_test.ail`: for a fixture set of inputs and
states (including 0.1, 1−2⁻⁵², 5e-324, 1e308, −0.0 and the cap's φ),
`decodeInput(encodeInput(x)) == x` and `decodeState(encodeState(s)) == s`;
every malformed case keeps today's reason codes plus `bad_tick`, `bad_v`,
`bad_intent`. `tests/test_sim_bridge.gd` sends the same float fixtures through
GDScript and checks the echoed `plan.target.pos` and `cruise_phi` are
bit-identical.

### M2.2 World clock, ship phases, energy ledger

```
World   = { tick, seed, params: Params, ship: Ship, journey: Journey,
            ledger: Ledger, rng: Rng, diag: bool }
Ship    = today's Ship (sim/core.ail:11) + phase: ShipPhase
ShipPhase = AtRest | Boosting | Cruising | Braking     -- TripPhase in canon words
Ledger  = { mEffKg, availableKg, boostJ, dragJ }        -- radiated = boost + drag
```

Galaxy and ship time are `motion.t` and `motion.tau`, not duplicated. `year = epoch + t` (epoch 0: the display reads "Earth +6.003 yr",
D-12), `age = startAge + tau` (placeholder for the crew model). Phase is
derived for manual (diag) flight (|φ| < 1e-9 → `AtRest`, the threshold used by
`turn`, `core.ail:24`) and set by the autopilot during a journey.

**The mass budget is closed** (higgs-bubble §8): no massive particle crosses,
so `availableKg = 20,000` (mass-budget §Starting Mass) is carried unchanged
and a test pins that. The ledger accumulates, per tick piece, `boostJ +=
photonDriveEnergy(mEff, |Δφ|)` in boost and brake and `dragJ +=
mirrorDragPower(n, φc, R)·dτ` in cruise (dτ in seconds). The boost/brake drag
terms are omitted because they cancel over the pair (M2.0), so mid-boost the
readout runs below the true radiated energy by at most the drag work of one
boost (0.22% of a boost's energy at the cap, for minutes); at arrival it equals
`tripEnergy(...).total` to 1e-9 relative. Nothing is deducted or enforced.
Scenario validation refuses a `new_game` where `brakeHoldsAgainstDrag` fails
at the cap (m_eff < 0.032 kg at the defaults; reason `m_eff_too_small`).

### M2.3 Planner and commit

**Plan.** `plan` computes `d = |target.pos − position(ship)|` in float64
scalars and calls `planBurnCoastBurn(d, boost_g·standardGravity(),
cruise_phi)` (or, in diag with `flip_g`, `planFlipAndBurn`). It stores
`Planned {id, target, from, heading, flip, trip}` (`trip` is the package's
`TripPlan` whole; `from` is the ship's position when planned, so a commit
from elsewhere is `stale_plan`); plan ids increase monotonically from 1 and
are counted in `World.lastPlanId`, so they are never reused. Every number in `journey.plan` is a package output or arithmetic on
one: `arrive_year = year + trip.galaxyTime`, `age_on_arrival = age +
trip.shipTime`, `years_left = 100 − (age − startAge) − trip.shipTime`,
`boost_minutes = tauBurn·525,960`, `energy = tripEnergy(p, mEff, n, R)`,
`ism = {mirrorDragForce, mirrorDragPower, loadScale, glowInwardFlux}` and
`cmb_forward_k = cmbForwardTemperature(phiPeak)`.

**Journey state machine** (`Journey = Idle | Planned(..) | Committed(..) | Arrived(..)`):

```
Idle/Arrived --plan--> Planned --plan--> Planned (replan)
Planned --cancel--> Idle
Planned --commit(id, at rest)--> Committed {plan, tau0, t0}
Committed --(sim only, tau = tau0 + tauTotal)--> Arrived {plan, tau0, t0, el}
Committed --plan|cancel|commit|thrust|heading--> Committed, refused "committed"
```

There is no function from `Committed` to `Planned` or `Idle`. `commit`
performs the at-rest `turn` (`core.ail:21-30`) to the plan heading; "up" is
the direction of travel for the whole journey (no flip, D-14).

**Autopilot.** Each tick, with τ the proper time since commit, the sim splits
`dtau` at any boundary (τburn, τburn + τcoast, τtotal) inside the tick and
applies `accelerate` with +a_B, 0 or −a_B to each piece (exact at any step,
`kinematics.ail:59-72`), emitting a `phase` event at each crossing. A boost is
~1e-5 yr, so at dtau = 0.01 one tick can hold the whole boost and two `phase`
events. Drag does not alter the kinematics: by construction the drive cancels
it, and the cost appears only in the ledger. The final piece ends exactly at
τtotal; then φ is snapped to 0, position to `target.pos`, and the `arrived`
event reports the residuals `|x_stepped − d|` and
`|t_stepped − (t0 + galaxyTime)|`, which tests require below 1e-9·max(1, d).
Leftover `dtau` after arrival is spent at rest.

*As implemented in M2.3b:* the commitment carries `el`, the proper time flown
since the commit, set to the boundary value exactly when a boundary is
crossed (the ship's own `tau` is τ0 plus the pieces, which can be an ulp
off); the phase is the package's `phaseAt(trip, el)` and each piece runs to
the next boundary of that phase. `commit` rebases the line of motion at the
ship (origin = position, x0 = x) even when no turn is needed, so x − x0 is the
distance flown. The brake's last |Δφ| is taken to the snapped 0, so the
ledger's boost + brake is m_eff c² · 2φ_peak to rounding and closes on
`tripEnergy(...).total`. `phaseAt` reaches core through `sim/tripphase.ail`
(an index 0–3) because the package's `TripPhase.Arrived` constructor clashes
with `Journey.Arrived`, and an aliased constructor import is accepted but
never matches (ailang#1478).

**Tests** (`sim/core_test.ail`, named `check…()`): plans equal check rows
1–3 and (diag) 6–9 to 1e-9; plan readouts equal the readout table to 1e-9
relative; a 0.01-yr stepped α Cen voyage at 0.99c and at the cap hits each
phase boundary and `motionAt` to 1e-9; the residuals; the ledger at arrival;
`cruise_phi` below 0.9c or above the cap refused `out_of_range`; every intent
kind against a `Committed` world leaves `journey` unchanged and is refused
`committed` (one arm per `Intent` constructor and no wildcard; AILANG does
not check match exhaustiveness, so the coverage is test-enforced:
`checkCommittedRefusesAll` sends every constructor, and a constructor added
without an arm is a runtime match failure, never an accepted intent); `thrust`/`heading`/`flip_g`
outside diag refused `diag_only`; commit while moving refused `moving`; a stale
`plan_id` refused `stale_plan`. A scripted α Cen journey entry (`journeyVm`)
joins `make strict`.

### M2.4 Pure PRNG with named streams

Counter-based: a value is `mix(seed, streamId, counter)`, and the world holds
one counter per named stream (`Rng = {journey, crew, events, galaxy, ai: int}`
as a fixed record, not a map). Streams are independent by construction and
adding a stream never shifts another's values. `rng` in `hello` names the
algorithm, so golden logs record it.

The mixer must run on the strict VM, which today rules out xor and shifts
(V3). Plan:
- **Preferred: SplitMix64** finaliser, checked against its test vector
  (seed 0 → `0xe220a8397b1dcdaf`, V4), once bitwise ops are VM-wired; the
  repro goes upstream at sprint start.
- **Fallback** (if the fix is not in the pin when M2.4 starts): a 64-bit LCG
  (`state·6364136223846793005 + inc`, wrapping) from the counter-derived
  state, high 32 bits by division. Only `*`, `+`, `/`, `%`, comparisons, all
  strict-clean (V3). `rng: "lcg64hi-1"`.
- Either way: `tools/rng_ref.py` reproduces the first 1,000 values of each
  stream bit for bit; chi-square on 10⁵ draws per stream passes at p > 0.001;
  seed and stream id fully determine output. Switching algorithms is an `rng`
  id change plus regenerated goldens.

### M2.5 Replay harness and 10k-tick parity

- `tests/replays/*.ndjson`: input logs (first lines `hello`, `new_game`);
  `*.state.ndjson`: the sim's full stdout for that log.
- `tools/gen_session.py` writes `session10k.ndjson` deterministically: 10,000
  `input` lines at dtau = 0.01 covering a plan, a replan, a commit, a full
  α Cen voyage at 0.99c (≈ 63 ticks) with cancel, thrust and replan attempts
  during transit, arrival, a cap-speed voyage, a 100-ly voyage in larger
  ticks, a diag 1 g flip-and-burn voyage (≈ 359 ticks), out-of-range
  `cruise_phi`, `draw` intents on every stream, and malformed lines (each
  kind once). Its golden output is ~3 MB, so only `session10k.state.sha256`
  is committed; smaller sessions commit the full golden.
- `make replay`: per log, run `--bytecode` and the interpreter, `cmp` them,
  then `cmp`/`shasum -c` against the golden; prints the AILANG version.
  `make replay-record LOG=…` regenerates a golden (a reviewed diff, never in
  `make test`). `make test` gains `replay`; `parity`/`parity-offaxis` point at
  the harness. Godot logs (`record_path`) replay the same way, which M4's
  "replay is byte-identical" acceptance inherits.

### M2.6 Godot galaxy map (first UI)

`ui/galaxy_map.{tscn,gd}`: the catalogue as a MultiMesh point cloud (float32
is fine for drawing), an orbit camera, screen-space nearest-star picking and a
side panel whose numbers are **only** the sim's `journey.plan` fields; the map
has no physics. Selecting a star sends `plan` with the star's catalogue
**index**, `id`, the float64 `x, y, z` read from the parsed JSON dictionary
(never from a `Vector3`) and the slider's `cruise_phi`. The cruise slider spans
0.9c to the cap, uniform in φ, default 0.99c (D-14). The panel shows both
clocks first, then arrival ("Earth +4.414 yr"), age on arrival, years left,
then the energy ledger, ISM load, glow and forward CMB temperature. Commit
opens one dialog showing both clocks and the years left at home with a 1.5 s
hold (D-12), then sends `commit`; afterwards the Cancel button stays enabled
and shows the sim's `committed` refusal. Crew-age lines read "placeholder".
In play the clock at rest advances at a fixed host rate with no pause while
planning (D-12). `main.gd` gains a `--map` start mode.

`tests/test_galaxy_map.gd` (headless, fake viewport) selects a star by index
and asserts: labels equal the formatted sim values; `plan.target.pos` and
`cruise_phi` echo exactly; the default slider sends φ = atanh 0.99; the commit
dialog does not send before 1.5 s of hold; `tick` advances while the panel is
open; a post-commit Cancel gives `refused: committed` with no journey change.
`--map-capture=renders` writes `renders/galaxy_map.png` for a human look.

## Acceptance criteria

`$A` is the pinned v0.50.0 `ailang` (`AILANG=$A` on every make line; V8). `$PKG`
is the package clone's `packages/relativity`.

| # | Criterion | Command |
|---|---|---|
| AC1 | Package: new functions' tests pass (trip rows 1–9, readout table, HB-n digits, finite φ sweep), quality clean (no PUB gates), the next free minor is published and pinned, lock consistent | `cd $PKG && $A test --package . && $A pkg quality . && $A pkg info sunholo/relativity`; then `grep relativity sim/ailang.toml && make deps AILANG=$A` |
| AC2 | Planner equals the closed form to 1e-9: cruise rows 1–3 (α Cen 0.99c: 0.6227 ship-yr, 4.414 Earth-yr) and diag flip rows 6–9 (α Cen 1 g: 3.582 ship-yr, 6.003 Earth-yr, 0.9517c) | `cd sim && $A test --package .` (`checkPlanCruise09`, `checkPlanCruise099`, `checkPlanCruiseCap`, `checkPlanAlphaCen`, `checkPlanGl559`, `checkPlanCoast100`, `checkPlanFallback`) |
| AC3 | Planner readouts (boost/brake/drag/total energy, drag force, hold power, load, glow, forward CMB, arrival, age, years left, boost minutes) equal the readout table and package outputs to 1e-9 relative | `cd sim && $A test --package .` (`checkPlanReadouts`) |
| AC4 | Cruise speed bounds: φ outside [atanh 0.9, φcap] refused `out_of_range`; `flip_g`, `thrust`, `heading` outside diag refused `diag_only` | `cd sim && $A test --package .` (`checkCruiseRange`, `checkDiagOnly`) |
| AC5 | Stepped voyage matches `motionAt` at every phase boundary (0.99c and cap) and arrival residuals < 1e-9·max(1, d) | `cd sim && $A test --package .` (`checkVoyageBoundaries`, `checkArrivalResidual`) |
| AC6 | Ledger at arrival equals `tripEnergy` total to 1e-9 relative; `available_kg` unchanged by any journey | `cd sim && $A test --package .` (`checkLedgerAtArrival`, `checkMassClosed`) |
| AC7 | Commit is irreversible: every intent kind against a committed world is refused `committed` and leaves `journey` unchanged; no `Committed → Planned/Idle` transition exists | `cd sim && $A test --package .` (`checkCommittedRefusesAll`) and `! grep -nE "Committed.*=> *(Idle\|Planned)" sim/core.ail` |
| AC8 | Codecs round-trip every fixture, including the float edge cases; all reason codes are stable | `cd sim && $A test --package .` (`protocol_test.ail`) |
| AC9 | Godot↔sim float64 round trip is bit-exact and the bridge refuses a major ≠ 2 | `godot --headless --path . --script tests/test_sim_bridge.gd` |
| AC10 | Pure core, protocol and PRNG run fully on the strict VM and equal the interpreter (`journeyVm`, `rngVm`, `protocolVm`, existing `scripted*`) | `make strict AILANG=$A` |
| AC11 | PRNG: reference vectors match bit for bit, chi-square passes, streams independent | `python3 tools/rng_ref.py --check` and `cd sim && $A test --package .` (`checkRngVectors`, `checkStreamsIndependent`) |
| AC12 | 10k-tick session with journeys: VM output `cmp`-identical to interpreter output and to the committed golden digest | `make replay AILANG=$A` |
| AC13 | The v2 off-axis log reproduces v1.1's kinematic values from `e9d35c5` | `make replay AILANG=$A` (case `offaxis_v11_equiv`) |
| AC14 | The sim runs headless from a file of inputs with no Godot | `$A run --quiet --package-dir sim --caps IO --entry main sim/ship.ail < tests/replays/alpha_cen.ndjson \| tail -1 \| grep '"arrived"'` |
| AC15 | Galaxy map shows only sim numbers, sends catalogue doubles and φ, defaults to 0.99c, enforces the 1.5 s hold, never pauses, shows the sim's refusal | `godot --headless --path . --script tests/test_galaxy_map.gd` |
| AC16 | Whole headless suite green (includes `replay`, `strict`, `wd-vm`, `catalogue-vm`) | `make test AILANG=$A` |
| AC17 | `make capture` still produces the contact sheet through the v2 bridge, and the map capture exists; both opened and looked at | `make capture && test -s renders/contact_sheet.png && godot --path . -- --map-capture=renders && test -s renders/galaxy_map.png` |
| AC18 | No trip or bubble maths outside the package | `! grep -rnE "acosh\|sinh\|cosh\|exp\(\|tanh\|2\.0 \* phi" sim/core.ail sim/protocol.ail ui/ bridge/` |

## Sub-milestones and estimates

| Sub | Content | LOC (code + tests) | Depends on |
|---|---|---|---|
| M2.0 | Package: `acosh1p`, `rapidityOfOneMinusBeta`, `TripPlan`, `plan*`, `phaseAt`, `motionAt`, `medium` module, `cmbForwardTemperature`; publish next free minor; game pin | 190 + 260 | — |
| M2.1 | `protocol.ail`, slim `ship.ail`, bridge v2 + tee, `main.gd` migration, v1.1 equivalence fixture | 450 + 400 | — (parallel with M2.0) |
| M2.2 | `World`, params, clock, phases, ledger, `tick` skeleton | 170 + 140 | M2.1 |
| M2.3 | Planner, readouts, journey state machine, autopilot, residuals | 290 + 320 | M2.0, M2.2 |
| M2.4 | PRNG streams, `rng_ref.py`, `draw` intent | 110 + 150 | M2.2 |
| M2.5 | `make replay`, `gen_session.py`, goldens, parity targets migrated | 80 + 200 (+ fixtures) | M2.3, M2.4 |
| M2.6 | Galaxy map scene, cruise slider, commit dialog, `--map`, `--map-capture`, headless test | 460 + 180 | M2.3 |
| **Total** | | **≈1,750 + 1,650 ≈ 3,400** (+ fixtures) | |

Order: M2.0 ∥ M2.1 → M2.2 → M2.3 → (M2.4 ∥ M2.6) → M2.5. M2.5 lands last so
its goldens include every intent.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Bitwise ops stay off the strict VM (V3) | Counter-based design is algorithm-agnostic; the LCG fallback is strict-clean today; the repro goes upstream at sprint start |
| M2.1 breaks M1's capture/golden paths while M1 is in sprint | `main.gd` migrates in the same PR; AC17 and `make golden` run before merge; M2.1 is scheduled when no M1 sub-milestone has the bridge open |
| Godot's float printing or parsing loses bits | `full_precision` writes, AC9 bit-exact echo test with edge values; if parsing fails, send floats as `"0x…"` bit strings for `pos` and `cruise_phi` only (decided by the AC9 result) |
| Canon numbers drift between higgs-bubble, the package and the sim (e.g. the brief's 2× flat-mirror drag) | The package tests assert HB-n to their printed digits; the sim tests assert package outputs; a change to HB-n is a reviewed package release |
| m_eff, ε or `boost_g` change after goldens exist | All are scenario parameters echoed in the full state; a default change is a `replay-record` diff, not code |
| Boost/brake shorter than a tick hides them from the player | The sim emits both `phase` events with exact τ; how the host slows the clock around them is M4's warp design |
| Golden logs churn on every harmless change | Goldens are regenerated only by `make replay-record`, reviewed as a diff; the 10k session commits a digest, not 3 MB |
| A protocol that grows into draw calls (roadmap risk) | Change-sets carry game state only; `ship.pos` and `heading` are the only geometry |
| 10k ticks on the interpreter is slow in CI | Measured at M2.5 start; if > 60 s, the CI job runs the 10k case on `main` only and a 2k case on PRs, both still `cmp`-gated |
| Catalogue ids are not unique (V6) and M1.2 will replace the catalogue | Targets are named by index plus id plus position, and the log records the position, so replays do not depend on the catalogue file; M1.2's tier format is asked to carry a unique id |
| PATH `ailang` differs from the pin and gives different bytes | Every gate takes `AILANG=$A`; `make replay` prints the version; queue row 6 (toolchain hygiene) fixes the default |

## Open questions for the user

1. **Journey profile and coasting.** **RESOLVED (D-11, 2026-10-01).** Boost
   (minutes) → cruise at the player's chosen speed (0.9c–0.999999c, γ cap) →
   brake; no flip; the pocket's acceleration is not felt and the generator
   holds 1 g toward aft, so there is no zero-g coast. Supersedes
   ship-structure "1 g from constant thrust". The 1 g flip-and-burn stays a
   package check value (HB-27…29), not the gameplay profile.
2. **Acceleration.** **RESOLVED (D-11).** There is no player-chosen felt
   acceleration: felt gravity is a fixed 1 g comfort setting. The boost
   proper acceleration is an unfelt scenario parameter (`boost_g`, default in
   question 6); `accel_g` is removed from the protocol.
3. **Calendar and ages.** **RESOLVED (D-12).** Relative display ("Earth +6.003
   yr"); `epoch` and `start_age` are scenario parameters; `start_age = 30`.
4. **Manual flight and pausing.** **RESOLVED (D-12).** Manual thrust only in
   `diag` sessions (dev, tests, capture); in play the clock at rest runs at a
   fixed host rate; no pause while planning (Pillar 3).
5. **Commit ritual.** **RESOLVED (D-12).** One dialog showing both clocks and
   the years left at home, with a 1.5 s hold.
6. **RESOLVED (D-15): m_eff canonical value (and the two other bubble defaults)** — m_eff 1 kg, boost 7.5e5 g, ε 1e-9, as recommended. m_eff
   sets the boost energy (m_eff c² φ per boost) and the minimum that lets the
   brake hold against drag; canon says only "tiny but never zero".
   **Recommendation:** `m_eff_kg = 1`. Then at the slice default (0.99c, α Cen)
   boost + brake is 4.76e17 J (5.3 kg mass-equivalent) against 1.37e17 J of
   drag, while at the cap drag dominates (1.38e19 J against 1.30e18 J), so the
   player sees both costs and the γ·d one wins at high speed (the Tau Zero
   theme). Above ~100 kg the boost term would hide the speed cost. Also:
   `boost_g = 7.5e5` (about 5 ship-minutes to the cap) and `glow_eps = 1e-9`
   with f_in = ½ (inward glow 0.28 W/m² at the cap, inside HB-61's guide).
   **Default if unanswered:** those three values, as scenario parameters;
   changing them later is a golden regeneration, not code.

## Deliverables

- Package: `sunholo/relativity` next free minor with `acosh1p`,
  `rapidityOfOneMinusBeta`, `TripPlan`, `planFlipAndBurn`,
  `planBurnCoastBurn`, `TripPhase`, `phaseAt`, `motionAt`, module `medium`
  (`photonDriveEnergy`, `mirrorDragForce`, `mirrorDragPower`,
  `cruiseDragEnergy`, `loadScale`, `kineticFlux`, `glowInwardFlux`,
  `tripEnergy`, `brakeHoldsAgainstDrag`), `optics.forwardDoppler`,
  `optics.cmbForwardTemperature`.
- Game: `sim/protocol.ail`, `sim/core.ail` (`World`, `tick`, journey, ledger,
  PRNG), slim `sim/ship.ail`, `sim/*_test.ail`, `bridge/sim_bridge.gd` v2 with
  record tee, `main.gd` migration, `ui/galaxy_map.{tscn,gd}`,
  `tests/test_galaxy_map.gd`, `tests/replays/`, `tools/gen_session.py`,
  `tools/rng_ref.py`, Makefile `replay`/`replay-record`, CI step.
- Upstream (`ailang messages`, inbox `user`, from `stapledons_godot`, gcp
  store): bitwise operators unwired on the VM under `--strict-bytecode`
  although pure (repro V3), plus any parity divergence the 10k session finds.
- Design repo: roadmap M2 status; a note in `journey-system.md` that its
  instant-acceleration maths is superseded by higgs-bubble §3.
- Report: `design_docs/implemented/r1/m2-report.md` (10k timings, residuals,
  the PRNG algorithm used, upstream reports).

## Verification log

| # | Claim | How checked (2026-10-01) | Result |
|---|---|---|---|
| V1 | α Cen 1 g flip check values (HB-27…29) | `python3` closed form, a = 1.032295275553596 | 3.5823937227478337 / 6.00250277725247 / 0.9516558449006334 |
| V2 | Package has totals but no phase boundaries or φ | read `relativity/0.3.0/journey.ail` | `Trip` = {distance, shipTime, galaxyTime, peakBeta, peakGamma} |
| V3 | Bitwise ops fail the strict VM; `* / %` pass | v0.47.2 release binary: `n ^ 3`, `n & 3`, `n << 3` under `--bytecode --strict-bytecode` | "effectful builtin `_bitwiseXor_Int` not yet wired (Phase 2E)"; same for And, ShiftLeft, ShiftRight; `*`, `/`, `%` ok. Same on v0.50.0 |
| V4 | SplitMix64 on the interpreter matches the reference | `ailang run` vs `python3`, seed 0 | both −2152535657050944081 (= `0xe220a8397b1dcdaf`) |
| V5 | `std/json` runs on the strict VM and prints shortest round-trip | v0.47.2 `--strict-bytecode`: encode 0.1 + 0.2 | `{"x":0.30000000000000004}` on both runtimes (re-run on v0.50.0 at sprint start) |
| V6 | Catalogue ids not unique | `python3` over `data/starmap/stars.json` | 3,802 rows, 3,363 ids; `Gl 559` twice at (1.5, −4.09, −0.05), 4.35667 ly |
| V7 | Staged runtime stale (historical) | `runtime/bin/ailang --version`, `runtime/VERSION` | was v0.45.0; superseded by V8 |
| V8 | Current pin | `runtime/VERSION`, `.github/workflows/ci.yml`, `sim/ailang.lock` | v0.50.0 in all three; `sunholo/relativity` pinned 0.3.0 in `sim/ailang.toml` |
| V9 | Cruise-profile trip rows 1–5 | `python3` closed form (burn-coast-burn in rapidity, a_B = 7.5e5·1.032295275553596 c/yr) | as tabled; 0.99c α Cen 227.44 ship-days, 4.414 yr (matches D-14, HB-20…22); cap 2.263 ship-days (HB-25/26); boost 1.80 / 4.93 ship-minutes; HB-30…34 example 26.5 Earth-minutes, 2.77 AU |
| V10 | Boost/brake drag work cancels in the ledger | `python3` midpoint integration (2×10⁵ steps) of (m_eff a ± F)c over boost and brake plus F c τcoast, α Cen, m_eff = 1 kg | relative difference from the closed-form total: −2.8e-15 (0.9c), −9.4e-15 (0.99c), 0.0 (cap) |
| V11 | Readouts vs higgs-bubble and the brief | `python3`, n = 10⁵ m⁻³, R = 100 m, T_CMB = 2.725 K | HB-35…37, HB-38…43, HB-47…50, HB-51…56, HB-62 reproduced to printed digits; the brief's drag force and energy are 2× (flat mirror; canon is the sphere); brief's "1.7 million suns" = HB-38…43's 1.66 million rounded; brief's 3,850 K used T = 2.7255 (3,854.4 K) vs HB-62's 3,853.7 K; dCoast vs d differs by 4.2e-4 relative at the cap |
| V12 | Minimum m_eff for the brake to hold against drag | `python3`: F(φcap)/(7.5e5 g) | 0.0321 kg at the defaults (0.064 kg for a flat mirror) |
