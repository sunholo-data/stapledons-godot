# Sprint plan: R1-7AK-FREE-NAV-STOP-EYE — free-nav-stop's I checks look from the clear captain eye (row 7ak)

**Design doc:** [m4-7ak-free-nav-stop-eye.md](m4-7ak-free-nav-stop-eye.md) (revision 2; quorum round 1 BLOCKED
1/3 → r1's V13 and shared-eye softening; round 2 BLOCKED 2/3 → r2 by the controller under the narrow-refinement
carve-out: glm's "Overlap with open PRs #380 and #373" sentence + V15, kimi's AC2/AC5 fenced commands verbatim —
plain `|` under `grep -E`; no round 3, straight to planning). **Sprint JSON:**
`.ailang/state/sprints/sprint_R1-7AK-FREE-NAV-STOP-EYE.json`.
**Approval basis:** pillar table net 0, none below 0 (neutral suite hygiene; unattended loop proceeds).
**Branch:** `mission/stapledon-iter86-7ak` (planner clone at detached HEAD `aef5057e`, the r2 design commit;
merge-base with `origin/main` is `312b1772` = `origin/main` = the design's `B`; `git diff --name-only
312b1772..HEAD` = the design doc alone, so every V-number applies verbatim). **Scope:** 4 lines in one test
file, `tests/test_free_nav_stop.gd` (2 changed, 2 added), plus the changelog fragment. No product, asset or
Makefile change. **No GPU, no `make golden`, no capture, no full local `make test`** (merge rule, CLAUDE.md);
the targeted gate is `make free-nav-stop-test` (AC1) plus `make uid-guard` (AC8), and the nightly `rig/full`
keeps running the suite on main post-merge — that nightly has been red on exactly this row since PR #379
(R3-COMMS-V2, merged as `8ba1e3c8`), which is the row's reason to exist.

**Role split:** the planner runs no Godot and no make (this file was planned read-only); the controller and the
executor run everything below. No git write operations by the planner; the controller commits. The executor's
only git write is the AC7-mandated restore `git checkout -- ui/ship_star_identification.gd`.

## Environment (executor)

```sh
cd <executor clone> && export PATH=$PWD/runtime/bin:$PATH   # AILANG v0.56.1, Godot 4.7.2
```

Preamble once per session (every command headless from the clone root; `perl -e 'alarm N; exec @ARGV'` bounds
every long run):

```sh
runtime/bin/ailang --version    # expect "AILANG v0.56.1"; anything else → stop
godot --version                 # expect 4.7.2.stable…
B=312b1772                      # design base = origin/main at planning
T=tests/test_free_nav_stop.gd
G='AILANG_BIN=$(command -v ailang) godot --headless --path .'
S=$PWD/.godot/tmp/7ak; mkdir -p "$S"   # scratch; .godot/ is .gitignore:1; D1: this sandbox blocks /tmp writes
```

**AILANG discipline (planner-measured):** this planner clone has **no `runtime/`**; `Makefile:2` is
`AILANG ?= ailang`, `Makefile:6` is `GODOT_SIM = AILANG_BIN="$$(command -v $(AILANG))" $(GODOT)`, and the
`ailang` on PATH is **v0.59.0-92-g24802d854-dirty** — wrong for this repo (pinned v0.56.1). If the executor
clone lacks `runtime/bin/ailang`, stage it first with `make runtime` (Makefile:725) before anything else; the
preamble's version check enforces it. The main checkout's pinned binary
(`/Users/voightkampff/dev/sunholo-data/stapledons-godot/runtime/bin/ailang`) reports `AILANG v0.56.1` for
read-only cross-checks. Godot 4.7.2.stable is on PATH here (`/opt/homebrew/bin/godot`).

**Asset prerequisite:** this planner clone has no sky textures (`data/sky/` holds only SHA256SUMS and reports;
the ~164 MB set is not in git, D-18). The target boots the ship demo with the starmap and sky assets (design
F1); the designer's `stapledons-godot-iter86-7ak` clone had them (V1–V17 ran there). If the executor clone
lacks them, run `make sky-assets` first (seconds from the public bucket). The primary catalogue
`data/starmap/stars.json` is tracked (931975 bytes) and present.

## Plan-time checks (planner, 2026-11-11, HEAD `aef5057e`)

Cheap re-verification of the doc's claims against the tree (all read-only, bounded):

- **Base/HEAD.** HEAD = r2 design commit `aef5057e`; merge-base = `origin/main` = `312b1772` = the design's
  `B`; only the design doc differs. Every V-number applies at HEAD without checkout. `git status --porcelain`
  empty.
- **Cited test lines — all match the file (planner-verified at HEAD; the file is identical to `$B`).**
  `:57` and `:76` are exactly `demo.avatar_pos = Vector3(8, 82, -4.8) # a fixed eye: …` (the M1 sites);
  `:60` and `:78` are exactly `ident.set_held(true); ident.update_candidates()` (the refresh lines; V8 says the
  M2 check must *follow* the refresh); `:62` is the `I offers the destination as its finite body, not the
  hidden catalogue point (%d candidates)` check; `:80` is the `alpha Cen A is inspectable at its stop` check.
  `Vector3(8, 82, -4.8)` occurs exactly twice in the test (`:57`, `:76`) and `Vector3(11, 82, -4.8)` zero
  times, so M1's substitution and AC3's `2, 0` counts are well-formed.
- **M2 insertion points.** The check lands between `:60` and `:61` (`var hit …`) and between `:78` and `:79`
  (`var a_c …`); in the final diff the two added lines sit at new-file `:61` and `:80`, matching V7b's measured
  shape ("lines 57, 76 changed, 61, 80 added").
- **The golden's eye.** `tools/m4_ship_golden.gd:241` carries exactly one `Vector3(11, 82, -4.8)` with
  `_pose(-0.01, -PI * 0.5)` (G-M4-S3) → AC3's third grep = `1`.
- **R3 sed target.** `ui/ship_star_identification.gd:105` is exactly the line
  `\t_add_body_candidates(sky,view,focal,px,canvas_to_pixel)`; grep shows the call only at `:105` (`:111` is the
  func definition and does not match AC7's anchored pattern). The `sed -i.bak -e … && rm .bak` form is the one
  V14 measured and kimi vetted as portable.
- **R2 anchors.** `var monitor_frames: Node3D` at `demos/ship_geometry_demo.gd:811` and
  `var geometry := Node3D.new()` at `:48` (`find_child` is a Node method) → R2's awk one-shot edit
  (`demo.monitor_frames.position.x += 2.418; demo.geometry.find_child("monitor_face_course", true,
  false).position.x += 2.418`) is well-formed; its `!d` guard fires only on the first `Vector3(11, 82, -4.8)`
  line (post-M1 `:57`).
- **Makefile anchors.** `SCRATCH := .godot/tmp` (`:13`); `free-nav-stop-test:` at `:1210`, recipe `:1211` with
  `$(SCRIPT_GATE) free-nav-stop-test $(SCRATCH)/free-nav-stop.log 1800 '^free-nav-stop: [1-9][0-9]* passed, 0
  failures$$'` — the 1800 s budget the design cites, and AC1/AC2's log path. `uid-guard:` at `:1100`; `runtime:`
  at `:725`. The target is never edited by this row.
- **Red premise stands.** V1 (controller, at `312b1772` = `B`): `free-nav-stop: 48 passed, 2 failures`, make rc
  2, FAILs at `:62` and `:80`; tonight's nightly names the same two checks (design Priority). No re-run needed
  before the edits.
- **Environment.** `.godot/` is `.gitignore:1` and `$S` is writable; `perl -e 'alarm N; exec @ARGV'` works
  (7ai-verified pattern); `/tmp` writes are **refused here** (`touch /tmp/…` → `Operation not permitted`) — see
  D1.

**Discrepancies (record, don't fix mid-sprint):**

- **D1.** The design's AC5/AC6/AC7 commands write scratch under `/tmp` (`/tmp/7ak_r1.gd`, …). This sandbox
  blocks `/tmp` writes (planner-measured), as in 7ai's D3. The executor reroots 1:1 to `$S` (`.godot/tmp/7ak`,
  gitignored): every `/tmp/7ak_…` path in the design's commands becomes `$S/7ak_…`, the grep patterns and
  expected lines unchanged. If the executor's sandbox allows `/tmp`, either root is fine — assert the same
  outputs. The scratch copies never edit the tree regardless of root (design AC preamble).
- **D2.** AC7's Expected ends "no `git status` output (V14)", but the sprint's own MS1 edit
  (`tests/test_free_nav_stop.gd`) is still uncommitted at that point, so porcelain lists it. Read it as "no
  porcelain lines beyond the sprint's own files" (7ah AC7 / 7ai D4 precedent) — the check that matters is that
  `ui/ship_star_identification.gd` is restored to its tracked bytes.

## Byte-for-byte rule (binding)

Never retype design-doc text into the tree. Extract the two fences, apply from the extractions, prove with
`cmp`:

```sh
D=design_docs/planned/r1/m4-7ak-free-nav-stop-eye.md
awk '/^### M1\./,/^### M2\./' $D | awk '/^```gdscript$/{f=1;next} /^```$/{if(f){exit}} f' > $S/m1.gd
awk '/^### M2\./,/^## Files touched/' $D | awk '/^```gdscript$/{f=1;next} /^```$/{if(f){exit}} f' > $S/m2.gd
wc -l $S/m1.gd $S/m2.gd   # expect 1 and 1; each begins with a literal tab
```

m1.gd = the 1-line `demo.avatar_pos = Vector3(11, 82, -4.8) # the captain eye of G-M4-S3 …` replacement (M1).
m2.gd = the 1-line clear-eye `check(not ident.occlusion.blocked(…), "the fixed eye looks ahead past the ship
…")` (M2). Neither contains a backslash, so `awk -v` passes them unmangled. The cmp proofs close at MS1.

## Test-first order (mandatory)

The design's sub-milestones in their fixed order: **S1 → S2 → S3** = MS1 (M1+M2, green, AC1–AC4) → MS2 (red
controls AC5–AC7) → MS3 (fragment + AC8). The red baseline is already on record (V1: `free-nav-stop: 48
passed, 2 failures`, make rc 2, at `312b1772` with HEAD's test file byte-identical; the nightly repeats it), so
no 7.5-minute re-run precedes the edits. Test-first for the **new** checks is discharged by MS2's red controls,
and no control may be presented as green that never went red:

| New/changed line | Killing control (proves it can fail) | Exact red evidence |
|---|---|---|
| M1, eye `(8, 82, -4.8)` → `(11, 82, -4.8)` at `:57` | **R1 (AC5)**: sed the fixed test back to the old eye in a scratch copy | rc=1; `FAIL the fixed eye looks ahead past the ship (no surface on its centre ray)` (1st leg); `FAIL I offers the destination as its finite body, not the hidden catalogue point (40 candidates)`; tail `free-nav-stop: 48 passed, 4 failures` |
| M1 at `:76` + M2 after `:78` | **R1 (AC5)**, same run | the 2nd `FAIL the fixed eye looks ahead …` and `FAIL alpha Cen A is inspectable at its stop` (grep -c = `2`, the AC5 fenced grep shows exactly the two original FAIL lines, count test rc 0) |
| M2 after `:60` (clear-eye guard, 1st leg) | **R2 (AC6)**: the course monitor + face shifted +2.418 m in x onto the new eye's line (scratch copy) | rc=1; `FAIL the fixed eye looks ahead …` ×2 and `FAIL I offers the destination … (41 candidates)` (grep -c = `1`); tail `free-nav-stop: 48 passed, 4 failures` |
| M2 after `:78` (clear-eye guard, 2nd leg) | **R2 (AC6)**, same run | the fourth FAIL is exactly `FAIL alpha Cen A is inspectable at its stop` (V10: same four-line shape as R1 with `(41 candidates)`) |
| Both I checks keep their teeth with the new eye | **R3 (AC7)**: `_add_body_candidates(sky,view,focal,px,canvas_to_pixel)` → `pass # R3` at `ui/ship_star_identification.gd:105` (the only tree edit; runs alone; restored) | rc=1; exactly `FAIL I offers the destination as its finite body, not the hidden catalogue point (43 candidates)` and `FAIL alpha Cen A is inspectable at its stop`; tail `free-nav-stop: 50 passed, 2 failures`; both clear-eye checks stay `ok` (V14 — M2 does not false-positive on a product regression) |

Green expectation after MS1 (V7b measured): `free-nav-stop: 54 passed, 0 failures`, rc 0.

## Milestones

### MS1 — S1: M1 + M2 in `tests/test_free_nav_stop.gd` (2 changed, 2 added), then AC1–AC4

Files: `tests/test_free_nav_stop.gd`. Closes: AC1, AC2, AC3, AC4, the byte-for-byte cmp proofs.

1. **Pre-edit anchor assert (cheap):** `sed -n '57p;60p;62p;76p;78p;80p' $T` → the six lines planner-verified
   above (`Vector3(8, 82, -4.8)` at `:57`/`:76`, the refresh at `:60`/`:78`, the two I checks at `:62`/`:80`).
   Any mismatch → tree drift; stop.
2. **Fence extraction** (Byte-for-byte rule) → `1` and `1`, both tab-led.
3. **Apply from the extractions; cmp proofs:**
   ```sh
   awk -v repl="$(cat $S/m1.gd)" '/^\tdemo\.avatar_pos = Vector3\(8, 82, -4\.8\)/{print repl; next} {print}' $T > $S/t.m1 && cp $S/t.m1 $T
   awk -v ins="$(cat $S/m2.gd)" '{print} /ident\.set_held\(true\); ident\.update_candidates\(\)$/{print ins}' $T > $S/t.m2 && cp $S/t.m2 $T
   awk 'NR==57||NR==76' $T | sort -u | cmp - $S/m1.gd && echo m1-ok
   awk 'NR==61||NR==80' $T | sort -u | cmp - $S/m2.gd && echo m2-ok
   grep -n -B1 'the fixed eye looks ahead' $T    # each check's previous line is the refresh line (V8: must follow the refresh)
   ```
   Both patterns hit exactly twice (planner-measured), so the file grows by exactly 2 lines and the M2 checks
   land at new `:61` and `:80` (V7b's measured diff shape). Expected: `m1-ok`, `m2-ok`, the two `-B1` pairs
   each headed by `ident.set_held(true); ident.update_candidates()`.
4. **AC1 (the green run; ~7.5 min under load 12–25, SCRIPT_GATE budget 1800 s at Makefile:1211):**
   `make free-nav-stop-test; echo rc=$?; tail -1 .godot/tmp/free-nav-stop.log` → `rc=0`;
   `free-nav-stop: 54 passed, 0 failures`. (A fresh clone may need `make runtime` + `make sky-assets` first —
   Environment.)
5. **AC2 — fenced command, verbatim from the design's "AC command blocks" (plain `|` under `grep -E`; do not
   re-escape; the fence is flush-left so the command line is byte-identical to the design's). First run by the
   executor on this green log; the controller re-runs it:**

```sh
grep -E '^(ok|FAIL) (I offers|alpha Cen A is inspectable|a click on A.s centre|its card says|the fixed eye looks ahead)' .godot/tmp/free-nav-stop.log; test $(grep -Ec '^(ok|FAIL) (I offers|alpha Cen A is inspectable|a click on A.s centre|its card says|the fixed eye looks ahead)' .godot/tmp/free-nav-stop.log) -eq 6 && ! grep -q '^FAIL' <(grep -E '^(ok|FAIL) (I offers|alpha Cen A is inspectable|a click on A.s centre|its card says|the fixed eye looks ahead)' .godot/tmp/free-nav-stop.log)
```

   Expected: rc 0, exactly the 6 listed `ok` lines, in check order: `ok the fixed eye looks ahead past the ship
   (no surface on its centre ray)`; `ok I offers the destination as its finite body, not the hidden catalogue
   point (44 candidates)`; `ok its card says the radius is inferred: …`; `ok the fixed eye looks ahead past the
   ship (no surface on its centre ray)`; `ok alpha Cen A is inspectable at its stop`; `ok a click on A's centre
   picks A, not B (["body:acen-a"])`.
6. **AC3:** `grep -c 'Vector3(11, 82, -4.8)' $T; grep -c 'Vector3(8, 82, -4.8)' $T; grep -c 'Vector3(11, 82,
   -4.8)' tools/m4_ship_golden.gd` → `2`, `0`, `1`.
7. **AC4:** `git diff --name-only origin/main...HEAD` → only `tests/test_free_nav_stop.gd`, a
   `changelogs/unreleased/*` fragment and landing docs/state (design doc, this plan, the sprint JSON); nothing
   under `demos/`, `ui/`, `interior/`, `assets/`, `art/`, `Makefile`, `mk/`.
8. **Cleanliness:** `git status --porcelain` shows only `tests/test_free_nav_stop.gd` modified (plus the
   controller's plan/JSON files).

### MS2 — S2: red controls AC5 (R1), AC6 (R2), AC7 (R3)

Files: none in the tree persisted (R1, R2 are scratch copies under `$S` per D1 — the design's `/tmp` paths
reroot 1:1; R3's tree edit is temporary and restored). Depends on MS1. **R1 and R2 may run in parallel**
(independent scratch copies, both read-only on the tree); **R3 runs alone** — it seds
`ui/ship_star_identification.gd` in the tree, and no other run may load the tree meanwhile. Bound each Godot
run at 1500 s (`perl -e 'alarm 1500; exec @ARGV' …`; measured 435–466 s at load 12–25, V7b/V10/V14).

1. **AC5 — red control R1 (the old eye; occlusion still counts, and the new check names the cause):**
   ```sh
   sed 's/Vector3(11, 82, -4.8)/Vector3(8, 82, -4.8)/' $T > $S/7ak_r1.gd
   perl -e 'alarm 1500; exec @ARGV' bash -c "$G --script $S/7ak_r1.gd > $S/7ak_r1.log 2>&1"; echo rc=$?
   grep -c '^FAIL the fixed eye looks ahead' $S/7ak_r1.log
   ```
   then the fenced **AC5** second grep, verbatim from the design (plain `|` under `grep -E`; flush-left fence so
   the line is byte-identical; `/tmp` → `$S` per D1):

```sh
grep -E '^FAIL (I offers|alpha Cen A is inspectable)' /tmp/7ak_r1.log; test $(grep -Ec '^FAIL (I offers|alpha Cen A is inspectable)' /tmp/7ak_r1.log) -eq 2
```

   then `tail -1 $S/7ak_r1.log`. Expected (V10 measured): `rc=1`; grep -c = `2`; the fenced grep prints exactly
   `FAIL I offers the destination as its finite body, not the hidden catalogue point (40 candidates)` and
   `FAIL alpha Cen A is inspectable at its stop` with the count test rc 0; tail
   `free-nav-stop: 48 passed, 4 failures`.
2. **AC6 — red control R2 (the furniture moves onto the new eye's line; may run in parallel with R1):**
   ```sh
   awk '{print} /Vector3\(11, 82, -4.8\)/ && !d {print "\tdemo.monitor_frames.position.x += 2.418; demo.geometry.find_child(\"monitor_face_course\", true, false).position.x += 2.418"; d=1}' $T > $S/7ak_r2.gd
   perl -e 'alarm 1500; exec @ARGV' bash -c "$G --script $S/7ak_r2.gd > $S/7ak_r2.log 2>&1"; echo rc=$?
   grep -c '^FAIL the fixed eye looks ahead' $S/7ak_r2.log; grep -c '^FAIL I offers the destination' $S/7ak_r2.log; tail -1 $S/7ak_r2.log
   ```
   Expected (V10 measured): `rc=1`; `2`; `1` (that FAIL ends `(41 candidates)`);
   `free-nav-stop: 48 passed, 4 failures` — the fourth FAIL is exactly
   `FAIL alpha Cen A is inspectable at its stop`.
3. **AC7 — red control R3 (a product regression in body gathering; the only tree edit; runs alone):**
   ```sh
   sed -i.bak -e 's/^\t_add_body_candidates(sky,view,focal,px,canvas_to_pixel)$/\tpass # R3/' ui/ship_star_identification.gd && rm ui/ship_star_identification.gd.bak && perl -e 'alarm 1500; exec @ARGV' bash -c "$G --script $T > $S/7ak_r3.log 2>&1"; echo rc=$?
   git checkout -- ui/ship_star_identification.gd
   grep -E '^FAIL' $S/7ak_r3.log; tail -1 $S/7ak_r3.log; git status --porcelain
   ```
   Expected (V14 measured): `rc=1`; `grep -E '^FAIL'` prints exactly
   `FAIL I offers the destination as its finite body, not the hidden catalogue point (43 candidates)` and
   `FAIL alpha Cen A is inspectable at its stop` (the two clear-eye checks stay `ok`); tail
   `free-nav-stop: 50 passed, 2 failures`; after the restore, porcelain shows nothing beyond the sprint's own
   files (D2 reading).
4. **Parallelism note:** run steps 1 and 2 concurrently and step 3 only after both finish; scratch filenames
   are disjoint and R3 is the only mutator of the tree (design AC preamble; kimi's portability note).

### MS3 — S3: changelog fragment `changelogs/unreleased/2026-11-11-free-nav-stop-eye.md` and AC8 (+ evidence note)

Files: `changelogs/unreleased/2026-11-11-free-nav-stop-eye.md`. Depends on MS2. No product or test change.

1. **Fragment** (`### Fixed` section per `changelogs/unreleased/README.md`): name row **7ak** and sprint
   R1-7AK-FREE-NAV-STOP-EYE; attribute the red to PR #379 (R3-COMMS-V2, merged as `8ba1e3c8`, approved by Mark
   2026-11-03); say the test's eye moved from the lift landing `(8, 82, -4.8)` to G-M4-S3's clear captain eye
   `(11, 82, -4.8)` at both I checks; say one clear-eye `check` now follows each `update_candidates()` so a
   future furniture move fails by name; name the three red controls (R1 old eye 48/4, R2 monitor shift 48/4,
   R3 `_add_body_candidates` mutation 50/2). No product, asset or Makefile change.
2. **AC8:** `git status --porcelain; make uid-guard` → no porcelain lines beyond the sprint's own files (the
   test edit, the fragment, plan/JSON/landing files); `uid-guard` rc 0 (`Makefile:1100`; no new script, so no
   new `.uid`).
3. **Evidence note (per the mission):** before handoff the executor records this sprint's evidence into
   `.ailang/state/sprints/sprint_R1-7AK-FREE-NAV-STOP-EYE.json`: each milestone's `measured` field (AC1–AC8
   actuals — the exact counts, the exact FAIL lines, wall times), `passes: true` per milestone, the fragment
   path here in MS3, and wall-clock totals under `velocity`. MS3 passes only with that evidence recorded.

## Pause points (stop and report; do not improvise)

- Preamble: `runtime/bin/ailang --version` ≠ v0.56.1 or `godot --version` ≠ 4.7.2 → stop; never let
  `AILANG ?= ailang` / `command -v ailang` fall through to PATH's v0.59.0-dev (Makefile:2/:6).
- MS1: a fence extraction ≠ 1/1 lines, a cmp proof fails, or the pre-edit anchor assert mismatches →
  re-extract / stop; never retype design text. AC1 anything but `rc=0` + `free-nav-stop: 54 passed, 0
  failures` → stop; never weaken the target's gate regex to make it pass. AC2 count test ≠ 6 or any `^FAIL`
  among the six → stop.
- MS2: any count or candidate number differing from V10/V14's measured values (the `(40)`/`(41)`/`(43)`
  candidate counts, the FAIL sets, the `48 passed, 4 failures` / `48 passed, 4 failures` / `50 passed, 2
  failures` tails) → the fixture or product drifted since V1; stop and re-measure like V2 before touching
  anything. R1 and R2 scratch copies editing the tree, or another run loading the tree during R3 → stop.
- AC7: the FAIL set ≠ exactly the two named lines, or `git checkout -- ui/ship_star_identification.gd` leaves
  porcelain noise about that file → stop and report; the restore must be byte-exact (V14).
- Timing: a Godot run hitting the 1500 s bound or `make free-nav-stop-test` the 1800 s gate → pause, rerun on
  a quieter host; do not bump the bound silently across retries.
- Any temptation to touch the do-not-touch list below → stop; the fix needs none of it. No merge before the
  cross-family evaluation (generator ≠ judge); landing files wait on it.

## Risks (from the design; planner additions marked)

- **The x = 11 ray's clearance is not measured as a margin** (design Risks): the BVH reports no hit (V7) but
  the margin is unmeasured; a small monitor or frond move could block it again. Mitigation in the bytes: M2
  fails first and says so; the deck-layout row then decides. G-M4-S3 shares the eye and forward look (V13) but
  its behaviour under R2 is unmeasured and not relied on.
- **Merge rule — attended PR #412** ("Captain's cockpit integrated with the current AI-panel build", 48
  files): it touches `demos/ship_geometry_demo.gd` and `ui/ship_star_identification.gd` (both do-not-touch
  here). No textual conflict (V9: it does not touch `tests/test_free_nav_stop.gd`; its `identification.gd`
  hunk adds a `typing()` focus test only, no `update_candidates`/occlusion change; its demo hunks gate HUD and
  camera on `consoles.command.visible`, no geometry `add_child`). Semantic risk low but not zero (its
  `open_navigation()` helm-mode change under the chair cockpit; this test calls it with the chair closed).
  **Whichever lands second reruns AC1 (`make free-nav-stop-test`).** The same rule applies to open PRs #380
  and #373 (V15 measured no overlap: 0 hits on the edited file or any do-not-touch path); if either lands
  first and moves bridge geometry, V2 and V7 are re-measured before this row's ACs are treated as holding.
- **Run time under load:** 445–466 s measured at load 12–25 (V7b/V10/V14), within the target's 1800 s
  `SCRIPT_GATE` budget (`Makefile:1211`).
- **(Planner-added) Scratch root:** `/tmp` is blocked in this sandbox (D1) — `$S` reroot, byte-identical
  expectations; never point the scratch copies into the tree.
- **(Planner-added) Fresh-clone prerequisites:** no `runtime/` (→ `make runtime`, Makefile:725) and possibly no
  sky textures (→ `make sky-assets`, D-18); the designer's iter86-7ak clone had both (V1–V17). The preamble's
  version assert and AC1's green run are the checks.

## Files allowed and do-not-touch (design, verbatim scope)

- **Allowed:** `tests/test_free_nav_stop.gd` (M1 + M2: 2 changed, 2 added), the changelog fragment
  `changelogs/unreleased/2026-11-11-free-nav-stop-eye.md`, and this sprint's plan/JSON. Landing edits (charter
  row, README status, doc/plan move) are the controller's routine.
- **Do not touch:** `demos/ship_geometry_demo.gd`, `ui/ship_star_identification.gd` **(except R3's temporary
  in-run edit, restored in the same step)**, `ui/star_occlusion.gd`, `assets/ship_demo/*`,
  `art/deck-layout-v2/*`, `interior/bridge_monitor.gd`, `tools/m4_ship_golden.gd`, `Makefile`, `mk/*`.

## Local PR gates (targeted, headless, bounded)

The GitHub fast tier is `make ci-fast` — unchanged by this row (design F1: ci-fast membership not proposed; the
target boots the ship demo with starmap and sky assets and takes ~7.5 min, and the CI workflow fetches
neither). For this row:

1. MS1 on record: the byte-for-byte cmp proofs (`m1-ok`, `m2-ok`; the refresh above each clear-eye check), AC1
   (`rc=0`, `free-nav-stop: 54 passed, 0 failures`), AC2 (rc 0, exactly the 6 `ok` lines), AC3 (`2`, `0`, `1`),
   AC4 (allowed file set only).
2. MS2 red-control evidence: R1 rc 1 with grep -c `2`, the fenced grep's two FAIL lines (`(40 candidates)`)
   and tail `48 passed, 4 failures`; R2 rc 1 with `2` / `1` (`(41 candidates)`) and tail `48 passed, 4
   failures`; R3 rc 1 with exactly the two FAIL lines (`(43 candidates)`), tail `50 passed, 2 failures`, the
   restore clean.
3. MS3: the fragment in place; AC8 porcelain clean (sprint's own files only) and `make uid-guard` rc 0.
4. No GPU gate, no `make golden`, no capture, no full local `make test` anywhere in this sprint (merge rule,
   Mark 2026-11-03/06; 7af/7ag/7ah/7ai/7aj precedent) — the nightly `rig/full` runs the suite on main
   post-merge, which is the gate this row repairs (red since PR #379).

## Controller checks (the controller re-runs after the executor)

AC1 tail (`rc=0`, `free-nav-stop: 54 passed, 0 failures`) · AC2 fenced block re-run on the executor's green
log (rc 0, exactly the 6 `ok` lines — the revision-2 note says the corrected AC2 is first run by the executor
and re-run by the controller) · AC3 (`2`, `0`, `1`) · AC4 file set · cmp proofs `m1-ok`/`m2-ok` and the
refresh-above-check shape · AC5/AC6 logs (rc 1; counts `2` and `2`/`1`; the exact FAIL lines with
`(40 candidates)` and `(41 candidates)`; tails `free-nav-stop: 48 passed, 4 failures` twice) · AC7 (rc 1;
exactly the two named FAIL lines with `(43 candidates)`; tail `free-nav-stop: 50 passed, 2 failures`; restore
byte-exact, porcelain clean) · AC8 (porcelain sprint-files only; `uid-guard` rc 0) · the sprint JSON's
measured fields filled.

## Landing (controller, after the cross-family evaluation passes) and post-merge check

Fragment already in tree from MS3; `git mv` doc + plan to `design_docs/implemented/r1/`; README index row;
charter row 7ak status; sprint JSON → recorded counts and wall times, `status: completed`, evaluation block,
path moves. Post-merge (observation, not a gate): the next nightly `rig/full` passes `free-nav-stop-test`
(`free-nav-stop: 54 passed, 0 failures`) and the `nightly-rig` issue sheds exactly it; if PR #412 (or #380 /
#373) landed second without the AC1 re-run, run it once and record.

## Velocity / estimate

~4 LOC in one test file + the fragment, none product. Four Godot runs ≈ 7.5 min each under load (≈ 30 min
machine time; R1 ∥ R2 overlap), edits + greps + evidence ≈ 20 min (design estimates: S1 15 min + one 8 min
run, S2 25 min, S3 5 min). **One executor session, well under half a day** (compare 7ai ~16 LOC half a day,
7aj ~55 LOC half a day).
