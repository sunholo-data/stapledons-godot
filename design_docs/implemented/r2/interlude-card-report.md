# R2-INTERLUDE: report

**Status:** I1–I4 built (2026-10-16/17); I3b blocked upstream (crew_core E4). Independent evaluation:
**PASS 89/100** (a different agent and model; `.ailang/state/evaluations/R2-INTERLUDE-eval.md`), and its
defects fixed before merge (below). PR #264. Design: [interlude-card.md](interlude-card.md). Plan:
[interlude-card-sprint.md](interlude-card-sprint.md). Progress: `.ailang/state/sprints/sprint_R2-INTERLUDE.json`.

## What it delivers

The 6-second interlude card is gone. A long cruise is crossed in chunks the sim publishes (protocol
**2.10** `cruise {next_stop_years, stop_kind}`, exact to the crew day), a crew hold stops the crossing on
its own check-in day, and the crossing ends in a review the player reads at their own pace: the
crossing, home (a picture per home tier), aboard, up to seven moments with the speaker's face at the
sim's emotion, who changed, the medium, and who is waiting. Every number is a binding over the pure
sim's cruise digest. The Archive frames pages 1 and 3 with authored lines, and with live AI and a key
tells the crossing in its own words, recorded as sim input and voiced once.

## Toolchain

| | |
|---|---|
| AILANG | v0.54.11 (pinned) |
| `sunholo/crew_core` | 0.5.0 |
| Godot | 4.7.2-stable |
| Machine | Mac Studio, Apple M4 Max (darwin arm64) |

## Acceptance criteria

| # | Check | Result |
|---|---|---|
| AC1 | `cruise_digest_test` (hand-computed counts, movement, moments ≤ 7, tier edges) | pass |
| AC2 | `make strict` (`digestScripted`) | pass |
| AC3/AC4 | `make crew-parity` `crossing_hold` (VM == interpreter, repeat run identical), `make parity` | pass |
| AC5 | `make crew-hold-test`: holds stop the crossing on days 31, 61 …; ship time waits; Resume reaches the boundary within 1e-12 of plan | pass |
| AC6 | `make crew-perf`: slowest chunk 0.112 s, critical_only decade 0.89 s | pass |
| AC7 | `make no-twitch-test` NT4 (600 s on every page; an auto-dismiss mutant fails by assertion) | pass |
| AC8 | `make display-audit-interlude`: 129 samples, new findings 0 | pass |
| AC9/AC10 | `make crossing-review-test` (crew text, scored words, faces per emotion) | pass |
| AC11 | `make crossing-review-capture`: 62 frames at 1280×720 and 2560×1440, opened | pass |
| AC12 | `make -k test` locally (exit 0); CI on #264 | pass locally |

## Decisions and deviations

- Protocol **2.10** (`interludeMinor = 10`); replay goldens below 2.10 never moved. 2.10 data
  re-recorded: `tests/crew/crossing_hold.ndjson`, `tests/fixtures/crossing_review/*`.
- **Days:** "You lived N days" and "Your crew lived N days" are one function (`cruise_digest.shipDays`):
  the crew's day clock with a crew aboard, whole days of proper time without.
- **Home art** (ruling 2): seven pictures as lossy WebP (q88, native 1536×1024, ~3.8 MB); the PNG
  masters stay in the public bucket (D-18). The Home page shows the picture as a 3:2 cover with the
  words over its calm left side.
- **I4:** the "recorded `ai_result`" is the existing `record` → `ai_accepted` path. One telling per
  crossing, replacing page 1's authored line; page 3 keeps its authored line. Without a key no service
  starts (D-8), so the authored lines stand silent; the stub voice plays under the stub service only.
- **News copy:** `{elapsed_years}` is when a message left home, not time passed since; six templates
  were reworded (a lint rule enforces it), and a tier-0 message that rounds to zero says "within days
  of your departure".
- **Look around while waiting** (dev.31): the arrival and medium cards no longer take the pointer;
  right-drag or Alt/Option+move looks while the review needs it; one centred line says what to press.

## Evaluation fixes (round 1, 89/100)

1. Two news ages on the Home page told apart ("News reaching the ship now left home …"; "The last word
   received, at your last stop"), and "within days of your departure" for a zero written-after age.
2. Narration lines claim only what their key guarantees: the tier is Earth time since departure, so no
   line pins it on this crossing or states this crossing's ship time (tier 3 said "in weeks"; Aldebaran
   is 248 ship days); "restless" may be concerns alone; "held" may be one hold. Tested.
3. A hold with no digest yet shows the Hold page and its confirmed Resume. Tested.
4. The export witness for `data/interlude` is the WebP art.
5. A full state carries the cruise section like a tick (`protocol.cruiseFull`; new_game's full state is
   never committed, so nothing changes there). Tested at 2.10 and below.
6. NT4 fails the auto-dismiss mutant by assertion (pages taken once), not by a script error.

## Open notes

- **D-80:** the analyst's portrait does not fit the generated name; fixed in the console sprint.
- **Relief never comes up in the guided voyage** until crew_core 0.6 is pinned (0.5.0's auto-captain
  checks in only on even turns; every monthly decision turn is odd). Unit tests cover relief counting.
- **Tier 3's bench figure** sits half under the left scrim (visible, dimmed).
- The HUD card column clips at the bottom on small windows: it predates this PR (follow-up).
- The camera redesign (fixed zoom, third person) will supersede free look and the right-drag look.
- I3b (crew_core E4 skip report) is blocked upstream.
- AILANG: a `{` in a string inside a multi-line `test` body fails to parse on v0.54.11
  (PAR_NO_PREFIX_PARSE); fixed in v0.54.13 (consistent with ailang#1821).
