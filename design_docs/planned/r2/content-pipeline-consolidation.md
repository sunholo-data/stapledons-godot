# R2: Content pipeline consolidation

**Status:** Approved 2026-11-17; CP1–CP3 verification pilot implemented, awaiting integration/evaluation and real-pack AC9. See [execution evidence](content-pipeline-consolidation-report.md). Created from Mark's attended request for a concrete plan to consolidate AI-authored captain, environment and NPC resources before implementation.
**Release:** r2 · **Milestone:** new; no roadmap row yet.
**Priority:** P2. Make the existing painted-content paths reproducible and reviewable without blocking their current art reviews.
**Implements:** [AI showcase](https://github.com/sunholo-data/stapledons-design/blob/c0ff15282dbdf4e82ceae47aafa6b1efcddf96aa/features/ai-showcase.md) §§3–5 (identity, generated assets and recorded selection), [ship exploration](https://github.com/sunholo-data/stapledons-design/blob/c0ff15282dbdf4e82ceae47aafa6b1efcddf96aa/features/phase2-core-views/ship-exploration.md) “Ship Layout Philosophy”, and ledger D-7, D-18, D-139–D-141, D-164–D-165. Only the offline, authored-resource part is in scope.
**Depends on:** Godot 4.7.2; the existing captain/NPC/deck tooling; reconcile the painted-level candidate at `19e4a76338cb72e88e73a22790239691a72ab439` with the implementation base before changing its staging/export files. No AILANG dependency bump.
**Estimated:** 650–850 code/test LOC in three bounded work packages; no new art generation. Estimates are planning ranges, not measured velocity.
**Evidence:** V1–V12 below. Tracked baseline `f3aa83bf4120fb6f57d858129dd9bada59ed91b4`; canon `c0ff15282dbdf4e82ceae47aafa6b1efcddf96aa`. Untracked painted work is separately hash-pinned in V10 and must not be attributed to that baseline commit.

## Game vision alignment

Scored using `game-vision-designer` against the pinned [core pillars](https://github.com/sunholo-data/stapledons-design/blob/c0ff15282dbdf4e82ceae47aafa6b1efcddf96aa/vision/core-pillars.md).

| Pillar | Relevance | Score | Mechanism |
|---|---|---:|---|
| Choices Are Final | 0 | 0 | Offline content validation introduces no player save, reload or outcome preview. |
| The Game Doesn't Judge | 0 | 0 | Acceptance refers to art production, never moral scores or endings. |
| Time Has Emotional Weight | + | +1 | Captain age-stage and named-crew identity bindings remain checked when their files move through packaging. |
| The Ship Is Home | ++ | +2 | Painted people and both decks retain their current identities, complete surface coverage and native interaction points. |
| Grounded Strangeness | + | +1 | Explicit identity/style references make one additional authored asset possible without a second loading framework. |
| We Are Not Built For This | 0 | 0 | No resilience, psychology or animation-state changes. |
| Hard sci-fi authenticity (spec) | + | +1 | Deck adapters retain face hashes, live sky/light ownership and existing physical acceptance gates; a texture cannot replace geometry. |
| **Net** | | **+5** | **Go for a small offline consolidation.** No canon change. |

## Problem

There is already a workable pipeline, but its common evidence is scattered rather than absent (V2–V7).

| Existing path | What is already strong | Gap this design closes |
|---|---|---|
| Captain | Manifest file pins, age/facing/crop contract; `captain_frames.gd` checks guides, palette, planted feet and per-stage budgets. | Animations and stills need one explicitly enumerated export closure; generation history is prose and per-pilot records. |
| Painted NPC | Preserved source/prompt records, 25 pose pins, portrait/style bindings; decoded alpha/anchor tests and guarded install. | A source checker and a packed runtime checker need different input availability. Successful source validation alone does not prove raw images survive export. |
| Painted decks | Source/resource/mesh pins, face-identity checks, complete target coverage; combined installer rolls back both decks on late NPC failure. | Staging repeats common pin/closure work; recorded resource totals need independent measurement and consistent reporting. |
| Distribution | Content-addressed D-18 downloads and existing literal, level and civic pack audits. | Dynamic painted resource references need an explicit expected closure in the real pack audit. |

The sibling painted-level candidate already fixes a real packaging detail: images read with `FileAccess` are staged as raw `.bin` bytes, including the portrait witnesses (V7). Recreating that work, replacing the typed loaders or migrating every asset in the game would enlarge this task without solving a measured gap. The older canon “asset-pipeline-hardening” document describes the retired Go/Ebiten renderer; its sprite-ID/audio-manager proposal is not a Godot implementation plan (V9).

## Goals and non-goals

**Goals:** one small authoring inventory for the three existing resource types (four bundle records); consistent provenance, pin, closure and budget checks; independent packaged-byte evidence; preserve all stronger type-specific checks. Demonstrate adding one additional asset through a fixture before extending production content.

**Non-goals:** a registry service, universal runtime loader, asset database, schema migration of every manifest, new image generation, animation or room redesign, remote fetching during play, new publishing infrastructure, changing runtime cache/replay policy, physics/sim/protocol work, or changing an art approval. The initial sprint does not generalize audio, sky, planets, portraits outside these bundles, or AI-generated narrative content.

## Design

Add a small authoring catalog and a shared verification helper around the existing typed contracts; keep their loaders and staging algorithms.

### D1. Boundaries and authority

Package maths, `sim/core.ail`, `sim/ship.ail` and NDJSON are unchanged. No new formula or RS/HB value is introduced. The [relativity spec](https://github.com/sunholo-data/stapledons-design/blob/c0ff15282dbdf4e82ceae47aafa6b1efcddf96aa/physics/relativity-spec.md) §§2/4 and [Higgs bubble](https://github.com/sunholo-data/stapledons-design/blob/c0ff15282dbdf4e82ceae47aafa6b1efcddf96aa/physics/higgs-bubble.md) §§2/6 remain authoritative over every artistic choice. In particular, keep live sky, physical light, WALK/collision, cameras and interaction geometry under their existing owners.

D-7's first-use generation and recorded AI result selections remain the responsibility of the AI service, outside this offline slice. File provenance does not satisfy replay recording by itself. A future runtime-library design must preserve recorded asset IDs/content hashes rather than selecting a different image on replay.

### D2. A catalog, not a new runtime manifest

**Proposed** `art/content-pipeline/catalog.json`, schema `stapledons.content.catalog/1`, has exactly four initial entries: `captain`, `painted-npcs`, `painted-bridge`, `painted-commons`. Three explicit adapters are sufficient: captain, NPC, painted deck (parameterized by deck). Do not discover or migrate every manifest in the repository.

Each entry contains:

| Shared authoring field | Contract |
|---|---|
| `id`, `kind`, `runtime_manifest` | Stable unique ID, one of the three supported kinds, canonical existing manifest path. Reject unknown kinds and duplicate IDs. |
| `provenance` | References and sha256 pins for existing notes/generation JSON, prompt files and style/identity inputs. Preserve their full records in place; do not duplicate full prompts. Record generator/tool, reported model/seed or explicit `not_exposed`, source revision/script digest and mechanical processing command. Never invent unavailable model IDs or seeds. |
| `inputs` | Explicit source path + sha256/bytes; large masters may use their existing D-18 URI/pin. Required for authoring checks, absent from the runtime dependency graph. Historical unavailable masters are recorded as unavailable and cannot claim reproducibility. |
| `runtime_manifest_sha256`, `closure_sha256` | Manifest pin and digest over sorted records of canonical runtime path, file-byte sha256 and bytes. Enumerate through the typed adapter; do not maintain another handwritten list of every frame/mesh. |
| `review` | Separate direction/appearance ruling and production/native-review status, each with an actual D-row or evidence reference. Checking hashes must never advance an approval. |
| `budgets` | Explicit ceilings with units and provenance, scoped by stage or bundle; the independent report measures actual files/resources. |

The catalog is authoring/test input and is excluded from shipping. Existing runtime manifests stay readable by existing loaders. Existing provenance strings in those manifests can remain; the closure follows fields actually consumed as resources, not arbitrary strings that happen to contain `art/`. Do not delete guide/source metadata or invent a runtime authoring dependency to make a clean split look tidier.

The helper **proposed** `tools/content_contract.gd` exposes only plain validation/enumeration functions and named errors. It uses Godot JSON, file/hash, image and resource I/O, already used by these pipelines. No Python pipeline and no new AILANG package are warranted for this small file/resource I/O layer (V12). Keep adapters explicit, in `tools/content_check.gd` or a companion if size/readability calls for it; no plugin registration mechanism.

### D3. Shared checks and type-owned checks

| Shared helper | Existing type owner remains responsible |
|---|---|
| Parse, supported schema/kind, unique IDs, safe canonical paths within declared roots, finite nonnegative counts, bytes/hash checks, deterministic closure order. Reject absolute/home paths, traversal, duplicate destinations and unresolved dependencies. | Captain: stage/facing coverage, gait cycle and contacts, crop/anchor, guide IoU, palette and foot-slide checks. |
| Deduplicate resources by canonical runtime path; count a shared texture once per installed closure, with separate per-stage/bundle reports. Use `ResourceLoader.get_dependencies` recursively for native resources, resolving serialized external dependencies; also enumerate dynamic/raw paths in the adapters. | NPC: canvas/alpha, height/feet, required poses, entity/portrait/style bindings, floor support and view-facing choices. |
| Separate authoring availability from runtime availability. Runtime checks require only packaged resources; source checks require pinned inputs or an explicitly requested master fetch. | Deck: target keys, source and cooked face hashes, complete family coverage, material/shader ownership, no added bodies/lights/triangles, existing install/remove/rollback. |
| Check review references/status structure, never infer visual approval from a successful command. | Existing fixed cardinalities (five identities/25 poses, current mesh coverage) stay in their production gates. |

Relative paths resolve against the owning manifest. UID references resolve through Godot and their canonical file identity. Reject any transitive runtime dependency on `art/`, `tools/`, `tests/`, `renders/` or the source checkout's `.godot/imported/`; allow Godot's valid packed import/remap representation through the existing pack oracle. A textual source citation is not a runtime resource dependency. Count missing dependencies as failures, never skips.

The extension example is one additional small fixture asset under `tests/fixtures/content_pipeline/`, associated with an existing family and omitted from the shipped catalog. It proves enumeration, byte/budget accounting and rejection on corruption without changing the production NPC population, generating art or weakening its 25-pose gate. No fourth adapter is required.

### D4. Budgets are measured at the right level

Keep the captain's current **3 MiB on disk / 32 MiB decoded with mipmaps per animation stage** and existing silhouette/palette/stance limits (V3). Do not replace a per-stage limit with an aggregate allowance. Inventory other captain stills separately before setting an explicit baseline cap; stage-0 ceilings do not silently authorize all stills.

For NPCs, decode the current 192×288 RGBA pose files, sum each unique image's real mip chain, and report portrait witnesses separately. For painted decks, load textures/meshes to recompute sizes and counts rather than trusting manifest totals. V6 records 141 bridge meshes/193,150 indexed vertices/212,308 triangles and 1,000 Commons meshes/661,166 vertices/769,386 triangles. Recorded texture totals are 30,753,700 and 30,756,340 bytes; these are metadata, **not measured VRAM or a performance pass**.

The first implementation check records actual disk bytes, maximum image dimension, decoded texture bytes with mipmaps, unique resources, mesh/surface/triangle/vertex counts for those four bundles. Catalog caps freeze that independently measured baseline with no automatic growth allowance. Re-staging the unchanged baseline must fit exactly; any changed encoding needing more bytes requires an explicit reviewed cap edit. These new baseline caps supplement, rather than relax, existing captain and deck-layout budgets. Aggregate installed texture reporting deduplicates dependencies shared across bundles. Shader/material/node counts remain type-specific metrics where meaningful; this is not a promise about frame time.

Do not reduce mesh, image or physics quality to pass a new cap. GPU memory/performance acceptance stays with R2-VIEW-FINISH and its existing platform measurements. No GPU work is part of this design/planning task or the initial verification-only sprint.

### D5. Author → verify → stage → install → export

1. **Author:** preserve raw output, prompt/reference/generator records and selection history using existing pilot directories. AI generation is nondeterministic; promise exact retained outputs and deterministic mechanical staging, not identical re-generation from a prompt.
2. **Verify:** proposed `make content-check MODE=authoring` enumerates the four records, validates source and output pins, emits machine-readable metrics, and invokes the existing typed checks through bounded `SCRIPT_GATE` targets. It never generates, downloads, installs, re-pins or writes production assets. Missing authoring inputs fail with a named fetch/manual-recovery requirement.
3. **Stage:** retain `captain-frames-ingest`, `npc-painted-ingest`, civic staging and `painted_levels_stage.gd`. Reconcile the sibling's raw-image fix first. Existing stages remain explicit mutations. This sprint adds verification around them; a broader transactional rewrite is deferred. Run the existing stage to a scratch destination for reproducibility evidence, not into the attended checkout during tests. If the tool needs a destination option, add only that bounded option. Pin two byte-identical staged closures on the same pinned Godot version, and independently compare deck faces; do not confuse byte equality with geometry equality.
4. **Install:** retain current typed loaders and `PaintedLevelsFinish`'s all-or-rollback installation. Shared verification cannot install or mark a pilot production-approved. The existing malformed/duplicate/missing-NPC controls still prove state restoration.
5. **Export:** proposed `make content-check MODE=runtime` checks only the installed runtime closure. Extend `tests/test_export_pack.gd` with an external painted-content audit using the same enumerator and the existing ZIPReader/remap conventions. Missing dynamic raw PNG `.bin`, portrait witness, texture, material, mesh or runtime JSON fails. Production source resources and the authoring catalog must be absent from the real pack. Keep `export-filter-audit` and `export-pack-check-strict`; a source-tree check is not a substitute for either.

D-18 remains distribution policy. Small runtime files keep their current git/staging arrangement; large masters continue through content-addressed bucket pins and explicit authoring fetches. No upload command is added or run by `content-check`; no auto-generation fallback is introduced. Normal dev builds remain a single current-main-based update through `publish-dev`, installed with `tools/install_review_build.sh --dev`. This plan does not authorize a build or publication.

## Acceptance criteria

These commands were proposed at design time. CP1–CP3 now implement the pilot gates in `mk/content.mk`; the execution report records actual results. The integrator adds its top Makefile include. AC9 remains unexecuted; existing gate names are unchanged.

| ID | Checkable result | Command |
|---|---|---|
| AC1 | Four bundle records resolve through three explicit adapters; current runtime manifest/closure pins and provenance references check, with no source writes. | **Proposed:** `make content-check MODE=authoring` |
| AC2 | Missing/wrong source pin, unknown kind/schema, duplicate ID/destination, path traversal and transitive authoring dependency each fail for their own named reason. | **Proposed:** `make content-contract-test` |
| AC3 | Extra fixture asset is enumerated and changes closure bytes/digest; removing or corrupting it fails; production fixed-count checks are preserved. | **Proposed:** `make content-contract-test` |
| AC4 | Reports independently measure unique disk/decoded/mip/resource and mesh counts; fixtures exceed each configured ceiling and fail; existing captain stage caps remain 3/32 MiB. | **Proposed:** `make content-budget-test`; existing `make captain-frames-check deck-assets-check` |
| AC5 | Runtime validation succeeds without authoring inputs and rejects missing runtime resources; authoring mode rejects absent required source inputs. Neither mode re-pins or generates. | **Proposed:** `make content-contract-test content-check MODE=runtime` |
| AC6 | Same-input scratch staging twice produces identical closure hashes; source pins stay unchanged and painted faces are identical. No generation/network/GPU step occurs. | **Proposed:** `make content-stage-test` |
| AC7 | Type-owned identity/animation/install behavior survives; a late NPC failure restores both decks, collisions, WALK and cameras. | Existing `make captain-anim-test captain-frames-check npc-painted-assets-check npc-painted-test`; **proposed:** `make painted-levels-test` wrapping current `tests/test_painted_levels.gd` |
| AC8 | Pack-audit fixtures pass with complete closure and reject missing dynamic raw image, portrait, resource, manifest and leaked authoring files. | **Proposed:** `make content-pack-test`; existing `make export-filter-audit level-export-test` |
| AC9 | Existing real-pack oracle checks the four dynamic closures; strict publication gate counts no skips. Run only during later packaging work, not this initial verification sprint. | Existing `make export-pack-check-strict` after the new audit hook |
| AC10 | Validation targets use bounded SCRIPT_GATE wiring, report nonzero on errors, and preserve policy/UID checks. | Existing `make script-gate-lint uid-guard python-guard`; **proposed:** `make content-contract-test content-budget-test content-pack-test` |

No visual behavior changes are intended. If implementation changes rendered resources, geometry, light, camera or animation, stop that slice and route it through the existing visual/physics design and Mark's dev-build review; do not claim this verification-only sprint approves it. GitHub `ci-fast`, focused local gates and cross-family evaluation remain the merge requirements; full suite/nightly and GPU policy stay as specified in CLAUDE.md.

## Sub-milestones and estimates

| Package | Scope / example files | Code + tests | Dependency / boundary |
|---|---|---:|---|
| CP1 | Catalog + provenance references; `tools/content_contract.gd`, `.uid`, `tests/test_content_contract.gd`, `.uid`, one extra fixture asset. Explicit adapters over existing four records. | 250–320 LOC | Reconcile implementation base and ownership; no loader or asset-byte changes. |
| CP2 | Independent budget/closure report and scratch-stage controls; `tools/content_check.gd`, `.uid`, `tests/test_content_budget.gd`, `.uid`, bounded destination option only where needed. | 230–300 LOC | CP1; same Godot serializer version; preserve existing typed checks. |
| CP3 | Pack-fixture audit hook and bounded make targets; `tests/content_export_audit.gd`, `.uid`, `tests/test_content_pack.gd`, `.uid`, `tests/test_export_pack.gd`, narrow `mk/content.mk` include and changelog. | 170–230 LOC | CP2; reuse sibling raw-image staging, existing ZIPReader conventions. Real pack AC9 stays later packaging evidence. |

Total 650–850 LOC; midpoint 750. Initial sprint covers CP1–CP3 with fixture/headless evidence only. No global migration, new server, asset generation, native build or publication. The additional fixture demonstrates one asset through the catalog; any broader expansion follows evidence from this pilot.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Attended checkout and painted-level sibling differ. | V1/V7/V10 identify both; integrate the committed candidate intentionally before implementation and re-measure pins. Never clean/reset or sweep unrelated assets into the change. |
| Catalog becomes another conflicting pin authority. | Existing typed manifests remain authoritative; derive closure rows, store only their digest/manifest pin and catalog-level caps. Changes must update source evidence explicitly, never via test auto-pin. |
| Imported textures work in source but not in the pack. | Reuse `.bin` witness staging and existing remap/ZIP audits, with missing-image negative controls. AC9 remains mandatory when a build is actually prepared. |
| Native `.res` serialization differs by Godot version. | Pin 4.7.2 for same-input staging comparison; retain semantic face/image checks. Do not promise cross-version binary identity. |
| Legacy provenance lacks a model/seed/master. | Record `not_exposed`/unavailable and its source record. Fail only claims that require an unavailable input; do not fabricate provenance or demand another paid generation. |
| Common checker weakens a family gate. | Compose existing commands and controls; never replace palette/foot/portrait/face checks with hashes. |
| Expensive checks creep into CI or regenerate assets. | Fast fixture tests only in `ci-fast`; full four-bundle source verification stays targeted/nightly. Registry calls, generation, fetch and stages are never hidden prerequisites of a read-only check. |

## Open questions for Mark

None about canon or already-ruled art direction. Implementation approval was given by Mark on 2026-11-17; CP1–CP3 were executed under CLAUDE.md's design → sprint → execute cycle. The bounded verification pilot is approved and complete. Broader catalog expansion/new asset production remain outside its scope; real-pack acceptance and landing remain pending.

## Deliverables

This design, a proposed sprint and tracking JSON; after approval, the four-entry authoring catalog, three adapters/shared helper, independent budget/closure reports, one extension fixture, pack negative controls and focused make wiring. The later implementation report must distinguish headless fixture evidence from real-pack, native visual and performance acceptance. No design-repo change is needed; the old Go asset-pipeline proposal is not superseded silently.

## Verification log

Read-only audit on 2026-11-17. No Godot run, GPU use, build, generation, publication or commit occurred. Rows describe inspected implementation, not executed green tests.

| # | Claim | Command / inspected evidence | Result |
|---|---|---|---|
| V1 | Working baseline and dirty work are distinct. | `git rev-parse HEAD`; `git status --short`; `git -C ../stapledons-design rev-parse HEAD` | Game `f3aa83bf4120fb6f57d858129dd9bada59ed91b4`; canon `c0ff15282dbdf4e82ceae47aafa6b1efcddf96aa`. Existing sprint/ledger edits and untracked captain/environment assets/scripts preserved. |
| V2 | Runtime/authoring records already exist. | Read `assets/characters/captain/{manifest.json,generation_notes.md}`, `art/npc-painted-v1/{roster.json,provenance.json}`, `tools/npc_painted_assets.gd:1–132`, environment `generation.json` | Existing generation notes record tool, prompts, references, selections and unavailable model/seed; NPC ingest/validator pins source/style/portrait/poses. No need to invent another generation system. |
| V3 | Captain has meaningful existing stage gates. | `rg -n 'DISK_STAGE_MAX\|GPU_STAGE_MAX\|STANCE_PX_MAX' tools/captain_frames.gd`; read `mk/captain-anim.mk:1–25`, `interior/captain_anim.gd:1–130`; `jq 'keys' assets/characters/captain/manifest.json` | 3 MiB disk / 32 MiB decoded stage caps; 2 px base stance limit; guide/palette/selftest gates. Manifest has `files` and `anim`; pure presentation state uses distance-driven phase. |
| V4 | NPC install validates runtime witnesses separately from source checker. | Read `demos/painted_npc_pilot.gd:14–89`, `tools/npc_painted_assets.gd:96–132`, `mk/npc-painted.mk` | Loader checks schema, canvas/anchor, portrait pins and pose bytes; source checker additionally needs preserved authoring sources/style. Five identities/25 poses are an explicit production target. |
| V5 | Existing deck install is typed and atomic. | Read `demos/{bridge,commons}_painted_finish.gd`, `demos/painted_levels_finish.gd`, `tests/test_painted_levels.gd` | Coverage and face pins guard geometry; combined installer rolls back both decks on failed NPC install. Test inspects source meshes, WALK, camera and collision-body count. Read, not run. |
| V6 | Candidate deck sizes are known metadata. | `jq '{schema,triangles,paint_vertices,texture_bytes_with_mips,mesh_count:(.meshes|length)}' assets/levels/painted/{bridge,commons}/manifest.json` | Bridge: 141 / 212,308 triangles / 193,150 vertices / 30,753,700 texture bytes; Commons: 1,000 / 769,386 / 661,166 / 30,756,340. Not independent decoded measurements. |
| V7 | Sibling has packaging work absent from local untracked stage. | `git -C ../stapledons-godot-painted-levels rev-parse HEAD`; read its `tools/painted_levels_stage.gd`, log last three commits | Clean sibling `19e4a76338cb72e88e73a22790239691a72ab439`; `7003783c` adds raw NPC/portrait `.bin` staging; local tool lacks `_people`. Candidate also closes the review package. Consulted read-only. |
| V8 | Existing export/staging/distribution infrastructure is reusable. | Read `tools/commons_civic_stage.gd`, `tests/{export_audit,test_export_pack,level_export_audit,commons_civic_export_audit}.gd`, `export_presets.cfg`, `tools/sky_assets.sh`, Makefile `export-pack-check*` | Explicit pin/stage maps, ZIPReader audits, strict no-skip publish gate, content-addressed D-18 transfer all exist. Export all-resources plus dynamic raw-file includes means source literals alone are insufficient. |
| V9 | Relevant canon and rulings constrain scope. | Read project/design skills, core pillars, relevant decision/open-question entries, normative spec, R1 roadmap, ADR 0001, AI-showcase, old asset-pipeline-hardening; inspect D-7/18/139–141/164–165 | Godot owns rendering/I/O, AILANG sim stays pure; painted identities and whole-room direction already ruled; native performance/visual acceptance remains separate. Old asset-pipeline-hardening names Go/Ebiten code and is not reusable architecture. |
| V10 | Untracked candidate inspection is reproducibly identified. | `shasum -a 256 tools/painted_levels_stage.gd demos/painted_levels_finish.gd tests/test_painted_levels.gd assets/levels/painted/{bridge,commons}/manifest.json` | Stage `f174470ee889dfa19cf8c3f7ce4c687c23915631c9b9202f7bbc0342cbcfb788`; combined install `2d28fb308e7225b4eae5f805c36b20f7cbec6f902e4831a90903ceaf559397a0`; test `b8266aaf2aaaa1ae311b1a9ce116d317b4034d53f23a996b3904d5207edfbd1b`; bridge manifest `bac1e9d99a53da8c69f1550660a9c5b0d3621dbfb3ffe00b2c5a88834120a7d1`; Commons `c4472c8c4fa851e171da696346150676cf02eb777dcbd58e228980ebd5ef447e`. |
| V11 | Open PRs do not currently duplicate this slice. | `gh pr list --repo sunholo-data/stapledons-godot --limit 30`; same for design repo (read-only network escalation after sandbox DNS failure) | Game #435 (reasons detector), #380/#373 (Kerr); canon #49 (Kerr spec). No pipeline PR listed. Re-check before execution because this is a dated snapshot. |
| V12 | No suitable published package should replace Godot file/resource checks. | `runtime/bin/ailang pkg search asset`, `manifest`, `image`; `pkg info` / `pkg docs sunholo/registry_validator` (read-only network escalation) | Asset search empty; manifest candidate `registry_validator@0.1.2` validates `ailang.toml` and `.ail` exports, not Godot assets. Image results are document parsing/upload/service packages. Reuse Godot APIs and repo helpers; no package/dependency change. |
