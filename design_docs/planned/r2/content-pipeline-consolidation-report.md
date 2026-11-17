# CONTENT-PIPELINE-CONSOLIDATION implementation evidence

2026-11-17, isolated clone `/private/tmp/stapledons-playable-content-20261117`, branch `sprint/playable-content`. Approved CP1–CP3 executed against refreshed integration `ec415f33` (painted candidate ancestry `19e4a763`). Existing attended/sibling work was not modified. This is executor evidence, not an independent evaluation or native visual approval.

## Result

Four catalog records use three explicit adapters. Runtime loaders/manifests/production asset bytes are unchanged. New checks enumerate explicit consumed fields plus serialized native resource dependencies; provenance text is not a dependency. Authoring mode requires source pins, runtime mode does not. Byte/decoded budget reports keep the existing captain animation stage's 3 MiB/32 MiB limits and separately inventory its larger still set. Source generation metadata honestly retains unavailable model/seed information.

The existing stage gained only a restricted scratch source/destination option under `res://.godot/tmp/`, enabling the same stage algorithm to run twice on a retained test fixture. Both stages produce byte-identical outputs and exact source faces, without changing source pins. This is representative stage evidence; a full re-generation of all historical art/authoring compiled meshes is not claimed.

The new pack audit runs externally from the source checkout and joins `tests/test_export_pack.gd`. It checks every typed closure member, exact raw-byte pins, and imported texture remaps against the local pinned import representation. Missing local import witnesses fail closed. Fixture ZIPs are small synthetic records, not new native game exports. The inherited three unclassified painted paths were reproduced and resolved with one dynamic row and two exact source-default rows; removing the native include is a killed control.

## Focused validation

All new Godot gates ran through `tools/script_gate.sh`, checking exit code, no `SCRIPT ERROR`, a positive result count and a timeout. Red-first failures were recorded before adding contract/metrics/pack helpers; the scratch-stage test failed before its destination option existed.

Until the integrator adds `include mk/content.mk` to the top Makefile, invoke new targets with `make -f Makefile -f mk/content.mk …`. No top Makefile change is included in this branch.

| Gate | Result |
|---|---|
| `content-contract-test` | 22 passed, 0 failures; fixtures need no staged game witnesses. |
| `godot --headless --path . --script tests/test_content_contract.gd -- --current` through SCRIPT_GATE | 26 passed, 0 failures, including all four real bundles and authoring pins. |
| `content-budget-test` | 30 passed, 0 failures; every metric has a killed ceiling control, including malformed/non-finite caps. |
| `content-stage-test` | 7 passed, 0 failures; two scratch stages, exact faces, unchanged manifest/resource pins. |
| `content-pack-test` | 19 passed, 0 failures; complete raw/imported fixtures and missing/corrupt/raw/portrait/native/manifest/remap/leak controls. |
| `content-check MODE=authoring` | 4 bundles, 0 failures, 92 s. Existing ship-demo/Commons raw stages were run explicitly beforehand to ignored bundle directories. The check itself does not stage them. |
| `content-check MODE=runtime` | 4 bundles, 0 failures, 91 s. No authoring input is required by this mode. |
| `captain-anim-test` | 87 passed, 0 failures. |
| `captain-frames-check` | 50 frames plus the 50-frame selftest pass; existing stance/palette/stage caps retained. |
| `npc-painted-assets-check`, `npc-painted-test` | Five identities/25 poses validated; pilot 23 passed, 0 failures. |
| `painted-levels-test` | 1,168 passed, 0 failures. Existing actual-world install, late-NPC rollback, camera/WALK/collider preservation, lift round trip and restoration assertions retained; added only a counted SCRIPT_GATE summary. No sim journey started. |
| `deck-assets-check` | 12 pins/budgets and wrong-pin/emissive-prop controls pass; its VRAM probe explicitly skips in headless mode. |
| `export-filter-audit` | 159 literals, 84 R / 18 F / 33 D / 24 X, 0 failures; all 16 inherited mutants killed. Previously three unclassified painted roots failed this gate. |
| `level-export-test` | 4 passed, 0 failures. |
| `uid-guard`, `python-guard` | Pass (483 UIDs at check time; 25 Python allowlist entries, no new Python). |
| `script-gate-lint` | Pass with the one proposed include temporarily inserted solely for validation, then top Makefile restored. 287 invocations, 169 guarded, 118 inherited baseline; 38 includes/39 makefiles; existing prerequisite controls pass. |
| `git diff --check` | Pass. |

Logs are retained under `/private/tmp/content-*.log` and `.godot/tmp/content-*.log`; machine-readable full reports are `.godot/tmp/content-authoring.json` and `.godot/tmp/content-check-runtime.json`. The local sandbox emits a macOS certificate-query warning and editor-settings write errors during the inherited import prerequisite; the focused gates above still finish with their stated result and no script errors. No credentials, external messages or network generation were used.

## Independent decoded baseline

These are RGBA8-equivalent full-mip estimates, **not actual VRAM or frame-time measurements**. Raw geometry witness bytes count toward disk; duplicate paths shared between bundles count once in the aggregate.

| Bundle | Files | Disk bytes | Decoded texture bytes |
|---|---:|---:|---:|
| Captain | 67 | 13,697,815 | 141,951,200 |
| NPCs | 28 | 1,136,462 | 8,071,548 |
| Bridge | 151 | 27,397,104 | 30,753,700 |
| Commons | 1,008 | 27,571,008 | 30,756,340 |
| Aggregate (deduplicated) | 1,252 | 69,797,998 | 211,532,788 |

Captain stills: 12,217,078 disk / 134,217,664 decoded bytes, separate from animation stage y0: 1,441,648 / 7,733,536. Deck geometry independently measures 141 bridge meshes / 212,308 triangles / 193,150 vertices and 1,000 Commons meshes / 769,386 triangles / 661,166 vertices. Catalog caps freeze this baseline without automatic headroom or quality reduction.

## Remaining acceptance

- **AC9 now passes for the source-clone pack:** see the follow-up below. The parent combined integration/native build must still validate its own exact bytes; no native app, GPU acceptance or publication is claimed.
- The integrator must add exactly `include mk/content.mk` to the top Makefile and rerun its normal focused integration gates. The new fragment adds only small budget/pack fixtures to `ci-fast`; the full four-bundle scan is targeted, not a hidden CI regeneration step.
- Cross-family evaluation, GitHub fast-tier status and Mark's combined native visual/performance review remain with the integration owner. The design stays under `planned/` until its outstanding packaging/landing requirements are met.

CP1 and CP2 committed as `211fd52b` and `42eeb816`; CP3 records this evidence. The original 750 LOC estimate excluded the size of retained pin data; no measured LOC/day or calendar velocity is inferred from this single run.

## AC9 follow-up: fresh headless resource pack

Mark authorized local pack validation on 2026-11-17 after the initial pilot. In this same isolated source clone at `352552aa8990044e9df0a28b73b38030ca963794`, `make export-pack-check-strict` created a **new** `.godot/tmp/export-pack/game.zip`. It was not copied from the older sibling archive. Godot headless `--export-pack` requires no export templates and does not run the sim journey or use a GPU window. No native `.app` or publication was made.

Preparation copied only known ignored runtime/bundle inputs: `runtime/` from the integration clone; `areas_bundle/`, `audio_bundle/`, `observation_bundle/`, `planet_bundle/`, `ai_core/` and the two lens `.bin` files from the clean painted-level candidate. Existing ship bundle witnesses had already been staged locally; the make target ran its existing civic stage. The copied lens files match committed pins `69cf728d…` and `419c0fd5…`. No new generation or network fetch occurred.

The initial strict audit found **66 failures**, all captain imported textures. Inspecting the actual ZIP showed that Godot 4.7.2 packs texture metadata as `<image>.import` plus `.godot/imported/<image>-<hash>.ctex`; the new auditor had assumed the script/scene `.remap` convention. This was a demonstrated audit bug, not missing art. The fixture now reproduces the observed `.import` format, including its terminating NUL, importer/type fields and external texture path. It failed before the fix. The auditor accepts this measured representation while retaining exact imported target-path and byte-hash checks. Controls also reject missing/corrupt imported textures, an incorrect importer and a valid raw source attempting to mask a corrupt active imported texture.

- `make -f Makefile -f mk/content.mk content-pack-test`: **24 passed, 0 failures**.
- `sh tools/script_gate.sh content-real-pack /private/tmp/content-ac9-strict.log 180 '^export-pack-check: [1-9][0-9]* checked, 0 skips, 0 failures$' -- STRICT=1 godot --headless --path . --log-file /private/tmp/content-ac9-strict-engine.log --script tests/test_export_pack.gd -- .godot/tmp/export-pack/game.zip`: **2,869 checked, 0 skips, 0 failures**, 15 seconds, rc 0, no script errors.
- Pack: **336,137,617 bytes**, SHA256 **`9b26623d9224f2d2283de1329278ae7cfa11fb6d0d89e888721b646abd9d9975`**, generated 2026-11-17 at 08:53 local time. Lens SHA256 pins were independently rechecked.

Only excluded test/audit files changed after the export, so the corrected strict auditor checked the same new package bytes without an unnecessary regeneration. This closes the pilot's AC9. It does **not** validate the parent's later combined integration commit (`48120f99` plus subsequent ship work), a native app, visual performance or publication. The ignored pack remains available in this clone; it is not committed.
