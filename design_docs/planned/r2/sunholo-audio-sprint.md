# Sprint R2-SUNHOLO-AUDIO: the synthesis and its loudness checks as `sunholo/audio`

**Design doc:** [sunholo-audio.md](sunholo-audio.md)
**Sprint JSON:** `.ailang/state/sprints/sprint_R2-SUNHOLO-AUDIO.json` (`awaiting_approval`)
**Status:** **Awaiting Mark's approval** of the plan and OQ1–OQ8. Nothing is executed or published before it.
**Plan review:** an independent Sonnet review (read-only, `claude -p --model sonnet`) scored the first draft **82/100 (pass)** with five blocking items, all fixed here and in the design doc: the AC commands moved out of the markdown table so pipes are real (AC5 gained a positive control); `verify` retargeted to the game's `levels.ail`; the provenance plumbing (`Args.lock`, `SOUND_SYNTH_ARGS`) spelled out; no PR, rig or CI run while the path pin is in place; `sound-levels-parity` in `make test` with per-guard comparison. Non-blocking ones folded in: the exact `db()` formula, a `wavProbe`, Opus in the review fixture, an AU0 stop condition, the `rate` record-literal note, the LOC reconciled, the spike deleted (`sprint_R2-SUNHOLO-AUDIO.json` `reviews`).
**Base:** `origin/main` adf34a67 (branch `design/sunholo-audio`). Execution starts from the `main` that contains PR #319 (R2-SOUND S1), on `feat/sunholo-audio` in the game and `feat/audio` in `sunholo-data/ailang-packages`.
**AILANG:** v0.54.14 (pinned). AILANG prompt version loaded: v0.16.7 (`ailang prompt --version-active`). Every milestone writes `.ail` code; the syntax checklist is below.
**Registry reuse:** searched 2026-10-22 (`ailang pkg search audio`, `synth`, `dsp`, `wav`, `sound`): only `sunholo/gemini_live` (voice protocol, no synthesis); `ailang-packages/packages/` has no audio package. Decision per milestone in the JSON `registry_reuse`: AU1–AU3 **contribute** (new package `sunholo/audio`), AU4 **depend** (the game pins it), and every milestone reuses `std/audio` (stdlib) for WAV headers and Opus rather than re-implementing them.
**Estimate:** about 1,500 LOC in all (package 920 incl. tests and smoke, about 250 lines of package prose, game 330), about 300 deleted, over **5 working days**: about 300 LOC/day, the recent attended R2 rate (R2-CAMERA 1,700 LOC in about 5.5 days). Much of it is code moved verbatim under a byte gate, which is slow to verify (83 s per `make sound-synth-check`) rather than slow to write.

## What the survey found

- `tools/audio/synth.ail` (224 lines) is generic; `synth_main.ail` is the FS shell; `synth_test.ail` holds 18 named checks plus the reference PCM sha256 `28ee281f…7467`; `review_main.ail` renders the listening page and (after #319) places one-shots at start times.
- `make sound-synth-check` on the base with the pinned runtime: `synth-ok 28ee28 VM = interpreter; 19 sounds regenerate byte for byte`, 83 s.
- Provenance rows hash `tools/audio/synth.ail` itself (`21289da2…`); `SoundData.check_rows` requires only that the three fields exist.
- `std/audio` writes WAV and Opus but reads nothing; reported upstream (ailang#1930) together with the missing fixed-precision float formatter.
- **Spike** (design §Evidence): AILANG's port of `sound_check.gd`'s four offline measures matched the GDScript to 0.01 dB on six shipped sounds; all 19 measured in 9.8 s on the VM; strict VM = interpreter on the probe.
- `sunholo/celestial` 0.5.0 is the house pattern: pure exports, `[effects] max = ["IO"]` for `_smoke.ail` only, AGENT.md, `ai_summary`, CHANGELOG with the release kind, `_smoke.ail` probes compared strict VM vs interpreter, and `ailang pkg quality` with no gates (`--no-run` on a copy: no gates, PUB011/PUB016 informational).

## Milestones

### AU0: baseline (~20 LOC, 0.5 day)
- On the base that contains #319: `make sound-synth-check` (expect 28 sounds; **stop and report** if it prints another count or fails), `make sound-check` (keep `.godot/tmp/sound/measure.json`), `make sound-review`; write `tests/fixtures/sound/review_sha256.txt` (`cd build/sound_review && shasum -a 256 *.wav *.ogg | LC_ALL=C sort -k2`).
- Re-read #319's merged `tools/audio/review_main.ail`: `mix.tile` copies its `at` semantics as merged, not as in the open PR.
- Re-run the spike's four measures on all 28 sounds against `measure.json`. Any cell off by one centi-dB is recorded here and decides the parity rule (integers vs 1e-9 unrounded) before AU2.
- **Gate:** the fixture is committed; the three commands are green on the base.

### AU1: the package core, moved verbatim, then generalised (~630 LOC incl. 220 tests, 1.5 days)
- **Path pin (AU1–AU3):** the game branch pins `{ path = … }` to the local `ailang-packages` clone. It works only on this machine, so no PR is opened, no rig or CI run is requested and `make deps` is not expected to pass until AU4; the path pin never reaches `main`.
- **Red first** (in `ailang-packages`, branch `feat/audio`): `recipe_test.ail` with every check from the game's `synth_test.ail` and golden pin 1 (`28ee281f…`); `dsp_test`, `noise_test`, `pcm_test`, `mix_test` from design §D5. They fail because the modules do not exist.
- **Step 1, the pure move:** `synth.ail` split into `dsp`, `noise` (`noise` → `rampNoise`), `recipe`, `pcm` with no change to any expression; the game branch pins `{ path = … }`, imports the package, and runs `make sound-synth-check`. Green before step 2.
- **Step 2, generalise:** `rate` in `Recipe` (default 48000; add `rate: 48000` to every `Recipe` record literal in the tests and in `synth_test.ail`), `parseRecipesAs`, `wavInfo`, `pcm16Floats`, `wav16`, and `mix` (`tile`, `sum`, from `review_main.ail` with #319's `at`). `make sound-synth-check` again on the path pin.
- **Gate:** `ailang check --package $PKG`, `ailang test --package $PKG`, the skeleton through `ailang pkg quality $PKG` (no gates already), `make sound-synth-check` on the path pin.

### AU2: analysis in the package, the levels check in the game (~450 LOC incl. 110 tests, 1 day)
- **Red first:** `analysis_test.ail` (closed forms: the gated sine RMS −2.83 dB, the one-pole |H| at 1 kHz, a 60 Hz low-band fail and a 2 kHz pass, seam of whole-cycle and cut sines).
- **Build:** `analysis.ail` (`peak`, `rmsGated`, `level` in centi-dB, `highpassKeepDb`, `lowbandDb`, `seam`; `gainToDb` exactly `sound_check.gd`'s `20.0 * log(x) / log(10.0)`); game `tools/audio/levels.ail` (the cue rules of `sound_check.gd`, design §D9, plus a pure `levelsProbe` compared strict VM vs interpreter) and `levels_main.ail` (FS shell, `levels.json`); `mk/sound.mk`: `sound-levels` and `sound-levels-parity` (depends on `sound-check` and `sound-levels`; compares every cue's RMS and peak and the guard values where present, design §D9), both in `test:`. `sound-synth-check`'s `verify` step moves from `synth.ail` to `levels.ail`.
- **Gate:** AC8 and AC9 on the path pin; the two negative controls fail as expected.

### AU3: package finish and publish (~320 LOC incl. prose, 0.75 day)
- `_smoke.ail` (`main` prints `OK: …`; `renderProbe`, `wavProbe`, `levelProbe`), contracts (design §D5), AGENT.md (when to use, the recipe schema field by field, the render-stability contract, the ×32767/÷32768 note, the two noise generators), CHANGELOG `## 0.1.0`, `ai_summary`, `[release] kind = "feature"`, `ailang = ">=0.54.14"`, `[stability] level = "experimental"`.
- **Gate:** AC1–AC3, and AC6, AC8 once more on the path pin from the final package tree. Then `cd packages/audio && ailang publish` under Mark's standing approval for `sunholo/*` (no crew_lab involvement). The package PR in `ailang-packages` merges after publish, as for celestial 0.5.0.

### AU4: the game pins the registry package (~80 LOC, −300, 0.75 day)
- `tools/audio/ailang.toml` → `"sunholo/audio" = "0.1.0"`; `ailang lock`; commit `tools/audio/ailang.lock`. `Makefile` `deps` locks `tools/audio` with the same diff guard as `sim/`.
- Delete `tools/audio/synth.ail`; trim `synth_test.ail` to the game's pin (the reference recipe through the package, strict VM = interpreter).
- `synth_main.ail` provenance from the lock (design §D6): `Args.generator` → `Args.lock`, `SOUND_SYNTH_ARGS` passes `"lock":"tools/audio/ailang.lock"`; `make sound-synth` regenerates `data/audio/assets_synth.json`; only provenance changes (AC7).
- Open the game PR now (registry pin only), READY, with the rig run.
- **Gate:** AC4–AC12; then the rig `make test` (AC13) via `tools/rig_check.sh`.

### AU5: evaluation and landing (0.5 day)
- `sprint-evaluator` run by a different model from the executor (100 points, 70 to pass) → `.ailang/state/evaluations/eval_R2-SUNHOLO-AUDIO_round_1.json`.
- Landing: this doc and the design doc to `design_docs/implemented/r2/`, a report (the parity table for all 28 sounds, timings, upstream status of ailang#1930), a changelog fragment `changelogs/unreleased/<date>-sunholo-audio.md`, the index row updated.

## Pause points

1. **Now:** Mark approves the plan and OQ1–OQ8 (a new ledger row, attended).
2. No listening pause: the bytes do not change, and AC6/AC10 prove it.
3. Publishing is covered by the standing approval, but only after the path-pin gate (AU3) is green; if any AC6–AC9 check needs a byte or number change to pass, execution stops and asks.

## AILANG syntax checklist (per module)

| Module | Contracts | Effects | Inline tests |
|---|---|---|---|
| `dsp` | include: `clamp16` ensures int16 range; `onePole` requires `cut > 0 && rate > 0`; `centiDb` | pure (no row) | include: `tests [...]` on `clamp16`, `centiDb` |
| `noise` | skip: float range ensures are unencodable for Z3 (PUB016); covered by named tests | pure | include: determinism pairs |
| `recipe` | include: `frames` requires `seconds >= 0`, ensures `result >= 0` | pure | skip: covered by `recipe_test.ail` named checks (renders are too long for inline rows) |
| `pcm` | skip: `wavInfo` returns `Err` on bad input instead of requiring | pure | include: `tests [...]` on `pcm16` of [0.0, 1.0, -1.0] |
| `mix` | include: `tile` requires `n >= 0` | pure | include: a 3-sample loop tiled to 7 |
| `analysis` | include: `level` requires a finite gain (`gainDb > -1000.0 && gainDb < 1000.0`) | pure | skip: closed-form checks live in `analysis_test.ail` |
| `_smoke` | skip: probe | `! {IO}` (`main` only) | skip: it is the probe |
| game `levels` / `levels_main` | skip: game rules, checked by `make sound-levels` with negative controls | `levels` pure; `levels_main` `! {FS, IO}` | skip: make target |

## Validation (per milestone, focused)

`make sound-synth-check` (AC6), `make sound-levels`, `make sound-levels-parity` (needs Godot; wrap with `perl -e 'alarm 900; exec @ARGV'`), `make sound-assets-check`, `make python-guard`, `make deps`; in the package `ailang check/test/verify --package` and `ailang pkg quality`. The full `make test` runs once, on the rig, at AU4.
