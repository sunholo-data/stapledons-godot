# R2-SOUND report: the ship's sound, heard from inside

**Landed:** S0a and S0b (#298), S1 the bridge (#319), S2 the voyage (#375, merge `ddc4795e`, 2026-11-03).
**Design:** [sound.md](sound.md). **Sprint:** [sound-sprint.md](sound-sprint.md), `.ailang/state/sprints/sprint_R2-SOUND.json`.
**Rulings:** D-101 (plan), D-108, D-112, D-122, D-123 (listens), D-144 (S2 attended run); standing order 2026-10-30 (no compromises on the physics) for the home beacon. Mark on S2 (2026-11-03): "the sounds are awesome".

## What shipped in S2

- **The voyage's cues**, wired in `audio/ship_sound.gd` from what the ship already exposes (no sim, protocol or ship-demo change):
  - `plan_select`, a new sound, when the sim plots a new destination;
  - `commit_hold` while a commit is held, stopped on release; `commit_seal` on the sim's `committed`;
  - the drive, which boosts, falls silent and brakes, never boosting and coasting at once;
  - the dust counter at the helm, for the sim's drawn grains, with a 25 ms dead time in impact ship time;
  - arrival.
- **The home beacon, exact.** It plays in Earth's beam away from home, at the sim's `earth.rate` unrounded, with the comms station's True / Receiver setting.
  - **True:** a 400 Hz keyed carrier, resampled by D.
  - **Receiver:** generated as a heterodyne receiver hears it, Earth's keying at D on the true 400 Hz carrier, at every D.
  - No FFT pitch shift is used, and the compressed pitch (k = 0.25) is gone.
- **Tests:**
  - `make sound-voyage-test`: a real sim voyage heard through `ShipSound`, compared with a golden cue log, byte-identical in two processes.
  - `test_beacon_measured`: the carrier frequency and Earth's pip spacing measured through the mixer at D = 0.03 to 30, with a 2.01×D negative control.
- **Listening review:** https://storage.googleapis.com/stapledons-voyage-assets/refs/sound_s2/index.html

## Measurements (review render, CoreAudio 48 kHz, beacon dry)

| D | Receiver carrier, pip gap | True carrier, pip gap |
|---|---|---|
| 0.03 | 400.0 Hz, 33.37 s (33.33) | 12.0 Hz, 33.33 s |
| 0.0709 (outbound 0.99c) | 400.0 Hz, 14.11 s | 28.3 Hz, 14.17 s |
| 1 | 400.0 Hz, 1.0 s | 400.0 Hz, 1.0 s |
| 14.107 (homebound 0.99c) | 400.0 Hz, 0.0709 s | 5642.8 Hz, 0.0709 s |
| 30 | 400.1 Hz, 0.0333 s | 12000 Hz, 0.0333 s |

True at D = 60 is silent. The montage peaks at −4.3 dBFS, and nothing clipped.

## Evaluation

The cross-family Codex review scored 64/100 FAIL at `2aa509dd`, with two blocking items:
- the Receiver's keying was clamped to the station's real-time range;
- the live beacon was updated once per frame, not once per sim step.

Both were fixed. The review then scored 91/100 PASS at `acb85bc7`, and three cheap non-blocking items were fixed in `fb4282e8`. `rig/full` and the fast tier were green on the merge.

## Open items (not built)

1. **The comms station's home sounds still use Godot's pitch shifter for Receiver** (R3 audio realism AR8b).
   - Measured through the mixer: a 400 Hz tone corrected at D = 0.07 or 0.2 reads 314 Hz.
   - At high D the shifter's window smears short sounds: at D = 14.1 only 8 to 16 of 21 beacon pips survived, at every FFT size from 256 to 2,048.
   - The beacon avoids this by being generated directly. Making the beds exact the same way is Mark's call.
2. **S2b cues:**
   - `stop_turn` (it needs the tour's `attitude_hold_changed` signal);
   - `brake_notice`, `crew_hold`, `medium_change`, `interlude_bed` and `bh_enter`.
3. **Dust timing.**
   - Now: each tick starts on the first frame at or after its own time, so it is late by under one frame and the error never adds up.
   - Option: a generator voice could start ticks at the exact sample, but it needs about 0.1 s of buffer, so the ticks would trail the dome's flashes.
4. **Finding about headless audio.** Godot's headless Dummy driver mixes in 4,096-frame blocks, so sounds requested within one block start together (dust ticks stacked +6 dB, measured). The review therefore renders on CoreAudio. Any future audio timing test should keep this in mind.
