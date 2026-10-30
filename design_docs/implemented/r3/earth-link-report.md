# R3-EARTH-LINK report

**Sprint:** R3-EARTH-LINK, Earth's signal, the live Earth rate, the comms station and Earth's beams (R3 S1, K1, F6). Design: [earth-link.md](earth-link.md). Plan: [earth-link-sprint.md](earth-link-sprint.md). PR #344.
**Dates:** plan approved 2026-10-28 (PR #340), built 2026-10-28 to 2026-10-30.
**Evaluation:** 90/100 PASS, round 1, by an independent evaluator on a different model (Sonnet; `.ailang/state/evaluations/eval_R3-EARTH-LINK_round_1.json`); no blocking findings. Its findings are addressed below.

Renders: `make capture-earth-link` writes `renders/earth_link/` (ten frames and `contact_sheet.png`); the reviewed set is the review page https://claude.ai/artifact/5JjGWJ2kRDVBAdpJ4AAKUj.

## Mark's reviews (attended)

- 2026-10-28, the plan: "please merge in the plan" (OQ1–OQ5 at their recommendations).
- 2026-10-28, the EL3 panes: "the comms station is boring - this is the connection of the crew to home it should be a wash of images, text, emotions and feelings, and a good visual UI not lots of text". This became EL3b and the standing order "Visual First, Words Last".
- 2026-10-28, EL3b: "yep good go ahead and we will start seeding the library ... yeah we can do the crew faces as well".
- 2026-10-30, the EL3b.5 renders: "very nice". Audio (proposed after his question about the feed's media mix, "hmm we could also add snippets of audio"): "yes continue", which became EL3b.7.
- 2026-10-30, the EL5 renders: "looks great".
- 2026-10-30, the sound review: "wow im impresssed we generated this via ailang? they all seem to include noise in background is that intentional?", then v2 with less hiss; "they are nice, not really realistic sounding but spooky and unique enough to include - but yeah if we can get closer to real sounding effects etc whynot try it". The follow-up design is PR #360 (`sunholo/audio` 0.6.0, not in this sprint).

## What was built

| Milestone | What |
|---|---|
| EL1 | `sunholo/observe` 0.1.0 published (the light cone: seenAt, catchUp, triangleExcess, onBeamLine, linkWindow, earthRate), pinned in `sim/` |
| EL2 | `sim/earth_link.ail` and protocol 2.16: the plan sent home at every commit, Earth's aim only at plans it has heard, in beam by geometry, the Earth rate D on every tick, stale beams, the link window and the plan preview (cost fields only) |
| EL3 | The comms station on the spare console (`reserved_2`): Listen and Exchange log; home is the Solar System (120 AU, amended after the first run in the game) |
| EL3b.1–.3 | `earth.feed` (Earth's weeks at the scale a voyage receives, a seeded mix of kinds), a seeded library of 48 pictures, the visual station: the feed with tint, jumble, static and the ring, the twin clocks |
| EL3b.4 | The crew at the console with their home feelings; emotion portraits for every member |
| EL3b.5 | The exchange as light: a spacetime strip from `earth.messages` (the sim adds from_ly, port_ly, arrive_t); the station layout; `make capture-comms-station` |
| EL3b.6 | Live frames painted each time the player looks (the AI lane, the player's keys, nothing from the ship); the library grows |
| EL3b.7 | Sound from home: 8 synthesised beds and 5 accents (route A, `synth-own`), pitch by the Earth rate's band, held beds, accents stretched by the pitch, played at the receiver only while the station is open |
| EL4 | Earth's beams on the galaxy map (`ui/earth_beams.gd`): heard beam and its light-front, plans in flight home, stale beams, the window ring, silence, and the preview alone while planning (AC12) |
| EL5 | `physics/observe.gd` and RS-26..RS-37 in `make physics`; the sim's Earth rate fixture; golden G-EL-1; `make capture-earth-link` (five states and a contact sheet) |

## Measurements

- **The Earth rate from the real sim** (seed 7, 0.99c): 0.0708881389 astern leaving Earth (e^−φ = 0.0708881205; the voyage starts at Earth, 1 AU from Sol, so Sol is not exactly astern: 2.6e-7 relative), 14.10673598 ahead flying home (e^φ to 1e-11). At the top speed (β 0.999999): 7.0711e-4.
- **The wait at a 30 ly turn 40 ly out** (RS-33's 60 yr at high γ): 59.70 yr at 0.99c, as the preview before the commit and the window after it.
- **G-EL-1:** 9 light-front and window-ring centroids within 0.18 px of the float64 projection (limit 0.5); a front 0.05 ly off is caught.
- **Sound:** 13 files, 5.7 MB of the 20 MB audio git budget (18.1 MB used in all); v2 cut the energy above 3 kHz by 8–15 dB in five beds.

## Found along the way

- **The export dropped the feed library.** `data/feed/SOURCES` and the raw WebP pictures were not in `include_filter`; `make export-filter-audit` caught it on this branch (fixed in 6ce9dcc5).
- **`make golden` counts 400 locally, 401 on the rig.** The textured Jupiter case (G-M5-4) skips without `make planet-assets`; the 401 pin assumes the textures. Not a regression; noted so the next local run does not chase it.
- **Godot's import writes stray `.translation` files** next to the planet and truth CSVs on every import in a side clone (follow-up).

## Evaluation findings (90/100, round 1)

- **Medium, the sprint JSON left EL3b open.** Closed: EL3b `passes` true with its sub-steps, the sprint `completed`, the evaluation recorded.
- **Medium, no changelog entry.** Added: `changelogs/unreleased/2026-10-30-earth-link.md` (this repo files fragments; `CHANGELOG.md` is folded from them at a tag).
- **Low, the design and plan still in `planned/`.** Moved to `implemented/r3/` with their status lines, links and the README index row.
- **Low, AC11 rests on the review.** The contact sheet is `renders/earth_link/contact_sheet.png` and the reviewed page is linked above; `rig/full` with `--golden` runs on the merged head.
- **Low, the branch was behind main.** `origin/main` merged in (one conflict, the sim's export list, both sides kept), so the rig tests the merged tree.

## Follow-ups

- `sunholo/audio` 0.6.0, closer-to-real synthesis (PR #360, awaiting Mark's approval).
- AI-voiced news lines from home (D-101: no generated sound yet).
- The home beacon (R2-SOUND S2) can now follow `earth.rate` and `earth.in_beam`.
- `crew_core` reacting to news from home (a package change).
