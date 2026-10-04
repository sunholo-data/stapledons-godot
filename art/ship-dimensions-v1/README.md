# Bubble ship dimension study v1

Review hub: https://www.sunholo.com/stapledons-godot/docs/ship-layer-reference

Two alternatives, not approved floor schedules:
- A: 7 tiers including the actual bridge, 25 m spacing, +82 to −68 m.
- B: 20 decks including the actual bridge, 8.5 m spacing, +82 to −79.5 m.

Units are metres. Blender +Z is up/forward. Sphere radius 100 m at origin.
Main bridge deck radius 22 m, surface Z +82 m. Actual imported needle tip Z +98 m.
Lower radii: 0.55 × sqrt(100² − Z²). Opaque lower slabs: 1 m thick.
Actual bridge geometry imported from the bridge_v2 play_bridge.glb, excluding invisible
WALK collision meshes. Bridge prototype/style geometry is otherwise unchanged.
All physical mesh vertices fit inside the sphere; max radius 98.00 m.

Each Blender file embeds its generator in `generator.py` and a READ ME text block.
It includes an overview, orthographic elevation, and nine named perspective cameras.
Metal Cycles was used for the checked renders. The sphere circles are measurement aids;
hide them for eye views. Lower rooms, railings, roofs, supports and vegetation are absent:
these are visibility blockouts, not structural engineering or finished style models.
The concept sheet in ../ship-layers-v1 is for style only, never dimensional measurement.

Eye position: interior (16, −8, 83.7), rim (19.0513, −9.52565, 83.7).
Both look outward at down tilts 15, 30, 45, 60 degrees. Vertical FOV 78 degrees.
Measurement JSONs record schedules, actual bridge bounds and centre-ray first hits.
The current game panorama points inward/up and play plate is orthographic/down;
these whole-model perspective renders deliberately provide coherent physical sightlines.

Published assets live at:
https://storage.googleapis.com/stapledons-voyage-assets/refs/ship_dimensions_v1/

Files: ship_dimensions_tiers_v1.blend/.glb, ship_dimensions_dense_v1.blend/.glb.
Subfolders tiers/ and dense/: overview.png, elevation.png, interior_{15,30,45,60}.png,
rim_{15,30,45,60}.png, panorama_current.png, measurements.json.

Validation: saved scene health (no missing dependencies), clean GLB reimports, all-vertex
boundary checks, centre-ray audit, and visual inspection of the matched captures.
