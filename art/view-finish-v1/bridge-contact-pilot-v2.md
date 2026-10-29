# Low-console contact shape v2 (VFB, unsettled)

Mark's review direction: **"Refine their shape before installing."** This is the
next optional proposal, not an installation or accepted finish. Existing operator
points, palm targets, sprites, consoles and their transforms are unchanged. V1's
source/master/GLB remain preserved.

The thin hollow controller loops become solid, low, tapered teal leaves growing
from the desk toward each ochre palm rest. The broader horizontal bodies read as
desk extensions. The hand endpoints cannot move without breaking the accepted
contact, so this changes the shape between them and the console. The initially
tried cream inset was removed to keep two palette materials and the shipping
triangle allowance. Original source objects were not edited.

| Guard | Measured result |
|---|---:|
| V2 additive meshes | 8 |
| V2 triangles | 1,824 |
| V2 materials / images | 2 / 0 |
| Additive GLB bytes | 37,312 |
| Current bridge props + V2 | 176,760 + 1,824 = 178,584 |
| Existing combined hero cap | 180,000 |

The pilot's previous standalone <5k budget was insufficient for installation:
V1's 3,776 triangles would put the combined total at 180,536. The v2 guard reads
the actual imported hero asset and its configured cap, tests the combined total,
and rejects that previous variant as an explicit negative control. It also holds
the new set to <=2k triangles, two materials, broader low leaf silhouettes and
exact v1 palm coordinates. Neither variant is installed in the playable scene.

## Actual player-camera comparison

Run `godot --path . --script tools/bridge_contact_v2_review.gd` in a reserved GPU
slot. `renders/view-finish/contact-pilot-v2/` contains 12 matched current/v1/v2
full 1280x720 frames, enlarged 640x640 detail crops, a sheet and `review.json`.
Sheet rows are Voyage then Crew. Columns are Astern current/v1/v2, then Bow
current/v1/v2. The review remains frozen rest, HUD off and +2-stop (4x) sky display
aid, matching the earlier study. The camera, feet and shown frame are recorded.
These are engine captures with the existing toon/ink shader, not paintovers.

Opened v2 Voyage Astern/Bow, Crew Astern and the full Astern view: both palm rests
remain in contact, with the hollow loop silhouette replaced by a broad filled
form. The shape still needs Mark's preference; this observation is not approval.
The Crew Bow lift occlusion remains baseline behavior. Navigation/Archive contact,
other light/resolution coverage and final VFB integration remain unfinished.

`godot --headless --path . --script tests/test_bridge_contact_pilot.gd -- --v2`
passes 46 checks. The unchanged v1 variant still passes its 33 standalone checks;
its combined installation budget is deliberately rejected by the v2 gate.

## Source preservation

The distinct authoring source is
`~/dev/blender/scripts/stapledon_bridge_contact_pilot_v2.py`, embedded in the new
`~/dev/blender/scenes/stapledon_bridge_contact_pilot_v2.blend`. Both original
v1 files and the 183 source object transforms remain unchanged. Input, generator,
master and output hashes are in `bridge-contact-pilot-v2.json`. Blender was run
through the workspace launcher with explicit assertion failure exit status.

The first task-created v2 draft was moved to ignored
`build/contact-v2-first-draft/` before refinement. Its captures are not the final
review set. The final v2 generator/master are copied into a **local-only** source
archive at `build/view-finish-contact-source-v2.tar.gz`, SHA-256
`febcb12b7e15d3c48d529d241abbdb5a32803f00e716fce03ce60b8a36f98712`.
No publication or durable remote backup of that new source archive is claimed.

Blender `make inspect SCENE=stapledon_bridge_contact_pilot_v2` reports zero missing
external files. A clean empty-scene GLB import verifies exactly 8 meshes,
2 materials and 1,824 triangles. The GPU harness returned 0 with all 12 frames
and no script errors; existing theme-import warnings and teardown RID warnings
remain. All captures were made in the isolated art clone, with the unchanged
bridge runtime baseline and only the additive proposal toggled.
