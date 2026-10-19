# R2-CAMERA: fixed zoom levels and authored third-person views

**Status:** **Implemented** 2026-10-19 (PR #270; evaluation 79/100 PASS, fixes in D9). Approved 2026-10-16 by Mark, attended ("yes continue", all nine recommendations; OQ1-OQ9 answered as recommended); amended 2026-10-17 ("Sky forward under way", D9). Ledger D-83. C5 (the 19-tool smoke runs) held.
**Release:** R2. **Milestone:** a player-facing camera for the 3D ship (D-52 A), replacing free look and free zoom.
**Priority:** P1 for R2. Every session runs through this camera, and Mark's dev.31 playtest asked for it.

**Mark's direction** (playtest of dev.31, 2026-10-16, verbatim):
> I think we need to turn off zoom in and out for players, and switch to fixed zoom levels instead. we may want to also start having more fixed camera angles and not be 1st person but 3rd person only

This doc treats that as:
- **A ruling (R1):** free player zoom goes away. It is replaced by a small set of fixed zoom levels, stepped, with eased transitions.
- **A direction (R2):** fixed, authored camera angles per place and situation, and third person only. The design and recommendations below, and the open questions, are for Mark to confirm.

This PR does not edit the decision ledger. The attended session may record R1 as a ledger row (`mission_answer.sh`); the open questions below are candidates for rows.

**Implements** (design repo):
- [vision/design-decisions.md, 2026-09-28 "Interior: Isometric Three-Layer View From Inside the Bubble" (D-6)](https://github.com/sunholo-data/stapledons-design/blob/main/vision/design-decisions.md): "the player walks the ship among the crew", room scale "about 16 m in view", first-person 3D rejected because it "pulls focus from conversations". It also covers the 2025-12-18 first-person entry, which D-6 supersedes.
- [art/characters-blender-brief.md §2.2, §3.1](https://github.com/sunholo-data/stapledons-design/blob/main/art/characters-blender-brief.md): the captain is a static mini avatar at 4 life stages, which must "read at approximately 60–80 px tall in the play view. Validate at 70 px on the bridge".
- [art/ship-interior-blender-brief.md §2](https://github.com/sunholo-data/stapledons-design/blob/main/art/ship-interior-blender-brief.md): the player is inside the bubble, up is forward, and the sky is at infinity ("fixed when the camera pans").
- [features/future/sr-view-directions.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/sr-view-directions.md): forward, side and aft show different physics, so those directions stay as authored views.
- [features/future/input-rebinding.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/input-rebinding.md): input goes through named actions, so a controller is a mapping.
- [physics/relativity-spec.md §2](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md) (SR, a moving observer: aberration and Doppler depend on direction and velocity only), the GR section (an observer at finite r, δ(ψ, r)), and [physics/higgs-bubble.md §6](https://github.com/sunholo-data/stapledons-design/blob/main/physics/higgs-bubble.md) (the wall glow, which depends on where the observer is in the bubble).
- Ledger: D-6, D-14 (up is the direction of travel), D-52 A (the 3D ship is the game), D-55 (Auto view default; unaffected), D-56/D-57 (decisions at consoles; console focus dolly, Q4), D-63 (default mouse look; **superseded for players** by this doc).

**Depends on:**
- Nothing upstream. No new physics formula, so `sunholo/relativity` is not touched (gate 3 holds trivially).
- Crew console v2 (two-panel videocom, in design separately). It shares the console-focus view, C1 below. Whichever lands second adapts to the first; the contract is in §D4.
- The Alpha Centauri mouse-look bug (being investigated separately). For players, this design removes mouse look. The fix still matters for the developer free camera and for pointer ownership (§D7).

**Estimated LOC:** about 1,250 of product code and about 450 of test changes, about 1,700 in all. The sprint plan schedules 5.5 days.

## Game vision alignment

Scored with the `game-vision-designer` skill (feature-validation mode, against `vision/core-pillars.md` and the D-6 / 2026-10-03 decisions), 2026-10-16. **ALIGNED.** It moves the 3D ship back toward D-6, which chose an avatar in the scene over first person.

| Pillar | Score | Rationale |
|---|---|---|
| Choices Are Final | 0 | The camera never takes a decision. The no-twitch tests (NT1–NT5) keep proving that |
| The Game Doesn't Judge | 0 | Neutral |
| Time Has Emotional Weight | +2 | Third person puts the captain's ageing sprite (stages 0/20/40/60 years) on screen in every session; the player sees their own years pass. The authored sky view frames a small figure under the starbow |
| The Ship Is Home | +2 | D-6: "the player walks the ship among the crew". You see yourself among the consoles and crew at the art brief's reading scale (70 px), rather than a floating eye |
| Grounded Strangeness | +1 | The sky is still rendered from the ship's frame through the same camera. Forward, side and aft stay one key away as authored views. Cost: the player can no longer point at any patch of sky. Mitigation: `I` identification still works in every view, and the sky views cover the three physically different directions |
| We Are Not Built For This | +1 | Framing a 1.75 m figure against a 100 m bubble and a crowded forward sky shows the human scale |
| **Net** | **+6** | **Go.** No pillar is negative |

## Problem

What happens today, from a code read of `origin/main` 13bcc40 and captures taken on 2026-10-16 (see Evidence):

1. **"Zoom" is a free dolly.** `_zoom()` (`demos/ship_geometry_demo.gd:443`) adds the wheel or pan-gesture delta to `camera.pullback`, clamped to [0, 300] m. The field of view is fixed at 78° (`demos/ship_demo_camera.gd:12`). At pullback 25 m from the spawn, the eye is at 93.7 m from the ship's centre. Past 100 m, `ShipCamera.follow` sets `external` and `sync_sky` zeroes the glow pole: the player has left the bubble, and the camera is no longer a ship-frame observer inside the wall. Nothing stops a player scrolling there. Trackpad scroll is continuous (`-event.delta.y*2`), so a MacBook two-finger swipe slides the camera by tens of metres (CHANGELOG dev.4: "two-finger scrolling zooms"; `tests/test_ship_demo_input.gd:25` pins "fractional two-finger scroll smoothly zooms").
2. **The default is first person.** The launch view is the captain's 1.7 m eye, and the sprite is hidden (`avatar.visible = pullback > .5`; CHANGELOG dev.10: "Normal launch opens ... at the captain's measured eye. Scrolling reveals a labelled third-person view"). D-6 rejected first-person 3D. The eye default came in with the unified painted ship (2026-10-05) as a review choice; no design decision for players made it.
3. **Mouse look is on by default** (D-63, 2026-10-10: "make mouse look the default without Option-drag"). The pointer is captured whenever no panel is open (`_sync_pointer`, line 1241). Clicking a console therefore aims from the screen centre (line 382). A pointer-ownership fault strands the player; the open bug "mouse look stops working after arriving at Alpha Centauri" is one.
4. **Views come from several places.** There are presets 1–4 and R (`set_preset`), looks 7/8/9 (`look_direction`, first person at tilt ±89.5/0), the console dolly (`ShipConsoles.focus_pose`, 0.6 s smoothstep), and tour turns (`_begin_tour_turn` lerps tilt/yaw over 3 s to 89.5° at departure and 15° at a stop). Two of the presets are external (3: (145, 90, 145), outside the bubble) or diagnostic (4: rim "not reachable"), yet both are on player keys.
5. **The sprite is drawn for one camera family.** The captain sprite (`interior/captain_avatar.gd`) is a full billboard drawn for the −14° iso pitch, with facings front/back/ne/se. It reads well from a fixed, slightly elevated three-quarter view. It reads badly from an arbitrary orbit or from below.

## Goals and non-goals

**Goals**
- G1. No continuous zoom for players: **three fixed zoom levels**, stepped by key, wheel notch, trackpad gesture or controller, with eased transitions.
- G2. **Third person only** for players: the captain is on screen in every player view except console focus, which frames a screen (§D4).
- G3. **Authored views** for each place (bridge, lift, lower deck) and situation (sky at speed, departure turn, stops, arrivals, Sgr A*, interludes, console focus).
- G4. **The physics is unchanged.** The sky is rendered from the ship's frame, through the same camera as the geometry. Every player camera stays inside the bubble's inner envelope. Goldens cover the new observer positions.
- G5. **Motion sensitivity:** a reduced-motion setting, a cap on camera angular speed, no shake, no FOV change.
- G6. **Free look and free zoom survive as developer tools only** (command-line launches), so captures, goldens and reviews keep working.

**Non-goals**
- The galaxy map's and star chart's own zoom (`ui/galaxy_map.gd`, + / − / pinch). That is a 2D instrument, not the player camera, and is unchanged.
- An exterior view of the ship from outside the bubble for players (OQ5).
- New art: no new sprite facings or plates. The views are chosen to suit the existing sprite.
- Orthographic projection (OQ8).
- Rebinding UI (`input-rebinding.md`). This sprint adds the named actions it needs.
- Fixing the Alpha Centauri pointer bug. That is a separate investigation; §D7 says what this design changes about it.

## Design

### D0. One camera director

There is a new `demos/camera_director.gd` (`CameraDirector`, about 350 LOC). It owns every pose the player camera takes. `ShipCamera` (`ship_demo_camera.gd`) stays the render boundary (`sync_sky`, the float64 attitude); the director only sets its transform.

- **Views are data:** `data/camera/views.json`, validated at load (schema test). Each view has:
  `id`, `kind` (`level` | `place` | `situation` | `console`), `anchor` (`captain` | `point` | `station`), `pitch_deg`, `distance_m`, `height_m`, `yaw_rule` (`sector` | `fixed:<deg>` | `toward:<target>`), `look_offset_m`, `ease_s`, and `envelope_m` (the maximum |eye|, default 95).
- **One state:** `{view_id, level, sector, blend}`. `advance(dt)` is the only time source, the same fake-clock seam as `ShipConsoles` (AC13 of R1-SHIP-UI), so tests run without wall time.
- **Transitions:** a pose-to-pose blend. The position is lerped and the basis slerped with smoothstep, exactly as the console dolly does now (`ship_consoles.gd:610`). The dolly is folded into the director, so there is one easing code path.
- **Envelope:** every resolved eye must satisfy |eye| ≤ 95 m (the inner envelope from `m4-ship-geometry-demo.md`; bubble R = 100 m). A view that would leave it is a data error: the test fails, and at runtime the eye is clamped along its boom and the clamp is logged. Nothing ever sets `external` in a player launch.
- **Clear line:** for each view, a ray from the eye to the captain's head (foot + 1.6 m) must not hit opaque geometry. This is checked for every walkable sample of the walk meshes (§D2). There is no dynamic camera-collision pushing, because it twitches.
- **The FOV stays fixed at 78°** for every player view. A zoom level changes the distance, never the FOV (§D8).

### D1. Zoom levels (the ruling)

There are **three levels**. Each is a distance and pitch on the captain's boom, at the current authored yaw. The pixel figures are at 720 px height; they scale with resolution.

| Level | Name | Boom (distance, pitch) | Frames | Captain height | Replaces |
|---|---|---|---|---|---|
| Z1 | **Close** | 4.5 m, −20° | The captain and what is within reach: the console in front, the lift rail | ~150 px | Today's eye view (1.7 m, sprite hidden) and scroll pullback 0–5 m |
| Z2 | **Deck** (default) | 12 m, −35° | A room-scale patch of deck, ~19 m tall at the captain (D-6's "about 16 m in view"). Consoles and crew around the captain | **~65–70 px** (the art brief's validation scale) | Scroll pullback ~5–20 m |
| Z3 | **Whole level** | A per-area authored place camera. Bridge: at the rim opposite the captain's sector, ~9 m above the deck, looking across the disc | The whole bridge disc, the spire and every station. The captain is marked with a small ring in the accent colour | ~25 px + ring | Preset 3 "whole ship" (external, at 224 m) and scroll pullback 20–300 m |

Z3 cannot be a longer boom: the bridge floor is at +82 m and the bubble is 100 m. A 26 m boom at −50° puts the eye at 104.6 m, outside the bubble (captured, see Evidence). So Z3 is a **place camera** that tracks the captain by rotation only: the eye is fixed per sector, and the yaw/pitch is eased toward the captain within ±25°.

Rules:
- **Stepping:** one input step moves one level. Z1 is the floor and Z3 the ceiling; there is no wrap.
- **While walking**, the level holds. The boom follows the captain with a critically damped spring (0.25 s), so the captain stays put on screen with no bob.
- **Level steps are disabled** during lift travel and benchmark sampling, as today, and during console focus and open panels, where the wheel belongs to the panel.
- **The level is remembered** across console focus, lift rides and situation views. `R` returns to the default view and level.
- **Z3 has a per-area authored camera:** the bridge, the lower-deck Commons and the lift shaft (§D2).

### D2. The authored angle set, and when each view is used

The yaw on the bridge is decided by **sectors**, not by the player. The bridge is a 22 m disc around a central spire, so a fixed world yaw would put the spire between camera and captain on the far side. The disc is split into **8 sectors of 45°** around the spire axis. In each sector, the boom points **outward over the captain toward the rail and the sky**: the camera is on the spire side, so the sky is behind the captain, and the spire is never between them. A sector switch happens only 10° past the boundary (hysteresis) and eases over 0.8 s. The 45° steps match the sprite's diagonal facings (ne/se), so the billboard is seen close to its drawn angle.

**Walking while the view turns.** WASD is screen-relative (W = up the screen, as the sprite's facing rule assumes). While a key is held across a sector switch, the walking direction is **held in world space** until every move key is released. This is the standard fixed-camera rule; it stops the captain reversing mid-stride.

| View | Kind | Where and how | Used when | Replaces |
|---|---|---|---|---|
| **Z1/Z2 on the bridge** | level | Captain boom, sector yaw | Default while walking or standing on the bridge | Presets 1 "bridge", 2 "overlook", R |
| **Z3 bridge** | place | Rim camera opposite the captain's sector, ~91 m height, \|eye\| ≤ 93 m | The player picks Z3 | Preset 3 (external), preset 4 (diagnostic rim) |
| **Lower deck (Commons)** Z1–Z3 | level / place | The same levels; Z3 is a Commons authored camera under the bridge's underside | After the lift lands | Today's free view on the lower deck |
| **Lift** | place | Fixed on the shaft, captain on the platform, looking along the travel | During lift travel (levels locked) | Today's eye riding the platform |
| **Sky forward** (7) | situation | Captain at the bridge's **forward-watch point** (an authored anchor at the rail, clear of the lift and spire). Camera low behind, pitch about +55°; the captain's silhouette in the lower third, the forward pole (starbow) in frame | Key 7. **Cued** during the departure attitude turn and the first seconds of boost, at the start of braking and on the Sgr A* approach | `look_direction("forward")` (first person, tilt 89.5); the tour's departure turn to 89.5° |
| **Sky side** (8) | situation | Captain at the rail in the sector the stop's body is in. Camera behind at shoulder height, pitch about +10°, yaw toward the side | Key 8. **Cued** at each guided stop once the stop turn (`Attitude.side_basis`) completes, so the body is beyond the rail | `look_direction("side")`; the tour's stop turn to 15° |
| **Sky aft** (9) | situation | Captain at the rail, camera above and behind, pitch about −60° over the rail: down the ship's levels toward the aft sky (floors block most of it, which is physics) | Key 9 only (never cued) | `look_direction("aft")` |
| **Arrival** | situation | Braking: Sky forward (cued). Arrived: the arrival card shows over Z2; at a guided stop, Sky side follows the stop turn | Phase changes from the sim (`ship.phase`) | Today's arrival keeps whichever free view was active |
| **Interlude / crossing review** | situation | The crossing review is a full panel (`ui/crossing_review.gd`). The camera **holds** Sky forward behind it and does not move while the review is open | `CardInterlude` active | Today: whatever view was active |
| **Sgr A*** | situation | The ship holds its nose on the hole (client attitude, `bh_*`). Sky forward frames the shadow overhead with the captain small below; 8 and 9 as above | Sgr A* visit | `look_direction` after `_apply_bh_world` |
| **Console focus** | console | `ShipConsoles.focus_pose`, unchanged: in front of the screen, looking down onto it. The captain is out of frame (§D4) | E or click at a station | The same dolly, now through the director |

**Cue rules.** A cued view starts only when no panel is open, the captain is not in console focus and the lift is not moving. It ends on any level key, any move key or `R`, and returns to the remembered level. A cue never pauses, holds or advances the sim; only the existing tour `attitude_hold` does that, and it is unchanged. With reduced motion on, cues become a HUD prompt ("Sky ahead · 7") instead of moving the camera.

**Getting to the anchor.** Sky forward and Sky side need the captain at an anchor. Pressing 7 or 8 auto-walks the captain there with the existing `ShipConsoles` walk path (3.5 m/s), as Tab "Walk to" does now. The view starts on arrival. If the captain is not on the bridge, the HUD prompt says "Sky views are on the bridge".

### D3. Third-person framing of the captain

- **The captain is always in frame**, except at console focus. The framing target is the head (foot + 1.6 m), placed on the lower-third line at Z1/Z2. At Z3 it is tracked within the place camera's ±25° range and marked with a ring.
- **Sprite angle.** The sprite is drawn for −14°. The boom pitches (−20° and −35°) and sector yaws (45° steps) keep the view within ~20° of the drawn angle. Sky views look up at the sprite; there the sprite is a dark silhouette by lighting (the spire key light from above, the sky behind), which the art brief allows ("show at most a silhouette or back view").
- **Facing.** The facing comes from screen motion (`CaptainAvatar.face`, unchanged). When standing, the captain faces away from the camera (back) in sky views, so the player looks where the captain looks.
- **Age** comes from `clock.tau` (unchanged). This is why third person serves Pillar 3.
- **The shadow** (`avatar_shadow`) is unchanged.
- **Crew and the Archive's presence** are framed by the same rules when they are on the bridge. That is out of this sprint's scope beyond keeping the clear-line test general (any `CharacterSprite` anchor).

**Does third person fit the chosen direction?** Yes, more closely than the current eye default:
- D-6 chose "isometric play areas ... The player walks around" with a captain avatar, and rejected first-person 3D.
- The characters brief sizes the captain for a play view (60–80 px; Z2 measures ~65–70 px at 720p).
- The bridge v2 decisions lock an iso camera family (yaw 45°, pitch −14°) for the painted plate. The sector yaws reuse its 45° diagonals.

The remaining difference from D-6 is perspective rather than orthographic (OQ8).

### D4. Console focus and the Crew console v2

The console view stays a **framed screen**, not the captain's eye. Today's `focus_pose` (1.25 m out, 0.55 m up, looking down at the screen) is kept. It moves into the director as view kind `console`, with the same 0.6 s ease (reduced motion: a cut, §D6).

Contract for the Crew console v2 (two-panel videocom):
1. **The camera does not move while a console is focused.** Panels, including both videocom panels, are 2D UI over a still frame.
2. **Wheel, trackpad scroll and pinch belong to the panel** while focused (the rule at `ship_geometry_demo.gd:365`). Level keys 1–3 are ignored, as today for 1–4.
3. **Step back** (E/Esc) returns to the remembered level and sector view, not to a stored tilt/yaw/pullback (`ShipConsoles._eye` goes away).
4. If v2 wants the captain visible (an over-the-shoulder pose for the videocom), it adds a `console` view to `views.json` with `anchor: station`. No code change in the director is needed.

### D5. Input mapping

All camera inputs become named `InputMap` actions (`camera_level_in`, `camera_level_out`, `camera_level_1..3`, `camera_sky_forward|side|aft`, `camera_default`, and the developer-only `camera_free_toggle`). `ShipControls` rows name the action, so NT5 (the control table matches the handler both ways) keeps holding.

| Action | Keyboard | Mouse | Trackpad (MacBook) | Controller |
|---|---|---|---|---|
| Level in / out | `=` / `-` | Wheel: **one notch = one level** (repeat ignored for 0.3 s) | Two-finger vertical scroll: accumulate `delta.y`; **one level per 1.0 unit** (one wheel notch), then 0.3 s cooldown. Pinch (magnify): one level per ×1.15 / ×0.87. Horizontal scroll is ignored | RB / LB |
| Level 1 / 2 / 3 | `1` / `2` / `3` | — | — | — |
| Sky forward / side / aft | `7` / `8` / `9` | — | — | D-pad up / right / down |
| Default view (Z2, sector) | `R` | — | — | R3 (right-stick click) |
| Walk | WASD (screen-relative) | Click a console or the floor to walk there | Click (tap) | Left stick (screen-relative) |
| Use / step back | `E` / `Esc` | Click | Click | A / B |
| Look | **none** | **none** (the pointer is always visible) | **none** (Option-drag removed) | Right stick: **none** |
| Developer free camera | `F8` (command-line launches only) | Free look and dolly as today | As today | — |

Notes:
- **Key 4** is freed (the diagnostic rim moves to the developer free camera). Keys 5/6 stay developer sky snapshots.
- **The pointer is never captured in a player launch.** Clicks aim at `event.position`, never the screen centre. Hover-to-highlight (`consoles.aim`) uses the real pointer.
- **Gesture accumulation** fixes the MacBook feel Mark reported: one deliberate swipe makes one step, not a drift.
- **Controller** support is new. The sprint adds the joypad events to the actions and a test with synthetic `InputEventJoypadButton` / `InputEventJoypadMotion`. Menus and panels are not made controller-navigable here; that is `input-rebinding.md` / `supporting-uis.md` work.

### D6. Transitions and accessibility (motion sensitivity)

| Transition | Default | Reduced motion |
|---|---|---|
| Level step | 0.45 s smoothstep on the boom | 0.15 s cross-fade cut |
| Sector switch | 0.8 s, yaw rate ≤ 90°/s | Cut at the boundary with a 0.15 s fade (hysteresis kept) |
| Cued sky view (in or out) | 1.5 s | **No camera move**: a HUD prompt instead |
| Player sky view (7/8/9) | 1.2 s after the walk | 0.15 s fade |
| Console focus | 0.6 s (today's dolly) | 0.15 s fade |
| Walking follow | Critically damped 0.25 s | Rigid follow (no lag) |

Everywhere:
- **No camera shake.** Dust-grain flashes (`interior/dust_flash.gd`) stay a light effect, never a camera kick.
- **No FOV change.**
- **No roll.**
- **Angular speed is capped at 90°/s.**
- **Easing never overshoots** (smoothstep, no spring overshoot).

The setting: `[display] camera_motion = "full" | "reduced"` in `settings.cfg` (`GameSettings`), on the title Settings screen and in the Tab panel beside the confirm mode. The default is `full`. It changes presentation only; no sim input.

### D7. Free look: developer and debug only

- `F8` (and `--free-camera` on the command line) toggles the **developer free camera**: today's mouse look, Option-drag, scroll dolly 0–300 m, presets 3 (external) and 4 (rim), and `reference_view()`. It shows only when `dev_controls()` is true (no `menu_return`). The HUD labels it "FREE CAMERA · developer", in the same place as today's "external pullback review — not captain eye".
- **Tools keep their API.** Captures, benchmarks and goldens call `camera.follow`, `set_preset` and `reference_view` directly (24 tools and tests, listed in §Migration). `CameraDirector.override(pose)` hands the camera to them, and `release()` returns it. `set_preset("overview")` and `"rim"` keep working for tools and the free camera only.
- **The menu-launch default is `mouse_look_enabled = false`.** `_sync_pointer` reduces to "visible, unless the developer free camera is on and no panel is open".
- **The Alpha Centauri bug.** A player can no longer lose mouse look, because there is none. That bug's symptom (the pointer captured or released at the wrong moment after an arrival) was in `_sync_pointer` / `pointer_required()`, and those still decide whether a click reaches a console. The separate investigation should still find the root cause; its regression test should run on the player path (the pointer stays visible and clicks reach consoles after arrival) and on the developer free camera.

### D8. Physics: the observer, the sky and the goldens

**Who observes.** The physical observer is the ship's rest frame. Every point inside the bubble shares the ship's four-velocity, so every point in the bubble is the same SR observer. Aberration and Doppler (spec §2: n → n′, D = 1/(γ(1−β cos θ′)), RS-1..) depend on the **view direction** and the **velocity**, not on where in the ship you stand. A third-person camera 4.5–12 m from the captain is therefore a ship-frame observer that the captain could be, a few metres away. For any given direction it sees exactly the sky the captain would see. The sky is at infinity: it is fixed under camera translation and changes only with orientation (the ship-interior brief §2, "fixed: at infinity").

**What translation does change,** and how it is already handled:

| Term | Depends on the camera position? | Handling |
|---|---|---|
| Catalogue stars, the galaxy, CMB, starbow | No (directions at infinity) | Unchanged. `sync_sky` passes the orientation; `position_m` does not enter the star projection |
| Bubble-wall glow (`ForwardGlow.wall_cos`, `glow_overlay.gdshader` `cam_ship`) | **Yes.** The ray leaves the sphere at a point that depends on the eye | Already computed from the real eye (`sync_sky` sets `cam_ship`). **New goldens at the new eyes** (G-CAM-2) |
| Dust-grain flashes (`dust_flash.gdshader` `cam_ship`) | **Yes** (the wall spot projection) | Already from the real eye. G-ISM-4/5 already cover off-centre and near-wall observers |
| Finite bodies at stops (planets, finite star discs) | Negligibly | A 12 m offset at 10⁴ km is 1.2 µrad (0.25″), against a pixel of ~0.11° (390″) at 720p: sub-pixel by ×1,500 |
| GR at Sgr A* (δ(ψ, r)) | Negligibly | A 12 m offset at the 1,000 AU stand-off is 8×10⁻¹⁴ in r. The GR goldens use their own sky camera and are unaffected |
| Exposure meter | Through the view only | A fixed FOV keeps `pano_px_per_screen_px` and the meter constant across levels. Turning (sector switches) is already covered ("Preserve the sky meter while turning the camera", dev.7) |

**The rules this design adds:**
1. **Inside the wall, always.** Every player eye has |eye| ≤ 95 m. Outside 100 m, `wall_cos` is NaN and `sync_sky` zeroes the glow pole: such a camera is not an observer inside the bubble, and its frame would need its own decision (OQ5). The external overview becomes developer-only.
2. **One observer, never painted space.** The sky is rendered through the **same camera pose** as the geometry (`sync_sky` every frame from the director's pose). There is no backdrop, no billboard sky and no plate behind a third-person camera. The D-6 parallax layers apply to the developer `--interior` composite, where the sky is fixed and the panorama and plates move, and they are unchanged. In the 3D ship, the depth layering comes from real geometry occluding the live sky.
3. **Fixed FOV (78°).** Zoom is a dolly. A narrower FOV would be a telescope: it would magnify the starbow's angular size and change the star PSF scale and the meter. A dolly changes neither.
4. **Perspective only.** An orthographic camera has parallel rays and cannot render a sky at infinity. In D-6 the sky came from a separate perspective panorama camera. Here one perspective camera renders both (OQ8).
5. **Precision unchanged.** Poses are float32 render transforms. The attitude stays the float64 `attitude_basis`. γ and 1−β come from the sim. No new lookup table.

**Goldens and physics checks affected** (names as in the Makefile `golden` target and `tests/test_physics.gd`):

| Check | Today | Effect | Action |
|---|---|---|---|
| **G-M4-S2** one tonemap (ship) | `_pose(30, 0.47)`, pullback 0 (captain eye) | The pose no longer exists for players | Keep the eye case (the physics is still valid) and **add** G-CAM-3: S2 at the Z2 Deck pose and at Sky forward |
| **G-M4-S3** forward pole (ship), ×3 phases | `_pose(89.99, 0)` at the eye | Sky forward pitches about +55°, with the pole off the frame centre and the eye off the captain | **Add G-CAM-1**: the pole pixel vs the CPU `unproject` of +Y×1000 from the Sky forward pose and the Sgr A* forward pose, ×3 phases |
| **G-M4-S4** glow, ×6 | `wall_cos` at the eye position | Glow depends on the eye: the new eyes are at 84–93 m, nearer the wall | **Add G-CAM-2**: `wall_cos` + the rendered glow at the Z1, Z2, Z3-bridge and Sky forward eyes, at 0.99c and cap 1−β 2e-9 (8 cases) |
| G-ISM-4/5 (wall observer, dim overlaps) | Off-centre observers | Already covers near-wall eyes | Unchanged; checked by re-running |
| Off-axis 144, background markers 16, stand-off 8, WD, cull, M1.5a, CMB 10, G-M4-1..6 (iso), GR1–GR12 | Sky camera / iso / hole | Do not use the ship player camera | Unchanged |
| Total `ok` count | 373 | +2 (S2) + 6 (S3) + 8 (S4) | **389**; the Makefile count line is updated in the same commit as the cases |
| `tests/test_physics.gd` AC4 (rolled and off-axis free-look camera, M1.6b) | `FreeLookCamera` (main.gd's sky viewer) | That camera stays (developer sky viewer) | Unchanged |
| `tests/test_physics.gd` **new: translation invariance** | — | — | **Add**: RS-1 (a 90° source at 0.9c appears at 25.842°) and RS-2 (60° at 0.5c), measured through the `ShipCamera` at each `views.json` eye vs the captain eye: the same apparent direction to 1e-9 rad (float64), the same `unproject` pixel to 0.05 px |
| Reference renders | — | — | `make camera-views-capture` → `renders/camera_views/*.png`: every view × {rest, cruise 0.99c, a guided stop, Sgr A*} at 1280×720 and 2560×1440. **Opened by eye** before merge (gate 2) |

No formula is added, so no `sunholo/relativity` release is needed. The glow and wall maths are already the package's mirror (`ForwardGlow`), and the new goldens use them unchanged.

### D9. Amendments after execution (2026-10-17 to 2026-10-19)

#### Under-way default (approved by Mark, 2026-10-17, attended)

**Mark's choice, verbatim: "Sky forward under way".** At rest the default is Z2 Deck; under way it is Sky forward, with the captain from behind and the starbow in frame; at a guided stop it is Sky side; at Sgr A* it is the hole view. Any zoom key returns to Z1 / Z2 / Z3.

Why: at 0.99c the sky is black across the deck and astern (spec §2: sideways and aft starlight is redshifted out of the visible), and the starbow is overhead. Z2 looks across the deck, so a cruise in Z2 showed the deck against black and lost the game's centrepiece. The implementation (`CameraDirector.default_view`, the commit / departure / braking cues, `under_way_view()`) is unchanged by this amendment. `tests/test_camera_director.gd` `test_default_mapping` pins the mapping.

#### Sgr A*: the hole view

At Sgr A* the cue (the visit's start and every stop's arrival) and R select `sky_hole`: the forward-sky view aimed at the hole's direction from the sim's GR state, with the hole 18 deg above the frame centre and the captain below. It frames the shadow and the ring at the 10, 5 and 3 r_s hovers and the 3 r_s orbit. The M3.6 visit framed the hole by looking straight at it in first person; the hole view keeps it framed in third person.

#### Authored angles: two rings and per-cell values

The design's single "camera on the spire side, looking outward" rule puts the Z2 eye inside the spire needle for any captain near the axis (512 blocked samples). The sectors therefore have a second ring: the stations ring inside 12 m looks inward across the consoles, and the rail ring looks outward over the captain toward the sky (1 m hysteresis). Where the sweep needs it, a view's `cells` map overrides a value for one cell (the lift landing at the spawn, the Commons streets). Z1 pitches -25 deg (from -20 deg) to clear the navigation consoles.

#### Lower deck (Commons): deferred to the deck-layout pass

The Commons views are authored per cell. The clear line still fails at 2 (Z1), 2 (Z2) and 39 (Z3) of 1,881 walk samples, points under the arcades' lintels that no candidate camera sees. These ceilings stay, held by `make camera-test`. They are **deferred to the deck-layout pass Mark asked for after the camera lands ("arrange the deck furniture and sightlines")**, which owns the fix. The current `z2_lower` and `z3_commons` frames are cluttered (a pillar fills about a third of the Z3 frame, and the captain is about 45 px); that pass should reshape the sightlines and then bring the ceilings to 0.

#### Trackpad and wheel direction

One convention: zoom in = closer = toward Z1. The wheel rolled up, a trackpad scroll up (pan `delta.y < 0`, the direction Godot also reports as wheel up) and a pinch open all come closer. A trackpad gesture is the run of its events with gaps under 0.5 s, so its inertial tail is part of it: one gesture steps at most one level, and its accumulator starts fresh with each gesture.

## Migration of tests and tools

**Behaviour changes** (rewritten red first):

| File | Today asserts | Becomes |
|---|---|---|
| `tests/test_ship_demo_input.gd` | Plain motion looks; Option and right-drag look; fractional scroll zooms smoothly; horizontal scroll doesn't zoom; lift and benchmark block | Menu launch: motion **never** turns the view; one wheel notch = one level; 0.25 + 0.25 + 0.5 trackpad units = one level, with the 0.3 s cooldown; pinch steps; horizontal scroll ignored; lift and benchmark still block; F8 free camera only in developer launches (then the old asserts run) |
| `tests/test_ship_ui.gd` (NT5, AC11) | `POINTER` rows "mouse look", "scroll / pinch to zoom"; key rows 1–4, R, 7–9 | New rows (levels, sky views, F8 dev). NT5 both ways; F8 absent on a menu launch |
| `tests/test_no_twitch.gd` (NT1/NT2) | The key and mouse sweep sends no decision | The sweep adds `=`, `-`, 1–3, 7–9, the joypad events and gestures. Cues over 600 s of fake time send no intent |
| `tests/test_ship_consoles.gd` | Focus stores tilt/yaw/pullback in `_eye`; the dolly; go_to faces at pullback 0 | Focus and step back return to the remembered **level and sector**; the dolly runs through the director; reduced motion makes it a cut |
| `tests/test_ship_demo_consolidation.gd` | Captain-eye default; "Reset restores captain eye" | The default is Z2 Deck, third person (the sprite is visible); R restores Z2 |
| `tests/test_tour_attitude.gd` | `_tour_view` lerps tilt to 89.5 / 15 | The departure turn cues Sky forward and a stop cues Sky side; `attitude_hold` timing is unchanged |
| `tests/test_navigation_usability.gd`, `tools/free_nav_review.gd` (F7) | Default mouse look; pointer released for panels | The pointer is never captured on a menu launch; panels and clicks are unchanged |
| `tests/test_ship_demo_lift.gd`, `test_ship_demo_journey.gd`, `test_ship_demo_live.gd`, `test_free_nav_stop.gd`, `test_manual_exposure.gd`, `test_title_screen.gd` | Use `set_preset` / `look_direction` / `pullback` as setup | Setup moves to `director.set_view(...)`, or keeps `set_preset` through `override`; the asserts themselves are unchanged. `test_title_screen` gains the `camera_motion` setting |
| `tests/test_galaxy_map.gd`, `test_loading_jump.gd` | Map zoom (pinch, wheel) | **Unchanged** (not the player camera) |

**Tools that keep the old API through `override`** (a smoke run in the sprint, no rewrite): `ship_demo_capture`, `ship_ui_capture`, `ship_commons_capture`, `ship_lighting_capture/bench`, `ship_star_light_capture/bench`, `ship_star_identification_capture/bench`, `ship_contact_capture`, `ship_demo_journey_capture`, `ship_demo_live_capture`, `ship_demo_movie`, `bh_ship_capture/bench`, `ism_hud_capture`, `ism_golden`, `stops_capture`, `solar_departure_bench`, `recent_feature_movies`, `m4_ship_golden`.

## Acceptance criteria

Every row is a command. `make camera-test` joins `ship-demo-ci`, so it is in `make test`. `golden` and `camera-views-capture` need a GPU window.

| # | Criterion | Command |
|---|---|---|
| 1 | `data/camera/views.json` validates: every view's eye has \|eye\| ≤ 95 m at every walkable sample of `walk_bridge.glb` / `walk_lower.glb` (sampled at 0.5 m), with a clear line to the captain's head; FOV 78° for every player view; a mutant view at 26 m / −50° fails | `make camera-test` |
| 2 | Exactly three levels. One wheel notch, 1.0 accumulated trackpad unit, one pinch step, `=`/`-`, RB/LB each move exactly one level, with the cooldown; no input moves the camera continuously on a menu launch | `make camera-test ship-demo-input-test` |
| 3 | Mouse motion, Option-drag, right-drag and the right stick never change the camera pose on a menu launch; the pointer is never captured on a menu launch | `make ship-demo-input-test free-nav-recovery-test` |
| 4 | Every player view puts the captain's head in frame (except `console`); Z2 captain height is 60–80 px at 1280×720 (measured from the sprite's projected anchor and height) | `make camera-test` |
| 5 | Sector switching has 10° hysteresis; walking across a boundary with W held keeps the world direction until release; no pose jump > 1 cm or 0.5° per frame at 60 Hz in full motion | `make camera-test` |
| 6 | Cues: departure → Sky forward, guided stop → Sky side, braking → Sky forward, Sgr A* → Sky forward; none fires with a panel open, at a console or in the lift; any level, move or R key ends it; reduced motion makes cues prompts | `make camera-test tour-attitude-test` |
| 7 | Reduced motion: every transition ≤ 0.15 s and no camera travel; full motion: angular speed ≤ 90°/s, no roll, no FOV change, no overshoot (sampled over every transition in the table in §D6) | `make camera-test` |
| 8 | Console focus and step back go through the director and restore level and sector; wheel, scroll and pinch at a console never move the camera | `make ship-console-test` |
| 9 | The developer free camera (F8 / `--free-camera`) exists only when `dev_controls()`; all listed tools still run through `override` | `make camera-test ship-ui-test && make ship-demo-capture` |
| 10 | No decision intent from any camera input or cue (NT1); the control table and the handler match both ways (NT5) | `make no-twitch-test ship-ui-test` |
| 11 | Translation invariance: RS-1 and RS-2 through every view eye equal the captain eye to 1e-9 rad and 0.05 px | `make test` (in `tests/test_physics.gd`) |
| 12 | G-CAM-1 (6), G-CAM-2 (8), G-CAM-3 (2) pass on the GPU; total `ok` count 389 | `make golden` |
| 13 | Renders of every view × {rest, 0.99c, stop, Sgr A*} at both sizes exist and are opened by eye (author and evaluator); the capture fails if a player view has \|eye\| > 95 m or no captain in frame | `make camera-views-capture` |
| 14 | Everything else stays green | `make test` |

## Sub-milestones and estimates

| # | Milestone | LOC | Depends on |
|---|---|---|---|
| C1 | `CameraDirector`, `views.json` + schema, levels Z1–Z3 on the bridge, sectors, input actions (keys, wheel, trackpad, pinch, joypad), the console dolly folded in | ~550 | — |
| C2 | Situation views: Sky forward/side/aft with anchors and auto-walk, cues (tour departure/stop, braking, Sgr A*, interlude hold), lift and lower-deck views | ~350 | C1 |
| C3 | Developer free camera (F8, `override`), pointer simplification, the `camera_motion` setting (title + Tab), HUD labels | ~200 | C1 |
| C4 | Physics: `test_physics.gd` invariance, G-CAM-1/2/3 in `tools/m4_ship_golden.gd`, `make camera-views-capture` | ~250 | C2 |
| C5 | Test migration (the table above), tool smoke runs, CHANGELOG fragment | ~350 | C1–C3 |

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| The spire or the lift blocks the captain in some sector (a capture showed the lift filling a low sky view at the spawn) | Clear-line check over every walk sample (AC1). Sky views use authored anchors, not the captain's current spot |
| Sector switches feel like a camera "swing" | Hysteresis, a 90°/s cap, held walk direction, reduced-motion cuts. Mark reviews `renders/` and a movie (`ship_demo_movie` through the director) |
| The billboard sprite looks flat from the sky views (looking up) | A silhouette by lighting is allowed by the art brief. If Mark dislikes it, a back-view-from-below sprite is an art task (D-7 generate-and-cache), outside this sprint |
| Players miss looking at any sky direction | Three sky views + `I` identification in every view. OQ2 offers 90° rotation if the playtest wants more |
| Tools and goldens silently change pose | `override` keeps their exact API; the golden count is pinned (389), so a lost case fails |
| Overlap with the Crew console v2 | §D4 contract; the console view is data |
| The Alpha Centauri pointer bug masks a click failure | §D7: its regression test runs on the player path too |

## Open questions for Mark (with recommendations)

**Answered 2026-10-16 (attended, Mark: "yes continue"): every recommendation below is accepted as written.** OQ1 three levels; OQ2 no player camera rotation in R2 (the slice decides the angle); OQ3 first person gone everywhere, console focus stays a framed screen; OQ4 automatic situation cues, any input takes over, reduced motion uses prompts; OQ5 no exterior view in this sprint; OQ6 the default is Z2 Deck; OQ7 keep a developer free camera; OQ8 perspective; OQ9 the zoom ruling is recorded in the ledger by the attended session (this branch does not edit the ledger).

| # | Question | Recommendation |
|---|---|---|
| OQ1 | How many zoom levels, and what does each frame? | **Three**: Close (captain and reach), Deck (room scale, default, the 70 px art scale), Whole level (a per-area place camera). Two loses the room scale; four adds steps nobody needs |
| OQ2 | May the player rotate the authored yaw (90° steps, e.g. `Q`/`` ` `` and the bumpers), or is the yaw always the sector's? | **Sector only for R2**: fully authored, fewest inputs. Revisit after a playtest of dev.32 |
| OQ3 | Is first person gone everywhere, including the sky views? | **Yes.** Sky views are third person with the captain's silhouette. Console focus stays a framed screen (not the captain's eye). Developer free camera only |
| OQ4 | Should the camera cut to situation views on its own (departure, stops, braking, Sgr A*)? | **Yes, by default**, ended by any camera or move input; with reduced motion they become prompts |
| OQ5 | An exterior shot of the ship (departure or arrival cinematic) for players? | **Not in this sprint.** A camera outside the wall is not an observer inside the bubble; it needs its own physics decision (what an outside observer sees, the wall from outside) and an exterior art pass |
| OQ6 | The default level at launch and after R? | **Z2 Deck** |
| OQ7 | Keep a developer free camera? | **Yes**, F8 / `--free-camera`, command-line launches only; captures and goldens depend on it |
| OQ8 | Orthographic iso (as D-6's play layer) or perspective? | **Perspective, 78°**: one camera must render the sky, and an orthographic camera cannot. The sector yaws reuse the iso 45° family for the sprite |
| OQ9 | Record the ruling as a ledger row? | **Yes**, attended: R1 as a RESOLVED row citing the verbatim quote; OQ1–OQ8 as one OPEN row answered with the sprint approval |

## Evidence: today's views and candidates (captured 2026-10-16)

These were captured from a fresh clone at `origin/main` 13bcc40 with a throwaway script (not committed), `godot --path . --script`, at 1280×720, at rest and in the `sky_review.json` cruise snapshot (0.99c, γ 7.09). Every image was opened.

| Shot | Eye (m), \|eye\| | What it shows | Fixed view that replaces it |
|---|---|---|---|
| Today: default eye (preset 1) | (8, 83.7, −4.8), 84.2 | Floor and rail at the eye, the lift's corner at the left edge, no captain | Z2 Deck |
| Today: look forward (7), 0.99c | 84.2 | The starbow straight up, first person, no ship and no captain | Sky forward (captain silhouette under the starbow) |
| Today: scroll pullback 25 m | 93.7 | Near the wall; 6 m more crosses it | Z3 (place camera inside the envelope) |
| Today: preset 3 "whole ship" | (145, 90, 145), **223.9** | Outside the bubble: the glow pole is zeroed; not a ship-frame interior observer | Developer only |
| Today: console focus (navigation) | 84.2 | The panel fills the frame | Unchanged (console view) |
| Candidate Z1 (4.5 m, −20°) | 85.6 | The captain at ~150 px beside the lift; the rail and the spire's lamps behind | Z1 Close |
| Candidate Z2 (12 m, −35°) | 91.1 | The captain at ~65 px, the lift, the deck and rail, the spire base; reads like the D-6 room | Z2 Deck |
| Candidate boom 26 m, −50° | **104.6** | The whole disc, but **outside the bubble** | Rejected; this is why Z3 is a place camera |
| Candidate Z3 rim camera (−14, 91, −10) | 92.6 | The whole bridge: the spire, every station, the lift, the captain small by the lift | Z3 Whole level |
| Candidate low sky view at the spawn | 82.8 | The lift wall fills half the frame; the starbow is in the other half | Why Sky views need an authored anchor clear of the lift |

Sketches of the proposed set (the bridge seen from above; S = spire, L = lift, c = captain, ◎ = camera):

```
  Z1/Z2 (sector boom, outward)        Z3 (rim place camera)           Sky forward (from the side)
        .-~~~~~~~-.                         .-~~~~~~~-.                         * * starbow * *
     .'   rail      '.                   .'      ◎      '.                     *   (pole, +Y)  *
    /     c  ←◎      \                  /    ↙ looks      \                          ↑
   |        ↖  S      |                |   across  S       |                   c  (silhouette)
    \   L             /                 \  L   c          /                  ◎ low, behind, pitch +55°
     '.            .'                    '.            .'               ───────── bridge deck ─────────
        '-.______.-'                        '-.______.-'
  camera on the spire side, sky         eye ≤ 93 m from centre        eye ≈ deck + 0.4 m, ≤ 95 m
  behind the captain
```

## Deliverables

- `demos/camera_director.gd`, `data/camera/views.json` (+ schema and the export row in `export_presets.cfg` / `tests/export_audit.gd`).
- Edits to `demos/ship_geometry_demo.gd` (input → actions, `_zoom`/`look_direction`/presets through the director, `_sync_pointer`), `demos/ship_consoles.gd` (focus via the director), `demos/ship_demo_camera.gd` (no change to `sync_sky`), `ui/ship_controls.gd`, `ui/game_settings.gd`, `project.godot` (the InputMap actions).
- `tests/test_camera_director.gd` and `make camera-test`; the migrated tests in the table above; `tests/test_physics.gd` invariance cases.
- `tools/m4_ship_golden.gd` G-CAM-1/2/3 and the Makefile golden count; `tools/camera_views_capture.gd` and `make camera-views-capture`.
- A CHANGELOG fragment in `changelogs/unreleased/`; the design repo's roadmap row on landing.
