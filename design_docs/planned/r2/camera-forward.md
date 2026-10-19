# R2-CAMERA-FORWARD: fixed views per level that slide with the captain and never turn

**Status:** Planned. Awaiting Mark's approval of this doc and its sprint plan ([camera-forward-sprint.md](camera-forward-sprint.md)). Independent plan review (Sonnet): round 1 71 with 4 blocking, round 2 86 with 0 blocking; all findings folded in (`.ailang/state/evaluations/eval_R2-CAMERA-FORWARD_plan_round_{1,2}.json`).
**Release:** R2. **Milestone:** the player camera for the 3D ship, corrected after the dev.33/dev.34 playtest (ledger D-91). Amends R2-CAMERA ([implemented/r2/camera-fixed-views.md](../../implemented/r2/camera-fixed-views.md), D-83).
**Priority:** P1 for R2. Every session runs through this camera. The paused deck-layout sprint (D-90, branch `feat/deck-layout` at 7863c831) is re-planned on top of it.

**Mark's direction** (attended, 2026-10-19, verbatim):
> we misunderstood what a fixed camera meant. as I walk around we can still see the whole ship, and I get a confusing new perspective where my buttons now dont travel to the right direction. I also now miss the good views of the onward forward facing jounrey and as I walk around lose the view of the planet/sun etc we are visiting. the fixed camera is meant to make it simpler by having fixed perspective and the player walks around in that.

He then chose **"Slide, never turn"** (D-91), and added:
> I dont know if its possible to have the side view and forward view ivisble in same frame, so perhaps its a hot key to look between them?

> we can have a few fixed views possible, but yeah at least one forward looking, one planet facing (same as navigation around ship?) and maybe when we sue consoles it zooms in - we take advantage of the 3d blender model but for visuals, not a 3d game - does that make sense? we did consider isometric at one point but this was early designs, but its really just to give the sense of scale

> we are just on the bridge for now, but as we go down through the levels we will have similar fixed caemra views as we explore them - more like a 2d/2.5d platform game? able to explore the layers

> this way we dont have to dress full on 3d environemtns and can get a sense of style and taste for each level that is in keeeping with the concept art, relying on paralax etc. to help give sense of scale

**What this doc takes from that:**
- **The 3D ship is a presentation stage, not a free 3D game.** It is a diorama that gives scale. The Blender model is used for visuals.
- **Each level has a small set of authored, fixed views.** A view's angle never changes while the captain walks. The camera slides to keep the captain in frame.
- **On the bridge:** a Forward view (the journey ahead), a Target view (the body being visited), a Deck view (walking among the stations), and a Console zoom.
- **Moving between levels** (the lift today, stairs later) cuts or eases to that level's views. The ship reads as stacked layers, explored like a 2.5D platformer.
- **Only what a view sees gets dressed.** Depth comes from parallax layers. The sky layer stays the live SR/GR render.

**Implements** (design repo):
- [vision/design-decisions.md, 2026-09-28 "Interior: Isometric Three-Layer View From Inside the Bubble" (D-6)](https://github.com/sunholo-data/stapledons-design/blob/main/vision/design-decisions.md).
  - Superseded in its projection: no orthographic iso camera, because one perspective camera must render the sky (R2-CAMERA OQ8).
  - Kept in its purpose: the captain walks among the crew at room scale, with parallax layers behind (play area 1:1, ship structure slower, the sky fixed at infinity).
  - D-6's "the bridge's dome is the bubble's forward pole; the starbow gathers overhead there" is why the Forward view looks up.
- [art/ship-interior-blender-brief.md §2](https://github.com/sunholo-data/stapledons-design/blob/main/art/ship-interior-blender-brief.md): up is forward, and the sky is at infinity, "fixed when the camera pans".
- [features/future/sr-view-directions.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/sr-view-directions.md): forward, side and aft show different physics. That decides which directions earn a view (§D5).
- [features/phase2-core-views/multi-level-ship-visualization.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase2-core-views/multi-level-ship-visualization.md) and [ship-exploration.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase2-core-views/ship-exploration.md): the ship's levels, the spire through them, and the vertical position the player must be able to read. The level-keyed views (§D7) are their camera half.
- [features/scene-based-interior-navigation.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/scene-based-interior-navigation.md) (2025-12-20, "fixed-camera scenes per deck … with parallax"). The idea returns here, now with a walking avatar and a live sky.
- [physics/relativity-spec.md §2](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md) (a moving observer: aberration and Doppler depend on direction only) and the GR section (the hole view).
- Ledger: D-6, D-14 (up is the direction of travel), D-52 A (the 3D ship is the game), D-83 (R2-CAMERA), D-90 (deck layout, paused), D-91 (this ruling).

**Depends on:** nothing upstream. There is no new physics formula, so `sunholo/relativity` is untouched (gate 3 holds trivially). The sky is rendered through the camera pose exactly as today (`ShipCamera` stays the render boundary).

**Estimated LOC:** about 1,320 in all: about 700 of product code (the sector machinery goes for the bridge but stays fenced for the Commons) and about 620 of tests, tools and caller migration. The sprint plan schedules 4 days.

## Game vision alignment

Scored with the `game-vision-designer` skill (feature-validation mode, against `vision/core-pillars.md`, D-6 and D-91), 2026-10-19. **ALIGNED.**

| Pillar | Score | Rationale |
|---|---|---|
| Choices Are Final | 0 | The camera takes no decision. The R2-CAMERA no-twitch tests (NT1–NT5) stay |
| The Game Doesn't Judge | 0 | Neutral |
| Time Has Emotional Weight | +2 | The journey stays in frame under way, with the starbow overhead and the destination ahead. The captain's ageing figure is on screen in every walking view |
| The Ship Is Home | +2 | A stable stage: the deck no longer spins under the player, so its layout can be learned like a home. The levels become layers to explore (the 2.5D model) |
| Grounded Strangeness | +2 | Every sky the player sees is the physics render through the same pose. The Forward view frames the pole wherever the captain walks; the Target view keeps the real body in frame; the Deck view shows the side sky going dark at speed |
| We Are Not Built For This | +1 | Scale comes from parallax and framing: a small figure under a vast sky, with the ship's structure between |
| **Net** | **+7** | **Go.** No pillar is negative |

## Problem

What happens on `origin/main` (5118cc2), measured by `tools/camera_walk_capture.gd` (added by this PR) over a scripted walk around the spire. There are 8 angles × 2 radii (10 m and 17 m) on the bridge, sampled at rest (default Z2) and under way (a committed voyage at β = 0.90, default Sky forward):

| Pass | Samples | Camera yaw spread | Forward pole in frame | Captain's head in frame |
|---|---|---|---|---|
| rest, Z2 (sector booms) | 16 | **180°** (yaw = sector centre + ring turn) | 0 | 16 |
| under way, Sky forward (`yaw_rule: tangent`) | 16 | **180°** (yaw = the captain's ring angle + offset) | 16 (y = 82 px at 720p) | 16 |

Evidence (opened by eye: the contact sheet, `rest_r10_0` and `under_way_r10_3`):
- https://storage.googleapis.com/stapledons-voyage-assets/refs/camera_forward/before/contact_sheet.png
- The 32 frames and `walk.json` are in the same folder.

What the numbers mean:
1. **The ship turns under the player.**
   - Z2's yaw is `sector_centre + turn_deg[ring]` (`CameraDirector.sector_yaw`). Over a walk around the spire it takes every value, which is what Mark saw as "a confusing new perspective".
   - Sky forward's yaw is `atan2(foot) + offset` (`CameraDirector._sky`), so it also turns with every step around the ring.
2. **The keys change direction on screen.**
   - `walk_yaw()` is screen-relative, as R2-CAMERA's D2 intended, but the screen itself turns.
   - After a sector switch the same key moves the captain a different way across the deck. A held key is "held direction" for one swing, then it changes.
3. **The journey leaves the frame.**
   - At rest and at Z1/Z2/Z3 the pole is never in frame (pitch −20° to −35°). The planet or sun beside the ship is in frame only from some sectors.
   - Under way, the Sky forward view keeps the pole but turns with the walk, so the Milky Way and the bodies wheel around it.
4. **One framing cannot hold both the deck and the starbow.** This is physics and geometry, not a bug; see §D2's table. The pole is straight up (D-14, D-6: the bridge dome is the forward pole). At FOV 78° (vertical), the pole is in frame only at pitch ≥ 51°, and then no deck surface is visible. That is why Mark's "hot key to look between them" is the right model.

## Goals and non-goals

**Goals**
- G1. **Fixed views:** a view's yaw and pitch never change while the captain walks. The camera slides (translation only) to keep the captain framed.
- G2. **The bridge's views:** Forward (default under way), Target (default at a stop, the body being visited, or the hole at Sgr A*), Deck (default at rest, walking among the stations), and Console (a zoom onto a screen that returns to the previous view).
- G3. **Constant, screen-relative controls:** W is up-screen, S down, A left and D right in every view. The mapping changes only when the player (or a cue) switches view, and then it eases once.
- G4. **Level-keyed view data:** each level has its own small set of views in `data/camera/views.json` (schema v2). Moving between levels selects that level's default view. The bridge is fully authored in this sprint; the Commons keeps its current views until its own pass.
- G5. **The physics is unchanged:** the sky is rendered through the same pose. The goldens' camera cases (G-CAM-1..3) are re-pinned to the new eyes with the same case counts.

**Non-goals**
- Dressing or rearranging the deck: that is the re-planned deck layout (§D9).
- An inset window showing a second direction: later and optional (Mark: "perhaps its a hot key"). Not in this sprint.
- New levels below the Commons, stairs, or an exterior shot.
- Orthographic projection (one perspective camera renders the sky; R2-CAMERA OQ8 stands).

## Design

### D0. The model: a stage, levels as layers

- **The ship is a set of stacked layers along the travel axis:** bridge (top, under the forward dome), Commons, and future levels below.
- **Each layer has a few authored views.** A view is a fixed direction (yaw, pitch) and a framing (distance behind and above the captain, dead zone). The camera's only motion while walking is a slide parallel to itself.
- **Switching views is deliberate:** a key, a console, or a situation cue (departure, a stop, braking, Sgr A*). Switches ease once (full motion) or cut (reduced motion), as R2-CAMERA's D6.
- This is the "2.5D platformer" reading. Inside a level you walk a stage seen from a fixed side. Going down a level is a cut to the next stage.

### D1. Slide-follow (all walking views)

- **Rig:** `eye = foot − flat(yaw) × back_m + up × rise_m`, where `flat(yaw)` is the horizontal unit vector of the view's yaw. This is today's sky-view rig (`CameraDirector._sky`), now with a yaw that never changes. The basis is `basis_of(yaw, pitch)` and is never re-aimed at the captain.
- **The eye never goes below the deck:** `rise_m ≥ 0.3` is a schema rule, and a test (AC5) checks `eye_y ≥ deck_y + 0.3` at every walk sample. The captain's head is then above the eye in Forward (28° above the horizontal at 2.4 m back), which puts the head inside the frame (pitch 56° − 39° = 17° bottom edge).
- **Dead zone:** the camera starts sliding only when the captain's projected head leaves a central box. The box is 24% of the width by 20% of the height at 720p, and it is data.
- **Follow:** critically damped (time constant 0.25 s, the existing `FOLLOW_S`). This holds R2-CAMERA's eye-acceleration cap of 36 m/s² (AC5).
- **Bounds:**
  - The eye stays inside the 95 m envelope. A clamp now slides the eye along the deck plane instead of along a boom, so the angle is untouched.
  - Each view may carry an `xz` slide box. At its edge the camera stops and the captain walks toward the frame edge.
- **Occlusion:** the spire, the lift and tall props can sit between the camera and the captain at some deck positions, because the yaw no longer turns away from them.
  - **Fix:** the occluder fades. New machinery, budgeted as its own sub-milestone (F1b). The nodes are named, not inferred: the spire mesh(es) under the geometry's `Spire*` nodes and the lift's visible boxes (`lift_boxes()`), added to a Godot group `camera_occluder` at scene build. While their AABB crosses the camera-to-captain segment (the same test `view_clear` already uses for the lift), their material's alpha eases to 0.25 over 0.2 s (`advance(dt)` time, no wall clock), restored the same way.
  - **Fallback** if a dither material is not cheap on those meshes: hide the occluder's `MeshInstance3D` while it crosses (a cut). Either way the test counts "after fades" as: hits against nodes outside `camera_occluder` only.
  - **Not allowed:** turning the camera.
  - The bridge's clear-line sweep (`tests/test_camera_director.gd` `sweep`) becomes "0 blocked samples after fading". Untagged geometry must never block.
  - **Physics:** fading touches ship meshes only. The sky layer is never dimmed or masked by it. A test asserts that a fade changes no sky uniform and no sim input. `camera-views-capture` adds one frame with a forced fade, opened by eye, to check the sort order against the sky.

### D2. Forward (the journey)

**Measured trade-off.** FOV 78° is vertical, so the half-angle is 39°. At 1280×720:

| Pitch | Pole in frame | Pole y (px) | Frame below the eye's horizon | Rest-frame 90° stars in frame at 0.9c / 0.99c / 0.999c |
|---|---|---|---|---|
| 10° | no | −2161 | 39% | no / no / no |
| 30° | no | −410 | 14% | yes / no / no |
| 45° | no | −85 | 0% | yes / yes / no |
| 51° | yes | 0 | 0% | yes / yes / yes |
| 56° (proposed) | yes | 60 | 0% | yes / yes / yes |
| 58° (today's Sky forward) | yes | 82 (measured: 82.2) | 0% | yes / yes / yes |

Rest-frame 90° stars appear at 25.8°, 8.1° and 2.6° from the pole at 0.9c, 0.99c and 0.999c (relativity-spec §2 aberration). At the guided voyage's speeds, the starbow is only in frame with the pole.

**The view:**
- Yaw is fixed per level: `yaw_deg` in the data. The bridge's Forward yaw is chosen in F1 by the sweep: the yaw with the fewest occluder fades over the bridge walk.
- Pitch 56° keeps the pole about 60 px below the top edge at 720p.
- The eye is 2.4 m behind the captain's feet (horizontally) and 0.3 m above the deck, as today's Sky forward (2.2 m, 0.3 m). The captain is a silhouette in the lower part of the frame: today's measured head is y = 590 px at 720p.
- It slides with the captain and never turns.
- **Walking in it:** the captain stays near the bottom centre. W walks up-screen, which is away from the camera along the yaw.
- The deck surface is not visible (the table above). Walking in Forward is for watching, and Deck is the walking view. The HUD's console prompts still work by proximity.
- **Default under way:** departure, cruise and braking cue it. At Sgr A* the cue is the hole view (§D3), as today.

### D3. Target (the body being visited)

**What Mark likely means by "same as navigation around ship?"** Today, at each guided stop, the ship makes a stationary attitude turn so the body sits beside the rail (`_begin_tour_turn(Attitude.side_basis(rel_km), …)`). The camera is then cued to "Sky to the side" (`director.sky("sky_side", true)`). That stop view, "navigating around" the planet, is the closest existing thing, so Target generalises it. The Navigation station's chart (`ui/galaxy_map.gd`), which orbits a camera around the ship and system, is a different, map-only view, and nothing here changes it. Open question OQ2 checks this reading.

**The view:**
- **What it aims at, in order:**
  - the hole at Sgr A* (`hole_direction()`, as `sky_hole` today);
  - otherwise the current stop's body, its `rel_km` taken into the ship frame by the attitude basis (the same transform as `hole_direction`);
  - otherwise the destination (the forward pole).
- **Yaw:** the aim's horizontal bearing, fixed while the captain walks.
- **Pitch:** the aim's elevation, clamped to [−10°, 60°] and offset so the aim sits in the upper third of the frame.
- **Framing:** the eye is 4.0 m behind the captain's feet along the aim's bearing and 0.6 m above the deck. The captain is in the lower third with the body beyond the rail.
- **Re-aim rule:** the target only moves when the ship turns or the body drifts. Re-aim with one ease when the aim leaves the middle 60% of the frame, and never because the captain walked. At a stop, 1 ship second per second, a planet drifts far less than that within a dwell.
- **Default at a stop:** it replaces today's Sky-to-the-side cue at a stop, and replaces `sky_hole` at Sgr A* (same aim and offset, now a Target view).
- **Measured (AC1, AC2):** with the ship stationary (a guided stop's dwell, or a Sgr A* hover, held), the 16-sample walk causes no re-aim. So Target's yaw spread is checked like the others, and the target is in frame at every sample. Re-aim is tested separately (AC6b), by moving the aim, not the captain.

### D4. Deck (walking among the stations)

- Yaw is fixed per level; F1 chooses the bridge yaw by the sweep, as for Forward.
- Pitch is −30°. The eye is 10.4 m behind the feet and 7.6 m above the deck, that is, a 12 m boom at −30° from a 1.6 m head. (Today’s Z2 boom is −35° with its look tilted up by `frame_deg` 15.1°, so it looks down about 20°; the measured walk pitch is −19.9°. F1a sets Deck’s pitch by the same 60–80 px figure band and records it.) The captain is then 60 to 80 px at 720p (R2-CAMERA AC4’s band).
- It slides with dead zone and bounds (§D1), and never turns.
- This is the D-6 "room scale" view. Stations, crew and the rail are readable, and the side sky shows above the rail.
- **Default at rest,** and after a console when the previous view was Deck.

### D5. Switching views: keys, cues, and side and aft

| Key (pad) | Today | Proposed |
|---|---|---|
| 7 (D-pad up) | Sky ahead (forward) | **Forward** |
| 8 (D-pad right) | Sky to the side | **Target** (the body; Forward when there is none) |
| 9 (D-pad down) | Sky astern | **Deck** |
| R (R3) | default view and level | default view for the situation (under way: Forward; at a stop: Target; else Deck) |
| +/− (RB/LB), wheel, pinch | Z1/Z2/Z3 | see OQ4 (recommendation: removed for players; Console is the only zoom) |
| E at a console | console focus | Console, unchanged; Esc or walking away returns to the view before it |

- **A switch eases once:**
  - The basis moves at ≤ 90°/s with a 1.2 s floor; under reduced motion it is a 0.15 s fade cut.
  - Then the view is fixed again.
  - The WASD mapping switches to the new view's screen axes at the end of the ease. During the ease the keys keep the old mapping, so a held key never turns mid-step.
- **Cues** keep R2-CAMERA's rules (C2). A cue starts only with no panel open, not at a console and not in the lift, and it is a prompt under reduced motion. Departure, cruise and braking cue Forward; a stop or Sgr A* cues Target.
- **Side and aft as views:**
  - **Side:** recommendation, fold into Target and Deck. The side sky's physics (at speed it goes dark and red, sr-view-directions) is visible above the rail in Deck and beyond the body in Target.
  - **Aft:** recommendation, drop it for players. Straight aft looks through the deck ("floors correctly block the aft sky", the HUD's own line), so it is mostly hull. At speed the aft sky is the darkest, most redshifted part, which a dedicated view would only show as black.
  - Keep `sky_aft` for tools and goldens. See OQ3.

### D6. Console focus, tour turns and the captain sprite

- **Console:**
  - `ShipConsoles.focus_pose` is unchanged. It frames the screen and may turn to face it.
  - `restore()` returns to the view (not the level or sector) that was active before. The camera's yaw is back exactly where it was, so the controls are too.
- **Tour turns:** the player camera is already cued, never turned (R2-CAMERA C2). Under this model:
  - a departure turn cues Forward;
  - a stop turn cues Target once the turn ends;
  - the ship's attitude turn itself rotates only the sky (the attitude basis), never the camera.
  - The developer free camera keeps the old first-person turn (`director.overridden`).
- **Captain sprite:**
  - The yaw is fixed, so the sprite's facing is just the screen direction of motion (front, back, ne, se and their mirrors). It no longer depends on a swinging camera.
  - Forward and Target show the captain from behind (`back`, upright billboard), as the sky views do today.
  - The sprites were drawn for a −14° iso pitch. At Deck's −30° they read as today's Z2 does (R2-CAMERA AC4, 64 px at 720p).

### D7. Data: `views.json` schema v2, level-keyed

```json
{
  "schema": "stapledons.camera.views/2",
  "fov_deg": 78.0, "envelope_m": 95.0,
  "levels": {
    "bridge":  {"deck_y_m": 82.0, "default": {"rest": "deck", "under_way": "forward", "stop": "target"},
                "views": [
                  {"id": "forward", "kind": "forward", "yaw_deg": Y, "pitch_deg": 56.0, "back_m": 2.4, "rise_m": 0.3, "dead_zone": [0.24, 0.20], "slide_box_m": [...], "ease_s": 1.2},
                  {"id": "target",  "kind": "target",  "pitch_clamp_deg": [-10.0, 60.0], "aim_frac": 0.33, "back_m": 4.0, "rise_m": 0.6, "reaim_frac": 0.6, "ease_s": 1.2},
                  {"id": "deck",    "kind": "deck",    "yaw_deg": Y, "pitch_deg": -30.0, "back_m": 10.4, "rise_m": 7.6, "dead_zone": [0.24, 0.20], "ease_s": 0.6},
                  {"id": "console", "kind": "console", "ease_s": 0.6}]},
    "commons": {"deck_y_m": 57.0, "legacy": true, "views": [ ...today's z1_lower / z2_lower / z3_commons, unchanged ... ]}
  }
}
```

- `validate()` checks:
  - every level has a `default` for each situation that names one of its own views;
  - non-legacy walking views carry a fixed `yaw_deg` (except `target` and `console`);
  - every walking view has `rise_m ≥ 0.3` (the eye stays above its deck);
  - no view changes FOV;
  - the envelope.
- Negative controls cover each rule.
- **The Commons is `legacy: true`.** It keeps today's sector views, data and code path until its own pass (§D9). The sector code is fenced to legacy levels, and bridge views can no longer use it.
- **Level changes:** arriving at a level (the lift's arrival) selects that level's default view: a cut in reduced motion, the view's ease otherwise.

### D8. Physics: the observer, the sky and the goldens

- **The sky is rendered through the same pose** (`_sync_observer()` after every director write), unchanged. The observer's position inside the bubble only matters through the glow and wall terms, which the goldens already check from player eyes.
- **Goldens:** `make golden` keeps 393 ok lines. The R2-CAMERA cases move to the new eyes:
  - The counts and case shapes stay as they are; only the poses change. `_pole()` checks three phases per pose, as today.
  - **G-CAM-1** (forward pole, 9) = Forward at `spawn` (3) + Forward at `helm` (3) + Target aimed at the hole with `hole_override = UP` (3), replacing Sky forward spawn/helm and the hole view. The pole is within 0.75 px of the CPU reference.
  - **G-CAM-2** (glow, 8) = 4 eyes × {0.99c, cap}: Deck at `spawn`, Deck at the rail (the eye nearest the wall, replacing Z3), Forward at `spawn`, Target (hole aim) at `spawn`. These replace z1, z2, z3_bridge and sky_forward.
  - **G-CAM-3** (one tonemap, 2): Deck and Forward at `spawn`, 0.99c (replacing Z2 and Sky forward).
  - The Makefile pins (`G-CAM-1` 9, `G-CAM-2` 8, `G-CAM-3` 2, 393 ok lines) are unchanged. The labels change to name the new views. The recipe’s grep prefixes (`G-CAM-1 forward pole`, `G-CAM-2 glow`, `G-CAM-3 one tonemap`) stay; only the parenthesised suffix changes. The recipe’s `##` help and failure text are updated in the same commit.
  - No other golden may move. If one does: stop and list the diff for Mark.
- **Captures:** `make camera-views-capture` renders Forward, Target and Deck (plus Commons legacy and the lift) at rest, 0.99c cruise, a guided stop and Sgr A*, at 720p and 1440p. It fails if the pole is out of Forward, the target is out of Target, or the head is out of any walking view. Every frame put in front of Mark is opened by eye (gate 2).

### D9. What this means for art and the deck-layout re-plan

- **Dress only what a view sees.**
  - Each level's views are fixed, so only the surfaces facing its cameras need finished art.
  - Backs, undersides and off-camera sides can stay rough or be absent.
  - Blender authors **per-view set pieces** (and can bake painted layers for them) instead of full 360° environments.
- **A style per level**, matched to that level's concept art: the bridge under the dome, the Commons streets, later levels their own.
- **Depth from parallax.** As the camera slides, the layers move at different rates:
  - foreground props: fast;
  - the deck (play area): 1:1;
  - the far structure (spire, far rail, bubble wall, levels below): slower;
  - the sky at infinity: fixed.

  This is D-6's layered depth, now produced by one perspective camera rather than composited plates.
- **The physics rule stays:** the sky layer is always the live SR/GR render through the camera's pose. It is never painted, baked or composited from an image. Painted layers stop at the bubble wall.
- **The deck layout (D-90) is re-planned on this basis after this camera lands.** It is paused at DL1 on `feat/deck-layout` (7863c831). From its DL0 work:
  - **Carries over unchanged:** `tools/deck_assets_check.gd` + `art/deck-layout-v1/budgets.json` (pins, budgets, named nodes, opaque materials, emission only on screens, clean reimport, negative controls); `tools/deck_layout.gd` with `layout_current.json` (moving props and rebuilding the walk); the rendered sky-mask control and the analytic sky-fraction maths.
  - **Carries over, re-targeted:** the metric code (clear line, captain size, foreground share, stations in frame, sky fraction). It now samples the bridge's three fixed walking views over every walk sample, instead of 16 sector cells × Z1/Z2/Z3. The key numbers become: the forward sky clear of the spire needle in Forward; the captain in frame and unblocked (after fades) at every walk sample in Deck; and the target in frame in Target.
  - **Obsolete:** its `thresholds.json` per-view framing (sector cells, Z3 spread, spawn at Z2, boom intrusion), and the two candidate layouts' scores (taken against sector views).

### D10. What is removed or changed, and what changes in tests

**Removed for the bridge:**
- the 8 sectors × 2 rings (16 cells), 10° and 1 m hysteresis, per-ring `turn_deg`, and per-cell overrides;
- the yaw rules `sector`, `tangent` and `outward`;
- Sky forward's `yaw_candidates_deg` and `choose_offset`;
- the sky views' `walk_to` anchors, since the captain no longer walks to the rail before a view starts.

All of these remain only behind `legacy: true` for the Commons.

| File | Change |
|---|---|
| `data/camera/views.json` | schema v2 (§D7) |
| `demos/camera_director.gd` | fixed-view slide rig, Target aim and re-aim, view switching, level defaults, occluder fade, legacy fence. `walk_yaw()` returns the view's fixed yaw (no resolve per frame) |
| `demos/ship_geometry_demo.gd` | 7/8/9 to Forward/Target/Deck, cues remapped (§D5), `under_way_view()` returns forward/target |
| `tests/test_camera_director.gd` | rewritten checks: schema v2 and negative controls, yaw constant, W up-screen in each view, the switch ease, the console round trip, level defaults, the sweep after fades. Sector and ring tests move to a legacy block for the Commons |
| `tests/test_camera_forward.gd` (new) | AC1–AC4 headless (below) |
| `tools/camera_walk_capture.gd` (new, this PR) | the walk measurement (before and after) |
| `tools/camera_views_capture.gd`, `tools/m4_ship_golden.gd` | new view list and eyes (§D8) |
| `Makefile` | `camera-forward-test` (headless, on `ship-demo-ci`, so in `make test`), `camera-walk-capture` (GPU evidence); golden pins unchanged at 393 |
| `ui/ship_controls.gd`, HUD hints | 7 Forward · 8 Target · 9 Deck · R default; zoom keys listed only in developer launches (OQ4) |

**Caller migration (F3)** (from `git grep` of `set_preset`, `look_direction`, `set_level`, `step_level`, `camera_level_*`, the `sky_*` ids and `director.sky(`, excluding the director itself):
- **Tests that assert player views, rewritten or retargeted:** `test_camera_director.gd` (sectors and the sky sweep move to a Commons-legacy block), `test_ship_demo_input.gd` (zoom keys become developer-only; 7/8/9 assert the new views), `test_no_twitch.gd`, `test_ship_consoles.gd` (console round trip), `test_ship_movement.gd` (screen-relative walk), `test_ship_ui.gd`, `test_ship_demo_journey.gd` and `test_ship_demo_live.gd` (cues), `test_free_nav_stop.gd`, `test_ship_demo_consolidation.gd`, `test_physics.gd` (only where it names a sky view id).
- **Tools that pose the camera through `override()` and keep working unchanged:** the captures and benches (`bh_ship_*`, `crossing_review_capture`, `free_nav_review`, `ism_hud_capture`, `recent_feature_movies`, `ship_*_capture`, `ship_*_bench`, `solar_departure_bench`, `stops_capture`). Any that name `sky_forward`, `sky_side` or `z2` get the new id, which F3 checks by running each one's smoke where a make target exists.
- **Retargeted:** `tools/camera_views_capture.gd`, `tools/m4_ship_golden.gd` (§D8).
- **Kept for tools and goldens only:** `sky_side` and `sky_aft` (OQ3), and the legacy Commons views.

## Acceptance criteria

**Conventions:**
- `$A` = `AILANG=$PWD/runtime/bin/ailang` (the pinned runtime, also first on PATH). `$S` = `.godot/tmp`.
- Every new test prints one line per check, `ok    <name>` or `FAIL  <name>: <why>`, and a final `<suite>: <n> passed, 0 failures`, as the repo's tests do.
- A recipe saves the full log to `$S/<suite>.log` and fails unless that final line says 0 failures. An AC's command greps that saved log, so a line the recipe doesn't echo still counts.
- In the table below, `\|` is markdown escaping for `|`. The real commands use a bare `|` (ERE alternation). The sprint JSON carries them verbatim and is the copy to run.
- **Headless fixtures:** `test_camera_forward.gd` runs with no sim for the aim. It injects a fixed stop-body direction and attitude basis through a `target_override` (as `hole_override` does for the hole). The real guided stop and the lensed Sgr A* are covered by `camera-views-capture` (AC11).

**New recipes** (in F1, in the `Makefile` beside `camera-test`):
- `camera-forward-test: import`
  - Runs `$(GODOT_SIM) --headless --path . --script tests/test_camera_forward.gd > $(SCRATCH)/camera-forward-test.log 2>&1`.
  - Gate: `test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' … && grep -q '^camera-forward: [0-9]* passed, 0 failures$$' …`.
  - Added to `ship-demo-ci:`, which is on `make test`'s line (Makefile:973). It is **headless**.
  - The yaw, pole and target assertions are projection maths on the director's pose (`CameraDirector.screen_point`). They run here, not in a GPU capture.
- `camera-walk-capture: import` (GPU window) renders the same walk for review, with gate `^camera-walk-capture: [0-9]* frames, 0 failures$`. This is visual evidence only, not a gate on behaviour.

| # | Criterion | Command (exit 0 = met) |
|---|---|---|
| AC1 | The yaw is constant over a scripted walk around the whole bridge in every walking view. Over 16 walk samples (8 angles × radii 10 m and 17 m, `closest_walkable`), each after 1.5 s of `advance`, the yaw spread is ≤ 0.1° for Forward, Deck and Target (ship stationary, no re-aim). Today it is 180° | `make camera-forward-test $A && test $(grep -cE '^ok    yaw constant (forward\|deck\|target_stop\|target_sgr_a) spread=0\.[0-9]+ deg over 16$' $S/camera-forward-test.log) -eq 4` |
| AC2 | The forward pole is in frame (inside 1280×720 with a 40 px margin) at all 16 Forward samples. The stop's body is in frame at all 16 Target samples at the first guided stop, and the hole at all 16 at Sgr A* (flat-space aim, `hole_override`) | `grep -qE '^ok    pole in frame forward 16/16$' $S/camera-forward-test.log && grep -qE '^ok    target in frame target_stop 16/16$' $S/camera-forward-test.log && grep -qE '^ok    target in frame target_sgr_a 16/16$' $S/camera-forward-test.log` |
| AC2b | In Forward, the ray from the eye toward the pole and the line to the captain’s head are clear (after fades) at all 16 samples, so the spire never hides the journey | `grep -qE '^ok    pole ray clear forward 16/16$' $S/camera-forward-test.log` |
| AC3 | W moves the captain up-screen and D moves it right, in Deck, Forward and Target and after each of two switches. Each key is held 0.5 s of `advance`: screen Δy < −20 px with \|Δx\| < 0.3\|Δy\| for W, and the mirror for D | `test $(grep -cE '^ok    (W up-screen\|D right) (deck\|forward\|target)$' $S/camera-forward-test.log) -eq 6 && test $(grep -cE '^ok    W up-screen after switch (deck>forward\|forward>target)$' $S/camera-forward-test.log) -eq 2` |
| AC4 | In Deck, the captain's head is in frame and the line to it is clear, after occluder fades, at every 0.5 m bridge walk sample (the existing `sweep` grid). The `camera_occluder` group holds only the named nodes (§D1) | `make camera-test $A && grep -qE '^ok    AC4 deck clear after fades: 0 blocked of [0-9]+ samples$' $S/camera-test.log && grep -qE '^ok    occluder group = spire, lift$' $S/camera-test.log` |
| AC5 | Every eye stays within 95 m and at least 0.3 m above its deck; an envelope clamp never changes yaw or pitch | `grep -qE '^ok    envelope keeps the angle$' $S/camera-forward-test.log && grep -qE '^ok    eye above deck at 48 samples$' $S/camera-forward-test.log` |
| AC6 | (a) A view switch eases at ≤ 90°/s (full motion) or cuts in a 0.15 s fade (reduced), then the basis is constant. The WASD mapping changes only at the end of the ease. (b) Target re-aims only when the aim leaves the middle 60% (aim moved, captain still), never on a walk | `test $(grep -cE '^ok    (switch ease max [0-9.]+ deg/s\|reduced cut\|mapping at ease end\|re-aim on aim exit\|no re-aim on walk)$' $S/camera-forward-test.log) -eq 5` |
| AC7 | A console round trip returns to the previous view's exact basis and id, for Deck and Forward | `test $(grep -cE '^ok    console returns to (deck\|forward) exact$' $S/camera-test.log) -eq 2` |
| AC8 | `views.json` v2 validates. Six negative controls fail as they must: no default; a default naming another level's view; a non-legacy walking view without `yaw_deg`; an FOV change; `envelope_m > 95`; `rise_m < 0.3` | `grep -qE '^ok    schema v2$' $S/camera-test.log && test $(grep -cE '^ok    negative control ' $S/camera-test.log) -ge 6` |
| AC9 | The lift's arrival selects the level's default view: the bridge's by situation, and the Commons' legacy Z2 | `test $(grep -cE '^ok    level default (bridge\|commons)$' $S/camera-forward-test.log) -eq 2` |
| AC10 | Goldens: 393 ok lines; G-CAM-1 9, G-CAM-2 8, G-CAM-3 2 with the new labels; no non-camera case changed (the recipe's own count gate) | `make golden $A` |
| AC11 | Captures: Forward, Target, Deck, legacy Commons and the lift × rest, 0.99c, stop and Sgr A*, at 720p and 1440p, with 0 failures. Frames opened by eye are listed in the report | `make camera-views-capture $A && make camera-walk-capture $A` |
| AC12 | Determinism: the same scripted inputs (walk, switches, a console round trip, 600 steps at fixed `dt`) run twice give bit-identical pose sequences. Fades and eases read `advance(dt)` only | `grep -qE '^ok    deterministic poses 600 steps$' $S/camera-forward-test.log` |
| AC13 | The full suite is green, with no new Python | `make python-guard && make test $A` |
| AC14 | Landed (checked at landing, not before merge): doc and sprint in `implemented/r2/`, changelog fragment | `test -f design_docs/implemented/r2/camera-forward.md && ls changelogs/unreleased/*camera-forward*` |

## Sub-milestones and estimates

Approval gate: the sprint starts after Mark answers OQ1–OQ4. F2 is built on the OQ1/OQ2/OQ3 answers, and F1's key map on OQ4.

| # | What | LOC | Days |
|---|---|---|---|
| F1a | Schema v2 + validate (legacy fence, 6 negative controls); slide rig (dead zone, follow, slide box, envelope slide, eye ≥ deck); Deck on the bridge; constant `walk_yaw`; 9 / R keys; zoom actions developer-only (OQ4); lift-arrival level default; `camera-forward-test` and `camera-walk-capture` recipes. AC1 (deck), AC3 (deck), AC5, AC8, AC9, AC12 | ~420 | 1.25 |
| F1b | Forward view (pitch 56°, 2.4 m / 0.3 m); the occluder group and fade (or the hide fallback); the bridge yaw sweep (15° steps; the fewest fades, the pole clear of the spire). AC1 (forward), AC2 (forward), AC3 (forward), AC4. **Pause point:** a dev build for Mark to play | ~280 | 0.75 |
| F2 | Target (aim order, pitch clamp and hand-over, re-aim); 8 key; cue remap (departure/cruise/braking/stop/Sgr A*); console `restore()` to the view id; the HUD key hints. AC1 (target), AC2 (target), AC3 (target, after switch), AC6, AC7 | ~320 | 0.75 |
| F3 | Goldens re-posed (§D8); captures; migration of the callers listed in §D10; dead bridge sector paths removed; report; independent evaluation and fixes; landing. AC10–AC14 | ~300 | 1.25 |

Total: about 1,320 LOC over 4.0 days, about 330 LOC/day, against R2-CAMERA's measured ~310/day.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| A fixed yaw puts the spire between camera and captain at some positions | Occluder fade (§D1), AC4 sweep; F1 picks the bridge yaw that minimises fades |
| Forward shows no deck, so walking there feels blind | Deck is the walking view (default at rest); Forward is cued only under way; R and 9 always return to Deck |
| The Target body is near the pole (the ship pointed at it), so the pitch clamp loses it | Above 60° elevation, Target hands over to Forward, which frames the pole (AC2 includes the guided stop, where the body is beside the rail by design) |
| Goldens move beyond the G-CAM cases | Stop and list the diff for Mark (pause point) |
| The Commons' legacy path rots | Fenced and tested as legacy; its own pass replaces it (follow-up) |
| Sprites read worse at Deck's −30° than the −14° they were drawn for | Same as today's Z2 (accepted); revisit in the deck-layout re-plan |

## Open questions for Mark (with recommendations)

OQ1–OQ4 are an approval-time gate: the sprint starts with them answered (sprint plan, "Approval gate"). OQ5–OQ7 may be answered later.

| # | Question | Recommendation |
|---|---|---|
| OQ1 | The bridge's views: Forward, Target, Deck and Console. Is a Deck (walking) view wanted beside Forward, given one frame cannot hold both the deck and the starbow (§D2)? | **Yes**: Deck is the walking view at rest; Forward is the journey view under way |
| OQ2 | "One planet facing (same as navigation around ship?)": is that the guided stop's view, where the ship turns its side to the planet beside the rail? | **Yes**, Target generalises it (and the Sgr A* hole view). The Navigation station's chart stays as it is |
| OQ3 | Side and aft views | **Fold side** into Target and Deck; **drop aft** for players (it looks through the deck; at speed the aft sky is the darkest); keep both for tools and goldens |
| OQ4 | Zoom levels Z1/Z2/Z3 | **Remove for players**: each view has one authored framing, and Console is the only zoom. Keep the levels as developer presets |
| OQ5 | Spire and lift between the camera and the captain | **Fade the occluder** (dither to 25%); never turn the camera |
| OQ6 | The Commons in this sprint | **Leave as is** (legacy), with its own fixed-view pass after the deck layout re-plan |
| OQ7 | An inset window for a second direction (side or forward) | **Later**, after Mark plays F1 |

## Evidence

- **Before:** https://storage.googleapis.com/stapledons-voyage-assets/refs/camera_forward/before/contact_sheet.png (rows: rest at 10 m and 17 m, then under way at 10 m and 17 m; 8 angles each). Frames `rest_r<r>_<i>.png` and `under_way_r<r>_<i>.png`, and `walk.json` with per-sample yaw, pitch, pole and head pixels. Opened by eye: the contact sheet, `rest_r10_0`, `under_way_r10_3`.
- **Tool:** `tools/camera_walk_capture.gd`. In F1 it gains the forward/target/deck passes and the `make camera-walk-capture` target used by AC1/AC2.

## Deliverables

- This doc and [camera-forward-sprint.md](camera-forward-sprint.md); `.ailang/state/sprints/sprint_R2-CAMERA-FORWARD.json`.
- F1–F3 code, tests, tools and data per §D10.
- A dev build after F1 for Mark to play.
- After-captures and a report; the independent evaluation; landing (doc to `implemented/r2/`, roadmap, changelog).
- Then the deck-layout re-plan (D-90) on this camera.
