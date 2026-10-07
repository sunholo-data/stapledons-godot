# The full 100 pc sky and destinations: the large tier and a wider map

| Pillar | Alignment | Reason |
|---|---:|---|
| Choices Are Final | +1 | More real destinations to commit to. |
| The Game Doesn't Judge | 0 | The data is all measured; nothing is invented. |
| Time Has Emotional Weight | +1 | Destinations out to 326 ly mean round trips of centuries to millennia at home. |
| The Ship Is Home | 0 | No change. |
| Grounded Strangeness | +2 | Every star within 100 pc is real and parallax-correct in flight; at high γ, forward boosting reveals the faint M-dwarf majority. |
| We Are Not Built For This | 0 | No change. |

Net +4: aligned.

**Status:** Approved by Mark, attended 2026-10-07 (selected for dev.20: "benchmark first"). Proposed 2026-10-06 (Mark, attended). It depends on `starmap-single-truth.md`.
**Release:** R1 follow-up.
**Implements:** [starmap data model](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase1-data-models/starmap-data-model.md) and [galaxy map](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase2-core-views/galaxy-map.md). It is the measured core of the design repo's galaxy-beyond-measurement feature.
**Estimated scope:** about 600 LOC, plus data (the large tier is about 8 MB, fetched, not in git).

## Where we are (measured 2026-10-06)

| Layer | In use | Available in `data/raw` |
|---|---|---|
| Sky, nearby stars (GCNS, 100 pc) | 50,000 nearest (`stars_medium`) | 331,312 (`gcns.csv`); about 281,000 unused |
| Sky, bright distant stars (HIP, V < 7) | 10,713 (`stars_bright`) | rest of `hip_v7.tsv` |
| Destinations (CNS5, 25 pc, 81 ly) | 5,685 (`stars.json`) | GCNS to 100 pc (326 ly) |
| Beyond | destarred NOIRLab panorama (no parallax) | — |

The pipeline already supports `make catalogue TIER=large`, and `InteriorSky` and `main.gd` load `stars_large.bin` automatically when it exists.

## Goals

1. **L1. Large tier.** Build `stars_large` from all GCNS rows with complete photometry, with positions from the truth table. Publish it by sha256 to the public bucket, like the sky textures (`make starmap-assets`), so a fresh clone fetches it in seconds.
2. **L2. Performance budget.** At 2560×1440 the frame time with the large tier must stay within the current `make bench` budget. If it doesn't, cull per frame by apparent flux (stars far below the display floor are skipped on the GPU), never by distance, so the high-γ forward boost still reveals faint stars.
3. **L3. Destinations to 100 pc.** Extend `stars.json` with GCNS rows that pass quality cuts (ϖ/σ_ϖ ≥ 10, RUWE < 1.4, not a duplicate). That's an expected 100,000–300,000 destinations. The galaxy map needs level of detail: clustering, magnitude-limited labels, and search by name or id.
4. **L4. Evidence.** Before-and-after renders, opened and looked at, of:
   - the rest-frame sky (no visible change expected: the added stars are below the naked-eye limit);
   - the γ 707 forward view (more stars expected in the starbow);
   - a 50 ly journey (expected parallax shift of nearby faint stars).

## Non-goals

- Stars beyond 100 pc beyond the bright tier. The galaxy-beyond-measurement feature covers the synthetic remainder.
- Exoplanet systems (Sprint B's TRAPPIST-1 pipeline handles those one system at a time).

## Acceptance criteria

| # | Criterion | Command |
|---|---|---|
| AC1 | The large tier builds on the VM, matches the interpreter, and its sidecar records the truth sha | `make catalogue TIER=large` + `make catalogue-parity PARITY_TIER=large` |
| AC2 | The asset is fetched by sha256 from the public bucket | `make starmap-assets` |
| AC3 | Frame time is within budget at 2560×1440 with the large tier | `make bench BENCH_TIER=large` |
| AC4 | Destinations to 100 pc pass the quality cuts and the consistency gate | `make starmap` + `make starmap-consistency` |
| AC5 | The galaxy map stays interactive (≥ 60 fps pan and zoom) with the full destination set | `make bench-map` (new) |
| AC6 | L4 renders inspected | capture tool |
| AC7 | Gate 1 | `make test` |

## Risks

- **GPU cost of about 6× the instances.** Mitigation: flux culling in the vertex stage, measured first.
- **Map clutter.** Mitigation: level of detail and search; the default view shows named and bright stars.
- **Repository size.** Mitigation: fetch by sha256 (D-18 pattern), so tiers aren't stored in git.

## Open questions for Mark

1. Destinations to 100 pc now, or first only the sky (L1, L2) and leave L3 until the map's level of detail is designed? Default: sky first.
