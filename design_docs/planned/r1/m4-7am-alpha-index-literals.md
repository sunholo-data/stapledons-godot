# Hand-copied catalogue targets carry their real map index (7am)

**Status:** Planned 2026-11-12 (mission iteration 88, designer Opus 5.5). Measured at `origin/main` `c35efb57`. **Release:** r1. **Milestone:** none (suite hygiene, queue row **7am**).
**Priority:** low (clause 5 hygiene). Nothing is red today. One review capture is affected (`tools/earth_link_capture.gd`); its change is Mark's (OQ1). The rest is test and tool data, and the loop can land it.
**Implements:** row 7am of the charter (`design_docs/stapledon-mission.md`, Queue). The row comes from 7ai's follow-up F1 and two non-blocking judge findings ([`design_docs/implemented/r1/m4-7ai-earth-log-map-index.md`](../../implemented/r1/m4-7ai-earth-log-map-index.md), "Follow-ups"). It extends 7ai's map-index rule from recorded replay logs to hand-written targets in GDScript and Python. That rule says a plan target's `index` is the `data/starmap/stars.json` index of its `id`. No design-repo feature or physics-spec section applies: the sim never reads the index (V7).
**Depends on:** nothing. It builds on 7ai's `replay-map-index` (in `ci-fast`) and on 7x's `tools/script_gate_prereqs.sh` (in `script-gate-lint`, also in `ci-fast`).
**Estimated LOC:** about 105, none of it product code.
- 15 one-token literal edits in 12 files (M1).
- `tools/test_replay.py`: +80/−5 (M2, M3; Appendix A). It is a listed harness (`tools/python-allowlist.txt`), so no Python pipeline step is added.
- `mk/script-gates.mk`: 2 changed lines. `tests/fixtures/script_gate/prereq_negative.mk.txt`: +1 line (M4).
- The `Makefile` is not edited.

The measured prototype is `/tmp/stap_i88_7am/proto.patch` (266 lines, sha256 `0f440e28e170bdf5…`; its `tools/test_replay.py` part is `proto_test_replay.patch`, `aa98906c1614c3f3…`). It was reverted from the tree. Appendix A reproduces the harness part verbatim, so the doc does not depend on `/tmp`.

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

   The only correct pair is `ui/transit_harness.gd:10`. The row's tenth file, `sim/stops_test.ail:92`, is AILANG (see 4).
2. **What reads the index (V3).** In product GDScript (everything outside `tests/`, `tools/` and `spike/`), only `ui/galaxy_map.gd` reads a plan target's index. It does so in four places:
   - `target_name()` (`:947`) and `subtitle_text()` (`:972`);
   - `_refresh_view()` (`:1020`), where `distance_ly` is filled only when `catalogue[i].id == id`;
   - `refresh()` (`:1059`).

   The test-side reader is `tests/display_audit.gd:142`. `CommsStation`, `BridgeScreens`, `CommsWaterfall`, `EarthStrip`, `EarthFeed` and `EarthHistory` do not read it. The sim stores the index (`sim/core.ail:302`) and echoes it (`sim/protocol.ail:272`), and nothing else (V7).
3. **The hypothesis was half right (V4, V5).** The row guessed that a capture might title the star `CNS5:3627` instead of "Alpha Centauri A". Measured through `GalaxyMap` on the real sim:
   - **The title does not change.** It reads `En route to CNS5:3627` at both index 1 and index 2, because the capture never calls `load_names()`. Without names, `display_name(2)` falls back to the id.
   - **The subtitle does change.** It reads `CNS5:3627` at index 1 and `CNS5:3627  ·  4.32 ly` at index 2. For OFF_RAY it reads `CNS5:1676` at index 2 and `CNS5:1676  ·  8.60 ly` at index 9.

   Of the sites, only `tools/earth_link_capture.gd` puts a `GalaxyMap` in a frame. Running its own flow headlessly, with the image saving removed (V5), shows its `a_outbound` map frame's subtitle moves from `[CNS5:3627]` to `[CNS5:3627  ·  4.32 ly]`, and the subtitle is visible. Frames b–e do not use ALPHA and are identical. That capture goes to `renders/earth_link/a_outbound_map.png` and `contact_sheet.png` (`make capture-earth-link`, GPU window, not in `make test`).
4. **AILANG literals are inert, and AILANG tests number their own catalogues (V2, V7, V11).** The `*.ail` scan finds 17 catalogue-id pairs in 6 files whose index differs from `stars.json` (for example `sim/trappist1_test.ail:100` `index: 0, id: "CNS5:3627"`). They are deliberate local numbering inside test-built catalogues. `sim/stops_test.ail:92–97` numbers acenA, Aldebaran, TRAPPIST-1, Barnard and Sol as 1, 2, 3, 4 and 0. Changing `acenA` to 2 leaves `ailang test stops_test.ail` at 13/13, and `stopsVm` is byte-identical on the VM and the interpreter (V11).
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
- Scanning AILANG. The sim never reads the index, and its tests use local catalogue numbering (Problem 4). The `stops_test.ail` acenA literal is corrected anyway (M1), because it is where the GDScript copy came from (7ai V4). Its siblings keep their local numbers (F1).
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
| `tools/comms_golden.gd:23` | ALPHA | sim, then `CommsWaterfall` and `EarthStrip` (GPU golden G-CV, `make golden`) | inputs no: neither class reads the index (V3), and the sim changes only the echo bytes (V9). **Pixels UNMEASURED** (GPU; not run by rule) | iii |
| `tools/comms_station_capture.gd:26,27` | ALPHA, OFF_RAY | sim, `CommsStation`, `BridgeScreens` faces (`make capture-comms-station`, `capture-comms-v2`) | no: in all 10 frames, the world without `journey.plan.target.index` hashes the same, and every visible label's text hashes the same, at (1, 2) and (2, 9) (V8). Pixels not rendered (GPU) | iii |
| `tools/earth_link_capture.gd:16` | ALPHA | **`GalaxyMap`** in the `a_outbound` map frame (`make capture-earth-link`) | **yes:** subtitle `[CNS5:3627]` → `[CNS5:3627  ·  4.32 ly]`, visible; title unchanged; frames b–e identical (V5) | **ii** |
| `tools/earth_rate_fixture.gd:10` | ALPHA | sim; writes `tests/fixtures/earth/earth_rates.json` | no: regenerated fixture byte-identical to the committed one and to each other (V6) | i |
| `sim/stops_test.ail:92` | acenA | sim tests (`ailang test`, `stopsVm` in `make strict`) | no: 13/13 both ways; `stopsVm` byte-identical, VM = interpreter (V11) | i |
| `tools/worlds_leak.py:29` | ALPHA (+`star` row) | sim, 10k ticks; compares engines and presets with each other, with no pinned digest (V10) | no: the sim output changes in exactly 3 bytes (`1`→`2` at 54809, 58913, 63714); `audit()` passes on both; the VM digest moves `4cea2b92…` → `f466c843…` (V9). That digest is quoted only in R3-WORLDS evidence (V10) | i |
| `tools/exposure_solar_recovery.gd:22` (not in row) | `{"id":"CNS5:3627","index":0}` | none: overwritten at `:24` when the catalogue has the id, and never read afterwards; no make target runs the tool (V12) | no | i |
| `tools/ism_service_bench.gd:5` (not in row) | `{"index": 2, "id": "CNS5:1142"}` | sim (timing bench `make ism-bench`) | no visible output; the index is echoed only (V7). Bench run **UNMEASURED** (timing-sensitive on a loaded host); the sprint runs it (AC10) | i |

Totals: 11 sites in category (i), 2 in (iii), and 1 in (ii) (`tools/earth_link_capture.gd`).

### M1. The literal fixes (loop scope, 15 tokens in 12 files)

- ALPHA `"index": 1` → `2` in `tests/test_bridge_monitors.gd:15`, `tests/test_earth_beams.gd:15`, `tests/test_earth_history.gd:21`, `tests/test_earth_log_bridge.gd:14`, `tools/comms_golden.gd:23`, `tools/comms_station_capture.gd:26`, `tools/earth_rate_fixture.gd:10`, and `tools/worlds_leak.py:29`.
- OFF_RAY `"index": 2` → `9` in `tests/test_bridge_monitors.gd:16`, `tests/test_earth_history.gd:22`, `tests/test_earth_log_bridge.gd:15`, `tools/comms_station_capture.gd:27`.
- `tools/exposure_solar_recovery.gd:22` `"index":0` → `2`. `tools/ism_service_bench.gd:5` `"index": 2` → `3158`.
- `sim/stops_test.ail:92` `acenA()` `index: 1` → `2`. Its siblings keep their local numbers (F1).
- **Not edited:** `tools/earth_link_capture.gd:16` (OQ1).

Nothing else on those lines changes. The trailing `pos` values already equal `stars.json` to six decimals (7ai V13).

### M2. Source guard in `MapIndex` (Appendix A)

The guard lives in `tools/test_replay.py` beside `plan_index_mismatches`, inside the `MapIndex` class. `make replay-map-index` (`python3 tools/test_replay.py MapIndex`, `Makefile:478`, in `ci-fast`) and `make tools-test` (in `make test`) already run that class, so no Makefile edit is needed.
- `SOURCE_PAIR` matches `"index" : N , "id" : "S"` and `"id" : "S" , "index" : N`, with any whitespace, newlines included, between the tokens. The id string allows escapes but not a raw newline.
- `source_files()` is `git ls-files -z -- '*.gd' '*.py'`. The git pathspec `*` crosses `/`, so subdirectories are covered (V15). It **fails closed** outside a git work tree: `CalledProcessError`, so the test ERRORs (V16).
- `SOURCE_EXEMPT = ("tools/test_replay.py",)`: this file's own controls write wrong pairs (`:344`, `:353`; V17 shows them flagged without the exemption).
- `SOURCE_PENDING = ("tools/earth_link_capture.gd:16",)`: OQ1. The test requires every pending entry to **still** be a mismatch, so a stale entry fails and the list can only shrink.
- Ids not in `stars.json` are skipped: `Sol`, `port A (40 ly)`, `alpha Cen`, `synthetic-only`.
- Tests:
  - `test_source_literals_match_the_map`: no mismatch outside the pending list; no stale pending entry; and the known correct pair `ui/transit_harness.gd:10` is among those checked. That last condition is the scan's positive control.
  - `test_source_scan_covers_gd_and_py_in_subdirectories`: enumeration control.
  - `test_the_7am_literals_fail`: five in-memory texts covering both key orders, compact JSON, a pair spanning two lines (the bench's shape), and a correct pair plus `Sol`. It expects exactly four messages, by name, and 5 checked pairs.

Cost: `make replay-map-index` ran in 0.25 s wall for 7 tests (V18). It is headless, needs no GPU or AILANG, and reads 426 files.

### M3. The 7ai control derives its indices

`test_the_7ai_index_fails` reads `a = index of CNS5:3627` and `b = index of HIP 71681` from `stars.json`. It replaces `"index":a` with `"index":b` and expects the message `… index b, stars.json a`. This is the same defect it was written for, alpha Cen A at alpha Cen B's index, without today's numbers. Under a reorder with re-recorded logs, the old control fails and the new one passes (V14).

### M4. The `ci-fast: replay-map-index` edge is checked (precedent: 7ah/7al's edges, 7x's prerequisite pairs)

Add `ci-fast:replay-map-index` to `SG_PREREQS` in `mk/script-gates.mk:17`, and raise `SG_PREREQS_PAIRS` from 4 to 5 (`:20`). `script-gate-lint` is already in `ci-fast` and `make test`. Through `tools/script_gate_prereqs.sh`, it checks each pair in make's own database (`make -pq`), so an edge declared on a separate rule line counts. The pin is a ratchet: removing the pair from the list fails on the count.

`tests/fixtures/script_gate/prereq_negative.mk.txt` gains one line, `ci-fast: replay-map-index`. The negative control passes `$(SG_PREREQS)` to the fixture and expects exactly 2 refusals; without the line it would see a third. Measured (V13): green with the pair; `ci-fast lost its prerequisite replay-map-index (…)` and make rc 2 when the `Makefile:479` line is deleted; the pin message and rc 2 when the pair is dropped from the list.

**Why there and not a new target.** A new target needs its own `ci-fast` edge, which nothing would check (the same regress). The shared pinned list stops that regress at one pinned number that a reviewer sees move. The list's comment widens from "asset prerequisites" to "prerequisites a row depends on (assets, fast-tier edges)".

## Files touched and Do-not-touch

- **Touched:** the 12 files of M1; `tools/test_replay.py` (M2, M3); `mk/script-gates.mk:15–20` (M4; comment, list, pin); `tests/fixtures/script_gate/prereq_negative.mk.txt` (+1 line). No new file, so no `.uid` and no allowlist row. Landing adds a changelog fragment and the charter and README status rows.
- **Do not touch:**
  - `tools/earth_link_capture.gd` (OQ1);
  - `Makefile`;
  - `data/starmap/*`;
  - `tests/replays/*` and every golden;
  - `tests/fixtures/*.ndjson`;
  - `ui/`, `demos/`, `bridge/`, `main.gd`;
  - every other `*.ail`;
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
| 1 | RED first: guard in, literals not yet fixed | `python3 -W ignore tools/test_replay.py MapIndex; echo rc=$?` | `Ran 7 tests`, `FAILED (failures=1)` in `test_source_literals_match_the_map`, listing exactly the 14 non-pending mismatches of V2; `rc=1` |
| 2 | GREEN after M1 | `make replay-map-index; echo rc=$?` | `Ran 7 tests`, `OK`, `rc=0` |
| 3 | Only the pending pair is left | `python3 -I -c "import sys; sys.path.insert(0,'tools'); import test_replay as t; m=t.MapIndex(); c,b=t.source_index_pairs(m.sources(), m.stars()); print(len(c), b)"` | `16 ['tools/earth_link_capture.gd:16 CNS5:3627 index 1, stars.json 2']` |
| 4 | RED: a site reverted | `sed -i.bak 's/^const ALPHA := {"index": 2,/const ALPHA := {"index": 1,/' tests/test_earth_beams.gd; make replay-map-index; echo rc=$?; mv tests/test_earth_beams.gd.bak tests/test_earth_beams.gd` | `tests/test_earth_beams.gd:15 CNS5:3627 index 1, stars.json 2`, make rc 2 |
| 5 | RED: a stale pending entry | `sed -i.bak 's/^const ALPHA := {"index": 1,/const ALPHA := {"index": 2,/' tools/earth_link_capture.gd; make replay-map-index; echo rc=$?; mv tools/earth_link_capture.gd.bak tools/earth_link_capture.gd` | `['tools/earth_link_capture.gd:16'] != []`, make rc 2 |
| 6 | The edge is checked | `make -s script-gate-lint 2>&1 \| tail -1; grep -v '^ci-fast: replay-map-index$' Makefile > /tmp/7am_mk && cp Makefile /tmp/7am_mk.orig && cp /tmp/7am_mk Makefile; make -s script-gate-lint 2>&1 \| tail -2; cp /tmp/7am_mk.orig Makefile; git diff --quiet Makefile && echo restored` | first line `script-gate-prereqs: ok (5 pairs hold in Makefile: … ci-fast:replay-map-index)`; then `script-gate-prereqs: ci-fast lost its prerequisite replay-map-index (…)` and `make: *** [script-gate-lint] Error 1`; then `restored` |
| 7 | Behaviour identical: the four headless tests | `make earth-beams-test comms-log-bridge-test comms-history-test bridge-monitors-test; echo rc=$?` | `earth-beams: 29 passed, 0 failures` (the summary from its log), `comms-log-bridge: 9 passed`, `comms-history: 37 passed`, `bridge-monitors: 19 passed` (all `0 failures`; counts may grow with main), `rc=0` |
| 8 | The Earth-rate fixture is unchanged | `make earth-rate-fixture; git diff --exit-code tests/fixtures/earth/earth_rates.json; echo rc=$?` | `earth-rate-fixture: 2 rows -> res://tests/fixtures/earth/earth_rates.json`, `rc=0` |
| 9 | stops_test is unchanged | `cd sim && ailang test stops_test.ail \| tail -1; cd .. && make strict 2>&1 \| grep 'strict stopsVm'` | `13 tests: 13 passed, 0 failed, 0 skipped (…)`; `strict stopsVm (D-54): VM stops-ok 24643.227462158196 … \| interpreter stops-ok 24643.227462158196 …` (identical) |
| 10 | The bench and worlds-leak still pass (long: about 10–20 min on the loaded Studio) | `make ism-bench worlds-leak; echo rc=$?` | `worlds-leak: four presets × two engines byte-identical; schema/import audit passed (…)`, each `worlds-leak vm/<preset>: … sha256 f466c8433b75375d…`; `ism-service-bench:` line and `.passes == true`; `rc=0`. A timing-only bench failure on a loaded host is re-run once on a quieter host; it is not a 7am regression (the bench's index is echo-only, V7) |
| 11 | The 7ai control survives a catalogue reorder | the AC11 block below | `M6 orig rc=1` with `AssertionError: 0 not greater than 0`; `M6 new rc=0` |
| 12 | Hygiene and scope | `make python-guard uid-guard script-gate-lint; git diff --check origin/main; git diff --name-only origin/main` | `python-guard: ok`, `uid-guard: ok`, `script-gate-lint: ok …`; diff-check silent; exactly the 12 M1 files, `tools/test_replay.py`, `mk/script-gates.mk`, `tests/fixtures/script_gate/prereq_negative.mk.txt`, plus landing files under `changelogs/`, `design_docs/`, `.ailang/state/` |
| 13 | Fast tier green on GitHub (Ubuntu) | push, then `gh pr checks <PR>` | the `make ci-fast` check `pass`; the job log contains `Ran 7 tests` / `OK` from `replay-map-index`, and `5 pairs hold` from `script-gate-lint` |

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

## Test plan: each new check and the mutation that kills it (all run, V20)

| Check | Mutation (on the prototype tree, reverted after) | Result |
|---|---|---|
| `test_source_literals_match_the_map` | M1: `tests/test_earth_beams.gd` ALPHA back to 1 | rc 1, `['tests/test_earth_beams.gd:15 CNS5:3627 index 1, stars.json 2'] != []` |
| reverse key order in `SOURCE_PAIR` | M2: the `\|"id"…"index"` alternative deleted | rc 1, `test_the_7am_literals_fail`: `z.gd:1 CNS5:3627 index 3, stars.json 2` missing |
| whitespace tolerance | M3: every `\s*` in `SOURCE_PAIR` → one space | rc 1, `test_the_7am_literals_fail` and `test_source_literals_match_the_map` (the pending entry is no longer seen) |
| enumeration covers subdirectories | M4: `source_files()` keeps only top-level files | rc 1, `'ui/transit_harness.gd' not found in ['main.gd']`, plus the stale pending entry |
| stale pending entry | M5: `tools/earth_link_capture.gd` fixed, entry kept | rc 1, `['tools/earth_link_capture.gd:16'] != []` |
| 7ai control is index-free | M6: `stars.json` entries 1 and 2 swapped, logs re-recorded (AC11) | old control rc 1 (`0 not greater than 0`); new rc 0 |
| exemption is needed (justification, not a kill) | M7: `SOURCE_EXEMPT = ()` | rc 1, `tools/test_replay.py:381 CNS5:1676 index 8, stars.json 9` and the 7ai mutation line flagged |
| pending list is needed (justification) | M8: `SOURCE_PENDING = ()` | rc 1, `['tools/earth_link_capture.gd:16 CNS5:3627 index 1, stars.json 2'] != []` |
| fails closed without git | M9: the prototype run from a non-git copy | `ERROR: test_source_literals_match_the_map`, `CalledProcessError … returned non-zero exit status 128` |
| edge pair | E1: `ci-fast: replay-map-index` line deleted | rc 2, `ci-fast lost its prerequisite replay-map-index (…)` |
| edge pin | E2: the pair removed from `SG_PREREQS`, pin left at 5 | rc 2, `SG_PREREQS holds 4 pairs (4 distinct) but SG_PREREQS_PAIRS is 5: …` |

## Sub-milestones and estimates

| # | What | LOC | Depends | Order |
|---|---|---:|---|---|
| T1 | M2 + M3 in `tools/test_replay.py`, M4 in `mk/script-gates.mk` and the fixture: AC1 red, AC6 green | ~85 | none | 1 (red first) |
| M1 | the 15 literal tokens: AC2–AC5 | 15 | T1 | 2 |
| V | AC7–AC12 (AC10 long); push a draft PR, AC13 | 0 | M1 | 3 |

About 25 minutes of headless runs (most of it AC10). No GPU.

## Risks and mitigations

- **The `comms_golden` pixels were not measured** (GPU, not run by rule). Its inputs are shown equal except for the echoed index (V3, V8, V9), and neither of its view classes reads the index. The nightly `rig/golden` runs it on main. If G-CV goes red after landing, revert the one token in `tools/comms_golden.gd`; do not re-record.
- **A false positive on a non-target dictionary** that pairs a catalogue id with an unrelated `"index"` (a list position, for example). None exists today: all 16 hits are plan targets (V2). The fix would be an explicit `SOURCE_EXEMPT` row with a comment, never a looser pattern.
- **A literal written another way** (`{"id": id, "index": i}` with variables, a `Dictionary` built field by field, or AILANG) is out of the guard's reach. The product map derives indices itself (`plan_intent`, `index_of`). 7ai's MapIndex still covers recorded logs. F1 tracks AILANG.
- **`git ls-files` on the runner:** `actions/checkout` gives a work tree. Outside one, the test errors instead of passing (M9).
- **OQ1 left unanswered:** the pending entry stays, and the guard keeps checking that it is the only wrong pair.

## Open questions for the user

- **OQ1 (Mark; attended).** Should `tools/earth_link_capture.gd`'s ALPHA move to alpha Cen A's real map index (2)? Its `a_outbound` map review frame would then show the subtitle `CNS5:3627  ·  4.32 ly` (as the live map does) instead of `CNS5:3627`. The title stays `En route to CNS5:3627`, and frames b–e are unchanged (V5). Answer **yes** or **no**. **Default if unanswered: no.** The capture stays as reviewed, and the guard's pending entry stays. A "yes" is one token plus deleting the pending entry, followed by `make capture-earth-link` for Mark to look at.

## Follow-ups (new findings, not scope)

- **F1.** AILANG test catalogues use local numbering for real `stars.json` ids: 17 pairs in 6 files (V2). This is inert today (V7). If a GDScript copy of one appears, M2 catches it. An AILANG scan would need an opt-out for local catalogues.
- **F2.** `tests/fixtures/protocol_27_inferred.{input,expected}.ndjson` plans Barnard at index 1 (`stars.json` 3). It is a frozen recording for `make ism-compat`, so it is not changed here. This is a provenance question: the fixture claims to be "a real … session", but the map would not write index 1.
- **F3.** 7ah's and 7al's `ci-fast` edges (`similar-main-guard`, `session-minor-guard` and their controls) could join `SG_PREREQS` the same way. That is four pairs and a pin of 9 (row 7ao's area).

## Deliverables

- M1: the 15 tokens. M2: the source guard and its three tests. M3: the derived 7ai control. M4: the edge pair, the pin and the fixture line.
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
| V11 | `stops_test.ail` is unchanged | `ailang test stops_test.ail` and `stopsVm` (strict VM; interpreter) at base and with `acenA` index 2 | `13 tests: 13 passed, 0 failed` both; check lines identical; `stopsVm` base VM = fixed VM = fixed interpreter (`cmp`), `stops-ok 24643.227462158196 107061.51570942107 …` |
| V12 | `exposure_solar_recovery`'s literal is dead | `grep -n destination tools/exposure_solar_recovery.gd`; `git grep -n 'exposure_solar_recovery\|ism_service_bench' -- Makefile mk tools tests sim` (excluding the files themselves) | only `:22` (literal) and `:24` (overwrite); no make target names it, while `mk/ism.mk:36` names `ism_service_bench.gd` (positive) |
| V13 | The edge is checked through `SG_PREREQS` | in tree: `SG_PREREQS += ci-fast:replay-map-index`, pin 5, fixture +1; `make -s script-gate-lint`; then the `Makefile:479` line deleted; then the pair dropped (reverted) | `script-gate-prereqs: ok (5 pairs hold …)`, rc 0; `ci-fast lost its prerequisite replay-map-index (ci-fast: stellar-protocol-test deps …)`, rc 2; `SG_PREREQS holds 4 pairs (4 distinct) but SG_PREREQS_PAIRS is 5 …`, rc 2. Without the fixture line, `make script-gate-lint SG_PREREQS="… ci-fast:replay-map-index" SG_PREREQS_PAIRS=5` fails `the prerequisite control … was not refused by name` |
| V14 | The 7ai control hard-codes today's index and breaks on a reorder | `sed -n 352,356p tools/test_replay.py`; AC11 block | `'"index":2,"id":"CNS5:3627"'`, `"… index 1, stars.json 2"`; re-recorded logs 7; `M6 orig rc=1`, `AssertionError: 0 not greater than 0`; `M6 proto rc=0`, `Ran 4 tests … OK` |
| V15 | The scan covers subdirectories | `source_files()` | 426 files incl. `ui/transit_harness.gd`, `tests/test_earth_beams.gd`, `tools/worlds_leak.py`; mutant M4 sees only `['main.gd']` |
| V16 | Fails closed without git | the prototype in `/tmp/stap_i88_7am/m6` (no `.git`) | `ERROR: test_source_literals_match_the_map`, `CalledProcessError: … returned non-zero exit status 128` |
| V17 | The harness's own controls hold wrong pairs | M7 (`SOURCE_EXEMPT = ()`) | `tools/test_replay.py:381 CNS5:1676 index 8, stars.json 9` and the 7ai mutation line |
| V18 | Prototype green and cheap | prototype applied: `time make -s replay-map-index` | `Ran 7 tests in 0.154s`, `OK`; 0.254 s wall. At base `python3 tools/test_replay.py MapIndex` prints 22 `ResourceWarning`s already (pre-existing `logs()`), `Ran 4 tests`, `OK` |
| V19 | Conflict surface | `git fetch origin feat/captain-command feat/r2-kerr-table-preflight feat/r2-kerr`; per branch `git diff --name-only $(git merge-base origin/main origin/$b) origin/$b -- <the 16 7am paths + Makefile>`; added pair lines `git diff … -- '*.gd' '*.py' \| grep '^+' \| grep -cE '<pair regex>'`; control `git show d6f2889a -- '*.gd' \| grep '^+' \| grep -cE …` | each branch lists only `Makefile` (positive: the instrument sees a touched file); added pair lines 0, 0, 0; control 3. `git ls-remote origin refs/pull/412/head` = `3926f4f3…` = branch head; `git merge-base --is-ancestor 7add91e4 origin/feat/captain-command` → yes |
| V20 | The test-plan mutations | `/tmp/stap_i88_7am/mut.*.log` (M1–M5, M7, M8 in tree; M4 re-run with a top-level-only filter; M6 and M9 in scratch) | as in the Test plan table; the prototype restored → `base-proto rc=0` |
| V22 | AC1 and AC3 as written | `git apply proto_test_replay.patch` (guard only), then MapIndex; then `git apply --exclude=tools/test_replay.py proto.patch` (M1), then the AC3 one-liner and MapIndex; reverted | `First list contains 14 additional elements.`, `Ran 7 tests`, `FAILED (failures=1)`; then `16 ['tools/earth_link_capture.gd:16 CNS5:3627 index 1, stars.json 2']` and `OK` |
| V21 | `earth_link_capture` and `comms_golden` are GPU targets outside `make test` | `sed -n 100,110p mk/earth-link.mk`; `sed -n 80,84p mk/earth-link.mk` | `capture-earth-link` "GPU window; not in make test"; `comms-golden` "(GPU window)", `golden: comms-golden` |

## Appendix A. `tools/test_replay.py` prototype (diff against `c35efb57`; keep two blank lines before `class AiSession` when applying)

```diff
@@ -7,6 +7,7 @@
 import hashlib
 import json
 import os
+import re
 import subprocess
@@ -324,6 +325,42 @@ def plan_index_mismatches(log_texts, stars):
     return bad
 
 
+# 7am: a catalogue target written by hand in GDScript or Python carries its stars.json index, as a
+# recorded log's must (GalaxyMap.target_name()/subtitle_text() trust the index only when
+# catalogue[index].id == id). Both key orders, JSON spacing or none. Ids not in stars.json (Sol, the
+# design row, synthetic ports) are not catalogue targets and are skipped. This file is exempt: its
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
+def source_index_pairs(file_texts, stars):
+    """(checked, bad): every hand-written (index, catalogue id) pair, and those whose index is not the id's."""
+    index = {s["id"]: i for i, s in enumerate(stars)}
+    checked, bad = [], []
+    for name, text in file_texts:
+        for m in SOURCE_PAIR.finditer(text):
+            i, sid = (m.group(1), m.group(2)) if m.group(1) is not None else (m.group(4), m.group(3))
+            if sid not in index:
+                continue
+            where = "%s:%d" % (name, text.count("\n", 0, m.start()) + 1)
+            checked.append(where)
+            if int(i) != index[sid]:
+                bad.append("%s %s index %s, stars.json %d" % (where, sid, i, index[sid]))
+    return checked, bad
+
+
 class MapIndex(unittest.TestCase):
@@ -347,14 +384,54 @@ class MapIndex(unittest.TestCase):
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
```

## Appendix B. `mk/script-gates.mk` and fixture (M4)

```make
# Prerequisites a row depends on: gates whose test needs fetched assets keep the target that fetches them (B3; …),
# and fast-tier edges a row's guard lives on (7am: replay-map-index carries 7ai's and 7am's map-index checks).
SG_PREREQS := constellation-test:starmap-assets planets-test:planet-assets planet-textures-check:planet-assets ship-console-test:ship-baseline ci-fast:replay-map-index
SG_PREREQS_PAIRS := 5
```

`tests/fixtures/script_gate/prereq_negative.mk.txt` gets this line appended, with one comment word added ("ci-fast keeps replay-map-index (7am)"):

```make
ci-fast: replay-map-index
```
