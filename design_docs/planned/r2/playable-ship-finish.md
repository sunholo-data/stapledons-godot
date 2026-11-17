# PLAYABLE-SHIP-FINISH: close the painted ship's native review gap

**Status:** Approved SF0–SF1b implemented and locally qualified, 2026-11-17. SF2/native acceptance and remote landing remain open.
**Release:** r2 · **Milestone:** continuation of R2-VIEW-FINISH / R2-LEVELS and R2-CAPTAIN-ANIMATION; no new roadmap row.
**Priority:** P1. Makes the already packaged painted bridge/Commons review assessable on the laptop; broader gameplay is owned by the other playable strands.
**Implements:**
- [Multi-level ship visualization](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase2-core-views/multi-level-ship-visualization.md), “Superseded in part”: distinct zones, spire anchor and real lift continuity under R2-LEVELS, without resurrecting cut-away floors or isometric tiles.
- [Character brief](https://github.com/sunholo-data/stapledons-design/blob/main/art/characters-blender-brief.md) §3.1–3.3: painted captain, restrained background figures and life stages; existing captain review gates remain authoritative.
- [ADR 0001](https://github.com/sunholo-data/stapledons-design/blob/main/decisions/0001-engine-and-architecture.md): Godot presentation around the existing AILANG sidecar.
- [Relativity spec](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md) §1–2 and [Higgs bubble](https://github.com/sunholo-data/stapledons-design/blob/main/physics/higgs-bubble.md) §1, §7: preserve physical sky, precision and live star lighting. No new physics model.
**Depends on:** clean combined candidate `19e4a76338cb72e88e73a22790239691a72ab439` in `../stapledons-godot-painted-levels`, based on main `36f4ab4c4044f2d57f1b532cf298ca21c29346c5`; existing R2 review gates; pinned runtime v0.56.1; access to Mark's actual laptop for native evidence.
**Estimated:** initial evidence slice ~390 LOC (implementation + meaningful harness tests), four bounded packages; 2–3 working days as a planning allowance, excluding human review/publication waits. No measured comparable velocity supports a delivery promise.
**Evidence:** V1–V12 distinguish committed candidate evidence from this checkout's uncommitted authoring records. Tests reported in existing receipts were not rerun for this planning audit.

## Game vision alignment

Scored with `game-vision-designer`, feature-validation mode, against the six current pillars; canon checkout `c0ff15282dbdf4e82ceae47aafa6b1efcddf96aa`.

| Pillar | Relevance | Score | Notes |
|---|---|---|---|
| Choices Are Final | 0 | 0 | Review fixtures use disposable seeded sessions; no player save/reload or undo feature. |
| The Game Doesn't Judge | 0 | 0 | Resident appearance, camera coverage and frame timings carry no moral score. |
| Time Has Emotional Weight | + | +1 | Native review includes transit clocks and the live starbow alongside the human captain; no presentation freeze of the voyage. |
| The Ship Is Home | ++ | +2 | Both painted decks, 42 anchored residents, named crew and the lift must coexist in one installed app. |
| Grounded Strangeness | 0 | 0 | No new species or encounter design; avoids suggesting painted residents constitute population simulation. |
| We Are Not Built For This | + | +1 | Retains human figure scale and reduced motion; checks a seated person and walking feet against real furnishings. |
| Hard sci-fi authenticity (spec) | ++ | +2 | Surface finish cannot replace physical sky/lighting, change WALK or weaken existing pole/occlusion checks. |
| **Net** | | **+6** | **Go for planning.** Native appearance and laptop performance remain unmeasured. |

## Problem

The missing step is reliable native review of the combined result, not another environment prototype.

1. **A concrete candidate exists.** The sibling is clean at `19e4a763`. Its production finish covers 141 bridge and 1,000 Commons meshes, preserving 981,694 source triangles; it installs 42 static painted residents including two named crew identities. Four textures add 61,510,040 bytes including mipmaps; this is a texture payload, not peak memory or frame cost (V1–V3).
2. **Packaging is ahead of delivery.** The local archive `v0.4.0-dev.37-living-bridge-703-g19e4a763` is 405,329,291 bytes; the receipt reports packed startup and strict export passing, SHA-256 `39f4169497c87a6752e94c7992a057af21ac3f253b9d2c9f93d87a1c550adf98`. The receipt says publication awaits approval after automatic approval review rejected external source publication. A local archive is not a normal-channel update or laptop install (V3).
3. **Existing benchmark commands do not establish painted-candidate cost.** Normal `main.gd` installs the finish after civic/physics readiness, but `tools/ship_demo_bench.gd` and `tools/m4_ship_bench.gd` instantiate the demo directly without calling that installer. `make bench SCENE=bridge` additionally hardcodes 2560×1440 in its bridge script; `BENCH_SIZE` is only wired into the separate starfield branch. Treating these commands as a painted laptop measurement would be false (V4–V5).
4. **There is useful infrastructure to extend.** The in-app `ShipDemoBenchmark.run(demo)` measures the actual passed scene at 1920×1080, records hardware, raw frame samples, draw calls and memory, and writes `user://ship_demo_benchmark.json`. Its default path starts the existing public-summary uploader. It currently labels the target laptop measurement pending and does not certify finish counts/hash, captain identity or a live-transit phase (V6).
5. **Captain authoring is not production completion.** The dirty local sprint records accepted dense profile art, revisions of front/diagonal arms and a later parked 3D experiment. `art/captain-elegant-rig/README.md` explicitly says to keep the painted captain/images. None of those authoring records certifies native installation of a new all-direction set, older ages or final foot/hand contact. The production captain must be inventoried rather than inferred from the newest art directory (V7).
6. **Historical timing does not settle this.** Studio docked-p99 attribution and D-127/D-147 concern another hardware/presentation path; the 16.7 ms bound and valid-control rule remain. No laptop FPS or native lighting measurement was performed here (V8).

## Goals and non-goals

**Goals:** identify precisely what is installed; collect reproducible local native evidence from the normal game entry; review both decks, painted residents and the shipped captain together; retain one app/one dev channel; turn concrete failures into bounded follow-up packages owned by the existing sprints.

**Non-goals:** repaint accepted assets, resume the parked 3D captain, generate more images, finish all older-age animations, add residents' walking AI, change geometry/physics/controls, redesign the cockpit, expand to more decks, complete the entire game's playable loop, or publish during planning. No improvement is presumed before a measured defect exists.

## Design

Extend the existing finish and benchmark paths so a native laptop report proves which production scene it measured, then close the original visual gates from that evidence.

### D1. Preserve the simulation and physics contract

No package maths, pure-sim or NDJSON change is needed. Existing float64 values, gamma and `1−beta` provenance, finite lookup tables, deterministic sim inputs and recorded AI inputs remain authoritative. The harness only observes presentation and drives existing seeded input paths. If profiling indicates a sim/physics change, stop this scope and design that change under the package-first/strict-VM/parity rules.

Paint resources keep the current live-lit toon/ink path and untouched astronomical rendering. Any later shader/observer repair must name the affected RS/HB check, existing or added GPU-vs-CPU case and opened references before merge. D-151's no-local-GPU instruction remains in force; it is not overridden by an idle rig.

### D2. Candidate identity and production closure (SF0)

Reuse the sibling's `PaintedLevelsFinish` installer and `tests/test_painted_levels.gd`. Wrap its existing integration check in a counted `SCRIPT_GATE` target, preserving late-NPC rollback, disjoint deck ownership, unchanged bodies/WALK/camera and the painted lift round trip. Add a normal-entry assertion so a fixture cannot pass by installing a different scene than the game launches.

Emit an evidence receipt containing build version/commit, finish manifest/resource hashes and install counts, captain production-manifest hash/current stage, resident semantics, and whether the run is source or packed. Fail on missing finish state, mismatched closure or a report from an unexported source tree presented as an installed archive. Keep source recovery/authoring receipts separate from runtime resource receipts.

Own one shared, proposed startup seam: `ShipReviewReadiness.wait(demo, timeout_ms)` in `demos/ship_review_readiness.gd`, returning `{ok, errors, identity}`. It waits, with a bounded deadline, until normal entry clears `painted_levels_pending`, then validates `painted_levels_result` and the production closure. Main retains ownership of civic readiness and its two-physics-frame installation ordering. Missing closure, installer error and a stalled pending marker fail closed. The benchmark and the playable-voyage PV1 harness consume this same helper; neither assumes one process frame means readiness. This avoids a race without changing gameplay startup or duplicating readiness logic.

The existing archive is a valid review baseline, not a reason to rebuild now. A later code-bearing review archive must incorporate current main and retain cockpit, AI panel, telescope and all other combined work; record new pins rather than reusing the old archive's receipt.

### D3. Local-only native profile using the installed scene (SF1a/SF1b)

Extend `ShipDemoBenchmark`; do not write a competing benchmark or optimize geometry before evidence. Add an explicit local-only mode that **never calls the uploader**, while preserving the existing default remote-summary behavior for other callers. Exercise this distinction with an uploader spy and the real report-writing path. Include exact build/finish/captain identity from D2 and actual viewport dimensions, driver, vsync, model, GPU, memory and sample windows. Metal GPU timestamps unavailable/zero are `unavailable`, not measured zero work.

Expose a proposed packaged argument `--ship-finish-review=<absolute-output-directory>` through the normal game entry after its real finish installation. It must refuse a headless performance claim. Use separate fresh seeded fixtures for docked bridge, Commons court/terrace/gantry, lift transit, seated console selection and one real sim-driven transit; save enough input/phase/camera metadata to reproduce the route. This argument is review tooling, not a player save mechanic. Reuse authored views and existing journey scripts. Preserve the normal game's state by running in a disposable review session.

Begin with the existing 120-frame warm-up and at least 300 samples per static phase; record all raw times, p50/p95/p99, over-budget frames, draw calls, primitives, engine texture/video counters and process memory. Add two repeated longer windows (at least 1,500 samples) for any failing/tail-sensitive phase before attribution. Run identical original-material and painted-material conditions through the same installer/scene on the same laptop; verify full restoration and do not substitute a geometry-reduced scene. Record power mode, display scaling/refresh, actual window size and other activity. Cold startup and deck-switch hitches are separate from warm steady-state timings.

**Report, then classify:** validity failure, native visual defect, or measured performance miss. Preserve the existing canonical `make bench SCENE=bridge` gate and D-127/D-147 rules; the new local report is complementary and does not retire or silently loosen them. The proposed laptop target is the existing 60 fps / 16.7 ms budget at 1920×1080, with p95/p99 both reported. Native-resolution results are additional evidence, not directly comparable. Mark must confirm the actual target machine before a laptop acceptance claim (OQ1).

### D4. Close existing reviews; keep repairs bounded (SF2 and later)

Create a single evidence matrix mapping the native shots, profile phases and Mark's verdicts to the existing R2-VIEW-FINISH VFB/VF2/VF3/VF4 and R2-LEVELS S3/S5 items. Include Bow/Astern on both decks, live rest/cruise/arrival lighting, functional screens, named crew, resident feet/seated contacts, under-terrace clamps, opaque service enclosure, lift return, reduced motion and chair/console transitions.

Record **accepted**, **needs repair** or **not reviewed** per item with exact archive/report pins. A report validator can reject missing evidence or stale hashes; it cannot manufacture visual approval. CPU inspection renders and browser animation reviews remain labelled as such.

Inventory the shipped captain before choosing any follow-up. Retain accepted painted imagery, 2.2 m/s traversal, distance-driven contacts, echo and reduced motion. If the native captain is acceptable, do not block ship delivery on a new art set. If a reproducible foot-slide/contact/facing defect remains, resume the matching CA1/CA2 task, capped initially at one stage and one failing facing/interaction. Older ages remain CA3, requiring their original art/spend review. No automatic propagation from v5–v7 authoring folders and no 3D substitution.

Any measured environment cost first gets a one-cause package: shared-resource/loading fix, redundant work removal or index/UV layout repair, with unchanged source faces and functional geometry. Retain before/after reports on the same hardware and archive. A proposal that changes art quality/budgets or exceeds ~200 implementation + ~100 test LOC returns for a new scoped sprint review. These conditional repair packages are **not** included in the initial sprint.

### D5. Delivery and approval boundaries

Keep the ordinary `./tools/install_review_build.sh --dev` workflow and one installed app (D-152). Do not introduce branch-specific installers or claim a channel update until its remote manifest/archive and downloaded checksum agree. The existing external publication rejection is recorded evidence, not new approval; publication remains an outstanding attended action, outside this planning run. Do not repeat an external push/upload here.

Mark's existing S3/S5 and captain review gates remain open where unreviewed. A targeted headless pass, archive smoke or independent internal preflight does not close them. Merge follows the GitHub fast tier, focused local gates, cross-family evaluation and Mark's native visual approval under CLAUDE.md. Do not schedule full GPU reruns as a quick merge prerequisite; nightly owns broad physics/golden coverage.

## Acceptance criteria

Commands marked **new** are specified implementation deliverables, not currently available targets. All performance and visual criteria are pending; none was executed for this design.

| ID | Checkable result | Command / evidence check |
|---|---|---|
| AC1 | Real normal-entry finish receipt, counts 141/1,000/42, captain/hash identity, rollback/restoration and lift invariants; parse/runtime errors and empty summaries fail. | **New:** `make ship-finish-test` (existing `tests/test_painted_levels.gd` plus focused normal-entry/receipt controls). |
| AC2 | Local review writes a complete report without any upload; existing default upload behavior preserved. Missing finish, bad hash, fake samples and GPU timing unavailable cases fail or are labelled correctly. | **New:** `make ship-finish-profile-test`. |
| AC3 | Packed headless finish closure passes on the final review archive. | Existing packed executable: `"$SHIP_EXE" --headless -- --painted-levels-smoke`; `make export-pack-check-strict`. Resolve `SHIP_EXE` from the actual app's `CFBundleExecutable`, as in the sprint command below. |
| AC4 | Native report proves the actual laptop/build/scene, both material conditions and all required phases, raw timing/memory, repeated windows for misses; reports validity separately from the 16.7 ms budget. | **New:** `"$SHIP_EXE" -- --ship-finish-review="$REVIEW_OUT"`, then `make ship-finish-review-report REPORT="$REVIEW_OUT/report.json"`. Native laptop run only; no automatic upload. |
| AC5 | Existing captain, camera, route, civic and contact behavior stays green on the final code. | `PATH="$PWD/runtime/bin:$PATH" make captain-anim-test captain-frames-check captain-chair-test bridge-operator-test camera-test camera-forward-test level-runtime-test commons-civic-playtest-test ship-demo-lift-test`. |
| AC6 | Native checklist has exact build/report/shot pins and Mark's explicit per-item verdicts; unreviewed S3/S5/CA rows cannot be marked complete. | **New:** `make ship-finish-review-report REPORT="$REVIEW_OUT/report.json" REVIEW="$REVIEW_OUT/mark-review.json"`; status check rejects absent verdicts, includes unresolved items rather than synthesizing approval. |
| AC7 | Integration remains eligible for landing without losing main's combined features. | GitHub `make ci-fast`, targeted gates above and cross-family sprint evaluation; nightly `rig/full`/`rig/golden` inspected separately. Publication, if separately authorized: `make publish-dev`, normal `--dev` installer and receipt checksum check. |

AC1/AC2/AC5 are the initial sprint's automated implementation gates. AC3/AC4/AC6 require a subsequently authorized archive/laptop session; AC7 is landing, not a claim that this evidence sprint alone finishes the ship.

## Sub-milestones and estimates

| Package | Existing owner | Bounded result | Estimate | Dependency |
|---|---|---|---|---|
| SF0 | VF4 integration | Counted normal-entry/closure evidence and receipt controls | ~60 implementation + 60 tests LOC; 60–90 min | sprint approval; current-main reconciliation |
| SF1a | VF4 performance evidence | Explicit no-upload mode, production/hardware metadata and validity controls | ~70 + 60 LOC; 60–90 min | SF0 |
| SF1b | VF4 performance evidence | Packaged entry into existing profiler; authored route/phase metadata and report validation | ~80 + 60 LOC; 60–90 min | SF1a |
| SF2 | VF2/VF3/VFB and CA review | One evidence matrix and exact laptop/captain handoff; independent evaluation | ~0 code LOC; 0.5–1 day including review preparation | SF1b; laptop/publication availability for actual acceptance |
| SF3, later | matching original sprint | One diagnosed environment or captain repair, only if evidence requires it | cap ~200 + 100 LOC per reviewed package; not initial sprint | native evidence + separate bounded plan |

Total initial slice ~390 LOC; allow 2–3 working days with ~25% uncertainty allowance and review preparation, not a measured velocity forecast. Existing art authoring, tests and indexing are reused rather than estimated again. See [the proposed sprint](playable-ship-finish-sprint.md).

## Risks and mitigations

| Risk | Response |
|---|---|
| Wrong build/scene yields reassuring performance | Assert normal-entry install markers, counts, closure hashes and packed build identity in every report. |
| Laptop tail blamed on paint without attribution | Paired original/painted runs; raw times, longer repeat windows and power/presentation metadata; native Metal tracing only if still needed. |
| Default profiler unexpectedly publishes | New local mode makes no uploader call and has a negative/spy test; existing behavior stays scoped to its current callers. |
| Art source directories appear newer than installed captain | Hash and inventory production assets first; preserve rejected/parked experiments and original review ownership. |
| Decision identifiers drifted between authoring and shared main | Shared candidate D-158 is the painted ship review ruling. Dirty art notes use prototype D-153–D-165 for different session decisions; cite file/date/words and never silently renumber the shared ledger (V9). |
| Candidate falls behind main or publication remains blocked | Reconcile at later execution; record archive/channel status explicitly. Network PR inventory failed in this audit, so check both repos' live PRs before execution (V10). |
| Planning creates accidental execution | Sprint and JSON remain `awaiting_approval`, all `passes` null; no executor message, push or commit. |

## Open questions for Mark

1. **Laptop measurement session (AC4):** recommendation: confirm the existing intended MacBook Air M2 (2022), 24 GB target, then run the local 1920×1080 review with an actual build pin. A different machine is valid evidence but needs its own target row; default if unanswered: all laptop/performance acceptance remains pending, headless harness work can proceed after sprint approval.
2. **Native appearance (AC6):** recommendation: assess the already packaged candidate first, then request specific ship/captain repairs from its exact shots. Choosing a wholesale new art/character pass costs additional review/spend and delays usable evidence; default if unanswered: keep the production painted captain and accepted environment direction, leave S3/S5/CA native gates open.
3. **Outstanding delivery action (D5):** recommendation: resolve publication for the concrete combined review archive through the normal dev channel in the attended delivery thread, after checking current-main freshness and the earlier automatic-review rejection. Choosing local transfer keeps the channel stale and needs an explicit receipt for the archive actually installed; default if unanswered: archive remains packaged/unpublished and no external write is attempted by this plan.

## Deliverables

This design, [proposed sprint](playable-ship-finish-sprint.md) and `.ailang/state/sprints/sprint_PLAYABLE-SHIP-FINISH.json` are the planning deliverables. Execution would add a small extension to existing benchmark/finish harnesses, local report schema/validator, native evidence matrix, and bounded issue handoffs to the original sprints. It does not add a competing ship-art or captain sprint. No canon changes are needed.

## Verification log

Audit date 2026-11-17. **R** = this checkout HEAD `f3aa83bf4120fb6f57d858129dd9bada59ed91b4`, with listed dirty authoring files; **C** = clean sibling candidate `19e4a76338cb72e88e73a22790239691a72ab439`; **D** = local canon `c0ff15282dbdf4e82ceae47aafa6b1efcddf96aa`. Commands below are read-only audit commands unless expressly described as future acceptance commands above.

| # | Claim | Command | Result |
|---|---|---|---|
| V1 | Candidate identity, ancestry and clean worktree | `git -C ../stapledons-godot-painted-levels rev-parse HEAD`; `git -C ../stapledons-godot-painted-levels log -8 --oneline`; `git -C ../stapledons-godot-painted-levels status --short` | C, three finish/export commits above base `36f4ab4c`; no dirty entries. Latest includes raw NPC images and pinned AI core export fixes. |
| V2 | Coverage/texture/semantics and limits are explicitly recorded | `cat ../stapledons-godot-painted-levels/assets/levels/painted/README.md` | C records 141/1,000 meshes, 42 static residents, 854,316 vertices, 981,694 retained source triangles, 61,510,040 texture bytes. No certified native appearance/FPS. Recorded authoring/headless passes and internal preflight 86 are historical receipts, not this audit's test results. |
| V3 | Concrete archive exists in authoring record, publication remains pending | `cat art/visual-refresh-v1/playable-review.json`; `cat art/environment-painted-pilot/commons-finish/README.md` | Untracked R records C archive, size/hash and packed startup/strict export 3,046 checks, zero failures. Earlier automatic approval review rejected external source publication. Archive bytes and remote state not independently rehashed/queried here. |
| V4 | Normal entry installs finish after readiness; packed smoke exists | `rg -n 'painted' ../stapledons-godot-painted-levels/main.gd` | C `main.gd:106–118` installs finish; `:1356` onward contains headless packed closure smoke. |
| V5 | Canonical source benchmarks omit finish installer and bridge size override | `cat ../stapledons-godot-painted-levels/tools/ship_demo_bench.gd`; `sed -n '1,100p' ../stapledons-godot-painted-levels/tools/m4_ship_bench.gd`; `sed -n '705,729p' ../stapledons-godot-painted-levels/Makefile` | C scripts construct demo directly; bridge script fixed size 2560×1440. BENCH_SIZE only passed in starfield make branch. Neither script installs painted finish. |
| V6 | Existing in-app profiler is reusable but its default uploads | `sed -n '1,185p' ../stapledons-godot-painted-levels/demos/ship_demo_benchmark.gd` | C `run(demo)` sizes 1920×1080, takes 120 warm-up/300 sample frames per view, records raw timing/hardware/memory and starts `upload` when output is the default path. Target measurement pending is hardcoded. |
| V7 | Captain authoring continuation is not installed production acceptance | `sed -n '23,49p' design_docs/planned/r2/captain-animation-sprint.md`; `cat art/captain-elegant-rig/README.md`; `cat ../stapledons-godot-painted-levels/mk/captain-anim.mk` | Dirty R notes preserve v5–v7 art and rejected/parked rig history; D-161 prototype header parks 3D work. C exposes existing captain/contact/chair tests. No new native captain/older-stage acceptance was established. |
| V8 | Historical Studio evidence and unchanged gate rules | `sed -n '1,110p' design_docs/planned/r1/m4-7md-docked-p99-attribution.md`; `rg -n '^\| D-(127|147)' ../stapledons-godot-painted-levels/design_docs/stapledon-mission.md` | Studio draw-bracket/pacing attribution is qualified and native Metal mechanism unresolved; D-147 permits readings 3 s after a run, preserves all other D-127 validity/budget rules. Not laptop evidence. |
| V9 | Shared decision authority differs from prototype labels | `rg -n '^\| D-(150|151|152|158)' ../stapledons-godot-painted-levels/design_docs/stapledon-mission.md`; `rg -n 'D-16[1-5]' design_docs/planned/r2/bridge-commons-finish-sprint.md` | C D-150 chair, D-151 seated view/no GPU, D-152 one build, D-158 painted ship candidate. Dirty R art labels remain historical; shared ledger was not modified. |
| V10 | Live PR overlap not verified | `gh pr list --repo sunholo-data/stapledons-godot --limit 30`; same for `sunholo-data/stapledons-design` | Both failed connecting to `api.github.com`; no claim of an empty PR queue. Refresh before execution. |
| V11 | Existing ownership/gates already cover finish and animation | `cat design_docs/planned/r2/bridge-commons-finish-sprint.md`; `cat design_docs/planned/r2/captain-animation-sprint.md`; `cat design_docs/levels/README.md`; `rg -n '^[a-zA-Z0-9_-]+:' ../stapledons-godot-painted-levels/mk/commons-civic.mk ../stapledons-godot-painted-levels/mk/levels.mk` | VF is an overlay of approved LP tasks; S3/S5 remain attended. Existing headless route/civic/captain targets are reused. This design supplies production-scene/profile evidence rather than re-estimating completed art. |
| V12 | Normative and velocity grounding | `git -C ../stapledons-design rev-parse HEAD`; read pillars, character brief, visualization supersession, ADR, RS/HB and bubble Archive entry; `git log --since='2026-11-10' --format='%h %ad %s' --date=short -15`; `head -75 CHANGELOG.md` | D links preserve canon/physics; rejected visible-dome route is not reintroduced. Recent R history mostly ledger/test gates; C's three art/export commits give no comparable elapsed effort. No defensible LOC/day was calculated; estimates are bounded task allowances. |
