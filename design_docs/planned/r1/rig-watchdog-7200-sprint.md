# Sprint plan: rig watchdog 7,200 s, hermetic rig-check control

**Sprint id:** R1-RIG-WATCHDOG. **Design doc (authority):** [rig-watchdog-7200.md](rig-watchdog-7200.md).
**Approval:** D-126 answer **C** (Mark, attended 2026-10-28) directs this change; D-88 test hygiene (net pillar score 0).
**Base:** `834db76c` (origin/main at planning). **Mission iteration:** 55. **Release:** r1.

## Baseline (measured by the planner at base `834db76c`)

`sh tools/test_rig_check.sh tools/rig_check.sh` → **rc 0**, six `rig-check control …: ok` lines,
trailer **`rig-check control: 6 cases, 0 failures`** (2026-10-28, matches design V3).
`git status --porcelain` clean; `.godot/tmp/wd-drills.sh` is ignored (`.gitignore:1:.godot/`).

## One milestone: WD1 — watchdog 7,200 s + hermetic control (test-first)

The executor orders the work exactly so:

1. **WD1.1 — Save the drills.** Save the design's §3 drill block **verbatim** as
   `.godot/tmp/wd-drills.sh` (ignored, under `.godot/`; never committed). The block defines
   `drillwd ROOT H|D|O`, which mutates scratch copies only and runs the control in a clean
   environment.
2. **WD1.2 — RED first.** Run **AC7** against the pre-change tree. Expected: `rc=1` (the
   pre-change control is 6 cases, not 8, so the drill baseline exits 1). **Stop if this is not red**:
   a green AC7 means the drills were saved wrong or the pre-change tree already differs; do not edit.
3. **WD1.3 — Apply the design, verbatim in substance.**
   - **Design §1** in `tools/rig_check.sh`: the single line
     `TEST_S=${RIG_TEST_S:-7200}   # make test is 66-90 min on the Studio; D-126 C (Mark, 2026-10-28)`
     replacing the `:-5400, ~50 min` line. No other change to this script.
   - **Design §2** in `tools/test_rig_check.sh`: the header ("Row 7o and D-126 control"),
     the hermetic line `unset RIG_TEST_S RIG_GOLDEN_S` right after `set -eu` (with its comment),
     the `run` usage comment and invocation change (optional 10th argument `RIG_TEST_S`, exported
     inside a subshell only when given), the `make-test-red` expectation `…ran over 7200s$`,
     the new `watchdog-override` case and comment after `clone-red-pointer`, the `caller-poison`
     guard with `RIG_CHECK_NESTED` recursion skip, and the trailer `echo "rig-check control: $n cases, $fails failures"` (`n=7` nested, `n=8` outer).
   - **Keep the hermeticity mechanism exactly as designed** (design §2, "One hermeticity mechanism,
     on purpose"): the `unset` is the only guard; the override case's export is conditional on the
     10th argument and scoped to the subshell. Do **not** "simplify" `run` to always pass
     `RIG_TEST_S=${10:-}` — that makes the `unset` dead weight and drill H survivable.
4. **WD1.4 — GREEN.** Run **AC1–AC8 and AC10** in order from the implementation root (with
   `.godot/tmp/wd-drills.sh` in place). Record the observed outputs in the sprint JSON feature's
   `notes` array only.

**AC9 is the controller's**, not the executor's (see below).

## Acceptance criteria (copied from the design's AC table; do not weaken)

| # | Criterion | Command | Expected |
|---|---|---|---|
| AC1 | The default is 7,200 s | `grep -c '^TEST_S=\${RIG_TEST_S:-7200}' tools/rig_check.sh; grep -c 5400 tools/rig_check.sh` | `1`, then `0` |
| AC2 | `make-test-red` expects the new default, and a reverted default is killed | `grep -c "ran over 7200s\\$'" tools/test_rig_check.sh; grep -c 5400 tools/test_rig_check.sh; sh -c '. .godot/tmp/wd-drills.sh; drillwd "$PWD" D'; echo rc=$?` | `1`, `0`, `drillwd D: killed (make-test-red caller-poison)`, `rc=0` |
| AC3 | Hermetic against a caller's `RIG_TEST_S` (and `RIG_GOLDEN_S`); deleting the `unset` reds a clean run | `RIG_TEST_S=1234 make rig-check-control > .godot/tmp/wd-h.log 2>&1; echo "rc=$? $(tail -1 .godot/tmp/wd-h.log)"; RIG_GOLDEN_S=999 make rig-check-control > .godot/tmp/wd-g.log 2>&1; echo "rc=$? $(tail -1 .godot/tmp/wd-g.log)"; sh -c '. .godot/tmp/wd-drills.sh; drillwd "$PWD" H'; echo rc=$?` | `rc=0 rig-check control: 8 cases, 0 failures` (twice), `drillwd H: killed (caller-poison)`, `rc=0` |
| AC4 | Green with the count asserted, under make, dash and shellcheck | `env -u RIG_TEST_S -u RIG_GOLDEN_S make rig-check-control > .godot/tmp/wd.log 2>&1; echo rc=$?; test "$(grep -c ': ok$' .godot/tmp/wd.log)" -eq 8 && echo count-ok; grep -c '^rig-check control caller-poison: ok$' .godot/tmp/wd.log; dash tools/test_rig_check.sh tools/rig_check.sh \| tail -1; shellcheck -s sh -S warning tools/rig_check.sh tools/test_rig_check.sh; echo sc=$?` | `rc=0`, `count-ok`, `1`, `rig-check control: 8 cases, 0 failures`, `sc=0` |
| AC5 | An explicit `RIG_TEST_S` still takes effect, and ignoring it is killed | `grep -c '^rig-check control watchdog-override: ok$' .godot/tmp/wd.log; sh -c '. .godot/tmp/wd-drills.sh; drillwd "$PWD" O'; echo rc=$?` | `1`, `drillwd O: killed (watchdog-override caller-poison)`, `rc=0` |
| AC6 | The CI tiers are unaffected: ci.yml's `run:` steps are `make deps`, `make lore-import CHECK=1`, `make ci-fast` and (release, `inputs.full`) `make test`; `ci-fast` does not reach the control, `test` does (AC4 covers it under dash) | `make -qp 2>/dev/null \| grep '^ci-fast:' \| tr ' ' '\n' \| grep -cx rig-check-control; make -qp 2>/dev/null \| grep '^test:' \| tr ' ' '\n' \| grep -cx rig-check-control` | `0`, then `1` |
| AC7 | RED first: the pre-change control fails the drill baseline | `R0=$(mktemp -d) && mkdir "$R0/tools" && git show origin/main:tools/rig_check.sh > "$R0/tools/rig_check.sh" && git show origin/main:tools/test_rig_check.sh > "$R0/tools/test_rig_check.sh" && sh -c ". .godot/tmp/wd-drills.sh; drillwd $R0 H"; echo rc=$?; rm -rf "$R0"` | `rc=1` |
| AC8 | Scope: two scripts, no charter | `git diff --name-only origin/main...HEAD \| grep -cvE '^(tools/(test_)?rig_check\.sh\|design_docs/planned/r1/rig-watchdog-7200(-sprint)?\.md\|\.ailang/state/(sprints\|evaluations)/.*\.json)$'; git diff --name-only origin/main...HEAD \| grep -c stapledon-mission` | `0`, then `0` |
| AC9 | Landing (**controller only**) | `tools/rig_check.sh <PR>` | `rig/full` success on the PR head. The run uses the new 7,200 s default, with no override exported. |
| AC10 | The hermetic line is exactly as designed | `grep -c '^unset RIG_TEST_S RIG_GOLDEN_S' tools/test_rig_check.sh` | `1` |

(In the table above `\|` is markdown escaping for a literal `|` in the command.)

## Files

**The executor may touch exactly two files, plus the sprint JSON `notes`:**
- `tools/rig_check.sh` (1 changed line)
- `tools/test_rig_check.sh` (16 lines: 11 added, 5 changed)
- `.ailang/state/sprints/sprint_R1-RIG-WATCHDOG.json` — **`notes[]` entries only, for AC evidence.**

**Forbidden to the executor:** `Makefile`, `mk/*` (the make wiring at `mk/m45.mk:56` already runs the
control), `design_docs/stapledon-mission*.md` (charter-line closure is the controller's, design §4),
`sim/*`, and anything held by attended PR #344. The stale dated records that quote 5400 or `6 cases`
(mission log, status archive, older planned docs and sprint JSON) stay untouched — they are dated
evidence (design §4). The drill file `.godot/tmp/wd-drills.sh` is written but never committed.

**Passes fields:** the sprint JSON `passes` fields are set by the **controller only**, and only after
`rig/full` (AC9) is green on the PR head — never by the executor. The executor leaves `passes: null`
and `status: "planned"` → execution progress belongs in `notes`.

**Do not run `make test`** (≈90 minutes; it is AC9's rig run, the controller's call).

## Estimate

- **LOC:** 17 changed lines total (design, measured on prototype V17): `tools/rig_check.sh` 1;
  `tools/test_rig_check.sh` 16 (11 added, 5 changed). Zero lines in `Makefile` and `mk/`.
- **Time:** under 1 hour per the design; planned **45–60 min** including the drill save, the RED
  check, both edits, and the AC1–AC8/AC10 runs (each control run ~2 s; drills are scratch copies).

## Risks

| Risk | Mitigation |
|---|---|
| The drill block is saved wrong, so RED never shows and the edits proceed on a false start. | WD1.2 gates the edits: AC7 must give `rc=1` before any change; stop and re-save if not. |
| The executor reshapes the hermeticity mechanism (e.g. `run` always passes `RIG_TEST_S`), making the `unset` dead weight that drill H cannot catch. | The plan and design §2 pin the exact shape; AC10 pins the `unset` line verbatim; drill H (in AC3) must kill a mutant that deletes it. |
| A caller exports `RIG_CHECK_NESTED` and silently skips `caller-poison` (control reports 7 cases). | AC4 asserts exactly 8 `: ok` lines under a clean `env -u` invocation; the name is unused anywhere else in the tree (design V19). |
| A genuinely hung `make test` now holds the rig for up to 30 more minutes before reporting. | Accepted by ruling D-126 C; the rig runs one suite at a time anyway and `RIG_TEST_S` can still lower the limit (AC5 proves the escape hatch). |
| Load pushes a rig run past 120 min (worst on record: 99 min, V13). | Out of scope; needs a new ruling. L4 (test-suite speed) removes the cause. |
| Shell portability of `unset`/`$0` re-exec (macOS bash 3.2 `sh`, CI dash). | Measured by the designer on both shells, through make and direct, with relative and absolute `$0` (V17, V18); AC4 re-checks dash and shellcheck. |

## Controller handoff

After the executor's AC1–AC8 and AC10 are green: the controller makes the D-126 **B** charter edit
(L4 ahead of Kerr a4) and strikes the iteration-52 backlog clause (design §4), opens/uses the PR,
runs AC9 (`tools/rig_check.sh <PR>`), and only on a green `rig/full` sets the sprint JSON feature
`passes: true` / `status: "done"`. Then evaluation by a different agent (generator ≠ judge) and
landing per CLAUDE.md.

**SPRINT_PLAN_PATH**: `design_docs/planned/r1/rig-watchdog-7200-sprint.md`
**SPRINT_JSON_PATH**: `.ailang/state/sprints/sprint_R1-RIG-WATCHDOG.json`
