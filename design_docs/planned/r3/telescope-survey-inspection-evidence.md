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
| Source import | 21/0; real 40-row generated JSON and strict pure probe byte-identical between engines |
| Exact-ID index | 23/0; content pin/snapshot/mutation suite 27/0 |
| Reproducible independent oracle | 51 cases / 246 checks; actual pinned FITS/CSV, both TAN directions, Galactic defining angles, five remeasured anchors; full-gate half-pixel fault fails |
| Registered footprint | Native 10/0; real and strict pure parity; map 26/0 including draw callback and independent WCS corners |
| Tile cache | 36/0, including corruption, gutters/seams, cancellation/version change, budgets and `.bin` fallback |
| Shared facts | 33/0; explicit per-fact methods/epochs and unavailable values |
| Telescope UI | 32/0 including real keyboard/pinch/pan dispatch, rendered pixel-centre picking at high zoom, invariant archive metadata, session pinning, live viewport fit, sources/licence disclosure and scroll reset |
| Live targeting | 10/0; explicit missing/hidden target never falls back; native field crops labelled honestly |
| Journey boundary | 49/0. Planned and committed real-sim journeys: no observation decision intents, target retained, clocks advance; observation owns focus and hides underlying route controls; missing identities clear stale inspection markers |
| First information entry | 48/0. Actual recorded NDJSON with default consent crew: all read-only heartbeats empty; first later helm entry sends deferred critical-only orders exactly once; explicit selection alone sends a plan; Captain position preserved |
| Chair integration | 54/0: actual projected Telescope click; Esc/pad Back and screen-switch cache/viewport lifecycle; one panel/callback |
| Physics regression | 1080/0 after importing main's new classes |
| Finder regression | Existing ship-star-identification 60/0; existing chair geometry 101/0 |
| Export filter audit | 143 runtime path literals, 0 failures |
| Offline PCK | Minimal actual PCK opens all 176 production tiles from `.png.bin`; raw manifest/index/tile paths absent. Missing bundled manifest negative control fails. 2/0 |

The PCK probe verifies the observation bundle/cache independently. It does **not** substitute for a complete macOS app or live-renderer export test.

## Performance and size

The four-plate bundle is 60,515,006 bytes (182 files, 176 tiles), below 100 MiB. The cache stores RGBA8 images and non-mipped textures with 64 MiB CPU and 128 MiB texture-payload caps. Texture counts are payload estimates, not measurements of driver VRAM overhead.

The final headless benchmark exercises 32 real-pack zoom/pan states and 1,024 individual warmed calls, including the panel's actual process/status work. Warmed CPU p95 was 0.216 ms; closed p95 0.001 ms; peak resident CPU and texture payload were each 15,303,488 bytes. Closing leaves zero cache bytes and zero extra decodes. At most one tile decodes per pump. Cold setup was 110.290 ms and cold tile-batch p95 42.966 ms, reported separately rather than hidden in warmed timing. Earlier loaded-host samples were substantially slower (360.397 ms cold batch p95). These are CPU timings, not GPU frame-time claims.

The initial Studio health snapshot showed GPU 75%, CPU 70.1%, with an active Ollama job; GPU work was deferred. Once it became free, the focused capture rendered 40 frames at 960×540, 1280×720 and 2560×1440: actual ship/Navigation/chair/popup contexts, live Sun and Aldebaran, registered picking, survey context, credits, missing imagery and resolution limits. All five archive SR/GR image comparisons passed. The actual unclipped Sun viewport has a black rim and 0.000581-pixel CPU/GPU centroid error; 39 physical uniforms match. Eight independent image-mask controls reject blank, all-lit, edge-clipped and displaced cases. Aldebaran at the actual close stop exceeds the fixed 14° field, so its centroid is deliberately not assessed and the panel labels the native crop. No demagnification or exposure-model change was introduced.

Visual review opened all 40 initial frames and caught panel clipping, stale scroll position and arrival-presentation timing. These are corrected; the final stable-source rerender and complete dev-build review remain pending. Raw oracle viewport validation alone is explicitly insufficient to claim that the composed UI fits.

The public immutable observation cache has 193 hash-addressed objects; 12 anonymous downloads verified source/image/index/tile and provenance bytes. Publisher negative controls pass 28/0. No latest alias is overwritten.

## Remaining review gates

- Current main `0154b7c2` is integrated. The final lock uses celestial 0.7.0 and worlds 0.2.1; the latter's 19 AILANG files and 78 interfaces are identical to main's worlds 0.2.0, with 65 native tests passing.
- Final stable-source rendered evidence and GitHub fast tier on the review head (earlier checkpoints `04cdd5e6` and `dc15f91e` passed).
- Independent cross-family evaluation under `sprint-evaluator`: round 1 scored 62; round 2 scored 75 with a required deferred-crew-orders fix. That fix has red/green evidence (47/1 → 48/0); final re-review remains pending.
- Complete combined macOS review build, opened rendered evidence and Mark's visual verdict.
- Only after those gates: land, move design/sprint to implemented, and update the canon/roadmap. The sprint remains in progress until then.
