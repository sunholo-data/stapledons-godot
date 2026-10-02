# M2 journey core: report (draft)

> **Draft.** Written at M2.5 (2026-10-02). At landing, after M2.6b, it moves to
> `design_docs/implemented/r1/m2-report.md` with the M2.6b and evaluation
> rows filled in. Design: [m2-journey-core.md](m2-journey-core.md). Plan:
> [m2-journey-core-sprint.md](m2-journey-core-sprint.md).

## Toolchain

| | |
|---|---|
| AILANG | v0.51.0 (b99dd25), `runtime/bin/ailang`, CI `linux.x64` release. M2.0–M2.3 ran on v0.50.0 (6abe1a5) |
| `sunholo/relativity` | 0.4.0 (ailang-packages PR #84, 1abde63), published at M2.0 under the standing grant |
| Godot | 4.7.2-stable |
| Machines | dev: darwin arm64 (16 cores). CI: GitHub `ubuntu-latest` x86_64 (2 cores) |

## Milestones

| Milestone | Result | Evaluation |
|---|---|---|
| M2.0 package trip + energetics | relativity 0.4.0: `TripPlan`, `planBurnCoastBurn`, `planFlipAndBurn`, `phaseAt`, `motionAt`, `acosh1p`, `rapidityOfOneMinusBeta`, `medium`, `cmbForwardTemperature`; 101/101 tests | 96/100 |
| M2.1a protocol codecs | protocol v2 codecs in `sim/protocol.ail`; float-text repairs for −0.0 and large/small floats | 92/100 |
| M2.1b bridge v2 | `SimBridge` v2, `record_path` tee, v1.1 removed; AC9 bit-exact float64 echo | 93/100 |
| M2.2 world + ledger | `World`, params, clock, phases, closed mass budget | 94/100 |
| M2.3a planner + commit | planner = closed form to 1e-9; commit irreversible (AC7) | 95/100 |
| M2.3b autopilot | stepped voyage = `motionAt` at every boundary; residuals < 1e-9·max(1, d) | 96/100 |
| M2.4 PRNG | SplitMix64 named streams (P4, below) | 94/100 |
| M2.6a map + plan panel | galaxy map, cruise slider, panel shows sim numbers only | 89/100 |
| M2.5 replay + 10k parity | `make replay`, goldens, 10k-tick session (this report) | pending |
| M2.6b commit ritual | in progress | pending |

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

### Timings

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

| Issue | Topic | Status |
|---|---|---|
| ailang#1419 | NaN comparisons: `NaN > x` true in the interpreter (VM/interpreter divergence); `ailang test` cannot see NaN-guard mutants (`make wd-vm` works around it) | open |
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
| ailang#1486 | interpreter has no tail-call elimination: RT_REC_003 at 10k lines in a tail-recursive stdin loop; VM fine (M2.5) | open (new) |

There were also DX messages without issue numbers: the compile cache's
`ARTIFACT_TOO_LARGE` for `protocol_test` (M2.4), and the lockfile's churning
`generated_at`.

## Open at landing

- M2.6b (commit ritual) and its evaluation.
- The M2.5 independent evaluation, then P5 (golden review) by Mark.
- Landing: move the design doc and plan to `design_docs/implemented/r1/`;
  update the design repo's roadmap M2 status and add the `journey-system.md`
  superseded-maths note; add a changelog entry; move this file to
  `implemented/r1/m2-report.md`.
