# Sprint R2-BRIDGE-STYLE: the styling and graphic pass for the bridge and the HUD

**Design doc:** [bridge-styling-pass.md](bridge-styling-pass.md)
**Sprint JSON:** `.ailang/state/sprints/sprint_R2-BRIDGE-STYLE.json`
**Status:** **Approved** (Mark, 2026-10-20, ledger D-100). Executing; hard stop at the ST2 style frame.
**Base:** main after R2-DECK-LAYOUT DL3 (#292, merged).
**AILANG:** v0.54.14, pinned. No `.ail` code: syntax gate skipped. Registry reuse: none (Godot shaders, themes and Blender assets; no physics maths).
**Estimate:** about 1,440 game LOC plus about 800 lines of `bpy`, over **10.5 working days** (D-104 shape language +1.5 days, D-106 foliage cards +0.5 day; was 8.5), excluding Mark's review at the pause. Engine and UI code (ST0, ST1, ST2, ST4: about 1,000 LOC) runs at the recent attended rate of about 300 LOC a day. The art milestones (ST3: 2 days; ST5: 1.5 days) are capped at their days, and Blender work is not counted in LOC. The blended rate is about 150 LOC a day.

## Velocity

R2-DECK-LAYOUT ran DL0–DL3 in one long day each on this rig. That came to about 2,600 game LOC with Blender iteration and GPU captures dominating, against a planned 115 game LOC a day. The plan here keeps the old rate's caution for the art work:

- **ST3 and ST5:** the Blender and dressing milestones are capped at their days.
- **ST1, ST2, ST4:** engine and UI code run at the recent attended rate, about 300 LOC a day.

## What the survey found

- **Lighting:**
  - `SpireLight` (DL2, `demos/ship_lighting.gd`) already shares the broad key's dimming rule in `ship_star_light.apply_rig`.
  - The broad key is one global `DirectionalLight3D` for every level.
  - The mocks show that retiring it on the bridge needs the mast to be a non-caster for the spire's shadow.
- **Shading:**
  - Every surface is Godot PBR (`StandardMaterial3D` from the GLB importer).
  - The inverted-hull ink outline (`interior/outline.gdshader`) is on the DL2/DL3 props only.
  - The mock's three-band toon shader (`tools/style_mock_capture.gd`) keeps each material's albedo and works on both GLBs.
- **Big surfaces:**
  - `bridge_floor_top82` (a tiled 4 m pigment) and `spire_needle` (one canon mesh) are in `ship.glb`.
  - The lift box is runtime geometry in `demos/ship_demo_lift.gd`.
- **HUD:**
  - 13 files build their own `StyleBoxFlat`, and there are 49 `add_theme_color_override` calls across `ui/` and `demos/`.
  - There is no project theme or bundled typeface.
  - The crew palette (`ui/crew_palette.gd`) carries identity colours that must stay distinct (D-80).
- **Dressing:**
  - `views.json` v2 already has per-level data (`levels.bridge.occluders`); a `dressing` list fits beside it.
  - The bow evaluator (`DeckBowMetrics`) measures near-field shares and every sightline the dressing must respect.

## Milestones

### ST0: the checks first (~300 LOC, 1 day)
- **`tools/style_capture.gd` and `make style-capture TAG=<tag>`:**
  - frames: Bow (deep space, near the Sun, 0.99c, the first stop), Astern, and the three console zooms;
  - each with the HUD on and off, plus a before/after sheet against a pinned "before" run.
- **`tests/test_style.gd` and `make style-test`** (red first):
  - every bridge mesh uses the toon material with the ink next pass;
  - no sky, glow, planet or lens material does;
  - negative control: a seeded PBR material on a bridge mesh fails.
- **`tools/ui_theme_check.gd` and `make ui-theme-check`** (red first):
  - no `StyleBoxFlat.new()` and no `add_theme_color_override` in `ui/` outside the theme builder, with an allow-list for the crew palette;
  - WCAG 4.5:1 text contrast for every theme type;
  - negative controls: a seeded override, and a low-contrast colour pair.
- **Gate:** the three run red as expected, then join `make test`. `ui-theme-check` starts as a report and becomes a failure at ST4.

### ST1: the spire keys the bridge (~200 LOC, 1 day)
- **Red first:** new `ship-star-light-test` checks:
  - on the bridge the broad key is 0;
  - the spire is at `spire_base` with no star close and holds the only shadow;
  - near a star exactly one of spire and star holds a shadow;
  - the mast does not cast the spire's shadow.
- **Lower levels:** the broad key stays on below the bridge. `ship-commons-test` and `ship-lighting-test` keep it.
- **Build:**
  - `apply_rig` gets a `bridge` flag from the active level;
  - the shadow handover covers the spire and the star;
  - the spire's shadow uses a cube map with blur;
  - one rebalance pass, captured at deep space, the Earth stop and Jupiter.
- **Gate:**
  - `make ship-star-light-test ship-commons-test ship-lighting-test`;
  - `make golden` (393 / baseline 364);
  - `make bench SCENE=bridge`, with the fallbacks in order if p99 misses.

### ST2: toon shading and the theme's first panels; the style frame (~250 LOC, 1 day) ⏸ Mark approves the look
- `shaders/stapledon_toon.gdshader` (from the mock), applied at load to every bridge-level mesh in both GLBs, with the ink next pass. The band thresholds are uniforms.
- `ui/stapledon_theme.tres`, built by `ui/stapledon_theme.gd`: palette tokens, the OQ3 typefaces (SIL OFL, bundled), and the OQ4 panel shape. It is applied to the status strip and the arrival card only.
- `make style-capture TAG=sf`; every frame opened and published to `refs/bridge_style/sf/`.
- **Gate:**
  - `make style-test`, `make golden`, `make bench SCENE=bridge`;
  - `make deck-layout-eval`, unchanged numbers;
  - display-audit and its controls.
- **D-104 shape language (S7):** the desks, the captain's chair and every screen housing rebuilt as grown forms by `~/dev/blender/scripts/stapledon_bridge_props_v3.py` (`reshape()`, then v2's bakes); the straight-edge share ≤ 0.10 on `style.shaped` (AC12); `make deck-layout-eval` still bridge ok.
- **Pause:** Mark approves the style frame (look, bands, typeface, panel, and the shapes) or redirects.

### ST3: the deck, the spire and the lift head (~100 LOC + bpy, 2 days)
- **`~/dev/blender/scripts/stapledon_bridge_props_v3.py`:**
  - the deck top in four quadrant meshes, 1024² WebP atlases each (about 2.5 cm per texel), on the DL2 recipe;
  - the spire body, with the lamp band's warm pigment;
  - an authored lift cage, gates and platform;
  - the manifest's `style.bridge_nodes` list.
- **Lift:** `demos/ship_demo_lift.gd` loads the authored lift; its behaviour and `ship-demo-lift-test` are unchanged.
- **S7 (D-104):** the rail segments and lamps, the bridge guardrails and the lift guides grown (`reshape()`), added to `style.shaped`.
- **Gate:**
  - `make deck-assets-check` (new budgets: images ≤ 24, VRAM ≤ baseline + 48 MB);
  - `make bridge-floor-test ship-demo-lift-test ship-commons-test deck-layout-eval`;
  - `make golden`; `make style-capture TAG=st3`, opened and published.

### ST4: the theme everywhere (~250 LOC, 1.5 days; can ship as its own PR if ST3 or ST5 slips)
- **Assets first:** the OQ3 fonts, with their OFL licences and pins, go into `assets/fonts/`. `tools/theme_assets.gd` draws the ink 9-slice border from a seeded jitter.
- **Replace every panel style and colour override** in `ui/` and the demo's HUD with theme types. The panels covered are cards, console panels, the galaxy map's side panel, the Archive, the crew console, Tab help, the title screen and the crossing review.
- **Physics overlays** keep their functional colours (OQ5).
- **Gate:**
  - `make ui-theme-check` now fails on any leftover;
  - display-audit (all four) and `ship-ui-test`, `crew-console-test`, `title-screen-test`;
  - `make style-capture TAG=st4` with the HUD on.

### ST5: dressing per view (~200 LOC + bpy, 1.5 days)
- **`bridge_dressing.glb`:**
  - Bow: frond tips and rail stanchions at the lower corners;
  - Astern: the mast root and a cable run;
  - below the rail: silhouettes of the next deck's rim and the canopy, 25–50 m down, outside every lower-deck volume.
- **Placement:** each piece is placed from `views.json` `levels.bridge.dressing` and shown only in its view.
- **S7 (D-104):** the watch benches and details, the Archive terminal and detail, and the conduits grown, added to `style.shaped`.
- **D-106 painted foliage:** the ten rim fronds become painted frond cards (spike PR #299): the spike's card shader merged into `shaders/stapledon_toon.gdshader` as a card mode (alpha cut, sphere normal, the same three bands), cards clamped to ±25° toward the camera, evenly lit paintings, shadow-only proxy casters for the large fronds, the occluder fade kept. `make style-test` audits the cards; `make deck-layout-eval` keeps every threshold.
- **Evaluator:** gets a `dressing` row (≤ 8 % of each view), with a seeded oversized-prop negative control. Every §D4 threshold is kept.
- **Gate:** `make deck-layout-eval deck-layout-eval-test camera-test camera-forward-test`; `make style-capture TAG=st5`, opened and published.

### ST6: landing (docs, 0.5 day)
- `make test` on the rig (`tools/rig_check.sh`), `make golden`, `make bench SCENE=bridge` (AC9's rule), `make style-capture TAG=final`; a dev build.
- `design_docs/implemented/r2/bridge-styling-pass-report.md`; a changelog fragment.
- An independent `sprint-evaluator` run by Sonnet (the executor is Opus), scoring ≥ 70.

## Pause points

| After | Mark sees | Mark decides |
|---|---|---|
| Plan approval | The design doc, this plan, the mock sheet (`refs/bridge_style/mock/`) | OQ1–OQ7 (one ledger row) |
| ST2 | The style frame: Bow and Astern with the HUD, deep space and near the Sun; the bench | The look: bands, typeface, panel shape |

## Risks

See the design doc's table. Sprint-specific:

- **Shared rig:** the bench and captures share the rig with the mission loop. Wait for an idle rig, and log host load. A DL3 bench under load around 16 missed at 23 ms; under load around 12 it measured 15.6 ms.
- **Theme spillover:** the consistency pass touches many UI files. ST4 runs every UI test and display-audit before its commit.
- **ST3 is the art-heavy milestone.** It is capped at 1.5 days; anything past the cap returns to Mark.

## Validation

- **Every milestone:** its focused gates, run with the pinned runtime.
- **Before the PR:** the full `make test` on the rig, plus `rig_check`.
- **Captures:** every one is opened before a pause.
