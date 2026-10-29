# Commons architectural backdrop — bounded pilot

The current furniture pilot does not fill the large empty outer floor. These
four modules supply a layered civic district around the existing Commons,
using the approved concepts for density, curved architecture and palette.
Concept glass dome and broadened spire remain rejected geometry drift.
No layout, WALK, bridge, core, sky or production activation is changed here.
Root owns placements, real player views and the complete95m vertex envelope.

| Root | Triangles | Blender bounds min → max, metres |
| --- | ---: | --- |
| civic_arcade | 23,418 | [-5.15,-2.73,0] → [5.15,2.73,7.18] |
| low_market_canopy | 10,616 | [-2.65,-2.025,0] → [2.65,2.025,3.1915] |
| curved_garden_parapet | 2,416 | [-2.96985,-1.03227,0] → [2.96985,1.03227,1.13] |
| civic_alcove | 9,996 | [-3.65,-2.09,0] → [3.65,1.92,5.1261] |

Total46,446triangles,4,303,624bytes,one referenced material/embedded1536×1024
pigment atlas. Two meshes per logical module, named `<root>__structure` and
`<root>__details`, allow repeated instances without hundreds of child draws.
The metadata structural list selects the first mesh, but the current distant
review placements should remain non-solid outside the existing WALK.

All roots are identity, metre-scale at the floor; Blender+Zup/+Yfront converts
to glTF(x,z,-y). The GLB is an overlapping catalog: extract each named subtree.
`kit-source.json` supplies exact measured source/glTF bounds, hashes and all
11soil anchors:5arcade,4garden,2alcove. No geometric leaves or foliage cards
are embedded. Existing painted shrubs/trees belong on the real soil anchors;
root must validate complete plant crowns as well as structural vertices.

The arcade has three true open ground passages, hollow civic-room wall shells,
cut arched door/window openings, inset closed leaves, a planted upper terrace
and one continuous swept roof with grown structural backbones. Doors are2.2m.
The low market shade has actual double-sided thickness, curved rooted supports,
a sagging tension roof, modest counter and ceramic wares. The low garden is an
actual curved soil bed/parapet; the rear alcove has a deep open bay and rooted
roof gardens. No uniform enclosing ring, blank billboard facade, repeated roof
domes, glass hull or new tier is supplied.

The existing cream/teal/ochre/violet/coral/leaf pigment maps are reused. No
emission, sky, star, spire lighting, AO/light bake or camera projection appears
in the material. The shared game toon/ink and live lights remain authoritative.
The neutral Metal studio hero omits foliage and overlaps modules for catalog
inspection; it is not a world-composition or lighting proposal. Actual normal
Bow/Astern frames with furniture hidden are the density sign-off evidence.

New native sources remain in the Blender workspace:
`scripts/stapledon_commons_backdrop_pilot_v1.py`,
`scripts/validate_stapledon_commons_backdrop_pilot_v1.py`, and
`scenes/stapledon_commons_backdrop_pilot_v1.blend` (packed editable master).
Generate with the workspace `./blender.sh --background --factory-startup
--python-exit-code 1 --python scripts/stapledon_commons_backdrop_pilot_v1.py --
--game GAME --out OUT --scene NEW_DISTINCT_NAME`. Existing masters are refused.
No Python authoring pipeline is added to the game repository.

Clean reimport verifies4identityroots,8meshes,11exactanchor transforms, the
full source bounds, per-module triangle counts and nonblack atlas pixels.
Nine real structural rays pass the open arcades and cut wall apertures;
window-wall rays begin behind the real foreground colonnade. Closed leaves
remain intentionally present in the separate detail mesh. Master inspection
finds no missing external resources; workspace GLB validation passes.

Final generator, validator, packed master and atlas have a recoverable local
archive under ignored `build/commons-backdrop-source/`; exact SHA/path are in
metadata. Earlier task-created iterations were preserved in Blender
`scenes/backups/`. No source upload, off-host backup or production readiness is
claimed. Existing user scenes and earlier furniture sources remain untouched.
