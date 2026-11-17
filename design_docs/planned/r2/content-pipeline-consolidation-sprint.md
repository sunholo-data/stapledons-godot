# Sprint: CONTENT-PIPELINE-CONSOLIDATION

**Status:** Approved CP1–CP3 locally qualified with combined real-pack evidence and independent review. Remote landing remains open. See [integration report](../../reports/playable-batch-integration.md).
**Design:** [content-pipeline-consolidation.md](content-pipeline-consolidation.md).
**Tracking:** `.ailang/state/sprints/sprint_CONTENT-PIPELINE-CONSOLIDATION.json`.
**Goal:** Verify four current bundles through three explicit adapters, retaining their typed loaders/gates; prove one additional fixture asset passes the same lifecycle.
**Estimate:** ~750 code/test LOC; two active engineering days as a provisional allocation, not a delivery promise. Use small 60–90 minute sessions; split a package if it exceeds one session. Review/integration waits excluded.
**Risk:** Medium: attended dirty work, a more recent painted-level candidate, dynamic raw-file export and native resource serialization.

## Current status and reuse

Design V1–V12 distinguish baseline `f3aa83bf4120fb6f57d858129dd9bada59ed91b4` from untracked painted work and the committed sibling `19e4a76338cb72e88e73a22790239691a72ab439`. Do not reset, clean, stage or overwrite another owner's work. Refresh open PRs and compare source pins before execution; the sibling already includes the raw NPC/portrait `.bin` fix.

Current captain, NPC and deck paths already have source/identity/geometry validation. The new work composes them and adds consistent closure/budget/pack evidence. No new renderer, registry service, AI generation or runtime loader is required. All `content-*` targets below and `painted-levels-test` are **proposed**. Their mention does not mean they exist or passed.

Recent history/CHANGELOG review found predominantly test-maintenance and ledger work (7an, 7am, 7al); no defensible asset-pipeline LOC/day or comparable completion duration. `target_loc_per_day` therefore stays null in tracking. The two-day allocation is a planning assumption with review buffer, not measured velocity. No coverage percentage is claimed; success is the enumerated positive/negative controls.

### Registry reuse audit

Read the sprint-planner skill and registry reuse gate. Read-only registry searches `asset`, `manifest`, `image` succeeded after sandbox DNS failed. `asset` returned none; `sunholo/registry_validator@0.1.2` was inspected with `pkg info`/`pkg docs` and handles AILANG package manifests/exports. Image candidates parse/upload documents or call services. They do not enumerate/inspect Godot resources.

| Package | Decision | Reuse / reason |
|---|---|---|
| CP1 | `none` (new published dependency) | Reuse Godot JSON/FileAccess/HashingContext and existing manifest shapes. No suitable registry asset validator. |
| CP2 | `none` | Reuse Godot Image/resource I/O, existing captain budget checks and existing stages. No new package maths or data transform. |
| CP3 | `none` | Reuse existing ZIPReader/export audits and SCRIPT_GATE shell wiring. No package-level capability to publish. |

No `.ail` changes or showcase modules: AILANG syntax gate is inapplicable. CLAUDE.md's project-specific Godot I/O and focused-gate policy governs execution; generic AILANG-core `make test-changed`/file-size/example conventions are not invented here.

## Milestones and session order

### CP1: Catalog and explicit contracts

**Estimate:** 150 implementation + 135 tests/data = 285 LOC; 0.75 active day. Depends on approval and a reconciled base.

1. Reconcile read-only inventory with the executor checkout; keep exact source/closure baseline evidence. Agree file ownership with active captain/deck work before touching shared stage/make files.
2. Add `art/content-pipeline/catalog.json` with four current records and references to existing provenance, including explicit unavailable model/seed values and separate direction/production review status.
3. Add `tools/content_contract.gd` and `.uid`, `tests/test_content_contract.gd` and `.uid`; three bounded typed enumerators, safe paths, source/runtime separation and deterministic closure digest.
4. Add one additional tiny asset fixture under `tests/fixtures/content_pipeline/` associated with an existing family. It is not a production crowd/animation change.

**Acceptance:** design AC1–AC3 and AC5. Proposed `make content-contract-test` rejects bad schema/kind/IDs, wrong source/closure pins, traversal, duplicate destination and source dependency. An extra fixture asset is counted and corruption fails. Runtime mode works without authoring sources; authoring mode fails on missing required sources. Existing cardinality checks stay intact.

**Risk:** a generic adapter might accidentally follow provenance strings as runtime resources. Only enumerate named consumed fields and native serialized dependencies; fixture both cases.

### CP2: Independent budgets and scratch-stage evidence

**Estimate:** 145 implementation + 120 tests = 265 LOC; 0.75 active day. Depends on CP1.

1. Add `tools/content_check.gd`/`.uid`, `tests/test_content_budget.gd`/`.uid`; recompute file bytes, decoded mip sizes and mesh counts using actual resources.
2. Freeze measured four-bundle baseline caps; retain captain 3 MiB disk/32 MiB decoded per-stage gates. Count shared dependencies once in aggregate reports. Do not infer actual VRAM or frame time.
3. Test independent cap failures and report deterministic machine-readable metrics under scratch storage.
4. Reuse existing staging to isolated scratch destinations; add only a bounded destination option if necessary. Compare two same-input outputs and face hashes. Do not recreate the sibling `.bin` fix or rewrite stages transactionally.

**Acceptance:** design AC4, AC6 and AC7. Proposed `make content-budget-test content-stage-test content-check MODE=authoring`; existing `make captain-anim-test captain-frames-check npc-painted-assets-check npc-painted-test deck-assets-check`; proposed `make painted-levels-test` wraps the current actual-world rollback test. No production outputs/source pins change during check commands.

**Risk:** Godot import prerequisites may write scratch caches. Isolate fixture project/cache paths; compare tracked output/input files before/after. Serializer comparisons use pinned 4.7.2 and semantic geometry checks.

### CP3: Export controls and bounded wiring

**Estimate:** 95 implementation + 105 tests/wiring = 200 LOC; 0.5 active day. Depends on CP2.

1. Add `tests/content_export_audit.gd`/`.uid` and `tests/test_content_pack.gd`/`.uid`; use existing ZIPReader/remap representations and typed dynamic closure enumeration.
2. Hook the audit into `tests/test_export_pack.gd`; add narrow `mk/content.mk` include and bounded SCRIPT_GATE targets. Small fixture tests may join `ci-fast`; full source verification remains targeted/nightly, with no fetch/generation side effects.
3. Add fixtures for missing raw NPC image, portrait witness, texture/material/mesh/manifest and leaked authoring resource/catalog. Keep existing level/civic pack checks intact.
4. Add a changelog entry in this repository's established format and a short report listing commands actually run, expected failures and deferred real-pack evidence.

**Acceptance:** design AC8 and AC10. Proposed `make content-pack-test content-contract-test content-budget-test`; existing `make export-filter-audit level-export-test script-gate-lint uid-guard python-guard`. Every seeded defect fails by name and gate failures propagate nonzero. A complete fixture pack passes. No native build is made by this sprint.

**Risk:** fixture success cannot certify the native pack. Design AC9 remains an explicit later packaging gate: existing `make export-pack-check-strict` must exercise the new audit when an authorized combined review build is prepared. Do not mark AC9 passed from fixture evidence.

## Validation and completion

Use the focused commands per milestone, inspect all failure output, and record exact results in sprint JSON/report. New GDScript files include tracked `.uid` companions. Do not run a GPU capture, Blender render, full suite, native build or publication for this verification-only slice. GitHub `ci-fast` and a different-family evaluator remain required at landing; main's nightly owns the full suite.

Completion means CP1–CP3 pass their focused controls and the report states the real-pack limitation. The overall design is not declared implemented until AC9 is satisfied during separately authorized packaging. Any rendered-resource/physics behavior change falls outside this sprint and requires its established visual/physics review. Keep Mark's current art rulings as rulings; D-139–141 and D-164–165 are not new human-decision gates.

## Approval and stop behavior

There are no unresolved canon decisions. Mark approved CP1–CP3 on 2026-11-17 (tracking JSON approval). The historical pre-execution rule was CLAUDE.md's “Sprint plan … Stop for approval before executing.” That gate was satisfied before execution. If an unattended executor receives them while `approved` is false: **STOP: report `BLOCKED: sprint approval pending` and end the run without mutations.** Do not create a commit merely to document that no implementation was authorized.

If implementation discovers different asset bytes/base ownership or a necessary visual behavior change, stop the affected slice, preserve current work and report the concrete conflict. Approval of this plan must not be interpreted as approval to overwrite other work, regenerate art, alter a cap silently or publish a build.

## Execution checkpoints (2026-11-17)

- [x] CP1: 25 contract checks pass through SCRIPT_GATE, including four real bundle source/closure checks. Red first: absent shared helper failed the gate. Added one retained captain test-image fixture; no new art generated. Runtime mode ignores absent source inputs; authoring mode fails by name. Existing ship-demo/Commons stages were invoked explicitly once to prepare ignored `.bin` witnesses; checks do not stage them. Base refreshed to `ec415f33` before implementation.
- [x] CP2 core: budget30/0, scratch-stage7/0, real authoring check4/0 (92 s), captain-anim87/0. Same-input scratch staging is byte-identical and face-identical; no production output changed. Broader typed regressions are recorded in final evidence.
- [x] CP3: pack19/0; export audit159 literals/0 failures and16 inherited mutants killed; level-export4/0; UID/Python guards and script-gate lint pass. Narrow inherited painted-path classifications added. Top Makefile include is an integrator action; no native export performed.
