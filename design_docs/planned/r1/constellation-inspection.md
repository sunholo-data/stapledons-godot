# Constellations in the I inspection view

| Pillar | Relevance | Score | Notes |
|---|---|---:|---|
| Choices Are Final | 0 | 0 | A read-only sky annotation issues no simulation inputs. |
| The Game Doesn't Judge | + | +1 | Familiar Earth patterns are labelled as human annotations. |
| Time Has Emotional Weight | + | +1 | Recognisable patterns change as the ship leaves its original viewpoint. |
| The Ship Is Home | + | +1 | The captain watches familiar shapes through the ship's windows. |
| Grounded Strangeness | ++ | +2 | Each endpoint follows a real catalogue star, with the renderer's aberration and position. |
| We Are Not Built For This | + | +1 | Familiar sky patterns become unfamiliar without artificially amplifying their movement. |
| Hard sci-fi authenticity (spec) | ++ | +2 | Endpoint alignment is checked against rendered stars and RS-1/RS-2. |
| **Net** | | **+8** | **Go:** a small extension of inspection, using existing physics. |

**Status:** Approved by Mark, attended 2026-10-17 (“yep continue”); implementation in progress. Created 2026-10-17 from Mark's attended request: press I to see constellations and how they distort while moving.
**Release:** r1 follow-up; the roadmap has no dedicated row yet.
**Priority:** P2, an aid to reading the existing relativistic sky.
**Implements:** [relativity specification](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md) §§1–2, 4 and 7; [R1 foundations](https://github.com/sunholo-data/stapledons-design/blob/main/roadmap/r1-foundations.md), relativistic-sky bar; [starmap data model](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase1-data-models/starmap-data-model.md), real catalogue identities; [starbow Archive entry](https://github.com/sunholo-data/stapledons-design/blob/main/lore/archive/starbow.md).
**Depends on:** existing inspection, composed ship/sky cameras, catalogue stack and `sunholo/relativity` 0.12.0. No package upgrade.
**Estimated:** ~720 LOC including authored data, tests and capture/golden tools; three milestones.
**Evidence:** code observations below are pinned to `53f5fe8`; V1–V9 record the inspection. No implementation or visual validation is claimed.

## Problem

Holding I currently draws identification rings and offers star/body cards, but no connected patterns (V1). Without familiar reference shapes, the player has little help noticing how the sky changes with motion.

The necessary SR endpoint projection already exists, including uploaded high/low position rebasing, aberration, exposure and physical-emitter replacement directions (V2). However, inspection candidates require a navigation-catalogue record (V1). The bright sky catalogue is larger and contains constellation stars outside that set (V3). Constellation membership therefore cannot be built from the current clickable candidates alone.

The shader also renders GR images that the inspection projection does not model (V4). A first version must explicitly suppress its lines during GR rather than attach them to the wrong positions.

## Goals and non-goals

While I is held, draw faint connecting lines and small names for recognisable Earth sky patterns. As velocity changes, their endpoints move with aberration; as the simulated ship position changes, they move with catalogue parallax. Camera turns and zoom reveal the same annotations from the current eye.

Start with four compact figures: Orion, Cassiopeia, Crux and the Big Dipper. Label the Big Dipper as an asterism within Ursa Major. The manifest supports adding other figures without renderer changes. Full IAU constellation boundaries, all 88 figures, artwork and multiple sky cultures are later scope.

Use the existing hold-I interaction. Releasing I or losing focus hides lines immediately. Existing rings, clicks, overlapping-source choices and cards retain their semantics. Looking around remains available through the existing pointer/look controls. Walking around the ship must not exaggerate stellar parallax: the meaningful change comes from travelling astronomical distances or changing velocity.

No proper-motion, stellar-evolution, new retarded-time or GR constellation model is introduced. The annotations follow the sky the game currently renders. Lines are a chart aid, not luminous structures in space, and their colour/opacity do not claim photometry.

## Design

### 1. Package maths, simulation and protocol

Reuse `sunholo/relativity` 0.12.0 through the established mirrors. There is no new physical formula, simulation state, intent, protocol field or package release. Gamma and one-minus-beta continue to come from the uploaded observer state. Keep high/low positions in the existing projection path; never subtract large catalogue positions in a fresh float32 `Vector3` calculation.

The simulation remains pure and deterministic. The feature's only new state is local annotation/cache state; it cannot pause, advance or plan a journey.

### 2. Authored identities, not another star catalogue

Add `data/starmap/constellations.json`: version, annotation description, four figures with stable IDs/names, endpoint records and pairs of endpoint IDs. Each endpoint stores the actual rendered catalogue identity and a human-readable source alias/evidence note. It stores no position, temperature, magnitude or fabricated distance.

Hand-author small original stick figures. Verify each named star's alias against the existing pinned HIP/CNS5 inputs and catalogue producer rules before committing the manifest. A star matched out of the HIP bright tier must resolve to its actual CNS5/Gaia sky row; `Starfield.aliases_of` only handles Gaia prefix spelling, not HIP-to-Gaia crossmatching (V5). Do not guess or choose the nearest screen point.

Validate unique figure/endpoint IDs, nonempty labels, valid distinct segment endpoints and exactly one matching physical source per endpoint in the normal loaded stack. A missing or ambiguous endpoint suppresses only its incident segments, with a diagnostic count; it never creates a substitute star. The full normal stack must resolve every endpoint of the four shipped figures. Reduced/missing-asset stacks may show partial figures.

### 3. Rendering and compositing

Add a small `ui/constellation_overlay.gd` module. Resolve the few manifest endpoints directly against `Starfield.ids`, independent of `Info.records` and inspection's eligible list. Rebuild identities on `identity_revision`; refresh apparent samples when position/rebase, replacement or observer parameters change. Camera and viewport changes always refresh screen projection.

Use `StarProjection.context`, `direction` and `visible`, including physical-emitter replacement handling. An unresolved, zero-distance, nonfinite, hidden, pinned-away or photometrically culled endpoint contributes no segment. A physical resolved-body replacement must either use its rendered apparent centre and visibility or suppress the incident segment; no annotation may attach to a hidden catalogue copy.

Project through the actual sky camera and current viewport/stretch transform. Cull behind-camera endpoints before projection; first version suppresses a segment if either endpoint is behind the camera. Clip front-facing segments to the viewport, allowing a line to enter from an off-screen endpoint. Degenerate or antipodal pairs are suppressed. Draw straight screen-space connectors between the current apparent star centres; these are chart connectors with no physical path between their endpoints. Do not interpolate a fixed Earth panorama.

Place the line layer between sky (-40) and ship geometry (-20), so hull, decks, sprites and window frames cover it naturally (V6). The overlay uses the current camera, including external/fixed views. Match that compositing order if the pending camera work lands first. Names/rings/cards remain above it. For opaque celestial discs, conservatively suppress a segment intersecting the renderer's current apparent disc footprint; use the existing package-backed apparent-disc geometry. Prefer losing a connector near a body to drawing across its surface. Transparent rings are not opaque discs.

Initial style: muted cyan, ~1 logical pixel, alpha ~0.25; labels ~12 logical pixels and lower emphasis than hover labels. Put one label beside a visible endpoint belonging to a surviving segment, suppress collisions with inspection cards/other labels, and keep it inside the viewport. Tune against actual captures. No labels for completely absent figures. The help line says “Hold I: stars, bodies and constellation guides”.

### 4. Visibility and limits

Gate the overlay on the real `held` state, the existing inspection suppression state and GR being inactive. `probe()` briefly sets `held` for hover sampling, so it must not flash or persist this overlay (V1). Hide during benchmark/console/modal suppression and after focus loss. A small I-view note says “Earth constellation guides · partial where stars are unavailable”; under GR it instead says “Constellation guides unavailable during gravitational lensing”.

At high speed, stars can leave the visible band and guides become incomplete. Preserve that limit; do not brighten stars to keep a pattern complete. If the bright tier is unavailable, report the missing endpoints without changing catalogue assets or fetching data during gameplay.

## Acceptance criteria

Commands marked **new** are deliverables, not existing passing checks.

| ID | Criterion | Command → expected |
|---|---|---|
| AC1 | Four figures resolve completely on the shipped normal catalogue stack; alias evidence recorded; malformed, missing and ambiguous IDs fail safely | **new** `make constellation-test` → manifest and source-resolution cases pass |
| AC2 | I press/release, focus loss, typing, probe-only hover and modal suppression preserve existing interaction; no simulation inputs emitted | `make ship-star-identification-test` and **new** `make constellation-test` → green |
| AC3 | Actual line endpoints agree with visible GPU star centroids to ≤0.75 px at rest, β .5/.9/.99/.999, rolled/off-axis views, translated ship positions and a rebase boundary | **new** `make constellation-golden`, included in `make golden` → each expected case present and passing |
| AC4 | RS-1/RS-2 angles and RS-Q1 culling remain correct; high-speed parameters stay finite | `godot --headless --path . --script tests/test_physics.gd`; **new** `make constellation-test` → 90° source at .9c = 25.842°, at .5c = 60° within existing tolerances |
| AC5 | No mirrored behind-camera lines, stale zoom/resize positions, lines on opaque bodies or lines through ship geometry; replacement sources do not leave orphan connectors | **new** `make constellation-test constellation-golden` → explicit hidden, clipped, occluded and replacement cases pass |
| AC6 | GR, incomplete catalogues and invisible endpoints suppress affected guides with the stated status; no synthetic endpoint appears | **new** `make constellation-test` → negative cases pass |
| AC7 | Reference renders show recognisable rest patterns and changed shapes with velocity/position, at 1280×720 and 2560×1440 | **new** `make constellation-capture` → manifest plus PNGs in `renders/constellations/`; open every image and record visual findings |
| AC8 | Feature remains inactive when I is released; held-I endpoint resolution does not scan the full catalogue per frame; warm overlay CPU p95 ≤2 ms at 1920×1080 on the Studio | **new** `make constellation-bench` → paired held/released results, sample count ≥300 and limits asserted |
| AC9 | Data/module ship in exports; existing suite remains green | `PATH=$PWD/runtime/bin:$PATH make test`; `make export-filter-audit`; **new** exported constellation smoke integrated into existing identification export smoke → green locally and CI |

## Sub-milestones and estimates

| ID | Work | LOC | Depends on |
|---|---|---:|---|
| C1 | Manifest, alias audit, source resolver and failing projection/input tests | 220 | Sprint approval |
| C2 | Overlay/compositing, occlusion, held-I integration, clipping/labels and help | 260 | C1 |
| C3 | GPU endpoint golden, captures/bench, export smoke and final evidence | 240 | C2 |

## Risks and mitigations

- **Aliases differ across tiers.** Resolve and audit stable physical identities once; reject ambiguous matches. The bright-tier spot check found only two of seven sampled Big Dipper HIP IDs there, versus seven of seven sampled Orion IDs (V7). This is a coverage observation, not a completed astronomical identification audit.
- **CPU/GPU drift or a shared mirrored frame.** GPU centroid checks supplement the package reference; retain the independent D-28 frame checks. Deliberately offset one annotation endpoint in a temporary copy to prove the golden fails.
- **Clutter and disappearing patterns.** Faint guides, collision-suppressed labels and explicit partial coverage. Keep familiar names small and hover information readable.
- **Occlusion cost.** Ship geometry masks through compositing; celestial masks are limited to the few resolved discs. Cache endpoint physics rather than scanning catalogue candidates.
- **Concurrent camera work.** Open PRs #261/#270 affect viewing/zoom. Re-read their final camera/viewport contract before wiring and test the accepted views; do not replace their key bindings (V8).
- **Physics scope.** GR guides are deliberately unavailable until a separately tested image-order-aware design exists. Fixed catalogue positions also inherit the current proper-motion limits.

## Open questions for Mark

No separate design ruling is needed. Sprint approval accepts the proposed four-figure starter set, hold-I interaction, partial visibility and GR suppression. Expanding coverage later is data work once its identities are audited.

## Deliverables

Manifest; overlay module; focused tests; golden/capture/bench tools and Makefile wiring; exported smoke; help update; changelog fragment; completed sprint/evaluation evidence. Before merge, an evaluator different from the executor checks the acceptance table, and the inspected renders are linked in the implementation report.

No canon change is proposed: the feature annotates the existing physical sky. Add a roadmap/index status only during landing; do not alter prior rulings D-17 (catalogue facts), D-28 (right-handed sky frame) or D-53 (GR demo sky policy).

## Verification log

Read at game commit `53f5fe8`, 2026-10-17. Planned commands above have not been run.

| # | Claim | Command | Result |
|---|---|---|---|
| V1 | I currently holds inspection; membership uses navigation facts; probe temporarily changes held; no constellation drawing | `cat ui/ship_star_identification.gd`; `rg -n -i constellation design_docs ui sky` | Input, focus/suppression and drawing inspected; only old catalogue-coverage prose mentions constellations |
| V2 | Existing projection mirrors rebasing/boost and replacement directions | `cat sky/star_projection.gd` | `context`, `direction`, `visible` read; no fresh physics needed |
| V3 | Larger bright tier and limited named navigation subset | `jq '{tier,count}' data/starmap/stars_bright.json`; `jq '.names|length' data/starmap/names.json`; `cat ui/star_info.gd` | Bright tier 10,713; navigation common-name rows 52; inspector ignores names outside records |
| V4 | Star shader lenses before SR; projection helper does not lens | `sed -n '1,110p' sky/starfield.gdshader`; `cat sky/star_projection.gd`; `rg -n gr_lens interior/interior_sky.gd` | Primary/secondary GR paths exist only in shader/lens path; overlay must gate on active lens |
| V5 | Existing alias helper is spelling normalisation, not cross-catalogue matching | `sed -n '149,169p' sky/starfield.gd`; `sed -n '1,80p' sim/tools/bright.ail` | Gaia prefix handling and cached index; producer reads exact HIP↔CNS5 IDs from pinned inputs |
| V6 | Separate layers can naturally mask guides with ship geometry | `rg -n '_draw_layer|identify_canvas' demos/ship_geometry_demo.gd`; `rg -n 'apparent_disc64|occludes_direction' planets/system_view.gd` | Sky -40, geometry -20, identification 11; package-backed apparent-disc geometry already used |
| V7 | Several candidate HIP aliases are not literal bright-tier identities | `jq` membership query against `.ids` in `stars_bright.json` | Big Dipper sample: HIP 54061/67301 present, 53910/58001/59774/62956/65378 absent; Orion sample 27989/24436/25336/25930/26311/26727/27366 all present |
| V8 | No open constellation PR found; camera overlap exists | `gh pr list --repo sunholo-data/stapledons-godot --json number,title,headRefName`; same for design repo | Game #261/#270 cover camera views; no constellation-titled PR; design #26 is roadmap status |
| V9 | Existing physics checks and package support cover SR; registry reuse inspected | `sed -n '1,75p' tests/test_physics.gd`; `cat sim/ailang.toml`; `runtime/bin/ailang pkg search relativity`; `runtime/bin/ailang pkg info sunholo/relativity`; `runtime/bin/ailang pkg docs sunholo/relativity` | RS angles/culling already checked; pin 0.12.0 matches registry; reuse existing optics. Initial sandbox DNS restriction cleared by read-only network escalation |
