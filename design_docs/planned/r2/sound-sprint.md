# Sprint R2-SOUND: the ship's sound, heard from inside

**Design doc:** [sound.md](sound.md)
**Sprint JSON:** `.ailang/state/sprints/sprint_R2-SOUND.json`
**Status:** **Awaiting Mark's approval.** Nothing is executed until he answers OQ1–OQ9 (one ledger row). Three further hard stops: the S0 sound board, the S1 bridge dev build, the S2 voyage dev build.
**Base:** `origin/main` 8e49c160 (branch `design/sound`).
**Plan review:** an independent Sonnet review (read-only) scored the first draft 78/100 (pass) with six blocking items; all six are fixed here and in the design doc (export filter, a second spike for ducking, limiter and 3D panning, the cue clocks, the footstep accumulator, the lift and tour signals, headroom before the limiter), and its non-blocking suggestions are folded in (`sprint_R2-SOUND.json` `reviews`).
**AILANG:** v0.54.14 (pinned). AILANG prompt version loaded: v0.16.7 (`ailang prompt --version-active`). `.ail` code is written in S0b (the synthesis tool); syntax checklist below.
**Registry reuse:** searched 2026-10-20 (`ailang pkg search audio|synth|dsp`): only `sunholo/gemini_live` (voice protocol, not synthesis). Decision **none**: the synthesis tool is game-specific authoring; `std/audio` (stdlib) covers WAV and Opus. A generic synth package is a possible later contribution, not in scope.
**Estimate:** about 1,800 game LOC over **9 working days**, excluding Mark's three listens. Recent attended R2 velocity is about 300 LOC/day (R2-CAMERA 1,700 LOC in about 5.5 days); this plan assumes about 200/day because sound design (choosing, trimming and tuning about 35 cues by ear and by the loudness check) is not counted in LOC. Each milestone has a day cap; an overrun goes back to Mark at the next pause.

## What the survey found

- **Audio today:** two `AudioStreamPlayer`s on the default bus (`ui/conversation/conversation.gd`, `ArchiveVoice` in `demos/ship_geometry_demo.gd`), no bus layout, no audio assets, no volume setting, no audio test.
- **The events exist:** the sim emits `committed`, `phase` (`boosting`, `cruising`, `braking`, `at_rest`), `arrived`, `hold_limit`, `crew_hold`, `archive` (`bh_enter`); `ship.ism` carries `medium` and the drawn dust `impacts` (`interior/dust_flash.gd` reads them); `SimBridge.stepped(events)`, `ShipConsoles.used(station, action)`, `GalaxyMap.target_selected`, the HUD's signals and `JourneyHud.BRAKE_NOTICE` cover the rest. **No sim change is needed.**
- **Settings:** `ui/game_settings.gd` (`settings.cfg`; `camera_motion`, `confirm_mode`, `text_only`), tested by `tests/test_title_screen.gd`.
- **The spike** (design §Evidence): AILANG synthesis 2 s in 0.28 s (VM) = interpreter byte for byte; Godot loads the WAV; the headless Dummy driver mixes, so loudness tests run without a sound card.
- **Canon:** the spire's constant hum (ship-structure.md), the teacup rule (one-g.md), nothing crosses but light (nothing-crosses.md, photon-drive.md).

## Milestones

### S0a: foundation (~550 LOC, 2 days)
- **Red first:** `tests/test_sound.gd` + `make sound-test`: schema validation with three negative fixtures (renamed trigger, missing stream, unknown bus); a scripted `stepped` sequence fires the mapped cues in order; the footstep accumulator gives 9 steps for 6,990 mm and 10 for 7,000 mm; the clocks are sim ticks, impact ship time and the input sequence, never frames (design §D1); the visual-counterpart and forbidden-word checks; a cue log twice from the same input is byte-identical.
- **First, on the rig:** record the frame-time baseline (`make bench SCENE=bridge`, GPU window) into `tests/fixtures/sound/bench_baseline.json` with the host load, before any sound code lands.
- **Build:** `default_bus_layout.tres` (§D2 buses, sidechain compressors, Master limiter, Ship reverb); `audio/sound_director.gd` (cue table loader and validator, deterministic variant and pitch, the cue log ring buffer, 2D/3D players, the listener rule); `data/audio/cues.json` and `assets.json` with placeholder silent WAVs for the S0a tests; the two existing voice players onto the Voice bus. `export_presets.cfg`: `assets/audio/*` and `data/audio/*` added to `include_filter`; `mk/sound.mk` included from the `Makefile`, its targets in `.PHONY` and the checks in the `test:` prerequisites.
- **Settings, red first:** extend `tests/test_title_screen.gd`: per-bus volumes persist and apply, 0% mutes, Mute when unfocused, Reduced audio.
- **`make sound-assets-check`:** the manifest's bytes, sha256, rate and licence; the git budget. Negative controls: a wrong sha256 and a `CC-BY` licence each fail.
- **Gate:** `make sound-test sound-assets-check title-screen-test ai-conversation crossing-review-test ship-ui-test`; `make strict parity replay`; `git diff --stat origin/main -- sim/` empty.

### S0b: synthesis and the first sounds (~450 LOC, 3 days) ⏸ sound board
- **AILANG, red first:** `tools/audio/synth_test.ail` (named checks: a sine recipe's first samples, the int16 clamp, loop-join slope ≤ 1 LSB, a recipe's sha256), run strict VM and interpreter, compared.
- **Build:** `tools/audio/synth.ail` (pure: oscillators, partials, slow swell, deterministic noise from SplitMix64, envelopes, integer-cycle loops, per-second rendering joined with `concatList`), `synth_main.ail` (FS shell: recipes in, WAVs out, the manifest rows), `data/audio/recipes.json`; the first set: `spire_hum`, `room_bridge`, the UI clicks, `console_wake`/`sleep`, `arrived`, `commit_seal`, `drive_boost`/`silent`/`brake`, `stop_turn`, `dust_tick`, `archive_ready`.
- **`make sound-check`** (`tools/sound_check.gd`, headless capture): per-cue bands and peaks, the pre-limiter Master peak ≤ −1 dBFS with everything at once and the limiter present, voice ducking ≥ 6 dB, the 150 Hz high-pass survival, the +6 dB hot fixture fails.
- **`make sound-synth-check`:** strict VM clean, VM = interpreter on a short recipe, every synthesised file reproduces its sha256.
- **`make sound-review STAGE=s0`:** each cue and a 30 s hum-and-room loop through the real buses, rendered by Godot, compressed to Ogg Opus by `std/audio.encode`, an `index.html` of players; published to `gs://stapledons-voyage-assets/refs/sound/s0/` with per-file URLs.
- **Gate:** S0a's gate plus `make sound-check sound-synth-check`.
- **Pause:** Mark listens to the sound board (the hum first). He approves the palette or redirects (ledger row in the attended session).

### S1: the bridge (~380 LOC, 1.5 days) ⏸ dev build
- **Foley:** CC0 footsteps on metal (6 variants), the lift's mechanism and chime; fetched with `curl` from Kenney.nl CC0 packs (no login) into `assets/audio/foley/`, URL, author, licence and sha256 in `assets.json`; trims and fades by the AILANG tool; a synthesised placeholder if nothing CC0 fits, so S1 never stalls.
- **Red first:** the listener test (a source left of the captain pans left in Bow and right in Astern); lift start/run/arrive order; console wake/sleep at each station; `rooms.json` sets the bridge reverb on arrival; the hum's 3D source is at the mast node.
- **Build:** the bridge cues of design §D4; `started(level)` and `arrived(level)` signals on `demos/ship_demo_lift.gd`; `data/audio/rooms.json`; the `AudioListener3D` rule; attenuation.
- **Gate:** `make sound-test sound-check sound-assets-check camera-test camera-forward-test ship-ui-test ship-demo-lift-test`, `make bench SCENE=bridge` (GPU window, rig): p99 < 16.7 ms and within 0.5 ms of the S0a baseline, then the full `make test` on the rig (`tools/rig_check.sh`).
- **Pause:** `make publish-dev` (no `v*` tag) and `make sound-review STAGE=s1` (a 60 s bridge walk). Mark walks the bridge with sound.

### S2: the voyage (~420 LOC, 1.5 days) ⏸ dev build
- **Red first:** the voyage cue-log golden (`tests/fixtures/sound/cue_log_voyage.txt`) from a short recorded session (plan, commit, boost, cruise, brake, arrive, one stop) driven through `ui/transit_harness.gd`, byte-identical in two separate Godot processes; `commit_seal` only on the sim's `committed`; the dust counter's dead time; `medium_change` on a cloud edge; the home beacon's pitch at β = 0, 0.9, 0.99 (Sol astern and ahead) to 0.01 semitone, if OQ6 is accepted.
- **Build:** the voyage cues of design §D6, the tour's `attitude_hold_changed(on)` signal, the interlude bed under the Archive's voice, the beacon if accepted.
- **Gate:** S1's gate plus `make ai-conversation crossing-review-test`, `make export-filter-audit ship-demo-export-smoke` (the smoke asserts the exported pack loads the cue table and logs one cue), and on the rig `make export-pack-check` (zip growth ≤ 6 MB) and the full `make test`.
- **Pause:** a dev build and `make sound-review STAGE=s2` (the voyage at speed, the dust counter in a warm cloud and in the hot bubble). Mark plays a voyage with sound.

### S3: evaluation and landing (0.5 day)
- Independent evaluation by a different model (`sprint-evaluator`, ≥ 70/100), `.ailang/state/evaluations/eval_R2-SOUND_round_1.json`.
- Landing: the doc to `design_docs/implemented/r2/`, the README index, a changelog fragment, the design repo's `features/next/sound.md` status.

## AILANG syntax checklist (S0b)

| Module | Contracts | Effects | Inline tests |
|---|---|---|---|
| `tools/audio/synth.ail` | **include:** `clamp16(v: int) -> int` with `ensures { result >= -32768 && result <= 32767 }`; `loopFrames(rate: int, seconds: int) -> int` with `requires { rate > 0, seconds > 0 }`, verified with `ailang verify` | **include:** pure (`! {}`), strict VM | **include:** `tests [(0, 0), (40000, 32767), (-40000, -32768)]` on `clamp16` |
| `tools/audio/synth_main.ail` | **skip:** an I/O shell; its inputs are validated by the pure core | **include:** `! {FS, IO}` | **skip:** covered by `make sound-synth-check` (sha256 of every output) |
| `tools/audio/synth_test.ail` | **skip:** a test entry | **include:** `! {IO}` | **skip:** it is the named-check runner |

## Pause points

1. **Plan approval:** OQ1–OQ9 answered in one ledger row.
2. **After S0b:** the sound board.
3. **After S1:** the bridge dev build.
4. **After S2:** the voyage dev build.

## Risks (summary)

The hum's fatigue and the laptop's low end (both checked before anything builds on them), long-bed synthesis speed (short loops), loop clicks (integer cycles, tested), CC0 provenance (recorded per file), spoilers in cue names (reviewed). Full table in the design doc.
