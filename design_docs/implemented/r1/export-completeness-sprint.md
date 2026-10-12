# Sprint R1-L6-EXPORT-COMPLETENESS: static res:// audit in `make test` + rig-only pack oracle in `publish-dev`

**Design doc:** [export-completeness.md](export-completeness.md) (charter triage row L6, `design_docs/stapledon-mission.md:299`, `[LOOP]`; triage order line 312: L1 → **L6** → L2 …; quorum-reviewed twice, V1–V26 measured).
**Status:** **Approved — charter triage L6 `[LOOP]` = route now (Mark, attended 2026-10-09, PR #185).** The design has no open questions ("Open questions for the user: None"); G1 (`spike/*` exclusion) is loop-decidable because the game never loads `res://spike/`.
**Branch:** `mission/stapledon-iter26-l6-export-completeness` (this worktree; HEAD `66b0455`, the committed design doc, on `origin/main` `98ec78b`).
**Estimate:** ~250 LOC. **L6a ~215** (`tests/export_audit.gd` ~140, `tests/test_export_audit.gd` ~65, Makefile + preset ~10); **L6b ~35** (`tests/test_export_pack.gd` ~27, Makefile ~8). One executor daybooked; buffer is mutation tuning and review, not new code.
**Risk:** low. No physics, sim, AILANG-package or gameplay change; `sim/` is untouched. The only behavioural edit is one glob appended to `export_presets.cfg:10` (G1). Everything new lives under `tests/`, which is excluded export scope (`tests/*` in `exclude_filter`, `export_presets.cfg:10`), so the audit cannot self-trip.

## Registry reuse

| Milestone | Package | Action | Reason |
|---|---|---|---|
| L6a, L6b | none | none | Headless GDScript + Makefile + one preset line. No `.ail` is touched, so the AILANG syntax gate (SKILL.md 5.1) does not apply; `sunholo/relativity` is untouched and gates 2, 3, 4 (physics, purity, parity) are unaffected. |

## Current status (evidence, re-verified in this worktree at `66b0455`)

- Export mechanism: `export_presets.cfg:8` `export_filter="all_resources"`; line 9 `include_filter` with **24** entries; line 10 `exclude_filter` with **8** entries (`sim/.ailang/*,ai/.ailang/*,renders/*,build/*,docs/*,design_docs/*,tests/*,tools/*`); exactly **1** preset. What auto-packs with no filter entry (measured V9/V21, design): `.gd`→`.gdc`+`.gd.remap`, `.tscn`→`.scn`+`.tscn.remap`, `.gdshader`/`.gdshaderinc`/`.json` raw; everything else needs the filter.
- Shipped scope: **80** tracked `.gd` outside `tests/ tools/ spike/` (`git ls-files '*.gd' | grep -vcE '^(tests|tools|spike)/'`), holding **90** distinct `"res://…"` literals (235 files / 263 literals counting everything; positive controls in the same commands). Extension tally matches V7 exactly (gd 29, noext 23, gdshader 10, tscn 8, json 7, ail 4, bin 3, png 2, txt 1, ttf 1, ndjson 1, gdshaderinc 1). The 23 no-extension literals are the design's 22 DYNAMIC prefixes plus bare `"res://"` — no more, no less (measured here by awk on the shipped-literal set).
- The live G1 gap: `spike/panorama_main.gd` carries `"res://data/raw/hip_v7.tsv"` (plus `"res://main.gd"`); `data/raw/` is gitignored (`.gitignore:7`) without an include entry, and nothing in the game loads `res://spike/` (references only in `spike/panorama_main.gd:5`‘s usage comment, `spike/panorama.tscn`, `docs/m1.4a/README.md` — V14). `spike/*` is in neither filter (verified line 9/10 above).
- The dynamic sites the DYNAMIC table must cover are real: `physics/schwarzschild.gd:22` (`LENS_DIR`; `load_tables` reads `lens_<t>.json` headers and `lens_<t>.bin` tables, lines 216–224), `demos/ship_commons.gd:4-5` (fallback `res://ship_commons_bundle/…​.bin`), `sky/background.gd:13-16` + `:88` (dev source `data/raw/background/*` with bundled `sky_bundle/*.png.bin` fallback), `bridge/ai_cache.gd:17` (`res://ai_core`), `sky/starfield.gd:139` (`stars_large.bin`), `main.gd` names 11 distinct `res://tools/*.gd` on 14 lines. `make lens-assets` fetches the lens `.bin` tables (`.gitignore:32`); `export-macos` does fetch them (`Makefile:366`).
- Where the audit plugs in: `SCRATCH := .godot/tmp` (`Makefile:9`); the `test:` aggregate is `Makefile:29`; the summary-grep idiom is `Makefile:51-55` (physics: a script that fails to parse exits 0 without its summary, so the target requires the summary line); separate prerequisite lines already exist (`test: ship-demo-ci` at `Makefile:795`, `publish-dev: <smoke>` at `Makefile:787/823/832/858/921`); `.PHONY` is `Makefile:17`; `import` is `Makefile:21`; `@mkdir -p $(SCRATCH)` precedes every Godot test (`Makefile:38, 52, 86, 93`).
- Test conventions to copy: `tests/test_physics.gd:1` `extends SceneTree`, `check()` helper (`tests/test_planets.gd:16`), `quit(1 if failures > 0 else 0)` (`tests/test_planets.gd:249`); `ConfigFile` precedent `tests/test_ai_settings.gd`; `DirAccess` precedent `tests/test_ai_bridge.gd`. `ZIPReader` and `String.matchn` have no current in-repo usage — only the design doc names them (both first-party Godot APIs; `matchn` is deliberately Godot's own glob so the filter semantics aren't re-implemented — design V12).
- CI: job `headless` at `.github/workflows/ci.yml:9`, `GODOT_VERSION: 4.7.2-stable` (line 14), no export step and no templates (grep for `export-pack|export-release|export-debug|export.templates` empty; positive control: 4 `godot` hits). The pack oracle stays rig-only (design risk row).
- Nothing exists yet: no `tests/export*` file (control: 71 test `.gd` files); the only pre-existing filter check is the narrow `planet_bundle/*` + `data/planets/*` probe in `tests/test_planets.gd:206-212` (V24).
- Changelog convention: fragments `changelogs/unreleased/YYYY-MM-DD-<slug>.md` opening with `### ` (e.g. `2026-10-09-ship-ui-hud.md`).

## Milestones

| ID | Work | LOC | Depends | Acceptance (design AC) |
|---|---|---:|---|---|
| **L6a** | Static audit: `tests/export_audit.gd` (filters, scope walk, extraction, R/F/D/X rules, DYNAMIC/DEV_ONLY tables, anti-vacuity), `tests/test_export_audit.gd` (real arm + 16 in-process mutants) written **first**; Makefile `export-filter-audit` in `test`; G1 (`spike/*` into `exclude_filter`). | ~215 | `import` | AC1–AC6, AC10, AC11 |
| **L6b** | Rig-only pack oracle: `tests/test_export_pack.gd` (ZIPReader over a real `--export-pack` zip; re-measures AUTO_EXT forms, witnesses, absence of dev-only/excluded paths, ≥400 anti-vacuity); `export-pack-check` + strict variant; `publish-dev` wiring; changelog fragment. | ~35 | L6a (preloads `tests/export_audit.gd` classification) | AC7–AC9, AC12 |

## L6a — files and line anchors (≈215 LOC)

1. **CREATE `tests/test_export_audit.gd` first (~65 LOC).** `extends SceneTree`; `const ExportAudit = preload("res://tests/export_audit.gd")` per the house pattern; `check()` helper and `quit(1 if failures > 0 else 0)` (`tests/test_physics.gd:1`, `tests/test_planets.gd:16,249`). Arms:
   - **Real arm** (must exist before logic): `var f := ExportAudit.read_filters()` → `ExportAudit.audit(f.include, f.exclude)` returns `Array[String]` of failures → assert empty; print the floor lines (`scoped files <n>`, `distinct literals <m>`, `filters <i>/<e>`) and the summary `export-filter-audit: <n> literals, <r>R <f>F <d>D <x>X, 0 failures` — the exact string the Makefile greps (`^export-filter-audit: [0-9]* literals.*, 0 failures$$`).
   - **Mutation arms M1–M16** (table below), each on **in-memory copies only** (never edited files); each asserts its named failure string(s) appear and prints exactly `ok   mutant M<k> killed (<assertion detail>)` so AC3's grep `^ok +mutant M([1-9]|1[0-6]) killed` counts 16. A surviving mutant is a test failure `mutant M<k> survived`.
2. **CREATE `tests/export_audit.gd` (~140 LOC) after the test file exists.** Static functions only, plain script (no `class_name`; tests/ is excluded scope anyway):
   - `read_filters() -> Dictionary{include, exclude}`: `ConfigFile` on `res://export_presets.cfg`, `preset.0` (1 preset — verified), split on `,`, strip, drop empties.
   - Scope walk (`DirAccess`, skip `.godot/` and hidden dirs): collect `*.gd` whose project-relative path matches **no** `exclude_filter` entry via `path.matchn(entry)` — scope derives from the filter itself, so the G1 fix automatically removes `spike/` and M13's mutated exclude re-derives it.
   - Extraction: union of `RegEx` `"res://[^"]*"` and `'res://[^']*'` into `(literal, file:line)` pairs (single-quoted: 0 in shipped scope today, control 8 files in tests/tools — V25, re-verified).
   - Classification, exactly one class per literal, else `UNCLASSIFIED` (printed as `UNCLASSIFIED <literal> (<file:line>)`, counted by AC6):
     - **R**: extension in `AUTO_EXT` = `{gd → .gdc+.gd.remap, tscn → .scn+.tscn.remap, gdshader, gdshaderinc, json → raw}` with per-extension expected pack forms stored as data (L6b reuses it). Passes iff the literal matches no exclude entry.
     - **F**: any other extension; passes iff it matches some include entry and no exclude entry. `tres` failing F reports `unmeasured extension tres` (`const UNMEASURED_EXT`, cites V23/M16).
     - **D**: no extension / trailing `/`; needs a `DYNAMIC` row `{prefix, filter, witnesses, reason}` — 22 rows (prefixes: `ai`, `ai_core`, `areas_bundle`, `assets/areas`, `assets/characters/captain`, `assets/planets`, `assets/ship_commons/`, `assets/ship_demo/`, `data/ai`, `data/ai/cast`, `data/lens`, `data/lore`, `data/planets/ALBEDO`, `data/planets/TEXTURES`, `data/starmap`, `planet_bundle`, `runtime`, `runtime/cache`, `runtime/VERSION`, `ship_commons_bundle/`, `ship_demo_bundle/`, `sim` — the measured noext list above minus root). Row passes iff `filter` is literally in `include_filter`, no witness matches an exclude entry, every witness passes F, and a non-empty-`filter` row has ≥1 witness outside `AUTO_EXT` (the dev.23 rule: `data/lens` witnesses are the `.bin` tables, never `.json`-only). A `filter: ""` row's witnesses must all pass R (`assets/characters/captain`/`manifest.json` is the example).
     - **X**: `DEV_ONLY` rows `{path, reason, fallback, exact}`: `res://tools/` (main.gd dev routes), `res://data/raw/background/` with fallback `res://sky_bundle/`, and the root row `{"res://", "root, never read as a file", "", exact: true}`. Fallback must classify passing; the dev-only path must FAIL R and F (a stale row otherwise).
   - Stale rows: any DYNAMIC/DEV_ONLY row matching no extracted literal fails with `stale row`.
   - Anti-vacuity floors (fail before classifying): scoped files <60 (measured 80), distinct literals <70 (90), include entries <20 (24), exclude entries <6 (8→9 after G1), DYNAMIC rows <15 (22).
   - **Chosen signature** (design left the literal-set argument name open; this plan fixes it, see Plan findings):
     `static func audit(include: PackedStringArray, exclude: PackedStringArray, mutations: Dictionary = {}) -> Array[String]`, with `mutations` keys `"extra_literals"` (M6, M7, M16), `"replace_literals"` (M11; `has()` distinguishes empty from absent), `"dynamic_rows"` (M8, M9, M14), `"dev_only_rows"`, `"auto_ext"` (M12, M15). The scope walk and extraction run inside `audit()` on every call; the real run passes no mutations.
   - `static func classify(include, exclude, mutations := {}) -> Dictionary` (literal → class, plus rows/witnesses) — the shared seam; `audit()` is classify + rule evaluation → failures. L6b's `test_export_pack.gd` preloads this script and calls `classify` (design: L6b "reuses export_audit.gd classification"; the seam name is this plan's choice).
3. **MODIFY `Makefile`** (≈4 lines + `.PHONY`):
   - `Makefile:17` `.PHONY`: add `export-filter-audit`.
   - After the physics block (pattern from `Makefile:38,51-55`; separate-line precedent `Makefile:795`):
     ```make
     test: export-filter-audit

     export-filter-audit: import   ## L6a: shipped res:// reads vs export_presets.cfg; fails when the export would drop one
     	@mkdir -p $(SCRATCH)
     	@$(GODOT) --headless --path . --script tests/test_export_audit.gd > $(SCRATCH)/export-audit.log 2>&1; rc=$$?; grep -E '^(FAIL|UNCLASSIFIED|scoped files|distinct literals|filters|export-filter-audit)' $(SCRATCH)/export-audit.log; test $$rc = 0 && grep -q '^export-filter-audit: [0-9]* literals.*, 0 failures$$' $(SCRATCH)/export-audit.log
     ```
4. **MODIFY `export_presets.cfg:10` only** (G1): append `,spike/*` → `exclude_filter="sim/.ailang/*,ai/.ailang/*,renders/*,build/*,docs/*,design_docs/*,tests/*,tools/*,spike/*"`. **Line 9 (`include_filter`) is not touched** (design step 9); entries go 8→9, which AC1's "filters 24/9" pins.

### L6a test-first task list

- **T1 (red):** write `tests/test_export_audit.gd` with the real arm and all 16 mutation arms against the API above. **No `tests/export_audit.gd` yet.** Run `godot --headless --path . --script tests/test_export_audit.gd`; it fails red on the missing preload — record the error line in the sprint notes (precedent: R1-SHIP-UI U0's red run "Could not find type ShipHud").
- **T2:** implement `tests/export_audit.gd` (tables + rules). First real-arm run at HEAD must be red **for the documented reason**: `FAIL … res://data/raw/hip_v7.tsv not covered` from `spike/panorama_main.gd` — the audit catching the live G1 gap. Fix mutations M1–M12, M14–M16 until each is killed.
- **T3:** G1 edit (`export_presets.cfg:10`). Real arm goes green; **M13 only now has its base** (dropping `spike/*` from the fixed exclude re-scopes `spike/panorama_main.gd` → `F res://data/raw/hip_v7.tsv not covered`) — tune it last.
- **T4:** Makefile wiring + `.PHONY`; run the AC1–AC6, AC10, AC11 commands below; `make test` green.

### L6a mutation table (design rule 8; every mutant runs in-process on every `make test`)

| Mutant | Mutation (input the test passes) | Killing assertion |
|---|---|---|
| **M1** (dev.23) | include without `data/lens/*` | **both** (a) D row `res://data/lens`: `filter data/lens/* not in include_filter`; **and** (b) `F data/lens/lens_fwd.bin not covered` (and `lens_inv.bin`) |
| **M2** | include narrowed to `data/lens/*.json` | **both** (a) D-row filter text missing; **and** (b) `F data/lens/lens_fwd.bin not covered` (the `.json` headers still pass R — why they can never be the only witnesses) |
| **M3** | exclude + `data/lens/*` | **both** (a) D row `witness data/lens/lens_fwd.bin excluded`; **and** (b) `F data/lens/lens_fwd.bin excluded` |
| **M4** | include without `data/starmap/*` | F: `res://data/starmap/stars_large.bin` uncovered (`sky/starfield.gd:139`) |
| **M5** | include without `sky_bundle/*` | X row `data/raw/background/`: fallback `res://sky_bundle/…png.bin` fails F |
| **M6** | extra literal `res://data/news/extra.bin` | F: no include entry matches |
| **M7** | extra literal `res://data/brand_new` (no ext, no row) | UNCLASSIFIED |
| **M8** | `dynamic_rows` without the `ai_core` row | `res://ai_core` (`bridge/ai_cache.gd:17`) becomes UNCLASSIFIED |
| **M9** | `dynamic_rows` + row for `res://data/never_referenced` | stale row |
| **M10** | empty include list | anti-vacuity `include_filter entries 0 < 20` |
| **M11** | `replace_literals` = empty set | anti-vacuity `literals 0 < 70` |
| **M12** | `auto_ext` without `json` | R/F: `res://data/news/copy.json` uncovered — proves `AUTO_EXT` is load-bearing and pinned |
| **M13** (G1 regression) | exclude without `spike/*` | `spike/panorama_main.gd` re-enters scope; `F res://data/raw/hip_v7.tsv not covered` |
| **M14** | `data/lens` witnesses replaced by `.json`-only | `row res://data/lens has no non-resource witness` |
| **M15** | `auto_ext` without `gd` | each of the 29 `res://*.gd` literals fails F, e.g. `F res://main.gd not covered` |
| **M16** | extra literal `res://ui/theme.tres` | fails F and is reported `unmeasured extension tres` |

### L6a acceptance (commands copied verbatim from the design AC table; runnable as written on this rig)

| # | Criterion | Command |
|---|---|---|
| AC1 | The audit is green at HEAD after the G1 fix, with literals ≥ 70 and filters 24/9 | `make export-filter-audit` (prints `export-filter-audit: N literals, … 0 failures`) |
| AC2 | The audit is part of `make test` | `make -n test \| grep -c 'tests/test_export_audit.gd'` → ≥ 1 |
| AC3 | All 16 mutants are killed in-process, each by its named assertion. M1 to M3 must log both kills, (a) and (b) | `grep -cE '^ok +mutant M([1-9]\|1[0-6]) killed' .godot/tmp/export-audit.log` → 16 |
| AC4 | The dev.23 regression turns the audit red in a real file edit, and the failure names the **data file** (the `.bin` table), not only the filter text | `cp export_presets.cfg /tmp/ep && sed -i '' 's#,data/lens/\*##' export_presets.cfg; make export-filter-audit; rc=$?; cp /tmp/ep export_presets.cfg; test $rc != 0 && grep -qE '^FAIL.*data/lens/lens_(fwd\|inv)\.bin' .godot/tmp/export-audit.log` |
| AC5 | Anti-vacuity: the audit fails when no literals are found | covered by M11 in AC3, plus `make export-filter-audit` printing `scoped files N` with N ≥ 60 |
| AC6 | No silent skip: every literal is in exactly one class, and every class line is printed | `grep -c '^UNCLASSIFIED' .godot/tmp/export-audit.log` → 0, and the summary's R+F+D+X equals N |
| AC10 | The Do-not-touch files are unmodified | `git diff --quiet origin/main -- demos/ship_geometry_demo.gd demos/ship_consoles.gd` |
| AC11 | No Python was added | `make python-guard` and `git diff --name-only origin/main \| grep -c '\.py$'` → 0 |

Rig notes: AC4 uses macOS BSD `sed -i ''` and is self-restoring; `.godot/tmp` is `$(SCRATCH)` (V26, `Makefile:9`). Where a check is `grep -c …` → 0 (AC6, AC11, later AC7), the **count is the oracle**: `grep -c` exits 1 on zero matches, and that exit code is the passing case — do not wire these counts into an `&&` chain.

## L6b — files and line anchors (≈35 LOC)

1. **CREATE `tests/test_export_pack.gd` (~27 LOC).** `extends SceneTree`; zip path from `OS.get_cmdline_user_args()` (the argument after `--`); strict flag from `OS.get_environment("STRICT")` (this plan's choice — the design names `STRICT=1` but not how it reaches GDScript); zip listed with first-party `ZIPReader`. Preloads `tests/export_audit.gd` and calls `classify()` on the real filters. Assertions (design L6b step 2):
   - Every literal classified R or F that **exists on disk** is in the zip in its measured form: `.gd` → `<path>.remap` + `<base>.gdc`; `.tscn` → `<path>.remap` + `.scn`; `.gdshader`/`.gdshaderinc`/`.json` and all F files → raw path. Any other form is a `FAIL` naming the path — this re-measures `AUTO_EXT` on every `publish-dev`.
   - Every `DYNAMIC` witness: absent witness + `STRICT=1` → hard `FAIL` named by path; absent + non-strict → print `SKIP absent witness <path>` and count it; present → must be in the zip (includes `data/lens/lens_{fwd,inv}.bin`; on disk via `lens-assets`, `Makefile:366`, V22).
   - No DEV_ONLY path or excluded-scope file in the zip (G1 ⇒ `spike/` count 0).
   - Anti-vacuity: zip has ≥ 400 entries.
   - Summary `export-pack-check: <n> checked, <s> skips, 0 failures`; `quit(1)` with `FAIL` lines otherwise.
2. **MODIFY `Makefile`** (≈8 lines; `.PHONY` at `Makefile:17` gains both targets; block placed after the `export-macos` target, `Makefile:366-372`):
   ```make
   export-pack-check: import   ## L6b (rig-only): re-measure AUTO_EXT and the classified paths on a real --export-pack zip
   	@mkdir -p $(SCRATCH)/export-pack
   	@$(GODOT) --headless --path . --export-pack "macOS" $(SCRATCH)/export-pack/game.zip
   	@STRICT="$(STRICT)" $(GODOT) --headless --path . --script tests/test_export_pack.gd -- $(SCRATCH)/export-pack/game.zip > $(SCRATCH)/export-pack.log 2>&1; rc=$$?; grep -E '^(FAIL|SKIP|export-pack-check)' $(SCRATCH)/export-pack.log; test $$rc = 0 && grep -q '^export-pack-check: [0-9]* checked, [0-9]* skips, 0 failures$$' $(SCRATCH)/export-pack.log

   export-pack-check-strict:   ## publish-dev gate: an absent witness is a hard failure; no silent skips (AC8)
   	@$(MAKE) --no-print-directory export-pack-check STRICT=1
   	@grep -q ', 0 skips, 0 failures$$' $(SCRATCH)/export-pack.log || { echo 'export-pack-check-strict: silent skips at the publish-dev gate'; exit 1; }
   ```
   Then the prerequisite line beside the existing pattern (`Makefile:787/823/832/858/921`):
   ```make
   publish-dev: export-pack-check-strict   # L6b pack oracle, strict (AC8)
   ```
   AC8's `make -n publish-dev | grep -c 'test_export_pack.gd'` works because GNU make executes `$(MAKE)` lines under `-n` and propagates the flag, so the sub-make prints the `godot --script tests/test_export_pack.gd …` recipe line without running it.
3. **CREATE `changelogs/unreleased/2026-10-12-export-completeness.md`** — one `### ` fragment (convention verified above).

### L6b test-first task list

- **T1 (red, scratch only):** write `tests/test_export_pack.gd`. Demonstrate both failure paths before any Makefile target exists: (a) a nonexistent zip argument → non-zero exit with a `FAIL` line and no summary (the failure mode the summary-grep exists for); (b) a **scratch copy** of the real zip under `$(SCRATCH)` with one expected form removed (e.g. no `main.gdc`) → `FAIL` names `res://main.gd`'s missing form. Never touch tracked state.
- **T2:** the two Makefile targets + `.PHONY`; `make export-pack-check` green on the rig (lens bins on disk per V22); then `make STRICT=1 export-pack-check-strict` green with `, 0 skips,`.
- **T3:** the `publish-dev:` prerequisite line; AC7–AC9; full `make test` (AC12's local half); changelog fragment.

**The executor never runs a real `make publish-dev`** (gcloud upload to Mark's dev channel): the first wired `publish-dev` run happens attended (pause point below). Until then the strict path is proven by `make STRICT=1 export-pack-check-strict` on the rig (AC8).

### L6b acceptance (copied verbatim from the design AC table)

| # | Criterion | Command |
|---|---|---|
| AC7 | G1 is fixed: `spike/` is out of the pack | `make export-pack-check && unzip -Z1 .godot/tmp/export-pack/game.zip \| grep -c '^spike/'` → 0 (with a positive control: `grep -c '^data/news/copy.json$'` → 1) |
| AC8 | The pack oracle is green and wired into `publish-dev`, strict there | `make export-pack-check`; `make -n publish-dev \| grep -c 'test_export_pack.gd'` → ≥ 1; under the `publish-dev` (strict) wiring, `make STRICT=1 export-pack-check-strict` is green and `grep -c "SKIP absent witness" $(SCRATCH)/export-pack.log` = 0 |
| AC9 | The oracle needs no export templates | `HOME=$(mktemp -d) make export-pack-check` → green |
| AC12 | `make test` is green locally and in CI | `make test`; the PR CI check `headless` |

Rig note on AC8's last clause: `$(SCRATCH)` is Make syntax; in a shell the runnable form is `.godot/tmp/export-pack.log` (`SCRATCH := .godot/tmp`, V26/`Makefile:9` — the same literal form AC3/AC4/AC6/AC7 already use). Recorded in Plan findings rather than edited here.

## Do-not-touch (AC10)

`demos/ship_geometry_demo.gd` and `demos/ship_consoles.gd` **must not be edited** in this sprint (PR #208's line; verified by AC10's `git diff --quiet`). The audit only **reads** them; their bundles (`ship_demo_bundle/*`, `ship_commons_bundle/*`) are already in `include_filter` (`export_presets.cfg:9`) and their literals classify without any edit. If PR #208 later adds a literal to those files, the fix is a table row in `tests/export_audit.gd` (DYNAMIC or DEV_ONLY) — the audit fails loudly until then (design risks row).

## Order

```
1  L6a T1  test file red (missing preload) — red log recorded
2  L6a T2  audit logic; first real run red on G1 (hip_v7.tsv) — red log recorded
3  L6a T3  G1 fix → green; 16/16 mutants killed
4  L6a T4  Makefile wiring; AC1–AC6, AC10, AC11; make test green
5  L6b T1  oracle red on scratch zips — red logs recorded
6  L6b T2  targets + STRICT; AC7–AC9
7  L6b T3  publish-dev line; AC12 make test; changelog fragment
```

Critical path: L6a → L6b (L6b preloads L6a·s classification seam). L6a T4 (Makefile) and L6b T1 can overlap, but L6b·s green runs need L6a·s G1 fix (the oracle asserts `spike/` count 0) and `classify()`.

## Velocity and estimate

Design estimate ~250 LOC (measured parts: audit ~140 with measured `AUTO_EXT`/non-resource-witness rule; test + 16 mutants ~65; oracle ~35 with measured forms; Makefile/preset ~10). Repo velocity data points: ~400 LOC/day observed (R1-SHIP-STAR-LIGHT 600 LOC in 1.5 days; free-nav-stops ~600 LOC in a day — recorded in `ship-ui-hud-consoles-sprint.md`, estimate header); R1-SHIP-UI delivered ~2,330 LOC in one day across three PRs (`sprint_R1-SHIP-UI.json` progress). At that pace this sprint is well inside one executor day; **1 day booked**, the slack going to mutation tuning (M13's base depends on the G1 edit order) and review.

**Split rule (not triggered):** neither milestone exceeds ~250 LOC (215 / 35), so no split. If L6a overruns, split at the natural seam: **L6a-1** = audit read-only (tables, rules, real arm, Makefile wiring, AC1/AC2/AC5/AC6) and **L6a-2** = the 16-mutant suite (AC3/AC4); L6b is atomic (an oracle you can't trust is worse than none — the strict/skips split stays).

## Pause points

- **P1 (non-blocking, attended):** the executor never runs `make publish-dev` (gcloud upload). The first real `publish-dev` with `export-pack-check-strict` wired happens attended with Mark; nothing unattended waits on it, and AC8 proves the strict path on the rig meanwhile. Charter row L6 is marked done and the design doc moves to `implemented/` at landing, not here.

## Plan findings (design/code deltas and choices fixed by this plan)

1. **`mkdir -p $(SCRATCH)` added to both new targets.** The design's step-7 snippet omits it; standalone `make export-filter-audit` (AC1/AC4) on a freshly imported tree would fail on the `>` redirect before the audit runs. Every existing Godot test target creates it first (`Makefile:38, 52, 86, 93`). One-line hardening, design intent unchanged.
2. **Surface-grep widened for AC5.** AC5 requires `make export-filter-audit` to *print* `scoped files N`, but the design's recipe grep `^(FAIL|export-filter-audit)` would swallow that line. The recipe greps `^(FAIL|UNCLASSIFIED|scoped files|distinct literals|filters|export-filter-audit)`; the strict summary-grep `^export-filter-audit: … , 0 failures$$` is unchanged, so a parse error that exits 0 still fails the target (the `Makefile:51-55` property).
3. **`publish-dev` wiring wording reconciled.** The L6b text says both `publish-dev: export-pack-check` and "runs as `export-pack-check-strict` (`STRICT=1`)". Fixed: `publish-dev: export-pack-check-strict`, a wrapper that recurses `$(MAKE) export-pack-check STRICT=1` and then requires `, 0 skips, 0 failures$$` in the log; plain `make export-pack-check` stays skip-tolerant. This satisfies AC8's `make STRICT=1 export-pack-check-strict` and the dry-run grep (GNU make executes `$(MAKE)` lines under `-n`).
4. **`STRICT` passage chosen** (design left it open): the recipe prefixes `STRICT="$(STRICT)"` on the Godot line; the script reads `OS.get_environment("STRICT")`.
5. **Mutation-input signature chosen** (design deferred the extra-literals argument name to the executor): `audit(include, exclude, mutations: Dictionary = {})` with keys `extra_literals` / `replace_literals` / `dynamic_rows` / `dev_only_rows` / `auto_ext`. A single Dictionary also covers the mutants the design's two-argument note does not reach (M8/M9/M14 mutate DYNAMIC rows; M12/M15 mutate AUTO_EXT). The real run always passes `{}`, and the scope walk + extraction run on every call, so no mutant bypasses the real pipeline (design rule 8).
6. **L6b seam named** (design: "reuses export_audit.gd classification", unnamed): `classify(include, exclude, mutations := {}) -> Dictionary`; `audit()` = classify + rule evaluation. `tests/test_export_pack.gd` preloads the same script.
7. **DEV_ONLY root-row matching chosen**: rows carry `exact: bool`; the root row `{"res://", "root, never read as a file", "", true}` matches only the bare literal (a prefix match on `res://` would swallow everything).
8. **AC8's last clause is Make syntax in a shell command** (`$(SCRATCH)/export-pack.log`): kept verbatim in the AC table above (mission rule), with the runnable shell form `.godot/tmp/export-pack.log` noted beside it (V26, `Makefile:9`).
9. **grep-count oracle semantics noted** (AC6, AC7, AC11): `grep -c` exits 1 when the count is 0; the printed count, not the exit code, is the oracle. No command changed.
10. **Literal totals:** my recount of distinct `"res://"` literals over all `.gd` gives **263** (matches the designer's V6 figure; the controller's was 262). Anti-vacuity floors sit below both; nothing load-bearing changes. No action.
11. **No in-repo precedent for `ZIPReader`/`String.matchn`** (git grep: only the design doc names them); `ConfigFile` and `DirAccess` have test precedent (`tests/test_ai_settings.gd`, `tests/test_ai_bridge.gd`). No action — both are first-party Godot 4.7.2 APIs and the reliance is deliberate (`matchn` = the exporter's own glob semantics, V12).
12. **Known, accepted blind spot** (carried from the design, not a disagreement): the raw captain PNGs are unverified statically and by the oracle — safeguarded only by the exported-app smokes. Relative paths with no `res://` literal (e.g. `"assets/planets"`, `planets/planet_smoke.gd:13`) are likewise smoke-covered. Do not widen scope in this sprint.
