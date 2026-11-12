# R3-TELESCOPE sprint: visible telescope, map links and Euclid inspection

**Status:** Approved by Mark, attended 2026-11-12: “approved”. Execution begins at TS0. Prepared after Mark's “ok continue”; the concrete sprint was then explicitly approved. The accepted direction is the existing 3D map plus telescope and inspection enhancements, for a non-commercial game.
**Design:** [telescope-survey-inspection.md](telescope-survey-inspection.md).
**Progress:** `.ailang/state/sprints/sprint_R3-TELESCOPE.json`.
**Baseline inspected:** game `f3aa83bf`, current branch `feat/captain-command`; unrelated animation/art/mission edits must be preserved. Plan files only in this planning session. Do implementation in a separate full clone based on the combined current game, following CLAUDE.md's checkout policy; retain the approved cockpit work rather than starting a feature build that drops it.
**Estimate:** 2,600 code/test/tool LOC, 12 small milestones, nine working days of planning capacity including ~25% uncertainty and integration/review allowance. This is not a delivery-date promise; source-service availability and Mark's visual review are not timed commitments. Each coding milestone is sized for a 60–90 minute focused executor run; repeat runs are expected for source investigation and review fixes.
**Risk:** Medium, primarily scientific image registration and real data retrieval. A single outreach JPEG has been fetched and inspected; a registered scientific cutout/catalogue import has not been proven.

## Settled scope and approval boundary

- Use the existing map, Navigation station and captain's chair. A visible **Telescope** button and links from object inspection replace reliance on knowing the T shortcut. There is no new physical telescope station.
- Preserve the live stellar renderer; add an explicitly dated **Survey archive** view and shared facts/sources. No live optical galaxy reconstruction, cosmological distance conversion, new survey-time cost or bulk survey streaming.
- Non-commercial use is settled. Retain CC BY-NC DR1 terms/credit and each outreach asset's own terms; no commercial-permission gate.
- Default collection: M81 group, NGC 1291 and Abell 3128. At least one field must have independently verified astrometric registration and actual catalogue associations; other plates may be explicitly unregistered. Never fake a footprint or association to reach three fields.
- D-28, D-41, D-56/D-57, D-111 and D-150 apply. No still-OPEN product decision blocks this scope. Do not reopen those rulings or the non-commercial decision during execution.
- **Execution approval:** CLAUDE.md §Development cycle step 2 requires “Stop for approval before executing.” Keep `approved: false` until Mark approves this plan. Do not send an executor handoff or start coding before that approval. Technical failures use the finite failure handling below; visual acceptance remains the normal merge requirement.

## Current implementation and evidence

The design's V1–V11 are the baseline source audit. Rechecked this planning session:

| Evidence | Result and planning implication |
|---|---|
| `ui/telescope_view.gd`; demo `_unhandled_input` and `at_helm_closeup` | Renderer and whole-disc/close/off cycle exist behind T in the Navigation close-up. No installed-build availability claim; establish it through TS5/TS9 tests. |
| `GalaxyMap.preselect` | Queues `plan_intent` during planning. TS4 creates a separate read-only object-focus path before any new inspection link uses the map. |
| `ui/captain_command.gd` | Navigation is hosted on chair screens; route the shared panel through its current screen host rather than creating a second UI instance/input dispatcher. |
| Runtime `ailang version` | v0.56.1, commit `05c860a`; the game pin is correct. |
| Teaching prompt | **AILANG prompt version loaded: v0.16.11**, from `runtime/bin/ailang prompt` and `prompt --version-active`. This is the prompt version, distinct from runtime v0.56.1. |
| Registry searches and info/docs, 2026-11-12 | `celestial` returns celestial 0.6.1 and observe 0.1.0; `wcs` and `csv` return no packages. `hips` returns an unrelated decisions package. Latest celestial docs list frames/rotations, no TAN/WCS projection. Keep current game pins until TS1 deliberately publishes/adopts the additive extension; do not upgrade solely because 0.6.1 exists. |
| `gh pr list` both repos | Game #433 reason-card fixture, #432 site, #373/#380 Kerr remain open. #431 no longer appears as open; inspect its merged state/base at execution before integrating finder links. Canon #58 dark-lenses proposal and #49 Kerr are separate work. Do not implement those proposals here. |
| Recent velocity | Seven-day non-merge code/test churn: +4,126/−417 across 126 file-change entries, from `git log --since=2026-11-05 --no-merges --numstat --format= -- '*.gd' '*.ail' '*.gdshader' '*.sh'`. This is team/branch churn, not a measured individual throughput. |
| Comparable UI/renderer change | `git show --stat 8912360f` on five relevant files: +249/−15 for the original telescope/close-pass/activity slice. The landed star-surface work also required independent evaluation, rendering and review. Budget source proof/integration rather than extrapolating only that coding diff. |

The velocity script was run; it found no changelog LOC metrics and reports only HEAD~1→HEAD, so its diff is not used as seven-day velocity. Planning capacity is conservatively ~400 code/test LOC per working day: 2,600/400 = 6.5 days; 25% buffer plus review preparation rounds to nine. Do not represent that assumption as historical solo velocity.

## Registry reuse audit

| Milestone | Decision | Package and rationale |
|---|---|---|
| TS0 | none | Source/rights curation and image-file proof; searches `wcs`, `csv`, `hips` found no suitable ingestion package. Shell downloads and Godot I/O, not a new service client library. |
| TS1 | contribute | Extend `sunholo/celestial` for supported TAN forward/inverse and angular geometry; reuse its existing `frames` helpers. Inspect current package source before adding; no fresh astronomy package. |
| TS2 | depend | Use the celestial version published in TS1 for coordinates; retain existing AILANG JSON/CSV tooling patterns for the small observation index. |
| TS3 | none | Godot image tiling/cache is engine/file I/O; celestial/observe are maths, not image codecs. |
| TS4 | none | Exact-ID selection adapter over current Godot map/body records, with no new physics capability. |
| TS5 | depend | Existing `sunholo/celestial` surface records and `sunholo/relativity@0.12.0`; preserve physical uniforms, no new optical model. |
| TS6 | none | Godot archive-panel composition and controls; projection maths comes from TS1, not a UI package. |
| TS7 | depend | Celestial frame/projection output and the game's shared `SkyFrame`; direction-only survey layer, no cosmology. |
| TS8 | depend | Existing `sunholo/observe@0.1.0` and celestial data feed authoritative live facts; formatting adds no new light-time calculation. |
| TS9 | none | Compose current station/chair/read-only panel hosts. No new agent or simulation package. |
| TS10 | none | Existing asset/export infrastructure with engine tile I/O; no library capability missing. |
| TS11 | none | Independent review, measured captures and landing evidence; no new package functionality. |

## Execution rules and finite failure handling

Run tests red before implementing each new behaviour, then the milestone's targeted checks. New `make` targets are explicitly new until their milestone creates them. Use `SCRIPT_GATE`, deadlines, counted success, non-zero failure and script-error rejection. Isolate temporary mutants and restore originals. New GDScript/shader files carry `.uid` files. No production Python pipeline; Python may be a scratch independent oracle/harness only.

Source-service retries are bounded: connect timeout 10 s, total request timeout 60 s, at most two retries per endpoint. TS0 tries the documented DR1 service and one documented mirror/published-table route. If neither yields a real supported registered field and a usable real table, record exact endpoints/errors, retain the source report and stop dependent milestones. Do not silently substitute test data or claim a functioning importer. This is a technical prerequisite failure, not a new permission request.

No hidden new physics. TS1 package tests/CHANGELOG/quality/release precede a game pin/lock update. Package publication follows the project's established package workflow and existing authorisation; any required environment approval is handled when actually reached, not invented as a new product decision here. Strict VM/interpreter disagreement or language DX failures get a minimal upstream report through the standing channel.

For the actual example/probe modules:

| Module | Contracts | Effects | Inline tests/properties |
|---|---|---|---|
| celestial TAN/projection module | include: finite input scale, non-singular CD transform, latitude domain and explicit unsupported/singular result; requires/ensures on pure forward/inverse helpers. Float inverse accuracy is numeric evidence, not an SMT-proof claim. | include: pure helpers `! {}` | include: centre, five independent field points, RA wrap, poles, unsupported/singular and round-trip fixtures. |
| `sim/tools/observations.ail` | include: pure validate/normalise helper contracts; no accepted NaN/Inf or numeric-ID coercion. File/network parsing failure is an explicit Result. | include: CLI `main() -> () ! {IO, FS, Env}` with pure parsing/index functions separate | include: real small extract plus labelled malformed/ambiguous/long-ID fixtures; pure `observationProbe` VM/interpreter equality. |
| `sim/tools/observations_probe.ail` if a separate showcase is needed | include: deterministic projection/index digest for accepted fixtures; skip solver proofs for filesystem contents | include: pure exported probe; a printing `main() -> () ! {IO}` | include: equal digest and explicit rejection examples. Otherwise keep probe in existing observation tests and create no redundant showcase module. |

No simulation/NDJSON minor bump in this sprint. Host session metadata pins the observation pack. Project gate names override generic AILANG-repo targets: use this game's targeted tests/`ci-fast`, not `make test-changed` or coverage targets that do not exist here.

## Milestones

All paths below are intended implementation files, not files created by this plan. Existing giant coordinator scripts receive narrow hooks; keep substantial behaviour in the named companion files. Every milestone records actual counts, time and evidence in the JSON before setting `passes: true`.

### TS0_SOURCE — prove one real registered observation (150 LOC; 1–2 investigation runs)

Files/examples: `data/observations/euclid_dr1/{sources.csv,objects.csv,manifest.json,SHA256SUMS,credits.md}`, `tools/observation_pack_verify.gd` and `.uid`, bounded source-download shell glue. Large bytes stay in ignored scratch/content-addressed assets.

First write a small verifier that rejects missing/changed hashes, absent rights, unsupported projection and a bad registration anchor; show those red cases using labelled fixtures. Retrieve a real field and real associated rows using the documented API/table route; preserve original columns, schema/quality definitions, query, source date, hashes and IDs. Verify at least five independent anchor positions across a supported plate and two actual zoom levels; no caption-only registration. Log sizes/format and the source URL for each. Read-only external requests are allowed; no account creation or credential dependency.

Gate/example: `make observation-pack-verify` (**new**, 180 s local bound after explicit downloads); M81 is first choice, a genuine supported cutout in another selected field is an allowed technical fallback. At least one registered field is mandatory; do not defer it away. Design AC1, source part of AC9. Fail TS0 and stop its dependents if proof fails.

### TS1_COORDS — package projection and independent coordinates (250 LOC; 1–2 runs)

Depends TS0. Files: celestial package projection module/tests and package CHANGELOG/metadata in its own checkout; game `physics/observation_projection.gd` + `.uid`, coordinate test + `.uid`, sim pin/lock only after release. Reuse `frames.unitFromAngles/equatorialToGalactic` and `SkyFrame`.

Tests first: centre/corners/five independent source anchors, wrap, near-pole, determinant/orientation and singular/unsupported inputs. Use an independent astrometric oracle; package/mirror agreeing with each other is insufficient. Support only the source's declared TAN projection with a full pixel/CD transform; reject other distortions. Publish the additive package extension and record the actual version; never hand-copy the only formula into Godot.

Gate/example: native package check/tests/quality, probe strict VM/interpreter parity; `make observation-coordinate-test` (**new**, 180 s) with ≤0.1 source-pixel reference error on supported fields; `make physics` for any touched shared frame. Design AC3 and coordinate part of AC6. Avoid changing unrelated package behaviour or dependency pins.

### TS2_INDEX — deterministic facts and observation associations (280 LOC; 1 run)

Depends TS0/TS1. Files: `sim/tools/observations.ail`, `sim/tools/observations_test.ail`, sim module exports, `mk/observations.mk`, small explicit fixtures. Pure parse/validate/normalise and exact identity associations; CLI owns file I/O. Every imported fact has a unit, source, method and epoch if known; redshift is not distance or age. Missing is null. Do not join a nearby star just because its position falls in a field. Preserve long Euclid IDs as strings; ambiguous positional matches create a review report, not an accepted alias.

Gate/example: `make observation-import-test observation-import-parity` (**new**, 180 s each) using the real TS0 subset plus malformed/non-finite/duplicate/ambiguous/sentinel fixtures; compare index bytes twice and strict pure-probe VM/interpreter output. Design AC2/7. No production synthetic science rows.

### TS3_TILES — offline pyramid and bounded image loader (280 LOC; 1 run)

Depends TS0/TS1. Files: `tools/observation_tiles.gd`, `ui/observation_tiles.gd`, `.uid` companions and fixture tile pack. Godot generates 512-px tiles, gutters/mips and hashes offline. Runtime loads visible tiles only, retains low-res while loading, rejects stale replies and evicts to the fixed budget. No runtime network dependency or full-plate pan decode.

Gate/example: `make telescope-cache-test` (**new**, 180 s): seams on a labelled coordinate-grid fixture; known source crop; missing/corrupt/stale/cancelled/pack-mismatch cases; CPU/GPU accounting includes mip/gutter bytes. Caps: 128 MiB resident GPU tiles, 64 MiB CPU tiles, 100 MiB compressed starter pack. Reduce delivered sampling/optional image bytes with explicit resolution labels if needed; do not change caps silently. Design AC9/11.

### TS4_IDENTITY — read-only map focus and shared references (180 LOC; 1 run)

Depends TS2. Files: `ui/observation_index.gd`, `ui/object_reference.gd`, `.uid` files, narrow map/demo handoff hooks, `tests/test_telescope_map.gd`.

First prove the unsafe path with a test observing actual queued/sent plan intents. Add `focus_object`/observation selection independent of catalogue selection/planning. Exact star/body/survey references round-trip without index casts. Preserve the prior plot target, `_pending`, commit state and map camera. A read-only inspection action never queues `plan`, `commit`, `cancel`, approach/leave or a time-spending intent. Compare against the same running-session baseline so ordinary ticks remain legal.

Gate/example: `make telescope-map-test` (**new**, 600 s), including active uncommitted and committed real-sim journeys, invalid IDs, body/catalogue aliases and survey-only objects. Mutate it to call `preselect`; the no-extra-intent check must fail. Design AC4 and part AC8/12.

### TS5_LIVE — selected-star rendering and visible Telescope action (180 LOC; 1 run)

Depends TS4. Files: `ui/telescope_view.gd`, telescope controller companion, `.uid`, `tests/test_telescope_live.gd`, a small Navigation action hook.

Add an explicit selected finite-star ID. Keep largest-visible-disc fallback only when no target was requested; missing/hidden requested target shows an unavailable state. Keep the copied material, physical uniforms, scale function, surfaces and normaliser. Add a visible Telescope button rather than relying on T. Confirm the current shortcut's actual executable path before reporting it works. Do not change stellar stop distances or physical source brightness.

Gate/example: `make telescope-live-test` (**new**, 180 s); `make star-surface-test stellar-protocol-test`. Add targeted live `telescope-golden` cases now; windowed run only when GPU is free. Design AC5/6. No claim that a simulated stellar photosphere is a Euclid image.

### TS6_ARCHIVE — pan/zoom real Euclid imagery (340 LOC; up to 2 runs)

Depends TS2/TS3/TS4. Files: `ui/observation_panel.gd`, `.uid`, telescope UI tests and presentation labels/data. Keep one implementation, with Live and Survey archive tabs and explicit unavailable states. Image first; compact scale/date/source line; real-product band picker only. Pan, wheel/pinch/keys, fit-to-field, stable point-under-cursor zoom and source-resolution limit. Pixel picking exists only for registered fields and associated rows; overlap chooser preserves exact IDs. No invented object is created by clicking an uncatalogued pixel.

Gate/example: `make telescope-ui-test` (**new**, 300 s) for pan/zoom/masks/limits, overlap choice, stale field changes and missing products; `make object-inspection-test` (**new**, initial archive facts). Encoded archive pixels/overlay coordinates stay invariant with ship velocity/location/GR; do not pretend to live-render a photographed galaxy. Design AC7/8 and archive part AC6.

### TS7_MAP — survey directions inside the existing map (240 LOC; 1 run)

Depends TS4/TS6. Files: `ui/survey_map_layer.gd`, `.uid`, narrow `ui/galaxy_map.gd` hooks and map tests. Add a Survey sky context using the same map UI and exact references, with a Sol-centred directional sphere and real registered footprints. Label depth not shown; suppress distance rings/routes for that context. Preserve local 3D star positions/camera and frame conventions on returning. No survey object has a journey action, including one with a published redshift or distance. Unregistered plates stay in the collection browser only.

Gate/example: expanded `make telescope-map-test observation-coordinate-test`; `make starmap-consistency`. Direction/context toggle cannot generate navigation intents. Remove the survey non-navigable guard as a mutation and require a failed test. Design AC3/4/12.

### TS8_INSPECTION — common object facts and source cards (200 LOC; 1 run)

Depends TS2/TS4/TS6. Files: `ui/object_info.gd`, `.uid`, compatibility hooks in `ui/star_info.gd`, `ui/body_info.gd`, `ui/ship_star_identification.gd`, inspector tests. Compact primary facts and image/target thumbnail; expandable Details/Sources. Keep catalogue distance/brightness, live body distance/light age and dated survey facts in distinct sections. Preserve measured/inferred/assumed/modelled labels. Catalogue stars without imagery and survey galaxies without distance remain useful cards. All buttons take the same reference, no approximate/name-based reverse lookup.

Gate/example: `make object-inspection-test ship-star-identification-test`; fixture examples for nearby star, current finite star, planet/body, galaxy, candidate, no image, no distance and unknown fact. Do not overwrite the finder/reason-card schema or generate life evidence. Design AC7/12.

### TS9_ACCESS — station, chair and instant read-only entry (240 LOC; 1 run)

Depends TS5/TS6/TS7/TS8. Files: telescope controller/panel hosts, narrow `ShipConsoles`, captain-command/screen-host and demo hooks, UI/map tests. Navigation at the physical console and captain's chair hosts the same active telescope panel. I-card and M chart offer immediate read-only access without walking the captain. Full future time-spending actions remain outside this panel. T does not fire while typing; preserve legacy stellar cycling where applicable. Closing, standing, switching system and reparenting cleanly suspend renders, release drag/focus and restore each containing panel's Esc chain. No second renderer or duplicate callbacks.

Gate/example: `make telescope-ui-test telescope-map-test captain-command-test chair-cockpit-test ship-console-test`, projected chair clicks, keyboard/pad/typing/pinch cases and live-clock continuity. Use actual input dispatch, not only direct calls to callbacks. Design AC8/11/12.

### TS10_PACKAGE — ship offline assets and reproducible gates (160 LOC; 1 run)

Depends TS3/TS7/TS9. Files: observation asset download/staging shell, export filters/bundle handling, `mk/observations.mk`, `.uid` for new GDScript tools, host session metadata version pin, export smoke and capture/bench drivers. Wire manifest/image bytes and required credits through source and exported app; pin pack/version for the host session, never fall forward on a missing version. Include all three curated plates subject to TS0 registration rules. Observe no-network execution in the packaged smoke and reject corrupted/missing-pack cases without preventing the map/live telescope.

Gate/example: `make observation-assets-check telescope-export-smoke telescope-cache-test export-filter-audit` (**new** first and smoke), `make uid-guard python-guard`. Add new fast pure checks to `ci-fast`, focused UI checks to the existing headless tier, GPU cases to nightly `golden`; gate wrappers need killing failure controls. Design AC9/12.

### TS11_REVIEW — evidence, independent evaluation and landing (100 LOC; review runs)

Depends TS0–TS10. Run the targeted set below; add no full local suite or repeated loaded-host GPU runs. `make telescope-capture` (**new**) emits required layout checks/contact sheet at the three design sizes: M81 wide/detail, live Aldebaran, Navigation/chair/popup cards, directional survey context, gaps, credits and resolution limit. Open every frame and report issues. `make telescope-bench` (**new**) compares baseline/open/closed, warmed pan p95 added CPU ≤2 ms, cold loads separately, and exact resident memory against TS3 caps. Closing must stop decode/render updates.

Obtain the mandated independent cross-family evaluation (generator ≠ judge) before landing. Use the project's evaluator skill in a separate reviewer context at that stage, with the final diff and evidence; this planning session does not spawn an evaluator. Prepare one combined dev candidate with current main/cockpit/AI-panel work preserved. Publish/review candidate creation is not visual acceptance; Mark's actual dev-build OK is required for visual landing. Follow current publish rules rather than tagging a dev release without its required tests.

After evaluation and visual acceptance, move design/plan to `implemented/r3/`, add the README row and changelog entry/fragment under this game's convention, update canon feature/roadmap links in a separate reviewed change, and mark actual completion in JSON. Until then retain accurate pending status. Design AC10–12.

## Schedule and success metrics

| Working day | Intended work |
|---|---|
| 1 | TS0 real data/registration proof and TS1 package boundary; report any failed source route with bounded attempts. |
| 2 | Finish TS1 and TS2 deterministic import. |
| 3 | TS3 image tiles/cache and TS4 read-only selection. |
| 4 | TS5 selected live view and TS6 archive controls. |
| 5 | Finish TS6 and TS7 survey map context. |
| 6 | TS8 shared inspection and TS9 station/chair/input integration. |
| 7 | TS10 offline export, failure controls and targeted regression evidence. |
| 8–9 | Buffer, TS11 review/capture/bench fixes and review candidate preparation. Human/external waiting is additional. |

Success is all twelve design acceptance criteria satisfied with actual commands/evidence, one real registered field with two levels, three curated plates, the example object/card matrix above, no new navigation intents during observation, bounded assets/memory, exact provenance and usable helm/chair/read-only entry. Do not use a coverage percentage as a substitute for identity/physics/input failure tests.

## Targeted validation and merge gates

Use pinned runtime: `PATH=$PWD/runtime/bin:$PATH`. New targets come from their owning milestone before invocation. Keep bounded wrappers and real input failures visible. The final executor's focused set is:

```sh
make observation-pack-verify observation-import-test observation-import-parity observation-coordinate-test
make telescope-cache-test telescope-map-test telescope-live-test telescope-ui-test object-inspection-test
make star-surface-test stellar-protocol-test ship-star-identification-test free-nav-stop-test
make captain-command-test chair-cockpit-test ship-console-test starmap-consistency
make observation-assets-check telescope-export-smoke export-filter-audit uid-guard python-guard
make strict parity
```

Run `make physics` when touching frame/projection physics mirrors, along with the package-native tests. GitHub must pass `make ci-fast`; main's full `make test`/`make golden` remain nightly. Do not run the 70+ minute full suite per milestone. Add/run only the new `telescope-golden` cases locally when GPU is free, otherwise leave them to nightly plus the dev-build review. Before any windowed capture/bench on the Studio, follow the host's GPU/load guidance; do not wait in an unbounded loop for a quiet rig.

The existing plan's proposed ≤2-ms p95 CPU and memory caps are acceptance budgets, not already-measured performance. A failing benchmark, wrong registration or wrong physics remains a failed criterion; reduce implementation cost or repair data rather than changing the threshold to pass.

## Open questions and handoff

No new product question needs an answer beyond approval of this concrete plan. Navigation/chair placement and the three-field offline collection are the design defaults retained under Mark's continuation. Technical source proof is TS0, not a request to reconfirm the feature. Visual acceptance remains Mark's later dev-build verdict.

Do not execute or hand off while `approved` is false. On explicit sprint approval, record its actual date/words in JSON, load `sprint-executor`, and start at TS0; do not mark a milestone complete from this plan's source inspection. All milestones currently have `passes: null`. No GitHub issue is invented or auto-closed: #433 is adjacent work, not this sprint's issue.
