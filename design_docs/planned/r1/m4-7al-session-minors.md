# One source for the session minors (7al)

**Status:** Planned 2026-11-11 (mission iteration 87, designer Opus 5.5). Revision 1 answers design-quorum round 1 (BLOCKED 3/3 on narrow points; option (b) not disputed). Revision 2 (controller, narrow-refinement carve-out) applies the round-2 reviewers' fixes (BLOCKED 2/3, kimi-k3 pass; option (b) not disputed); see "Quorum verification log". **Release:** r1. **Milestone:** none (suite hygiene, queue row **7al**).
**Priority:** low (clause 5 hygiene). Nothing is red today. The row closes a gap a future protocol bump would open: the three game sessions agree on their protocol minor only by convention, and four feature-test checks name today's constant.
**Implements:** row 7al of the charter (`design_docs/stapledon-mission.md`, Queue), which comes from follow-ups F1 and F2 and the lexical-limit finding of row 7ah ([`design_docs/implemented/r1/m4-7ah-similar-guard-minor.md`](../../implemented/r1/m4-7ah-similar-guard-minor.md), "Follow-ups" and "Risks"). It protects the loading jump's simulation prefetch ([`design_docs/implemented/r1/lightspeed-loading.md`](../../implemented/r1/lightspeed-loading.md)) and serves definition-of-done gate 1. Design-repo context: the NDJSON protocol and its minor negotiation follow ADR 0001 ([`../stapledons-design/decisions/0001-engine-and-architecture.md`](../../../../stapledons-design/decisions/0001-engine-and-architecture.md)). Protocol 2.18 is R3-COMMS-V2 ([`design_docs/implemented/r3/comms-station-v2.md`](../../implemented/r3/comms-station-v2.md)). No physics-spec section applies.
**Depends on:** nothing new. It builds on 7ah's `similar-main-guard`, which stays as it is and passes on the new constant (V14).
**Estimated LOC:** about 240. Most of it is make glue and one shell control script; the product change is one new constant and three one-token edits.
- `bridge/sim_bridge.gd`: +5 (a doc comment and `const SESSION_MINOR := 18`, after `:77`).
- `main.gd:304`, `demos/ship_geometry_demo.gd:1025`, `ui/loading_jump.gd:254`: one token each, `EARTH_LOG_MINOR` → `SESSION_MINOR`. The trailing history comments are not edited.
- `tests/test_bh_hud.gd:109,176`, `tests/test_comms_station.gd:133`, `tests/test_ship_ui.gd:416`: one comparison each. The comms check also keeps its own feature floor, `SESSION_MINOR >= EARTH_LOG_MINOR`.
- `Makefile`: +40 after `:133` (Appendix A): the `session-minor-guard` and `session-minor-guard-controls` targets and their `test` and `ci-fast` edges.
- `tools/session_minor_guard_controls.sh`: new, 183 lines (Appendix B). It is shell, so it needs no `.uid` and no Python allowlist row.

The measured revision-1 prototype is `/tmp/stap_i87_7al/proto_r1.patch` (343 lines, sha256 `ef85d2c28a0f…`); revision 0's was `/tmp/stap_i87_7al/proto.patch` (308 lines, `6936010ac48c…`). Both were reverted from the tree. Appendices A and B reproduce revision 1 verbatim, so the doc does not depend on `/tmp`. The product and test edits are byte-identical in the two revisions (V21); only the Makefile block and the control script changed.

## Game vision alignment

Scored against `../stapledons-design/vision/core-pillars.md` (pillars 1–6) and `physics/relativity-spec.md` for authenticity.

| Pillar | Relevance | Score | Notes |
|---|---|---:|---|
| Choices Are Final | 0 | 0 | No game logic changes. |
| The Game Doesn't Judge | 0 | 0 | No copy changes. |
| Time Has Emotional Weight | 0 | 0 | Nothing a player sees or hears changes. Every session still asks 2.18 (V14, V15). |
| The Ship Is Home | 0 | 0 | No scene or asset changes. The row protects a load-time saving: with a missed bump, pressing New game, Guided voyage or Galaxy map would hold the loading animation on one frame for an extra 2–5 s on the loaded Studio (V2), about 0.5 s on a quiet host by the loading table (V3). That keeps an existing feature intact; it adds nothing. |
| Grounded Strangeness | 0 | 0 | No content change. |
| We Are Not Built For This | 0 | 0 | No crew or AI change. |
| Hard sci-fi authenticity (spec) | 0 | 0 | No formula, shader, lookup table or render change. Physics gates 2 and 3 do not apply. |
| **Net** | | **0** | **Go.** Neutral suite hygiene with low player-visible value. No pillar scores below 0, so no stop for a human. |

## Problem

1. **Three sessions, one minor, kept equal by hand (V1).** On `origin/main` (`8334b124`) the game's three sessions all ask `SimBridge.EARTH_LOG_MINOR` (18):
   - the map, `main.gd:304` in `_run_map`: `if not capture:sim.want_minor=SimBridge.EARTH_LOG_MINOR # …`;
   - the ship (New game and Guided voyage), `demos/ship_geometry_demo.gd:1025` in `_create_navigation`: `journey_sim=SimBridge.new();journey_sim.want_minor=SimBridge.EARTH_LOG_MINOR # …`;
   - the loading jump's prefetch, `ui/loading_jump.gd:254` in `_work_sim`: `holder["value"] = SimBridge.warm(SimBridge.EARTH_LOG_MINOR) # …`.

   `SimBridge.warm(` has no other production caller (V1). The only thing tying the three together is their trailing comments ("as the ship, so it adopts the loading jump's prefetch").
2. **A mismatch costs a main-thread spawn, measured (V2, V3).** `SimBridge._adopt_warm()` (`bridge/sim_bridge.gd:228–233`) returns false when `w.want_minor != want_minor`. A scratch probe isolates the minor: no `launch_override`, no `record_path`, only a different minor. That differs from `tests/test_loading_jump.gd:160–163`, which sets both a launch override and another minor in one check. In 5 of 5 rounds, a 2.16 `start()` beside an offered 2.18 warm sim did not adopt it. The warm sim stayed offered, and the start paid a full spawn + hello: 3953–5103 ms at load 23–41. A 2.18 `start()` adopted it in 0.0–0.1 ms. The route (`main.gd`, the ship demo) runs that `start()` in the loading jump's blocking **build** phase, on the main thread. Mutating one site at a time in the tree and running `tests/test_loading_jump.gd` headless measured:

   | Mutation (to `EARTH_MINOR`) | `loading-jump` result | Build blocked (baseline → mutated) |
   |---|---|---|
   | none (baseline) | `77 passed, 0 failures` | ship 4440, guided 3111, map 532 ms |
   | map site (`main.gd:304`) | `76 passed, 1 failures`: `FAIL map: the map's simulation is the prefetched one` | map 532 → 4474 ms |
   | ship site (`demos/…:1025`) | `75 passed, 2 failures`: `FAIL ship: navigation runs on the prefetched simulation`, `FAIL guided: the tour runs on the prefetched simulation` | ship 4440 → 6797, guided 3111 → 6943 ms |
   | prefetch site (`ui/loading_jump.gd:254`) | `74 passed, 3 failures` (ship, guided, map) | ship 10210, guided 6524, map 6053 ms |

   The host was shared (load 10–60), so the numbers move by 1–2 s from run to run. The sign and the size, seconds, do not. The quiet-host figure in the loading table is 540 ms for the `sim` stage (`ui/loading_jump.gd:49–55`, measured 2026-10-08). It was not re-measured here (no quiet host).
3. **"Silently" is only half true (V2, V4).** F1 called a missed bump silent. It is not silent for the suite: `loading-jump-test` (in `make test`, so the nightly `rig/full`) fails at the mismatched route, because it compares the route's live child pid with the prefetch's. It is silent at merge time: `ci-fast` installs no Godot (`.github/workflows/ci.yml:41–42`, `if: ${{ inputs.full }}`). So a PR that bumps one site merges green on the fast tier, and main's nightly goes red the next morning. A player sees no error, only a longer hold on one loading frame.
4. **Four feature checks name today's constant (V5, V6).** `tests/test_bh_hud.gd:109,176` and `tests/test_comms_station.gd:133` check `demo.journey_sim.want_minor == SimBridge.EARTH_LOG_MINOR`. `tests/test_ship_ui.gd:416` checks the negotiated minor, `demo.journey_sim.hello_reply.proto.minor == SimBridge.EARTH_LOG_MINOR`. The row named only the first three. These are the only test comparisons of `journey_sim`'s minor with a SimBridge constant, in any form, including `get("minor")` reads (V5, V18). `test_bh_hud.gd:115` compares the black-hole session with `GR_MINOR`, its own fixed minor. `tests/test_sim_bridge.gd:341,394,447` compare their own bridges' negotiated minors with `SYSTEM_MINOR`, `NAV_MINOR` and `GR_MINOR`, also fixed feature sessions. In production code (`demos/`, `main.gd`, `ui/`, `interior/`, `sky/`, and `bridge/` per V23) the only comparison of a minor with a SimBridge constant is the `>=` feature floor at `demos/ship_consoles.gd:1186` (V18; see Non-goals). A simulated bump on `origin/main` measured the cost: moving the ship site to `WORLDS_MINOR` turned `bh-hud` from 64/0 to `62 passed, 2 failures` (109 and 176), while the feature still worked. None of these tests is in `ci-fast` either.
5. **7ah's lexical limit (V7).** 7ah's guard reads `_run_map`'s text, so it cannot see a write made elsewhere, such as `sim.set("want" + "_minor", 2)` or a helper. The loading-jump pid checks do not depend on how `want_minor` was written. They compare the running child, so they already catch any map-session minor that differs from the prefetch's, but only at night.

## Goals and non-goals

**Goals.**
- **One source.** All three sites, and all four test comparisons, name `SimBridge.SESSION_MINOR`. A protocol bump that the game's sessions adopt edits one line, `const SESSION_MINOR := <n>`, and no session file or test.
- **A missed or partial bump fails at the PR.** A headless guard in `ci-fast` and `make test` requires each site to ask exactly `SimBridge.SESSION_MINOR`, and requires every test comparison of `journey_sim`'s minor with a SimBridge constant to name it. Its committed mutation controls (19 rejected, 3 accepted) run beside it. "Every comparison" is measured against the enumerated comparisons (V5 for tests, V18 for production): the scan covers `tests/*.gd`, and the one production comparison, a `>=` feature floor that survives a bump, is a documented blind spot with a nightly backstop (Risks). AC20 re-runs the enumeration, so a new production comparison is seen at the sprint.
- **Visible behaviour identical.** `SESSION_MINOR` is 18, so every session still asks 2.18, the prefetch is still adopted on all three routes (V15), and no capture, render, layout or audio changes.

**Non-goals.**
- A new runtime check. The runtime coverage already exists and stays nightly; see Design, "Measured options". `ci-fast` cannot run Godot.
- Requiring `SESSION_MINOR` to be the newest protocol minor. That is 7ah's rejected option (b″): a tool-only or later-wired minor (as WORLDS_MINOR 17 was) must not force the game's sessions up.
- The other `want_minor` writers. `main.gd:258,280,414`, the black-hole visit, and tools and tests that open their own 2.18 sessions (`tests/test_earth_history.gd`, `tests/test_earth_log_bridge.gd`, `tests/test_bridge_monitors.gd`, `tools/comms_golden.gd`, `tools/comms_station_capture.gd`) are not prefetch sessions. They keep their own feature minors. `demos/ship_consoles.gd:1186` (read, V18) is `if sim is SimBridge and int((sim as SimBridge).hello_reply.get("proto", {}).get("minor", 0)) >= SimBridge.EARTH_LOG_MINOR:` in `_ask_weeks`, the only `SimBridge.*_MINOR` in that file. It is a `>=` floor on the negotiated minor for the `earth_weeks` intent (2.18), which stays true at any bump above 2.18, so it keeps naming `EARTH_LOG_MINOR`. The file is also in attended PR #412 (the same line is at `:1276` on #412's head).
- Editing 7ah's `similar-main-guard` or its controls. They pass unchanged (V14).
- Splitting `tests/test_loading_jump.gd:160–163`'s conflated check (see Follow-ups).

## Design

### Measured options

| Option | What | Measured | Verdict |
|---|---|---|---|
| (a) Lexical guard, three constants | a guard that resolves each site's named constant and requires the three values equal | feasible: each site is one line in one function (`want_minor` ×1 in `_run_map` and `_create_navigation`, `warm(` ×1 in `_work_sim`; V8) | **Rejected as incomplete.** The sites would still need three edits per bump, and the tests would still name a constant that moves. |
| (b) One constant + lexical guard in `ci-fast` | `SimBridge.SESSION_MINOR`, used by the three sites and the four tests; `session-minor-guard` requires exactly that name at each site and in each test comparison | revision-1 prototype green: guard under 0.1 s, controls 16/3 in 1.7 s (V21); 9 of 9 meta-weakenings caught (V21); dash, GNU Make 4.4.1, make 3.81 and shellcheck clean on macOS (V21). The GNU userland run is a pre-landing AC (AC19) | **Chosen.** |
| (c) Runtime check of the negotiated minor | assert `hello_reply.proto.minor == SESSION_MINOR` in a route test | feasible headlessly: the probe read `proto.minor` 16 for a 2.16 ask and 18 for 2.18 (V2); the sim caps a higher ask at 18 (`sim/protocol_test.ail:714`, V13). It would catch two things (b) cannot: a write the text does not show (7ah's limit), and `SESSION_MINOR` set above what the sim serves | **Not added; it already exists, nightly.** `tests/test_ship_ui.gd:416` is that check for the ship session, and the loading-jump pid checks cover all three routes (V2). Neither can run in `ci-fast` (no Godot, V4). This row keeps both and points `test_ship_ui.gd:416` at `SESSION_MINOR`. |
| (b′) `const SESSION_MINOR := EARTH_LOG_MINOR` | an alias instead of digits | 7ah's grammar rejects an expression constant (its D10), so `similar-main-guard` would fail on `_run_map` | Rejected. It would mean loosening 7ah's fail-closed resolver. Digits plus "equals a defined protocol constant" (below) keep both guards strict. |

**Why (b).** It is the smallest change that makes a partial bump fail loudly in the fast tier. It pairs the three-site check with the test-comparison scan: a bump that moves one site by hand fails; a feature test that names `EARTH_LOG_MINOR` again fails; and a real bump is one line. The runtime coverage (c) stays where Godot runs, in the nightly, and it is the backstop for the lexical limit.

### M1. `SimBridge.SESSION_MINOR` (product, behaviour-identical)

- `bridge/sim_bridge.gd`: after `const EARTH_LOG_MINOR := 18` (`:77`), a 4-line doc comment and `const SESSION_MINOR := 18`. The doc comment names the three sites and says a bump moves this line.
- `main.gd:304`, `demos/ship_geometry_demo.gd:1025`, `ui/loading_jump.gd:254`: `SimBridge.EARTH_LOG_MINOR` → `SimBridge.SESSION_MINOR`. One token per line; the trailing comments are kept.
- `tests/test_bh_hud.gd:109,176` and `tests/test_ship_ui.gd:416`: `SimBridge.EARTH_LOG_MINOR` → `SimBridge.SESSION_MINOR` in the comparison; the check messages are unchanged.
- `tests/test_comms_station.gd:133`: `want_minor == SimBridge.SESSION_MINOR and SimBridge.SESSION_MINOR >= SimBridge.EARTH_LOG_MINOR`. The floor keeps the feature's own need (the comms station reads `earth_log`, 2.18). The message becomes `the session asks SESSION_MINOR (2.18 or later) and the world carries earth and its log`; test text only, never shown to a player.

### M2. `session-minor-guard` (Appendix A)

POSIX sh in make (dash-clean), read-only, git-free. It reads `$(SESSION_GUARD_ROOT)` (default `.`). In order:
1. `bridge/sim_bridge.gd` exists. `SESSION_MINOR` resolves with 7ah's end-anchored grammar, `^const SESSION_MINOR := ([0-9]+)[[:space:]]*(#.*)?$`; otherwise `SESSION_MINOR unresolved in bridge/sim_bridge.gd` (also an expression, a missing or a duplicated definition).
2. The value equals at least one other `const <NAME>_MINOR := <digits>`, so the sessions ask a protocol minor the bridge defines; otherwise `SESSION_MINOR (<v>) is no protocol minor in bridge/sim_bridge.gd`. The matching names go into the ok line.
3. For each site, (file, function, token): (`main.gd`, `_run_map`, `want_minor`), (`demos/ship_geometry_demo.gd`, `_create_navigation`, `want_minor`), (`ui/loading_jump.gd`, `_work_sim`, `warm(`). The function's range is `sed -n '/^func NAME(/,/^[^[:space:]#]/p'`: from its `func NAME(` line to the next **top-level** line (column 0 and not a comment, so a `func`, a `static func`, a `var` or a `const`). Revision 0 ended it at the next `^func ` line, which runs on through a `static func` (all three files have some: 3, 7 and 5; V22) and would credit an ask moved into one (control `stray`). Today both patterns give the same three ranges (96, 55 and 6 lines; V22). The range must exist, else `<file> has no func NAME(` (control `renamed`). It must be **bounded**: its last line must be that top-level line, else `<file> <func> has no following top-level line; range unbounded` (control `unbounded`; kimi-k3's fix, with the end pattern widened from `func` to any top-level line). The token must occur exactly once, counted with an awk `index` loop, so `warm(` is a literal and not a regex. Otherwise `<file> <func> mentions <token> <n> times, want 1`. That one line must then match `^[^#]*want_minor *= *SimBridge\.SESSION_MINOR[[:space:]]*(#.*)?$`, or for the prefetch `^[^#]*SimBridge\.warm\(SimBridge\.SESSION_MINOR\)[[:space:]]*(#.*)?$`; otherwise `<file> <func> does not ask SimBridge.SESSION_MINOR`. A literal, arithmetic, a ternary or another constant fails here.
4. The test scan: `grep -oHE 'journey_sim\.(want_minor|hello_reply\.proto\.minor) *[=!<>]=? *SimBridge\.[A-Z0-9_]+_MINOR' tests/*.gd`. Its exit status is captured, never suppressed (revision 2, gpt-6.1-sol): status 0 goes on, status 1 (no match) goes to the no-comparisons rejection below, and any other status rejects with `test scan error (grep rc <n>)`, even when the readable files emitted valid comparisons (control `brokentest`). There must be at least one hit; otherwise `no test compares journey_sim's minor with a SimBridge constant`, which is the scan's known-positive control. Every hit must end in `SimBridge.SESSION_MINOR`; otherwise `<file> compares journey_sim's minor with SimBridge.<NAME>, not SESSION_MINOR`. `-o` checks each comparison on its own, so a second comparison on the same line is not hidden by the first.
5. The ok line: `session-minor guard: ok, SESSION_MINOR (18) = EARTH_LOG_MINOR; main.gd _run_map, demos/ship_geometry_demo.gd _create_navigation and ui/loading_jump.gd _work_sim ask it; 4 test comparisons name it`.

### M3. `session-minor-guard-controls` and `tools/session_minor_guard_controls.sh ROOT` (Appendix B)

It has 7ah's drill shape: an explicit `ROOT`, `mktemp -d` with a trap, and copies of the seven files only. `cmp` proves each mutation changed its copy, else exit 3. The guard runs through its make target with `MAKEFLAGS` cleared. Each case asserts make's rc and the exact reason line once, with no ok line on a rejection, and the totals close the run.

**Portability (revision 1, kimi-k3).** The mutations use only constructs that behave the same in GNU and BSD sed and awk, including mawk:
- **sed** edits are single-line `s` commands under `sed -E`, optionally range-addressed (`/re/,/re/s/…/…/`). There are no `a`, `i` or `c` commands, no `{…}` blocks, and no `\n`, `\t` or backslash-newline in a replacement.
- **Multi-line edits** (`twice`, `removed`, `unbounded`, `stray`) are POSIX awk programs. They use no character classes (`[^ \t#]`, not `[^[:space:]#]`), no `ENVIRON`, and no gawk extensions; `"\t"` appears only inside awk string literals.
- **Appends** (`bump`) are `printf '%s\n' … >>`, checked with `tail -n 1`.

Revision 0's three divergent forms are gone: the `twice` backslash-newline insert with literal TABs, the `removed` `/…/,/…/{/…/d;}` block, and the `bump` `$a\` append.

| Case | Mutation (on the copy) | Expected |
|---|---|---|
| `pristine` | none | rc 0, ok line |
| `map` | `_run_map`: `SESSION_MINOR` → `EARTH_LOG_MINOR` | rc 2, `main.gd _run_map does not ask SimBridge.SESSION_MINOR` |
| `ship` | `_create_navigation`: → `EARTH_MINOR` | rc 2, `demos/ship_geometry_demo.gd _create_navigation does not ask …` |
| `prefetch` | `_work_sim`: `warm(SimBridge.EARTH_LOG_MINOR)` | rc 2, `ui/loading_jump.gd _work_sim does not ask …` |
| `literal` | `_work_sim`: `warm(18)` | rc 2, same line as `prefetch` |
| `arith` | ship: `SimBridge.SESSION_MINOR - 2` | rc 2, `… _create_navigation does not ask …` |
| `ternary` | map: `SimBridge.SESSION_MINOR if capture else SimBridge.EARTH_MINOR` | rc 2, `main.gd _run_map does not ask …` |
| `twice` | ship: a second `journey_sim.want_minor = 2` after the line (awk) | rc 2, `… _create_navigation mentions want_minor 2 times, want 1` |
| `removed` | map: the line deleted inside `_run_map` (awk) | rc 2, `main.gd _run_map mentions want_minor 0 times, want 1` |
| `renamed` (r1) | `func _work_sim(` → `func _work_sim_renamed(` | rc 2, `ui/loading_jump.gd has no func _work_sim(` |
| `unbounded` (r1) | `ui/loading_jump.gd` cut after `_work_sim`'s body, so no top-level line follows it (awk) | rc 2, `ui/loading_jump.gd _work_sim has no following top-level line; range unbounded` |
| `stray` (r1) | the prefetch's ask moved out of `_work_sim` into a `static func _stray(…)` inserted right after it (awk) | rc 2, `ui/loading_jump.gd _work_sim mentions warm( 0 times, want 1`; with revision 0's `^func ` range end this passed (meta-drill M7, V21) |
| `nosession` | `const SESSION_MINOR :=` renamed | rc 2, `SESSION_MINOR unresolved in bridge/sim_bridge.gd` |
| `exprsession` | `const SESSION_MINOR := EARTH_LOG_MINOR` | rc 2, same |
| `orphan` | `const SESSION_MINOR := 99` | rc 2, `SESSION_MINOR (99) is no protocol minor in bridge/sim_bridge.gd` |
| `testname` | `test_comms_station.gd`: the comparison names `EARTH_LOG_MINOR` | rc 2, `tests/test_comms_station.gd compares journey_sim's minor with SimBridge.EARTH_LOG_MINOR, not SESSION_MINOR` |
| `notests` | the copied tests removed and one readable test with no comparison written (r2, so grep exits 1, not 2) | rc 2, `no test compares journey_sim's minor with a SimBridge constant` |
| `missbridge` (r2, glm-5.3) | the copied `bridge/sim_bridge.gd` removed | rc 2, `session-minor guard: missing bridge/sim_bridge.gd` |
| `misssite` (r2, glm-5.3) | the copied `main.gd` removed | rc 2, `session-minor guard: missing main.gd` |
| `brokentest` (r2, gpt-6.1-sol) | a dangling `tests/broken.gd` symlink beside the readable tests, which still emit their valid comparisons | rc 2, `session-minor guard: test scan error (grep rc 2)` |
| `bump` | `SESSION_MINOR := <max+1>` (an `s` command) and `const FUTURE_MINOR := <max+1>` appended with `printf >>` (19 today, computed); no session file or test edited | rc 0, `ok, SESSION_MINOR (19) = FUTURE_MINOR; …` |
| `comment` | a trailing `# comment` on `SESSION_MINOR` | rc 0, ok line |

Every guard branch has a control. The 16 cases through `notests` and the 3 accepted cases were measured on the revision-1 prototype (V21); the three revision-2 cases (`missbridge`, `misssite`, `brokentest`) and the revision-2 `notests` mutation are measured by the sprint (V24). The mutations never depend on today's value except where it is the subject (`literal`'s `18` is the literal being rejected).

### M4. Wiring

`test: session-minor-guard session-minor-guard-controls` and `ci-fast: session-minor-guard session-minor-guard-controls` are separate rule lines beside the targets, the pattern of 7ah and `mk/script-gates.mk:27`. The `ci-fast:` and `test:` lines at `Makefile:55,57` are not edited. **Why ci-fast:** the measured gap is merge time (Problem §3). The guard and controls cost under 4 s and use only `sh`, `sed`, `grep`, `awk`, `cmp`, `mktemp` and `make`.

## Files touched and Do-not-touch

- **Touched (exact paths):** `bridge/sim_bridge.gd` (insert after `:77`), `main.gd` (`:304`, one token), `demos/ship_geometry_demo.gd` (`:1025`, one token), `ui/loading_jump.gd` (`:254`, one token), `tests/test_bh_hud.gd` (`:109`, `:176`), `tests/test_comms_station.gd` (`:133`), `tests/test_ship_ui.gd` (`:416`), `Makefile` (insert after `:133`), and the new `tools/session_minor_guard_controls.sh`. Landing adds a changelog fragment and the charter and README status rows.
- **Do not touch:** the trailing history comments on the three site lines; 7ah's `similar-main-guard`, its controls and its `Makefile:105–133`; the `ci-fast:` and `test:` lines (55, 57); the include list (`Makefile:30–40`, where #412 adds a line); `demos/ship_consoles.gd`; every other `want_minor` writer (Non-goals); `sim/` and `tests/fixtures/protocol_*`.

## Conflict surface

Measured with git, not `gh pr diff` (V16).
- **#412** `feat/captain-command` (Mark's, attended; head `3926f4f3`). It touches `demos/ship_geometry_demo.gd` and `Makefile`, among 46 files. Its ship-demo hunks nearest `:1025` are an insert after `:1012` (in `_place_navigation`) and an insert after `:1057` (in `_create_navigation`, two input-handling lines). Neither is within 3 lines of `:1025`, and **no hunk of #412 adds or removes a `want_minor` or `_MINOR` line**: 0 matches, against 25 in #379's merge diff as a positive control. Its only Makefile hunk is `@@ -34,0 +35 @@` (the include list). `git merge-file` of this row's prototype against #412's versions: 0 conflicts for both files. On the merged ship file, `_create_navigation` still has one `want_minor`, and `session-minor-guard` is ok. #412 does not touch `main.gd`, `ui/loading_jump.gd`, `bridge/sim_bridge.gd` or any of the three test files, and its tree has the same four comparisons. **Verdict: no overlap; #412 merges cleanly in either order.** The one-line ship edit is the only touch of that file, and it is required: the ship is one of the three sessions, and a guard alone cannot make it name `SESSION_MINOR`.
- **#380** `feat/r2-kerr-table-preflight` and **#373** `feat/r2-kerr`: Makefile hunks at 13, 21, 23, 24 and 228 (both), plus 247 (#380). Neither touches any other file here. `git merge-file` on the Makefile: 0 conflicts each.

## Acceptance criteria

All commands are headless and run in the fix clone with `export PATH=$PWD/runtime/bin:$PATH` (or the main checkout's `runtime/bin`) and the default zsh. Expected outputs were measured on the revision-1 prototype (V21, plus V9–V16 for the product and test edits, which are unchanged). The Godot rows (10, 11) need a warm sim compile and, for `bh-hud-test`, the lens tables (`make lens-assets`, or the symlinks described in the Verification log). AC19 is the one criterion that cannot run on this host: it is measured on GitHub's runner and **gates the PR leaving draft**.

| # | Criterion | Command | Expected |
|---|---|---|---|
| 1 | GREEN: the guard on the tree | `make session-minor-guard; echo rc=$?` | `session-minor guard: ok, SESSION_MINOR (18) = EARTH_LOG_MINOR; main.gd _run_map, demos/ship_geometry_demo.gd _create_navigation and ui/loading_jump.gd _work_sim ask it; 4 test comparisons name it`, `rc=0` |
| 2 | The controls: 19 rejected, 3 accepted | `make session-minor-guard-controls; echo rc=$?` | the 22 case lines of the M3 table in order, each `session-minor-guard-controls: <case> rejected (session-minor guard: <exact line>)` or `session-minor-guard-controls: <case> accepted`, then `session-minor-guard-controls: 19 rejected, 3 accepted`, `rc=0` |
| 3 | RED: the map asks another constant | `sed -i.bak '/^func _run_map(/,/^func /s/SimBridge\.SESSION_MINOR/SimBridge.EARTH_LOG_MINOR/' main.gd && make -s session-minor-guard; echo rc=$?; mv main.gd.bak main.gd` | `session-minor guard: main.gd _run_map does not ask SimBridge.SESSION_MINOR`, `make: *** [session-minor-guard] Error 1`, `rc=2` |
| 4 | RED: the ship asks another constant | `sed -i.bak '/^func _create_navigation(/,/^func /s/SimBridge\.SESSION_MINOR/SimBridge.EARTH_MINOR/' demos/ship_geometry_demo.gd && make -s session-minor-guard; echo rc=$?; mv demos/ship_geometry_demo.gd.bak demos/ship_geometry_demo.gd` | `session-minor guard: demos/ship_geometry_demo.gd _create_navigation does not ask SimBridge.SESSION_MINOR`, `rc=2` |
| 5 | RED: the prefetch asks another constant | `sed -i.bak '/^func _work_sim(/,/^func /s/SimBridge\.SESSION_MINOR/SimBridge.EARTH_LOG_MINOR/' ui/loading_jump.gd && make -s session-minor-guard; echo rc=$?; mv ui/loading_jump.gd.bak ui/loading_jump.gd` | `session-minor guard: ui/loading_jump.gd _work_sim does not ask SimBridge.SESSION_MINOR`, `rc=2` |
| 6 | RED: a feature test names today's constant again | `sed -i.bak 's/journey_sim\.want_minor == SimBridge\.SESSION_MINOR/journey_sim.want_minor == SimBridge.EARTH_LOG_MINOR/' tests/test_comms_station.gd && make -s session-minor-guard; echo rc=$?; mv tests/test_comms_station.gd.bak tests/test_comms_station.gd` | `session-minor guard: tests/test_comms_station.gd compares journey_sim's minor with SimBridge.EARTH_LOG_MINOR, not SESSION_MINOR`, `rc=2` |
| 7 | GREEN: a bump is one line | `sed -i.bak 's/^const SESSION_MINOR := 18$/const SESSION_MINOR := 17/' bridge/sim_bridge.gd && make -s session-minor-guard; echo rc=$?; mv bridge/sim_bridge.gd.bak bridge/sim_bridge.gd` | `session-minor guard: ok, SESSION_MINOR (17) = WORLDS_MINOR; …; 4 test comparisons name it`, `rc=0` |
| 8 | 7ah's guard and controls are unchanged and green | `make similar-main-guard similar-guard-controls; echo rc=$?` | `similar-test guard: ok, main.gd _run_map asks SESSION_MINOR (18) >= SIMILAR_MINOR (14)`, …, `similar-guard-controls: 13 rejected, 3 accepted`, `rc=0` |
| 9 | Wired into `ci-fast` and `test`, locally and on GitHub | the AC9 block below | `2`; lines `test: session-minor-guard session-minor-guard-controls` and `ci-fast: session-minor-guard session-minor-guard-controls`; `ci-fast` has 23 prerequisites (21 on `origin/main`), with `session-minor-guard` and `session-minor-guard-controls` among them. **Evidence required at landing:** the GitHub fast-tier run on the **final** commit of the PR (`gh run list --commit <final sha>`) is `success`, and its job log shows the two lines of AC19. Record the run id, its head sha and the two log lines in the sprint JSON |
| 10 | Behaviour identical at runtime: every route still runs on the prefetch | `make loading-jump-test; echo rc=$?` | `loading-jump-test` ok (the log ends `loading-jump: 77 passed, 0 failures`, including the three `… prefetched simulation` checks), `rc=0` |
| 11 | The feature tests pass on `SESSION_MINOR` | `make comms-station-test bh-hud-test ship-ui-test; echo rc=$?` | `comms-station: 42 passed, 0 failures`, `bh-hud: 64 passed, 0 failures`, `ship-ui: 288 passed, 0 failures` (the exact counts may grow with main), `rc=0` |
| 12 | The controls catch a weakened guard (meta-drills; sprint evidence, Appendix C saved to `/tmp/7al_meta.sh`) | `sh /tmp/7al_meta.sh "$PWD"; echo rc=$?` | `meta base: rc 0 :: session-minor-guard-controls: 19 rejected, 3 accepted`; M1 → `map: make rc 0, want 2`; M2 → `twice: …`; M3 → `orphan: …`; M4 → `testname: …`; M5 → `notests: …`; M6 → `arith: …`; M7 (range end back to `^func `) → `stray: make rc 0, want 2`; M8 (bounded check deleted) → `unbounded: make rc 0, want 2`; M9 (function-present check deleted) → `renamed: missing reason: …`; `meta: 9 weakenings caught`, `rc=0` |
| 13 | A no-op mutation exits 3 from the script | `sed '/^mutate map /s/\\1EARTH_LOG_MINOR/\\1SESSION_MINOR/' tools/session_minor_guard_controls.sh > /tmp/7al_noop.sh; MAKE=make sh /tmp/7al_noop.sh . >/dev/null; echo rc=$?` | `session-minor-guard-controls: map: mutation left main.gd unchanged` on stderr, `rc=3` |
| 14 | Robust to make flags, GNU make, dash; shellcheck (macOS userland) | the AC14 block below | every controls run ends `session-minor-guard-controls: 19 rejected, 3 accepted`; dash guard `rc=0`; dash controls `19 rejected, 3 accepted`; both shellchecks silent |
| 15 | The tree is never modified; no temp dirs left | the AC15 block below | `unchanged`, then `0` |
| 16 | Hygiene | `make uid-guard python-guard script-gate-lint audio-silent-guard; echo rc=$?; git diff --check origin/main; echo rc=$?` | `uid-guard: ok`, `python-guard: ok`, `script-gate-lint: ok`, `audio-silent-guard: ok`, `rc=0`, `rc=0` |
| 17 | Diff scope | `git diff --name-only origin/main` | exactly the nine paths in "Files touched", plus the landing's changelog fragment, `design_docs/` and `.ailang/state/` files |
| 18 | No conflict with attended #412 | the AC18 block below | `conflicts=0` twice |
| 19 | **PRE-LANDING, GNU userland (kimi-k3):** the guard and controls pass on GitHub's `ubuntu-latest` fast tier (GNU sed and grep, mawk, dash, GNU make) | the sprint pushes its branch and opens a **draft** PR (`gh pr create --draft`); then the AC19 block below, on the PR head | `success <head sha>`; then `2`, the two matching lines being `session-minor guard: ok, SESSION_MINOR (18) = EARTH_LOG_MINOR; …; 4 test comparisons name it` and `session-minor-guard-controls: 19 rejected, 3 accepted` (each after the runner's timestamp). **The PR does not leave draft until this holds.** A red or missing run blocks landing (Risks) |
| 20 | The production comparisons are still the enumerated one (V18, V23) | the AC20 block below | first command: only the five `want_minor` assignment lines of V18 (`demos/black_hole_visit.gd:52`, `demos/ship_geometry_demo.gd:1025`, `main.gd:258`, `:304`, `:414`), with `SESSION_MINOR` at `:1025` and `:304`; second: exactly `demos/ship_consoles.gd:1186` (or its moved line) and the two `bridge/` validity reads. Any new production comparison of a session minor must be added to the scan or recorded as a blind spot before landing |

AC9 (outside the table so the `|` is literal):

```sh
make -n ci-fast 2>/dev/null | grep -cE 'session_minor_guard_controls\.sh|SESSION_MINOR := '
grep -nE '^(test|ci-fast): session-minor-guard session-minor-guard-controls$' Makefile
make -pq 2>/dev/null | grep -E '^ci-fast:' | tr ' ' '\n' | grep -c .
make -pq 2>/dev/null | grep -E '^ci-fast:' | tr ' ' '\n' | grep -nx -e session-minor-guard -e session-minor-guard-controls
```

AC14:

```sh
for m in make gmake; do for f in '' -n -j4 -k; do $m $f session-minor-guard-controls 2>&1 | tail -n 1; done; done
gmake SHELL=/bin/dash session-minor-guard >/dev/null; echo rc=$?
MAKE=gmake dash tools/session_minor_guard_controls.sh . | tail -n 1
shellcheck tools/session_minor_guard_controls.sh && shellcheck -s dash tools/session_minor_guard_controls.sh
```

AC15:

```sh
h=$(shasum bridge/sim_bridge.gd main.gd demos/ship_geometry_demo.gd ui/loading_jump.gd tests/test_*.gd Makefile | shasum); make -s session-minor-guard-controls >/dev/null; test "$h" = "$(shasum bridge/sim_bridge.gd main.gd demos/ship_geometry_demo.gd ui/loading_jump.gd tests/test_*.gd Makefile | shasum)" && echo unchanged; find "${TMPDIR:-/tmp}" -maxdepth 1 -name 'session-minor-guard.*' | wc -l
```

AC18 (`B` is the merge base with #412; both files are merged three-way into #412's versions):

```sh
B=$(git merge-base origin/main origin/feat/captain-command); for f in demos/ship_geometry_demo.gd Makefile; do git show origin/feat/captain-command:$f > /tmp/7al_pr; git show $B:$f > /tmp/7al_base; git merge-file -p /tmp/7al_pr /tmp/7al_base $f > /dev/null; echo conflicts=$?; done
```

AC19. Job logs are fetched through the API: `gh run view --log` can refuse output with terminal escape sequences, and that refusal is an instrument failure, not an empty log. The API call needs `--allow-escape-sequences`, and the ANSI colour codes are stripped before matching. V20 ran this exact pipeline on main's run `42991331626` as a positive control, where it found 7ah's two lines.

```sh
SHA=$(git rev-parse HEAD); R=sunholo-data/stapledons-godot
RUN=$(gh run list -R $R --workflow ci.yml --commit "$SHA" --event pull_request --limit 1 --json databaseId --jq '.[0].databaseId')
gh run view "$RUN" -R $R --json conclusion,headSha --jq '.conclusion+" "+.headSha'
JOB=$(gh run view "$RUN" -R $R --json jobs --jq '.jobs[0].databaseId')
E=$(printf '\033'); gh api --allow-escape-sequences repos/$R/actions/jobs/$JOB/logs | LC_ALL=C sed "s/$E\[[0-9;]*m//g" | grep -cE 'session-minor guard: ok, SESSION_MINOR \(18\) = EARTH_LOG_MINOR; .* 4 test comparisons name it$|session-minor-guard-controls: 19 rejected, 3 accepted$'
```

AC20:

```sh
git grep -nE '(want_minor|hello_reply\.proto\.minor) *[=!<>]=? *SimBridge\.[A-Z0-9_]+_MINOR' -- demos/ main.gd ui/ interior/ sky/ bridge/
git grep -nE 'get\("minor"' -- demos/ main.gd ui/ interior/ sky/ bridge/
```

## Sub-milestones and estimates

| # | What | LOC | Depends | Order |
|---|---|---:|---|---|
| T1 | Write `tools/session_minor_guard_controls.sh` and the two make targets. On today's tree, which has no `SESSION_MINOR`, the guard is expected to fail with `SESSION_MINOR unresolved` and the controls at `pristine` (red first; not run for this doc) | ~223 | none | 1 |
| M1 | The constant, the three site tokens and the four test comparisons. AC1–AC8 go green | ~12 | T1 | 2 |
| M4 | The `test` and `ci-fast` edges | 2 | M1 | 3. AC9 (local half) |
| V | AC10–AC18 and AC20, meta-drills; Godot rows on a warm compile | 0 | M4 | 4 |
| G | Push, open a **draft** PR, then AC19 on the PR head; AC9's GitHub evidence on the final commit | 0 | V | 5. The PR leaves draft only after this |

## Risks and mitigations

- **A function is renamed or split** (`_run_map`, `_create_navigation`, `_work_sim`). The guard fails loudly: `has no func NAME(` for a rename (control `renamed`), `mentions <token> 0 times` for a split that moves the ask. The fix is one word in the recipe's site list and in the script's range. As in 7ah, an explicit anchor is better than a whole-file scan.
- **A site function becomes the last in its file, or a `static func` follows it.** Revision 1 handles both: the range must end at a top-level line (control `unbounded`), and a `static func` ends it (control `stray`).
- **A fourth prefetch session appears** (a new title route). The guard does not know it exists. The loading-jump route checks catch it at night only if the new route is added to `test_routes`. The site list is one line to extend.
- **`SESSION_MINOR` duplicates a number.** `const SESSION_MINOR := 18` sits beside `EARTH_LOG_MINOR := 18`. The guard requires the value to equal a defined constant (control `orphan`), and its ok line names the match. If a bump author adds `FOO_MINOR := 19` and forgets `SESSION_MINOR`, every session stays at 18 together. The prefetch still works, and the new feature's own tests fail, which is their job. That is the intended trade (Non-goals, b″).
- **A test reads the session minor in another form** (`journey_sim.get("want_minor")`, or a local variable). The scan does not see it. Such a test still works at a bump unless it names a moving constant. V18 found no such form in `tests/` today, the four known forms are covered, and the scan is known-positive (control `notests`).
- **Production comparisons are a documented blind spot (V18, V23).** The scan reads `tests/*.gd` only. The one production comparison, `demos/ship_consoles.gd:1186` (`… .get("minor", 0)) >= SimBridge.EARTH_LOG_MINOR`), is a feature floor that stays true at every bump, so it is correct as written. If `SESSION_MINOR` ever fell below 18, `_ask_weeks` would silently send nothing. The nightly backstop is `comms-station-test`, whose `:133` check keeps `SESSION_MINOR >= SimBridge.EARTH_LOG_MINOR`. AC20 re-enumerates at the sprint.
- **The lexical limit remains at merge time.** A write the text does not show passes the guard. The nightly loading-jump pid checks and `test_ship_ui.gd:416` catch it at runtime (V2, V7). That is the accepted split: lexical in `ci-fast`, runtime where Godot runs.
- **`make -n` runs the controls line** (a `$(MAKE)` line), as in 7ah. They are read-only and take under 4 s (V21).
- **The fast-tier runner (Ubuntu: GNU sed and grep, mawk, dash, GNU make).** Locally only BSD userland, dash and GNU Make 4.4.1 were available (V21); this host has no GNU sed, gawk or GNU grep and no docker, and installing software was out of bounds. Revision 1 removed the constructs that differ (M3, "Portability"), and AC19 measures the runner before the PR leaves draft. The `ci-fast` guard and controls edges are mandatory acceptance requirements. A runner/environment failure blocks landing; fix the dependency or invocation and rerun the GitHub fast-tier check. Do not remove either edge or suppress its failure. If the runner cannot support these checks, revise this design with a verified replacement that enforces the same invariant on every PR before proceeding.

## Open questions for the user

None. Nothing a player sees changes, and the constant's value is today's.

## Follow-ups (new findings, not scope)

- **F1. `test_sim_warm` conflates two refusals.** `tests/test_loading_jump.gd:157–163` checks "a start() with a launch override or another minor leaves the warm sim" with one bridge that has both. A regression that made `_adopt_warm` ignore the minor would still pass that check (the launch override alone refuses). The probe in V2 isolates the minor; two one-line checks would cover each refusal separately. Headless, test-only.
- **F2. 7ah's `similar-main-guard` has the same range-end hole.** It reads `_run_map` with `/^func _run_map(/,/^func /`, so a `static func` placed after `_run_map` is read as part of it (main.gd has 3 `static func`s, V22). Its count check makes a moved ask plus the real ask fail closed (2 mentions), but an ask moved entirely into such a `static func` would pass. The fix is this row's top-level range end plus a `stray` control. It belongs to 7ah's guard, so it is a separate row and is not edited here (Non-goals).
- **F4 (r2, kimi-k3, non-blocking). The scan sees two syntactic forms.** A test that writes the constant first (`SimBridge.<NAME>_MINOR == journey_sim.want_minor`) or reads the minor through another expression is not scanned; none exists today (controller, round 2). Options: a committed `session-minor-audit` target running the AC20 sweep in `make test`, or a second constant-on-left pass in step 4 with its own control.

## Deliverables

- `bridge/sim_bridge.gd` `SESSION_MINOR`; the three site tokens; the four test comparisons.
- `Makefile`: `session-minor-guard`, `session-minor-guard-controls` and their `test` and `ci-fast` edges (Appendix A).
- `tools/session_minor_guard_controls.sh` (Appendix B).
- Evidence for AC1–AC20 in the sprint JSON, including the meta-drill log (AC12), the draft PR's fast-tier run id and log lines (AC19), and the final commit's run (AC9).

## Verification log

Run on 2026-11-11 in `stapledons-godot-iter87-7al` at `origin/main` `8334b124`, on the Studio under shared load (load 10–155 over the session; noted where it matters). Tools: Godot `4.7.2.stable.official.ed1daf0bf`, AILANG `v0.56.1` (commit `05c860a`, the main checkout's `runtime/bin`; the clone has no `runtime/bin`), macOS make (GNU Make 3.81), `gmake` 4.4.1, `/bin/dash`, BSD `sed` and `awk`. **Assets:** the clone had no `.godot` import, so `godot --headless --path . --import` ran first (rc 0, 43 s; 7 pre-existing CSV-translation errors). `data/lens/lens_fwd.bin` and `lens_inv.bin` (untracked, `.gitignore:34`) were missing, so `bh-hud` failed 7 checks with `gr lens: lens_fwd missing`. They were **symlinked** from the main checkout's `data/lens/`, and `sh tools/lens_assets.sh verify` reported `tables match data/lens/SHA256SUMS`; the symlinks are left in the clone. The first two Godot runs failed at `startup_timeout` (cold sim compile at load 60–155, as the controller warned); the warm runs below are the measurements. The prototype was applied, measured, and reverted; `git status --porcelain` was empty before the doc commit. **Revision 1** (rows V18–V22, and V17 re-run) was measured the same day in the same clone at the same `origin/main`, on the rebuilt revision-1 prototype (load about 10–15). It was reverted again before the revision-1 commit. Rows marked (r0) are revision 0 readings; where revision 1 changed the thing measured, V21 supersedes them.

| # | Command | Result |
|---|---|---|
| V1 | `git grep -n want_minor -- main.gd`; `git grep -n 'want_minor' -- demos/ ui/`; `git grep -n 'SimBridge.warm(' -- '*.gd'` | `main.gd:304` `if not capture:sim.want_minor=SimBridge.EARTH_LOG_MINOR # R3-COMMS-V2: 2.18 (as the ship; …) … so it adopts the loading jump's prefetch …` (also `:258`, `:280`, `:414`, not prefetch sessions); `demos/ship_geometry_demo.gd:1025` `journey_sim=SimBridge.new();journey_sim.want_minor=SimBridge.EARTH_LOG_MINOR # …`; `demos/black_hole_visit.gd:52` `GR_MINOR`; `SimBridge.warm(` only at `ui/loading_jump.gd:254` (`SimBridge.warm(SimBridge.EARTH_LOG_MINOR)`) and `tests/test_loading_jump.gd:153,169` (positive control: the test's own two calls are found) |
| V2 | `sed -n 228,233p bridge/sim_bridge.gd`; scratch probe `/tmp/stap_i87_7al/probe_warm.gd` (warm 18, offer, a default `start()` at 16, then at 18; 5 rounds) run headless; `tests/test_loading_jump.gd` headless, baseline then each site mutated to `EARTH_MINOR` in the tree (`sed -i ''`, run, `git checkout --`) | `:232` `if w == null or not launch_override.is_empty() or record_path != "" or w.want_minor != want_minor: return false`. Probe, load 41→23: 5/5 `minor 16 vs warm 18: start=true adopted=false warm_left=true spawn+hello` 5103, 4444, 3981, 3953, 4166 ms, `negotiated 16`; 5/5 `minor 18 … adopted=true warm_left=false adopt` 0.0–0.1 ms, `negotiated 18`. Route runs: baseline `77 passed, 0 failures` (51 s, load 21); map mutated `76 passed, 1 failures` (`FAIL map: the map's simulation is the prefetched one`); ship mutated `75 passed, 2 failures` (ship, guided); prefetch mutated `74 passed, 3 failures` (ship, guided, map). Build-blocked figures as in Problem §2, from each run's `loading-jump: <route> ready after … (build blocked … ms)` line |
| V3 | `sed -n 49,57p ui/loading_jump.gd` (the `sim` stage figures) | `["sim", "Starting the simulation", "thread", 540.0]` (ship and guided), `545.0` (map); the comment dates them 2026-10-08. Not re-measured (no quiet host) |
| V4 | `sed -n 41,42p .github/workflows/ci.yml`; `sed -n 59,61p .github/workflows/ci.yml`; `grep -n 'loading-jump-test' Makefile` | `- name: Install Godot` / `if: ${{ inputs.full }}`; `- name: make ci-fast` / `if: ${{ !inputs.full }}`: the fast tier has no Godot. `Makefile:1238` `test: loading-jump-test` (nightly only) |
| V5 | the V5 block below the table | `tests/test_bh_hud.gd:109`, `:115` (`v.sim.want_minor == SimBridge.GR_MINOR`, the black-hole session), `:176`; `tests/test_comms_station.gd:133`; `tests/test_ship_ui.gd:416` (`hello_reply.proto.minor == SimBridge.EARTH_LOG_MINOR`); `tools/similar_guard_controls.sh:118` (a 7ah mutation string). So there are exactly four `journey_sim` comparisons |
| V6 | on `origin/main` (prototype stashed): `demos/ship_geometry_demo.gd:1025` → `WORLDS_MINOR`, `tests/test_bh_hud.gd` headless, then `git checkout --` | `FAIL a normal navigation session has no gr …`, `FAIL navigation after the visit is a normal 2.8 session without gr`, `bh-hud: 62 passed, 2 failures` (64/0 unmutated, V15) |
| V7 | `sed -n 280,290p tests/test_loading_jump.gd` (read) | the route checks compare `demo.journey_sim.child_pid == r["warm_pid"]` and `m3.sim.child_pid == r["warm_pid"]`: the live child, independent of how `want_minor` was written |
| V8 | the V8 block below the table (each function's range, then a literal count of its token) | `main.gd _run_map` 96 lines, `want_minor`=1; `demos/ship_geometry_demo.gd _create_navigation` 55 lines, `want_minor`=1; `ui/loading_jump.gd _work_sim` 6 lines, `warm(`=1, `want_minor`=0; the functions start at `main.gd:302`, `demos/…:1022`, `ui/loading_jump.gd:253` |
| V9 | (r0) prototype: `make session-minor-guard`; `time make -s session-minor-guard`; AC3–AC7 commands verbatim | the AC1 ok line, rc 0, 0.086 s; AC3 rc 2 `main.gd _run_map does not ask SimBridge.SESSION_MINOR`; AC4 rc 2 `demos/ship_geometry_demo.gd _create_navigation does not ask …`; AC5 rc 2 `ui/loading_jump.gd _work_sim does not ask …`; AC6 rc 2 `tests/test_comms_station.gd compares journey_sim's minor with SimBridge.EARTH_LOG_MINOR, not SESSION_MINOR`; AC7 rc 0 `ok, SESSION_MINOR (17) = WORLDS_MINOR; …`; the guard was ok again after each `mv` back, and no `.bak` was left |
| V10 | (r0, superseded by V21) prototype: `time make session-minor-guard-controls` | rc 0, 3.64 s wall (load ~12); the 16 case lines of the M3 table, ending `session-minor-guard-controls: 13 rejected, 3 accepted`; every guard branch exercised |
| V11 | (r0, superseded by V21) the r0 meta-drill file (since overwritten by revision 1's Appendix C) as `/tmp/stap_i87_7al/meta.sh`, `ROOT` = the clone with the prototype | `meta base: rc 0 :: … 13 rejected, 3 accepted`; `M1_noask: rc 2 :: …map: make rc 0, want 2`; `M2_nocount: … twice: make rc 0, want 2`; `M3_noname: … orphan: …`; `M4_notest: … testname: …`; `M5_noscan: … notests: …`; `M6_prefix: … arith: …`; `meta: 6 weakenings caught`, rc 0. (The first run expected M2 at `removed`; it is caught earlier, at `twice`, and the expectation was corrected) |
| V12 | (r0, superseded by V21) AC14 block; `sh tools/session_minor_guard_controls.sh` (no argument); the AC13 no-op variant | 8/8 make variants end `13 rejected, 3 accepted`; `gmake SHELL=/bin/dash session-minor-guard` rc 0; `MAKE=gmake dash tools/session_minor_guard_controls.sh .` `13 rejected, 3 accepted`; shellcheck and `-s dash` silent (rc 0). No argument: rc 1, `…: 1: usage: session_minor_guard_controls.sh ROOT`. No-op: `session-minor-guard-controls: map: mutation left main.gd unchanged`, rc 3 |
| V13 | `sed -n 714,716p sim/protocol_test.ail` | `test "S0.2 negotiation preserves 13..18 and caps 99 at 18 …"`, `map(helloMinor, [13, …, 99]) == [13, …, 18, 18]`: an ask above the sim's maximum is answered with the maximum |
| V14 | prototype: the V14 block below the table | `similar-test guard: ok, main.gd _run_map asks SESSION_MINOR (18) >= SIMILAR_MINOR (14)` rc 0; `similar-guard-controls: 13 rejected, 3 accepted`; 0 committed consumers of 7ah's literal ok text (2 design docs quote it) |
| V15 | (r0 product and test edits, byte-identical in r1, V21) prototype, headless: `tests/test_loading_jump.gd`; then `SESSION_MINOR := 17` (one line) and `tests/test_loading_jump.gd` and `tests/test_bh_hud.gd` again; `tests/test_comms_station.gd`, `tests/test_bh_hud.gd`, `tests/test_ship_ui.gd` at 18; AC9 and AC16 commands; `git diff --stat` | `loading-jump: 77 passed, 0 failures` (64 s; map build blocked 621 ms, adopted); at 17: `77 passed, 0 failures` (all three routes adopted; map 544 ms) and `bh-hud: 64 passed, 0 failures`; at 18: `comms-station: 42 passed, 0 failures` (`ok the session asks SESSION_MINOR (2.18 or later) …`), `bh-hud: 64 passed, 0 failures`, `ship-ui: 288 passed, 0 failures` (`ok AC17 real protocol-2.8 world …`); AC9 count `2`, lines 145 and 146; `uid-guard: ok (422 .uid files)`, `python-guard: ok (21 allowlisted, 0 awaiting AILANG port)`, `script-gate-lint: ok`, `audio-silent-guard: ok`, rc 0; `git diff --check` rc 0; `8 files changed, 48 insertions(+), 7 deletions(-)` plus the new 152-line script. AC15: `unchanged`, `0` leftover temp dirs (after the controls and the meta-drills) |
| V16 | the V16 block below the table (`git`, not `gh pr diff`) | #412 head `3926f4f3`, 46 files including `demos/ship_geometry_demo.gd` and `Makefile`, not `main.gd`, `ui/loading_jump.gd`, `bridge/` or the four tests. Ship-demo hunks: `-239,0`, `-431,0`, `-526`, `-548,0`, `-993`, `-997`, `-1012,0 +1018,3` (`_place_navigation`), `-1057,0 +1066,2` (`_create_navigation`), `-1098,0`, … `-1851,0`, `-1861,0`, `-1864,0`; none within 3 lines of 1025. `_MINOR` lines in #412: **0**; #379 positive control: 25; `consoles.command`: 48. On #412's head, `_create_navigation` has 1 `want_minor`, the line `journey_sim.want_minor=SimBridge.EARTH_LOG_MINOR` (at `:1033`), and the tests have the same four comparisons. `git merge-file`: ship file `conflicts=0` (the only difference from #412's file is the one token), Makefile `conflicts=0` against #412, #380 (`68e4ca6d`) and #373 (`e37b3579`). #412's Makefile hunk is `@@ -34,0 +35 @@`; #380/#373's are at 13, 21, 23, 24, 228 (+247 for #380). Guard on the #412 merge: ok, rc 0 |
| V17 | (r1) extract Appendices A, B and C from this doc with `awk`; `cmp` A against the revision-1 Makefile block, B against the revision-1 script and C against the meta-drill file run in V21; rebuild the Makefile from `origin/main`'s by inserting A after `:133`, then `git apply /tmp/stap_i87_7al/proto_r1.patch` and `cmp` | all three byte-identical; the rebuilt Makefile and the extracted script equal the revision-1 prototype's (`cmp` silent); Appendix C, run from the doc's copy, gives `meta: 9 weakenings caught`; reverted |
| V18 | (r1, glm-5.3) the V18 block below the table: `sed -n '1180,1195p' demos/ship_consoles.gd`; the production comparison sweep over `demos/ main.gd ui/` (extended to `interior/ sky/ bridge/` in AC20); the `get("minor"` read sweep, with `tests/` as the positive control; every `SimBridge.*_MINOR` in production outside `want_minor =` and `warm(` lines; the `journey_sim` minor reads in `tests/` in any form; the same line on #412's head | `:1186` (in `func _ask_weeks(a: int, b: int) -> void:`, after `var sim = demo.get("journey_sim") if demo != null else null`) is `if sim is SimBridge and int((sim as SimBridge).hello_reply.get("proto", {}).get("minor", 0)) >= SimBridge.EARTH_LOG_MINOR:`, followed by `(sim as SimBridge).send([{"k": "earth_weeks", "from": a, "to": b}], 0.0)`. Sweep: only assignments (`demos/black_hole_visit.gd:52` `GR_MINOR`, `demos/ship_geometry_demo.gd:1025`, `main.gd:258`, `:304`, `:414`) and no comparison. The `get("minor"` reads are `bridge/ai_relay.gd:77` (`>= 1`, AI relay enable), `bridge/sim_bridge.gd:268` (`_is_count`, hello validity) and `demos/ship_consoles.gd:1186`; the positive control in `tests/` finds `tests/test_sim_bridge.gd:97,108,341,394,447` (`:341,394,447` compare `s`'s minor with `SYSTEM_MINOR`, `NAV_MINOR` and `GR_MINOR`). Outside assignments, the only production `SimBridge.*_MINOR` is `demos/ship_consoles.gd:1186`. `journey_sim` minor reads in `tests/`, any form: `test_bh_hud.gd:109,176`, `test_comms_station.gd:133` (`want_minor`), `test_ship_ui.gd:416` (`hello_reply.proto.minor`), and no `get("minor")` form. On #412's head the line is at `:1276`, the file's only `SimBridge.*_MINOR`. So there is no production equality on a session minor and no production comparison naming the session constant |
| V19 | (r1, glm-5.3) `ci-fast`'s prerequisites on `origin/main` and on the revision-1 prototype (the AC9 block); `make session-minor-guard session-minor-guard-controls` | `origin/main`: 21 prerequisites (`stellar-protocol-test deps python-guard audio-silent-guard uid-guard lint-precision strict parity-v2 parity parity-gr replay crew-sync-check crew-parity lore-import-check capture-m4-publish-test similar-main-guard similar-guard-controls replay-map-index script-gate-lint script-gate-selftest`). Prototype: 23, with `session-minor-guard` 19th and `session-minor-guard-controls` 20th; `make -n ci-fast` shows 2 of the new recipe lines; rule lines 147 and 148. Both new targets run green (V21). The rest of `ci-fast` (deps, strict VM, parity, replay; about 10 min) was not run here; the PR's GitHub run covers it (AC9, AC19) |
| V20 | (r1, kimi-k3, AC19 instrument) the AC19 pipeline on main's latest fast-tier run, `42991331626` (head `8334b124`), matching 7ah's two lines instead of this row's; `gh api --help`, `gh run list --help`; `grep -n runs-on .github/workflows/ci.yml` | `success 8334b1248bda1a7188d7d5b7db34239e8ed921b8`; job `130424691758`; the log has 469 lines; after ANSI stripping it contains `2026-11-11T09:19:50.7938605Z similar-test guard: ok, main.gd _run_map asks EARTH_LOG_MINOR (18) >= SIMILAR_MINOR (14)` and `2026-11-11T09:19:51.2362157Z similar-guard-controls: 13 rejected, 3 accepted`. So the instrument works (a positive control), and 7ah's controls already pass on the runner: its `sed -E` `$a\` appends and backslash-newline inserts are fine under GNU sed, though revision 1 avoids them anyway. `gh api` has `--allow-escape-sequences`; `gh run list` has `-c/--commit` and `-e/--event`. The job runs on `ubuntu-latest`. On this prototype output with a timestamp prefix added, the AC19 grep counted `2` |
| V21 | (r1) prototype rebuilt from revision 0's product and test edits (`git apply --exclude=Makefile --exclude=tools/session_minor_guard_controls.sh proto.patch`) plus Appendix A and Appendix B: `git apply --check -R` of the same exclusion; `make session-minor-guard`; `time make session-minor-guard-controls`; Appendix C; the AC14 block; AC3–AC9, AC13, AC15, AC16, AC18 commands; `git merge-file` of the Makefile against #380 and #373; `git diff --numstat Makefile` | product and test edits identical to revision 0's. Guard: the AC1 ok line, rc 0. Controls: the 19 case lines of the M3 table in order (`renamed`, `unbounded` and `stray` rejected with their exact lines), `session-minor-guard-controls: 16 rejected, 3 accepted`, rc 0, 1.70 s. Appendix C: `meta base: rc 0 :: … 16 rejected, 3 accepted`; M1 `map`, M2 `twice`, M3 `orphan`, M4 `testname`, M5 `notests`, M6 `arith`, M7_funcend `stray: make rc 0, want 2`, M8_nobound `unbounded: make rc 0, want 2`, M9_nofunc `renamed: missing reason: session-minor guard: ui/loading_jump.gd has no func _work_sim(`; `meta: 9 weakenings caught`, rc 0. All 8 make/gmake × `''`/`-n`/`-j4`/`-k` runs end `16 rejected, 3 accepted`; `gmake SHELL=/bin/dash session-minor-guard` rc 0; `MAKE=gmake dash …` and `gmake SHELL=/bin/dash session-minor-guard-controls` both `16 rejected, 3 accepted`. shellcheck first flagged SC2016 on `stray`'s awk `$0` (info); a `# shellcheck disable=SC2016` line was added above it, and then both shellchecks were silent. AC3–AC7 as in V9; AC8 `asks SESSION_MINOR (18)` and `13 rejected, 3 accepted`; AC9 `2`, lines 147/148, 23 prerequisites; AC13 rc 3; AC15 `unchanged`, `0`; AC16 all ok, `git diff --check` rc 0; AC18 `conflicts=0` twice; #380 and #373 `conflicts=0`; Makefile `40 0`. The controls contain no `a\`, `{…}` block or tab character (`grep -cP '\t'` = 0). Reverted; `git status --porcelain` empty |
| V22 | (r1) the V22 block below the table: each site's range with the old (`^func `) and the new (`^[^[:space:]#]`) end; `grep -c '^static func'` and `grep -c '^func '` per file | `main.gd _run_map` 96/96 lines, identical, ends at `func _run_interior(…`; `demos/ship_geometry_demo.gd _create_navigation` 55/55, identical, ends at `func start_solar_departure() -> bool:`; `ui/loading_jump.gd _work_sim` 6/6, identical, ends at `func _warm_optics() -> void:`. `static func`: main.gd 3, ship demo 7, loading jump 5 (`func`: 48, 129, 20) |
| V23 | (r2, glm-5.3; controller, 2026-11-11, `8334b124`) the V23 block below the table: glm's two `bridge/` sweeps, with two controls in the same call (the first pattern over `tests/`; the bare-constant assignment form over `bridge/`) | both `bridge/` sweeps empty (rc 1); controls fire: the `tests/` sweep hits `test_bh_hud.gd` 3, `test_bridge_monitors.gd` 1, `test_comms_station.gd` 1, `test_crew_console.gd` 3, `test_crew_hold.gd` 3 (first five files), and `bridge/sim_bridge.gd:131:var want_minor := PROTO_MINOR`. `bridge/` holds no comparison of a minor with a protocol constant in either form; `_adopt_warm`'s `w.want_minor != want_minor` (`:232`) compares two variables. Measured on `origin/main`; the prototype adds only the definition `const SESSION_MINOR := 18` to `bridge/` |
| V24 | (r2) the three revision-2 controls (`missbridge`, `misssite`, `brokentest`), the revision-2 `notests` mutation and Appendix A's captured grep status | **UNMEASURED at design time**: the controller applied the reviewers' fixes under the narrow-refinement carve-out and did not rebuild the prototype. The sprint measures them: AC2's 22 case lines ending `19 rejected, 3 accepted`, on macOS (AC14) and on the runner (AC19). If BSD or GNU grep does not exit 2 on the dangling symlink, `brokentest` fails and the sprint replaces the symlink with an unreadable file (`chmod 000`), recording which. Partial probe (controller): `grep` on this rig's PATH is ugrep 7.8.4; on a dangling symlink beside a matching file it prints the match and exits 2; a match exits 0; no match exits 1 |

V5:

```sh
git grep -nE '(want_minor|proto\.minor|"minor"\)?) *(==|>=|!=) *SimBridge\.[A-Z_]+_MINOR' -- tests/ tools/
```

V14:

```sh
make similar-main-guard
make -s similar-guard-controls | tail -1
git grep -c 'asks EARTH_LOG_MINOR' -- Makefile 'mk/*.mk' tools/ tests/ .github/ | wc -l   # 0
git grep -l 'asks EARTH_LOG_MINOR' -- design_docs/ | wc -l                               # 2 (positive control)
```

V16:

```sh
git fetch -q origin
git diff --name-only origin/main...origin/feat/captain-command
git diff -U0 origin/main...origin/feat/captain-command -- demos/ship_geometry_demo.gd | grep '^@@'
git diff origin/main...origin/feat/captain-command | grep -cE '^[+-].*(want_minor|_MINOR)'      # 0
git diff 8ba1e3c8^1 8ba1e3c8 | grep -cE '^[+-].*(want_minor|_MINOR)'                             # 25 (positive control, #379)
git diff origin/main...origin/feat/captain-command | grep -cE '^[+-].*consoles\.command'          # 48 (positive control, #412)
git show origin/feat/captain-command:demos/ship_geometry_demo.gd | sed -n '/^func _create_navigation(/,/^func /p' | grep -c want_minor   # 1
git grep -nE 'journey_sim\.(want_minor|hello_reply\.proto\.minor) *[=!<>]=? *SimBridge\.' origin/feat/captain-command -- tests/
# then the AC18 block for both files, the same git merge-file for the Makefile against
# origin/feat/r2-kerr-table-preflight and origin/feat/r2-kerr, and make session-minor-guard on a
# root whose demos/ship_geometry_demo.gd is the #412 merge-file output
```

V8 (zsh; the count is the guard's own awk `index` loop):

```sh
for spec in main.gd:_run_map:want_minor demos/ship_geometry_demo.gd:_create_navigation:want_minor ui/loading_jump.gd:_work_sim:'warm(' ui/loading_jump.gd:_work_sim:want_minor; do f=${spec%%:*}; r=${spec#*:}; fn=${r%%:*}; tok=${r#*:}; body=$(sed -n "/^func $fn(/,/^func /p" $f); echo "$f $fn lines=$(printf '%s\n' "$body" | wc -l | tr -d ' ') $tok=$(printf '%s\n' "$body" | awk -v t="$tok" '{ s=$0; while ((i = index(s, t)) > 0) { n++; s = substr(s, i + length(t)) } } END { print n + 0 }')"; done
git grep -n -e 'func _run_map(' -e 'func _create_navigation(' -e 'func _work_sim(' -- main.gd demos/ship_geometry_demo.gd ui/loading_jump.gd
```

V18 (r1):

```sh
sed -n '1180,1195p' demos/ship_consoles.gd
git grep -nE '(want_minor|hello_reply\.proto\.minor) *[=!<>]=? *SimBridge\.[A-Z0-9_]+_MINOR' -- demos/ main.gd ui/
git grep -nE 'get\("minor"' -- demos/ main.gd ui/ bridge/ interior/ sky/
git grep -nE '\.minor\b|get\("minor"' -- tests/ | head -5                      # positive control for the read pattern
git grep -nE 'SimBridge\.[A-Z0-9_]+_MINOR' -- demos/ main.gd ui/ interior/ sky/ | grep -vE 'want_minor *= *SimBridge|warm\(SimBridge'
git grep -nE 'get\("minor"\)? *[=!<>]=? *(float|int)?\(?SimBridge\.[A-Z0-9_]+_MINOR' -- tests/
git grep -nE 'journey_sim[^ ]*minor|journey_sim\.hello_reply' -- tests/
git show origin/feat/captain-command:demos/ship_consoles.gd | grep -nE 'SimBridge\.[A-Z0-9_]+_MINOR'
```

V22 (r1, zsh):

```sh
for s in "main.gd _run_map" "demos/ship_geometry_demo.gd _create_navigation" "ui/loading_jump.gd _work_sim"; do set -- ${=s}; a=$(sed -n "/^func $2(/,/^func /p" $1); b=$(sed -n "/^func $2(/,/^[^[:space:]#]/p" $1); echo "$1 $2 old=$(printf '%s\n' "$a" | wc -l) new=$(printf '%s\n' "$b" | wc -l) same=$([ "$a" = "$b" ] && echo yes || echo no) last=[$(printf '%s\n' "$b" | tail -n 1)]"; done
for f in main.gd demos/ship_geometry_demo.gd ui/loading_jump.gd; do echo "$f static_func=$(grep -c '^static func' $f) func=$(grep -c '^func ' $f)"; done
```

V23 (r2, controller, zsh; the two sweeps are glm-5.3's, then the controls):

```sh
git grep -nE '(want_minor|hello_reply\.proto\.minor) *[=!<>]=? *SimBridge\.[A-Z0-9_]+_MINOR' -- bridge/; echo rc=$?
git grep -nE '(want_minor|hello_reply\.proto\.minor|\bminor\b) *[=!<>]=? *[A-Z][A-Z0-9_]*_MINOR\b' -- bridge/; echo rc=$?
git grep -cE '(want_minor|hello_reply\.proto\.minor) *[=!<>]=? *SimBridge\.[A-Z0-9_]+_MINOR' -- tests/ | head -5
git grep -nE 'want_minor *:?= *PROTO_MINOR' -- bridge/
```

## Quorum verification log

Design-quorum round 1 BLOCKED revision 0 3/3 on narrow, fixable points. Option (b), one constant plus a lexical guard in `ci-fast`, was not disputed. The controller measured two premises before the revision; the designer re-ran both (V18, V20 and the host check below). Each objection, and how revision 1 answers it:

| Reviewer | Objection | Premise check | Answer in revision 1 |
|---|---|---|---|
| glm-5.3 | `demos/ship_consoles.gd:1186` was asserted, not read, and V5's comparison sweep left out `demos/`, `main.gd` and `ui/` | **Confirmed.** Revision 0 quoted the floor from a grep line and swept only `tests/` and `tools/`. Controller reading: `:1186` is `if sim is SimBridge and int((sim as SimBridge).hello_reply.get("proto", {}).get("minor", 0)) >= SimBridge.EARTH_LOG_MINOR:`, the file's only `SimBridge.*_MINOR`, at `:1276` on #412's head. Re-read by the designer: identical (V18) | Added **V18**: `sed -n '1180,1195p'`, the sweep over `demos/ main.gd ui/` (and `bridge/ interior/ sky/` in AC20), and a `get("minor"` read sweep with `tests/` as its positive control. The Non-goals bullet now quotes the read line. The goal is restated as "measured against the enumerated comparisons (V5, V18)". The sweep found no production equality on a session minor and nothing naming the session constant; the one comparison is a `>=` feature floor. So step 4's scan stays on `tests/`, and the floor is listed as a **documented blind spot** with its nightly backstop named (`comms-station-test`'s `SESSION_MINOR >= EARTH_LOG_MINOR`; Risks). **AC20** re-runs the enumeration at the sprint |
| glm-5.3 | The new `ci-fast` edges were not evidenced locally | Revision 0 showed the edge lines and a `make -n ci-fast` count, but did not enumerate `ci-fast`'s prerequisites | **V19**: `ci-fast` has 21 prerequisites on `origin/main` and 23 on the prototype, with the two new targets 19th and 20th. `make -n ci-fast` shows their recipe lines, and both targets run green. The rest of `ci-fast` (about 10 min of deps, strict VM, parity and replay) was not run on this loaded host; the GitHub run covers it (AC9, AC19) |
| kimi-k3 | Every portability measurement was on macOS BSD userland; the runner is `ubuntu-latest` (GNU sed and grep, mawk or gawk, dash). Named constructs: the `twice` backslash-newline + literal-TAB `s`, the `removed` `/…/,/…/{/…/d;}`, and the `bump` `$a\` under `sed -E` | **Confirmed for this host:** no GNU sed, gawk or GNU grep is installed and docker is not running (controller), so no local GNU run; no software was installed. Partly mitigated already: 7ah's controls, which use the same `$a\` and backslash-newline forms, pass on the runner (V20) | (a) **Removed the divergent forms** (M3, "Portability"). `twice`, `removed`, `unbounded` and `stray` are POSIX awk programs with no character classes and no `ENVIRON`; `bump`'s append is `printf >>`; every sed edit is a single-line `s`. (b) **AC19**, a required pre-landing criterion: the sprint pushes, opens a **draft** PR, and the fast-tier job log on the PR head must show the guard's ok line and `16 rejected, 3 accepted` before the PR leaves draft. The job log is read through `gh api --allow-escape-sequences …/actions/jobs/<id>/logs` with ANSI stripped; that pipeline was proven on main's run `42991331626` (V20) |
| kimi-k3 | The site function's range is not asserted to be bounded: `sed -n '/^func NAME(/,/^func /p'` runs to end of file if no `func` follows | **Confirmed by reading**, and found wider. The range also runs on through a `static func`, which all three files contain (V22), so an ask moved into a following `static func` would be credited to the site | Step 3 now ends the range at the next **top-level** line (`/^[^[:space:]#]/`). The range must exist (`has no func NAME(`, control `renamed`) and must be bounded (`has no following top-level line; range unbounded`, control `unbounded`). Control `stray` moves the prefetch's ask into a `static func` inserted after `_work_sim` and expects rc 2; meta-drill M7 shows it passes with revision 0's `^func ` end. Today the old and new ends give identical ranges (V22). The same hole in 7ah's guard is follow-up F2. Controls: **16 rejected, 3 accepted** (was 13/3); meta-drills 9 (was 6) |
| kimi-k3 | Fallback: "ship in `make test` only" if the runner cannot run the guard | — | **Not adopted.** It is the fail-open hatch gpt-6.1-sol objected to (next row): it would let a PR that bumps one site merge on the fast tier, which is the exact gap this row closes (Problem §3) |
| gpt-6.1-sol | Risks said "drop the `ci-fast:` edge rather than weaken the guard" if the runner is red: a fail-open hatch | **Confirmed**: revision 0's Risks paragraph said exactly that | That paragraph is replaced with the reviewer's text verbatim (Risks, last bullet): "The `ci-fast` guard and controls edges are mandatory acceptance requirements. A runner/environment failure blocks landing; fix the dependency or invocation and rerun the GitHub fast-tier check. Do not remove either edge or suppress its failure. If the runner cannot support these checks, revise this design with a verified replacement that enforces the same invariant on every PR before proceeding." AC9 now requires the successful GitHub run against the **final** commit, recorded with its run id, head sha and the two log lines |


**Round 2** (revision 1; seats oc-glm-5-3, oc-kimi-k3, gpt6-1-sol; Claude benched; absent empty; $0.5557): BLOCKED 2/3 (glm reject, gpt reject, kimi pass). Neither objection disputes option (b); both carry a concrete reviewer fix. Revision 2 is the controller's bounded refinement under the narrow-refinement carve-out: the reviewers' fixes as written, no round 3.

| Reviewer | Objection | Measured | Fix applied (revision 2) |
|---|---|---|---|
| glm-5.3 | Problem §4 claims `bridge/` was swept, but V18 sweeps `bridge/` only for `get("minor"`; no comparison or bare-constant sweep | **Confirmed**: V18's comparison sweeps omit `bridge/` | **V23** (controller): both of glm's `bridge/` sweeps are empty, with firing controls. Problem §4 now reads "and `bridge/` per V23"; the Risks blind-spot bullet and AC20 cite V23 |
| glm-5.3 | "Every guard branch has a measured run" overclaims: the two missing-file branches have no control | **Confirmed** | glm's first option: controls `missbridge` and `misssite`. With gpt's control below the totals become 19 rejected, 3 accepted; AC2, AC12, AC14 and AC19 are updated; the M3 sentence now says which cases V21 measured and which the sprint measures (V24) |
| gpt-6.1-sol | Appendix A's test scan ended in `or true`, so grep's exit 2 counted as success: an unreadable test file could leave the scan incomplete and still print ok | **Confirmed by reading** Appendix A | grep's status is captured without suppression: 0 goes on, 1 goes to the no-comparisons rejection, anything else rejects with `test scan error (grep rc <n>)`. Control `brokentest`: a dangling `tests/broken.gd` symlink beside the readable tests. `notests` now leaves one readable empty test, so its grep exits 1, not 2 (with no file the glob stays literal and grep would exit 2) |
| kimi-k3 (pass, non-blocking) | the scan covers two syntactic forms; suggested a committed `session-minor-audit` target or a constant-on-left pass | controller: the constant-on-left form (`SimBridge.<NAME>_MINOR` before `want_minor` or `proto.minor`) has no hit in `tests/` today | Not adopted in this row (kimi passed); recorded as follow-up F4 |

## Appendix A. The Makefile block (revision-1 prototype plus the revision-2 grep-status lines; inserted after `Makefile:133`, the end of 7ah's `similar-guard-controls` recipe, after one blank line)

```make
# Row 7al: one source for the session minors. The game's three sessions, the map (main.gd _run_map), the ship
# (demos/ship_geometry_demo.gd _create_navigation) and the loading jump's prefetch (ui/loading_jump.gd _work_sim),
# must each ask exactly SimBridge.SESSION_MINOR: SimBridge._adopt_warm() refuses a prefetched sim of another minor,
# and the route then spawns its own on the main thread (2-5 s on the loaded Studio). SESSION_MINOR must be
# `const SESSION_MINOR := <digits>` equal to another `const <NAME>_MINOR` (a defined protocol minor), and every test
# comparison of journey_sim's minor with a SimBridge constant must name SESSION_MINOR, so a bump edits one line.
# A site function's range runs from its `func NAME(` line to the next top-level line (column 0, not a comment: a
# `func`, a `static func`, a `var`); it must have one (else the range is unbounded) and must mention its token
# (want_minor; warm( for the prefetch) exactly once (fail closed).
# SESSION_GUARD_ROOT is where the files are read; session-minor-guard-controls points it at mutated copies.
SESSION_GUARD_ROOT ?= .
.PHONY: session-minor-guard session-minor-guard-controls
test: session-minor-guard session-minor-guard-controls
ci-fast: session-minor-guard session-minor-guard-controls
session-minor-guard: ## 7al: the map, the ship and the loading jump's prefetch all ask SimBridge.SESSION_MINOR
	@set -eu; r='$(SESSION_GUARD_ROOT)'; p='session-minor guard:'; b="$$r/bridge/sim_bridge.gd"; \
	  test -f "$$b" || { echo "$$p missing bridge/sim_bridge.gd" >&2; exit 1; }; \
	  v=$$(sed -nE 's/^const SESSION_MINOR := ([0-9]+)[[:space:]]*(#.*)?$$/\1/p' "$$b"); \
	  case "$$v" in ''|*[!0-9]*) echo "$$p SESSION_MINOR unresolved in bridge/sim_bridge.gd" >&2; exit 1;; esac; \
	  names=$$(sed -nE "s/^const ([A-Z0-9_]+_MINOR) := $$v[[:space:]]*(#.*)?$$/\1/p" "$$b" | grep -vx SESSION_MINOR | tr '\n' ' ' | sed 's/ $$//'); \
	  test -n "$$names" || { echo "$$p SESSION_MINOR ($$v) is no protocol minor in bridge/sim_bridge.gd" >&2; exit 1; }; \
	  for s in 'main.gd _run_map want_minor' 'demos/ship_geometry_demo.gd _create_navigation want_minor' 'ui/loading_jump.gd _work_sim warm('; do \
	    set -- $$s; f="$$r/$$1"; test -f "$$f" || { echo "$$p missing $$1" >&2; exit 1; }; \
	    body=$$(sed -n "/^func $$2(/,/^[^[:space:]#]/p" "$$f"); \
	    test -n "$$body" || { echo "$$p $$1 has no func $$2(" >&2; exit 1; }; \
	    printf '%s\n' "$$body" | tail -n 1 | grep -q '^[^[:space:]#]' || { echo "$$p $$1 $$2 has no following top-level line; range unbounded" >&2; exit 1; }; \
	    n=$$(printf '%s\n' "$$body" | awk -v t="$$3" '{ s = $$0; while ((i = index(s, t)) > 0) { n++; s = substr(s, i + length(t)) } } END { print n + 0 }'); \
	    test "$$n" = 1 || { echo "$$p $$1 $$2 mentions $$3 $$n times, want 1" >&2; exit 1; }; \
	    case "$$3" in want_minor) e='^[^#]*want_minor *= *SimBridge\.SESSION_MINOR[[:space:]]*(#.*)?$$';; *) e='^[^#]*SimBridge\.warm\(SimBridge\.SESSION_MINOR\)[[:space:]]*(#.*)?$$';; esac; \
	    printf '%s\n' "$$body" | grep -qE "$$e" || { echo "$$p $$1 $$2 does not ask SimBridge.SESSION_MINOR" >&2; exit 1; }; \
	  done; \
	  set +e; hits=$$(cd "$$r" && grep -oHE 'journey_sim\.(want_minor|hello_reply\.proto\.minor) *[=!<>]=? *SimBridge\.[A-Z0-9_]+_MINOR' tests/*.gd); gs=$$?; set -e; \
	  case "$$gs" in 0|1) ;; *) echo "$$p test scan error (grep rc $$gs)" >&2; exit 1;; esac; \
	  k=$$(printf '%s\n' "$$hits" | grep -c . || true); \
	  test "$$k" -ge 1 || { echo "$$p no test compares journey_sim's minor with a SimBridge constant" >&2; exit 1; }; \
	  bad=$$(printf '%s\n' "$$hits" | grep -v 'SimBridge\.SESSION_MINOR$$' | sed -n 1p); \
	  test -z "$$bad" || { echo "$$p $${bad%%:*} compares journey_sim's minor with SimBridge.$${bad##*.}, not SESSION_MINOR" >&2; exit 1; }; \
	  echo "$$p ok, SESSION_MINOR ($$v) = $$names; main.gd _run_map, demos/ship_geometry_demo.gd _create_navigation and ui/loading_jump.gd _work_sim ask it; $$k test comparisons name it"
session-minor-guard-controls: ## 7al: session-minor-guard rejects each mutation of a session minor and accepts a one-line bump
	@MAKE='$(MAKE)' sh tools/session_minor_guard_controls.sh .
```

## Appendix B. `tools/session_minor_guard_controls.sh` (revision-1 prototype plus the revision-2 cases R17–R19 and the `notests` file)

```sh
#!/bin/sh
# Row 7al: mutation controls for `make session-minor-guard`. Each case copies ROOT's bridge/sim_bridge.gd,
# the three session files and the tests that compare journey_sim's minor into a temporary root, mutates
# the copy (cmp proves it changed, else exit 3), runs the guard THROUGH its make target with
# SESSION_GUARD_ROOT pointed at the copy, and asserts make's rc and the guard's one reason line.
# The tree is never modified. Portable to GNU and BSD userland and to mawk: sed edits are single-line
# s commands (no a/i/c, no {} blocks, no \n or \t in a replacement); multi-line edits are POSIX awk
# programs (no character classes, no gawk extensions); appends are printf >>.
# Usage: session_minor_guard_controls.sh ROOT
set -eu
ROOT=${1:?usage: session_minor_guard_controls.sh ROOT}
MAKE=${MAKE:-make}
tmp=$(mktemp -d "${TMPDIR:-/tmp}/session-minor-guard.XXXXXX")
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
FILES='bridge/sim_bridge.gd main.gd demos/ship_geometry_demo.gd ui/loading_jump.gd tests/test_bh_hud.gd tests/test_comms_station.gd tests/test_ship_ui.gd'
for f in $FILES; do
  test -f "$ROOT/$f" || { echo "session-minor-guard-controls: no $ROOT/$f" >&2; exit 1; }
done
rejected=0
accepted=0
MAP='/^func _run_map\(/,/^func /'
SHIP='/^func _create_navigation\(/,/^func /'
JUMP='/^func _work_sim\(/,/^func /'
P='session-minor guard:'

# copy CASE: a fresh pristine root at $tmp/CASE
copy() {
  for f in $FILES; do
    mkdir -p "$tmp/$1/$(dirname "$f")" || exit 1
    cp "$ROOT/$f" "$tmp/$1/$f" || exit 1
  done
}
# changed CASE FILE: move FILE.new over FILE; exit 3 if the edit changed nothing
changed() {
  if cmp -s "$tmp/$1/$2" "$tmp/$1/$2.new"; then echo "session-minor-guard-controls: $1: mutation left $2 unchanged" >&2; exit 3; fi
  mv "$tmp/$1/$2.new" "$tmp/$1/$2" || exit 1
}
# mutate CASE FILE SED_SCRIPT: one single-line sed -E s command on $tmp/CASE/FILE
mutate() {
  sed -E "$3" "$tmp/$1/$2" > "$tmp/$1/$2.new" || exit 1
  changed "$1" "$2"
}
# awkmut CASE FILE AWK_PROGRAM: a POSIX awk program on $tmp/CASE/FILE (multi-line edits)
awkmut() {
  awk "$3" "$tmp/$1/$2" > "$tmp/$1/$2.new" || exit 1
  changed "$1" "$2"
}
# append CASE FILE LINE: add LINE at the end of $tmp/CASE/FILE; exit 3 if it is not the last line after
append() {
  printf '%s\n' "$3" >> "$tmp/$1/$2" || exit 1
  test "$(tail -n 1 "$tmp/$1/$2")" = "$3" || { echo "session-minor-guard-controls: $1: append to $2 failed" >&2; exit 3; }
}
# guard CASE: run the target on $tmp/CASE; make's rc in $rc, its output in $tmp/CASE.log
guard() {
  rc=0
  MAKEFLAGS='' MFLAGS='' "$MAKE" -s --no-print-directory -C "$ROOT" session-minor-guard SESSION_GUARD_ROOT="$tmp/$1" > "$tmp/$1.log" 2>&1 || rc=$?
}
# reject CASE LINE: make fails (rc 2) and prints LINE exactly once, and no ok line
reject() {
  guard "$1"
  test "$rc" -eq 2 || { echo "session-minor-guard-controls: $1: make rc $rc, want 2" >&2; cat "$tmp/$1.log" >&2; exit 1; }
  test "$(grep -cxF "$2" "$tmp/$1.log")" -eq 1 || { echo "session-minor-guard-controls: $1: missing reason: $2" >&2; cat "$tmp/$1.log" >&2; exit 1; }
  test "$(grep -c "^$P ok" "$tmp/$1.log")" -eq 0 || { echo "session-minor-guard-controls: $1: ok line on a rejection" >&2; exit 1; }
  rejected=$((rejected + 1))
  echo "session-minor-guard-controls: $1 rejected ($2)"
}
# accept CASE ERE: make passes (rc 0) and its ok line matches ERE exactly once (the capture is live)
accept() {
  guard "$1"
  test "$rc" -eq 0 || { echo "session-minor-guard-controls: $1: make rc $rc, want 0" >&2; cat "$tmp/$1.log" >&2; exit 1; }
  test "$(grep -cxE "$2" "$tmp/$1.log")" -eq 1 || { echo "session-minor-guard-controls: $1: no ok line matching $2" >&2; cat "$tmp/$1.log" >&2; exit 1; }
  accepted=$((accepted + 1))
  echo "session-minor-guard-controls: $1 accepted"
}
OK_TAIL='; main\.gd _run_map, demos/ship_geometry_demo\.gd _create_navigation and ui/loading_jump\.gd _work_sim ask it; [1-9][0-9]* test comparisons name it$'

# P: the tree as it is (positive control: rc 0 and the ok line is captured).
copy pristine
accept pristine "^$P ok, SESSION_MINOR \\([1-9][0-9]*\\) = [A-Z0-9_ ]+$OK_TAIL"

# R1: the map asks another protocol constant (a bump applied to one site by hand).
copy map
mutate map main.gd "${MAP}s/(want_minor *= *SimBridge\.)SESSION_MINOR/\1EARTH_LOG_MINOR/"
reject map "$P main.gd _run_map does not ask SimBridge.SESSION_MINOR"

# R2: the ship asks another protocol constant.
copy ship
mutate ship demos/ship_geometry_demo.gd "${SHIP}s/(want_minor *= *SimBridge\.)SESSION_MINOR/\1EARTH_MINOR/"
reject ship "$P demos/ship_geometry_demo.gd _create_navigation does not ask SimBridge.SESSION_MINOR"

# R3: the loading jump prefetches another protocol constant.
copy prefetch
mutate prefetch ui/loading_jump.gd "${JUMP}s/warm\(SimBridge\.SESSION_MINOR\)/warm(SimBridge.EARTH_LOG_MINOR)/"
reject prefetch "$P ui/loading_jump.gd _work_sim does not ask SimBridge.SESSION_MINOR"

# R4: a literal instead of the constant.
copy literal
mutate literal ui/loading_jump.gd "${JUMP}s/warm\(SimBridge\.SESSION_MINOR\)/warm(18)/"
reject literal "$P ui/loading_jump.gd _work_sim does not ask SimBridge.SESSION_MINOR"

# R5: arithmetic on the constant.
copy arith
mutate arith demos/ship_geometry_demo.gd "${SHIP}s/(want_minor *= *SimBridge\.SESSION_MINOR)/\1 - 2/"
reject arith "$P demos/ship_geometry_demo.gd _create_navigation does not ask SimBridge.SESSION_MINOR"

# R6: a conditional with another branch.
copy ternary
mutate ternary main.gd "${MAP}s/(want_minor *= *SimBridge\.SESSION_MINOR)/\1 if capture else SimBridge.EARTH_MINOR/"
reject ternary "$P main.gd _run_map does not ask SimBridge.SESSION_MINOR"

# R7: a second, later write in the ship's function (awk inserts the line after the ask).
copy twice
awkmut twice demos/ship_geometry_demo.gd '{ print } !d && /want_minor *= *SimBridge\.SESSION_MINOR/ { print "\t\tjourney_sim.want_minor = 2"; d = 1 }'
reject twice "$P demos/ship_geometry_demo.gd _create_navigation mentions want_minor 2 times, want 1"

# R8: the map's want_minor line removed (awk, inside _run_map only).
copy removed
awkmut removed main.gd '/^func _run_map\(/ { f = 1; print; next } f && /^[^ \t#]/ { f = 0 } !(f && /want_minor *= *SimBridge\.SESSION_MINOR/)'
reject removed "$P main.gd _run_map mentions want_minor 0 times, want 1"

# R9: the prefetch's function renamed (the site function is gone).
copy renamed
mutate renamed ui/loading_jump.gd 's/^func _work_sim\(/func _work_sim_renamed(/'
reject renamed "$P ui/loading_jump.gd has no func _work_sim("

# R10: the prefetch's function is the last thing in the file (no following top-level line).
copy unbounded
awkmut unbounded ui/loading_jump.gd '/^func _work_sim\(/ { f = 1; print; next } f && /^[^ \t#]/ { exit } { print }'
reject unbounded "$P ui/loading_jump.gd _work_sim has no following top-level line; range unbounded"

# R11: the prefetch's ask moved out of _work_sim into a static func inserted right after it
# (a range ending at the next `^func ` line would still see it and pass).
copy stray
# shellcheck disable=SC2016 # $0 is awk's record, not a shell expansion
awkmut stray ui/loading_jump.gd '/^func _work_sim\(/ { f = 1; print; next } f && /warm\(SimBridge\.SESSION_MINOR\)/ { ask = $0; next } f && /^[^ \t#]/ { print "static func _stray(holder: Dictionary) -> void:"; print ask; print ""; f = 0 } { print }'
reject stray "$P ui/loading_jump.gd _work_sim mentions warm( 0 times, want 1"

# R12: SESSION_MINOR gone from sim_bridge.gd.
copy nosession
mutate nosession bridge/sim_bridge.gd 's/^const SESSION_MINOR := /const SESSION_MINOR_GONE := /'
reject nosession "$P SESSION_MINOR unresolved in bridge/sim_bridge.gd"

# R13: SESSION_MINOR as an expression (the 7ah grammar would reject it too: its D10).
copy exprsession
mutate exprsession bridge/sim_bridge.gd 's/^const SESSION_MINOR := [0-9]+/const SESSION_MINOR := EARTH_LOG_MINOR/'
reject exprsession "$P SESSION_MINOR unresolved in bridge/sim_bridge.gd"

# R14: SESSION_MINOR equal to no defined protocol minor.
copy orphan
mutate orphan bridge/sim_bridge.gd 's/^const SESSION_MINOR := [0-9]+/const SESSION_MINOR := 99/'
reject orphan "$P SESSION_MINOR (99) is no protocol minor in bridge/sim_bridge.gd"

# R15: a feature test names today's constant again.
copy testname
mutate testname tests/test_comms_station.gd 's/(journey_sim\.want_minor == SimBridge\.)SESSION_MINOR/\1EARTH_LOG_MINOR/'
reject testname "$P tests/test_comms_station.gd compares journey_sim's minor with SimBridge.EARTH_LOG_MINOR, not SESSION_MINOR"

# R16: no test comparison left (the scan's known-positive control).
copy notests
rm -f "$tmp/notests/tests/"*.gd
test ! -e "$tmp/notests/tests/test_ship_ui.gd" || { echo "session-minor-guard-controls: notests: tests not removed" >&2; exit 3; }
# r2: one readable test with no comparison stays, so the scan's grep exits 1 (no match), not 2 (no file)
printf '%s\n' 'extends SceneTree' > "$tmp/notests/tests/test_empty.gd"
reject notests "$P no test compares journey_sim's minor with a SimBridge constant"

# R17 (r2, glm-5.3): the bridge file is missing.
copy missbridge
rm -f "$tmp/missbridge/bridge/sim_bridge.gd"
test ! -e "$tmp/missbridge/bridge/sim_bridge.gd" || { echo "session-minor-guard-controls: missbridge: file not removed" >&2; exit 3; }
reject missbridge "$P missing bridge/sim_bridge.gd"

# R18 (r2, glm-5.3): a session file is missing.
copy misssite
rm -f "$tmp/misssite/main.gd"
test ! -e "$tmp/misssite/main.gd" || { echo "session-minor-guard-controls: misssite: file not removed" >&2; exit 3; }
reject misssite "$P missing main.gd"

# R19 (r2, gpt-6.1-sol): the scan cannot read one test (a dangling symlink) while the readable tests still
# emit valid comparisons; grep exits 2 and the guard must reject rather than print its ok line.
copy brokentest
ln -s "$tmp/brokentest/tests/no_such_file.gd" "$tmp/brokentest/tests/broken.gd"
{ test -L "$tmp/brokentest/tests/broken.gd" && test ! -e "$tmp/brokentest/tests/broken.gd"; } || { echo "session-minor-guard-controls: brokentest: no dangling symlink" >&2; exit 3; }
reject brokentest "$P test scan error (grep rc 2)"

# B: a protocol bump the game adopts: a new constant one above the highest minor, and SESSION_MINOR moved to
# it. No session file and no test is edited.
copy bump
next=$(( $(sed -nE 's/^const [A-Z0-9_]+_MINOR := ([0-9]+).*/\1/p' "$tmp/bump/bridge/sim_bridge.gd" | sort -n | tail -n 1) + 1 ))
test "$next" -gt 18 || { echo "session-minor-guard-controls: bump: next minor $next" >&2; exit 1; }
mutate bump bridge/sim_bridge.gd "s/^const SESSION_MINOR := [0-9]+\$/const SESSION_MINOR := $next/"
append bump bridge/sim_bridge.gd "const FUTURE_MINOR := $next"
accept bump "^$P ok, SESSION_MINOR \\($next\\) = FUTURE_MINOR$OK_TAIL"

# C: a trailing comment on SESSION_MINOR (the one suffix the grammar allows).
copy comment
mutate comment bridge/sim_bridge.gd "s/^(const SESSION_MINOR := [0-9]+)\$/\\1  # a trailing comment/"
accept comment "^$P ok, SESSION_MINOR \\([1-9][0-9]*\\) = [A-Z0-9_ ]+$OK_TAIL"

# G: the comparisons' count is the real one (4 today: test_bh_hud x2, test_comms_station, test_ship_ui).
test "$(grep -oE 'journey_sim\.(want_minor|hello_reply\.proto\.minor) *[=!<>]=? *SimBridge\.SESSION_MINOR' "$tmp/pristine/tests/"*.gd | wc -l | tr -d ' ')" -ge 4 || { echo "session-minor-guard-controls: fewer than 4 comparisons in the pristine copy" >&2; exit 1; }

test "$rejected" -eq 19 || { echo "session-minor-guard-controls: $rejected rejected, want 19" >&2; exit 1; }
test "$accepted" -eq 3 || { echo "session-minor-guard-controls: $accepted accepted, want 3" >&2; exit 1; }
echo "session-minor-guard-controls: $rejected rejected, $accepted accepted"
```

## Appendix C. Meta-drills (sprint evidence, not committed; the exact file run in V21)

Save as `/tmp/7al_meta.sh` for AC12.

```sh
#!/bin/sh
# 7al meta-drills (sprint evidence, not committed): weaken session-minor-guard in a scratch root and
# prove session-minor-guard-controls goes red at the named case. Weakenings are literal: DEL deletes
# every Makefile line containing the string; OLD/NEW replaces its first occurrence on each line
# (awk index/substr through ENVIRON, so no regex or escape processing). Usage: meta.sh ROOT
set -eu
ROOT=${1:?usage: meta.sh ROOT}
MAKE=${MAKE:-make}
FILES='Makefile tools/session_minor_guard_controls.sh bridge/sim_bridge.gd main.gd demos/ship_geometry_demo.gd ui/loading_jump.gd tests/test_bh_hud.gd tests/test_comms_station.gd tests/test_ship_ui.gd'
tmp=$(mktemp -d "${TMPDIR:-/tmp}/stap7al-meta.XXXXXX")
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
caught=0
# drill NAME KIND WANT_ERE (KIND: base | del | sub; DEL or OLD/NEW in the environment)
drill() {
  d="$tmp/$1"; mkdir -p "$d"
  for f in $FILES; do mkdir -p "$d/$(dirname "$f")"; cp "$ROOT/$f" "$d/$f"; done
  cp -R "$ROOT/mk" "$d/mk"
  case "$2" in
    del) awk 'index($0, ENVIRON["DEL"]) == 0' "$ROOT/Makefile" > "$d/Makefile" ;;
    sub) awk '{ i = index($0, ENVIRON["OLD"]); if (i) $0 = substr($0, 1, i - 1) ENVIRON["NEW"] substr($0, i + length(ENVIRON["OLD"])); print }' "$ROOT/Makefile" > "$d/Makefile" ;;
  esac
  if [ "$2" != base ] && cmp -s "$ROOT/Makefile" "$d/Makefile"; then echo "meta $1: weakening changed nothing" >&2; exit 3; fi
  rc=0; MAKEFLAGS='' "$MAKE" -s --no-print-directory -C "$d" session-minor-guard-controls > "$d.log" 2>&1 || rc=$?
  if [ "$2" = base ]; then
    test "$rc" -eq 0 || { echo "meta base: rc $rc" >&2; cat "$d.log" >&2; exit 1; }
    echo "meta base: rc 0 :: $(tail -n 1 "$d.log")"; return
  fi
  test "$rc" -ne 0 || { echo "meta $1: NOT caught (rc 0)" >&2; exit 1; }
  test "$(grep -cE "$3" "$d.log")" -eq 1 || { echo "meta $1: wrong failure" >&2; cat "$d.log" >&2; exit 1; }
  caught=$((caught + 1))
  echo "meta $1: rc $rc :: $(grep -E "$3" "$d.log")"
}
drill base base ''
DEL='does not ask SimBridge.SESSION_MINOR' drill M1_noask del 'map: make rc 0, want 2'
DEL='mentions $$3 $$n times' drill M2_nocount del 'twice: make rc 0, want 2'
DEL='is no protocol minor' drill M3_noname del 'orphan: make rc 0, want 2'
DEL='not SESSION_MINOR" >&2' drill M4_notest del 'testname: make rc 0, want 2'
DEL='no test compares journey_sim' drill M5_noscan del 'notests: make rc 0, want 2'
OLD='SESSION_MINOR[[:space:]]*(#.*)?$$'"'"';; *)' NEW='SESSION_MINOR'"'"';; *)' drill M6_prefix sub 'arith: make rc 0, want 2'
OLD='/^[^[:space:]#]/p" "$$f"' NEW='/^func /p" "$$f"' drill M7_funcend sub 'stray: make rc 0, want 2'
DEL='range unbounded' drill M8_nobound del 'unbounded: make rc 0, want 2'
DEL='has no func $$2(' drill M9_nofunc del 'renamed: missing reason'
echo "meta: $caught weakenings caught"
```
