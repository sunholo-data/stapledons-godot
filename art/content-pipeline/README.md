# Adding or updating painted assets

Use the existing family pipeline, then record and check its evidence in [catalog.json](catalog.json). The catalog currently has exactly four bundle IDs:
`captain`, `painted-npcs`, `painted-bridge`, `painted-commons`. Their `kind` values
are `captain`, `npc`, and `painted_deck`. Add assets within the appropriate typed
manifest; a fifth bundle or a new kind needs a deliberate contract/test change.
The extension fixture is not installed production art.

## 1. Keep the authoring evidence

Retain the original AI image, prompt, reference/identity images, selection notes,
tool/model/seed information and mechanical processing recipe. Use `not_exposed`
when the provider does not expose model/seed; do not invent them. Follow the existing
captain generation notes, `art/npc-painted-v1/`, or environment `generation.json`.
Keep source evidence under `art/`; runtime files belong in the existing `assets/`
or raw bundle locations. Preserve named crew portraits and authoritative geometry.

## 2. Run the relevant existing authoring command

Run from the repository root in an isolated authoring checkout. These commands write assets; choose the relevant family rather than running every ingest:

```sh
make import
make captain-frames-ingest RAW=path/to/painted-frames GUIDES=path/to/pose-guides
make npc-painted-ingest
```

Captain ingest uses the existing clip/guide contract; NPC ingest uses the retained roster/sheets and current five-identity/25-pose target. It does not add an arbitrary
new person automatically. After NPC ingest, stage the exact raw pose/portrait bytes:

```sh
godot --headless --path . --script tools/painted_levels_stage.gd -- people
```

For decks, the existing builders compile materials onto unchanged native geometry.
Commons needs the bridge authoring resources built first. Preserve the retained authoring inputs; a fresh clone may lack historical compiled intermediates.

```sh
godot --headless --path . --script tools/bridge_painted_finish_build.gd
godot --headless --path . --script tools/commons_painted_finish_build.gd
godot --headless --path . --script tools/painted_levels_stage.gd
```

The last command stages both deck closures and raw NPC images. There is no generic asset builder, AI-generation command or automatic catalog re-pin in this pilot.

## 3. Update the owning catalog record explicitly

Copy the complete shape of the appropriate existing entry in [catalog.json](catalog.json).
Keep `id`, `kind`, `runtime_manifest`, `runtime_manifest_sha256`, `closure_sha256`,
`inputs`, `provenance`, `review`, `budgets`, and `budget_basis`; captain also has
`stage_budgets`. For each new retained source, add one `inputs` record with this shape:

```json
{"path": "res://art/your-pilot/source.png", "bytes": 12345, "sha256": "replace-with-the-actual-64-hex-file-hash"}
```

The example values are placeholders. Measure bytes with `wc -c FILE` and the hash with `shasum -a 256 FILE`. Also update pins for changed prompts, scripts, references
and the runtime manifest. Keep the full recipe in `provenance.processing` and cite
actual appearance/production evidence in `review`; a hash check cannot approve art.

Run `make content-check MODE=authoring`. It reports failures without re-pinning and
writes `.godot/tmp/content-check-authoring.json`, including each bundle's actual
`digest` and independently measured `metrics`. Review the intended changes before
updating `closure_sha256` or budget caps. Resolve every unexpected pin/path error.
Caps have no automatic headroom; `texture_bytes` is an RGBA8 full-mip estimate,
not measured VRAM. Keep captain's 3 MiB disk/32 MiB decoded limit per animation stage;
its still portraits are inventoried separately. Record the reason for cap changes.

## 4. Verify source, runtime and the actual package

```sh
make content-check MODE=authoring
make content-check MODE=runtime
make content-contract-test content-budget-test content-stage-test content-pack-test
make captain-frames-check npc-painted-assets-check npc-painted-test painted-levels-test
make export-filter-audit
make export-pack-check-strict
```

Run the applicable family checks. Authoring mode additionally requires retained
source pins; runtime mode checks runtime closure/budgets without source availability.
Both modes are read-only except scratch reports. Prepare missing raw ship witnesses
explicitly with `make ship-demo-stage ship-commons-stage`; checks do not fetch them.
The final command makes a new headless resource-pack ZIP and audits real bytes,
including imported textures and raw `.bin` witnesses. Fixture ZIPs are not that gate.
Passing checks establishes technical validity. Native appearance, performance and
production acceptance still need their existing review; publication is a separate action.
See the [implementation evidence](../../design_docs/planned/r2/content-pipeline-consolidation-report.md).
