# Evaluation: R1-M1-SKY / M1.2b-T1_TRANSFORM, iteration 7, round 1

- **Verdict: PASS, 88/100** (threshold 70), no hard fails, no blockers.
- Reviewed SHA: `e5908ce7fa7041db407f1e36af44316fc8806936` against base `d26cacfca50c69ca0c2c46faf3c91afa954b28f5` (whole diff, 16 files).
- Evaluator: Anthropic claude-sonnet-5-5 (Sonnet 5.5). Generator: Codex GPT6.1 Sol.
- Binary: pinned v0.47.2 `/Users/voightkampff/dev/sunholo-data/.stapledon-wt-iter4/runtime/bin/ailang`. Platform: darwin/arm64 only. Renderer unchanged, GPU gate N/A.
- Parent `M1.2b_AILANG_CATALOGUE` `passes` is still null (verified). Child `passes` is left for the controller.

## Commands
| Command | Result |
|---|---|
| `make test` (AILANG, AILANG_BIN set) | rc=0: physics 42/42, AILANG 30/30 (10 T1 tests), parity 601 and 17 lines, strict, wd-vm, **catalogue-vm printed transform-ok / selection-ok**, extraction 15/15 |
| `ailang check --package sim` | rc=0 |
| `cd sim && ailang test --package .` | rc=0, 30/30 |
| `make -n test` / `ci.yml` | `catalogue-vm` is a `test` prerequisite and CI runs `make test` |
| reverse repro | strict VM rc=1 ("std/list.reverse is evaluator-only"); interpreter rc=0 `[3,2,1]`. Reproduced independently. |

## Independent mutation drill (mine, not the executor's)
Each of 68 mutants was applied with a count==1 structural replace, hashed, and built (`check` rc=0 for all). I then recorded the named `ailang test` failures plus the strict-VM and interpreter entry outputs. The file was restored from a copy and the sha256 was asserted identical (`147e2454…`). The raw data is in `eval_R1-M1-SKY_M1.2b-T1_iter7_round1_mutants.json`.

**60 of 68 were killed.** Each kill is a named T1 test, strict VM BAD, and interpreter BAD. Every refusal predicate (x, y, z, g, c, blank ID with and without trim, wd, field count, header, trailing line, error propagation) has its own killer. Every package-call path, flag bit, counter, distance term, comparator direction, quota, skip, excluded count, sort and tier dispatch is killed too.

**8 survived:**
1. **`flag-dwarf-uses-wd-table`: real gap.** Dwarf rows can use `bbBpRpInvertible` instead of `bpRpInTable` and everything stays green. The fixtures use dwarf BP-RP 0.823 and -9, where the two predicates agree. I probed: at BP-RP 2.5 to 5.0 the dwarf table says in-range and the WD says non-invertible; at -0.5 it is the reverse. Fix: add a dwarf row at 2.5 (flags 0) and at -0.5 (flags 16).
2. **`trailing-blank-strip-two`: real gap.** Production rejects `row\n\n` (probed), but no test pins that refusal.
3. **`tier-limit` 50000→49999: measured residual.** The constant is only exercised through small-limit helpers. The plan assigns the boundary check to the integration milestone.
4. **Equivalent, unreachable or redundant (5):**
   - `v == v` is redundant: NaN already fails the range comparisons.
   - The `number` None arm is unreachable behind `finite`.
   - The blank-row arm is redundant, because it falls through to the field-count Err.
   - The `[] => Err("empty input")` arm is unreachable, since `split` never returns `[]`.
   - Tie→1 behaves the same under this stable `sortBy` (tie→-1 is killed).

## Makefile and config hunks
- **Guard is reached and non-redundant.** Switching `reverseRows` to `std/list.reverse` leaves `check` rc=0 and all named tests green (interpreter), but `make catalogue-vm` exits 2 with the strict-VM error.
- **Equality check is load-bearing.** With an `input` counter defect, the intact guard gives rc=2. With `test "$(cat)" = "$want"` neutered it gives rc=0 and prints `selection-BAD`.
- **toml export is load-bearing.** Removing the catalogue entry makes `check --package sim` rc=1 and `catalogue-vm` rc=2.
- **Not pinned:** deleting `catalogue-vm` from the `test` prerequisite list has no meta-test. This is the same as the existing `wd-vm` wiring.

## Named targets
- **foldl-cons reversal replaces `std/list.reverse`: measured residual, not a blocker.** The upstream bug is reproduced. The replacement is pure, and its order is pinned by 6 to 7 named tests. The strict-VM guard would catch a regression to `reverse`. Full-catalogue cost (several O(n) reversals) goes to the integration milestone.
- **`selectTier` pass-through: measured residual.** Tiers `"bogus"` and `"Medium"` silently return all rows with excluded=0 (probed on the strict VM). The contract covers only quick, medium and large. The writer or caller must validate. A sum type or Result is recommended.
- **Squared-distance overflow: measured residual.** With `(2e200,0,0)` listed before `(1e200,0,0)` and limit 1, the farther row is selected (both distances are inf). Magnitudes of 1e150 and 1e140 order correctly. The real catalogue is about 147 orders of magnitude below the overflow range, so this is acceptable and should be documented in the writer.
- **Sept-27 approval covers the split: confirmed.** `m1-relativistic-sky.md` has zero diff. The refinement restates design lines 180–203 (missing sentinel, extends past missing rows, 50,000 nearest including WD) and changes no threshold or AC. The parent stays null.

## Score
| Category | Points |
|---|---|
| Tests | 20/20 |
| Lint (`check`, no lint target) | 10/10 |
| Acceptance criteria | 27/30 (dwarf-flag and double-newline pins missing) |
| Code quality | 12/15 (dense one-line code, one aggregate refusal test, undeclared dead branches) |
| Documentation | 13/15 (changelog in `changelogs/unreleased`; JSON `\u` churn; design doc unchanged, which is appropriate) |
| Design fidelity | 6/10 |
| **Total** | **88** |

## Non-blocking findings
N1 dwarf bit-16 pin. N2 double trailing newline pin. N3 the 50,000 boundary belongs to integration. N4 declare or remove dead branches. N5 split the aggregate refusal test. N6 `\u` escape churn in the sprint JSON. N7 pre-existing `[exports]` warnings for test modules. N8 stringly-typed `selectTier`. N9 code density. N10 the plan's evaluator checkbox is for the controller.
