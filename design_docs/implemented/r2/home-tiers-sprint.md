# Sprint R2-HOME-TIERS: sixteen home-time tiers with variant pools

**Design doc:** [home-tiers.md](home-tiers.md)
**Sprint JSON:** `.ailang/state/sprints/sprint_home_tiers.json`
**Status:** **Done 2026-10-19** (H1-H5; independent evaluation 91/100 PASS, PR #277). **Approved 2026-10-19** by Mark (attended), with one change: no picks; each tier has a pool of variants, and the voyage seed picks one (D-86). The website shows tiers 0–12 only (canon: the doom). In execution on `design/home-tiers`, the same clone and branch as the plan. It ships as one PR.
**Base:** `origin/main` at `ddc1278` (2026-10-19).
**AILANG:** v0.54.14 (pinned; `make runtime`). AILANG prompt version loaded: v0.16.7.
**Protocol minor:** 2.12 (`homeTiersMinor()`). Whichever PR merges first takes 12 (OQ3), so re-check before merge.

## What the survey found

- **The ladder is in one place.** `homeTier`, `tierLine`, `tierWord` and `crossingLine` are in `sim/cruise_digest.ail`. Only `sim/protocol_interlude.ail` (`timeJson`, `homeJson`, `narrationJson`) puts them on the wire.
- **2.11's gate is one bool.** `withCruise` and `cruiseFull` in `sim/protocol.ail` pass `s.minor >= consoleMinor()` into `encodeCruiseSectionAt`, which passes it on to `digestJsonAt(d, console)`. 2.12 adds a second bool and the world seed.
- **`crossing_hold` stays put.** `sim/crew_script.ail` records through `encodeDigest`, the 2.10 encoding, and that stays 7-tier.
- **No replay golden carries the digest.** Only `tests/crew/crossing_hold.ndjson` and `tests/fixtures/crossing_review/*.ndjson` do.
- **The seed.** `World.seed` is the voyage seed. `ism.ail dustKey` shows the salted-key pattern, which draws nothing from `Rng`.
- **The host trusts `time.tier` as a file index** (`ui/crossing_review.gd`). Older streams need the 7→16 map and variant 0.
- **The pool.** All 21 added variants were inspected at 1:1, in quadrants, with 3× zooms on the plain memorial stones in `tier_d`. None has text, letters or glyph-like marks, so none is dropped. The pool is 28 pictures; the design doc's H3 table gives the per-tier counts.

## Milestones

### H1: the ladder, the variants and protocol 2.12 (~380 LOC) ✅ done 2026-10-19
- **Red first:**
  - `sim/home_tiers_test.ail`:
    - the edges and the strings;
    - the distinctness and voice rules;
    - `pictureOfSeven`;
    - the line pins;
    - `homeVariant`: stable, within `[0, count)`, 0 on single-variant tiers, and covering every variant across 64 seeds.
  - `sim/protocol_interlude_test.ail`: the 2.12 fields (`tier`, `tier_count`, `variant`, `tier_line`, `narration`), and byte-equality below 2.12.
  - `sim/protocol_test.ail`: the hello at 12.
- **Sim:**
  - `sim/home_tiers.ail`: the ladder, the text and `homeVariant`.
  - `sim/data/home_variants.ail`: the counts.
  - `sim/cruise_digest.ail`: `homeTierAt`, `tierLineAt`, `narrationForAt`, `narrationOfAt`.
  - Protocol: `homeTiersMinor`, the chain, and the `sixteen` and `seed` threading.
- **Gate:** `make sim strict home-tiers-vm parity parity-v2 replay crew-parity`, then `git diff --exit-code origin/main -- tests/replays tests/crew`.

### H2: the host (~200 LOC) ✅ done 2026-10-19
- **Red first:** `tests/test_crossing_review.gd` covers:
  - `picture_index` and `picture_variant`;
  - `PICTURE_OF_SEVEN` against the sim's;
  - a legacy 2.10 frame shows v0 of the mapped tier;
  - a missing variant falls back to v0, and a missing tier gives words only;
  - a real-sim hello at 12.
- **Host:**
  - `HOME_TIERS_MINOR`, used at the three session sites.
  - In `CrossingReview`: `TIER_COUNT`, `PICTURE_OF_SEVEN`, `picture_index`, `picture_variant`, `home_path(dir, tier, variant)` and `home_texture_for`.
- **Tools:**
  - The fixture tool records at 2.12.
  - Keep today's `trappist.ndjson` as `legacy_2_10_trappist.ndjson`.
  - The capture loops over every variant, plus the guided tour's last crossing (tier 7) and a deep-tier fixture.
- **Re-record:** `make crossing-review-fixtures` (reviewed diff).
- **Gate:** `make crossing-review-test crew-bridge-test crew-console-test tour-pacing-test display-audit-interlude`.

### H3: the pictures (~60 LOC + binaries) ✅ done 2026-10-19
- **Renumber:** `git mv` each shipped file to `tier<new>_v0.webp`.
- **The 21 new variants**, each:
  - upload the master with `tools/site_media.sh asset`;
  - convert with `cwebp -q 88 -m 6 -sharp_yuv -metadata none`;
  - compare at 1:1.
- **Provenance:** `SOURCES` gets 28 rows. `generation_notes.md` renames the old sections and adds the 2026-10-19 session.
- **`make home-art-check`** (in `make test`):
  - the counts match the files;
  - each sha matches its row;
  - every file is a 1536×1024 WebP;
  - there is no PNG in the tree.
- **Gate:** `make home-art-check crossing-review-test export-filter-audit`. The WebPs total ≤ 20 MB.

### H4: the website (~80 LOC) ✅ done 2026-10-19
- `tools/concept_thumbs.gd` builds the 800 px thumbnails for the 23 variants of tiers 0–12.
- `concept.js` `HOME` lists tiers 0–12 only, titled by time range. The public tier-6 thumbnail (now tier 13) comes down.
- **`make home-site-check`** (in `make test`):
  - no tier ≥ 13 in `HOME`;
  - every thumbnail exists and is ≤ 1 MB;
  - the entries are exactly the `SOURCES` masters of tiers 0–12.
- **Gate:** `make home-site-check site`, plus `curl -sfI` on each master URL.

### H5: rig gates and PR ✅ done 2026-10-19
- Full `PATH=$PWD/runtime/bin:$PATH make test` on the rig. `make golden` is skipped because nothing in the 3D render changes.
- `make crossing-review-capture`. Open the guided tour's last crossing (tier 7), a deep-tier frame and every variant frame.
- A changelog fragment and the protocol 2.12 line.
- A PR, not a draft. Don't merge: a different model evaluates first.

## Estimates

| Milestone | LOC | Days |
|---|---|---|
| H1 | 380 | 1.0 |
| H2 | 200 | 0.5 |
| H3 | 60 | 0.5 |
| H4 | 80 | 0.25 |
| H5 | 0 | 0.5 |
| **Total** | **720** | **2.75** |

## Gates from CLAUDE.md

| Gate | How |
|---|---|
| 1 `make test` | Focused gates per milestone; the full suite on the rig at H5 |
| 2 Physics | No SR or GR visual |
| 3 Maths in package | No formulas; the threshold table and the hash are game data and logic |
| 4 Pure core | `home_tiers.ail` and `home_variants.ail` are pure and strict-VM (`make strict`, `home-tiers-vm`) |
| 5 Precision | float64 years; the edge tests are scaled to float spacing |
| 6 Determinism | The variant is a pure function of `(seed, tier)`; no `Rng` draw; VM == interpreter |

## Registry reuse

| Milestone | Package | Decision |
|---|---|---|
| H1–H4 | none (game data, UI, assets, website) | **none** |

## AILANG syntax gate

| Module | Contracts | Effects | Inline tests |
|---|---|---|---|
| `sim/home_tiers.ail` | include: `homeTier16` and `homeVariant` ensure their result is in range | pure | `sim/home_tiers_test.ail` |
| `sim/data/home_variants.ail` | skip: data | pure | covered by `home_tiers_test` and `home-art-check` |
| `sim/cruise_digest.ail`, `sim/protocol*.ail` | skip: a threaded flag, covered by byte-equality tests | pure | `protocol_interlude_test`, `protocol_test` |

## Pause points

1. A golden below 2.12 moves: stop and report.
2. A variant fails the 1:1 check: drop it, list it, and continue.
3. Merge: never by this sprint. The coordinator runs the independent evaluation first.
