# Sprint addendum: R1-M4-JOURNEY row 7n(b), ISM layer survivors

**Status:** Planned, mission iteration 60 planner, 2026-10-30, HEAD `d20dd84e` (= `origin/main` `b2e6c110` plus three design-doc commits, `96c50b2e`/`0e3cae1c`/`d20dd84e`; the implementation tree is unedited, `git diff --name-only origin/main` lists only the design doc). One milestone `M4.6pR3_7nb_ISM_LAYER_SURVIVORS` under the approved sprint `R1-M4-JOURNEY` (D-22/D-66, D-88 A).
**Design:** [m4-7nb-ism-layer-survivors.md](m4-7nb-ism-layer-survivors.md) — the contract, read in full: Design (1)–(3), the Changelog fragment, the Drills section (`deadline` + `drill` functions), the Acceptance criteria (AC1–AC12), the Verification log (V1–V34) and the Review history (quorum rounds 1–2; the controller's narrow-refinement carve-out fixes already applied; no third round).
**Scope:** the whole design: (1) MG KILL (an `ErrorLog` logger over the hidden-window section of `tests/test_ism_layer.gd`, a `7nb-sentinel` positive control, three new named checks; 19 → 22 checks), (2) MN RECORD AS EQUIVALENT (two comment lines in `ui/ism_layer.gd`), (3) MS already killed (one comment before the shown-window case), plus the changelog fragment. Test and code-comment only; no behaviour change, no new script (so no new `.uid`).
**Budget:** ~24 LOC: `tests/test_ism_layer.gd` +20, `ui/ism_layer.gd` +2 comment lines, one 2-line changelog fragment. Pinned AILANG v0.54.18 (`runtime/bin`, unused by this row), Godot 4.7.2 (`OS.add_logger`, design V8/V21). Registry reuse: none — GDScript tests and docs only, no package-like capability. No `.ail` file is written, so the AILANG syntax gate does not apply.
**Ownership:** everything here is headless. The executor does the RED probe, the GREEN edits, and runs every headless gate and AC1–AC11 on the **uncommitted** tree (design V27). The controller re-runs every AC (RED included) outside any sandbox, commits the three implementation files by name, opens the PR, runs `rig/full` (AC12, the definition of done) and the GitHub fast tier, merges, runs the independent evaluation, and only then sets `passes`. **No executor sets `passes`.**

## Reality check against HEAD

Every design line anchor was re-verified at `d20dd84e` in this clone with `grep -n`/`sed -n` (full evidence in Verification below): `tests/test_ism_layer.gd:13` (`var passes := 0`), `:91` (the `# A CanvasLayer keeps its overlay visible-in-tree…` comment), `:114` (the `window.show()` that precedes the shown-window check at `:117`), `:133` (the closing `print("ism-layer: …")`); `ui/ism_layer.gd:254–266` (`func draw(…)` … `return 0`) and `:261` (the last line of the M4.6pR3 comment, directly above `var host := overlay.get_window()` at `:262`). The drill's MG/MS/MN perl edits all apply to the current `ui/ism_layer.gd`; ML cannot apply yet (no `OS.add_logger(errors)` exists on the unedited tree — a drill ML would exit 3 today, exactly as designed on a pre-GREEN tree). Baseline: `godot --headless --path . --script tests/test_ism_layer.gd` → rc 0, `ism-layer: 19 passed, 0 failures`. **No design premise proved false on this tree.** One environment caveat, recorded in Verification: under this planner sandbox the bare script also prints three start-up-only `ERROR` lines (two `user://logs` open failures and one macOS CA-certificates `ret != noErr`), all before the M4.6pR3 section; the design's first-party unsandboxed runs measured 0 (V3, V25, V31). AC1's trailing `0` is the controller's unsandboxed call; see Pause points.

## Tasks (test-first, in order)

1. **Preflight (controller):** refresh `origin/main`; `git log --oneline b2e6c110..origin/main -- ui/ism_layer.gd tests/test_ism_layer.gd mk/ism.mk` must still print nothing, and the AC11 `gh api` check on PRs #344/#351 must still not list `ui/ism_layer.gd` or `tests/test_ism_layer.gd` (design Risks; 0/0 at plan time). Pause for rebase/recount if either moved. Define `deadline` and `drill` (copied verbatim below).
2. **RED — prove MG survives on the unedited tree (executor, headless; controller re-runs):** save `ui/ism_layer.gd` to a temp copy; apply the drill's exact MG perl edit; run `deadline 120 make map-ism-test` (and once with `gmake`); expect make rc 0, `ism-layer: 19 passed, 0 failures`, 0 FAIL lines, and exactly one `ERROR: Signal 'visibility_changed' is already connected to given callable 'Control::queue_redraw' in that object.` line (`object.cpp:1562`, backtrace `draw (res://ui/ism_layer.gd:264)`); restore the saved copy and `cmp` it byte-identical. This reproduces premise V6 first-hand before fixing it; no kill is claimed at RED. Record the rc and counts in this feature's `notes`. (On the unedited tree the drill itself would exit 1 — its signatures assume the GREEN state — and drill ML would exit 3; neither is a RED tool.)
3. **GREEN (1) MG (~+20, executor):** apply the design §(1) edit to `tests/test_ism_layer.gd` in three parts, verbatim from Design code below: the `ErrorLog` class after line 13; the logger install + `7nb-sentinel` positive control directly before line 91; the `OS.remove_logger` + three checks directly before line 133. The cited line numbers are against the unedited file, so apply bottom-up (before `:133`, then before `:91`, then after `:13`) or always locate the textual anchor; never paste by stale number. Add the MS comment (part 4 of the test edit, design §(3)) directly before the `window.show()` at line 114.
4. **GREEN (2) MN (+2 comment lines, executor):** add the design §(2) two-line comment in `ui/ism_layer.gd` after line 261, directly above `var host := overlay.get_window()`, verbatim. No code line changes (AC8 counts 0 non-comment changed lines).
5. **GREEN (3) changelog (executor):** create `changelogs/unreleased/2026-10-30-7nb-ism-layer-survivors.md` with the design's sentence as the bullet, under a `### Fixed` heading per the fragment convention of its neighbours (README in that directory).
6. **Drills and AC1–AC11 (executor, all headless, uncommitted tree, in the doc's order):** define `deadline`/`drill`; run AC1 (`make`), AC2 (`gmake`), then AC3–AC6 (the four drills MG, MS, MN, ML under `make` then `gmake`), AC7–AC11. A drill exit 4 (INFRASTRUCTURE — timeout, no log, wild make rc) is a rig failure: re-run, never a kill or a pass. A drill exit 1 on the fixed tree halts the row as a doc bug (design Acceptance preface). The edits stay uncommitted (V27): AC7 compares `git hash-object` before AC3 and after AC6 and prints `restored=0`; record the two `$TMPDIR` counts and the `find` result in the `notes` (AC7's instruction).
7. **Close-out (executor):** append the dated row-7n(b) note (RED outputs, AC1–AC7 outputs, both tmp counts) to this feature's `notes` in the sprint JSON — the design's Files table assigns exactly that content — and leave `passes` false. Hand everything to the controller.
8. **Controller (outside any sandbox):** re-run RED and every AC first-hand; only then `git add tests/test_ism_layer.gd ui/ism_layer.gd changelogs/unreleased/2026-10-30-7nb-ism-layer-survivors.md` (by name; **never** the 5 untracked `*.translation` files, design V1/gemini's round-1 note; AC11's `git add -N` names its files, never `git add -N .`), commit, open the PR, run `rig/full` via `tools/rig_check.sh <PR>` (AC12) and wait for the GitHub fast tier; merge on both green; run the independent evaluator (generator ≠ judge, 100 points / 70 to pass, output in `.ailang/state/evaluations/`); then set `passes`.

## Design code (verbatim from the design)

Every block below is copied byte-for-byte from the design's Design section and Changelog section; apply it unchanged.

§(1), part 1 — after `var passes := 0` (line 13 of `tests/test_ism_layer.gd`):

```gdscript
## 7n(b): engine and script errors raised while installed (OS.add_logger); warnings are skipped.
## A second visibility_changed.connect to the same callable is refused (the count stays 1) but logs one.
class ErrorLog extends Logger:
	var lines: Array[String] = []
	func _log_error(_function: String, _file: String, _line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type != ERROR_TYPE_WARNING:
			lines.append(rationale if rationale != "" else code)
```

§(1), part 2 — directly before `# A CanvasLayer keeps its overlay visible-in-tree…` (line 91):

```gdscript
	var errors := ErrorLog.new()
	OS.add_logger(errors)
	push_error("7nb-sentinel")
	var capture_live := errors.lines.any(func(l: String) -> bool: return l.contains("7nb-sentinel"))
	errors.lines.clear()
```

The sentinel is the quorum round-2 positive control: it proves the capture path is live on every run, then `errors.lines.clear()` drops it so it matches neither filter; it prints one expected `ERROR: 7nb-sentinel` console line (V31).

§(1), part 3 — directly before the closing `print("ism-layer: …")` (line 133):

```gdscript
	OS.remove_logger(errors)
	check("M4.6pR3 error capture is live (7n-b)", capture_live, "")
	var refused := errors.lines.filter(func(l: String) -> bool: return l.contains("'visibility_changed' is already connected"))
	check("M4.6pR3 hidden redraws: no refused repeated visibility_changed connect (7n-b)", refused.is_empty(), str(refused.slice(0, 1)))
	var other := errors.lines.filter(func(l: String) -> bool: return not l.contains("'visibility_changed' is already connected"))
	check("M4.6pR3 hidden-window section logs no other engine or script error", other.is_empty(), str(other.slice(0, 1)))
```

§(3) — the MS comment, directly before the `window.show()` at line 114 (the one that precedes `check("M4.6pR3 shown window …")` at line 117):

```gdscript
	# Godot redraws a shown window's canvas by itself: this case passes with the connect deleted
	# (7n-b). The is_connected and connection-count assertions are what guard the connection.
```

§(2) — the MN comment, in `ui/ism_layer.gd` after line 261, directly above `var host := overlay.get_window()`:

```gdscript
	# get_window() is null only outside the tree, where the draw signal never fires (the one
	# caller is GalaxyMap._draw_overlay); `host != null` is defensive, equivalent in use (7n-b).
```

Changelog — `changelogs/unreleased/2026-10-30-7nb-ism-layer-survivors.md`, the design's sentence (placed as the bullet of a `### Fixed` fragment):

> Tests: the ISM map layer's hidden-window test now fails on a repeated `visibility_changed` connect (row 7n(b)); the `host != null` check is recorded as equivalent in use.

## Drill and deadline functions

Copied verbatim from the design's Drills section (its extraction `sed -n '/^deadline() {/,/^)$/p'` passes `sh -n` and `bash -n` at plan time — see Verification). The executor and the controller run this exact function; it is not committed (wiring it in would need the held `Makefile`, design §Drills). DRILL_S defaults to 120 s (a pristine run is about 1 s).

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
drill() (  # drill ROOT MUTANT(MG|MS|MN|ML) [MAKE]: exit 0 measured signature, 1 wrong signature, 2 usage, 3 mutation not applied, 4 INFRASTRUCTURE
  set -eu
  ROOT=${1:?explicit checkout ROOT required}; mutant=${2:?MG, MS, MN or ML}; MK=${3:-make}
  cd "$ROOT" || exit 2; ROOT=$(pwd -P); F=ui/ism_layer.gd
  case "$mutant" in ML) F=tests/test_ism_layer.gd ;; esac
  test -f "$F" || exit 2
  T=$(mktemp -d "${TMPDIR:-/tmp}/stapledon-7nb.XXXXXX") || exit 2
  trap 'if test -f "$T/orig.gd"; then cp "$T/orig.gd" "$ROOT/$F"; fi; rm -rf "$T"' EXIT
  trap 'exit 130' INT; trap 'exit 143' TERM HUP
  cp "$F" "$T/orig.gd" || exit 2
  case "$mutant" in
    MG) perl -0 -i -pe 's/\t\tif not host\.visibility_changed\.is_connected\(overlay\.queue_redraw\):\n\t\t\thost\.visibility_changed\.connect\(overlay\.queue_redraw\)\n/\t\thost.visibility_changed.connect(overlay.queue_redraw)\n/' "$F" || exit 1
        want_rc=2; summary='^ism-layer: 21 passed, 1 failures$'
        fails='^  FAIL  M4\.6pR3 hidden redraws: no refused repeated visibility_changed connect \(7n-b\) \["Signal .*visibility_changed.* is already connected .*"\]$'; nfail=1 ;;
    MS) perl -0 -i -pe 's/\t\tif not host\.visibility_changed\.is_connected\(overlay\.queue_redraw\):\n\t\t\thost\.visibility_changed\.connect\(overlay\.queue_redraw\)\n//' "$F" || exit 1
        want_rc=2; summary='^ism-layer: 20 passed, 2 failures$'
        fails='^  FAIL  M4\.6pR3 (hidden-window: no media drawn|hide/show cycle: one redraw connection)'; nfail=2 ;;
    MN) perl -i -pe 's/^\tif host != null and not host\.visible:$/\tif not host.visible:/' "$F" || exit 1
        want_rc=0; summary='^ism-layer: 22 passed, 0 failures$'; fails='^  FAIL'; nfail=0 ;;
    ML) perl -i -ne 'print unless /^\tOS\.add_logger\(errors\)$/' "$F" || exit 1
        want_rc=2; summary='^ism-layer: 21 passed, 1 failures$'; fails='^  FAIL  M4\.6pR3 error capture is live \(7n-b\)'; nfail=1 ;;
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
  L="$T/s/map-ism-test.log"; test -s "$L" || { echo "drill $mutant: INFRASTRUCTURE no log"; exit 4; }
  test "$(grep -c 'SCRIPT ERROR' "$L")" -eq 0 || exit 1
  test "$(grep -c -E "$summary" "$L")" -eq 1 || exit 1
  test "$(grep -c '^  FAIL' "$L")" -eq "$nfail" || exit 1
  test "$(grep -c -E "$fails" "$L")" -eq "$nfail" || exit 1
  if test "$rc" -eq 2; then test "$(grep -c '^map-ism-test: FAILED$' "$T/make.out")" -eq 1 || exit 1; fi
  echo "drill $mutant ($MK): measured signature"
)
```

## Acceptance criteria (verbatim, in the design's order)

AC1–AC11 run from the implementation root on the uncommitted tree; AC12 is the controller's rig gate after the commit and PR. The design's preamble and table, unmodified:

Run from the implementation root after the edit. **The edits stay uncommitted during the run**: no criterion compares against `HEAD`. AC7 hashes the file instead, and AC8 and AC11 compare against `origin/main`. Define `deadline` and `drill` from the Drills section first. `make` is `/usr/bin/make` 3.81, and `gmake` is Homebrew GNU Make 4.4.1. Both are headless; the target needs no GPU window.

| # | Criterion and command | Expected output |
|---|---|---|
| AC1 | `deadline 120 make map-ism-test; echo rc=$?; L=.godot/tmp/map-ism-test.log; grep -c '^ism-layer: 22 passed, 0 failures$' $L; grep -c '^ERROR: 7nb-sentinel$' $L; grep -E 'SCRIPT ERROR\|^ERROR\|^WARNING' $L \| grep -cv 7nb-sentinel` | `rc=0`, `1`, `1` (the expected sentinel line), `0` |
| AC2 | AC1 with `gmake` in place of `make` | `rc=0`, `1`, `1`, `0` |
| AC3 | `pre=$(git hash-object ui/ism_layer.gd); n0=$(ls "$TMPDIR" \| wc -l); drill "$PWD" MG; echo exit=$?` | `drill MG (make): make rc 2`, `drill MG (make): measured signature`, `exit=0` (MG killed: `ism-layer: 21 passed, 1 failures` and the one FAIL, literally from the V32 log: `  FAIL  M4.6pR3 hidden redraws: no refused repeated visibility_changed connect (7n-b) ["Signal \'visibility_changed\' is already connected to given callable \'Control::queue_redraw\' in that object."]`) |
| AC4 | `drill "$PWD" MS; echo exit=$?` | `drill MS (make): make rc 2`, `drill MS (make): measured signature`, `exit=0` (still killed: 2 FAILs, 20 passed) |
| AC5 | `drill "$PWD" MN; echo exit=$?` | `drill MN (make): make rc 0`, `drill MN (make): measured signature`, `exit=0` (recorded equivalent: 22/0) |
| AC5b | `drill "$PWD" ML; echo exit=$?` | `drill ML (make): make rc 2`, `drill ML (make): measured signature`, `exit=0` (dead capture killed by the sentinel: `  FAIL  M4.6pR3 error capture is live (7n-b)`, 21 passed) |
| AC6 | `for m in MG MS MN ML; do drill "$PWD" $m gmake; echo exit=$?; done` | four `measured signature` lines (`gmake`), make rc `2`, `2`, `0`, `2`, and `exit=0` four times |
| AC7 | In the same shell as AC3 (whose `pre` then also hashes the test, which ML mutates: `pre=$(git hash-object ui/ism_layer.gd tests/test_ism_layer.gd \| tr '\n' ' ')`), after AC6: `test "$pre" = "$(git hash-object ui/ism_layer.gd tests/test_ism_layer.gd \| tr '\n' ' ')"; echo restored=$?; echo "tmp $n0 -> $(ls "$TMPDIR" \| wc -l)"; find "${TMPDIR:-/tmp}" -maxdepth 1 -name 'stapledon-7nb.*' \| wc -l` | `restored=0` (the trap restored the edited file byte for byte); `tmp N -> N`; `0` (no drill temp dir is left). On a busy rig another process may change the count; the `find` is the decisive check, so record both numbers in the sprint JSON |
| AC8 | `D=$(git diff -U0 origin/main -- ui/ism_layer.gd); echo "$D" \| grep -E '^[-+][^-+]' \| grep -cvE '^\+[[:space:]]*#'; echo "$D" \| grep -cE '^\+[[:space:]]*#'` | `0` (no code line changed), `2` |
| AC9 | `grep -cE 'OS\.add_logger\(errors\)\|OS\.remove_logger\(errors\)\|passes with the connect deleted\|is already connected"\)' tests/test_ism_layer.gd` | `5` (install, remove, the MS comment, and the two filters) |
| AC10 | `make uid-guard lint-precision AILANG=$PWD/runtime/bin/ailang && git diff --check origin/main && echo gates-ok` | `gates-ok` (no new script, so no new `.uid`) |
| AC11 | `git diff --name-only origin/main \| grep -cvxE 'ui/ism_layer\.gd\|tests/test_ism_layer\.gd\|changelogs/unreleased/2026-10-30-7nb-ism-layer-survivors\.md\|design_docs/planned/r1/m4-7nb-ism-layer-survivors(-sprint)?\.md\|\.ailang/state/sprints/sprint_R1-M4-JOURNEY\.json'` (with untracked row files added by name: `git add -N changelogs/unreleased/2026-10-30-7nb-ism-layer-survivors.md design_docs/planned/r1/m4-7nb-ism-layer-survivors.md` first; never `git add -N .`, which would also mark the 5 untracked `*.translation` files); then for both PRs `gh api --paginate repos/sunholo-data/stapledons-godot/pulls/$p/files --jq '.[].filename' \| grep -cxE 'ui/ism_layer\.gd\|tests/test_ism_layer\.gd'` (p = 344, 351) | `0`; then `0` and `0` |
| AC12 | `make test` on the rig (`tools/rig_check.sh <PR>`), after the commit and PR: the definition of done | `rig/full` green |

## Gates

- **Executor (all headless, in order):** `deadline 120 make map-ism-test` (AC1); the same with `gmake` (AC2); the four drills MG, MS, MN, ML under `make` (AC3, AC4, AC5, AC5b) and under `gmake` (AC6); AC7–AC9 as written; `make uid-guard lint-precision python-guard ai-live-guard AILANG=$PWD/runtime/bin/ailang` (AC10's targets plus the mission gate list; `ai-live-guard` is `mk/ai.mk:423` and does its scratch `git init`/`git add` in a `mktemp` dir, not the repo — the 7l executor ran it locally the same way); `git diff --check origin/main`; AC11's scope and held-PR proofs.
- **Controller (merge gates):** re-run of every executor gate outside any sandbox, then `rig/full` via `tools/rig_check.sh <PR>` (AC12 — `make test` reaches `map-ism-test`, `Makefile:50`; it is not in `ci-fast`, `Makefile:48`) plus the GitHub fast tier. Both green before merge.
- **Evaluation (controller):** independent evaluator, generator ≠ judge, 100 points / 70 to pass, output in `.ailang/state/evaluations/`; the evaluator re-runs the drills and ACs first-hand.

## Files / do-not-touch

Executor allowlist — exactly these five paths: `tests/test_ism_layer.gd`, `ui/ism_layer.gd`, `changelogs/unreleased/2026-10-30-7nb-ism-layer-survivors.md`, `.ailang/state/sprints/sprint_R1-M4-JOURNEY.json` (only this feature's `notes` during execution), `design_docs/planned/r1/m4-7nb-ism-layer-survivors-sprint.md` (this plan).

Held/banned — must not be touched: `Makefile`, `mk/*`, `demos/*`, `ui/galaxy_map.gd` (the one production caller of `draw`, `ui/galaxy_map.gd:1407`, design V5; banned by the design's non-goals and this brief even though it is 0/0 in the held list), every scene, and all 415 paths in `/tmp/stap_i60_held.txt` (the union of attended PRs #344 and #351). Verified at plan time: each of the five allowlisted paths (and the design doc itself) greps **0** in `/tmp/stap_i60_held.txt`; `Makefile` greps 1; `mk/` has 5 held files, `demos/` 20, `ui/` 16 — none of them the allowlisted ones. AC11's regex and the two `gh api` greps re-prove this at execution time. Also out of scope: the approved design doc itself; rows 7n (a), (c), (d), (e); any behaviour change. A fresh clone holds **5 untracked `*.translation` files** from the import (`data/planets/trappist1_ps.*` ×4, `data/starmap/truth/positions.…` ×1): never commit them, and never `git add -N .` or `git add .` (design V1, V34, AC11).
## Pause points

- Planner stops at these two artifacts (this plan + the appended feature); the controller owns the handoff, all git writes, the PR and both merge statuses. The executor must not commit and snapshots nothing (single milestone).
- If the refreshed origin moved any anchor surface (`ui/ism_layer.gd`, `tests/test_ism_layer.gd`, `mk/ism.mk`) or either held PR now lists `ui/ism_layer.gd` / `tests/test_ism_layer.gd`, pause and re-verify; do not widen scope.
- **Sandbox log noise:** under this planner sandbox the bare script prints three start-up `ERROR` lines (two `Failed to open 'user://logs/…'`, one `get_system_ca_certificates … ret != noErr`) that first-party unsandboxed runs never showed (V3, V25, V31). If AC1's trailing count is not `0`, read the lines: the same start-up noise under a sandboxed executor is an environment artifact to record in `notes` and defer to the controller's unsandboxed re-run; anything raised **inside** the M4.6pR3 section (the logger window) is a real failure that halts the row — that is exactly what the separately named "no other engine or script error" check is for (design Risks).
- A drill exit 1 on the fixed tree halts the row as a doc bug (it is neither a kill nor a rig failure); exit 4 is INFRASTRUCTURE — re-run. If a Godot bump ever makes duplicate connects silent or reference-counted, MG's signature changes and the row re-opens for re-measurement (design Risks).
- If AC1 fails on the unmutated fixed tree, that contradicts V31 and is a re-measure, not a pass.

## Verification (planner, 2026-10-30, HEAD d20dd84e)

Every claim above was checked first-hand in this clone (read-only, or on copies under `.godot/tmp/7nb-planner/`; no mutant ran in the working tree, no make target, no git write). AILANG pinned v0.54.18 per CLAUDE.md, unused by this row.

| Claim | Command (abbreviated) | Result |
|---|---|---|
| HEAD = origin/main + 3 design-doc commits only | `git log --oneline -4`; `git diff --name-only origin/main` | `d20dd84e` on top of `0e3cae1c`, `96c50b2e`, `b2e6c110` (=#357 merge); diff lists only `design_docs/planned/r1/m4-7nb-ism-layer-survivors.md` |
| Working tree | `git status --porcelain` | only the 5 untracked `*.translation` files (`data/planets/trappist1_ps.*` ×4 incl. `.default/.pl/.rowupdate/.st`, `data/starmap/truth/positions.…` ×1) — never commit them |
| Nothing since b2e6c110 touches the code files | `git log --oneline b2e6c110..HEAD -- ui/ism_layer.gd tests/test_ism_layer.gd mk/ism.mk` | empty (the three commits are design-doc only) |
| Anchor :13 | `grep -n 'var passes := 0' tests/test_ism_layer.gd` | `13:var passes := 0` — `ErrorLog` class goes after it |
| Anchor :91 | `grep -n '# A CanvasLayer keeps its overlay' tests/test_ism_layer.gd` | `91:` (one leading tab) — install+sentinel go directly before it |
| Anchor :114 | `grep -n 'window.show()' tests/test_ism_layer.gd`; `grep -n 'M4.6pR3 shown window' …` | `window.show()` at `:114` and `:128`; the shown-window `check` at `:117`, so the MS comment's anchor is `:114` (design's phrasing holds) |
| Anchor :133 | `grep -n 'print("ism-layer:' tests/test_ism_layer.gd` | `133:` — the three checks + `OS.remove_logger` go directly before it; file has 134 lines |
| Anchor :254–266 | `sed -n '252,268p' ui/ism_layer.gd` | `func draw(overlay: Control, camera: Camera3D, …) -> int:` at `:254`, the early-return block (non-null host → connect guard → `return 0`) closes at `:266` |
| Anchor :261 | `grep -n 'cost ~24 ms\|var host := overlay.get_window()' ui/ism_layer.gd` | `:261` `# cost ~24 ms of main-thread time a tick. Showing the window redraws it.` (last comment line); `:262` `var host := overlay.get_window()` — the two MN comment lines insert between them, tab-indented |
| Guard lines the MG/MS/MN edits match | same `sed` block | `:263` `if host != null and not host.visible:` (1 tab); `:264` `if not host.visibility_changed.is_connected(overlay.queue_redraw):` (2 tabs); `:265` `host.visibility_changed.connect(overlay.queue_redraw)` (3 tabs) — byte-compatible with the drill's perl patterns |
| Baseline | `godot --headless --path . --script tests/test_ism_layer.gd` | rc 0, `ism-layer: 19 passed, 0 failures`, 19 `  ok` lines, 0 `SCRIPT ERROR` (see Pause points for the 3 sandbox-only start-up `ERROR` lines) |
| Drill mutations on copies | drill's four perl edits against copies in `.godot/tmp/7nb-planner/`, then `cmp -s` | MG applied, MS applied, MN applied; ML unchanged on the unedited tree (no `OS.add_logger(errors)` yet → drill exit 3 path, as designed pre-GREEN) |
| Drill shell valid | `sed -n '/^deadline() {/,/^)$/p'` of the design → `sh -n`, `bash -n` | both pass; 54 lines extracted |
| Target wiring | `grep -n '^test:\|^ci-fast:' Makefile`; `sed -n '45,48p' mk/ism.mk` | `map-ism-test` in `test` (Makefile:50), not in `ci-fast` (Makefile:48); target needs rc 0 and `^ism-layer: [1-9][0-9]* passed, 0 failures$`, else `map-ism-test: FAILED` and make rc 2 (V20 holds) |
| Gate targets exist | `grep -n '^uid-guard:\|^lint-precision:\|^python-guard:' Makefile`; `grep -n '^ai-live-guard:' mk/ai.mk` | Makefile:981, :258, :977; mk/ai.mk:423 |
| Held list vs allowlist | `grep -cxF <path> /tmp/stap_i60_held.txt` for all five allowlisted paths + the design doc | `0` for every one; control: `Makefile` 1, `mk/` 5, `demos/` 20, `ui/` 16 (incl. `ui/ship_hud.gd`), 415 total; `ui/galaxy_map.gd` 0 but banned by the design and this plan regardless |
| Tools | `command -v make gmake perl timeout gtimeout`; `make --version`; `gmake --version` | `/usr/bin/make` GNU Make 3.81, `/opt/homebrew/bin/gmake` 4.4.1, `/usr/bin/perl`; no `timeout`/`gtimeout` (V19 holds) |
| Changelog convention | `cat changelogs/unreleased/README.md`; a recent fragment | fragments hold `### Added/Changed/Fixed` sections with `- ` bullets; the design's sentence is the bullet under `### Fixed` |
| Sprint JSON shape | `jq '.features \| length'`; array bounds | 20 features (→ 21); `.features` opens at l.124 and closes at l.881 (`  ],`); the new feature is appended last with keys id/depends_on/estimated_loc/files/acceptance_criteria/design_doc/sprint_plan/passes/notes; nothing else touched |

Not re-verifiable at planner time (make-target and drill-run facts; taken on the design's first-party evidence — V6, V13, V22, V26, V31, V32 — and re-measured first-hand by executor and controller during execution): the MG rc-0-19/0 survival through `make map-ism-test`, the 22-check fixed-tree counts, the four drill signatures, AC1's trailing `0`, and the V32 literal FAIL line.

Planner performed no implementation edit, no git write, no approval request and no make run; the only writes are this addendum and the one appended feature (scratch copies lived under `.godot/tmp/7nb-planner/`, ignored, removed at close).
