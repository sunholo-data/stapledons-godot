# Sprint plan: R1-M2-JOURNEY, the simulation protocol and the journey core

## Summary

Turn the spike's one-ship command echo into the game's journey core: a
versioned NDJSON protocol with hand-written codecs, a pure `tick(world,
input)` that owns the clock, the boost → cruise → brake journey (D-11), the
commit rule, a closed energy ledger and a pure PRNG, a replay harness, and the
first Godot UI (the galaxy map). All trip and bubble maths ships first in
`sunholo/relativity` (package-first, CLAUDE.md gate 3).

**Ordering goal (Mark, attended 2026-10-01: "get something up so I can review
it, and then we can tweak as we go"):** the sequence is built for M4's **first
review build** (galaxy map → commit → transit on the blockout bundle).
Package → protocol → world/planner → map comes first, and the first reviewable
capture of the map with real plan numbers is an explicit checkpoint for Mark
(**⏸ R1**, after milestone 6 of 10). PRNG and replay come last; nothing the
review build needs depends on them.

**Design doc:** [m2-journey-core.md](m2-journey-core.md) (AC1–AC18;
OQ1–OQ6 resolved by ledger D-11, D-12, D-15; mission queue row 1)
**Sprint ID:** `R1-M2-JOURNEY` · **Progress file:** `.ailang/state/sprints/sprint_R1-M2-JOURNEY.json`
**Duration:** 10 milestones, each sized for one mission iteration; planned
at **~12–13 iterations, ~5 working days** of loop time (velocity below), plus
Mark's review time at ⏸ R1. The loop does not block on that review.
**Dependencies:** M0 spike (done); `sunholo/relativity@0.3.0` (published,
pinned); AILANG **v0.50.0** (`runtime/VERSION`, CI, lockfile: V8). Does not
depend on M1 finishing.
**Risk level:** Medium. The physics is pre-measured to 1e-12 (design
V1, V9–V12). The risks are the bridge migration while M1 still uses it, Godot
float round-trips, and strict-VM support for ADTs with record payloads at
`World` scale.

**Command legend.** `$A` = `/Users/voightkampff/dev/sunholo-data/stapledons-godot/runtime/bin/ailang`
(v0.50.0; every make line passes `AILANG=$A`, as M1 did). `$PKG` = a **fresh
clone** of `sunholo-data/ailang-packages` at `origin/main`, at
`packages/relativity`, never `~/dev/sunholo-data/ailang-packages` (dirty
working copy; the M1.2b-WD precedent). `godot` = the 4.7.2 binary the Makefile
uses (`$(GODOT)`).

## Current status analysis

### What exists (main at `3cb5406`)
- `sim/core.ail` (58 lines): `Ship {tick, motion, heading, origin, x0}`,
  `step`, at-rest `turn`, `scripted`/`scriptedOffAxis` strict entries.
- `sim/ship.ail` (107 lines): v1.1 command echo (`proto: "1.1"`, string
  `cmd` dispatch, std/json field parsing, reason codes `bad_json`,
  `bad_cmd`, `bad_step`, `bad_heading`, `moving`).
- `bridge/sim_bridge.gd` (179 lines): bounded hello/step waits and child
  cleanup (M1.6a, tested). `main.gd` (377 lines): drives capture and golden.
- `make test` = deps, import, physics, sim, parity, parity-offaxis, strict,
  wd-vm, catalogue-vm, catalogue-bytes, sky-vm, tools-test.
- `sunholo/relativity@0.3.0` has `journey.flipAndBurn`, `burnCoastBurn`,
  `coastAt` returning totals (`Trip`); no phase boundaries, no rapidity
  output, no energetics.
- No `ui/` directory, no PRNG, no replay goldens.

### Velocity (this repo's mission log, `design_docs/stapledon-mission-log.md`)

| Iteration | Item | Estimate | Actual counted LOC | Eval |
|---|---|---|---|---|
| 0 | M1.1 photometry package + publish 0.2.0 | 500 | 323 | 86 PASS |
| 1 → 3 | M1.6a protocol v1.1 + bridge | 450 | ~450 (parked on 2 VM bugs, iter 1 eval 59 FAIL; landed iter 3) | 87 PASS |
| 2 | M1.2a acquire + parse | 250 | 666 (fixtures + mutation tests) | 92 PASS |
| 4 | M1.2b preflight | 200 | 218 | 85 PASS |
| 5 | M1.2b-WD1+WD2 package module + publish 0.3.0 | 410 | ~403 hand-written (+137 generated) | 98 PASS |
| 6 | M1.2b-WD3 game pin | 40 | ~22 code + 38 doc | 98 PASS |
| 7 | M1.2b-T1 pure transform | 240 | 192 | 88 PASS |
| 8 | M1.2b-T2 F32 records | 210 | 133 | 92 PASS |
| attended | M1.4b/c sky model (PR #16) | — | 1,352 insertions incl. data | 91 PASS |

- **First-pass landing rate:** 7 of 8 unattended items landed in their first
  iteration; the one that didn't (M1.6a) was blocked by upstream VM bugs, not
  scope. Estimate accuracy: 0.6× to 2.7× (median about 1.0×). Overruns come
  from fixtures and mutation-driven test strengthening, not from scope growth.
- **Pace:** 9 iterations between 2026-09-27 and 2026-10-01; on 2026-10-01,
  three unattended landings (iterations 6–8) plus one attended landing.
  Planning figure: **~2.5 iterations per day**.
- **Size per iteration:** recent landings were 130–670 counted code/test LOC,
  and 360–3,000 PR insertions including fixtures and evidence. The M1.2b caps
  (250) were a reaction to iteration 1's failure, at a time when the catalogue
  pipeline had no measurements. M2's maths is pre-measured, so this sprint uses
  a **cap of 650 counted code + test + config LOC per milestone**. Fixtures,
  goldens, generated files and docs don't count. Every milestone is planned at
  ≤ 480.
- **Planning total:** 3,420 counted LOC across 10 milestones (design: ≈3,400).
  At ~1.25 iterations per milestone (one evaluator FAIL or upstream park in
  every ~5), that's ~12–13 iterations, **~5 working days at 2.5/day**, or
  ~700 LOC/day. The same planning figure as M1.

### Registry reuse gate (searched 2026-10-01 with `$A pkg search`)

| Milestone | Package | Action | Reason |
|---|---|---|---|
| M2.0 | `sunholo/relativity@0.3.0` | **contribute** | The single source of physics maths (CLAUDE.md gate 3). `journey`, `hyper`, `kinematics`, `optics` exist; add `TripPlan`/`plan*`/`phaseAt`/`motionAt`/`acosh1p`/`rapidityOfOneMinusBeta`, a new `medium` module and `cmbForwardTemperature`, published as the next free minor |
| M2.1a, M2.1b | std/json (bundled v0.50.0) | depend | Shortest round-trip float printing, strict-clean (design V5, re-run at M2.1a start). `pkg search` json/ndjson/protocol/codec returned only unrelated packages (http_helpers, logging, a2ui, agui, discord, ollama_stream); ADR 0001 requires hand-written codecs |
| M2.2, M2.3a, M2.3b | `sunholo/relativity` (new minor) | depend | Planner, readouts, ledger and autopilot call package functions only; AC18 forbids local trip/bubble maths. `pkg search journey/energy` returned no other package |
| M2.4 | none | none | `pkg search random/prng/rng` returned no packages; `hash` returned only `sunholo/auth` (SHA-256 key compare) and `registry_validator`, which aren't counter-based PRNGs. ADR 0001 rules out `std/rand` |
| M2.5 | none | none | `pkg search replay` returned no packages. The harness is Makefile + `cmp` + Python stdlib |
| M2.6a, M2.6b | none | none | Godot UI; no AILANG package applies. The map has no physics |

### Pre-planning findings (made while planning, 2026-10-01)

1. **The design doc's HB-n citations do not match canon.** Canon's IDs come
   from `../stapledons-design/physics/higgs-bubble.md`, at origin/main
   `e1b565e`, which the design doc cites as normative. The design doc uses an
   older, short numbering. For example, its "HB-6" (α Cen 1 g flip) is canon
   **HB-27…29**, and canon HB-6 is "interior gravity 1 g". The numbers
   themselves agree (checked: 0.99c drag 1.37e17 J = HB-53; cap load 2.25e9
   W/m² = HB-42; T_fwd 38.44 K / 3,853.7 K = HB-62/63). Only the IDs differ.
   **Package tests and sim tests cite the canon IDs in the table below.**
   M2.0 task 0 also corrects the design doc's citations, which is a
   docs-only edit.

   | Design doc cites | Quantity | Canon ID (`e1b565e`) |
   |---|---|---|
   | HB-1, HB-3 | α Cen 0.99c: γ, φ, Earth 4.414 yr, ship 0.6227 yr / 227.4 d | HB-16, HB-17, HB-20, HB-21, HB-22 |
   | HB-2, HB-5 | cap 0.999999c: γ 707.107, φ 7.2543, Earth 4.370 yr, ship 2.26 d | HB-18, HB-19, HB-25, HB-26 |
   | HB-4 | felt 1 g to 0.99c / 0.999999c: 2.56 / 7.03 ship-yr | HB-23, HB-24 |
   | HB-6 | α Cen 1 g flip: 3.582 ship-yr, 6.003 yr, 0.9517c | HB-27, HB-28, HB-29 |
   | HB-7 | example boost, 10 ship-min to 0.99c | HB-30 … HB-34 |
   | HB-8 | photon-drive energy per kg m_eff | HB-35 … HB-37 |
   | HB-9 | load scale | HB-38 … HB-43 |
   | HB-10 | kinetic flux | HB-44 … HB-46 |
   | HB-11 | drag force (sphere) | HB-47 … HB-50 |
   | HB-12 | ship-frame drag energy (full d) | HB-51 … HB-56 |
   | HB-13, HB-14 | proton energy, plume (M3/M4, not M2) | HB-57 … HB-60 |
   | HB-15 | glow design guide ε ≤ 3.6e-9 | HB-61 |
   | HB-16, HB-17 | forward CMB temperature / forward Doppler | HB-62, HB-63 |
   | HB-19 … HB-25 | tides, hover (M3) | HB-71 … HB-90 |

2. **ailang#1450 (strict VM rejects bitwise Int ops) is CLOSED upstream
   (2026-10-01 16:14Z), but the fix is not in v0.50.0.** Probed today:
   `n ^ 3` under `--bytecode --strict-bytecode` still fails on
   `runtime/bin/ailang` v0.50.0 *and* on the PATH dev build
   v0.50.0-6-g021c46907 ("`_bitwiseXor_Int` not yet wired (Phase 2E)").
   The interpreter gives 112650. M2.4 therefore plans the **LCG fallback**.
   SplitMix64 is used only if a pin bump (CI + runtime + lockfile together,
   its own queue item) lands a release containing the fix before M2.4 starts.
3. **AC18's grep would fail on today's code.** `sim/core.ail:48` has the
   comment "2 sinh(g T)/g". The design's markdown also escapes the
   alternation as `\|`, which BSD `grep -E` reads as a literal pipe. So copied
   verbatim, the command passes vacuously on macOS. This plan uses the
   unescaped command, and M2.2 rewords the comment (core.ail is rewritten
   there anyway). AC7's grep is unescaped the same way.
4. **Next free minor:** the registry shows `sunholo/relativity` latest
   v0.3.0. **M2.0 publishes 0.4.0** (Q1 answered: Mark, attended 2026-10-01: M2.0 takes 0.4.0; `teffFromBV` (M1.2d) and M3.1's geodesics take the next free minors (0.5.0/0.6.0, first to publish takes the lower)).
5. **M4's interface table** (`m4-first-journey.md` §Interfaces assumed)
   "adopts M2's names". Three of its asks are cheap here and avoid churn later:
   - a `news` PRNG stream (M2.4);
   - `make replay SESSION=…` (M2.5);
   - the map emitting `target_selected(star_id)` and accepting a preselected
     star (M2.6a).

   All three are in scope below.

## Execution order and pause points

```
M2.0 pkg ──publish(P1)──┐
M2.1a protocol ── M2.1b bridge v2 ─┐
                └── M2.2 world/ledger ── M2.3a planner/commit ── M2.6a map + plan panel ──⏸ R1 (Mark review)
                                                     └── M2.3b autopilot ── M2.6b commit ritual ──◆ R2 (M4 first review build unblocked)
                                         M2.2 ─────────────────────────────── M2.4 PRNG ── M2.5 replay + 10k
```

| # | Iteration | Milestone | LOC | Depends on | Pause after |
|---|---|---|---|---|---|
| 1 | 1 | M2.0 package: trip phases + bubble energetics, publish 0.4.0 | 450 | — | **P1** controller publish (standing grant, after independent PASS) |
| 2 | 2 | M2.1a protocol v2 + codecs (sim side, v1.1 still served) | 480 | — | — |
| 3 | 3 | M2.1b bridge v2, `main.gd`/capture migration, v1.1 removed | 370 | M2.1a | — |
| 4 | 4 | M2.2 world, params, clock, phases, ledger; game pins 0.4.0 | 330 | M2.1a, M2.0 published | — |
| 5 | 5 | M2.3a planner, readouts, journey state machine, commit rule | 360 | M2.2 | — |
| 6 | 6 | M2.6a galaxy map + plan panel + `--map-capture` | 430 | M2.3a, M2.1b | **⏸ R1 review checkpoint for Mark** |
| 7 | 7 | M2.3b autopilot, phase splitting, residuals, ledger at arrival | 250 | M2.3a | — |
| 8 | 8 | M2.6b commit ritual, 1.5 s hold, post-commit refusal, transit readout | 210 | M2.6a, M2.3b | **◆ R2** notify: M4 first review build unblocked |
| 9 | 9 | M2.4 PRNG named streams (SplitMix64; P4 re-probe passed on v0.51.0) + `draw` | 260 | M2.2 | — |
| 10 | 10 | M2.5 replay harness, goldens, 10k-tick parity | 280 | M2.3b, M2.4, M2.1b | **P5** golden review → landing |
| | +2–3 | contingency (evaluator FAIL / upstream park) | | | |
| | | **Total** | **3,420** | | |

**Why this order and not the design's `M2.0 ∥ M2.1 → … → (M2.4 ∥ M2.6) →
M2.5`.** The loop runs one item per iteration, so parallel arms become a
sequence. Mark's priority puts the map before the PRNG. M2.6 is split so that
the reviewable map, which needs only planner output (M2.3a), lands *before*
the autopilot (M2.3b). M2.4 depends only on M2.2. It could move earlier if the
loop is ever blocked waiting on a publish or a review, but it never moves
ahead of M2.6a.

**Pause points**
- **P0 (now):** this plan stops for Mark's approval. No execution, no handoff
  message, no commit.
- **P1, M2.0 publish (irreversible).** Covered by the **standing publish
  grant** (charter guardrails, 2026-09-27; ratified D-1). Run by the
  **controller**, not the executor. It runs only after all of these:
  1. the independent evaluator PASSes M2.0. Per the routing policy this is the
     strongest available evaluator, since M2.0 is physics code. It checks the
     package tests against the canon HB IDs.
  2. `ailang pkg quality .` exits with no gates;
  3. `CHANGELOG` and `[release] kind = "feature"` are in place;
  4. `publish --dry-run` passes.

  This is the sprint's physics-gate review. M2 adds **no SR/GR visual and no
  shader** (forward CMB disc is queue row 6a), so CLAUDE.md gate 2 (golden +
  human-reviewed render) does not apply; `make golden` and `make capture`
  must still pass (AC17).
- **⏸ R1, review checkpoint for Mark (after M2.6a).** This is the first point
  where a reviewable capture of the map with real plan numbers exists. The
  controller publishes three things:
  1. `renders/galaxy_map.png`, with α Cen selected at the 0.99c default;
  2. a panel dump at 0.9c, 0.99c and the cap: every label next to the sim's
     raw value, as `renders/galaxy_map_panel.json`;
  3. a private review page (claude.ai artifact, as in M1.0), plus a review
     build tag `v0.2.0-m2-map` with the macOS `.app` (standing grant covers
     review-build tags).

  The loop then **continues with M2.3b**, which is sim only and unaffected by
  UI feedback. Mark's tweaks go into the ledger or issue #1. Layout, labels
  and ordering go into M2.6b; scenario-parameter changes are data. **M2.6b
  waits for Mark's feedback; default if unanswered when M2.3b lands: build
  M2.6b as designed and fold later tweaks in as follow-ups.**
- **◆ R2, M4 hand-off (after M2.6b).** Map → plan → commit → transit now runs
  end to end in the sim with the D-12 ritual. That is everything M4's first
  review build needs from M2 (galaxy map → commit → transit; M4.0 + M4.2 add
  the blockout interior). The controller posts a capture and notifies; it
  isn't a stop.
- **P4, M2.4 algorithm choice (no Mark stop).** Verified 2026-10-01: AILANG `dev` at `7c640e83d` (contains the ailang#1450 fix `51b03ee73`), built locally, gives `^ & << >>` identical on the interpreter and `--strict-bytecode` (5/2/48/0 for n=6, k=3). CI pins releases only, so SplitMix64 needs the first release containing `51b03ee73` pinned (CI, runtime, lockfile together) before M2.4; otherwise the LCG. At M2.4 start, re-probe
  `n ^ 3` under `--strict-bytecode` on the pinned binary. If it passes, use
  SplitMix64 (`rng: "splitmix64-1"`). Otherwise use the LCG
  (`rng: "lcg64hi-1"`). Record which one in `m2-report.md`.
- **P5, golden review (M2.5).** Every committed golden is a reviewed diff from
  `make replay-record`, never regenerated inside `make test`. The evaluator
  checks each golden against an independent expectation: the arrival
  residuals, and the α Cen plan numbers from the design's check rows.

## Milestones

### M2.0: Trip phases and bubble energetics in `sunholo/relativity` 0.4.0 (package first)

**Goal:** one source of maths for the gameplay journey and every D-11 cost,
as additive package functions, tested against python references and canon HB
values, then published.
**Estimated:** 190 code + 260 tests = **450** · **Cap:** 650 · **Iteration:** 1 ·
**Depends on:** — · **Registry:** contribute `sunholo/relativity`

**Files (fresh clone `$PKG`):**
- modify `hyper.ail` (`acosh1p`), `kinematics.ail`
  (`rapidityOfOneMinusBeta`), `optics.ail` (`forwardDoppler`,
  `cmbForwardTemperature`);
- modify `journey.ail`:
  - add `TripPlan`, `planBurnCoastBurn`, `planFlipAndBurn`, `TripPhase`,
    `phaseAt`, `motionAt`;
  - reimplement `flipAndBurn`/`burnCoastBurn` as `planX(...).trip`, with
    signatures unchanged;
- create `medium.ail`:
  - constants `cSI`, `protonMassKg` (CODATA, m_p c² = 1.50328e-10 J),
    `lightYearM`, `cmbTemperatureK` = 2.725;
  - functions `photonDriveEnergy`, `mirrorDragForce`, `mirrorDragPower`,
    `cruiseDragEnergy`, `loadScale`, `kineticFlux`, `glowInwardFlux`,
    `tripEnergy`, `brakeHoldsAgainstDrag`;
- create `journey_plan_test.ail`, `medium_test.ail`; create
  `tools/journey_ref.py` (stdlib only; emits every check row);
- modify `_smoke.ail` (`journeyDigest(n)` for the strict-VM parity entry, the
  same pattern as `wdDigest`);
- modify `ailang.toml`:
  - version `0.4.0`, `[release] kind = "feature"`;
  - `medium` in `[exports]`;
  - extend `ai_summary` with "trip phase boundaries, boost–cruise–brake plans
    and Higgs-bubble energetics (photon drive, ISM drag, glow, forward CMB)";
- modify `CHANGELOG.md` (`## 0.4.0`), `AGENT.md` (when to use `plan*` vs the
  old totals; rapidity in, never β near c), `README.md`.
- this repo, docs only: correct the HB citations in
  `design_docs/planned/r1/m2-journey-core.md` to the canon IDs (finding 1).

**Tasks (test-first):**
0. Fix the design doc's HB citations (docs-only edit; table above).
1. Write `tools/journey_ref.py` first. It reproduces design rows 1–9 and the
   readout table to their printed 16–17 digits (design V9, V11). Commit its
   output as the expected values. Never derive expected values from the
   AILANG under test.
2. Write the tests (named `check…()` functions, CLAUDE.md test-block
   workaround):
   - every trip row (1–9) to 1e-12 relative;
   - the readout table to 1e-12 relative;
   - canon HB values to their printed digits (HB-16…HB-29 trip side; HB-35…37,
     HB-38…43, HB-44…46, HB-47…50, HB-51…56, HB-61, HB-62/63);
   - `motionAt(p, τtotal)` has φ = 0 and x = d to 1e-12;
   - continuity of t and x across each boundary;
   - `phaseAt` at each boundary (left-closed);
   - `fellBack` true on row 4 and row 9;
   - every `medium` function finite over a 10⁴-point φ sweep of [0, φcap];
   - existing 0.3.0 tests unchanged and green.
3. Implement until green on the interpreter **and** with `journeyDigest` under
   `--strict-bytecode`. Implementation rules:
   - rapidity forms only (γβ = sinh φ, γ−1 = 2 sinh²(φ/2), γ(1+β) = e^φ);
   - never form 1−β;
   - no nested cons patterns (ailang#1420);
   - test NaN first with `x == x` where inputs can be NaN (ailang#1419).
4. Gates, in order, run by the executor:
   1. `$A test --package .`
   2. `$A pkg quality .`
   3. strict-VM vs interpreter `cmp` on `journeyDigest`
   4. smoke "OK:"
   5. `publish --dry-run`

   **STOP.** The publish is the controller's (P1).

**Acceptance (design AC1, package half; AC18 package side):**
- **AC1 (package):** `cd $PKG && $A test --package . && $A pkg quality . && $A pkg info sunholo/relativity`
  (shows v0.4.0 after the controller's publish). The game-pin half of AC1 is
  in M2.2.
- strict-VM = interpreter bit for bit on `journeyDigest` (the AC-W5
  precedent): `$A run --quiet --bytecode --strict-bytecode --entry journeyDigest --args-json 400 _smoke.ail`
  vs the same without the two bytecode flags, compared with `cmp`.

**Mutations it must kill:**
- `planBurnCoastBurn` using (cosh φ − 1)/a instead of 2 sinh²(φ/2)/a: row 3
  digits;
- β instead of φ as cruise input: row 3;
- no fallback: rows 4 and 9;
- flat-mirror 2× drag: HB-47…50 and the readout table;
- dCoast vs d in `tripEnergy`: readout total;
- `phaseAt` right-closed: boundary checks;
- `rapidityOfOneMinusBeta` forming 1−e: row 3 at 1e-12;
- `acosh1p` as `acosh(1+u)`: row 4 short-trip digits.

**Risks:**
- Z3 `ensures` on functions that call list walkers get skipped (PUB016 info,
  as 0.3.0). Keep contracts off the plan functions, or prove them on small
  helpers.
- 1e-12 may be tighter than libm ulp on some forms. Measure first. If it is,
  widen per check to the measured worst case plus a 10× margin and record
  this in the notes; never across the board.

### M2.1a: Protocol v2 and codecs (sim side; v1.1 still served)

**Goal:** `sim/protocol.ail` with typed messages and inverse codec pairs,
round-trip-tested; `ship.ail` speaks v2 while still answering v1.1, so
`make test` (whose bridge and parity fixtures are v1.1) stays green until
M2.1b.
**Estimated:** 230 code + 250 tests = **480** · **Cap:** 650 · **Iteration:** 2 ·
**Depends on:** — · **Registry:** depend std/json

**Status (executed 2026-10-01, branch `sprint/m2.1a-protocol`; independent evaluation pending):**
- [x] Task 0: V5 re-run on v0.50.0 passes on the strict VM and the interpreter.
  std/json drops the sign of −0.0 and prints 1e308 as integer digits that
  decode saturates at 2^63−1, so `protocol.num` writes `-0.0` and exponent
  form (reported upstream via the controller)
- [x] Tasks 1–2: fixtures and tests first (red), then green
- [x] Task 3: codecs, `v: 2` envelope, `hello` with `rng: "none-0"`
- [x] Task 4: diag adapter onto `core.step`/`turn`; plan/commit/cancel/record/draw refused `unsupported`
- [x] AC8 · [x] AC10 (part, `protocolVm`) · [x] `make test` green with v1.1 unchanged (+ `parity-v2`)
- Deviation: the unsolicited v1.1 startup line stays until M2.1b deletes v1.1
  (the v1.1 bridge waits for it); a v2 session gets nothing before its `hello`

**Files:**
- create `sim/protocol.ail` (pure):
  - types `Input`, `Intent` (`plan`, `commit`, `cancel`, `thrust`,
    `heading`, `record`, `draw`), `StateMsg`, `Params`;
  - `decodeInput : string -> Result[Input, string]`, `encodeInput`,
    `encodeState`, `decodeState`, `encodeHello`;
- rewrite `sim/protocol_test.ail` (keep every existing reason-code assertion);
- modify `sim/ship.ail`:
  - I/O loop only: read → (v2: decode → step adapter → encode) | (no `"v"`:
    the existing v1.1 path) → print;
  - `hello` first; no state line before `hello`, fixing design Problem 1;
- modify `Makefile` `strict`: add a `protocolVm` entry (round-trips the
  fixture set on the strict VM and prints a digest; interpreter equal).

**Tasks (test-first):**
0. **Re-run design V5 on v0.50.0** (std/json shortest round-trip on the strict
   VM: encode 0.1 + 0.2 → `{"x":0.30000000000000004}` on both runtimes).
   Record it in the notes. If it fails, stop and re-plan (codec choice).
1. Fixtures first:
   - inputs and states with 0.1, 1−2⁻⁵², 5e-324, 1e308, −0.0, and the cap's
     φ 7.254328619262047;
   - integers up to 2^53−1;
   - every intent kind;
   - every malformed case: bad JSON, `bad_v`, `bad_tick`, bad `dtau` (< 0,
     > 1, NaN), unknown `k` → `bad_intent`, schema errors;
   - params out of range.
2. Tests: `decodeInput(encodeInput(x)) == x`,
   `decodeState(encodeState(s)) == s`, and reason codes stable. A malformed
   line leaves the tick unchanged. A well-formed but refused intent goes into
   `refused` and the tick proceeds.
3. Implement the codecs. Envelope `"v": 2` and `"type"`. Handshake `hello`
   → `proto {major: 2, minor: 0}`, `sim`, `relativity`, and
   `rng: "none-0"` until M2.4.
4. The step adapter maps diag `thrust`/`heading` onto today's `core.step`/
   `turn`. Until M2.2/M2.3a, `plan`/`commit`/`cancel` are refused
   `unsupported`. `record` is refused `unsupported` (reserved for 2.1).
   `draw` is refused `unsupported` until M2.4.

**Acceptance (design AC8, AC10 protocol part):**
- **AC8:** `cd sim && $A test --package .` (`protocol_test.ail`: all fixtures
  round-trip, including the float edge cases; reason codes stable)
- **AC10 (part):** `make strict AILANG=$A` (`protocolVm` strict VM = interpreter)
- `make test AILANG=$A` green (v1.1 bridge, parity and parity-offaxis still
  pass unchanged)

**Mutations it must kill:**
- float printed with `%g` or 15 digits: the 1−2⁻⁵² fixture;
- −0.0 normalised to 0.0: the −0.0 fixture;
- tick check `>=` instead of `== world + 1`: `bad_tick`;
- refused intent stalls the tick: the rejection-model test;
- state line before `hello`: the handshake test.

**Risks:**
- std/json may decode 5e-324 or −0.0 differently on VM vs interpreter. That
  would be an upstream report (ailang messages, gcp store) and a fixture
  marked known-divergent, never a silent drop.

### M2.1b: Bridge v2, `main.gd`/capture/golden migration, v1.1 removed

**Goal:** Godot speaks v2 only; the capture and golden paths run through a
diag session; v1.1 is removed and its kinematics are preserved by an
equivalence fixture.
**Estimated:** 220 code + 150 tests = **370** (+ fixtures) · **Cap:** 650 ·
**Iteration:** 3 · **Depends on:** M2.1a · **Registry:** none (GDScript)

**Status (executed 2026-10-01, branch `sprint/m2.1b-bridge`; independent evaluation pending):**
- [x] Bridge tests first (red against the v1.1 bridge), then `sim_bridge.gd` v2:
  `hello()`, `new_game()`, `send()`, integer-major check, mirrored `world`,
  `record_path` tee, `full_precision` writer with a `-0.0` repair
- [x] `main.gd` and capture on a diag session (`heading` + `thrust` intents,
  `--record=`); golden never used the sim, so nothing to migrate there
- [x] v1.1 deleted from `ship.ail`: no startup line, nothing before the first
  input (ship-level check in `make parity-v2`)
- [x] `parity` generator and `offaxis.ndjson` are v2 logs;
  `tests/fixtures/v11_offaxis.{arm64,x86_64}.golden` + `make offaxis-v11-equiv`
- [x] AC9 · [x] AC13 (interim) · [x] AC16 · [x] AC17 capture part: 13/13 PNGs
  byte-identical to main; `make golden` 0 failures
- [x] M2.1a follow-ups: every `inRange` bound pinned (23/23 mutants killed);
  reason-code and parameter-range tables in the design doc (ranges pending
  Mark's ratification); -0.0 and 1e308 in the echo
- Decision (executor): AC9's pos/cruise_phi echo goes through a diag-only
  `echo` intent (plan payload in, `echo` event out), so AC9 stays in M2.1b
- Known divergence: Godot's JSON reader returns 0.0 for \|x\| ≤ DBL_MIN
  (5e-324, DBL_MIN); asserted as known-divergent, no bit-string fallback
- Finding (affects M2.5): sim floats differ by 1 ulp between arm64 and x86_64
  (`std/math` exp/log). The v1.1 golden is kept per architecture (x86_64 one
  generated on CI), and the equivalence holds bit for bit on each

**Files:**
- modify `bridge/sim_bridge.gd`:
  - `hello()`, `new_game(seed, scenario, diag, params)`,
    `send(intents, dtau) -> bool`;
  - integer-major check (refuse major ≠ 2);
  - a mirrored `world` dictionary that applies change-sets;
  - `record_path` tee (every stdin line byte for byte);
  - `JSON.stringify(x, "", true, true)` (`full_precision`);
  - timeouts and cleanup unchanged;
- modify `main.gd`: diag session, `thrust`/`heading` intents, state from the
  mirrored world;
- modify `tests/test_sim_bridge.gd`:
  - v2 hello; refusal of major 1 and 3;
  - a float64 echo of `plan.target.pos` and `cruise_phi` for the M2.1a float
    fixtures, bit-exact. Until M2.3a, the echo goes through a diag-only
    `echo` test hook or `refused` payloads. **Executor decides**: if the echo
    needs the planner, AC9 moves to M2.3a and this milestone asserts the
    `thrust`/`heading` float echo only;
  - existing timeout/cleanup tests unchanged;
- modify `sim/ship.ail`: delete the v1.1 path;
- convert `tests/fixtures/offaxis.ndjson` and the `parity` generator to v2
  logs (Makefile `parity`, `parity-offaxis`);
- create `tests/fixtures/v11_offaxis.golden`: v1.1 output at `e9d35c5`
  (generated by checking out `sim/` at that commit into scratch; the
  command goes in the fixture header). Create a `make offaxis-v11-equiv`
  target: v2 off-axis log → `beta, gamma, tau, t, x, pos` equal
  bit-for-bit. It folds into `make replay` at M2.5.

**Tasks (test-first):** bridge tests first (red against the v1.1 bridge), then
the bridge, then `main.gd`, then delete v1.1, then the parity conversions.

**Acceptance (design AC9, AC13 interim, AC16, AC17 capture part):**
- **AC9:** `godot --headless --path . --script tests/test_sim_bridge.gd`
  (bit-exact float64 round trip; major ≠ 2 refused)
- **AC13 (interim):** `make offaxis-v11-equiv AILANG=$A` (becomes
  `make replay` case `offaxis_v11_equiv` in M2.5)
- **AC16:** `make test AILANG=$A`
- **AC17 (capture part):** `make capture AILANG=$A && test -s renders/contact_sheet.png`,
  plus `make golden AILANG=$A` (GPU window, Studio shell). The renders are
  opened and confirmed pixel-unchanged from main: same seed, same thrust
  script.

**Mutations it must kill:** major parsed as float ("2.10" < "2.9"); missing
`full_precision` (0.1 echo); change-set applied as replace instead of merge
(mirror test); tee drops or reorders a line (`cmp` of the tee vs the sent
lines).

**Risks:** M1 still uses this bridge. M1.6b (camera + golden) is the
remaining M1 item that touches `main.gd`. **Schedule rule:** M2.1b runs only
when no M1 sub-milestone has `bridge/` or `main.gd` open, and M1.6b then
builds on the v2 API. If Godot's float parsing loses bits, the design
fallback applies: `"0x…"` bit strings for `pos` and `cruise_phi` only, decided
by AC9's result.

### M2.2: World, scenario params, clock, phases, energy ledger; game pins 0.4.0

**Goal:** the pure `World` and `tick` skeleton that every later milestone
extends, with the closed mass budget pinned.
**Estimated:** 190 code + 140 tests = **330** · **Cap:** 650 · **Iteration:** 4 ·
**Depends on:** M2.1a, M2.0 **published and visible** · **Registry:** depend
`sunholo/relativity@0.4.0`

**Status (executed 2026-10-01, branch `sprint/m2.2-world`; independent evaluation 94/100 PASS, follow-ups applied after rebasing on M2.1b):**
- [x] Task 0: probe (`ShipPhase` + `Journey = Idle | Planned({…TripPlan…}) |
  Committed({…})` + `Rng` inside a `World` record, 4 transitions) gives
  identical output on `--strict-bytecode` and the interpreter on v0.50.0;
  no tagged-int fallback needed
- [x] Pin: `sunholo/relativity` 0.4.0 in `sim/ailang.toml`, relocked with
  `runtime/bin/ailang`; `make deps` clean. Bundled `runtime/cache` gained
  0.4.0 additively (full `make runtime` left to the controller: it `rm -rf`s
  the runtime M2.1b is using)
- [x] Tests first (red on missing `World`/`tick`), then green: `checkMassClosed`,
  `checkPhaseDerivedDiag`, `checkWorldPhases`, `checkLedgerDiag`,
  `checkScenarioMEff`, `checkRngZero`, `checkTickRefusals` (core_test, also
  strict `worldVm`); `checkParamRange`, `checkMEffTooSmall`,
  `checkClockFields`, `checkPhaseOnWire` (protocol_test, in `protocolVm`);
  `checkParamsEcho` kept. core_test imports `relativity/medium` (fails on 0.3.0)
- [x] 11/11 mutations killed (tolerance 0.5 ×2, no m_eff check, mass deducted
  ×2, boost/brake sign, phase not stored, year/age swapped ×2, range
  dropped, phase string)
- [x] AC1 (game) · [x] AC6 (part) · [x] AC10 (part, + `worldVm`) · [x] AC18 · [x] `make test`
- Deviations: `tick(world, {dtau, intents}) -> {world, refused, events}`;
  `protocol.serve` builds the `StateMsg` (change-sets need the codec).
  Domain types (`Intent`, `Target`, `Params`, `Refusal`, `Event`) moved
  from protocol.ail to core.ail. Ledger and phase are in the world; the
  `ledger` wire section waits for M2.3a/b. The ship `phase` wire string is
  now `at_rest|boosting|cruising|braking`. ship.ail unchanged (v2 already
  routes through `serve` → `core.tick`)
- [x] Rebased on M2.1b (#25): `PlanReq`, the diag `IEcho` hook and
  `Event.echo` moved into core.ail with the other domain types (`core.tick`
  emits the echo event); v2-only session kept. Evaluator follow-ups:
  `checkLedgerMEff` (m_eff 0.5; both surviving m_eff mutations now killed),
  `ailang#1466`/`#1467` annotated at the workarounds, duplicated `Ship.tick`
  dropped (`World.tick` is the only tick)

**Files:**
- modify `sim/ailang.toml` (`"sunholo/relativity" = "0.4.0"`) and
  `sim/ailang.lock`. Relock with `$A`; `make deps AILANG=$A` passes, ignoring
  `generated_at`. Re-stage `runtime/` (`make runtime`) so the bundled app
  picks up 0.4.0;
- modify `sim/core.ail`:
  - `World {tick, seed, params, ship, journey, ledger, rng, diag}`;
  - `Ship` + `phase: ShipPhase` (AtRest | Boosting | Cruising | Braking);
  - `Params` with the `"sol"` defaults: epoch 0, start_age 30, boost_g 7.5e5,
    m_eff_kg 1.0, ism_n_cm3 0.1, bubble_radius_m 100, glow_eps 1e-9,
    glow_f_in 0.5, cruise_min_beta 0.9, cap_one_minus_beta 1e-6;
  - `Ledger {mEffKg, availableKg = 20000, boostJ, dragJ}`;
  - `Rng` record with counters `{journey, crew, events, galaxy, ai, news}`
    all 0 (algorithm in M2.4);
  - `Journey = Idle` only for now;
  - `tick(world, input) -> (World, StateMsg)`;
  - the comment at line 48 reworded (finding 3);
- modify `sim/protocol.ail`: `new_game` → world construction, param
  validation (out of range → schema error), `m_eff_too_small` via
  `brakeHoldsAgainstDrag` at the cap; full first `state` echoes `params`;
  `clock {tau, t, year, age}`; `ship` section including `one_minus_beta` from
  the package's `oneMinusBeta(phi)`;
- modify `sim/ship.ail`: route through `core.tick`;
- create or extend `sim/core_test.ail`.

**Tasks (test-first):**
0. **Probe first:** an ADT with record payloads (`Journey = Idle |
   Planned({…}) | Committed({…})`) inside a `World` record. Run it on
   `--strict-bytecode` vs the interpreter, matching shape and field count.
   The custom-record VM bug ailang#1354 was fixed in v0.47.2; re-check on
   v0.50.0. If it diverges: shrink, report upstream, and fall back to tagged
   int + flat record (design-neutral).
1. Tests:
   - `checkMassClosed`: `available_kg` = 20000 after any tick sequence;
   - `checkParamsEcho`: full state echoes the effective set;
   - `checkParamRange`: each param out of range → schema error, tick
     unchanged;
   - `checkMEffTooSmall`: m_eff 0.03 refused, 0.033 accepted (V12: threshold
     0.0321);
   - `checkClockFields`: year = epoch + t, age = start_age + tau;
   - `checkPhaseDerivedDiag`: |φ| < 1e-9 → AtRest, the M1.6a follow-up
     tolerance pinned with a mutation at 0.5;
   - existing `scripted*` and off-axis tests unchanged.
2. A load-bearing pin: one test imports `pkg/sunholo/relativity/medium` (fails
   on 0.3.0).

**Acceptance (design AC1 game half, AC6 part, AC10 part, AC18):**
- **AC1 (game):** `grep relativity sim/ailang.toml && make deps AILANG=$A`
  (shows 0.4.0)
- **AC6 (part):** `cd sim && $A test --package .` (`checkMassClosed`)
- **AC10 (part):** `make strict AILANG=$A` (existing `scripted*` + `protocolVm`
  still equal on strict VM and interpreter)
- **AC18:** `! grep -rnE "acosh|sinh|cosh|exp\(|tanh|2\.0 \* phi" sim/core.ail sim/protocol.ail ui/ bridge/`
  (`ui/` may not exist yet; run as `grep -rnE … $(ls -d sim/core.ail sim/protocol.ail ui bridge 2>/dev/null)`)
- `make test AILANG=$A`

### M2.3a: Planner, readouts, journey state machine, commit rule

**Goal:** `plan` returns every panel number as a package output; commit is
irreversible by construction.
**Estimated:** 170 code + 190 tests = **360** · **Cap:** 650 · **Iteration:** 5 ·
**Depends on:** M2.2 · **Registry:** depend `sunholo/relativity@0.4.0`

**Status (executed 2026-10-01, branch `sprint/m2.3a-planner`; independent evaluation pending):**
- [x] Tests first (red on missing `Planned`/`LedgerView`), then green:
  `checkPlanCruise09/099/Cap`, `checkPlanAlphaCen`, `checkPlanGl559`,
  `checkPlanCoast100`, `checkPlanFallback` (rows 1–4, 6–9, 1e-9),
  `checkPlanReadouts` (readout table 1e-9; derived fields after a 1.5 yr rest
  with epoch 2100/start_age 41; m_eff 0.5; 1−β readout at cap 1e-17;
  committed view frozen), `checkCruiseRange`, `checkDiagOnly`,
  `checkCommittedRefusesAll`, `checkCommitTurns`, `checkCommitMoving`,
  `checkStalePlan`, `checkPlanIds`, `checkPlanIsPackage` (core_test; all in
  the new strict entry `planVm`); `checkJourneyOnWire`, `checkAlphaCenPanel`,
  `checkLedgerOnWire` (m_eff 0.5 on the wire) in protocol_test/`protocolVm`
- [x] α Cen 0.99c panel as the sim emits it: ship 0.6226958707592057 yr,
  Earth 4.414143655383168 yr, boost 1.7979782022600483 min, total
  6.1276428633128384e17 J = 6.817922175341585 kg, T_fwd 38.44085554458952 K
- [x] 27/27 applied mutations killed (Committed→Idle via cancel, committed
  arm bypassed, plan_id / position staleness ignored, readout 1−β, `>`→`>=`
  at the cap, `<`→`<=` at the floor, years_left without elapsed age, …)
- [x] AC2 · AC3 · AC4 · AC7 (+ grep) · AC18 · `make test` (strict: protocolVm,
  worldVm, planVm; parity, parity-offaxis, parity-v2, offaxis-v11-equiv)
- Deviations: `World` gains `lastPlanId`; `Plan {id, target, from, heading,
  flip, trip: TripPlan}`, `Committed`/`Arrived` carry `{plan, tau0, t0}`.
  `stale_plan` also covers a plan made from another position. A target at
  the ship's position and a non-positive `flip_g` are `out_of_range`.
  `cancel` with no plan is a no-op. A committed world refuses *every*
  intent kind (also `echo`/`draw`/`record`) `committed`. The planned panel is
  live ("if you commit now"), the committed one frozen at (τ0, t0).
  AILANG does not check match exhaustiveness at compile time (reported), so
  the one-arm-per-constructor rule is enforced by `checkCommittedRefusesAll`.
  New upstream: ailang#1473 (variable pattern evaluator-only on strict VM;
  `_ => j` workaround); #1467 also hits `let` bindings (`later` rename)

**Files:** `sim/core.ail` (`Journey = Idle | Planned | Committed | Arrived`,
plan/commit/cancel rules, plan readouts), `sim/protocol.ail` (`journey`
section with `plan {…}` exactly as design §M2.1 Change-sets), `sim/core_test.ail`.

**Tasks (test-first):**
1. Tests (named, from the design):
   - planner check rows: `checkPlanCruise09`, `checkPlanCruise099`,
     `checkPlanCruiseCap` (rows 1–3, 1e-9); `checkPlanAlphaCen`,
     `checkPlanGl559`, `checkPlanCoast100`, `checkPlanFallback` (diag
     `flip_g`, rows 6–9);
   - `checkPlanReadouts`: readout table rows, 1e-9 relative. Also the
     derived fields: `arrive_year = year + galaxyTime`, `age_on_arrival`,
     `years_left = 100 − (age − start_age) − shipTime`,
     `boost_minutes = tauBurn·525960`;
   - rules: `checkCruiseRange` (below atanh 0.9, or above
     `rapidityOfOneMinusBeta(1e-6)`, refused `out_of_range`); `checkDiagOnly`
     (`flip_g`/`thrust`/`heading` outside diag); `checkCommittedRefusesAll`
     (exhaustive match over the `Intent` constructors); `checkCommitMoving`
     (`moving`); `checkStalePlan` (`stale_plan`); plan ids monotonic from 1;
     replan replaces the plan.
2. Implement. `d` is float64 scalars from `target.pos − position(ship)`;
   `planBurnCoastBurn(d, boost_g·standardGravity(), cruise_phi)`; `commit`
   performs the at-rest `turn` to the plan heading. There is **no** arm from
   `Committed` to `Planned`/`Idle`.
3. Until M2.3b, `Committed` holds position (no autopilot yet). Tests that
   need arrival are M2.3b's.

**Acceptance (design AC2, AC3, AC4, AC7, AC18):**
- **AC2:** `cd sim && $A test --package .` (`checkPlanCruise09`, `checkPlanCruise099`,
  `checkPlanCruiseCap`, `checkPlanAlphaCen`, `checkPlanGl559`, `checkPlanCoast100`,
  `checkPlanFallback`)
- **AC3:** `cd sim && $A test --package .` (`checkPlanReadouts`)
- **AC4:** `cd sim && $A test --package .` (`checkCruiseRange`, `checkDiagOnly`)
- **AC7:** `cd sim && $A test --package .` (`checkCommittedRefusesAll`) and
  `! grep -nE "Committed.*=> *(Idle|Planned)" sim/core.ail`
- **AC18:** as M2.2
- `make test AILANG=$A`

**Mutations it must kill:**
- range bound `>` vs `>=` at the cap: `checkCruiseRange` at exactly φcap and
  just above;
- `years_left` off by the elapsed age: `checkPlanReadouts` after a non-zero
  rest period;
- a `cancel` arm accepted while committed: `checkCommittedRefusesAll`;
- `d` computed from float32-rounded positions: `checkPlanGl559`, which uses
  catalogue doubles 4.35667304258651.

### M2.6a: Galaxy map and plan panel (first reviewable UI) → ⏸ R1

**Goal:** pick a star, choose a cruise speed, and see the sim's plan. Every
number on screen is a sim field. The capture is what Mark reviews.
**Estimated:** 330 code + 100 tests = **430** · **Cap:** 650 · **Iteration:** 6 ·
**Depends on:** M2.3a, M2.1b · **Registry:** none

**Status (executed 2026-10-01, branch `sprint/m2.6a-map` on `sprint/m2.3a-planner`; independent evaluation pending):**
- [x] Tests first (`tests/test_galaxy_map.gd` red on missing `GalaxyMap`), then
  green: 57 checks against the real sim in a fake 800×600 `SubViewport`
- [x] α Cen A by catalogue **index 1** (Gl 559; B is index 2, same id); the
  `plan` carries the parsed-JSON doubles (pos.y −4.09 ≠ its float32), the sim
  echoes them bit for bit, distance = 4.35667304258651 (`checkPlanGl559`)
- [x] Slider default = `phi099` bits, echoed bit for bit, `cruise_beta` 0.99;
  min/max = `phi09`/`plPhiCap` bits, accepted at each end, refused
  `out_of_range` one ulp past (panel shows the refusal)
- [x] Every row: raw = sim field (bits), text = its formatting; clocks first,
  then arrival ("Earth +x yr"), age/years left (placeholder), energy, ISM,
  glow, drag, hold, forward CMB; the clock ticks at 1 ship-day per real second
  with the panel open (D-12); `target_selected(star_id)`; `preselect(index)`
- [x] AC15 (part) · AC17 map part (captures opened; copies in `docs/m2.6a/`)
  · AC18 incl. `ui/` · `make test` (new `ui` target) · `make capture`,
  `make golden` unchanged
- **Finding for ⏸ R1:** the catalogue's α Cen A is **4.35667 ly** from Sol
  (`stars.json` x, y, z are rounded to 0.01 ly), not the check row's 4.37 ly.
  So the real map at 0.99c reads **0.6208 ship-yr / 4.401 Earth-yr / 1.80
  min / 6.813 kg**. The 0.6227 / 4.414 / 1.80 / 6.818 digits are check row 2
  (4.37 ly on an axis). The test formats that row through the same panel and
  gets exactly those digits, and `--map-capture` dumps it next to the
  catalogue panels (`check_row_4_37ly`).
- Deviations: the `params` echo carries betas, not rapidities, so Godot
  computes the slider's two ends and its 0.99c default from it with the
  package's own expressions. The ulp probes prove they equal the sim's bounds.
  `preselect` does not emit `target_selected`. Extras: `--map=INDEX`, and
  the `make ui` and `make map-capture` targets

**Files:**
- create `ui/galaxy_map.tscn`, `ui/galaxy_map.gd`:
  - a MultiMesh point cloud from `data/starmap/stars.json` (float32 for
    drawing only);
  - an orbit camera;
  - screen-space nearest-star picking;
  - signal `target_selected(star_id)`;
  - `preselect(index)`;
  - a cruise slider uniform in φ from atanh 0.9 to the cap, default
    atanh 0.99. Its labels are the sim's `cruise_beta`/`cruise_gamma`; Godot
    computes no rapidity beyond the slider's linear φ mapping and the two
    endpoints, which are read from the sim's `params` echo;
  - a side panel:
    - both clocks first, then arrival ("Earth +4.414 yr"), age on arrival,
      years left;
    - then energy (boost/brake/drag/total J and kg), ISM load, glow, drag
      force, hold power, forward CMB K;
    - crew-age lines read "placeholder";
  - the fixed host clock rate at rest, with no pause while the panel is open
    (D-12);
- modify `main.gd`: `--map` start mode, `--map-capture=DIR` (writes
  `galaxy_map.png` and `galaxy_map_panel.json`: every label with its source
  sim field and raw value);
- create `tests/test_galaxy_map.gd` (headless, fake viewport).

**Tasks (test-first):** `test_galaxy_map.gd` first:
- select α Cen by **index**;
- the `plan` sent carries index, id, and float64 `x, y, z` from the parsed
  JSON dictionary (never from a `Vector3`), plus the slider's `cruise_phi`;
- the default slider sends φ = atanh 0.99 bit-exactly as the sim echoes it;
- every label equals the formatted sim value;
- `tick` advances while the panel is open;
- `target_selected` fires;
- `preselect` works.

**Acceptance (design AC15 part, AC17 map part, AC18):**
- **AC15 (part):** `godot --headless --path . --script tests/test_galaxy_map.gd`
  (labels = sim values; pos/φ echo exact; default 0.99c; never pauses)
- **AC17 (map part):** `godot --path . -- --map-capture=renders && test -s renders/galaxy_map.png`.
  **Opened and looked at** by the controller before ⏸ R1 is posted.
- **AC18:** as M2.2 (now including `ui/`)
- `make test AILANG=$A` (the map test is added to the `sim` target or a new
  `ui` target inside `make test`)

**⏸ R1 deliverables (controller, after the evaluator PASSes M2.6a):**
`renders/galaxy_map.png` (α Cen, 0.99c), three panel dumps (0.9c, 0.99c,
cap), a review page artifact, and review build `v0.2.0-m2-map`
(`make export-macos`, `make export-smoke`, tag; standing grant). The α Cen
0.99c panel must read 0.6227 ship-yr / 4.414 Earth-yr / 1.80 boost-min /
6.818 kg total. That is the check Mark sees.

### M2.3b: Autopilot, phase splitting, residuals, ledger at arrival

**Goal:** a committed journey flies itself through boost, cruise and brake,
lands within 1e-9 of the closed form, and closes the energy ledger.

**Status (executed 2026-10-01, branch `sprint/m2.3b-autopilot`; independent evaluation pending):**
- [x] Tests first, then green: `checkVoyageBoundaries` (0.99c, cap and diag
  1 g flip: every 0.01-yr tick end equals `motionAt(el)` to 1e-9, crossing τ
  = τ0 + boundary, ticks ending on each boundary), `checkArrivalResidual`
  (incl. `checkResidualsMeasured`), `checkLedgerAtArrival` (m_eff 3 kg),
  `checkWholeBoostTick`, `checkStartEventOnce`, `checkArrivedThenReplan`,
  `checkArrivalOnWire`; strict `journeyVm` and `voyageVm`
- [x] α Cen 0.99c replay residuals: x 1.8e-15 ly, t 8.0e-15 yr, φ 4.8e-11;
  ledger radiated 6.12764286331283712e17 J vs `tripEnergy` 6.1276428633128384e17
- [x] M2.3a follow-ups: plan from a moved ship (`checkPlanFromMovedShip`),
  `moving` at |φ| = 1e-9, NaN guard (`checkNaNCruise`), design §M2.3 wording
- [x] 17/18 mutations killed (1 equivalent on tested values)
- [x] AC5 · AC6 · AC10 (journeyVm) · AC14 (`make journey-replay`) · `make test`
- Deviations: `Event` gains `phase`/`arrived` options (wire adds
  `residual_phi`); `Commitment` gains `el`; `phaseAt` via `sim/tripphase.ail`
  (ailang#1478); commit always rebases the line of motion; the replay arrives
  on its 64th input (66 output lines). New upstream: ailang#1478
**Estimated:** 120 code + 130 tests = **250** (+ `tests/replays/alpha_cen.ndjson`) ·
**Cap:** 650 · **Iteration:** 7 · **Depends on:** M2.3a · **Registry:** depend
`sunholo/relativity@0.4.0`

**Files:**
- `sim/core.ail`:
  - split `dtau` at each boundary inside the tick (τburn, τburn+τcoast,
    τtotal) and apply `accelerate` with +a_B, 0 or −a_B to each piece;
  - a `phase` event per crossing;
  - at τtotal, snap φ to 0 and position to `target.pos`, and emit `arrived`
    with the residuals; leftover dtau is spent at rest;
  - ledger accumulation: `boostJ += photonDriveEnergy(mEff, |Δφ|)` in boost
    and brake; `dragJ += mirrorDragPower(n, φc, R)·dτ_s` in cruise;
- `sim/core.ail` `journeyVm` strict entry (scripted α Cen journey → digest);
- Makefile `strict`: add `journeyVm`;
- `tests/replays/alpha_cen.ndjson`: hello, new_game, plan, commit, about 70
  inputs at dtau 0.01, quit.

**Tests:**
- `checkVoyageBoundaries`: a 0.01-yr stepped α Cen voyage at 0.99c and at the
  cap matches `motionAt` at each boundary to 1e-9;
- `checkArrivalResidual`: < 1e-9·max(1, d);
- `checkLedgerAtArrival`: equals `tripEnergy(...).total` to 1e-9 relative;
- `checkMassClosed` still holds;
- a tick that holds the whole boost emits two `phase` events with exact τ;
- `Committed → Arrived` only via the sim.

**Acceptance (design AC5, AC6, AC10 journey part, AC14):**
- **AC5:** `cd sim && $A test --package .` (`checkVoyageBoundaries`, `checkArrivalResidual`)
- **AC6:** `cd sim && $A test --package .` (`checkLedgerAtArrival`, `checkMassClosed`)
- **AC10 (part):** `make strict AILANG=$A` (`journeyVm`)
- **AC14:** `$A run --quiet --package-dir sim --caps IO --entry main sim/ship.ail < tests/replays/alpha_cen.ndjson | tail -1 | grep '"arrived"'`
- `make test AILANG=$A`

**Mutations it must kill:** no tick splitting (boundary residual ~ a_B·dtau);
snap without residual check; drag accumulated during boost (ledger ≠ total by
the boost drag work); phase event τ taken at the tick end instead of the
boundary.

### M2.6b: Commit ritual, post-commit refusal, transit readout → ◆ R2

**Goal:** the D-12 commit dialog and the visible, sim-side refusal. After this,
map → commit → transit runs end to end (M4's first review build input).
**Estimated:** 130 code + 80 tests = **210** · **Cap:** 650 · **Iteration:** 8 ·
**Depends on:** M2.6a, M2.3b · **Registry:** none

**Files:** `ui/galaxy_map.gd`, `ui/commit_dialog.tscn` (or inside the map
scene), `tests/test_galaxy_map.gd`, plus Mark's ⏸ R1 tweaks if any arrived.

**Tasks (test-first):**
- the commit dialog shows both clocks and the years left at home, with a
  1.5 s hold; it does not send before 1.5 s of hold (fake clock), and sends
  `commit {plan_id}` after;
- post-commit, the Cancel button stays enabled and pressing it shows the
  sim's `refused: committed`, with no journey change;
- the transit readout shows `phase`, the two clocks advancing and progress;
- the map capture can be taken mid-transit (`--map-capture=renders
  --map-commit`).

**Acceptance (design AC15 complete, AC17 map part re-run):**
- **AC15:** `godot --headless --path . --script tests/test_galaxy_map.gd`
  (adds: 1.5 s hold; post-commit Cancel → `refused: committed`, journey
  unchanged)
- **AC17:** `make capture AILANG=$A && test -s renders/contact_sheet.png && godot --path . -- --map-capture=renders && test -s renders/galaxy_map.png`
  (both opened and looked at)
- `make test AILANG=$A`

**◆ R2:** controller posts a mid-transit capture and notifies Mark and the M4
track that M4.0/M4.3a can bind to M2's names (`m4-first-journey.md`
§Interfaces assumed → "adopt M2's").

### M2.4: Pure PRNG with named streams

**Goal:** counter-based, strict-VM-clean randomness with independent named
streams, reproducible from Python.

**Status (executed 2026-10-02, branch `sprint/m2.4-prng`; independent evaluation pending):**
- [x] P4 re-probe on `runtime/bin/ailang` v0.51.0 (b99dd25): `^ & << >>`
  give 5/2/48/0 for n=6 on the interpreter *and* `--strict-bytecode`
  (ailang#1450 fixed in the pin). Int is 64-bit two's complement; `+ *`
  wrap mod 2^64 and `n << 62`, `n << 64` (= 0) agree on both runtimes;
  `>>` is **arithmetic** (−96 >> 2 = −24), so the logical shift is
  emulated: `shr(x, k) = (x >> k) & ((1 << (64 − k)) − 1)`. Division
  truncates. **Algorithm: SplitMix64, `rng: "splitmix64-1"`.**
- [x] `sim/rng.ail` (pure): stream s of seed `seed` is SplitMix64 seeded
  with `mix64(mix64(seed) ^ id(s))`; value n = `mix64(key + (n+1)·γ)`.
  Fixed ids journey 1 … news 6; `Rng` fixed record (moved from core);
  `draw(seed, rng, stream)` returns the value and the advanced record.
- [x] Diag `draw {stream}`: `draw` event `{stream, n, value}` (value = top 53
  bits, exact JSON integer), `rng` change-set (counters; in every full
  state, else only when changed); outside diag `diag_only`; unknown stream
  `bad_intent`; committed refuses `committed` (counters unchanged)
- [x] `tools/rng_ref.py --check` (`make rng-ref`, in `make test`): SplitMix64
  published vectors (seed 0 → 0xe220a8397b1dcdaf…, seed 1234567), chi-square
  on 10⁵ draws per stream (top and low byte, 255 dof, all p > 0.02), and the
  first 1,000 values of all 6 streams for seeds 0, 7, 2⁵³−1 from the strict
  VM *and* the interpreter, bit for bit (36,000 values)
- [x] `rngVm` in `make strict`: vectors + independence, then a digest
  (h = mix64(h ^ v)) over 10,000 draws per stream for seeds 7 and 2⁵³−1;
  strict VM = interpreter = `rng_ref.py --digest` (seed 7:
  −9169153163131597079). Integers only: no float enters any value or digest
- [x] Mutations 12/13 killed: wrong constant (mulA, γ), arithmetic shift,
  counters shared (read, advance), counter not advanced, stream id
  ignored, seed ignored, signed high bits, n off by one, counter not
  persisted in core, draw outside diag. Survivor `rng: a.rng` dropped in
  the committed branch is equivalent (draws are refused while committed)
- [x] AC10 (rngVm) · AC11 · `make test`
- Deviations: `IDraw` carries a typed `Stream` (unknown names are
  malformed at decode, not refused); `Event` gains `drew`; `StateMsg` gains
  `rng`; hello `rng` is `splitmix64-1` (tests/test_sim_bridge.gd updated);
  the 10k digest folds in blocks of 100 (the interpreter has no tail calls,
  default depth 10,000). `m2-report.md` does not exist yet; the P4 choice is
  recorded here and in the sprint JSON for it. New upstream: ailang#1481
  (hex literals > 2⁶³−1, no logical shift), DX message on the compile-cache
  `ARTIFACT_TOO_LARGE` for `protocol_test`
**Estimated:** 110 code + 150 tests = **260** · **Cap:** 650 · **Iteration:** 9 ·
**Depends on:** M2.2 · **Registry:** none

**Files:**
- `sim/rng.ail` (or inside `core.ail`): `mix(seed, streamId, counter)`.
  Streams `journey, crew, events, galaxy, ai, news` (`news` is M4's ask;
  adding a stream never shifts the others);
- `draw {stream}` intent (diag only; the value goes in `events`);
- `rng` in `hello` names the algorithm; `rng {streams}` change-set;
- `tools/rng_ref.py` (stdlib; `--check` reproduces the first 1,000 values of
  each stream bit for bit and runs chi-square on 10⁵ draws per stream,
  p > 0.001);
- `rngVm` strict entry; Makefile `strict` gains it.

**Algorithm (P4):** re-probe bitwise ops on the pinned binary first (finding 2).
- **Default, LCG fallback:** a 64-bit LCG (`state·6364136223846793005 + inc`,
  wrapping) from the counter-derived state, high 32 bits by division. It uses
  only `*`, `+`, `/`, `%` and comparisons, all strict-clean on v0.50.0 (V3).
  `rng: "lcg64hi-1"`. Test the wrap-around explicitly on both runtimes.
- **SplitMix64 only if** the pin has moved to a release with the ailang#1450
  fix. Check against its test vector (seed 0 → `0xe220a8397b1dcdaf`, V4);
  `rng: "splitmix64-1"`.

**Acceptance (design AC10 rng part, AC11):**
- **AC11:** `python3 tools/rng_ref.py --check` and `cd sim && $A test --package .`
  (`checkRngVectors`, `checkStreamsIndependent`)
- **AC10 (part):** `make strict AILANG=$A` (`rngVm`)
- `make test AILANG=$A`

**Mutations it must kill:** a stream id ignored (independence test); the
counter not advanced on `draw` (vectors); signed vs unsigned high bits
(vectors past value 2³¹); the seed ignored (two seeds differ).

### M2.5: Replay harness and 10k-tick parity

**Goal:** recorded logs re-run on the VM and the interpreter and diff
byte-for-byte against committed goldens, including a 10k-tick session that
exercises every intent.
**Estimated:** 80 code + 200 tools/tests = **280** (+ goldens) · **Cap:** 650 ·
**Iteration:** 10 · **Depends on:** M2.3b, M2.4, M2.1b · **Registry:** none

**Files:**
- `tests/replays/*.ndjson` with `*.state.ndjson` goldens. These include
  `alpha_cen`, `offaxis_v11_equiv` and a Godot-recorded log from `record_path`;
- `tools/gen_session.py` (deterministic `session10k.ndjson`):
  - a plan, a replan, a commit;
  - a full α Cen voyage at 0.99c, with cancel, thrust and replan attempts in
    transit;
  - arrival; a cap-speed voyage; a 100-ly voyage in larger ticks;
  - a diag 1 g flip voyage;
  - out-of-range φ;
  - `draw` on every stream;
  - each malformed kind once.

  Only `session10k.state.sha256` is committed;
- Makefile:
  - `replay` (per log: `--bytecode` vs interpreter `cmp`, then `cmp` or
    `shasum -c` against the golden; prints `$A --version`; accepts
    `SESSION=…` for M4);
  - `replay-record LOG=…` (never in `make test`);
  - `make test` gains `replay`; `parity`/`parity-offaxis` point at the
    harness; `offaxis-v11-equiv` becomes a replay case;
- CI step; measure the 10k interpreter time first. If it is over 60 s: 10k on
  `main` only, a 2k case on PRs, both still `cmp`-gated (design risk row);
- `design_docs/implemented/r1/m2-report.md`: 10k timings, residuals, the PRNG
  algorithm used, upstream reports.

**Acceptance (design AC12, AC13, AC16):**
- **AC12:** `make replay AILANG=$A`
- **AC13:** `make replay AILANG=$A` (case `offaxis_v11_equiv`)
- **AC16:** `make test AILANG=$A`, locally and in CI

**Landing (after M2.5 PASSes):** move the design doc and this plan to
`design_docs/implemented/r1/`; update the design repo's roadmap M2 status and
add the `journey-system.md` superseded-maths note; add a changelog entry.

## Acceptance criteria → milestone map

| AC | Milestone(s) | Command |
|---|---|---|
| AC1 | M2.0 (package), M2.2 (pin) | `cd $PKG && $A test --package . && $A pkg quality . && $A pkg info sunholo/relativity`; `grep relativity sim/ailang.toml && make deps AILANG=$A` |
| AC2 | M2.3a | `cd sim && $A test --package .` (`checkPlanCruise09`, `checkPlanCruise099`, `checkPlanCruiseCap`, `checkPlanAlphaCen`, `checkPlanGl559`, `checkPlanCoast100`, `checkPlanFallback`) |
| AC3 | M2.3a | `cd sim && $A test --package .` (`checkPlanReadouts`) |
| AC4 | M2.3a | `cd sim && $A test --package .` (`checkCruiseRange`, `checkDiagOnly`) |
| AC5 | M2.3b | `cd sim && $A test --package .` (`checkVoyageBoundaries`, `checkArrivalResidual`) |
| AC6 | M2.2 (mass), M2.3b (ledger) | `cd sim && $A test --package .` (`checkLedgerAtArrival`, `checkMassClosed`) |
| AC7 | M2.3a | `cd sim && $A test --package .` (`checkCommittedRefusesAll`) and `! grep -nE "Committed.*=> *(Idle\|Planned)" sim/core.ail` (unescaped: `(Idle|Planned)`) |
| AC8 | M2.1a | `cd sim && $A test --package .` (`protocol_test.ail`) |
| AC9 | M2.1b (or M2.3a, see M2.1b) | `godot --headless --path . --script tests/test_sim_bridge.gd` |
| AC10 | M2.1a, M2.3b, M2.4 | `make strict AILANG=$A` (`protocolVm`, `journeyVm`, `rngVm`, existing `scripted*`) |
| AC11 | M2.4 | `python3 tools/rng_ref.py --check` and `cd sim && $A test --package .` (`checkRngVectors`, `checkStreamsIndependent`) |
| AC12 | M2.5 | `make replay AILANG=$A` |
| AC13 | M2.1b (interim), M2.5 | `make replay AILANG=$A` (case `offaxis_v11_equiv`) |
| AC14 | M2.3b | `$A run --quiet --package-dir sim --caps IO --entry main sim/ship.ail < tests/replays/alpha_cen.ndjson \| tail -1 \| grep '"arrived"'` |
| AC15 | M2.6a (part), M2.6b | `godot --headless --path . --script tests/test_galaxy_map.gd` |
| AC16 | every milestone; final at M2.5 | `make test AILANG=$A` |
| AC17 | M2.1b (capture), M2.6a/b (map) | `make capture && test -s renders/contact_sheet.png && godot --path . -- --map-capture=renders && test -s renders/galaxy_map.png` |
| AC18 | M2.2 onward | `! grep -rnE "acosh\|sinh\|cosh\|exp\(\|tanh\|2\.0 \* phi" sim/core.ail sim/protocol.ail ui/ bridge/` (unescaped alternation; see finding 3) |

## Success metrics

- Every AC above green, with the named command, on `$A` v0.50.0 locally
  and in CI.
- Each milestone's independent evaluation ≥ 70/100 (generator ≠ judge;
  physics milestones M2.0, M2.3a, M2.3b by the strongest available evaluator).
- `make strict` covers `protocolVm`, `journeyVm`, `rngVm`; `make replay` covers
  the 10k session; VM = interpreter byte-identical throughout.
- No trip or bubble maths outside the package (AC18), and no `1.0 - beta`
  anywhere in `sim/`, `ui/` or `bridge/`.
- `renders/galaxy_map.png` and the contact sheet were opened and looked at.
- Upstream: the ailang#1450 status recorded at M2.4. Any new VM/interpreter
  divergence goes as `ailang messages send user … --from stapledons_godot`
  with `AILANG_STORAGE_MESSAGING=gcp`, `AILANG_MESSAGES_PROJECT=ailang-multivac`.

## Risks

| Risk | Milestone | Mitigation |
|---|---|---|
| Bridge migration breaks M1's capture/golden while M1.6b is pending | M2.1b | Schedule rule (no M1 item has `bridge/`/`main.gd` open); same-PR `main.gd` migration; AC17 + `make golden` before merge; M1.6b rebuilds on v2 |
| Godot float JSON loses bits | M2.1b | `full_precision`; AC9 bit-exact echo with edge values; `"0x…"` fallback for `pos` and `cruise_phi` only |
| ADT-with-record payloads in `World` diverge on the strict VM | M2.2 | Probe is task 0; report upstream; tagged-int fallback |
| std/json edge floats (5e-324, −0.0) differ VM vs interpreter | M2.1a | V5 re-run first; fixture-level upstream report |
| ailang#1450 fix not released before M2.4 | M2.4 | LCG fallback is the default; algorithm id in `hello`; a later switch is a golden regen |
| HB ID drift between canon and the design doc | M2.0 | Canon IDs (`e1b565e`) in tests; design doc corrected in M2.0 task 0 |
| 1e-12 package tolerance tighter than libm on some forms | M2.0 | Measure; widen per check only to measured worst × 10, recorded |
| 10k-tick interpreter run too slow for PR CI | M2.5 | Measure first; 10k on main, 2k on PRs, both `cmp`-gated |
| Mark's ⏸ R1 feedback arrives after M2.6b started | M2.6b | Tweaks land as follow-ups (data or small UI edits); scenario params need no code |
| PATH `ailang` (v0.50.0-6 dev build) differs from the pin and rewrites the lock | all | Every gate passes `AILANG=$A`; `make replay` prints the version |
| Version slot collision with M3.1 / M1.2d | M2.0 | M2.0 takes 0.4.0 (Q1); M3.1 and M1.2d share 0.5.0/0.6.0 |

## Questions for Mark

1. **ANSWERED — Package version for M2.0: 0.4.0** (Mark, attended 2026-10-01: M2.0 takes 0.4.0; `teffFromBV` (M1.2d) and M3.1's geodesics take the next free minors (0.5.0/0.6.0, first to publish takes the lower)).
2. **ANSWERED (all four) — ⏸ R1 format.** Is a capture + panel dump + review page + a tagged macOS
   review build (`v0.2.0-m2-map`) the right shape for the map review, or do you
   want only the images until the commit → transit flow exists (◆ R2)?
   **Default: all four at ⏸ R1.**
3. **Per-milestone cap 650** (instead of M1.2b's 250), justified by the
   pre-measured maths and the recent 130–670 LOC landings. **Default: 650.**

No design question is open. D-11, D-12, D-14 and D-15 cover the physics, the
calendar, the slice default and the bubble defaults. The planner wrote no git
objects. The executor and the evaluator stay separate.
