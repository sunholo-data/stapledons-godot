# Sprint addendum: R1-M4-JOURNEY rows 7o and 7s

**Status:** Planned; mission iteration 44, 2026-10-21. Planning only; no implementation performed.
**Milestone:** `M4.5bR3_7s7o_FOLLOWUPS`, one milestone and one PR under approved `R1-M4-JOURNEY` (D-66/D-88 A).
**Approved design:** [m4-7s-7o-followups.md](m4-7s-7o-followups.md), final commit `74e68540ef891e261c598f716564503b5b67ca92`, including the quorum narrow-refinement outcome, conditional log pointer, refused-success case and hardened drills.
**Precedent:** [7q design](m4-7q-ruling-pin-controls.md), [7q sprint](m4-7q-ruling-pin-controls-sprint.md), and landed feature `M4.5bR3_7q_RULING_PIN_CONTROLS` (PR #288). Depends only on that feature; D-77/D-78 acceptance is unchanged.
**Estimate:** about 105 test/tooling/data LOC; 2.5 h executor time (design's 2 h plus 25% contingency), 0.5 h independent evaluation/evidence review, then 70–100 min Studio full-suite latency: about 4 h 10 min–4 h 40 min without queueing; reserve 5 h within one working day. Low implementation risk, medium verification risk.

## Method, scope and current state

Applied the [sprint-planner skill](/Users/voightkampff/.claude/skills/sprint-planner/SKILL.md): inspect the approved design and landed work, establish premises, order RED before GREEN, budget evidence and gates, and populate real acceptance criteria. This mission's explicit one-milestone/two-deliverable/no-git-write instructions override the generic skill's minimum-two-milestones, generator, metadata rewrites and automatic handoff. CLAUDE.md's full Studio `make test` remains a controller gate. No messages, commits, snapshots or implementation handoff are sent by the planner.

One milestone is appropriate: both small hygiene changes share `mk/m45.mk`, the existing sprint JSON and one final rig run, and Mark ordered batching. Keep the internal order 7o first, then 7s, record correction, final gates, as the design specifies. Splitting would repeat controller/evaluator overhead without creating a useful independent delivery boundary.

HEAD is the approved design commit on `mission/stapledon-iter44-followups`. Initially `git diff --quiet HEAD` returned 0; 41 pre-existing untracked Godot UID files are outside this task. The baseline loop has 28 spec triples by static count; this planner has not run Godot or claimed a fresh display-audit baseline. The design's V8/V23 are supplied designer measurements. The 7q implementation (`080b4f7d`, 2026-10-20) changed 40 insertions and 4 deletions against its ~30 LOC design, supporting a contingency rather than extrapolating the parent sprint's unrelated 2300 LOC/day velocity. `git log 4bf95435..origin/main -- tools/rig_check.sh mk/m45.mk tests/display_audit.gd tests/fixtures/display_audit/` produced no output against the local remote-tracking ref; the controller must refresh/recheck before execution.

Registry reuse decision for this milestone: **none**. It adds shell controls and JSON fixtures, no package-like capability; registry search and the `.ail` syntax gate do not apply. Working examples are the six network-free rig cases and the three five-entry audit fixtures, verified by AC1/AC5; no gameplay demo is introduced.

## Re-verified planning premises

Read-only commands run at HEAD `74e68540` on 2026-10-21. These are planning evidence, not implementation acceptance results.

| Row | Premise / command | Observed output | Verdict |
|---|---|---|---|
| P1 | `git grep -n '^short=' tools/rig_check.sh`; `git grep -n '^status()\|^fail()\|description=' tools/rig_check.sh` | `short` at line 29; `status()` at 33, uncapped `description="$2"` at 35; one-line post-before-echo `fail()` at 42. Exact lines below. | CONFIRMED: short exists before fail; current status/failure code matches the design. |
| P2 | `make -qp 2>/dev/null \| sed -n '/^display-audit-controls:/,+5p'`; `make -qp 2>/dev/null \| grep '^test:' \| tr ' ' '\n' \| grep -cx rig-check-control` | `display-audit-controls: import`, recipe from `mk/m45.mk`, line 16; second command prints `0`, exit 1. Raw `make -qp` query exits 1 with empty stderr. | CONFIRMED: existing control home and no rig prerequisite yet; query/non-match status is not a build failure. |
| P3 | `sed -n '/^## Files$/,/^## Deferred/p' design_docs/planned/r1/m4-7s-7o-followups.md` | Eight Files rows: the rig script, NEW control, m45 include, three NEW fixtures, sprint JSON and approved design artifact. Explicit Not touched list includes root Makefile, audit script and production paths. | CONFIRMED: no planned permanent Makefile, audit-script or production edit. The approved design artifact remains read-only. |
| P4 | Inspect target definitions from `make -qp` against all ACs: `make -qp 2>/dev/null \| awk '/^(rig-check-control\|display-audit-controls\|test\|python-guard):/ {print $1}'` | `python-guard:`, `test:`, `display-audit-controls:`; no `rig-check-control:`. | CONFIRMED: `rig-check-control` is NEW (AC1); display-audit-controls (AC5), test (AC3/AC11) and python-guard (AC10) EXIST. AC4/AC6 call those targets inside copied drills. Other ACs use shell/git/tool commands, not new make targets. |
| P5 | `command -v shellcheck dash` | `/opt/homebrew/bin/shellcheck` then `/bin/dash`, exit 0. | CONFIRMED: both expected Studio tools are present. |

P1 exact source lines (pipes here are literal shell text):

```sh
tools/rig_check.sh:29:short=$(printf %s "$sha" | cut -c1-8)
tools/rig_check.sh:33:status() {
tools/rig_check.sh:35:  gh api "repos/$REPO/statuses/$sha" -f state="$1" -f context=rig/full -f description="$2" > /dev/null
tools/rig_check.sh:42:fail() { status failure "$1 (log on the Studio: $log)"; echo "rig-check: FAIL: $1"; exit 1; }
```

The make database was also inspected in memory with a read-only Python harness (no make recipes executed), confirming the complete `test:` prerequisite list has no `rig-check-control`. No remote PR/CI freshness is inferred from local refs.

## Ordered tasks: RED first, then GREEN

1. **Preflight and preserve evidence (15 min).** Controller refreshes origin and checks the design's scoped `git log` command; any overlap goes back to the controller for rebase/recount. Executor records initial tracked/untracked state and byte copies/hashes of the three drill-mutated files under `.godot/tmp/`; exports the pinned runtime environment below. Save the exact Test-plan block below as `.godot/tmp/iter44-drills.sh`. Run drills sequentially under `sh`; never use whole-package `ailang test --package .`. Baseline `make display-audit-controls AILANG="$AILANG"` must actually return 0 with exactly 28 rejection rows and no per-row script errors before RED is meaningful. Any sandbox denial makes the affected gate **UNINFORMATIVE UNDER SANDBOX**, requiring an outside-sandbox rerun.
2. **7o RED: control before fix (20 min).** Create `tools/test_rig_check.sh` verbatim from design §2, with all six cases: make-test-red, long-reason, long-success, clone-red-pointer, failure-refused, success-refused. Run it against the pre-fix script via AC2: control rc 1 and exactly `rig-check control: 6 cases, 6 failures`; also retain six individual FAIL lines and the 160/340/257 refused lengths. Add the design's NEW target and `test: rig-check-control` in `mk/m45.mk`; before the fix, `make rig-check-control` must be red for the control's assertions (normally make rc 2), not a missing-target failure.
3. **7o GREEN (25 min).** Apply only design §1's rig diff: cap every post in `status()` at 140; echo failure reason/log before posting; put existing eight-character short SHA first; append pointer iff `${#d} + ${#log} + 8 <= 140`; report refused failure posts; print success before posting, reporting refused success and exiting 1. Retain timeouts, clone/runtime/pending flow and all other wording. AC1 must now report six cases/zero failures and AC3 print 1. Run R1–R5 sequentially and require each exact named failure. Retain evidence and independently `cmp` the restored script against the pre-drill GREEN copy; literal AC4's final HEAD check is controller-owned (DI-03). Run AC9, recording dash's own rc separately from `tail` (DI-04).
4. **7s RED before its edits (20 min).** Still at the original 28-row audit tree, run the copied `drill7s "$PWD" E1 28` and `drill7s "$PWD" E5 28` before adding fixtures/count/guard. Both design invocations exit 1; record baseline rc/count, mutation application, mutated make rc/count, per-row errors and actual last failing assertion. DI-01 limits what the E5 exit proves: its final fixture is absent at RED, so this exit is not proof of a killed mutant or of non-vacuity. E1 requires evidence of genuine survival (mutated make rc 0/28), not an infrastructure failure. Record E5's equivalence, never a new kill. Do not edit the copied function silently.
5. **7s fixtures and GREEN loop (30 min).** Create the three compact five-entry fixtures named below from `known_findings.json`, retaining all other field values exactly and D-77's correct `accepted_by`. Transit-kind changes kind only to `unbound`; caption-kind changes kind to `transit-ISM` AND adds the two required D-77 card fields after `observed_samples`; nonstring changes transit `accepted_by` only to JSON number 77. `jq -e .` each file, inspect parsed diffs against the source and raw field values. Append the three spec triples after `known_wrong_caption_node.json` in design order. Add n=0, increment each iteration, final `test $$n -eq 31` diagnostic, and replace only the loop's dead standalone `! grep` with the explicit if/exit guard. Keep the four non-loop controls unchanged. Run AC5 (31 then 3) and AC7 (printed 0, exit 1 is expected); then run all AC6 drills at default 31, requiring exact signatures and S1's deliberate script errors only. Restore each file byte-for-byte against its GREEN backup. E5 stays equivalent at 31; C1–C4 must fail the positive control before any rejection rows. See DI-02 for E7's row label.
6. **Record, review and controller gates (20 min executor + downstream latency).** Rerun restored AC1/AC5 and complete focused AC1–AC10 with the ownership qualifications below. Update only this new feature's notes with dated commands/rc/counts/signatures, E5 and echo-order equivalence, 7i(l) evidence, coverage correction and all three deferrals. Do not mark aggregate completion or alter 7q. Independent evaluator checks evidence and scope. Controller commits, reruns literal AC4/AC6 at the implementation HEAD, completes AC8, and runs AC11/full merge gates outside the sandbox. Planner/executor perform no git writes.

The task allowances total 130 min, with another 20 min contingency to reach the 150 min executor budget, including roughly eight minutes of GREEN drill execution; archive any needed baseline/mutant/per-row logs before the copied traps remove their scratch directories. Keep the copied drill code intact; evidence retention may use an external traced runner capturing output and copies before cleanup. A mutation that did not apply, a wrong baseline/count, parse error or unrelated failure is never a kill.

## Acceptance criteria — exact approved commands and outputs

The following section is copied verbatim from the approved design. Markdown `\|` escapes in table cells represent literal pipeline/regex pipes when running commands. These are requirements for the executor/controller, not a claim that this planner passed the implementation gates. Create `.godot/tmp/` before redirecting, and export `PATH="$PWD/runtime/bin:$PATH"` and `AILANG="$PWD/runtime/bin/ailang"`. DI-03/DI-04 explain commit-state and shell-status limits without changing any acceptance command.


Run these from the implementation root with `PATH="$PWD/runtime/bin:$PATH"` and `AILANG="$PWD/runtime/bin/ailang"`. First save the Test-plan block as `.godot/tmp/iter44-drills.sh`.

| # | Command | Expected output |
|---|---|---|
| AC1 | `make rig-check-control > .godot/tmp/7o.log 2>&1; echo "rc=$? $(tail -1 .godot/tmp/7o.log)"` | `rc=0 rig-check control: 6 cases, 0 failures` |
| AC2 | `git show 4bf95435:tools/rig_check.sh > .godot/tmp/rig_check.4bf95435.sh; sh tools/test_rig_check.sh .godot/tmp/rig_check.4bf95435.sh \| tail -1` | `rig-check control: 6 cases, 6 failures` (RED on the pre-fix script, V4) |
| AC3 | `make -qp AILANG="$AILANG" 2>/dev/null \| grep '^test:' \| tr ' ' '\n' \| grep -cx rig-check-control` | `1` (inside `make test`) |
| AC4 | `sh -c '. .godot/tmp/iter44-drills.sh; for d in R1 R2 R3 R4 R5; do drill7o "$PWD" $d \|\| exit 1; done' && git diff --quiet -- tools/rig_check.sh && echo killed` | `killed` |
| AC5 | `make display-audit-controls AILANG="$AILANG" > .godot/tmp/7s-controls.log 2>&1 && grep -c ': rejected$' .godot/tmp/7s-controls.log && (cd .godot/tmp/display-audit/playthrough && grep -lx 'FAIL known-ruling invalid acceptance' display-known-known_wrong_transit_kind.json.log display-known-known_wrong_caption_kind.json.log display-known-known_nonstring_ruling.json.log \| wc -l \| tr -d ' ')` | `31`, then `3` |
| AC6 | `sh -c '. .godot/tmp/iter44-drills.sh; for d in E1 E2 E5 E5b E7 E7b S1 C1 C2 C3 C4; do drill7s "$PWD" $d \|\| exit 1; done' && git diff --quiet -- tests/display_audit.gd mk/m45.mk && echo killed` | `killed`. Each kill signature is as in the Test plan; E5 is asserted equivalent. About 7 minutes. |
| AC7 | `grep -c "^[[:space:]]*! grep -q 'SCRIPT ERROR:'" mk/m45.mk` | `0` (the dead guard is gone; S1 in AC6 proves its replacement live) |
| AC8 | `git diff --name-only origin/main...HEAD \| grep -cvE '^(tools/rig_check\.sh\|tools/test_rig_check\.sh\|mk/m45\.mk\|tests/fixtures/display_audit/known_(wrong_transit_kind\|wrong_caption_kind\|nonstring_ruling)\.json\|design_docs/planned/r1/m4-7s-7o-followups(-sprint)?\.md\|\.ailang/state/sprints/sprint_R1-M4-JOURNEY\.json)$'` | `0` (no `Makefile`, no `tests/display_audit.gd`, no production path) |
| AC9 | `shellcheck -s sh -S warning tools/rig_check.sh tools/test_rig_check.sh && dash tools/test_rig_check.sh tools/rig_check.sh \| tail -1` | `rig-check control: 6 cases, 0 failures` (warning-clean; portable to dash, which is Linux's `sh`) |
| AC10 | `make python-guard AILANG="$AILANG" > /dev/null 2>&1; echo rc=$?` | `rc=0` |
| AC11 | `tools/rig_check.sh <PR>` (controller) | `rig/full` success on the PR head. The fixed script posts its own pending and success statuses. |


## Mutation drills — verbatim approved Test plan

The entire Test-plan body below, including the shell block and expected-outcome table, is copied verbatim. Its RED E5 and E7-label inconsistencies are recorded in DI-01/DI-02. Only future execution may transiently mutate `tests/display_audit.gd`; this planner does not. Snapshot GREEN bytes externally and compare after every trap, including when AC4/AC6's HEAD checks cannot yet succeed.


**Order.** Test-first:

1. RED: `drill7s "$PWD" E1 28` and `drill7s "$PWD" E5 28` on the pre-change tree each exit 1 (V16, V23). AC2 is 7o's RED: `6 cases, 6 failures`.
2. GREEN: land the fixtures, loop edits, script fix and control. Then run AC1–AC9.

**Drill shape.** Both functions use the hardened shape:

- an explicit `ROOT`;
- a cleanup trap right after `mktemp`;
- a `cmp` proof that the mutation applied (else exit 3);
- make's rc passed through;
- counts asserted with `test`, never printed.

They also correct three things in the shape 7q used:

- **Every assertion carries its own `|| exit`.** A caller's `||`, `&&` or `if` (the ACs use `drill … || exit 1`) switches `set -e` off for the whole function body, subshell included (V22). Only `set -u` is kept.
- **No `!` assertion.**
- **Script errors are counted in the per-row logs** under `$T/scratch`, not in make's stdout, where Godot's output never appears.

The patterns go through the environment, because inline Perl interpolates `$(` and `@`. Run the drills sequentially (they share the import cache) under `sh`. They were validated as written, through the AC form, in a rehearsal of the GREEN tree (V23).

```sh
# Every assertion carries its own `|| exit`: a caller's `||`, `&&` or `if` switches `set -e` off
# inside the whole function body (measured, V22), so the drills never rely on it.

# Row 7o drills: R1 (no cut), R2 (the old fail()), R3 (a refused failure post aborts),
# R4 (a refused success post aborts), R5 (no conditional log pointer).
drill7o() (
  set -u
  ROOT=${1:?explicit checkout ROOT required}
  mutant=${2:?R1, R2, R3, R4 or R5 required}
  cd "$ROOT" || exit 2
  ROOT=$(pwd -P)
  T=$(mktemp -d "${TMPDIR:-/tmp}/stapledon-7o.XXXXXX") || exit 2
  trap 'if test -f "$T/orig"; then cp "$T/orig" "$ROOT/tools/rig_check.sh"; fi; rm -rf "$T"' EXIT
  trap 'exit 130' INT; trap 'exit 143' TERM HUP
  sh tools/test_rig_check.sh tools/rig_check.sh > "$T/baseline.log" 2>&1 || exit 1
  test "$(grep -c ': ok$' "$T/baseline.log")" -eq 6 || exit 1
  cp tools/rig_check.sh "$T/orig" || exit 2
  case "$mutant" in   # patterns via env: inline Perl interpolates $( and @ (iteration-41 lesson)
    R1) PAT='"$(printf %s "$2" | cut -c1-140)"' REP='"$2"' ;;
    R2) PAT='fail() {
  echo "rig-check: FAIL: $1 (log: $log)"
  d="$short: $1"   # the log pointer goes in too whenever it fits GitHub'"'"'s 140 characters (row 7o)
  if [ $((${#d} + ${#log} + 8)) -le 140 ]; then d="$d (log: $log)"; fi
  status failure "$d" || echo "rig-check: could not post the failure status"
  exit 1
}'
        REP='fail() { status failure "$1 (log on the Studio: $log)"; echo "rig-check: FAIL: $1"; exit 1; }' ;;
    R3) PAT=' || echo "rig-check: could not post the failure status"' REP='' ;;
    R4) PAT=' || { echo "rig-check: could not post the success status"; exit 1; }' REP='' ;;
    R5) PAT='  if [ $((${#d} + ${#log} + 8)) -le 140 ]; then d="$d (log: $log)"; fi
' REP='' ;;
    *) exit 2 ;;
  esac
  PAT=$PAT REP=$REP perl -0pi -e 's{\Q$ENV{PAT}\E}{$ENV{REP}}' tools/rig_check.sh || exit 2
  cmp -s "$T/orig" tools/rig_check.sh && exit 3
  rc=0; sh tools/test_rig_check.sh tools/rig_check.sh > "$T/mutant.log" 2>&1 || rc=$?
  test "$rc" -ne 0 || exit 1
  case "$mutant" in
    R1) grep -q '^rig-check control long-reason: FAIL' "$T/mutant.log" || exit 1
        grep -q '^rig-check control long-success: FAIL' "$T/mutant.log" || exit 1 ;;
    R2) grep -q '^rig-check control make-test-red: FAIL' "$T/mutant.log" || exit 1
        grep -q '^rig-check control clone-red-pointer: FAIL' "$T/mutant.log" || exit 1 ;;
    R3) grep -q '^rig-check control failure-refused: FAIL' "$T/mutant.log" || exit 1 ;;
    R4) grep -q '^rig-check control success-refused: FAIL' "$T/mutant.log" || exit 1 ;;
    R5) grep -q '^rig-check control clone-red-pointer: FAIL' "$T/mutant.log" || exit 1 ;;
  esac
  exit 0
)

# Row 7s drills: E1/E2 (kind pins), E5 (type guard deleted: equivalent), E5b (type guard flipped),
# E7/E7b (a spec row deleted, new and old), S1 (a script error on the known-ruling path),
# C1-C4 (one D-78 caption dropped from the accepted list: the positive control already kills it).
drill7s() (
  set -u
  ROOT=${1:?explicit checkout ROOT required}
  mutant=${2:?E1, E2, E5, E5b, E7, E7b, S1 or C1-C4 required}
  expected=${3:-31}
  cd "$ROOT" || exit 2
  ROOT=$(pwd -P)
  case "$mutant" in E7|E7b) F=mk/m45.mk ;; *) F=tests/display_audit.gd ;; esac
  T=$(mktemp -d "${TMPDIR:-/tmp}/stapledon-7s.XXXXXX") || exit 2
  trap 'if test -f "$T/orig"; then cp "$T/orig" "$ROOT/$F"; fi; rm -rf "$T"' EXIT
  trap 'exit 130' INT; trap 'exit 143' TERM HUP
  PATH="$ROOT/runtime/bin:$PATH" make display-audit-controls \
    SCRATCH="$T/scratch" AILANG="$ROOT/runtime/bin/ailang" > "$T/baseline.log" 2>&1 || exit 1
  test "$(grep -c ': rejected$' "$T/baseline.log")" -eq "$expected" || exit 1
  cp "$F" "$T/orig" || exit 2
  case "$mutant" in
    E1) PAT='entry.kind == "transit-ISM" and ' REP='' ;;
    E2) PAT='entry.kind == "unbound" and ' REP='' ;;
    E5) PAT='	if not entry.accepted_by is String: return false
' REP='' ;;
    E5b) PAT='if not entry.accepted_by is String: return false' REP='if not entry.accepted_by is String: return true' ;;
    E7) PAT="'known known_wrong_accompanying.json known-ruling' " REP='' ;;
    E7b) PAT="'review_unbound empty_known.json NEW.unbound' " REP='' ;;
    C1) PAT='"Cruise N - beta", ' REP='' ;;
    C2) PAT=', "N - beta", ' REP=', ' ;;
    C3) PAT='"  its N - beta", ' REP='' ;;
    C4) PAT=', "Grains swept (>= N um)"]' REP=']' ;;
    S1) PAT='check(false, "known-ruling invalid acceptance"); continue'
        REP='check(false, "known-ruling invalid acceptance"); var probe: Array = []; print(probe[0]); continue' ;;
    *) exit 2 ;;
  esac
  PAT=$PAT REP=$REP perl -0pi -e 's{\Q$ENV{PAT}\E}{$ENV{REP}}' "$F" || exit 2
  cmp -s "$T/orig" "$F" && exit 3
  rc=0; PATH="$ROOT/runtime/bin:$PATH" make display-audit-controls \
    SCRATCH="$T/scratch" AILANG="$ROOT/runtime/bin/ailang" > "$T/mutant.log" 2>&1 || rc=$?
  errs=$(grep -l 'SCRIPT ERROR:' "$T"/scratch/display-audit/*/*.log 2>/dev/null | wc -l | tr -d ' ')
  if [ "$mutant" = E5 ]; then   # equivalent: same rows, the non-String fixture still rejected for the ruling
    test "$rc" -eq 0 || exit 1
    test "$errs" -eq 0 || exit 1
    test "$(grep -c ': rejected$' "$T/mutant.log")" -eq "$expected" || exit 1
    grep -qx 'FAIL known-ruling invalid acceptance' "$T"/scratch/display-audit/*/display-known-known_nonstring_ruling.json.log || exit 1
    exit 0
  fi
  test "$rc" -ne 0 || exit 1
  if [ "$mutant" = S1 ]; then test "$errs" -gt 0 || exit 1; else test "$errs" -eq 0 || exit 1; fi
  case "$mutant" in
    E1) grep -qx 'display control known/known_wrong_transit_kind.json wrong reason (want known-ruling)' "$T/mutant.log" || exit 1 ;;
    E2) grep -qx 'display control known/known_wrong_caption_kind.json wrong reason (want known-ruling)' "$T/mutant.log" || exit 1 ;;
    E5b) grep -qx 'display control known/known_nonstring_ruling.json missed' "$T/mutant.log" || exit 1 ;;
    E7|E7b) grep -qx "display control rows: $((expected - 1)), want $expected" "$T/mutant.log" || exit 1 ;;
    S1) grep -qx 'display control known/known_bad_ruling.json script error' "$T/mutant.log" || exit 1 ;;
    C[1-4]) test "$(grep -c ': rejected$' "$T/mutant.log")" -eq 0 || exit 1
            grep -qx 'FAIL known-ruling invalid acceptance' "$T"/scratch/display-audit/*/display-known.log || exit 1 ;;
  esac
  exit 0
)
```

**Expected outcomes, all measured (V14, V16, V23):**

| Drill | Mutation | Expected outcome |
|---|---|---|
| R1 | no cut | `long-reason` and `long-success` FAIL (340 and 257 refused) |
| R2 | the old one-line `fail()` | `make-test-red` and `clone-red-pointer` FAIL |
| R3 | no failure `\|\| echo` | `failure-refused` FAIL |
| R4 | no success `\|\| { echo …; exit 1; }` | `success-refused` FAIL |
| R5 | no conditional pointer line | `clone-red-pointer` FAIL |
| — | echo moved after the failure post | **Equivalent** while R3's `\|\|` stands: order matters only if the post can abort `fail()`. Measured surviving in round 1; no drill. |
| E1 | D-77 kind pin deleted | `known/known_wrong_transit_kind.json wrong reason (want known-ruling)` |
| E2 | D-78 kind pin deleted | `known/known_wrong_caption_kind.json wrong reason (want known-ruling)` |
| E5 | type guard deleted | **Equivalent**: green, 31 rows, non-String fixture rejected for the ruling |
| E5b | type guard flipped | `known/known_nonstring_ruling.json missed` |
| E7 | new row deleted | `rows: 30, want 31` |
| E7b | old row deleted | `rows: 30, want 31` |
| S1 | script error on the known-ruling path | `known/known_bad_ruling.json script error` |
| C1–C4 | one D-78 caption dropped | positive control fails, 0 rows reached |


## Files touched and boundaries

Planner writes exactly these two deliverables:

- `design_docs/planned/r1/m4-7s-7o-followups-sprint.md` (this plan).
- `.ailang/state/sprints/sprint_R1-M4-JOURNEY.json` (append this one feature only).

Future executor implementation scope:

| File | Planned change |
|---|---|
| `tools/rig_check.sh` | Only approved §1 status/fail/success diff; about 13 changed lines. |
| `tools/test_rig_check.sh` | NEW; verbatim approved six-case network-free shell control, about 64 lines. |
| `mk/m45.mk` | NEW rig target/test prerequisite plus the three triples, count and live script-error guard. |
| `tests/fixtures/display_audit/known_wrong_transit_kind.json` | NEW; D-77 kind → unbound. |
| `tests/fixtures/display_audit/known_wrong_caption_kind.json` | NEW; first D-78 kind → transit-ISM, plus required folding/accompanying fields. |
| `tests/fixtures/display_audit/known_nonstring_ruling.json` | NEW; transit accepted_by → 77. |
| `.ailang/state/sprints/sprint_R1-M4-JOURNEY.json` | Dated evidence in this new feature's notes; controller owns final completion flags. |

No permanent edit to `Makefile`, `tests/display_audit.gd`, the approved design, existing fixtures, workflows, runtime/locks/packages, production or other tracked paths. The design Files table's final doc row records the designer artifact, not permission to edit it. The plan is the planner artifact and remains read-only during execution. Temporary audit/rig/m45 drill changes are restored byte-identically; they never enter a controller commit.

AC8 checks committed paths only. Supplement it with `git diff --name-only 74e68540ef891e261c598f716564503b5b67ca92` and `git ls-files --others --exclude-standard`, comparing against the exact initial inventory and the scoped implementation files; no broad UID exemption. Untracked scratch under `.godot/tmp/` is allowed and cleaned or left untracked. Review full diff and `git diff --check`; the controller verifies no production/audit/Makefile edits, including temporary mutations accidentally left behind.

## Controller-only steps and completion gates

- Refresh remote refs and rebase if scoped drift exists; all git writes, PR creation, commits and lifecycle/landing changes belong to the controller. No planner/executor commits, snapshots, stashes, checkout, reset or scratch git repositories.
- Rerun all ACs outside the sandbox against the finished implementation. AC4/AC6's final `git diff --quiet` checks run after controller commit on an otherwise clean implementation HEAD (DI-03); still compare bytes after every drill. Retain observed rc/output for counted grep commands instead of treating every nonzero shell rc as a failed gate (DI-04).
- **AC11: `tools/rig_check.sh <PR>`** on the Studio with status posting enabled. It fresh-clones the PR head, pins/stages runtime, runs sky-assets and the **entire `make test`**, and posts `rig/full`. Require full-suite rc 0 and a green `rig/full` attached to that exact implementation SHA; a printed ok line with a refused success post is rc 1 and not completion. Run this from the controller's reviewed fixed script so the test of its own status path uses the new implementation. Do not substitute a focused subset or `RIG_NO_STATUS=1`.
- Require the actual GitHub fast-tier green on the same implementation head. `.github/workflows/ci.yml` runs `make deps`, `make lore-import CHECK=1 D=/tmp/stapledons-design AILANG=ailang`, then `make ci-fast`; its workflow-call full tier runs `make test`. `deps`/lock restoration, CI scratch git operations and rig setup are controller/CI-owned under the no-git-writes rule. Do not add `rig-check-control` to ci-fast or tools-test in this sprint.
- Independent evaluation uses a different executor/judge agent or model and verifies exact named mutations, equivalent cases, scope and full evidence. No new golden/render/Mark visual review is needed for these nonvisual test/tooling changes. Any required gate blocked by sandbox writes/sockets is **UNINFORMATIVE UNDER SANDBOX** and remains pending until the Studio/controller reruns it; never call it pass or fail.

Only after all eleven ACs, independent evaluation, full `make test`/`rig/full`, GitHub fast tier and scope/metadata checks may the controller mark the new feature complete. Parent/aggregate flags stay untouched by this follow-up.

## Record correction and deferrals

Future executor notes and controller landing commit body must state the design's correction verbatim:

> `080b4f7`'s title overstated coverage. E1 and E2 survived until this row. E5 (deleting the type guard) is an equivalent mutant (V11), and its flip E5b is now controlled.

Do not rewrite history. Record closure evidence for 7i(l) from the 31-row self-count and named deletion kills. Record that C1–C4 already exercise every accepted caption through the positive control; no extra caption fixtures. E5 equivalence and echo-after-failure-post equivalence remain explicit, separate from kills.

Carry all three approved deferrals in the new feature's notes: move rig-check-control to tools-test/ci-fast when Makefile is free; repair Makefile:778's standalone catalogue-main `! grep` guard in a later row; count/protect deletion of the four non-loop display controls in a later row. No implementation of these deferrals here.

## Pause points

**None for Mark expected.** Every pillar score is 0, no pillar is negative, and 7s is D-88 A test/audit hygiene within D-66's approved sprint; 7o is the tooling batch Mark explicitly ordered. No new ruling, scope/canon choice or third quorum round is requested. The planner stops after the two reviewable artifacts and leaves handoff to the unattended controller.

Operational stops are for the controller/evaluator: refreshed scoped drift, missing prerequisites, a wrong mutation or signature, unsuccessful restoration, or an uninformative sandbox result. Preserve evidence, restore, diagnose and rerun; do not silently weaken an AC. DIs below require explicit controller disposition where needed, not a new Mark decision. Any future negative pillar or production scope expansion requires a new design decision outside this plan.

## Design inconsistencies

- **DI-01 — E5 RED is not a valid non-vacuity proof by rc alone.** The Test plan asks `drill7s "$PWD" E5 28` to exit 1 before adding fixtures. Its E5 branch first asserts mutated make rc 0, zero errors and 28 rows, then greps `display-known-known_nonstring_ruling.json.log`, which does not exist before the new fixture/row. Read-only `test -f tests/fixtures/display_audit/known_nonstring_ruling.json` returned 1. Thus the specified RED exit can come from the missing log even with a correctly equivalent mutant. Preserve the exact command/function; explicitly record the failing assertion and mutation/baseline evidence. Do not advertise this exit as proving mutation sensitivity. GREEN E5 equivalence at 31 and E1's actual RED survival remain separate required evidence. Controller may request a separate equivalent-type probe if additional RED evidence is wanted.
- **DI-02 — E7 is labelled new but removes an existing 7q row.** The expected-outcome table says E7 is a new-row deletion, while its literal PAT removes `known_wrong_accompanying.json`, already in `mk/m45.mk:22` at HEAD. E7b also removes an old row (`review_unbound`). Keep both drills verbatim; each must produce `display control rows: 30, want 31`. They prove deletion of two existing rows, not specifically deletion of a newly added 7s row. Do not claim the latter without a separately recorded controller probe.
- **DI-03 — AC4/AC6 restoration checks require committed GREEN files for the final controller run.** Their plain `git diff --quiet` compares `tools/rig_check.sh` and `mk/m45.mk` against the index, which stays at HEAD under the executor's no-git-write rule. Restoring correct uncommitted GREEN changes still makes them fail before echoing killed. Run per-drill `cmp` against GREEN copies during executor work; controller runs the exact full AC commands after committing the implementation. This is a gate-ownership prerequisite, not permission for the executor to stage, commit or skip the checks.
- **DI-04 — output assertions and exit status are different gates.** AC7's zero-match grep and AC8's zero-forbidden-path grep print the required 0 but return 1. AC2's `tail` masks the expected RED control rc 1; AC9's `tail` can mask a failed dash control. AC1/AC10 likewise report upstream rc in text while their last echo succeeds. Preserve the exact commands/expected outputs and inspect those outputs; record underlying control/dash/make rc separately. Do not run the whole AC list blindly under errexit or claim a bare pipeline rc is sufficient evidence. AC8 also needs the uncommitted/untracked review above.

Schema adaptation: the parent 7q feature has 12 keys and no `status` key; none of the existing features has one. The new feature retains those keys and adds only the explicitly requested `status: "planned"`, with `passes`, `completed` and `evaluation` null. This resolves the requested planned status without changing any other feature or top-level value. It is reported rather than silently modifying the parent's schema.

## Risks and mitigations

- GitHub/network refusal can still leave pending even on a locally green run; require exit 1 plus refused-post stdout, then controller retry/repost and verify exact-head status. This is the accepted residual risk, not a further flow change.
- `cut -c` may split future multibyte version output on GNU systems; current measured output is ASCII. Keep the design's cap unchanged and record this residual risk.
- Long TMPDIR affects pointer-fit branches; the control's length precondition must hold. Refusal cases are deliberately simulated, not evidence of a real GitHub outage. Stub PATH affects only child rig processes and makes no real git/network writes.
- Fixture drift/multiple field changes can weaken isolation. Compare parsed field deltas, retaining the intentional three-field caption change and exact untouched string values. Compact layout necessarily changes whitespace from the pretty source; byte preservation refers to untouched field content, not whole-file formatting.
- The 31-row count must change visibly whenever a later row is added. S1 depends on Godot runtime-error behavior; remeasure on a Godot bump rather than accept a different signature.
- Sandbox denials, absent baseline logs and import/cache contention can masquerade as kills. Isolate SCRATCH, run sequentially, capture per-row errors, require exact signatures and rerun affected gates on the Studio. Budget gate latency separately from code effort.

## Planner validation and state preservation

Planner used a temporary `.godot/tmp/iter44-planner-*` directory only to extract the approved shell control/drills and `git show 4bf95435:tools/rig_check.sh`. `sh -n` passed on both extracts; `shellcheck -s sh -S warning` passed with no diagnostics. Running the verbatim control against that pre-fix copy returned 1, six individual FAIL lines and final `rig-check control: 6 cases, 6 failures`, with refused lengths 160/340/257. All gh/git/make child calls were stubs, no network or actual git mutation. Scratch was removed. No fixed script, target, fixture, Godot run, GREEN drill, full suite or remote status was created/claimed by the planner.

JSON proof commands (run by planner after append; no alternate structure was needed):

```sh
jq '.features | length' .ailang/state/sprints/sprint_R1-M4-JOURNEY.json
jq -e . .ailang/state/sprints/sprint_R1-M4-JOURNEY.json
diff -u <(git show HEAD:.ailang/state/sprints/sprint_R1-M4-JOURNEY.json | jq -S .) <(jq -S 'del(.features[] | select(.id=="M4.5bR3_7s7o_FOLLOWUPS"))' .ailang/state/sprints/sprint_R1-M4-JOURNEY.json)
```

Observed feature counts: **17 before → 18 after** (+1). `jq -e .` returned 0; the required sorted diff was empty/rc 0. Exactly one new id has passes/completed/evaluation null and status planned; old feature order and every top-level value are unchanged. The feature was appended without reserializing prior content. Both approved sections were compared against the design and preserved exactly, and all eleven JSON AC command strings passed `sh -n` (substituting 123 only for the `<PR>` syntax placeholder). Final scope review and `git diff --check` confirm only the two planner deliverables beyond the original 41 untracked UID files. Controller owns all subsequent changes.
