# Sprint sequence: ship lighting and Solar System departure

**Status:** Approved by Mark, attended 5 October 2026: “ok sounds good - pick what is easiest for you to work with”; lighting is central to the feel. [Design](m4-ship-lighting-and-solar-departure.md). Choose A, painted 3D with real lighting and free camera; matched captures remain an art review, not a blocker to making the first pass. Do not duplicate the approved [M5 sprint](m5-planets-sprint.md).

**Goal:** one atmospheric, navigable ship with a measured Solar System departure into an actual interstellar journey. Ship geometry remains the seven-tier Blender assembly. Faster movement and map correction ship first; artwork/camera decisions are reviewed before substantial production.

## Capacity and sequence

Recent work delivered Commons architecture, live journey, UV bridge and exact-ID inspection in successive small increments. The latest source/evidence integration alone changed 747 lines; producer regenerations and binary art assets make raw git LOC an unreliable calendar predictor. The existing M5 estimate was calibrated at 1.6×. This continuation therefore budgets **2,400 code/test lines**, plus **30% contingency**, and separately budgets Blender/lighting iteration. Expect roughly **10–16 focused implementation/review sessions**, rather than a fixed one-session promise; the camera decision, remaining M5 physics and actual Air measurement can extend that. A focused session is a reviewed work block, not an unattended loop commitment.

| ID | Increment | Code/test LOC | Dependencies | Example files / commands |
|---|---|---:|---|---|
| SD1 | Faster walk and ship-origin map | 220 | dev.10 | `demos/ship_geometry_demo.gd`, `ui/galaxy_map.gd`, `tests/test_map_origin.gd`, `tests/test_ship_movement.gd`; `make ui map-origin-test ship-movement-test` |
| SD2 | Matched lighting/camera comparison | 300 | SD1 | `demos/ship_lighting.gd`, `tools/ship_lighting_capture.gd`, `art/ship-lighting-v1/`; `make ship-lighting-test ship-lighting-capture` |
| SD3 | Selected moody viewpoint finish | 280 | SD2 + Mark image review | measured camera profile, packed Blender pigments/light manifest, `demos/ship_geometry_demo.gd`; existing camera/SI gates |
| SD4 | Earth/Sun/planet renderer in ship view | 220 | SD3 + completed M5 foundations | `interior/interior_sky.gd`, `planets/system_view.gd`, `tests/test_ship_planets.gd`; `make ship-planets-test golden-m5` |
| SD5 | Saturn/radiometry readiness | 480 | SD4; remaining M5.2b/M5.4 | approved M5 ring/atmosphere/meter/package files, golden fixtures; `make golden-m5` with extended M5 cases |
| SD6 | Physical Earth/Jupiter/Saturn itinerary | 380 | SD5; M5.5b/M5.6 navigation work as required | `sim/solar_departure.ail`, existing M5 system planning, `tests/test_solar_departure.gd`; `make solar-departure-test` |
| SD7 | Outbound acceleration and flyby presentation | 340 | SD6; M5.3/M5.6b readiness | current journey host plus approved M5 apparent-disc/pacing work, `tools/solar_departure_capture.gd`; `make solar-departure-capture golden golden-m5` |
| SD8 | Coverage, independent review and delivery | 180 | initial coverage after SD1; final gates after SD7 | coverage metadata/UI, `tests/test_catalogue_coverage.gd`, art/gallery/docs/build; `make catalogue-coverage-test test` and native export/deployment gates |
| | Total | **2,400** | | |

LOC includes tests and selected existing M5 completion work; do not add these estimates on top of identical M5 milestones. SD5–7 are integration buckets, and may be split into <=400-line implementation milestones during execution if package/renderer changes expand. SD5's 480 lines should execute as two bounded parts (ring/shadow support and metering/illumination verification). Package source changes occur only in the established package workflow, with pinned releases and independent checks.

## Session-sized work

1. **SD1:** increase traversal speed to 3.5 m/s; capture time/distance and collision behavior. Audit all map origins/framing and A→B→C route lifecycle; add Centre on ship/Fit journey. Publish this useful small increment independently.
2. **SD2:** same-pose lighting comparison at bridge outward/inward/overlook and Commons interior/arrival, keeping 4× sky state constant. Produce free-camera and near-fixed-camera 3D versions; retain old plate only as labelled reference. Tune ash-gray floor/readable face values, key/fill/practical lighting and physically meaningful spire shadows. Profile the shadow cost.
3. **Art review:** Mark delegated the camera choice; A is selected. Continue the painted 3D lighting pass and keep matched captures available for finish feedback. Keep the old captured reference for fidelity review. A later C/plate fallback would require a separately bounded camera/depth plan.
4. **SD4:** connect existing planet renderer/system state to the unified observer, with near-Earth physical start and tested angular sizes. Release a first near-Earth view while the outer tour remains under construction.
5. **SD5–6:** reuse/complete M5 rings, illumination/meter and target/navigation prerequisites; build successive Earth→Jupiter→Saturn legs with real epoch, closest approach and allowed turns. Never move planetary positions for composition.
6. **SD7:** outbound destination and continuous acceleration/cruise/braking; pacing changes real-time presentation only, with both clocks and compression shown. High-speed near-planet mode remains disabled until M5 apparent-disc/relativity goldens pass.
7. **SD8:** coverage legend can ship with SD1; finish capture evidence, independent evaluator, paired profiling, packaged native click/nav/normal startup, downloaded checksum and website verification. Keep actual Air signoff pending until measured, and later ship levels unfinished.

## Acceptance and ownership

Use the design's command-based acceptance table. Tests should verify observable behavior, real input and physical/reference values; do not add tests merely mirroring a speed constant. Movement/camera changes must preserve lift, map and I-click interactions. Map recentering must not emit a sim reset. Lighting comparison records model/material hashes, observer/FOV, light sources and sky state. Solar captures must disclose any visual approximation and the exact sim itinerary.

Executor owns code/authoring; a different evaluator checks behavior, geometry/photometry, actual opened images and the packaged app. The first draft build can ship SD1 alone. Continue using PR117/current install channel and the single reference website. Art deliverables remain editable Blender masters plus source maps; plate production is conditional on the camera review.

## Explicit pending decisions

- The plan is approved and camera A is selected. Matched images remain available for lighting and finish feedback.
- Actual M2 Air shadow/planet resource measurements. Studio results cannot approve these on behalf of the laptop.

No new large catalogue import, fictional star generator, whole-ship buildout, population/life-support certification, GR lensing or travel glow is included. Record those separately on the roadmap. Reaching beyond the present destination/sky fidelity envelope requires a later data/background milestone.
