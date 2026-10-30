# Sprint addendum: R1-M4-JOURNEY row 7l, capture follow-ups

**Status:** Planned, mission iteration 59 planner, 2026-10-30, HEAD `71b6f313` (= `origin/main` `e94ed9b7` plus the approved design commit; the implementation tree is unedited). One milestone `M4.6rR3_7l_CAPTURE_FOLLOWUPS` under the approved sprint `R1-M4-JOURNEY` (D-22/D-66, D-88 A).
**Design:** [m4-7l-capture-followups.md](m4-7l-capture-followups.md) — the contract, read in full: Acceptance criteria, the Drills section (`deadline` + `drill` functions), the Verification log (V1–V33) and the Quorum log (rounds 1–2; controller carve-out fixes already applied; no third round).
**Scope:** design items (b), (c) and (d) only. Item **(a) is deferred on hold** — the root `Makefile` is held by open attended PRs #344 and #351 (design V2) — and is **not planned here**: no `Makefile` edit, no drill script committed (it could not be wired in anyway, design §Drills).
**Budget:** ~50 LOC: `tools/m4_ship_capture.gd` ~38 (CA 2, CC 8, CB 26, the sheet call 1), `tools/m4_ship_bench.gd` ~10, the M4.6rR3 report one paragraph. Pinned AILANG v0.54.18 (`runtime/bin`), Godot 4.7.2. Registry reuse: none — GDScript tools and docs only, no package-like capability.
**Ownership:** every GPU step is controller/evaluator-only, never the sandboxed executor: `make capture-m4`, `make bench SCENE=bridge`, the RED mutations, drills CA/CB/CC/DB1, and AC1–AC5 plus AC8. The executor edits the allowlisted files and runs the local ACs (AC6, AC7, AC9, AC10, AC11); the controller reruns every AC outside the sandbox and owns the merge gates.

## Reality check against HEAD

Every design line anchor was re-measured at `71b6f313` in this clone (commands and outputs in Verification below): CA line 62, CC line 156 and CB line 214 of `tools/m4_ship_capture.gd`; the `if failures:` gate at lines 32–34 before the demo load at line 36; bench consts at `tools/m4_ship_bench.gd:4–6`, `quit(1)` at :37, `_stop(1)` at :67, the JSON `"verdict"` at :138, `_stop(1 if failures …)` at :143, `func _stop(code)` at :174; the report's public-set paragraph is line 7. Both `.uid` files are tracked; no new script means no new `.uid`. The drill mutations behave as designed on scratch copies. **No design premise proved false on this tree.**

## Tasks (test-first, in order)

1. **Preflight (controller):** refresh `origin/main`; `git log e94ed9b7..origin/main -- tools/m4_ship_capture.gd tools/m4_ship_bench.gd ui/ship_hud.gd` must be empty, and `gh api` on PRs #344/#351 must still not list the two tool files (design Risks). Pause for rebase/recount if either moved. Define `deadline` and `drill` (copied verbatim below).
2. **RED — prove CA and CB survive on the unedited tree (controller/evaluator, GPU):** apply the CA mutation with the drill's exact perl edit against a saved copy, run `make capture-m4`, restore; repeat with the CB mutation. Each run must return make rc 0 with 14 `ok frame` lines — the checks that would catch them do not exist yet. This reproduces premise V9 first-hand before fixing it; no kill is claimed at RED. (CC's mutation cannot apply yet: no `CRUISE_BETA_TOL` const exists, so a CC drill exits 3 on the unedited tree — V23 holds, re-verified on a scratch copy.)
3. **GREEN (b) CA (~2 LOC, executor):** at `tools/m4_ship_capture.gd` lines 61–62, insert design §(b) CA's exact pair: after `await _views(6, "arrived_acen")` add `_check(demo.ship_hud.has_card("arrival"), "arrival card not shown at arrived_acen")` (the positive control), keep `demo.dismiss_arrival()`, then add `_check(not demo.ship_hud.has_card("arrival"), "arrival card still up after dismiss")`.
4. **GREEN (b) CC (~8 LOC, executor):** add `const CRUISE_BETA_TOL := 1e-12` with the design's 2-ulp comment and `func _near(a: float, b: float) -> bool`; insert the two self-test `_check`s at the top of `_run`, above the stale-file cleanup at line 29 (so they run before the line-32 gate; AC4's 0 frames rely on this, V29); rewrite the line-156 cruise check to design §(b) CC's form — `ship.phase == "cruising" and _near(beta, float(world.journey.plan.cruise_beta)) and _near(float(world.journey.plan.cruise_beta), 0.99) and glow > 0.0 and demo.sky_state == "live"`.
5. **GREEN (b) CB (~27 LOC, executor):** add `_sheet_layout()` exactly per design §(b) CB — reload `contact_sheet.png` from disk, assert its size against the literal `Vector2i(2276, 366)`, derive each cell from the file name (`col = int(name.substr(0, 2)) - 1`, `row = 1 if name.ends_with("_forward.png") else 0`), rebuild the thumbnail with the same `load_from_file`/`convert(FORMAT_RGB8)`/`resize(THUMB, LANCZOS)` calls, compare `sheet.get_region(Rect2i(Vector2i(col * (THUMB.x + GAP), row * (THUMB.y + GAP)), THUMB)).get_data() == thumb.get_data()` failing as `contact sheet cell <name> at col <c> row <r> differs`, and assert 14 distinct `col * 2 + row` keys (`contact sheet cells <n> (want 14 distinct)`) — then call it after `_sheet()`.
6. **GREEN (c) (one paragraph, executor):** insert the design §(c) reproducibility paragraph verbatim, directly after line 7 of `design_docs/planned/r1/m4-6rr3-ship-renders-bench-report.md`. No pixel pinning, no republication of the public set.
7. **GREEN (d) (~10 LOC, executor):** in `tools/m4_ship_bench.gd`: add `const VERDICTS := ["ok", "invalid", "MISS"]`; give `_stop` a detail argument so it prints `bench-bridge: verdict %s exit %d: %s` % [VERDICTS[code], code, detail] before its unchanged `quit(code)`; line 37 `quit(1)` → `_stop(1, "demo not ready")`; line 67 `_stop(1)` → `_stop(1, "departure not committed")`; line 143 → `_stop(1 if failures else (2 if miss else 0), "%d frames of %d needed, p99 %s ms against %.1f ms, %d structural failures" % [times.size(), MIN_FRAMES, "n/a" if times.is_empty() else "%.3f" % timing.p99_ms, P99_TARGET_MS, failures])`; the JSON becomes `"verdict": VERDICTS[1 if failures else (2 if miss else 0)]`. Exit codes, the p99 computation, `MIN_FRAMES`, `P99_TARGET_MS`, `miss =` and every `Summary.summarize` call stay byte-identical (AC7).
8. **Drills in order CA, CB, CC, DB1 (controller/evaluator, GPU):** each must exit 0 with `drill <id>: make rc 2` and `drill <id>: killed`. Drill exit 4 is INFRASTRUCTURE (a rig failure: re-run, never a kill); a drill exit 1 on the fixed tree halts the row as a doc bug (design Acceptance preface). DB1 overwrites `res://.godot/tmp/bench-bridge.json` whatever SCRATCH is, so AC8 runs after DB1.
9. **AC1 last (controller/evaluator, GPU):** a failed or timed-out drill leaves `renders/m4/` partly cleared (design Risks, V28), so the bounded AC1 run is the final GPU step and rebuilds a good set.
10. **Close-out (executor):** append the dated row-7l note (drill results, AC1/AC8 outputs, "(a) deferred on hold") to this feature's `notes` in the sprint JSON; run AC6, AC7, AC9–AC11 locally; hand AC1–AC5, AC8 and the gates to the controller/evaluator.

## Drill and deadline functions

Copied verbatim from the design's Drills section — the executor runs these exact functions (the 7q pattern): hardened shape with explicit ROOT, one parent `mktemp -d` with a single restoring trap, `cmp` proof of the applied mutation (else exit 3), make's rc captured and asserted, counts asserted with `test`, no `!`, `|| exit 1` on every check, verification through the make target with SCRATCH redirected; `deadline` maps expiry to 124 → drill exit 4 INFRASTRUCTURE.

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

The CB count of 14 relies on the manifest order — deck before forward in every column (V26). DRILL_S defaults: 900 s for a capture (measured 121 s, V10), 300 s for the bench (14 s for DB1, V25).

## Acceptance criteria

Run from the implementation root: `export PATH="$PWD/runtime/bin:$PATH"` and `A="AILANG=$PWD/runtime/bin/ailang"` first (`make runtime` if `runtime/` is absent), and define `deadline`/`drill` above first. AC1 and AC8 run under the same `deadline` (900 s/300 s); wrapper status 124 is INFRASTRUCTURE (a rig failure: re-run), never an accepted result; a drill exit 1 on the fixed tree halts the row as a doc bug. AC1–AC5 and AC8 need the GPU window — controller/evaluator-only.

- **AC1:** `deadline "${DRILL_S:-900}" make capture-m4 $A > .godot/tmp/7l-ac1.out 2>&1; echo rc=$?; L=.godot/tmp/capture-m4.log; grep -c '^capture-m4: ok frame' $L; grep -c '^capture-m4: OK$' $L; grep -c '^capture-m4: FAIL' $L` — Expected: `rc=0`, `14`, `1`, `0` (the new self-test, CA and CB checks pass on the fixed tree).
- **AC2:** `drill "$PWD" CA` — Expected: `drill CA: make rc 2`, `drill CA: killed`; exit 0. For AC2–AC5, drill exit 4 (`INFRASTRUCTURE`) is a rig failure: re-run the drill. It is never a pass or a kill.
- **AC3:** `drill "$PWD" CB` — Expected: `drill CB: make rc 2`, `drill CB: killed` (14 cell FAILs, 14 frames).
- **AC4:** `drill "$PWD" CC` — Expected: `drill CC: make rc 2`, `drill CC: killed` (1 FAIL, 0 frames).
- **AC5:** `drill "$PWD" DB1` — Expected: `drill DB1: make rc 2`, `drill DB1: killed`. The log has exactly one `bench-bridge: verdict invalid exit 1: 0 frames of 300 needed, p99 n/a ms against 16.7 ms, 3 structural failures` and one `FAIL measured 0 frames (want >= 300)`; the footer reads `FAILED (exit 1:` (V25).
- **AC6:** after AC2–AC5, on the executor's committed tree: `git diff --quiet HEAD -- tools/m4_ship_capture.gd tools/m4_ship_bench.gd && find "${TMPDIR:-/tmp}" -maxdepth 1 -name 'stapledon-7l.*' \| wc -l` — Expected: rc 0 and `0` (the traps restored both files and removed every temp dir).
- **AC7:** `D=$(git diff -U0 origin/main -- tools/m4_ship_bench.gd); echo "$D" \| grep -cE '^-[^-]'; echo "$D" \| grep -cE '^-.*(summarize\|MIN_FRAMES\|P99_TARGET_MS\|miss = \|timing)'; echo "$D" \| grep -cF '1 if failures else (2 if miss else 0)'` — Expected: `5` (removed: lines 37, 67, 138, 143, 174 only), `0` (no p99, threshold or frame-count line touched), `3` (the exit expression: 1 removed, 2 added byte-identically in the `_stop` call and the JSON).
- **AC8:** `deadline "${BENCH_S_LIMIT:-300}" make bench SCENE=bridge $A > .godot/tmp/7l-b.out 2>&1; rc=$?; test "$rc" -ne 124 || { echo INFRASTRUCTURE; false; }; L=.godot/tmp/bench-bridge.log; test "$(grep -c '^bench-bridge: verdict ' $L)" -eq 1 && v=$(sed -n 's/^bench-bridge: verdict \([a-zA-Z]*\) exit \([012]\): .*/\1 \2/p' $L) && echo "$rc $v"` — Expected: one of `0 ok 0`, `2 MISS 2`, `2 invalid 1` (load-dependent; any other pairing fails). For the last two, `grep -c "^bench-bridge: FAILED (exit ${v#* }:" .godot/tmp/7l-b.out` prints `1`.
- **AC9:** `grep -cF 'Only the worlds are reproducible, not the pixels' design_docs/planned/r1/m4-6rr3-ship-renders-bench-report.md` — Expected: `1`.
- **AC10:** `make uid-guard lint-precision python-guard $A && git diff --check origin/main && echo gates-ok` — Expected: `gates-ok` (no new script, so no new `.uid`).
- **AC11:** `n=$(git diff --name-only origin/main \| wc -l); h=$(git diff --name-only origin/main \| grep -cxE 'Makefile\|mk/.*\|tools/m4_ship_golden\.gd\|tools/ship_ui_capture\.gd\|tests/display_audit\.gd\|demos/.*\|ui/.*'); echo "$n $h"` — Expected: `n` ≥ 3 (control), `h` = `0`.

## Gates

- **In-repo lint gates (AC10), executor-local then controller-rerun:** `make uid-guard lint-precision python-guard AILANG=$PWD/runtime/bin/ailang` and `git diff --check origin/main`, both rc 0.
- **`ai-live-guard` (controller-run):** `make ai-live-guard AILANG=$PWD/runtime/bin/ailang` (`mk/ai.mk:423`) uses scratch `git init`/`git add`, so the no-commit executor defers the complete target to the controller, as on 7q. This row adds no live path; expected unchanged green.
- **Merge gates (controller/rig):** green `rig/full` via `tools/rig_check.sh <PR>` on the implementation head, plus the GitHub fast tier (`make ci-fast`). `make test` reaches neither `capture-m4` nor `bench` (design V4), which is why the drills run by hand; no pixel changes, so no golden/render gate is added.
- **Evaluation (controller):** independent evaluator, generator ≠ judge, 100 points / 70 to pass, output in `.ailang/state/evaluations/`; the evaluator reruns the drills and ACs first-hand.

## Files / do-not-touch

Executor allowlist — exactly these five paths: `tools/m4_ship_capture.gd`, `tools/m4_ship_bench.gd`, `design_docs/planned/r1/m4-6rr3-ship-renders-bench-report.md`, `.ailang/state/sprints/sprint_R1-M4-JOURNEY.json` (only this feature's notes during execution), `design_docs/planned/r1/m4-7l-capture-followups-sprint.md` (this plan).

Held — must not be touched: `Makefile`, `mk/*`, `demos/*`, `ui/*`, `tools/m4_ship_golden.gd`, `tools/ship_ui_capture.gd`, `tests/display_audit.gd` (AC11's regex counts any touch and must print `h` = 0). Also out of scope: the approved design doc itself; any republish of the public render set; dust-flash/card-fade pixel pinning (changes pixels, needs Mark's S1 sign-off); the bench's exit codes, p99 computation and existing lines (row 7m-d depends on them). A fresh-clone `make import` can leave 5 untracked `*.translation` files — never commit them (design Risks).

## Pause points

- Planner stops at these two artifacts; the controller owns the handoff, all git writes and both merge statuses. The executor must not commit and snapshots nothing (single milestone).
- If the refreshed origin moved any anchor surface (`tools/m4_ship_capture.gd`, `tools/m4_ship_bench.gd`, `ui/ship_hud.gd`), pause and re-verify before RED; do not widen scope.
- CB pixel equality: both sides come from the same PNG through the same convert/Lanczos calls on the same CPU (design Risks). If AC1 fails on the unmutated tree, fall back to a mean-absolute-difference bound of 1/255 per cell and record the exact byte-difference count per cell in the sprint JSON notes; any other failure is a re-measure, not a pass.
- A loaded rig can make AC8 `invalid`: AC8 accepts any consistent pairing; a quiet `ok` run is row 7m-d's job, not this row's.

## Verification (planner, 2026-10-30, HEAD 71b6f313)

Every claim above was checked first-hand in this clone. No GPU make, `make bench`, `make capture-m4` or `make test` was run (forbidden to the planner); drill mutations were tried only on scratch copies under `.godot/tmp/7l-planner/`, never on the working tree. AILANG is pinned v0.54.18 per CLAUDE.md; `runtime/bin` use is unchanged by this row.

| Claim | Command (abbreviated) | Result |
|---|---|---|
| HEAD = origin/main + design commit only | `git log --oneline -1; git diff --name-only origin/main` | `71b6f313 design(7l): …`; one file (`...m4-7l-capture-followups.md`); AC11 held-file regex on the current diff prints `0` |
| CA anchor | `sed -n '61,63p' tools/m4_ship_capture.gd \| cat -et` | l.62 `^I^I^Idemo.dismiss_arrival()$` (three tabs) between `_views(6, …)` and `if await _helm()` |
| CC anchor | `sed -n '154,157p' tools/m4_ship_capture.gd` | l.156 `_check(ship.phase == "cruising" and absf(beta - 0.99) < 1e-12 and …, state + " values")`, 2-ulp comment above |
| CB anchor | `sed -n '212,216p' tools/m4_ship_capture.gd \| cat -et` | l.214 `^I^Ivar row := 0 if frame.view == "deck" else 1$` (two tabs); the save is the only other `contact_sheet` use |
| Gate before demo load | `sed -n '20,37p' tools/m4_ship_capture.gd` | `func _run` l.26; stale cleanup l.29–31; `if failures:`/`_finish()`/`return` l.32–34; demo load l.36 (V29 holds) |
| FAIL print sites; HUD reads | `grep -n 'print("capture-m4: ' tools/m4_ship_capture.gd`; `grep -c has_card tools/m4_ship_capture.gd demos/ship_geometry_demo.gd` | per-check FAIL l.253, bare summary l.258 (V27); `0`/`8`, so the capture reads no HUD today (V6) |
| Bench anchors | `sed -n '4,6p;36,38p;66,68p;136,144p;172,178p' tools/m4_ship_bench.gd` | `BENCH_S/P99_TARGET_MS/MIN_FRAMES` = `30.0`/`16.7`/`300` at l.4–6; `quit(1)` l.37; `_stop(1)` l.67; `"verdict": "MISS" if miss else "ok"` l.138 (writer, `grep -c '"verdict"'` = 1); `_stop(1 if failures else (2 if miss else 0))` l.143; `_stop(code: int){… quit(code)}` l.174–177 (V17/V25 hold) |
| Report anchor | `sed -n '7p' design_docs/planned/r1/m4-6rr3-ship-renders-bench-report.md`; `grep -ci reproducib; grep -c byte-equal` | l.7 is the public-set paragraph; `reproducib` 0, `byte-equal` 3 (V16 holds) |
| SCRATCH and log paths | `sed -n '9p' Makefile; sed -n '310p;546,548p' Makefile` | `SCRATCH := .godot/tmp`; capture recipe writes `$(SCRATCH)/capture-m4.log`; bench recipe writes `$(SCRATCH)/bench-bridge.log`, greps every `^bench-bridge` line (so the new verdict prints through with no Makefile change), failure footer `FAILED (exit $$rc: …)` then `exit 1` → make rc 2 (V18/V19 hold) |
| Gate targets exist | `grep -n '^uid-guard:\|^lint-precision:\|^python-guard:' Makefile; grep -n '^ai-live-guard:' mk/ai.mk` | Makefile:981, :258, :977; mk/ai.mk:423 |
| `.uid` tracked; no new script | `git ls-files tools/m4_ship_capture.gd.uid tools/m4_ship_bench.gd.uid` | both listed (V22 holds) |
| Drill shell valid | extract design lines 86–144 → `sh -n`, `bash -n` | both pass |
| Mutations behave as designed | the drill's four perl edits on scratch copies of both tool files, then `cmp -s` | CA changed, CB changed, DB1 changed; CC unchanged on the unedited tree → drill rc 3 path (V23 holds) |
| `deadline` is feasible | `command -v timeout gtimeout perl; perl -v` | no `timeout`/`gtimeout`; `/usr/bin/perl` 5.34.1 (V24 holds) |
| Sprint JSON shape | `jq '.features \| length'`; `grep -n '"features":'` | 19 features (→ 20); `.features` opens at l.124; this feature is appended last with keys id/depends_on/estimated_loc/files/acceptance_criteria/design_doc/sprint_plan/passes/notes; nothing else touched |

Not re-verifiable at planner time (GPU or artifact facts; taken on the design's first-party evidence and re-measured by the controller during execution): V9's SURVIVED outcomes, V10 timing, V11's screenshot, V13's sheet pixels and the 2276×366 size, V14/V15's manifest comparisons, V25's DB1 path, V26's frame order, V28/V33. `renders/m4/` is absent in this fresh clone, so V26's on-disk order check is the controller's to repeat after a capture.

Planner performed no implementation edit, no git write, no approval request; the only writes are this addendum and the one appended feature.
