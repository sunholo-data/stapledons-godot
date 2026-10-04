# Bubble ship dimension study v2

Review hub: https://www.sunholo.com/stapledons-godot/docs/ship-layer-reference

Mark prefers seven major layers with architecture, buildings and forests within them
(attended 4 October 2026, ledger D-34). Twenty decks remain a comparison, not the preferred
layout. The exact radii and clearance are still proposals.

Revision 1 used 55% of the sphere's available horizontal radius at every lower deck.
The 3/4 projection made the middle gaps appear disproportionately large. Both revisions
have identical straight-on orthographic elevation cameras for a trustworthy comparison.

Revision 2 fits the entire 1 m lower-floor slabs and edge lips within a 95 m radius inner
sphere, leaving at least 5 m to the 100 m bubble. Main slab radius at surface height Z:
sqrt(95^2 - max(Z^2, (Z-1)^2)) - 0.08 m.
This follows the bubble contour with a clearance rather than scaling each cross-section.

Units: metres. Blender +Z up/forward; origin at bubble centre.
Actual bridge unchanged: main radius 22 m, floor +82 m, needle +98 m. It is a smaller
platform, not expanded into a sphere-wide upper deck. Hidden WALK meshes are excluded.
A: bridge + six lower tiers, 25 m spacing, bottom −68 m.
B: bridge + nineteen lower decks, 8.5 m spacing, bottom −79.5 m.
Each blend embeds generator.py and a READ ME. Camera positions/FOV match v1.

Buildings and canopies must be tested at their actual heights. A 5 m buffer for the floor
alone does not certify architecture above it. The sphere narrows above upper tiers, so
roofs/trees need setbacks. Lower rooms, vegetation, roofs and bracing remain absent.
Nominal 24 m between lower slabs leaves room for multiple building storeys and tall spaces.
These are dimension/visibility blockouts, not structural engineering or final painted style.

Models and captures:
https://storage.googleapis.com/stapledons-voyage-assets/refs/ship_dimensions_v2/
ship_dimensions_tiers_v2.blend/.glb and ship_dimensions_dense_v2.blend/.glb.
tiers/ and dense/ contain overview.png, elevation.png, interior_{15,30,45,60}.png,
rim_{15,30,45,60}.png, panorama_current.png and measurements.json.
Revision 1 remains in ../ship-dimensions-v1 and its original public asset prefix.

Verification: all physical vertices inside 100 m bubble; all lower-floor vertices inside
95 m envelope. Saved-scene health, clean GLB reimports, visual inspection, and centre-ray
hits checked. Models retain neutral blockout materials; use the concept sheet for style.
