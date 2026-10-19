# Sprint R2-CAMERA-FORWARD: fixed views per level that slide with the captain and never turn

**Design doc:** [camera-forward.md](camera-forward.md) (from Mark's dev.34 playtest, ledger D-91)
**Sprint JSON:** `.ailang/state/sprints/sprint_R2-CAMERA-FORWARD.json`
**Status:** **Awaiting approval** (Mark, attended). Nothing executes until he approves.
**Approval gate:** Mark answers OQ1–OQ4 at approval. F2 depends on OQ1–OQ3 (which views, what "planet facing" is, side and aft). F1a's key map depends on OQ4 (zoom levels).
**Scope:**
- F1a: the slide rig, schema v2, Deck, constant controls.
- F1b: Forward, the occluder fade, the bridge yaw.
- F2: Target, keys and cues, the console return.
- F3: goldens, captures, migration, evaluation, landing.

**Base:** `origin/main` (5118cc2 or later). Branch `feat/camera-forward`, one PR, with a dev tag after F1b for Mark to play. Every commit keeps `make test` green on the rig.
**AILANG:** no sim change. The pin stays v0.54.14, and only `make test`'s existing sim targets run.

## What the survey found (origin/main 5118cc2)

- **Yaw comes from the walk.**
  - `CameraDirector.sector_yaw` (16 cells, `turn_deg` per ring) gives the level views their yaw.
  - `_sky` uses `yaw = atan2(foot) + offset` for Sky forward (`yaw_rule: tangent`).
  - Measured over 16 walk samples, the yaw spread is 180° at rest and under way (`tools/camera_walk_capture.gd`; design §Problem).
- **WASD is already screen-relative.** `walk_yaw()` resolves the active view's flat forward each frame, so the keys turn with the camera. Making the view's yaw constant fixes the keys too.
- **The sky-view rig is the model for Forward.** `_sky` places the eye at `foot − flat(yaw) × back_m + up × rise_m`, about 0.3 m above the deck. Its pole lands at y = 82 px at pitch 58°, matching the design's analytic table to 0.2 px. The table is therefore trustworthy for choosing pitches (56° → 60 px).
- **Stop turns:**
  - Stops use `Attitude.side_basis(rel_km)` and cue `sky_side`.
  - The body's ship-frame direction comes from the same transform as `hole_direction()`.
- **Goldens.** `tools/m4_ship_golden.gd`:
  - G-CAM-1 = Sky forward at spawn and at helm, plus the hole view, each through `_pole()` (3 phases), so 9.
  - G-CAM-2 = 4 eyes (z1, z2, z3_bridge, sky_forward) × {0.99c, cap}, so 8.
  - G-CAM-3 = 2.
  - The Makefile pins 393 ok lines (Makefile:447–450). Design §D8 keeps every count by re-posing each case one for one.
- **Tests.** `ship-demo-ci` is on `make test`'s line (Makefile:973), and `camera-test` hangs off it. The new `camera-forward-test` does the same.
  - The `camera-test` recipe echoes only `FAIL|figure|transitions|camera-director` lines. The ACs therefore grep the saved logs (`.godot/tmp/<suite>.log`).
- **No occluder machinery exists.**
  - Today, the clear-line `sweep` treats any hit as blocked (`tests/test_camera_director.gd:152–166`).
  - `view_clear` already tests the lift's AABBs against the camera–captain segment.
  - F1b adds a `camera_occluder` group (spire, lift) and a fade or hide.
- **Callers.** 34 files call the camera API (design §D10 lists them). Most tools pose through `override()` and keep working. About 11 tests assert player views and are rewritten or retargeted in F3.
- **The paused deck work** (`feat/deck-layout` 7863c831) has metric and asset tools that the deck re-plan reuses (design §D9). This sprint doesn't touch them.

## Plan shape

```
F1a (schema v2, rig, Deck, keys) ──▶ F1b (Forward, occluder fade, yaw sweep) ──▶ [pause: dev tag, Mark plays] ──▶ F2 (Target, keys, cues, console) ──▶ F3 (goldens, captures, migration) ──▶ E (evaluate, land)
```

## Milestones

### F1a: schema v2, the slide rig, Deck, constant controls (~420 LOC, 1.25 days)

- **Red first.** These fail on main:
  - **`tests/test_camera_forward.gd`** (new) and its `camera-forward-test` recipe (on `ship-demo-ci`). Checks:
    - `ok    yaw constant deck spread=… deg over 16`;
    - `ok    W up-screen deck` and `ok    D right deck`;
    - `ok    envelope keeps the angle`;
    - `ok    eye above deck at 48 samples`;
    - `ok    level default bridge|commons`;
    - `ok    deterministic poses 600 steps`.
  - **`tests/test_camera_director.gd`:** `ok    schema v2` and 6 negative controls (design AC8).
  - **The `camera-walk-capture` recipe** (GPU evidence), wrapping the tool already in this PR.
- **Green:**
  - **`data/camera/views.json` → v2.** It is level-keyed; the Commons is `legacy: true` with today's views unchanged.
  - **`CameraDirector`:**
    - the fixed-view rig (`eye = foot − flat(yaw) × back_m + up × rise_m`, the basis never re-aimed);
    - the dead zone, critically damped follow (`FOLLOW_S`), slide box and envelope slide;
    - `walk_yaw()` returns the view's fixed yaw;
    - the legacy fence (sector code only for `legacy` levels);
    - level defaults on lift arrival.
  - **`ship_geometry_demo.gd`:**
    - 9 = Deck, R = the situation default;
    - the zoom actions (`camera_level_*`, wheel, pinch) are developer-only, per OQ4's answer.
- **Check:** AC1 (deck), AC3 (deck), AC5, AC8, AC9, AC12; `make camera-test camera-forward-test`.

### F1b: Forward, the occluder fade, the bridge yaw (~280 LOC, 0.75 day)

- **Red first:**
  - `ok    yaw constant forward …`;
  - `ok    pole in frame forward 16/16`;
  - `ok    W up-screen forward`;
  - in `camera-test`: `ok    AC4 deck clear after fades: 0 blocked of N samples` and `ok    occluder group = spire, lift`.
- **Green:**
  - **The Forward view:** pitch 56°, back 2.4 m, rise 0.3 m; 7 = Forward.
  - **The `camera_occluder` group:**
    - members: the spire's `Spire*` meshes and the lift's visible boxes, added at scene build;
    - the material alpha eases to 0.25 over 0.2 s of `advance(dt)` while the member's AABB crosses the camera–captain segment;
    - fallback: hide the mesh while it crosses.
  - **The sweep:** "after fades" counts hits on non-group nodes only.
  - **The bridge yaw:**
    - sweep in 15° steps over the walk samples (analytic: segment against the AABBs, no rendering; budget 2 h);
    - pick the yaw with the fewest fades and the pole clear of the spire in Forward;
    - record the table in the sprint notes.
- **Check:** AC1 (forward), AC2 (forward), AC3 (forward), AC4; then a full `make test` on the rig.
- **Pause point:** tag a dev build (after a green `make test`) and ask Mark to play Forward and Deck. His notes may change numbers in the data before F2.

### F2: Target, keys and cues, console return (~320 LOC, 0.75 day)

- **Red first:**
  - `ok    yaw constant target_stop|target_sgr_a …`;
  - `ok    target in frame target_stop 16/16`;
  - `ok    target in frame target_sgr_a 16/16`;
  - `ok    W up-screen target`;
  - `ok    W up-screen after switch deck>forward|forward>target`;
  - `ok    switch ease max … deg/s`, `ok    reduced cut`, `ok    mapping at ease end`;
  - `ok    re-aim on aim exit`, `ok    no re-aim on walk`;
  - in `camera-test`: `ok    console returns to deck|forward exact`.
- **Green:**
  - **The Target view:**
    - aim order: the hole, then the stop's body (`rel_km` through the attitude basis), then the destination;
    - pitch clamp [−10°, 60°], handing over to Forward above 60°;
    - the aim sits 1/3 from the top;
    - back 4.0 m, rise 0.6 m;
    - re-aim with one ease when the aim leaves the middle 60%.
  - **8 = Target.**
  - **Cues:**
    - departure, cruise and braking → Forward;
    - the end of the stop turn → Target;
    - Sgr A* → Target (aim = hole).
  - **`sky_side` and `sky_aft`** stay for tools only (OQ3).
  - **`restore()`** returns to the previous view id.
  - **HUD key hints** (`ui/ship_controls.gd`).
- **Check:** AC1 (target), AC2 (target), AC3 (target, after switch), AC6, AC7.

### F3: goldens, captures, migration, evaluation, landing (~300 LOC, 1.25 days)

- **Goldens.** Re-pose one for one (design §D8). G-CAM-1 is Forward at spawn and at helm plus Target on the hole (9). G-CAM-2 is Deck at spawn and at the rail, Forward and Target, × 2 (8). G-CAM-3 is Deck and Forward (2). `make golden` must show 393 ok lines. If any non-camera case moves, stop and list the diff for Mark.
- **Captures.** `tools/camera_views_capture.gd` gets the new view list (Forward, Target, Deck, legacy Commons, lift) × rest, 0.99c, stop and Sgr A*, at 720p and 1440p, with pole, target and head gates. `make camera-walk-capture` follows. Open every frame and publish the after-sheets to `gs://stapledons-voyage-assets/refs/camera_forward/after/`.
- **Migration** (design §D10 list):
  - rewrite or retarget about 11 tests;
  - run the make-target smoke of each capture tool that names a renamed view id;
  - remove the dead bridge sector paths (the legacy fence stays);
  - add a changelog fragment;
  - update the `demos/README.md` controls.
- **Evaluate.** An independent model (not the executor) runs the `sprint-evaluator` skill; 70 to pass. Apply its should-fix items.
- **Land:**
  - move the doc and sprint to `implemented/r2/` and update the README index;
  - update the design repo's roadmap status;
  - re-plan the deck layout (D-90) as a separate attended step.
- **Check:** AC10–AC13, a full `make test` and `make golden` on the rig before merge. AC14 at landing.

## Acceptance criteria

These are the design doc's AC1–AC14; each row names its exact command and log line. The executor runs them in milestone order, and the evaluator re-runs them on the PR head.

## Pause points

1. **After F1b:** the dev tag; Mark plays Forward and Deck (a visible feature, so attended).
2. **Any golden outside G-CAM-1..3 moving:** stop, list the diff for Mark.
3. **The bridge yaw sweep finds no yaw with 0 blocks after fades:** stop and ask. Options are a second named occluder or a slide box that keeps the camera off the blocked arc. Never a turning camera.
4. **Before merge:** after-captures opened by eye (gate 2); `make test` and `make golden` green on the rig.

## Risks

See the design doc's table. Planning-specific:
- **The occluder fade is new machinery.** It has its own milestone (F1b) and a cheap fallback (hide).
- **Test migration is the largest unknown.** About 11 tests touch player views, so F3 carries 1.25 days.

## Velocity

R2-CAMERA landed about 1,700 LOC in 5.5 planned days, about 310 LOC/day including evaluation fixes. This sprint is about 1,320 LOC in 4.0 days, about 330/day. The Forward rig reuses `_sky`'s geometry and the sweep reuses `sweep()`, which saves about a fifth.
