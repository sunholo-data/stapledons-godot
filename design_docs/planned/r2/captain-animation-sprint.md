# Sprint R2-CAPTAIN-ANIMATION: painted frames, posed by a rig

**Design doc:** [captain-animation.md](captain-animation.md)
**Sprint JSON:** `.ailang/state/sprints/sprint_R2-CAPTAIN-ANIMATION.json`
**Status:** **Awaiting Mark's approval** (plan only; nothing built beyond the spike).
**Base:** `origin/main` 8e49c160 (branch `design/captain-animation`). CA0 starts after #292 (DL3) merges; it does not touch #293's files.
**AILANG:** v0.54.14 (pinned). No `.ail` code (syntax gate: skip). Registry reuse: none; no maths for `sunholo/relativity`.
**Estimate:** about 1,400 game LOC, **9–10 working days** of execution, excluding Mark's three reviews and the art turnaround (the painted frames are made by the Codex art thread, and only after Mark approves the spend).

## What the survey found

- **The captain is a painted `Sprite3D` billboard** (`interior/captain_avatar.gd`, `CaptainAvatar`): 4 stages (0, 20, 40, 60 years on the ship's clock) × 4 facings (`front`, `back`, `se`, `ne`, drawn for the retired −14° iso view), 1024 × 1536 canvas, foot anchor (512, 1440), 720 px/m, mirror-safe. 34 MB of PNGs in `assets/characters/captain/`.
- **Facing is front/back only** (`set_motion`, `demos/ship_geometry_demo.gd:374`); sideways walks keep the last facing (the moonwalk). A standing captain is turned to the back each frame (`:436`).
- **Speed is 3.5 m/s** (`WALK_SPEED_MPS` in `ship_geometry_demo.gd` and `ship_consoles.gd`): a jog.
- **The chair is a prop:** nothing lets the captain sit; sitting is a new interaction (OQ9).
- **The figure is 161 px** at 2560 × 1440 in the Bow view (81 px at 1280 × 720), `CameraDirector.figure_px`.
- **The spike** (`tools/captain_anim_spike.gd`; frames in `gs://stapledons-voyage-assets/refs/captain_animation/spike/`) compared today's still, a live rigged GLB with the ink outline, pre-rendered rig frames, and procedural motion on the still. The rig gives readable strides in every direction; the untextured stand-in looks like a mannequin, which is the risk Mark ruled on in 2026-09-28; procedural motion alone glides. The recommended hybrid itself was **not** spiked (hence the CA1 pilot). Frame time was inconclusive: every run sat at the 120 Hz vsync.
- **The bench is tight:** `make ship-demo-bench` p99 15.5–16.3 ms against 16.7 ms (DL0's numbers). The atlas adds memory, not draw calls.
- **The art pipeline exists:** Codex "Sol 6.1" agents with the built-in image generator made today's avatars as identity-preserving edits (`assets/characters/captain/generation_notes.md`).

## Milestones

### CA0: the animation state with today's stills (~800 LOC, 4 days)
- **Red first:** `tests/test_captain_anim.gd` (`make captain-anim-test`, a `test:` prerequisite via `mk/captain-anim.mk`): 8-sector facing in Bow and Astern with 10° hysteresis; a starboard walk shows the mirrored `se`/`ne` stand-in with the right flip, never the back (AC2, CA0 half); distance-driven phase (no distance, no advance); start, stop, station, chair (stand before leaving), lift and look-up transitions; reduced motion drops bob, lean and look-ups; determinism (one input script, two runs, identical outputs).
- **Build:** `interior/captain_anim.gd` (`CaptainAnim`, pure); `CaptainAvatar` reads manifest v2 `clips` (v1 stills still load) and shows a frame with trim offset and `flip_h`; `ship_geometry_demo.gd` feeds velocity, view yaw, station, chair, lift and cues, and drops the front/back-only facing and the per-frame turn to the back (`:436`); `ship_consoles.gd` exposes station states; the `foot_down` and transition signals (the sound hook, §D5).
- **Tools:** `tools/captain_anim_capture.gd` (`make captain-anim-capture`, from the spike): strips and a contact sheet in Bow and Astern at 2560 × 1440; its machine half fails on a missing, blank or frozen strip.
- **Validation:** `make captain-anim-test camera-test camera-forward-test deck-layout-eval test`; `make golden ship-demo-bench` on the rig; the sheet opened. Ships on its own: no more moonwalk, even with stills.

### CA1: pose guides, the pilot, age-0 moving clips (~350 LOC + bpy, 2.5 days of build, plus the art turnaround) ⏸ Mark: the pilot, then the look
- **Before any spend:** the design-repo amendment of `art/characters-blender-brief.md` ("Motion", D-98) is merged, and Mark has approved OQ5.
- **Pose guides:** `~/dev/blender/scripts/char_captain_pose_guides_v1.py` (from the spike rig, guide elevation 29°): silhouettes with limb keys on the avatar canvas contract, in 5 facings, for idle, jog (and walk if OQ2), start, stop, lift, look-up. Pins, prompts and the identity inputs in `art/captain-anim-v1/`; files by sha256 in `gs://stapledons-voyage-assets/captain/`.
- **Red first:** `tools/captain_frames_check.gd` (`make captain-frames-check`) with fixtures: a guide-matching frame passes; a frame of another identity (palette ΔE), a misplaced foot (anchor, 3 cell px) and a wrong pose (IoU 0.85) fail; the disk (≤ 3 MB a stage) and GPU-memory (≤ 32 MB for the loaded stage) budgets.
- **Pilot:** 10 frames (one jog cycle's key poses, `back` and `profile`) through the Codex art thread; `captain-frames-check`; strips to `refs/captain_animation/pilot/`. ⏸ Mark glances; a fail twice triggers the fallback re-plan (design §D1).
- **Then age 0:** 95 moving-clip frames (19 in each of 5 facings). Contacts and `stride_m` measured from each frame's alpha; 192 × 288 trimmed WebP cells; manifest v2 `clips`; `captain-frames-check` joins `make test`.
- **Validation:** all CA0 gates; `make captain-frames-check`; `make golden` (re-posed captain cases listed); `make ship-demo-bench` p99 ≤ 16.7 ms with the memory read-back; `make export-filter-audit`; `make publish-dev` (export smoke); strips to `refs/captain_animation/ca1/` with per-file URLs. ⏸ Mark reviews the look before more spend.

### CA2: stations, chair, sound hook (~200 LOC, 1.5 days + art) ⏸ Mark plays
- Pose guides and age-0 frames for `use_low/mid/high`, sit, seated, stand in 4 facings (60 frames); the chair interaction (E at the seat point, sit, seated, any move key stands; OQ9); the station and chair timings; the director's arrival and starbow cues raise `look_up`.
- **Validation:** CA1's list plus scripted station and chair sequences in `captain-anim-test`; dev build; strips to `refs/captain_animation/ca2/`.

### CA3: the other three stages, evaluation, landing (~50 LOC, 1 day + art)
- Stages 20, 40, 60 as identity-preserving edits of the age-0 frames (as the stills were made), each through `captain-frames-check`, each with its own measured stride; budgets; the next stage preloads a year of ship time before it is due.
- Independent evaluation (a different model, `sprint-evaluator`), changelog fragment, the design doc to `design_docs/implemented/r2/`, the design-repo roadmap.

## Pause points

1. **Plan approval:** OQ1–OQ9 answered (one ledger row). OQ1 and OQ5 decide whether CA1 happens as written.
2. **CA1 pilot:** 10 frames, before the rest of age 0 is painted.
3. **After CA1:** Mark reviews the age-0 moving clips (strips and a dev build) before more spend.
4. **After CA2:** Mark plays the stations and the chair.

## Risks

| Risk | Mitigation |
|---|---|
| Painted frames drift off-identity | Identity sheet and pose guide as inputs; the 10-frame pilot; `captain-frames-check`; Mark at the pilot and at CA1; fallback re-plan to a painted 3D captain after two failed rounds |
| Spend (about 620 frames plus retries) | The pilot; age 0 first; three facings mirrored; stations and chair in four facings |
| GPU memory and bench headroom (p99 15.5–16.3 ms of 16.7) | Trimmed 1.5× cells, about 30 MB a stage, one stage loaded, the ≤ 32 MB bound; one quad, no extra draw calls; bench at every milestone |
| File conflicts with DL3 and the styling pass | Start after #292 merges; stay out of #293's files; re-read `git log HEAD..origin/main` before merging |
| A frantic jog | 12 frames a second over a 2.33 m cycle; OQ2 |

## Validation (every milestone)

`PATH=$PWD/runtime/bin:$PATH make test` (green locally and `tools/rig_check.sh` on the PR head), plus the milestone's own list. GPU captures are opened by a person. Godot runs under `perl -e 'alarm N; exec @ARGV'`.
