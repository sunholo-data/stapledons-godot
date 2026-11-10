# earth_log_voyage plans alpha Cen A at its real map index (7ai)

**Status:** Planned 2026-11-10 (mission iteration 85, designer). **Release:** r1. **Milestone:** none (suite hygiene, queue row **7ai**).
**Priority:** P1. `make tools-test` has been red on main since PR #379 (R3-COMMS-V2, `e70d0fdf`, merged as `8ba1e3c8`). The nightly `rig/full` reports it every night (7ag keeps going past it), so gate 1 of the definition of done ("main's nightly `rig/full` stays green") cannot hold until it is fixed.
**Implements:** row 7ai of the charter (`design_docs/stapledon-mission.md`, Queue), clause 2/5 replay hygiene. Restores the map-index rule of `0f5a1175`: every committed replay log's plan target index is the `data/starmap/stars.json` index of its id. No design-repo feature or physics-spec section applies. The sim does not read the index for any physics (V6).
**Depends on:** nothing.
**Estimated LOC:** about 16, none of it product code. 1 byte in `tests/replays/earth_log_voyage.ndjson`, 2 re-recorded `.sha256` lines, 7 lines of control test in `tools/test_replay.py` (an allowlisted harness), and 4 Makefile lines.

## Game vision alignment

Scored against `../stapledons-design/vision/core-pillars.md` (pillars 1–6) and `physics/relativity-spec.md`.

| Pillar | Relevance | Score | Notes |
|---|---|---:|---|
| Choices Are Final | 0 | 0 | No game code changes. |
| The Game Doesn't Judge | 0 | 0 | No copy changes. |
| Time Has Emotional Weight | 0 | 0 | No player-visible change. |
| The Ship Is Home | 0 | 0 | No scene or asset change. |
| Grounded Strangeness | 0 | 0 | None. |
| We Are Not Built For This | 0 | 0 | None. |
| Hard sci-fi authenticity (spec) | 0 | 0 | No formula, shader, LUT or render. Only the echoed catalogue index changes in the state golden; no physics field moves (V6). Physics gates 2 and 3 do not apply. |
| **Net** | | **0** | **Go.** Neutral test hygiene. Nothing scores below 0 and nothing is visible, so no stop for Mark. |

## Problem

1. **The red (V1).** At `e0ba4ae7`, `python3 tools/test_replay.py` exits rc 1. It runs 32 tests with 3 failures, all in `MapIndex`. The real mismatch is `earth_log_voyage.ndjson:3 plan CNS5:3627 index 1, stars.json 2`. The two controls (`test_a_stale_index_fails`, `test_an_unknown_id_fails`) expect exactly one injected mismatch. They fail `2 != 1` only because the real fixture already adds one.
2. **The fixture line.** Line 3 is `{"k":"plan","target":{"index":1,"id":"CNS5:3627","pos":{"x":3.094521,"y":-3.015404,"z":-0.051608}},…}`. Its id and position belong to stars.json entry 2 (alpha Centauri A). Index 1 is `HIP 71681` (alpha Cen B, 19″ away), a different star. It has been index 1 since `e70d0fdf`. `cc6dc7c8` only appended tick 43 and re-recorded. `8ba1e3c8` (#379's merge) carries index 1 (V2).
3. **Root cause: a hand-written constant, copied. No recorder wrote it (V3–V5).**
   - **CNS5:3627 has never been at index 1** in any tracked `stars.json`. It is 2 at every revision since the M1.7 catalogue switch (`0a8f4264`). Before that the id did not exist (V3).
   - **The index-1 literal was typed by hand.** It first appears on 2026-10-08 in `sim/stops_test.ail:92` (`acenA() = { index: 1, id: "CNS5:3627", … }`, `7f392c59`). It most likely comes from the pre-M1.7 design row `alpha Cen`, which is index 1 in `tools/gen_session.py:42`. That origin is an inference, not measured. R3-EARTH-LINK (`d6f2889a`, 2026-10-29) copied it as `const ALPHA := {"index": 1, "id": "CNS5:3627", …}` into the GDScript comms and earth tests and tools. It now sits in 8 GDScript files, `sim/stops_test.ail` and `tools/worlds_leak.py` (V4). The earth_log_voyage plan line is that constant in compact JSON.
   - **No in-tree recorder produced the fixture (V5).**
     - No tracked tool, script or Makefile line names `earth_log_voyage` except its two goldens.
     - The fixture's plan carries no `"star"` row, but `GalaxyMap.plan_intent` (`ui/galaxy_map.gd:541–548`) adds one for CNS5:3627 (vmag −0.01, teff 5550), and already did at `e70d0fdf`. The fixture's ticks use `dtau` 0 and 0.02, not the map's host rate.
     - Every real recorder takes the index from the catalogue order. `GalaxyMap.plan_intent(i)` writes `"index": i` for `catalogue[i]`, and `index_by_id` is built from the same array (`:457–460`). `tools/record_godot_session.gd` uses `map.index_of(...)`, and `ui/transit_harness.gd:10` has index 2. `0f5a1175`'s Sirius A re-record was the honest case: the map changed under a real recording. Here the map never changed and the log was never recorded.
   - **Why it reached main.** `tools-test` is in `make test`, but `make ci-fast` does not run it: `make -n ci-fast | grep -c test_replay.py` = 0 (V7). #379's gate list (`e70d0fdf` message) names `replay` but not `tools-test`. The nightly then stopped at its first red until 7ag.
4. **What the sim does with the index (V6).** `sim/core.ail` plans from `rq.target.pos` (star) or `rq.target.id` (finite body). It stores the target and echoes it in `journey.plan.target` (`sim/protocol.ail:272`). Changing 1 → 2 in the input changes exactly 3 bytes of the 1,389,901-byte state stream: the `"index":1` → `"index":2` echoes at ticks 1 (planned), 2 (committed) and 33 (arrived). Nothing else moves. The VM and the interpreter agree on the corrected log.

**Verdict: (a), fixture edit plus golden re-record.** There is no recorder to fix. The guard in M3 is what stops this recurring: it puts the check in the fast tier.

## Goals and non-goals

**Goals.**
- `make tools-test` green: `MapIndex` 0 real mismatches, and both existing controls back to exactly 1.
- `earth_log_voyage` replays VM = interpreter = golden. The arm64 and x86_64 `.sha256` files stay byte-identical.
- A committed control proves that this exact defect (CNS5:3627 at index 1) is caught.
- The MapIndex check runs in `ci-fast`, so a log like this goes red at its PR.

**Non-goals.**
- The copied `ALPHA` constant in GDScript tests and tools, `sim/stops_test.ail` and `tools/worlds_leak.py`. These feed the sim directly, not a committed replay log, and some drive GPU goldens and review captures (see F1).
- Adding a `"star"` row or the host `dtau` to the fixture to make it look Godot-recorded. That would change the plan path (D-58 `inferStar`) and the golden beyond the index.
- Moving the rest of `tools-test` (Replay, VmOnly, Compat, AiSession, sky and lens fetch tests; about 8 s) into `ci-fast` (F2).

## Design

### M1. Fix the fixture and re-record the goldens

- Change `tests/replays/earth_log_voyage.ndjson` line 3 `"index":1,"id":"CNS5:3627"` → `"index":2,"id":"CNS5:3627"`. This is one byte (V8).
- `make replay-record LOG=earth_log_voyage` on arm64 with AILANG v0.56.1. The output exceeds 256 KB, so it is digest-only. The harness writes `tests/replays/earth_log_voyage.state.arm64.sha256` = `07dcdfc610228499082996f3753acffa5b385734101a66fff515fa26bce0a454  earth_log_voyage.state.ndjson` (the digest V6 measured; the line format is `record()`'s `"%s  %s.state.ndjson\n"`).
- Copy that file to `…state.x86_64.sha256`, as `0f5a1175` did. The two were byte-identical before (`e62a9272…`). The line names `earth_log_voyage.state.ndjson` with no arch, so the copy is exact. The GitHub fast tier (`ubuntu-latest`, x86_64, `make replay` in `ci-fast`) confirms x86_64 at the PR.
- `replay-compat` is untouched: `earth_log_voyage` has no frozen 2.0 golden (`tests/replays/compat-2.0/inputs.sha256` has 0 matches). No other tracked file pins `e62a9272` (V9).

### M2. A committed control for the 7ai defect

Add this to `class MapIndex` in `tools/test_replay.py`, after `test_an_unknown_id_fails`:

```python
    def test_the_7ai_index_fails(self):  # control: alpha Cen A (CNS5:3627) at HIP 71681's index 1, as earth_log_voyage had it until 7ai
        logs = self.logs()
        n = sum(t.count('"index":2,"id":"CNS5:3627"') for _, t in logs)
        bad = plan_index_mismatches([(f, t.replace('"index":2,"id":"CNS5:3627"', '"index":1,"id":"CNS5:3627"')) for f, t in logs], self.stars())
        self.assertGreater(n, 0)
        self.assertEqual(len(bad), n)
        self.assertIn("earth_log_voyage.ndjson:3 plan CNS5:3627 index 1, stars.json 2", bad)
```

The prototype was measured on a scratch copy of the corrected logs (V10). The mutation hits 6 plan lines in 5 logs: earth_log_voyage:3, godot_map_voyage:6, m4_adversarial:3 and :6, m4_min_path:3, m4_transit_harness:6. It yields exactly 6 mismatches, each `… index 1, stars.json 2`. At base the test is red (n = 5, mismatches 6), so it fails until M1 lands. The existing controls are unchanged.

### M3. `replay-map-index` in `ci-fast`

Insert after the `replay-record` recipe (`Makefile:431–433`, the replay block):

```make
.PHONY: replay-map-index
replay-map-index:  ## 7ai: every committed replay log plans each star at its stars.json index (tools/test_replay.py MapIndex, under a second; also in tools-test)
	python3 tools/test_replay.py MapIndex
ci-fast: replay-map-index
```

**Why only MapIndex, and why ci-fast.**
- MapIndex takes 0.28 s wall (V11). It only reads JSON from the tree, with no subprocess, no AILANG, no arch and no network.
- `python3` is already on the fast-tier runner (`replay` in `ci-fast` runs `python3 tools/replay.py`).
- The other `tools-test` classes run the harness against a fake ailang across arch fallbacks, and the sky and lens scripts run under `sh`. That is dash on Ubuntu, and none of it has been measured on the runner. F2 leaves them to the 7ag tiering line.
- `ci-fast:` gets a separate rule line, as 7ah did (`Makefile:115`). The `ci-fast:` and `test:` lines (55, 57) are not edited. `make test` keeps reaching MapIndex through `tools-test`.

**Placement.** No open PR has a hunk there. #412 edits around line 32, #373 around 10, 18 and 225, and #380 around 251 (the `extract:` area). None is near 431–436 (V12).

## Files touched and do-not-touch

- **Touched:** `tests/replays/earth_log_voyage.ndjson` (1 byte), `tests/replays/earth_log_voyage.state.{arm64,x86_64}.sha256`, `tools/test_replay.py` (M2), `Makefile` (M3). Landing adds a changelog fragment and the charter and README status rows.
- **Do not touch:**
  - `data/starmap/*`, `sim/`, `ui/`, `bridge/` and every other replay log or golden;
  - the GDScript and Python `ALPHA` constants (F1);
  - `tools/replay.py`;
  - the `ci-fast:` and `test:` lines.

## Acceptance criteria

Headless. Run in the fix clone with `B=e0ba4ae7`. `AILANG` must be v0.56.1. The clone has no `runtime/`, so either run `make runtime` first or set `AILANG=../stapledons-godot/runtime/bin/ailang`, as was measured (V1). Expected values were measured on scratch copies (V1–V12).

| # | Criterion | Command | Expected |
|---|---|---|---|
| 1 | Red before (base) | at `$B`: `python3 tools/test_replay.py MapIndex; echo rc=$?` | `Ran 3 tests`, `FAILED (failures=3)`, the line `earth_log_voyage.ndjson:3 plan CNS5:3627 index 1, stars.json 2`, `rc=1` |
| 2 | Red before (T1, M2 and M3 in, fixture not yet fixed) | `make replay-map-index; echo rc=$?` | `Ran 4 tests`, `FAILED (failures=4)` (`test_the_7ai_index_fails`: `6 != 5`), make rc 2 |
| 3 | Green after | `make replay-map-index; echo rc=$?` and `make tools-test; echo rc=$?` | `Ran 4 tests` `OK`, `rc=0`; `Ran 33 tests` `OK`, then the sky and lens scripts pass, `rc=0` |
| 4 | Fixture change is one byte | `git show $B:tests/replays/earth_log_voyage.ndjson \| cmp -l - tests/replays/earth_log_voyage.ndjson` | exactly one line, `<offset>  61  62` (`1` → `2`) |
| 5 | Goldens re-recorded and identical across arches | `cat tests/replays/earth_log_voyage.state.arm64.sha256; cmp tests/replays/earth_log_voyage.state.arm64.sha256 tests/replays/earth_log_voyage.state.x86_64.sha256; echo rc=$?` | `07dcdfc610228499082996f3753acffa5b385734101a66fff515fa26bce0a454  earth_log_voyage.state.ndjson`, `rc=0` |
| 6 | Replay passes, VM = interpreter = golden | `make replay SESSION=tests/replays/earth_log_voyage.ndjson AILANG=$AILANG; echo rc=$?` | `ok    earth_log_voyage  45 lines  1389901 bytes … sha256 07dcdfc610228499 …`, `replay: 1 cases, all identical`, `rc=0` |
| 7 | Only the index echoes change in the state | `git show $B:tests/replays/earth_log_voyage.ndjson \| $AILANG run --quiet --bytecode --package-dir sim --caps IO --entry main sim/ship.ail > /tmp/7ai_b.out; $AILANG run --quiet --bytecode --package-dir sim --caps IO --entry main sim/ship.ail < tests/replays/earth_log_voyage.ndjson > /tmp/7ai_f.out; cmp -l /tmp/7ai_b.out /tmp/7ai_f.out; rm /tmp/7ai_?.out` | exactly `56554  61  62`, `60660  61  62` and `1059580  61  62` (the three `journey.plan.target.index` echoes at ticks 1, 2 and 33) |
| 8 | A re-introduced wrong index is caught at the fast tier | `sed -i.bak 's/"index":2,"id":"CNS5:3627"/"index":1,"id":"CNS5:3627"/' tests/replays/earth_log_voyage.ndjson; make replay-map-index; echo rc=$?; mv tests/replays/earth_log_voyage.ndjson.bak tests/replays/earth_log_voyage.ndjson; git status --porcelain` | the mismatch line `earth_log_voyage.ndjson:3 plan CNS5:3627 index 1, stars.json 2`, `FAILED (failures=…)` (four tests red), make rc 2; then no `git status` output |
| 9 | Wired into `ci-fast` | `make -n ci-fast 2>/dev/null \| grep -c 'test_replay.py MapIndex'` and `grep -nx 'ci-fast: replay-map-index' Makefile` | `1`; one line. After the push the PR's `make ci-fast` check is green (`gh pr checks <PR>`), which also runs `replay` on x86_64 against the copied golden |
| 10 | Cheap | `time make replay-map-index` | real under 2 s (0.28 s measured for the test alone) |
| 11 | Hygiene and scope | `make python-guard uid-guard; git diff --check $B; git diff --name-only $B` | `python-guard: ok`, `uid-guard: ok`; diff-check silent; exactly `Makefile`, `tests/replays/earth_log_voyage.ndjson`, the two `.state.*.sha256`, `tools/test_replay.py`, plus landing files under `changelogs/`, `design_docs/`, `.ailang/state/` |

## Sub-milestones and estimates

| # | What | LOC | Depends | Order |
|---|---|---:|---|---|
| T1 | M2 control and M3 target, fixture still wrong: AC2 red | ~11 | none | 1 (red first) |
| M1 | Fixture byte, `replay-record` on arm64, copy to x86_64 | 3 | T1 | 2. AC3–AC7 green |
| V | AC8–AC11; push, fast tier green (AC9) | 0 | M1 | 3 |

About 2 minutes of replay (VM about 10–45 s and interpreter about 55–92 s on the busy Studio, V1/V6). No GPU.

## Risks and mitigations

- **x86_64 differs from arm64.** Not measured locally. Every replay golden so far has been identical on both arches (CLAUDE.md), and the change is 3 ASCII bytes of echo. The fast tier runs `make replay` on x86_64 and decides it (AC9). If it disagrees, record x86_64 from the runner's output rather than copy.
- **A later stars.json reorder** moves alpha Cen A again. MapIndex now fails at the PR (ci-fast) instead of on the nightly. The fix is a `0f5a1175`-style re-record. The intended behaviour is unchanged.
- **The M2 control's count depends on how many logs plan CNS5:3627 at 2.** It counts them (`n`) instead of hard-coding 6, and requires `n > 0`, so adding or removing a log does not break it.
- **AC8 edits a tracked file in place.** It restores the file from `.bak` and checks `git status --porcelain`. If it is interrupted, `git checkout -- tests/replays/earth_log_voyage.ndjson` restores it.

## Open questions for the user

None. The fix is test data and a fast-tier test edge. Nothing a player sees or hears changes.

## Follow-ups (new findings, not scope)

- **F1. The wrong `ALPHA` constant lives on outside replay logs (V4).** `{"index": 1, "id": "CNS5:3627", …}` appears in:
  - `tests/test_bridge_monitors.gd:15`, `tests/test_earth_beams.gd:15`, `tests/test_earth_history.gd:21`, `tests/test_earth_log_bridge.gd:14`;
  - `tools/comms_golden.gd:23`, `tools/comms_station_capture.gd:26`, `tools/earth_link_capture.gd:16`, `tools/earth_rate_fixture.gd:10`;
  - `sim/stops_test.ail:92` and `tools/worlds_leak.py:29`.

  The sim ignores the index. One product reader does use it: `GalaxyMap.target_name()` and `subtitle_text()` (`ui/galaxy_map.gd:951`, `:976`) show the common name only when `catalogue[index].id == id`. Otherwise they fall back to the raw id. **Hypothesis, not measured:** a capture that shows the galaxy-map title for one of these plans reads "CNS5:3627" where the live game reads "Alpha Centauri A". Some of these tools feed GPU goldens and review captures. Changing them is a visual-review change, so it belongs in its own row, attended if any capture changes. A source lint could extend MapIndex to `"id": "CNS5:…"` literals in `tests/` and `tools/`.
- **F2. The rest of `tools-test` is not in `ci-fast`.** It takes about 8 s (V11), but the Replay, VmOnly and Compat arch-fallback tests and the `sh` asset scripts are unmeasured on Ubuntu and dash. This is for the 7ag test-tiering line.

## Deliverables

- M1: fixture byte and both goldens. M2: `test_the_7ai_index_fails`. M3: `replay-map-index` with its `ci-fast` edge.
- Evidence for AC1–AC11 in `.ailang/state/sprints/sprint_7ai.json`.
- On landing: a changelog fragment, row 7ai's status in the charter, and the README index row.

## Verification log

Run 2026-11-10 in `stapledons-godot-iter85-7ai` at `e0ba4ae7` on the Studio (arm64). The `AILANG` binary was `../stapledons-godot/runtime/bin/ailang` (`AILANG v0.56.1`), because the clone has no `runtime/` and the `ailang` on PATH is v0.59.0-dev. Scratch work was done in `/tmp/stap_i85_7ai` and deleted afterwards. The tree was not modified.

| # | Command | Result |
|---|---|---|
| V1 | `python3 tools/test_replay.py MapIndex`; `python3 tools/test_replay.py`; `tools/replay.py --session <scratch copy of the log and both goldens>` | MapIndex `Ran 3 tests`, `FAILED (failures=3)`, `earth_log_voyage.ndjson:3 plan CNS5:3627 index 1, stars.json 2`; the full file `Ran 32 tests`, failures=3; scratch replay of the unchanged log `ok … 45 lines 1389901 bytes VM 42.89 s interpreter 92.47 s sha256 e62a9272814e3057`, rc 0 |
| V2 | `git log --follow -- tests/replays/earth_log_voyage.ndjson`; `git show e70d0fdf:…` line 3; `git show cc6dc7c8 -- …`; `git show 8ba1e3c8:…` line 3 | two commits; index 1 at `e70d0fdf` (hello minor 17); `cc6dc7c8` only appended tick 43 (`earth_weeks`) and moved the hello to 18; `8ba1e3c8` has index 1 |
| V3 | for each commit in `git log -- data/starmap/stars.json`: index of `CNS5:3627` | `2f57110f`, `d80d1abc`, `00e89d1d`, `0a8f4264`: 2; `47008254`, `27af5935`: absent (pre-M1.7 ids). Head: 0 `Gaia DR3 5853498713190525696`, 1 `HIP 71681`, 2 `CNS5:3627` |
| V4 | `git log --reverse -S'index: 1, id: "CNS5:3627"'`; `git log --reverse -S'{"index": 1, "id": "CNS5:3627"'`; `git ls-files '*.gd' '*.ail' '*.py' '*.sh' \| xargs grep -n '"index"[: ]*1\b'` | first `7f392c59` (2026-10-08, `sim/stops_test.ail`); GDScript first in `d6f2889a` (R3-EARTH-LINK EL3b.5), then `ffbf6729`, `21756ce7`, `6bdbed04`, `1f7444cb`, `e70d0fdf`, `cc6dc7c8`; 10 files hold it (F1); `tools/gen_session.py:42` and `gen_ai_session.py:37` hold the design row `alpha Cen` at index 1 |
| V5 | `git ls-files \| xargs grep -l earth_log_voyage` (excluding docs and state); `sed` of `ui/galaxy_map.gd:448–460, 541–548`; `git show e70d0fdf:ui/galaxy_map.gd \| grep -n '"star"'`; `head tools/record_godot_session.gd`; `grep TARGET ui/transit_harness.gd` | only the two `.sha256` goldens; `plan_intent(i)` writes `"index": i` from `catalogue[i]`, `index_by_id` from the same array; `"star"` row present at `e70d0fdf:547`; recorder uses `map.index_of`; `TransitHarness.TARGET` index 2 |
| V6 | `$AILANG run --quiet --bytecode --package-dir sim --caps IO --entry main sim/ship.ail` on the base log and on the index-2 copy; `cmp -l`; the tick and journey state of each differing line; `tools/replay.py --session <index-2 copy>`; `sed -n 285,350p sim/core.ail` | base sha `e62a9272…` (= golden), fixed `07dcdfc610228499082996f3753acffa5b385734101a66fff515fa26bce0a454`; `cmp -l`: `56554 61 62`, `60660 61 62`, `1059580 61 62`; lines 3, 4, 35 = ticks 1 (`planned`), 2, 33 (`arrived`); 1,389,901 bytes and 45 replies in both; replay `FAIL` with only the golden line (`07dcdfc6… != e62a9272…`), no VM ≠ interpreter line (VM 9.32 s, interpreter 54.96 s); `planStarIntent` uses `rq.target.pos`, `planFiniteIntent` uses `rq.target.id`, the index is only stored |
| V7 | `make -n ci-fast \| grep -c test_replay.py`; `make -n test \| grep -c test_replay.py`; `git show -s e70d0fdf` gates | 0; 1; #379's gates list `replay` but not `tools-test` |
| V8 | `diff` of the base and index-2 scratch logs | one line differs, at the single byte `1` → `2` |
| V9 | `grep -c earth_log tests/replays/compat-2.0/inputs.sha256`; `git ls-files \| xargs grep -l e62a9272`; `sed -n 398,416p tools/replay.py` | 0; only the two goldens; digest goldens are written as `"%s  %s.state.ndjson\n"` (no arch in the line) |
| V10 | the M2 test body run via `python3 -I` against `tools/test_replay.py`'s `plan_index_mismatches` on a scratch copy of `tests/replays/*.ndjson` with the index-2 fixture | corrected logs: `[]`; the stale-index and unknown-id controls: 1 each; the 7ai mutation: 6 occurrences, 6 mismatches (the six lines listed in M2), all `index 1, stars.json 2` |
| V11 | wall time (`perl Time::HiRes`) of `python3 tools/test_replay.py MapIndex`, the whole file, and `sh tools/test_sky_assets.sh; sh tools/test_lens_assets.sh` | 0.28 s; 7.37 s; 0.96 s (both rc 0) |
| V12 | `gh pr list --state open`; per PR, `gh pr diff N --allow-escape-sequences` Makefile hunk headers and name-only diffs | #412 `@@ -32`; #373 `@@ -10`, `-18`, `-225` (and touches `tests/replays/scene/m4_scene_session.record.txt`, not this case); #380 `@@ -251`; none touches `earth_log_voyage*`, `tools/test_replay.py` or Makefile 431–436 |
