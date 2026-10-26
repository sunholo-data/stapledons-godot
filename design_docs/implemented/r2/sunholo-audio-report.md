# R2-SUNHOLO-AUDIO report: the sound tools on `sunholo/audio`

**Landed:** 2026-10-26, one game PR with two commits: the AILANG v0.54.18 pin, then the migration.
**Design:** [sunholo-audio.md](sunholo-audio.md) (see its §As built). **Sprint:** [sunholo-audio-sprint.md](sunholo-audio-sprint.md).
**Package:** `sunholo/audio` 0.5.0 (sunholo-data/ailang-packages #167; 0.1.0 was #154).

## What shipped

- **`sunholo/audio` 0.5.0.** It was extracted from `tools/audio/synth.ail` as 0.1.0. The package then grew to 0.4.0, and 0.5.0 adds per-layer `lowpass_poles` and closed layer keys.
- **The game's sound tools import the package.** `tools/audio/synth.ail` is deleted. `synth_main.ail` records `generator: sunholo/audio@0.5.0` and the lock's content hash.
- **The offline loudness rules run in AILANG.** `tools/audio/levels.ail` and `levels_main.ail` back `make sound-levels`. `make sound-levels-parity` keeps `tools/sound_check.gd` as the second-language mirror. Both targets are in `make test`.
- **The AILANG pin moves from v0.54.14 to v0.54.18.** The lockfiles are unchanged.

## Measurements

| Check | Result |
|---|---|
| `make sound-synth-check` | `synth-ok 28ee28 VM = interpreter; 28 sounds regenerate byte for byte` (path pin before publish, registry pin after) |
| Manifest | `assets_synth.json` differs from `origin/main` only in `provenance` (`jq 'del(.assets[].provenance)'` diff empty) |
| `make sound-review` | 58 WAV + Opus files, byte-identical to the base rendered with the in-tree synth on v0.54.14 |
| `make sound-levels` | 31 passed, 0 failures (24 cues, 2 laptop guards, 3 teacup guards, 2 negative controls), `levelsProbe` strict VM = interpreter |
| `make sound-levels-parity` | 24 cues, 5 guard values, 0 differences in centi-dB |
| `sound-test`, `sound-assets-check`, `ship-sound-test`, `sound-stage-check` | 40 passed; 28 files, 0 failures; 15 passed; 0 failures |
| `make ci-fast` on v0.54.18 | green (deps, policy lints, strict, parity, replay, crew parity, lore) |
| Package `ailang pkg quality` (v0.54.18) | no gates: 16/71 contracts verified, 0 refuted; 100/100 exports pure; 198 tests passed; smoke passed |

## Spike (design phase)

An AILANG port of `sound_check.gd`'s four offline measures matched the GDScript to 0.01 dB on six shipped sounds. It measured all 19 sounds then shipped in 9.8 s on the VM. Both engines agree to the centi-dB on every cue today.

## Upstream

- ailang#1930 (2026-10-22) reported that `std/audio` could not read a WAV and `std/string` had no fixed-precision formatter. Both shipped in v0.54.18.
- Follow-up: the package can delegate `wavInfo` and `pcm16Floats` to std in a later release.

## Footsteps (D-122 to D-124)

The footsteps were reworked three times while this sprint waited for S1 (#319):

- v2 was nearly white noise.
- v3 was a two-pole padding.
- v4 is three-pole, sits under the hum, and has level jitter with every other foot softer. Mark accepted it at the default level ("we can slightly hear under the hum so have variation, but yeah not annoying").

`lowpass_poles` came from that rework and went into the package as 0.5.0. The v4 footsteps regenerate byte for byte from it.
