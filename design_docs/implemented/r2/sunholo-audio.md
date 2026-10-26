# R2-SUNHOLO-AUDIO: the sound synthesis and its loudness checks as the package `sunholo/audio`

**Status:** **Implemented** 2026-10-26 (approved D-119; footsteps D-122 to D-124). The game pins `sunholo/audio` **0.5.0** on AILANG **v0.54.18**; see §As built for what changed from this plan. [Report](sunholo-audio-report.md).
**Release:** R2. **Milestone:** a tooling extraction under R2-SOUND (sound.md): no player-facing change.
**Priority:** P2. It pays off when a second consumer appears (other sunholo games and demos, the website's listening pages, the crew lab's voice bed) and it moves the loudness checks out of GDScript into AILANG, as CLAUDE.md asks of every offline tool.

**Implements:**
- This repo: [sound.md](../../planned/r2/sound.md) §D8 (the AILANG synthesis tool) and §D9 (loudness bands, the laptop-speaker high-pass, the teacup rule's under-200 Hz guard); ledger D-101 (approval, AI-generated sound later), D-108 (the rework that added vibrato, beats, filter sweeps, drive and the true `white` noise, and kept the legacy `noise` so approved sounds stay byte-identical), D-112 (the room 6 dB lower; QOA compression at import), D-113 (the Archive's memory health drives the spire's degradation layer; unaffected).
- CLAUDE.md "Python" (the game is AILANG + Godot; offline tools are AILANG) and "Definition of done" gate 3 (shared maths lives in a published `sunholo/*` package, the game pins it; GDScript mirrors, never the only copy). Sound is not physics, so gate 3 does not bind here, but the same pattern is used on purpose.
- Design repo: [decisions/0001-engine-and-architecture.md](https://github.com/sunholo-data/stapledons-design/blob/main/decisions/0001-engine-and-architecture.md) (audio plays in Godot; the sim stays pure). **No design-repo change** and no physics-spec row: the package carries no physics.

**Depends on:**
- **PR #319 (R2-SOUND S1) merged first.** It adds nine synthesised sounds, the mix part `at` starts in `tools/audio/review_main.ail` and edits `mk/sound.mk`. This sprint starts from the `main` that contains it, and does not touch `audio/*.gd` (S1's files) at all.
- AILANG v0.54.14 at planning, **v0.54.18 as built** (sunholo/audio 0.3+ requires it): `std/audio` (`wavFromPcm`, `encode` to Ogg Opus), `std/bytes`, `std/json`, path dependencies (`{ path = "..." }`, resolution path > git > registry) for the pre-publish gate.
- `sunholo-data/ailang-packages` (new directory `packages/audio`); Mark's standing approval to publish `sunholo/*` packages (memory: publish standing approval; never crew_lab).

**Estimated LOC:** about 1,500 in all. Package about 920 (code 520: the synthesis core moved 290, PCM/WAV 80, mix 40, analysis 110; tests 330; `_smoke.ail` 70) plus about 250 lines of AGENT.md and CHANGELOG prose. Game about 330 (the shells re-pointed and the provenance plumbing 80, `levels.ail` + `levels_main.ail` 170, make targets 60, fixture 20) and about **−300** deleted (`tools/audio/synth.ail` and most of `synth_test.ail`).

## As built (2026-10-26)

What landed differs from the plan in these ways; everything else is as written below.

- **Package version: 0.5.0, not 0.1.0.** 0.1.0 was published from this plan (2026-10-22). The package
  then grew separately: 0.2.0 to 0.4.0 added hardening, clips, editing, levels, block filters, delay
  and gain automation, and require AILANG v0.54.18. The footsteps rework (D-122, D-123) needed a
  darker low-pass, so 0.5.0 adds per-layer `lowpass_poles` (1..4, default 1; record shape only, no
  sample changes, `kind = "breaking"`). 0.5.0 also refuses unknown layer and `env` keys, so a field a
  version does not implement can never be silently ignored (0.4.0 would have rendered the footsteps
  brighter without an error). Package PRs: ailang-packages #154 (0.1.0), #167 (0.5.0).
- **AILANG v0.54.18.** The game moved from v0.54.14 in the same PR (a separate commit; lockfiles
  unchanged). v0.54.18 also ships what we reported as ailang#1930 (`std/audio.wavInfo`,
  `std/string.formatFixed`); the package still carries its own reader (a later release can delegate).
- **The 0.1.0 module list grew** a `reference` module (exported reference recipes, so tests in other
  modules and consumers can pin them); the API is otherwise as in §D2.
- **AC6 is 28 sounds** (S1 added nine; the footsteps are v4, D-124). **AC7:** provenance is
  `sunholo/audio@0.5.0` and the lock's content hash.
- **AC10** was checked directly instead of through a committed fixture: `make sound-review` rendered
  on the base (`origin/main` 53b206a0, in-tree synth, v0.54.14) and on this branch gives the same 58
  WAV and Opus files byte for byte. A fixture would have to change with every sound.
- **AC commands:** the block below is updated to the as-built pins (0.5.0) and AC10's direct
  comparison. AC11's command covers `sim/`, `audio/` and the Python allowlist; two Godot files outside
  it changed by one cosmetic string each (`tools/sound_review.gd` shows the generator from the
  provenance; `tests/test_sound.gd`'s fixture provenance names the package).
- **`levels.ail`** refuses a cue table with a malformed cue instead of skipping it, and
  `sound-levels-parity` first proves it catches a 1 centi-dB mutant.
- **`sound-synth-check`'s `verify`** now targets `tools/audio/levels.ail`, which has no contracts, so
  it is a compile-under-verify step; the package's contracts are verified in its own repo.

## Game vision alignment

Scored with the `game-vision-designer` skill (feature-validation mode, against `vision/core-pillars.md`, last changed 2026-09-27; no prior decision on audio packaging). It is infrastructure: the player hears exactly the same bytes. **ALIGNED** (enabling work, no pillar negative).

| Pillar | Score | Rationale |
|---|---|---|
| Choices Are Final | 0 | No change to the commit's sounds or any decision flow |
| The Game Doesn't Judge | 0 | No new cue; the no-stinger rule (sound.md §D7) is untouched |
| Time Has Emotional Weight | 0 | No change to the coast or the crossing bed |
| The Ship Is Home | +1 | The spire's hum and the room tone are what make the bridge a place; keeping them reproducible byte for byte from a versioned, tested package (and the loudness bands checked in AILANG beside the maths that made them) protects that mix from silent drift as S2 adds the voyage's sounds |
| Grounded Strangeness | +1 | The teacup rule (no drive rumble under 200 Hz) becomes a pure AILANG guard over the same samples the game ships, with a negative control, instead of living only in a Godot script |
| We Are Not Built For This | 0 | No change |
| **Net** | **+2** | **Go.** Every pillar is 0 or positive; the work serves the two pillars the sound already serves |

## Problem

1. **The synthesis core is game-local but not game-specific.** `tools/audio/synth.ail` (224 lines, package `stapledons/audio` 0.1.0) is generic DSP: envelopes, exponential glides, vibrato, beats, one-pole filters and sweeps, soft saturation, a swell, edge fades, peak normalisation, deterministic noise, 16-bit PCM, loop rules and a JSON recipe parser. Nothing in it names the ship. Other sunholo projects that want a deterministic, strict-VM-clean synth would have to copy it, and copies drift.
2. **The loudness checks exist only in GDScript.** `tools/sound_check.gd` computes peak, gated RMS, the 150 Hz high-pass keep and the 4-pole 120 Hz low-band level by hand over decoded samples. They are pure arithmetic over a WAV, but they need a Godot import to run, and they are the only copy. Measured on 2026-10-22 (spike below), the same numbers come out of AILANG on the VM in about 10 s for all 19 shipped sounds.
3. **The mixing in the review renderer is generic too.** `review_main.ail` tiles loops, places one-shots at start times (PR #319's `at`), applies dB gains and sums. A second listening page would copy it.
4. **`std/audio` is write-only.** It builds WAV headers and encodes Opus but cannot read a WAV or decode PCM (reported upstream, below). Every measuring tool re-implements a decoder.
5. **Provenance is tied to a file path.** Each synthesised row in `data/audio/assets_synth.json` records `generator: tools/audio/synth.ail` and that file's sha256 (`21289da2…`). Once the code is a package, provenance should name the package version and its locked content hash, which is stronger evidence than a path.

### Evidence (spike, 2026-10-22, throwaway, not committed)

A throwaway package under `tools/audio_spike/` (not in this PR) decoded the shipped WAVs in AILANG and ran `sound_check.gd`'s four measures, copied verbatim into a GDScript spike for the same files at gain 0:

| Sound | Peak | RMS (gated) | 150 Hz HP keep | 120 Hz 4-pole low band |
|---|---|---|---|---|
| ui_click | −3 / −3.0 | −15.52 / −15.52 | −0.11 / −0.11 | −67.51 / −67.51 |
| spire_hum | −3 / −3.0 | −11.82 / −11.82 | −4.40 / −4.4 | −6.59 / −6.59 |
| drive_boost | −3 / −3.0 | −10.83 / −10.83 | −1.25 / −1.25 | −27.06 / −27.06 |
| drive_silent | −3 / −3.0 | −17.75 / −17.75 | −1.21 / −1.21 | −31.32 / −31.32 |
| drive_brake | −3 / −3.0 | −9.47 / −9.47 | −1.46 / −1.46 | −26.53 / −26.53 |
| room_bridge | −6 / −6.0 | −20.24 / −20.24 | −2.76 / −2.76 | −7.03 / −7.03 |

(AILANG / GDScript, both snapped to 0.01 dB as `snappedf` does.) Identical in every cell. All 19 sounds took 9.8 s on the bytecode VM (the interpreter took 34 s for two, so parity tests use short fixtures). A strict-VM probe (`--strict-bytecode`) on a full-scale 1 kHz sine printed `0 -2.83 -0.18` and a 60 Hz sine's low band `-3.89`, byte-identical to the interpreter. The −2.83 dB is the closed form: −3.0103 dB for a sine, plus 10·log10(48/46) = +0.185 dB because the RMS gate (|x| > 0.001) drops the two exact zero crossings per 48-sample cycle, which makes it a good package test value.

The baseline on `origin/main` adf34a67 with the pinned runtime: `make sound-synth-check` prints `synth-ok 28ee28 VM = interpreter; 19 sounds regenerate byte for byte` in 83 s; the reference loop's PCM sha256 is `28ee281fd0d0f02f67aa83295b89490a94895a654084a095ccf9772b59797467`.

Registry search on 2026-10-22 (`ailang pkg search audio|synth|dsp|wav|sound`): only `sunholo/gemini_live` (a voice protocol, no synthesis). `sunholo-data/ailang-packages/packages/` has no audio package. Decision: a **new** package (`none` to depend on; this sprint contributes it).

## Goals and non-goals

**Goals**
- G1. A published package `sunholo/audio` 0.1.0 in `sunholo-data/ailang-packages`, every export pure, strict-VM clean, VM = interpreter, `ailang pkg quality` with no gates, contracts where Z3 can encode them, AGENT.md, `ai_summary`, CHANGELOG, `[release] kind`.
- G2. It holds the generic parts: DSP primitives, both noise generators (the legacy ramp kept on purpose, honestly named), the recipe schema and renderer, loop rules and seam measurement, mixing, PCM16 encode and decode and a WAV reader, and the offline loudness analysis (peak, gated RMS, high-pass keep, low-band level).
- G3. **The game pins it and nothing audible changes:** after the pin, every one of the 28 synthesised WAVs (19 today plus #319's nine) regenerates byte for byte (`make sound-synth-check`), and the AILANG loudness numbers equal `sound_check.gd`'s for every cue to 0.01 dB.
- G4. The game's offline loudness checks (bands, peak ceiling, laptop-speaker high-pass, the teacup guard) run in AILANG (`make sound-levels`, in `make test`); the mixer checks stay in Godot.
- G5. A render-stability contract for consumers: a published version never changes the samples of an existing recipe unless its release kind is `breaking`.

**Non-goals**
- Any new sound, any recipe change, any change to the cue table, the director, the bus layout, the mix or the export (QOA staging stays in Godot, D-112).
- A QOA encoder (OQ3), stereo or multichannel rendering, sample-rate conversion, a realtime/streaming synth, or a Godot-side GDExtension.
- Moving the Godot mixer checks (capture, ducking, the limiter, every cue at once) out of `sound_check.gd`: they measure Godot's mixer and must run in it.
- Any sim, protocol or replay change (`git diff --stat origin/main -- sim/` stays empty).
- Python: none is added; `tools/python-allowlist.txt` is unchanged.

## Design

### D1. What moves and what stays

| Moves into `sunholo/audio` | Stays in the game |
|---|---|
| `synth.ail` whole: `Env`, `Layer`, `Recipe`, `envAt`, `phaseAt`, vibrato, beat, one-pole low/high-pass, the swept low-pass, `sat`, swell, edges, `layerSamples`, `render`, `clamp16`, `pcm16`, `loopErrors`, `parseRecipes` | `data/audio/recipes.json`, `cues.json`, `assets.json`, `assets_synth.json`, `rooms.json` (the game's sounds and their manifest) |
| `noise` (renamed `rampNoise`; recipe kind string `"noise"` unchanged) and `white` | `tools/audio/synth_main.ail`: the FS shell, now importing the package; it writes the WAVs and the manifest part, and computes provenance from the lock (D6) |
| The mix from `review_main.ail` (PR #319): tile a loop, place a one-shot at start times, dB gain, sum | `tools/audio/review_main.ail`: the review plan, file naming, Opus/WAV writing (it calls `std/audio.encode` and the package's `mix`) |
| A WAV reader (`wavInfo`, mirroring `SoundData.wav_info`'s chunk walk) and `pcm16Floats` decode | `tools/audio/synth_test.ail`, trimmed to the game's own pins: the reference recipe's PCM sha256 through the package, VM = interpreter (it guards the pin) |
| Analysis: `peakDb`, gated `rmsDb`, `level`, `highpassKeepDb`, `lowbandDb`, `seam`, `dbToGain`, `gainToDb`, centi-dB rounding | New `tools/audio/levels.ail` + `levels_main.ail`: the game's rules (each cue's `volume_db` plus its param curve's loudest point, bus bands, the −1 dBFS peak ceiling, which cues get the laptop and teacup guards) over the package's measures |
| | `audio/sound_director.gd`, `sound_mix.gd`, `sound_data.gd`, `ship_sound.gd` (untouched), `tools/sound_stage.gd` (QOA), `tools/sound_review.gd`, `tools/sound_assets_check.gd`, the Godot mixer half of `tools/sound_check.gd` |

`sound_check.gd`'s four offline measures stay in place as the **second-language mirror**: `make sound-levels-parity` compares them with the package's numbers (OQ2). They are not deleted in this sprint.

### D2. Package layout and public API

Directory `packages/audio` in `sunholo-data/ailang-packages`, module prefix `sunholo/audio`. Sketch (final signatures fixed at AU1; every export pure):

```
sunholo/audio/dsp        -- primitives, no recipe types
  absF(x) ; clamp16(v: int) -> int          ensures -32768 <= result <= 32767
  dbToGain(db) ; gainToDb(g) -> float       gainToDb is exactly sound_check.gd's db(): -120 if g <= 1e-6,
                                            else 20.0 * log(g) / log(10.0) (not log10: parity rests on the same ops)
  centiDb(x: float) -> int                  floor(x / 0.01 + 0.5), Godot's snappedf(x, 0.01), as an int
  onePole(cut, rate) -> float               1 - exp(-2 pi cut / rate)
  lowpass(a, xs) ; highpass(a, xs) ; sweepLowpass(c0, c1, n, rate, xs)
  softSat(k, x)                             x (1 + k) / (1 + k |x|)
  normalisePeak(db, xs) -> [float]
sunholo/audio/noise
  rampNoise(i, seed) -> float               the legacy generator: three affine LCG rounds, NOT white
                                            (affine in i: a fast ramp mod 2^31); kept so approved sounds keep their bytes
  white(i, seed) -> float                   affine start + three squarings mod 2^31; lag-1 |r| < 0.03
sunholo/audio/recipe
  type Env, Layer, Recipe                   Recipe gains `rate: int` (default 48000; OQ4)
  frames(r) ; envAt(e, t) ; phaseAt(l, t) ; layerSamples(l, n, loop, rate) ; render(r) -> [float]
  loopErrors(r) -> [string]
  parseRecipes(text) -> Result[[Recipe], string]               schema "sunholo.audio.recipes/1"
  parseRecipesAs(schema: string, text) -> Result[[Recipe], string]  the host names its own schema id (OQ5)
sunholo/audio/pcm
  pcm16(xs) -> bytes                        x * 32767, rounded, clamped (unchanged; see D5)
  type WavInfo = {rate, channels, bits, frames, dataOffset}
  wavInfo(b: bytes) -> Result[WavInfo, string]   RIFF/WAVE chunk walk, format tag 1 only
  pcm16Floats(b, info) -> [float]           s16 / 32768, mono or channel 0 (as sound_check.gd reads)
  wav16(xs, rate) -> bytes                  std/audio.wavFromPcm(pcm16(xs), rate, 1, 16)
sunholo/audio/mix
  tile(xs, loop, gain, n, starts: [int]) -> [float]   PR #319's semantics: a loop repeats from 0;
                                            a one-shot plays at each start, a later start cuts the earlier
  sum(parts: [[float]], n) -> [float]
sunholo/audio/analysis
  type Level = {peakCdb: int, rmsCdb: int, seconds: float}   centi-dB ints: no float printing noise
  peak(xs) ; rmsGated(xs, threshold) ; level(xs, gainDb) -> Level   (gate |x| > 0.001 after gain)
  highpassKeepDb(xs, cut, rate) -> float    RMS kept through a one-pole high-pass, dB of the whole
  lowbandDb(xs, cut, poles, rate) -> float  RMS through `poles` cascaded one-pole low-passes, dB of the whole
  seam(xs) -> {seam: int, maxStep: int}     int16 step across a loop's join vs the largest inside it
```

`[effects] max = ["IO"]`, used only by `_smoke.ail` to print its verdict (as `sunholo/celestial`). No FS: reading and writing files stays in the consumer's shell, which keeps the style section at 100% pure exports. `ailang = ">=0.54.14"`. No dependency on any other package; `std/audio` is stdlib.

Order of float operations is preserved exactly where code moves. Where the rate becomes a parameter, `intToFloat(i) / rate` with `rate = 48000.0` gives the same bits as today's `intToFloat(i) / rateF()`; the byte gate (AC6) proves it rather than trusting it.

### D3. What `std/audio` already does, and what is reported upstream

`std/audio` (unchanged since v0.44) writes the 44-byte RIFF header (`wavHeader`, `wavFromPcm`), `durationMs`, and a deterministic pure-Go Opus (`encode … OggOpus(bitrate)`). The package **calls** these and never re-implements them. Two gaps were reported on 2026-10-22 with `ailang messages` to `user` from `stapledons_godot` (GCP store; it opened **sunholo-data/ailang#1930**): (1) `std/audio` cannot read a WAV or decode PCM16; (2) `std/string` has no fixed-precision float formatter (`floatToStr(floor(-27.0612/0.01+0.5)*0.01)` prints `-27.060000000000002`). Until (1) lands upstream the package carries `wavInfo`/`pcm16Floats` (about 40 lines); when it lands, a later minor release delegates to std and keeps its signatures. (2) is why `Level` carries centi-dB integers.

### D4. Determinism and parity

- Every export is pure and total over its documented domain; no clocks, no randomness except the two index-and-seed generators.
- Package tests and `_smoke.ail` probes run on `--bytecode --strict-bytecode` and the interpreter, and their outputs are compared with `cmp` (as `sunholo/celestial`'s probes). Probes use short fixtures (a 0.25 s loop, a 0.1 s one-shot, 1 s analysis signals), because the interpreter is about 10× slower than the VM on a full file.
- Probes cover every module that touches bytes or floats: `renderProbe` (recipe, pcm), `wavProbe` (`wavInfo` and `pcm16Floats` over a WAV built in memory, so the `std/bytes` readers are exercised on the strict VM) and `levelProbe` (analysis).
- In the game, `make sound-synth-check` keeps its four steps with one change: `check --package tools/audio`; `verify` now targets the game's own pure module `tools/audio/levels.ail` (the deleted `synth.ail` was its only target; the package's contracts are verified in the package repo, AC1); the trimmed `synth_test` on the strict VM and the interpreter (byte-identical, `synth-ok 28ee28…`); and the regeneration of every WAV into scratch against the manifest.
- `levels_main.ail` reads files, so it runs on the plain VM; `make sound-levels` also runs `levels.ail`'s pure entry `levelsProbe` on a short in-memory fixture on the strict VM and the interpreter and compares them with `cmp`.

### D5. Contracts and tests

Contracts (Z3 proves what it can; PUB016 skips are expected for float maths and are fine, as in celestial): `clamp16` ensures the int16 range; `centiDb`, `frames` (requires `seconds >= 0`, ensures `result >= 0`); `onePole` requires `cut > 0 && rate > 0`; `wavInfo` returns `Err` instead of requiring; `tile` requires `n >= 0`; `level` requires a finite gain.

Package tests (`*_test.ail`, named `test "…"` blocks). Expected values are closed forms or published constants, never a module's own output, except two golden pins that guard bytes:
- dsp: `clamp16` edges; `dbToGain(-3)` = 0.70794578…; `onePole` against `1 − e^(−2π·150/48000)`; one-pole high-pass steady-state gain at 1 kHz against |H| = |1 − a/(1 − (1−a)e^(−jω))| computed in the test; `softSat(k, 1) = 1`.
- noise: determinism and seed sensitivity for both; `white` lag-1 |r| < 0.03 over 20,000 samples; `rampNoise` lag-1 |r| > 0.03 (its documented flaw must not silently change: that would change approved bytes).
- recipe: every check now in `synth_test.ail` (loop frames, seam ≤ max step + 1, one-shot peak −3 dBFS, starts and ends at silence, loop rules for sines, vibrato, beats and sweeps, drive keeps the peak, a 200 Hz → 8 kHz sweep brightens, empty and bad files refused, both schema ids); golden pin 1: the reference loop's PCM sha256 `28ee281f…7467` (moved from the game, so a maths change shows in the package first).
- pcm: `wavInfo` on `std/audio.wavFromPcm` output, on a file with a `LIST` chunk before `data`, and refusals (not RIFF, format tag 3); `pcm16Floats(pcm16(xs))` within 1/32767 + 1/32768 of xs (the encode uses ×32767 and the decode ÷32768, as the game and Godot do today; documented, see Risks); golden pin 2: the WAV bytes of the reference loop.
- mix: a loop tiles periodically; a one-shot at two starts plays twice and the later start cuts the earlier; gains in dB sum linearly.
- analysis: full-scale 1 kHz sine RMS = −2.83 dB (the gate's closed form above) and peak 0; a 60 Hz sine fails a −20 dB low-band guard and a 2 kHz sine passes it; high-pass keep of a 1 kHz sine against the closed-form |H|; `seam` of a sine with whole cycles is ≤ max step + 1 and of a cut sine is not.
- `_smoke.ail` prints `OK: …` when the reference pins and the analysis closed forms hold, plus `renderProbe` and `levelProbe` entries for the strict-VM/interpreter comparison.

### D6. Provenance in the game's manifest

`synth_main.ail` today hashes its own generator source file: its `Args` has a `generator` path, `mk/sound.mk`'s `SOUND_SYNTH_ARGS` passes `"generator":"tools/audio/synth.ail"`, and the shell reads and hashes that file. After the pin, `Args.generator` is replaced by `lock` (`"lock":"tools/audio/ailang.lock"` in `SOUND_SYNTH_ARGS`, which both `sound-synth` and the regeneration step of `sound-synth-check` use). The shell reads the lock with `std/fs`, and a pure function in `synth_main.ail` parses it with `std/json` (`packages[]` where `name == "sunholo/audio"`, taking `version` and `content_hash` without its `sha256:` prefix; a missing entry is a `FAIL`). The row records `generator: "sunholo/audio@<version>"` and `generator_sha256` = that hash. The `provenance` object keeps its three fields (`generator`, `generator_sha256`, `recipe`), so `SoundData.check_rows` and `tests/test_sound.gd` need no change. Only the `provenance` of synthesised rows changes in `assets_synth.json`; `id`, `path`, `bytes`, `sha256`, `frames` and `loop` do not (AC7).

### D7. Recipe schema and versioning

- Schema id `sunholo.audio.recipes/1`, documented field by field in AGENT.md (`id`, `seconds`, `loop`, `peak_db`, `fade_ms`, `swell{rate,depth}`, `drive`, `rate` (new, default 48000), `layers[]` with `kind` ∈ {`sine`, `noise`, `white`}, `freq`, `glide_to`, `glide_from_s`, `glide_until_s`, `amp`, `lowpass_hz`, `lowpass_to_hz`, `highpass_hz`, `seed`, `env{delay,attack,tau,stop}`, `vib_hz`, `vib_cents`, `beat_hz`, `beat_depth`). Every default is the no-op it is today.
- The game keeps its file and its schema id `stapledons.audio.recipes/1` and calls `parseRecipesAs("stapledons.audio.recipes/1", text)`, so `make sound-review V1_REF=<old ref>` still parses historical recipe files.
- **Render-stability contract** (AGENT.md and CHANGELOG): for a given recipe and `rate`, `render` and `pcm16` give the same bytes in every 0.x release unless that release's `[release] kind = "breaking"`. New fields must default to a no-op. 0.1.0 is `kind = "feature"`, stability `experimental`.

### D8. The game migration

1. `tools/audio/ailang.toml`: `[dependencies] "sunholo/audio" = "0.1.0"`; exports drop `stapledons/audio/synth`; add `levels`, `levels_main`. `ailang lock` writes `tools/audio/ailang.lock` (committed, as `tools/glow_probe`).
2. Before publishing, the execution branch pins `{ path = "<ailang-packages clone>/packages/audio" }` and must pass AC6, AC8 and AC9 locally (the pre-publish gate). A path pin works only on the machine that has that clone, so during AU1–AU3 **no PR is opened, no rig or CI run is requested, and `make deps` is not expected to pass**; the game PR opens at AU4, after the switch to the registry pin, and the path pin never reaches `main`.
3. Delete `tools/audio/synth.ail`. `synth_main.ail`, `review_main.ail` and `synth_test.ail` import `pkg/sunholo/audio/...`.
4. `make deps` also locks `tools/audio` (same `generated_at`-insensitive diff check as `sim/`), so CI and a clean rig fetch the package. `make runtime` is unchanged: the authoring tool is not bundled into the export.
5. `mk/sound.mk`: `SOUND_SYNTH_ARGS` passes `lock` instead of `generator` (D6); `sound-synth-check` verifies `tools/audio/levels.ail` instead of `synth.ail` (D4); new `sound-levels` and `sound-levels-parity` (D9), both added to `test:`.
6. `tools/python-allowlist.txt` unchanged; no `.py` is added anywhere, in either repo.

### D9. The loudness checks in AILANG

`tools/audio/levels.ail` (pure) reads the parsed `cues.json` (bands, `peak_max_dbfs`, each cue's bus, `volume_db`, `streams[0]`, its `param` curve) and the manifest paths, and applies the package's measures with the game's rules, exactly as `sound_check.gd` does offline today: level at `volume_db + max_param_db`; RMS inside the cue's band (or its bus's), peak ≤ `peak_max_dbfs`; `spire_hum` and `drive_boost` keep ≥ −6 dB through 150 Hz; `drive_boost`, `drive_silent`, `drive_brake` ≤ −20 dB under the 4-pole 120 Hz low band. Negative controls: the same `ui_click` cue 30 dB hot fails both its band and the ceiling; a 60 Hz + 300 Hz thud fails the teacup guard. `levels_main.ail` (FS) prints `sound-levels: N passed, 0 failures` and writes `levels.json` with centi-dB integers. The guarded cue lists move from GDScript literals into `cues.json` as a per-cue `guards` array only if Mark prefers data to code (not in this sprint; noted under OQ7).

`make sound-levels-parity` depends on `sound-check` (already in `make test`, and it writes `measure.json`) and `sound-levels`, so in `make test` it costs only the comparison. It compares, with `jq`, for **every cue** `round(100·rms_dbfs)` and `round(100·peak_dbfs)`, and `round(100·highpass150_keep_db)` and `round(100·below_200hz_db)` **for the cues that carry them** (today 2 and 3: `sound_check.gd` measures the laptop guard on `spire_hum`, `drive_boost` and the teacup guard on the three drive cues). It prints `sound-levels-parity: <cues> cues, <guards> guard values, 0 differences`, and fails naming the cue and field on any difference or on a cue present in one file and not the other. The 30 dB-hot `ui_click` negative control mirrors the one `sound_check.gd` already has (both its band and the ceiling fail); AU2 confirms it fails both in AILANG too.

## Acceptance criteria

Commands run from the game clone with `export PATH=$PWD/runtime/bin:$PATH`, `PKG=<ailang-packages clone>/packages/audio`, and `BASE` = the `origin/main` commit the execution branch starts from (after #319). The table names each criterion; the exact commands are in the block below it (kept out of the table so that pipes are real pipes).

| # | Criterion | Stage |
|---|---|---|
| AC1 | Package compiles, contracts verify with 0 refuted, quality has no gates | AU3 |
| AC2 | Package tests pass | AU1–AU3 |
| AC3 | Strict VM = interpreter on the package probes; `_smoke` prints `OK:` | AU3 |
| AC4 | Published and pinned from the registry | AU4 |
| AC5 | No in-tree copy of the core (with a positive control) | AU4 |
| AC6 | Every synthesised WAV regenerates byte for byte; strict VM = interpreter on the game's pin | AU1 (path pin), AU4 |
| AC7 | Only provenance changed in the manifest; the manifest check passes | AU4 |
| AC8 | AILANG loudness numbers equal the GDScript mirror for every cue and guard | AU2 (path pin), AU4 |
| AC9 | The offline loudness checks pass in AILANG; negative controls fail; `levels` strict VM = interpreter | AU2, AU4 |
| AC10 | The listening page renders the same audio (WAV and Opus) | AU4 |
| AC11 | No sim, Python or Godot sound-code change | AU4 |
| AC12 | The deps step locks the new package cleanly | AU4 |
| AC13 | Whole suite | AU4 |

```sh
# AC1
ailang check --package $PKG && ailang verify --package $PKG && ailang pkg quality $PKG | tee /dev/stderr | grep -q 'no gates'
# AC2
ailang test --package $PKG
# AC3
cd $PKG && for p in renderProbe wavProbe levelProbe; do
  cmp <(ailang run --quiet --relax-modules --bytecode --strict-bytecode --entry $p --args-json 0 _smoke.ail) \
      <(ailang run --quiet --relax-modules --entry $p --args-json 0 _smoke.ail) || exit 1; done
ailang run --quiet --relax-modules --caps IO --entry main _smoke.ail | grep -q '^OK:'; cd -
# AC4 (the search output format is confirmed at AU3, as for celestial)
ailang pkg search audio | grep -q 'sunholo/audio@0.5.0'
jq -e '.packages[] | select(.name == "sunholo/audio" and .version == "0.5.0" and .source == "registry")' tools/audio/ailang.lock
# AC5: the positive control proves the pattern can match; then nothing in the game defines the core
git -C $PKG/../.. grep -q -E 'func (layerSamples|rampNoise)\(' -- packages/audio
test ! -e tools/audio/synth.ail
! git grep -n -E 'func (white|noise|rampNoise|pcm16|layerSamples)\(' -- tools sim
# AC6
make sound-synth-check | grep -q '^sound-synth-check: synth-ok 28ee28 VM = interpreter; 28 sounds regenerate byte for byte$'
# AC7
diff <(git show $BASE:data/audio/assets_synth.json | jq -S 'del(.assets[].provenance)') \
     <(jq -S 'del(.assets[].provenance)' data/audio/assets_synth.json)
jq -e '[.assets[].provenance.generator] | unique == ["sunholo/audio@0.5.0"]' data/audio/assets_synth.json
make sound-assets-check
# AC8
make sound-levels-parity | grep -q ', 0 differences$'
# AC9
make sound-levels | grep -q '^sound-levels: [0-9]* passed, 0 failures$'
# AC10 (as built: no fixture; render BASE in its own clone with its own runtime, then compare)
make sound-review SOUND_REVIEW_OUT=$PWD/build/review_pkg   # on this branch; on BASE: SOUND_REVIEW_OUT=<base>/build/review_base
diff <(cd <base>/build/review_base && shasum -a 256 *.wav *.ogg | LC_ALL=C sort -k2) \
     <(cd build/review_pkg && shasum -a 256 *.wav *.ogg | LC_ALL=C sort -k2)
# AC11
test -z "$(git diff --stat $BASE -- sim/ audio/ tools/python-allowlist.txt)" && make python-guard
# AC12
make deps
# AC13 (rig)
tools/rig_check.sh
```

## Sub-milestones and estimates

| Id | What | LOC | Days | Depends |
|---|---|---|---|---|
| AU0 | Baseline on the base commit: `make sound-synth-check` (stop if it does not print 28 sounds), `make sound-check` (keep `measure.json`), `make sound-review` → `tests/fixtures/sound/review_sha256.txt` (WAV and Opus); re-read #319's merged `review_main.ail` (the `at` semantics `mix.tile` copies); the four measures re-run on all 28 sounds | 20 | 0.5 | #319 merged, plan approved |
| AU1 | Package core in `ailang-packages/packages/audio`: `dsp`, `noise`, `recipe`, `pcm`, `mix`, tests red first; the game branch on a path pin passes AC6 | 410 + 220 tests | 1.5 | AU0 |
| AU2 | `analysis` + tests; game `levels.ail`/`levels_main.ail`, `make sound-levels` and `sound-levels-parity` on the path pin (AC8, AC9) | 110 + 110 tests + 230 game | 1 | AU1 |
| AU3 | `_smoke.ail`, AGENT.md, CHANGELOG, `ai_summary`, contracts; AC1–AC3; publish 0.1.0 (standing approval) | 70 + 250 prose | 0.75 | AU2 |
| AU4 | Game switches to the registry pin: lock, `make deps`, delete `synth.ail`, provenance (D6), regenerate the manifest part, open the game PR, AC4–AC13 | 80, −300 | 0.75 | AU3 |
| AU5 | Independent evaluation (a different model), landing (doc to `implemented/`, changelog fragment, index row) | — | 0.5 | AU4 |

About **5 working days** for about 1,500 LOC (prose included), 300 deleted: about 300 LOC/day, the recent attended R2 rate.

Design sections by sub-milestone: D1, D2, D3, D5, D7 → AU1 (D2's `analysis` → AU2); D9 → AU2; D4 throughout (probes at AU3); D6, D8 → AU4.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| A refactor changes float operation order and one WAV's bytes | Code moves verbatim first (AU1 opens with a pure move and the byte gate), generalisation (the `rate` parameter) second, each followed by AC6 on the path pin before anything is published. Adding `rate` to `Recipe` breaks every record literal that builds one (the trimmed `synth_test.ail` and the package tests build `Recipe`s field by field): step 1 keeps the old record shape, step 2 adds `rate: 48000` to each literal |
| #319 (S1) or S2 change `tools/audio` while this runs | Start after #319 merges; S2 adds recipes (data) only, which need no code change; if S2 needs a new synthesis feature it lands in the package as 0.2.0 |
| The ×32767 encode vs ÷32768 decode asymmetry looks like a bug and someone "fixes" it | Documented in AGENT.md as the convention of the shipped bytes (encode) and of Godot's reader (decode); changing the encode is a `breaking` release under D7 |
| The interpreter is about 10× slower than the VM on full files | Parity runs on short fixtures; full-file work runs on the VM (as today) |
| GDScript and AILANG `log`/`exp` differ in the last ulp and a value sits on a 0.005 dB rounding edge | Measured identical for six sounds; AU0 re-runs the spike on all 28; if a single cell differs by one centi-dB the parity check reports it and we compare unrounded values to 1e-9 instead (decided at AU2, recorded) |
| `ailang pkg quality` flags something new on v0.54.14 | Run it at AU1 on the skeleton, not first at AU3 |
| Publishing is irreversible | Publish only after the path-pin gate is green (AC6–AC9 on unpublished code); the standing approval covers `sunholo/*` packages |

## Open questions for Mark

| # | Question | Recommendation |
|---|---|---|
| OQ1 | Package name: `sunholo/audio` or `sunholo/synth`? | **`sunholo/audio`.** It holds synthesis, mixing, PCM/WAV reading and loudness analysis; `synth` would be wrong for half of it. Modules are `sunholo/audio/…`, distinct from `std/audio` |
| OQ2 | Is the loudness analysis in scope, and what happens to the GDScript copy? | **In scope.** AILANG becomes the source of the offline checks (`make sound-levels`); `sound_check.gd` keeps its four offline functions as the second-language mirror checked by `sound-levels-parity`, and keeps all mixer checks |
| OQ3 | Include a QOA encoder? | **No.** Godot's import compresses to QOA (D-112) and the game ships Godot's resource; an AILANG encoder would have to match Godot's decoder for no gain today. Revisit if a non-Godot consumer needs QOA |
| OQ4 | Fixed 48 kHz or a `rate` per recipe? | **A `rate` field, default 48000**, so other consumers can render 24 kHz (speech beds, smaller loops); the game's recipes omit it and keep their bytes |
| OQ5 | Recipe schema id | **Package id `sunholo.audio.recipes/1`, plus `parseRecipesAs` so the game keeps `stapledons.audio.recipes/1`** and historical recipe files (V1_REF A/B) still parse |
| OQ6 | Provenance of synthesised rows | **`sunholo/audio@<version>` and the lock's `content_hash`**, replacing the source path and file hash |
| OQ7 | Should the guarded cue lists (which cues get the laptop and teacup guards) move from code to `cues.json`? | **Not now**: keep them in `levels.ail` as `sound_check.gd` has them; a data field is a separate cue-table change |
| OQ8 | Rename the legacy generator to `rampNoise` in the package? | **Yes**: the package is new, so the honest name costs nothing; the recipe kind string stays `"noise"` so no data changes |

## Deliverables

- `sunholo-data/ailang-packages` `packages/audio/`: `ailang.toml`, `dsp.ail`, `noise.ail`, `recipe.ail`, `pcm.ail`, `mix.ail`, `analysis.ail`, one `*_test.ail` per module, `_smoke.ail`, `AGENT.md`, `CHANGELOG.md`; published `sunholo/audio` 0.1.0.
- This repo: `tools/audio/ailang.toml` + `ailang.lock` (pin), `synth_main.ail` (`Args.lock`, provenance from the lock), `review_main.ail`, `synth_test.ail` (trimmed), `levels.ail`, `levels_main.ail`; `tools/audio/synth.ail` deleted; `mk/sound.mk` (`SOUND_SYNTH_ARGS` with `lock`, `verify` on `levels.ail`, `sound-levels`, `sound-levels-parity`, both in `test:`), `Makefile` `deps`; `data/audio/assets_synth.json` (provenance only); a changelog fragment (as built: no review fixture, see §As built); this doc moved to `implemented/r2/` with a report.
- The design spike (`tools/audio_spike/`, never committed) was deleted after it ran; its numbers are in §Evidence.
