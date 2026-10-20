# R2-SOUND: the ship's sound, heard from inside

**Status:** Proposed 2026-10-20, awaiting Mark's approval (design and sprint plan only; nothing is built). A throwaway spike de-risked the pipeline (§Evidence).
**Release:** R2. **Milestone:** the first sound in the game: the bridge, the voyage's moments and the interface, mixed and tested headless.
**Priority:** P1 for R2. Mark, after playing the bow-facing bridge (ledger D-98, 2026-10-20): *"it looks really great. obviously we need animation on the captain a bit and sound effects and the level design but such good potential"*.

**Implements** (design repo; a companion canon doc is proposed in [stapledons-design PR, §D10](#d10-canon-for-the-design-repo)):
- [features/phase1-data-models/ship-structure.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase1-data-models/ship-structure.md) "The Spire": **"Low constant hum, felt as much as heard"**; the Archive's voice "from any terminal"; "Ambient audio per zone".
- [lore/archive/one-g.md](https://github.com/sunholo-data/stapledons-design/blob/main/lore/archive/one-g.md) (in game as `data/lore/archive/one-g.md`): *"A boost to cruise speed can take 10 minutes … Inside, the teacup on the table does not tremble. And when the drive is silent and the ship coasts between stars, you still weigh what you weigh."* This is the **teacup rule** (§D3).
- `nothing-crosses.md` (nothing material crosses the wall; only light) and `photon-drive.md` (the drive throws light aft): no exhaust, no thruster hiss, no sound from outside (§D3).
- `weather-between-the-stars.md`: dust grains meet the wall and flash on the forward dome; the dust layer the sim already draws (R1-ISM-DUST) becomes an instrument you can hear (§D6).
- [features/future/bubble-constraint.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/bubble-constraint.md) "Audio": *"Muffled external sounds (everything is mediated)"*, *"Signal reception sounds"*. [features/future/bubble-ship-layout.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/bubble-ship-layout.md): *"Ambient soundscapes per location"*.
- [vision/design-decisions.md](https://github.com/sunholo-data/stapledons-design/blob/main/vision/design-decisions.md) 2026-09-28 (D-7, D-8): every crew line is spoken in a per-character voice, no live real-time voice, text-only always available. This plan mixes those voices; it does not generate any.
- [decisions/0001-engine-and-architecture.md](https://github.com/sunholo-data/stapledons-design/blob/main/decisions/0001-engine-and-architecture.md): audio runs in Godot; the sim stays pure.
- This repo: ledger D-91 to D-98 (fixed views, the bow, the spire light D-96, the bridge accepted D-97/D-98); [camera-forward.md](../../implemented/r2/camera-forward.md) (Bow, Astern, console zoom); [deck-layout.md](deck-layout.md) (the stations, the lift, the spire light).

**Depends on:**
- The bridge as built by R2-DECK-LAYOUT (DL1–DL3: station use points, the lift, the spire light). Sound sources attach to those nodes by name.
- The sim's existing events, unchanged: `committed`, `phase` (`from`/`to`: `boosting`, `cruising`, `braking`, `at_rest`), `arrived`, `hold_limit`, `crew_hold`, `archive` (`bh_enter`), the drawn dust `impacts` and the `medium` in `ship.ism` (read today by `interior/dust_flash.gd` and `ui/ism_hud.gd`). **No sim, protocol or replay change.**
- Godot 4.7.2: buses, `AudioEffectCompressor` sidechain, `AudioEffectHardLimiter`, `AudioEffectReverb`, `AudioEffectCapture`, `AudioStreamPlayer3D`, WAV import with QOA compression.
- AILANG v0.54.14 `std/audio` (`wavFromPcm`, deterministic Ogg Opus `encode`) for the synthesis tool and the review renders.
- **No physics change** except the optional home beacon (OQ6), which reads the Doppler factor the package already provides (`Planets.doppler_seen64`, sim γ and 1−β). No new formula.

**Estimated LOC:** game about 1,800 (sound director and cue table 450, tests 500, settings and bus layout 150, review and loudness tools 250, AILANG synthesis tool 300, data 100, the lift and tour signals 50). Assets: about 35 cues, about 60 files.

## Game vision alignment

Scored with the `game-vision-designer` skill (feature-validation mode, against `vision/core-pillars.md` and the D-7/D-8 voice decisions), 2026-10-20. No prior sound decision exists, so nothing conflicts. **ALIGNED.**

| Pillar | Score | Rationale |
|---|---|---|
| Choices Are Final | +1 | The commit gets a hold tone that rises while you hold and a single sealing chord when the sim accepts it (`committed`). An irreversible act sounds irreversible. There is no undo sound because there is no undo |
| The Game Doesn't Judge | +1 | A design rule, checked by a test (§D7): **no success or failure stingers**. Arrival, a crew concern and a hold limit each get a neutral instrument cue; nothing sounds like a reward or a punishment |
| Time Has Emotional Weight | +1 | The coast is quiet: when the drive falls silent the ship is just its hum and its people. The crossing interlude gets its own bed under the Archive's voice. The optional home beacon (OQ6) drops in pitch as Earth recedes in time |
| The Ship Is Home | +2 | The bridge stops being silent: footsteps on the plating, the consoles waking, the lift, the spire's hum that is always there, the crew and the Archive in a mix where voices always win |
| Grounded Strangeness | +1 | Hard physics heard honestly: **no sound from space**. The drive is never a rumble (the teacup rule); dust impacts are heard only through a counter that ticks for the grains the sim actually draws |
| We Are Not Built For This | +1 | A 100 m dome answers every footstep with a long tail; between stars the only constant is a machine nobody can enter |
| **Net** | **+7** | **Go.** No pillar is negative |

## Problem

1. **The game is silent except for two voice players.** The only audio in the tree is `ui/conversation/conversation.gd` (crew lines) and `ArchiveVoice` in `demos/ship_geometry_demo.gd` (the crossing telling). Both play on the default Master bus; there is no `default_bus_layout.tres`, no volume setting and no ducking. `git ls-files | grep -iE '\.(ogg|wav|mp3)$'` lists nothing in `assets/` or `data/`.
2. **Mark named it** after the DL3 playtest (D-98): sound effects, alongside captain animation and level design.
3. **The canon already constrains sound and nobody has written it down.** The spire hums (ship-structure.md); the teacup does not tremble during a boost (one-g.md); nothing material crosses the wall (nothing-crosses.md). A naive pass (engine rumble, thruster hiss, whooshing stars) would contradict three lore entries.
4. **The design repo's old audio plans are Go-era** (`features/future/asset-pipeline-hardening.md`: an Ebiten `AudioManager` playing `FrameOutput.Sounds` ids from the sim). In the Godot architecture the sim must not know about sound (CLAUDE.md gate 4), so that design does not carry over.
5. **Nothing tests audio.** A cue could stop firing, clip or drown a voice and no gate would notice.

## Goals and non-goals

**Goals**
- G1. **A diegetic soundscape.** Every sound has a source inside the ship (a machine, a surface, an instrument, a person), plus one quiet interface layer. Nothing is heard "from space".
- G2. **The bridge sounds like a place:** room tone, the spire's hum, footsteps, consoles, the lift, the Archive terminal, positioned in 3D around the captain.
- G3. **The voyage's moments are heard:** plan, commit, boost, cruise, brake, stops, arrival, the braking notice, hold limits, crew holds, the crossing interlude, and the dust counter.
- G4. **A mix with rules:** buses, voice ducking, a limiter, per-level reverb, volume settings, mute when unfocused, a reduced-audio option, and visual counterparts for every cue that carries information.
- G5. **Deterministic and tested headless:** a cue log that is byte-identical across runs for the same session, loudness bands per cue, and licences and sizes for every file, all in `make test`.
- G6. **A pipeline that obeys the repo's language rule:** tonal sounds are synthesised by an AILANG tool (strict-VM core, VM = interpreter, byte-identical WAVs); foley comes from CC0 libraries with a recorded licence. No Python step, no API spend, no keys.

**Non-goals**
- Music (OQ4: deferred; the Music bus exists with nothing on it).
- Generating voices or changing the AI service (D-7/D-8 stand; voices are only routed and ducked).
- Sound for levels below the bridge, beyond the lift and a per-level reverb hook (level design is its own track, D-98).
- The Commons (legacy; it gets room tone only if it is still reachable at S1).
- Literal physics of sound in a relativistic frame (there is none to hear from outside; §D3).
- Sound on the website (later, as part of a news post, with no spoilers).

## Evidence: the spike (2026-10-20, throwaway, not committed)

Run in `$TMPDIR/sound-spike`, deleted with the scratchpad:
- **AILANG synthesis works and is fast.** A 2 s, 48 kHz, 16-bit mono spire hum (55 Hz with a 55.35 Hz partner for a slow beat, 110/165 Hz partials, a 0.25 Hz swell, fades) built with `std/math.sin`, `std/bytes.fromInts` and `std/audio.wavFromPcm`: **0.28 s on the VM, 7.7 s on the interpreter, byte-identical** (sha256 `3c3d6ead…af38`, 192,044 bytes). The FS write is evaluator-only on the strict VM (Phase 2E), so the synthesis core is a pure module and the writer a shell, as `sim/tools/*_main.ail` already do.
- **Godot loads it the way the game loads voice lines** (`AudioStreamWAV.load_from_buffer`): 48,000 Hz, mono, 2.000 s, peak −8.47 dBFS, RMS −15.76 dBFS, matching the synthesis.
- **Headless Godot mixes.** With `--headless` the Dummy driver still runs the mixer: a player on a bus with `AudioEffectCapture` delivered 40,448 frames in about 1 s at 44.1 kHz with peak 0.377 (= −8.47 dBFS). So loudness, ducking and limiter checks can run in `make test` on the rig and on GitHub, with no sound card.
- **The effects the checks rely on process headless too** (second spike, synthetic tones, captures on each bus):
  - **sidechain ducking:** a Ship bus with an `AudioEffectCompressor` sidechained to Voice dropped from RMS 0.177 to 0.0013 when a voice tone started (42.9 dB with deliberately extreme settings);
  - **the limiter:** a full-scale tone at +6 dB through `AudioEffectHardLimiter` (ceiling −1 dB) peaked at exactly −1.00 dBFS;
  - **3D panning:** an `AudioStreamPlayer3D` 5 m to the left of the current `AudioListener3D` gave RMS 0.447 left and 0.223 right (about 6 dB), **but only once a `Camera3D` was in the tree**; with no camera it was silent. The test scenes therefore carry a camera, as the game does.
- **Import:** Godot 4.7 imports WAV with QOA compression by default (`compress/mode=2`): the 192,044-byte hum became a 39,247-byte sample (4.9×). This repo ignores `*.import` (`.gitignore`), so the default is what every machine and the export get; loop points are set at load from `assets.json` (§D1), not from committed import files.

## Design

### D1. Architecture: where sound lives

```
sim (pure, unchanged) ──NDJSON──▶ SimBridge.stepped(events) ─┐
                                                              ├─▶ SoundDirector ──▶ buses ──▶ device
UI signals (consoles, map, commit, crew, archive, lift) ──────┤        │
game state (walk distance, view, level, settings) ────────────┘        └─▶ cue log (ring buffer, tests)
```

- **`audio/sound_director.gd`** (`class_name SoundDirector`, a Node the ship scene creates as it creates `ArchiveVoice`): owns the players, reads `data/audio/cues.json`, subscribes to `SimBridge.stepped`, the consoles' `used(station, action)`, the HUD's and map's signals, the camera director's view and the lift. It never sends anything to the sim.
- **`data/audio/cues.json`** (schema `stapledons.audio.cues/1`): one row per cue: `id`, `trigger` (`sim_event` + `k` and optional field match, `sim_state` + section/field edge, `ui_signal` + emitter/signal/args, or `game` + name), `streams` (asset ids), `bus`, `volume_db`, `variants` and `pitch_cents_spread`, `source` (`ui` or a scene node name for 3D), `loop`, `cooldown` (in the trigger's own clock, below), `priority`, `visual` (§D7) and `about`. Validated on load; an invalid table fails `make sound-test`.
- **`data/audio/assets.json`** (schema `stapledons.audio.assets/1`): one row per file: path, bytes, sha256, rate, channels, `source` (`synth:<generator>@<sha>:<recipe>` or a URL), `licence`, `author`, loop points (applied to the loaded `AudioStreamWAV` at load). §D8.
- **Deterministic variation.** Variant and pitch choice come from a hash of `(cue id, the cue's fire count)`, not Godot's RNG, so a recorded session renders the same audio twice. (`AudioStreamRandomizer` is not used for that reason.)
- **The clocks: never wall time, never frames.** Every cue is ordered and rate-limited in the clock of what triggered it, so the log does not depend on frame rate, time scale or machine:
  - **sim cues** are keyed `(sim tick, event index within the tick's events)`; their cooldowns count sim ticks;
  - **dust ticks** use each impact's own ship time (the tick's start τ plus the impact's `t_s`); the 25 ms dead time is measured in that time, so a step that delivers many impacts at once (high time scale) yields the same ticks as many small steps. At most 8 ticks sound per sim tick; the rest are logged as a count (`dust_tick ×n`) and not played;
  - **UI and console cues** are keyed by an input sequence number the director increments per accepted UI signal; cooldowns count those;
  - **footsteps** use an integer accumulator in millimetres (each frame adds `round(1000 · walked metres)`); a step fires at every whole 700 mm. The test drives the accumulator directly: 6,990 mm gives 9 steps, 7,000 mm gives 10;
  - **state edges** (a lift starting or arriving, the stop turn beginning or ending) come from signals, not polling: `demos/ship_demo_lift.gd` gains `started(level)` and `arrived(level)` (it exposes only `travelling()` today), and the guided tour gains `attitude_hold_changed(on)` (today a field, `solar_tour.attitude_hold`). Both are small additions to S1 and S2.
- **The cue log.** Every fire appends `clock key, cue id, variant, pitch, volume` to a ring buffer the tests read. It is the contract between game events and sound, and it is what `make sound-test` compares with goldens.
- **The existing voice players move onto the Voice bus** (`conversation.gd`, `ArchiveVoice`); their behaviour and tests are otherwise unchanged.

### D2. The mix

| Bus | Feeds | Effects |
|---|---|---|
| Master | device | `HardLimiter` ceiling −1.0 dB |
| Voice | Master | none (crew lines, the Archive) |
| Ship | Master | `Compressor` sidechained to Voice (ducks ≥ 6 dB while a voice plays), `Reverb` (per level, §D5) |
| ↳ Ambience | Ship | room tone, spire hum, interlude bed |
| ↳ Effects | Ship | machines, lift, phase cues, footsteps |
| ↳ Instruments | Ship | dust counter, nav tones, home beacon (own slider: OQ5) |
| UI | Master | `Compressor` sidechained to Voice (lighter, ≥ 3 dB) |
| Music | Master | sidechained to Voice; **empty** (OQ4) |

- **Levels** (targets for `make sound-check`, at the bus output with default settings): voice −16 to −20 dBFS; effects −20 to −28; UI −26 to −32; ambience beds −30 to −38; spire hum −32 to −40 (constant, so it must sit low enough to forget); every cue's sample peak ≤ −3 dBFS.
  - **RMS** for a one-shot is taken over its active span (samples above a −60 dBFS gate); for a loop, over exactly one loop length.
  - **Headroom is measured before the limiter.** A capture sits ahead of the limiter on Master, and with every cue playing at once its peak must stay ≤ −1 dBFS: the mix fits without the limiter's help. Separately the test asserts that the limiter is present on Master with its −1 dB ceiling, as the safety net (a check after the limiter alone would pass by construction).
- **Laptop speakers.** Mark plays on a MacBook Air, whose speakers barely reproduce 55 Hz. Every low sound (the hum, the boost) carries harmonics above 150 Hz, checked by rendering it through a 150 Hz high-pass and requiring at least half its RMS (−6 dB) to survive.
- **Settings** (`ui/game_settings.gd`, `settings.cfg`): Master (default 80%), Voice, Effects, Ambience, Instruments, UI, Music (100%); Mute when the window is unfocused (on); **Reduced audio** (off): halves the dynamic range of alerts, removes transient attacks, keeps every cue. Sliders map linearly in dB from −40 dB to 0 dB, and 0% is mute.

### D3. The canon: what can be heard (the diegetic rule and the teacup rule)

1. **Nothing is heard from outside the bubble.** Space has no medium, and nothing material crosses the wall (`nothing-crosses.md`). Stars, planets, the starbow, black holes and the drive's beam are silent. What reaches the ear is the ship.
2. **The teacup rule.** A boost is not felt (`one-g.md`), so it may not sound like a rocket: **no rumble below 80 Hz, no shake, no hull stress during boost or brake.** What changes is the machinery: the drive's emitter rises to a clean, high tone with the generator's partials stepping up, then it settles. When the ship coasts, **"the drive is silent"**: the emitter fades out and only the spire's hum and the room remain.
3. **No exhaust, no thrusters.** The stop turn (the ship turning the body 30° off the bow) has no RCS hiss: nothing leaves the bubble but light. A soft navigation tone tracks the turn instead.
4. **The spire hums, always** (ship-structure.md): constant, low, positioned at the mast, never tied to the drive. Its light dims as a star takes over (D-96); its hum does not.
5. **Instruments may sonify what the ship measures**: the dust counter (§D6), the home beacon (OQ6), the navigation tones. They are machines on the bridge, so they are diegetic.
6. **One non-diegetic layer**: interface clicks, quiet and short, on the UI bus.
7. **No judgement** (Pillar 2): no fanfare, no "success" or "failure" stinger, anywhere.

### D4. The bridge (S1)

| Cue | Trigger | Source | Notes |
|---|---|---|---|
| `room_bridge` | level = bridge | Ambience, 2D | air handling under the dome; a 12 s seamless loop |
| `spire_hum` | always | Ambience, 3D at the mast | §D3.4; synthesised loop with integer cycles so it never clicks |
| `footstep_deck` | every whole 700 mm of captain walk distance (integer accumulator, §D1) | Effects, 3D at the captain | 6 CC0 variants; deterministic choice; stride from data, so the count = ⌊distance / stride⌋ |
| `console_wake` / `console_sleep` | console zoom in / out (`ShipConsoles.used`) | Effects, 3D at the station | the screen and servo; the Crew, Voyage and navigation stations share them |
| `console_key` | a console action | UI | short and quiet |
| `lift_start`, `lift_run`, `lift_arrive` | the lift's new `started(level)` / while travelling / `arrived(level)` signals | Effects, 3D at the lift | an old brass chime on arrival (Moebius / *Métal Hurlant* style brief) |
| `archive_open`, `archive_ready` | terminal opened / the Archive's reply arrives (`stepped` AI event) | Instruments, 3D at the terminal | the reply cue is a soft tone, not a voice |
| `crew_open` | Crew console opened | Effects | |

- **The Bow ↔ Astern switch is silent** (OQ8): the camera is not an event in the world, so it has no cue row.
- **The listener** (`AudioListener3D`) sits at the captain's head, turned to the active view's yaw, so what is on the left of the screen is on the left in the ears, in Bow and in Astern (OQ7). The console zoom keeps the captain's position.
- **Attenuation:** inverse distance, unit size 3 m, max distance 60 m; the spire's hum has a floor so it is never fully gone on the bridge.

### D5. Levels and rooms

- `data/audio/rooms.json`: per level, the room tone cue and the Ship bus reverb (room size, damping, wet). The bridge under the 100 m dome: room size 0.8, wet −14 dB, a long tail that makes footsteps sound small.
- Arriving on a level (the lift's level change, which already selects the level's default view) swaps the room tone with a 1.5 s crossfade and sets the reverb. Lower levels get rows when level design lands; until then they inherit the bridge's.

### D6. The voyage (S2)

| Cue | Trigger | Bus | Notes |
|---|---|---|---|
| `plan_select` | galaxy map `target_selected` | UI | |
| `commit_hold` | the commit confirm (hold or twice, `confirm_mode`) | Effects | pitch rises with the hold progress; stops cleanly if released |
| `commit_seal` | sim event `committed` | Effects | a single chord, low-mid, the generator settling under it. Fires on the sim's acceptance, never on the key press |
| `drive_boost` | `phase` to `boosting` | Effects, 3D below the deck | §D3.2: emitter up over 4 s, then a held high tone at low level |
| `drive_silent` | `phase` to `cruising` | Effects | the emitter fades over 6 s; the coast is the hum and the room |
| `drive_brake` | `phase` to `braking` | Effects | the boost's mirror |
| `stop_turn` | the tour's new `attitude_hold_changed(on)` signal | Instruments | a soft navigation tone while the ship turns; no hiss (§D3.3) |
| `arrived` | sim event `arrived` | Instruments | a neutral two-note chime |
| `brake_notice` | `BRAKE_NOTICE` shown | Instruments | |
| `hold_limit` | sim event `hold_limit` | Instruments | an alert, not an alarm (Pillar 2) |
| `crew_hold` | sim event `crew_hold` | Instruments | |
| `dust_tick` | each drawn dust impact (`ship.ism.impacts`, as `interior/dust_flash.gd` reads them) | Instruments, 3D at the helm | a counter's tick, Geiger-style dead time 25 ms; the rate is the sim's drawn rate, so it rises with speed and in the warm clouds and falls in the hot bubble |
| `medium_change` | `ship.ism.medium` changes | Instruments | entering or leaving a cloud |
| `interlude_bed` | crossing interlude shown | Ambience | a slow bed under the Archive's telling; ducked by Voice |
| `bh_enter` | `archive` event `bh_enter` | Instruments | a low instrument sweep; reveals nothing beyond what the screen shows |
| `home_beacon` | optional (OQ6), in transit | Instruments | Earth's carrier at the helm; pitch follows the Doppler factor, compressed (below) |

**The home beacon (OQ6).** If Mark agrees that Earth keeps a beacon aimed at the ship, the helm's receiver plays its carrier continuously in transit. Its pitch shift in semitones is `12 · k · log2(D)`, with `D` the package's Doppler factor for Sol's apparent direction (`Planets.doppler_seen64`, sim γ and 1−β, never `1.0 - beta` in GDScript) and `k = 0.25` in data, clamped to ±24 semitones. Outbound at 0.99c, Sol is astern: D = 0.0709, so the carrier drops about 11.5 semitones; at a stop it returns to its true pitch; heading home it rises. The mapping is **not physical** (the true shift would be inaudible) and is labelled so, as the star light's brightness mapping is (`ship_star_light.gd`).

### D7. Accessibility and the no-judgement rule

- Every cue row has a `visual` field: either the HUD or console element that already shows the same information (for example `arrived` → the arrival card, `hold_limit` → the hold-limit line, `brake_notice` → the notice) or `ambient: <reason>` for sounds that carry no information (room tone, footsteps). `make sound-test` fails if an informative cue has no visual counterpart, or if a named counterpart does not exist in the code.
- A list of forbidden words in cue ids and `about` fields (`success`, `fail`, `win`, `lose`, `reward`, `penalty`, `fanfare`, `victory`) is checked by the same test.
- Text-only mode (D-8) keeps every voice line as text; this plan does not change it.
- Reduced audio and per-bus volumes (§D2) cover sensitivity to sound; Mute when unfocused is on by default.

### D8. Sourcing, licences and the pipeline

| Route | For | Licence | How |
|---|---|---|---|
| **A. AILANG synthesis** | tonal and machine sounds: the hum, the drive, instruments, chimes, UI, the interlude bed | our own (`synth-own`) | `tools/audio/synth.ail` (pure core, strict VM, VM = interpreter) + `synth_main.ail` (FS shell); recipes in `data/audio/recipes.json`; `make sound-synth` writes `assets/audio/synth/*.wav`; `make sound-synth-check` regenerates and compares sha256 |
| **B. CC0 library** | foley: footsteps on metal, the lift's mechanism, chair and cloth | CC0-1.0 only | first choice **Kenney.nl** CC0 packs (direct download, no login, so an agent can fetch them with `curl` and record the URL and sha256); Freesound's CC0 filter only when Mark fetches a file himself (it needs a login); WAV only, the URL and author recorded per file; **if no CC0 source fits, a synthesised placeholder ships so S1 never stalls**; trims and fades by the AILANG tool (WAV in, WAV out), never by an editor whose steps are not recorded |
| C. Generative AI SFX | none in this sprint | — | API spend is attended and licences vary; out of scope (OQ3) |

- **No Python** (the repo rule): synthesis and WAV trimming are AILANG; loudness checks and review renders are Godot headless; downloads are shell.
- **Formats:** sources are 48 kHz, 16-bit WAV, mono (stereo only for beds); Godot imports with **QOA** compression (about a fifth of the size); loops carry loop points in the import settings.
- **Budget:** at most 12 MB of WAV sources in git (checked); at most 6 MB added to the exported zip (checked by `export-pack-check` on the rig). Beds are short loops (8–20 s) so neither budget is close.
- **Review renders:** `make sound-review` renders each cue and a 60 s bridge walk through the real buses (Godot headless capture, written as WAV by Godot), compresses them to Ogg Opus with `std/audio.encode` (deterministic), and writes an `index.html` of players. Published to `gs://stapledons-voyage-assets/refs/sound/<stage>/` (standing approval) with per-file URLs.

### D9. Determinism and tests

- **`make sound-test`** (headless, in `make test`):
  - the cue table and asset manifest validate; a renamed trigger, a missing stream and an unknown bus each fail (negative controls);
  - **scenario goldens:** a short recorded session (plan, commit, boost, cruise, brake, arrive, one stop) driven through `ui/transit_harness.gd` with a SoundDirector attached gives a cue log equal to `tests/fixtures/sound/cue_log_voyage.txt` byte for byte, in **two separate Godot processes** (so state left in the director would show); the footstep accumulator gives 9 steps for 6,990 mm and 10 for 7,000 mm; a console zoom in and out produces wake then sleep;
  - every informative cue has a visual counterpart; no forbidden words (§D7);
  - the home beacon's pitch at β = 0, 0.9, 0.99 (Sol astern and ahead) matches `12 · k · log2(D)` from the package mirror to 0.01 semitone (only if OQ6 is accepted).
- **`make sound-check`** (headless capture, in `make test`): each cue alone through its bus chain at default settings lands in its band (§D2) with sample peak ≤ −3 dBFS; with all cues at once the capture before the Master limiter peaks ≤ −1 dBFS, and the limiter is present with its −1 dB ceiling; a voice line ducks Ship by ≥ 6 dB; the hum and the boost keep ≥ −6 dB of their RMS through a 150 Hz high-pass; a +6 dB hot fixture fails (negative control).
- **`make sound-synth-check`:** the synthesis core passes `--strict-bytecode`; the VM and the interpreter produce identical bytes for a short recipe; regenerating every synthesised file reproduces the sha256 in `assets.json`.
- **`make sound-assets-check`:** every file in `assets/audio/` is in the manifest with matching bytes and sha256; every licence is `CC0-1.0` or `synth-own`; 48 kHz, 16-bit; the git budget holds. Negative controls: a manifest row with a wrong sha256 and one with a `CC-BY` licence each fail.
- **The sim is untouched:** `git diff --stat origin/main -- sim/` is empty; `make strict parity replay` stay green.
- **Frame time** (a GPU-window gate on the rig, not part of `make test`): `make bench SCENE=bridge` keeps the Makefile's absolute p99 < 16.7 ms and stays within 0.5 ms of a baseline recorded on the rig at the start of S0a (`tests/fixtures/sound/bench_baseline.json`, with the host load) (audio mixes on its own thread; the director's per-frame work is the walk-distance check).

### D10. Canon for the design repo

The **what** belongs in stapledons-design: a short `features/next/sound.md` with §D3 (the diegetic rule, the teacup rule, no exhaust, the spire's constant hum, instruments, no judgement) and the palette in words, linking the lore it rests on. Opened as a design-repo PR alongside this plan, not merged.

## Acceptance criteria

| ID | Criterion | Command |
|---|---|---|
| AC1 | Cue table and asset manifest validate; renamed trigger, missing stream and unknown bus each fail | `make sound-test` |
| AC2 | A recorded voyage's cue log equals the golden byte for byte, in two separate processes | `make sound-test` |
| AC3 | Footsteps from the integer accumulator: 6,990 mm → 9, 7,000 mm → 10; console wake/sleep order; lift start/run/arrive order | `make sound-test` |
| AC4 | Sim events map to cues: `committed` → `commit_seal` (never on the key press alone), `phase` to boosting/cruising/braking → drive cues, `arrived`, `hold_limit`, `crew_hold`, `bh_enter`; drawn impacts → `dust_tick` with 25 ms dead time | `make sound-test` |
| AC5 | Every informative cue names an existing visual counterpart; no forbidden word in ids or descriptions | `make sound-test` |
| AC6 | Per-cue loudness bands, peaks ≤ −3 dBFS, pre-limiter Master peak ≤ −1 dBFS with every cue at once and the limiter present, voice ducks Ship ≥ 6 dB, low cues survive a 150 Hz high-pass within 6 dB, hot fixture fails | `make sound-check` |
| AC7 | Synthesis core strict-VM clean, VM = interpreter, every synthesised file reproduces its sha256 | `make sound-synth-check` |
| AC8 | Every audio file listed with bytes, sha256, rate, licence ∈ {CC0-1.0, synth-own}; ≤ 12 MB in git; wrong-sha and CC-BY fixtures fail | `make sound-assets-check` |
| AC9 | Volume settings persist in `settings.cfg` and set bus volumes; 0% mutes; Mute when unfocused; Reduced audio | `make title-screen-test` (extended: `tests/test_title_screen.gd` covers `GameSettings`) |
| AC10 | The listener follows the captain and the active view's yaw (a source left of the captain in Bow pans left; in Astern it pans right) | `make sound-test` |
| AC11 | The existing voices play on the Voice bus; conversation and crossing tests unchanged and green | `make ai-conversation crossing-review-test` (existing targets) |
| AC12 | No sim, protocol or replay change | `git diff --stat origin/main -- sim/` empty; `make strict parity replay` |
| AC13 | `export_presets.cfg` includes `assets/audio/*` and `data/audio/*`; the exported pack loads the cue table and fires one cue into its log (the export smoke asserts the log line); zip grows ≤ 6 MB | `make export-filter-audit`; `make ship-demo-export-smoke`; `make export-pack-check` (rig) |
| AC14 | Frame time: p99 < 16.7 ms and within 0.5 ms of the recorded baseline (GPU window, rig) | `make bench SCENE=bridge` |
| AC15 | Home beacon pitch matches the formula at the check speeds (only if OQ6 is accepted) | `make sound-test` |
| AC16 | Full suite green | `make test` (rig, `tools/rig_check.sh`) |

## Sub-milestones and estimates

| ID | What | LOC | Depends on |
|---|---|---|---|
| S0a | Foundation: bus layout, SoundDirector + cue log, cue/asset schemas and validation, settings, voices onto the Voice bus, `sound-test` and `sound-assets-check` | 550 | plan approval |
| S0b | The AILANG synthesis tool and the first synthesised set (hum, room tone, UI, chimes, drive tones), `sound-check` (loudness), `sound-synth-check`, the review renderer. ⏸ **sound board**: Mark listens to every synthesised cue and the hum in place | 450 | S0a |
| S1 | The bridge: room tone, spire hum in 3D, footsteps (CC0), consoles, lift, Archive terminal, Crew console, the listener, rooms.json and the bridge reverb. ⏸ **dev build**: Mark walks the bridge with sound | 380 | S0b |
| S2 | The voyage: plan, commit hold and seal, the drive cues, stop turn, arrival, notices, hold limits, crew holds, the dust counter, medium changes, the interlude bed, `bh_enter`, the home beacon if OQ6. ⏸ **dev build**: Mark plays a voyage with sound | 420 | S1 |
| S3 | Independent evaluation (a different model), landing, changelog, design-repo status | — | S2 |

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| The hum is fatiguing over a long session | It sits at −32 to −40 dBFS, has its own Ambience slider, and is reviewed at the S0 sound board before anything else is built |
| Laptop speakers lose the low end | Harmonics above 150 Hz, checked (AC6) |
| Long beds are slow or memory-hungry to synthesise as one list in AILANG | Beds are 8–20 s loops; the tool renders per second and joins with `concatList`; the spike's rate (2 s in 0.28 s) puts a 20 s stereo bed near 6 s |
| Loops click | Synthesised loops use integer cycles of every partial over the loop length; a test checks the first and last samples join within 1 LSB slope |
| Headless mixing differs between macOS and Linux | Loudness bands are ranges, not exact values; the cue log (exact) never depends on the mixer |
| A cue gives a spoiler (for example something distinctive near Sgr A*) | Cue ids and descriptions are reviewed against the spoiler rule; `bh_enter` reveals only what the screen already shows |
| CC0 provenance is wrong | URL, author and licence recorded per file; Freesound's CC0 filter only; anything unclear is replaced with a synthesised sound |
| Sound competes with crew voices | Voice ducking ≥ 6 dB (AC6); voices are the loudest bus by design |

## Open questions for Mark

| # | Question | Recommendation |
|---|---|---|
| OQ1 | **The diegetic rule** (§D3): only in-ship sources, plus a quiet UI layer; nothing heard from space | **Yes.** Three lore entries already imply it |
| OQ2 | **The teacup rule for the drive** (§D3.2): no rumble or shake during boost and brake; the emitter rises to a clean high tone; the coast is "the drive is silent" | **Yes,** and record it as canon in the design repo (§D10) |
| OQ3 | **Sourcing** (§D8): AILANG synthesis for tonal sounds, CC0 libraries for foley, no generative AI audio or API spend in this sprint | **Yes.** Keeps licences clean and the pipeline in AILANG; revisit AI audio for hero sounds later, attended |
| OQ4 | **Music** | **Defer.** Wire the Music bus empty; the ship's soundscape is the score for now. Decide with level design, where each level may want its own identity |
| OQ5 | **The dust counter** (§D6): a Geiger-style tick at the helm for every grain the sim draws, with its own Instruments slider | **Yes,** on by default, quiet. It turns the dust layer and the clouds into something you hear without breaking the diegetic rule |
| OQ6 | **The home beacon** (§D6): does Earth keep a beacon aimed at the ship? If so, its carrier plays at the helm with a compressed Doppler pitch, low as Earth recedes, true at stops, rising on the way home | **Yes, in S2,** labelled as a compressed mapping. It makes time and distance from home audible (Pillar 3). Canon is Mark's call; if no, S2 drops it and AC15. It is new lore as well as sound, and it sonifies physics, so CLAUDE.md gate 2 applies: the test asserts the pitch against the Doppler factor of `physics/planets.gd` `doppler_seen64` (the GDScript mirror of `sunholo/relativity` 0.7 optics) at the package's probe values; no new formula. If Mark prefers, it moves to its own small follow-up |
| OQ7 | **The listener** (§D4): at the captain's head, turned with the active view | **Yes,** so left on screen is left in the ears in Bow and Astern |
| OQ8 | **The Bow ↔ Astern switch**: silent or a cue? | **Silent.** The camera is not an event on the ship |
| OQ9 | **Pause points**: S0 sound board, S1 bridge dev build, S2 voyage dev build | **Yes,** three listens, each before the next stage builds on it |

## Deliverables

- `audio/sound_director.gd`, `default_bus_layout.tres`, `data/audio/{cues,assets,recipes,rooms}.json`, settings in `ui/game_settings.gd`.
- `tools/audio/synth.ail`, `synth_main.ail`, `synth_test.ail` (AILANG); `tools/sound_check.gd`, `tools/sound_review.gd` (Godot); `mk/sound.mk` (`sound-test`, `sound-check`, `sound-synth`, `sound-synth-check`, `sound-assets-check`, `sound-review`), included from the `Makefile` (`include mk/sound.mk`, beside the other `mk/*.mk`), every target in `.PHONY`; `sound-test`, `sound-check`, `sound-synth-check` and `sound-assets-check` added to the `test:` prerequisites.
- `export_presets.cfg`: `assets/audio/*` and `data/audio/*` added to `include_filter` (it is an explicit list today, so without this nothing reaches the zip); `demos/ship_demo_lift.gd` signals `started` and `arrived`; the guided tour's `attitude_hold_changed`.
- `assets/audio/synth/*.wav`, `assets/audio/foley/*.wav` (CC0) with their `.import` (QOA).
- `tests/test_sound.gd`, `tests/fixtures/sound/*`.
- Review pages at `gs://stapledons-voyage-assets/refs/sound/{s0,s1,s2}/`.
- Changelog fragments; on landing, the doc moves to `design_docs/implemented/r2/`.
- Design repo: `features/next/sound.md` (§D10).
