# Telescope implementation evidence

Status: implementation and review in progress, 2026-11-12. This is not visual acceptance or a landing record. [Design](telescope-survey-inspection.md), [sprint](telescope-survey-inspection-sprint.md), [progress](../../../.ailang/state/sprints/sprint_R3-TELESCOPE.json).

## Real observations

The starter archive has four plates covering the three approved fields. One is a registered 724×724 VIS science cutout of Abell 3128, with 40 real source records from `dr1.mer_catalogue_wide_survey`. The other three are explicitly unregistered colour outreach images of M81, NGC 1291 and Abell 3128. No redshift-to-distance conversion or addition to the navigable local-star catalogue is made.

Five distributed measured centroids on the actual FITS image have maximum registration residual 0.368168 source pixel. Independent analytical TAN coordinates also exercise the centre, corners, RA wrap and poles. Original CSV, WCS, query, source hashes, dates, quality flags and rights remain in `data/observations/euclid_dr1/`. A blended sixth anchor was rejected rather than counted as passing. This is an independent scalar/centroid oracle, not a claim of validation by Astropy or wcslib.

The offline source decoder accepts only bounded, uncompressed primary float32 FITS images. It is a build tool, with no runtime FITS dependency. Prepared PNGs use a declared log stretch; colour outreach products remain separate from science registration.

## Focused evidence

| Check | Recorded result |
|---|---|
| Celestial 0.7.0 package | 174 native tests; strict VM/interpreter probe identical; independent scalar oracle max pixel error 6.86e-10 |
| Godot projection mirror | 65/0 |
| Source import | 16/0; real 40-row generated JSON and strict pure probe byte-identical between engines |
| Exact-ID index | 18/0 |
| Registered footprint | Native 10/0; real and strict pure parity; map 26/0 including draw callback and independent WCS corners |
| Tile cache | 36/0, including corruption, gutters/seams, cancellation/version change, budgets and `.bin` fallback |
| Shared facts | 32/0; explicit provenance and unavailable values |
| Telescope UI | 22/0 including real keyboard/pinch/pan dispatch, exact source/image association, invariant archive metadata and session pinning |
| Live targeting | 7/0; explicit missing/hidden target never falls back |
| Journey boundary | Planned and committed real-sim journeys: no observation decision intents, target retained, clocks advance |
| Chair integration | Actual projected Telescope click; Esc/pad Back and screen-switch cache/viewport lifecycle; one panel/callback |
| Physics regression | 1080/0 after importing main's new classes |
| Finder regression | Existing ship-star-identification 60/0; existing chair geometry 101/0 |
| Export filter audit | 142 runtime path literals, 0 failures (before final main refresh; rerun before review) |
| Offline PCK | Minimal actual PCK opens all 176 production tiles from `.png.bin`; raw manifest/index/tile paths absent. Missing bundled manifest negative control fails. 2/0 |

The PCK probe verifies the observation bundle/cache independently. It does **not** substitute for a complete macOS app or live-renderer export test.

## Performance and size

The four-plate tile pack is 60,356,380 bytes, below 100 MiB. The cache stores RGBA8 images and non-mipped textures with 64 MiB CPU and 128 MiB texture-payload caps. Texture counts are payload estimates, not measurements of driver VRAM overhead.

The headless benchmark exercises 32 real-pack zoom/pan states and 1,024 individual warmed calls. On revision `42230383`, added warmed CPU p95 was 0.134 ms; closed p95 0.001 ms; peak resident CPU and texture payload were each 15,303,488 bytes. Closing leaves zero cache bytes and zero extra decodes. At most one tile decodes per pump. Cold setup was 640.641 ms and cold tile-batch p95 360.397 ms under load, reported separately rather than hidden in warmed timing. These are CPU timings, not GPU frame-time claims.

The Studio health snapshot showed GPU 75%, CPU 70.1%, with an active Ollama job. New GPU cases and captures were prepared but not run while it was occupied, following CLAUDE.md. `make telescope-capture` covers 960×540, 1280×720 and 2560×1440, actual ship/Navigation/chair/popup contexts, Aldebaran whole/close, registered picking, survey context, credits, missing imagery and resolution limits. `make telescope-golden` adds archive SR/GR byte invariance and live physical-uniform/centroid checks. All rendered output still needs to be generated, opened and accepted.

## Remaining review gates

- Resolve the final dependency lock against current main, preserving its new worlds propagation API through a dependency-only patch.
- Final focused regressions and GitHub fast tier on the review head.
- Independent cross-family evaluation under `sprint-evaluator`.
- Complete combined macOS review build, opened rendered evidence and Mark's visual verdict.
- Only after those gates: land, move design/sprint to implemented, and update the canon/roadmap. The sprint remains in progress until then.
