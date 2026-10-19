# Sprint R1-CONSTELLATIONS: constellation guides while holding I

**Design:** [constellation-inspection.md](constellation-inspection.md).
**Status:** Local implementation and verification complete; independent review recorded separately. CI and landing pending. Approved by Mark, attended 2026-10-17 (“yep continue”).
**Created:** 2026-10-17, attended request from Mark.
**Estimate:** ~720 LOC; two engineering days including visual review, with allowance for alias work and GPU access. Medium risk.
**Progress:** `.ailang/state/sprints/sprint_R1-CONSTELLATIONS.json`.

## Summary and current state

Add faint, named stick figures for Orion, Cassiopeia, Crux and the Big Dipper to the existing hold-I inspection mode. Endpoints follow the current rendered sky under velocity and position changes. Missing/invisible stars yield partial figures; GR guides are suppressed.

Existing input, projection, rebase, body visibility and catalogue machinery is available (design V1–V6). The feature itself is unimplemented. Alias resolution is the main data risk: do not infer full coverage from literal HIP IDs (V7). Read the current camera work in #261/#270 before editing camera integration.

Recent scale evidence: `658072a` (2026-10-16) added a 379-line GPU driver plus wiring; `fc2d552` (2026-10-15) added ~90 audit lines plus fixtures/integration. These are examples of delivered scope, not measured individual-agent hours. Budget ~360 LOC/day including tests, with the second day reserved partly for GPU/render/export evidence. Do not present this estimate as a measured velocity.

## Registry reuse

Audit 2026-10-17: `runtime/bin/ailang pkg search relativity`, `pkg info sunholo/relativity`, `pkg docs sunholo/relativity`; latest and game pin both 0.12.0. Existing optics already owns the needed physical maths. The new work is catalogue annotation and Godot presentation; no `.ail` edits or package release are planned. The AILANG syntax gate therefore does not apply. Project `CLAUDE.md` takes precedence over generic planner advice on validation: full local `make test` is required before merge.

| Milestone | Package | Action | Reason |
|---|---|---|---|
| C1 | `sunholo/relativity` 0.12.0 | depend | Verify endpoints with existing aberration/reference mirrors; add no physical formula |
| C2 | `sunholo/relativity` 0.12.0 | depend | Reuse uploaded observer values, `StarProjection` and apparent-disc geometry |
| C3 | `sunholo/relativity` 0.12.0 | depend | CPU/spec checks provide independent GPU endpoint references |

## Milestones

| ID | Scope and example files | LOC | Dependencies | Acceptance |
|---|---|---:|---|---|
| C1 | Audit endpoint identities from pinned data; author `data/starmap/constellations.json`; add manifest/resolver in `ui/constellation_overlay.gd`; begin `tests/test_constellations.gd` and `make constellation-test` | 220 | Approval | AC1; failing AC2–AC6 cases identify missing integration |
| C2 | Complete overlay module, line layer between sky/hull, projected/clipped segments, apparent-disc masking, muted labels; wire real held/suppression state in `ui/ship_star_identification.gd` and demo setup; update `ui/ship_controls.gd`; expand focused tests | 260 | C1 | AC2, AC4–AC6; no simulation inputs, no hover-only guide activation |
| C3 | `tools/constellation_golden.gd`, `tools/constellation_capture.gd`, `tools/constellation_bench.gd`; wire Makefile/main golden and identification export smoke; changelog and report evidence | 240 | C2 | AC3, AC7–AC9; green targeted/full gates and inspected images |

Each milestone is a bounded executor step. C3's golden, capture and bench runs may be resumed separately; do not mark it passing before all evidence is recorded. Example/showcase coverage is the actual ship driven by `constellation-capture`, rather than a new scene with different projection rules.

## Execution order

1. **Day 1, C1:** tests first for manifest rejection, exact identity/duplicate handling, reduced stacks and normal-stack completeness. Verify named aliases against pinned inputs; keep evidence with endpoint records. Do not download assets in gameplay.
2. **Day 1, C2:** integrate using existing projection and compositor. Finish input, clipping, exposure-cull, rebase, replacement, GR and occlusion cases. Run `make constellation-test ship-star-identification-test`; inspect the first rest/cruise frames before broad capture.
3. **Day 2, C3:** compare line endpoints to GPU star centroids using independent references, including β 0/.5/.9/.99/.999 and translated observers. A temporary one-pixel endpoint mutation must fail. Capture four rest figures, speed/position comparisons, window occlusion, body occlusion, high-speed partial coverage and GR suppression at both resolutions. Open each image and record results. Run the paired warm benchmark and export smoke.
4. **Before landing:** `PATH=$PWD/runtime/bin:$PATH make test`, `make golden`, `make export-filter-audit`, plus new capture/bench/export checks. Resolve failures; request an independent evaluator under the project workflow. Only after passing evaluation, move design/sprint documents to implemented, record measured results/changelog and update roadmap/index status.

## Success and pause points

- P0 **satisfied:** Mark approved this sprint before C1 execution, per `CLAUDE.md`.
- Normal stack resolves all four figures; graceful omissions apply only to actual missing/invisible sources.
- GPU endpoint error ≤0.75 px; no mirrored rear-camera guides, stale view transforms, line leakage through hull or opaque discs, or duplicate replacement endpoints.
- Warm overlay CPU p95 ≤2 ms over ≥300 held-I frames at 1920×1080 on the Studio; no full catalogue scan per held frame; released-I overlay idle.
- Full local/CI checks, export evidence and independent evaluation pass; all new reference images opened.
- No additional discretionary product-approval gate is added. A physics change or inability to resolve the starter figures requires revising this plan rather than silently changing scope.

## Risks and dependencies

Alias audit can consume the estimate; identity uncertainty must be resolved from pinned data, never guessed. Camera PRs can change wiring; re-read the accepted API and retain their bindings. Quiet GPU access is needed for captures/bench. Keep unrelated untracked `.uid` files out of feature changes. The design's explicit limits are part of approval: four starter figures, straight chart connectors, visible endpoints, existing catalogue positions and GR suppression.

## Execution evidence

- C1/C2 complete: 23 audited identities, 35 focused assertions, 59 existing inspection assertions, and the 95-literal export-filter audit pass.
- C3 local verification complete: full `make golden` passes, including 33 constellation cases. A 1.5-pixel endpoint mutation in an isolated temporary copy fails 32 alignment cases. Warm-field rebase invalidation is checked without recreating identities, supplementing the large-coordinate GPU cases.
- Native macOS windows clamp tall capture sizes; review tools now use an exact-size SubViewport. New 1280×720 and 2560×1440 cases cover all four figures, travel/SR, opaque bodies, partial high-speed coverage, actual GR suppression/status and a standing-eye ship view.
- Full pinned-runtime `make test` exits 0 (2026-10-17, 19:05 UTC). Final capture has 32 inspected images. Warm CPU p95 is 0.144 ms held / 0.004 ms released, with zero identity rescans. The packaged native I/card/release/map smoke passes. See [report](constellation-inspection-report.md) and `.ailang/state/evaluations/eval_R1-CONSTELLATIONS_round_1.json`.
- CI-before-merge and landing remain pending; C3's overall `passes` stays null for those external gates. No branch publication, merge or dev release is claimed.
