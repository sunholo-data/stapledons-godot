# R3-SUNHOLO-AUDIO-REALISM: `sunholo/audio` 0.6.0, closer-to-real synthesis

**Status:** Implemented 2026-10-30 (game PR #361, package PR sunholo-data/ailang-packages#172; `sunholo/audio` 0.6.0 and 0.6.1 published). Approved by Mark 2026-10-30 ("looks great go on audio and then lets preview the new sounds"), OQ1–OQ8 at their recommendations. Report: [sunholo-audio-realism-report.md](sunholo-audio-realism-report.md); evaluation 83/100 PASS.
**Release:** R3. **Milestone:** a tooling release under R3-EARTH-LINK EL3b.7 (the comms station's "sound from home") and R2-SOUND route A (AILANG synthesis).
**Priority:** P2. It makes the 13 home sounds sound more like home. Every later synthesised sound (rain, voices, bells, the dome's echo) gets the same tools.
**Origin:** Mark, 2026-10-30, after listening to the home beds (EL3b.7 v2): *"they are nice, not really realistic sounding but spooky and unique enough to include - but yeah if we can get closer to real sounding effects etc why not try it"*. He had already agreed that the package should gain tools beyond tones and noise.

**Implements:**
- This repo: [earth-link.md](earth-link.md) row "Sound from home" (EL3b.7: a room of voices and a tune, wind and birds, bells over a street, a crowd far off, a lab's pips, night air and crickets, the torrent's babble, the static); [sound.md](../../planned/r2/sound.md) §D3 (the canon: diegetic, instruments may sonify, no judgement), §D7 (no stingers), §D8 (route A synthesis, `synth-own`; route C generated sound stays off, D-101), §D9 (`make sound-synth-check`).
- The package process of [sunholo-audio.md](../../implemented/r2/sunholo-audio.md) (R2-SUNHOLO-AUDIO, D-119, D-124): pure exports, strict VM = interpreter, the render-stability contract, a path pin before publishing, the game's byte gate.
- Design repo: no change. Sound is not physics: no physics-spec row, and CLAUDE.md gate 2 does not bind. The acoustic models used here are textbook (§D1 to §D6 cite them).

**Depends on:**
- **PR #344 (R3-EARTH-LINK, branch `feat/earth-link`) merged first** for the game half (AR8 onward). The 13 `home_*` recipes exist only on that branch today (head `67dc0842`, "home beds v2, less hiss"). The package half (AR0 to AR7) does not wait for it.
- `sunholo/audio` 0.5.0 (`sunholo-data/ailang-packages` `packages/audio`, PRs #154 and #167), AILANG **v0.54.18** (the pinned runtime). AILANG prompt loaded for the signatures below: **v0.16.7** (`ailang prompt --version-active`).
- Mark's standing approval to publish `sunholo/*` packages (memory: publish standing approval; never crew_lab). Publishing happens at step AR9, not in this design task.

**Estimated LOC:** about **2,700**. Package about 2,230: code 1,230 (filter 150, noise colours 50, osc 230, the `sound` front end with a 10-line `recipe.finish` export 390, events 120, space 110, the compat fixture and timing probe 90, `_smoke` probes 90), tests 750, prose 250 (AGENT.md, README, CHANGELOG). Game about 490: the shells switched to the new entry points 60, the re-voiced recipes about 350 lines of JSON, the synth_test pin, the registry pin and lock 80.

## Game vision alignment

Scored with the `game-vision-designer` skill (feature-validation mode) against `vision/core-pillars.md` (last changed 2026-09-27), the sound canon (sound.md §D3, §D7) and D-101 (no generated sound yet). **ALIGNED.**

| Pillar | Score | Rationale |
|---|---|---|
| Choices Are Final | 0 | No change to the commit or any decision flow |
| The Game Doesn't Judge | 0 | No new cue. The re-voiced crowd neither cheers nor jeers and the bells are not a reward (§D7's forbidden words still checked by `make sound-test`) |
| Time Has Emotional Weight | +2 | The home sounds are what the crew loses. A room of real-sounding voices, a garden's birds and a town's bells make the loss land. Slowed and deepened by the Earth rate, a believable sound going strange carries more weight than an abstract one |
| The Ship Is Home | +1 | The comms station becomes the place you go to hear home. The same tools later give the 100 m dome a real echo and softer foley (candidates in §D8, not in this sprint) |
| Grounded Strangeness | +1 | Real acoustics, not effects: a plucked string is a physical model (Karplus–Strong), a raindrop rings at its bubble's Minnaert frequency, a cricket's chirp is a pulse train, a far crowd loses its highs and gains a room. The strangeness comes from the Earth rate, which is honest |
| We Are Not Built For This | +1 | Voices from home you can hear but never understand (murmur, never words, sound.md §D3) |
| **Net** | **+5** | **Go.** No pillar is negative. One risk to the tone: Mark liked the beds for being "spooky and unique", so every re-voiced sound keeps its v2 beside it, and he picks per sound (pause point P2) |

## Problem

1. **The package has two sources: sines and noise.** Every 0.5.0 layer is a sine (with glide, vibrato and a beat) or white or legacy noise, through one-pole filters (`lowpass_poles` 1 to 4 in series) and a one-pole high-pass. One-pole filters cannot make a resonance. So a voice has no formants, a bell no inharmonic shimmer from its strike, a string no pluck. The home beds use what there is: `home_family` is four white-noise bands with amplitude beats, `home_world` three. They read as "filtered hiss with a pulse", which is what Mark heard.
2. **Loops cannot hold events.** `loopErrors` refuses envelopes and glides on loop sines, and every loop sine must complete whole cycles. That rule keeps loops click-free, but it means a bed cannot contain a raindrop, a footstep, a word or a chirp. EL3b.7 works around it with separate one-shot accents (`home_family_tune`, `home_home_birds`, `home_town_bells`, `home_world_swell`, `home_science_pips`). Rain, chatter, crackle and crickets need events inside the loop.
3. **Only white noise.** Real air, wind, rooms and distant traffic are pink to brown (energy falling with frequency). A white noise through one pole still has a white floor above its corner (AGENT.md: "a single pole on white noise keeps much of its energy above 2 kHz"), which is the hiss Mark called out twice ("they all seem to include noise in background", v2).
4. **No distance.** A crowd "far off" and bells "across the town" have no room around them: no pre-delay, no reverberant tail, no air absorption beyond a low-pass.

### Evidence: the 0.5.0 render rate (measured 2026-10-30)

Measured on the Studio (Apple M4 Max), AILANG v0.54.18 pinned runtime, `sunholo/audio` 0.5.0 from the registry cache, strict VM (`--bytecode --strict-bytecode`), a throwaway probe package (scratch, not committed) that parses one recipe from `feat/earth-link`'s `data/audio/recipes.json` and prints the WAV sha256. Parsing alone takes 0.04 s. Every WAV sha256 equals the manifest row in `data/audio/assets_synth.json`.

| Recipe | Audio | Layers | Strict VM | Per audio second |
|---|---|---|---|---|
| home_science (loop: 4 sines, 1 white, 2 poles) | 5 s | 5 | 1.66 s | 0.33 s |
| home_family (loop: 4 white, 3 poles + high-pass, beats) | 5 s | 4 | 2.60 s | 0.52 s |
| home_town_bells (one-shot: 11 sines, 2 white) | 5 s | 13 | 3.42 s | 0.68 s |
| spire_drift (loop: 9 sines, 1 white) | 32 s | 10 | 20.38 s | 0.64 s |
| **All 13 `home_*` recipes** | **59 s** | 54 | **22.05 s** | **0.37 s** |

- About **50 to 65 ms of strict-VM time per layer-second** at 48 kHz (1.0 to 1.4 µs per layer-sample); a loop's noise layer costs two passes.
- The interpreter is **45× slower** than the VM on home_science (74.65 s against 1.66 s; the R2 note said about 10×). Parity probes therefore use 0.05 to 0.25 s fixtures.
- The 0.5.0 package suite: `ailang test --package .` gives 198 passed in 68 s. `ailang pkg quality --no-run` reports no gates (interface v2, 154 signatures, `kind breaking`).

The budgets in §D9 are stated against these numbers.

## Goals and non-goals

**Goals**
- G1. `sunholo/audio` **0.6.0**, `[release] kind = "feature"`. Six new tools (§D1 to §D6): a resonant state-variable filter and formant banks; pink and brown noise; FM operators; a Karplus–Strong pluck; events inside loops; a short Schroeder reverb for distance.
- G2. **Render stability, proven three ways.** Every 0.5.0 signature is unchanged (interface check). Every 0.5.0 recipe gives the same bytes through the new front end (package compat pins). The game's 41 sounds regenerate byte for byte on the 0.6.0 pin before any recipe changes.
- G3. The 13 `home_*` sounds re-voiced with the new tools, played to Mark on a review page beside their v2, kept or reverted per sound by his ruling.
- G4. The package's usual gates: tests, strict VM = interpreter on every new probe, contracts where Z3 can encode them, AGENT.md, CHANGELOG, `ailang pkg quality` with no gates, publish, then the game pins 0.6.0 and `make sound-synth-check` regenerates byte for byte.

**Non-goals**
- Re-voicing the bridge sounds. Mark approved them by ear (D-108, D-112, D-124). §D8 lists the candidates for a later pass, with his go.
- Generated or AI sound (D-101), CC0 field recordings for the home beds (OQ4 asks), speech or words of any kind, stereo rendering (the recipe renderer stays mono), resampling, realtime synthesis.
- Changing the loop lengths, the cue table, the director, the Earth-rate pitch mapping, the buses or the export. The re-voiced sounds keep each recipe's `seconds`, so the WAV bytes in git stay at 18.10 MB of the 20 MB budget (`data/audio/assets.json` `budget_bytes`).
- Any sim, protocol or replay change. No Python is added to either repo (a throwaway spike computed some check values; §D10).

## Design

### D0. Shape of the release: additive, so `feature` and not `breaking`

0.5.0 was `breaking` only because `recipe.Layer` gained a field (`lpPoles`), which breaks code that builds `Layer` records. 0.6.0 needs many new fields, so it **does not touch the 0.5.0 types**. The `recipe` module keeps every type and signature. A new module, `sunholo/audio/sound`, holds the richer description and its parser and renderer:

- A 0.6 **sound** is a 0.5.0 `Recipe` (`base`: id, seconds, loop, peak, fade, swell, drive, rate) plus a list of **parts** in file order.
- A part is either `Classic(Layer)`, a 0.5.0 layer rendered by `recipe.layerSamples` unchanged, or one of the new parts.
- **When every part is `Classic`, `renderSound(s)` is `recipe.render(s.base)`**, the same call. Byte identity for old recipes is then true by construction, and the compat pins (AC4) and the game's byte gate (AC9) prove it.
- When any part is new, `renderSound` sums the parts in file order into an array and hands it to the same post-chain as 0.5.0 (drive, swell, edges, peak normalisation). That chain is moved into an exported `recipe.finish(r, summed)` that `render` itself calls, with no change to any expression (AGENT.md: "do not tidy operation order").

**JSON.** The schema id stays `sunholo.audio.recipes/1`, and the game keeps `stapledons.audio.recipes/1` through `parseSoundsAs`. All new fields are **layer-level**. 0.5.0 made layer keys a closed vocabulary, so a file using a 0.6 field is *refused* by 0.5.0 (`layer: unknown key bands`) and never silently rendered differently. Recipe-level keys stay open in 0.5.0, so 0.6.0 adds none: an ignored recipe-level `reverb` would have been the silent failure 0.5.0 closed. `parseRecipesAs` keeps 0.5.0's vocabulary and refuses the new keys. Its message names `parseSoundsAs`.

```ailang
module sunholo/audio/sound
-- Types (sketch; final shapes fixed at AR4). Leaf parts can appear inside an event voice; Events cannot (depth 1).
export type Space = {t60: float, dampHz: float, predelayMs: float, wet: float}               -- wet 0 = off
export type Extra = {bands: [Band], vowel: string, vowelTo: string, jitterCents: float, jitterHz: float, space: Space}
export type FmVoice = {freq: float, ratio: float, index0: float, index1: float, indexTau: float}
export type PluckVoice = {freq: float, t60: float, bright: float, pick: float}
export type Leaf = Classic(Layer) | Shaped(Layer, Extra) | Fm(Layer, FmVoice, Extra) | Pluck(Layer, PluckVoice, Extra)
export type Voice = {seconds: float, fadeMs: float, parts: [Leaf]}
export type Times = Fixed([float]) | Scatter({count: int, seed: int, spread: float, minGap: float})
export type Vary = {ampDb: float, cents: float, cycle: bool}
export type EventLayer = {voices: [Voice], times: Times, vary: Vary, amp: float, seed: int}
export type Part = Leaf(Leaf) | Events(EventLayer, Extra)
export type Sound = {base: Recipe, parts: [Part]}
export type SoundLimits = {render: RenderLimits, maxEvents: int, maxEventFrames: int, maxWorkFrames: int}

export pure func defaultSoundLimits() -> SoundLimits
export pure func parseSoundsAs(schema: string, text: string) -> Result[[Sound], string]
export pure func parseSounds(text: string) -> Result[[Sound], string]
export func parseSoundsChecked(text: string, limits: SoundLimits) -> Result[[Sound], AudioError] ! {}
export func validateSound(s: Sound) -> Result[Sound, AudioError] ! {}
export pure func soundLoopErrors(s: Sound) -> [string]          -- recipe.loopErrors(base) ++ the 0.6 rules (§D7)
export pure func soundFrames(s: Sound) -> int                    -- frames(s.base)
export pure func classicOnly(s: Sound) -> bool
export pure func renderSound(s: Sound) -> [float]                -- classicOnly: recipe.render(s.base), else finish(s.base, sum of parts)
export func renderSoundChecked(s: Sound, limits: SoundLimits) -> Result[[float], AudioError] ! {}
```

`Classic`, `Leaf` and `Events` share no name with 0.5.0 exports (MOD015). If AILANG v0.54.18 refuses a constructor named like its type (`Leaf(Leaf)`), the wrapper becomes `Single(Leaf)`. AR4 settles it.

### D1. A resonant filter: the state-variable filter and formant banks

**Model.** The topology-preserving state-variable filter (Zavalishin, *The Art of VA Filter Design*, ch. 4; the Simper/Cytomic "SvfLinearTrapOptimised2" form). It gives low-pass, band-pass, high-pass and notch from one recurrence and stays stable when its cutoff moves, which a formant glide needs. With fixed parameters its response is the bilinear transform of the analog prototype, prewarped at the centre. That is the same response as the RBJ cookbook biquad, so the check values are closed forms.

```ailang
module sunholo/audio/filter
export type SvfMode = BandPass | LowPass2 | HighPass2 | Notch deriving (Eq)
export type Band = {hz: float, hzTo: float, q: float, gain: float}     -- hzTo = hz: fixed
-- |H(e^{j 2 pi f / rate})| in closed form: W = tan(pi f / rate) / tan(pi hz / rate); band-pass 1 / sqrt(1 + q^2 (W - 1/W)^2).
export func svfGain(mode: SvfMode, hz: float, q: float, rate: float, f: float) -> float ! {}
requires { hz > 0.0 && hz < rate / 2.0 && q > 0.0 && f > 0.0 && f < rate / 2.0 }
export pure func svf(mode: SvfMode, hz: float, q: float, rate: float, xs: [float]) -> [float]       -- from rest
export pure func svfSweep(mode: SvfMode, hz0: float, hz1: float, q: float, n: int, rate: float, xs: [float]) -> [float]   -- exponential, as sweepLowpass
export pure func bank(bands: [Band], n: int, rate: float, xs: [float]) -> [float]   -- parallel band-passes, gains, summed in list order
export pure func vowelBands(v: string) -> [Band]   -- "a" "e" "i" "o" "u": F1-F3 (Peterson and Barney 1952, adult male means), bandwidths 80/100/120 Hz
```

- The band-pass is the constant-peak form (0 dB at the centre for every Q). A band's `gain` scales it.
- `vowelBands` fixes the formants: i 270/2290/3010, e 530/1840/2480, a 730/1090/2440, o 570/840/2410, u 300/870/2240 Hz. A murmur is a buzz or breath through these, the vowel changing per syllable (§D5).
- **JSON** (any 0.6 source kind): `"bands": [{"hz": 700, "q": 6, "gain": 1, "hz_to": 900}]` (`q` default 0.7071, `gain` 1, `hz_to` = `hz`), or `"vowel": "a"` with an optional `"vowel_to": "i"` (a straight-line move of each formant over the sound). `bands` with `vowel` is refused. Absent: no stage at all.
- **Stage order in a 0.6 layer:** source → the 0.5.0 low-pass chain and high-pass, if set → bands → amp × envelope × beat → space (§D6). The space comes last, so a tail rings on after its envelope ends, as a room does.
- **0.5.0 trap, kept:** in a `Classic` sine layer `lowpass_hz` does nothing (0.5.0 filters only noise). In a `Shaped` layer every stage acts on every source. AGENT.md says so.

**Check values** (AR1 tests; numbers from the closed form at 48 kHz):

| Case | Expected | Tolerance |
|---|---|---|
| band-pass, 1 kHz, Q 2: steady-state RMS gain of a sine at 1 kHz | 0.000 dB | ±0.02 dB |
| same, at 500 Hz / 2 kHz (±1 octave) | −10.014 dB / −10.056 dB (analog −10.000; the bilinear warp steepens the upper octave) | ±0.05 dB |
| band-pass, 1 kHz, Q 0.7071, ±1 octave | −3.282 dB / −3.307 dB | ±0.05 dB |
| band-pass, 3 kHz, Q 8, ±1 octave | −21.753 dB / −22.182 dB | ±0.05 dB |
| `svfGain` against the measured gain, 20 random (hz, q, f) from a seeded generator | equal | ±0.05 dB |
| low-pass + band-pass + high-pass reconstructs the input (the SVF identity; the band-pass is the constant-peak form) | equal | 1e-9 |
| a fixed sweep (`hz_to` = `hz`) equals `svf` | bit-identical | exact |
| `vowelBands("a")` | three bands at 730, 1090, 2440 Hz | exact |

Steady state means after 10 ring times (τ = Q / (π·hz)), measured over whole cycles.

### D2. Pink and brown noise

- **Pink:** white (the existing `white(i, seed)`) through Paul Kellet's refined filter (seven first-order sections; ±0.05 dB of a −3.01 dB/octave slope from 9.2 Hz to Nyquist at 44.1 kHz, documented in the music-dsp archive). Pink has equal power in every octave, which is what rooms, rain and wind sound like.
- **Brown:** white through a one-pole low-pass at 20 Hz (`onePole(20, rate)`), −6.02 dB/octave above it. A leaky integrator, so it never drifts.
- **Level:** each colour is scaled so its RMS matches white's, 1/√3 within 10%. Brown's scale is the closed form √((2 − a)/a) for the pole's coefficient a. Pink's is a constant fixed at AR2 (the spike found an unscaled RMS of 1.70, so about 0.34).
- **JSON:** `"kind": "pink"` or `"kind": "brown"`, with the same fields as `white`. In a loop they use the 0.5.0 rule for noise: generator index i mod n, filters run over two periods, keep the second.

```ailang
-- additions to sunholo/audio/noise (white and rampNoise unchanged)
export pure func pinkOf(xs: [float]) -> [float]              -- Kellet refined, scaled to white's RMS
export pure func brownOf(rate: float, xs: [float]) -> [float] -- onePole(20 Hz) with the closed-form RMS scale
```

**Check values** (AR2). The PSD slope is fitted over six octave-spaced Goertzel bins, 93.75 to 3,000 Hz: 4,096-sample Hann segments, 24 segments (2 s), least squares over the six points. The Goertzel helper lives in the test file (30 lines) and is independent of §D1's filter. A throwaway spike with the same method measured: white −0.24, pink −3.05, brown −6.04 dB/octave.

| Colour | Expected slope | Tolerance |
|---|---|---|
| white | 0 dB/octave | ±0.5 |
| pink | −3.01 dB/octave | ±0.5 |
| brown | −6.02 dB/octave | ±0.5 |

Also: RMS within 10% of 1/√3; same seed gives the same samples, another seed others; a 1 s pink loop's `analysis.seam` ≤ max step + 1.

### D3. FM operators: bells and chimes

**Model.** Two-operator phase modulation (Chowning 1973): `x(t) = sin(2π fc t + I(t) sin(2π r fc t))`, with the index decaying from `I0` to `I1` with time constant `τI`. A bell's brightness dies faster than its loudness, which is what makes it a bell. Chowning's bell is r = 1.4, I0 = 10 → 0 over the note. The phase is a closed form in t = i / rate, with no running sum, so it is as deterministic as today's sines.

```ailang
-- sunholo/audio/osc
export pure func fmIndexAt(v: FmVoice, t: float) -> float      -- index1 + (index0 - index1) exp(-t / indexTau); indexTau 0 = constant index0
export pure func fmSamples(v: FmVoice, n: int, rate: int) -> [float]
```

**JSON:** `"kind": "fm"`, `"freq"` (the carrier), `"ratio"` (modulator = ratio × freq), `"index"`, `"index_to"` (default `index`), `"index_tau"` (default 0), plus the 0.5.0 `amp`, `env`, `beat_*`, filters, and the 0.6 extras.

**Check values** (AR3): with a constant index each sideband `fc + k·r·fc` has amplitude |J_k(I)| (the Bessel function, computed in the test by its series). As built, fc = 6,000 Hz and r = 0.1 (sidebands every 600 Hz). The planned fc 2,400 Hz, r 0.25 failed at I = 2, because J_5 folds through 0 Hz onto the k = −3 line. A 1 s window puts each line on a whole number of cycles:

| I | k = 0 | ±1 | ±2 | ±3 | Tolerance |
|---|---|---|---|---|---|
| 1 | 0.7652 | 0.4401 | 0.1149 | 0.0196 | ±0.002 |
| 2 | 0.2239 | 0.5767 | 0.3528 | 0.1289 | ±0.002 |

Also: with I = 0, `fm` equals a 0.5.0 sine of the same freq and amp to 1e-12; a decaying index lowers the energy above fc + 2·r·fc between 0.1 s and 1 s (a monotone check).

### D4. Karplus–Strong pluck: a believable harp, guitar or music box

**Model.** Karplus and Strong (1983), with Jaffe and Smith's (1983) loss and tuning extensions. A burst of seeded white noise one period long fills a delay line of N samples. Each pass, adjacent samples are averaged (the half-sample loop filter), scaled by ρ = 10^(−3 / (f0 · t60)) so the note decays by 60 dB in `t60` seconds, and passed through a first-order allpass that supplies the fractional delay. Without the allpass the pitch is rate / (N + 0.5): 9.4 cents sharp at 440 Hz, 14 cents at C6.

- `bright` (0..1) low-passes the excitation (dark nylon to bright steel). `pick` (0..0.5) combs the excitation at that fraction of the string (a pick near the bridge is thin; 0 is off).
- **Implementation, blocked delay line:** the output is computed one period (N samples) at a time, each block a `mapAccumL` over the previous block, carrying the allpass state. It needs no mutable array and runs in O(n) on the strict VM. The arithmetic per sample is the textbook recurrence in the same order, so a per-sample reference (an `Array` ring, in the test only) must agree bit for bit.

```ailang
export type Period = {n: int, c: float}                          -- integer delay and allpass coefficient
export func pluckPeriod(freq: float, rate: int) -> Period ! {}
requires { freq >= 20.0 && freq <= 4000.0 && rate > 0 }
export pure func pluckSamples(v: PluckVoice, seed: int, n: int, rate: int) -> [float]
```

**JSON:** `"kind": "pluck"`, `"freq"`, `"t60"` (default 1.5 s), `"bright"` (0.5), `"pick"` (0), `"seed"`, `"amp"`, `"env"` (usually none), filters and extras. No glide or vibrato on a pluck (refused).

**Check values** (AR3). The fundamental is estimated by the autocorrelation peak with parabolic interpolation over 0.1–0.6 s. A spike of this model measured:

| Target | Untuned (N + 0.5) | Tuned | Tolerance |
|---|---|---|---|
| A2 110 Hz (N = 435) | +3.43 cents (textbook +3.43) | +0.01 cents | tuned ±1 cent; untuned within 0.5 cent of rate / (N + 0.5) |
| A4 440 Hz (N = 108) | +9.42 (textbook +9.40) | −0.03 | same |
| C6 1046.5 Hz (N = 45) | +14.13 (textbook +13.91) | +0.85 | same |

Also: the RMS envelope falls 60 dB in `t60` within 10% (Schroeder backward integration between −5 and −35 dB, extrapolated); the blocked form equals the per-sample reference exactly; the same seed gives the same note.

**The music box.** A real music box is a struck steel comb: inharmonic cantilever-beam modes at 1 : 6.27 : 17.55 of the fundamental, decaying fast. That needs no new tool. It is sine layers at those ratios, with an FM or pluck attack transient for the strike. AR8 renders both takes of `home_family_tune` (beam modes, and a pluck "harp") for Mark to choose (OQ5).

### D5. Events inside loops: rain, chatter, crackle, birds in a bed

An **event layer** places short one-shot **voices** at fixed or seeded times. In a loop the output is defined on the circle of n samples: an event that starts near the end wraps its tail to the start. So the loop is exactly periodic by construction, whatever the event does (envelopes, glides, plucks, FM index decays, jitter). This lifts the 0.5.0 rule "a loop cannot have envelopes" for everything inside an event.

```ailang
module sunholo/audio/events
-- Starts in [0, n), in event order k = 0..count-1. Scatter: a jittered grid, slot k = [k n / count, (k + 1) n / count),
-- start = slot start + floor(u_k * spread * (slot - minGap)), u_k from white(k, seed) in integer arithmetic.
export pure func scatterStarts(count: int, seed: int, spread: float, minGap: int, n: int) -> [int]
export pure func fixedStarts(times: [float], rate: int) -> [int]
-- Sum event sample lists at starts over n samples, in event order; wrap: index (s + j) mod n (std/array scatterAdd, one copy per event).
export pure func place(evs: [[float]], starts: [int], n: int, wrap: bool) -> [float]
export type Variation = {gain: float, ratio: float, voice: int}
export pure func variation(seed: int, k: int, ampDb: float, cents: float, voices: int, cycle: bool) -> Variation
```

**JSON:**

```json
{"kind": "events", "amp": 0.6, "seed": 41,
 "voices": [{"seconds": 0.03, "fade_ms": 10, "layers": [{"kind": "sine", "freq": 3260, "glide_to": 3900, "glide_until_s": 0.02, "amp": 0.5, "env": {"attack": 0.0005, "tau": 0.006}},
                                                       {"kind": "pink", "amp": 0.2, "bands": [{"hz": 3000, "q": 2}], "env": {"tau": 0.002}}]}],
 "scatter": {"count": 600, "spread": 1.0, "min_gap_s": 0.001},
 "vary": {"amp_db": 9, "cents": 300},
 "space": {"t60": 0.6, "damp_hz": 4000, "wet": 0.25}}
```

(That is rain: 120 drops a second on a 5 s loop, each a Minnaert bubble ring. A 1.0 mm-radius bubble rings near 3.3 kHz, f ≈ 3.26 / r Hz·m, with a tick of filtered air.)

- `times` (seconds, fixed) or `scatter` (`count`, `spread` 0..1, `min_gap_s`), not both. `voices`: one or more one-shot voices, each with `seconds`, `fade_ms` (default 5) and `layers` (any leaf part: 0.5.0 kinds, the 0.6 kinds and extras; no nested `events`).
- `vary`: per event, a gain uniform in ±`amp_db`, a pitch ratio uniform in ±`cents` applied to the voice's source frequencies (freq, glide_to, FM carrier, pluck freq) but not to its filters (formants stay put when a speaker's pitch moves), and the voice picked by seed (`"cycle": true` takes them in turn).
- **Seeds:** event k's noise and pluck seeds are `seed + 1009·k` added to each layer's own seed, documented. Variation draws use `white(k, seed + 7)`, `white(k, seed + 11)` and `white(k, seed + 13)`, in integer arithmetic until the final scale.
- **Each voice** renders as a one-shot (2 ms fade-in, its `fade_ms` fade-out, no normalisation; `amp` sets its level) and is cut at its `seconds`. An event layer's samples are then scaled by its `amp`, given its extras (bands, space) and summed with the other parts.
- **Talkers** (the murmur): a voice of `kind: "saw"` (a polyBLEP sawtooth, the glottal buzz; `jitter_cents` and `jitter_hz` give a seeded, smoothly drifting pitch) through `vowel` → `vowel_to`. One event per syllable at 4 to 5 a second, vowels picked by seed, one event layer per talker at its own pitch. At a distance, low-passed, with a room (§D6). `saw` is the one new source not in the brief's list, and murmur needs it: noise through formants is a whisper, not a room of voices.

```ailang
-- sunholo/audio/osc
export pure func sawSamples(l: Layer, x: Extra, n: int, rate: int) -> [float]   -- polyBLEP saw; glide and vibrato as phaseAt/vibAt; seeded jitter
```

**Check values** (AR3, AR5):
- saw: harmonics 1 to 5 of a 1 kHz saw within 0.5 dB of 2/(πk) (the spike: −0.01 to −0.32 dB). The alias of a 3.1 kHz saw's 16th harmonic at 1.6 kHz is at least 20 dB lower than a naive saw's (spike: −28 dB naive, below −80 dB polyBLEP).
- events: an event starting at n − 100 puts its first 100 samples at the end and the rest at the start, exactly; a loop of events has `analysis.seam` ≤ max step + 1; the starts of a scatter are in [0, n), keep `min_gap`, number exactly `count`, the same for the same seed and different for another; non-overlapping events sum to the sum of their energies (linearity, 1e-9); a one-shot with an event past its end is cut and gets its fade-out.

### D6. A short Schroeder reverb: "far off"

**Model.** Schroeder (1962), with Moorer's (1979) low-pass in each comb's feedback: four parallel feedback combs (29.7, 37.1, 41.1, 43.7 ms) into two series allpasses (5.0 ms and 1.7 ms, g 0.7). Delays are rounded to frames at the recipe's rate. Each comb's gain gives the requested decay: g_i = 10^(−3 · d_i / (t60 · rate)). Then `predelay_ms` and `wet` (dry stays 1). Mono, as the renderer is. Every delay line is a blocked delay line (§D4): one block of d samples is a `mapAccumL` over the previous block, carrying the damping state.

```ailang
module sunholo/audio/space
export pure func spaceOff() -> Space
export func combGain(delayFrames: int, t60: float, rate: int) -> float ! {}
requires { delayFrames >= 1 && t60 > 0.0 && rate > 0 }
export pure func schroeder(s: Space, rate: int, xs: [float]) -> [float]     -- wet 0: the input itself, not a computation
```

**JSON:** a layer's `"space": {"t60": 1.8, "damp_hz": 3000, "predelay_ms": 25, "wet": 0.35}` (default off). "Far off" is a recipe choice: low-pass, more wet, longer pre-delay. It is per layer, so near birds and far bells can share a recipe.

**Check values** (AR6): one comb's impulse response is g^k at multiples of d, exactly; each allpass's impulse-response energy is 1 (the geometric series g² + (1 − g²)² Σ g^(2k) = 1) within 1e-9; the measured T60 (Schroeder backward integration, −5 to −35 dB) is within 5% of `t60` with damping off; `wet` 0 returns the input bit for bit.

### D7. Loop rules in 0.6.0

`soundLoopErrors` = `recipe.loopErrors(base)` for the `Classic` parts (unchanged), plus:

| Part | In a loop |
|---|---|
| `pink`, `brown`, `white` + bands | allowed: periodic generator, filters run over two periods, keep the second (the 0.5.0 noise rule) |
| `saw` | as a 0.5.0 sine: whole cycles, no glide, no jitter, no envelope |
| `fm` | whole cycles of `freq` and `ratio·freq`; constant index (`index_to` = `index`); no envelope |
| `pluck` | refused at the top level (it decays); allowed inside events |
| `bands` on a tonal source | filters over two periods; refused if the slowest band's ring time 2.2·Q/hz s exceeds `seconds` |
| swept bands (`hz_to`, `vowel_to`) | refused at the top level (as a 0.5.0 sweep); allowed inside events |
| `events` | every voice's `seconds` ≤ the loop's `seconds` (a tail wraps at most once); times in [0, seconds); voices follow the one-shot rules |
| `space` | rendered over 1 + ⌈t60 / seconds⌉ periods, keeping the last, so the residual at the seam is below −60 dB; refused if that is more than 5 periods (budget) |

Every 0.6 loop is checked by its rendered seam in the package tests (`analysis.seam` ≤ max step + 1), not only structurally.

### D8. Re-voicing the home sounds (and the bridge candidates)

Each home sound gets a v3 in `data/audio/recipes.json` with the same id, `seconds`, `loop` and `peak_db`, so the cue table, the loop points and the bytes in git do not change. Its `about` says what it imitates. The v2 stays renderable for the A/B through `make sound-review V1_REF=<the pre-re-voice ref>`.

| Sound | v2 (today) | v3 plan (tools) |
|---|---|---|
| home_family | 4 white bands with beats | 3 talkers (saw + jitter through vowel formants, syllable events, seeded), a quiet pink room tone, a small room (`space` t60 0.4 s) |
| home_home | white leaves over low air | wind as brown noise with slow gusts (events of pink through a band sweep, wrapping), leaf rustle (scattered short pink bursts at 2–8 kHz) |
| home_town | 2 white bands | footsteps (fixed-time events: a soft brown thump through a 120 Hz band), distant traffic (brown, low-passed, slow swell), far talkers (babble events, low-passed, `space` t60 1.2 s) |
| home_world | 3 white bands | a crowd far off: about 12 talkers' syllable events summed, low-passed at 1.5 kHz, `space` t60 2 s, wet 0.5 |
| home_science | hum + fan + pulsed tone | mostly kept (mains hum is already real); the fan becomes pink with its blade-pass tone (7 blades × 20 rev/s = 140 Hz and 280 Hz); the pulsed tone kept |
| home_sky | low air + 2 beating sines | crickets as real chirps: events of 3–4 pulses of a 4.5 kHz tone, 2 chirps a second (Dolbear's law: about 20 °C), night air as brown noise |
| home_babble | 3 fast-beating white bands + 2 sines | dense syllable events from 6 talkers, scattered FM chime and pluck fragments |
| home_static | band-limited white | pink receiver hiss + crackle (scattered 1–3 ms clicks with random gain, `vary.amp_db` 18) |
| home_family_tune | 10 sines, harmonic partials | two takes for Mark: a music box (beam modes 1 : 6.27 : 17.55 with an FM strike) and a pluck harp (§D4) |
| home_home_birds | gliding sines | the same phrases with fast trills (events of FM chirps 2.8–4.5 kHz) and a little open-air `space` |
| home_town_bells | 11 sine partials + noise | FM bells (Chowning r 1.4, I 10 → 0) under the existing church-bell partials (hum, prime, tierce, quint, nominal), far off: `space` t60 2.5 s, low-pass |
| home_world_swell | 2 enveloped white bands | the crowd voice of home_world, its density and level rising and settling (fixed-time events) |
| home_science_pips | 6 × 1 kHz pips | kept: the BBC time signal *is* 1 kHz pips. Re-voiced only if OQ3 adds a receiver colour |

**OQ3 (receiver colour).** The home sounds reach the bridge as a transmission (earth-link EL3b.7: "the receiver plays the week's home"). A light receiver colour (band-limited 250 Hz–5 kHz, a touch of drive) is honest for an instrument (sound §D3.5) and hides synthesis artefacts. It could be applied to all 13 or none.

**Bridge sounds that could benefit later** (not in this sprint; they are approved by ear): `room_bridge` (pink or brown air in place of filtered white; the dome's real echo with `space`); `footstep_deck_1`–`6` (a soft brown thump through a resonant band, and the 100 m dome's tail sound §D3 promises); `console_wake`/`console_sleep` (a resonant servo sweep, events for the latch clicks); `lift_run` (rail ticks as events inside the loop); `archive_ready` and `arrived` (FM glass). `spire_hum`, `commit_seal` and `dust_tick` are Mark's reference sounds and stay as they are.

### D9. CPU and size budgets

Stated against the measured 0.5.0 rate (§Evidence: 50–65 ms of strict-VM time per layer-second; the home set 0.37 s per audio second). Measured at AR7 on the Studio with the same probe method and recorded in the package evidence (`design_docs/implemented/audio-realism-0.6.0/timings.json`, as 0.4.0 did):

| Item | Budget (strict VM, Studio, 48 kHz) |
|---|---|
| a `Classic`-only recipe through `renderSound` | within 5% of `recipe.render` (it is the same call plus a check) |
| one SVF pass | ≤ 0.10 s per layer-second (about 2× a one-pole pass); a 3-band vowel bank ≤ 0.30 s |
| pink / brown | ≤ 1.5× / 1.2× a white layer |
| saw / fm / pluck | ≤ 1.5× / 2× / 2× a sine layer per output second |
| events | ≤ 0.08 s per second of event voice per leaf part, plus ≤ 0.02 s per output second per 100 events for placement |
| space | ≤ 0.6 s per output second per layer, times the loop periods (§D7) |
| **the 13 re-voiced home sounds** | **≤ 60 s** in all (today 22 s), so `make sound-synth-check` grows by at most about a minute |
| package suite | ≤ 180 s (today 68 s); probe fixtures ≤ 0.25 s because the interpreter is 45× slower |
| size | the WAVs keep their `seconds`: 18.10 MB of the 20 MB git budget, unchanged |

`SoundLimits` bound the work before any sample is allocated. The defaults are `maxEvents` 4,096 per layer, `maxEventFrames` 16 × `maxFrames` (event voice frames summed), and `maxWorkFrames` 32 × `maxFrames` (all passes, two-period and reverb periods included). These limit list sizes, not wall time, as the 0.1.1 limits say.

### D10. Determinism and evidence

- Every new export is pure. The only randomness is `white(i, seed)` over integers. Scatter positions, variation draws and seeds are integer arithmetic until the final scale. No float is sorted, no map is iterated, and sums run in a stated order: parts in file order, bands in list order, events in event order.
- The phase of saw and FM is a closed form in i / rate. Jitter, the SVF, the pluck and the reverb carry state through `mapAccumL` in sample order. The blocked delay lines compute the same recurrence in the same order as a per-sample loop, and the tests prove it bit for bit against an `Array`-ring reference.
- New `_smoke.ail` probes, each the sha256 of a 0.05–0.25 s render, compared on `--strict-bytecode` and the interpreter with `cmp`: `filterProbe`, `colourProbe`, `oscProbe` (saw, fm, pluck), `eventsProbe` (a wrapping loop), `spaceProbe`, `soundProbe` (a JSON sound with every kind), and `compatProbe` (0.5.0 recipes through `renderSound`).
- **Compat pins (AR0, before any code changes):** `compat_test.ail` pins the 0.5.0 PCM sha256 of the `reference` recipes and of eight short recipes that between them use every 0.5.0 field (glide, vibrato, beat, sweep, 1–4 poles, high-pass, drive, swell, `noise`, `white`, a noise loop, a one-shot fade). They are rendered with the published 0.5.0 and frozen. 0.6.0 must reproduce them through both `render` and `renderSound`.
- Check values are closed forms or published constants (Bessel series, bilinear gains, Kellet's slope, rate / (N + 0.5), Schroeder's comb decay), never a module's own output, except the byte pins. A throwaway Python spike (2026-10-30, scratch, not committed, no file in either repo) computed the spike numbers quoted in §D1–§D5. Nothing in Python is a pipeline step or a test here (CLAUDE.md "Python").
- Cross-architecture equality is not claimed, as in 0.5.0. The game regenerates its WAVs on the Studio.

### D11. The game migration

1. **Path pin first (AR8).** `tools/audio/ailang.toml` pins `{ path = "<ailang-packages clone>/packages/audio" }` on the execution branch only. No PR, no rig run, no `make deps` until the registry pin (as R2-SUNHOLO-AUDIO did).
2. `synth_main.ail` and `review_main.ail` call `parseSoundsAs("stapledons.audio.recipes/1", …)`, `renderSound` and `soundFrames`; `r.id`, `r.rate` and `r.loop` become `s.base.…`. About 30 lines. `synth_test.ail` adds a second pin: a 0.25 s 0.6 sound (events wrapping, a band, FM) whose PCM sha256 is printed on the strict VM and the interpreter (`cmp`, as today).
3. **Byte gate before any recipe changes:** with the 0.6.0 package, `make sound-synth-check` reproduces all 41 manifest sha256 values (AC9).
4. Re-voice (§D8), regenerate, `make sound-levels` (the home cues stay inside the Instruments band), `make sound-review` with the v2 A/B, publish the page, **pause for Mark (P2)**.
5. After his ruling: publish 0.6.0 (AR9), pin `"sunholo/audio" = "0.6.0"`, `ailang lock` (lock and `make deps`), regenerate (provenance becomes `sunholo/audio@0.6.0` and the lock's hash), open the game PR, rig run.

## Acceptance criteria

Commands run from the game clone with `export PATH=$PWD/runtime/bin:$PATH`. `PKG` = the ailang-packages execution clone's `packages/audio`. `OLD` = the published 0.5.0 (`~/.ailang/cache/registry/sunholo/audio/0.5.0`, or the same path under `runtime/cache/registry`). `AR0` = the package commit that froze the compat pins. `BASE` = the game `origin/main` commit the execution branch starts from (after #344). `REVOICE` = the game commit before the re-voice. The table names each criterion, and the commands are in the block below it, so pipes are real pipes.

| # | Criterion | Stage |
|---|---|---|
| AC1 | Package compiles, contracts verify with 0 refuted, quality has no gates | AR7 |
| AC2 | Package tests pass, including every check value in §D1–§D6 | AR1–AR7 |
| AC3 | **Not breaking:** every 0.5.0 signature is present unchanged; version 0.6.0, `kind = "feature"`, CHANGELOG section | AR7 |
| AC4 | **0.5.0 bytes hold in the package:** the compat pins frozen at AR0 pass through `render` and `renderSound` | AR4, AR7 |
| AC5 | Strict VM = interpreter on every probe; `_smoke` prints `OK:` | AR7 |
| AC6 | New layer keys are refused by `parseRecipes` (0.5.0 vocabulary) and accepted by `parseSounds`; unknown keys are still refused | AR4 |
| AC7 | Loop rules: each refusal in §D7 has a test; every 0.6 loop fixture has a clean seam | AR4–AR6 |
| AC8 | Budgets: the timings in §D9 are recorded and within budget; the suite is ≤ 180 s | AR7 |
| AC9 | **Game byte gate on 0.6.0, before any recipe change:** all 41 sounds regenerate byte for byte; strict VM = interpreter on both game pins | AR8 (path pin), AR9 |
| AC10 | After the re-voice, only `home_*` rows change in the manifest (besides provenance) | AR9 |
| AC11 | The re-voiced cues pass the offline loudness rules and the GDScript parity | AR8, AR9 |
| AC12 | Review page published with v2 beside v3 for every re-voiced sound; Mark's ruling recorded in the ledger | AR8 |
| AC13 | Published and pinned from the registry; lock clean | AR9 |
| AC14 | No sim, Python or Godot sound-code change; git budget holds | AR9 |
| AC15 | Whole suite on the rig | AR9 |

```sh
# AC1
ailang check --package $PKG && ailang verify --package $PKG && ailang pkg quality $PKG | tee /dev/stderr | grep -q 'no gates'
# AC2
ailang test --package $PKG
# AC3: every 0.5.0 interface line still exists in 0.6.0 (comm prints old-only lines; none allowed)
for m in dsp noise recipe pcm mix analysis reference safety clip edit clip_pcm levels block delay automation; do
  gone=$(comm -23 <(cd $OLD && ailang iface -compact -relax-modules $m.ail | LC_ALL=C sort) \
                  <(cd $PKG && ailang iface -compact -relax-modules $m.ail | LC_ALL=C sort))
  [ -z "$gone" ] || { echo "$m: $gone"; exit 1; }; done
grep -q '^version = "0.6.0"' $PKG/ailang.toml && grep -q '^kind = "feature"' $PKG/ailang.toml && grep -q '^## 0.6.0' $PKG/CHANGELOG.md
# AC4: the pins were not edited after AR0, and they pass (inside AC2; the probe repeats them on the strict VM)
git -C $PKG diff --quiet $AR0 -- compat.ail   # as built: the frozen recipes and pins live in compat.ail (exported), compat_test.ail checks them
cd $PKG && ailang run --quiet --relax-modules --bytecode --strict-bytecode --entry compatProbe --args-json 0 _smoke.ail | grep -q '^compat-ok '; cd -
# AC5
cd $PKG && for p in renderProbe wavProbe levelProbe filterProbe colourProbe oscProbe eventsProbe spaceProbe soundProbe compatProbe; do
  cmp <(ailang run --quiet --relax-modules --bytecode --strict-bytecode --entry $p --args-json 0 _smoke.ail) \
      <(ailang run --quiet --relax-modules --entry $p --args-json 0 _smoke.ail) || exit 1; done
ailang run --quiet --relax-modules --caps IO --entry main _smoke.ail | grep -q '^OK:'; cd -
# AC6, AC7: named tests in sound_test.ail (inside AC2); the positive control proves the names exist
grep -c -E '^test "(parseRecipes refuses 0.6 key|parseSounds accepts|unknown key still refused|loop: )' $PKG/sound_test.ail
# AC8
jq -e '.within_budget == true and .suite_seconds <= 180' $PKG/../../design_docs/implemented/audio-realism-0.6.0/timings.json
# AC9 (on REVOICE, i.e. the 0.6.0 pin with the recipes unchanged)
make sound-synth-check | grep -q '^sound-synth-check: synth-ok [0-9a-f]* VM = interpreter; 41 sounds regenerate byte for byte$'
# AC10
diff <(git show $REVOICE:data/audio/assets_synth.json | jq -S '[.assets[] | select(.id | startswith("home_") | not) | del(.provenance)]') \
     <(jq -S '[.assets[] | select(.id | startswith("home_") | not) | del(.provenance)]' data/audio/assets_synth.json)
jq -e '[.assets[].provenance.generator] | unique == ["sunholo/audio@0.6.0"]' data/audio/assets_synth.json
# AC11
make sound-levels | grep -q '^sound-levels: [0-9]* passed, 0 failures$' && make sound-levels-parity | grep -q ', 0 differences$'
# AC12
curl -fsS https://storage.googleapis.com/stapledons-voyage-assets/refs/sound/r3-realism/sounds.json \
  | jq -e '[.sounds[] | select(.id | startswith("home_"))] | length == 13 and ([.[] | select(.status == "changed")] | length) >= 11'
grep -E '^\| D-[0-9]+ \| RESOLVED \|.*sunholo/audio 0\.6' design_docs/stapledon-mission.md
# AC13
ailang pkg search audio | grep -q 'sunholo/audio@0.6.0'
jq -e '.packages[] | select(.name == "sunholo/audio" and .version == "0.6.0" and .source == "registry")' tools/audio/ailang.lock
make deps
# AC14
test -z "$(git diff --stat $BASE -- sim/ audio/ tools/python-allowlist.txt)" && make python-guard && make sound-assets-check
# AC15 (rig)
tools/rig_check.sh <PR>
```

AC12 reads `sounds.json` as `tools/sound_review.gd` writes it (schema `stapledons.audio.review/1`: `sounds[]` rows with `id` and `status`, which is `changed` when the sha256 differs from `V1_REF`). At least 11 of the 13 change; `home_science_pips` and possibly `home_science` stay (§D8).

## Sub-milestones and estimates

| Id | What | LOC | Days | Depends |
|---|---|---|---|---|
| AR0 | Baseline. Package: branch `feat/audio-0.6` in a fresh ailang-packages clone; `compat_test.ail` pins rendered with the published 0.5.0 and frozen; timings re-run with the §Evidence probe. Game: on `BASE`, `make sound-synth-check` prints 41 sounds (stop and report otherwise) | 90 | 0.5 | plan approved |
| AR1 | `filter`: SVF, `svfGain`, sweep, `bank`, `vowelBands`; tests red first (§D1 table) | 150 + 120 | 1 | AR0 |
| AR2 | `noise`: `pinkOf`, `brownOf`; the Goertzel PSD test (§D2) | 50 + 70 | 0.5 | AR0 |
| AR3 | `osc`: `sawSamples` (polyBLEP, jitter), `fmSamples`, `pluckPeriod`/`pluckSamples` (blocked, tuned); tests (§D3–§D5) | 230 + 160 | 1.5 | AR1 |
| AR4 | `sound`: types, `parseSoundsAs` (closed vocabulary extended), `validateSound`, `soundLoopErrors`, `renderSound` with Classic delegation, `recipe.finish`, `SoundLimits`, checked API; AC4, AC6 | 390 + 200 | 1.5 | AR1–AR3 |
| AR5 | `events`: scatter, fixed, `place` with wrap, `variation`; event layers in `sound`; tests (§D5) | 120 + 110 | 1 | AR4 |
| AR6 | `space`: Schroeder/Moorer; layer `space`; loop periods; tests (§D6). **Cut line:** if the sprint runs long, AR6 moves to 0.7.0 and the home sounds use low-pass + pre-delay only | 110 + 90 | 0.75 | AR4 |
| AR7 | Package finish: `_smoke` probes, AGENT.md (the new schema fields, loop rules, budgets, pitfalls), README, CHANGELOG `## 0.6.0`, `ai_summary`, version, `kind = "feature"`, timings evidence; AC1–AC8. **No publish yet** | 90 + 250 prose | 0.75 | AR5, AR6 |
| AR8 | Game on the path pin: shells switched (§D11), AC9 byte gate, then the re-voice (§D8), `make sound-levels`, review page with the v2 A/B published (`STAGE=r3-realism PUBLISH=1`); **pause P2 for Mark** | 60 + 350 data | 1.5 | AR7, #344 merged |
| AR9 | After Mark's ruling: tool fixes if he asks (back to AR7's gates), `cd packages/audio && ailang publish` (standing approval), registry pin, lock, `make deps`, regenerate, game PR, AC9–AC15 | 40 | 0.5 | P2 |
| AR10 | Independent evaluation (a different model from the executor), landing (doc to `implemented/r3/`, report, changelog fragment, index row, earth-link row note) | — | 0.5 | AR9 |

About **9.5 working days** for about 2,700 LOC (prose and recipe data included), about 285 LOC a day, close to the R2 attended rate. The new DSP needs closed-form checks for every primitive, and the listening pause is unbounded. AR2 runs in parallel with AR1, and AR6 in parallel with AR5.

Design sections by milestone: D1 → AR1; D2 → AR2; D3, D4 and D5's saw → AR3; D0, D7 → AR4; D5's events → AR5; D6 → AR6; D9, D10 → AR7; D8, D11 → AR8–AR9.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Moving the post-chain into `recipe.finish` changes a float order and one old sound's bytes | The move is verbatim and the first change in AR4; the AR0 compat pins and the reference loop pin run before and after it; AC9 runs on the full 41 before any recipe changes |
| Realism loses what Mark liked ("spooky and unique") | Every v3 sits beside its v2 on the review page; he rules per sound; a v2 stays if he prefers it. The Earth-rate pitch mapping still makes them strange |
| Synthesised voices sound like a vocoder or speech, breaking "murmur, never words" (sound §D3, D-101) | Formants and syllables only: no phoneme sequences, no consonant models, low-pass at a distance. OQ2 lets Mark set how close to voices to go |
| The interpreter is 45× slower, so parity probes time out | Probes are ≤ 0.25 s. Full renders run on the VM only, as today |
| `scatterAdd` or a recursive ADT is not strict-VM clean on v0.54.18 | Checked at AR0 on a 20-line probe. Fallbacks are a fold of `updateMany` per event and the depth-1 `Leaf`/`Part` split already in §D0. A VM bug is reported upstream and fixed at source (memory: VM bugs fix at source), not worked around in the package |
| The re-voiced home set exceeds the 60 s budget | Event density and talker count are recipe data: thin them before touching the code. A primitive over its own budget is profiled and reported, not hidden |
| A 5 s loop with recognisable events repeats audibly (every 5 s, every 2.5 s at pitch 2.0) | Sparse, varied events; distinctive events (a laugh, a bell) belong in the accents, not the beds. Longer beds would exceed the 20 MB git budget (1.9 MB left), so OQ6 asks |
| 0.5.0 consumers outside the game are surprised by `parseRecipes` refusing a 0.6 file | Expected and wanted (fail-closed). The refusal names `parseSounds`, and AGENT.md says so |
| Publishing is irreversible | Publish only after the path-pin gates (AC1–AC9, AC11) and Mark's ruling (P2) |

## Open questions for Mark

| # | Question | Recommendation |
|---|---|---|
| OQ1 | All six tools, or fewer? Reverb (AR6) is the optional one | **All six, with AR6 as the cut line.** "Far off" is half of what makes the crowd and the bells real |
| OQ2 | How voice-like may the murmur get? | **Formants and syllables, never words**: talkers at a distance, low-passed. That is sound §D3 and D-101's line; real speech stays a later generated-sound ruling |
| OQ3 | A receiver colour on the home sounds (band-limited 250 Hz–5 kHz, a touch of drive), since they arrive by radio? | **Try it as a third take on two sounds** (home_family, home_town_bells) on the review page and let the ear decide. It is honest for an instrument and hides synthesis artefacts |
| OQ4 | Would CC0 field recordings (route B, Kenney) be acceptable for some home sounds instead of synthesis? | **No, synthesis for now.** EL3b.7 chose route A, and the point of this release is tools every later sound can use. Recordings stay route B for foley |
| OQ5 | The family tune: music box (struck comb, inharmonic) or plucked harp (Karplus–Strong)? | **Render both and pick by ear**: the music box first, which matches the EL3b.7 note |
| OQ6 | The beds are 5 s loops (the 20 MB git budget has 1.9 MB left). Keep 5 s? | **Keep 5 s** and use sparse, varied events. A longer bed is a budget ruling, best taken after hearing v3 |
| OQ7 | `kind = "feature"` with an additive `sound` module (0.5.0 types untouched), or a `breaking` 0.6.0 that grows `Layer` as 0.5.0 did? | **Additive, `feature`.** Byte identity is then true by construction, the 0.5.0 interface is checked (AC3), and the game's migration is about 30 lines |
| OQ8 | Re-voice the bridge sounds too (§D8 candidates)? | **Not now.** They are approved by ear (D-108, D-112, D-124). Each is a later pass with its own listen |

## Deliverables

- `sunholo-data/ailang-packages` `packages/audio/`: new `filter.ail`, `osc.ail`, `events.ail`, `space.ail` and `sound.ail`, each with a `*_test.ail`; `noise.ail` (`pinkOf`, `brownOf`); `recipe.ail` (`finish` exported, nothing else changed); `compat_test.ail`; `_smoke.ail` probes; AGENT.md, README, CHANGELOG `## 0.6.0`, `ailang.toml` (0.6.0, `kind = "feature"`, exports, `ai_summary`); evidence `design_docs/implemented/audio-realism-0.6.0/` (timings, quality). Published `sunholo/audio` 0.6.0 at AR9.
- This repo: `tools/audio/ailang.toml` + `ailang.lock` (0.6.0); `synth_main.ail`, `review_main.ail`, `synth_test.ail` on the `sound` API; `data/audio/recipes.json` (13 `home_*` v3, as Mark rules); `data/audio/assets_synth.json` and `assets/audio/synth/home_*.wav` regenerated; the review page at `gs://stapledons-voyage-assets/refs/sound/r3-realism/`; a ledger row for P2; this doc moved to `implemented/r3/` with a report.

## As built (landing, 2026-10-30)

- **AR8b was added by Mark's standing order** (2026-10-30, stapledons-design #46: "no compromises on the physcis, if we can help it", with a true setting and processed settings). The station's sound now runs at the Earth rate D exactly in every setting; Receiver (the default) corrects the frequency on a new Receiver bus, True does not and is silent outside human hearing. EL3b.7's compressed band pitches are gone.
- **AC12, amended.** The review page is the listening preview artifact https://claude.ai/artifact/ANRG4SeogdoN7tkgDPLsD7 (v2 beside v3 for every re-voiced sound, the takes, and each sound in True, Receiver-corrected and Old modes at every Earth rate), not a `make sound-review` bucket stage. Mark's ruling (P2: "yeah these sound good - lets merge it in to the game", "v3") is recorded in the sprint plan and its JSON (`ruling_p2`); `mission_answer.sh` answers existing OPEN ledger rows and there was none for P2, so no ledger row was added.
- **AC14, amended.** AR8b changes Godot sound code (the Receiver bus, `SoundDirector.set_pitch` unrounded, `ShipSound` following the receiver's rates, `EarthFeed.receiver_plan`), by the standing order. There is still no sim or Python change, and the git budget holds (18,104,524 of 20,000,000 bytes).
- **AC8.** The timings are recorded in the package repo, `design_docs/implemented/audio-realism-0.6.0/timings.json` (sunholo-data/ailang-packages). The 13 home sounds render in 58.4 s on the strict VM (budget 60 s; v2 took 22.05 s). Pink noise costs 1.51x white (budget 1.5x). The package suite takes about 10 s on the bytecode VM and 302 s on the interpreter (budget 180 s): over on the interpreter, recorded rather than hidden.
- **The Receiver correction is measured** (evaluation finding 4): `tests/test_sound.gd` `test_receiver_measured` plays a 1 kHz tone through the Receiver bus and reads the mixer's output: Receiver gives 1000, 1000 and 1011 Hz at D = 0.5, 2 and 16; True gives 499, 2000 and 15998 Hz (within 3 %).
- **0.6.1** is a smoke-only fix: the package CI's 30 s smoke limit (PUB015). The game stays on 0.6.0 (the same code and samples).
