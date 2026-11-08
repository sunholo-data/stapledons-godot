# Row 7ad: bound the crew-console recipe and clean up escaped simulation children

**Status:** Planned, mission iteration 80, designer, 2026-11-08. Design only; implementation and live acceptance checks are unmeasured.
**Release:** r1. **Milestone:** charter row **7ad**, test hygiene within approved `R1-M4-JOURNEY` (D-22/D-66), prerequisite of row 7ac (V6).
**Priority:** P1. Supply the bounded recipe and simulation cleanup required before 7ac resumes; leave its serial-pin change separate.
**Implements:**

- [Charter row 7ad and D-88 A](../../stapledon-mission.md): bounded test execution, including the simulation outside Godot's process group; no negative pillar (V6).
- Test infrastructure supporting [R1 foundations, M4](https://github.com/sunholo-data/stapledons-design/blob/main/roadmap/r1-foundations.md#m4-first-journey-a-vertical-slice) and the [crew assignment system](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/crew-assignment-system.md), not another crew feature.
- Preserve [ADR 0001](https://github.com/sunholo-data/stapledons-design/blob/main/decisions/0001-engine-and-architecture.md)'s Godot/AILANG sidecar boundary. No implementation of a new [relativity-spec §2–§4](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md) or [Higgs-bubble §2, §8](https://github.com/sunholo-data/stapledons-design/blob/main/physics/higgs-bubble.md) rule is needed (V12).

**Depends on:** the existing script-gate infrastructure and raw `crew-console-test` at `fa8480d5` (V2–V5); shell, Perl with a monotonic clock, and working process inspection on macOS/Linux. The latter is unavailable in this designer's sandbox (V9, V11). Controller owns capacity probes, quorum, live gates and landing; the designer made no additional provider/quorum calls beyond its configured Codex authoring run (subscription tokens are recorded by the controller).
**Estimated LOC:** approximately 600–700 code/test LOC across five implementation files, three sub-milestones. Shell plus embedded Perl is test/process glue; no new Python, package or `.gd` file.
**Evidence:** all current-checkout observations below are pinned to **`fa8480d55d55df7eccc3d16cf4f296e2357e327f`**. Canon read at `586f0eb542edaee19944222e94ff1daeb823680c`. V8 is inherited first-party **controller** evidence, not a designer-run test. Proposed behavior and future test interfaces below are requirements, not measurements.

## Game vision alignment

Feature-validation method from `game-vision-designer`, using the six actual current pillars, not its starter-template candidates (V1, V12).

| Pillar | Relevance | Score | Notes |
|---|---|---:|---|
| Choices Are Final | 0 | 0 | Proposed changes affect test process lifetimes only; no save, replay or commitment rule change. |
| The Game Doesn't Judge | 0 | 0 | No player-facing text or scoring change. |
| Time Has Emotional Weight | 0 | 0 | Wall-clock test deadlines introduce no simulation-clock or voyage-pacing change. |
| The Ship Is Home | 0 | 0 | Crew-console checks gain cancellation cleanup; crew relationships and console presentation do not change. |
| Grounded Strangeness | 0 | 0 | No species, sky or scientific model change. |
| We Are Not Built For This | 0 | 0 | No crew psychology or resilience change. |
| Hard sci-fi authenticity (spec) | 0 | 0 | No physical quantity, RS/HB check value or rendering formula change. |
| **Net / Go** | | **0 / Go** | **D-88 A applies:** test hygiene inside D-22/D-66, with no pillar negative (V6). No human decision is required. |

## Problem

1. **The shipped crew-console recipe has no deadline.** `Makefile:158–161` invokes raw `$(GODOT_SIM)`, then checks its captured exit status, absence of `SCRIPT ERROR:`, and `^crew-console: 0 failures$`. Its `import` prerequisite and `test` membership are explicit (V2). The test calls `real_sim()` and constructs `SimBridge` instances; the bridge launches through `OS.execute_with_pipe` (V2). These are static observations, not a live simulation-group measurement.
2. **The existing supervisor cannot cover a changed process group.** `tools/script_gate.sh:28` signals only `-$pid`; its comment explicitly excludes `setsid`/`setpgrp` children (V3). The controller's fresh two-arm reproduction found the same-group child absent after timeout, but the escaped child still live with status `Ss`; both gate calls returned 1 with timeout rc 142 (V8). The controller killed only its registered child during final cleanup. Interruption behavior of a repaired runner is still UNMEASURED.
3. **A migration would change the wrong surface.** A designer-run, finite summary probe returned 1 because the zero-count guard refuses `crew-console: 0 failures` (V3). Preserve that guard and the raw recipe's predicate; do not change the test's summary merely to use `SCRIPT_GATE`.
4. **The tests need an independent outer bound.** `mk/script-gates.mk:23` duplicates the group-only supervisor as `SG_SUP`, used at 120/600 seconds for selftest/drill (V4). Reusing the candidate runner as its own escaped-child watchdog could leave the test stuck or leaking precisely when the candidate is broken.
5. **This is the missing prerequisite, not a second serial design.** The charter and [7ac revision 2](m4-7ac-serial-pin.md#quorum-r2-response-revision-2-controller-carve-out) already describe the requirement (V6). No dedicated 7ad doc was tracked at the measured base; the positive control was the tracked 7ac doc (V7). Historical 7ac V15/V18/V19 and its `kh`/`ks` results remain historical; none is a live result for this proposal.

## Goals and non-goals

**Goals:** one production bounded runner; use it in both `script_gate.sh` and the actual raw crew-console recipe; terminate observed descendants even after a process-group change or reparenting; bound cleanup on timeout and TERM/INT/HUP; preserve ordinary command status, environment and arguments; commit hermetic regression controls and targeted Make wiring.

**Non-goals:** no physics/package, simulation, protocol, bridge, UI, scene, audio, crew-test or `_serial` edits; no 7ac implementation; no baseline migration, zero-count relaxation, new aggregate for real-sim stress drills, GPU check, full-suite run, shared mission-state write, or canonical/attended-repo mutation. The `import` prerequisite itself is outside this recipe deadline; the controller harness must independently cap the entire `make` invocation, including import.

## Design

Add a reusable bounded runner that records living descendants before terminating their ancestors, then apply it without changing either gate's result predicate.

### D1. Production runner: `tools/bounded_run.sh`

Interface: **`sh tools/bounded_run.sh N -- command [args ...]`**. Validate a positive whole-second `N`, `--`, and a nonempty command before launch; usage errors return 2. Use shell as the entry point and `exec` embedded Perl, so there is one supervisor PID. Use `exec env` with an argument array, never `eval` or a reconstructed command string: leading `VAR=value`, an explicit `env -u NAME`, spaces, empty arguments, stdin, cwd, stdout and stderr must survive unchanged.

Use a monotonic deadline starting at runner entry. Fork the command into its own process group, with a pipe handshake holding it before exec until the supervisor has its initial identity and signal handlers installed. Reset the command child's signal dispositions before exec, including INT inherited as ignored from a background shell. Handlers in the supervisor only set a cancellation flag; cleanup must not run recursively inside a signal handler. The first cancellation event wins; repeated signals do not restart the deadline or grace period.

**Discovery and identity policy:**

- While the command runs, take `LC_ALL=C ps -axo pid=,ppid=,pgid=,lstart=,stat=` snapshots at most 100 ms apart, subject to snapshot cost. Parse PID/PPID/PGID, the five `lstart` fields and state; do not collect the host's command lines or environment. Check the actual supervisor and held command against the table before releasing exec. An absent/denied/malformed table is an inspection failure, never an empty successful scan.
- Build the descendant closure from the command and each still-matching recorded descendant. Keep `(pid, birth/start token)` records after reparenting; a later `PPID=1` or changed PGID does not erase ownership. Retire identities that disappear or change. Never expand ancestry through a stale/reused PID.
- Before **each** STOP/TERM/CONT/KILL, recheck that exact identity. Signal individual owned PIDs; do not broadcast a cached negative PGID after its leader has exited. Exclude the supervisor, its `ps` helpers, and unrelated processes. Keep the command's wait status when observed; do not derive it from a later cleanup `waitpid` result.
- Snapshot acquisition is itself asynchronous: fork/exec `ps`, read its pipe nonblocking, and cap each acquisition at 200 ms or the remaining phase budget, whichever is smaller. Kill and collect only that direct helper on overrun. No backticks with an unbounded `ps`, blocking pipe drain, or blocking `waitpid(..., 0)` belongs in the supervisor.

**Cleanup policy:** one **3-second total budget** after cancellation or detected command exit. Freeze the matching command and recorded descendants top-down, refresh the descendant closure while parents are stopped, and freeze newly found descendants before sending graceful signals. Spend at most 250 ms of the cleanup budget on this final discovery. Send TERM then CONT to the frozen owned set, allow up to 2 seconds of grace within the same budget, and send KILL to every remaining matching identity, including reparented children. Continue bounded nonblocking waits/probes through the remainder of the 3 seconds. Do not end cleanup just because Godot/the command exited during grace. A process stopped by this runner must receive CONT or KILL on every exit path.

Reap the direct command and helper children with `WNOHANG`. For grandchildren reparented to the OS, require absence of a living matching identity; a zombie is dead but cannot portably be `waitpid`-reaped by this supervisor on macOS. Report that distinction accurately. Cleanup also runs after ordinary command exit, so an already recorded escaped child cannot survive a successful parent exit.

| Event | Runner result after successful cleanup |
|---|---|
| Ordinary exit | Exact child exit code, including 0, 7, 127 and 142. No timeout diagnostic on an ordinary exit 142. |
| Child dies by signal, supervisor not cancelled | `128 + signal`, e.g. TERM = 143. |
| Deadline | 142; stderr contains `bounded-run: timeout after N s`. |
| Supervisor receives HUP / INT / TERM | 129 / 130 / 143 respectively; stderr names the interruption. |
| Inspection/setup failure or living owned process at cleanup deadline | 125 with a specific diagnostic; attempt the same bounded cleanup for already owned children. Never claim success. |

Elapsed cancellation time must be at most **N + 3 seconds**, allowing one additional second in command-level assertions for scheduling/measurement granularity. Set the timeout cleanup end to the original command deadline plus three seconds, so a late polling iteration cannot add another full cleanup budget. An interruption gets the same cleanup bound from the first signal's recorded delivery time. An ordinary exit with no survivors should return promptly, not wait until N. The bound assumes schedulable user processes and a responsive kernel; no shell tool can force a process out of uninterruptible kernel sleep.

**Limit of the claim:** polling is not a process-containment primitive. An unobserved child that double-forks and reparents between snapshots can be missed; `lstart` has only second precision on some hosts, and PID reuse between observation and signal still has a race. Retiring changed identities and verifying immediately before signaling reduces, but does not abolish, that risk. This design closes the ordinary long-lived sim/escaped-child failure by recording it while its parent is alive and retaining it after parent exit. It makes no arbitrary-daemon discovery guarantee. Kernel job containment or runtime child registration would be a separate cross-platform design if needed.

### D2. Integration and signal relay

Define `BOUNDED_RUN = sh $(SG_TOOLS)/bounded_run.sh` and `CREW_CONSOLE_TIMEOUT_S ?= 300` in `mk/script-gates.mk`. In `tools/script_gate.sh`, resolve the helper beside `$0`; replace only the embedded group-only Perl invocation and its obsolete limitation comment. Keep argument validation, log routing, WANT_RC behavior, summary matching, per-count zero probe and public success/failure status. In particular, timeout remains a gate failure with the existing `timeout after N s (rc 142)` wording (V3, V4).

For the raw crew-console recipe, put `$(BOUNDED_RUN) $(CREW_CONSOLE_TIMEOUT_S) --` before `$(GODOT_SIM)` with the same script arguments and log. Preserve `mkdir`, `import`, the displayed `ok/FAIL/crew-console` lines, and the three conjuncts: captured rc 0, no `SCRIPT ERROR:`, exact zero-failure summary (V2). Preserve the raw test file byte-for-byte. Do not route through `SCRIPT_GATE`, change baseline row 37, or lower the 118 pin (V5).

Both calling shells need an explicit HUP/INT/TERM relay while awaiting the runner. Start the runner asynchronously, store its owned identity, trap each signal and forward that signal only to that supervisor. A trap-interrupted `wait` is not the runner's final status. Use a completion flag and a relay watchdog with an absolute N+4-second deadline, shortened to at most four seconds after a relayed signal; never reset it on another signal. At watchdog overrun, signal/collect only the still-owned supervisor, return failure and retain the diagnostic. Every shell wait, including collection of the watchdog, must be covered by that deadline; do not append an unconditional blocking second wait. The production runner owns descendant cleanup; the independent test guardian additionally owns fixture cleanup if the runner is defective. Record interruption separately so a previously printed success summary, or WANT_RC matching a signal code, cannot turn cancellation green. Clear the traps after collection. The runner must install handlers even if INT was inherited ignored. Exercise direct signals to these wrapper shells as well as signals to the runner and a foreground make group.

The runner deadline starts after `import`; at the 300-second default its test command must finish or clean up within 303 seconds (assertion allowance 304). Controller checks put a separate outer bound around all of make. Do not silently raise other targets' limits or relax existing selftest ceilings to accommodate this change.

### D3. Independent test guardian and fixtures: `tools/test_bounded_run.pl`

Commit a Perl harness with the exact interfaces below. It is test glue, not another production-runner implementation. Every invocation takes an **absolute isolated clone ROOT** and an **absolute artifact parent**. Create a new mode-0700 `7ad-*` directory beneath that parent on every run; print its path, retain logs/results, and record ROOT's HEAD. Never reuse a fixed results file or change `$HOME`/mission state. Reject a missing ROOT or unwritable artifact parent before launching children.

The top-level harness forks a worker and remains an independent guardian. It must **not** call/source `bounded_run.sh`, `script_gate.sh`, or `SG_SUP` to enforce its own cap. Maintain a private registration channel from fixtures to guardian. Register fixture PID, actual birth token, nonce and parent identity while the parent relationship still exists; acknowledge before allowing the fixture to escape. A ready marker alone or `kill(pid, 0)` alone is insufficient evidence of identity. Use real `ps` output, with the guardian and a live owned sentinel as positive controls in the same probes. Never turn a denied `ps`/Godot access into a pass, fail, or evidence of absence: return **3 / UNINFORMATIVE UNDER SANDBOX** after safe cleanup.

For each case, observe the identities alive before the trigger, assert escaped PGID differs from the parent, and preserve those records for the post-check even if the parent vanishes. Fixtures are private Perl parent/child processes. Cover both same-group and `POSIX::setsid()` children, with TERM/HUP/INT/ALRM ignored, and a parent that dies on TERM before its child. A separate fixture lets the parent exit after at least two positive observations while its escaped child remains; this tests retained tracking on ordinary exit/reparenting. Give fixture loops an independent finite monotonic lifetime as a backup; do not rely on their stdout pipe closing. An unrelated owned sentinel must remain alive until guardian cleanup.

All worker/command waits, readiness waits, process probes, pipe drains and cleanup waits have absolute deadlines; use `WNOHANG`/nonblocking I/O. Register both fixture parents and children. On assertion failure, timeout, or interruption, the guardian KILLs only still-matching registered fixture identities and its own unreaped direct children/private command group, collects direct children and checks for no live registered survivors. Hold the private group's leader identity until cleanup; never signal a stale/reused group number. The guardian has a separate **3-second cleanup budget** after its mode cap. For legacy gate fixtures without registration, the guard owns the private command group; new escaped fixtures must always register. No `pkill`, name-based host sweep, or PID copied from an old artifact. The guardian must first record a candidate's leak as a failure, then clean it; its cleanup must never make the candidate pass.

Replace duplicated `SG_SUP` with **`perl $(SG_TOOLS)/test_bounded_run.pl guard "$(CURDIR)" "$(BOUNDED_TEST_ARTIFACTS)"`**, where `BOUNDED_TEST_ARTIFACTS ?= /tmp`. Retain the existing 120/600 caps; add the `--` delimiter in its two calls. The guard supplies fresh `SCRIPT_GATE_TMP` within its run directory; remove the two fixed `SCRIPT_GATE_TMP=$(SCRATCH)/...` prefixes. Keep `tools/test_script_gate.sh` and all its fixtures/assertions unchanged (V4). This is an independent outer guard, not a recursive run of the candidate supervisor.

Add `.PHONY` targets `bounded-run-selftest` and `bounded-run-drill` in the same mk file. `test` and `ci-fast` depend on the former; it calls harness `selftest` only. The latter calls `mutants` and is a targeted executor gate, not a new real-sim aggregate dependency. The existing script-gate selftest/drill/lint remain required. No lint classification exemption is needed: the crew-console invocation remains raw/ungated, with its baseline key intact (V5).

### D4. Required test command interfaces

These are **future committed interfaces**, fully specified for planning; none has been implemented or run by the designer. Each mode writes `results.json` with case name, actual command rc, trigger, elapsed monotonic time, pre/post identity observations, cleanup outcome and any inner make rc. It returns 0 only if every expected assertion holds, 1 on assertion failure, 2 on usage error, 3 on a void fixture/inspection restriction. A cap firing is always failure, not a successful mutation kill.

| Invocation after `perl tools/test_bounded_run.pl` | Hard worker cap | Fixtures and required assertions |
|---|---:|---|
| `selftest ROOT ARTIFACT_PARENT` | 120 s | Production runner: exit 0/7/142; missing executable 127; child self-TERM 143; leading assignment, `env -u`, empty/spaced/metacharacter args, stdin and both output streams preserved. Invalid N/missing delimiter launch nothing, rc 2. Deadline N=2 with ignored signals, same-group and escaped child: runner 142, elapsed ≤6 s, no live registered identity. HUP/INT/TERM to runner: 129/130/143, ≤4 s after trigger, no survivors. Parent exits 7 leaving observed escaped child: runner 7 and child gone. Run the gate and raw-Make stub cases below in the same mode. |
| `mutants ROOT ARTIFACT_PARENT` | 180 s | Run clean candidate first. Test scratch copies with old/group-only runner, descendant retention disabled, interruption cleanup disabled, and raw recipe's runner bypassed. Each must actually change bytes or exit 3. Old/group-only must fail the escaped timeout and interruption absence assertions; no timeout-only mutant credit. No-retention must fail the parent-exit/reparenting case; no-relay must fail directed wrapper interruption. Runner-bypass must fail raw-Make hang/deadline cleanup. Assert named failure plus real rc, then independently clean owned survivors. Restore every scratch mutation and `cmp` it against its saved original in the exit cleanup. |
| `crew ROOT ARTIFACT_PARENT normal` | 480 s | Run actual `make --no-print-directory -C ROOT crew-console-test AILANG=ROOT/runtime/bin/ailang` with real Godot and no GODOT override. Assert actual make rc 0, exact zero-failure summary, no `FAIL` or `SCRIPT ERROR:`, and no live recorded sim after completion. Record real sim/Godot identities while live. No 7ac checks/count pin added. |
| `crew ROOT ARTIFACT_PARENT hang` | 240 s | In a private synthetic project copy, substitute only the copied crew test with the minimal real-sim fixture specified below. After readiness, let the recipe's 60 s limit expire. Actual make rc 2; timeout diagnostic, elapsed command time ≤64 s; real sim and Godot gone even if summary printed first. |
| `crew ROOT ARTIFACT_PARENT hup` / `int` / `term` | 240 s each | Same synthetic real-sim fixture. Deliver the selected signal to the foreground make group after independent readiness/identity probes; require actual nonzero make status (record the exact platform value), interruption diagnostic, no green verdict, and no live registered sim/Godot ≤4 s after delivery. Also test direct recipe-shell relay in the stub cases. |
| `audit ROOT ARTIFACT_PARENT BASE` | 30 s | Assert the union of `git diff --name-only BASE` and untracked nonignored paths contains only the five implementation Files paths and the explicitly named record paths below. Report each class separately; a record allowance never admits another implementation file. Materialize BASE's crew test, script-gate test and baseline via `git show` into private scratch, then `cmp` each against ROOT. Capture `make -qp` output/status without a pipe: rc 0 or 1 is a usable database, rc 2 is an error. Traverse its actual prerequisite graph and require `bounded-run-selftest` reachable from both `test` and `ci-fast`. No source-string-only substitute for the functional wiring cases. |
| `guard ROOT ARTIFACT_PARENT CAP -- command [args ...]` | CAP | Independent guardian described above. On ordinary completion return the command's true normalized status, unaltered; on guardian cap return 124 with a distinct guard diagnostic. Never confuse 124 with a production runner timeout. Uses no candidate supervisor. |

**Gate cases inside `selftest`:** call the actual `script_gate.sh` with a counted summary and the registered same-group/escaped fixture, N=2. Assert gate rc 1, timeout reason, and no surviving child. Repeat directed HUP/INT/TERM to the script-gate shell after readiness, including a valid summary emitted before the hang; all must be failures with cleanup. Keep ordinary counted success and WANT_RC=1 negative-control success. The existing zero-count rejection must still fail; do not exempt crew-console from it. Call the runner through the shell wrapper, not just a standalone helper.

Include a repeated-signal case (TERM followed by INT/HUP during grace): the initial cancellation classification and cleanup deadline must stay fixed. Require a named result for every specified case, with a fixed expected case-name set, so silently deleting a case cannot leave the harness green.

**Raw-Make cases inside `selftest`:** invoke real make against ROOT, with GODOT set to a private executable stub and AILANG set to a private no-op executable; the stub accepts `--import` and exits 0 there. For the script invocation it checks `AILANG_BIN` equals that actual stub path and arguments name `tests/test_crew_console.gd`, then produces the case's output/status or spawns the registered escaped child. Pass summary + rc 0 must give **make rc 0**; rc 7 + summary, `SCRIPT ERROR:` + summary, and no summary must each give **make rc 2**. Summary followed by a hang at N=2 must give make rc 2 within 6 seconds of the script launch, with no survivor. Direct signals to the recipe shell and signals to the make group must fail and clean up, even after a summary. Override `SCRIPT_GATE` to a nonexistent private path in the success case: raw success must still work. These are execution tests of Make wiring/predicates, not source-string tests. The real normal mode separately verifies the actual test and sim.

**Synthetic real-sim fixture:** copy the candidate project/resource files (including `.uid`s and the required runtime/cache/assets) from the explicit ROOT into a private run directory; never symlink a file that will be edited or copy shared mission state. Replace only that copy of `tests/test_crew_console.gd` with a tiny `SceneTree` retaining a member `SimBridge`. Call `start()` and `new_game` successfully, emit a private ready record containing actual `child_pid`, print `crew-console: 0 failures`, and stay in the event loop without `quit` or `stop`. The harness validates the recorded child through actual parent/identity probes and a healthy handshake before applying SIGSTOP to that owned real sim, then verifies it is stopped. This produces a live, hung real sim without implementing fake NDJSON replies. Ignored-signal/KILL escalation is covered separately by the Perl fixtures. Assert the sim's different PGID as an actual observation; if that premise no longer holds, return 3 and retain evidence rather than invent an escape.

Import the synthetic project under its own 120 s guardian cap, then run its real `make crew-console-test CREW_CONSOLE_TIMEOUT_S=60 AILANG=<copied-runtime>` with normal GODOT. Readiness must arrive within 30 s of the script launch; otherwise the fixture is void. Cap the make child independently at 70 s after launch within the mode's 240 s overall budget. Register Godot/sim before delivering any fault. On every exit restore the substituted scratch file and `cmp` against its saved bytes. Original ROOT's tracked bytes must remain unchanged. No mutation of the actual crew test, bridge, sim, or canonical checkout is authorized.

## Acceptance criteria

Use the controller commands in Appendix A. **No live row below is claimed passed.** `H MODE [args]` there captures the harness's real status without a pipe. For make commands, `G CAP ...` captures the independent guard's status; the guard must record and preserve the actual inner make rc.

| ID | Criterion | Command / required evidence |
|---|---|---|
| AC1 | Ordinary statuses, signals, env/argv/stdin preserved; invalid invocation launches nothing | `H selftest`; status/transport cases from D4 all pass with recorded exact statuses. |
| AC2 | Timeout stops same-group and escaping ignored-signal child, including when parent dies first | `H selftest`; N=2 → runner 142 in ≤6 s; owned identity positive controls before, no live registered child after. |
| AC3 | HUP/INT/TERM trigger bounded cleanup through runner, script-gate shell and raw recipe shell/make group | `H selftest`; runner 129/130/143, wrappers fail, cleanup ≤4 s; a prior success summary cannot mask interruption. |
| AC4 | Recorded descendant survives neither reparenting nor ordinary parent exit; unrelated sentinel untouched | `H selftest`; parent-exit 7 retained, child absent, sentinel alive before guardian cleanup. |
| AC5 | Real raw Make wiring preserves rc/error/summary conjuncts and bounds a hung escaped child | `H selftest`; actual make rc 0/2 as specified in D4, not the rc of grep/tee/cat. |
| AC6 | Controls discriminate the defect and regressions | `H mutants`; clean cases green; old/group-only, no-retention, no-interruption/relay and bypass mutants red for the specified behavior, not a watchdog/inspection failure; no survivors on failure; restored bytes equal. |
| AC7 | Actual raw test with the real simulation passes | `H crew normal`; inner make rc 0, original summary/predicate and test unchanged, real processes collected. |
| AC8 | Hung real sim is cleaned up by the recipe timeout | `H crew hang`; actual make rc 2, timeout ≤64 s, no living registered Godot/sim. |
| AC9 | Interrupted real sim is cleaned up through the actual Make invocation | `H crew hup`; `H crew int`; `H crew term`; record true make status, require failure and cleanup ≤4 s from signal. |
| AC10 | Existing gate semantics, fixture assertions and ratchet remain intact | `G 30 make --no-print-directory -C "$ROOT" script-gate-lint`; `G 135 make --no-print-directory -C "$ROOT" script-gate-selftest`; `G 615 make --no-print-directory -C "$ROOT" script-gate-drill`; each make rc 0. Expect unchanged 18-stub and 24-total case summaries (V4) and 249/131/118 inventory (V5), unless a separately landed migration is explicitly reconciled. |
| AC11 | Permanent headless regression test is wired and bounded; no unrelated implementation changes | `G 135 make --no-print-directory -C "$ROOT" bounded-run-selftest`; `G 195 make --no-print-directory -C "$ROOT" bounded-run-drill`; `G 30 make --no-print-directory -C "$ROOT" python-guard`; `H audit "$BASE"`. Require actual allowlist, byte-equality and graph assertions from D4; functional wiring cases remain mandatory. |

For AC10 a sandbox denial is **UNINFORMATIVE UNDER SANDBOX**, not a failed gate and not permission to remove an assertion. Keep existing test bodies and max-time assertions unchanged. Rerun targeted tests on the actual candidate after reconciliation; controller handles GitHub fast CI and independent evaluation under CLAUDE.md. No GPU or full `make test` is required by this design.

## Sub-milestones and estimates

| Order | Work | Estimated LOC / time | Dependency |
|---|---|---|---|
| M1 | Bounded runner plus independent guardian, registered fixtures, status/timeout/signal/reparenting tests | 400–450 / 0.75 day | Static contracts above; controller process access |
| M2 | Two integrations, replace test-only SG_SUP, Make targets and wiring/negative controls | 100–130 / 0.5 day | M1; existing selftest/drill/lint pass |
| M3 | Synthetic real-sim fixture, real normal/hang/interruption probes, mutant controls and candidate scope audit | 100–120 / 0.5 day | M2; isolated runtime-capable clone outside sandbox |

One implementation PR after planning, with the five-file surface below. Stop for a new design if fixing cleanup requires a bridge/runtime/protocol change. Row 7ac resumes only after 7ad lands, following its recorded resume predicate (V6).

## Conflict Surface

- **Makefile:** restrict the implementation hunk to `crew-console-test` around measured lines 158–160, including its signal relay. Leave top-of-file runtime/Kerr and star-name regions alone. The named designer Agent wrapper independently read GitHub this fire and reports PR #373 changes runtime release/top Kerr oracle and star-names near 225, while #380 adds `kerr-physics-test` near 251, neither touching this recipe or `tools/script_gate.sh`. That is wrapper evidence inherited by the pinned heavy designer, **not independently reverified inside its sandbox**: both `gh api` reads failed to connect (V10). Fresh PR heads/hunks remain UNMEASURED; Appendix B is the landing recheck.
- **mk/script-gates.mk:** new production helper variable, crew limit, independent SG_SUP definition/two invocations, and two targeted test targets/prerequisites. Preserve all baseline/prerequisite pins and existing gate-test assertions (V4, V5). Concurrent gate migration may move counts, so remeasure rather than copy 118 blindly at landing.
- **tools/script_gate.sh:** shared production supervisor only, plus necessary shell signal relay; public predicate remains unchanged. Every caller shares this behavior; existing gate regression checks are mandatory (V3, V4).
- **7ac:** no overlapping test hunk; its proposed `tests/test_crew_console.gd` additions, serial logic, `.gitattributes` and changelog remain separate (V6, V7). Do not transplant its historical drill code, broad process-name cleanup, or live verification claims.
- **Canon/attended work:** no changes. Rejected dome/dual-coordinate directions and the retired Go renderer are irrelevant to this process-glue repair; no revival or code port is proposed (V12).

## Files

Explicit **future implementation/test** allowlist for planner lane derivation (five code/test paths):

| File | Change |
|---|---|
| `tools/bounded_run.sh` **new** | The single production shell/Perl supervisor, D1. |
| `tools/test_bounded_run.pl` **new** | Independent guardian, hermetic fixtures, integration/mutation/real-sim modes, D3–D4. Generated fixture files live only in private temporary directories. |
| `tools/script_gate.sh` | Replace embedded supervisor, signal relay and corrected supervisor documentation, D2. |
| `Makefile` | Bound the raw crew-console recipe and relay interruptions; preserve test invocation and predicate, D2. |
| `mk/script-gates.mk` | Variables, independent test guard, bounded selftest/drill wiring, D3. |

**Record paths (controller bookkeeping, outside the five implementation paths):** the mandatory `changelogs/unreleased/2026-11-08-bounded-script-runner.md` fragment; this doc and its companion `m4-7ad-bounded-script-supervisor-sprint.md` (in planned or implemented/r1); `.ailang/state/sprints/sprint_R1-M4-JOURNEY.json`; named row-7ad evaluation/reproduction JSONs under `.ailang/state/evaluations/`; and the six `design_docs/stapledon-mission{,-log,-index,-dashboard,-status-archive,-log-archive}.md` streams. Audit must enumerate each actual record path, never blanket-exempt `tools/`, `tests/` or other code. The fragment and final doc/index progress are required on implementation landing.

Keep `tools/test_script_gate.sh`, `tools/script_gate_lint.sh`, `tools/script-gate-baseline.txt`, `tests/test_crew_console.gd`, `ui/crew_console.gd`, `bridge/`, `sim/`, lockfiles, packages, scenes, shaders, assets and audio byte-identical. No new `.uid` or Python allowlist entry. Controller may make ordinary landing records later; they are not implementation dependencies or additional files authorized in this designer turn.

**This designer turn's entire change:** this one new document, `design_docs/planned/r1/m4-7ad-bounded-script-supervisor.md`.

## Risks and mitigations

| Risk | Mitigation / limit |
|---|---|
| Escape before any observation | Do not claim arbitrary double-fork coverage. Retain observed identities across reparenting; freeze/scan before ancestor termination. Long-lived escaped and parent-exit fixtures exercise the ordinary failure. |
| PID reuse / second-resolution start token | Verify birth identity before every signal; retire disappeared/changed records; avoid stale group broadcasts. Residual observation-to-signal race remains on portable macOS Perl; stronger kernel containment is outside this row. |
| `ps` hangs, is denied or parsing differs across macOS/Linux | Bound its own child/read/wait, use C locale, parse actual tool output with identity positive controls. Fail closed before releasing the command where possible. Sandbox denial is uninformative for acceptance. |
| Root exits during grace, or repeated interruption races cleanup | Keep accumulated descendants and original wait status; one cancellation state and one total cleanup deadline; test parent-first exit and repeated signals. |
| SIGINT ignored by background shell or make loses a job signal | Explicit handler reset and wrapper relay; independently direct signals to wrappers as well as make's foreground group. Do not infer interruption success from timeout tests. |
| New supervisor hides its own broken tests | Independent guardian with registered fixture identities, bounded raw waits, failure-before-cleanup reporting; do not use candidate runner as watchdog. |
| Wall clock overhead trips existing 6-second selftest ceiling | Retain the 2-second grace inside a 3-second total cleanup budget; enforce N+4 assertion allowance. Fix the algorithm if it exceeds existing ceilings; do not raise those ceilings. |
| Imported project or real runtime cannot run here | Designer did not launch Godot. Controller runs real normal/hang/three interruptions in isolated copies; these are explicitly UNMEASURED. No data written to shared HOME for a persistence drill. |
| Old artifact PID accidentally treated as an owned process | V8 is read-only provenance. Never reuse its PIDs in a signal command; every fixture run registers fresh identities. |

## Open questions

None.

## Deliverables

The implementation should deliver the five-file change, permanent hermetic `bounded-run-selftest` in both headless aggregates, targeted `bounded-run-drill`, and fresh per-run controller evidence for AC1–AC11, including ordinary real crew-console success and the real-sim timeout/interruption cases. No 7ac test change, baseline migration, new game behavior or canon amendment is part of the deliverable.

The present artifact is design only. Controller's remaining process/Godot probes, fresh PR conflict checks, fast CI, quorum and independent evaluation are **UNMEASURED** here. No current or historical full-suite/rig result is asserted for this design.

## Verification log

Measured 2026-11-08 in the specified checkout, HEAD **`fa8480d55d55df7eccc3d16cf4f296e2357e327f`** throughout. Static read commands completed with rc 0 unless stated otherwise. Pipe outputs below are static inspection only; no live-gate status is inferred from a pipeline. Acceptance commands separately require the true command/make status.

| # | Claim | Command | Observed result |
|---|---|---|---|
| V0 | Base and initial scope | `pwd`; `git rev-parse HEAD`; `git status --short` | Requested design checkout; full HEAD above; initial status empty. No git writes performed. |
| V1 | Required local rules/format and vision method read | `cat CLAUDE.md`; `cat .agents/skills/stapledons-design-doc/SKILL.md`; `cat .claude/skills/game-vision-designer/SKILL.md`; `cat .claude/skills/game-vision-designer/resources/interview_questions.md`; `cat .claude/skills/game-vision-designer/resources/vision_templates.md`; `cat design_docs/README.md` | Read project rules in full, implementation-doc header/sections, command-checkable ACs, bounded searches, Python policy and feature-validation method. Starter-template pillars are explicitly suggestions. User's stricter one-doc/no-mutation scope applies. |
| V2 | Raw recipe, real-test calls and process boundary | `sed -n '1,16p' Makefile`; `sed -n '150,165p' Makefile`; `make --no-print-directory -n crew-console-test AILANG=runtime/bin/ailang`; `sed -n '50,65p' tests/test_crew_console.gd`; `sed -n '414,425p' tests/test_crew_console.gd`; `sed -n '150,192p' bridge/sim_bridge.gd` | Dry-run prints import, mkdir and unbounded `AILANG_BIN=... godot ... --script tests/test_crew_console.gd`; rc captured before grep; rc/error/zero-failure conjuncts; `test: crew-console-test`. Test calls `real_sim`; bridge calls `OS.execute_with_pipe`, stores `child_pid`. No live Godot/process-group conclusion. |
| V3 | Group-only production supervisor; crew zero summary rejected | `cat tools/script_gate.sh`; `premise_dir=$(mktemp -d /tmp/iter80-7ad-premises.XXXXXX)`; `zero_rc=0; sh tools/script_gate.sh crew-zero "$premise_dir/zero.log" 5 '^crew-console: 0 failures$' -- sh -c 'echo "crew-console: 0 failures"' > "$premise_dir/zero.out" 2>&1 \|\| zero_rc=$?`; `cat "$premise_dir/zero.out"`; `test "$zero_rc" = 1` | Comment at 10–12 excludes setsid/setpgrp; embedded Perl at **28** kills only negative root PGID; no wrapper cancellation trap. Finite probe: `summary 'crew-console: 0 failures' carries no nonzero count`, `zero_probe_rc=1`; assertion rc 0. Scratch `/tmp/iter80-7ad-premises.Uwrt7g`. This tests the predicate, not escaped-child cleanup. |
| V4 | Duplicated outer supervisor and existing tests | `cat mk/script-gates.mk`; `cat tools/test_script_gate.sh`; `rg -c '^case_ stub' tools/test_script_gate.sh`; `rg -n 'case_ (raw\|godot\|make-sim)\|stub=\|test-script-gate: ok' tools/test_script_gate.sh` | SG_SUP line 23 repeats group-only Perl; selftest 120 and drill 600 at 59/62. Existing bodies: 18 stub cases plus 6 Godot cases, `test-script-gate: ok ($n cases: $stub stub, ...)`. Existing ignored-signal/orphan assertions have 6-second ceilings. Read, not run. |
| V5 | Ratchet and crew baseline measured, with positive inventory control | `rg -n '^SCRIPT_GATE_BASELINE_ROWS' mk/script-gates.mk`; `rg -n '^crew-console-test' tools/script-gate-baseline.txt`; `SCRIPT_GATE_BASELINE_ROWS=118 sh tools/script_gate_lint.sh; rc=$?; printf 'lint_rc=%s\n' "$rc"; exit "$rc"`; `cat tools/script_gate_lint.sh` | Pin 118; baseline line 37 names crew-console/test script. **rc 0:** `249 --script invocations: 131 through $(SCRIPT_GATE), 118 on the baseline; 22 includes ...; 23 makefiles scanned`. Linter's own positive inventory control compares actual occurrences; classification requires SCRIPT_GATE before GODOT, baseline key is target/script. |
| V6 | Approved sprint, neutral-hygiene exception and prerequisite boundary | Read ledger decisions (`sed -n '141,299p' design_docs/stapledon-mission.md`, in bounded chunks); `sed -n '356,375p' design_docs/stapledon-mission.md`; `rg -n '^7ac\.\|^7ad\.' design_docs/stapledon-mission.md`; `sed -n '1,35p' design_docs/planned/r1/m4-7ac-serial-pin.md`; `sed -n '175,193p'` of that doc | D-22/D-66 approved; D-88 A explicitly permits net-0 hygiene/no negative pillar. Queue 520/521: 7ad prerequisite, 7ac parked. Revision-2 `bounded()` is a historical tree-at-cleanup starting point, with historical kh/ks evidence; it is not this checkout's recipe. |
| V7 | No existing tracked dedicated 7ad doc; serial belongs to another change | `git ls-files -- design_docs/planned/r1/m4-7ac-serial-pin.md design_docs/planned/r1/m4-7ad-bounded-script-supervisor.md`; `rg -n '_serial' ui/crew_console.gd tests/test_crew_console.gd` | Only 7ac doc listed (known-positive control for the absent 7ad path). `_serial` positive hits in `ui/crew_console.gd`, including static line 44 and tag line 265; no hit in the crew test. No serial behavior experiment performed. |
| V8 | Inherited controller repro, read without rerunning or signaling | `cat /tmp/iter80-supervisor-repro.py`; `cat /var/folders/kr/h0wr2sj94vd6ljtmsxv8jkt00000gn/T/iter80-supervisor-h9qquwf0/results.json`; `shasum -a 256` on those exact two files | Script sha256 `2e41147ef6e12f423e151fcb854696ee5108645ace7c939fbe95bcd88af88a4e`; JSON `7f7272b9dc71f77e56651163f13854e2f598e380d5fc6e7dcb8cc760ef735505`. Controller results: group arm `runner_rc=1, child_live_after=false`; escape arm `runner_rc=1, child_live_after=true, after_stat=Ss`; both timeout 2 s/rc 142. Script points at controller's `stapledons-godot-iter80` checkout, **not** this design checkout; no independent source-pin claim for that artifact. |
| V9 | Process access unavailable | `probe_rc=0; ps -o pid=,ppid=,pgid=,lstart=,stat= -p $$ \|\| probe_rc=$?; printf 'ps_rc=%s\n' "$probe_rc"; test "$probe_rc" = 0` | `operation not permitted: ps`, **ps rc 127**, positive self-identity assertion rc 1. **UNINFORMATIVE UNDER SANDBOX** for process cleanup. No escaped-child or Godot test launched by designer. |
| V10 | Fresh GitHub conflict checks unavailable | `gh pr list --repo sunholo-data/stapledons-godot --limit 30 --json number,title,headRefName`; same for `stapledons-design`; `gh api 'repos/sunholo-data/stapledons-godot/pulls/373/files?per_page=100' --jq '.[] \| select(.filename == "Makefile") \| {filename,patch}'`; same for 380 | Each attempted read: rc 1, `error connecting to api.github.com`. `command -v gh` positive control `/opt/homebrew/bin/gh`, jq `/usr/bin/jq`. Not an empty PR list and not verified hunk clearance. Named designer Agent wrapper PR readiness is inherited by the heavy designer only. |
| V11 | Static shell syntax and monotonic-clock primitive | `sh -n tools/script_gate.sh tools/test_script_gate.sh tools/script_gate_lint.sh`; `perl -MTime::HiRes=clock_gettime,CLOCK_MONOTONIC -e 'my $t=clock_gettime(CLOCK_MONOTONIC); die unless $t>0; print "monotonic clock: available\n"'` | rc 0; `monotonic clock: available`. This does not validate a candidate supervisor or cross-platform ps parser. |
| V12 | Canon and recent examples consulted | `git -C ../stapledons-design rev-parse HEAD`; `cat` canon `vision/core-pillars.md`, `vision/design-decisions.md`, `vision/open-questions.md`, `physics/relativity-spec.md`, `roadmap/r1-foundations.md`, `decisions/0001-engine-and-architecture.md`, `features/next/crew-assignment-system.md`; `rg -n '^##\|^###' ../stapledons-design/physics/higgs-bubble.md`; read its 1–100 and 549–570; read `lore/archive/README.md`; `git -C ../stapledons-design ls-files rejected`; read the rejection notices in those four files. Read recent planned 7ae/7md and implemented 7aa/rig-watchdog headers, alignment, problem and design sections. | Canon HEAD `586f0eb5`; six pillars as table above; RS §4 visual gates/§5 old-engine audit; HB one admitted invention and closed mass budget; M4 scripted journey/test bar; ADR sidecar NDJSON. Rejected notices concern dome/dual-coordinate interior approaches. No canon requirement for a test runner or new lore entry; no physics/player-facing change proposed. Example shape matches header, alignment, problem, ACs, estimates, risks, questions, deliverables and verification. |
| V13 | Final designer scope | `git --no-optional-locks diff --exit-code HEAD --`; `git --no-optional-locks status --short`; `git ls-files --others --exclude-standard`; `git diff --check`; `git diff --no-index --check /dev/null design_docs/planned/r1/m4-7ad-bounded-script-supervisor.md` | Existing tracked diff rc 0; status and untracked list contain only the requested new design path. Tracked whitespace check rc 0; new-file no-index check prints no whitespace errors (rc 1 denotes the new-file difference). No implementation/sprint/canon/mission changes or live gate claims. |
| V14 | Document structure and controller-block syntax | Scratch-only Python harness reads this doc, asserts its 12 required section headings, `Open questions: None` and no trailing whitespace; extracts the two `sh` fenced blocks to fresh `/tmp/iter80-7ad-doccheck-5xjrkf93/appendix-{1,2}.sh`; `sh -n` on each | Harness rc 0: `doc structure: 12 required sections; Open questions: None; no trailing whitespace`; `appendix shell syntax: 2 blocks, rc 0 each (not executed)`. No candidate tool or controller probe executed. |

## Appendix A: controller checks after implementation (UNMEASURED)

The command interfaces below are implementation deliverables, not installed tools in this designer turn. Invoke from a shell script with **`$1` = absolute isolated candidate clone**, **`$2` = its base commit before implementation**, never the canonical/attended checkout. ROOT must already contain the candidate; this block performs no checkout/add/commit/stash. All mutations performed by harness modes are confined to their new private copies. Keep artifacts for independent evaluation.

```sh
ROOT=$1
BASE=$2
case "$ROOT" in /*) ;; *) exit 2 ;; esac
test -f "$ROOT/Makefile" || exit 1
test -f "$ROOT/tools/test_bounded_run.pl" || exit 1
T=$(mktemp -d /tmp/iter80-7ad-check.XXXXXX) || exit 1
printf 'artifacts=%s\n' "$T"
git -C "$ROOT" rev-parse HEAD > "$T/head.txt" || exit 1
H() {
  mode=$1; shift
  hrc=0
  perl "$ROOT/tools/test_bounded_run.pl" "$mode" "$ROOT" "$T" "$@" || hrc=$?
  printf 'harness %s rc=%s\n' "$mode" "$hrc"
  test "$hrc" = 0 || exit 1
}
G() {
  cap=$1; shift
  grc=0
  perl "$ROOT/tools/test_bounded_run.pl" guard "$ROOT" "$T" "$cap" -- "$@" || grc=$?
  printf 'guard rc=%s\n' "$grc"
  test "$grc" = 0 || exit 1
}
H selftest
H mutants
H crew normal
H crew hang
H crew hup
H crew int
H crew term
G 30 make --no-print-directory -C "$ROOT" script-gate-lint
G 135 make --no-print-directory -C "$ROOT" script-gate-selftest
G 615 make --no-print-directory -C "$ROOT" script-gate-drill
G 135 make --no-print-directory -C "$ROOT" bounded-run-selftest
G 195 make --no-print-directory -C "$ROOT" bounded-run-drill
G 30 make --no-print-directory -C "$ROOT" python-guard
H audit "$BASE"
```

Set the selected `GODOT`/PATH in the controller shell if needed; real crew modes must preserve the test's real runtime choice. Harness reports must include make's actual rc captured immediately, before reading logs. A positive assertion must use `... || exit 1` (or an explicit harness assertion); never `! assertion`. Do not pipe command execution to a log filter and then call the filter's rc a gate result. The guardian must clean up on a failed assertion before returning. Inspect final scope against Files with BASE saved by controller before implementation, including byte comparisons of the unchanged crew test and baseline. Do not seed shared state to prove that shared state is unchanged.

## Appendix B: fresh conflict recheck (UNMEASURED)

From a controller shell, `$1` is again the isolated ROOT. Use structured JSON and files; no unrestricted `gh pr diff` terminal output. Check tools as well as Makefile, and use the full PR file arrays as positive controls for a negative hunk search.

```sh
ROOT=$1
case "$ROOT" in /*) ;; *) exit 2 ;; esac
test -f "$ROOT/Makefile" || exit 1
T=$(mktemp -d /tmp/iter80-7ad-prs.XXXXXX) || exit 1
git -C "$ROOT" rev-parse HEAD > "$T/head.txt" || exit 1
for repo in stapledons-godot stapledons-design; do
  rrc=0
  gh pr list --repo "sunholo-data/$repo" --limit 100 \
    --json number,title,headRefName > "$T/$repo.json" || rrc=$?
  printf '%s list rc=%s\n' "$repo" "$rrc"
  test "$rrc" = 0 || exit 1
done
for n in 373 380; do
  prc=0
  gh api "repos/sunholo-data/stapledons-godot/pulls/$n/files?per_page=100" \
    > "$T/$n.json" || prc=$?
  printf 'PR %s files rc=%s\n' "$n" "$prc"
  test "$prc" = 0 || exit 1
  jq -e 'type == "array" and length > 0 and length < 100' "$T/$n.json" >/dev/null || exit 1
  jq '[.[] | select(.filename == "Makefile" or .filename == "mk/script-gates.mk" or
    .filename == "tools/script_gate.sh" or .filename == "tools/bounded_run.sh" or
    .filename == "tools/test_bounded_run.pl") | {filename,patch}]' "$T/$n.json" || exit 1
done
printf 'conflict artifacts=%s\n' "$T"
```

If an array reaches 100, paginate before judging clearance. Read PR metadata/heads separately if their status changed, and inspect relevant files in any newly open PR before implementation/landing. A successful read is evidence of the returned hunks only, not a merge verdict.

## Controller pre-quorum factual corrections (2026-11-08)

Authoring subscription tokens are recorded, wrapper PR-read provenance is explicit, and the scope audit permits the mandatory named changelog/sprint/mission records separately from its five code/test paths. No runner decision changed. The controller banked V8's source and results in `.ailang/state/evaluations/repro_R1-7ad_iter80.json` for future re-derivation; its recorded historical PIDs are never signal targets.

## Quorum verification log (2026-11-08)

Round 1 at `34a83ec4`: **PROCEED degraded, one external reviewer present** (`gemini-4-argon` PASS); `oc-glm-5-3` and `oc-kimi-k3` absent (`unreachable` in synthesis, actual errors HTTP 429 Ollama session quota), `claude-sonnet-5@claude-p` absent (`quota`). Author OpenAI vendor benched. This is not a full three-seat pass. Artifact: `m4-7ad-bounded-script-supervisor-2026-11-08T04-16-39Z.json` in the mission quorum export. Cost $0.060768; 13,852 input / 268 output tokens.

Gemini non-blocking signal-registration fix, adopted verbatim before planning:

> In D2, specify that the wrapper shell spawns `bounded_run.sh` in the background, immediately captures `$!` before yielding or waiting, and verifies `(pid, lstart)` or uses a readiness pipe before forwarding trapped signals, or else kills the unconfirmed `$!` child directly and exits non-zero if a signal arrives before identity confirmation.

D2 therefore requires a pending cancellation flag before spawning and deterministic handling of cancellation before and after readiness; selftest must exercise the pre-registration window as well as the already-ready relay. The quoted reviewer fix specifies the implementation choice, and the executor/evaluator must verify the chosen branch by an actual directed-signal case. Existing budgets and ownership limits remain.


## Controller D1/D2 implementation clarification (2026-11-08, r20)

Native r19 full selftest was 41/42: the ready-INT wrapper received INT, but the inner runner recorded a typed polling inspection failure without an observed inner INT; registered descendants were absent. One separately instrumented private run passed, with actual inner INT about 108 ms after its fixture trigger and before its deadline. That diagnostic did not reproduce or attribute the native failure. Both results remain evidence.

D1's first-event rule applies when a polling acquisition returns as well as at the loop top: settle the fixed command deadline against the actual handler receipt timestamp before classifying a fully collected typed read/exit timeout. A signal received before the deadline retains its named event; a signal at/after the fixed deadline cannot replace TIMEOUT at that deadline. Earlier inspection errors, denied/malformed/execution errors and outstanding helpers remain hard 125. Successful timeout/cancellation still requires fresh closure and verified absence within the unchanged cleanup budget.

D2 permits the existing private `pending-signal` request file to carry the first named trapped shell signal in the confirmed path as well as the unconfirmed path. The outer relay's existing bounded poll consumes a valid request once, then performs the actual OS signal to its confirmed owned inner supervisor after a fresh identity check. This removes the extra first-hop Perl/PS acquisition; it introduces no shell signal to a potentially reaped PID. The unconfirmed captured-child TERM fallback remains. Readiness still proves installed handlers and actual held-command identities before exec release. The intermediate handoff need not itself be an OS signal; the actual trapped wrapper signal and actual inner OS signal/diagnostic remain mandatory evidence. Private requests must preserve the first named signal, not overwrite it during repeated traps.

Treat the pending-file path as an implementation refinement of D2's already approved readiness/pending-cancellation contract and adopted Gemini readiness fix. There is no new quorum result: the original one-external-seat PROCEED DEGRADED remains the only design quorum. No pillar, game, protocol, runtime or human-decision change is authorized.

Add bounded nested regression evidence to the existing auxiliary controls without changing fixed42 or auxiliary62 names: a held inspector in the last shortened polling window must yield TIMEOUT142 after fresh healthy cleanup; a private old-catch reversal must yield125. Actual late INT must not replace the earlier timeout, and an actual pre-deadline INT must remain130. A separately forced obsolete first-hop inspection failure must expose the old transport's lost inner INT while the private-request path still delivers actual innerINT/130. Compare actual statuses/timestamps, record leaks before independent cleanup, require no cap/void/inspection credit, restore private source bytes, and make every nested check mandatory for its enclosing auxiliary case. These are targeted regression controls, never substitutes for clean-first AC6 mutants or the full actual suite. Runtime outcomes remain UNMEASURED until outside checks run.

## Iteration 80 parked implementation record

The approved design and sprint remain planned. Independent implementation round 1 is FAIL47, implementation_approved=false. The final r21 M4 self-test is 41/42: rawmake-summary-hang fails on process inspection before its deadline barrier; no registered survivor or cap was observed. M3 is reopened, M4/M5 incomplete. No implementation round 2, code-head CI or code merge occurred. Unapproved source is preserved on backup/stapledon-iter80-7ad-final-unapproved-r21 at 6abbd8b2aaeb89fe737a72f25bb55625ba7ff74a. This record approves no source.

Resume engineering from that bank, resolve the evidenced inspection failure without weakening fixed bounds, run the complete final gates including clean-first mutations and real healthy-sim signal controls, then obtain independent implementation review and exact-head fast CI. No new human decision is required; all six OPEN ledger rows retain their existing defaults. Decision-bearing runtime history is in .ailang/state/evaluations/repro_R1-7ad_iter80.json; raw bulk artifacts remain at its named paths.
