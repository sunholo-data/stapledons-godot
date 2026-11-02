# R3-WORLDS execution checkpoint — Codex B, 2026-11-02

**Status: in progress, not complete.** D-144's nine recommendations are recorded
as accepted. The first execution commit was `eb4d892f`. Game implementation
continues on `design/r3-worlds`, draft PR #371; nothing merged or published.
The remaining dependent work stops at the explicitly attended package handoff
and the confirmed upstream VM disagreement. No downstream VM workaround was made.

## Draft PRs and review state

| Repository | Branch | Draft PR | Pushed code checkpoint |
|---|---|---|---|
| Game | `design/r3-worlds` | [#371](https://github.com/sunholo-data/stapledons-godot/pull/371) | `68fe72ad` (this report/progress update follows) |
| Design | `feat/life-and-worlds` in `../stapledons-design-worlds` | [#50](https://github.com/sunholo-data/stapledons-design/pull/50) | `c876de1` |
| Packages | `feat/worlds-habitability` in `../ailang-packages-worlds` | [#174](https://github.com/sunholo-data/ailang-packages/pull/174) | `00f0c7f` |

Independent cross-family evaluation is pending. No `rig/full` was run: the
new targeted `exoplanets-check` is already red on a confirmed VM bug, and the
package-dependent milestones cannot pass before the attended publications.
This is not a gate waiver or a claim that the complete sprint passes.

## Milestones

- **W1.0:** `physics/life-and-worlds.md` in the fresh design clone: cited
  baseline, exact table/equation/page locators, 41 LW check values, Sandberg's
  rate prior, canon lifetime range, SAG13 units and coefficients. The game
  imports the registry and checks LW lore values; a one-digit HZ mutant fails.
  Source review is complete to the limits listed below; registry merge/review
  remains open. Three historical rounding cells are corrected in the feature
  doc: 805→804, 1.7e5→1.6e5, .27→.26. The physical inputs are unchanged.
- **W1.1:** celestial 0.6.0 implemented and ready for attended publication:
  Kopparapu HZ/clamp flag, insolation, equilibrium temperature, RV amplitude,
  transit geometry, mutual Hill spacing; tests, contracts, docs and changelog.
  No sim pin to an unpublished version.
- **W1.2:** worlds 0.1.0 implemented: baseline priors/quantiles, dial and
  effective luck, stable disc integrals/inverse CDF, SAG13 occurrence and
  caller-uniform histories. Shared pathway ranks preserve nesting and onsets.
  Native/local tests pass; full publication quality waits for celestial 0.6.0.
- **W1.3 (part):** FNV-1a UTF-8 ids, keyed SplitMix64 and exact unit53, without
  changing the World's stream counters. Independent oracle covers 10,000
  distinct ids/draws/uniforms on VM and interpreter. `rng-keyed` is in strict
  and parity. Calibration core, policies, detection and budget probe are pending.
- **W1.4:** not run. S2's observe 0.2.0 photon budgets and the two publications
  are prerequisites. The registry search returned observe 0.1.0; a separate
  versions request timed out. No literal detection reaches were substituted.
- **W2.0:** deterministic measured-planet ingestion implemented, raw snapshot
  pinned/uploaded, curated fields retained. Eight native tests and deterministic
  regeneration pass. Interpreter verification of the whole compiled table
  passes; the same VM verifier fails (AILANG #2052). This milestone is **not passed**.
- **W2.1–W2.3:** not started; package/population/calibration dependencies pending.
  No census, lazy population, protocol 2.17 integration or AC16 leak test is claimed.
- **W2.4:** not reached. No map changes or mock-up renders were made.
- **W2.5 (draft only):** three Archive entries under design
  `lore/drafts/r3-worlds/`, for Mark. Proposed hints are not registered and
  the entries are excluded from active import. No landing/status move to implemented.

## Verification evidence

Pinned runtime v0.54.18; teaching prompt v0.16.7 loaded before AILANG edits.

```text
✓ 139 files checked, all passed!
7 tests: 7 passed, 0 failed, 0 skipped
keyed RNG strict VM: 10000 UTF-8 hashes, keyed values and top53 identical to oracle
keyed RNG interpreter: 10000 UTF-8 hashes, keyed values and top53 identical to oracle
rng_ref: ok
rng-keyed: keyed-rng-ok (10000 uniforms, strict VM = interpreter)
strict digestScripted: crossing chunks 15 holds 1 turn 391 digest a9a7c96e3b78a6c05cdfd7ef6e23c3d7b76fe9d664ef0a660b26911b6d766b03
replay: 11 cases, all identical (44.9 s wall)
python-guard: ok (20 allowlisted, 0 awaiting AILANG port)
uid-guard: ok (401 .uid files)
lore-test: lore_test: lore-ok (strict VM = interpreter)
lore-test: lore_check_test: lore-check-ok (strict VM = interpreter)
lore-test: lore_values_test: lore-values-ok (strict VM = interpreter)
lore-check-test: ok
lore-import-test: ok
lore-values: 149 HB rows, 40 RS rows, 36 IS rows, 41 LW rows
lore-check: 13 entries, every unlock a known hint, every check id resolved, every number bound but 2 allowed (266 registry rows)
lore-import: cross-repo: ../stapledons-design-worlds at c876de1 equals the vendored copy
```

`make strict parity replay python-guard uid-guard` passed. The two pre-existing
photon-drive lore unit allowances remain explicitly reported by the checker.
The existing `session10k` golden is unchanged; it is **not** the unimplemented
four-preset AC16 check. Broad native sim package tests: 586 tests passed, 0 failed, 0 skipped (8m53.9s); the final provenance change separately passes all 8 exoplanet tests on the strict VM.

Celestial:

```text
✓ 22 files checked, all passed!
156 tests: 156 passed, 0 failed, 0 skipped
14 tests: 14 passed, 0 failed, 0 skipped
habitabilityProbe(1000): 12012 values strict VM = interpreter, byte-identical
habitabilityProbe(1000): 12012 values satisfy runtime contracts
habitability contracts: 7/7 invalid domains rejected
✓ no gates
```

Full quality: 1/42 contracts verified, 0 refuted, 90 uncontracted exports;
15 unsupported encodings, 8 verifier errors; effects [IO], 132/132 exports
pure; tests 156/156 and smoke passed. Proof gaps are not claimed as proofs.

Worlds:

```text
✓ 11 files checked, all passed!
20 tests: 20 passed, 0 failed, 0 skipped
19 named-test bodies ran on the VM, 0 fell back
worlds smoke: strict VM = interpreter (byte-identical), runtime contracts enabled
PUB015: staged smoke failed
package sunholo/celestial@0.6.0 not found in registry
```

100 generated property cases and 10k history/occurrence vectors are covered.
Quality inventory: 0/7 contracts verified, 0 refuted, 12 uncontracted exports;
19/19 exports pure. `--no-run` reports no gates **only for inventory**; it does
not clear PUB015 or make worlds publish-ready.

Exoplanets:

```text
8 tests: 8 passed, 0 failed, 0 skipped
bytecode: 8 named-test bodies ran on the VM, 0 fell back
exoplanets-check: JSON, AILANG module and curated differences byte-identical
exoplanets-verify: 1599 generated planets and 18722 nonmissing archive scalars equal regeneration field-for-field; curated alpha Cen and TRAPPIST-1 equal source modules; full JSON digest 116e7d91897fef17cb8e44e91742ceffc97286fbbb52a4e7a357d5fb56d1c8f1
GET_FIELD: index 4 exceeds field count 2 (in pkg/stapledons/sim/tools/exoplanets.main)
make: *** [exoplanets-check] Error 1
```

The corrected full-data witness passes on the interpreter. It compares every
record scalar and provenance string explicitly and hashes untruncated JSON;
its final digest is printed above. The VM fails. Cause is unconfirmed, although
the stack names the imported generator's `main`. The production gate retains
the failing VM witness, with no entry rename/fallback.

The initial witness compared human `show()` displays, which truncate composite
values. That claim was retracted and the verifier replaced with complete
record/field comparisons plus full JSON hashing. Mutation tests cover long
metadata and middle-record changes. An independent read-only Python test
oracle (listed in `tools/python-allowlist.txt`) also passes:

```text
exoplanets independent oracle: 1590 snapshot planets, 18722 nonmissing scalars bit-identical (IEEE754 binary64); missingness and derived provenance correct
```

Python does not generate any catalogue or pipeline output.

## Data and references

The [raw NASA snapshot](https://storage.googleapis.com/stapledons-voyage-assets/planets/exoplanets_ps_100pc_20261102.csv)
has SHA256 `ce6345482ca387dd6a8fca73d909d25b78c3ce24eea5efab1afdbda279ea335b`:
1,590 planets/1,077 hosts; output 1,599 planets/1,079 hosts, including two
curated candidates; 412 planets on 241 navigation-registry hosts. Eleven
curated planet rows are unchanged. All seven TRAPPIST-1 default PS distances
are null, so the raw distance predicate excludes them; the curated rows restore
them explicitly. The snapshot is not claimed to contain every known nearby
planet regardless of missing distance. See `data/planets/exoplanets_source.md`.

No reference render/audio/video URLs: W2.4 was not reached and no visible or
sound change was made. The public URL above is scientific source data.
After fetching/checking assets, `godot --headless --path . --import` completed
with exit 0, but emitted CSV translation-import errors for the starmap truth
CSV (and CSV translation warnings). This is not a clean visual validation;
no Godot rendering acceptance is claimed by this checkpoint.

## Calibration and slice seed

**No calibration results exist yet.** The columns below preserve the accepted
targets, not measurements or estimated achievements. Binding strategies are
cautious explorer and mid-range wanderer at Standard's 16,000-year Earth clock.

| Preset | Measured detected / visited / remnants / signals / contacts | Accepted target bands in that order |
|---|---|---|
| Lonely Universe | not run | baseline zero offsets; no encounter target |
| Scattered Few | not run | 20–40 / 3–6 / 1–3 / 1–3 / 1–2 |
| Stapledon's Voyage | not run | 40–80 / 5–10 / 3–6 / 5–10 / at least 5 (5–8 typical) |
| Teeming Galaxy | not run | 80–160 / 8–12 / 6–12 / 15–30 / 8–12 |

**Chosen slice seed: none.** Search follows the calibrated default preset;
choosing one against uncalibrated parameters would not fulfil OQ3.

## Attended handoff and open evidence

Ready now (celestial 0.6.0, no publication performed):

```text
! cd /Users/voightkampff/dev/sunholo-data/ailang-packages-worlds/packages/celestial && ailang-publish
```

Worlds is implemented but **not ready yet**: after celestial publication,
regenerate its lock and rerun check, tests and full package quality. Only after
PUB015 clears is its attended publish line:

```text
! cd /Users/voightkampff/dev/sunholo-data/ailang-packages-worlds/packages/worlds && ailang-publish
```

Then pin published versions, obtain S2 observe 0.2.0, implement/probe the
calibration and run it; resume W2.1–W2.3 after the population prerequisites.
AILANG #2052 must be fixed upstream before the measured-data gate can pass.
The pinned toolchain is unchanged; a future bump must move binary/CI/lock together.

For Mark: review design PR50 (including the explicit nominal M=0.75 assumption)
and the Archive drafts. Recommendation: retain the labelled approximation until
a denominator-matched type census is selected; do not present it as a verified
Reylé measurement. The original Chambers section locator also remains unverified,
with an exact alternate primary citation for the formula. No OQ1–OQ9 is reopened.

Upstream reports on v0.54.18:

- SMT scientific-numeral emitter: `inbox_1793635195781_38382f1d`.
- Formatter named-test/let-bound-record nil node: corrected reproduction
  `inbox_1793635675993_104d08ec`; earlier `inbox_1793635573382_2800f307`
  misidentified the trigger and was explicitly corrected.
- [AILANG #2052](https://github.com/sunholo-data/ailang/issues/2052):
  `inbox_1793635994881_582a4a2b`; interpreter confirmation
  `inbox_1793636152850_f8f6f0f2`. The earlier human-display comparison claim was retracted in `inbox_1793637149423_28d159fb`; final verification uses explicit complete comparisons.

All three working clones are committed/pushed with no stashes at final handoff;
the final response records the last game commit and audit results.
