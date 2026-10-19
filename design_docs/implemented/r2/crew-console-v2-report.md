# R2-CREW-CONSOLE-V2 report

**Sprint:** R2-CREW-CONSOLE-V2, the Crew console as an internal videocom. Design: [crew-console-v2.md](crew-console-v2.md). Plan: [crew-console-v2-sprint.md](crew-console-v2-sprint.md). PR #267.
**Dates:** approved 2026-10-16, built 2026-10-16 to 2026-10-17.
**Evaluation:** 86/100 PASS (independent evaluator; `.ailang/state/evaluations/R2-CREW-CONSOLE-V2-eval.md`), then its fixes (below).

## Mark's reviews (attended)

- 2026-10-16, the plan: "yes continue" (all nine recommendations).
- 2026-10-17, the V3 renders: "yeah they look good - I think the UI is still a bit text heavy so we can have more visual UI but its a big improvement". This became milestone V7b.
- 2026-10-17, the visual pass: "crew console is looking great".

## What was built

| Milestone | What |
|---|---|
| V1 | Protocol 2.11: the sim names each member's `work_state` (the page derives nothing, D-20); working work carries its start `terms`; `crew_start {as}` (one start under the other captaincy, all or nothing); `crew_offer {start: on_accept \| now}` |
| V2 | One palette (Okabe-Ito based) with a drawn icon and a word per state; contrast and colour-blind separation proven in a test (Machado 2009, CIEDE2000) |
| V3 | The roster board and the two-panel call (a 240-logical portrait at the sim's emotion, their words; the work and the decisions); every Label a display binding (`make display-audit-crew`) |
| V4–V5 | A reply to a concern is reconsidered at once and the work starts when they agree (`crew_reply {start}`); Start disabled with its reason; Insist as the fourth answer; Make it an order; lapse notes |
| V6 | Keyboard and pad: the console's own focus ring; Enter/A arms, the same press sends; 1–4 answers; [ ] and LB/RB switch the call; O/Y Ask or Order; Esc/B one level back |
| V7b | Less text: terms as day pips and resource icons with count pips, rule lines in one line behind "?", answer icons, faces for who is waiting, icon bars, the legend and an icon key behind "?" |
| V8 | crew_core 0.6.0 pinned (stand-downs): `stand_down_asked` and `resting`, `crew_stand_down`, the digest's stand-down counts (2.11); crew days wait while a stand-down is unanswered |
| D-80 | Names fit faces: each portrait records its presentation and naming regions (`sim/data/crew_faces.ail`, `data/crew/portraits/SOURCES`, `make crew-faces-check`); from 2.11 the names are drawn within them |

## Measurements

- **Visible words per state at 1280×720**, V3 → V7b: board 101 → 87, offer 113 → 69, sending 107 → 55, concern 143 → 101, working 95 → 38, hold 120 → 89; total 679 → 439 (−35%).
- **Captures:** `make crew-console-capture`, ten states at 1280×720 and 2560×1440, no label under 12 logical, nothing outside the panel, the call portrait 240 logical (2.5× its 256 px source at 1440p, OQ7).
- **crew-perf:** the chunked critical_only decade takes about 3.1 s under crew_core 0.6 (39 monthly chunks instead of 20 cap-sized ones; slowest chunk 0.13 s). It has its own 4.0 s total budget; the per-chunk ceiling is unchanged.

## Evaluation fixes (86/100, round 1)

- **D1 (medium), the stand-down call focused Resume.** The model listed Resume first, so the default focus and a confirmed press resumed auto-run before the captain answered; the stand-down lapsed, which crew_core counts as refusing the rest. Now the two answers lead (the focus is on "Let them rest"), and Resume is unavailable until the stand-down is answered, with its reason as a visible line and a tooltip. Chosen over a reworded confirm because a lapse is an answer the captain did not give: "Ask them to carry on" is the explicit, confirmed way to refuse, and it stays one press away. Tests: the first focus is a stand-down answer; neither presses nor keys can send Resume before the answer.
- **D2 (low), test gaps.** Every state's token and icon is pinned in a test (declined and concern among them); `actions()`'s enabled flags are tested per state, and the console's buttons read `a.enabled` (a press on a disabled action sends nothing).
- **D3 (low).** `SimBridge.CREW_INTENTS` lists `crew_stand_down`.
- **D4 (low).** Landed: the design doc and the plan in `implemented/r2`, this report, the changelog fragment, the sprint JSON completed.
- **Icon meanings.** The work and bar icons have a "?" key in the focus order (keyboard and pad), the same mechanism as the board's legend; closed, it adds no words.
- **Real names in the scripted crossing.** With AILANG v0.54.14 (#262) the names table runs on the strict VM, so `scriptedCrossing` brings the named crew aboard (`core.withCrew`). Re-recorded once: `tests/crew/crossing_hold.ndjson` (two runs identical, VM == interpreter) and the scripted-crossing pins; replay goldens unchanged.

## Upstream asks and follow-ups

- crew_core could keep `archive.completed` sorted, as it does `events` (several tasks archived in one batched span fold in another order; `crew_hold_test` compares it as a set).
- OQ6: concern text written for the game's jobs (crew lab).
- OQ8: offer withdrawal in crew_core (the console shows a lapse note meanwhile).
- OQ7: 1024 px portraits (an attended art task).
- crew-work.md: W5's concern buttons are superseded by the call window; OQ4 (readouts) gets a note.
