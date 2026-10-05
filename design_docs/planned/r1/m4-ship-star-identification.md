# M4: identify known stars from aboard ship

| Pillar | Score | Evidence |
|---|---:|---|
| Choices Are Final | +1 | Inspecting is read-only; map commitment retains its hold ritual. |
| The Game Doesn’t Judge | +1 | Catalogue facts and missing-data labels, without invented conclusions. |
| Time Has Emotional Weight | +1 | Identify the same source while the actual moving sky changes around it. |
| The Ship Is Home | +2 | Learn about destinations directly from the captain’s ship viewpoint. |
| Grounded Strangeness | +2 | Highlights follow rendered apparent directions and known identities. |
| We Are Not Built For This | 0 | No new crew or psychological mechanics. |

**Status:** Planned, awaiting approval of bounded sprint. **Release:** R1. **Priority:** high.
**Requested:** Mark,5October2026: hotkey/click sky stars for existing map information; highlight only stars with available information.
**Implements:** [Journey planning](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/journey-planning-ui.md), [SR source-direction and observer rules](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md#2-special-relativity-moving-observer-flat-space).
**Depends on:** ship geometry review/live journey, current sky tiers and stable map catalogue IDs. **Estimate:**450–650implementation/test LOC, two focused sessions plus independent evaluation/export. Pillar net+7: aligned, go to planning.

## Problem and inspected evidence

The ship renders physical sky stars but has no star inspection interaction. `GalaxyMap` has a stable ID/name lookup and catalogue fields. Its current `stars.json` contains5685 records within25pc; this is a catalogue boundary, not a full-galaxy knowledge model. Missing photometry can keep a catalogue row out of the rendered sky. Sky binary rows have no per-row identity in their six-field position/temperature/magnitude/flags format; `Starfield` filters and combines tiers. Never assume map index equals renderer index, or identify stars by nearest position. The map’s geometric picker cannot be directly used for the relativistically aberrated sky.

## Proposed interaction

- Hold **I** to identify. Display subtle unfilled rings for visible rendered stars with an exact known catalogue record. No physical star brightness changes; rings are a labelled navigation overlay.
- Hover a ring to show its name, or catalogue ID when unnamed. **Left-click** opens a compact card. ReleaseI hides rings; the card remains. **Esc** closes the card before existing quit behavior. **Close** also works on trackpads.
- Card uses existing common name, ID, catalogue temperature/magnitude where present, and explicitly labelled catalogue distance fromSol. Do not relabel that distance as current distance fromship. Missing values say unavailable. No invented planets, civilizations or spectral classifications.
- Card offers **Open in map**, selecting the same exact ID. Planning/commit stays in the existing map; inspecting does not emit plan/commit, pause clocks or alter the voyage.
- Nearby overlapping hit regions offer a small candidate list with names/IDs, not arbitrary nearest selection. Limit clutter by grouping screen-space overlaps and naming only hover/selected candidates; grouped stars remain individually accessible.
- Option-drag remains look; right-drag remains look; scrolling remains zoom. AnI-click is consumed by identification, not walking or map input. Suppress identification while navigation/modal UI is open or benchmark capture is running. Clear held-key state on focus loss.

## Technical approach and bounded scope

1. Establish an exact renderer-row→catalogue-ID mapping. Prefer an AILANG-produced companion identity sidecar pinned to each tier’s binary hash and row count, retaining the binary layout. Carry IDs through filtering/tier stacking. Reuse existing catalogue producer identity if available; verify that before writing a new producer. Refuse stale/ambiguous identity instead of guessing. Only IDs present in the current map knowledge catalogue are eligible; faint background layers and unmapped stars are not interactive. A future discovery system can replace this eligibility predicate.
2. Project eligible active rendered stars using the same float64 rebase, `SkyFrame`, simulation velocity/gamma/one-minus-beta, camera rotation/projection and render visibility conditions as the audited starfield. Reuse the package-backed relativity mirrors; if a stable explicit-state projection helper is needed, keep it tested against existing package/spec/GPU behavior. Do not compute physics in a second unaudited picker or recompute1-beta nearc.
3. Test opaque geometry visibility from the current captain eye in ship metres along the apparent ray. Use actual visible opaque meshes/depth or equivalent occlusion evidence, including meshes without colliders. Collision-ray-only rejection is insufficient. Rings must not reveal stars through floor, rail, spire, arcade, buildings or offscreen/behind-camera stars. Camera-only turning must not change velocity heading. Unresolved point-source blends yield the candidate list.
4. Extract a shared read-only catalogue presentation component for map and ship card; never instantiate a second simulation merely to inspect data. Reuse existing map-selection/navigation session for the explicit Open in map action. Integrate first in the current draft ship demo, then the production interior using the same component after review.
5. Update only eligible onscreen overlay candidates whileI is held or a source is selected. Budget measured separately from baseline atrest and0.99c; avoid per-frame scanning of the entire324k tier. Retain native laptop viewport sizing and a cached identity/metadata lookup.

Non-goals: complete research/discovery gameplay, remote object simulation, GR lensing, catalogue expansion, new travel equations, detailed planet facts or direct sky-click commitment.

## Acceptance criteria (new targets to be added by executor)

| ID | Evidence / command |
|---|---|
| SI1: exact IDs survive filtering/tier stacking; stale hash/count, duplicates and absent metadata refuse eligibility | `make ship-star-identification-test` |
| SI2: hold/release/focus loss, trackpad click, look/zoom, modal gating, Esc-first close, no plan/commit or clock pause | `make ship-star-identification-test ui ship-demo-ci` |
| SI3: overlay centres match actual rendered stars atrest and0.99c forward/side/aft, pan/tilt/FOV/resize and nearby-source rebases; all boost/brake states stay aligned | `make ship-star-identification-capture golden` (GPU image comparison, target <=1px for resolvable sources at1920×1080) |
| SI4: no highlight/click through actual opaque floor/rail/core/arcade, even non-collision geometry; behind/offscreen excluded; close blends individually selectable | `make ship-star-identification-test ship-star-identification-capture` |
| SI5: factual card matches map by exact ID; unavailable data labelled; Open in map preselects same star without commitment | `make ship-star-identification-test` plus native1280×800/900×600 captures |
| SI6: identity sidecars staged/verified in bundled app; native heldI-click opens card without developer runtime | `make ship-star-identification-export-smoke` after `make export-macos` |
| SI7: incremental overlay work measured at1920×1080 baseline/on rest/cruise; target <=2ms p95 extra with candidate count recorded | `make ship-star-identification-bench` onStudio; actual M2Air signoff pending |

## Risks, milestones and deliverables

Identity plumbing and apparent-ray occlusion are the main work; a plain2D ring over a rest-frame map point would be incorrect. Dense forward star cones need grouping and stable hover hysteresis. Blackbody/render culling must not produce rings around invisible sources. Catalogued versus observed facts must remain visibly distinct.

Milestones: SI-A exact identity/metadata (150–220LOC); SI-B apparent projection/occlusion/input/card (200–280LOC); SI-C meaningful GPU/native tests, benchmark, independent review and demo publication (100–150LOC). Existing journey/sky behavior must remain green. Deliverables: shared lookup/card, overlay, hash-pinned identity mapping, tests/captures, documented controls and next reviewed dev build. No implementation begun in this planning step.

## Proposed defaults for approval

HoldI+left-click; persistent card after release; overlap candidate list; current map knowledge is eligibility; inspection leaves voyage running; only explicit Open in map can enter planning. These are proposed defaults, not recorded user rulings on the key or card design.
