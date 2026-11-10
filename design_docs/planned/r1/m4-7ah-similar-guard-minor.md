# The similar-test main.gd guard checks a property, not a constant name (7ah)

**Status:** Planned (mission iteration 84, designer). **Release:** r1. **Milestone:** none (suite hygiene, queue row **7ah**).
**Priority:** P1. `make similar-test` has been red on main since PR #379 (R3-COMMS-V2, `e70d0fdf`, merged 2026-11-06 as `8ba1e3c8`). Every ranking, session and oracle step passes; the run then fails on its last line, `similar-test guard: main.gd lost EARTH_MINOR` (V1). It went unseen because the nightly stopped at the first red target (7ag fixed that), and because `similar-test` is not in `ci-fast`, so #379's fast tier never ran it.
**Implements:** row 7ah of the charter (`design_docs/stapledon-mission.md`), clause 5 / suite hygiene. It restores the R2-SIMILAR-S0 S0.3 source guard (`e151c903`; sprint `.ailang/state/sprints/sprint_R2-SIMILAR-S0.json`, AC11; changelog `changelogs/unreleased/2026-10-31-similar-bridge-parse.md`) and serves definition-of-done gate 1: main's nightly `rig/full` stays green. Design-repo context: protocol 2.14 `similar` is R2-SIMILAR-S0 (similar worlds, data only; no physics-spec section applies).
**Depends on:** nothing new.
**Estimated LOC:** about 130, all make glue and one shell control script. No product file changes.
- `Makefile`: -2 lines in the `similar-test` recipe, +24 for a `similar-main-guard` target, a `similar-guard-controls` target and their edges (`similar-test`, `ci-fast`). This is the whole Appendix A hunk, at lines 100–129 (no overlap with attended PRs, V17).
- `tools/similar_guard_controls.sh`: new, 104 lines (Appendix B). A shell script, so no `.uid`; not Python, so no allowlist row.

The measured prototype is `/tmp/stap_i84_7ah_prototype.patch` (151 lines, sha256 `39b38557…`), reverted from the tree. Appendices A and B reproduce it verbatim, so the doc does not depend on `/tmp`.

## Game vision alignment

Scored against `../stapledons-design/vision/core-pillars.md` (pillars 1–6) and `physics/relativity-spec.md` for authenticity.

| Pillar | Relevance | Score | Notes |
|---|---|---:|---|
| Choices Are Final | 0 | 0 | No game code changes. |
| The Game Doesn't Judge | 0 | 0 | No copy changes. |
| Time Has Emotional Weight | 0 | 0 | Nothing a player sees or hears changes. |
| The Ship Is Home | 0 | 0 | No scene or asset changes. |
| Grounded Strangeness | 0 | 0 | The guard keeps the similar-worlds data (2.14) reaching the map session for the later similar-worlds UI. That protects a future feature but adds nothing today. |
| We Are Not Built For This | 0 | 0 | No crew or AI change. |
| Hard sci-fi authenticity (spec) | 0 | 0 | No formula, shader, lookup table or render change. Physics gates 2 and 3 do not apply. |
| **Net** | | **0** | **Go.** Neutral suite hygiene. No pillar scores below 0, so no stop for a human. |

## Problem

1. **The red (V1).** At `79eadb49`, `make similar-test` exits rc 2 after about 44 s. Every `cmp`, oracle and hash step passes, and the trailing zsh block fails at `Makefile:104`:
   ```
   git grep -q "SimBridge.EARTH_MINOR" -- main.gd || { echo "similar-test guard: main.gd lost EARTH_MINOR" >&2; exit 1; }
   ```
   `main.gd:304` (in `_run_map`) now reads `if not capture:sim.want_minor=SimBridge.EARTH_LOG_MINOR`. #379 moved the map session from 2.16 to 2.18 (`bridge/sim_bridge.gd`: `EARTH_MINOR := 16`, `EARTH_LOG_MINOR := 18`). The controller measured `git show 523d96f9:main.gd | grep -c 'SimBridge.EARTH_MINOR'` = 1 (the parent of the #379 merge) and 0 at `8ba1e3c8`.
2. **What the guard was for (V2).** Both main.gd lines came in with `e151c903`, "R2-SIMILAR-S0 S0.3: bridge keeps the similar section as sent". The S0.3 sprint says: "Keep … main.gd byte-identical at its merge-base asking EARTH_MINOR (16)" and "source guards assert main.gd keeps SimBridge.EARTH_MINOR and never names SIMILAR_MINOR". S0.3 added `SIMILAR_MINOR := 14` below the game's minor (then 16). The guards make sure that adding the constant did not tempt anyone to point the game at 2.14, a downgrade, and that the game's session still negotiates a minor that carries `similar` (2.14 and later; its real-sim tests ran at 14, 15 and 16). The literal `EARTH_MINOR` was only a snapshot of "the game's current minor". It encoded the property "the game asks for a minor at or above 2.14, and does not name `SIMILAR_MINOR`" as the name of one constant. So the first protocol bump broke it, as the row predicted.
3. **Which session (V3).** main.gd starts one game session: `_run_map`, the title's "map" route (`main.gd:185`) and `--map` (`:223`). Its range (`func _run_map(` up to the next `func `) has exactly one `want_minor` assignment, `:304`. The other main.gd assignments are the M5.2a flight (`:258`, SYSTEM_MINOR 3), transit (`:280`, 2) and the interior/ISM routes (`:414`, ISM_MINOR 8 or 2). They sit below 14 on purpose and were never this guard's subject. The ship route's session lives in `demos/ship_geometry_demo.gd:1025` and has never been covered by this guard (see Follow-ups).
4. **No other make guard names a single minor (V16).** `git grep -nE '[A-Z_]+_MINOR' -- Makefile 'mk/*.mk' tools/` finds only `Makefile:104–105` among the guards; the other hits are tools that set their own session's minor.

## Goals and non-goals

**Goals.**
- `make similar-test` is green at the fix head with every existing step unchanged.
- The guard checks the **property**: `_run_map`'s single `want_minor` assignment names a `SimBridge` constant whose value, read from `bridge/sim_bridge.gd`, is at least `SIMILAR_MINOR` (also read from there). main.gd never names `SIMILAR_MINOR` (the S0.3 line, kept as is).
- A future protocol bump (a new `FOO_MINOR := 19` asked by the map session) passes with no edit to the guard. A downgrade, removal, literal, duplicate assignment, unknown constant or missing floor each fails with its own message.
- The controls that prove this are committed and cheap (0.3 s), and run on every `make similar-test` and in `ci-fast`.

**Non-goals.**
- Editing `main.gd`, `bridge/sim_bridge.gd` or any product file. The row says fix the guard, not main.gd.
- Changing the vector-read guard (`Makefile:96–103`); it is green and untouched except that its zsh block now ends at line 103.
- Covering the ship session (`demos/ship_geometry_demo.gd:1025`) or the loading jump's prefetch minor (`ui/loading_jump.gd:254`). That is a different property (see Follow-ups).
- The other #379 reds named by 7ag (`bridge-operator-test` D-148, `tools-test` 7ai, `free-nav-stop-test` 7ak). No GPU gate.

## Design

### Alternatives considered

| Option | What | Verdict |
|---|---|---|
| (a) Rename the literal | `SimBridge.EARTH_MINOR` → `SimBridge.EARTH_LOG_MINOR` on line 104 | **Rejected.** A one-token fix, but it breaks again at the next bump, exactly as this one did. The protocol went from 2.13 to 2.18 in about two weeks (SURFACE, SIMILAR, ARCHIVE, EARTH, WORLDS, EARTH_LOG), so another bump is near-certain. It also keeps the guard's meaning implicit. |
| (b) Guard the property | resolve `_run_map`'s requested constant in `bridge/sim_bridge.gd`; require ≥ `SIMILAR_MINOR`; keep "never names `SIMILAR_MINOR`" | **Chosen.** About 15 recipe lines of POSIX sh, read-only and git-free, 0.02 s. It passed at every main.gd since S0.3 (`e151c903`, `523d96f9`, `8ba1e3c8`, `79eadb49`; V7), so it would have stayed green through #379, and it rejects every mutation in the controls (V5). |
| (b′) Whole-file maximum | require that the highest `SimBridge.*_MINOR` named in any `want_minor` assignment in main.gd is ≥ 14 | Rejected as weaker. It passes if the map session is downgraded while another route asks for a high minor. Anchoring on `_run_map` names the session the guard is about. |
| (b″) Require the newest minor | `_run_map` must ask for the highest constant in `sim_bridge.gd` | Rejected as a different, stricter property. S0.3 never asked for that, and it would make adding a constant (for a tool-only or later-wired section, as WORLDS_MINOR 17 was) break the guard until main.gd follows. |
| (c) Delete the main.gd lines | rely on the S0 scope being over | Rejected. Nothing else checks that the game's map session still carries `similar` (2.14+), and the check costs nothing. |

### M1. `similar-main-guard` (the fix)

Split the two main.gd lines out of `similar-test`'s trailing zsh block into their own target, `similar-main-guard`, which reads `$(SIMILAR_GUARD_ROOT)/main.gd` and `$(SIMILAR_GUARD_ROOT)/bridge/sim_bridge.gd` (`SIMILAR_GUARD_ROOT ?= .`). The text is verbatim in Appendix A. In order:
1. Both files exist.
2. Take `_run_map`'s range with `sed -n '/^func _run_map(/,/^func /p'` and its `want_minor` assignments with `grep -E 'want_minor *= *[^= ]'`. The `[^= ]` excludes a `==` comparison. There must be exactly 1, else `sets want_minor N times, want 1`.
3. That line must name `SimBridge.<NAME>_MINOR`, else `asks no SimBridge minor` (for example, a literal).
4. Resolve `^const <NAME> := <digits>` and `^const SIMILAR_MINOR := <digits>` in `sim_bridge.gd`. A missing or non-numeric value fails with `<NAME> unresolved` or `SIMILAR_MINOR unresolved`.
5. `want ≥ floor`, else `asks <NAME> (<want>) below SIMILAR_MINOR (<floor>)`.
6. The S0.3 line, unchanged in meaning: `grep -q SIMILAR_MINOR main.gd` fails with `main.gd asks SIMILAR_MINOR`. Step 5 lets `SIMILAR_MINOR` itself through (14 ≥ 14); this step catches it, and control D2 proves the hand-off.
7. On success it prints `similar-test guard: ok, main.gd _run_map asks EARTH_LOG_MINOR (18) >= SIMILAR_MINOR (14)`. The ok line is the controls' positive capture control.

Failure messages keep the `similar-test guard:` prefix and go to stderr, as before. The recipe is POSIX sh (make's default `SHELL`), not zsh, so it runs under dash on the clean-Linux fast tier (V12).

### M2. `similar-guard-controls` and `tools/similar_guard_controls.sh ROOT` (committed)

The script is verbatim in Appendix B. It follows the mission's drill shape:
- an explicit `ROOT` argument (`${1:?usage}`; no argument is rc 1, V14);
- `mktemp -d` followed at once by `trap 'rm -rf "$tmp"' EXIT HUP INT TERM`;
- each case copies `ROOT/main.gd` and `ROOT/bridge/sim_bridge.gd` into `$tmp/<case>/`, so the tree is never written;
- `mutate` proves the edit changed the copy with `cmp -s`, else **exit 3**;
- the guard runs **through its make target**: `MAKEFLAGS='' MFLAGS='' "$MAKE" -s --no-print-directory -C "$ROOT" similar-main-guard SIMILAR_GUARD_ROOT="$tmp/<case>"`, with make's rc passed through into `$rc`;
- assertions use `test` on counts (`grep -cxF` of the exact reason line `-eq 1`, and no ok line on a rejection), and every check in a function carries its own `|| exit 1`;
- there are no `!`-negated assertions; the totals `test "$rejected" -eq 7` and `test "$accepted" -eq 2` close the run.

`MAKEFLAGS` is cleared for the inner make, so an outer `-n`, `-k`, `-j` or `-s` cannot turn the controls into a dry run or a jobserver warning (V11).

| Case | Mutation (on the copy, inside `_run_map` only) | Expected (make rc, exact line) |
|---|---|---|
| `pristine` (positive control) | none | rc 0; `^similar-test guard: ok, main\.gd _run_map asks [A-Z0-9_]+_MINOR \(([1-9][0-9]+)\) >= SIMILAR_MINOR \(14\)$` once |
| D1 `below` (drill i) | the named constant → `SURFACE_MINOR` (13, the boundary below 14) | rc 2; `similar-test guard: main.gd _run_map asks SURFACE_MINOR (13) below SIMILAR_MINOR (14)` |
| D2 `exact` (drill ii) | → `SIMILAR_MINOR` | rc 2; `similar-test guard: main.gd asks SIMILAR_MINOR` (the existing S0.3 line) |
| D3 `removed` (drill iii) | the `want_minor` line deleted | rc 2; `similar-test guard: main.gd _run_map sets want_minor 0 times, want 1` |
| D4 `literal` | `SimBridge.X_MINOR` → `13` | rc 2; `similar-test guard: main.gd _run_map asks no SimBridge minor` |
| D5 `twice` | a second `sim.want_minor = 2` after the line | rc 2; `similar-test guard: main.gd _run_map sets want_minor 2 times, want 1` |
| D6 `unknown` | → `NO_SUCH_MINOR` | rc 2; `similar-test guard: NO_SUCH_MINOR unresolved in bridge/sim_bridge.gd` |
| D7 `nofloor` | `sim_bridge.gd`: `const SIMILAR_MINOR :=` renamed | rc 2; `similar-test guard: SIMILAR_MINOR unresolved in bridge/sim_bridge.gd` |
| F `future` (drill iv) | `sim_bridge.gd` gains `const FUTURE_MINOR := <max+1>` (19 today, computed, not hard-coded); the map session asks `FUTURE_MINOR` | rc 0; `similar-test guard: ok, main.gd _run_map asks FUTURE_MINOR (19) >= SIMILAR_MINOR (14)` |

The mutations never name today's constant (`EARTH_LOG_MINOR`). They rewrite whatever `SimBridge.*_MINOR` `_run_map` names, so the controls survive the next bump as well. Each guard branch (count ≠ 1 both ways, no name, unresolved name, unresolved floor, below the floor, names `SIMILAR_MINOR`, ok) has at least one measured run (V5).

**Why commit the controls rather than keep them as sprint evidence.** The precedent is 7aj's `display-audit-monitor-controls`. A guard that went red at a bump nobody noticed for four days should prove on every run that it still guards. They cost 0.30 s (V5) against `similar-test`'s 30–53 s, need no AILANG, Godot or git, and leave the tree untouched (V10).

### M3. Wiring

- `similar-test: similar-main-guard similar-guard-controls`, as prerequisites. A bad main.gd now fails in 0.3 s, before the 30–53 s of sessions. `make test` reaches both through `similar-test` (prerequisite 19 of `test`), so the controls are verified through that target (AC1) as well as directly (AC3).
- `ci-fast: similar-main-guard similar-guard-controls`, as a separate rule line beside the targets (the same pattern as `mk/script-gates.mk:27`). The `ci-fast:` line at `Makefile:55` is not edited. **Why ci-fast:** #379 merged on the fast tier with this guard red because `similar-test` (sessions, about 50 s) is not in it. The guard and its controls together cost about 0.3 s, use only POSIX `sh`, `sed`, `grep`, `cmp`, `mktemp` and `make`, and pass under dash and GNU Make 4.4.1 (V11, V12). Wired in, a PR that downgrades the map session goes red at the PR.

## Files touched and Do-not-touch

- **Touched:** `Makefile` (lines 100–129 only, Appendix A) and the new `tools/similar_guard_controls.sh` (Appendix B). The sprint's changelog fragment (`changelogs/unreleased/…`) and the charter/README status rows are routine landing edits.
- **Do not touch:**
  - `main.gd`, `bridge/sim_bridge.gd`, `demos/`, `ui/`, `sim/` and `tests/fixtures/protocol_*`;
  - the vector-read guard's logic (`Makefile:96–103`), beyond closing its zsh string one line earlier;
  - the `ci-fast:` and `test:` lines (55, 57);
  - anything in attended PR #412 (its Makefile hunk is the include list, `@@ -32,6 +32,7 @@`) or in #373 (Makefile hunks at 10, 18 and 225) and #380 (at 251). None overlaps lines 96–129 (V17).

## Acceptance criteria

All commands are headless, run in the fix clone with `export PATH=$PWD/runtime/bin:$PATH` (or the main checkout's `runtime/bin`). `B=79eadb49`. Expected outputs were measured with the prototype (V4–V15).

| # | Criterion | Command | Expected |
|---|---|---|---|
| 1 | The full target is green, the guard and controls reached through it | `make similar-test > /tmp/7ah_st.log 2>&1; echo rc=$?; grep -cx 'similar-test guard: ok, main.gd _run_map asks EARTH_LOG_MINOR (18) >= SIMILAR_MINOR (14)' /tmp/7ah_st.log; grep -cx 'similar-guard-controls: 7 rejected, 2 accepted' /tmp/7ah_st.log; grep -c 'lost EARTH_MINOR' /tmp/7ah_st.log` | `rc=0`, then `1`, `1`, `0`. Every existing ranking, session, oracle and sha step still runs (the log ends with `…session-215-strict.ndjson`'s sha256 `a64e9634…`) |
| 2 | The guard alone | `make similar-main-guard; echo rc=$?` | `similar-test guard: ok, main.gd _run_map asks EARTH_LOG_MINOR (18) >= SIMILAR_MINOR (14)`, `rc=0` |
| 3 | Controls: 7 rejections, 2 acceptances, through the make target | `make similar-guard-controls; echo rc=$?` | nine case lines as in the M2 table (`pristine accepted`, `below rejected (… SURFACE_MINOR (13) below SIMILAR_MINOR (14))`, `exact rejected (… asks SIMILAR_MINOR)`, `removed … 0 times`, `literal … no SimBridge minor`, `twice … 2 times`, `unknown … NO_SUCH_MINOR unresolved …`, `nofloor … SIMILAR_MINOR unresolved …`, `future accepted`), then `similar-guard-controls: 7 rejected, 2 accepted`, `rc=0`; wall time under 2 s |
| 4 | Drills (i)–(iv) as required by the row | the `below`, `exact`, `removed` and `future` lines of AC3 | (i) rc 2 below the floor; (ii) rc 2 on the S0.3 line; (iii) rc 2 at 0 assignments; (iv) rc 0 for `FUTURE_MINOR (19)` |
| 5 | The controls catch a weakened guard (meta-drills, sprint evidence; Appendix C, which works on scratch copies) | `sh /tmp/7ah_meta.sh "$PWD"; echo rc=$?` (Appendix C saved to `/tmp/7ah_meta.sh`) | `meta base: rc 0 :: similar-guard-controls: 7 rejected, 2 accepted`; M1 (floor check deleted) → `below: make rc 0, want 2`; M2 (S0.3 line deleted) → `exact: make rc 0, want 2`; M3 (count check deleted) → `removed: missing reason: …`; M4 (the old `EARTH_MINOR` literal re-added) → `pristine: make rc 2, want 0`; M5 (a no-op mutation) → `below: mutation left main.gd unchanged` (the script exits 3, make rc 2); `meta: 5 weakenings caught`, `rc=0` |
| 6 | A no-op mutation exits 3 from the script itself | `sed '/^mutate below/s/want_minor \*= \*SimBridge/NOPE_NOPE/' tools/similar_guard_controls.sh > /tmp/7ah_noop.sh; MAKE=make sh /tmp/7ah_noop.sh .; echo rc=$?` | `similar-guard-controls: below: mutation left main.gd unchanged`, `rc=3` |
| 7 | The tree is never modified; temp dirs are removed after passing and failing runs | `h=$(shasum main.gd bridge/sim_bridge.gd Makefile); make similar-guard-controls >/dev/null; sh /tmp/7ah_meta.sh "$PWD" >/dev/null; test "$h" = "$(shasum main.gd bridge/sim_bridge.gd Makefile)" && git status --porcelain && find "${TMPDIR:-/tmp}" -maxdepth 1 \( -name 'similar-guard.*' -o -name 'stap7ah-meta.*' \) \| wc -l` | no `git status` output; `0` |
| 8 | The guard passes at every main.gd since S0.3, so a bump no longer breaks it | for each of `e151c903 523d96f9 8ba1e3c8 $B`: `git show $c:main.gd` and `git show $c:bridge/sim_bridge.gd` into `$d/$c/`, then `make -s similar-main-guard SIMILAR_GUARD_ROOT=$d/$c` | all rc 0: `EARTH_MINOR (16)` at the first two, `EARTH_LOG_MINOR (18)` at the last two |
| 9 | Robust to outer make flags and to dash / GNU make | `for m in make gmake; do for f in '' -n -j4 -k; do $m $f similar-guard-controls 2>&1 \| tail -1; done; done` (gmake if installed); `make SHELL=/bin/dash similar-main-guard` (if dash is installed); `shellcheck tools/similar_guard_controls.sh && shellcheck -s dash tools/similar_guard_controls.sh` | every run ends `similar-guard-controls: 7 rejected, 2 accepted` with no `warning`/`jobserver` line; dash rc 0; shellcheck silent |
| 10 | Wired into `ci-fast` and `similar-test` | `make -n ci-fast 2>/dev/null \| grep -cE '_run_map\|similar_guard_controls.sh'`; `grep -nE '^(similar-test\|ci-fast): similar-main-guard similar-guard-controls$' Makefile` | count ≥ 2; two lines. After push: the PR's GitHub `make ci-fast` check is green (`gh pr checks <PR>`) |
| 11 | Hygiene | `make uid-guard python-guard script-gate-lint audio-silent-guard; echo rc=$?` and `git diff --check $B; echo rc=$?` | `uid-guard: ok`, `python-guard: ok`, `script-gate-lint` rc 0 (the recipe has no `--script` call), `audio-silent-guard: ok`; `rc=0` both times |
| 12 | Diff scope | `git diff --name-only $B` | exactly `Makefile` and `tools/similar_guard_controls.sh`, plus the landing's changelog fragment, `design_docs/` and `.ailang/state/` files. Nothing in `main.gd`, `bridge/`, `demos/`, `ui/`, `sim/` or `tests/` |
| 13 | No conflict with attended PRs | `git diff -U0 $B -- Makefile \| grep '^@@'` | hunks only within lines 96–130 (#412 edits 32–38; #373 10, 18, 225; #380 251) |

## Sub-milestones and estimates

| # | What | LOC | Depends | Order |
|---|---|---:|---|---|
| T1 | Write `tools/similar_guard_controls.sh` and the `similar-guard-controls` target first; run it at `B` with the old inline guard and no `similar-main-guard` target, and see it fail (every case: the target does not exist yet, so make rc 2 at `pristine`) | ~106 | none | 1 (red first) |
| M1 | `similar-main-guard`; remove `Makefile:104–105`; close the zsh string at 103 | ~20 | T1 | 2. AC2 and AC3 go green |
| M3 | `similar-test` and `ci-fast` edges | 2 | M1 | 3. AC1 and AC10 |
| V | AC5–AC13, meta-drills | 0 | M3 | 4 |

## Risks and mitigations

- **`_run_map` is renamed or split.** The guard then fails loudly (`sets want_minor 0 times`) rather than passing silently. The fix is a one-word edit to the range in the recipe and in the script's `RANGE`. Accepted: an explicit anchor is better than the whole-file maximum (b′).
- **A constant defined by an expression** (for example `const FOO_MINOR := EARTH_LOG_MINOR + 1`) does not resolve, and the guard fails with `FOO_MINOR unresolved`. That is loud, and every protocol constant so far is a literal (V3). If it happens, extend the resolver; do not weaken it.
- **The want_minor line is reformatted** (for example `sim.want_minor = (SimBridge.X if a else SimBridge.Y)`). Two names on one line: the sed takes the last one, so a ternary that downgrades on one branch could pass. Today's line has one name; D5 covers a second assignment. Recorded as a known limit. The S0.3 guard had the same blind spot.
- **`make -n similar-test` executes the controls line** (standard make semantics for a `$(MAKE)` line). It then really runs the 0.3 s read-only controls, because `MAKEFLAGS` is cleared for the inner make (V11). No tool runs `-n` or `-q` on these targets; `tools/suite_profile.sh` queries a no-op target (V11).
- **The ci-fast runner (Ubuntu, dash, GNU make).** Measured locally under dash and GNU Make 4.4.1 (V11, V12), but not on GitHub's runner. AC10's post-push check closes that gap. If it is red there for an environment reason, drop the `ci-fast:` edge (one line) rather than weaken the guard.

## Open questions for the user

None. The fix is test-only, changes nothing a player sees, and keeps the S0.3 guard's meaning while making it survive protocol bumps.

## Follow-ups (new findings, not scope)

- **F1. The session minors agree only by convention.** `main.gd:304` (map), `demos/ship_geometry_demo.gd:1025` (ship) and `ui/loading_jump.gd:254` (the prefetch, `SimBridge.warm`) all ask `EARTH_LOG_MINOR`. The comments say the map asks "as the ship, so it adopts the loading jump's prefetch" (`main.gd:304`). `SimBridge` hands a warm sim only to a start with the same `want_minor` (`bridge/sim_bridge.gd:198`, `tests/test_loading_jump.gd:163`). Nothing checks that the three agree. A bump that misses one would silently skip the prefetch: slower loading, no error. A candidate row: one guard that resolves all three and requires them equal.
- **F2. Feature tests name today's minor literally.** `tests/test_bh_hud.gd:109,176` and `tests/test_comms_station.gd:133` assert `journey_sim.want_minor == SimBridge.EARTH_LOG_MINOR`. These are feature checks, and a bump author is expected to update them. They will still go red at the next bump the way this guard did, outside `ci-fast`. They may be worth folding into F1's single source.
- **F3. `similar-test` itself is not in `ci-fast`.** This row adds only the 0.3 s guard and controls. Whether the S0 sessions (about 30–50 s) belong in the fast tier is a tier-budget question for the 7ag/test-tiering line, not this row.

## Deliverables

- `Makefile`: `similar-main-guard`, `similar-guard-controls`, the `similar-test` and `ci-fast` edges, and lines 104–105 removed (Appendix A).
- `tools/similar_guard_controls.sh` (Appendix B).
- Evidence for AC1–AC13 in the sprint JSON, including the meta-drill log (AC5).
- A changelog fragment and row 7ah's status in the charter on landing.

## Verification log

Run on 2026-11-10 in `stapledons-godot-iter84` at `79eadb49` (AILANG v0.56.1 pinned runtime, the Studio, macOS make = GNU Make 3.81). V4–V15 used the prototype (Appendices A and B), which was then reverted. `git status --porcelain` was empty before the doc was written.

| # | Command | Result |
|---|---|---|
| V1 | `make -s similar-test` at `79eadb49`, unmodified | rc 2, 44 s wall; the last lines are `a64e9634…  .godot/tmp/similar/session-215-strict.ndjson`, `similar-test guard: main.gd lost EARTH_MINOR`, `make: *** [similar-test] Error 1` |
| V2 | `git log -S 'lost EARTH_MINOR' -- Makefile`; `git log -S 'asks SIMILAR_MINOR'`; the S0.3 rows of `sprint_R2-SIMILAR-S0.json`; `git show e151c903:main.gd \| grep -n want_minor` | Both lines came from `e151c903` (2026-10-31, S0.3). The sprint says "main.gd byte-identical … asking EARTH_MINOR (16)" and "source guards assert main.gd keeps SimBridge.EARTH_MINOR and never names SIMILAR_MINOR". At `e151c903`, `main.gd:304` was `if not capture:sim.want_minor=SimBridge.EARTH_MINOR` |
| V3 | `sed -n '/^func _run_map(/,/^func /p' main.gd \| grep -n want_minor`; `git grep -n _run_map -- main.gd`; `grep -n '^const .*_MINOR' bridge/sim_bridge.gd` | one assignment in `_run_map` (`main.gd:304`, `EARTH_LOG_MINOR`); `_run_map` is called from the title's map route (`:185`) and `--map` (`:223`); every `*_MINOR` constant is a literal `const NAME := N` (1, 3–18) |
| V4 | prototype `make similar-main-guard` | rc 0; `similar-test guard: ok, main.gd _run_map asks EARTH_LOG_MINOR (18) >= SIMILAR_MINOR (14)` |
| V5 | prototype `time make similar-guard-controls` | rc 0, 0.30 s; nine case lines exactly as in AC3, ending `similar-guard-controls: 7 rejected, 2 accepted`; every guard branch rejected at least once |
| V6 | prototype `make similar-test` (twice: before and after the `MAKEFLAGS=''` refinement) | rc 0, 53 s and 30 s; the guard's ok line and `similar-guard-controls: 7 rejected, 2 accepted` present; no `lost EARTH_MINOR`; every existing step ran (the log ends with the 215 oracle line and the session-215 sha `a64e9634…`) |
| V7 | prototype guard against historical heads: `git show <c>:main.gd`, `git show <c>:bridge/sim_bridge.gd` into a trap-cleaned temp dir, `make -s similar-main-guard SIMILAR_GUARD_ROOT=…` | `e151c903` rc 0 `EARTH_MINOR (16)`; `523d96f9` rc 0 `EARTH_MINOR (16)`; `8ba1e3c8` rc 0 `EARTH_LOG_MINOR (18)`; `79eadb49` rc 0 `EARTH_LOG_MINOR (18)`. It would have stayed green through #379 |
| V8 | meta-drills (Appendix C's shape; scratch copies of `Makefile`, `mk/`, `main.gd`, `bridge/sim_bridge.gd` with the prototype patch applied) | `meta base: rc 0 :: similar-guard-controls: 7 rejected, 2 accepted`; `M1_nofloor: rc 2 :: …below: make rc 0, want 2`; `M2_noexact: rc 2 :: …exact: make rc 0, want 2`; `M3_nocount: rc 2 :: …removed: missing reason: similar-test guard: main.gd _run_map sets want_minor 0 times, want 1`; `M4_oldguard: rc 2 :: …pristine: make rc 2, want 0`; `M5_noop: rc 2 :: …below: mutation left main.gd unchanged`; `meta: 5 weakenings caught`, rc 0 |
| V9 | the no-op variant of the script run directly with `sh` | rc 3; `similar-guard-controls: below: mutation left main.gd unchanged` |
| V10 | `shasum main.gd bridge/sim_bridge.gd` before and after all runs; `find "$TMPDIR" -maxdepth 1 -name 'similar-guard.*' -o -name 'stap7ah-meta.*'` after passing and failing runs | sources unchanged; 0 leftover temp dirs; `git status --porcelain` showed only the prototype's `Makefile` and script |
| V11 | `make` (3.81) and `gmake` (4.4.1) × `''`, `-n`, `-j4`, `-k` on `similar-guard-controls`; `git grep` for `make -n`/`-q` in tools; `sed -n 36,52p tools/suite_profile.sh` | all 8 rc 0, 7 rejections each, 0 warning/jobserver lines. Before `MAKEFLAGS=''`, `make -n` made the inner make dry-run and the controls fail at `pristine`, hence the refinement. No tool dry-runs these targets; `suite_profile` runs `-pq` on a no-op target only |
| V12 | `gmake SHELL=/bin/dash similar-main-guard`; `MAKE=gmake dash tools/similar_guard_controls.sh .`; `shellcheck`; `shellcheck -s dash` | rc 0; `7 rejected, 2 accepted`; both shellchecks silent (after replacing `MAKEFLAGS= ` with `MAKEFLAGS=''`, SC1007) |
| V13 | prototype: `make uid-guard script-gate-lint python-guard`; `AUDIO_GUARD_FILES=tools/similar_guard_controls.sh sh tools/audio_silent_guard.sh`; `git diff --check`; `git diff --stat` | `uid-guard: ok (422 .uid files)`, script-gate-lint rc 0, `python-guard: ok (21 allowlisted…)`, `audio-silent-guard: ok`; diff-check rc 0; `Makefile | 30 ++++++++++--`, `tools/similar_guard_controls.sh | 104 +` |
| V14 | `sh tools/similar_guard_controls.sh` (no argument) | rc 1; `…: 1: usage: similar_guard_controls.sh ROOT` |
| V15 | prototype `make -n ci-fast \| grep -c '_run_map\|similar_guard_controls.sh'`-style check | 2 matching recipe lines: both edges present |
| V16 | `git grep -nE '[A-Z_]+_MINOR' -- Makefile 'mk/*.mk' tools/` | in make files only `Makefile:104–105`; `tools/*.gd` hits set their own sessions' minors (not guards) |
| V17 | `gh pr diff 412/373/380 --allow-escape-sequences`, Makefile hunk headers | #412 `@@ -32,6 +32,7 @@`; #373 `@@ -10,7`, `@@ -18,10`, `@@ -225,8`; #380 `@@ -251,6`. None in 96–130 |
| V18 | extract Appendices A, B and C from this doc with `awk`; `cmp` A (the inserted block) and B against the prototype patch's added lines and script; run Appendix C as written against a temp root holding `Makefile`, `mk/`, `main.gd`, `bridge/sim_bridge.gd` with Appendix A applied and Appendix B as `tools/similar_guard_controls.sh` | A and B byte-identical to the prototype; Appendix C rc 0, the same six lines as V8, `meta: 5 weakenings caught`; the clone's `git status --porcelain` showed only this doc |

## Appendix A. The Makefile change (prototype, verbatim)

The block is shown as plain text, not a raw diff, because diff context lines (a space before a recipe tab) would fail `git diff --check` on this doc. There are three edits.
1. `Makefile:103`, the vector-read guard's last line: its ending `fi; \` becomes `fi'`, which closes the zsh string one line earlier. Nothing else on the line changes.
2. `Makefile:104–105` are deleted: `git grep -q "SimBridge.EARTH_MINOR" -- main.gd || { … lost EARTH_MINOR … }; \` and `if git grep -q "SIMILAR_MINOR" -- main.gd; then … asks SIMILAR_MINOR …; fi'`.
3. This block is inserted after line 103, preceded by one blank line. The blank line before `# Recording is separate from test.` stays.

```make
# Row 7ah: the map session main.gd starts (_run_map) must ask a SimBridge minor at or above SIMILAR_MINOR, so its
# new_game carries `similar` (R2-SIMILAR-S0), and main.gd must never name SIMILAR_MINOR (S0.3: the game keeps its newer
# minor). Both numbers are read from bridge/sim_bridge.gd, so a protocol bump passes and a downgrade fails.
# SIMILAR_GUARD_ROOT is where main.gd and bridge/sim_bridge.gd are read; similar-guard-controls points it at mutated copies.
SIMILAR_GUARD_ROOT ?= .
.PHONY: similar-main-guard similar-guard-controls
similar-test: similar-main-guard similar-guard-controls
ci-fast: similar-main-guard similar-guard-controls
similar-main-guard: ## 7ah: main.gd's map session asks a SimBridge minor >= SIMILAR_MINOR, and never SIMILAR_MINOR
	@set -eu; r='$(SIMILAR_GUARD_ROOT)'; g="$$r/main.gd"; b="$$r/bridge/sim_bridge.gd"; \
	  test -f "$$g" && test -f "$$b" || { echo "similar-test guard: missing $$g or $$b" >&2; exit 1; }; \
	  set_lines=$$(sed -n '/^func _run_map(/,/^func /p' "$$g" | grep -E 'want_minor *= *[^= ]' || true); \
	  n=$$(printf '%s' "$$set_lines" | grep -c . || true); \
	  test "$$n" = 1 || { echo "similar-test guard: main.gd _run_map sets want_minor $$n times, want 1" >&2; exit 1; }; \
	  name=$$(printf '%s\n' "$$set_lines" | sed -nE 's/.*want_minor *= *SimBridge\.([A-Z0-9_]+_MINOR).*/\1/p'); \
	  test -n "$$name" || { echo "similar-test guard: main.gd _run_map asks no SimBridge minor" >&2; exit 1; }; \
	  want=$$(sed -nE "s/^const $$name := ([0-9]+).*/\1/p" "$$b"); \
	  floor=$$(sed -nE 's/^const SIMILAR_MINOR := ([0-9]+).*/\1/p' "$$b"); \
	  case "$$want" in ''|*[!0-9]*) echo "similar-test guard: $$name unresolved in bridge/sim_bridge.gd" >&2; exit 1;; esac; \
	  case "$$floor" in ''|*[!0-9]*) echo "similar-test guard: SIMILAR_MINOR unresolved in bridge/sim_bridge.gd" >&2; exit 1;; esac; \
	  test "$$want" -ge "$$floor" || { echo "similar-test guard: main.gd _run_map asks $$name ($$want) below SIMILAR_MINOR ($$floor)" >&2; exit 1; }; \
	  if grep -q SIMILAR_MINOR "$$g"; then echo "similar-test guard: main.gd asks SIMILAR_MINOR" >&2; exit 1; fi; \
	  echo "similar-test guard: ok, main.gd _run_map asks $$name ($$want) >= SIMILAR_MINOR ($$floor)"
similar-guard-controls: ## 7ah: similar-main-guard rejects each mutation of main.gd's map-session minor and accepts a future bump
	@MAKE='$(MAKE)' sh tools/similar_guard_controls.sh .
```

## Appendix B. `tools/similar_guard_controls.sh` (prototype, verbatim)

```sh
#!/bin/sh
# Row 7ah: mutation controls for `make similar-main-guard`. Each case copies ROOT's main.gd and
# bridge/sim_bridge.gd into a temporary root, mutates the copy (cmp proves it changed, else exit 3),
# runs the guard THROUGH its make target with SIMILAR_GUARD_ROOT pointed at the copy, and asserts make's
# rc and the guard's one reason line. The tree is never modified. Usage: similar_guard_controls.sh ROOT
set -eu
ROOT=${1:?usage: similar_guard_controls.sh ROOT}
MAKE=${MAKE:-make}
tmp=$(mktemp -d "${TMPDIR:-/tmp}/similar-guard.XXXXXX")
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
test -f "$ROOT/main.gd" || { echo "similar-guard-controls: no $ROOT/main.gd" >&2; exit 1; }
test -f "$ROOT/bridge/sim_bridge.gd" || { echo "similar-guard-controls: no $ROOT/bridge/sim_bridge.gd" >&2; exit 1; }
rejected=0
accepted=0
RANGE='/^func _run_map\(/,/^func /'

# copy CASE: a fresh pristine root at $tmp/CASE
copy() {
  mkdir -p "$tmp/$1/bridge" || exit 1
  cp "$ROOT/main.gd" "$tmp/$1/main.gd" || exit 1
  cp "$ROOT/bridge/sim_bridge.gd" "$tmp/$1/bridge/sim_bridge.gd" || exit 1
}
# mutate CASE FILE SED_SCRIPT: edit $tmp/CASE/FILE; exit 3 if the edit changed nothing
mutate() {
  sed -E "$3" "$tmp/$1/$2" > "$tmp/$1/$2.new" || exit 1
  if cmp -s "$tmp/$1/$2" "$tmp/$1/$2.new"; then echo "similar-guard-controls: $1: mutation left $2 unchanged" >&2; exit 3; fi
  mv "$tmp/$1/$2.new" "$tmp/$1/$2" || exit 1
}
# guard CASE: run the target on $tmp/CASE; make's rc in $rc, its output in $tmp/CASE.log
guard() {
  rc=0
  MAKEFLAGS='' MFLAGS='' "$MAKE" -s --no-print-directory -C "$ROOT" similar-main-guard SIMILAR_GUARD_ROOT="$tmp/$1" > "$tmp/$1.log" 2>&1 || rc=$?
}
# reject CASE LINE: make fails (rc 2) and prints LINE exactly once
reject() {
  guard "$1"
  test "$rc" -eq 2 || { echo "similar-guard-controls: $1: make rc $rc, want 2" >&2; cat "$tmp/$1.log" >&2; exit 1; }
  test "$(grep -cxF "$2" "$tmp/$1.log")" -eq 1 || { echo "similar-guard-controls: $1: missing reason: $2" >&2; cat "$tmp/$1.log" >&2; exit 1; }
  test "$(grep -c '^similar-test guard: ok' "$tmp/$1.log")" -eq 0 || { echo "similar-guard-controls: $1: ok line on a rejection" >&2; exit 1; }
  rejected=$((rejected + 1))
  echo "similar-guard-controls: $1 rejected ($2)"
}
# accept CASE ERE: make passes (rc 0) and its ok line matches ERE exactly once (the capture is live)
accept() {
  guard "$1"
  test "$rc" -eq 0 || { echo "similar-guard-controls: $1: make rc $rc, want 0" >&2; cat "$tmp/$1.log" >&2; exit 1; }
  test "$(grep -cxE "$2" "$tmp/$1.log")" -eq 1 || { echo "similar-guard-controls: $1: no ok line matching $2" >&2; cat "$tmp/$1.log" >&2; exit 1; }
  accepted=$((accepted + 1))
  echo "similar-guard-controls: $1 accepted"
}

# P: the tree as it is (positive control: rc 0 and the ok line is captured).
copy pristine
accept pristine '^similar-test guard: ok, main\.gd _run_map asks [A-Z0-9_]+_MINOR \(([1-9][0-9]+)\) >= SIMILAR_MINOR \(14\)$'

# D1: the map session asks the constant just below SIMILAR_MINOR.
copy below
mutate below main.gd "${RANGE}s/(want_minor *= *SimBridge\.)[A-Z0-9_]+_MINOR/\1SURFACE_MINOR/"
reject below 'similar-test guard: main.gd _run_map asks SURFACE_MINOR (13) below SIMILAR_MINOR (14)'

# D2: the map session asks SIMILAR_MINOR exactly (passes the floor; the S0.3 line catches it).
copy exact
mutate exact main.gd "${RANGE}s/(want_minor *= *SimBridge\.)[A-Z0-9_]+_MINOR/\1SIMILAR_MINOR/"
reject exact 'similar-test guard: main.gd asks SIMILAR_MINOR'

# D3: the map session's want_minor line removed.
copy removed
mutate removed main.gd "${RANGE}{/want_minor *= *[^= ]/d;}"
reject removed 'similar-test guard: main.gd _run_map sets want_minor 0 times, want 1'

# D4: a literal instead of a SimBridge constant.
copy literal
mutate literal main.gd "${RANGE}s/(want_minor *= *)SimBridge\.[A-Z0-9_]+_MINOR/\113/"
reject literal 'similar-test guard: main.gd _run_map asks no SimBridge minor'

# D5: a second, later assignment in _run_map (a downgrade after the checked line).
copy twice
mutate twice main.gd "${RANGE}s/^(.*want_minor *= *SimBridge\.[A-Z0-9_]+_MINOR.*)$/\1\\
	sim.want_minor = 2/"
reject twice 'similar-test guard: main.gd _run_map sets want_minor 2 times, want 1'

# D6: a constant sim_bridge.gd does not define.
copy unknown
mutate unknown main.gd "${RANGE}s/(want_minor *= *SimBridge\.)[A-Z0-9_]+_MINOR/\1NO_SUCH_MINOR/"
reject unknown 'similar-test guard: NO_SUCH_MINOR unresolved in bridge/sim_bridge.gd'

# D7: SIMILAR_MINOR gone from sim_bridge.gd (the floor cannot be read).
copy nofloor
mutate nofloor bridge/sim_bridge.gd 's/^const SIMILAR_MINOR := /const SIMILAR_MINOR_GONE := /'
reject nofloor 'similar-test guard: SIMILAR_MINOR unresolved in bridge/sim_bridge.gd'

# F: a future protocol bump: a new constant one above the highest minor, asked by the map session.
copy future
next=$(( $(sed -nE 's/^const [A-Z0-9_]+_MINOR := ([0-9]+).*/\1/p' "$tmp/future/bridge/sim_bridge.gd" | sort -n | tail -1) + 1 ))
test "$next" -gt 14 || { echo "similar-guard-controls: future: next minor $next" >&2; exit 1; }
mutate future bridge/sim_bridge.gd "\$a\\
const FUTURE_MINOR := $next
"
mutate future main.gd "${RANGE}s/(want_minor *= *SimBridge\.)[A-Z0-9_]+_MINOR/\1FUTURE_MINOR/"
accept future "^similar-test guard: ok, main\\.gd _run_map asks FUTURE_MINOR \\($next\\) >= SIMILAR_MINOR \\(14\\)\$"

test "$rejected" -eq 7 || { echo "similar-guard-controls: $rejected rejected, want 7" >&2; exit 1; }
test "$accepted" -eq 2 || { echo "similar-guard-controls: $accepted accepted, want 2" >&2; exit 1; }
echo "similar-guard-controls: $rejected rejected, $accepted accepted"
```

(The D5 replacement's second line starts with a literal tab.)

## Appendix C. Meta-drills (sprint evidence, not committed; post-fix form of V8)

At the fix head this needs no patch step: it copies the build files from `ROOT` and weakens the copy. V8 ran the same drills with `patch -p1 < /tmp/stap_i84_7ah_Makefile.patch` and the prototype script applied to the copy.

```sh
#!/bin/sh
# 7ah meta-drills: weaken the guard in a scratch copy and prove similar-guard-controls goes red at the named case.
# Usage: 7ah_meta.sh ROOT  (ROOT = the fix clone)
set -eu
ROOT=${1:?ROOT}
w=$(mktemp -d "${TMPDIR:-/tmp}/stap7ah-meta.XXXXXX")
trap 'rm -rf "$w"' EXIT HUP INT TERM
mkdir -p "$w/base/bridge" "$w/base/tools" || exit 1
cp -R "$ROOT/Makefile" "$ROOT/mk" "$ROOT/main.gd" "$w/base/" || exit 1
cp "$ROOT/bridge/sim_bridge.gd" "$w/base/bridge/" || exit 1
cp "$ROOT/tools/similar_guard_controls.sh" "$w/base/tools/" || exit 1
red=0
# drill NAME FILE SED WANT_RC FIRST_FAILURE_ERE
drill() {
  rm -rf "$w/d" || exit 1; cp -R "$w/base" "$w/d" || exit 1
  sed -E "$3" "$w/base/$2" > "$w/d/$2" || exit 1
  if cmp -s "$w/base/$2" "$w/d/$2"; then echo "meta $1: mutation changed nothing" >&2; exit 3; fi
  rc=0; MAKEFLAGS='' make -s -C "$w/d" similar-guard-controls > "$w/$1.log" 2>&1 || rc=$?
  test "$rc" -eq "$4" || { echo "meta $1: rc $rc want $4" >&2; cat "$w/$1.log" >&2; exit 1; }
  test "$(grep -cE "$5" "$w/$1.log")" -eq 1 || { echo "meta $1: no line $5" >&2; cat "$w/$1.log" >&2; exit 1; }
  red=$((red + 1)); echo "meta $1: rc $rc :: $(grep -E "$5" "$w/$1.log")"
}
# positive control: the unweakened copy passes and its summary is captured
rc=0; MAKEFLAGS='' make -s -C "$w/base" similar-guard-controls > "$w/base.log" 2>&1 || rc=$?
test "$rc" -eq 0 || { echo "meta base: rc $rc" >&2; cat "$w/base.log" >&2; exit 1; }
test "$(grep -cx 'similar-guard-controls: 7 rejected, 2 accepted' "$w/base.log")" -eq 1 || exit 1
echo "meta base: rc 0 :: $(tail -1 "$w/base.log")"
drill M1_nofloor Makefile '/test "\$\$want" -ge/d' 2 '^similar-guard-controls: below: make rc 0, want 2$'
drill M2_noexact Makefile '/if grep -q SIMILAR_MINOR/d' 2 '^similar-guard-controls: exact: make rc 0, want 2$'
drill M3_nocount Makefile '/test "\$\$n" = 1/d' 2 '^similar-guard-controls: removed: missing reason: '
drill M4_oldguard Makefile 's/^(similar-main-guard:.*)$/\1\n\t@grep -q "SimBridge.EARTH_MINOR" "$(SIMILAR_GUARD_ROOT)\/main.gd" || { echo "similar-test guard: main.gd lost EARTH_MINOR" >\&2; exit 1; }/' 2 '^similar-guard-controls: pristine: make rc 2, want 0$'
drill M5_noop tools/similar_guard_controls.sh '/^mutate below/s/want_minor \*= \*SimBridge/NOPE_NOPE/' 2 '^similar-guard-controls: below: mutation left main.gd unchanged$'
test "$red" -eq 5 || exit 1
echo "meta: 5 weakenings caught"
```
