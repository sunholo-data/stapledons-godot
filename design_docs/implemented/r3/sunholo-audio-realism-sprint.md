# Sprint R3-SUNHOLO-AUDIO-REALISM: `sunholo/audio` 0.6.0, closer-to-real synthesis

**Design doc:** [sunholo-audio-realism.md](sunholo-audio-realism.md)
**Sprint JSON:** `.ailang/state/sprints/sprint_R3-SUNHOLO-AUDIO-REALISM.json` (`awaiting_approval`)
**Status:** Completed 2026-10-30: AR0–AR10 with AR8b (game PR #361, rig/full 74 min; package PR sunholo-data/ailang-packages#172; `sunholo/audio` 0.6.0 and 0.6.1 published). Approved by Mark 2026-10-30, OQ1–OQ8 at their recommendations; the listen ruled v3 (P2). Evaluation 83/100 PASS (`.ailang/state/evaluations/eval_R3-SUNHOLO-AUDIO-REALISM_round_1.json`). Report: [sunholo-audio-realism-report.md](sunholo-audio-realism-report.md).
**Base:** `origin/main` 061e71aa (branch `design/sunholo-audio-realism`). The package half runs on `feat/audio-0.6` in a fresh clone of `sunholo-data/ailang-packages` (`~/dev/sunholo-data/ailang-packages-audio06`, never the shared checkout). The game half runs on `feat/sunholo-audio-realism` from the `main` that contains PR #344 (R3-EARTH-LINK, whose EL3b.7 adds the 13 `home_*` recipes).
**AILANG:** v0.54.18 (the pinned runtime). AILANG prompt version loaded: **v0.16.7** (`ailang prompt --version-active`). Every package milestone writes `.ail` code; the syntax checklist is below.
**Registry reuse:** searched 2026-10-30 (`ailang pkg search audio`, `synth`, `dsp`, `filter`, `reverb`, `noise`, `fm`). Only `sunholo/audio` 0.5.0 does synthesis; `sunholo/gemini_live` and `sunholo/explainer` handle speech I/O, not DSP. Decision per milestone in the JSON `registry_reuse`: AR0–AR7 **contribute** (0.6.0 of `sunholo/audio`), AR8–AR9 **depend** (the game pins it), AR10 **none**. `std/audio` (WAV, Opus) and `std/array` (`scatterAdd`, `updateMany`) are reused, not re-implemented.
**Estimate:** about **2,700 LOC** (package code 1,230, tests 750, prose 250; game 60 code + 350 recipe data + 80) over **9.5 working days**, about 285 LOC a day. The recent attended rate is about 300 LOC a day (R2-SUNHOLO-AUDIO: 1,500 in 5 days). It is lowered for new DSP that needs closed-form checks on every primitive, and the listening pause is not counted.

## What the survey found

- **0.5.0 render rate** (design §Evidence, measured 2026-10-30 on the Studio, strict VM): the 13 `home_*` recipes, 59 s of audio, take 22.05 s (0.37 s per audio second). That is about 50–65 ms per layer-second; spire_drift (32 s) takes 20.4 s. The interpreter is 45× slower (home_science 74.65 s against 1.66 s). Every WAV sha256 matched `data/audio/assets_synth.json` on `feat/earth-link` 67dc0842.
- **0.5.0 suite:** 198 tests pass in 68 s. `pkg quality --no-run` shows no gates, interface v2 with 154 signatures, `kind breaking`.
- **0.5.0's `breaking` came from a record shape** (`Layer.lpPoles`), not from samples. A `feature` 0.6.0 therefore leaves `Env`, `Layer`, `Recipe` and `RenderLimits` untouched and adds a `sound` module (design §D0). `ailang iface -compact` gives one line per type and export, so "every 0.5.0 line still exists" is a `comm -23` check (AC3).
- **Layer keys are closed in 0.5.0, recipe-level keys open.** 0.6.0 adds only layer-level keys, so an older parser refuses a 0.6 file rather than rendering it differently.
- **Sine layers in 0.5.0 ignore their filter fields** (only noise is filtered). This stays for `Classic` layers and is documented as a pitfall.
- **The game's uses of the recipe API:** `synth_main.ail` (`parseRecipesAs`, `render`, `frames`), `review_main.ail` (`parseRecipesAs`, `render`, `defaultRate`, `mix.tile`), `synth_test.ail` (record literals and `render`). `levels*.ail` use `analysis`, `dsp` and `pcm` only.
- **The review page** (`tools/sound_review.gd`) writes `sounds.json` (`stapledons.audio.review/1`, `sounds[]` with `id` and `status` = `changed` against `V1_REF`), so the v2/v3 A/B needs no tool change.
- **Budget:** WAVs in git are 18,104,524 of 20,000,000 bytes. The re-voice keeps every `seconds`, so this does not move.
- **Spike** (throwaway, pure Python, scratch only, deleted): the closed-form check values in design §D1–§D5 (bilinear band-pass gains, Bessel lines, Kellet/brown PSD slopes −3.05 and −6.04 dB/octave, Karplus–Strong tuning within 0.85 cent, a polyBLEP saw's harmonics within 0.32 dB).

## Milestones

Package milestones run in `$PKG` = `~/dev/sunholo-data/ailang-packages-audio06/packages/audio`. Every milestone writes its tests **red first** and records the gate output in the sprint JSON `notes`.

### AR0: baseline and frozen compat pins (~90 LOC, 0.5 day)
- Package: branch `feat/audio-0.6` from `origin/main`. Write `compat_test.ail` with eight short recipes (≤ 0.25 s each). Between them they use every 0.5.0 field: glide, vibrato, beat, sweep, 1–4 poles, high-pass, drive, swell, `noise`, `white`, a noise loop and a one-shot fade. Add the `reference` recipes. Pin their PCM sha256 values as rendered by the **published 0.5.0** (a scratch package depending on the registry 0.5.0, as the design's timing probe did). Commit the pins alone and record that commit as `AR0` in the JSON.
- A 20-line strict-VM probe of `std/array.scatterAdd`, an ADT whose constructor carries a record, and a constructor named like a type (`Leaf(Leaf)`). Each one that fails is reported upstream (`ailang messages`, GCP store) and the design's fallback is recorded.
- Re-run the §Evidence timing probe (the numbers become the AR7 baseline in `timings.json`).
- Game (only once #344 has merged; otherwise at AR8): on `BASE`, `make sound-synth-check` prints `41 sounds regenerate byte for byte`. **Stop and report** if it prints another count or fails.
- **Gate:** `ailang test --package $PKG` passes with the new pins (0.5.0 code, so they must); the AR0 commit hash is in the JSON.

### AR1: `filter`, the state-variable filter (~270 LOC incl. 120 tests, 1 day)
- Red first: `filter_test.ail` with the design §D1 table: the gains at the centre and ±1 octave for (1 kHz, Q 2), (1 kHz, Q 0.7071) and (3 kHz, Q 8); `svfGain` against measurement on 20 seeded cases; the LP + BP/Q + HP identity; a fixed sweep equal to `svf`; `vowelBands`.
- Build `filter.ail`: `SvfMode`, `Band`, `svfGain` (with `requires`), `svf`, `svfSweep`, `bank`, `vowelBands`. Add the module to `[exports]`.
- **Gate:** `ailang check --package $PKG`, `ailang test --package $PKG`, `ailang pkg quality --no-run $PKG` (no gates).

### AR2: pink and brown noise (~120 LOC incl. 70 tests, 0.5 day; parallel with AR1)
- Red first: `noise_test.ail` additions. The Goertzel PSD slope (six bins 93.75–3,000 Hz, 24 Hann segments of 4,096) for white 0, pink −3.01 and brown −6.02 dB/octave, each ±0.5. RMS within 10% of 1/√3. Seed determinism. `white` and `rampNoise` pins unchanged.
- Build `pinkOf` (Kellet refined, a fixed scale) and `brownOf` (`onePole(20 Hz)`, scale √((2 − a)/a)).
- **Gate:** as AR1.

### AR3: `osc`, saw, FM and pluck (~390 LOC incl. 160 tests, 1.5 days)
- Red first: `osc_test.ail`. The saw harmonics 1–5 within 0.5 dB of 2/(πk), and the 1.6 kHz alias at least 20 dB under a naive saw. FM lines |J_k(1)| and |J_k(2)| for k 0–3 within 0.002 (Bessel by series in the test); I = 0 equals a sine. Pluck: the tuned fundamental within 1 cent at 110, 440 and 1046.5 Hz; untuned within 0.5 cent of rate / (N + 0.5); the T60 within 10%; the blocked form equals the per-sample `Array`-ring reference bit for bit.
- Build `osc.ail`: `sawSamples` (polyBLEP, the `phaseAt`/`vibAt` glide and vibrato, seeded smooth jitter), `fmIndexAt`, `fmSamples`, `Period`, `pluckPeriod` (with `requires`), `pluckSamples` (blocked delay line). The `FmVoice`, `PluckVoice` and `Extra` types live here or in `sound`, settled at AR3 so as to avoid an import cycle.
- **Gate:** as AR1.

### AR4: `sound`, the 0.6 front end (~590 LOC incl. 200 tests, 1.5 days)
- **Step 1, the verbatim move.** `recipe.render`'s post-chain becomes the exported `recipe.finish(r, summed)`, and `render` calls it. No expression changes. Run the AR0 pins and the reference pin before and after; they must stay green.
- Red first: `sound_test.ail`. `renderSound` equals `render` on every compat recipe (bit for bit). `classicOnly` is true for 0.5.0 files. `parseRecipes` refuses each 0.6 key and names `parseSounds`. `parseSounds` accepts them. An unknown key is still refused (`bandz`). Every §D7 refusal gets a named test `loop: …`. The checked API refuses over-budget events and work before allocating.
- Build `sound.ail`: the types of design §D0, `defaultSoundLimits`, `parseSoundsAs`/`parseSounds`/`parseSoundsChecked`, `validateSound`, `soundLoopErrors`, `soundFrames`, `classicOnly`, `renderSound`, `renderSoundChecked`. The stage order is design §D1's.
- **Gate:** as AR1, plus AC4 and AC6 of the design.

### AR5: events inside loops (~230 LOC incl. 110 tests, 1 day)
- Red first: `events_test.ail`. Wrap at the loop point is exact (an event at n − 100). A loop of events has a clean `analysis.seam`. The scatter's count, range, min gap and seed behaviour. Linearity of non-overlapping events to 1e-9. A one-shot cuts and fades an event past its end. The voice seed rule `seed + 1009·k`. `vary.cents` moves sources and leaves filters alone.
- Build `events.ail` (`scatterStarts`, `fixedStarts`, `place` with `scatterAdd` or the AR0 fallback, `variation`) and the `events` layer in `sound` (voices as one-shots; depth 1).
- **Gate:** as AR1.

### AR6: `space`, the Schroeder reverb (~200 LOC incl. 90 tests, 0.75 day; parallel with AR5; the cut line)
- Red first: `space_test.ail`. The comb impulse response g^k exactly. Allpass energy 1 within 1e-9. The measured T60 within 5%. `wet` 0 returns the input bit for bit. A loop with `space` keeps a clean seam over 1 + ⌈t60 / seconds⌉ periods, and more than 5 periods is refused.
- Build `space.ail` (`spaceOff`, `combGain` with `requires`, `schroeder`) and the layer `space` stage in `sound`.
- **Cut line:** if the sprint passes day 7 before AR6 starts, AR6 moves to 0.7.0, the `space` key stays unknown (refused), and §D8's "far off" uses low-pass and pre-delay only. Mark is told at P2.
- **Gate:** as AR1.

### AR7: package finish, not yet published (~340 LOC incl. 250 prose, 0.75 day)
- `_smoke.ail`: `filterProbe`, `colourProbe`, `oscProbe`, `eventsProbe`, `spaceProbe`, `soundProbe`, `compatProbe` (prints `compat-ok <n>`), each ≤ 0.25 s. `main` prints `OK:` with the new closed forms included.
- AGENT.md: a "Sounds (0.6.0)" section with every new field, its default and its meaning; the stage order, the loop rules (§D7), seeds and summation order; budgets and `SoundLimits`; pitfalls (the `Classic` sine filter trap, the 45× interpreter, `parseRecipes` refusing 0.6 files). Also README, CHANGELOG `## 0.6.0` ("Feature: … every 0.5.0 recipe renders byte for byte"), `ai_summary`, `version = "0.6.0"` and `kind = "feature"`.
- Evidence directory `design_docs/implemented/audio-realism-0.6.0/` in ailang-packages: `timings.json` (the §D9 table measured, `within_budget`, `suite_seconds`) and `quality.json`.
- **Gate:** design AC1–AC8. **No publish yet**: the game's path-pin gates and Mark's listen come first.

### AR8: the game on the path pin, the re-voice, the listen (~450 LOC incl. 350 recipe data, 1.5 days)
- **Path pin:** `tools/audio/ailang.toml` → `{ path = "<ailang-packages-audio06>/packages/audio" }`. It works only on this machine, so no PR is opened, no rig or CI run is requested, and `make deps` is not expected to pass until AR9. The path pin never reaches `main`.
- Switch `synth_main.ail`, `review_main.ail` and `synth_test.ail` to `parseSoundsAs`/`renderSound`/`soundFrames` (design §D11), and add `synth_test`'s second pin (a 0.25 s 0.6 sound). Commit this as `REVOICE`. **AC9 now:** `make sound-synth-check` reproduces all 41 sounds before any recipe changes.
- Re-voice the 13 `home_*` recipes as design §D8 lays out, two takes for `home_family_tune` (OQ5) and, if OQ3 is approved, a receiver-colour third take on two sounds. The page lists cues from `cues.json`, so an extra take is not a new id. It is a second page rendered from a scratch commit where those recipes carry take B (`STAGE=r3-realism-b`), never merged. The cue table does not change. Then `make sound-synth`, `make sound-levels`, `make sound-levels-parity`, and `make sound-review STAGE=r3-realism V1_REF=$REVOICE PUBLISH=1` (public bucket, standing approval).
- Time the re-voiced set on the strict VM (≤ 60 s, design §D9) and record it.
- **Pause P2:** send Mark the review page URL. Ask him to rule per sound (keep v3, keep v2, rework) and on OQ3/OQ5. Record the ruling with `mission_answer.sh` in a fresh clone (memory: ledger edit safety). **Stop** until it is recorded.
  - **Ruled 2026-10-30 (Mark, attended):** "yeah these sound good - lets merge it in to the game", then "v3": **v3 for all twelve re-voiced sounds**, `home_science_pips` unchanged; the family tune is take A (the music box, OQ5); the receiver colour (OQ3) is not adopted (no ruling for it: the plain v3). Preview: https://claude.ai/artifact/ANRG4SeogdoN7tkgDPLsD7.

### AR8b: the station's True and Receiver settings (standing order 2026-10-30, ~200 LOC)

Mark, attended 2026-10-30: "so like the exposure visuals, we can have a true setting, and processed settngs. this is a general principle for ths game - no compromises on the physcis, if we can help it" (stapledons-design #46). EL3b.7 squeezed the Earth rate's 46 semitones into six. It is replaced:
- **The time rate is exact in every setting:** the bed plays at speed D (`earth.rate`) and the accents come every `every_s / D` (the first after `first_s / D`). The band's compressed `pitch` is removed.
- **Receiver (the default):** the ship's receiver corrects the frequency, as the DSN corrects the Voyagers' Doppler shift: a new `Receiver` bus (into Instruments) with `AudioEffectPitchShift` at 1/rate, enabled only while it corrects. A real-time receiver plays between 1/16× and 16× (`receiver.min_rate`, `max_rate` in data): below, it holds the moment; above, the backlog grows.
- **True:** speed and pitch × D, uncorrected; where the result is outside human hearing (`receiver.audible`: D < 0.02 or > 50) nothing plays and the station says so (a tag, no digits).
- A toggle on the station (True / Receiver), and the home cues on the `Receiver` bus.
- **Tests:** the rate is earth.rate at RS-26..RS-30; the receiver's clamp and its correction; True's silence outside hearing; the accent interval at D; ShipSound sets the bus correction and plays nothing when silent; the bus layout carries the Receiver bus and its pitch shift.

### AR9: publish, pin, PR (~40 LOC, 0.5 day)
- If the ruling needs a tool change: back to AR7's gates on the package, then AR8's regeneration. If it only needs recipe changes: regenerate. The chosen take goes into `recipes.json`; the take-B scratch commit is deleted.
- `cd packages/audio && ailang publish` (Mark's standing approval for `sunholo/*`; never crew_lab). Open and merge the ailang-packages PR after publishing, as 0.5.0 did.
- Game: `"sunholo/audio" = "0.6.0"`, `cd tools/audio && ailang lock`, `make deps`, `make sound-synth` (provenance becomes `sunholo/audio@0.6.0`), and commit. Open the game PR ready, then run `tools/rig_check.sh <PR>`.
- **Gate:** design AC9–AC15.

### AR10: evaluation and landing (0.5 day)
- `sprint-evaluator` run by a different model from the executor (100 points, 70 to pass), written to `.ailang/state/evaluations/eval_R3-SUNHOLO-AUDIO-REALISM_round_1.json`.
- Landing: the design doc and this plan to `design_docs/implemented/r3/`, plus a report: the timings, the per-sound ruling, the upstream reports and the review URL. Also a changelog fragment `changelogs/unreleased/<date>-sunholo-audio-realism.md`, the README index row, and a note on earth-link's EL3b.7 row.

## Pause points

1. **Now (P1):** Mark approves the plan and OQ1–OQ8 (a new ledger row, attended).
2. **AR8 (P2):** the listening page. Mark rules per sound, plus OQ3 and OQ5. Nothing is published before this.
3. **Any byte drift:** if AC4 or AC9 fails (an old sound's bytes change), execution stops and reports. It never re-pins.

## AILANG syntax checklist (per module)

| Module | Contracts | Effects | Inline tests |
|---|---|---|---|
| `filter` | include: `svfGain` `requires { hz > 0.0 && hz < rate / 2.0 && q > 0.0 && f > 0.0 && f < rate / 2.0 }`, `ensures { result >= 0.0 }` | pure (no row) | include: `tests [...]` on `svfGain` at the centre = 1.0 for three (hz, q) |
| `noise` (additions) | skip: float-sequence ensures are unencodable for Z3 (PUB016); named tests cover them | pure | skip: the slope checks need 2 s of noise, too long for inline rows |
| `osc` | include: `pluckPeriod` `requires { freq >= 20.0 && freq <= 4000.0 && rate > 0 }`, `ensures { result.n >= 2 }` | pure | include: `tests [...]` on `pluckPeriod(440.0, 48000)` (n 108) |
| `events` | include: `scatterStarts` `requires { count >= 0 && n > 0 && minGap >= 0 }` | pure | include: `tests [...]` on `fixedStarts([0.0, 0.5], 48000)` = [0, 24000] |
| `space` | include: `combGain` `requires { delayFrames >= 1 && t60 > 0.0 && rate > 0 }`, `ensures { result > 0.0 && result < 1.0 }` | pure | skip: impulse-response checks live in `space_test.ail` |
| `sound` | include: `soundFrames` `ensures { result >= 0 }`; `validateSound` and the checked APIs return `Result` (as `recipe`) | pure | skip: renders are too long for inline rows; `sound_test.ail` named checks |
| `recipe` (`finish`) | skip: a verbatim move; the byte pins are its contract | pure | skip: covered by the reference and compat pins |
| `_smoke` | skip: probe | `! {IO @limit=1}` (`main` only, as today) | skip: it is the probe |
| game `synth_main` / `review_main` / `synth_test` | skip: shells, checked by `make sound-synth-check` and the review page | `! {FS, IO}` / `! {FS, IO}` / `! {IO}` | skip: make targets |

## Validation (per milestone, focused)

Package: `ailang check --package $PKG`, `ailang test --package $PKG`, `ailang verify --package $PKG`, `ailang pkg quality $PKG`, and the `_smoke` probes on `--strict-bytecode` against the interpreter. Game: `make sound-synth-check` (AC9), `make sound-levels`, `make sound-levels-parity` (needs Godot; wrap with `perl -e 'alarm 900; exec @ARGV'`), `make sound-assets-check`, `make sound-test`, `make python-guard`, `make deps` (AR9 only). The full `make test` runs once, on the rig, at AR9 (`tools/rig_check.sh`).
