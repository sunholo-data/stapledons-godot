# The similar-test main.gd guard checks a property, not a constant name (7ah)

**Status:** Planned (mission iteration 84, designer). Revision 1 answers design-quorum round 1; revision 2 (the controller, under the narrow-refinement carve-out) answers round 2 with the reviewers' own fixes; see "Quorum verification log". **Release:** r1. **Milestone:** none (suite hygiene, queue row **7ah**).
**Priority:** P1. `make similar-test` has been red on main since PR #379 (R3-COMMS-V2, `e70d0fdf`, merged 2026-11-06 as `8ba1e3c8`). Every ranking, session and oracle step passes; the run then fails on its last line, `similar-test guard: main.gd lost EARTH_MINOR` (V1). It went unseen because the nightly stopped at the first red target (7ag fixed that), and because `similar-test` is not in `ci-fast`, so #379's fast tier never ran it.
**Implements:** row 7ah of the charter (`design_docs/stapledon-mission.md`), clause 5 / suite hygiene. It restores the R2-SIMILAR-S0 S0.3 source guard (`e151c903`; sprint `.ailang/state/sprints/sprint_R2-SIMILAR-S0.json`, AC11; changelog `changelogs/unreleased/2026-10-31-similar-bridge-parse.md`) and serves definition-of-done gate 1: main's nightly `rig/full` stays green. Design-repo context: protocol 2.14 `similar` is R2-SIMILAR-S0 (similar worlds, data only; no physics-spec section applies).
**Depends on:** nothing new.
**Estimated LOC:** about 165, all make glue and one shell control script. No product file changes.
- `Makefile`: 3 lines changed or removed in the `similar-test` recipe, plus 27 new lines: a `similar-main-guard` target, a `similar-guard-controls` target and their edges (`similar-test`, `ci-fast`). This is all of Appendix A, at lines 100–131. It does not overlap attended PRs (V17).
- `tools/similar_guard_controls.sh`: new, 135 lines (Appendix B). It is a shell script, so it needs no `.uid`; it is not Python, so it needs no allowlist row.

The measured revision-1 prototype is `/tmp/stap_i84_7ah_prototype_r1.patch` (184 lines, sha256 `27e68a04…`); revision 0's was `/tmp/stap_i84_7ah_prototype.patch`. Both were reverted from the tree. Appendices A and B reproduce revision 1 verbatim, so the doc does not depend on `/tmp`.

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

1. **The red (V1).** At `79eadb49`, `make similar-test` exits rc 2 after about 44 s. Every `cmp`, oracle and hash step passes, then the trailing zsh block fails at `Makefile:104`:
   ```
   git grep -q "SimBridge.EARTH_MINOR" -- main.gd || { echo "similar-test guard: main.gd lost EARTH_MINOR" >&2; exit 1; }
   ```
   `main.gd:304` (in `_run_map`) now reads `if not capture:sim.want_minor=SimBridge.EARTH_LOG_MINOR # R3-COMMS-V2: 2.18 (as the ship; 2.17 is R3-WORLDS); …` (the line carries a long trailing `#` comment, elided here and in V20; V22 records it). #379 moved the map session from 2.16 to 2.18 (`bridge/sim_bridge.gd`: `EARTH_MINOR := 16`, `EARTH_LOG_MINOR := 18`). The controller measured `git show 523d96f9:main.gd | grep -c 'SimBridge.EARTH_MINOR'` = 1 (the parent of the #379 merge) and 0 at `8ba1e3c8`.
2. **What the guard was for (V2).** Both main.gd lines came in with `e151c903`, "R2-SIMILAR-S0 S0.3: bridge keeps the similar section as sent". The S0.3 sprint says: "Keep … main.gd byte-identical at its merge-base asking EARTH_MINOR (16)" and "source guards assert main.gd keeps SimBridge.EARTH_MINOR and never names SIMILAR_MINOR". S0.3 added `SIMILAR_MINOR := 14` below the game's minor, which was 16 at the time. The guards had two jobs. They made sure the new constant did not tempt anyone to point the game at 2.14, which would be a downgrade. They also made sure the game's session still negotiated a minor that carries `similar` (2.14 and later; the S0.3 real-sim tests ran at 14, 15 and 16). The literal `EARTH_MINOR` was only a snapshot of "the game's current minor". It encoded the property "the game asks for a minor of at least 2.14 and does not name `SIMILAR_MINOR`" as the name of one constant. So the first protocol bump broke it, as the row predicted.
3. **Which session (V3, V20).** main.gd starts one game session, `_run_map`, reached from the title's "map" route (`main.gd:185`) and from `--map` (`:223`). Its range (`func _run_map(` up to the next `func `) has exactly one `want_minor` assignment, `:304`. main.gd's other assignments are measured in V20:
   - `:258`, the M5.2a flight: `SimBridge.SYSTEM_MINOR if not _fixed_scale else sim.want_minor` (3);
   - `:280`, transit: `2`;
   - `:414`, the interior and ISM routes: `SimBridge.ISM_MINOR if args.has("ism-capture") else (2 if capture or smoke else SimBridge.ISM_MINOR)` (8 or 2).

   They are below 14 on purpose and were never this guard's subject. The ship route's session is `demos/ship_geometry_demo.gd:1025` (V20), which this guard has never covered (see Follow-ups).
4. **No other make guard names a single minor (V16).** `git grep -nE '[A-Z_]+_MINOR' -- Makefile 'mk/*.mk' tools/` finds only `Makefile:104–105` among the guards. The other hits are tools that set their own session's minor.

## Goals and non-goals

**Goals.**
- `make similar-test` is green at the fix head with every existing step unchanged.
- The guard checks the **property** with a **fail-closed grammar**. `_run_map`'s single `want_minor` assignment must be exactly `want_minor = SimBridge.<NAME>_MINOR`. That constant's value must be exactly `const <NAME> := <digits>` in `bridge/sim_bridge.gd`, and it must be at least `SIMILAR_MINOR`, which is itself exactly `const SIMILAR_MINOR := <digits>`. Each of these may carry a trailing `#` comment. Any other form fails with its own message: an expression, a ternary, arithmetic, a literal, a second assignment, an unknown name or a missing floor. main.gd never names `SIMILAR_MINOR`; the S0.3 line is kept as it is.
- A future protocol bump passes with no edit to the guard: a new `FOO_MINOR := 19`, with or without a trailing comment, asked by the map session.
- The controls that prove this are committed and cheap (0.48–0.64 s). They run on every `make similar-test` and in `ci-fast`.

**Non-goals.**
- Editing `main.gd`, `bridge/sim_bridge.gd` or any product file. The row says fix the guard, not main.gd.
- Changing the vector-read guard (`Makefile:96–103`). It is green, and the only change is that its zsh block now ends at line 103.
- Evaluating GDScript constant expressions. An expression-valued minor constant is rejected, not computed (see Risks).
- Covering the ship session (`demos/ship_geometry_demo.gd:1025`) or the loading jump's prefetch minor (`ui/loading_jump.gd:254`). That is a different property (see Follow-ups).
- The other #379 reds named by 7ag (`bridge-operator-test` D-148, `tools-test` 7ai, `free-nav-stop-test` 7ak). No GPU gate.

## Design

### Alternatives considered

| Option | What | Verdict |
|---|---|---|
| (a) Rename the literal | `SimBridge.EARTH_MINOR` → `SimBridge.EARTH_LOG_MINOR` on line 104 | **Rejected.** A one-token fix, but it breaks again at the next bump, exactly as this one did. The protocol went from 2.13 to 2.18 in about two weeks (SURFACE, SIMILAR, ARCHIVE, EARTH, WORLDS, EARTH_LOG), so another bump is near-certain. It also keeps the guard's meaning implicit. |
| (b) Guard the property, fail-closed | resolve `_run_map`'s requested constant in `bridge/sim_bridge.gd` with an end-anchored grammar; require ≥ `SIMILAR_MINOR`; keep "never names `SIMILAR_MINOR`" | **Chosen.** About 17 recipe lines of POSIX sh, read-only and git-free, 0.02 s. It passes at every main.gd since S0.3 (`e151c903`, `523d96f9`, `8ba1e3c8`, `79eadb49`; V7), so it would have stayed green through #379. It rejects all 13 mutations in the controls (V5), including the three false acceptances round 1 found in revision 0 (V19). |
| (b0) Revision 0's prefix resolver | `s/^const NAME := ([0-9]+).*/` and `s/.*want_minor *= *SimBridge\.(NAME).*/` | **Rejected in round 1.** Each reads a prefix, so it silently accepts `const FOO_MINOR := 18 - 10` as 18, `SimBridge.EARTH_LOG_MINOR - 10` as 18, and a ternary with a below-floor branch as its first constant (V19). |
| (b′) Whole-file maximum | require that the highest `SimBridge.*_MINOR` named in any `want_minor` assignment in main.gd is ≥ 14 | Rejected as weaker. It passes if the map session is downgraded while another route asks for a high minor. Anchoring on `_run_map` names the session the guard is about. |
| (b″) Require the newest minor | `_run_map` must ask for the highest constant in `sim_bridge.gd` | Rejected as a different, stricter property. S0.3 never asked for it. It would also break the guard whenever a constant is added before main.gd follows, for example for a tool-only or later-wired section, as WORLDS_MINOR 17 was. |
| (c) Delete the main.gd lines | rely on the S0 scope being over | Rejected. Nothing else checks that the game's map session still carries `similar` (2.14+), and the check costs nothing. |

### M1. `similar-main-guard` (the fix)

Split the two main.gd lines out of `similar-test`'s trailing zsh block into their own target, `similar-main-guard`. It reads `$(SIMILAR_GUARD_ROOT)/main.gd` and `$(SIMILAR_GUARD_ROOT)/bridge/sim_bridge.gd` (`SIMILAR_GUARD_ROOT ?= .`). The recipe is verbatim in Appendix A. In order:
1. Both files exist.
2. Take `_run_map`'s range with `sed -n '/^func _run_map(/,/^func /p'` and count every occurrence of `want_minor` in it (`awk '{ n += gsub(/want_minor/, "") } END { print n + 0 }'`). **The count is deliberately broad** (revision 2, quorum round 2): it includes compound writes (`-=`, `+=`), reassignments, `==` comparisons, `:=` defaults and comments. Any of them over-counts and fails closed with `mentions want_minor N times, want 1`, rather than being silently ignored. Only step 3's grammar decides what a valid assignment is. Revision 1 counted only lines matching `want_minor *= *[^= ]`. That pattern ignored `sim.want_minor -= 10` after the checked line, so a downgrade to 8 passed (V22, gpt6-1-sol). It did not match `==` or `:=` either (V22 measured 0 for both, contrary to a round-2 claim). The one line that mentions `want_minor` is the one step 3 parses.
3. **Assignment grammar, end-anchored:** `s/^[^#]*want_minor *= *SimBridge\.([A-Z0-9_]+_MINOR)[[:space:]]*(#.*)?$/\1/p`. The right-hand side must be one bare `SimBridge.<NAME>_MINOR`, followed only by whitespace and an optional `#` comment. `[^#]*` keeps the match in the code part of the line, so a comment that mentions `want_minor = SimBridge.X` cannot be picked up. Anything else fails with `main.gd _run_map want_minor is not one bare SimBridge minor`: a literal, arithmetic (`SimBridge.X - 10`), a ternary (`SimBridge.X if a else SimBridge.Y`) or a call.
4. **Constant grammar, end-anchored:** the value of `<NAME>` is `s/^const <NAME> := ([0-9]+)[[:space:]]*(#.*)?$/\1/p`, and the value of `SIMILAR_MINOR` uses the same pattern. The whole right-hand side must be digits, optionally followed by whitespace and a `#` comment. A missing name, an expression (`18 - 10`), a duplicate definition (two lines, so the value contains a newline) or anything non-numeric fails with `<NAME> unresolved in bridge/sim_bridge.gd` or `SIMILAR_MINOR unresolved in bridge/sim_bridge.gd`.
5. `want ≥ floor`, else `main.gd _run_map asks <NAME> (<want>) below SIMILAR_MINOR (<floor>)`.
6. The S0.3 line, unchanged in meaning: `grep -q SIMILAR_MINOR main.gd` fails with `main.gd asks SIMILAR_MINOR`. Step 5 lets `SIMILAR_MINOR` itself through (14 ≥ 14); this step catches it, and control D2 proves the hand-off.
7. On success it prints `similar-test guard: ok, main.gd _run_map asks EARTH_LOG_MINOR (18) >= SIMILAR_MINOR (14)`. The controls use this ok line as their positive capture control.

Failure messages keep the `similar-test guard:` prefix and go to stderr, as before. The recipe is POSIX sh (make's default `SHELL`), not zsh, so it runs under dash on the clean-Linux fast tier (V12).

### M2. `similar-guard-controls` and `tools/similar_guard_controls.sh ROOT` (committed)

The script is verbatim in Appendix B. It follows the mission's drill shape:
- an explicit `ROOT` argument (`${1:?usage}`; no argument is rc 1, V14);
- `mktemp -d` followed at once by `trap 'rm -rf "$tmp"' EXIT HUP INT TERM`;
- each case copies `ROOT/main.gd` and `ROOT/bridge/sim_bridge.gd` into `$tmp/<case>/`, so the tree is never written;
- `mutate` proves with `cmp -s` that the edit changed the copy, else **exit 3**;
- the guard runs **through its make target**: `MAKEFLAGS='' MFLAGS='' "$MAKE" -s --no-print-directory -C "$ROOT" similar-main-guard SIMILAR_GUARD_ROOT="$tmp/<case>"`, with make's rc passed through into `$rc`;
- assertions use `test` on counts: `grep -cxF` of the exact reason line `-eq 1`, and no ok line on a rejection. Every check in a function carries its own `|| exit 1`;
- there are no `!`-negated assertions; the totals `test "$rejected" -eq 13` and `test "$accepted" -eq 3` close the run.

`MAKEFLAGS` is cleared for the inner make. An outer `-n`, `-k`, `-j` or `-s` therefore cannot turn the controls into a dry run or cause a jobserver warning (V11). Every mutation is a `sed -E` script that runs on BSD `/usr/bin/sed` and GNU sed. The appends use the portable `$a\` + newline form, and the D5 insert uses backslash-newline, not `\n` (V21).

| Case | Mutation (on the copy; main.gd edits inside `_run_map` only) | Expected (make rc, exact line) |
|---|---|---|
| `pristine` (positive control) | none | rc 0; `^similar-test guard: ok, main\.gd _run_map asks [A-Z0-9_]+_MINOR \(([1-9][0-9]+)\) >= SIMILAR_MINOR \(14\)$` once |
| D1 `below` (drill i) | the named constant → `SURFACE_MINOR` (13, the boundary below 14) | rc 2; `similar-test guard: main.gd _run_map asks SURFACE_MINOR (13) below SIMILAR_MINOR (14)` |
| D2 `exact` (drill ii) | → `SIMILAR_MINOR` | rc 2; `similar-test guard: main.gd asks SIMILAR_MINOR` (the existing S0.3 line) |
| D3 `removed` (drill iii) | the `want_minor` line deleted | rc 2; `similar-test guard: main.gd _run_map mentions want_minor 0 times, want 1` |
| D4 `literal` | `SimBridge.X_MINOR` → `13` | rc 2; `similar-test guard: main.gd _run_map want_minor is not one bare SimBridge minor` |
| D5 `twice` | a second `sim.want_minor = 2` after the line | rc 2; `similar-test guard: main.gd _run_map mentions want_minor 2 times, want 1` |
| D6 `unknown` | → `NO_SUCH_MINOR` | rc 2; `similar-test guard: NO_SUCH_MINOR unresolved in bridge/sim_bridge.gd` |
| D7 `nofloor` | `sim_bridge.gd`: `const SIMILAR_MINOR :=` renamed | rc 2; `similar-test guard: SIMILAR_MINOR unresolved in bridge/sim_bridge.gd` |
| D8 `ternary` (r1) | `SimBridge.X_MINOR` → `SimBridge.X_MINOR if capture else SimBridge.SURFACE_MINOR` (a below-floor branch) | rc 2; `similar-test guard: main.gd _run_map want_minor is not one bare SimBridge minor` |
| D9 `arith` (r1) | `SimBridge.X_MINOR` → `SimBridge.X_MINOR - 10` | rc 2; same line as D8 |
| D10 `exprconst` (r1) | `sim_bridge.gd` gains `const FOO_MINOR := 18 - 10`; the map session asks `FOO_MINOR` | rc 2; `similar-test guard: FOO_MINOR unresolved in bridge/sim_bridge.gd` |
| D11 `exprfloor` (r1) | `const SIMILAR_MINOR := 14` → `const SIMILAR_MINOR := 24 - 10` | rc 2; `similar-test guard: SIMILAR_MINOR unresolved in bridge/sim_bridge.gd` |
| D12 `comparison` (r2, kimi) | `if sim.want_minor == SimBridge.SURFACE_MINOR: pass` inserted after the line | rc 2; `similar-test guard: main.gd _run_map mentions want_minor 2 times, want 1` |
| D13 `compound` (r2, gpt6-1-sol) | `sim.want_minor -= 10` inserted after the line (the checked line is kept; the real minor becomes 8) | rc 2; `similar-test guard: main.gd _run_map mentions want_minor 2 times, want 1` |
| F `future` (drill iv) | `sim_bridge.gd` gains `const FUTURE_MINOR := <max+1>` (19 today; computed, not hard-coded); the map session asks `FUTURE_MINOR` | rc 0; `similar-test guard: ok, main.gd _run_map asks FUTURE_MINOR (19) >= SIMILAR_MINOR (14)` |
| C `comment` (r1) | `sim_bridge.gd` gains `const COMMENTED_MINOR := <max+1>  # a trailing comment`; the map session asks it | rc 0; `similar-test guard: ok, main.gd _run_map asks COMMENTED_MINOR (19) >= SIMILAR_MINOR (14)` |

The mutations never name today's constant (`EARTH_LOG_MINOR`). They rewrite whatever `SimBridge.*_MINOR` `_run_map` names, so the controls survive the next bump too. The pristine case also covers a trailing comment on the main.gd side: the real line `:304` ends in a `#` comment. Every guard branch has at least one measured run (V5): count ≠ 1 both ways (a deletion, a second assignment, a comparison, a compound write), not one bare name (literal, ternary, arithmetic), unresolved name (unknown, expression), unresolved floor (missing, expression), below the floor, names `SIMILAR_MINOR`, and ok (plain and commented).

**Why commit the controls rather than keep them as sprint evidence.** The precedent is 7aj's `display-audit-monitor-controls`. This guard went red at a bump that nobody noticed for four days, so it should prove on every run that it still guards. The controls cost 0.48–0.64 s (V5) against `similar-test`'s 30–53 s. They need no AILANG, Godot or git, and they leave the tree untouched (V10).

### M3. Wiring

- `similar-test: similar-main-guard similar-guard-controls`, as prerequisites. A bad main.gd now fails in under a second, before the 30–53 s of sessions. `make test` reaches both through `similar-test` (prerequisite 19 of `test`), so the controls are verified through that target (AC1) as well as directly (AC3).
- `ci-fast: similar-main-guard similar-guard-controls`, as a separate rule line beside the targets (the same pattern as `mk/script-gates.mk:27`). The `ci-fast:` line at `Makefile:55` is not edited. **Why ci-fast:** #379 merged on the fast tier with this guard red, because `similar-test` (sessions, about 50 s) is not in it. The guard and its controls cost under a second and use only POSIX `sh`, `sed`, `grep`, `cmp`, `mktemp` and `make`. They pass under dash and GNU Make 4.4.1 (V11, V12). Wired in, a PR that downgrades the map session goes red at the PR.

## Files touched and Do-not-touch

- **Touched:** `Makefile` (lines 100–131 only, Appendix A) and the new `tools/similar_guard_controls.sh` (Appendix B). The sprint's changelog fragment (`changelogs/unreleased/…`) and the charter and README status rows are routine landing edits.
- **Do not touch:**
  - `main.gd`, `bridge/sim_bridge.gd`, `demos/`, `ui/`, `sim/` and `tests/fixtures/protocol_*`;
  - the vector-read guard's logic (`Makefile:96–103`), beyond closing its zsh string one line earlier;
  - the `ci-fast:` and `test:` lines (55, 57);
  - anything in attended PR #412, whose Makefile hunk is the include list (`@@ -32,6 +32,7 @@`);
  - anything in #373 (Makefile hunks at 10, 18 and 225) or #380 (at 251). None of these overlaps lines 96–131 (V17).

## Acceptance criteria

All commands are headless and run in the fix clone with `export PATH=$PWD/runtime/bin:$PATH` (or the main checkout's `runtime/bin`). `B=79eadb49`. Expected outputs were measured with the revision-1 prototype (V4–V15, V19–V21).

| # | Criterion | Command | Expected |
|---|---|---|---|
| 1 | The full target is green, the guard and controls reached through it | `make similar-test > /tmp/7ah_st.log 2>&1; echo rc=$?; grep -cx 'similar-test guard: ok, main.gd _run_map asks EARTH_LOG_MINOR (18) >= SIMILAR_MINOR (14)' /tmp/7ah_st.log; grep -cx 'similar-guard-controls: 13 rejected, 3 accepted' /tmp/7ah_st.log; grep -c 'lost EARTH_MINOR' /tmp/7ah_st.log` | `rc=0`, then `1`, `1`, `0`. Every existing ranking, session, oracle and sha step still runs (the log ends with `…session-215-strict.ndjson`'s sha256 `a64e9634…`) |
| 2 | The guard alone | `make similar-main-guard; echo rc=$?` | `similar-test guard: ok, main.gd _run_map asks EARTH_LOG_MINOR (18) >= SIMILAR_MINOR (14)`, `rc=0` |
| 3 | Controls: 13 rejections and 3 acceptances, through the make target | `make similar-guard-controls; echo rc=$?` | the 16 case lines of the M2 table in order (`pristine`, `below`, `exact`, `removed`, `literal`, `twice`, `unknown`, `nofloor`, `ternary`, `arith`, `exprconst`, `exprfloor`, `comparison`, `compound`, `future`, `comment`), each `rejected (<exact line>)` or `accepted`, then `similar-guard-controls: 13 rejected, 3 accepted`, `rc=0`; wall time under 2 s |
| 4 | Drills (i)–(iv) required by the row, plus round 1's three | the `below`, `exact`, `removed`, `future`, `exprconst`, `arith` and `ternary` lines of AC3 | (i) rc 2 below the floor; (ii) rc 2 on the S0.3 line; (iii) rc 2 at 0 assignments; (iv) rc 0 for `FUTURE_MINOR (19)`; `exprconst` rc 2 `FOO_MINOR unresolved`; `arith` and `ternary` rc 2 `not one bare SimBridge minor` |
| 5 | The controls catch a weakened guard (meta-drills, sprint evidence; Appendix C, which works on scratch copies) | `sh /tmp/7ah_meta.sh "$PWD"; echo rc=$?` (Appendix C saved to `/tmp/7ah_meta.sh`; it mutates with awk and runs with BSD `/usr/bin/awk` and `/usr/bin/sed`) | `meta base: rc 0 :: similar-guard-controls: 13 rejected, 3 accepted`; then each weakening goes red at its own case: M1 (floor check deleted) → `below: make rc 0, want 2`; M2 (S0.3 line deleted) → `exact: make rc 0, want 2`; M3 (count check deleted) → `removed: missing reason: …`; M4 (the old `EARTH_MINOR` literal re-inserted) → `pristine: make rc 2, want 0` **and** `similar-test guard: main.gd lost EARTH_MINOR`; M5 (a no-op mutation) → `below: mutation left main.gd unchanged` (the script exits 3, make rc 2); M6 (constant resolver back to a prefix) → `exprconst: make rc 0, want 2`; M7 (floor resolver back to a prefix) → `exprfloor: missing reason: …`; M8 (name extraction back to revision 0) → `ternary: make rc 0, want 2`; M9 (the count back to revision 1's `grep -cE 'want_minor *= *[^= ]'`) → `comparison: make rc 0, want 2`; finally `meta: 9 weakenings caught`, `rc=0` |
| 6 | A no-op mutation exits 3 from the script itself | `sed '/^mutate below/s/want_minor \*= \*SimBridge/NOPE_NOPE/' tools/similar_guard_controls.sh > /tmp/7ah_noop.sh; MAKE=make sh /tmp/7ah_noop.sh .; echo rc=$?` | `similar-guard-controls: below: mutation left main.gd unchanged`, `rc=3` |
| 7 | The tree is never modified; temp dirs are removed after passing and failing runs | `h=$(shasum main.gd bridge/sim_bridge.gd Makefile); make similar-guard-controls >/dev/null; sh /tmp/7ah_meta.sh "$PWD" >/dev/null; test "$h" = "$(shasum main.gd bridge/sim_bridge.gd Makefile)" && git status --porcelain && find "${TMPDIR:-/tmp}" -maxdepth 1 \( -name 'similar-guard.*' -o -name 'stap7ah-meta.*' \) \| wc -l` | no `git status` output; `0` |
| 8 | The guard passes at every main.gd since S0.3, so a bump no longer breaks it | for each of `e151c903 523d96f9 8ba1e3c8 $B`: write `git show $c:main.gd` and `git show $c:bridge/sim_bridge.gd` into `$d/$c/`, then run `make -s similar-main-guard SIMILAR_GUARD_ROOT=$d/$c` | all rc 0: `EARTH_MINOR (16)` at the first two, `EARTH_LOG_MINOR (18)` at the last two |
| 9 | Robust to outer make flags and to dash and GNU make | `for m in make gmake; do for f in '' -n -j4 -k; do $m $f similar-guard-controls 2>&1 \| tail -1; done; done` (gmake if installed); `gmake SHELL=/bin/dash similar-main-guard` (if dash is installed); `shellcheck tools/similar_guard_controls.sh && shellcheck -s dash tools/similar_guard_controls.sh` | every run ends `similar-guard-controls: 13 rejected, 3 accepted` with no `warning` or `jobserver` line; dash rc 0; shellcheck silent |
| 10 | Wired into `ci-fast` and `similar-test` | the two commands in the AC10 block below the table (kept out of the table so the `|` alternations are not markdown-escaped) | count ≥ 2 (12 measured in V22); two lines, 114 and 115 in the prototype. After the push, the PR's GitHub `make ci-fast` check is green (`gh pr checks <PR>`) |
| 11 | Hygiene | `make uid-guard python-guard script-gate-lint audio-silent-guard; echo rc=$?` and `git diff --check $B; echo rc=$?` | `uid-guard: ok`, `python-guard: ok`, `script-gate-lint` rc 0 (the recipe has no `--script` call), `audio-silent-guard: ok`; `rc=0` both times |
| 12 | Diff scope | `git diff --name-only $B` | exactly `Makefile` and `tools/similar_guard_controls.sh`, plus the landing's changelog fragment, `design_docs/` and `.ailang/state/` files; nothing in `main.gd`, `bridge/`, `demos/`, `ui/`, `sim/` or `tests/` |
| 13 | No conflict with attended PRs | `git diff -U0 $B -- Makefile \| grep '^@@'` | hunks only within lines 100–136 (#412 edits 32–38; #373 10, 18, 225; #380 251) |

AC10 commands (outside the table so the `|` alternations are literal; the first is BRE `\|`, the second ERE `|`):

```sh
make -n ci-fast 2>/dev/null | grep -c '_run_map\|similar_guard_controls.sh'
grep -nE '^(similar-test|ci-fast): similar-main-guard similar-guard-controls$' Makefile
```

## Sub-milestones and estimates

| # | What | LOC | Depends | Order |
|---|---|---:|---|---|
| T1 | Write `tools/similar_guard_controls.sh` and the `similar-guard-controls` target first. Run it at `B`, which still has the old inline guard and no `similar-main-guard` target, and see it fail: make rc 2 at `pristine`, because the target does not exist yet | ~137 | none | 1 (red first) |
| M1 | Add `similar-main-guard`, remove `Makefile:104–105`, and close the zsh string at 103 | ~22 | T1 | 2. AC2 and AC3 go green |
| M3 | `similar-test` and `ci-fast` edges | 2 | M1 | 3. AC1 and AC10 |
| V | AC5–AC13, meta-drills | 0 | M3 | 4 |

## Risks and mitigations

- **`_run_map` is renamed or split.** The guard then fails loudly (`mentions want_minor 0 times`) rather than passing silently. The fix is a one-word edit to the range in the recipe and in the script's `RANGE`. Accepted: an explicit anchor is better than the whole-file maximum (b′).
- **A constant is defined by an expression** (for example `const FOO_MINOR := EARTH_LOG_MINOR + 1` or `18 - 10`). It does not resolve, and the guard fails with `FOO_MINOR unresolved`. Revision 1 makes this true: the resolver needs the whole right-hand side to be digits up to an optional `#` comment and the end of the line. Control D10 measures it, and D11 does the same for the floor. Revision 0's prefix resolver read `18 - 10` as 18 and passed (V19; round 1's blocking objection). Every protocol constant so far is a plain literal (V3). If an expression is ever wanted, extend the resolver to evaluate it; do not loosen the grammar.
- **The want_minor line takes another form.** Examples are a ternary (`SimBridge.X if a else SimBridge.Y`), arithmetic (`SimBridge.X - 10`), parentheses or a call. Revision 0's extractor, `.*want_minor *= *SimBridge\.([A-Z0-9_]+_MINOR).*`, captured the **first** `SimBridge` constant after the assignment and ignored the rest. So a ternary whose later branch is a downgrade passed, and so did arithmetic (V19). Round 1 (kimi) corrected revision 0's "last one" wording. Revision 1 requires one bare constant up to an optional comment, so every such form fails as `not one bare SimBridge minor`. Controls D8 and D9 measure it. If the game ever needs a conditional map minor, the guard must change with it, which is the point.
- **A commented-out `want_minor = …` inside `_run_map`** counts as an assignment and fails (`mentions want_minor 2 times`). That fails closed, and a comment rewording fixes it.
- **`make -n similar-test` executes the controls line.** That is standard make semantics for a `$(MAKE)` line. Because `MAKEFLAGS` is cleared for the inner make, the controls then really run, which is read-only and takes under a second (V11). No tool runs `-n` or `-q` on these targets; `tools/suite_profile.sh` queries a no-op target (V11).
- **The ci-fast runner (Ubuntu, dash, GNU make).** The recipe and script were measured locally under dash and GNU Make 4.4.1 (V11, V12), but not on GitHub's runner. AC10's post-push check closes that gap. If the runner is red for an environment reason, drop the `ci-fast:` edge (one line) rather than weaken the guard.

## Open questions for the user

None. The fix is test-only and changes nothing a player sees. It keeps the S0.3 guard's meaning and makes it survive protocol bumps.

## Follow-ups (new findings, not scope)

Every reference below was measured in V20.
- **F1. The session minors agree only by convention.** All three sessions ask `EARTH_LOG_MINOR`:
  - `main.gd:304` (map): `if not capture:sim.want_minor=SimBridge.EARTH_LOG_MINOR`;
  - `demos/ship_geometry_demo.gd:1025` (ship): `journey_sim.want_minor=SimBridge.EARTH_LOG_MINOR`;
  - `ui/loading_jump.gd:254` (the prefetch): `SimBridge.warm(SimBridge.EARTH_LOG_MINOR)`.

  The main.gd comment says the map asks "as the ship, so it adopts the loading jump's prefetch". **Premise, measured by reading the code:** `SimBridge._adopt_warm()` (`bridge/sim_bridge.gd:228–233`) returns false when `w.want_minor != want_minor`; the doc comment at `:196–199` says the same. `tests/test_loading_jump.gd:160–163` checks that "a start() with a launch override or another minor leaves the warm sim". That test was not run for this doc. Nothing checks that the three sessions agree. A bump that misses one would silently skip the prefetch: loading gets slower, with no error. **Hypothesis, not measured:** how much slower. A candidate row is one guard that resolves all three and requires them equal.
- **F2. Feature tests name today's minor literally.** `tests/test_bh_hud.gd:109` and `:176`, and `tests/test_comms_station.gd:133`, check `demo.journey_sim.want_minor == SimBridge.EARTH_LOG_MINOR`. These are feature checks, and the bump author is expected to update them. They will still go red at the next bump the way this guard did, outside `ci-fast`. They could be folded into F1's single source.
- **F3. `similar-test` itself is not in `ci-fast`.** This row adds only the guard and its controls, under a second. Whether the S0 sessions (about 30–50 s) belong in the fast tier is a tier-budget question for the 7ag test-tiering line, not this row.

## Deliverables

- `Makefile`: `similar-main-guard`, `similar-guard-controls`, the `similar-test` and `ci-fast` edges, and lines 104–105 removed (Appendix A).
- `tools/similar_guard_controls.sh` (Appendix B).
- Evidence for AC1–AC13 in the sprint JSON, including the meta-drill log (AC5).
- On landing, a changelog fragment and row 7ah's status in the charter.

## Verification log

Run on 2026-11-10 in `stapledons-godot-iter84` at `79eadb49`, on the Studio, with the AILANG v0.56.1 pinned runtime and macOS make (GNU Make 3.81). The tools were `/usr/bin/sed` and `/usr/bin/awk` (BSD); there is no GNU sed on PATH. V4–V15 and V19–V21 were re-measured with the revision-1 prototype (Appendices A and B), and the revision-0 values are noted where they differ. Both prototypes were reverted, and `git status --porcelain` was empty before each doc commit.

| # | Command | Result |
|---|---|---|
| V1 | `make -s similar-test` at `79eadb49`, unmodified | rc 2, 44 s wall; the last lines are `a64e9634…  .godot/tmp/similar/session-215-strict.ndjson`, `similar-test guard: main.gd lost EARTH_MINOR`, `make: *** [similar-test] Error 1` |
| V2 | `git log -S 'lost EARTH_MINOR' -- Makefile`; `git log -S 'asks SIMILAR_MINOR'`; the S0.3 rows of `sprint_R2-SIMILAR-S0.json`; `git show e151c903:main.gd \| grep -n want_minor` | Both lines came from `e151c903` (2026-10-31, S0.3). The sprint says "main.gd byte-identical … asking EARTH_MINOR (16)" and "source guards assert main.gd keeps SimBridge.EARTH_MINOR and never names SIMILAR_MINOR". At `e151c903`, `main.gd:304` was `if not capture:sim.want_minor=SimBridge.EARTH_MINOR` |
| V3 | `sed -n '/^func _run_map(/,/^func /p' main.gd \| grep -n want_minor`; `git grep -n _run_map -- main.gd`; `grep -n '^const .*_MINOR' bridge/sim_bridge.gd` | one assignment in `_run_map` (`main.gd:304`, `EARTH_LOG_MINOR`); `_run_map` is called from the title's map route (`:185`) and from `--map` (`:223`); every `*_MINOR` constant is a literal `const NAME := N` (1, 3–18) |
| V4 | r1 `make similar-main-guard` | rc 0; `similar-test guard: ok, main.gd _run_map asks EARTH_LOG_MINOR (18) >= SIMILAR_MINOR (14)` |
| V5 | r1 `time make similar-guard-controls` | rc 0, 0.48 s (0.64 s with the hygiene run); 16 case lines exactly as in the M2 table, ending `similar-guard-controls: 13 rejected, 3 accepted`; every guard branch exercised. (r0: 0.30 s, `7 rejected, 2 accepted`) |
| V6 | r1 `make similar-test` | rc 0, 32 s; `grep -cx` finds the guard's ok line once and `similar-guard-controls: 13 rejected, 3 accepted` once; `lost EARTH_MINOR` 0 times; the last line is the session-215 sha `a64e9634…`. (r0: rc 0, 53 s and 30 s) |
| V7 | r1 guard against historical heads: `git show <c>:main.gd` and `git show <c>:bridge/sim_bridge.gd` into a temp dir, then `make -s similar-main-guard SIMILAR_GUARD_ROOT=…` | `e151c903` rc 0 `EARTH_MINOR (16)`; `523d96f9` rc 0 `EARTH_MINOR (16)`; `8ba1e3c8` rc 0 `EARTH_LOG_MINOR (18)`; `79eadb49` rc 0 `EARTH_LOG_MINOR (18)`. The guard would have stayed green through #379 (same as r0) |
| V8 | r1 meta-drills (Appendix C as written, `ROOT` = the clone with the r1 prototype applied) | `meta base: rc 0 :: similar-guard-controls: 13 rejected, 3 accepted`; `M1_nofloor: rc 2 :: …below: make rc 0, want 2`; `M2_noexact: rc 2 :: …exact: make rc 0, want 2`; `M3_nocount: rc 2 :: …removed: missing reason: similar-test guard: main.gd _run_map mentions want_minor 0 times, want 1`; `M4_oldguard: rc 2 :: …pristine: make rc 2, want 0` (and its log has `similar-test guard: main.gd lost EARTH_MINOR`, so the old guard itself fired, not a Makefile parse error); `M5_noop: rc 2 :: …below: mutation left main.gd unchanged`; `M6_prefix_const: rc 2 :: …exprconst: make rc 0, want 2`; `M7_prefix_floor: rc 2 :: …exprfloor: missing reason: similar-test guard: SIMILAR_MINOR unresolved in bridge/sim_bridge.gd`; `M8_loose_name: rc 2 :: …ternary: make rc 0, want 2`; `meta: 9 weakenings caught`, rc 0. (r0: 5 weakenings, M4 by GNU-only sed escapes) |
| V9 | the no-op variant of the script, run directly with `sh` | rc 3; `similar-guard-controls: below: mutation left main.gd unchanged` |
| V10 | `shasum main.gd bridge/sim_bridge.gd` before and after all r1 runs; `find "$TMPDIR" -maxdepth 1 \( -name 'similar-guard.*' -o -name 'stap7ah-meta.*' \)` after passing and failing runs | sources unchanged; 0 leftover temp dirs; `git status --porcelain` showed only the prototype's `Makefile` and script |
| V11 | `make` (3.81) and `gmake` (4.4.1), each with `''`, `-n`, `-j4` and `-k`, on r1 `similar-guard-controls`; `git grep` for `make -n`/`-q` in tools; `sed -n 36,52p tools/suite_profile.sh` | all 8 runs rc 0, 13 rejections each, 0 warning or jobserver lines. In r0, before `MAKEFLAGS=''`, `make -n` made the inner make dry-run and the controls failed at `pristine`; that is why it was added. No tool dry-runs these targets; `suite_profile` runs `-pq` on a no-op target only |
| V12 | `gmake SHELL=/bin/dash similar-main-guard`; `MAKE=gmake dash tools/similar_guard_controls.sh .`; `shellcheck`; `shellcheck -s dash` (r1) | rc 0; `13 rejected, 3 accepted`; both shellchecks silent. r1's `exprconst` append was first single-quoted, which raised SC2016; it now uses the same double-quoted form as `future` |
| V13 | r1: `make uid-guard script-gate-lint python-guard`; `AUDIO_GUARD_FILES=tools/similar_guard_controls.sh sh tools/audio_silent_guard.sh`; `git diff --check`; `git diff --stat` | `uid-guard: ok (422 .uid files)`; script-gate-lint rc 0; `python-guard: ok (21 allowlisted, 0 awaiting AILANG port)`; `audio-silent-guard: ok`; diff-check rc 0; `Makefile \| 32 +++…---` (29+, 3−), `tools/similar_guard_controls.sh \| 135 +` |
| V14 | `sh tools/similar_guard_controls.sh` (no argument) | rc 1; `…: 1: usage: similar_guard_controls.sh ROOT` |
| V15 | r0 prototype: `make -n ci-fast \| grep -c '_run_map\|similar_guard_controls.sh'` | 2 matching recipe lines, so both edges are present. The `similar-test:` and `ci-fast:` edge lines are byte-identical in r1 (Appendix A) |
| V16 | `git grep -nE '[A-Z_]+_MINOR' -- Makefile 'mk/*.mk' tools/` | in make files, only `Makefile:104–105`; the `tools/*.gd` hits set their own sessions' minors and are not guards |
| V17 | `gh pr diff 412/373/380 --allow-escape-sequences`, Makefile hunk headers | #412 `@@ -32,6 +32,7 @@`; #373 `@@ -10,7`, `@@ -18,10`, `@@ -225,8`; #380 `@@ -251,6`. None in 96–132 |
| V18 | extract Appendices A, B and C from this doc with `awk`; `cmp` A (the inserted block) and B against the r1 prototype's added Makefile lines and script; `cmp` C against the meta-drill file run in V8 | all three byte-identical (r1). Appendix C is the exact file that produced V8 |
| V19 | (r1, round-1 reproduction) the r0 resolver and extractor on the objection's inputs: `echo 'const FOO_MINOR := 18 - 10' \| sed -nE 's/^const FOO_MINOR := ([0-9]+).*/\1/p'`; `echo 'sim.want_minor = SimBridge.A_MINOR if x else SimBridge.B_MINOR # c' \| sed -nE 's/.*want_minor *= *SimBridge\.([A-Z0-9_]+_MINOR).*/\1/p'`; `echo 'sim.want_minor = SimBridge.EARTH_LOG_MINOR - 10' \| …`; then the r0 and r1 `similar-main-guard` targets each run on four mutated roots (`exprconst`, `arith`, `ternary`, `exprfloor`, built as in D8–D11) | `18`, `A_MINOR` (the **first** constant), `EARTH_LOG_MINOR`. r0 target: `exprconst` **rc 0** `asks FOO_MINOR (18)`, `arith` **rc 0** `asks EARTH_LOG_MINOR (18)`, `ternary` **rc 0** `asks EARTH_LOG_MINOR (18)`, `exprfloor` rc 2 for the wrong reason (`below SIMILAR_MINOR (24)`). r1 target: `exprconst` rc 2 `FOO_MINOR unresolved in bridge/sim_bridge.gd`; `arith` and `ternary` rc 2 `main.gd _run_map want_minor is not one bare SimBridge minor`; `exprfloor` rc 2 `SIMILAR_MINOR unresolved in bridge/sim_bridge.gd` |
| V20 | (r1) the line references in Problem §3 and F1/F2: `git grep -n want_minor -- main.gd`; `git grep -n 'want_minor=SimBridge' -- demos/ship_geometry_demo.gd`; `git grep -n 'SimBridge.warm(' -- ui/loading_jump.gd`; `git grep -nE 'want_minor == SimBridge.EARTH_LOG_MINOR' -- tests/test_bh_hud.gd tests/test_comms_station.gd`; `sed -n 196,222p bridge/sim_bridge.gd`; `git grep -n _warm -- bridge/sim_bridge.gd`; `sed -n 228,236p bridge/sim_bridge.gd`; `sed -n 152,170p tests/test_loading_jump.gd` | `main.gd:258` `sim.want_minor = SimBridge.SYSTEM_MINOR if not _fixed_scale else sim.want_minor`; `:280` `sim.want_minor = 2`; `:304` `…want_minor=SimBridge.EARTH_LOG_MINOR`; `:414` `sim.want_minor = SimBridge.ISM_MINOR if args.has("ism-capture") else (2 if capture or smoke else …`; `demos/ship_geometry_demo.gd:1025` `journey_sim=SimBridge.new();journey_sim.want_minor=SimBridge.EARTH_LOG_MINO…`; `ui/loading_jump.gd:254` `holder["value"] = SimBridge.warm(SimBridge.EARTH_LOG_MINOR)`; `tests/test_bh_hud.gd:109` and `:176`, `tests/test_comms_station.gd:133` match `want_minor == SimBridge.EARTH_LOG_MINOR`; `bridge/sim_bridge.gd:196–199` doc comment "(no launch_override, no record_path, the same want_minor) takes it over"; `:232` `if w == null or not launch_override.is_empty() or record_path != "" or w.want_minor != want_minor: return false`; `tests/test_loading_jump.gd:160–163` `other.want_minor = SimBridge.PROTO_MINOR … check(SimBridge.has_warm(), "a start() with a launch override or another minor leaves the warm sim")` (read, not run) |
| V21 | (r1) portability: `command -v sed awk`; the controls (all `sed -E` mutations, `$a\` appends, the backslash-newline insert) and Appendix C (awk with `ENVIRON`, `index`, `substr`, and a `\t`-free inserted line) run under `/usr/bin/sed` and `/usr/bin/awk` | `/usr/bin/sed`, `/usr/bin/awk`; the controls rc 0 with `13 rejected, 3 accepted`; Appendix C rc 0 with `9 weakenings caught`. M4 now inserts its line with awk `print ENVIRON["NEW"]`, a literal-tab string with no escape processing, and also asserts the old guard's own reason line |
| V22 | (r2, controller, round-2 measurements) `sed -n 304p main.gd`; `printf '%s\n' '<line>' \| grep -cE 'want_minor *= *[^= ]'` for `if want_minor == 14:`, `func _run_map(want_minor := 0):`, `sim.want_minor -= 10`, `sim.want_minor+=1`, `sim.set("want_minor", 8)`, `sim.want_minor=SimBridge.EARTH_LOG_MINOR`; the r1 target on a copy whose `_run_map` gains `sim.want_minor -= 10` after line 304; then the r2 prototype: `make similar-guard-controls`, `make similar-test`, the AC8 heads, AC9's 8 make variants, dash, shellcheck, hygiene, AC10, Appendix C | `:304` is `if not capture:sim.want_minor=SimBridge.EARTH_LOG_MINOR # R3-COMMS-V2: 2.18 (as the ship; 2.17 is R3-WORLDS); R3-EARTH-LINK: 2.16 …`, so it **does** end in a `#` comment and the pristine case covers the assignment-side comment branch (glm's premise; the earlier quotes were elided). Revision 1's count pattern: 0, 0, 0, 0, 0, 1. So `==` and `:=` were **not** counted (kimi's ERE claim is refuted), and neither were compound writes. r1 target with `-= 10`: **rc 0**, `ok … asks EARTH_LOG_MINOR (18)` (gpt6-1-sol's hole reproduced). r2: controls rc 0, `13 rejected, 3 accepted` (D12 and D13 each `mentions want_minor 2 times, want 1`); `similar-test` rc 0 in 36 s, the ok line once, the controls summary once, `lost EARTH_MINOR` 0 times, last line the session-215 sha `a64e9634…`; AC8 heads all rc 0 (16, 16, 18, 18); 8 of 8 make variants end `13 rejected, 3 accepted`; `gmake SHELL=dash` rc 0, dash controls `13 rejected, 3 accepted`; shellcheck and `-s dash` clean; `uid-guard: ok (422 .uid files)`, `python-guard`, `script-gate-lint`, `audio-silent-guard` ok; `git diff --check` rc 0; `Makefile` 31+ 3−, script 147 lines; AC10 count 12 and lines 114/115; Appendix C (r2) rc 0, `meta: 9 weakenings caught`, M9 red at `comparison`. Appendices A–C `cmp` byte-identical to the r2 prototype (`/tmp/stap_i84_7ah_prototype_r2.patch`, sha256 `1945fc9b…`), then reverted; `git status --porcelain` empty |

## Quorum verification log

**Round 1 (2026-11-10T14:36:49Z): BLOCKED 2/3, `absent_reviewers` empty, total cost $0.4612.** Seats: `oc-glm-5-3` pass ($0.1097), `oc-kimi-k3` pass ($0.3217), `gpt6-1-sol` reject ($0.0299). The controller also passed in session, having reproduced V1. Artifact: `~/.ailang/state/mission-quorum-repos/sunholo-data/stapledons-godot/m4-7ah-similar-guard-minor-2026-11-10T14-36-49Z.json`. No seat disputed the direction (a property guard over `_run_map`).

**gpt6-1-sol (blocking).** "The guard silently accepts downgrades because its resolver reads numeric prefixes rather than complete constant values … `const FOO_MINOR := 18 - 10` … passes as minor 18." The catch adds `sim.want_minor = SimBridge.EARTH_LOG_MINOR - 10`, and the proposed fix adds a conditional with a below-floor branch.

*What changed:*
- Both resolvers and the assignment extractor are now end-anchored and fail closed (M1 steps 3–4; Appendix A).
- New committed controls: D8 `ternary`, D9 `arith`, D10 `exprconst` (the reviewer's exact `18 - 10`), D11 `exprfloor`, and the positive C `comment`.
- New meta-drills: M6, M7 and M8 put each revision-0 regex back and prove the controls go red.
- V19 reproduces all three false acceptances on the revision-0 target (rc 0) and their rejection on revision 1 (rc 2).
- The Risks section no longer claims expression constants fail when they did not.

**oc-kimi-k3 (non-blocking).**
1. *The Risks section said the name sed "takes the last one".* Measured (V19): revision 0 captured the first constant (`A_MINOR`). The wording is corrected, and the blind spot is closed rather than documented: a line naming more than one constant, or any expression, now fails as `not one bare SimBridge minor` (D8, D9).
2. *Appendix C's M4 relied on GNU-sed `\n`/`\t` escapes.* All meta-drill mutations are now awk (`ENVIRON`, `index`, `substr`) and were run with BSD `/usr/bin/awk` and `/usr/bin/sed` (V21). M4 also now asserts `similar-test guard: main.gd lost EARTH_MINOR`, which shows the old guard fired rather than a Makefile parse error.
3. *Unverified line references.* See V20, below.

**oc-glm-5-3 and oc-kimi-k3 (non-blocking): line references with no verification row.** V20 measures every file:line cited in Problem §3 and F1/F2. They all held as cited. F1's warm-sim premise is now backed by the code (`bridge/sim_bridge.gd:232`) and the test's own text (`tests/test_loading_jump.gd:160–163`, read, not run). The size of the slowdown remains labelled a hypothesis.

**Round 2 (2026-11-10T14:49:25Z): BLOCKED 3/3, `absent_reviewers` empty, total cost $0.4487, same seats.** Artifact `…/m4-7ah-similar-guard-minor-2026-11-10T14-49-25Z.json`. Every objection is on one surface, the `want_minor` count in M1 step 2, and none disputes the direction. Each carried a concrete fix.
- **gpt6-1-sol: a compound write after the checked line passes.** *Measured true* (V22: the r1 target accepts `sim.want_minor -= 10`, rc 0, as minor 18). Its fix, applied: "reject any want_minor write other than the single permitted bare-constant assignment … conservatively reject additional code occurrences that it cannot classify … Add a committed mutation that preserves the existing assignment and inserts `sim.want_minor -= 10` afterward; require a specific rejection message and no success line. Add a verification-log row …". Done as follows: the count is now every occurrence of `want_minor` in `_run_map`, and it must be 1 (M1 step 2); D13 `compound`; V22.
- **oc-kimi-k3: `==` comparisons and `:=` defaults match the count pattern.** *Measured false* (V22: 0 matches for each). The pattern requires `=` straight after the optional spaces, so `==` fails at its second `=` and `:=` at the `:`. The fix it proposed is still applied, because revision 2's broad count makes its wording true: M1 step 2 now says the count is deliberately broad and that comparisons and defaults over-count and fail closed. Kimi's D12 `comparison` control is added with the message the new count prints, and meta-drill M9 puts revision 1's narrow count back and sees D12 go red.
- **oc-glm-5-3: the doc quotes `main.gd:304` without a comment but claims the pristine case covers a trailing comment.** *Premise measured* (V22): the line does end in a long `#` comment. The quotes were elided. Its fix's second branch, applied: the Problem §1 quote now shows the comment, and V20/V22 note the elision. Its AC10 note is applied too: AC10's commands moved below the table, with BRE `\|` and ERE `|` written literally.

*Revision 2 is by the controller*, under the narrow-refinement carve-out (`gate-2-pick.md`): every remaining blocking objection carries a reviewer-authored fix, and none disputes the direction. It applies those fixes and is re-measured end to end (V22). There is no round 3; the doc routes to the planner. Objections by surface: round 1, the value resolvers; round 2, the occurrence count. Each round's objections landed on the surface the previous revision had left narrowest. Neither round touched the property, the scope (`_run_map`) or the wiring.

## Appendix A. The Makefile change (revision-2 prototype, verbatim)

The change is shown as plain text, not a raw diff, because diff context lines (a space before a recipe tab) would fail `git diff --check` on this doc. There are three edits:
1. `Makefile:103` is the vector-read guard's last line. Its ending `fi; \` becomes `fi'`, which closes the zsh string one line earlier. Nothing else on the line changes.
2. `Makefile:104–105` are deleted. They are `git grep -q "SimBridge.EARTH_MINOR" -- main.gd || { … lost EARTH_MINOR … }; \` and `if git grep -q "SIMILAR_MINOR" -- main.gd; then … asks SIMILAR_MINOR …; fi'`.
3. This block is inserted after line 103, preceded by one blank line. The blank line before `# Recording is separate from test.` stays.

```make
# Row 7ah: the map session main.gd starts (_run_map) must ask a SimBridge minor at or above SIMILAR_MINOR, so its
# new_game carries `similar` (R2-SIMILAR-S0), and main.gd must never name SIMILAR_MINOR (S0.3: the game keeps its newer
# minor). Both numbers are read from bridge/sim_bridge.gd, so a protocol bump passes and a downgrade fails. Fail-closed
# grammar: the assignment is exactly `want_minor = SimBridge.<NAME>_MINOR` and each constant exactly `const <NAME> := <digits>`,
# each optionally followed by a `#` comment; anything else (an expression, a ternary, a literal) is rejected. _run_map must
# mention want_minor exactly once, so a second write (`-=`, `+=`, a reassignment), a comparison or a comment fails closed.
# SIMILAR_GUARD_ROOT is where main.gd and bridge/sim_bridge.gd are read; similar-guard-controls points it at mutated copies.
SIMILAR_GUARD_ROOT ?= .
.PHONY: similar-main-guard similar-guard-controls
similar-test: similar-main-guard similar-guard-controls
ci-fast: similar-main-guard similar-guard-controls
similar-main-guard: ## 7ah: main.gd's map session asks a SimBridge minor >= SIMILAR_MINOR, and never SIMILAR_MINOR
	@set -eu; r='$(SIMILAR_GUARD_ROOT)'; g="$$r/main.gd"; b="$$r/bridge/sim_bridge.gd"; \
	  test -f "$$g" && test -f "$$b" || { echo "similar-test guard: missing $$g or $$b" >&2; exit 1; }; \
	  body=$$(sed -n '/^func _run_map(/,/^func /p' "$$g"); \
	  n=$$(printf '%s\n' "$$body" | awk '{ n += gsub(/want_minor/, "") } END { print n + 0 }'); \
	  test "$$n" = 1 || { echo "similar-test guard: main.gd _run_map mentions want_minor $$n times, want 1" >&2; exit 1; }; \
	  set_lines=$$(printf '%s\n' "$$body" | grep want_minor); \
	  name=$$(printf '%s\n' "$$set_lines" | sed -nE 's/^[^#]*want_minor *= *SimBridge\.([A-Z0-9_]+_MINOR)[[:space:]]*(#.*)?$$/\1/p'); \
	  test -n "$$name" || { echo "similar-test guard: main.gd _run_map want_minor is not one bare SimBridge minor" >&2; exit 1; }; \
	  want=$$(sed -nE "s/^const $$name := ([0-9]+)[[:space:]]*(#.*)?$$/\1/p" "$$b"); \
	  floor=$$(sed -nE 's/^const SIMILAR_MINOR := ([0-9]+)[[:space:]]*(#.*)?$$/\1/p' "$$b"); \
	  case "$$want" in ''|*[!0-9]*) echo "similar-test guard: $$name unresolved in bridge/sim_bridge.gd" >&2; exit 1;; esac; \
	  case "$$floor" in ''|*[!0-9]*) echo "similar-test guard: SIMILAR_MINOR unresolved in bridge/sim_bridge.gd" >&2; exit 1;; esac; \
	  test "$$want" -ge "$$floor" || { echo "similar-test guard: main.gd _run_map asks $$name ($$want) below SIMILAR_MINOR ($$floor)" >&2; exit 1; }; \
	  if grep -q SIMILAR_MINOR "$$g"; then echo "similar-test guard: main.gd asks SIMILAR_MINOR" >&2; exit 1; fi; \
	  echo "similar-test guard: ok, main.gd _run_map asks $$name ($$want) >= SIMILAR_MINOR ($$floor)"
similar-guard-controls: ## 7ah: similar-main-guard rejects each mutation of main.gd's map-session minor and accepts a future bump
	@MAKE='$(MAKE)' sh tools/similar_guard_controls.sh .
```

## Appendix B. `tools/similar_guard_controls.sh` (revision-2 prototype, verbatim)

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
reject removed 'similar-test guard: main.gd _run_map mentions want_minor 0 times, want 1'

# D4: a literal instead of a SimBridge constant.
copy literal
mutate literal main.gd "${RANGE}s/(want_minor *= *)SimBridge\.[A-Z0-9_]+_MINOR/\113/"
reject literal 'similar-test guard: main.gd _run_map want_minor is not one bare SimBridge minor'

# D5: a second, later assignment in _run_map (a downgrade after the checked line).
copy twice
mutate twice main.gd "${RANGE}s/^(.*want_minor *= *SimBridge\.[A-Z0-9_]+_MINOR.*)$/\1\\
	sim.want_minor = 2/"
reject twice 'similar-test guard: main.gd _run_map mentions want_minor 2 times, want 1'

# D6: a constant sim_bridge.gd does not define.
copy unknown
mutate unknown main.gd "${RANGE}s/(want_minor *= *SimBridge\.)[A-Z0-9_]+_MINOR/\1NO_SUCH_MINOR/"
reject unknown 'similar-test guard: NO_SUCH_MINOR unresolved in bridge/sim_bridge.gd'

# D7: SIMILAR_MINOR gone from sim_bridge.gd (the floor cannot be read).
copy nofloor
mutate nofloor bridge/sim_bridge.gd 's/^const SIMILAR_MINOR := /const SIMILAR_MINOR_GONE := /'
reject nofloor 'similar-test guard: SIMILAR_MINOR unresolved in bridge/sim_bridge.gd'

# D8: a conditional with a below-floor branch (the first branch keeps today's constant).
copy ternary
mutate ternary main.gd "${RANGE}s/(want_minor *= *SimBridge\.[A-Z0-9_]+_MINOR)/\1 if capture else SimBridge.SURFACE_MINOR/"
reject ternary 'similar-test guard: main.gd _run_map want_minor is not one bare SimBridge minor'

# D9: arithmetic on today's constant (a downgrade the name alone would hide).
copy arith
mutate arith main.gd "${RANGE}s/(want_minor *= *SimBridge\.[A-Z0-9_]+_MINOR)/\1 - 10/"
reject arith 'similar-test guard: main.gd _run_map want_minor is not one bare SimBridge minor'

# D10: an expression-valued constant (18 - 10 = 8; a numeric-prefix reader would see 18).
copy exprconst
mutate exprconst bridge/sim_bridge.gd "\$a\\
const FOO_MINOR := 18 - 10
"
mutate exprconst main.gd "${RANGE}s/(want_minor *= *SimBridge\.)[A-Z0-9_]+_MINOR/\1FOO_MINOR/"
reject exprconst 'similar-test guard: FOO_MINOR unresolved in bridge/sim_bridge.gd'

# D11: an expression-valued floor (24 - 10 = 14; a numeric-prefix reader would see 24).
copy exprfloor
mutate exprfloor bridge/sim_bridge.gd 's/^const SIMILAR_MINOR := [0-9]+/const SIMILAR_MINOR := 24 - 10/'
reject exprfloor 'similar-test guard: SIMILAR_MINOR unresolved in bridge/sim_bridge.gd'

# D12: a comparison on want_minor in _run_map (r2, quorum round 2): any second mention fails closed.
copy comparison
mutate comparison main.gd "${RANGE}s/^(.*want_minor *= *SimBridge\.[A-Z0-9_]+_MINOR.*)$/\1\\
	if sim.want_minor == SimBridge.SURFACE_MINOR: pass/"
reject comparison 'similar-test guard: main.gd _run_map mentions want_minor 2 times, want 1'

# D13: a compound write after the checked line keeps it intact and downgrades to 8 (r2, quorum round 2).
copy compound
mutate compound main.gd "${RANGE}s/^(.*want_minor *= *SimBridge\.[A-Z0-9_]+_MINOR.*)$/\1\\
	sim.want_minor -= 10/"
reject compound 'similar-test guard: main.gd _run_map mentions want_minor 2 times, want 1'

# F: a future protocol bump: a new constant one above the highest minor, asked by the map session.
copy future
next=$(( $(sed -nE 's/^const [A-Z0-9_]+_MINOR := ([0-9]+).*/\1/p' "$tmp/future/bridge/sim_bridge.gd" | sort -n | tail -1) + 1 ))
test "$next" -gt 14 || { echo "similar-guard-controls: future: next minor $next" >&2; exit 1; }
mutate future bridge/sim_bridge.gd "\$a\\
const FUTURE_MINOR := $next
"
mutate future main.gd "${RANGE}s/(want_minor *= *SimBridge\.)[A-Z0-9_]+_MINOR/\1FUTURE_MINOR/"
accept future "^similar-test guard: ok, main\\.gd _run_map asks FUTURE_MINOR \\($next\\) >= SIMILAR_MINOR \\(14\\)\$"

# C: the same bump with a trailing comment on the constant (the one suffix the grammar allows).
copy comment
mutate comment bridge/sim_bridge.gd "\$a\\
const COMMENTED_MINOR := $next  # a trailing comment
"
mutate comment main.gd "${RANGE}s/(want_minor *= *SimBridge\.)[A-Z0-9_]+_MINOR/\1COMMENTED_MINOR/"
accept comment "^similar-test guard: ok, main\\.gd _run_map asks COMMENTED_MINOR \\($next\\) >= SIMILAR_MINOR \\(14\\)\$"

test "$rejected" -eq 13 || { echo "similar-guard-controls: $rejected rejected, want 13" >&2; exit 1; }
test "$accepted" -eq 3 || { echo "similar-guard-controls: $accepted accepted, want 3" >&2; exit 1; }
echo "similar-guard-controls: $rejected rejected, $accepted accepted"
```

(The D5 replacement's second line starts with a literal tab.)

## Appendix C. Meta-drills (sprint evidence, not committed; the exact file run in V8 and V21)

At the fix head this runs with no patch step: it copies the build files from `ROOT` and weakens the copy. Every mutation is an awk program that reads `OLD` and `NEW` from the environment, so nothing depends on GNU sed escapes. Shellcheck reports only SC2016 infos, all for intentional literal `$` strings.

```sh
#!/bin/sh
# 7ah meta-drills: weaken the guard in a scratch copy and prove similar-guard-controls goes red at the named case.
# Mutations are awk programs (portable: BSD, GNU and busybox awk; no sed replacement escapes).
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
# drill NAME FILE WANT_RC AWK_PROGRAM ERE [ERE2]: each ERE must match exactly one line of the controls' output.
# The awk program reads OLD and NEW from the environment (ENVIRON: no escape processing).
drill() {
  rm -rf "$w/d" || exit 1; cp -R "$w/base" "$w/d" || exit 1
  awk "$4" "$w/base/$2" > "$w/d/$2" || exit 1
  if cmp -s "$w/base/$2" "$w/d/$2"; then echo "meta $1: mutation changed nothing" >&2; exit 3; fi
  rc=0; MAKEFLAGS='' make -s -C "$w/d" similar-guard-controls > "$w/$1.log" 2>&1 || rc=$?
  test "$rc" -eq "$3" || { echo "meta $1: rc $rc want $3" >&2; cat "$w/$1.log" >&2; exit 1; }
  test "$(grep -cE "$5" "$w/$1.log")" -eq 1 || { echo "meta $1: no line $5" >&2; cat "$w/$1.log" >&2; exit 1; }
  if [ -n "${6:-}" ]; then test "$(grep -cE "$6" "$w/$1.log")" -eq 1 || { echo "meta $1: no line $6" >&2; cat "$w/$1.log" >&2; exit 1; }; fi
  red=$((red + 1)); echo "meta $1: rc $rc :: $(grep -E "$5" "$w/$1.log")"
}
DEL='index($0, ENVIRON["OLD"]) == 0'
SUB='{ i = index($0, ENVIRON["OLD"]); if (i) $0 = substr($0, 1, i - 1) ENVIRON["NEW"] substr($0, i + length(ENVIRON["OLD"])); print }'
# positive control: the unweakened copy passes and its summary is captured
rc=0; MAKEFLAGS='' make -s -C "$w/base" similar-guard-controls > "$w/base.log" 2>&1 || rc=$?
test "$rc" -eq 0 || { echo "meta base: rc $rc" >&2; cat "$w/base.log" >&2; exit 1; }
test "$(grep -cx 'similar-guard-controls: 13 rejected, 3 accepted' "$w/base.log")" -eq 1 || exit 1
echo "meta base: rc 0 :: $(tail -1 "$w/base.log")"
export OLD NEW
OLD='test "$$want" -ge'; drill M1_nofloor Makefile 2 "$DEL" '^similar-guard-controls: below: make rc 0, want 2$'
OLD='if grep -q SIMILAR_MINOR'; drill M2_noexact Makefile 2 "$DEL" '^similar-guard-controls: exact: make rc 0, want 2$'
OLD='test "$$n" = 1'; drill M3_nocount Makefile 2 "$DEL" '^similar-guard-controls: removed: missing reason: '
OLD='similar-main-guard: ##'
NEW='	@grep -q "SimBridge.EARTH_MINOR" "$(SIMILAR_GUARD_ROOT)/main.gd" || { echo "similar-test guard: main.gd lost EARTH_MINOR" >&2; exit 1; }'
drill M4_oldguard Makefile 2 '{ print } index($0, ENVIRON["OLD"]) == 1 { print ENVIRON["NEW"] }' '^similar-guard-controls: pristine: make rc 2, want 0$' '^similar-test guard: main.gd lost EARTH_MINOR$'
OLD='want_minor *= *SimBridge'; NEW='NOPE_NOPE'
drill M5_noop tools/similar_guard_controls.sh 2 '{ if (index($0, "mutate below") == 1) { i = index($0, ENVIRON["OLD"]); $0 = substr($0, 1, i - 1) ENVIRON["NEW"] substr($0, i + length(ENVIRON["OLD"])) } print }' '^similar-guard-controls: below: mutation left main.gd unchanged$'
OLD='const $$name := ([0-9]+)[[:space:]]*(#.*)?$$/'; NEW='const $$name := ([0-9]+).*/'
drill M6_prefix_const Makefile 2 "$SUB" '^similar-guard-controls: exprconst: make rc 0, want 2$'
OLD='const SIMILAR_MINOR := ([0-9]+)[[:space:]]*(#.*)?$$/'; NEW='const SIMILAR_MINOR := ([0-9]+).*/'
drill M7_prefix_floor Makefile 2 "$SUB" '^similar-guard-controls: exprfloor: missing reason: '
OLD='^[^#]*want_minor *= *SimBridge\.([A-Z0-9_]+_MINOR)[[:space:]]*(#.*)?$$/'; NEW='.*want_minor *= *SimBridge\.([A-Z0-9_]+_MINOR).*/'
drill M8_loose_name Makefile 2 "$SUB" '^similar-guard-controls: ternary: make rc 0, want 2$'
OLD='awk '"'"'{ n += gsub(/want_minor/, "") } END { print n + 0 }'"'"''; NEW='grep -cE '"'"'want_minor *= *[^= ]'"'"' || true'
drill M9_narrow_count Makefile 2 "$SUB" '^similar-guard-controls: comparison: make rc 0, want 2$'
test "$red" -eq 9 || exit 1
echo "meta: 9 weakenings caught"
```
