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
