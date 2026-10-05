# Chosen bubble-ship geometry: seven major layers

Review hub: https://www.sunholo.com/stapledons-godot/docs/ship-layer-reference

Mark chose seven major layers and retained the proposed minimum 5 m lower-floor clearance
on 4 October 2026 (attended ledger D-34 and D-35). Architecture within these major tiers
will include buildings, forests and other spaces. The twenty-deck option is removed from
the current review and website assets; previous revisions remain in version history.

Revision 1 used 55% of the sphere's available horizontal radius at every lower deck.
The 3/4 projection made the middle gaps appear disproportionately large. Both revisions
have identical straight-on orthographic elevation cameras for a trustworthy comparison.

The chosen model fits the entire 1 m lower-floor slabs and edge lips within a 95 m radius
inner sphere, leaving at least 5 m to the 100 m bubble. Main slab radius at surface height Z:
sqrt(95^2 - max(Z^2, (Z-1)^2)) - 0.08 m.
This follows the bubble contour with a clearance rather than scaling each cross-section.

Units: metres. Blender +Z up/forward; origin at bubble centre.
Actual bridge unchanged: main radius 22 m, floor +82 m, needle +98 m. It is a smaller
platform, not expanded into a sphere-wide upper deck. Hidden WALK meshes are excluded.
Seven tiers: bridge +82 m, then +57, +32, +7, −18, −43 and −68 m.
The blend embeds generator.py and a READ ME from the study's creation; this document and
the decision ledger record its subsequent selection. Camera positions/FOV match v1.

Buildings and canopies must be tested at their actual heights. A 5 m buffer for the floor
alone does not certify architecture above it. The sphere narrows above upper tiers, so
roofs/trees need setbacks. Lower rooms, vegetation, roofs and bracing remain absent.
Nominal 24 m between lower slabs leaves room for multiple building storeys and tall spaces.
This is a dimension/visibility blockout, not structural engineering or final painted style.

Chosen model and captures:
https://storage.googleapis.com/stapledons-voyage-assets/refs/ship_dimensions_v2/
ship_dimensions_tiers_v2.blend/.glb.
tiers/ contains overview.png, elevation.png, interior_{15,30,45,60}.png,
rim_{15,30,45,60}.png, panorama_current.png and measurements.json.

Recommended asset architecture: one Blender master assembly using linked tier/area
collections; detailed playable sections and simplified whole-ship/map representations
exported from the same measured design. This page update does not change the game renderer.

Verification: all physical vertices inside 100 m bubble; every lower-floor vertex inside
95 m envelope (actual minimum clearance 5.027 m). Saved-scene health, clean GLB reimport,
visual inspection, and centre-ray hits checked. Models retain neutral blockout materials;
use the concept sheet for style.
