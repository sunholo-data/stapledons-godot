# Sprint R1-STARMAP-LARGE: the full 100 pc sky (large tier)

**Design doc:** [starmap-large-tier-and-reach.md](starmap-large-tier-and-reach.md). It depends on [starmap-single-truth.md](starmap-single-truth.md) (sprint R1-STARMAP-TRUTH).
**Status:** Approved by Mark, attended 2026-10-07 (selected for dev.20: "benchmark first").
**Estimate:** about 350 LOC plus data, 1.5 days. Branch `sprint/starmap-large-tier`, based on `sprint/starmap-single-truth`.
**Risk:** low to medium. The pipeline, the loader and `main.gd` already handle `stars_large`; the open questions are frame time on Mark's M2 Air and load time.

## Scope decision (design open question 1)

The default applies: **sky first** (L1, L2, L4). L3, destinations to 100 pc (100,000 to 300,000 map stars), waits until the galaxy map's level of detail is designed. That would be the design's own AC5 (`make bench-map`), and it is not in this sprint. `stars.json` stays at 25 pc.

## Milestones

| ID | Work | LOC | Acceptance (design AC) |
|---|---|---|---|
| LT0 | **Benchmark gate, first.** Build `stars_large` locally with truth positions. `make bench` at 1920×1080 and 2560×1440 on the Studio, medium vs large: frame p50/p99, star-pass GPU ms, `load_tiers` wall time, process RSS. Estimate the M2 Air by scaling the measured star-pass cost (instances × fill) against the GPU ratio. **Stop and report with numbers if it does not fit the budget**: p99 within the current `make bench` budget, and an M2 Air estimate under 16.7 ms. | 60 | AC3 |
| LT1 | Large tier from truth: `make catalogue TIER=large` (sidecar `truth_sha256`), `make catalogue-parity PARITY_TIER=large`. Add a bench resolution option (`BENCH_SIZE`) so 1920×1080 is measured reproducibly. | 40 | AC1 |
| LT2 | D-18 for tiers: `data/starmap/SHA256SUMS` pins `stars_large.bin` and `.json`; `make starmap-assets` fetches them from `gs://stapledons-voyage-assets/starmap/` by sha256 (or rebuilds from the pinned inputs); `make starmap-publish` (maintainers) uploads them. | 120 | AC2 |
| LT3 | Consistency on large: `make starmap-consistency TIER=large` (the truth gate holds on the large stack too); `catalogue-stats` covers large when present. | 40 | AC4 (sky part) |
| LT4 | Renders before and after (rest frame, γ 707 forward, a 50 ly journey), opened; `make test`; CHANGELOG; sprint JSON; PR. | 90 | AC6, AC7 |

## Acceptance by command

| AC | Command | Pass |
|---|---|---|
| AC1 | `make catalogue TIER=large AILANG=runtime/bin/ailang` + `make catalogue-parity PARITY_TIER=large AILANG=runtime/bin/ailang` | built on the VM; VM = interpreter; sidecar has `truth_sha256` |
| AC2 | `rm data/starmap/stars_large.*; make starmap-assets` | fetched and verified by sha256 in seconds |
| AC3 | `make bench TIER=large` (and `BENCH_SIZE=1920x1080`) | within the budget; numbers in the sprint JSON |
| AC4 | `make starmap-consistency TIER=large` | pass |
| AC6 | `make capture`-style renders | opened, described |
| AC7 | `make test AILANG=runtime/bin/ailang` | green |

## Deferred, with reasons

- **L3 destinations to 100 pc and `make bench-map`.** The design's default says sky first, and the map needs a level-of-detail design before it can hold 10⁵ stars.
- **Flux culling in the vertex stage.** Built only if LT0 shows the frame budget is missed. The faint-star cull (`CULL_PEAK`) already skips sub-threshold splats in the fragment stage.

## LT0 result: viable (measured 2026-10-07, before building anything else)

The Mac Studio has an M4 Max with a 40-core GPU. The runs used `make bench TIER=… BENCH_SIZE=…` with vsync off: a 30 s scripted flight to 0.99c with the camera sweeping, background on, Metal then Vulkan. Host load was 3 to 7 (other tracks' AILANG builds). The star pass is the Vulkan GPU time of each frame minus the replayed frame without stars.

| Stack | Size | Stars drawn | Frame p50 / p99 ms (Metal) | Viewport GPU p50 / p99 ms | Star pass GPU p50 / p90 / p99 ms | `load_tiers` | Static / video memory |
|---|---|---:|---|---|---|---|---|
| medium | 1920×1080 | 60,883 | 8.31 / 10.07 | 0.46 / 0.76 | 0.08 / 0.15 / 0.35 | 107 ms | 97 / 935 MB |
| large | 1920×1080 | 335,189 | 8.43 / 10.99 | 0.72 / 1.14 | 0.34 / 0.55 / 0.76 | 659 ms | 248 / 1,052 MB |
| medium | 2560×1440 | 60,883 | 8.43 / 11.23 | 0.67 / 1.13 | 0.10 / 0.18 / 0.56 | 115 ms | 97 / 1,014 MB |
| large | 2560×1440 | 335,189 | 8.43 / 11.48 | 0.93 / 1.61 | 0.35 / 0.55 / 0.99 | 623 ms | 248 / 1,132 MB |

- **Frame time does not change.** p50 is pinned at the present floor (8.4 ms). p99 stays within the 16.7 ms budget at both sizes, and 2 to 9 frames out of 3,550 exceed it, the same for both tiers.
- **The star pass grows by +0.25 ms (p50) and +0.4 ms (p99)** for 5.5× the instances. That is 0.35 ms at p50 against the 2 ms star-pass target. The fragment cost does not depend on resolution here, which points at vertex and instance cost rather than fill.
- **Loading costs +0.5 s once**, in `load_tiers` (GDScript, 335k rows, the identity index and the float64 restore). Memory rises by +150 MB on the CPU and +100 MB on the GPU, of which +16 MB is the instance buffer.
- **M2 MacBook Air estimate** (8 to 10 GPU cores, about 2.9 to 3.6 TFLOPS and 100 GB/s, against the M4 Max's about 16 TFLOPS and 546 GB/s; scale ×5 to ×6): the large star pass is about 1.7 to 2.1 ms p50 and 4 to 6 ms p99, which is +1.4 ms p50 over medium. That fits a 16.7 ms frame, with the ship and the rest of the scene budgeted separately. Loading takes about 1 s (single-core ×1.5), and the extra 250 MB fits in 8 GB. This is an estimate; confirm it on the Air with `make bench TIER=large BENCH_SIZE=1470x956`.
- **No vertex flux cull is needed** (design L2's fallback).
