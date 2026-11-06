# Row 7aa: `sim-pipeline-test` is red because the test sends two different offers, not because pipelining diverges

**Status:** Planned, mission iteration 73, designer, 2026-11-06; **revision 1** after design quorum round 1 (see [Quorum r1 response](#quorum-r1-response-revision-1)). **Release:** r1. **Milestone:** charter queue row **7aa**, inside the approved sprint `R1-M4-JOURNEY` (D-22/D-66), the same home as row 7x.
**Priority:** P2 (follow-up backlog, [LOOP]). Suite hygiene, charter clause 5.
**Implements:** [charter](../../stapledon-mission.md) row 7aa ("reproduce at HEAD in a fresh clone, attribute (test or sim), fix the side at fault, then decide whether `ship-demo-ci` or `test` should run it, and migrate its row through `$(SCRIPT_GATE)`"). It follows the migration rule and conventions of [m4-7x-script-gate-predicates.md](m4-7x-script-gate-predicates.md) and [m4-7x-b4-script-gates.md](m4-7x-b4-script-gates.md) (D9 recorded this row as B4b's one base-red row). No design-repo feature or [relativity spec](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md) section changes: no formula, sim, protocol, shader, scene, sound or anything the player sees changes.
**Depends on:** the landed 7x helper, lint and baseline (PRs #393, #395, #397, #400); D-88 A (test or audit hygiene inside an approved sprint, with no pillar below 0, does not stop); Godot 4.7.2; AILANG v0.56.1 (`runtime/bin`, `make runtime`).
**Estimated LOC:** **+15/−7 in 4 tracked files** (`git diff --numstat`, V13), plus a changelog fragment of about 8 lines. No new `.gd`, so no new `.uid`. No production code changes.

**Evidence:** the [Verification log](#verification-log). Every row was run first-hand on 2026-11-06, 02:00–02:45 CET, with Godot `4.7.2.stable.official.ed1daf0bf` and each clone's own `runtime/bin` ailang. The base was `c2e5f8f9` (origin/main). The working clone was `stapledons-godot-iter73`; the fresh-clone reproduction and the full change were run in a separate `git clone --shared` checked out at `c2e5f8f9` (V14); historical commits ran in their own shared clones with their own pinned runtimes (V5). The candidate change set was applied, run end to end through `$(SCRIPT_GATE)`, drilled with all seven kill drills of [Appendix A1](#a1-the-kill-drills-ac7), saved as a unified diff for the controller's reference, and the tracked files were restored (V15). **Revision 1** (02:45–03:00 CET, same clone, same `c2e5f8f9`, same diff) adds V19–V25: the package rule and its pin, `crew-console-test` with and without the static counter, drill k7 with its harness (Appendix A4), the host and the nightly's idle gate, five more timing runs, and the full eight-drill run. The change set is unchanged.

**The verdict, in one line.** The **test** is at fault, not the sim or the bridge. `CrewConsole` numbers its offer ids with a **process-wide** `static var _serial` (made static in **`b42fc0e3`**, 2026-10-16, on purpose: with a per-console counter, two consoles built from the same crew turn and revision repeat an offer id, and the sim refuses the repeat as `crew:blocked:altered_duplicate:…`; V19, V21, drill k7). The test runs its synchronous and its pipelined game in one Godot process, so the first game's offer is `tc6-61-1-pilot` and the second's is `tc6-61-2-pilot`. The two runs send different inputs, so the journal, the world (only its `crew` section) and the crew differ. Given identical inputs, pipelined and synchronous heartbeats end byte-identical (V6, drill k6). The fix resets the counter at the start of each run in the test, adds a non-vacuity check, gives the summary a count, migrates the row through `$(SCRIPT_GATE)`, and joins `ship-demo-ci` (so the nightly `make test` runs it).

## Quorum r1 response (revision 1)

Round 1 was **BLOCKED, 1 of 3**: gemini-4-argon passed, oc-glm-5-3 passed, oc-kimi-k3 rejected. This is the one permitted revision. The change set (`7aa.diff`) is unchanged; the doc gains evidence, one drill and two pre-committed follow-up rows.

| # | Seat and objection | Change in this revision | Evidence |
|---|---|---|---|
| 1 | oc-kimi-k3 (blocking): "the sim refuses a reused id" is stated three times (verdict, D1, non-goals) with no row that executes it, and k6 shows a per-instance counter keeps the test green, so nothing measured requires the static counter. | **Measured.** The rule is `proposals.ail:111` of `sunholo/social_dynamics` 0.4.0, the version the lock pins (V19). The controller proposed that `crew-console-test` pins it. It does **not**: made per-console, `crew-console-test` stays green (rc 0, 100 `ok`, 0 failures), because its rebuilt console comes after an accepted send and the revision has moved (V20). So this revision adds drill **k7** with its own harness (Appendix A4). Two consoles are built from the same crew with no send between them. With the static counter the ids are `tc0-4-2`/`tc0-4-3` and nothing is refused; per-console, both are `tc0-4-1-counselor` and the sim refuses the second: `crew:blocked:altered_duplicate:offer-tc0-4-1-counselor` (V21). The verdict, the pillar row, Problem 4, D1, the non-goals and the risk row now cite V19–V21. OQ5 pre-commits row 7ac to put that case into `crew-console-test`, which `make test` runs. | V19, V20, V21, V25 |
| 2 | oc-glm-5-3 (non-blocking, with a fix): the 0.25 ratio goes into the nightly with a worst measured 0.192–0.198, and the idle-nightly premise cites CLAUDE.md with no row. | The host is stated: every timing run was on the nightly host, `Voights-Mac-Studio.local`, an Apple M4 Max (V22). The idle gate is cited from `tools/rig_nightly.sh` (load5 < 16; six GPU samples under 25 %), and during these runs the GPU was at 99–100 % (V23). Five more runs of the patched test give a worst ratio of **0.209**, under the 0.22 bar (V24), so the threshold and the `ship-demo-ci` wiring stay. glm's fix is taken as written: follow-up row **7ab**, "measure the sync/pipelined ratio over N runs on the Studio", is named in OQ3 and the Deliverables, so a first nightly flake has somewhere to land. | V22, V23, V24 |
| 3 | gemini-4-argon (pass, note): the test writes a static that is private by convention. | Already answered by OQ2 (default: no public reset helper); left as is. | — |

## Game vision alignment

Scored by the designer against the [core pillars](https://github.com/sunholo-data/stapledons-design/blob/main/vision/core-pillars.md), in the `game-vision-designer` skill's feature-validation format; the skill itself was **not invoked** (an unattended sub-agent; the row changes no game behaviour). **ALIGNED (neutral)**, no conflict.

| Pillar | Relevance | Score | Notes |
|---|---|---:|---|
| Choices Are Final | 0 | 0 | No game code changes. The crew console's ids stay process-unique, so the `altered_duplicate` refusal a per-console counter produces (V21) stays impossible. |
| The Game Doesn't Judge | 0 | 0 | No text the player sees. |
| Time Has Emotional Weight | 0 | 0 | The sim and its clocks are untouched. |
| The Ship Is Home | 0 | 0 | No scene change. |
| Grounded Strangeness | 0 | 0 | No visual change. |
| We Are Not Built For This | 0 | 0 | No change to crew behaviour. |
| Hard sci-fi authenticity / determinism (CLAUDE.md DoD 6) | low | +1 | The one test that proves pipelined heartbeats leave the world byte-identical is green again and runs nightly; a real bridge divergence turns it red (drill k2). |
| **Net** | | **+1** | **Go under D-88 A.** Nothing visual or audible changes; no dev-build review is needed. |

## Problem

V-numbers refer to rows of the [Verification log](#verification-log).

1. **Red on every run at HEAD, in a fresh clone too.** `make sim-pipeline-test` at `c2e5f8f9` in a fresh shared clone: rc 2 in 2 of 2 runs (70 s, 50 s), each with exactly `FAIL same inputs in the same order (sent journal)`, `FAIL same world at the end`, `FAIL same crew at the end`, `sim-pipeline: 3 failures` (V14). The controller's two runs in the working clone agree (V1). The other four checks pass, the guided voyage included.
2. **What diverges** (V2, the diagnostic harness of [Appendix A2](#a2-the-diagnostic-harness-v2)). Of the 60 journal lines, exactly one differs: index 40, tick 41, the crew offer the test builds from `CrewConsole.offer_intents("pilot")`:
   ```
   sync : {"intents":[{"k":"crew_offer","line":"{\"command\":\"offer\",\"id\":\"tc6-61-1-pilot\",...}"},{"k":"crew_ask","line":"{...\"id\":\"rc6-61-1-pilot\",\"task\":\"tc6-61-1-pilot\"}"}],"source":"player","tick":41}
   piped: {"intents":[{"k":"crew_offer","line":"{\"command\":\"offer\",\"id\":\"tc6-61-2-pilot\",...}"},{"k":"crew_ask","line":"{...\"id\":\"rc6-61-2-pilot\",\"task\":\"tc6-61-2-pilot\"}"}],"source":"player","tick":41}
   ```
   The id is `"c%d-%d-%d" % [turn, revision, _serial]` (`ui/crew_console.gd:265`): turn 6 and revision 61 agree, the serial does not. The world differs in exactly one key, `crew`; inside it `members`, `heard` and `lines`, each carrying that task id (`agreement-tc6-61-1-pilot` against `agreement-tc6-61-2-pilot`).
3. **Not the one-tick lag.** In the pipelined run the console reads `sim.crew` one tick early (page tick 39 against 40), but the crew it reads is byte-identical to the synchronous run's (`PAGE_CREW same … true`), and draining before the page does not remove the divergence (`DRAINED_VARIANT sent_same=false`) (V2).
4. **The counter is process-wide by design.** `ui/crew_console.gd:44`: `static var _serial := 0      ## ids count across every console in the process (a reused id is refused)`. No other tracked `.gd` file touches `_serial` (V3). `b42fc0e3` ("fix(crew): offers answered while the guided tour is paused") turned `var _serial := 0` into `static var _serial := 0` in `ui/crew_page.gd`; `3aca7a03` (R2-CREW-CONSOLE-V2) moved it into `ui/crew_console.gd` and pointed the test at `CrewConsole` (V4). The refusal it prevents is real and measured:
   - the rule is `sunholo/social_dynamics` 0.4.0 (the version `sim/ailang.lock` pins), `proposals.ail:111`: a reused id with the same body is a silent `Duplicate` with no events, and with a different body it is `Err(AlteredDuplicate(p.id))` (V19);
   - through the real sim, with the counter made per-console, consoles B and C built from one crew (turn 0, revision 4, no send between them) both offer `tc0-4-1-counselor`, and C's offer is refused with `crew:blocked:altered_duplicate:offer-tc0-4-1-counselor` and `crew:{"host":"request capacity/id/clock"}`. With the static counter they offer `tc0-4-2` and `tc0-4-3`, and nothing is refused (V21, drill k7, Appendix A4);
   - the existing `crew-console-test`, which `make test` runs (`Makefile:161`; still on the script-gate baseline), does **not** pin this. Its rebuilt console is built after an accepted send, so the revision has already moved (0 to 4) and the ids differ with either counter. Made per-console, it stays green: rc 0, 100 `ok`, `crew-console: 0 failures` (V20); OQ5.
5. **First red: `b42fc0e3`.** Its parent `13bcc409` is green 2 of 2 (`sim-pipeline: 0 failures`, 61 s, 48 s); `b42fc0e3` is red 2 of 2 with the same three FAIL lines (74 s, 47 s) (V5). The test itself has not changed since `3aca7a03`, and that change was a rename (`CrewPage` to `CrewConsole`) (V4).
6. **Did the test ever pass?** Yes. At `76ec1785`, the commit that added it, run 2 is green (51 s). Run 1 in that fresh clone failed `both runs complete` and the timing check with `0.00 ms` medians while the journal, world and crew checks passed: the sim never answered in that first run. Its cause is **UNMEASURED** (the log was overwritten by run 2); it is the old v0.54.8 runtime's first start in a fresh clone, not this divergence (V5). No later commit and not HEAD showed it in 12 fresh-clone runs (V5, V14, V16).
7. **The single-cause control.** At HEAD, with the test as it is and only line 44 changed back to `var _serial := 0`, the test is green: `sim-pipeline: 0 failures`, rc 0, 45 s (V6). So pipelined heartbeats do not diverge; the counter is the whole of it. CLAUDE.md's definition of done 6 ("the simulation has no hidden state; same seed and inputs, byte-identical output") holds: the inputs were not the same.
8. **Ungated, and no aggregate runs it.** `Makefile:1340` checks rc, `SCRIPT ERROR` and `^sim-pipeline: 0 failures$` inline, with no timeout and no count, and is baseline row 97 (`rc,se,sum,-`) (V9). It is no direct prerequisite of `ship-demo-ci` in `make -pq` (V9). B4 D8 took the transitive closure of `test`, `ci-fast` and `golden` (its V17, at `05e64cd1`) and found that none reaches it. Nothing in `tools/` or `.github/` calls it either (V11). Row 7x's B4 left it on the baseline because it was red (B4 D9).

## Goals and non-goals

**Goals**
- G1. The test compares two runs that send the same inputs, so it measures pipelining and nothing else; green on every run at HEAD.
- G2. It can't pass vacuously: a check that the journal really holds 60 ticks and the two-intent crew offer at tick 41.
- G3. Its row goes through `$(SCRIPT_GATE)` with a counted summary the helper's per-count zero probe accepts; its baseline row goes and the pin falls by exactly one (119 to 118).
- G4. The nightly `make test` runs it, through `ship-demo-ci`.
- G5. Kill drills prove that the old divergence, a real bridge divergence, a parse error and a zero count each turn it red through `make sim-pipeline-test`.

**Non-goals**
- No change to `ui/crew_console.gd`, `bridge/sim_bridge.gd` or any sim file. The static counter is required: with a per-console counter, two consoles built from the same crew turn and revision give the same offer id, and the sim refuses the second offer with `crew:blocked:altered_duplicate:…` (drill k7, V21; the rule is `proposals.ail:111` in the pinned `sunholo/social_dynamics` 0.4.0, V19). Undoing it, the alternative fix that drill k6 shows would also turn this test green, would re-open that bug.
- No change to `ci-fast` (OQ1), to the timing threshold (OQ3), or to any other baseline row.
- Not in this row: the other orphan targets of B4 D8 (`frame-check-test` and the rest).

## Design

### D1. The test fix (`tests/test_sim_pipeline.gd`, +11/−3)

Hunks against `c2e5f8f9`, as `git diff -U0` gives them (V13):

| Hunk | Change |
|---|---|
| `@@ -7,0 +8 @@` | `var passes := 0` |
| `@@ -10 +11,2 @@` | `check()` counts a pass: `if ok: passes += 1` / `else: failures += 1` |
| `@@ -13,0 +16,4 @@` | at the top of `drive()`: a three-line comment naming row 7aa, `b42fc0e3` and the two ids, then **`CrewConsole._serial = 0`**. Each run starts from a fresh process's counter, as a real game session does. |
| `@@ -36 +42,2 @@` | `drive()` also returns `sent_n` (`sim.sent_log.size()`) and `offer_n` (the intent count of journal entry 40, only if its tick is 41, else −1) |
| `@@ -69,0 +77 @@` | a new check, before the journal comparison: `the journal holds 60 ticks and the tick-41 crew offer (offer and ask)`, `a.sent_n == 60 and a.offer_n == 2` |
| `@@ -83 +91 @@` | the summary becomes `print("sim-pipeline: %d passed, %d failures" % [passes, failures])` |

Reason for each:
- The reset is the fix. It only touches the test's own fixture, and every assertion stays as strict as it was: the journal, world and crew comparisons are still exact string equality.
- It is the fix rather than a per-console counter. Drill k6 shows a per-console counter would also turn this test green, but drill k7 shows it makes the sim refuse a rebuilt console's offer (`altered_duplicate`, V21). The game needs the static counter; only the test needs a fresh one per run.
- The new check guards the comparison. If `offer_intents` ever returned `[]`, or the journal stopped recording, both runs would agree trivially and the test would pass; now it fails.
- The count is what `$(SCRIPT_GATE)`'s zero probe needs (D2). With 8 checks a green run prints `sim-pipeline: 8 passed, 0 failures`.

The reset reaches into a member named with a leading underscore. GDScript has no private access, and the run logs show no `SCRIPT ERROR` (V7, V14). A public `CrewConsole.reset_ids()` would mean a production change for a test's sake; OQ2 records that choice.

### D2. The gate (`Makefile:1340`, +2/−1)

```make
sim-pipeline-test: import ## performance pass: … (unchanged)
	@$(SCRIPT_GATE) sim-pipeline-test $(SCRATCH)/sim-pipeline.log 600 '^sim-pipeline: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT_SIM) --headless --path . --script tests/test_sim_pipeline.gd
ship-demo-ci: sim-pipeline-test
```

- **Timeout 600 s.** Measured runs take 44–79 s (V1, V5, V7, V14). This is the ceiling its neighbours use.
- **The ERE** binds the count with `[1-9][0-9]*` and pins `0 failures`. The helper's per-count zero probe accepts it. A loose `[0-9]*` is refused with `SUMMARY_ERE also matches 'sim-pipeline: 0 passed, 0 failures'` (drill k5, V8).
- **`$(GODOT_SIM)`** stays, because the test starts the sim through `AILANG_BIN`.

### D3. Baseline and pin (`tools/script-gate-baseline.txt` −1, `mk/script-gates.mk` ±2)

- Delete the row `sim-pipeline-test	tests/test_sim_pipeline.gd	rc,se,sum,-` (line 97).
- Set `SCRIPT_GATE_BASELINE_ROWS := 118`. Append to the comment above it: `, 118 after row 7aa (sim-pipeline-test).`

The lint moves from `239 --script invocations: 120 through $(SCRIPT_GATE), 119 on the baseline` to `239 --script invocations: 121 through $(SCRIPT_GATE), 118 on the baseline` (V9, V10). The inventory row changes from `ungated rc,se,sum,-` to `gated rc,se,sum,to` (V9, V10).

### D4. Which aggregate runs it: `ship-demo-ci` (so `test`, nightly)

| Aggregate | Measured | Verdict |
|---|---|---|
| `ci-fast` (GitHub, clean Linux, about 10 min, Mark 2026-11-03) | runs **no** Godot `--script` test today. In `make -n ci-fast` the only `--script` text is the lint's fixture strings (`tests/x.gd`, `tools/x.gd`) (V11) | **No.** Adding the first sim-plus-Godot test, with a timing assertion, to shared GitHub runners changes the tier Mark designed; OQ1 |
| `ship-demo-ci` (in `test`: `Makefile:1151 test: ship-demo-ci`) | the headless ship and sim tests, among them `ship-console-test`, two lines above this target; `make -pq` shows `test` → `ship-demo-ci` (V10) | **Yes**, with one line `ship-demo-ci: sim-pipeline-test`, the pattern its neighbours use |
| `golden` | GPU cases only | No: the test is headless |

That adds about 45–80 s to the nightly `rig/full` (V14).

### D5. Conflict surface

This change does **not** touch `bridge/sim_bridge.gd`. Drill k2 mutates its line 372 only inside the drill, and restores it byte for byte (`cmp`).
- **PR #379** touches the bridge at old lines 69, 392 and 791, so there is **no overlap**. Its `Makefile` hunk is at old line 485, more than 800 lines from ours at 1340.
- **PR #373**: `Makefile` hunks at 10, 18 and 225. **PR #380**: `Makefile` at 251. **PR #384**: no `Makefile`, test, console or script-gate file.
- None of the four PRs touches `tests/test_sim_pipeline.gd`, `ui/crew_console.gd`, `mk/script-gates.mk` or `tools/script-gate-baseline.txt` (V12).
- Nothing in the D-144 do-not-touch list is touched (R2-KERR, R3-WORLDS, R2-SOUND, `ui/earth_feed.gd`, `data/ui/comms_feed.json`, the ship's star light).

The baseline row and the pin are shared with any other 7x batch in flight. None is open today (V12). If one lands first, rebase, and the pin becomes (that batch's pin − 1).

## Acceptance criteria

Run them from the implementation root, in a fresh clone of the PR branch:
1. If `runtime/bin/ailang` is missing, run `make runtime`.
2. `export PATH="$PWD/runtime/bin:$PATH"`, then check that `ailang --version` says v0.56.1.
3. `make deps import`.

`data/starmap/stars.json` is tracked, so no asset fetch is needed (V14 ran with none).

The expected values were measured at `c2e5f8f9` plus this change (V7–V10, V14). Run times vary with host load, and only the relations are binding.

**Sandbox.** AC1, AC2, AC7 and AC8 start Godot and the sim, and Godot writes its user data under `~/Library/Application Support/Godot`. The controller runs them **outside** codex's `workspace-write` sandbox. AC3–AC6 and AC9–AC10 need no Godot and can run inside it.

**Appendix extraction.** AC7 and AC8 read their harnesses from this doc's [Appendix](#appendix-the-harnesses). Extract them first with:

````sh
x() { awk -v t="$1" '$0 == "```" t {f=1; next} f && $0 == "```" {exit} f' design_docs/planned/r1/m4-7aa-sim-pipeline-test.md; }
mkdir -p .godot/tmp/7aa
x 'sh 7aa-drill'      > .godot/tmp/7aa/drill.sh     # A1
x 'gdscript 7aa-diag' > .godot/tmp/7aa/diag.gd      # A2
x 'sh 7aa-history'    > .godot/tmp/7aa/history.sh   # A3
x 'gdscript 7aa-ids'  > .godot/tmp/7aa/ids.gd       # A4 (drill k7 reads it from here)
````

| # | Criterion and command | Expected output |
|---|---|---|
| AC1 | **Green through the gate, twice:** `for r in 1 2; do make sim-pipeline-test; echo rc=$?; done` | Twice: `script-gate: sim-pipeline-test ok: sim-pipeline: 8 passed, 0 failures (rc 0, no SCRIPT ERROR, N s of 600 s)` with N under 120, then `rc=0` (V14: 50 s, 44 s) |
| AC2 | **The comparison checks ran, with a live capture:** `L=.godot/tmp/sim-pipeline.log; grep -c '^ok ' $L; grep -cE '^FAIL \|SCRIPT ERROR' $L; grep -cxE 'ok (same inputs in the same order \(sent journal\)\|same world at the end\|same crew at the end\|the journal holds 60 ticks and the tick-41 crew offer \(offer and ask\))' $L` | `8`; `0`; `4` (V7). The first count is the positive control for the capture |
| AC3 | **The ratchet:** `make script-gate-lint; echo rc=$?` | `script-gate-lint: ok (239 --script invocations: 121 through $(SCRIPT_GATE), 118 on the baseline; 22 includes, all in mk/*.mk; 23 makefiles scanned)`, `script-gate-prereqs: ok (4 pairs …)`, `rc=0` (V10, V14). At base the first line reads `120 through …, 119 on the baseline` (V9) |
| AC4 | **The pin moved by exactly one:** `make script-gate-lint SCRIPT_GATE_BASELINE_ROWS=119 2>&1 \| grep 'the baseline has'; grep -c '^sim-pipeline-test' tools/script-gate-baseline.txt; grep -vc '^#' tools/script-gate-baseline.txt` | `script-gate-lint: the baseline has 118 rows but SCRIPT_GATE_BASELINE_ROWS is 119: the pin moves with the rows, and only down`; `0`; `118` (V10) |
| AC5 | **The row cannot come back:** `mkdir -p .godot/tmp/7aa; { cat tools/script-gate-baseline.txt; printf 'sim-pipeline-test\ttests/test_sim_pipeline.gd\trc,se,sum,-\n'; } > .godot/tmp/7aa/back.txt; SCRIPT_GATE_BASELINE=.godot/tmp/7aa/back.txt SCRIPT_GATE_BASELINE_ROWS=119 sh tools/script_gate_lint.sh > .godot/tmp/7aa/back.out 2>&1; echo rc=$?; grep -c '^script-gate-lint: ' .godot/tmp/7aa/back.out; grep '^script-gate-lint: stale' .godot/tmp/7aa/back.out` | `rc=1`; `1`; `script-gate-lint: stale baseline row (no longer unguarded): delete it and lower SCRIPT_GATE_BASELINE_ROWS: sim-pipeline-test tests/test_sim_pipeline.gd` (V10) |
| AC6 | **Aggregate wiring:** `P=$(make -pq 2>/dev/null); for a in ship-demo-ci:sim-pipeline-test test:ship-demo-ci ci-fast:sim-pipeline-test; do printf '%s\n' "$P" \| awk -v t="${a%%:*}:" '$1 == t' \| tr ' ' '\n' \| grep -cx "${a#*:}"; done; make --no-print-directory script-gate-inventory \| grep -cE 'sim-pipeline-test.tests/test_sim_pipeline\.gd.gated.rc,se,sum,to$'` | `1`, `1`, `0`, then `1` (V10). These are direct prerequisites, which is enough here: `test` lists `ship-demo-ci` directly (`Makefile:1151`) |
| AC7 | **Kill drills** (A1; about 5 min; outside the sandbox): `sh .godot/tmp/7aa/drill.sh "$PWD"; echo rc=$?; git status --porcelain` | `drill d0: ok …` to `drill k7: ok …` (eight lines), `sim-pipeline-drill: ok (8 drills: d0 k1 k2 k3 k4 k5 k6 k7)`, `rc=0`. `git status --porcelain` is unchanged by the drill: empty in a clean clone of the PR branch (V8, V14, V25; the three mutated files are restored and `cmp`-checked). They prove:<br>- k1: removing the reset brings back the three iteration-72 FAIL lines and `5 passed, 3 failures`;<br>- k2: a real bridge divergence (pipelined ticks advance twice the time) gives `4 passed, 4 failures`, `FAIL same world at the end` among them;<br>- k3: Godot exits 0 on a parse error and the gate refuses on `SCRIPT ERROR`;<br>- k4: `0 passed, 0 failures` is refused;<br>- k5: the ERE binds the count; the helper's probe accepts it and refuses `[0-9]*`;<br>- k6: no reset, but a per-console counter, is green: the attribution control;<br>- k7: why k6 is not the fix. A4 through the real sim: with the static counter, consoles B and C get `tc0-4-2`/`tc0-4-3` and nothing is refused; with a per-console counter both get `tc0-4-1-counselor`, and C's offer is refused `crew:blocked:altered_duplicate:offer-tc0-4-1-counselor` |
| AC8 | **The mechanism, at base or on the branch** (A2; outside the sandbox): `godot --headless --path . --script "$PWD/.godot/tmp/7aa/diag.gd" > .godot/tmp/7aa/diag.log 2>&1; grep -E '^(PAGE_TICK\|PAGE_CREW\|SENT_LEN\|WORLD_DIFF\|DRAINED\|diag)' .godot/tmp/7aa/diag.log; grep -c '^SENT_DIFF 40$' .godot/tmp/7aa/diag.log; grep -cE '^SENT_DIFF' .godot/tmp/7aa/diag.log; grep -oE 'tc6-61-[12]-pilot' .godot/tmp/7aa/diag.log \| sort -u` | `PAGE_TICK sync=40 piped=39 piped_drained=40`, `PAGE_CREW same sync/piped=true sync/piped_drained=true`, `SENT_LEN 60 60`, `WORLD_DIFF key crew`, `DRAINED_VARIANT sent_same=false world_same=false crew_same=false`, `diag: done`; `1`; `1`; `tc6-61-1-pilot`, `tc6-61-2-pilot` (V2). The harness does not reset the counter, so the result is the same on the branch |
| AC9 | **Scope and policy:** `git diff --name-only origin/main \| grep -cvxE 'Makefile\|mk/script-gates\.mk\|tools/script-gate-baseline\.txt\|tests/test_sim_pipeline\.gd\|changelogs/unreleased/2026-1[12]-[0-9][0-9]-sim-pipeline-test\.md\|design_docs/planned/r1/m4-7aa-sim-pipeline-test.*\.md\|\.ailang/state/sprints/sprint_R1-M4-JOURNEY\.json'; git diff --name-only origin/main -- bridge/ sim/ ui/ \| wc -l \| tr -d ' '; make --no-print-directory uid-guard python-guard && git diff --check origin/main && echo gates-ok` | `0`; `0`; `uid-guard: ok (406 .uid files)`, `python-guard: ok (21 allowlisted, 0 awaiting AILANG port)`, `gates-ok` (V13) |
| AC10 | **GitHub fast tier** on the PR: `gh pr checks <PR>` | `success`; `script-gate-lint` runs in `ci-fast` and reads `121 through …, 118 on the baseline` in the run log (`gh run view <run> --log \| grep -c '118 on the baseline'` gives `1` or more) |
| AC11 (optional, controller) | **History** (A3; network, about 8 min): `sh .godot/tmp/7aa/history.sh "$PWD" 13bcc409 b42fc0e3` | `history: 13bcc409 run 1 rc=0 … ok=7 fail=0 se=0 sim-pipeline: 0 failures`, the same for run 2; then `history: b42fc0e3 run 1 rc=2 … ok=4 fail=3 se=0 sim-pipeline: 3 failures` with the three FAIL lines, the same for run 2 (V5, V16) |

## Sub-milestones and estimates

One sprint and one PR, test-first:
1. **K-first.** Apply D3 (baseline row and pin) and D2 (the gate line) with the test unchanged. Run `make sim-pipeline-test` and record that it is red through the gate: the three FAIL lines, `sim-pipeline: 3 failures`, then `script-gate: sim-pipeline-test FAIL; rc 1, want 0; no summary line matching ^sim-pipeline: [1-9][0-9]* passed, 0 failures$ …`, make rc 2 (V18). Then run AC3 and AC4.
2. **D1:** the reset, the non-vacuity check and the counted summary. Then run AC1 and AC2.
3. Run AC5, AC6, AC8 and AC9, add the changelog fragment, and have the controller run AC7. AC10 follows on the PR.

This is about 30 minutes of editing; the wall time is dominated by Godot (AC1 about 2 min, AC7 about 5 min). The reference diff is `/tmp/iter73_designer/7aa.diff` (sha256 `7e88dd28…`), for the controller only. It applies to `c2e5f8f9` (`git apply --check`, V13). The executor may apply it and then verify, but no AC reads it.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| The timing check (`pipelined median < 0.25 × synchronous`) flakes on the nightly. Every timing run was on the nightly host itself, `Voights-Mac-Studio.local` (Apple M4 Max, 16 cores; V22). Over 18 measured runs the synchronous median spans 18.0–37.3 ms and the pipelined one 0.73–3.76 ms. The ratio is worst when the synchronous median is low: 0.209 (3.76/18.02), 0.2005 (3.73/18.60) and 0.193 (3.58/18.55) in V24; 0.198 (drill k1, V8); 0.192 (V6). The other thirteen fall between 0.02 and 0.18 (V1, V5, V7, V8, V14, V24). The five extra runs (V24) stay under 0.22, so the `ship-demo-ci` wiring stands. A synchronous median under about 15 ms, with a 3.7 ms pipelined one, would cross 0.25 | The nightly's own idle gate (`tools/rig_nightly.sh`, V23) starts only when the 5-minute load is under 16 and six GPU samples, 20 s apart, are all under 25 %. Every run here was taken with the GPU at 99–100 % and a 5-minute load of 2.3–2.7 (V23, V24), which is busier than any night the gate lets start. A red night opens a `nightly-rig` issue, and follow-up row **7ab** (OQ3, pre-committed) is where it lands |
| A future test that drives two `CrewConsole` games in one process hits the same trap | The comment at the reset names the cause and the commit. OQ2 offers a public reset helper as a follow-up |
| The reset hides a real id collision | It cannot: each run is a new sim (`SimBridge.new()`, `start()`, `new_game`), so no id in a run is ever reused, and the sim would refuse one if it were (V19, V21) |
| A stale or vacuous comparison | The new non-vacuity check, and drills k1 and k2 |
| A cold first run (seen once, on v0.54.8, V5) turns AC1 red | Not seen in 12 fresh-clone runs on v0.54.11 and v0.56.1 (V5, V14, V16). If AC1's first run fails `both runs complete` with `0.00 ms` medians, record it as a separate finding; do not loosen the test |

## Open questions

Each has a default the unattended loop may take. None is a stop for Mark.

- **OQ1. Should `ci-fast` also run it? Default: no.** It joins `ship-demo-ci`, so the nightly `test` runs it. `ci-fast` is Mark's ten-minute GitHub tier, and today it runs no Godot `--script` test (V11). Adding the first one, with a timing assertion, on shared runners is a tier decision. If Mark wants it there, a follow-up row adds it.
- **OQ2. Add a public `CrewConsole.reset_ids()` for tests instead of writing `_serial`? Default: no.** That would be a production change for a test's sake, and nothing else needs it (V3). Revisit if a second test needs the reset.
- **OQ3. If the timing check ever flakes nightly, what then? Default: pre-commit follow-up row 7ab now, at landing, so a first nightly flake has somewhere to land.** Row 7ab: "measure the sync/pipelined heartbeat ratio of `sim-pipeline-test` over N runs on the Studio (`Voights-Mac-Studio.local`), idle and under the nightly's own load, and set the threshold from that distribution". This row does not change the 0.25 threshold: it changes no assertion. The worst ratio measured here is 0.209 (V24).
- **OQ5. Pin the static counter in a test that `make test` runs? Default: follow-up row 7ac, not this row.** `crew-console-test` stays green with a per-console counter (V20), so only drill k7 catches that regression today. Row 7ac: "add to `tests/test_crew_console.gd` the two-consoles-with-no-send-between case of Appendix A4 (same ids are refused `altered_duplicate`), so a per-console `_serial` turns `crew-console-test` red". It is about 8 lines in a test this row does not otherwise touch. Keeping it out keeps the change set the quorum reviewed.
- **OQ4. The first run at `76ec1785` failed on a cold start (V5). Default: no row.** It was old runtime v0.54.8 at the commit that added the test, and nothing later shows it.

## Deliverables

- `tests/test_sim_pipeline.gd`: D1.
- `Makefile`: D2.
- `tools/script-gate-baseline.txt` and `mk/script-gates.mk`: D3.
- `changelogs/unreleased/<date>-sim-pipeline-test.md`, a `### Fixed` fragment. Suggested text: "`make sim-pipeline-test` (pipelined heartbeats end byte-identical to synchronous ones) was red since `b42fc0e3`. The test's two runs shared CrewConsole's process-wide offer-id counter, so they sent different offers. Each run now starts the counter afresh. The gate goes through `$(SCRIPT_GATE)` with a counted summary, and the nightly runs it through `ship-demo-ci`."
- The `R1-M4-JOURNEY` sprint JSON entry, for the planner.
- On landing, mark charter row 7aa landed, and add the two follow-up rows to the charter queue: **7ab** (the timing-ratio measurement, OQ3) and **7ac** (pin the static counter in `crew-console-test`, OQ5).

## Verification log

The working clone is `stapledons-godot-iter73` at `c2e5f8f9`, unless a row says otherwise. Every command ran with the clone's `runtime/bin` first on `PATH` (AILANG v0.56.1) and `AILANG_BIN` set by `$(GODOT_SIM)` or exported.

| # | Claim | Command | Observed |
|---|---|---|---|
| V1 | Red at HEAD in the working clone (controller) | `make sim-pipeline-test`, twice (controller logs `/tmp/iter73/simpipe_r1.log`, `_r2.log`) | rc 2 both runs (79 s, 53 s); `FAIL same inputs in the same order (sent journal)`, `FAIL same world at the end`, `FAIL same crew at the end`, `sim-pipeline: 3 failures`. Medians 30.58/3.50 ms and 26.58/3.69 ms |
| V2 | What diverges, and it is not the lag | `godot --headless --path . --script <A2 diag.gd>` (31 s, rc 0) | `PAGE_TICK sync=40 piped=39 piped_drained=40`; `PAGE_CREW same sync/piped=true sync/piped_drained=true`; one `SENT_DIFF 40` (tick 41: `tc6-61-1-pilot`/`rc6-61-1-pilot` sync, `tc6-61-2-pilot`/`rc6-61-2-pilot` piped); `SENT_LEN 60 60`; one `WORLD_DIFF key crew`; `CREW_DIFF key members`, `heard`, `lines`; `DRAINED_VARIANT sent_same=false world_same=false crew_same=false` |
| V3 | The counter is static and nobody else touches it | `grep -n "static var\|_serial" ui/crew_console.gd`; `git ls-files '*.gd' \| xargs grep -n "_serial" \| grep -v "^ui/crew_console.gd"`; control `git ls-files '*.gd' \| xargs grep -c "_serial" \| grep -v ':0$'` | `44:static var _serial := 0      ## ids count across every console in the process (a reused id is refused)`, uses at `:264`, `:265`, `:283`, `:285`; the filtered grep is empty; the control prints `ui/crew_console.gd:5` |
| V4 | History of the counter and the test | `git log -S'static var _serial' --format='%h %ad %s' --date=short -- ui/crew_console.gd ui/crew_page.gd`; `git show b42fc0e3 -- ui/crew_page.gd \| grep _serial`; `git log --format='%h %s' -- tests/test_sim_pipeline.gd`; `git show 3aca7a03 -- tests/test_sim_pipeline.gd` | `3aca7a03 … R2-CREW-CONSOLE-V2`, `b42fc0e3 … fix(crew): offers answered while the guided tour is paused`; `-var _serial := 0`, `+static var _serial := 0`; test commits `3aca7a03`, `76ec1785` only; the `3aca7a03` hunk is `-var page := CrewPage.new()` / `+var page := CrewConsole.new()` |
| V5 | First red is `b42fc0e3`; the test passed at birth | per commit: `git clone -q --shared <clone> <tmp>`, `git -C <tmp> checkout --detach <sha>`, `make runtime`, `make import`, `make sim-pipeline-test` twice (`/tmp/iter73_designer/hist.sh`, the measured precursor of A3) | `13bcc409` (v0.54.11): run 1 rc 0, 61 s, `sim-pipeline: 0 failures`; run 2 rc 0, 48 s. `b42fc0e3` (v0.54.11): run 1 rc 2, 74 s; run 2 rc 2, 47 s, each with the same three FAILs and `sim-pipeline: 3 failures`. `76ec1785` (v0.54.8): run 1 rc 2, 137 s, `FAIL both runs complete`, `FAIL a pipelined heartbeat …`, medians `0.00 ms`/`0.00 ms`, while `ok same inputs …`, `ok same world …` and `ok same crew …` pass; run 2 rc 0, 51 s, `sim-pipeline: 0 failures` |
| V6 | Single-cause control at HEAD | the unchanged test, with `perl -pi -e 's/^static var _serial := 0 /var _serial := 0 /' ui/crew_console.gd`; `godot --headless --path . --script tests/test_sim_pipeline.gd`; then the file restored | rc 0, 45 s; every check `ok`; medians 18.69/3.59 ms; `sim-pipeline: 0 failures`. After the restore, `git status --porcelain` showed only the change set under test |
| V7 | The fix, through the gate (working clone) | the D1–D3 change applied; `make script-gate-lint`; `make sim-pipeline-test`; `grep -E '^(ok\|FAIL\|heartbeat\|guided\|sim-pipeline)\|SCRIPT ERROR' .godot/tmp/sim-pipeline.log` | lint `121 through …, 118 on the baseline`; `script-gate: sim-pipeline-test ok: sim-pipeline: 8 passed, 0 failures (rc 0, no SCRIPT ERROR, 65 s of 600 s)`; 8 `ok` lines, the new journal check among them; 0 FAIL; 0 SCRIPT ERROR; medians 31.15/0.73 ms |
| V8 | Kill drills (working clone) | `sh sim-pipeline-drill.sh "$PWD"` (A1 at k1–k5; k6 added later and run in V14), then single runs of k2, k1 and k3, each followed by a grep of the log | `sim-pipeline-drill: ok (6 drills: d0 k1 k2 k3 k4 k5)`, rc 0, 208 s. Log lines:<br>- k2: `FAIL same inputs …`, `FAIL same world …`, `FAIL same crew …`, `guided voyage: 510 steps synchronous, 260 pipelined`, `FAIL the guided voyage's ticks and world are identical` (k2 was then tightened to 4 FAILs and `4 passed, 4 failures`, and re-run in V14);<br>- k1: `sim-pipeline: 5 passed, 3 failures`, medians 18.90/3.75 ms;<br>- k3: `SCRIPT ERROR: Parse Error: Expected parameter name.`<br>k5 alone, earlier: `drill k5: ok` |
| V9 | Base lint, pin and inventory | in a shared clone at `c2e5f8f9`: `make script-gate-lint`; `make script-gate-lint SCRIPT_GATE_BASELINE_ROWS=118 \| grep 'the baseline has'`; `make script-gate-inventory \| grep sim-pipeline`; `make -pq \| awk '/^ship-demo-ci:/' \| tr ' ' '\n' \| grep -cx sim-pipeline-test` | `239 --script invocations: 120 through $(SCRIPT_GATE), 119 on the baseline; 22 includes, …; 23 makefiles scanned`; `the baseline has 119 rows but SCRIPT_GATE_BASELINE_ROWS is 118`; `Makefile:1340	sim-pipeline-test	tests/test_sim_pipeline.gd	ungated	rc,se,sum,-`; `0` |
| V10 | The changed tree: pin, stale row, closure, inventory | AC4's pin command; AC5's command; the `make -pq` closures for `ship-demo-ci`, `test` and `ci-fast`; the inventory | `the baseline has 118 rows but SCRIPT_GATE_BASELINE_ROWS is 119 …`; AC5 gives `rc=1`, exactly 1 lint line, the stale line; closures `1` (`ship-demo-ci` ∋ `sim-pipeline-test`), `1` (`test` ∋ `ship-demo-ci`), `0` (`ci-fast`); `Makefile:1340	sim-pipeline-test	tests/test_sim_pipeline.gd	gated	rc,se,sum,to` |
| V11 | Who calls it; `ci-fast` runs no Godot test | `git ls-files \| xargs grep -ln "sim-pipeline"`, with the control `git ls-files \| xargs grep -ln "frame-check-test"`; `make -n ci-fast > f; grep -o -- '--script [^ ]*' f \| sort -u` (base clone) | `.ailang/state/sprints/sprint_R2-INTERLUDE.json`, `CHANGELOG.md`, `Makefile`, the two B4 docs, the mission dashboard, log and charter, `mk/script-gates.mk`, `tests/test_sim_pipeline.gd`: nothing in `tools/` or `.github/`. The control lists `CHANGELOG.md`, `Makefile`, the B4 sprint. `ci-fast` shows only `--script tests/x.gd\n'`, `--script tools/x.gd\nok-capture:…` and `--script tools/x.gd\nok-test:…` (lint fixture text) |
| V12 | Open PRs | `gh pr list --state open`; `gh pr view <n> --json files`; `gh api --allow-escape-sequences -H 'Accept: application/vnd.github.v3.diff' repos/sunholo-data/stapledons-godot/pulls/<n>`, with hunk headers for `Makefile`, `sim_bridge`, `script-gate`, `crew_console`, `test_sim_pipeline` | open: #384, #380, #379, #373. #373 `Makefile -10,7 -18,10 -225,8`; #379 `Makefile -485,6`, `bridge/sim_bridge.gd -69,6 -392,7 -791,3`; #380 `Makefile -251,6`; #384 none of those files. No PR touches the test, `ui/crew_console.gd`, `mk/script-gates.mk` or the baseline |
| V13 | Size, hunks, hygiene | `git diff --numstat`; `git diff -U0 \| grep -E '^(\+\+\+\|@@)'`; `git diff --check`; `make uid-guard python-guard`; `git apply --check /tmp/iter73_designer/7aa.diff` (on the restored tree) | `2 1 Makefile`, `2 2 mk/script-gates.mk`, `11 3 tests/test_sim_pipeline.gd`, `0 1 tools/script-gate-baseline.txt`; hunks as in D1, D2, D3 (`Makefile -1340 +1340,2`, `mk/script-gates.mk -11,2 +11,2`, baseline `-97`); `--check` silent; `uid-guard: ok (406 .uid files)`, `python-guard: ok (21 allowlisted, 0 awaiting AILANG port)`; `applies` |
| V14 | **Fresh clone at HEAD: base red, change green, every drill** | `git clone -q --shared <clone> fresh; git checkout --detach c2e5f8f9; make runtime` (3 s), `make import` (17 s), `make sim-pipeline-test` ×2; `patch -p1 < 7aa.diff`; `make sim-pipeline-test` ×2; `make script-gate-lint`; `sh <A1> "$PWD"`; `git status --porcelain` | base: rc 2, 70 s and rc 2, 50 s, each with the three FAILs and `sim-pipeline: 3 failures` (medians 27.46/3.60, 20.48/3.71 ms). Change: `script-gate: sim-pipeline-test ok: sim-pipeline: 8 passed, 0 failures (rc 0, no SCRIPT ERROR, 50 s of 600 s)`, then `… 44 s of 600 s`. Lint `121 through …, 118 on the baseline` and prereqs ok. Drills d0, k1, k2 (tightened), k3, k4, k5 and k6 all `ok`, `sim-pipeline-drill: ok (7 drills: d0 k1 k2 k3 k4 k5 k6)`, rc 0, 255 s. Status: the 4 changed files and the harness's own untracked logs |
| V15 | The working tree is restored | after saving `git diff > /tmp/iter73_designer/7aa.diff` (sha256 `7e88dd2861ff…`), the four files copied back from their saved originals; `git status --porcelain` | only `?? design_docs/planned/r1/m4-7aa-sim-pipeline-test.md` |
| V16 | A3, as printed in this doc, reproduces V5 | `sh <A3> <working clone> 13bcc409 b42fc0e3` (02:34–02:45; the extracted A3 is `cmp`-identical to the file run) | rc 0. `history: 13bcc409 run 1 rc=0 57s ok=7 fail=0 se=0 sim-pipeline: 0 failures`, `run 2 rc=0 45s ok=7 fail=0 se=0 …`; `history: b42fc0e3 run 1 rc=2 57s ok=4 fail=3 se=0 sim-pipeline: 3 failures`, `run 2 rc=2 47s ok=4 fail=3 se=0 …`, each run followed by the three FAIL lines (`same inputs …`, `same world …`, `same crew …`) |
| V17 | The ACs as printed run | the D1–D3 change applied to the working clone (`git apply 7aa.diff`); AC1 (one run), AC2, AC3, AC4, AC5, AC6, AC8 and AC9 typed as in the table (a `\|` in a table cell is typed as a bare pipe); the appendix blocks extracted with `x` and `cmp`-compared to the files run in V8, V14 and V16; then the four files copied back | AC1 `… 8 passed, 0 failures (rc 0, no SCRIPT ERROR, 47 s of 600 s)`, `rc=0`; AC2 `8`, `0`, `4`; AC3 the `121 … 118` line, prereqs ok, `rc=0`; AC4 the pin line, `0`, `118`; AC5 `rc=1`, `1`, the stale line; AC6 `1 1 0 1`; AC8 the six lines as expected, `1`, `1`, the two ids; AC9 `0`, `0`, both guards ok, `gates-ok`. A1, A2 and A3 are byte-identical to the files run (116, 51 and 27 lines). After the restore, `git status --porcelain` shows only this doc |
| V18 | K-first: the new gate refuses the old test | the D2 and D3 change applied, `tests/test_sim_pipeline.gd` left at base; `make --no-print-directory sim-pipeline-test`; then the four files copied back | rc 2, 52 s; `FAIL same inputs …`, `FAIL same world …`, `FAIL same crew …`, `sim-pipeline: 3 failures`; `script-gate: sim-pipeline-test FAIL; rc 1, want 0; no summary line matching ^sim-pipeline: [1-9][0-9]* passed, 0 failures$ (rc 1 with no summary is a load failure, not a result) (log .godot/tmp/sim-pipeline.log)`; `make: *** [sim-pipeline-test] Error 1`. After the restore, `git status --porcelain` shows only this doc |
| V19 | The refusal rule, and the version the sim pins | `grep -n 'AlteredDuplicate(p.id)' runtime/cache/registry/sunholo/social_dynamics/0.4.0/proposals.ail`; `ls runtime/cache/registry/sunholo/social_dynamics/`; `grep -n social_dynamics sim/ailang.toml`; `grep -n -A3 '"name": "sunholo/social_dynamics"' sim/ailang.lock` | `111:    prior :: _ => if prior.body == body then Ok({state: s, disposition: Duplicate, events: []}) else Err(AlteredDuplicate(p.id)),` (a reused id with the same body is a silent `Duplicate`, no events; with a different body, `AlteredDuplicate`); `0.4.0` is the only cached version; `36:"sunholo/social_dynamics" = "0.4.0" # crew_core's engine; …`; lock `142: "name": "sunholo/social_dynamics"`, `144: "version": "0.4.0"`. The controller measured the grep independently with the same output |
| V20 | `crew-console-test` does **not** pin the static counter | `sed -n 470,485p tests/test_crew_console.gd`; `sed -n 161p Makefile`; with the 7aa change applied: `make --no-print-directory crew-console-test`, then the same with `perl -pi -e 's/^static var _serial := 0 /var _serial := 0 /' ui/crew_console.gd`; each followed by `grep -cE '^ok ' .godot/tmp/crew-console.log; grep -E '^FAIL\|^crew-console\|rebuilt console\|re-sending' .godot/tmp/crew-console.log`; then the file restored and `cmp`-checked | The test builds console A, **sends** A's offer, then builds B, and checks that the ids differ and that re-sending A's intents is refused `crew:blocked:altered_duplicate:`. `Makefile:161` is `test: crew-console-test`. Static (base): rc 0, `100`, `ok a rebuilt console in the same crew turn makes new task and request ids`, `ok re-sending an old id is refused (altered_duplicate, request capacity/id/clock)`, `crew-console: 0 failures` (the controller's own run at `c2e5f8f9`: rc 0 in 13 s, the same two lines, 100 `ok`). **Per-console: rc 0, `100`, the same two `ok` lines, `crew-console: 0 failures`**. The controller's predicted red does not happen: A's send moves the revision from 0 to 4 (V21), so B's id differs from A's with either counter. `cc-restored` |
| V21 | The static counter is what prevents the refusal (A4, drill k7) | `godot --headless --path . --script "$PWD/.godot/tmp/7aa/ids.gd" \| grep -E '^K7IDS\|^k7-ids\|SCRIPT ERROR'`, then the same with the counter per-console, then the file restored and `cmp`-checked; then `sh <A1> "$PWD" k7` (7 s, rc 0) | Static: `K7IDS a=tc0-0-1-counselor b=tc0-4-2-counselor c=tc0-4-3-counselor turn=0.0 revision=4.0`, `b_and_c_same=false`, `b_refused=0`, `c_refused=0`, `k7-ids: done`. Per-console: `K7IDS a=tc0-0-1-counselor b=tc0-4-1-counselor c=tc0-4-1-counselor turn=0.0 revision=4.0`, `b_and_c_same=true`, `b_refused=0`, `c_refused=2 crew:blocked:altered_duplicate:offer-tc0-4-1-counselor,crew:{"host":"request capacity/id/clock"}`, `k7-ids: done`. No `SCRIPT ERROR` either way; the only warnings are portrait `Loaded resource as image file` notices and leak counts at exit. Drill: `drill k7: ok (a per-console counter repeats an id in a rebuilt console, and the sim refuses it: altered_duplicate)` |
| V22 | The host every timing run used | `hostname; sysctl -n machdep.cpu.brand_string; sysctl -n hw.ncpu` | `Voights-Mac-Studio.local`, `Apple M4 Max`, `16`. Every run in V1, V5–V8, V14 and V24 was on this host, which is the nightly `rig/full` host (the controller's runs too) |
| V23 | The nightly's idle gate, and the load during these runs | `grep -n -E 'GPU_MAX=\|LOAD_MAX=\|SAMPLES=\|loadavg\|not starting' tools/rig_nightly.sh`; `grep -c 'not starting' ~/Library/Logs/stapledon-rig-nightly.log; grep 'not starting' ~/Library/Logs/stapledon-rig-nightly.log \| tail -5`; during V24, every 20 s: `curl -s http://127.0.0.1:8941/rig.json` (the gate's own `RIG_JSON`) → `system.gpu.utilization`, and `sysctl -n vm.loadavg` | `19:GPU_MAX=${RIG_NIGHTLY_GPU_MAX:-25}     # % GPU utilisation, every sample must be below`; `20:LOAD_MAX=${RIG_NIGHTLY_LOAD_MAX:-16}   # 5-minute load average (40 cores)`; `21:SAMPLES=${RIG_NIGHTLY_SAMPLES:-6}      # GPU samples, 20 s apart`; `42:` eval window 01:45–04:00 `not starting`; `44:  load=$(sysctl -n vm.loadavg \| awk '{print int($3)}')`; `45:` `load … >= $LOAD_MAX, not starting`; `49:` `GPU at ${gpu}% (>= $GPU_MAX), not starting`. Log: `13` refusals; the last five are `GPU at 100% (>= 25)` at 2026-11-05 05:15, 06:15 and 22:30, `99%` at 23:30, and `100%` at 2026-11-06 00:30. Samples 02:48:47–02:52:30: `gpu=99` ×9 and `gpu=100` ×3; load `{ 2.05 2.27 2.69 }` to `{ 2.60 2.47 2.69 }`. So the timing runs saw a GPU busier than any night the gate starts on. (The script comment says 40 cores; `hw.ncpu` is 16, V22) |
| V24 | Five more runs of the patched test (glm's bar: a ratio over 0.22 would drop the wiring) | the 7aa change applied; 5 × `make --no-print-directory sim-pipeline-test`, each with `sysctl -n vm.loadavg` before and `grep '^heartbeat' .godot/tmp/sim-pipeline.log` after | all rc 0, `script-gate: sim-pipeline-test ok: sim-pipeline: 8 passed, 0 failures` (48, 45, 45, 50, 48 s of 600 s). Medians, synchronous / pipelined (ratio): **18.02 / 3.76 (0.209)**, 24.43 / 3.65 (0.149), 18.60 / 3.73 (0.2005), 22.82 / 3.51 (0.154), 18.55 / 3.58 (0.193). The worst is 0.209, under 0.22. The 5-minute load before each run (the field the gate reads, `awk '{print $3}'`) was 2.45, 2.56, 2.66, 2.53 and 2.35 |
| V25 | The full revised drill, A1 with k7 | the 7aa change applied, A4 at `.godot/tmp/7aa/ids.gd`; `sh <A1> "$PWD"` (02:54:51–02:59:20); `git status --porcelain`; then the four files copied back | `drill d0: ok …` through `drill k7: ok …`, `sim-pipeline-drill: ok (8 drills: d0 k1 k2 k3 k4 k5 k6 k7)`, rc 0, 269 s. Status: the four changed files and this doc only. After the copy-back: only this doc |

## Appendix: the harnesses

The doc's own `x` function extracts these blocks ([Acceptance criteria](#acceptance-criteria)). Each harness is exactly the file that ran in V2, V8, V14 and V16.

### A1. The kill drills (AC7)

```sh 7aa-drill
#!/bin/sh
# Row 7aa kill drills for make sim-pipeline-test. usage: sh sim-pipeline-drill.sh ROOT [DRILL...]
# ROOT: a clone with the 7aa change applied, `make import` done, the pinned ailang first on PATH.
# DRILLS: d0 k1 k2 k3 k4 k5 k6 k7 (default: all). Each Godot drill is one `make sim-pipeline-test` (~50-80 s);
# k7 runs the A4 harness twice (~10 s each); extract it to ROOT/.godot/tmp/7aa/ids.gd first.
set -u
ROOT=${1:?usage: sim-pipeline-drill.sh ROOT [DRILL...]}
shift
cd "$ROOT" || exit 2
T=$(mktemp -d /tmp/sim-pipeline-drill.XXXXXX) || exit 2
trap 'cp "$T/keep/test_sim_pipeline.gd" tests/test_sim_pipeline.gd 2>/dev/null; cp "$T/keep/sim_bridge.gd" bridge/sim_bridge.gd 2>/dev/null; cp "$T/keep/crew_console.gd" ui/crew_console.gd 2>/dev/null; rm -rf "$T"' EXIT INT TERM
mkdir -p "$T/keep" || exit 2
cp tests/test_sim_pipeline.gd bridge/sim_bridge.gd ui/crew_console.gd "$T/keep/" || exit 2
LOG=.godot/tmp/sim-pipeline.log

restore() { cp "$T/keep/test_sim_pipeline.gd" tests/test_sim_pipeline.gd && cp "$T/keep/sim_bridge.gd" bridge/sim_bridge.gd && cp "$T/keep/crew_console.gd" ui/crew_console.gd; }
mutate() { # FILE PERL-PROGRAM: edit FILE in place; exit 3 unless it changed
  perl -pi -e "$2" "$1" || exit 2
  if cmp -s "$1" "$T/keep/$(basename "$1")"; then echo "drill: the mutation left $1 unchanged"; exit 3; fi
}
run() { # NAME: one make sim-pipeline-test; output in $T/NAME.out, make's rc in $T/NAME.rc
  rm -f "$LOG"
  make --no-print-directory sim-pipeline-test > "$T/$1.out" 2>&1
  echo $? > "$T/$1.rc"
  test -s "$LOG" || { echo "drill: $1 left no $LOG"; exit 1; }
}
n() { grep -cE -- "$1" "$2"; } # count of lines matching ERE $1 in file $2
IDS=$(pwd)/.godot/tmp/7aa/ids.gd  # A4, extracted from the doc (k7)
run_ids() { # NAME: the A4 harness once; output in $T/NAME.out, Godot's rc in $T/NAME.rc
  AILANG_BIN="$(command -v ailang)" perl -e 'alarm 300; exec @ARGV' "${GODOT:-godot}" --headless --path . --script "$IDS" > "$T/$1.out" 2>&1
  echo $? > "$T/$1.rc"
}

d0() { # the change as committed: green through the gate
  restore || exit 2
  run d0
  test "$(cat "$T/d0.rc")" = 0 || exit 1
  test "$(n '^script-gate: sim-pipeline-test ok: sim-pipeline: 8 passed, 0 failures \(rc 0, no SCRIPT ERROR' "$T/d0.out")" = 1 || exit 1
  test "$(n '^ok ' "$LOG")" = 8 || exit 1
  test "$(n '^FAIL ' "$LOG")" = 0 || exit 1
  test "$(n 'SCRIPT ERROR' "$LOG")" = 0 || exit 1
  echo "drill d0: ok (rc 0, 8 passed, 0 failures)"
}
k1() { # the divergence back: drop the per-run counter reset
  restore || exit 2
  mutate tests/test_sim_pipeline.gd '$_ = "" if /^\tCrewConsole\._serial = 0$/'
  run k1
  test "$(cat "$T/k1.rc")" = 2 || exit 1
  test "$(n '^ok both runs complete$' "$LOG")" = 1 || exit 1
  test "$(n '^FAIL ' "$LOG")" = 3 || exit 1
  test "$(n '^FAIL (same inputs in the same order \(sent journal\)|same world at the end|same crew at the end)$' "$LOG")" = 3 || exit 1
  test "$(n '^sim-pipeline: 5 passed, 3 failures$' "$LOG")" = 1 || exit 1
  test "$(n '^script-gate: sim-pipeline-test FAIL; rc 1, want 0' "$T/k1.out")" = 1 || exit 1
  echo "drill k1: ok (rc 2, the three iteration-72 FAIL lines)"
}
k2() { # a real bridge divergence: a pipelined tick advances twice the time
  restore || exit 2
  mutate bridge/sim_bridge.gd 's/"dtau": dtau, "intents": intents\}/"dtau": (dtau * 2.0 if pipelined and pipelined_ok and intents.is_empty() else dtau), "intents": intents}/'
  run k2
  test "$(cat "$T/k2.rc")" = 2 || exit 1
  test "$(n '^ok both runs complete$' "$LOG")" = 1 || exit 1
  test "$(n '^FAIL ' "$LOG")" = 4 || exit 1
  test "$(n '^FAIL same world at the end$' "$LOG")" = 1 || exit 1
  test "$(n '^sim-pipeline: 4 passed, 4 failures$' "$LOG")" = 1 || exit 1
  test "$(n "^FAIL the guided voyage's ticks and world are identical$" "$LOG")" = 1 || exit 1
  test "$(n '^script-gate: sim-pipeline-test FAIL; rc 1, want 0' "$T/k2.out")" = 1 || exit 1
  echo "drill k2: ok (rc 2, the world and the guided voyage diverge)"
}
k3() { # a parse error: Godot exits 0, the gate refuses on SCRIPT ERROR
  restore || exit 2
  mutate tests/test_sim_pipeline.gd '$_ .= "func broken(:\n" if eof'
  run k3
  test "$(cat "$T/k3.rc")" = 2 || exit 1
  test "$(n 'SCRIPT ERROR' "$LOG")" -ge 1 || exit 1
  test "$(n '^sim-pipeline: ' "$LOG")" = 0 || exit 1
  test "$(n '^script-gate: sim-pipeline-test FAIL; [0-9]+ SCRIPT ERROR line\(s\)' "$T/k3.out")" = 1 || exit 1
  test "$(n 'want 0' "$T/k3.out")" = 0 || exit 1
  echo "drill k3: ok (Godot rc 0 on a parse error; the gate refuses)"
}
k4() { # a zero count: every check runs, none is counted
  restore || exit 2
  mutate tests/test_sim_pipeline.gd 's/^\tif ok: passes \+= 1$/\tif ok: passes += 0/'
  run k4
  test "$(cat "$T/k4.rc")" = 2 || exit 1
  test "$(n '^sim-pipeline: 0 passed, 0 failures$' "$LOG")" = 1 || exit 1
  test "$(n '^ok ' "$LOG")" = 8 || exit 1
  test "$(n '^script-gate: sim-pipeline-test FAIL; no summary line matching' "$T/k4.out")" = 1 || exit 1
  echo "drill k4: ok (0 passed is refused)"
}
k6() { # attribution control: no reset, but a per-console counter (b42fc0e3 undone): green again
  restore || exit 2
  mutate tests/test_sim_pipeline.gd '$_ = "" if /^\tCrewConsole\._serial = 0$/'
  mutate ui/crew_console.gd 's/^static var _serial := 0 /var _serial := 0 /'
  run k6
  test "$(cat "$T/k6.rc")" = 0 || exit 1
  test "$(n '^script-gate: sim-pipeline-test ok: sim-pipeline: 8 passed, 0 failures' "$T/k6.out")" = 1 || exit 1
  test "$(n '^FAIL ' "$LOG")" = 0 || exit 1
  echo "drill k6: ok (the process-wide counter is the whole divergence)"
}
k7() { # why the counter is static: consoles B and C built with no accepted send between them
  restore || exit 2
  test -s "$IDS" || { echo "drill: k7 needs $IDS (extract A4 first)"; exit 2; }
  run_ids k7base
  test "$(cat "$T/k7base.rc")" = 0 || exit 1
  test "$(n '^k7-ids: done$' "$T/k7base.out")" = 1 || exit 1
  test "$(n '^K7IDS a=tc0-0-1-counselor b=tc0-4-2-counselor c=tc0-4-3-counselor turn=0.0 revision=4.0$' "$T/k7base.out")" = 1 || exit 1
  test "$(n '^K7IDS b_and_c_same=false$' "$T/k7base.out")" = 1 || exit 1
  test "$(n '^K7IDS c_refused=0 $' "$T/k7base.out")" = 1 || exit 1
  test "$(n 'SCRIPT ERROR' "$T/k7base.out")" = 0 || exit 1
  mutate ui/crew_console.gd 's/^static var _serial := 0 /var _serial := 0 /'
  run_ids k7
  test "$(cat "$T/k7.rc")" = 0 || exit 1
  test "$(n '^k7-ids: done$' "$T/k7.out")" = 1 || exit 1
  test "$(n '^K7IDS b_and_c_same=true$' "$T/k7.out")" = 1 || exit 1
  test "$(n '^K7IDS b_refused=0$' "$T/k7.out")" = 1 || exit 1
  test "$(n '^K7IDS c_refused=2 crew:blocked:altered_duplicate:offer-tc0-4-1-counselor,' "$T/k7.out")" = 1 || exit 1
  test "$(n 'SCRIPT ERROR' "$T/k7.out")" = 0 || exit 1
  echo "drill k7: ok (a per-console counter repeats an id in a rebuilt console, and the sim refuses it: altered_duplicate)"
}
k5() { # no Godot: the Makefile's ERE, and the helper's per-count zero probe on it
  ere=$(sed -n "s/.*SCRIPT_GATE) sim-pipeline-test [^ ]* 600 '\([^']*\)'.*/\1/p" Makefile | sed 's/\$\$/$/')
  test "$ere" = '^sim-pipeline: [1-9][0-9]* passed, 0 failures$' || exit 1
  test "$(printf 'sim-pipeline: 8 passed, 0 failures\n' | grep -cE -- "$ere")" = 1 || exit 1
  test "$(printf 'sim-pipeline: 0 passed, 0 failures\nsim-pipeline: 8 passed, 1 failures\nsim-pipeline: 3 failures\n' | grep -cE -- "$ere")" = 0 || exit 1
  sh tools/script_gate.sh probe "$T/p.log" 10 "$ere" -- sh -c 'echo "sim-pipeline: 8 passed, 0 failures"' > "$T/k5a.out" 2>&1
  test $? = 0 || exit 1
  test "$(n '^script-gate: probe ok: sim-pipeline: 8 passed, 0 failures' "$T/k5a.out")" = 1 || exit 1
  sh tools/script_gate.sh probe "$T/p.log" 10 '^sim-pipeline: [0-9]* passed, 0 failures$' -- sh -c 'echo "sim-pipeline: 8 passed, 0 failures"' > "$T/k5b.out" 2>&1
  test $? = 1 || exit 1
  test "$(n "SUMMARY_ERE also matches 'sim-pipeline: 0 passed, 0 failures'" "$T/k5b.out")" = 1 || exit 1
  echo "drill k5: ok (the ERE binds the count; the helper's zero probe accepts it and refuses [0-9]*)"
}

[ $# -gt 0 ] || set -- d0 k1 k2 k3 k4 k5 k6 k7
for d in "$@"; do
  case $d in d0|k1|k2|k3|k4|k5|k6|k7) "$d" ;; *) echo "drill: unknown drill $d"; exit 2 ;; esac
done
restore || exit 2
cmp -s tests/test_sim_pipeline.gd "$T/keep/test_sim_pipeline.gd" || { echo "drill: restore failed (test)"; exit 1; }
cmp -s bridge/sim_bridge.gd "$T/keep/sim_bridge.gd" || { echo "drill: restore failed (bridge)"; exit 1; }
cmp -s ui/crew_console.gd "$T/keep/crew_console.gd" || { echo "drill: restore failed (console)"; exit 1; }
echo "sim-pipeline-drill: ok ($# drills: $*)"
```

Shape:
- ROOT is an explicit argument;
- there is one parent temp dir with an explicit template, and the cleanup trap follows `mktemp -d` at once and also restores the three files;
- every mutation is `cmp`-proved, or the drill exits 3; k7 mutates `ui/crew_console.gd` and runs the A4 harness, not the test;
- make's rc is kept per drill and asserted;
- counts are asserted with `test`, every check carries its own `|| exit 1`, and there are no `!` assertions;
- each Godot drill's positive control for a live capture is that the log is non-empty, plus an `ok` line it expects (`ok both runs complete`, or 8 `ok` lines);
- `shellcheck -s sh -e SC2016` is clean (SC2016 is the intended single-quoted perl).

### A2. The diagnostic harness (V2)

```gdscript 7aa-diag
extends SceneTree
func drive(pipelined: bool, drain_before_page: bool) -> Dictionary:
	var sim := SimBridge.new()
	sim.want_minor = SimBridge.CREW_MINOR
	sim.record_sent = true
	var ok := sim.start() and sim.new_game(3, "free_nav", false, {}, "", "consent")
	sim.pipelined = pipelined
	var hb := 1.0 / (31557600.0 * 20.0)
	var page_crew := ""
	var page_tick := -1
	for i in 60:
		if i == 20:
			ok = ok and sim.send([SimBridge.crew_intent("crew_orders", {"command": "orders", "preset": "critical_only"})], 0.0)
		elif i == 40:
			if drain_before_page:
				ok = ok and sim.drain()
			var page := CrewConsole.new()
			page_crew = JSON.stringify(sim.crew)
			page_tick = int(sim.world.get("tick", -1))
			page.show_crew(sim.crew)
			ok = ok and sim.send(page.offer_intents("pilot"), 0.0)
			page.free()
		else:
			ok = ok and sim.send([], hb if i % 10 else 2.0 / 365.25, true)
			if pipelined:
				OS.delay_msec(25)
	ok = ok and sim.drain()
	var out := {"ok": ok, "world": sim.world.duplicate(true), "crew": sim.crew.duplicate(true), "sent": sim.sent_log.duplicate(true), "page_tick": page_tick, "page_crew": page_crew}
	sim.stop()
	return out

func _initialize() -> void:
	var a := drive(false, false)
	var b := drive(true, false)
	var c := drive(true, true)
	print("PAGE_TICK sync=%d piped=%d piped_drained=%d" % [a.page_tick, b.page_tick, c.page_tick])
	print("PAGE_CREW same sync/piped=%s sync/piped_drained=%s" % [a.page_crew == b.page_crew, a.page_crew == c.page_crew])
	for i in a.sent.size():
		var x = JSON.stringify(a.sent[i]); var y = JSON.stringify(b.sent[i]) if i < b.sent.size() else "<none>"
		if x != y:
			print("SENT_DIFF %d\n  sync : %s\n  piped: %s" % [i, x, y])
	print("SENT_LEN %d %d" % [a.sent.size(), b.sent.size()])
	for k in a.world:
		if JSON.stringify(a.world[k]) != JSON.stringify(b.world.get(k)):
			print("WORLD_DIFF key %s" % k)
	for k in a.crew:
		if JSON.stringify(a.crew[k]) != JSON.stringify(b.crew.get(k)):
			print("CREW_DIFF key %s\n  sync : %s\n  piped: %s" % [k, JSON.stringify(a.crew[k]).left(600), JSON.stringify(b.crew.get(k)).left(600)])
	print("DRAINED_VARIANT sent_same=%s world_same=%s crew_same=%s" % [JSON.stringify(a.sent) == JSON.stringify(c.sent), JSON.stringify(a.world) == JSON.stringify(c.world), JSON.stringify(a.crew) == JSON.stringify(c.crew)])
	print("diag: done")
	quit(0)
```

It mirrors `drive()` of the test as it stands at `c2e5f8f9`, without the reset. It adds a third run that drains before building the page, and it prints the differences instead of asserting them. It is a diagnostic, not a gate: AC8 reads its output lines, and `diag: done` is the positive control that it ran to the end.

### A3. The history harness (AC11, V16)

```sh 7aa-history
#!/bin/sh
# Row 7aa attribution: make sim-pipeline-test at past commits, each in a throwaway shared clone with its own
# pinned runtime. usage: sh sim-pipeline-history.sh ROOT SHA... (ROOT: any clone holding the commits)
# Needs gh (make runtime downloads each commit's pinned ailang release). Prints one result line per run.
set -u
ROOT=${1:?usage: sim-pipeline-history.sh ROOT SHA...}
shift
[ $# -ge 1 ] || { echo "usage: sim-pipeline-history.sh ROOT SHA..."; exit 2; }
T=$(mktemp -d /tmp/sim-pipeline-history.XXXXXX) || exit 2
trap 'rm -rf "$T"' EXIT INT TERM
for sha in "$@"; do
  D=$T/$sha
  git clone -q --shared "$ROOT" "$D" || exit 2
  git -C "$D" checkout -q --detach "$sha" || exit 2
  (cd "$D" && make runtime > "$T/$sha.runtime.log" 2>&1) || { tail -5 "$T/$sha.runtime.log"; exit 2; }
  (cd "$D" && PATH=$D/runtime/bin:$PATH perl -e 'alarm 900; exec @ARGV' make import > "$T/$sha.import.log" 2>&1) || exit 2
  for r in 1 2; do
    s=$(date +%s)
    (cd "$D" && PATH=$D/runtime/bin:$PATH perl -e 'alarm 540; exec @ARGV' make sim-pipeline-test > "$T/$sha.$r.out" 2>&1)
    rc=$?
    L=$D/.godot/tmp/sim-pipeline.log
    test -s "$L" || { echo "history: $sha run $r left no log"; exit 1; }
    echo "history: $sha run $r rc=$rc $(( $(date +%s) - s ))s ok=$(grep -c '^ok ' "$L") fail=$(grep -c '^FAIL ' "$L") se=$(grep -c 'SCRIPT ERROR' "$L") $(grep '^sim-pipeline: ' "$L" | tail -1)"
    grep '^FAIL ' "$L" | sed "s/^/history: $sha run $r   /"
  done
  rm -rf "$D"
done
```

The clones are temporary `--shared` clones under one parent temp dir. They are not worktrees, and they write nothing to ROOT's refs. At these commits the test has 7 checks and an uncounted summary, so the harness reports counts and does not assert them: it is evidence for a reader, not a gate.

### A4. The id-collision harness (drill k7, V21)

```gdscript 7aa-ids
extends SceneTree
## Row 7aa, drill k7: why CrewConsole._serial is static. Console A offers and the sim accepts it; then
## consoles B and C are built from the same crew (same turn, same revision, no send between them) and
## each offers the same member. B and C must get different ids, and C's offer must not be refused.
func _initialize() -> void:
	var us := SimBridge.new()
	us.want_minor = SimBridge.CONSOLE_MINOR
	var ok := us.start() and us.new_game(1, "free_nav", false, {}, "", "orders")
	var pa := CrewConsole.new()
	pa.show_crew(us.crew)
	var oa := pa.offer_intents("counselor")
	ok = ok and us.send(oa, 0.0) and us.last_refused.is_empty()
	var pb := CrewConsole.new()
	pb.show_crew(us.crew)
	var ob := pb.offer_intents("counselor")
	var pc := CrewConsole.new()
	pc.show_crew(us.crew)
	var oc := pc.offer_intents("counselor")
	var ib: String = JSON.parse_string(ob[0].line).id
	var ic: String = JSON.parse_string(oc[0].line).id
	print("K7IDS a=%s b=%s c=%s turn=%s revision=%s" % [JSON.parse_string(oa[0].line).id, ib, ic, us.crew.get("turn"), us.crew.get("revision")])
	print("K7IDS b_and_c_same=%s" % (ib == ic))
	ok = ok and us.send(ob, 0.0)
	print("K7IDS b_refused=%d" % us.last_refused.size())
	ok = ok and us.send(oc, 0.0)
	print("K7IDS c_refused=%d %s" % [us.last_refused.size(), ",".join(us.last_refused.map(func(r): return str(r.get("reason", ""))))])
	us.stop(); pa.free(); pb.free(); pc.free()
	print("k7-ids: %s" % ("done" if ok else "sim failed"))
	quit(0)
```

The harness asserts nothing itself; drill k7 asserts on its `K7IDS` lines, and `k7-ids: done` is the positive control that the sim answered every step. It needs the protocol minor `CONSOLE_MINOR`, the one `crew-console-test` uses for the same section.
