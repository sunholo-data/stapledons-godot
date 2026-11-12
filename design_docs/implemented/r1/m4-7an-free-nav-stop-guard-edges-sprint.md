# Sprint plan: R1-7AN-FREE-NAV-GUARD-EDGES (landed 2026-11-12, PR #429) — free-nav-stop's I checks: the guard's edges (row 7an)

**Design doc:** [m4-7an-free-nav-stop-guard-edges.md](m4-7an-free-nav-stop-guard-edges.md) (revision 2;
quorum round 1 BLOCKED at 2 seats, sol REJECT on the unbounded mutation runner → designer revision 1
(bounded `run` through `tools/script_gate.sh`, `reap`, `mutate` with an EXIT-trap restore, every mutation
AC re-measured, V27–V32); round 2 BLOCKED at 2 seats, gemini PASS, sol REJECT on cross-session isolation
→ controller revision 2 under the narrow-refinement carve-out (sol's fix applied verbatim: per-session
`W=$(mktemp -d …)`, same-clone sessions prohibited, the two-clone drill V33). No round 3.)
**Sprint JSON:** `.ailang/state/sprints/sprint_R1-7AN-FREE-NAV-GUARD-EDGES.json`.
**Approval basis:** pillar table net 0, no pillar below 0 (neutral suite hygiene — every 0 means "not
touched"), no open questions.
**Branch:** `mission/stapledon-iter89-7an` (HEAD `0ac39ca4`, the r2 design commit; merge-base with
`origin/main` is `b96b2d60` = `origin/main` = the base every V-number was measured at;
`git diff --name-only origin/main...HEAD` = the design doc alone, so every V-number applies verbatim;
`git status --porcelain` empty).
**Scope:** 42 lines in two test files — `tests/test_free_nav_stop.gd` (+35/−2: the `sky_hides`,
`eye_clear`, `catalogue_rows_lit` helpers, two preloads, three new checks, two changed checks) and
`tests/test_ship_star_identification.gd` (+5: the pin-fixture check) — applied byte-exactly from Appendix
A (`git apply --stat`: `2 files changed, 40 insertions(+), 2 deletions(-)`, V25, planner-replicated),
plus the changelog fragment. No product, asset, Makefile, shader, golden or `*.ail` change.
**No GPU, no `make golden`, no capture, no full local `make test`** (merge rule, CLAUDE.md; 7ah–7am
precedent). The targeted gates are **`make free-nav-stop-test`, `make ship-star-identification-test`,
`make uid-guard`, `make python-guard`**, and the GitHub fast tier (`make ci-fast`) on the PR. The nightly
`rig/full` runs the suite on main post-merge.

**Role split:** the planner ran the pristine full target once (foreground) plus cheap read-only checks
(Plan verification), made no tree writes outside `.godot/tmp` scratch, and commits only this plan and the
JSON. The executor applies Appendix A and runs every AC below in its own disposable full clone. The
controller lands (per the mission cycle).

## Environment (executor)

```sh
cd <executor clone>          # the disposable tree: its own full clone ../stapledons-godot-<topic>
                             # (CLAUDE.md "Checkouts"; no worktrees). Only that clone is ever mutated.
export PATH=$PWD/runtime/bin:$PATH   # AILANG v0.56.1. runtime/ is UNTRACKED (planner-measured):
                             # a fresh clone may lack it -> use the main checkout's
                             # /Users/voightkampff/dev/sunholo-data/stapledons-godot/runtime/bin instead.
B=b96b2d60                   # origin/main = merge-base = the design's measured base
ailang --version             # expect "AILANG v0.56.1" (commit 05c860a); anything else -> stop
godot --version              # expect 4.7.2.stable…
```

**Environment requirements (all planner-measured as failures in the planner's own sandbox):**

1. **`user://` must be writable.** `tests/test_ship_star_identification.gd:45` writes
   `user://identify-test.bin`; where `~/Library/Application Support/Godot` is read-only the open returns
   null and the test SCRIPT ERRORs (`Cannot call method 'store_buffer' on a null value`), never reaches
   `quit()`, and hangs until the gate's 600 s budget. AC2 and AC9's `ac9s` half need it.
   `make free-nav-stop-test` and the short copies do not (planner-measured green here).
2. **`ps` must work.** The preamble's `mine`/`reap` parse `ps -axo pid=,command=`; a sandbox that denies
   process listing cannot run the mutation ACs.
3. **`/tmp` may be refused.** If so, `mkdir -p $PWD/.godot/tmp/7an && export TMPDIR=$PWD/.godot/tmp/7an`
   before sourcing the preamble — `mktemp` honours `TMPDIR`, and the per-session unique `7an.XXXXXXXX`
   prefix (the V33 isolation property) is unchanged. Expectations are byte-identical.

## The AC preamble (copied verbatim from the design doc; normative — source it, never paraphrase it)

Source AFTER Appendix A is applied (`short` cuts the patched test; V24 measured it reproduces the
prototype copies byte for byte). If a new shell starts MS2, re-source it — the test files are committed
at MS1's end, so `short` reproduces the same copies.

```sh
T=tests/test_free_nav_stop.gd; S=tests/test_ship_star_identification.gd; R=$PWD
W=$(mktemp -d "${TMPDIR:-/tmp}/7an.XXXXXXXX") || exit 1; export W
# Processes this clone's runs own: Godot on a $W script, the sim on this clone's sim/ (its own process group).
mine() { ps -axo pid=,command= | grep -F -e "--script $W/" -e "--package-dir $R/sim " | grep -v -F 'grep -F' | awk '{print $1}'; }
# reap: wait up to 5 s for them to exit, then TERM, 2 s, KILL; says what it had to kill.
reap() { _ri=0; while [ -n "$(mine)" ] && [ $_ri -lt 5 ]; do sleep 1; _ri=$((_ri+1)); done; _rp=$(mine); [ -z "$_rp" ] && return 0; echo "reap: leftover" $_rp; echo "$_rp" | xargs kill -TERM 2>/dev/null; sleep 2; _rp=$(mine); [ -n "$_rp" ] && echo "$_rp" | xargs kill -KILL 2>/dev/null; return 0; }
# run NAME BUDGET_S WANT_RC SUMMARY_ERE SCRIPT: tools/script_gate.sh bounds Godot (own process group; TERM at the
# deadline, KILL 2 s later, rc 142) and passes only on rc == WANT_RC, no SCRIPT ERROR and a summary matching the ERE.
# Log $W/NAME.log. Returns 0 when all hold, 142 on a timeout (an instrument failure, never a kill), 1 otherwise.
run() { _ro=$(sh tools/script_gate.sh "$1" "$W/$1.log" "$2" "$4" "$3" -- AILANG_BIN="$(command -v ailang)" godot --headless --path . --script "$5"); _rs=$?; printf '%s\n' "$_ro"; reap; case $_ro in *"timeout after"*) return 142 ;; esac; return $_rs; }
# mutate FILE SED_EXPR NAME BUDGET_S WANT_RC SUMMARY_ERE SCRIPT: edits FILE in this disposable clone for one run;
# the subshell's EXIT trap reaps and restores FILE on success, failure, timeout, interrupt (INT) or termination (TERM).
mutate() ( f=$1; e=$2; shift 2
  git diff --quiet HEAD -- "$f" || { echo "mutate: $f already differs from HEAD; restore it first"; exit 4; }
  trap 'reap; git checkout -- "$f"' EXIT; trap 'exit 130' INT; trap 'exit 143' TERM
  sed -i.bak -e "$e" "$f" && rm -f "$f.bak"; git diff --quiet -- "$f" && { echo "mutate: $f unchanged"; exit 3; }
  run "$@" )
short() { n=$(grep -nx "$(printf '\t')ident.set_held(false)" "$1" | tail -1 | cut -d: -f1); { head -n "$n" "$1"; printf '\tprint("free-nav-stop: %%d passed, %%d failures" %% [passed, failures]); quit(1 if failures else 0)\n'; } > "$2"; }
short $T $W/short.gd; cp $S $W/ssi.gd
```

Rules that come with it (design, normative): every mutation AC goes through `mutate`; one at a time, in
the foreground; no other Godot run may load the tree meanwhile; **simultaneous acceptance sessions within
the same clone are prohibited** (quorum r2, sol; V33); the mutation ACs are **never started as `&` jobs**
(V30's negative control: a non-interactive `&` shell has INT ignored at start, the trap cannot fire, and
the file stayed mutated until the next run); **`run` returning 142 is an instrument failure, never a
kill** — rerun on a quieter host. `mutate` refuses a file that already differs from `HEAD` (exit 4) and
restores its file on success, failure, timeout, INT and TERM (V29, V30). Note on the doc table's `\|`:
inside the table it stands for a bare `|` — typed into a shell the commands are `grep -E '^FAIL|^ok I
offers'` and `mine | wc -l` (7ak V17).

## Byte-for-byte rule (binding)

Never retype appendix text into the tree. Extract the fence, prove it, apply it:

```sh
D=design_docs/planned/r1/m4-7an-free-nav-stop-guard-edges.md
SC=$PWD/.godot/tmp/7an-plan; mkdir -p "$SC"      # scratch; .godot/ is .gitignore'd
awk '/^## Appendix A\./,0' $D | awk '/^```diff$/{f=1;next} /^```$/{if(f){exit}} f' > $SC/A.patch
wc -l < $SC/A.patch          # expect 81 (planner-measured)
shasum -a 256 $SC/A.patch    # expect 12880f78a2757838e4c3ac836bc7a40730c49ccb3a63e774d0dcb1fa3d6d5558
git apply --check $SC/A.patch && git apply --stat $SC/A.patch
# expect: tests/test_free_nav_stop.gd 37 ++--…, tests/test_ship_star_identification.gd 5 +++…,
#         "2 files changed, 40 insertions(+), 2 deletions(-)" — the doc's stat (V25)
git apply $SC/A.patch
git diff --stat              # must equal the doc's stat above; git status --porcelain = exactly the two test files
```

A mismatch means re-extract, never retype. The patch touches nothing but the two test files → no new
script, no `.uid`, no allowlist row.

## Test-first order (mandatory)

**MS1** opens RED on the pristine tree (the new checks are absent where the design says they are), then
applies Appendix A and runs the non-mutation ACs (AC1–AC5, AC11). **MS2** runs the mutation ACs
AC6–AC10, one at a time in the foreground, then AC12. **MS3** adds the changelog fragment and the sprint
JSON evidence. Never present a check as green that was never shown able to fail:

| New/changed check | RED evidence (where shown) | Exact red shape |
|---|---|---|
| `the fixed eye looks ahead …` through `eye_clear` (T2) | pristine AC5 greps `2/0/0` (planner-measured); mutation **AC7** (moved before `update_candidates()` + monitor on the eye's line); **AC10** (7ak R1's eye back at `(8, 82, -4.8)`) | AC7: `17 passed, 4 failures`, `FAIL the fixed eye …` ×2, `FAIL I offers … (41 candidates)`, `FAIL alpha Cen A is inspectable at its stop` (V11). AC10: `17 passed, 4 failures`, `grep -c '^FAIL the fixed eye'` → `2` (V15) |
| `the sky draws the destination/alpha Cen A …` (T1) | pristine AC3 greps `0` for `the sky draws` (planner-measured); mutation **AC6** (`planets/system_view.gd:793` → `pass`) | AC6: `17 passed, 4 failures`, the two sky FAILs + the two opaque I FAILs (`43 candidates`) (V10) |
| `its catalogue row is dark …` (T3) | pristine AC3 greps `0` (planner-measured); mutation **AC8** (`sky/starfield.gd:110` → `pass`) | AC8: `22 passed, 1 failures`, `ok I offers … (44 candidates)` (the I check survives — that is the point), `FAIL its catalogue row is dark, replaced by the body, not pinned (1 rows, lit ["4472832130942575872"], 0 pins)` (V12) |
| `a pinned destination is offered once, as its pin row` (T3) | pristine: the check is absent (`grep -c` → `0`, planner-measured); mutation **AC9** (`ui/ship_star_identification.gd:62` filter dropped) | AC9s: `59 passed, 1 failures`, `ERROR: a pinned destination is offered once, as its pin row (0 candidates)` (V14); AC9f (the same mutation against the free-nav flow): `23 passed, 0 failures` — unreachable there, now asserted by `0 pins` (V14) |

The pristine full-target RED baseline is already measured twice (V1: `54 passed, 0 failures`;
planner: same, 301 s of 1800 s) — the executor does NOT re-run the full target before patching; the
cheap greps below are its RED demonstration.

## Milestones

### MS1 — RED on the pristine tree, then Appendix A byte-exact; AC1, AC2, AC3, AC4, AC5, AC11

Files: `tests/test_free_nav_stop.gd`, `tests/test_ship_star_identification.gd` (Appendix A). **Nothing
else.** Estimate: ~20–30 min (10 min of steps + one full run ~5–11 min + one short run ~2–4 min + AC2
~15 s). Closes: **AC1, AC2, AC3, AC4, AC5, AC11.**

1. **Environment preamble + asserts (cheap; stop on any mismatch):** the Environment block;
   `ailang --version` = v0.56.1 (05c860a), `godot --version` = 4.7.2.stable. Assert `user://` writable
   (`FileAccess.open("user://probe.bin", FileAccess.WRITE)` non-null) and `ps -axo pid=,command= | head -1`
   works — both are planner-measured failure modes; without them stop and report before any run.
2. **Anchor asserts (planner-verified; any mismatch → stop, tree drift):**
   - `sed -n '62p;101p;130p' ui/ship_star_identification.gd` → `:62` `if i >= field.ids.size() or
     field.ids[i] in field.pinned_ids:continue` · `:101` the catalogue-star `occludes_direction` (`if
     sky.system_view!=null and sky.system_view.visible and …`) · `:130` `if sv.occludes_direction(dir,
     b.id, dist):continue`
   - `sed -n '793p' planets/system_view.gd` → `if b.id == skip_id: continue`
   - `sed -n '110p' sky/starfield.gd` → `if bare!=id and not bare in replacements:
     replacements.append(bare)`
   - `sed -n '60,61p;79,80p' tests/test_free_nav_stop.gd` → twice `ident.set_held(true);
     ident.update_candidates()` then `check(not ident.occlusion.blocked(…)` with no comment
   - `sed -n '201p' tests/test_ship_star_identification.gd` → `check(identify.candidates.size()==1 and
     identify.candidates[0].id=="Gaia DR3 123","a bare Gaia row is offered as its catalogue id")`
3. **RED on the pristine tree (seconds; record verbatim):**
   `grep -c 'ident.occlusion.blocked' tests/test_free_nav_stop.gd; grep -c 'check(eye_clear(demo, ident)'
   tests/test_free_nav_stop.gd; grep -c 'ident.occlusion.refresh(demo.camera)'
   tests/test_free_nav_stop.gd; grep -c 'a pinned destination is offered once'
   tests/test_ship_star_identification.gd` → **`2`, `0`, `0`, `0`** (the doc's base columns; the new
   checks are absent — this is the RED). The full-target pristine baseline is planner-measured in Plan
   verification (`54 passed, 0 failures`; AC3 labels `2/0/0/0`); do not spend a second full run on it.
4. **Extract + apply Appendix A** (Byte-for-byte rule): 81 lines, the sha256, `git apply --check`, the
   stat `2 files changed, 40 insertions(+), 2 deletions(-)`; then `git apply`; `git diff --stat` must
   equal it; `git status --porcelain` = exactly the two test files.
5. **Source the AC preamble** (the fence above; TMPDIR note if the sandbox refuses /tmp).
6. **AC1:** `make free-nav-stop-test; echo rc=$?` → `rc=0`;
   `script-gate: free-nav-stop-test ok: free-nav-stop: 57 passed, 0 failures (rc 0, no SCRIPT ERROR, … of
   1800 s)`. Foreground; ~5–11 min depending on load (planner-measured 301 s at load ~4; V8 433 s at
   load 17; the budget is 1800 s).
7. **AC2:** `make ship-star-identification-test; echo rc=$?` → `rc=0`;
   `ship-star-identification: 60 passed, 0 failures` (base 59 + the new pin check; V9). Needs writable
   `user://` (step 1).
8. **AC3:** `for p in 'the fixed eye looks ahead' 'the sky draws' 'its catalogue row is dark'; do grep -c
   "^ok $p" .godot/tmp/free-nav-stop.log; done; grep -c '^FAIL' .godot/tmp/free-nav-stop.log` →
   **`2`, `2`, `1`, `0`** (base was `2`, `0`, `0`, `0`).
9. **AC4:** `git diff --name-only origin/main...HEAD` → only the two test files plus docs/state (the
   design doc; this plan/JSON if the controller committed them here); **nothing under `ui/ demos/ sky/
   planets/ interior/ bridge/ sim/ audio/ data/ assets/`, no `Makefile`, `mk/` or `*.ail`** (the
   negative list is the assertion). Then `git status --porcelain` shows only the two test files.
10. **AC5:** `grep -c 'ident.occlusion.blocked' $T; grep -c 'check(eye_clear(demo, ident)' $T; grep -c
    'ident.occlusion.refresh(demo.camera)' $T` → **`1`, `2`, `1`** (base `2`, `0`, `0`).
11. **AC11:** `run ac11 900 0 '^free-nav-stop: 23 passed, 0 failures' $W/short.gd; echo rc=$?` →
    `script-gate: ac11 ok: free-nav-stop: 23 passed, 0 failures (rc 0, no SCRIPT ERROR, … of 900 s)`;
    `rc=0` (V7, V31: 155–246 s). This is the green reference for AC6–AC10.
12. **Commit** the two test files (e.g. `7an MS1: the guard's edges — sky/occlusion/catalogue-row/pin
    checks (AC1-AC5, AC11 green)`); `git status --porcelain` empty afterwards (scratch lives under
    `.godot/tmp`, ignored; no `.bak`, no `.uid`).

### MS2 — the mutation ACs AC6–AC10, one at a time in the foreground; AC12 last

Files: **none persistently** — `mutate` edits `planets/system_view.gd:793` (AC6), `sky/starfield.gd:110`
(AC8), `ui/ship_star_identification.gd:62` (AC9) for one bounded run each and restores them from its
EXIT trap; AC7/AC10 build scratch copies under `$W`. Depends on MS1 (the patch committed, the preamble
sourced; re-source it in a new shell). Estimate: 7 short runs + 1 identification run ≈ 20 min measured
at load 5–28 (V31: 10:57–11:17); allow 45 min under heavier load. Closes: **AC6, AC7, AC8, AC9, AC10,
AC12.**

Rules, repeated because they are the quorum's point: one AC at a time, in the foreground; no other Godot
run loads the tree meanwhile; no second acceptance session in this clone; **never a `&` job**; **a 142 is
an instrument failure, never a kill — rerun on a quieter host**; after every AC, `git status --porcelain`
must be empty (the trap restored the file) before starting the next.

1. **AC6 (the (a) killer):**
   `mutate planets/system_view.gd 's/^\t\tif b.id == skip_id: continue$/\t\tpass # 7an a/' ac6 900 1 '^free-nav-stop: 17 passed, 4 failures$' $W/short.gd; echo rc=$?; grep '^FAIL' $W/ac6.log; git status --porcelain`
   → `script-gate: ac6 ok: free-nav-stop: 17 passed, 4 failures (rc 1, …)`; `rc=0`;
   `FAIL the sky draws the destination with no nearer body over it`, `FAIL I offers … (43 candidates)`,
   `FAIL the sky draws alpha Cen A with no nearer body over it`,
   `FAIL alpha Cen A is inspectable at its stop`; no status output (V10, V31).
2. **AC7 (the (b) killer) — the design's fenced block, verbatim:**

   ```sh
   perl -0pe 's/(\tident\.set_held\(true\); ident\.update_candidates\(\)\n)(\tcheck\(eye_clear\(demo, ident\)[^\n]*\n)/$2$1/g; s/(\tdemo\.avatar_pos = Vector3\(11, 82, -4\.8\)[^\n]*\n)/$1\tdemo.monitor_frames.position.x += 2.418; demo.geometry.find_child("monitor_face_course", true, false).position.x += 2.418\n/' $W/short.gd > $W/b.gd
   perl -0pe 's/(\tident\.set_held\(true\); ident\.update_candidates\(\)\n)(\tcheck\(eye_clear\(demo, ident\)[^\n]*\n)/$2$1/g' $W/short.gd > $W/b0.gd
   run ac7 900 1 '^free-nav-stop: 17 passed, 4 failures$' $W/b.gd; echo rc=$?; grep '^FAIL' $W/ac7.log
   run ac7b 900 0 '^free-nav-stop: 23 passed, 0 failures$' $W/b0.gd; echo rc=$?
   ```

   → `script-gate: ac7 ok: free-nav-stop: 17 passed, 4 failures (rc 1, …)`, `rc=0`,
   `FAIL the fixed eye looks ahead …` twice, `FAIL I offers … (41 candidates)`,
   `FAIL alpha Cen A is inspectable at its stop`; then `script-gate: ac7b ok: free-nav-stop: 23 passed,
   0 failures (rc 0, …)`, `rc=0` (the move without the shift stays green — placement-independence) (V11,
   V31).
3. **AC8 (the (c) replacement killer):**
   `mutate sky/starfield.gd 's/^\t\tif bare!=id and not bare in replacements: replacements.append(bare)$/\t\tpass # 7an c1/' ac8 900 1 '^free-nav-stop: 22 passed, 1 failures$' $W/short.gd; echo rc=$?; grep -E '^FAIL|^ok I offers' $W/ac8.log; git status --porcelain`
   → `script-gate: ac8 ok: free-nav-stop: 22 passed, 1 failures (rc 1, …)`; `rc=0`;
   `ok I offers … (44 candidates)` (the I check survives — defence in depth is the design's finding);
   `FAIL its catalogue row is dark, replaced by the body, not pinned (1 rows, lit
   ["4472832130942575872"], 0 pins)`; no status output (V12, V31).
4. **AC9 (the (c) pin killer — two `mutate` runs in one criterion, in order):**
   `M='s/^\t\tif i >= field.ids.size() or field.ids\[i\] in field.pinned_ids:continue$/\t\tif i >= field.ids.size():continue # 7an c2/'; mutate ui/ship_star_identification.gd "$M" ac9s 300 1 '^ship-star-identification: 59 passed, 1 failures$' $W/ssi.gd; echo rc=$?; grep 'ERROR: a pinned' $W/ac9s.log; mutate ui/ship_star_identification.gd "$M" ac9f 900 0 '^free-nav-stop: 23 passed, 0 failures$' $W/short.gd; echo rc=$?; git status --porcelain`
   → `script-gate: ac9s ok: ship-star-identification: 59 passed, 1 failures (rc 1, …)`, `rc=0`,
   `ERROR: a pinned destination is offered once, as its pin row (0 candidates)`; then `script-gate: ac9f
   ok: free-nav-stop: 23 passed, 0 failures (rc 0, …)` (the flow never pins — the premise the new check
   asserts), `rc=0`; no status output (V14, V31). `ac9s` needs writable `user://`.
5. **AC10 (7ak's R1 still kills `eye_clear`):**
   `sed 's/Vector3(11, 82, -4.8)/Vector3(8, 82, -4.8)/' $W/short.gd > $W/r1.gd; run ac10 900 1 '^free-nav-stop: 17 passed, 4 failures$' $W/r1.gd; echo rc=$?; grep -c '^FAIL the fixed eye' $W/ac10.log`
   → `script-gate: ac10 ok: free-nav-stop: 17 passed, 4 failures (rc 1, …)`; `rc=0`; `2` (V15, V31).
6. **AC12 (last):** `git status --porcelain; mine | wc -l; make uid-guard` → no status output; `0`;
   `uid-guard: ok (422 .uid files)` (no new script, so no new `.uid`; V23, planner-replicated).
   Record each run's gate line and wall seconds into the sprint JSON `measured` field as you go.

### MS3 — the changelog fragment; re-assert; the sprint JSON evidence

Files: `changelogs/unreleased/2026-11-12-free-nav-stop-guard-edges.md` (new),
`.ailang/state/sprints/sprint_R1-7AN-FREE-NAV-GUARD-EDGES.json` (evidence). Depends on MS2. Estimate:
5–10 min.

1. **Fragment** (per `changelogs/unreleased/README.md`; one `YYYY-MM-DD-<slug>.md` file opening with
   `### `; the 7am shape — see commit `77c5b7b5`). Content: row **7an**, sprint
   **R1-7AN-FREE-NAV-GUARD-EDGES**. `### Added`: the I-key guard's edges in `make free-nav-stop-test`
   now fail for the right reason — a sky-renderer occlusion of the destination fails with its own
   message at both stops (`sky_hides` asks `occludes_direction` as `_add_body_candidates` does); the
   clear-eye check refreshes the ship BVH itself (`eye_clear`), so it means the same wherever it stands
   in the test; the stop's catalogue point is checked layer by layer (the row is dark under the body's
   replacement, `0 pins` asserted) and the `pinned_ids` filter is checked in a fixture where a pin really
   happens (`test_ship_star_identification.gd`). Each new check has a measured killing mutation
   (AC6–AC10). Test-only: two files, +40/−2; nothing a player sees or hears changes.
2. **Re-assert:** AC12's line again (`git status --porcelain`; `mine | wc -l` → `0`;
   `make uid-guard` → `uid-guard: ok (422 .uid files)`); `make python-guard` → ok (no `*.py` touched);
   `git status --porcelain` shows only the fragment and the JSON on top of MS1's commit.
3. **Sprint JSON evidence:** fill each milestone's `measured` (MS1: the RED greps `2/0/0/0`, the fence
   sha256/stat, AC1's gate line + wall time, AC2's summary, AC3's `2/2/1/0`, AC4's file list, AC5's
   `1/2/1`, AC11's gate line; MS2: each AC's `script-gate: … ok:` line with rc and wall seconds, the
   FAIL/`ok I offers`/`ERROR` lines, the empty porcelains, AC12's three results; MS3: the fragment
   path), set `passes: true` per milestone, and wall-clock totals under `velocity`.
4. **Commit** the fragment + JSON (e.g. `7an MS3: changelog fragment and sprint evidence`).

## Pause points (stop and report; do not improvise)

- Environment: `ailang --version` ≠ v0.56.1 or `godot --version` ≠ 4.7.2 → stop. `user://` not writable
  or `ps` denied → stop (planner-measured sandbox failure modes); never patch the test around them.
- MS1: a fence extraction ≠ 81 lines, the sha256 ≠ `12880f78a2757838…`, or `git apply --check` fails →
  re-extract, never retype; an anchor assert mismatches → tree drift, stop (if attended PR #412 landed
  first, its `ui/ship_star_identification.gd` hunk at `:237` moves no line the anchors or mutations use —
  re-run AC1 and AC2 after the rebase, per the design's Conflict surface). The applied `git diff --stat`
  ≠ `2 files changed, 40 insertions(+), 2 deletions(-)` → stop. AC1 not `57 passed, 0 failures`/rc 0, AC2
  not `60 passed, 0 failures`/rc 0, AC3 not `2/2/1/0`, AC5 not `1/2/1`, AC11 not `23 passed, 0
  failures`/rc 0 → stop.
- MS2: any `run` returning **142 → instrument failure: rerun on a quieter host; it is never read as a
  kill** (design, normative). A gate line or `rc=` differing from the doc's expected → stop. `mutate`
  refusing a dirty file (exit 4, `already differs from HEAD`) → a previous run left the tree mutated:
  stop, `git checkout -- <file>`, report (never force past it). `git status --porcelain` non-empty after
  any mutation AC → the trap failed: stop and report; do not start the next AC. Any urge to run a
  mutation AC as a `&` job or alongside another Godot run → that's the prohibited shape (V30); run it in
  the foreground.
- AC12: `mine | wc -l` ≠ 0 → leftover processes: stop and name them (reap's TERM/KILL already ran; report
  what survived). `uid-guard` ≠ `ok (422 .uid files)` → stop.
- Any temptation to touch the do-not-touch list → stop; the fix needs none of it. In particular
  `ui/ship_star_identification.gd`, `sky/starfield.gd`, `planets/system_view.gd` are edited only by
  `mutate` for one bounded run each and restored; #412 (attended) also holds `ui/ship_star_identification.gd`.
- No merge before the cross-family evaluation (generator ≠ judge); landing files wait on it.

## Risks (from the design; planner additions marked)

- **Host load vs budgets** (design F2, V31): short copies 900 s (measured 104–246 s at load 6–34), the
  identification test 300 s (7–17 s), the full targets through `make` (1800 s and 600 s `SCRIPT_GATE`;
  planner-measured 301 s at load ~4). Under heavy load any run can 142 — that is an instrument failure:
  rerun on a quieter host, never bump a budget silently, never read it as a kill.
- **Two sessions, one clone** (quorum r2, sol): the preamble's `mine` matches only this session's unique
  `$W` prefix and this clone's `sim/` path (V33 two-clone drill), but simultaneous acceptance sessions
  within the same clone are prohibited outright — and a mutation AC as a `&` job cannot trap INT (V30
  negative control: the file stayed mutated). Foreground, one at a time.
- **The eye's margin is 0.55 m** (V16): if a monitor frame grows by that much the eye is blocked again;
  the clear-eye check fails first and names the eye. Moving the eye or the furniture is the deck-layout
  row's call, not this row's.
- **`sky_hides` mirrors `_add_body_candidates`** (direction, skip id, distance; quorum r1 gemini,
  non-blocking): if the product helper changes how it asks, the two drift. AC6 fails both together, so a
  drift shows up as one failing without the other; the helper's comment names what it mirrors.
- **The pin fixture's state** (quorum r1 gemini; V32 measured): `pin_destination` leaves
  `pinned_ids=["b"]`, `pin_fallbacks=1`; the next fixture line's `set_custom_stars` → `clear()` resets
  both before "absent metadata fails closed" runs. Coupling, not a defect.
- **The bounded runner's limits** (V27–V30): a Godot child that leaves its process group escapes the
  supervisor (the sim does; `reap` catches it by its `--package-dir <clone>/sim` argv); a shell with INT
  ignored at start cannot trap INT (foreground only); a lone TERM to the AC shell runs the trap when the
  current bounded gate returns.
- **The fixture's `vmag -14`** has no physical meaning beyond brightness (~1 lux, as bright as the
  fixture rows' `flux=1`; vmag 0 is invisible at the fixture's exposure, V9); the comment says why.
- **#412 lands first:** no textual conflict (its hunk is at `:237`; the mutations edit `:62`);
  whichever lands second reruns AC1 and AC2.
- **(Planner-added) Sandbox environment:** the planner's sandbox refused `/tmp` writes, `~/Library`
  writes (→ `user://` unwritable → AC2/ac9s SCRIPT ERROR at
  `tests/test_ship_star_identification.gd:45`) and `ps` (→ `mine`/`reap` blind). All three are hard
  prerequisites asserted in MS1 step 1; a sandbox that fails them reports and stops, it does not adapt
  the tests.
- **(Planner-added) `runtime/` is untracked:** a fresh executor clone may lack `runtime/bin`; point PATH
  at the main checkout's runtime and assert v0.56.1 (Environment).

## Files allowed and do-not-touch

- **Allowed:** `tests/test_free_nav_stop.gd`, `tests/test_ship_star_identification.gd` (Appendix A only);
  `changelogs/unreleased/2026-11-12-free-nav-stop-guard-edges.md`; this sprint's plan/JSON; scratch under
  `.godot/tmp` and `$W`. Landing edits at the end (charter row, README index, the doc/plan move to
  `implemented/`) are routine.
- **Do not touch** (design Non-goals): everything under `ui/`, `demos/`, `sky/`, `planets/`, `interior/`,
  `bridge/`, `sim/`, `audio/`, `data/`, `assets/`, shaders, captures, goldens, any `*.ail`, `Makefile`,
  `mk/`. The mutation ACs edit `planets/system_view.gd:793`, `sky/starfield.gd:110`,
  `ui/ship_star_identification.gd:62` only through `mutate` (one bounded run each, trap-restored).
  `ui/ship_star_identification.gd` and `demos/ship_geometry_demo.gd` are also in attended PR #412. No new
  file but the fragment → no `.uid`, no python-allowlist row. Never move the course monitor, the landing
  or the eye.

## Local PR gates (targeted, headless, bounded)

1. MS1 on record: the anchor asserts; the RED greps `2/0/0/0`; the 81-line fence with sha256
   `12880f78a2757838…`; `git apply --check` + the `40 insertions(+), 2 deletions(-)` stat; AC1's gate
   line (`57 passed, 0 failures`); AC2 (`60 passed, 0 failures`); AC3 `2/2/1/0`; AC4's file list; AC5
   `1/2/1`; AC11's gate line.
2. MS2 on record: AC6–AC10 each with its `script-gate: … ok:` line, rc 0, the doc's exact FAIL/`ok`/`ERROR`
   lines, and an empty `git status --porcelain` after each; AC12's empty status, `mine | wc -l` → 0,
   `uid-guard: ok (422 .uid files)`.
3. MS3 evidence: the fragment in place; AC12 re-asserted; `make python-guard` ok; the JSON's `measured`
   fields filled, `passes: true`.
4. The GitHub gate: `make ci-fast` green on the PR. **No GPU gate, no `make golden`, no capture, no full
   local `make test`** (merge rule); the nightly `rig/full` runs the suite on main post-merge.

## Plan verification (planner, 2026-11-12, HEAD `0ac39ca4`; baselines measured, not copied)

Cheap re-verification of the doc's claims against the pristine tree (the tree is at the r2 design commit;
the test files are unpatched). One full target run, foreground, as the mission allows:

- **Base/HEAD.** HEAD = r2 design commit `0ac39ca4`; merge-base with `origin/main` = `b96b2d60` =
  `origin/main` = the design's measured base; `git diff --name-only origin/main...HEAD` = the design doc
  alone (AC4's pristine expectation); `git status --porcelain` empty before and after every planner run.
- **Toolchain.** `runtime/bin/ailang --version` → `AILANG v0.56.1`, commit `05c860a`; `godot --version`
  → `4.7.2.stable.official.ed1daf0bf`. `runtime/` is untracked (present in this clone).
- **AC1 pristine (planner-run, once, foreground):** `make free-nav-stop-test` → `rc=0`, wall 304 s;
  `script-gate: free-nav-stop-test ok: free-nav-stop: 54 passed, 0 failures (rc 0, no SCRIPT ERROR, 301 s
  of 1800 s)`. Matches V1's `54 passed, 0 failures` (V1 measured 634 s at load 9–21; the planner's host
  was quieter: load 3.7–5.1). The log holds `ok I offers the destination as its finite body, not the
  hidden catalogue point (44 candidates)` and `ok alpha Cen A is inspectable at its stop` (V1's opaque
  pair).
- **AC3 pristine (measured):** the label greps on `.godot/tmp/free-nav-stop.log` → **`2`, `0`, `0`, `0`**
  (the doc's base column): two `ok the fixed eye looks ahead`, zero `ok the sky draws`, zero `ok its
  catalogue row is dark`, zero `FAIL`.
- **AC5 pristine (measured):** `ident.occlusion.blocked` ×**2**, `check(eye_clear(demo, ident)` ×**0**,
  `ident.occlusion.refresh(demo.camera)` ×**0** (the doc's base column).
- **The identification fixture check is absent (measured):** `grep -c 'a pinned destination is offered
  once' tests/test_ship_star_identification.gd` → `0`.
- **Fence extraction (measured; V25 replicated):** the Appendix-A `diff` fence = **81 lines**, sha256
  **`12880f78a2757838e4c3ac836bc7a40730c49ccb3a63e774d0dcb1fa3d6d5558`** (the doc's
  `12880f78a2757838…` prefix matches); `git apply --check` clean; `git apply --stat` = `2 files changed,
  40 insertions(+), 2 deletions(-)` (`test_free_nav_stop.gd` 37, `test_ship_star_identification.gd` 5).
  The patch was NOT applied (check/stat only); porcelain stayed empty.
- **Anchors (measured; V2/V3 replicated):** `ui/ship_star_identification.gd:62` = the `pinned_ids`
  filter, `:101` the catalogue-star `occludes_direction`, `:130` the body `occludes_direction` (so the
  row's `:96/:127` premise correction holds; `:96` is `if not sample.visible:continue`, `:127` a comment);
  `planets/system_view.gd:793` = `if b.id == skip_id: continue`; `sky/starfield.gd:110` = the bare-alias
  replacement line; `tests/test_free_nav_stop.gd:60-61` and `:79-80` = `set_held(true);
  update_candidates()` then the clear-eye `check(not ident.occlusion.blocked(…))` with no comment;
  `tests/test_ship_star_identification.gd:201` = the bare-Gaia check the pin fixture lands after. The
  AC9 sed pattern matches `:62` verbatim.
- **AC12 pieces pristine (measured; V23 replicated):** `make uid-guard` → `uid-guard: ok (422 .uid
  files)`; `git status --porcelain` empty.
- **AC2 baseline NOT planner-measured — environment, recorded:** this sandbox refuses `~/Library` writes
  (`touch …/Godot/app_userdata/probe` → `Operation not permitted`), so `user://` is unwritable (probe:
  `FileAccess.open("user://probe.bin", WRITE)` → null, err 12). `make ship-star-identification-test`
  here SCRIPT ERRORs at `tests/test_ship_star_identification.gd:45` (`Cannot call method 'store_buffer'
  on a null value`) and Godot then never reaches `quit()`, bounded by the gate's 600 s. The doc's V9
  base (`script-gate: ship-star-identification-test ok: 59 passed, 0 failures (rc 0, no SCRIPT ERROR, 12
  s of 600 s)`) stands as the baseline; the executor asserts a writable `user://` in MS1 step 1. This
  sandbox also refuses `/tmp` writes (`Operation not permitted`; reroot via `TMPDIR`, Environment note 3)
  and process listing (`ps`/`pgrep` denied), so the planner ran no `run`/`mutate` AC — those are all
  designer-measured (V27–V33) in an environment with working `ps` and `user://`.

## Velocity / estimate

42 LOC in two test files (Appendix A, byte-exact) + the fragment. MS1 ≈ 20–30 min (one full run 5–11 min
+ one short run 2–4 min; the rest is seconds). MS2 ≈ 20 min measured at load 5–28 (V31), allow 45 under
load — 7 short runs + 1 identification run, foreground, serial. MS3 ≈ 5–10 min. Recent rows of this size
each took one iteration (7ak ~4 LOC; 7ai ~16; 7aj ~55; 7am ~135): the same is planned here — one
iteration, no day-count estimated.
