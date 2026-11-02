# R3-WORLDS continuation report — Codex B, 2026-11-02

**In progress; no landing or complete-sprint claim.** Mark's D-144 approval and
all OQ1–OQ9 recommendations stand. This continuation implements the accessible
W1–W2 work against local package sources, validates it on released AILANG
v0.56.0, and supplies the attended publication/render handoffs. No PR was merged
and no package was published by Codex. Mark published celestial 0.6.0 during
the continuation; the game pins that published version.

## 1. Draft PRs and toolchain

| Repository | Branch / clone | Draft PR | Pushed checkpoint |
|---|---|---|---|
| Game | `design/r3-worlds`, `stapledons-godot-worlds` | [#371](https://github.com/sunholo-data/stapledons-godot/pull/371) | `1f7444cb` implementation/evidence; this documentation handoff follows |
| Packages | `feat/worlds-habitability`, `ailang-packages-worlds` | [#174](https://github.com/sunholo-data/ailang-packages/pull/174) | `4d6367a` |
| Design | `feat/life-and-worlds`, `stapledons-design-worlds` | [#50](https://github.com/sunholo-data/stapledons-design/pull/50) | `c876de1` |

Merged `origin/chore/ailang-0.56.0` first (`64a8d426`), then ran `make runtime`.
Released binary: v0.56.0, `e1ef997298bd96f27a3cf28e7997e766b73270be`;
teaching prompt v0.16.11 loaded before AILANG edits. PR #377 was still open at
final preflight; merge `origin/main` after it lands. No runtime binary is
committed. The `star_names` entry rename came with that merge.

The unpublished worlds package is used only through an ignored isolated
overlay (`tools/worlds_dev.sh`, `tools/worlds_ailang.sh`). The committed manifest
and lock contain published registry pins; **there is no local path pin and no
unpublished worlds pin**. Consequently final production CI/rig acceptance is
pending attended worlds publication and its game pin. Initial checkpoint
`57e62d2b` passed the fast tier; that result does not certify this final code.
Independent cross-family evaluation is pending. No `rig/full` was started.

## 2. Milestones and measured gates

| ID | Implemented in the drafts | Remaining acceptance |
|---|---|---|
| W1.0 | Cited normative baseline, 41 LW rows; lore checks and mutants | Design PR50 review/merge; two source qualifications below |
| W1.1 | Celestial 0.6.0 HZ, clamp, insolation, Teq, RV, transit, Hill; published by Mark and pinned | No new publication required |
| W1.2 | Worlds 0.1.0 baseline/dial/disc/occurrence/histories; explicit inference helpers and finite-epoch statistics | Attended publication, then registry pin and production gates |
| W1.3 | Keyed RNG; pure marked-Poisson Monte Carlo; detected-only strategies, retarded observation, search scoring/conflict reporting; detector interface and budget probe | S2 photon backend, production matrix budget |
| W1.4 | 32-row development artifact on both engines, provisional table below | Photon calibration, 256-seed/four-strategy matrix, Gentle/Hard, final presets/ruling, pinned every-sixteenth-row replay, slice search |
| W2.0 | Complete measured catalogue and scalar/provenance witness, now passing on v0.56.0 | No #2052 blocker remains |
| W2.1 | Stable keyed population, measured constraints/provenance, HZ/debate, eta-Earth and SAG13 synthesis, survey veto, Hill spacing | Production package pin/gates; inference-source review below |
| W2.2 | Internal 64-seed census, exact expectation, nesting/growth/digest witnesses; full GCNS run 862.43 s / 900 s | Production package pin/gates; broader identity coverage noted below |
| W2.3 | Free minor 2.17, preset envelope, public physical DTO, host/target/system projection and AC16 leak audit | Production package pin/gates |
| W2.4 | Four inspected/uploaded Godot review mock-ups | Mark review before product UI/copy; HZ-band ABI review |
| W2.5 | Three Archive drafts remain excluded from live import; changelog/report/progress | Mark lore review, independent judge, production gates and landing |

Population preserves every measured source record, including missingness and
individual field provenance; it never fills a measured host with extra synthetic
planets. Non-dwarf stars receive no dwarf mass fit. Synthetic relative Kepler
orbits include both stellar and planetary nominal GM. HZ temperature clamping
is retained in the public citation. Stable keyed uniforms consume no existing
World RNG counters. Host indexes preserve original observation order, because
the first available measured stellar value is meaningful.

Protocol 2.17 was free on main and the concurrent Kerr PR (maximum minor 16).
The physical encoder accepts no preset/dial/history input; `target` is measured
or candidate only, and synthetic `system` planets appear only within 0.1 ly.
All 241 measured-host directory rows appear on full state only. The 2.17-only
`system.worlds_planet_ids` joins those records without inventing rendered discs.
The gameplay bridge still negotiates 2.16; its only change is the 17 constant.

### Verification (local overlay unless stated)

```text
✓ 161 files checked, all passed!
628 tests: 625 passed, 3 failed, 0 skipped (19m10.91s)
38 tests: 38 passed, 0 failed, 0 skipped (strict VM, corrected protocol test files)
42 tests: 42 passed, 0 failed, 0 skipped (strict VM, final worlds/protocol/census/calibration files)
bytecode: 42 named-test bodies ran on the VM, 0 fell back to the evaluator
sim bridge: 0 failures
bh-hud: 64 passed, 0 failures
19 tests: 19 passed, 0 failed, 0 skipped (calibration strict VM)
bytecode: 19 named-test bodies ran on the VM, 0 fell back
19 tests: 19 passed, 0 failed, 0 skipped (calibration interpreter)
worlds-parity: worldsVm worlds-ok (strict VM = interpreter)
worlds-parity: protocolWorldsVm protocol-worlds-ok (strict VM = interpreter)
worlds-parity: censusVm census-ok (strict VM = interpreter)
worlds-parity: calibVm 2 development seeds byte-identical
keyed RNG strict VM/interpreter: 10000 UTF-8 ids/draws/exact unit53 identical to independent oracle
replay: 11 cases, all identical (43.5s wall, final frozen source)
world-hosts-check: measured host facts byte-identical
python-guard: ok (21 allowlisted, 0 awaiting AILANG port)
uid-guard: ok (402 .uid files)
ui-theme-check: ok
ui-theme-check: negative controls (seeded StyleBoxFlat, low contrast) fail as they must
worlds-leak: four presets × two engines byte-identical; schema/import audit passed (347.4s)
```

The broad native run's three failures were stale assertions of newest minor
16 in archive/crew/interlude tests. They were corrected to 17; all 38 tests in
those files pass on the strict VM. Its other 625 tests passed, including the
new population and calibration tests. A complete second 19-minute native run
was not performed; **`make sim` as a single invocation is not claimed green**.
The two old closed Session literals were also updated to extend `newSession()`
when the new cached catalogue fields made the full check reject them.
The final Godot bridge check passes; HUD resource-leak warnings at shutdown
remain visible in the log, with no script errors or failed assertions.

Strict core, parity, all historical replays, independent RNG oracle, lore
checks/import/mutants, host regeneration, smoke and policy guards passed.
The historical moving/adversarial replays retain their existing goldens. The
new AC16 fixture has two three-tick voyages that positively expose a catalogue
target and a local synthesized system, then idle clock/galaxy draws, totaling
10,000 accepted ticks. It compares complete public bytes across four presets
and both engines, exact DTO keys, host counts, target visibility and system
joins; imports and biological field reads are linted too. Each stream is
1,513,789 bytes, SHA256
`62e594d9d64f591dee54df63b2733471607ef3720145d73d3ba540c0473ff4e1`.
This is not a claim of 10,000 continuous travel ticks.

### Package and measured-catalogue evidence

Celestial: 156/156 native tests; 16 stellar strict-VM tests; full quality with
no gates. Private 64-row `stellar_ld` batches reduce cold check RSS from
295.6–302.4 MB to 100.4–105.8 MB (2.85–2.98 s to 2.05–2.09 s). API and normalized
interface are unchanged. All 508 rows and 1,400 interpolation samples are
byte-identical on both engines; SHA256
`42a7ab2996026697201ee74f1351e70132e3eb6649fbad23a5cd8a2898502858`.
No physics changed. Evidence: package `tools/check_memory.md`, PR174.

Worlds: 16 files checked; 34/34 native tests; 32 named test bodies on strict VM,
0 fallback, plus two property suites. Full `ailang pkg quality` reports no gates,
including staged registry smoke now celestial is published. 25/25 exports pure;
0/12 contracts verified, 0 refuted, 13 uncontracted. Strict proof mode still
has PUB011. Quality acceptance is not a claim of complete formal proofs.

The #2052 entry-resolution fix makes the complete measured witness pass:
1,599 generated planets and 18,722 nonmissing archive scalars equal regeneration
field-for-field; all curated alpha Cen/TRAPPIST-1 fields are retained. Full JSON
science digest remains
`116e7d91897fef17cb8e44e91742ceffc97286fbbb52a4e7a357d5fb56d1c8f1`.
The independent raw-scalar oracle is binary64 bit-identical. The compact
canonical-JSON source representation preserves results while avoiding compiler
blow-up for thousands of nested literal records. Cold full-FS witness: 7.92 s,
403 MB; pure catalogue digest strict VM 0.91 s/358 MB versus interpreter
1.33 s/556 MB. `std/fs.readFile` is evaluator-only, so the FS wrapper is not
claimed strict VM; the pure full-catalogue digest separately is strict.
The former truncated `show()` comparison was replaced in the earlier run by
complete comparisons and mutation tests; no truncated display is evidence.

The [pinned raw NASA snapshot](https://storage.googleapis.com/stapledons-voyage-assets/planets/exoplanets_ps_100pc_20261102.csv)
has SHA256 `ce6345482ca387dd6a8fca73d909d25b78c3ce24eea5efab1afdbda279ea335b`.
It contains 1,590 planets/1,077 hosts; output has 1,599 planets/1,079 hosts,
including curated candidates. 412 planets match 241 navigation hosts. Raw
TRAPPIST-1 default distances are null, so the explicit curated rows restore
those seven planets. The snapshot does not promise every known planet with
missing distance. Auxiliary host facts compare exactly to navigation data.

### Census evidence

The 25-pc census covers 5,685 systems, 64 seeds and four provisional dials.
The complete first seed has 11,576 planets: 410 measured, two candidates and
11,164 synthetic; 401 habitable and 589 debated. Every planet is included in
first-seed counts/digest. Statistical rows use an exact biological marginal:
deterministically sterile non-HZ SAG13 extras do not affect histories, so they
need not be regenerated for each of 64 seeds. This changes no probability,
identity, random domain or first-seed planet. Statistical maths is package-owned.

| Provisional dial | Sum over 64 seeds: background biospheres | Minds overlapping [0,16000] | Technological at t=0 | Remnants at t=0 |
|---|---:|---:|---:|---:|
| Lonely | 41207 | 0 | 0 | 0 |
| Scattered | 41207 | 0 | 0 | 0 |
| Stapledon | 41207 | 0 | 0 | 5 |
| Teeming | 65459 | 2 | 2 | 18 |

All realized-vs-expectation |z| < 4; largest 2.24968 (Teeming remnants).
Background biospheres include immutable inhabited histories, including ended
lineages; these are not current detectable encounter counts. Full JSON repeats
byte-for-byte, SHA256
`39482d0def4b3cb7108eeefff40c4c3882d0106294db2fa069ebd44bc6517851`.
A complete 500-system witness, including physical/citation mutation controls,
is identical VM/interpreter, SHA256
`9bd52bed5602d215925ded0726c84da91f2e1e550572044682cb2e6c0fe8c88e`.

The large tool uses the 331,311-row GCNS float64 registry produced by the
existing transform/truth/companion pipeline, not float32 sidecar positions.
Its 900-second watchdog includes input preparation and kills timed-out process
trees; true/exit7/timeout124 cleanup controls pass. Earlier slow runs exceeded
the budget and were not claimed successful. Identity matching uses navigation
host id then archive Gaia id; positional-only farther hosts remain uncrossmatched
until a fresh positional cross-match.

**Full GCNS result:** `make census-large` completed in 862.43 s (862.45 s total),
including input preparation, against the 900 s ceiling. The shared Studio run
has only 37.57 s of margin; it is one measured pass, not a guarantee across
machines/load. All moments, nesting and growth stability pass; max |z|=2.16641.
Seed 0 contains 707,231 planets: 1,577 measured, one candidate, 705,653 synthetic;
24,240 habitable and 38,105 debated. 1,578 snapshot identities match; the
remaining 21 are outside this registry or unmatched, not silently counted.

| Provisional dial | Background biospheres over 64 seeds | Minds overlapping [0,16000] | Tech at t=0 | Remnants at t=0 |
|---|---:|---:|---:|---:|
| Lonely | 2522399 | 0 | 0 | 2 |
| Scattered | 2522399 | 9 | 9 | 40 |
| Stapledon | 2522399 | 42 | 40 | 198 |
| Teeming | 3989317 | 246 | 238 | 630 |

Full report SHA256:
`fdb4dcdd391e40b435c1fc057f9d2a051c85105d9f982231c3c52fade3e4ecf0`.
Both full census JSON artifacts and timing/identity evidence are pinned under
`data/worlds/`; all three `DEVELOPMENT.SHA256` entries verify.
This successful large run uses correct relative GM and both exact host indexes.
The final source additionally prepares immutable history keys/eligibility once:
15 census tests and 128-seed exact-uniform comparisons pass, while the full
25-pc JSON remains byte-identical (14.76 s). The full 100-pc run was not repeated
after that exact optimization. Full first-seed populations/digests are untouched.

## 3. Reference mock-ups for Mark

All four actual 1600×1000 Godot 4.7.2 Compatibility viewport captures were opened
and inspected. Repeat captures and anonymous HTTPS downloads are byte-identical.
No production UI, copy or live lore was installed. A new dated public prefix
preserves prior references. Full hashes/reproduction:
[data/worlds/mockup-evidence.md](../../../data/worlds/mockup-evidence.md).

- [25-ly map](https://storage.googleapis.com/stapledons-voyage-assets/refs/worlds_v1/20261102T200654Z/map_25ly.png): true 3D sphere projected onto Galactic XY; 182 stars, 38 known hosts, 82 known planets.
- [81-ly map](https://storage.googleapis.com/stapledons-voyage-assets/refs/worlds_v1/20261102T200654Z/map_81ly.png): 5,591 stars, all 241 hosts/412 planets; overlap/decluttering awaits Mark.
- [TRAPPIST-1 strip](https://storage.googleapis.com/stapledons-voyage-assets/refs/worlds_v1/20261102T200654Z/trappist1_strip.png): seven measured planets, e/f/g debated; inferred HZ and explicit 2,566→2,600 K clamp.
- [alpha Cen A strip](https://storage.googleapis.com/stapledons-voyage-assets/refs/worlds_v1/20261102T200654Z/alpha_cen_a_strip.png): dashed candidate with labelled model-dependent orbit/radius; no life claim.

Numerical HZ edges/clamp details are offline mock metadata from package calls,
not new production protocol fields. A real W2.4 card needs a reviewed metadata
contract. This is an attended review boundary, not W2.4 acceptance.

## 4. Calibration results and attended package handoff

**Provisional interpreter measurements, reproduced byte-for-byte on the VM.**
Four seeds × four candidate dials × two binding strategies = 32 rows;
Standard clock 16,000 yr, arbitrary ideal 10-ly support, `photon_budget=false`.
The following medians are the same for cautious explorer and mid-range wanderer.
They are development samples, not final photon-budget predictions or a bound
on real encounters; all non-baseline presets remain `calibrated=false`.

| Preset | Detected / visited / remnants / signals / contacts | Accepted target in the same order |
|---|---|---|
| Lonely Universe | 1 / 1 / 0 / 0 / 0 | Baseline, zero offsets; no target |
| Scattered Few | 1 / 1 / 0 / 0 / 0 | 20–40 / 3–6 / 1–3 / 1–3 / 1–2 |
| Stapledon's Voyage | 0 / 0 / 0 / 0 / 0 | 40–80 / 5–10 / 3–6 / 5–10 / ≥5 (5–8 typical) |
| Teeming Galaxy | 2 / 2 / 0 / 0 / 0 | 80–160 / 8–12 / 6–12 / 15–30 / 8–12 |

These samples do not achieve the accepted targets. The quarter-dex search
reports conflicts rather than manufacturing a feasible solution. Artifact:
`data/worlds/calibration-development.json`, SHA256
`39d4f6e82d736aa2ee5075cd14c91f4b6f4d20f8fe7cf018e397d795c0a77b44`;
input science SHA256
`49b78ea2740fd1c2eab7c22106183514661c85e7140ff00c4750f3bc72d969e6`.
VM 19.65 s, interpreter 380.18 s. Development smoke 18.60 s ≤60 s, reduced to
four seeds after the 64-row four-strategy probe took 88.82 s. The production
256-seed/four-strategy, 30-minute budget is unverified; linear extrapolation
would exceed it and S2 needs a new probe. No final preset numbers were written
into canon. **Chosen First Contact slice seed: none.**

Celestial 0.6.0 is already published and pinned. Worlds 0.1.0 is ready for Mark:

```text
! cd /Users/voightkampff/dev/sunholo-data/ailang-packages-worlds/packages/worlds && ailang-publish
```

After that: pin the published worlds package, regenerate lock, rerun normal fast
CI and `rig/full` on the final PR head. S2 observe 0.2.0 is independently needed
before final W1.4. The last registry search still found worlds absent and only
observe 0.1.0. `configuredDetector()` is `None`; production `make calibrate`
exits with the missing-S2 reason instead of silently substituting a reach.

## 5. Review questions and upstream evidence

No accepted OQ1–OQ9 is reopened. Remaining review items:

1. **Mass inference source adjustment:** the available star rows have no K-band
   absolute magnitude for Mann (2019). The implementation explicitly uses an
   18-knot Pecaut–Mamajek dwarf Teff/Msun sequence (maximum 6.34% interpolation
   discrepancy at omitted source knots), labels it inferred and never applies
   it to WD/giants. Synthetic radius-to-mass sampling is a documented 128-cell
   log-mass prior / linear-radius Gaussian approximation using Chen–Kipping
   median relations, not the full Forecaster posterior. Measured fields never
   change. Recommendation: review this explicit approximation for v1, or extend
   the catalogue with the required K-band inputs before claiming Mann. Source
   and independent 780-quantile oracle are in package `planet_model` docs/tests.
2. **W2.4:** review the four frames before runtime UI/copy; decide the inferred
   HZ-band metadata contract and crowded-map presentation.
3. **Canon/lore:** review design PR50 and the three excluded Archive drafts.
   M-share 0.75 remains an explicitly nominal model parameter with empirical
   attribution unverified; the original Chambers section locator is unverified,
   while the formula has an alternate exact primary citation. Recommendation:
   retain the labels until a denominator-matched census/source is selected.
4. **Final calibration:** wait for S2, probe the real backend, then run/rule
   presets and select the slice seed. Development counts do not justify tuning.

Reports were sent through the explicitly invoked
[ailang-feedback skill](/Users/voightkampff/.agents/skills/ailang-feedback/SKILL.md)
to the canonical AILANG inbox. No external email/chat was sent.

| Runtime | Issue / evidence | Canonical message |
|---|---|---|
| v0.54.18 | SMT scientific-numeral emitter | `inbox_1793635195781_38382f1d` |
| v0.54.18 | Formatter named-test/let-bound-record crash, corrected trigger | `inbox_1793635675993_104d08ec` |
| v0.54.18 → v0.56.0 | [#2052 VM entry resolution](https://github.com/sunholo-data/ailang/issues/2052), now fixed and witnessed | `inbox_1793635994881_582a4a2b` and follow-ups |
| v0.56.0 | Quadratic compiler memory for nested constant record tables; 128-record/141-KB repro check 21.29 s/5.43 GB | `inbox_1793647232876_a814f0b7` |
| v0.56.0 | Documented prelude println rejected by check, accepted by evaluator/VM | `inbox_1793647242437_58bbdaf1` |
| v0.56.0 | std/fs.readFile strict-VM support gap (known Phase2E) | `inbox_1793647163478_e025808f` |
| v0.56.0 | --verify-contracts failing requires ignored on strict VM; interpreter rejects minimal positive(0) | `inbox_1793648615351_707bec99` |

The invalid-domain VM regression is separate from successful valid-domain
physics/witness tests. No downstream workaround or invalid-domain enforcement
claim was made. Mark's registry-cap #2057 was fixed upstream in v0.56.0 and
requires registry redeployment; the celestial memory change independently
shrinks checks without changing API, rows or physics.

## 6. Clone state and landing boundary

All game/package/design changes are committed and pushed at handoff; final
response gives exact heads and clean/no-unpushed/no-stash audit results.
PRs remain drafts. Design stays under `planned/r3`; roadmap is not marked done.
No `rig/full`, final-head fast-tier success, Mark render approval, independent
judge, production photon calibration or complete W1–W2 acceptance is claimed.
