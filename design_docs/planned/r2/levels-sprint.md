# Sprint R2-LEVELS: the level pipeline, and the Commons as its first full run

**Design doc:** [levels.md](levels.md). **Process doc:** [design_docs/levels/README.md](../../levels/README.md). **Backlog:** [design_docs/levels/backlog.md](../../levels/backlog.md).
**Sprint JSON:** `.ailang/state/sprints/sprint_R2-LEVELS.json`
**Status:** **Approved** (ledger D-103, 2026-10-20, with every recommendation; the charter rows are on main). LP0/LP1a complete. D-130 (2026-10-29) resumes LP1b–LP4 through [R2-VIEW-FINISH](bridge-commons-finish-sprint.md), which owns current concurrency and review sequencing. D-104/D-106 remain binding. Historical merge holds below are cleared by D-125; current runtime ownership is assigned by the overlay. S3 and S5 approval gates remain.
**Base:** `origin/main` 8e49c160, on branch `design/levels`.

**Shared files, and how the sprint is split.** R2-BRIDGE-STYLE (approved as D-100, executing) and DL3 (#292) hold `data/camera/views.json`, `demos/camera_director.gd`, `tests/test_camera_director.gd`, `demos/ship_demo_lift.gd`, `demos/ship_lighting.gd` and `demos/ship_star_light.gd` on the charter's do-not-touch line. This sprint never edits the bridge's art, lighting rig or HUD.
- **LP0 and LP1a start on approval.** They use only new files plus `interior/walk.gd`, `mk/levels.mk` and one `Makefile` include and bench branch. The `Makefile` is released on the do-not-touch line.
- **LP1b waits for those merges.** It edits the held files: `views.json` v3, the vertical camera, the lift and per-level light.

**AILANG:** v0.54.18 (current pin). The sprint writes no `.ail` code, so the syntax gate is skipped. Registry reuse: none (Godot tools, data and Blender assets; no maths for `sunholo/relativity`).

**Estimate:** about 2,350 game LOC plus about 600 lines of `bpy`, over **14.5 working days**, or **16 with buffer**. Mark's time at the two pauses is extra.

| | Days | LOC |
|---|---|---|
| LP0 | 1 | ~300 |
| LP1a | 3 | ~750 |
| LP1b | 3 | ~650 |
| LP2 | 2.5 | ~300 |
| LP3 | 4 | ~150 + bpy |
| LP4 | 1 | ~200 |

That is about 160 LOC a day, below the recent attended rate of about 300 (R2-CAMERA). Blender, retiring the legacy Commons, the captures and the shared rig dominate.

**Cut list,** applied in this order if a cap is hit, and noted in the JSON:
1. the service gallery stage (and its hatch) moves to a revisit;
2. the N-stop lift generalisation (the Commons needs only two stops);
3. the enclosed view.

## What the survey found

- **The camera keys views by level** (`views.json` v2; `levels.commons.legacy`; `CameraDirector` branches on `legacy` at `demos/camera_director.gd:233, 257, 469, 589`). The lift's arrival selects the level default (AC-V10 expects `z2_lower` for the Commons today).
- **Walk height is "highest hit"** (`WalkArea.height_at`, `interior/walk.gd:49`), so a captain under a terrace would be put on top of it. Multi-height needs a nearest-surface rule.
- **The lift is two-stop** (`demos/ship_demo_lift.gd`, 80 lines; gates at 82 and 57; an 11 s ride).
- **The evaluator pattern is ready to generalise:** `tools/deck_bow_metrics.gd` (289 lines), `tools/deck_layout_eval*.gd`, `mk/deck-layout.mk`, and the thresholds and budgets in data.
- **In-engine greybox works:** `tools/levels_intricate_mock.gd` (this branch) builds 30 primitives with colliders over the real ship. It measures traversal (7 surfaces, 4 heights, 0 unreached), head and pole rays per surface, the ceiling clamp (26% → 9.5% of floor samples with the head hidden, as LP1a measured it; the mock first printed 22% → 8% because of duplicate piece names) and finds in frame, and renders through the live sky. The whole run takes under two minutes.
- **The Commons exists:** the painted court and arcade, a coarse remainder, a walk mesh and the lift landing. It is lit by the bridge's rig; the spire light stops above its deck.

## Milestones

### LP0: process, schema, backlog and the bridge baseline (~300 LOC, 1 day; starts on approval)
- **The process docs are on the branch:** `design_docs/levels/README.md`, `TEMPLATE.md`, `backlog.md` and `commons.md`. LP0 makes them checkable.
- **Red first:** `tools/levels_backlog.sh`.
  - `--check`: every row has a known id, a status from the fixed set and a valid "who". A bad-status fixture fails.
  - `--next`: lists only loop-eligible items. A fixture with a level in S3 is not listed.
- **Red first:** `tests/test_levels.gd` (new `make level-test`) validates `stapledons.level/1`:
  - a stage view with a yaw rule is rejected;
  - so is an exit to an unknown stage;
  - so is a route missing an end;
  - so is a `captain_px` band outside 30–90.
- **`mk/levels.mk`,** included from the `Makefile`, with `test: level-test level-eval-test levels-regress` (the last two are added in LP1a).
- **The bridge as a level, as data only:** `assets/levels/bridge/manifest.json` (one stage, `deck`, today's Bow and Astern values) and `art/levels/bridge/baseline.json` pinned from today's bridge numbers. The camera doesn't read this manifest until LP1b.
- **Gate:** `make level-test`; `sh tools/levels_backlog.sh --check`; `make deck-layout-eval` (`bridge ok`).

### LP1a: greybox, walk, evaluator, captures, regression and bench (~750 LOC, 3 days; starts on approval)
- **`LevelGreybox`** (`demos/level_greybox.gd`), from the mock: builds `art/levels/<id>/layout.json` as role-coloured primitives with colliders and walk surfaces, and writes the manifest. A dev build can ship a greybox level.
- **Multi-height walk (red first):** `WalkArea.height_at_near(x, z, y_now, 0.45)`, used by `step`.
  - On a two-floor fixture, the captain under the upper floor stays on the lower one.
  - A ramp joins them.
  - A hatch at an overhang's edge is a valid transfer end.
  - A sweep over every bridge walk sample is unchanged.
- **Routes:** stairs and ramps are walkable. Ladders and hatches are use-point transfers until climb clips exist (the `clip` field).
- **`LevelMetrics` and `make level-eval LEVEL=<id>`:**
  - every §B5 metric, including the ceiling clamp, applied by the metric's own pose rule (the camera code follows in LP1b and is tested against the same rule);
  - thresholds in `art/levels/<id>/thresholds.json`;
  - inputs: a greybox layout or an exported level through `asset_dir`, with a fixture for each.
- **Red first, `tests/test_level_eval.gd` (`make level-eval-test`):**
  - the positive control is the mock greybox as a fixture layout, which reproduces its numbers (7 surfaces, 4 heights, 0 unreached, floor head behind greybox 163 → 59 with the clamp, 81 tower pole blocks);
  - seeded defects each fail by name: a route removed (`unreached`), a box on the pole line (`pole-ray`), a roof lowered 5 m (`band-top`), a find walled off without a cue (`find-sight`).
- **`make level-capture LEVEL= TAG=`** (GPU): Bow and Astern per stage and surface, at rest, at 0.99c and at a stop, plus set pieces, a diagnostic overview, the sheet, `metrics.json` and `frames.sha256`. It exits non-zero on a missing or blank frame.
- **`make levels-regress`:** every `art/levels/*/baseline.json`. Its negative controls must both fail: a seeded change to the bridge, and a landed layout whose sha256 changed without a change-log row.
- **`make bench SCENE=level LEVEL=<id> [STAGE=]`:** a new branch beside `SCENE=bridge` (`Makefile` bench target, about 60 LOC, reusing `tools/m4_ship_bench.gd`'s measurement).
- **Gate:** `make level-test level-eval-test levels-regress`, and `make bench SCENE=level LEVEL=bridge` runs.

### LP1b: the camera, views v3, the lift and light (~650 LOC, 3 days; after #292 and R2-BRIDGE-STYLE's held files merge)
- **`views.json` v3:** global camera settings only. `CameraDirector` reads levels from manifests, including the bridge's from LP0. Its readers move in the same commit: `demos/camera_director.gd`, `demos/ship_geometry_demo.gd`, `tests/test_camera_director.gd` and `tools/deck_bow_metrics.gd`. AC11 (`bridge ok`) holds.
- **The vertical camera (red first, `make camera-test`):**
  - the slide follows the floor height with F1's vertical dead zone, and the yaw spread stays 0.0000° over a climb;
  - the **ceiling clamp** eases in when a surface is overhead within 8 m and out after, using the same rule as `LevelMetrics`;
  - the enclosed view for crawlspace stages;
  - reduced motion cuts.
- **Physics gate for the new poses (§C6):**
  - check values in `tests/test_physics.gd`: the pole's screen position through the clamp and raised poses, and the band edge against the slab model within 0.5°;
  - `make golden` cases G-LVL-1 (the clamp) and G-LVL-2 (the raised pose): GPU vs CPU, the starbow at 0.99c;
  - references opened.
- **The lift with N stops** (`assets/levels/lift.json`): 6 m/s plus 0.8 s transfers, a `ride` view that slides only vertically, a skip key, and reduced motion cutting.
- **Per-level light:** a spire segment with a range bounded by its ceiling, practicals from the manifest, and the star handover on the active level. The bridge's own rig stays as R2-BRIDGE-STYLE leaves it.
- **Gate:** `make camera-test camera-forward-test level-test ship-demo-lift-test ship-star-light-test ship-console-test deck-layout-eval physics`; `make golden` (the existing count plus G-LVL-1 and G-LVL-2, 0 failures).

### LP2: the Commons, S1–S3 (~300 LOC, 2.5 days) ⏸ Mark plays the greybox
- **S1:** `art/levels/commons/layout.json` v1 from the approved brief (`design_docs/levels/commons.md`):
  - the stages `landing`, `court`, `terrace`, `gantry` and `service`;
  - the routes;
  - the finds with cues;
  - the set pieces;
  - the light.

  It is layered over the existing painted court and arcade, which stay as the court's floor and far structure. `art/levels/commons/thresholds.json` is approved with the brief.
- **S2:** iterate until `make level-eval LEVEL=commons` prints `level-eval: commons ok`. Known starting failures from the mock:
  - the civic tower stands on the pole line;
  - the captain's head is hidden under the terrace at 8% even with the clamp;
  - finds are hidden from the court's first view.
- **Retire the legacy Commons:**
  - `levels.commons.legacy`, its sector views, the player Z1–Z3 keys, and the `legacy` branches in `camera_director.gd` go;
  - AC-V10 expects the Commons' default stage;
  - the Commons' goldens and tests that pose the old views move in the same commit, with their references recomputed by their CPU or sim references, never re-recorded from the GPU.
- **S3 pause:**
  - a dev build (`make publish-dev`, no `v*` tag);
  - `make level-capture LEVEL=commons TAG=s3` (every frame opened);
  - the contact sheet, per-file URLs and the brief's checklist.

  Mark plays. His ruling is recorded (ledger plus the brief's Rulings section) and `backlog.md` is updated.

### LP3: the Commons, S4–S5 (~150 LOC + ~600 lines of bpy, 4 days) ⏸ Mark approves the style
- **S4:** `~/dev/blender/scripts/stapledon_level_lib.py` and `stapledon_level_commons_v1.py`.
  - The shared library reads `layout.json`, exports hero, coarse, walk, cards and the manifest, and packs itself into the master.
  - The Commons script reuses the existing kit (ribs, rails, benches, planters) and adds modules for the terrace, stalls, gantry, balcony and service gallery.
  - Two runs give byte-identical exports. The master is pinned in the bucket.
  - **Gate:** `make level-assets-check LEVEL=commons`, `make level-eval LEVEL=commons` on the export, and `make export-filter-audit`.
- **S5:** style frames on R2-BRIDGE-STYLE's finish, lit by the spire segment and practicals.
  - `make level-capture LEVEL=commons TAG=s5`, with every frame opened.
  - `make bench SCENE=level LEVEL=commons` (p99 < 16.7 ms at 2560×1440, quiet rig).
- **S5 pause:** Mark approves the style or redirects. The ruling is recorded.

### LP4: landing (~200 LOC, 1 day)
- **S6 checks:**
  - pin `art/levels/commons/baseline.json`;
  - `make levels-regress`;
  - `make test` on the rig (`tools/rig_check.sh`);
  - `make golden`;
  - `make level-capture LEVEL=commons TAG=after`;
  - a dev build.
- **Write-up and review:** `design_docs/implemented/r2/levels-report.md`, a changelog fragment, and an independent evaluation (`sprint-evaluator` on Sonnet; the executor is Opus).
- **Landing:**
  - the docs move to `implemented/r2/` (the process docs stay in `design_docs/levels/`);
  - `backlog.md`: the Commons becomes `landed v1`, and the Garden moves to `S0-brief`;
  - a design-repo PR, not merged by the executor: the seven-tier table and stage model in `ship-structure.md`, the interior brief's lower levels, and the roadmap row.

## Pause points

| After | Mark sees | Mark decides |
|---|---|---|
| Plan | This plan, the design doc, the process docs, the Commons brief, the proposed charter rows (§A6), and the mock frames (`refs/levels/mock/`, `refs/levels/intricate/`) | OQ1–OQ10, the Commons brief and thresholds (S0), and the charter rows (recorded in that session) |
| LP2 (S3) | A dev build of the Commons greybox: five stages, routes, finds, the balcony at a stop; the contact sheet; per-file URLs; the 7-line checklist | Accept the layout, or ask for moves (back to S2) |
| LP3 (S5) | Style frames of the dressed Commons on the R2-BRIDGE-STYLE finish; the bench | Approve the finish, or redirect |

## Risks and day caps

- **LP1a and LP1b are each capped at 3 days.** If either overruns, apply the cut list in order and note it in the JSON.
- **Held files.** LP1b can't start until #292 and R2-BRIDGE-STYLE's camera, lift and lighting files merge. LP0 and LP1a fill that wait, and LP1b rebases daily.
- **Too many routes.** If a stage's `head` or `find-sight` can't pass, the brief loses a surface rather than gaining a threshold exception. Thresholds change only with Mark.

## Validation (each milestone)

The targeted gates are listed per milestone. The full `make test` runs on the rig before each pause and at landing, and `make python-guard` confirms no new Python.
