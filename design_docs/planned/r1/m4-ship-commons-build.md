# Ship architecture: first Commons build

**Status:** Approved by Mark, 2026-10-04; execution started.
**Release / milestone:** r1 / M4 art and spatial review, extending the separate ship demo.
**Priority:** Prove multi-angle painted architecture before populating seven tiers.
**Implements:** [interior brief](https://github.com/sunholo-data/stapledons-design/blob/main/art/ship-interior-blender-brief.md), [art bible](https://github.com/sunholo-data/stapledons-design/blob/main/art/README.md), [ship exploration](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase2-core-views/ship-exploration.md). D-34/D-35 and the approved shared-observer clarification supersede the brief's older deck count and independent plate parallax. Existing physics remains governed by the [relativity spec](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md).
**Depends on:** `demo/ship-geometry-seven` at `540d7bb`; `art/ship-demo-v1/ship_geometry_demo_v1.blend`; measured seven-tier layout; `art/ship-tier-concepts-v1`; Blender workspace AGENTS/workflow.
**Estimate:** 1,050 authoring/export/integration/check lines, excluding generated meshes; 3–5 focused work/review sessions. No full-ship completion estimate implied.

## Game vision alignment

| Pillar | Score | Reason |
|---|---:|---|
| Choices Are Final | 0 | Separate art demo, no voyage decisions changed |
| The Game Doesn't Judge | 0 | Shared public space, no new status/caste policy |
| Time Has Emotional Weight | 0 | No demographic or clock changes |
| The Ship Is Home | +2 | A recognizable place to arrive, meet and dwell |
| Grounded Strangeness | +2 | Measured architecture and reachable observer positions |
| We Are Not Built For This | 0 | Does not claim that spaciousness solves voyage psychology |
| **Net** | **+4** | **Go for a bounded first architectural area** |

## Problem and evidence

The editable master contains seven slabs, the actual bridge and guarded lift, but no finished lower-tier architecture. Concepts establish mood; several show outside observers, enlarged spires or invented glass domes. They cannot establish player sightlines. The approved painted bridge is a fixed-view plate; it cannot supply unseen surfaces when a camera turns or descends. The current free-angle demo uses native materials and has not passed laptop performance signoff. The recorded Studio baseline also misses the proposed 16.67 ms p95 target; adding detail requires profiling, not extrapolating from GLB size.

## Goals and scope

First build: Commons at Z +57 m, one 6–10 m tall civic pavilion, a modest courtyard with seating/planters, Archive approach adjacent to the inaccessible spire, and a walkable connection to the existing lift. Use a bounded approximately 20 × 30 m review area near the landing; survey its exact footprint against current guards/core before placing objects. Leave the rest of the Commons coarse. Include 1.7 m scale figures as reference, not new crew AI.

Make the new kit reusable across later tiers: floor trim, grown structural ribs, rail, bench, planter, wall/door opening and roof modules. Common shapes and palette unite the ship; each deck can vary its arrangement and accent colours. Validate one structural bay/attachment to the existing tier rather than inventing a fully certified structural system.

Do not populate all seven tiers, change ship dimensions, move the needle, enclose the bubble in glass, add external docks, adopt the 1,000-person scenario as canon, or implement new sky physics. Full detailed bridge retexturing is a subsequent reuse of the successful material workflow, not a prerequisite to this first Commons proof.

## Asset and paint workflow

One Blender master assembly owns coordinates and layout. Linked area/kit collections hold editable detailed assets; the game loads section exports and simpler distant/overview representations derived from the same layout. The map representation can eventually use the same silhouette with a much smaller mesh/material budget.

Start with geometry and flat palette; inspect proportions before spending effort painting. UV-map reusable modules, then add view-independent base-colour brush texture, roughness and deliberate ink details. Keep texture density consistent at human viewing distances. Test one representative rib/wall/floor kit in Godot before propagating it. Blender procedural/toon nodes are not automatically portable glTF materials: export compatible Principled/image-texture materials and bake only the required surface channels. [Blender exporter reference](https://docs.blender.org/manual/en/5.3/addons/scene_gltf2.html).

Do not bake star fields, starbow, bubble glow or a viewpoint-specific shadow into base colour. Use Godot for runtime light/outline treatment; judge the result in the actual demo, including back and side views. A generated repaint may guide palette/brushwork, but a camera render cannot be reused as a general texture without UV projection and unseen-surface work.

Provisional limits for this first kit: at most four new material slots, two 2K texture sets, and 30k additional visible triangles at local detail. These are initial caps, not measured proof of laptop suitability. Record imported texture memory, draw calls and actual triangles; reduce the caps if the first experiment warrants it. Far-detail architecture must preserve roofs, major ribs and opaque occlusion while discarding small decorations. Do not assume imported GLBs automatically receive useful LOD.

Keep collision separate from decorative geometry. Extend the Commons WALK domain into the bounded area; retain deck-specific walking so the bridge does not become the lower captain's floor. Guard inaccessible edges and preserve lift swept clearance.

## Observer and dimensional checks

Retain R=100 m bubble, lower architecture target R=95 m, and existing bridge exception. Check every new roof/rib/canopy vertex at its actual height; a floor's radius does not certify the room above it. Preserve all seven floor heights and actual spire proportions. Include human-scale door, seating and path dimensions in the manifest as design targets, not regulatory certification.

Required review cameras: reachable bridge overlook, mid-lift, Commons arrival eye and courtyard eye, plus reverse view toward bridge underside. Standing eye defaults to 1.7 m above the verified WALK surface. Check camera/capsule clearance and reachable paths for player labels. Whole-ship outside cameras remain explicitly labeled diagnostic; cutaways remain diagnostic only. Floors/roofs stay opaque in player captures. The concepts' impossible external observer positions do not dictate construction.

## Acceptance criteria

Commands below are planned interfaces, not present/passing today.

| ID | Required evidence | Command |
|---|---|---|
| CB1 | Saved scene reproducible, no missing external assets; new mesh vertices within envelope; seven floor heights/bridge unchanged; clean GLB reimport | `make validate-ship-commons`; Blender `make inspect SCENE=stapledon_ship_commons_v1` |
| CB2 | Path from lift through new area remains on Commons; collision/roof/capsule/edge checks; lift swept route remains clear | `make ship-commons-test`; existing `make ship-demo-lift-test` |
| CB3 | Five inside-observer captures and one labeled exterior diagnostic, with eye/FOV/first-hit audit; multi-angle material appearance visually reviewed | `make ship-commons-capture` plus recorded visual inspection |
| CB4 | Coarse/detailed exports share transforms and silhouette; measured texture/draw/triangle statistics and baseline/delta recorded | `make ship-commons-bench`; `make validate-ship-commons` |
| CB5 | Native M2 Air benchmark at 1920×1080 recorded before performance signoff; 16.67 ms p95 target met or explicitly left blocked | `make ship-commons-bench` on Mark's laptop |
| CB6 | Existing input/camera/lift checks green; exported app includes new area; published ZIP hash checked | `make ship-demo-ci`; `make ship-demo-export-smoke`; `make publish-dev` after checks |

Run project definition-of-done checks before production merge; this is a draft review delivery. Generator and independent evaluator differ. If the material/observer proof fails, deliver the inspected blockout and report remaining work rather than replicating the defect onto every tier.

## Subsequent ship build order

After first Commons review: complete its kit/footprint as needed, then Homes courtyard kit, Garden tree/cultivation-light kit, Workshops, Farms and Engineering. Block layouts before final paint. Each has a local playable sample and cheap background assembly, checked from the tiers above/below. Broader structural/transit/ecology design remains staged work; visual realism alone cannot establish closed-loop habitability.

## Risks and deliverables

Main risks: paint seams/repetition at close range, export losing shading, costly outlines/vegetation, new roofs obscuring expected views, and decorative collision blocking the lift. Early in-engine sample, actual view captures and measured costs address these before duplication.

Deliver editable master/linked kit, textures and hashes, detailed/coarse GLBs and separate WALK data, geometry/material manifest, player-camera captures, benchmark comparison, independent evaluation, updated review webpage and laptop build. Art review precedes any production integration.

## Approved continuation — 2026-10-04

Mark requested a brighter-star trial and further development of the current area.
Vision alignment remains +4: Ship Is Home and Grounded Strangeness. This bounded
continuation keeps the current seven-tier geometry, courtyard/WALK, lift and simulation.

Offer calibrated sky baseline, +1 stop (2×) and +2 stops (4×) via existing exposure
bias; default to labelled2× trial for review. Apply exposure to the whole sky pipeline,
not selected stars; no magnitude floor, new photons or directional compensation.
Optional16× and64× settings extend the comparison because the modest boost leaves the side view nearly black at0.99c. Strong settings can saturate forward highlights. Photometric inputs, aberration, Doppler and heading remain unchanged. This is an
explicit display aid, not a claim of naked-eye visibility or passive bubble amplification.
The geometry layer retains its existing diagnostic lighting, so no full coupled
interior/eye-adaptation realism is claimed. Compare reachable and sky-only views.

Expand the existing Commons with reusable seating, planters/low vegetation,
canopy/terrace forms and pavilion detail. Preserve capsule routes and lift clearance;
keep the kit within existing material/triangle/envelope caps and derive coarse geometry
from the same master. No new tier or flyby is part of this continuation.

Checks: `make ship-demo-journey-test` verifies exposure ratios, baseline restoration,
state/heading invariance and benchmark lock; `make golden` checks calibrated rendering;
`make ship-demo-ci` checks navigation/assets/envelope; native reference captures prove
baseline/2×/4× appearance and multi-angle Commons quality; packaged smokes and ZIP
hash precede the next draft release. Actual Air profiling remains pending.

## Review correction — approved concept, 2026-10-04

Mark confirmed the Level1 concept was approved and pointed out that the generic
barrel-roofed test pavilion does not match it. Treat its architectural character
as the target: sweeping terraces, open curved arcades, planted promenades, civic
plazas and warm inhabited spaces. Preserve the measured bridge/spire and sphere;
the concept's enlarged core/illustrative sky are not geometric changes.

Before further architecture, agree a whole-Common circulation/zoning plan, then
block one representative arcade/plaza section. Do not spend another full art pass
refining the current generic pavilion as though it were the accepted design.
The current pavilion remains a historic working test, not approved final architecture.
The new bridge-style paintover is a finish study only; it is not a UV-textured asset.

Mark selected4× sky exposure for the review default; physics inputs stay unchanged.

### Review publication, 2026-10-04

- Published native build `v0.4.0-dev.8-commons-review-4x`, source
  `6e613a9d384bcc5558ab6859dc2596dba4832dd2`; default exposure 4×.
- Archive checksum `3394468b430671341752a5403b88869d86ebff36429443f61ff8e757783f8660`;
  latest manifest verified, ZIP integrity passed, focused journey checks 47/47
  and packaged ship smoke passed. No geometry or physics changes in this update.
- Review page source `cee12ee`, Pages publication `8f3c22f`: approved concept,
  unbuilt measured zoning proposal and finish-only paintover shown separately.
- Next: Mark reviews the proposed Commons circulation and use zones. Develop one
  representative open arcade/plaza section matching the approved concept after
  layout agreement. No replacement architecture approval inferred.
