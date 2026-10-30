# Independent review: bounded Commons lived-in pilot

**Reviewed checkpoint:** `dfc4142f`.
**Scope:** publication readiness for the D-133 court/arcade art study, measured against the approved bridge styling and Commons brief. This reviewer did not author the pilot kit, placements, loader or capture tools. No GPU work or source changes were performed during the review.

## Pinned evidence

The completed `renders/view-finish/commons-lived-in-pilot/review.json` contained **48 frames and zero errors** when inspected:

- Source GLB SHA-256: `7b841838dfab86c6c0f96ab0bb10c26842ce51440bae843b12cdb6c3eb9e2935`.
- Placement config SHA-256: `88079c7c7dc40cf8e2ecae451db921adbe02a9b3eee5594cfb3d549b1124da7c`.
- Capture set: four supported player positions, Bow/Astern, rest/cruise/real guided stop, matched pilot-off/pilot-on variants.

The complete 48-frame contact sheet was inspected. These actual player frames were also opened at full size:

- `seating_bow_rest_before.png` and `seating_bow_rest_after.png`.
- `seating_bow_stop_after.png`.
- `seating_astern_rest_after.png`.
- `arcade_edge_bow_rest_after.png` and `arcade_edge_astern_rest_after.png`.

## Visual findings

**No publication blocker found for this bounded pilot study.** The seating and notice corner make the court feel used while preserving the open centre, captain readability and monumental architecture. Curved furniture, restrained cream/teal pigments and visible local lamps fit the approved bridge treatment. No visible floating furniture, doubled pots, captain obstruction or new sky clutter was found in the inspected evidence.

Use the seating Bow rest comparison as the main presentation: it shows the change clearly. Captions should distinguish **“Current layout, pilot off; greybox notice marker restored”** from **“Review-only lived-in pilot.”** Remaining upper magenta find markers and unfinished architecture are greybox, outside this furniture study.

**Arcade coverage limit:** `arcade_edge` resolves to the court stage and should be presented as **“Arcade approach.”** Piers and framing largely hide the counter/cart. These frames establish the approach composition but provide limited evidence for accepting the bay interior's finish. They should not be described as a complete interior review.

## Loader and QA scope

Code inspection found the review-only boundary appropriate: selected authored GLB subtrees, explicit structural collider meshes, shared toon/ink materials, foliage grounded at world/soil anchors and bounded local practicals. The loader does not change WALK, camera definitions, layout or simulation. Capture variants switch pilot geometry, foliage, lights and solids together, restore/remove the notice marker, compare camera transforms and record source/config hashes.

The placement validator covers actual floor support, captain capsules at the selected views, their executed returns to the lift, stair/ladder/hatch endpoints and unchanged full Commons metric thresholds. This is **sampled-path QA**, not proof that every possible free walk avoids every new prop. The executor reported placement validation 44/0, loader checks 31/0 and dedicated pilot GPU pole checks 6/0; those checks were not independently rerun as part of this visual/code review.

## Decision boundary

This finding establishes **pilot feedback readiness only**. It is not visual acceptance of the pilot, permission to repeat its treatment across other stages, completion of every manual S3 playtest item, S5 appearance acceptance, a full-sprint evaluation or an exact-head rig/CI/native-export/performance result. Those remaining gates retain their approved scope.
