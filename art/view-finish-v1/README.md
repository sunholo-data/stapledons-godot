# Bridge / Commons finishing sources (VF0)

Recovered on 2026-10-29 for approved R2-VIEW-FINISH (D-130). This directory records
source preservation; large snapshots stay outside git. The content-addressed
archive is now backed up publicly at the approved project asset bucket; its
downloaded SHA-256 was independently checked against the local archive.

`source-inventory.json` records SHA-256 and byte length for every preserved file,
plus Blender read-only inspection of both current art masters. Bridge v4 master
and script match `art/deck-layout-v2/asset-pins.json`. Both masters open in Blender
5.2.1 LTS without missing image or library resources. Commons v3's embedded native,
paint and expanded generators were recovered, along with the embedded bridge
floor/paint/deck dependency chain.

| Master | Objects / meshes | Image datablocks | Missing resources |
|---|---:|---:|---:|
| `stapledon_bridge_props_v4.blend` | 183 / 72 | 30 | 0 |
| `ship_commons_master_v3.blend` | 535 / 408 | 1 | 0 |

The original Blender checkout is on `art/bridge-buildout-v1` at `e4da963`. Its
latest bridge generators and masters are untracked; unrelated captain animation
sources also exist. Preservation copied specific files and opened copies only;
no clean, reset, original scene save or unrelated modification was performed.
The current Commons v3 master remains tracked at `art/ship-commons-v1/`.

## Recover or repeat inspection

From a game clone, run `./art/view-finish-v1/preserve-sources.sh [Blender repo]`.
It refuses to overwrite an existing `build/view-finish-source` snapshot. It uses
that workspace's launcher and bundled bpy, never system Python. This is an
explicit source-recovery authoring operation, not a game asset pipeline.

The snapshot includes selected authoring scripts, v4/layout/grounded/Commons
masters, the packed original Commons atlas, layout/pin inputs, embedded scripts
and an inventory. The recovery scripts do not regenerate or export runtime GLBs.

Archive: `build/view-finish-source.tar.gz`, SHA-256
`2e13388120ca13101d657e7d7af7637ea47a8837cb1caaf695e25bfb33bc5237`.
Mark explicitly approved this exact archive and destination in the attended
session after automatic review required payload/destination approval. The upload
used a create-only generation precondition and its public download hashes to the
value above. [Download the preserved sources](https://storage.googleapis.com/stapledons-voyage-assets/ship/2e13388120ca13101d657e7d7af7637ea47a8837cb1caaf695e25bfb33bc5237.tar.gz).
The inventory's local-snapshot status describes the inspection before upload;
this note records completed publication. Published bridge v4 master recovery
also remains available at the content-addressed URL already pinned in
`art/deck-layout-v2/asset-pins.json`; no duplicate large `.blend` is added here.

VF0's full milestone also includes the coordinator's baseline captures/gallery;
source inspection alone does not mark VF0 or VFB complete.
