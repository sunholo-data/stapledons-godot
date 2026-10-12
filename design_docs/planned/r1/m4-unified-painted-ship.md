# One current ship demo with painted 3D bridge

| Pillar | Score | Evidence |
|---|---:|---|
| The Ship Is Home | +2 | A single playable ship connects bridge, Commons, star inspection and navigation. |
| Grounded Strangeness | +2 | Painted mesh surfaces retain perspective and physical occlusion under one observer. |
| Time Has Emotional Weight | +1 | Normal startup uses the live at-rest simulator; committing shows actual boost/cruise/braking. |
| Choices Are Final | +1 | Existing irreversible hold-to-commit remains the only departure action. |

Status: Approved attended continuation,5October2026. Mark requested consolidation of the earlier painted bridge style with expanded ship/eyeline, then clarified the desired Blender model with painted assets attached. This is a bounded review-build continuation, not approval of final replacement art or a production merge.

Implements [ship layout](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/bubble-ship-layout.md) and [SR observer specification](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md). Depends on the approved seven-tier model, Commons and star identification. Net+6, aligned. Estimate one focused authoring pass plus integration, native captures and independent evaluation.

Inspected reality: the original bridge plate is a painted orthographic render; the separate sky used a perspective camera. Neither original bridge GLB nor expanded ship GLB contains image textures. Therefore the finished old composite is an art reference, not proof of free-angle physical alignment. The expanded demo has one perspective observer for actual3D geometry and sky. Its previous bridge default was3m third-person pullback, raising the camera above the captain; look shortcuts use a true1.7m standing eye.

## Approved continuation

- A normal double-click/noargument launch opens the latest integrated ship; no second player-facing review demo button is needed. Explicit original `--interior`, captures/goldens/map/voyage remain developer reference modes, preserving existing evidence.
- Main startup is a normal live at-rest navigation session, with a hidden map using the same session as the ship. M opens it; a heldCommit returns the player aboard for physically simulated acceleration/coast/braking. Snapshot controls stay clearly labelled diagnostics.
- Default bridge view is the captain’s actual1.7m eye (Z83.7m onZ82floor),78° verticalperspective. Scrolling can reveal an explicitly labelled third-person view. Reset restores captain eye. Geometry/sky always share the actual current camera pose.
- Author a bounded painted3D bridge finish in the existing Blender workspace. Preserve positions/topology/transforms/guarded lift/WALK; attach genuine UV textures to opaque surfaces. Reuse approved bridge colours/inked finish and Commons’s textured-mesh approach. Do not stamp an occluded old plate across arbitrary surfaces or use a camera-following billboard to simulate free-angle paint.
- Preserve editable packed Blender master and asset provenance. Record this as first3Dpaint interpretation awaiting art review, not a pixel-identical recreation or final whole-ship painting.

## Checkable gates

| Gate | Command/evidence |
|---|---|
| One normal entry, explicit legacy test routes retained | `make ship-demo-consolidation-test` plus normal bundled startup |
| Live rest clock, same navigation session, no frozen-cruise default | `make ship-demo-consolidation-test ship-demo-live-test` |
| Captain eye default, optional labelled third person, shared physical camera | `make ship-demo-consolidation-test ship-demo-ci` and actual eye/FOV captures |
| Genuine UV/image materials, unchanged geometry and WALK assets, packed master | Blender inspect/export + geometry/material/texture pin comparison |
| Style assessed from multiple reachable camera positions, not solely original projection | Native bridge captain-eye/third-person/look-down and Commons captures opened by author and independent judge |
| Star overlays continue to align/occlude after texture/material replacement | `make ship-star-identification-test ship-star-identification-capture` |
| Regression/physics/native bundle retain approved behavior | `make test golden`, packaged live/identification/normal smokes |
| One installable next devbuild and reference-page instructions | Published manifest, downloadedZIPchecksum and deployedpage verification |

No newphysics formulas. Actual M2Air performance remains pending. Main landing/production merge remains gated by applicable project requirements.
