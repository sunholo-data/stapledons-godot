# R2-DECK-LAYOUT: a bridge laid out for the Bow view, then Blender hero assets

**Status:** Approved by Mark on 2026-10-20 (ledger D-95: "yep these are great", then "A"), with every recommendation; executing on `feat/deck-layout-bow`. The first plan (D-90, PR #279) was approved, then paused at DL1 when the camera changed (D-91 to D-93). Mark accepted the F1 Bow view on 2026-10-20 (D-94) and asked for the ship-building work on top of it.
**Release:** R2. **Milestone:** the bridge arranged to face the bow, then dressed with Blender hero assets, seen through the fixed Bow and Astern views.
**Priority:** P1 for R2. Every session starts on this deck.

**Mark's direction** (verbatim):
> 2026-10-19: "yes lets do a good deck layout sprint. I was thinking now we have fixed camera angles we can do some blender work to make them beautiful."
> 2026-10-19 (D-91): "we take advantage of the 3d blender model but for visuals, not a 3d game"; "this way we dont have to dress full on 3d environemtns and can get a sense of style and taste for each level that is in keeeping with the concept art, relying on paralax etc. to help give sense of scale"
> 2026-10-20 (D-94): "yeah this looks great. we can do more ship building assets now assuming these"

**Implements** (design repo):
- [art/ship-interior-blender-brief.md](https://github.com/sunholo-data/stapledons-design/blob/main/art/ship-interior-blender-brief.md) §2–3 (D-92: travel along the deck toward the bow, the generator mast, the bridge's bow rail facing the forward pole), §4 (Moebius / *Métal Hurlant* style), §5 (the physics contract: never paint space), §6 (the kit: `WALK_` / `SPAWN_` / `INTERACT_`). §5.3, §6 and §9 still described the old isometric camera; [stapledons-design PR #31](https://github.com/sunholo-data/stapledons-design/pull/31) updates them for the fixed views (§D7).
- [art/README.md](https://github.com/sunholo-data/stapledons-design/blob/main/art/README.md) "Review and hand-off": style frames first, stop for Mark; large binaries by sha256 in `gs://stapledons-voyage-assets/`.
- [vision/design-decisions.md](https://github.com/sunholo-data/stapledons-design/blob/main/vision/design-decisions.md): 2026-10-03 "Bridge v2" (the spire is the ship-fixed key light, so its light may be baked; nothing from outside the ship is baked) and 2026-10-19 "Travel Runs Along the Deck, Into the Screen" (D-92).
- [features/future/bubble-ship-layout.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/bubble-ship-layout.md) "Observation Deck": minimal interior, focus on the exterior, **the captain's chair as the focal point**.
- [physics/relativity-spec.md §2](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md): forward crowds and blues, sideways and aft go dark. The layout decides only what architecture frames the live sky.
- This repo: [camera-forward.md](camera-forward.md) §D0 (levels as stages), §D2 (the slide rig and occluders), §D3 (the Bow view), §D4 (the stop turn), §D9 (art and this re-plan); ledger D-90, D-91, D-92, D-93, D-94.

**Depends on:**
- **R2-CAMERA-FORWARD F1** (PR #282, D-93, accepted by Mark as D-94). This plan assumes the Bow view as built: yaw toward the bow, pitch −8°, the eye 9 m sternward of the captain and 5.5 m above the deck, a slide that never turns, Astern its mirror, and the console zoom. It changes nothing in `views.json` except moving the bridge's occluder list into it (§D3).
- **F2 and F3 of R2-CAMERA-FORWARD** run separately. One finding here belongs to F2 (the stop turn's side, §D4); it is passed to F2, not built here.
- **Blender 5.2.1 LTS** in `~/dev/blender` (headless `./blender.sh -b`). The current bridge comes from `scripts/stapledon_bridge_floor_restore_v2.py` on authoring commit `e4da963` (pins in `art/ship-demo-v1/grounded-bridge-v2/asset-pins.json`).
- **No physics change:** `sunholo/relativity` is not touched (gate 3 holds trivially). No sim, protocol or replay change.

**Estimated LOC:** game repo about 900 (the bow evaluator 300, tests 250, manifest and director wiring 120, asset-check carry-over 150, data 80). Blender generator scripts in `~/dev/blender/scripts` (about 1,000 lines of `bpy`) are authoring tools, not a game pipeline step (§D6).

## Game vision alignment

Scored with the `game-vision-designer` skill (feature-validation mode, against `vision/core-pillars.md`, the 2026-10-03 bridge decisions and D-92), 2026-10-20. **ALIGNED.**

| Pillar | Score | Rationale |
|---|---|---|
| Choices Are Final | 0 | Neutral. Stations keep their functions; no decision moves |
| The Game Doesn't Judge | 0 | Neutral |
| Time Has Emotional Weight | +1 | The journey is in frame wherever the captain works: the forward pole is on screen at every active station and in every console zoom (today it is behind the camera in all three console zooms) |
| The Ship Is Home | +2 | The bridge becomes a place with a front: the helm at the bow rail, the chair behind it, the crew's consoles flanking, all facing where the ship is going; then finished by hand to the sprites' level |
| Grounded Strangeness | +1 | The live sky is framed, never painted: the starbow sits over the helm, and the stop body 30° off the bow stays clear at every station. Risk: hero props competing with the sky; guarded by the pole-ray and body checks (§D4) and the goldens |
| We Are Not Built For This | +1 | A 1.75 m figure at a rail under a 100 m bubble, with depth from real parallax (props 2–20 m away, the sky at infinity) |
| **Net** | **+5** | **Go.** No pillar is negative |

## Problem

R2-CAMERA-FORWARD turned the camera to face the bow (D-91 to D-93). The bridge was laid out for the old ring of sector views, so it now faces the wrong way. Measured on the shipped bridge (`ship.glb` from grounded v2) with `tools/deck_bow_probe.gd`, over all 4,803 bridge walk samples (0.5 m grid), through the real Bow and Astern poses (`CameraDirector.walk_pose`, `occluders_for`, `clear_after_fades`), on 2026-10-20:

1. **The working stations face the stern.** Three of the four active stations (navigation, Voyage, Crew) put the operator on the bow side of the console or beside it, so at the console the captain faces the camera or turns sideways, away from the journey. Only the Archive terminal faces the bow.
2. **Every console zoom loses the journey.** In the navigation, Voyage and Crew zooms the forward pole is behind the camera (0 of 3 in frame). The Voyage zoom looks sideways across the desk at the dark side sky at 0.99c ([frame](https://storage.googleapis.com/stapledons-voyage-assets/refs/deck_layout_bow/current_console_voyage.png)).
3. **The spawn faces the lift.** The captain spawns at glTF (8, −4.8); the cell straight ahead is not walkable, and the first thing ahead is the lift's guardrail 5.3 m away ([frame](https://storage.googleapis.com/stapledons-voyage-assets/refs/deck_layout_bow/current_bow_rest_spawn.png)). In Astern the lift box fills the near foreground, 4.8% of the frame by ray grid ([frame](https://storage.googleapis.com/stapledons-voyage-assets/refs/deck_layout_bow/current_astern_rest_spawn.png)).
4. **All stations are stern of the mast,** in the stern-port quadrant ([plan](https://storage.googleapis.com/stapledons-voyage-assets/refs/deck_layout_bow/current_plan.png)). Working there puts the mast between the captain and the bow: 530 of 4,803 Bow samples (11%) need a fade, 383 of them for the spire.
5. **The stop body hides behind the mast** for a captain stern of it: the ray toward a body 30° off the bow hits the mast or the Archive shrine at 330 samples on the port side and 280 on the starboard side. Only **8** samples are blocked on both sides.
6. **The finish is a technical draft.** `art/ship-demo-v1/painted-bridge-v1/deployment.md`: "Final ink detail and art approval ... are pending." The play GLB is flat-painted toon; Mark ruled on 2026-10-03 that the bridge should reach the captain sprites' hand-illustrated finish.

What turned out **not** to be a layout problem (measured, so this plan leaves it alone):
- **The bow fronds never block the journey.** The Bow eye is 5.5 m above the deck and the fronds are 5.26 m tall, so the pole ray passes over them (0 pole-ray blocks). The Bow-view frond fades (79 samples) are all the **stern** fronds (6–9), crossed when the captain walks the stern rail with the camera 9 m behind.
- **After fades the pole ray is never blocked** (0 of 4,803), and the captain's head is blocked at 0 Bow and 4 Astern samples.

## Goals and non-goals

**Goals**
- G1. **Face the bow.** Every active station's operator stands stern of it, facing the bow, so the captain works toward the journey and the console zoom frames the forward sky.
- G2. **A start that reads.** The captain spawns where the Bow view frames the helm, the chair and the forward sky, and the first W press walks to the helm, not into the lift.
- G3. **Sightlines measured.** A bow evaluator (§D4) scores every candidate over every walk sample and at the spawn and stations; the shipped GLB must meet its thresholds.
- G4. **A blockout first**, exported from Blender and played by Mark in a dev build before any hero art.
- G5. **Blender hero assets dressed per view:** what the Bow and Astern views and the console zooms see gets the sprites' finish; backs and undersides stay rough.
- G6. **Physics unchanged.** The sky, the glow and the lensing stay live; `make golden` stays green with the same case count.
- G7. **Performance held.** `make bench SCENE=bridge` p99 < 16.7 ms at 2560×1440 on a quiet rig; the budgets in §D5.

**Non-goals**
- New camera views, keys or rules (R2-CAMERA-FORWARD owns them; F2/F3 run separately).
- The stop turn's side choice (handed to F2, §D4).
- The Commons and other levels. The Commons stays legacy until its own Bow pass (camera-forward OQ6); the first plan's lintel fix moves there.
- Painted parallax plates. The bridge is the top level and open to the sky, so its depth comes from the real 3D props; plates start with the roofed lower levels (§D7).
- New stations or console functions; the reserved consoles 2 and 3 stay inactive.
- Character art (the captain and crew sprites are unchanged).

## Design

### D0. The stage

The Bow view looks at the bridge the way an audience looks at a stage: from the stern, over the captain, toward the bow rail and the sky. The plan follows from that:

- **The working half is the bow half.** Stations, the chair and the spawn sit between the mast and the bow rail, so the mast is behind the camera while the captain works.
- **The stage front is the bow rail.** The forward pole sits at the horizon above it; the starbow gathers there under way.
- **The mast is a foreground pillar** that fades when the captain walks stern of it (camera-forward §D2). It is canon and does not move.
- **The stern fronds and rail are the near foreground** when the captain walks the stern deck, and they fade the same way. This is the 2.5D foreground layer.

### D1. The layout: candidate A, the bow stage (recommended)

Scored and captured against the shipped layout, an alternative (B) and a control (§Evidence). Ship metres, Blender +Z up and +Y the bow (glTF (x, −z)); bearings from the bow, positive to starboard. The data is `art/deck-layout-v2/bow_a.json`.

| Prop | Today | Candidate A |
|---|---|---|
| Navigation arc (`console_navigation_0..2`) | bearings −110/−135/−160 at 10 m (stern-port) | **at the bow rail on the centreline:** bearings +16/0/−16 at 17.5 m; the operator stands stern of the middle pod (use point (0, 15)) |
| Captain's chair | (1.9, −5.2), beside the mast, stern side | (−2.6, 12.2), behind the helm and just to port, facing the bow |
| Voyage console (`console_decision_0`) | (−8, 2), operator to starboard | bearing −34 at 14 m, turned so the operator stands stern of it, facing the bow |
| Crew console (`console_decision_1`) | (−10.5, 6.5), operator to starboard | bearing +32 at 16 m, operator stern of it, at (8.5, 12.2), about 1.9 m bow-ward of the lift's bow guardrail |
| Archive terminal | (−3.0, −2.1), at the mast's stern-port face | **unchanged** (canon: against the mast); it already faces the bow and is clear |
| Spawn | (8, 4.8), facing the lift | (0, 13): behind the helm, between the chair and the Crew console. Its `yaw` (0.47) is carried from today's manifest; in the Bow view the director turns the standing captain to face the bow anyway (camera-forward §D6) |
| Rim frond under the starbow (`rim_frond_2`) | at +10° | **+25°**, pairing with `rim_frond_3` at −25° so the two frame the starbow. (The fronds pivot at the mast axis, so the layout's `yaw_deg: -15` is a turn about the mast relative to today: bearing old − new) |
| Floor conduits | radiate to the old stations | re-aimed at the moved stations (the generator re-routes them in DL1) |
| Reserved consoles 2 and 3, benches, the other fronds | — | unchanged |
| The lift | shaft at (8, 8) | **unchanged:** the shaft is pinned by `manifest.lift_route` and the Commons |

**Why A over B.** B puts the helm 20° to port and leaves the starboard bow quadrant open as a walk from the lift to the rail. It measures as well as A (§Evidence), but the starbow sits off the helm's centre and the chair partly hides the captain at the spawn ([frame](https://storage.googleapis.com/stapledons-voyage-assets/refs/deck_layout_bow/bow_b_bow_cruise_spawn.png)). In A the starbow, the helm and the captain share the frame's centreline ([frame](https://storage.googleapis.com/stapledons-voyage-assets/refs/deck_layout_bow/bow_a_bow_cruise_spawn.png)).

**Why not just move the spawn.** The control (the shipped layout with the spawn moved 5 m to port of the lift) clears the walk ahead (16 m) but puts the mast in 30% of the Bow frame's near field, and at the first guided stop the Sun is half behind it ([frame](https://storage.googleapis.com/stapledons-voyage-assets/refs/deck_layout_bow/spawn_only_bow_stop_spawn.png)).

### D2. Layout as data, authored use points

- **`art/deck-layout-v2/<name>.json`** (schema `stapledons.deck.layout/1`, the DL0 format) holds each moved prop group's pivot and yaw and, for stations, an authored **`use_m`** operator point.
- **Authored use points replace the closest-walkable guess.** Today `ShipConsoles.setup` stands the operator at the walkable point nearest the console, which can land on any side. The Blender generator writes an `INTERACT_<station>_use` empty per station (brief §6), the export records it in `assets/ship_demo/manifest.json` (`stations.<id>.use_m`), and `ShipConsoles` reads it, falling back to today's rule for a station without one. "Faces the bow" becomes a property of the asset.
- **Node names stay stable;** `ShipConsoles.STATIONS` finds stations by name, and the console screens are rebuilt from the moved meshes.
- **The spawn moves from code into the manifest** (`spawn_captain: {position_m, yaw}`), read by `_reset_captain()` and `ShipConsoles.BRIDGE_SPAWN`. The tests and tools that assert the spawn (`test_camera_director.gd`, `test_camera_forward.gd`, `camera_forward_review.gd`) read it too. The walk regenerates, so the camera tests' sample counts (4,803 bridge samples today) change: they are derived from the walk at test time, and any count a test pins is re-derived from the new walk and stated in the commit, never re-recorded to make a failure pass. The physics tests and tools that use (8, 82, −4.8) as a **fixed observer** (`test_physics.gd`, `test_ship_star_light.gd`, `m4_ship_golden.gd`'s spots) keep it: they test observer positions, not the spawn.
- **The generator** (`~/dev/blender/scripts/stapledon_deck_layout_v2.py`, run through `./blender.sh`) reads the layout JSON and rebuilds the bridge master from the grounded v2 master: moves the named props (the conduits and fronds turn about the mast axis, so they re-aim at the moved stations), writes the `INTERACT_` and `SPAWN_` empties, and exports `ship.glb` and `walk_bridge.glb`. Every acceptance check runs on the export.
- **As built (DL1): the walk is baked by the game, not re-derived in Blender.** `tools/deck_walk_bake.gd` applies the same layout with `DeckLayout.apply` on the pinned grounded v2 deck and writes the rebuilt walk (the shipped walk clipped out of each moved footprint and re-rastered on the 0.125 m grid, merged into row runs); the generator puts it into `WALK_bridge`. So the walk that ships is exactly the walk the evaluator measured in-engine, and the rule has one implementation. The identity layout reproduces the grounded v2 GLBs byte for byte, and two runs give byte-identical exports (`art/deck-layout-v2/asset-pins.json`).

### D3. Occluders as data

F1 hard-codes the fading props in `demos/ship_geometry_demo.gd` (`OCCLUDER_NAMES := ["spire","shrine_ribs","archive_terminal","rim_frond"]`, plus the lift's boxes). Under A the list is unchanged: the spire and the shrine are canon at the mast, the Archive terminal stays at the mast, the stern fronds are the near foreground, and the lift is pinned. What changes is where it lives:

- **`views.json` gets `levels.bridge.occluders`** (node-name substrings, plus `"lift"` for the lift's boxes), checked by `CameraDirector.validate`; the demo reads it. Each future level will name its own foreground layer the same way (camera-forward §D0).
- **No prop joins the list in this sprint.** A moved prop that would need a fade at the spawn or a station fails the evaluator instead (§D4).

### D4. The bow evaluator and its thresholds

`tools/deck_layout_eval.gd` is rebuilt on the probe's measurements (`tools/deck_bow_probe.gd` is this plan's evidence tool; DL0 folds its metrics into the evaluator and its test). Headless, over every bridge walk sample and both walk views:

| ID (the failure name) | Metric | Today | A (measured) | Threshold on the exported GLB |
|---|---|---|---|---|
| `pole-ray` | Bow: pole ray blocked after fades | 0 | 0 | **0** |
| `head-bow` | Bow: captain's head blocked after fades | 0 | 1 | **≤ 2** deck-wide; **0** at the spawn and every active station |
| `head-astern` | Astern: captain's head blocked after fades | 4 | 6 | **≤ 8** deck-wide; **0** at the spawn |
| `fade-count` | Bow samples needing a fade | 530 | 487 | **≤ 530** (no worse than today) |
| `body-both` | Stop body (30° off the bow) blocked on **both** sides, deck-wide | 8 | 8 | **≤ 10** |
| `station-body` | Stop body clear on both sides at the spawn and every active station's use point | 5 of 5 | 5 of 5 | **5 of 5** |
| `spawn-open` | Spawn: open walk straight ahead | 0 m (the lift) | 3.5 m, then the helm | **≥ 3 m**, and the first thing ahead is a station |
| `near-field` | Spawn: near-field share (frame rays hitting geometry nearer than the captain, lift boxes included) | Bow 6.1%, Astern 6.2% (lift 4.8%) | Bow 2.4%, Astern 7.0% (the helm pods, the stage front) | **Bow ≤ 5%**; **Astern ≤ 10% with no lift** |
| `faces-bow` | Active stations facing the bow (console centre bow-ward of the use point) | 1 of 4 | 4 of 4 | **4 of 4** |
| `station-clear` | Active stations clear in the Bow view, no fades at the use point | 4 of 4 | 4 of 4 | **4 of 4** |
| `zoom-pole` | Forward pole in frame in the console zoom (navigation, Voyage, Crew) | 0 of 3 | 3 of 3 (x 640, y 129 at 720p) | **3 of 3** |
| `captain-px` | Captain's height in the Bow view, 720p | 80.6 px | 80.6 px | **60–82 px** (F1's band, at the sprite's 1.754 m) |

**The positive control survives the change.** Once DL1 ships the new layout, "today" is no longer the shipped GLB. The evaluator's test therefore runs its positive control on the **pinned grounded v2 export** (`ship.glb` sha256 `9da74077…`, `walk_bridge.glb` `9775c88d…`), uploaded once by DL0 to `gs://stapledons-voyage-assets/ship/<sha256>` (standing approval; the `ship/` prefix is empty today) and fetched by sha256 with `curl` (no credentials, the `tools/sky_assets.sh` pattern) into an untracked cache and loaded through the demo's `asset_dir` hook (carried from DL0). The test fails loudly if the fetch fails, never skips.

**The stop body's side (handed to F2).** Deck-wide, a body 30° off the bow is hidden by the mast on one side at about 300 samples but on both sides at only 8. If F2's stop turn puts the body on the side away from the mast, measured from where the captain stands, it is visible almost everywhere. That is camera-forward's stop-turn code, so it goes to F2 as a finding; this sprint checks only the layout side (the spawn and stations clear on both sides).

### D5. Blender hero assets, dressed per view

Once Mark approves the blockout (DL1), the props the views see are rebuilt in Blender to the sprites' finish:

- **Dress what the view sees.** The Bow view sees the stern faces of the stations and the chair, the deck, and the bow rail against the sky; Astern sees the deck toward the mast and the bow faces of the helm pods in the near foreground; the console zoom sees each station's operator face from 1.25 m. Those get the finish. Faces no view reaches stay rough.
- **The navigation arc gets an operator-side screen.** Its lens faces outward, toward the sky, so the operator, now stern of it, sees its back, and the zoom frames a plain dome ([frame](https://storage.googleapis.com/stapledons-voyage-assets/refs/deck_layout_bow/bow_a_console_navigation.png)). The hero pod keeps the sky-facing lens and adds a screen on its stern face, so the zoom frames the screen with the starbow beyond (OQ7).
- **Priority by screen time:** the navigation arc; the captain's chair; the Voyage and Crew consoles (one kit piece, two dressings); the bow rail and its two framing fronds; the deck surface of the bow half; then the Archive terminal and shrine ribs, the lift head, the benches, the stern fronds and rail, the conduits, the reserved consoles, and the spire base to deck height (the needle and spire body stay canon geometry).
- **Authoring:** generator scripts in `~/dev/blender/scripts/` under that workspace's `AGENTS.md` and `skills/blender-studio-workflow`, producing `art/deck-layout-v2/stapledon_bridge_deck_v2.blend` (packed, no external files): clean geometry, hand-painted pigments in the captain sheet's cream / ochre / violet, ink lines by the engine's outline pass.
- **Light:** the spire is the ship-fixed key light, so its light and shadow may be **baked** into a lightmap UV set (2026-10-03). Nothing from outside the ship is baked: the starlight on the deck (`ship_star_light.gd`), the wall glow and the sky stay live layers on top.
- **Style frame first** (DL2): the navigation arc and the chair, dressed and lit, captured in the Bow view at rest, at 0.99c and at the first guided stop, and in the navigation zoom. **Mark approves it before the rest is built.**
- **Export:** glTF 2.0 binary, Blender +Z → glTF +Y, metres, modifiers applied, stable node names, the `WALK_` / `SPAWN_` / `INTERACT_` collections. Materials stay opaque (`all_materials_opaque` in the pins).
- **Size strategy, up front.** `ship.glb` is 9.1 MB against a 10 MB cap, so the hero art does not go into it: the dressed props and their textures export to a **separate `bridge_props.glb`** (its own < 10 MB cap), which the demo loads beside `ship.glb`, and the props' blockout copies are removed from `ship.glb`. Textures are WebP inside the GLB (`EXT_texture_webp`, which Godot 4.7's glTF importer reads; DL0 proves it with a one-texture fixture), the lightmap atlas at 2048² at most. DL2's gate measures the style-frame export's bytes against the cap, so the finish Mark approves is known to fit.
- **Hosting:** every GLB the game loads stays under 10 MB and in git, so the build staging, CI and `tools/rig_check.sh` need nothing new. `.blend` masters go to `gs://stapledons-voyage-assets/ship/<sha256>` with pins in `art/deck-layout-v2/asset-pins.json`, fetched by `make ship-masters` for authoring only (the D-18 pattern). A runtime GLB that cannot fit in 10 MB is a budget miss reported to Mark, not a silent move to the bucket.
- **Determinism:** the generator records its script sha256 and the authoring commit; the same layout and script produce byte-identical GLBs (checked once by re-running the export); clean reimport is an AC.
- **Licences:** project art is owned by Sunholo and ships under Apache-2.0; no third-party models or textures.

**Budgets** (`art/deck-layout-v2/budgets.json`, carried from DL0), read by `make deck-assets-check`:

| Budget | Today (grounded v2) | Limit |
|---|---|---|
| Bridge + ship visual triangles | 200,399 (153 mesh instances) | ≤ 220,000 |
| Materials / images | 14 / 10 | ≤ 18 / ≤ 16 (the lightmap atlas counts) |
| Texture memory after loading the bridge (`RENDERING_INFO_TEXTURE_MEM_USED`) | 112.6 MB (DL0) | ≤ +32 MB |
| `ship.glb` bytes | 9.1 MB | < 10 MB (no growth expected: the hero props move out) |
| `bridge_props.glb` bytes | — | < 10 MB |
| `make bench SCENE=bridge` p99, quiet rig, 2560×1440 | 15.5–16.3 ms | < 16.7 ms |

The bench runs at DL2 on the style-frame props, before Mark approves the finish. Fallbacks if p99 misses, in order: halve the lightmap atlas, drop prop textures to 1K, merge the rail and frond meshes.

### D6. Python policy

The `bpy` generators are authoring tools in the Blender workspace (`~/dev/blender`, its own repo), like a DCC application, not a step of this repo's pipeline: the game loads committed GLBs and checks their pins, and `make python-guard` sees no new `*.py` here. This is the grounded v2 precedent ("No Python asset pipeline is added to the game"), which Mark confirmed for the first plan (D-90, OQ8).

### D7. Parallax and the brief

- **On the bridge, parallax is real 3D.** The bridge is the top level and open to the sky; its props sit 2–20 m from the eye and the sky is at infinity, so the slide gives true parallax for free. The brief's painted layers (layer 3, the interior panorama at about ×0.15; layer 5, foreground silhouettes at about ×1.6) are for the roofed lower levels, where a whole level cannot be modelled.
- **The design repo brief is updated** ([stapledons-design PR #31](https://github.com/sunholo-data/stapledons-design/pull/31)): §5.3 aims panoramas at the bow; §6 makes the play area a stage read from the level's fixed views (Bow and Astern at pitch −8°, the eye 9 m back and 5.5 m up) instead of the iso −14°/45°, adds "dress what the views see", `INTERACT_<station>_use` and `SPAWN_captain`; §9's manifest names views instead of `iso_*`. Stations facing the bow is marked there as proposed until Mark approves this plan; canon in §3 is unchanged.

### D8. The physics guard

- **No painted space:** no hero asset carries a sky, star, glow or lensing texture (the asset check's emissive scan: nothing emissive outside the console screens and the spire's existing emission).
- **Goldens:** `make golden` (393 `ok`, 0 failures, the same count as after F1), `make camera-forward-test` and `make camera-test` run at DL1 and DL2, **before** each pause. A golden observer that moves with the spawn is recomputed by its independent sim/CPU reference, never re-recorded from the GPU.
- **Captures opened:** every frame of DL1, DL2 and DL4 is opened before its pause, as the definition of done requires for visuals.

## Acceptance criteria

| # | Criterion | Command |
|---|---|---|
| AC1 | The bow evaluator reproduces today's numbers on the shipped GLB, and seeded bad layouts fail with the named metric | `make deck-layout-eval-test` (positive control: today's §D4 numbers; negative controls: a station turned to face the stern fails `faces-bow`; a box on the spawn's bow line fails `spawn-open`; a box at eye height on the Bow pole line fails `pole-ray`; a station whose use point is in the mast's shadow fails `station-body`) |
| AC2 | The exported bridge meets every §D4 threshold | `make deck-layout-eval` prints `deck-layout: bridge ok` and exits 0 |
| AC3 | Stations work where they moved: walk-to, reach, focus pose, every action | `make ship-console-test ship-ui-test crew-console-test crew-hold-test camera-test camera-forward-test` |
| AC4 | The manifest drives the spawn and the use points; a station without `use_m` falls back to today's rule | `make ship-console-test` (new cases in `tests/test_ship_consoles.gd`) |
| AC5 | The walk map is valid: the lift route clear, the spawn on the deck, no walk sample inside a footprint | `make ship-demo-assets-test validate-ship-demo ship-demo-lift-test` |
| AC6 | Occluders are data | `make camera-test` (`validate` rejects a `levels.bridge.occluders` that is not a list of strings; the demo's occluder group equals the data's) |
| AC7 | Asset pins match, GLBs reimport cleanly, materials opaque, §D5 budgets, no painted emission | `make deck-assets-check` (its negative controls: a wrong pin and an emissive prop fail) |
| AC8 | The masters fetch by pin; runtime GLBs stay in git under 10 MB | `make ship-masters && make deck-assets-check MASTERS=1` (the bucket is public-read: the fetch uses `curl`, no credentials; only publishing needs gcloud. The rig runs it; GitHub's fast tier does not) |
| AC9 | Physics goldens unchanged in count, 0 failures | `make golden` (393 `ok`, 0 failures) |
| AC10 | Performance | `make bench SCENE=bridge` p99 < 16.7 ms at 2560×1440 on a quiet rig (logged with host load) |
| AC11 | Review captures for each pause, opened and published | `make deck-layout-capture TAG=<tag>` writes `renders/deck_layout/<tag>/` (plan, Bow at rest / 0.99c / first stop, Astern, the console zooms, a contact sheet), published to `gs://stapledons-voyage-assets/refs/deck_layout_bow/<tag>/` with per-file URLs in the report |
| AC12 | The full suite is green; no new Python in the game | `make test` and `make python-guard` |

The finish itself ("the sprites' illustrated look") is not command-checkable: Mark judges it at the DL2 pause, and the evaluator scores only that the pause happened with published, opened frames.

## Sub-milestones and estimates

| ID | What | LOC (game) | Depends on | Pause |
|---|---|---|---|---|
| DL0 | Carry over the DL0 tools (asset check, budgets, `DeckLayout`); the bow evaluator (§D4) and its test; occluders as data (§D3); the capture target | ~450 | — | — |
| DL1 | Bridge blockout in Blender: layout A (or Mark's pick), authored use points and spawn in the manifest, conduits re-routed, walk regenerated; a dev build | ~250 + generator | DL0 | **Mark plays the blockout** |
| DL2 | Style frame: the navigation arc (with its operator screen) and the chair, dressed and lit; bench | ~60 + generator | DL1 | **Mark approves the finish** |
| DL3 | The rest of the hero list (§D5); pins and masters in the bucket | ~80 + generator | DL2 | — |
| DL4 | Integration and landing: goldens, bench, captures, a dev build, report, independent evaluation | ~60 (docs) | DL3 | — |

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Hero props push p99 over 16.7 ms | §D5 budgets checked by `deck-assets-check` from DL0; instancing; the bench at DL2 (before the style-frame approval), DL3 and DL4; the fallbacks in order |
| Props at the bow rail compete with the starbow | The pole ray must stay clear at every sample (0 blocked); the pods are 2.1 m tall and the Bow eye 5.5 m up, so they sit below the horizon; style frames at 0.99c before approval |
| The in-engine search and the Blender export disagree | Every AC runs on the export; DL1 starts with a one-prop round trip through the generator before the full move |
| Moving the spawn changes golden observers | Fixed observers keep (8, 82, −4.8); anything that moves is recomputed by its independent reference; AC9 keeps the count |
| Baked spire light looks wrong at 0.99c | Only the ship-fixed spire light is baked; live starlight and glow stay on top; the style frame includes 0.99c |
| The art does not reach the sprites' finish | DL2 is a hard stop; Mark can redirect before the rest is built |
| Station moves break dev.34 muscle memory | Tab "Walk to" and the HUD prompts are unchanged; the dev build's notes say the bridge was rearranged |
| F2 changes the stop turn at the same time | This sprint checks only the layout side of the stop (clear on both sides at the spawn and stations), which holds whichever side F2 picks |
| `ship.glb` also carries the Commons assembly (the unified export) | The generator changes only bridge-level objects; the Commons gates (`make ship-commons-test ship-commons-assets-test ship-commons-arcade-test`) run at DL1 and DL3 |
| F1 is not merged when DL0 starts | DL0 branches from `feat/camera-forward` with main merged (as this plan did) and rebases when #282 lands |

## Open questions for Mark (with recommendations)

| # | Question | Recommendation |
|---|---|---|
| OQ1 | Which layout goes to Blender: A (the bow stage, the helm on the centreline), B (the helm 20° to port, an open starboard walk from the lift to the rail), or changes to either? | **A.** It measures as well as B, and the starbow, the helm and the captain share the frame's centre |
| OQ2 | The spawn behind the helm on the centreline (A), so the game opens on the captain facing the starbow over the navigation arc, and the first W press walks to the helm? | **Yes** |
| OQ3 | What fades: keep F1's list (the mast and shrine, the Archive terminal at the mast, the stern fronds, the lift) as the bridge's foreground layer, now as data, and add nothing else? | **Yes.** All four active stations measure clear with no fades; fades happen only when walking stern of the mast or along the stern rail |
| OQ4 | The captain at about 81 px in the Bow view (the top of the 60–80 band, at the sprite's real 1.754 m): keep it, with the band widened to 60–82? | **Keep.** Props are built to the sprite's scale; if the finished props make the captain read too large, that is a view tweak (`back_m`) after DL2, not a layout change |
| OQ5 | Who models: an agent writing `bpy` generators in `~/dev/blender` (as for every ship asset so far), you by hand, or both? | **Agent-generated; you may tweak masters**, and hand edits are folded back into the generator |
| OQ6 | The finish: the sprites' illustrated look (the 2026-10-03 ruling), with the spire's light baked into lightmaps? | **Yes to both** |
| OQ7 | The navigation arc: add an operator-side screen on its stern face (the zoom frames the screen with the starbow beyond), keeping the sky-facing lens? | **Yes** |
| OQ8 | Scope: the bridge only, with the Commons getting its own Bow pass later (the lintel fix moves there)? | **Bridge only** |

**Resolved (D-95, 2026-10-20): every recommendation.** OQ1 A; OQ2 yes; OQ3 yes (F1's list as data, nothing added); OQ4 keep, band 60–82; OQ5 agent-generated, Mark may tweak masters; OQ6 yes to both; OQ7 yes; OQ8 bridge only.

## Evidence

Measured and captured 2026-10-20 in a fresh clone on `design/deck-layout-bow` (base `feat/camera-forward` 0a787245 with `origin/main` 8982bd78 merged) with `tools/deck_bow_probe.gd`: headless metrics over every bridge walk sample, then GPU captures at 1280×720 (a separate orthographic camera for the plans, the real director for the walk views, the game's console mode for the zooms). Candidates are applied in-engine with `DeckLayout.apply`, with the moved props' colliders synced before measuring. Every frame below was opened.

**Contact sheet** (rows: today, A, B, the spawn-only control; columns: plan, Bow at rest, Bow at 0.99c, Bow at the first guided stop, Astern at rest, navigation zoom): https://storage.googleapis.com/stapledons-voyage-assets/refs/deck_layout_bow/contact_sheet.png. All numbers: https://storage.googleapis.com/stapledons-voyage-assets/refs/deck_layout_bow/probe.json.

| Layout | Bow fades | Pole blocked | Head blocked (Bow / Astern) | Body blocked both sides | Spawn open ahead | Near field (Bow / Astern) | Stations facing the bow | Pole in console zoom |
|---|---|---|---|---|---|---|---|---|
| Today | 530 | 0 | 0 / 4 | 8 | 0 m (lift) | 6.1% / 6.2% | 1 / 4 | 0 / 3 |
| **A** | 487 | 0 | 1 / 6 | 8 | 3.5 m (helm) | 2.4% / 7.0% | **4 / 4** | **3 / 3** |
| B | 495 | 0 | 1 / 5 | 6 | 3.75 m (helm) | 2.4% / 5.3% | 4 / 4 | 3 / 3 |
| Spawn only | 530 | 0 | 0 / 4 | 8 | 16 m | **30.4%** / 3.1% | 1 / 4 | 0 / 3 |

| Frame | What it shows |
|---|---|
| [Today, plan](https://storage.googleapis.com/stapledons-voyage-assets/refs/deck_layout_bow/current_plan.png) | The bow is up. Every station is in the stern-port quadrant; the lift is bow-starboard; the bow half is empty deck |
| [Today, Bow at the spawn](https://storage.googleapis.com/stapledons-voyage-assets/refs/deck_layout_bow/current_bow_rest_spawn.png) | The captain facing the lift box; the mast's flank at the left |
| [Today, at the helm](https://storage.googleapis.com/stapledons-voyage-assets/refs/deck_layout_bow/current_bow_rest_helm.png) | The navigation pods around the captain, the mast and chair beyond; the captain faces the pods, away from the bow |
| [Today, Voyage zoom](https://storage.googleapis.com/stapledons-voyage-assets/refs/deck_layout_bow/current_console_voyage.png) | Looking sideways across the desk at the dark side sky (0.99c) |
| [A, plan](https://storage.googleapis.com/stapledons-voyage-assets/refs/deck_layout_bow/bow_a_plan.png) | The helm arc at the bow rail, the chair, the Voyage and Crew consoles flanking; yellow marks the use points, green the spawn |
| [A, Bow at rest](https://storage.googleapis.com/stapledons-voyage-assets/refs/deck_layout_bow/bow_a_bow_rest_spawn.png) | The captain on the centreline behind the helm, the chair to the left, the consoles flanking, two fronds framing the bow; the lift's corner at the lower right |
| [A, Bow at 0.99c](https://storage.googleapis.com/stapledons-voyage-assets/refs/deck_layout_bow/bow_a_bow_cruise_spawn.png) | The starbow centred over the navigation arc |
| [A, first guided stop](https://storage.googleapis.com/stapledons-voyage-assets/refs/deck_layout_bow/bow_a_bow_stop_spawn.png) | The Sun 30° to port over the rail, clear of every prop |
| [A, Astern](https://storage.googleapis.com/stapledons-voyage-assets/refs/deck_layout_bow/bow_a_astern_rest_spawn.png) | Looking back at the mast over the helm pods (the stage front, nearest the camera); no lift in the foreground |
| [A, navigation zoom](https://storage.googleapis.com/stapledons-voyage-assets/refs/deck_layout_bow/bow_a_console_navigation.png) | The starbow over the rail beyond the pod; the pod's back fills the lower half (OQ7) |
| [A, Voyage zoom](https://storage.googleapis.com/stapledons-voyage-assets/refs/deck_layout_bow/bow_a_console_voyage.png) | The desk with the starbow and the helm beyond (the in-engine search does not move the desk's in-game screen panel; the game rebuilds it from the export) |
| [B, Bow at 0.99c](https://storage.googleapis.com/stapledons-voyage-assets/refs/deck_layout_bow/bow_b_bow_cruise_spawn.png) | The helm offset to port; the chair partly hides the captain |
| [Spawn only, Bow at rest](https://storage.googleapis.com/stapledons-voyage-assets/refs/deck_layout_bow/spawn_only_bow_rest_spawn.png) | The mast fills the left 40% of the frame |
| [Spawn only, first stop](https://storage.googleapis.com/stapledons-voyage-assets/refs/deck_layout_bow/spawn_only_bow_stop_spawn.png) | The Sun half behind the mast |

## Deliverables

- `tools/deck_layout_eval.gd` (the bow evaluator), `tools/deck_layout_capture.gd`, `tools/deck_assets_check.gd`, `tests/test_deck_layout_eval.gd`, `mk/deck-layout.mk` (`deck-layout-eval`, `deck-layout-eval-test`, `deck-layout-capture`, `deck-assets-check`, `ship-masters`); `tools/deck_bow_probe.gd` and `tools/deck_layout.gd` (this plan's evidence tools, kept).
- `art/deck-layout-v2/`: the layouts (`bow_a.json`, `bow_b.json`, `spawn_only.json`), `budgets.json`, `asset-pins.json`, the master `.blend` pin, validation logs, and a README with the generator's commit and sha.
- Updated `assets/ship_demo/` GLBs and manifest (spawn, use points); `data/camera/views.json` (`levels.bridge.occluders`).
- `design_docs/implemented/r2/deck-layout-report.md`: before/after numbers, contact sheets, bench, goldens.
