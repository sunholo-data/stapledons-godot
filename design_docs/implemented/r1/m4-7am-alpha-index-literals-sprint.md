# Sprint plan: R1-7AM-ALPHA-INDEX — hand-copied catalogue targets carry their real map index (row 7am)

**Design doc:** [m4-7am-alpha-index-literals.md](m4-7am-alpha-index-literals.md) (revision 2; quorum round 1
BLOCKED 3/3 on narrow points → r1: file counts restated, the `sim/stops_test.ail` token dropped, `decode_id`
escape decoding applied verbatim; round 2 BLOCKED 2/3, glm pass → r2 by the controller under the
narrow-refinement carve-out: the comment rewrite dropped (V26), AC11 re-measured `Ran 2 tests` (V14), the
open-PR surface enumerated (V29), and **M2 now REQUIRES dictionary-aware scanning** — Appendix A's
adjacency-only `SOURCE_PAIR` is the starting point, not the shipped form — with red controls for both key
orders and a nested dictionary between (test-plan M12, sprint-measured; the controller's independent spike
V28 finds the same 16 pairs, 0 non-adjacent at HEAD). No round 3, straight to planning.) **Sprint JSON:**
`.ailang/state/sprints/sprint_R1-7AM-ALPHA-INDEX.json`.
**Approval basis:** pillar table net 0, none below 0 (neutral suite hygiene); the one open question OQ1 is
Mark's (attended) with a stated default of **no** — `tools/earth_link_capture.gd` stays at index 1 as the
guard's one pending entry, and the loop proceeds.
**Branch:** `mission/stapledon-iter88-7am` (HEAD `bb701793`, the r2 design commit; merge-base with
`origin/main` is `c35efb57` = `origin/main` = the base every V-number was measured at;
`git diff --name-only c35efb57..HEAD` = the design doc alone, so every V-number applies verbatim;
`git status --porcelain` empty).
**Scope:** about 135 LOC (planner-corrected; the design header says ~125 — see D2): 14 one-token literal
edits in 10 files (M1, V23); `tools/test_replay.py` +118/−4 (the Appendix-A fence, planner-measured) plus
the r2 dictionary-aware extension and its fifth new test (sprint-measured); `mk/script-gates.mk` 2 changed
lines (`:17` the `SG_PREREQS` list, `:20` the pin 4→5; the comment is NOT rewritten, r2/glm);
`tests/fixtures/script_gate/prereq_negative.mk.txt` +1 line (V26: `2 files changed, 3 insertions(+),
2 deletions(-)` for the M4 pair); plus the changelog fragment. No `*.ail` file is edited (AC9); the
`Makefile` is never edited; `tools/earth_link_capture.gd` is never edited (OQ1 — its only write is AC5's
transient sed/mv drill, byte-restored in the same command line).
**No GPU, no `make golden`, no capture, no full local `make test`** (merge rule, CLAUDE.md; 7ah–7al
precedent); the targeted gates are `make replay-map-index` (already in `ci-fast`, `Makefile:477-479`) and
`make script-gate-lint` (already in `ci-fast` and `make test`), the four headless Godot rows of AC7, the
fixture regen AC8, and the long AC10 (`make ism-bench worlds-leak`, 10–20 min on the loaded Studio). The
GitHub fast tier on the draft PR is AC13 (controller). The nightly `rig/full` runs the suite on main
post-merge.

**Role split:** the planner ran no Godot and no make (this file is planned read-only; all plan-time checks
were git/grep/sed/awk/python reads) and runs no git write. The controller commits and lands. The executor
edits the tree and runs everything below **except** MS3's push, draft PR and AC13, which are marked
**(controller)** per the mission. The executor's git-adjacent commands are read-only (`git apply --check`,
`git diff`, `git show`, `git status`, the AC11 `git show origin/main:...` read); `git apply` of the
byte-extracted Appendix-A fence is the one working-tree write it does with git (never an index or history
write).

## Environment (executor)

```sh
cd <executor clone>
export PATH=/Users/voightkampff/dev/sunholo-data/stapledons-godot/runtime/bin:$PATH  # AC preamble: "or
                                   # AILANG=../stapledons-godot/runtime/bin/ailang" (this clone has no runtime/;
                                   # planner-measured); AILANG v0.56.1. PATH's own ailang is v0.59.0-92-dirty — never it.
B=c35efb57                          # origin/main = merge-base = the design's measured base; every V-number applies
S=$PWD/.godot/tmp/7am; mkdir -p "$S"   # scratch; .godot/ is .gitignore'd
export TMPDIR="$S"                  # D1: this sandbox refuses /tmp writes (planner-measured, as in 7al);
                                    # AC6's /tmp/7am_mk* and AC11's mktemp reroot here 1:1, expectations unchanged
```

Preamble once per session (every command headless, from the clone root; `perl -e 'alarm N; exec @ARGV'`
bounds every long run, 7ah/7ak/7al pattern):

```sh
ailang --version    # expect "AILANG v0.56.1" (commit 05c860a); anything else -> stop
godot --version     # expect 4.7.2.stable…
python3 --version   # stdlib only; the harness is a listed harness (tools/python-allowlist.txt)
```

The AC preamble also says run `make import` once; this clone's `.godot/` is already imported
(planner-measured). A fresh executor clone runs `godot --headless --path . --import` once first (rc 0; the
7 CSV-translation errors are pre-existing).

**Host note (Studio, per the mission):** the host is heavily loaded. AC7's four Godot rows can take several
minutes each and AC10 is the long pole (**10–20 min**, design AC10). A timing-only `ism-bench` failure on a
loaded host is re-run once on a quieter host and is not a 7am regression (the bench's index is echo-only,
V7); never bump a `SCRIPT_GATE` bound silently.

## Plan-time checks (planner, 2026-11-12, HEAD `bb701793`)

Cheap re-verification of the doc's claims against the tree (all read-only, bounded):

- **Base/HEAD.** HEAD = r2 design commit `bb701793`; merge-base with `origin/main` = `c35efb57` =
  `origin/main` = the design's "Measured at" base; only the design doc differs. `git status --porcelain`
  empty.
- **The 14 M1 literals — all match the tree verbatim (planner-verified).** `tests/test_bridge_monitors.gd:15`
  ALPHA `"index": 1` / `:16` OFF_RAY `"index": 2`; `tests/test_earth_beams.gd:15` ALPHA 1;
  `tests/test_earth_history.gd:21,22` ALPHA 1 / OFF_RAY 2; `tests/test_earth_log_bridge.gd:14,15` ALPHA 1 /
  OFF_RAY 2; `tools/comms_golden.gd:23` ALPHA 1; `tools/comms_station_capture.gd:26,27` ALPHA 1 / OFF_RAY 2;
  `tools/earth_rate_fixture.gd:10` ALPHA 1; `tools/worlds_leak.py:29` ALPHA 1 (inside the `star` row);
  `tools/exposure_solar_recovery.gd:22` `"id":"CNS5:3627","index":0` (reverse key order, compact JSON);
  `tools/ism_service_bench.gd:5` `{"index": 2, "id": "CNS5:1142",` (the pair spans two lines — the bench's
  shape in `test_the_7am_literals_fail`). The untouched sites also match: `tools/earth_link_capture.gd:16`
  ALPHA still at 1 (OQ1 pending entry) and `ui/transit_harness.gd:10` the correct pair `"index": 2` (the
  scan's positive control). `sim/stops_test.ail` untouched (r1 AILANG non-goal).
- **stars.json indices (planner-measured):** 5685 stars; `CNS5:3627` = 2, `HIP 71681` = 1, `CNS5:1676` = 9,
  `CNS5:1142` = 3158; `Sol` is not a catalogue id (skipped by design). These pin every edit target and the
  derived 7ai control.
- **`tools/test_replay.py` anchors.** Imports at `:7-13` (`hashlib, json, os, subprocess, sys, tempfile,
  unittest` — the fence's `+import re` lands after `os`); `plan_index_mismatches` at `:300`, its
  `return bad` at `:324`; `class MapIndex` at `:327`; the hard-coded 7ai control at `:350-356`
  (`"index":2,"id":"CNS5:3627"` → `"index":1,…`, the doc's V14 defect); `class AiSession` at `:359`. The
  appendix hunk headers (`@@ -7,6 +7,7 @@`, `@@ -324,6 +325,67 @@`, `@@ -347,13 +409,65 @@`) match these
  lines. Base MapIndex = 4 tests (V18); r1 adds 4 → 8; r2 adds the intervening-field test → **9
  (sprint-measured)**.
- **`mk/script-gates.mk` anchors.** `:17` = the `SG_PREREQS :=` line with 4 pairs (planner-verified);
  `:20` = `SG_PREREQS_PAIRS := 4`; the comment between them is NOT rewritten (r2/glm; V26 measured the
  applied form: 2 + 1 lines, `3 insertions(+), 2 deletions(-)`). The lint recipe's negative control
  (`:49-53`) expects exactly 2 refusals from the fixture; the pin check at `:54-55`. The ok line is printed
  by `tools/script_gate_prereqs.sh:27` (`script-gate-prereqs: ok ($n pairs hold in $mf: $*)`), so AC6's
  expected first line `ok (5 pairs hold in Makefile: … ci-fast:replay-map-index)` is exactly the shipped
  shape. `tools/script_gate_prereqs.sh` and `tools/script_gate_lint.sh` are do-not-touch (design).
- **Makefile anchors (never edited).** `replay-map-index` at `:476-478`
  (`python3 tools/test_replay.py MapIndex`), its edge `ci-fast: replay-map-index` at `:479` — the line AC6's
  middle step deletes transiently. The `Makefile` itself is do-not-touch (design); AC6's deletion is proven
  then restored by `cp` in the same command, closing with `git diff --quiet Makefile && echo restored`.
- **AC7/AC8/AC10 targets exist (planner-verified):** `earth-beams-test` `mk/earth-link.mk:93`,
  `earth-rate-fixture` `:101`, `comms-log-bridge-test` `:126`, `comms-history-test` `:134`,
  `bridge-monitors-test` `:158`; `ism-bench` `mk/ism.mk:34`; `worlds-leak` `mk/worlds.mk:20`.
- **Fence extraction (commands in "Byte-for-byte rule") planner-measured:** the Appendix-A `diff` fence =
  **146 lines, 3 hunks, +118/−4** (hunk math verified: 1 + 61 + 56 adds, 4 dels, all in hunk 3; well-formed —
  every line is context/`+`/`-`, no bare lines, so `git apply` takes it). The doc's "150 lines" for
  `proto_r1_test_replay.patch` is the fence plus a 4-line `diff --git`/`index`/`---`/`+++` header — consistent.
  Appendix-B `make` fences = **2 lines** (the new `SG_PREREQS` line and `SG_PREREQS_PAIRS := 5`) and **1
  line** (`ci-fast: replay-map-index`).
- **Clone state.** `.godot/` already imported; no `runtime/` (Environment); `godot` 4.7.2 on PATH;
  `/Users/voightkampff/dev/sunholo-data/stapledons-godot/runtime/bin/ailang` = v0.56.1 (commit 05c860a).
- **Toolchain on this host:** python3 present (the harness is stdlib-only). The planner sandbox's `gh` fails
  TLS (`x509: OSStatus -26276`), so the doc's conflict table (V19/V29: PRs #412/#380/#373 touch `Makefile`
  only, zero overlap; control `d6f2889a`) is **not** planner-re-verified — the controller re-checks the open
  PR surface before landing (Controller checks).

**Discrepancies (record, don't fix mid-sprint):**

- **D1. `/tmp` blocked.** Planner-measured (`touch /tmp/7am_plan_probe` → `Operation not permitted`), as in
  7al. AC6's `/tmp/7am_mk`/`/tmp/7am_mk.orig` and AC11's `S=$(mktemp -d)` reroot 1:1 under `$S` via
  `TMPDIR="$S"` (Environment); expectations byte-identical (`mktemp` honours `TMPDIR`; the `grep -v` /
  `cp` pairs write `$S/7am_mk*`). If the executor's sandbox allows `/tmp`, run as written — assert the same
  outputs.
- **D2. Appendix-A size.** The design header's Estimated-LOC bullet says `tools/test_replay.py`:
  **+104/−4** (and the ~125 total). The Appendix-A fence extracts to a well-formed 3-hunk diff whose own
  hunk headers total **+118/−4** (planner-measured; 146 lines). The fence is authoritative (byte-for-byte
  rule; its hunk math is self-consistent); the true total is ~135 LOC. Do not fix the header mid-sprint;
  record the actual `git diff --shortstat` at MS1.
- **D3. Deliverables wording stale at r2.** "M2: the source guard (with id decoding) and its four tests"
  counts the r1 tests; r2 adds `test_the_7am_intervening_fields_fail` (five new tests; MapIndex 4→9). The
  AC rows already carry the r2 form ("Ran 9 tests …; sprint-measured"). Report only.
- **D4. Doc's 7ai control line range.** The doc quotes `tools/test_replay.py:352–356`; the tree shows the
  method at `:350–356` (the body at `:352-356` — same lines, quote offset only). No action.

## Byte-for-byte rule (binding)

Never retype appendix text into the tree. Extract the fences, apply the extractions, prove with
`git apply --check` / `git diff --shortstat`:

```sh
D=design_docs/planned/r1/m4-7am-alpha-index-literals.md
awk '/^## Appendix A\./,/^## Appendix B\./' $D | awk '/^```diff$/{f=1;next} /^```$/{if(f){exit}} f' > $S/A.diff
awk '/^## Appendix B\./,0' $D | awk '/^```make$/{n++; f=1; next} /^```$/{if(f){f=0; next}} f {print > ("'$S'/B" n ".txt")}'
wc -l $S/A.diff $S/B1.txt $S/B2.txt    # expect 146, 2, 1 (planner-measured)
```

`git apply --check $S/A.diff` must pass against the untouched `tools/test_replay.py` (anchors above). A
mismatch means re-extract, never retype. The r2 dictionary-aware extension is then written on top of the
applied r1 form as ordinary executor code (it is not appendix text — the doc specifies it in M2's
revision-2 paragraph and pins its behaviour through AC1, the intervening-field test and mutation M12).

## Test-first order (mandatory)

The design's sub-milestones **T1 → M1 → V** map to **MS1** (T1: the guard and its controls land FIRST and
AC1 is shown RED on the unfixed tree — "guard in, literals not yet fixed"; M4's 2-line mk edit and fixture
line land here too, with the lint still green), **MS2** (M1: the 14 tokens turn AC2–AC5 GREEN), **MS3**
(V: AC6–AC12 + the fragment; AC13 is the controller's). **MS1 ends RED by design** (`replay-map-index`
fails with exactly the 14 non-pending mismatches until MS2 lands): the controller must not push or open a
PR from MS1's tree, and MS2 follows in the same iteration. Never present a control as green that never
went red:

| New/changed line | Killing control (proves it can fail) | Exact red evidence |
|---|---|---|
| `source_index_pairs` (r2 dictionary-aware scan) | **AC1 on the unfixed tree** (MS1 step 5); mutation **M12** (revert to adjacency-only, MS1 step 7) | AC1: `Ran 9 tests`, `FAILED (failures=1)` in `test_source_literals_match_the_map`, `First list contains 14 additional elements.`, `rc=1`. M12: `test_the_7am_intervening_fields_fail` fails for `{"index": 1, "pos": {"x": 1}, "id": "CNS5:3627"}` and `{"id": "CNS5:3627", "pos": {}, "index": 1}` (both key orders, nested dictionary between); **sprint-measured**, record the actual failing lines |
| `decode_id` (escape decoding) | mutations **M10**, **M11** (MS1 step 7) | M10 (`sid = raw`): rc 1, `test_the_7am_escaped_ids_fail`, `Lists differ: [] != ['e.gd:1', 'q.py:1']`. M11 (`return None` → `return raw`): rc 1, same test, the `u.gd:1 unsupported escape in id literal "CNS5\x3a3627"` entry missing |
| `source_files()` git enumeration | mutation **M9** (MS1 step 7, non-git copy under `$S`) | `ERROR: test_source_literals_match_the_map`, `CalledProcessError … returned non-zero exit status 128` (fails closed, V16) |
| The 14 literal tokens (M1) | **AC1 is RED until they land**; then AC4 (mutation M1: `tests/test_earth_beams.gd` ALPHA back to 1) | AC4: `tests/test_earth_beams.gd:15 CNS5:3627 index 1, stars.json 2`, make rc 2, restored by `mv` in the same command |
| `SOURCE_PENDING` (OQ1 entry) | AC5 (mutation M5: `tools/earth_link_capture.gd` fixed transiently, entry kept); mutation M8 (`SOURCE_PENDING = ()`) | AC5: `['tools/earth_link_capture.gd:16'] != []`, make rc 2, `mv` restores byte-identical. M8: rc 1, `['tools/earth_link_capture.gd:16 CNS5:3627 index 1, stars.json 2'] != []` |
| The M3 derived 7ai control | AC11 (mutation M6: `stars.json` entries 1 and 2 swapped, logs re-recorded, scratch dir) | `M6 orig rc=1`, `AssertionError: 0 not greater than 0`, `Ran 2 tests`, `FAILED (failures=1)`; `M6 new rc=0`, `Ran 2 tests`, `OK` |
| The `SG_PREREQS` pair + pin (M4) | AC6 middle step (mutation E1: `Makefile:479` line deleted); mutation E2 (pair dropped, pin left at 5) | E1: `ci-fast lost its prerequisite replay-map-index (…)`, make rc 2, then `restored`. E2: `SG_PREREQS holds 4 pairs (4 distinct) but SG_PREREQS_PAIRS is 5: …`, rc 2 |

Green expectation after MS2 (AC2): `Ran 9 tests`, `OK`, `rc=0`.

## Milestones

### MS1 — T1 RED: the guard (r2 dictionary-aware scan + escape decoding + intervening-field control), the derived 7ai control, the M4 edge pair

Files: `tools/test_replay.py` (+118/−4 from the fence, then the r2 delta — sprint-measured),
`mk/script-gates.mk` (`:17` and `:20`, 2 changed lines, comment untouched),
`tests/fixtures/script_gate/prereq_negative.mk.txt` (+1 line, appended). **Nothing else.** Closes: **AC1**
(RED — the milestone's end state, by design). The M4 half of AC6 (lint green at 5 pairs) is sanity-checked
here; AC6's full mutation sequence runs in MS3.

1. **Preamble + anchor assert (cheap; stop on any mismatch):** the Environment block; then
   `sed -n '7,13p;300p;324p;327p;350,356p;359p' tools/test_replay.py`, `sed -n '17p;20p' mk/script-gates.mk`,
   `tail -1 tests/fixtures/script_gate/prereq_negative.mk.txt`, `sed -n '476,479p' Makefile` → the
   planner-verified lines above (fixture's last line is `ship-console-test: import ship-baseline`;
   `Makefile:479` = `ci-fast: replay-map-index`).
2. **Fence extraction** (Byte-for-byte rule) → `146`, `2`, `1`.
3. **Apply Appendix A (the r1 base) byte-exactly:** `git apply --check $S/A.diff && git apply $S/A.diff`
   then `git diff --shortstat tools/test_replay.py` → ` 1 file changed, 118 insertions(+), 4 deletions(-)`
   (planner-measured fence math; the header's +104 is D2 — record the actual).
4. **Intermediate r1 RED (record):** `python3 -W ignore tools/test_replay.py MapIndex; echo rc=$?` →
   `Ran 8 tests`, `FAILED (failures=1)` in `test_source_literals_match_the_map`, `First list contains 14
   additional elements.`, `rc=1` (the r1 form on the unfixed tree; V18/V20's `Ran 8 tests, OK` was the
   prototype on the fixed tree).
5. **The r2 extension (executor-written, doc-specified):** rework the pair scan to be **dictionary-aware**
   (design M2, revision 2, verbatim requirement): for each `"index": N` literal, take its innermost
   enclosing `{…}`, keep only that dictionary's own level (nested dictionaries are skipped — a `"pos":
   {…}` between the keys does not hide the pair, and a nested `"id"` is never paired with the outer
   `"index"`), and look up a `"id": "<decoded>"` at that level, in either key order. Appendix A's
   `decode_id`, `source_files()`, `SOURCE_EXEMPT`, `SOURCE_PENDING`, the message formats
   (`<file>:<line> <id> index N, stars.json M` and `<file>:<line> unsupported escape in id literal
   "<raw>"`), the checked-pair accounting and the four r1 tests are unchanged; the adjacency-only
   `SOURCE_PAIR` regex may survive only as the per-level token matcher, never extended across braces.
   Add `test_the_7am_intervening_fields_fail`: in-memory texts `{"index": 1, "pos": {"x": 1}, "id":
   "CNS5:3627"}` and `{"id": "CNS5:3627", "pos": {}, "index": 1}` (both key orders, a nested dictionary
   between) at a wrong index, each flagged by name — its exact expected messages are **sprint-measured**
   (the V28 spike flags both shapes); record them. The r1 tests' expectations (4 messages, 5 checked;
   `['e.gd:1', 'q.py:1']` + 2 bad) must hold unchanged on the r2 form.
6. **AC1 (RED first — record verbatim; this is the first run of the 9-test suite ever):**
   `python3 -W ignore tools/test_replay.py MapIndex; echo rc=$?` → `Ran 9 tests` (**sprint-measured**:
   revision 2 adds the intervening-field test; if the count is not 9, stop — Pause points), `FAILED
   (failures=1)` in `test_source_literals_match_the_map`, `First list contains 14 additional elements.`
   (the 14 non-pending mismatches of V2), `rc=1`. **This RED is the milestone's required end state.**
7. **Tree-independent mutations (scratch, reverted; the doc's test plan, run on the 9-test form):**
   - **M12 (r2's killing mutation):** revert the scan to adjacency-only matching (Appendix A's
     `SOURCE_PAIR` as shipped by step 3 — keep a copy) → `test_the_7am_intervening_fields_fail` fails for
     `{"index": 1, "pos": {"x": 1}, "id": "CNS5:3627"}` and `{"id": "CNS5:3627", "pos": {}, "index": 1}`
     (both key orders, nested dictionary between; the V28 spike's own control already flags both).
     **Sprint-measured**: record the failing assertion lines; restore the dictionary-aware form and
     re-assert AC1's exact RED.
   - **M10:** `sid = decode_id(raw)` → `sid = raw` → rc 1, 1 failing: `test_the_7am_escaped_ids_fail`,
     `Lists differ: [] != ['e.gd:1', 'q.py:1']` (V25). Restore, re-assert.
   - **M11:** `decode_id`'s `return None` → `return raw` → rc 1, 1 failing:
     `test_the_7am_escaped_ids_fail`, the `u.gd:1 unsupported escape in id literal "CNS5\x3a3627"` entry
     missing (V25). Restore, re-assert.
   - **M9 (fails closed):** copy the harness to a non-git scratch dir
     (`mkdir -p $S/nogit/tools && cp tools/test_replay.py $S/nogit/tools/ && (cd $S/nogit && python3
     -W ignore tools/test_replay.py MapIndex; echo rc=$?)`) → `ERROR:
     test_source_literals_match_the_map`, `CalledProcessError … returned non-zero exit status 128` (V16;
     record whether the other source tests ERROR too — the doc names the one).
8. **M4 (the edge pair; Appendix B):** set `mk/script-gates.mk:17` to `$S/B1.txt` line 1 (the
   `SG_PREREQS :=` list gaining `ci-fast:replay-map-index`) and `:20` to line 2 (`SG_PREREQS_PAIRS := 5`);
   the comment between is untouched. Append `$S/B2.txt` (`ci-fast: replay-map-index`) to
   `tests/fixtures/script_gate/prereq_negative.mk.txt` — exactly one line, no comment change (r2/glm).
   Verify: `cmp <(sed -n '17p;20p' mk/script-gates.mk) $S/B1.txt && echo B1-ok`;
   `git diff --shortstat mk/script-gates.mk tests/fixtures/script_gate/prereq_negative.mk.txt` → ` 2 files
   changed, 3 insertions(+), 2 deletions(-)` (V26).
9. **M4 sanity green (AC6's first segment; full AC6 in MS3):** `make -s script-gate-lint 2>&1 | tail -1` →
   `script-gate-prereqs: ok (5 pairs hold in Makefile: constellation-test:starmap-assets
   planets-test:planet-assets planet-textures-check:planet-assets ship-console-test:ship-baseline
   ci-fast:replay-map-index)` (the ok line is `tools/script_gate_prereqs.sh:27`'s shape, planner-verified).
10. **Cleanliness:** `git status --porcelain` shows only the three MS1 files (plus the controller's
    plan/JSON); no `.bak`; the step-7 mutations are all reverted (`git diff` on `tools/test_replay.py`
    shows exactly the guard, never a leftover mutation). **Record in the sprint JSON that MS1 ends with
    `replay-map-index` RED by design (AC1) — do not push.**

### MS2 — M1 GREEN: the 14 literal tokens in 10 files; AC2–AC5; the tree-dependent guard mutations

Files (the design's ten paths, V23): `tests/test_bridge_monitors.gd` (`:15`,`:16`),
`tests/test_earth_beams.gd` (`:15`), `tests/test_earth_history.gd` (`:21`,`:22`),
`tests/test_earth_log_bridge.gd` (`:14`,`:15`), `tools/comms_golden.gd` (`:23`),
`tools/comms_station_capture.gd` (`:26`,`:27`), `tools/earth_rate_fixture.gd` (`:10`),
`tools/worlds_leak.py` (`:29`), `tools/exposure_solar_recovery.gd` (`:22`), `tools/ism_service_bench.gd`
(`:5`). **Not edited:** `tools/earth_link_capture.gd` (OQ1; AC5's drill below is transient) and
`sim/stops_test.ail` (AILANG non-goal). Depends on MS1. Closes: **AC2, AC3, AC4, AC5.**

1. **Anchor assert:** `sed -n '15,16p' tests/test_bridge_monitors.gd; sed -n '15p'
   tests/test_earth_beams.gd; sed -n '21,22p' tests/test_earth_history.gd; sed -n '14,15p'
   tests/test_earth_log_bridge.gd; sed -n '23p' tools/comms_golden.gd; sed -n '26,27p'
   tools/comms_station_capture.gd; sed -n '10p' tools/earth_rate_fixture.gd; sed -n '29p'
   tools/worlds_leak.py; sed -n '22p' tools/exposure_solar_recovery.gd; sed -n '5p'
   tools/ism_service_bench.gd` → the planner-verified literals above; any mismatch → stop (tree drift).
2. **The 14 one-token edits** (nothing else on those lines changes; the trailing `pos` values already
   equal `stars.json` to six decimals, 7ai V13):
   - ALPHA `"index": 1` → `2` in the 8 ALPHA files:
     `sed -i.bak 's/^const ALPHA := {"index": 1,/const ALPHA := {"index": 2,/' <file> && rm <file>.bak`
     for `tests/test_bridge_monitors.gd`, `tests/test_earth_beams.gd`, `tests/test_earth_history.gd`,
     `tests/test_earth_log_bridge.gd`, `tools/comms_golden.gd`, `tools/comms_station_capture.gd`,
     `tools/earth_rate_fixture.gd`; and `tools/worlds_leak.py`:
     `sed -i.bak 's/{"index": 1, "id": "CNS5:3627"/{"index": 2, "id": "CNS5:3627"/' tools/worlds_leak.py && rm tools/worlds_leak.py.bak`.
   - OFF_RAY `"index": 2` → `9` in the 4 OFF_RAY files:
     `sed -i.bak 's/^const OFF_RAY := {"index": 2,/const OFF_RAY := {"index": 9,/' <file> && rm <file>.bak`
     for `tests/test_bridge_monitors.gd`, `tests/test_earth_history.gd`,
     `tests/test_earth_log_bridge.gd`, `tools/comms_station_capture.gd`.
   - `tools/exposure_solar_recovery.gd:22` (reverse order, compact):
     `sed -i.bak 's/"id":"CNS5:3627","index":0/"id":"CNS5:3627","index":2/' tools/exposure_solar_recovery.gd && rm tools/exposure_solar_recovery.gd.bak`.
   - `tools/ism_service_bench.gd:5` (Aldebaran at its real index):
     `sed -i.bak 's/{"index": 2, "id": "CNS5:1142",/{"index": 3158, "id": "CNS5:1142",/' tools/ism_service_bench.gd && rm tools/ism_service_bench.gd.bak`.
   Verify: `git diff --shortstat` over the ten paths → ` 10 files changed, 14 insertions(+),
   14 deletions(-)` (V23); each hunk is one token.
3. **AC2 (GREEN after M1):** `make replay-map-index; echo rc=$?` → `Ran 9 tests`
   (**sprint-measured**, as in AC1), `OK`, `rc=0`.
4. **AC3 (only the pending pair is left):** `python3 -I -c "import sys; sys.path.insert(0,'tools');
   import test_replay as t; m=t.MapIndex(); c,b=t.source_index_pairs(m.sources(), m.stars());
   print(len(c), b)"` → `16 ['tools/earth_link_capture.gd:16 CNS5:3627 index 1, stars.json 2']`.
5. **AC4 (mutation M1, verbatim from the design; scratch + restored in one line):**
   `sed -i.bak 's/^const ALPHA := {"index": 2,/const ALPHA := {"index": 1,/' tests/test_earth_beams.gd; make replay-map-index; echo rc=$?; mv tests/test_earth_beams.gd.bak tests/test_earth_beams.gd`
   → `tests/test_earth_beams.gd:15 CNS5:3627 index 1, stars.json 2`, make rc 2. Re-assert AC2 green after
   the `mv`.
6. **AC5 (mutation M5, verbatim; the ONLY write `tools/earth_link_capture.gd` ever sees — transient,
   byte-restored):**
   `sed -i.bak 's/^const ALPHA := {"index": 1,/const ALPHA := {"index": 2,/' tools/earth_link_capture.gd; make replay-map-index; echo rc=$?; mv tools/earth_link_capture.gd.bak tools/earth_link_capture.gd`
   → `['tools/earth_link_capture.gd:16'] != []`, make rc 2. Then `git diff --quiet
   tools/earth_link_capture.gd && echo oq1-byte-identical` (mandatory proof; the file's bytes never
   change). Re-assert AC2 green.
7. **The tree-dependent guard mutations (the doc's test plan; each scratch + reverted, each followed by
   an AC2 re-assert).** These need the green baseline so their red shapes match the doc exactly:
   - **M2 (key order):** the id-first/reverse-order handling deleted from the scan → rc 1, 1 failing
     (`test_the_7am_literals_fail`): `z.gd:1 CNS5:3627 index 3, stars.json 2` missing. (Doc's number is
     from the r1 prototype; on the r2 form record the actual — the shape, 1 failing by name, is the
     expectation.)
   - **M3 (whitespace):** every whitespace-tolerant matcher → one space → rc 1, 3 failing:
     `test_source_literals_match_the_map` (the pending entry is no longer seen),
     `test_the_7am_escaped_ids_fail` (`[] != ['e.gd:1', 'q.py:1']`), `test_the_7am_literals_fail`.
   - **M4 (enumeration):** `source_files()` keeps only top-level files → rc 1, 2 failing:
     `'ui/transit_harness.gd' not found in ['main.gd']`, plus the stale pending entry.
   - **M7 (exemption justification):** `SOURCE_EXEMPT = ()` → rc 1, 2 failing:
     `tools/test_replay.py:<line> CNS5:1676 index 8, stars.json 9` (and the 7ai mutation line) flagged;
     `'tools/test_replay.py' unexpectedly found`. (Line numbers move with the r2 form — record actuals.)
   - **M8 (pending justification):** `SOURCE_PENDING = ()` → rc 1,
     `['tools/earth_link_capture.gd:16 CNS5:3627 index 1, stars.json 2'] != []`.
8. **Cleanliness:** `git status --porcelain` shows exactly the ten M1 files + the three MS1 files (plus
   controller files); no `.bak`; `git diff --name-only $B -- '*.ail' | wc -l` → `0` already holds (AC9's
   first half; MS3 re-runs the full row).

### MS3 — V: AC6–AC12 (AC10 long), the changelog fragment (executor); push, DRAFT PR, AC13 (controller)

Files: `changelogs/unreleased/2026-11-12-alpha-index-literals.md` (new). Scratch only otherwise
(`$S/7am_mk*`, AC11's `mktemp` dir — never committed). Depends on MS2. Closes: **AC6, AC7, AC8, AC9,
AC10, AC11, AC12** (executor) and **AC13** (controller; the one criterion that cannot run on this host).

Executor:

1. **AC6 (the edge is checked; includes mutation E1) — verbatim from the design, `/tmp` → `$S` per D1:**
   `make -s script-gate-lint 2>&1 | tail -1; grep -v '^ci-fast: replay-map-index$' Makefile > $S/7am_mk && cp Makefile $S/7am_mk.orig && cp $S/7am_mk Makefile; make -s script-gate-lint 2>&1 | tail -2; cp $S/7am_mk.orig Makefile; git diff --quiet Makefile && echo restored`
   → first line `script-gate-prereqs: ok (5 pairs hold in Makefile: … ci-fast:replay-map-index)`; then
   `script-gate-prereqs: ci-fast lost its prerequisite replay-map-index (…)` and `make: ***
   [script-gate-lint] Error 1`; then `restored`. **The `Makefile` is never left modified** — the `cp`
   restore and the `git diff --quiet` proof are part of the criterion.
2. **E2 (the pin is a ratchet; scratch + reverted):** remove `ci-fast:replay-map-index` from the
   `SG_PREREQS` line, leave the pin at 5 → `make -s script-gate-lint` rc 2 with `SG_PREREQS holds 4 pairs
   (4 distinct) but SG_PREREQS_PAIRS is 5: the pin moves with the pairs, and only up`; restore; re-assert
   the step-1 ok line.
3. **AC7 (the four headless tests, behaviour identical):** `make earth-beams-test comms-log-bridge-test
   comms-history-test bridge-monitors-test; echo rc=$?` → `earth-beams: 29 passed, 0 failures`,
   `comms-log-bridge: 9 passed`, `comms-history: 37 passed`, `bridge-monitors: 19 passed` (all `0
   failures`; counts may grow with main), `rc=0` (V6). Bound each run; under Studio load allow several
   minutes each (host note).
4. **AC8 (the Earth-rate fixture is unchanged):** `make earth-rate-fixture; git diff --exit-code
   tests/fixtures/earth/earth_rates.json; echo rc=$?` → `earth-rate-fixture: 2 rows ->
   res://tests/fixtures/earth/earth_rates.json`, `rc=0` (V6).
5. **AC9 (no AILANG file is edited, r1):** `git diff --name-only origin/main -- '*.ail' | wc -l; git
   diff --name-only origin/main -- '*.gd' | wc -l` → `0`; then `9` (positive control: the 9 edited
   GDScript files are seen; V23).
6. **AC10 (LONG — 10–20 min on the loaded Studio; bound it, poll inside the bound):** `make ism-bench
   worlds-leak; echo rc=$?` → `worlds-leak: four presets × two engines byte-identical; schema/import
   audit passed (…)`, each `worlds-leak vm/<preset>: … sha256 f466c8433b75375d…`; the `ism-service-bench:`
   line and `.passes == true`; `rc=0`. A timing-only bench failure on a loaded host is re-run once on a
   quieter host; it is not a 7am regression (the bench's index is echo-only, V7). The
   `worlds_leak.py:29` edit moves the sim's echoed index bytes only (V9: exactly 3 bytes, digest
   `4cea2b92…` → `f466c843…`; quoted only in R3-WORLDS evidence, V10).
7. **AC11 (mutation M6; the 7ai control survives a catalogue reorder) — the design's verbatim block,
   `S=$(mktemp -d)` under `TMPDIR=$S` (D1):**

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

   Expected (V14, re-measured at r2): `M6 orig rc=1`, `AssertionError: 0 not greater than 0`, `Ran 2
   tests`, `FAILED (failures=1)`; `M6 new rc=0`, `Ran 2 tests`, `OK` (both via the two-method selection;
   a full-class run in the non-git scratch dir ERRORs per V16, so it is not used). Note: in this block
   the design's `$S` is its own `mktemp` dir, not the executor scratch — under D1 `mktemp` roots at
   `$S` (TMPDIR), which is fine; the block cleans itself up.
8. **AC12 (hygiene and scope):** `make python-guard uid-guard script-gate-lint; git diff --check
   origin/main; git diff --name-only origin/main` → `python-guard: ok`, `uid-guard: ok`,
   `script-gate-lint: ok …`; diff-check silent; exactly the 10 M1 files, `tools/test_replay.py`,
   `mk/script-gates.mk`, `tests/fixtures/script_gate/prereq_negative.mk.txt` = **13 files**, plus landing
   files under `changelogs/`, `design_docs/`, `.ailang/state/`. (`tools/test_replay.py` is already a
   listed harness — no new allowlist row; no new `.gd` file — no `.uid`.)
9. **Fragment** (per `changelogs/unreleased/README.md`; one fragment, `YYYY-MM-DD-<slug>.md`; the 7al
   shape — `### Added` for the guard, `### Fixed` for the literals): name row **7am** and sprint
   `R1-7AM-ALPHA-INDEX`. Content: every hand-written catalogue target in tracked GDScript and Python now
   carries its `stars.json` index (14 literals in 10 files; alpha Cen A at 2, Sirius A at 9, Aldebaran at
   3158, the dead placeholder at 2); `make replay-map-index` (already in `ci-fast` and `make test`) now
   also scans tracked `*.gd`/`*.py` sources for hand-written `"index"`/`"id"` pairs — dictionary-aware,
   either key order, with `\"`/`\\`/`\uXXXX` decoding — so a new wrong pair fails at its PR;
   `tools/earth_link_capture.gd` stays at 1 as the guard's single pending entry until Mark answers OQ1;
   the 7ai control derives its indices from `stars.json`, so a catalogue reorder no longer false-fails
   it; the `ci-fast: replay-map-index` edge joins `SG_PREREQS` (pin 5), so dropping the edge fails
   `script-gate-lint` by name. Visible behaviour identical (V5, V6, V8, V9, V24); no product, sim, asset
   or physics change.
10. **Re-assert after the fragment:** AC12's line again (the file set now includes the fragment);
    AC2's `Ran 9 tests`, `OK` once more; `git status --porcelain` shows only the sprint's own files.
11. **Evidence note (per the mission):** record the sprint's evidence into
    `.ailang/state/sprints/sprint_R1-7AM-ALPHA-INDEX.json` before handoff — each milestone's `measured`
    field (MS1: the r1 8-test RED, AC1's exact 9-test RED with the `14 additional elements` line, the
    intervening-field test's actual messages **(sprint-measured)**, M9/M10/M11/M12 actuals, the B1-ok cmp
    and the V26 shortstat; MS2: the V23 shortstat, AC2–AC5 actuals incl. `oq1-byte-identical`, the
    M2/M3/M4/M7/M8 red lines; MS3: AC6's three segments, E2, AC7's four counters, AC8, AC9, AC10's
    digest/bench lines and wall time, AC11's four lines, AC12), `passes: true` per milestone, the
    fragment path, and wall-clock totals under `velocity`. MS3's executor half passes only with that
    evidence recorded; the controller's steps append the AC13 run evidence.

**(controller — the controller, not the executor, pushes and opens the PR, per the mission):**

12. Push the branch and open a **draft** PR with `gh pr create --draft` (`gh`, CLAUDE.md). The PR fires
    the ci.yml fast tier (`make ci-fast`, which includes `replay-map-index` and `script-gate-lint`) on
    the PR head.
13. **AC13 (fast tier green on GitHub, Ubuntu):** `gh pr checks <PR>` → the `make ci-fast` check `pass`;
    the job log contains `Ran 9 tests` / `OK` from `replay-map-index` (the sprint-measured count from
    MS1/MS2 — record it here) and `5 pairs hold` from `script-gate-lint`. Read the log through the API
    (`gh api repos/<R>/actions/jobs/<JOB>/logs`, ANSI-stripped — the 7al/V20 pipeline), never `gh run
    view --log`. **The PR does not leave draft until this holds.** A red or missing run blocks landing —
    fix the change, never remove the `ci-fast: replay-map-index` edge, never weaken the guard or the pin
    (design Risks, verbatim rule).

## Pause points (stop and report; do not improvise)

- Preamble: `ailang --version` ≠ v0.56.1 (or the unpinned PATH `ailang` v0.59.x in use) or `godot
  --version` ≠ 4.7.2 → stop; never let `AILANG ?= ailang` fall through to the unpinned PATH `ailang`.
- MS1: a fence extraction ≠ 146/2/1 lines, `git apply --check` fails, or the anchor assert mismatches →
  re-extract / stop; never retype design text. The r1 intermediate not `Ran 8 tests` with the 14-element
  failure → tree drift; stop. AC1 not `Ran 9 tests` / `FAILED (failures=1)` / `First list contains 14
  additional elements.` / `rc=1` → stop (the 9 is sprint-measured but must be 9: 4 base + 4 r1 + 1 r2; a
  different count means the test set drifted). The intervening-field control not catching both key orders
  → the scan is not dictionary-aware; stop (that is r2's whole requirement). M10/M11/M12/M9 red shapes
  differ → stop. The V26 shortstat not `2 files changed, 3 insertions(+), 2 deletions(-)` → stop.
- **MS1 ends RED by design (AC1): never push, never open a PR from it; MS2 follows in the same
  iteration.** If anything interrupts the loop between MS1 and MS2, the controller reverts or completes
  MS2 before any push.
- MS2: any of the 14 sed edits touching more than one token, or the V23 shortstat ≠ `10 files changed,
  14 insertions(+), 14 deletions(-)` → stop. AC2 not `Ran 9 tests` / `OK` / `rc=0` → stop. AC3 not `16
  ['tools/earth_link_capture.gd:16 CNS5:3627 index 1, stars.json 2']` → stop (a 17th pair or a missing
  one is a new finding, not an edit). AC4/AC5 not rc 2 with their exact lines, or a `mv` not restoring →
  stop; `git diff --quiet tools/earth_link_capture.gd` must print nothing (OQ1 byte-identity).
- MS3: AC6's first line not the 5-pair ok, the E1 deletion not rc 2 with the `lost its prerequisite`
  line, or `restored` absent → stop; the `Makefile` must be byte-restored. E2 not rc 2 with the pin
  message → stop. AC7 a counter or `0 failures` deviates → fixture or product drift; stop (counts may
  grow with main — a *different* number is drift to re-measure like V6, never to edit into the doc). AC8
  not byte-identical → stop. AC9 ≠ `0`/`9` → stop. AC10: a timing-only bench failure re-runs once on a
  quieter host; any other failure → stop. AC11 not the four exact lines → stop. AC12's file set ≠ the 13
  files + landing files → stop.
- AC13 (controller): a red/missing fast-tier run, or the job log lacking `Ran 9 tests` / `OK` or `5
  pairs hold` → **landing blocked**: fix and re-run; never remove the edge or suppress its failure. The
  PR stays draft until AC13 holds.
- Any temptation to touch the do-not-touch list below → stop; the fix needs none of it. In particular
  `tools/earth_link_capture.gd` sees no persistent edit (OQ1 is Mark's), and no `*.ail` file is touched
  (AC9 enforces it). No merge before the cross-family evaluation (generator ≠ judge); landing files wait
  on it.

## Risks (from the design; planner additions marked)

- **The `comms_golden` pixels were not measured** (GPU, not run by rule). Its `frame_cases` view and CPU
  reference points were measured identical at index 1 and index 2 (V24); its view classes do not read the
  index (V3). The nightly `rig/golden` runs it on main. If G-CV goes red after landing, revert the one
  token in `tools/comms_golden.gd`; do not re-record.
- **A false positive on a non-target dictionary** pairing a catalogue id with an unrelated `"index"`: none
  exists today (all 16 hits are plan targets, V2/V28). The fix is an explicit `SOURCE_EXEMPT` row with a
  comment, never a looser pattern.
- **A literal written another way** is out of reach: variables, a `Dictionary` built field by field,
  single-quoted or raw strings, GDScript `&"…"`/`^"…"`, or AILANG. None occurs today (all 16 hits are
  double-quoted, V2); the product map derives indices itself; 7ai's MapIndex covers recorded logs; F1
  tracks AILANG.
- **`git ls-files` on the runner:** `actions/checkout` gives a work tree; outside one the test ERRORs
  instead of passing (M9, V16) — fails closed.
- **OQ1 left unanswered:** the pending entry stays, and the guard keeps checking it is the only wrong
  pair; a stale pending entry fails (AC5).
- **(Planner-added) The r2 scan is executor-written, not appendix text:** the doc pins its behaviour
  (AC1's 14, the intervening-field test, M12's red, the unchanged r1 expectations), and V28's independent
  spike measured the same 16 pairs with 0 non-adjacent at HEAD — if the executor's scan finds a different
  inventory at AC1/AC3, that is a finding, not an adjustment; stop (Pause points).
- **(Planner-added) Host load:** AC7's Godot rows and AC10's bench are the slow parts; AC10's
  timing-only failure mode is a re-run on a quieter host, never a bound bump and never a regression claim
  (V7: the bench's index is echo-only).
- **(Planner-added) D1 `/tmp`:** AC6 and AC11 reroot under `$S` via `TMPDIR`; expectations byte-identical;
  AC11's block still self-cleans (`rm -rf`).
- **(Planner-added) gh TLS failure in some sandboxes** (planner-measured): AC13 runs where `gh` works
  (the controller's environment, as in 7al); the conflict table (V19/V29) is re-checked by the controller
  before landing since the planner could not reach GitHub.

## Files allowed and do-not-touch (design, verbatim scope)

- **Allowed (the design's 13 paths + landing files):** the ten M1 files (`tests/test_bridge_monitors.gd`,
  `tests/test_earth_beams.gd`, `tests/test_earth_history.gd`, `tests/test_earth_log_bridge.gd`,
  `tools/comms_golden.gd`, `tools/comms_station_capture.gd`, `tools/earth_rate_fixture.gd`,
  `tools/worlds_leak.py`, `tools/exposure_solar_recovery.gd`, `tools/ism_service_bench.gd`);
  `tools/test_replay.py`; `mk/script-gates.mk` (`:17` and `:20` only; the comment is NOT rewritten);
  `tests/fixtures/script_gate/prereq_negative.mk.txt` (+1 line only); plus
  `changelogs/unreleased/2026-11-12-alpha-index-literals.md` and this sprint's plan/JSON/scratch.
- **Do not touch (design, verbatim):** `tools/earth_link_capture.gd` (OQ1 — AC5's transient drill
  excepted, byte-restored and proven); `Makefile` (AC6's transient deletion excepted, restored and
  proven); `data/starmap/*` (AC11 swaps a *copy* in scratch); `tests/replays/*` and every golden (AC11
  re-records *copies* in scratch); `tests/fixtures/*.ndjson`; `ui/`, `demos/`, `bridge/`, `main.gd`;
  every `*.ail`, `sim/stops_test.ail` included (r1; AC9 checks it); `tools/script_gate_prereqs.sh` and
  `tools/script_gate_lint.sh`. No new file but the fragment → no `.uid`, no allowlist row.

## Local PR gates (targeted, headless, bounded)

The GitHub fast tier (`make ci-fast`) already runs both gates this row leans on (`replay-map-index`,
`script-gate-lint`); M4 only ratchets the edge. Locally:

1. MS1 on record: the anchor asserts; the 146/2/1 extractions; `git apply --check` + the +118/−4
   shortstat; the r1 8-test RED; **AC1's 9-test RED verbatim** (`14 additional elements`, rc 1); the
   intervening-field test's measured messages; M9/M10/M11/M12 reds; the B1-ok cmp; the V26 shortstat; the
   5-pair ok line.
2. MS2 on record: the ten-file anchor assert; the V23 shortstat (10/14/14); AC2 `Ran 9 tests`, `OK`,
   rc 0; AC3's `16 […]`; AC4/AC5 rc 2 with exact lines and byte-restores (incl. `oq1-byte-identical`);
   the M2/M3/M4/M7/M8 red lines with AC2 re-asserted after each.
3. MS3 evidence: AC6's three segments (`ok (5 pairs …)` → `lost its prerequisite` rc 2 → `restored`);
   E2's pin line; AC7's four counters rc 0; AC8 rc 0; AC9 `0`/`9`; AC10's digest/bench lines rc 0 with
   wall time; AC11's four lines; AC12's three oks + the 13-file set; the fragment in place; the sprint
   JSON's `measured` fields filled.
4. The GitHub gate is AC13 on the **draft** PR's head (controller): `pass` + the job-log lines (`Ran 9
   tests` / `OK`, `5 pairs hold`). No GPU gate, no `make golden`, no capture, no full local `make test`
   (merge rule); the nightly `rig/full` runs the suite on main post-merge.

## Controller checks (the controller re-runs after the executor, before landing)

AC1's RED log vs AC2's GREEN (`Ran 9 tests` both; the 14-element line) · the +118/−4 and V26 shortstats
against fresh fence extractions (146/2/1) · the intervening-field test's messages vs M12's red (both key
orders, nested dictionary) · M9/M10/M11 and M2/M3/M4/M7/M8 red lines · the V23 shortstat (10/14/14) ·
AC3's `16 […]` · AC4/AC5 rc 2 + restores (`oq1-byte-identical`, porcelain clean, no `.bak`) · AC6's
three segments and E2 · AC7's counters · AC8 · AC9 `0`/`9` · AC10's `f466c843…` digests and `.passes ==
true` · AC11's four lines · AC12's file set (13 + landing) · the fragment naming row 7am · **AC13 on the
draft-PR head** (`pass`; job log `Ran 9 tests` / `OK` and `5 pairs hold`) · the sprint JSON's `measured`
fields filled · the open-PR conflict surface re-checked (V19/V29; the planner's `gh` could not reach
GitHub — controller re-runs the fetch/diff measurement) · OQ1 still unanswered ⇒ the pending entry and
`tools/earth_link_capture.gd:16` at index 1 both still in place.

## Landing (controller, after the cross-family evaluation passes and AC13 holds) and post-merge check

Fragment already in tree from MS3; `git mv` doc + plan to `design_docs/implemented/r1/`; README index row;
charter row 7am status; sprint JSON → recorded counts, wall times and the AC13 evidence, `status:
completed`, evaluation block, path moves. The PR leaves draft only after AC13 holds. Post-merge
(observation, not a gate): the next nightly `rig/full` (`make test`) runs `tools-test` → the 9-test
MapIndex and stays green, and the nightly `rig/golden` covers G-CV-2 (`tools/comms_golden.gd`'s one token;
if it goes red, revert that token, do not re-record — design Risks). A `replay-map-index` failure on an
unmutated tree post-merge is a product finding for its own row, never an allowlist entry. If OQ1 is
answered "yes" later: one token in `tools/earth_link_capture.gd`, the pending entry deleted, `make
capture-earth-link` for Mark — its own attended step, outside this sprint.

## Velocity / estimate

~135 LOC planner-corrected (design header ~125; D2: the fence measures +118/−4, not +104/−4; the r2 delta
is sprint-measured on top). MS1 ≈ 120 LOC + the r2 extension, ~30–45 min wall (runs are seconds — V18:
0.70 s for the 8-test form on the loaded host; the work is the dictionary-aware scan and the mutation
drills). MS2 = 14 tokens, ~15 min (the sed edits and drills; AC2–AC5 run in seconds). MS3 ≈ 25–35 min of
headless runs dominated by **AC10 (10–20 min, design AC10)** plus AC7's four Godot rows (minutes each
under Studio load), plus the fragment and evidence. **This repo's recent rows of this size each took one
iteration** (7ah ~180 LOC one executor session; 7aj ~55; 7ai ~16; 7ak ~4; 7al ~240): the same is planned
here — one iteration, no day-count estimated.
