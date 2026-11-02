# Evaluation: R2-KERR package candidate af2a767 (K1.1a/K1.1b, compact radial chart + regular sphere), round 1

Judge: Claude Sonnet 5.5 (other family from Codex A). Scope: package maths and the current axis/compact/regular-action-angle solver only. Not the GPU sprint, not the full rig, not publication.
Numerical tests are evidence, not continuum proofs.

## Verdict
**Scoped numerical/code verdict: PASS, 89/100.** No numerical or domain blocker found.
**Publication readiness: CONDITIONAL.** `/private/tmp/kerr-quality-final056.txt` was still 0 bytes when I finished, and the exact-head sweeps and mutations have not been confirmed (see below).

## Score (100)
| Area | Max | Score | Basis |
|---|---|---|---|
| Radial chart derivation and root/sign handling | 15 | 14 | Re-derived by hand (below); chart is correct |
| Angular sphere, pole phase, asymptotic sky, action-angle phases | 20 | 18 | Independent oracle agrees to 3.8e-9 on 140 rays; `phi` meaning undocumented |
| Conditioning / refinement / failure semantics | 15 | 14 | Step-independent to ~1e-10; errors are loud; no clamps |
| Zero spin, scalar, capture classification | 10 | 9 | s=0 rays match the oracle; capture matches the analytic R(u) |
| Full-Weyl frame/tides | 10 | 9 | Test-evidenced only (80 tensors pass); I re-derived nothing here |
| Tests / gates matched to logs | 15 | 13 | Counts verified (see Evidence); quality pending, stale logs |
| Evidence honesty / no invented gates | 10 | 9 | Claims match the logs, with the caveats below |
| Docs / API clarity | 5 | 3 | `SkyTrace.phi` semantics, stale sweep logs, legacy exports |
| **Total** | 100 | **89** | |

## Independent checks I ran (scratch only, `/tmp/ev_scratch`)
1. **Radial chart algebra (by hand).** With t=rt/u and x²=1−t, R/u⁴ = (1−t)Q(t), where Q = 1+t+(1+A)t²+(1+A+B)t³, A=a/rt², B=b/rt³. This uses the root condition C=1+A+B. It matches `kerr_trace.rates` exactly.
   - The derivatives x' = rt/(2u₀)√Q (turning chart) and x' = −√q (no-root chart, u=u₀/x) both check out. Both include the ζ'=u₀ζ rescale, which matches `sphereRates(s/u₀, K/u₀²)`.
   - For an inward Escaped ray, `classifyCapture` guarantees v<−tol, so `outerTurningRadius` cannot fall into its `Err→rt=0` branch. The silent mis-sign branch is therefore unreachable. A defensive `Err` there would still be better (nonblocker N3).
2. **Independent Kerr-Schild Cartesian Hamiltonian oracle.**
   - It is written from scratch in pure Python (no scipy/numpy available on this machine). It uses the ½g^{μν}pp Hamiltonian with Kerr-Schild g^{μν}=η−2H l l, RK4, and finite-difference gradients.
   - The observer covector comes from the spec's ZAMO projection, with the BL→KS covector and Jacobian maps done by hand.
   - It shares neither the Carter separation nor the sphere chart with the package or with `tools/kerr_null_ref.py`.
   - 160 rays: s∈{0,.5,.9,.998} × u∈{4,6,20,200,2e6} × 8 random directions. They include nz∈{0, ±1e-12, ±1e-7, ±1e-4, ±1e-3, ±0.4}, both senses and ±nt.
   - 8 were skipped because my generator made them non-unit; the package refuses them as `invalid_ray`.
   - **140 package-escaping rays: worst sky error 3.80e-9, 0 over 1e-5.**
   - 12 package-captured rays: 10 agree with the oracle. For the other 2 (s=.998, u=4 n=(−.7,−.714,1e-7) and u=6 n=(−.95,.312,−1e-4)) I evaluated the Carter R(u) directly. It is >0 on the whole interval from the horizon to the observer, so the package "captured" is correct. The oracle's "escaped" there is its own artefact: it turns around at r≈1.167 because it under-resolves the near-horizon region.
   - The package's own near-axis test value (u=6, s=.9) also matches my oracle to ~4e-11.
3. **Near-critical, 30 rays** (s∈{.5,.9,.998}, u∈{6,20}, ψ at ε=1e-3/1e-5 above the bisected critical angle, 4 azimuths).
   - The package traces all 30 at steps 0.02, 0.005 and 0.0025 with 0 errors. The three step sizes agree with each other to ≲1e-10. This confirms the refinement and the 2e-14 floor on the near-critical class.
   - Against my RK4 oracle the worst error is 2.0e-5 (median 1.3e-6). That error is not convergent as I refine the oracle (1.4e-6, 2.0e-5, 9.8e-6, 1.4e-5 for hf 0.002…0.00025), so the oracle's finite-difference noise is the limit, not the package.
4. **Pole phase / lens phase.** For 42 near-axis rays I compared `phi` with atan2 of the sky. They agree to ~1e-5, except rays whose sky is within ~0.01 of the pole (up to 1e-2). The cause is that `phi` is the far-sphere azimuth, not the asymptotic azimuth. The geometric-vs-integrated sky consistency check (`lens_phase_conservation`, 1e-8) sits inside `finish`. Nonblocker N1.
5. **Gate files.**
   - `/private/tmp/kerr-final-check056.txt`: "58 files checked, all passed".
   - `/private/tmp/kerr-final-tests056.txt`: "729 tests: 729 passed, 0 failed, 0 skipped (22.3 s)". Matrix test counts confirmed: 280 near-axis, 80 tides, 49 trace.
   - I did not re-run the whole suite (the executor's log was used). I did run my own probes on `--bytecode`.

## Blockers
None for the scoped numerical verdict.

## Nonblockers
- **N1.** `SkyTrace.phi` is the BL azimuth on the finite far sphere. It is not the sky azimuth, and it differs by up to ~1e-2 rad for skies within ~0.01 of the pole. Document it, or expose `atan2(sky)`; consumers should use `sky` and `LensTrace.phase`/`node`.
- **N2.** The `axis-compact-{0..6}.txt` logs (5880 rays, 0 failures) count only "did not Err" plus a checksum, so they are a domain-coverage gate, not an accuracy gate. They precede the normalized-error/floor change in af2a767. They must be re-run at exact head before they are cited. The old `axis-sweep-*.txt` still contain the four failures and must not be cited as passing.
- **N3.** In `traceLens`, the `outerTurningRadius` `Err→rt=0` fallback is unreachable for Escaped rays. Make an inward ray with no root `Err("no_root")` instead of silently continuing outward.
- **N4.** The legacy BL Carter/RK4 exports (`polar_chart` Err at λ≠0, sn²<1e-300) remain public. They are documented non-production; note that they are not near-axis-safe.
- **N5.** The 280/49/12 oracle values come from the repo's `kerr_null_ref.py`, which shares the regular-sphere formulation. The independent KS result above is the oracle that is genuinely chart-independent; consider adding the 140-ray KS set as a second fixture.
- **N6.** The oracle needs scipy/numpy, and neither is installed on this machine (I could not run it here).

## Limitations of this evaluation
- I did not re-run the mutation scripts or the exact-head sweeps (the executor is still running them).
- I did not run the interpreter-mode full `pkg quality` or dry-run. The log is empty, so publication stays conditional.
- Tides/frame maths were scored from the passing 80-tensor test and the spec, not re-derived.
- My oracle is RK4 with finite differences. Its error floor is ~1e-5 near-critical and it cannot resolve near-horizon rays, so it validates only escaping rays.

## Commands
```
A=/Users/voightkampff/dev/sunholo-data/stapledons-godot-kerr/runtime/bin/ailang   # v0.56.0
cp -R .../ailang-packages-kerr/packages/relativity /tmp/ev_scratch/pkg   # head af2a767
$A run --bytecode --caps IO --entry main --package-dir /tmp/ev_scratch/pkg kerr_probe{,2,3}.ail
python3 /tmp/ev_scratch/or/cmp.py   # oracle: /tmp/ev_scratch/or/ks.py
```

EVALUATION_SCORE: 89/100
