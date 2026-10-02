# M2 journey core: report

**Status:** Implemented (2026-10-02). Sprint `R1-M2-JOURNEY`, 10 milestones,
all independently evaluated (89–96/100, generator ≠ judge). Bar clause 2 of
the R1 charter is **met** (below). Design:
[m2-journey-core.md](m2-journey-core.md). Plan:
[m2-journey-core-sprint.md](m2-journey-core-sprint.md). Progress file:
`.ailang/state/sprints/sprint_R1-M2-JOURNEY.json`. Evaluations:
`.ailang/state/evaluations/eval_R1-M2-JOURNEY*`.

This report was drafted at M2.5 as `planned/r1/m2-report-draft.md` and
completed at landing.

## Toolchain

| | |
|---|---|
| AILANG | v0.51.0 (b99dd25), `runtime/bin/ailang`, CI `linux.x64` release. M2.0–M2.3 ran on v0.50.0 (6abe1a5); pins: v0.50.0 (#18), v0.51.0 (#30) |
| `sunholo/relativity` | 0.4.0 (ailang-packages PR #84, 1abde63), published at M2.0 under the standing grant |
| Godot | 4.7.2-stable |
| Machines | dev: darwin arm64 (16 cores). CI: GitHub `ubuntu-latest` x86_64 (2 cores) |

## Milestones

In execution order. The order was built for M4's first review build: map
before PRNG and replay (sprint plan §Execution order).

| Milestone | PR | Result | Evaluation (judge) |
|---|---|---|---|
| M2.0 package trip + energetics | #22 (docs), #24 (record); ailang-packages #84 | relativity 0.4.0: `TripPlan`, `planBurnCoastBurn`, `planFlipAndBurn`, `phaseAt`, `motionAt`, `acosh1p`, `rapidityOfOneMinusBeta`, `medium`, `cmbForwardTemperature`; 101/101 tests | 96/100 (Fable 5.1; publish GO) |
| M2.1a protocol codecs | #23 | protocol v2 codecs in `sim/protocol.ail`; float-text repairs for −0.0 and large/small floats | 92/100 (Sonnet 5.5) |
| M2.1b bridge v2 | #25 | `SimBridge` v2, `record_path` tee, v1.1 removed; AC9 bit-exact float64 echo | 93/100 (Sonnet 5.5) |
| M2.2 world + ledger | #26 | `World`, params, clock, phases, closed mass budget; game pins relativity 0.4.0 | 94/100 (Fable 5.1) |
| M2.3a planner + commit | #27 | planner = closed form to 1e-9; commit irreversible, one arm per constructor, no wildcard (AC7) | 95/100 (Fable 5.1) |
| M2.6a map + plan panel | #28 | galaxy map, cruise slider, panel shows sim numbers only; **⏸ R1** review build `v0.2.0-m2-map` | 89/100 (independent); R1 accepted by Mark (D-17) |
| M2.3b autopilot | #29 | stepped voyage = `motionAt` at every boundary; residuals < 1e-9·max(1, d); ledger closed | 96/100 (Fable 5.1) |
| M2.4 PRNG | #31 | SplitMix64 named streams (P4, below) | 94/100 (Sonnet 5.5) |
| M2.6b commit ritual | #33 | commit dialog (both clocks, years left, 1.5 s hold), transit readout, refusal display, star names (D-17); **R2** M4 review build unblocked | 93/100 (Sonnet 5.5) |
| M2.5 replay + 10k parity | #35 | `make replay`, per-arch goldens, 10k-tick session; **P5** goldens approved by Mark 2026-10-02 | 93/100 (independent) |

Also landed during the sprint: AILANG pins v0.50.0 (#18) and v0.51.0 (#30);
the attended D-17 ledger record (#32); the Python policy and
`make python-guard` (#34, from a parallel attended session); the catalogue
galactic-longitude fix (#37, below); the no-broad-find hook (#38).

### Sprint timeline

| | |
|---|---|
| Sprint created | 2026-10-01 18:40 UTC |
| First M2 PR merged | #22, 2026-10-01 18:54 UTC |
| R1 review build | `v0.2.0-m2-map`, 2026-10-01 22:42 UTC (iteration 6 of 10) |
| R1 accepted (D-17) | 2026-10-02 (attended) |
| Last M2 PR merged | #35, 2026-10-02 08:07 UTC |
| Elapsed | ~13.5 h wall clock, against the plan's ~12–13 iterations / ~5 working days |
| Code delta | ~5,000 lines added in `sim/ ui/ bridge/ tools/ tests/ Makefile .github` (excluding replay goldens and fixtures; includes the small #34/#37 parts), against the design's ~3,400 estimate |

The milestone `started`/`completed` stamps in the sprint JSON are
executor-written and not all consistent with merge times (M2.4 is stamped
completed 11:30 UTC; PR #31 merged 06:18 UTC), so this table uses PR merge
times from GitHub.

## Bar clause 2: met

Charter clause 2 (`design_docs/stapledon-mission.md`, "The bar"):

| Clause part | Evidence |
|---|---|
| Versioned protocol | Protocol v2: `hello` → `proto {major: 2, minor: 0}` plus `sim`, `relativity`, `rng` versions; hand-written codecs in `sim/protocol.ail` with round-trip tests (M2.1a, eval 92); bridge v2 with bit-exact float64 echo (M2.1b AC9, eval 93) |
| Planner matches the rocket equations to 1e-9 | `make sim strict`: planner = `sunholo/relativity` closed form to 1e-9, HB-20…22 and HB-27…29 (M2.3a, eval 95; the judge's independent python reproduced the α Cen 0.99c panel bit for bit). Stepped voyages match `motionAt` at every boundary (M2.3b, eval 96); arrival residuals in the table below |
| Commits irreversible, enforced by the sim | The commit rule lives in `sim/core.ail`: every intent against a committed journey is refused `committed` until arrival, with no path back to planned/idle (M2.3a AC7, code audit and wire session by the judge). The UI cannot bypass it: `tests/test_galaxy_map.gd` shows Cancel after commit sends `cancel` and the sim refuses it (M2.6b AC15). The 10k session holds 15 + 8 in-transit refusals |
| 10k-tick replay byte-identical on VM and interpreter | `make replay`: `session10k` (10,000 accepted ticks) VM output `cmp`-identical to the interpreter and equal to the committed digest, on darwin arm64 locally and on x86_64 in CI (main runs 10k, PRs 2k). Goldens are **per architecture** because std/math `exp`/`log` differ by 1 ulp between arm64 and x86_64 (ailang#1465); P5 approved by Mark 2026-10-02 |

## P4: the PRNG algorithm

The plan defaulted to an LCG fallback because bitwise Int operators were not
wired on the strict VM in v0.50.0 (ailang#1450). The pin moved to v0.51.0
before M2.4, and the P4 re-probe passed: `^ & << >>` give 5/2/48/0 for n = 6
on both the interpreter and `--strict-bytecode`. Int is 64-bit two's
complement, `+` and `*` wrap mod 2^64 on both runtimes, and `>>` is
arithmetic, so the logical shift is emulated as
`shr(x, k) = (x >> k) & ((1 << (64 − k)) − 1)`.

**Decision: SplitMix64, `rng: "splitmix64-1"`.** Stream s of seed `seed` has
key `mix64(mix64(seed) ^ id(s))`; its n-th value is `mix64(key + (n+1)·γ)`.
The stream ids are fixed: journey 1, crew 2, events 3, galaxy 4, ai 5, news 6.
The checks are the published vectors, chi-square on 10^5 draws per stream
(all p > 0.02), and 36,000 values matched bit for bit against
`tools/rng_ref.py` on the strict VM and the interpreter. Hex literals above
2^63 − 1 do not parse (ailang#1481), so the constants are written as signed
decimals.

## Replay harness (M2.5)

`make replay` runs `tools/replay.py`. For every `tests/replays/*.ndjson` log,
and for the session that `tools/gen_session.py` generates, it does four
things:
- runs the log on the bytecode VM and on the interpreter;
- requires the two stdouts to be byte-identical;
- requires one reply per input line up to the first `quit`;
- requires the output to match this architecture's golden: byte for byte
  (`NAME.state.ARCH.ndjson`), or by sha256 (`NAME.state.ARCH.sha256`) when
  the output is the generated session or over 256 KB.

It prints the AILANG version. `make replay SESSION=path` replays one log
against the golden beside it (this is the path M4 uses).
`make replay-record LOG=path|case|session10k|all` regenerates goldens. It
refuses if VM ≠ interpreter, and the result is a reviewed diff (pause point
P5). It is never part of `make test`.

| Case | Input | Output | Golden |
|---|---|---|---|
| `alpha_cen` | 67 lines: α Cen at 0.99c, arrives on the last input | 66 lines, 37 KB | full, per arch (arm64 = x86_64) |
| `offaxis_v11_equiv` | 18 lines: v1.1 off-axis log (turns, burns, refusals, malformed) | 17 lines | full, per arch (differs in one `beta`); also == v1.1 kinematics (AC13) |
| `diag_thrust600` | 603 lines: the old `make parity` diag 1 g session | 602 lines, 324 KB | sha256, per arch (differs) |
| `godot_map_voyage` | 74 lines recorded by Godot through the galaxy map and the `record_path` tee (`tools/record_godot_session.gd`) | 73 lines, 48 KB | full, per arch (arm64 = x86_64) |
| `session10k` | 10,017 lines from `gen_session.py` (10,000 accepted ticks) | 10,016 lines, 4.16 MB | sha256, per arch (differs) |
| `session2k` | the same session cut to 2,000 ticks (CI on PRs) | 2,016 lines, 0.88 MB | sha256, per arch (differs) |

`make parity`, `parity-offaxis`, `offaxis-v11-equiv` and `journey-replay` are
now thin aliases for `replay --case …`. `make test` runs `replay` in their
place. `parity-v2` (silent-startup checks) is unchanged.

### What the 10k session covers

- **Session-level malformed kinds, once each:** `no_hello` (input and new_game
  before hello), `bad_json`, `bad_v`, `bad_cmd`, `no_game`, `bad_game`,
  `bad_params`, `m_eff_too_small`.
- **Malformed inputs mid-voyage:** `bad_tick`, `bad_step`, `bad_intent`,
  `bad_heading`. None of them advances the tick.
- **Game A (play mode):**
  - a plan, a replan (id 2), and a commit of the stale id 1 (`stale_plan`)
    with id 2 in the same line;
  - α Cen at 0.99c with 15 `committed` refusals in transit (cancel, thrust,
    replan, draw, heading, commit, echo); arrival at tick 65;
  - out-of-range φ on both sides (1e-9 past each bound), plus `diag_only` for
    thrust, draw and `flip_g`; both bounds accepted;
  - a voyage at the cap speed to Sirius;
  - a voyage in 0.1-yr ticks to a target 100 ly from Sol (109 ly from
    Sirius), 15.6 ship-yr and 110.5 Earth-yr.
- **Game B (diag):**
  - draws on all six streams, forward and reversed;
  - commit while moving (`moving`);
  - a 1 g flip-and-burn voyage to α Cen: 3.58 ship-yr, 6.00 Earth-yr,
    0.9517c peak; 8 draws in transit refused `committed`;
  - 1 g burns out and back, with a draw every 7 ticks until tick 10,000.

In total the session has 1,308 draws (218 per stream), 4 voyages and
4 arrivals.

| Arrival | residual_x (ly) | residual_t (yr) | residual_phi |
|---|---|---|---|
| α Cen 0.99c (4.37 ly) | 1.8e-15 | 8.0e-15 | 4.8e-11 |
| Sirius at the cap (8.60 ly) | 7.1e-15 | 8.9e-15 | 8.9e-13 |
| 100-ly target (109.4 ly) | 4.8e-13 | 7.4e-13 | 9.8e-10 |
| α Cen 1 g flip, diag (4.37 ly) | 1.1e-14 | 2.6e-14 | 3.7e-14 |

All are within the AC5 bound of 1e-9·max(1, d).

### Replay timings

| Run | darwin arm64 (dev) | linux x86_64 (CI, 2 cores) |
|---|---|---|
| session10k, VM | 3.6 s | 16.0–18.5 s |
| session10k, interpreter | 32.4 s | 74.7 s alone, 82.7 s alongside other cases |
| session2k, VM / interpreter | 0.8 s / 6.6 s | 3.6 s / 16.4 s |
| `make replay` (5 cases, 10k) | 32.4 s wall | 88.8 s wall |
| `make replay TICKS=2000` | ~7 s wall | 22.5 s wall |

The 10k interpreter run takes over 60 s in CI, so the design's risk row
applies. `ci.yml` sets `REPLAY_TICKS` to 2000 on pull requests and 10000 on
`main`. Both are VM == interpreter == digest gated. The x86_64 10k digest was
produced and verified on a throwaway CI branch (run 36974675400, branch
deleted). Locally, `make test` always runs the 10k session.

### Cross-architecture goldens

The sim is bit-deterministic per architecture (VM == interpreter on each),
but not across architectures. `std/math` `exp`/`log` differ by 1 ulp between
arm64 and x86_64 (ailang#1465), and every journey's kinematics pass through
exp-derived floats. So every golden is per architecture, selected by
`uname -m` (aarch64 is read as arm64). The x86_64 goldens come from CI.

The two short play-mode voyages (`alpha_cen`, `godot_map_voyage`) happen to
be identical on both architectures. The diag sessions differ: for example,
`offaxis_v11_equiv` line 8 has `beta` 0.1028644010192098 on arm64 and
0.10286440101920982 on x86_64. A missing golden for the running architecture
is a failure, not a skip.

### Upstream finding at M2.5

The interpreter does not eliminate tail calls. `ship.ail`'s read loop
(`loop(r.session)` in tail position) dies with RT_REC_003 after 10,000 lines
on the interpreter, while `--bytecode` runs 300,000 lines in constant stack.
The harness passes `--max-recursion-depth 100000` to the interpreter only.
Per ailang#1317, that ceiling is not safe far beyond ~84k frames, so
interpreter parity is practical up to sessions of tens of thousands of
lines. The game itself runs on the VM. Reported as **ailang#1486**.

### Bridge tee flake

An earlier full `make test` failed once on "tee == bytes the child read" under
load. The test compared the files after `stop()`, which writes `quit` and
kills the child after 1 s. Under load, the fake child could be killed before
it read `quit` and copied it to its dump. The test now compares while the
child is alive and has answered every line: the fake flushes its dump before
it replies, so there is no race. It then checks that the tee gained exactly
the quit line on `stop()`.

## AILANG issues filed during M2

Statuses checked on GitHub at landing (2026-10-02).

| Issue | Topic | Status |
|---|---|---|
| ailang#1419 | NaN comparisons: `NaN > x` true in the interpreter (VM/interpreter divergence); `ailang test` cannot see NaN-guard mutants (`make wd-vm` works around it) | open (pre-existing, filed in M1) |
| ailang#1450 | strict VM: bitwise Int ops "effectful builtin not yet wired" | fixed in v0.51.0 (enabled SplitMix64, P4) |
| ailang#1456 | whole-number float literal in a test block resolves as Int | fixed in v0.51.0 |
| ailang#1460 | std/json: −0.0 loses its sign; large whole floats encode as integer digits and saturate on decode (`protocol.num` repairs both) | open |
| ailang#1461 | `ailang test`: same-named private functions in different modules collide | open |
| ailang#1462 | strict VM: `std/string.repeat` not wired | fixed in v0.51.0 |
| ailang#1465 | std/math `exp`/`log` differ by 1 ulp arm64 vs x86_64 (forces per-arch goldens) | open |
| ailang#1466 | a single nullary constructor with a leading pipe hides the next declaration's export (IMP010) | open |
| ailang#1467 | an imported function name shadows a lambda parameter of the same name (`\tk.` workaround) | open |
| ailang#1473 | strict VM: a variable pattern in a match arm is evaluator-only | open |
| ailang#1478 | aliased constructor import never matches; unknown constructor in a pattern is not an error (`sim/tripphase.ail` workaround) | open |
| ailang#1481 | hex Int literals above 0x7fffffffffffffff do not parse | open |
| ailang#1486 | interpreter has no tail-call elimination: RT_REC_003 at 10k lines in a tail-recursive stdin loop; VM fine (M2.5) | closed upstream 2026-10-02; not in the v0.51.0 pin, so the harness keeps `--max-recursion-depth 100000` until the next pin bump |
| ailang#1487 | `ailang test --bytecode`: run test bodies on the VM (float-heavy packages take minutes) | open (feature request, 2026-10-02) |

DX messages without issue numbers (sent to inbox `user`, `--from
stapledons_godot`): the interpreter recursion limit on long sessions, the compile cache's `ARTIFACT_TOO_LARGE` for
`protocol_test` (M2.4), a non-exhaustive match that was not reported as one,
and the lockfile's churning `generated_at`.

## R1 review (⏸ R1, D-17)

The sprint's one planned stop for Mark came after M2.6a (milestone 6 of 10):
the release `v0.2.0-m2-map` ("R1 review: galaxy map and plan panel", tagged
macOS build, captures, panel dump and a review page). The loop did not wait
on it and continued with M2.3b and M2.4.

Mark's ruling (D-17, attended 2026-10-02): **R1 accepted, continue to
M2.6b.**
- The map always shows the catalogue's own distance (α Cen A 4.357 ly from
  the 0.01-ly rounding of `stars.json`). Full-precision positions come with
  the M1.2 catalogue tiers. The 4.37 ly check row stays a package test and is
  never shown in game.
- Add common star names from a name table in M2.6b, with the catalogue id as
  subtitle. Done: `data/starmap/names.json`, 54 entries, checked by
  `tools/check_star_names.py`.
- The executor-chosen scenario-parameter ranges in the design doc's protocol
  section are ratified as written.

## The catalogue mirror fix (#37)

M2.6b's name-table check found that every galactic longitude in
`data/starmap/stars.json` was mirrored: l_cat = 245.86° − l_true.
`.claude/skills/starmap-manager/scripts/process_stars.sh` added the IAU atan2
term to l_NCP instead of subtracting it. Latitudes and distances were right;
`tools/extract.py` (M1.2) already used the IAU matrix.

Mark approved fixing it at once in a separate PR. The fix was a regeneration,
not a reflection: the script's real input (VizieR V/70A, which is CNS3, not
CNS5 as the file's header says) was re-downloaded, the unfixed script was
shown to reproduce the committed file byte for byte, and the fixed script
regenerated it. Same 3,802 rows and order; only x and y changed. Sixteen
literature (l, b) check values in `tests/test_physics.gd` fail 16/16 on the
old file and pass on the new one (worst 0.037°). On the NOIRLab panorama the
fraction of bright catalogue positions that sit on a real star went from 4 %
(chance) to 79 %. α Cen A's catalogue distance moved from 4.35667 to
4.35643 ly (re-rounding), which `tests/test_galaxy_map.gd` pins. Mark looked
at the before/after renders before merge (physics gate 2).

Knock-on: the M1.4a destar mask (D-10) was built partly from the mirrored
positions, so up to ~0.38 % of panorama pixels were masked for no reason.
It needs a rerun, and the raw panorama inputs are not on this machine
(follow-up below).

## P5: golden review

Pause point P5 was Mark's review of the replay goldens. He approved them on
PR #35 (attended, 2026-10-02: "yep approved"): the per-architecture goldens
for `offaxis_v11_equiv`, `diag_thrust600`, `session10k` and `session2k`
(1-ulp `exp`/`log` drift, ailang#1465) and the architecture-identical goldens
for `alpha_cen` and `godot_map_voyage`. Regenerating goldens stays a reviewed
`make replay-record` diff, never part of `make test`.

## What M4 can now rely on

The whole loop M4's first review build needs runs end to end on `main`:
**galaxy map → plan → commit → transit → arrival**, driven by the real sim,
recorded through the bridge tee, and replayable (`godot_map_voyage` is a
Godot-recorded session in `make replay`).

M4's design doc (`design_docs/planned/r1/m4-first-journey.md`, §Interfaces
assumed) says "if M2's names differ, M4 adopts M2's". Against what M2
shipped:

| M4 assumed | M2 shipped | Note for M4 |
|---|---|---|
| `hello` → `proto {major: 2, minor}`; minor ≥ 1 (`record`) for live AI | `proto {major: 2, minor: 0}`, plus `sim`, `relativity`, `rng` | `record` (minor 1) is M4's or the AI foundation's addition |
| `new_game{seed, scenario, epoch, start_age, archive}` | `new_game{seed, scenario, diag}`; epoch, start_age and the bubble defaults are scenario params, echoed in `params` | add `archive` in M4 |
| `input{tick, dtau, intents}`; `plan{target, profile{cruise_beta or cruise_phi}}`, `commit{plan_id}`, `cancel`; `refused: [{i, reason}]` | same envelope; intents keyed by `k`: `plan{target{index, id, pos}, cruise_phi}`, `commit{plan_id}`, `cancel`; `refused: [{i, reason}]` | cruise is given as rapidity `cruise_phi`; bounds and default come from `params.cruise_phi_min/max/default` |
| Clock at rest at a fixed host rate, no pause (D-12) | yes: `HOST_DTAU`, 1 ship-day per real second at 20 Hz; transit at `TRANSIT_RATE` 0.1 ship-yr/s | D-12 fixes only the rate at rest; the transit rate is a UI constant |
| State `ship{…}`, `journey{phase, plan{…}, progress, distance_remaining}`, `ism{…}` | change-sets (`changes`, `full`) of `clock{tau, t, year, age}`, `ship{phase, beta, one_minus_beta, gamma, heading, pos, x, flown}`, `journey{state, plan_id, plan{distance, cruise_beta, cruise_gamma, ship_years, earth_years, arrive_year, age_on_arrival, years_left, energy{…}, ism{…}, cmb_forward_k}}`, `ledger{…}`, `rng{…}`, `params{…}`; `events` (`committed`, `phase`, `arrived` with residuals) | journey `state` ∈ idle/planned/committed/arrived; ship `phase` ∈ at_rest/boosting/cruising/braking. Progress is `ship.flown / plan.distance` |
| Commit rule: plan, commit, cancel refused `committed` until arrival | yes, every intent kind, enforced in the sim | — |
| Named PCG streams, `"news"`; `make replay SESSION=…` | SplitMix64 (`splitmix64-1`), streams journey/crew/events/galaxy/ai/**news**; `make replay SESSION=path` against the golden beside it | goldens per architecture until ailang#1465 |
| Galaxy map: `target_selected(star_id)`, plan fields, 0.9c–0.999999c slider default 0.99c, D-12 commit dialog, preselect | all present: `target_selected`, `preselect(index)` (no emit), sim-bound slider, dialog with both clocks and years left, 1.5 s hold, post-commit Cancel refused | star names from `names.json` |
| Arrival 1,000 AU short of the star (D-14) | arrival is at the target position | the stand-off is M4's |

## Follow-ups

- **D-10 destar rerun.** Rebuild the M1.4a destar mask with the corrected
  `stars.json` (or without it: HIP and GCNS probably already cover those
  stars). The raw panorama inputs are not on this machine, so this needs the
  machine that holds `data/raw/background`.
- **CNS3 distances.** `stars.json` is CNS3 (V/70A); 16 of the 54 named stars
  are 3–15 % off literature distances. Move the map to CNS5 via M1.2's
  `tools/extract.py` and the catalogue tiers (D-17 already points there).
- **Per-arch goldens until ailang#1465.** Keep the arm64 and x86_64 goldens;
  x86_64 ones come from CI. Collapse to one set when `exp`/`log` agree.
- **Interpreter TCO (ailang#1486).** Closed upstream; on the next AILANG pin
  bump, drop `--max-recursion-depth 100000` from `tools/replay.py` and check
  that the 10k interpreter run still passes.
- **Transit and hold polish** (M2.6b evaluation, non-blocking): clamp the
  frame delta in `hold_commit` (one 1.5 s stall commits in one frame) and
  release the hold on focus loss; pin the transit row formats and the
  transit `dtau` on the wire (two surviving mutants); `make ui` cold start
  can hit `startup_timeout` with an empty compile cache; the committed
  `docs/contact_sheet.png` differs from a fresh `make capture` (pre-existing).
- **Replay inputs** (M2.5 evaluation): consider committing the 2k session
  input or its digest, so reviewers can read it without running
  `gen_session.py`.
- **Design repo:** the `journey-system.md` superseded-maths note
  (`calculateJourneyTimes` is the instant-acceleration idealisation; the
  package's boost–cruise–brake profile replaces it) goes with the roadmap
  update.
