# Designer scope review — Stapledon iteration 8
## M1.2b float32 writer + sidecars (proposed child: `M1.2b-T2_WRITER_SIDECARS`)

**Designer:** pi:ollama/glm-5.3:cloud (selected, scheduled iteration 8)
**Mode:** READ-ONLY scope review. No tools run, no edits made. Every codebase/runtime claim below is cited to the supplied record; claims measured on older pins are flagged for mandatory re-verification on the current pin.
**Environment:** AILANG v0.50.0 (CLAUDE.md pin; charter queue row 6: bumped attended 2026-10-01, `runtime/` restaged). Standing constraint this iteration: **no Python physics fallback**.

---

## 1. Scope verdict

**COVERED. ROUTE IT NOW, BOUNDED. No new design doc, no new human approval, no quorum.**

The float32 writer + sidecars task is not a new design: it is item (3) of the approved post-preflight dependency split, the explicitly-deferred remainder of the approved 2026-09-27 sprint, and the charter's `[NEXT]` queue row. What this review adds is the precise boundary the record left implicit: the writer task ends at *encoder + record assembly + sidecar emission + runner wiring + the carried test gaps (N1/N2, tier validation, unit-level 50,000 pin, coordinate guard)*; full-catalogue timing/parity, medium/large runs, fallback and commits are **out** and parked.

Two things must be **recorded, not silently applied**: (a) the quick-tier byte count in the retained acceptance row is arithmetically stale (see §9 P1); (b) the sidecar hash-computation split and stars.json key set are underdetermined in the record and are bounded here as implementation latitude, not new design.

---

## 2. Coverage: the approval trail that already rules this task

| Ruling | What it fixes for the writer |
|---|---|
| Design doc §M1.2 (m1-relativistic-sky.md), binary-format block | `stars_<tier>.bin`, little-endian float32 records `x,y,z,teff,v,flags` + JSON header (tier, count, source, version, checksums); "AILANG does all the physics conversion"; JSON stays for CNS5 only. |
| Design doc §M1.3, WD consumer contract (landed via WD-3, PR #12) | Flag semantics incl. bit 16 `TEFF_CLAMPED`; `checkWDRow` values (0.30 → teff 8941.61808557, v = G + 0.064716662329, flags 5; 2.5 → 3000.0, flags 21); "any Python fallback must reuse the package's generated table, never a second physics copy." |
| Sprint §M1.2b (m1-relativistic-sky-sprint.md), "Binary record" paragraph | 24 B LE f32; flags 1=WD, 2=MISSING_PHOT, 4=APPROX_TEFF, 8=BRIGHT; v=+99 sentinel; **sidecar schema verbatim**: `tier, count, count_excluded, source, format_version (1), record_bytes (24), fields, ailang, package, producer, sha256 {raw inputs, csv, bin}`; quick's human-readable `stars.json` "written by the same AILANG run"; `make catalogue TIER=…`, `make catalogue-parity`; FS in `sim/ailang.toml [effects].max`. |
| Sprint, iteration-4 scope correction, "Remaining dependency split" | **"(3) float32 binary writer plus IEEE-754 boundary tests and runner/sidecars; (4) complete-tier parity/performance integration before M1.2c. None is silently marked complete by a successful preflight."** — the ≤250-LOC-per-task regime and the writer/integration seam. |
| Sprint, iteration-7 refinement (T1) | "Writer/sidecars and full-catalogue timing/parity remain subsequent tasks"; T1's negative scope ("no FS/IO entry, binary writer, runner, sidecars, committed catalogue output") is this task's positive scope; the **Encoder correction for later writer** (normative formula, see §3.2); the **F4 production test table** restored for the writer; "Original production acceptance retained unchanged below; these are later full M1.2b gates"; Authorization paragraph: scope-preserving decomposition of the approved sprint, **"No new approval is needed for this refinement."** |
| Sprint JSON, `M1.2b-T1_TRANSFORM` notes (iteration 7) | "Carry both [N1/N2] to writer along with 50,000 boundary, tier validation and coordinate-range guard." |
| Sprint, iteration-7 checkpoint, N1/N2/N3(±N4/N5/N9) | The exact test gaps and residuals this task owns (§4). |
| Charter STATUS 2026-10-01 (iter 7) + Queue row 1 | **"[NEXT] bounded float32 writer/sidecars (N1/N2 test gaps, tier validation) → full-tier integration + 5-run VM parity → M1.2c …"** — the mission's routing order. |
| Ledger D-3 / D-4 / D-5 | Commits of tier binaries are M1.2c's (quick+medium only, large never); WD blackbody is the flagged D-4 approximation (already in the package, 0.3.0); bright tier accepted (D-5) → bit 8 reserved, implementation is M1.2d. |
| CLAUDE.md | Pin v0.50.0 (all gates `AILANG=$PWD/runtime/bin/ailang`); rule 3 package-first; rule 5 precision; rule 6 determinism; carried workarounds on v0.50.0: strict-VM bitwise ops rejected (ailang#1450), test-block literal pitfall (ailang#1456, call named `check…()`); upstream reporting via `ailang messages` with the gcp env. |
| Preflight evidence (iteration 4) and sky-model amendment | Runner pattern (subprocess, bounded timeouts, sha256 evidence, args-file, `.godot/tmp/` outputs); `std/fs` camelCase names, block-bodied `main`, no streaming FS; **strict VM cannot run FS** (evaluator-only); `std/array` and `std/list.range` evaluator-only on strict VM; T1 replaced `std/list.reverse` with pure foldl. |

**Duplicate/coverage gate (design-doc-creator skill):** the task is already enumerated in three approved artifacts; a new design doc would duplicate the approved M1 design §M1.2/§M1.3 and the sprint's M1.2b section. **Do not create one.** Quorum triggers: none fire — no new freeze items (everything frozen here was frozen by the approved sprint), no shared-machinery override (reuse of probed `std/fs`/`std/bytes`/`std/json`), no cost/schema-bank surface beyond the already-approved sidecar schema, premises in-repo and already measured.

---

## 3. Permissible bounded scope

### 3.1 In-scope behavior

1. **Pure f32 LE encoder** (the "hand-rolled float32 LE encoder" of the sprint feature row), authorized *here and only here* — iteration-7 explicitly withheld it from preflight ("No custom f32 implementation is authorized in preflight"). Contract, quoting the record's **Encoder correction** verbatim as normative:
   - `m = roundTiesToEven((abs(x)/2^e − 1)·2^23)`; carry at `m == 2^23` sets `m=0, e=e+1`; bits are `sign·2^31 + (e+127)·2^23 + m`.
   - Handle explicitly: **signed zero, subnormals, finite/range rejection, exponent boundaries**. Note (arithmetic, oracle-arbitrated): the fractional-mantissa identity only holds for normals (e ≥ −126); the subnormal branch (exponent field 0) and the 2^−126 boundary are separate cases. Finite inputs whose nearest f32 rounding is out of finite range are **refused fail-loud** (explicit row identification, no partial output) — never encoded as ±inf/NaN bytes, never clamped. `struct.pack('<f', x)` is the arbiter (it raises on out-of-range after round-to-nearest; the executor confirms and records this in the oracle harness).
   - Composition must be arithmetic — **no bitwise ops** in strict-gated code (ailang#1450, carried on v0.50.0).
   - If a std/bytes f32 builtin exists on the pinned runtime, it may replace the hand-rolled path **only** if every oracle/F4 test passes unchanged; the corrected formula remains the reference semantics.
2. **Record assembly**: 24 B per row, field order `x,y,z,teff,v,flags`, LE, exactly as the sprint's "Binary record" paragraph. The f32 quantization of coordinates is the designed behavior (the record is f32; the M1.3 loader consumes `PackedFloat32Array`).
3. **Sidecar emission**: `stars_<tier>.json` with exactly the sprint's field set, `format_version` 1, `record_bytes` 24; `count` = records written; `count_excluded` from the T1 selection counter (0 for quick/large). One AILANG implementation of the schema (the sidecar builder); the runner may supply inputs (hashes, versions, paths) and write the builder's output, or invoke the builder a second time — either way **sidecar bytes are deterministic** (no wall-clock, no `generated_at`-style fields; the lockfile-churn lesson). `sha256{raw inputs, csv, bin}` may be computed runner-side (`shasum -a 256`/hashlib; preflight precedent), provided every raw input consumed by the tier is present and matches `data/raw/SHA256SUMS`.
4. **Quick human-readable JSON emission** (`stars.json` path): implemented and proven on a **scratch output path** via the parameterized args. The working-tree `data/starmap/stars.json` is **not** replaced in this task — M1.2c owns "the rebuilt stars.json" commit. Suggested key set (implementation latitude, recorded): `{id, x, y, z, teff, v, flags}` — id being the one field the binary lacks.
5. **Thin FS shell + runner**: block-bodied `main`, `--caps IO,FS`, args-file driven, **input and output paths parameterized** (M1.2c's `catalogue-verify` explicitly requires output-path args). Runner (new stdlib Python or Makefile/shell — preflight pattern) only launches, times, hashes, cmp-compares and reports; **no per-record transformation, no physics, no catalogue byte production**. Bounded subprocess timeout (≈120 s for quick; timeouts are evidence, never silently a gate). Evidence under `.godot/tmp/catalogue-writer/`. Exact lock/package version checks (relativity 0.3.0) carried from preflight.
6. **Tier validation (N3)**: `make catalogue` accepts exactly `quick|medium|large`; missing `TIER` → usage refusal; unknown string → nonzero exit with explicit error. Bright is refused until M1.2d.
7. **Carried test gaps**: N1, N2, unit-level 50,000 pin, coordinate-range guard (§4).
8. **Hygiene (N4/N5/N9)**, only in touched functions: dead/redundant-branch declarations, refusal localisation, long-line readability. No behavior change; droppable first if the LOC cap pinches — tests are never dropped (T1 precedent).
9. **First task — v0.50.0 re-probe** (V17-recheck precedent): FS caps still in `ailang.toml`; `std/bytes`/`std/fs` names; block-bodied-main behavior; strict-VM surface for the touched builtins; real `data/raw/*.csv` end with exactly one trailing newline. Results recorded; any *new* gap → upstream report, never a silent workaround.

### 3.2 Allowed files

- `sim/tools/catalogue.ail` (extend: pure encoder + sidecar builder + tier validation + thin FS shell; T1's transform/selection exports untouched in behavior)
- `sim/tools/catalogue_test.ail` (extend: new named checks)
- `sim/ailang.toml` (only if export/effects wiring needs it; FS already present from preflight)
- `Makefile` (add `catalogue` target; `catalogue-probe` remains a frozen preflight benchmark)
- `tools/catalogue_runner.py` (new, stdlib only) — or equivalent Makefile/shell orchestration
- `tools/test_catalogue_writer_oracle.py` (new unittest; `tools/test_extract.py` precedent)
- `tools/fixtures/writer_anchors.*` (anchor floats + expected bytes **generated by struct.pack at authoring time**, real-generated not hand-typed; M1.2a fixture rule)
- Docs excluded from the LOC cap: optional one-line CLAUDE.md/README mention of `make catalogue`

**Forbidden in this task:** `tools/catalogue_fallback.py`; any Python per-record physics/encoding; `tools/extract.py`, `download_stars.sh`, `sky/`, `main.gd`, `bridge/`, `sim/core.ail`, `sim/ship.ail`, `physics/`, Godot `tests/`; the starmap-manager skill, `status.sh`, `.gitignore` (all M1.2c); anything bright (M1.2d); the package repo and lock version (stay `sunholo/relativity@0.3.0`, no publish); loader/shader work (M1.3); CI workflow changes; committing anything (executor stages nothing; controller commits — T1 pattern).

### 3.3 Out of scope — do not silently enlarge

- **No medium or large production runs**, not even informally: `make catalogue TIER=medium|large` is wired and tier-validated but not executed here. Full-tier integration + 5-run VM parity + six wall times + the medium 1,200,000 B / `count_excluded > 0` gates + the >60 s fallback-trigger evaluation are the **subsequent bounded slice** (iteration-4 split item 4; T1 checkpoint: "binary writing/full-catalogue integration remain [pending]" — writer lands the binary writing, integration owns the full-catalogue part).
- No tier commits (M1.2c, D-3), no stats tool, no `catalogue-verify` target, no loader.
- No schema/threshold/tier-rule changes of any kind (§5).

---

## 4. N1/N2/N3 disposition (iteration-7 notes)

| Item | Record text (abridged) | Disposition in this task |
|---|---|---|
| **N1** | "add dwarf BP-RP 2.5 expecting flags0 and −0.5 expecting16, so replacing bpRpInTable with WD invertibility fails. Controller reproduced flags0→16 while existing transformVm remains green." | **In scope, mandatory.** Two exact-flag transform assertions in `catalogue_test.ail`. Load-bearing for the writer: the flags field is written bytes. |
| **N2** | "explicitly reject a data row followed by two trailing newlines. Controller reproduced a two-strip mutant accepted it while transformVm stayed green." | **In scope, mandatory.** Refusal test for input ending `…row\n\n`; contract stays "trailing empty line is allowed" (singular). If a real CSV violates the single-trailing-newline contract, record and park — no silent stripping in the catalogue tool (extract.py is M1.2a's landed domain). |
| **N3a** | "Writer validates quick/medium/large tier names; unknown strings currently pass through." | **In scope, mandatory** (§3.1 item 6). |
| **N3b** | "full integration pins exactly 50,000 at the boundary (49,999 mutant survives the small fixture)." + T1 notes carry "50,000 boundary" to writer. | **Split, nothing dropped.** Writer adds the unit-level pin: (i) production medium-limit == 50,000 assertion (kills 49,999/50,001 constants); (ii) helper boundary case — limit k with k+1 complete rows selects exactly k, stable order, correct counters. The authoritative pin (real medium = exactly 1,200,000 B) stays with integration, per N3's own "full integration" wording. This reconciles the carry lists without a 50k-row fixture. |
| **N3c** | "Restrict or safely compare squared distances before binary64 overflow for input ranges beyond the catalogues." + T1 evidence: "huge-coordinate distance overflow [is an] explicit review residual." | **In scope, either route, recorded.** (a) order-preserving safe comparison, or (b) an explicit documented magnitude bound with refusal — far outside any real catalogue row (GCNS ≤ 100 pc ≈ 326 ly), so no real row is affected. Either way: deterministic, tested (a two-row huge-coordinate fixture whose naive d² overflows to inf must still order correctly or refuse identically), and the chosen route + rationale recorded in notes. No real-data behavior change; if the controller judges route (b) a contract change, it parks — but the residual may not be silently dropped. |

N4/N5/N9: opportunistic hygiene only (§3.1 item 8).

---

## 5. Implementation detail vs changed design

| Implementation detail (permitted, no new approval) | Changed design (parked; §9) |
|---|---|
| Encoder internals under the normative corrected formula; div/mod byte composition; builtin-instead-of-hand-rolled iff oracle-identical | Any change to the 24 B layout, field order, flag bits (1/2/4/8/16), sentinels (teff 0, v +99), `format_version` |
| Where sha256 is computed (AILANG vs runner), provided fields/determinism/provenance hold | Adding/dropping/renaming sidecar schema fields |
| Single file vs `catalogue_main.ail` split; runner language (shell vs stdlib Python) for orchestration | Tier definitions, the 50,000-nearest rule, missing-photometry policy, WD policy (D-4), sources |
| Output/input path args, scratch-vs-default destinations, runner report layout | The fallback (trigger evaluation, `tools/catalogue_fallback.py`) — plus the brief's standing "no Python physics fallback" |
| N1/N2/N3 tests, unit 50,000 pin, hygiene | Medium/large full runs, 5-run full parity, six wall times, timing thresholds |
| Data-derived quick count (5,908 → §9 P1 amendment) | Committing binaries (M1.2c, D-3); bright tier (M1.2d, D-5); loader (M1.3) |
| stars.json key set at emission (recorded; M1.2c finalizes the committed rebuild) | New package code; physics outside `sunholo/relativity`; any publish |

---

## 6. Required tests (mutation each kills)

| Test | Obligation / mutation killed |
|---|---|
| `checkF32LEVectors` (F4) | 1.0→[0,0,128,63]; −2.5→[0,0,32,192]; 99.0→[0,0,198,66]; 0.0→zeros. Wrong endianness, bias or sign. |
| `checkF32LECarry` (F4, corrected 2^23 premise) | Fractional mantissa rounding to 2^23: reset + exponent carry; signed-zero [0,0,0,128]; subnormal anchors (min/max/mid subnormal, 2^−126 boundary, 2^−150 half-min-subnormal tie); half-ULP ties incl. the boundary tie 2−2^−23 → 2.0; f32max accepted. |
| Oracle harness (`tools/test_catalogue_writer_oracle.py`) | AILANG encoder == `struct.pack('<f', x)` over the committed anchor set; refusal set {NaN, ±inf, out-of-range finite} → explicit Result refusal, no bytes. Kills ties-away-from-even, bias drift, subnormal mishandling. |
| `checkMissingPhotEncoding` (F4, byte level) | Missing G or BP−RP → full 24 B record with teff 0.0, v 99.0, bit 2 (+1 if WD). Silent clamp/default. |
| `checkWDRow` encoding (F4 / §M1.3 contract) | WD 0.30 → teff 8941.61808557, v = G + 0.064716662329, flags 5; 2.5 → 3000.0, flags 21. Flag loss, second physics copy. |
| `checkMediumSelection` encoding (F4) | Five-row interleaved fixture, helper limit 2 → two named complete rows in distance order, excluded=2; count/count_excluded land in the sidecar. Selection-before-sort, file-order, dropped rows. |
| N1 discriminators | Dwarf 2.5 → flags 0; dwarf −0.5 → bit 16. Kills the WD-invertibility predicate swap (controller-reproduced). |
| N2 refusal | `…row\n\n` refused. Kills the two-strip mutant (controller-reproduced). |
| Tier validation | quick/medium/large accepted at the validation layer; unknown/missing TIER refused nonzero with explicit message. Kills tier passthrough (controller-reproduced). |
| 50,000 unit pin | Constant assertion + helper boundary (k+1 complete rows → exactly k). Kills 49,999-class constants. |
| Coordinate guard | Huge-coordinate fixture orders correctly or refuses identically where naive d² = inf. Kills overflow-ordering mutant. |
| Sidecar schema verifier | Exact field/nested-key set; count×24 == bin size; `shasum -a 256` match; no timestamp-like keys. Kills field-drop/add. |
| Determinism | Two consecutive quick runs cmp-identical (bin + sidecar). CLAUDE.md rule 6; preps M1.2c's `catalogue-verify`. |
| Mutant re-application gate | Re-apply the four carried mutants (N1 swap, N2 double-strip, 49,999, tier passthrough) + encoder mutants → named tests BAD; restore byte-identical (sha256 before/after) — iter-7 practice. |

Named `check…()` functions in test blocks (ailang#1456). Strict-gated pure code avoids bitwise ops, `std/array`, `std/list.range`, `std/list.reverse` (carried strict-VM gaps; T1's foldl pattern).

---

## 7. Acceptance checks (all with `AILANG=$PWD/runtime/bin/ailang`, pinned v0.50.0)

1. **G0 probe record**: v0.50.0 re-probe results (§3.1 item 9) in evidence; no blocking finding, or a parked gate with upstream report.
2. `make deps AILANG=$PWD/runtime/bin/ailang` — green; lock shows `sunholo/relativity@0.3.0`; no re-pin; `generated_at` ignored when diffing.
3. `runtime/bin/ailang check --package sim` — exit 0.
4. `runtime/bin/ailang test --package sim` — exit 0, including every §6 check.
5. **Strict/parity machinery**: writer pure entries (encoder, sidecar builder) strict-VM == interpreter, `cmp`, inside the existing `make test`/`strict` pattern T1 established (FS shell stays outside strict — evaluator-only, iteration-4 evidence; shell equality is covered by G8).
6. `python3 tools/test_catalogue_writer_oracle.py` — PASS. `python3 tools/test_extract.py` — still 15/15.
7. `make catalogue TIER=quick AILANG=$PWD/runtime/bin/ailang` — exit 0; `data/starmap/stars_quick.bin` = **5,908 × 24 = 141,792 B** (recorded amendment vs the retained 141,816, §9 P1 — never pad); sidecar schema-exact and consistent; second run cmp-identical; wall time recorded as evidence only.
8. `make catalogue TIER=bogus …` → nonzero + explicit unknown-tier error; bare `make catalogue` → usage refusal.
9. **Fixture parity**: interpreter ×1 == VM ×5, `cmp`-identical bin **and sidecar bytes**, on a fixture spanning normal/WD/missing/clamped rows; report JSON under `.godot/tmp/catalogue-writer/`.
10. Mutant-kill gate (§6 last row) — all named mutants BAD, byte-identical restoration.
11. `make test AILANG=$PWD/runtime/bin/ailang AILANG_BIN=$PWD/runtime/bin/ailang` — rc 0 (full headless suite, CI-equivalent).
12. **LOC**: ≤ 250 changed code/test/config lines (docs/evidence excluded; iteration-4 accounting precedent). **No render-affecting file touched** (no visual gate applies — no SR/GR visual merges here, charter guardrail satisfied).
13. **Independent evaluator** (different model from executor, per charter routing) — PASS, zero blockers on the carried items; parent `M1.2b` remains `passes: null`; evidence in `.ailang/state/evidence/iter8/`; report to issue #1.

Estimated ~230 code/test/config LOC (encoder ~70, sidecar+shell ~50, runner/Makefile ~30, tests ~80); hard cap 250; one executor session.

---

## 8. Stop conditions

1. **Any VM/interpreter divergence** in new pure code → shrink to minimal repro, report upstream (`ailang messages`, gcp env, `--from stapledons_godot`), park the affected gate. Never a silent workaround (charter guardrail).
2. **v0.50.0 probe reveals missing/renamed builtins or new strict-VM gaps** → record + upstream report; if blocking, stop with evidence.
3. **Oracle mismatch** irreconcilable under the normative formula (e.g., float division semantics break ties-to-even) → park; never weaken the `struct.pack` oracle.
4. **Quick run unbounded-slow or blocked by a VM bug** → stop, record timing; the >60 s medium fallback trigger is *not* evaluated here and the fallback is not built (parked, §9 P2).
5. **LOC overflow** → stop with partial evidence and split (encoder-only vs runner/sidecar); never drop tests.
6. **Real CSV violates the single-trailing-newline contract** → record and park (M1.2a domain); no silent strip.
7. **Any pressure to touch** schema/flag bits/sentinels/thresholds/tier rules, run medium/large, commit binaries, build the fallback, add bright, change the loader, or modify the package → out of scope; park.
8. **141,816 vs 141,792 contested** → never pad records to match a stale number (the skipped CNS5 placeholder row has no position and padding would violate AC2's no-defaulted-rows clause); park for the recorded amendment.

---

## 9. Parked for human/controller (no direction authorized here)

- **P1 — Quick byte-count amendment.** The retained row says `5,909 × 24 = 141,816 B`; the landed, evaluated M1.2a parser reports **5,908 rows (1 skipped placeholder)**, so the gate's correct arithmetic is **141,792 B**. This is a measured implementation correction in the M1.2a amendment precedent ("AMENDED iter 2, controller-adjudicated"), but it must be **recorded by the controller**, not silently applied and not gamed. Recommend amending the retained M1.2b row with provenance when integration lands; writer asserts `size == count × 24` with count data-derived.
- **P2 — Fallback.** Trigger evaluation + `tools/catalogue_fallback.py` = subsequent bounded task, gated on integration's measurements, must reuse package physics for WD too (design §M1.3; sprint "A fallback is a subsequent bounded task…"), and is currently barred by this iteration's standing "no Python physics fallback" constraint.
- **P3 — Full-tier integration**: medium/large runs, 5-run full parity + six wall times, medium 1,200,000 B and `count_excluded > 0` gates, large or fallback path, timing thresholds.
- **P4 — M1.2c**: stats tool, `process_stars.sh` removal, skill/`status.sh`/`.gitignore`, tier commits (D-3).
- **P5 — M1.2d bright tier** (D-5; bit 8 reserved only; `teffFromBV` ships in 0.4.0).
- **P6 — M1.3 loader** (version/checksum checks consume the sidecar produced here).
- **P7 — Any schema/flag/sentinel/threshold/tier-rule change**, any new package code or publish.
- **P8 — Coordinate "restrict" route**, if the controller judges the documented magnitude-bound refusal a contract change (my ruling permits it with mandatory recording; contested → human).
- **P9 — Committed stars.json format finalization** (M1.2c commits the rebuild; writer proves emission on scratch).

---

## 10. Bookkeeping (controller's, not mine — I make no edits)

- Register a child row (suggest `M1.2b-T2_WRITER_SIDECARS`, est. ~240 LOC, cap 250) in `sprint_R1-M1-SKY.json` mirroring T1's style, transcribing §3/§7 here into an iteration-8 refinement block; executor updates only `passes`/`started`/`completed`/`notes`; parent M1.2b stays `passes: null`.
- Executor ≠ evaluator (charter routing); evidence in `.ailang/state/evidence/iter8/`; iteration report to issue #1; upstream reports via `ailang messages` with the gcp env.
- No new design doc, no quorum, no human gate: no M1 open question is touched (1→D-10, 3→D-4, 5→D-5 all resolved; 2 and 4 untouched), no publish, no visuals, no pillar surface.

## 11. Verdict restated

The writer/sidecars task is fully pre-authorized by the approved sprint's M1.2b section, the iteration-4 dependency split item (3), the iteration-7 refinement (encoder correction + F4 table + explicit deferral), and the charter's `[NEXT]` queue row, under the same scope-preserving-decomposition authorization T1 used. Route it as a ≤250-LOC bounded task: corrected fractional-mantissa f32 LE encoder with oracle-pinned boundary behavior, 24 B record assembly, schema-exact deterministic sidecars, thin FS shell + runner with parameterized paths, tier validation, and the carried N1/N2/50,000-unit/coordinate-guard test gaps — with the quick tier (141,792 B, amendment recorded) as the only full-tier execution. Everything beyond that — medium/large runs, full parity and timing, fallback, commits, bright, loader — stays parked for the integration slice and the human where applicable.