# Sprint R2-DECK-LAYOUT (re-planned for the Bow view): face the bow, then Blender hero assets

**Design doc:** [deck-layout.md](deck-layout.md)
**Sprint JSON:** `.ailang/state/sprints/sprint_R2-DECK-LAYOUT.json`
**Status:** **Approved** (D-95, 2026-10-20, every recommendation; layout A). Executing. The first plan (D-90) was approved and paused at DL1 when the camera changed (D-91 to D-93); Mark accepted the F1 Bow view on 2026-10-20 (D-94). Nothing in this plan is executed until he approves; it has two further hard stops (DL1 blockout, DL2 style frame).
**Base:** `feat/camera-forward` 0a787245 with `origin/main` 8982bd78 merged (branch `design/deck-layout-bow`). DL0 rebases onto main once #282 merges.
**AILANG:** v0.54.14 (pinned). No `.ail` code in this sprint (syntax gate: skip, no AILANG module is written). Registry reuse: none (Godot tools and Blender assets; no maths for `sunholo/relativity`).
**Estimate:** about 900 game LOC plus about 1,000 lines of `bpy` in `~/dev/blender`, **8 working days** of execution, excluding Mark's review time at the two pauses. That is about 115 game LOC a day, well under the recent attended rate of about 300 (R2-CAMERA: 1,700 LOC in about 5.5 days), because Blender iteration, baking and GPU captures dominate and are not counted in game LOC. DL2 and DL3 are the optimistic part (hand-finished art plus lightmaps); their day caps return any overrun to Mark at the next pause.

## What the survey found

- **The Bow view and its tools exist** (F1, PR #282): `CameraDirector.walk_pose`, `occluders_for`, `clear_after_fades`; `make camera-forward-test` (22 checks), `make camera-test` (182, including a Bow sweep of all 4,803 bridge samples), `tools/camera_forward_review.gd`.
- **The DL0 tools exist on the paused branch** (`feat/deck-layout` 7863c831): `DeckLayout` (applies a layout in-engine and rebuilds the walk by clipping only the moved rectangles), `deck_assets_check.gd` + `budgets.json` (VRAM baseline 112.6 MB), `deck_layout_capture.gd`, and an evaluator with 26 passing checks, all aimed at the old sector views. `DeckLayout` and `layout_current.json` are already on this branch (the probe uses them); the rest carries over in DL0.
- **The probe** (`tools/deck_bow_probe.gd`, this plan's evidence) measures what the bow evaluator needs: fades by family, blocked after fades, the stop body by side, the spawn's open walk and near field, the stations' facing and clearance, the pole in the console zoom; it also draws the plan view and a contact sheet. One trap it found: a moved prop's collider reaches the physics space only after the transform notifications flush, so metrics wait a few physics frames after `apply`.
- **The stations' operator point is a guess today** (`ShipConsoles.setup`: the nearest walkable point), so "faces the bow" needs authored use points (design §D2).
- **The fading list is hard-coded** (`OCCLUDER_NAMES` in `demos/ship_geometry_demo.gd`); it moves to `views.json`.
- **The Blender route is proven:** `art/ship-demo-v1/grounded-bridge-v2/` (generator `stapledon_bridge_floor_restore_v2.py`, authoring commit `e4da963`, packed masters, `asset-pins.json`, a clean reimport).
- **Budgets are tight:** `ship.glb` 9.1 MB, 200,399 triangles, 14 materials, 10 images; `make bench SCENE=bridge` p99 15.5–16.3 ms against 16.7 ms.

## Milestones

### DL0: carry-over, the bow evaluator, occluders as data (~450 LOC, 2 days)
- **Carry over** from 7863c831: `tools/deck_assets_check.gd`, `budgets.json` (to `art/deck-layout-v2/`), `tools/deck_layout_capture.gd`, `mk/deck-layout.mk` (included from the Makefile), and the asset check's fixtures. Drop the sector-view metrics, `thresholds.json` and `layout_a/b.json` (they face the old views).
- **Red first:** `tests/test_deck_layout_eval.gd` rebuilt for the bow:
  - positive control: the **pinned grounded v2 export** (uploaded once to `gs://stapledons-voyage-assets/ship/<sha256>`, fetched with `curl` into an untracked cache, loaded through the carried `asset_dir` hook) reproduces the §D4 "today" numbers, so the control still holds after DL1 changes the shipped GLB (Bow fades 530, pole blocked 0, head blocked 0 / 4, body blocked on both sides 8, spawn open 0 m, stations facing the bow 1 of 4, pole in the console zoom 0 of 3);
  - negative controls (fixtures under `tests/fixtures/deck_layout/`): a station turned to face the stern fails `faces-bow`; a box on the spawn's bow line fails `spawn-open`; a box at eye height on the Bow pole line fails `pole-ray`; a station with its use point in the mast's shadow fails `station-body`;
  - `deck-assets-check` passes on today's pins and fails on the wrong-sha and emissive fixtures.
- **Prove the size route:** a one-texture WebP glTF fixture (`EXT_texture_webp`) imports in Godot 4.7 and `deck-assets-check` counts its bytes and image (design §D5).
- **Build:** `tools/deck_layout_eval.gd` on the probe's measurements (failure names are the §D4 IDs), with `--layout <json>` (in-engine search) and the §D4 thresholds in `art/deck-layout-v2/thresholds.json`; `deck-layout-eval-test` and `deck-assets-check` join `make test`; `make deck-layout-capture TAG=<tag>` (GPU) runs the probe's capture and sheet.
- **Occluders as data (red first):** `levels.bridge.occluders` in `data/camera/views.json` with F1's list; `CameraDirector.validate` checks it; `_mark_occluders` reads it. New `make camera-test` checks: a non-list is rejected; the demo's group equals the data's.
- **Gate:** `make deck-layout-eval-test deck-assets-check camera-test camera-forward-test`.

### DL1: bridge blockout in Blender (~250 LOC + generator, 2.5 days, half a day of it contingency) ⏸ Mark plays it
- **Generator spike first (0.5 day):** `~/dev/blender/scripts/stapledon_deck_layout_v2.py` moves one prop from the layout JSON and exports; `make deck-assets-check ship-demo-assets-test validate-ship-demo` pass on that export before the full move.
- **Blender:** the generator reads `art/deck-layout-v2/bow_a.json` (or Mark's pick at plan approval), moves the named props in a copy of the grounded v2 master, re-routes the conduits, regenerates the `WALK_bridge_deck` holes, writes `INTERACT_<station>_use` and `SPAWN_captain`, keeps node names and the lift shaft, and exports `ship.glb` and `walk_bridge.glb`. Props keep their current materials (a blockout, not art).
- **Game, red first:** the manifest's `spawn_captain` and `stations.<id>.use_m`; new cases in `tests/test_ship_consoles.gd` (the manifest's `use_m` wins; a station without one uses today's rule); the spawn read by `_reset_captain()`, `ShipConsoles.BRIDGE_SPAWN`, `test_camera_director.gd`, `test_camera_forward.gd` and `camera_forward_review.gd`. Fixed physics observers keep (8, 82, −4.8).
- **Gate:** `make deck-layout-eval` (`deck-layout: bridge ok` on the export), `make deck-assets-check ship-console-test ship-ui-test crew-console-test crew-hold-test camera-test camera-forward-test ship-demo-assets-test validate-ship-demo ship-demo-lift-test ship-commons-test ship-commons-assets-test ship-commons-arcade-test` (`ship.glb` also carries the Commons), then **`make golden`** (idle rig) and `make deck-layout-capture TAG=dl1`, every frame opened and published.
- **Pause:** a dev build (`make publish-dev`, no `v*` tag) for Mark to play, with the capture sheet and the numbers. He accepts the blockout or asks for moves (recorded as a ledger row in the attended session).

### DL2: style frame (~60 LOC + generator, 1.5 days) ⏸ Mark approves the finish
- The dressed props export to `bridge_props.glb` (WebP textures, lightmap ≤ 2048²), and their blockout copies leave `ship.glb` (design §D5 size strategy).
- Dress the navigation arc (with an operator-side screen on its stern face, OQ7) and the captain's chair to the sprites' finish: painted pigments in the captain sheet's palette, the spire's key light baked into a lightmap UV set (OQ6); live starlight and glow unchanged.
- **Precondition:** Mark has answered OQ6 and OQ7 (at plan approval).
- Capture the Bow view at rest, at 0.99c and at the first guided stop, and the navigation zoom (`make deck-layout-capture TAG=dl2`); open every frame; publish.
- **Gate:** `make deck-assets-check` (the budgets now with the lightmap atlas, and both GLBs' bytes under 10 MB on the style-frame export), `make deck-layout-eval`, `make golden`, and **`make bench SCENE=bridge`** on a quiet rig, so the finish Mark approves is known to fit the frame budget.
- **Pause:** Mark approves the style frame or redirects before the rest is built.

### DL3: the rest of the hero assets (~80 LOC + generator, 1.5 days)
- In order: the Voyage and Crew consoles (one kit piece, two dressings), the bow rail and its two framing fronds, the bow-half deck surface, the Archive terminal and shrine ribs, the lift head, the benches, the stern fronds and rail, the conduits, the reserved consoles 2 and 3, the spire base to deck height.
- **Pins and hosting:** `art/deck-layout-v2/asset-pins.json` (generator sha, authoring commit, each runtime file's bytes and sha256, materials, images, opaque). Runtime GLBs stay in git under 10 MB; `.blend` masters go to `gs://stapledons-voyage-assets/ship/<sha256>`, fetched by `make ship-masters` (authoring only). If p99 misses, apply the design's fallbacks in order before asking Mark.
- **Gate:** `make deck-assets-check deck-layout-eval camera-test camera-forward-test ship-console-test ship-commons-test ship-commons-assets-test`; `make ship-masters && make deck-assets-check MASTERS=1` (public-read fetch by `curl`, no credentials); `make golden`; `make deck-layout-capture TAG=dl3` with every frame opened and published; `make bench SCENE=bridge` on a quiet rig (host load logged).

### DL4: integration and landing (docs, 0.5 day)
- `make test` on the rig (`tools/rig_check.sh`), `make golden` (393 `ok`, 0 failures), `make bench SCENE=bridge` (p99 < 16.7 ms, quiet), `make deck-layout-capture TAG=after` with before/after sheets published, a dev build.
- `design_docs/implemented/r2/deck-layout-report.md` (numbers, before/after, bench, goldens); a changelog fragment `changelogs/unreleased/2026-10-XX-deck-layout.md`; evaluation by a different model from the executor (the executor is Opus; the judge runs Sonnet, `sprint-evaluator`); the finish itself is judged by Mark at DL2, not by command; then landing (docs to `implemented/r2/`, the design-repo roadmap row, and the brief's "stations face the bow" line made canon).

## Pause points

| After | Mark sees | Mark decides |
|---|---|---|
| Approval of this plan | The design doc, this plan, the review frames and the contact sheet | OQ1–OQ8 (one ledger row); OQ1–OQ3 before DL1, OQ6–OQ7 before DL2 |
| DL1 | A dev build with the blockout, the capture sheet and the §D4 numbers | Accept the blockout, or ask for moves |
| DL2 | The style frame: Bow at rest, 0.99c, the first stop, the navigation zoom; the bench | Approve the finish, or redirect |

## Risks

See the design doc's table. Sprint-specific:
- **The rig is shared** with the mission loop: GPU captures and the bench wait for an idle rig (an until-loop on `pgrep -f "make test"`), and the bench logs host load.
- **Art iteration can run long:** DL2 and DL3 are capped at their days; anything past the cap returns to Mark at the next pause rather than growing silently.
- **A fresh clone lacks `data/raw/.gdignore`** and needs `make ai-core-assets ai-core-bundle` before `publish-dev` (found in F1); DL1 does both before its dev build.

## Validation (every milestone)

The focused gates listed per milestone, run with the pinned runtime; the full `make test` on the rig at DL4 (and before any dev tag). Changelog as a fragment. Every capture opened before a pause.
