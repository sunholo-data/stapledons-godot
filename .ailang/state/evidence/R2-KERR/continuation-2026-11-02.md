# R2-KERR continuation: v0.56.0, regular charts and table preflight

Authority: Mark's continuing Codex A prompt and D-144. The runtime bump branch
origin/chore/ailang-0.56.0 was merged first; `make runtime` staged v0.56.0,
e1ef997298bd96f27a3cf28e7997e766b73270be. Teaching prompt v0.16.11 loaded.
Package candidate: ../ailang-packages-kerr/packages/relativity, feat/r2-kerr,
65bcaa8 (production solver af2a767). Publication remains Mark's step.

## Numerical changes and regression chronology

The original near-axis named regression was RED (0/1), then GREEN with a
regular Cartesian angular sphere and explicit signed pole phase. A subsequent
5,880-ray sweep found four *additional* far-domain failures in radial event
departure: u=2e6, spins .5/.75, n_r=-.6, n_phi=-1e-4, both hemispheres.
Those failures were not counted as capture. The first sphere-only candidate's
quality/evaluation attempts were superseded, not passed.

The production solver now uses a compact radial root coordinate
x=sign(du/dzeta_past)*sqrt(1-rt/u), crossing a simple outer turning root at x=0.
Its radial potential remains factored; the sphere chart has no polar
denominator. Cash–Karp 5(4) replaces representability-sensitive radial patches.
The far-radius named regression was RED 3/4, then GREEN 4/4. The standalone
BL/event exports remain available and retain their direct departure regression.

`traceLens` also carries regular unwrapped angular-action and node phases;
its reconstructed Cartesian direction must agree with the independently
integrated sphere state. `lensAngles` removes the flat-space arc before F32
storage. A coefficient-fit ray at psi=.977920452141398*(1+1e-8), chi=.7,
u=6,s=.9,step=.0025 exposed an absolute accumulated-phase error budget below
binary64 rounding. That named regression was RED 5/6, then GREEN 6/6 with
relative accumulated-angle errors and a fixed measured 2e-14 floor. Its
independent DOP853 sky is (-.6063575941257582,-.4931450632000425,
-.6238095981046209), and .005/.0025 step refinement is checked explicitly.

## Exact-head bounded sweeps

From evidence/R2-KERR/bench, A is the absolute game runtime; PKG is the
development package root. These are development package contexts, not a pin.

```
$A run --quiet --bytecode --strict-bytecode --package-dir "$PKG" \
  --entry benchmark --args-json 400 kerr_bench.ail
# 347 escaped, 53 captured, 0 critical, 0 failed; checksum 9.667368447086702
# real 3.37s, user 3.77s, maximum RSS 138395648 bytes

$A run --quiet --bytecode --strict-bytecode --caps IO --package-dir "$PKG" \
  --entry band --args-json N kerr_axis_sweep.ail  # N=0..6
```

Each band: **840 rays, 768 escaped, 72 captured, 0 critical, 0 failed**.
Total: **5,880 rays, 5,376 escaped, 504 captured, zero solver failures**.
Spins 0/.1/.25/.5/.75/.9/.998; u=4/6/20/200/2e6; radial components
-.9/-.6/-.3/0/.3/.6/.9; azimuth magnitudes 0/1e-16/1e-13/1e-10/1e-7/1e-4;
both azimuth senses and both polar hemispheres. Exact zero is intentionally
repeated by the two sense branches. This is discrete coverage, not a proof
over the continuous domain. Raw final logs: axis-final-0.txt through -6.txt
and sweep400-final.txt. The sphere-only 400-ray run took 67.03s; these are
bounded mixed-ray timings, not a promised full-bake cost.

Independent oracle: `kerr_null_ref.py --nearaxis`, NumPy/SciPy versions pinned
in tools/kerr-oracle-requirements.txt. Fixture nearaxis.json has 336 rays,
280 escaping (each pinned by a native package test), both hemispheres/senses,
seven spins and u=4/6/2e6. Maximum oracle refinement 3.50625e-15; maximum null
residual 1.37484e-13. Analytic Schwarzschild great-circle and angular invariant
tests cross multiple poles independently of this numerical fixture.

## Runtime/verifier disposition

`verify kerr.ail` now exits zero: 16 exports, 15 skipped, one without contracts;
the two prior invalid-SMT helper/sqrt errors are now unsupported-encoding
skips. The minimal repro likewise reports one unsupported encoding, no error.
This confirms the leak fix, **not a proof** of these functions. Inline source
tests: **19 tests: 2 passed, 0 failed, 17 skipped**. The pre-existing generated
domain-filter skips remain disclosed. Formatter round-trip of the regression
test blocks passes and preserves/runs the tests. Strict VM/interpreter digest
bytes remain exactly **560.5017148517253** (independent reference within1e-9).

Full quality, smoke, dry-run and independent review results will be appended
after completion; no unfinished/canceled invocation is a passing gate.

## Table preflight: original layout FAILS, no production pins

Development generator/harness live under tools/kerr_dev and use a temporary
consumer manifest with an explicit local package context. The game registry
pin and sim protocol remain unchanged. `tools/test_kerr_lut.sh` creates that
context; it is not a release pin. The pure table tests include the measured
Schwarzschild log coefficient and a separately measured nonzero twist.

The proposed 96x64 boundary grid was generated by package analytic-capture
bisection. Across 6,048 cell-centre probes its bilinear maximum is
1.6006073e-3 rad; Catmull–Rom radius with linear-extrapolated ghost rows gives
6.3321692e-4 rad. These are measurements, not silhouette-golden passes.

The first complete regularised row (u=6,s=.9,chi=.7,1536 columns, cutoff1e-8)
was generated in AILANG and compared after F32 encoding against 1,535
independently refined package rays. It FAILS the1.2e-4 rad budget:

- Even with the exact boundary: **9.0074193e-4 rad**, worst near the antipode
  (psi3.12809274294005). This is interpolation/representation evidence.
- F32 boundary .977920472621918 vs exact .977920452141398: **59 false
  captures**, maximum escaping-ray error **2.937606 rad**. Boundary rounding
  exceeds the near-critical first-column separation.

The original F32 boundary plus1536-column scheme is therefore not bake-ready.
Per K1.2's failure rule, do not pin assets or claim a GPU Kerr sky. A doubled
row is being measured to distinguish column resolution from boundary precision.
Recommend reviewing a hi/lo boundary representation and the antipode phase
chart/interpolation before full generation. No cutoff narrowing, dropped
probe, failure-as-capture, or Schwarzschild substitute is accepted.

K1.3 preparation mirrors the package's scalar/frame math in float64 arrays:
40 RK seed rows,5 invalid-spin checks,13 independent V33 frame/frequency pins.
`make kerr-physics-test`: **58 passed,0 failures**. `make physics` with those
anchors delegated through tests/test_physics.gd: **1082 passed,0 failed**.
Table loading/interpolation, remaining RK14–17 CPU anchors and GPU milestones
remain open. No GPU sky, reference sky renders, MP4, upload or aboard demo is
claimed from these headless measurements.
