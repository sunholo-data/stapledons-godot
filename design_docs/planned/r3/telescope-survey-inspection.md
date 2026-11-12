# R3-TELESCOPE: the existing map, a visible telescope and one object inspector

**Status:** Planned design, 2026-11-12. Mark requested an investigation of Euclid DR1-Foundation, proposed a telescope console, then directed: “we already have a 3d map … lets add the telescope and object inspection enhancements”; he confirmed this is a non-commercial game. This records the feature direction; implementation follows the separate approved sprint plan.
**Release:** r3 · **Milestone:** new; the roadmap has no dedicated telescope-browser row yet. Extends R2-STAR-SURFACES D-111 and the existing map/inspection paths.
**Priority:** P2. Makes astronomical objects worth looking at from aboard ship; independent of R1 completion.
**Implements:**
- [Galaxy map](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase2-core-views/galaxy-map.md), object selection and detail, using the shipped Godot 3D implementation rather than that document's historical Go/2D examples.
- [Signals and instruments](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/signals-and-instruments.md) §§1, 2, 4.1, 6–7: passive observing, dated evidence and automatic discovery. This browser adds no deep-stare or lens-look commitment.
- [Galaxy beyond measurement](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/galaxy-beyond-measurement.md) §§1, 3: measured/assumed provenance, augment-only updates and data versions pinned per voyage.
- [Relativity spec](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md) §§1–2, 4 and RS-Q5: shared frames, existing live optical rendering, and stored pictures retaining their encoded colours. [Higgs-bubble](https://github.com/sunholo-data/stapledons-design/blob/main/physics/higgs-bubble.md) §§2, 7: no new bubble property.
- Ledger **D-28**, **D-41**, **D-56/D-57**, **D-111**, **D-150**: one sky frame, living measured data, information controls, the existing helm telescope and seated access to ship systems.
**Depends on:** AILANG v0.56.1; current `sunholo/celestial` 0.6.0, `sunholo/relativity` 0.12.0 and `sunholo/observe` 0.1.0; existing map, star/body cards, telescope and captain-command UI. A celestial package extension precedes any new image-coordinate maths (§T1). No new protocol minor is required for this scope.
**Estimated:** ~2,600 code/test/tool LOC plus curated data, six sub-milestones. Estimate, not a measured implementation diff; archive format and image registration need T0 evidence first.
**Evidence:** source inspection at game `f3aa83bf4120fb6f57d858129dd9bada59ed91b4` and canon `20c8a9ae86c424a2378721af90a2734a9a2157fa`. Verification log below separates inspected source, retrieved assets and untested proposals. Existing unrelated working-tree changes are outside this design.

## Game vision alignment

Scored with `game-vision-designer` in feature-validation mode against the six current pillars and the normative physics specs.

| Pillar | Relevance | Score | Mechanism |
|---|---|---:|---|
| Choices Are Final | + | +1 | Observation-pack versions are fixed for the voyage; browsing never commits, cancels or replaces a journey. |
| The Game Doesn't Judge | + | +1 | Facts carry method, uncertainty and source; no ranking, discovery score or recommended destination. |
| Time Has Emotional Weight | + | +1 | Live light age and archive observation dates are distinct; ship/home clocks continue during browsing. |
| The Ship Is Home | ++ | +2 | Navigation and the captain's chair gain a useful, image-led observing instrument. |
| Grounded Strangeness | + | +1 | Actual galaxy structure and observed lens images are labelled measured; simulated stellar patterns remain labelled modelled. |
| We Are Not Built For This | 0 | 0 | No new crew psychology mechanism is claimed. |
| Hard sci-fi authenticity (spec) | ++ | +2 | Distance-free sources stay directional; archival RGB is never represented as newly collected ship-frame light. |
| **Net** | | **+8** | **Go.** No pillar conflict and no survey-budget mechanic. |

## Problem

1. **We already have a 3D map.** `ui/galaxy_map.gd` owns catalogue selection, orbit/zoom, body stops and planning. `ShipGeometryDemo.open_identified_star` already opens that map on the exact catalogue identity (V1). A second map would duplicate working navigation.
2. **A small star-magnification popup exists in code.** `ui/telescope_view.gd` renders a finite star with the sky's material, at whole-disc/close magnification. T at the Navigation console is its coded entry point; there is no separate physical telescope station. Mark did not know this shortcut existed, and its accessibility in his installed build has not been verified. `pick_star` currently chooses the largest visible stellar disc; it has no explicit selected-object input, image-pack browser or survey catalogue (V2). Reuse the renderer and make Telescope a visible control.
3. **Inspection is split.** `StarInfo` formats catalogue distance from Sol, temperature and V magnitude. `BodyInfo` formats current ship distance, radius, apparent size, light age and inferred properties. The I card handles both and offers Open in map, but has no survey image/action (V3).
4. **Euclid is useful at a different scale.** DR1-Foundation offers images, catalogues and spectra over approximately 1,900 deg². These are observations from near Earth, not the internal 3D geometry of every galaxy or a local-star replacement (V7).
5. **The current telescope entry condition names only the helm close-up.** Captain-command now hosts systems on physical chair screens; telescope access and input must work there too (V4).

## Goals and non-goals

**Goals:** tie the existing 3D map, I card and telescope together by exact identity; retain the live stellar telescope; add a zoomable Euclid observation browser; improve shared object facts; run the shipped starter collection offline; preserve physics, navigation authority and provenance.

**Non-goals:** a new navigation map; bulk ingestion of the billion-object release; cosmological redshift-to-distance conversion; extragalactic journeys; pretending Euclid supplies resolved exoplanet surfaces; new survey budgets, exposure-time costs, discoveries or rewards; synthesis of unmeasured image detail; automatic mid-voyage catalogue refreshes. Full HiPS streaming, arbitrary sky-point live rendering and new simulated planet magnification are later work, not hidden requirements of the first slice.

## Design

Extend the helm telescope into a shared observing panel with **Live** and **Survey archive** views, opened from the existing map or inspector and hosted by Navigation at the helm or captain's chair.

### T0. A small, reproducible observation pack

Start with three useful Euclid fields: the M81 group, NGC 1291 and Abell 3128, subject to successful retrieval and coordinate registration. M81 is the first concrete candidate, not a claimed completed pack. Include a nearby live star and a body without an archive image as explicit fallback cases.

Use selected rendered images/cutouts and a bounded catalogue extract; do not download the full survey. T0 verifies an actual DR1 query or published object table, its column definitions/quality flags, and two registered zoom levels in at least one field. If the catalogue endpoint is unavailable, a documented published object table is acceptable; invented rows are test fixtures only. T0 records the actual bytes and usable object count before fixing the starter pack budget. **Execution evidence, 2026-11-12:** DR1 Abell 3128 science cutout and 40 catalogue rows retrieved; five independent empirical centroids agree within 0.369 source pixel. M81/NGC 1291/Abell colour outreach plates remain explicitly unregistered.

Tracked inputs: `data/observations/euclid_dr1/{sources.csv,objects.json,product.csv,manifest.json,registration-evidence.json,credits.md}` plus asset pins. Large images and generated tiles use the existing D-18 content-addressed asset mechanism under a new `observations/` prefix. Downloads are shell glue; AILANG validates/normalises records and builds the index; headless Godot decodes, tiles and encodes images. **Bounded transport refinement:** the documented archive cutout returns uncompressed primary float32 FITS; a tested offline Godot reader accepts only SIMPLE, two-dimensional BITPIX=-32 cutouts up to 2048², rejects other encodings/non-finite/truncated input and retains calibration. This file/image I/O is needed to use the real registered data; runtime still loads prepared tiles. No general FITS framework, arbitrary projection support, Python pipeline or Python runtime dependency is introduced.

Every image needs an authoritative WCS or explicit calibrated projection plus at least five independently checked reference positions across the field, with their source. A press-image caption and nominal field size alone are insufficient registration. An image that lacks this stays browsable as an unregistered plate, marked **Unregistered image**; it cannot paint a footprint or enable pixel-to-object picking. The starter must include at least one registered field to pass.

The manifest records release, DOI, observation epoch/date range, retrieval date, source URL, source-product identity, band/composite mapping, projection, angular sampling, footprint/mask, valid zoom levels, processing history, hashes, licence and credit. Observation date, retrieval date and release date are separate fields. Unknown values stay unknown.

**Non-commercial scope is settled by Mark.** DR1 science data's CC BY-NC 3.0 IGO terms fit that stated scope; commercial authorisation is not a prerequisite for this design. Preserve per-product terms and the DR1 credit `Data from ESA Euclid/Euclid Consortium/NASA/DR1-2026`. ESA outreach images can carry different licences and processing credits; store those individually. Mirroring or tiling an image retains its source terms. A future change to commercial distribution would require a fresh rights review, not a change imposed now (V8).

### T1. Package maths and coordinate contract

Reuse `sunholo/celestial/frames.unitFromAngles` and `equatorialToGalactic`, already used by the exoplanet importer, then the game's `SkyFrame` rotation (V5). All source astrometry stays ICRS with its epoch and units stated. Store directions/positions in float64 scalars; create float32 vectors only after normalising or rebasing for drawing.

For registered cutouts, support one explicitly declared tangent-plane projection first. Forward/inverse projection and angular separation belong in `sunholo/celestial` before a Godot mirror or shader uses them. T1 checks whether the required helpers already exist in the then-current package; reuse them if they do. Otherwise publish the additive extension with tests, CHANGELOG and quality gates, then pin the released version. Do not reserve a version number in this design. Validate corners, centre, RA wrap and near-pole fields against an independent astrometric reference; reject unsupported projection/distortion metadata instead of approximating it silently.

No cosmology formula is needed: a supplied redshift is a redshift, and a supplied distance retains the source's method and distance definition. Do not relabel luminosity/comoving distance as light age or divide it by c. A reliable derived 3D extragalactic layer needs its own cosmology design later.

### T2. Object identity, facts and simulation boundary

Add an observation index, not a replacement for the star-truth table. Its proposed object key is `{namespace, source_id}`; a selection reference also identifies `catalogue`, `body` or `survey`. Keep existing catalogue strings and body IDs unchanged. A Euclid identifier never becomes a navigation catalogue index.

| Record | Contents and rule |
|---|---|
| Object | Stable source ID, aliases, object kind/candidate status, sky direction, coordinate frame/epoch, optional documented distance/redshift, observation references. IDs stay strings, including long numerical IDs. |
| Fact | Value, unit, method (`measured`, `inferred`, `assumed`, `modelled`), source, epoch and optional uncertainty. Missing is null, never zero. |
| Association | Exact published cross-match first; explicit reviewed links next. Positional matches need an epoch-aware tolerance and ambiguity report; proximity alone cannot overwrite an identity. |
| Availability | Supported live renderer, registered archive fields, unregistered plates and maximum source resolution. It is not a statement that the object is visible to the ship now. |

AILANG owns import rules, joins, rejection reports and derived catalogue facts. Godot merges presentation references to existing sim body records and formats them; it does not create new physical measurements. Live distances/light age come from existing sim fields, archive facts from the pinned index. Proposed files: `sim/tools/observations.ail`, its tests, and `ui/object_info.gd`/`ui/observation_index.gd` as presentation adapters. Keep `StarInfo` and `BodyInfo` compatibility entry points while their cards adopt the common sections.

**Pure sim and protocol:** browsing changes only host presentation state. No new NDJSON message, physics state or session is needed. The simulation's clock and journey continue under the existing rules. A future observation that changes evidence or consumes time belongs to signals-and-instruments and must enter through a deterministic sim intent; a click on this archive cannot do that. `sim/core.ail` stays strict-bytecode clean, with existing VM/interpreter parity.

**Versioning:** when the world/session is created, retain the observation-pack version/hash in its existing host session metadata, alongside the world's pinned catalogue assets. This is a presentation asset pin, not a new simulation parameter. Define this host field in T2; no network or asset update silently replaces it. New packs become the default for new sessions. Missing pinned bytes produce an unavailable-source state rather than falling forward to another version.

### T3. Tie into the existing 3D map

- Add **Inspect** and **Telescope** beside the selected object's current detail. Catalogue stars remain at their current measured xyz; known bodies use existing sim/body links. Selecting a telescope target does not call `select`, `preselect`, `plan_body` or `plan_target` because those can queue a plan. Introduce a separate read-only observation selection and `focus_object` route; only an explicit navigation action reaches the current planning path.
- **Open in map** returns to that same exact object and restores the prior map camera/selection where appropriate. Test the round trip from a stellar card, finite body and survey object, including an in-progress/committed journey.
- Add a **Survey sky** context layer inside the same map UI: a labelled sky sphere centred on the survey observer at Sol, with field footprints and angular source markers using `SkyFrame`. Its radius is a diagram convention, labelled **Directions from Sol · depth not shown**. It has no distance rings, routes or journey controls for survey sources. Existing local stars retain their real positions in the ordinary 3D map; switching context preserves that view's camera.
- The context selection/list is the route to M81 and other out-of-range sources. Do not squeeze them into the local 400-ly camera range, invent distances, or pin them to nearby stars. Survey direction remains tied to the archive observer even after the ship travels.
- Disable plotting for all survey objects in this slice, even when a published distance exists. They remain inspectable and observable. Their type and source ID are distinct from visitable stars.

This adds context to the current map, not a second navigator. A future distance-qualified galaxy layer can reuse these identities without moving local stars or changing this direction-only contract.

### T4. Telescope panel and shared inspection

Keep the telescope within Navigation, available from its helm close-up and captain-command Navigation screen. Use the existing chair screen host and input forwarding; do not add another physical desk, command system or camera controller. **Telescope** is a visible button; T works only when not typing and while its owning Navigation view has focus. Preserve the existing whole-disc/close/off shortcut when that legacy stellar view is active. Escape returns through the containing panel's normal stack; leaving the station, standing or changing system releases input and suspends rendering.

| View | Behaviour |
|---|---|
| **Live** | Existing finite-star telescope, now with an explicit selected body ID. If no selection was requested, retain the current largest-visible-disc fallback. Copy the same material/physical uniforms, surface model, resolution gate and normaliser. A selected star that is absent/hidden shows an honest unavailable state rather than switching to another star. |
| **Survey archive** | Image dominates the panel. Pan, wheel/pinch/keys and fit-to-field; source/band picker only for real available products. Show angular scale, observation date, release and a persistent **Survey archive · observed near Earth** label. Pixels/overlay positions use the registered plate's coordinates. |
| **Unavailable** | Explain **No survey image**, **No live resolved view**, **Outside this field**, **Source file missing** or **Resolution limit** as appropriate. Retain catalogue inspection and the route back to the map. |

Live retains the actual ship-frame renderer and existing SR/GR restrictions; this scope does not implement live galaxy imaging. Archive images keep encoded pixels and recorded viewpoint at every ship speed, location and GR state. Never Doppler-tint an RGB composite or treat it as a blackbody temperature map. Archive and live overlays cannot be composited into one purported optical exposure. No artificial exposure wait, telescope-time budget or frozen simulation is added.

The shared inspector is image-led, following the standing UI direction: a thumbnail/target outline and a few primary facts, with expandable **Details** and **Sources**. Suggested primary facts are kind, size/angular extent where known, distance with its reference, and observation availability. Details separate **Catalogue**, **From the ship now** and **Survey observation**; never show catalogue V magnitude as current apparent brightness. Label simulated stellar surface structure and assumed appearances. Euclid galaxy/candidate facts retain their original class and confidence; no galaxy inherits a stellar Teff/radius template.

On an I card, **Telescope** opens or selects a read-only observation view immediately (D-56 permits information controls); it never moves the captain. Full control remains accessible at Navigation and the chair. A standalone read-only popup can host the same panel when reached from I or the M chart; it exposes no journey or time-spending controls. This uses one panel implementation and one active renderer. Returning to the helm reuses its object selection.

In the archive, clicking a catalogued source selects its registered ID, with a chooser for overlaps. Uncatalogued pixels remain image pixels. A nearby star selected on the map does not imply Euclid coverage: show the live renderer or missing-archive state instead. An angular overlap with a Euclid field is not an identity match.

**Relation to ongoing work:** PR #431's reasons-to-travel design and #433's fixture reason card concern evidence, needs, costs and finder candidates (V10). Keep their card and schema intact; object inspection can offer an observation link by object reference. This archive does not set biological evidence, reveal generated worlds or populate a finder field merely because an image exists.

### T5. Assets, limits and rendering lifecycle

Generate a rectangular mip/tile pyramid offline from each approved plate, with 512-px tiles, 1-px gutters and deterministic names/hashes. Both generation and decoding belong to Godot; manifests/indexes to AILANG. A loader draws only visible tiles and keeps a bounded LRU. Proposed starter caps: 128 MiB resident image textures, 64 MiB CPU tile cache and 100 MiB compressed downloadable pack; T0 reports whether the selected source content fits before the sprint fixes those caps. These are product budgets, not measured results.

Use recorded angular sampling to stop useful zoom; optional pixel enlargement says **Resolution limit** and adds no generated detail. Low-resolution imagery remains until the requested level is ready. Cancel/discard stale requests when selection or pack version changes. On close, render-target updates stop; caches release deterministically under their limits. No network calls on the frame path and no service dependency at runtime. The default starter pack is downloaded/pinned during build/install using the asset mechanism; missing optional content never prevents the local map or live telescope from opening.

## Acceptance criteria

Commands marked **new** are proposed implementation deliverables, not current passes. Put new gates behind `SCRIPT_GATE` with deadlines, counted success, non-zero failure and script-error rejection. Synthetic malformed inputs and coordinates are labelled fixtures. No full survey download in CI.

| ID | Check | Command |
|---|---|---|
| AC1 | At least one real registered field, two zoom levels and a real object-table extract/published table; source hashes, original columns, rights, epochs and five reference positions recorded; registration residual ≤1 source pixel | `make observation-pack-verify` (**new**, pinned small real pack; offline validation after explicit fetch) |
| AC2 | Import is byte-identical VM/interpreter; IDs retain precision; duplicate/ambiguous associations, missing values, unsupported projections and non-finite data rejected correctly | `make observation-import-test observation-import-parity` (**new**) |
| AC3 | Projection/inverse, RA wrap, poles and frame orientation agree with independent reference within 0.1 source pixel on declared supported fields; new maths published before use | `make observation-coordinate-test` (**new**; package tests plus Godot mirror); `make physics` |
| AC4 | Map ↔ telescope ↔ I-card returns exact star/body/survey ID; survey directions have no fabricated depth; opening/zooming/switching emits zero plan/commit/cancel/time intents | `make telescope-map-test` (**new**, records queue/intents; active plan and committed journey fixtures) |
| AC5 | Live selected star is honoured; an unavailable explicit target never silently switches; legacy fallback/cycle, angular magnification, copied physical uniforms and flux normaliser preserved | `make telescope-live-test` (**new**); `make star-surface-test stellar-protocol-test ship-star-identification-test free-nav-stop-test` |
| AC6 | Live SR projection/photometry retains RS-1–4, RS-Q1/Q2 and RS-24/25; touched live rendering has independent CPU/GPU checks, ≤0.75-px centroid error; archive RGB/plate coordinates unchanged across β=0,0.5,0.9,0.99,0.999 and GR state | `make telescope-golden` (**new**, new cases only locally if GPU free); `make physics`; main nightly `make golden` |
| AC7 | Same facts/provenance from all entry points; missing/candidate/inferred fields explicit; redshift and catalogue distance never become live light age or brightness; sources/credits accessible | `make object-inspection-test` (**new**) |
| AC8 | Helm, chair screens, I popup and read-only M chart: keyboard/mouse/pad, typing, pinch, focus, overlap choice, Esc and close/reopen lifecycle; no captain move/hidden render or duplicate signal; clocks keep advancing | `make telescope-ui-test telescope-map-test captain-command-test ship-console-test` (**new** first two) |
| AC9 | Offline packaged run opens registered imagery and live star; missing/corrupt/pinned-version mismatch and stale loads handled; texture/CPU/download caps enforced, including mip memory | `make observation-assets-check telescope-export-smoke telescope-cache-test` (**new**); `make export-filter-audit` |
| AC10 | Visual/layout report at 960×540, 1280×720, 2560×1440: M81 wide/detail, live Aldebaran, card from each entry, survey sphere, gaps and resolution limit; no clipping; source registration/scale visible | `make telescope-capture` (**new**, layout assertions + contact sheet); inspect all frames and obtain Mark's dev-build verdict |
| AC11 | Closed panel performs no tile decode/render updates; open panel fits declared memory caps and adds ≤2 ms p95 CPU during a warmed pan on the reference host, with cold-load stalls reported separately | `make telescope-bench` (**new**, measured baseline/open/closed report; capture host/build and load) |
| AC12 | Existing pure sim, protocol, catalogue and navigation regressions stay green; new fast tests included in the relevant tiers | `make strict parity starmap-consistency uid-guard python-guard`; `make ci-fast`; targeted gates above; nightly `make test` |

Per CLAUDE.md, a merge does not wait on a GPU or a quiet host. Add the golden cases, run those cases if the GPU is free, and otherwise use the nightly and Mark's combined dev build. Visual acceptance and publishing a review candidate remain separate. No test or render run is claimed by this design.

## Sub-milestones and estimates

| Order | Deliverable | Approx. LOC | Dependency |
|---|---|---:|---|
| T0 | Retrieve bounded real sources, rights/source ledger, registration and usable-table proof, measured pack sizes | 200 + data | None; fixes format/pack feasibility before UI execution |
| T1 | Package projection extension if needed, independent reference checks, Godot mirror | 350 | T0's actual projection |
| T2 | Deterministic AILANG index/import, identity/facts adapters and host pack pin | 500 | T0/T1 |
| T3 | Existing-map actions, read-only focus, survey context and identity round trips | 400 | T2 |
| T4 | Extend live telescope target selection; archive panel, cards and helm/chair/popup input | 700 | T2/T3 |
| T5 | Tile assets, bounded loader, export/lifecycle gates, captures and review evidence | 450 | T4; validate loader budget early with T0 sample |
| **Total** | Code, tests and tools; excludes image bytes and a full HiPS client | **2,600** | Separate sprint approval, then cross-family evaluation and visual review |

## Risks and mitigations

- **New release API/schema not exercised yet:** documentation confirms catalogue/HiPS services, but no DR1 query or scientific cutout retrieval was run in this investigation. T0 must produce the small real extract and registered zoom proof; do not equate the downloaded outreach JPEG with a working archive importer.
- **Press-image registration:** stitching/distortion may make a simple projection invalid. Admit only independently verified supported plates; use a small science cutout when needed, or leave an image unregistered. Never approximate a sky footprint from its rectangular pixels alone.
- **Map selection accidentally plans:** current `preselect` can queue `plan_intent` (V1). The new read-only route is mandatory; AC4 observes actual outgoing intents rather than testing only the visible buttons.
- **Mixed observer/epoch:** Euclid plates include foreground stars at their original Earth viewpoint. Display the whole plate as archival; never paste it into the ship's current sky or subtract catalogue stars by appearance. This avoids false parallax and new unrecoverable geometry.
- **Chair/view input ownership:** reuse current screen-host routing and shared panel lifecycle. Verify projected clicks and typing so T/pan does not leak into navigation or walking.
- **Heavy images:** tile/mip caps include decompressed GPU memory. No full plate is decoded during ordinary pan; import preprocesses it offline.
- **Unknown measurements:** no invented distance, spectrum, stellar surface or object identification fills a gap. A plotted confidence interval requires real source metadata.
- **Adjacent finder changes:** rebase onto the actual landed #431/#433 interfaces before implementation. They remain separate work and are not silently accepted by this design.
- **AILANG limitations:** no compiler/VM bug was encountered because no new pipeline code ran. If T0/T1 exposes a language/runtime gap, report its minimal repro via the standing upstream channel; do not introduce a Python pipeline workaround.

## Open questions for Mark

No blocking scope question remains from this request: telescope enhancement, object inspection, reuse of the existing 3D map and non-commercial use are settled. The following are proposed defaults for review, not requests to reconfirm those decisions:

1. **Placement:** extend Navigation at both the helm and captain's chair, with instant read-only inspection access. **Recommendation/default:** this design. A separate physical observatory station costs ship art/layout, interaction and camera work and is not included.
2. **Initial collection:** three curated fields, with a fully registered M81 field first. **Recommendation/default:** this bounded offline pack. Full survey streaming adds service availability, download/cache policy, a HiPS client and much wider integration tests; it is a later extension.

## Design-repo changes this needs

In a separate canon change, record Mark's 2026-11-12 feature direction and the non-commercial distribution scope; extend the map/ship feature descriptions with map-linked telescope inspection, Live versus Survey archive semantics and direction-only survey context. Add an R3 implementation link. Preserve the existing automatic survey, D-111 telescope, no-budget decision and D-150 chair authority. This design does not change the normative SR/GR or Higgs-bubble model and does not revive any rejected Go dome/engine direction. No canon or decision-ledger file is edited here.

## Deliverables

The later implementation delivers the observation pack and required credits; deterministic import and source audit; any published celestial projection helpers; one enhanced telescope/inspector tied to the existing map and chair; a directional survey context; bounded offline tiles; named checks above; independent evaluation and opened reference captures; Mark's combined dev-build review. This change delivers only this implementation design.

## Verification log

All source claims below are inspections, not runtime verdicts, at the two header commits. External documentation and image retrieval were checked on 2026-11-12. Scratch HTML/JPEG downloads and a throwaway standard-library HTML text-extraction harness lived under `/tmp`; none is a pipeline step or tracked file.

| # | Claim | Command/source | Result |
|---|---|---|---|
| V1 | Existing 3D map, identity handoff and plan-producing selection | Read `ui/galaxy_map.gd:1–30,535–575`; `demos/ship_geometry_demo.gd:1139–1145` | `GalaxyMap extends Node3D`; `select/preselect` use catalogue IDs, `preselect` sets `_pending=plan_intent(i)` in planning mode; existing `open_identified_star` uses it. New observation handoff must avoid this side effect. |
| V2 | Telescope already exists and chooses a finite star automatically | `cat ui/telescope_view.gd`; read `demos/ship_geometry_demo.gd:457–486`; inspect `tests/test_star_surface.gd:208–219` | 520-px own-world SubViewport, two levels, copied sky material, largest visible-disc selection, helm-only entry condition; current scale tests exist. No telescope run performed. |
| V3 | Existing star/body fact and I-card paths | Read `ui/star_info.gd`, `ui/body_info.gd`, `ui/ship_star_identification.gd:1–245` | Catalogue and live-body facts already distinguished; exact-ID/overlap and occlusion rules exist. Star/body cards expose Open in map; no survey index. |
| V4 | Chair access is a current integration surface | Read `ui/captain_command.gd:1–65`, `demos/ship_consoles.gd`; ledger D-150 and `design_docs/planned/r2/captain-command.md` | Navigation is an existing chair system; physical-screen host and input routing require reuse. Source/design inspection does not claim chair visual acceptance. |
| V5 | Shared frame maths and package pins | `cat runtime/cache/registry/sunholo/celestial/0.6.0/frames.ail`; `rg -n 'equatorialToGalactic' sim/tools/exoplanets.ail`; `cat sky/sky_frame.gd`; inspect `sim/ailang.toml:31–36` | Existing ICRS→galactic package helpers, det+1 engine rotation and stated package versions verified. Projection extension is proposed, not an existing API claim. |
| V6 | Current panorama and nearby catalogue are separate from observations | Read `sky/background.gd:14–31`, `sky/star_catalogue.gd:1–28`, `sky/starfield.gd:136–142`; existing sky reports | NOIRLab panorama plus local catalogue tiers; Euclid is an added observation dataset, with no local truth-table replacement. |
| V7 | DR1 access and scope | Retrieved [release](https://www.esa.int/articles/about-us/directorates/science/euclid/euclid-lays-the-foundation-for-its-best-ever-3d-map-of-the-universe), [access](https://www.cosmos.esa.int/web/euclid/dr1-data), [Foundation contents](https://euclid.caltech.edu/page/euclid-dr1-foundation) using public HTTP; read response bodies | Images/catalogues/spectra and ~1,900 deg²; anonymous discovery/visualisation, IVOA APIs and HiPS documented. No actual query, tile or FITS import verified. |
| V8 | Non-commercial licence and individual image terms | Retrieved [DR1 credits](https://www.cosmos.esa.int/web/euclid/dr1-data-credits) and [archive terms](https://www.cosmos.esa.int/web/esdc/terms-and-conditions); Mark's attended instruction | DR1 CC BY-NC 3.0 IGO and credits explicit. Commercial permission requirement is inapplicable to Mark's stated non-commercial scope. Outreach image terms are separate. |
| V9 | A real new image is retrievable and visually useful | Fetch JPEG linked by [M81 image page](https://www.esa.int/media/about-us/directorates/science/euclid/euclid-views-the-core-of-the-messier-81-galaxy-group); `sips -g pixelWidth -g pixelHeight /tmp/euclid-m81-sample.jpg`; open image | 3840×2160, opened and inspected; galaxies and background sources visible. Page links larger TIFF and names processing credits/licence. Scientific registration, larger TIFF and deeper tile retrieval untested. |
| V10 | Open work overlaps evidence presentation, not a telescope implementation | `gh pr list` in both repos; `gh pr view 431` and `433 --json title,body,files` | Game #431 reasons-to-travel design/plan; #433 fixture reason card, not yet map-connected per its body; #373/#380 Kerr. Canon #49 Kerr spec. No open telescope design shown in these lists. |
| V11 | Existing regression/merge gates and canon constraints | Read `CLAUDE.md`, `design_docs/README.md`, `mk/star-surfaces.mk`, Makefile identification/free-nav targets; canon pillars, decisions, roadmap, ADR 0001, normative RS/HB and relevant feature sections | Package-first physics, strict VM, parity, no Python pipeline, no-survey-budget, shared frame, live clocks, non-twitch controls and diegetic authority incorporated. Proposed make targets above do not yet exist. |
