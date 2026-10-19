# Sprint R2-CAMERA-FORWARD: travel along the deck, and a fixed bow view that slides with the captain

**Design doc:** [camera-forward.md](camera-forward.md), revised for D-92. Ledger: D-91 and D-92.

**Sprint JSON:** `.ailang/state/sprints/sprint_R2-CAMERA-FORWARD.json`

**Status:** **Approved** (Mark, attended 2026-10-19, ledger D-93, every recommendation). In progress: F1.

**Approval gate:**
- Mark answers OQ1–OQ4: the Bow framing, planet facing at stops, astern and side, and zoom.
- Design repo PR [#30](https://github.com/sunholo-data/stapledons-design/pull/30) merges before F1a's lore re-import. If it hasn't, F1a lands without that step and F3 completes it.

**Scope:**
- **F1a:** the ship basis change.
- **F1b:** the Bow view, the slide rig and occluders, then a dev build.
- **F2:** Astern, switching, the console, and stops and Sgr A* in frame.
- **F3:** captures, migration, evaluation and landing.

**Base:**
- Branch `feat/camera-forward` from `origin/main` (775bf07 or later), one PR.
- A dev tag after F1b.
- Every commit keeps `make test` green on the rig.

**AILANG:** there is no sim change, so the pin stays v0.54.14. AC-B5 proves that `sim/` is untouched.

## What the survey found (origin/main 775bf07)

**One mapping serves two frames today.**
- The structure frame (Blender, `cam_*.json`, the Commons data) maps to glTF as `(s.x, s.z, −s.y)`.
- The kinematic frame (the sky, glow, dust and observer, with +Z along the velocity) is its inverse: `ShipCamera.ship_vector(g) = [g.x, −g.z, g.y]`.
- D-92 inserts a fixed rotation R between them. Design §D1 lists every site: 11 kinematic and 7 structure.

**Shaders follow `orient_basis` for free.** The glow and dust overlays get `ship_x/y/z` from `InteriorSky.orient_basis` (interior_sky.gd:175–180).

**The sim never sees the interior frame.**
- The heading, glow and dust are all galactic or kinematic.
- `sunholo/relativity` 0.12.0 uses +z = velocity only.
- So no package release, no protocol minor version and no replay re-record are needed.

**The prototype confirms the geometry.**
- With `ShipCamera.travel_axis = "bow"`, a camera at pitch −8° looking at glTF −Z sits 8.05° from the direction of travel.
- The rendered starbow is over the bow rail; I opened the frames.

**Candidate A passes 16/16 walk samples.** At −8°, 9 m back and 5.5 m up:
- the pole and the destination are in frame;
- the starbow at 0.9c and 0.99c is in frame;
- the captain is 73 px;
- the deck fills 59% of the frame.

**The spire is the one obstacle.** It blocks the pole ray in 2 of 16 samples and swallows the eye in 1, hence the occluder rule (design §D2).

**Stop turns put the body out of frame.** `Attitude.side_basis` uses a 15° tilt, which puts the body 75° off the travel axis. Under D-92 that is out of the Bow frame, so the tilt goes to 60° (attitude only).

**Sgr A* already holds the ship's nose on the hole** (`m4_ship_golden.gd:248`).

**HUD copy assumes "travel is up":** `ship_geometry_demo.gd:428`, the status line, and `look_direction`'s tilt table.

**Lore:** `data/lore/archive/one-g.md` and `starbow.md` say up is forward. Design PR #30 fixes the source, and F1a re-imports it.

**Goldens:**
- **To re-pose:** G-M4-S3 (`_pose(89.99, 0)` looks up), G-CAM-1/2/3 (Sky forward and the Z eyes), and G-M4-S2/S4 (through `ship_vector`).
- **Unaffected:** interior_golden (a pure ship frame, and the painted-plate legacy path, byte-identical), GR* and M1.x.

**Tests:**
- `tests/test_physics.gd:1705` builds `_ship_cam` with the old map.
- `m4_playthrough_ship.gd` aims at the forward pole.
- `ship-demo-ci` is on `make test` (Makefile:973). `camera-test` hangs off it, and `camera-forward-test` will too.
- `camera-test` echoes only some lines, so the ACs grep the saved logs.

**The paused deck work** (`feat/deck-layout` 7863c831):
- Its asset check, layout tool and sky maths carry over.
- Its views and layouts don't.
- The re-plan will face the bow (design §D9).

## Plan shape

```
F1a (basis change, goldens + physics re-baselined, lore) ──▶ F1b (Bow view, rig, occluders) ──▶ [pause: dev tag, Mark plays] ──▶ F2 (Astern, switches, console, stops, Sgr A*) ──▶ F3 (captures, migration) ──▶ E (evaluate, land)
```

## Milestones

### F1a: the ship basis change (~650 LOC, 2.5 days)

**Red first:**
- `tests/test_camera_forward.gd` (new) with `ok    basis R proper bow->+Z mast->+Y` and the kinematic and structure composite-map checks.
- The `camera-forward-test` recipe, on `ship-demo-ci`.
- `tools/golden_baseline.sh capture|check` (shell). It records main's `golden.log` ok lines, with numbers stripped, into `tests/fixtures/golden_baseline_ok.txt`. Capture runs on main first.
- The AC-B1 grep gate. It fails on main: 18 inline sites with the old patterns, 19 once the new-map pattern is added. It has a positive control, `tests/fixtures/basis_gate/inline.gd.txt`, that holds old-form and new-form literals.
- `golden_baseline.sh selftest`: a moved number in a non-excluded line must fail.

**Green:**
- Named maps:
  - `ShipFrame.gltf_from_structure` / `structure_from_gltf`, plus R, in `interior/ship_frame.gd`;
  - `ShipCamera.ship_vector` / `gltf_from_ship`, R-composed, in `demos/ship_demo_camera.gd`. The prototype flag is removed.
- Every site rewired, per design §D1.1 (kinematic) and §D1.2 (structure).
- `CameraDirector.aim_dir` returns the bow.
- The `side_basis` tilt becomes 60°.
- HUD copy and `look_direction` re-posed.
- G-M4-S3 and G-CAM re-posed; recipe labels updated, with the same prefixes.
- `tests/test_physics.gd` `_ship_cam` uses the new map. Its `sky_camera` cases (lines 1066–1090, the painted-plate path) stay byte-identical (design §D1.6).
- The painted-plate path keeps the pre-D-92 basis, with a label and no number changes (design §D1.6). Its tests (`test_area_bundle`, `test_interior`, `test_bridge_floor`, m4-smoke, `interior_golden`) must pass unchanged.
- `BRAKE_NOTICE` and the tour-turn camera arguments (design §D1.5).
- **Every test these changes break moves in the same commit:** `test_physics`, `test_ship_demo`, `test_tour_attitude`, `test_ship_attitude`, `test_no_twitch`, `test_transit`, `test_ship_star_light`, `test_ship_demo_journey`, `test_ship_demo_live`, `test_free_nav_stop`, `test_camera_director` and `test_ship_ui`.
- `tests/fixtures/physics_total.txt` captured from main first (AC-B3).
- The lore re-imported (`make lore-import D=../stapledons-design`) if #30 has merged. Otherwise it moves to F3 (AC-B6).

**Check:**
- AC-B1 to AC-B5 and AC-R2 (AC-B6 too, if #30 has merged).
- `make physics`, the headless tests that F1a touches, and `make golden` on the rig. F1 as a whole ends green (see F1b).
- `make golden` on the rig: 393 lines, and a clean baseline diff outside the re-posed families.
- `make capture`, with the frames opened.

**Pause:** if any golden outside the re-posed families moves, stop. List the diff with before and after renders. Mark either accepts the re-baseline (it is recorded in the PR) or the site is fixed.

### F1b: the Bow view, the slide rig and occluders (~450 LOC, 1.25 days)

**F1a and F1b are one green point, F1.**
- Commits inside F1 may be red. Once the basis changes, `camera-test`’s legacy pole and hole checks fail until the Bow view replaces those views. That is by design, and it is noted in the commit messages.
- F1 ends green with `make camera-test` and a full `make test` on the rig. Only then is the dev build tagged.
- F1b adds `CameraDirector.pole_dir()` (the bow) and moves `test_camera_director.gd`’s pole literals (lines 589, 595, 633 and 704–810) onto it. The legacy sky-view checks are replaced by the Bow ones.

**Red first, in `camera-forward-test`:**
- `ok    yaw constant bow spread=… deg over 16`
- `ok    in frame bow pole|starbow_0.9c|starbow_0.99c 16/16`
- `ok    clear after fades bow pole_ray|captain|eye_free 16/16`
- `ok    captain px bow …`
- `ok    deck fraction bow …`
- `ok    envelope keeps the angle`
- `ok    eye above deck at 32 samples`
- `ok    level default bridge|commons`
- `ok    deterministic poses 600 steps`
- `ok    fade leaves sky and sim untouched`

**Red first, elsewhere:**
- `camera-test` (single-space format): `ok schema v2` and 7 `ok negative control v2 …` lines.
- The `camera-walk-capture` recipe: Bow and Astern passes, driven by the real director rather than the prototype.

**Green:**
- `views.json` v2: level-keyed, `travel_axis: "bow"`. The bridge has `bow` (candidate A, per OQ1) and `console`; the Commons is legacy.
- `CameraDirector`:
  - the slide rig, `eye = foot − flat(yaw)·back + up·rise`, with the basis never re-aimed;
  - the dead zone, follow, envelope slide, and eye ≥ deck + 0.3;
  - the legacy fence;
  - level defaults on the lift's arrival.
- The occluder group: the `Spire*` meshes (including `spire_needle_col`) and the lift's boxes. Each fades under rules (a), (b) and (c), alpha to 0.25 over 0.2 s of `advance(dt)`, with hiding as the fallback.
- The captain faces the bow at rest, and facing follows screen motion.
- Keys: 7 is Bow and R is Bow. The zoom actions become developer-only (OQ4).

**Check:**
- AC-V1 (Bow), V2, V3, V4, V7 and V9–V12.
- A full `make test` on the rig.

**Pause point:** tag a dev build and ask Mark to play the Bow view.

### F2: Astern, switching, console, stops and Sgr A* in frame (~200 LOC, 0.5 day)

**Red first:**
- `ok    yaw constant astern …`
- `ok    W up-screen|D right bow|astern`
- `ok    W up-screen after switch bow>astern|astern>bow`
- `ok    switch ease max … deg/s`
- `ok    reduced cut`
- `ok    mapping at ease end`
- `ok    console returns to bow|astern exact`
- `ok    in frame bow stop_body|sgr_a_hole 16/16`, using a `target_override` fixture for the stop body.

**Green:**
- Astern: yaw 90° (ShipCamera's convention), on key 9.
- Switch eases.
- `restore()` returns to the view id.
- Cues return to Bow.
- `sky_side` and `sky_hole` stay, but only as tool and golden poses.

**Check:** AC-V1 (Astern), V5, V6 and V8.

### F3: captures, migration, evaluation, landing (~300 LOC, 1.75 days)

**Lore:** if design PR #30 merged after F1a, re-import now (AC-B6).

**Captures:**
- `tools/camera_views_capture.gd` gets the new view list: Bow, Astern, the legacy Commons and the lift.
- Each view is captured at rest, at 0.9c and 0.99c, at the first guided stop and at Sgr A*, at 720p and 1440p.
- The gates check the pole, the body or hole, and the captain's head. One forced-fade frame is included.
- Then `make camera-walk-capture`.
- Open every frame, and publish the after-sheets to `gs://stapledons-voyage-assets/refs/camera_forward/after/`.

**Migration** (the design §D10 list):
- about 11 tests rewritten or retargeted;
- the make-target smoke of each capture tool that names a renamed view id;
- the dead bridge sector paths removed, with the legacy fence kept;
- a changelog fragment;
- the `demos/README.md` controls.

**Evaluate:** an independent model (not the executor) runs the `sprint-evaluator` skill; 70 points to pass. Its should-fix items are applied.

**Land:**
- `implemented/r2/` and the README index;
- the design repo's roadmap status;
- then the D-90 deck re-plan, facing the bow, as a separate attended step.

**Check:**
- AC-B6 (if not already met), AC-R1 and AC-T1.
- A full `make test` and `make golden` on the rig before merge.
- AC-T2 at landing.

## Acceptance criteria

The criteria are the design doc's AC-B1–B6, AC-V1–V12, AC-R1–R2 and AC-T1–T2. Each row names its exact command and log line. The sprint JSON's `acceptance_commands` carries them verbatim, with the markdown escaping removed, and is the copy to run.

## Pause points

1. **After F1a:** if any golden outside G-M4-S2..S4 or G-CAM-1..3 moves, stop and list the diff for Mark, with before and after renders. Mark accepts the re-baseline or the site is fixed.
2. **After F1b:** the dev tag. Mark plays the Bow view. It is a visible feature, so this is attended.
3. **If the occluder rule can't reach 16/16 on AC-V3:** stop and ask. The options are a slide box that keeps the eye out of the spire, or a different `back_m`. The camera never turns.
4. **Before merge:**
   - the after-captures have been opened by eye (gate 2);
   - `make test` and `make golden` are green on the rig.

## Risks

See the design doc's table. Two are specific to planning:
- **F1a touches about 30 files and the goldens.** The baseline tool and the grep gate exist so that a misfiled site fails loudly rather than silently.
- **The lore step depends on design PR #30.** It can slip to F3 without blocking anything else.

## Velocity

R2-CAMERA landed about 1,700 LOC in 5.5 planned days, about 310 LOC a day including evaluation fixes. This sprint is about 1,600 LOC in 6.0 days, about 270 a day. F1a budgets for round trips to the Studio GPU, batching re-poses per golden run.
- F1a's basis surgery and golden re-baseline go slower per line.
- F2 is small because it shares F1b's rig.
