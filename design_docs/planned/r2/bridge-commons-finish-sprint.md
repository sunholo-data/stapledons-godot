# R2-VIEW-FINISH: finish the bridge and first Commons views

**Status:** Approved by Mark in this attended session, 2026-10-29: "proceed" (D-130). VF0 preserved and backed up; Commons runtime/layout, natural bridge contact and UI integrated in draft PR #351. Commons S3, art-pilot and S5 visual approvals remain pending.
**Attended continuation D-133:** Mark likes the current direction and asks for more lived-in detail. One court/arcade art pilot is authorized on the current layout. This bounded visual study does not assert that every S3 manual playtest item is complete, and does not authorize repeating the finish before pilot review.
**Request:** audit existing work, respect settled art decisions, propose concurrent sprints, and provide laptop asset previews before final visual approval.
**Base audited:** `b07c9763` on `main`. Runtime: AILANG v0.54.18.
**Design authority:** [R2-LEVELS](levels.md), [its approved sprint](levels-sprint.md), [Commons brief](../../levels/commons.md), [level lifecycle](../../levels/README.md), [approved bridge styling](../../implemented/r2/bridge-styling-pass.md), and [camera-forward](../../implemented/r2/camera-forward.md).
**Tracking:** `.ailang/state/sprints/sprint_R2-VIEW-FINISH.json`. This is a coordination/replanning overlay, not a replacement for D-103 or a second game design. LP1b–LP4 keep their existing acceptance criteria.

## Recommendation and sequence

Finish a coherent bridge → lift → Commons journey. Preserve the approved bridge composition, bring the Commons onto the approved fixed-view level system, then dress its accepted layout to the bridge's finish.

1. Sign off this delivery sequence and bounded bridge/UI scope.
2. Preserve sources and capture the current baseline. Publish a private Tailscale review gallery.
3. Run Commons runtime/layout, bridge finish, and UI polish in parallel, with one integration owner.
4. **Review the playable Commons greybox (S3)** before detailed Commons construction.
5. Dress the accepted Commons; **review an actual in-engine style pilot** before repeating the finish across all approved views. Finish approved bridge/UI changes alongside it.
6. **Review the complete Commons style set (S5)**, integrate, evaluate independently, and deliver a tested dev build.

The pilot is an early checkpoint inside LP3, not approval of the whole dressed level. Layout changes requested at S3 return to S2; style changes return to the pilot. Capture and asset work may proceed incrementally, but approval does not arise from silence.

## What the audit establishes

| Area | Evidence at the audited base | Consequence |
|---|---|---|
| Bridge | `design_docs/implemented/r2/bridge-styling-pass-report.md`: approved grown props, painted floor/mast, toon/ink, lift head, foliage and common HUD theme | Refine an established look; avoid a new visual direction |
| Commons geometry | `art/ship-commons-v1/README.md`: v3 open plaza, guarded link, four curved arcade bays; 24,528-triangle detailed asset and 11,380-triangle coarse asset | Reuse this architecture/kit; it is not a finished whole tier |
| Commons runtime | `data/camera/views.json:25` is still `legacy: true`; `demos/ship_geometry_demo.gd:754` deliberately excludes lower decks from styling | Camera, stage integration and an explicit Commons styling boundary are required |
| Level tooling | R2-LEVELS JSON records LP0/LP1a complete; `mk/levels.mk` has evaluator, regression and capture tools | Resume LP1b, not a new framework |
| Layout gap | No production `art/levels/commons/layout.json` or `assets/levels/commons/manifest.json`; the brief records mock pole/head failures | A fixture/mock is not the finished playable Commons |
| Old dependency | D-125 records the held scene PRs merged; bridge styling is implemented | Remove obsolete merge holds after checking current owners |
| Bridge contact | D-121 accepts CA2 and explicitly defers facing-specific console hand/furniture alignment | A suitable small bridge finish task |
| Performance | D-127 B retains docked-control p99 validity; recorded docked p99 17.62–19.28 ms, 9/9 quiet runs | Coordinate existing row 7m-d attribution; old 16.0 ms styling results do not establish current completion |
| Source health | Blender checkout `e4da963` has untracked latest bridge generators/masters; bridge v4 hashes match `art/deck-layout-v2/asset-pins.json`; Commons v3 source master is tracked with embedded scripts | Preserve/recover before authoring; never clean/reset the Blender workspace |
| Preview history | `art/ship-commons-v1/style-preview/README.md` labels the old generated image as the earlier test pavilion | Exclude it from proposed Commons architecture approval |

Live `gh pr list` / `gh pr view` checks on 2026-10-29 found game PRs [#344](https://github.com/sunholo-data/stapledons-godot/pull/344), [#346](https://github.com/sunholo-data/stapledons-godot/pull/346), and [#349](https://github.com/sunholo-data/stapledons-godot/pull/349); no open design-repo PRs. Recheck at execution. #344 is approved and in progress per its live PR body, already has Earth-link sim work and reserves EL3 comms UI/station, EL4 map and EL5 visuals; coordinate future shared-file edits as well as today's diff. #346 touches Crew UI/tests and Makefile. #349 owns suite profiling. Use **gh**, not the GitHub connector.

## Settled visual contract

- D-91–D-95: fixed Bow/Astern views slide without turning; travel runs along the deck; preserve the bridge's approved bow-stage composition and authored station points.
- D-97/D-100/D-110: the spire and nearby star light the ship live, with their approved handover. Bake pigment/AO/contact treatment only. Sky, starbow, bodies, eclipses and lensing remain live.
- D-104: flowing curves and grown structures. Commons is an open civic plaza and curved arcade, not the rejected barrel pavilion.
- D-106 and #322 review: painted foliage cards placed in world space, footprint/shadow checks, varied plants. Do not restore camera-attached foreground plants.
- Preserve Josefin Sans/Nunito, cream/teal/ochre/violet materials, restrained ink and the existing functional UI colors. Preserve the captain's accepted painted walk, held poses and reduced-motion behavior (D-115/D-120/D-121); attended playtest D-138 raises traversal from 1.3 to 2.2 m/s for manual movement and Walk to.
- D-132 refines the console-contact contract: move the actual Voyage/Crew working destinations closer and use a gentle working lean on the existing desks. Check front and rear views. This explicitly releases the old fixed-use-point constraint for those two destinations; the proposed loops and desk leaves are retired without installation.
- Follow D-34's measured seven-tier geometry and the approved Commons brief over obsolete prose in older art briefs. No literal copying of concept-art sky, external camera or oversized spire.

## Sprint packages and dependencies

Effort is provisional agent working time, not a promise of elapsed autonomous runtime. The original remaining LP1b/LP2/LP3/LP4 estimates total 10.5 serial days. Recent merged work (#322 bridge styling, #330 CA2, #331 audio) demonstrates integration progress, but no measured art-throughput rate justifies a faster commitment. Allow roughly **12–15 working days on the critical path**, excluding Mark's review time and shared-rig waits, including about 25% contingency. Parallel bridge/UI work consumes additional agent time without extending that path if bounded.

| Package | Scope and files | Dependency | Estimate |
|---|---|---|---|
| VF0: source/baseline | Preserve bridge v4 master/scripts and recover Commons v3 embedded generators; source/hash inventory; current player-camera/HUD baseline and private gallery | Plan sign-off | 0.5–1 day; ~100 game/harness LOC |
| VF1: Commons runtime, existing LP1b | Manifest camera loading, vertical follow/clamp, enclosed pose, lift and per-level lights. `data/camera/views.json`, `demos/camera_director.gd`, lift/light/runtime adapters and corresponding tests | VF0 | ~3 days; ~650 LOC |
| VF2: Commons layout, existing LP2 | Production layout, thresholds, manifest, reachable routes/cues; fix head/pole blocks; retire legacy views. `art/levels/commons/`, `assets/levels/commons/`, level/camera tests | VF1; reuse kit inventoried in VF0 | ~2.5 days; ~300 LOC; **S3 review** |
| VFB: bridge finish | Facing/contact at existing console use points; chair/lift/prop readability; bounded source mesh corrections. Separate bridge authoring assets and targeted animation/console tests | VF0; runtime contract frozen | ~1.5 days; ~150 game/test LOC plus authoring |
| VFU: UI polish | Level-aware help, prompt hierarchy, lift return guidance, spacing/focus and laptop scaling. `ui/ship_hud.gd`, `ui/ship_controls.gd`, theme only when needed, UI tests/captures | VF0; agree runtime state contract with VF1 | ~2 days; ~250 LOC |
| VF3: Commons art, existing LP3 | Curved stalls/terraces/gantry/balcony, furnishings and foliage, hero/coarse/walk exports, bounded spire/practical light; retire temporary below-rail silhouettes through integrator. New Commons master/generator, assets/manifest/pins, explicit Commons style tests | VF2 **and S3 acceptance**; module/material studies may precede S3 | ~4 days; ~250 game/test LOC + ~600–1,000 authoring LOC; **pilot then S5 review** |
| VF4: integrate/evaluate, existing LP4 | Final captures, regression baselines, export/dev build, independent evaluation, report and doc/status updates | VFB + VFU + VF3; S5 acceptance; performance evidence | ~1–2 days; ~250 LOC |

Game/harness estimate: **1,950 LOC**, separate from Blender authoring. Do not expand scope to fill these estimates. Break VF1 into camera/manifests, lift/transfers, and light/physics-check commits; VF2 into layout/data and legacy retirement; VF3 into pilot and approved propagation. Each executor session ends with a small reviewable commit and updated state.

## Concurrency and ownership

At most **three worker agents plus the coordinator**:

| Wave | Worker A | Worker B | Worker C | Coordinator |
|---|---|---|---|---|
| Baseline | Runtime inventory | Blender preservation | UI baseline inventory | Capture/publish schedule and shared owners |
| First implementation | VF1 → VF2 Commons runtime/layout | VFB bridge finish; Commons kit studies when free | VFU UI polish | Integrate shared hooks; coordinate existing performance owner |
| After S3 | Runtime integration and regressions | VF3 Commons pilot → approved dressing | UI integration/preview review fixes | Publish review rounds; reserve quiet GPU slots |
| Final | Targeted fixes | Source/export fixes | UI verification | Assign a **different agent** to evaluate after executor work ends |

The runtime/integration owner alone edits `ship_geometry_demo.gd`, `camera_director.gd`, `views.json`, lift and light adapters. The UI owner alone edits the shared theme. One integrator stages Makefile changes and unified `ship.glb` exports. Art workers exchange independently named assets/layout data rather than concurrently exporting the same file. Bridge and Commons authoring must use separate working copies/masters. Respect #344/#346 reservations; do not implement a second comms station or duplicate suite instrumentation.

CPU authoring, data work and code review can run concurrently. **GPU captures, Blender GPU renders, goldens and performance runs are serialized.** Row 7m-d remains with its existing owner; reserve an uncontended slot and use its findings. Do not mark the docked-performance criterion met or change its validity rule to unblock art.

## Previews and sign-off packages

Use the `tailscale-preview` skill when hosting starts: inspect current DNS/Serve routes/listeners, preserve other services, serve a dedicated staging directory containing only review exports, use private Tailnet HTTPS, verify the page and an image, return the actual laptop URL. No repo-root file server and no public Funnel. The preview server must remain running. A self-request failure is reported accurately and does not establish laptop failure.

Each gallery round includes revision/commit and asset hashes, contact sheet, full-size images, current/proposed labels, real camera/viewport/UI scale, review checklist and known unfinished items. Supply a downloadable dev build for layout feel; a static asset gallery does not certify traversal or run the native game in a browser.

| Round | What Mark receives | Decision |
|---|---|---|
| Baseline | Current bridge Bow/Astern, consoles, lift and Commons plaza/arcade; existing legacy cameras explicitly labelled | Reference only; already approved art direction stays settled |
| S3 layout | Actual fixed player views for landing/court/terrace/gantry/service, route walk-through, lift round trip, metrics, dev build | Can you find the routes/landmarks, keep the captain visible, and enjoy the reveals? Accept layout or request moves |
| Art pilot | One representative Commons court/arcade view with nearby furnishings/foliage/practicals; matched rest, cruise and stop; bridge contact/UI proposal | Approve finish and scale before repeating it |
| S5 complete | Full dressed stage set, lift continuity and bridge/lower-deck relationship, HUD on/off, final comparison | Approve the complete appearance or request concrete fixes |
| Final | Tested native build, final gallery and independent evaluation | Accept delivery |

Core views: bridge Bow/Astern/console contact; Commons arrival, court, inside/along arcade, terrace, gantry balcony, enclosed service and roof crossings; bridge → lift → Commons → bridge. Include deep space, nearby-star handover, 0.99c and a stop with body framing. Use HUD on/off at **1280×720 and 2560×1440**, a 1920×1080 performance/review sample, and actual laptop Retina UI scaling. Existing old standing-eye Commons captures are diagnostics, not final player-camera approval. Generated finish studies, if requested later, are explicitly labelled concepts; runtime acceptance uses engine captures.

Bridge contact and UI proposals are published and reviewed as soon as ready, independently of the Commons art pilot; they do not wait for S3. Their approval authorizes only that bounded bridge/UI work.

## Acceptance and verification

Commands marked **add** are planned missing gates, not commands claimed to pass today. Existing scripts may need the indicated coverage extended. Every changed SR/GR pose retains spec check values, GPU/CPU goldens and opened renders.

| Package | Checkable acceptance |
|---|---|
| VF0 | `shasum -a 256` matches source inventory/pins; authoring master opens without missing packed resources; `make style-capture TAG=view-finish-before`, `make ship-ui-capture`, diagnostic `tools/ship_commons_capture.gd` outputs inspected; gallery page/image requests succeed or precise connection limits recorded |
| VF1 | `make camera-test camera-forward-test level-test level-eval-test ship-demo-lift-test ship-star-light-test ship-console-test deck-layout-eval physics`; add G-LVL clamp/raised cases to `make golden`; reference images inspected |
| VF2 | `make level-eval LEVEL=commons`, `make levels-regress`, `make camera-test camera-forward-test level-eval-test ship-movement-test`; `make level-capture LEVEL=commons TAG=s3`; all approved per-metric thresholds pass, including head ≤2% per surface, zero at spawns/use points/route ends, and pole-ray clearance (D-103, `levels.md` §B5/OQ4); route/checklist playtest; S3 ruling recorded |
| VFB | `make deck-assets-check deck-layout-eval style-test dressing-test ship-console-test`; extend held-pose/console coverage for contact; `make style-capture TAG=bridge-finish`; actual facing/contact frames inspected; keep approved use points/layout unless a specific move is reviewed |
| VFU | `make ui-theme-check ship-ui-test ship-console-test no-twitch-test crew-console-test`; `make ship-ui-window-check`; extend `make ship-ui-capture` for Commons stages and scaling; measure panel/text bounds and inspect keyboard/pad/mouse focus; no clipped/overlapping actionable controls in tested sizes |
| VF3 | **Add** `make level-assets-check LEVEL=commons` and `make foliage-check` from the existing LP3 plan, with bad-pin/sky-treatment/foliage-placement negative controls; repeated authoring exports match hashes; `make level-eval LEVEL=commons`, `make export-filter-audit`, updated style exclusions/assertions, `make level-capture LEVEL=commons TAG=s5`; inspect pilot and all stage frames; S5 ruling recorded |
| VF4 | `make levels-regress`; quiet `make bench SCENE=bridge` and `make bench SCENE=level LEVEL=commons` at 2560×1440, p99 <16.7 ms, D-127 docked validity honored; `tools/rig_check.sh <PR> --golden` green and fast CI green on final head; `make export-smoke`; independent evaluator ≥70/100; final captures opened |

No tests/full suite were run during this documentation-only audit. At implementation, targeted behavioral tests precede runtime changes; aesthetic-only edits use relevant captures and existing guards. Full `make test` remains the Studio landing gate per CLAUDE.md. Do not pin a stale golden count from the old plan; retain all current cases and add required ones.

## Document updates at execution

1. Refresh `levels.md`, `levels-sprint.md` and `sprint_R2-LEVELS.json`: obsolete dependency holds, current runtime version, completed LP0/LP1a and split handoffs. Preserve original D-103 approval and completed evidence; link this coordination overlay.
2. Correct `design_docs/README.md`'s deck-layout status/scope and obsolete baked-light wording. Reconcile `deck-layout.md`/sprint landing status against its implemented assets/report; do not execute its old bridge+Commons assumptions.
3. Keep `design_docs/levels/commons.md`, `bridge.md` and `backlog.md` current at S3/S5/landing, with version, next pause and attended rulings. Final baselines change only with measured reasons.
4. At landing, write the R2-LEVELS report/changelog and the already planned canon follow-up for seven-tier/stage terminology. No silent canon or threshold changes.

## Scope, risks and approval boundaries

**Included:** finished first playable bridge/Commons views, five-stage Commons brief where feasible, calm captain integration, local cues, lighting/material/foliage continuity, laptop UI clarity and a reviewed dev build. A finished view means coherent art, navigation and presentation. D-134 expands the review pilot to the wider physical Commons backdrop: broken civic fronts, planted terraces, market canopies and low rim gardens toward the 75.9 m edge. Background architecture can occupy existing physical deck beyond WALK; this adds no new traversable area or population simulation. Keep foreground, middle distance and distant planted silhouettes visible together from actual player cameras, with intentional live-sky avenues. All vertices remain inside the conservative 95 m envelope; no visible dome or enlarged spire.

**Deferred:** Garden and other tiers, a new bridge stern gallery/mast-ring layout, new population/crowd simulation, crew-work systems, Archive-presence choice and Earth-link behavior owned by #344. These can remain separate roadmap lanes. Reusing shipped ambience/animation is in scope; broad new sound/character production needs its own reviewed slice.

**Cut order:** retain the existing approved service-gallery → N-stop lift generalization → enclosed-view cut order if the runtime/layout cap is exceeded; report any cut and adjust the S3 checklist before claiming five-stage completion. Never trade away core arrival/court/terrace/gantry readability or weaken thresholds silently.

Mark approved execution through D-130. The remaining S3/S5 pauses come from [levels-sprint.md](levels-sprint.md#pause-points). At each required review: preserve/commit current task work, report the concrete pending decision, and end the executor run. Already settled design rulings are not reopened. No detailed Commons production before S3 acceptance; no propagation beyond the art pilot before its finish is accepted.

## Registry reuse

VF0/VF1/VF2/VFB/VFU/VF3/VF4: **none** for new package capability. This scope writes no `.ail`, adds no physics formulas, and reuses repo-native `LevelSchema`, `LevelGreybox`, `LevelMetrics`, `CameraDirector`, `StapledonStyle` and `StapledonTheme`. No package-like capability is proposed, so no registry search is needed for this overlay. Any newly discovered package/maths work triggers a registry audit and design adjustment before handoff.

## D-134 macro backdrop review

Mark found the furniture pilot pleasant but too sparse across the wider deck compared with the concept. The next bounded pilot compares furniture alone with real architectural/landscape depth using `art/commons-backdrop-pilot/placements.json`. Capture Bow/Astern at rest, cruise and real stop, including the under-terrace clamp and a valid bridge rim point. Validate actual physical floor support outside WALK, whole-vertex envelope, original head/pole metrics and existing routes. Production propagation and S5 remain pending.

## D-135 grown civic life refinement

Mark asks to go further: follow the comic aesthetic and long tendril architecture, and make the still-bare deck feel like a living level. The next preview replaces the miniature-building-on-platform composition with three occupied middle-distance districts: north-west grove around (14,26), southern social spaces around (15,-21)/(39,-24), and grown arcade edge around X44–58/Y-2–12. Use rooted 12–18m sweeping structure, substantial long planted islands, curved patterned paving, sheltered dining/market/readers and restrained ambient residents. The distant D-134 architecture remains a background layer. Keep existing WALK/routes, approved cameras, invisible boundary and measured inaccessible spire. Activity is decorative review art, without new population/crew systems. Source masters remain recoverable; actual player views and all original envelope/head/pole/body thresholds are the review evidence. No propagation before this appearance is reviewed.

## D-136 playable handoff

Mark accepts the grown civic direction for hands-on review: enable the existing pilot layers and ambient activity in the normal ship entry, build a native Mac playtest, verify the bridge/lift/court/return path and reduced-motion behavior, and share the new immutable archive on the existing private gallery. The loading jump waits for the civic installation. Raw authoring studies remain opt-in so matched comparisons retain their before state. Bundle exact source assets/configs with hash closure checks. This authorizes playable integration of the reviewed composition, without certifying all S3/S5 observations, final performance or landing.

## D-139 NPC appearance and crew in the crowd

Mark's native playtest correction: all NPCs use the captain's painted comic character style. Replace the procedural 3D resident figures in `demos/commons_life_pilot.gd` with painted, foot-anchored figures using the captain's presentation as the reference. Background NPCs need only appropriate still poses or restrained loops; they do not need the captain's full animation set. The existing mesh people are temporary proxies, not an accepted character treatment. This carries D-7's portrait-derived figure direction into the Commons.

Named crew mingle with the residents in the same visual treatment. Preserve each crew member's established portrait identity so their in-world figure and Crew console portrait read as the same person. A generic decorative resident must not silently become a named simulated crew member. Crew presence, identity binding and any interaction belong in the character follow-up; this ruling does not mark those systems implemented.

Before replacing the full crowd, review a bounded painted-character pilot in actual Bow and Astern player views, with the captain, background residents and named crew together. Check foot anchors, seated contacts, floor/route clearance, occlusion and reduced motion using the existing civic playtest and capture guards. Plan the asset/identity slice explicitly before execution under the project's design → sprint → approval cycle. Current publication and S3/S5 evidence remain historical; D-139 is pending implementation and visual review.
