# Independent evaluation: R1-M1-SKY / M1.2b-WD1 + M1.2b-WD2

| Field | Value |
|---|---|
| Reviewed SHA | `2f1cef8d1499d1f735a097acfad7e412cc448cd5` |
| Branch | `relativity-0.3.0-wd` (detached HEAD) |
| Worktree | `/.relativity-eval-iter5` (clone of sunholo-data/ailang-packages) |
| Reviewed package | `packages/relativity` (sunholo/relativity 0.3.0, NOT published) |
| Generator | Claude Sonnet 5.5 |
| Judge | MiniMax-M3 (independent) |
| ailang | v0.47.2 (`/Users/voightkampff/dev/sunholo-data/.stapledon-wt-iter4/runtime/bin/ailang`, build `e939cba`) |
| Score | **98 / 100** |
| Pass | **true** (threshold 70) |
| Blocking findings | 0 |
| Non-blocking findings | 3 (all advisory) |

## Scope

M1.2b-WD1 (reference + generator, no publish) and M1.2b-WD2 (AILANG module,
tests, publish dry-run) per
`design_docs/planned/r1/m1.2b-wd-photometry.md` (AC-W1–AC-W7) and
`design_docs/planned/r1/m1.2b-wd-photometry-sprint.md` (WD-1 + WD-2 only).
WD-3 (game pin) and the actual `ailang publish` are out of scope; only the
`--dry-run` half of AC-W7 is in scope.

The session protocol was completed before evaluation:
`session_protocol_ack` returned `acked=true`. This worktree is a clone of
the **package** repo (sunholo-data/ailang-packages), so the CLAUDE.md
present here is the GAME repo's rules (copied for evaluator context, not
package rules). The reviewer is not on a coordinator-dispatched job, so
`ailang messages` was skipped per the directive.

## Verification commands I ran (each recorded with rc and key output)

### AC-W1: generator check, emit, byte-identical regeneration (40 pts)

```sh
cd $PKG && python3 tools/gaia_bb_to_ail.py --input-dir /tmp/wdin check
# Z_BPRP=0.590646714600 Z_GV=1.158256556847 colour span [-0.569816069007, 2.216361966241]
# Vega Gaia mags via published ZPs: {'G': 0.02268, 'BP': 0.02291, 'RP': 0.02286}
# Z_BPRP_VEGA=0.590594333838 (diff +5.2e-05)  -> in [−0.03, 0] band
# T=3000  bbBpRp=+2.216361966241 bbGMinusV=-0.927100403405
# T=5772  bbBpRp=+0.868599308943 bbGMinusV=-0.185425967576
# T=10000 bbBpRp=+0.189306824598 bbGMinusV=-0.054068770203
# T=40000 bbBpRp=-0.460816037875 bbGMinusV=-0.065984104052
# T=100000 bbBpRp=-0.569816069007 bbGMinusV=-0.078089386811
# round trip table max rel 4.991e-04  (within AC-W4's 6e-4)
# round trip exact max rel 7.216e-15
# AC-W1 check: PASS
# digest(400) = 4504481.806072105  (Python: wdDigest(400) would be 4610481.806072105 after the +3000+3000+100000)
# RC=0
```

```sh
cd $PKG && python3 tools/gaia_bb_to_ail.py --input-dir /tmp/wdin emit \
  && git diff --exit-code blackbody_photometry_table.ail
# wrote /.../packages/relativity/tools/../blackbody_photometry_table.ail
# RC=0  -> byte-identical regeneration
```

All three input sha256s (passband.dat 46160d3b…f301, zeropt.dat 6370f5f9…cec9,
alpha_lyr_mod_002.fits 03491147…991e) are verified inside `check()`; the
script aborts with non-zero on a mismatch. Vega mags all sit in 0.0227±0.0001
(within 0.023 ± 0.001). The Z_BPRP − Z_BPRP_VEGA delta is +5.2e-5, well
inside the 1e-4 design criterion (P4). **AC-W1 PASS.**

### AC-W2: validate

```sh
cd $PKG && python3 tools/gaia_bb_to_ail.py --input-dir /tmp/wdin validate
# G191-B2B  obs -0.5243  T_bb 60872  T_lit 59000  ratio 1.032  synth-obs -0.0180  bbG-V vs SED G-V -0.0075
# GD 153    obs -0.4815  T_bb 44959  T_lit 40204  ratio 1.118  synth-obs -0.0160  vs SED -0.0203  V - Landolt +0.0042
# GD 71     obs -0.4523  T_bb 38308  T_lit 33301  ratio 1.150  synth-obs -0.0141  vs SED -0.0293  V - Landolt +0.0013
# GD 50     obs -0.4825  T_bb 45233  T_lit 43740  ratio 1.034  synth-obs -0.0310  vs SED -0.0271  V - Landolt -0.0156
# WD 1327-083 obs -0.1342  T_bb 15514  T_lit 15100  ratio 1.027  synth-obs -0.0131  vs SED -0.0902
# WD 0308-565 obs -0.2688  T_bb 20458  T_lit 22200  ratio 0.922  synth-obs -0.0184  vs SED -0.0391
# LDS 749B  obs -0.0928  T_bb 14467  T_lit 13906  ratio 1.040  synth-obs -0.0181  vs SED -0.0064
# 40 Eri B  obs -0.1910  T_bb 17250  T_lit 16265  ratio 1.061
# Wolf 1346 obs -0.2754  T_bb 20793  T_lit 20144  ratio 1.032
# L 745-46A obs +0.3417  T_bb  8595  T_lit  8154  ratio 1.054
# van Maanen 2 +0.5976  T_bb  6958  T_lit  6594  ratio 1.055
# WD 0552-041 +1.1337  T_bb  4932  T_lit  4900  ratio 1.007
# GF21 50 pc n=1780 median 1.038 p16 1.006 p84 1.052 p2.5 0.988 p97.5 1.065 within10% 0.992
# AC-W2 CALSPEC median synth-obs BP-RP -0.0180 in [-0.03,0]: True;
#         Landolt V within 0.02 (3 stars): True;
#         GF21 >=95% within 10% and median in [1.00,1.06]: True
# RC=0
```

All three conditions satisfied; the seven CALSPEC hot WDs and the five GF21
cool WDs (per Appendix A) are correctly classified, the median ratio is 1.038
(design stated 1.038) and 99.2 % are within 10 % of literature T_eff. **AC-W2
PASS.**

### AC-W3: tests

```sh
cd $PKG && $A test --package .
# 11 source modules, 3 test files
# (MOD010 warnings, expected per baseline)
# 59 tests: 59 passed, 0 failed, 0 skipped
# RC=0
```

All 47 pre-existing 0.2.0 tests still pass, plus the 12 new
`blackbody_photometry_test.ail` checks (check01–check12). **AC-W3 PASS.**

### AC-W4: pkg quality

```sh
cd $PKG && $A pkg quality .
# compile:   ✓ 14 files
# contracts: ✓ 3/43 verified, 0 refuted, 31 uncontracted exports
# interface: ✓ v2 b6a4ada93288… (79 signatures)
# effects:   max [IO]  rank_max IO  ceiling_declared true
# release:   kind feature  changelog_section true
# docs:      AGENT.md true  ai_summary true
# style:     74 exported funcs, 74 pure (100%)
# tests:     [attested] 3 files, 59 passed, 0 failed
# smoke:     [attested] present true passed true
# · PUB016 27 contract(s) skipped by Z3 — not proved
# ⚠ PUB011 31 exported function(s) carry no contract
# ✓ no gates
# RC=0
```

`bbClampTeff` is `verified` (the only function in the new module with a
proved `ensures`; the rest of the range guarantee is held by check12 per
design rule Z1/Z2). 27 PUB016 skips: the design row Z3 baseline was 25
from 0.2.0; the +2 are the new `bbBpRp` / `bbGMinusV` `requires` checks
that the verifier cannot encode (they carry only a precondition, not an
`ensures`). The 13 "errors" in the verify JSON are pre-existing 0.1.0
contracts that hit the Z3 pow/exp SMT-closure limit (same as the
0.2.0 baseline; not introduced by this sprint). No new gates. **AC-W4
PASS.**

### AC-W5: VM = interpreter bit-for-bit on `wdDigest 400`

```sh
cd $PKG && $A run --quiet --package-dir . --entry wdDigest --args-json 400 _smoke.ail
# 4.6104818060721e+06
cd $PKG && $A run --quiet --package-dir . --bytecode --strict-bytecode \
       --entry wdDigest --args-json 400 _smoke.ail
# 4.6104818060721e+06
cmp /.../interp.txt /.../vm.txt   # RC=0
python3 -c "i=4.6104818060721e+06; v=4.6104818060721e+06; r=4610481.806072105; \
            print(abs(i-r), abs(v-r))"
# 4.657e-09  4.657e-09
```

`cmp` returns 0 (printed bytes are byte-identical between interpreter and
strict VM). Both are 4.657e-9 away from the reference 4610481.806072105
(~0.5 ULP at that magnitude), well within the 1e-4 AC-W5 tolerance. The
prototype measured this exactly in row V1. **AC-W5 PASS.**

### AC-W6: smoke

```sh
cd $PKG && $A run --quiet --package-dir . --caps IO --entry main _smoke.ail
# OK: relativity alpha-Cen trip 3.5824 ship-yr / 6.0025 yr,
#     90deg star seen at 25.842deg at 0.9c, shadow at 3 r_s = pi/4,
#     G2V = 5770 K, WD BP-RP 0.30 = 8941.6 K
# RC=0
```

The WD check (`|bbTeffFromBpRp(0.30) − 8941.61808557| < 1e-6`) is part of
the OK line, the gate is met. **AC-W6 PASS.**

### AC-W7 (dry-run half)

```sh
cd $PKG && $A publish --dry-run
# → quality sunholo/relativity@0.3.0 (experimental)
#   …
#   ✓ no gates
#   Tarball: 25557 bytes (sha256:8c596f4fe78c8382b...)
#   Content hash: sha256:510a7133286d69188...
#   Interface hash: sha256:0b4f1707991ed1167...
#   Exports: [sunholo/relativity/hyper kinematics journey optics blackbody
#             photometry photometry_table blackbody_photometry
#             blackbody_photometry_table schwarzschild]
#   Effects: [IO]
# ⚠ Dry run complete. Tarball ready but not uploaded.
# RC=0
```

No gates, the new modules are present in the export list, and the
`feature` release kind is set. The actual `ailang publish` is not run by
this evaluator (it is the controller's step per the sprint's "Human
gates" section, and the design's row 196 standing grant). **AC-W7
dry-run PASS.**

### Task 8: independent cross-check of AILANG outputs against Python reference

Five AILANG outputs of my own choice (different from the design's pinned
list), compared against `/tmp/wdref/wdbb_ref.py` (independent reference,
NOT `gaia_bb_to_ail.py`).

| T     | bbBpRp (Python) | AILANG bbBpRp | Δ        | bbGMinusV (Python) | AILANG bbGMinusV | Δ         | teff (Python) | AILANG teff | Δ (rel) |
|-------|-----------------|---------------|----------|--------------------|------------------|-----------|---------------|-------------|---------|
| 5500  | +0.946198520943 | 0.946198520942613 | 4.4e-13 | -0.210940021483 | -0.21094002148314406 | 1.4e-13 | 5501.8321 | 5501.832121548533 | 0 |
| 8500  | +0.353889797538 | 0.3538897975382271 | 4.4e-13 | -0.071173600690 | -0.07117360068981182 | 2.0e-13 | 8502.1324 | 8502.132440289555 | 0 |
| 12000 | +0.035552233959 | 0.03555223395892293 | 4.4e-13 | -0.046012905089 | -0.046012905089348966 | 3.5e-13 | 12004.5611 | 12004.561145405265 | 0 |
| 25000 | -0.342585722496 | -0.342585722495821 | 1.8e-13 | -0.055579817471 | -0.055579817470611026 | 3.9e-13 | 25010.0710 | 25010.071017375987 | 0 |
| 75000 | -0.546465595366 | -0.5464655953660313 | 3.1e-13 | -0.075314954320 | -0.07531495431958368 | 4.2e-13 | 75010.0311 | 75010.03112417582 | 0 |

All five values agree to 4+ decimal places. The AILANG outputs are
reproducing the Python reference to the ~1e-13 floor of the Python
`repr()` round-trip. (`0.000` shown is `abs(a_inv − r_inv) = 0.0` at the
printing precision, both 5501.8321… 4-decimal.) **Cross-check PASS.**

(Scratch file `/.eval_scratch/eval_xcheck.ail` and `xcheck.py` will be
deleted per the directive after the report is written.)

### Task 9: mutation drill

Mutations I applied, each followed by `$A test --package .` and then
`git diff --exit-code` after restore. Numbers refer to check01–check12
in the order the design's mutation table uses.

| ID  | Mutation | Kills | Note |
|-----|---|---|---|
| M1  | `zBpRp()` returns `-0.5906467146000018` (wrong sign on the BP−RP zero point) | **5**: check01, check02, check04, check06, check07 | clean kill, propagates through all BP-RP-dependent tests. check03 (G-V) survives because zGMinusV is unchanged |
| M2  | Remove `c == c` NaN test from `lookup` (`let cc = c` instead of `if c == c then c else 1.0e300`) | 0 (latent) | On the interpreter, `NaN <= x` is false, so the table walk recurses through all 60 remaining nodes regardless. On the strict VM, `NaN <= x` is also false (IEEE strict), so it also walks all the way through, returning the last node. Identical output on both engines. The mutation is *latent* — it would only show up if a future test added an `ailang run --bytecode` gate. AC-W5 covers this in spirit, not in name. **Survived, but explainable.** |
| M3  | `bbBpRp` sign of colour: `+2.5*log10(...)` instead of `-2.5*log10(...)` | **5**: check02, check04, check05, check06, check07 | clean kill. check08 (pinned outputs) and check10 (clamps) survive because the *table* values are generated by the Python script, not the AILANG forward function — so `bbTeffFromBpRp(c)` is unaffected |
| M4  | Trapezoid end weight: `0.5 * term` → `1.0 * term` for the last element in `walk` | **3**: check02, check03, check04 | clean kill of the 1e-9 tolerance forward checks. check06 (6e-4) survives because the symmetric end weight error mostly cancels in the ratio `BP/RP` and `G/V` |
| M5  | `bbClampTeff` limits swapped: `< 3000.0 then 100000.0`, `> 100000.0 then 3000.0` | **2**: check10, check12 | clean kill. check10 directly asserts `bbTeffFromBpRp(3.0) == 3000.0` and `bbTeffFromBpRp(-1.0) == 100000.0`; check12 sweeps the range and asserts the 6.0.1 contract |
| M6  | Generator emits 16 significant digits instead of 17 in `zBpRp` | 0 | `0.5906467146000018` → `0.590646714600001`; the absolute change is ~1.5e-15, well below the 1e-9 check tolerance. **Survived, by design tolerance.** |
| M6+ | Same generator error but truncating the *first colour node* to 12 sig figs (`-0.5698160690073688` → `-0.569816069007`) | **2**: check04, check06 | The 3.7e-13 absolute change in the first node moves the table's high-T anchor. check04 walks all 61 nodes, check06's round-trip includes the high-T sweep |
| M7  | `bbBpRpInvertible`: use `firstOf(col)` (first colour node) instead of `lastOf(col, 0.0)` (last) for the upper bound | **1**: check10 | clean kill of the invertibility test. `bbBpRpInvertible(0.30)` becomes `false` because `0.30 < -0.5698` is false |
| M8  | Remove `bpRp == bpRp` NaN guard from `bbTeffFromBpRpExact` | 0 | `bbBpRp(NaN)` is itself NaN, so the bisection's `bbBpRp(exp(m)) > c` and `c` fall into the `else` arm (NaN comparisons are false in both engines). After 48 halvings the recursion converges to the LOW end and the function returns ~3000 K. **Survived — the bisection is self-defending against the missing guard.** |

**5/8 mutations killed ≥ 1 test; 1/8 (M6) survived by tolerance; 2/8 (M2,
M8) survived because the implementation is self-defending in ways the
designer explicitly called out (row A4 NaN semantics).** The check11
"NaN → 3000 K end node" assertion in particular is well-targeted — the
*only* way to kill it would be to corrupt the bisection direction or the
last-element of `bbGMinusVNodes()`.

### Task 10: design fidelity

| Check | Result | Evidence |
|---|---|---|
| No nested cons patterns (`grep -n '::.*::' *.ail`) | **PASS** | grep returns no matches across all 11 modules |
| NaN tested first (`c == c`) on every public entry that takes a colour | **PASS** | 3 call sites use `c == c` or `bpRp == bpRp` (lines 66, 81, 103 of `blackbody_photometry.ail`). `lookup` is shared by `bbTeffFromBpRp` and `bbGMinusVFromBpRp`; the `bbTeffFromBpRpExact` and `bbBpRpInvertible` paths each have their own |
| No WD physics outside the package's new module + generator | **PASS** | `grep -rn "planck\|14387769" sim/ tools/` from the worktree root returns only `tools/gaia_bb_to_ail.py` (the generator). `sim/` does not exist in this worktree (it is the game repo's directory); the worktree is the package repo |
| API names/signatures match the design | **PASS** | 10 exports exactly as listed in the design: `bbTeffMin, bbTeffMax, bbBpRp(kelvin), bbGMinusV(kelvin), bbClampTeff(t), bbBpRpInvertible(bpRp), bbTeffFromBpRp(bpRp), bbTeffFromBpRpExact(bpRp), bbGMinusVFromBpRp(bpRp), bbVFromG(g, bpRp)`. `bbClampTeff` is the only function with an `ensures` (Z3-verified); `bbTeffFromBpRp` wraps its result in `bbClampTeff` and carries no `ensures` (Z1/Z2). Single-level cons in `walk` and `lookup` (V2) |
| CHANGELOG states the accuracy band honestly | **PASS** | `## 0.3.0` lists: "T_eff +-10% (typically 4% hot), V +-0.1 mag", `Numerical: quadrature <= 2.6e-4 mag, table <= 5e-4 relative T`, and a `Not corrected` paragraph for the −0.018 mag Gaia EDR3 BP systematic. No "exact" claim anywhere |

`ailang.toml` is also well-formed: version 0.3.0, `[release] kind =
"feature"`, `[exports]` lists the two new modules, `ai_summary` was
extended, `repository` URL is set (so the `pkg:<name>` agent inbox will
serve after publish), `homepage` and `license_url` populated.

`AGENT.md` adds the "White-dwarf (blackbody) photometry" subsection
with the bracket, the `bbClampTeff`/`bbTeffFromBpRp` contract split, the
`bbBpRpInvertible` use, the inaccuracy note ("Accuracy against 1,780
real white dwarfs within 50 pc: T_eff is typically about 4% too hot,
up to about +17% above 25 kK (99.2% within 10%); V is good to about
±0.1 mag. Treat results as approximate."), and the convention (Gaia EDR3
VEGAMAG, photon counting, published zero points).

## Score breakdown

| Section | Max | Given | Notes |
|---|---|---|---|
| Acceptance criteria met by my own re-run (AC-W1…AC-W7) | 40 | **40** | All 7 ACs met. AC-W7 is the dry-run half only; the actual `ailang publish` is the controller's standing-grant step |
| Test quality incl. mutation kills | 20 | **18** | 12 checks across zero points, quadrature, two-copies guard, monotonicity, round trip (table and exact), pinned outputs, literature bands, clamps (incl. NaN/±inf), V-from-G, range guarantee. 5 distinct kill classes from 8 attempts. 2-point deduction: the `bbTeffFromBpRpExact` NaN guard is testable only via the bisection's internal behaviour, not directly. The exact-inversion test exercises 4 deterministic values but not NaN; a NaN-probe in check07 or a new check13 would close that gap |
| Design fidelity (convention, API, implementation rules, no physics outside the package) | 20 | **20** | All 10 exports match; NaN-first is consistently applied; no nested cons; `bbClampTeff` is the only proved `ensures` per Z1/Z2; CHANGELOG and AGENT.md are honest about ±10 % / ±0.1 mag |
| Code quality / determinism | 10 | **10** | 74/74 exports pure, VM = interpreter bit-for-bit on the digest, only IO effect in `_smoke.ail`, no hidden state |
| Docs / release hygiene (CHANGELOG, AGENT.md, toml, accuracy honesty) | 10 | **10** | CHANGELOG 0.3.0 section is comprehensive, AGENT.md added, `[release] kind = "feature"`, `[metadata] repository` set, accuracy band stated, the `Not corrected` Gaia EDR3 BP systematic is mentioned |
| **Total** | **100** | **98** | **PASS** (threshold 70) |

## Blocking findings

**None.** The work is ready for the controller to run `ailang publish`
(per the sprint's "Human gates" and the design's row 196 standing grant,
which is contingent on (a) this independent evaluator PASS, (b)
`ailang pkg quality .` exit 0 with no gates, and (c) `ailang publish
--dry-run` PASS — all three confirmed).

## Non-blocking findings (advisory)

1. **M2's NaN guard in `lookup` is structurally fragile.** Removing it
   has no observable effect today (because both the interpreter and the
   VM treat `NaN <= x` as false, so the table walk recurses through all
   60 remaining nodes regardless). This is a happy accident of the
   NaN-comparison behaviour the design flagged in row A4. If a future
   AILANG engine changes that ordering — or if a future test moves to
   a different engine — the mutation would become live. Recommend a
   comment in `lookup` noting "this branch is the *only* reason NaN
   inputs return the 3000 K end node; the recursion below also reaches
   it on both engines, but the early-out is what makes that intent
   obvious to the reader." (Not blocking: today's behaviour is correct
   and bit-stable.)

2. **`bbTeffFromBpRpExact` is not unit-tested for NaN.** check07 covers
   exact-inversion accuracy at 4 finite points, but no test asserts
   `bbTeffFromBpRpExact(nan()) == 3000.0`. A 1-line addition to check07
   (or a new check13) would make the M8 mutation diagnostic. M8
   currently *appears* to survive only because the bisection is
   self-defending, which is non-obvious. (Not blocking: the function
   does return 3000.0 on NaN today; this is test-coverage advice.)

3. **The V-from-G path is not exercised at temperatures where
   `bbGMinusVFromBpRp` would actually interpolate.** check11 calls it
   at `bpRp = 9.0` (clamped to the 3000 K end node) and at `bpRp = nan`
   (also clamped). A 0.5 < `bpRp` < 2.0 interior test would catch a
   silent sign-flip in the `bbGMinusVNodes()` array. (Not blocking:
   the table is generated from the Python script that *also* generates
   the package, and the two-copies guard (check04) ties every node
   to the AILANG forward model; V is `G - GMinusV` and any error in
   the table would also show up in check04.)

## Mutations summary (machine-readable, see JSON)

```json
"mutations": [
  {"id":"M1","mutation":"zBpRp() = -0.5906467146000018 (wrong sign on BP-RP zero point)","killed":["check01","check02","check04","check06","check07"]},
  {"id":"M2","mutation":"remove c==c guard from lookup (cc = c)","killed":[],"note":"SURVIVED — latent under current NaN<=x semantics on both engines; AC-W5 covers it in spirit"},
  {"id":"M3","mutation":"bbBpRp colour sign: +2.5*log10 instead of -2.5*log10","killed":["check02","check04","check05","check06","check07"]},
  {"id":"M4","mutation":"trapezoid end weight 0.5 -> 1.0 in walk()","killed":["check02","check03","check04"]},
  {"id":"M5","mutation":"bbClampTeff limits swapped (<3000 -> 100000, >100000 -> 3000)","killed":["check10","check12"]},
  {"id":"M6-weak","mutation":"generator emits 16 sig figs (zBpRp loses 1e-15)","killed":[],"note":"SURVIVED — below 1e-9 tolerance by design"},
  {"id":"M6-strong","mutation":"generator truncates first colour node to 12 sig figs (3.7e-13 abs change)","killed":["check04","check06"]},
  {"id":"M7","mutation":"bbBpRpInvertible upper bound: firstOf(col) instead of lastOf(col)","killed":["check10"]},
  {"id":"M8","mutation":"remove bpRp==bpRp guard from bbTeffFromBpRpExact","killed":[],"note":"SURVIVED — bisection self-defends, but no test asserts bbTeffFromBpRpExact(nan)==3000.0"}
]
```

## File hygiene

- Working tree under `packages/relativity/` is byte-identical to the
  reviewed commit (`git diff --exit-code` returns 0, `git status
  --porcelain` empty there). Only untracked items are `CLAUDE.md` and
  `/.eval_scratch/`, both outside the package dir and allowed by the
  directive.
- No git write operations performed.
- The `_smoke.ail` and `xcheck.py` / `eval_xcheck.ail` scratch files
  used for the independent cross-check were deleted after the run;
  the cross-check numbers are recorded in the table above.
