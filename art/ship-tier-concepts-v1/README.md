# Seven-tier concepts — v1

Art-direction proposals, 2026-10-04. Seven separate built-in ImageGen frames, one for
each approved major tier. These explore furnishings, architecture, mood and palette;
they are not validated dimensional renders, textures or physics imagery. The measured
Blender assembly remains the dimensional authority. Exact prompts are in `prompts.json`.
Visual QA: the generated frames sometimes broaden the spire, suggest a glass dome and
add mezzanines. Treat these as generation drift, not approved physical changes. Retain
the measured spire, invisible bubble boundary and actual height envelope in Blender.

Review hub: https://www.sunholo.com/stapledons-godot/docs/ship-layer-reference

## Fixed geometry and canon

- Bubble radius100m, bridge floor+82m/radius22m, needle tip+98m.
- Lower tiers+57,+32,+7,-18,-43,-68m, with a95m inner floor envelope and5m clearance.
- One continuous inaccessible Higgs Generator Spire; Archive terminals adjacent.
  Lifts run beside the core, not through a newly invented habitable spire.
- +Z is up/forward. Generator supplies crew gravity. Bubble is a boundary, not a glass hull.
- Crew and mass cannot cross the bubble. Engineering cradles service internal equipment.
- Seven tiers supersede the older10–20-level proposal for this review. No twenty-deck option.
- New lower architecture is proposed, not canon. No executive caste, fixed population ceiling,
  compulsory demographic policy, reaction-mass drive layout or external docks adopted.

## Concepts and first Blender blocks

| File | Floor / diameter | Proposed content | First build and sightline check |
|---|---|---|---|
| bridge.png | +82m /44m | Decision balcony; cream/teal, violet rail, ochre consoles | Preserve actual bridge mesh and thin needle; new furnishing only. Frond roots visible. Concept spire width and sky are illustrative. |
| commons.png | +57m /151.84m | Shared civic pavilions, market, conversation courts, dining and guest rooms | Block one6–10m pavilion beside demo lift;10m roofs stay within radius67.35m. The44m bridge shelters only the centre; outer ring opens upward. |
| homes.png | +32m /178.74m | Two/three-storey courtyard homes, clinic, school, shaded neighbourhood lanes | One dwelling/court kit;10m roofs stay within radius85.21m. Keep realistic rooms and doors, closed private spaces and open communal routes. |
| garden.png | +7m /189.32m |15–20m canopy, shallow water, remembrance paths, stewards' pavilions | Test20m tree crowns within radius91.08m. Underside of+32m slab is+31m. No Earth sunshine assumed; integrate cultivation lighting. |
| workshops.png | -18m /186m | Making quarter, academy and modest homes | One public workshop and street;10m buildings under24m clear gap, with structural roots and separate transit. |
| farms.png | -43m /168.23m | Mixed staple beds, rack crops, algae and water systems | Reserve crop/aisle/service zones; use lit shelves with access clearance. Show power and water routes, not certified food capacity. |
| engineering.png | -68m /130.44m | Repair, reclamation, internal robots, power and watch alcoves | One service bay and inaccessible lower equipment volume. No boundary crossing, rocket plume or invented external dock. |

All height envelopes are checked over the WHOLE object: each vertex must satisfy
`x²+y²+z² <=95²` to preserve the proposed5m architecture buffer. This extends the
approved floor rule as a conservative build target, not a new blanket ruling for the
existing bridge needle (which remains at98m). For a straight vertical object from floor
z to z+h, its maximum radius is `sqrt(95²-max(z²,(z+h)²))`, also bounded by its actual
floor radius. Branches, roofs, ribs and supports need the same test at their heights.
24m clearance applies below the next slab where that slab exists; it is not uniform
to the perimeter. The first lower tier has additional open height outside the bridge
footprint, curtailed by the spherical boundary.

## Audit of the supplied other-agent proposal

The zoning is a useful starting scaffold and the seven gross areas are close to the
measured ideal discs: total135,633.85m² (13.563ha). Gross disc area is NOT usable room
area; holes, core, circulation, structures and service margins remain to be measured.
The quoted150–250m² core deduction and134,000m² usable total are assumptions.

The needle's16m rise above the bridge is not a ceiling. Under the100m bubble the ceiling
is18m above deck at the axis and15.55m at radius22m, before structure or any setback.
Under a95m architectural envelope, those heights are13m and10.41m instead.

Full100m sphere volume is4,188,790m³;95m sphere volume3,591,364m³. Neither is measured
breathable air volume: slabs, machinery, enclosed volumes, tanks and reserves occupy
space. Do not label deck area×24m as verified atmospheric volume or habitability.

NASA's review offers an approximate experimental yardstick of50m² of crop area per
person for dietary calories, with oxygen needs covered by about20–25m². For1,000 people
the former is roughly50,000m² of cultivated area, not22,000m² of floor. Stacking can
add crop area but power, lighting, heat, diet, water/nutrient recycling, redundancy and
failure recovery still require budgets. This does not validate a complete closed ecosystem
or a1,300–1,500-person carrying capacity.
Source: https://ntrs.nasa.gov/citations/20205008786

The inaccessible spire, generator-controlled gravity and closed mass boundary constrain
the proposal's lift core, propulsion assumptions and docks. The supplied20-deck comparison
is obsolete for this review. Canon describes an autonomous society, not an automatic
population plateau imposed by floor area; retirement does not remove a person.

## Population scenario, not a canon change

The supplied1,000 starting population is an exploration scenario. The earlier interior
brief describes roughly100 people; this concept set does not silently change that canon.
At constant ANNUAL NET growth `N(t)=1000*(1+g)^t`, after100SHIP years:

| Net rate | People after100years |
|---|---:|
|0%|1,000|
|0.3%|1,349|
|0.5%|1,647|
|1.5%|4,432|

These are arithmetic scenarios, not demographic forecasts. Age distribution, births,
deaths, migration constraints, social choices and resource budgets determine actual
growth. A plateau at1,350–1,500 must be an explicit assumption or emergent outcome;
it is not a consequence of the geometry. Resident assignments are not daily occupancy.

## Build sequence

Review the seven frames, then begin with the Commons pavilion/lift approach visible from
the bridge. Add one linked architectural kit at a time to the measured assembly. Validate
the envelope and opaque sightlines; derive simpler distant meshes and local materials.
Keep skies, starbow and boundary glow engine-generated in any game exports. Concept skies
and decorative lighting must not be treated as baked SR/GR effects.

Sources: design-repo `art/ship-interior-blender-brief.md`,
`vision/design-decisions.md` (autonomous society and inaccessible spire), approved
seven-tier measurements in `website/src/components/ShipGeometryReview/tiers.json`, and
demo branch `demo/ship-geometry-seven`.

AI-generated concept art under Sunholo art direction. No copyright is claimed (D-33).
