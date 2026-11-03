# W1.3 development calibration evidence — 2026-11-02

**W1.4 remains open.** This is an ideal-detector development fixture, not a
photon-budget calibration. The registry only supplies observe 0.1.0. The
production calibration entry exits 1 with the explicit missing-S2 reason;
`configuredDetector()` is `None`. No final preset, encounter-band achievement,
instrument reach, or First Contact slice seed is claimed.

The artifact is `calibration-development.json`: four seeds (0–3), four
provisional presets, and the two binding strategies (32 rows). All calculations
ran on released AILANG v0.56.0 (`e1ef997`), with an ignored local-package overlay:
celestial 0.6.0, worlds 0.1.0, published observe 0.1.0/relativity 0.12.0. The game
manifest and lock retain their published pins. Its caller-selected ideal
support is 10 ly and its Standard doom clock 16,000 yr. This support is an
arbitrary sampling fixture; it is not a telescope reach or a bound on real
encounter counts. `photon_budget=false` is explicit in the artifact.

| Provisional preset | life / minds / tech / lifetime offsets (dex) | effective luck (dex) | Cautious median: detected / visited / remnants / signals / contacts | Wanderer median in the same order | Detected and visited 10–90% range, both strategies |
|---|---|---|---|---|---|
| Lonely Universe (fixed baseline) | 0 / 0 / 0 / 0 | 0 | 1 / 1 / 0 / 0 / 0 | 1 / 1 / 0 / 0 / 0 | 0–2 |
| Scattered Few (uncalibrated candidate) | 0 / .75 / .75 / .25 | 1.75 | 1 / 1 / 0 / 0 / 0 | 1 / 1 / 0 / 0 / 0 | 0–2 |
| Stapledon's Voyage (uncalibrated candidate) | 0 / 1.25 / 1.25 / .25 | 2.5 | 0 / 0 / 0 / 0 / 0 | 0 / 0 / 0 / 0 / 0 | 0–2 |
| Teeming Galaxy (uncalibrated candidate) | .25 / 1.5 / 1.5 / .5 | 3.1992000846277815 | 2 / 2 / 0 / 0 / 0 | 2 / 2 / 0 / 0 / 0 | 1–4 |

Every remnant/signal/contact range is 0–0. Quantiles use the lower empirical
order statistic, documented by the generator. This tiny ideal fixture misses
the non-baseline encounter bands and does not establish the feasibility of a
photon-budget calibration. No offsets were written into the normative design
registry. The slice seed remains **none**; 0–3 are development samples only.

All 32 rows and their summaries are byte-identical between strict VM and
interpreter. Input SHA256:
`49b78ea2740fd1c2eab7c22106183514661c85e7140ff00c4750f3bc72d969e6`.
Artifact SHA256 (also in `DEVELOPMENT.SHA256`):
`39d4f6e82d736aa2ee5075cd14c91f4b6f4d20f8fe7cf018e397d795c0a77b44`.
The input digest binds model, tool, RNG, detection and preset sources; worlds'
science modules; celestial's Poisson implementation; and the runtime/package
version identities. It is computed before the run. No `show()` display is used
for composite equality or data hashing.

Targeted verification on the shared Studio:

```text
19 tests: 19 passed, 0 failed, 0 skipped (strict VM; 2.03 s)
bytecode: 19 named-test bodies ran on the VM, 0 fell back
19 tests: 19 passed, 0 failed, 0 skipped (interpreter; 89.07 s)
calibVm-development: 2 seeds strict VM = interpreter (byte-identical)
calib-smoke-development: 32 rows; photon_budget=false
sha256 238415dabbfeec89c61d4e0e7d0a27023a508af6797c79082b2aedfe58fee2e0
smoke wall 18.60 s; planned 60 s development ceiling passes
32-row strict-VM artifact wall 19.65 s
32-row interpreter artifact wall 380.18 s; frozen runner exits 0
```

Tests cover the retarded emission boundary; detected-only policy types;
arrival just before/exactly at a technological ending; Remnant as retained
biosphere, Ecocide as dead, Transcended as ecological status unknown;
Poisson intensities 1–10,000 over 128 seeds; marked-process counts against
closed-form disc intensity; 20,000 spatial samples against the radial CDF
and north/south symmetry; keyed local-cell replay; and stable interior worlds
when outer shells are appended. Quarter-dex search scoring requires both
binding strategies to satisfy all five accepted bands and retains conflicts.
A one-point ideal-fixture search reports all ten binding conflicts, not a
manufactured feasible solution. It is not a completed preset grid search.

The development smoke uses four seeds after the four-strategy 64-row budget
probe took 88.82 s. The 256-seed/all-four-strategy production matrix and its
30-minute budget remain unverified; linear scaling of the development probe
would exceed that budget. S2's real backend needs a fresh probe. Production
file pinning/every-sixteenth-row replay, Gentle/Hard clocks, a final grid search,
the attended preset ruling and the slice-seed search remain open.

`std/fs.readFile` remains evaluator-only on the strict VM. Minimal reproduction
and v0.56.0 evidence were sent upstream as
`inbox_1793647163478_e025808f`. The FS digest shell runs on the interpreter;
the separate IO-only emitter performs the complete Monte Carlo on the strict
VM. No numerical VM fallback or physics change was applied. There is no
`rig/full` or full-sprint acceptance claim in these targeted development checks.
