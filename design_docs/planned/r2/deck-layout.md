# R2-DECK-LAYOUT: deck furniture and sightlines for the fixed views, then Blender hero art

**Status:** Planned, awaiting Mark's approval (design doc and sprint plan only; nothing executed).
**Release:** R2. **Milestone:** the bridge and the Commons, rearranged for R2-CAMERA's authored views and then dressed with Blender hero assets.
**Priority:** P1 for R2. Every session is seen through these views, and Mark asked for the pass twice (2026-10-17, 2026-10-19).

**Mark's direction** (verbatim):
> 2026-10-17: "once we have settled the fixed views we will arrange the deck furniture and sightlines a bit to optimise visuals."
> 2026-10-19: "yes lets do a good deck layout sprint. I was thinking now we have fixed camera angles we can do some blender work to make them beautiful."

**Implements** (design repo):
- [art/ship-interior-blender-brief.md](https://github.com/sunholo-data/stapledons-design/blob/main/art/ship-interior-blender-brief.md) §3 (ship canon: spire, bridge under the forward pole, tiny humans in cathedral spaces), §4 (Moebius / *Métal Hurlant* style), §5 (the physics contract: never paint space), §6 (kit, `WALK_` / `SPAWN_` / `INTERACT_` collections).
- [art/README.md](https://github.com/sunholo-data/stapledons-design/blob/main/art/README.md) "Who renders what", "Review and hand-off" (style frames first, stop for Mark; large binaries by sha256 in `gs://stapledons-voyage-assets/`).
- [vision/design-decisions.md, 2026-10-03 "Bridge v2"](https://github.com/sunholo-data/stapledons-design/blob/main/vision/design-decisions.md): the spire is the ship-fixed key light, so its light and shadow **may be baked**; nothing from outside the ship is baked; the palette pulled toward the captain sheet. And "Bridge v2 follow-up: forward sky first".
- [features/future/bubble-ship-layout.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/bubble-ship-layout.md) "Observation Deck": minimal interior, focus on the exterior, **the captain's chair as the focal point**.
- [physics/relativity-spec.md §2](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md) (aberration and Doppler: forward crowds and blues, sideways and aft go dark) and [physics/higgs-bubble.md §6](https://github.com/sunholo-data/stapledons-design/blob/main/physics/higgs-bubble.md) (the wall glow): the sky and glow stay live; the pass only decides what architecture frames them.
- This repo: [implemented/r2/camera-fixed-views.md](../../implemented/r2/camera-fixed-views.md) §D2, §D8 and §D9 ("Lower deck (Commons): deferred to the deck-layout pass", which this doc owns); ledger D-83 (the camera ruling), D-84 (the S1 render findings).

**Depends on:**
- R2-CAMERA (landed, PR #270). The views and their data (`data/camera/views.json`) are the input; this pass may retune per-cell values but does not add views.
- Blender 5.2.1 LTS in `~/dev/blender` (verified headless: `./blender.sh -b` imports `bpy` 5.2.1; masters open without missing files).
- No physics change: `sunholo/relativity` is not touched (gate 3 holds trivially).

**Estimated LOC:** game repo about 1,050 (layout evaluator 320, tests 300, capture and contact sheets 160, asset pins and checks 170, data and manifest 100). Blender generator scripts live in `~/dev/blender/scripts` (about 1,200 lines of `bpy`) and are **not** a game pipeline step: the game consumes GLBs and pins, as today (`art/ship-demo-v1/grounded-bridge-v2/README.md`: "No Python asset pipeline is added to the game").

## Game vision alignment

Scored with the `game-vision-designer` skill (feature-validation mode, against `vision/core-pillars.md`, the 2026-10-03 bridge decisions and D-6), 2026-10-19. **ALIGNED.**

| Pillar | Score | Rationale |
|---|---|---|
| Choices Are Final | 0 | Neutral. Stations keep their functions and use points; no decision moves |
| The Game Doesn't Judge | 0 | Neutral |
| Time Has Emotional Weight | +1 | The bridge is where the decades pass; a composed Z2 frame keeps the ageing captain at the centre of a place that reads as lived-in |
| The Ship Is Home | +2 | The bridge stops being a demo kit: stations arranged around the captain's chair, each view framing a station or the crew, hand-finished to the sprites' level ("the bridge has to look as hand-made as its people", 2026-10-03) |
| Grounded Strangeness | +1 | The sightlines give the live sky more of every sky view (the starbow is the centrepiece under way). Risk: hero props competing with the sky; guarded by a measured sky-fraction floor (§D4) and the goldens |
| We Are Not Built For This | +1 | Cathedral scale: a 1.75 m figure among tall consoles under a 100 m dome |
| **Net** | **+5** | **Go.** No pillar is negative |

## Problem

The bridge and the Commons were laid out for the first-person eye and the iso spike, before R2-CAMERA gave the player fixed third-person views. Evidence (a code and asset read at `origin/main` c62353a, the R2-CAMERA doc §D9, the D-84 S1 set, and the before captures in §Evidence):

1. **Every station sits in one quadrant.** In ship coordinates (Blender, metres) the navigation arc is at (−9.4, −3.4), (−7.1, −7.1), (−3.4, −9.4); the decision consoles at (−8, 2), (−10.5, 6.5), (−13.2, −3), (−12, −9.5); the Archive terminal at (−3, −2.1); the captain's chair at (1.9, −5.2). The east half of the 22 m disc holds only the lift (8, 8) and the spawn beside it. Half the eight sector views frame empty deck, and the other half frame a crowd of consoles.
2. **The captain's chair is not a focal point.** It is off-centre, faces nothing in particular, and is not a station (the design guideline calls it the focal point).
3. **The spawn is against the lift box.** The default Z2 at rest opens on the lift's guardrails; the R2-CAMERA evidence noted "the lift wall fills half the frame" for a low view at the spawn.
4. **The spire needle forced a second sector ring** (512 blocked samples in R2-CAMERA's first sweep). The stations ring inside 12 m now looks inward across the consoles, so Z2 near the stations is a view of console backs.
5. **The Commons sightlines still fail.** The clear line from camera to captain's head is blocked at 2 (Z1), 2 (Z2) and 39 (Z3) of 1,881 walk samples under the arcades' lintels, held as ceilings in `tests/test_camera_director.gd` (`LOWER_CEILING`). A pillar fills about a third of the Z3 frame, and the captain is about 45 px there.
6. **D-84 S1 findings that belong to geometry:** a hull spire in every forward view (the needle crossing the starbow in Sky forward). The other S1 findings (flat Earth and α Cen A discs, cards over transit frames, dust flashes at rest) are not layout and stay in their own rows.
7. **The finish is a technical draft.** `art/ship-demo-v1/painted-bridge-v1/deployment.md`: "Final ink detail and art approval ... are pending." The play GLB is flat-painted toon; Mark ruled on 2026-10-03 that the bridge should reach the captain sprites' hand-illustrated finish.

## Goals and non-goals

**Goals**
- G1. **Layout for the views.** Rearrange the bridge furniture (stations, chair, Archive terminal, lift head, rail props) so every authored view frames something deliberate: the captain, a station or the crew, and the sky.
- G2. **Sightlines measured, not eyeballed.** A layout evaluator scores every candidate on the camera's walk samples: clear line, captain size, sky fraction in sky views, stations in Z3, nothing between the boom and the captain. The Commons ceilings go to **0**.
- G3. **A layout blockout first**, reviewed by Mark in captures before any hero art (the art bible's "style frames first").
- G4. **Blender hero assets per view**: the props each view frames, rebuilt in Blender to the sprite finish, with the spire's light baked (allowed, 2026-10-03) and nothing from outside the ship baked.
- G5. **Physics unchanged.** The sky, the bubble glow and the lensing are the live render; no geometry paints or blocks them beyond the measured floor. `make golden` stays green.
- G6. **Performance held.** `make bench SCENE=bridge` p99 < 16.7 ms at 2560×1440 (M4 AC12, row 7m) on a quiet rig; the asset budgets in §D6.

**Non-goals**
- New camera views, zoom levels or rules (R2-CAMERA owns them; this pass may retune per-cell values in `views.json`, and, only if Mark picks it at DL1, fix Sky forward’s `walk_to.angle_deg` as §D1’s fallback).
- New stations or console functions. Reserved consoles 2 and 3 stay inactive (they may move).
- Lower ship levels other than the Commons (residential, garden cathedral): future areas.
- An exterior view (R2-CAMERA OQ5).
- The UI card coverage, planet disc and dust-flash findings of D-84.
- Character art (captain and crew sprites are unchanged).

## Design

### D0. What the views need (per-view composition goals)

The views are R2-CAMERA's (`data/camera/views.json`). Each row is a goal the evaluator measures (§D4) and the captures show.

| View | Frames today (before captures) | Composition goal |
|---|---|---|
| **Z2 Deck**, bridge (default at rest) | Lift guardrails at the spawn; console backs on the stations ring | The captain at ~65–70 px on the lower third, one station or the chair in the near field, the rail and sky beyond. At the spawn: the captain facing the chair and the stations, not the lift |
| **Z1 Close**, bridge | Navigation consoles crowd the frame (Z1 pitch already moved to −25° to clear them) | The captain and the one thing within reach; no prop within 1.5 m of the boom |
| **Z3 Whole level**, bridge | The whole disc from the rim | Every active station readable (≥ 24 px tall), the chair at the centre of the composition, the captain ring visible |
| **Sky forward** (default under way) | Captain under the starbow; the spire needle crosses the forward sky (D-84) | The forward pole and the starbow unobstructed: sky fraction ≥ the floor in §D4 at β 0.9 / 0.99 / 0.999; the needle out of the pole's neighbourhood |
| **Sky side** (guided stops) | The captain at the rail toward the body | A clear rail segment at every sector a stop can use: no frond or prop between the captain and the body's direction |
| **Sky aft** | The ship's levels below the rail | Unchanged (floors blocking the aft sky is physics) |
| **Sky hole** (Sgr A*) | The hole 18° above centre | As Sky forward, at the hole's direction |
| **Console focus** | The screen fills the frame | Unchanged; a station may move but its `focus_pose` is computed from its mesh |
| **Lift** | Fixed on the shaft | Unchanged geometry; the lift head is restyled only |
| **Z1 / Z2 / Z3 Commons** | Lintels block 2 / 2 / 39 samples; a pillar fills a third of Z3; the captain ~45 px | Ceilings 0 at every level; no single prop over 15 % of the Z3 frame; the captain ≥ 55 px at Z2 |

### D1. Bridge layout proposal (to be tested by the evaluator, then shown to Mark)

A starting proposal, not a ruling. The evaluator (§D3) scores it and up to three alternatives; DL1 shows Mark the best two.

- **The chair at the centre of the working half**, facing outward over the rail, so Sky forward's captain silhouette and the chair share the frame. The chair becomes a soft station: no new function, but the captain spawns at it instead of against the lift. **Where the spawn lives:** today it is hard-coded (`_reset_captain()` in `demos/ship_geometry_demo.gd`, `Vector3(8, 82, -4.8)`, yaw 0.47; `ShipConsoles.BRIDGE_SPAWN`), and `tests/test_camera_director.gd` (the R-returns-to-Z2 check and `test_spawn_occlusion`) asserts it. DL1 moves it into `assets/ship_demo/manifest.json` (`spawn_captain: {position_m, yaw}`), read by both, and updates those tests red first. The physics tests that use (8, 82, −4.8) as a **fixed observer** (`tests/test_physics.gd`, `tests/test_ship_star_light.gd`) keep it: they test observer positions, not the spawn.
- **Stations on a horseshoe around the chair** at 8–11 m from the spire: navigation arc, Voyage console, Crew console, Archive terminal (the Archive stays against the spire, as canon). This spreads the stations so most of the eight sector views frame one station each, rather than one quadrant holding all of them.
- **Reserved consoles 2 and 3** move to the far side of the horseshoe so they read as crew posts in Z3 (inactive, as now).
- **The lift head keeps its shaft** (ship XY 8, 8 is pinned by `manifest.lift_route` and the lower deck); only its guardrails and housing are restyled, and the spawn moves away from it.
- **The rim fronds** (`rim_frond_0..9`, 5 m tall) are thinned where Sky side's rail segments need a clear line, keeping their silhouettes elsewhere as foreground framing.
- **The spire needle in Sky forward:** Sky forward has no fixed anchor today. `views.json` sends the captain to the rail (`walk_to: {radius_m: 15, angle_deg: "captain"}`, keeping the captain's current bearing) and chooses the camera yaw from `yaw_candidates_deg`, so the pose depends on where the captain stood. The pass measures every landing pose (bearings every 5° at 15 m, 72 poses) and moves props, not the needle (canon), until the worst pose keeps the forward pole at least 15° from any geometry. If no layout achieves that at every bearing, the fallback is a named data anchor (`walk_to.angle_deg` fixed to the best bearing, an R2-CAMERA data value) for Mark to choose at DL1.

The Commons: raise or open the arcade lintels that block the 43 samples, and move or slim the pillar that fills Z3. Commons streets keep their `WALK_` topology where possible, so the per-cell camera values change least.

### D2. Layout as data

- **`art/deck-layout-v1/layout.json`** in this repo holds each movable prop's ship-frame position, yaw and footprint, keyed by the GLB node name (`console_navigation_0`, `captain_chair`, ...). Node names stay stable: `ShipConsoles.STATIONS` finds stations by name, and console focus derives its pose from the mesh.
- The **Blender generator** (`~/dev/blender/scripts/stapledon_deck_layout_v1.py`, run through `./blender.sh`) reads that JSON and rebuilds the bridge master from the grounded v2 master: moves props, regenerates the `WALK_bridge_deck` holes, and exports `ship.glb` and `walk_bridge.glb`. The same JSON drives the Commons pass. This keeps the layout reviewable as a diff, and reproducible (the art bible: "prefer a reproducible generator script over hand edits").
- The **Godot evaluator** (§D3) can also apply `layout.json` in-engine to today's GLB (moving the named nodes and treating footprints as obstacles for walk samples), so candidates are scored in seconds without a Blender round trip. The Blender export is the source of truth; the evaluator's in-engine mode is for search only, and every AC runs on the exported GLB.

### D3. The layout evaluator

`tools/deck_layout_eval.gd` (headless, `GODOT_SIM`) loads the ship (or a candidate `layout.json` applied in-engine), walks every walk sample at 0.5 m (the camera test's grid), resolves each authored view through `CameraDirector`, and reports per view:

- **clear line:** samples whose eye-to-head ray hits opaque geometry (the R2-CAMERA AC1 test, shared code);
- **captain px:** head-to-foot height at 1280×720;
- **station legibility:** for Z3, the projected height of each active station;
- **sky fraction:** for the sky views, the share of frame rays (a 64×36 grid at 78° FOV) that reach the sky without hitting ship geometry, plus the angular clearance of the forward pole from the nearest geometry. The rays are cast against the **visual** meshes (`ship.glb`, built into a temporary `ConcavePolygonShape3D` per mesh), not the collision or walk meshes, which omit the fronds, rails and needle. It is computed over every pose the view can land in (Sky forward: the 72 walk_to bearings; Sky side: every guided-stop sector), reporting the worst and the median. A positive control compares it with a rendered frame's sky mask (alpha of the geometry viewport) for one pose, within 2 %;
- **boom intrusion:** props within 1.5 m of the eye-to-head segment;
- **frame dominance:** the largest single node's screen share at Z3.

Output: `renders/deck_layout/eval_<candidate>.json` and a one-line summary per view; `--compare a.json b.json` prints a table. `make deck-layout-eval` runs it on the shipped GLB and fails on any threshold in §D4.

### D4. Thresholds (the bar for a layout)

| Metric | Bridge | Commons |
|---|---|---|
| Clear-line blocked samples, every level view | 0 (today 0, keep) | **0** (today 2 / 2 / 39) |
| Captain at Z2 (1280×720), every walk sample | 60–80 px (today ~65–70 at the spawn) | ≥ 55 px (today ~45, re-measured in DL0); the lever is the per-cell `distance_m` in `views.json`, re-swept for the clear line |
| Active stations in Z3, each ≥ 24 px | 4 of 4 | n/a |
| Sky forward, over the 72 walk_to landing poses (§D1) | sky fraction worst ≥ 0.45 and median ≥ 0.55 (both re-measured in DL0), and the forward pole ≥ 15° from any geometry at every pose | n/a |
| Sky side: clear rail segments | every sector a guided stop uses | n/a |
| Boom intrusions (props within 1.5 m of the eye–head segment) | 0 | 0 |
| Largest single node at Z3 | ≤ 15 % of frame | ≤ 15 % (today the pillar ~33 %) |

The numbers marked "today" are re-measured in DL0 by the evaluator. DL0 may tighten a floor that today’s layout already beats. The Sky forward floors (0.45 / 0.55, 15°) are first estimates: if DL0 measures that no plausible layout reaches them at every bearing, DL0 sets them from the measurement and says so in one line to Mark, and the fixed-bearing fallback (§D1) becomes the planned route.

### D5. Blender hero assets

Once Mark approves a blockout (DL1/DL2), each view's framed props are rebuilt in Blender:

- **What:** a priority list by screen time: the captain's chair; the navigation arc; the Voyage and Crew consoles (one kit piece, two dressings); the Archive terminal and shrine ribs; the rail and its fronds; the lift head; the spire base (to the deck height only; the needle and spire body stay canon geometry). Commons: the arcade and its pillars.
- **How (authoring):** generator scripts in `~/dev/blender/scripts/` under that workspace's `AGENTS.md` and `skills/blender-studio-workflow`, producing a new master `art/deck-layout-v1/stapledon_bridge_deck_v1.blend` (packed, no external files). The bridge v2 route applies: clean geometry, hand-painted texture pigments (the captain sheet's cream / ochre / violet), and a refine pass to reach the sprites' illustrated finish.
- **Light:** the spire is the ship-fixed key light, so its **light and shadow are baked** into a second UV set (lightmap) on the props, as the 2026-10-03 ruling allows. **Nothing from outside the ship is baked:** the starlight on the deck (`ship_star_light.gd`), the wall glow and the sky stay live layers on top.
- **Style frames first:** for each view, one composed in-engine capture at rest and at 0.99c, reviewed by Mark before the remaining props are built (DL3 pause).
- **Export:** glTF 2.0 binary, Blender +Z → glTF +Y, metres, modifiers applied, stable node names, `WALK_` / `SPAWN_` / `INTERACT_` collections as the brief's §6. Materials stay opaque (`all_materials_opaque` in the pins).
- **Hosting:** every GLB the game loads stays **under 10 MB and in git**, as today (`ship.glb` 9.1 MB), so the build staging (`ship-demo-stage`, `ship-commons-stage`), CI and `tools/rig_check.sh`’s fresh clone need nothing new. The `.blend` masters and review-only files go to `gs://stapledons-voyage-assets/ship/<sha256>` with pins in `art/deck-layout-v1/asset-pins.json`, fetched by `make ship-masters` for authoring only (the D-18 pattern). If a runtime GLB cannot fit in 10 MB, that is a budget miss reported to Mark, not a silent move to the bucket.
- **Determinism:** the generator records its script sha256 and the authoring commit; a clean reimport of each GLB (`ship-demo-assets-test`, `validate-ship-demo`) is part of the ACs; the same layout and script produce byte-identical GLBs (checked once by re-running the export).
- **Licences:** project art is owned by Sunholo and ships under Apache-2.0 (art bible, 2026-10-03); no third-party models or textures. Any reference image used in a refine pass is recorded in a `SOURCES` row.

### D6. Performance budget

The bridge in live transit is already at the edge: M4.6pR3 brought `make bench SCENE=bridge` p99 to 15.5–16.3 ms against a 16.7 ms bar at 2560×1440. The pass therefore holds the scene's cost flat:

| Budget | Today (grounded v2 pins) | Limit |
|---|---|---|
| Bridge + ship visual triangles | 200,399 (153 mesh instances) | ≤ 220,000 |
| Materials / images | 14 / 10 | ≤ 18 / ≤ 16 (the lightmap atlas counts) |
| Texture memory (VRAM after loading the bridge, `RenderingServer.get_rendering_info(RENDERING_INFO_TEXTURE_MEM_USED)`) | measured by `deck-assets-check` in DL0 | ≤ +32 MB over today |
| `ship.glb` bytes | 9.1 MB | < 10 MB (stays in git) |
| `make bench SCENE=bridge` p99, quiet rig | 15.5–16.3 ms | < 16.7 ms |

Props reuse one kit mesh per type (instancing), the Commons gets a coarse LOD (the existing `commons_coarse.glb` route), and baked light adds no live lights. The budgets live in `art/deck-layout-v1/budgets.json`, read by `make deck-assets-check` (created in DL0, in `make test` from then on). **The bench runs at DL3 on the style-frame props**, before Mark approves the finish, so the approval is not undone by DL4. **Fallbacks if p99 misses**, in order: halve the lightmap atlas, drop prop textures to 1K, use the coarse LOD for props beyond 12 m, merge the rail and frond meshes.

**Python policy.** The `bpy` generators are authoring tools in the Blender workspace (`~/dev/blender`, its own repo), like a DCC application, and are not a step of this repo’s pipeline: the game loads committed GLBs and checks their pins, and `make python-guard` still sees no new `*.py` here. This is the grounded v2 precedent ("No Python asset pipeline is added to the game"); OQ8 asks Mark to confirm it for this larger pass.

### D7. The physics guard

- **No painted space:** no hero asset carries a sky, star, glow or lensing texture; the dome is not modelled (the bubble is the engine's). Checked by the asset check (no emissive material outside the console screens and the spire's existing emission).
- **Goldens:** `make golden` and `make camera-views-capture` run at **DL1 and DL2, before Mark’s pause**, so a layout he picks cannot break them later. `make golden` stays at 0 failures with the same case count (393 `ok` lines in `golden.log` today, plus the constellation goldens). G-M4-S2 (one tonemap), S3 (forward pole at the captain's eye) and S4 (glow) run on the new geometry; if the moved spawn changes a golden's observer position, the golden's reference is recomputed by its independent sim/CPU reference (never re-recorded from the GPU output).
- **Sky views:** `make camera-views-capture` keeps its existing assertions (the starbow in frame at β 0.9 / 0.99 / 0.999, the hole in frame at every Sgr A* stop).
- **Captures opened:** every frame of DL1, DL3 and DL5 is opened before its pause, as the definition of done requires for visuals.

## Acceptance criteria

| # | Criterion | Command |
|---|---|---|
| AC1 | The evaluator reproduces today's numbers on the shipped GLB and fails on a seeded bad layout | `make deck-layout-eval-test` (positive control on today's GLB; negative control: a fixture layout with a console on the Z2 boom must fail with `boom-intrusion`) |
| AC2 | Bridge thresholds (§D4) met on the exported GLB | `make deck-layout-eval` prints `deck-layout: bridge ok` and exits 0 |
| AC3 | Commons clear-line ceilings are 0 | `make camera-test` with `LOWER_CEILING := {1: 0, 2: 0, 3: 0}`; and `make deck-layout-eval` prints `deck-layout: commons ok` |
| AC4 | Stations still work where they moved: walk-to, reach, focus pose, every action | `make ship-ui-test crew-console-test crew-hold-test` (existing suites) and `make camera-test` |
| AC5 | The walk map is valid: the lift route clear, the spawn on the deck, no walk sample inside a footprint | `make ship-demo-assets-test validate-ship-demo ship-demo-lift-test` |
| AC6 | Asset pins match and GLBs reimport cleanly; materials opaque; budgets of §D6 | `make deck-assets-check` (created in DL0: sha256 of every pinned file, clean reimport, node names, triangle/material/image counts, bytes, VRAM, no emissive outside screens and the spire; budgets from `art/deck-layout-v1/budgets.json`) |
| AC7 | The masters fetch by pin; runtime GLBs stay in git under 10 MB | `make ship-masters && make deck-assets-check MASTERS=1` (masters sha256 match `asset-pins.json`; every runtime GLB < 10 MB) |
| AC8 | Physics goldens unchanged in count, 0 failures | `make golden` (its own count assertion: 393 `ok`, 0 failures, plus `constellation-golden`) |
| AC9 | Sky views keep the starbow and the hole | `make camera-views-capture` (0 failures; cruise defaults at β 0.9 / 0.99 / 0.999 frame the pole) |
| AC10 | Performance | `make bench SCENE=bridge` p99 < 16.7 ms at 2560×1440 on a quiet rig (logged with host load) |
| AC11 | Review captures: every view, rest and 0.99c, before and after, two sizes, contact sheets published | `make deck-layout-capture` writes `renders/deck_layout/{before,after}/*.png` and `contact_*.png`; the URLs are in the report |
| AC12 | The full suite is green; no new Python in the game | `make test` and `make python-guard` |

## Sub-milestones and estimates

| ID | What | LOC (game) | Depends on | Pause |
|---|---|---|---|---|
| DL0 | Evaluator (§D3), thresholds (§D4), `deck-assets-check` and its budgets file, before captures and numbers, `deck-layout-capture` | ~560 | — | — |
| DL1 | Bridge blockout: `layout.json`, candidates scored, Blender generator move-and-export (grey props, current materials), the two best candidates captured | ~150 | DL0 | **Mark picks a layout** |
| DL2 | Commons blockout: lintels and pillar, ceilings to 0, per-cell camera values retuned | ~120 | DL0 | with DL1's review |
| DL3 | Bridge hero assets, style frame: the chair and the navigation arc dressed and lit (baked spire light), captured in Sky forward and Z2 at rest and 0.99c | ~80 | DL1 | **Mark approves the style frame** |
| DL4 | Bridge hero assets, the rest of §D5’s list; pins, masters in the bucket | ~90 | DL3 | — |
| DL5 | Commons hero pass (arcade, pillars) at the same finish | ~50 | DL2, DL3 | — |
| DL6 | Integration: goldens, bench, captures, packaged smoke, report, landing | ~0 (docs) | DL4, DL5 | — |

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Hero props push p99 over 16.7 ms | §D6 budgets checked by `deck-assets-check` from DL0; instancing; the bench runs at DL3 (before the style-frame approval), DL4 and DL6; the fallbacks in §D6, in order |
| Moving the spawn changes golden observers | `make golden` runs before the DL1/DL2 pause; references are independent (sim/CPU); recompute, never re-record; AC8 keeps the count |
| Baked light looks wrong at 0.99c when the sky changes | Only the ship-fixed spire light is baked; the live starlight and glow layers stay on top (2026-10-03 ruling); style frames at rest and at 0.99c |
| The art does not reach the sprites' finish | The DL3 style frame is a hard stop; Mark can redirect before the other props are built |
| A Blender generator diverges from the master | The generator is the source; `.blend` masters are outputs with the script sha in the pins, as grounded v2 does |
| The repo grows with each art iteration | Files over 10 MB and masters by sha256 in the bucket (D-18 pattern) |
| Station moves break muscle memory from dev.33 | Tab "Walk to" and the HUD prompts are unchanged; the dev tag's notes say the bridge was rearranged |

## Open questions for Mark (with recommendations)

| # | Question | Recommendation |
|---|---|---|
| OQ1 | Who models: an agent writing `bpy` generator scripts in `~/dev/blender` (as every ship asset so far), or you by hand in Blender, or both? | **Agent-generated, you tweak masters if you want.** The generator stays the source of truth, so any hand edit is folded back as script changes |
| OQ2 | Art style references for "beautiful": keep the Moebius / *Métal Hurlant* toon-and-ink look of the sprites and the bridge v2 plate, or move toward a more painterly 3D finish? | **Keep the sprites' illustrated finish** (the 2026-10-03 ruling); the DL3 style frame shows it |
| OQ3 | May the captain's chair become the default spawn and the bridge's focal point (no new function)? | **Yes** (the design-repo guideline names it the focal point) |
| OQ4 | Keep the spire needle as canon and move props, or shorten it where it crosses the starbow in Sky forward? | **Keep the needle; move props**, and if needed fix Sky forward’s walk_to bearing (§D1); the evaluator measures ≥ 15° pole clearance at every landing pose |
| OQ5 | Scope: the bridge and the Commons only, or also the lift interior? | **Bridge and Commons**; the lift is restyled only where it shows on the bridge |
| OQ6 | Bake the spire's light into lightmaps on the play GLB (beyond the plate the 2026-10-03 ruling covered)? | **Yes**, same reasoning: the spire is ship-fixed; nothing from outside the ship baked |
| OQ7 | How many layout candidates to review at DL1? | **Two**, the evaluator's best, with their numbers |
| OQ8 | Confirm the Blender `bpy` generators as authoring tools outside the game’s Python policy (they live in `~/dev/blender`; the game reads only GLBs and pins)? | **Yes**, the grounded v2 precedent |

Mark’s approval of the plan answers OQ1–OQ8 (the attended session records them as one ledger row). OQ1 must be answered before DL1 (the generator runs there); OQ2 and OQ6 before DL3.

## Evidence: the before state

See §Evidence below (captures and evaluator numbers from DL0's first run are added when the sprint executes; the before contact sheet captured for this doc is linked here).

## Deliverables

- `tools/deck_layout_eval.gd`, `tools/deck_layout_capture.gd`, `tools/deck_assets_check.gd`, `tests/test_deck_layout_eval.gd`, `mk/deck-layout.mk` (`deck-layout-eval`, `deck-layout-eval-test`, `deck-layout-capture`, `deck-assets-check`, `ship-masters`).
- `art/deck-layout-v1/`: `layout.json`, `asset-pins.json`, the master `.blend` (or its bucket pin), validation logs, README with the generator's commit and sha.
- Updated `assets/ship_demo/` and `assets/ship_commons/` GLBs (or pins), `data/camera/views.json` per-cell values if retuned, `LOWER_CEILING` to 0.
- `design_docs/implemented/r2/deck-layout-report.md`: before/after numbers per view, contact sheets, bench, goldens.
