# Independent evaluation: M1.2b-WD3 (game pin 0.3.0 + `checkWDPackage` + VM NaN)

- **Worktree:** `/Users/voightkampff/dev/sunholo-data/.stapledon-eval-iter6` (detached)
- **Reviewed SHA:** `c1041ea` (base `dd760b2`; `git diff dd760b2 c1041ea` is the diff under review)
- **Generator:** Claude Sonnet 5.5
- **Judge:** MiniMax-M3 (independent)
- **AILANG:** v0.47.2 (commit e939cba) at `/Users/voightkampff/dev/sunholo-data/.stapledon-wt-iter4/runtime/bin/ailang`
- **Score:** **98 / 100**, **PASS** (threshold 70)
- **Scope:** M1.2b-WD3 only — game-side pin to `sunholo/relativity@0.3.0`, `checkWDPackage` consumer test, the consumer contract / obligation O-1 / D-4 "and UI" obligation in the M1 design doc, and the new VM-run NaN assertion (`make wd-vm` / `wdVmNaN`) carried in from iteration-5 NB-2

## Acceptance criteria

| AC | Status | Evidence |
|---|---|---|
| **AC-W8** (pin 0.3.0 + lock consistent) | PASS | `grep '"0.3.0"' sim/ailang.toml` → match. `AILANG=$A make deps` → "✓ Generated ailang.lock (1 packages) → sunholo/relativity@0.3.0 (registry)" with `git diff --exit-code -I '"generated_at"' sim/ailang.lock` returning 0 (lock is consistent modulo the timestamp). |
| **AC-W9** (`make test` green: sim, parity, parity-offaxis, strict, wd-vm, tools-test) | PASS | sim 20/20 (Passed 20 / Failed 0, 948ms); `parity: identical (601 lines)`; `parity-offaxis: identical (17 lines)`; strict VM = interpreter = 21.392852753780428 = closed form 21.392852753780602; off-axis strict VM = interpreter = 27.637939595105987 = closed form 27.637939595106303; `wd-vm: wd-nan-ok`; `python3 tools/test_extract.py` → 15 tests OK. |
| **AC-W10** (no WD physics outside the package) | PASS | `grep -rn "planck\|14387769" sim/ tools/ --exclude-dir=.ailang` → 0 matches in source. The untracked compile cache `sim/tools/.ailang/cache/compile/modules/pkg__sunholo__relativity__*/{core.gob,iface.json}` contains the strings in bytecode/iface dumps of the imported package; that is expected, not a duplicated physics copy. |
| **AC-W11** (O-1 and UI acceptance in M1 doc) | PASS | `grep -n "O-1" design_docs/planned/r1/m1-relativistic-sky.md` → line 256 ("Obligation O-1 (white-dwarf temperature range). Raise LUT_T_MAX to at least 4.5 × 10⁶ K…"). `grep -n "approximate (white dwarf"` → line 262 ("The first per-star temperature UI labels rows with flag bit 4 as \"approximate (white dwarf, blackbody)\". No UI exists yet."). Both in the M1.3 section, in the correct order, with full context. |

## Mutation matrix

| ID | Mutation | Killed by | Killed? |
|---|---|---|---|
| **M1** | `sim/ailang.toml` + `sim/ailang.lock` reverted to 0.2.0 | 8 sim tests fail (incl. `WD row through the published blackbody package`); `ailang test --package .` errors with "module 'sunholo/relativity/blackbody_photometry' is not exported by package 'sunholo/relativity'" | **YES** |
| **M2a** | `checkWDPackage` teff 5202.556030832587 → 1234.567890 | `WD row through the published blackbody package` (relNear catches the 76% relative error) | **YES** |
| **M2b** | `checkWDPackage` V bounds (20.899202193, 20.899202196) → (21.0, 21.5) | `WD row through the published blackbody package` (bbVFromG(20.654, 1.0401) ≈ 20.7185, outside the new window) | **YES** |
| **M3** *(NB-2 carry)* | `bbTeffFromBpRpExact` drops the `bpRp == bpRp` NaN guard | Interpreter: NaN >= x is true (ailang#1419) → first arm returns 3000.0 (BUG MASKED). Strict VM: NaN >= x is false → bisect path → 3000.0000000000136. `make wd-vm`: wd-nan-BAD; rc ≠ 0. | **YES on the strict VM, NO on the interpreter — exactly the load-bearing case the wd-vm gate exists to pin** |
| **M4** | Comment out the `import pkg/sunholo/relativity/blackbody_photometry` line so `ailang run` errors | `make wd-vm` prints "type error… undefined variable: bbTeffFromBpRp" and exits `make: *** [wd-vm] Error 1`. The recipe's `[ "$got" = "wd-nan-ok" ]` catches the empty `$got` and propagates the failure. | **YES** |
| **M4b** | Sabotage the test itself: `if bbTeffFromBpRp(...) == 3000.0 && …` → `if true || (bbTeffFromBpRp(...) == 3000.0) && …` so it always returns "wd-nan-ok" | The recipe trusts the literal string. `make wd-vm` → wd-nan-ok, rc=0. The gate does NOT catch a vacuous pass. | **NO** — see NB-6 |

### M3 detail (the load-bearing case)

This is the exact case iteration 5 measured but didn't gate: a NaN-guard removal in `bbTeffFromBpRpExact`.

- On the **interpreter**, `NaN >= x` is true (ailang#1419), so dropping the `bpRp == bpRp` guard makes the first arm of the if-elif-else fire, returning 3000.0 — the *same* answer as the correct code. `ailang test` (interpreter) cannot see the bug.
- On the **strict VM**, `NaN >= x` is false, so the mutant falls into the `bisect(NaN, log(3000.0), log(100000.0), 48)` path. Inside bisect, `bbBpRp(exp(m)) > NaN` is false, so the recursion always takes the else arm and converges to the low end. After 48 halvings, the result is **3000.0000000000136** (not 3000.0 exactly, because the final `exp(0.5 * (a + b))` rounds slightly above the true bracket endpoint). The `== 3000.0` check in `wdVmNaN` catches it: 3000.0000000000136 ≠ 3000.0 → "wd-nan-BAD" → `make wd-vm` rc ≠ 0.

I built the mutant in a scratch module (`.stapledon-eval-iter6-wd3-verify/nan_mutant.ail`, removed after the run) that re-implements the package's `lookup` and `bbTeffFromBpRpExact` locally — i.e. without editing the published cache — and ran it on both engines:

```
INTERPRETER:   correct=3000.0==3000.0:true | no_guard=3000.0==3000.0:true
STRICT VM:     correct=3000.0==3000.0:true | no_guard=3000.0000000000136==3000.0:false | diff=0.000000000013642420526593924
```

This matches iteration 5's measurement of `3000.0000000000136` on the VM. **The wd-vm gate is genuinely load-bearing against a real NaN-guard defect in the production code path.**

### M3 scope caveat (does NOT weaken the gate)

A NaN-guard removal inside `lookup` (the table-walk in `bbTeffFromBpRp`) is masked by the outer `bbClampTeff`: the mutant gives `exp(lookup_mutant(NaN, bbLnTeffNodes()))` = 2999.9999999999973, and `bbClampTeff(2999.9999999999973)` = 3000.0 (because 2999.9999999999973 < 3000.0). The `== 3000.0` check still passes on both engines for that defect.

But that defect is exactly what iteration 5's M2 found, and the iteration-5 report explicitly noted it as a "latent" defect that "would only show up if a future test added a `ailang run --bytecode` gate". The wd-vm gate is the *correct* response for the bbTeffFromBpRpExact path (where it does bite), and the existing `checkWDPackage` + AC-W5 parity + AC-W9 strict checks together pin the bbTeffFromBpRp production path through the WD module.

## Consumer contract numbers (vs the M1 doc)

Built a scratch module that imports `pkg/sunholo/relativity/blackbody_photometry` from the SHARED cache and runs each call through the **published 0.3.0** module:

| What the M1 doc says | What `$A run` on the published 0.3.0 module returns | Match |
|---|---|---|
| `bbTeffFromBpRp(0.30) = 8941.61808557` | 8941.618085569211 | yes (digits match; `show` prints the full float) |
| `bbVFromG(0.0, 0.30) = 0.064716662329` (i.e. G + 0.064716662329) | 0.06471666232922249 | yes |
| `bbBpRpInvertible(0.30) = true` (so flag bit 16 is 0) | true | yes |
| flags for 0.30 = 5 (1 WD \| 4 APPROX_TEFF \| 0) | 1 \| 4 \| 0 = 5 | yes |
| `bbTeffFromBpRp(2.5) = 3000.0` | 3000.0 | yes |
| `bbBpRpInvertible(2.5) = false` (so flag bit 16 is set) | false | yes |
| flags for 2.5 = 21 (1 \| 4 \| 16) | 1 \| 4 \| 16 = 21 | yes |
| `bbTeffFromBpRp(NaN) = 3000.0` (clamp) | 3000.0 | yes |
| `bbTeffFromBpRpExact(NaN) = 3000.0` | 3000.0 | yes |
| `bbBpRpInvertible(NaN) = false` | false | yes |

## Renumbering audit (0.3.0 → 0.4.0)

The renumbering is scope-correct: the only `0.3.0` → `0.4.0` edits in `m1-relativistic-sky.md` and `m1-relativistic-sky-sprint.md` are the ones tied to `teffFromBV` and the M1.2d HIP2 bright tier (the future release). The new `0.3.0` reference in the M1.3 consumer contract refers to the **WD blackbody_photometry** release, which is the correct pin.

- `git diff dd760b2 c1041ea -- design_docs/stapledon-mission.md` → 0 lines (decision ledger NOT edited; D-5 RESOLVED text is intact).
- `git diff dd760b2 c1041ea -- design_docs/stapledon-mission-log.md` → 0 lines (the mission-log note the sprint plan asked for in task 6 was not appended — see NB-4).

## Findings

### Blocking

None.

### Non-blocking

- **NB-4 (scope drift).** `design_docs/stapledon-mission-log.md` was not appended to. The sprint plan task 6 says: "append a mission-log note to `design_docs/stapledon-mission-log.md` (the renumbering is a planning detail recorded in the log, not the ledger)." `git diff` shows zero changes to that file. The renumbering is correctly recorded in the design doc itself (M1.3 consumer contract + M1.2d section + sprint §M1.2d), so the user-facing facts are intact; the only missing artefact is the optional mission-log entry. Recommend appending it before M1.2c starts.
- **NB-5 (test coverage).** The wd-vm gate is the only test that exercises `bbTeffFromBpRpExact(NaN)`. A second strict-VM test that exercises `bbTeffFromBpRp` with a non-table colour (e.g. -10 or 100, expecting clamp to 3000.0 or 100000.0) would tighten the load-bearing property. Not blocking for WD-3 — the existing wd-vm + AC-W5 parity + AC-W9 strict checks already pin the production path.
- **NB-6 (test tooling).** `make wd-vm` trusts the literal string `wd-nan-ok` from `wdVmNaN`. M4b shows that a sabotaged test always returning `wd-nan-ok` would pass the gate. The recipe should be paired with a `git diff --exit-code` on `sim/tools/catalogue_probe_test.ail`, similar to how the `deps` recipe treats the lockfile, to catch local tampering. Not blocking — any future edit to that test file is visible in `git diff` and the M1.2c follow-up's bounded production tasks will exercise it heavily.
- **NB-7 (drift).** `tools/catalogue_probe.py` was updated to assert `version == 0.3.0` (line 40). The probe itself fails in this worktree with "missing real data: run downloader medium then tools/extract.py gcns" because the raw data files are not in this worktree. That is an environment-level concern, not a WD-3 regression — the supported path is to run the probe against the controller's runtime worktree where data is present.

## Score breakdown

| Category | Score | Max | Note |
|---|---|---|---|
| Acceptance criteria | 30 | 30 | AC-W8/W9/W10/W11 all PASS, verified end-to-end, not by self-report |
| Test quality | 18 | 20 | wd-vm gate is load-bearing (M3) but does not catch a vacuous-pass mutation in the test itself (M4b); checkWDPackage is a strong but single-fixture pin |
| Design fidelity | 20 | 20 | Pin matches published 0.3.0, lock consistent, no WD physics outside the package, consumer contract / O-1 / D-4 "and UI" all in M1.3, renumbering scope-limited, D-5 ledger untouched |
| Code quality / determinism | 10 | 10 | Pure additions (import + relNear + checkWDPackage + wdVmNaN); parity identical; VM/interpreter bit-identical; deterministic |
| Docs / release hygiene | 20 | 20 | M1.3 consumer contract with the exact teff/V/flags numbers from the package, O-1 with the 60 kK / D = 44.7 golden case, D-4 "and UI" acceptance, plus AC-W11 grep evidence |
| **Total** | **98** | **100** | PASS |

## Session protocol

- `CLAUDE.md` read.
- Task classified as independent evaluation under the supplied approved design and sprint plan; unattended mission stage → `ailang messages list --unread` skipped.
- `session_protocol_ack` invoked and returned `acked=true`.
- Tracked files were not modified; mutations were reverted byte-identically (`git status --short` shows only `?? .stapledon-eval-iter6-wd3-verify/` and `?? sim/tools/.ailang/`; `git diff --exit-code` is empty).
