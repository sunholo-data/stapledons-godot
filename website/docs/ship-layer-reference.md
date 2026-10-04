---
title: Ship layers — art reference
sidebar_position: 7
---

This concept sheet connects the bridge to the whole bubble ship. It is a **proposal for
art review**, created on 4 October 2026, and a reference for future Blender builds. It is
not an approved exterior model, a game capture or a dimensioned construction drawing.

![Whole-ship cutaway and bridge-rim support concept](/img/concept/ship-layers-v1.jpg)

[Open the full-resolution concept sheet](https://storage.googleapis.com/stapledons-voyage-assets/refs/ship_layers_v1/ship_layers_concept_v1.png).

The sphere contains the ship; it is not a solid hull. The central Higgs spire connects its
levels, with the bridge as the highest occupied deck beneath the forward pole. Lower
levels widen toward the equator and narrow toward aft. Gardens and every part of their
canopy stay inside the boundary.

## The fixed frame

| Anchor | Authoring reference |
|---|---|
| Bubble | Approximately 100 m radius, centred at the ship origin |
| Forward and up | Blender +Z; aft and down are -Z |
| Current bridge | Deck at +82 m, about 44 m across |
| Current needle tip | +98 m, on the same central spire |
| Above the bridge | Open view to the bubble's forward pole; no higher occupied deck |

These anchors come from the ship briefs and current bridge bundle, not from measurements
of the generated illustration. The outline in the sheet only makes the containing sphere
readable. The game renders the sky and physical boundary glow live.

## Why the foreground has roots

The rim detail proposes curved members attached to the bridge rim or structural gallery
below it. They can rise past the bridge deck and curve beside the viewer, provided their
roots and tips fit the shared ship geometry and remain inside the sphere. They cannot float
in front of the camera merely because they are drawn in a foreground layer.

The drawing layers describe distance from a camera, not separate physical decks:

- **Play layer:** the walkable deck, captain and nearby ship geometry.
- **Foreground:** real nearby rails, fronds or supports, placed mainly at the view's edges.
- **Panorama:** ship structure beyond the play area, viewed through its own exported camera.
- **Sky:** drawn live behind the ship and fixed at infinity.

The same spire must not appear twice in different layers. On the current bridge, the
panorama camera looks upward toward the forward sky, so it does not see lower decks. A
view from the rim or a lift can look down into them. Other levels need their own views,
including the underside of the deck above.

## What remains a proposal

The commons, homes, garden cathedral, workshops and engineering form a zoning study.
Their precise order, floor count, heights, routes and details are open for review.

The older briefs contain a spacing conflict: 10–20+ levels and roughly 25 m between
levels cannot both describe a simple stack inside a 200 m sphere. An older feature instead
lists 5–8 m spacing. This sheet explores major cathedral-height zones with smaller
mezzanines, without choosing a final floor schedule.

For Blender builds, use the measured coordinate frame and boundary constraints first,
then review the zoning and support attachments. Do not infer exact dimensions from the art.

**AI-generated concept art under Sunholo art direction. No copyright is claimed.** See
[Credits and licences](credits.md) and [Concept art](/concept-art).
