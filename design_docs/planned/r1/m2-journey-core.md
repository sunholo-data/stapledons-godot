# M2: Simulation protocol and the journey core

**Status:** Planned (design, awaiting sprint plan)
**Release:** r1 · **Milestone:** M2 of [R1 foundations](https://github.com/sunholo-data/stapledons-design/blob/main/roadmap/r1-foundations.md) · mission queue row 3, bar clause 2
**Priority:** P0: M4 (first journey) and the AI service's replay recording both sit on this protocol
**Implements:**
- [R1 roadmap §M2](https://github.com/sunholo-data/stapledons-design/blob/main/roadmap/r1-foundations.md) items 1–6 and its three acceptance bullets
- [ADR 0001](https://github.com/sunholo-data/stapledons-design/blob/main/decisions/0001-engine-and-architecture.md) §Decision (NDJSON sidecar, fixed tick, state lives in AILANG) and §Constraints (pure hash PRNG, hand-written codecs)
- [journey-system](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase3-gameplay/journey-system.md) Parts 1–2 (planning, commit), **not** its maths: its `calculateJourneyTimes` is the instant-acceleration idealisation and is replaced by the package's rocket profiles
- [journey-planning-ui](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/journey-planning-ui.md) §Journey Calculator Panel (numbers only; predictions and crew panels are M4+)
- [galaxy-map](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase2-core-views/galaxy-map.md) Phases 1–3 and 7 (starfield, pan/zoom, select, journey preview)
- [mass-budget](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/mass-budget.md) §AILANG Types, as a stub
- [relativity spec](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md) §1 (conventions: c = 1, rapidity integrated) and §2 "float64 for γ and 1−β". The spec has no trip-time section; the closed forms below are the normative reference, and they live in `sunholo/relativity/journey`
- AILANG `design_docs/planned/v1_1_0/m-game-engine-effects.md` (`Render`/`Input`/`Clock` host effects)

**Depends on:** M0 spike (done). `sunholo/relativity` next minor (M2.0, published here). Does **not** depend on M1 finishing, but M2.1 changes the bridge that M1's `make capture` and `make golden` use (see Risks).
**Estimated:** ~3,150 LOC committed (≈1,700 code + 1,450 tests/tools/fixtures), 7 sub-milestones. The charter row says ~2,000; the difference is the 10k-tick replay tooling and the galaxy map test harness.
**Evidence:** pinned to `e9d35c5`; probes run with the v0.47.2 release binary are in the [Verification log](#verification-log).

## Game vision alignment

Scored against the six pillars (`stapledons-design/vision/core-pillars.md`), as in the M1.2b doc.

| Pillar | Relevance | Score | Notes |
|---|---|---|---|
| Choices Are Final | ++ | +2 | The commit rule lives in the simulation, has no code path back, and is tested by enumerating every intent against a committed journey. The planner shows costs, not outcomes, so it is not a "branching preview" (excluded by the pillar) |
| The Game Doesn't Judge | 0 | 0 | Numbers only; no labels such as "safe" or "reckless" (the old presets' "Dangerous speed" text is dropped) |
| Time Has Emotional Weight | ++ | +2 | Ship-years against Earth-years, the arrival year and the years of your 100 left are the first thing the map shows for every star |
| The Ship Is Home | 0 | 0 | No interior yet (M4) |
| Grounded Strangeness | + | +1 | Real rocket kinematics: a 1 g trip to α Cen peaks at 0.9517c, and no slider pretends acceleration is instant |
| We Are Not Built For This | 0 | 0 | Crew ages are placeholders; frailty arrives with crew simulation (R2) |
| Hard-science spec (constraint, not a pillar) | ++ | +2 | Planner = package closed forms to 1e-9; the stepped voyage is checked against them at every phase boundary |
| **Net** | | **+7** | **Go.** No pillar is at risk. One pillar tension (manual flight and pausing) is open question 4 |

## Problem

The spike has one ship, one command and no rules beyond "don't turn while moving":

1. **The protocol is an unversioned command echo.** `handle` dispatches on a
   `cmd` string with three values (`sim/ship.ail:69-85`) and answers every
   line, accepted or not, with the full ship report (`sim/ship.ail:16-23,64`).
   The version is a string compared as a float on the Godot side
   (`sim/ship.ail:28` sends `"1.1"`; `bridge/sim_bridge.gd:49` refuses
   `to_float() < 1.1`), so "1.10" would read as older than "1.2". There is no
   tick number on the input, so a dropped or duplicated line cannot be
   detected; the bridge infers success from `tick == before + 1`
   (`bridge/sim_bridge.gd:125`). The sim prints an unsolicited state line
   before `hello` (`sim/ship.ail:104`).
2. **Codecs are ad hoc and one-way.** Requests are parsed field by field
   (`sim/ship.ail:35-62`) and there is no decoder for the sim's own output, so
   nothing proves encode∘decode is the identity. On the Godot side,
   `JSON.stringify(request)` is called without `full_precision`
   (`bridge/sim_bridge.gd:121`); the only float round-trip test uses 0.6 and
   0.8 (`tests/test_sim_bridge.gd:31-33`), which survive any 15-digit printer.
3. **There is no world clock, phase or journey.** `Ship` is
   `{tick, motion, heading, origin, x0}` (`sim/core.ail:11`); galaxy and ship
   time exist only as `motion.t` and `motion.tau`. `sim/` never imports
   `sunholo/relativity/journey`, although the package already ships
   `flipAndBurn`, `burnCoastBurn` and `coastAt`
   (`relativity/0.3.0/journey.ail:19,35,55`). Thrust is whatever Godot sends
   each tick (`main.gd:101-104`), so "flip at the midpoint" is the player's
   job, and nothing stops a player reversing mid-voyage.
4. **The package's trip functions are not enough to fly a trip.** They return
   totals (`Trip`, `journey.ail:10-16`) but not the phase boundaries
   (when to flip, when to stop coasting) or the closed-form motion at an
   arbitrary proper time, which the stepped voyage needs to split ticks at a
   flip and to be checked against. `peakBeta` is `tanh(phiPeak)`; the
   rapidity itself is not returned, so `oneMinusBeta` cannot be called on it
   (the spec's §2 precision rule). `burnCoastBurn` takes the cruise speed as
   β, which rounds badly at the vision's 0.999999c cap.
5. **There is no randomness and no replay.** No module in `sim/` uses a
   generator. ADR 0001 rules out `std/rand` (one global seeded stream). The
   only determinism gates are a 600-tick thrust script (`Makefile:35-40`) and
   a 5-line off-axis fixture (`Makefile:42-46`); there is no recorded input
   log and no golden state. **Probe (V3, V4):** on v0.47.2 the bitwise
   operators that SplitMix64 and PCG need (`^`, `&`, `<<`, `>>`) work on the
   interpreter but are labelled "effectful builtin … not yet wired (Phase 2E)"
   by the VM, so a SplitMix64 core fails `--strict-bytecode`. Integer `*`, `/`,
   `%` and wrap-around run on the strict VM.
6. **There is no map or target selection.** The only UI is a HUD label
   (`main.gd:85-86`). The committed catalogue has 3,802 rows but only 3,363
   distinct `id`s (V6: α Cen A and B are both `"Gl 559"`), so an id cannot
   name a target. Star positions are loaded into float32 `Vector3`s
   (`sky/starfield.gd:13,22`), which must not feed a planner.
7. **The staged runtime is stale.** `runtime/VERSION` and `runtime/bin/ailang`
   report v0.45.0 while the pin is v0.47.2 (V7). M2's parity and replay gates
   must name the binary they ran.

## Goals and non-goals

**Goals**
- Protocol v2 (the roadmap's "protocol v1": the first versioned spec; the wire
  already says 1.1, so the integer major is 2) with a handshake, tick-numbered
  inputs of typed intents, and state change-sets. Hand-written AILANG codecs
  with round-trip tests; matching GDScript codec with the same fixtures.
- A pure `tick(world, input)` in `sim/core.ail` owning the clock, the ship's
  phases, the planner, the commit rule and the PRNG, strict-VM clean.
- Planner numbers equal the package closed forms to 1e-9; the stepped voyage
  lands within 1e-9 of them.
- `make replay`: recorded input logs re-run on VM and interpreter, diffed
  byte-for-byte against committed golden state, including a 10k-tick session.
- A Godot galaxy map: pick a star, see the sim's plan, commit; cancel is
  visibly refused by the sim.
- An input record slot for AI results (D-7) so the AI service can be replayed
  without a protocol major bump.

**Non-goals**
- Crew simulation, crew vote, deaths and births (journey-system Part 1 crew
  projection): ages are `startAge + tau` placeholders.
- Journey events, arrival sequence, Earth-side consequences (M4).
- Mass sinks and sources: the mass budget is a carried, reported, unchanging
  value in M2.
- Native `Render`/`Input`/`Clock` effects: the messages are shaped for them;
  the pipe stays.
- Anything SR-visual. M2 adds no shader and no visual of SR, so physics gate 2
  of the definition of done does not apply; the existing `make golden`
  and `make capture` must keep passing.
- Multi-star target catalogues beyond what M1 has committed when M2.6 runs.

## Design

### M2.0 Trip phases in `sunholo/relativity` (package first)

New in the **next minor** after 0.4.0 (0.4.0 is earmarked for `teffFromBV`; M3.1's geodesics target the same slot, so whichever publishes first takes 0.5.0 and the other 0.6.0),
module `journey`, plus one helper in `hyper`. Additive only, so `Trip` and the
three existing functions keep their signatures.

| Function | Definition | Why |
|---|---|---|
| `hyper.acosh1p(u)` | acosh(1+u) = log1p(u + √(u(2+u))) | `flipAndBurn` forms `1 + a·d/2` and loses the low bits of short trips |
| `type TripPlan = { trip: Trip, a: float, phiPeak: float, tauBurn: float, tauCoast: float, tauTotal: float, dBurn: float, dCoast: float }` | phase boundaries in proper time and distance | the sim flips and stops at exact τ |
| `planFlipAndBurn(d, a) -> TripPlan` | φp = acosh1p(a·d/2), τburn = φp/a, τcoast = 0 | |
| `planBurnCoastBurn(d, a, phiCruise) -> TripPlan` | φc given as rapidity; falls back to flip-and-burn when 2(cosh φc − 1)/a ≥ d | β = 0.999999 is 1−1e-6 in float64; the game's slider is γ or φ |
| `type TripPhase = Accelerating \| Coasting \| Decelerating \| Arrived` | | |
| `phaseAt(p, tau) -> TripPhase` | boundaries τburn, τburn+τcoast, τtotal; left-closed | one definition for sim and tests |
| `motionAt(p, tau) -> Motion` | closed form per phase, using 2 sinh²(φ/2)/a for (cosh φ − 1)/a; clamped to [0, τtotal] | reference for the stepped voyage |

Existing `flipAndBurn`/`burnCoastBurn` are reimplemented as `planX(...).trip`
so there is one formula. Tests (named `check…()` per the CLAUDE.md test-block
workaround): α Cen and the rows below to 1e-12 against `python3` references
committed in the package; `motionAt(p, τtotal)` has φ = 0 and x = d to 1e-12;
continuity of t and x across each boundary; `phaseAt` at each boundary;
strict-VM equals interpreter on a digest entry, as AC-W5 did. Then
`CHANGELOG`, `[release] kind = "feature"`, `ailang pkg quality` with no gates,
dry run, publish (standing grant), and the game pins it.

Check values (a = `standardGravity()` = 1.032295275553596 c/yr):

| Trip | Ship-yr | Earth-yr | Peak β | Peak γ |
|---|---|---|---|---|
| Sol → α Cen, 4.37 ly, flip at 1 g (roadmap) | 3.5823937227478337 | 6.00250277725247 | 0.9516558449006334 | 3.2555651770846072 |
| Sol → `Gl 559` catalogue position, 4.35667304258651 ly | 3.5780871495240905 | 5.988497264963769 | 0.9514456743125428 | 3.248686499496882 |
| 100 ly, 1 g, cruise β = 0.99 (φc = atanh 0.99) | 17.696001151818983 | 102.69103232505418 | 0.99 | 7.088812050083355 |
| 1,000 ly, 1 g, cruise γ = 707.1 (unreachable, falls back) | 13.448622327743177 | 1001.9355569687548 | 0.9999981304317682 | 517.147637776798 |

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
| G→S | `new_game` | `seed` (0 ≤ seed < 2^53), `scenario` (`"sol"`), `diag` (bool), `epoch`, `start_age` | world construction |
| G→S | `input` | `tick` (= world tick + 1), `dtau` (ship-years, 0 ≤ dtau ≤ 1), `intents: [...]` | `Clock` supplies (tick, dtau); `Input` supplies intents |
| S→G | `state` | `tick`, `status`, `changes: {clock?, ship?, journey?, mass?, rng?}`, `events: [...]`, `refused: [{i, reason}]`, `full` (bool) | `Render` receives game state, never draw calls |
| G→S | `quit` | | |

**Intents** (tagged by `k`; unknown `k` is a schema error):

| `k` | Fields | Accepted when |
|---|---|---|
| `plan` | `target: {index, id, pos: {x,y,z}}` (float64 ly, galactic Cartesian as `stars.json`), `profile: {accel_g, cruise_phi?}` | not committed |
| `commit` | `plan_id` | a plan with that id exists, ship at rest, not committed |
| `cancel` | | never while committed (refused `committed`); clears an uncommitted plan |
| `thrust`, `heading` | as v1.1 | `diag` sessions only, not committed (open question 4) |
| `record` | `source` (`"ai"`), `req`, `kind`, `sha256`, `body` | reserved in 2.0 (refused `unsupported`); the AI service adds it as 2.1 |
| `draw` | `stream` | `diag` only: draws one value, reported in `events` (exercises the PRNG in replays) |

**Rejection model.** Two levels, both deterministic. A *malformed* input (bad
JSON, wrong `v`, `tick` ≠ world tick + 1 → `bad_tick`, bad `dtau`, schema
error) changes nothing and the tick does not advance (today's behaviour,
`protocol_test.ail:47-51`). A *well-formed intent the rules refuse* is listed in
`refused` and the rest of the tick proceeds, so pressing Cancel during transit
never stalls the clock.

**Change-sets.** The first `state` after `new_game` is `full: true`. After that
a section appears only if a field in it changed, and carries the whole section
(sections are small, so field-level diffs are not worth the codec size).
`clock: {tau, t, year, age}`; `ship: {phase, beta, one_minus_beta, gamma,
heading, pos}` (`one_minus_beta` from `oneMinusBeta(phi)`, so Godot never
subtracts); `journey: {state, plan_id, plan?}` with `plan: {target, distance,
ship_years, earth_years, peak_beta, peak_one_minus_beta, peak_gamma,
arrive_year, age_on_arrival, years_left}`; `mass: {available_kg}`;
`rng: {streams}`. `events` include `phase` (from, to, tau), `committed`,
`arrived` (with residuals, below) and `draw`.

**Modules.** `sim/protocol.ail` (new, pure): `type Input`, `type Intent`,
`type StateMsg`, `decodeInput : string -> Result[Input, string]`,
`encodeState : StateMsg -> string`, and the inverse pair `encodeInput`,
`decodeState`, which exist for the round-trip tests and for `make replay`
tooling. `std/json` runs on the strict VM (V5), so `protocol.ail` is added to
`make strict`. `sim/ship.ail` shrinks to the I/O loop: read line → decode →
`core.tick` → encode → print. That loop is the only code a native-effects
port replaces.

**Godot.** `bridge/sim_bridge.gd` gains `hello()`, `new_game(seed, …)`,
`send(intents, dtau) -> bool`, an integer-major check, a mirrored `world`
dictionary that applies change-sets, and an optional `record_path` that tees
every line written to stdin (byte for byte) into an NDJSON log. Timeouts and
child cleanup stay as tested (`tests/test_sim_bridge.gd:65-92`).
`main.gd` and the capture/golden paths move to the new API in the same
sub-milestone (diag session, `thrust` intents), so `make capture` keeps
working. v1.1 is removed, not kept alongside: `make parity` and
`parity-offaxis` fixtures are rewritten as v2 logs, and a one-time
conversion test asserts that the v2 off-axis log produces the same
`beta, gamma, tau, t, x, pos` values as v1.1 did at `e9d35c5`
(`tests/fixtures/v11_offaxis.golden`, captured before the change).

**Round-trip tests.** `sim/protocol_test.ail`: for a fixture set of inputs and
states (including 0.1, 1−2⁻⁵², 5e-324, 1e308 and −0.0),
`decodeInput(encodeInput(x)) == x` and `decodeState(encodeState(s)) == s`;
every malformed case keeps today's reason codes plus `bad_tick`, `bad_v`,
`bad_intent`. `tests/test_sim_bridge.gd` sends the same float fixtures through
GDScript and checks the echoed `plan.target.pos` is bit-identical.

### M2.2 World clock, ship phases, mass stub

```
World   = { tick, seed, clock: {epoch, startAge}, ship: Ship, journey: Journey,
            mass: {availableKg}, rng: Rng, diag: bool }
Ship    = today's Ship (sim/core.ail:11) + phase: ShipPhase
ShipPhase = AtRest | Accelerating | Coasting | Decelerating
```

Galaxy time is `motion.t` and ship time is `motion.tau`; they are not
duplicated. `year = epoch + t`, `age = startAge + tau` (placeholder for the
crew model). Phase is derived for manual flight (|φ| < 1e-9 → `AtRest`, the
threshold already used by `turn`, `core.ail:24`) and set by the autopilot
during a journey. The mass budget is `20,000 kg` (mass-budget §Starting Mass):
the bubble ship carries no propellant (bubble-constraint: mass cannot cross),
so no rocket-equation mass ratio exists and journeys leave it unchanged; a
test pins that.

### M2.3 Planner and commit

**Plan.** `plan` computes `d = |target.pos − position(ship)|` in float64
scalars, picks `planFlipAndBurn` or `planBurnCoastBurn` from the profile, and
stores `Planned {id, target, heading, tripPlan}`. Plan ids increase
monotonically from 1. All numbers in `journey.plan` are package outputs or
arithmetic on them (`arrive_year = year + trip.galaxyTime`,
`years_left = 100 − age − trip.shipTime`).

**Journey state machine** (`Journey = Idle | Planned(..) | Committed(..) | Arrived(..)`):

```
Idle/Arrived --plan--> Planned --plan--> Planned (replan)
Planned --cancel--> Idle
Planned --commit(id, at rest)--> Committed {plan, tau0, t0}
Committed --(sim only, tau = tau0 + tauTotal)--> Arrived
Committed --plan|cancel|commit|thrust|heading--> Committed, refused "committed"
```

There is no function from `Committed` to `Planned` or `Idle`. `commit`
performs the at-rest `turn` (`core.ail:21-30`) to the plan heading.

**Autopilot.** Each tick, with τ the proper time since commit, the sim splits
`dtau` at any boundary (τburn, τburn + τcoast, τtotal) inside the tick and
applies `accelerate` with +a, 0 or −a to each piece (exact at any step,
`kinematics.ail:59-72`), emitting a `phase` event at each crossing. The final
piece ends exactly at τtotal; then φ is snapped to 0, position to
`target.pos`, and the `arrived` event reports the residuals
`|x_stepped − d|` and `|t_stepped − (t0 + galaxyTime)|`, which tests require
below 1e-9·max(1, d). Leftover `dtau` after arrival is spent at rest.

**Tests** (`sim/core_test.ail`, named `check…()`): α Cen plan equals the table
to 1e-9; a 0.01-yr stepped α Cen voyage hits each phase boundary and
`motionAt` to 1e-9; the residuals; the 100-ly coast case; every intent kind
against a `Committed` world leaves `journey` unchanged and is refused
`committed` (exhaustive over the `Intent` constructors, so adding an intent
without a rule fails to compile the match); commit while moving is refused
`moving`; a stale `plan_id` is refused `stale_plan`. A scripted α Cen journey
entry (`journeyVm`) joins `make strict`.

### M2.4 Pure PRNG with named streams

Counter-based: a value is `mix(seed, streamId, counter)`, and the world holds
one counter per named stream (`Rng = {journey, crew, events, galaxy, ai: int}`
as a fixed record, not a map). Streams are independent by construction and
adding a stream never shifts another's values. `rng` in `hello` names the
algorithm, so golden logs record it.

The mixer must run on the strict VM, which today rules out xor and shifts
(V3). Plan:
- **Preferred: SplitMix64** finaliser, checked against its published test
  vector (seed 0 → `0xe220a8397b1dcdaf`, V4), once bitwise ops are VM-wired.
  The repro goes upstream at sprint start (see Deliverables).
- **Fallback, used if the fix is not in the pinned release when M2.4 starts:**
  a 64-bit LCG (`state·6364136223846793005 + inc`, wrapping) iterated from
  the counter-derived state, returning the high 32 bits with a division-based
  logical shift. Only `*`, `+`, `/`, `%` and comparisons, all strict-VM clean
  (V3). Lower statistical quality, ample for game events. `rng:
  "lcg64hi-1"`.
- Either way: a `python3` reference (`tools/rng_ref.py`) reproduces the first
  1,000 values of each stream bit for bit; a chi-square smoke test on 10⁵
  draws per stream passes at p > 0.001; `seed` and stream id fully determine
  output (two worlds, same seed, same draws). Switching algorithms later is a
  `rng` id change plus regenerated goldens, recorded in the changelog.

### M2.5 Replay harness and 10k-tick parity

- `tests/replays/*.ndjson`: input logs (first lines `hello`, `new_game`).
  `tests/replays/*.state.ndjson`: the sim's full stdout for that log.
- `tools/gen_session.py` writes `session10k.ndjson` deterministically: 10,000
  `input` lines at dtau = 0.01 covering a plan, a replan, a commit, a full
  α Cen voyage (≈ 359 ticks) with cancel, thrust and replan attempts during
  transit, arrival, a burn-coast-burn voyage to a 100-ly target in larger
  ticks, `draw` intents on every stream, and malformed lines (each kind once).
  Its golden output is ~3 MB, so only `session10k.state.sha256` is committed;
  smaller sessions commit the full golden.
- `make replay`: for each log, run `--bytecode` and the interpreter
  (`$(SIMFLAGS)`, `--package-dir sim`), `cmp` VM against interpreter, then
  `cmp` (or `shasum -c`) against the golden. Prints the AILANG version used.
- `make replay-record LOG=…` regenerates a golden; regenerating is a reviewed
  diff, never part of `make test`.
- `make test` gains `replay`; `parity` and `parity-offaxis` become replay
  logs, so their targets point at the harness.
- Godot logs played interactively (bridge `record_path`) replay the same way:
  the M4 "replay is byte-identical" acceptance inherits this.

### M2.6 Godot galaxy map (first UI)

`ui/galaxy_map.tscn` + `ui/galaxy_map.gd`: the committed catalogue as a 3D
point cloud (MultiMesh; positions may be float32 for drawing), an orbit
camera, nearest-star picking by screen-space distance, and a side panel. The
panel's numbers are **only** the sim's `journey.plan` fields, formatted; the
map has no physics. Selecting a star sends `plan` with the star's catalogue
**index**, `id`, and the float64 `x, y, z` read from the parsed JSON
dictionary (never from a `Vector3`). A profile control offers 1 g
flip-and-burn and, if open question 1 says so, a cruise cap in γ. Commit
opens a confirmation (open question 5), then sends `commit`; afterwards the
Cancel button stays enabled and shows the sim's `committed` refusal. Crew-age
lines read "placeholder". `main.gd` gains a `--map` start mode.

`tests/test_galaxy_map.gd` (headless): loads the map controller with a fake
viewport, selects the star at a given index, and asserts the panel's label
text equals the formatted sim values, that `plan.target.pos` echoes the
catalogue doubles exactly, and that a post-commit Cancel produces
`refused: committed` with no journey change. `godot --path . -- --map-capture=renders`
writes `renders/galaxy_map.png` for a human look (needs a window; not CI).

## Acceptance criteria

`$A` is a v0.47.2 `ailang` (`AILANG=$A` on every make line; V7). `$PKG` is
the package clone's `packages/relativity`.

| # | Criterion | Command |
|---|---|---|
| AC1 | Package: new functions' tests pass, quality clean (no PUB gates), the next-minor version is published and pinned, lock consistent | `cd $PKG && $A test --package . && $A pkg quality . && $A pkg info sunholo/relativity`; then `grep relativity sim/ailang.toml && make deps AILANG=$A` |
| AC2 | Planner equals the closed form to 1e-9 for all four check-value rows (α Cen: 3.582 ship-yr, 6.003 Earth-yr, 0.9517c) | `cd sim && $A test --package .` (`checkPlanAlphaCen`, `checkPlanGl559`, `checkPlanCoast100`, `checkPlanFallback`) |
| AC3 | Stepped voyage matches `motionAt` at every phase boundary and arrival residuals < 1e-9·max(1, d) | `cd sim && $A test --package .` (`checkVoyageBoundaries`, `checkArrivalResidual`) |
| AC4 | Commit is irreversible: every intent kind against a committed world is refused `committed` and leaves `journey` unchanged; no `Committed → Planned/Idle` transition exists | `cd sim && $A test --package .` (`checkCommittedRefusesAll`) and `! grep -nE "Committed.*=> *(Idle\|Planned)" sim/core.ail` |
| AC5 | Codecs round-trip every fixture, including the float edge cases; all reason codes are stable | `cd sim && $A test --package .` (`protocol_test.ail`) |
| AC6 | Godot↔sim float64 round trip is bit-exact and the bridge refuses a major ≠ 2 | `godot --headless --path . --script tests/test_sim_bridge.gd` |
| AC7 | Pure core, protocol and PRNG run fully on the strict VM and equal the interpreter (`journeyVm`, `rngVm`, `protocolVm`, existing `scripted*`) | `make strict AILANG=$A` |
| AC8 | PRNG: reference vectors match bit for bit, chi-square passes, streams independent | `python3 tools/rng_ref.py --check` and `cd sim && $A test --package .` (`checkRngVectors`, `checkStreamsIndependent`) |
| AC9 | 10k-tick session with journeys: VM output `cmp`-identical to interpreter output and to the committed golden digest | `make replay AILANG=$A` |
| AC10 | The v2 off-axis log reproduces v1.1's kinematic values from `e9d35c5` | `make replay AILANG=$A` (case `offaxis_v11_equiv`) |
| AC11 | The sim runs headless from a file of inputs with no Godot | `$A run --quiet --package-dir sim --caps IO --entry main sim/ship.ail < tests/replays/alpha_cen.ndjson \| tail -1 \| grep '"arrived"'` |
| AC12 | Galaxy map shows only sim numbers, sends catalogue doubles, shows the sim's refusal | `godot --headless --path . --script tests/test_galaxy_map.gd` |
| AC13 | Whole headless suite green (includes `replay`, `strict`, `wd-vm`, `catalogue-vm`) | `make test AILANG=$A` |
| AC14 | `make capture` still produces the contact sheet through the v2 bridge, and the map capture exists; both opened and looked at | `make capture && test -s renders/contact_sheet.png && godot --path . -- --map-capture=renders && test -s renders/galaxy_map.png` |
| AC15 | No trip maths outside the package | `! grep -rnE "acosh\|sinh\(phi\|2\.0 \* phi" sim/core.ail sim/protocol.ail ui/ bridge/` |

## Sub-milestones and estimates

| Sub | Content | LOC (code + tests) | Depends on |
|---|---|---|---|
| M2.0 | Package: `acosh1p`, `TripPlan`, `plan*`, `phaseAt`, `motionAt`; publish next minor; game pin | 120 + 160 | — |
| M2.1 | `protocol.ail`, slim `ship.ail`, bridge v2 + tee, `main.gd` migration, v1.1 equivalence fixture | 450 + 400 | — (parallel with M2.0) |
| M2.2 | `World`, clock, phases, mass stub, `tick` skeleton | 150 + 120 | M2.1 |
| M2.3 | Planner, journey state machine, autopilot, residuals | 250 + 280 | M2.0, M2.2 |
| M2.4 | PRNG streams, `rng_ref.py`, `draw` intent | 110 + 150 | M2.2 |
| M2.5 | `make replay`, `gen_session.py`, goldens, parity targets migrated | 80 + 200 (+ fixtures) | M2.3, M2.4 |
| M2.6 | Galaxy map scene, `--map`, `--map-capture`, headless test | 450 + 180 | M2.3 |
| **Total** | | **≈1,610 + 1,490 ≈ 3,100** (+ fixtures) | |

Order: M2.0 ∥ M2.1 → M2.2 → M2.3 → (M2.4 ∥ M2.6) → M2.5. M2.5 lands last so
its goldens include every intent.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Bitwise ops stay off the strict VM (V3) | Counter-based design is algorithm-agnostic; the LCG fallback is strict-clean today; the repro goes upstream at sprint start |
| M2.1 breaks M1's capture/golden paths while M1 is in sprint | `main.gd` migrates in the same PR; AC14 and `make golden` run before merge; M2.1 is scheduled when no M1 sub-milestone has the bridge open |
| Godot's float printing or parsing loses bits | `full_precision` writes, AC6 bit-exact echo test with edge values; if parsing fails, send floats as `"0x…"` bit strings for `pos` only (decided by the AC6 result) |
| Golden logs churn on every harmless change | Goldens are regenerated only by `make replay-record`, reviewed as a diff; the 10k session commits a digest, not 3 MB |
| A protocol that grows into draw calls (roadmap risk) | Change-sets carry game state only; `ship.pos` and `heading` are the only geometry |
| 10k ticks on the interpreter is slow in CI | Measured at M2.5 start; if > 60 s, the CI job runs the 10k case on `main` only and a 2k case on PRs, both still `cmp`-gated |
| Catalogue ids are not unique (V6) and M1.2 will replace the catalogue | Targets are named by index plus id plus position, and the log records the position, so replays do not depend on the catalogue file; M1.2's tier format is asked to carry a unique id |
| Stale staged runtime (V7) or PATH `ailang` (v0.50 here) gives different bytes | Every gate takes `AILANG=$A`; `make replay` prints the version; queue row 6 (toolchain hygiene) fixes the default |

## Open questions for the user

1. **Journey profile and coasting.** The vision has the player choose a cruise
   speed between 0.9c and 0.999999c; the roadmap's example is 1 g
   flip-and-burn; ship canon says continuous 1 g thrust *is* the ship's
   gravity, so a coast phase means weightlessness aboard. Offer burn-coast-burn
   with a γ cap in the map, or flip-and-burn only? **Recommendation:** the sim
   supports both (it costs nothing); the map offers a γ cap, defaulting to
   "no cap" (flip-and-burn); record "coasting is zero-g" as canon for M4 to
   use or overrule. **Default if unanswered:** both in the sim, map shows
   flip-and-burn only.
2. **Acceleration.** Fixed 1 g, or player-chosen (e.g. 0.5–2 g, with the
   human cost as a later pillar-6 hook)? **Recommendation:** fixed 1 g in R1;
   the protocol already carries `accel_g`. **Default:** 1 g.
3. **Calendar and ages.** What year is departure, and how old is the player at
   the start of the 100-year career? **Recommendation:** scenario parameters
   (`epoch`, `start_age`) so canon can change without code. **Default:**
   relative display ("Earth +6.003 yr"), `start_age = 30`.
4. **Manual flight and pausing (Pillar 1 and 3 tension).** The spike's free W/S
   thrust lets a player "turn back" outside any commit, and `dtau = 0` ticks
   pause the universe, which Pillar 3 excludes. **Recommendation:** manual
   thrust only in `diag` sessions (dev, tests, capture); in play, the clock at
   rest runs at a fixed host rate with no pause while planning. **Default:**
   that.
5. **Commit ritual.** Type "DEPART" (journey-planning-ui), a two-step dialog
   (journey-system), or hold-to-confirm? The sim only needs `commit`, so this
   is UI. **Recommendation:** one dialog showing both clocks and the years
   left, with a 1.5 s hold. **Default:** that.

## Deliverables

- Package: `sunholo/relativity` next minor with `acosh1p`, `TripPlan`,
  `planFlipAndBurn`, `planBurnCoastBurn`, `TripPhase`, `phaseAt`, `motionAt`.
- Game: `sim/protocol.ail`, `sim/core.ail` (`World`, `tick`, journey, PRNG),
  slim `sim/ship.ail`, `sim/*_test.ail`, `bridge/sim_bridge.gd` v2 with
  record tee, `main.gd` migration, `ui/galaxy_map.{tscn,gd}`,
  `tests/test_galaxy_map.gd`, `tests/replays/`, `tools/gen_session.py`,
  `tools/rng_ref.py`, Makefile `replay`/`replay-record`, CI step.
- Upstream (`ailang messages`, inbox `user`, from `stapledons_godot`, gcp
  store): bitwise operators unwired on the VM under `--strict-bytecode`
  although pure (repro V3), plus any parity divergence the 10k session finds.
- Design repo: roadmap M2 status; a note in `journey-system.md` that its
  instant-acceleration maths is superseded.
- Report: `design_docs/implemented/r1/m2-report.md` (10k timings, residuals,
  the PRNG algorithm used, upstream reports).

## Verification log

| # | Claim | How checked (2026-10-01) | Result |
|---|---|---|---|
| V1 | α Cen check values | `python3` closed form, a = 1.032295275553596 | 3.5823937227478337 / 6.00250277725247 / 0.9516558449006334 |
| V2 | Package has totals but no phase boundaries or φ | read `relativity/0.3.0/journey.ail` | `Trip` = {distance, shipTime, galaxyTime, peakBeta, peakGamma} |
| V3 | Bitwise ops fail the strict VM; `* / %` pass | v0.47.2 release binary: `n ^ 3`, `n & 3`, `n << 3` under `--bytecode --strict-bytecode` | "effectful builtin `_bitwiseXor_Int` not yet wired (Phase 2E)"; same for And, ShiftLeft, ShiftRight; `*`, `/`, `%` ok. Same on v0.50.0 |
| V4 | SplitMix64 on the interpreter matches the reference | `ailang run` vs `python3`, seed 0 | both −2152535657050944081 (= `0xe220a8397b1dcdaf`) |
| V5 | `std/json` runs on the strict VM and prints shortest round-trip | v0.47.2 `--strict-bytecode`: encode 0.1 + 0.2 | `{"x":0.30000000000000004}` on both runtimes |
| V6 | Catalogue ids not unique | `python3` over `data/starmap/stars.json` | 3,802 rows, 3,363 ids; `Gl 559` twice at (1.5, −4.09, −0.05), 4.35667 ly |
| V7 | Staged runtime stale | `runtime/bin/ailang --version`, `runtime/VERSION` | v0.45.0 (pin and lock say v0.47.2) |
