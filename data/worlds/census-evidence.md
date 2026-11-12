# worlds 0.2.0 pin (R3-REASONS RT3b) — 2026-11-12, AILANG v0.56.1

The sim now pins `sunholo/worlds` 0.2.0 (lock content hash
`sha256:59b019bb…caae`, was 0.1.0 `sha256:74251652…5a02`). 0.2.0 adds the `propagate`
module and exports five constants from `history`; no 0.1.0 output changes. Measured
on the same clone before and after the pin, pinned runtime on `PATH`:

```text
make census                 -> census.json sha256 1a96191c…d688 before and after (= DEVELOPMENT.SHA256, census-25pc)
make worlds-parity (calibVm)-> calib-vm.jsonl sha256 58770e4e…0853 before and after
make calib-smoke            -> rows sha256 238415da…e2e0 before and after
```

The 100-pc report and the calibration-development report were not regenerated.

---

# Evaluation correction census — 2026-11-03, AILANG v0.56.1

The 25-pc development report has been regenerated against the normal registry
worlds 0.1.0 / celestial 0.6.0 pins. `DEVELOPMENT.SHA256` pins the new report.
Counts and moments remain unchanged; per-system digests change because the
synthetic-HZ assumption and atmosphere-rule citations are now accurate.

```text
census: 5685 systems; 64 seeds/preset; moments=true; labels/RV=true; nested=true; growthStable=true
```

For each preset, the first-seed complete population audit checks all 11,576
planets, including 589 M-dwarf rocky-HZ cases and 1,278 synthesised planets
around surveyed FGK hosts. Label violations = 0; RV violations = 0.
The RV audit evaluates celestial's edge-on circular amplitude directly and
asserts <=3 m/s, independently of the generator's acceptance predicate.
The moment test spans 64 seeds; the complete physical audit is explicitly
for the first seed and all four preset variants. Targeted tests additionally
exercise 128 seeds for M-dwarf HZ labels/atmosphere vetoes and 32 seeds for
population audits. Controls with a bad M-dwarf label and a synthetic giant
exceeding the RV limit both fail the audit as intended.

The historical 100-pc report below has not been regenerated in this correction
run. Its older digests and lack of the new audit fields do not certify the
current head. No census-large, full rig suite or final calibration claim is
made. Both census sizes now execute the same new label/RV audit when queued.

---

# Census evidence — v0.56.0, 2026-11-02

These are internal population checks against the four **provisional** dials,
not detector/encounter calibration. Seeds 0–63 are test seeds; seed 0 is not a
chosen First Contact slice. Library science uses celestial 0.6.0 and worlds
0.1.0 (package PR174, `4d6367a`); game validation used the ignored local-package
overlay. Normal registry-pin CI and `rig/full` remain separate landing gates.

The complete first-seed counts/digests contain every generated planet. The
64-seed statistical rows use the exact biological marginal: non-HZ SAG13 slots
are sterile by construction. `biospheres` means inhabited backgrounds, including
ended lineages; `mindsWindow` means a technological interval overlaps [0,16000].
Technology and remnants are counted at t=0. These differ from current detected
biospheres, visits, signals and contacts.

| Preset | 25 pc: biospheres / mindsWindow / technology / remnants, summed over 64 seeds | GCNS: same counts, summed over 64 seeds |
|---|---|---|
| Lonely | 41,207 / 0 / 0 / 0 | 2,522,399 / 0 / 0 / 2 |
| Scattered | 41,207 / 0 / 0 / 0 | 2,522,399 / 9 / 9 / 40 |
| Stapledon | 41,207 / 0 / 0 / 5 | 2,522,399 / 42 / 40 / 198 |
| Teeming | 65,459 / 2 / 2 / 18 | 3,989,317 / 246 / 238 / 630 |

Both registries pass all four analytic moment checks per preset: maximum |z|
2.24968 (25 pc) and 2.16641 (GCNS), below 4. First-seed nesting and growth
validation pass. Native tests additionally cover shuffled/appended registries,
ambiguous duplicate IDs, immutable measured fields, full metadata mutations,
finite-window edges and independent complete-system statistics.

- **25 pc:** 5,685 systems; seed 0 has 11,576 planets: 410 measured, 2 candidates,
  11,164 synthetic; 401 habitable and 589 debated. Complete report repeated
  byte-identically. SHA256 `39482d0def4b3cb7108eeefff40c4c3882d0106294db2fa069ebd44bc6517851`.
- **GCNS:** 331,311 systems; seed 0 has 707,231 planets: 1,577 measured,
  1 candidate, 705,653 synthetic; 24,240 habitable and 38,105 debated.
  SHA256 `fdb4dcdd391e40b435c1fc057f9d2a051c85105d9f982231c3c52fade3e4ecf0`.
  It matches 1,578 snapshot planets by navigation/archive identity; 21 are
  outside this registry or uncrossmatched. This is not a claim of complete
  positional cross-matching of every known 100 pc planet host.

`make census-large` passed **862.43 s / 900 s** (862.45 s total), including
pinned CSV verification and input preparation. It reuses the shipped catalogue's
truth/companion transformations and binary64 CSV positions, never the float32
sky binary. This measurement precedes the final immutable draw-plan preparation;
no full-large rerun of that final preparation is claimed. Earlier bounded runs
hit 900 seconds and produced no report; obsolete physics runs were discarded.
The bound was never raised.

Final preparations reuse host/slot hashes and immutable eligibility across
seeds, retain the exact HZ/RV path for surveyed FGK stars, and change no keyed
RNG API/domain/draw index or planet physics. **15/15 named tests ran on the
strict VM with zero fallback**. Seven prepared-plan cases compare every uniform
across 128 seeds (including negative seeds, RV vetoes and atmospheric limits),
and independent full population runs verify the statistical shortcut. The
post-preparation complete 25 pc report stayed byte-identical in **14.76 s**.

The actual 500-system subset's full census digest is
`9bd52bed5602d215925ded0726c84da91f2e1e550572044682cb2e6c0fe8c88e`
on strict VM and interpreter (1.75 s / 19.12 s after the host index). It binds
complete physical/history scalars plus the untruncated observed-catalogue
metadata digest. Original snapshot parsing also reproduces the complete
1,599-planet witness `116e7d91897fef17cb8e44e91742ceffc97286fbbb52a4e7a357d5fb56d1c8f1`.

Reusable epoch expectations live in `sunholo/worlds/epoch_statistics`, with
34/34 package tests and full staged quality showing no gates. Proof inventory:
0/12 contracts verified, 0 refuted, 13 uncontracted exports. Strict inventory
still gates PUB011; no proof/strict-quality pass is claimed. AILANG v0.56.0
ignores failing `requires` under strict VM despite `--verify-contracts`, while
the interpreter rejects them; reported through ailang-feedback as
`inbox_1793648615351_707bec99`. Valid-domain parity is measured; VM enforcement
of invalid domains is not claimed, and no downstream VM workaround was added.
