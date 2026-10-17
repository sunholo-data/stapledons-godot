# R2-CAMERA evaluation (independent)

Evaluated: PR #270, branch feat/camera-fixed-views at b6493fa (C1-C4; C5 held by design). Evaluator: Claude Sonnet 5.5 (different agent from the executor). Fresh clone, pinned runtime v0.54.11 as the branch pins it.

**Score: 79 / 100. PASS (70).**

| Rubric line | Score | Notes |
|---|---|---|
| ACs and behaviour (30) | 24 | AC1-AC11 pass as written. Deductions: under-way default is Sky forward, not Z2 (unapproved deviation, design doc not updated); lower-deck clear line is not met everywhere (ceilings Z1 2, Z2 2, Z3 39 of 1,881 samples blocked, AC1 says every sample); Sgr A* framing defect (below); trackpad accumulator never decays. |
| Physics and goldens (25) | 20 | Goldens green, 390 ok, no existing case moved. Deductions: Sgr A* not framed by any player view and G-CAM-1 uses spawn and helm, not the Sgr A* forward pose the design named; invariance test is near-tautological (one foot point, pure translation of a far point); G-CAM-2 discriminates the eye only at the cap cases. |
| Tests and gates (20) | 18 | `make -k test` exit 0; camera-test 131 passed; golden exit 0. 7 of 7 mutations caught. Minus 2: a mutated lens FOV is caught only by the schema test, not by any golden (CPU and GPU share the camera FOV). |
| UX and accessibility (15) | 10 | Reduced motion and cue prompts work and are tested. Deductions: lower-deck Z2/Z3 frames are cluttered (a pillar fills a third of the Z3 frame, captain about 45 px), Z2 at 0.99c is a black half-sky, no Sgr A* view, wheel up/pan direction inconsistent. |
| Hygiene and docs (10) | 7 | Changelog, README controls, pins and Makefile text updated, OK under make 3.81 and GNU make 4.4.1. Deductions: branch 6 commits behind main (runtime pin v0.54.11 vs main's v0.54.14; textual conflicts below); design doc not updated for the deviations; sprint JSON status in_progress with no milestones array. |

## Gates
- `make -k test AILANG=runtime/bin/ailang`: EXIT=0. `camera-director: 131 passed, 0 failures`. Transition peak rates 90 deg/s.
- `make golden`: exit 0, 390 ok lines (the new pin). Main's golden, run on origin/main 50242fa with v0.54.14: 374 ok, exits 2 against its stale pin 373 (explained: main's own pin is wrong by one). The 374 non-G-CAM lines are identical on the branch (timings stripped, sorted diff empty); only the 16 G-CAM lines are added (6 + 8 + 2).
- `make camera-views-capture`: 86 frames, 0 failures.

## Physics
- G-CAM-1 compares the rendered pole to `camera.unproject_position` (CPU). G-CAM-2 compares the rendered unit-gain glow to `ForwardGlow.profile(pole, wall_cos)` and the wall cos to a closed-form ray-sphere hit (CPU). G-CAM-3 compares the final frame to the sky SubViewport. None compares GPU with GPU.
- `sync_sky` takes the same camera pose; no backdrop. All views |eye| <= 93 m (worst 92.96).
- Mutation, golden: glow `cam_ship` fixed to the captain's eye. Caught by 2 G-CAM-2 cases (z2 and z3_bridge at the 1-beta 2e-9 cap). The z1, sky_forward and all 0.99c cases still passed, because those eyes are within 1 % of the captain's.

## Mutations (scratch copy, `make camera-test`)
| Mutation | Result |
|---|---|
| step by 2 per input | caught (wheel, pan, pinch checks) |
| cue does not end on input | caught (AC6, 4 checks) |
| reduced motion still animates | caught (AC7, 4 checks) |
| Sky forward pitch 10 deg (pole out of frame) | caught (sweep: 4803 samples, plus 7 key) |
| Z2 at 26 m / -50 deg (outside the bubble) | caught (95.00 m envelope, 58 px figure, AC5 jump) |
| spawn occlusion (Z2 turn 0) | caught (533 blocked samples) |
| lens FOV 60 in views.json | caught (schema) |

## Ruling and approvals
Met: no free zoom or mouse look (tested); three levels; third person; console focus is a framed screen with the wheel and pinch owned by the panel; no player rotation; cues end on any input and become prompts under reduced motion; no exterior view for players; 78 degree perspective; F8 and --free-camera are developer-only. Not met as ruled: "Z2 default" holds only at rest; under way R and the departure cue give Sky forward.

## Input probes
Burst plus inertial tail gives exactly 1 step. Pinch noise 30 x 1.03 gives 1 step. Keyboard (= - 1 2 3 R 7 8 9, F8) and controller (RB, LB, D-pad, R3) map to named actions; NT5 passes.
- Pan with a 0.35 s gap in the middle of one inertial tail gives 2 steps.
- Pan 0.6, idle 10 s, pan 0.5 steps (the accumulator never decays).

## Renders opened (12+)
cruise_default b9, b99, b999 (starbow in frame, captain visible; b999 is an orange glow wash, physics), z1, z2, z3_bridge at rest (captain visible, ring at Z3), z2 at 0.99c (black sky, expected), sky_side at a stop (good), sky_forward at Sgr A* (no hole in frame), z2_lower and z3_commons (cluttered), z2 stop at 1440p (fine). Nothing clips; the captain is never occluded in the frames viewed.

## Confirmed defects
1. **Sgr A*: no player view frames the hole at the close stops** (coordinator-confirmed, fix pending). The sgr_a capture is the 10^6 r_s first hover along the ship axis; sky_forward shows only Milky Way. Effect: -3 ACs/behaviour, -4 physics (G-CAM-1 lacks the Sgr A* pose). Evaluated commit b6493fa; the delta needs a separate check.
2. Under-way default (`CameraDirector.default_view`, demos/camera_director.gd about line 481) is Sky forward, contradicting the approved "Z2 default"; the design doc is not updated.
3. Lower deck: `LOWER_CEILING` Z3 39 blocked samples (tests/test_camera_director.gd:35); the Commons frames are cluttered.
4. `CameraDirector.pan` accumulator has no decay (demos/camera_director.gd, pan()).
5. Integration with #267: textual conflicts in demos/ship_geometry_demo.gd and design_docs/README.md; ship_consoles.gd, main.gd and the tests auto-merge. #267 `leave()` code must be re-read against the director's `restore()` (the `_eye` removal), and the crew console's `key()` runs before `_camera_action`, which is compatible. Branch also needs rebasing on main (v0.54.14 pin).

## Suggested fixes
Add a black-hole view and per-stop captures; keep Z2 as the under-way default or amend the design with Mark's approval; decay `_pan` (for example reset after 0.5 s idle); add an eye-sensitive 0.99c G-CAM-2 tolerance or a FOV-sensitive golden; rebase on main after #267.
