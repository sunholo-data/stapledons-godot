# M1.2b freshness review, iteration 4

Pinned designer lane: codex:gpt-6.1-sol. Review only; no implementation, git writes, second design document, or direction changes. Base 06311aa. Read CLAUDE.md, design_docs/README.md, authoritative design-doc-creator skill and local game-vision-designer skill. Prior narrow-refinement quorum is accepted context, not rerun here.

## Verdict

Existing approved direction remains valid. Amend the already approved sprint narrowly before execution: package-first WD prerequisite and a corrected float32 encoder are required. Runtime-risk wording must reflect v0.47.2. No measured catalogue timing is available at this base; do not turn a five-thousand-row extrapolation into an acceptance measurement.

## Findings and proposed amendments

1. **WD location:** task 2 explicitly places a new Planck integration, color residual and inversion in catalogue.ail. CLAUDE rule 3 requires new physics formulas in sunholo/relativity first, tested, changelog/release-kind, quality without gates and published, then sim pin. Keep D-4's approved approximate fit and flags. Move that exact approximation into the package; catalogue calls its API. Package 0.2.0 exposes normal-dwarf photometry and Planck, but WD model search is empty with export positive control (E6). A package prerequisite is necessary, not a new design direction.
2. **WD specification remains underdetermined:** approved D-4 says approximate blackbody, flagged in data and UI. Sprint supplies rectangular intervals, but no BP/RP zero-point ratio/reference spectrum, photon versus energy weighting, quadrature step, numerical grid or residual tolerance. Planck returns spectral radiance up to a common constant (E12). That common constant cancels in a ratio; *band-specific magnitude zero points do not*. The conversion needs an explicit convention such as BP-RP = -2.5 log10(F_BP/F_RP) + Z_BP-RP and a justified Z. Do not equate raw integrated radiance ratio directly to observed Gaia color. Fixed 4000–60000 test bounds alone cannot establish calibration. Package designer must freeze and test normalization within D-4 approximation before production catalogue execution. If choosing normalization changes accepted physical meaning, return to the human; unresolved normalization is an execution gate now.
3. **Float32 encoder correction:** old text defines m=round((a/2^e-1)*2^23), a fractional mantissa, but then subtracts 2^23 and carries at 2^24. For x=1 it yields bits 126*2^23, encoding 0.5. Use one consistent convention: q=roundTiesToEven((a/2^e)*2^23); if q==2^24, increment e and set q=2^23; bits=sign*2^31+(e+127)*2^23+(q-2^23). Alternatively retain fractional m and carry at 2^23, resetting m=0. Add tie-even, carry, negative, zero and Python struct.pack('<f') reference vectors. Preserve 24-byte six-float format and exact integer flags. These are transport maths, not new astrophysics.
4. **Encoder domain:** distance >=0.1 ly does not bound individual x/y/z components away from zero; finite values alone also do not establish float32 representability. Replace the assertion with per-scalar domain checks (zero or normal representable value, if retaining normal-only scope), rejecting unhandled subnormals/overflow explicitly. No claim that all real catalogue components satisfy it is established without full data. Signed-zero policy must be explicit (old text canonicalizes zero).
5. **VM bug premises:** upstream changelog records #1354/#1355 fixes; current make strict passes both shared-record real-game paths (E7). Remove mandatory 'no custom record types because bug 1354' and blanket nondeterminism wording. Named records may be used subject to actual catalogue strict pure-transform/parity probes. Keep interpreter plus five VM runs as useful determinism acceptance, without asserting the old bug remains. Existing test success is not proof future catalogue performance or exhaustive VM correctness.
6. **Existing bytes/FS APIs:** fromInts/concatList imports check and strict execution succeed on the pinned runtime (E8). Existing std/fs also exposes appendFileBytes, documented O(1) per call (E9); no float32 helper is exported by inspected std/bytes (E10). Reuse APIs; do not implement bytes concatenation/writes anew. Single concatList plus writeFileBytes is still valid approved direction. The claim 'no streaming API' is too broad; input readFile is whole-file, binary output append exists. No input-line API claim is made here beyond enumerated exports.
7. **Perf risk:** cached package interpolation does repeated nth_or accesses (E6), so actual 5k CSV parse+photometry+WD and encoder timing remains necessary. 'No unboxed Array on v0.45.0' is obsolete/unverified for v0.47.2 and must be deleted or checked anew; not a reason to prohibit named records. No raw catalogue or catalogue tool exists at this base (E11); full medium/large times and FS bridge counters are PENDING, not measured. Probe must include sorting, bytes construction, WD share and IO time, report memory/bridge observations, then run full medium for the >60s trigger. Keep quick/medium/large selections, missing sentinels and fallback threshold unchanged.
8. **Fallback completeness:** if triggered, normal-dwarf table extraction alone cannot reproduce the newly package-owned WD fit. Fallback must consume a package-produced representation for *all* physics or call the package WD function; sampled cross-check must include WD, missing, clamped and normal rows. Do not quietly create independent Python WD physics. Package-version/hash path changes alongside pin; old hardcoded 0.2.0 path is stale once prerequisite publishes.
9. **Shell contract:** printed signature has five string args while recipe supplies seven including hashes. Amend signature to seven args (or a clearly specified aggregate), preserving package-dir and capability flags; sim currently allows only IO, so FS manifest addition remains required before filesystem shell check. Parser input schema is measured as id,x,y,z,G,BPRP,wd (E11). Exact quick count should be validated from extraction output rather than inferred solely from nominal 5909; medium 50000 complete nearest remains approved criterion.

## Vision and human gates

ALIGNED: Choices Are Final 0; The Game Doesn't Judge 0; Time Has Emotional Weight +1; The Ship Is Home +1; Grounded Strangeness +2; We Are Not Built For This 0. Normative hard-science specification +2 as an additional constraint, not a seventh pillar. Net +6, same direction. Pillar six was missing from old table; add its neutral row if touching alignment. No fresh player-facing decision is proposed.

Production execution gates: package WD normalization/specification and publication prerequisite; float32 correction/domain fixtures; actual runtime perf probe. Human authorization remains the existing project/controller gate for outward package publication; reviewer does not infer fresh permission. Any changed WD physical approximation must be adjudicated against D-4. Pure preflight/probe can be scoped now without asserting production catalogue readiness.

## Measured verification log

Commands below executed in the iteration-4 worktree. Every absence assertion includes a named positive control. Exit status is recorded. Source inspection identifies upstream fix evidence; live make strict supplies local behavior evidence.

### E1

```sh
git rev-parse HEAD; runtime/bin/ailang --version
```

Exit 0

```text
06311aa35979af86b100a5f6ecb1e3d47435ee2e
AILANG v0.47.2
Commit: e939cba
Full:   e939cba032c0f38fbecffb47e8261fb58e1a2ca1
Built:  2026-09-28T15:53:12Z

The AI-First Programming Language
Copyright (c) 2025-2026
```

### E2

```sh
rg -n 'v0.47.2|Physics maths|New formulas' CLAUDE.md sim/ailang.lock .github/workflows/*
```

Exit 0

```text
.github/workflows/ci.yml:13:      AILANG_VERSION: v0.47.2
sim/ailang.lock:2:  "ailang_version": "v0.47.2",
sim/ailang.lock:4:  "generator": "ailang lock v0.47.2",
CLAUDE.md:23:AILANG is pinned to **v0.47.2** (CI, the bundled runtime and the lockfile move together; bump all three at once). Use the same version on `PATH`, or `AILANG=runtime/bin/ailang`. Use `--package-dir sim` for `run`, `--package sim` for
CLAUDE.md:84:3. **Physics maths lives in `sunholo/relativity`.** New formulas go into the
CLAUDE.md:107:- **Known workarounds (found on v0.45.0; re-check each on v0.47.2 before relying on it):**
```

### E3

```sh
rg -n 'D-4' design_docs/stapledon-mission.md
```

Exit 0

```text
115:  amendment accepted, D-3 quick+medium tiers in git, D-4 approximate WD fit.
143:| D-4 | RESOLVED | White dwarfs in M1: approximate blackbody fit, flagged approximate (design open question 3). Recommendation: yes. Default: yes, when M1.2 starts.  **ANSWERED — YES: approximate blackbody fit for white dwarfs in M1, flagged approximate in data and UI (Mark, attended 2026-09-28: "record decisions as ratified").** (Mark Edmondson, attended 2026-09-28, recorded directly in this ledger.)| Handover comment on #1; `photometry` 0.2.0 deliberately has no WD model.  **Attended ruling 2026-09-28** — recorded in-session under the ATTENDED LEDGER EDITS contract, not via the bookkeeping issue. Provenance is the ATTENDED SESSION, not the commit author: this script stamps a fixed attended identity for EVERY caller (ATT_NAME/ATT_EMAIL are defaults, not derived from the invoker), and nothing in scripts/mission_decisions.sh or the mission-control skill reads the commit author of a ledger resolution (verified 2026-09-04, positive-controlled). The control is the charter rule that the UNATTENDED loop may not resolve a row on its own behalf.|
```

### E4

```sh
sed -n '405,455p' design_docs/planned/r1/m1-relativistic-sky-sprint.md
```

Exit 0

```text
  `catalogue-verify`)
- `tools/catalogue_fallback.py` (new only if the trigger fires, ~120 LOC)

**Tasks (in order)**
1. **Perf probe before the design hardens.** `head -5001 data/raw/gcns.csv >
   data/raw/probe5k.csv`; run the CSV parse + photometry path (task 2) over
   it on the VM, time it, extrapolate ×10 (medium) and ×66 (large) and
   record all three numbers in the sprint JSON notes. Rationale: package
   photometry interpolates by a recursive `nth_or` scan over a ~50-node
   table (seen in the 0.2.0 cache), so per-row cost is hundreds of builtin
   calls, and there is no unboxed `Array[float]` on v0.45.0.
2. **Pure transform** in `catalogue.ail` (no custom record types — bug
   1354):
   - `parseCsv(text) -> [[string]]` via `split(text, "\n")`, skip header,
     `split(line, ",")`; floats via `stringToFloat`, empty string → `None`.
     Build rows by list prepend and one `reverse` at the end. Never index
     with `nth_or` in a loop (the O(n²) trap measured in the M1.1 notes).
   - Tier selection on parsed GCNS rows: sort by `x²+y²+z²` with the
     prelude's stable iterative `sortBy(cmp, rows)`. quick = CNS5 rows
     unsorted; large = all rows; medium = walk sorted rows, take rows with
     both G and BPRP present until 50,000 are taken, counting skipped
     (missing-photometry) rows as `count_excluded`.
   - Photometry per row, using `pkg/sunholo/relativity/photometry`
     (`teffFromBpRp`, `vFromG`): normal row → `teff = teffFromBpRp(bprp)`,
     `v = vFromG(g, bprp)`; clamping stays inside the package (the tool
     never clamps). WD row (`wd = 1`) with complete photometry → D-4 path
     below, flags = 1 ∥ 4. Row with null G or null BPRP → `teff = 0.0`,
     `v = 99.0`, flags get bit 2 (the verbatim quorum encoding; 99.0 is
     the +99 sentinel, exact in float32).
   - **Where the WD teff comes from (D-4, accepted; package 0.2.0 has no WD
     model):** catalogue.ail computes it as a least-squares fit of the
     package's `blackbody.planck(lNm, kelvin)` integrated over two
     approximate rectangular Gaia passbands (BP 505–680 nm, RP 640–1050 nm,
     stated as approximations of the EDR3 response curves in a comment),
     scanning T over a fixed grid and refining by bisection on the BP−RP
     residual. It sets flags bit 4 (`APPROX_TEFF`) so the approximation is
     visible in data. A proper Gaia-passband WD model remains a package
     item, deferred by D-4.
3. **float32 LE encoder** (`f32LE`): for x = 0 → `[0,0,0,0]`; otherwise
   e = `floor(log(|x|) / log(2))` refined by comparing `|x|` against
   `pow(2, e)` and `pow(2, e+1)`; m = `round((|x| / pow(2, e) − 1) * 2^23)`;
   if `m = 2^24` then `e += 1, m = 2^23` (the mantissa carry); bits =
   sign·2³¹ + (e+127)·2²³ + (m − 2²³); bytes little-endian via
   `bitwiseAnd`/`shiftRight`; record = 6 floats → `fromInts([24 bytes])`;
   file = one `concatList` over the per-record bytes; one `writeFileBytes`.
   All inputs are in normal float32 range (positions ≥ ~0.1 ly, teff ≤
   100000, v ≤ 99), so no subnormal path; assert finite via the M1.6 rule
   (self-equal, magnitude ≤ 1e308).
4. **Shell:** `export func main(tier, csvPath, binPath, hdrPath,
   jsonPath: string) -> () ! {IO, FS} { ... }` (block body — see the probe
   note above). Header JSON via std/json `jo`/`kv`/`jnum`/`jint`/`encode`;
```

### E5

```sh
cat sim/ailang.toml; sed -n '1,33p' sim/ailang.lock
```

Exit 0

```text
[package]
name = "stapledons/sim"
version = "0.1.0"
edition = "1"
description = "Stapledon's Voyage simulation (runs as a Godot sidecar over NDJSON stdio)."

[exports]
modules = ["stapledons/sim/core", "stapledons/sim/ship"]

[effects]
max = ["IO"]

[stability]
level = "experimental"

[dependencies]
"sunholo/relativity" = "0.2.0"
{
  "ailang_version": "v0.47.2",
  "generated_at": "2026-09-28T17:48:11.017944Z",
  "generator": "ailang lock v0.47.2",
  "packages": [
    {
      "ailang": ">=0.45.0",
      "content_hash": "sha256:1af50b9d22d5e975b1d9fa0d3236590f127894ed55ad9cde36ca8bdf1f28868d",
      "effects": [
        "IO"
      ],
      "exports": [
        "sunholo/relativity/blackbody",
        "sunholo/relativity/hyper",
        "sunholo/relativity/journey",
        "sunholo/relativity/kinematics",
        "sunholo/relativity/optics",
        "sunholo/relativity/photometry",
        "sunholo/relativity/photometry_table",
        "sunholo/relativity/schwarzschild"
      ],
      "interface_hash": "sha256:f84d983078af293159a6343d094d40dde7b225abe3c8b36871a9282da94673bb",
      "name": "sunholo/relativity",
      "source": "registry",
      "version": "0.2.0"
    }
  ],
  "schema": "ailang.lock/v1",
  "schema_version": "1.0.0"
}
```

### E6

```sh
rg -n 'export.*func|nth_or' /Users/voightkampff/.ailang/cache/registry/sunholo/relativity/0.2.0/photometry.ail; rg -n -i 'wd|white.dwarf' /Users/voightkampff/.ailang/cache/registry/sunholo/relativity/0.2.0/*.ail; test $? -eq 1 && echo 'WD search empty; positive control exports above'
```

Exit 1

```text
7:import std/list (length, nth_or)
13:  let left = nth_or(xs, i, 0.0);
14:  let right = nth_or(xs, i + 1, left);
15:  let yLeft = nth_or(ys, i, 0.0);
16:  let yRight = nth_or(ys, i + 1, yLeft);
25:  if x <= nth_or(xs, 0, 0.0) then nth_or(ys, 0, 0.0)
26:  else if x >= nth_or(xs, last, 0.0) then nth_or(ys, last, 0.0)
31:export pure func teffFromBpRp(bpRp: float) -> float
38:export pure func gMinusV(bpRp: float) -> float {
43:export pure func bpRpInTable(bpRp: float) -> bool
50:export pure func vFromG(g: float, bpRp: float) -> float = g - gMinusV(bpRp)
54:export pure func illuminanceFromV(v: float) -> float
62:export pure func fluxRatioFromMags(m1: float, m2: float) -> float
/Users/voightkampff/.ailang/cache/registry/sunholo/relativity/0.2.0/relativity_test.ail:32:pure func fwd() -> Vec3 = { x: 0.0, y: 0.0, z: -1.0 }
/Users/voightkampff/.ailang/cache/registry/sunholo/relativity/0.2.0/relativity_test.ail:36:pure func angleFromFwd(v: Vec3) -> float = deg(acos(dot(v, fwd())))
/Users/voightkampff/.ailang/cache/registry/sunholo/relativity/0.2.0/relativity_test.ail:149:  near(angleFromFwd(aberrate(side(), fwd(), atanh(0.9))), 25.841932763167, 0.000000001)}
/Users/voightkampff/.ailang/cache/registry/sunholo/relativity/0.2.0/relativity_test.ail:154:  near(angleFromFwd(aberrate(side(), fwd(), atanh(0.5))), 60.0, 0.000000001)}
/Users/voightkampff/.ailang/cache/registry/sunholo/relativity/0.2.0/relativity_test.ail:159:  near(angleFromFwd(aberrate(fwd(), fwd(), 3.0)), 0.0, 0.0000001) &&
/Users/voightkampff/.ailang/cache/registry/sunholo/relativity/0.2.0/relativity_test.ail:160:  near(angleFromFwd(aberrate(back(), fwd(), 3.0)), 180.0, 0.0000001)}
/Users/voightkampff/.ailang/cache/registry/sunholo/relativity/0.2.0/relativity_test.ail:165:  near(norm(aberrate({ x: 0.3, y: 0.4, z: -0.866 }, fwd(), 2.1)), 1.0, 0.000000000001)}
/Users/voightkampff/.ailang/cache/registry/sunholo/relativity/0.2.0/relativity_test.ail:171:  let r = deaberrate(aberrate(n, fwd(), atanh(0.99)), fwd(), atanh(0.99));
/Users/voightkampff/.ailang/cache/registry/sunholo/relativity/0.2.0/relativity_test.ail:183:  near(doppler(fwd(), fwd(), phi), sqrt(19.0), 0.000000000001) &&
/Users/voightkampff/.ailang/cache/registry/sunholo/relativity/0.2.0/relativity_test.ail:184:  near(doppler(back(), fwd(), phi), sqrt(1.0 / 19.0), 0.000000000001) &&
/Users/voightkampff/.ailang/cache/registry/sunholo/relativity/0.2.0/relativity_test.ail:185:  near(doppler(side(), fwd(), phi), 1.0 / sqrt(0.19), 0.000000000001)}
/Users/voightkampff/.ailang/cache/registry/sunholo/relativity/0.2.0/relativity_test.ail:190:  near(dopplerApparent(side(), fwd(), atanh(0.9)), sqrt(0.19), 0.000000000001)}
/Users/voightkampff/.ailang/cache/registry/sunholo/relativity/0.2.0/relativity_test.ail:197:  near(dopplerApparent(aberrate(n, fwd(), phi), fwd(), phi), doppler(n, fwd(), phi), 0.000000001)}
/Users/voightkampff/.ailang/cache/registry/sunholo/relativity/0.2.0/relativity_test.ail:202:  rel(doppler(back(), fwd(), 19.0), 0.000000005602796437537268, 0.000000000001)}
/Users/voightkampff/.ailang/cache/registry/sunholo/relativity/0.2.0/optics.ail:60:-- with gamma - 1 = 2 sinh^2(phi/2). Sources crowd toward bh.
/Users/voightkampff/.ailang/cache/registry/sunholo/relativity/0.2.0/_smoke.ail:18:  let fwd = { x: 0.0, y: 0.0, z: -1.0 };
/Users/voightkampff/.ailang/cache/registry/sunholo/relativity/0.2.0/_smoke.ail:19:  let seen = aberrate({ x: 1.0, y: 0.0, z: 0.0 }, fwd, atanh(0.9));
/Users/voightkampff/.ailang/cache/registry/sunholo/relativity/0.2.0/_smoke.ail:20:  let angle = acos(dot(seen, fwd)) * 180.0 / pi();
```

### E7

```sh
sed -n '430,461p' /Users/voightkampff/dev/sunholo-data/ailang/changelogs/v0.32-current.md; make strict AILANG=$PWD/runtime/bin/ailang
```

Exit 0

```text
image's npm 10 (`node:22`) rejects it: "Missing: esbuild@0.28.2". They land together here, with
the lockfile generated by npm@10.9.9. `npm ci` passes under npm 10 and 11, `npm run build`
passes, all 147 vitest tests pass, and `ui/dist` is resynced with the Vite 8 bundle.
`vite.config.ts` needs no change because it uses plain `react()` with no Babel options.
### Fixed — bytecode VM read the wrong record field, and compiled differently on each run (ailang#1354, #1355)

When two record types shared a field name at different sorted positions (`Motion {phi,tau,t,x}`
and `Vec3 {x,y,z}`), the bytecode compiler could compile `v.x` with the other type's slot. The
lower pass never passed a named record's type (`v: V` reaches CoreTI as a bare `TCon`), so the
compiler fell back to scanning every registered record type for one containing `x`, in Go map
order. Each process sampled a new order. In-range wrong slots read the wrong field silently, even
under `--strict-bytecode`. Out-of-range ones errored under strict and silently fell back to the
evaluator otherwise. Record updates rebuilt the record with the other type's field list.
Measured on the Stapledon game (branch `m1.6-free-motion-iter1`): the one-line step input diverged
from the interpreter in 4/25 VM runs, and the off-axis fixture in 10/30. `make strict` failed
10/10. After the fix all of them match the interpreter in every run.

- The lower pass now attaches the receiver's declared type name (`FieldAccess.RecordType`,
  `RecordUpdate.RecordType`) and the base's inferred field set to record updates. Update fields
  are sorted.
- The compiler resolves a slot only from the receiver's own field set or its exact declared type,
  including alias chains (`type P = V`). There is no cross-type scan. An unknown type reads by
  name (`_record_get`). A record update on an unknown base uses a new `_record_set` builtin, which
  updates by name as the evaluator does. A record name declared twice with different fields is
  treated as unknown.
- `switch` ADT inference falls back through ADTs in declaration order, not map order.
- Tests: `tests/golden/bytecode/shared_field_names.ail` under `--strict-bytecode` must match the
  interpreter, and its disassembly must be byte-identical, on each of 8 runs. The base binary
  fails it 5/5. `determinism_test.go` compiles a shared-field program 200 times in-process. With
  the old scan reinstated, that test fails.

### Fixed — dashboard UI build: pin eslint back to 9 (red since 2026-07-14)
strict VM 21.392852753780428 | interpreter 21.392852753780428 | closed form 21.392852753780602
strict off-axis VM 27.637939595105987 | interpreter 27.637939595105987 | closed form 27.637939595106303
```

### E8

```sh
AILANG_RELAX_MODULES=1 runtime/bin/ailang check .ailang/state/freshness/claim.ail; AILANG_RELAX_MODULES=1 runtime/bin/ailang run --quiet --strict-bytecode --entry main .ailang/state/freshness/claim.ail
```

Exit 0

```text
→ Type checking .ailang/state/freshness/claim.ail...
→ Effect checking...
WARNING MOD010 (relaxed): module 'claim' does not match canonical path '.ailang/state/freshness/claim'
  Running under --relax-modules; mismatch ignored. For strict checking, omit --relax-modules flag.

✓ No errors found!
[0, 0, 128, 63, 0]
```

### E9

```sh
rg -n 'export.*func|stream|line' /Users/voightkampff/dev/sunholo-data/ailang/std/fs.ail /Users/voightkampff/dev/sunholo-data/ailang/std/bytes.ail
```

Exit 0

```text
/Users/voightkampff/dev/sunholo-data/ailang/std/bytes.ail:16:export pure func fromString(s: string) -> bytes {
/Users/voightkampff/dev/sunholo-data/ailang/std/bytes.ail:22:export pure func toString(b: bytes) -> string {
/Users/voightkampff/dev/sunholo-data/ailang/std/bytes.ail:28:export pure func toBase64(b: bytes) -> string {
/Users/voightkampff/dev/sunholo-data/ailang/std/bytes.ail:35:export pure func fromBase64(s: string) -> Option[bytes] {
/Users/voightkampff/dev/sunholo-data/ailang/std/bytes.ail:43:export pure func fromBase64URL(s: string) -> Option[bytes] {
/Users/voightkampff/dev/sunholo-data/ailang/std/bytes.ail:55:export pure func toBase64URL(b: bytes) -> string {
/Users/voightkampff/dev/sunholo-data/ailang/std/bytes.ail:63:export pure func length(b: bytes) -> int {
/Users/voightkampff/dev/sunholo-data/ailang/std/bytes.ail:71:export pure func slice(b: bytes, start: int, len: int) -> Option[bytes] {
/Users/voightkampff/dev/sunholo-data/ailang/std/bytes.ail:77:export pure func concat(a: bytes, b: bytes) -> bytes {
/Users/voightkampff/dev/sunholo-data/ailang/std/bytes.ail:84:export pure func concatList(xs: [bytes]) -> bytes {
/Users/voightkampff/dev/sunholo-data/ailang/std/bytes.ail:91:export pure func fromInts(xs: [int]) -> bytes {
/Users/voightkampff/dev/sunholo-data/ailang/std/bytes.ail:100:export pure func byteAt(b: bytes, i: int) -> Option[int] {
/Users/voightkampff/dev/sunholo-data/ailang/std/bytes.ail:111:export pure func toInts(b: bytes) -> [int] {
/Users/voightkampff/dev/sunholo-data/ailang/std/fs.ail:19:export func readFile(path: string) -> string ! {FS} = _fs_readFile(path)
/Users/voightkampff/dev/sunholo-data/ailang/std/fs.ail:26:export func readFileBytes(path: string) -> Result[string, string] ! {FS} = _fs_readFileBytes(path)
/Users/voightkampff/dev/sunholo-data/ailang/std/fs.ail:34:export func writeFile(path: string, content: string) -> () ! {FS} = _fs_writeFile(path, content)
/Users/voightkampff/dev/sunholo-data/ailang/std/fs.ail:42:export func writeFileBytes(path: string, data: bytes) -> () ! {FS} = _fs_writeFileBytes(path, data)
/Users/voightkampff/dev/sunholo-data/ailang/std/fs.ail:50:export func appendFile(path: string, content: string) -> () ! {FS} = _fs_appendFile(path, content)
/Users/voightkampff/dev/sunholo-data/ailang/std/fs.ail:54:-- O(1) per call — ideal for streaming binary data to disk (e.g., PCM audio frames)
/Users/voightkampff/dev/sunholo-data/ailang/std/fs.ail:58:export func appendFileBytes(path: string, data: bytes) -> () ! {FS} = _fs_appendFileBytes(path, data)
/Users/voightkampff/dev/sunholo-data/ailang/std/fs.ail:64:export func fileExists(path: string) -> bool ! {FS} = _fs_exists(path)
/Users/voightkampff/dev/sunholo-data/ailang/std/fs.ail:70:export func listDir(path: string) -> [string] ! {FS} = _fs_listDir(path)
/Users/voightkampff/dev/sunholo-data/ailang/std/fs.ail:76:export func mkdir(path: string) -> () ! {FS} = _fs_mkdir(path)
/Users/voightkampff/dev/sunholo-data/ailang/std/fs.ail:83:export func mkdirAll(path: string) -> () ! {FS} = _fs_mkdirAll(path)
/Users/voightkampff/dev/sunholo-data/ailang/std/fs.ail:89:export func isDir(path: string) -> bool ! {FS} = _fs_isDir(path)
/Users/voightkampff/dev/sunholo-data/ailang/std/fs.ail:95:export func isFile(path: string) -> bool ! {FS} = _fs_isFile(path)
/Users/voightkampff/dev/sunholo-data/ailang/std/fs.ail:101:export func removeFile(path: string) -> () ! {FS} = _fs_removeFile(path)
/Users/voightkampff/dev/sunholo-data/ailang/std/fs.ail:110:export func renameFile(oldPath: string, newPath: string) -> () ! {FS} = _fs_rename(oldPath, newPath)
/Users/voightkampff/dev/sunholo-data/ailang/std/fs.ail:123:export func readFileResult(path: string) -> Result[string, string] ! {FS} = _fs_readFileResult(path)
/Users/voightkampff/dev/sunholo-data/ailang/std/fs.ail:129:export func writeFileResult(path: string, content: string) -> Result[(), string] ! {FS} =
/Users/voightkampff/dev/sunholo-data/ailang/std/fs.ail:136:export func appendFileResult(path: string, content: string) -> Result[(), string] ! {FS} =
/Users/voightkampff/dev/sunholo-data/ailang/std/fs.ail:143:export func removeFileResult(path: string) -> Result[(), string] ! {FS} = _fs_removeFileResult(path)
/Users/voightkampff/dev/sunholo-data/ailang/std/fs.ail:149:export func mkdirAllResult(path: string) -> Result[(), string] ! {FS} = _fs_mkdirAllResult(path)
/Users/voightkampff/dev/sunholo-data/ailang/std/fs.ail:154:export func mkdirResult(path: string) -> Result[(), string] ! {FS} = _fs_mkdirResult(path)
/Users/voightkampff/dev/sunholo-data/ailang/std/fs.ail:158:export func removeDirResult(path: string) -> Result[(), string] ! {FS} = _fs_removeDirResult(path)
/Users/voightkampff/dev/sunholo-data/ailang/std/fs.ail:164:export func renameFileResult(oldPath: string, newPath: string) -> Result[(), string] ! {FS} =
/Users/voightkampff/dev/sunholo-data/ailang/std/fs.ail:172:-- 2026-09-16); walk/glob make "find every .ail under a tree" a one-liner.
/Users/voightkampff/dev/sunholo-data/ailang/std/fs.ail:182:export func walk(root: string) -> [string] ! {FS} = sortBy(compare, walkDir(root))
/Users/voightkampff/dev/sunholo-data/ailang/std/fs.ail:189:export func glob(root: string, suffix: string) -> [string] ! {FS} = filter(\p. endsWith(p, suffix), walk(root))
```

### E10

```sh
rg -n 'float32|Float32|f32' /Users/voightkampff/dev/sunholo-data/ailang/std/bytes.ail; test $? -eq 1 && echo 'float32 API search empty; positive control follows'; rg -n 'fromInts|concatList' /Users/voightkampff/dev/sunholo-data/ailang/std/bytes.ail
```

Exit 0

```text
float32 API search empty; positive control follows
83:-- Example: concatList([header, body, footer])
84:export pure func concatList(xs: [bytes]) -> bytes {
90:-- Example: fromInts([0x52, 0x49, 0x46, 0x46]) returns bytes for "RIFF"
91:export pure func fromInts(xs: [int]) -> bytes {
96:-- Inverse of fromInts. For UTF-8 strings, returns the raw byte at that
105:-- Exact inverse of fromInts: toInts(fromInts(xs)) == xs.
```

### E11

```sh
rg -n 'CSV_COLUMNS|wd_prob|missing|format_csv' tools/extract.py; rg --files tools/fixtures; test -d data/raw || echo 'data/raw absent; positive control: tools/fixtures listed'; test -d sim/tools || echo 'sim/tools absent; positive control follows'; rg --files sim
```

Exit 0

```text
18:          a missing magnitude is never defaulted).
22:Rows whose parallax is missing, non-finite or <= 0 are skipped and counted;
23:missing right ascension or declination skips a row too.  Inputs and outputs
48:CSV_COLUMNS = ("id", "x", "y", "z", "G", "BPRP", "wd")
152:        wd_prob = _number(line[245:250])  # WDprob  bytes 246-250
161:            1 if (wd_prob is not None and wd_prob > 0.5) else 0,
177:def format_csv(rows):
179:    lines = [",".join(CSV_COLUMNS)]
194:    return format_csv(rows), len(rows), skipped
205:        print("ERROR: missing %s - run "
tools/fixtures/cns5_null_plx.dat
tools/fixtures/cns5_bp_blank_rp_set.dat
tools/fixtures/cns5_alpha_cen.dat
tools/fixtures/gcns_head.dat
tools/fixtures/gcns_wdprob_050.dat
tools/fixtures/cns5_head.dat
tools/fixtures/gcns_wdprob_0506.dat
tools/fixtures/gcns_wd_1p000.dat
tools/fixtures/gcns_wd.dat
tools/fixtures/gcns_missing_phot.dat
sim/tools absent; positive control follows
sim/ailang.toml
sim/core_test.ail
sim/protocol_test.ail
sim/ship.ail
sim/ailang.lock
sim/core.ail
```

### E12

```sh
sed -n '27,43p' /Users/voightkampff/.ailang/cache/registry/sunholo/relativity/0.2.0/blackbody.ail
```

Exit 0

```text
export pure func cmf(l: float) -> XYZ = {
  x: 1.056 * lobe(l, 599.8, 37.9, 31.0) + 0.362 * lobe(l, 442.0, 16.0, 26.7) - 0.065 * lobe(l, 501.1, 20.4, 26.2),
  y: 0.821 * lobe(l, 568.8, 46.9, 40.5) + 0.286 * lobe(l, 530.9, 16.3, 31.1),
  z: 1.217 * lobe(l, 437.0, 11.8, 36.0) + 0.681 * lobe(l, 459.0, 26.0, 13.8)
}

-- Spectral radiance up to a constant; wavelength enters in micrometres so
-- cool sources stay far from float underflow.
export pure func planck(lNm: float, kelvin: float) -> float
  requires { lNm > 0.0 && kelvin > 0.0 }
  ensures { result >= 0.0 }
{
  let e = c2() / (lNm * kelvin);
  if e > 700.0 then 0.0 else pow(lNm / 1000.0, -5.0) / (exp(e) - 1.0)
}

func integrate(kelvin: float, l: float, acc: XYZ) -> XYZ {
```

### E13

```sh
rg -n '^## ' /Users/voightkampff/dev/sunholo-data/stapledons-design/vision/core-pillars.md
```

Exit 0

```text
5:## 1. Choices Are Final
22:## 2. The Game Doesn't Judge
40:## 3. Time Has Emotional Weight
57:## 4. The Ship Is Home
75:## 5. Grounded Strangeness
93:## 6. We Are Not Built For This
```

### E14: arithmetic positive control

Command: `python3 -c "import struct; old=(127*2**23)-2**23; print(hex(old),struct.unpack('<f',struct.pack('<I',old))[0]); print(struct.pack('<f',1.0).hex())"`

```text
0x3f000000 0.5
0000803f
```
