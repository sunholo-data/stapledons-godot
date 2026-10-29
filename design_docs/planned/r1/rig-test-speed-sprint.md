# Sprint plan: L4 test-suite speed

**Sprint:** R1-RIG-TEST-SPEED · **Iteration:** 56 · **Release:** r1 · **Created:** 2026-10-29.
**Design authority:** [rig-test-speed.md](rig-test-speed.md), including both quorum rounds and their controller-applied refinements. Approved for planning.
**Base commit:** `c2e70e15bd28955cd9aac01b67ec6b458862f681`. Planning checkout HEAD is `817f4ba69585d205f08a94133416c8d51819d3de`; the intervening commits change the design only. Source baseline is unchanged. No tool is implemented by this plan.

## Summary and authorization

Measure the suite before changing execution, then parallelize with coverage proved on every run, and finally declare real edges and shard the sim tests. The instrument must work on system make 3.81 and GNU Make 4.4.1. All performance comparisons use GNU Make 4.4.1 on both sides.

**Controller decision: split M1 now, regardless of its final LOC.** The charter stops the unattended loop at a design's Open questions. OQ2 governs design 1d's use of `--make gmake` on the rig; OQ1/OQ4 govern M2. Only M1a proceeds: Mark's **D-126 C** orders L4, and **D-88** permits test/tooling hygiene inside an approved item with no negative pillar. None of OQ1–OQ4 touches M1a. This is no resolution of the questions by the planner.

The controller will file **D-129**, covering OQ1–OQ4 with the design's defaults: parallel rig default 6 subject to measurement; gmake on the rig; keep every duplicate; missing gmake fails after M2 unless `RIG_JOBS=1`. Defaults are proposals, not authorization. M1b's resume predicate is **D-129 RESOLVED**; M2 additionally needs M1b's accepted baseline; M3 additionally needs the held-file predicate and M2's evidence. If the resolved answer changes the defaults, re-plan the affected commands before execution. Do not edit the ledger in this sprint.

| ID | Deliverable | Estimated LOC | Status | Blocker / dependency |
|---|---|---:|---|---|
| M1a | Instrument, fixture control, one existing-control case | 248 | in_progress (authorized, code not started) | None; D-126 C + D-88 |
| M1b | Rig profile path, fallback cases, serial baseline data | 49 + data/report | blocked | **D-129 RESOLVED**; M1a accepted |
| M2 | Parallel setup/P1/P2 runner, lanes, after data | 255 + data/report | blocked | **D-129 RESOLVED**; M1b baseline accepted |
| M3 | Real edges, stamped import, sim shards | 144 + data/report | blocked | **D-129 RESOLVED**; M2 accepted; AC14 held-file predicate |

**Capacity:** 696 changed source/control/changelog lines, plus generated evidence. M1a ≤ approximately 250 LOC. This expands the design's ≈630 for the sampler/report refinements, control budget, per-milestone changelog, and M3 guard tests. Estimates are budgets, not permission to omit a check or compress unreadable code; an M1a overrun returns to the controller for a smaller split.

## Baseline and cheap verification

Observed 2026-10-29 on the pristine planning checkout, before either output was written:

| Command (repo root) | Observed base result | Interpretation |
|---|---|---|
| `env -u RIG_TEST_S -u RIG_GOLDEN_S sh tools/test_rig_check.sh tools/rig_check.sh` | rc 0; all 8 named cases ok; `rig-check control: 8 cases, 0 failures` | GREEN |
| `sh -n tools/timed_recipe_shell.sh` | rc 127, No such file or directory | Already RED: new file absent |
| `sh -n tools/suite_profile.sh` | rc 127, No such file or directory | Already RED: new file absent |
| `sh -n tools/test_suite_profile.sh` | rc 127, No such file or directory | Already RED: new file absent |
| `make python-guard` | rc 0; `python-guard: ok (20 allowlisted, 0 awaiting AILANG port)` | GREEN |
| `make uid-guard` | rc 0; `uid-guard: ok (352 .uid files)` | GREEN |

`git status --short` was empty. `/usr/bin/make --version` is GNU Make 3.81; `/opt/homebrew/bin/gmake --version` is GNU Make 4.4.1. `make -n rig-check-control` prints exactly `sh tools/test_rig_check.sh tools/rig_check.sh`. Safe `gmake -pq --eval='__nop__:' __nop__` parsing confirms one direct `test` → `rig-check-control` edge. `mk/m45.mk:54-57` already supplies it. Held files have no diff against the stated base. These are the only design premises rechecked; V1–V44 remain the timing/audit premises.

Recent velocity: iteration 55 delivered 17 changed watchdog/control lines, estimated 45–60 minutes, with an independent 95/100 evaluation; its rig run took 117 minutes after a load-related failed attempt. That small change is not a credible general LOC/day rate. Budget M1a 2 focused 60–90-minute sessions, M1b one such coding session plus ≥4 controller rig runs, M2 2 sessions plus ≥4 rig runs, M3 2 sessions plus re-baselining and performance runs. Roughly 4–5 active engineering days after all holds clear; decision and rig queues have no promised calendar date.

## Execution contract and scope

The executor writes code and evidence but **never commits**, stages, checks out, stashes, merges, or performs another git write operation. The controller commits and re-runs **every gate outside the sandbox**. A verdict obtained inside a sandbox by a gate touching **sockets/GPU/launchctl** must be labelled **UNINFORMATIVE UNDER SANDBOX**; it cannot certify a pass or a product regression. Fixture shell controls do not use these facilities. No planner `make test`, `make -j`, long target, `make -p`, or unsafe bare `make -qp` is authorized. Full-suite and real rig commands below are controller-only, after the relevant blocker clears.

**Never touch in M1a/M1b/M2:** `Makefile`, `mk/m45.mk`, `mk/earth-link.mk`, `tools/import_keep.txt`, `tools/python-allowlist.txt`, `tools/python_guard.sh` (attended PRs #344/#346). M1a also makes **zero changes to `tools/rig_check.sh`**. M1a wiring is precisely one new `suite-profile` case in `tools/test_rig_check.sh`, invoking `sh tools/test_suite_profile.sh`; it is reached through the existing `rig-check-control` target. Update its counted trailer and nested caller-poison count to 9 outer / 8 nested. Retain all original 8 cases and their assertions. Do not add a make target or edit make wiring. M1b adds only design 1d/1e rig cases later.

No Python additions or new pipeline steps. Shell + awk + Perl timing only. No game, physics, shader or `.ail` source change; AILANG syntax gate is inapplicable. No new `.gd`/shader, hence no `.uid` companion. Changelog entries go in this repo's `CHANGELOG.md`. The sprint JSON's notes hold RED/GREEN/drill evidence; `passes:false` stays false until the controller certifies each milestone. Only the controller clears blockers and advances status. Independent evaluator ≠ executor, ≥70/100 and zero blocking findings before landing. Landing retains CLAUDE.md gate 1 (rig/full and fast tier), moves completed docs/report/data coherently, updates roadmap/changelog; blocked work stays planned.

Registry reuse: **none for M1a, M1b, M2, M3**. These are repository-specific make/SHELL orchestration and test fixtures, not package-like capabilities. No package logic or dependency is introduced; `ailang pkg search/info/docs` are inapplicable, so no registry/cache-writing query is run. Existing AILANG v0.54.18 remains pinned. Fixture makefiles are the runnable examples for every new shell capability.

## M1a — instrument only (test-first)

**Files / LOC:** `tools/timed_recipe_shell.sh` new 28; `tools/suite_profile.sh` new 125; `tools/test_suite_profile.sh` new 86; `tools/test_rig_check.sh` +5; `CHANGELOG.md` +4 = **248**. Ignored `.godot/tmp/suite-drills.sh` is an execution scratch artifact, not shipped source. Sprint JSON notes are evidence, not implementation LOC.

1. **RED first:** write the fixture control before either implementation. Run AC1; require nonzero with named missing-instrument failures, not a green skipped control. Save base RED evidence. Save the design drill block below verbatim. In a scratch copy of the pinned base, copy in the newly written control only, then run it first: require rc 1 with named missing-instrument failures. This is the baseline RED. The verbatim R/C block computes the mutation before its baseline check, so on an entirely pristine base its missing source returns rc 2; record that preflight separately and never call it a killed mutant. After implementation R/C must pass their unmutated baseline and kill the actual mutations. Preserve both RED records for review.
2. Implement design 1a: `/bin/sh "$@"`, millisecond start/end, child CPU user+sys using `times` redirected in the same shell (never `$(times)`), recipe rc, MAKELEVEL, target and top target. Export `SUITE_TOP_TARGET=${SUITE_TOP_TARGET:-$SUITE_TARGET}`. Empty target is `(parse)`. Exactly **one printf append per TSV row**; no split writes. Exit with recipe rc. Retain a line the R mutation can prove changed.
3. Implement all of design 1b: **run/summary/targets/compare/gap/agree/report**, including deterministic formatting, busy-job histogram, top 20, CPU classification (<0.3 floor; <0.9 mixed; otherwise cpu; >1 internally parallel), CPU lower-bound caveat for daemons, and closure hash metadata. Unset caller top-target before make. `run` passes rc, records sha/make/jobs/cores/start/end/rc/sampler PID, samples load into `load.tsv` **every 30 seconds**, and traps cleanup. `report` requires 4.4.1, load files and ≥3 comparable serial and -j6 runs for certification; fallback 3.81 is evidence only. See AC9 for exact load rule. Synthetic data suffices in M1a; no real suite is run.
4. GREEN AC1, R/C, all extra guard drills, syntax/policy gates. Only then add the **one `suite-profile` case** to `tools/test_rig_check.sh`, maintaining outer/nested counts; run M1a AC4, AC13 and fast gates. No profile stub or rig policy change yet. Add changelog entry and evidence notes.

**Fixture safety:** create `T=$(mktemp -d ...)` and install cleanup trap immediately, before any other command. Use only fixture makefiles **inside T**, with cwd, TMPDIR, output directories, fake metadata, helper binaries and child CPU scratch files inside T. Real `/usr/bin/make` and gmake both execute the complete fixture set; absence is a failure, never a skip. Only fixture `-j2` is allowed to the later executor. No real repo target, AILANG cache, sockets, Godot, launchctl or external network. Do not write to `$HOME` or `~/.ailang`, even to plant a sentinel. Verify safety by **observing** before/after metadata of known external locations and auditing explicit output paths; exercise observation positive controls only inside T. Test sampler cadence with a temp fixture `sleep`/load probe, asserting its argument is 30; do not add a production short-interval knob or wait a minute in the control. Verify recorded sampler PID is gone after completion and interruption. RED/GREEN fixtures and mutation workspaces also keep all writes under their own T.

The control emits `suite-profile control NAME: ok|FAIL (...)`, asserts counts, and returns 1 for assertion failure. Define these **20 cases, each on both makes** (40 executions; final k=40 ≥8):

| Case | Required assertion / new guard | Supplemental scratch mutation that must FAIL this case |
|---|---|---|
| `rc-passthrough` | failing recipe rc 1 row; make rc 2 | **R:** wrapper always exits 0 |
| `bare-true` | bare `@true` has a row | suppress its row |
| `submake-level` | child's own name and MAKELEVEL 2 | replace child level/name with parent's |
| `top-target-j2` | p/q overlapping children retain p/q parent | clear inherited top-target in wrapper |
| `caller-top-poison` | caller `SUITE_TOP_TARGET=x` has no effect | delete run's unset |
| `parallel-overlap` | -j2 row intervals overlap | force jobs=1 |
| `cpu-busy-sleep` | busy CPU ≥0.5 wall; sleep CPU ≤0.1 s | read `times` through command substitution |
| `compare-missing` | remove one target: missing=1, rc 1 | **C:** remove missing increment |
| `compare-fewer-extra` | fewer lines fails; extra only reports | disable fewer comparison / reject extra |
| `closure-mismatch` | differing hashes refused | bypass closure-hash comparison |
| `overhead-200` | 200 rows; child CPU ≤ 150 ms/line (30 s) and wall ≤ 1 s/line (hang guard); wall and CPU per line printed. Amended in eval round 1: the design's ≤ 50 ms/line wall bound flaked under rig load (4/4 at 6 busy loops), so 50 ms is reported, not gated | add ~200 ms busy CPU per invocation (a pure sleep is caught only by the hang guard) |
| `atomic-rows` | concurrent finishes have valid, complete TSV fields | split printf at a field, interleave via fixture barrier |
| `load-sampler` | epoch/load rows, sleep argument 30, PID recorded | disable sampler / change cadence to 60 |
| `sampler-cleanup` | PID gone after normal/TERM/INT completion | omit sampler kill in cleanup |
| `report-version` | 3.81 refused as comparison input | remove 4.4.1 check |
| `report-load` | missing load refused; strict/fallback rules, median/max, retries and sample >8 exclusions | ignore absent file / use edge loads only / allow >8 |
| `report-medians` | ≥3 before/-j6 comparable, ratio thresholds, -j8 shown, 3.81 excluded | accept 2 runs / include 3.81 in median / weaken threshold |
| `summary-targets` | golden synthetic summary/targets/histogram, nested folding, (parse), CPU classes and stable ordering | group by child target / drop row count / unsort output |
| `gap-agree` | synthetic timestamped trace parsed; top-20 max(2s,2%) boundary and failure | always accept agree / omit trace target |
| `temp-only` | all writable paths confined to T; external locations only observed | redirect a test output to T's observed outside-fixture probe (still inside T) |

Supplemental mutations use the hardened drill protocol below, one at a time; preserve valid shell syntax and isolate to the named case. For dual-make failures normalize duplicate names before the exact fail-set assertion; each make must itself fail the intended case. The R/C verbatim block's fail-name assertion expects one name, so the control prints one aggregate line per case (both makes' assertions inside it) plus a trailer counting 40 case executions; do not print two FAIL lines for the same case. This keeps the design's R/C assertion valid.

**Risks:** 248 LOC is tight; fixture helpers should share assertion code without deleting coverage. Perl startup overhead is measured, not assumed. Child CPU excludes unreaped daemons; state the caveat in summaries/reports. Sampler traps and attribution are easy to get subtly wrong: explicit cases and kill drills gate them. Load-certification fixture data tests the instrument without resolving any rig policy question.

## M1b — rig wiring and serial baselines (BLOCKED)

**Resume:** **D-129 RESOLVED** and M1a accepted; read the actual answers first.
**Files / LOC:** `tools/rig_check.sh` +20; `tools/test_rig_check.sh` +25; `CHANGELOG.md` +4 = **49**; `design_docs/planned/r1/rig-test-speed-report.md` ≈40 documentation lines; `rig-test-speed-data/` generated raw/header/load/summary/trace/status evidence (excluded from source LOC). Never touch held files.

1. **RED first:** extend rig fixtures with `profile-on`, `profile-off`, `profile-absent`, `gmake-missing` and caller poison (`RIG_PROFILE`, `RIG_TRACE`, top-target). Run AC4/AC5 before rig edits; new cases must fail (existing 9 cases retained). The fake clone copies real instrument scripts; provide stub **gmake** and make, keeping host gmake inaccessible in missing-gmake tests. Retain `suite-profile` fixture case.
2. Implement design 1d under existing watchdog: serial `suite_profile.sh run --make gmake -- test`, optional `RIG_TRACE=1`, adjacent `<sha>.profile/`, summary top 10. Fallbacks exactly profile-off (`RIG_PROFILE=0`), profile-absent, gmake-missing (instrumented --make make). Every fallback logs marker and ≤140-character success description. Do not change default watchdog or runtime/sky/golden behavior. M1b has no lanes.
3. GREEN focused cases/gates; kill the guard mutations below. Controller performs AC10 and **four** AC11 runs on the M1b PR: ≥3 comparable serial gmake runs, first traced; one PATH-without-gmake system-3.81 run. Save first three as `before-gmake-1/2/3`; fourth as `fallback-make381`. Repeat loaded slots at most twice. Baseline is ≥3 comparable runs, never a median of 2; fallback never enters a median. Retain the load files, although the original committed-output bullets omit them: AC9 requires them. Save `.trace.log` for run 1 and each clone's `.status.txt`.
4. Run AC2 (extended to run 3), AC3 and baseline report. Quote independent V29 4,123-second trace as cross-check, not an asserted speed gate. No after-performance certification yet; baseline-only report must identify it as pending, not GREEN AC9. Freeze accepted baseline and closure hash for M2.

**Guard drills:** remove profiler invocation → `profile-on` FAIL; ignore `RIG_PROFILE=0` → `profile-off`; force profile-present → `profile-absent`; choose gmake without checking PATH → `gmake-missing`; for each of these three fallbacks suppress its log marker, remove `SERIAL FALLBACK:` or remove length clamp → corresponding named fallback case FAIL (use long fixture paths/version text); remove environment sanitization → `caller-poison` FAIL. Apply each independently with exact fail-set including caller-poison when its nested rerun fails. Observe sampler cleanup through M1a control. All drills use scratch copies.

**Risks:** fallback fixtures could reach installed gmake unless PATH is fully controlled; make/gmake stubs and command transcript assertions prohibit that. Four runs consume ≥4.6 rig hours at V29 speed; load/retries can add more. Changed closure invalidates baseline; collect all comparison runs on the same accepted closure. D-129 might alter policy: keep blocked until reconciled.

## M2 — parallel lanes (BLOCKED)

**Resume:** **D-129 RESOLVED**, M1b accepted, ≥3 comparable serial gmake runs with matching closure hashes and reproducible summaries.
**Files / LOC:** `tools/suite_lanes.txt` new 25; `tools/suite_parallel.sh` new 120; `tools/test_suite_parallel.sh` new 70; `tools/rig_check.sh` +12; `tools/test_rig_check.sh` +20; `mk/home-tiers.mk` 4; `CHANGELOG.md` 4 = **255**, plus report/data updates (≈20 doc lines; generated data excluded).

1. **RED first:** write parallel fixtures/cases below and rig cases `parallel-on`, `serial-jobs1`, `parallel-absent`, `parallel-no-gmake`, `no-gmake-jobs1`; include `RIG_JOBS` caller poison. Run controls before implementation: require missing-runner/policy failures. Save D/L/E drills; pinned pre-M2 control baseline must RED; missing runner mutation inputs in the verbatim drill are preflight errors, never killed-mutant evidence.
2. Implement 2a/2b. Setup in order `import deps starmap-assets lens-assets deps-ai planet-assets`. Replay lane `replay tools-test parity-m4 .godot/tmp/replay/m4_min_path.vm.ndjson codex-unlocks replay-compat replay-scene`; AI-settings `ai-live-guard ai-settings`; AI-relay `ai-relay replay-noai`. Listed exclusives `crew-perf ship-demo-launch-test`; derive H2 recursive exclusives from goals reaching setup except lens-assets. `plan` safely dumps db, emits order-only lane chains, computes setup/P1/P2, closure SHA256 and coverage including explicit/pattern file rules and generated lane reach. `check` rejects unknown names, cycles, mutants and uncovered rules. P1 uses `-j N --output-sync=target`, -o setup/EXCL; P2 serial with -o setup. One profile across all phases, first-red rc propagation, ALRM/TERM/INT process-group cleanup, cache-write observation at P1/P2 boundary and user-path observations. No seeded user-directory writes.
3. Implement 2c/2d; wire parallel control as a further case through the existing rig control, retaining suite-profile. Default jobs 6; RIG_JOBS=1 and parallel-absent are loud serial fallbacks. Missing gmake defaults to failure naming the serial escape hatch; `no-gmake-jobs1` remains serial 3.81 with marker. Retire M1b's `gmake-missing` case; AC5 now expects **6**, not 7. Change only four counts-file references in `mk/home-tiers.mk`: counts-art and counts-site. No held edits.
4. GREEN controls, AC4–AC8, AC12–AC13 and policy gates. Controller runs AC10; three comparable successful -j6 rig runs plus one -j8 run, evaluates AC9 ≤0.5 baseline and AC11 stability. Every parallel run must automatically prove compare missing=0/fewer=0 and matching closure. Stop landing on coverage loss, cache writes, unexplained status changes, flakes or exhaustion; RIG_JOBS=1 provides operational recovery, not evidence of parallel success.

Parallel control cases (all hermetic fixtures): `setup-first` (plain -j fixture RED, runner GREEN); `lane-order` (second reads first's file); `exclusive-p2` (exclusive behind aggregator runs P2 only); `unknown-lane`; `lane-cycle`; `mutant-closure`; `uncovered-rule`; `lane-file-reach` (explicit and pattern-rule fixture files reached through generated edges); `coverage-counts`; `phase-rc`; `group-cleanup`; `cache-observe`; `user-observe`; `counts-disjoint`. Assertions observe fake cache/user locations inside T. For wall-sensitive fixture ordering use barriers rather than probabilistic races.

| New guard mutation | Control that must FAIL |
|---|---|
| D: force jobs=6, ignoring RIG_JOBS | `serial-jobs1` (and nested `caller-poison` if applicable) |
| L: omit emit_lanes | `lane-order` |
| E: omit subtraction of EXCL from P1 | `exclusive-p2` |
| move setup after P1 | `setup-first` |
| accept unknown lane / cycle / mutants / uncovered rule | respectively `unknown-lane`, `lane-cycle`, `mutant-closure`, `uncovered-rule` |
| omit generated edges in reach / skip explicit or pattern file rules | `lane-file-reach` |
| skip compare / swallow phase failure / omit process-group cleanup | respectively `coverage-counts`, `phase-rc`, `group-cleanup` |
| suppress cache count / suppress user-path observations | `cache-observe`, `user-observe` |
| restore shared counts.txt | `counts-disjoint` |
| bypass runner / fallback marker or truncation / missing-gmake failure | respectively `parallel-on`, each named fallback case, `parallel-no-gmake` |
| forbid serial escape without gmake / ignore new caller sanitization | `no-gmake-jobs1`, `caller-poison` |

**Risks:** hidden edges and load flakes require three successful comparable runs; fake-fixture success alone cannot certify safety. Lane order and EXCL are derived from the current closure, not V4's count frozen forever. The explicit replay-state rule (V43) must count as reached. Trap must kill children, not only parent. No target/assertion/duplicate removal.

## M3 — edges and shards (BLOCKED; held files)

**Resume:** **D-129 RESOLVED**, M2 accepted, and **before any held-file edit**:

```sh
test "$(gh pr view 344 --json state -q .state)" != OPEN && test "$(gh pr view 346 --json state -q .state)" != OPEN
```

Require successful `gh` lookups as well as this predicate (empty/error output is not clearance). Controller refreshes base to main after both PRs are closed/merged, re-runs plan/check, and takes one fresh serial baseline to detect drift. If closure changed (V24), collect ≥3 comparable serial runs on the new closure for AC9; the one refresh run does not replace the n≥3 requirement.

**Files / LOC:** `Makefile` 41 (sim split 30, include 1, import stamp 10); `mk/test-edges.mk` new 45; `mk/m45.mk` 1; `tools/suite_lanes.txt` 3; `tools/suite_parallel.sh` +30; `tools/test_suite_parallel.sh` +20; `CHANGELOG.md` +4 = **144**; report/data updates ≈20 doc lines + generated evidence. This is the only milestone allowed Makefile/m45 edits; the other held files remain outside scope.

1. **RED first:** extend parallel control with `shard-counts`, `shard-partition`, `discovered-unlisted`, `godot-import-edge`, `replay-state-edge`, `import-once`, `import-new-run`; exercise equivalent missing-edge/duplicate-file fixtures against pre-M3 logic before production edits. The new control cases must RED before implementation; AC15/AC16 must also RED on the pre-M3 runner (unsupported subcommands are preflight failures, not proof of a killed guard). Record held predicate first.
2. Measure compile overhead and internal parallelism before fixing K (start at 4, greedily balanced by fresh per-file times). Shards use `cd sim && ailang test FILE...`, **not `--package` plus files**. Partition all **50** files today: 34 sim/ and 16 sim/tools/. Keep sim-check `ailang check --package sim` (STRICT_FALLBACK_001), bridge script and bh-hud-test commands unchanged. `shards-check` compares shard JSON counts with package JSON (554 today), package-discovered count and tracked-file union, no duplicate/missing/discovered-but-unlisted files. Counts adapt to the refreshed tree; never hardcode 554 to mask new tests.
3. Declare Godot→import, AILANG→deps, AI→deps-ai lists in mk/test-edges.mk, include it, and add `parity-m4: $(M45_STATE)` plus `$(M45_STATE): | replay` in mk/m45.mk. Stamp import per exported SUITE_RUN_ID; nested make skips same-run import, a new run always imports. Release H2 exclusives only after import-once proof. Keep needed lanes.
4. GREEN shard/edge controls and drills, AC6–AC8/AC13 (Python only)/AC14–AC16; controller runs full serial/fast/rig gates and ≥3 comparable after runs for ≤0.35 baseline (retain one -j8 evidence run). Publish updated report. Controller routes the design's AILANG `test --jobs N` DX request with measured file/compile evidence; no planner/executor message is sent by this planning run.

**Guard drills:** wrong JSON count → `shard-counts`; duplicate shard file → `shard-partition`; omit discovered fixture test → `discovered-unlisted`; remove Godot import edge → `godot-import-edge`; remove replay ordering/state edge → `replay-state-edge`; disable stamp skip → `import-once`; reuse stale stamp across run IDs → `import-new-run`. Retest all earlier live guards. Held-file gate negative control is a fake `gh` OPEN response inside T; it must prevent every edit (control case `held-open`, added to the same parallel control budget). Failed lookup must also block (`held-open`). No real PR/held-file mutation drill.

**Risks:** K's compile amplification and AILANG's internal parallelism can erase the expected gain; choose K from measurements. Omitting sim/tools would lose 16 files. Stamped import may outlive a run without unique IDs. Changed closure demands re-baselining and proper attribution of intentional sharding changes: preserve pre-M3 target recipe work through equivalent sim-check/unit/bridge mapping and keep all check commands, and have the controller review this mapping; do not simply waive AC7 on renamed targets. If raw per-target/count comparison cannot remain missing=0/fewer=0 after decomposition, M3 stays blocked pending a design refinement rather than weakening compare.

## Acceptance commands and expected base verdicts

All commands run from repo root. `D=design_docs/planned/r1/rig-test-speed-data` in commands below is a local variable, not a global environment change. Logs live in ignored `.godot/tmp`; `mkdir -p .godot/tmp` before checks. Save full control logs and inspect the script's rc **before** tail/grep so a pipeline's last command cannot mask failure. In Markdown tables, `\|` means a literal shell pipe.

| AC / milestone | Runnable command | Expected after implementation | Pristine base (mentally baselined unless marked observed) |
|---|---|---|---|
| AC1 / M1a+ | `sh tools/test_suite_profile.sh > .godot/tmp/sp.log 2>&1; rc=$?; tail -1 .godot/tmp/sp.log; echo rc=$rc` | `suite-profile control: 40 cases, 0 failures`, rc=0; every case exercises both makes | RED: control absent |
| AC4 / each | `env -u RIG_TEST_S -u RIG_GOLDEN_S -u RIG_PROFILE -u RIG_JOBS -u RIG_TRACE -u SUITE_TOP_TARGET -u RIG_CHECK_NESTED sh tools/test_rig_check.sh tools/rig_check.sh > .godot/tmp/rc.log 2>&1; rc=$?; tail -1 .godot/tmp/rc.log; echo rc=$rc` | M1a: 9 cases; M1b: 13; M2/M3: 18 (8 original + profile-control + parallel-control + 4 M1 cases − retired gmake-missing +5 M2 cases); zero failures, rc=0; assert named cases too | Observed base 8 GREEN; enhanced count/names RED |
| M1a fast gates / each | `sh -n tools/timed_recipe_shell.sh; echo rc=$?; sh -n tools/suite_profile.sh; echo rc=$?; sh -n tools/test_suite_profile.sh; echo rc=$?; make python-guard; echo rc=$?; make uid-guard; echo rc=$?` | Each rc=0; include sh -n on each later changed/new shell script in its milestone | Observed three rc127 RED; policy gates GREEN |
| AC12 / M1a | `for m in R C; do sh -c '. .godot/tmp/suite-drills.sh; drillsp "$PWD" "$1"' sh "$m"; echo "$m rc=$?"; done` | R killed (rc-passthrough), C killed (compare-missing), each rc=0 | RED: drill/control/tools absent; pinned-base control baseline must fail (verbatim missing-source drill preflight is rc2) |
| AC2 / M1b+ | `D=design_docs/planned/r1/rig-test-speed-data; rc=0; for n in before-gmake-1 before-gmake-2 before-gmake-3 fallback-make381; do sh tools/suite_profile.sh summary "$D/$n.tsv" > .godot/tmp/summary.txt && cmp .godot/tmp/summary.txt "$D/$n.summary.txt" || rc=1; done; echo rc=$rc` | rc=0; design AC2 extended to third required serial baseline, no weakening | RED: tool/data absent |
| AC3 / M1b+ | `sh tools/suite_profile.sh agree design_docs/planned/r1/rig-test-speed-data/before-gmake-1.tsv design_docs/planned/r1/rig-test-speed-data/before-gmake-1.trace.log; echo rc=$?` | rc=0, each top-20 within max(2s,2%) on same traced run | RED: tool/data absent |
| AC5 / M1b | `grep -c -E '^rig-check control (profile-off\|profile-absent\|gmake-missing): ok$' .godot/tmp/rc.log` | 3 | RED: base control has none |
| AC5 / M2+ | `grep -c -E '^rig-check control (profile-off\|profile-absent\|serial-jobs1\|parallel-absent\|no-gmake-jobs1\|parallel-no-gmake): ok$' .godot/tmp/rc.log` | 6, with all marker/description/failure assertions inside cases | RED: cases absent |
| AC6 / M2+ | `sh tools/suite_parallel.sh check; echo rc=$?` | `plan: setup <a>, P1 <b> goals, P2 <c> goals, lanes <d>, closure covered <e> of <e>`, rc=0; hash printed | RED: runner absent; counts derived, not hardcoded |
| AC12 / M2+ | `for m in R C D L E; do sh -c '. .godot/tmp/suite-drills.sh; drillsp "$PWD" "$1"' sh "$m"; echo "$m rc=$?"; done` | All killed, rc=0; D serial-jobs1 (plus caller-poison if nested), L lane-order, E exclusive-p2 | RED: controls/tools absent |
| AC13 / M1a/M1b/M2 | `git diff --name-only origin/main...HEAD \| grep -c -x -E 'Makefile\|mk/m45\.mk\|mk/earth-link\.mk\|tools/import_keep\.txt\|tools/python-allowlist\.txt\|tools/python_guard\.sh'; git diff --name-only origin/main...HEAD \| grep -c '\.py$'` | 0 then 0 (grep rc1 means zero matches). Also inspect working-tree/untracked paths before controller commit; committed diff alone is vacuous for executor edits | GREEN at base; no implementation diff |
| AC14 / M3 only | `test "$(gh pr view 344 --json state -q .state)" != OPEN && test "$(gh pr view 346 --json state -q .state)" != OPEN; echo rc=$?` | rc=0 **and successful lookups** before edits | Held per V23; expected RED pending controller's external recheck; not queried here |
| AC15 / M3 | `sh tools/suite_parallel.sh shards-check; echo rc=$?` | `shards: <K> shards, <t> tests = package <t>, files <f> = package <f>`, rc=0; current premises t=554 f=50 | RED: runner/subcommand absent |
| AC16 / M3 | `sh tools/suite_parallel.sh check --edges; echo rc=$?` | `godot targets without import: 0`, rc=0 | RED: runner absent and V6 has 35 missing edges |

For all milestones, supplemental guard drills in their tables use scratch copies with the same hardened protocol as R/C; attach mutation diff, unmutated rc0, mutated rc1, and exact named FAIL set to JSON notes. This is required acceptance, not optional test design. Every named case above must actually be implemented before claiming its guard is protected.

**Controller-only commands AC7–AC11 (not run in planning or by the sandbox executor):**

Before a rig run, set `PR` to the actual milestone PR number (required input). Use a distinct `RIG_DIR` for every run so the next clone does not delete previous evidence. For example:

```sh
: "${PR:?controller sets milestone PR number}"
RIG_DIR="${TMPDIR:-/tmp}/rig-check/l4-before-gmake-1" RIG_TRACE=1 tools/rig_check.sh "$PR"
```

First baseline uses trace, next two default serial M1b; fourth uses a controlled PATH without gmake (make still available). Copy each run's `profile.tsv`, `header.txt`, `load.tsv`, summary, and clone status to `D/NAME.tsv`, `D/NAME.header.txt`, `D/NAME.load.tsv`, `D/NAME.summary.txt`, `D/NAME.status.txt`; trace to `D/before-gmake-1.trace.log`. Ensure header/profile companion-path lookup remains valid after copying (the instrument must support these committed stem names). Record sha/make/closure in headers; no absolute scratch-only path may be required to reproduce them. Raw files ~1,500 rows /120 KB per run; retain all, not just summaries.

For M2 use distinct dirs with `RIG_JOBS=6` for three after-j6 slots and `RIG_JOBS=8` for one after-j8 slot; M3 same stable artifact convention on its refreshed baseline. The controller saves the rig log, profile directory and status snapshot before another run. After a parallel run set `RUN_DIR` to that actual clone directory:

```sh
: "${RUN_DIR:?controller sets completed rig clone directory}"
D=design_docs/planned/r1/rig-test-speed-data
# AC7: matching closure, every target and recipe count retained.
sh tools/suite_profile.sh compare "$D/before-gmake-1.tsv" "$RUN_DIR.profile/profile.tsv"; echo rc=$?
# AC8: no new Godot cache write during P1 and same known five untracked files.
grep -c '^godot cache writes outside .godot/tmp during P1: 0$' "$RUN_DIR.log"
git -C "$RUN_DIR" status --porcelain | LC_ALL=C sort > .godot/tmp/after.status.txt
cmp .godot/tmp/after.status.txt "$D/before-gmake-1.status.txt"; echo rc=$?
# AC9: reproducible report from committed evidence.
sh tools/suite_profile.sh report "$D"/before-gmake-*.tsv -- "$D"/after-j6-*.tsv "$D"/after-j8-*.tsv; echo rc=$?
# AC10: unchanged serial local gate (controller, outside sandbox).
PATH=$PWD/runtime/bin:$PATH make test > .godot/tmp/mt.log 2>&1; echo rc=$?
# AC11: real rig/full on milestone PR head (repeat as specified).
tools/rig_check.sh "$PR"
```

Expected AC7 `missing=0 fewer=0 extra=<x>`, rc0, refusal on mismatched closure; AC8 grep **1**, cmp rc0 (baseline contains exactly V35/V42's five `.translation` files, including the literal `positions. 1%) is resolved in the audit.translation`; preserve git's filename quoting). Expected AC10 rc0; AC11 real `rig/full` success at exact PR head, three times for M2 (also M3 performance evidence). Baseline mentality: AC7/AC9 RED without tools/data; AC8 uncertifiable until real P1 exists (not a base regression); AC10/AC11 not run, no claimed base verdict.

AC9 prints make version, spans, CPU-seconds, loads at edges and sampled median/max. Refuse non-4.4.1 or missing load. Comparable: **every sample ≤5.0**; if normal Studio mid-run background makes that unachievable, explicitly record use of design fallback **median ≤5.0, no sample >8** across before/after. No mixing hidden eligibility rules. Each loaded slot repeats at most twice. ≥3 comparable before and ≥3 comparable after-j6; -j8 recorded. M2 median ratio **≤0.5**, M3 **≤0.35**; fallback-make381 excluded. If fewer than 3 eligible -j6 remain, no landing: controller reports blockage to Mark. M1b's before-only report is preliminary and cannot claim AC9 performance success.

## Hardened drill handoff

Save the following design block verbatim as ignored `.godot/tmp/suite-drills.sh` at execution time, not as a third planner output. It is the required R/C drill for M1a and adds D/L/E only after M2. Never invoke D/L/E in M1a/M1b. The block uses explicit ROOT, immediate trap, scratch-only mutations, cmp proof (exit3 if no change), baseline rc assertion, mutated rc1, exact failing-case assertion, and no negated assertion. Adjust anchors only when justified by implementation shape and record the exact change. D may also require pinning caller-poison in its fail-set after nested evidence. For the no-production-tools RED baseline, construct a temp ROOT from the pinned base's tracked tools using read-only git show/archive, copy in the test-first control, and run that control before the mutation generator (which cannot sed a nonexistent source). Keep every write inside that ROOT. Preserve the verbatim drill separately; its pristine-base missing-source rc2 is not the control RED rc1 and is never a killed-mutant result.

```sh
# drillsp ROOT MUTANT, on scratch copies of tools/ (the tree is never edited):
#   R  timed_recipe_shell.sh always exits 0          -> test_suite_profile.sh FAILs case rc-passthrough
#   C  suite_profile.sh compare ignores missing rows -> test_suite_profile.sh FAILs case compare-missing
#   D  rig_check.sh ignores RIG_JOBS=1               -> test_rig_check.sh FAILs case serial-jobs1
#   L  suite_parallel.sh drops the lane edges        -> test_suite_parallel.sh FAILs case lane-order
#   E  suite_parallel.sh puts EXCL into P1           -> test_suite_parallel.sh FAILs case exclusive-p2
drillsp() (
  set -u
  ROOT=${1:?explicit checkout ROOT required}
  mutant=${2:?R, C, D, L or E required}
  cd "$ROOT" || exit 2
  T=$(mktemp -d "${TMPDIR:-/tmp}/stapledon-sp.XXXXXX") || exit 2
  trap 'rm -rf "$T"' EXIT
  trap 'exit 130' INT; trap 'exit 143' TERM HUP
  cp -R tools "$T/tools" || exit 2
  case "$mutant" in
    R) f=tools/timed_recipe_shell.sh; ctl=tools/test_suite_profile.sh; want=rc-passthrough
       sed 's/; exit \$rc$/; exit 0/' "$T/$f" > "$T/m" || exit 2 ;;
    C) f=tools/suite_profile.sh; ctl=tools/test_suite_profile.sh; want=compare-missing
       sed 's/^\( *\)missing=\$((missing + 1))/\1:/' "$T/$f" > "$T/m" || exit 2 ;;
    D) f=tools/rig_check.sh; ctl=tools/test_rig_check.sh; want=serial-jobs1
       sed 's/^jobs=\${RIG_JOBS:-6}/jobs=6/' "$T/$f" > "$T/m" || exit 2 ;;
    L) f=tools/suite_parallel.sh; ctl=tools/test_suite_parallel.sh; want=lane-order
       sed 's/^\( *\)emit_lanes /\1: emit_lanes /' "$T/$f" > "$T/m" || exit 2 ;;
    E) f=tools/suite_parallel.sh; ctl=tools/test_suite_parallel.sh; want=exclusive-p2
       sed 's/^\( *\)p1=\$(minus "\$p1" "\$excl")/\1:/' "$T/$f" > "$T/m" || exit 2 ;;
    *) exit 2 ;;
  esac
  rc=0; (cd "$T" && env -u RIG_TEST_S -u RIG_GOLDEN_S -u RIG_PROFILE -u RIG_JOBS sh "$ctl" > "$T/base.log" 2>&1) || rc=$?
  test "$rc" -eq 0 || exit 1
  cmp -s "$T/$f" "$T/m" && exit 3
  cp "$T/m" "$T/$f" || exit 2
  rc=0; (cd "$T" && env -u RIG_TEST_S -u RIG_GOLDEN_S -u RIG_PROFILE -u RIG_JOBS sh "$ctl" > "$T/mut.log" 2>&1) || rc=$?
  test "$rc" -eq 1 || exit 1
  got=$(sed -n 's/^.* control \([a-z0-9-]*\): FAIL.*/\1/p' "$T/mut.log" | tr '\n' ' ')
  test "$got" = "$want " || exit 1
  echo "drillsp $mutant: killed ($want)"
)
```

## Controller handoff and success metrics

Execute **M1a only** under D-126 C / D-88. M1b resumes only at **D-129 RESOLVED**, M2 after that plus accepted M1b data, M3 after those prerequisites plus successful held-file checks. Planning does not launch an executor, send messages, resolve D-129, or commit; this mission controller owns that handoff. Each feature starts passes:false. Record concrete RED/GREEN values, mutation proof and outside-sandbox rechecks in notes before controller changes passes/status.

Success means every named guard kills its mutant, all fixture cases run on both makes, deterministic summaries reproduce, no coverage shrinks, no held file changes early, and the measured 0.5 / 0.35 speed ratios satisfy the full comparability rule. A failed ratio or exhausted load budget is a blocked result, not a relaxed gate. Unresolved questions remain visible; the unattended loop never treats their defaults as decisions.

**SPRINT_PLAN_PATH:** design_docs/planned/r1/rig-test-speed-sprint.md
**SPRINT_JSON_PATH:** .ailang/state/sprints/sprint_R1-RIG-TEST-SPEED.json
