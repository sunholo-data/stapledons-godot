# Sprint plan: R1-7AQ-GUARD-SURVIVORS — guard survivors: free-nav-stop's own checks and the 7ao/7ap fold-ins (row 7aq)

**Design doc:** [m4-7aq-guard-survivors.md](m4-7aq-guard-survivors.md) (planned 2026-11-18; designer
Kimi K3's draft patch, Opus 5.5 takeover: review, re-measurement at `9081260f`, the doc; approved by
the mission controller — committed as `31841315` on the branch, the branch's only commit over the
base).
**Sprint JSON:** `.ailang/state/sprints/sprint_R1-7AQ-GUARD-SURVIVORS.json`.
**Approval basis:** neutral test hygiene — no pillar, spec, ruling or canon text touched (net 0, no
pillar below 0); no open questions (design: "Open questions for the user: None").
**Branch:** `mission/stapledon-iter98-7aq` (HEAD `31841315`, the design commit; merge-base with
`9081260f` is `9081260f` = the base every V-number was measured at; `git diff --name-only
9081260f...HEAD` = the design doc alone, so every V-number applies verbatim; `git status --porcelain`
empty — planner-checked, PV1). Base sha `9081260f` (`9081260f2577733826c588f57d13118bfa9b1827`).
**Scope:** 61 changed lines in seven files, applied byte-exactly from Appendix A (`git apply
--numstat`, planner-checked: `4 0 changelogs/unreleased/2026-11-18-guard-survivors.md`,
`5 0 mk/script-gates.mk`, `5 0 tests/fixtures/script_gate/prereq_dupe.mk.txt` (new),
`10 0 tests/test_free_nav_stop.gd`, `1 0 tests/test_loading_jump.gd`,
`13 1 tools/session_minor_guard_controls.sh`, `19 3 tools/test_replay.py` — `7 files changed,
57 insertions(+), 4 deletions(-)`; fence 149 lines, sha256
`cf27f2ce744cb0ee7609d6413db729d69c91bb1a7fbe264566f322288e2a32e0`). The changelog fragment rides
inside Appendix A (AC1 stages it first, by name). **No Makefile line is edited** (the S12/S1 drills
mutate it through `mut` and the EXIT trap restores); no product file (`ui/`, `bridge/`, `demos/`,
`main.gd`), no `*.ail`; no new script or scene → no new `.uid` (the new fixture is `.txt`, which
Godot does not import; uid-guard green on the patch, V4); no new `*.py` → no allowlist row
(`tools/test_replay.py` is already registered, `tools/python-allowlist.txt:24` — planner-read).

**Role split:** the planner (this file) checked the fence, the base gates and the cheap read-only
anchors from inside the planner sandbox (Plan verification — **well-formedness only, not evidence**;
no Godot there: it cannot write `user://` in the sandbox and hangs — the (f) environment limit) and
writes only this plan and the JSON (both **uncommitted** — the controller commits them with the
branch). The executor (Claude Haiku 5.5) applies Appendix A byte-exactly with
`git apply "$W/7aq.patch"` and commits it (AC1 does both, so each drill's trap restores to the
patched state), then runs every acceptance criterion AC1–AC12, in order, in one shell, in a full
clone with the pinned runtime, the sky and lens assets and an imported `.godot` (AC6–AC9 are
executor-side Godot runs, never in a pi sandbox), recording each output in the sprint JSON's
milestone `notes`. The controller lands (per the mission cycle): the PR, the cross-family evaluation
(generator ≠ judge), the charter row 7aq marked done, and the doc move to
`design_docs/implemented/r1/` with the README index row.

**Not run (explicit):** no `make golden`, no capture, no bench, no full local `make test` (merge
rule: the GitHub fast tier plus the targeted gates green locally; the nightly `rig/full` runs the
suite on main post-merge — CLAUDE.md definition-of-done 1). TEST-ONLY row: no product behaviour runs
differently. Every command needs only `python3`, `git`, `make`, `perl`, `sh` and, for AC6–AC9, Godot
4.7.2.stable with `PATH=$PWD/runtime/bin:$PATH` (the sim bridge execs the pinned AILANG v0.56.1).

## Environment (executor)

```sh
cd <executor full clone>             # runtime/, sky and lens assets, an imported .godot
                                     # (`make import` once if .godot is absent)
export PATH=$PWD/runtime/bin:$PATH   # the sim bridge needs the pinned AILANG v0.56.1 on PATH
python3 --version                    # 3.14.5 measured (design header)
command -v git make perl godot       # godot 4.7.2.stable (design header); the rig has NO GNU
                                     # timeout: every long command is bounded with
                                     #   perl -e 'alarm shift; exec @ARGV' <secs> ...
                                     # (the preamble's gate() already wraps each Godot gate in a
                                     # 2400 s perl-alarm)
```

**Godot evidence rule (binding, from the design):** AC6–AC9 are read from **named check lines** in
the per-run log copy, **never from the target's rc** — free-nav-stop flakes late (after the alpha
Cen legs) on the bridge's 2 s `step_timeout` under host load (the known cascade, controller M2 in
the design), and every line read here prints before the trip home. The preamble's `gate NAME TAG`
does the right thing mechanically: it deletes the reused `.godot/tmp/<target>.log` **before** each
run and copies it to `$W/<tag>.log` **after**; the greps read the copy, so a stale log can never
masquerade as a fresh one. A missing named line is a failure — stop (pause points); do not
substitute the rc.

## The AC preamble and command block (copied verbatim from the design doc — its lines 140–200, the two ` ```sh ` fences; normative — source it, never paraphrase it)

Byte-identical copy: 61 lines, 4166 bytes, sha256
`2acfff4a876a46df81ff672de97eb58bb8b5aa04d39069fed90a855dd40a0d82` (planner-assembled by extraction,
not retyped; PV3). The `D=` line keeps the doc's own `# design_docs/implemented/r1/… after landing`
comment verbatim: source the preamble from the planned path now, from the implemented path after the
doc moves.

```sh
D=design_docs/planned/r1/m4-7aq-guard-survivors.md   # design_docs/implemented/r1/… after landing
W=$(mktemp -d "${TMPDIR:-/tmp}/7aq.XXXXXXXX") || exit 1
# fence NAME: the body of the fence opened by a line "```<lang> NAME" in this doc
fence() { awk -v n="$1" '$0 ~ "^```[a-z]+ " n "$" { f = 1; next } f && /^```$/ { exit } f' "$D"; }
fence 7aq.patch > "$W/7aq.patch"; fence 7aq_mut.py > "$W/7aq_mut.py"
# gate NAME TAG: one Godot --script gate (make NAME-test), bounded, its log kept as $W/TAG.log (the gate reuses its log path)
gate() { rm -f ".godot/tmp/$1.log"; PATH=$PWD/runtime/bin:$PATH perl -e 'alarm shift; exec @ARGV' 2400 make "$1-test" > "$W/$2.make" 2>&1; echo "$2 rc=$?"; cp ".godot/tmp/$1.log" "$W/$2.log"; }
# mut NAME CMD...: apply one Appendix B mutation, run CMD, restore the touched files on any exit
mut() ( git diff --quiet HEAD -- tools/test_replay.py tools/script_gate_prereqs.sh Makefile tests/test_free_nav_stop.gd tests/test_loading_jump.gd tests/test_ship_star_identification.gd \
    || { echo "mut: a target file differs from HEAD"; exit 4; }
  trap 'git checkout -- tools/test_replay.py tools/script_gate_prereqs.sh Makefile tests/test_free_nav_stop.gd tests/test_loading_jump.gd tests/test_ship_star_identification.gd' EXIT
  n=$1; shift; python3 "$W/7aq_mut.py" "$n" && "$@" )
```

Each AC is one command group in the block below, marked `# ACn`.

```sh
# AC1
shasum -a 256 "$W/7aq.patch" | cut -d' ' -f1
git apply --check "$W/7aq.patch" && git apply "$W/7aq.patch" \
  && git add changelogs/unreleased/2026-11-18-guard-survivors.md mk/script-gates.mk tests/fixtures/script_gate/prereq_dupe.mk.txt \
       tests/test_free_nav_stop.gd tests/test_loading_jump.gd tools/session_minor_guard_controls.sh tools/test_replay.py \
  && git commit -q -m "7aq: guard survivors (free-nav eye refresh, 7ap/7ao fold-ins)" && echo committed
git diff --numstat HEAD~1 HEAD | awk '{ i += $1; d += $2 } END { print i, d }'
# AC2
python3 tools/test_replay.py MapIndex 2>&1 | grep -E '^Ran|^OK$|^FAILED'; python3 tools/test_replay.py 2>&1 | grep -E '^Ran|^OK$|^FAILED'
# AC3
for m in m5 m7 m8 m12 m13 m22 m23; do mut "$m" python3 tools/test_replay.py MapIndex 2>&1 | grep -m1 -E '^(FAIL|ERROR): ' | sed "s/^/$m /"; done
# AC4
make -s --no-print-directory script-gate-lint 2>&1 | tail -1 | cut -c1-32
sh tools/script_gate_prereqs.sh tests/fixtures/script_gate/prereq_dupe.mk.txt dupe:wanted-prereq; echo rc=$?
mut m33 make -s --no-print-directory script-gate-lint 2>&1 | grep -c '^script-gate-lint: FAIL the duplicate-rule control passed'
# AC5
make -s --no-print-directory session-minor-guard-controls 2>&1 | tail -1
for m in S12 S1; do mut "$m" make -s --no-print-directory session-minor-guard-controls 2>&1 | grep -E '^session-minor-guard-controls: (condwrap|revparen): make rc 0, want 2$' | sed "s/^/$m /"; done
# AC6 (Godot, 2-7 min)
gate free-nav-stop ac6; grep -E "^(ok|FAIL) the (test's blocker|fixed eye)" "$W/ac6.log" | cut -c1-60
# AC7 (Godot, 2-7 min: JM1 with JM2+JM3)
mut jm1 gate free-nav-stop ac7; grep -E "^(ok|FAIL) the (test's blocker|fixed eye)|^(ok|FAIL) its catalogue row is dark" "$W/ac7.log" | cut -c1-60
# AC8 (Godot, about 50 s each)
gate loading-jump ac8a; grep -E '^loading-jump: [0-9]+ passed|^(ok|FAIL) the override probe' "$W/ac8a.log" | cut -c1-60
mut t3 gate loading-jump ac8b; grep -E '^loading-jump: [0-9]+ passed|^(ok|FAIL) the override probe' "$W/ac8b.log" | cut -c1-60
# AC9 (Godot, under 1 min: the (c) deferral's premise, on the unchanged SSI check)
mut nopin gate ship-star-identification ac9; grep -E '^ship-star-identification: [0-9]+ passed|a pinned destination is offered once' "$W/ac9.log" | cut -c1-70
# AC10
make -s --no-print-directory python-guard uid-guard replay-map-index >/dev/null 2>&1; echo guards=$?
git diff --check HEAD~1 HEAD; echo check=$?
git diff --name-only HEAD~1 HEAD
# AC11
python3 -I -c "
import hashlib, sys
sys.path.insert(0, 'tools')
import test_replay as t
m = t.MapIndex()
c, b = t.source_index_pairs(m.sources(), m.stars())
print(len(c), b, hashlib.sha256('\n'.join(sorted(c)).encode()).hexdigest())
"
# AC12
rm -rf "$W"; git status --porcelain --untracked-files=all
```

Rules that come with it (design, normative): run the ACs **in order, in one shell, after the
preamble**; AC1 applies **and commits** the patch first, so each drill's trap restores to the
patched state, not to the base; `mut` refuses a target file that already differs from `HEAD`
(exit 4) and restores its files from an EXIT trap on success, failure or signal — AC12 proves
nothing is left behind. In AC7 the run may be stopped (kill the Godot process group) once all four
lines are present; the drill needs nothing later. The evidence fences live in the doc's appendices
(`7aq.patch` in Appendix A, `7aq_mut.py` in Appendix B — planner-checked, PV2) and are never
committed; `$W` is removed at AC12.

**Commit conventions (binding on the executor):** commit per milestone boundary, staging files **by
name** — never `git add -A`: (1) AC1's code commit, the seven patch paths exactly as its `git add`
lists them (the changelog fragment is one of the seven — it is Appendix A content, so the
fragment commit is realized inside AC1's commit by design; AC1's `57 4` numstat depends on it);
(2) the sprint-JSON evidence commit at M5 (`.ailang/state/sprints/sprint_R1-7AQ-GUARD-SURVIVORS.json`,
alone). The plan file and the first JSON are the controller's branch bookkeeping, not the
executor's. **Every commit message ends with the line
`Co-Authored-By: Claude Haiku 5.5 <noreply@anthropic.com>`** — for AC1 append it as a second `-m`:
`git commit -q -m "7aq: guard survivors (free-nav eye refresh, 7ap/7ao fold-ins)" -m
"Co-Authored-By: Claude Haiku 5.5 <noreply@anthropic.com>"`. The message gains a trailer; the tree
and the numstat are unchanged (7ap precedent: trailer amended in, tree identical).

## Byte-for-byte rule (binding)

Never retype appendix text into the tree. Extract the fence, prove it, apply it:

```sh
fence 7aq.patch > "$W/7aq.patch"          # through the preamble's fence()
wc -l < "$W/7aq.patch"        # expect 149 (planner-checked)
shasum -a 256 "$W/7aq.patch"  # expect cf27f2ce744cb0ee7609d6413db729d69c91bb1a7fbe264566f322288e2a32e0
git apply --check "$W/7aq.patch"          # clean (planner-checked: apply-ok)
git apply --numstat "$W/7aq.patch"
# expect: 4 0 changelogs/unreleased/2026-11-18-guard-survivors.md / 5 0 mk/script-gates.mk /
#         5 0 tests/fixtures/script_gate/prereq_dupe.mk.txt / 10 0 tests/test_free_nav_stop.gd /
#         1 0 tests/test_loading_jump.gd / 13 1 tools/session_minor_guard_controls.sh /
#         19 3 tools/test_replay.py
git apply "$W/7aq.patch"
```

AC1 then commits the seven files and prints `57 4` (`git diff --numstat HEAD~1 HEAD`). The doc
computed the sha256 over `git diff 9081260f HEAD` output in its scratch clone (V18, the patch
committed there as one scratch commit on the base). Reproduce that exactly after AC1's commit as the
applied-diff proof — the branch carries the design doc and the bookkeeping between `9081260f` and
HEAD, so path-limit the diff to the seven patch paths:

```sh
git diff 9081260f2577733826c588f57d13118bfa9b1827 HEAD -- \
  changelogs/unreleased/2026-11-18-guard-survivors.md mk/script-gates.mk \
  tests/fixtures/script_gate/prereq_dupe.mk.txt tests/test_free_nav_stop.gd \
  tests/test_loading_jump.gd tools/session_minor_guard_controls.sh tools/test_replay.py \
  > "$W/roundtrip.patch"
shasum -a 256 "$W/roundtrip.patch"   # expect the same cf27f2ce… — proof of no hand edits
```

A mismatch means re-extract, never retype. The patch touches nothing but the seven files → no new
script, no `.uid`, no allowlist row.

## Gate list (every target the change touches that the GitHub fast tier runs)

The GitHub fast tier runs on this PR as `make ci-fast` (`.github/workflows/ci.yml:60-62` —
planner-read; the runner installs Godot but `ci-fast` names no Godot script gate). `ci-fast`
prerequisites come from `Makefile:73`, `Makefile:134`, `Makefile:172`, `Makefile:513` and
`mk/script-gates.mk:28` (all planner-read at branch head, PV6). Every fast-tier target this patch
can affect:

| Gate | In ci-fast via | Target defined at | Why this patch affects it |
|---|---|---|---|
| `replay-map-index` | `Makefile:513` | `Makefile:511` | Its recipe is `python3 tools/test_replay.py MapIndex` — the patched file; test counts unchanged at 11 (the five texts join the existing control test, AC2). |
| `script-gate-lint` | `mk/script-gates.mk:28` (`ci-fast: script-gate-lint script-gate-selftest`) | `mk/script-gates.mk:33` | The lint recipe gains the duplicate-rule control (+5) and its new fixture `tests/fixtures/script_gate/prereq_dupe.mk.txt` (+5) (AC4). |
| `session-minor-guard-controls` | `Makefile:172` | `Makefile:207` | Its driver `tools/session_minor_guard_controls.sh` is patched (+13/−1): R28 `condwrap` and R29 `revparen` join, 27 → 29 rejected (AC5). |
| `session-minor-guard` | `Makefile:172` | `Makefile:173` | The guard itself is untouched; the controls prove it rejects the two new spellings (AC5); AC10 runs it as hygiene. |
| `python-guard` | `Makefile:73` | `Makefile:1163` | Hygiene: `tools/test_replay.py` is already allowlisted (`tools/python-allowlist.txt:24`), no new `*.py`; AC10 asserts it stays green. |
| `uid-guard` | `Makefile:73` | `Makefile:1175` | Hygiene: no new script → no new `.uid`; the new fixture is `.txt` (AC10). |

**Not in the fast tier:** the whole `python3 tools/test_replay.py` file (40 tests) — the tier runs
only the `MapIndex` class via `replay-map-index` (`Makefile:511` recipe, planner-read); the full
file runs as this row's targeted gate (AC2) and in the nightly via `tools-test`/`make test`. The
three Godot gates — `free-nav-stop-test` (`Makefile:1285`, SCRIPT_GATE 1800 s),
`loading-jump-test` (`Makefile:1313`), `ship-star-identification-test` (`Makefile:1277`, 600 s) —
are named by no `ci-fast:` edge (planner-read `Makefile:73/134/172/513`, `mk/script-gates.mk:28`);
they run executor-side (AC6–AC9) and controller-side.

Targeted gates for this row: **`python3 tools/test_replay.py MapIndex`,
`python3 tools/test_replay.py`, `make script-gate-lint`, `make session-minor-guard`,
`make session-minor-guard-controls`, `make python-guard uid-guard`, `make free-nav-stop-test`,
`make loading-jump-test`, `make ship-star-identification-test`**, and the GitHub fast tier
(`make ci-fast`) on the PR. Of these, all but the full-file harness run and the three Godot gates
are in `ci-fast` (table above, file:line).

## Test-first order

The RED evidence — each survivor green at the base — is the doc's own base measurements,
**doc-quoted**: V2 (m5, m7, m8, m12, m13, m14, m22, m23 each leave `Ran 11 tests … OK` at
`9081260f`), V3 (m33 leaves the lint `ok (9 pairs …)`; S12 and S1 each leave
`27 rejected, 3 accepted`), controller M3 and V9's patched control (`eye_clear`'s refresh dropped,
both eye lines stay `ok`), the 7ao judge's T3 (cited: the override probe's minor unpinned). The
design's AC block applies and commits the patch **first** (AC1) and asks for **no base drill
re-runs** — none are planned (the planner's sandbox base runs are well-formedness only, PV4, **not
evidence**). After the patch, every drill proves its control can fail: AC3 kills the seven MapIndex
mutations through the preamble's `mut`, AC4 kills m33, AC5 kills S12 and S1, AC7 kills JM1 (with
JM2+JM3 dropped in the same run, the dark-row line stays `ok` — the deferral-(b) witness), AC8's
second run kills T3, AC9's nopin confirms the shipped SSI pin check (the (c) deferral's premise).
Nothing is presented green that was never shown able to fail. The executor runs the doc's AC block
strictly in order AC1→AC12 in one shell after the preamble (design, normative); the milestones
below group the ACs for reporting and scoring — they do not re-sequence the run.

## Milestones

*(Authority: the design doc's "## Milestones" table — M1 (a) blocker, precondition check,
`tests/test_free_nav_stop.gd`, +10, any; M2 m5/m7/m8/m12/m13/m22/m23, `tools/test_replay.py`,
+19 −3, any; M3 S12/S1 controls + T3 pin, `tools/session_minor_guard_controls.sh` and
`tests/test_loading_jump.gd`, +14 −1, any; M4 m33, `mk/script-gates.mk` and
`tests/fixtures/script_gate/prereq_dupe.mk.txt`, +10, any; M5 evidence and changelog, AC1–AC12,
`changelogs/unreleased/…`, +4, last. The executor applies Appendix A as ONE patch and commits it —
AC1; the doc's expected wall time is about 20 minutes, mostly AC6 and AC7.)*

### M1 — (a) blocker, precondition check: `tests/test_free_nav_stop.gd`

*(Design Milestones table M1, order any.)* Files: `tests/test_free_nav_stop.gd` (+10/−0: the test
blocker — a 2 × 2 × 0.2 m `BoxMesh` under `demo.geometry`, placed 1 m ahead of the camera in
**global** coordinates, joined to the BVH through `ident.occlusion._collect(eye_block)` with the
size before recorded; the new precondition check `the test's blocker eclipses the fixed eye's centre
ray after update_candidates()`; the blocker hidden with no other refresh, then the **existing** eye
check unchanged; the one-line cleanup `meshes.resize(n)` + `free()` + `update_candidates()`). Part
of the single byte-exact apply. **Acceptance: AC6, AC7.**

1. **Apply phase (with M2–M4):** Byte-for-byte rule: fence 149 lines, sha256 `cf27f2ce…`,
   `git apply --check` clean, numstat the seven rows, `git apply`; AC1 commits the seven files
   (executed first, recorded under M5).
2. **AC6 (command verbatim from the AC block):** `gate free-nav-stop ac6; grep -E "^(ok|FAIL) the
   (test's blocker|fixed eye)" "$W/ac6.log" | cut -c1-60` → `ac6 rc=…` (0 on a quiet host, as in
   V8; 2 is the known load cascade and does not count), then exactly three lines: `ok the test's
   blocker eclipses the fixed eye's centre ray af`, `ok the fixed eye looks ahead past the ship (no
   surface on it`, `ok the fixed eye looks ahead past the ship (no surface on it`.
3. **AC7 (command verbatim; JM1 with JM2+JM3):** `mut jm1 gate free-nav-stop ac7; grep -E
   "^(ok|FAIL) the (test's blocker|fixed eye)|^(ok|FAIL) its catalogue row is dark" "$W/ac7.log" |
   cut -c1-60` → `ac7 rc=…` (nonzero), then exactly four lines in this order: `ok the test's blocker
   eclipses the fixed eye's centre ray af`, `FAIL the fixed eye looks ahead past the ship (no
   surface on ` (the cut keeps the trailing space), `ok its catalogue row is dark, replaced by the
   body, not pinn`, `ok the fixed eye looks ahead past the ship (no surface on it`. The run may be
   stopped once the four lines are present.

### M2 — m5, m7, m8, m12, m13, m22/m23: `tools/test_replay.py`

*(Design Milestones table M2, order any.)* Files: `tools/test_replay.py` (+19/−3:
`test_the_7ap_spellings_fail` gains the five control texts — `caret.gd`, `caretsq.gd`, `negsq.py`,
`topbrace.gd` (also kills m14: a bare top-level pair stays fail closed, wanted), `unc2.gd` — each
wrong index computed from `stars.json` at run time (`a + 1`); `test_the_7ap_guard_test_can_fail`
gains the final healthy run that must not raise). Part of the single byte-exact apply.
**Acceptance: AC2, AC3.**

1. **AC2 (commands verbatim):** `python3 tools/test_replay.py MapIndex 2>&1 | grep -E
   '^Ran|^OK$|^FAILED'` → `Ran 11 tests …`, `OK`; `python3 tools/test_replay.py 2>&1 | grep -E
   '^Ran|^OK$|^FAILED'` → `Ran 40 tests …`, `OK` (test counts unchanged: the texts join existing
   tests; the sandbox base reads the same 11/40, PV4 — not evidence).
2. **AC3 (command verbatim):** `for m in m5 m7 m8 m12 m13 m22 m23; do mut "$m" python3
   tools/test_replay.py MapIndex 2>&1 | grep -m1 -E '^(FAIL|ERROR): ' | sed "s/^/$m /"; done` →
   seven lines: `m5 FAIL: test_the_7ap_spellings_fail …`, `m7 FAIL: …spellings…`, `m8 FAIL:
   …spellings…`, `m12 ERROR: test_the_7ap_spellings_fail …`, `m13 FAIL: …spellings…`, `m22 FAIL:
   test_the_7ap_guard_test_can_fail …`, `m23 FAIL: …guard_test_can_fail…` (doc expected table; base
   survival V2, doc-quoted).

### M3 — S12, S1 controls; T3 pin: `tools/session_minor_guard_controls.sh`, `tests/test_loading_jump.gd`

*(Design Milestones table M3, order any.)* Files: `tools/session_minor_guard_controls.sh` (+13/−1:
R28 `condwrap` — the prefetch wrapped in `if OS.has_feature("x"):` must be refused; R29 `revparen` —
the reversed comparison in parentheses must be named; the count moves 27 → 29 rejected, 3 accepted
unchanged; the corrected R29 comment), `tests/test_loading_jump.gd` (+1/−0: the T3 pin check `the
override probe asks the warm sim's own minor, so only the launch override can refuse it`). Part of
the single byte-exact apply. **Acceptance: AC5, AC8.**

1. **AC5 (commands verbatim):** `make -s --no-print-directory session-minor-guard-controls 2>&1 |
   tail -1` → `session-minor-guard-controls: 29 rejected, 3 accepted`; then `for m in S12 S1; do
   mut "$m" make -s --no-print-directory session-minor-guard-controls 2>&1 | grep -E
   '^session-minor-guard-controls: (condwrap|revparen): make rc 0, want 2$' | sed "s/^/$m /"; done`
   → `S12 session-minor-guard-controls: condwrap: make rc 0, want 2`, `S1
   session-minor-guard-controls: revparen: make rc 0, want 2` (doc expected table; base survival
   V3, doc-quoted).
2. **AC8 (commands verbatim; about 50 s each):** `gate loading-jump ac8a; grep -E '^loading-jump:
   [0-9]+ passed|^(ok|FAIL) the override probe' "$W/ac8a.log" | cut -c1-60` → `ac8a rc=0`, `ok the
   override probe asks the warm sim's own minor, so only`, `loading-jump: 84 passed, 0 failures`;
   then `mut t3 gate loading-jump ac8b; grep -E '^loading-jump: [0-9]+ passed|^(ok|FAIL) the
   override probe' "$W/ac8b.log" | cut -c1-60` → `ac8b rc=2`, `FAIL the override probe asks the warm
   sim's own minor, so on`, `loading-jump: 83 passed, 1 failures` (doc expected table; V10/V11).

### M4 — m33: `mk/script-gates.mk`, `tests/fixtures/script_gate/prereq_dupe.mk.txt`

*(Design Milestones table M4, order any.)* Files: `mk/script-gates.mk` (+5/−0: the lint recipe gains
the duplicate-rule control — make merges single-colon rule lines, so only a double-colon fixture can
show awk two stanzas, V7), `tests/fixtures/script_gate/prereq_dupe.mk.txt` (new, +5/−0: the two
`dupe::` stanzas). Part of the single byte-exact apply. **Acceptance: AC4.**

1. **AC4 (commands verbatim, three groups):** `make -s --no-print-directory script-gate-lint 2>&1 |
   tail -1 | cut -c1-32` → `script-gate-prereqs: ok (9 pairs`; `sh tools/script_gate_prereqs.sh
   tests/fixtures/script_gate/prereq_dupe.mk.txt dupe:wanted-prereq; echo rc=$?` →
   `script-gate-prereqs: dupe lost its prerequisite wanted-prereq (dupe:: nothing-here)`, `rc=1`;
   `mut m33 make -s --no-print-directory script-gate-lint 2>&1 | grep -c '^script-gate-lint: FAIL
   the duplicate-rule control passed'` → `1` (doc expected table; base survival V3, mechanism
   V6/V7, doc-quoted).

### M5 — Evidence and changelog: AC1–AC12 assembled, the fragment, the JSON

*(Design Milestones table M5: last.)* Files:
`changelogs/unreleased/2026-11-18-guard-survivors.md` (new, +4/−0; it is Appendix A content —
committed inside AC1's commit, staged by name; per `changelogs/unreleased/README.md`, one
`YYYY-MM-DD-<slug>.md` file), `.ailang/state/sprints/sprint_R1-7AQ-GUARD-SURVIVORS.json`
(evidence). The design's M5 row names AC1–AC12 because this milestone assembles the evidence; in
the sprint JSON each AC is recorded exactly once, against the milestone it proves (M1–M4 the patched
behaviour; M5 the cross-cutting verification: patch identity, the (c) deferral's premise, hygiene,
scope, the real-tree pin, cleanliness). **Acceptance: AC1, AC9, AC10, AC11, AC12.**

1. **AC1 (first in execution order; commands verbatim):** `shasum -a 256 "$W/7aq.patch" | cut -d' '
   -f1` → `cf27f2ce744cb0ee7609d6413db729d69c91bb1a7fbe264566f322288e2a32e0` (planner-checked);
   `git apply --check "$W/7aq.patch" && git apply "$W/7aq.patch" && git add
   changelogs/unreleased/2026-11-18-guard-survivors.md mk/script-gates.mk
   tests/fixtures/script_gate/prereq_dupe.mk.txt tests/test_free_nav_stop.gd
   tests/test_loading_jump.gd tools/session_minor_guard_controls.sh tools/test_replay.py && git
   commit -q -m "7aq: guard survivors (free-nav eye refresh, 7ap/7ao fold-ins)" && echo committed`
   → `committed` (append the Co-Authored-By trailer as a second `-m`, Commit conventions); `git
   diff --numstat HEAD~1 HEAD | awk '{ i += $1; d += $2 } END { print i, d }'` → `57 4`
   (planner-checked on the extracted fence). Then the round-trip proof (Byte-for-byte rule): the
   path-limited `git diff 9081260f… HEAD` re-hashes to the same `cf27f2ce…`.
2. **AC9 (command verbatim; the (c) deferral's premise on the UNCHANGED SSI check):** `mut nopin
   gate ship-star-identification ac9; grep -E '^ship-star-identification: [0-9]+ passed|a pinned
   destination is offered once' "$W/ac9.log" | cut -c1-70` → `ac9 rc=2`, `ERROR: a pinned
   destination is offered once, as its pin row (1 candida`, `ship-star-identification: 59 passed, 1
   failures` (V12). `tests/test_ship_star_identification.gd` is mutated by the drill and
   trap-restored; the patch never touches it.
3. **AC10 (commands verbatim):** `make -s --no-print-directory python-guard uid-guard
   replay-map-index >/dev/null 2>&1; echo guards=$?` → `guards=0`; `git diff --check HEAD~1 HEAD;
   echo check=$?` → `check=0` (the diff is exactly the seven committed paths; the patch's blank
   context lines carry the standard single leading space); `git diff --name-only HEAD~1 HEAD` → the
   seven paths, one per line: `changelogs/unreleased/2026-11-18-guard-survivors.md
   mk/script-gates.mk tests/fixtures/script_gate/prereq_dupe.mk.txt tests/test_free_nav_stop.gd
   tests/test_loading_jump.gd tools/session_minor_guard_controls.sh tools/test_replay.py`.
4. **AC11 (command verbatim; the real-tree checked set is unchanged — 7ap AC12's pin):** the inline
   Python → `16 [] 67f76aef3d3b7ad8219067e91e6a259edfe92dca00c16d53196f1dd6e4927566` (V17 on the
   patched tree; the sandbox base agrees, PV5 — not evidence). A legitimate new tracked pair moves
   the pin — name the delta and move it; a shrunk or changed set with no new pair is a blinding
   regression: stop.
5. **AC12 (command verbatim, last):** `rm -rf "$W"; git status --porcelain --untracked-files=all` →
   empty. Before landing, the executor (with `gh`) lists open PRs' files and halts on any hit among
   the seven paths (design Conflict surface; the planner sandbox had no `gh` either — if the
   executor lacks it, record that and hand the re-check to the controller; never land past it).
6. **Sprint JSON evidence:** fill each milestone's `measured`/`notes` (M1: AC6's `ac6 rc=…` note +
   the three ok lines, AC7's `ac7 rc=…` + the four lines in order; M2: AC2's two `Ran … OK` pairs,
   AC3's seven kill lines; M3: AC5's `29 rejected, 3 accepted` + the two named kill lines, AC8's
   `ac8a rc=0` / ok line / `84 passed, 0 failures` and `ac8b rc=2` / FAIL line /
   `83 passed, 1 failures`; M4: AC4's ok-prefix, the refusal + `rc=1`, the count `1`; M5: AC1's sha
   + `committed` + `57 4` + the round-trip sha, AC9's three lines, AC10's `guards=0` / `check=0` /
   the seven paths, AC11's pin line, AC12's empty status, the fragment path), set `passes: true`
   per milestone, `status` → `executed`, and wall-clock totals under `velocity`.
7. **Evidence commit:** stage `.ailang/state/sprints/sprint_R1-7AQ-GUARD-SURVIVORS.json` **by
   name** and commit it alone (message e.g. `7aq: sprint evidence (AC1-AC12)` + the Co-Authored-By
   trailer — Commit conventions). This is the evidence commit the AC12 cleanliness check precedes:
   run AC12's `git status --porcelain` **before** this commit (the JSON edit is the only intended
   post-AC12 change; stage it, commit, then confirm porcelain empty once more).

## Pause points (stop and report; do not improvise)

- Fence extraction ≠ 149 lines, sha256 ≠ `cf27f2ce…`, or `git apply --check` fails → re-extract,
  never retype. The applied numstat ≠ `57 4` over exactly the seven files, or the round-trip
  path-limited diff's sha256 ≠ the fence's → stop.
- Any AC line differing from the design doc's expected table → stop. Specifically: AC2 ≠ `Ran 11
  tests … OK` / `Ran 40 tests … OK`; AC3 ≠ seven kill lines or one names a different test (m12's is
  an `ERROR:`, the rest `FAIL:`); AC4 ≠ the `script-gate-prereqs: ok (9 pairs` prefix, the named
  refusal with `rc=1`, the count `1`; AC5 ≠ `29 rejected, 3 accepted` or the two named control
  lines; AC6 ≠ exactly the three ok lines (rc 2 under load does not count, but the three lines are
  required); AC7 ≠ the four lines in that order (the FAIL cut keeps its trailing space); AC8 ≠
  `ac8a rc=0` with `84 passed, 0 failures` then `ac8b rc=2` with `83 passed, 1 failures`; AC9 ≠ the
  three lines; AC10 ≠ `guards=0` / `check=0` / the seven paths; AC11 ≠ `16 []` with the pinned sha
  and no new tracked pair to name; AC12 non-empty → stop.
- Godot reads: never the target's rc as the verdict (the load cascade fails the late legs after
  every needed line has printed). A named line missing from `$W/<tag>.log` → stop. Never retry-loop
  a flaked late leg into a pass; never grep the reused `.godot/tmp/<target>.log` instead of the
  per-run copy.
- A Godot run SCRIPT ERRORs on `user://` (`identify-test.bin`) → the executor is inside a sandbox
  (the (f) environment limit): stop, mark AC6–AC9 CONTROLLER-RUN, report; never skip silently,
  never patch a test to dodge it.
- `mut` refusing a dirty target (exit 4, `mut: a target file differs from HEAD`) → a previous run
  left the tree mutated: stop, `git checkout -- tools/test_replay.py tools/script_gate_prereqs.sh
  Makefile tests/test_free_nav_stop.gd tests/test_loading_jump.gd
  tests/test_ship_star_identification.gd`, report; never force past it. `git status --porcelain`
  non-empty after any drill → the trap failed: stop and report; do not start the next AC.
- AC12's pre-landing PR re-check: any hit among the seven paths halts the landing; `gh` or network
  unavailable to the executor → record that and hand the re-check to the controller. Never land
  past it; never widen the patch to pre-empt a conflict.
- Any temptation to touch the do-not-touch list → stop; the fix needs none of it. In particular no
  Makefile line and no `tools/script_gate_prereqs.sh` line is edited by the patch (the S12/S1/m33
  drills mutate them through `mut` and the trap restores), and the shipped SSI pin check's clauses
  stay as shipped (the draft's drop of `"b" in pinned_ids` is the 7an judge's JM-A3 itself —
  rejected, deferral (c)).
- No merge before the cross-family evaluation (generator ≠ judge); landing files wait on it.

## Risks (from the design; planner additions marked)

- **The free-nav run fails late under load and an executor reads the rc** → every AC reads named
  lines that print before the trip home; the AC table says rc 2 under load does not count
  (controller M2) (design).
- **`_collect` is an underscore method of `ui/star_occlusion.gd`** → called from a test, which
  GDScript allows; a rename makes the line a SCRIPT ERROR, which the gate fails loudly; the
  precondition check (`meshes.size() == n + 1`) catches a `_collect` that silently stops adding
  (design).
- **`resize(n)` removes a real mesh if `_collect` added nothing** → `_collect` adds exactly one
  entry for a `MeshInstance3D` with a triangle `BoxMesh` and no children; the precondition check
  fails first if it did not, and the AC6 lines after it would show the damage (design).
- **The blocker leaks into later checks** → hidden before the eye check, removed from the BVH and
  freed on the next line, `update_candidates()` recomputes; the later offer, card and alpha Cen
  checks pass (V8) (design).
- **`topbrace.gd` also pins top-level pairing (m14)** → wanted: a bare top-level pair is checked
  today (fail closed); stated in M2 (design).
- **The dupe fixture relies on double-colon semantics of GNU Make 3.81** → measured on this host
  (V7); the lint fails loudly, not silently, if a make prints the stanzas merged (the control then
  reads `ok`, and the lint says so) (design).
- **(Planner-added) The Godot log path is reused between runs** → `gate()` deletes
  `.godot/tmp/<target>.log` before each run and copies it to `$W/<tag>.log` after; the greps read
  the copy, so a stale log can never masquerade as a fresh one (mission constraint, encoded in the
  preamble).
- **(Planner-added) The planner sandbox's green base runs are not evidence** → plan_verification
  says so explicitly; the executor's full-clone run is the only evidence (mission rule). The
  sandbox forbids Godot (`user://` — the (f) limit), so AC6–AC9 were not even smoke-run by the
  planner.
- **(Planner-added) Open PRs unknown to the planner** (no `gh`, no network in the sandbox;
  the designer had none either, design Conflict surface) → AC12's note is blocking at landing; the
  controller's landing checklist re-runs it.
- **(Planner-added) AC1's commit gains the Co-Authored-By trailer** → message-only adaptation, the
  tree and the `57 4` numstat unchanged (7ap precedent: "message amended to name the sprint; tree
  unchanged").

## Files allowed and do-not-touch

- **Allowed:** `changelogs/unreleased/2026-11-18-guard-survivors.md`, `mk/script-gates.mk`,
  `tests/fixtures/script_gate/prereq_dupe.mk.txt`, `tests/test_free_nav_stop.gd`,
  `tests/test_loading_jump.gd`, `tools/session_minor_guard_controls.sh`, `tools/test_replay.py`
  (all seven strictly via `git apply "$W/7aq.patch"`);
  `.ailang/state/sprints/sprint_R1-7AQ-GUARD-SURVIVORS.json` (evidence); scratch under `$W`
  (mktemp) and `.godot/tmp`. The drills' mutations of `tools/test_replay.py`,
  `tools/script_gate_prereqs.sh`, `Makefile`, `tests/test_free_nav_stop.gd`,
  `tests/test_loading_jump.gd`, `tests/test_ship_star_identification.gd` happen only through `mut`
  and are trap-restored; `$W/7aq_mut.py` is never committed. Landing edits (charter row, README
  index, doc move) are routine for the controller.
- **Do not touch** (design Non-goals): any product file (`ui/`, `bridge/`, `demos/`, `main.gd`);
  any `*.ail`; any Makefile line; `tools/script_gate_prereqs.sh`;
  `tests/test_ship_star_identification.gd`; the shipped SSI pin check's clauses (deferral (c));
  anything under `design_docs/stapledon-mission*` (controller-only). No `.uid`, no data, no asset,
  no shader, no golden, no capture.

## Local PR gates (targeted, headless or named-line Godot, bounded)

1. M1 on record: AC6's `ac6 rc=…` note + the three ok lines; AC7's `ac7 rc=…` + the four lines in
   order (the FAIL line's cut keeps the trailing space).
2. M2 on record: AC2's `Ran 11 tests … OK` and `Ran 40 tests … OK`; AC3's seven kill lines
   (m12's an `ERROR:`, the rest `FAIL:`).
3. M3 on record: AC5's `29 rejected, 3 accepted` and the two named kill lines; AC8's `ac8a rc=0` /
   ok line / `84 passed, 0 failures` and `ac8b rc=2` / FAIL line / `83 passed, 1 failures`.
4. M4 on record: AC4's `script-gate-prereqs: ok (9 pairs` prefix; the dupe refusal + `rc=1`; the
   count `1`.
5. M5 on record: AC1's sha256 + `committed` + `57 4` and the round-trip sha256; AC9's `ac9 rc=2` /
   ERROR line / `59 passed, 1 failures`; AC10's `guards=0` / `check=0` / the seven paths; AC11's
   `16 []` + sha256; AC12's empty status; the fragment in place (inside AC1's commit); the JSON's
   `measured`/`notes` filled, `passes: true`.
6. The GitHub gate: `make ci-fast` green on the PR (`.github/workflows/ci.yml:60-62`) — it runs
   `replay-map-index` (`Makefile:513`), `script-gate-lint` (`mk/script-gates.mk:28`),
   `session-minor-guard` and `session-minor-guard-controls` (`Makefile:172`), `python-guard` and
   `uid-guard` (`Makefile:73`).
7. **Not run:** no GPU gate, no `make golden`, no capture, no bench, no full local `make test`
   (merge rule); the nightly `rig/full` runs the whole suite — including the full
   `tools/test_replay.py` via `tools-test` and the Godot gates — on main post-merge.

## Plan verification (planner, 2026-11-18, HEAD `31841315`; sandbox well-formedness only — NOT evidence)

The planner runs inside a sandbox: **no Godot** (it cannot write `user://` there and hangs — the
(f) environment limit, design Deferred items), **no network, no `gh`, no git write operations**.
Every command below is read-only; scratch in `/tmp/claude/7aq-plan`, deleted after; `git status
--porcelain` empty after every run (checked). These runs prove the doc's commands are well-formed
and the base looks as the doc says; **they are not evidence — the executor's full-clone run is.**

- **PV1 — base/HEAD.** `git rev-parse HEAD` → `3184131539cbb07587a9015652aab0ae7e2c3b44`;
  `git merge-base HEAD 9081260f…` → `9081260f2577733826c588f57d13118bfa9b1827`; `git diff
  --name-only 9081260f...HEAD` → one line, `design_docs/planned/r1/m4-7aq-guard-survivors.md`;
  status empty. **planner-checked (sandbox).**
- **PV2 — Appendix A applies (not applied).** The fence cut with the doc's own `fence` function →
  **149 lines**, sha256 **`cf27f2ce744cb0ee7609d6413db729d69c91bb1a7fbe264566f322288e2a32e0`** (the
  doc's AC1 expectation); `git apply --check` → clean; `git apply --numstat` →
  `4 0 changelogs/unreleased/2026-11-18-guard-survivors.md`, `5 0 mk/script-gates.mk`,
  `5 0 tests/fixtures/script_gate/prereq_dupe.mk.txt`, `10 0 tests/test_free_nav_stop.gd`,
  `1 0 tests/test_loading_jump.gd`, `13 1 tools/session_minor_guard_controls.sh`,
  `19 3 tools/test_replay.py`; `--stat` tail → ` 7 files changed, 57 insertions(+), 4 deletions(-)`.
  The `7aq_mut.py` fence extracts to 26 lines. Temp kept under `/tmp/claude/7aq-plan` only; the
  patch was NOT applied to the tree; porcelain empty. **planner-checked (sandbox).**
- **PV3 — the copied AC block.** This plan's "AC preamble and command block" section is
  byte-identical to the design doc's lines 140–200 (the two ` ```sh ` fences: the preamble and the
  AC1–AC12 command groups): 61 lines, 4166 bytes, sha256
  **`2acfff4a876a46df81ff672de97eb58bb8b5aa04d39069fed90a855dd40a0d82`**. Assembled by extraction
  (`sed -n '140,200p'`) and inserted by script, never retyped. **planner-checked.**
- **PV4 — the base is green (V1's shape; sandbox, NOT evidence).** `python3 tools/test_replay.py
  MapIndex` → `Ran 11 tests in 0.293s` / `OK`; `python3 tools/test_replay.py` → `Ran 40 tests in
  3.268s` / `OK` (counts match AC2's expectation — unchanged, the texts join existing tests);
  `make -s --no-print-directory script-gate-lint | tail -1` → `script-gate-prereqs: ok (9 pairs
  hold in Makefile: … ci-fast:session-minor-guard-controls)`; `make -s --no-print-directory
  session-minor-guard-controls | tail -1` → `session-minor-guard-controls: 27 rejected,
  3 accepted`; `make -s --no-print-directory session-minor-guard | tail -1` → `session minor
  guard: ok, SESSION_MINOR (18) = EARTH_LOG_MINOR; …`; `make -s --no-print-directory python-guard
  uid-guard` → rc 0. Wall 12 s for the five. **planner-checked (sandbox, not evidence).**
- **PV5 — AC11's pin at the base (sandbox, NOT evidence).** The AC11 inline Python →
  `16 [] 67f76aef3d3b7ad8219067e91e6a259edfe92dca00c16d53196f1dd6e4927566` — matches the doc's AC11
  expectation (7ap AC12's pin). **planner-checked (sandbox, not evidence).**
- **PV6 — gate anchors and tools (grep/sed reads).** `Makefile:73` ci-fast's `python-guard` and
  `uid-guard` (targets `:1163`, `:1175`); `Makefile:134 ci-fast: similar-main-guard
  similar-guard-controls`; `Makefile:172 ci-fast: session-minor-guard
  session-minor-guard-controls` (targets `:173`, `:207`); `Makefile:513 ci-fast: replay-map-index`,
  target `Makefile:511` (recipe `python3 tools/test_replay.py MapIndex`); `Makefile:1277`
  `ship-star-identification-test` (SCRIPT_GATE, 600 s), `:1285` `free-nav-stop-test` (1800 s;
  `ship-demo-ci:` at `:1283`/`:1287`), `:1313` `loading-jump-test`; `mk/script-gates.mk:18`
  `SG_PREREQS` 9 pairs, `:21` `SG_PREREQS_PAIRS := 9`, `:28 ci-fast: script-gate-lint
  script-gate-selftest`, `:33` the lint target; `.github/workflows/ci.yml:60-62` runs `make
  ci-fast` on PRs; `tools/python-allowlist.txt:24` = `tools/test_replay.py<TAB>harness`;
  `runtime/bin/ailang` present; `.godot/` imported; `assets/` present; `godot` at
  `/opt/homebrew/bin/godot` (**not run** — sandbox). **planner-checked (sandbox reads).**

**Doc-quoted (not re-measured by the planner):** every V-number (V1–V20, all re-measured by the
reviewer at `9081260f` or controller-attributed); the base survival of the eleven fold-in mutations
and T3 (V2, V3, controller M3, 7ao judge T3 cited); AC6–AC9's expected lines and wall times (V8–V12:
385 s free-nav patched, 122 s to AC7's four lines, 49/37 s loading-jump, 7 s SSI nopin); the host's
GNU Make 3.81 double-colon semantics (V7); the conflict surface (V18: the seven files' last commits
are landed rows, no local-only branches; the PR re-check is AC12's note, executor/controller-side);
the design's wall-time estimate (about 20 minutes, mostly AC6 and AC7).

## Velocity / estimate

61 changed lines in seven files (57 insertions, 4 deletions), byte-exact from Appendix A; the
changelog fragment rides inside the patch; the drills come from Appendix B. One iteration planned
(as 7ak ~4 LOC, 7ai ~16, 7aj ~55, 7an ~42, 7ap ~82, 7ao ~103; 7am ~135). Milestone estimates: the
headless ACs (AC1–AC5, AC10–AC12) under 1 minute together (design; the sandbox base ran the five
gates in 12 s, PV4 — not evidence); AC8 ≈ 50 s twice (V10: 49 s; V11: 37 s) and AC9 under 1 minute
(V12: 7 s); AC6 2–7 min (V8: 385 s wall on a loaded host) and AC7 2–7 min (V9: stopped at 122 s
once the four lines were present) dominate. The design's estimate: about 20 minutes wall, mostly
AC6 and AC7. **Executor wall-clock estimate: ~30–40 minutes** (clone checks ~5 min; commands ~20
min; evidence ~5–10 min).

**Cap (the bound the controller should give the executor).** Each Godot gate call is already bounded
by the preamble's 2400 s perl-alarm (the make targets' own SCRIPT_GATE bounds are tighter: 1800 s
free-nav-stop, 600 s loading-jump and ship-star-identification — planner-read, PV6); the headless
ACs are seconds each. Worst honest path: AC6 + AC7 toward their late legs (≤ 2 × 7 min — AC7 may be
stopped at four lines) + AC8 twice + AC9 + the headless minute ≈ 20 min of commands (design); 2 ×
for host load and evidence + a floor → **cap the executor at 60 minutes wall-clock from start**
(the 7ao/7ap 30-minute floor, doubled for the two free-nav legs; no separate `gh` bound needed —
AC12's re-check is a note handed to the controller if the executor lacks `gh`).
