# Sprint R2-CAMERA: fixed zoom levels and authored third-person views

**Design doc:** [camera-fixed-views.md](camera-fixed-views.md) (proposed 2026-10-16, from Mark's dev.31 playtest direction)
**Sprint JSON:** `.ailang/state/sprints/sprint_R2-CAMERA.json`
**Status:** **Approved 2026-10-16** (Mark, attended: "yes continue"; OQ1-OQ9 answered as recommended). PR 1 (C1 + C3) executing on `feat/camera-fixed-views`.
**Scope:** C1 (director, levels, input), C2 (authored situation views and cues), C3 (developer free camera, pointer, the reduced-motion setting), C4 (physics invariance, goldens, renders), C5 (test migration, tool smoke runs). Then E (evaluate, land).
**Base:** `origin/main`. Sprint branch `feat/r2-camera`. C1+C3 make one PR (the player-visible switch), and C2, C4 and C5 follow as PRs to main. Every PR keeps `make test` green.
**AILANG:** no sim change. The pin is whatever main has (v0.54.8; v0.54.11 if `feat/crew-core-0.5.0` lands first). Only `make test`'s sim targets run.

## What the survey found

- **Zoom is a dolly, not a lens.** `_zoom()` (`demos/ship_geometry_demo.gd:443`) adds to `camera.pullback` in [0, 300] m. The FOV is fixed at 78° (`demos/ship_demo_camera.gd:12`). Trackpad scroll is continuous (`-event.delta.y*2`, line 376). `tests/test_ship_demo_input.gd:25` pins the smooth behaviour that the ruling removes.
- **The camera can leave the bubble.** `follow()` sets `external` at |eye| ≥ 100 m, and `sync_sky` then zeroes the glow pole. A pullback of 25 m from the spawn is at 93.7 m. A 26 m / −50° boom is at 104.6 m. Preset 3 is at 223.9 m. All three were measured on 2026-10-16.
- **The default is first person** (`set_preset("bridge")`, pullback 0). The sprite is shown only when `pullback > .5` (line 351).
- **Mouse look and the pointer** come from D-63. `_sync_pointer` (line 1241) captures the pointer whenever no panel is open, and clicks aim from the screen centre while it is captured (line 382).
- **Five pose writers:** `set_preset`, `look_direction`, the `_unhandled_input` look, `ShipConsoles` (focus dolly `DOLLY_S = 0.6`, `face`, `go_to`, the auto-walk yaw at line 462), and the tour turn (`_begin_tour_turn` / `_update_tour_attitude`, which lerps tilt/yaw over 3 s).
- **WASD is camera-relative** (`walk_motion`, line 304). Fixed views need the held-direction rule (design §D2).
- **Console facing** uses `camera.yaw` (`ship_consoles.gd:154`, `FACING_DEG = 60`). In third person, the captain's facing must be separate from the camera yaw. C1 adds `captain_yaw` to the demo, and `ShipConsoles` reads it.
- **The sprite** (`interior/captain_avatar.gd`) is a full billboard drawn for −14° pitch, with facings front/back/ne/se and four age stages (y0/y20/y40/y60).
- **Goldens.** `tools/m4_ship_golden.gd` S2 uses `_pose(30, 0.47)`, S3 `_pose(89.99, 0)` and S4 the eye position. All of them are at pullback 0. The Makefile pins 373 `ok` lines.
- **No controller code exists** (no `JOY_` anywhere). There are no InputMap actions for the camera; keys go through `match event.physical_keycode`.
- **24 tools and tests** call `set_preset` / `look_direction` / `follow` / `pullback` / `reference_view` (design §Migration).
- **Settings:** `ui/game_settings.gd` holds `[display] auto_view` and `[controls] confirm_mode`. `camera_motion` joins `[display]`.

## Plan shape

```
C1 (director, levels, input) ─┬─▶ C2 (situation views, cues) ─▶ C4 (physics, goldens, renders) ─┐
                              └─▶ C3 (dev free camera, pointer, reduced motion) ─────────────────┼─▶ C5 (migration) ─▶ E
```

C1 and C3 ship together as the first PR. That PR is the ruling: no free zoom and no mouse look for players. C2 adds the authored situation views. C4 must pass before any SR-showing view merges (gate 2). Since C1 already changes the SR-showing views, the G-CAM-2 glow cases for Z1/Z2 move into C1's PR (see C1 gate).

## Milestones

### C1: the director, three levels, input actions (~550 LOC, 1.5 days) — ✅ done 2026-10-17, PR 1 (render review pending)

- **Red first.**
  - `tests/test_camera_director.gd` (new, `make camera-test`). It covers:
    - the `views.json` schema;
    - the envelope and clear-line sweep over `walk_bridge.glb` at 0.5 m, plus the mutant 26 m / −50° view (AC1);
    - the three levels and the steps from each input (AC2);
    - the captain in frame, and Z2 at 60–80 px at 1280×720 (AC4);
    - sector hysteresis, the held walk direction, and the per-frame pose-jump bound (AC5).
  - `tests/test_ship_demo_input.gd` is rewritten red (AC2, AC3).
- **Code.**
  - `demos/camera_director.gd`: the state, `advance(dt)`, `set_view`, `step_level`, the sectors, the blend, the envelope clamp with a log, `override(pose)` / `release()`.
  - `data/camera/views.json`: Z1, Z2, Z3-bridge, Z3-commons, lift.
  - `ShipCamera.follow` stays for tools. The director writes `global_transform`, then calls `_sync_observer()`.
  - `project.godot` InputMap actions: `camera_level_in/out`, `camera_level_1..3`, `camera_default`, with key, wheel and joypad events.
  - Wheel and trackpad gestures are accumulated in the director (one level per notch / 1.0 unit / ×1.15 pinch; 0.3 s cooldown).
  - `ShipConsoles`: focus and leave go through `director.set_view("console:<mesh>")` and `director.restore()`. `_eye` is deleted. Facing reads `demo.captain_yaw`.
  - `walk_motion` is screen-relative with the held direction.
  - `ui/ship_controls.gd`: rows for the actions (NT5).
- **Gate:** `make camera-test ship-demo-input-test ship-console-test ship-ui-test no-twitch-test`, plus G-CAM-2's Z1/Z2 cases and G-CAM-3's Z2 case in `make golden` (count 373 → 378 at this PR: 4 glow cases + 1 tonemap case). Open the Z1/Z2 renders at rest and at 0.99c.

### C3: developer free camera, pointer, reduced motion (~200 LOC, 0.5 day; ships with C1) — ✅ done 2026-10-17, PR 1 (render review pending)

- **Red first.**
  - `test_camera_director.gd` reduced-motion cases (AC7).
  - The `test_ship_ui.gd` dev-gating case: F8 is absent on a menu launch (AC9).
  - `test_navigation_usability.gd`: the pointer is never captured on a menu launch (AC3).
- **Code.**
  - F8 and `--free-camera` toggle the old look/dolly path behind `dev_controls()`. Presets 3 and 4 work only there.
  - `mouse_look_enabled` defaults to false for menu launches.
  - `_sync_pointer` captures only in the free camera.
  - Click aim always uses `event.position`.
  - `GameSettings.camera_motion` (`full` | `reduced`): the title Settings and the Tab panel. The HUD label "FREE CAMERA · developer".
- **Gate:** `make ship-ui-test free-nav-recovery-test title-screen-test camera-test`.
- **PR 1 = C1 + C3.** An attended render review of the default views follows before merge (visible feature; mission-loop routing keeps it attended).

### C2: situation views and cues (~350 LOC, 1 day) — ✅ done 2026-10-17 (PR #270)

- **Red first.**
  - `test_camera_director.gd` cue cases (AC6). Each cue fires on its trigger and never with a panel, at a console or in the lift; it ends on any input; with reduced motion it is a prompt.
  - `tests/test_tour_attitude.gd` is rewritten: the departure turn cues Sky forward and a stop cues Sky side, with `attitude_hold` timing unchanged.
  - `tests/test_no_twitch.gd` gains cues over 600 s of fake time (no intent; AC10).
- **Code.**
  - `views.json`: `sky_forward`, `sky_side`, `sky_aft`, the anchors (the forward-watch point clear of the lift and spire, rail points per sector), `arrival`, `interlude_hold`, `sgr_a_forward`.
  - Keys 7/8/9 and the D-pad.
  - Auto-walk to the anchor through `ShipConsoles` walk paths.
  - `_begin_tour_turn` keeps the attitude turn but no longer writes tilt/yaw; it calls `director.cue(...)`.
  - Braking and Sgr A* cues come from `ship.phase` / `bh_*`.
  - The interlude holds the camera still while `CardInterlude` is active.
  - Lift and lower-deck Z3 views.
- **Gate:** `make camera-test tour-attitude-test tour-pacing-test no-twitch-test ship-demo-lift-test solar-departure-test`.

### C4: physics invariance, goldens, renders (~250 LOC, 1 day) — ✅ done 2026-10-17 (PR #270)

- **Red first.**
  - `tests/test_physics.gd`: RS-1 and RS-2 through every `views.json` eye equal the captain eye to 1e-9 rad and 0.05 px (AC11).
  - `tools/m4_ship_golden.gd`: G-CAM-1 (forward pole from Sky forward and Sgr A* forward, ×3 phases = 6), the rest of G-CAM-2 (Z3, Sky forward, 0.99c and cap 1−β 2e-9; 8 cases in all with C1's), and G-CAM-3 (S2 at Sky forward; 2 in all).
  - The Makefile `golden` count goes to 389, with grep lines for each new family.
- **Renders.** `tools/camera_views_capture.gd` and `make camera-views-capture` → `renders/camera_views/*.png`: every view × {rest, 0.99c, a guided stop, Sgr A*} at 1280×720 and 2560×1440, plus a contact sheet. The capture fails on |eye| > 95 m or a missing captain (AC13). **Open every frame** (author, then the evaluator).
- **Gate:** `make test` (physics), `make golden` (GPU, attended shell or Studio), `make camera-views-capture` opened by eye.

### C5: migration, tool smoke runs, changelog (~350 LOC, 1 day)

- **Migrate the setups** listed in the design's migration table: `test_ship_demo_consolidation` (Z2 default, R → Z2), `test_ship_demo_lift`, `test_ship_demo_journey`, `test_ship_demo_live`, `test_free_nav_stop`, `test_manual_exposure`, `test_title_screen`.
- **Tool smoke runs** through `override`: `make ship-demo-capture ship-ui-capture` plus one run each of the bench and capture tools listed in the design. Each must exit 0 with the same frame names.
- **Changelog:** `changelogs/unreleased/r2-camera.md`. The `demos/README.md` controls section and the Tab help text.
- **Gate:** `make -k test` exit 0 locally. CI green.

### E: evaluate and land (0.5 day)

- The `sprint-evaluator` runs on a **different model** from the executor. It opens the renders itself.
- Landing: the design doc moves to `implemented/r2/`, the design repo roadmap row and `vision/design-decisions.md` get an entry (third person / fixed views, superseding the eye default and D-63 for players), and the index row in `design_docs/README.md` is updated.

## Estimates

| Milestone | LOC | Days |
|---|---|---|
| C1 | 550 | 1.5 |
| C3 | 200 | 0.5 |
| C2 | 350 | 1.0 |
| C4 | 250 | 1.0 |
| C5 | 350 | 1.0 |
| E | — | 0.5 |
| **Total** | **~1,700** | **5.5** |

Velocity is 350 LOC/day, the figure R2-INTERLUDE planned with. That sprint ran ahead of it on the sim side. Camera work is tuning-heavy (sector anchors, envelope), so this plan keeps 350 and adds no buffer beyond E.

## Pause points

1. **After PR 1 (C1 + C3):** Mark opens the Z1/Z2/Z3 renders at rest and at 0.99c and plays a menu launch. This is the ruling's visible change; nothing else merges first.
2. **Any golden outside G-CAM moving:** stop and list the diff for Mark. The physics is meant to be unchanged.
3. **C4:** the renders are opened by eye before the C2/C4 PRs merge (gate 2).
4. **If the clear-line sweep cannot be met** in some bridge sector without moving an anchor more than 2 m from the design values: stop, capture the sector, and ask.

## Risks

See the design doc §Risks. The plan-specific one: `ship_geometry_demo.gd` is 1,249 lines and other branches edit it (crew console v2, the Alpha Centauri pointer fix). C1 moves the camera code *out* of it into `camera_director.gd`, which reduces later conflicts. Rebase before each PR.

## Progress (PR 1: C1 + C3, 2026-10-17)

- Executed on `feat/camera-fixed-views`. `make camera-test` 95 checks; `make ship-demo-input-test ship-console-test ship-ui-test no-twitch-test title-screen-test` green; `make golden` adds G-CAM-2 (4) and G-CAM-3 (1), 379 ok lines.
- Deviations: a second sector ring (the stations ring inside 12 m looks inward, turn 135 deg; the rail ring looks outward, turn 30 deg), because the design's single outward rule puts the Z2 eye inside the spire needle for any captain within ~10 m of the axis; Z1 pitch -25 deg (from -20) to clear the navigation consoles; actions registered at runtime instead of `project.godot`; long sector/ring swings ease longer than 0.8 s to keep the eye's acceleration under 1 cm/frame^2 (AC5); lower-deck views are interim (ceilings 9/47/75 blocked samples) until C2's Commons cameras; keys 7/8/9 and the tour's turns still use the old first-person looks until C2.
- Pause point 1: Mark's render review of `renders/camera_views/` and a menu launch.

## Progress (C2 + C4 added to PR #270, 2026-10-17, after the lead's frame review)

- Blocker fixed: at 0.99c every level view showed a black sky. Under way the default view is now Sky forward (cued at commit / departure / braking / Sgr A*, R under way), framing the starbow; `cruise_default_b9/b99/b999` captures of a real committed voyage show it.
- Spawn occlusion fixed by per-cell angles at the lift landing; whole-figure sweep including the lift's boxes.
- Commons authored per cell (ceilings Z1 2, Z2 2, Z3 39 blocked samples of 1,881).
- C4: invariance in `test_physics.gd`; G-CAM-1 6, G-CAM-2 8, G-CAM-3 2; `make golden` 390 (fixes main's stale 373 pin; main ran 374).
- C5 held: the 19-tool smoke runs are not done in this PR.
