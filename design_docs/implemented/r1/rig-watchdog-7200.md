# Rig watchdog 7,200 s, and a hermetic rig-check control

**Status:** Implemented 2026-10-28 (mission iteration 55; PR #345, merge `d63b47a4`; evaluation Sonnet 95/100 PASS; `rig/full` green 117 min). **Release:** r1. **Milestone:** none (merge tooling).
**Priority:** P1. It protects every landing: `rig/full` on PR #341 took 90 min, which is the whole 5,400 s watchdog.
**Implements:** ledger [D-126](../../stapledon-mission.md) answer **C**, the **A half only** (Mark, attended 2026-10-28: "raise the rig/full watchdog default to 7,200 s (TEST_S=${RIG_TEST_S:-7200} and the make-test-red case in tools/test_rig_check.sh)"). It also covers the charter's iteration 52 backlog note: "`tools/test_rig_check.sh` inherits `RIG_TEST_S` from the caller ... (unset it in the test)". The B half (moving L4 ahead of Kerr a4) is a charter edit that the controller makes. L4 itself is a separate item.
**Depends on:** row 7o landed (PR #309, `tools/test_rig_check.sh` inside `make test` via `mk/m45.mk`); AILANG v0.54.18. No sim, package, physics, scene or player-visible change.
**Estimated LOC:** 17 lines in total, as measured on the prototype diff (V17).
- `tools/rig_check.sh`: 1 changed line.
- `tools/test_rig_check.sh`: 16 lines, 11 added and 5 changed.
  - Added: the hermetic `unset` (1 line), the `watchdog-override` case and its comment (2), and the `caller-poison` guard (8).
  - Changed: the header, the `run` usage comment, the `run` invocation, the `make-test-red` expectation, and the trailer.
- Zero lines in `Makefile`, `mk/` and the charter.

## Game vision alignment

| Pillar | Relevance | Score | Notes |
|---|---|---:|---|
| Choices Are Final | 0 | 0 | No game code. |
| The Game Doesn't Judge | 0 | 0 | No player-facing copy. |
| Time Has Emotional Weight | 0 | 0 | No clocks. |
| The Ship Is Home | 0 | 0 | No scene. |
| Grounded Strangeness | 0 | 0 | No visuals. |
| We Are Not Built For This | 0 | 0 | No crew. |
| Hard sci-fi authenticity (spec) | 0 | 0 | No physics. |
| **Net** | | **0** | **Go.** This is merge-tooling hygiene that Mark ruled directly (D-126 C). D-88 A applies: test and audit hygiene does not stop at a 0 net. |

## Problem

1. **The watchdog equals the suite's measured duration.** `tools/rig_check.sh:15` reads `TEST_S=${RIG_TEST_S:-5400}   # make test is ~50 min on the Studio` (V1). The `rig/full` runs on record took 65, 66, 66–77, 90 and 99 min. The 99-min run used `RIG_TEST_S=9000`. Iteration 45 timed out twice at 5,400 s with 0 failures (V13). Under load, a green suite gets posted as a failure.
2. **The control pins the old default.** The `make-test-red` case at `tools/test_rig_check.sh:47` expects `make test failed or ran over 5400s$` (V2). Raising the default alone would turn `make rig-check-control` red.
3. **The control is not hermetic, and this reproduces at HEAD `7e0e6860`.** The script sets `RIG_DIR`, `RIG_NO_STATUS` and the stubs for each case, but never sets `RIG_TEST_S`. A caller's value therefore reaches `rig_check.sh`:
   - `RIG_TEST_S=1234 sh tools/test_rig_check.sh tools/rig_check.sh` gives rc 1, `6 cases, 1 failures`, with `make-test-red` failing. The paired run with the variable unset gives rc 0 (V4).
   - Through make, `RIG_TEST_S=6600 make rig-check-control` gives make rc 2, and `env -u RIG_TEST_S` gives rc 0 (V4).
   - The case posts `01234567: make test failed or ran over 1234s` (V5). This shows that the override is honoured and that the control is what breaks.
   - `rig_check.sh` runs `make test` with its own environment, so an operator who raises the watchdog turns their own `rig/full` red. Iteration 52 hit exactly this with `RIG_TEST_S=6600` (V14).
   - The hole matters more once the default moves: the escape hatch is the only tool for a loaded rig, and it must not trip the suite it guards.
   - **The rest of the caller-reachable `RIG_*` surface** (V16):
     - `rig_check.sh` reads `RIG_DIR`, `RIG_NO_STATUS`, `RIG_TEST_S` and `RIG_GOLDEN_S`.
     - The control already pins `RIG_DIR` and `RIG_NO_STATUS=0` on every call.
     - No case reaches the golden path, so `RIG_GOLDEN_S=1` leaves both the script and make at rc 0 with `6 cases, 0 failures`.
     - `RIG_TEST_S` is the only leak.

## Goals and non-goals

**Goals.**
- The default watchdog is 7,200 s.
- The control expects 7,200 s, which pins the default.
- The control is hermetic against a caller's `RIG_TEST_S`. The `unset` also clears `RIG_GOLDEN_S` as prophylaxis, though no current case reads it.
- Hermeticity is checked on every run, not only by a drill: a committed `caller-poison` case re-runs the control under a poisoned caller environment. Deleting the `unset` turns a clean-environment run red.
- A new control case proves an explicit `RIG_TEST_S` still sets the watchdog.
- Each of the three properties has a mutation drill that kills its mutant.

**Non-goals.**
- `GOLDEN_S` (1,800 s) is unchanged.
- No change to `rig_check.sh`'s flow, status wording or clone. The only change is the default.
- No `Makefile` or `mk/` edit. `rig-check-control` stays out of `ci-fast` (V6), as row 7o deferred it.
- No L4 or test-suite speed work, and no charter edit by the executor.

## Design

### 1. `tools/rig_check.sh`: one line

```diff
-TEST_S=${RIG_TEST_S:-5400}   # make test is ~50 min on the Studio
+TEST_S=${RIG_TEST_S:-7200}   # make test is 66-90 min on the Studio; D-126 C (Mark, 2026-10-28)
```

The `${RIG_TEST_S:-…}` form stays, so the override keeps working: an empty or unset value means the default. 7,200 s leaves 30 min over the 90-min run and 21 min over the 99-min loaded run (V13).

### 2. `tools/test_rig_check.sh`: hermetic, the new default, one override case

```diff
@@ header
-# Row 7o control: tools/rig_check.sh must post only descriptions GitHub accepts (at most 140
+# Row 7o and D-126 control: tools/rig_check.sh must post only descriptions GitHub accepts (at most 140
@@ after set -eu
+unset RIG_TEST_S RIG_GOLDEN_S   # hermetic: a caller's watchdog override must not reach the cases (iteration 52)
@@ run()
-# run <case> ... <RIG_DIR> [clone]
+# run <case> ... <RIG_DIR> [clone] [RIG_TEST_S]
-  rc=0; STUB_VERSION=$6 ... sh "$RIG" 7 > "$T/out" 2>&1 || rc=$?
+  rc=0; ( if [ -n "${10:-}" ]; then RIG_TEST_S=${10}; export RIG_TEST_S; fi; STUB_VERSION=$6 ... sh "$RIG" 7 ) > "$T/out" 2>&1 || rc=$?
-run make-test-red 1 failure '01234567: make test failed or ran over 5400s$' ...
+run make-test-red 1 failure '01234567: make test failed or ran over 7200s$' ...
@@ after clone-red-pointer
+# An explicit RIG_TEST_S still sets the watchdog (the escape hatch, D-126).
+run watchdog-override 1 failure '01234567: make test failed or ran over 60s$' '^rig-check: FAIL: make test failed or ran over 60s ' 'AILANG v0.54.14' test "$pad" '' 60
-echo "rig-check control: 6 cases, $fails failures"
+# caller-poison: the whole control again under a caller's overrides; it must stay green (D-126, iteration 52).
+n=7
+if [ -z "${RIG_CHECK_NESTED:-}" ]; then
+  n=8; nrc=0
+  RIG_CHECK_NESTED=1 RIG_TEST_S=1234 RIG_GOLDEN_S=7 sh "$0" "$RIG" > "$T/nested.log" 2>&1 || nrc=$?
+  nok=$(grep -c ': ok$' "$T/nested.log" || true)
+  if [ "$nrc" = 0 ] && [ "$nok" = 7 ]; then echo "rig-check control caller-poison: ok"; else echo "rig-check control caller-poison: FAIL (rc $nrc, $nok of 7 ok)"; fails=$((fails + 1)); fi
+fi
+echo "rig-check control: $n cases, $fails failures"
```

(`...` stands for the unchanged text of the existing line.)

**One hermeticity mechanism, on purpose.** The `unset` at the top is the only thing that keeps a caller's value out. The override case sets `RIG_TEST_S` inside a subshell and only when it is given a 10th argument, so the value does not mask the caller's in any other case. If `run` instead always passed `RIG_TEST_S=${10:-}`, `run` would be hermetic by itself, the `unset` would be dead weight, and drill H would survive. The executor must keep this shape. `unset` of an unset name under `set -eu` is safe in bash 3.2 `sh` and in dash (V17).

**The `caller-poison` case: kimi's guard, adapted so it really runs.**
- **What it runs.** `$0` is the script's own path as the caller gave it: `tools/test_rig_check.sh` under make, which runs from the repo root (`mk/m45.mk:56`), or an absolute scratch path in the drills. `$RIG` is already absolute (line 8).
- **Isolation.** The nested run makes its own `mktemp` directory, so it cannot collide with the outer `$T`. Its log lands in the outer `$T/nested.log`, which the EXIT trap removes.
- **No recursion.** `RIG_CHECK_NESTED=1` skips the guard in the nested run, which therefore reports 7 cases.
- **Pass rule.** The case passes only if the nested rc is 0 and the nested log holds exactly 7 `: ok` lines.
- **Cost.** No measurable cost: baseline and 8-case control both 2 s (V3, V17).
- **What it catches.** Under a clean caller environment, deleting the `unset` now makes `make rig-check-control` exit 2 with `caller-poison: FAIL (rc 1, 6 of 7 ok)` (V18).

### 3. Mutation drills (hardened shape)

Save this block as `.godot/tmp/wd-drills.sh`; it is ignored, under `.godot/`. Each drill takes an explicit ROOT and mutates **scratch copies** only, never the tree. The trap is set right after `mktemp`. `cmp` proves the mutation applied, else exit 3. The control's rc is captured and asserted. Counts are checked with `test`. There is no `!`, and every check has its own `|| exit`. The drills call the script directly because the make target is the one-line wrapper `sh tools/test_rig_check.sh tools/rig_check.sh` (`mk/m45.mk:56`); AC3 and AC4 cover make's rc. I validated the block verbatim on a prototype of this design (V18). The exact-set assertion means a mutant must fail precisely the expected cases.

```sh
# drillwd ROOT MUTANT. Each mutant is applied to a scratch copy (the tree is never edited) and the
# control runs in a CLEAN environment (no RIG_TEST_S, RIG_GOLDEN_S or RIG_CHECK_NESTED):
#   H  test_rig_check.sh loses its unset line          -> FAIL: caller-poison           (AC3)
#   D  rig_check.sh's default goes back to 5400         -> FAIL: make-test-red, caller-poison (AC2)
#   O  rig_check.sh ignores RIG_TEST_S                  -> FAIL: watchdog-override, caller-poison (AC5)
drillwd() (
  set -u
  ROOT=${1:?explicit checkout ROOT required}
  mutant=${2:?H, D or O required}
  cd "$ROOT" || exit 2
  T=$(mktemp -d "${TMPDIR:-/tmp}/stapledon-wd.XXXXXX") || exit 2
  trap 'rm -rf "$T"' EXIT
  trap 'exit 130' INT; trap 'exit 143' TERM HUP
  cp tools/rig_check.sh tools/test_rig_check.sh "$T/" || exit 2
  ctl() { env -u RIG_TEST_S -u RIG_GOLDEN_S -u RIG_CHECK_NESTED sh "$T/test_rig_check.sh" "$T/rig_check.sh"; }
  rc=0; ctl > "$T/base.log" 2>&1 || rc=$?
  test "$rc" -eq 0 || exit 1
  test "$(grep -c ': ok$' "$T/base.log")" -eq 8 || exit 1
  case "$mutant" in
    H) f=test_rig_check.sh; want='caller-poison'; sed '/^unset RIG_TEST_S RIG_GOLDEN_S/d' "$T/$f" > "$T/m" || exit 2 ;;
    D) f=rig_check.sh; want='make-test-red caller-poison'; sed 's/RIG_TEST_S:-7200}/RIG_TEST_S:-5400}/' "$T/$f" > "$T/m" || exit 2 ;;
    O) f=rig_check.sh; want='watchdog-override caller-poison'; sed 's/^TEST_S=\${RIG_TEST_S:-7200}/TEST_S=7200/' "$T/$f" > "$T/m" || exit 2 ;;
    *) exit 2 ;;
  esac
  cmp -s "$T/$f" "$T/m" && exit 3
  cp "$T/m" "$T/$f" || exit 2
  rc=0; ctl > "$T/mut.log" 2>&1 || rc=$?
  test "$rc" -eq 1 || exit 1
  got=$(sed -n 's/^rig-check control \([a-z-]*\): FAIL.*/\1/p' "$T/mut.log" | tr '\n' ' ')
  test "$got" = "$want " || exit 1
  echo "drillwd $mutant: killed ($want)"
)
```

**Test-first order.**
- RED: on the pre-change tree, `drillwd ROOT H` exits 1 at its baseline (6 cases, not 8; AC7, V18).
- GREEN: apply sections 1 and 2, then run AC1–AC8 and AC10.

### 4. Stale prose

- **Executor updates:** the `tools/rig_check.sh:15` comment ("~50 min" becomes the measured 66–90 min, as in the diff) and `tools/test_rig_check.sh:47` (the expectation). These are the only live mentions of 5400 or ~50 min in tracked code (V10).
- **Executor leaves alone:** historical records that quote the old value (`m4-7s-7o-followups.md`, `m4-7ic-scene-session-golden.md` V10, the mission log and status archive). They are dated evidence.
- **Executor leaves alone:** dated records quoting `6 cases` (found in V20), same rule as the 5400 quotes. (Quorum round 2, oc-kimi-k3, applied verbatim under the narrow-refinement carve-out.)
- **Charter lines, for the controller only (the executor must not edit `design_docs/stapledon-mission.md`):**
  - **Line 421**, the iteration 52 backlog: its clause "`tools/test_rig_check.sh` inherits `RIG_TEST_S` ... (unset it in the test)" is closed by this item and can be struck or marked done when it lands.
  - **Line 413**, the queue order: the D-126 B half (L4 ahead of Kerr a4).
  - **Line 240**, D-126: stays as recorded.
  - **Repo Profile (lines 58–86):** it does not state the watchdog, so nothing to change there (V9).

## Acceptance criteria

Run from the implementation root after saving the drill block as `.godot/tmp/wd-drills.sh`.

| # | Criterion | Command | Expected |
|---|---|---|---|
| AC1 | The default is 7,200 s | `grep -c '^TEST_S=\${RIG_TEST_S:-7200}' tools/rig_check.sh; grep -c 5400 tools/rig_check.sh` | `1`, then `0` |
| AC2 | `make-test-red` expects the new default, and a reverted default is killed | `grep -c "ran over 7200s\\$'" tools/test_rig_check.sh; grep -c 5400 tools/test_rig_check.sh; sh -c '. .godot/tmp/wd-drills.sh; drillwd "$PWD" D'; echo rc=$?` | `1`, `0`, `drillwd D: killed (make-test-red caller-poison)`, `rc=0` |
| AC3 | Hermetic against a caller's `RIG_TEST_S` (and `RIG_GOLDEN_S`); deleting the `unset` reds a clean run | `RIG_TEST_S=1234 make rig-check-control > .godot/tmp/wd-h.log 2>&1; echo "rc=$? $(tail -1 .godot/tmp/wd-h.log)"; RIG_GOLDEN_S=999 make rig-check-control > .godot/tmp/wd-g.log 2>&1; echo "rc=$? $(tail -1 .godot/tmp/wd-g.log)"; sh -c '. .godot/tmp/wd-drills.sh; drillwd "$PWD" H'; echo rc=$?` | `rc=0 rig-check control: 8 cases, 0 failures` (twice), `drillwd H: killed (caller-poison)`, `rc=0` |
| AC4 | Green with the count asserted, under make, dash and shellcheck | `env -u RIG_TEST_S -u RIG_GOLDEN_S make rig-check-control > .godot/tmp/wd.log 2>&1; echo rc=$?; test "$(grep -c ': ok$' .godot/tmp/wd.log)" -eq 8 && echo count-ok; grep -c '^rig-check control caller-poison: ok$' .godot/tmp/wd.log; dash tools/test_rig_check.sh tools/rig_check.sh \| tail -1; shellcheck -s sh -S warning tools/rig_check.sh tools/test_rig_check.sh; echo sc=$?` | `rc=0`, `count-ok`, `1`, `rig-check control: 8 cases, 0 failures`, `sc=0` |
| AC5 | An explicit `RIG_TEST_S` still takes effect, and ignoring it is killed | `grep -c '^rig-check control watchdog-override: ok$' .godot/tmp/wd.log; sh -c '. .godot/tmp/wd-drills.sh; drillwd "$PWD" O'; echo rc=$?` | `1`, `drillwd O: killed (watchdog-override caller-poison)`, `rc=0` |
| AC6 | The CI tiers are unaffected. ci.yml's `run:` steps are `make deps`, `make lore-import CHECK=1`, `make ci-fast` and (release, `inputs.full`) `make test`, and `ci-fast` does not reach the control. Release's full `make test` runs it under Linux `sh` (dash), which AC4 covers. | `make -qp 2>/dev/null \| grep '^ci-fast:' \| tr ' ' '\n' \| grep -cx rig-check-control; make -qp 2>/dev/null \| grep '^test:' \| tr ' ' '\n' \| grep -cx rig-check-control` | `0`, then `1` |
| AC7 | RED first: the pre-change control fails the drill baseline | `R0=$(mktemp -d) && mkdir "$R0/tools" && git show origin/main:tools/rig_check.sh > "$R0/tools/rig_check.sh" && git show origin/main:tools/test_rig_check.sh > "$R0/tools/test_rig_check.sh" && sh -c ". .godot/tmp/wd-drills.sh; drillwd $R0 H"; echo rc=$?; rm -rf "$R0"` | `rc=1` |
| AC8 | Scope: two scripts, no charter | `git diff --name-only origin/main...HEAD \| grep -cvE '^(tools/(test_)?rig_check\.sh\|design_docs/planned/r1/rig-watchdog-7200(-sprint)?\.md\|\.ailang/state/(sprints\|evaluations)/.*\.json)$'; git diff --name-only origin/main...HEAD \| grep -c stapledon-mission` | `0`, then `0` |
| AC9 | Landing (controller) | `tools/rig_check.sh <PR>` | `rig/full` success on the PR head. The run uses the new 7,200 s default, with no override exported. |
| AC10 | The hermetic line is exactly as designed | `grep -c '^unset RIG_TEST_S RIG_GOLDEN_S' tools/test_rig_check.sh` | `1` |

## Sub-milestones and estimate

One milestone of 17 lines, under an hour. Order: save the drills, show RED (AC7), edit both scripts, then run AC1–AC8 and AC10. The controller runs AC9.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| A genuinely hung `make test` now holds the rig for 30 more minutes before it reports. | The rig runs one suite at a time anyway, and `RIG_TEST_S` can still lower the limit (AC5). |
| Load pushes a run past 120 min. The worst on record is 99 min (V13). | That would need a new ruling; L4 (test-suite speed) removes the cause. The escape hatch now works without reddening the run (AC3). |
| The override case's subshell masks a caller's value, which would make the `unset` untestable. | The export is conditional on the 10th argument and scoped to the subshell. Drill H proves the `unset` is load-bearing (V18). |
| A caller that exports `RIG_CHECK_NESTED` skips `caller-poison` (the control then reports 7 cases, V18). | AC4 asserts 8 `: ok` lines. The name is unused anywhere else: at HEAD, `git grep -l RIG_CHECK_NESTED` outside this doc lists 0 files, while the positive control `git grep -l RIG_NO_STATUS` lists 5 (V19). |
| `unset` or the `$0` re-exec misbehaves on some `sh`. | Measured on bash 3.2 `sh` and on dash, by direct run, through make, and with absolute and relative `$0` (V17, V18). |

## Open questions

None. Mark's ruling fixes the value (7,200 s), and the backlog note fixes the remedy ("unset it in the test").

## Deliverables

- `tools/rig_check.sh`: the default and its comment.
- `tools/test_rig_check.sh`: the hermetic `unset`, the 7,200 s expectation, the `watchdog-override` and `caller-poison` cases, and 8 cases.
- Drill and AC evidence in the sprint JSON. The executor does not commit the drill file (it lives in `.godot/tmp/`).

## Verification log

All rows were run by the designer in `/Users/voightkampff/dev/sunholo-data/.stap-iter55-src` at `7e0e6860`. Prototypes ran on scratch copies under `mktemp -d`, and afterwards `git status --porcelain` listed only this doc.

| # | Claim | Command | Observed |
|---|---|---|---|
| V1 | The default is 5,400 s, with the "~50 min" comment | `grep -n 'RIG_TEST_S:-' tools/rig_check.sh` | `15:TEST_S=${RIG_TEST_S:-5400}   # make test is ~50 min on the Studio` |
| V2 | `make-test-red` hardcodes 5400s | `grep -n 5400 tools/test_rig_check.sh` | `47:run make-test-red 1 failure '01234567: make test failed or ran over 5400s$' …` |
| V3 | The baseline control is green and fast | `sh tools/test_rig_check.sh tools/rig_check.sh` | 6 `: ok` lines, `rig-check control: 6 cases, 0 failures`, rc 0, 2 s |
| V4 | **The coupling reproduces** | `RIG_TEST_S=1234 sh tools/test_rig_check.sh …`; `env -u RIG_TEST_S make -s rig-check-control`; `RIG_TEST_S=6600 make -s rig-check-control` | rc 1, `make-test-red: FAIL (; no failure description /…5400s$/)`, `6 cases, 1 failures`; then make rc 0 (control); then make rc 2 with the same single FAIL |
| V5 | The override is honoured at HEAD | A copy of the control that prints the `failure` post after `make-test-red`, run with `RIG_TEST_S=1234` | `POST: failure 44 01234567: make test failed or ran over 1234s` |
| V6 | `ci-fast` does not reach the control; `test` does | `make -qp` prerequisites, with `strict` as a positive control | ci-fast `rig-check-control` 0, test 1, ci-fast `strict` 1 |
| V7 | The only make wiring | `git grep -n 'rig_check\|test_rig_check' -- Makefile 'mk/*.mk' .github/` | Invocation only at `mk/m45.mk:56`; the other hits are comments (`Makefile:44`, `mk/m45.mk:51,55`, `ci.yml:16`) |
| V8 | ci.yml `run:` steps | `sed -n 1,70p .github/workflows/ci.yml` | Install AILANG and Godot, `make deps` + `make lore-import CHECK=1 …`, `make ci-fast` (`!inputs.full`), `make test` (`inputs.full`) |
| V9 | The Repo Profile does not state the watchdog | `sed -n 58,86p` of the charter, then `grep -ci 'watchdog\|5400\|5,400\|rig_check'` and `grep -c 'make test'` | 0, with the positive control 1 |
| V10 | The only live stale mentions | `git grep -n -I -e 5400s -e 5,400 -e '5400 s' -e '~50 min' -e 'RIG_TEST_S:-'` (excluding fixtures and data) | Live: `tools/rig_check.sh:15` and `tools/test_rig_check.sh:47`. The rest are dated records (planned docs, the mission log, the status archive, sprint JSON, charter rows 98/239/240/370/413/421/447) |
| V11 | (Round 1 prototype, 7 cases; superseded by V17.) | — | — |
| V12 | (Round 1 drills, single-FAIL form; superseded by V18.) | — | — |
| V13 | Recorded `rig/full` durations | `grep` of the charter (D-126 row 240, row 7o at 447) and `stapledon-mission-log.md` lines 663 and 1044 | 66–77 min earlier; 90 min on #341; iteration 45 two 0-failure timeouts at 5,400 s; 65 min (7o, idle); 66 min (iteration 52 run 2); **99 min** with `RIG_TEST_S=9000` (line 663) |
| V14 | Iteration 52 hit the coupling | `sed -n 1044p design_docs/stapledon-mission-log.md` | "I exported `RIG_TEST_S=6600` … the nested control test inherits it … `RIG_TEST_S=6600 sh tools/test_rig_check.sh` rc 1, `env -u RIG_TEST_S` rc 0" |
| V15 | The shells | `sh --version \| head -1; command -v dash shellcheck` | `GNU bash, version 3.2.57(1)-release`; `/bin/dash`; `/opt/homebrew/bin/shellcheck` |
| V16 | The caller-reachable `RIG_*` surface, and `RIG_GOLDEN_S` reaches no case | `grep -n -o 'RIG_[A-Z_]*' tools/rig_check.sh`; `grep -n -o 'RIG_DIR=[^ ]*\|RIG_NO_STATUS=[^ ]*' tools/test_rig_check.sh`; `grep -n GOLDEN tools/rig_check.sh`; `grep -c -i golden tools/test_rig_check.sh` (positive control `grep -c RIG_DIR` gives 3); `RIG_GOLDEN_S=1 sh tools/test_rig_check.sh tools/rig_check.sh`; `RIG_GOLDEN_S=1 make -s rig-check-control` | `9:RIG_DIR 12:RIG_NO_STATUS 15:RIG_TEST_S 16:RIG_GOLDEN_S 30:RIG_DIR 34:RIG_NO_STATUS` (9 and 12 are comments); the control pins `RIG_DIR=$8`/`"$T/$1"` and `RIG_NO_STATUS=0` at lines 38 and 55; `16:GOLDEN_S=${RIG_GOLDEN_S:-1800}`, `74:` the golden alarm; golden in the control 0; script rc 0 `6 cases, 0 failures`; make rc 0 `6 cases, 0 failures` |
| V17 | Prototype of sections 1 and 2 (round 2, with `caller-poison`) | `env -u RIG_TEST_S sh` and `dash tools/test_rig_check.sh tools/rig_check.sh`; `RIG_TEST_S=1234 sh …`; `RIG_GOLDEN_S=999 sh …`; through a Makefile holding the `mk/m45.mk` recipe verbatim: `RIG_GOLDEN_S=999 make`, `RIG_TEST_S=1234 make`, `env -u RIG_TEST_S make`; `shellcheck -s sh -S warning`; `diff` against HEAD | 8 `: ok`, `8 cases, 0 failures`, rc 0 under sh and dash; 1234 and 999 both rc 0 `8 cases, 0 failures` (script and make); clean make rc 0, ok 8, 2 s; shellcheck rc 0; `test_rig_check.sh` diff is 16 `>` and 5 `<` lines (5 changed, 11 added), plus 1 line in `rig_check.sh` |
| V18 | The drills kill, RED holds, unapplied mutants exit 3, and a clean run reds without the `unset` | The section 3 block in its AC form under `sh` and `dash`; the `unset` deleted, then `env -u RIG_TEST_S make -s rig-check-control`; `drillwd` H on `origin/main` copies (AC7); `drillwd` O on a copy with the line quoted, and H on a copy with a doubled space after `unset` (each `sed` misses); `RIG_CHECK_NESTED=1 sh tools/test_rig_check.sh …` | `drillwd H: killed (caller-poison)`, `D: killed (make-test-red caller-poison)`, `O: killed (watchdog-override caller-poison)`, `killed`, rc 0 in both shells; clean make with H applied rc 2, `caller-poison: FAIL (rc 1, 6 of 7 ok)`; RED rc 1; no-op O rc 3, no-op H rc 3; nested skip `7 cases, 0 failures` |
| V19 | `RIG_CHECK_NESTED` is unused elsewhere | `git grep -c RIG_CHECK_NESTED -- ':!design_docs/planned/r1/rig-watchdog-7200.md' \| wc -l`; positive control `git grep -l RIG_NO_STATUS \| wc -l` | `0`; `5` |
| V20 | No live consumer of the control's output contract (quorum round 2, oc-kimi-k3) | `git grep -n -I -E 'rig-check control|cases, [0-9]+ failures|6 cases' -- . ':!design_docs/stapledon-mission*.md' ':!design_docs/planned/r1/rig-watchdog-7200.md'`; positive control `git grep -c 'rig-check control' -- tools/test_rig_check.sh` | Every hit is a dated record (`.ailang/state/evaluations/*.json`, `.ailang/state/sprints/sprint_R1-M4-JOURNEY.json:777-785`, `design_docs/planned/r1/m4-7s-7o-followups*.md`, unrelated `N cases` lines in other harnesses) or the control itself (`tools/test_rig_check.sh:44,57,58,63`; positive control 4). The only live consumer is `mk/m45.mk:56`, which consumes only the exit code: `@sh tools/test_rig_check.sh tools/rig_check.sh`. `tools/rig_check.sh` parses no `cases`/`: ok` text (its only match is its own `rig-check: ok` line 77). Controller-measured 2026-10-28. |
| V21 | The drill/log path is git-ignored (quorum round 2, oc-kimi-k3) | `git check-ignore -v .godot/tmp/wd-drills.sh` | `.gitignore:1:.godot/	.godot/tmp/wd-drills.sh`, rc 0. Controller-measured 2026-10-28. |

## Quorum log

- Round 1 (2026-10-28T11:48:58Z): BLOCKED. gemini-4-argon pass; oc-glm-5-3 reject (RIG_GOLDEN_S half unverified); oc-kimi-k3 reject (hermeticity guarded only at design time); gpt6-1-sol absent (unreachable). The controller measured both premises (RIG_GOLDEN_S=1 gave rc 0 with 0 golden cases; mk/ is not held by #344). Designer revision: GOLDEN_S scoped to prophylaxis, AC10, and the committed `caller-poison` case.
- Round 2 (2026-10-28T12:02:06Z): BLOCKED, at N-2. gemini-4-argon pass; oc-kimi-k3 reject (no audit of consumers of the output shape, and the ignore status of `.godot/tmp` unproven); oc-glm-5-3 and gpt6-1-sol absent (unreachable). The objection is on a new surface (the conflict audit), carries a concrete proposed_fix, and does not dispute the direction. The controller measured it: no live consumer, and `.godot/tmp` is ignored. Kimi's fix was applied verbatim (V20, V21, the cost line, the §4 line) under the narrow-refinement carve-out, with no third round.
