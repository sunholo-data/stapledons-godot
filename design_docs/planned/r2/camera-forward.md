# R2-CAMERA-FORWARD: travel along the deck, and a fixed bow view that slides with the captain

**Status:** Approved 2026-10-19 by Mark, attended ("yep looks great approved"), with every recommendation: ledger D-93. In progress (F1). Sprint plan: [camera-forward-sprint.md](camera-forward-sprint.md).
- **Independent plan reviews (Sonnet):** the D-91 draft scored 71, then 86. The D-92 revision was reviewed in rounds 3–5: 71, 76, 79, then the round-5 blocker was folded in (`.ailang/state/evaluations/eval_R2-CAMERA-FORWARD_plan_round_{3,4,5}.json`).

**Release:** R2. **Milestone:** the player camera for the 3D ship, and the ship basis it needs (ledger D-91, D-92). It amends R2-CAMERA ([implemented/r2/camera-fixed-views.md](../../implemented/r2/camera-fixed-views.md), D-83).

**Priority:** P1 for R2. Every session runs through this camera. The paused deck-layout sprint (D-90, `feat/deck-layout` 7863c831) is re-planned on top of it.

**Mark's direction** (attended, 2026-10-19, verbatim):
> we misunderstood what a fixed camera meant. as I walk around we can still see the whole ship, and I get a confusing new perspective where my buttons now dont travel to the right direction. I also now miss the good views of the onward forward facing jounrey and as I walk around lose the view of the planet/sun etc we are visiting. the fixed camera is meant to make it simpler by having fixed perspective and the player walks around in that.

He then chose "Slide, never turn" (D-91), and added:
> we can have a few fixed views possible, but yeah at least one forward looking, one planet facing (same as navigation around ship?) and maybe when we sue consoles it zooms in - we take advantage of the 3d blender model but for visuals, not a 3d game - does that make sense? we did consider isometric at one point but this was early designs, but its really just to give the sense of scale

> we are just on the bridge for now, but as we go down through the levels we will have similar fixed caemra views as we explore them - more like a 2d/2.5d platform game? able to explore the layers

> this way we dont have to dress full on 3d environemtns and can get a sense of style and taste for each level that is in keeeping with the concept art, relying on paralax etc. to help give sense of scale

The first draft of this doc measured that a forward pole straight overhead cannot share a frame with the deck. Mark then changed the ship (D-92):
> shall we chaneg it so the direction of travel is the bubble moving sideways? just for asethetic reasons? may make it all simpler?

and chose **"Into the screen"**.

**What this doc takes from that:**
- **The direction of travel lies in the deck plane, toward the bow** (D-92). The decks stay level under the generator's comfort 1 g (D-11, HB-6). The spire is the generator mast, and the levels stack vertically along it.
- **The 3D ship is a stage, not a free 3D game.** It is a diorama that gives scale. Each level has a few authored, fixed views, and the camera slides with the captain without ever turning.
- **The bridge's default view looks over the captain toward the bow.** The starbow, the destination and the forward glow sit near the horizon above the deck, so the journey and the deck share one frame.
  - At a stop, the ship turns so the body is in that frame too (Mark's "planet facing").
  - Using a console zooms in.
- **Moving between levels** cuts to that level's views, so the levels read as stacked layers (2.5D).
- **Only what a view sees gets dressed.** Depth comes from parallax. The sky layer is always the live SR/GR render.

**Implements** (design repo):
- **D-92 and its doc amendments:** [stapledons-design#30](https://github.com/sunholo-data/stapledons-design/pull/30) amends:
  - `art/ship-interior-blender-brief.md` §2–3, `art/ship-exterior-blender-brief.md` §2 and `art/README.md`;
  - `vision/design-decisions.md`: a new D-92 entry, with D-14 and D-6 marked superseded in part;
  - the lore entries `archive/one-g.md` and `archive/starbow.md`.
- **[vision/design-decisions.md](https://github.com/sunholo-data/stapledons-design/blob/main/vision/design-decisions.md) D-6** ("Isometric Three-Layer View"):
  - kept for its purpose: room scale, the captain among the crew, parallax layers;
  - superseded in its projection, and in "the bridge's dome is the forward pole".
- **[features/future/sr-view-directions.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/sr-view-directions.md):** forward, side and aft show different physics (§D5).
- **[features/phase2-core-views/multi-level-ship-visualization.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase2-core-views/multi-level-ship-visualization.md)** and **[ship-exploration.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase2-core-views/ship-exploration.md):** levels as layers (§D7).
- **[physics/relativity-spec.md §2](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md)** (aberration and Doppler depend on the angle from the velocity only) and **[physics/higgs-bubble.md](https://github.com/sunholo-data/stapledons-design/blob/main/physics/higgs-bubble.md)** (HB-6, the generator's 1 g; the forward glow).
- **Ledger:** D-6, D-11, D-14 (amended by D-92), D-52 A, D-83, D-90, D-91, D-92.

**Depends on:**
- **No new physics formula.** `sunholo/relativity` 0.12.0 works in a frame with +z along the velocity (for example, `_smoke.ail:290`, `pole = {0, 0, 1}`). It never refers to the ship's structure, so **the package-first rule does not apply.**
- **The sim and the protocol are untouched** (§D1). There is no protocol minor version, the digest is unchanged, and the replay goldens are unchanged.
- **Design repo PR #30** must merge before F1a lands its lore re-import (§D1.5).

**Estimated LOC:** about 1,600 in all.
- About 750 of product code: the basis change at about 25 call sites, the slide rig and the views.
- About 700 of tests, tools, re-baselined goldens and caller migration.
- The sprint plan schedules 6 days.

## Game vision alignment

Scored with the `game-vision-designer` skill in feature-validation mode, against `vision/core-pillars.md`, D-6, D-91 and D-92, on 2026-10-19. **ALIGNED.**

| Pillar | Score | Rationale |
|---|---|---|
| Choices Are Final | 0 | The camera takes no decision. The no-twitch tests (NT1–NT5) stay |
| The Game Doesn't Judge | 0 | Neutral |
| Time Has Emotional Weight | +2 | The journey ahead stays on screen while you walk: the starbow, the destination and the forward glow over the bow rail. The captain's ageing figure is in every walking view |
| The Ship Is Home | +2 | A stable stage: the deck no longer spins under the player. Levels become layers to explore, and every level's bow edge sees the forward sky |
| Grounded Strangeness | +2 | Every sky is the physics render through the same pose. The sky crowds ahead and goes dark astern, and the Astern view (§D5) shows that directly |
| We Are Not Built For This | +1 | Scale comes from parallax and framing: a small figure on a deck under a vast forward sky |
| **Net** | **+7** | **Go.** No pillar is negative |

## Problem

**1. The camera turns as the captain walks (D-91).**

I measured this with `tools/camera_walk_capture.gd` (this PR) on `origin/main` 5118cc2: a walk of 8 angles × radii 10 m and 17 m on the bridge.

| Pass | Samples | Yaw spread | Forward pole in frame | Captain's head in frame |
|---|---|---|---|---|
| At rest, Z2 (sector booms) | 16 | **180°** | 0 | 16 |
| Under way, Sky forward (`yaw_rule: tangent`) | 16 | **180°** | 16 (y = 82 px) | 16 |

- **Evidence:** https://storage.googleapis.com/stapledons-voyage-assets/refs/camera_forward/before/contact_sheet.png. I opened the sheet, `rest_r10_0` and `under_way_r10_3` individually.
- **Why it turns:** Z2's yaw is `sector_centre + turn_deg[ring]`, and Sky forward's is `atan2(foot) + offset`.
- **Why the keys flip:** WASD is screen-relative (`walk_yaw()`), so it turns with the screen.

**2. Under D-14, one frame cannot hold both the deck and the journey.**
- **The pole was straight up.** At the fixed 78° vertical FOV it is in frame only at a pitch of 51° or more, and then 0% of the frame is below the horizon.
- **The starbow sits close to the pole.** Rest-frame 90° stars appear 25.8°, 8.1° and 2.6° from the pole at 0.9c, 0.99c and 0.999c (relativity-spec §2), so the starbow too is only in frame with the pole.
- This measurement led to D-92.

## Goals and non-goals

**Goals**
- **G1. The ship basis change (D-92).** The physics frame keeps +Z along the travel. Its mapping onto the ship's structure changes from "travel = up" to "travel = the bow", in one named place. There is no new formula and no sim change.
- **G2. A fixed Bow view.** Its yaw and pitch stay fixed while walking, and it slides with the captain.
  - The starbow, the destination and the forward glow are in frame.
  - The deck fills the lower part.
  - The captain is about 70 px tall.
- **G3. Constant controls.** W walks toward the bow (up-screen) in the default view. The mapping changes only on a deliberate view switch, once, at the end of the ease.
- **G4. A few authored views:**
  - Bow (the default);
  - Astern (OQ3);
  - Console: a zoom onto the screen that returns to the previous view;
  - stops and Sgr A* are framed by the Bow view through the ship's attitude (§D4).
- **G5. Level-keyed view data** (`views.json` v2). The bridge is authored in this sprint; the Commons keeps its views until its own pass.
- **G6. Physics gate 2 holds.** Goldens and forward-pole tests re-baseline one for one, and the reference renders are opened.

**Non-goals**
- Dressing or re-arranging the deck. That is the deck-layout re-plan (§D9), and its stations will face the bow.
- An inset second-direction window, new levels, stairs, an exterior shot, or an orthographic projection.
- Any sim or protocol change.

## Design

### D0. The model: a stage, levels as layers, travel into the screen

- **Levels stack vertically along the generator mast.** The travel axis is horizontal, toward each level's bow edge.
- **Each level has a few authored views,** each with a fixed direction and framing. While the captain walks, the camera's only motion is a slide parallel to itself.
- **Switching views is deliberate:** a key, a console or a cue. A switch eases once, or cuts under reduced motion (R2-CAMERA D6).
- **Inside a level you walk a stage,** seen from behind and above, facing the bow. Going down a level cuts to that level's stage. This is the 2.5D reading.

### D1. The basis change (D-92): one named mapping, no new formula

**Two frames are in use today, and they share one mapping:**
- **Structure:** Blender and `cam_*.json`. ShipFrame's comment says "+Z = direction of travel (up)". The Commons walk targets, the benchmark eyes, the courtyard data and the Commons validation are authored in it. glTF = `(s.x, s.z, −s.y)`.
- **Kinematic:** the sky, the glow, the dust and the observer, with +Z along the velocity (`ShipFrame.ship_basis(heading)`, `sunholo/relativity`, the sim). `ShipCamera.ship_vector(gltf) = [x, −z, y]`, and its inverses are written inline.

**D-92 splits them with a fixed proper rotation R.** Travel becomes the structure's bow (Blender +Y), and the mast stays up:
- `kinematic = R · structure`, where `R(s) = (−s.x, s.z, s.y)`. So K+Z = S+Y (the bow), K+Y = S+Z (the mast), and K+X = −S+X.
- R has det +1. A test asserts that R is orthonormal with det 1, maps the bow to +Z and the mast to +Y, and that the two composite maps agree with these literals.
- Hence **`ship_vector(gltf) = [−x, y, −z]`**: glTF −Z (Godot's forward) is the bow.

**Measured:** this PR's prototype (`ShipCamera.travel_axis = "bow"`, measurement only) puts a camera looking at glTF −Z at a pitch of −8° at 8.0° from the velocity (`view_velocity_angle`). The rendered sky shows the starbow ahead, over the bow rail (§Evidence).

**D1.1 Kinematic sites move to the new map.** Each goes through one named function (`ShipCamera.ship_vector` / `gltf_from_ship`), with no inline literals:
- **ShipCamera:** `ship_vector`, `to_sky_direction` and `sync_sky`. That covers `cam`, and the glow and dust `cam_ship`, which today are written inline as `(x, −z, y)`.
- **Demo code:** `ship_geometry_demo.hole_direction` (the inverse, line 584) and `ship_star_light.gd:89`.
- **`CameraDirector.aim_dir`:** the pole changes from `Vector3.UP` to the bow, `Vector3.FORWARD`.
- **Tests and tools:**
  - `tests/test_physics.gd:1705` (`_ship_cam`);
  - `tests/test_ship_demo.gd:31` (the observer eye);
  - `tools/constellation_golden.gd:59, 239`;
  - `tools/m4_ship_golden.gd:484–490` (the glow eye and directions);
  - `tools/m4_ship_golden.gd:395–407` (`_unit_sample`, G-M4-S4: a hand-written ship-to-glTF yaw/pitch, `atan2(dz, …)`, `atan2(−dy, dx)`, which the grep gate cannot see) and G-CAM-2's aim directions built about glTF +Y as the pole. Both are rewritten through `gltf_from_ship`, and AC-B4's re-posed families cover them;
  - `tools/ship_star_identification_capture.gd:149`;
  - the capture metadata `eye_m` (`m4_ship_capture`, `ship_demo_journey_capture`, `ship_demo_live_capture`), through `ship_vector`.

**D1.2 Structure sites keep the old map, now named `ShipFrame.gltf_from_structure`:**
- `ship_commons.gd:37` and `ship_demo_benchmark.gd:48–49`;
- `tests/test_ship_commons.gd:27`, `tests/test_ship_commons_assets.gd:31` and `tests/test_ship_demo_consolidation.gd:25` (a measured cam JSON eye against the camera position);
- `tools/validate_ship_commons.gd:56` and `tools/ship_commons_capture.gd:44`.

A grep gate (AC-B1) fails on any inline `[2], −x[1]` or `x, −z, y` pattern outside these two functions.

**D1.3 Shaders need no edit.**
- The glow and dust overlays take their ship axes from `InteriorSky.orient_basis` (world), so they follow automatically.
- Their uniform defaults (`ship_y = (0, 1, 0)`) are overwritten at runtime.
- `tools/glow_planet_golden.gd` already sets a bow-style frame (`ship_z = (0, 0, −1)`) in its own harness.
- `interior_golden.gd` works in a pure ship frame and is unchanged.

**D1.4 The sim and the protocol are untouched.**
- Evidence: no `sim/*.ail` file encodes an interior or structure axis. `gr.hole_dir` and `dir_local` are galactic (`sim/protocol.ail:443–449`), and the protocol minor lives in `sim/protocol.ail`, so an untouched `sim/` means an unchanged minor.
- Every sim quantity is in galactic or kinematic coordinates: the heading, velocity, glow pole emittance, ISM and dust impacts, and `gr.hole_dir`. The host maps each one into the interior.
- AC-B5 checks that `git diff origin/main -- sim/` is empty, that `make parity replay strict` is green, and that the protocol minor version is unchanged.

**D1.5 Attitude, HUD copy and lore.**
- **The stop turn** (`Attitude.side_basis`).
  - Today it tilts the travel axis 15° toward the body, which puts the body 75° off the travel, along kinematic +X. Under D-92 that is horizontal and 90° off the bow, so it falls outside the Bow frame.
  - **The change:** a tilt of 60°. The body then sits 30° off the bow, in the deck plane. That is in frame: x = 640 ± 256 px at 720p (the half-horizontal FOV is 55.2°), at the horizon.
  - This is attitude only. Stationary turns precede commitment, and nothing in the sim changes.
  - It makes the Bow view the "planet facing" view at stops (§D4).
- **The tour-turn camera arguments:** `_begin_tour_turn(…, 89.5, "departure")` and `(…, 15., "stop")` (ship_geometry_demo.gd:969, 977) pose only the developer free camera's first-person turn (`_tour_view_to`). They become tilt 0° toward the bow (yaw 270°, ShipCamera's convention) for a departure, and the body's bearing at tilt 0° for a stop. Tests: `test_tour_attitude.gd`, `test_ship_attitude.gd` (the side_basis tilt), `test_free_nav_stop.gd`.
- **Player-facing copy that says up is the travel:** `ui/journey_hud.gd:8` `BRAKE_NOTICE` ("Braking. Up is still the way we are travelling.") becomes "Braking. The bow is still the way we are travelling.". It is asserted in `tests/test_no_twitch.gd:342, 361` and `tests/test_transit.gd:85`, which move in the same commit. The frame comments in `interior/ship_frame.gd:4–8` and `interior/area_bundle.gd:49` are updated too.
- **HUD copy:** "Travel is UP; floors correctly block the aft sky" and "SKY ONLY DIAGNOSTIC — … travel is UP, aft is DOWN" are reworded. The `look_direction` tilt table (forward 89.5°) is re-posed. `make display-audit` re-runs, and the PR lists any changed caption pin.
- **Lore:** `data/lore/archive/one-g.md` ("'up' is toward the direction of travel") and `starbow.md` ("the stars have gathered overhead") are vendored from the design repo.
  - They are re-imported (`make lore-import D=../stapledons-design`) after design PR #30 merges.
  - The gate is `make lore-import CHECK=1`.

**D1.6 The painted-plate interior (`main.gd --interior`, the M4.2 area bundles) stays in the pre-D-92 basis, as a labelled legacy reference.**
- **What it does today:**
  - `interior/area_bundle.gd` reads Blender's `cam_*.json`, whose frame string `CAMERA_FRAME` (line 49) reads "ship: +Z = direction of travel (up)".
  - `InteriorSky.orient_basis` (interior_sky.gd:162–167) and `ShipFrame.sky_camera` (ship_frame.gd:66) multiply that camera by the ship basis directly. `sky_camera` is called from `tests/test_physics.gd:1066–1090` and `interior/interior_smoke.gd:91`.
- **Who sees it:** nobody in play. It is the D-6 painted reference, reached only through developer launches (`--interior`, `--interior-capture`, `--m4-smoke`, `make interior-test`). Players reach the 3D ship from the title screen (`main.gd:_start_current_ship`).
- **Why it can't take R yet:** its bridge plate camera looks up at the old dome pole (`forward` ≈ (−0.27, 0.14, 0.95)). Applying R would turn that plate perpendicular to the direction of travel. G-M4-3 ("a star dead ahead lands on the projection of ship +Z") would then fall off-frame, so the plate would need re-rendering in Blender. That is art work outside this sprint.
- **Decision:** the bundle path explicitly keeps the old identity mapping.
  - `CAMERA_FRAME` and the bundle JSONs are unchanged, so `test_area_bundle` is unchanged.
  - A comment in `area_bundle.gd` and `interior_sky.gd`, plus a `const BUNDLE_BASIS := "legacy-up (pre-D-92)"`, records that a bundle camera is in the legacy frame.
  - The `--interior` HUD gains one line: "painted reference (pre-D-92 orientation)".
  - `interior_golden` (G-M4-1..6), m4-smoke, `make interior-test` and `test_physics.gd:1066–1090` stay **byte-identical**. AC-B4's baseline includes them, and they are not among the re-posed families.
- **The two paths never mix.** `InteriorSky.cam` is written either by `ShipCamera.sync_sky` (kinematic, D-92) or by the bundle `Interior` (legacy), never both in one session. (`tests/test_physics.gd:1705` `_ship_cam` builds a bundle-format dictionary only to call `AreaBundle.unproject`, which is frame-agnostic projection maths, so it stays on the kinematic map.)
- **Follow-up (not this sprint):** re-render or retire the painted plates under D-92 (OQ8).

### D2. The slide rig and occluders (all walking views)

- **The rig:** `eye = foot − flat(yaw) × back_m + up × rise_m`. The basis is `basis_of(yaw, pitch)` and is never re-aimed.
- **Dead zone:** 24% × 20% of the frame, as data.
- **Follow:** critically damped (`FOLLOW_S`, 0.25 s), within R2-CAMERA's 36 m/s² cap.
- **Bounds:** the eye stays within 95 m (the clamp slides; it never rotates) and at least 0.3 m above its deck.
- **Occluders (measured, §D3):**
  - **Members:** the `camera_occluder` group holds the named spire meshes (`Spire*`, including `spire_needle_col`) and the lift's visible boxes.
  - **A member fades** (alpha 0.25 over 0.2 s of `advance(dt)`; fallback: hidden) while it does any of these:
    - (a) crosses the eye-to-captain segment;
    - (b) crosses the eye-to-pole ray, so it never hides the journey;
    - (c) contains the eye.
  - **"Clear after fades"** means no hit on a node outside the group.
- **Physics:** a fade changes no sky uniform and no sim input (asserted). `camera-views-capture` adds a forced-fade frame, which I open by eye to check the sort order against the sky.

### D3. Bow, the default view (merges D-91's Forward and Deck)

**Measured candidates.**
- **How:** `tools/camera_walk_capture.gd --bow` with the D-92 prototype basis, 16 bridge walk samples each, at rest and at 0.99c cruise, at 1280×720.
- **The pole, the destination and the forward glow** are tested along the travel direction (glTF −Z).
- **The starbow's upper edge** is the rest-frame 90° ring: 25.8° above the pole at 0.9c, 8.1° at 0.99c.
- **"In frame"** means inside a 40 px margin.

| Candidate (pitch, back, rise) | Pole and destination in frame | Pole ray clear (no fades) | Starbow 0.9c / 0.99c in frame | Captain | Horizon y | Frame below the horizon (deck) |
|---|---|---|---|---|---|---|
| **A** (−8°, 9.0 m, 5.5 m) | 16/16 | 14/16 | 16/16 / 16/16 | 73 px | 298 | 59% |
| B (−12°, 9.0 m, 6.5 m) | 16/16 | 14/16 | 0/16 / 16/16 | 70 px | 266 | 63% |
| C (−16°, 10.0 m, 8.5 m) | 16/16 | 14/16 | 0/16 / 16/16 | 59 px | 233 | 68% |

The numbers are the same at rest and at 0.99c, because the framing is geometric.

**Two problems turned up in the walk, the same for every candidate:**
- **The spire needle blocks the pole** (`spire_needle_col`) at 2/16 samples, where the captain stands sternward of the spire: foot (0, 82, 10) and (0, 82, 17).
- **The eye is inside the spire** at 1/16, where the captain stands 10 m bow-ward of it. The eye is 1 m from the axis and the frame is solid dark (opened: `bow_*_r10_6`).

Both are cleared by the occluder rule (§D2 b, c). F1b's AC-V3 must measure 16/16 after fades.

**Recommendation: A.** It is the only candidate with the 0.9c starbow in frame. The captain is 73 px (the R2-CAMERA band is 60–80), and the deck fills 59% of the frame. I opened `bow_cruise_A_r17_6`: the starbow sits over the bow rail with the captain on the deck below.

**The view:**
- a fixed yaw toward the bow (glTF −Z), pitch −8°;
- the eye 9 m sternward of the captain's feet and 5.5 m above the deck;
- it slides and never turns.

**The forward glow** lies on the bubble wall in the pole's direction, so "pole ray clear" covers it too. At 0.99c it is faint (HB glow), as it is today.

**It is the default everywhere on the bridge,** at rest and under way.

### D4. Stops and Sgr A*: the Bow view does "planet facing"

- **At a guided stop,** the ship turns (§D1.5) so the body sits 30° off the bow, at the horizon. The Bow view frames it, so Mark's "planet facing" needs no separate view and no camera turn. F2 measures it: AC-V6 requires the body in frame at 16/16 walk samples at the first guided stop.
- **At Sgr A*:** the golden harness assumes the nose is on the hole (`m4_ship_golden.gd:248`), but the live visit has no attitude code (`black_hole_visit.gd`), and the heading comes from the sim. So: **while hovering** (at rest relative to the hole), the same render-only attitude turn as at a stop brings the hole 30° off the bow. **On moving legs** (approach, orbit) the nose stays on the heading (D-14’s rule for moving legs), and F2 measures whether the hole is in frame. If it is not, the Target key (OQ2) is the follow-up. AC-V6 covers the hover. 
- **"Same as navigation around ship?"** I read this as the guided stop.
  - Today the stop turns the ship side-on and cues "Sky to the side" (`_begin_tour_turn(Attitude.side_basis(…))`, `director.sky("sky_side")`). Under D-92 the same turn, tilted further, puts the body in the default view.
  - The Navigation station's chart (`ui/galaxy_map.gd`) is unchanged.
  - See OQ2.
- **There is no Target view this sprint.** `sky_side` and `sky_hole` stay as tool and golden poses only. If a body can still leave the frame (in free navigation), a Target key is a follow-up (OQ2).

### D5. Keys, cues, astern and side

| Key (pad) | Today | Proposed |
|---|---|---|
| 7 (D-pad up) | Sky ahead | **Bow** (the default) |
| 9 (D-pad down) | Sky astern | **Astern:** the same rig, yaw + 180°, looking aft over the stern rail |
| 8 (D-pad right) | Sky to the side | Reserved (OQ3); the developer pose `sky_side` |
| R (R3) | the default view | Bow |
| +/− (RB/LB), wheel, pinch | Z1/Z2/Z3 | Developer presets only (OQ4) |
| E at a console | console focus | Console, unchanged; Esc or walking away returns to the previous view |

- **Astern (OQ3):**
  - Under D-14, straight aft looked through the floor. Under D-92 it is horizontal, over the stern rail.
  - At speed it shows the aft sky dark and redshifted (relativity-spec §2). sr-view-directions treats that as the physics a forward view cannot show.
  - **Recommendation:** keep it.
  - In Astern, W walks up-screen, which is toward the stern. The mapping changes once, at the end of the ease.
- **Side (OQ3):** **recommendation:** no player view this sprint. The sideways darkening at speed shows at the left and right edges of the Bow frame (the half-horizontal FOV is 55°), and the stops' bodies are already in the Bow frame.
- **Cues:** departure, cruise, braking, a stop and Sgr A* all keep, or return to, Bow. A cue never turns the camera; the ship's attitude turn rotates only the sky.
- **Switches:**
  - Ease at ≤ 90°/s with a 1.2 s floor; under reduced motion, a 0.15 s fade cut.
  - A held key keeps the old mapping until the ease ends.

### D6. Console, tour turns, the captain sprite

- **Console:** `ShipConsoles.focus_pose` is unchanged. `restore()` returns to the previous view id with its exact basis.
- **Tour turns:** the attitude turn (`tour_attitude`) rotates only the sky. The player camera is never turned (R2-CAMERA C2). The developer free camera keeps the old first-person turn.
- **The captain sprite:**
  - **Facing:** the yaw is fixed, so facing is just the screen direction of motion. Walking toward the bow shows the `back` sprite. At rest the captain faces the bow (`back`), so the captain looks where the player looks.
  - **Seen in the D-92 prototype frames:** the sprite faced the camera (`front`) because the prototype didn't set the facing. F1b sets it.
  - **Pitch:** the sprites were drawn for a −14° iso pitch, and the Bow view is −8°. AC-V4 checks the 60–80 px band, and the sprite's read is reviewed by eye.

### D7. Data: `views.json` schema v2, level-keyed

```json
{
  "schema": "stapledons.camera.views/2",
  "fov_deg": 78.0, "envelope_m": 95.0, "travel_axis": "bow",
  "levels": {
    "bridge":  {"deck_y_m": 82.0, "default": "bow",
                "views": [
                  {"id": "bow",     "kind": "walk", "yaw_deg": 270.0, "pitch_deg": -8.0, "back_m": 9.0, "rise_m": 5.5, "dead_zone": [0.24, 0.20], "ease_s": 1.2},
                  {"id": "astern",  "kind": "walk", "yaw_deg": 90.0,  "pitch_deg": -8.0, "back_m": 9.0, "rise_m": 5.5, "dead_zone": [0.24, 0.20], "ease_s": 1.2},
                  {"id": "console", "kind": "console", "ease_s": 0.6}]},
    "commons": {"deck_y_m": 57.0, "legacy": true, "views": [ "...today's z1_lower / z2_lower / z3_commons, unchanged..." ]}
  }
}
```

- **`yaw_deg`** uses ShipCamera's convention, forward = (cos, ·, sin), so 270° looks along −Z, the bow.
- **`validate()` checks that:**
  - each level's `default` names one of its own views;
  - every non-legacy `walk` view has a fixed `yaw_deg` and `rise_m ≥ 0.3`;
  - nothing changes the FOV;
  - the envelope is ≤ 95 m;
  - `travel_axis` is `"bow"`, matching ShipCamera.

  Each rule has a negative control.
- **Level changes:** the lift's arrival selects the level's default view.
- **The Commons:** `legacy: true` keeps today's sector code path, fenced off from the bridge.
- **Later levels** each get a Bow view at their own height, looking out over their own bow edge.

### D8. Physics gate: goldens, tests and renders re-baselined one for one

- **The sky is still rendered through the same pose** (`_sync_observer()` after every director write). The basis change moves where the pole is in the interior. It never changes what the sky looks like at a given angle from the velocity.
- **Goldens:** `make golden` keeps 393 ok lines and unchanged counts. The re-posed families:
  - **G-M4-S3** (forward pole, 3): `_pose(89.99, 0)` looked up; it now looks at the bow (`_pose(−0.01, 270°)`).
  - **G-M4-S2** (one tonemap) and **G-M4-S4** (glow, 6): the same poses through the new basis.
  - **G-CAM-1** (forward pole, 9): Bow at `spawn` (3), Bow at `helm` (3), and Bow at Sgr A* with the hole on the pole (3).
  - **G-CAM-2** (glow, 8): 4 eyes × {0.99c, cap}. The eyes are Bow at `spawn`, Bow at the rail (nearest the wall), Astern at `spawn`, and Bow at the helm.
  - **G-CAM-3** (one tonemap, 2): Bow and Astern.
- **Golden labels:** the recipe's grep prefixes stay. The parenthesised suffixes, and the `##` help and failure text, change in the same commit.
- **Nothing else may move.** Every other case (interior_golden's pure-frame cases, GR1–GR12, M1.x, constellations) must print the same `ok` line with the same numbers.
  - AC-B4 diffs the number-stripped `ok` lines against a baseline captured from main.
  - Any unexpected move: stop and list it for Mark.
- **tests/test_physics.gd:** the forward-pole cases built through `_sky_cam` (line 1706) use the new map. Their check values (from relativity-spec) and their counts are unchanged.
- **Reference renders:** `make capture`, `camera-views-capture` and `camera-walk-capture` at rest, 0.9c, 0.99c, a guided stop and Sgr A*. Every frame put in front of Mark is opened (gate 2). The after-sheets are published to `gs://stapledons-voyage-assets/refs/camera_forward/after/`.

### D9. Art and the deck-layout re-plan

- **Dress only what a view sees.**
  - The bridge's Bow view sees the deck's stern-facing surfaces and the bow rail against the sky, so those get finished art.
  - Backs and undersides can stay rough.
  - Blender authors per-view set pieces and may bake painted layers.
- **Each level gets its own style,** matched to its concept art.
- **Depth comes from parallax:** foreground props move fast, the deck 1:1, the far rail, the wall and the mast slower, and the sky is fixed.
- **The sky layer is always the live SR/GR render:** never painted, baked or composited. Painted layers stop at the bubble wall.
- **The deck layout (D-90) is re-planned to face the bow.**
  - **Stations face the forward window:** the helm and navigation at the bow rail, and the others in an arc that keeps the pole ray clear in the Bow view.
  - **The spire** becomes a foreground occluder to compose around, rather than a centrepiece.
  - **Carries over** from `feat/deck-layout` (7863c831):
    - `tools/deck_assets_check.gd` and `art/deck-layout-v1/budgets.json`;
    - `tools/deck_layout.gd` with `layout_current.json` (moving props and rebuilding the walk);
    - the sky-mask and sky-fraction maths.
  - **Re-targeted:** the metric code samples the Bow and Astern views over every walk sample. The key numbers become: the pole ray clear, the captain 60–80 px and unblocked, and the stations in frame.
  - **Obsolete:** the per-sector framing in `thresholds.json`, and both candidate layouts (they face the old views).

### D10. What changes, and where

| File | Change |
|---|---|
| `demos/ship_demo_camera.gd` | `ship_vector` (new R) and its named inverse `gltf_from_ship`; `sync_sky`'s `cam_ship` goes through it; the prototype flag is removed |
| `interior/ship_frame.gd` | `gltf_from_structure` / `structure_from_gltf` named; R documented; the frame comment updated (D-92) |
| `demos/ship_geometry_demo.gd` | `hole_direction` via the named inverse; keys 7, 9 and R; HUD copy; `look_direction` re-posed; the level default on the lift |
| `demos/ship_attitude.gd` | `side_basis` tilt 15° → 60° (the body 30° off the bow) |
| `interior/area_bundle.gd`, `interior/interior_sky.gd` (comment), the `--interior` HUD line | legacy tag on the bundle frame (§D1.6); no change of numbers |
| `ui/journey_hud.gd` | `BRAKE_NOTICE` reworded (§D1.5) |
| `demos/ship_star_light.gd`, the structure sites (§D1.2) | the named maps |
| `demos/camera_director.gd` | the v2 rig; Bow and Astern; the occluder group and fade; the legacy fence; `aim_dir` → the bow |
| `data/camera/views.json` | schema v2 (§D7) |
| `data/lore/archive/{one-g,starbow}.md`, `data/lore/manifest.json` | re-imported from the design repo after #30 |
| Tests | `test_camera_forward.gd` (new); `test_camera_director.gd` (v2 plus a legacy block); `test_physics.gd` (the `_sky_cam` map); `test_ship_demo.gd` (the observer); `test_ship_demo_input.gd` (the keys); `test_no_twitch.gd`, `test_ship_consoles.gd`, `test_ship_movement.gd`, `test_ship_ui.gd`, `test_ship_demo_journey.gd`, `test_ship_demo_live.gd`, `test_free_nav_stop.gd`, `test_ship_demo_consolidation.gd` and `m4_playthrough_ship.gd` (the forward pole) |
| Tools | `camera_walk_capture.gd` (Bow and Astern passes; the prototype flag removed); `camera_views_capture.gd`; `m4_ship_golden.gd`; `constellation_golden.gd`; `ship_star_identification_capture.gd`; capture metadata via `ship_vector` |
| `Makefile` | `camera-forward-test` (headless, on `ship-demo-ci`); `camera-walk-capture` (GPU evidence); the golden labels |

The other tools that pose the camera through `override()` keep working. Any that names `sky_forward`, `sky_side` or `z2` gets the new id, and its make-target smoke checks it.

## Acceptance criteria

**Conventions:**
- `$A` = `AILANG=$PWD/runtime/bin/ailang`: the pinned runtime, also first on PATH. `$S` = `.godot/tmp`.
- Tests print `ok    <name>` or `FAIL  <name>: <why>`, and end with `<suite>: <n> passed, 0 failures`.
- Recipes save `$S/<suite>.log`, and the ACs grep the saved logs.
- `camera-test` (the existing `tests/test_camera_director.gd`) prints `ok <name>` with one space. The new `camera-forward-test` prints `ok    <name>` with four spaces, as `make golden` does.
- In the table below, `\|` is markdown escaping for `|`. The sprint JSON carries the commands verbatim and is the copy to run.

**Headless fixtures:**
- `test_camera_forward.gd` injects the stop body's direction and the attitude through `target_override`, the way `hole_override` does for the hole.
- The real guided stop and the lensed Sgr A* are covered by `camera-views-capture` (AC-R1).

**Recipes (F1a):**
- `camera-forward-test: import` runs `tests/test_camera_forward.gd` headless.
  - It logs to `$(SCRATCH)/camera-forward-test.log`.
  - Gate: `^camera-forward: [0-9]* passed, 0 failures$`.
  - It hangs off `ship-demo-ci`, which `make test` runs (Makefile:973).
- `camera-walk-capture: import` (GPU). Gate: `^camera-walk-capture: [0-9]* frames, 0 failures$`.

| # | Criterion | Command (exit 0 = met) |
|---|---|---|
| AC-B1 | One named map per frame: no inline structure or kinematic conversion literal outside `ShipFrame.gltf_from_structure`/`structure_from_gltf` and `ShipCamera.ship_vector`/`gltf_from_ship`. The pattern also matches the new map's form (`-x, y, -z`). A positive control, `tests/fixtures/basis_gate/inline.gd.txt`, holds one literal of each form and must be caught | `test $(git ls-files '*.gd' \| xargs grep -nE '\[2\], *-[a-z_.]*\[1\]\|\.x, *-[a-z_.]*\.z, *[a-z_.]*\.y\|-[a-z_.]*\.x, *[a-z_.]*\.y, *-[a-z_.]*\.z' \| grep -vE '^(interior/ship_frame\|demos/ship_demo_camera)\.gd:' \| wc -l) -eq 0 && test $(grep -cE '\[2\], *-[a-z_.]*\[1\]\|\.x, *-[a-z_.]*\.z, *[a-z_.]*\.y\|-[a-z_.]*\.x, *[a-z_.]*\.y, *-[a-z_.]*\.z' tests/fixtures/basis_gate/inline.gd.txt) -ge 3` |
| AC-B2 | R is a proper rotation: orthonormal, det +1, the structure's bow (+Y) to kinematic +Z and the mast (+Z) to +Y; the composite maps agree. The same check values are also asserted in `tests/test_physics.gd` (gate 2) | `grep -qE '^ok    basis R proper bow->\+Z mast->\+Y$' $S/camera-forward-test.log` |
| AC-B3 | `tests/test_physics.gd` passes with the new map, with the same total as main (recorded at F1a start in `tests/fixtures/physics_total.txt`) | `make physics $A > $S/physics.txt && grep -q "^$(cat tests/fixtures/physics_total.txt) passed, 0 failed" $S/physics.txt` |
| AC-B4 | `make golden` gives 393 ok lines, with G-M4-S2..S4 and G-CAM-1..3 re-posed; every other `ok` line matches main's baseline with numbers stripped. `golden_baseline.sh` excludes exactly the label prefixes `G-M4-S2`, `G-M4-S3`, `G-M4-S4`, `G-CAM-1`, `G-CAM-2`, `G-CAM-3`. interior_golden's G-M4-1..6 (the legacy plate path, §D1.6) are not excluded and must stay identical. Negative control: `golden_baseline.sh selftest` changes one number in a non-excluded line and must fail | `make golden $A && tools/golden_baseline.sh check $S/golden.log tests/fixtures/golden_baseline_ok.txt && tools/golden_baseline.sh selftest` |
| AC-B5 | The sim is untouched (the protocol minor lives in `sim/protocol.ail`, so it is unchanged too); parity, replay and strict are green | `test -z "$(git diff --name-only origin/main -- sim/)" && make parity replay strict $A` |
| AC-B6 | The vendored lore matches the design repo after #30, and the lore pins still hold (checked in F3 if #30 merges after F1a) | `make lore-import CHECK=1 D=../stapledons-design AILANG=ailang && make lore-check lore-test $A` |
| AC-V1 | Bow and Astern hold a constant yaw over the 16-sample bridge walk, spread ≤ 0.1° (today: 180°) | `test $(grep -cE '^ok    yaw constant (bow\|astern) spread=0\.[0-9]+ deg over 16$' $S/camera-forward-test.log) -eq 2` |
| AC-V2 | In Bow, the pole (the destination when under way) and the 0.9c and 0.99c starbow edges are in frame (40 px margin) at 16/16 samples | `test $(grep -cE '^ok    in frame bow (pole\|starbow_0\.9c\|starbow_0\.99c) 16/16$' $S/camera-forward-test.log) -eq 3` |
| AC-V3 | In Bow, the pole ray (the journey and the forward glow) and the line to the captain's head are clear after fades, and the eye is never inside geometry, at 16/16 | `test $(grep -cE '^ok    clear after fades bow (pole_ray\|captain\|eye_free) 16/16$' $S/camera-forward-test.log) -eq 3` |
| AC-V4 | The captain is 60–80 px tall at 720p at every Bow sample, and at least 50% of the frame is below the horizon | `grep -qE '^ok    captain px bow (6[0-9]\|7[0-9]\|80)\.\.(6[0-9]\|7[0-9]\|80)$' $S/camera-forward-test.log && grep -qE '^ok    deck fraction bow 0\.[5-7][0-9]$' $S/camera-forward-test.log` |
| AC-V5 | W moves the captain up-screen and D moves it right, in Bow and in Astern and after each switch: each key held 0.5 s gives Δy < −20 px with \|Δx\| < 0.3\|Δy\| | `test $(grep -cE '^ok    (W up-screen\|D right) (bow\|astern)$' $S/camera-forward-test.log) -eq 4 && test $(grep -cE '^ok    W up-screen after switch (bow>astern\|astern>bow)$' $S/camera-forward-test.log) -eq 2` |
| AC-V6 | With the new stop turn, the first guided stop's body is in the Bow frame at 16/16, and the Sgr A* hole at 16/16 (flat-space aim). The fixture is not trivial: it runs the real `side_basis` and `ship_vector` with the guided stop's body direction (taken from `tests/fixtures/crossing_review` or the stop capture), and the camera pose comes from the director. AC-R1 gates the real stop and the lensed hole in a capture | `test $(grep -cE '^ok    in frame bow (stop_body\|sgr_a_hole) 16/16$' $S/camera-forward-test.log) -eq 2` |
| AC-V7 | The eye stays within 95 m and at least 0.3 m above its deck; a clamp keeps the angle | `grep -qE '^ok    envelope keeps the angle$' $S/camera-forward-test.log && grep -qE '^ok    eye above deck at 32 samples$' $S/camera-forward-test.log` |
| AC-V8 | A switch eases at ≤ 90°/s (full motion) or cuts (reduced); the key mapping changes at the end of the ease; a console round trip restores the exact basis and id | `test $(grep -cE '^ok    (switch ease max [0-9.]+ deg/s\|reduced cut\|mapping at ease end\|console returns to (bow\|astern) exact)$' $S/camera-forward-test.log) -eq 5` |
| AC-V9 | `views.json` v2 validates; the negative controls fail as they must: no default, a foreign default, no `yaw_deg`, an FOV change, envelope > 95, `rise_m` < 0.3, a `travel_axis` mismatch | `grep -qE '^ok schema v2$' $S/camera-test.log && test $(grep -cE '^ok negative control v2 ' $S/camera-test.log) -eq 7` |
| AC-V10 | The lift's arrival selects the level default: Bow on the bridge, legacy Z2 in the Commons | `test $(grep -cE '^ok    level default (bridge\|commons)$' $S/camera-forward-test.log) -eq 2` |
| AC-V11 | Determinism: the same scripted inputs (walk, switches, console, 600 steps at fixed `dt`) run twice give bit-identical poses; fades and eases read `advance(dt)` only | `grep -qE '^ok    deterministic poses 600 steps$' $S/camera-forward-test.log` |
| AC-V12 | A fade changes no sky uniform and no sim input | `grep -qE '^ok    fade leaves sky and sim untouched$' $S/camera-forward-test.log` |
| AC-R1 | Captures with 0 failures: Bow, Astern, the legacy Commons and the lift, × rest, 0.9c, 0.99c, a guided stop and Sgr A*, at 720p and 1440p, gated on the pole, body or hole, and head; plus a forced-fade frame. **Human gate (not machine-checked):** the report lists every frame opened by eye, and the PR is not merged without it | `make camera-views-capture $A && make camera-walk-capture $A` |
| AC-R2 | The display audit is green with the new HUD copy; any changed caption pin is listed in the PR | `make display-audit $A` |
| AC-T1 | The full suite is green; no new Python | `make python-guard && make test $A` |
| AC-T2 | Landed (checked at landing): doc and sprint in `implemented/r2/`, plus a changelog fragment | `test -f design_docs/implemented/r2/camera-forward.md && ls changelogs/unreleased/*camera-forward*` |

## Sub-milestones and estimates

**Approval gate:** Mark answers OQ1–OQ4, and design PR #30 merges before F1a's lore step.

| # | What | LOC | Days |
|---|---|---|---|
| F1a | **The basis change.** Named maps (§D1.1–D1.2), R and its test, the grep gate, the legacy tag on the painted-plate path (§D1.6), HUD copy and `BRAKE_NOTICE`, `look_direction` and the tour-turn arguments, and the stop-turn tilt. Every test those changes break moves in the same commit: `test_physics`, `test_camera_director`, `test_ship_demo`, `test_tour_attitude`, `test_ship_attitude`, `test_no_twitch`, `test_transit`, `test_ship_star_light`, `test_ship_demo_journey`, `test_ship_demo_live`, `test_free_nav_stop` and `test_ship_ui`; the painted-plate tests (`test_area_bundle`, `test_interior`, `test_bridge_floor`, m4-smoke) must pass unchanged. Goldens re-baselined with the baseline tool, and the reference renders opened. Covers AC-B1–B5 and AC-R2, plus `make camera-test` and a full `make test` | ~650 | 2.5 |
| F1b | **The Bow view.** F1a and F1b form **one green point (F1)**: commits inside F1 may be red (after the basis change and before the Bow view replaces the legacy sky views, `camera-test`’s pole and hole checks fail by design). F1 ends green with `make camera-test` and a full `make test`, and only then is the dev build tagged. F1b adds `CameraDirector.pole_dir()` (new: the bow, `Vector3.FORWARD`) and moves `test_camera_director.gd`’s pole literals (lines 589, 595, 633, 704–810) onto it, while the legacy `sky_forward`, `sky_hole` and `sky_side` checks are replaced by the Bow ones. Schema v2 and validate, the slide rig, the Bow view (candidate A), the occluder group and fade, the captain's facing, keys 7 and R, the level default, and the `camera-forward-test` and `camera-walk-capture` recipes. Covers AC-V1–V4 (Bow), AC-V7 and AC-V9–V12. **Pause point:** a dev build for Mark to play | ~450 | 1.25 |
| F2 | **Astern and the rest.** Astern and the 9 key, switch eases, the console restore, cues to Bow, and the stop body and Sgr A* in frame. Covers AC-V1 (Astern), AC-V5, AC-V6 and AC-V8 | ~200 | 0.5 |
| F3 | **Finish and land.** The lore re-import if #30 merged late (AC-B6), captures, the remaining caller migration (the director and capture tools, §D10), the legacy-fence cleanup, the report, an independent evaluation and its fixes, and landing. Covers AC-B6, AC-R1, AC-T1 and AC-T2 | ~300 | 1.75 |

That is about 1,600 LOC over 6.0 days, roughly 270 LOC a day, against R2-CAMERA's measured ~310 a day. F1a is surgery on the basis across about 30 files plus re-baselining the goldens on the Studio's GPU, so it is slower per line.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| A golden family outside the planned re-pose moves | AC-B4's baseline diff; stop and list it for Mark |
| Golden re-baselining needs the Studio's GPU window, and every round trip costs time | F1a carries 2.5 days with that in mind. Goldens run once per batch of re-poses, not per site; `make physics` and the headless tests catch most errors before a GPU run |
| A conversion site is filed in the wrong frame (structure vs kinematic) | AC-B1's grep gate forces every site through a named map. The structure tests (Commons walk targets, the consolidation eye) and the kinematic tests (the observer, constellations, star identification) each check their own side |
| The spire hides the journey or swallows the eye | The occluder rule (§D2 b, c); AC-V3 requires 16/16 |
| The 60° stop-turn tilt reads oddly (the body ahead but low) | AC-V6 and the stop capture check it. The tilt is one constant, and Mark sees it in the F1b dev build |
| The design repo's lore PR isn't merged when F1a lands | AC-B6 waits: F1a can land without the lore step, and F3 completes it |
| The sprites were drawn for a −14° iso pitch | The 60–80 px band plus review by eye; the deck-layout re-plan revisits them |
| Lower levels under D-92 (each bow edge sees the forward sky) | Out of scope: the Commons stays legacy until its own pass |

## Open questions for Mark (with recommendations)

**All resolved as recommended (Mark, attended 2026-10-19, ledger D-93: "yep looks great approved").**

| # | Question | Recommendation |
|---|---|---|
| OQ1 | The default Bow view: candidate A (pitch −8°, 9 m back, 5.5 m up) keeps the 0.9c starbow in frame, with the captain at 73 px and the deck filling 59% of the frame. B and C lose the 0.9c starbow | **A** |
| OQ2 | "Planet facing (same as navigation around ship?)": the guided stop turns the ship so the body sits 30° off the bow, inside the Bow frame, with no separate view. Is that what you meant? | **Yes.** A Target key for free navigation is a follow-up, if bodies can still leave the frame |
| OQ3 | Side and Astern views under D-92 | **Astern: yes** (key 9: the dark, redshifted aft sky over the stern rail). **Side: no** player view (its darkening shows at the edges of the Bow frame) |
| OQ4 | Zoom levels Z1–Z3 | **Remove for players.** Each view has one framing, and Console is the only zoom. Keep them as developer presets, and revisit after the F1b dev build |
| OQ5 | The spire in the way | **Fade it** (or hide it as a fallback) while it crosses the line to the captain or the pole ray, or contains the eye. Never turn the camera |
| OQ6 | The Commons in this sprint. Legacy keeps its turning sector views (the thing you objected to) and its Z1–Z3 keys, which stay live on legacy levels only, so it is unchanged | **Legacy for now** and its own Bow pass after the deck re-plan. The alternative is a minimal Commons Bow view in F2 (about +0.5 day, if its clear-line sweep passes) |
| OQ7 | An inset window showing Astern while in Bow | **Later,** after the F1b dev build |
| OQ8 | The painted-plate interior (`--interior`, the D-6 reference) keeps the pre-D-92 orientation (§D1.6). Re-render its plates for D-92, or retire it? | **Keep it labelled as legacy this sprint;** decide with the deck-layout re-plan, whose Blender work could re-render it |

## Evidence

- **Before (D-91):** https://storage.googleapis.com/stapledons-voyage-assets/refs/camera_forward/before/contact_sheet.png, with the `rest_*` and `under_way_*` frames and `walk.json`.
- **D-92 candidates:** https://storage.googleapis.com/stapledons-voyage-assets/refs/camera_forward/bow_candidates/contact_sheet_bow.png.
  - The sheet has 12 rows: rest A, B, C, then 0.99c cruise A, B, C, each at radii 10 m and 17 m, with 8 angles per row.
  - The 96 frames and `walk_bow.json` are in the same folder.
  - Opened by eye: the sheet, `bow_cruise_A_r17_2`, `bow_cruise_A_r17_6`, and a debug frame from directly behind the spire.
- **Tool:** `tools/camera_walk_capture.gd` (`--bow`). The `ShipCamera.travel_axis` flag is a prototype for measurement only; F1a removes it.

## Deliverables

- This doc, [camera-forward-sprint.md](camera-forward-sprint.md) and `.ailang/state/sprints/sprint_R2-CAMERA-FORWARD.json`.
- Design repo PR [#30](https://github.com/sunholo-data/stapledons-design/pull/30): the D-92 amendments and the lore.
- The F1a–F3 code, tests, tools, data, goldens and renders listed in §D10, with a dev build after F1b.
- After-captures and a report, the independent evaluation, and landing (`implemented/r2/`, the roadmap, the changelog).
- Then the deck-layout re-plan (D-90), facing the bow.
