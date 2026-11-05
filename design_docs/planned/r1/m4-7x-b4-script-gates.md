# Row 7x batch B4: the `Makefile`'s `--script` gates from line 1080 through `$(SCRIPT_GATE)`, a pin on `SG_PREREQS`, and an orphan table

**Status:** Planned, mission iteration 72, designer, 2026-11-05; **revision 1** after design quorum round 1 (see [Quorum r1 response](#quorum-r1-response-revision-1)). **Release:** r1. **Milestone:** charter queue row **7x**, follow-up batch **B4** (W6 of the landed 7x design), inside the approved sprint `R1-M4-JOURNEY` (D-22/D-66).
**Priority:** P2 (follow-up backlog, [LOOP]). Test and build hygiene only.
**Implements:** [charter](../../stapledon-mission.md) row 7x ("Remaining: … B4 (`Makefile` 1080+, 86 rows) …; judge survivor: nothing asserts the `SG_PREREQS` list itself") and the iteration-71 retro item 3 ("B4 should list which migrated targets no aggregate runs"). It follows [m4-7x-b3-script-gates.md](m4-7x-b3-script-gates.md) (format and contract), [m4-7x-b2-script-gates.md](m4-7x-b2-script-gates.md) and the migration rule of [m4-7x-script-gate-predicates.md](m4-7x-script-gate-predicates.md). No design-repo feature or [relativity spec](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md) section changes: no formula, sim, protocol, shader, scene, sound or anything the player sees changes.
**Depends on:** the landed 7x helper, lint and baseline (PR #393), B2a (PR #395) and B3a with the prerequisite guard (PR #397, merge `b34fd1ef`); D-88 A (test or audit hygiene inside an approved sprint, with no pillar below 0, does not stop); Godot 4.7.2; AILANG v0.56.1 (`runtime/bin`, staged with `make runtime`).
**Estimated LOC:** **+135/−164 in 24 files** (`git diff --numstat`, V24; revision 0 was +132/−163 in 23 files, V19). Hand-written: +135/−108; the other 56 deletions are baseline rows. No new file, so no new `.uid`.

**Evidence:** the [Verification log](#verification-log). Every row was run first-hand in `/Users/voightkampff/dev/sunholo-data/stapledons-godot-iter72` at `05e64cd1` on 2026-11-05, 15:28–17:25 CET, with Godot `4.7.2.stable.official.ed1daf0bf` and AILANG v0.56.1 from the clone's `runtime/bin` (V3). Every base row was measured before the change was applied (V4–V7). Two exceptions: the windowed base run (V5) went on after 16:29, when the change set was in place, but no windowed recipe line or script is in it. The base runtime-error drill (V8) read the base scripts and `Makefile` through `git show HEAD:`. The whole B4a change set was then applied, every migrated gate was run end to end through `$(SCRIPT_GATE)` with the lint, self-test and drill (V9–V18), and the diff was saved as `/tmp/iter72_designer/b4.diff` (sha256 `9716f916…`), checked to apply to `05e64cd1` in a scratch index, and the tracked files were restored. `git status --porcelain` is empty apart from this doc (V19). **Revision 1** (17:27–18:10 CET, same clone, same `05e64cd1`) re-applied that diff with `patch -p1` and bounded `tools/ship_baseline.sh`. It ran AC5's target-list check and AC7–AC9 from this doc's own [Appendix](#appendix-the-ac-inputs-and-harness-revision-1), extracted with the stated `x` command (V21). It demonstrated the fetch bound against a stalled server and a connect blackhole (V22), re-ran the lint, self-test, drill, AC10 and hygiene on the revised tree (V23), and saved the new diff (V24). No git command wrote anything in revision 1 (V24).

**The split, in one line.** **B4a: 56 rows** (48 targets, 57 gate lines), every headless row of the 86 except three: all measured at base and through their migrated line, all green. **B4b: 30 rows**: 27 rows that need a GPU window (7 of them red or timed out at base under a 0–100 % GPU), 2 authoring rows that write tracked files, and `sim-pipeline-test`, which is red on every run at base and that no aggregate runs. The pin `SCRIPT_GATE_BASELINE_ROWS` goes from **175 to 119**, and the new pin `SG_PREREQS_PAIRS` is **4**.

## Quorum r1 response (revision 1)

Round 1 was **BLOCKED, 2 of 3**: oc-kimi-k3 and gpt6-1-sol rejected, and gemini passed with a note. The controller also rejected. This is the one permitted revision. Every fix was measured on the revised tree, and the change set grows by one file (`tools/ship_baseline.sh`, +3/−1).

| # | Seat and objection | Change in this revision | Evidence |
|---|---|---|---|
| 1 | oc-kimi-k3, the controller, and gemini's note: AC5 and AC7–AC9 read `/tmp/iter72_designer/` (the target list, `drill.sh`, the rt rows, `zero.sh`), so an evaluator in a fresh clone cannot run them. | **Option (b).** A new [Appendix](#appendix-the-ac-inputs-and-harness-revision-1) holds four named blocks: A1, the 48 targets; A2, the drill harness, verbatim; A3, the 8 runtime-drill pairs; A4, the 22 zero-probe pairs. One stated command, `x`, extracts them (above the AC table), and AC5 and AC7–AC9 now read only the clone and this doc. No harness ships, so the change set gets no new tool. Re-run from the extracted blocks:<br>- A1 equals the 48 gated targets from `Makefile:1080`, and `make -n` accepts them;<br>- AC7 gives `57 rc=2`;<br>- AC8 gives `8 rc=2` on the B4a tree and 6 of 8 `rc=0` at base;<br>- AC9 gives `22 zeroed=0 real=1`, with each ERE found in the `Makefile`.<br>**Found while doing this:** the revision-0 scratch harness wrote `$$$$` for `GODOT_SIM`, so its `$(GODOT_SIM)` rows ran with a bogus `AILANG_BIN`. That confounded V8's `ship-demo-live-test` row: the sim never started. A2 writes `$$` (as the `Makefile` does). Re-measured, the row still fails at base, now for the right reason: 17 checks erroring, and the pinned `ok` line absent. V8's conclusion (6 of 8 pass at base) stands. | V21 |
| 2 | oc-kimi-k3: D3 pattern 1 says "This applies to 16 files" but lists 15. | Corrected to **15**: 12 files that had a summary, plus the 3 that had none. | V20: `git diff --name-only \| xargs grep -lE 'passes ?\+= ?int\(ok\)'` gives `15` |
| 3 | oc-kimi-k3: AC9's "22 ERE/line pairs" cannot be derived from D2. | A4 lists the 22 pairs by D2 row, each with the measured pass line as a positive control:<br>- 20 cover every changed positive ERE. Rows 1 and 12 share one ERE (1 pair); row 49's two-count line is **two** pairs, 49a and 49b;<br>- row 6 (`ship-commons-arcade`) is **in**;<br>- row 2 (`ship-demo`) is the unchanged-format control.<br>AC9 now also checks that each ERE is the `Makefile`'s own. | V21 |
| 4 | gpt6-1-sol: D5 makes `ship-baseline`, a network fetch, a prerequisite with no evidence that it is bounded on failure. That time falls outside the 600 s gate. | **Bounded.** `tools/ship_baseline.sh:28` (unchanged since `c61f8599`) runs `curl -fsS --retry 3` with **no connect or total timeout**. Against a stalled server (it accepts, then never answers) it was still waiting when the 150 s ceiling killed it: rc 142, no output. Connect failures were already finite on this host. The unroutable `10.255.255.1` and `192.0.2.1` fail in 4–5 s, and a loopback connect blackhole fails in 39 s (four attempts, each cut by the OS's own SYN limit at 7.8 s, not by curl). So the unbounded case is a stall after connecting. Revision 1 changes that line to `curl -fsS --connect-timeout 10 --max-time 60 --retry 2 --retry-max-time 120`. No open PR touches the file, which is in `tools/`; `mk/deck-layout.mk` stays unedited. Measured:<br>- stalled server: **121 s**, rc 1, `ship-baseline: FAIL fetch ship.glb`;<br>- blackhole: rc 1 in 27 s (three attempts);<br>- through `make ship-console-test` on a stalled server: `make: *** [ship-baseline] Error 1`, rc 2, in 125 s, with **no `script-gate:` line and the test log untouched**, so Godot's test never started;<br>- a real fetch: rc 0 in 1 s, byte-identical files.<br>D5 states the prerequisite bound (≤ 183 s per file, ≤ 549 s per fetch) and the 600 s gate bound separately. | V22, V23 |

## Quorum r2 response (revision 2, controller, narrow-refinement carve-out)

Round 2 (`m4-7x-b4-script-gates-2026-11-05T17-03-08Z`, $0.59, same seats, `absent_reviewers` empty): **BLOCKED 1/3**; oc-kimi-k3 pass, gemini-4-argon pass, gpt6-1-sol reject. The reject carried a reviewer-written fix and did not dispute the direction, so the controller applied it verbatim and measured it (mission-control Gate 2 narrow-refinement carve-out).

| Objection | Fix applied | Evidence |
|---|---|---|
| gpt6-1-sol: V9 reports 0 matches for an unqualified `grep -c FAIL`, but four successful negative gates print `FAIL` in their reason text | V9's command replaced with the reviewer's status-anchored form `grep -h '^script-gate:' mig/*.out \| grep -cE '^script-gate: [^ ]+ FAIL'`; the unanchored count and the five negatives recorded separately | Controller re-measure on the designer's V9 outputs (`/tmp/iter72_designer/mig/*.out`, 49 files): 57 distinct gate names; anchored FAIL statuses **0**; unanchored **4** (the four negatives named in V9); all five negatives `ok … (rc 1, no SCRIPT ERROR …)`. AC5 already used the anchored form, so no AC changes. |

Non-blocking notes from the passing reviewers, recorded for the plan and the judge, not designed here:
- oc-kimi-k3: D5's "worst case = `import` + ≤ 549 s + ≤ 600 s" is not a full bound, because `import` (a pre-existing prerequisite, unchanged here) has no deadline. Read D5's figure as bounding the two terms this batch adds or gates, not the whole target.
- gemini-4-argon: D3 pattern 3 turns short-circuit `and` chains in `test_ship_demo_benchmark.gd` and `test_ship_demo_launch.gd` into eagerly evaluated arrays, so a failure path can now raise a `SCRIPT ERROR` (for example `main.sim.world` read when `pid <= 0`) instead of a counted failure. Controller reading: this fails closed, because `$(SCRIPT_GATE)` refuses any `SCRIPT ERROR`, so it cannot turn a failure into a pass; the executor may guard the later conjuncts (for example `main.sim != null and …`) without changing any passing summary.

## Game vision alignment

Scored against the [core pillars](https://github.com/sunholo-data/stapledons-design/blob/main/vision/core-pillars.md) (design repo `35793fc`, 2026-09-27), in the `game-vision-designer` skill's feature-validation mode: **ALIGNED (neutral)**, with no conflict.

| Pillar | Relevance | Score | Notes |
|---|---|---:|---|
| Choices Are Final | 0 | 0 | No game code touched. |
| The Game Doesn't Judge | 0 | 0 | No text the player sees. `news-lint` still lints the same news copy; only its own summary line changes. |
| Time Has Emotional Weight | 0 | 0 | The sim and its clocks are untouched. `ship-demo-live-test` and `solar-departure-test` keep every clock assert. |
| The Ship Is Home | 0 | 0 | No scene change. |
| Grounded Strangeness | 0 | 0 | No visual change. No windowed row is touched (B4b). |
| We Are Not Built For This | 0 | 0 | No change to the crew or to consequences. |
| Hard sci-fi authenticity (spec) | 0 | 0 | `flyby-optics-test`, `planet-rings-test`, `planet-meter-test`, `ship-star-light-test` and `solar-departure-test` keep every assert. After this change they pass only if the script ran to its summary with no `SCRIPT ERROR`. Today a runtime error in `check()` turns `flyby-optics-test` into `0 checks, 0 failures`, and that passes (Problem 3). |
| **Net** | | **0** | **Go under D-88 A.** This is suite hygiene inside the approved sprint, and no pillar goes negative. Nothing visual or audible changes: 19 scripts' summary lines gain a count, and no render, sound or scene changes. No dev-build review is needed. |

## Problem

V-numbers refer to rows of the [Verification log](#verification-log).

1. **86 `--script` rows from `Makefile:1080` on are ungated.** Instrument: `SCRIPT_GATE_BASELINE_ROWS=175 sh tools/script_gate_lint.sh --inventory`, filtered with `awk` on `file == "Makefile"`, `line >= 1080` and class `ungated` (V2). That gives 86, and 30 ungated rows below line 1080 (116 in the `Makefile` in all), as the controller measured. No B4 row is `gated` or `other`. The 86 rows belong to 77 targets: 59 rows are headless and 27 need a GPU window.
2. **Five rows check nothing, and all five pass a test that never ran** (four in B4a, plus the authoring row). `validate-ship-demo` (`:1093`), `validate-ship-commons` (`:1120`), `ship-demo-assets-test`'s first two lines (`:1125`, `:1126`) and the authoring row `ship-demo-sky-states` (`:1159`) are bare `$(GODOT)` lines with no predicate (`-,-,-,-`). **Measured:** each line run as written, with its script swapped for a parse-error copy, exits **rc 0**. All 54 other headless rows fail that drill (V7).
3. **A runtime error that skips every check passes six of the eight rows drilled.** Each drill puts one runtime error at the top of the script's `check()`, so every check aborts and the script still reaches its summary (V8, re-measured with the corrected harness in V21):
   - `ship-demo-test` prints `ship-demo: 0 passed, 0 failures` and passes, with 244 checks skipped;
   - `catalogue-coverage-test` prints `0 passed` and passes; `flyby-optics-test` prints `0 checks, 0 failures` and passes, with 1,061 skipped;
   - `ring-protocol-test` and `tour-pacing-test` print `0 failures` and pass;
   - `validate-ship-demo` passes, with 24 `SCRIPT ERROR` lines and a summary of `OK`.

   Only `ship-attitude-test` (its predicate checks `SCRIPT ERROR`) and `ship-demo-live-test` (it pins one `ok` line) fail it. **31 of the base predicates accept a zero count** (`[0-9]* passed`/`checks`, V14). After this change, the migrated line fails all eight (V12).
4. **Two headless rows are red at base:**
   - **`ship-console-test` needs `build/ship-baseline` but does not fetch it.** In this fresh clone it gives **rc 2**, `FAIL AC4 fallback: the pinned baseline is fetched (make ship-baseline)` and `ship-consoles: 133 passed, 1 failures`. After `make ship-baseline` it gives rc 0 and `135 passed` (V4, V5). It is the same class of defect as B3's `constellation-test: starmap-assets`. Under `make test`, `ship-baseline` is also a prerequisite of `deck-layout-eval-test` (`mk/deck-layout.mk:11`). So whether the baseline is fetched before `ship-console-test` runs depends on the order make picks (inferred from the rules, not measured).
   - **`sim-pipeline-test` is red on every run:** three runs gave rc 2, 49–54 s, `FAIL same inputs in the same order (sent journal)`, `FAIL same world at the end`, `FAIL same crew at the end`, `sim-pipeline: 3 failures` (V4, V5). No aggregate runs it (V17), so nothing noticed, as with `alpha-centauri-golden` in iteration 71.

   The other 47 headless targets are rc 0 at base, with 0 `SCRIPT ERROR` in every log (V4).
5. **20 positive rows, in 19 scripts, print no counted summary**, so the per-count zero probe (`tools/script_gate.sh:38–54`) would refuse them:
   - `OK`/`FAIL` with no count: `validate_ship_demo.gd`, `validate_ship_commons.gd`, `test_ship_commons_assets.gd`, `test_ship_demo_assets.gd`, `test_ship_demo_benchmark.gd`, `test_ship_demo_launch.gd`, `news_lint.gd`;
   - `<name>: N failures` with no passes: `test_ring_protocol.gd`, `test_ship_attitude.gd`, `test_benchmark_upload.gd`, `test_shadow_contacts.gd`, `test_tour_attitude.gd`, `test_tour_pacing.gd`, `test_destination_pin.gd`, `test_cruise_interlude.gd`, `test_frame_check.gd`;
   - no summary line at all: `test_runtime_fingerprint.gd`, `test_live_journey.gd`, `test_ship_demo_live.gd`. Today `ship-demo-live-test` pins one `ok <label>` line from each (V6).
6. **Iteration-71 judge survivor: nothing asserts `SG_PREREQS` itself.** At base, with a pair dropped from the list, `make script-gate-lint` gives **rc 0** and `script-gate-prereqs: ok (2 pairs hold …)`. The negative control and the real check both read the list, so neither notices (V13, control).
7. **Orphans (iteration-71 retro 3).** 13 already-gated targets are reachable from no aggregate (`test`, `ci-fast` or `golden`). That covers `alpha-centauri-golden`, which was red on main until B3a. B4a adds a 14th, `frame-check-test` (V17, D8).
8. **New measurement, windowed rows: a parse error exits rc 1 when Godot opens a window.** The same parse-error copy gave rc 0 under `--headless` and **rc 1** with `--audio-driver Dummy` and no `--headless` (raw runs, V7). All 27 windowed rows fail the parse drill at base for that reason. The helper's reason text, "Godot exits 0 on a parse error", is accurate for headless runs only. That is a wording note for B4b, not a defect (OQ4).

**Brief premises re-checked.**
- "86 such rows; 116 ungated in Makefile in total; 30 below line 1080": **true** (V2).
- "Open attended PRs #373, #379, #380 edit hunks around lines 10–251 and 485": **true**. Their `Makefile` hunks start at `-10`, `-18`, `-225`, `-245` (#380 only) and `-485` (#379). None is at line 1080 or later. #384 does not touch the `Makefile` (V16).
- "A B4 row's test script used by a row in a protected file": **none**. No `--script` row in `Makefile` below line 1080, `mk/m45.mk`, `mk/deck-layout.mk`, `mk/earth-link.mk` or `mk/sound.mk` names a B4 script. The one outside caller of a B4 script is `tests/test_playthrough.sh:11`. It runs `tests/m4_playthrough_ship.gd` on failing scripts, wants rc 1 and `FAIL <reason>`, and requires the `^playthrough: [0-9]* passed, 0 failures$` line to be absent (`:13–15`). B4a does not change that script (V15). `ship-baseline` is *defined* in `mk/deck-layout.mk:6`. B4a only names it as a prerequisite on `Makefile:1337`, and does not edit that file.
- "Rows depending on the shared `tools/m4_ship_golden.gd` count question": **none in B4**. No B4 script names it (V15).
- "The GPU is busy (50–100 %)": **true and intermittent**. `ioreg` `Device Utilization %` read 0–100 across the runs, with an Ollama runner (`gemma4:12b-mxfp8`) active (V3, V5). B4a has no windowed row, so the load matters only for B4b's base column. The 1-minute load reached 18.9 during the migrated run, and every B4a gate was still green (V9).
- "A fresh clone has no `runtime/`": **true**. `make runtime` staged v0.56.1 in 3.8 s, before any measurement (V3).

## Goals and non-goals

**Goals.**
1. **B4a: migrate 56 rows** (48 make targets) to `$(SCRIPT_GATE)` lines, 57 gate lines in all, because the `ship-demo-geometry-negative-test` loop becomes two. Each row was measured at base and through its migrated line (V4, V9).
2. **Add counted summaries to the 19 scripts of Problem 5.** The counts are measured equal to an independent reading of the same run (V10). No assert changes.
3. **Bind every negative control to its own failure reason** (D4): 5 lines with WANT_RC 1.
4. **`ship-console-test: import ship-baseline`**, plus the pair `ship-console-test:ship-baseline` in `SG_PREREQS`, with the fetch bounded in `tools/ship_baseline.sh` (D5; revision 1).
5. **Pin `SG_PREREQS`** (judge survivor; D6): `SG_PREREQS_PAIRS := 4`, and `script-gate-lint` fails unless the list holds exactly that many distinct pairs.
6. **Delete the 56 baseline rows and set the pin from 175 to 119** (D7).
7. **Record the orphan table** (D8) and **B4b's 30 rows with a one-line blocker each** (D9).

**Non-goals.**
- No edit to the `Makefile` below line 1080, `mk/m45.mk`, `mk/deck-layout.mk`, `mk/earth-link.mk` (attended PRs #373/#379/#380/#384) or `mk/sound.mk` (B7, attended R2-SOUND).
- No change to `tools/script_gate.sh`, `tools/test_script_gate.sh`, `tools/script_gate_lint.sh` or `tools/script_gate_prereqs.sh`. The self-test stays at 18 cases and the drill at 24. `tools/ship_baseline.sh` changes only its one curl line (revision 1, D5).
- No assert changes. The single-verdict scripts (`ship-demo-benchmark`, `ship-demo-launch`) count the conjuncts of their existing verdict (D3).
- No fix to `sim-pipeline-test` (a behavioural red, not a predicate defect; OQ1), and no change to which targets an aggregate runs (D8, OQ2).

## Design

### D1. The migration rule (as in B3 D1)

```
@$(SCRIPT_GATE) NAME LOG DEADLINE 'SUMMARY_ERE' [WANT_RC] -- <the row's own Godot command, unchanged>
```

- **NAME** is the make target, except where one target has several Godot lines. Those lines take the name of their log: `ship-commons-assets` / `ship-commons-assets-negative`; `ship-runtime-fingerprint` / `ship-live-sim` / `ship-live-demo`; `ship-demo-assets` / `ship-demo-assets-validate` / `ship-demo-assets-negative`; `ship-demo-geometry-wrong-tier` / `-wrong-tip`; `tour-pacing` / `destination-pin` / `cruise-interlude`; `news-lint` / `news-lint-stray-digit`. The lint keys rows on target and script, not on NAME.
- **LOG** is the row's existing log path. Four rows had no log and get `$(SCRATCH)/<name>.log`: `validate-ship-demo`, `validate-ship-commons`, `ship-demo-assets`, `ship-demo-assets-validate`. `playthrough` keeps `$(PLAYTHROUGH_OUT)/run.log`.
- **DEADLINE** is the smallest multiple of 600 s that is at least 5× the base wall time of the whole target:
  - 600 s for every row whose target measured ≤ 120 s;
  - 1,200 s for `playthrough` (`playthrough-adversarial` measured 155 s);
  - 1,800 s for `free-nav-stop-test` (276 s) and `no-twitch-test` (243 s);
  - 3,000 s for `solar-departure-test` (490 s at base; **603 s** through the gate at a 1-minute load near 5, V9). At 600 s that row would have timed out. That is why the deadline is per row.
- **The Godot command is unchanged:** `$(GODOT)` or `$(GODOT_SIM)`, and the row's own user arguments, `-- $(SCRIPT) $(PLAYTHROUGH_OUT) $(AI)` included. A script checks that each migrated line keeps its base line's script, Godot variable and user arguments (`applymap.pl`, V9).
- **Dropped:** the `> LOG 2>&1; rc=$$?; cat/grep/tail …; test …` tails, the `|| { echo …; exit 1; }` continuation lines of `news-lint`, `news-test` and `codex-test`, and the now-redundant `@mkdir -p $(SCRATCH)`/`$(PLAYTHROUGH_OUT)` before 7 migrated lines. The helper creates the log's directory (`tools/script_gate.sh:26`). `news-lint`'s final `echo` stays.
- **Regexes:** every count is `[1-9][0-9]*`, and every summary is anchored `^…$$`. The one literal pin is `ship-commons-arcade`'s `plaza=true … roof=true open_arch=true`, around its counted `measured_terrace_vertices=[1-9][0-9]*` (the script asserts `terrace>100` and exits 1 otherwise; OQ3).
- **Behaviour change, deliberate (as in 7x W5, B2 D1 and B3 D1).** On a pass, a gate prints one `script-gate: NAME ok: <summary> (rc, no SCRIPT ERROR, s of DEADLINE s)` line instead of the log excerpt. On a failure, it prints the log's non-`ok` lines and every reason. The full log stays at LOG.

### D2. The per-gate table: the 56 B4a rows (normative)

Line numbers are at `05e64cd1` (V2).
- **Today** is the inventory flag set: `rc` means rc is checked, `se` a `SCRIPT ERROR` check, `sum` a summary grep, `to` a timeout; `-` means absent.
- **Base** is the measured target rc and wall time (V4), with the last summary line of the row's own log.
- **Parse drill (today)** is the row's own line run with a parse-error copy of its script (V7).
- **After** is the measured migrated line (V9).
- **Edit** means the script's summary changes in D3.

| # | Target (`Makefile:line`) | Script | Today | Base: rc, s; summary (measured) | Parse drill (today) | SUMMARY_ERE (WANT_RC 0 unless stated) | DEADLINE s | After (V9) | Edit |
|---|---|---|---|---|---|---|---:|---|---|
| 1 | `validate-ship-demo` (`:1093`) | `tools/validate_ship_demo.gd` | -,-,-,- | 0, 1 s; `validate-ship-demo: OK` | **passes** | `^validate-ship-demo: OK \([1-9][0-9]* passed, 0 failures\)$$` | 600 | `validate-ship-demo: OK (24 passed, 0 failures)`; rc 0, 1 s | **yes** |
| 2 | `ship-demo-test` (`:1096`) | `tests/test_ship_demo.gd` | rc,-,sum,- | 0, 0 s; `ship-demo: 244 passed, 0 failures` | fails | `^ship-demo: [1-9][0-9]* passed, 0 failures$$` | 600 | `ship-demo: 244 passed, 0 failures`; rc 0, 1 s | no |
| 3 | `ship-commons-test` (`:1106`) | `tests/test_ship_commons.gd` | rc,-,sum,- | 0, 13 s; `ship-commons: 39 passed, 0 failures` | fails | `^ship-commons: [1-9][0-9]* passed, 0 failures$$` | 600 | `ship-commons: 39 passed, 0 failures`; rc 0, 19 s | no |
| 4 | `ship-commons-assets-test` (`:1108`) | `tests/test_ship_commons_assets.gd` | rc,-,sum,- | 0, 2 s; `ship-commons-assets: OK` | fails | `^ship-commons-assets: OK \([1-9][0-9]* passed, 0 failures\)$$` | 600 | `ship-commons-assets: OK (16 passed, 0 failures)`; rc 0, 1 s | **yes** |
| 5 | `ship-commons-assets-test` (`:1109`) | `tools/validate_ship_commons.gd` | rc,-,sum,- | 0, 2 s; `validate-ship-commons: FAIL` | fails | `^  FAIL actual new vertices inside95m envelope$$` (WANT_RC **1**) | 600 | `  FAIL actual new vertices inside95m envelope`; rc 1, 1 s | **yes** |
| 6 | `ship-commons-arcade-test` (`:1111`) | `tests/test_ship_commons_arcade.gd` | rc,-,sum,- | 0, 0 s; `ship-commons-arcade: OK plaza=true measured_terrace_vertices=6142 roof=true open_arch=true` | fails | `^ship-commons-arcade: OK plaza=true measured_terrace_vertices=[1-9][0-9]* roof=true open_arch=true$$` | 600 | `ship-commons-arcade: OK plaza=true measured_terrace_vertices=6142 roof=true open_arch=true`; rc 0, 1 s | no |
| 7 | `ship-demo-live-test` (`:1114`) | `tests/test_runtime_fingerprint.gd` | rc,-,sum,- | 0, 110 s; `ok nested module edit invalidates bundled cache` | fails | `^runtime-fingerprint: [1-9][0-9]* passed, 0 failures$$` | 600 | `runtime-fingerprint: 6 passed, 0 failures`; rc 0, 0 s | **yes** |
| 8 | `ship-demo-live-test` (`:1115`) | `tests/test_live_journey.gd` | rc,-,sum,- | 0, 110 s; `ok arrival point matches target` | fails | `^live-journey: [1-9][0-9]* passed, 0 failures$$` | 600 | `live-journey: 17 passed, 0 failures`; rc 0, 26 s | **yes** |
| 9 | `ship-demo-live-test` (`:1116`) | `tests/test_ship_demo_live.gd` | rc,-,sum,- | 0, 110 s; `ok arrival stays rest` | fails | `^ship-demo-live: [1-9][0-9]* passed, 0 failures$$` | 600 | `ship-demo-live: 9 passed, 0 failures`; rc 0, 87 s | **yes** |
| 10 | `validate-ship-commons` (`:1120`) | `tools/validate_ship_commons.gd` | -,-,-,- | 0, 0 s; `validate-ship-commons: OK` | **passes** | `^validate-ship-commons: OK \([1-9][0-9]* passed, 0 failures\)$$` | 600 | `validate-ship-commons: OK (25 passed, 0 failures)`; rc 0, 2 s | **yes** |
| 11 | `ship-demo-assets-test` (`:1125`) | `tests/test_ship_demo_assets.gd` | -,-,-,- | 0, 1 s; `ship-demo-assets: OK` | **passes** | `^ship-demo-assets: OK \([1-9][0-9]* passed, 0 failures\)$$` | 600 | `ship-demo-assets: OK (13 passed, 0 failures)`; rc 0, 1 s | **yes** |
| 12 | `ship-demo-assets-test` (`:1126`) | `tools/validate_ship_demo.gd` | -,-,-,- | 0, 1 s; `validate-ship-demo: OK` | **passes** | `^validate-ship-demo: OK \([1-9][0-9]* passed, 0 failures\)$$` | 600 | `validate-ship-demo: OK (24 passed, 0 failures)`; rc 0, 1 s | **yes** |
| 13 | `ship-demo-assets-test` (`:1127`) | `tools/validate_ship_demo.gd` | rc,-,sum,- | 0, 1 s; `validate-ship-demo: FAIL` | fails | `^  FAIL tier height 1$$` (WANT_RC **1**) | 600 | `  FAIL tier height 1`; rc 1, 1 s | **yes** |
| 14 | `ship-demo-lift-test` (`:1129`) | `tests/test_ship_demo_lift.gd` | rc,-,sum,- | 0, 5 s; `ship-demo-lift: 29 passed, 0 failures` | fails | `^ship-demo-lift: [1-9][0-9]* passed, 0 failures$$` | 600 | `ship-demo-lift: 29 passed, 0 failures`; rc 0, 12 s | no |
| 15 | `ship-demo-benchmark-test` (`:1139`) | `tests/test_ship_demo_benchmark.gd` | rc,-,sum,- | 0, 0 s; `ship-demo-benchmark: OK` | fails | `^ship-demo-benchmark: OK \([1-9][0-9]* passed, 0 failures\)$$` | 600 | `ship-demo-benchmark: OK (3 passed, 0 failures)`; rc 0, 1 s | **yes** |
| 16a | `ship-demo-geometry-negative-test` (`:1141`) | `tools/validate_ship_demo.gd` | rc,-,sum,- | 0, 1 s (loop, both); `validate-ship-demo: FAIL` (wrong-tier, wrong-tip) | fails | `^  FAIL actual exported tier height 3$$` (WANT_RC **1**) | 600 | `  FAIL actual exported tier height 3`; rc 1, 1 s | **yes** |
| 16b | `ship-demo-geometry-negative-test` (`:1141`) | `tools/validate_ship_demo.gd` | rc,-,sum,- | 0, 1 s (loop, both); `validate-ship-demo: FAIL` (wrong-tier, wrong-tip) | fails | `^  FAIL actual bridge needle98m$$` (WANT_RC **1**) | 600 | `  FAIL actual bridge needle98m`; rc 1, 1 s | **yes** |
| 17 | `ship-demo-launch-test` (`:1148`) | `tests/test_ship_demo_launch.gd` | rc,-,sum,- | 0, 7 s; `ship-demo-launch: OK` | fails | `^ship-demo-launch: OK \([1-9][0-9]* passed, 0 failures\)$$` | 600 | `ship-demo-launch: OK (4 passed, 0 failures)`; rc 0, 16 s | **yes** |
| 18 | `ship-demo-input-test` (`:1155`) | `tests/test_ship_demo_input.gd` | rc,-,sum,- | 0, 5 s; `ship-demo-input: 30 passed, 0 failures` | fails | `^ship-demo-input: [1-9][0-9]* passed, 0 failures$$` | 600 | `ship-demo-input: 30 passed, 0 failures`; rc 0, 11 s | no |
| 19 | `ship-demo-journey-test` (`:1157`) | `tests/test_ship_demo_journey.gd` | rc,-,sum,- | 0, 4 s; `ship-demo-journey: 47 passed, 0 failures` | fails | `^ship-demo-journey: [1-9][0-9]* passed, 0 failures$$` | 600 | `ship-demo-journey: 47 passed, 0 failures`; rc 0, 6 s | no |
| 20 | `ship-star-identification-test` (`:1166`) | `tests/test_ship_star_identification.gd` | rc,-,sum,- | 0, 9 s; `ship-star-identification: 59 passed, 0 failures` | fails | `^ship-star-identification: [1-9][0-9]* passed, 0 failures$$` | 600 | `ship-star-identification: 59 passed, 0 failures`; rc 0, 15 s | no |
| 21 | `free-nav-stop-test` (`:1174`) | `tests/test_free_nav_stop.gd` | rc,se,sum,- | 0, 276 s; `free-nav-stop: 52 passed, 0 failures` | fails | `^free-nav-stop: [1-9][0-9]* passed, 0 failures$$` | 1800 | `free-nav-stop: 52 passed, 0 failures`; rc 0, 366 s | no |
| 22 | `ship-demo-consolidation-test` (`:1182`) | `tests/test_ship_demo_consolidation.gd` | rc,-,sum,- | 0, 8 s; `ship-demo-consolidation: 18 passed, 0 failures` | fails | `^ship-demo-consolidation: [1-9][0-9]* passed, 0 failures$$` | 600 | `ship-demo-consolidation: 18 passed, 0 failures`; rc 0, 7 s | no |
| 23 | `title-screen-test` (`:1193`) | `tests/test_title_screen.gd` | rc,se,sum,- | 0, 31 s; `title-screen: 111 passed, 0 failures` | fails | `^title-screen: [1-9][0-9]* passed, 0 failures$$` | 600 | `title-screen: 111 passed, 0 failures`; rc 0, 44 s | no |
| 24 | `loading-jump-test` (`:1203`) | `tests/test_loading_jump.gd` | rc,-,sum,- | 0, 38 s; `loading-jump: 82 passed, 0 failures` | fails | `^loading-jump: [1-9][0-9]* passed, 0 failures$$` | 600 | `loading-jump: 82 passed, 0 failures`; rc 0, 41 s | no |
| 25 | `ship-movement-test` (`:1218`) | `tests/test_ship_movement.gd` | rc,-,sum,- | 0, 5 s; `ship-movement: 6 passed, 0 failures` | fails | `^ship-movement: [1-9][0-9]* passed, 0 failures$$` | 600 | `ship-movement: 6 passed, 0 failures`; rc 0, 3 s | no |
| 26 | `map-origin-test` (`:1220`) | `tests/test_map_origin.gd` | rc,-,sum,- | 0, 12 s; `map-origin: 58 passed, 0 failures` | fails | `^map-origin: [1-9][0-9]* passed, 0 failures$$` | 600 | `map-origin: 58 passed, 0 failures`; rc 0, 16 s | no |
| 27 | `ship-planets-test` (`:1222`) | `tests/test_ship_planets.gd` | rc,-,sum,- | 0, 7 s; `ship-planets: 21 passed, 0 failed` | fails | `^ship-planets: [1-9][0-9]* passed, 0 failed$$` | 600 | `ship-planets: 21 passed, 0 failed`; rc 0, 4 s | no |
| 28 | `ship-star-light-test` (`:1233`) | `tests/test_ship_star_light.gd` | rc,-,sum,- | 0, 8 s; `ship-star-light: 129 passed, 0 failures` | fails | `^ship-star-light: [1-9][0-9]* passed, 0 failures$$` | 600 | `ship-star-light: 129 passed, 0 failures`; rc 0, 6 s | no |
| 29 | `catalogue-coverage-test` (`:1260`) | `tests/test_catalogue_coverage.gd` | rc,-,sum,- | 0, 3 s; `catalogue-coverage: 7 passed, 0 failures` | fails | `^catalogue-coverage: [1-9][0-9]* passed, 0 failures$$` | 600 | `catalogue-coverage: 7 passed, 0 failures`; rc 0, 1 s | no |
| 30 | `solar-departure-test` (`:1262`) | `tests/test_solar_departure.gd` | rc,-,sum,- | 0, 490 s; `solar-departure: 134 passed, 0 failures` | fails | `^solar-departure: [1-9][0-9]* passed, 0 failures$$` | 3000 | `solar-departure: 134 passed, 0 failures`; rc 0, 603 s | no |
| 31 | `flyby-optics-test` (`:1267`) | `tests/test_flyby_optics.gd` | rc,-,sum,- | 0, 2 s; `flyby-optics: 1061 checks, 0 failures` | fails | `^flyby-optics: [1-9][0-9]* checks, 0 failures$$` | 600 | `flyby-optics: 1061 checks, 0 failures`; rc 0, 1 s | no |
| 32 | `planet-rings-test` (`:1269`) | `tests/test_planet_rings.gd` | rc,-,sum,- | 0, 3 s; `planet-rings: 28 checks 0 failures` | fails | `^planet-rings: [1-9][0-9]* checks 0 failures$$` | 600 | `planet-rings: 28 checks 0 failures`; rc 0, 0 s | no |
| 33 | `ring-protocol-test` (`:1271`) | `tests/test_ring_protocol.gd` | rc,-,sum,- | 0, 12 s; `ring-protocol: 0 failures` | fails | `^ring-protocol: [1-9][0-9]* passed, 0 failures$$` | 600 | `ring-protocol: 9 passed, 0 failures`; rc 0, 11 s | **yes** |
| 34 | `planet-meter-test` (`:1273`) | `tests/test_planet_meter.gd` | rc,-,sum,- | 0, 7 s; `planet-meter: 23 checks 0 failures` | fails | `^planet-meter: [1-9][0-9]* checks 0 failures$$` | 600 | `planet-meter: 23 checks 0 failures`; rc 0, 3 s | no |
| 35 | `ship-attitude-test` (`:1297`) | `tests/test_ship_attitude.gd` | rc,se,sum,- | 0, 3 s; `ship-attitude: 0 failures` | fails | `^ship-attitude: [1-9][0-9]* passed, 0 failures$$` | 600 | `ship-attitude: 6 passed, 0 failures`; rc 0, 0 s | **yes** |
| 36 | `benchmark-upload-test` (`:1301`) | `tests/test_benchmark_upload.gd` | rc,se,sum,- | 0, 5 s; `benchmark-upload: 0 failures` | fails | `^benchmark-upload: [1-9][0-9]* passed, 0 failures$$` | 600 | `benchmark-upload: 12 passed, 0 failures`; rc 0, 2 s | **yes** |
| 37 | `shadow-contacts-test` (`:1305`) | `tests/test_shadow_contacts.gd` | rc,se,sum,- | 0, 3 s; `shadow-contacts: 0 failures` | fails | `^shadow-contacts: [1-9][0-9]* passed, 0 failures$$` | 600 | `shadow-contacts: 10 passed, 0 failures`; rc 0, 1 s | **yes** |
| 38 | `tour-attitude-test` (`:1309`) | `tests/test_tour_attitude.gd` | rc,se,sum,- | 0, 11 s; `tour-attitude: 0 failures` | fails | `^tour-attitude: [1-9][0-9]* passed, 0 failures$$` | 600 | `tour-attitude: 18 passed, 0 failures`; rc 0, 8 s | **yes** |
| 39 | `bridge-floor-test` (`:1313`) | `tests/test_bridge_floor.gd` | rc,se,sum,- | 0, 4 s; `bridge-floor: 14 passed, 0 failures` | fails | `^bridge-floor: [1-9][0-9]* passed, 0 failures$$` | 600 | `bridge-floor: 14 passed, 0 failures`; rc 0, 1 s | no |
| 40 | `sim-bootstrap-test` (`:1321`) | `tests/test_sim_bootstrap.gd` | rc,-,sum,- | 0, 12 s; `sim-bootstrap: 10 checks 0 failures` | fails | `^sim-bootstrap: [1-9][0-9]* checks 0 failures$$` | 600 | `sim-bootstrap: 10 checks 0 failures`; rc 0, 8 s | no |
| 41 | `tour-pacing-test` (`:1326`) | `tests/test_tour_pacing.gd` | rc,-,sum,- | 0, 4 s; `tour-pacing: 0 failures` | fails | `^tour-pacing: [1-9][0-9]* passed, 0 failures$$` | 600 | `tour-pacing: 15 passed, 0 failures`; rc 0, 0 s | **yes** |
| 42 | `tour-pacing-test` (`:1327`) | `tests/test_destination_pin.gd` | rc,se,sum,- | 0, 4 s; `destination-pin: 0 failures` | fails | `^destination-pin: [1-9][0-9]* passed, 0 failures$$` | 600 | `destination-pin: 23 passed, 0 failures`; rc 0, 1 s | **yes** |
| 43 | `tour-pacing-test` (`:1328`) | `tests/test_cruise_interlude.gd` | rc,se,sum,- | 0, 4 s; `cruise-interlude: 0 failures` | fails | `^cruise-interlude: [1-9][0-9]* passed, 0 failures$$` | 600 | `cruise-interlude: 36 passed, 0 failures`; rc 0, 1 s | **yes** |
| 44 | `ship-ui-test` (`:1334`) | `tests/test_ship_ui.gd` | rc,se,sum,- | 0, 93 s; `ship-ui: 288 passed, 0 failures` | fails | `^ship-ui: [1-9][0-9]* passed, 0 failures$$` | 600 | `ship-ui: 288 passed, 0 failures`; rc 0, 92 s | no |
| 45 | `ship-console-test` (`:1338`) | `tests/test_ship_consoles.gd` | rc,se,sum,- | **2**, 114 s, `ship-consoles: 133 passed, 1 failures` (no `build/ship-baseline`: `FAIL AC4 fallback: the pinned baseline is fetched (make ship-baseline)`); after `make ship-baseline`: 0, 111 s, `135 passed, 0 failures` | fails | `^ship-consoles: [1-9][0-9]* passed, 0 failures$$` | 600 | `ship-consoles: 135 passed, 0 failures`; rc 0, 109 s | no |
| 46 | `frame-check-test` (`:1342`) | `tests/test_frame_check.gd` | rc,se,sum,- | 0, 9 s; `frame-check: 0 failures` | fails | `^frame-check: [1-9][0-9]* passed, 0 failures$$` | 600 | `frame-check: 6 passed, 0 failures`; rc 0, 6 s | **yes** |
| 47 | `no-twitch-test` (`:1344`) | `tests/test_no_twitch.gd` | rc,se,sum,- | 0, 243 s; `no-twitch: 41 passed, 0 failures` | fails | `^no-twitch: [1-9][0-9]* passed, 0 failures$$` | 1800 | `no-twitch: 41 passed, 0 failures`; rc 0, 237 s | no |
| 48 | `playthrough` (`:1351`) | `tests/m4_playthrough_ship.gd` | rc,se,sum,- | 0, 120 s; `playthrough: 122861 passed, 0 failures` | fails | `^playthrough: [1-9][0-9]* passed, 0 failures$$` | 1200 | `playthrough: 122861 passed, 0 failures`; rc 0, 122 s | no |
| 49 | `news-lint` (`:1405`) | `tools/news_lint.gd` | rc,-,sum,- | 0, 1 s; `news-lint: ok` | fails | `^news-lint: ok \([1-9][0-9]* tiers, [1-9][0-9]* templates\)$$` | 600 | `news-lint: ok (5 tiers, 20 templates)`; rc 0, 0 s | **yes** |
| 50 | `news-lint` (`:1407`) | `tools/news_lint.gd` | rc,-,-,- | 0, 1 s; `news-lint: FAILED, 1 problems` | fails | `^news-lint: tier 0 template 1: a numeral outside a slot$$` (WANT_RC **1**) | 600 | `news-lint: tier 0 template 1: a numeral outside a slot`; rc 1, 1 s | **yes** |
| 51 | `news-test` (`:1413`) | `tests/test_news.gd` | rc,se,sum,- | 0, 14 s; `news: 95 passed, 0 failures` | fails | `^news: [1-9][0-9]* passed, 0 failures$$` | 600 | `news: 95 passed, 0 failures`; rc 0, 14 s | no |
| 52 | `codex-test` (`:1418`) | `tests/test_codex.gd` | rc,se,sum,- | 0, 10 s; `codex: 53 passed, 0 failures` | fails | `^codex: [1-9][0-9]* passed, 0 failures$$` | 600 | `codex: 53 passed, 0 failures`; rc 0, 9 s | no |
| 53 | `camera-test` (`:1426`) | `tests/test_camera_director.gd` | rc,se,sum,- | 0, 103 s; `camera-director: 187 passed, 0 failures` | fails | `^camera-director: [1-9][0-9]* passed, 0 failures$$` | 600 | `camera-director: 187 passed, 0 failures`; rc 0, 98 s | no |
| 54 | `camera-forward-test` (`:1438`) | `tests/test_camera_forward.gd` | rc,se,sum,- | 0, 31 s; `camera-forward: 35 passed, 0 failures` | fails | `^camera-forward: [1-9][0-9]* passed, 0 failures$$` | 600 | `camera-forward: 35 passed, 0 failures`; rc 0, 25 s | no |
| 55 | `guided-finale-test` (`:1443`) | `tests/test_guided_finale.gd` | rc,se,sum,- | 0, 68 s; `guided-finale: 21 passed, 0 failures` | fails | `^guided-finale: [1-9][0-9]* passed, 0 failures$$` | 600 | `guided-finale: 21 passed, 0 failures`; rc 0, 62 s | no |
| 56 | `free-nav-recovery-test` (`:1466`) | `tests/test_free_nav_recovery.gd` | rc,se,sum,- | 0, 65 s; `free-nav-recovery: 28 passed, 0 failures` | fails | `^free-nav-recovery: [1-9][0-9]* passed, 0 failures$$` | 600 | `free-nav-recovery: 28 passed, 0 failures`; rc 0, 53 s | no |


**Counts:** 56 rows in 48 targets and 57 gate lines (row 16 is 2). 52 lines are positive and 5 are negative (rows 5, 13, 16a, 16b and 50). Every line ran green (V9). 32 of the 56 rows need no script edit; row 6 is among them, because its summary already carries a number. 24 rows, in 19 scripts, get the D3 edit.

**The `ship-console-test` rule line** (`Makefile:1337`) becomes `ship-console-test: import ship-baseline ## …` (D5). Every other non-recipe line is unchanged: the `##` help, `.PHONY`, and the `test:` and `ship-demo-ci:` joins. The 57 recipe lines, as measured, are in `/tmp/iter72_designer/mig_lines.txt` and in `b4.diff`. Two representative lines, numbered on the applied tree (tabs shown as four spaces):

```make
Makefile:1095:    @$(SCRIPT_GATE) ship-demo-test $(SCRATCH)/ship-demo-test.log 600 '^ship-demo: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --script tests/test_ship_demo.gd
Makefile:1140:    @$(SCRIPT_GATE) ship-demo-geometry-wrong-tier $(SCRATCH)/ship-demo-wrong-tier.log 600 '^  FAIL actual exported tier height 3$$' 1 -- $(GODOT) --headless --path . --script tools/validate_ship_demo.gd -- assets/ship_demo/manifest.json wrong-tier
```

### D3. The counted summaries (19 scripts)

Three edit patterns, all measured (V9, V10). None changes what a check asserts.

1. **A `check()` that only counted failures** gains `var passes:=0` (or `passes := 0` in the spaced files). Its `if not ok:failures+=1` becomes `passes+=int(ok);failures+=int(not ok)`, which is the idiom `tests/test_bridge_floor.gd:6` already uses. Every one of these files increments its failure counter in exactly one place, inside `check()` (V10), so `passes + failures` is the number of checks run. The summary becomes `<name>: %d passed, %d failures` (or `<name>: OK|FAIL (%d passed, %d failures)` where the script printed `OK`). This applies to 15 files (V20): 12 that already printed a summary, and 3 that printed none.
   - `tools/validate_ship_demo.gd`, `tools/validate_ship_commons.gd`;
   - `tests/test_ship_commons_assets.gd`, `test_ring_protocol.gd`, `test_ship_attitude.gd`, `test_benchmark_upload.gd`, `test_shadow_contacts.gd`, `test_tour_attitude.gd`, `test_tour_pacing.gd`, `test_destination_pin.gd`, `test_cruise_interlude.gd`, `test_frame_check.gd`;
   - `test_runtime_fingerprint.gd`, `test_live_journey.gd`, `test_ship_demo_live.gd`. These three had no summary and now print `runtime-fingerprint:`, `live-journey:` and `ship-demo-live: %d passed, %d failures` just before their existing `quit(1 if failures else 0)`.

   This replaces the old pins on one `ok <label>` line. Read from source (V10), every check in the three scripts runs on every pass, with two exceptions. `test_live_journey.gd`'s `new target changes journey plan` is guarded by `prior_distance>=0.`, which is true on the loop's second target every time. Its startup check runs only on a failure path that exits 1. So a fixed count of checks reaches the summary, and the counted line binds at least as much as the pinned label did.
2. **Inline counting** in `tests/test_ship_demo_assets.gd` (it has no `check()`): `checks += 1` beside each of its three existing `failures += 1` sites, and `ship-demo-assets: %s (%d passed, %d failures)` with `checks - failures`. The measured 13 equals 7 deck heights + 1 lift route + 5 asset files (`jq '.assets|length' assets/ship_demo/manifest.json` = 5, V10).
3. **A single verdict counted by its conjuncts**, in `tests/test_ship_demo_benchmark.gd` and `tests/test_ship_demo_launch.gd`. The `a and b and c` verdict becomes `var conds: Array=[a,b,c]`, `passed=conds.count(true)` and `ok=passed==conds.size()`, and the summary prints `OK (3 passed, 0 failures)` and `OK (4 passed, 0 failures)`.
   - `launch` keeps the guard: its second conjunct stays `pid>0 and not OS.is_process_running(pid)`.
   - One difference on failure paths only: the conjuncts no longer short-circuit. So a missing `result` key now raises a `SCRIPT ERROR`, which the helper fails, instead of a plain `FAIL`.

**`tools/news_lint.gd`**: the `ok` line becomes `news-lint: ok (%d tiers, %d templates)`. It counts `t.tiers` and the templates under them, which is exactly what `NewsCopy.lint` walks (`ui/news_copy.gd:116–126`). Measured: `ok (5 tiers, 20 templates)`, which equals `jq '(.tiers|length), ([.tiers[].templates|length]|add)' data/news/templates.json` = `5 20` (V10). The problem lines and the `FAILED, N problems` line are unchanged.

**Consumers of the changed lines** (V15): `git grep` over every tracked file at HEAD, all types (`.py` included), for every old and new summary prefix, finds 49 lines:
- **42 in code or config:** the 20 print lines in the 16 scripts that had a summary, the 16 `Makefile` predicates this change replaces, `demos/frame_check.gd:217` (the in-game frame check's own `frame-check: <status>` print, which `tests/test_frame_check.gd` does not read), and five recorded validation logs under `art/` (`art/ship-commons-v1/{asset,geometry}-checks.txt`, `negative-control.txt`, `art/ship-demo-v1/*/validation/*.log`). Those logs are frozen evidence of past runs and no tool reads them.
- 6 in `.ailang/` records and 1 Markdown doc.
- `.py`: 0.

No `.gd` runs a B4 script through `OS.execute` (the `git grep` of every B4 script path in `.gd`/`.sh`/`.yml`/`.py` finds only comments and `tests/test_playthrough.sh:11`).

### D4. Negative controls bound to their own failure reason

Today each negative passes on rc 1 and a generic `<tool>: FAIL` line. A run that fails for the wrong reason passes too. Each negative is now its own gate with WANT_RC 1, and its summary is the reason line the planted defect produces (measured at base and migrated, V9):

| Line | NAME | The defect planted | SUMMARY_ERE |
|---|---|---|---|
| `:1109` | `ship-commons-assets-negative` | `bad-envelope` moves the scene by +100 m in x (`tools/validate_ship_commons.gd:15`) | `^  FAIL actual new vertices inside95m envelope$$` |
| `:1127` | `ship-demo-assets-negative` | `bad_height.json` sets tier 1 to 56 m (`deck_heights_ship_m` `[82,56,…]`) | `^  FAIL tier height 1$$` |
| `:1141` | `ship-demo-geometry-wrong-tier` | `Deck 03 top` +1 m (`_mutate`) | `^  FAIL actual exported tier height 3$$` |
| `:1141` | `ship-demo-geometry-wrong-tip` | `spire_needle` +1 m | `^  FAIL actual bridge needle98m$$` |
| `:1407` | `news-lint-stray-digit` | `tests/fixtures/news/stray_digit.json` | `^news-lint: tier 0 template 1: a numeral outside a slot$$` |

The `for mutation in wrong-tier wrong-tip` loop becomes two lines, so the inventory goes from 238 to **239** `--script` invocations (V11). Negative controls are exempt from the zero probe (`tools/script_gate.sh:42`, `[ "$want" -eq 0 ]`).

### D5. `ship-console-test` fetches its baseline

`Makefile:1337` becomes `ship-console-test: import ship-baseline ## …`, and `SG_PREREQS` gains `ship-console-test:ship-baseline`.
- `tests/test_ship_consoles.gd:171–173` checks `res://build/ship-baseline/manifest.json` and fails `AC4 fallback` without it.
- `ship-baseline` is a 0.8 s public-bucket fetch with a sha256 check (`tools/ship_baseline.sh fetch`, V5), and it is already in `make test`'s closure through `deck-layout-eval-test`, so `make test` fetches nothing new. `ship-console-test` is not in `ci-fast` (V17).
- **The fetch is bounded (revision 1; gpt6-1-sol's objection).**
  - **Before.** `tools/ship_baseline.sh:28` ran `curl -fsS --retry 3 -o "$f.part" …`, with no `--connect-timeout`, no `--max-time` and no `--retry-max-time`. The script has no other timeout: `set -eu` at `:12`, the loop at `:25–31`. Against a stalled server the fetch was still waiting when a 150 s ceiling killed it (V22).
  - **After.** That one line becomes `curl -fsS --connect-timeout 10 --max-time 60 --retry 2 --retry-max-time 120 …`, with a two-line comment.
    - Each attempt is at most 60 s, with connect inside it.
    - There are at most 3 attempts, with curl's 1 s and 2 s backoff. `--retry-max-time 120` can only stop retries earlier.
    - So one file gives up in **≤ 183 s**, and the script exits 1 on the first file that fails (`:28`).
  - **Prerequisite bound.** A whole fetch is at most 3 files × 183 s = **549 s**, worst case. Measured: 121 s and rc 1 against a stalled server, 27 s and rc 1 against a connect blackhole (V22).
  - **Gate bound, separately.** `$(SCRIPT_GATE)`'s 600 s deadline covers only the Godot test, and it starts only after `import` and `ship-baseline` have succeeded. Make runs no recipe of a target whose prerequisite failed. Measured on a stalled server: `make ship-console-test` stopped with `make: *** [ship-baseline] Error 1`, rc 2, in 125 s, with no `script-gate:` line, and `.godot/tmp/ship-consoles.log` kept its old mtime (V22). So `ship-console-test` worst case = `import` + ≤ 549 s + ≤ 600 s.
  - **A real fetch is unchanged.** rc 0 in 1 s, the three files byte-identical to the earlier fetch (V22), so 60 s per attempt leaves room on a 9.1 MB `ship.glb` down to about 150 KB/s.
  - **Scope.** The file is in `tools/`. No open PR touches it (V22), it has had one commit (`c61f8599`), and its callers are `mk/deck-layout.mk:7` (not edited) and `tools/deck_blockout.sh:15`, both of which gain the same bound.
- **Measured** with `build/ship-baseline` moved away: `make ship-console-test` printed `ship-baseline: build/ship-baseline matches art/deck-layout-v2/baseline.sha256` and then `script-gate: ship-console-test ok: ship-consoles: 135 passed, 0 failures`, rc 0, in 117 s (V12).
- The fixture `tests/fixtures/script_gate/prereq_negative.mk.txt` gains `ship-console-test: import ship-baseline`. Without it, the negative control would print a third line, `ship-console-test has no rule`, and refuse itself.
- **The mutant** (`ship-console-test: import`) gives rc 2 and `script-gate-prereqs: ship-console-test lost its prerequisite ship-baseline (ship-console-test: import)` (V13).

### D6. A pin on `SG_PREREQS` (the iteration-71 judge survivor)

`mk/script-gates.mk` gains `SG_PREREQS_PAIRS := 4`, with a comment that cites the survivor. `script-gate-lint` gains one line before the real prerequisite check:

```make
    @test "$(words $(SG_PREREQS))" = "$(SG_PREREQS_PAIRS)" && test "$(words $(sort $(SG_PREREQS)))" = "$(SG_PREREQS_PAIRS)" \
      || { echo "script-gate-lint: SG_PREREQS holds $(words $(SG_PREREQS)) pairs ($(words $(sort $(SG_PREREQS))) distinct) but SG_PREREQS_PAIRS is $(SG_PREREQS_PAIRS): the pin moves with the pairs, and only up"; exit 1; }
```

`$(sort)` removes duplicates, so padding the list with a repeated pair cannot keep the count. This is the baseline pin's discipline (`SCRIPT_GATE_BASELINE_ROWS`). Removing a pair now takes two visible edits, and the pin's comment says it only rises.

Measured on the B4a tree (V13). Every mutant gives **rc 2** and the line above:
- **A**, `ship-console-test:ship-baseline` dropped: `holds 3 pairs (3 distinct) but SG_PREREQS_PAIRS is 4`;
- **B**, `planets-test:planet-assets` dropped (the judge's mutant shape): `3 pairs (3 distinct)`;
- **C**, one pair replaced by a duplicate of another: `holds 4 pairs (3 distinct)`;
- **D** and **E**, `SG_PREREQS_PAIRS=5` and `=3`: refused.

**Control:** the base `mk/script-gates.mk` (`git show HEAD:`) with a pair dropped gives **rc 0** and `script-gate-prereqs: ok (2 pairs hold …)`. That reproduces the survivor.

**Residual:** a swap of one real pair for a *different* real pair keeps the count and passes. Closing that needs a derived list (B3 OQ5), which is still a later batch's choice. Recorded as OQ5.

### D7. Baseline and pin

Delete every `tools/script-gate-baseline.txt` row whose target is one of the 48 B4a targets ([Appendix A1](#a1-the-48-b4a-targets-ac5-ac7-ac12)). That is 56 rows; every rule for those targets is in the `Makefile` (V11). Then set `SCRIPT_GATE_BASELINE_ROWS := 119`, with the comment `…, 119 after B4a (56 rows in the Makefile at line 1080 and below it).` The rows go with:

```sh
awk -F'\t' 'FNR==NR{d[$1]=1;next} /^#/ || !($1 in d)' b4a-targets.txt tools/script-gate-baseline.txt > b.new && mv b.new tools/script-gate-baseline.txt
grep -vc '^#' tools/script-gate-baseline.txt   # 119 (175 - 56)
```

`make script-gate-lint` then reads `script-gate-lint: ok (239 --script invocations: 120 through $(SCRIPT_GATE), 119 on the baseline; 22 includes, all in mk/*.mk; 23 makefiles scanned)`, and `script-gate-prereqs: ok (4 pairs hold in Makefile: …)` (V11). In the `Makefile` from line 1080 on, 57 lines are gated and 30 ungated (the B4b rows).

### D8. Orphan targets (iteration-71 retro 3)

An *orphan* is a `--script` target that no aggregate reaches. The aggregates are `test` (the nightly `rig/full`), `ci-fast` (GitHub) and `golden` (nightly).

**Instrument** (V17): [Appendix A5](#a5-the-aggregate-closure-d8-v17), extracted with `x 'sh b4-closure'` (the revision-0 scratch copy was `/tmp/iter72_designer/closure.sh`, the same file). It reads make's own database (`make -pq`) and takes the transitive closure from each root over prerequisites and over every word on a recipe line that calls `$(MAKE)`. That second rule is what puts `playthrough` in `test`, through `playthrough-adversarial`. On the B4a tree the closures hold 366, 24 and 25 targets.

**Gated targets that no aggregate runs (14 of 106 gated targets):**

| Target | File | Kind | Note |
|---|---|---|---|
| `alpha-centauri-golden` | `mk/m5.mk:143` | GPU golden | red on every run on main until B3a fixed its regex; still in no aggregate (not even `golden`) |
| `commons-grown-check`, `commons-backdrop-check`, `commons-pilot-check` | `mk/levels.mk:26,34,43` | **headless validators** | could rot unseen |
| `level-eval` | `mk/levels.mk:61` | headless authoring metric | run by hand and by `tools/levels_backlog.sh` |
| `frame-check-test` | `Makefile:1342` | **headless test (new in B4a)** | green, 6 checks, 9 s |
| `commons-grown-capture`, `commons-backdrop-capture`, `commons-pilot-capture`, `commons-grown-motion`, `level-capture`, `ai-style-frame` | `mk/levels.mk`, `mk/ai.mk:560` | GPU captures | review renders, manual by design |
| `planet-cpu-bench`, `exposure-cpu-bench` | `mk/planet-presentation.mk:12,33` | benches | manual by design |

**Ungated B4b targets that no aggregate runs:** 28 of B4b's 29 targets. The exception is `true-light-golden`, which `golden` runs. They include `sim-pipeline-test`, red on every run at base (Problem 4).

Across the whole inventory, 73 of 105 ungated targets reach no aggregate (V17). They are outside B4's scope and are listed here only as the size of the question.

**No orphan is fixed here.** Putting `frame-check-test` or the three Commons validators into `test` changes what the nightly runs. That is a scope decision for the rows that own them, and it is not suite hygiene. OQ2 proposes a guard instead.

### D9. B4b: the 30 rows, recorded but not designed here

**B4b is out of this sprint** (as B2b and B3b). Each row lists what was measured and its blocker. It proposes no invocation, regex or edit. Every base run is V5, with `Device Utilization %` sampled before and after (the `gpu` column). A red under that load is **UNATTRIBUTED** until it is re-run on a quiet GPU.

| Target (`Makefile:line`) | Today | Base, measured (rc, s, gpu %) | Blocker |
|---|---|---|---|
| `ship-demo-capture` (`:1098`) **window** | -,-,-,- | 0, 10, 16/99; `ship-demo-capture: OK` | GPU window; uncounted `OK` |
| `ship-demo-live-capture` (`:1118`) **window** | -,-,-,- | **2**, 10, 100/99; `ERROR: native commit click did not open dialog` | GPU window; red at base, UNATTRIBUTED |
| `ship-commons-capture` (`:1122`) **window** | -,-,-,- | 0, 7, 100/100; `OK` | GPU window; uncounted |
| `ship-demo-movie` (`:1132`) **window** | -,-,-,- | **2**, 12, 100/99; a silent `quit(1)` in the lift sequence (`tools/ship_demo_movie.gd:14–23`) | GPU window; red at base, UNATTRIBUTED; also runs `ffmpeg` |
| `ship-demo-optics` (`:1135`) **window** | -,-,-,- | 0, 11, 100/100; `81 cases, worst 0.1699 px, …, failures 0` | GPU window (a GPU-vs-CPU optics check) |
| `ship-demo-bench` (`:1137`) **window** | -,-,-,- | 0, 42, 100/100; `OK (actual hardware …)` | bench: needs a quiet GPU |
| `ship-demo-sky-states` (`:1159`) | -,-,-,- | not run; parse drill **passes** | authoring: writes the **tracked** `assets/ship_demo/sky_review.json` (`tools/ship_demo_sky_states.gd:25`) |
| `ship-demo-journey-capture` (`:1161`) **window** | -,-,-,- | 0, 8, 100/97; `OK` | GPU window; uncounted |
| `ship-star-identification-capture` (`:1168`) **window** | -,-,-,- | **2**, 62, 94/26; `273 cases, worst 0.5659 px, 2 failures` | GPU window; red at base, UNATTRIBUTED |
| `ship-star-identification-bench` (`:1170`) **window** | -,-,-,- | 0, 95, 67/6; `OK · <abs path>` | bench; absolute path in summary |
| `title-capture` (`:1196`) **window** | -,-,-,- | 0, 5, 52/48; no summary line | GPU window; prints no summary |
| `loading-jump-capture` (`:1205`) **window** | -,-,-,- | 0, 5, 0/73; no summary of its own | GPU window; prints no summary |
| `loading-profile` (`:1208`, `:1209`) **window** | -,-,-,- ×2 | 0, 60, 18/83; `loading-profile: route … 7862.0 ms …` | profile (timing): needs a quiet GPU; piped through `grep` |
| `ship-lighting-capture` (`:1224`) **window** | rc,-,sum,- | 0, 14, 0/52; `OK` | GPU window; uncounted |
| `ship-lighting-bench` (`:1227`) **window** | -,-,-,- | 0, 35, 100/0; `OK` | bench |
| `ship-star-light-capture` (`:1235`) **window** | rc,se,sum,- | **142**: killed at the 600 s ceiling, 97/100 | GPU window; timeout under load, UNATTRIBUTED |
| `ship-star-light-bench` (`:1237`) **window** | rc,-,sum,- | 0, 51, 100/69; `OK` | bench |
| `true-light-golden` (`:1243`) **window** | rc,se,sum,- | 0, 6, 77/28; `16 passed, 0 failures` | GPU golden; in `golden`; pins 16 `G-TL-` lines (a count question like B3b's) |
| `trappist1-capture` (`:1256`) **window** | rc,se,-,- | 0, 12, 0/45; `9 frames, 0 failures` | GPU window |
| `solar-departure-capture` (`:1276`) **window** | rc,se,sum,- | **142**: killed at 600 s, 0/40 | GPU window; timeout, UNATTRIBUTED |
| `solar-departure-bench` (`:1279`) **window** | rc,se,sum,- | **2**, 92, 0/89; `solar-departure-bench: FAIL commit` | bench; red at base, UNATTRIBUTED |
| `sim-pipeline-test` (`:1340`) | rc,se,sum,- | **2** three times, 49–54 s; `sim-pipeline: 3 failures` | **red on every run** (OQ1); no aggregate runs it |
| `ship-ui-window-check` (`:1360`) **window** | rc,se,sum,- | 0, 22, 97/69; `OK` | GPU window; uncounted |
| `ship-ui-capture` (`:1364`) **window** | rc,se,sum,- | 0, 192, 0/100; `OK (52 frames)` | GPU window |
| `camera-forward-targets` (`:1447`) | rc,se,-,- | not run | authoring: rewrites the **tracked** `tests/fixtures/camera_forward/targets.json` (`tools/camera_forward_targets.gd:13,64`) |
| `camera-forward-review` (`:1450`) **window** | rc,se,sum,- | 0, 40, 100/100; `8 frames, 0 failures` | GPU window |
| `camera-walk-capture` (`:1453`) **window** | rc,se,sum,- | 0, 46, 100/65; `48 frames, 0 failures` | GPU window |
| `bh-ahead-capture` (`:1457`) **window** | rc,se,-,- | 0, 50, 12/87; `7 frames, 0 failures (now)` | GPU window |
| `camera-views-capture` (`:1460`) **window** | rc,se,sum,- | **2**, 222, 53/99; `52 frames, 18 failures` | GPU window; red at base, UNATTRIBUTED |

That is 30 rows in 29 targets: 27 windowed rows, 2 authoring rows and `sim-pipeline-test`. Each windowed row fails the parse drill at base, because a windowed Godot exits 1 on a parse error (Problem 8, V7). B4b's sprint inherits B3's rule that a summary holding an absolute path binds the path literally (`ship-star-identification-bench`).

## Acceptance criteria

Run them from the implementation root. First run `make runtime` if `runtime/bin/ailang` is missing (V3), then `export PATH="$PWD/runtime/bin:$PATH"` (check that `ailang --version` says v0.56.1), then `make deps import starmap-assets planet-assets sky-assets`.
- The expected values were measured at `05e64cd1` plus this change (V9–V19; revision 1: V20–V24). Counts may only grow. If the base has moved, the relations must still hold: the pin equals the pre-migration rows minus 56, and the lint is ok.
- Commands write only inside the clone (`.godot/tmp/`, the ignored `renders/`, `build/ship-baseline/`, `data/raw/`, `assets/planets/`) and read public buckets. Nothing uploads.
- Afterwards, delete the 5 ignored `.translation` files that `make import` leaves (row 7u).
- AC5 runs about 41 min of Godot (2,435 s summed in V9). Run it in the background with an rc file and poll that file in a bounded loop.
- AC14 starts a throwaway local server on `127.0.0.1:18731`, which exits by itself after 900 s, and points only that one `make` at it through `SHIP_BASE_URL`, an override the script already has (`tools/ship_baseline.sh:16`).

**Revision 1: the ACs need nothing outside the clone.** AC5 and AC7–AC9 read their inputs from this doc's [Appendix](#appendix-the-ac-inputs-and-harness-revision-1), extracted with this one command (run it from the clone root first):

````sh
x() { awk -v t="$1" '$0 == "```" t {f=1; next} f && $0 == "```" {exit} f' design_docs/planned/r1/m4-7x-b4-script-gates.md; }
mkdir -p .godot/tmp/b4
x 'text b4a-targets' > .godot/tmp/b4/targets.txt      # A1: 48 lines
x 'sh b4-drill'      > .godot/tmp/b4/drill.sh         # A2: 41 lines
x 'text b4-rt-pairs' > .godot/tmp/b4/rt-pairs.txt     # A3: 8 lines
x 'text b4-zero-pairs' > .godot/tmp/b4/zero-pairs.txt # A4: 22 lines
make --no-print-directory script-gate-inventory > .godot/tmp/b4/inv.tsv
````

| # | Criterion and command | Expected output |
|---|---|---|
| AC1 | The ratchet, the prerequisite guard and the new pin: `make script-gate-lint; echo rc=$?` | `script-gate-lint: ok (239 --script invocations: 120 through $(SCRIPT_GATE), 119 on the baseline; 22 includes, all in mk/*.mk; 23 makefiles scanned)`; `script-gate-prereqs: ok (4 pairs hold in Makefile: constellation-test:starmap-assets planets-test:planet-assets planet-textures-check:planet-assets ship-console-test:ship-baseline)`; `rc=0` (V11) |
| AC2 | The baseline pin bites at N+1: `make script-gate-lint SCRIPT_GATE_BASELINE_ROWS=120 2>&1 \| grep 'the baseline has'` | `script-gate-lint: the baseline has 119 rows but SCRIPT_GATE_BASELINE_ROWS is 120: the pin moves with the rows, and only down` (V11) |
| AC3 | **The judge survivor is killed:** `cp mk/script-gates.mk .godot/tmp/b4-sg.keep; perl -pi -e 's/ planets-test:planet-assets / /' mk/script-gates.mk; make script-gate-lint > .godot/tmp/b4-ac3.out 2>&1; echo rc=$?; grep '^script-gate-lint: SG_' .godot/tmp/b4-ac3.out; cp .godot/tmp/b4-sg.keep mk/script-gates.mk; make script-gate-lint SG_PREREQS_PAIRS=5 2>&1 \| grep -c '^script-gate-lint: SG_PREREQS holds 4 pairs (4 distinct) but SG_PREREQS_PAIRS is 5'` | `rc=2`, `script-gate-lint: SG_PREREQS holds 3 pairs (3 distinct) but SG_PREREQS_PAIRS is 4: the pin moves with the pairs, and only up`, then `1` (V13) |
| AC4 | **The new prerequisite is guarded:** `cp Makefile .godot/tmp/b4-mf.keep; perl -pi -e 's/^ship-console-test: import ship-baseline ##/ship-console-test: import ##/' Makefile; make script-gate-lint > .godot/tmp/b4-ac4.out 2>&1; echo rc=$?; grep '^script-gate-prereqs:' .godot/tmp/b4-ac4.out; cp .godot/tmp/b4-mf.keep Makefile` | `rc=2`, `script-gate-prereqs: ship-console-test lost its prerequisite ship-baseline (ship-console-test: import)` (V13) |
| AC5 | **Every B4a target green, with no API key** (background, about 41 min). The list check first: `T=.godot/tmp/b4; awk -F'\t' '{split($1,a,":"); if (a[1]=="Makefile" && a[2]+0>=1080 && $4=="gated") print $2}' $T/inv.tsv \| sort -u > $T/g.txt; sort -u $T/targets.txt \| diff - $T/g.txt && echo list-ok; make -n $(cat $T/targets.txt) playthrough-adversarial > /dev/null; echo n-rc=$?`. Then `env -u AI_LIVE -u GOOGLE_API_KEY -u OPENROUTER_API_KEY -u OPENAI_API_KEY make $(cat $T/targets.txt) playthrough-adversarial > $T/ac5.out 2>&1; echo $? > $T/ac5.rc`, and when `$T/ac5.rc` exists: `cat $T/ac5.rc; grep '^script-gate:' $T/ac5.out \| sort -u -t: -k2,2 \| wc -l; grep -c 'script-gate: [^ ]* FAIL' $T/ac5.out` | `list-ok`, `n-rc=0` (V21); then `0`; `57`; `0`. Each line is `ok` with D2's "After" summary, for example `ship-demo: 244 passed`, `validate-ship-demo: OK (24 passed, 0 failures)`, `live-journey: 17 passed`, the five negatives `ok:   FAIL …` / `ok: news-lint: tier 0 template 1: …` with `rc 1`, `news-lint: ok (5 tiers, 20 templates)`, and `solar-departure: 134 passed` under its 3,000 s deadline (V9) |
| AC6 | Helper self-test and drill unchanged: `make script-gate-selftest 2>&1 \| tail -1; make script-gate-drill 2>&1 \| tail -1` | `test-script-gate: ok (18 cases: 18 stub, 0 Godot)`, `test-script-gate: ok (24 cases: 18 stub, 6 Godot)` (V12) |
| AC7 | **Parse-error drill on all 57 migrated lines,** with A2: `T=.godot/tmp/b4; awk -F'\t' 'FNR==NR{d[$1]=1;next} {split($1,a,":"); if (a[1]=="Makefile" && ($2 in d)) print $1, $2, $3}' $T/targets.txt $T/inv.tsv > $T/rows.txt; wc -l < $T/rows.txt; sh $T/drill.sh ac7 parse $T/rows.txt; grep -h 'script-gate: .* FAIL' .godot/tmp/b4-drill/ac7/drill-*.out \| grep -c 'SCRIPT ERROR line(s)'` | `57`; `57 rc=2`; `57`. The 5 negatives also say `rc 0, want 1` (V21; at base the same harness gives `5 rc=0` among the 59 headless rows, V7) |
| AC8 | **Runtime-error drill, a skipped `check()`,** with A2 and A3: `T=.godot/tmp/b4; awk -F'\t' 'FNR==NR{k[$0]=1;next} {split($1,a,":"); if (a[1]=="Makefile" && (($2" "$3) in k)) print $1, $2, $3}' $T/rt-pairs.txt $T/inv.tsv > $T/rt-rows.txt; wc -l < $T/rt-rows.txt; sh $T/drill.sh ac8 rt $T/rt-rows.txt`. Optional base side: `git show origin/main:Makefile > $T/Makefile.base`, the rows of A3's base line numbers, `sh $T/drill.sh ac8-base rt <rows> $T/Makefile.base origin/main` | `8`; `8 rc=2` (V21). At base, `6 rc=0` and `2 rc=2`: `ship-demo-test` passes with `ship-demo: 0 passed, 0 failures`, and `flyby-optics-test` with `0 checks, 0 failures` (V21, which supersedes V8) |
| AC9 | **The new summaries reject zero,** with A4: `while IFS='\|' read -r row ere zero real; do mk=$(printf '%s' "$ere" \| sed 's/\$$/$$/'); printf '%s zeroed=%s real=%s makefile=%s\n' "$row" "$(printf '%s\n' "$zero" \| grep -cE -- "$ere")" "$(printf '%s\n' "$real" \| grep -cE -- "$ere")" "$(grep -cF -- "'$mk'" Makefile)"; done < .godot/tmp/b4/zero-pairs.txt` | 22 lines, each `zeroed=0 real=1` and `makefile=1`, except `1,12 … makefile=2` (rows 1 and 12 share their ERE) (V21) |
| AC10 | **`ship-console-test` fetches its baseline:** `mv build/ship-baseline .godot/tmp/b4-sb.aside 2>/dev/null; make ship-console-test 2>&1 \| grep -E '^ship-baseline:\|^script-gate:'; echo rc=$?` | `ship-baseline: build/ship-baseline matches art/deck-layout-v2/baseline.sha256`, `script-gate: ship-console-test ok: ship-consoles: 135 passed, 0 failures (…)`, `rc=0` (V12; about 2 min) |
| AC11 | Policy gates and hygiene: `make uid-guard python-guard audio-silent-guard lint-precision && git diff --check origin/main && shellcheck -s sh tools/ship_baseline.sh && echo gates-ok` | `uid-guard: ok (406 .uid files)`, `python-guard: ok (21 allowlisted, 0 awaiting AILANG port)`, `audio-silent-guard: ok (79 windowed godot invocations; 5 allowlisted to keep sound)`, `lint-precision: ok …`, `gates-ok` (V23). No new `.gd`, `.sh` or `.py` file |
| AC12 | Scope: `git diff --name-only origin/main \| grep -cvxE 'Makefile\|mk/script-gates\.mk\|tools/(script-gate-baseline\.txt\|validate_ship_demo\.gd\|validate_ship_commons\.gd\|news_lint\.gd\|ship_baseline\.sh)\|tests/test_(ship_commons_assets\|runtime_fingerprint\|live_journey\|ship_demo_live\|ship_demo_assets\|ship_demo_benchmark\|ship_demo_launch\|ring_protocol\|ship_attitude\|benchmark_upload\|shadow_contacts\|tour_attitude\|tour_pacing\|destination_pin\|cruise_interlude\|frame_check)\.gd\|tests/fixtures/script_gate/prereq_negative\.mk\.txt\|design_docs/planned/r1/m4-7x-b4-script-gates.*\.md\|\.ailang/state/sprints/sprint_R1-M4-JOURNEY\.json'; git diff -U0 origin/main -- Makefile \| grep '^@@' \| awk '{split($2,a,","); if (substr(a[1],2)+0 < 1080) n++} END{print n+0}'; git diff --name-only origin/main -- mk/sound.mk mk/m45.mk mk/deck-layout.mk mk/earth-link.mk tools/script_gate.sh tools/test_script_gate.sh tools/script_gate_lint.sh tools/script_gate_prereqs.sh \| wc -l; git diff --numstat origin/main -- tools/ship_baseline.sh` | `0`, `0` (no `Makefile` hunk starts before line 1080), `0`, `3	1	tools/ship_baseline.sh` (V24) |
| AC13 | The PR's GitHub fast tier (the first Linux, `dash` and GNU make 4 run of the pin line): `gh pr checks <PR>`; `gh run view <run> --log \| grep -cE 'script-gate-lint: ok \(239 --script invocations: 120 through\|script-gate-prereqs: ok \(4 pairs hold in Makefile\|test-script-gate: ok \(18 cases: 18 stub, 0 Godot\)'` | `success`; `3`. GNU make 4.4.1 (`gmake`) already gives AC1's two lines locally (V11) |
| AC14 | **The baseline fetch is bounded on a stalled server, and the test never starts (revision 1).** Start a server that accepts and never answers: `perl -MIO::Socket::INET -e '$s=IO::Socket::INET->new(LocalAddr=>"127.0.0.1",LocalPort=>18731,Listen=>16,ReuseAddr=>1) or die; alarm 900; push @k, $c while $c=$s->accept' &`. Then `mv build/ship-baseline .godot/tmp/b4-sb.aside 2>/dev/null; s=$(date +%s); SHIP_BASE_URL=http://127.0.0.1:18731 make ship-console-test > .godot/tmp/b4/ac14.out 2>&1; echo "rc=$? $(( $(date +%s)-s ))s"; grep -cE '^curl: \(28\)' .godot/tmp/b4/ac14.out; grep -E '^ship-baseline: FAIL\|^make: \*\*\*' .godot/tmp/b4/ac14.out; grep -c '^script-gate:' .godot/tmp/b4/ac14.out; make ship-baseline \| tail -1` | `rc=2` in about 125 s (≤ 549 s plus `import` by D5's bound); `2` (two 60 s attempts, then the 120 s retry window closes); `ship-baseline: FAIL fetch ship.glb (9da7…)` and `make: *** [ship-baseline] Error 1`; `0` (Godot's test never started); then `ship-baseline: build/ship-baseline matches art/deck-layout-v2/baseline.sha256` (V22) |

## Sub-milestones and estimates

One sprint and one PR, in this order. Each step is test-first against the AC that names it.
1. **D6 pin and D5 pair** (`mk/script-gates.mk` +9/−3, fixture +3/−1, `Makefile:1337`), plus the bounded curl line in `tools/ship_baseline.sh` (+3/−1; AC14): AC3 and AC4 first, because they need no Godot.
2. **D3 summaries** (19 scripts, +62/−35), then **the D2/D4 recipe lines** (`Makefile` +58/−68). Run each script's rows as soon as it is edited.
3. **D7 baseline and pin** (−56 rows, pin 119): AC1, AC2.
4. Drills and hygiene: AC5–AC12. Then AC13 on the PR.

For a mid-tier model that is about an hour of editing. The wall time is dominated by AC5 (about 41 min of Godot, mostly `solar-departure-test`, `free-nav-stop-test` and `no-twitch-test`). The edits are mechanical. `b4.diff` is the measured reference: it applies to `05e64cd1` (V19), and the executor may apply it and then verify.

## Conflict surface

**Files touched (24):**
- `Makefile` (line 1093 onward only), `mk/script-gates.mk`, `tools/script-gate-baseline.txt`;
- `tools/ship_baseline.sh` (revision 1: the curl line only, D5);
- `tools/validate_ship_demo.gd`, `tools/validate_ship_commons.gd`, `tools/news_lint.gd`;
- `tests/test_{ship_commons_assets,runtime_fingerprint,live_journey,ship_demo_live,ship_demo_assets,ship_demo_benchmark,ship_demo_launch,ring_protocol,ship_attitude,benchmark_upload,shadow_contacts,tour_attitude,tour_pacing,destination_pin,cruise_interlude,frame_check}.gd`;
- `tests/fixtures/script_gate/prereq_negative.mk.txt`;
- plus this doc and the sprint JSON.

**Open PRs** (V16; `gh pr diff --name-only`, then the `Makefile` hunk starts of each PR's head against its merge base):

| PR | Files | Of ours | `Makefile` hunks (old start) |
|---|---:|---|---|
| #384 | 11 | 0 | none |
| #380 | 31 | `Makefile` | 10, 18, 225, 245 |
| #379 | 99 | `Makefile` | 485 |
| #373 | 57 | `Makefile` | 10, 18, 225 |

`tools/ship_baseline.sh` is in none of the four PRs (`gh pr diff <n> --name-only`, V22). Every attended hunk ends before line 500. Every B4a hunk starts at line 1093 or later (AC12), so git merges them without a conflict. B4a moves no line above 1093. No protected-file row uses a B4 script, and `mk/deck-layout.mk` is only *referenced* (the `ship-baseline` target), never edited.

**Not touched:** the `Makefile` below line 1080, `mk/sound.mk`, `mk/m45.mk`, `mk/deck-layout.mk`, `mk/earth-link.mk`, the four 7x helper scripts, `tools/m4_ship_golden.gd`, every windowed row and both authoring rows.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| `solar-departure-test` runs long under load (490 s at base, 603 s through the gate). | Its own deadline is 3,000 s (D1). A timeout says `timeout after 3000 s (rc 142)`, and the deadline is one number on one line. |
| A quiet pass hides the log excerpt that `make test` used to print (`cat`, `tail -3`, `grep -E '^(FAIL\|…)'`). | The same deliberate change as B2 D1 and B3 D1. A failure prints every non-`ok` line and every reason, and the full log stays at LOG. |
| The single-verdict counts (`3 passed`, `4 passed`) are structural: the conjunct count is fixed in the source. | They still prove the verdict line was reached with every conjunct true, and the zero probe refuses `0 passed`. The alternative is a literal `^…: OK$$`, which the probe refuses outright ("carries no nonzero count"). |
| `ship-commons-arcade` keeps a literal `plaza=true … roof=true open_arch=true`. | It pins exactly what the script prints on a pass. The script exits 1 on any false flag or on `terrace<=100`, and the count is bound with `[1-9][0-9]*` (OQ3). |
| `SG_PREREQS_PAIRS` can be lowered together with the list. | That takes two visible edits in one file, as with the baseline pin. A same-count swap of real pairs survives (OQ5). |
| The `ship-console-test` prerequisite adds a network fetch. | It is a 0.8 s public-bucket read with a sha256 check, already in `make test`'s closure through `deck-layout-eval-test`. `ci-fast` does not reach `ship-console-test` (V17). Revision 1 bounds the fetch: ≤ 183 s per file and ≤ 549 s per fetch, and on failure make stops before the gate (D5, AC14, V22). |
| Concurrent load during the measurements. | The migrated run overlapped the tail of the windowed base run (16:30–16:49), and the 1-minute load reached 18.9. Every B4a gate was green anyway (V9). Times in D2's "After" column are upper bounds. |
| The new 60 s per-attempt limit could fail a real fetch on a very slow link. | `ship.glb` is 9.1 MB, so 60 s allows about 150 KB/s. The measured fetch took 1 s for all three files (V22). A failure is loud (`ship-baseline: FAIL fetch …`, rc 1) and never a silent pass. `SHIP_BASE_URL` still points the fetch at a mirror. |

## Open questions

None blocks the sprint.
- **OQ1. `sim-pipeline-test` is red on every run (B4b). Default: open a new charter row.** It was rc 2 in three runs (`same inputs in the same order (sent journal)`, `same world at the end`, `same crew at the end`). That is a behavioural divergence between pipelined and synchronous heartbeats, not a predicate defect. It needs its own diagnosis, and then a decision on whether `ship-demo-ci` should run it.
- **OQ2. Orphan targets. Default: record, do not fix.** D8 lists 14 gated orphans. Four are headless checks that can rot unseen (`commons-{grown,backdrop,pilot}-check`, `frame-check-test`); the iteration-71 precedent is `alpha-centauri-golden`. One option for a later row is a lint that every gated target is either reachable from `test`/`ci-fast`/`golden` or listed on an explicit `SG_MANUAL` allowlist with a reason. It would reuse D8's `make -pq` closure.
- **OQ3. `ship-commons-arcade`'s literal flags. Default: keep.** Rewriting the line as `N passed` would mean splitting a four-way conjunction, as D3 pattern 3 does. It was left as printed, because it already carries a bound number.
- **OQ4. The helper's reason text says "Godot exits 0 on a parse error".** That is measured true headless and false windowed (rc 1, V7). Default: leave the helper unchanged here (non-goal) and let B4b, the first windowed batch to need it, reword it.
- **OQ5. `SG_PREREQS` completeness (B3 OQ5, carried).** The count pin kills drop and pad mutants, but not a swap of one real pair for another. Deriving the list from what each gated script reads is still a later batch's lint.

## Deliverables

- The B4a change set: the 24 files above, saved as `/tmp/iter72_designer/b4.diff` (revision 1, sha256 `cdfaa8ffbf6ba33dcd2f536f1af4e11583aa6f005be388337e9fef43bc486f6c`; revision 0 was `9716f916…`). Apply it with `git apply`; `git apply --check` passes on `05e64cd1` (V24).
- The baseline down 56 rows, the pin at 119, and the new pin `SG_PREREQS_PAIRS := 4`.
- The AC inputs and harnesses are in this doc ([Appendix](#appendix-the-ac-inputs-and-harness-revision-1), A1–A5), not in the change set. The revision-0 scratch (`/tmp/iter72_designer/{run.sh,applymap.pl,makemap.txt}`) is evidence only, and no AC reads it.
- The sprint JSON progress and the evaluation, per the development cycle. The B4b rows (D9), OQ1 and OQ2 are handed to later rows.

## Estimated LOC per file

Measured with `git diff --numstat` on the applied revision-1 tree (V24):

| File | + | − |
|---|---:|---:|
| `Makefile` | 58 | 68 |
| `mk/script-gates.mk` | 9 | 3 |
| `tools/script-gate-baseline.txt` | 0 | 56 |
| `tests/fixtures/script_gate/prereq_negative.mk.txt` | 3 | 1 |
| `tools/validate_ship_demo.gd`, `tools/validate_ship_commons.gd` | 6 | 4 |
| `tools/news_lint.gd` | 4 | 1 |
| `tests/test_ship_demo_assets.gd` | 5 | 1 |
| `tests/test_ship_demo_benchmark.gd`, `tests/test_ship_demo_launch.gd` | 8 | 4 |
| `tests/test_runtime_fingerprint.gd` | 3 | 1 |
| the other 12 `tests/*.gd` (3/2 each) | 36 | 24 |
| `tools/ship_baseline.sh` (revision 1) | 3 | 1 |
| **Total (24 files)** | **135** | **164** |

## Verification log

All rows ran at `05e64cd1` on 2026-11-05, 15:28–17:25 CET, in `/Users/voightkampff/dev/sunholo-data/stapledons-godot-iter72`, on the Studio (Apple M4 Max).
- **Tools:** Godot `4.7.2.stable.official.ed1daf0bf`; AILANG v0.56.1 (`runtime/bin`); GNU make 3.81, and `gmake` 4.4.1 for V11.
- **Supervision:** every `make` run sat under a process-group supervisor, a copy of the perl in `tools/script_gate.sh` (`/tmp/iter72_designer/sup.pl`). Ceilings were 900 s per base headless target, 600 s per windowed target, 3,600 s per migrated target, and 180 s per drill line.
- **Environment:** every run had `AI_LIVE`, `GOOGLE_API_KEY`, `OPENROUTER_API_KEY`, `OPENAI_API_KEY`, `GEMINI_AGENTS_API_KEY`, `OLLAMA_API_KEY`, `ZAI_API_KEY` and `ANTHROPIC_API_KEY` unset (`run.sh`). Each target's results row logs `ioreg` `Device Utilization %` before/after and the 1-minute load.
- **Not run:** the two authoring targets (they write tracked files), and anything that uploads.

| # | Claim | Command | Observed |
|---|---|---|---|
| V1 | The lint at base | on the restored tree: `make script-gate-lint` | `script-gate-lint: ok (238 --script invocations: 63 through $(SCRIPT_GATE), 175 on the baseline; 22 includes, all in mk/*.mk; 23 makefiles scanned)`; `script-gate-prereqs: ok (3 pairs hold in Makefile: …)` |
| V2 | 86 B4 rows; the instrument | `SCRIPT_GATE_BASELINE_ROWS=175 sh tools/script_gate_lint.sh --inventory > inv_base.tsv`; `awk -F'\t' '{split($1,a,":"); if (a[1]=="Makefile" && $4=="ungated") { if (a[2]+0>=1080) hi++; else lo++ }} END{print hi, lo}'`; per file and class `\| sort \| uniq -c`; window = the line lacks `--headless` | 238 rows; `Makefile`: 116 ungated (**86** at ≥ 1080, **30** below), 5 gated, 3 other; none of the ≥ 1080 rows gated or other. 86 = 59 headless + 27 windowed, in 77 targets. Line, target, script and flags exactly as D2 and D9 |
| V3 | Tools, runtime, GPU at start | `ls runtime`; `make runtime`; `runtime/bin/ailang --version`; `godot --version`; `make deps starmap-assets planet-assets sky-assets import`; `ioreg … Device Utilization`; `ps … ollama` | no `runtime/` in the fresh clone; `make runtime` 3.8 s (15:28:51), then `AILANG v0.56.1`; `4.7.2.stable.official.ed1daf0bf`; deps, starmap, planet and sky assets and import rc 0 (0, 1, 4, 3 and 19 s); GPU 63 %; `ollama runner --model gemma4:12b-mxfp8` up 1 h 26 min; load 1.78 |
| V4 | Base: every headless target | `sh run.sh base 900 <49 headless targets>` (15:30:22–16:04:12); per row the last summary line of its own log and `grep -c 'SCRIPT ERROR'`, `grep -cE '^\s*ok\b'` | **47 rc 0, 2 rc 2**: `ship-console-test` (114 s, `FAIL AC4 fallback: the pinned baseline is fetched (make ship-baseline)`, `ship-consoles: 133 passed, 1 failures`) and `sim-pipeline-test` (54 s, `sim-pipeline: 3 failures`). 0 `SCRIPT ERROR` in every log. Times and summaries are D2's "Base" column; the 2,027 s total includes `solar-departure-test` 490 s, `free-nav-stop-test` 276 s and `no-twitch-test` 243 s |
| V5 | Base: reruns, the windowed rows, the fetch | `make ship-baseline`; `sh run.sh base-rerun 900 ship-console-test sim-pipeline-test sim-pipeline-test`; `sh run.sh base-win 600 <26 windowed targets>` (16:10:26–16:48:56); `sh run.sh base-extra 900 playthrough-adversarial` | `ship-baseline` 0.8 s, `build/ship-baseline matches art/deck-layout-v2/baseline.sha256`. Then `ship-console-test` rc 0, 111 s, `135 passed, 0 failures`; `sim-pipeline-test` rc 2 twice more (49 s, 51 s, the same three FAILs). Windowed: 19 rc 0, 5 rc 2, 2 rc 142 at the 600 s ceiling, with the rcs, times, GPU samples and summaries of D9; 0 `SCRIPT ERROR` in every windowed log. `playthrough-adversarial` rc 0, 155 s, `playthrough: 124218 passed, 0 failures` (it overlapped the windowed run) |
| V6 | What each B4 script prints | `grep -nE 'print\(.*(passed\|failures\|failed\|OK\|ok\|checks\|frames\|cases\|FAIL)' <each B4 script>` | the formats of Problem 5 and D3, for example `test_ring_protocol.gd:22` `"ring-protocol: %d failures"`, `validate_ship_demo.gd:42` `"validate-ship-demo: %s"` (`OK`/`FAIL`), `test_runtime_fingerprint.gd`, `test_live_journey.gd` and `test_ship_demo_live.gd` with no summary print, and `test_ship_commons_arcade.gd:14` `measured_terrace_vertices=%d` |
| V7 | Parse drill at base; headless vs windowed rc | `sh drill.sh pdrill-base head_rows.tsv` (59 headless rows) and `sh drill.sh pdrill-win win_rows.tsv` (27 windowed), each line from the base `Makefile` with its script swapped for a copy carrying `var _b4_drill: int = undefined_name_b4` after `extends`; then raw: `godot --headless --path . --script <copy>` vs `godot --audio-driver Dummy --path . --script <copy>` | headless: **5 rc 0** (`:1093`, `:1120`, `:1125`, `:1126`, `:1159`), 54 rc 2, 23 s in all; each copy logged `SCRIPT ERROR: Parse Error: Identifier "undefined_name_b4" not declared …`. Windowed: 27 rc 2. Raw: **headless rc 0, windowed rc 1** on the same copy |
| V8 | Runtime-error drill at base | **Superseded by V21 (revision 1):** this run's scratch harness wrote `$$$$` for `GODOT_SIM`, so the sim rows ran with a bogus `AILANG_BIN`, and the `ship-demo-live-test` row failed at startup. `INJECT=rt SRCREV=HEAD sh drill.sh rtdrill-base rt_base.tsv Makefile.base`: the base script (`git show HEAD:`) with `print(self.no_such_member_b4)` as the first line of `check()` | `rc=0` (passes) for `validate-ship-demo` (24 `SCRIPT ERROR`, `validate-ship-demo: OK`), `ship-demo-test` (`ship-demo: 0 passed, 0 failures`, 244 errors), `catalogue-coverage-test` (`0 passed`), `flyby-optics-test` (`0 checks, 0 failures`, 1,061 errors), `ring-protocol-test` (`0 failures`) and `tour-pacing-test` (`0 failures`); `rc=2` for `ship-demo-live-test` and `ship-attitude-test` |
| V9 | **The migrated tree, end to end** | the staged change set copied over the 23 files (16:29); `perl applymap.pl makemap.txt Makefile` refuses any line whose script, Godot variable or user arguments differ from its base line; `sh run.sh mig 3600 <48 B4a targets> playthrough-adversarial` (16:30:18–17:10:55); `grep -h '^script-gate:' mig/*.out \| sort -u -t: -k2,2 \| wc -l`; `grep -h '^script-gate:' mig/*.out \| grep -cE '^script-gate: [^ ]+ FAIL'` (status-anchored; corrected in revision 2, see the Quorum r2 response) | all **49 runs rc 0**; **57** distinct gate lines, each `ok` with D2's "After" summary and time; **0** gate FAIL statuses (anchored). The unanchored `grep -c FAIL` over the same 57 lines gives **4**: the reason text of four expected negative-control summaries (`ship-commons-assets-negative`, `ship-demo-assets-negative`, `ship-demo-geometry-wrong-tier`, `ship-demo-geometry-wrong-tip`); the fifth negative, `news-lint-stray-digit`, carries no `FAIL` text. All five negatives read `ok: … (rc 1, no SCRIPT ERROR, …)`; 58 `ok` status lines in all (controller re-measure, 18:12 CET). For example `solar-departure-test ok: … 134 passed … (603 s of 3000 s)` and `playthrough ok: … 124218 passed …` under `playthrough-adversarial`. GPU sampled 0–100 %, 1-minute load 2.5–18.9 |
| V10 | The new counts equal an independent reading; the D3 source facts | `grep -cE '^\s*ok\b'` in V4's base logs; `jq '.assets\|length' assets/ship_demo/manifest.json`; `jq '(.tiers\|length), ([.tiers[].templates\|length]\|add)' data/news/templates.json`; `grep -cE '(failures\|failed) *\+= *1'` in each pattern-1 file; a source read of the three no-summary scripts | base `ok` lines 24, 16, 25, 6, 17, 9, 9, 6, 12, 10, 18, 15, 23, 36 and 6 equal the new `passed` counts of `validate-ship-demo`, `ship-commons-assets`, `validate-ship-commons`, `runtime-fingerprint`, `live-journey`, `ship-demo-live`, `ring-protocol`, `ship-attitude`, `benchmark-upload`, `shadow-contacts`, `tour-attitude`, `tour-pacing`, `destination-pin`, `cruise-interlude` and `frame-check`; `5` assets (7 + 1 + 5 = 13); `5 20`; exactly **1** increment in each of the 15 files; one guarded check (`if prior_distance>=0.:check(…)`, `test_live_journey.gd`) and failure-path checks only |
| V11 | The applied tree: lint, inventory, pin, make versions | `make script-gate-lint`; `gmake --no-print-directory script-gate-lint`; `make script-gate-lint SCRIPT_GATE_BASELINE_ROWS=120`; `grep -vc '^#' tools/script-gate-baseline.txt`; the inventory on the applied tree filtered as V2 | `239 --script invocations: 120 through $(SCRIPT_GATE), 119 on the baseline …` and `4 pairs hold in Makefile: …` under both makes; the N+1 pin is refused; `119`; from line 1080, 57 gated and 30 ungated; 48 B4a targets × 56 deleted rows, every rule in the `Makefile` |
| V12 | Drills on the applied tree; the fresh baseline | `sh drill.sh pdrill-mig mig_rows.tsv` (57 lines); `INJECT=rt sh drill.sh rtdrill-mig rt_mig.tsv`; `make script-gate-selftest`; `make script-gate-drill`; `mv build/ship-baseline <aside>; make ship-console-test` | parse: **57 rc 2**, 52 `; 1 SCRIPT ERROR line(s) …; no summary line matching …` and 5 `; rc 0, want 1; 1 SCRIPT ERROR …`. Runtime: all 8 `rc=2`. `18 cases: 18 stub, 0 Godot`; `24 cases: 18 stub, 6 Godot`. Fresh: `ship-baseline: build/ship-baseline matches …`, `script-gate: ship-console-test ok: ship-consoles: 135 passed, 0 failures (rc 0, no SCRIPT ERROR, 114 s of 600 s)`, rc 0, 117 s |
| V13 | The `SG_PREREQS` pin and the new pair: mutants and control | on the applied tree, each mutant by `perl -pi` on `mk/script-gates.mk`, then `make script-gate-lint`, then restore from a copy (`cmp` equal): A, B, C as D6; `SG_PREREQS_PAIRS=5` and `=3`; the prerequisite mutant on `Makefile:1337`. Control: `git show HEAD:mk/script-gates.mk` (and the HEAD fixture) in place, `planets-test:planet-assets` dropped, `make script-gate-lint SCRIPT_GATE_BASELINE_ROWS=119` | A, B, C, D, E all **rc 2** with `script-gate-lint: SG_PREREQS holds 3 pairs (3 distinct)…`, `4 pairs (3 distinct)…`, `…is 5…`, `…is 3…`; the prerequisite mutant **rc 2**, `script-gate-prereqs: ship-console-test lost its prerequisite ship-baseline (ship-console-test: import)`. **Control rc 0**: `script-gate-prereqs: ok (2 pairs hold in Makefile: constellation-test:starmap-assets planet-textures-check:planet-assets)` (the survivor). Restored |
| V14 | Zero counts | `git show HEAD:Makefile \| awk 'NR>=1080' \| grep -cE "grep -q .\^[a-z-]+: \[0-9\]\* (passed\|checks)"`; `printf 'ship-demo: 0 passed, 0 failures\n' \| grep -cE '^ship-demo: [0-9]* passed, 0 failures$'`; `sh zero.sh \| sort \| uniq -c` | `31`; `1` (the old form accepts zero); `22 0` (every new ERE refuses its zeroed line) |
| V15 | Consumers of the changed lines; other users of B4 scripts | `P='validate-ship-demo: \|ship-commons-assets: \|validate-ship-commons: \|ship-demo-assets: \|ship-demo-benchmark: \|ship-demo-launch: \|ring-protocol: \|ship-attitude: \|benchmark-upload: \|shadow-contacts: \|tour-attitude: \|tour-pacing: \|destination-pin: \|cruise-interlude: \|frame-check: \|news-lint: (ok\|%s\|FAILED)\|runtime-fingerprint: \|live-journey: \|ship-demo-live: '; git grep -nIE "$P" HEAD -- .`, classified by path; the same on `'*.py'`; `git grep -nF -f b4_scripts.txt -- '*.sh' '*.gd' '*.yml' '*.py'`; the base inventory outside `Makefile` ≥ 1080 filtered by the B4 scripts; `git grep -n m4_ship_golden` on the B4 scripts | **49** lines: 42 code or config (20 print lines, 16 `Makefile` predicates at `:1108 1109 1127 1139 1141 1148 1271 1297 1301 1305 1309 1326 1327 1328 1342 1406`, `demos/frame_check.gd:217`, 5 frozen `art/` validation logs), 6 `.ailang/`, 1 `.md`; **`.py`: 0**. Script users: comments only, plus `tests/test_playthrough.sh:11` (it greps `FAIL <reason>` and the absence of `^playthrough: [0-9]* passed, 0 failures$`, `:13–15`; `m4_playthrough_ship.gd` is unchanged). No protected-file row names a B4 script. `m4_ship_golden`: 0 |
| V16 | Open PRs | `gh pr list --state open`; `gh pr diff <n> --name-only`; `Makefile` hunk starts: `gh pr diff 379` and, for #373/#380 (`gh pr diff` refused their escape sequences), `git diff $(git merge-base 05e64cd1 pr/<n>) pr/<n> -- Makefile` on a fetched PR ref | open #384, #380, #379, #373: 11, 31, 99, 57 files; ours `0`, `Makefile`, `Makefile`, `Makefile`; hunk starts #373 `-10 -18 -225`, #380 `-10 -18 -225 -245`, #379 `-485` |
| V17 | Aggregate closures and orphans | `sh closure.sh Makefile test` (and `ci-fast`, `golden`) on the base and the applied tree; every gated and every ungated target of the inventory checked against the three closures; parents from the `make -pq` database; `git grep` of the orphan names in `*.sh`, `*.yml`, `*.py` | closures 366, 24 and 25 targets; `ship-baseline` in `test`'s closure; `ship-console-test` not in `ci-fast`'s. Gated orphans: 13 at base, **14** on the applied tree (D8's table, `frame-check-test` the new one; each has `.PHONY` as its only parent or no parent). B4b: 28 of 29 targets orphaned (`true-light-golden` is in `golden`). Ungated in the whole inventory: 73 of 105. `level-eval` is named only in `tools/levels_backlog.sh` |
| V18 | Hygiene | `make uid-guard python-guard audio-silent-guard lint-precision`; `git diff --check` | `uid-guard: ok (406 .uid files)`; `python-guard: ok (21 allowlisted, 0 awaiting AILANG port)`; `audio-silent-guard: ok (79 windowed godot invocations; 5 allowlisted to keep sound)`; `lint-precision: ok (positive control matched 6 lines; 3 allowlisted non-computations; no live hand-computed gamma or 1 - beta)`; clean |
| V19 | Size, the diff, restore | `git diff --numstat`; `git diff > /tmp/iter72_designer/b4.diff`; `shasum -a 256`; `GIT_INDEX_FILE=<tmp> git read-tree 05e64cd1 && GIT_INDEX_FILE=<tmp> git apply --cached --check b4.diff`; restore each of the 23 files with `git show HEAD:<f> > <f>`; `git diff --quiet`; the 5 ignored `.translation` files deleted; `git status --porcelain`; `ps … godot` | 23 files, **+132/−163** (per file as in [Estimated LOC per file](#estimated-loc-per-file)); sha256 `9716f916…0f5d`; applies to `05e64cd1`; tree equal to HEAD; status empty before this doc was written; no Godot process left |

**Revision 1 (after design quorum round 1), 2026-11-05, 17:27–18:10 CET, same clone at `05e64cd1`.**
- `b4.diff` was re-applied with `patch -p1` and the one-line bound was added to `tools/ship_baseline.sh`. Every check below ran on that tree unless it says base.
- The tree was restored by writing `git show HEAD:<f>` over each of the 24 files.
- **No git command wrote anything:** no fetch, no ref, no index, no apply-to-index. The read-only ones were `git show`, `git diff`, `git apply --check`, `gh pr diff` and `git rev-parse`.
- The 5 ignored `.translation` files were deleted again. No Godot process was left.

| # | Claim | Command | Observed |
|---|---|---|---|
| V20 | D3 pattern 1 covers 15 files (objection 2) | on the applied tree: `git diff --name-only \| xargs grep -lE 'passes ?\+= ?int\(ok\)' \| wc -l`; `git show HEAD:tests/test_bridge_floor.gd \| grep -c 'passed+=int(ok)'` | **`15`**: `tests/test_{benchmark_upload,cruise_interlude,destination_pin,frame_check,live_journey,ring_protocol,runtime_fingerprint,shadow_contacts,ship_attitude,ship_commons_assets,ship_demo_live,tour_attitude,tour_pacing}.gd`, `tools/validate_ship_commons.gd`, `tools/validate_ship_demo.gd`; the idiom's precedent `1` |
| V21 | **AC5's list check and AC7–AC9 from this doc alone** (objections 1 and 3) | the `x` block above the AC table, run on this doc after the Appendix was written: `x 'text b4a-targets'`, `x 'sh b4-drill'`, `x 'text b4-rt-pairs'`, `x 'text b4-zero-pairs'`, `x 'sh b4-closure'`; `cmp` with the revision-0 scratch; then AC5's list check, AC7, AC8 (migrated, then base with `git show HEAD:Makefile` and `SRCREV=HEAD`), AC7's harness at base on the 59 base headless rows, and AC9, each exactly as the AC rows give them; `shellcheck -s sh` on the extracted harness | blocks of 48, 41, 8, 22 and 19 lines. The target list and closure are byte-identical to the revision-0 scratch. The harness rewrites the scratch `drill.sh` with the same two injections and the same line extraction. It writes `$$` in `GODOT_SIM`, where the scratch's `$$$$` gave a bogus `AILANG_BIN`, carries its supervisor inline, and writes only under `.godot/tmp/b4-drill/`. **AC5 list:** `list-ok` (A1 equals the 48 gated targets from `Makefile:1080`), `make -n` rc 0, no A1 target on the baseline. **AC7:** rows `57`, **`57 rc=2`**, `57` with `SCRIPT ERROR line(s)`; 52 `…; no summary line matching …` and 5 `rc 0, want 1; …`; 43 s. **AC7 harness at base:** `5 rc=0` (`:1093 :1120 :1125 :1126 :1159`), `54 rc=2`, as V7. **AC8:** rows `8`, **`8 rc=2`**; the sim row's log now shows 17 `SCRIPT ERROR` and `live-journey: 0 passed, 0 failures`, refused by the gate. **AC8 base:** `6 rc=0`, `2 rc=2`, the same rows as V8: `validate-ship-demo` (`OK`, 24 errors), `ship-demo-test` (`0 passed`), `catalogue-coverage-test`, `flyby-optics-test` (`0 checks`), `ring-protocol-test` and `tour-pacing-test` (`0 failures`) pass. `ship-demo-live-test` fails with its sim running (17 errors, the pinned `ok` line absent), and `ship-attitude-test` fails. **AC9:** **22 lines `zeroed=0 real=1`**, each ERE in the `Makefile` (`makefile=1`, and `1,12 … makefile=2`). shellcheck reports only SC2016 (info) on the two `printf` lines that write make syntax on purpose |
| V22 | **The baseline fetch: unbounded before, bounded after** (objection 4) | read `tools/ship_baseline.sh` (`cat -n`) and `git log --oneline -- tools/ship_baseline.sh`; callers `git grep -n ship_baseline.sh -- Makefile 'mk/*.mk' '*.sh' '*.yml'`. Throwaway copies (`/tmp/iter72_designer/sb*/` holding the script and `art/deck-layout-v2/baseline.sha256`) run with `SHIP_BASE_URL` set to: a stalled server (`stall.pl`, which accepts and never answers; probe `curl -m 3` → rc 28); a loopback connect blackhole (`blackhole.pl`, backlog full; probe `--connect-timeout 5` → rc 28 in 5 s); `http://10.255.255.1`; `http://192.0.2.1`. Each run under `sup.pl`, the HEAD script against the bounded one. Then, in the clone, with `build/ship-baseline` moved away: `SHIP_BASE_URL=<stalled> make ship-console-test`, with `stat -f %m .godot/tmp/ship-consoles.log` before and after. Then `make ship-baseline` and `cmp` with the earlier files. Then `gh pr diff <n> --name-only \| grep -c '^tools/ship_baseline.sh$'` for #373, #379, #380 and #384 | **Source:** `:28` `curl -fsS --retry 3 -o …`, no connect, total or retry-window limit, and no other timeout in the file; one commit (`c61f8599`); callers `mk/deck-layout.mk:7` and `tools/deck_blockout.sh:15`. **Stalled:** HEAD script **rc 142, killed at the 150 s ceiling, no output**; bounded script **rc 1 in 121 s**, `curl: (28) Operation timed out after 60101 milliseconds with 0 bytes received` ×2, then `ship-baseline: FAIL fetch ship.glb (9da7…)`. **Blackhole:** HEAD rc 1 in 39 s (4 × `Failed to connect … after 7786 ms`, the OS's SYN limit); bounded rc 1 in 27 s (3 attempts). **Unroutable:** both rc 1 in 4–5 s (`curl: (7) … Couldn't connect`). **Through make:** `make: *** [ship-baseline] Error 1`, rc 2, 125 s, no `script-gate:` line, test-log mtime unchanged (`import` ran first, as its prerequisite). **Real fetch:** rc 0, 1 s, `fetched` ×3, all three files identical. PRs: `0` each |
| V23 | The revised tree: AC14 as written, AC10, lint, self-test, drill, hygiene | AC14's server one-liner and command, copied from the AC row; `mv build/ship-baseline <aside>; make ship-console-test` (AC10); `make script-gate-lint`; `make script-gate-selftest`; `make script-gate-drill`; `make uid-guard python-guard audio-silent-guard lint-precision`; `git diff --check origin/main`; `shellcheck -s sh tools/ship_baseline.sh` | AC14: probe `28`; **`rc=2 124s`**; `2` timeouts; `ship-baseline: FAIL fetch ship.glb (…)` and `make: *** [ship-baseline] Error 1`; **`0`** `script-gate:` lines; then `ship-baseline: build/ship-baseline matches art/deck-layout-v2/baseline.sha256`. AC10: `ship-baseline: … matches …`, `script-gate: ship-console-test ok: ship-consoles: 135 passed, 0 failures (rc 0, no SCRIPT ERROR, 120 s of 600 s)`, rc 0. Lint `239 … 120 through $(SCRIPT_GATE), 119 on the baseline …`, `4 pairs hold …`; `18 cases`; `24 cases: 18 stub, 6 Godot`; the four guards as V18; `gates-ok` |
| V24 | Scope, size, the new diff, restore | AC12's three commands plus `git diff --numstat origin/main -- tools/ship_baseline.sh`; `git rev-parse --short origin/main`; `git diff --shortstat`; `git diff > /tmp/iter72_designer/b4.diff`; `shasum -a 256`; restore by `git show HEAD:<f> > <f>` for the 24 files; `git diff --quiet`; `git apply --check b4.diff`; `git status --porcelain` | `0`, `0`, `0`, `3	1	tools/ship_baseline.sh`; `05e64cd1`; **24 files, +135/−164**; sha256 `cdfaa8ffbf6ba33dcd2f536f1af4e11583aa6f005be388337e9fef43bc486f6c`; tree equal to HEAD; **applies to `05e64cd1`**; status `?? design_docs/planned/r1/m4-7x-b4-script-gates.md` only |

## Appendix: the AC inputs and harness (revision 1)

The ACs extract these blocks from this doc with the `x` helper given above the AC table, so they need nothing outside the clone. Each block opens with a fence whose info string names it, and ends at the next bare fence.

### A1. The 48 B4a targets (AC5, AC7, AC12)

The targets of D2, one per line, in `Makefile` order.

```text b4a-targets
validate-ship-demo
ship-demo-test
ship-commons-test
ship-commons-assets-test
ship-commons-arcade-test
ship-demo-live-test
validate-ship-commons
ship-demo-assets-test
ship-demo-lift-test
ship-demo-benchmark-test
ship-demo-geometry-negative-test
ship-demo-launch-test
ship-demo-input-test
ship-demo-journey-test
ship-star-identification-test
free-nav-stop-test
ship-demo-consolidation-test
title-screen-test
loading-jump-test
ship-movement-test
map-origin-test
ship-planets-test
ship-star-light-test
catalogue-coverage-test
solar-departure-test
flyby-optics-test
planet-rings-test
ring-protocol-test
planet-meter-test
ship-attitude-test
benchmark-upload-test
shadow-contacts-test
tour-attitude-test
bridge-floor-test
sim-bootstrap-test
tour-pacing-test
ship-ui-test
ship-console-test
frame-check-test
no-twitch-test
playthrough
news-lint
news-test
codex-test
camera-test
camera-forward-test
guided-finale-test
free-nav-recovery-test
```

### A2. The drill harness (AC7, AC8)

POSIX `sh` plus `awk`, `sed`, `perl` (the same supervisor as `tools/script_gate.sh`) and `make`. It is not a change-set file. It is a measuring tool, extracted from this doc and run from `.godot/tmp/`.

```sh b4-drill
#!/bin/sh
# Row 7x B4 drill (design m4-7x-b4-script-gates.md, Appendix A2). Run from the clone root.
# usage: sh b4-drill.sh TAG parse|rt ROWS [MAKEFILE [SRCREV]]
# ROWS holds lines "Makefile:LINE TARGET SCRIPT". Each LINE of MAKEFILE (default Makefile) runs exactly as written,
# continuation lines included, in a throwaway makefile that carries the Makefile's own GODOT, GODOT_SIM, AUDIO_OFF and
# $(SCRIPT_GATE) definitions, with SCRIPT swapped for a copy: parse = a parse error after `extends`; rt = a runtime
# error as the first line of check(), so every check aborts. SRCREV takes SCRIPT from that git revision (git show,
# read-only). Each line runs under a 180 s process-group deadline. Writes only under .godot/tmp/b4-drill/TAG.
set -u
tag=$1 mode=$2 rows=$3 mf=${4:-Makefile} rev=${5:-}
out=.godot/tmp/b4-drill/$tag
mkdir -p "$out/scratch/playthrough"
: > "$out/results.txt"
sup() {
  perl -e 'use POSIX ":sys_wait_h"; my $secs = shift; my $pid = fork; die "fork: $!" unless defined $pid; if ($pid == 0) { setpgrp(0, 0); exec @ARGV or exit 127; } my $end = time + $secs; my $st; while (1) { my $r = waitpid($pid, WNOHANG); if ($r == $pid) { $st = $?; last } if (time >= $end) { kill "TERM", -$pid; select(undef, undef, undef, 2); kill "KILL", -$pid; waitpid($pid, 0); exit 142 } select(undef, undef, undef, 0.1) } exit($st & 127 ? 128 + ($st & 127) : $st >> 8)' "$@"
}
while read -r loc t s; do
  [ -n "${loc:-}" ] || continue
  ln=${loc#*:}
  b=$(basename "$s" .gd)
  src=$s
  if [ -n "$rev" ]; then src=$out/src-$b.gd; git show "$rev:$s" > "$src"; fi
  if [ "$mode" = rt ]; then
    p=$out/${b}_r.gd
    awk '{print} f==0 && /^func check\(/ {print "\tprint(self.no_such_member_b4)"; f=1}' "$src" > "$p"
  else
    p=$out/${b}_p.gd
    awk 'f==0 && /^extends /{print; print "var _b4_drill: int = undefined_name_b4"; f=1; next} {print}' "$src" > "$p"
  fi
  grep -q 'no_such_member_b4\|undefined_name_b4' "$p" || { echo "$ln $t NOINJECT" >> "$out/results.txt"; continue; }
  {
    printf 'GODOT ?= godot\nAILANG ?= ailang\nGODOT_SIM = AILANG_BIN="$$(command -v $(AILANG))" $(GODOT)\nAUDIO_OFF := --audio-driver Dummy\n'
    printf 'SCRATCH := %s/scratch\nPLAYTHROUGH_OUT := %s/scratch/playthrough\nSCRIPT ?= tests/playthrough_min.json\nAI ?= none\n' "$out" "$out"
    printf 'SG_TOOLS := tools\nSCRIPT_GATE = sh $(SG_TOOLS)/script_gate.sh\ndrill:\n'
    awk -v L="$ln" 'NR >= L { print; if ($0 !~ /\\$/) exit }' "$mf" | sed "s#--script $s#--script $p#"
  } > "$out/drill-$ln.mk"
  grep -q -- "--script $p" "$out/drill-$ln.mk" || { echo "$ln $t NOSUB" >> "$out/results.txt"; continue; }
  sup 180 make --no-print-directory -f "$out/drill-$ln.mk" drill > "$out/drill-$ln.out" 2>&1
  echo "$ln $t rc=$?" >> "$out/results.txt"
done < "$rows"
awk '{print $3}' "$out/results.txt" | sort | uniq -c
```

### A3. The runtime-error drill rows (AC8)

`TARGET SCRIPT` pairs. AC8 maps them to their line numbers on the tree under test through `make script-gate-inventory`. The base rows (`origin/main` at `05e64cd1`) are `Makefile:1093`, `1096`, `1115`, `1260`, `1267`, `1271`, `1297` and `1326`, in this order.

```text b4-rt-pairs
validate-ship-demo tools/validate_ship_demo.gd
ship-demo-test tests/test_ship_demo.gd
ship-demo-live-test tests/test_live_journey.gd
catalogue-coverage-test tests/test_catalogue_coverage.gd
flyby-optics-test tests/test_flyby_optics.gd
ring-protocol-test tests/test_ring_protocol.gd
ship-attitude-test tests/test_ship_attitude.gd
tour-pacing-test tests/test_tour_pacing.gd
```

### A4. The 22 zero-probe pairs (AC9)

`D2 row|SUMMARY_ERE as the shell sees it ($$ in the Makefile is $ here)|the pass line with one count zeroed|the measured pass line (V9)`.
- 20 pairs cover every *changed* positive ERE: rows 1 and 12 share one ERE (one pair), and row 49 has two counts (two pairs, 49a with `tiers` zeroed and 49b with `templates` zeroed).
- Row 6 (`ship-commons-arcade`, unchanged script, new ERE) and row 2 (`ship-demo`, the unchanged-format control whose old ERE `[0-9]*` accepted zero) make 22.
- The other 30 positive lines carry the same `[1-9][0-9]*` form. The helper's run-time probe (`tools/script_gate.sh:38–54`) passed every one of the 52 positive lines in V9: a gate prints `ok` only after that probe.

```text b4-zero-pairs
1,12|^validate-ship-demo: OK \([1-9][0-9]* passed, 0 failures\)$|validate-ship-demo: OK (0 passed, 0 failures)|validate-ship-demo: OK (24 passed, 0 failures)
4|^ship-commons-assets: OK \([1-9][0-9]* passed, 0 failures\)$|ship-commons-assets: OK (0 passed, 0 failures)|ship-commons-assets: OK (16 passed, 0 failures)
10|^validate-ship-commons: OK \([1-9][0-9]* passed, 0 failures\)$|validate-ship-commons: OK (0 passed, 0 failures)|validate-ship-commons: OK (25 passed, 0 failures)
11|^ship-demo-assets: OK \([1-9][0-9]* passed, 0 failures\)$|ship-demo-assets: OK (0 passed, 0 failures)|ship-demo-assets: OK (13 passed, 0 failures)
15|^ship-demo-benchmark: OK \([1-9][0-9]* passed, 0 failures\)$|ship-demo-benchmark: OK (0 passed, 0 failures)|ship-demo-benchmark: OK (3 passed, 0 failures)
17|^ship-demo-launch: OK \([1-9][0-9]* passed, 0 failures\)$|ship-demo-launch: OK (0 passed, 0 failures)|ship-demo-launch: OK (4 passed, 0 failures)
7|^runtime-fingerprint: [1-9][0-9]* passed, 0 failures$|runtime-fingerprint: 0 passed, 0 failures|runtime-fingerprint: 6 passed, 0 failures
8|^live-journey: [1-9][0-9]* passed, 0 failures$|live-journey: 0 passed, 0 failures|live-journey: 17 passed, 0 failures
9|^ship-demo-live: [1-9][0-9]* passed, 0 failures$|ship-demo-live: 0 passed, 0 failures|ship-demo-live: 9 passed, 0 failures
33|^ring-protocol: [1-9][0-9]* passed, 0 failures$|ring-protocol: 0 passed, 0 failures|ring-protocol: 9 passed, 0 failures
35|^ship-attitude: [1-9][0-9]* passed, 0 failures$|ship-attitude: 0 passed, 0 failures|ship-attitude: 6 passed, 0 failures
36|^benchmark-upload: [1-9][0-9]* passed, 0 failures$|benchmark-upload: 0 passed, 0 failures|benchmark-upload: 12 passed, 0 failures
37|^shadow-contacts: [1-9][0-9]* passed, 0 failures$|shadow-contacts: 0 passed, 0 failures|shadow-contacts: 10 passed, 0 failures
38|^tour-attitude: [1-9][0-9]* passed, 0 failures$|tour-attitude: 0 passed, 0 failures|tour-attitude: 18 passed, 0 failures
41|^tour-pacing: [1-9][0-9]* passed, 0 failures$|tour-pacing: 0 passed, 0 failures|tour-pacing: 15 passed, 0 failures
42|^destination-pin: [1-9][0-9]* passed, 0 failures$|destination-pin: 0 passed, 0 failures|destination-pin: 23 passed, 0 failures
43|^cruise-interlude: [1-9][0-9]* passed, 0 failures$|cruise-interlude: 0 passed, 0 failures|cruise-interlude: 36 passed, 0 failures
46|^frame-check: [1-9][0-9]* passed, 0 failures$|frame-check: 0 passed, 0 failures|frame-check: 6 passed, 0 failures
49a|^news-lint: ok \([1-9][0-9]* tiers, [1-9][0-9]* templates\)$|news-lint: ok (0 tiers, 20 templates)|news-lint: ok (5 tiers, 20 templates)
49b|^news-lint: ok \([1-9][0-9]* tiers, [1-9][0-9]* templates\)$|news-lint: ok (5 tiers, 0 templates)|news-lint: ok (5 tiers, 20 templates)
6|^ship-commons-arcade: OK plaza=true measured_terrace_vertices=[1-9][0-9]* roof=true open_arch=true$|ship-commons-arcade: OK plaza=true measured_terrace_vertices=0 roof=true open_arch=true|ship-commons-arcade: OK plaza=true measured_terrace_vertices=6142 roof=true open_arch=true
2|^ship-demo: [1-9][0-9]* passed, 0 failures$|ship-demo: 0 passed, 0 failures|ship-demo: 244 passed, 0 failures
```

### A5. The aggregate closure (D8, V17)

`sh b4-closure.sh MAKEFILE ROOT...` prints every target that the roots reach through prerequisites and through words on recipe lines that call `$(MAKE)`, read from `make -pq`.

```sh b4-closure
#!/bin/sh
# usage: closure.sh MAKEFILE ROOT... -> every target reachable from the roots through prerequisites and through
# recipe lines that call $(MAKE) (make -pq database; every word on such a line counts as a possible target)
mf=$1; shift
env -u MAKEFLAGS -u MFLAGS -u MAKELEVEL make -pq --no-print-directory -f "$mf" closure-probe 2>/dev/null |
awk -v roots="$*" '
  /^# Not a target:/ { skip = 1; next }
  /^\t/ { if (cur != "" && $0 ~ /\$\(MAKE\)|\$\{MAKE\}|\$\$\(MAKE\)/) deps[cur] = deps[cur] " " $0; next }
  /^[^#\t ][^=]*:/ && $0 !~ /=/ {
    if (skip) { skip = 0; cur = ""; next }
    t = $0; sub(/:.*/, "", t); p = $0; sub(/^[^:]*:+/, "", p); sub(/\|.*/, "", p)
    deps[t] = deps[t] " " p; cur = t; next }
  /^$/ { cur = "" }
  { skip = 0 }
  END {
    n = split(roots, q, " "); for (i = 1; i <= n; i++) seen[q[i]] = 1
    while (n > 0) { t = q[n]; n--; m = split(deps[t], d, /[ \t;]+/)
      for (j = 1; j <= m; j++) if (d[j] != "" && !(d[j] in seen)) { seen[d[j]] = 1; q[++n] = d[j] } }
    for (t in seen) print t }' | LC_ALL=C sort
```
