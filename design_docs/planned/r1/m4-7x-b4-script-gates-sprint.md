# Sprint plan: R1-M4-JOURNEY row 7x, B4a script gates

**Status:** Planned, mission iteration 72 planner, 2026-11-05. Branch `feat/m4-7x-b4-script-gates`, HEAD `955c6d1a47d939249bb9c649fc72aafcac3ff092`; implementation base `05e64cd1cf2109684f3b081eb550249945cd243b` (`origin/main` at planning). Feature **`M4.6uR3_7x_B4_SCRIPT_GATES`**, dependent on landed `M4.6tR3_7x_B3_SCRIPT_GATES`.
**Design:** [m4-7x-b4-script-gates.md](m4-7x-b4-script-gates.md), **revision 1 implementation scope plus the controller's revision 2 status-count correction under the narrow-refinement carve-out**. Round 1 was BLOCKED 2/3; round 2 was BLOCKED 1/3 and the controller closed the rejection with its supplied fix. This does not claim quorum passed. Read both quorum response sections first. D1–D9, D2's per-line predicates/deadlines, AC1–AC14 and Appendix A1–A5 bind execution.
**Scope:** B4a only: **56 baseline rows, 48 targets, 57 gate lines** at `Makefile:1080` onward; 19 counted-summary scripts; the fourth asset-prerequisite pair and its count pin; one bounded curl invocation. Baseline **175 → 119**; lint **238/63/175 → 239/120/119** (total/gated/baseline). The geometry-negative loop becomes two lines. No assertion, physics, scene, sound or gameplay change. Pillar net 0; D-88 A inside the D-22/D-66 approved sprint.
**Budget:** One working session/day, six serial milestones, **140 minutes** including editing buffer and the roughly 41-minute acceptance run, plus asynchronous PR fast-tier and controller/evaluator availability. The measured implementation diff at `05e64cd1` is **24 files, +135/−164**: **243 hand-written changed lines plus 56 baseline deletions**. Allocations are 18 + 97 + 128 + 0 + 0 + 0 hand-written lines; M3 also owns the 56 baseline deletions, for a largest milestone of **184 changed lines**. These are allocations of the final diff, not promised intermediate numstats or a measured velocity.
**Ownership:** The planner writes only this plan and appends one JSON feature. The controller owns commits, PR operations, dependency setup that writes git, and runtime verdicts outside the sandbox. The executor edits implementation files and snapshots each milestone; an independent evaluator owns judgment (generator ≠ judge). The controller schedules execution; this plan does not start it or introduce a new approval gate.

## Reality check against HEAD

Read-only planner observations, 2026-11-05. No Godot or make gate was run. Future gate expectations come from the approved design's measurements, not this planner's runtime evidence.

| Check | Observed |
|---|---|
| `git branch --show-current`; `git rev-parse HEAD origin/main` | Branch and revisions in the header. |
| `git status --porcelain` before planning | Empty. |
| `mk/script-gates.mk` | Baseline pin 175; three `SG_PREREQS` pairs; no `SG_PREREQS_PAIRS` count pin. The real check and its negative fixture both consume the same list. |
| `tests/fixtures/script_gate/prereq_negative.mk.txt` | Seven existing lines; no `ship-console-test` rule. |
| `Makefile:1337` | `ship-console-test: import`, without `ship-baseline`. |
| `tools/ship_baseline.sh:28` | `curl -fsS --retry 3`, without connect, attempt or retry-window bounds. |
| `Makefile:45–49` | `make deps` invokes `git checkout` on both lockfiles; the executor must not run this setup. |
| Existing sprint JSON | **26** features; B3 is implemented with `passes: true`. Preserve all 26 and every other top-level key, including historical status/pin/order fields. Append B4 as feature 27. |
| Available convention source | No `sprint-planner` skill exists inside this repo. Use the user-supplied B3 sprint and B3 JSON feature as the exact structural precedents; do not search outside the repo. |

The design's controller-measured diff applies to **`05e64cd1`**, not a newly inferred base. Its recorded revision-1 sha256 is `cdfaa8ffbf6ba33dcd2f536f1af4e11583aa6f005be388337e9fef43bc486f6c`. That historical reference is optional; all AC inputs needed in a fresh clone are in Appendix A1–A5. No `/tmp/iter72_designer/` file is an execution dependency. B3's 91/100 independent evaluation and its surviving dropped-pair mutant explain M1; they do not establish current runtime verdicts or velocity.

**Findings to preserve.** The design prescribes `make deps` and suggests `git apply`; those execution instructions conflict with the executor's no-git-writes contract. Dependency setup belongs to the controller, and the executor implements by ordinary file edits. Do not change the setup target, bypass its checks, or invoke git patch application. D5's bound wording and D3's eager-conjunct behavior have explicit decisions in M1/M2 and the risk section below. No unresolved implementation contradiction was found beyond these documented execution constraints.

## Execution, sandbox and snapshot contract

The executor makes **NO git writes**, including scratch repositories: no add, commit, stash, checkout, reset, push, index changes or git patch application. Read-only inspection is allowed. The controller builds **one commit per milestone** from snapshots. Do not run commands that hide a git write in a prerequisite or setup recipe; in particular, leave `make deps` to the controller. If required dependencies are absent, record setup pending rather than bypassing the lock check or selecting another AILANG version.

**Every Godot or make gate run inside the executor sandbox is UNINFORMATIVE UNDER SANDBOX**, regardless of its return code. Preserve the exact command, output, true rc and reason; never label those runs RED/GREEN acceptance verdicts. The controller reruns them outside the sandbox, including import, direct summary probes, mutants, the inherited process/orphan controls and the stalled-server check. Socket denial, `user://` errors, process-list restrictions and host load must not cause weakened predicates, alternate user-data paths, increased deadlines or deleted controls.

After **each** milestone, snapshot **every changed file cumulatively** under **`.godot/tmp/snap/M1/` through `.godot/tmp/snap/M6/`**, preserving repository-relative paths. Include this plan, the sprint JSON and the design artifact already on the branch. M4–M6 retain all implementation content even when they add no implementation lines. Each directory contains `FILES.txt` and `RESULT.txt`: copied paths, before/after evidence, exact commands, full log locations, true statuses, AC disposition and sandbox limitations. Build manifests outside the copy set to avoid recursion. Restore mutants and baseline caches before snapshots; do not copy ignored generated assets as implementation changes. The controller compares consecutive snapshots to form commits; evidence-only milestones can update the new feature's progress notes.

The first **26 features and every other JSON key remain untouched**. Execution progress belongs only in the appended feature's notes/status. Start with `passes: false`, `status: planned`; keep passes false until external gates and independent evaluation are complete. Do not repair older feature metadata as part of this sprint.

Controller setup, outside the sandbox: stage `make runtime` if necessary, `export PATH="$PWD/runtime/bin:$PATH"`, verify AILANG **v0.56.1** and Godot **4.7.2**, then run the design's `make deps import starmap-assets planet-assets sky-assets`. `make deps` is controller-only because it restores lockfiles through git. Keep public fetches and hashes intact. Clear `AI_LIVE`, `GOOGLE_API_KEY`, `OPENROUTER_API_KEY`, `OPENAI_API_KEY`, `GEMINI_AGENTS_API_KEY`, `OLLAMA_API_KEY`, `ZAI_API_KEY` and `ANTHROPIC_API_KEY` for runtime measurement. No API key is needed. Record and remove only the five known ignored `.translation` outputs from import; preserve unrelated files.

Run targets serially. Save unfiltered logs and actual originating make status before filtered catalogue views; `tail`, `grep` and `wc` do not prove make succeeded. A zero-match `grep -c` prints 0 and exits 1, which is expected in rejection/count controls. AC5 runs asynchronously with an rc file and bounded polling; check for completion at intervals no longer than 60 seconds. Do not launch full `make test` or `make golden`: targeted gates, the PR fast tier and main's nightly `rig/full` follow CLAUDE.md.

## Scope guard and deferred B4b

The implementation allowlist is exactly **24 files**: `Makefile`, `mk/script-gates.mk`, `tools/script-gate-baseline.txt`, `tools/ship_baseline.sh`, the 19 scripts named in M2, and `tests/fixtures/script_gate/prereq_negative.mk.txt`. The design, this plan and the appended JSON feature are the permitted planning artifacts under AC12. No new implementation file, `.uid` or package is needed.

**No Makefile hunk may start before line 1080 at `05e64cd1`.** Preserve `mk/sound.mk`, `mk/m45.mk`, `mk/deck-layout.mk`, `mk/earth-link.mk`, `tools/script_gate.sh`, `tools/test_script_gate.sh`, `tools/script_gate_lint.sh`, `tools/script_gate_prereqs.sh` and `tools/m4_ship_golden.gd`. Preserve every assertion, threshold, `.PHONY`, aggregate join, tracked asset and existing `.uid`. The sole non-recipe Makefile edit is `ship-console-test: import ship-baseline`; keep its help text. The curl edit is exactly +3/−1 including its two-line comment.

All **30 B4b rows in 29 targets** remain unchanged and on the baseline. D9 is the authoritative per-row blocker table: 27 windowed rows, two authoring rows (`ship-demo-sky-states`, `camera-forward-targets`) that write tracked files, and base-red `sim-pipeline-test`. Do not migrate or invoke them here. `loading-profile` owns two rows. The seven windowed red/timeout measurements remain UNATTRIBUTED under load; this sprint supplies no gameplay fix or GPU verdict.

D8's **14 gated orphans**, including newly gated `frame-check-test`, stay documented without aggregate edits. B4b has 28 orphan targets; only `true-light-golden` belongs to `golden`. Record OQ1's pipelining defect and OQ2/OQ5's future aggregate/completeness lint as deferred findings; no new charter edit, issue or external message is part of this sprint. OQ3 keeps the arcade flags, and OQ4 leaves the helper's headless parse-error wording unchanged. The controller checks open PR overlaps with `gh` at pickup; V16/V22's PR list is historical, not a current observation.

## Sequence and registry reuse

**M1 → M2 → M3 → M4 → M5 → M6.** Kill the dropped-pair survivor and bound the new prerequisite first. Add counted summaries before migrating their recipes. M3 migrates all 56 baseline rows, deletes those exact rows and lowers the pin atomically, so there is no partially migrated ratchet snapshot. M1/M2 retain **238/63/175** with **four** prerequisite pairs; M3 onward requires **239/120/119**, again with four pairs. Counts come from the design and must be checked by the controller.

M2's new summaries intentionally make some old exact-summary predicates incompatible until M3. Check those scripts directly through the landed helper with D2's future EREs, preserve that expected transition, and do not add temporary recipe changes. M3 reuses M2's logs to avoid rerunning long scripts solely to repeat summary evidence.

**Registry reuse:** `none` for M1–M6. This is repository-specific Make/shell maintenance and summary counting in existing GDScript, with no new package-like capability or `.ail` code. No registry search, new demo or AILANG syntax gate applies. Reuse the landed helper, lint, prerequisite checker and unchanged 18/24-case harness; Appendix A1–A5 and the fixture/mutants provide runnable controls.

## Milestones (test-first)

### M1 — Prerequisite count pin, fourth pair and bounded baseline fetch

**Files/estimate:** `mk/script-gates.mk` list/pin/lint allocation **8** lines; `tests/fixtures/script_gate/prereq_negative.mk.txt` +3/−1 (**4**); `tools/ship_baseline.sh` +3/−1 (**4**); `Makefile` prerequisite +1/−1 (**2**). **18 hand-written changed lines, 15 min.** Dependency: landed B3. Keep the baseline pin at 175.

1. **RED first (controller outside sandbox):** reproduce the survivor by dropping `planets-test:planet-assets` from the old list; old lint wrongly accepts the two remaining pairs. Restore byte-for-byte. Read the unbounded curl line; reproduce the stalled-server defect only under a scratch supervisor with a 150 s deadline, as V22, so a known unbounded command cannot hang the sprint. AC4's pre-edit substitution is a no-op because the prerequisite is absent: record that absence instead of claiming the mutant already failed.
2. Implement D5/D6: add `ship-console-test: import ship-baseline`, the fourth `SG_PREREQS` pair, `SG_PREREQS_PAIRS := 4`, and the exact total-and-distinct-word check before the real prerequisite check. Update the fixture so it still produces exactly the original two named diagnostics; preserve its merged-rule control. Replace only curl's one line with `--connect-timeout 10 --max-time 60 --retry 2 --retry-max-time 120`, plus D5's two-line comment. Keep SHA validation and first-error exit.
3. **GREEN gates:** `make script-gate-lint` (interim **238/63/175**, four pairs); **AC3** dropped-pair and pin-5 refusals; **AC4** removed-prerequisite refusal. Also run D6's A–E controls: drop the new pair, drop the planets pair, duplicate-pad a pair, set pin 5, set pin 3; each must return make rc 2, with restored controls afterward. `gmake --no-print-directory script-gate-lint` repeats portability where installed.
4. Run **AC14**, including real baseline restoration, in a uniquely backed-up cache context. Expect stalled fetch make rc 2, curl timeouts, no test start and unchanged test-log mtime. Track the server PID and clean it up; a denied sandbox bind is uninformative. The real fetch must remain SHA-identical. AC10's final gate summary waits for M4.

**Explicit decision (kimi r2):** D5 bounds curl at ≤183 s/file and ≤549 s/three-file fetch; the Godot gate is separately ≤600 s. The existing `import` prerequisite has no deadline. Therefore **no finite whole-target bound is asserted**. AC14's roughly 125 s is measured evidence, not a guarantee about import.

**Milestone ACs:** AC3, AC4, AC14; interim AC1. **Stop/report:** extra fixture diagnostics, a surviving drop/pad mutant, checksum change, un-restored mutant/cache, or need to change the protected checker. Snapshot M1; controller creates milestone commit 1.

### M2 — Nineteen counted summaries with unchanged assertions

**Files/estimate:** `tools/validate_ship_demo.gd`, `tools/validate_ship_commons.gd`, `tools/news_lint.gd`; `tests/test_ship_commons_assets.gd`, `tests/test_runtime_fingerprint.gd`, `tests/test_live_journey.gd`, `tests/test_ship_demo_live.gd`, `tests/test_ship_demo_assets.gd`, `tests/test_ship_demo_benchmark.gd`, `tests/test_ship_demo_launch.gd`, `tests/test_ring_protocol.gd`, `tests/test_ship_attitude.gd`, `tests/test_benchmark_upload.gd`, `tests/test_shadow_contacts.gd`, `tests/test_tour_attitude.gd`, `tests/test_tour_pacing.gd`, `tests/test_destination_pin.gd`, `tests/test_cruise_interlude.gd`, `tests/test_frame_check.gd`. Exactly **19 files, +62/−35 = 97 changed lines, 20 min.** Depends on M1.

1. **RED first:** extract Appendix inputs with the catalogue's `x` helper. Before each edit, run its original D2 Godot command directly through `sh tools/script_gate.sh` with that row's future summary ERE, log and deadline. The old uncounted/missing summary must be refused. Preserve original emitted check lines for independent counting; a shell-only zero regex test alone does not establish this RED. Controller verdicts only.
2. Apply D3's **15** `check()` counting edits, the inline asset-check count, the two single-verdict conjunct counts and the news tier/template totals. Add the three formerly absent summaries immediately before existing quits. Keep all assertions, failure-path quits and launch's `pid>0 and not OS.is_process_running(pid)` guard. Do not confuse the 15 pattern-1 files with the 19-script total.
3. **GREEN gates:** rerun each direct helper probe using the exact command tokens from D2/current recipe. For example: `sh tools/script_gate.sh b4-m2-demo .godot/tmp/b4/m2-demo.log 600 '^validate-ship-demo: OK \([1-9][0-9]* passed, 0 failures\)$' -- godot --headless --path . --script tools/validate_ship_demo.gd`. The same form with `$(GODOT_SIM)` expanded as in Makefile preserves AILANG for live scripts; never replace a sim invocation with plain Godot.
4. Compare same-run passed counts with emitted `ok` checks: validate demo **24**, commons assets **16**, validate commons **25**, fingerprint **6**, live journey **17**, demo live **9**, ring protocol **9**, attitude **6**, upload **12**, shadow **10**, tour attitude **18**, pacing **15**, destination pin **23**, cruise interlude **36**, frame check **6**. Independently verify demo assets **13 = 7+1+5**, benchmark **3**, launch **4** and news **5 tiers/20 templates** with source/manifest/news JSON. Run **AC9**'s zero/real controls now; defer its Makefile-presence component until M3. These counted-summary components contribute to AC5.

**Explicit decision (gemini r2):** retain D3's eager `conds` arrays in both benchmark and launch, with no optional extra guards in this batch, to match the measured diff exactly. A later conjunct may raise `SCRIPT ERROR` on a failure path (including a `main.sim.world` read after startup failure); the helper refuses it, so this **fails closed**. Keep passing summaries at 3/4 checks. Optional guarding was permitted by the controller, but is not needed for this implementation; do not broaden assertions or interpret the error as success.

**Milestone ACs:** AC5 counted-summary components; AC9 regex components. **Stop/report:** lower independent counts, changed assertions, changed successful summaries or an error escaping the helper. Old exact-summary recipe failures until M3 are an expected dependency, not permission to weaken predicates. Snapshot M2; controller creates milestone commit 2.

### M3 — All 57 gate lines, reason-bound negatives and baseline ratchet

**Files/estimate:** remaining `Makefile` recipe diff **124** lines; `mk/script-gates.mk` final pin/comment allocation **4** lines; `tools/script-gate-baseline.txt` **56 deletions**. **128 hand-written changed lines plus 56 baseline deletions = 184 changed lines, 25 min.** Depends on M2.

1. **RED first:** capture the pre-migration inventory and A1's 48 target list; the 56 rows are still ungated. Save representative old zero-summary acceptance (`ship-demo: 0 passed, 0 failures`) and M2's old-predicate mismatches. For the controller's eventual before/after drills, use base scripts and Makefile from **`05e64cd1`**, not the planner HEAD's design commit or moving `origin/main`.
2. Replace every D2 row with its exact helper contract `NAME LOG DEADLINE SUMMARY_ERE [WANT_RC] -- original-command`. Preserve `$(GODOT)` versus `$(GODOT_SIM)`, all flags/user args and Make recipe tabs. Keep each existing log path and `news-lint`'s final echo; drop only D1's redundant tails/mkdirs. Use **600 s** normally, **1200 s playthrough**, **1800 s free-nav-stop/no-twitch**, **3000 s solar-departure**. Never replace these with a uniform deadline.
3. Bind D4's five WANT_RC-1 controls to their own reasons: commons envelope, demo tier 1, geometry tier 3, bridge needle, news stray digit. Split the geometry loop into two invocations. Positives retain nonzero counts and anchors; preserve the arcade literal flags and counted vertices. No helper changes.
4. Delete exactly A1's **56 existing baseline rows** and lower the pin/comment **175 → 119 in this milestone**. Never regenerate/grow the baseline or delete B4b rows. Cumulative baseline diff must be +0/−56. Refresh the inventory after edits; all A1 targets must be gated and none may remain on the baseline.
5. **GREEN commands:** `make script-gate-lint`; **AC1** → **239/120/119**, four pairs, rc 0; **AC2** → pin 120 refused; repeat AC3/AC4; **AC9** → 22 lines `zeroed=0 real=1`, Makefile matches 1 except shared row `1,12` matches 2. Run AC5's list check and dry run → `list-ok`, `n-rc=0`. Representative serial controller smoke gates: `make validate-ship-demo ship-commons-assets-test ship-demo-assets-test ship-demo-benchmark-test ship-demo-geometry-negative-test ship-demo-launch-test news-lint`, preserving every own gate status and true make rc; the complete sweep is M4.

**Milestone ACs:** AC1, AC2, AC9; AC5 inventory/list and smoke components. **Stop/report:** other row arithmetic, wrong Godot tokens/args, a generic negative reason, omitted count anchor, scope drift or any before-1080 hunk. Snapshot M3; controller creates milestone commit 3.

### M4 — Complete serial B4a acceptance and fresh ship baseline

**Files/estimate:** **no implementation edits, 0 LOC, 50 min** including the approximately 41-minute sweep. Only this feature's progress and ignored evidence/snapshots change. Depends on M3 and external controller runtime access.

1. **RED evidence first:** retain M1/M2/M3 base defects and pre-edit logs; do not rerun the whole 41-minute base sweep for a second copy. Verify setup, credentials unset, refreshed inventory, 48 extracted targets and absence of stale `ac5.rc` before the complete run.
2. Run the catalogue's literal **AC5** target list plus `playthrough-adversarial` serially, asynchronously with its rc file. Do not replace it with `ship-demo-ci`, which pulls in unrelated audits. Retain all output, per-gate times and rc-file completion. Require make **rc 0**, **57 distinct gate names**, every status `ok`, and **zero status-anchored FAILs**. There are **58 ok lines** because playthrough runs twice. All five expected negatives are ok with rc 1; four include `FAIL` in reason text and news does not. Use `^script-gate: [^ ]+ FAIL`, never an unqualified `grep FAIL`.
3. Run **AC10** with the baseline genuinely absent in a uniquely backed-up cache context. Require the public fetch/hash line, `ship-consoles: 135 passed, 0 failures`, helper ok, true make rc 0, and restore/reconcile the cache. Do not infer make rc from the final grep's status. Reuse AC14 evidence from M1 if the same curl/prerequisite content is unchanged; otherwise rerun AC14 outside sandbox before acceptance.

**Milestone ACs:** AC5 complete; AC10. **Stop/report:** missing rc file, wrong gate-name count, a real FAIL status, lower counts or incorrect cache prerequisite behavior. A sandbox run is uninformative even if every status is ok. Snapshot M4; controller creates milestone commit 4.

### M5 — Parse/runtime drills and inherited helper controls

**Files/estimate:** **no implementation edits, 0 LOC, 15 min**. Only this feature's progress and ignored evidence/snapshots change. Depends on M4.

1. **RED first:** preserve A2's before-migration controls from `05e64cd1`: headless parse drill **5 rc 0/54 rc 2** among 59 rows; runtime drill **6 rc 0/2 rc 2** among the eight A3 pairs. V21 supersedes V8's bogus `GODOT_SIM` scratch harness; use the embedded A2 that writes `$$`, never the old `$$$$` version. These before/after controls require external controller execution; do not invent a local RED from sandbox errors.
2. Run **AC7** using the refreshed final inventory and extracted A2: **57 rows, 57 make rc 2, 57 logs mentioning SCRIPT ERROR**. The five negative rows additionally report rc 0, want 1. Mutants live solely under `.godot/tmp/b4-drill/` and must never reach snapshots as implementation files.
3. Run **AC8** using A3: **8 rows, 8 make rc 2** when `check()` aborts, including sim-backed demo live. Retain original command/env and script selection. Then **AC6**: unchanged **18 stub cases** and **24 cases = 18 stub + 6 Godot**. Capture actual make statuses before tail views and preserve the orphan-process control unchanged.

**Milestone ACs:** AC6, AC7, AC8. **Stop/report:** surviving mutant, count mismatch or unexpected raw behavior; sandbox socket/process visibility does not establish a pass or a failure. Snapshot M5; controller creates milestone commit 5.

### M6 — Hygiene, exact scope, orphan evidence and PR fast tier

**Files/estimate:** **no implementation edits, 0 LOC, 15 min**, plus asynchronous CI and independent evaluation. Only this feature's progress and ignored evidence/snapshots change. Depends on M5.

1. **RED/scope controls first:** retain the deliberately out-of-allowlist paths and before-1080 hunk checks as executable rejection conditions; no new tracked mutation is necessary. Review the cumulative 24-file implementation diff against `05e64cd1`, not only HEAD (which already contains the design). Confirm the two r2 decisions and every restored mutant/cache in the record.
2. Run **AC11** policy gates, `shellcheck -s sh tools/ship_baseline.sh` and read-only `git diff --check`. Run **AC12** against the measured base: **0 unexpected paths, 0 early Makefile hunks, 0 protected files, and exactly +3/−1 in tools/ship_baseline.sh**. Verify the 24 implementation paths, +135/−164 final diff and +0/−56 baseline deletion separately from planning artifacts. Any drift is reported, not fixed by expanding the allowlist.
3. Extract A5 with `x 'sh b4-closure' > .godot/tmp/b4/closure.sh`; `sh .godot/tmp/b4/closure.sh Makefile test`, then `ci-fast`, then `golden`. Check D8's closure/orphan facts and record **14 gated orphans including frame-check-test**, without aggregate edits. D9's 30 B4b rows and their blockers remain deferred.
4. Controller runs **AC13** on the actual committed PR head: GitHub fast tier success plus the three exact lint/prerequisite/18-case evidence lines from that head's `pull_request` CI run. A missing/pending run is pending. Keep all prior external acceptance evidence; an independent evaluator reviews the diff and mutants. Leave passes false until these complete.

**Milestone ACs:** AC11, AC12, AC13; final confirmation AC1–AC14 and D8/D9. **Stop/report:** changed protected file, unexpected LOC/scope, red fast tier, unavailable evidence or any remaining contradiction. Snapshot M6; controller creates milestone commit 6.

## Acceptance coverage

| AC | Owner milestone | Evidence required outside sandbox |
|---|---|---|
| AC1 | M1 interim, M3 final | Final lint 239/120/119 and four exact prerequisite pairs; true rc 0. |
| AC2 | M3 | Pin 120 refused against 119 baseline rows. |
| AC3 | M1, recheck M3 | Dropped planets pair refused; count-pin overrides refused; restore verified. |
| AC4 | M1, recheck M3 | Lost ship-baseline prerequisite named and refused; restore verified. |
| AC5 | M2 counts, M3 list, M4 complete | All 48 targets plus adversarial playthrough; rc 0, 57 names, zero failed statuses. |
| AC6 | M5 | Unchanged 18/24-case self-test/drill with actual originating statuses. |
| AC7 | M5 | All 57 parse-mutant recipe lines refused with SCRIPT ERROR diagnostics. |
| AC8 | M5 | All eight skipped-check runtime mutants refused. |
| AC9 | M2 regex, M3 complete | 22 zero/real pairs, with actual recipe ERE matches and shared-row exception. |
| AC10 | M4 | Absent baseline fetched/verified before 135-pass console gate. |
| AC11 | M6 | Policy gates, shellcheck and whitespace check. |
| AC12 | M6 | Exact 24-file scope at 05e64cd1, early-hunk/protected-path zeros, curl +3/−1. |
| AC13 | M6, controller | Successful PR-head fast tier plus three evidence lines. |
| AC14 | M1, M4 confirms unchanged content | Stalled fetch fails before test start; cache/server restored; real fetch succeeds. |

## Acceptance catalogue (approved design AC1–AC14)

The catalogue below transcribes the design's commands with Markdown table pipe escaping removed. It is future executor/controller work, **not planner-run results**. Extract A1–A4 first, refresh inventory after migration, and extract A5 for M6. AC13 resolves actual PR/run IDs. AC8's optional base comparison must read `05e64cd1`; do not use a moving base. Keep true make statuses alongside the design's filtered views. AC3/AC4 require restore traps and byte comparisons even if a command aborts. For AC10/AC14, the literal fixed aside path must be absent before moving the cache; use separate unique backups and a restore trap for repeated checks, and never mistake a move into an existing directory for an absent-cache test. AC14's server must be tracked and stopped at completion.

````sh
x() { awk -v t="$1" '$0 == "```" t {f=1; next} f && $0 == "```" {exit} f' design_docs/planned/r1/m4-7x-b4-script-gates.md; }
mkdir -p .godot/tmp/b4
x 'text b4a-targets' > .godot/tmp/b4/targets.txt
x 'sh b4-drill' > .godot/tmp/b4/drill.sh
x 'text b4-rt-pairs' > .godot/tmp/b4/rt-pairs.txt
x 'text b4-zero-pairs' > .godot/tmp/b4/zero-pairs.txt
make --no-print-directory script-gate-inventory > .godot/tmp/b4/inv.tsv
````

Expected input lengths: **48 targets, 41 harness lines, 8 runtime pairs, 22 zero pairs**. The harness and inputs are scratch extractions, not new implementation files.

### AC1

```sh
make script-gate-lint; echo rc=$?
```

Expected: script-gate-lint: ok (239 --script invocations: 120 through $(SCRIPT_GATE), 119 on the baseline; 22 includes, all in mk/*.mk; 23 makefiles scanned); script-gate-prereqs: ok (4 pairs hold in Makefile: constellation-test:starmap-assets planets-test:planet-assets planet-textures-check:planet-assets ship-console-test:ship-baseline); rc=0 (V11)

### AC2

```sh
make script-gate-lint SCRIPT_GATE_BASELINE_ROWS=120 2>&1 | grep 'the baseline has'
```

Expected: script-gate-lint: the baseline has 119 rows but SCRIPT_GATE_BASELINE_ROWS is 120: the pin moves with the rows, and only down (V11)

### AC3

```sh
cp mk/script-gates.mk .godot/tmp/b4-sg.keep; perl -pi -e 's/ planets-test:planet-assets / /' mk/script-gates.mk; make script-gate-lint > .godot/tmp/b4-ac3.out 2>&1; echo rc=$?; grep '^script-gate-lint: SG_' .godot/tmp/b4-ac3.out; cp .godot/tmp/b4-sg.keep mk/script-gates.mk; make script-gate-lint SG_PREREQS_PAIRS=5 2>&1 | grep -c '^script-gate-lint: SG_PREREQS holds 4 pairs (4 distinct) but SG_PREREQS_PAIRS is 5'
```

Expected: rc=2, script-gate-lint: SG_PREREQS holds 3 pairs (3 distinct) but SG_PREREQS_PAIRS is 4: the pin moves with the pairs, and only up, then 1 (V13)

### AC4

```sh
cp Makefile .godot/tmp/b4-mf.keep; perl -pi -e 's/^ship-console-test: import ship-baseline ##/ship-console-test: import ##/' Makefile; make script-gate-lint > .godot/tmp/b4-ac4.out 2>&1; echo rc=$?; grep '^script-gate-prereqs:' .godot/tmp/b4-ac4.out; cp .godot/tmp/b4-mf.keep Makefile
```

Expected: rc=2, script-gate-prereqs: ship-console-test lost its prerequisite ship-baseline (ship-console-test: import) (V13)

### AC5

```sh
T=.godot/tmp/b4; awk -F'\t' '{split($1,a,":"); if (a[1]=="Makefile" && a[2]+0>=1080 && $4=="gated") print $2}' $T/inv.tsv | sort -u > $T/g.txt; sort -u $T/targets.txt | diff - $T/g.txt && echo list-ok; make -n $(cat $T/targets.txt) playthrough-adversarial > /dev/null; echo n-rc=$?
# Remove a stale rc file before launch; retain the real make rc.
rm -f "$T/ac5.rc"
( env -u AI_LIVE -u GOOGLE_API_KEY -u OPENROUTER_API_KEY -u OPENAI_API_KEY make $(cat $T/targets.txt) playthrough-adversarial > $T/ac5.out 2>&1; echo $? > $T/ac5.rc ) &
B4_AC5_PID=$!
# Bounded polling: at most 120 minutes, checking every 30 seconds.
B4_AC5_POLL=0
while [ ! -f "$T/ac5.rc" ] && [ "$B4_AC5_POLL" -lt 240 ]; do sleep 30; B4_AC5_POLL=$((B4_AC5_POLL+1)); done
# On exhaustion record pending and let the controller supervise; do not claim success.
if [ -f "$T/ac5.rc" ]; then
  cat $T/ac5.rc; grep '^script-gate:' $T/ac5.out | sort -u -t: -k2,2 | wc -l; grep -cE '^script-gate: [^ ]+ FAIL' $T/ac5.out
else
  echo "AC5 pending: no rc file for process $B4_AC5_PID"
fi
```

Expected: list-ok, n-rc=0 (V21); then 0; 57; 0. Each line is ok with D2's "After" summary, for example ship-demo: 244 passed, validate-ship-demo: OK (24 passed, 0 failures), live-journey: 17 passed, the five negatives ok:   FAIL … / ok: news-lint: tier 0 template 1: … with rc 1, news-lint: ok (5 tiers, 20 templates), and solar-departure: 134 passed under its 3,000 s deadline (V9)

### AC6

```sh
make script-gate-selftest 2>&1 | tail -1; make script-gate-drill 2>&1 | tail -1
```

Expected: test-script-gate: ok (18 cases: 18 stub, 0 Godot), test-script-gate: ok (24 cases: 18 stub, 6 Godot) (V12)

### AC7

```sh
T=.godot/tmp/b4; awk -F'\t' 'FNR==NR{d[$1]=1;next} {split($1,a,":"); if (a[1]=="Makefile" && ($2 in d)) print $1, $2, $3}' $T/targets.txt $T/inv.tsv > $T/rows.txt; wc -l < $T/rows.txt; sh $T/drill.sh ac7 parse $T/rows.txt; grep -h 'script-gate: .* FAIL' .godot/tmp/b4-drill/ac7/drill-*.out | grep -c 'SCRIPT ERROR line(s)'
```

Expected: 57; 57 rc=2; 57. The 5 negatives also say rc 0, want 1 (V21; at base the same harness gives 5 rc=0 among the 59 headless rows, V7)

### AC8

```sh
T=.godot/tmp/b4; awk -F'\t' 'FNR==NR{k[$0]=1;next} {split($1,a,":"); if (a[1]=="Makefile" && (($2" "$3) in k)) print $1, $2, $3}' $T/rt-pairs.txt $T/inv.tsv > $T/rt-rows.txt; wc -l < $T/rt-rows.txt; sh $T/drill.sh ac8 rt $T/rt-rows.txt
```

Expected: 8; 8 rc=2 (V21). At base, 6 rc=0 and 2 rc=2: ship-demo-test passes with ship-demo: 0 passed, 0 failures, and flyby-optics-test with 0 checks, 0 failures (V21, which supersedes V8)

### AC9

```sh
while IFS='|' read -r row ere zero real; do mk=$(printf '%s' "$ere" | sed 's/\$$/$$/'); printf '%s zeroed=%s real=%s makefile=%s\n' "$row" "$(printf '%s\n' "$zero" | grep -cE -- "$ere")" "$(printf '%s\n' "$real" | grep -cE -- "$ere")" "$(grep -cF -- "'$mk'" Makefile)"; done < .godot/tmp/b4/zero-pairs.txt
```

Expected: 22 lines, each zeroed=0 real=1 and makefile=1, except 1,12 … makefile=2 (rows 1 and 12 share their ERE) (V21)

### AC10

```sh
mv build/ship-baseline .godot/tmp/b4-sb.aside 2>/dev/null; make ship-console-test 2>&1 | grep -E '^ship-baseline:|^script-gate:'; echo rc=$?
```

Expected: ship-baseline: build/ship-baseline matches art/deck-layout-v2/baseline.sha256, script-gate: ship-console-test ok: ship-consoles: 135 passed, 0 failures (…), rc=0 (V12; about 2 min)

### AC11

```sh
make uid-guard python-guard audio-silent-guard lint-precision && git diff --check origin/main && shellcheck -s sh tools/ship_baseline.sh && echo gates-ok
```

Expected: uid-guard: ok (406 .uid files), python-guard: ok (21 allowlisted, 0 awaiting AILANG port), audio-silent-guard: ok (79 windowed godot invocations; 5 allowlisted to keep sound), lint-precision: ok …, gates-ok (V23). No new .gd, .sh or .py file

### AC12

```sh
git diff --name-only origin/main | grep -cvxE 'Makefile|mk/script-gates\.mk|tools/(script-gate-baseline\.txt|validate_ship_demo\.gd|validate_ship_commons\.gd|news_lint\.gd|ship_baseline\.sh)|tests/test_(ship_commons_assets|runtime_fingerprint|live_journey|ship_demo_live|ship_demo_assets|ship_demo_benchmark|ship_demo_launch|ring_protocol|ship_attitude|benchmark_upload|shadow_contacts|tour_attitude|tour_pacing|destination_pin|cruise_interlude|frame_check)\.gd|tests/fixtures/script_gate/prereq_negative\.mk\.txt|design_docs/planned/r1/m4-7x-b4-script-gates.*\.md|\.ailang/state/sprints/sprint_R1-M4-JOURNEY\.json'; git diff -U0 origin/main -- Makefile | grep '^@@' | awk '{split($2,a,","); if (substr(a[1],2)+0 < 1080) n++} END{print n+0}'; git diff --name-only origin/main -- mk/sound.mk mk/m45.mk mk/deck-layout.mk mk/earth-link.mk tools/script_gate.sh tools/test_script_gate.sh tools/script_gate_lint.sh tools/script_gate_prereqs.sh | wc -l; git diff --numstat origin/main -- tools/ship_baseline.sh
```

Expected: 0, 0 (no Makefile hunk starts before line 1080), 0, 3	1	tools/ship_baseline.sh (V24)

### AC13

```sh
B4_PR=$(gh pr view --json number --jq '.number') || exit 1
B4_HEAD=$(gh pr view "$B4_PR" --json headRefOid --jq '.headRefOid') || exit 1
gh pr checks "$B4_PR" || exit 1
B4_RUN=$(gh run list --workflow ci.yml --event pull_request --commit "$B4_HEAD" --limit 1 --json databaseId --jq '.[0].databaseId') || exit 1
test -n "$B4_RUN" && test "$B4_RUN" != null || exit 1
gh run view "$B4_RUN" --log > .godot/tmp/b4/ac13.log || exit 1
grep -cE 'script-gate-lint: ok \(239 --script invocations: 120 through|script-gate-prereqs: ok \(4 pairs hold in Makefile|test-script-gate: ok \(18 cases: 18 stub, 0 Godot\)' .godot/tmp/b4/ac13.log
```

Expected: success; 3. GNU make 4.4.1 (gmake) already gives AC1's two lines locally (V11)

### AC14

```sh
perl -MIO::Socket::INET -e '$s=IO::Socket::INET->new(LocalAddr=>"127.0.0.1",LocalPort=>18731,Listen=>16,ReuseAddr=>1) or die; alarm 900; push @k, $c while $c=$s->accept' &
B4_STALL_PID=$!
trap 'kill "$B4_STALL_PID" 2>/dev/null || true' EXIT HUP INT TERM
mv build/ship-baseline .godot/tmp/b4-sb.aside 2>/dev/null; s=$(date +%s); SHIP_BASE_URL=http://127.0.0.1:18731 make ship-console-test > .godot/tmp/b4/ac14.out 2>&1; echo "rc=$? $(( $(date +%s)-s ))s"; grep -cE '^curl: \(28\)' .godot/tmp/b4/ac14.out; grep -E '^ship-baseline: FAIL|^make: \*\*\*' .godot/tmp/b4/ac14.out; grep -c '^script-gate:' .godot/tmp/b4/ac14.out; make ship-baseline | tail -1
kill "$B4_STALL_PID" 2>/dev/null || true
wait "$B4_STALL_PID" 2>/dev/null || true
trap - EXIT HUP INT TERM
```

Expected: rc=2 in about 125 s (≤ 549 s plus import by D5's bound); 2 (two 60 s attempts, then the 120 s retry window closes); ship-baseline: FAIL fetch ship.glb (9da7…) and make: *** [ship-baseline] Error 1; 0 (Godot's test never started); then ship-baseline: build/ship-baseline matches art/deck-layout-v2/baseline.sha256 (V22)

AC5 uses the r2 status-anchored FAIL form; its background launch/polling is the design's required execution arrangement. AC13 resolves the real PR and run. AC14 adds server-process cleanup to the transcribed command. All filtered checks still require the separately retained originating status. AC14's literal aside move is safe only after the cache backup preconditions above; the trap for the server does not replace the required cache restore trap.

## Risks and mitigations

| Risk or contradiction | Decision / mitigation |
|---|---|
| Design setup says `make deps`, which runs `git checkout`; the deliverables also suggest `git apply`. Both conflict with the executor's no-git-writes instruction. | **Operational instruction conflict, reported rather than silently followed.** Controller performs dependency setup; executor uses file edits and snapshots. No setup-target or lockfile change is authorized. The measured diff base remains `05e64cd1`. |
| D5 calls `import + ≤549 s fetch + ≤600 s gate` a worst case although import has no deadline (kimi r2). | **Explicit M1 decision:** bound only the fetch and Godot terms. No complete target deadline is claimed; do not modify import or widen the curl edit. AC14's wall time is historical evidence. |
| Eager `conds` arrays can raise SCRIPT ERROR on a failure path (gemini r2). | **Explicit M2 decision:** retain the measured arrays and existing launch guard. The helper fails closed on any SCRIPT ERROR. Optional additional guards are not included; passing summaries remain 3/4. |
| Four successful negative reasons contain the word FAIL; an unqualified grep would misreport four failures. | Use `^script-gate: [^ ]+ FAIL` for statuses. AC5 requires zero failed statuses, 57 distinct names and five expected rc-1 negative ok statuses, not zero occurrences of the word FAIL. |
| Godot/make/socket/process results in sandbox are misleading, including apparently green stub aggregates. | Every sandbox Godot/make gate is **UNINFORMATIVE UNDER SANDBOX**. Controller reruns outside; keep actual logs/statuses without verdicts or weakened controls. |
| Long targets and host load dominate runtime. | Preserve D1's 600/1200/1800/3000 s deadlines. Run serially; AC5 background rc-file polling is bounded and progress remains visible. A missing rc file is pending, not success. |
| A slow link may exceed curl's new 60 s attempt limit. | Preserve SHA checks and loud failure; use the existing public mirror override only for the controlled AC14 probe. No retries or bounds beyond D5 are added. |
| Reusing AC10/AC14's fixed aside path can move the cache into an existing directory and invalidate the fresh-cache premise. | Require an absent fixed aside path, keep unique backups per run and restore on exit. Verify the cache is absent before each fetch probe; preserve test-log mtime evidence for failure-before-start. |
| M2 summaries temporarily disagree with old predicates. | Use direct helper probes, keep that expected intermediate failure in evidence, and migrate recipes plus baseline/pin together in M3. No temporary relaxation. |
| SG_PREREQS count pin does not prove semantic completeness. | Kill drop/duplicate/pin mutants; retain OQ5's same-count swap residual. A derived-list lint remains a later batch. |
| Orphan targets can rot, and sim-pipeline-test is base-red. | Record D8's 14 gated orphans and D9's blockers. No aggregate join, behavioral fix, B4b migration or new charter row is part of this sprint. |
| The measured base differs from a future branch/rebase. | Check `05e64cd1` explicitly, preserve the 24-file allowlist and AC12 hunk boundary. Report drift/contradictions rather than inventing new counts or expanding scope. No unresolved implementation contradiction was found. |
| The sprint-planner skill is not present within the permitted search boundary. | Use the supplied B3 plan structure and B3 feature schema; no outside-repo search or invented skill requirement. |

## LOC footer

| Final implementation allocation | Added | Deleted | Changed lines |
|---|---:|---:|---:|
| `Makefile` (M1 prerequisite; M3 recipes) | 58 | 68 | 126 |
| `mk/script-gates.mk` (M1 list/guard; M3 baseline pin/comment) | 9 | 3 | 12 |
| `tests/fixtures/script_gate/prereq_negative.mk.txt` (M1) | 3 | 1 | 4 |
| `tools/ship_baseline.sh` (M1) | 3 | 1 | 4 |
| Nineteen existing summary scripts (M2) | 62 | 35 | 97 |
| `tools/script-gate-baseline.txt` (M3) | 0 | 56 | 56 |
| **Total: 24 implementation files** | **135** | **164** | **299** |

**Hand-written changed LOC: 243; baseline-only deletions: 56.** Milestones: **M1 18, M2 97, M3 184 including baseline deletions, M4 0, M5 0, M6 0**. Each is under 250 changed LOC. The 140-minute estimate excludes asynchronous CI/controller/evaluator scheduling. Planning artifacts and ignored harness/snapshot outputs are excluded from the implementation LOC, matching V24. No implementation files were edited by the planner and no runtime verdict is claimed.
