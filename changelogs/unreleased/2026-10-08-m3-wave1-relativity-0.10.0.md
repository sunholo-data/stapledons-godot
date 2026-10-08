### Added

- `sunholo/relativity` **0.10.0** (sprint R1-M3-BLACK-HOLES wave 1, M3.1a/b/p, ailang-packages #103), published under ledger D-53 after an independent evaluation (91/100 PASS), a clean `pkg quality` and a dry run. New module `geodesic`: the Binet RK4 integrator (`escapeAzimuth`, `lensDeflection`, `deflectionFromInfinity`), analytic capture (`escapes`), Darwin's exact form through Carlson R_F (`carlsonRF`, `deflectionExact`, `escapeAzimuthExact`, `deflectionExactAt`), the lens map (`lensRegular`, `imageAngle`, `einsteinAngle`, `imageMagnification`) and Fritsch–Carlson inverse rows (`inverseRow`). `schwarzschild` gains the closed forms for a visit: clocks and circular orbits, tides across the bubble and their inversions, hover acceleration and power.
- `tools/geodesic_ref.py` (role `oracle`): an independent Python integrator, Carlson R_F and a 50-digit Decimal truth that reproduces design rows V9–V16. `make geodesic-oracle` (in `make test`) runs its `--check`, holds its digests to the package's pinned `lensDigest`/`schwarzschildDigest` within 1e-9, and reruns the pinned package's `lensDigest 16` on the strict VM.

### Changed

- The sim pins `sunholo/relativity` 0.10.0 (M3.1c). The hello pin is split: minors 4 and 5 keep reporting "0.9.0" (`relativityPinNav`, frozen so every 2.4/2.5 stream stays byte-identical); `relativityPin()` is the current pin, which protocol 2.6 (M3.4b) will report. `make hello-pin` checks both.
