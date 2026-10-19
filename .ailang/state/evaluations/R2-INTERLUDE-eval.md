# R2-INTERLUDE evaluation (independent)

Evaluator: Claude Sonnet 5.5 (not the executor). Branch feat/interlude-card, head 8694891. Fresh clone, pinned runtime v0.54.11, sky assets fetched.
Rubric (the plan has none; standard 100, pass 70). Weights used: acceptance criteria and behaviour 35, tests and gates 25, determinism/protocol/purity 15, display audit and UX 15, hygiene and docs 10.

## Score: 89 / 100 — PASS

| Line | Max | Got | Evidence |
|---|---|---|---|
| ACs and behaviour | 35 | 32 | AC1-AC12 verified by command (below). Rulings 1-7 verified: pages with dots, a home image per tier (7 WebP, three viewed), holds stop the crossing (crew-hold: holds on days 31, 61..., each on a check-in), critical_only queued at ship_geometry_demo.gd:638, 365-day cap (mutant 400 fails 3 tests), tier lines word for word incl. "A year at home." for whole==1, Archive authored lines always and live telling only via AiRelay.can_open. -3: the defects below. |
| Tests and gates | 25 | 24 | `make -k test` finished with no make errors (log has no "Error"); the extra target list exited EXIT=0; crossing-review 82 passed, no-twitch 40, crew-hold 0 failures, crew-perf chunk slowest 0.112 s, critical_only decade 0.89 s. Mutants (below) all killed. -1: the auto-dismiss mutant is stopped in no-twitch only by a SCRIPT ERROR (the gate catches it), not by an assertion; test_cruise_interlude catches it cleanly. |
| Determinism, protocol, purity | 15 | 14 | `make strict parity parity-v2 replay crew-parity` pass; replay: 11 cases identical; tests/replays/* not in the diff vs origin/main (only tests/crew/console_state.json, a 2.10 view fixture gaining `emotion`, and the new crossing_hold.ndjson). Digest sha c9ed005e... equal on strict VM x2 and interpreter x2 and the golden. -1: nothing tests the `cruise` section on a full-state/reconnect path (it is only emitted on the tick path, sim/protocol.ail withCruise). |
| Display audit and UX | 15 | 11 | display-audit-interlude: 13 of 13 pages sampled, 0 new findings, known_findings.json untouched; control `review_unbound` is rejected as it should. 62 frames captured; 14 opened. Defects D1-D4 below. |
| Hygiene and docs | 10 | 8 | Design doc + sprint + JSON present; export filter extended; ui/interlude_card.gd removed cleanly. -2: sprint JSON status still "in_progress"; export_audit witness for data/interlude is SOURCES (text), not a .webp, so WebP survival in an export is not proven; no exported build was run. |

## Commands run
- `make -k test` (about 1 h wall): no failures.
- `make crossing-review-test no-twitch-test tour-pacing-test crew-hold-test display-audit-interlude display-audit-controls export-filter-audit ai-test in-world-voice-check playthrough-ai-modes strict parity parity-v2 replay crew-parity`: EXIT=0.
- `make crossing-review-capture`: OK (62 frames).

## Red checks and mutation probes (scratch copy, all reverted)
1. Tier threshold 80 -> 70 in cruise_digest.ail homeTier: FAIL "home tiers 0-6 at every edge".
2. Tier line `whole == 1` -> `== 2`: FAIL "tier lines ... one year is singular".
3. chunkDays 365 -> 400: FAIL (3 tests incl. "auto-run off is the 365-day cap").
4. Hold does not end its chunk (crewStop always chunk): FAIL 4 tests (AC5 "a hold ... ends its chunk", digest through two holds, ship days, next stop).
5. Host ignores crew_held (solar_departure.gd:182): test_crew_hold FAIL 4 (ship time waits, stops on check-in day, day 31).
6. CardInterlude.done() auto-dismisses after 6 s: test_cruise_interlude FAIL "with a reader, 600 s ... leave the review open"; no-twitch SCRIPT ERROR.
7. Numeral check removed in ai/reply.ail screen: reply_test FAIL x2 (incl. the I4 telling test). Removed in sim/ai.ail record validation: ai_test FAIL (AC3 record refusals).

## Defects (none blocks the pass)
- D1 (UX, D-80): portraits and names mismatch in the review. Aboard frame acen_aboard: "Abebe Njoroge" (male name) on a grey-haired woman, "Madina Rahimov" (female name) on a man. D-80 (RESOLVED) says the name fits the face; sim/crew_names.ail nameOne draws region only, no gender (pre-existing on main, but the review now shows it on every page and the design cites D-80).
- D2 (UX): Home page shows two different news ages: "News from home is 66.6 years old when it reaches you" (ui/crossing_review.gd:450, live digest age) above the news body "... it is 40.62 years old" (template slot at the last stop). Also "They wrote it 0.00 years after your departure" (data/news/templates.json rewritten text with a slot of 0.00). Confusing for a player.
- D3 (copy, D-68 truthfulness): sim/cruise_digest.ail:320 tier 3 Archive line says "We crossed in weeks of our own time"; tier 3 covers 30-80 Earth years and the Aldebaran leg is 248 ship days (months). Make it "in a short span of our own time".
- D4 (layout): at 2560x1440 and 1280x720 the right-hand HUD column runs off the bottom ("Guided voyage" title clipped) and the bottom hint line crosses the cone/side panel. Pre-existing HUD layout, visible in every frame.
- D5 (edge): ui/crossing_review.gd page_spec returns only ["crossing"] when a hold is open but `cruise.digest` is absent, so the Hold page and its Resume button would not exist (cannot happen on 2.10 committed ticks, but there is no fallback).

## Renders opened (14)
acen_hold_2560, acen_moment_0_2560, aldebaran_home_2560, art_tier0/3/6_2560 (all three home images: legible text over the calm left side, scrims fine), acen_aboard_2560, acen_changed_2560, acen_moment_3_1280, trappist_hold_1280, nocrew_home_1280. No digits in crew text; counts are spelled ("seven", "three"); the Archive line has no digits; text legible, no overlaps inside the panel.
