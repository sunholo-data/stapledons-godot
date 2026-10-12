# Export completeness: every data path the shipped code reads survives the export filter

**Status:** Implemented 2026-10-12 (mission iteration 26; sprint R1-L6-EXPORT-COMPLETENESS, evaluator Sonnet r1 84/100 PASS). The first real `publish-dev` with the strict pack gate runs attended.
**Release:** r1
**Milestone:** charter triage row L6 (clause 5 hygiene)
**Priority:** P1. It is next in the charter order (L1 → **L6** → L2 …), and dev.23 shows what this costs: a dev build where Sgr A* drew nothing.
**Implements:** `design_docs/stapledon-mission.md` triage row L6. It touches no design-repo feature or physics-spec section. It protects the delivery of the GR lens tables (`physics/schwarzschild.gd`, M3.2), but no physics changes.
**Depends on:** nothing new. It uses Godot 4.7.2 (`ConfigFile`, `RegEx`, `String.matchn`, `DirAccess`, `ZIPReader`), the existing `import` target and `export_presets.cfg`.
**Estimated LOC:** about 250. The parts are:

- the audit, about 140 (measured `AUTO_EXT` forms and the non-resource-witness rule);
- its test with 16 mutants, about 65;
- the pack oracle, about 35 (measured `.gdc`/`.scn` + `.remap` forms);
- the Makefile and preset changes, about 10.
**Planner-Lane:** pi:ollama/kimi-k3:cloud

## Game vision alignment

| Pillar | Alignment | Reason |
|---|---:|---|
| Choices Are Final | 0 | No gameplay change. |
| The Game Doesn't Judge | 0 | No change. |
| Time Has Emotional Weight | 0 | No change. |
| The Ship Is Home | +1 | Mark's dev builds show the ship as designed, not a black sky because a table was left behind (dev.23). |
| Grounded Strangeness | +1 | The GR lens, the starmap tiers and the sky bundle are what make the strangeness real. This guards against their silent absence. |
| We Are Not Built For This | 0 | No change. |

Net +2: weakly aligned. This is hygiene, and it's cheap. **Go.**

## Problem

L6 has two halves. **The exported-app smoke half has landed. The static half is missing.**

**Landed (record only; do not redesign).** Commit `93cda65` (2026-10-08) made `publish-dev` depend on `ship-demo-export-smoke`, which had previously run nowhere (V2). `publish-dev` now has these prerequisites:

- `export-macos` and `export-smoke`, which itself pulls in `starmap-export-smoke`;
- `ship-demo-export-smoke`;
- `ship-star-identification-export-smoke`;
- `current-ship-export-smoke`;
- `title-export-smoke`;
- `solar-departure-export-smoke`.

See V3. A dry run of `make -n publish-dev` reaches all six exported-app smoke flags (V4). The lens tables themselves were put back into the filter by `01af4c5` (V5).

**Missing: a static check.** Nothing in `make test` relates the `res://` paths that shipped code reads to `export_presets.cfg`. The relevant settings are:

- `export_filter="all_resources"`;
- `include_filter` at line 9, with 24 entries;
- `exclude_filter` at line 10, with 8 entries.

See V1. Today the only line of defence is the smokes. They run on the rig, only at `publish-dev` time, and only along the routes they happen to exercise. The dev.23 regression was exactly a non-resource file (`data/lens/*.bin`) that the export dropped silently.

**What the export actually keeps.** This was measured, not recalled (V9). In a scratch project with an empty `include_filter`, `all_resources` packed the following from a directory of probe files:

- `p.json` raw;
- `p.csv` only as `p.csv.import`, so the raw CSV was dropped.

It dropped `.bin`, `.txt`, `.ndjson`, `.ail`, `.md`, `.cfg`, `.toml`, `.lock` and `.png.bin`. So:

- **`data/news/copy.json` is not a gap.** JSON is a Godot 4 resource type and is packed without a filter entry. The full-project pack contains both `data/news/copy.json` and `data/news/templates.json` (V8).
- **Every non-resource extension depends on `include_filter`.** That covers `.bin`, `.ndjson`, `.ail`, `.txt` and extensionless files such as `data/planets/ALBEDO`. That dependence is what the audit must check.
- **`*` in a filter crosses `/`.** `sim/*.ail` packs `sim/data/acen.ail` and the other four files in `sim/data/` (V12). The audit must therefore use Godot's own `String.matchn` rather than a re-implemented glob.
- **`exclude_filter` beats resource auto-inclusion.** `tools/*` holds `.gd` files, yet no `tools/` or `tests/` file is in the pack (V13).

**Measured state at HEAD `98ec78b`:**

- Shipped code is 80 tracked `.gd` files outside `tests/`, `tools/` and `spike/`, holding 90 distinct `res://` literals (V6, V7).
- Every concrete literal whose file exists on disk is in the full-project pack (V11).
- Six literals name files that are absent in a clean clone (fetched or staged artifacts). Each one is covered by a filter entry or is a dev-only source with a bundled fallback (V11, V18).
- 25 shipped lines build `res://` paths dynamically, by `+`, `path_join` or `%` (V17). Examples are `demos/ship_commons.gd:4-5` (V19) and `physics/schwarzschild.gd:22` (`LENS_DIR`).

**Real gaps found at HEAD:** one, and it is hygiene rather than a broken build.

- **G1. `spike/` ships in the pack, and it reads a path the export drops.** The pack has 3 `spike/` files (V14). `spike/panorama_main.gd` reads `res://data/raw/hip_v7.tsv`. `data/raw/` is gitignored and not exported (V15), and nothing in the game loads `res://spike/` (V14). **Fix in scope:** add `spike/*` to `exclude_filter`.
- **Intended, not a gap.** `main.gd` names 11 distinct `res://tools/*.gd` scripts on 14 lines (V13). These are the `--golden`, `--bench`, `--*-capture` and site-movie routes, and `tools/*` is excluded on purpose. The audit records them in a declared dev-only table and does not skip them silently.

## Goals and non-goals

**Goals**

1. Add `make export-filter-audit`, a headless GDScript audit in `make test`. It fails when shipped code reads a path that `export_presets.cfg` would drop.
2. Classify every literal. Dynamic and dev-only paths go in declared tables with a reason, and a stale table row fails.
3. Make the audit fail loudly on empty extraction. Prove it with named in-process mutations that run on every `make test`.
4. Add a rig-only pack oracle, `make export-pack-check`, wired into `publish-dev`. It re-measures the audit's two assumptions on the real `--export-pack` output: which extensions are auto-included, and that the classified paths are present.
5. Fix G1.

**Non-goals**

- Redesigning the exported-app smokes. They have landed (V2 to V4).
- Dependencies between imported resources (`.tscn` to texture and so on). Godot's own exporter follows these.
- Checking `load()` versus `FileAccess` on imported files: whether a raw `.png` is readable by bytes. See the risks.
- Editing `demos/ship_geometry_demo.gd` or `demos/ship_consoles.gd`. These are on the Do-not-touch line for PR #208. The audit only **reads** them, and needs no edit to them (`ship_demo_bundle/*` is already in the filter).
- Running the pack oracle in CI. See the risks and Open questions.

## Design

### Sub-milestone L6a: static audit in `make test` (about 215 LOC)

**Files:** `tests/export_audit.gd` (new; pure logic plus the declared tables), `tests/test_export_audit.gd` (new; real run plus mutations), a Makefile target, and `export_presets.cfg` (G1). Everything under `tests/` is excluded from the export (`tests/*` in `exclude_filter`, V1).

1. **Filters.** Read `res://export_presets.cfg` with `ConfigFile` and take `preset.0`. The file has one preset (V7 control). Split `include_filter` and `exclude_filter` on `,`, then strip and drop empty strings.
2. **Shipped scope.** Walk `res://` with `DirAccess`, skipping `.godot/` and hidden directories. Collect each `*.gd` whose project-relative path matches **no** `exclude_filter` entry, using `path.matchn(entry)`. Scope comes from the exclude filter itself, so a directory that becomes excluded leaves scope automatically. The read-only `demos/` files are in scope, since `demos/` ships.
3. **Extraction.** Run both `RegEx` `"res://[^"]*"` and `'res://[^']*'` over each scoped file and union the `(literal, file:line)` pairs, so any future single-quoted literal is extracted rather than silently skipped. Shipped code has no single-quoted `res://` literal today (V25).
4. **Classify each distinct literal.** Exactly one class must apply. Otherwise the literal is **UNCLASSIFIED**, and that fails the audit.
   - **R, resource.** The extension is in `AUTO_EXT`. The class passes iff the path matches no `exclude_filter` entry. `AUTO_EXT` is exactly the set measured in the pack, each with the form it ships in:
     - `gd`, packed as `.gdc` plus `.gd.remap` (V21);
     - `tscn`, packed as `.scn` plus `.tscn.remap` (V21);
     - `gdshader` and `gdshaderinc`, packed raw (V21);
     - `json`, packed raw (V9).

     **`tres` is not in the set.** The repo has no `.tres` file, so its export form is unmeasured (V23), and a `res://*.tres` literal falls to F. It fails unless an include entry covers it, and the failure is reported as `unmeasured extension tres` until someone measures the form and adds it to `AUTO_EXT` with a V row (M16). A false red is cheaper than an unmeasured green. Round 1's "or `<path>.import` exists" clause is also **dropped**: the pack has zero `.import` and zero `.godot/imported/` entries (V21), so that rule was unmeasured.
   - **F, filtered file.** Any other extension (for example `bin`, `ndjson`, `txt`, `ail`, `png`, `ttf`). It passes iff it matches some `include_filter` entry and no `exclude_filter` entry. `png` is conservatively F. The only concrete `png` literals in scope are the dev-only `data/raw/background/*` (X).
   - **D, dynamic prefix.** The literal has no extension, or ends in `/`, or is a prefix used in concatenation. It needs a row in `DYNAMIC` of the form `{prefix, filter, witnesses, reason}`. Example: `{"res://data/lens", "data/lens/*", ["data/lens/lens_fwd.bin","data/lens/lens_inv.bin"], "Schwarzschild tables: load_tables reads lens_<t>.json headers and lens_<t>.bin tables (physics/schwarzschild.gd:216-224); dev.23"}`.
     - The row passes iff `filter` is literally present in `include_filter`, and no witness matches an `exclude_filter` entry.
     - Every witness must also pass rule F.
     - **Witnesses must be the bytes the game needs, not resources.** A row with a non-empty `filter` must have at least one witness outside `AUTO_EXT`, or it fails with `row <prefix> has no non-resource witness`. For `data/lens` the witnesses are the `.bin` tables: `load_tables` reads both `lens_<t>.json` and `lens_<t>.bin` (V20). The `.json` headers are auto-packed resources (V9), so a `.json`-only witness would still pass under M2's narrowed `data/lens/*.json` filter, while the build that shipped would have no tables. That is the dev.23 failure (V5). A `.json` witness is therefore never acceptable as the only one.
     - Rows in the table are needed for each of these prefixes: `ai`, `ai_core`, `areas_bundle`, `assets/areas`, `assets/characters/captain`, `assets/planets`, `assets/ship_commons/`, `assets/ship_demo/`, `data/ai`, `data/ai/cast`, `data/lens`, `data/lore`, `data/planets/ALBEDO`, `data/planets/TEXTURES`, `data/starmap`, `planet_bundle`, `runtime`, `runtime/cache`, `runtime/VERSION`, `ship_commons_bundle/`, `ship_demo_bundle/` and `sim` (V7, V17).
     - A row whose directory is read only through `AUTO_EXT` files names filter `""`, and all its witnesses must pass R. An example is `assets/characters/captain`, whose `manifest.json` is read by `interior/captain_avatar.gd`.
     - The static audit does not cover directories whose files are neither `AUTO_EXT` nor filtered, such as the captain PNGs. The V8 pack lists those PNGs without a filter entry, but the mechanism is unmeasured. **The raw captain PNGs are completely unverified, both statically and by the L6b oracle.** Their presence is safeguarded solely by the runtime exported-app smokes. No import rule is assumed.
   - **X, declared dev-only.** The literal has a row in `DEV_ONLY` of the form `{literal-or-prefix, reason, fallback}`. Rows are `res://tools/` (the `main.gd` dev routes, V13) and `res://data/raw/background/` with fallback `res://sky_bundle/`.
     - The fallback must itself classify as passing.
     - The dev-only path must **fail** rules R and F. A dev-only row for something that actually ships is a stale row.
   - **Root.** The bare `"res://"` literal is used only with `globalize_path` and string concatenation (V7). It gets one explicit `DEV_ONLY`-style row, `"root, never read as a file"`, rather than a special case.
5. **Stale rows.** Any `DYNAMIC` or `DEV_ONLY` row whose prefix matches no extracted literal fails, with the message `stale row`.
6. **Anti-vacuity.** The audit fails before classifying if any of the following holds. Each floor is set just below the V1 and V6 measurements, so shrinkage gets noticed in review.
   - scoped files < 60 (measured 80);
   - distinct literals < 70 (measured 90);
   - `include_filter` entries < 20 (measured 24);
   - `exclude_filter` entries < 6 (measured 8);
   - `DYNAMIC` rows < 15.
7. **Output.** One `ok`/`FAIL` line per literal class, then `export-filter-audit: <n> literals, <r>R <f>F <d>D <x>X, 0 failures`. The Makefile target follows the existing summary-grep pattern (Makefile:53), so a parse error that exits 0 cannot pass:

   ```make
   test: export-filter-audit
   export-filter-audit: import
   	@$(GODOT) --headless --path . --script tests/test_export_audit.gd > $(SCRATCH)/export-audit.log 2>&1; rc=$$?; grep -E '^(FAIL|export-filter-audit)' $(SCRATCH)/export-audit.log; test $$rc = 0 && grep -q '^export-filter-audit: [0-9]* literals.*, 0 failures$$' $(SCRATCH)/export-audit.log
   ```
8. **Mutations.** These run in-process on every `make test`. `export_audit.gd` exposes `audit(include: PackedStringArray, exclude: PackedStringArray) -> Array[String]`, which returns its failures. The scope walk and extraction are performed inside `audit()` on every call, so M13's mutated exclude re-derives scope. `test_export_audit.gd` passes raw filter arrays only. Literal-set mutants (M6, M7, M11, M16) use an optional extra-literals or replace-literals argument; the executor names it, and it never bypasses the scope walk for the real run. `test_export_audit.gd` first runs the real inputs and asserts no failures. Then it re-runs on mutated **in-memory** copies, never on edited files, and asserts each kill below. A mutant that survives is a test failure: `mutant M<k> survived`.

| Mutant | Mutation | Killing assertion |
|---|---|---|
| M1 (dev.23) | drop `data/lens/*` from include | both: (a) D row `res://data/lens`: `filter data/lens/* not in include_filter`; (b) `F data/lens/lens_fwd.bin not covered` (and `lens_inv.bin`) |
| M2 | narrow `data/lens/*` to `data/lens/*.json` | both: (a) D-row filter text missing; (b) `F data/lens/lens_fwd.bin not covered`. The `.json` headers still pass R, which is why they cannot be the only witnesses |
| M3 | add `data/lens/*` to exclude | both: (a) D row `witness data/lens/lens_fwd.bin excluded`; (b) `F data/lens/lens_fwd.bin excluded` |
| M4 | drop `data/starmap/*` | F: `res://data/starmap/stars_large.bin` uncovered (`sky/starfield.gd:139`) |
| M5 | drop `sky_bundle/*` | X row `data/raw/background/`: fallback `res://sky_bundle/…png.bin` fails F |
| M6 | add literal `res://data/news/extra.bin` | F: no include entry matches |
| M7 | add literal `res://data/brand_new` (no extension, no row) | UNCLASSIFIED |
| M8 | delete the `DYNAMIC` row for `ai_core` | `res://ai_core` (`bridge/ai_cache.gd:17`) becomes UNCLASSIFIED |
| M9 | add a `DYNAMIC` row for `res://data/never_referenced` | stale row |
| M10 | empty include list | anti-vacuity `include_filter entries 0 < 20` |
| M11 | empty literal set | anti-vacuity `literals 0 < 70` |
| M12 | remove `json` from `AUTO_EXT` | R/F: `res://data/news/copy.json` uncovered. This proves that `AUTO_EXT` is load-bearing and pinned |
| M13 | drop `spike/*` from exclude (the G1 regression) | `spike/panorama_main.gd` comes into scope, and `F res://data/raw/hip_v7.tsv not covered` (a `.tsv` literal is class F under rule 4) |
| M14 | replace the `data/lens` witnesses with `lens_fwd.json`/`lens_inv.json` only | `row res://data/lens has no non-resource witness` |
| M15 | remove `gd` from `AUTO_EXT` | each of the 29 `res://*.gd` literals (V7) fails F, e.g. `F res://main.gd not covered`; this shows the measured set is load-bearing |
| M16 | add literal `res://ui/theme.tres` | `tres` is unmeasured, so the literal fails F (no include entry) and is reported as `unmeasured extension tres` |

9. **G1 fix.** Add `spike/*` to `exclude_filter`, giving `…,tests/*,tools/*,spike/*`. Line 9 (`include_filter`) is not touched.

### Sub-milestone L6b: rig-only pack oracle in `publish-dev` (about 35 LOC)

The static audit trusts two measured facts: the `AUTO_EXT` set and the glob semantics of `matchn`. The oracle re-measures both against Godot's real exporter. It writes a scratch export with **`--export-pack`, which needs no export templates.** V10 measured this with an empty `export_templates` directory: rc 0, same listing.

1. **`make export-pack-check`.** Depends on `import`. It runs:

   ```sh
   $(GODOT) --headless --path . --export-pack "macOS" $(SCRATCH)/export-pack/game.zip
   ```

   about 4 s, 443 files at HEAD (V8). Then it runs `godot --headless --script tests/test_export_pack.gd -- $(SCRATCH)/export-pack/game.zip`, which lists the zip with `ZIPReader` (first-party).
2. **Assertions.**
   - Every audit literal classified R or F that **exists on disk** is in the zip, in its measured form (V21):
     - `.gd`: a `<path>.remap` entry plus `<base>.gdc`;
     - `.tscn`: a `<path>.remap` entry plus an `.scn` entry;
     - `.gdshader`, `.gdshaderinc`, `.json` and all F files: the raw path.

     Any other form is a failure that names the path. This re-measures `AUTO_EXT` on every `publish-dev`.
   - **Every `DYNAMIC` witness is required on disk.** In the `publish-dev` wiring the target runs as `export-pack-check-strict` (`STRICT=1`): an absent witness is a hard failure named by path, since `export-macos` already fetches all staged artifacts (V22, Makefile:366). In plain `make export-pack-check`, each absent witness prints `SKIP absent witness <path>`, and the summary becomes `export-pack-check: <n> checked, <s> skips, 0 failures`. The `publish-dev` grep requires `, 0 skips,`. Every present witness must be in the zip; this includes `data/lens/lens_{fwd,inv}.bin`.
   - No `DEV_ONLY` path or excluded-scope file is in the zip. G1 makes `spike/` count 0.
   - The zip has ≥ 400 entries (anti-vacuity).

   Summary line: `export-pack-check: <n> checked, <s> skips, 0 failures`.
3. **Wiring.** `publish-dev: export-pack-check`, beside the smokes. It stays out of `make test` and CI for now, because it is unmeasured on the Linux runner. CI installs no templates (V16), and `--export-pack` on Linux with a macOS preset has not been run there.

## Acceptance criteria

| # | Criterion | Command |
|---|---|---|
| AC1 | The audit is green at HEAD after the G1 fix, with literals ≥ 70 and filters 24/9 | `make export-filter-audit` (prints `export-filter-audit: N literals, … 0 failures`) |
| AC2 | The audit is part of `make test` | `make -n test \| grep -c 'tests/test_export_audit.gd'` → ≥ 1 |
| AC3 | All 16 mutants are killed in-process, each by its named assertion. M1 to M3 must log both kills, (a) and (b) | `grep -cE '^ok +mutant M([1-9]\|1[0-6]) killed' .godot/tmp/export-audit.log` → 16 |
| AC4 | The dev.23 regression turns the audit red in a real file edit, and the failure names the **data file** (the `.bin` table), not only the filter text | `cp export_presets.cfg /tmp/ep && sed -i '' 's#,data/lens/\*##' export_presets.cfg; make export-filter-audit; rc=$?; cp /tmp/ep export_presets.cfg; test $rc != 0 && grep -qE '^FAIL.*data/lens/lens_(fwd\|inv)\.bin' .godot/tmp/export-audit.log` |
| AC5 | Anti-vacuity: the audit fails when no literals are found | covered by M11 in AC3, plus `make export-filter-audit` printing `scoped files N` with N ≥ 60 |
| AC6 | No silent skip: every literal is in exactly one class, and every class line is printed | `grep -c '^UNCLASSIFIED' .godot/tmp/export-audit.log` → 0, and the summary's R+F+D+X equals N |
| AC7 | G1 is fixed: `spike/` is out of the pack | `make export-pack-check && unzip -Z1 .godot/tmp/export-pack/game.zip \| grep -c '^spike/'` → 0 (with a positive control: `grep -c '^data/news/copy.json$'` → 1) |
| AC8 | The pack oracle is green and wired into `publish-dev`, strict there | `make export-pack-check`; `make -n publish-dev \| grep -c 'test_export_pack.gd'` → ≥ 1; under the `publish-dev` (strict) wiring, `make STRICT=1 export-pack-check-strict` is green and `grep -c "SKIP absent witness" $(SCRATCH)/export-pack.log` = 0 |
| AC9 | The oracle needs no export templates | `HOME=$(mktemp -d) make export-pack-check` → green |
| AC10 | The Do-not-touch files are unmodified | `git diff --quiet origin/main -- demos/ship_geometry_demo.gd demos/ship_consoles.gd` |
| AC11 | No Python was added | `make python-guard` and `git diff --name-only origin/main \| grep -c '\.py$'` → 0 |
| AC12 | `make test` is green locally and in CI | `make test`; the PR CI check `headless` |

## Sub-milestones and estimates

| Sub-milestone | LOC | Depends on | Order |
|---|---:|---|---|
| L6a: static audit, tables, 16 mutants, `make test` wiring, G1 | about 215 | `import` | 1 |
| L6b: `export-pack-check` oracle and `publish-dev` wiring | about 35 | L6a (it reuses `export_audit.gd` classification) | 2 |

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| `AUTO_EXT` drifts with a Godot bump, for example if JSON stops being a resource | M12 proves the set is load-bearing. L6b re-measures it on the real exporter at every `publish-dev`. The godot pin moves with CI's `GODOT_VERSION`. |
| An imported file is read by bytes (`FileAccess`), so `.import` exists but the raw file is dropped, as V9 showed for CSV | Out of scope; listed as a non-goal. The existing pattern (`.bin` staging, as in `ship_commons_bundle`) is the remedy. The exported-app smokes catch this at runtime. |
| The non-`AUTO_EXT` resource forms (PNG, TTF, imported textures) are unmeasured as a rule. V8 lists the captain PNGs raw without a filter entry, for a reason not yet measured | No rule is assumed for them. Literals with these extensions are conservatively F (a false red, never a false green). **The raw captain PNGs are completely unverified, statically and by the L6b oracle; their presence is safeguarded solely by the runtime exported-app smokes.** Any new rule needs a V row first. |
| The regex misses paths built without a `res://` literal, such as `"assets/planets"` relative (`planets/planet_smoke.gd:13`) | The prefix row `assets/planets` covers the concrete `TEX_DIR` literal. A relative path with no `res://` is a known blind spot; the smokes cover it. Named here and not hidden. |
| Table maintenance churn when a new data directory lands | Failing is intended: a new prefix with no row is UNCLASSIFIED, and the author must state the filter entry and a reason. |
| The oracle on Linux CI is unmeasured | It stays rig-only. Promotion is a follow-up after one measured CI run. |
| A PR #208 edit to the demo files adds a new literal | The audit reads those files, and a new prefix fails loudly. The fix is a table row in `tests/export_audit.gd`, not an edit to the demo files. |

## Open questions for the user

None. G1 (excluding `spike/`) is a dev-only directory that the game never loads (V14), so the loop can decide it. Promoting the pack oracle into CI is a later measured step, not a decision.

## Deliverables

- `tests/export_audit.gd`, `tests/test_export_audit.gd` and `tests/test_export_pack.gd`
- the Makefile targets `export-filter-audit` (in `test`) and `export-pack-check` (in `publish-dev`)
- `export_presets.cfg`: `spike/*` added to `exclude_filter`
- a changelog entry, and the charter row L6 marked done when the work lands

## Quorum log

**Round 1, 2026-10-12: BLOCKED.** oc-kimi-k3 and gemini-3-1-pro rejected; gpt6-1-sol and oc-glm-5-3 were unreachable. Both objections were the same kind of problem, an unverified premise:

- **kimi:** the lens witnesses and `LENS_DIR` were recalled, not quoted, and V8's pack showed only `lens_*.json`. This landed on the D-row example, on M1 to M3 and on AC4.
- **gemini:** `AUTO_EXT` was said to be "pinned to V9", but V9 probed none of `gd`, `gdshader`, `gdshaderinc`, `tscn` or `tres`. This landed on rule R and on L6b's presence check.

**What changed in round 2.** The controller measured both premises, recorded as V20 to V23.

- Lens:
  - The D row now cites `physics/schwarzschild.gd:216-224` and states that witnesses must be the `.bin` tables. A non-empty-filter row with no non-resource witness fails, and M14 proves this.
  - M1 to M3 now kill through both the D-row check and a `.bin` F failure.
  - AC4 asserts that the failure names `lens_{fwd,inv}.bin`.
  - V8 now explains why the bins were absent from its pack.
- Rule R:
  - `AUTO_EXT` is now the measured set {gd as `.gdc`+`.remap`, tscn as `.scn`+`.remap`, gdshader and gdshaderinc raw, json raw}.
  - `tres` is dropped as unmeasured; M16 makes it fail loudly.
  - The unmeasured `.import` clause is dropped.
  - M15 removes `gd` from the set to prove it is load-bearing.
- L6b checks the measured forms.
- LOC rose from about 230 to about 250.

**Round 2, 2026-10-12: BLOCKED.** oc-kimi-k3, gemini-3-1-pro and oc-glm-5-3 rejected; gpt6-1-sol was unreachable. None of the objections disputed the design direction. Each carried a concrete `proposed_fix`, and each landed on a different surface:

- **kimi (L6b oracle):** "Every DYNAMIC witness that exists on disk" was a silent skip at the dev.23 gate.
- **gemini (captain PNGs):** the doc claimed L6b checks them, which its own rules make impossible.
- **glm (rule 3 extraction):** a double-quote-only regex, with no row for single-quoted literals; M13's class was wrong; the AC scratch paths were unverified.

**What changed for round 3.** Under the Gate-2 narrow-refinement carve-out, the controller applied the reviewers' own fixes verbatim, with no controller-invented resolution:

- kimi: L6b assertion 2 now uses strict `publish-dev` wiring (`export-pack-check-strict`, `, 0 skips,`). AC8 is updated. `audit()` re-derives scope per call. V24 is added, and the citation is corrected to V22/Makefile:366.
- gemini: the captain-PNG text and its risk row now state that the PNGs are unverified statically and by the oracle, and are covered only by the exported-app smokes.
- glm: rule 3 now runs a union of both quote styles (V25). M13's kill is now `F res://data/raw/hip_v7.tsv not covered`. V26 verifies `SCRATCH := .godot/tmp` for the AC paths.

One consistency note is the controller's own. Kimi's two-argument `audit()` signature leaves the literal-set mutants (M6, M7, M11, M16) without an input. The doc therefore names an optional extra-literals or replace-literals argument and leaves the parameter name to the executor. This answers no objection. It only keeps the mutation table runnable.

## Verification log

V20 to V23 were measured by the controller in iteration 26. The designer re-ran the read-only `grep` and `unzip` listings and got the same output.

All commands were run in the iteration-26 clone at `98ec78b` on 2026-10-12, with Godot 4.7.2.stable on the rig. Scratch output is in `/tmp/l6-pack` and `/tmp/l6-probe`.

| # | Claim | Command | Observed output |
|---|---|---|---|
| V1 | Filter mode and filter lines; entry counts | `sed -n 1,10p export_presets.cfg`; `sed -n 9p … \| tr ',' '\n' \| wc -l`; same for line 10 | `export_filter="all_resources"`; line 9 `include_filter="ui/splash/Montserrat-Bold.ttf,…,data/lens/*,data/ism/*,…,ai_core/*"`; line 10 `exclude_filter="sim/.ailang/*,ai/.ailang/*,renders/*,build/*,docs/*,design_docs/*,tests/*,tools/*"`; counts **24** and **8** |
| V2 | The landed smoke fix | `git log --oneline -1 --format='%h %ad %s' --date=short 93cda65`; `git show --stat 93cda65 \| tail -3` | `93cda65 2026-10-08 fix(make): publish-dev runs the ship-demo export smoke (it ran nowhere)`; `Makefile \| 1 +` |
| V3 | `publish-dev` prerequisites | `grep -n "export-smoke\|publish-dev" Makefile` | `386:publish-dev: export-macos export-smoke`; `787:publish-dev: ship-demo-export-smoke # … (dev.23 shipped without them)`; `823:publish-dev: ship-star-identification-export-smoke`; `832:publish-dev: current-ship-export-smoke`; `858:publish-dev: title-export-smoke`; `921:publish-dev: solar-departure-export-smoke`; `931:export-smoke: starmap-export-smoke` |
| V4 | The dry run reaches the smokes | `make -n publish-dev > dryrun.txt; grep -oE -- '--(ship-demo-smoke\|ship-identification-smoke\|solar-departure-smoke\|m4-smoke\|capture=\|starmap[a-z-]*)' dryrun.txt \| sort \| uniq -c`; `grep -cE 'current-ship-export\|title-export\|title-smoke\|current-ship' dryrun.txt` | rc 0; each of `--capture=`, `--m4-smoke`, `--ship-demo-smoke`, `--ship-identification-smoke`, `--solar-departure-smoke` and `--starmap-smoke` appears once; title/current-ship matches: **4** |
| V5 | Lens tables restored to the filter | `git log --format='%h %ad %s' --date=short -S'data/lens/*' -- export_presets.cfg` | `01af4c5 2026-10-08 fix(export): bundle the GR lens tables (dev.23 shipped without them: Sgr A* drew nothing)` |
| V6 | File and literal counts | `git ls-files '*.gd' \| wc -l`; `… \| xargs grep -ohE '"res://[^"]*"' \| sort -u \| wc -l`; same excluding `^(tests\|tools\|spike)/`; `cut -d/ -f1 \| uniq -c` | **235** `.gd` files, **263** distinct literals in total (the controller's figure was 262); **80** shipped files, **90** distinct literals. By directory: bridge 6, demos 12, interior 10, main.gd 1, physics 4, planets 2, sky 10, spike 1, tests 71, tools 83, ui 35 |
| V7 | Extension breakdown of the 90 shipped literals; one preset | `awk` extension tally on `lits.txt`; `grep -c '^\[preset\.[0-9]*\]$' export_presets.cfg` | gd 29, noext 23, gdshader 10, tscn 8, json 7, ail 4, bin 3, png 2, txt 1, ttf 1, ndjson 1, gdshaderinc 1; bare `"res://"` among noext; presets **1** |
| V8 | Full-project pack (no templates step); news JSON is packed | `godot --headless --path . --import`; `godot --headless --path . --export-pack "macOS" /tmp/l6-pack/game.zip`; `unzip -l … \| tail -1`; `grep -E "news\|lens_" list.txt` | rc 0 in 3.8 s; `443 files`; `data/lens/lens_fwd.json`, `data/lens/lens_inv.json`, **`data/news/copy.json`**, `data/news/templates.json` There are no `lens_*.bin` entries. Why: at the time of this pack the bins were not on disk. A plain `ls data/lens` in the same session listed only `SHA256SUMS lens_fwd.json lens_inv.json`. The bins are gitignored (`.gitignore:32: data/lens/*.bin`) and fetched by `make lens-assets` (V22). Exporting does not fetch them, and the export cannot pack a file that doesn't exist. So V8 says nothing about whether the bins survive the filter; L6b checks that on a tree after `lens-assets`. |
| V9 | What `all_resources` auto-packs with no include entry | scratch project `/tmp/l6-probe`, with `data/probe/p.{json,bin,txt,ndjson,ail,csv,md,cfg,toml,lock,png.bin}` and `include_filter=""`; import, then `--export-pack`, then `unzip -Z1` | Only `data/probe/p.csv.import` and **`data/probe/p.json`** (plus `.godot/…`, `project.binary`). Every other probe was dropped. Positive control: `p.json` present |
| V10 | `--export-pack` needs no export templates | `HOME=/tmp/l6-home godot --headless --path . --export-pack "macOS" out2.zip`; `ls -la "/tmp/l6-home/Library/Application Support/Godot/export_templates/"` | rc 0; the templates directory is **empty** (`total 0`); listing identical to V9 |
| V11 | Every on-disk concrete shipped literal is packed | loop over `lits.txt` entries with an extension, excluding `tools/`: if the file exists, `grep -qxF` it (or `.remap`/`.import`) in `list.txt`, else print "absent" | **0** `ON DISK, NOT PACKED` lines (positive control: V8 finds `data/news/copy.json`). Absent on disk: `data/raw/background/noirlab_10k_{destarred,skymodel}.png`, `data/starmap/stars_large.bin`, `runtime/build_version.txt`, `sky_bundle/noirlab_10k_{destarred,skymodel}.png.bin`. These are covered by `data/starmap/*`, `runtime/*` and `sky_bundle/*` (V1), or are dev-only sources (V18) |
| V12 | `*` crosses `/` (`sim/*.ail` matches `sim/data/`) | `grep -E '^sim/data/' list.txt`; `git ls-files sim/data` | pack: `sim/data/{trappist1,stars,ism,acen,sol}.ail`; tracked: the same 5 |
| V13 | `tools/` and `tests/` are excluded; `main.gd` dev routes | `grep -cE '^(tools\|tests)/' list.txt`; `grep -nE '"res://tools/' <shipped .gd>` | **0** in pack (positive control: 92 `sim/` entries via `grep -c '^sim/'`); 14 lines in `main.gd` (216, 243, 247, 315, 426, 428, 430, 828, 886 to 891) naming 11 distinct `tools/*.gd` |
| V14 | `spike/` ships and is unreachable | `grep -c '^spike/' list.txt`; `grep -ohE '"res://[^"]*"' spike/*.gd`; `git grep -n "res://spike"` | **3**; `"res://main.gd"` (positive control) and **`"res://data/raw/hip_v7.tsv"`**; references only in `docs/m1.4a/README.md:80`, `spike/panorama.tscn:3` and `spike/panorama_main.gd:5`. Nothing in the game loads it |
| V15 | `data/raw/` is not shipped | `grep -n "data/raw" .gitignore`; `grep -E '^data/raw' list.txt` | `7:data/raw/`; no pack entries (control: V8 data/ entries present) |
| V16 | CI has no export templates or export step | `grep -n "export.templates\|export-pack\|export-release\|export-debug" .github/workflows/ci.yml Makefile` | only `Makefile:371: $(GODOT) --headless --path . --export-release "macOS" "$(APP)"` (positive control); **none** in ci.yml |
| V17 | Dynamic constructions in shipped code | `grep -nE '"res://[^"]*" *\+\|path_join\(\|"res://[^"]*%' <shipped .gd> \| grep -c res:` | **25** |
| V18 | The sky's dev source has a bundled fallback | `sed -n 5,17p sky/background.gd`; `grep -n "BUNDLED_PHOTO" sky/background.gd` | "Exported builds: data/raw/ carries a .gdignore … stages byte copies into res://sky_bundle/ as *.png.bin"; `88: for pair in [[PHOTO, MODEL], [BUNDLED_PHOTO, BUNDLED_MODEL]]:` |
| V19 | `ship_commons` dynamic fallback | `grep -n 'res://' demos/ship_commons.gd` | `4: var source := "res://assets/ship_commons/"+file`; `5: return source if FileAccess.file_exists(source) else "res://ship_commons_bundle/"+file+".bin"` (`ship_commons_bundle/*` in include, V1) |
| V20 | `load_tables` reads both the `.json` header and the `.bin` table (measured by controller, iteration 26) | `grep -nE 'LENS_DIR\|lens_\|\.bin\|\.json' physics/schwarzschild.gd` | `22: const LENS_DIR := "res://data/lens"`; `216: ## Load data/lens/lens_{fwd,inv}.{bin,json}; checks each bin's size and its header sha256.`; `218: static func load_tables(dir: String = LENS_DIR) -> bool:`; `221: var hdr := _read_header("%s/lens_%s.json" % [dir, t])`; `222: var bin := "%s/lens_%s.bin" % [dir, t]`; `224: load_error = "lens_%s missing (run make lens-assets)" % t` |
| V21 | Measured export forms of the resource extensions in the full pack, from V8 (measured by controller, iteration 26) | `unzip -Z1 /tmp/l6-pack/game.zip`, then count entries by suffix | `gd:0 gdc:81 gdshader:10 gdshaderinc:3 tscn:0 scn:10 tres:0 res:0 remap:91 import:0`. For example, `main.gd` ships as `main.gdc` + `main.gd.remap` and `main.tscn` as `main.tscn.remap` + a `.scn`; `sky/starfield.gdshader`, `sky/schwarzschild.gdshaderinc` and `planets/rings.gdshaderinc` ship raw. `grep -c '^\.godot/imported/'` gives **0** (positive control in the same listing: `gdc:81`) |
| V22 | The lens bins are fetched artifacts, not tracked; `export-macos` fetches them (measured by controller, iteration 26) | `git ls-files data/lens`; `git check-ignore -v data/lens/lens_fwd.bin`; `ls data/lens`; `grep -n '^export-macos:' Makefile` | tracked: `SHA256SUMS`, `lens_fwd.json`, `lens_inv.json`; `.gitignore:32:data/lens/*.bin data/lens/lens_fwd.bin`; on disk now: `SHA256SUMS lens_fwd.bin lens_fwd.json lens_inv.bin lens_inv.json`; `366:export-macos: runtime sky-bundle areas-stage starmap-assets lens-assets import` |
| V23 | There is no `.tres` in the repo, so its export form is unmeasured (measured by controller, iteration 26) | `git ls-files '*.tres' \| wc -l`; positive control `git ls-files '*.gd' \| wc -l` | **0**; control **235** |
| V24 | No general export-filter audit exists before this sprint (kimi round 2; measured by controller, iteration 26) | `grep -rn "export_presets\|include_filter" Makefile tests/ tools/ \| grep -vc export_audit`, then the matching lines | **3** lines, all in `tests/test_planets.gd:206-212`: a narrow check that `include_filter` carries `planet_bundle/*` and `data/planets/*`. That covers two entries of 24 and nothing in `Makefile` or `tools/`, so the "missing static half" claim holds for every other entry |
| V25 | Shipped code has no single-quoted `res://` literal (glm round 2; measured by controller, iteration 26) | `git grep -nE "'res://" -- '*.gd' \| grep -vE '^(tests\|tools\|spike)/'`; positive control `git grep -nE "'res://" -- '*.gd' \| grep -cE '^(tests\|tools)/'` | empty (grep rc 1); control **15** (all in `tests/` and `tools/`, which are excluded scope). Double-quoted `"res://` over all `.gd`: 497 lines |
| V26 | The acceptance commands' scratch path is the Makefile's `SCRATCH` (glm round 2; measured by controller, iteration 26) | `grep -n '^SCRATCH' Makefile` | `9:SCRATCH := .godot/tmp`. So `.godot/tmp/export-audit.log` and `.godot/tmp/export-pack/` in AC3, AC4, AC6 and AC7 are the files the targets write, as `$(SCRATCH)/…` |
