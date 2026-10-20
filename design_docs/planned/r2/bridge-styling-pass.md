# R2-BRIDGE-STYLE: the styling and graphic pass for the bridge and the HUD

**Status:** Approved by Mark 2026-10-20 (ledger D-100, every recommendation); executing on `feat/bridge-style`. An independent Sonnet plan review scored it 74/100 (pass) with eight blocking items, all folded in (sprint JSON `reviews`).
**Release:** R2. **Milestone:** the bridge and its HUD read as one illustrated world in the art bible's style, lit by its own spire in deep space and by the real star near one.
**Priority:** P1 for R2. Every session opens on this deck, and the HUD is on screen the whole game.

**Mark's direction** (verbatim):
> 2026-10-20 (D-96, on the DL1 blockout): "we can set up some very cool eclipse/transition positions with this control of viewpoint. we should also keep in mind that light sources will play in for atmosphere, with the spire providing its own light when nothing close by is available"
> 2026-10-20 (D-97, on the DL2 style frame): "yes we need more styling and graphic pass overall but in general happy"

**Implements** (design repo):
- [art/README.md](https://github.com/sunholo-data/stapledons-design/blob/main/art/README.md) "Style": French 70s comics (Moebius, Druillet, *Métal Hurlant*): grown technology, saturated colour against emptiness, tiny humans in vast structures, flowing curves, cathedral spaces. "Who renders what": the engine applies **toon shading and ink outlines** to play-area GLBs; never paint space.
- [art/ship-interior-blender-brief.md](https://github.com/sunholo-data/stapledons-design/blob/main/art/ship-interior-blender-brief.md) §2 (the five layers: sky, panorama ×0.15, play area, foreground silhouettes ×1.6), §3 (the spire "calm, faintly luminous"; the bridge as the decision hub), §4 (banded toon shading, ink lines, a restricted palette per level), §5 (the physics contract), §6 (as updated for the fixed views by stapledons-design #31).
- [vision/core-pillars.md](https://github.com/sunholo-data/stapledons-design/blob/main/vision/core-pillars.md); [vision/design-decisions.md](https://github.com/sunholo-data/stapledons-design/blob/main/vision/design-decisions.md) 2026-10-03 "Bridge v2" (the spire as the ship-fixed key light; the sprites' illustrated finish).
- This repo: [deck-layout.md](deck-layout.md) §D5, §D5a (D-96 amendment: the SpireLight, live; the broad key's retirement scoped as this follow-up), its "Future: authored sky framings" note; ledger D-91 to D-97.

**Depends on:** R2-DECK-LAYOUT DL3 (every bridge hero dressed, `bridge_props.glb`), merged first. **No physics change:** the sky, the glow, lensing and the star light's direction, colour and brightness rules stay as they are (`sunholo/relativity` untouched; the GPU goldens keep their 393 cases).

**Estimated LOC:** about 1,300 game LOC (checks 300, lighting 200, toon material and first theme 250, big surfaces 100, theme everywhere 250, dressing 200) plus about 500 lines of `bpy` (deck and spire paint, lift, dressing) in `~/dev/blender`.

## Game vision alignment

Scored with the `game-vision-designer` skill (feature-validation mode, against `vision/core-pillars.md` and the art bible), 2026-10-20. **ALIGNED.**

| Pillar | Score | Rationale |
|---|---|---|
| Choices Are Final | 0 | Neutral: no decision or consequence changes |
| The Game Doesn't Judge | 0 | Neutral. The HUD keeps showing facts, not verdicts |
| Time Has Emotional Weight | +1 | The spire's warm light in the long dark between stars, and the star taking over on arrival, make the voyage's rhythm visible on the deck; the HUD's clocks read as part of that world |
| The Ship Is Home | +2 | The bridge becomes one illustrated place lit by its own heart (the spire), and the HUD stops looking like a debugging overlay |
| Grounded Strangeness | +1 | The art bible's look (grown technology, saturated colour against emptiness) on a ship whose sky is physically exact. Risk: stylised shading must not leak into the sky; guarded by the goldens and the "never paint space" rule (§S6) |
| We Are Not Built For This | +1 | Foreground layers and a darker deck make the captain small against the void |
| **Net** | **+5** | **Go.** No pillar is negative |

## Problem

After DL1–DL3 the bridge's furniture faces the bow and is painted with inked edges. Measured and seen in the DL3 frames (`refs/deck_layout_bow/dl3/`) and the mocks below:

1. **Two lighting languages.** The abstract ship-fixed "InternalBroadKey" still lights the whole deck evenly in deep space, so the spire's light (D-96) barely reads. With the key at 1.5 and the spire at 5 (attenuation 0.4), the spire adds a warm lift to the faces toward the mast, and nothing more ([mock, row "now"](https://storage.googleapis.com/stapledons-voyage-assets/refs/bridge_style/mock/contact_sheet.png)).
2. **PBR shading, not the art bible's.** Every surface uses Godot's physically based shading (smooth gradients and specular highlights). The bible asks for banded toon shading with ink lines. Only the DL2/DL3 props carry the ink outline; the deck, the spire and the rails' supports do not.
3. **Unfinished big surfaces.** The deck surface (a tiled 4 m pigment) and the spire body were left in `ship.glb` by DL3. They are most of the frame in every view. The runtime lift box (`demos/ship_demo_lift.gd`) is still a white blockout.
4. **The HUD is a separate visual language.** Twelve files build their own `StyleBoxFlat` (dark navy panels, thin blue-grey borders, 5 px corners), and 49 colour overrides are scattered through `ui/` and `demos/`. There is no project theme, no typeface choice, and nothing ties the HUD to the comic look or the crew portraits.
5. **No per-view dressing.** The fixed views (Bow, Astern, the console close-ups) frame the bridge from known poses, but nothing is placed for them. There is no foreground layer, and no silhouette of the ship below the rail to show scale.

## Goals and non-goals

**Goals**
- G1. **One light language on the bridge.** The spire keys the bridge in deep space, with a shadow. The star takes over near a star, as R1-SHIP-STAR-LIGHT already computes. The abstract broad key is retired on the bridge.
- G2. **The art bible's shading.** Banded toon shading plus ink outlines on every bridge surface, palette-true, from one shared material. The sky stays untouched.
- G3. **Finish the big surfaces.** The deck, the spire body (to deck height and the visible mast) and the lift head are painted on the DL2 recipe.
- G4. **A HUD in the same world.** One Godot `Theme` holds the palette, typeface, panel and border shapes (ink lines, the cream, ochre and violet of the captain sheet). Every HUD panel uses it; no hard-coded colours remain in `ui/`.
- G5. **Dressing per view.** Foreground silhouettes and below-rail scale cues placed for the Bow and Astern views, with real parallax from their distance.
- G6. **Measured, not guessed.** Before/after captures through the real views, a tonemap and sky guard, the bench, and Mark's approval at a style-frame pause.

**Non-goals**
- Authored sky framings (eclipses, transits, the starbow forming, arrivals). They get their own design doc, per D-96.
- Character art. The captain and crew sprites and portraits are unchanged; the HUD frames them.
- The Commons and the lower levels. Their own passes follow the bridge.
- New HUD features or layout changes. This is a re-skin plus a consistency pass, not new information.

## Design

### S1. Lighting: the spire is the bridge's key

- **Retire the broad key on the bridge.**
  - **How the level switch works:** `apply_rig` takes the active level (`demo.active_level`, 0 = the bridge). On the bridge the key's energy is 0 and the share rule drives the spire. On every other level the key behaves exactly as today. The lower decks and the below-rail cues, seen from the bridge, are then lit only by ambient, fill and the spire's reach. They read as silhouettes, which is intended (S5).
  - **Existing checks that change, and only these:**
    - "at Earth the broad key sits at its 25 % floor" becomes "on the bridge the key is 0 and the spire sits at its floor";
    - "interstellar cruise: the moody broad key is fully restored" becomes "the spire is at `spire_base`";
    - "exactly one shadow-casting directional light" becomes "exactly one shadow owner among spire and star".
    - The same checks keep their old form on the Commons level, and every other check is unchanged.
  - The `InternalBroadKey` directional light is set to energy 0 while the captain is on the bridge level. The lower decks keep it until their own passes.
  - The share rule moves to the spire. `SpireLight` energy is `spire_base × max(KEY_FLOOR_SHARE, 1 − level)`, exactly the key's former rule, so near a star the spire falls to its floor.
- **The spire casts the shadow.**
  - The light sits on the mast's axis, so the mast body is a non-caster for it. The mocks found that otherwise the mast hides the whole deck from its own light.
  - `SpireLight` gets an omni shadow (cube map, `shadow_blur` for the soft comic look) while it owns the light, that is while the star's level is below `SHADOW_HANDOVER`.
  - Its `shadow_opacity` follows the key's existing ramp, `clamp(1 − level / SHADOW_HANDOVER)`. The swap with the star's shadow then happens where both opacities are zero, so there is no pop. Tests at levels 0, `HANDOVER − ε`, `HANDOVER`, `2 × HANDOVER` and 1.
  - The existing one-shadow-owner rule extends to it: exactly one of spire and star holds a shadow map at any time. This is tested like today's key/star handover.
- **Rebalance.**
  - `spire_base`, `omni_attenuation`, ambient and fill are tuned once against two captures: deep space and near the Sun.
  - The ambient stays the readability floor (the deck must be readable with the spire at its floor and the star below the deck).
- **The lamp reads as a source.** The mast's lamp band brightens with the spire, and the spire body's paint carries a warm band around it.
- **Physics guard.** The star light's direction, colour and log-compressed brightness are unchanged. `make ship-star-light-test` keeps every check; new checks cover the spire's shadow ownership and the retired key.

### S2. Shading: banded toon and ink on every bridge surface

- **One shared material**, `shaders/stapledon_toon.gdshader`:
  - **Shading:** it keeps the albedo (texture × colour) and the normal map when there is one. Diffuse light falls into three bands: thresholds and band values are uniforms, defaults 0.55/0.12 → 1.0/0.55/0.18, with a 2 % smoothstep at each edge against aliasing. There is no specular.
  - **Ink:** the ink outline (`interior/outline.gdshader`) is its `next_pass`, exactly that material.
  - **Shadows:** `cast_shadow` is passed through unchanged.
  - **Exclusions:** emissive materials (the lamp band, glow strips), transparent materials (glass), the game's screen quads (`IdleScreen_*`) and every sprite or billboard (the captain, crew) keep their own materials.
- **What counts as a bridge mesh.** Membership is the node group `bridge_style`, never a position test.
  - The group is assigned at load to every mesh of `bridge_props.glb`, and to the `ship.glb` nodes listed in the manifest's `style.bridge_nodes`.
  - The v3 generator writes `style.bridge_nodes` from the master's bridge collection: the deck top, the spire body, the guardrails and the lift head.
  - `make style-test` checks the group and that every listed node exists, so a rename cannot make it pass vacuously.
- **Hook for authored framings.** The band thresholds, `spire_base` and the ambient are uniforms or rig fields that a future authored framing (D-96) can override per shot. Nothing in S1/S2 needs rework for that design.
  - Every mesh on the bridge level gets it at load, both `ship.glb`'s bridge meshes and `bridge_props.glb`.
  - The mocks below use exactly this (`tools/style_mock_capture.gd`).
- **Which lights band.** Every light that reaches the deck bands: the star, the spire, the fill. Ambient stays flat.
- **Never paint space.**
  - The material is applied to the `bridge_style` group only. The sky, glow, planets and lens layers render in their own viewport (`InteriorSky`), separate from the ship's `geometry_view` SubViewport, so they are structurally out of reach.
  - `make golden` keeps its 393 cases and its 364 baseline lines.
  - `make style-test` names the sky layers' nodes (`InteriorSky`, `SystemView`, `ForwardGlow`, the starfield), asserts that they exist, and checks that none uses the toon shader.

### S3. The big surfaces

- **Deck.**
  - `~/dev/blender/scripts/stapledon_bridge_props_v3.py` paints the deck top (`bridge_floor_top82`) on the DL2 recipe: pigment × contact AO × crease ink × grain.
  - The disc is split into four quadrant meshes so each atlas holds about 1 cm per texel at 2048². It stays in `ship.glb` with stable node names.
  - The walk files do not change.
- **The spire body.** The mast from the deck to its needle is painted on the same recipe, with the lamp band's warm pigment. It stays one canon mesh.
- **The lift head.** The runtime lift box (`demos/ship_demo_lift.gd`) moves to an authored GLB piece. The cage, gates and platform are painted, and the gates keep their behaviour and tests.
- **Budgets.**
  - **Cost of the textures:** GLB textures are loaded at run time (`AreaBundle.load_glb`), so they sit in VRAM uncompressed, as RGBA8 with mips. That is about 5.6 MB per 1024² texture and 22 MB per 2048².
  - **So the deck quadrants and the spire are 1024² each** (about 2.5 cm per texel on the deck): 5 × 5.6 ≈ 28 MB. DL3's atlases already measure in the current baseline.
  - **The budgets:** `deck-assets-check` grows to images ≤ 24 and VRAM ≤ baseline + 48 MB, measured with a GPU window. `ship.glb` stays under 10 MB, with WebP throughout.
  - **If the measured VRAM misses:** compress the textures at load (`Image.compress`, ASTC on Apple, BPTC elsewhere), or halve the bow-half quadrants' partners.

### S4. The HUD and graphic language

- **One theme**, `ui/stapledon_theme.tres`, set as the project's GUI theme. It defines:
  - **Palette tokens:** cream `#EFE3C8`, ochre `#C98E3A`, violet `#5B4A78`, teal `#3F7F86`, ink `#211A33`, and night `#0B0D16` for panel ground. These come from the captain sheet and DL2's pigments. All text meets WCAG 4.5:1 on its panel.
  - **Typeface:** one humanist face for text and one display face for headings, both SIL OFL licensed and bundled. OQ3 offers two pairs.
  - **Panel shape:** ink border 2 px, slightly irregular corners from a 9-slice texture (not a perfect radius), and a warm inner rule.
  - **Cards and buttons:** follow the same shapes. The focus ring stays at least as visible as today's.
- **Theme assets (authored, pinned, licensed).**
  - **Typefaces:** the two OQ3 faces come from Google Fonts under the SIL OFL. They go into `assets/fonts/` with their `OFL.txt` files and sha256 pins.
  - **Panel border:** the 9-slice ink border is drawn by a Godot tool, `tools/theme_assets.gd`, from a seeded jitter so it is reproducible. It is committed as `ui/theme/ink_panel.png` with its pin.
  - **Checks:** `make ui-theme-check` verifies the fonts, licences and pins are present.
- **Consistency pass.**
  - The 13 `StyleBoxFlat` builders and 49 colour overrides in `ui/` and `demos/` are replaced by theme types (`HUDPanel`, `HUDCard`, `HUDLabelDim`, …).
  - `make ui-theme-check` fails on any `StyleBoxFlat.new()` or `add_theme_color_override` left in `ui/` or in the demo's HUD code outside the theme builder. The HUD code means `demos/ship_geometry_demo.gd`'s `_hud` and the display panel, plus the HUD builders in `demos/`. Both allow-lists are explicit: the crew palette (crew identity colours, D-80) and the physics overlays (OQ5).
  - S4 can ship as its own PR if the Blender work in S3 or S5 slips.
- **What it frames.** The status strip, cards, console panels, the galaxy map's side panel, the Archive and the crew console all take the theme. The physics overlays (the forward pole marker, star labels) keep their functional colours (OQ5).

### S5. Dressing per view, with parallax

- **Foreground silhouettes**, the art bible's layer 5, as real meshes near the views' near plane:
  - frond tips and rail stanchions at the frame's lower corners in Bow;
  - the mast's root and a cable run in Astern.
  - They live in `bridge_dressing.glb`, placed per view from `views.json` (`levels.bridge.dressing`). Each is shown only in its view, and they fade with the occluder rule.
- **Below-rail scale cues.** Through the rail's gaps, a painted silhouette of the levels below: the next deck's rim and the garden cathedral's canopy. These are low-poly meshes 25–50 m down, inside the bubble, never painted space. They give true parallax as the camera slides.
- **Checks.**
  - The §D4 bow evaluator (`make deck-layout-eval`) keeps every threshold: dressing must not block the pole ray, the head, the stations or the stop body.
  - A new `dressing` row caps the dressing's share of each view's frame at 8 %. Its negative control is a seeded oversized prop.
  - The below-rail silhouettes are checked to lie outside every lower-deck volume in `ship.glb`, so they never intersect real geometry.

### S6. Review, measurement and the pause

- **`make style-capture TAG=<tag>`** writes a before/after sheet through the real views. The sheet covers Bow at rest in deep space, near the Sun, at 0.99c and at the first stop, plus Astern and the three console close-ups, with the HUD on and off.
- **Style frame first.**
  - S1 and S2 on the bridge as it stands, plus the theme on the status strip and one card, are captured and published.
  - **Mark approves the look before S3–S5 are built.**
- **Bench.** `make bench SCENE=bridge` p99 < 16.7 ms on a quiet rig, at the style-frame pause and at the end. The spire's shadow cube is the main risk, so §Risks lists the fallbacks.

## Review mocks (made for this plan, nothing built)

`tools/style_mock_capture.gd` applies S1 and S2 in-engine to the DL3 bridge, so Mark can choose before anything is built. Rows: **now**, **key retired** (S1), **toon** (S2), **both**. Columns: Bow in deep space, Bow near the Sun, Astern in deep space, Astern near the Sun.

- Contact sheet: https://storage.googleapis.com/stapledons-voyage-assets/refs/bridge_style/mock/contact_sheet.png
- The individual frames are `refs/bridge_style/mock/<row>_<deep|star>_<bow|astern>.png`. The PR body lists every per-file URL. The mock tool is committed with this plan as review-only; ST0's `tools/style_capture.gd` replaces it.

The mocks made one finding that the design now carries. The spire light sits inside the mast, so with shadows on, the mast hid the whole deck from it. Rendered with the mast as a non-caster (S1), the deep-space Astern frame shows the props throwing radial shadows from the spire, which is the look D-96 asks for.

## Acceptance criteria

| # | Criterion | Command |
|---|---|---|
| AC1 | The spire keys the bridge: on the bridge the broad key is 0; with no star close the spire is at `spire_base` and holds the only shadow; near a star exactly one of spire and star holds a shadow, the handover ramp has no step at its boundaries, and the spire sits at its floor; the three key checks listed in S1 change as stated, every other star-light check is unchanged | `make ship-star-light-test` |
| AC2 | The lower decks keep the broad key | `make ship-commons-test ship-lighting-test` |
| AC3 | Every `bridge_style` mesh (except the stated exclusions) uses the toon material with exactly the ink material as `next_pass`; every `style.bridge_nodes` entry exists; the named sky layers exist and none uses the toon shader; negative control: a seeded PBR bridge mesh fails | `make style-test` |
| AC4 | The physics goldens are unchanged in count and baseline | `make golden` (393 ok; `tools/golden_baseline.sh check`: 364 lines match main) |
| AC5 | The deck and spire painted, in budget, reimport clean, opaque, no emission | `make deck-assets-check` |
| AC6 | No hard-coded panel styles or colours in `ui/` or the demo's HUD code outside the theme builder (allow-lists: the crew palette, the physics overlays); the fonts, their OFL licences and the ink border present and pinned | `make ui-theme-check` (its negative control: a seeded `StyleBoxFlat.new()` fails) |
| AC7 | HUD text contrast ≥ 4.5:1 on its panel for every theme type | `make ui-theme-check` |
| AC8 | Dressing never blocks the pole, the head, the stations or the stop body, holds ≤ 8 % of each view, and the below-rail silhouettes lie outside the lower decks | `make deck-layout-eval` (`bridge ok`, the new `dressing` row; `make deck-layout-eval-test`'s seeded oversized prop fails) |
| AC9 | Frame time | `make bench SCENE=bridge` p99 < 16.7 ms with host load logged; on a shared rig, up to three runs while the 1-minute load is below 12, the best counting (the DL3 benches measured 15.6 ms at load ~12 and missed at 23 ms at ~16 with a capture running) |
| AC10 | Style frame and final captures opened and published | `make style-capture TAG=sf` / `TAG=final`, published to `refs/bridge_style/<tag>/` with per-file URLs |
| AC11 | The full suite | `make test`, `tools/rig_check.sh` on the PR head |

The look itself is Mark's judgement at the style-frame pause; the evaluator scores only that the pause happened with published, opened frames.

## Sub-milestones

| ID | What | LOC | Pause |
|---|---|---|---|
| ST0 | `make style-capture`, `make style-test`, `make ui-theme-check` with their controls (red first) | ~300 | — |
| ST1 | S1 lighting (spire key, shadow ownership, retire the bridge's broad key, rebalance) | ~200 | — |
| ST2 | S2 toon material on the bridge; the theme on the status strip and one card; **style frame** | ~250 | **Mark approves the look** |
| ST3 | S3 deck, spire and lift head painted (Blender) | ~100 + bpy | — |
| ST4 | S4 the theme across every HUD panel; the consistency pass | ~250 | — |
| ST5 | S5 per-view dressing and below-rail cues | ~200 + bpy | — |
| ST6 | Landing: rig run, goldens, bench, final captures, report, independent evaluation | docs | — |

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| The spire's omni shadow costs too much | Bench at ST1 and ST2. Fallbacks in order: a dual-paraboloid shadow, then a lower shadow atlas size, then shadows only inside 20 m, then no spire shadow with baked contact AO only |
| Toon bands flicker or alias at the slide's motion | Bands are computed from `NdotL × attenuation` with a 2 % smoothstep. `make style-capture` adds a 60-frame slide and bounds the mean frame-to-frame difference on the bridge's pixels against today's PBR shading |
| The theme lowers readability | WCAG check (AC7) and Mark's look at ST2 on the status strip, where text density is highest |
| Stylisation drifts into the sky | AC3's check and the golden baseline (AC4) |
| Retiring the key leaves the stern deck too dark near a star below the deck | The ambient floor and the spire's floor share stay. Captured at the Earth and Jupiter stops |

## Open questions (resolved by Mark, D-100, 2026-10-20: every recommendation taken)

| # | Question | Recommendation |
|---|---|---|
| OQ1 | Retire the broad key on the bridge and let the spire key it in deep space (row "key" of the mocks)? | **Yes** (resolved D-100) |
| OQ2 | Banded toon shading on the whole bridge (row "toon")? Three bands, or two for a harder comic look? | **Yes, three bands.** The sprites have soft shadow edges (resolved D-100) |
| OQ3 | Typeface pair for the HUD: (a) Fraunces + Source Sans 3; (b) Josefin Sans + Nunito (rounder, more 70s); (c) keep the current system face | **(b).** It echoes the comics' lettering. Recorded as the default with the plan's approval; the ST2 pause only confirms it on the status strip (resolved D-100: Josefin Sans + Nunito) |
| OQ4 | Panel shape: hand-drawn ink border (9-slice) or clean thin border in the palette? | **Hand-drawn ink border** (resolved D-100) |
| OQ5 | Physics overlays (pole marker, star labels, the Doppler legend) keep their functional colours rather than the palette? | **Yes:** readable and physically honest beats on-brand (resolved D-100) |
| OQ6 | Below-rail scale cues (the next deck's rim, the canopy below): wanted on the bridge now, or wait for the levels' own passes? | **Now:** a few low-poly silhouettes, replaced when those levels are built (resolved D-100) |
| OQ7 | Scope: bridge and HUD only; the Commons keeps the broad key and its look until its pass? | **Yes** (resolved D-100) |

## Deliverables

- `shaders/stapledon_toon.gdshader`; the lighting changes in `demos/ship_lighting.gd` and `demos/ship_star_light.gd`; `ui/stapledon_theme.tres` and its builder; the consistency pass across `ui/`.
- `tools/style_capture.gd`, `tests/test_style.gd`, `tools/ui_theme_check.gd`, `mk/style.mk`.
- `~/dev/blender/scripts/stapledon_bridge_props_v3.py`, `assets/ship_demo/bridge_dressing.glb`, pins in `art/deck-layout-v2/asset-pins.json`.
- `design_docs/implemented/r2/bridge-styling-pass-report.md` with before/after sheets and the bench.
