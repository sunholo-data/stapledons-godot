# Changelog

## Unreleased

### Combined landing checks (2026-10-30)

- Integrate current main and committed Earth-link audio for D-142. Add numeric light-cone/Doppler reference checks and GPU comparisons for the production Earth feed and exchange strip, mirroring the pinned Observe package. Preserve existing golden coverage and keep unfinished feature milestones explicit.

### Painted NPC asset pilot (2026-10-29)

- D-139/D-140: three painted civilian identities and portrait-derived Medic/Chief Engineer figures, with 25 standing/seated pose assets, preserved generation sources/prompts, deterministic Godot ingestion and alpha/height/foot-anchor/hash checks. An opt-in Commons capture mingles the two crew identities among the existing crowd without changing normal game setup. Appearance approval, per-seat contact calibration, live crew binding and production rollout remain pending.

### rig-test-speed (2026-10-29)

#### Added

- **Suite profiling instruments and fixture controls** (R1-RIG-TEST-SPEED M1a). Per-recipe wall/CPU timing, nested-target attribution, load sampling, coverage comparisons and reproducible reports are available through `tools/suite_profile.sh`. The existing rig-check control now runs the profiler's 20 cases on each distinct GNU make; suite execution and rig policy are unchanged.

### rig-watchdog (2026-10-28)

#### Changed

- **`rig/full` allows 120 minutes** (R1-RIG-WATCHDOG, D-126 C). `tools/rig_check.sh` now defaults to a 7,200 s `make test` watchdog (it was 5,400 s, and a 90-minute run had reached it). The rig-check control ignores a caller's `RIG_TEST_S`, so raising the watchdog by hand no longer turns the run red, and a new case checks that an explicit override still takes effect.

## v0.4.0-dev.37-living-bridge (2026-10-26)

### sunholo-audio (2026-10-26)

#### Changed

- **The sound tools use the `sunholo/audio` package** (R2-SUNHOLO-AUDIO, D-119). The game's
  synthesised sounds are now rendered by the published AILANG package (pinned 0.5.0) instead of a
  copy in the game; every sound is byte-identical. The loudness checks (bands, the laptop-speaker
  high-pass, the teacup rule) also run in AILANG now (`make sound-levels`), and agree with the
  Godot-side checks on every cue.

### captain-ca2 (2026-10-26)

#### Added
- The captain's held poses (R2-CAPTAIN-ANIMATION CA2): painted reaches at the stations with a step back, the captain's chair (E at the seat sits; E or a move key stands), a look-up when the ship arrives or the starbow forms, a lift pose, and a slight lean when the captain starts and stops walking (none under reduced motion).

### ailang-0.54.18 (2026-10-26)

#### Changed

#### AILANG v0.54.18

- **Upgrade:** CI, the bundled runtime and the CLAUDE.md pin move to AILANG v0.54.18. The lockfiles
  are unchanged (relativity 0.12.0, celestial 0.5.0, crew_core 0.6.0); `ailang lock` on v0.54.18
  rewrites nothing.
- **Why now:** `sunholo/audio` 0.3.0 onwards requires v0.54.18, which adds the WAV reader and
  fixed-decimal formatting we asked for (ailang#1930); the sound tools move onto the package next.
- **Workarounds re-checked:** an aliased constructor import now matches in a pattern (TC_MATCH_001
  no longer fires); `sim/tripphase.ail` stays as the module boundary. `ailang check --package`
  stays beside `ailang test --package` (only `check` enforces STRICT_FALLBACK_001).

### sound-s1 (2026-10-22)

#### Added
- **The bridge has sound around the captain** (R2-SOUND S1). Footsteps on the plating with every
  step, consoles waking and sleeping where they stand, the lift's latch, motor and bell, and the
  spire's hum at the mast, all placed in 3D so a sound on the left of the screen is on the left,
  in Bow and in Astern. The bridge's air has a long, soft tail under the dome.
- **Footsteps you barely notice** (D-122, D-123). The captain's steps are a soft, dark padding felt
  under the spire's hum rather than heard over it: no hit, nothing bright or metallic, each step a
  little different in level and pitch and every other foot softer, so a long walk never sounds
  like a metronome. The synthesis tool gains `lowpass_poles` (low-passes in series, so a sound can
  be truly dark); every other sound is byte-identical.

### bridge-style (2026-10-22)

#### Changed

- **The bridge is one illustrated world** (R2-BRIDGE-STYLE, D-100, D-104, D-106, D-110). In deep space the
  spire lights the deck and casts soft radial shadows; near a star the star takes over. Every bridge surface is
  banded toon shading with an ink line; the deck and the mast are painted; the desks, the captain's chair, the
  Archive terminal, the benches, the guardrails and the lift are grown, curved forms; the rim fronds are painted
  potted palms, and a few painted fronds frame the Bow and Astern views.
- **The HUD has one look.** Every panel, card, button and screen uses the same ink panels, palette and
  typefaces (Josefin Sans and Nunito, both SIL OFL), with text coloured by what it means.

### star-surfaces-landing (2026-10-21)

#### Star surfaces landed (R2-STAR-SURFACES SS4)

- R2-STAR-SURFACES is complete. The design doc, sprint plan and a new report move to `design_docs/implemented/r2/`. The independent evaluation scored 77/100 (PASS).
- α Cen's activity cycles now use the opened source, Ayres 2014 (arXiv 1401.0847). B's cycle is 8.2 years. A's is 19.1 years, marked as tentative.
- Barnard's Star's 10-year cycle is now cited.
- New tests:
  - the telescope's magnification (whole disc, close-up cell size, no demagnification, clamp);
  - the cited cycle lengths.

### star-surfaces-d111 (2026-10-21)

#### Added

- **The helm's telescope** (R2-STAR-SURFACES, D-111). At the navigation console's close-up, T shows the
  stop's star through the ship's telescope, labelled "telescope ×N" with its true magnification: alpha
  Centauri's spot groups and faculae, TRAPPIST-1's starspots and flares resolve there. The Bow view
  stays true size.
- **A close pass of Sun-like stars.** Free navigation now stops main-sequence F, G and K stars at twice
  the D-54 size: alpha Centauri A fills about 22° of the sky instead of 11°.
- **Each star's own activity.** Spot groups follow each star's real cycle (alpha Cen A quieter, B
  livelier), TRAPPIST-1 is heavily spotted and flares, and Barnard's Star stays quiet, as it is.
- **Eclipses** (SS3). When a body covers part of a star, the corona appears (the Baumbach mean corona,
  with streamers), with hydrogen-alpha prominences at the limb; the last sliver of photosphere glints
  through the starfield's point-spread glow.

### sound-rework (2026-10-21)

#### Changed
- **Sound rework after the first listen (R2-SOUND, D-108).** The bridge's room tone is now barely
  there and the spire's hum leads. The consoles wake and sleep like a precise machine. The drive is
  lower and richer (beating partials, a noise band whose filter opens and closes) and the brake
  rougher, still with nothing felt (a new check keeps everything under 200 Hz at least 20 dB down).
  Arrival is an understated suspended chord. The Archive's reply is a small breathing figure.

#### Added
- **The spire's degradation layer.** A second, much slower beat under the hum that rises as the
  Archive's Memory Health falls. The sim does not emit Memory Health yet, so in game it stays silent.
- Synthesis: vibrato, amplitude beats, filter sweeps, soft saturation and a true white noise.
- **The export carries the sounds QOA-compressed** (D-112): 2.3 MB instead of 11.4 MB, staged by
  `make sound-stage` and proven by `make sound-export-smoke` in the exported app. The room tone is
  another 6 dB lower.

### captain-walk (2026-10-21)

#### Changed
- The captain walks calmly at 1.3 m/s (was a 3.5 m/s jog), for WASD and walk-to: the bridge takes longer to cross (spawn to the helm 2.7 s, to the navigation station 15 s). (D-115)
- The captain's painted animation is a calm walk, now in the game: 12 unique frames a cycle in the back and side views, heel strike to toe off, the coat hanging, the planted foot staying put. (R2-CAPTAIN-ANIMATION)
#### Fixed
- The captain's painted feet rest on the deck instead of sinking below it. (D-118)

#### Added
- A between-frame "echo" on the painted walk: the previous step fades behind the captain for 60 ms, leaning into the stepped cadence (off under reduced motion). (D-118)

### archive-memory-health (2026-10-21)

#### Added
- **The Archive's Memory Health** (ledger D-113). The sim now tracks it, hidden from the player:
  100, one point lost per decade of ship time, ten per entry into a black hole's zone (protocol 2.15).
  The spire's degradation layer under the bridge's hum follows it, so a long or hard voyage
  begins to sound wrong.

## v0.4.0-dev.36-styled-bridge (2026-10-21)

### star-surfaces (2026-10-20)

#### Added

- **Stars show their surfaces** (R2-STAR-SURFACES SS0-SS2, D-105). In the Auto view a star's disc now
  shows what its real surface would show at that size: Aldebaran's giant convection cells (about 33
  across its disc at the stop), red dwarfs' dark starspots with bright faculae, and every star's own
  limb darkening (Claret & Bloemen 2011, per temperature and gravity). Structure appears only where
  it would resolve, so the Sun from home and every distant star look as before, and a star's total
  light is unchanged. Each surface element is a blackbody at its own temperature, so spots are redder
  and the whole surface Doppler-shifts as the disc does. The Realistic view still shows the clipped
  white disc an eye would see.
- **sunholo/celestial 0.5.0** (`stellar`, `stellar_ld`): limb darkening, convection, spot, rotation and
  corona numbers, each cited. **Protocol 2.13**: every finite star carries its `surface` record.

### sound-s0 (2026-10-20)

#### Added
- **Sound, first stage (R2-SOUND S0a and S0b; ledger D-98, D-101).** The game's first sound
  system: a sound director that plays cues for the sim's events, interface signals, the walk and
  game states, keyed in each trigger's own clock so the same session always gives the same cue log.
  A bus layout with voices ducking everything else and a limiter at -1 dB. Per-bus volume settings,
  Mute when unfocused and Reduced audio. Seventeen sounds synthesised by an AILANG tool
  (`tools/audio/`, strict VM = interpreter, byte-identical on every machine): the spire's hum, the
  bridge's air, the interface, the consoles, the commit, the drive (no rumble: the teacup rule),
  the stop turn, the dust counter, arrival, the Archive and the hold limit. Nothing is heard from
  space. The sounds are not yet wired into the bridge and the voyage (S1, S2).
- `make sound-test`, `sound-assets-check`, `sound-synth-check` and `sound-check` in `make test`;
  `make sound-review` renders the listening page (Ogg Opus via `std/audio`).

#### Changed
- The crew's conversation voice and the Archive's crossing voice play on the Voice bus.

### sgr-a-final-stop (2026-10-20)

#### Fixed

- **Sgr A* sat behind the ship after the guided voyage.** The Sgr A* visit set the ship's heading on
  the hole but kept the guided tour's last attitude, and the sky is oriented by that attitude when
  one is set. After the tour (heading for Aldebaran, almost opposite the galactic centre) the hole
  rendered 170° astern. The attitude now belongs to the session that set it: leaving a session
  clears it, and the Sgr A* visit sets its own, nose on the hole. Free navigation after the tour had
  the same stale attitude and is fixed too.
- `make camera-forward-test` AC-V13 checks the hole on the rendered sky (the sky camera the player
  sees through) after a guided voyage, at every stop. AC-V6 had recorded Sgr A* only in a fresh
  session with no tour, so it never met the stale attitude.

#### Changed

- **Sgr A* is the guided voyage's last stop** (Mark, attended 2026-10-20). After the Aldebaran stop
  dwells like every other (12 s of tour time, or Skip dwell [N]), the tour hands over to the Sgr A*
  visit, announced as a demonstration jump with the hole ahead in the Bow view. The HUD reads
  "GUIDED VOYAGE · FINAL STOP · SGR A*". The navigation station's entry still opens it directly.
  `make guided-finale-test` (21 checks) drives the tour's final leg the honest way. The tour card's Skip dwell stays offered at the final stop.
- `make bh-ahead-capture` (GPU window): the final stop and every Sgr A* stop after flying the last leg, Bow view with the HUD, with the hole's angle off the sky camera's axis in the manifest.

### levels-pipeline (2026-10-20)

#### R2-LEVELS: the level pipeline's tools (LP0, LP1a)
- **The level pipeline has its tools** (design_docs/levels/README.md; ledger D-103). These are the shared commands every level of the ship goes through, from greybox to landing:
  - `make level-eval LEVEL=<id>` (traversal, readability, sightlines, the sky band, captain size, finds);
  - `make level-capture LEVEL=<id> TAG=<tag>`;
  - `make levels-regress` (every landed level against its pinned baseline);
  - `make bench SCENE=level LEVEL=<id>`;
  - `sh tools/levels_backlog.sh --check|--next` (the backlog that Mark and the mission loop share).
- **Greybox in the engine:** a level's layout builds as role-coloured boxes, arcs and ramps with colliders and walk surfaces. Curved platforms and catwalks are arcs (D-104).
- **Walking on several heights:** the captain stays on the surface within a step of where they stand, so a terrace overhead is ignored, a ramp is climbed, and a raised edge stops you. The bridge walk is unchanged.
- **The bridge is measured as a one-stage level,** with a regression baseline.

### deck-layout-dl3 (2026-10-20)

#### Changed

- **The whole bridge is dressed** (R2-DECK-LAYOUT DL3, D-97). The Voyage, Crew and reserved desks
  (the two live desks with a brass screen bezel), the rim rail with its lamps and fronds, the Archive
  terminal and shrine ribs, the lift guides and guardrails, and the benches and floor conduits now
  share the navigation arc's painted, inked finish (one painted atlas per set, in `bridge_props.glb`).
  The deck surface and the spire body wait for the styling pass.
- **The help names the current views.** 7 or R is the Bow view, 9 Astern, 8 is reserved, a console
  zooms in; 1-3 and = / - are developer presets. The display panel's camera buttons match.

### captain-animation-ca0 (2026-10-20)

#### Changed
- The captain faces the way they move on screen, in eight directions, so a sideways walk no longer shows the back (the moonwalk). A view switch turns the drawing, not the captain. (R2-CAPTAIN-ANIMATION CA0)

#### Added
- The captain's animation state (`CaptainAnim`): jog by distance, start, stop, stations, the chair, the lift and a look-up, with reduced motion and footstep events for sound. Painted frames come next, after Mark reviews the 10-frame pilot.

## v0.4.0-dev.35-bow-view (2026-10-20)

### deck-layout-dl2 (2026-10-20)

#### Added

- **The spire is the bridge's own light** (R2-DECK-LAYOUT DL2, D-96). A warm lamp on the mast lights
  the bridge when no star is close and hands over to the star as one draws near (it dims with the
  ship's broad key, down to the same 25 % floor); a lamp band on the mast glows with it. The lower
  decks are unchanged.

#### Changed

- **The navigation arc and the captain's chair are dressed** (R2-DECK-LAYOUT DL2 style frame, for
  Mark's approval): painted textures with contact shading and ink creases, an ink outline, and a
  brass screen bezel on each navigation pod's operator face (the live screen sits in the middle
  one). They ship in their own `bridge_props.glb` beside `ship.glb`. No light is baked: the spire
  and the star light them live.

### deck-layout-dl1 (2026-10-20)

#### Changed

- **The bridge faces the bow** (R2-DECK-LAYOUT DL1, D-95; a blockout). The navigation arc stands at
  the bow rail on the centreline with the captain's chair behind it, and the Voyage and Crew
  consoles flank it; at every station the captain stands stern of the console facing the way the
  ship is going, and each console's close-up looks out at the sky ahead. A new game starts behind
  the helm (the manifest's `spawn_captain`), and the first step forward walks to the helm, not into
  the lift. Operator points are authored in Blender (`stations.<id>.use_m`). The props keep their
  grounded-v2 look; the hand-finished art follows Mark's playtest.

#### Added

- `make deck-layout-eval` (the bow evaluator: every bridge walk sample through the Bow and Astern
  views, §D4 thresholds), `make deck-layout-eval-test` and `make deck-assets-check` in `make test`;
  `make ship-baseline` fetches the pinned pre-move deck for the evaluator's positive control; the
  bridge's fading props are data (`views.json` `levels.bridge.occluders`).

### camera-forward (2026-10-19)

#### Changed

- **Travel runs along the deck, toward the bow** (D-92, amends D-14). The ship's direction of travel
  is now a horizontal axis in the deck plane, so the journey and the deck share one frame. One named
  map per frame: `ShipCamera.ship_vector` / `gltf_from_ship` (kinematic) and
  `ShipFrame.gltf_from_structure` (Blender structure); `make basis-gate` fails on any inline copy.
  No physics formula, sim, protocol or replay changed; the GPU goldens re-posed one for one (393).
- **A fixed bow camera** (R2-CAMERA-FORWARD F1, D-91, D-93). On the bridge the camera looks over the
  captain toward the bow and slides with the captain without ever turning: W is always up the
  screen. 7 Bow (default), 9 Astern, R back to Bow; 8 reserved. The spire and the lift fade while
  they hide the captain or the journey. Every cue (departure, braking, a stop, Sgr A*) returns to
  Bow; a guided stop now turns the ship so the body sits 30° off the bow, inside the frame, and at
  Sgr A* the hole sits on the bow at every stop. Zoom levels are developer presets on the bridge;
  the Commons keeps its views for now. The old sky views (Sky ahead, to the side, astern) are gone
  as player views; they remain only as tool and golden poses.
- Braking notice: "Braking. The bow is still the way we are travelling."
- Developer tooling: `make camera-views-capture` renders Bow, Astern, the Commons and the lift at
  rest, 0.99c, a guided stop and Sgr A* (plus a forced-fade frame and a real voyage at 0.9/0.99/
  0.999c), gated on the pole, the stop body or the hole being in frame. `make camera-forward-targets`
  records the live stop and Sgr A* targets the camera test checks. A fresh clone now gets
  `data/raw/.gdignore` from `make sky-assets`, and `make publish-dev` fails with the fix
  (`make ai-core-assets`) instead of publishing a build without the core layer.

### context-controls (2026-10-16)

#### Changed

- Display audit controls now prove that absent frame paths are rejected, catalogue distance
  must appear in binding parts even when carried in context, and Crew working counts match
  the frame. The distance-presence rule reports `context-presence`, distinct from
  `context-source`, and wrong-reason failures name the control fixture.

## v0.4.0-dev.34-home-tiers (2026-10-19)

### home-tiers (2026-10-19)

#### Changed: the crossing review's Home page has sixteen home-time tiers with variant pictures (R2-HOME-TIERS, protocol 2.12)

Mark, attended 2026-10-19: "lets get more of them so we can split the tiers up more" and "we can have even more actually"; "we can just have random choices from the varients we have. good replayability" (ledger D-86). Design: `design_docs/implemented/r2/home-tiers.md`.

- **Sixteen tiers** of Earth years since departure (edges 1, 3, 10, 20, 35, 55, 90, 130, 250, 500, 1,000, 3,000, 10,000, 50,000 and 250,000) in `sim/home_tiers.ail`, with Mark's approved Home-page lines, digit-free narration words (launch ... aeons) and the Archive's crossing lines. Every line is true across its whole range. The old "Longer than recorded history" now starts at 10,000 years, where it holds. A century and a half no longer shows the drowned town.
- **Variant pools.** Each tier has one or two pictures (28 in all). The voyage's seed picks one per tier with a pure, salted hash that draws nothing from the world's RNG, so a tier shows the same picture every time it comes up in that voyage. The counts are data (`sim/data/home_variants.ail`). To add a picture, add a file and its `SOURCES` row and raise the count.
- **Protocol 2.12** (`homeTiersMinor`): `cruise.digest.time` gains `tier_count` (16) and `variant`. `tier`, `tier_line`, `home.tier` and the narration use the sixteen tiers. 2.10 and 2.11 streams are byte-identical: their stream sha256 is pinned in `sim/protocol_interlude_test.ail`. The game's sessions ask for 2.12.
- **The host** loads `data/interlude/home/tier<n>_v<k>.webp`. A missing variant falls back to v0, and a missing tier to words only. A frame below 2.12 shows v0 of the old tier's place (`PICTURE_OF_SEVEN`, checked against the real sim's table).
- **Pictures:** the seven shipped pictures become v0 of tiers 0, 2, 4, 6, 8, 10 and 13, with their bytes unchanged. Three earlier candidates and eighteen new ones from 2026-10-19 were added, all checked at 1:1 for text-like marks. The masters are in the public bucket; `SOURCES` and `generation_notes.md` record every one. The pictures ship at about 16 MB.
- **Website:** the concept-art page shows every picture of tiers 0–12 (23), titled by time range, with no captions. The tiers from 10,000 years on are story and stay off the site, so the old tier-6 picture came down.
- **Checks:** `make home-tiers-vm` (strict VM == interpreter on the ladder and the variants), `make home-art-check` (pool == counts == `SOURCES`) and `make home-site-check` (site == tiers 0–12, no later tier). All three are in `make test`. The crossing-review fixtures were re-recorded at 2.12 and now include the whole guided tour, whose last crossing is about 120 Earth years: tier 7.

### m46pr3-hidden-map-redraw (2026-10-17)

#### Fixed

- The bridge no longer redraws the hidden star map's gas layer every tick
  (M4.6pR3). The ISM layer skips drawing into a hidden window and redraws when
  the window is shown.

### m4-6rr3-ship-renders-bench (2026-10-16)

#### Added

- `make capture-m4` records the 3D ship's first journey from the captain's eye:
  seven real sim states, deck and forward views, a contact sheet, and world/PNG
  manifests, with blank, duplicate, state and stale-output checks.
- `make capture-m4-publish` verifies and uploads the 18-file S1 reference set.
- `make bench SCENE=bridge` measures live transit at 2560×1440 with vsync off
  and the medium star tier. It reports a docked control, nearest-rank frame
  percentiles and JSON evidence, rejecting invalid runs and p99 ≥16.7 ms.
  The default starfield benchmark remains unchanged; S1 review and the live
  transit performance gate still require measurements on the GPU host.

## v0.4.0-dev.33-fixed-camera (2026-10-19)

### crew-console-v2 (2026-10-17)

#### Added

- **Protocol 2.11 (R2-CREW-CONSOLE-V2 V1): the sim names whose move it is.** Each crew member
  carries `work_state` (held, relief_asked, concern, declined, deferred, asked, agreed, offered,
  resting, working, done, stopped, free) and working work its start `terms`. `crew_start` may
  carry `"as": "orders"` (one start under the other captaincy, all or nothing, journalled as three
  crew_core lines) and `crew_offer` `"start": "on_accept" | "now"`. Below 2.11 these are
  `bad_intent` and every stream is byte-identical. The game asks for 2.11.
- **The Crew console as an internal videocom (V2, V3).** A roster board (whose move first, one
  chip of colour, icon and word per member, one quick action, the ship default and auto-run in a
  header strip, the free resources as gauges, a legend) and a two-panel call: a 240-logical
  portrait at the sim's emotion with their words, and beside it the work and the next legal
  actions. Ask or Order is chosen inline on each offer; Start is disabled with its reason while a
  concern, a decline or a deferral is open; Insist is the fourth answer; "Make it an order" orders
  over an answer. Every crew decision (the offer included) arms on the first press. Once an
  intent about someone is on its way, all their actions wait ("Sent, waiting for the ship").
  A concern or a hold opens its call when nothing else is open or armed; otherwise the row pulses.
- The palette (Okabe-Ito based) is checked for contrast and for colour-blind separation
  (Machado 2009 deutan, protan and tritan; CIEDE2000) in `make crew-console-test`.
- `make display-audit-crew` (in `ship-demo-ci`): the Crew console's playthrough, every Label a
  display binding, with the `crew_unbound` negative control.

#### Changed

- Captures: `make crew-console-capture` writes ten states at 1280x720 and 2560x1440.
- **Crew console (V4–V8, the visual pass, 2026-10-17).** A reply to a concern is reconsidered at once
  and the work starts when they agree. Keyboard and pad: a focus ring, Enter/A to arm and send,
  1–4 for answers, [ ] or LB/RB to switch calls, Esc/B one level back. Less text: terms as day pips
  and resource icons, rule lines in one line behind "?", faces for who is waiting, icon bars.
- **crew_core 0.6.0 (stand-downs).** A crew member can ask to stand down at a duty check-in; under
  hands-on auto-run the console asks you (Let them rest / Ask them to carry on), and crew time waits
  for your answer. The crossing digest counts stand-downs (protocol 2.11).
- **Names fit faces (ledger D-80).** Generated crew names now match each portrait's presentation and
  naming tradition (from protocol 2.11).

#### Fixed (after the evaluation)

- A stand-down call no longer offers Resume first: the two answers lead and Resume waits until
  the stand-down is answered (resuming first let it lapse, which crew_core counts as refusing
  their rest). The console's buttons follow the model's enabled flags.
- The work and bar icons have a "?" key the keyboard and pad reach.
- The scripted crossing (make strict, crew-parity) now brings the named crew aboard (AILANG
  v0.54.14 runs the names table on the strict VM).

### constellation-guides (2026-10-17)

#### Added

- Hold I to see faint Earth constellation guides for Orion, Cassiopeia, Crux and
  the Big Dipper. Their endpoints follow the rendered stars as velocity and
  observer position change. Missing or invisible stars leave partial figures;
  guides are unavailable during gravitational lensing. Existing star/body
  inspection and cards remain available.

### camera-fixed-views (2026-10-17)

#### Changed: the player camera is third person with three fixed zoom levels and authored sky views (R2-CAMERA: C1, C2, C3, C4)

Mark's dev.31 ruling: no free zoom for players; fixed zoom levels; third person. Design: `design_docs/implemented/r2/camera-fixed-views.md` (approved 2026-10-16).

- **One camera director** (`demos/camera_director.gd`, views as data in `data/camera/views.json`). It owns every pose of the player camera; `ShipCamera` stays the render boundary, so the sky is still rendered through the same pose as the geometry.
- **Three zoom levels:** Z1 Close (4.5 m, -25 deg), Z2 Deck (12 m, -35 deg; the default, the captain about 64 px tall at 720p, the art brief's reading scale) and Z3 Whole level (a place camera on the bridge's edge that tracks the captain by rotation). Keys 1 / 2 / 3 and = / -; one wheel notch, one trackpad scroll gesture (its inertial tail included) or one pinch is one level, so a MacBook swipe no longer drifts the camera. Zoom in is closer: wheel up, scroll up and pinch open come closer. RB / LB on a controller. The FOV stays at 78 deg.
- **Authored angles:** the boom yaw comes from 8 sectors around the spire (10 deg hysteresis) and 2 rings (the stations ring inside 12 m, the rail ring outside, 1 m hysteresis). Every eye stays inside the 95 m envelope, and a sweep of every walkable point checks the line to the captain's head (`make camera-test`).
- **No mouse look for players.** The pointer is never captured; clicks aim where the pointer is. WASD is screen-relative, and a held key keeps its world direction when the view changes. The left stick walks; A uses and B steps back.
- **Console focus** eases to the framed screen through the director, and stepping back returns to the remembered level and sector, not a stored eye.
- **Reduced camera motion** (title Settings and Tab, `[display] camera_motion`): cuts with a 0.15 s fade instead of eases, and a rigid follow. In full motion the camera turns at most 90 deg/s, never rolls and never overshoots.
- **Developer free camera:** F8 or `--free-camera` (command-line launches only) restores the old mouse look, scroll dolly and presets 1-4, labelled FREE CAMERA. Tools, captures and goldens keep `set_preset`, `look_direction` and `reference_view`, which take the camera through the director's override.
- The waiting line under the crossing review and the arrival card no longer mentions mouse look.
- **Sky views (7 / 8 / 9, D-pad):** Sky forward (a low eye beside the captain, pitch +58 deg, the forward pole and the starbow in frame, the captain an upright figure from behind at the bottom), Sky to the side (walks to the rail facing where a guided stop puts the body) and Sky astern (walks to the rail and looks down over it). Any level key, move key or R ends one.
- **Under way the forward sky is the default.** Committing a course, the guided voyage's departure turn, braking and Sgr A* cue Sky forward; a guided stop cues Sky side once its turn completes; under way R returns to Sky forward. No cue starts with a panel open, at a console or in the lift; with reduced motion a cue is a HUD prompt ("Sky ahead · 7"). The crossing review holds Sky forward behind it. Without this, a 0.99c cruise showed the deck against a black sky.
- **Sgr A*: the hole view.** At Sgr A* the cue (on arrival and at every stop) and R select a view aimed at the hole's direction from the sim's GR state, the hole 18 deg above the frame centre and the captain below, so the shadow, the photon ring and the lensed sky are framed at the 10, 5 and 3 r_s hovers and the 3 r_s orbit (as the M3.6 visit's own look toward the hole did, now third person). Key 7 at Sgr A* opens it; reduced motion keeps the prompt ("The hole · 7").
- **The spawn:** the lift's guards no longer hide the captain (per-cell angles at the lift landing, checked with a whole-figure sweep).
- **The lower deck (Commons):** views authored per cell; points under the arcades' lintels that no camera sees are held to a measured ceiling (Z1 2, Z2 2, Z3 39 of 1,881 samples).
- **Physics:** no formula changes. `tests/test_physics.gd`: RS-1 and RS-2 through every view's eye land on the captain eye's pixel to 0.05 px, and a pixel's sky ray matches to 1e-9 rad. New goldens: G-CAM-1 (the forward pole through Sky forward, 3 phases, 2 standing points: 6), G-CAM-2 (the wall glow from the Z1, Z2, Z3 and Sky forward eyes at 0.99c and the cap, against `ForwardGlow` and a closed-form wall hit: 8) and G-CAM-3 (one tonemap through Z2 and Sky forward: 2). `make golden` pins 393 ok lines (G-CAM-1 also through the Sgr A* hole view's pose; G-CAM-2 aims where the eye changes the glow by 13-34 %, at 0.99c too; G-CAM-1 also checks the pole against the 78 deg constant); this also fixes main's stale pin (main ran 374 ok lines against 373). `make camera-views-capture` renders every view at rest, 0.99c, a guided stop and Sgr A* at 1280x720 and 2560x1440 with contact sheets, and the default cruise view of a real voyage at 0.9, 0.99 and 0.999c.

### ailang-0.54.14 (2026-10-17)

#### AILANG v0.54.14

- **Upgrade:** CI, the bundled runtime and the CLAUDE.md pin move to AILANG v0.54.14 (via v0.54.13). The lockfiles are unchanged (crew_core 0.5.0).
- **Workarounds removed (outputs byte-identical):**
  - ailang#1736 / #1865: every strict-VM list-literal split is gone. `applyOverride` is one if-chain. In `sim/data/ism.ail` the efficacy LUT, each cloud's planes and the members are single literals. `data/ism/ism.json` and the `ism-determinism` stream are unchanged.
  - ailang#1576: the stub voice builds a segment as a plain list of periods again, and the lens-table builders use plain recursion. The voice stub bytes, `aiWireVm`, `lens-lut-check` and full lens rows match.
  - ailang#1737: the `protocol_ism_test` checks are inline test bodies again.
  - v0.52.0 fixes: restored the `\tick` binders (#1467), a variable arm (#1473), nested cons patterns (#1505, #1517) and constructor-at-cons-head patterns (#1503). Dropped the stale #1460, #1461, #1465, #1516 and #1419 notes. The replay interpreter no longer passes `--max-recursion-depth` (#1486).
- **Crew names on the strict VM:** the crew-names table now runs under `--strict-bytecode`. `make strict` checks it with `namesVm`: the table and five generated names, VM == interpreter. The scripted crossing still uses role ids. The crew console sprint (D-80) switches it to names and owns the `crossing_hold` re-recording.
- **Kept on purpose:** `ailang check --package` stays beside `ailang test --package`. The test runner now catches type errors in untested modules (ailang#1845), but only `check` enforces STRICT_FALLBACK_001.

## v0.4.0-dev.32-crossing-review (2026-10-17)

### crossing-review (2026-10-17)

#### Added

- **The crossing review (R2-INTERLUDE, protocol 2.10).**
  - The cruise is crossed in chunks the sim publishes (`cruise {next_stop_years, stop_kind}`).
  - A crew hold stops the crossing on its check-in day.
  - The crossing ends in a review the player reads at their own pace: the crossing, home (a picture per home tier), aboard, moments with faces, who changed, the medium, and who is waiting.
  - Every number comes from the pure sim's cruise digest. Streams below 2.10 are unchanged.
- **The Archive narrates.**
  - Authored, in-world framing lines appear on the crossing and aboard pages.
  - With live AI and a key, the Archive tells the crossing once in its own words. The telling is recorded as sim input and voiced once.

#### Changed

- The 6-second interlude card is gone; no timer dismisses the review.
- After arriving, the view can be turned without first dismissing the card. While the review is open, right-drag or Alt/Option+move looks around, and one centred line says what to press.
- The HUD's Braking notice waits until the player brakes.

#### Fixed

- News from home no longer says "Only 0.00 years have passed there since you left". `{elapsed_years}` is when the message left home, and a message sent right after departure says "within days of your departure".

### crew-offer-while-paused (2026-10-16)

#### Crew offers get an answer while the guided tour is paused (dev.31 playtest)

- **Bug:** with the guided voyage paused (P), turning, or waiting on a stop choice, an offer made on the Crew console got no answer, and "Offer this work" stayed live, so every press queued another offer. The Crew page's intents ride the sim's next tick (`SimBridge.queue`), and `SolarDeparture.step` sent no tick in those states.
- **Fix, guided tour:** in those states the tour now sends a zero-dtau tick whenever intents are queued, so the crew answer and ship time does not move. With nothing queued it sends nothing, as before, so idle ticks and replays are unchanged. A refused crew intent is now the Crew page's to word; it no longer fails the tour. The other hosts already tick while paused (`GalaxyMap.tick` sends dtau 0), and the Sgr A* visit has no crew.
- **Fix, Crew page:** after an offer is sent, the member's card says "Offer sent. Waiting for their answer." and the Offer button is disabled (not hidden), with that reason, until the sim's crew shows the work or the tick that carried it answers. Refusals are attributed to the member their intent was about (`SimBridge.queued_refused`), and only the tick that carried the page's intents settles them, not a pipelined heartbeat. `altered_duplicate` and the host's "request capacity/id/clock" refusal now have plain words.
- **Task ids:** they carry the crew's turn and revision and a serial shared by every page, so a page rebuilt in the same turn never reuses one.
- **Tests:** `crew-hold-test` drives the paused, turning and stop-choice cases against the real sim. `crew-console-test` covers id uniqueness across rebuilt pages, the sim's duplicate refusals and their words, and the pending state.

## v0.4.0-dev.31-crew-core-0.5 (2026-10-16)

### m4-6gr3-ship-goldens (2026-10-16)

#### Added

- Ten GPU golden cases cover the 3D ship's single tonemap, captain-eye forward pole
  in boost, cruise and brake, and glow profiles, absolute simulation poles and zero at rest.
  The golden target requires the simulation probe and exact case counts.

### crew-core-0.5.0 (2026-10-16)

#### crew_core 0.5.0: resource units come from the package; long crew runs stay fast

- **Pin:** crew_core 0.5.0 (ailang-packages #146; it passed independent evaluation at 90/100 and then 92/100).
- **Resource units:** the rules (allocate, lint, used) now live in `crew_core/units`. The game keeps only its eight-row bubble table and the ship's spare capacity in `sim/crew_resources.ail`.
- **Archiving fix:** memory compaction no longer waits for the bank to fill, so evidence stops growing. A free-nav leg to Barnard's Star now arrives in 1,201 ticks: the longest takes 117 ms and none hits `step_timeout`.
- **Performance:** on AILANG v0.54.11, where ailang#1827 is fixed:
  - a busy crew's ten-year skip takes 11.2 s on the Studio, down from about 40 s;
  - the skip as played takes 0.46 s.

  `crew-perf`'s ceiling for the busy skip drops from 150 s to 30 s.

### ailang-0.54.11 (2026-10-16)

#### AILANG v0.54.11

- **Upgrade:** CI and the bundled runtime move to AILANG v0.54.11.
  - std/map now runs on the strict VM.
  - `ailang lock` no longer restamps unchanged lockfiles.
  - The VM's slow list walk is fixed (ailang#1827).
- **Input handling:** the sim and the AI service read input with `readLineOpt`. End of input now ends a session cleanly, and a blank line is skipped. This replaces the "16 empty reads" guard.

### context-crosscheck (2026-10-15)

#### Changed

- Display audit cross-checks each recorded binding context (row 7i(g)): a shared path that
  disagrees with the frame view fails `context-drift`; a context-only `client.*` path must match
  its producer (`context-source`: target id, catalogue distance with required presence, star
  count and radius, zoom rate, hold time, Archive and Crew counts); anything else fails
  `context-unknown`. The only allowlisted path is `client.map.target_name`. Six new control
  fixtures, three edited.

#### Fixed

- The galaxy map's clock line could stay one or two ticks behind the frame after a pipelined
  heartbeat or a console send advanced the world without a refresh (the AI-stub playthrough
  caught it). `GalaxyMap._process` now refreshes when its tick differs from the world's.

### crew-core-0.4.1 (2026-10-14)

#### crew_core 0.4.1 in the game: auto-run answers concerns, the captain can too

- **Pin:** crew_core 0.4.1 (ailang-packages #143). It fixes the auto-captain deadlock that kept a crew with a concern from being offered work.
- **Auto-run presets:**
  - critical-only answers a concern itself by asking the worker's advice, shown as a crew line ("Auto-run answered their concern by asking their advice.");
  - hands-on hands every concern to the captain as a hold.
- **Answering a concern yourself:** open concerns that can still be answered show on the member's card, with one confirmed button per approach (make the job clearer, ask their advice, plan it in stages, explain why it matters, insist). The button sends `crew_reply` (captain_reply) at the crew's tick and revision.
- **Holds:** the new `stuck` hold has its own words.
- **Gate:**
  - the game's crew runs conversation v3;
  - a year of critical-only auto-run logs no error acts, at daily and monthly check-ins, under both captains.
- **Performance, measured honestly:** a busy crew's ten-year skip costs about 40 s. The old 0.6–1 s came from the deadlock. `crew-perf` keeps the 2 s budget for the critical-only skip as played, and sets a documented 60 s ceiling for the rule-free worst case. The cause is ailang#1827 plus encoding work; options are with Mark.

## v0.4.0-dev.30-crew-replies (2026-10-15)

### medic-emotions (2026-10-14)

#### The medic's full emotion set

- **Art:** `assets/characters/medic/` holds all eight D-7 emotions at stage 0, 1254 px: neutral, happy, sad, angry, fearful, curious, loving and grieving.
  - Codex (`gpt-6.1-sol`) made each one as an edit of the accepted neutral, so she stays the same person.
  - The folder has a manifest (with the D-80 name region and gender), generation notes with full prompts, and a review contact sheet.
- **In game:** 256 px copies sit with the trial portraits, and the Crew page's faces follow more replies:
  - declining shows anger and a concern shows fear;
  - asking to step back, or stress at the strained line, shows sadness;
  - accepting shows happiness.

  A role without an emotion falls back along a list, ending at neutral.

## v0.4.0-dev.29-crew-console (2026-10-14)

### Scene session audits (M4.5bR3, D-66/D-68), 2026-10-14

- The scene run records received states alongside inputs and walk/use/read events. Timing charges measured walking at 3.5 m/s, console use, commit holds and reading; the default round trip measures 226.502 s, with 60.15 s and 61.35 s legs. Unlock auditing handles simultaneous commit/boost hints and preserves the legacy scope controls.
- `make playthrough AI=none|stub|digits` exercises template, generated and numeral-refused news through the local stub. The Archive requests news and receives accepted-text events through a three-line console seam.
- `make display-audit` streams frame states, binding contracts and codex bodies; valid, unbound-numeral, stale-format and missing-field controls check the auditor. Sampling every fourth frame plus phase edges reduces the default sample file to 32.46 MB (716 samples).
- AC4 is OPEN with the known findings ratcheted in `tests/fixtures/display_audit/known_findings.json`: existing unbound numeric GalaxyMap/Archive labels and 42 transit samples where the expanded Medium boundary and Braking notice cards fold Transit. Follow-up row **M4.5bR3-follow-up** owns these UI fixes. Scene audits in `ship-demo-ci` accept only the recorded findings, reject new findings and stale entries, and keep binding, lore, AI and frame-state failures strict. Full scene replay is excluded from CI.
- `make playthrough-ai-modes` runs separate stub/digits scene and display audits and requires both AI results to pass; these optional AI modes stay outside `make test`. Ratchet controls reject a new numeral, a never-observed entry and missing transit ISM without the recorded folding cards.

### Scene playthrough bot (M4.5aR3, D-66/D-68), 2026-10-13

- `make playthrough` follows the title screen's New game through walked navigation and Archive visits: Alpha Centauri A, news from home, Return to Sol and the Voyage log. A pinned seed and fake clock record the real sim session, walk/use/read events and display samples under `.godot/tmp/playthrough/`; boost, cruise and brake check the CPU forward pole within 0.75 px.
- The adversarial script sends re-plan, cancel and commit attempts against a committed journey through the navigation console; the sim refuses them without advancing the journey and the HUD shows why. Both scripts and three driver failure controls run in `make test`.

### sim-pipeline (2026-10-14)

#### Performance: the sim computes while the game renders

- **The cause:** the main thread blocked on every sim tick, about 20 ms per heartbeat at 20 Hz on a Mac Studio, and more on a laptop.
- **What changes:** the live game now pipelines intent-free heartbeat ticks. `SimBridge.send(..., pipelined_ok)` writes the tick and returns. The sim computes while the frame renders, and `drain()` takes the reply before the next decision.
- **What doesn't change:**
  - ticks that carry intents (player, crew or AI) wait for their own reply as before;
  - tools, captures and tests stay synchronous.
- **Results:**
  - same inputs, same order: `make sim-pipeline-test` checks identical worlds, journals and crew against a synchronous run, including a guided-voyage arrival into its dwell;
  - main-thread cost per heartbeat drops from 19.3 to 0.7 ms;
  - headless frame check: 66 → 132 fps mean, p95 33 → 14 ms, sim share of frame time 44% → 2%.

### frame-check (2026-10-14)

#### B is a frame check again

- **What B does:** it measures 10 seconds of whatever the player is doing, in any launch, including from the title screen. It changes no game state.
- **What it records:**
  - frame-time percentiles, and stalls over 25 ms with when they happened;
  - **how much of each frame the main thread spent waiting on the sim** (`SimBridge.send_ms_total`);
  - draw calls, memory and node counts;
  - what the game was doing, and the hardware.
- **Where it goes:**
  - the report and a midpoint screenshot are saved under `user://frame_checks/`;
  - both are uploaded to `gs://stapledons-voyage-assets/benchmarks/play/<id>.json|.png` by the Cloud CLI on a worker thread;
  - the result shows in the ship's log card.
- **The scripted benchmark** moves to the developer panel button. `make frame-check-test` covers the check.

### crew-portraits-trial (2026-10-14)

#### Crew portraits (trial)

- **Every crew row on the Crew page has a face.** The faces are the website's concept portraits, one per role, downscaled to 256 px in `data/crew/portraits` (provenance in `SOURCES`) and exported with the build.
- **A call panel** shows the person the captain is facing, larger, with their latest words: whoever spoke last, or during a hold the person who needs the captain.
- **The face follows the reply.** Asking for relief, declining, raising a concern or high stress shows the strained face, and accepting shows the warm one. A missing emotion falls back to neutral, so only the medic changes expression for now (neutral, loving, grieving).
- **Provisional:** the counselor wears the diplomat concept face, and the generated names (D-74) aren't matched to the faces yet. Per-person variants come with the D-7 portrait sets.

### crew-console (2026-10-14)

#### The Crew console (crew-work W1)

- **The crew have their own console.** The first reserved bridge console is now the Crew console, with the full Crew page. The Voyage console keeps a one-line summary and, during a hold, "Needs you at the Crew console".
- **Work cards say what's on offer:**
  - the job's name and purpose, and how many days it takes;
  - what it needs from the ship ("one archive compute slot, free mass (used up)");
  - what it costs the person;
  - its state: waiting for their answer, their reply, "day two of three", or last finished.
- **Refusals in words, on the member.** For example: "Couldn't start: not enough archive compute slots free. Andrei Shevchenko and Santiago Navarro are using them." The sim normalises crew_core errors to `blocked:<code>:<detail>`.
- **Resources:** the ship's resources show as free of total, in words.
- **Relief:** relief requests sit on the asker's card.
- **Crew view:** gains `work.started`, `work.due` and `done` (additive to protocol 2.9).
- **Design:** `design_docs/planned/r2/crew-work.md` (W2–W5 await Mark's OQ1–OQ4).

## v0.4.0-dev.28-crew (2026-10-13)

### r2-crew (2026-10-14)

#### Added

- **The crew aboard** (sprint R2-CREW, PR #224; design `design_docs/implemented/r2/crew-integration.md`; evaluation round 2 PASS 88/100).
  - **The crew engine.** `sunholo/crew_core` 0.3.0 (a registry pin) runs inside the pure sim, with byte parity to the crew lab (`make crew-parity`).
  - **Who is aboard.** New games carry a consent crew of five, with names generated from an international list (D-74).
  - **The ship reaches the crew.** Physics moments become crew events: GR approach heat, signal from news bursts and arrivals, and the drive mass bill as a readout. A news burst that carries a death is a `loss`.
  - **Crew words.** Each answer opens a `crew_reply` AI request; the words never change the decision. Engine internals in a reply are refused (`ai_internal`).
  - **Crew page.** The Voyage console's Crew page shows names, roles, stress, fatigue and trust. It offers work, starts work, grants or denies relief, and switches consent and orders, each decision confirmed.
  - **Auto-run.** On long legs the crew run under standing orders, checking in monthly far from stars and daily near them (D-76). Critical moments stop the voyage as crew holds.
- Protocol **2.9**: `new_game` takes `crew`; nine crew intents; a `crew` state section; a `crew_hold` event.

#### Changed

- **AILANG v0.54.8** (#226) fixes ailang#1812, a cold compile of crew_core that took ~20 GB.
- The live game, the loading jump's prefetch and the map route use protocol 2.9.

### l2-m46-followups (2026-10-13)

#### Changed

- **One precision lint** (sprint R1-L2-M46-FOLLOWUPS; charter L2, queue row 7d). `make lint-precision` now covers the `b` name as well as `beta` (so the γ form is caught too), `*.gdshaderinc`, and `physics/planets.gd` through `LINT_OMB_ALSO`, which fails loudly if the file is untracked. `lint-precision-m5` is deleted, and `m5-test` depends on `lint-precision`. The controls grew to 6 planted lines and 3 clean lines beyond the old 4 and 0; the allowlist is unchanged at 3 rows.
- **D-52 wording** in the M4.5s changelog and inventory now points at the D-66 re-plan (M4.5aR3, M4.5bR3) instead of an open D-52. The meaning is unchanged: the UI events are still fixtures, and M4.5's `passes` stays null.
- **`codexUnlocks` `holds` clause** is kept, with a comment saying what it guards. A pure test (`checkHintless`) now fails when the clause is deleted: an unlock with no inferable trigger is rejected even when its expected row has no hint.

#### Fixed

- `main.gd` took the `beta` branch's γ as a hand-computed `1.0 / sqrt(1.0 - b * b)`. It now calls `Relativity.gamma_of(b)`, the package mirror, which is the same expression.
- `tools/glow_eps_sheet.gd` computed a fallback `1.0 - b` for `one_minus_beta`. It now reads `s["one_minus_beta"]` strictly, like its sibling fields `beta` and `gamma`.

#### Closed by evidence (no code)

- The M4.6 follow-up (a), the demo hand-computing `1.0 - beta` when the sim omits it, is closed: `545887f` (R1-SHIP-UI) makes `speed_text` return the β-only string and compute nothing.
- The M4.6 follow-up (b), `ForwardGlow.temperature` checked only for finiteness, is closed: `test_glow_mirror` checks it against the package `glowTemperatureAt` to 1e-12, and the `sqrt(sqrt(c))` → `sqrt(c)` mutant moves `interior` from 142 passed to 132 passed, 10 failures. The drill is reproducible with `godot --headless --path . --script tests/test_interior.gd`.
- The M4.5s follow-up (d), the `ai-godot` "hang portrait" 2 ms poll flake, is closed by PR #165 (merged 2026-10-08).

## v0.4.0-dev.26-archive-voice (2026-10-12)

### Manual journeys and seven guided highlights (D-65), 2026-10-11

- Interactive Galaxy map starts in the same stationary free-navigation session as Board the ship; historical capture/movie Sol sessions remain unchanged. Variable map details scroll, keeping zoom and journey review reachable. Enter reviews, Space retains the existing hold/press-twice confirmation, and Esc backs out.
- The guided route keeps Earth → Sun → Jupiter → Callisto → Saturn → Alpha Centauri A → TRAPPIST-1 → Aldebaran. The three distant arrivals use existing D-54 finite-star stops directly, removing redundant outer stops and inward hops while preserving real three-dimensional distances, speeds, safety and both clocks. Legacy rule-zero ten-leg replays remain frozen. TRAPPIST no longer uses the specially placed beside-e/HZ stop.
- Navigation exposes Sgr A* as a separate GR demo, including after the guided trip finishes; committed journeys disable that entry. The stellar stop attitude follows the actual held body, including catalogue-identified stars.

### Bubble surfaces, moon detail and the gas chart (D-64), 2026-10-11

- Dust afterglow uses short, incidence-oriented, curved surface marks on the spherical wall. Their area remains π r_s²; package event rates, energy, temperature and decay are unchanged. The shape is a labelled G-AG presentation approximation, with the original circles retained for comparison.
- Callisto and nine other moons gain their own pinned USGS/NASA mosaics. Bundle, albedo and exported-app checks now cover all nineteen declared textured bodies. Source monochrome/enhanced colours and missing coverage are disclosed; Titan's radar/infrared surface is not presented as visible imagery.
- The D layer adds translucent false-colour density shading, a LIC silhouette and separated cloud labels. Source outlines and approximate depths remain explicit; construction guides are optional. These are instrument surfaces, not naked-eye nebular fog.

### Free-navigation and mouse controls (D-63), 2026-10-10

- Mouse motion looks around by default. Tab, inspection cards and console panels release the pointer for their buttons; stepping back returns to looking, and leaving the window releases capture.
- Board the ship starts at rest near Earth. The in-system list keeps a stable Sun/planet/moon order, and refused plans explain the current journey or clearance constraint. P and the Pause/Resume buttons freeze time without changing the ship’s course.
- Idle free navigation now advances at one real second per second, so ephemerides do not race away after arrival. Earth remains visible at its inertial standoff; this is not a gravity-bound orbit.
- The map exposes Interstellar medium, Local ISM and optional Depth guides. Cloud boundaries show by themselves; radial construction guides are off by default and the legend labels the approximate depths.

### Local clouds, dust impacts and weather along the route (D-60–D-62), 2026-10-10

- New games use `lism-1`: the Local Interstellar Cloud, fourteen published local-cloud outlines and the Local Bubble's hot gas drive the route's column drag, wall glow and drive-hold limit. The chart lists every medium in order, including re-entry; a route above the limit is refused with the supported speed shown. Existing uniform scenarios and frozen protocol 2.7 replays keep their previous bytes; the new fields use protocol 2.8.
- Individual grains flash on the wall with a seeded, capped display sample and a labelled afterglow approximation. Cumulative grain and bright-impact totals survive compressed flight and arrival; every changing-speed piece is integrated, including short high-acceleration trips. At rest the display emits no impacts. The numerical threshold solver inverts the same adopted efficacy table directly, checked against the original solver and package oracle.
- The ship HUD names the medium, announces every crossed boundary, shows local rates per ship second and cumulative counts, and distinguishes the largest displayed grain from the unobserved population. The Archive adds “Weather Between the Stars” and corrects the old single-density description. Mark accepted the rendered afterglow/defaults/Archive choices at P2 (D-62).
- The published angular outlines recover 56 of 59 nearby sight lines; their shell depths and the numerical LIC surface remain explicit model approximations. Dense-cloud tomography and the Local Leo Cold Cloud are deferred while independent scientific comparisons fail.
- New native videos show a stable Sgr A* orbit, the guided Saturn arrival and six cloud intervals toward Aldebaran. Gallery/news captions disclose time compression, omitted journey stretches and the black-hole demo's Sol-sky background.

### Inferred radii, synchronous orbits (D-58), 2026-10-09

- Every catalogue star now shows its size in free navigation: a star with no measured radius gets one inferred from its catalogue V, distance and Teff (sunholo/relativity 0.11.0: Pecaut & Mamajek bolometric correction, M_bol,sun 4.74, Stefan-Boltzmann) and becomes a finite star coloured by its Teff, stopping where it looks 2 atan(tan 5° √(R/R☉)) across: Barnard's Star 0.19 R☉, 4.4° at 0.023 AU; Proxima 0.16 R☉, 4.0°; 61 Cygni A 0.66 R☉, 8.1°; Vega 2.6 R☉, 16°. Its I card says the radius is inferred, with the luminosity and the inputs.
- Planet, moon and Sun cards show the synchronous orbit (sunholo/celestial 0.3.0, Kepler's third law): Earth 35,786 km above the surface, Mars 17,031 km, Jupiter 88,517 km; "none" for tidally locked moons and for Mercury and Venus, which turn too slowly (the orbit would lie beyond their Hill spheres).
- The black-hole ISCO comes from the package (`isco()`). Protocol 2.7; the hello reports relativity 0.11.0.

### export-completeness (2026-10-12)

#### Added

- **Export completeness check** (sprint R1-L6-EXPORT-COMPLETENESS; charter L6, clause 5 hygiene). `make export-filter-audit` runs in `make test`: it reads every `res://` literal the shipped code uses and fails when `export_presets.cfg` would drop one. Dynamic prefixes and dev-only paths are declared in `tests/export_audit.gd` with a reason, and a stale row fails. Sixteen named mutants run on every `make test` to prove the audit catches a dropped lens table (the dev.23 failure), an empty scan and a missing extension.
- `make export-pack-check` (rig-only, no export templates): lists a real `--export-pack` zip and checks the measured pack forms, the witnesses and the excluded paths. `make export-pack-check-strict` is the `publish-dev` gate: an absent witness fails there instead of being skipped.

#### Fixed

- `spike/` no longer ships in the pack. Its `res://data/raw/hip_v7.tsv` read was dropped by the export anyway, and nothing in the game loads `res://spike/` (`export_presets.cfg` `exclude_filter`).

### archive-voice (2026-10-12)

#### Added

- **Ask the Archive** (R1-ARCHIVE-VOICE phase 1, D-67/D-68) at the Archive terminal: type a question, press Ask or Enter. With live AI on (switched on in the AI indicator, with a key), the ship's Archive answers as itself, an artificial mind aboard the bubble ship. It answers from its own entries and a live sensor feed (where the ship is, speed, both clocks, the medium outside, the journey, the news). With AI off, an in-world line answers instead.
- **The Archive's persona** (`data/ai/cast/archive.json`): temperament, manner and the bounds of its knowledge. **The Archive is sandboxed:** the model is told none of the lore's mechanics, and works out what it can from evidence. `make in-world-voice-check` fails if its cast, prompt or canon names one. Its prompt is its own boot record: no game, no player, the captain, no digits (instruments show every number).
- **Reply filter for every AI line:** a reply that steps outside the ship ("game", "player", "fiction", "language model", the model's maker, its training or prompt) falls back like a numeral does. **Theories pass** (Mark, 2026-10-13): every AI character is sandboxed and told none of the lore's mechanics. So a line wondering about loops, other universes or a simulated, chosen universe is the speaker's own inference, and the Archive may work the loop out for itself. `make in-world-voice-check` now checks every cast file and prompt golden for lore mechanics.
- **Frame-break questions** for the attended live check: `data/ai/archive_frame_break.json`.
- Typing at a terminal no longer triggers the I key or walking.

#### Fixed

- **The Archive terminal's layout:** the codex no longer covers the reading row, so Read news, Voyage log, Ask the Archive and Ask stay clickable. The codex, news, log and answer panels all fill the terminal below its two rows, laid out with the terminal.
- **A Codex button** returns from news, the log or an answer to the Archive's entries.
- **The Voyage log lists its entries:** the ship now feeds every sim step to the log (the sim's section carries only the entries since the previous step), so it no longer shows "3 entries" over an empty list. Rows read in words ("Archive entry opened · The Bubble", "Arrived · Sol"), never as sim ids.
- Website: news post "The Archive answers" and three gallery captures (Ask the Archive, the Voyage log, New game); `make ship-ui-capture` gains the `archive_question` and `voyage_log` frames.

### free-navigation-recovery (2026-10-10)

#### Fixed

- Free navigation starts at rest 50,000 km from Earth's centre using the existing Solar initializer. The live world appears immediately; the older diagnostic Sol scenario and frozen protocol recordings retain their behaviour.
- The **In this system** list retains stable buttons in Sun/planet order, with moons beside their parent. Refusals preserve the simulation's reason and explain the next action without committing an invalid plan.
- Live idle advances one ship second per real second. Earth remains resolved at its arrival standoff through the checked one-minute dwell. Stops are inertial standoffs rather than gravity-bound orbits.
- Menu prefetch uses the same protocol 2.8 as ship, guided-voyage and map consumers, restoring warm simulator reuse.

#### Changed

- Mouse movement looks around by default. **Tab**, inspection, console, chart, arrival and interlude panels release the pointer for interaction; focus loss and exit also release it. **P** and visible Pause/Resume controls hold simulation time while preserving the course.
- Local clouds are visible by default on the chart, with **Interstellar medium [D]** and **Local ISM** controls. The legend labels approximate shell depths; radial depth-construction guides are optional and off by default.
- The website gallery and news include native black-hole orbit, Saturn arrival and ISM-transition videos, with their presentation compression and cuts disclosed. Controls and roadmap reporting are updated alongside the captures.

### ship-ui-land (2026-10-09)

#### Changed

- **R1-SHIP-UI U6–U8 (landing PR).**
  - **Migration:** `tools/exposure_sky_recovery.gd` opens the helm before it plans. The free-navigation test and `tools/stops_capture.gd` already did so in PR 2.
  - **Helm readability:** the embedded map scales to fit the panel (minimum 0.62 of full size) and the panel's explanatory line moved into its title. Map text now reads at about 12 px at 1280×720.
  - **Dwell label:** names only named stars and resolved bodies; an unnamed catalogue row is the I card's job. It hides while the cruise interlude card shows and stays clear of the card column.
- **Renders:** `make ship-ui-capture` writes 24 frames to `renders/ship_ui/`, 12 states at 1280×720 and 2560×1440, plus `contact_sheet.png`. The states: strip at rest, the prompt at the navigation station, the helm, the chart, the Voyage console, the Archive terminal, transit in cruise, the cruise interlude, arrival, the guided voyage at a dwell, Sgr A* gravity, and the lower deck.
- **Docs:** the design-doc index row, and the M4.5 bot hook (`ShipConsoles.walk_to` and `use`) in `design_docs/planned/r1/m4.5s-inventory.md`.

### ship-ui-hud (2026-10-09)

#### Added

- **The 3D ship's HUD informs** (sprint R1-SHIP-UI, U0–U2; D-56, D-57 Q1 = A: this absorbs M4.3b's 3D-ship half). `ui/ship_hud.gd` (`ShipHud`) replaces the HUD text block and the button column of `demos/ship_geometry_demo.gd`:
  - **Status strip** (top centre, always shown in every scene state: docked, the live journey's phases, the guided voyage's dwell and interlude, Sgr A*, the lower deck): ship clock and home clock at the same size (D-12; "home (far-away)" at Sgr A*), speed while moving, the view tag (click toggles Auto / Realistic), then where / phase and the distance line (`distances_text`; `r = … r_s` at Sgr A*). Every value is a `DisplayBinding` on the sim's world (clocks in adaptive units via the new `dur_yr` format) or on a sim-derived line; captions are digit-free.
  - **Contextual cards** (right column; at most two expanded by priority, the rest one-line chips, never dropped; 0.4 s fade in, 0.6 s fade out; never over the centre third): transit (the M4.3a `JourneyHud` rows, compact; all rows in Tab; warp shown as the live pacing rate, no warp control), brake and final-approach notices (8 s), arrival (the M4.3a arrival rows; Enter, Esc or Dismiss, or the next commit), gravity at Sgr A* (`BlackHoleVisit.hud_lines`), the guided voyage (leg, stage, dwell left, PAUSED, with **Pause [P]**, **Skip dwell** and **Skip stage [K]**), the cruise interlude's chip (the D-41 card keeps its content and now sits left of the column), Archive unlocks (the codex's toast, moved into the stack, 10 s) and refusals (verbatim, 8 s). No card changes game state on a timer.
  - **Prompt line** (bottom centre; the lift and, on the lower deck, "decisions are made on the bridge") and the **Tab panel**: Walk to (lands with the consoles), display controls (view, brightness, sky only, the dwell-label toggle, the confirm mode, camera presets and looks), the full journey rows, the details block and the controls grouped as the design's §F.
- `ui/ship_controls.gd` (`ShipControls`): every control of the 3D ship as data, by kind (display, pacing, camera, move, dev, console).
- **Developer controls** (B benchmark, G guides, 5/6 sky snapshots, the audit buttons) only on command-line launches; a title-screen launch hides them.
- **Confirm mode** setting (D-57 Q6): title Settings "Confirm decisions: Hold (1.5 s) / Press twice" (`settings.cfg` `[controls] confirm_mode`), carried into the ship and toggled in Tab; the consoles use it (next PR).
- `SimBridge` record seam: with `record_sent`, every sent line is logged with its source (`player`, `tour`, `tick`); the guided voyage tags its own legs `tour`, the Sgr A* ring report `tick`. Record only: nothing sent changes.
- `make ship-ui-test` (in `ship-demo-ci`, so in `make test`): the strip in nine scene states (each value equals its field formatted, captions digit-free, `DisplayBinding.audit` clean, clocks the same size, speed only while moving and the sim's `one_minus_beta` present), each card's appear and leave trigger, priority and two expanded, no card over the centre third at 960×540, 1280×720, 2560×1440 and a UI-scaled 640×360, the control table against the key handler in both directions, and developer gating on menu and command-line launches.
- `make ship-ui-capture` (GPU window): `renders/ship_ui/*.png` at 1280×720 and 2560×1440 from the real sim in the Auto view, plus a contact sheet; fails on a missing or uniform frame.

#### Changed

- `speed_text` reads `ship.one_minus_beta` only; the `1.0 - beta` fallback and its `lint-precision` allowlist row are gone (charter follow-up 7d(a)). The beta digits are formatted from `ship.beta` itself.
- The committed-leg distance line no longer says "from Earth" twice when the leg left Earth.
- Tests that read the retired HUD label (`test_bh_hud`, `test_free_nav_stop`, `test_ship_demo_consolidation`) read the strip and cards (`ShipHud.all_text()`).

### ship-ui-consoles (2026-10-09)

#### Added

- **The bridge consoles decide** (sprint R1-SHIP-UI, U3–U5; D-56, D-57 Q2–Q6). `demos/ship_consoles.gd` (`ShipConsoles`) reads the stations from `ship.glb` node names: the **navigation station** (`console_navigation_0..2`), the **Voyage console** (`console_decision_0`), the **Archive terminal** (`archive_terminal`), and three reserved crew consoles (`console_decision_1..3`, dark and "offline", kept for M6).
  - Walk there (WASD), click a console to walk to it, or use Tab's keyboard **Walk to** list. All three move at 3.5 m/s along `WalkArea.path`, and WASD takes over. The walked paths from the bridge spawn are 15–20 m.
  - The prompt names what **E** will use: the nearest interactable in reach (2.5 m) and facing (60°), with the lift as one of them. On the lower deck it says decisions need the bridge.
  - **E** or a click uses a console. The camera dollies over 0.6 s to a framed panel (D-57 Q4). **E** or **Esc** steps back.
  - Each console carries a live idle screen (display only), for example "Course plotted · commit here", "Guided voyage ready" or "Archive · 3 entries open".
  - On a title-screen launch the Voyage console and the navigation station glow and a hint shows. Both stay until the first console use.
- **The navigation station (helm)**: `GalaxyMap` is embedded in the ship's window over the panel (`force_native` off, its own 3D world and input; the U4a spike's choice). It holds plotting (a star, Sol, a body in this system), cruise speed, commit, cancel, Return to Sol and the Sgr A* entry. At Sgr A* the panel shows the stop ladder with **Approach to the next stop** and **Leave Sgr A\***.
- **M is the read-only star chart** (D-57 Q2): browse, select and read only. It has no slider, commit, cancel, Return to Sol, in-system list or Sgr A* entry. It never plans and never pauses the guided voyage. Its selection carries over to the helm. I-card "Open in map" opens the chart.
- **The Voyage console** shows the itinerary and **Begin guided voyage**. **The Archive terminal** opens the codex with the news and legacy-log line. The free-navigation session now carries the Archive table, so the codex shows what it has unlocked.
- **Confirms** (§C4): commit, Begin guided voyage, Approach and Leave confirm by a 1.5 s hold. Releasing restarts the hold with no penalty. With the accessibility setting they confirm by pressing twice; Esc backs out. No confirm has a deadline.
- `ShipConsoles.use(station, action)` is the single decision entry for the player's panels, the tests and M4.5's bot.
- **Dwell label** (§A3): when the view rests 0.5 s, the star or body at the centre is named with its distance and "I details". It uses the I card's own pick, read only, and can be toggled in Tab.
- `make ship-console-test` and `make no-twitch-test` (in `make test`).
  - The console test covers stations, reach and facing, the dolly, both confirm modes, helm against chart, Voyage, Archive, Sgr A*, Walk to and onboarding.
  - The no-twitch test (NT1) sweeps every key, the mouse buttons and the pan gesture in four states and finds no player decision intent. NT2 shows that a dialog, a panel and an armed confirm survive 600 s of fake time.
- `make ship-ui-window-check` (GPU window, AC15): the helm opens over the console, takes a real click selection and a 1.5 s hold commit.

#### Changed

- **N, L and C no longer decide.** N is the guided voyage's Skip dwell (pacing); K stays as skip stage, or finish approach at Sgr A*. Approach and Leave are at the navigation station, and the codex is at the Archive terminal. The interim Tab "Decisions" block is gone.
- Outside the helm the map rests in chart mode and plans nothing. A commit confirmed at the helm still goes out on the next tick.
- A commit now re-plans any plan in its own tick (it used to re-plan body plans only). Before this, a star plan made before the 1.5 s hold was refused `stale_plan`, because a ship at rest moves with its body. The GPU window check found this.

### ism-dust (2026-10-09)

#### Added

- **The real interstellar medium** (sprint R1-ISM-DUST, PR A; D-60, D-61). New games (protocol 2.8) fly model `lism-1`: the Local Interstellar Cloud the Sun sits in (its harmonic surface, refit to Linsky et al. 2019 Table 2), the 14 other Redfield & Linsky 2008 clouds with digitised angular outlines and approximate radial depths (a labelled game approximation; G starts at the Sun, the Hyades cloud lies on the road to Aldebaran) and the Local Bubble's hot gas everywhere else (n_H 0.2474 and 0.0039 cm⁻³; Slavin & Frisch 2008, Snowden 2014). The glow, the load, the drag and the drag-energy ledger follow the medium the ship is in; the ledger integrates the column of each flown piece exactly (`sim/ism.ail`, `sim/data/ism.ail` generated by `sim/tools/ism_build.ail` from `data/ism/sources/*.tsv`). Older protocol minors stay `uniform` (HB-3's 0.1 cm⁻³): every recorded stream is unchanged.
- **The drive-hold limit** (D-61): a plan whose cruise the photon drive cannot hold against the drag at its route's densest medium is refused `m_eff_too_small`, followed by a `hold_limit` event with the highest speed it can hold and the medium; never capped. The plan shows the media crossed, the peak density, that limit, the grains swept and the expected visible flashes. Every guided-tour leg plans under `lism-1`.
- **Dust-grain impacts** (D-60, D-61): the grains the Ulysses spacecraft measured (Krüger et al. 2015), drawn per tick from a stateless SplitMix64 stream (no existing Rng stream moves): bright impacts as events in `ship.ism.impacts`, the faint ones as a glitter descriptor; each flashes on the forward wall as the wall afterglow G-AG (labelled a game approximation; r_s 0.5 m, τ 0.2 s, eps the glow's 1e-10), through the same blackbody efficacy and exposure as the glow (`interior/dust_flash.gd`, `.gdshader`).
- **The medium on the galaxy map** (key **D**, a display control): the LIC surface, the cloud shells coloured by n_H on one log scale, labels, the legend with the sources and the assumptions, and the planned route coloured by medium (`ui/ism_layer.gd`).
- Packages: `sunholo/celestial` 0.4.0 (`ism`) and `sunholo/relativity` 0.12.0 (`medium` column and hold limit, `dust`), published after an independent evaluation (86/100), clean quality and dry runs. Spec: stapledons-design `physics/ism-structure.md` (IS-1..36) and higgs-bubble.md §5/§6b (HB-113..149), vendored into `data/lore/physics`.
- Make: `ism-data`, `ism-data-verify`, `ism-oracle-check` (`tools/ism_dust_ref.py`, stdlib oracle), `ism-test`, `ism-determinism`, `ism-bench`, `dust-flash-test`, `map-ism-test`, `ism-lore-drafts`, `ism-capture` (renders/ism: flight frames per medium and speed, the flash close-up, the afterglow, eps and sensitivity sheets, map views); goldens G-ISM-1..4 in `make golden`.

#### Changed

- Pins: `sunholo/relativity` 0.12.0, `sunholo/celestial` 0.4.0. The 2.6 hello keeps reporting relativity 0.10.0 (`relativityPinGr`); 2.7 keeps the inferred-star pin 0.11.0; 2.8 reports the current pin.
- Interactive sessions ask for protocol 2.8 (`SimBridge.ISM_MINOR`); captures keep their pinned minors.
- The lore registry also reads the IS-n rows of `physics/ism-structure.md`.

- The HUD reports local visible and bright flash rates per ship second, plus cumulative grains swept; cruise summaries scroll and retain their Continue control at 720p.
- Route media preserve travel order and repeated entries. Compressed boost/brake dust totals use phase-split quadrature checked against an independent fine-grid oracle; final arrival records the flown total without at-rest flashes.
- A frozen protocol 2.7 inferred-star session from main is checked byte for byte against both engines. Refused inferred-star plans no longer mutate the celestial body catalogue.
- Compressed ticks report every crossed medium in order, including returns to the starting medium. Largest-impact readouts explicitly describe displayed samples rather than the unrendered compressed population. GR scenario placement refreshes the cached medium at the new position.

## v0.4.0-dev.25-free-nav (2026-10-09)

### Stops that show relative size (D-54), Sol in the map, in-system destinations, 2026-10-08

- Free navigation stops at a star with a cited radius where it shows its size (D-54: 2 atan(tan 5° √(R/R☉)) across): TRAPPIST-1 3.5° at 0.018 AU, alpha Cen A 11° at 0.059 AU, Aldebaran 61° at 0.415 AU. Stars without a cited radius (Barnard's Star, most of the map) still stop at 1,000 AU until a package release adds a bolometric correction (inferring their radius is blocked, see the design doc).
- Planet and moon stops (free navigation and the guided tour) show the body 2 atan(tan 15° √(R/R⊕)) across: Moon 16°, Earth 30° (24,643 km, also the tour's start), Callisto 18.7°, Jupiter 84°; Saturn clears its rings (154,673 km, 46°). The Sun keeps 3 R, the tour's star stops keep D-47 and the legs keep D-46's timing.
- Sol is clickable on the map, and a Return to Sol button plans home. Home now arrives beside Earth (30° across) with the Solar System around the ship, not at the Sun's centre; the M4.4 return log is unchanged.
- In a system the map lists its bodies ("In this system": planets, moons, the stars) as destinations, planned with the tour's body planner and stopping at D-54 distances; the commit hold is the same. A refused leg says why (collision, ring_crossing).
- `make free-nav-stop-test` flies it all; `sim/stops_test.ail` and `make strict` (stopsVm) check the rule's values on both engines; `tools/stops_capture.gd` renders every stop to `renders/stops/`.

### Fix: free-navigation stops (HUD distances, I at the destination), 2026-10-08

- Stopped after a free-navigation leg, the HUD now says where the ship is: "At Barnard's Star 1000 AU · from Earth 5.95 ly", and after a second leg "At Alpha Centauri A 1000 AU · from Barnard's Star 6.43 ly · from Earth 4.31 ly". It used to show only "from Earth". Destinations use catalogue names, not raw ids, while cruising too.
- I now offers the free-navigation destination with its card. The sky tiers key Gaia sources by the bare source number while the catalogue keys them "Gaia DR3 n", so no Gaia-identified star (Barnard's Star, most of the map) was ever offered; sky rows now map to their catalogue record. A click between alpha Cen A and the nearer B now picks the disc it is on (or the closer centre) instead of always the nearer body.
- `make free-nav-stop-test` (in `make test`) flies the real flow: open navigation, commit, fly to Barnard's Star and then alpha Cen A, check the HUD line, then I and the card.

## v0.4.0-dev.23-black-hole (2026-10-08)

### Lightspeed loading view, 2026-10-08

- Board the ship, Guided voyage and Galaxy map no longer freeze the title while they load. The title's own sky accelerates toward the galactic centre as the load progresses, through the game's real relativistic optics (aberration, Doppler colour, the starbow), to 0.99999c at 100% (γ 223.6): the whole sky collapses into one blinding blue-white point. Then a white-out (a transition effect, not physics) blooms from that point and fades into the destination.
- The overlay shows β, γ and 1 − β (from the `sunholo/relativity` mirror; never 1.0 − β), the percentage, the stage being loaded, and says the speed is illustrative while the optics are the renderer's. Progress is real: stages weighted by measured time and counted when they finish, monotone, 100% only when the destination is built and drawn.
- Faster: press to ready, Board the ship 7.9 s → 2.0 s, Guided voyage 7.3 s → 2.0 s, Galaxy map 3.0 s → 0.7 s (Mac Studio). The simulation starts on a worker thread; the galaxy map's star colours are computed on workers and ten times faster (a table form of the colour integral, bit-identical); the ship reuses the title's decoded sky panorama and loaded star tiers; the captain's sprites are built one a frame. The ship's scene build still holds the jump for about 1.3 s.
- Command-line, capture, golden, smoke and export modes are unchanged. `make loading-jump-test` (in `make test`), `make loading-jump-capture` (renders to `renders/loading_jump/`), `make loading-profile`; two golden cases at the jump's 50% and 100% speeds. Design: `design_docs/planned/r1/lightspeed-loading.md`.

### m3.6-sgr-a-aboard (2026-10-08)

#### Added

- **Sgr A\* aboard the 3D ship** (sprint R1-M3-BLACK-HOLES, M3.6; D-52, D-53). The navigation window (M) has a **"Sgr A\* (black hole) · demo"** entry, the HUD a **"Visit Sgr A\* (black hole)"** button, and `make run-bh` launches straight into it (`-- --ship-demo --scenario=sgr_a`). It starts its own simulation session (scenario `sgr_a`, protocol 2.6) in place of the normal navigation session; the ship hovers 10⁶ r_s (1.34 ly) out with its nose on the hole. **N** takes the next stop: approach to 10 r_s at local β 0.1 (paced as a steady fall in log r, about 15 s), then 5 and 3 r_s, then an orbit at 3 r_s, then a hover. **K** finishes an approach at once, **C** opens the Archive codex, **L** leaves (back to Sol at rest, GR off). The sky is the M3.5 lensed sky: the Milky Way and the large-tier stars as seen from Sol (design OQ5), captioned on the HUD.
- The black-hole HUD shows only the sim's `gr` fields, formatted: hole, mass and r_s; hovering / approaching / orbiting at r; the static clock and "1 ship-hour = … home hours"; the shadow half-angle and the blueshift of incoming light; the tide across the bubble (radial and squeeze); "hover … g · not felt (bubble) · … W per kg of m_eff", or "free fall: 0 W" in orbit. The details line now reads "GR on … / GR off" instead of "GR not implemented", and so does the ship benchmark's report.
- The Archive events reach the codex: arriving unlocks nothing new, the first hover at r ≤ 10 opens *Tides* and *The Shadow and the Ring* (the sim's `first_black_hole`), and the first ring star the sky draws is reported to the sim (`gr_ring`), which records `bh_ring`.
- `make bh-hud-test` (in `make sim`, so in `make test`): HUD sentinels (each shown number moves with its field), the menu entry and `--scenario=sgr_a`, the scripted stops through the real sim, the codex unlocks, the three Archive events in order, the ship's key light back at its moody level with no star, GR off after leaving and in a normal navigation session, and the AC-12 grep (no `sqrt(1 - 1/r)` in demos, ui, sky, bridge, interior).
- `make capture-bh` (sim-driven, GPU window): `renders/bh_r{10,5,3}_{toward,side,away}_{hover,orbit}.png`, the same on the debug grid, two bridge views with the HUD, two contact sheets and `renders/bh_manifest.sha256`. The reviewed baseline is pinned in `data/refs/bh_manifest.sha256` and served from the public bucket (`make bh-refs`); `make bh-render-diff` diffs the current renders against it (`tools/render_diff.gd`, mean |d| ≤ 1/255). Two captures in a row are byte-identical.
- `make bench-bh`: the ship's frame cost with GR on (hover at 10 r_s; a live orbit at 3 r_s) against GR off at the large tier, wall time and the GPU time of the sky and ship viewports.
- The M3 report, `design_docs/implemented/r1/m3-report.md`: bar clause 3's evidence, command by command.

#### Changed

- `InteriorSky.apply()`: with a `gr` section the catalogue stars are placed as seen from Sol (`gr_stars_from_sol`, design OQ5), matching the Milky Way photograph; the sim's ship position at Sgr A\* would otherwise rebase 335k stars to the Galactic Centre.
- The weak-field factor `gr_weak_k` moved from `sky/gr_lens.gd` into the CPU mirror as `Schwarzschild.weak_k(r)` (= 1 / impact(r, π/2)), with a `make physics` check against `weak_deflection_finite`; no client file outside `physics/` holds a Schwarzschild formula.

### m3.5-lensed-sky (2026-10-08)

#### Added

- **The lensed sky** (sprint R1-M3-BLACK-HOLES wave 3, M3.5a/b; relativity spec §3). `sky/schwarzschild.gdshaderinc` mirrors `physics/schwarzschild.gd` function for function on the pinned `lens_fwd`/`lens_inv` texels, and `sky/background.gdshader` and `sky/starfield.gdshader` include it. Per pixel: de-aberrate to the local static frame with the sim's local motion, the analytic capture test (black inside Synge's shadow; α_sh arrives as a float32 hi/lo pair formed in float64), the table lens to n_∞ in the galaxy frame, the panorama (or the debug grid, `grid_on`) with the mip level grown by the lens stretch, and D = D_g·D_SR. Stars: order 0 on the starfield, order 1 on a second `MultiMeshInstance3D` on the same multimesh that exists only while GR is on, with flux μ·Y(D T)/Y(T)/D_SR²; a star whose image is stretched over 8 goes to the ring-star path (up to 64 source-plane Gaussians in the sky pass; the overflow stays splats with μ capped at 8 and is counted on `GrLens.debug_line()`).
- `sky/gr_lens.gd` (`GrLens`): the sim's protocol-2.6 `gr` section → the shaders, through float64 scalars only; `InteriorSky.set_gr` (and `apply()` when the world carries `gr`) and `SkyBackground.set_gr`. The unified 3D ship's sky (D-52) is the target.
- `make golden` GR1–GR12 (`tools/gr_golden.gd`, sky-only `InteriorSky`, linear half-float target): the shadow radius at 10, 5 and 3 r_s against Synge (bar clause 3), the orbit shadow mask per pixel at three orientations, both images of a star at three geometries, the Einstein ring at 10, 100 and 1000 r_s, black inside the shadow, the blueshifted colour at 3 r_s, the weak-field hand-off at 9e5 and 2e6, and an exact table mirror (GR10/GR11: the shader's float32 δ and image ψ against the CPU per pixel to 2e-5 relative, and GR12, which switches each interpolation rule off in turn through a golden-only `gr_mutant` uniform and asserts that GR10 fails).
- `make capture-bh-sky` (`tools/gr_capture.gd`): debug-grid, Milky Way + large-tier, Einstein-ring and two-image renders to `renders/bh_sky/`.
- `make bench` prints `bench: GR off/on/approach` sweeps (r = 10 r_s, the whole tier, both images and the ring path; the approach calls `set_gr` every frame as `InteriorSky.apply` does and reports its CPU cost).

#### Fixed

- Float32 conditioning in the lens lookups, found by the GR10/GR11 mirror goldens: the column grid is uploaded per r as ψ_i − α in float64 (`GrLens.column_offsets`), and the column fraction is never carried as the float i0 + f (near column 2047 that keeps only 2.4e-4 of a column; the Metal compiler also re-associated `(1023.5 − i0) + F k`).

## v0.4.0-dev.22-title-screen (2026-10-08)

### Title screen, 2026-10-08

- A plain launch (a double-click on the app) now opens a title screen over the real sky: the NOIRLab panorama and the catalogue stars, rendered at rest by the game's own sky stack with a slow pan along the Milky Way. Buttons: **Board the ship** (the 3D ship at live rest, as before), **Guided voyage** (the ship, straight into the solar-departure tour), **Galaxy map**, **Settings**, **Credits**, **Quit**. Mouse or keyboard (Up/Down wrap, Enter, Esc closes a panel, PageUp/PageDown scroll the credits). The footer shows the build id and "dev build".
- Esc aboard the ship, or the new "Main menu [Esc]" HUD button, returns to the menu when the ship was opened from it; Esc on the map does too. Every command-line launch (`--ship-demo`, `--voyage`, `--interior`, `--map`, captures, goldens, benches, smokes) is unchanged and keeps Esc = quit.
- Settings: the ship's view, Realistic (default) or Auto (D-38), saved in `user://settings.cfg`; text-only AI (D-8), saved as the AI settings' own `text_only` in `user://ai_settings.cfg`, so the AI tick and ceiling are kept.
- Credits: the NOIRLab CC BY 4.0 panorama, Solar System Scope textures, CNS5, Gaia/DPAC, Hipparcos, the NASA Exoplanet Archive, Godot and AILANG, plus every paper and table the simulation cites, read at runtime from the citation lists in `sim/data/*.ail`.
- `make export-macos` stamps `runtime/build_version.txt` (`git describe`). `make title-screen-test` (in `make test`), `make title-capture` (renders to `renders/title_screen/`), `make title-export-smoke` (in `publish-dev`); `current-ship-export-smoke` now launches with `-- --ship-demo`. Design: `design_docs/planned/r1/title-screen.md`.

### m4.5s-session-audits (2026-10-08)

#### Added

- M4.5's scene-independent audits: AILANG `playthroughTime` and `codexUnlocks`, strict pure fixture tests, VM/interpreter fixture parity, minimum-path and adversarial sim replays with arm64 digest goldens, explicit unchanged-state refusal assertions, and a one-bit replay positive control.
- `mk/m45.mk` provides `parity-m4`, `session-audit-test`, `codex-unlocks`, `playthrough-time`, and the scene-independent replay authoring command. The first three are main test prerequisites.
- The requested Sol → alpha Cen A → Sol round trip at default warp measures 67.35 s per leg, 134.70 s transit total. The ten-stop `solar_departure` tour is a separate scenario. UI events are fixtures until the scene playthrough bot (M4.5aR3, D-66 re-plan of D-52 (A), the default 3D ship) lands.

#### Verification limitations

- v0.52.0 FS entries require ordinary VM interop; the pure audit functions and named tests run strictly. An effectful test-helper omission has a minimal repro in `design_docs/planned/r1/m4.5s-inventory.md`; strict fixture byte mirrors are verified against the actual files by the FS test entry.
- x86_64 goldens recorded on CI (throwaway draft #153, run 37742569263): both digests equal the arm64 ones. No scene bot, walking test or display audit was built.

### m3.4-gr-mode (2026-10-08)

#### Added

- **The sim's black-hole mode** (sprint R1-M3-BLACK-HOLES M3.4a, `sim/gr.ail`, pure, strict VM). A non-spinning hole (D-13, D-53): the ship hovers, orbits or approaches radially, and every step is ship-proper-time driven. Home time is dτ divided by the package's clock rate: `staticClockRate` for a hover, `circularOrbitClockRate` for an orbit (the orbit phase advances by `orbitalAngularVelocity`), `movingClockRate` for an approach. An approach integrates r with RK4 on `radialCoordinateRate` and stops exactly at the target; the rest of the tick is a hover there. The tide across the bubble (`tidalAccelSI`, `tidalOrbitAccelSI`), the hover acceleration and power (`hoverAccelSI`, `hoverPowerPerKg`, `medium.hoverPower` × m_eff), the blueshift, the shadow, and the local β, γ and 1 − β (rapidity forms) all come from `sunholo/relativity` 0.10.0. The sim adds no formula of its own. `make strict` gains `scriptedApproach` (Sgr A*, 10⁶ → 10 r_s at β 0.1: 1.0000016182849817e7 t_s against the closed form 1.0000016182849806e7, 1.1e-15 relative, strict VM = interpreter) and `grVm`.
- **Protocol 2.6** (M3.4b). A client that asks for minor ≥ 6 gets minor 6, and the hello reports relativity "0.10.0".
  - The `new_game` scenario `sgr_a` places Sgr A* at its galactic position: 4.297 × 10⁶ M☉ at 8,277 pc (GRAVITY 2021), at l 359.944°, b −0.046°. The ship starts 10⁶ r_s (1.341 ly) from it, on the Sol side. The params `bh_mass_msun` and `bh_r` make the mass and the starting radius scenario data, so the canon's rogue hole needs no code.
  - Four intents: `gr_approach {to_r, beta_local}`, `gr_hover`, `gr_orbit` and `gr_ring`. The client sends `gr_ring` the first time a ring star fires.
  - The refusals `bad_radius` (outside [2, 10⁶]), `bad_gr` (a speed outside (0, 0.99] or a zero-length approach; a malformed GR intent makes the whole line `bad_gr`), `not_in_gr`, `moving` and `in_gr` each leave the state unchanged. `in_gr` refuses the flat plan, commit, thrust and heading intents near the hole.
  - Each state carries a `gr` section with everything the HUD shows: r, mode, static and ship clocks, home hours per ship hour, blueshift, shadow, local β/γ/1 − β, tides, and the hover acceleration and power. A black hole has no `system` section.
  - The archive events `{"k":"archive","event":…}` are `bh_enter` (at `new_game`), `bh_hover` (the first hover at r ≤ 10) and `bh_ring`. They go into the legacy log. `first_black_hole` now holds after `bh_hover`, which unlocks the Archive's tides and shadow-ring entries.
- `SimBridge.GR_MINOR`, `SimBridge.gr`, `parse_gr()` and `gr_approach()`. A live bridge test runs under `make sim`.
- `make parity-gr` (in `make test`) runs `tests/fixtures/gr.ndjson`, which covers every GR intent and refusal. It checks that the VM and the interpreter agree byte for byte, that the archive events come in the order bh_enter, bh_hover, bh_ring, and that Sgr A* has mass 4.297e6.

#### Changed

- Below minor 6 every recorded stream is unchanged: `make replay`, `parity`, `parity-offaxis` and `parity-v2` pass with no golden re-recorded.

### m3-wave2a-lens-tables (2026-10-08)

#### Added

- **Schwarzschild lens tables** (R1-M3-BLACK-HOLES M3.2). `sim/tools/lens_lut.ail` lays out two 2048 × 256 float32 RG tables from `sunholo/relativity` 0.10.0: `lens_fwd` (the regular part of the deflection, by the Binet integrator at h = 0.0025, and dδ/dx) and `lens_inv` (image angle and dψ/dF by Fritsch–Carlson inversion of the exact form). `sim/tools/lens_lut_main.ail` writes them in parallel VM shards (436 s wall with 14 jobs; the bytes never depend on the sharding) with a JSON header (layout, ranges, generator, package version, sha256). The headers are committed. The 4 MiB bins are pinned in `data/lens/SHA256SUMS` and live in `gs://stapledons-voyage-assets/lens/`.
- `make lens-assets` (in `make test` and before `make physics`) fetches them in under a second, or regenerates them on the VM and requires the pinned bytes. `make lens-lut` regenerates them, `make lens-publish` uploads them (maintainers), and `make lens-lut-check` (in `make test`) regenerates a sample bit for bit and compares row 128 on the strict VM and the interpreter.
- **CPU mirror `physics/schwarzschild.gd`** (M3.3): Synge's shadow, the static blueshift, the exact form (Carlson R_F) as an oracle, the table lookup the shader will mirror, `lens_direction`, `star_images` and `compose`. The new "Schwarzschild (spec §3)" section of `make physics` checks RS-9 to RS-21, the package's check41–47, table accuracy on 10,000 probes (worst 1.1 × 10⁻⁵ rad at r ≤ 100), the weak-field pair on the r = 10⁶ row, finite and monotone tables, and a 1,000-pair round trip.

#### Changed

- Design doc corrections from wave 1, recorded as dated notes in the doc: `tidalAccelSI` divides by r_s², the exact form's outgoing branch uses 20-point Gauss–Legendre, and check44 at ε = 10⁻⁸ is held to 3 × 10⁻⁹ of the 50-digit truth.

### m3-wave1-relativity-0.10.0 (2026-10-08)

#### Added

- `sunholo/relativity` **0.10.0** (sprint R1-M3-BLACK-HOLES wave 1, M3.1a/b/p, ailang-packages #103), published under ledger D-53 after an independent evaluation (91/100 PASS), a clean `pkg quality` and a dry run. New module `geodesic`: the Binet RK4 integrator (`escapeAzimuth`, `lensDeflection`, `deflectionFromInfinity`), analytic capture (`escapes`), Darwin's exact form through Carlson R_F (`carlsonRF`, `deflectionExact`, `escapeAzimuthExact`, `deflectionExactAt`), the lens map (`lensRegular`, `imageAngle`, `einsteinAngle`, `imageMagnification`) and Fritsch–Carlson inverse rows (`inverseRow`). `schwarzschild` gains the closed forms for a visit: clocks and circular orbits, tides across the bubble and their inversions, hover acceleration and power.
- `tools/geodesic_ref.py` (role `oracle`): an independent Python integrator, Carlson R_F and a 50-digit Decimal truth that reproduces design rows V9–V16. `make geodesic-oracle` (in `make test`) runs its `--check`, holds its digests to the package's pinned `lensDigest`/`schwarzschildDigest` within 1e-9, and reruns the pinned package's `lensDigest 16` on the strict VM.

#### Changed

- The sim pins `sunholo/relativity` 0.10.0 (M3.1c). The hello pin is split: minors 4 and 5 keep reporting "0.9.0" (`relativityPinNav`, frozen so every 2.4/2.5 stream stays byte-identical); `relativityPin()` is the current pin, which protocol 2.6 (M3.4b) will report. `make hello-pin` checks both.

## v0.4.0-dev.21-perf-inspect (2026-10-08)

### Inspect the system you are in (I key), 2026-10-08

- Holding I now rings the Sun, planets, moons, finite stars and exoplanets as well as catalogue stars, at the size they are drawn. Clicking one opens its card: distance from the ship, size and apparent size, temperature for stars, how long ago its light left, its catalogue identity ("Open in map") and its data source.
- Planets and moons of a distant system are not offered (they are invisible from there), and a body behind a nearer one is hidden, as stars are.

### Fix: the dev.20 lag with the 100 pc sky, 2026-10-08

- Every frame, the sky checked each finite star against all 335,189 star identities with a linear scan: 13.7 ms a frame on an M4 Max at the Aldebaran stop, enough to drop Mark's M2 Air from 60 to about 53 fps (30 fps in the overview). It now uses the starfield's hash index: 0.01 ms. With the large sky, Studio frames went from 16.1–30.3 ms to 8.3–8.5 ms, the same as the medium sky.
- A regression test checks that the unchanged per-frame call costs no more at 300,000 stars than at 3,000; it fails on the old scan (3.3 ms against 0.03 ms).
- Performance audits record the exported build's real version (written into the bundle at export) instead of a stale "dev.14" constant.

### m4.6-ungated-physics (2026-10-07)

#### Added

- M4.6, ungated half (sprint R1-M4-JOURNEY): the CPU physics check values and the precision lint. The GPU goldens, `capture-m4` and the bench stay open.
  - `sim/tools/m4_physics_probe.ail` (`make m4-physics-probe`, VM = interpreter): prints the cruise (`gammaOf`, `coastAt`, `planBurnCoastBurn`), ISM load, glow profile and one row per stop of the guided voyage. Every new expected value is copied from it.
  - `tests/test_physics.gd`: gamma(0.99c) = 7.088812050083356 exact; `cam_bridge.json` read from the shipped asset and projected through the ship basis (galactic centre and pole headings, galactic +x and +z); the glow profile at the sim's eps 1e-10 at 0/45/80/90/120 deg (the plan quoted 1e-9, ten times brighter, same shape); finite pole, luminance, LUT efficacy and colour at every stop (0.99c legs, the 0.999c / 0.9999c / 0.999999c hops, rest, the guided drive cap).
  - `sim/m4_physics_test.ail`: the quantities only the sim computes: `coastAt` 4.398169 / 0.620438, `planBurnCoastBurn` 4.398171 / 0.620443, `loadScale` 221961.27 W/m2 (HB-40) read back through `ismAt`, and finite load, drag, glow, pole temperature and luminance on all 10 legs of `solar_departure.legs`.
  - `make lint-precision` (in `make test`): no hand-computed `1 - beta` in `*.gd` / `*.gdshader` outside `physics/` and `tests/`. `tests/fixtures/lint_precision/bad_one_minus_beta.gd` must match all four planted lines, the good file none, and `allowlist.txt` lists the seven existing non-computations (a fallback default, three golden-harness gammas at beta <= 0.9, a caption and two row labels).

#### Changed

- `make physics` fails unless the run prints its `<n> passed, 0 failed` summary. A script that failed to parse used to exit 0 with no summary.

#### Not yet

- At the guided drive cap (1 - beta = 2e-9) the glow reaches 14 W/m2 (mean), above the 1 W/m2 bound HB-61 holds at the 1e-6 cap. It is finite and kept by D-48; the HB-61 bound is not asserted there.

## v0.4.0-dev.20-trappist-planets (2026-10-07)

### The ship lit by the real star, 2026-10-07

- The ship's geometry is lit by the star the player sees (dev.20). A new `StarLight` comes from the dominant finite star's apparent direction, the same aberrated disc centre the sky draws, turned into ship axes by the sky camera's attitude, so the light comes from where the Sun is seen through the bubble. Turning the ship sweeps the Sun's shadows across the bridge; when the star is below the deck, the floors shade it.
- Its colour is the star's blackbody at T × D (the renderer's lookup, Doppler at the apparent angle): TRAPPIST-1's light is red, Aldebaran's orange, the Sun's white.
- Its brightness is **log-compressed, not physical**: each decade of the illuminance at the ship (sim `e_v_lux`, Doppler flux ratio, eclipses) is an equal step from 1 lx (off) to 10⁵ lx (full). Earth is full, Jupiter about 73%, interstellar cruise off. The HUD details (Tab) and the lighting manifest say so.
- The moody ambient, cool fill and Commons practical stay; the ship-fixed broad key dims as the star takes over, never below a 25% readability floor (ship light, not physical, shadowless), and is fully back between the stars. Exactly one light casts shadows at a time; the handover fades through zero opacity. Changes ease over 0.5 s; a second star must be 1.5× brighter to take over.
- `make ship-star-light-test` (in `make test`), `make ship-star-light-capture`, `make ship-star-light-bench`.

### TRAPPIST-1's seven planets, 2026-10-07

- TRAPPIST-1 b–h are real bodies at the voyage's habitable-zone stop (Sprint B part 2, D-41). They come from a pinned NASA Exoplanet Archive snapshot (`data/planets/trappist1_ps.csv`, sha256 in `EXOPLANETS.SHA256`, fetched by `tools/fetch_trappist1.sh`), transcribed with citations into `sim/data/trappist1.ail`.
  - Size and orbit are from Agol et al. 2021. Orbital phase is from Ducrot et al. 2020's mean transit ephemeris, which predicts JWST's 2024 transits of b and c within 15 minutes.
  - Circular orbits, the sky-plane node and the albedos are stated assumptions.
- Each planet is where it really is when the ship arrives: Kepler orbits from `sunholo/celestial`, phased by the transit epochs less the 40.6-year light-time. Each is lit by TRAPPIST-1's own light: the wire carries the host's `teff_k` and `e1_au_lux`, so `SystemView` no longer lights every planet with the Sun.
- The stop keeps D-47 (√L = 0.0235 AU from the star) but now sits on that sphere beside the best-lit planet. At the voyage's arrival that is e, 0.72° across. c (crescent), d (half lit) and f are resolved discs too. Every orbit stays more than 30 radii from the resting ship; d, just inside the HZ, comes nearest at 192,000 km. The voyage keeps its 10 stops.
- `make trappist1-test` (in `make test`) checks the pin, runs the sim checks with the strict VM equal to the interpreter, and runs a Python oracle that recomputes every row and position (worst 2e-12 AU). `make trappist1-capture` renders the stop to `renders/trappist1/`.

### Star colours in Auto view, and a longer approach to a giant (D-49), 2026-10-07

- In Auto view a star is dimmed just enough to keep its hue and its own blackbody colour is lifted: Aldebaran is golden orange, TRAPPIST-1 red-orange, the Sun a warm white. Realistic view is unchanged; the HUD says "star colours enhanced".
- Aldebaran's final approach lasts 90 s from where it is 25° across, so the giant grows from the starbow into a 40° disc instead of appearing in the last seconds. Other stops keep 25 s.
- The voyage capture takes approach frames at the start, middle and 85% of each leg's own approach.

### The full 100 pc sky (large tier), 2026-10-07

- The ship's sky draws every GCNS star within 100 pc. The large tier has 331,311 rows: all of GCNS minus HIP 27890's duplicate. Of these, 324,306 have photometry and are drawn. With 170 CNS5-only stars and 10,713 bright Hipparcos stars added, the sky draws 335,189 stars, against 60,883 on the medium stack. All are at truth positions.
- `make starmap-assets` fetches the pinned tier (`data/starmap/SHA256SUMS`) from `gs://stapledons-voyage-assets/starmap/` in under a second. `make test` (and so CI) and `make export-macos` run it. `make starmap-consistency-large` fails if the file is missing or not 331,311 rows. The game falls back to medium with a warning naming the missing file, and the galaxy map's coverage tooltip shows the active sky tier.
- Benchmarked first on the M4 Max, 3 runs per tier.
  - GPU timestamps (Vulkan): the star pass costs +0.25 to 0.30 ms at p50 (0.32 ms against 0.02 to 0.07 ms).
  - Wall time (Metal): frame p99 is 10.6 to 10.8 ms on both tiers.
  - Loading takes +0.45 s.
  - Exported app: +15.2 MB, and about +240 MB peak RSS at the sky scene (`make starmap-export-smoke`).
  - M2 Air: an estimate of about +1.3 to 1.8 ms, not measured.
  - Destinations to 100 pc wait for the galaxy map's level-of-detail design (the design's default: sky first).
- `tools/starmap_sky_capture.gd` renders medium and large side by side. At rest and 50 ly out, the large tier adds about 20 % more visible faint stars. These are GCNS stars that the destarred panorama had already removed. At γ 707 the boosted CMB fills the forward cone; with the CMB off the starbow gains 3 % in light.

### One position per star, 2026-10-07

- A new star-truth table, `data/starmap/truth/positions.csv`, gives one position for each of the 5,212 stars that more than one catalogue lists. It is built in AILANG by `make starmap-truth` (VM = interpreter). Navigation and every sky tier take positions from it, so a map journey to a Gaia-only star arrives with the star 1,000 AU ahead. TRAPPIST-1 was 3,650 AU away on arrival, 10 UMa 8.7 ly beyond its stop, and GJ 10940 6 ly *behind* the ship.
- Rule `truth-1`: CNS5's adopted parallax wherever CNS5 evaluated the star. That is Gaia EDR3 with the Lindegren zero-point correction, or Hipparcos/DR2 for the 69 stars whose EDR3 solution is poor. Gaia EDR3 is used for CNS5 stars without a Gaia id, when its solution is good. The design's "posterior vs 1/ϖ" diagnosis was wrong: every catalogue already uses 1/ϖ, and the offsets were the zero-point correction plus CNS5's per-star source choices. The 14 disagreements over max(3σ, 1 %) are all "better parallax" cases, each one documented in `design_docs/implemented/r1/starmap-truth-audit.md` (`make starmap-truth-audit`).
- The sky stack now adds every CNS5 star that GCNS lacks (26 destinations were missing from the sky). It restores destinations to their float64 navigation positions and draws no star twice. `make starmap-consistency` checks all 5,685 destinations. `pin_destination` is now an assertion, and a no-op for every destination.
- Navigation is unchanged apart from CNS5:138, which has no photometry. The medium tier moves about 5,100 stars onto the navigation positions.

## v0.4.0-dev.19-finite-stars (2026-10-07)

### Finite destination stars, 2026-10-07

- Every star the voyage visits has its real size (D-47/D-48). Aldebaran (45 R☉, 3,927 K; Richichi & Roccatagliata 2005, Heiter 2015) and TRAPPIST-1 (0.119 R☉, 2,566 K; Agol 2021) become cited finite stars, replacing their catalogue points.
- Stops follow one rule. Main-sequence stars stop in their habitable zone (√L AU), where they look like the Sun from Earth: α Cen A at 1.233 AU, TRAPPIST-1 at 0.0235 AU (2.7° across). Giants stop where they fill 40° of sky: Aldebaran at 0.615 AU.
- Each star's final hop uses the even-leg rhythm: 30 s accelerating, about 60 s cruising, then the 25 s final approach. The voyage now has 10 stops.
- A finite star named by its Gaia id also hides the sky's bare-number catalogue row, so its light isn't counted twice even without a destination pin.

### News from home, the AI path, the return trip and the legacy screen, 2026-10-06

- M4.4. The Archive terminal's news tab is a panel: "Transmission received", a header built from sim fields ("Latest news from Earth: Earth-year +0.04, already 4.31 years old."), and one paragraph from `data/news/templates.json` (five tiers of four, numerals only inside `{slots}`, at most 280 characters), or the accepted AI text. What it shows follows the sim's `news.body_source`: `template` has no notice, `ai` a small "generated" tag, `fallback` the template under "Live transmission unavailable: archived text shown", the reason in words from a fixed digit-free table and a diagnostics entry. Nothing is asked of the AI service without AI on and a key (D-8).
- The map's return trip opens with Sol planned and highlighted (`GalaxyMap.plan_home`, `R` in the interior); the hold-to-commit ritual is unchanged and the sim still refuses a stale plan. Arriving at Sol shows the legacy screen: the sim's log, the closing line from `clock.tau` and `clock.t` ("You were away 1.24 years. Home is 8.80 years older.") and "Begin again" (a new voyage with a new seed on the running sim; no save or load).
- `make news-lint` (template lint, with the stray-digit fixture as a positive control) and `make news-test` (renderings, reason table, return trip, legacy screen over the real sim) are part of `make test`. `make sim` asserts `body_source` template / ai / fallback(`ai_numeral`) on one arrival. S4 copy approved (D-45 B, Mark attended 2026-10-06): at the Sol return the header drops the age clause (", just arrived.") and the body shows the no-age phrase, so the panel never reads "0.00 years old" (`data/news/copy.json` labels; review sheet `design_docs/planned/r1/m4.4-s4-copy-review.md`).

## v0.4.0-dev.18-even-legs (2026-10-06)

### Even legs, a gentle final approach and skip-to-next-stage, 2026-10-06

- Every in-system leg of the guided voyage has the same rhythm: 30 s accelerating, about 60 s cruising, braking, then a 25 s final approach. The sim solves each leg's thrust and cruise speed (0.07c to the Callisto hop, above 0.999c to Jupiter and Saturn); Sun → Jupiter takes about 2¼ minutes instead of 6½ (D-46).
- Arrivals ease in: a new trip profile brakes hard, then approaches gently from where the body is 4° across. It's in `sunholo/relativity` 0.9.0 (published; existing outputs bit-identical), and the ship reports a new `approaching` phase.
- **Skip stage [K]** jumps exactly to the next stage of the leg (accelerating → cruise → braking → approach → arrival). The HUD shows "FINAL APPROACH" and this leg's thrust, and labels how many stages were skipped.
- The HUD also shows the distance to the destination, from the last stop, and from Earth.

## v0.4.0-dev.17-real-time-voyage (2026-10-06)

### Real-time voyage to Aldebaran, 2026-10-06

- The guided tour runs in real time: one ship second per wall second, with no time compression (D-39). A single drive is used for the whole voyage: 3,000,000 g, cap 1 − β = 5 × 10⁻⁷, m_eff 10 kg. It passes the unchanged brake-vs-drag check. Solar System legs cruise at 0.99c (Earth → Jupiter is about 6 ship minutes and 39 Earth minutes).
- The voyage continues past α Cen to TRAPPIST-1 at 0.9999c and Aldebaran at 0.999999c (D-41). It is measured at 0.891 ship years against 120.47 Earth years.
- Cruises longer than 10 minutes of ship time play 10 s in real time, then hand over to a cruise interlude (`ui/cruise_interlude.gd`), the seam for in-ship gameplay. The demo's interlude is a card (`ui/card_interlude.gd`, `ui/interlude_card.gd`). It shows speed, γ, both clocks and the age of news from home, all read from simulation fields, and a line of scale chosen from the cumulative Earth time: "…Everyone you knew is gone." The clock lands exactly on the braking boundary, and braking plays in real time.
- Ordinary map journeys keep their pacing, checked byte-identical against a recorded golden.
- The ship demo HUD is compact: destination and phase, speed (β from the sim's exact 1 − β, γ, km/s) and both clocks; the review and debug details are behind Tab.
- Destination stars render where the simulation navigates (`Starfield.pin_destination`). The sky's GCNS tier placed some stars thousands of AU from the navigation catalogue (TRAPPIST-1 by 0.042 ly), which showed at a 1,000 AU stand-off. A pinned destination later drawn as a physical emitter is suppressed with its identity, so its light is not counted twice.

## v0.4.0-dev.15-auto-view (2026-10-06)

### Realistic and Auto views, 2026-10-06

- Ship demo: a View button `[V]` switches between **Realistic** (default: one manual exposure; sunlit planets clip, as for a real observer) and **Auto** (each resolved body faded on its own to fit the display, labelled as a composite on the HUD). The manual exposure presets work in both; the sky exposure, star photometry and SR maths are unchanged (D-38).
- `tools/exposure_auto_view.gd` renders Earth and Jupiter stops in both views.
- Auto view: stars (the Sun, Alpha Centauri A/B) fade to a higher target than lit bodies, so the Sun stays the brightest thing on screen: white with its warm channel order kept (255, 254, 254), not a grey star. `tools/exposure_auto_view.gd` checks it.

### Boot splash, 2026-10-06

- Replace Godot's default boot logo with a Stapledon's Voyage splash in the style of the website hero: the destarred Milky Way around the galactic centre, the wordmark and tagline, and "Simulation built in AILANG" with the AILANG logo. `make splash` recomposes it in Godot from the panorama (`tools/splash_compose.gd`). Exported builds hold it for at least 1.5 s; editor and headless runs are not delayed.

### m4.7-archive-codex (2026-10-05)

#### Added

- The Archive codex, sprint R1-M4-JOURNEY M4.7 (design `m4-first-journey.md` §M4.7): the design repo's physics lore as in-game entries whose numbers cannot drift.
  - `make lore-import` (`tools/lore_import.sh`, `sim/tools/lore_import.ail`): copies `lore/archive/*.md`, `physics/higgs-bubble.md` and `physics/relativity-spec.md` into `data/lore/` as git objects at a design-repo commit (never the sibling's working tree) and writes `data/lore/manifest.json` (the design sha and a sha256 per file). Imported at `ebe46f9`. `make lore-import CHECK=1` is fail-closed and offline (every vendored file hash-equals the manifest, none missing or extra) and, wherever `D=` has the manifest's sha, also compares the design repo at that sha. CI clones the public design repo (ledger D-24) and runs both halves.
  - `make lore-values` (`sim/tools/lore_values.ail`): the check-value registry `data/lore/check_values.json`: the 112 HB and 23 RS rows as printed, 17 `pkg:<function>(<args>)` values evaluated from `sunholo/relativity` 0.8.0, and `m4:glow_eps` / `m4:glow_f_in` / `m4:glow_099`. It fails unless each package value equals its HB row at the row's printed significant figures (HB-16, 17, 18, 19, 35, 36, 40 to 43, 45, 46, 49, 50, 53, 54, 61) and `m4:glow_eps` <= HB-61.
  - `make lore-check` (`sim/tools/lore.ail`, `lore_check.ail`; strict VM = interpreter): valid front matter, a known unlock hint, every `checks` id resolved, and every number in the title and body bound to a listed row by its shown significant figures and the README's textual unit aliases. A number needing numeric conversion does not bind. Exact decimal-string rounding, no floats. `LORE=<file|dir>` checks that instead: `tests/fixtures/lore/drifted.md` (one number off in its last digit) exits non-zero, as do fixtures with an unknown hint, an unresolvable id, an unlisted check and a wrong unit.
  - The Archive's third tab (`ui/archive/codex.tscn`, `interior/lore_loader.gd`, `ui/archive/lore_binding.gd`): locked entries greyed, a Markdown subset into a `RichTextLabel`, an unlock toast per batch. Unlocks come only from the sim's `consequence.archive.unlocked`; the panel has no way to unlock. The loader refuses any file whose sha256 differs from the manifest, and `LoreBinding` hash-compares the shown body with the imported entry. `SimBridge.archive_rows` (opt-in) carries the table in `new_game`; the interior run sets it, so every existing replay is unchanged.
  - `make lore-test` and `make codex-test` (both in `make test`): the real sim's minimum path unlocks the seven entries of `tests/expected_unlocks.json` in order; `archive.cmb-forward` stays locked at gamma 7.0888.

#### Not yet

- Two numbers in the vendored `archive.photon-drive` do not bind: `2.379 × 10¹⁷ J` and `6.520 × 10¹⁷ J` are per kilogram of effective mass in HB-35 and HB-36 (unit J/kg), and the prose says J. They are listed with a reason in `data/lore/unbound.txt` (an allowance that stops matching is itself an error). The fix belongs in the design repo: a J row, or "per kilogram" in the prose with a J/kg binding rule.
- Registry source (c), `tests/test_physics.gd`'s `CHECKS`, is not wired: that file has no such table.

## v0.4.0-dev.14-manual-sky (2026-10-05)

### Manual sky exposure correction, 2026-10-05

- Remove automatic exposure changes from the current ship demo, following laptop review. Camera motion, bright planets and nearby stars no longer dim the background automatically. Keep physical source brightness and SR calculations unchanged; manual brightness settings control the display.
- Withdraw dev13 as the default private download after its unresolved-star anticipation caused missing starfields. Retain dev12 as the fallback until the manual-exposure replacement is visually verified.
- Initialize the tour camera from the new session heading, removing a one-frame old-heading jump. Ease guided departure time compression over three seconds so nearby planets do not leap on the first compressed tick; simulation motion and ordinary navigation remain unchanged.

## v0.4.0-dev.13-stable-sky (2026-10-05)

### Laptop sky and approach follow-up, 2026-10-05

- Meter the final shared camera view rather than temporary simulation headings, preventing Earth/Jupiter and Sun exposure from alternating between updates. Interactive brightness adaptation is a labelled display policy; fixed EV and physical reference paths stay explicit.
- Set the guided tour to 1 g so braking starts farther out, then give approaches 90 wall seconds with progressively less time compression near arrival. Ordinary map sessions retain their acceleration and pacing.
- Add measured Alpha Centauri A/B radii and temperatures, continuous exact-ID rendering and star inspection, and a final moving-A intercept at 1 AU after the system stand-off. Binary motion uses the existing package orbit/light-time functions; the stellar surface is a uniform emitter.

## v0.4.0-dev.12-close-tour (2026-10-05)

### Solar departure and moody ship review, 2026-10-05

- Increase collision-safe walking to 3.5 m/s and restore warm internal light, cool fill and geometry shadows on the painted ship. Retain the movable camera and shared observer; simulation-driven external ship sunlight remains pending.
- Add a guided Earth → Jupiter → Saturn → Alpha Centauri journey with actual acceleration, cruise, braking and continuous positions/clocks. Planet stops are inertial; Earth uses the Earth–Moon barycentre approximation.
- Render moving planet discs and Saturn rings through package-backed inverse aberration, radiometry and shared metering. Opaque planet faces also mask known-star inspection.
- Start subsequent map routes from the current ship endpoint; add recenter/fit controls and honest surveyed-catalogue coverage.
- Publish selected native lighting, planet-stop, outbound and navigation screenshots in the gallery. M2 Air performance and further ship art remain pending.

### close-tour (2026-10-05)

#### Close Solar review and continuous presentation

- Bring Earth/Jupiter to two measured radii, add a bounded three-radius Sun stop,
  and use Callisto as a real collision-safe clearance leg before close Saturn.
  Keep Alpha Centauri's surveyed point and existing 1000 AU endpoint.
- Turn smoothly at stationary stops and before departure with both clocks held;
  ship geometry and sky share the observer. Moving legs retain the existing
  forward-pole attitude without teleporting or a braking turnover flip.
- Cache planetary preparation, warm existing textures, bound moving disc draws
  and blend point/disc contributions continuously with physical occultation.
  Moon records persist through braking, arrival and stationary epochs.
- Restore the painted bridge's actual +82 m floor top and lift opening, retaining
  all prior meshes, pigments and unchanged WALK files. Add a grounded invisible
  human shadow volume for the painted captain, including first-person views.
- B keeps its complete local audit and automatically uploads a filtered public
  summary using the authenticated Cloud CLI. Show a link only after success;
  preserve local fallback, fix forward-dome pose and count-statistic units.

This review retains fixed internal lighting. External stellar illumination,
thermal hazards, gravity-bound orbits, resolved Alpha Centauri detail and GR
remain unfinished. New-build M2 Air performance needs a fresh laptop audit.

- Exported first-launch simulation compilation has a bounded30-second bootstrap
  handshake allowance; editor/test launches retain five seconds and normal
  gameplay/AI request timeouts are unchanged. Clean-home validation caught the
  previous five-second first-install failure.

### m4.3a-transit-hud (2026-10-03)

#### Added

- The transit loop, time warp, HUD and arrival card on a sky-only harness, sprint R1-M4-JOURNEY M4.3a (design `m4-first-journey.md` §M4.3).
  - `bridge/transit.gd` (`Transit`): scheduling only. Docked, planning and arrived time runs at M2's host rate (no pause, D-12). Boost and brake each play over 3 s of real time by choosing and logging `dtau`; cruise sends the warp level (0.002 / **0.01 default** / 0.05 ship-yr/s) times the real step. No tick overshoots a phase, so the brake is always its own phase at any warp. The commit tick carries `dtau` 0.
  - Warp is a recorded intent `{"k":"warp","level":L}`: accepted by the sim only while committed (otherwise refused `not_committed`, which is also what a hand-sent warp before the commit or after arrival gets), `bad_intent` for any level but the three. It changes no sim state; the client chooses `dtau` and the input log replays the run.
  - `ui/display_binding.gd` (`DisplayBinding`): a label that is one sim field, formatted. `DisplayBinding.audit` is the positive control M4.5 runs: a numeric label that is not a binding, a binding with no field, or a binding whose text was set by hand is a violation.
  - `ui/journey_hud.tscn`: tau and t side by side at one size, `gap_years`, phase, beta (4 dp), gamma (3 dp), distance left, Earth-years to arrival, ISM load (W/m2 and suns), drag energy (J and kg), glow on/off, warp level, and a one-line brake notice. `ui/arrival_card.tscn`: distance, ship years, Earth years, gap. There is no turnover or flip event (D-11/D-14).
  - `ui/transit_harness.gd` and `godot --path . -- --transit`: the harness over the real sim; `run_session` is the scripted flight, recorded as `tests/replays/m4_transit_harness.ndjson` (VM == interpreter == golden).
  - `make transit-test` (in `make test`): warp intent, 3 s pacing at two boost lengths, the HUD fixtures and audit positive controls, the phase sequence, the arrival card, `standoff_au` 1000, and the AC3 grep half (`! grep -rniE "save_game|load_game|ResourceSaver" interior ui`).
- Protocol 2.2 (additive, minor 2 only): the `consequence` section gains `distance_remaining`, `earth_years_remaining`, `phase_remaining_yr`, `load_suns` (load / 1361 W/m2) and `drag_energy_kg` (drag energy / c^2), so Godot formats and never subtracts or divides. 2.0 and 2.1 streams and every existing golden are unchanged. `make strict` also runs `transitVm`.

#### Changed

- The M4 client sends `standoff_au` 1000 from one constant (`Transit.STANDOFF_AU`), used by `main.gd`'s interior run and the harness (M4.1 evaluation finding 4). `--map` alone still starts at the sim default of 0.

#### Not yet

- The x86_64 golden for `m4_transit_harness` (a sha256 digest) has to be recorded on CI (`make replay-record LOG=tests/replays/m4_transit_harness.ndjson` on x86_64), as for every earlier replay (ailang#1465). Only the arm64 golden is committed.
- The harness draws no sky; the HUD moves into the interior with M4.3b.

### glow-blackbody (2026-10-03)

#### Changed

- **The forward glow is a blackbody at the impact temperature, and its wall efficiency is
  ε = 1e-10.** These are ledger D-30, D-29 and Mark's follow-up to D-29 (attended 2026-10-03);
  the canon is stapledons-design `physics/higgs-bubble.md` §6, rows HB-95 to HB-112.
  - **Package pin.** `sunholo/relativity` goes from 0.7.0 to 0.8.0, in both `sim/` and
    `tools/glow_probe/`.
  - **M4.1 step 2 (the sim's pole values).** The sim now emits `ship.ism.glow_pole_w_m2`, which is
    `glowEmittanceAt(…, 1)`, and `ship.ism.glow_pole_k`, which is `glowTemperatureAt(…, 1)`.
    The temperature is (K/σ)^¼ and does not depend on ε.
  - **New default ε.** `glowEps` defaults to 1e-10; it was 1e-9 under D-15, and it is still a
    scenario parameter that the sim echoes.
    - At 0.99c the glow pole is 1.65e-3 of the dark sky.
    - It becomes visible, at 0.3 of the dark sky, from about 0.997c.
    - At the cap it is 1.56 cd/m².
  - **Godot mirrors the package instead of the placeholder.** `interior/forward_glow.gd` drops
    the equal-energy white (182.6 lm/W) and mirrors the package:
    - `temperature` is T_pole·cos^¼θ;
    - `efficacy` is luminousEfficacy;
    - `luminance` is radiance × efficacy;
    - `colour` is rgbUnitLuminance.

    The shader reads T and efficacy from Blackbody's existing colour lookup (`efficacy_lut`,
    `colour_lut`), which is finite and tested over 1e-3 K to 1e9 K.
  - **Goldens.** G-M4-4 (d) now checks the blackbody chain at 0.999c and at the cap. The new
    G-M4-6 compares the GPU colour ramp against the CPU at 10 temperatures. The worst
    difference is 0.07 %.
  - **ε comparison sheet.** `make glow-eps-sheet` renders the bridge interior and the forward
    sky at 0.99c, 0.995c, 0.999c, 0.9999c and the cap, for each candidate ε, through the eye
    exposure. It writes the measured star counts, limiting magnitudes and EV shifts. The
    published copy is `gs://stapledons-voyage-assets/refs/glow/eps_compare.jpg`.
  - **Review captures.** The M4.2 captures no longer use the probe's "glow preview" poles,
    because the sim now owns the glow values.

The blackbody spectrum is the canon’s labelled game stand-in for the impact
cascade, not a claim that real GeV cascades yield Planck radiation. Plate
projection retains G-M4-5; the combined spectral colour ramp is G-M4-6.

## v0.4.0-dev.10-unified-painted-ship (2026-10-05)

### One current ship and known-star identification, 2026-10-05

- Normal launch opens one current expanded ship at the captain’s measured eye, with live navigation at rest. Scrolling reveals a labelled third-person view. Original painted/capture modes remain explicit reference tools.
- Add genuine UV-painted bridge surfaces and packed editable Blender masters; preserve exact geometry, walk meshes and the existing Commons paint. This first texture interpretation remains open for art review.
- In the current ship, hold I to highlight known visible stars, hover for a name and click for catalogue facts. The details card persists after release; Esc closes it. Overlapping sources offer individual choices.
- Open the same exact catalogue ID in navigation explicitly. Inspection leaves the running voyage and irreversible commitment unchanged.
- Carry producer IDs through the sky renderer, and place highlights on apparent star directions while respecting opaque ship geometry. Catalogue distance is labelled from Sol; unavailable fields remain unavailable.

## v0.4.0-dev.9-commons-live-journey (2026-10-04)

### Open Commons arcade and live journey review, 2026-10-04

- Replace the generic pavilion with the first section of the approved Commons layout: an open curved arcade, planted plaza and guarded walking link. This remains a bounded prototype; other districts and final painting are still to come.
- Committed review journeys now show actual simulation acceleration, coast and braking aboard ship, with about 20 seconds per phase using labelled time compression. Navigation remains reachable at laptop window sizes.
- Refresh the bundled simulation cache when its contents change, including nested modules, so updates do not reuse an older simulation.
- Retain 4× exposure. Target MacBook Air performance remains to be measured.

## v0.4.0-dev.8-commons-review-4x (2026-10-04)

### Commons architectural review and 4× default, 2026-10-04

- Set the review demo sky exposure to 4× by default, as requested; physical sky inputs remain unchanged.
- Record that the generic pavilion is a prototype, not a faithful build of the approved Commons concept. Add an unbuilt zoning proposal and finish-only paint study for review before replacing its architecture.

## v0.4.0-dev.7-commons-exposure-trial (2026-10-04)

### Commons expansion and exposure trial, 2026-10-04

- Add reusable planted terrace canopy, seating, reading tables and pavilion details within the current playable Commons.
- Trial labelled sky exposure at baseline,2×,4×,16× and64× (default2×), with physical sky inputs unchanged. J cycles settings.
- Preserve the sky meter while turning the camera; record the active exposure in captures and benchmarks.

## v0.4.0-dev.6-commons-sky-review (2026-10-04)

### Commons and journey sky review, 2026-10-04

- Add the first painted Commons pavilion and courtyard, with collision, lift access and a coarse distance model.
- Open the ship review in an actual frozen 0.99c simulation snapshot, with rest and forward/side/aft comparisons.
- Include native export checks and five-view profiling. MacBook Air performance remains pending.

## v0.4.0-dev.4-ship-geometry-review (2026-10-04)

### Seven-tier geometry review demo,2026-10-04

- Trackpad controls: Option plus one-finger movement looks without a held click; two-finger scrolling zooms. Mouse right-drag and wheel still work. Whole-ship zoom keeps its overview, with zoom disabled during lift travel and benchmark sampling.
- Separate review window preserves the running voyage. One perspective observer aligns native bridge geometry, lower tiers and the existing live star/sky renderer; opaque floor/rail occlusion is preserved. GR remains unimplemented.
- Demo-only guarded lift openings support a physical25m descent to the first tier, a bounded landing walk and return with separate active WALK regions. Production bridge art stays unchanged.
- In-app1920×1080 benchmark and packaged smoke checks added. StudioM4Max frame-time p95 measured26–29ms in this run; this does not meet the proposed60fps budget and does not establish MacBookAirM2 performance. Actual target-laptop measurements remain pending.

### sky-mirror-fix (2026-10-03)

#### Fixed

- **The M1 sky was a mirror image of the real sky (D-28, Mark, attended 2026-10-03).** The
  galactic → Godot map `(x, y, z) → (y, z, −x)` had determinant −1, a reflection. Stars, the
  NOIRLab panorama, the sky model, the forward CMB and the galaxy map all rendered left-right
  reversed. The GPU-vs-CPU goldens could not see it because both sides shared the map; the
  M4.2 evaluation found it, and M4.2 had undone it locally with `SKY_FLIP_H`.
  - One right-handed map, `(x, y, z) → (−y, z, −x)` (det +1), and its inverse
    `(x, y, z) → (−z, −x, y)`, are now defined once: `sky/sky_frame.gd` (`SkyFrame`, Vector3
    and float64 forms) and `sky/sky_frame.gdshaderinc` for shaders. The hand copies in
    `starfield.gd`, `sky_model.gd`, `background.gdshader`, `interior_sky.gd` (three),
    `interior_smoke.gd`, `interior_golden.gd` (two), `main.gd` and `test_physics.gd` (two)
    are gone. `Starfield.galactic_to_world` keeps its name and now calls `SkyFrame.to_world`;
    `Starfield.world_to_galactic` is new.
  - The interior's local flip is removed: no `Interior.SKY_FLIP_H`, the sky texture is shown
    as rendered, and G-M4-2 / G-M4-4(c) no longer mirror columns. G-M4-1..4 pass without it.
  - Views: facing the galactic centre with the north galactic pole up, **starboard (KEY_2,
    yaw −90°) now looks at l 270** (Vela, Canopus, α Cen, the LMC) and **port (yaw +90°) at
    l 90** (Cygnus), as on a real ship. The yaw sign and the KEY_1–4 bindings were already
    right; only what the sky put there was mirrored. The named yaws are `main.gd`
    `VIEW_YAW`.
  - The galaxy map is now the real neighbourhood, not its reflection: seen from the NGP side,
    longitude turns counter-clockwise.
- New tests: `make physics` `test_sky_frame` (det +1, round trips, the shader include
  evaluated against `SkyFrame`, a guard that fails on any hand copy of the map, and an oracle
  of real objects through the free-look camera: Antares and α Cen right of the centre, Vega
  and the Scutum cloud left, Orion's belt Alnitak–Alnilam–Mintaka left to right, the LMC
  right of and below Acrux, the starboard/port/astern longitudes, and the LMC and SMC bright in
  the NOIRLab panorama where the frame puts them, 9.4x and 6.9x their mirror positions);
  `make ui` `test_handedness` (galaxy map); `make interior-test` (no flip, det +1).
- `bridge/sim_bridge.gd` declared `want_minor` twice after merging #101 and #102, so `main.gd`
  failed to parse on main; the second declaration is removed.
- Regenerated reference renders: `docs/m1.3`, `docs/m1.6b`, `docs/m1.8`, `docs/m1.7`,
  `docs/m2.6a`, `docs/m2.6b` (images), `docs/contact_sheet.png`, `docs/sky_b099_forward.png`;
  before/after sheets in `docs/d28-sky-frame/`. The stand-off golden uses the mirror of its old
  geometry, which keeps the 0.4 AU case's power (float32 from Sol: 8.17 / 1.90 px, ≥ 1.5 px).

### planet-bundle (2026-10-03)

#### Added

- Planet textures ship in exported builds. `make planet-bundle` fetches the pinned Solar System Scope textures (bucket, else source), checks them against `data/planets/SHA256SUMS`, and stages them as `planet_bundle/<file>.bin`. `make export-macos` (and so the release workflow and `make publish-dev`) depends on it, and the build FAILS if any texture is missing. The export filter now carries `planet_bundle/*` and `data/planets/*` (ALBEDO, CREDITS).
- `SystemView.load_texture_image` reads `assets/planets` in a source checkout and the bundle in an export.
- `--planet-smoke=PNG` (`planets/planet_smoke.gd`) and `make export-smoke-planets` (run by `make publish-dev`): the exported app must load all nine textures from its bundle and draw a textured Jupiter.
- `tests/test_planets.gd` checks the export filter and that a bundled copy decodes like the source.

### m5-system-data (2026-10-03)

#### Added

- Sol and α Centauri as cited AILANG data, sprint R1-M5-PLANETS M5.1a (design `m5-planets.md` §M5.1, §M5.7). Both modules are pure and load on the strict VM.
  - `sim/data/sol.ail` covers the Sun, the 8 planets and the 12 moons named in the design, plus ring profiles for all four giants. The sources are:
    - Standish Table 2a/2b elements and rates;
    - the IAU WGCCRE 2015 poles, W and radii (from NAIF `pck00011.tpc`, including the periodic terms);
    - DE440 GMs;
    - Mallama 2017 p_V;
    - Minnaert k from Binder & McCarthy 1973 for Jupiter and Saturn, with Lambert assumed for the rest;
    - JPL SSD satellite mean elements;
    - NSSDC satellite albedos.

    The ring profiles are `[(r_in, r_out, tau, w0)]` bands with a tint, taken from PDS Rings Node (Saturn) and NSSDC (the others). Every row carries citation keys that resolve in `citations()`.
  - `sim/data/acen.ail` holds the AB orbit (Akeson 2021), Proxima b and d (confirmed in the NASA Exoplanet Archive snapshot of 2026-10-03), Proxima c (candidate; P and a as adopted by Kervella 2020) and α Cen A b (candidate, from one of Beichman 2025's four orbit families). Every number records its provenance: `measured`, `inferred` (the relation is named) or `assumed` (with the reason). No retracted row (α Cen B b) is loaded.
  - `sim/celestial_test.ail` holds the provenance half of AC6, 22 checks in all. They cover:
    - citation keys;
    - NSSDC orbit periods, obliquities and rotation periods;
    - each moon's return after its published sidereal period, which catches a misread JPL `P` column or a wrong rate sign;
    - synchronous rotation;
    - Kepler's third law for planets and moons, NSSDC eccentricities and masses, albedos in (0, 1], and node directions;
    - ring structure including the Encke gap, the design-repo ring table where it agrees, and the published edges beyond it (its Uranus row is wrong: 1.637-2.002 R);
    - α Cen status and provenance, Kepler's third law for AB, and the recomputed inferred radii.
  - `make strict-m5` (in the new `mk/m5.mk`, part of `make test`) checks that the strict VM, the interpreter and `sol-data-ok` all agree. `make acen-snapshot` fetches the archive rows, and `make acen-snapshot-verify` checks them against `data/planets/EXOPLANETS.SHA256`.

#### Changed

- `sim/ailang.toml` now pins `sunholo/relativity` 0.7.0, which carries M4.6a's `glowEmittanceAt` and M5.0b's `apparentDisc`, `angleSeen` and `hoverPower`. It also adds `sunholo/celestial` 0.1.0. The pin is its own commit, and the lockfile and bundled cache move with it.

### m5-system-at (2026-10-03)

#### Added

- `sim/celestial.ail` (sprint R1-M5-PLANETS M5.1b, design `m5-planets.md` §M5.1) works out where Sol's bodies are seen from the ship, and how bright they are. The module is pure and clean under `--strict-bytecode`. It only composes `sunholo/celestial` 0.1.0 and `sunholo/relativity` 0.7.0 functions with the cited rows in `sim/data/sol.ail`.
  - `bodyAt(sys, id, jd)` returns a body's position and velocity in the galactic frame (km and km/s, float64), plus its pole and W.
  - `systemAt(sys, jd, shipLy)` returns the Sun, the 8 planets and the 12 moons with every design field: `rel_km` at the retarded time (from `lighttime.retarded`, computed in the galactic frame), `radius_km`, `flattening`, `pole`, `w_deg`, `sun_dir`, `r_au`, `phase_deg`, `e_v_lux` (from `discIlluminance` with relativity's `illuminanceFromV(-26.74)`), `p_v`, `minnaert_k`, `ring_id`, `light_age_s`, `visitable`, `source`, `status` and `host`.
  - The time base is `system.jd = epoch_jd + t × 365.25`. Outside Standish's window (3000 BC to 3000 AD) the section reports `ephemeris: "mean-orbit"`.
- Protocol 2.3 adds the `system` section. A client that asks for minor ≥ 3 gets `system{jd, ephemeris, frame: "galactic", bodies}`. It comes in the full state and on every tick that moves the clock or the ship; a tick that moves neither has no `system` section. Clients at minor 2 and below see exactly the stream they saw before. The new scenario parameter `epoch_jd` (default J2000, |v| ≤ 1e9) sets the epoch. It isn't echoed in `params`, which follows the `standoff_au` precedent. `decodeSystem` is `encodeSystem`'s inverse.
- `SimBridge` has two new members. `want_minor` lets a client opt in to minor 3 (`SYSTEM_MINOR`); the default stays 1. `system` holds the last section, checked field by field by `SimBridge.parse_system`.
- `tests/fixtures/system_sol.ndjson` is the sim's own output for a short session at minor 3. M5.2a can start from it before it has a live sim.
- New tests:
  - `celestial_test.ail` checks that positions equal `stateFromElements ∘ eclipticToGalactic` to 1e-12 AU, and that Jupiter's light time at the 2023 opposition equals `lightTimeDays` to 1e-6 s (about 1,986 s).
  - It also checks: the retarded offset (about 26,000 km); the pole and W at the retarded time; the mean-orbit label; the time base; Jupiter at V −2.9; the Sun's illuminance; and that every field is finite, including with the ship inside the Sun.
  - `protocol_test.ail` adds handshake, wire, `epoch_jd` and round-trip checks, as additions only.
  - `test_sim_bridge.gd` adds a live session at minor 3 and checks the fixture.
- `make strict-m5` now also runs `systemVm`, which must print the same bytes on the strict VM and the interpreter. `make parity-v2-system` checks the 2.3 tail of `tests/fixtures/v2_session.ndjson`.

#### Changed

- `Params` gains `epochJd`, and `core.ail` changes by 7 lines.

### m5-globes (2026-10-03)

#### Added

- Planets and the Sun on screen (sprint R1-M5-PLANETS M5.2a, design `m5-planets.md` §M5.2), fed only by the sim's protocol 2.3 `system` section:
  - `planets/system_view.gd` (`SystemView`): a body under 2 px across becomes a starfield point (its `e_v_lux`, the solar colour 5,772 K), so the stars' aberration, band-ratio Doppler and PSF apply unchanged; at 2 px or more it is a disc. Bodies far below the naked-eye threshold and under 0.1 px are culled in Godot, not in the sim.
  - `planets/planet.gdshader`: an exact ray-traced sphere on a camera-facing quad, Minnaert/Lambert lit (mirroring `sunholo/celestial` `reflect.minnaertRadiance`), supersampled per pixel so the pixel sum is the disc integral even at 2 px, and pre-exposed by `Exposure.k` (one tonemap). The Sun is a limb-darkened (u = 0.6), flux-normalised disc, clipped at linear 1,024 until row 6b's glare pass.
  - Placement keeps gate 5: direction and asin(R/d) in float64, each disc drawn 10 units out with its radius scaled by 10/d, so no raw km value enters a `Vector3`. Directions use `Starfield.galactic_to_world`, the stars' own axis map.
  - `physics/planets.gd` (`Planets`): the CPU mirror of `starIlluminanceAt`, `lambertPhase`, `lambertRadiance`, `minnaertRadiance`, `rhoFromGeometricAlbedo`, `minnaertPhase` (Simpson 256, same operations), `phaseFunction` and `discIlluminance`, plus placement and the IAU body frame (pole, W from the node on the ICRF equator).
  - `Starfield.add_point_sources` / `clear_point_sources`: a second MultiMesh sharing the star quad (and so every star uniform).
- Planet textures: Solar System Scope 2k (CC BY 4.0), ten files, about 5 MB, pinned by sha256 in `data/planets/SHA256SUMS` with attribution in `data/planets/CREDITS`. `make planet-assets` fetches them into the gitignored `assets/planets/` from `gs://stapledons-voyage-assets/planets/`, falling back to the source; `make planet-publish` uploads (maintainers, after Mark's licence check L-tex).
  - `tools/planet_textures.gd` writes `data/planets/ALBEDO`, each texture's disc-integrated mean luminance for the body's Minnaert k, so the disc-integrated albedo on screen is the sim's p_V; `-- --check` verifies it independently (a ray-sampled disc at 12 longitudes) within 1%. Earth composites its cloud map over the day map.
- `main.gd`: interactive sky flights ask the sim for minor 3 and draw the system; `--golden-m5` and `--capture-m5=DIR` run the M5 goldens and reference renders (`tools/m5_golden.gd`). Captures, goldens and the bench keep their M1 output.
- Gate 2:
  - `make physics` (`_m5_photometry`): the mirror equals the package's probe values (`sim/tools/planets_probe.ail`) within 1e-12 relative; the disc integral of the drawn radiance equals `discIlluminance`.
  - `make planets-test` (in `make test`): `SystemView` on the recorded Sol section, the point/disc switch at 1.9 and 2.1 px, placement precision, the albedo table against the sim's k and the pins.
  - `make golden` / `make golden-m5`: G-M5-4 (Jupiter at opposition: integrated illuminance = `discIlluminance` within 2%, centroid within 0.75 px, extent = the pinhole diameter within 1 px) and G-M5-6 (1.9 px point vs 2.1 px disc, flux within 2%). M1's golden counts are unchanged.
  - `make capture-m5a` writes `renders/m5/m5.2a/`.
  - `make lint-precision` (`lint-precision-m5` until M4.6's lint lands): no hand-computed γ or 1 − β in the planet renderer.
- In-game credits (Mark, L-tex, 2026-10-03: the CC BY credit must be displayed): `ui/credits.gd`, a small "C  credits" hint whose panel lists the planet textures (Solar System Scope, CC BY 4.0), the NOIRLab panorama, the star catalogues and the engine, on the galaxy map and in the sky flight. The same line is on the website's Credits page and in the release notes. The textures are published to `gs://stapledons-voyage-assets/planets/`.
- Planet directions use D-28's `SkyFrame` (the real, unmirrored sky).

### m5-body-targets (2026-10-03)

#### Added

- `sim/navigation.ail` (sprint R1-M5-PLANETS M5.5a, design `m5-planets.md` §M5.5) plans a leg to a planet or moon. The module is pure and clean under `--strict-bytecode`. It composes `bodyAt` (from `sim/celestial.ail`) with relativity's `planBurnCoastBurn`, `motionAt` and `doppler`; it adds no physics formula.
  - **Body targets.** The plan intent gains a body form, `target: {kind: "body", id}`. The sim computes the arrival point itself and never reads a client `pos` or `index`. The stored plan's `target.index` is the body's place in `system.bodies` and its `target.pos` is the arrival point.
  - **Stop.** The ship arrives `standoff_km` from the body's centre at the arrival time. The default stand-off is max(10 R, 1.5 × the outer ring); values above 0.1 AU are clamped.
  - **Flyby.** The ship passes at exactly `b_km` on the side `clock_deg` (0 = the body's north, 90 = right of it as seen from the ship). It is one burn-coast-burn through the pass point to a stop `run_out_km` beyond it (default: the braking distance + 10⁶ km). The plan reports β and D at the pass.
  - **Intercept.** The arrival or pass time is iterated 12 fixed times; the plan carries the residual, and a plan whose residual is 1e-9 of the leg or more is refused `no_converge`.
  - **Refusals:** `not_visitable` (the α Cen worlds, the Sun, unknown ids), `out_of_range`, `too_close` (below 1.1 R + the bubble radius), `no_converge`, `collision` (within R + bubble of any body), `ring_crossing` (through a ring plane inside the outer ring), and `committed` (M2's rule).
- Protocol 2.4. A client that asks for minor ≥ 4 may send body plans. A body plan's `journey.plan` adds `target_kind`, `intercept{t, pos}`, and `pass{t, b_km, beta, d_at_pass}` (flyby) or `hold{body, offset_km}` (stop). Below minor 4 a body plan is `bad_intent`. Star plans and every stream at minor 3 and below are unchanged, byte for byte.
- `SimBridge` gains `NAV_MINOR`, `body_plan(id, cruise_phi, approach)`, `parse_plan_nav` and `plan_nav`. `tests/fixtures/nav_session.ndjson` is the sim's own 2.4 output (a Saturn flyby, a Mars stop and a commit).
- `make strict-m5` now also runs `navigationVm`, which must print the same bytes on the strict VM and the interpreter. `make hello-pin` checks that the 2.4 hello's relativity version equals the pin in `sim/ailang.toml`.
- New tests: `sim/navigation_test.ail` (18 checks: AC14, AC15, AC17's residual half, the iteration count, the clock convention, commit staleness, the 2.4 wire and codec), plus `celestial_test.ail`'s retarded `sun_dir`/`r_au`/`phase_deg` check and two live bridge tests.

#### Changed

- `core.ail` dispatches the body form to `sim/navigation.ail` (34 lines added). `Plan` gains `nav` (`None` for a star plan). A body plan goes stale at commit once the Earth clock has moved.
- Home is now the target id `"Sol"`, not catalogue index 0. The map's index 0 is Proxima Centauri, which therefore got no M4 stand-off (M4.2 finding). `standoffFor` takes the id.
- `protocolVm` now runs the four 2.3 checks on the strict VM too.
- From minor 4 the hello reports the pinned relativity release (0.7.0). Minors 0 to 3 keep the old string, "0.4.0", so that every recorded stream and golden stays byte-identical.
- Documented: the star's `sun_dir` is the zero vector (`celestial.ail`, the protocol notes, the bridge).
- Design `m5-planets.md` §M5.1 now matches the landed M5.1b: `systemAt(sys, jd, shipLy)`, `kind` and `ring_id`, `SimBridge.system`, and the Sun at 1.2706e5 lux. §M5.5 records the choices M5.5a made. In the sprint plan, M5.5b and M5.7 now depend on celestial 0.1.1 (the Earth-Moon barycentre split).

## v0.4.0-dev.1 (2026-10-03)

### Companion stars take their system's distance, 2026-10-03 (Mark's ruling; M1.7 evaluation follow-ups)

- **Companion rule** (`sim/tools/companions.ail`, design
  `design_docs/planned/r1/m1-companion-parallax.md`): a star within 60″ and
  2,000 AU of a brighter star, with parallaxes within 20% (and 5% or 3σ) and
  proper motions within the orbital bound, takes the system root's parallax.
  `make companions` writes `data/starmap/companions/companions.csv` (20,515 companions over
  CNS5 + GCNS + the bright tier; 9 cross-identifications, e.g. GJ 10136 = CNS5:252,
  dropped as the same star); every tier and `stars.json` apply it, the GCNS tiers move
  CNS5-record roots with their companions, and every build refuses a split pair. Sirius B
  now 8.601 ly (was 8.709), Luyten 726-8 B 8.817 (was 8.724), Wolf 424 B 14.112
  (was 14.593). α Cen B is the old rule (c) case: its bytes are unchanged;
  `bright_overrides.json` is retired. No primary row moves in quick, bright or the map; every non-companion
  row is byte-identical (the GCNS tiers also move 488 root rows).
- **Tests:** `make companions-test` (thresholds just inside/outside, real-line
  fixtures, strict VM = interpreter); `tools/check_companions.py` (oracle) in
  `make catalogue-verify`.
- **`make catalogue-verify` green again:** tier sidecars regenerated on v0.52.0 /
  relativity 0.5.2 (they still said v0.51.0 / 0.5.1 after the bump).
- **`tools/check_star_names.py`:** negative controls for direction (5°),
  distance (10%) and a name row repeated.
- **Galaxy map labels** skip a name whose box overlaps a drawn label;
  `docs/m1.7/destar_before_after.png` labelled before/after.

### showcase-site (2026-10-03)

#### Added

- Showcase website in `website/` (Docusaurus 3.10.2, AILANG family theme), for
  https://www.sunholo.com/stapledons-godot/: landing page with real captures, gallery, and pages on
  the game, the physics, the Higgs bubble, the AILANG architecture, the roadmap, trying it and
  credits. `make site`, `make site-serve`, `make site-deploy` (temporary clone of `gh-pages`, no
  worktree; `DRY=1` stops before the push). Publishing and the Pages setting are the owner's call.
- Website clips are frame-exact captures: `tools/site_movie.gd` behind `main.gd --movie=CLIP`
  (`hero`, `voyage`, `lookaround`, `cmb`) and `--map --movie=map`; `tools/site_media.sh` renders,
  encodes (MP4 + WebM + posters) and publishes them content-addressed to
  `gs://stapledons-voyage-assets/site/` (`make site-media`, `make site-media-publish`).
  `--movie` is an automation flag, so a clip never starts live AI.

### photometric-exposure (2026-10-03)

#### Added

- M1.5a photometric exposure (F5, Q8/D-19). Scene units are physical: stars carry E_v in lux
  and the background is in cd/m², calibrated so the panorama's dark-sky patch (median of the
  galactic caps, |b| ≥ 70°) reads 23.5 mag/arcsec², the deep-space value (D-25: integrated starlight, diffuse galactic light and EBL; no airglow or zodiacal light; Leinert et al. 1998), through `luminanceFromSurfaceMag`.
  `sky/exposure.gd` maps luminance to pixels with an EV100 exposure
  (L_white = 1.2 × 2^EV). It has two metering modes. **Eye** is the default: dark-adapted
  at EV_dark, where a star at the Crumey naked-eye threshold (`pointThresholdIlluminance`,
  field factor 2) lands on the display's lowest visible level. AC8 measures V_lim 6.9 against Crumey's 6.897; the window is 6.6–7.4. The eye light-adapts only
  when the log-average meter asks for less sensitivity. **Camera** is labelled: log-average
  metering, K = 12.5.
- Exposure honesty: the HUD shows the EV and the metering mode. **F** locks a fixed EV at the
  rest value and **M** switches eye/camera. In eye mode the HUD says "pinned at EV_dark" or "light-adapted", never "auto". The default camera EV clamp floor is −14 (ISO 102400, f/1.4, 30 s). The readability aids are off by default and
  labelled on the HUD when on: **[ ]** for exposure bias, **G** for a magnitude floor (V 8).
  The same controls exist as flags: `--exposure`, `--fixed-ev`, `--ev-bias`, `--ev-clamp`
  and `--mag-floor`.
- GDScript mirrors of `luminanceFromSurfaceMag`, `pointThresholdIlluminance`,
  `limitingMagnitude` and `vFromIlluminance` (sunholo/relativity 0.5.x), with package values
  in `make physics`.
- `make physics`: scene-unit tests and the corrected-F5 sideways-darker test. At θ′ = 90° and
  0.99c, D = 1/γ, and both the sky patch and an isotropic starfield patch read below the
  rest frame. The patch at θ′ = 8.1° (D = γ) is brighter, and the D = 1 boundary is at 29.83°.
- `make golden`: the display floor of the production chain, a known-lux star integrating to
  E·k/Ω_px within 1%, the calibrated sky reading L(23.5) within 1%, and the AC8
  limiting-magnitude ladder (V 5.0–8.5, measured in the rendered frame).
  `make bench` prints the AC8 limiting magnitude at 2560×1440.
- `make capture`: starboard pairs at rest and at 0.99c in camera mode, auto-exposed and at a
  fixed EV, beside the default eye view (`*_camera_auto.png`, `*_camera_fixed.png`,
  `exposure_sheet.png`).

#### Changed

- `EXPOSURE` and `BG_EXPOSURE` are gone from `main.gd`; the goldens use a named `GOLDEN_PEAK`.
- The sky background un-stretches the panorama's luminance with one power law that keeps
  chromaticity, anchored at the dark patch (23.5 mag/arcsec²) and the photo's 99.9th-percentile
  luminance (20.8 mag/arcsec², the brightest Milky Way; D-25, Leinert 1998 Table 16, Duriscoe 2013). The
  NOIRLab photo is tone-stretched: its peak is about 290× its dark patch. With a purely linear
  calibration the Milky Way read about 6 mag too bright and buried the stars. The fitted
  exponent is 0.43; uniform (golden) panoramas keep 1.

### m4.2-interior (2026-10-03)

#### Added

- **The bridge interior with the live sky (M4.2, R1-M4-JOURNEY).** A plain launch (`make run`,
  a double-clicked review build) now opens on the bridge: `interior/interior.gd` composites
  five layers from the area bundle, far to near: the M1 sky (`interior/interior_sky.gd`, its
  own HDR `SubViewport`), the panorama (pan 0.15), the play GLB (toon + ink, pan 1, its own
  transparent `SubViewport`), the foreground (pan 1.6) and the HUD.
  - **One tonemap:** only the sky `SubViewport` tonemaps (AgX + the M1.5a photometric
    exposure). The main viewport has no environment or 3D of its own (G-M4-2).
  - **Sky camera** = `cam_<area>.json` × `ship_basis(heading)` (D-14: up is the direction of
    travel, no flip). Velocity, heading and position come from the sim only, on a protocol
    2.2 session with the 1,000 AU stand-off.
  - **Plate parallax** is clamped at each plate's overscan. The camera follows the captain
    inside the bundle's pan range (new optional `pan_range_m`, else derived from the
    overscan), so the plates stay aligned with the set.
- **Forward glow overlay** (`interior/glow_overlay.gdshader`, CPU reference
  `interior/forward_glow.gd`). It is additive and drawn before the tonemap, and it traces each
  ray from the panorama camera to the bubble wall. The profile mirrors `glowEmittanceAt`
  (sunholo/relativity 0.7.0): pole × clamp(cos θ, 0, 1). The wall is Lambertian (E/π), and
  the efficacy is equal-energy white (182.57 lm/W, pending a spectrum ruling). The sky's one
  exposure converts it, with no gain. The overlay reads `ship.ism.glow_pole_w_m2` and stays
  off until the sim emits it (M4.1 step 2). The eye meter now sees the glow.
- **Walking and the captain.**
  - `interior/walk.gd` keeps the avatar on the bundle's `WALK_` triangles, with the agent
    radius, sliding along obstacles. Grid routes are used for scripted walks.
  - `interior/captain_avatar.gd` is a billboard at 720 px/m with the feet on the anchor. The
    life stage follows ship years since departure, and facing (front or back) follows
    movement on screen.
  - Neither talks to the sim. `make m4-smoke` checks the recorded input log has no intents
    while walking.
- **Interactables:** a navigation console opens the M2 galaxy map, and the Archive terminal
  opens the Archive (news, legacy log, codex stub). Keys: E use, M map, L log, K codex, Esc.
- **AreaBundle (optional, typed, never required):**
  - `play_origin_ship_m` (`glb_to_ship`);
  - `pan_range_m`;
  - `layers.play.camera` (the isocam JSON);
  - `layers.play.plate {file}`, the bridge v2 hook: a projected illustrated plate under the
    play layer. The plates' `interior/plate.gdshader` carries a glow tint/rim term, a no-op
    until v2.
- **Export staging:** `make areas-stage` copies `assets/areas/<area>/` (which is
  `.gdignore`'d) to `areas_bundle/<area>/*.bin`, and `make export-macos` runs it.
  `make export-smoke` also runs the interior slice from inside the `.app`.
- **Targets:**
  - `make interior-test`, in `make test`;
  - `make m4-smoke [BUNDLE=dir]`, now real and in `make test`: on each bundle the captain
    walks to a console, the map commits alpha Cen A, and the sky follows the cruise to the
    arrival;
  - `make capture-m4`, the S1 review captures to `renders/m4/`;
  - `make glow-probe`, the check values from the package, VM = interpreter;
  - `make golden` gains G-M4-1 (72 composite cases, pan-invariant, ≤ 0.75 px), G-M4-2
    (≤ 1/255), G-M4-3 (forward pole, boost/cruise/brake on two headings) and G-M4-4 (glow
    profile and absolute pole ≤ 1 %, off-centre camera, photometric chain).

#### Changed

- `SimBridge.want_minor` (opt-in, default 1) lets the interior ask for protocol 2.2. Every
  other session, and the replay goldens, are unchanged.
- `make golden`'s summary check now also requires the M4.2 case counts.

### m4.0-area-bundles (2026-10-03)

#### Added

- **Area bundles (M4.0, R1-M4-JOURNEY).** `interior/area_bundle.gd` loads the ship-interior
  brief's §9 delivery format (`manifest.json`, `cam_`, `pano_`, `play_`, `fg_<area>`). It checks
  the manifest field for field against brief §9 (V17) and refuses a bundle with a missing layer,
  listing every problem. Unknown keys are kept, and an optional `placeholder` bool puts a
  "placeholder art" tag in the HUD. The images and the GLB load from the files at runtime, so
  swapping a bundle is a data drop (AC14).
- **`make validate-areas [BUNDLE=dir]`** (`tools/validate_area.gd`, Godot headless) checks:
  - the manifest and camera schema (the camera must use the ship-frame contract string);
  - plate size: each plate is the view plus 2 × its optional `overscan_px` (m4-2-requirements
    §4; the camera spans the whole panorama plate), and equals the camera resolution without
    overscan;
  - alpha: exactly-0 coverage, and no isolated specks (painted stars) or faint haze (painted
    nebula);
  - the foreground keeps the centre clear (measured on the pan-0 view region of an overscanned
    plate);
  - the camera round trip within 1 px, plus any declared `validation.needle_tip_pixel`, plus a
    check that the needle shows in the panorama at the projected pixel (its solid top 0–2.5 px
    above the tip, from the ink outline, and at most 0.5 px below);
  - the GLB is in metres with Y up, and has its `WALK_`, `SPAWN_` and `INTERACT_` nodes and any
    names the manifest lists.

  It runs in `make test` on the blockout fixture and on `assets/areas/bridge/`. `make area-test`
  holds the positive controls: each check must fail on a bundle broken in its way.
- **Blockout test fixture** `tests/fixtures/areas/bridge_blockout/`, copied from
  `origin/spike/iso-bridge` (4eda978). Its GLB gains a walk disc, two spawns and two `INTERACT_`
  stand-ins (`tools/build_blockout_fixture.gd`). `assets/areas/bridge/` holds the same blockout
  as `placeholder: true` until the bridge v1 bundle is approved.
- **Frame contract** `interior/ship_frame.gd` (float64): `ship_basis(heading)` sets ship +Z to the
  direction of travel, and that stays "up" for the whole journey, with no flip (D-14). Roll comes
  from the north galactic pole, falling back to galactic +X within 1e-6 of a pole.
  `make physics` checks:
  - the basis is orthonormal and right-handed to 1e-12 over 73 headings;
  - heading maps to +Z;
  - both pole fallbacks;
  - the sky camera mapping.
- `make m4-smoke` is a stub that fails until M4.2.

### m4-consequence (2026-10-03)

#### Added

- `sim/consequence.ail` and the consequence state in the world, sprint R1-M4-JOURNEY M4.1 (step 1; the design doc is `m4-first-journey.md` §M4.1). Pure, so it runs on the strict VM; I/O stays in `sim/ship.ail`.
  - Stand-off: the new scenario param `standoff_au` (default 0, so M2 plans are unchanged; the M4 client sends 1000) plans to `d - s` along the same heading, `s = 1000 AU = 0.0158125 ly`. Sol (star index 0) never has one, and a star inside the stand-off is `out_of_range`.
  - Displayed quantities as sim fields: `gap_years = t - tau`, `news_epoch = t - |p - Sol|`, `news_age_years`, `progress`. At rest the clock runs at the host rate and the gap does not change.
  - News at arrival: a tier (`<1`, `1-5`, `5-15`, `15-50`, `>=50` Earth-years since departure at the news epoch) and a template id seeded from the `news` stream. alpha Cen is tier `<1`, the return `5-15`.
  - News provenance: `body_source` is `template`, `ai` or `fallback`, with a `fallback_reason` (`ai_numeral`, `ai_length`, `expired`, ...). It follows the existing `ai_request` / `ai_accepted` / `ai_fallback` events; the record validation already in `sim/ai.ail` is reused, not duplicated.
  - Live `ship.ism{load_w_m2, drag_n, glow_w_m2, drag_energy_j}` at the current rapidity (package calls at the current pin, zero at rest), `drag_energy_j` being the ledger's `drag_j` since the latest commit.
  - An append-only legacy log (`commit`, `departure`, `boost`, `cruise`, `brake`, `arrival`, `news`, `return`, `archive_unlock`) and the six README archive hint predicates. `new_game` may carry `archive: [{id, unlock}]`; rows unlock once, in table order.
- Protocol 2.2 (additive): a client that asks for minor 2 is answered minor 2 and receives the `consequence` change set and `ship.ism`. Clients asking for 2.0 or 2.1 get the 2.1 stream byte for byte, so every M2 and AI test and golden is unchanged.
- `make strict` runs `scriptedRoundTrip` (Sol, alpha Cen, Sol at 0.99c with the stand-off, zero dwell) against a closed form, and `consequenceVm` (the whole new battery) on the strict VM.

#### Not yet

- `glow_pole_w_m2` is step 2: it waits on M4.6a's `glowEmittanceAt` package release; the sim never computes 4 x `glowInwardFlux` itself.
- The design-repo canon (HB-4 at 4.37 ly) is not yet regenerated at the catalogue 4.32 ly (D-23). The target distance is a parameter; the tests assert the verified 4.37 ly check values and a 4.32 ly case computed from the package.

### forward-cmb (2026-10-03)

#### Added

- M1.8 forward CMB disc (queue row 6a, D-11). The sky shader adds the CMB per pixel as
  `photopicRadiance(T0 · D(θ′))` in cd/m², with D = 1/(γ(1 − β cos θ′)) and T0 = 2.725 K, in the
  same exposure as the galaxy and the stars. At the cap (1 − β = 1e-6, γ 707) the pole is
  3,853.7 K (HB-63) and 1.98e8 cd/m²; T halves near θ′ = 1/γ (4.9′), and the disc delivers
  ~189 lux. At γ 275 the pole is 1,499 K, a visible orange disc. At rest the term is exactly 0.
  `sky/cmb.gd` builds a radial profile once per speed (rebuilt when γ moves 0.5%), blurred by
  the same angular PSF as the stars (Hankel form with I0e), so the sub-pixel core neither aliases
  nor loses illuminance. It reads photopic radiance through a finite lookup over T ∈ [0, 5,000 K]
  (gate 5).
- GDScript mirrors of `photopicRadiance`, `cmbSeenTemperature` and `cmbSeenTemperatureApparent`
  (sunholo/relativity 0.5.2), written in the 1 − β form so nothing cancels near c. `make physics`
  checks them against the package's values: HB-62 38.44 K, HB-63 3,853.7 K, rest-frame 90° = 1,926.9 K
  (apparent asin(1/γ)), apparent 90° = T0/γ.
- `make golden`: 7 CMB cases. The sharp disc at γ 707 reads the package radiance within 1% at θ′ ≈ 0,
  1/γ and 2/γ; the PSF disc matches the CPU profile; θ′ = 45° and 90° read exactly 0, and so does
  every pixel at β = 0.
- `make capture`: γ 275 and γ 707 on a real journey (boost, then cruise), forward and starboard,
  each as eye, camera auto and camera fixed-at-rest; 4° zooms on the disc; `cmb_sheet.png`.

#### Changed

- The star PSF is fixed in angle (σ = 6′, the dark-adapted eye's blur; at least 0.7 px). EV_dark is
  now one number (−4.40) at every render size, and the dark sky shows the same linear value at
  960×540 and 2560×1440. M1.5a measured a 7.1× difference. V_lim is 6.8 at 960×540 and 6.9 at
  2560×1440 (AC8 6.6–7.4).
- The eye mode meters with `sky/sky_meter.gd`: a centre-weighted (σ 12°) arithmetic mean that
  includes the stars (direction × temperature bins, nearer than 20 ly one by one) and the CMB
  disc. The eye now light-adapts forward at 0.99c (EV −3.8) and to the disc at γ 707 (EV +12.4),
  and stays pinned at EV_dark sideways. The camera mode keeps its log-average meter.

### cmb-ring-fix (2026-10-03)

#### Fixed

- A bright white ring around the forward view at γ ≈ 40–60 (from M1.8, #79). At these speeds the
  CMB pole is only 218–327 K. The PSF-blurred profile's radiance underflowed float32 near the cutoff,
  and the colour normalisation became 0/0 = NaN; the sky shader drew those texels as a white ring.
  The colour sums now run in float64, with the local temperature's colour as a fallback, and the
  shader also skips NaN texels.
- `make physics` checks every CMB profile texel is finite, that radiance never rises outward and
  that nothing is left at θ_max, at γ 40, 50, 60, 275 and 707, with and without the PSF.
  `make golden` adds 3 cases: γ 40, 50 and 60 ahead are exactly black at k = 1e6 (10 CMB cases).
  `make capture` adds a 20° view at γ 40–60 (`cmb_ring_sheet.png`).

### catalogue-switch (2026-10-03)

#### Changed

- Galaxy map catalogue switched off CNS3 (M1.7, F6, Q7): `data/starmap/stars.json` is now written
  by AILANG (`make starmap`, `sim/tools/starmap.ail` via `bright_main.ail mapMain`) from the same
  rows as the shipped point tiers, quick (CNS5 + Hipparcos photometry fill) + bright (HIP2), within
  25 pc: 5,687 stars (was 3,802), float64 positions, one star per line, nearest first. Ids are stable
  catalogue ids (`Gaia DR3 n`, `CNS5:n`, `HIP n`), one per star, so alpha Centauri A (`CNS5:3627`)
  and B (`HIP 71681`) are two selectable stars, both at the catalogue's 4.321 ly (Q2 (a), D-19).
  `make catalogue-verify` rebuilds and cmp-checks it; `make star-catalogue-test` checks every map
  row is a tier record bit for bit.
- `data/starmap/names.json` is keyed by catalogue id (52 names; Procyon, Kruger 60 and Ross 614 are
  one catalogue row each, so their B names are gone). The map subtitle is the catalogue id and the
  catalogue's own distance (D-17). `tools/check_star_names.py` checks every name by id against its
  SIMBAD reference: direction within 0.1 deg, distance within 3 %, V within 0.3 mag.
- Sky background destar (D-10) now masks only stars the point layers ship: Hipparcos V < 7 with
  Plx > 0 and B-V (the bright tier's cut) instead of V < 7.5. Masked sources 24,437 -> 17,690; the
  V 7-7.5 stars no layer draws stay as photo pixels. New texture pins in `data/sky/SHA256SUMS`.
- Replay golden `godot_map_voyage` re-recorded (Sirius A and alpha Cen A at their new catalogue
  doubles); `sim/core_test.ail` row 7 uses the alpha Cen A catalogue doubles (4.32103979249451 ly).

### ai9-hardening (2026-10-03)

#### Fixed

- The player's AI cost ceiling now bounds the whole game session (AI.9 hardening, before the first attended live run). The service used to start its ledger at zero every time it restarted (after a settings change, a fault or a timeout). `AiBridge` now passes the session's spend so far, summed from `usage.ndjson` like the indicator, as the config's `spent`, and the service's ledger starts from it.
- AI calls that are sent but never answered are now charged. A transport error or dropped connection is charged at the call's cap. Before each live call the service writes a provisional usage line at the request's worst case to `inflight.json`. If Godot kills the service mid-call (timeout) or it dies mid-call, that line is appended to `usage.ndjson`, so the indicator and the next launch count the call.
- `make ai-live-guard` can no longer be evaded by an extra space or quotes around `--entry live`, a variable as the entry, a recipe ending in the old exemption suffix, or a Python harness passing `env={"AI_LIVE": "1"}`. Lines are normalised, `*.py` and `*.gd` are scanned, any assignment or mapping of AI_LIVE is caught, the mutation tables are exempt only by place, and only tracked files count (so `.claude/worktrees/*` is ignored). Each evasion is now a guard mutant.
- An exported build re-unpacks its AI service when any file under `ai/` or `data/ai/` changes, not only `service.ail`, the lockfile or the data tables.
- A session key file left by a crash (`user://.ai_key_session_*`) is removed when the next session starts. `make export-smoke` and `ai-export-smoke` run the app with a scratch HOME, so they never touch the player's `user://`.
- New tests: key files at a path with a space and an apostrophe, an empty key file counts as no key, an automation run has no indicator, and an earlier session's usage lines are not counted. Every new test kills a mutant (`make ai-mutants`, `make ai-bridge-mutants`, `make ai-live-guard`).
- A usage line with an absurd cost (or one that would overflow) now makes every later request refused at the ceiling instead of wrapping around and admitting it. Quitting the game in the middle of a live call charges that call's reservation. The live guard also scans game scripts and every make file, rejects includes outside `mk/` and a sim exception without a `sim/` program, and reads Python `"--entry=live"` tokens.
- `make test` passes on a checkout without `make runtime` (CI): the unpack test uses a stand-in package cache there.

### ai10a-style-frame (2026-10-03)

#### Added

- The Medic conversation (AI.10a, rehearsed on the stub; no live call): `godot --path . res://ui/conversation/conversation.tscn -- --conversation=medic`. A large portrait crossfades between the Medic's accepted portraits as the line's emotion markers change, the subtitle is revealed segment by segment, and the voice line plays. The portrait swaps 150 ms before each of the voice's exact segment offsets (`segments_ms`), as Mark chose at the style frame (`--swap-offset-ms`, default -150; 0 swaps at the segment start), with a 120 ms crossfade (`--crossfade-ms`). A missing emotion falls back along the portrait chain, and a missing voice degrades to text with `missing_blob` logged. The scene reads only the sim's `ai_accepted` events and the cache, either from a replayed log (`--log=`, no AI process) or from a stub rehearsal.
- `data/ai/cast/medic.json`: the Medic's cast entry (departure age 35, persona, voice `Aoede` pending Mark's choice, delivery style, core portrait keys). The relay now takes the cast it sends with each request from `data/ai/cast/`.
- `tests/replays/medic_rehearsal.ndjson` (with per-arch goldens): one Medic line with emotions neutral, loving and grieving, and its voice, recorded on the stub. `make ai-conversation` (in `make test`) re-records it byte for byte and checks the swap timing, crossfade, fallbacks and the no-audio path; `make ai-rehearsal-record` re-records it.
- `make ai-style-frame` (GPU window, never in `make test`): replays a log through the conversation and writes `renders/ai_medic/` (a PNG at each swap, `contact_sheet.png`, `line.ogg`, `line.wav`, `timeline.json`, and `frame.avi` with audio from Godot's movie writer). On the rehearsal it first re-records the stub session to get the blobs.

#### Changed

- The AI service's voice index lines now carry `duration_ms` and `segments_ms`, so a voice line already in the player's library is a cache hit instead of being generated (and paid for) again.
- Every voice blob now has a WAV playback copy beside it (the same PCM). Godot 4.7 plays WAV and Ogg Vorbis, not Ogg Opus; the Ogg Opus blob stays the canonical, hashed asset the sim validates. The voice index line records the WAV's `wav_sha256`, checked before it is played. `make ai-playback-verify` (in `make test`) proves each WAV is derived from its Ogg: its PCM, re-encoded, gives the Ogg blob byte for byte. The core layer carries a voice's WAV too (core verify, bundle, publish), so an accepted core voice is heard, not only read.
- While the voice plays, the conversation follows the audio clock, so the portrait swaps cannot drift from the voice when frames hitch.

#### Fixed

- The stub voice of a long segment (more than about a thousand tone periods, e.g. a grieving segment of 43 characters) made the service silently drop the request on the bytecode VM: no result, no error. The tone is now built by doubling, which gives the same bytes. Reported upstream as ailang#1576.

### ai-keys-cost-ux (2026-10-03)

#### Added

- Live AI settings, the cost indicator and the game wiring (sprint R1-AI-FOUNDATION AI.9, design (a5)):
  - `AiSettings` (`ui/settings/ai_settings.gd`): live AI stays off until at least one key is present **and** the player ticks the opt-in. Each key comes from `GOOGLE_API_KEY` / `OPENROUTER_API_KEY`, else a pasted key saved to `user://ai_key_gemini` / `user://ai_key_openrouter` with mode 0600. There is one player-set ceiling over both providers (default US$0.50, bounds 0.05 to 20), a text-only toggle and a `--text-only` flag, all persisted in `user://ai_settings.cfg` (never a key). Automation runs (`--capture`, `--map-capture`, `--golden`, `--bench`, `--ai-hello`) never go live.
  - The settings panel (`ui/settings/ai_settings.tscn`) shows which kinds each key enables (OpenRouter: text; Gemini: text, portraits, voice), a price estimate per kind and a plain warning.
  - `AiIndicator` (`ui/ai_indicator.tscn`, its own CanvasLayer) shows the session's running cost per provider and in total against the ceiling, taken from the service's usage lines (charged failures included), and says when the ceiling stops a request. Clicking it opens the settings.
  - `AiSession` (`bridge/ai_session.gd`) wires the settings, `AiBridge`, `AiCache`, `AiRelay` and the indicator into the galaxy map (one `main.gd` hunk), and sends `ai_core` in `new_game`.
- `make ai-live-guard` (part of `make test`, AC15): static rules that no Makefile target, test, CI job or launch path can start a live provider with AI_LIVE=1 (the one exception is `tests/test_ai_relay.gd`'s cleared AI_LIVE), plus 10 guard mutants, and the launch builder run with AI_LIVE unset (stub, `--caps IO,FS`).
- `make ai-settings` (part of `make test`) runs `tests/test_ai_settings.gd`. It covers the opt-in rules, the 0600 key files, the kinds per key, the ceiling, text-only, the panel, the indicator with a `budget` refusal on the stub, and AC14 re-run through the wired path.
- Export: `make ai-runtime` adds `ai/`'s packages (sunholo/gemini_live) to the bundled runtime. `export-macos` also depends on `ai-runtime` and `ai-core-bundle`. The preset bundles `ai/`, `data/ai/` and `ai_core/`. `make export-smoke` gains a stub AI hello from the bundled runtime, with no ailang on PATH (`ai-export-smoke`).

#### Fixed

- Live Gemini can no longer bill a gcloud project. On AILANG v0.51 and later, gcloud Application Default Credentials in HOME beat `GOOGLE_API_KEY`. The live launch now binds Gemini with `--ai-key-file <key file>`, and every live launch passes `--ai-no-adc`.
- The live service runs under a minimal environment. The wrapper execs `env -i` with only PATH, HOME, `GOOGLE_APPLICATION_CREDENTIALS=/nonexistent`, the keys read from their files and, only when allowed, AI_LIVE=1. Other `*_API_KEY` variables no longer reach the child.
- A billed reply that fails to parse is now charged. This covers an OpenRouter reply with usage but no content, and TTS speech over its token cap: the call and its reported tokens reach the ledger and `usage.ndjson`. Previously such a reply was dropped. `make ai-loopback` checks both cases, and `make ai-mutants` gains `ai-loopback-mutants`.
- `ai/tools/core_import_test.ail` adds a non-square PNG, so a width/height swap fails a test. It also adds refusals for 0 bytes, height 0, a short source and a commit that is not 40 lowercase hex characters, with 6 new mutants.

### ai-core-layer (2026-10-03)

#### Added

- The AI core layer (sprint R1-AI-FOUNDATION AI.8, design (a4)). The accepted Medic set (4 portraits and 1 avatar) is now pinned and content-addressed:
  - `data/ai/core/index.ndjson` and `data/ai/core/SHA256SUMS` hold the set, imported from `blender@8f04dfc` by `ai/tools/core_import.ail` (AILANG, `std/crypto.sha256Bytes`).
  - `ai_core`, the `new_game` value, is the sha256 of the index: `$(AI_CORE)` in `mk/ai.mk`.
- `make ai-core-verify` runs offline as part of `make test`. It checks:
  - the fixture import against its expected files, and that a corrupted blob is refused;
  - that the committed index and sums are consistent and every key is valid;
  - the blob hashes, when `data/raw/ai_core` has the blobs (AILANG, plus `shasum` as an independent check);
  - with the Blender checkout present, that a fresh import from the pinned commit matches.

  `AI_CORE_FETCH=1` fetches the blobs first.
- `make ai-core-assets` fetches the blobs from `gs://stapledons-voyage-assets/ai/` over anonymous HTTPS and checks each sha.
- `make ai-core-bundle` stages `ai_core/` for the export.
- `make ai-core-publish` uploads the blobs `--no-clobber` (maintainers, gcloud).
- `make ai-core-import` re-imports the set from the Blender repo at `AI_CORE_COMMIT` (maintainers).
- `make ai-mutants` gains 5 mutants of the core import and verifier.

#### Changed

- `infra/gcp/README.md` documents the bucket's `ai/` prefix, and that the `openrouter-api-key` secret is created empty and Mark adds its value.

### starfield-v2 (2026-10-02)

#### Added

- M1.3 starfield v2: the sky flight draws a binary catalogue tier (`--tier=quick|medium|large`;
  default large when built, else medium) through `sky/star_catalogue.gd`, plus the bright tier on
  top once M1.2d builds it. The large tier is 324,307 instances (7,005 GCNS rows without
  photometry are skipped). The starfield no longer reads `stars.json`.
- With M1.2d merged, the medium and large tiers also stack quick's 137 HIP-filled rows (flag 8:
  Sirius, α Cen A/B, Procyon, Altair, ...; GCNS has no photometry for them and the bright tier
  excludes them as CNS5 matches) and the bright tier: 335,157 stars on the large tier.
  `make capture` gains a port view. (Corrected by D-28: port looks at l 90; starboard is l 270, with Canopus, α Cen and the LMC.)
- Instance custom data is (T_eff, E_v at Sol in lux from `illuminanceFromV`, flags, |p|²); the
  shader rescales E_v by inverse square and multiplies by `pointFluxRatio(T, D)`.
- Rebasing (gate 5): positions are float64 on the CPU and uploaded as float32 hi/lo pairs with
  the ship as a hi/lo uniform, so the direction to the destination at the 1,000 AU stand-off holds
  to 2.4e-8 rad (the float64 path to below 1e-9). A CPU rebase of the large tier takes ~74 ms, so the
  default is design plan B (no CPU rebase; the shader computes direction and 1/r²).
- O-1: `LUT_T_MAX` 1e7 K, `LUT_SIZE` 1320, with a finite-LUT test and a 60 kK / D 44.7 golden.
- `make bench`: a scripted 30 s flight at 2560×1440 on Metal (frame times) and Vulkan (GPU
  star-pass time, which the Metal driver doesn't report), plus the CPU rebase time.
- `make golden` also checks: the stand-off direction in both rebase modes, the hot white dwarf,
  and that the faint-star cull (splat peak below 1e-4) leaves nothing visible.

#### Changed

- `catalogue_stats.gd`: a row with only half the default (teff 0, or v 99) and no MISSING_PHOT
  flag is now a violation. The output labels rows in the bin, with and without photometry,
  separately from rows excluded before the bin.

### sky-background-rebuild (2026-10-02)

#### Fixed

- Sky background rebuilt with the corrected `stars.json` (M1.4d, after #37): the destar step no
  longer removes photo stars at the mirrored catalogue positions (118 V<4.5 discs, 0.32% of the
  panorama, are back as photo pixels); every V<6 `stars.json` star is drawn where its photo star
  was removed (474/475).
- Exported builds now carry the sky textures (`make export-macos` stages them via `make sky-bundle`);
  before, every build rendered a black sky.

#### Added

- `make sky-assets` (`sky-inputs` -> `destar` -> `sky-model` -> `sky-verify`): rebuilds the two
  generated textures byte for byte from pinned downloads; `data/sky/SHA256SUMS` pins inputs and textures.
- `download_background.sh raw` (the untouched NOIRLab TIF) and `download_stars.sh hip` (the exact
  VizieR request behind `data/raw/hip_v7.tsv`, pinned on its data rows).

### python-ports (2026-10-02)

#### Changed

- Star removal for the sky background is AILANG (`sim/tools/destar.ail`, `make destar`) with Godot headless
  image I/O (`tools/destar_io.gd`), replacing the Python spike. Catalogue-driven and local; all 49 stars
  brighter than V 2 are removed; `make destar-test` (in `make test`) runs a synthetic panorama on the strict VM
  and the interpreter.
- Merged with M1.4d (#45): `make destar` in the sky-assets pipeline is the AILANG destar; its catalogue
  list is HIP V<7.5 + GCNS + CNS5 (`data/raw/cns5.csv`, now pinned) instead of `stars.json`. A bright
  catalogue star (V < 4.5) whose core rolls off at 245-253 instead of clipping now counts as detected:
  eps Sco, alpha Ara, lambda Cen, zeta Ara, eta Sco and alpha Lac were left in the photo on the Milky
  Way band. Every HIP star brighter than V 4.5 is removed. New texture pins in `data/sky/SHA256SUMS`;
  `sky-inputs` falls back to `sim/tools/extract.ail` for gcns.csv/cns5.csv.

#### Removed

- `tools/m14a_destar.py`, `tools/m14a_register.py`, `tools/m14a_crops.py`. With `tools/extract.py` gone too,
  no Python pipeline step remains (`make python-guard`: 0 awaiting port).

### catalogue-tiers (2026-10-02)

#### Changed

- The catalogue tool builds every list with linear builtins (map, filter,
  flatMap, take, one stable sort), never a consing fold (ailang#1501). On the VM,
  the medium tier drops from 6 min 23 s to 61 s and the large tier from
  8 min 56 s to 55 s. The output bytes are unchanged.

#### Added

- All three tiers build from the real catalogues: quick (5,908 rows), medium
  (50,000 rows, 965 excluded) and large (331,312 rows, 7,951,488 B).
- N3: an exact 50,000-row boundary test with missing rows in between, an
  independent excluded count, and tests that the first error wins (row order) in
  the transform, the range check and `encodeRows`.
- `make catalogue-parity` builds a real tier once on the interpreter and five
  times on the VM, compares the bin and sidecar bytes, and prints each run's wall
  time and peak RSS.

### catalogue-commit (2026-10-02)

#### Added

- The quick (5,908 stars) and medium (50,000 stars) catalogue tiers and their
  sidecars are committed under `data/starmap/` (D-3). The large tier stays a
  local build.
- `sky/star_catalogue.gd` (`StarCatalogue`) loads a binary tier. It refuses any
  pair whose sidecar `format_version`, `record_bytes`, `fields` or `count`, or
  whose sha256 of the bin, does not match. M1.3 renders from it.
- `make catalogue-stats` (Godot headless, part of `make test`) reports each
  tier's count, excluded count, M-dwarf share and white dwarfs, and checks the
  defaulted-photometry invariant on every record. Medium: 74.4 % M dwarfs, 0
  violations (AC3; AC2's clause).
- `make catalogue-verify` rebuilds quick and medium from the pinned inputs and
  checks them byte for byte against the committed files.
- `make catalogue-inputs` fetches the four catalogue inputs from the bucket,
  falls back to VizieR and `extract.ail`, then checks their pins.

#### Fixed

- `data/raw/cns5.dat`, the raw input of the quick tier, is now pinned in
  `data/sky/SHA256SUMS` (sha256 `7e8c1a2c…`). `tools/sky_assets.sh fetch` now
  tries every pin before it exits 1, so `make` falls back only for the files the
  bucket lacks. It also takes an optional path filter.

#### Removed

- `process_stars.sh`. The starmap-manager skill now documents the binary tiers
  and `make catalogue`, and `status.sh` reads the tier sidecars.

### bright-tier (2026-10-02)

#### Added

- M1.2d bright tier (D-5, D-19): `data/starmap/stars_bright.bin` (10,713 rows,
  257,112 B) and its sidecar, committed (Q4). These are the Hipparcos stars with
  V < 7 and a positive parallax (HIP2 I/311 astrometry, I/239 Johnson V and
  B−V) that match no CNS5 row (by CNS5's HIP column) and no GCNS row (within
  1″ at J2016.0 after proper motion, |G − V| < 2). Of these, 463 matched CNS5,
  4,120 matched GCNS and 7 lack B−V. teff comes from `teffFromBV`, v is V
  verbatim, and flags are 8. Rigel, Canopus, Betelgeuse, Deneb, Polaris, Spica
  and Antares are now real catalogue stars. It is built with
  `make catalogue TIER=bright` (`sim/tools/bright.ail`, entry `brightMain`,
  about 7 s on the VM).
- Rule (b), the HIP photometry fill: a CNS5 row without Gaia photometry, whose
  HIP id it owns, takes that star's V and `teffFromBV(B−V)` in place (flag 8).
  The quick tier fills 137 rows, among them Sirius (V −1.44), α Cen A, Procyon,
  Altair, Vega, Arcturus, Capella and Aldebaran. A row whose HIP id another
  CNS5 row shares is filled only when no other row's Gaia G is within 2 mag of
  V, so a faint companion never takes its primary's light. 11 such rows and
  CNS5:1164 (no B−V) stay missing.
- Rule (c), `data/starmap/bright_overrides.json`: α Cen B (HIP 71681) sits at
  the CNS5 system parallax (754.81 mas, 4.321 ly), at its own HIP2 position,
  19″ from A (about 25 AU). It is never at its own 4.09 ly. Each row carries a
  citation, and an override that cannot apply refuses the tier.
- `tools/bright_star_audit.gd`, the AC11 auditor (Godot replaces the planned
  Python). `make test-bright-audit` checks it on synthetic renders. The render
  gate runs in M1.5b.
- `make bright-test` checks the named checks (Vega excluded, Arcturus matched
  only after proper-motion propagation, Rigel included, CNS5 per-row epoch,
  Sirius filled, α Cen components, the shared-HIP guard, the V/Plx cuts and
  override refusals) on real fixture bytes, with strict VM = interpreter.
- `download_stars.sh bright` fetches the inputs, and `data/sky/SHA256SUMS` pins
  `hip2.dat.gz` and `hip_main.dat`.

#### Changed

- The committed quick tier is rebuilt with the fill. Its bin sha256 changed
  from 73f4d0e1… to 422a0600…, the size is unchanged (5,908 rows), there are
  137 more complete rows (5,138 → 5,275) and the M-dwarf share went from 76.8%
  to 75.5%. The medium tier's bytes are unchanged.
- Flag 8 (Hipparcos photometry) is a valid flags bit: `FLAG_SETS` gains 8 and
  24, and `catalogue-stats` reports HIP photometry counts and judges the bright
  tier.

### ai-relay (2026-10-02)

#### Added

- `AiRelay` (`bridge/ai_relay.gd`) and `AiCache` (`bridge/ai_cache.gd`), sprint R1-AI-FOUNDATION AI.7. The sim's AI requests now reach the stub service and come back as records, end to end:
  - The relay sees each tick's events through an optional `SimBridge.ai_relay` hook; its records and cancels ride on the next `send`, so the tick never waits and the session log holds them.
  - A cache hit records straight away with no service call. Text-only mode cancels media requests, live AI off cancels `offline`, and a kind with no key for its route cancels `no_key`.
  - The cache reads the core layer, then the player library (newest line wins), resolves `age_stage` to the greatest stage at or below the years asked, and mirrors the sim's portrait fallback chain.
  - Replay mode only observes, so a replay never starts an AI process.
- The live launch (`AiBridge.live_plan`): keys travel as key-file paths through a wrapper that also clears `AI_LIVE` unless it is explicitly allowed. A key never appears in argv.
- `tests/test_ai_relay.gd` with `--news`, `--key-hygiene`, `--routes`, `--replay-noai` and `--faults`. It runs as `make ai-relay` and `make replay-noai` (both part of `make test`). `tools/record_ai_session.gd` records `tests/replays/ai_stub_session.ndjson`, which `make replay` replays on both runtimes.
- `make ai-loopback` (part of `make test`) runs the OpenRouter and Gemini TTS network halves of the adapters against a local fixture server with fake keys, and checks the URLs, headers, bodies and the retry. The keys must never reach stdout, stderr or the cache.

#### Changed

- `SimBridge` asks for protocol 2.1, accepts an optional `ai_core` in `new_game`, and starts the sim through the same descriptor scrub as the AI service, so the sim no longer inherits Godot's other pipes.
- The busy-machine frame rule in `tests/test_ai_bridge.gd` now times a control step that makes the same system calls as a poll (pipe read, process probe, stat). The allowance is control + max(4, n/100).
- Tests carried over from the AI.3 and AI.5 evaluations: one digit fixture per digit in the sim and the service screen; an accepted portrait leaves `ai.lines` unchanged; a failed live call is charged; nano-dollar rounding. Each of these has a mutant.

### ai-bridge (2026-10-02)

#### Added

- `AiBridge` (`bridge/ai_bridge.gd`), sprint R1-AI-FOUNDATION AI.6. It runs the AI service as a separate child process, started only when a request misses the cache, and never blocks the frame:
  - Reads are non-blocking and assemble lines across partial reads; the spawn and the kill run on the worker pool.
  - One request is in flight at a time, picked by priority: text, then voice, then portrait.
  - The handshake must arrive within 5 s with `proto.major` 1.
  - Per-kind timeouts (text 30 s, voice 60 s, portrait 120 s) kill the child, cancel the request and restart lazily.
  - A crash restarts with a backoff of 1, 4 and 16 s and resends the open request.
  - After 3 failures in 10 minutes the service is down for the session: every pending request falls back and the toast is shown.
  - Shutdown sends `quit`, waits up to 1 s, then kills.
  - The child starts through a bash script that closes every inherited descriptor (Godot sets no close-on-exec), so the AI process never holds the sim's pipes.
- `ai/tools/fake_service.ail`, a misbehaving stand-in for the fault tests, and `tests/test_ai_bridge.gd -- --faults`. `make ai-godot` (part of `make test`) runs the test, and `make ai-bridge-mutants` runs 17 mutants, each of which fails a named check.

## v0.3.2-m2-journey (2026-10-02)

### Review-build polish, 2026-10-02 (Mark's feedback on `v0.3.1-m2-journey`)

- **Trackpad zoom on the galaxy map:** pinch (magnify gesture) and two-finger
  scroll (pan gesture, one unit = one wheel notch) zoom, clamped like the
  wheel; `+`/`=` and `-` zoom by a notch. Two-finger scroll never orbits.
- **HiDPI and UI size:** `allow_hidpi`, canvas-items stretch (aspect expand)
  so the panel scales while 3D renders at full resolution; on a HiDPI screen
  the window opens at base × screen scale. Cmd/Ctrl `+`/`-`/`0` change the UI
  size (0.75–3.0). Captures and goldens keep the 1:1 window: committed
  `docs/m2.6a`, `docs/m2.6b` PNGs are byte-identical.
- **Footer hint** "Pinch or scroll to zoom · drag to orbit · ⌘+/− UI size"
  (hidden in `--map-capture`).
- **Missing sky background is loud:** the sky flight warns on startup and
  shows "sky background not bundled in this build" when the M1.4 panorama is
  absent (HUD note hidden in `--capture`).

## v0.3.1-m2-journey (2026-10-02)

### M2 journey core, 2026-10-01 – 2026-10-02 (sprint R1-M2-JOURNEY, landed; bar clause 2 met)

Ten milestones, PRs #22–#35, each independently evaluated (89–96/100).
Report: `design_docs/implemented/r1/m2-report.md`.

- **M2.0 package (96):** `sunholo/relativity@0.4.0` published (ailang-packages
  #84): boost–cruise–brake and flip-and-burn trip plans, `phaseAt`,
  `motionAt`, `acosh1p`, `rapidityOfOneMinusBeta`, ISM `medium`, forward CMB
  temperature; 101/101 tests.
- **M2.1a protocol codecs (92), M2.1b bridge v2 (93):** protocol v2 with
  hand-written codecs and float-text repairs (−0.0, large/small floats);
  `SimBridge` v2 with a `record_path` tee and bit-exact float64 echo; v1.1
  removed.
- **M2.2 world (94):** `World`, scenario params, clock, ship phases, closed
  energy ledger; game pins relativity 0.4.0.
- **M2.3a planner + commit (95), M2.3b autopilot (96):** planner equals the
  closed form to 1e-9; the sim refuses every intent against a committed
  journey; stepped voyages match `motionAt` at every phase boundary, arrival
  residuals ≤ 4.8e-13 ly.
- **M2.6a galaxy map (89), M2.6b commit ritual (93):** galaxy map with a
  sim-bounded cruise slider and a panel of sim numbers only (review build
  `v0.2.0-m2-map`, R1 accepted by Mark, D-17); commit dialog with both clocks,
  years left and a 1.5 s hold, transit readout, refusal display, 54 common
  star names. Map → plan → commit → transit now runs end to end.
- **M2.4 PRNG (94):** SplitMix64 with six named streams (`splitmix64-1`),
  checked against published vectors and a reference on both runtimes.
- **M2.5 replay (93):** `make replay` / `make replay-record`; a 10,000-tick
  session is byte-identical on the VM and the interpreter and matches its
  golden. Goldens are per architecture (ailang#1465); P5 approved by Mark.
- **Toolchain:** AILANG pinned to v0.50.0 (#18), then v0.51.0 (#30).
  Thirteen AILANG issues filed or tracked during M2 (see the report).

## v0.3.0-m2-journey (2026-10-02)

### Fix: mirrored galactic longitudes in stars.json, 2026-10-02

- Every longitude in `data/starmap/stars.json` was mirrored, l = 245.86° − l_true
  (`process_stars.sh` added the IAU atan2 term to l_NCP instead of subtracting
  it). Fixed and regenerated from the same VizieR V/70A votable (the unfixed
  script reproduces the old file byte for byte): same 3,802 rows and order,
  only x, y change. 16 literature (l, b) check values in `tests/test_physics.gd`.
  The M1.4a destar mask (D-10) was built from the mirrored positions and needs
  a rerun.

## v0.2.0-m2-map (2026-10-02)

### M1 sky, 2026-09-27 – 2026-09-30 (3 of 12 milestones at the time; M1 later shipped through M1.8, only M1.5b open)

- **M1.1 photometry (iteration 0):** `sunholo/relativity@0.2.0`
  (BP−RP → T_eff, G−V, V → lux); game pin `b258222`.
- **M1.2a catalogue (iteration 2):** CNS5 + GCNS acquired from VizieR and
  parsed to galactic CSV (5,908 + 331,312 rows), 15 real-byte-fixture tests
  in `make test`; merge `77d3f04`.
- **M1.6a turns at rest (iteration 3):** pure ship turns at rest with phi
  snap and `origin + heading*(x−x0)`; `std/json` protocol v1.1 with reason
  codes; bounded bridge waits (5 s hello, 2 s step, 1 s graceful exit);
  off-axis parity and strict `scriptedOffAxis`; default-heading render
  unchanged (601-line v1.0 parity byte-identical). Requires AILANG v0.47.2
  (fixes the two VM bugs that parked this milestone; see the design doc's
  toolchain amendment).

- **M1.2b preflight (iteration 4):** bounded AILANG CSV and published normal
  photometry probe, real-byte fixture checks, strict VM/interpreter parity
  and real 5,000-row timing. WD fitting, production tiers and binary
  writing remain incomplete and depend on the package prerequisite.

- **M1.2b white-dwarf photometry (iterations 5–6):** `sunholo/relativity@0.3.0`
  published (blackbody WD Teff and V from Gaia BP−RP); the game pins it,
  `checkWDPackage` pins the fixture WD row, and `make wd-vm` checks the
  package's NaN contract on the strict VM (ailang#1419 hides NaN-guard
  mutants from the interpreter-only `ailang test`). PR #12, merge `68575d9`.

- **M1.2b pure transform (iteration7):** package-backed normal/white-dwarf
  photometry, explicit missing/clamped flags and independent counters; stable
  nearest-complete medium selection with quick/large source order preserved.
  Ten new tests and strict-VM/interpreter anchors run in `make test`.
  Independent Sonnet5.5 review: 88/100 PASS. Binary writer and full-tier
  parity/performance remain pending; full M1.2b is incomplete.

### Catalogue F32 records (M1.2b-T2, iteration 8)

- Pure AILANG Row/list encoding uses the bundled native little-endian F32 codec;
  invalid fields or flags refuse the whole output before any writer is involved.
- Independent Python byte oracle runs interpreter and five ordinary VM passes in
  `make test`; strict T1 tests now pin dwarf clamps and exactly one final newline.
- Filesystem writing, sidecars and production catalogue tiers remain downstream.

### sky-background (2026-10-01)

#### Added

- Real Milky Way background (M1.4, D-10): the NOIRLab `noirlab2430b` panorama with the
  catalogue-matched stars removed, rendered per pixel with inverse aberration and blackbody
  Doppler colour and brightness (`sky/background.gdshader`, `SkyBackground`, `SkyModel`).
- AILANG sky-model fitter `sim/tools/sky_model.ail`: per-colour T_c on the `sunholo/relativity`
  Planckian locus, residual and emission-line flags; `make sky-vm` (strict VM = interpreter,
  in `make test`) and the offline `make sky-model` (Godot headless I/O, `tools/sky_colours.gd`).
- `Relativity.surface_brightness_ratio` and physics checks for extended sources (D^4
  bolometric), the panorama contract and the T_c code; golden AC5 background marker (12 cases)
  and AC6 background colour (D = 0.3, 1, 3).

#### Notes

- The panorama is valid to about 50 ly from Sol (parallax); emission nebulae are flagged,
  not yet line-modelled; exposure is hand-set until M1.5.

### catalogue-transform (2026-10-01)

#### Added

- Pure AILANG CSV catalogue transform using the locked dwarf and white-dwarf
  photometry package, preserving coordinates, missing/clamped flags and counters.
- Stable nearest-complete selection for medium (50,000 rows), with quick/large
  preserving source order. Binary writing and full-catalogue integration remain pending.
- Ten exact fixture tests and `make catalogue-vm`, which checks transform and
  selection anchors on the strict VM and compares interpreter output byte for byte.

## v0.1.0-m0 (2026-09-27)

### M0 spike, 2026-09-27 (~1,900 LOC including tests)

- **Simulation:** AILANG sidecar over NDJSON stdio, about 50 µs per tick
  round trip.
  - Pure core on the bytecode VM, checked under `--strict-bytecode`.
  - I/O shell bridged to the interpreter.
- **Physics:**
  - GDScript reference: 27 checks.
  - GPU starfield: aberration, blackbody Doppler colour, point-source beaming,
    HDR.
  - 9 golden cases at under 0.1 px.
- **`sunholo/relativity@0.1.0`:** published (about 600 LOC, 40 tests); the
  simulation depends on it.
- **Tooling:** `make test` (physics, sim, parity, strict) and CI.
- **Process:** the design-doc → sprint → execute → evaluate cycle, the
  `game-vision-designer` and `starmap-manager` skills, and the M1 design doc.
- **Upstream reports:** 11 AILANG bug and DX reports.

