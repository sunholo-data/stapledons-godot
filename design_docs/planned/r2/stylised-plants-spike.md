# Spike: stylised plants (decision note)

**Status:** spike result, awaiting Mark's choice. Nothing here ships.
**Asked by:** Mark, attended 2026-10-20, as a D-103 follow-up: "I wonder how we handle organic plants etc the current blender models are not good, anyway we can get something more stylistic?" Then, as D-104: "everything looks quite boxy with edges, isn't the style more rounded curves?"
**Tool:** `tools/plants_spike_capture.gd`, a review tool only. It renders through the player's Bow view at 1280×720.
**Frames:** `gs://stapledons-voyage-assets/refs/plants/spike/` (contact sheet: rows A–D; columns deep space, near the Sun, 0.99c).

## What was compared

One plant bed beside the captain's spawn point: a frond, a flowering shrub, a 4 m tree, vines on a rail, and a "grown" planter. Each treatment also replaces the bridge's ten rim fronds.

| | Treatment | How it was made |
|---|---|---|
| A | Today's Blender plants | The rim-frond mesh, the only plant in the ship today, scaled to each slot |
| B | Painted cards | 5 gouache sprites with transparent backgrounds from the art pipeline (`codex exec -m gpt-6.1-sol`, built-in image_gen, subscription lane, one run of about 3 minutes, no metered spend). Each sits on a view-locked card and is lit through a rounded "sphere" normal with three toon bands. A mirrored back card adds depth. A wind sway shader is in place but holds still in stills. |
| C | Stylised 3D | Sinuous swept tubes, lathed (turned) planters, arching ribbon leaves, ellipsoid leaf clouds, three toon bands and an inverted-hull violet ink line. The tree canopy carries painted leaf-clump cards cropped from B's tree, as the hybrid. |
| D | Procedural leaf clouds | C's stems and planters, with canopies and shrubs made of 40–180 generated leaf quads each, shaded by normals centred on each cloud. No image generation. |

## Findings

| Criterion | A | B | C | D |
|---|---|---|---|---|
| Style match to the concept art (gouache, violet ink, Moebius curves) | No. A green crook stalk, not a plant | **Yes.** It is the concept art's own medium. The grown planter reads as grown technology at once | Partly. Smooth and curved, but reads as clay or toy | No. Speckled and noisy at game size |
| Readable at captain scale (81 px at 720p) | Poorly | **Yes.** Silhouette, blossoms and trunk all read | Yes, but simple | The silhouette reads, the detail turns to noise |
| Curves (D-104) | Smooth but crude | **Flowing.** Painted curves at any resolution | Smooth. Tubes and lathes have no facets | Ragged edge |
| Lighting (spire key in deep space, star key near a star) | Lit as a mesh | Takes the spire and the star through the sphere normal and toon bands. Paintings should be lit evenly, so their baked light never fights the star | Correct 3D lighting and shadows | Correct volume lighting and shadows |
| Shadows | Mesh | A card silhouette. It thins to a line when the light is edge-on, so it needs a proxy caster | Real | Real |
| Depth and parallax as the camera slides | Real 3D | A flat card is foreshortened toward the frame edge. Needs a clamped billboard (see OQ2) plus layered cards | Real 3D | Real 3D |
| Authoring cost | Hand-modelled | **About 1 image per plant kind,** plus an automatic cut-out check. Dozens per level is cheap. The 5 cards took one 3-minute Codex run | High. Every plant is code or Blender | Medium. Generated, but tuning per species |
| Determinism and regression | Yes | Yes | Yes | Yes |
| Triangles for the bed plus rim fronds | 23,440 | **56** | 96,952 | 45,546 |
| Texture memory | — | 1024² RGBA per kind. 512² is enough at game size (about 0.3 MB per kind, compressed) | — | 64 KB |

**Determinism:** two separate runs give byte-identical deep-space frames for every treatment, including the baseline. The near-Sun and 0.99c frames differ between runs for every treatment, the baseline A included. That comes from the scene's easing toward the star and the sky, not from the plants, and is noted as out of scope.

**Frame time:** not measured reliably. Load on the rig was 45–48 while the spike ran, and every treatment came out at 9.5–12.7 ms with vsync off, inside the noise. Triangle counts are the dependable cost signal, and there B is the cheapest by far.

## Recommendation

**B, painted cards, as the default for plants, with C kept narrowly for structure.**

- **Every plant, frond, shrub, vine and leaf mass** is a painted card from the art pipeline. It shows the art bible's medium directly, it is the only option that answers D-104's "rounded curves", and it is cheap enough for an agent to dress a whole Garden or Farm.
- **Stylised 3D (C) only where a plant is walked around or blocks the view:** large Garden tree trunks (15–20 m canopies), planters, and grown-technology fixtures that are part of the architecture. They use smooth tubes and lathes, never faceted low-poly, with painted leaf cards for their foliage. That is C's hybrid half, which looked right on the tree.
- **Rejected:**
  - D: noisy at game scale.
  - A: Mark's original complaint.

## How it plugs in

- **R2-LEVELS (D-103):**
  - The level manifest gains a `foliage` list. Each entry has a `kind` (a key into a foliage library), `pos_m`, `height_m`, `layer` (foreground, middle or background, for parallax), `facing` (view-locked, or a billboard clamped to ±25°), `sway` and `shadow` (card or proxy).
  - The library lives in `assets/foliage/<kind>.png`, with sha256 pins and provenance (prompt, model `gpt-6.1-sol`, date), the same pattern as the characters.
  - A `make foliage-check` gates alpha coverage, no key colour, the base anchor at the bottom centre, the palette range and size.
  - At S4 (dressing), the level brief lists the plant kinds, the art pipeline paints any that are missing, and the generator places cards from the manifest. The evaluator already measures occlusion, so plants join the fade list like any other occluder.
- **The bridge's rim fronds:** replace the ten rim-frond meshes with painted frond cards. This belongs to R2-BRIDGE-STYLE S5 (dressing per view), which owns the bridge files now. The card material needs the occluder-fade parameter the fade list drives.
- **Shaders:** the spike's card shader (alpha cut, sphere normal, three bands) should merge into R2-BRIDGE-STYLE's shared toon material, not ship as a second shader.

## Open questions, with recommendations

- **OQ1, the treatment:** B as the default, C for structure. Recommended.
- **OQ2, facing:** a billboard around the plant's base, clamped to ±25°, so the flat card never foreshortens toward the frame edge but keeps its painted side to the view. Recommended. Purely view-locked cards already looked fine near the centre of the frame.
- **OQ3, painted light:** ask the art pipeline for evenly lit paintings with ink lines, so the game's spire and star light do the shading. Recommended.
- **OQ4, shadows:** a low-poly proxy that casts the shadow, for trees and big plants. Small plants keep their card shadow. Recommended.
- **OQ5, spend:** Codex Sol on the subscription lane, about one image per plant kind, batched per level brief, no metered API. Recommended. Mark approves each level's kinds at S0 (the brief).
- **OQ6, rim fronds:** swap them within R2-BRIDGE-STYLE S5 rather than in a sprint of their own. Recommended.
