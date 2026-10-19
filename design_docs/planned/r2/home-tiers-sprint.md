# Sprint R2-HOME-TIERS: sixteen home-time tiers

**Design doc:** [home-tiers.md](home-tiers.md) (planned 2026-10-19)
**Sprint JSON:** `.ailang/state/sprints/sprint_home_tiers.json`
**Status:** **Awaiting Mark's approval.** Nothing is implemented. Branch `design/home-tiers` holds the doc and this plan. Execution runs on `feat/home-tiers` after approval.
**Scope:** H1 (the sim ladder and the protocol 2.12 gate), H2 (host), H3 (pictures), H4 (website), H5 (verify, evaluate, land).
**Base:** `origin/main` at `ddc1278` (2026-10-19).
**AILANG:** v0.54.14 (pinned; `make runtime`). AILANG prompt version loaded: v0.16.7.
**Protocol minor:** 2.12 (`homeTiersMinor()`). It is free on origin/main today. PR #272 (R2-SIMILAR-S0, parked on D-85) also plans 2.12; see OQ3. Re-check before H1 and before merge.

## What the survey found

- **The ladder is in one place.** `homeTier`, `tierLine`, `tierWord` and `crossingLine` are in `sim/cruise_digest.ail` (lines 110–121 and 322–343). `narrationFor` and `narrationOf` build the key `tierWord "." band`. Only `sim/protocol_interlude.ail` (`timeJson`, `homeJson`, `narrationJson`) calls them on the wire.
- **2.11's gate is one bool.** `withCruise` and `cruiseFull` in `sim/protocol.ail` pass `s.minor >= consoleMinor()` into `encodeCruiseSectionAt` and then `digestJsonAt(d, console)`. 2.12 adds a second bool the same way.
- **`crossing_hold` stays put.** `sim/crew_script.ail` records `tests/crew/crossing_hold.ndjson` through `encodeDigest`, which is the 2.10 encoding. If `encodeDigest` keeps the 7 tiers, that recording does not move.
- **No replay golden carries the digest.** `tier_line` appears only in `tests/crew/crossing_hold.ndjson` and `tests/fixtures/crossing_review/*.ndjson`; the fixtures are recorded at 2.10 by `tools/crossing_review_fixture.gd`.
- **The fixtures stop at tier 4.** `trappist.ndjson` reaches tier 4 (`lifetimes`), `acen.ndjson` tier 1 and `nocrew.ndjson` tier 1. Mark's ~150-year end of tour is not in them yet, so the re-recorded set must reach it (AC12).
- **The host trusts `time.tier` as a file index** (`ui/crossing_review.gd:435`). Renumbering the files needs a 7→16 map for frames below 2.12.
- **Sessions ask for `CONSOLE_MINOR` in three places:** `main.gd:286`, `demos/ship_geometry_demo.gd:772` and `ui/loading_jump.gd:254` (the prefetch; it must match the session minor).
- **Text tests already exist** in `sim/cruise_digest_test.ail`: `noDigit`, `outOfWorld`, `distinct`, the 280-character cap and the banned "claims". The 16-tier tests reuse them.
- **`ai/prompt_test.ail` uses `years.held`.** At 2.12 the scripted crossing (seven years) is tier 2, whose word is still `years`, so that test does not change.
- **Pictures.** Seven WebPs total about 3.8 MB. `SOURCES` gives the encoder line (`cwebp -q 88 -m 6 -sharp_yuv -metadata none`, libwebp 1.6.0) and master URLs under `gs://stapledons-voyage-assets/site/<sha>.png`. The website thumbnails are 800×533 JPGs.

## Plan shape

```
approval (OQ1 text, OQ3 minor) ─▶ H1 sim ladder + 2.12 ─▶ H2 host + fixtures ─┐
                                   Mark's picks (OQ2) ─▶ H3 pictures ──────────┼─▶ H4 website ─▶ H5 verify, evaluate, land
```

H1 and H2 need no pictures. Until H3, missing files fall back to words only (AC11). All of it ships as one PR (OQ5).

## Milestones

### H1: the 16-tier ladder in the sim, protocol 2.12 (~330 LOC, 1 day)
- **Red first:**
  - `sim/home_tiers_test.ail` (new) covers:
    - edges: for each of the 15 edges e, `homeTier16(e) == k` and `homeTier16(e - d) == k - 1` (d = 1e-6 below 1,000 years and 1e-3 above); also 0.0, a negative value and 1e9;
    - the approved strings word for word, as a table;
    - `noDigit` on every line, word and crossing line;
    - one `%s` per line, except tier 0 and tier 1's singular;
    - 16 distinct words, 16 distinct crossing lines, 80 distinct keys;
    - `inWorld`, ≤ 280 characters and no banned claims;
    - `pictureOfSeven == [0, 2, 4, 6, 8, 10, 13]`;
    - the per-range line pins (AC3).
  - `sim/protocol_interlude_test.ail` gains:
    - at sixteen = true, `time.tier`, `tier_count: 16`, `tier_line` and `narration.key` are 16-tier;
    - at console = true and sixteen = false, the encoding is byte-equal to today's `digestJsonAt(d, true)` output (captured before the change as a literal or a sha);
    - at both false, it is byte-equal to `encodeDigest`.
  - `sim/protocol_test.ail` gains: want 12 is answered 12, want 11 is answered 11, and the hello chain is in order.
- **Sim:**
  - `sim/home_tiers.ail`, pure: `tierCount`, `homeTier16`, `tierLine16`, `tierWord16`, `crossingLine16` and `pictureOfSeven`.
  - `cruise_digest.ail`: `homeTierAt`, `tierLineAt`, `narrationForAt` and `narrationOfAt`. The legacy functions are untouched.
  - Both modules are added to `[exports].modules`.
- **Protocol:**
  - `homeTiersMinor()` with its comment block, in `helloFor` and `sessionMinor`.
  - `withCruise` and `cruiseFull` pass `s.minor >= homeTiersMinor()`.
  - `encodeCruiseSectionAt` and `digestJsonAt` take `sixteen`.
  - The header comment of `protocol_interlude.ail` is updated.
- **Determinism:** the entry `homeTiersTable` and the `make home-tiers-vm` target (strict VM vs interpreter, `cmp`), added to `make test`.
- **Gate:** `make sim strict home-tiers-vm parity parity-v2 replay crew-parity` and `git diff --exit-code origin/main -- tests/replays tests/crew`.

### H2: the host reads 16 tiers (~170 LOC, 0.5 day)
- **Red first:** `tests/test_crossing_review.gd` gains:
  - `picture_index` with and without `tier_count`;
  - `PICTURE_OF_SEVEN` equals the sim's `pictureOfSeven`, read from a real-sim call;
  - a 7-tier frame (`legacy_2_10_trappist.ndjson`, today's file kept byte for byte) shows `tier<PICTURE_OF_SEVEN[t]>.webp`;
  - one-tier-missing fallback (a temp `home_dir` with tier8 absent): words only;
  - a real-sim hello at 12;
  - the loop over all 16 pictures, red until H3.
- **Host:**
  - `SimBridge.HOME_TIERS_MINOR = 12`.
  - The three session sites move from `CONSOLE_MINOR` to `HOME_TIERS_MINOR`.
  - `CrossingReview.TIER_COUNT`, `PICTURE_OF_SEVEN` and `picture_index`.
  - `_home` uses `picture_index`.
- **Tools:**
  - `tools/crossing_review_fixture.gd` records at `HOME_TIERS_MINOR`, and the recorded guided voyage reaches its last crossing (about 150 years).
  - `tools/crossing_review_capture.gd` loops over `TIER_COUNT`.
- **Re-record:** `make crossing-review-fixtures`. Review the diff: only the digest's tier, tier_line, tier_count and narration move. Commit it.
- **Gate:** `make crossing-review-test crew-bridge-test crew-console-test tour-pacing-test` (the existing targets that load the review; tour-pacing-test runs `tests/test_cruise_interlude.gd`), then `make display-audit-interlude`.

### H3: the pictures (~40 LOC + binaries, 0.5 day after the picks)
- **Waits on OQ2** (Mark's picks for N a to N i).
- **Renumber:** `git mv` from the top down (6→13, 5→10, 4→8, 3→6, 2→4, 1→2).
- **Each pick:**
  - check the master: 1536×1024, calm left third, no text-like marks at 1:1;
  - upload it with `gcloud storage cp` to `gs://stapledons-voyage-assets/site/<sha256>.png` (standing approval);
  - convert it with `cwebp -q 88 -m 6 -sharp_yuv -metadata none` (libwebp 1.6.0; record the version);
  - compare it with the master at 1:1.
- **Provenance:** `SOURCES` gets a 16-row table and an updated header. `generation_notes.md` renames the 7 sections ("was tierK") and adds 9 sections from the generating session's notes.
- **`make home-art-check`** (new, in `make test`): 16 rows, each file's sha256 equal to its row, each file 1536×1024 WebP, and no `.png` under `data/interlude/home/`.
- **Gate:** `make home-art-check crossing-review-test export-filter-audit`; the size total is ≤ 10 MB (AC14).

### H4: the website (~70 LOC, 0.25 day)
- **Thumbnails:** `tools/concept_thumbs.gd` (headless Godot: master PNG → 800 px wide, Lanczos, `save_jpg` 0.85). It renumbers the 7 existing thumbnails and adds 9.
- **`concept.js`:** `HOME_FULL` with 16 shas and `HOME` with 16 time-range titles. Subject to OQ4.
- **Gate:** `make site` (no broken links); `HOME.length === 16`; each thumbnail ≤ 1 MB; each master URL answers 200 (`curl -sfI`).

### H5: verify, evaluate, land (~30 LOC, 0.5 day)
- **Captures:** `make crossing-review-capture` in a GPU window. **Open every `art_tier0..15` frame and the guided crossings**, and list them in the report.
- **Suite:** `make display-audit-interlude`, then `PATH=$PWD/runtime/bin:$PATH make test` green.
- **Changelog:**
  - the fragment `changelogs/unreleased/2026-10-<dd>-home-tiers.md` (`### ` opening);
  - the protocol 2.12 line in `CHANGELOG.md`.
- **Evaluation:** the `sprint-evaluator` skill, run by a different agent or model. Output goes to `.ailang/state/evaluations/`.
- **Landing:**
  - move the doc to `design_docs/implemented/r2/`;
  - write `home-tiers-report.md`;
  - add the README index row;
  - update the design repo's roadmap row.

## Estimates and velocity

| Milestone | LOC (impl + tests) | Days | Depends |
|---|---|---|---|
| H1 | 330 | 1.0 | approval (OQ1, OQ3) |
| H2 | 170 | 0.5 | H1 |
| H3 | 40 | 0.5 | H2, picks (OQ2) |
| H4 | 70 | 0.25 | H3, OQ4 |
| H5 | 30 | 0.5 | all |
| **Total** | **640** | **2.75** | |

- **Velocity.** R2-INTERLUDE planned 1,800 LOC over 7 days and built I1–I4 in one day. R2-CREW-CONSOLE-V2 planned 1,750 LOC over 7 days and landed in two. Git stats are dominated by assets and recordings, so they give no usable LOC rate.
- **Assumption.** 300 LOC a day, plus buffer for the attended steps (text review, picks, render review). That gives 2.75 working days. The calendar time is set by Mark's picks, not by the code.

## Gates from CLAUDE.md, per milestone

| Gate | How this sprint meets it |
|---|---|
| 1 `make test` | Focused gates per milestone; the full `make test` once at H5 on the pinned runtime, then CI |
| 2 Physics | No SR or GR visual. Earth years come from an existing sim field |
| 3 Maths in package | No formulas: a lookup by thresholds, which belongs to the game, not to `sunholo/relativity` |
| 4 Pure core | `home_tiers.ail` is pure and strict-VM (`make strict`, `home-tiers-vm`). No I/O in the sim |
| 5 Precision | The thresholds compare the sim's float64 `sinceDeparture`, with no subtraction near an edge. The edge tests use offsets scaled to float spacing |
| 6 Determinism | No state. VM == interpreter byte for byte; every stream below 2.12 is byte-identical |
| Display contract | The tier line stays a bound field (`%s` ← `years_at_home`); `display-audit-interlude` adds no known entry |

## Protocol version handling

- **`homeTiersMinor()`:** the next free minor at execution, read from `sim/protocol.ail` and never a literal in tests (F4). It joins `helloFor` and `sessionMinor`. The bridge gets `HOME_TIERS_MINOR`.
- **At ≥ 2.12:**
  - `time.tier` is 0–15;
  - `time.tier_line` and `narration.{key, crossing}` come from the 16-tier tables;
  - `home.tier` is 16-tier;
  - `time.tier_count: 16` is new.
- **Below it:** the digest is byte-identical to today's at 2.10 and at 2.11, and `encodeDigest` (`crossing_hold`) is unchanged. `make parity-v2 replay crew-parity` runs at every gate. If a golden moves, stop (pause point 2).
- **Re-recorded:** `tests/fixtures/crossing_review/{acen,nocrew,trappist}.ndjson` at 2.12 (reviewed diff). **Kept:** `legacy_2_10_trappist.ndjson` (today's bytes), `tests/crew/*.ndjson`, `tests/crew/console_v2/*.json` (2.11) and every `tests/replays` golden.

## Registry reuse

| Milestone | Package | Decision |
|---|---|---|
| H1 | none: a game-specific lookup table and authored text | **none** |
| H2–H4 | none: Godot UI, assets, website | **none** |

## AILANG syntax gate (new or changed `.ail`)

| Module | Contracts | Effects | Inline tests |
|---|---|---|---|
| `sim/home_tiers.ail` | include: `homeTier16` ensures `result >= 0 && result < tierCount()`; `pictureOfSeven` requires `tier >= 0 && tier < 7` and ensures `result < tierCount()` | include: pure (no effect row) | include: `sim/home_tiers_test.ail` tables (edges, strings, distinctness) |
| `sim/cruise_digest.ail` (`homeTierAt`, `narrationOfAt`) | include: `homeTierAt(false, y) == homeTier(y)` as a test property over a sample of years | include: pure | include: cases in `cruise_digest_test.ail` |
| `sim/protocol_interlude.ail`, `sim/protocol.ail` | skip: a flag threaded through codecs, covered by byte-equality tests | include: pure | include: `protocol_interlude_test` byte-equality below 2.12; `protocol_test` hello |

## New make targets

- `home-tiers-vm`: the strict VM vs the interpreter on `homeTiersTable` (in `make test`).
- `home-art-check`: 16 `SOURCES` rows equal to their files' sha256, each 1536×1024 WebP, no PNG (in `make test`).
- **Extended:** `crossing-review-test` (16 pictures, legacy map, fallback, hello 12), `crossing-review-capture` (`art_tier0..15`), `crossing-review-fixtures` (records at 2.12).

## Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| Minor 12 taken by R2-SIMILAR-S0 first | Medium | Re-check at H1 and at merge; take 13. Only the constant, the bridge and the fixtures change |
| A golden below 2.12 moves | Low | The flag is threaded, the legacy functions are untouched; `parity-v2 replay crew-parity` at every gate |
| The re-recorded guided voyage does not reach ~150 years | Medium | The fixture tool records through the last leg; if it cannot, add a scripted crossing at about 150 years in `sim/home_tiers_test.ail` and say so in the report |
| Picks arrive late | Medium | H1 and H2 are independent of them; the fallback covers missing files; one PR (OQ5) |
| A new picture breaks continuity or has text-like marks | Medium | The shared style block and viewpoint; 1:1 inspection; Mark picks from a contact sheet |
| An AILANG VM bug in the new functions | Low | Report upstream with a repro; no downstream workaround (project rule) |

## Pause points

1. **Before H1:** Mark approves this plan, the text (OQ1) and the minor (OQ3).
2. **Any golden below 2.12 moving:** stop. Mark reviews the diff.
3. **Before H3:** Mark's picks (OQ2).
4. **H5 renders:** Mark opens `renders/crossing_review/art_tier0..15` and the guided crossings before merge (a visible feature, attended).

## Questions for Mark (from the design doc)

1. **OQ1:** the 16 tier lines, words and crossing lines. The ⚑ rows change meaning.
2. **OQ2:** picks for N a to N i.
3. **OQ3:** minor 12 against R2-SIMILAR-S0. Recommendation: first to merge takes 12.
4. **OQ4:** all 16 on the website. Recommendation: yes, time-range titles, no captions.
5. **OQ5:** one PR after the picks (recommended), or land H1–H2 first with words only.
