# Sprint plan: R1-M4-JOURNEY row 7aa, sim-pipeline-test

**Status:** Planned, mission iteration 73 planner, 2026-11-06. Branch `mission/stapledon-iter73-7aa`, HEAD `61fa25b67a9fd2647f2c96bc083f6e76a397bf5a`; implementation base **`c2e5f8f96db687d40e328cb6bc6532dc52354b4f`** (`origin/main` at planning). Feature **`M4.6vR3_7aa_SIM_PIPELINE_TEST`**, dependent on landed `M4.6uR3_7x_B4_SCRIPT_GATES`.
**Design:** [m4-7aa-sim-pipeline-test.md](m4-7aa-sim-pipeline-test.md), **revision 2, controller narrow-refinement carve-out**. Read “Quorum r2 response (revision 2, controller, carve-out)” first. Round 2 was BLOCKED 2/3; the controller took both rejecting seats' deferral fix. This plan does not claim quorum passed. D1–D5, AC1–AC10 and Appendix A1/A2/A4 bind execution; A3/AC11 is optional controller history evidence.
**Scope:** Fix the test's shared offer-id fixture, add one non-vacuity check and a counted summary, migrate exactly one Makefile recipe through `$(SCRIPT_GATE)`, remove its baseline row and lower the pin **119 → 118**. Lint **239/120/119 → 239/121/118** (total/gated/baseline). **No `ship-demo-ci: sim-pipeline-test` line or other aggregate join.** Nightly wiring is deferred to **7ab**, which must measure under the nightly idle conditions first. Preserve every existing assertion, the 0.25 timing threshold, the process-wide production counter, bridge, sim and audiovisual behavior. D-88 A applies inside the approved D-22/D-66 sprint; pillar net +1, none negative.
**Budget:** Three serial milestones, one session, **45 minutes** (20 + 10 + 15), plus automated controller handoffs, CI and independent evaluation. Revision-2 core estimate **4 files, +14/−7 = 21 changed lines**, plus about **8 changelog lines** in a fifth implementation file (V13 minus the deferred Makefile join). About **28 hand-written changed lines**, plus **1 baseline deletion**, total about 29. M1 16 lines; M2 5 core lines plus fragment; M3 0 implementation lines. Largest milestone remains well below 250 changed lines. Design estimates about 30 minutes editing; the remainder budgets the measured runtime sweep, not a claimed velocity.
**Ownership:** Planner writes only this plan and appends one JSON feature. Executor makes ordinary implementation edits and cumulative snapshots. Controller owns dependency setup, all git writes/commits/PR operations, external runtime evidence and charter landing. A different family/agent evaluates (generator ≠ judge). This plan does not start execution or add a human approval requirement to the unattended loop.

## Reality check against HEAD

Read-only observations actually made on 2026-11-06 using `git`, `rg`, numbered source reads and a Python JSON read. No Godot, make gate, dependency setup or process-table command was run by the planner. V-rows below are the design's historical runtime evidence, never planner-run verdicts.

| Check / file:line | What was observed |
|---|---|
| `git branch --show-current`; `git rev-parse HEAD origin/main`; `git status --short` | Exact branch/HEAD/base in the header; initial status empty. |
| Four implementation files against the fixed base | `git diff --name-only c2e5f8f96db687d40e328cb6bc6532dc52354b4f HEAD -- Makefile tests/test_sim_pipeline.gd mk/script-gates.mk tools/script-gate-baseline.txt` is empty. The design's measured source baseline is present. |
| `Makefile:1339`, `Makefile:1340` | `sim-pipeline-test: import`; inline rc/SCRIPT ERROR/uncounted-summary checks, `$(GODOT_SIM)`, existing log, no deadline/helper. |
| `tests/test_sim_pipeline.gd:7`, `:10`, `:13`, `:36`, `:69`, `:76`, `:83` | Failure count only; `drive()` immediately creates `SimBridge`, without reset; no `sent_n`/`offer_n`; seven existing checks; threshold 0.25; summary `sim-pipeline: %d failures`. |
| `ui/crew_console.gd:44`, `:264`, `:265` | `_serial` is static; incremented for the offer tag using turn/revision/serial. Production counter must stay static. |
| `tools/script-gate-baseline.txt:97`; `mk/script-gates.mk:11`, `:12`, `:17`, `:20` | Exact `sim-pipeline-test` baseline row (`rc,se,sum,-`); 119 noncomment data rows counted; pin 119; four distinct prerequisite pairs and pair pin 4. |
| `Makefile:1151`, `:1152`, `:1335`, `:1341` | `test: ship-demo-ci` exists; neighboring ship-ui join and frame-check gate exist; no pipeline join in the candidate location. Direct aggregate counts are future AC6 evidence, not a planner make-query result. |
| `Makefile:45`, `:49`, `:55` | `deps` restores lockfiles with `git checkout`; `ci-fast` depends on `deps`. Executor must run neither setup nor a local fast-tier target that invokes it. |
| `tools/rig_nightly.sh:19`, `:20`, `:21`, `:56`; `tools/rig_check.sh:76` | Idle defaults GPU <25%, load5 <16, six GPU samples; nightly calls rig_check with `--golden`; rig_check invokes `make test` (V23/V26). This proves reachability, not idle-condition timing safety. |
| `tests/test_crew_console.gd:478`, `:479`, `:482`; `Makefile:161` | Existing rebuilt-console check sends A's offer before building B; `test` already runs crew-console-test. Consistent with V20's unpinned same-revision case; 7ac remains necessary. |
| `.ailang/state/sprints/sprint_R1-M4-JOURNEY.json:124`, `:1738`, `:1950` | 27 existing features; final feature is B4, status implemented, passes true. Use its object schema; append feature 28 without changing earlier objects or other top-level values. |
| `design_docs/stapledon-mission.md:514` | 7aa remains NEW, with the earlier suspected divergence and instruction to attribute it; no 7ab/7ac queue entries were found in the targeted charter search. Controller must correct attribution on landing and file both follow-ups. |
| `data/starmap/stars.json` | Listed by read-only `git ls-files`; no new asset-fetch requirement (V14). |
| Available convention sources | Repo-scoped skill search found no sprint-planner skill. Use the supplied B4 plan and B4 JSON object as exact structural precedents; no outside-repo search. |

**Findings to preserve:** No source drift from the design's base was found. The controller-authorized candidate `/tmp/iter73_designer/7aa.diff` was read directly (no outside-repo search); it still adds `ship-demo-ci: sim-pipeline-test`. **The executor must drop that line** and manually implement only revision-2 D1–D3. The reference diff is not an execution dependency. Design setup `make deps import` and suggested `git apply` conflict with the no-git-writes executor contract: controller handles setup; executor uses file edits. The charter's older “divergence” language is a hypothesis superseded by V2/V6/V19–V21, not authorization to edit production code.

## Execution, sandbox and snapshot contract

The executor makes **NO git writes of any kind**: no add, commit, stash, checkout, apply, fetch, branch, reset, push or scratch clone writes. Read-only git inspection is allowed. No `make deps`; do not run `make ci-fast` locally because it reaches `deps`. Dependency setup is the controller's responsibility. If caches/runtime/import are missing, record setup pending for the automated controller; do not bypass locks or change versions. Controller setup outside sandbox follows the design: provision `make runtime` if absent, put this clone's `runtime/bin` first on PATH, verify AILANG **v0.56.1** and Godot **4.7.2**, then `make deps import` (V14/V17). `AILANG_BIN` for runtime harnesses must resolve to that pinned runtime, as the design requires. Tracked star data needs no new asset fetch.

**AC1, AC2, AC7 and AC8 belong to the controller outside the workspace-write sandbox. Every runtime/Godot/user-data/process-table gate attempted inside it is UNINFORMATIVE UNDER SANDBOX**, regardless of rc or apparent summary. The executor cannot read the process table (`pgrep`) and some Godot user-data writes are denied. Retain logs and actual statuses without a pass/fail claim; do not move user data, weaken checks, increase deadlines or delete process controls to manufacture acceptance. The design explicitly permits **AC3–AC6 and AC9** in sandbox: these target/query/policy controls invoke no Godot and require no process-table drill. This row-specific split supersedes B4's broader sandbox wording. AC10 is controller-owned GitHub evidence even though its lookup commands need no Godot.

Run runtime targets serially, through **`make sim-pipeline-test`** when evaluating that control. A Godot `--script` gate passes only with its own successful summary, no `SCRIPT ERROR`, the correct rc and completion within its deadline; rc alone is insufficient. Retain the unfiltered output and originating make/Godot status before grep/tail views. Zero-match `grep -c` prints 0 with rc 1: expected zero counts are not failed assertions by themselves. The 600 s helper bound excludes the existing import prerequisite; do not assert a finite whole-target deadline. If a long command is supervised asynchronously, remove stale status evidence and preserve its real completion; keep progress intervals at most 60 seconds.

After **every milestone**, copy **every created-or-modified deliverable cumulatively** to **`.godot/tmp/snap/M1/`**, **`M2/`**, **`M3/`**, retaining repo-relative paths. Include this plan, the sprint JSON and the design already added on this branch relative to the implementation base, plus every implementation file created/modified so far. M3 retains all M1/M2 files despite zero implementation edits. Include `FILES.txt` and `RESULT.txt` listing copied paths, exact commands, log paths, originating statuses, V-row provenance, acceptance disposition and sandbox limits; build manifests outside the copy set to avoid recursion. Restore every mutant before snapshots; exclude generated caches, harness scripts and scratch logs from the implementation copy set, but keep their evidence locations in RESULT. Never copy transient bridge/console mutants as deliverables.

The controller rebuilds **one commit per milestone** from these snapshots. M3 may update only this feature's progress notes/status so the run-only milestone has a reviewable evidence record. Preserve all **27** existing feature objects and every other top-level JSON value; execution progress belongs solely to the appended feature. Start `status: planned`, `passes: false`; do not set passes true until external acceptance, actual PR-head CI and independent evaluation are complete. Landing bookkeeping remains controller-owned.

## Scope guard and sequence

Implementation allowlist: **`Makefile`**, **`tests/test_sim_pipeline.gd`**, **`tools/script-gate-baseline.txt`**, **`mk/script-gates.mk`**, **`changelogs/unreleased/2026-11-06-sim-pipeline-test.md`**. Planning artifacts: approved design, this plan, appended feature. No new `.gd`/`.uid`, AILANG package, helper, asset, protocol or public reset API. Preserve `bridge/`, `sim/`, `ui/`, other baseline rows, all aggregate prerequisites, helper/lint scripts, and all D-144 attended territory. Controller charter changes happen at landing, outside the executor implementation allowlist.

**M1 → M2 → M3.** Follow the supplied milestone grouping. This deliberately differs from the design's sub-milestone 1, which groups D3 with the recipe before the red step: here M1 owns recipe/test, M2 owns the baseline/pin/fragment. The reason is the mission's explicit milestone guidance and separately reviewable fixture and ratchet commits. V18 measured the recipe-only refusal with D3 already applied; D3 changes lint metadata, not `sim-pipeline-test: import` execution. Preserve V18's runtime expectation; no new interim lint gate is invented. **M1's migrated row still on the old baseline is intentionally not lint-clean. Do not claim AC3/AC4 complete at M1 or run PR fast tier on that interim snapshot.** M2 resolves it before final acceptance.

Registry reuse: **none** for M1–M3. Existing repository-specific GDScript/Make fixture maintenance and validation; no package-like capability or `.ail` changes. Reuse the landed helper/lint and the design's measured harnesses. No registry search or extra test suite is required.

## Milestones (test-first)

### M1 — Counted Makefile gate RED first, then isolated fixture and counted summary

**Files/estimate:** `Makefile` +1/−1; `tests/test_sim_pipeline.gd` +11/−3. **16 changed lines, 20 minutes plus controller handoff.** Depends on landed B4. Keep baseline row/pin 119 until M2.

1. Replace **only the recipe** first, with the test unchanged:

   ```make
       @$(SCRIPT_GATE) sim-pipeline-test $(SCRATCH)/sim-pipeline.log 600 '^sim-pipeline: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT_SIM) --headless --path . --script tests/test_sim_pipeline.gd
   ```

   Preserve target `import`, description, command environment and log path. **Drop the reference diff's `ship-demo-ci: sim-pipeline-test` line.** Retain a recipe-only checkpoint under `.godot/tmp/7aa/m1-red/` with the Makefile and unmodified test for controller replay; this is ignored evidence, not an extra milestone or commit.
2. **RED gate, controller outside sandbox, before the test fix:** `make sim-pipeline-test`. Require make rc 2; the three existing FAIL lines (sent journal/world/crew); old `sim-pipeline: 3 failures`; helper rejection containing **`no summary line matching`** and `rc 1, want 0` (V18). Save exact raw output and live log. The executor hands this checkpoint to the automated controller and proceeds with D1 only after the external red is recorded; sandbox errors cannot substitute. If replay is needed, the controller uses the preserved pre-fix content, never the fixed test. This is an execution-evidence handoff, not a request for human permission.
3. Implement D1: `var passes := 0`; count true checks, failures otherwise; at the **top of `drive()` before `SimBridge.new()`**, add the three-line cause comment naming row 7aa/`b42fc0e3`/the two ids and **`CrewConsole._serial = 0`**. Add `sent_n = sim.sent_log.size()` and guarded `offer_n` from journal index 40 only when its tick is 41 (otherwise −1). Before the journal equality check add **`a.sent_n == 60 and a.offer_n == 2`** with the design's exact label. Summary becomes **`sim-pipeline: %d passed, %d failures`** with `[passes, failures]`. Keep all seven original assertions, exact JSON comparisons, guided voyage and 0.25 threshold unchanged. Do not edit the production static counter.
4. **GREEN gate list:** one controller `make sim-pipeline-test` must yield `8 passed, 0 failures`, rc 0 and no SCRIPT ERROR (AC1 interim, V7/V17); AC2 on that same live log must give **8 / 0 / 4** (V7/V17). M3 runs final AC1 twice. Do not substitute a direct Godot call for the make control. No lint gate here because baseline cleanup intentionally belongs to M2.

**Milestone ACs:** AC1/AC2 interim. **Stop/report:** red evidence unavailable or unlike V18, wrong successful count, changed existing assertion, missing fixture check, runtime/sandbox ambiguity or any aggregate join. Snapshot M1 cumulatively; controller creates milestone commit 1.

### M2 — Delete exactly one baseline row, lower pin and add revision-2 changelog

**Files/estimate:** `tools/script-gate-baseline.txt` −1; `mk/script-gates.mk` +2/−2; new dated fragment about 8 lines. **5 core changed lines plus fragment, 10 minutes.** Depends on M1.

1. **Negative controls first:** retain V9's measured base pin refusal (119 rows against override 118) and M1's deliberately stale migration state; use the existing design evidence rather than invent an unmeasured pre-fix gate. The adversarial acceptance checks are AC4's old-pin rejection and AC5's restored-row rejection after the fix. They must stay red for their stated reasons, not because of unrelated sandbox errors.
2. Delete only the exact line **`sim-pipeline-test\ttests/test_sim_pipeline.gd\trc,se,sum,-`** (tabs in the file). Set **`SCRIPT_GATE_BASELINE_ROWS := 118`** and extend the existing history comment with **`, 118 after row 7aa (sim-pipeline-test).`**, replacing the preceding final period as in D3. No other row or prerequisite-pair change.
3. Create `changelogs/unreleased/2026-11-06-sim-pipeline-test.md`, `### Fixed`, with the revision-2 Deliverables text (wrapping is immaterial):

   > `make sim-pipeline-test` (pipelined heartbeats end byte-identical to synchronous ones) was red since `b42fc0e3`. The test's two runs shared CrewConsole's process-wide offer-id counter, so they sent different offers. Each run now starts the counter afresh. The gate goes through `$(SCRIPT_GATE)` with a counted summary; joining the nightly waits for a timing measurement under the nightly's idle conditions (row 7ab).

4. **Gate list (sandbox permitted):** AC3 `make script-gate-lint` gives **239/121/118**, four pairs, rc 0 (V10/V14/V17); AC4 rejects pin 119 and counts **0 / 118** (V10/V17); AC5 rejects re-added row with **rc 1 / one stale diagnostic** (V10/V17); AC6 gives **0 / 1 / 0 / 1** for revision-2 wiring/inventory (V9/V10/V17 plus r2 AC6); AC9 policy/scope gives **0 unexpected / 0 production paths**, 406 uid files, 21 Python allowlisted, `gates-ok` (V13/V17). Review untracked files too. Save actual originating statuses before filtered output.

**Milestone ACs:** AC3–AC6, AC9. **Stop/report:** pin/row arithmetic drift, other baseline edits, unexpected production path, missing fragment or any nightly join. Snapshot M2 cumulatively, including M1 files; controller creates milestone commit 2.

### M3 — Run-only acceptance sweep, controller drills, PR fast tier and landing handoff

**Files/estimate:** **0 implementation LOC, 15 minutes plus asynchronous CI/evaluation**. Only appended-feature progress and ignored evidence/snapshots change. Depends on M2 and controller runtime access.

1. Keep M1 red evidence and M2 adversarial controls with their measured reasons. Extract A1/A2/A4 using the catalogue below. No dependency on designer scratch files and no A3/history execution by the executor.
2. **Controller gate list outside sandbox:** final **AC1 twice** through make, preserving each full output/log; **AC2 8/0/4** from the live capture; **AC8** mechanism diagnostic with `diag: done`, all measured fields and no SCRIPT ERROR (V2/V17); **AC7** all eight drills (V25). Copy final AC1 captures aside before drills overwrite the main log. AC7's A1 must restore and cmp-check test/bridge/console byte-for-byte; compare pre/post status including unrelated existing planning changes.
3. Drill acceptance retains every measured control: **d0** eight checks green; **k1** no-reset regression `5 passed, 3 failures` and the three original FAILs; **k2** real pipelined-time divergence `4 passed, 4 failures`, world and guided equality failures; **k3** parse SCRIPT ERROR rejected even with Godot rc 0; **k4** zero-count summary rejected; **k5** exact ERE accepts 8 and rejects zero/failure/old summary, helper refuses loose `[0-9]*`; **k6** per-console attribution control green; **k7** static ids `tc0-4-2`/`tc0-4-3` with no refusal versus duplicated `tc0-4-1-counselor` with `crew:blocked:altered_duplicate:offer-tc0-4-1-counselor`. k6 is diagnostic proof, never a proposed production fix. k7 asserts A4's completion/fields and no SCRIPT ERROR rather than trusting its rc (V19–V21/V25).
4. **Executor gate list:** catalogue AC3–AC6 and AC9 can run in sandbox. Include M2 results in this complete sweep if covered files are byte-identical; repeat only after edits, restoration drift or unresolved failures. Final scope remains the five-file implementation allowlist. Do not add broad `make test`, `make golden`, inherited process/orphan self-tests or new unmeasured gates.
5. **Controller AC10:** after snapshot commits/PR exist, use actual PR/head/run IDs for fast-tier success and the 118-baseline CI line. This is the design's requested future CI gate, not a claimed prior PR result. A pending run remains pending. Independent evaluation must use another family, with the red/green/drill/scope evidence; keep passes false until complete.
6. Snapshot M3 cumulatively with this feature's evidence/progress notes; controller creates milestone commit 3. Controller then owns the landing checklist below, including charter edits and design archival. No implementation edits are authorized in this run-only milestone; report a discovered defect for correction and fresh snapshots rather than silently changing scope.

**Milestone ACs:** AC1–AC10 complete. **Stop/report:** surviving mutant, missing runtime evidence, altered production restoration, timing/cold-start failure, red/pending CI or independent evaluation still absent. Optional **AC11** is not scheduled: V5/V16 already supply history. A3 clones/checks out historical commits and downloads runtimes, so it is controller-only if separately needed; never run it under the executor's no-git-writes contract.

## Acceptance coverage

All V citations refer to the approved design. No new test gate has been invented. AC6's first count is the explicit revision-2 correction to V10/V17; AC10 is the design's prospective PR gate, whose final PR evidence necessarily follows implementation.

| AC | Owner milestone | Execution owner / evidence |
|---|---|---|
| AC1 | M1 interim; M3 final | Controller outside sandbox. V7, V14, V17. |
| AC2 | M1 interim; M3 final | Controller outside sandbox; tied to live AC1 capture. V7, V17. |
| AC3 | M2; M3 evidence sweep | Executor sandbox permitted: no Godot/process drill. V9 base; V10, V14, V17 final. |
| AC4 | M2; M3 evidence sweep | Executor sandbox permitted. V10, V17. |
| AC5 | M2; M3 evidence sweep | Executor sandbox permitted. V10, V17. |
| AC6 | M2; M3 evidence sweep | Executor sandbox permitted. V9, V10, V17; revision-2 AC6, V26. |
| AC7 | M3 | Controller outside sandbox: Godot user data and process controls. V8, V14, V21, V25. |
| AC8 | M3 | Controller outside sandbox: Godot and sim user data. V2, V17. |
| AC9 | M2; M3 evidence sweep | Executor sandbox permitted. V13, V17. |
| AC10 | M3, after controller commits/PR | Controller, GitHub PR/head evidence. Design AC10; V11 existing fast tier and V14/V17 measured lint; B4 sprint AC13 artifact lookup. |

## Acceptance catalogue (approved AC1–AC10)

Future executor/controller commands, not planner results. Decode Markdown-table escapes as real pipes. Commands below retain the measured checks, pin the observed base for scope and capture originating statuses where the design filtered them away. Runtime evidence stays external as specified above. Scratch extraction and artifact lookup are plumbing for the existing gates, not extra acceptance gates.

Extract only A1/A2/A4; A3 history is omitted:

````sh
x() { awk -v t="$1" '$0 == "```" t {f=1; next} f && $0 == "```" {exit} f' design_docs/planned/r1/m4-7aa-sim-pipeline-test.md; }
mkdir -p .godot/tmp/7aa
x 'sh 7aa-drill' > .godot/tmp/7aa/drill.sh
x 'gdscript 7aa-diag' > .godot/tmp/7aa/diag.gd
x 'gdscript 7aa-ids' > .godot/tmp/7aa/ids.gd
````

Controller runs AC8 with `AILANG_BIN` pointing to the pinned `runtime/bin/ailang` and pinned runtime first on PATH. AC7's k7 resolves it from PATH. A1 removes its own temporary logs on exit: tee/preserve its result stream and, if raw per-drill logs are required, copy them before its cleanup without changing checks or production content. Never use a post-cleanup missing log to claim a result. Whole-harness rc and eight exact drill outcomes remain required.

### AC1

**M1 interim; M3 final; Controller outside sandbox. Evidence: V7, V14, V17.**

```sh
for r in 1 2; do make sim-pipeline-test; echo rc=$?; done
```

Expected: Twice: script-gate: sim-pipeline-test ok: sim-pipeline: 8 passed, 0 failures (rc 0, no SCRIPT ERROR, N s of 600 s), then rc=0. Design AC1 expects N under 120; V14 measured 50 s and 44 s. Preserve actual times; the helper deadline remains 600 s.

### AC2

**M1 interim; M3 final; Controller outside sandbox; tied to live AC1 capture. Evidence: V7, V17.**

```sh
L=.godot/tmp/sim-pipeline.log
grep -c '^ok ' "$L"
grep -cE '^FAIL |SCRIPT ERROR' "$L"
grep -cxE 'ok (same inputs in the same order \(sent journal\)|same world at the end|same crew at the end|the journal holds 60 ticks and the tick-41 crew offer \(offer and ask\))' "$L"
```

Expected: 8; 0; 4, from the live AC1 capture. Save each AC1 run log before the next run or any drill overwrites it. The eight ok lines are the positive capture control.

### AC3

**M2; M3 evidence sweep; Executor sandbox permitted: no Godot/process drill. Evidence: V9 base; V10, V14, V17 final.**

```sh
make script-gate-lint; echo rc=$?
```

Expected: script-gate-lint: ok (239 --script invocations: 121 through $(SCRIPT_GATE), 118 on the baseline; 22 includes, all in mk/*.mk; 23 makefiles scanned); script-gate-prereqs: ok (4 pairs hold in Makefile: constellation-test:starmap-assets planets-test:planet-assets planet-textures-check:planet-assets ship-console-test:ship-baseline); rc=0.

### AC4

**M2; M3 evidence sweep; Executor sandbox permitted. Evidence: V10, V17.**

```sh
make script-gate-lint SCRIPT_GATE_BASELINE_ROWS=119 > .godot/tmp/7aa/pin.out 2>&1
rc=$?; echo "make rc=$rc"
grep 'the baseline has' .godot/tmp/7aa/pin.out
grep -c '^sim-pipeline-test' tools/script-gate-baseline.txt
grep -vc '^#' tools/script-gate-baseline.txt
```

Expected: Reject the old pin: script-gate-lint: the baseline has 118 rows but SCRIPT_GATE_BASELINE_ROWS is 119: the pin moves with the rows, and only down; then 0; 118. Keep the originating make rejection status separately from grep statuses.

### AC5

**M2; M3 evidence sweep; Executor sandbox permitted. Evidence: V10, V17.**

```sh
mkdir -p .godot/tmp/7aa
{ cat tools/script-gate-baseline.txt; printf 'sim-pipeline-test\ttests/test_sim_pipeline.gd\trc,se,sum,-\n'; } > .godot/tmp/7aa/back.txt
SCRIPT_GATE_BASELINE=.godot/tmp/7aa/back.txt SCRIPT_GATE_BASELINE_ROWS=119 sh tools/script_gate_lint.sh > .godot/tmp/7aa/back.out 2>&1
echo rc=$?
grep -c '^script-gate-lint: ' .godot/tmp/7aa/back.out
grep '^script-gate-lint: stale' .godot/tmp/7aa/back.out
```

Expected: rc=1; 1; script-gate-lint: stale baseline row (no longer unguarded): delete it and lower SCRIPT_GATE_BASELINE_ROWS: sim-pipeline-test tests/test_sim_pipeline.gd. The real baseline is never modified by this control.

### AC6

**M2; M3 evidence sweep; Executor sandbox permitted. Evidence: V9, V10, V17; revision-2 AC6, V26.**

```sh
P=$(make -pq 2>/dev/null)
for a in ship-demo-ci:sim-pipeline-test test:ship-demo-ci ci-fast:sim-pipeline-test; do
  printf '%s\n' "$P" | awk -v t="${a%%:*}:" '$1 == t' | tr ' ' '\n' | grep -cx "${a#*:}"
done
make --no-print-directory script-gate-inventory > .godot/tmp/7aa/inventory.tsv
rc=$?; echo "inventory rc=$rc"
grep -cE 'sim-pipeline-test.tests/test_sim_pipeline\.gd.gated.rc,se,sum,to$' .godot/tmp/7aa/inventory.tsv
```

Expected: Revision 2 prerequisite counts 0, 1, 0; inventory rc=0 and count 1. V10/V17 measured revision 1 counts 1,1,0,1; revision 2 explicitly removes only the first join. V9 already measured its absent base state. The test-to-ship-demo-ci join remains. make -pq is a database query, not a success gate on its query rc.

### AC7

**M3; Controller outside sandbox: Godot user data and process controls. Evidence: V8, V14, V21, V25.**

```sh
sh .godot/tmp/7aa/drill.sh "$PWD"; echo rc=$?
git status --porcelain
```

Expected: Eight drill ok lines d0 k1 k2 k3 k4 k5 k6 k7; sim-pipeline-drill: ok (8 drills: d0 k1 k2 k3 k4 k5 k6 k7); rc=0. Compare status with its pre-drill capture, not with an assumed clean executor tree. Three mutated files must be restored byte-for-byte by A1 cmp checks. Preserve logs outside the harness temporary directory before cleanup if needed.

### AC8

**M3; Controller outside sandbox: Godot and sim user data. Evidence: V2, V17.**

```sh
godot --headless --path . --script "$PWD/.godot/tmp/7aa/diag.gd" > .godot/tmp/7aa/diag.log 2>&1
rc=$?; echo "Godot rc=$rc"
grep -E '^(PAGE_TICK|PAGE_CREW|SENT_LEN|WORLD_DIFF|DRAINED|diag)' .godot/tmp/7aa/diag.log
grep -c '^SENT_DIFF 40$' .godot/tmp/7aa/diag.log
grep -cE '^SENT_DIFF' .godot/tmp/7aa/diag.log
grep -oE 'tc6-61-[12]-pilot' .godot/tmp/7aa/diag.log | sort -u
grep -c 'SCRIPT ERROR' .godot/tmp/7aa/diag.log
```

Expected: Godot rc=0 plus PAGE_TICK sync=40 piped=39 piped_drained=40; PAGE_CREW same sync/piped=true sync/piped_drained=true; SENT_LEN 60 60; WORLD_DIFF key crew; DRAINED_VARIANT sent_same=false world_same=false crew_same=false; diag: done; SENT_DIFF counts 1 and 1; ids tc6-61-1-pilot and tc6-61-2-pilot; no SCRIPT ERROR. A2 deliberately has no reset, so these diagnostic differences persist on the fixed branch. This is mechanism evidence, not a green sim-pipeline-test substitute.

### AC9

**M2; M3 evidence sweep; Executor sandbox permitted. Evidence: V13, V17.**

```sh
git diff --name-only c2e5f8f96db687d40e328cb6bc6532dc52354b4f | grep -cvxE 'Makefile|mk/script-gates\.mk|tools/script-gate-baseline\.txt|tests/test_sim_pipeline\.gd|changelogs/unreleased/2026-11-06-sim-pipeline-test\.md|design_docs/planned/r1/m4-7aa-sim-pipeline-test.*\.md|\.ailang/state/sprints/sprint_R1-M4-JOURNEY\.json'
git diff --name-only c2e5f8f96db687d40e328cb6bc6532dc52354b4f -- bridge/ sim/ ui/ | wc -l | tr -d ' '
make --no-print-directory uid-guard python-guard && git diff --check c2e5f8f96db687d40e328cb6bc6532dc52354b4f && echo gates-ok
```

Expected: 0 unexpected diff paths; 0 bridge/sim/ui paths; uid-guard: ok (406 .uid files); python-guard: ok (21 allowlisted, 0 awaiting AILANG port); gates-ok. Use the fixed base, equal to origin/main observed by the planner. git diff does not enumerate untracked files: also review the complete created-file list/status, including the exact changelog path, against the allowlist.

### AC10

**M3, after controller commits/PR; Controller, GitHub PR/head evidence. Evidence: Design AC10; V11 existing fast tier and V14/V17 measured lint; B4 sprint AC13 artifact lookup.**

```sh
SG7AA_PR=$(gh pr view --json number --jq '.number') || exit 1
SG7AA_HEAD=$(gh pr view "$SG7AA_PR" --json headRefOid --jq '.headRefOid') || exit 1
gh pr checks "$SG7AA_PR" || exit 1
SG7AA_RUN=$(gh run list --workflow ci.yml --event pull_request --commit "$SG7AA_HEAD" --limit 1 --json databaseId --jq '.[0].databaseId') || exit 1
test -n "$SG7AA_RUN" && test "$SG7AA_RUN" != null || exit 1
gh run view "$SG7AA_RUN" --log > .godot/tmp/7aa/ci.log || exit 1
grep -c '118 on the baseline' .godot/tmp/7aa/ci.log
```

Expected: Actual PR-head GitHub fast tier success and at least one 118 on the baseline line in that head's CI log (121 through the gate). Missing/pending CI is pending, not success. Artifact lookup follows the supplied B4 sprint precedent. This future PR result is not a planner measurement.

## Risks and mitigations

| Risk / conflict | Decision / mitigation |
|---|---|
| Candidate diff contains revision-1 nightly wiring; V10/V17 AC6 first count is 1. | Drop `ship-demo-ci: sim-pipeline-test`. Final AC6 is **0,1,0,1**. Revision-2 quorum response overrides r1 wording. Row 7ab measures idle timing before any join. |
| Idle-regime timing is unmeasured; worst busy-host ratio was 0.209 (V23/V24). | Keep the assertion 0.25 unchanged and add no aggregate. 7ab requires Studio GPU <25%, load5 <16 measurements and load cases; if every run stays below 0.22, wire there, otherwise establish the threshold from that distribution first. No safety claim from busy-host timings. |
| Reset reaches a conventionally private static member. | Keep it in the test at the start of drive only; no public production helper. Each drive starts a new sim session. Preserve k7's proof that making production ids per-console causes an altered_duplicate refusal (V19–V21). |
| M1 is intentionally lint-incomplete until M2. | Explicit mission grouping; do not claim interim lint acceptance or send M1 alone to CI. Runtime red/green is through its make target; M2 removes stale metadata before the final sweep. |
| Design setup/application and optional A3 perform git writes. | Controller owns dependency setup; executor uses ordinary edits, never make deps/git apply/history clones. Reference diff read is authorized, application is not. |
| Sandbox user-data/process denial looks like a test failure or an apparent success. | AC1/AC2/AC7/AC8 are controller-owned; runtime attempts inside are **UNINFORMATIVE UNDER SANDBOX**, never pass/fail evidence. AC3–AC6/AC9 remain explicitly permitted. |
| Godot parse errors can exit 0; stale captures or filtered shell rc can look green. | Own summary plus no SCRIPT ERROR and actual originating rc/deadline; copy each live capture and run k3/k4/k5 unchanged. AC2's eight ok lines pin capture non-vacuity. |
| A cold runtime start produces incomplete runs/0.00 ms (V5). | Record separately and stop acceptance; do not loosen threshold/assertions. Not seen in the design's later fresh-clone runs (V14/V16). |
| Historical PR overlap information becomes stale; another 7x batch could move the pin. | Header pins the exact measured base and all four core files match it now. Controller rechecks overlap at pickup. If a rebase changes baseline counts, report/reconcile with the controller rather than blindly applying 118 or changing scope. V12 is historical, not a planner claim about current remote PRs. |
| AC9 diff filters miss untracked files; A1 status assumes a clean clone. | Review the cumulative created-file manifest and initial/final read-only status. Compare drill status with its actual starting state, require byte restoration, never clear unrelated work. |
| AC10 has no completed run for this not-yet-built PR. | It is the approved design's prospective fast-tier gate, backed by existing-tier V11 and measured lint V14/V17. Record actual PR/head/run after controller commits; pending stays pending. No extra gate is introduced. |
| sprint-planner skill absent within repo boundary. | Supplied B4 sprint shape and last B4 feature schema provide the convention. No outside-repo search or missing-skill permission flow. |

## Landing checklist (controller-owned)

- [ ] Rebuild one commit per milestone from cumulative M1/M2/M3 snapshots; compare contents/manifests and ensure all test mutants are restored. Preserve the first 27 features and every unrelated top-level value.
- [ ] AC1–AC10 have their required evidence/owners, including outside-sandbox runtime results, actual PR-head fast-tier success, and independent cross-family evaluation. Mark this feature implemented/passes true only after those requirements complete.
- [ ] Verify final recipe contains counted helper/600 s and **no `ship-demo-ci: sim-pipeline-test` line**. Verify one deleted baseline row, pin 118, final lint 239/121/118, four pairs, unchanged production static counter and exact five-file implementation scope with dated revision-2 fragment.
- [ ] Mark **charter row 7aa LANDED**, with landed PR/commit and measured test-side attribution; remove the obsolete claim that different inputs prove a sim divergence. Archive the design under implemented/r1 and update relevant links according to CLAUDE.md in the controller's landing bookkeeping.
- [ ] File **7ab** in the charter queue: measure sync/pipelined heartbeat ratios over N Studio runs under the nightly's own idle start conditions (GPU <25%, load5 <16) and under load; only then decide threshold/wiring. If every run stays below 0.22, add the ship-demo-ci join in that follow-up; otherwise establish the threshold from the distribution first. **7ab is a prerequisite of nightly wiring**, not a post-flake repair row.
- [ ] File **7ac** in the charter queue: add Appendix A4's two-consoles/no-send-between case to `tests/test_crew_console.gd`, proving production static ids prevent altered_duplicate and a per-console mutation makes crew-console-test red. Existing make test reachability is already present; no crew-console test edit in 7aa.
- [ ] Record follow-up row links, landing evidence and main-nightly disposition without claiming this row joins the nightly. Existing nightly policy remains in force; no new broad runtime sweep is scheduled by this plan.

## LOC footer

| Final implementation allocation | Added | Deleted | Changed lines |
|---|---:|---:|---:|
| Makefile recipe (M1) | 1 | 1 | 2 |
| tests/test_sim_pipeline.gd (M1) | 11 | 3 | 14 |
| mk/script-gates.mk pin/comment (M2) | 2 | 2 | 4 |
| tools/script-gate-baseline.txt (M2) | 0 | 1 | 1 |
| Core total (V13 minus deferred join) | 14 | 7 | 21 |
| Dated changelog fragment (M2, estimate) | 8 | 0 | 8 |
| Total estimate, five implementation files | 22 | 7 | 29 |

Hand-written estimate 28 changed lines plus one baseline deletion. M1 **16**, M2 **13** including fragment, M3 **0**. Planning artifacts and ignored snapshots/evidence are excluded from implementation LOC. Only the two authorized planning deliverables were written by the planner; no runtime verdict is claimed.
