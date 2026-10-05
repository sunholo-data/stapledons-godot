# Unified ship: lighting, navigation and Solar System departure

| Pillar | Alignment | Reason |
|---|---:|---|
| Choices Are Final | +1 | Real route legs retain the existing commitment rules; the demo never silently resets the ship to Sol. |
| The Game Doesn't Judge | +1 | Measured, missing and fictional information stay distinguishable. |
| Time Has Emotional Weight | +2 | Leaving familiar planets leads into visible acceleration and diverging clocks. |
| The Ship Is Home | +2 | Faster movement and atmospheric, readable ship interiors support inhabiting the ship. |
| Grounded Strangeness | +2 | Measured geometry, real catalogue stars and package-owned physics govern the scene. |
| We Are Not Built For This | 0 | No new crew/psychology mechanic in this bounded visual/navigation work. |

Net +8: aligned. Use the Game Vision Designer pillar review; no vision change is required.

**Status:** Approved by Mark, attended 5 October 2026. Mark delegated the camera choice and emphasised lighting as central to the game feel. Select A: painted 3D geometry with real lighting and free camera. Captures remain a finish review; no switch to fixed views is planned.
**Release:** R1; continuation of the current unified ship and approved M5 planets sprint.
**Priority:** movement/map first; lighting comparison before extensive painting; Solar System departure next.
**Implements:** [journey system](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase3-gameplay/journey-system.md), [relativity spec](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md), [Higgs bubble](https://github.com/sunholo-data/stapledons-design/blob/main/physics/higgs-bubble.md), game [M5 planets design](m5-planets.md) and [approved sprint](m5-planets-sprint.md).
**Depends on:** dev.10 frozen source ec34d58, measured seven-tier assembly, real catalogue identity, existing AILANG journey core and completed M5 foundations. Execution follows CLAUDE.md's approved sprint and independent evaluation cycle.
**Estimated scope:** 2,400 implementation/test lines for this integration, including selected remaining M5 work rather than a duplicate planet implementation. Art/render iterations are estimated separately; see the sprint. No production merge is included.

## Verified starting point

- One default playable ship: bridge, first Commons arcade/plaza, lift, captain-eye perspective, Option-drag, optional labelled third-person zoom, native I-star inspection and live M navigation. Seven major tiers, 200 m bubble, 95 m lower inner envelope, minimum 5 m clearance remain settled. Other districts stay coarse/unopened.
- Current walking displacement in `demos/ship_geometry_demo.gd` is 2.2 m/s. Collision follows the authored walk meshes.
- The current bridge has real UV pigments on unchanged Blender geometry. Its earlier orthographic painted plate remains an art reference. The new pigments contain no projected plate or baked directional shadow pass.
- Current ship lighting is prototype ambient energy 0.65 plus fixed key/fill directional energies 1.3/0.65, with cast shadows not enabled. This is why the new model does not reproduce the old image's moody lighting; 3D geometry itself is not the obstacle.
- Map simulation plans from `position(ship)`. However, `frame_star` centres Sol and the target; the dashed selection line starts at Vector3.ZERO. The ship marker is gated on journey state. Audit selection, plan preview, commitment, transit, arrival, second departure and exact-ID star-card handoff together.
- Destination catalogue: 5,685 entries within 25 pc (81.54 ly). Point-star rendering uses additional real catalogues; it is a different coverage layer from selectable destinations. The current distant panorama has an acknowledged roughly 50 ly-from-Sol applicability limit.
- M5 state confirms orbits/light packages, data, system protocol, planet globes/textures and body-target intercept foundations pass. Rings/atmosphere, highlight metering, gravity/tour, fast flyby, system UI and transit presentation remain unfinished. `InteriorSky` currently has no `SystemView`; planets are not visible in the unified ship merely because textures are bundled.

## Goals

1. Walk around the existing spaces faster, without changing scale, collision, lift safety or simulation time.
2. Make navigation explain the actual current location and journey rather than appearing to restart at Earth.
3. Restore the moody painted atmosphere, with correct visibility and moving-light shadows, after a matched visual comparison.
4. Show a real Earth → Jupiter → Saturn departure and then interstellar acceleration from the same ship, with leg changes and clocks explained.
5. Keep the real star catalogue as the navigable foundation; show coverage and missing knowledge honestly.
6. Deliver incremental playable updates to the same installer/reference page; keep editable Blender masters and captured art decisions.

## Viewpoint and art decision

Blender remains the dimensional source in every option. Lighting does not require abandoning painted 3D assets. Compare the same model, pigment palette, captain position, physical sky state and output resolution:

| Candidate | What it permits | Main cost/limit |
|---|---|---|
| A: painted 3D surfaces with moody realtime lighting | Walking, looking around, downward views and lift travel; geometry and sky share one camera | More lighting/material tuning and GPU shadow cost; detailed illustrative ink requires additional art work |
| B: near-fixed camera using the same 3D model and lighting | Limited yaw/pitch at a measured eye; easier art composition and stable shadow quality | Less camera freedom; camera switches/rail movement need explicit design |
| C: Blender-derived painted plate with depth/masks | Strong authored composition and baked internal atmosphere at specific stations | Per-view painting and occlusion work; external moving shadows need separable passes; the old orthographic plate cannot be paired with an arbitrary perspective sky |

**Recommendation:** first tune A, then compare A and B in actual game captures against the approved original plate. C is a documented fallback, not the default or a requirement to repaint every level now. Preserve measured eye height and a shared observer in any player-facing option. External orbit/pullback remains diagnostic or explicitly third-person.

Use standing bridge outward/inward/overlook, Commons arcade interior and lift arrival for the comparison. Show at-rest near-Sun and dark-travel lighting separately. If B/C is selected, record the exact camera envelope, reachable stations, permitted pan/zoom and occlusion limits before authoring more plates. Do not present an off-ship concept perspective as a physically reachable view.

## Lighting design

- Retain pigments/brush grain and restrained crevice/material shading in the painted textures. Do not paint a permanent broad spire shadow into base colour when the illuminating Sun can move.
- Separate internal architectural lights from external illumination. Internal practical lights provide the ship's moody atmosphere even in deep space; painted static internal shading is allowed only where its light/geometry is genuinely fixed and recorded.
- Spire/building cast shadows follow the active light and actual geometry. Test underside, rails and foliage for correct occlusion. Begin with bounded shadow distance/quality and coarse distant casters for the M2 Air; add shadow quality controls only if performance evidence needs them.
- Near Sol, external light direction and intensity must come from the simulation/package system fields and a documented conversion into the renderer. Do not orient the Sun or spire shadow to the camera. Verify conventions against existing celestial/reflected-light specs; if ship illumination needs an absent formula, specify/test/publish it in the package first.
- At relativistic speeds, external illumination must follow the audited photon conventions. Keep decorative interior lights separate. Do not derive a new SR illumination approximation solely in GDScript.
- Keep current 4× sky exposure as the labelled display aid. Material/ship lighting tuning must not silently alter sky photometry. No travel glow, bubble amplification or GR lensing is introduced by this plan.

## Faster movement and map

Trial default movement at **3.5 m/s**, up from 2.2 (about 59% faster). It is a brisk game traversal speed, not a claim about ordinary human walking. Retain normalized diagonal movement. Verify walk boundaries, ramp approaches and lift arrival at the faster speed; subdivide movement only if collision evidence requires it. No sprint mechanic is needed initially.

Map improvements:

- Draw proposed route from current ship position; committed route from the plan's recorded departure to destination, with the moving ship marker on it.
- Show ship marker at rest, during travel and after arrival. Label departure/current system and distinguish the selected destination.
- Add **Centre on ship** and **Fit journey**. Fit ship/departure/destination as appropriate; preserve manual pan until the player requests framing. Sol remains a fixed astronomical reference, not the camera centre or forced origin.
- Audit re-opening M, star-card Open in map, target changes before commitment, and A→B→C journeys. No hidden `new_game` or clock/ship reset during recentering.

## Solar System departure

Reuse the approved M5 foundations and remaining milestones. Build one coherent route reviewed from the current bridge:

1. Near-Earth start: choose an explicit epoch and reachable standoff from real ephemeris data. Earth, Moon and Sun have correct positions, scale, lighting and exposure. Ship-eye viewpoint is the same observer as the sky.
2. Earth → Jupiter → Saturn: successive physical legs/encounters. These bodies will not generally lie on one straight line. Use moving-target intercept, safe closest approach and existing commitment semantics. Do not drag planets into alignment or invent screen-sized discs.
3. Saturn showcase: finish the relevant M5 rings/shadows support before claiming a Saturn flyby is ready. Atmosphere/meters and planet/star point-to-disc continuity remain package-tested.
4. Outbound interstellar leg: turn/accelerate toward the selected real destination. Reuse stable-heading acceleration/cruise/braking and both clocks. No velocity reset or arbitrary change of travel direction mid-leg disguised as a continuous journey.

Two useful presentations: a **single labelled demo itinerary** to experience the departure, and normal map planning when the M5 system-map work is ready. Both use the same simulation and renderers. A demo may automatically advance its itinerary only within an explicitly disclosed demo mode; normal play retains irreversible commitments. Itinerary sequencing must follow allowed stop/turn transitions; a continuously curved high-speed tour is not implied by the current straight-leg planner.

Pacing uses labelled time compression, not altered distances, planet sizes or acceleration. Slow presentation near encounters and show the faster outbound sky. Finish/verify fast apparent-disc rendering before enabling high-beta close planetary passes; initial local passes can use audited low speeds while outbound SR sky remains active. No fake continuous high-speed flyby is accepted as a placeholder.

## Catalogue and exploration boundaries

- Initial playable destinations remain real catalogue entries in the present local volume. Add a compact map legend for destination coverage, point-star coverage and distant-background limitations; do not render a hard sphere as if space ends there.
- A system can be catalogued while its planets are unknown. Label measured star facts, confirmed/candidate planets, unavailable measurements and authored fictional content separately, with provenance. Unknown never means physically absent.
- Expansion beyond 25 pc is a later data milestone using real GCNS/Gaia/Hipparcos sources and quality cuts. Recentring is a coordinate/view operation; it does not fabricate new measured catalogue rows around the ship.
- Before promoting long-distance destinations, resolve the panorama's parallax limitation or visibly declare the approximation. The departure demonstration can use a nearby destination within the present fidelity envelope, e.g. Alpha Centauri, without claiming an all-Galaxy renderer.
- No invented stars or procedural star-field replacement is needed for this release. Procedural planets/settlements, if later desired, require explicit fictional status and a separate content decision.

## Acceptance and review gates

New command names below are planned deliverables, not claims that they already exist. Use `AILANG=runtime/bin/ailang` throughout.

| Requirement | Verification command/evidence |
|---|---|
| Faster traversal retains geometry/collision/lift safety | `make ship-demo-input-test ship-demo-lift-test ship-movement-test` (new movement gate) |
| Route/framing/marker use actual departure; A→B→C never resets | `make ui map-origin-test` (new map gate) plus captured second departure |
| Mood comparison uses identical measured poses/sky, real cast shadows and external direction | `make ship-lighting-test ship-lighting-capture` (new) with opened A/B images and pose/light manifests |
| Selected camera mode preserves sky/ship eye and star inspection | `make ship-demo-consolidation-test ship-star-identification-test ship-star-identification-capture` |
| Planets share ship observer and correct real distances/angular sizes | `make planets-test golden-m5 ship-planets-test` (new integration gate); package reference cases |
| Jupiter/Saturn encounters and outbound state are continuous and package driven | Existing M5 gates plus new `make solar-departure-test solar-departure-capture`; deterministic itinerary and both clocks |
| Coverage/unknown status has provenance; no fabricated measurements | New `make catalogue-coverage-test` and existing catalogue verification targets |
| Physics/precision/regression pass | `make test golden golden-m5`; changed package quality/publish gates; GPU images opened by separate evaluator |
| Laptop resources and one published playable entry | Paired native baseline/enabled profiling at 1920×1080; actual M2 Air result pending until measured; empty-PATH native export tests, downloaded ZIP checksum and deployed page/model verification |

Do not broaden full-suite reruns without source/physics changes or unresolved failures. Each meaningful physics visual needs package reference, CPU/GPU golden and inspected captures. Generator and evaluator must differ. Each completed increment updates the existing review page, progress gallery, art folder and draft PR; no second competing demo link.

## Risks and boundaries

The art choice is the main uncertainty; measure first rather than commit the whole ship to plates. Shadows add GPU cost; quality/LOD must be measured on the Air. Planetary photography/geometry must retain licences and real scale. The already approved M5 sprint owns celestial/relativistic changes; this plan integrates and reprioritises it without asserting unfinished milestones are done. A Solar System itinerary is several reviewed increments, not an overnight completion of every tier or planet feature.

## Decision points and deliverables

Approved defaults: 3.5 m/s movement; painted 3D geometry with real lighting and free camera; matched baseline/moody comparisons for art review; nearest-star outbound demo; real destinations and explicit unknown information. Mark reviews finish captures; a future switch to constrained cameras/plates would be a separate decision.

Deliverables: sprint/state files; movement/map update; lighting comparison and recorded camera decision; integrated Earth/Jupiter/Saturn/outbound demo; coverage legend; Blender assets and native art evidence; independent evaluations; one verified Mac review build and lean reference-page updates per playable increment.
