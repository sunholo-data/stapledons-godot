# free-nav-stop's I checks look from the clear captain eye (7ak)

**Status:** Planned 2026-11-11 (mission iteration 86, designer). **Release:** r1. **Milestone:** none (suite hygiene, queue row **7ak**).
**Priority:** P1. `make free-nav-stop-test` has been red on main since PR #379 (R3-COMMS-V2, merged as `8ba1e3c8`): `free-nav-stop: 48 passed, 2 failures`, make rc 2 (controller, at `312b1772`; tonight's nightly names the same two checks). The nightly `rig/full` reports it every night, so gate 1 of the definition of done ("main's nightly `rig/full` stays green") cannot hold until it is fixed.
**Implements:** row 7ak of the charter (`design_docs/stapledon-mission.md`, Queue), clause 2/5 hygiene. It restores the R1-SHIP-UI / D-58 checks that the I key offers a free-navigation destination as its finite body (Barnard's Star, inferred radius; alpha Cen A at the D-111 close pass), not the hidden catalogue point. Design-repo context: the I identification overlay and the D-54/D-111 stop rules; no physics-spec formula, shader or table changes.
**Depends on:** nothing.
**Estimated LOC:** 4 lines in one test file, `tests/test_free_nav_stop.gd` (2 changed, 2 added), plus the changelog fragment. No product, asset or Makefile change.

## Game vision alignment

Scored against `../stapledons-design/vision/core-pillars.md` (pillars 1–6) and `physics/relativity-spec.md` for authenticity.

| Pillar | Relevance | Score | Notes |
|---|---|---:|---|
| Choices Are Final | 0 | 0 | No game code changes. |
| The Game Doesn't Judge | 0 | 0 | No copy changes. |
| Time Has Emotional Weight | 0 | 0 | Nothing a player sees or hears changes. |
| The Ship Is Home | 0 | 0 | No scene, furniture or asset changes. The monitor wall Mark approved on 2026-11-03 stays where it is. |
| Grounded Strangeness | 0 | 0 | The checks keep guarding that the destination is offered as a finite star with its inferred radius (D-58). That protects an existing feature; it adds nothing. |
| We Are Not Built For This | 0 | 0 | No crew or AI change. |
| Hard sci-fi authenticity (spec) | 0 | 0 | No formula, shader, lookup table or render change. Physics gates 2 and 3 do not apply. |
| **Net** | | **0** | **Go.** Neutral suite hygiene. No pillar scores below 0, so no stop for a human. |

## Problem

1. **The red (V1).** At `312b1772` the two failing checks are `tests/test_free_nav_stop.gd:62` (`I offers the destination as its finite body, not the hidden catalogue point (40 candidates)`) and `:80` (`alpha Cen A is inspectable at its stop`). Both run after `demo.avatar_pos = Vector3(8, 82, -4.8)` (`:57`, `:76`), `demo.look_direction("forward")` and `ident.set_held(true); ident.update_candidates()`.
2. **The measured cause: the #379 course monitor stands on that eye's look ahead (V2, V3).** After each arrival the destination is dead ahead: its projected point is the screen centre (`local=(-0.0, 0.0, -1.0)`, point `(32, 32)` of a 64×64 headless viewport). Neither body is refused by the sky renderer (`sv_occ=false`). Both are refused by the ship-occlusion BVH (`ui/ship_star_identification.gd:132`, `occlusion.blocked`), and the only surfaces on that ray are two #379 nodes:
   - `BridgeMonitors/monitor_course`, the course monitor's frame (`assets/ship_demo/bridge_monitors.glb`, new in #379), hit at 15.07 m;
   - `monitor_face_course/monitor_screen_course`, its live face (`interior/bridge_monitor.gd`, new in #379), hit at 14.85 m.

   Hiding just those monitor nodes (5 nodes: the frames root and the four faces) brings both bodies back in the same session (`has=true`, candidates 40 → 44 at Barnard, 27 → 30 at alpha Cen A). So the hypothesis in the row is right, and it is now measured. It is not a frustum, view-direction, candidate-cap or filter change: #379 changed neither the test (`git diff 523d96f9 8ba1e3c8 -- tests/test_free_nav_stop.gd` is empty) nor `ui/ship_star_identification.gd` or `ui/star_occlusion.gd` (empty), and the "40" in the label is a count, not a cap (V4).
3. **Why that eye and not another (V5).** `(8, 82, -4.8)` is the lift's landing (`demos/ship_geometry_demo.gd:864`, `tests/test_dressing.gd:85`), not the spawn; the spawn is `spawn_captain` `[0, 13]` (Godot `(0, 82, -13)`), behind the helm, "whose pods fill a level look ahead" (the test's own comment). The course monitor's face centre is ship `(8.582, 19.276, 84.675)`, i.e. Godot `(8.58, 84.68, -19.28)`, 4.0 × 2.25 m with its bottom 1.55 m above the deck (83.55 m), and the eye is at 83.7 m (V2: `cam=(8.0, 83.7, -4.8)`). So the eye's level look ahead passes through the bottom of that screen.
4. **#379 already chose a clear sightline, just not this test's (V6).** The manifest's monitor note reads: "The course screen sits at +24 deg, not the mirror of the signal's -30 deg, so it stays off the forward-pole line of the physics golden's fixed captain eye (G-M4-S3, ship (11, 4.8))." That eye is `tools/m4_ship_golden.gd:241`, `demo.avatar_pos = Vector3(11, 82, -4.8)`, moved there from `(8, 82, -4.8)` by R2-DECK-LAYOUT DL3 for the same kind of reason (a dressed frond). The free-nav test was never moved with it.

## Goals and non-goals

**Goals.**
- `make free-nav-stop-test` is green: `free-nav-stop: 54 passed, 0 failures` (V7).
- Both I checks keep their meaning: the destination body is offered and the hidden catalogue point is not, from an eye the shipped deck lets see the destination; the ship still occludes (a monitor moved onto the new eye's line fails them, R2).
- A future furniture move that blocks the fixed eye fails with a message that names the eye, not only the opaque I check.

**Non-goals.**
- Moving a monitor, desk, frond, the spawn or the lift landing. That is visible and Mark's (D-148 and the deck-layout row).
- Editing `ui/ship_star_identification.gd`, `ui/star_occlusion.gd` or `demos/ship_geometry_demo.gd` (both of the first and the last are in attended PR #412).
- Raising a candidate cap (there is none), dropping the occlusion test, or sky-only mode (`demo.sky_only` skips occlusion and would hide this class of regression).
- `ci-fast` membership for this target (see Follow-ups F1).

## Design

### Classification: (a) TEST-ONLY, loop work

The product is behaving correctly. From the lift landing the course screen really does stand in front of the destination, and the I key correctly refuses to offer a body the player cannot see (the occlusion contract the test itself relies on, `ui/ship_star_identification.gd:101-103, 130-132`). What went stale is the test's choice of eye. The placement of the monitor was approved by Mark (wall R, 2026-11-03) and is not changed here.

### Alternatives considered

| Option | What | Verdict |
|---|---|---|
| (a1) Move the test's eye to the golden's clear captain eye | `(8, 82, -4.8)` → `(11, 82, -4.8)` at `:57` and `:76` | **Chosen.** Measured 52/0 alone (V7a). It is the sightline #379 deliberately kept clear (V6) and the one G-M4-S3 already pins, so the two gates now share one sightline: a later monitor move that blocks it breaks both, which is the point. |
| (a1+) (a1) plus an explicit clear-eye check | one `check` after each `update_candidates()`: the eye's centre ray hits no ship surface | **Chosen, with (a1).** Two lines. Without it, the next furniture move again surfaces only as `I offers … (40 candidates)`, which cost this row a bisect and a hypothesis. With it, the first FAIL line says the eye is blocked (R1, R2). Measured 54/0 (V7b). |
| (a2) Look in another direction from `(8, 82, -4.8)` | e.g. turn the ship or the camera so the destination is off the monitor | Rejected. The arrival puts the destination dead ahead; "look forward at the destination" is the scenario. Turning the eye checks a different picture. |
| (a3) `demo.sky_only = true` for the I checks | skip ship occlusion | Rejected. It removes the occlusion half of the contract the checks stand on. |
| (a4) Hide the monitors during the checks | `monitor_frames.visible = false` | Rejected. It tests a deck that does not ship. |
| (c) Move the course monitor or the landing | Blender/manifest edit | Not loop work (visible). Not needed: the shipped deck has a clear eye already. |

### M1. The eye (tests/test_free_nav_stop.gd:57, :76)

Both lines become:

```gdscript
	demo.avatar_pos = Vector3(11, 82, -4.8) # the captain eye of G-M4-S3 (tools/m4_ship_golden.gd): the lift's landing (8, 82, -4.8) looks into the course monitor (R3-COMMS-V2 wall R), whose bearing keeps this line clear
```

### M2. The clear-eye check (after :60 and :78)

Directly after each `ident.set_held(true); ident.update_candidates()` (the call that refreshes the occlusion BVH's transforms; the check placed before it passed under R2 because `blocked()` reads the transforms of the last refresh, V8):

```gdscript
	check(not ident.occlusion.blocked(demo.camera.global_position, -demo.camera.global_basis.z), "the fixed eye looks ahead past the ship (no surface on its centre ray)")
```

It uses the same BVH and the same eye as the I candidates, so it cannot disagree with them about what blocks.

## Files touched and do-not-touch

- **Touched:** `tests/test_free_nav_stop.gd` (M1, M2: 2 lines changed, 2 added) and a changelog fragment under `changelogs/unreleased/`. Landing edits (charter row, README status) are routine.
- **Do not touch:** `demos/ship_geometry_demo.gd`, `ui/ship_star_identification.gd` (both in attended PR #412), `ui/star_occlusion.gd`, `assets/ship_demo/*`, `art/deck-layout-v2/*`, `interior/bridge_monitor.gd`, `tools/m4_ship_golden.gd`, `Makefile`, `mk/*`.
- **Overlap with attended PR #412 (V9):** none. #412 ("Captain's cockpit integrated with the current AI-panel build", 48 files) does not touch `tests/test_free_nav_stop.gd`. Its `ui/ship_star_identification.gd` hunk (+11 −1) adds a `typing()` focus test for the I key's input path; it does not touch `update_candidates` or occlusion. Its `demos/ship_geometry_demo.gd` hunks gate HUD and camera behaviour on `consoles.command.visible` (the chair cockpit); none adds bridge geometry. **Merge-time risk:** no textual conflict. Semantic risk is low but not zero: #412 changes `open_navigation()`'s helm mode when the chair command is visible (`journey_map.set_mode`), which this test calls 4 times with the chair closed. Whichever lands second reruns `make free-nav-stop-test` (AC1).

## Acceptance criteria

Headless, in the fix clone, after `export PATH=$PWD/runtime/bin:$PATH` (Godot 4.7.2, AILANG v0.56.1). A full run takes about 7.5 min under a load of 12–25 on the Studio (V7). For red controls, `T=tests/test_free_nav_stop.gd` and `G='AILANG_BIN=$(command -v ailang) godot --headless --path .'`; each control is a scratch copy under `/tmp`, never an edit of the tree.

| # | Criterion | Command | Expected |
|---|---|---|---|
| AC1 | The target is green | `make free-nav-stop-test; echo rc=$?; tail -1 .godot/tmp/free-nav-stop.log` | `rc=0`; `free-nav-stop: 54 passed, 0 failures` |
| AC2 | Both I checks and the clear-eye check pass, the destination offered as a body | `grep -E '^(ok\|FAIL) (I offers\|alpha Cen A is inspectable\|a click on A.s centre\|its card says\|the fixed eye looks ahead)' .godot/tmp/free-nav-stop.log` | 6 lines, all `ok`: two `the fixed eye looks ahead past the ship …`, `I offers the destination as its finite body, not the hidden catalogue point (44 candidates)`, `its card says the radius is inferred: …`, `alpha Cen A is inspectable at its stop`, `a click on A's centre picks A, not B (["body:acen-a"])` |
| AC3 | The eye is the golden's, at both checks | `grep -c 'Vector3(11, 82, -4.8)' $T; grep -c 'Vector3(8, 82, -4.8)' $T; grep -c 'Vector3(11, 82, -4.8)' tools/m4_ship_golden.gd` | `2`, `0`, `1` |
| AC4 | Test-only: no product, asset or build file changed | `git diff --name-only origin/main...HEAD` | only `tests/test_free_nav_stop.gd`, a `changelogs/unreleased/*` fragment and landing docs/state; nothing under `demos/`, `ui/`, `interior/`, `assets/`, `art/`, `Makefile`, `mk/` |
| AC5 | **Red control R1, the old eye:** occlusion still counts, and the new check names the cause | `sed 's/Vector3(11, 82, -4.8)/Vector3(8, 82, -4.8)/' $T > /tmp/7ak_r1.gd; eval $G --script /tmp/7ak_r1.gd > /tmp/7ak_r1.log 2>&1; echo rc=$?; grep -c '^FAIL the fixed eye looks ahead' /tmp/7ak_r1.log; grep -E '^FAIL (I offers\|alpha Cen A is inspectable)' /tmp/7ak_r1.log; tail -1 /tmp/7ak_r1.log` | `rc=1`; `2`; the two original FAIL lines (`(40 candidates)`); `free-nav-stop: 48 passed, 4 failures` |
| AC6 | **Red control R2, the furniture moves onto the new eye's line** (the course monitor and its face shifted +2.418 m in x, centred on x = 11) | `awk '{print} /Vector3\(11, 82, -4.8\)/ && !d {print "\tdemo.monitor_frames.position.x += 2.418; demo.geometry.find_child(\"monitor_face_course\", true, false).position.x += 2.418"; d=1}' $T > /tmp/7ak_r2.gd; eval $G --script /tmp/7ak_r2.gd > /tmp/7ak_r2.log 2>&1; echo rc=$?; grep -c '^FAIL the fixed eye looks ahead' /tmp/7ak_r2.log; grep -c '^FAIL I offers the destination' /tmp/7ak_r2.log; tail -1 /tmp/7ak_r2.log` | `rc=1`; `2`; `1` (`(41 candidates)`); `free-nav-stop: 48 passed, 4 failures` (the fourth FAIL is `alpha Cen A is inspectable at its stop`) |
| AC7 | **Red control R3, a product regression in body gathering** (the `_add_body_candidates` call in `ui/ship_star_identification.gd:105` replaced by `pass` in the tree for the run, then restored with `git checkout -- ui/ship_star_identification.gd`) | `sed -i '' 's/^\t_add_body_candidates(sky,view,focal,px,canvas_to_pixel)$/\tpass # R3/' ui/ship_star_identification.gd && make free-nav-stop-test; echo rc=$?; git checkout -- ui/ship_star_identification.gd; grep -c '^FAIL I offers the destination' .godot/tmp/free-nav-stop.log; git status --porcelain` | `rc=2`; `1` (`(43 candidates)`, measured in the short copy, V11; the full-run count is the executor's to record); no `git status` output |
| AC8 | The tree is clean and every `.gd` keeps its `.uid` | `git status --porcelain; make uid-guard` | no status output; `uid-guard` rc 0 (no new script) |

## Sub-milestones and estimates

| Id | Work | Estimate |
|---|---|---|
| S1 | M1 + M2 in `tests/test_free_nav_stop.gd`; AC1–AC4 | 15 min + one 8 min run |
| S2 | Red controls AC5–AC7 (three runs; R1 and R2 can run in parallel, R3 must run alone because it edits the tree) | 25 min |
| S3 | Changelog fragment; AC8 | 5 min |

## Risks and mitigations

- **The x = 11 ray's clearance is not measured as a margin.** The BVH reports no hit (V7), but how far the course frame's edge is from that ray is unmeasured. A small monitor or frond move could block it again. Mitigation: M2 fails first and says so, and the same move breaks G-M4-S3's golden, which shares the eye; the deck-layout row then decides.
- **#412 lands first and changes `open_navigation()`'s helm path** (see Files touched). Mitigation: AC1 after rebase.
- **Run time under load.** 445–466 s here at load 12–25, within the target's 1800 s `SCRIPT_GATE` budget (`Makefile:1211`).

## Open questions for the user

None blocking. The fix is a test eye. One observation for Mark, outside this row and changing nothing: from the lift's landing, a player who looks straight ahead at arrival sees the course screen over the destination, and holding I offers nothing there; one step to starboard (3 m, the golden's eye) clears it. If that view matters, it belongs to the deck-layout row (and D-148's family of #379 placements), not here.

## Follow-ups (new findings, not scope)

- **F1. ci-fast slice: not proposed.** `make -n ci-fast` names no `test_free_nav_stop.gd` line (V12), and the target cannot be sliced cheaply: it boots the whole ship demo with the starmap and sky assets, flies four AILANG legs and takes 7.5 min here; the CI workflow fetches neither `sky-assets` nor `starmap-assets` (V12). A cheap headless guard is possible instead: a GDScript `--script` that reads `assets/ship_demo/manifest.json`'s `monitors` and asserts that the level forward rays of the two fixed eyes (`(11, 83.7, -4.8)` here and in G-M4-S3) miss each face rectangle (4.0 × 2.25 m) with a margin. It would not see frames, stands or fronds, so it is a proxy; it needs its own row, timing and controls.
- **F2. Mutant M2 survives (V11).** Removing the `field.ids[i] in field.pinned_ids` filter in `reindex()` (`ui/ship_star_identification.gd:62`) leaves the "not the hidden catalogue point" check green (44 candidates, 10/0 in the short run). Something else also keeps the catalogue point out (plausibly the per-record duplicate count below it; unmeasured). The check's second half therefore has no measured killing mutant. Worth a row of its own; it is not a #379 regression.
- **F3. Other tests stand on `(8, 82, -4.8)`:** `tests/test_camera_forward.gd:479, 481, 505`, `tests/test_camera_director.gd:236–237, 336, 711, 790`, `tests/test_dressing.gd:85` and `demos/ship_geometry_demo.gd:864` (V5). They are not red for this cause today (the nightly names only this target among them); none of them looks ahead with I.

## Deliverables

- `tests/test_free_nav_stop.gd` (M1, M2).
- `changelogs/unreleased/2026-11-11-free-nav-stop-eye.md`.
- Sprint JSON and evaluation per the cycle.

## Verification log

Run 2026-11-11 in `stapledons-godot-iter86-7ak` at `312b1772` on the Studio (arm64), `PATH=$PWD/runtime/bin:$PATH` (AILANG v0.56.1, Godot 4.7.2), load 12–25. Probes and scratch copies of the test were in `/tmp/stap_i86_designer/`, run as `AILANG_BIN=$(command -v ailang) godot --headless --path . --script /tmp/stap_i86_designer/<x>.gd`; none was committed. Product-file mutations (R3, M2) were applied one at a time and restored with `git checkout -- ui/ship_star_identification.gd`; `git status --porcelain` was empty afterwards.

| # | Command | Result |
|---|---|---|
| V1 | controller: `make free-nav-stop-test` at `312b1772`; `grep -n 'avatar_pos = Vector3(8, 82, -4.8)\|I offers the destination\|alpha Cen A is inspectable' tests/test_free_nav_stop.gd` | `free-nav-stop: 48 passed, 2 failures`, make rc 2, the two FAIL lines of the row; lines `57`, `62`, `76`, `80` |
| V2 | `probe.gd`: replay the test's two legs (Barnard, then `CNS5:3627`), set the eye `(8, 82, -4.8)`, `look_direction("forward")`, hold I; for the destination body print its projection, `sv.occludes_direction`, `occlusion.blocked`, and every `occlusion.meshes` node whose triangle tree the centre ray hits | Barnard: `candidates=40 has=false cam=(8.0, 83.7, -4.8) fwd=(-0.0, 0.0, -1.0) fov=78.0`; `local=(-0.0, 0.0, -1.0) point=(32.0, 32.0) px=(64.0, 64.0) radius_px=1.5 sv_occ=false`; `blocked=true by=["…/BridgeMonitors/monitor_course (dist 15.07)", "…/monitor_face_course/monitor_screen_course (dist 14.85)"]`. alpha Cen A: `candidates=27 has=false`, `radius_px=7.6 sv_occ=false`, `blocked=true` by the same two nodes |
| V3 | same probe, then `demo.monitor_frames.visible = false` and every `demo.monitors` node hidden, `update_candidates()` again (positive control for V2) | `monitors hidden (5 nodes): candidates=44 has=true` (Barnard); `candidates=30 has=true` (alpha Cen A) |
| V4 | `git diff 523d96f9 8ba1e3c8 \| wc -l` for `tests/test_free_nav_stop.gd`, for `ui/ship_star_identification.gd ui/star_occlusion.gd`, and (positive control) for `demos/ship_geometry_demo.gd`; `git diff 523d96f9 8ba1e3c8 --stat -- assets/ship_demo/bridge_monitors.glb`; `sed -n 70,135p ui/ship_star_identification.gd` | `0`, `0`, `88`; `Bin 0 -> 47476 bytes` (new); `update_candidates` has no count limit: stars are filtered by frame, visibility, `occludes_direction` and `occlusion.blocked` (`:103`), bodies by frame, size, `occludes_direction` and `occlusion.blocked` (`:132`) |
| V5 | `sed -n 673,684p demos/ship_geometry_demo.gd`; manifest `spawn_captain`, `walk.bridge_spawn_gltf_m` and `monitors.course`; `sed -n 864p demos/ship_geometry_demo.gd`; `sed -n 85p tests/test_dressing.gd`; `grep -n 'Vector3(8, 82, -4.8)'` over tracked `.gd` | spawn `{'position_m': [0.0, 13.0], 'yaw': 0.47}` → `(0, 82, -13)`; course face `bearing_deg 24.0`, `screen_ship_m [8.582, 19.276, 84.675]`; `:864` `avatar_pos=Vector3(8,82,-4.8) # the lift's landing …`; `LANDING := Vector3(8, 82, -4.8) # the lift's board point`; hits in the files listed in F3 and `tests/test_free_nav_stop.gd:57, 76` |
| V6 | manifest `monitors.about` from "The course screen" on; `sed -n 237,241p tools/m4_ship_golden.gd`; `git log -1 --format=%h%n%s -- assets/ship_demo/manifest.json` | the quoted sentence ("… stays off the forward-pole line of the physics golden's fixed captain eye (G-M4-S3, ship (11, 4.8))"); `:241` `demo.avatar_pos = Vector3(11, 82, -4.8); _pose(-0.01, -PI * 0.5)` with the DL3 frond comment; `cc6dc7c8` "fix(comms-v2): Codex round-1 blockers, screens above the rail, 20 Hz floor" |
| V7 | (a) the test with only M1 (`sed 's/…(8, 82, -4.8)/…(11, 82, -4.8)/'`, 2 replacements); (b) the test with M1 + M2 (`diff` against the tree: lines 57, 76 changed, 61, 80 added) | (a) rc 0 in 466 s: `ok I offers … (44 candidates)`, `ok its card says the radius is inferred: Barnard's Star …`, `ok alpha Cen A is inspectable at its stop`, `ok a click on A's centre picks A, not B (["body:acen-a"])`, `free-nav-stop: 52 passed, 0 failures`; (b) rc 0 in 445 s, two `ok the fixed eye looks ahead past the ship …`, `free-nav-stop: 54 passed, 0 failures` |
| V8 | short copy (test lines 1–67, eye 11, + summary) with M2's check placed **before** `update_candidates()`, with and without R2's monitor shift; then **after** it | before: R2 run `ok the fixed eye looks ahead …` and `FAIL I offers … (41 candidates)` (stale BVH transforms; the check must follow the refresh); after: plain `11 passed, 0 failures`, R2 `FAIL the fixed eye looks ahead …`, `FAIL I offers … (41 candidates)`, `8 passed, 2 failures` |
| V9 | `gh pr view 412 --json files`; `gh pr diff 412` hunks of `ui/ship_star_identification.gd` and `demos/ship_geometry_demo.gd` (grep `add_child\|cockpit\|avatar_pos\|look_direction\|occlu\|visible`); `gh pr list --state open` | 48 files, `demos/ship_geometry_demo.gd +48 -16`, `ui/ship_star_identification.gd +11 -1` (the `typing()` focus helper only), no `tests/test_free_nav_stop.gd`; demo hunks gate on `consoles.command.visible`, no geometry `add_child`; open PRs #412, #380, #373 |
| V10 | full red controls R1 and R2 (scratch copies of the M1+M2 test, as AC5 and AC6), run in parallel | both rc 1. R1: `FAIL the fixed eye looks ahead …`, `FAIL I offers … (40 candidates)`, `FAIL the fixed eye looks ahead …`, `FAIL alpha Cen A is inspectable at its stop`, `free-nav-stop: 48 passed, 4 failures`. R2: the same four lines with `(41 candidates)`, `free-nav-stop: 48 passed, 4 failures` |
| V11 | short copy (eye 11), product mutations one at a time: R3 `_add_body_candidates(...)` → `pass` (`:105`); M2 `if i >= field.ids.size() or field.ids[i] in field.pinned_ids:continue` → `if i >= field.ids.size():continue` (`:62`); baseline unmutated | baseline `ok I offers … (44 candidates)`, `10 passed, 0 failures` (63 s); R3 `FAIL I offers … (43 candidates)`, `8 passed, 1 failures`; M2 `ok I offers … (44 candidates)`, `10 passed, 0 failures` (survives, F2) |
| V12 | `make -n ci-fast > f; wc -l f; grep -c 'test_free_nav_stop\|ship_geometry_demo' f; grep -c similar_guard_controls f` (positive control); `make -n free-nav-stop-test \| grep -c test_free_nav_stop.gd` (positive control); `grep -c 'sky-assets\|starmap-assets' .github/workflows/ci.yml` | `226`, `0`, `1`; `1`; `0` |
