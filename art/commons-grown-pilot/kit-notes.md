# Commons connective grown architecture — bounded pilot

Mark asked for a much larger change toward the comic concept: long tendrils and
connected floor planting, beyond additional small houses or scattered pots.
Both `art/ship-tier-concepts-v1/commons.png` and
`art/ship-layers-v1/ship_layers_concept_v1.png` were reopened during authoring.
This kit translates their rooted structural sweeps and layered negative spaces
into real metre-scale geometry. The images do not authorize a widened spire,
glass dome, habitable core, new major deck or changed bridge dimensions.

| Named root | Triangles | Blender bounds min → max, metres |
| --- | ---: | --- |
| tendril_arch | 8,536 | [-8.45,-0.82,0] → [8.00723,0.95,10.0078] |
| planted_island | 5,984 | [-6,-1.42852,0] → [6,1.84263,1.53834] |
| rib_shade_canopy | 12,456 | [-4.77185,-2.31169,0] → [4.77185,2.28775,4.51613] |

Total **26,976triangles**, **3,358,308bytes**, **one pigment material/atlas**.
Each root has exactly two batched meshes, `<root>__structure` and
`<root>__details`; original logical parts are recorded in metadata. The structural
mesh is the optional collision source. Root owns actual world colliders/routes.
Identity roots use metres, Blender+Zup/+Yfront; glTF converts `(x,z,-y)`.
The exported GLB is an overlapping catalog; extract each named subtree.

The arch spans16.46m with two substantial flared cream roots, tapered flattened
limbs, separately grown teal/violet splits, fine ochre veins and a large central
human-clear opening. It is a side-placed connective structure, not a new spire,
continuous shell or decorative camera overlay. Thin members taper into tips;
all principal roots visibly reach the floor.

The12m island is a continuous open soil trough with an integrated0.48m seated
edge and a low sweeping garden back. Ten `FOLIAGE_planted_island_0..9` empties
sit just above the real soil surface; exact local Blender/glTF coordinates are
in `kit-source.json`. Existing painted foliage belongs there. The bare soil in
the studio image is intentional; no geometric leaves are exported.

The shade is a broad curved leaf, not a rectangular market stall. Two asymmetric
rooted spines follow its real edges; a thick opaque membrane, six curved
underside ribs and fine ochre edge lines complete the form. Ordinary headroom
remains beneath its centre. It adds no elevated walkable deck or room.

Existing cream/teal/ochre/violet gouache pigments are reused from the pinned
bridge maps. Converted curves and authored meshes share a single UV layer before
batching, preserving their intended colours. UVs repeat pigment locally over long
forms. No sky, star, spire illumination, emission, AO/light bake or projection is
in the texture/material. The actual game's toon/ink and lights remain live.

Root owns final placement, complete95m spherical vertex/plant-crown clearance,
the north protected sky corridor (shipx10..39), human routes and Bow/Astern
composition. The Metal studio hero is a separated catalog arrangement, omits
painted foliage and is not player-view sign-off. No production activation is
included in this asset-only commit.

## Sources and checks

Distinct native sources remain in the Blender workspace:

- `scripts/stapledon_commons_grown_pilot_v1.py`
- `scripts/validate_stapledon_commons_grown_pilot_v1.py`
- `scenes/stapledon_commons_grown_pilot_v1.blend` (packed editable master)
- `exports/stapledon_commons_grown_pilot_v1.glb`

Generate with the workspace launcher and bundled bpy: `./blender.sh --background
--factory-startup --python-exit-code 1 --python
scripts/stapledon_commons_grown_pilot_v1.py -- --game GAME --out OUT
--scene NEW_DISTINCT_NAME`. Existing masters are refused. No Python authoring
pipeline is added to the game repository.

Clean reimport verifies the three identity roots, two meshes each, exact vertex
bounds/triangle counts, ten anchor transforms and real soil below each anchor.
Fifteen horizontal diagnostic lines through the central arch remain clear at
floor/1.75m/2.20m heights; three vertical canopy samples have>2.5m headroom.
Imported arch UV cells retain the teal/violet/ochre splits and nonblack pigment.
Workspace inspect/validate pass with no missing resources. Final Metal hero was
opened and inspected. These local checks do not replace parent world-route QA.

Generator, validator, packed master and atlas have a recoverable archive under
ignored `build/commons-grown-source/`; exact path/hash are in metadata. Initial
same-task iteration is preserved in Blender `scenes/backups/`. Earlier furniture
and backdrop sources remain untouched. This is local preservation only; no
public upload or off-host backup is claimed.
