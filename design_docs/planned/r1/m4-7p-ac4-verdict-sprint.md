# Sprint addendum: R1-M4-JOURNEY row 7p, AC4 verdict

**Status:** Planned (mission iteration 40, planner, 2026-10-20), one-day test-first addendum within approved sprint `R1-M4-JOURNEY` (D-66). Planning stops at these artifacts; the controller owns commits and execution handoff.
**Design doc:** [m4-7p-ac4-verdict.md](m4-7p-ac4-verdict.md), read in full at HEAD `1e570ea63c2bf07e145393a88d032bfc1ba8744a`, directly above `origin/main` `d6ef45e1`. Its Quorum verification log, narrow-refinement disposition and V13–V15 are binding; there is no third quorum round.
**Milestone id:** `M4.5bR3_7p_AC4_VERDICT` in `.ailang/state/sprints/sprint_R1-M4-JOURNEY.json`.
**Depends on:** `M4.5bR3_7ij_CONTEXT_CONTROLS` (landed); D-77 A and D-78 A are settled attended amendments. D-88 A permits this audit hygiene inside the approved sprint with no negative pillar.
**Size:** one day (8 hours), one milestone, about 90 code/test/data LOC (~40 audit, ~20 make, ~30 compact fixture/metadata) plus ~15 implementation record lines. **Risk:** low implementation risk; gate latency dominates. AILANG is pinned to v0.54.14. No package, simulation, protocol, numerical or production UI work.

## Reality check against HEAD

| Design seam | Pristine tree | Consequence |
|---|---|---|
| Loader / verdict | No `accepted_by` validation; only an empty known list prints bare MET | Metadata and assertion additions can demonstrate RED before changing the audit |
| Script scope | `known_entries` is unindented at line 20; loader appends at line 85 | Extraction reads the existing array; no scope change |
| Production pins | Four unbound captions and one transit-ISM entry; no acceptance fields | Add four D-78 fields and one D-77 field; retain identities, counts and row |
| Controls | 3 successful cases and 20 rejection rows | Add mixed OPEN case and four loader-rejection rows: 4 successful cases / 24 rejections |
| Verdict consumers (V9) | Scene echoes `ac4:`; valid asserts exact bare MET | Preserve bare-MET compatibility; add assertions to known and renumbered only; leave historical quotes |
| Known-file routing (V10/V14) | Known and renumbered load production pins; stale loads `known_stale.json`; scene/interlude/crew use `DISPLAY_KNOWN` defaulting to production pins | Migrate production pins only; preserve legacy stale rejection and all other assertions |
| Parent AC4 | `awk '$2 == "AC4"'` selects exactly one Markdown table row (line 664); no D-77, D-78 or OPEN text yet | Amend that row without weakening its other checks |
| Sprint parent | Exactly one `M4.5_PLAYTHROUGH_AUDIT`, with exactly one criterion starting `AC4:`; aggregate flags null and no verdict object | Executor records AC4 evidence only after AC8, preserving null aggregate flags |
| Concurrency (V13) | Local `git log d6ef45e1..origin/main -- tests/display_audit.gd mk/m45.mk tests/fixtures/display_audit/` is empty | Re-check before AC1; new overlapping commits require rebase/recount through the controller |

**Registry reuse:** `none`: this milestone changes a Godot audit, shell assertions and JSON metadata, with no package-like capability or `.ail` code. Package search and the AILANG syntax gate are not applicable. The existing sprint's historical 2,300 LOC/day estimate is not a useful gate-duration estimate: row 7i(j)'s landed notes report a 78-minute rig run. Budget for that run and evidence review instead. No existing velocity or registry records are changed by this planner.

## Tasks (Day 1, test-first, in order)

1. **Preflight and RED fixtures/assertions — 1.5 hours.** Check V13 concurrency before AC1 using the command above, with the controller ensuring `origin/main` is current. Re-check V14's `DISPLAY_KNOWN` routing and V15's diagnostic bytes. Keep all 20 original rejection rows and their known-file assignments/reasons. Add the five acceptance fields to production pins and rewrite only their `why` prose to cite the attended rulings. Keep the third caption's two leading spaces, absent caption card fields, every identity, `observed_samples` and `row`. Create five compact full-five-entry JSON copies:
   - `known_unaccepted.json`: remove only the transit `accepted_by`; retain D-77 prose, proving prose grants no authority.
   - `known_bad_ruling.json`: transit ID `D-777`.
   - `known_wrong_kind.json`: transit ID `D-78`.
   - `known_wrong_cards.json`: transit `folding_card` ends in `Card_other`.
   - `known_wrong_caption.json`: first caption becomes `Other N caption`, retaining D-78.
   In `mk/m45.mk`, retain valid's exact bare-MET grep; add qualified-MET assertions to known and known_renumbered, preserving all rc, summary, script-error and known-kind assertions. Add the unaccepted positive run on existing `known.ndjson`, exact mixed OPEN verdict, zero new/stale/failures and script-error exclusion. On its verdict mismatch use exactly `display control known_unaccepted verdict missed`. Add the four `known <new-file>.json known-ruling` rejection rows from design §3; retain nonzero rc, script-error exclusion and exact FAIL-reason checking. **Before editing `tests/display_audit.gd`, run AC1 and require a nonzero result at the new known-MET assertion.** Save the log and rc and inspect `display-known.log`: the old audit must still print `ac4: OPEN (4 known unbound, 1 known transit-ISM)` with zero failures. A 24-count failure alone on the untouched old make recipe is the planner baseline, not sufficient executor RED evidence. Do not claim unrelated loader/parse failures as RED.
2. **Validated loader and verdict GREEN — 1 hour.** Implement design §1's exact normalized tuple validator, after existing normalization and before append. Absent metadata stays loadable and unaccepted; present metadata must be a string with the matching D-77/D-78 identity. Unknown/empty/null/non-string IDs, cross-kind IDs, wrong nodes/captions/card pairs must fail `known-ruling invalid acceptance`. Keep all existing field, positive-integer count, row, duplicate, binding, lore, card-state, NEW/stale and exit-status checks. Preserve the exact seams `if not ruling_valid(entry):`, `if finding_entry.has("accepted_by"):` and `if accepted_count == known_entries.size():`. Extract `ac4_verdict() -> String` with the design's tab nesting and replace the current print. Count accepted entries, not occurrences; OPEN remains a verdict with rc 0 for valid pins. Run AC1–AC4 to GREEN, inspect all four new rejection logs for the required loader reason, and check legacy stale and renumbered controls still pass their existing contracts.
3. **Mutation drills — 1 hour.** Run AC5/M1, AC6/M2 and AC7/M3 sequentially on the fixed tree using the exact function below. Each requires its own green 24-row baseline before mutation, detects unapplied substitutions (exit 3), checks the exact named miss diagnostic and excludes script errors. M1/M2 must be killed by mixed OPEN; M3 by invalid ID. Both make calls must keep `SCRATCH="$T/scratch"` (V11/V15). Check audit byte equality before/after each drill; preserve rc/evidence in executor notes. Never use git restoration or run simultaneous drills/imports. Re-run AC1–AC4 after restoration; default control evidence must remain independent of mutation logs.
4. **Real scene evidence — 0.5 hour.** Run AC8 on the restored tree with default paths/default `DISPLAY_KNOWN`. Require qualified `MET (5 accepted by D-77/D-78)`, zero audit failures and no script errors. The known occurrences may still be 786 unbound + 42 transit-ISM: the accepted count is 5 entries. Read timing/unlocks output too. A verdict alone cannot override rc or summary failure. Report unexpected scene drift without widening pins, tolerances or UI scope.
5. **Parent and sprint evidence — 0.5 hour, after AC8 only.** Amend the parent AC4 row and opening stale “waits on D-77/D-78” sentence per design §4; preserve zero mismatches, ≥500 samples, both clocks, lore hashes and the full minimum playthrough. State D-77's two named notices, D-78's four pinned constant-notation captions, and that any other unaccepted known entry keeps AC4 OPEN. Update only the parent feature's `AC4:` criterion; add `ac4_verdict` exactly as checked by AC9 and a dated note with command, source revision and measured summary. Leave its aggregate `passes` and `completed` null. Run AC9 and `jq empty`; do not close the parent feature, sprint, or clause 4 from this verdict.
6. **Gates and independent review — 2 hours.** Run the preflight/gate list below, AC10 on the Studio and AC11 plus the complete file-scope review. Require green `rig/full` on the implementation head and the GitHub fast tier, including its lore pre-step. Re-check V13–V15 in independent evaluation (generator ≠ judge). The planner append leaves this feature's `passes`/`completed` null; executor evidence must cover all 11 ACs before claiming completion.
7. **Evidence review / reserve — 1.5 hours.** Record RED/GREEN, 3 named mutation kills, restored audit hash, scene result, scope, CI and rig links/statuses in the new feature's notes. Reserve time for import/rig latency and diagnosis. A required gate that was already red for an unrelated reason is a reported blocker, never removed from the plan. The controller handles commits and later lifecycle bookkeeping outside this implementation's Files-table scope.

## Acceptance criteria (AC1–AC11 from the design)

Run in a POSIX shell from the implementation checkout root. The commands below are copied unchanged; planner checks found no broken command or mutation expression. Setup and the definitions in the next block are required in the same shell:

```sh
mkdir -p .godot/tmp
W=.godot/tmp/display-audit/playthrough
export PATH="$PWD/runtime/bin:$PATH"
```

Every AC must exit 0 on the completed implementation. AC2–AC4 each refresh their own evidence via `controls`. AC8 and AC10 are executor/rig work, deliberately not run by the planner.

| # | Command | Expected result |
|---|---|---|
| AC1 | `controls` | rc 0; exactly 24 rejection rows, asserted. |
| AC2 | `controls && grep -qx 'ac4: MET' "$W/display-valid.log" && grep -qx 'ac4: MET (5 accepted by D-77/D-78)' "$W/display-known.log" && grep -qx 'ac4: MET (5 accepted by D-77/D-78)' "$W/display-known-renumbered.log"` | Empty compatibility and both accepted cases match exactly. |
| AC3 | `controls && grep -qx 'ac4: OPEN (1 unaccepted known, 4 accepted by D-77/D-78)' "$W/display-known-unaccepted.log" && grep -q 'new=0 .* stale=0 failures=0$' "$W/display-known-unaccepted.log"` | Mixed list stays OPEN without becoming an audit failure. |
| AC4 | `controls && for k in known_bad_ruling known_wrong_kind known_wrong_cards known_wrong_caption; do if grep -q "^display control known/$k.json: rejected$" .godot/tmp/7p-controls.log && grep -qx 'FAIL known-ruling invalid acceptance' "$W/display-known-$k.json.log"; then :; else exit 1; fi; done` | All four fail for the loader reason. |
| AC5 | `drill "$PWD" M1` | rc 0 only when forced MET is killed by the OPEN control. |
| AC6 | `drill "$PWD" M2` | rc 0 only when accepting all entries is killed by the OPEN control. |
| AC7 | `drill "$PWD" M3` | rc 0 only when dropping validation is killed by the invalid-ID control. |
| AC8 | `PATH="$PWD/runtime/bin:$PATH" make scene-session-audits AILANG="$PWD/runtime/bin/ailang" && grep -qx 'ac4: MET (5 accepted by D-77/D-78)' .godot/tmp/display-audit/playthrough/display-audit.log && grep -q '^display-audit: .* failures=0$' .godot/tmp/display-audit/playthrough/display-audit.log && ! grep -q 'SCRIPT ERROR:' .godot/tmp/display-audit/playthrough/display-audit.log` | rc 0; real scene qualified MET plus zero failures. Several minutes; required before recording MET. |
| AC9 | `awk '$2 == "AC4" {print}' design_docs/planned/r1/m4-first-journey.md > .godot/tmp/7p-parent-ac4.txt && test "$(wc -l < .godot/tmp/7p-parent-ac4.txt)" -eq 1 && grep -q 'D-77' .godot/tmp/7p-parent-ac4.txt && grep -q 'D-78' .godot/tmp/7p-parent-ac4.txt && grep -q 'OPEN' .godot/tmp/7p-parent-ac4.txt && jq -e 'any(.features[]; .id == "M4.5_PLAYTHROUGH_AUDIT" and .passes == null and .completed == null and .ac4_verdict == {status:"MET",accepted_entries:5,accepted_by:["D-77","D-78"],evidence:".godot/tmp/display-audit/playthrough/display-audit.log"} and any(.acceptance_criteria[]; startswith("AC4:") and contains("D-77") and contains("D-78")))' .ailang/state/sprints/sprint_R1-M4-JOURNEY.json` | `true`; parent and sprint criterion name both amendments, sprint records this evidence and preserves aggregate null flags. |
| AC10 | `PATH="$PWD/runtime/bin:$PATH" make python-guard && PATH="$PWD/runtime/bin:$PATH" make test AILANG="$PWD/runtime/bin/ailang"` | rc 0 on the Studio rig; merge also requires green fast tier and `rig/full` for the implementation head per CLAUDE.md. |
| AC11 | `git diff --name-only d6ef45e1 -- sim physics shaders ui demos bridge runtime > .godot/tmp/7p-production-paths.txt && test ! -s .godot/tmp/7p-production-paths.txt && git ls-files --others --exclude-standard -- sim physics shaders ui demos bridge runtime ':(exclude)**/*.uid' > .godot/tmp/7p-new-production.txt && test ! -s .godot/tmp/7p-new-production.txt` | Silent; no tracked production/physics/runtime change or new production source. Baseline untracked UID files are not implementation deliverables. |

## Control and mutation functions

Copied from the design, including the V11/V15 scratch isolation. Load these before AC1–AC7. A drill on the pristine planner tree exits at its baseline's 20-versus-24 assertion, before backup/mutation; that is expected RED, never a mutant kill. On the fixed implementation the EXIT trap restores the working copy on every exit. Scratch evidence is removed by that trap: record the command/rc and, if retaining detailed logs, copy scratch evidence before cleanup through a local shell instrumentation of the trap; never redirect mutation audit outputs to the default `.godot/tmp` audit logs. Re-check byte equality externally after each drill.

```sh
controls() (
  set -eu
  mkdir -p .godot/tmp || exit "$?"
  PATH="$PWD/runtime/bin:$PATH" make display-audit-controls \
    SCRATCH=.godot/tmp AILANG="$PWD/runtime/bin/ailang" \
    > .godot/tmp/7p-controls.log 2>&1 || exit "$?"
  test "$(grep -c ': rejected$' .godot/tmp/7p-controls.log)" -eq 24
)

drill() (
  set -eu
  ROOT=${1:?explicit checkout ROOT required}
  mutant=${2:?M1, M2 or M3 required}
  cd "$ROOT"
  ROOT=$(pwd -P)
  T=$(mktemp -d "${TMPDIR:-/tmp}/stapledon-7p.XXXXXX")
  trap 'if test -f "$T/audit.gd"; then cp "$T/audit.gd" "$ROOT/tests/display_audit.gd"; fi; rm -rf "$T"' EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM HUP
  PATH="$ROOT/runtime/bin:$PATH" make display-audit-controls \
    SCRATCH="$T/scratch" AILANG="$ROOT/runtime/bin/ailang" > "$T/baseline.log" 2>&1
  test "$(grep -c ': rejected$' "$T/baseline.log")" -eq 24
  cp tests/display_audit.gd "$T/audit.gd"
  case "$mutant" in
    M1) perl -i -pe 's/if accepted_count == known_entries\.size\(\):/if not known_entries.is_empty():/' tests/display_audit.gd ;;
    M2) perl -i -pe 's/if finding_entry\.has\("accepted_by"\):/if true:/' tests/display_audit.gd ;;
    M3) perl -i -pe 's/if not ruling_valid\(entry\):/if false:/' tests/display_audit.gd ;;
    *) exit 2 ;;
  esac
  if cmp -s "$T/audit.gd" tests/display_audit.gd; then
    exit 3
  else
    cmp_rc=$?
    test "$cmp_rc" -eq 1 || exit "$cmp_rc"
  fi
  if (
    set +e
    PATH="$ROOT/runtime/bin:$PATH" make display-audit-controls \
      SCRATCH="$T/scratch" AILANG="$ROOT/runtime/bin/ailang"
    make_rc=$?
    exit "$make_rc"
  ) > "$T/mutant.log" 2>&1; then
    exit 1
  else
    rc=$?
  fi
  test "$rc" -ne 0
  ! grep -q 'SCRIPT ERROR:' "$T/mutant.log"
  case "$mutant" in
    M1|M2) grep -q '^display control known_unaccepted verdict missed$' "$T/mutant.log" ;;
    M3) grep -q '^display control known/known_bad_ruling.json missed$' "$T/mutant.log" ;;
  esac
)
```

M1 forces MET for nonempty known lists; M2 counts every entry accepted; M3 bypasses ruling validation. Miss messages have **no colon** before `missed`; only the rejection success echo has `: rejected`. Preserve the full anchors in the function. Shell `set -e` is disabled around the expected failing mutant make through the conditional/subshell wrapper; do not simplify that wrapper.

## Gate list and CI/rig inventory

The complete make-target inventory in `.github/workflows/ci.yml` `run:` steps is `deps`, `lore-import CHECK=1 D=/tmp/stapledons-design AILANG=ailang`, `ci-fast`, and conditional full `test`. There are no separate ai/voice pre-steps in the current workflow; their applicable guards are still required through the full rig suite. The workflow file and top-level Makefile remain out of scope.

| Gate | Executor requirement / relevance |
|---|---|
| Focused controls | AC1–AC7, then restored AC1–AC4; no parse errors or unrelated failures count as kills |
| CI/rig preflight | `PATH="$PWD/runtime/bin:$PATH" make ai-live-guard python-guard in-world-voice-check AILANG="$PWD/runtime/bin/ailang"`; AI guard scans `mk/` and `tests/`, which this feature edits. Voice inputs are unchanged, but the gate remains part of `make test`; Python policy still applies |
| Scene and sibling consumers | AC8; `display-audit-interlude` and `display-audit-crew` are required via `make test` → `ship-demo-ci`, because they use the amended production pins too; no separate scene exemption |
| CI lore pre-step | `make deps`, clone the public design repo as the workflow does, then `make lore-import CHECK=1 D=/tmp/stapledons-design AILANG=ailang`. Both manifest and design-repo comparisons must pass |
| GitHub fast tier | `make ci-fast`: deps/lock, python-guard, lint-precision, strict, parity-v2, parity, parity-gr, replay, crew-sync-check, crew-parity, lore-import-check; PR `REPLAY_TICKS=2000`, main 10000. Require actual GitHub success for the implementation head |
| Studio full suite | AC10: pinned runtime, the **whole** `make test`. Controller/rig operator runs `tools/rig_check.sh <PR>` on the Studio, checking the exact implementation head, and requires posted green `rig/full`. The script stages runtime if needed and sky-assets before the suite. Local/focused success does not replace this status |
| Metadata / scope | AC9, `jq empty .ailang/state/sprints/sprint_R1-M4-JOURNEY.json`, AC11, and complete tracked/untracked path review against the exact Files list below |
| Independent evaluation | Re-check V13 external duplicate-PR/concurrency evidence, V14 actual known-file load, V15 measured space-form diagnostic/scratch isolation. Generator ≠ judge; no third design quorum round |

Merge requires **both** green `rig/full` and the green GitHub fast tier (including the workflow's lore pre-step). `make golden` is not added for this audit/metadata-only scope; a production visual change requires leaving this scope and replanning. Generic upstream skill suggestions such as `make test-changed` do not replace this repo's binding full-rig rule.

## Files / Do-not-touch

**Executor scope: only the ten paths in the design's Files table may change:**

- `tests/display_audit.gd`
- `tests/fixtures/display_audit/known_findings.json`
- `tests/fixtures/display_audit/known_unaccepted.json`
- `tests/fixtures/display_audit/known_bad_ruling.json`
- `tests/fixtures/display_audit/known_wrong_kind.json`
- `tests/fixtures/display_audit/known_wrong_cards.json`
- `tests/fixtures/display_audit/known_wrong_caption.json`
- `mk/m45.mk`
- `design_docs/planned/r1/m4-first-journey.md`
- `.ailang/state/sprints/sprint_R1-M4-JOURNEY.json`

No NDJSON capture, `known_stale.json`, other fixture, top-level `Makefile`, workflow, package pin, Python source, production UI/scene, sim/physics/shader/runtime, historical evaluation or historical verdict quote may change. No broad `docs/` or state-directory exception. The plan itself is a planner-only artifact authorized by this task: this planning pass changes only this new addendum and appends one feature plus one order entry to the sprint JSON. It does not yet amend the parent feature. The controller owns commits; no git write commands are part of this planner pass.

AC11 protects its listed production subtrees but is not a complete Files-table allowlist. **Scope correction in this plan:** retain AC11 unchanged and additionally compare `git diff --name-only 1e570ea63c2bf07e145393a88d032bfc1ba8744a` and `git ls-files --others --exclude-standard` against the exact ten executor paths, allowing only the two already-authorized planning artifacts. Exclude only the pre-existing untracked UID artifacts recorded at planner start; do not blanket-exempt newly introduced sources or arbitrary docs/state files. Use the planner HEAD as the supplemental diff base so the already-committed design doc is not misreported as an executor edit; any subsequent change to that design doc is out of scope. Inspect the actual diff, not just a count. Do not add an out-of-scope changelog or move the design doc in this milestone; later lifecycle bookkeeping belongs to the controller.

## Pause points

- **Planning boundary:** these two artifacts are the complete planner deliverable. Execution/handoff is controlled by the mission controller; no permission question or agent message is needed from this pass.
- **Before AC1:** if V13's range log becomes nonempty, pause implementation for controller rebase and re-count the actual rejection rows. V13's measured external PR check was resolved by the controller; do not re-open the design quorum.
- **After RED / before GREEN:** if new assertions do not fail the old audit for the intended verdict reason, stop and diagnose fixture/assertion isolation. Do not proceed on an unrelated baseline failure.
- **During drills/gates:** an unapplied substitution, script error, unrelated red prerequisite or changed default audit log is not a kill. Restore and diagnose. Socket binds, network or writes outside the clone blocked by sandbox are **UNINFORMATIVE UNDER SANDBOX**; record and re-run the affected check on the Studio.
- **Before recording MET:** AC8 must be measured green first. Keep aggregate parent flags null. Unexpected identities, ruling scope, fixture count drift or a necessary out-of-Files edit requires controller review/replanning, not a wider acceptance exception.
- **Before completion/merge:** all 11 ACs, independent evaluation, exact-scope review, green implementation-head `rig/full` and GitHub fast tier are mandatory. No AC4-only sprint closure.

## Planner findings

1. **Acceptance commands and sketch are usable unchanged.** AC9's default whitespace `awk` is correct for the real `| AC4 | ... |` row: field 2 is `AC4`, exactly one line selected. The sprint feature and its `AC4:` entry both exist. `sh -n` accepted all 11 commands and the functions. The sketch uses actual tabs with depth sequence `0,1,1,2,1,1,2,1`; the accepted-count increment belongs inside the loop, while the verdict returns are outside it. Godot v4.7.2 `--check-only` on a temporary scaffold containing that exact sketch and a hand-written loader seam returned rc 0, no script errors. No indentation or Perl fix is needed.
2. **Exact mutation dry-runs:** each expression from `drill()` was applied with `perl -i -pe` to its own TEMP copy of a hand-written post-implementation snippet. M1 changed only snippet line 8 (`if accepted_count == known_entries.size():`); M2 only line 6 (`if finding_entry.has("accepted_by"):`); M3 only line 17 (`if not ruling_valid(entry):`). All retained line counts and changed exactly one line. These are seam checks, not implementation or successful mutant kills.
3. **V11/V15 rechecked without implementation:** `make -n display-audit-controls SCRATCH=<TEMP>/routing/scratch AILANG="$PWD/runtime/bin/ailang"` returned rc 0; every expanded display log is under that scratch directory and none under `.godot/tmp/display-audit/`. The existing `missed` and `wrong reason` source literals match V15's no-colon convention. The controller's measured runtime miss diagnostic remains binding; independent evaluation re-measures it on the fixed tree.
4. **No broken AC command found; scope coverage needs the supplement above.** AC11 alone does not enforce the whole Files table (for example, it does not inspect arbitrary tools/docs additions). Its UID exclusion is intentional baseline handling, not a waiver for unrelated source. The explicit complete-scope review fixes this planning gap without changing an AC or widening allowed paths. It uses planner HEAD `1e570ea6` so the prior committed design doc does not create an unrelated scope failure.
5. **CI preflight is explicit.** Python and voice targets and the AI guard's read-only scanner are green at base. The full `make ai-live-guard` was source-inspected and dry-run, not executed: its scratch tests invoke `git init`/`git add`, forbidden in this planner pass. The executor must run the complete target, not substitute the scanner. Likewise no `make deps`/`ci-fast` was executed here: deps performs lockfile restoration with a git write. Full test and scene targets were expressly deferred. No unrelated red gate was found among the checks actually executed; unrun suites have no planner verdict.
6. **Sandbox diagnostics:** Godot's control import could not save external editor settings under `~/Library/Application Support/Godot`; that operation is **UNINFORMATIVE UNDER SANDBOX**, while in-clone controls completed rc 0 with 20 rejections. A first temporary parser check also reported external `user://logs` write denial (**UNINFORMATIVE UNDER SANDBOX**); re-running with `--log-file <TEMP>/check-only-godot.log` was clean rc 0. Do not count either external write failure as game failure or mutant kill.
7. **V13 external evidence is controller-supplied:** at the design base, game PRs #281/#282 each had zero matching paths and the design repo had zero open PRs. This planner checked the local origin range only; it did not redo network PR discovery. The independent evaluator re-checks V13–V15 at execution time. No production or AILANG defect was discovered.

## Planner verification (pristine implementation)

Planner date 2026-10-20, HEAD `1e570ea6` on `mission/stapledon-iter40-7p`. Before writing either deliverable, ran the requested baseline command with output saved in `.godot/tmp/7p-planner-baseline.log`:

```sh
mkdir -p .godot/tmp && PATH="$PWD/runtime/bin:$PATH" make display-audit-controls AILANG="$PWD/runtime/bin/ailang"
```

It returned **rc 0**, **20** `: rejected` rows. The known positive log prints `ac4: OPEN (4 known unbound, 1 known transit-ISM)` and `display-audit: samples=2 checks=20 mismatches=0 missing=0 new=0 known=5 stale=0 failures=0`. This agrees with the controller's measured baseline (rc 0, 15 s, 20 rows).

The exact acceptance commands were then run separately in POSIX shells with the copied functions and `W`, sequentially. AC5–AC7 reached only their failing unmutated count guard and never mutated the audit. Results:

| AC | Base result | Interpretation |
|---|---|---|
| AC1 | rc 1 (10.24 s) | Expected RED: old controls succeed but have 20, not 24, rejections |
| AC2 | rc 1 (10.30 s) | Expected RED at `controls`; bare valid MET is already green, qualified known/renumbered MET absent |
| AC3 | rc 1 (10.01 s) | Expected RED at `controls`; mixed fixture/log does not exist yet |
| AC4 | rc 1 (12.29 s) | Expected RED at `controls`; four new fixture/reason cases do not exist yet |
| AC5 | rc 1 (10.49 s) | Expected RED at drill baseline's count assertion, before mutation; no M1 kill claimed |
| AC6 | rc 1 (10.99 s) | Expected RED at drill baseline's count assertion, before mutation; no M2 kill claimed |
| AC7 | rc 1 (10.68 s) | Expected RED at drill baseline's count assertion, before mutation; no M3 kill claimed |
| AC8 | Not run, as instructed | Expected RED verdict from controller's scene measurement: target rc 0 in 177 s, `ac4: OPEN (786 known unbound, 42 known transit-ISM)`, 716 samples, checks=177686, mismatches=0 missing=0 new=0 known=828 stale=0 failures=0. This is supplied evidence, not a planner run |
| AC9 | rc 1 (0.01 s) | Expected RED: selected row lacks D-77; independently confirmed D-78/OPEN and sprint verdict/amendment are also absent |
| AC10 | Full command not run, as instructed | Python-guard prefix is green; whole `make test` / Studio rig status unverified |
| AC11 | rc 0 (0.03 s) | GREEN: no listed tracked production changes or new production sources; existing untracked UIDs excluded |

Supplementary pristine checks: `make python-guard in-world-voice-check` rc 0 (18 Python files allowlisted, zero awaiting port); `sh tools/ai_live_guard.sh .` rc 0 (34 make/shell/CI files, 321 scripts, launch builder/settings). Actual full `ai-live-guard`, GitHub fast/lore tier, scene, interlude/crew consumers, mutant kills and Studio full suite remain executor verification. No existing feature was modified to accommodate a baseline result.

TEMP evidence directory: `/var/folders/kr/h0wr2sj94vd6ljtmsxv8jkt00000gn/T/stapledon-7p-planner-fr5aq4al` (`functions.sh`, `commands.json`, `acceptance-baseline.json`, individual AC logs, independent mutant copies and `mutation-dry-runs.json`, parser/routing evidence, original sprint JSON). The tracked audit remained SHA-256 `482e42e3fcda2c7051d6e6d39f66edd0043650e3ce6f3fb04d5894d62deb49b9` after every acceptance baseline and all temporary dry-runs.

Final planner validation: `jq empty` passed; removing only the appended feature and last order ID reproduced the original JSON object, with all 15 previous features and every other top-level field unchanged. The 11 JSON commands and Markdown commands match the design, and the functions are identical. Final diff and untracked-path review found exactly the two requested planner deliverables beyond the 40 pre-existing UID artifacts. No implementation file was modified and no git write command was run.
