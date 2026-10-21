# R2-CAPTAIN-ANIMATION: the captain moves like a person on the bow-facing bridge

**Status:** Approved by Mark on 2026-10-20 (ledger D-102), every recommendation: "yeah painted animation no mannequin. I will review animations of it on website". The brief amendment (design PR #34) is merged. Executing CA0 and the CA1 pilot on `feat/captain-animation`; Mark reviews the pilot as animations on a web page.
**Release:** R2. **Milestone:** the player's captain animated in the fixed Bow and Astern views: idle, walking and jogging with the feet planted, facing the way they move, using each station, sitting in the chair, riding the lift, and looking up at arrivals.
**Priority:** P1 for R2. The captain is on screen in every player view (third person, D-91).

**Mark's direction** (verbatim):
> 2026-10-20 (D-98), after playing the bow-facing bridge: "it looks really great. obviously we need animation on the captain a bit and sound effects and the level design but such good potential"
> 2026-09-28, on the Blender medic character study: "the character study is aweful. I think we will instead generate images that are much richer and expressive, and not use animation, just change expression as we go."

D-98 lifts the 2026-09-28 "no animation" rule **for the player's captain only**. The rule's reason (a Blender person looked poor next to rich painted art) still stands, and it decides this design's main choice (§D1).

**Implements** (design repo):
- [vision/design-decisions.md](https://github.com/sunholo-data/stapledons-design/blob/main/vision/design-decisions.md) 2026-09-28 "Character and Exterior Review: Static Portraits" (amended here for the captain by D-98), and the 2026-10-03 picked identity "A, Longline Navigator".
- [art/characters-blender-brief.md](https://github.com/sunholo-data/stapledons-design/blob/main/art/characters-blender-brief.md) §1 and "Motion" (static art; amended by a design-repo PR for the captain), [art/handoff-codex-art.md](https://github.com/sunholo-data/stapledons-design/blob/main/art/handoff-codex-art.md) (the avatar canvas contract: 1024 × 1536, foot anchor (512, 1440), 720 px/m, mirror-safe).
- This repo: [camera-forward.md](../../implemented/r2/camera-forward.md) §D2, §D3, §D6 (the slide rig; facing from motion on screen), [deck-layout.md](deck-layout.md) (use points, the chair, the spawn), ledger D-91, D-93, D-96, D-98.

**Depends on:** R2-CAMERA-FORWARD (landed), R2-DECK-LAYOUT DL3 (#292, `manifest.stations.<id>.use_m`, the chair), and the styling pass R2-BRIDGE-STYLE (#293) for the final look of everything around the captain. CA1 starts after #292 merges, because both edit `demos/ship_geometry_demo.gd`. No physics: `sunholo/relativity`, the sim, the protocol and replays are untouched. The avatar never goes to the sim.

**Estimated LOC:** game repo about 1,400 (the animation state machine 260, demo and console wiring 120, the chair interaction 60, station and chair timings 80, the frames check 220, the capture tool 200, tests 360, manifest and data 50, make wiring 50). Generation glue (shell, prompts) about 150. Pose-guide Blender script about 300 lines of `bpy` in `~/dev/blender` (an authoring tool, not shipped).

## Game vision alignment

Scored with the `game-vision-designer` skill (feature-validation mode, against `vision/core-pillars.md` and the 2026-09-28 and 2026-10-03 character decisions), 2026-10-20. **ALIGNED.**

| Pillar | Score | Rationale |
|---|---|---|
| Choices Are Final | 0 | Neutral. Presentation only; no decision moves |
| The Game Doesn't Judge | 0 | Neutral. Poses never comment (no slumped "failure" walk) |
| Time Has Emotional Weight | +2 | The captain ages on the ship's clock (stages 0, 20, 40, 60 years) and now **moves** their age: gait, posture and pace change with the stage. The look-up at an arrival or as the starbow forms puts a person's reaction in the frame |
| The Ship Is Home | +2 | A person walking their deck, leaning on the helm, sinking into their own chair, instead of a cut-out sliding across the floor |
| Grounded Strangeness | 0 | Neutral. The sky is untouched; the figure never occludes the pole (the existing camera checks hold) |
| We Are Not Built For This | +1 | Human scale against the bubble: a 1.75 m figure with a real stride under a 100 m dome; the older stages move slower |
| **Net** | **+5** | **Go.** No pillar is negative |

## Problem

Measured in the spike (§Spike) and in play (D-98):

1. **The captain slides.** `interior/captain_avatar.gd` shows one painted still per life stage and facing; walking moves the still across the deck at 3.5 m/s with no stride.
2. **Sideways walks moonwalk.** `set_motion()` picks only `front` or `back` from the vertical screen motion; a walk to port or starboard keeps the last facing, so the captain glides sideways facing the bow (`demos/ship_geometry_demo.gd:374`). The four painted facings (`front`, `back`, `se`, `ne`) were drawn for the retired −14° isometric view; there is no profile.
3. **Stations and the chair have no poses.** At a console the captain's yaw and the camera turn to the station (`ShipConsoles.face`, `ship_consoles.gd:498`), but in the upright Bow and Astern views the still is turned to its back every frame while standing (`ship_geometry_demo.gd:436`). The chair is a prop: nothing lets the captain sit.
4. **3.5 m/s is a jog,** not a walk (a brisk human walk is 1.4–1.8 m/s). Whatever animates it must be a jog, or the speed changes (OQ2).

## Spike (2026-10-20): four ways, seen through the real Bow view

`tools/captain_anim_spike.gd` (committed with this plan; a spike, not a gate) renders the captain on a clear deck spot port of the helm through the real director at 2560 × 1440, where the figure is **161 px** tall (81 px at 1280 × 720). A rigged low-poly captain stand-in (`~/dev/blender/scripts/char_captain_anim_spike_v1.py`: the medic's 16-bone rig, the picked palette, 1,824 triangles, clips `run` 20 frames at 30 fps, `walk`, `idle`, `use_console`) feeds options B and C.

| Option | What | Seen at 161 px | Cost |
|---|---|---|---|
| **A** today | painted still per facing | rich, on-identity; slides; no profile | none |
| **B** live 3D | the rigged GLB in Godot with the props' ink outline (0.012 m) | a clear stride in every direction, but a **mannequin** next to the painted bridge. This stand-in is untextured and palette-flat, so it shows the **risk** of the failure Mark called "aweful" on 2026-09-28 (a large medic portrait), not proof that any 3D captain fails | 1.8 k triangles. Frame time **inconclusive**: every run sat at the 120 Hz vsync (8.33–8.36 ms mean on the Studio), so the spike could not see a cost; the bench settles it |
| **C** 3D pre-rendered | B rendered to 8-direction sprite frames, played on the billboard | the same mannequin look, flatter | sheet memory; no runtime cost |
| **D** procedural | today's painted still with bob, sway and step squash | on-identity and alive at rest, but the legs never move: a **gliding statue** when walking | none |

Frames (each opens on its own):
- In context, today: https://storage.googleapis.com/stapledons-voyage-assets/refs/captain_animation/spike/context_bow_1440p.png
- A, today's still (3×): https://storage.googleapis.com/stapledons-voyage-assets/refs/captain_animation/spike/A_painted_back_3x.png
- B, live 3D, jogging toward the bow (3×): https://storage.googleapis.com/stapledons-voyage-assets/refs/captain_animation/spike/B_glb_run_bow_3x.png
- B, jogging to starboard (3×): https://storage.googleapis.com/stapledons-voyage-assets/refs/captain_animation/spike/B_glb_run_starboard_3x.png
- C, pre-rendered sheet, toward the bow (3×): https://storage.googleapis.com/stapledons-voyage-assets/refs/captain_animation/spike/C_sheet_run_bow_3x.png
- C, to starboard (3×): https://storage.googleapis.com/stapledons-voyage-assets/refs/captain_animation/spike/C_sheet_run_starboard_3x.png
- D, painted with procedural motion, toward the bow (3×): https://storage.googleapis.com/stapledons-voyage-assets/refs/captain_animation/spike/D_painted_procedural_bow_3x.png
- D, the painted 3/4 still on a sideways walk (3×): https://storage.googleapis.com/stapledons-voyage-assets/refs/captain_animation/spike/D_painted_procedural_starboard_3x.png
- Numbers: https://storage.googleapis.com/stapledons-voyage-assets/refs/captain_animation/spike/spike.json; the stand-in GLB: https://storage.googleapis.com/stapledons-voyage-assets/refs/captain_animation/spike/captain_anim_spike_v1.glb

**Reading:** the stride must come from the rig (B and C prove the timing, the facings and the foot plants), and the **look** should stay painted (A and D, and the 2026-09-28 ruling). So the recommendation is a hybrid: **painted frames, posed by the rig** (§D1).

**Not yet tested:** the recommendation itself. Whether the image generator holds identity, pose and foot contacts across a cycle is the plan's main unknown, so CA1 opens with a **10-frame pilot** (§D1 step 2) that must pass the consistency check and Mark's glance before the rest is painted.

## Goals and non-goals

**Goals:** a painted captain who walks or jogs with planted feet in all eight screen directions in the Bow and Astern views; idle that breathes; start and stop; station use at three use heights; sit and stand at the chair; a lift-ride idle; a look-up on authored cues; four life stages; reduced motion; deterministic, headless-testable animation state.

**Non-goals:** crew on the deck (they stay portraits and static mini avatars, 2026-09-28); facial animation (expressions stay portrait swaps); the legacy painted-plate interior (keeps its stills); cloth simulation at runtime; any change to camera behaviour, speeds (unless OQ2 says so) or the sim.

## Design

### D1. Painted frames, posed by a rig (recommended; OQ1)

1. **Pose guides.** A Blender script (`~/dev/blender/scripts/char_captain_pose_guides_v1.py`, from the spike rig; a copy packed in its pinned `.blend`, as the bridge masters are) renders each clip frame in each painted facing as a flat grey silhouette with coloured limb keys, on the avatar canvas contract (1024 × 1536, foot anchor (512, 1440), 720 px/m, orthographic). **Guide elevation is 29°**: the line of sight from the Bow and Astern eyes (9 m back, 5.5 m up, pitch −8°) down to the captain, which ranges about 27–31° across the deck. Today's stills were painted for 14° (the retired iso view); CA0 keeps them as stand-ins, and the Z1–Z3 developer presets are not targeted. The guides, their sha256 pins and the prompts live in `art/captain-anim-v1/` (this repo), with the files in `gs://stapledons-voyage-assets/captain/<sha256>`.
2. **Painted frames, pilot first.** The art thread (Codex "Sol 6.1" agents with the built-in image generator, the pipeline that made today's avatars, `assets/characters/captain/generation_notes.md`) paints each frame as an identity-preserving edit: inputs are the picked identity sheet and the frame's pose guide; the prompt is today's avatar prompt plus "match this pose". Post-processing stays the handoff's (alpha cleanup, uniform downscale, translation). **A 10-frame pilot** (one jog cycle's key poses in `back` and `profile`) must pass `captain-frames-check` and Mark's glance before the rest of age 0 is painted. **This is API spend; it waits for Mark's go (OQ5)** and for the design-repo amendment of the brief's "Motion" section to merge.
3. **An automated consistency check** (`make captain-frames-check`, §D4) rejects frames before anyone looks: palette, silhouette agreement with the guide, foot anchor, canvas.
4. **Contacts come from the paint, not the guide.** After a frame passes, its sole contacts are measured from its alpha (the lowest opaque rows per foot, as `generation_notes.md` already measures the stills), and `stride_m` and the per-frame contacts in the manifest are written from those measurements.
5. **Display** stays the existing `Sprite3D` billboard (`CaptainAvatar`), now fed by an animation state (§D2), with D's procedural layer (a 2–3 cm bob in phase with the stride, a lean into starts and stops) on top.

Why not B (live 3D): it is the cheapest to animate and turns for free, but its look is the main risk Mark has already ruled on, and a painted-looking 3D person is a modelling project with no guarantee. **Fallback:** if the pilot or a later batch fails the consistency check or Mark's review twice, the plan switches to a painted 3D captain (B, textured like the DL2 props) as a re-plan, not silently.

### D2. The animation state (pure, headless)

A new `interior/captain_anim.gd` (`class_name CaptainAnim`, `RefCounted`, no nodes) maps inputs to what the billboard shows. It is a pure function of its inputs and its own small state, so it is testable headless and deterministic.

- **Inputs, per frame:** ground velocity (m/s, ship frame), the active view's yaw (Bow or Astern), the station state (`none`, `approach`, `use:<height>`, `leave`), chair (`none`, `sit`, `seated`, `stand`), lift (`riding` or not), the life stage (from ship years, as today), cue events (`look_up`), reduced motion, `dt`.
- **Outputs:** clip id, frame index, painted facing key, `flip_h`, the procedural offsets (bob, lean), and foot-contact events (`foot_down` L or R with its deck position).
- **Facing:** the velocity's direction **on screen** (relative to the view yaw), quantised to 8 sectors with 10° of hysteresis; at rest it keeps the last facing, at a station or in the chair it faces the bow (which shows `back` in Bow and `front` in Astern). Painted facings: `back`, `back_34`, `profile`, `front_34`, `front`; the other three mirror (the identity is mirror-safe, 2026-10-03). This fixes the moonwalk. The demo's per-frame turn to the back (`ship_geometry_demo.gd:436`) is removed.
- **Frames advance with distance, not time:** `phase += |v| · dt / stride_m`. At rest the phase holds, so feet cannot skate by construction.
- **Gait numbers:** the spike rig's jog is a 2.33 m cycle (20 frames at 30 fps at 3.5 m/s, 0.67 s); 8 painted frames a cycle show at 12 frames a second. Below 0.2 m/s idle; walk up to 2.2 m/s (only if OQ2 adds one); jog above. Start and stop are short clips (0.25 s, 0.3 s) triggered by the speed crossing 0.2 m/s.
- **Stations:** three use heights (the desks 0.95 m, the pods 1.1 m, the navigation arc 0.85 m) map to `use_low`, `use_mid`, `use_high` clips: reach (0.4 s), a held loop, step back.
- **Chair (new interaction, OQ9):** E at the chair's seat point (the console key) walks there and plays sit (0.6 s), then a seated loop; any move key plays stand (0.5 s) first, then walking resumes. The camera stays in its view; no station behaviour while seated.
- **Lift:** a standing idle with a hand on the rail.
- **Look-up:** a 2 s head-and-chest lift on authored cues (arrival at a stop, the starbow forming; the director already raises these situations). Skipped under reduced motion.
- **Reduced motion:** keeps the stride (it stops the sliding) and the station and chair poses; drops the bob, the lean, idle fidgets and look-ups.
- **Age:** the stage picks the frame set. Older stages move at the same speed (the camera and tests need one speed) with their own stride, measured from their frames (OQ4).

### D3. Data and memory

`assets/characters/captain/manifest.json` grows a `clips` section (schema v2; v1 stills keep working): for each clip its frame files per stage and facing, `fps` (time-based clips), `stride_m` (gait clips), loop flag, and per-frame contacts and trim offsets. The directory is the same literal `res://assets/characters/captain` the stills load from, so `export-filter-audit` covers it as it covers the stills; the export filter adds `*.webp` there.

- **Cells:** each painted frame is downscaled to a 192 × 288 cell (1.5× over the 161 px figure at 2560 × 1440), trimmed to its alpha bounding box with the offset in the manifest, and shipped as one WebP per frame (no atlas, so no texture-size limit). The billboard swaps textures per frame.
- **Counts** (from §D7): 19 frames in each of 5 painted facings for the moving clips, plus 15 station and chair frames in each of 4 facings (Bow shows `back` and `back_34`, Astern `front` and `front_34`): **155 frames a stage**, **620 in all**; with a walk (OQ2) 195 and 780.
- **Disk:** ≤ 3 MB of WebP a stage, ≤ 12 MB in all.
- **GPU memory:** trimmed cells average about 130 × 270 RGBA with mipmaps, about 190 KB each: **about 30 MB a stage**. Bound: **≤ 32 MB for the loaded stage**, computed by `captain-frames-check` from the shipped files and read back from the renderer in the bench. Only the current stage is loaded; the next stage loads in the background a year of ship time before it is due.

### D4. Checks

Each check names where it runs: **headless** (any machine, in `make test`), **rig** (the Studio GPU window), or **human**.

- `make captain-anim-test` (headless, new, in `make test` from CA0): the state machine on scripted inputs: facing sectors for Bow and Astern (in CA0 a starboard walk shows the mirrored `se`/`ne` stand-ins, from CA1 a true `profile`, never the back); hysteresis; distance-driven phase (zero distance, zero advance); start, stop, station, chair (stand before walking away), lift and look-up transitions; reduced motion; determinism (the same input script gives the same output sequence twice); stance drift ≤ 2 screen px at 2560 × 1440 per planted foot, from the manifest's measured contacts and the camera's projection.
- `make captain-frames-check` (headless; joins `make test` in CA1, when the first frames land): every manifest frame exists; canvas and anchor; palette ΔE (CIE76) ≤ 12 on the coat, yoke and trouser regions against the identity palette; silhouette IoU ≥ 0.85 against the pose guide; the measured foot anchor within 3 cell px (2 screen px) of the guide's; disk and GPU-memory budgets. Positive and negative fixtures (a frame of another identity, a misplaced foot, a wrong pose).
- `make captain-anim-capture` (rig): strips of every clip and facing in Bow and Astern at 2560 × 1440, plus a contact sheet. Its machine half fails on a missing strip, a blank strip, or a gait strip whose frames are identical; a person opens the sheet before any pause point.
- Existing gates stay green: `make test` (headless), `make camera-test`, `make camera-forward-test`, `make deck-layout-eval`, `make golden` (rig; a captain-bearing case is re-posed only with the reason recorded), `make ship-demo-bench` (rig; p99 ≤ 16.7 ms at 2560 × 1440), `make export-filter-audit`.

Wiring: `mk/captain-anim.mk`, included from the `Makefile` (released for this by the loop's do-not-touch line), adds the three targets; `captain-anim-test` joins the `test:` prerequisites in CA0 and `captain-frames-check` in CA1.

### D5. Sound hook

`foot_down` events (with the side and deck position) and the station and chair transitions are emitted as signals, so the sound design (D-98's second track) can attach footsteps and console sounds without touching animation code.

### D6. Where the code changes

`interior/captain_anim.gd` (new), `interior/captain_avatar.gd` (frame display, trim offsets, flip, the v2 manifest), `demos/ship_geometry_demo.gd` (feed velocity, view yaw, station, chair, lift and cues; drop the front/back-only facing and the turn to the back), `demos/ship_consoles.gd` (station states, the chair's seat point and E), `mk/captain-anim.mk`, tests and tools. The legacy `interior/interior.gd` keeps the stills.

### D7. Clip list (frames per painted facing)

| Clip | Frames | Facings | Notes |
|---|---|---|---|
| idle | 4 | 5 | breath; one weight shift after 8 s |
| jog | 8 | 5 | 3.5 m/s, a 2.33 m cycle |
| walk | 8 | 5 | only if OQ2 adds a walk |
| start, stop | 2, 2 | 5 | |
| lift | 1 | 5 | |
| look_up | 2 | 5 | head and chest; procedural blend |
| use_low, use_mid, use_high | 3 each | 4 (`back`, `back_34`, `front`, `front_34`) | the captain faces the bow at every station (DL1): Bow sees the back, Astern the front |
| sit, seated, stand | 3, 1, 2 | 4 | the chair faces the bow |

Moving clips: 4 + 8 + 2 + 2 + 1 + 2 = 19 per facing × 5 = 95. Stations and chair: 9 + 6 = 15 per facing × 4 = 60. **155 a stage.**

## Acceptance criteria

| # | Criterion | Command | Runs | First checked |
|---|---|---|---|---|
| AC1 | The state machine passes its scripted cases: 8-sector facing in Bow and Astern, hysteresis, distance-driven phase, transitions (incl. stand before leaving the chair, look-up on a cue), reduced motion, determinism | `make captain-anim-test` | headless | CA0 |
| AC2 | No moonwalk: a scripted starboard walk in Bow and in Astern shows a side facing with the right flip in ≥ 95% of its frames, never the back (CA0: the mirrored three-quarter stand-ins; CA1: a true profile) | `make captain-anim-test` | headless | CA0, CA1 |
| AC3 | Planted feet: stance drift ≤ 2 screen px at 2560 × 1440 for every gait clip of every shipped stage | `make captain-anim-test` | headless | CA1 (age 0), CA3 (all) |
| AC4 | Every shipped frame passes the consistency check; the negative fixtures fail it | `make captain-frames-check` | headless | CA1 |
| AC5 | Budgets: ≤ 3 MB WebP a stage and ≤ 12 MB in all; ≤ 32 MB GPU memory for the loaded stage; one stage loaded | `make captain-frames-check`; `make ship-demo-bench` (memory read-back) | headless; rig | CA1, CA3 |
| AC6 | In game, every clip and facing in Bow and Astern; the head stays in frame and the pole in the Bow frame | `make captain-anim-capture` (machine half), then the sheet opened | rig; human | CA0 |
| AC7 | Nothing else moved: full suite, camera, camera-forward, deck-layout-eval, golden (re-posed cases listed), bench p99 ≤ 16.7 ms | `make test camera-test camera-forward-test deck-layout-eval`; `make golden ship-demo-bench` | headless; rig | every milestone |
| AC8 | The frames ship in the export | `make export-filter-audit`; the `make publish-dev` export smoke | headless; rig | CA1 |
| AC9 | Mark accepts the pilot, the look (CA1) and the feel (CA2) | ledger rows | human | CA1, CA2 |

## Sub-milestones and estimates

| Id | What | LOC | Depends | Pause |
|---|---|---|---|---|
| CA0 | `CaptainAnim` with today's stills (`se`/`ne` mirrored for diagonals and sideways), the procedural layer, the manifest v2 reader, `captain-anim-test`, the capture tool, `mk/captain-anim.mk` | 800 (state 260, wiring 120, capture 200, tests 200, data 20) | #292 merged | — (ships the moonwalk fix on its own) |
| CA1 | Pose guides; `captain-frames-check` (with fixtures); the 10-frame pilot; then age-0 idle, jog, start, stop, lift, look-up in 5 facings; contacts measured from the paint; dev build | 350 (check 220, tests 100, data 30) | CA0, OQ1, OQ5, the brief amendment merged | ⏸ Mark: the pilot, then the age-0 look (strips and a dev build) before more spend |
| CA2 | Age-0 stations and chair in 4 facings; the chair interaction (E, sit, stand); the sound hook; dev build | 200 (chair 60, timings 80, tests 60) | CA1 accepted | ⏸ Mark plays |
| CA3 | Stages 20, 40, 60 as identity-preserving edits of the age-0 frames; budgets; independent evaluation; landing | 50 | CA2 accepted | — |

About **1,400 game LOC over 9–10 working days** (about 150 LOC a day, half the recent attended rate, because captures and frame review dominate). The art turnaround and Mark's reviews are not counted.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Painted frames are inconsistent (the 2025-12 failure of AI tile art) | Pose guides fix the pose; the identity sheet is an input; the 10-frame pilot first; `captain-frames-check` rejects outliers; the figure is 161 px; Mark reviews before more spend; a written fallback to a painted 3D captain |
| Spend grows (about 620 frames, plus retries) | The pilot; age 0 first; stop at CA1 for Mark's go; three of eight facings mirrored; stations and chair in four facings only |
| Feet skate at speed | Distance-driven phase; contacts measured from the paint; AC3 |
| GPU memory (about 30 MB a stage) on a bench with little headroom (p99 15.5–16.3 ms of 16.7) | Trimmed 1.5× cells, one stage loaded, AC5's bound; the billboard stays one quad, so no extra draw calls |
| Elevation varies across the deck (27–31°) and the guides use one (29°) | At 161 px a ±2° difference is under a pixel of foreshortening on the legs; the capture shows the far and near deck |
| Conflicts with DL3 and the styling pass | CA0 starts after #292 merges; #293's files are not touched; re-read `git log HEAD..origin/main` before merging |
| The jog looks frantic at 3.5 m/s | 12 frames a second over a 2.33 m cycle; OQ2 |

## CA0 and the CA1 pilot, as built (2026-10-20)

**CA0** (`interior/captain_anim.gd`, `make captain-anim-test`, 58 checks): as §D2, with one change: the facing is kept as a **heading on the deck**, and the sector is that heading's direction on screen. A view switch at rest therefore turns the drawing, not the captain (bow-facing shows the back in Bow and the front in Astern). The demo's front/back rule (D3, `ship_geometry_demo.gd:436`) is gone; with today's stills a sideways walk shows the three-quarter `se` still (mirrored to the left) instead of the back.

**The pilot** (10 frames, `art/captain-anim-v1/`): the Codex art thread (`gpt-6.1-sol`, built-in image generator, `NOTES.md`) painted the jog half cycle and a standing frame in `back` and `profile`, from the picked identity, the stage-0 stills and the pose guides (`char_captain_pose_guides_v1.py`, elevation 29°, a light jog: the spike's run swung the thighs 40°). The identity, costume and style held across all 10. The pilot's frames live in `assets/characters/captain/anim_pilot.json`, **not** `manifest.json`, so the game is unchanged until Mark accepts them; `tools/captain_review.gd` loads them for the review.

Findings that change the plan:
1. **The generator's alpha.** The figure's alpha sits at 0.9–0.99 and a glow halo is painted into fully transparent pixels. Ingest remaps alpha 0.5–0.9 to 0–1 and zeroes the rest; the halo never shows.
2. **The pose gate (§D4) is amended.** A painted open coat never matches the guide's cone, so silhouette IoU ≥ 0.85 is unreachable: the 10 frames score 0.565–0.753. The gate is now **IoU ≥ 0.55 and leg coverage ≥ 0.65** (the share of the guide's red and blue leg keys the paint covers; the pilot scores 0.677–0.930). Scored against the other facing's guide, the same frames reach IoU 0.43–0.57 and leg coverage 0.27–0.76, and none passes both, so the gate separates the poses. The thresholds were set **after** seeing these numbers and the margins are thin (the lowest own IoU is 0.565).
3. **Scale.** The painter's framing drifts (ingest rescales by 0.945–1.07 to the guide's figure height); the check gates the shipped figure's height against the guide's (± 4%), not the drift.
4. **AC3 (planted feet) is not met yet, and the cause is the guide rig.** Its jog moves the lowest foot forward by up to 0.39 m between frames (`guides.json`), so the contacts it implies are not a stance. `cycle_m` stays the rig's nominal 2.333 m (0.29 m a frame, 83 ms a frame at 3.5 m/s). Before the rest of age 0 is painted, the guides need a planted-stance gait (the stance foot fixed on the deck while the body passes over it) and `cycle_m` measured from it.
5. **The half cycle.** The back view's second half is the first half mirrored; the profile's repeats the first half (near and far legs read alike at 67–81 px). Both look right at game size in the review; the age-0 set would paint all 8.
6. **Budgets:** 10 cells, 279 KB of WebP, 1.7 MB of GPU memory with mipmaps.

## Open questions for Mark (all answered: D-102, as recommended)

| # | Question | Recommendation |
|---|---|---|
| OQ1 | How is the captain animated? (a) painted frames posed by a rig; (b) a live 3D captain painted like the props; (c) procedural motion on today's stills only | **(a).** It keeps the painted look you chose over the Blender person, and the rig gives real strides. (c) alone glides; (b) risks the mannequin |
| OQ2 | Speed: keep 3.5 m/s (a jog everywhere), or walk 1.8 m/s with a hold-Shift jog? | **Keep 3.5 m/s as a light jog for now,** with start and stop eases. The camera, walk-to-station and tests are tuned to it; revisit a walk in the level-design pass, where distances are longer |
| OQ3 | Facings: 5 painted plus 3 mirrored (8 directions), or 4 (back, front, two profiles)? | **5 + 3 mirrored.** Diagonals are common on a round deck |
| OQ4 | Ages: animate all four stages before landing, or age 0 now and the rest later? | **All four before landing,** age 0 first. The captain ages on the ship's clock; a still old captain beside an animated young one would break the spell |
| OQ5 | Spend: about 620 painted frames (780 with a walk) plus retries, through the Codex art thread | **Approve the 10-frame pilot and, if it passes, age 0 (about 155 frames); decide stages 20–60 at the CA1 review** |
| OQ6 | Look-up on cues (arrivals, the starbow forming)? | **Yes,** skipped under reduced motion. It ties into the authored sky framings (D-96) later |
| OQ7 | Crew on deck animated too? | **No.** They stay portraits and static avatars (2026-09-28); revisit when crew walk the levels |
| OQ8 | Who checks the look? | **You,** at the CA1 pilot, the CA1 strips and dev build, and CA2 (play) |
| OQ9 | The chair: make it sittable (E at the seat, any move key stands)? | **Yes.** The captain's chair is the deck's focal point (bubble-ship layout); sitting in it while the starbow forms is the shot. About 60 LOC; no camera change |

## Deliverables

- This design doc, the sprint plan ([captain-animation-sprint.md](captain-animation-sprint.md)) and `.ailang/state/sprints/sprint_R2-CAPTAIN-ANIMATION.json` (awaiting approval).
- The spike: `tools/captain_anim_spike.gd`, its frames in `gs://stapledons-voyage-assets/refs/captain_animation/spike/`, the stand-in script `~/dev/blender/scripts/char_captain_anim_spike_v1.py`.
- A design-repo PR amending `art/characters-blender-brief.md` ("Motion") for the player's captain (D-98). It must merge before any CA1 spend.
- After approval: `interior/captain_anim.gd`, `mk/captain-anim.mk`, `art/captain-anim-v1/` (guide pins, prompts), the manifest v2, the frames, `make captain-anim-test`, `make captain-frames-check`, `make captain-anim-capture`, a changelog fragment, the evaluation and the landing.
