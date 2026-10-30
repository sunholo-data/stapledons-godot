# ISM map layer: three M4.6pR3 drill survivors, one killed, one recorded as equivalent, one already killed (row 7n(b))

**Status:** Planned (mission iteration 60, designer, 2026-10-30). **Release:** r1. **Milestone:** M4.6pR3 follow-ups, charter queue row **7n(b)** (clause 4 hygiene) inside the approved sprint `R1-M4-JOURNEY` (D-22/D-66).
**Priority:** P2 (follow-up backlog). Test and code-comment only.
**Implements:** [charter](../../stapledon-mission.md) row 7n (b); the follow-up of [m4-6pr3-live-transit-frame-cost.md](m4-6pr3-live-transit-frame-cost.md) and its evaluation [`eval_R1-M4-JOURNEY_M4.6pR3_round_1.json`](../../../.ailang/state/evaluations/eval_R1-M4-JOURNEY_M4.6pR3_round_1.json) (drills M3, M4 and M5; non-blocking findings 2 and 3). The [relativity spec](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md) is untouched. Rows 7n (a), (c), (d) and (e) are out of scope.
**Depends on:** D-88 A (test hygiene inside an approved sprint needs no stop); Godot 4.7.2 (`OS.add_logger`, V8). No package, sim, protocol, scene, shader or player-visible change. Headless only: no GPU window needed.
**Estimated LOC:** about **17**: `tests/test_ism_layer.gd` +13, `ui/ism_layer.gd` +2 comment lines, one 2-line changelog fragment.
**Evidence:** the Verification log below, run first-hand at `b2e6c110` (origin/main) in this clone, with every mutant run in an APFS copy of it (`cp -cR`), never in the clone itself.

## Game vision alignment

Scored against [core pillars](https://github.com/sunholo-data/stapledons-design/blob/main/vision/core-pillars.md).

| Pillar | Relevance | Score | Notes |
|---|---|---:|---|
| Choices Are Final | 0 | 0 | No input, intent or commit path changes. |
| The Game Doesn't Judge | 0 | 0 | No player-facing copy. |
| Time Has Emotional Weight | 0 | 0 | Clocks and journey timing untouched. |
| The Ship Is Home | 0 | 0 | The navigation window behaves as today. |
| Grounded Strangeness | 0 | 0 | The ISM layer draws the same media whenever it can be seen (no pixel changes). |
| We Are Not Built For This | 0 | 0 | No crew or consequence change. |
| Hard sci-fi authenticity (spec) | 0 | 0 | No physics. The kill guards against a per-tick error flood in transit (V7), which is about engineering, not physics. |
| **Net** | | **0** | **Go under D-88 A:** test hygiene inside the D-66-approved sprint; no pillar is negative. |

## Problem

The M4.6pR3 fix (`ui/ism_layer.gd:254–266`, `draw()`) returns early while the overlay's window is hidden. It also connects the window's `visibility_changed` to `overlay.queue_redraw`, guarded by `is_connected`:

```gdscript
	var host := overlay.get_window()
	if host != null and not host.visible:
		if not host.visibility_changed.is_connected(overlay.queue_redraw):
			host.visibility_changed.connect(overlay.queue_redraw)
		return 0
```

Its tests are `tests/test_ism_layer.gd:91–133`: hidden window, shown window, and a hide/show cycle that counts `get_connections()`. The evaluator's drills left three mutants that the suite does not separate from the fix. Each was re-run here first-hand, on the pristine tree, through `make map-ism-test` (V6, V9, V13):

| Mutant | Edit | Pristine `make map-ism-test` | Production consequence |
|---|---|---|---|
| **MG** | delete the `is_connected` guard (connect on every call) | rc 0, `19 passed, 0 failures`; the log has one `ERROR: Signal 'visibility_changed' is already connected to given callable 'Control::queue_redraw' in that object.` (`object.cpp:1562`) | Godot refuses the duplicate, so the count stays 1. But it logs one error with a GDScript backtrace **per hidden redraw** (V7). Every tick in transit queues one, so that is about 20 errors a second. **Not equivalent.** |
| **MN** | `if host != null and not host.visible:` → `if not host.visible:` | rc 0, `19 passed, 0 failures`, 0 errors | None reachable: see (2). |
| **MS** | delete both lines (no connection at all) | rc 2, `17 passed, 2 failures`: the hidden-window and hide/show checks, i.e. the `is_connected` and connection-count assertions | None observable in Godot 4.7.2, which redraws a shown window's canvas by itself (V14). |

**Premises checked against the row and the brief.**
- The row says MG "stays 19/0". **Confirmed** (V6), so the claim is not stale. The existing `redraw_connections == 1` check is **not** a killer, because Godot refuses a duplicate connect without the reference-counted flag, and the count stays 1.
- The row calls MG and MN "equivalent in production". **Half wrong.** MN is equivalent (V5, V10, V12). MG is not: it floods the log (V7).
- The row says the redraw-on-show case "passes without the connection". **Confirmed** (V13, V14).
- The evaluation cites `galaxy_map.gd:1424` as the only caller. The line has moved: it is now `ui/galaxy_map.gd:1407` (V5).

## Goals and non-goals

**Goals.** Kill MG with one named FAIL through `make map-ism-test` (and `gmake`). Record MN as equivalent, with the measured reason, in a comment beside the check. Record why MS is guarded only by the structural assertions, in a comment beside the shown-window case. Change no behaviour.
**Non-goals.** No edit to `Makefile` (held by #344 and #351, V2), `mk/*`, `ui/galaxy_map.gd`, `demos/*` or any scene. No behaviour change in `ui/ism_layer.gd`. Row 7n (a), the open-map face cache, waits on its own files. No new test file (so no `.uid`).

## Design

### (1) MG: KILL with an error log over the hidden phases

The observable is the error Godot logs on a refused duplicate connect. A test can see it: Godot 4.7.2 exposes `OS.add_logger(Logger)`, and `Logger._log_error` receives engine errors (`error_type` 0) and script errors (`error_type` 2) (V8). The edit to `tests/test_ism_layer.gd`, exactly as measured (V15, V16):

After `var passes := 0` (line 13):

```gdscript
## 7n(b): every engine or script error raised while installed (OS.add_logger). A second
## visibility_changed.connect to the same callable is refused (the count stays 1) but logs one.
class ErrorLog extends Logger:
	var lines: Array[String] = []
	func _log_error(_function: String, _file: String, _line: int, code: String, rationale: String, _editor_notify: bool, _error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		lines.append(rationale if rationale != "" else code)
```

Directly before `# A CanvasLayer keeps its overlay visible-in-tree…` (line 91):

```gdscript
	var errors := ErrorLog.new()
	OS.add_logger(errors)
```

Directly before the closing `print("ism-layer: …")` (line 133):

```gdscript
	OS.remove_logger(errors)
	check("M4.6pR3 hidden redraws log no engine error (7n-b: a repeated connect would)", errors.lines.is_empty(), str(errors.lines.slice(0, 1)))
```

The window is scoped to the M4.6pR3 section, so start-up noise on another host cannot trip it. On this rig the whole pristine log has 0 `ERROR` lines (V3). The failure detail prints the first captured message. **Kill:** under MG the hide-again draw (a hidden draw with the connection already made) logs exactly one refused connect. The run then reads `19 passed, 1 failures` with one `FAIL  M4.6pR3 hidden redraws log no engine error … ["Signal 'visibility_changed' is already connected …"]`, and make rc is 2 (V16). The fixed tree reads `20 passed, 0 failures` (V15).

### (2) MN: RECORD AS EQUIVALENT

`get_window()` is null only for a node outside the tree. In Godot 4.7.2 that includes nodes added during a `SceneTree` script's `_init`, before the first frame (V10). The `draw` signal never fires for an out-of-tree Control: 0 draws, and 1 draw once it is added (V12). The one non-test caller is `GalaxyMap._draw_overlay` (`ui/galaxy_map.gd:1407`), which is connected to `_overlay.draw` (`:237`) (V5). So in use, `host` is never null.

A test can still reach the path, but only through a direct call outside the tree, and neither outcome there is a contract worth pinning (V11, camera in the tree, overlay not):

- **Today:** the null check lets the call fall through to drawing. It returns 797, sets `last_drawn` to all 15 media, and logs 1,728 engine errors (`Drawing is only allowed inside this node's _draw()…`). With the camera out of the tree as well, it returns 373 and logs 17,777 errors.
- **Under MN:** one SCRIPT ERROR (`Invalid access to property or key 'visible' on a base object of type 'null instance'`). The function aborts, and the typed `-> int` returns 0. A return-value assertion therefore cannot tell MN apart; only an error count can, and that count would pin the 1,728-error behaviour as "correct".

Making the case meaningful would need a behaviour change: `if host == null: return 0` turns the 1,728 errors into 0. It is rejected here because it changes a path no caller takes, and this row adds no contract. Instead, add two comment lines in `ui/ism_layer.gd` after line 261, directly above `var host := overlay.get_window()`:

```gdscript
	# get_window() is null only outside the tree, where the draw signal never fires (the one
	# caller is GalaxyMap._draw_overlay); `host != null` is defensive, equivalent in use (7n-b).
```

The drill's MN mutant expects **rc 0 and `20 passed, 0 failures`** on the fixed tree. That is the recorded-equivalent signature. If MN ever fails, the equivalence premise has changed, so re-open this row.

### (3) MS: already KILLED; the structural assertions are the right guard

MS fails 2 checks today (V13). In Godot 4.7.2, showing an embedded window with the overlay under a `CanvasLayer` redraws the overlay once, connected or not. The topology matches production (`ui/galaxy_map.gd:233–238`). The draws coalesce, so a draw count is +1 either way (V14). The connection therefore has no behavioural signature on show. Asserting that it exists (`is_connected`, and a count of exactly 1) is the sharpest honest check.

A sharper-looking alternative was measured and rejected. Emitting `visibility_changed` by hand while the window is hidden gives +1 draw with the connection and +0 without it (V14). It would kill MS too, but it adds no kill the two existing assertions miss, and it tests a synthetic event. Add a comment so no one reads the shown-window case as the connection's guard. It goes in `tests/test_ism_layer.gd`, directly before the `window.show()` that precedes `check("M4.6pR3 shown window …")` (line 114):

```gdscript
	# Godot redraws a shown window's canvas by itself: this case passes with the connect deleted
	# (7n-b). The is_connected and connection-count assertions are what guard the connection.
```

### Changelog

`changelogs/unreleased/2026-10-30-7nb-ism-layer-survivors.md`: "Tests: the ISM map layer's hidden-window test now fails on a repeated `visibility_changed` connect (row 7n(b)); the `host != null` check is recorded as equivalent in use."

### Drills: a function in this doc, not a committed script

`make map-ism-test` already runs in `make test` (`Makefile:50`), and a drill script would need a `Makefile` edit to be wired in (held, V2). So, as in 7l and 7q, the executor and the evaluator run this function. Its shape is hardened:

- an explicit ROOT;
- one parent `mktemp -d` with a single trap that restores the file and removes the directory;
- a `cmp` proof that the mutation changed the file, else exit 3;
- make's return code is captured and asserted, and a deadline (rc 124) or any rc other than 0 or 2 is **exit 4, INFRASTRUCTURE**;
- counts are asserted with `test`, there are no `!` assertions, and every check carries `|| exit 1`.

It verifies **through the make target**, with `SCRATCH` redirected into the temp directory, under `make` (3.81) or `gmake` (4.4.1). `deadline` is iteration 59's perl process-group wrapper, unchanged (there is no `timeout` or `gtimeout` on the rig). A pristine run takes about 1 s; the default bound is 120 s.

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
drill() (  # drill ROOT MUTANT [MAKE]: exit 0 measured signature, 1 wrong signature, 2 usage, 3 mutation not applied, 4 INFRASTRUCTURE
  set -eu
  ROOT=${1:?explicit checkout ROOT required}; mutant=${2:?MG, MN or MS}; MK=${3:-make}
  cd "$ROOT" || exit 2; ROOT=$(pwd -P); F=ui/ism_layer.gd
  test -f "$F" || exit 2
  T=$(mktemp -d "${TMPDIR:-/tmp}/stapledon-7nb.XXXXXX") || exit 2
  trap 'if test -f "$T/orig.gd"; then cp "$T/orig.gd" "$ROOT/$F"; fi; rm -rf "$T"' EXIT
  trap 'exit 130' INT; trap 'exit 143' TERM HUP
  cp "$F" "$T/orig.gd" || exit 2
  case "$mutant" in
    MG) perl -0 -i -pe 's/\t\tif not host\.visibility_changed\.is_connected\(overlay\.queue_redraw\):\n\t\t\thost\.visibility_changed\.connect\(overlay\.queue_redraw\)\n/\t\thost.visibility_changed.connect(overlay.queue_redraw)\n/' "$F" || exit 1
        want_rc=2; summary='^ism-layer: 19 passed, 1 failures$'
        fails='^  FAIL  M4\.6pR3 hidden redraws log no engine error \(7n-b: a repeated connect would\) \[".*already connected.*"\]$'; nfail=1 ;;
    MS) perl -0 -i -pe 's/\t\tif not host\.visibility_changed\.is_connected\(overlay\.queue_redraw\):\n\t\t\thost\.visibility_changed\.connect\(overlay\.queue_redraw\)\n//' "$F" || exit 1
        want_rc=2; summary='^ism-layer: 18 passed, 2 failures$'
        fails='^  FAIL  M4\.6pR3 (hidden-window: no media drawn|hide/show cycle: one redraw connection)'; nfail=2 ;;
    MN) perl -i -pe 's/^\tif host != null and not host\.visible:$/\tif not host.visible:/' "$F" || exit 1
        want_rc=0; summary='^ism-layer: 20 passed, 0 failures$'; fails='^  FAIL'; nfail=0 ;;
    *) exit 2 ;;
  esac
  if cmp -s "$T/orig.gd" "$F"; then echo "drill: mutation did not change $F"; exit 3; fi
  set +e
  deadline "${DRILL_S:-120}" "$MK" map-ism-test SCRATCH="$T/s" > "$T/make.out" 2>&1
  rc=$?
  set -e
  echo "drill $mutant ($MK): make rc $rc"
  case "$rc" in
    0|2) ;;
    124) echo "drill $mutant: INFRASTRUCTURE timeout"; exit 4 ;;
    *) echo "drill $mutant: INFRASTRUCTURE rc $rc"; exit 4 ;;
  esac
  test "$rc" -eq "$want_rc" || exit 1
  L="$T/s/map-ism-test.log"; test -s "$L" || exit 1
  test "$(grep -c 'SCRIPT ERROR' "$L")" -eq 0 || exit 1
  test "$(grep -c -E "$summary" "$L")" -eq 1 || exit 1
  test "$(grep -c '^  FAIL' "$L")" -eq "$nfail" || exit 1
  test "$(grep -c -E "$fails" "$L")" -eq "$nfail" || exit 1
  if test "$rc" -eq 2; then test "$(grep -c '^map-ism-test: FAILED$' "$T/make.out")" -eq 1 || exit 1; fi
  echo "drill $mutant ($MK): measured signature"
)
```

Test-first order: on the unedited tree, MG through `make map-ism-test` gives rc 0 and `19 passed, 0 failures` (RED: it survives, V6). Then add the test edit and the two comments, and run the drills. A drill exit 1 on the fixed tree is a doc bug that halts the row; it is neither a kill nor a rig failure. Exit 4 is a rig failure: re-run.

## Acceptance criteria

Run from the implementation root after the edit. Define `deadline` and `drill` from the Drills section first. `make` is `/usr/bin/make` 3.81, and `gmake` is Homebrew GNU Make 4.4.1. Both are headless; the target needs no GPU window.

| # | Criterion and command | Expected output |
|---|---|---|
| AC1 | `deadline 120 make map-ism-test; echo rc=$?; L=.godot/tmp/map-ism-test.log; grep -c '^ism-layer: 20 passed, 0 failures$' $L; grep -cE 'SCRIPT ERROR\|^ERROR' $L` | `rc=0`, `1`, `0` |
| AC2 | AC1 with `gmake` in place of `make` | `rc=0`, `1`, `0` |
| AC3 | `drill "$PWD" MG; echo exit=$?` | `drill MG (make): make rc 2`, `drill MG (make): measured signature`, `exit=0` (MG killed: one named FAIL carrying the "already connected" message) |
| AC4 | `drill "$PWD" MS; echo exit=$?` | `drill MS (make): make rc 2`, `drill MS (make): measured signature`, `exit=0` (still killed: 2 FAILs, 18 passed) |
| AC5 | `drill "$PWD" MN; echo exit=$?` | `drill MN (make): make rc 0`, `drill MN (make): measured signature`, `exit=0` (recorded equivalent: 20/0) |
| AC6 | `for m in MG MS MN; do drill "$PWD" $m gmake; echo exit=$?; done` | three `measured signature` lines (`gmake`), make rc `2`, `2`, `0`, and `exit=0` three times |
| AC7 | Count before AC3 and after AC6: `ls "$TMPDIR" \| wc -l`; then `git diff --quiet HEAD -- ui/ism_layer.gd && find "${TMPDIR:-/tmp}" -maxdepth 1 -name 'stapledon-7nb.*' \| wc -l` | the before and after counts are equal; rc 0 and `0` (the traps restored the file and removed every temp dir) |
| AC8 | `D=$(git diff -U0 origin/main -- ui/ism_layer.gd); echo "$D" \| grep -E '^[-+][^-+]' \| grep -cvE '^\+[[:space:]]*#'; echo "$D" \| grep -cE '^\+[[:space:]]*#'` | `0` (no code line changed), `2` |
| AC9 | `grep -cE 'OS\.add_logger\(errors\)\|OS\.remove_logger\(errors\)\|passes with the connect deleted' tests/test_ism_layer.gd` | `3` |
| AC10 | `make uid-guard lint-precision AILANG=$PWD/runtime/bin/ailang && git diff --check origin/main && echo gates-ok` | `gates-ok` (no new script, so no new `.uid`) |
| AC11 | `git diff --name-only origin/main \| grep -cvxE 'ui/ism_layer\.gd\|tests/test_ism_layer\.gd\|changelogs/unreleased/2026-10-30-7nb-ism-layer-survivors\.md\|design_docs/planned/r1/m4-7nb-ism-layer-survivors(-sprint)?\.md\|\.ailang/state/sprints/sprint_R1-M4-JOURNEY\.json'`; then for both PRs `gh api --paginate repos/sunholo-data/stapledons-godot/pulls/$p/files --jq '.[].filename' \| grep -cxE 'ui/ism_layer\.gd\|tests/test_ism_layer\.gd'` (p = 344, 351) | `0`; then `0` and `0` |
| AC12 | `make test` on the rig (`tools/rig_check.sh <PR>`), the definition of done | `rig/full` green |

## Sub-milestones and estimates

One step, about 17 LOC, headless, under an hour. (1) RED: MG survives on the unedited tree. (2) Make the test edit and add both comments, plus the fragment. (3) AC1–AC11. (4) PR and `rig/full`.

## Risks and mitigations

- **Logger callbacks can come from other threads.** In this section only the main thread logs (0 errors on the fixed tree, 5 repeats, V15). If a future Godot logs from a render thread here, the failure detail names the message, and that is a real error to look at, not noise.
- **Another host could log an unrelated engine error inside the section** (for example, a Linux headless renderer). The window covers only the M4.6pR3 section, not start-up. `map-ism-test` is in `make test` (the rig), not in `ci-fast` (V20).
- **A Godot bump could make duplicate connects silent, or reference-count them.** MG would then survive again, and AC3 would print a wrong signature (drill exit 1). Re-measure at the bump.
- **The held set can move.** Before editing, re-run AC11's `gh api` part and `git log b2e6c110..origin/main -- ui/ism_layer.gd tests/test_ism_layer.gd mk/ism.mk` (0 commits at design time, V1).

## Open questions

None. D-88 A covers this row: test hygiene inside an approved sprint, with no pillar below 0. MN's equivalence is a measured finding, and the alternative that would make it testable is a behaviour change on an unused path, rejected above.

## Files

| File | Change |
|---|---|
| `tests/test_ism_layer.gd` | `ErrorLog` (`extends Logger`), installed around the M4.6pR3 section, and one new check; one comment before the shown-window case. 19 → 20 checks. |
| `ui/ism_layer.gd` | Two comment lines above `var host := overlay.get_window()`. No code change. |
| `changelogs/unreleased/2026-10-30-7nb-ism-layer-survivors.md` | The fragment from Design. |
| `.ailang/state/sprints/sprint_R1-M4-JOURNEY.json` | A dated row-7n(b) note: RED, AC1–AC7 outputs. |
| `design_docs/planned/r1/m4-7nb-ism-layer-survivors.md` | This doc. |

## Verification log

Run on 2026-10-30 at `b2e6c110` with Godot 4.7.2. "Scratch" is an APFS copy of the clone (`cp -cR`) in one `mktemp -d`. Every mutant ran there, and the file was restored by `cp` after each run.

| # | Claim | Command | Result |
|---|---|---|---|
| V1 | Clone at origin/main; nothing since touches the three files | `git log --oneline -1 origin/main`; `git log --oneline b2e6c110..origin/main -- ui/ism_layer.gd tests/test_ism_layer.gd mk/ism.mk \| wc -l` | `b2e6c110 Merge pull request #357…`; `0`. (The clone also holds 5 untracked `*.translation` files from the import; they are not this row's and must not be committed.) |
| V2 | Held files | `gh api --paginate repos/sunholo-data/stapledons-godot/pulls/{344,351}/files --jq '.[].filename'`, then `grep -cxF` per path, and `sort -u` of both | 254 / 415 files (control); union 415, equal to the brief's list. `Makefile` 1/1; `ui/ism_layer.gd`, `tests/test_ism_layer.gd`, `mk/ism.mk`, `ui/galaxy_map.gd` and this doc 0/0 (also 0 in `/tmp/stap_i60_held.txt`) |
| V3 | Baseline script | `godot --headless --path . --script tests/test_ism_layer.gd` (scratch) | rc 0, `ism-layer: 19 passed, 0 failures`, 0 `SCRIPT ERROR`, 0 `ERROR:` lines; it matches the controller's baseline |
| V4 | Baseline through the target | `deadline 120 make map-ism-test SCRATCH=…`; the same with `gmake` (pristine scratch) | both rc 0, `19 passed, 0 failures` |
| V5 | The one production caller | `git grep -n "ism_layer.draw\|layer.draw" -- '*.gd'`; `git grep -n "_draw_overlay\|_overlay.draw" ui/galaxy_map.gd`; `sed -n 225,245p ui/galaxy_map.gd` | only `ui/galaxy_map.gd:1407`, inside `_draw_overlay` (`:1354`), connected at `:237`; the overlay sits under a `CanvasLayer` (`:233–238`). `tools/ism_capture.gd` and `tests/test_ism_surfaces.gd` never call `draw`. The evaluation's `:1424` is stale |
| V6 | MG survives today; the count check does not kill it | the MG perl edit (as in the drill), then `deadline 120 make map-ism-test SCRATCH=…` (pristine scratch) | rc 0, `19 passed, 0 failures`, 0 FAIL, 1 `already connected` line (`ERROR: Signal 'visibility_changed' is already connected to given callable 'Control::queue_redraw' in that object.`, `at: connect (core/object/object.cpp:1562)`, backtrace `draw (res://ui/ism_layer.gd:264)`) |
| V7 | MG logs once per hidden redraw | scratch probe: hidden window as in the test, 1 + 5 `queue_redraw`s, each awaited; a `Logger` counts errors | base: 6 draws, 0 errors, 1 connection. MG: 6 draws, **5** errors (`ERR_INVALID_PARAMETER` … `already connected`), 1 connection. In transit, `refresh()` queues one redraw a tick at 20 Hz ([M4.6pR3 Problem](m4-6pr3-live-transit-frame-cost.md)) |
| V8 | `OS.add_logger` and `Logger._log_error` work in 4.7.2 headless | the same probe: `class Catch extends Logger` with the 8-argument `_log_error`, `OS.add_logger(catch)` | engine errors arrive with `error_type` 0 and their rationale; script errors (MN) with `error_type` 2; the console still prints them; `godot --version` = `4.7.2.stable.official.ed1daf0bf` |
| V9 | MN survives today | the MN perl edit, then `make map-ism-test` (pristine scratch) | rc 0, `19 passed, 0 failures`, 0 errors |
| V10 | `get_window()` is null out of the tree, including during a `SceneTree._init` | probe: `Control.new().get_window()`; a Control added to a `SubViewport` under `root` inside `_init`, called before any `await` | `<Object#null>`, `is_inside_tree()` false, in both cases |
| V11 | Out-of-tree direct call: no outcome worth pinning | probe after `await process_frame`: in-tree camera, out-of-tree overlay, `layer.draw(loose, cam, f)`, with a `Logger` | base: returns `797`, `last_drawn` 15, **1,728** engine errors (first: `Drawing is only allowed inside this node's _draw()…`). MN: returns `0` (typed int after the abort), `last_drawn` 0, 1 SCRIPT ERROR (`Invalid access to property or key 'visible' on a base object of type 'null instance'.`). With the camera out of the tree too: base `373`, 17,777 errors (9,531 `!is_inside_tree()`, 7,871 `Camera is not inside scene`, 375 `!drawing`) |
| V12 | The `draw` signal never fires out of the tree | probe: out-of-tree Control, draw counter, `queue_redraw`, 2 frames; then `root.add_child`, 2 frames | `0` draws; then `1`, and `get_window()` non-null |
| V13 | MS is killed today only by the structural assertions | the MS perl edit, then `make map-ism-test` (pristine scratch) | rc 2, `17 passed, 2 failures`: `FAIL  M4.6pR3 hidden-window…` and `FAIL  M4.6pR3 hide/show cycle…`; the shown-window case passes |
| V14 | Godot redraws a shown window by itself; a hand emit would separate MS | probe (V7 setup): `window.show()`, 2 frames; hide, show, 2 frames; `window.visibility_changed.emit()` while hidden | show: +1 draw and 15 media, for base and MS alike (coalesced, never +2); hide/show with no explicit redraw: +1, 15, both. Emit while hidden: base +1, MS +0 |
| V15 | The fixed tree passes through both makes, stably | the Design edits applied in scratch; `deadline 120 make map-ism-test SCRATCH=…`, the same with `gmake`; 5 × the bare script | both rc 0, `ism-layer: 20 passed, 0 failures`, 0 `SCRIPT ERROR` or `ERROR` lines; 5/5 runs `20 passed, 0 failures`, 0–1 s each |
| V16 | The drills give the designed signatures | `drill "$S/p" MG\|MS\|MN make`, then `… gmake` (fixed scratch) | MG: make rc 2, `19 passed, 1 failures`, one FAIL with the `already connected` detail. MS: rc 2, `18 passed, 2 failures`. MN: rc 0, `20 passed, 0 failures`. Six runs, `measured signature`, exit 0 each |
| V17 | The drills leave nothing behind | `ls "$TMPDIR" \| wc -l` before and after the six drills; `git status --short ui tests` | `5025` → `5025` (counting the scratch dir); only the two intended edits are modified in scratch |
| V18 | Gates on the fixed tree | `make uid-guard lint-precision SCRATCH=… AILANG=$PWD/runtime/bin/ailang`; `git diff --check`; the AC8 pipeline | rc 0: `uid-guard: ok (352 .uid files)`, `lint-precision: ok …`; diff-check clean; `0` non-comment changed lines in `ui/ism_layer.gd` |
| V19 | Tools | `command -v make gmake perl`; `make --version`; `gmake --version` | `/usr/bin/make` (GNU Make 3.81), `/opt/homebrew/bin/gmake` (4.4.1), `/usr/bin/perl`; no `timeout`/`gtimeout` (iteration 59, V24) |
| V20 | Where the target runs, and what makes it pass | `grep -n '^test:\|^ci-fast:' Makefile`; `sed -n 45,48p mk/ism.mk` | `map-ism-test` is in `test` (`Makefile:50`) and not in `ci-fast` (`:48`). The target needs rc 0 and `^ism-layer: [1-9][0-9]* passed, 0 failures$`; otherwise it prints `map-ism-test: FAILED` and make exits 2 |
