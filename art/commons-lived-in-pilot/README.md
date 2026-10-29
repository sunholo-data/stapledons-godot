# Commons lived-in pilot

Mark's attended direction (D-133, 2026-10-29) is to make the promising but bare
levels feel like a lived-in ship. This is one court/arcade study on the current
layout, shown in actual player views before repeating its finish. It does not
assert that every S3 manual playtest item has been completed.

The existing architecture, routes and sky remain the large shapes. Three useful
clusters provide human scale:

- News corner: replace the notice-board marker with a grown stand, reading lamp
  and a shallow shelf. Use the established news-from-home function without
  inventing organisations, crew histories or new gameplay.
- Shared sitting place: crescent bench and low table, with cups, a book and
  folded cloth. A slightly pulled-out seat suggests recent use.
- One arcade bay: curved counter, vessels, small storage and a modest practical.
  Keep its passage and the main court open.

Match the approved bridge: grown curves, flared roots, leaf-like tops, cream and
teal, restrained ochre/violet accents, painted pigment and contact texture, shared
toon/ink materials. Illumination stays live. Ground varied foliage in real
planters. Small items support the furniture silhouettes rather than replacing
them with scattered clutter.

## Scope and evidence

The native Blender generator/master are distinct copies in the authoring
workspace. `kit-source.json` pins the review GLB and records provenance;
`placements.json` owns ship-frame placement and explicit structural colliders.
The review loader is invoked only by the pilot capture/validation tools. This
kit is not installed in the downloadable S3 layout build.

Check actual floor support, capsule-clear routes and both view directions.
Capture matched before/after rest, cruise and real-stop frames from court,
arcade and under-terrace positions, including the real ceiling clamp. Preserve
the bridge, hatch, stair/ramp, ladder approaches and rail horizon. World-space
plants use the existing painted-card/shadow conventions.

The next gate is visual acceptance of this pilot before it is repeated across
other stages. S5, performance, export and final independent/rig checks remain
required for the full finishing sprint.

## Review round 1

Private laptop gallery: https://voights-mac-studio.tail97eda0.ts.net:8452/ . The
first comparison is shared seating in Bow at rest. Forty-eight matched engine
frames cover four supported points, Bow/Astern and rest/cruise/real guided stop.
The same +2 EV display setting is retained in each pair; sky and lighting remain
live. The neutral Blender hero is labelled as an authoring detail view.

The kit has eight authored groups, 32,224 unique triangles, one pigment material
and one embedded 1536×1024 atlas. Repeated bench/basket placements bring the new
prop geometry to 42,688 triangles, plus existing painted foliage cards. The three
local practicals coincide with physical reading/task fixtures. The existing
layout, WALK, cameras and simulation are unchanged.

Checks: review loader 31/0; actual placement, sampled capsule/return paths,
route-end approaches and unchanged Commons thresholds 44/0; six independent
CPU/pixel pole cases with the furniture installed pass (maximum 0.103 px,
unchanged 0.75 px limit). Export-filter and UID guards pass. Independent review
found no visual publication blocker; see `independent-review.md` for its scope.

Arcade-approach frames remain in the court: piers and framing limit their
evidence for the bay interior/counter/cart. They do not certify that interior's
finished appearance. Upper magenta finds and unfinished structural shapes remain
greybox. The native download on the page is still the earlier S3 layout build,
without this review-only furniture.

Editable v2 sources are preserved locally in
`build/commons-lived-in-source/commons-lived-in-source-v2.tar.gz`, SHA256
`311212706db908e0f60126f9b7fe77bbf8800fb680b0f823179ea8c30f7e3c81`.
The original authoring workspace and v1 archive remain intact. This new source
archive has not been uploaded.
