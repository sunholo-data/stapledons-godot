# Painted 3D bridge — first material interpretation

Historical v1 material proof: current playable exports now include the physical floor restoration documented in `../grounded-bridge-v2/README.md`. Pins and exact unchanged-geometry statements below describe the v1 release, before that explicit new surface.

This is a review draft of the original painted bridge palette on the measured, freely viewable 3D ship. It does not claim a pixel-identical match or final art approval. The approved `assets/areas/bridge/plate_bridge.png` remains a reference only; no plate, camera silhouette or baked lighting is projected into this model.

The ten packed 627×627 pigment images reuse genuine brush variation from the existing Commons paint atlas (its source/provenance remains `art/ship-commons-v1/README.md`). Nine component families cover teal, cream, violet, ochre, coral, mint, leaf, spire and glow. A separate ash-gray pigment applies only to cream deck bodies/fill, preserving the original darker floor value without changing sky exposure or cream props. Authoring colours in the JSON are linear RGB. The earlier near-white floor draft was superseded after actual native review.

Every face uses continuous object-local dominant-plane UVs at a four-metre repeat scale. All materials are opaque and double-sided, as the original mesh requires. Existing violet seam and rim geometry supplies the thin geometric edges; complete original illustrative ink fidelity remains an art-review question. Floor, rails, fronds, helm and core props receive actual UV pigments; the underlying lower-tier surfaces retain the same bounded prototype geometry.

## Editable sources

The two `.blend` files here contain packed maps and an embedded generator. `stapledon_bridge_mesh_painted_v1.blend` exports the base ship; `stapledon_unified_ship_painted_v1.blend` includes the approved Commons first arcade and lower assembly, with the same bridge pigments. Its original Commons atlas, UVs and materials are unchanged. The canonical Blender authoring repository is `/Users/voightkampff/dev/blender`, commit `e4da963`; scripts are `scripts/stapledon_bridge_mesh_paint_v1.py` and `scripts/stapledon_bridge_mesh_paint_render.py`. Both are authored and run using that workspace's `./blender.sh`, not a game Python art pipeline.

The generator defaults to the original base master. Unified reproduction sets `BRIDGE_PAINT_SOURCE` to the Commons-v3 master, `BRIDGE_PAINT_MASTER`, `BRIDGE_PAINT_EXPORT_DIR`, `BRIDGE_PAINT_EXPORT_NAME`, and `BRIDGE_PAINT_ALLOWED` to the original bridge mesh-datablock selection. Original shared mesh instances inherit their family finish. Preserve a backup before rerunning into an existing task master.

## Validation and review views

Oriented world-triangle comparison at 10 micrometres is exact against the prior committed GLBs: base ship 152 instances / 196,182 triangles; unified assembly 499 / 220,698. Blender vertex coordinates, polygon topology and transforms also have identical before/after digests in each provenance JSON. All 348 Commons-added/unpainted UV and material records and its original packed atlas bytes are unchanged. WALK files, dimensions, manifest, lift and collision geometry remain unchanged. Asset byte counts and SHA-256 pins are in `asset-pins.json`.

Both masters passed `make inspect`; both exported GLBs passed clean Blender reimport. Logs and geometry proof are in `validation/`. Native views in `native/` show the physical captain eye at 83.7 m, a labelled three-metre third-person comparison, inward view, and overlook. Exact camera/sky metadata is in `native/manifest.json`. Blender views in `blender/` were rendered with Cycles Metal on the M4 Max at the same captain and third-person perspective settings. No photons, relativistic shader, kinematics or camera calibration were changed by the material pass.

Independent technical evaluation and user art review are required before calling this a final style match.
