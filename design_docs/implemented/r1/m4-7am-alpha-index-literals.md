# Hand-copied catalogue targets carry their real map index (7am)

**Status:** Implemented 2026-11-12 (mission iteration 88, PR #427; evaluation Sonnet 5.5 90 PASS, cross-vendor MiniMax M3 96 PASS; designer Opus 5.5). At landing the controller stripped trailing whitespace from the blank context lines of Appendix A's diff fence (AC12's `git diff --check`, the one finding both judges shared). The shipped code is `tools/test_replay.py`; the fence is now a record. Revision 2 (controller, narrow-refinement carve-out) answers design-quorum round 2 (BLOCKED 2/3, glm pass) with the reviewers' fixes as written; revision 1 answers design-quorum round 1 (BLOCKED 3/3; every objection carried a fix; see "Quorum log"). Measured at `origin/main` `c35efb57`. **Release:** r1. **Milestone:** none (suite hygiene, queue row **7am**).
**Priority:** low (clause 5 hygiene). Nothing is red today. One review capture is affected (`tools/earth_link_capture.gd`); its change is Mark's (OQ1). The rest is test and tool data, and the loop can land it.
**Implements:** row 7am of the charter (`design_docs/stapledon-mission.md`, Queue). The row comes from 7ai's follow-up F1 and two non-blocking judge findings ([`design_docs/implemented/r1/m4-7ai-earth-log-map-index.md`](../../implemented/r1/m4-7ai-earth-log-map-index.md), "Follow-ups"). It extends 7ai's map-index rule from recorded replay logs to hand-written targets in GDScript and Python. That rule says a plan target's `index` is the `data/starmap/stars.json` index of its `id`. No design-repo feature or physics-spec section applies: the sim never reads the index (V7).
**Depends on:** nothing. It builds on 7ai's `replay-map-index` (in `ci-fast`) and on 7x's `tools/script_gate_prereqs.sh` (in `script-gate-lint`, also in `ci-fast`).
**Estimated LOC:** about 125, none of it product code.
- 14 one-token literal edits in 10 files (M1; V23). `sim/stops_test.ail` is not edited (revision 1).
- `tools/test_replay.py`: +104/−4 (M2, M3; Appendix A). It is a listed harness (`tools/python-allowlist.txt`), so no Python pipeline step is added.
- `mk/script-gates.mk`: 2 changed lines (the `SG_PREREQS :=` list line and the pin; the comment rewrite is dropped, revision 2, glm). `tests/fixtures/script_gate/prereq_negative.mk.txt`: +1 line, no comment change (M4; V26: `2 files changed, 3 insertions(+), 2 deletions(-)`).
- The `Makefile` is not edited.

The measured revision-1 prototype is `/tmp/stap_i88_7am/proto_r1.patch` (288 lines, sha256 `91f597cb8be93396…`). It covers the 10 M1 files and `tools/test_replay.py`; the `tools/test_replay.py` part is `proto_r1_test_replay.patch` (150 lines, `6e9c41a6ad47da2a…`). Revision 0's prototype was `proto.patch` (266 lines, `0f440e28e170bdf5…`); it also edited `sim/stops_test.ail` and had no id decoding. Both prototypes were reverted from the tree. Appendix A reproduces the harness part verbatim, so the doc does not depend on `/tmp`.

## Game vision alignment

Scored against `../stapledons-design/vision/core-pillars.md` (pillars 1–6) and `physics/relativity-spec.md`. The `game-vision-designer` skill ran in feature-validation mode with no interview, because this run is unattended.

| Pillar | Relevance | Score | Notes |
|---|---|---:|---|
| Choices Are Final | 0 | 0 | No game logic changes. |
| The Game Doesn't Judge | 0 | 0 | No copy changes. |
| Time Has Emotional Weight | 0 | 0 | Nothing a player sees changes. The product map already resolves its targets through `GalaxyMap.plan_intent()`/`index_of()` (7ai V5). |
| The Ship Is Home | 0 | 0 | No scene or asset changes. |
| Grounded Strangeness | 0 | 0 | No content. If Mark says yes to OQ1, the review capture's map subtitle becomes the one the live map shows (`… · 4.32 ly`). That changes a review frame, not the game. |
| We Are Not Built For This | 0 | 0 | No crew or AI changes. |
| Hard sci-fi authenticity (spec) | 0 | 0 | No formula, shader, LUT or render. Only echoed index bytes move in sim output (V9). Physics gates 2 and 3 do not apply. |
| **Net** | | **0** | **ALIGNED (neutral): go.** This is test hygiene. No pillar scores at or below 0 in a way that harms the game; every 0 means "not touched". The one visible effect sits in a review capture and is held for Mark (OQ1). |

## Problem

1. **The wrong pair is wider than the row says (V1, V2).** The row names 10 files that hold `ALPHA = {"index": 1, "id": "CNS5:3627", …}`. In `stars.json`, CNS5:3627 (alpha Cen A) is index 2; index 1 is `HIP 71681` (alpha Cen B). A scan of every tracked `*.gd` and `*.py` for hand-written `(index, catalogue id)` pairs, in either key order, finds 16 pairs. 15 are wrong:
   - **ALPHA at 1 (should be 2):** 8 GDScript files (the row's list) and `tools/worlds_leak.py:29`.
   - **OFF_RAY `{"index": 2, "id": "CNS5:1676"}` (Sirius A, should be 9):** `tests/test_bridge_monitors.gd:16`, `tests/test_earth_history.gd:22`, `tests/test_earth_log_bridge.gd:15`, `tools/comms_station_capture.gd:27`. These are not in the row. They are the same copy-paste, and index 2 is alpha Cen A.
   - **`tools/exposure_solar_recovery.gd:22`:** a placeholder `{"id":"CNS5:3627","index":0,…}`, written in the other key order.
   - **`tools/ism_service_bench.gd:5`:** `{"index": 2, "id": "CNS5:1142"}` (Aldebaran, should be 3158).

   The only correct pair is `ui/transit_harness.gd:10`. The row's tenth file, `sim/stops_test.ail:92`, is AILANG (see 4). It carries one more wrong pair, which this row leaves alone.
2. **What reads the index (V3).** In product GDScript (everything outside `tests/`, `tools/` and `spike/`), only `ui/galaxy_map.gd` reads a plan target's index. It does so in four places:
   - `target_name()` (`:947`) and `subtitle_text()` (`:972`);
   - `_refresh_view()` (`:1020`), where `distance_ly` is filled only when `catalogue[i].id == id`;
   - `refresh()` (`:1059`).

   The test-side reader is `tests/display_audit.gd:142`. `CommsStation`, `BridgeScreens`, `CommsWaterfall`, `EarthStrip`, `EarthFeed` and `EarthHistory` do not read it. The sim stores the index (`sim/core.ail:302`) and echoes it (`sim/protocol.ail:272`), and nothing else (V7).
3. **The hypothesis was half right (V4, V5).** The row guessed that a capture might title the star `CNS5:3627` instead of "Alpha Centauri A". Measured through `GalaxyMap` on the real sim:
   - **The title does not change.** It reads `En route to CNS5:3627` at both index 1 and index 2, because the capture never calls `load_names()`. Without names, `display_name(2)` falls back to the id.
   - **The subtitle does change.** It reads `CNS5:3627` at index 1 and `CNS5:3627  ·  4.32 ly` at index 2. For OFF_RAY it reads `CNS5:1676` at index 2 and `CNS5:1676  ·  8.60 ly` at index 9.

   Of the sites, only `tools/earth_link_capture.gd` puts a `GalaxyMap` in a frame. Running its own flow headlessly, with the image saving removed (V5), shows its `a_outbound` map frame's subtitle moves from `[CNS5:3627]` to `[CNS5:3627  ·  4.32 ly]`, and the subtitle is visible. Frames b–e do not use ALPHA and are identical. That capture goes to `renders/earth_link/a_outbound_map.png` and `contact_sheet.png` (`make capture-earth-link`, GPU window, not in `make test`).
4. **AILANG literals are inert, and AILANG tests number their own catalogues (V2, V7, V11).** The `*.ail` scan finds 17 catalogue-id pairs in 6 files whose index differs from `stars.json` (for example `sim/trappist1_test.ail:100` `index: 0, id: "CNS5:3627"`). They are deliberate local numbering inside test-built catalogues. `sim/stops_test.ail:92–97` numbers acenA, Aldebaran, TRAPPIST-1, Barnard and Sol as 1, 2, 3, 4 and 0. Moving acenA alone to 2 would make it share local index 2 with Aldebaran (`:93`) and leave nothing at 1. The edit would also change nothing: `ailang test stops_test.ail` stays at 13/13, and `stopsVm` stays byte-identical on the VM and the interpreter (V11). Revision 1 therefore does not make it.
5. **The judges' two edges (V13, V14).**
   - Nothing checks that `ci-fast: replay-map-index` (`Makefile:479`) stays. Deleting it leaves `make ci-fast` green.
   - The 7ai control `test_the_7ai_index_fails` (`tools/test_replay.py:352–356`) hard-codes `"index":2` and `stars.json 2`. Suppose a catalogue reorder moves alpha Cen A and the logs are correctly re-recorded, 0f5a1175-style. The control then fails for no defect: `AssertionError: 0 not greater than 0` (V14).

## Goals and non-goals

**Goals.**
- Every hand-written catalogue target in tracked GDScript and Python carries its `stars.json` index. The one exception waits on Mark (OQ1).
- A fast-tier guard makes the class fail at its PR. Any tracked `*.gd`/`*.py` pair `"index": N, "id": "<stars.json id>"` (either order, any JSON spacing) whose N differs fails `make replay-map-index`. That target is already in `ci-fast`, and `make test` reaches it through `tools-test`. The guard has red controls.
- The `ci-fast: replay-map-index` edge is checked, and the 7ai control derives its indices from `stars.json`.
- Nothing visible changes in the loop's scope: every headless test result, fixture and capture input stays the same apart from the echoed index (V5, V6, V8, V9).

**Non-goals.**
- `tools/earth_link_capture.gd:16`. Fixing it moves a review capture (V5). It stays at index 1, as the guard's one pending entry, until Mark answers OQ1.
- Scanning AILANG. The sim never reads the index, and its tests use local catalogue numbering (Problem 4). `sim/stops_test.ail:92` (acenA at local index 1) is not edited either. Revision 1 takes the quorum's first option for it: drop the AILANG token. The GDScript copies started there (7ai V4), but M2 catches any new GDScript or Python copy, and the AILANG numbering is deliberate (F1).
- Recorded data: `tests/replays/*` (7ai's MapIndex already covers them) and `tests/fixtures/*.ndjson`. `protocol_27_inferred.*` is a frozen recording ("Do not regenerate", `tests/fixtures/README.md:3`) that plans Barnard at index 1 (`stars.json` 3); see F2.
- Markdown and design docs, which quote the wrong pair on purpose.
- The 7ah/7al `ci-fast` edges (F3).

## Design

### Per-site measurement and classification

Categories: **(i)** test-only or tool-only, no visible output changes; **(ii)** feeds a capture or golden and its output changes, so it is Mark's; **(iii)** feeds a capture or golden, and its output is shown unchanged.

| Site (line) | Literal(s) | Consumer of the index | Visible change at the stars.json index? | Cat. |
|---|---|---|---|---|
| `tests/test_bridge_monitors.gd:15,16` | ALPHA, OFF_RAY | sim only (`fly()`): `SimBridge`, `BridgeScreens` faces read `target.id` | no: `bridge-monitors: 19 passed, 0 failures` both ways, check lines identical (V6) | i |
| `tests/test_earth_beams.gd:15` | ALPHA | `GalaxyMap` on the real sim (`:148–154`); no check reads title or subtitle | no: `earth-beams: 29 passed, 0 failures` both ways, check lines identical (V6). The map's subtitle does change inside the test (V4), but nothing renders it | i |
| `tests/test_earth_history.gd:21,22` | ALPHA, OFF_RAY | sim, `CommsStation` | no: `comms-history: 37 passed, 0 failures` both ways (V6) | i |
| `tests/test_earth_log_bridge.gd:14,15` | ALPHA, OFF_RAY | sim | no: `comms-log-bridge: 9 passed, 0 failures` both ways (V6) | i |
| `tools/comms_golden.gd:23` | ALPHA (only in `frame_cases`; the waterfall cases do not plan) | sim, then `EarthStrip` (GPU golden G-CV-2, `make golden`) | no. Its `frame_cases` flow was run headless at index 1 and at index 2 (V24). The plan echoes 1.0 and 2.0 when ALPHA is planned (positive control). The view handed to `EarthStrip` is identical in full, because the voyage ends planning Sol (echo 0.0 in both runs). Both runs show the same `earth_log` hash, 123 records, the same homeward record (122), and the same CPU reference points (`want_sent`, `want_hit`, `want_then`) for the outbound and homebound cases. Pixels not rendered (GPU) | iii |
| `tools/comms_station_capture.gd:26,27` | ALPHA, OFF_RAY | sim, `CommsStation`, `BridgeScreens` faces (`make capture-comms-station`, `capture-comms-v2`) | no: in all 10 frames, the world without `journey.plan.target.index` hashes the same, and every visible label's text hashes the same, at (1, 2) and (2, 9) (V8). Pixels not rendered (GPU) | iii |
| `tools/earth_link_capture.gd:16` | ALPHA | **`GalaxyMap`** in the `a_outbound` map frame (`make capture-earth-link`) | **yes:** subtitle `[CNS5:3627]` → `[CNS5:3627  ·  4.32 ly]`, visible; title unchanged; frames b–e identical (V5) | **ii** |
| `tools/earth_rate_fixture.gd:10` | ALPHA | sim; writes `tests/fixtures/earth/earth_rates.json` | no: regenerated fixture byte-identical to the committed one and to each other (V6) | i |
| `sim/stops_test.ail:92` | acenA (local index 1) | sim tests (`ailang test`, `stopsVm` in `make strict`) | no: 13/13 both ways; `stopsVm` byte-identical, VM = interpreter (V11). **Not edited** (AILANG non-goal; revision 1) | i |
| `tools/worlds_leak.py:29` | ALPHA (+`star` row) | sim, 10k ticks; compares engines and presets with each other, with no pinned digest (V10) | no: the sim output changes in exactly 3 bytes (`1`→`2` at 54809, 58913, 63714); `audit()` passes on both; the VM digest moves `4cea2b92…` → `f466c843…` (V9). That digest is quoted only in R3-WORLDS evidence (V10) | i |
| `tools/exposure_solar_recovery.gd:22` (not in row) | `{"id":"CNS5:3627","index":0}` | none: overwritten at `:24` when the catalogue has the id, and never read afterwards; no make target runs the tool (V12) | no | i |
| `tools/ism_service_bench.gd:5` (not in row) | `{"index": 2, "id": "CNS5:1142"}` | sim (timing bench `make ism-bench`) | no visible output; the index is echoed only (V7). Bench run **UNMEASURED** (timing-sensitive on a loaded host); the sprint runs it (AC10) | i |

Totals: 9 sites in category (i), 2 in (iii), and 1 in (ii) (12 rows; `tools/earth_link_capture.gd` (OQ1) and `sim/stops_test.ail` (AILANG non-goal) are the untouched sites). They carry 15 wrong gd/py literal pairs plus one AILANG pair. M1 fixes 14 of the 15 in 10 files.

### M1. The literal fixes (loop scope, 14 tokens in 10 files; V23)

- ALPHA `"index": 1` → `2` in `tests/test_bridge_monitors.gd:15`, `tests/test_earth_beams.gd:15`, `tests/test_earth_history.gd:21`, `tests/test_earth_log_bridge.gd:14`, `tools/comms_golden.gd:23`, `tools/comms_station_capture.gd:26`, `tools/earth_rate_fixture.gd:10`, and `tools/worlds_leak.py:29`.
- OFF_RAY `"index": 2` → `9` in `tests/test_bridge_monitors.gd:16`, `tests/test_earth_history.gd:22`, `tests/test_earth_log_bridge.gd:15`, `tools/comms_station_capture.gd:27`.
- `tools/exposure_solar_recovery.gd:22` `"index":0` → `2`. `tools/ism_service_bench.gd:5` `"index": 2` → `3158`.
- The 10 files, by name: `tests/test_bridge_monitors.gd`, `tests/test_earth_beams.gd`, `tests/test_earth_history.gd`, `tests/test_earth_log_bridge.gd`, `tools/comms_golden.gd`, `tools/comms_station_capture.gd`, `tools/earth_rate_fixture.gd`, `tools/worlds_leak.py`, `tools/exposure_solar_recovery.gd`, `tools/ism_service_bench.gd`. The four OFF_RAY files are among the ALPHA files.
- **Not edited:** `tools/earth_link_capture.gd:16` (OQ1) and `sim/stops_test.ail:92` (AILANG non-goal; revision 1).

Nothing else on those lines changes. The trailing `pos` values already equal `stars.json` to six decimals (7ai V13).

### M2. Source guard in `MapIndex` (Appendix A)

The guard lives in `tools/test_replay.py` beside `plan_index_mismatches`, inside the `MapIndex` class. `make replay-map-index` (`python3 tools/test_replay.py MapIndex`, `Makefile:478`, in `ci-fast`) and `make tools-test` (in `make test`) already run that class, so no Makefile edit is needed.
- `SOURCE_PAIR` matches `"index" : N , "id" : "S"` and `"id" : "S" , "index" : N`, with any whitespace, newlines included, between the tokens. The id string may contain backslash escapes but not a raw newline.
- **Supported source-string forms (revision 1, gpt6-1-sol).** The captured id literal is decoded by `decode_id` before the catalogue lookup.
  - The double-quoted body may hold any character except `"`, `\` and a raw newline.
  - It may hold three escapes, which mean the same in GDScript, Python and JSON: `\"`, `\\` and `\uXXXX` (exactly four hex digits).
  - Any other escape (`\x3a`, `\n`, `\/`, `\U…`, a lone or trailing `\`) is rejected. The pair is then reported as bad, `<file>:<line> unsupported escape in id literal "<raw>"`, so it is never skipped as a synthetic id.
  - Single-quoted and raw strings and GDScript `&"…"`/`^"…"` literals are not matched (Risks).
- **Revision 2 (gpt6-1-sol, round 2), a requirement on the sprint; Appendix A's adjacency-only `SOURCE_PAIR` is the starting point, not the shipped form.** "Recognize index and id within the same dictionary regardless of intervening fields, using dictionary-aware source scanning rather than extending the regex across arbitrary braces." Concretely: for each `"index": N` literal, take its innermost enclosing `{…}`, keep only that dictionary's own level (nested dictionaries are skipped, so a `"pos": {…}` between the keys does not hide the pair and a nested `"id"` is never paired with the outer `"index"`), and look up a `"id": "<decoded>"` at that level. The controller's independent spike of exactly this (`/tmp/stap_i88_dictscan2.py`, V28) finds the same 16 pairs and 15 wrong ones at HEAD, 0 of them non-adjacent, and its positive control flags non-adjacent pairs in both key orders. "Add red controls for both key orders with an intervening pos field, including a nested dictionary, and verify that each wrong index fails make replay-map-index." That is a new test, `test_the_7am_intervening_fields_fail`, so MapIndex becomes 9 tests. "Re-run the inventory with an independent scan and record any additional sites before retaining the exhaustive coverage claim": done in V28, no additional site.
- `source_files()` is `git ls-files -z -- '*.gd' '*.py'`. The git pathspec `*` crosses `/`, so subdirectories are covered (V15). It **fails closed** outside a git work tree: `CalledProcessError`, so the test ERRORs (V16).
- `SOURCE_EXEMPT = ("tools/test_replay.py",)`: this file's own controls write wrong pairs (`:344`, `:353`; V17 shows them flagged without the exemption).
- `SOURCE_PENDING = ("tools/earth_link_capture.gd:16",)`: OQ1. The test requires every pending entry to **still** be a mismatch, so a stale entry fails and the list can only shrink.
- Ids not in `stars.json` are skipped: `Sol`, `port A (40 ly)`, `alpha Cen`, `synthetic-only`.
- Tests:
  - `test_source_literals_match_the_map`: no mismatch outside the pending list; no stale pending entry; and the known correct pair `ui/transit_harness.gd:10` is among those checked. That last condition is the scan's positive control.
  - `test_source_scan_covers_gd_and_py_in_subdirectories`: enumeration control.
  - `test_the_7am_literals_fail`: five in-memory texts covering both key orders, compact JSON, a pair spanning two lines (the bench's shape), and a correct pair plus `Sol`. It expects exactly four messages, by name, and 5 checked pairs.
  - `test_the_7am_escaped_ids_fail` (revision 1): three texts.
    - `{"index": <HIP 71681's index>, "id": "\u0043NS5:3627"}` must count as a checked catalogue pair and report `e.gd:1 CNS5:3627 index 1, stars.json 2`.
    - `{"index": <2>, "id": "CNS5\u003a3627"}` is checked and correct.
    - `{"index": <2>, "id": "CNS5\x3a3627"}` must be reported as an unsupported escape.

    The test asserts exactly the checked list `["e.gd:1", "q.py:1"]` and the two bad entries (V25).

Cost: `make replay-map-index` ran in 0.70 s wall for 8 tests on the loaded host (V18). Revision 0 took 0.25 s for 7 tests. It is headless, needs no GPU or AILANG, and reads 426 files.

### M3. The 7ai control derives its indices

`test_the_7ai_index_fails` reads `a = index of CNS5:3627` and `b = index of HIP 71681` from `stars.json`. It replaces `"index":a` with `"index":b` and expects the message `… index b, stars.json a`. This is the same defect it was written for, alpha Cen A at alpha Cen B's index, without today's numbers. Under a reorder with re-recorded logs, the old control fails and the new one passes (V14).

### M4. The `ci-fast: replay-map-index` edge is checked (precedent: 7ah/7al's edges, 7x's prerequisite pairs)

Add `ci-fast:replay-map-index` to `SG_PREREQS` in `mk/script-gates.mk:17`, and raise `SG_PREREQS_PAIRS` from 4 to 5 (`:20`). `script-gate-lint` is already in `ci-fast` and `make test`. Through `tools/script_gate_prereqs.sh`, it checks each pair in make's own database (`make -pq`), so an edge declared on a separate rule line counts. The pin is a ratchet: removing the pair from the list fails on the count.

`tests/fixtures/script_gate/prereq_negative.mk.txt` gains one line, `ci-fast: replay-map-index`. The negative control passes `$(SG_PREREQS)` to the fixture and expects exactly 2 refusals; without the line it would see a third. Measured (V13): green with the pair; `ci-fast lost its prerequisite replay-map-index (…)` and make rc 2 when the `Makefile:479` line is deleted; the pin message and rc 2 when the pair is dropped from the list.

**Why there and not a new target.** A new target needs its own `ci-fast` edge, which nothing would check (the same regress). The shared pinned list stops that regress at one pinned number that a reviewer sees move. The list's comment is not rewritten (revision 2, glm: the 2-line count is then true; V26 measured the applied form).

## Files touched and Do-not-touch

- **Touched:** the 10 files of M1 (V23); `tools/test_replay.py` (M2, M3); `mk/script-gates.mk:17` and `:20` (M4; list line and pin, 2 lines; the comment is not rewritten, revision 2); `tests/fixtures/script_gate/prereq_negative.mk.txt` (+1 line). No new file, so no `.uid` and no allowlist row. Landing adds a changelog fragment and the charter and README status rows.
- **Do not touch:**
  - `tools/earth_link_capture.gd` (OQ1);
  - `Makefile`;
  - `data/starmap/*`;
  - `tests/replays/*` and every golden;
  - `tests/fixtures/*.ndjson`;
  - `ui/`, `demos/`, `bridge/`, `main.gd`;
  - every `*.ail`, `sim/stops_test.ail` included (revision 1);
  - `tools/script_gate_prereqs.sh` and `tools/script_gate_lint.sh`.

## Conflict surface

Measured with `git fetch` and `git diff <merge-base> origin/<branch>`, not `gh pr diff` (V19).

| PR | Head | Touches a 7am file? | Adds a pair line in `*.gd`/`*.py`? |
|---|---|---|---|
| #412 `feat/captain-command` (Mark's, attended; `refs/pull/412/head` = branch head; it contains `7add91e4`, the attended checkout's HEAD) | `3926f4f3` | `Makefile` only, `@@ -34,0 +35 @@` (include list). 7am does not edit the Makefile | 0 |
| #380 `feat/r2-kerr-table-preflight` | `68e4ca6d` | `Makefile` only (lines 13–25, 228–260). Not edited by 7am | 0 |
| #373 `feat/r2-kerr` | `e37b3579` | `Makefile` only (same region). Not edited by 7am | 0 |

The control in the same call is `d6f2889a`, which adds 3 such lines. **Verdict: no overlap, and no PR would turn the new guard red on merge.** Every merge order is clean.

## Acceptance criteria

All criteria are headless and run in the fix clone. Use `export PATH=$PWD/runtime/bin:$PATH` (v0.56.1), or `AILANG=../stapledons-godot/runtime/bin/ailang` as measured, and run `make import` once. Expected values were measured on the prototype or on in-tree mutations that were then reverted (V-rows).

| # | Criterion | Command | Expected |
|---|---|---|---|
| 1 | RED first: guard in, literals not yet fixed | `python3 -W ignore tools/test_replay.py MapIndex; echo rc=$?` | `Ran 9 tests` (revision 2 adds the intervening-field test; sprint-measured), `FAILED (failures=1)` in `test_source_literals_match_the_map`, `First list contains 14 additional elements.` (the 14 non-pending mismatches of V2); `rc=1` |
| 2 | GREEN after M1 | `make replay-map-index; echo rc=$?` | `Ran 9 tests` (revision 2 adds the intervening-field test; sprint-measured), `OK`, `rc=0` |
| 3 | Only the pending pair is left | `python3 -I -c "import sys; sys.path.insert(0,'tools'); import test_replay as t; m=t.MapIndex(); c,b=t.source_index_pairs(m.sources(), m.stars()); print(len(c), b)"` | `16 ['tools/earth_link_capture.gd:16 CNS5:3627 index 1, stars.json 2']` |
| 4 | RED: a site reverted | `sed -i.bak 's/^const ALPHA := {"index": 2,/const ALPHA := {"index": 1,/' tests/test_earth_beams.gd; make replay-map-index; echo rc=$?; mv tests/test_earth_beams.gd.bak tests/test_earth_beams.gd` | `tests/test_earth_beams.gd:15 CNS5:3627 index 1, stars.json 2`, make rc 2 |
| 5 | RED: a stale pending entry | `sed -i.bak 's/^const ALPHA := {"index": 1,/const ALPHA := {"index": 2,/' tools/earth_link_capture.gd; make replay-map-index; echo rc=$?; mv tools/earth_link_capture.gd.bak tools/earth_link_capture.gd` | `['tools/earth_link_capture.gd:16'] != []`, make rc 2 |
| 6 | The edge is checked | `make -s script-gate-lint 2>&1 \| tail -1; grep -v '^ci-fast: replay-map-index$' Makefile > /tmp/7am_mk && cp Makefile /tmp/7am_mk.orig && cp /tmp/7am_mk Makefile; make -s script-gate-lint 2>&1 \| tail -2; cp /tmp/7am_mk.orig Makefile; git diff --quiet Makefile && echo restored` | first line `script-gate-prereqs: ok (5 pairs hold in Makefile: … ci-fast:replay-map-index)`; then `script-gate-prereqs: ci-fast lost its prerequisite replay-map-index (…)` and `make: *** [script-gate-lint] Error 1`; then `restored` |
| 7 | Behaviour identical: the four headless tests | `make earth-beams-test comms-log-bridge-test comms-history-test bridge-monitors-test; echo rc=$?` | `earth-beams: 29 passed, 0 failures` (the summary from its log), `comms-log-bridge: 9 passed`, `comms-history: 37 passed`, `bridge-monitors: 19 passed` (all `0 failures`; counts may grow with main), `rc=0` |
| 8 | The Earth-rate fixture is unchanged | `make earth-rate-fixture; git diff --exit-code tests/fixtures/earth/earth_rates.json; echo rc=$?` | `earth-rate-fixture: 2 rows -> res://tests/fixtures/earth/earth_rates.json`, `rc=0` |
| 9 | No AILANG file is edited (revision 1) | `git diff --name-only origin/main -- '*.ail' \| wc -l; git diff --name-only origin/main -- '*.gd' \| wc -l` | `0`; then `9` (positive control: the 9 edited GDScript files are seen; V23) |
| 10 | The bench and worlds-leak still pass (long: about 10–20 min on the loaded Studio) | `make ism-bench worlds-leak; echo rc=$?` | `worlds-leak: four presets × two engines byte-identical; schema/import audit passed (…)`, each `worlds-leak vm/<preset>: … sha256 f466c8433b75375d…`; `ism-service-bench:` line and `.passes == true`; `rc=0`. A timing-only bench failure on a loaded host is re-run once on a quieter host; it is not a 7am regression (the bench's index is echo-only, V7) |
| 11 | The 7ai control survives a catalogue reorder | the AC11 block below | `M6 orig rc=1`, `AssertionError: 0 not greater than 0`, `Ran 2 tests`, `FAILED (failures=1)`; `M6 new rc=0`, `Ran 2 tests`, `OK` (both via the two-method selection; a full-class run in the non-git scratch dir ERRORs per V16, so it is not used) |
| 12 | Hygiene and scope | `make python-guard uid-guard script-gate-lint; git diff --check origin/main; git diff --name-only origin/main` | `python-guard: ok`, `uid-guard: ok`, `script-gate-lint: ok …`; diff-check silent; exactly the 10 M1 files (`tests/test_bridge_monitors.gd`, `tests/test_earth_beams.gd`, `tests/test_earth_history.gd`, `tests/test_earth_log_bridge.gd`, `tools/comms_golden.gd`, `tools/comms_station_capture.gd`, `tools/earth_rate_fixture.gd`, `tools/worlds_leak.py`, `tools/exposure_solar_recovery.gd`, `tools/ism_service_bench.gd`), `tools/test_replay.py`, `mk/script-gates.mk`, `tests/fixtures/script_gate/prereq_negative.mk.txt` = 13 files, plus landing files under `changelogs/`, `design_docs/`, `.ailang/state/` |
| 13 | Fast tier green on GitHub (Ubuntu) | push, then `gh pr checks <PR>` | the `make ci-fast` check `pass`; the job log contains `Ran 9 tests` (revision 2 adds the intervening-field test; sprint-measured) / `OK` from `replay-map-index`, and `5 pairs hold` from `script-gate-lint` |

AC11 (outside the table so the `|` is literal). Run it from the fix clone with `S=$(mktemp -d)`:

```sh
mkdir -p $S/tools $S/tests/replays $S/data/starmap && cp tests/replays/*.ndjson $S/tests/replays/
python3 -I - "$S" <<'EOF'
import json, sys, glob
S = sys.argv[1]; d = json.load(open("data/starmap/stars.json")); st = d["stars"]; st[1], st[2] = st[2], st[1]
json.dump(d, open(S + "/data/starmap/stars.json", "w"))
for f in glob.glob(S + "/tests/replays/*.ndjson"):
    t = open(f).read(); open(f, "w").write(t.replace('"index":2,"id":"CNS5:3627"', '"index":@,"id":"CNS5:3627"').replace('"index":1,"id":"HIP 71681"', '"index":2,"id":"HIP 71681"').replace('"index":@,', '"index":1,'))
EOF
for v in orig new; do git show $([ $v = orig ] && echo origin/main || echo HEAD):tools/test_replay.py > $S/tools/test_replay.py
  (cd $S && python3 -W ignore tools/test_replay.py MapIndex.test_committed_logs_match_the_map MapIndex.test_the_7ai_index_fails > $v.log 2>&1; echo "M6 $v rc=$?"; grep AssertionError $v.log); done; rm -rf $S
```

## Test plan: each new check and the mutation that kills it (all run on the revision-1 prototype, V20, V25)

Every mutation below was re-run against revision 1 (8 tests). The unmutated prototype gives `Ran 8 tests`, `OK`, rc 0.

| Check | Mutation (on the prototype tree, reverted after) | Result (revision 1) |
|---|---|---|
| `test_source_literals_match_the_map` | M1: `tests/test_earth_beams.gd` ALPHA back to 1 | rc 1, `Ran 8 tests`, 1 failing test: `['tests/test_earth_beams.gd:15 CNS5:3627 index 1, stars.json 2'] != []` |
| reverse key order in `SOURCE_PAIR` | M2: the `\|"id"…"index"` alternative deleted | rc 1, 1 failing (`test_the_7am_literals_fail`): `z.gd:1 CNS5:3627 index 3, stars.json 2` missing |
| whitespace tolerance | M3: every `\s*` in `SOURCE_PAIR` → one space | rc 1, 3 failing: `test_source_literals_match_the_map` (the pending entry is no longer seen), `test_the_7am_escaped_ids_fail` (`[] != ['e.gd:1', 'q.py:1']`), `test_the_7am_literals_fail` |
| enumeration covers subdirectories | M4: `source_files()` keeps only top-level files | rc 1, 2 failing: `'ui/transit_harness.gd' not found in ['main.gd']`, plus the stale pending entry |
| stale pending entry | M5: `tools/earth_link_capture.gd` fixed, entry kept | rc 1, 1 failing: `['tools/earth_link_capture.gd:16'] != []` |
| 7ai control is index-free | M6: `stars.json` entries 1 and 2 swapped, logs re-recorded (AC11) | old control rc 1 (`0 not greater than 0`); revision 1 rc 0 (`Ran 2 tests`, `OK`; the two-method selection, re-measured revision 2, V14) |
| exemption is needed (justification, not a kill) | M7: `SOURCE_EXEMPT = ()` | rc 1, 2 failing: `tools/test_replay.py:406 CNS5:1676 index 8, stars.json 9` (and the 7ai mutation line) flagged; `'tools/test_replay.py' unexpectedly found` |
| intervening fields (revision 2, gpt) | M12: the scan reverted to adjacency-only matching (Appendix A's `SOURCE_PAIR`) | sprint-measured: `test_the_7am_intervening_fields_fail` fails for `{"index": 1, "pos": {"x": 1}, "id": "CNS5:3627"}` and `{"id": "CNS5:3627", "pos": {}, "index": 1}` (both key orders, nested dictionary between); the spike's own control already flags both (V28) |
| id decoding (revision 1) | M10: `sid = decode_id(raw)` → `sid = raw` (raw spelling compared) | rc 1, 1 failing: `test_the_7am_escaped_ids_fail`, `Lists differ: [] != ['e.gd:1', 'q.py:1']` |
| unsupported escapes rejected (revision 1) | M11: `decode_id`'s `return None` → `return raw` (an unsupported escape treated as a literal id) | rc 1, 1 failing: `test_the_7am_escaped_ids_fail`, the `u.gd:1 unsupported escape in id literal "CNS5\x3a3627"` entry missing |
| pending list is needed (justification) | M8: `SOURCE_PENDING = ()` | rc 1, `['tools/earth_link_capture.gd:16 CNS5:3627 index 1, stars.json 2'] != []` |
| fails closed without git | M9: the prototype run from a non-git copy | `ERROR: test_source_literals_match_the_map`, `CalledProcessError … returned non-zero exit status 128` |
| edge pair | E1: `ci-fast: replay-map-index` line deleted | rc 2, `ci-fast lost its prerequisite replay-map-index (…)` |
| edge pin | E2: the pair removed from `SG_PREREQS`, pin left at 5 | rc 2, `SG_PREREQS holds 4 pairs (4 distinct) but SG_PREREQS_PAIRS is 5: …` |

## Sub-milestones and estimates

| # | What | LOC | Depends | Order |
|---|---|---:|---|---|
| T1 | M2 + M3 in `tools/test_replay.py`, M4 in `mk/script-gates.mk` and the fixture: AC1 red, AC6 green | ~110 | none | 1 (red first) |
| M1 | the 14 literal tokens in 10 files: AC2–AC5 | 14 | T1 | 2 |
| V | AC7–AC12 (AC10 long); push a draft PR, AC13 | 0 | M1 | 3 |

About 25 minutes of headless runs (most of it AC10). No GPU.

## Risks and mitigations

- **The `comms_golden` pixels were not measured** (GPU, not run by rule). The view its strip draws, and its CPU reference points, were measured identical at index 1 and index 2 (V24). Its view classes do not read the index (V3). The nightly `rig/golden` runs it on main. If G-CV goes red after landing, revert the one token in `tools/comms_golden.gd`; do not re-record.
- **A false positive on a non-target dictionary** that pairs a catalogue id with an unrelated `"index"` (a list position, for example). None exists today: all 16 hits are plan targets (V2). The fix would be an explicit `SOURCE_EXEMPT` row with a comment, never a looser pattern.
- **A literal written another way** is out of the guard's reach: `{"id": id, "index": i}` with variables, a `Dictionary` built field by field, single-quoted or raw strings, GDScript `&"…"` or `^"…"`, or AILANG. None of these forms occurs today; all 16 hits are double-quoted (V2). The product map derives indices itself (`plan_intent`, `index_of`). 7ai's MapIndex still covers recorded logs. F1 tracks AILANG.
- **`git ls-files` on the runner:** `actions/checkout` gives a work tree. Outside one, the test errors instead of passing (M9).
- **OQ1 left unanswered:** the pending entry stays, and the guard keeps checking that it is the only wrong pair.

## Open questions for the user

- **OQ1 (Mark; attended).** Should `tools/earth_link_capture.gd`'s ALPHA move to alpha Cen A's real map index (2)? Its `a_outbound` map review frame would then show the subtitle `CNS5:3627  ·  4.32 ly` (as the live map does) instead of `CNS5:3627`. The title stays `En route to CNS5:3627`, and frames b–e are unchanged (V5). Answer **yes** or **no**. **Default if unanswered: no.** The capture stays as reviewed, and the guard's pending entry stays. A "yes" is one token plus deleting the pending entry, followed by `make capture-earth-link` for Mark to look at.

## Follow-ups (new findings, not scope)

- **F1.** AILANG test catalogues use local numbering for real `stars.json` ids: 17 pairs in 6 files (V2). This is inert today (V7). If a GDScript copy of one appears, M2 catches it. An AILANG scan would need an opt-out for local catalogues.
- **F2.** `tests/fixtures/protocol_27_inferred.{input,expected}.ndjson` plans Barnard at index 1 (`stars.json` 3). It is a frozen recording for `make ism-compat`, so it is not changed here. This is a provenance question: the fixture claims to be "a real … session", but the map would not write index 1.
- **F3.** 7ah's and 7al's `ci-fast` edges (`similar-main-guard`, `session-minor-guard` and their controls) could join `SG_PREREQS` the same way. That is four pairs and a pin of 9 (row 7ao's area).

## Deliverables

- M1: the 14 tokens in 10 files. M2: the source guard (with id decoding) and its four tests. M3: the derived 7ai control. M4: the edge pair, the pin and the fixture line.
- Evidence for AC1–AC13 in `.ailang/state/sprints/sprint_7am.json`.

## Verification log

Clone `/Users/voightkampff/dev/sunholo-data/stapledons-godot-iter88-7am` at `c35efb57`, AILANG v0.56.1 (`../stapledons-godot/runtime/bin/ailang`), Godot 4.7.2 headless. Scratch files are in `/tmp/stap_i88_7am/`. Every in-tree mutation was reverted, and the tree ends clean (`git status --porcelain` empty).

| # | Claim | Command | Observed |
|---|---|---|---|
| V1 | The row's 10 sites hold the ALPHA pair | `git grep -n '"index": 1, "id": "CNS5:3627"'` (plus the AILANG form) | 8 `.gd` lines and `tools/worlds_leak.py:29` (plus `design_docs` quotes); `sim/stops_test.ail:92` `index: 1, id: "CNS5:3627"` |
| V2 | 16 catalogue pairs in tracked `*.gd`/`*.py`, 15 wrong; 17 wrong AILANG pairs in 6 files | spike `/tmp/stap_i88_7am/scan.py .` (both key orders, ids checked against `stars.json`), then the prototype's `source_index_pairs` | `files 426 checked 16 bad 15`, the 15 lines of Problem 1; `ok pairs: ['ui/transit_harness.gd:10']` (positive). AILANG: `core_ism_test` 4, `similar_test` 2, `solar_departure_test` 3, `stops_test` 5, `sim/tools/solar_departure_probe` 1, `trappist1_test` 2 |
| V2b | `stars.json` indices | `python3 -I -c "… stars.json …"` | 0 `Gaia DR3 5853498713190525696`, 1 `HIP 71681`, 2 `CNS5:3627`; `CNS5:1676` 9; `CNS5:1142` 3158; Barnard `Gaia DR3 4472832130942575872` 3; `Sol` absent |
| V3 | Only `ui/galaxy_map.gd` reads a plan target's index in product code | `git ls-files '*.gd' \| grep -vE '^(tests\|tools\|spike)/' \| xargs grep -lE '"index"\|\.index\b\|target\.index\|plan\.target\.index'` | `demos/camera_director.gd` (level index), `demos/solar_departure.gd` (writes), `main.gd` (writes `:352`, `:877`), `ui/galaxy_map.gd` (reads `:951,976,1020,1059`), `ui/transit_harness.gd` (writes). The comms and monitor classes (`ui/comms_station.gd`, `bridge_screens.gd`, `comms_waterfall.gd`, `earth_strip.gd`, `earth_feed.gd`, `earth_history.gd`) are absent |
| V4 | `GalaxyMap` title and subtitle at each index | `AILANG_BIN=… godot --headless --path . --script /tmp/stap_i88_7am/probe_map.gd` (GalaxyMap + real sim, `load_catalogue` only) | `ALPHA@1 committed: _title=En route to CNS5:3627 \| _subtitle=CNS5:3627`; `ALPHA@2 committed: _title=En route to CNS5:3627 \| _subtitle=CNS5:3627  ·  4.32 ly`; `OFF_RAY@2 … _subtitle=CNS5:1676`; `OFF_RAY@9 … _subtitle=CNS5:1676  ·  8.60 ly`; `names.json` has `CNS5:3627` → "Alpha Centauri A", applied only by `load_names()` (`main.gd:325,427`) |
| V5 | `earth_link_capture`'s map frame moves | `earth_link_capture.gd` with its image block replaced by a label print (perl; `elc_probe1.gd`, and `elc_probe2.gd` = index 2), each `godot --headless --audio-driver Dummy --path . --script …` | idx 1: `elc-probe a_outbound title=[En route to CNS5:3627] subtitle=[CNS5:3627] subtitle_visible=true`; idx 2: `… subtitle=[CNS5:3627  ·  4.32 ly] subtitle_visible=true`; b_top, c_replan, d_stale, e_home identical; both `5 frames, 0 failures`, rc 0. `git check-ignore -v renders/x.png` → `.gitignore:2:renders/` |
| V6 | The four headless tests and the Earth-rate fixture are unchanged | `/tmp/stap_i88_7am/run_sites.sh base`, then the same after `sed` ALPHA 1→2 and OFF_RAY 2→9 in the 8 files (`git diff`: 8 files, 12 lines) | both: `earth-beams: 29 passed, 0 failures`, `comms-log-bridge: 9 passed`, `comms-history: 37 passed`, `bridge-monitors: 19 passed`, rc 0 each; check lines identical; `earth-rate-fixture: 2 rows`, `git diff --stat` empty at base, and `cmp base.earth_rates.json fixed.earth_rates.json` → identical |
| V7 | The sim only stores and echoes the index | `git ls-files 'sim/*.ail' \| grep -v '_test.ail$' \| xargs grep -nE '\.index\b\|index:'` | `sim/core.ail:302` `{ index: rq.target.index, … }` (copy), `sim/protocol.ail:272` `targetObj` (echo), `:604` (parse); `navigation.ail` indices are body `Facts` (positive hits; no branch on `target.index`) |
| V8 | `comms_station_capture` inputs and labels unchanged | `comms_station_capture.gd` with `get_image()` → `_dump(label, view, tree)` and `frame_post_draw` removed (`csc_probe1/2.gd`, (1,2) vs (2,9)), `--out=res://.godot/tmp/cscN` | all 10 frames (home, faces_home, away, faces_away, waiting, homeward, faces_homeward, frame_outbound, frame_homebound, frame_homebound_week): equal `view_sans_index_sha` and `labels_sha` in both runs (e.g. home `fc91399e…`/`3d34215c…`); `target_index` differs (1.0 vs 2.0; waiting 2.0 vs 9.0; positive). The shas differ from frame to frame (positive). `10 failures` = blank frames in headless, as expected |
| V9 | The sim output differs only at the index echo | `worlds_leak.requests('stapledon',10000)` with index 1 and 2 (`cmp -l` of inputs: `299 61 62`), each piped to `ailang run --quiet --caps IO --package-dir sim --entry main --strict-bytecode sim/ship.ail` | outputs both 1,514,071 bytes; `cmp -l` 3 lines: `54809 61 62`, `58913 61 62`, `63714 61 62`; sha256 `4cea2b92…` (= the harness's own `worlds-leak vm/*` digest, positive) → `f466c843…`; `audit()` ok on both |
| V10 | No check pins the worlds-leak digest | `git grep -c 4cea2b9282c7`; `sed -n 100,125p tools/worlds_leak.py` | only `.ailang/state/evidence/R3-WORLDS/20261103/leak-interrupted.txt`, `sprint_R3-WORLDS.json`, `design_docs/planned/r3/worlds-execution-report.md` (positive hits); the harness asserts `data == reference` across runs |
| V11 | Editing `stops_test.ail` would change nothing (why revision 1 drops it) | `ailang test stops_test.ail` and `stopsVm` (strict VM; interpreter) at base and with `acenA` index 2 | `13 tests: 13 passed, 0 failed` both; check lines identical; `stopsVm` base VM = fixed VM = fixed interpreter (`cmp`), `stops-ok 24643.227462158196 107061.51570942107 …` |
| V12 | `exposure_solar_recovery`'s literal is dead | `grep -n destination tools/exposure_solar_recovery.gd`; `git grep -n 'exposure_solar_recovery\|ism_service_bench' -- Makefile mk tools tests sim` (excluding the files themselves) | only `:22` (literal) and `:24` (overwrite); no make target names it, while `mk/ism.mk:36` names `ism_service_bench.gd` (positive) |
| V13 | The edge is checked through `SG_PREREQS` | in tree: `SG_PREREQS += ci-fast:replay-map-index`, pin 5, fixture +1; `make -s script-gate-lint`; then the `Makefile:479` line deleted; then the pair dropped (reverted) | `script-gate-prereqs: ok (5 pairs hold …)`, rc 0; `ci-fast lost its prerequisite replay-map-index (ci-fast: stellar-protocol-test deps …)`, rc 2; `SG_PREREQS holds 4 pairs (4 distinct) but SG_PREREQS_PAIRS is 5 …`, rc 2. Without the fixture line, `make script-gate-lint SG_PREREQS="… ci-fast:replay-map-index" SG_PREREQS_PAIRS=5` fails `the prerequisite control … was not refused by name` |
| V14 | The 7ai control hard-codes today's index and breaks on a reorder | `sed -n 352,356p tools/test_replay.py`; AC11 re-run verbatim at `6256e108` by the controller (revision 2), `origin/main`'s `tools/test_replay.py` vs that file with `proto_r1_test_replay.patch` applied | `'"index":2,"id":"CNS5:3627"'`, `"… index 1, stars.json 2"`; `M6 orig rc=1`, `AssertionError: 0 not greater than 0`, `Ran 2 tests in 0.127s`, `FAILED (failures=1)`; `M6 new rc=0`, `Ran 2 tests in 0.143s`, `OK` (both via the two-method selection; a full-class revision-1 run in the non-git scratch dir ERRORs per V16, so it was not used). Revision 1 quoted `Ran 4 tests` here; that was wrong (kimi, round 2) |
| V15 | The scan covers subdirectories | `source_files()` | 426 files incl. `ui/transit_harness.gd`, `tests/test_earth_beams.gd`, `tools/worlds_leak.py`; mutant M4 sees only `['main.gd']` |
| V16 | Fails closed without git | the prototype in `/tmp/stap_i88_7am/m6` (no `.git`) | `ERROR: test_source_literals_match_the_map`, `CalledProcessError: … returned non-zero exit status 128` |
| V17 | The harness's own controls hold wrong pairs | M7 (`SOURCE_EXEMPT = ()`) | `tools/test_replay.py:381 CNS5:1676 index 8, stars.json 9` and the 7ai mutation line |
| V18 | Prototype green and cheap | prototype applied: `time make -s replay-map-index` | revision 1: `Ran 8 tests`, `OK`, 0.70 s wall (revision 0: `Ran 7 tests in 0.154s`, 0.254 s). At base `python3 tools/test_replay.py MapIndex` prints 22 `ResourceWarning`s already (pre-existing `logs()`), `Ran 4 tests`, `OK` |
| V19 | Conflict surface | `git fetch origin feat/captain-command feat/r2-kerr-table-preflight feat/r2-kerr`; per branch `git diff --name-only $(git merge-base origin/main origin/$b) origin/$b -- <the 13 touched files, plus `tools/earth_link_capture.gd`, `ui/transit_harness.gd` and `Makefile` (V29 spells them out)>`; added pair lines `git diff … -- '*.gd' '*.py' \| grep '^+' \| grep -cE '<pair regex>'`; control `git show d6f2889a -- '*.gd' \| grep '^+' \| grep -cE …` | each branch lists only `Makefile` (positive: the instrument sees a touched file); added pair lines 0, 0, 0; control 3. `git ls-remote origin refs/pull/412/head` = `3926f4f3…` = branch head; `git merge-base --is-ancestor 7add91e4 origin/feat/captain-command` → yes |
| V20 | The test-plan mutations, re-run on revision 1 | `/tmp/stap_i88_7am/r1mut.*.log` (M1–M5, M7, M8, M10, M11 in tree; M6 and M9 in `/tmp/stap_i88_7am/m6`, no `.git`); E1/E2 with the M4 edits applied in tree | M1, M2, M5, M10, M11: rc 1 with 1 failing test each. M3: 3 failing. M4 and M7: 2 failing. M8: 1 failing. Every run says `Ran 8 tests`. M6: revision 1 rc 0 (`Ran 2 tests`, `OK`), `origin/main`'s control rc 1 `0 not greater than 0`, `Ran 2 tests` (corrected revision 2: the earlier `Ran 4 tests` quote was wrong; V14). M9: `ERROR: test_source_literals_match_the_map`, `CalledProcessError … exit status 128`. E0 `script-gate-prereqs: ok (5 pairs …)` rc 0; E1 `ci-fast lost its prerequisite replay-map-index` rc 2; E2 `SG_PREREQS holds 4 pairs (4 distinct) but SG_PREREQS_PAIRS is 5` rc 2. Unmutated: `base rc=0`, `Ran 8 tests` |
| V22 | AC1 and AC3 as written | revision 1: guard only (`proto_r1_test_replay.patch`), then MapIndex; then M1 applied, then the AC3 one-liner and MapIndex; reverted | `First list contains 14 additional elements.`, `Ran 8 tests`, `FAILED (failures=1)` (so no tree literal trips the unsupported-escape rule); then `16 ['tools/earth_link_capture.gd:16 CNS5:3627 index 1, stars.json 2']` and `Ran 8 tests`, `OK` |
| V23 | M1 diff file count | `git apply --exclude=tools/test_replay.py proto.patch && git diff --name-only \| wc -l` (revision 0, reverted); then `git apply --exclude=tools/test_replay.py --exclude=sim/stops_test.ail proto.patch && git diff --name-only \| wc -l; git diff -U0 \| grep -c '^+[^+]'` (revision 1, reverted) | revision 0: `11` files (`sim/stops_test.ail` and the 10 below), not 12 as revision 0's text said (controller C1). Revision 1: `10` files, `14` changed lines: `tests/test_bridge_monitors.gd`, `tests/test_earth_beams.gd`, `tests/test_earth_history.gd`, `tests/test_earth_log_bridge.gd`, `tools/comms_golden.gd`, `tools/comms_station_capture.gd`, `tools/earth_rate_fixture.gd`, `tools/exposure_solar_recovery.gd`, `tools/ism_service_bench.gd`, `tools/worlds_leak.py` |
| V24 | `comms_golden`'s G-CV-2 inputs are identical | `/tmp/stap_i88_7am/cg_probe.gd`: `frame_cases`' sim flow (`new_game(7, "free_nav", …)`, `fly(ALPHA)`, `0.004` ticks to arrival, `fly(SOL)`, 120 ticks) and its `EarthStrip` setup, verbatim, without `grab()`. Run as `godot --headless --audio-driver Dummy --path . --script … -- 1` and `-- 2` | `planned_echo=1.0` / `2.0` (positive). Both runs: `ok=true ticks=154 records=123 homeward=122 echoed_target_index=0.0 view_sans_index_sha=e33487da57bacb14… earth_log_sha=ad503dc4abca5f1e…`; outbound k=1 `want_sent=(26.33256, 120.0) want_hit=(120.2456, 26.08696) want_then=(25.38346, 119.9992)`; homebound k=122 `want_sent=(19.92152, 120.0) want_hit=(64.2206, 75.7009) want_then=(19.38077, 31.30948)`; `labels=[]` (the strip draws its tags; it has no Label children); rc 0 |
| V25 | Escaped ids are decoded; unsupported escapes fail; the mutations kill the control | revision 1 MapIndex; M10 and M11 (V20) | `test_the_7am_escaped_ids_fail` passes at base (`Ran 8 tests`, `OK`); M10 → `Lists differ: [] != ['e.gd:1', 'q.py:1']`; M11 → the `unsupported escape` entry missing; rc 1 both |
| V21 | `earth_link_capture` and `comms_golden` are GPU targets outside `make test` | `sed -n 100,110p mk/earth-link.mk`; `sed -n 80,84p mk/earth-link.mk` | `capture-earth-link` "GPU window; not in make test"; `comms-golden` "(GPU window)", `golden: comms-golden` |
| V26 | Appendix B as shipped (2-line form, fixture +1, no comment edits) | controller, revision 2: `sed` the `SG_PREREQS :=` line to append `ci-fast:replay-map-index`, pin 4 → 5, `echo 'ci-fast: replay-map-index' >>` the fixture; `git diff --stat` / `--numstat`; `make -s script-gate-lint`; then the pair dropped with the pin left at 5; reverted (`git status --porcelain` empty) | `2 files changed, 3 insertions(+), 2 deletions(-)`; numstat `2 2 mk/script-gates.mk`, `1 0 …prereq_negative.mk.txt`; `script-gate-prereqs: ok (5 pairs hold in Makefile: … ci-fast:replay-map-index)`, rc 0; then `SG_PREREQS holds 4 pairs (4 distinct) but SG_PREREQS_PAIRS is 5 …`, `Error 1` |
| V27 | `make test` reaches `replay-map-index`'s class through `tools-test` (glm, round 2) | `grep -nE '^tools-test:' -A2 Makefile`; `make -pq test \| grep -E '^test:'` / `grep -n '^test:' Makefile` | `Makefile:290 tools-test:` runs `python3 tools/test_replay.py` (all classes, MapIndex included); `Makefile:57 test: … tools-test …` |
| V28 | Dictionary-aware independent inventory (gpt, round 2) | controller spike `python3 -I /tmp/stap_i88_dictscan2.py` in the clone (innermost enclosing `{…}` of each `"index": N`, that level only, `"id"` anywhere at that level); positive control: the same script in a scratch git repo holding `{"index": 1, "pos": {"x": 1}, "id": "CNS5:3627"}` and `{"id": "CNS5:1676", "name": "x", "index": 9}` | tree: `"index" occurrences 47; dicts with a catalogue id 16; wrong 15; non-adjacent catalogue pairs 0`, the same 15 lines as Problem 1; control: `c.gd:1 CNS5:3627 index 1, stars.json 2 [NON-ADJACENT]`, `c.gd:2 … [NON-ADJACENT] (correct)`, `non-adjacent catalogue pairs 2` |
| V29 | Open-PR set and conflict pathspec (kimi, round 2) | `gh pr list --state open --limit 100` (and `git ls-remote origin 'refs/pull/*/head' \| wc -l` = 415 refs, open and closed); `git fetch origin pull/<n>/head`; per PR `git diff --name-only $(git merge-base origin/main pr/<n>) pr/<n> -- tests/test_bridge_monitors.gd tests/test_earth_beams.gd tests/test_earth_history.gd tests/test_earth_log_bridge.gd tools/comms_golden.gd tools/comms_station_capture.gd tools/earth_rate_fixture.gd tools/worlds_leak.py tools/exposure_solar_recovery.gd tools/ism_service_bench.gd tools/test_replay.py mk/script-gates.mk tests/fixtures/script_gate/prereq_negative.mk.txt tools/earth_link_capture.gd ui/transit_harness.gd Makefile` (zsh: the list expanded with `${=P}`; an unsplit first attempt returned nothing for every PR and was discarded as an instrument failure) | open PRs: exactly #412 `feat/captain-command`, #380 `feat/r2-kerr-table-preflight`, #373 `feat/r2-kerr`; each lists only `Makefile` (not edited by 7am); `tools/test_replay.py`, `mk/script-gates.mk` and the fixture: in the pathspec, no overlap on any head; control: the PRs change 48, 86 and 57 files in total; added pair lines 0, 0, 0 |

## Quorum log

**Round 1** (revision 0, `6d9d2b5b`): three seats, all **BLOCKED**, cost **$0.4280**. Every objection carried a concrete fix. Revision 1 applies them as follows, and the controller verified C1 and C2 at `6d9d2b5b`.

| Seat | Verdict | Objection | Fix applied in revision 1 |
|---|---|---|---|
| oc-glm-5-3 | BLOCKED | M1 named 11 distinct files, not 12 (C1). Moving `sim/stops_test.ail` acenA to 2 makes it share local index 2 with Aldebaran (C2) | **Counts:** option (a), restated after the next fix, so M1 is 14 tokens in 10 files. Applied in Estimated LOC, M1, Files touched, AC12 (the 10 M1 files by name + 3 = 13 files, plus landing files), V23 (the paths by name), and a totals line with one unit. **stops_test:** the first option, **drop the AILANG token**. M1 no longer edits `sim/stops_test.ail`; Problem 4 and Non-goals say why; AC9 now checks that no `*.ail` is edited |
| oc-kimi-k3 | BLOCKED | (a) the same counts and AC12 list; (b) the totals line; (c) a V-row for the M1 diff file count; and `comms_golden` was labelled (iii) without the probe used for `comms_station_capture` | (a) as above. (b) `Totals: 9 sites in category (i), 2 in (iii), and 1 in (ii) (12 rows; …)`, naming both untouched sites. (c) **V23** run on the prototype: revision 0 → 11 files; revision 1 → 10 files, 14 lines. **comms_golden:** the probe was cheap and headless, so it was **run** (V24) and the label (iii) **kept**. Its strip's full input view and its CPU reference points are identical at index 1 and index 2 |
| gpt6-1-sol | BLOCKED | The guard silently missed wrong targets whose id uses a string escape: `SOURCE_PAIR` accepts escapes, but the raw spelling was compared | **Applied verbatim in Appendix A.** `decode_id` decodes `\"`, `\\` and `\uXXXX` before the lookup, and rejects any other escape as bad (never treated as a synthetic id). The control `test_the_7am_escaped_ids_fail` requires `{"index": 1, "id": "\u0043NS5:3627"}` to count as a checked catalogue pair and to report its mismatch. M10 (decoding removed) and M11 (unsupported escape treated as literal) each fail it (V25). M2 now lists the supported source-string forms |

Re-run on revision 1: the full MapIndex suite (`Ran 8 tests`, `OK`) and M1–M11, E1–E2. All results are in V20 and the Test plan.

**Round 2** (revision 1, `6256e108`): same seats, **BLOCKED 2/3**, cost **$0.4750**. oc-glm-5-3 **pass**; oc-kimi-k3 and gpt6-1-sol **reject**. No reviewer disputes the direction, and every objection carries a reviewer-written fix. Revision 2 is the controller's narrow-refinement carve-out: the reviewers' fixes as written, plus the controller's measurements behind them (V14, V26–V29). There is no round 3.

| Seat | Verdict | Objection | Fix applied in revision 2 |
|---|---|---|---|
| oc-glm-5-3 | pass (non-blocking) | The shipped M4 diff was never applied as written (comment rewrite, `:=` form); `make test` reaching the guard via `tools-test` was asserted | The comment rewrite is **dropped** ("or drop the comment rewrite so 2 is true"), and the fixture gets the line only. **V26** applies Appendix B as now written: 2 + 1 lines, lint green, pin red. **V27** shows `make test` → `tools-test` → `python3 tools/test_replay.py` |
| oc-kimi-k3 | reject | AC11/M6 was quoted as `Ran 4 tests, OK`, impossible for a two-method selection; the conflict pathspec "the 16 7am paths" was undefined and the open-PR set not enumerated | AC11 re-run verbatim by the controller: `Ran 2 tests` both ways (V14, the AC11 row, the M6 test-plan row and V20 corrected). **V29** enumerates the open PRs and spells out the pathspec, with `tools/test_replay.py`, `mk/script-gates.mk` and the fixture included: no overlap except `Makefile`, which 7am does not edit |
| gpt6-1-sol | reject | M2 misses a wrong target when another field sits between `"index"` and `"id"` | M2 now **requires** dictionary-aware scanning ("regardless of intervening fields … rather than extending the regex across arbitrary braces"), with red controls for both key orders and a nested dictionary between (test-plan M12, sprint-measured). The independent inventory was re-run (**V28**): no additional site, 0 non-adjacent pairs at HEAD, and the control flags both shapes |

## Appendix A. `tools/test_replay.py` prototype, revision 1 (diff against `c35efb57`; `proto_r1_test_replay.patch`, 150 lines, sha256 `6e9c41a6ad47da2a…`)

```diff
@@ -7,6 +7,7 @@ dropped reply and a stale digest must each fail. Run: python3 tools/test_replay.
 import hashlib
 import json
 import os
+import re
 import subprocess
 import sys
 import tempfile
@@ -324,6 +325,67 @@ def plan_index_mismatches(log_texts, stars):
     return bad


+# 7am: a catalogue target written by hand in GDScript or Python carries its stars.json index, as a
+# recorded log's must (GalaxyMap.target_name()/subtitle_text() trust the index only when
+# catalogue[index].id == id). Both key orders, JSON spacing or none. Ids not in stars.json (Sol, the
+# design row, synthetic ports) are not catalogue targets and are skipped. Id literals are decoded first
+# (decode_id: \" \\ and \uXXXX); any other escape fails rather than passing as a synthetic id. This file is exempt: its
+# controls write wrong pairs on purpose. AILANG sources are out of scope: the sim never reads the
+# index (sim/core.ail stores it, sim/protocol.ail echoes it) and its tests number local catalogues.
+SOURCE_PAIR = re.compile(r'"index"\s*:\s*(-?\d+)\s*,\s*"id"\s*:\s*"((?:[^"\\\n]|\\.)*)"'
+                         r'|"id"\s*:\s*"((?:[^"\\\n]|\\.)*)"\s*,\s*"index"\s*:\s*(-?\d+)')
+SOURCE_EXEMPT = ("tools/test_replay.py",)
+# Pairs left wrong on purpose until Mark rules (7am OQ1): fixing them moves a review capture. Each must
+# still be wrong (a stale entry fails), so the list only shrinks.
+SOURCE_PENDING = ("tools/earth_link_capture.gd:16",)
+
+
+def source_files():
+    """Tracked *.gd and *.py files, in any directory (git pathspec * crosses /)."""
+    out = subprocess.run(["git", "-C", ROOT, "ls-files", "-z", "--", "*.gd", "*.py"], capture_output=True, check=True).stdout
+    return sorted(f for f in out.decode().split("\0") if f and f not in SOURCE_EXEMPT)
+
+
+def decode_id(raw):
+    """The id a GDScript or Python string literal spells. Supported escapes, which mean the same in
+    GDScript, Python and JSON: \\" \\\\ and \\uXXXX (four hex digits). Any other escape returns None."""
+    out, i = [], 0
+    while i < len(raw):
+        if raw[i] != "\\":
+            out.append(raw[i])
+            i += 1
+        elif raw[i + 1:i + 2] in ('"', "\\"):
+            out.append(raw[i + 1])
+            i += 2
+        elif raw[i + 1:i + 2] == "u" and re.fullmatch(r"[0-9A-Fa-f]{4}", raw[i + 2:i + 6]):
+            out.append(chr(int(raw[i + 2:i + 6], 16)))
+            i += 6
+        else:
+            return None
+    return "".join(out)
+
+
+def source_index_pairs(file_texts, stars):
+    """(checked, bad): every hand-written (index, catalogue id) pair, and those whose index is not the id's.
+    An id literal with an unsupported escape is reported as bad, never skipped as a synthetic id."""
+    index = {s["id"]: i for i, s in enumerate(stars)}
+    checked, bad = [], []
+    for name, text in file_texts:
+        for m in SOURCE_PAIR.finditer(text):
+            i, raw = (m.group(1), m.group(2)) if m.group(1) is not None else (m.group(4), m.group(3))
+            where = "%s:%d" % (name, text.count("\n", 0, m.start()) + 1)
+            sid = decode_id(raw)
+            if sid is None:
+                bad.append('%s unsupported escape in id literal "%s"' % (where, raw))
+                continue
+            if sid not in index:
+                continue
+            checked.append(where)
+            if int(i) != index[sid]:
+                bad.append("%s %s index %s, stars.json %d" % (where, sid, i, index[sid]))
+    return checked, bad
+
+
 class MapIndex(unittest.TestCase):
     """A committed log's plan targets point at the shipped map: index == stars.json index of the id
     (companions round 1: Sirius B moving ahead of Sirius A changed Sirius A's index 8 -> 9)."""
@@ -347,13 +409,65 @@ class MapIndex(unittest.TestCase):
     def test_an_unknown_id_fails(self):
         logs = [(n, t.replace('"id":"CNS5:1676"', '"id":"CNS5:999999"')) for n, t in self.logs()]
         self.assertEqual(len(plan_index_mismatches(logs, self.stars())), 1)
-    def test_the_7ai_index_fails(self):  # control: alpha Cen A (CNS5:3627) at HIP 71681's index 1, as earth_log_voyage had it until 7ai
+    def test_the_7ai_index_fails(self):  # control: alpha Cen A (CNS5:3627) at HIP 71681's index, as earth_log_voyage had it until 7ai
+        stars = self.stars()
+        a, b = self.at(stars, "CNS5:3627"), self.at(stars, "HIP 71681")
+        good, wrong = '"index":%d,"id":"CNS5:3627"' % a, '"index":%d,"id":"CNS5:3627"' % b
         logs = self.logs()
-        n = sum(t.count('"index":2,"id":"CNS5:3627"') for _, t in logs)
-        bad = plan_index_mismatches([(f, t.replace('"index":2,"id":"CNS5:3627"', '"index":1,"id":"CNS5:3627"')) for f, t in logs], self.stars())
+        n = sum(t.count(good) for _, t in logs)
+        bad = plan_index_mismatches([(f, t.replace(good, wrong)) for f, t in logs], stars)
         self.assertGreater(n, 0)
         self.assertEqual(len(bad), n)
-        self.assertIn("earth_log_voyage.ndjson:3 plan CNS5:3627 index 1, stars.json 2", bad)
+        self.assertIn("earth_log_voyage.ndjson:3 plan CNS5:3627 index %d, stars.json %d" % (b, a), bad)
+
+    @staticmethod
+    def at(stars, sid):
+        return [s["id"] for s in stars].index(sid)
+
+    def sources(self):
+        out = []
+        for f in source_files():
+            with open(os.path.join(ROOT, f), encoding="utf-8") as h:
+                out.append((f, h.read()))
+        return out
+
+    def test_source_literals_match_the_map(self):  # 7am
+        checked, bad = source_index_pairs(self.sources(), self.stars())
+        self.assertEqual([b for b in bad if b.split(" ")[0] not in SOURCE_PENDING], [])
+        self.assertEqual([p for p in SOURCE_PENDING if p not in [b.split(" ")[0] for b in bad]], [])
+        self.assertIn("ui/transit_harness.gd:10", checked)  # known positive: the scan sees a real pair
+
+    def test_source_scan_covers_gd_and_py_in_subdirectories(self):  # 7am: enumeration control
+        files = source_files()
+        for f in ("ui/transit_harness.gd", "tools/worlds_leak.py", "tests/test_earth_beams.gd"):
+            self.assertIn(f, files)
+        self.assertNotIn("tools/test_replay.py", files)
+
+    def test_the_7am_literals_fail(self):  # control: each 7am shape, at a wrong index, is caught by name
+        stars = self.stars()
+        a, b, s9 = self.at(stars, "CNS5:3627"), self.at(stars, "HIP 71681"), self.at(stars, "CNS5:1676")
+        texts = [("x.gd", 'const ALPHA := {"index": %d, "id": "CNS5:3627", "pos": {}}\n' % b),
+                 ("y.py", 'pass\nt = {"index":%d,"id":"CNS5:1676","pos":{}}\n' % (s9 - 7)),
+                 ("z.gd", 'var d:={"id":"CNS5:3627","index":%d,"x":0.}\n' % (a + 1)),
+                 ("w.gd", 'const P := {"k": "plan", "target": {"index": 2, "id": "CNS5:1142",\n\t"pos": {}}}\n'),
+                 ("ok.gd", 'const A := {"index": %d, "id": "CNS5:3627"}\nconst S := {"index": 0, "id": "Sol"}\n' % a)]
+        checked, bad = source_index_pairs(texts, stars)
+        self.assertEqual(bad, ["x.gd:1 CNS5:3627 index %d, stars.json %d" % (b, a),
+                               "y.py:2 CNS5:1676 index %d, stars.json %d" % (s9 - 7, s9),
+                               "z.gd:1 CNS5:3627 index %d, stars.json %d" % (a + 1, a),
+                               "w.gd:1 CNS5:1142 index 2, stars.json %d" % self.at(stars, "CNS5:1142")])
+        self.assertEqual(len(checked), 5)  # Sol is not a catalogue id
+
+    def test_the_7am_escaped_ids_fail(self):  # control: an escaped catalogue id is decoded and checked; an unsupported escape fails
+        stars = self.stars()
+        a, b = self.at(stars, "CNS5:3627"), self.at(stars, "HIP 71681")
+        texts = [("e.gd", 'const E := {"index": %d, "id": "\\u0043NS5:3627"}\n' % b),
+                 ("q.py", 'Q = {"index": %d, "id": "CNS5\\u003a3627"}\n' % a),
+                 ("u.gd", 'const U := {"index": %d, "id": "CNS5\\x3a3627"}\n' % a)]
+        checked, bad = source_index_pairs(texts, stars)
+        self.assertEqual(checked, ["e.gd:1", "q.py:1"])
+        self.assertEqual(bad, ["e.gd:1 CNS5:3627 index %d, stars.json %d" % (b, a),
+                               'u.gd:1 unsupported escape in id literal "CNS5\\x3a3627"'])


 class AiSession(unittest.TestCase):
```

## Appendix B. `mk/script-gates.mk` and fixture (M4; revision 2, measured as applied in V26)

Two lines change in `mk/script-gates.mk`; the comment above them is unchanged:

```make
SG_PREREQS := constellation-test:starmap-assets planets-test:planet-assets planet-textures-check:planet-assets ship-console-test:ship-baseline ci-fast:replay-map-index
SG_PREREQS_PAIRS := 5
```

`tests/fixtures/script_gate/prereq_negative.mk.txt` gets exactly this line appended, and nothing else:

```make
ci-fast: replay-map-index
```
