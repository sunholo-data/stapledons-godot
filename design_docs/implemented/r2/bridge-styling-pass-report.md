# R2-BRIDGE-STYLE: landing report

**Design:** [bridge-styling-pass.md](bridge-styling-pass.md) · **Sprint:** [bridge-styling-pass-sprint.md](bridge-styling-pass-sprint.md) ·
**Ledger:** D-100 (plan approved), D-104 (shape language), D-106 (painted foliage), D-110 (ST2 style frame approved, "continue").
**PRs:** #300 (ST0–ST2, merged), this branch `feat/bridge-style-2` (ST3–ST6).

The bridge and its HUD now read as one illustrated world: the spire lights the deck in deep space and hands
the light to a near star; every bridge surface is banded toon with an ink line; the props are grown, curved
forms; the deck and mast are painted; the rim fronds are painted cards; the whole HUD is on one theme.

## What was built, by stage

| Stage | Built |
|---|---|
| ST0 | `make style-test`, `make ui-theme-check`, `make style-capture`, red first, with their negative controls |
| ST1 | The broad key retired on the bridge; the spire keys it (base 8, 25 % floor, soft cube shadow handed to the star on the key's ramp, one shadow owner), the mast a non-caster for it, bridge ambient ×1.45, the lower decks unchanged. ST5 made its falloff flat inside the range window (`omni_attenuation` 0) so the dark ash rim reads |
| ST2 | `shaders/stapledon_toon.gdshader` (three bands, ink outline as the exact next_pass) on the `bridge_style` group; StapledonTheme on the status strip and the arrival card; D-104 grown desks, chair and screen housings (`stapledon_bridge_props_v3.py`) |
| ST3 | `stapledon_bridge_props_v4.py`: the deck top in four planar painted quadrants (an empty keeps its name) and its fill painted to match; the spire painted with a warm wash at its lamp; the authored lift head (`lift_head.glb`, grown pad, rails and gates); the rest of the bridge grown (Archive terminal and tomes, benches, guardrails, lift guides; the pods' bands softened). `ship.glb` exports WebP (5.6 → 2.3 MB) |
| ST4 | The theme everywhere: panels by kind (HUDPanel, HUDCard, HUDSheet, HUDDialog, HUDReview), text by meaning (HUDLabel … HUDWarn, HUDOverlay over the world), buttons (HUDButton, HUDSelected, HUDFlat, HUDMenu), slider and progress bars; `ui-theme-check` strict at **0** leftovers with one explicit allow-list (`ui/theme/allow.json`: the crew palette, D-80) |
| ST5 | `ShipDressing`: the ten rim fronds as painted cards (D-106) in the toon shader's card mode (no second shader), each with a crossed shadow-only proxy; below-rail canopy silhouettes on the Commons deck; per-view foreground cards with a bounded 0.6× parallax drift |
| ST6 | Quiet-rig bench, final captures, this report, the changelog, the independent evaluation, the design-repo roadmap row |

## Acceptance criteria

| # | Result |
|---|---|
| AC1 | `make ship-star-light-test` 77 passed (the three key checks in their old form on the lower decks; 19 bridge checks) |
| AC2 | `make ship-commons-test` 39, `make ship-lighting-test` OK |
| AC3 | `make style-test` 22 passed (toon + exact ink on every member, exclusions, sky untouched, lift and deck quadrants, the card default, both negative controls) |
| AC4 | `make golden`: run by `tools/rig_check.sh --golden` on the final head (see the PR) |
| AC5 | `make deck-assets-check` ok: `ship.glb` 42,048 tris, 15 materials, 11 images, 2.3 MB; `bridge_props.glb` 176,760 tris (cap 180,000); `lift_head.glb` 4,752 tris; images ≤ 24, VRAM cap +48 MB (measured with a GPU window in the rig run) |
| AC6/AC7 | `make ui-theme-check` (strict): 0 leftovers; fonts, OFL licences, ink border and frond card pinned; 57 text/panel pairs ≥ 4.5:1 over night and cream; both negative controls fail |
| AC8 | `make dressing-test` 10 passed: every plant stands on the deck clear of the lift, its guards, the rim rail and the landing (the real triangles; a plant seeded on the lift guard is caught); three kinds, no two neighbours alike; `make deck-layout-eval` bridge ok (fades 479 of 530) |
| AC9 | `make bench SCENE=bridge`, three runs at host load 3–5: p99 **16.0 ms** (best), 16.2 ms, and a cold first run at 30.1 ms; target < 16.7 ms met |
| AC10 | `make style-capture`: `before` (DL3), `st1`, `st2`, `sf`, `st3`, `st5`, `final` (with a before/after sheet against the approved ST2 style frame), every frame opened |
| AC11 | `make test` via `tools/rig_check.sh --golden` on the PR head |
| AC12 | D-104: every prop in `style.shaped` ≤ 0.10 straight-edge share (27 props plus the three lift pieces; floor markings ≤ 3 cm listed as decals) |

## Mark's review of #322 (2026-10-22)

"the bridge styling includes a plant with the wrong z-axis so its put over the lift railing. we also need some variations between the plants". The plant over the lift railing was a camera-attached foreground card: fixed to the camera, it read as standing on the lift's railing in the Bow view. The foreground layer is removed (the levels' view dressing places real props), and `dressing-test` now checks every plant's footprint against the lift's, the guards' and the rim rail's real triangles and the landing. The ten rim plants now vary: three painted kinds (frond, shrub, grown planter) with a seeded height, mirror and tint each; the final per-kind set comes with the R2-LEVELS foliage library (D-106).

## Deviations and things to know

- **The black band past the bridge disc** (ST2 report) was the bridge's own dark ash rim, not the lower deck: with
  the broad key retired, the spire's distance falloff left it unlit. ST5 flattened the spire's falloff inside its
  range window; the rim now reads dark brown.
- **Rim plants are 1.0–1.9 m** (the palms at most 1.9 m, not the spike's 3.2 m): the bow evaluator's fade budget (530)
  allows no more; the mixed set measures 479.
- **The below-rail canopies** sit on the Commons deck under the rim; from Bow and Astern they mostly stay below the
  rail line. They are cheap scale cues; the levels pass will replace them with the real Commons dressing.
- **No camera-attached foreground** (removed after Mark's review): the plan's S5 foreground layer becomes the levels' per-view dressing.
- **Test changes the plan did not list:** `bh-hud-test`'s Sgr A* key check (the spire is the bridge's key);
  `camera-test`'s landing sightline now uses the lift's triangles (one mesh per rail made the AABB close the gap
  between the bars); the Archive's tomes joined the fade list (`archive_detail`), which moves the deck evaluator's
  positive control from 4 to 3 Astern head blocks; the DL2/DL3 deck checks drop the fronds; `bridge-floor-test`
  reads the painted deck's colour family by chroma.
- **The project theme** is installed on the window at run time and set on each panel root (the bundled fonts load
  raw); no `.tres` ships.

## Independent evaluation

Claude Sonnet, independent (`.ailang/state/evaluations/eval_R2-BRIDGE-STYLE_round_1.json`): **82/100, pass**, no blocking findings; three of four mutation drills caught. Followed up: `style-test` now pins the 28 grown props by name (the fourth drill, a name dropped from `style.shaped`, now fails) and the card's ±25° default; the `ship.glb` figures above corrected.

## Follow-ups

- The Commons' own styling pass (it keeps the broad key and its look, OQ7).
- Real lower-deck dressing for the below-rail view when R2-LEVELS dresses the Commons.
- More painted foliage kinds through the art pipeline (`assets/foliage/`).
