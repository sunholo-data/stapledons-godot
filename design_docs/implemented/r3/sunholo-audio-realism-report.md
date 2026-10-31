# R3-SUNHOLO-AUDIO-REALISM report

**Sprint:** R3-SUNHOLO-AUDIO-REALISM, `sunholo/audio` 0.6.0 and the home sounds closer to real. Design: [sunholo-audio-realism.md](sunholo-audio-realism.md). Plan: [sunholo-audio-realism-sprint.md](sunholo-audio-realism-sprint.md). Game PR #361; package PR sunholo-data/ailang-packages#172.
**Dates:** designed, approved and built 2026-10-30.
**Evaluation:** 83/100 PASS, round 1, by an independent evaluator on a different model (Sonnet; `.ailang/state/evaluations/eval_R3-SUNHOLO-AUDIO-REALISM_round_1.json`); no hard fails. Its findings are addressed below.

## Mark's reviews (attended)

- 2026-10-30, the v1 beds (EL3b.7): "wow im impresssed we generated this via ailang? they all seem to include noise in background is that intentional?" (v2 cut the hiss), then "they are nice, not really realistic sounding but spooky and unique enough to include - but yeah if we can get closer to real sounding effects etc whynot try it". This sprint.
- 2026-10-30, the plan: "looks great go on audio and then lets preview the new sounds" (OQ1–OQ8 at their recommendations).
- 2026-10-30, on the compressed pitch: "we dont want to compromise on this? its educational I think - but I guess the software will help compensate?", then "so like the exposure visuals, we can have a true setting, and processed settngs. this is a general principle for ths game - no compromises on the physcis, if we can help it" (a standing order, stapledons-design #46). This became AR8b.
- 2026-10-30, the listen (P2, https://claude.ai/artifact/ANRG4SeogdoN7tkgDPLsD7): "yeah these sound good - lets merge it in to the game", "v3". v3 for all twelve re-voiced sounds; the music-box tune (take A); no receiver colour.

## What was built

| Milestone | What |
|---|---|
| AR0 | The eight frozen 0.5.0 compat pins (`compat.ail`): every 0.5.0 field, byte for byte through `recipe.render` and `renderSound` |
| AR1 | `filter`: a resonant state-variable filter, formant banks and vowel tables (0 / −10.014 / −10.056 dB at 1 kHz, Q 2) |
| AR2 | Pink and brown noise (−3.05 and −6.01 dB/octave) |
| AR3 | `osc`: a polyBLEP saw with jitter, FM (sidebands within 0.002 of \|J_k(I)\|), a Karplus–Strong pluck (within 1 cent) |
| AR4 | `sound`: the 0.6 front end (closed vocabulary, loop rules, budgets); a 0.5.0-only recipe renders through `recipe.render` itself |
| AR5 | Events inside loops, wrapping exactly at the loop point |
| AR6 | `space`: a short Schroeder/Moorer reverb (T60 within 5 %) |
| AR7 | 0.6.0 metadata, `_smoke` probes, docs; `ailang iface` of every 0.5.0 module kept line for line; quality with no gates |
| AR8 | The game's shells on the 0.6 API (41 sounds byte for byte), the 13 home sounds re-voiced (v3), the takes, the listening preview |
| AR8b | The station's True and Receiver settings (the standing order): the time rate exact at D, Receiver's frequency correction on a new Receiver bus, True silent outside hearing, the station's button |
| AR9 | 0.6.0 published (and 0.6.1, a smoke-only fix for the package CI's 30 s limit), pinned from the registry, the package PR merged, the game PR green on the rig (74 min) and merged |
| AR10 | This evaluation and landing |

## Measurements

- **Byte identity:** all 41 game sounds regenerate byte for byte on 0.6.0 (VM = interpreter); outside `home_*` only provenance changed.
- **Render time:** the 13 home sounds take 58.4 s on the strict VM (budget 60 s; v2 took 22.05 s); timings evidence in sunholo-data/ailang-packages `design_docs/implemented/audio-realism-0.6.0/timings.json`.
- **Asset budget:** 18,104,524 of 20,000,000 bytes (unchanged: the beds stayed 5 s).
- **The Receiver correction, through the mixer:** a 1 kHz tone at speed D comes back at 1000, 1000 and 1011 Hz at D = 0.5, 2 and 16 in Receiver; True plays 499, 2000 and 15998 Hz.

## Evaluation findings (83/100, round 1)

- **Medium, no ledger row for P2.** The ruling is recorded in the sprint plan and JSON (`ruling_p2`); `mission_answer.sh` answers existing OPEN rows and there was none, so AC12 is amended rather than a row invented.
- **Medium, the review manifest URL 404s.** The review was a listening artifact, not a `make sound-review` stage; AC12 now names it.
- **Medium, the sprint JSON stale.** Closed: AR8, AR8b, AR9, AR10 complete, the sprint `completed`, the evaluation recorded.
- **Medium, the Receiver correction asserted only as numbers.** Now measured through the mixer (`test_receiver_measured`, above). The receiver's 1/16x..16x clamp stays a stated limit of a real-time receiver (data `sound.receiver`), with the time rate exact everywhere else.
- **Low, landing not done.** Done: the design and plan in `implemented/r3/`, this report, the changelog fragment, the README row.
- **Low, the timings evidence not in the game repo.** Cited above at its path in the package repo.

## Follow-ups

- The other known compromises the standing order lists: the feed's tint bands (a camera's True and processed colour), the ship's star-light brightness mapping, the home beacon's compressed pitch (R2-SOUND OQ6).
- The bridge sounds could use the new tools (`room_bridge`, footsteps, consoles, the lift, `arrived`), each with its own listen (OQ8: not now).
- AI-voiced news lines from home wait for a ruling (D-101).
