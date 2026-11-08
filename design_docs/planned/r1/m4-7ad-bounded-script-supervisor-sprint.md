# Sprint plan: row 7ad bounded script supervisor

Planned 2026-11-08, unattended Stapledon iteration 80, HEAVY planner only. Implements [the accepted design](m4-7ad-bounded-script-supervisor.md), committed at `ffd9287cb39fb48a08459e833a7b5c3b93ae69df`, on implementation base `fa8480d55d55df7eccc3d16cf4f296e2357e327f`. Planning source is the detached sibling worktree `/Users/voightkampff/dev/sunholo-data/.planner-wt-iter80` at that LOCAL HEAD, not origin/main. No implementation or live acceptance is claimed here.

Goal: bound the actual raw crew-console recipe and both gate supervisors, retain observed escaped descendants through reparenting and ordinary exit, and prove cleanup with an independent guardian. Four serial implementable milestones plus one controller verification milestone; approximately 860 code/test LOC and 12 changelog lines, 5 h 45 min executor time including buffer, plus 60–100 min of controller boundary work and a separate 90 min final verification slot. Allow two working days including review, diagnosis and asynchronous CI/evaluation scheduling. Risk is high: portable process identity and cancellation races dominate the work, not recipe size.

## Authority, routing and current state

- D-22/D-66 already approve R1-M4-JOURNEY. D-88 A permits this neutral test hygiene with no negative pillar. Design Open questions=None: there are no human-decision gates for 7ad. Leave unrelated OPEN decisions D-128, D-129, D-145, D-146, D-147 and D-148 unchanged. Historical parent sprint approval questions/status are preserved, not reopened or resolved here.
- Design quorum round 1 is **PROCEED DEGRADED**, with ONE external `gemini-4-argon` PASS. GLM/Kimi were absent on HTTP 429 Ollama quota; Claude absent on quota; author OpenAI benched. This is not a full quorum pass. Adopt the final quoted signal-readiness fix below; do not rerun providers or claim new quorum evidence.
- Effective planner routing, independently rerun by the named planner wrapper before probe: `codex:gpt-6.1-sol declared:planner-lane-default-pin`. The wrapper invoked `codex exec --model gpt-6.1-sol`; the CLI banner confirms `model: gpt-6.1-sol` (Codex v0.167.0). Heavy planner rc 0, 81,299 quota tokens; bounded probe rc 0, 11,074 quota tokens; total 92,373. The model’s generic self-description is not used as exact model evidence. Fresh run artifacts: `/tmp/stapledon-iter80-planner.aTMCZi/`, pinned source HEAD in `source-head.txt`. Executor/evaluator routing and capacity remain controller responsibilities; generator must differ from judge.
- Read `CLAUDE.md` completely and `/Users/voightkampff/.claude/skills/sprint-planner/SKILL.md` plus its registry gate, plan template and coordinator resources. Mission-specific instructions supersede script creation, registry/message calls, approval prompts, handoff and git writes. No additional agents, external sends, shared message imports, inbox calls or `create_sprint_json.sh`.
- Current committed dashboard is iteration 79: 7ad still undone/PARKED-ON-LANE, 7ac follows it; clauses 1–3 MET, 4 UNMET, 5 ongoing. This is historical source status, not a new claim about active launchd, provider capacity or PR state. The accepted iteration-80 design and supplied routing now authorize this planning step. No mission records changed by planner.
- Static source: `tools/script_gate.sh` 60 lines, embedded group-only Perl at line 28, no signal relay; `mk/script-gates.mk` 62 lines, duplicated group-only `SG_SUP` at line 23, outer caps 120/600. `Makefile` 1,497 lines; restrict its change to the crew-console recipe at lines 158–160. Raw invocation has import, rc/error/exact-zero-summary conjuncts and `test` membership. New `tools/bounded_run.sh` and `tools/test_bounded_run.pl` are absent, as intended. The large Makefile is existing structure; no companion file outside the five-path scope is authorized.
- Parent JSON currently has 28 features; prior feature records are schema precedent, not current test-count evidence. Append only `M4.6wR3_7ad_BOUNDED_SCRIPT_SUPERVISOR`, planned/passes=false; preserve the previous 28 and every other top-level value, including status, completion, velocity and approval metadata.

Controller evidence, read only: `/tmp/iter80-base-results.json` records import rc 0 / 16.7 s and baseline rc 0 / 52.9 s. Bounded summary reads of its baseline log confirm `crew-console: 0 failures`, 18 stub cases, inventory 249 total / 131 gated / 118 baseline, four prerequisite pairs, uid 419, Python 21. The required 24-total script-gate drill was NOT in that baseline. A later controller run outside sandbox at `ffd9287c` (production bytes unchanged from `fa8480d5`) measured `make script-gate-drill AILANG=runtime/bin/ailang` rc 0 / 26.2 s, `test-script-gate: ok (24 cases: 18 stub, 6 Godot)`; fresh artifacts `/tmp/iter80-base-drill-result.json` and `/tmp/iter80-base-script-gate-drill.log`. All pinned existing targeted gates are now green before execution. Accepted design V8 records group cleanup versus escaped-child leakage; it is inherited controller evidence, never permission to signal its historical PIDs. Reproduction record is `.ailang/state/evaluations/repro_R1-7ad_iter80.json`. Current missing candidate commands are INTENDED RED, not environment failures. All new runtime gates remain UNMEASURED.

Recent scoped velocity was read from local git, 2026-11-01 through 2026-11-08, nonmerge commits touching `tools/script_gate.sh`, `tools/test_script_gate.sh`, `tools/script_gate_lint.sh`, `tools/script_gate_prereqs.sh`, `mk/script-gates.mk`: 15 commits, 365 insertions / 21 deletions (net 344). The visible implementation burst is November 4–6, about 122 inserted LOC per active calendar day, or 46 per day across the eight-day window; neither is measured labor throughput. Examples: `175bfe84` adds helper/stub bodies 43+65 lines, `3d9c4d5b` adds 46 wiring lines, `204b4fbd` adds 17+7 zero-count lines, `eba3705e` adds 27 prerequisite-tool lines, `da7afacf` preserves pin 118. Recipe migrations and baseline deletions are poor predictors of new process-control complexity. Estimates therefore exceed the design's 600–700 total rather than claiming its 400–450 LOC M1 fits one run. Design M1 becomes this plan's M1+M2 (450 LOC); expanded integration and adversarial fixtures account for the remaining 410.

## Exact scope and record allowlist

Implementation/test paths, exactly five:

1. `tools/bounded_run.sh` (new shell entry, embedded Perl production runner).
2. `tools/test_bounded_run.pl` (new independent guardian, all generated fixtures, mutations, probes and audit).
3. `tools/script_gate.sh` (supervisor replacement and bounded signal relay only).
4. `Makefile` (crew-console recipe only, including its relay).
5. `mk/script-gates.mk` (variables, guard invocations and target prerequisites).

Mandatory sixth implementation deliverable: `changelogs/unreleased/2026-11-08-bounded-script-runner.md`, opening `### `, describing behavior and its limits without unmeasured success claims. Executor may draft this named fragment; controller owns final records and landing. No new example file: the committed harness and its named cases are executable working examples once verified.

AC11 must enumerate these exact separately permissible bookkeeping paths; no directory-wide exemption:

- `design_docs/planned/r1/m4-7ad-bounded-script-supervisor.md`
- `design_docs/planned/r1/m4-7ad-bounded-script-supervisor-sprint.md`
- `design_docs/implemented/r1/m4-7ad-bounded-script-supervisor.md`
- `design_docs/implemented/r1/m4-7ad-bounded-script-supervisor-sprint.md`
- `.ailang/state/sprints/sprint_R1-M4-JOURNEY.json`
- `.ailang/state/evaluations/repro_R1-7ad_iter80.json` (existing controller source record)
- `.ailang/state/evaluations/eval_R1-M4-JOURNEY_7ad_round_1.json` (reserved controller evaluation record; no result asserted)
- `.ailang/state/evaluations/eval_R1-M4-JOURNEY_7ad_round_2.json` (explicitly reserved before final audit for independent corrective review; no result asserted)
- `.ailang/state/evaluations/eval_R1-M4-JOURNEY_7ad_round_3.json` (explicitly reserved before final audit only if the third and final independent round is required; no result asserted)
- `.ailang/state/evaluations/eval_R1-M4-JOURNEY_7ad_publication_iter80.json` (explicitly reserved before final audit for independent review of final mission records after the actual code outcome; distinct from implementation rounds, no result asserted)
- `changelogs/unreleased/2026-11-08-bounded-script-runner.md`
- `design_docs/stapledon-mission.md`
- `design_docs/stapledon-mission-log.md`
- `design_docs/stapledon-mission-index.md`
- `design_docs/stapledon-mission-dashboard.md`
- `design_docs/stapledon-mission-status-archive.md`
- `design_docs/stapledon-mission-log-archive.md`

If a further evaluation round needs another record name, controller explicitly enumerates it before audit; this does not authorize another code file. Design is immutable during planning; planned-to-implemented moves occur only at controller landing. This planner writes only this plan and the single appended JSON feature.

Byte-protect `tests/test_crew_console.gd`, `tools/test_script_gate.sh`, `tools/script_gate_lint.sh`, `tools/script-gate-baseline.txt` against BASE, along with unchanged fixtures and all other out-of-scope source. Preserve crew baseline row 37, pin 118, four prerequisite pairs, 18-stub/24-total bodies and existing 6 s ceilings. No `.ail`, physics, packages, `.gd`/`.uid`, Python, audio, `_serial`, bridge/runtime/protocol, assets, scenes or lockfile edits. Stop for a new design if cleanup requires bridge/runtime/protocol changes. Gate red at pristine base is a finding to report; never work around it, suppress predicates or raise assertion ceilings. Changed-head PR #373/#380 and all other overlapping PR hunks require controller's fresh Appendix B check before build and landing, including complete file-array positive controls and pagination at 100.

## Contracts carried into every boundary

Production D1: `sh tools/bounded_run.sh N -- command [args ...]`, positive whole-second N and nonempty command, usage 2 before launch. Shell execs embedded Perl, which uses `exec env` with an argument array. Preserve leading assignments, `env -u`, spaces/empty/metacharacter arguments, stdin, cwd and separate output streams. Monotonic deadline starts at entry. Held-child handshake installs supervisor handlers and confirms identities before exec; reset inherited ignored INT in the child. First cancellation wins; handlers set flags only.

Snapshot `LC_ALL=C ps -axo pid=,ppid=,pgid=,lstart=,stat=` at most 100 ms apart subject to cost. Acquisition itself is asynchronous, nonblocking, capped at 200 ms or remaining phase budget; collect only the direct helper using WNOHANG. Validate supervisor and held-child positive identities; denied/absent/malformed tables are inspection failure, not absence. Retain observed `(pid,birth)` descendants after PGID change/reparenting, retire changed/disappeared identities and never expand through stale PIDs. Identity check precedes EVERY individual STOP/TERM/CONT/KILL. Exclude supervisor/helpers/unrelated processes; no cached group broadcasts, name sweeps or stale groups.

Cleanup after cancellation AND ordinary exit: one total 3 s budget, freeze top-down, refresh closure for at most 250 ms while parents stopped, freeze newly observed descendants, TERM+CONT, at most 2 s grace within budget, KILL remaining matching identities, bounded WNOHANG/probes throughout. Continue after command exit; preserve original direct-child status. Stopped children always receive CONT or KILL on any exit path. Grandchild zombie is dead but not portably reapable on macOS; report accurately. Timeout cleanup ends at original deadline+3, signal cleanup at first delivery+3; command assertions allow one extra second. No-survivor ordinary exit returns promptly.

| D1 event | Required runner rc/evidence |
|---|---|
| Ordinary exit | Exact 0, 7, 127, 142; ordinary 142 has NO timeout diagnostic |
| Child self-TERM, uncancelled supervisor | 143 |
| Timeout | 142 and `bounded-run: timeout after N s` |
| HUP / INT / TERM | 129 / 130 / 143 and named interruption |
| Usage | 2; no child launched |
| Setup/inspection failure or living owned survivor at deadline | 125 with diagnostic after bounded cleanup attempt |

Polling covers retained observed descendants, not arbitrary unseen double-forks. Second-resolution birth identity and observation-to-signal races remain documented limitations; do not silently broaden the guarantee.

Adopt the reviewer instruction verbatim:

> In D2, specify that the wrapper shell spawns `bounded_run.sh` in the background, immediately captures `$!` before yielding or waiting, and verifies `(pid, lstart)` or uses a readiness pipe before forwarding trapped signals, or else kills the unconfirmed `$!` child directly and exits non-zero if a signal arrives before identity confirmation.

D2 wrapper contract: set pending-cancel handling BEFORE spawn; capture `$!` immediately; implement the quoted safe branch for pre-confirmation cancellation, then readiness-confirmed relay only to the owned supervisor. Deterministic test barriers must hold the wrapper in the pre-registration window and after ready, and send actual directed HUP/INT/TERM to runner, script-gate shell, raw recipe shell and foreground make group as applicable. Do not substitute a sleep race, timeout-only case or synthetic cancellation flag. Include inherited-ignored-INT and repeated TERM→INT/HUP; first event and deadline stay fixed. Keep tests and barriers inside the named harness/private fixtures and existing implementation paths.

Trap-interrupted wait is not final child status. Completion flag plus watchdog has absolute N+4 deadline, shortened to at most first-relay+4, never extended by repeated signals. Every wait, including watchdog collection, is bounded; no unconditional second wait. Overrun only signals/collects still-owned supervisor, returns failure and keeps diagnostic. Track cancellation separately from rc/summary/WANT_RC; printed success or a matching WANT_RC can never mask cancellation. Clear traps after collection. Default crew N=300 means cleanup ≤303, assertion ≤304, import excluded from runner deadline but included by outer controller guard.

D3/D4 guardian cannot call or source candidate bounded_run, script_gate or SG_SUP as its own watchdog. Absolute isolated ROOT and artifact parent required; each invocation creates fresh private mode-0700 `7ad-*` artifactdir, prints it and retains ROOT HEAD, logs/results. No HOME or shared mission-state writes. Missing ROOT/unwritable artifact parent fails before children. Register fresh parent AND child PID, birth, nonce and parent identity while relation exists, acknowledge before escape. Same ps probes must positively see guardian and live owned sentinel. Preserve pre/post identities; ready marker/kill-0 alone is insufficient.

Use finite absolute monotonic fixture lifetimes, WNOHANG, nonblocking readiness, pipe drains, probes, worker/command waits and cleanup. Cap has separate 3 s cleanup budget. Record candidate leaks BEFORE guardian cleanup; kill only matching registered-owned identities or private live-owned group whose leader identity remains held; collect direct children. No pkill, host-name scan or historical artifact PIDs. Guardian cap is FAIL, never mutant credit. Inspection or Godot denial/void escaped-PGID premise returns harness 3 / UNINFORMATIVE UNDER SANDBOX after safe cleanup, never a pass/fail absence claim. Ordinary independent guard returns true normalized child status; cap returns distinct 124 and diagnostic. No invented runtime or case-count claims.

## Milestones, dependencies and reversible controls

Every M is planned, not passed. Executor owns code/static syntax/schema/scope only; controller owns all process/Godot acceptance OUTSIDE SANDBOX and all commits/reconstruction. No executor git writes. Each M ends with a cumulative snapshot even if some later contract is intentionally RED. Intentional partial states never mark the feature passed. Before M1 controller saves BASE, verifies pristine targeted gates (including the later-measured 24-case drill) and refreshes conflict hunks. An unexpected pristine gate red is reported and resolved separately, not hidden in this work.

| M | Specific deliverable/files | Estimate incl. tests | Buffered executor slot | Depends on | Controller boundary |
|---|---|---:|---:|---|---|
| M1 | Independent guardian, registration/positive controls, private fixtures and guard status/cap tests in `tools/test_bounded_run.pl` | 220 test/glue LOC | 65+20=85 min | Accepted D3/D4 and external process access | Guard normalization/cap/cleanup controls and protected-source gates; later runner/integration still RED |
| M2 | Complete D1 `tools/bounded_run.sh`; harness runner status/transport, timeout, signal, reparenting, sentinel cases in `tools/test_bounded_run.pl` | 160 production +70 test=230 LOC | 70+20=90 min | M1 | AC1–AC4 runner cases GREEN; wrapper/RawMake cases still causal RED |
| M3 | D2 relays in `tools/script_gate.sh` and crew-only `Makefile`; variables/independent SG_SUP/targets in `mk/script-gates.mk`; RawMake/relay cases in harness | 110 production/wiring +65 test=175 LOC | 60+20=80 min | M2; existing gates green | Full selftest AC1–AC5 GREEN; existing targeted gates/graph unchanged except added selftest |
| M4 | `tools/test_bounded_run.pl` private real-sim/mutant/audit modes, fixed expected names and restoration; named changelog | 235 test LOC +12 fragment lines | 70+20=90 min | M3 | AC6–AC11 implementations ready; real/mutation results require outside-sandbox controller run |
| M5 | Run-only controller acceptance, independent evaluation, CI, conflict/scope/byte-fidelity and landing records | 0 code LOC | 90 min controller gate slot; async CI/judge separate | M4, restored snapshots | All AC1–AC11 measured; pass only on actual candidate evidence |

M1 tasks: make guard independently execute `sh -c 'exit 7'` and preserve rc 7; ordinary 0/142 and signalled child preserve normalization; a finite 10 s private command under cap 1 returns 124 with cap diagnostic and cleanup. Reverse a private guard status-normalization copy to return zero: the status control must reject it, restore and cmp. Register same-group/setsid parent-child fixtures with two positive observations, independent finite lifetimes and guardian/sentinel controls before any fault. Bounded inspection-denial control must return 3 with safe cleanup. At this boundary full `selftest` is expected nonzero for explicitly named not-yet-implemented runner/integration cases; no skip that yields green. Existing gates remain green and untouched. Examples are guard commands and named `guard-status7`, `guard-cap`, `guardian-positive-identities` cases in the committed harness.

M2 tasks: write runner cases first against missing/old group-only scratch runner, record missing-tool intended RED and actual escaped-timeout/escaped-interruption causal RED under independent guardian. Implement D1, then require runner cases GREEN with exact rc/diagnostic, absence and elapsed assertions. Named examples include `runner-exit0`, `runner-exit7`, `runner-exit142`, `runner-missing127`, `runner-child-term143`, `runner-timeout-escaped`, `runner-parent-exit7-retained`, `runner-hup`, `runner-int`, `runner-term`, `runner-first-signal-wins`, transport and usage cases. Parent-exit fixture releases parent only after at least two positive observations; no-retention reversal must expose child survival. H selftest still returns 1 for specified unintegrated wrapper/RawMake expectations; classify result names, never waive required cases. Protected existing gates stay green.

M3 tasks: write real RawMake and deterministic relay tests before integration. With stub Godot+AILANG and N=2, summary-then-hang must be RED against raw recipe and GREEN only after bounded cleanup. Independently direct signals before registration and after ready to wrapper shells and make group; a private no-relay mutation must fail named interruption absence assertions, even if a summary is already printed. Production runner bypass must fail raw hang/deadline cleanup. Restore each private mutation with cmp before snapshot. Never transiently relax rc/error/summary/zero-count/WANT_RC predicates to obtain a checkpoint. Define `BOUNDED_RUN = sh $(SG_TOOLS)/bounded_run.sh`, `CREW_CONSOLE_TIMEOUT_S ?= 300`, `BOUNDED_TEST_ARTIFACTS ?= /tmp`; replace SG_SUP with `perl $(SG_TOOLS)/test_bounded_run.pl guard "$(CURDIR)" "$(BOUNDED_TEST_ARTIFACTS)"`, preserve 120/600 caps, add `--` at both invocations. Remove fixed SCRIPT_GATE_TMP prefixes; guard supplies fresh private paths. Add .PHONY bounded targets; test and ci-fast reach selftest only, drill calls mutants and stays targeted. No real-sim aggregate dependency. Examples: `rawmake-pass`, `rawmake-rc7`, `rawmake-error`, `rawmake-nosummary`, `rawmake-summary-hang`, `relay-prereg-*`, `relay-ready-*` expanded to fixed HUP/INT/TERM names in the harness.

M4 tasks: finish modes exactly below, building real fixtures only in private copied project/runtime/resource/assets. Clean candidate runs first in mutants; assert byte change for each mutation or return 3. Old/group-only must fail BOTH escaped timeout and interruption absence; no-retention must fail parent-exit/reparenting; no-interruption/no-relay must fail actual directed wrapper interruption; bypass must fail real RawMake hang/deadline cleanup. Assert named behavioral failure plus actual rc, never accept cap/inspection failure as kill. Require fixed expected case-name set, including all signals and pre-registration cases, so deletion fails; restoration cmp runs even on error. Add audit with tracked+untracked union, exact record classes, BASE comparisons and actual make graph. Changelog opens ###. Full runtime is still UNMEASURED until controller runs it. If estimates overrun, split a remaining cohesive task within these paths into another ≤250 LOC/≤90 min run before execution; preserve contracts and record real size/time. Do not invent a bridge change or broaden scope.

M5 tasks (controller only): reconstruct and verify each boundary as described below, then run all AC commands in isolated runtime-capable ROOT, inspect captured status/evidence and restored bytes, run changed-head conflict checks again. Obtain independent cross-family evaluation and actual PR-head GitHub fast-tier success. Pending CI, quota, denied process access or missing real drill remain gaps, never passes. No make test, local ci-fast/full-suite, GPU, rig or quiet-host gate is required. The historical unrelated nightly red remains recorded separately. Only after all required evidence may controller mark this feature passed, commit final records and land; never complete the parent sprint. Row 7ac resumes after 7ad lands using its separate resume predicate.

## Concrete M2 partial-mode boundary validator (UNMEASURED)

The following is an executable **controller-side harness/metadata check**, not an added production mode and not an assertion skip. Save this fenced block in a fresh external file and invoke `sh /absolute/path/to/m2-boundary-check.sh /absolute/isolated/candidate/ROOT`. All 42 fixed selftest cases must run, with the same names retained after integration. M2 requires actual full-selftest rc 1, the 17 explicitly named integration failures only, and all 25 runner/ordinary cases passed. At M3 every one of these same cases must pass and full selftest must return 0; this M2 validator must consequently reject an already-integrated M3 candidate. If actual unchanged wrappers give a different failure set, report the mismatch and reconcile with controller before claiming M2; never change recorded outcomes, loosen the set or remove a case merely to pass this metadata check.

The committed harness adds these concrete report-field spellings to D4's retained evidence: one stdout line `artifacts=/absolute/private/7ad-*`; top-level `mode`, `worker_cap_fired`, `inspection_restricted`, `void_fixture`, and `cases`. Every case has `name`, boolean `passed`, integer `actual_rc`, boolean `guardian_cap_fired`, `inspection_restricted`, `void_fixture`, and `cleanup_outcome`, besides D4's trigger/elapsed/pre-post identities/inner make rc. A candidate leak is recorded as a failure before independent cleanup; the final cleanup outcome must confirm no live registered survivors. A guardian cap, denial or void fixture cannot satisfy an expected deferred failure. The stage predicate runs no candidate supervisor of its own and cannot turn a full RED mode into GREEN. Its missing tool on base is intended RED.

```sh
ROOT=$1
case "$ROOT" in /*) ;; *) exit 2 ;; esac
P=$(mktemp -d /tmp/stapledon-iter80-M2.XXXXXX) || exit 1
chmod 700 "$P" || exit 1
touch "$P/started" || exit 1
M2_RC=0
perl "$ROOT/tools/test_bounded_run.pl" selftest "$ROOT" "$P" > "$P/selftest.out" 2>&1 || M2_RC=$?
printf 'M2 selftest actual rc=%s artifacts-parent=%s\n' "$M2_RC" "$P"
if [ "$M2_RC" = 3 ]; then
  printf '%s\n' 'UNINFORMATIVE UNDER SANDBOX: retain evidence; M2 not accepted'
  exit 3
fi
test "$M2_RC" = 1 || exit 1
python3 - "$P" <<'PY'
import json, re, stat, sys
from pathlib import Path
p = Path(sys.argv[1]).resolve()
reported = re.findall(r'^artifacts=(/[^\n]+)$', (p/'selftest.out').read_text(), re.M)
assert len(reported) == 1, 'require one fresh harness artifact announcement'
run = Path(reported[0])
assert not run.is_symlink() and run.resolve().parent == p
assert run.name.startswith('7ad-') and stat.S_IMODE(run.stat().st_mode) == 0o700
result = run/'results.json'
assert result.is_file() and not result.is_symlink()
assert result.stat().st_mtime_ns >= (p/'started').stat().st_mtime_ns
data = json.loads(result.read_text())
assert data['mode'] == 'selftest' and data['worker_cap_fired'] is False
assert data['inspection_restricted'] is False and data['void_fixture'] is False
runner = {
 'runner-exit0','runner-exit7','runner-exit142','runner-missing127',
 'runner-child-term143','runner-transport','runner-usage',
 'runner-timeout-same-group','runner-timeout-escaped','runner-timeout-parent-first',
 'runner-hup','runner-int','runner-term','runner-parent-exit7-retained',
 'runner-first-signal-wins','runner-inherited-ignored-int','guardian-positive-identities'
}
ordinary = {
 'gate-counted-pass','gate-want1','gate-zero-reject','gate-timeout-same-group',
 'rawmake-pass','rawmake-rc7','rawmake-error','rawmake-nosummary'
}
deferred = {
 'gate-timeout-escaped','rawmake-summary-hang',
 'gate-relay-prereg-hup','gate-relay-prereg-int','gate-relay-prereg-term',
 'gate-relay-ready-hup','gate-relay-ready-int','gate-relay-ready-term',
 'raw-relay-prereg-hup','raw-relay-prereg-int','raw-relay-prereg-term',
 'raw-relay-ready-hup','raw-relay-ready-int','raw-relay-ready-term',
 'raw-make-group-hup','raw-make-group-int','raw-make-group-term'
}
cases = data['cases']
assert isinstance(cases, list) and len(cases) == len(runner|ordinary|deferred)
names = [c['name'] for c in cases]
assert len(names) == len(set(names)) and set(names) == runner|ordinary|deferred
for c in cases:
 assert type(c['passed']) is bool and type(c['actual_rc']) is int
 assert c['guardian_cap_fired'] is False and c['inspection_restricted'] is False
 assert c['void_fixture'] is False, c['name']
 assert c['cleanup_outcome'] == 'no_live_registered_survivors', c['name']
failed = {c['name'] for c in cases if not c['passed']}
assert failed == deferred, ('unexpected M2 failures/passes', failed ^ deferred)
assert all(c['passed'] for c in cases if c['name'] in runner|ordinary)
print('M2 boundary MET: 25 required runner/ordinary cases passed; exactly 17 named integration failures; full selftest remains RED; no cap/void accepted')
print('retained results='+str(result))
PY
```

## Snapshots and controller reconstruction

At each cumulative M1–M4 boundary executor writes `/tmp/stapledon-iter80-executor-snapshots/M#/{FILES.txt,RESULT.txt,<full repo-relative files>}`; M5 controller preserves the verified cumulative snapshot and final RESULT. FILES.txt lists every created/modified deliverable so far, including plan/feature JSON and fragment when introduced; preserve original bytes and paths, no patches or partial snippets as substitutes. Include prior milestone file contents, not only the newest edits. RESULT.txt states commands, immediately captured rc, expected and actual case statuses, elapsed times if measured, mutations/restoration, outstanding intentional RED cases, environment restrictions and scope checks. Static-only work explicitly says runtime UNMEASURED. Do not populate fabricated results.

Controller independently calculates sha256 manifests before reconstruction, copies each cumulative boundary into its own isolated clone, verifies byte equality against the snapshot, then runs relevant targeted gates outside sandbox and owns each milestone commit. Record zero byte mismatches before claiming a reconstructed result. M1 needs independent guard controls plus existing lint/selftest/drill; M2 adds runner controls; M3 adds full selftest, functional RawMake, bounded target graph and existing lint/selftest/drill; M4/M5 add mutation/real modes/audit. Each boundary records its actual HEAD and exact statuses. Preserve causal RED controls as evidence and their restored GREEN versions. Full candidate H selftest remains expected failure until M3 integration; full audit/real/mutants interfaces complete at M4. Controller may use named results from a failing partial selftest to verify earlier completed contracts, but cannot report the full mode green. Budget 15–25 controller minutes per reconstructed boundary; actual durations are evidence, not these planning estimates.

## Command interfaces, ownership and evidence

All commands below are CONTROLLER OUTSIDE SANDBOX. Executor may do static `sh -n`, `perl -c`, JSON/schema/diff/scope checks only. ps/socket/Godot acceptance inside workspace-write is **UNINFORMATIVE UNDER SANDBOX**. Missing proposed tools on base are expected RED. No runtime gate was run by planner.

`H`/`G` use the exact Appendix A scaffold below. Each invocation creates its own fresh private artifactdir and writes `results.json`: fixed case name, actual command rc, trigger, monotonic elapsed, pre/post identity observations, cleanup outcome, exact inner make rc where applicable, ROOT HEAD and artifact path. H modes return 0 only when expected assertions hold, 1 assertion failure, 2 usage, 3 void/inspection restriction after safe cleanup. Guard returns actual normalized child status, cap124 distinct. A cap firing fails acceptance, including mutants. Keep raw make rc captured before log inspection; no tee/grep/filter status substituted.

| Mode | Worker hardcap | Required result and evidence |
|---|---:|---|
| `selftest ROOT ARTIFACT_PARENT` | 120 s | Status 0/7/142/127, childsignal143, HUP129/INT130/TERM143, usage2, transport/env/stdin/stdout/stderr, setup/inspection125; N=2 ignored-signal same-group and escaped timeout rc142 ≤6 s, interruption cleanup ≤4 s, observed-parent-exit7 child absent, sentinel untouched. Gate timeout rc1 and relay failures with counted summary, counted pass/WANT_RC=1 pass, zero-count refusal. RawMake cases below; fixed case set. |
| `mutants ROOT ARTIFACT_PARENT` | 180 s | Clean GREEN first; group-only, no-retention, no-interruption/relay and recipe bypass yield specified named failures with actual rc and independent cleanup; byte change and cmp restoration required. |
| `crew ROOT ARTIFACT_PARENT normal` | 480 s | Actual `make --no-print-directory -C ROOT crew-console-test AILANG=ROOT/runtime/bin/ailang`, no GODOT override: make0, original exact summary, no FAIL/SCRIPT ERROR:, registered real sim/Godot absent after completion. |
| `crew ROOT ARTIFACT_PARENT hang` | 240 s | Private copied real-sim fixture, N=60, actual make2, timeout diagnostic and script-launch-to-return ≤64 s; no registered real sim/Godot alive. |
| `crew ROOT ARTIFACT_PARENT hup`, `int`, `term` | 240 s each | Healthy readiness/identity probes then actual directed foreground-make-group signal; exact platform make status recorded, require nonzero/interruption/no green verdict, cleanup ≤4 s after delivery. |
| `audit ROOT ARTIFACT_PARENT BASE` | 30 s | Diff BASE plus untracked nonignored paths in five-code/named-record allowlist; report classes separately. Materialize BASE protected crewtest/scriptgatetest/lint/baseline and cmp. Capture make -qp and rc directly (0/1 usable, 2 error), traverse actual test/ci-fast prerequisite graph to bounded-run-selftest; drill stays targeted. |
| `guard ROOT ARTIFACT_PARENT CAP -- command [args ...]` | CAP | Independent watchdog, fresh private SCRIPT_GATE_TMP, true normalized command status, cap124 diagnostic, safe registered-identity/private-live-group cleanup ≤3 s after cap. |

RawMake selftest invokes REAL make against ROOT with private executable Godot stub and private no-op AILANG; stub import exits0, script verifies AILANG_BIN is that actual stub and args name `tests/test_crew_console.gd`. Summary+rc0 → actual make0; rc7+summary, SCRIPT ERROR:+summary and noSummary → actual make2. Summary then hang, N=2 → make2 ≤6 s after script launch and escaped child absent. Direct recipe-shell and make-group signals before registration AND after ready must fail/clean up even after summary. Raw success with SCRIPT_GATE overridden to nonexistent private path proves no migration. These are functional tests, not source-pattern checks.

Synthetic real fixture copies candidate project/resource files including .uid, required runtime/cache/assets from explicit ROOT, with no editable symlinks or shared mission state. Replace ONLY private copied crewtest with tiny SceneTree retaining SimBridge member; successful start() and new_game, healthy actual handshake, ready record with actual child_pid, print original zero-failure summary, remain in event loop without quit/stop. Register/observe Godot and sim while relationship exists, validate real child identity, then SIGSTOP only that healthy owned sim and verify stopped. Observe different real PGID; absent premise returns3/void, never invent an escape. No fake protocol simulation. Synthetic import has independent120 s cap; readiness ≤30 s from script launch; make cap70 s with CREW_CONSOLE_TIMEOUT_S=60 inside overall240. Restore substituted scratch test and cmp on every exit; original ROOT byte-identical.

| Acceptance | Owner/milestone | Concrete commands and required statuses/evidence |
|---|---|---|
| AC1 | Controller M2/M3/M5 | `H selftest`: exact D1 status/transport/usage cases; full mode0 after M3, named runner assertions green at M2. |
| AC2 | Controller M2/M5 | `H selftest`: N2→142 ≤6 s, same-group/escaped positive identities before and absence after, parent-dies-first covered. |
| AC3 | Controller M2/M3/M5 | `H selftest`: runner129/130/143, all wrappers fail; actual signals before registration and after ready; prior summary cannot hide cancellation; ≤4 s cleanup. |
| AC4 | Controller M2/M5 | `H selftest`: ordinary parent exit7 retained, escaped child absent after reparenting, unrelated owned sentinel alive until guardian cleanup. |
| AC5 | Controller M3/M5 | `H selftest`: actual real-Make stub statuses0/2 and summary-hang make2 ≤6 s; raw success despite nonexistent SCRIPT_GATE. |
| AC6 | Controller M4/M5 | `H mutants`: clean green, named causal mutant reds, no cap/inspection kill credit, actual rc, registered cleanup and cmp-restored bytes. |
| AC7 | Controller M5 | `H crew normal`: make0, original crew summary/test/predicate and real-runtime selection unchanged; identity evidence. |
| AC8 | Controller M5 | `H crew hang`: make2, actual timeout ≤64 s, no live registered Godot/sim. |
| AC9 | Controller M5 | `H crew hup`; `H crew int`; `H crew term`: record exact platform nonzero make rc; cleanup ≤4 s and interruption diagnostics, no green verdict. |
| AC10 | Controller every applicable reconstructed boundary, final M5 | `G 30 make --no-print-directory -C "$ROOT" script-gate-lint`; `G 135 make --no-print-directory -C "$ROOT" script-gate-selftest`; `G 615 make --no-print-directory -C "$ROOT" script-gate-drill`: each actual make0. Unchanged18 stub/24total,249/131/118,four pairs; no ceiling changes. |
| AC11 | Controller M3 wiring/M4 audit/M5 final | `G 135 make --no-print-directory -C "$ROOT" bounded-run-selftest`; `G 195 make --no-print-directory -C "$ROOT" bounded-run-drill`; `G 30 make --no-print-directory -C "$ROOT" python-guard`; `H audit "$BASE"`: each make0/harness0, Python21 unchanged, actual graph traversal and protected-byte comparisons including untracked scope. |

All measured counts are from current source/controller baseline, not old sprint records. Reconcile separately landed changes explicitly at controller landing and rerun affected targeted gates; this work does not authorize baseline migration. Do not fabricate final inventory or unchanged counts after a changed head.

## Reuse, schedule and completion

For every implementable M1–M4, `registry_reuse` is `action:none`, `package:null`, reason: existing repository-specific shell/Perl process-test glue, no package-like capability or .ail module; registry searches are inapplicable. M5 is verification-only with the same no-package decision recorded for consistency. No registry calls. AILANG teaching prompt gate is not applicable because no .ail is written; contracts/effects/inline tests for .ail showcase modules are likewise not applicable. Named harness cases above are planned working examples; no fabricated examples file or runtime pass count.

Day 1: controller pristine/conflict preflight, M1 then M2, preserving partial causal RED evidence and cumulative snapshots. Day 2: M3 then M4, controller reconstructed-boundary gates, M5 complete acceptance and independent evaluation/PR-head fast tier. Execution slots contain about 25–30% contingency; external scheduling is separate. Scope overrun, unsupported ps, survivor125 or base red must be reported with evidence, without relaxing behavior. No additional human approval is introduced by this plan under the existing rulings.

Completion requires all AC1–AC11, fixed-name mutation discrimination, private-file restoration, five-code-path scope plus named fragment/records, sha256-faithful boundary reconstruction, actual prospective GitHub fast-tier success and independent evaluation. No visual/audio/physics change means no dev-build/GPU signoff. Only this feature can progress; the parent sprint's preexisting status/velocity/features remain preserved. Planner performs no implementation, commits, sends or handoff; controller owns continuation and landing.

## Planner validation and remaining gaps

Validate JSON with jq -e; exactly29 features, one new planned feature with ≥2 substantive milestones, no placeholders; parsed equality of prior28 and all non-feature top-level values against git show HEAD; nonempty plan names accepted design; exact tracked/untracked two-artifact scope; whitespace and extracted scaffold shell syntax. No runtime commands from this plan are executed by planner. The new tools, process correctness, candidate runtime statuses, fresh PR hunk checks, PR-head fast tier and independent evaluation remain unmeasured/controller-owned. The existing baseline 24-case drill was subsequently measured by controller as recorded above. Actual validation results are reported at completion, not invented here.

## Appendix A: controller command scaffold (UNMEASURED)

The following is copied from the accepted design; $1 is absolute isolated candidate ROOT and $2 its saved BASE. Execute only in the controller's outside-sandbox runtime context after implementation. Each H/G invocation retains its actual status and its own private artifact directory. ROOT and artifact parent must be absolute; no canonical checkout mutation.

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


## Controller implementation refinement r20 (2026-11-08)

Use the companion design's dated D1/D2 clarification for fixed-deadline event ordering and the existing private pending-signal first-hop handoff. Preserve actual inner OS signal evidence, fresh descendant/inner identity checks, unconfirmed-child safety, first named request, fixed42/aux62 names and every 200ms/600ms/3s/120s/180s bound. Nested causal regression evidence is mandatory inside existing auxiliary cases; it earns no AC6 credit. The historical r19 full42 41/42 failure and nonreproducing private trace are retained without attributing the former to transport. M3 is explicitly reopened; M4/M5 remain incomplete. Reconstruct and rerun full applicable M3 gates, then all M4 gates, before independent review. Estimated LOC and original planning history remain unchanged; record actual overrun. Original PROCEED DEGRADED quorum remains the only quorum; no new human ruling or canon change.
