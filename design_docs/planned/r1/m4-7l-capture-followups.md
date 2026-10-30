# S1 capture and ship-bench follow-ups: three drill survivors, a reproducibility note, a bench verdict line (row 7l)

**Status:** Planned (mission iteration 59, designer, 2026-10-30). **Release:** r1. **Milestone:** M4.6rR3 follow-ups, charter queue row **7l** (clause 4 hygiene) inside the approved sprint `R1-M4-JOURNEY` (D-22/D-66).
**Priority:** P2 (follow-up backlog). Test, tooling and report text only.
**Implements:** [charter](../../stapledon-mission.md) row 7l (b), (c) and (d); the follow-up of [m4-6rr3-ship-renders-bench.md](m4-6rr3-ship-renders-bench.md) and its evaluation [`eval_R1-M4-JOURNEY_M4.6rR3_round_1.json`](../../../.ailang/state/evaluations/eval_R1-M4-JOURNEY_M4.6rR3_round_1.json) (drills CA, CB, CC; non-blocking findings 1, 2 and 4). The [relativity spec](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md) stays untouched. **(a) is deferred on hold** (see Problem).
**Depends on:** D-88 A (test hygiene inside an approved sprint needs no stop); AILANG v0.54.18 (`runtime/bin`), Godot 4.7.2, the GPU window. No package, sim, protocol, scene, shader or player-visible change; no pixel of any render changes.
**Estimated LOC:** about **50**: `tools/m4_ship_capture.gd` ~38 (CA 2, CC 8, CB 26, the sheet call 1), `tools/m4_ship_bench.gd` ~10, the M4.6rR3 report 1 paragraph.
**Evidence:** the Verification log below, run first-hand in this clone at `e94ed9b7` (origin/main).

## Game vision alignment

Scored against [core pillars](https://github.com/sunholo-data/stapledons-design/blob/main/vision/core-pillars.md).

| Pillar | Relevance | Score | Notes |
|---|---|---:|---|
| Choices Are Final | 0 | 0 | The capture issues the same console inputs as today. |
| The Game Doesn't Judge | 0 | 0 | No player-facing copy. |
| Time Has Emotional Weight | 0 | 0 | Clocks and journey timing untouched. |
| The Ship Is Home | 0 | 0 | The arrival card is read, not changed. |
| Grounded Strangeness | 0 | 0 | No world or visual change. |
| We Are Not Built For This | 0 | 0 | No crew or consequence change. |
| Hard sci-fi authenticity (spec) | 0 | 0 | The cruise β is checked against the sim's own `journey.plan.cruise_beta` with a proven-tight tolerance; a stricter ratchet over the same S1 evidence, no new physics. |
| **Net** | | **0** | **Go under D-88 A:** test hygiene inside the D-66-approved sprint; no pillar is negative. |

## Problem

Each premise was measured at `e94ed9b7`; the V-numbers are rows of the Verification log.

- **(a) The publish is not atomic.** `capture-m4-publish` runs `test -s "$f"` inside the upload loop (`Makefile:323`, V5), so a missing `worlds.sha256` fails after 17 uploads (evaluator drill P4). **Out of scope: deferred on hold.** The root `Makefile` is held by both open attended PRs, #344 and #351 (V2). Re-file (a) unchanged when neither holds `Makefile`. This doc designs no edit to it.
- **(b) Three drill survivors in `tools/m4_ship_capture.gd`** (V9). **CA:** deleting `\t\t\tdemo.dismiss_arrival()` (line 62) stays green; nothing in the driver reads the HUD (V6). **CC:** the cruise check `absf(beta - 0.99) < 1e-12` (line 156) passes at tolerance 1.0. It compares against a literal, and nothing tests the tolerance (V8). **CB:** `var row := 0 if frame.view == "deck" else 1` (line 214) can be pinned to 0 because the sheet is saved and never read back (V7).
- **(c) Only the worlds are reproducible.** Two captures on the same tree give a byte-equal `worlds.sha256` and **15 of 15** different PNG hashes (V14; the evaluator saw 12 of 15 at iteration 36). The report still says the public set is "byte-equal to the local set" and has no reproducibility caveat (V16). The public set also no longer matches a fresh capture at all: 14 of 14 world hashes and 15 of 15 PNG hashes differ (V15).
- **(d) The bench verdict is not printed.** The driver exits 1 for an invalid run and 2 for a MISS (V17), but the recipe turns every failure into `exit 1`, so make returns 2 either way (V18). Only the footer's `exit $rc` tells the two apart. The JSON `verdict` field says `MISS` or `ok` even when the run is invalid (line 138, V17).

**Premises in the brief that proved false (corrected here):** `demos/ship_geometry_demo.gd` and `ui/ship_hud.gd` **are** held by both #344 and #351 (V2). This design edits neither; it only calls the existing `ship_hud.has_card`. The M4.6rR3 design, plan and report are in `design_docs/planned/r1/`, not `implemented/` (V21).

## Goals and non-goals

**Goals.** Kill CA, CB and CC, each with an exact named FAIL through `make capture-m4`. Make the report honest about reproducibility. Give the bench one greppable verdict line, with unchanged exit codes and p99.
**Non-goals.** No edit to `Makefile`, `mk/*`, `demos/*`, `ui/*`, `tools/m4_ship_golden.gd`, `tools/ship_ui_capture.gd` or `tests/display_audit.gd`. No pinning of dust flashes or card fades: that changes pixels and needs Mark's S1 render sign-off. No republish of the public set. No change to the bench's exit codes, its p99 computation or its existing lines, which row 7m-d depends on.

## Design

### (b) CA: the arrival card is up, then dismissed

The observable is `demo.ship_hud.has_card("arrival")`. `hide_card` sets `leaving` immediately, and `has_card` is false for a leaving card (`ui/ship_hud.gd:379–387`, V12). Frame 06 shows the Arrived card with `Dismiss [Enter]` (V11). Lines 61–62 become:

```gdscript
			await _views(6, "arrived_acen")
			_check(demo.ship_hud.has_card("arrival"), "arrival card not shown at arrived_acen")
			demo.dismiss_arrival()
			_check(not demo.ship_hud.has_card("arrival"), "arrival card still up after dismiss")
```

The first check is the positive control: without it, the second check would pass vacuously if the card never appeared. **Kill:** deleting the dismiss line gives exactly one `FAIL arrival card still up after dismiss`. The next commit hides the card (demo line 1270), so the rest of the run is unchanged and all 14 frames are still shot.

### (b) CC: a tolerance proven tight, measured against the sim's own value

The sim's cruise β is 0.9900000000000004, and its `journey.plan.cruise_beta` is 0.99; they are 4.4e-16 apart, so exact equality is wrong (V8). Add:

```gdscript
const CRUISE_BETA_TOL := 1e-12 # sim cruise beta is plan.cruise_beta + 2 ulp (0.9900000000000004)
func _near(a: float, b: float) -> bool:
	return absf(a - b) < CRUISE_BETA_TOL
```

At the top of `_run`, before the stale-file cleanup, add a self-test with one positive and one negative control:

```gdscript
	_check(_near(0.9900000000000004, 0.99), "cruise beta tolerance rejects 0.99 + 2 ulp")
	_check(not _near(0.99 + 1e-9, 0.99), "cruise beta tolerance accepts 0.99 + 1e-9")
```

The existing gate `if failures:` / `_finish()` / `return` (lines 32–34, V29) stops the run before the demo loads at line 36, and the self-test is inserted above the stale-file cleanup at line 29, so it runs before that gate; AC4's 0 frames means "the gate at the measured line fires before the demo loads". The cruise check (line 156) becomes `ship.phase == "cruising" and _near(beta, float(world.journey.plan.cruise_beta)) and _near(float(world.journey.plan.cruise_beta), 0.99) and glow > 0.0 and demo.sky_state == "live"`. **Kill:** CC is now `const CRUISE_BETA_TOL := 1e-12` → `1.0`. The negative control then accepts 0.99 + 1e-9, giving exactly one `FAIL cruise beta tolerance accepts 0.99 + 1e-9` and 0 frames. The same control also kills any tolerance at or above about 1e-9.

### (b) CB: each thumbnail in its own cell

The layout property: in the 7×2 sheet (2276×366, V13), the frame `NN_<state>_<view>.png` sits at column `NN − 1`. Deck frames go in row 0 and forward frames in row 1. The cell's pixels must equal that frame's thumbnail, and the 14 cells must all be distinct. A new `_sheet_layout()` runs after `_sheet()`. It reloads `contact_sheet.png` from disk, so the save is checked too, and asserts its size against the literal `Vector2i(2276, 366)`. For each path in `shots`, it works out the cell **from the file name**, independently of `_sheet`'s `col`/`row`: `col = int(name.substr(0, 2)) - 1` and `row = 1 if name.ends_with("_forward.png") else 0`. It then rebuilds the thumbnail with the same calls (`load_from_file`, `convert(FORMAT_RGB8)`, `resize(THUMB, LANCZOS)`) and checks `sheet.get_region(Rect2i(Vector2i(col * (THUMB.x + GAP), row * (THUMB.y + GAP)), THUMB)).get_data() == thumb.get_data()`. A mismatch fails as `contact sheet cell <name> at col <c> row <r> differs`. Last, it checks that the 14 `col * 2 + row` keys are distinct (`contact sheet cells <n> (want 14 distinct)`). **Kill:** with the row stuck at 0, row 1 stays black and row 0 holds the forward thumbnails, which are blitted after the deck ones. That gives exactly 14 cell FAILs and 14 frames.

### Drills: a function in this doc, not a committed script

No committed drill script. `capture-m4` and `bench` are GPU targets that `make test` does not reach (V4). Without a `Makefile` edit, a script could not be wired in either, so it would be an unexercised file. Instead, the executor and the evaluator run the functions below, which is the 7q pattern. The drill has the hardened shape: an explicit ROOT; one parent `mktemp -d` with a single trap that restores the file and removes the directory; `cmp` proof that the mutation changed the file, else exit 3; make's return code captured and asserted; counts asserted with `test`; no `!`; `|| exit 1` on every check. It verifies **through the make target**, with `SCRATCH` redirected into the temp directory.

**Deadline.** `timeout` and `gtimeout` are not installed on the rig; `/usr/bin/perl` 5.34 is (V24). `deadline` forks, puts make in a new process group and arms an alarm. On expiry it sends TERM to the whole group and, 5 s later, KILL. After reaping make, it waits up to 5 s more for the rest of the group, sends a final KILL and exits **124**. Otherwise it passes the command's return code through. The drill maps 124, and any return code other than 0 or 2, to **exit 4, INFRASTRUCTURE**, never "killed". Its trap still restores the source and removes the scratch. The defaults are `DRILL_S=900` for a capture (measured 121 s, V10) and 300 for the bench (14 s for DB1, V25).

```sh
deadline() { # deadline SECONDS CMD...: CMD's rc; 124 on expiry (TERM to its process group, KILL 5 s later)
  perl -e '
    my $s = shift; my $pid = fork; exit 125 unless defined $pid;
    if ($pid == 0) { setpgrp(0, 0); exec @ARGV; exit 127 }
    setpgrp($pid, $pid); my $hit = 0;
    $SIG{ALRM} = sub { kill(($hit++ ? "KILL" : "TERM"), -$pid); alarm 5 };
    alarm $s; waitpid($pid, 0); my $rc = $?; alarm 0;
    exit($rc & 127 ? 128 + ($rc & 127) : $rc >> 8) unless $hit;
    my $t = time + 5; select(undef, undef, undef, 0.2) while kill(0, -$pid) && time < $t;
    kill "KILL", -$pid; exit 124;' "$@" < /dev/null
}
drill() (  # exit 0 killed, 1 survived or wrong signature, 2 usage, 3 mutation not applied, 4 INFRASTRUCTURE
  set -eu
  ROOT=${1:?explicit checkout ROOT required}; mutant=${2:?CA, CB, CC or DB1}
  cd "$ROOT" || exit 2; ROOT=$(pwd -P)
  case "$mutant" in DB1) F=tools/m4_ship_bench.gd ;; CA|CB|CC) F=tools/m4_ship_capture.gd ;; *) exit 2 ;; esac
  test -f "$F" || exit 2
  T=$(mktemp -d "${TMPDIR:-/tmp}/stapledon-7l.XXXXXX") || exit 2
  trap 'if test -f "$T/orig.gd"; then cp "$T/orig.gd" "$ROOT/$F"; fi; rm -rf "$T"' EXIT
  trap 'exit 130' INT; trap 'exit 143' TERM HUP
  cp "$F" "$T/orig.gd" || exit 2
  target=capture-m4; scene=; log=capture-m4.log; frames=14; S=${DRILL_S:-900}
  case "$mutant" in
    CA) perl -i -ne 'print unless /^\t\t\tdemo\.dismiss_arrival\(\)$/' "$F" || exit 1
        want='^capture-m4: FAIL arrival card still up after dismiss$'; n=1 ;;
    CB) perl -i -pe 's/^\t\tvar row := 0 if frame\.view == "deck" else 1$/\t\tvar row := 0/' "$F" || exit 1
        want='^capture-m4: FAIL contact sheet cell [0-9]{2}_[a-z0-9_]+\.png at col [0-6] row [01] differs$'; n=14 ;;
    CC) perl -i -pe 's/^const CRUISE_BETA_TOL := 1e-12( |$)/const CRUISE_BETA_TOL := 1.0$1/' "$F" || exit 1
        want='^capture-m4: FAIL cruise beta tolerance accepts 0\.99 \+ 1e-9$'; n=1; frames=0 ;;
    DB1) perl -i -pe 's/^const BENCH_S := 30\.0$/const BENCH_S := 0.0/' "$F" || exit 1
        target=bench; scene=bridge; log=bench-bridge.log; S=${DRILL_S:-300}
        want='^bench-bridge: verdict invalid exit 1: 0 frames of 300 needed, p99 n/a ms against 16\.7 ms, 3 structural failures$'; n=1 ;;
  esac
  if cmp -s "$T/orig.gd" "$F"; then echo "drill: mutation did not change $F"; exit 3; fi
  set +e
  PATH="$ROOT/runtime/bin:$PATH" deadline "$S" make "$target" ${scene:+SCENE=$scene} SCRATCH="$T/s" AILANG="$ROOT/runtime/bin/ailang" > "$T/make.out" 2>&1
  rc=$?
  set -e
  echo "drill $mutant: make rc $rc"
  case "$rc" in
    2) ;;
    0) echo "drill $mutant: SURVIVED"; exit 1 ;;
    124) echo "drill $mutant: INFRASTRUCTURE timeout after $S s"; exit 4 ;;
    *) echo "drill $mutant: INFRASTRUCTURE rc $rc"; exit 4 ;;
  esac
  L="$T/s/$log"; test -s "$L" || exit 1
  test "$(grep -c 'SCRIPT ERROR:' "$L")" -eq 0 || exit 1
  test "$(grep -c -E "$want" "$L")" -eq "$n" || exit 1
  if test "$mutant" = DB1; then
    test "$(grep -c '^bench-bridge: verdict ' "$L")" -eq 1 || exit 1
    test "$(grep -c '^bench-bridge: FAIL measured 0 frames (want >= 300)$' "$L")" -eq 1 || exit 1
    test "$(grep -c '^bench-bridge: FAILED (exit 1:' "$T/make.out")" -eq 1 || exit 1
  else
    test "$(grep -c '^capture-m4: FAIL ' "$L")" -eq "$n" || exit 1   # per-check lines (trailing space)
    test "$(grep -c '^capture-m4: FAIL$' "$L")" -eq 1 || exit 1      # _finish's one bare summary line
    test "$(grep -c '^capture-m4: ok frame' "$L")" -eq "$frames" || exit 1
  fi
  echo "drill $mutant: killed"
)
```

The CB count of 14 relies on the manifest order: deck before forward in every column (V26). The bench always writes `res://.godot/tmp/bench-bridge.json`, whatever `SCRATCH` is, so DB1 overwrites the checkout's copy. Run AC8 after it.

Order: run the four drills first, then AC1 last, so `renders/m4/` ends as a good set. RED, before any edit: the evaluator has already measured CA, CB and CC surviving (V9). The executor may re-run the CA and CB mutations on the unedited tree and expect make rc 0.

### (c) Say so in the report; do not pin

Pinning dust flashes and card fades would change pixels, which needs Mark's S1 sign-off, so the report records the limit instead. Insert this paragraph into `design_docs/planned/r1/m4-6rr3-ship-renders-bench-report.md`, directly after line 7 (the "Public set" paragraph), exactly as written:

> **Reproducibility (row 7l, iteration 59).** Only the worlds are reproducible, not the pixels: a second `make capture-m4` on the same tree gives a byte-equal `worlds.sha256`, but the PNG hashes differ between runs (12 of 15 in the iteration-36 evaluation, which traced dust-impact flashes and HUD card fades; 15 of 15 at `e94ed9b7`, where even the docked frames differ, cause not traced). The AC5 table below describes one run, the published set. At `e94ed9b7` a fresh capture matches the public set in none of its 14 world hashes and none of its 15 PNG hashes, so S1 review should use a fresh capture.

### (d) One verdict line from the driver

Add `const VERDICTS := ["ok", "invalid", "MISS"]` (indexed by the exit code) and give `_stop` a detail argument. Before its unchanged `quit(code)`, `_stop` prints `bench-bridge: verdict %s exit %d: %s` % [VERDICTS[code], code, detail]. The calls become:

- `quit(1)` at line 37 → `_stop(1, "demo not ready")`;
- line 67 → `_stop(1, "departure not committed")`;
- line 143 → `_stop(1 if failures else (2 if miss else 0), "%d frames of %d needed, p99 %s ms against %.1f ms, %d structural failures" % [times.size(), MIN_FRAMES, "n/a" if times.is_empty() else "%.3f" % timing.p99_ms, P99_TARGET_MS, failures])`. When `times` is empty, the p99 field is the literal `n/a`; otherwise it is `timing.p99_ms` printed with `%.3f`. On the measured DB1 path (V25: 0 frames and three structural failures, namely `measured 0 frames`, `no boosting frames` and `no cruising frames`), the line is exactly `bench-bridge: verdict invalid exit 1: 0 frames of 300 needed, p99 n/a ms against 16.7 ms, 3 structural failures`.

The JSON field becomes `"verdict": VERDICTS[1 if failures else (2 if miss else 0)]`; nothing reads it (V20). The format is `^bench-bridge: verdict (ok|invalid|MISS) exit [012]: ` and contains neither `(` nor `)`. It therefore never matches the patterns that the recipe, 7m AC1 and M4.6rR3 AC7 count: `^bench-bridge: OK$`, `^bench-bridge: FAIL`, `^bench-bridge: frame ms` and `target p99 < 16.7: (ok|MISS))$` (V19). The exit-code expression, `MIN_FRAMES`, `P99_TARGET_MS`, `miss =` and every `Summary.summarize` call stay byte-identical (AC7). The recipe already prints every `^bench-bridge` line, so the verdict shows above the footer with no `Makefile` change.

## Acceptance criteria

Run from the implementation root. `export PATH="$PWD/runtime/bin:$PATH" A="AILANG=$PWD/runtime/bin/ailang"` first (`make runtime` if `runtime/` is absent). Define `deadline` and `drill` from the Drills section first. AC1 and AC8 run under the same `deadline` as the drills (900 s / 300 s), and their wrapper status is captured immediately: status 124 is INFRASTRUCTURE (a rig failure: re-run), never an accepted bench verdict or a completed recovery. A drill exit 1 on the fixed tree halts the row as a doc bug: it is neither a kill nor a rig failure. AC1–AC5 and AC8 need the GPU window; the controller or evaluator runs them.

| # | Criterion and command | Expected output |
|---|---|---|
| AC1 | `deadline "${DRILL_S:-900}" make capture-m4 $A > .godot/tmp/7l-ac1.out 2>&1; echo rc=$?; L=.godot/tmp/capture-m4.log; grep -c '^capture-m4: ok frame' $L; grep -c '^capture-m4: OK$' $L; grep -c '^capture-m4: FAIL' $L` | `rc=0`, `14`, `1`, `0` (the new self-test, CA and CB checks pass on the fixed tree) |
| AC2 | `drill "$PWD" CA` | `drill CA: make rc 2`, `drill CA: killed`; exit 0. For AC2–AC5, drill exit 4 (`INFRASTRUCTURE`) is a rig failure: re-run the drill. It is never a pass or a kill. |
| AC3 | `drill "$PWD" CB` | `drill CB: make rc 2`, `drill CB: killed` (14 cell FAILs, 14 frames) |
| AC4 | `drill "$PWD" CC` | `drill CC: make rc 2`, `drill CC: killed` (1 FAIL, 0 frames) |
| AC5 | `drill "$PWD" DB1` | `drill DB1: make rc 2`, `drill DB1: killed`. The log has exactly one `bench-bridge: verdict invalid exit 1: 0 frames of 300 needed, p99 n/a ms against 16.7 ms, 3 structural failures` and one `FAIL measured 0 frames (want >= 300)`; the footer reads `FAILED (exit 1:` (V25). |
| AC6 | After AC2–AC5, on the executor's committed tree: `git diff --quiet HEAD -- tools/m4_ship_capture.gd tools/m4_ship_bench.gd && find "${TMPDIR:-/tmp}" -maxdepth 1 -name 'stapledon-7l.*' \| wc -l` | rc 0 and `0` (the traps restored both files and removed every temp dir) |
| AC7 | `D=$(git diff -U0 origin/main -- tools/m4_ship_bench.gd); echo "$D" \| grep -cE '^-[^-]'; echo "$D" \| grep -cE '^-.*(summarize\|MIN_FRAMES\|P99_TARGET_MS\|miss = \|timing)'; echo "$D" \| grep -cF '1 if failures else (2 if miss else 0)'` | `5` (removed: lines 37, 67, 138, 143, 174 only), `0` (no p99, threshold or frame-count line touched), `3` (the exit expression: 1 removed, 2 added byte-identically in the `_stop` call and the JSON) |
| AC8 | `deadline "${BENCH_S_LIMIT:-300}" make bench SCENE=bridge $A > .godot/tmp/7l-b.out 2>&1; rc=$?; test "$rc" -ne 124 || { echo INFRASTRUCTURE; false; }; L=.godot/tmp/bench-bridge.log; test "$(grep -c '^bench-bridge: verdict ' $L)" -eq 1 && v=$(sed -n 's/^bench-bridge: verdict \([a-zA-Z]*\) exit \([012]\): .*/\1 \2/p' $L) && echo "$rc $v"` | one of `0 ok 0`, `2 MISS 2`, `2 invalid 1` (load-dependent; any other pairing fails). For the last two, `grep -c "^bench-bridge: FAILED (exit ${v#* }:" .godot/tmp/7l-b.out` prints `1` |
| AC9 | `grep -cF 'Only the worlds are reproducible, not the pixels' design_docs/planned/r1/m4-6rr3-ship-renders-bench-report.md` | `1` |
| AC10 | `make uid-guard lint-precision python-guard $A && git diff --check origin/main && echo gates-ok` | `gates-ok` (no new script, so no new `.uid`) |
| AC11 | `n=$(git diff --name-only origin/main \| wc -l); h=$(git diff --name-only origin/main \| grep -cxE 'Makefile\|mk/.*\|tools/m4_ship_golden\.gd\|tools/ship_ui_capture\.gd\|tests/display_audit\.gd\|demos/.*\|ui/.*'); echo "$n $h"` | `n` ≥ 3 (control), `h` = `0` |

## Risks and mitigations

- **The pixel compare in CB could be inexact.** Both sides come from the same PNG, through the same convert and Lanczos calls, on the same CPU, and the sheet is a lossless RGB8 PNG (colour type 2, V13), so equality is expected. If AC1 fails on the unmutated tree, compare the mean absolute difference per cell against a bound of 1/255 instead, and record the exact byte-difference count per cell in the sprint JSON. Any other change is a re-measure, not a pass.
- **The held surfaces can move.** CA reads `has_card`, and #344 and #351 hold `ui/ship_hud.gd`. Before AC1, the executor re-runs `gh api` on both PRs and `git log e94ed9b7..origin/main -- tools/m4_ship_capture.gd tools/m4_ship_bench.gd ui/ship_hud.gd`, and rebases if needed.
- **`make import` on a fresh clone leaves 5 untracked `*.translation` files** (`data/planets/trappist1_ps.*`, `data/starmap/truth/…`). They appeared on this run and were deleted. The executor must not commit them.
- **A drill that times out leaves `renders/m4/` partly deleted**, because the driver clears stale files first (seen in V28). AC1 runs last, and rebuilds the set.
- **A loaded rig makes AC8 `invalid`.** AC8 accepts any consistent pairing. A quiet run is row 7m-d's job, not this row's.

## Open questions

None. D-88 A covers this row: test hygiene inside an approved sprint, with no pillar below 0. (a) is deferred by measurement (`Makefile` held), not by choice. (c) takes the report path because pinning changes pixels.

## Files

| File | Change |
|---|---|
| `tools/m4_ship_capture.gd` | CA checks, `CRUISE_BETA_TOL`/`_near` with its self-test, the cruise check against the plan, `_sheet_layout()`. |
| `tools/m4_ship_bench.gd` | `VERDICTS`, `_stop(code, detail)` printing the verdict line, the JSON `verdict` word. |
| `design_docs/planned/r1/m4-6rr3-ship-renders-bench-report.md` | The reproducibility paragraph from (c). |
| `.ailang/state/sprints/sprint_R1-M4-JOURNEY.json` | A dated row-7l note: drill results, AC1 and AC8 outputs, (a) deferred on hold. |
| `design_docs/planned/r1/m4-7l-capture-followups.md` | This doc. |

## Verification log

Run in this clone at `e94ed9b7` on 2026-10-30, with AILANG v0.54.18 (`make runtime`) and Godot 4.7.2 in the unattended GPU session.

| # | Claim | Command | Result |
|---|---|---|---|
| V1 | Clone at origin/main, clean | `git log --oneline -1; git diff --name-only origin/main \| wc -l` | `e94ed9b7 Merge pull request #355…`; `0` |
| V2 | Held files | `gh api --paginate repos/sunholo-data/stapledons-godot/pulls/{344,351}/files --jq '.[].filename'`, then `grep -c` | totals 254 / 415 (control). `demos/ship_geometry_demo.gd` 1/1, `ui/ship_hud.gd` 1/1, `Makefile` 1/1; `m4_ship_capture` 0/0, `m4_ship_bench` 0/0, `m4-6rr3` 0/0, `sprint_R1-M4-JOURNEY` 0/0 |
| V3 | The capture-m4 recipe's checks | `sed -n 309,315p Makefile` | fails on rc ≠ 0, `SCRIPT ERROR:`, `^capture-m4: OK$` ≠ 1, any `^capture-m4: FAIL`, `ok frame` ≠ 14, PNG ≠ 15, manifest rows/uniques ≠ 15, worlds ≠ 14, `shasum -c` |
| V4 | `make test` reaches neither capture-m4 nor bench | `grep -h '^test:' Makefile mk/*.mk \| grep -c capture-m4` (and `-cw bench`, `-c python-guard`) | 49 `test:` lines; capture-m4 `0`, bench `0`, python-guard `1` (control) |
| V5 | The publish checks each file inside the upload loop | `grep -n 'test -s "\$\$f"' Makefile` | line 323 only: `test -s "$$f"; gcloud storage cp …` |
| V6 | The capture never reads the HUD | `grep -c has_card tools/m4_ship_capture.gd demos/ship_geometry_demo.gd` | `0` / `8` (control) |
| V7 | The sheet is saved, never re-read | `grep -c contact_sheet tools/m4_ship_capture.gd`; `git grep -nP '^\t\tvar row := 0 if frame\.view == "deck" else 1$'` | `1` (the save); the anchor is line 214 |
| V8 | The cruise β and plan values | `jq -r '.frames[]\|select(.state=="cruise_099")\|[.ship.beta,.journey.plan.cruise_beta,(.ship.beta==.journey.plan.cruise_beta)]' renders/m4/manifest.json` | `0.9900000000000004`, `0.99`, `false` (×2; diff 4.44e-16). Line 156 compares with the literal 0.99 |
| V9 | CA, CB and CC survived | `jq '.drills[]\|select(.id\|test("^C[ABC]$"))' eval_…M4.6rR3_round_1.json` | CA, CC, CB `SURVIVED (rc 0)`; control CE `KILLED` |
| V10 | capture-m4 is green at HEAD | `PATH=$PWD/runtime/bin:$PATH make capture-m4 AILANG=$PWD/runtime/bin/ailang` | rc 0; 14 `ok frame`, 0 `FAIL`, `14 renders in 121.0 s`, `capture-m4: OK` |
| V11 | The arrival card is up at frame 06 | Opened `renders/m4/06_arrived_acen_deck.png` | "Arrived" card (4.321 ly, Gap 3.749 yr, `Dismiss [Enter]`), hint "Press Enter to continue" |
| V12 | Dismissal is immediately observable | `sed -n 379,387p ui/ship_hud.gd; sed -n 1379,1381p demos/ship_geometry_demo.gd` | `hide_card` sets `leaving`; `has_card` returns `cards.has(id) and not leaving`; `dismiss_arrival` calls `hide_card("arrival")` |
| V13 | Sheet size and format | PNG IHDR of `renders/m4/contact_sheet.png` | 2276×366, colour type 2 (RGB8) |
| V14 | Run-to-run reproducibility | the same capture again; `cmp` worlds; `comm -3` of the sorted manifests | worlds byte-equal; PNGs differ 15/15 (all of 01–07 and the sheet) |
| V15 | The public set is stale | `curl` public `worlds.sha256` / `m4_manifest.sha256`; `diff` / `comm` against V10 | 28 differing world lines (14/14); 15/15 PNG hashes differ |
| V16 | The report has no caveat | `grep -ci reproducib; grep -c byte-equal` on the report | `0` / `3` (control) |
| V17 | Bench exit paths | `sed -n '36,38p;66,68p;138p;141,143p;174,177p' tools/m4_ship_bench.gd` | `quit(1)` at 37, `_stop(1)` at 67, `_stop(1 if failures else (2 if miss else 0))` at 143, `quit(code)` at 177; the JSON writes `"MISS" if miss else "ok"`, ignoring failures |
| V18 | Make returns 2 for either failure | `sed -n 547,548p Makefile`; a one-line Makefile with `exit 1` / `exit 0` | the recipe's failure branch is `exit 1`; make rc `2` / `0` (control) |
| V19 | Who counts bench lines | `git grep -c bench-bridge -- ':!design_docs' ':!.ailang/state/evaluations'`; sprint JSON AC1/AC7 text | Makefile 4, the driver 10, `tools/level_bench.gd` 1 (a comment), the sprint JSON 6; the patterns are the four quoted in (d) |
| V20 | Nothing reads the JSON `verdict` | `git grep -l 'bench-bridge\.json'`; `git grep -n '\.verdict' -- Makefile mk tools tests .github \| wc -l`; `git grep -c '"verdict"' tools/m4_ship_bench.gd` | readers: the sprint JSON and 7m docs, which read only `.docked_control.p99_ms`; `0`; `1` (the writer, control) |
| V21 | Where the M4.6rR3 docs are | `git ls-files \| grep m4-6rr3` | the design, sprint and report are all in `design_docs/planned/r1/` |
| V22 | The `.uid` files are tracked | `git ls-files tools/m4_ship_capture.gd.uid tools/m4_ship_bench.gd.uid` | both listed; no new script, so no new `.uid` |
| V23 | The drill shell is valid and refuses an unapplied mutation | the `drill` function extracted with `awk`, then `bash -n` / `sh -n`; `drill "$PWD" CC` and `drill "$PWD" XX` on the unedited tree | syntax ok; CC prints `drill: mutation did not change tools/m4_ship_capture.gd`, rc `3` (the const is not there yet); XX rc `2`; `git status` shows only this doc; `0` temp dirs left |
| V24 | No coreutils timeout on the rig; the perl deadline kills a stalled group | `command -v timeout gtimeout perl`; `deadline 3 sh -c "sleep 600 & echo \$! > p2; echo \$\$ > p1; wait"`; the same with `trap "" TERM`; `ps -o pid= -p` on `$$` (control), p1 and p2 | only `/usr/bin/perl` (5.34.1). Plain: rc `124` in 3 s, control pid printed, sh and sleep `[]`. TERM ignored: rc `124` in 9 s (KILL after the 5 s grace), both `[]`. Pass-through: `deadline 10 sh -c "exit 2"` gives `2`, `deadline 10 true` gives `0` |
| V25 | DB1 path, measured on the unedited tree | `grep -n '^const BENCH_S\|^const MIN_FRAMES\|^const P99_TARGET_MS' tools/m4_ship_bench.gd`; `BENCH_S := 30.0` → `0.0` with perl, then `deadline 300 make bench SCENE=bridge SCRATCH=$T/s`, restored and `cmp` clean | `30.0` (l.4), `16.7` (l.5), `300` (l.6). make rc `2` in 14 s; three FAILs (`measured 0 frames (want >= 300)`, `no boosting frames`, `no cruising frames`); `live transit 0 frames in 0.0 s`; docked control printed; 0 `SCRIPT ERROR`; footer `FAILED (exit 1:`; JSON `structural_failures 3`, `verdict "MISS"` (the (d) bug). The controller's run matches |
| V26 | The manifest lists deck before forward in each column | `jq -r '[.frames[].file]' renders/m4/manifest.json` after a fresh capture (rc 0, 14 ok) | 14 entries: `01_docked_deck`, `01_docked_forward`, … `07_arrived_home_deck`, `07_arrived_home_forward` |
| V27 | A failing capture prints one bare FAIL summary | `grep -n 'print("capture-m4: ' tools/m4_ship_capture.gd` | per-check `"capture-m4: FAIL " + what` (l.253); summary `"OK" if failures == 0 else "FAIL"` (l.258), so the bare `^capture-m4: FAIL$` appears exactly once |
| V28 | The drill's timeout path is bounded and clean | `cp` of the capture driver, then `DRILL_S=3 drill "$PWD" CA` on the unedited tree; `pgrep -f 'stapledon-7l\.'` at 2 s (control) and after; `cmp`; `find "$TMPDIR" -maxdepth 1 -name 'stapledon-7l.*'` | 3 pids during the run (control); `drill CA: make rc 124`, `INFRASTRUCTURE timeout after 3 s`, drill rc `4`, about 3 s; after: those pids gone, 0 `m4_ship_capture` processes; `cmp` identical; 0 temp dirs; `git status` shows only this doc |
| V29 | The early-stop gate sits after the self-test's insertion point and before the demo loads (controller, carve-out) | `sed -n '20,35p' tools/m4_ship_capture.gd` | `_run` opens at l.26; the output-dir check is l.28 and the stale-file cleanup l.29–31; the gate is l.32 `if failures:`, l.33 `_finish()`, l.34 `return`; the demo is loaded at l.36 (`demo = load("res://demos/ship_geometry_demo.tscn")…`) |
| V30 | `demo.ship_hud.has_card("arrival")` resolves (controller, carve-out) | `git grep -n ship_hud demos/ship_geometry_demo.gd \| head -5`; `grep -n '^var demo' tools/m4_ship_capture.gd`; `git grep -n 'func has_card' ui/` | `demos/ship_geometry_demo.gd:58: var ship_hud: ShipHud`, set up at l.252 (`ship_hud=ShipHud.new()…`); the driver's `var demo: Node` (l.15, dynamic access); `ui/ship_hud.gd:386: func has_card(id: String) -> bool:` |
| V31 | The capture log lands under `SCRATCH` (controller, carve-out) | `grep -n '^SCRATCH' Makefile`; `sed -n 310p Makefile` | `9:SCRATCH := .godot/tmp`; the `capture-m4` recipe writes `> $(SCRATCH)/capture-m4.log`, so the drills' `SCRATCH="$T/s"` puts the log at `$T/s/capture-m4.log` and the default is `.godot/tmp/capture-m4.log` |
| V32 | Line anchors (controller, carve-out) | `sed -n '1270p' demos/ship_geometry_demo.gd`; `sed -n '7p' design_docs/planned/r1/m4-6rr3-ship-renders-bench-report.md` | `ship_hud.hide_card("arrival")` (under `elif state == "committed":`); l.7 is the "Base URL … It holds 18 files" public-set paragraph |
| V33 | The clean-tree acceptance run is bounded and recovers (controller, carve-out) | `deadline` extracted from this doc with `awk`; `deadline 900 make capture-m4 AILANG=$PWD/runtime/bin/ailang`; then `deadline 5 make capture-m4 …`; `pgrep -fl m4_ship_capture` after, with `pgrep -fl claude` as the positive control | 900 s: rc `0` in 116 s, `14` ok frames, `1` OK. 5 s: rc `124` in 5 s; 0 `m4_ship_capture` processes afterwards (control: 1 match). The killed run leaves `renders/m4/` partly cleared; a bounded AC1 rebuilds it |

## Quorum log

- **Round 1** (2026-10-30T02:11:22Z): BLOCKED. gemini-4-argon PASS, with a non-blocking note on the CB fallback. gpt6-1-sol REJECT on the drill harness: GPU make ran without a deadline, so a hang would leave the mutation installed. oc-glm-5-3 REJECT on two points: DB1's expected verdict line was predicted, not measured; and the drill's total-FAIL count missed `_finish`'s bare summary line. The controller measured each premise first-party. Changes in this revision: the perl `deadline` wrapper (process-group TERM, then KILL, exit 124 → drill exit 4 INFRASTRUCTURE), proven by V24 and V28; DB1 and AC5 pinned to the measured path (V25), with the `n/a` p99 field defined; per-check FAILs counted with a trailing space plus exactly one bare summary (V27); the frame order recorded (V26); the CB fallback now records its byte-difference count. Scope, held files and everything else are unchanged.
- **Round 2** (2026-10-30T02:25:01Z): BLOCKED. gemini-4-argon PASS. gpt6-1-sol REJECT on the acceptance runs: AC1 and AC8 called GPU make outside the deadline wrapper. oc-glm-5-3 REJECT on unverified anchors: the line-32 early-stop gate that AC4's 0 frames depends on, `demo.ship_hud` resolution, the capture log's `SCRATCH` location and two line anchors. Surfaces: acceptance-run bounding; Verification-log anchors. Neither disputes the design direction and both carried a concrete `proposed_fix`, so the controller applied the reviewers' fixes under the narrow-refinement carve-out (gate 2) instead of a third designer run: AC1 wrapped in `deadline "${DRILL_S:-900}"`, AC8 in `deadline "${BENCH_S_LIMIT:-300}"`, status 124 classified as INFRASTRUCTURE, a drill exit 1 on the fixed tree declared a doc bug, and V29–V33 measured first-party (V29: the gate is l.32–34, before the demo load at l.36; V33: bounded AC1 rc 0 in 116 s, and rc 124 in 5 s with no capture process left). Nothing else changed. Routed to the planner without a third quorum round.
