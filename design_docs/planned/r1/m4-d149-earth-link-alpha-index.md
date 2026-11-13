# The Earth-link capture plans alpha Cen A at its real map index (D-149)

**Status:** Planned 2026-11-13 (mission iteration 91, designer Opus 5.5). Measured at `origin/main` `85ca5470`. **Release:** r1. **Milestone:** none (charter queue: "D-149's one-token fix", row 7am's held pair).
**Priority:** low. Nothing is red. Mark ruled on it (D-149, attended 2026-11-12), so the loop may land it.
**Implements:** ledger row **D-149** (`design_docs/stapledon-mission.md`, Decision ledger), verbatim: *"Yes: tools/earth_link_capture.gd's ALPHA target moves to alpha Cen A's real map index (2, from 1) and the guard's SOURCE_PENDING entry is removed; the a_outbound review frame's subtitle becomes CNS5:3627 with its 4.32 ly distance, as the live map shows."* It closes OQ1 of [`m4-7am-alpha-index-literals.md`](../../implemented/r1/m4-7am-alpha-index-literals.md) (V4, V5). The capture is AC11 of [`r3/earth-link.md`](../../implemented/r3/earth-link.md). That design implements the design repo's [signals-and-instruments.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/signals-and-instruments.md) §2–§3.1. No physics-spec section applies, because the sim never reads the index (7am V7).
**Depends on:** nothing.
**Estimated LOC:** 9 lines in 2 files, none of it product code (V13: `2 files changed, 3 insertions(+), 6 deletions(-)`).

## Game vision alignment

Scored against `../stapledons-design/vision/core-pillars.md` and `physics/relativity-spec.md`. The skill was not interviewed because this run is unattended, so the designer scored the table.

| Pillar | Relevance | Score | Notes |
|---|---|---:|---|
| Choices Are Final | 0 | 0 | No game logic changes. |
| The Game Doesn't Judge | 0 | 0 | No copy changes. |
| Time Has Emotional Weight | 0 | 0 | The live map already shows `· 4.32 ly`. Only the review frame catches up with it. |
| The Ship Is Home | 0 | 0 | No scene or asset changes. |
| Grounded Strangeness | 0 | 0 | No content changes. One review frame's subtitle gains the real distance. |
| We Are Not Built For This | 0 | 0 | No crew or AI changes. |
| Hard sci-fi authenticity (spec) | 0 | 0 | No formula, shader, LUT, golden or shipped render changes. Physics gates 2 and 3 do not apply. |
| **Net** | | **0** | **ALIGNED (neutral): go.** This is a correctness fix to a developer review capture. Every 0 means "not touched". |

## Problem

1. `tools/earth_link_capture.gd:16` reads `const ALPHA := {"index": 1, "id": "CNS5:3627", …}`. In `data/starmap/stars.json`, index 1 is `HIP 71681` (alpha Cen B) and index 2 is `CNS5:3627` (alpha Cen A). `CNS5:3627` occurs only at index 2 (V1).
2. It is the only wrong hand-written pair left. The 7am scan covers 444 tracked `*.gd`/`*.py` files and checks 16 pairs. Exactly one is bad: `tools/earth_link_capture.gd:16 CNS5:3627 index 1, stars.json 2` (V2). The guard passes today only because `SOURCE_PENDING` excuses that pair (V3).
3. `GalaxyMap.subtitle_text()` adds the distance only when `catalogue[index].id == id`. So the capture's `a_outbound` map frame shows `CNS5:3627`, while the live map shows `CNS5:3627  ·  4.32 ly` (V7).

## Goals and non-goals

**Goals:**
- Change the one token at `tools/earth_link_capture.gd:16` from `1` to `2`.
- Remove the `SOURCE_PENDING` mechanism, so that every wrong pair fails the guard.
- Keep a positive control that proves the scan still sees real pairs, including the pair this change fixes.

**Non-goals:**
- Showing the name "Alpha Centauri A" in the capture. The title stays `En route to CNS5:3627` because the capture never calls `load_names()` (7am V4).
- Any other capture, golden, `*.ail`, Makefile or `mk/*.mk` change.
- Running `make capture-earth-link`. It needs a GPU window (see "Gates").

## Design

### D1. The token

At `tools/earth_link_capture.gd:16`, change `"index": 1` to `"index": 2`. The `.uid` file does not change.

### D2. The guard: remove the mechanism, not just the entry

**Choice:** delete `SOURCE_PENDING` and its two-line comment (`tools/test_replay.py:340–342`). Replace the two assertions at `:462–463` with `self.assertEqual(bad, [])`. Add a second named positive control:

```python
        self.assertEqual(bad, [])
        self.assertIn("ui/transit_harness.gd:10", checked)  # known positive: the scan sees a real pair
        self.assertIn("tools/earth_link_capture.gd:16", checked)  # D-149: the pair held pending until Mark ruled is seen, and now matches
```

**Why not `SOURCE_PENDING = ()`?**
- With an empty tuple, the stale-entry assertion (`:463`) checks nothing. The filter in `:462` becomes `bad == []` spelled indirectly.
- The tuple was there for one ruling, and that ruling is now made. If a future pair needs an attended hold, that is a new decision and can bring the mechanism back. Git keeps the code.
- `assertEqual(bad, [])` gives the clearest failure: it prints every wrong pair.

**Why the second positive control?** When the pair leaves `bad`, nothing else shows that the scan still sees it. A tokeniser regression that dropped `tools/earth_link_capture.gd:16` would pass silently. The `blind` mutation (AC5) proves the new control is live.

**Both edits must land in one commit.** The old guard combined with the fixed `.gd` fails, because the pending entry is stale: `Lists differ: ['tools/earth_link_capture.gd:16'] != []` (V12). The new guard combined with the old `.gd` fails on the pair (V10, `index` mode).

The synthetic controls (`test_the_7am_literals_fail`, `_escaped_ids_fail`, `_intervening_fields_fail`) are unchanged. They still prove that any new wrong pair, in any shape, is caught.

### Gates: where the two files run (V4, V5)

| File | Run by | In `make test` | In `ci-fast` | In `make golden` |
|---|---|---|---|---|
| `tools/test_replay.py` | `replay-map-index` (`Makefile:479–482`, `MapIndex` only); `tools-test` (`Makefile:293–294`, the whole file) | yes, through `tools-test` | yes, through `replay-map-index` (`Makefile:482`; edge pinned in `mk/script-gates.mk:17` `SG_PREREQS`) | no |
| `tools/earth_link_capture.gd` | `capture-earth-link` only (`mk/earth-link.mk:104–109`). This is a GPU window: the recipe has no `--headless`, and the comment says "GPU window; not in make test". It is also listed in `tools/script-gate-baseline.txt:24` (a row only, unaffected). | no | no | no |

`.github/workflows/ci.yml` runs only `make ci-fast` (or `make test` under `workflow_call`). No aggregate target (`test`, `ci-fast`, `golden`, `capture`) depends on `capture-earth-link`.

**Nothing tracked depends on the capture's output.** The capture writes only `renders/earth_link/<state>_{station,map}.png` and `contact_sheet.png`. `renders/` is gitignored (`.gitignore:2`), and no tracked file sits under `renders/earth_link`. `tests/fixtures/earth_link/{strip,beams}.json` are read by `tools/earth_display_golden.gd`, not written by this capture. No sha256 pin names the capture's outputs.

### What visibly changes (V7, V8)

Measured with a headless label probe (Appendix B). It runs the capture's own flow on the real sim at AILANG v0.56.1 and replaces the image block with prints:

| Frame | Before (index 1) | After (index 2) |
|---|---|---|
| `a_outbound` map title | `En route to CNS5:3627` | `En route to CNS5:3627` (unchanged) |
| `a_outbound` map subtitle | `CNS5:3627` (visible) | `CNS5:3627  ·  4.32 ly` (visible) |
| `a_outbound` station | 20 labels, `labels_sha=c4b3e05190254f4f` | same |
| `a_outbound` sim view | `view_sans_index_sha=9ffd74fe7d35b829`, `"index":1.0` | same sha, `"index":2.0` (the echo only) |
| `b_top`, `c_replan`, `d_stale`, `e_home` | the V7 and V8 lines | byte-identical lines (`diff` shows only the two `a_outbound` lines) |
| summary | `earth-link-capture: 10 frames, 0 failures`, rc 0 | same |

The rate, in-beam state, beams and beam labels in every `earth-link-capture: ok …` line are identical.

## Acceptance criteria

Run from the clone root, `ROOT=/Users/voightkampff/dev/sunholo-data/stapledons-godot-iter91`, or the build's clone. `85ca5470` is the base. Each row also gives its reading on the pristine tree (base), recorded by the designer.

| AC | Checks | Command | Expected (built) | Baseline (pristine `85ca5470`) |
|---|---|---|---|---|
| AC1 | The one token | `test "$(grep -c '^const ALPHA := {"index": 2, "id": "CNS5:3627", ' tools/earth_link_capture.gd)" -eq 1 \|\| exit 1` | rc 0 | count 0 → rc 1 (V1/V2: the line has `"index": 1`) |
| AC2 | The mechanism is gone | `test "$(git grep -n SOURCE_PENDING -- tools \| wc -l)" -eq 0 \|\| exit 1` | rc 0 | 3 hits (`tools/test_replay.py:342,462,463`) → rc 1 (V4) |
| AC3 | The guard passes | `perl -e 'alarm 120; exec @ARGV' make replay-map-index` | rc 0; `Ran 9 tests`; `OK` | rc 0, `Ran 9 tests`, `OK`: passes only through the pending entry (V3) |
| AC4 | Killing mutation: ALPHA back at index 1 fails the guard | `perl -e 'alarm 240; exec @ARGV' bash "$D/d149_drill.sh" index "$ROOT"` (Appendix A, saved outside the repo as `$D/d149_drill.sh`) | `d149-drill: index make_rc=2`; `fail_lines=1 want_hits=3 summary=1`; `d149-drill: index KILLED`; rc 0; `git status --porcelain` empty afterwards | `d149-drill: mutation index did not apply`, rc 3 (V11) |
| AC5 | Killing mutation: the new positive control is live | `perl -e 'alarm 240; exec @ARGV' bash "$D/d149_drill.sh" blind "$ROOT"` | `d149-drill: blind make_rc=2`; `fail_lines=1 want_hits=1 summary=1`; `d149-drill: blind KILLED`; rc 0; tree clean | `mutation blind did not apply`, rc 3 (V11) |
| AC6 | The whole harness | `perl -e 'alarm 300; exec @ARGV' python3 tools/test_replay.py` | `Ran 38 tests`, `OK`, rc 0 | `Ran 38 tests`, `OK` (V3) |
| AC7 | Whitespace | `perl -e 'alarm 30; exec @ARGV' git diff --check 85ca5470 HEAD` | no output, rc 0 | rc 0 (V3) |
| AC8 | Scope | `test "$(git diff --name-only 85ca5470 HEAD -- . ':!design_docs' ':!.ailang' \| tr '\n' ' ')" = "tools/earth_link_capture.gd tools/test_replay.py " \|\| exit 1` | rc 0 | empty → rc 1 (V13 on the prototype: those 2 files) |
| AC9 | Policy gates on the touched files | `for t in python-guard uid-guard lint-precision; do perl -e 'alarm 120; exec @ARGV' make $t \|\| exit 1; done` | each `…: ok`, rc 0 (`438 .uid files`; `23 allowlisted`) | same (V9 on the prototype; neither file is new) |
| AC10 | The frame change, headless | `make runtime` (or AILANG v0.56.1) and `make import` first. Then: `T=$(mktemp -d) && trap 'rm -rf "$T"' EXIT && perl "$D/elc_probe_gen.pl" < tools/earth_link_capture.gd > "$T/p.gd" && AILANG_BIN=$PWD/runtime/bin/ailang perl -e 'alarm 600; exec @ARGV' godot --headless --audio-driver Dummy --path . --script "$T/p.gd" > "$T/log" 2>&1; rc=$?; test $rc -eq 0 \|\| exit 1; test "$(grep -cF 'elc-probe a_outbound title=[En route to CNS5:3627] subtitle=[CNS5:3627  ·  4.32 ly]' "$T/log")" -eq 1 \|\| exit 1; test "$(grep -c '^earth-link-capture: 10 frames, 0 failures$' "$T/log")" -eq 1 \|\| exit 1` | rc 0 for every step. The b–e `elc-` lines equal V7/V8's. | the `a_outbound` line has `subtitle=[CNS5:3627]` → the second `test` gives rc 1 (V7) |
| AC11 | Mark sees the frame (attended, after merge; not a merge gate) | `make capture-earth-link` in a GPU window when the GPU is free, then open `renders/earth_link/a_outbound_map.png` and `contact_sheet.png` | `earth-link-capture: 10 frames, 0 failures`. The `a_outbound` map subtitle reads `CNS5:3627  ·  4.32 ly`. | not run: GPU window, and the GPU is busy |

`$D` is a scratch directory outside the repo (for example `D=$(mktemp -d)`) holding Appendices A and B.

AC11 is the acceptance path Mark's ruling describes ("you see the new frame in the next dev build"). It does not block the merge. Nothing shipped in the game changes visually, and merges never wait on the GPU (CLAUDE.md, Merges §2).

## Sub-milestones and estimates

One milestone, **D149-1**: D1 and D2 in one commit, 2 files, +3/−6. Order: apply both edits, then run AC1–AC10. AC11 follows the merge.

## Risks and mitigations

- **Landing one edit without the other.** Each half alone fails `replay-map-index` (V10, V12). This is caught in `ci-fast`, and AC8 checks both files.
- **Removing the mechanism hides a future wrong pair.** It does not: `assertEqual(bad, [])` is stricter than before. Every wrong pair fails, and nothing is excused. The synthetic controls and AC4 prove this.
- **The positive control names a line number.** A future edit that moves `ALPHA` off line 16 fails the control, with a clear message. The `ui/transit_harness.gd:10` control already has the same property. This is accepted: the fix is to update the line number.
- **Probe drift.** Appendix B checks the exact lines it replaces (`die` on mismatch), so a changed capture script fails the probe instead of silently probing something else.

## Open questions for the user

None. D-149 is complete: the token, the guard entry and the expected frame are all named in the ruling.

## Deliverables

- `tools/earth_link_capture.gd`: one token.
- `tools/test_replay.py`: `SOURCE_PENDING` removed, the assertion rewritten, one positive control added.
- After the evaluation passes: this doc moves to `design_docs/implemented/r1/`, and the charter rows are updated (controller).

## Verification log

| V | What | Ran (where) | Reading |
|---|---|---|---|
| V1 | Catalogue indices | `python3 -c` over `data/starmap/stars.json` (clone, `85ca5470`) | `[(0,'Gaia DR3 5853498713190525696'), (1,'HIP 71681'), (2,'CNS5:3627'), (3,'Gaia DR3 4472832130942575872')]`; `CNS5:3627` at `[2]` only |
| V2 | Pristine source scan | `test_replay.source_index_pairs(MapIndex().sources(), stars())` (clone) | 444 files, 16 checked (incl. `tools/earth_link_capture.gd:16`, `ui/transit_harness.gd:10`); `bad = ['tools/earth_link_capture.gd:16 CNS5:3627 index 1, stars.json 2']` |
| V3 | Pristine gates | `make replay-map-index`; `python3 tools/test_replay.py`; `git diff --check` (clone, alarm-bounded) | `Ran 9 tests … OK` rc 0; `Ran 38 tests … OK`; diff-check rc 0 |
| V4 | References | `git grep` (clone, excluding `design_docs` and `.ailang`) | `SOURCE_PENDING` only at `tools/test_replay.py:342,462,463`. `capture-earth-link` only in `mk/earth-link.mk:106–107` and `tools/script-gate-baseline.txt:24`. `ci.yml` runs `make ci-fast` / `make test` only. `ci-fast: replay-map-index` at `Makefile:482`; `tools-test` runs `python3 tools/test_replay.py` (`Makefile:294`) and is in `test` (`Makefile:60`) |
| V5 | Output dependants | `git check-ignore -v renders/x.png`; `git ls-files \| grep earth_link`; `git grep fixtures/earth_link` (clone) | `.gitignore:2:renders/`; no tracked `renders/earth_link*`; `tests/fixtures/earth_link/*` read by `tools/earth_display_golden.gd:7–8` only; the capture writes only `OUT = res://renders/earth_link` |
| V6 | Pinned runtime | `make runtime` then `make import` (clone; both alarm-bounded) | `runtime/bin/ailang --version` → `AILANG v0.56.1`; import rc 0. (The `ailang` on PATH is v0.60.0-dev and was not used for probes.) |
| V7 | Frame labels at index 1 vs 2 | Appendix B probe on pristine (idx 1) and with `"index": 2` (idx 2): `AILANG_BIN=$PWD/runtime/bin/ailang godot --headless --audio-driver Dummy --path . --script …` (clone; 40 s and 37 s) | idx 1: `elc-probe a_outbound title=[En route to CNS5:3627] subtitle=[CNS5:3627] subtitle_text=[CNS5:3627] subtitle_visible=true`. idx 2: `… subtitle=[CNS5:3627  ·  4.32 ly] subtitle_text=[CNS5:3627  ·  4.32 ly] subtitle_visible=true`. b–e identical in both runs: `b_top title=[En route to waypoint C (60 ly)] subtitle=[waypoint C (60 ly)]`, `c_replan title=[port B (a 30 ly turn)]`, `d_stale title=[En route to port B (a 30 ly turn)]`, `e_home title=[En route to Sol] subtitle=[Sol]`. Both runs: `earth-link-capture: 10 frames, 0 failures`, rc 0 |
| V8 | Station and sim view | the same runs, `elc-station` lines | `a_outbound labels_sha=c4b3e05190254f4f nlabels=20 view_sans_index_sha=9ffd74fe7d35b829` in both; `view_sha` `17b1dec2…` → `335995a1…` and `index_values` `"index":1.0` → `"index":2.0` (positive: the echo moves). b–e `labels_sha` `e05ab2ad…`, `99ac268d…`, `ed10578f…`, `6e519ca8…` equal in both. `diff` of all `elc-`/`earth-link-capture` lines: exactly 2 lines differ (`a_outbound` probe and station) |
| V9 | Prototype gates | scratch clone `/tmp/iter91/proto` with D1+D2 committed: `make replay-map-index`; `python3 tools/test_replay.py`; `git diff --check HEAD~1 HEAD`; `make python-guard uid-guard lint-precision` | `Ran 9 tests … OK`; `Ran 38 tests … OK`; rc 0; `python-guard: ok (23 allowlisted, 0 awaiting AILANG port)`, `uid-guard: ok (438 .uid files)`, `lint-precision: ok (…)` |
| V10 | Killing mutations on the prototype | `perl -e 'alarm 240; …' bash d149_drill.sh {index,blind} /tmp/iter91/proto` | index: `make_rc=2`, `fail_lines=1 want_hits=3 summary=1`, `KILLED`, rc 0. blind: `make_rc=2`, `fail_lines=1 want_hits=1 summary=1`, `KILLED`, rc 0. `git status --porcelain` empty after each |
| V11 | Drill fails closed on the pristine tree | the same drill on the clone | `mutation index did not apply` rc 3; `mutation blind did not apply` rc 3; tree clean |
| V12 | Half-applied edit | prototype with the old `tools/test_replay.py` restored: `python3 tools/test_replay.py MapIndex` | rc 1: `FAIL: test_source_literals_match_the_map`, `AssertionError: Lists differ: ['tools/earth_link_capture.gd:16'] != []`, `FAILED (failures=1)` |
| V13 | Prototype diff | `git diff --stat` (prototype) | `tools/earth_link_capture.gd \| 2 +-`, `tools/test_replay.py \| 7 ++-----`, `2 files changed, 3 insertions(+), 6 deletions(-)` |
| V14 | AC10 as written | AC10's command, with Appendix B extracted from this doc (`cmp`-equal to the generator run in V7/V8), on the clone (pristine capture) and with the prototype's capture file as input | pristine: `godot_rc=0`, a_outbound hits 0 → rc 1. With the fix: rc 0, and its `elc-` lines `diff`-equal to V7/V8's index 2 run |

**UNVERIFIED:**
- AC11. `make capture-earth-link` (GPU window), the PNGs and the contact sheet were not run or opened.
- The CI fast-tier run on GitHub.

The probe's `target_index=-` field is uninformative: the journey has no `target` key. `index_values` in V8 is the measured echo.

## Appendix A: the drill (`d149_drill.sh`, sha256 `ae32d0e1cabb93c6…`)

```bash
#!/bin/bash
# D-149 killing-mutation drill. usage: bash d149_drill.sh MODE ROOT   (MODE: index | blind)
# index: ALPHA back at HIP 71681's index 1 -> test_source_literals_match_the_map must fail on the pair.
# blind: ALPHA's "id" key renamed -> the scan no longer sees the pair -> the D-149 positive control must fail.
MODE=${1:?MODE}; ROOT=${2:?ROOT}
F=tools/earth_link_capture.gd
cd "$ROOT" || exit 1
test -f "$F" || exit 1
T=$(mktemp -d /tmp/d149_drill.XXXXXX) || exit 1
cp "$F" "$T/orig" || exit 1
restore() {
  cp "$T/orig" "$ROOT/$F" || { echo "d149-drill: RESTORE FAILED"; exit 4; }
  cmp -s "$T/orig" "$ROOT/$F" || { echo "d149-drill: RESTORE MISMATCH"; exit 4; }
  rm -rf "$T"
}
trap restore EXIT
trap 'exit 142' ALRM INT TERM
case "$MODE" in
  index) perl -pi -e 's/^const ALPHA := \{"index": 2, "id": "CNS5:3627"/const ALPHA := {"index": 1, "id": "CNS5:3627"/' "$F" || exit 1
         want='tools/earth_link_capture.gd:16 CNS5:3627 index 1, stars.json 2' ;;
  blind) perl -pi -e 's/^const ALPHA := \{"index": 2, "id": "CNS5:3627"/const ALPHA := {"index": 2, "ident": "CNS5:3627"/' "$F" || exit 1
         want="'tools/earth_link_capture.gd:16' not found in" ;;
  *) echo "d149-drill: unknown MODE $MODE"; exit 1 ;;
esac
if cmp -s "$T/orig" "$F"; then echo "d149-drill: mutation $MODE did not apply"; exit 3; fi
perl -e 'alarm 120; exec @ARGV' make replay-map-index > "$T/log" 2>&1
rc=$?
echo "d149-drill: $MODE make_rc=$rc"
fails=$(grep -c '^FAIL: test_source_literals_match_the_map' "$T/log")
hits=$(grep -cF "$want" "$T/log")
summary=$(grep -c '^FAILED (failures=1)$' "$T/log")
echo "d149-drill: $MODE fail_lines=$fails want_hits=$hits summary=$summary"
test "$rc" -eq 2 || exit 1
test "$fails" -eq 1 || exit 1
test "$hits" -ge 1 || exit 1
test "$summary" -eq 1 || exit 1
echo "d149-drill: $MODE KILLED"
```

The drill's design:
- ROOT is explicit.
- The scratch directory comes from `mktemp`, and an EXIT trap restores the file. The restore fails closed with exit 4, and `ALRM`/`INT`/`TERM` route through the trap.
- A `cmp` check proves the mutation applied, or the drill exits 3.
- make's own rc is captured with no pipe and must be exactly 2. An alarm kill gives 142 and fails.
- Counts are asserted with `test`, every check ends in `|| exit 1`, and no assertion uses `!`.
- The whole drill is bounded by the outer `alarm 240`, and make by `alarm 120`.

## Appendix B: the headless frame probe (`elc_probe_gen.pl`)

`perl elc_probe_gen.pl < tools/earth_link_capture.gd > probe.gd`. This applies to the capture at `85ca5470` and to the capture after D1; the line numbers are the same in both.

The generator makes three changes:
- It removes the `_contact_sheet()` call (line 144) and `sheet.append` (line 191).
- It replaces lines 173–186 (`frame_post_draw` and the PNG save/hash/blank loop) with prints of the map's title and subtitle, a hash of the station's labels, and a hash of the sim view with its `index` values normalised. It keeps `frames += 2` so that the summary line still counts 10.
- It `die`s if any replaced line differs from what it expects.

The probe keeps the capture's sim flow, its state checks and its `DisplayBinding.audit`.

```perl
my $block = <<'GD';
	print("elc-probe %s title=[%s] subtitle=[%s] subtitle_text=[%s] subtitle_visible=%s target_index=%s" % [label, map._title.text, map._subtitle.text, map.subtitle_text(), map._subtitle.visible, journey().get("target", {}).get("index") if journey().get("target") is Dictionary else "-"])
	var labs := []
	var stack: Array = [station]
	while not stack.is_empty():
		var nd: Node = stack.pop_back()
		if nd is Label: labs.append((nd as Label).text)
		if nd is RichTextLabel: labs.append((nd as RichTextLabel).text)
		stack.append_array(nd.get_children())
	var vj := JSON.stringify(view, "", true)
	var rx := RegEx.create_from_string("\"index\":\\s*-?[0-9.]+")
	print("elc-station %s labels_sha=%s nlabels=%d view_sha=%s view_sans_index_sha=%s index_values=%s" % [label, str(labs).sha256_text().substr(0, 16), labs.size(), vj.sha256_text().substr(0, 16), rx.sub(vj, "\"index\":X", true).sha256_text().substr(0, 16), rx.search_all(vj).map(func(m: RegExMatch) -> String: return m.get_string())])
	var imgs := [null, null]
	frames += 2
GD
my $n = 0;
while (my $l = <STDIN>) {
  $n++;
  if ($n == 144) { $l eq "\t_contact_sheet()\n" or die "144"; next; }
  if ($n == 191) { $l =~ /^\tsheet\.append/ or die "191"; next; }
  if ($n == 173) { $l eq "\tawait RenderingServer.frame_post_draw\n" or die "173"; print $block; next; }
  if ($n > 173 && $n <= 186) { $l =~ /frames \+= 1/ and $n != 186 and die "186"; next; }
  print $l;
}
```

The generator was checked to reproduce the probes run in V7/V8 byte for byte: `cmp` against the pristine capture gives the index 1 probe, and against the prototype's capture gives the index 2 probe.
