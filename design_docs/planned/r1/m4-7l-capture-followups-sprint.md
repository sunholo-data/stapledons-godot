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


## Amendment iter64: row 7l(a)

Mission iteration 64, planner, 2026-11-02. This amendment supersedes the iteration-59 plan's Makefile prohibition and deferred-(a) wording **only for row 7l(a)**. Everything above remains the landed (b)–(d) history (PR #356); CA/CB/CC/DB1, GPU captures and benches are not re-planned or re-run. Authority: the design's iteration-64 Addendum, including both iteration-64 Quorum rounds, AC-a14, A-V21/A-V22 and V34/V35; D-66 approved sprint and D-88 A test hygiene. There are no human-decision gates and no new approval request. The mission controller owns the next role, PR, rig/full, fast tier, merge and independent evaluation. This planner edits and commits only the two planning artifacts and does not push or dispatch another agent.

One cohesive feature: `M4.6rR3_7la_ATOMIC_PUBLISH`, `passes: false`. Goal: reject any locally incomplete or invalid 18-file set before the first upload, from the same positional list later uploaded; retain the destination and cache-control bytes. Remote upload failure remains outside this row's atomicity guarantee. Example/fixture coverage is the seven synthetic cases in the single new shell test; no separate example file or drill script. Registry reuse: **none**; shell/Make orchestration of an existing recipe, no package-like capability and no registry search needed. No AILANG code, Python code, runtime/pin change or new `.uid`.

Estimate: 110 added physical lines: the exact designed test is **95** lines, and the designed Makefile splice plus the round-2 `ci-fast` edit measures **+15/−9** using a generated in-memory diff (+14/−8 for the recipe/test block, plus one changed prerequisite line). Plan/state documentation is additional. One executor session, about 30–60 minutes including RED, focused checks and bounded drills; no whole-suite velocity estimate is useful for this small shell change. Rig/full is a separate controller stage.

### Reality check at HEAD (first-hand)

Measured at `d1cf07f71e0dfcdb6f3af48521e1bc9748a4dd10` on `mission/stapledon-iter64-7la`; local `origin/main` is `6d92d2cb96f4f7324b618da99297caeb666decf0`. Three design commits (`fc00624b`, `8b640806`, `d1cf07f7`) follow it. Initial `git status --short` was empty; `git diff --name-only origin/main` listed only the design doc. The recipe and test anchors have **not drifted** from A-V3/A-V7. `tools/test_m4_publish.sh` does **not** exist (neither tracked nor on disk); neither the new target nor `M4_PUBLISH_DIR` exists.

`nl -ba Makefile | sed -n '330,338p'` measured this exact base recipe (line numbers are evidence; splice by text):

```make
330: capture-m4-publish: ## maintainers (gcloud): verify and upload the 18-file 3D-ship S1 set to the public refs/m4_ship_s1 bucket path
331: 	@set -eu; test "$$(ls renders/m4/*.png | wc -l | tr -d ' ')" = 15; \
332: 	  test "$$(wc -l < renders/m4/m4_manifest.sha256 | tr -d ' ')" = 15; \
333: 	  test "$$(cut -d' ' -f1 renders/m4/m4_manifest.sha256 | sort -u | wc -l | tr -d ' ')" = 15; \
334: 	  (cd renders/m4 && shasum -a 256 -c m4_manifest.sha256 > /dev/null); \
335: 	  n=0; for f in renders/m4/*.png renders/m4/manifest.json renders/m4/m4_manifest.sha256 renders/m4/worlds.sha256; do \
336: 	    test -s "$$f"; gcloud storage cp --cache-control="public, max-age=300" "$$f" "gs://stapledons-voyage-assets/refs/m4_ship_s1/$${f##*/}" > /dev/null; n=$$((n+1)); done; \
337: 	  test $$n = 18; echo "capture-m4-publish: uploaded 18 files"
338: .PHONY: capture-m4-publish
```

`rg -n '^(ci-fast:|test:)' Makefile` measured the following (all 15 `test:` lines, including the complete long list):

```text
22:test: kerr-oracle
50:ci-fast: deps python-guard uid-guard lint-precision strict parity-v2 parity parity-gr replay crew-sync-check crew-parity lore-import-check ## GitHub fast tier (clean Linux): lock, policy lints, strict VM, parity, replay golden, crew parity, lore manifest
52:test: python-guard uid-guard lint-precision deps starmap-assets import physics sim ui lore-test codex-test lore-import-check lore-check news-lint news-test replay parity-v2 strict similar-test rng-ref wd-vm catalogue-vm catalogue-main catalogue-bytes catalogue-stats star-catalogue-test bright-test companions-test starmap-test truth-test starmap-truth-audit starmap-consistency starmap-consistency-large test-bright-audit sky-vm extract-test destar-test tools-test star-names area-test validate-areas interior-test m4-smoke transit-test trappist1-test parity-m4 session-audit-test codex-unlocks geodesic-oracle lens-assets lens-lut-check parity-gr ism-oracle-check ism-data-verify ism-compat ism-determinism dust-flash-test map-ism-test ism-lore-drafts in-world-voice-check ## everything that runs without a GPU window
126:test: crew-sync-check
131:test: crew-faces-check
147:test: crew-bridge-test
152:test: crew-events-check
156:test: crew-console-test
165:test: crew-hold-test
169:test: crossing-review-test
211:test: crew-perf
214:test: crew-parity
254:test: export-filter-audit
1091:test: ship-demo-ci
1141:test: loading-jump-test
1437:test: import-keep-check
```

`/usr/bin/make` is GNU Make 3.81; `/opt/homebrew/bin/gmake` is GNU Make 4.4.1. The narrowed-path dependency audit from A-V22 was repeated: `perl shasum make mktemp sed awk grep sort cut wc tr ls rm mkdir mv chmod cat` all resolve under `/usr/bin:/bin`. This is macOS evidence only. Source re-checks confirm A-V21: `.github/workflows/ci.yml:7–12` defaults `workflow_call.full` to true, :21 uses `ubuntu-latest`, :61 runs `make ci-fast`, :65 runs the full suite; `release.yml:21` calls that workflow for plain release tags. V34/V35 remain source-pinned at `Makefile:569` (`$(SCRATCH)/bench-bridge.log`) and `tools/m4_ship_bench.gd:132` (literal `res://.godot/tmp/bench-bridge.json`). No bench was run, and neither is relevant to executing (a).

**PR ownership finding — UNINFORMATIVE UNDER SANDBOX.** `gh pr list --state open` returned rc 1, `error connecting to api.github.com`. For each last-known PR **371, 373, 374, 375**, both `gh pr diff <n> --name-only` and `gh pr diff <n> --allow-escape-sequences` returned the same rc 1. Therefore the current open PR set, whether any touches the recipe or `ci-fast:`, and current Makefile hunks cannot be certified here. A-V2's older #371 hunk `@@ -505,9 +505,31 @@` and #373 hunk `@@ -18,10 +18,16 @@` are design history, not this planner's measurements. Do not infer that the hold remains lifted. No GitHub app/browser fallback was used.

Controller/executor preflight must repeat **before any implementation edit**:

```sh
gh pr list --state open
# For every PR number returned, not just the four historical numbers:
gh pr diff <n> --name-only
gh pr diff <n> --allow-escape-sequences
```

Read every Makefile patch hunk (`diff --git a/Makefile b/Makefile` through the next file header), including its `@@` range and context; record which hunks touch `capture-m4-publish`, `renders/m4`, its surrounding block or `ci-fast:`. Search each full diff for `capture-m4-publish|renders/m4|^[-+]ci-fast:` and inspect adjacent context. Zero matches alone is insufficient if a hunk overlaps the recipe by position. Record a genuine zero as such only after `gh` succeeds. Any overlapping or changed PR, recipe drift, or unavailable `gh` is a STOP for controller re-measurement; never splice through unknown ownership. Refresh/rebase is controller-owned; re-run anchors and base guards after any rebase.

### Base gates and RED findings (planner-run)

Every executable base check below was run before editing the planning files. The new target is expected RED; `uid-guard`, `python-guard` and whitespace checks **must** be green at base. A sandbox verdict provides no evidence for sockets/GPU; this row needs neither, nor Godot. All fixture makes ran under a fake-only gcloud PATH. No real `gcloud`, capture, upload, whole `make test`, `make ci-fast`, rig job or background process was started.

| Gate | Measured base result and disposition |
|---|---|
| AC-a1/a2, target existence | With the body's `deadline 400`, `make -s capture-m4-publish-test` and `gmake -s capture-m4-publish-test` each return **2**, `No rule to make target ...`. Expected RED, not an implementation verdict. |
| New test on the unfixed recipe | Private copy of base `Makefile` + all `mk/` includes; add only the variable, replace literal `renders/m4` within that old recipe with `$(M4_PUBLISH_DIR)`, and wire the exact 95-line designed script/target. No validation fix. `deadline 400 make -s -C <copy> capture-m4-publish-test` returns **2**, script rc 1, `FAILED (12 of 14 cases)`, `ok complete` twice. **FINDING / expected RED**, table below. Both GNU versions actually exercise every case. |
| AC-a3 | `make -pnq test` and `gmake -pnq test` membership counts **0, 0**; standalone `test:` line count **0**. Expected RED until wiring. Query only; no suite execution. |
| AC-a4/a5 | All five exact addendum `drill "$PWD" <mutant>` calls return **2** at base: script absent. Unavailable pre-GREEN, neither kills nor survivors. Extracted functions and script pass `sh -n` and `bash -n` individually. |
| AC-a6 | `git diff --quiet HEAD -- Makefile tools/test_m4_publish.sh` rc **0**; bounded temp-prefix search count **0**. Green at base; repeat on the controller's committed implementation tree. |
| AC-a7 | Unchanged public-path/cache-control count **1**; default variable count **0**. Default is expected RED until added. |
| AC-a8 | Exact source-order awk prints **ORDER-BAD**. **FINDING / expected RED**: presence check is on the upload line, no worlds-count pre-check. |
| AC-a9 | Both greps error rc **2**, script absent. Expected unavailable until script added. |
| AC-a10 | `make uid-guard python-guard && git diff --check origin/main && echo gates-ok`: rc **0**, `uid-guard: ok (401 .uid files)`, `python-guard: ok (19 allowlisted, 0 awaiting AILANG port)`, `gates-ok`. Separate `git diff --check` also rc **0**, no output. These must stay green; no workaround permitted for base guard failures. |
| AC-a11 | Original design allowlist prints **0** outside files, **0** changed code files at base (only design differs from origin/main). The code control must become 2 after implementation. The plan omission is D1 below. |
| AC-a12 | No implementation PR/head or rig/full record yet: controller-only, not runnable at planning time. Source route and actual log assignment were read, not executed. |
| AC-a13 | Probe setup, body's deadline and make call attempted at base: rc **2** in **0 s**, missing target, timeout signature count **0**, private tmp entry count **1** (`xcrun_db`). Expected timeout cannot be tested before target exists; the temp entry independently exposes D2 below. Probe stub never executed. |
| AC-a14 | Source membership count **0**, expected RED until added. Linux job/log unavailable without implementation PR and network; **UNINFORMATIVE UNDER SANDBOX**, no Linux pass claimed. |
| Process assertions for drills/probe | `pgrep -fx 'sleep 617'`, `pgrep -fx 'sleep 618'` and a direct private-path query error `sysmond service not found; Cannot get process list`, rc **3**. A downstream `wc -l` prints 0 but is **UNINFORMATIVE UNDER SANDBOX**, never proof of no process. Re-run outside sandbox. |

The RED run's exact measurements per **each** GNU version (3.81 and 4.4.1); every failure had `pre-check lines 0`:

| Case | Recipe rc | Fake uploads / well-formed lines | Test |
|---|---:|---:|---|
| complete | 0 | 18 / 18 | ok |
| worlds-missing | 2 | 17 / 17 | FAIL |
| worlds-empty | 2 | 17 / 17 | FAIL |
| worlds-short | 0 | 18 / 18 | FAIL |
| manifest-missing | 2 | 15 / 15 | FAIL |
| png-missing | 2 | 0 / 0 | FAIL (missing named pre-check signature) |
| hash-mismatch | 2 | 0 / 0 | FAIL (missing named pre-check signature) |

### Design defects found by the planner

**D1 — AC-a11 cannot pass after the required sprint amendment.** Its four-file allowlist omits `design_docs/planned/r1/m4-7l-capture-followups-sprint.md`. At base its outside-file count is 0; after this required edit the exact original command prints **1**, naming that plan as the sole excluded file. A planning commit does not remove it from `git diff origin/main`. Proposed minimal fix: add only `design_docs/planned/r1/m4-7l-capture-followups-sprint\.md` to that regex; preserve the independent code-file count of **2**. The gate table and feature below explicitly carry this **proposed D1 correction**, pending controller disposition; the original design is not edited. Until ratified, AC-a11 is blocked by a design defect, not passed by ignoring the file.

**D2 — zero-private-temp assertions encounter Apple's make shim cache.** On this host, a fresh private `TMPDIR` followed solely by `env TMPDIR="$Q/tmp" /usr/bin/make --version` returns rc 0 and creates **`xcrun_db`**. AC-a13 at base likewise leaves that one entry despite never running the new script. The addendum drill's after-make zero-entry check would fail for the same reason. This is a measured host artifact, not a test-script leak and not evidence to waive cleanup. Proposed minimal fix: on macOS, resolve `/usr/bin/xcrun --find make` once **before** private-temp runs, prepend its directory to PATH, and keep all zero-entry assertions. Here it resolves `/Library/Developer/CommandLineTools/usr/bin/make`; running that executable with fresh private TMPDIR prints **GNU Make 3.81** and leaves **0** entries. Controller must ratify and repeat the actual drills/probe on the unsandboxed host before adopting this preflight. Linux needs no Apple adjustment. No test/recipe redesign or zero-entry suppression is proposed.

The process-list error and GitHub access failure above are sandbox limitations, not product defects. The existing `pgrep | wc -l` shape can mask a process-list failure; the mandatory process preflight below prevents treating that output as evidence. No other design command defect was established. In particular, +15/−9 rather than +14/−8 is explained by the required round-2 `ci-fast` line edit, not scope growth.

### Ordered tasks — RED before GREEN

1. **Preflight and disposition (controller, then executor).** Resolve D1/D2, obtain successful fresh PR ownership evidence including `ci-fast:`, check recipe against the numbered base block, confirm script absent, and run `make uid-guard python-guard`, `git diff --check origin/main`, `git diff --check`. Any base guard RED is a FINDING and STOP, not a workaround. Confirm functional `pgrep` outside the sandbox before running any cleanup assertions. There are no assets/runtime prerequisites to fetch.
2. **RED first (executor; about 10 minutes).** Create only `tools/test_m4_publish.sh` verbatim from the Addendum's 95-line test block. In `Makefile` add the fixed-default `M4_PUBLISH_DIR := renders/m4`, use that variable inside the **otherwise unchanged old recipe**, and add the standalone `test: capture-m4-publish-test`, target invoking `@sh tools/test_m4_publish.sh "$(CURDIR)"` and `.PHONY` membership. This is test injection, not the pre-check fix. Run the single script through `deadline 400 make -s capture-m4-publish-test`, then through `gmake`, capturing rc immediately and complete logs. Require the measured RED signature above: complete green on both inner makes, the four partial/truncated cases FAIL with 17/17/18/15 fake uploads, 12/14 total FAIL because the old PNG/hash checks also lack named failures. Never accept just missing-target RED. Record it in this new feature's notes. No direct maintainer publish call.
3. **GREEN (executor; about 10 minutes).** Replace the old recipe by the exact Addendum Design block (avoid duplicating wiring from step 2). Set the 18 paths once; presence/non-empty loop first; chained path/PNG/manifest/unique/worlds14/hash checks second; upload loop from that same positional list last. Preserve bucket/cache bytes; keep `:=`. Add `capture-m4-publish-test` exactly once to `ci-fast:` at the measured line 50, immediately before its `##` comment. Do not modify the line-52 list or other recipes. Re-run AC-a1/a2: 14 ok, no FAIL or INFRASTRUCTURE, one final OK, rc 0. Do not weaken signatures to get GREEN.
4. **Targeted validation and sensitivity (executor; about 10–30 minutes).** Run AC-a3/a7/a8/a9/a10 and source part of AC-a14; run all five hardened drills in the order `inloop`, `noupload`, `deadcapture`, `nopositive`, `stall`, each through both outer makes; run hardened AC-a13; check AC-a6 against a committed implementation tree (controller commits first) and ratified AC-a11. Run only this shell test and these focused gates, never the whole `make test`, `make ci-fast`, Godot, GPU or network upload. A sandbox-blocked process check is UNINFORMATIVE UNDER SANDBOX: hand it to the controller, leave passes false.
5. **Close-out (executor/controller).** Executor appends dated RED/GREEN, make versions, every AC verdict and drill timing to this new feature's notes and preserves other objects. The controller commits implementation by explicit filenames, re-runs gates outside sandbox, opens the PR, runs AC-a12 and the CI-log half of AC-a14, and obtains independent evaluation (generator ≠ judge). Only controller sets `passes: true` after rig/full and required evidence are green. This planner stops after its two-file planning commit; no automatic executor dispatch or push.

### Drill setup and invocations

Use a fresh `/bin/sh` so the historical (b)–(d) `drill` function is not accidentally called. The following are the body's unchanged `deadline` and **only the Addendum's** 93-line drill; copied verbatim. The script's separate deadline includes its TERM/INT/HUP forwarding line (A-V20); do not replace that script wrapper with the body's shorter one. Limits stay 10 s probe / 20 s fixture / 400 s outer, no environment-configurable shortening and no background jobs.

Process preflight: capture `pgrep -fx 'stapledon-7la-process-probe-no-match'` to a temporary log and capture rc immediately; only rc 1 (no matches, working process service) permits process assertions. Rc 3 here means STOP and **UNINFORMATIVE UNDER SANDBOX**. If D2 is ratified on macOS, first resolve the real make and prepend its directory to PATH; record both make versions again. Do not silently ignore `xcrun_db`.

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
drill() (  # exit 0 expected outcome, 1 unexpected outcome, 2 usage, 3 mutation not applied, 4 INFRASTRUCTURE
  set -eu
  ROOT=${1:?explicit checkout ROOT required}; mutant=${2:?inloop, noupload, deadcapture, nopositive or stall}
  cd "$ROOT" || exit 2; ROOT=$(pwd -P)
  test -f Makefile || exit 2; test -f tools/test_m4_publish.sh || exit 2
  case "$mutant" in inloop|noupload|deadcapture|nopositive|stall) ;; *) exit 2 ;; esac
  S=${DRILL_S:-400}  # above the script's own worst case (2 probes x 10 s + 14 makes x 20 s), so the inner deadlines fire first
  P=$(mktemp -d "${TMPDIR:-/tmp}/stapledon-7la.XXXXXX") || exit 2
  trap 'rm -rf "$P"' EXIT
  trap 'exit 130' INT; trap 'exit 143' TERM HUP
  mkdir "$P/w" "$P/w/tools" "$P/tmp" || exit 2
  cp Makefile "$P/w/Makefile" || exit 2; cp -R mk "$P/w/mk" || exit 2
  cp tools/test_m4_publish.sh "$P/w/tools/test_m4_publish.sh" || exit 2
  MK=$P/w/Makefile; TS=$P/w/tools/test_m4_publish.sh
  case "$mutant" in
    inloop)  # restore the old shape: no pre-check loop, no worlds count, test -s back inside the upload loop
      perl -i -ne 'if (/^\t  for f; do test -s "\$\$f" \|\| \{ echo "capture-m4-publish: FAILED before any upload: \$\$f missing or empty"; exit 1; \}; done; \\$/) { $a++; next }
        if (/^\t  test "\$\$\(wc -l < "\$\$d\/worlds\.sha256" \| tr -d . .\)" = 14 && \\$/) { $b++; next }
        $c++ if s/^\t  n=0; for f; do gcloud /\t  n=0; for f; do test -s "\$\$f"; gcloud /; print;
        END { exit(($a == 1 && $b == 1 && $c == 1) ? 0 : 3) }' "$MK" || exit 3 ;;
    noupload|nopositive)  # the recipe still says "uploaded 18 files" but uploads nothing
      perl -i -pe '$n += s/^\t  n=0; for f; do gcloud storage cp /\t  n=0; for f; do true storage cp /; END { exit($n == 1 ? 0 : 3) }' "$MK" || exit 3 ;;
    deadcapture)  # the fake gcloud logs nowhere
      perl -i -pe '$n += s{>> "\$T/log"}{>> /dev/null}g; END { exit($n == 2 ? 0 : 3) }' "$TS" || exit 3 ;;
    stall)  # the recipe hangs in a child that ignores TERM
      perl -i -pe '$n += s/^\t\@set -eu; d=/\t\@sh -c \x27trap "" TERM; exec sleep 617\x27; set -eu; d=/; END { exit($n == 1 ? 0 : 3) }' "$MK" || exit 3 ;;
  esac
  if test "$mutant" = nopositive; then  # and the positive control loses its upload count
    perl -i -pe '$n += s/test "\$rc" = 0 && test "\$n" = 18 && test "\$good" = 18 && test "\$uniq" = 18 && /test "\$rc" = 0 && /; END { exit($n == 1 ? 0 : 3) }' "$TS" || exit 3
  fi
  F=$MK; O=Makefile; if test "$mutant" = deadcapture; then F=$TS; O=tools/test_m4_publish.sh; fi
  if cmp -s "$ROOT/$O" "$F"; then echo "drill: mutation did not change $O"; exit 3; fi
  if test "$mutant" = nopositive; then
    if cmp -s "$ROOT/tools/test_m4_publish.sh" "$TS"; then echo "drill: mutation did not change the test"; exit 3; fi
  fi
  ran=0
  for outer in make gmake; do
    M=$(command -v "$outer" 2>/dev/null) || { echo "drill $mutant: $outer absent, skipped"; continue; }
    test "$(ls -A "$P/tmp" | wc -l)" -eq 0 || exit 1                    # private leftovers before
    t0=$(date +%s)
    set +e
    deadline "$S" env TMPDIR="$P/tmp" "$M" -C "$P/w" capture-m4-publish-test > "$P/out" 2>&1
    rc=$?
    set -e
    t1=$(date +%s)
    test "$(ls -A "$P/tmp" | wc -l)" -eq 0 || exit 1                    # and after: the test's trap ran
    test "$(pgrep -f "$P/" | wc -l | tr -d ' ')" -eq 0 || exit 1        # no make or script of this drill is left
    test "$(pgrep -fx 'sleep 617' | wc -l | tr -d ' ')" -eq 0 || exit 1 # nor the stall mutant's TERM-ignoring child
    echo "drill $mutant via $outer: make rc $rc in $((t1 - t0)) s"
    case "$rc" in
      0|2) ;;
      124) echo "drill $mutant: INFRASTRUCTURE timeout after $S s"; exit 4 ;;
      *) echo "drill $mutant: INFRASTRUCTURE rc $rc"; exit 4 ;;
    esac
    I=$(grep -c '^capture-m4-publish-test: INFRASTRUCTURE timeout after ' "$P/out" || :)
    if test "$mutant" = stall; then  # the expected outcome IS the INFRASTRUCTURE classification, bounded
      test "$rc" -eq 2 || exit 1
      test "$I" -eq 1 || exit 1
      test "$(grep -c '^capture-m4-publish-test: INFRASTRUCTURE timeout after 20 s: make for case complete ' "$P/out")" -eq 1 || exit 1
      test "$(grep -cE '^capture-m4-publish-test: (ok|FAIL|OK)' "$P/out")" -eq 0 || exit 1   # a timeout is never a case result
      test "$((t1 - t0))" -le 40 || exit 1
      ran=$((ran + 1)); continue
    fi
    if test "$I" -ne 0; then echo "drill $mutant: INFRASTRUCTURE (inner make timed out)"; exit 4; fi
    N=$(grep -c '^capture-m4-publish-test: ok complete ' "$P/out" || :)
    case "$mutant" in
      inloop)
        test "$rc" -eq 2 || exit 1
        test "$N" -ge 1 || exit 1                                           # positive control still green
        test "$(grep -c '^capture-m4-publish-test: FAIL ' "$P/out")" -eq $((4 * N)) || exit 1
        test "$(grep -c '^capture-m4-publish-test: FAIL worlds-missing (.*): rc 2, uploads 17, ' "$P/out")" -eq "$N" || exit 1
        test "$(grep -c '^capture-m4-publish-test: FAIL worlds-empty (.*): rc 2, uploads 17, ' "$P/out")" -eq "$N" || exit 1
        test "$(grep -c '^capture-m4-publish-test: FAIL worlds-short (.*): rc 0, uploads 18, ' "$P/out")" -eq "$N" || exit 1
        test "$(grep -c '^capture-m4-publish-test: FAIL manifest-missing (.*): rc 2, uploads 15, ' "$P/out")" -eq "$N" || exit 1
        test "$(grep -c '^capture-m4-publish-test: ok png-missing ' "$P/out")" -eq "$N" || exit 1
        test "$(grep -c '^capture-m4-publish-test: ok hash-mismatch ' "$P/out")" -eq "$N" || exit 1 ;;
      noupload|deadcapture)
        test "$rc" -eq 2 || exit 1
        test "$N" -eq 0 || exit 1
        K=$(grep -c '^capture-m4-publish-test: FAIL complete (.*): rc 0, uploads 0, ' "$P/out" || :)
        test "$K" -ge 1 || exit 1
        test "$(grep -c '^capture-m4-publish-test: FAIL ' "$P/out")" -eq "$K" || exit 1
        test "$(grep -c '^capture-m4-publish-test: ok ' "$P/out")" -eq $((6 * K)) || exit 1 ;;
      nopositive)  # predicted SURVIVOR: without the count, nothing sees that no file was uploaded
        test "$rc" -eq 0 || exit 1
        test "$(grep -c '^capture-m4-publish-test: FAIL ' "$P/out")" -eq 0 || exit 1
        test "$(grep -c '^capture-m4-publish-test: ok complete ' "$P/out")" -ge 1 || exit 1 ;;
    esac
    ran=$((ran + 1))
  done
  test "$ran" -ge 1 || exit 1
  echo "drill $mutant: expected outcome on $ran outer makes"
)
```

After the preflights, on the fixed tree:

```sh
for m in inloop noupload deadcapture; do
  drill "$PWD" "$m"; rc=$?; echo "exit=$rc"; test "$rc" -eq 0 || exit "$rc"
done
drill "$PWD" nopositive; rc=$?; echo "exit=$rc"; test "$rc" -eq 0 || exit "$rc"
drill "$PWD" stall; rc=$?; echo "exit=$rc"; test "$rc" -eq 0 || exit "$rc"
```

Each drill must report **2 outer makes**, not merely an exit 0 after silently skipping gmake on the rig. `inloop` must give 4N FAILs with complete still green; `noupload` and `deadcapture` only N complete-case FAILs and 6N ok; `nopositive` is the deliberate survivor with rc 0, not a kill; `stall` expects exactly one inner INFRASTRUCTURE line and no case verdict, rc 2 per make within 40 s. Exit 1 is a doc/test mismatch: STOP. Exit 2 is setup/usage failure, 3 means mutation not applied, 4 means infrastructure; none is a kill. Never classify outer deadline rc 124 as expected for stall.

The copied drill provides explicit ROOT, one parent template mktemp + immediate cleanup/signal traps, private Makefile/mk/script copy, exact substitution counts and cmp proof, captured/asserted rc, asserted counts, inherited private TMPDIR empty before and after, process absence, and both outer make paths. It never mutates the checkout. No drill script is committed. Retain every assertion; pgrep failures cannot be converted into zeroes.

AC-a13 uses this hardened equivalent of the design's probe command (same injected hang and expected bounds; immediate traps, explicit ROOT, asserted counts and process-query status):

```sh
probe_7la() (
  set -u
  ROOT=${1:?explicit checkout ROOT required}
  cd "$ROOT" || exit 2
  ROOT=$(pwd -P)
  Q=$(mktemp -d "${TMPDIR:-/tmp}/stap-7la-q.XXXXXX") || exit 2
  trap 'rm -rf "$Q"' EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM HUP
  mkdir "$Q/bin" "$Q/tmp" || exit 2
  printf '#!/bin/sh\ntrap "" TERM\nexec sleep 618\n' > "$Q/bin/gmake" || exit 2
  chmod +x "$Q/bin/gmake" || exit 2
  test "$(ls -A "$Q/tmp" | wc -l)" -eq 0 || exit 1
  s=$(date +%s)
  rc=0
  deadline 400 env PATH="$Q/bin:$PATH" TMPDIR="$Q/tmp" make -s capture-m4-publish-test > "$Q/out" 2>&1 || rc=$?
  elapsed=$(($(date +%s) - s))
  echo "rc=$rc ${elapsed}s"
  case "$rc" in 124) echo 'probe: INFRASTRUCTURE outer deadline'; exit 4 ;; esac
  test "$rc" -eq 2 || exit 1
  test "$elapsed" -le 25 || exit 1
  test "$(grep -c 'INFRASTRUCTURE timeout after 10 s: .*/gmake --version' "$Q/out")" -eq 1 || exit 1
  test "$(grep -c '^capture-m4-publish-test: INFRASTRUCTURE' "$Q/out")" -eq 1 || exit 1
  test "$(grep -cE '^capture-m4-publish-test: (ok|FAIL|OK)' "$Q/out")" -eq 0 || exit 1
  prc=0; pgrep -fx 'sleep 618' > "$Q/pids" 2> "$Q/ps.err" || prc=$?
  case "$prc" in 0|1) ;; *) cat "$Q/ps.err"; echo 'UNINFORMATIVE UNDER SANDBOX: process query'; exit 4 ;; esac
  test "$(wc -l < "$Q/pids")" -eq 0 || exit 1
  prc=0; pgrep -f "$Q/" > "$Q/pids" 2> "$Q/ps.err" || prc=$?
  case "$prc" in 0|1) ;; *) cat "$Q/ps.err"; echo 'UNINFORMATIVE UNDER SANDBOX: process query'; exit 4 ;; esac
  test "$(wc -l < "$Q/pids")" -eq 0 || exit 1
  test "$(ls -A "$Q/tmp" | wc -l)" -eq 0 || exit 1
  echo 'probe: timeout-signature=1 processes=0 tmp=0'
)
```

### Exact acceptance gates (AC-a1 through AC-a14)

Run from the implementation root; `mkdir -p .godot/tmp` for log redirections. Define the functions above first. Capture each command's substantive rc immediately; grep count 0 itself returns rc 1 and is not evidence that a make failed. All expected values below are **fixed-tree** values, separate from base findings. On the rig require the two measured GNU versions. AC-a12 and AC-a14 CI evidence are controller-only. AC-a6 requires the controller's committed implementation tree: before that commit compare saved hashes across drills instead, then repeat the literal HEAD gate afterwards. No pass is inferred from a query or a missing target.

Status 124 / unexpected INFRASTRUCTURE / drill exit 4: infrastructure, STOP and controller re-run; never test evidence. The only expected injected INFRASTRUCTURE paths are the inner stall and version-probe bounds, which must also satisfy timing and cleanup. AC-a11 below is explicitly the D1 proposed correction, requiring controller disposition. AC-a13 uses the hardened wrapper above; it must report the same signature, bound and cleanup as the design command.

| ID | Command | Expected |
|---|---|---|
| AC-a1 | `deadline 400 make -s capture-m4-publish-test > .godot/tmp/7la-m.out 2>&1; echo rc=$?; grep -c '^capture-m4-publish-test: ok ' .godot/tmp/7la-m.out; grep -c '^capture-m4-publish-test: INFRASTRUCTURE' .godot/tmp/7la-m.out; tail -1 .godot/tmp/7la-m.out` | `rc=0`, `14` (7 cases × 2 makes on the rig), `0`, `capture-m4-publish-test: OK (7 cases on 2 makes: GNU Make 3.81, GNU Make 4.4.1)`. `rc=124`, or an INFRASTRUCTURE count of 1, is a rig failure: re-run |
| AC-a2 | `deadline 400 gmake -s capture-m4-publish-test > .godot/tmp/7la-g.out 2>&1; echo rc=$?; grep -c '^capture-m4-publish-test: ok ' .godot/tmp/7la-g.out; grep -c '^capture-m4-publish-test: INFRASTRUCTURE' .godot/tmp/7la-g.out` | `rc=0`, `14`, `0` (the same through gmake, with the same INFRASTRUCTURE rule) |
| AC-a3 | `for m in make gmake; do $m -pnq test 2>/dev/null \| grep '^test:' \| tr ' ' '\n' \| grep -cx capture-m4-publish-test; done; grep -c '^test: capture-m4-publish-test$' Makefile` | `1`, `1`, `1` (`make test` reaches it with either make, from its own line) |
| AC-a4 | `for m in inloop noupload deadcapture; do drill "$PWD" $m; echo "exit=$?"; done` | for each: `drill <m> via make: make rc 2 in <s> s`, `drill <m> via gmake: make rc 2 in <s> s`, `drill <m>: expected outcome on 2 outer makes`, `exit=0`. `exit=4` (`INFRASTRUCTURE`) is a rig failure: re-run, never a kill |
| AC-a5 | `drill "$PWD" nopositive; echo "exit=$?"; drill "$PWD" stall; echo "exit=$?"` | `nopositive`: `make rc 0` via both, `expected outcome on 2 outer makes`, `exit=0` (the predicted survivor). `stall`: `make rc 2 in <s> s` via both, with each `<s>` ≤ 40 (measured 25), `expected outcome on 2 outer makes`, `exit=0`. That proves a hung make with a TERM-ignoring child is bounded, classed INFRASTRUCTURE rather than as a case result, and leaves no process or temp dir. An `exit=4` from `nopositive`, or from the outer wrapper during `stall`, is a rig failure: re-run |
| AC-a6 | `git diff --quiet HEAD -- Makefile tools/test_m4_publish.sh; echo $?; find "${TMPDIR:-/tmp}" -maxdepth 1 \( -name 'stapledon-7la.*' -o -name 'm4-publish-test.*' \) \| wc -l` | `0` and `0` (drills never touched the checkout; no temp dirs left) |
| AC-a7 | `grep -cF -- '--cache-control="public, max-age=300" "$$f" "gs://stapledons-voyage-assets/refs/m4_ship_s1/$${f##*/}"' Makefile; grep -c '^M4_PUBLISH_DIR := renders/m4$' Makefile` | `1`, `1` (public path and cache-control byte-identical; default source unchanged) |
| AC-a8 | `awk '/^capture-m4-publish:/,/^\.PHONY: capture-m4-publish/' Makefile \| awk '/gcloud storage cp/ {g=NR} /test -s/ && !t {t=NR} /shasum -a 256 -c/ {s=NR} /worlds\.sha256" \| tr/ {w=NR} END {print (t<g && s<g && w<g) ? "pre-checks-first" : "ORDER-BAD"}'` | `pre-checks-first` |
| AC-a9 | `grep -c '^NP=\$T/bin:/usr/bin:/bin$' tools/test_m4_publish.sh; grep -c 'is not first on PATH' tools/test_m4_publish.sh` | `1`, `1` (real `gcloud` unreachable, guarded) |
| AC-a10 | `make uid-guard python-guard && git diff --check origin/main && echo gates-ok` | `gates-ok` (a `.sh` needs no `.uid`; no Python) |
| AC-a11 | `git diff --name-only origin/main \| grep -cvxE 'Makefile\|tools/test_m4_publish\.sh\|\.ailang/state/sprints/sprint_R1-M4-JOURNEY\.json\|design_docs/planned/r1/m4-7l-capture-followups\.md\|design_docs/planned/r1/m4-7l-capture-followups-sprint\.md'; git diff --name-only origin/main \| grep -cxE 'Makefile\|tools/test_m4_publish\.sh'` | `0` outside files; `2` changed code files. Proposed correction D1: five allowed paths, including the required sprint plan; controller must ratify. |
| AC-a12 | `rig/full` on the PR head (`tools/rig_check.sh <PR>`, launched detached per the iteration-61 fix). `rig_check.sh` runs `make test` and writes its log to `${RIG_DIR:-${TMPDIR:-/tmp}/rig-check/<sha>}.log` (A-V17), so afterwards run `grep -c '^capture-m4-publish-test: OK (7 cases on 2 makes' "${TMPDIR:-/tmp}/rig-check/<full head sha>.log"` | status `success`; `1` |
| AC-a13 | `probe_7la "$PWD"; rc=$?; echo "exit=$rc"; test "$rc" -eq 0` (function above; hardened equivalent of AC-a13) | `rc=2` within 25 s; `probe: timeout-signature=1 processes=0 tmp=0`; `exit=0`. One 10 s probe INFRASTRUCTURE line, zero case verdicts, zero remaining processes/temp entries. Outer timeout is infrastructure failure, never accepted. |
| AC-a14 | Linux run (quorum round 2): `grep -cE '^ci-fast:.* capture-m4-publish-test( \|$)' Makefile`; then, on the PR's fast-tier run, `gh run view <run> --log \| grep -E 'capture-m4-publish-test: (OK\|FAIL\|INFRASTRUCTURE)'` | `1`; the fast-tier job is `success` and its log carries `capture-m4-publish-test: OK (7 cases on 1 makes: GNU Make 4.<n>)`, with 0 `FAIL` and 0 `INFRASTRUCTURE` lines. |


For AC-a12 the controller launches `tools/rig_check.sh <PR>` detached according to the mission's iteration-61 procedure **after this bounded planner/executor run ends**; that later controller-owned job is the full-suite stage. Use the actual `dir=${RIG_DIR:-${TMPDIR:-/tmp}/rig-check/$sha}` and `log="$dir.log"` values if RIG_DIR is overridden; default is `<tmp>/rig-check/<full sha>.log`. Require rig/full success on the exact PR head and the OK count of 1, not an older head's status. Executor does not launch this job or run the whole suite.

For AC-a14 source grep must print 1. The controller records PR head SHA, fast-tier run ID, successful `gh run view <run> --log` retrieval, one Linux OK with seven cases on one GNU Make 4.x, and zero FAIL/INFRASTRUCTURE lines from that test. A failed `gh` pipeline is not a zero-match result. Linux timeout behavior is not claimed here. Any other Linux make inventory must be measured and reported for controller disposition rather than relabelled as the specified runner evidence.

### Files allowed / do not touch

Planner writes only this sprint plan and `.ailang/state/sprints/sprint_R1-M4-JOURNEY.json` (one appended feature); existing feature objects and all other state remain canonical-byte-identical under `jq -S`. Keep `passes: false`.

Executor code scope: **`Makefile`** (the publish block and single `ci-fast:` prerequisite addition only) and **`tools/test_m4_publish.sh`** (one new shell test, no `.uid`). Bookkeeping: only this new feature's notes in the sprint JSON. The branch's five-path allowlist after planning/implementation is the two code files, sprint JSON, existing design addendum, and this sprint plan; the planner's D1 correction adds the fifth path to AC-a11. Do not edit the design doc while resolving defects; controller disposition is explicit in notes/plan.

Do not touch `mk/*`, other Makefile recipes/test prerequisites, `sim/*`, any `.ail`/`.py`, packages, pins/locks/runtime, `.github/workflows/*`, `demos/*`, `ui/*`, scenes/shaders, capture/bench drivers, historical (b)–(d) report or feature, render assets/public set, normative physics/design canon, or generated `.translation` files. No republish and no call to a real gcloud. No changelog fragment is in the design's bounded allowlist. If one becomes required, STOP for controller scope disposition instead of silently widening it.

### Pause points and handoff

- **Before implementation:** STOP and report `BLOCKED: PR ownership unverified` until fresh gh reads succeed; STOP on any recipe/ci-fast overlap or anchor drift for controller re-measurement. The historical PR list is not a substitute.
- **Design defect disposition:** STOP dependent work until the controller records D1's allowlist correction and D2's host-preflight decision. These are engineering/design dispositions within the existing grant, not reopened human decisions.
- **RED:** STOP if the new script fails for environment reasons, if complete is not green, or if the measured partial-upload failures are not reproduced. Keep the evidence; do not implement a fix over an unproven test.
- **GREEN/drills:** STOP on any unmutated FAIL, wrong mutant signature, unapplied mutation, unexpected survivor, timeout or process-query failure. Label sandbox-blocked checks `UNINFORMATIVE UNDER SANDBOX`; preserve passes false and transfer only those checks to the controller. Re-run relevant gates after an actual correction; do not broaden into GPU or full-suite work.
- **After focused execution:** executor stops with code and dated evidence; controller commits implementation, repeats AC-a6 on that committed tree, runs rig/full and Linux fast tier on the PR head, and arranges independent evaluation. Only controller can mark passes true after rig/full. No human pause is added under D-88 A.

Planner validation: run `git diff --check`, the exact D1 original/corrected allowlist comparison, and the requested `jq -S` preservation comparison against planning HEAD, then stage **only these two planning files** and commit `plan(7l-a): sprint amendment and feature object` with the specified co-author trailer. If the sandbox refuses the commit, leave these edits uncommitted and report the refusal; no escalation or push.

### Planning artifact checks (measured before commit)

The required canonical comparison returned **cmp rc 0**: all 21 existing features and every other top-level value are unchanged; feature count is now 22. Exact comparison (HEAD is the planning base at this point):

```sh
(
  S=.ailang/state/sprints/sprint_R1-M4-JOURNEY.json
  Q=$(mktemp -d "${TMPDIR:-/tmp}/iter64-state-check.XXXXXX") || exit 2
  trap 'rm -rf "$Q"' EXIT
  git show "HEAD:$S" | jq -S 'del(.features[] | select(.id=="M4.6rR3_7la_ATOMIC_PUBLISH"))' > "$Q/before" || exit 1
  jq -S 'del(.features[] | select(.id=="M4.6rR3_7la_ATOMIC_PUBLISH"))' "$S" > "$Q/after" || exit 1
  cmp "$Q/before" "$Q/after" || exit 1
  echo existing-state-identical
)
```

Expected and observed: `existing-state-identical`, rc 0. `git diff --check` is clean. Original AC-a11 outside-file count after these edits is **1**, the sprint plan; proposed D1 regex gives **0**; changed-code count remains **0** until execution (must become 2). Every extracted shell block containing runnable code passes `sh -n` and `bash -n`; the literal numbered-placeholder PR snippets are instructions, not scripts to execute verbatim. The new test still does not exist in the checkout, and `git diff --quiet HEAD -- Makefile tools/test_m4_publish.sh` still returns 0. Only the sprint plan and sprint JSON are edited. No fixed-tree test result, GPU/socket check, process-cleanup verdict, current PR hold verdict or CI/rig success is claimed by this planning commit.

Commit attempt: `git add` of exactly the two planning paths was refused with rc 128: `Unable to create .../.git/index.lock: Operation not permitted`. The requested commit therefore was not created; both artifacts remain **uncommitted** for the controller. No escalation or push was attempted.

### Controller dispositions (iteration 64, 2026-11-02)

- **D1 ACCEPTED.** AC-a11's allowlist regex gains `design_docs/planned/r1/m4-7l-capture-followups-sprint\.md`; the code-file control count stays `2`. The gate table and feature object already carry it.
- **D2 NOT ADOPTED: a sandbox artifact, not a host defect.** Re-measured by the controller outside the sandbox: `env TMPDIR=$Q/ /usr/bin/make --version` and the same for `/opt/homebrew/bin/gmake` each leave **0** entries in a fresh private `$Q`. The `xcrun_db` entry appears only inside the codex sandbox (its xcrun cache path is not writable there, so xcrun falls back to `TMPDIR`). So no `xcrun --find make` preflight is added and the design is unchanged. Zero-entry assertions (drill private-temp counts, AC-a6, AC-a13) are judged on the controller's and evaluator's out-of-sandbox runs; inside the sandbox the executor labels them `UNINFORMATIVE UNDER SANDBOX` when `xcrun_db` is the only entry.
- **PR ownership** (the planner's `gh` was blocked by the sandbox): measured by the controller and the designer at 17:00–18:45Z: open PRs #371 (`Makefile` hunk at ~505), #373 (hunk at 18–28), #374 (no `Makefile`), #375 (`mk/sound.mk` only). None touches the recipe, the `ci-fast:` line or the `test:` region. The executor re-checks at splice time per the Risks pre-flight.
