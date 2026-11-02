# Sprint R3-TRUE-PROCESSED: the feed's colour and the ship's star light made exact

**Design doc:** [true-processed-fixes.md](true-processed-fixes.md). **Sprint JSON:** `.ailang/state/sprints/sprint_R3-TRUE-PROCESSED.json`.
**Branch:** `feat/true-processed-fixes` (clone `~/dev/sunholo-data/stapledons-godot-true-processed`, from main `6d92d2cb`).
**Approval:** ledger D-144 (Mark, attended 2026-11-02) approves executing this work as an attended parallel agent; the visual landing stops for Mark's render review, the PR stays a draft.
**Duration:** one working session (about 6 hours). **Risk:** medium (a visible change in developer launches; goldens see only the sky).

## Analysis

- **Velocity.** The last comparable attended sprints (AR8b, PR #361 game half; R1-SHIP-STAR-LIGHT, PR #144) moved 300–600 LOC of GDScript plus tests per session. This sprint is about 650 LOC, a third of it removal or test.
- **Registry reuse (mandatory gate).** No milestone adds a package capability. The star light reuses what the game already mirrors from `sunholo/relativity` (Doppler, point-flux ratio, aberration, blackbody) and `sunholo/celestial` (the sim's `e_v_lux`). Decision per milestone: TP1 `none` (removal), TP2 `none` (a rendering calibration and an exposure rule over existing physics; no new formula), TP3 `none`, TP4 `none`, TP5 `none`. Option B's spectral-shift matrix would be `contribute` to `sunholo/relativity`, and is not built.
- **AILANG.** No `.ail` change, so the syntax gate does not apply; the sim, protocol and parity are untouched.
- **Baseline (measured on `6d92d2cb`).** `make capture-comms-station` OK (4 frames). `make ship-star-light-capture` writes 16 frames (Earth, the departure turn, Jupiter, Saturn, the outbound cruise, the α Centauri approach), then fails on main: `capture-arrival-failed: CNS5:3627 state committed phase braking phase ticks 5021 beta 0.999` and `make: *** [ship-star-light-capture] Error 1`. It is a GPU capture outside `make test`; this sprint does not fix it (the 6000-tick arrival budget is a tour matter) and reports it.

## Milestones

### TP0: plan and baseline (docs)
- Design doc, this plan, the JSON. Before renders of the feed (4 comms frames) and the star light (16 frames) saved to the scratch review set; the feed option mock-ups (A, B, before) at D = 0.071, 0.5, 0.8, 1, 1.25, 2, 14.1 from a throwaway spike in scratch.
- **Acceptance:** the files exist; the mock-ups opened. **Done** (bb8cb586).

### TP1: the feed's picture as decoded (~120 LOC)
- Tests first: `test_earth_feed_bands` in `tests/test_physics.gd` asserts no band carries `tint`/`tint_alpha`, the band names at RS-26..RS-30, and that `EarthFeed` refreshed in beam at each of those D draws the picture unmodulated (white `self_modulate`, no tint child). `tests/test_earth_feed.gd` replaces its warm/cool checks with "no wash at fast and slow".
- Then: `data/ui/comms_feed.json` (bands without colour; `about` rewritten: the colour is exact, why, and that the receiver's correction applies to the sound), `ui/earth_feed.gd` (no tint ColorRect), earth-link.md "Doppler tint" row superseded.
- **Acceptance:** `make earth-feed-test comms-station-test physics` green. **Done** (35748f15: earth-feed 59 ok, comms-station 42 ok, physics 1027 then 1034 ok, earth-link-golden 20 ok).

### TP2: the star light's True and Processed (~330 LOC)
- Tests first (`tests/test_ship_star_light.gd`, a new section): `StarLight.true_energy(E) == E / 10`; `deck_meter` with f(y) at y = 1, 0, -0.1, -0.3; exposure = E_ship / E_meter at the Sun at 1 AU, 5.2 AU, 30 AU (1/1588.5 overhead at 1 AU); the share and the shadow owner; the bounce term; lamps at base in True; Processed reproduces every pre-existing assertion; a controlled-distance sweep (1 AU to interstellar, and an M-dwarf and a K-giant at their habitable/close distances) is monotonic and finite.
- Then: `demos/ship_star_light.gd` (`mode`, `LUX_PER_ENERGY`, `BOUNCE`, the meter, `apply_rig` per mode, manifest, HUD line), `demos/ship_lighting.gd` (record the ambient colour and energy base so the star can add its bounce and restore them).
- **Acceptance:** `make ship-star-light-test` green with the new section. **Done** (113 passed, 0 failures). Amended in execution: the adaptation is a gain on the interior's lights, not `tonemap_exposure` (the unshaded captain went black).

### TP3: the setting on the view toggle (~60 LOC)
- `ship_geometry_demo.set_auto_view` sets the mode; the view button text names it; `tests/test_bh_hud.gd` keeps its "no star" check in both modes; a demo check in `test_ship_star_light.gd` toggles V both ways.
- **Acceptance:** `make ship-star-light-test bh-hud-test` green. **Done** (834f4dac; bh-hud 64 ok, style-test 22 ok).

### TP4: gate 2 (~60 LOC)
- `tests/test_physics.gd`: the True deck illuminance equals E × the spec's point ratio at RS-3/RS-4 (Sun ahead and astern at 0.9c) and follows the inverse square (1 AU vs 5.2 AU); the feed rows of TP1.
- Design repo: a fresh clone `~/dev/sunholo-data/stapledons-design-true-processed`, RS-Q5 (a decoded frame keeps its colours) as a draft PR.
- **Acceptance:** `make physics` green; the design draft PR URL. **Done** (1034 passed, 0 failed; stapledons-design#51).

### TP5: renders, PR, rig (~80 LOC)
- `tools/ship_star_light_capture.gd` shoots each pose in True and Processed (`_true`, `_processed` suffixes); the comms capture re-run (after); every frame opened; the review set uploaded to `refs/true_processed_v1/`; changelog fragment; draft PR; `tools/rig_check.sh <PR> --golden` when no other rig check runs.
- **Acceptance:** `gsutil ls` lists the set; `rig/full` posted.

## Validation (targeted, never the full suite locally)

`make earth-feed-test comms-station-test physics ship-star-light-test bh-hud-test uid-guard python-guard ui-theme-check`; the full suite on the rig only.

## Pause points

- After TP5: Mark's render review (visual landing). Questions 1–4 of the design doc go to Mark with recommendations; none blocks execution.
