# Sprint R2-DECK-LAYOUT: deck furniture and sightlines for the fixed views, then Blender hero art

**Design doc:** [deck-layout.md](deck-layout.md)
**Sprint JSON:** `.ailang/state/sprints/sprint_R2-DECK-LAYOUT.json`
**Status:** **Approved** (Mark, attended 2026-10-19, ledger D-90, every recommendation). Executing DL0-DL2; the next stop is the DL1/DL2 layout pick.
**Base:** `origin/main` at `c62353a` (2026-10-19).
**AILANG:** v0.54.14 (pinned). No `.ail` code in this sprint (syntax gate: skip, no AILANG module is written). Registry reuse: none (Godot tools, Blender assets; no maths for `sunholo/relativity`).
**Estimate:** about 1,050 game LOC plus about 1,200 lines of `bpy` generator in `~/dev/blender`, **11 working days** of execution, excluding Mark's review time at the two pauses. Recent velocity on attended R2 sprints is about 300 game LOC a day (R2-CAMERA 1,700 LOC in about 5.5 days; R2-HOME-TIERS 720 LOC in one day), but art iteration and captures dominate here, so the plan budgets by milestone, not by LOC.

## What the survey found

- **The views and their test exist.** `data/camera/views.json` (12 views), `demos/camera_director.gd`, and `tests/test_camera_director.gd` already sweep a clear line from every 0.5 m walk sample; the Commons residue is held as `LOWER_CEILING := {1: 2, 2: 2, 3: 39}`. The evaluator reuses that sweep rather than re-deriving it.
- **The capture exists.** `make camera-views-capture` (`tools/camera_views_capture.gd`) renders all ten place and level views, plus the cruise defaults at β 0.9 / 0.99 / 0.999 and every Sgr A* stop, at 1280×720 and 2560×1440, failing on |eye| > 95 m or the captain off frame. DL0 wraps it for before/after contact sheets.
- **The layout is in the GLB.** Stations are found by node name (`ShipConsoles.STATIONS`: `console_navigation_0..2`, `console_decision_0..3`, `archive_terminal`); `captain_chair` is a mesh but not a station. All stations sit at x < 0 (one quadrant and a half); the spawn (ship 8, 4.8) is beside the lift (8, 8).
- **The Blender route is proven.** `art/ship-demo-v1/grounded-bridge-v2/` shows the pattern: a generator in `~/dev/blender/scripts`, packed masters, `asset-pins.json` with script and file sha256, validation logs, a clean reimport. Blender 5.2.1 LTS runs headless here (`./blender.sh -b`, `bpy` imports).
- **Budgets are tight.** `ship.glb` is 9.1 MB, 200,399 triangles, 14 materials, 10 images; `make bench SCENE=bridge` p99 is 15.5–16.3 ms against 16.7 ms after M4.6pR3.
- **Goldens:** `make golden` asserts 393 `ok` lines plus the constellation goldens; G-M4-S2/S3/S4 run on the 3D ship.

## Milestones

### DL0: the evaluator, the asset check, thresholds and before evidence (~560 LOC, 2 days)
- **Red first:** `tests/test_deck_layout_eval.gd`:
  - positive control: today's GLB reproduces the camera test's blocked counts (bridge 0; Commons 2 / 2 / 39);
  - negative controls (fixtures under `tests/fixtures/deck_layout/`): a console moved onto the Z2 boom fails `boom-intrusion`; a 6 m prop placed at a Sky forward landing pose (bearing 0°, 15 m) fails `sky-fraction`; a Z3 frame with one node over 15 % fails `frame-dominance`;
  - the sky-fraction metric against a rendered frame’s sky mask for one pose, within 2 % (it casts on the visual meshes);
  - `deck-assets-check` on today’s pins passes, and on a fixture with a wrong sha256 and one with an emissive prop fails.
- **Build:** `tools/deck_assets_check.gd` and `art/deck-layout-v1/budgets.json` (sha256 pins, clean reimport, node names, triangles, materials, images, bytes, VRAM via `RENDERING_INFO_TEXTURE_MEM_USED`, emissive scan; `deck-assets-check` joins `make test`); `tools/deck_layout_eval.gd` (shared sweep with the camera test; captain px, station legibility, sky fraction by ray casts on the visual meshes (over every landing pose), pole clearance, boom intrusion, frame dominance; `--layout <json>` applies a candidate in-engine; `--compare`); `tools/deck_layout_capture.gd` (wraps the camera capture into `renders/deck_layout/<tag>/` with contact sheets); `mk/deck-layout.mk` (`deck-layout-eval`, `deck-layout-eval-test`, `deck-layout-capture`), included from the Makefile; `deck-layout-eval-test` joins `make test`.
- **Evidence:** before numbers per view (including the Commons Z2 captain px and the bridge VRAM) into the design doc's §Evidence; before contact sheets (rest and 0.99c, both sizes) to `gs://stapledons-voyage-assets/refs/deck_layout/before/`. Open every frame.
- **Gate:** `make deck-layout-eval-test camera-test`; `make deck-layout-capture TAG=before` (GPU window).

### DL1: bridge blockout (~150 LOC + generator, 2.5 days, half a day of it contingency) ⏸ pause for Mark
- **Layout data:** `art/deck-layout-v1/layout.json` (node name → ship-frame position, yaw, footprint) for the §D1 proposal and up to three alternatives.
- **Generator spike first (0.5 day):** the Blender script moves one prop and exports; `make deck-assets-check ship-demo-assets-test validate-ship-demo` pass on that export before the search, so the round trip is proven early.
- **Search (capped: the proposal plus at most three alternatives, 0.5 day):** If DL1 runs late, the cut is the proposal plus one alternative. score each with `deck_layout_eval.gd --layout` in-engine; keep the two best by the §D4 thresholds. If none meets the Sky forward floor at every bearing, include the fixed-bearing fallback (§D1) as a candidate.
- **Blender:** `~/dev/blender/scripts/stapledon_deck_layout_v1.py` reads `layout.json`, moves the named props in a copy of the grounded v2 master, regenerates the `WALK_bridge_deck` holes, keeps node names and the lift shaft, exports `ship.glb` and `walk_bridge.glb`. Props stay in their current materials (a blockout, not art).
- **Game, red first:** the spawn moves from code into `assets/ship_demo/manifest.json` (`spawn_captain`), read by `_reset_captain()` and `ShipConsoles.BRIDGE_SPAWN`; update the spawn assertions in `tests/test_camera_director.gd` (the R-returns-to-Z2 check, `test_spawn_occlusion`) first; the fixed-observer physics tests (`test_physics.gd`, `test_ship_star_light.gd`) keep (8, 82, −4.8). `ShipConsoles` otherwise unchanged (it finds stations by name); per-cell values in `views.json` retuned only if the evaluator needs it.
- **Gate:** `make deck-layout-eval` (bridge ok on the exported GLB), `make deck-assets-check camera-test ship-ui-test crew-console-test crew-hold-test ship-demo-assets-test validate-ship-demo ship-demo-lift-test`, then **`make golden` and `make camera-views-capture`** (GPU, idle rig) before the pause, with their results on the sheet Mark sees.
- **Pause:** captures of both candidates (`make deck-layout-capture TAG=dl1-a`, `TAG=dl1-b`) published with their numbers; **Mark picks one** (recorded as a ledger row in the attended session).

### DL2: Commons blockout (~120 LOC + generator, 1 day) ⏸ reviewed with DL1
- Raise or open the lintels over the 43 blocked samples; move or slim the Z3 pillar; regenerate `walk.glb` and `collision.glb` for the Commons from the same generator (Commons section of `layout.json`).
- Set `LOWER_CEILING := {1: 0, 2: 0, 3: 0}` first (red), then make it pass.
- The Commons Z2 captain floor (≥ 55 px) via per-cell `distance_m`, re-swept for the clear line.
- **Gate:** `make camera-test deck-layout-eval deck-assets-check ship-commons-test ship-commons-assets-test ship-commons-arcade-test`, then `make golden camera-views-capture` before the joint pause.

### DL3: bridge style frame (~80 LOC + generator, 1.5 days) ⏸ pause for Mark
- Dress the captain's chair and the navigation arc to the sprites' finish: painted pigments (the captain sheet's palette), the spire's key light baked into a lightmap UV set (OQ6), live starlight and glow layers unchanged.
- Capture Sky forward and Z2 at rest and 0.99c (both sizes), open every frame, publish to `refs/deck_layout/style_frame/`.
- **Precondition:** Mark has answered OQ2 and OQ6 (OQ1 before DL1).
- **Gate:** `make deck-assets-check` (the budgets file, now with the lightmap atlas), `make golden`, and **`make bench SCENE=bridge`** on a quiet rig with the dressed props, so the finish Mark approves is known to fit the frame budget.
- **Pause:** **Mark approves the style frame** (or redirects) before the rest is built.

### DL4: the rest of the bridge hero assets (~90 LOC + generator, 2 days)
- The Voyage and Crew consoles (one kit piece, two dressings), the Archive terminal and shrine ribs, the rail and fronds (thinned where Sky side needs a clear segment), the lift head housing, the spire base to deck height, reserved consoles 2 and 3.
- **Pins and hosting:** `art/deck-layout-v1/asset-pins.json` (generator sha, authoring commit, each runtime file’s bytes and sha256, materials, images, opaque). Runtime GLBs stay in git under 10 MB; the `.blend` masters go to `gs://stapledons-voyage-assets/ship/<sha256>`, fetched by `make ship-masters` (authoring only). If p99 misses, apply the design’s fallbacks in order before asking Mark.
- **Gate:** `make deck-assets-check deck-layout-eval camera-test ship-ui-test`; `make ship-masters && make deck-assets-check MASTERS=1`; `make bench SCENE=bridge` on a quiet rig (log host load).

### DL5: Commons hero pass (~50 LOC + generator, 1 day)
- The arcade and pillars at the same finish; the coarse LOD regenerated.
- **Gate:** `make deck-assets-check deck-layout-eval ship-commons-test ship-commons-assets-test`.

### DL6: integration and landing (docs, 1 day)
- `make test`, `make golden` (count unchanged, 0 failures), `make camera-views-capture` (0 failures), `make bench SCENE=bridge` (p99 < 16.7 ms quiet), `make deck-layout-capture TAG=after` with before/after sheets published, a packaged smoke of the review build.
- `design_docs/implemented/r2/deck-layout-report.md` (numbers per view, before/after, bench, goldens); changelog fragment `changelogs/unreleased/2026-10-XX-deck-layout.md`; evaluation by a different model (sonnet), then landing (docs to `implemented/r2/`, design-repo roadmap row).

## Pause points

| After | Mark sees | Mark decides |
|---|---|---|
| DL1 + DL2 | Two bridge candidates and the Commons fix: contact sheets at rest and 0.99c, with each view's numbers | Which bridge layout (or changes), and, if offered, the Sky forward fixed-bearing fallback |
| DL3 | The style frame: chair and navigation arc dressed, Sky forward and Z2 at rest and 0.99c | Approve the finish, or redirect |
| Approval of this plan | The design doc and this plan | OQ1–OQ8 (one ledger row; OQ1 needed before DL1, OQ2 and OQ6 before DL3) |

## Risks

See the design doc's table. Sprint-specific:
- **The rig is shared** with the mission loop and `make test` runs: GPU captures and the bench wait for an idle rig (an until-loop on `pgrep -f "make test"`), and the bench logs host load.
- **Art iteration can run long:** DL3 and DL4 are capped at their days; anything past the cap returns to Mark at the next pause rather than growing silently.

## Validation (every milestone)

The focused gates listed per milestone, run with the pinned runtime; `make test` in full at DL6 (and before any dev tag). Changelog as a fragment. Every capture opened before a pause.
