# M4: First journey, a vertical slice

**Status:** Planned (design, awaiting sprint plan)
**Release:** r1 · **Milestone:** M4 of [R1 foundations](https://github.com/sunholo-data/stapledons-design/blob/main/roadmap/r1-foundations.md) (bar clause 4)
**Priority:** P0: the first time the game is a game
**Implements:**
- Roadmap §M4 items 1–5, with item 2 **superseded by ledger D-6**: the
  "placeholder painted deck scene" becomes the isometric three-layer interior
  ([ship-interior-blender-brief](https://github.com/sunholo-data/stapledons-design/blob/main/art/ship-interior-blender-brief.md) §2, §5, §9).
- [viewport-compositing](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase1-data-models/viewport-compositing.md):
  only the idea (live sky composited behind interior plates). Its Go
  `ViewportManager`, masks and edge-blend shader are not ported; the mask is
  the panorama's alpha.
- [journey-system](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase3-gameplay/journey-system.md)
  Parts 3–4 (transit, arrival summary), stubbed: no crew events, no vote.
- [ai-showcase](https://github.com/sunholo-data/stapledons-design/blob/main/features/ai-showcase.md)
  §2 row "News from home" and §5 (the sim never calls AI; results are
  recorded inputs), under D-7 and D-8.
- [relativity spec](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md)
  §2 rendering requirements (HDR, float64 γ and 1−β, finite tables) and §4
  (golden tests, reference renders), applied to the composited interior view.

**Depends on:**
- **M2** journey core ([m2-journey-core.md](m2-journey-core.md)): protocol v2,
  planner, sim-owned commit rule, replay harness, galaxy map. Hard dependency;
  M4 extends it and does not redesign it. The assumed interface is in
  [§Interfaces assumed](#interfaces-assumed).
- **M1**: M1.2 tiers (α Cen A and B need real astrometry; see Problem 5),
  M1.3 rebasing, M1.5 exposure, M1.6b camera golden. M1.4 background is
  optional (without it the slice shows catalogue stars only).
- **AI service foundation** (queue row 2, D-9; no design doc yet). Soft
  dependency: M4 is fully playable on templated text if it slips.
- **Blender bridge style frame** (brief §7 step 1). Soft dependency: M4 ships
  on the spike blockout if it is not approved in time.

**Estimated:** ~2,950 LOC (≈1,750 code + 1,200 tests/tools), 7 sub-milestones
**Evidence:** codebase claims are in the [Verification log](#verification-log),
pinned to `e9d35c5` (main) and `fe16790` (`origin/spike/iso-bridge`).

## Game vision alignment

| Pillar | Relevance | Score | Notes |
|---|---|---|---|
| Choices Are Final | ++ | +2 | Commit is the slice's centrepiece; the sim rejects cancel mid-journey; no save/load exists (replay is a developer tool, not a reload) |
| The Game Doesn't Judge | + | +1 | News and legacy log state facts only; template copy is reviewed against this pillar (stop point S4) |
| Time Has Emotional Weight | ++ | +2 | Both clocks on screen all journey; news at α Cen is 4.35 years stale by light delay; home is ~12 years older on return, ~4.8 more than the crew aged |
| The Ship Is Home | + | +1 | The player walks the bridge under the forward pole; placeholder art and no crew dialogue keep this at +1 |
| Grounded Strangeness | + | +1 | The starbow gathers overhead through the real architecture, then relaxes on arrival |
| We Are Not Built For This | 0 | 0 | No crew psychology in R1 |
| Hard sci-fi authenticity (spec) | ++ | +2 | No new formulas; every displayed number comes from the sim; light-delay news is a closed form |
| **Net** | | **+9** | **Go.** One tension: the universe does not advance while docked and planning (Time pillar excludes "pausing the universe while you decide"). Open question 7 |

## Problem

R1 has a sky (M1, in sprint) and will have a journey core (M2, design in
progress), but nothing a player can play:

1. **No interior on `main`.** `main.gd` is the M0 spike: W/S thrust, a free
   camera, a debug label (V1). The iso interior exists only on the unmerged
   branch `spike/iso-bridge` (V2), with hand-set speeds `SPEEDS := [0.0, 0.99]`
   and a constant `HEADING`, not driven by the sim.
2. **The spike breaks the precision gate.** `spike/interior3.gd:176` computes
   `g := 1.0 / sqrt(1.0 - b * b)` in GDScript (V3). CLAUDE.md gate 5 says γ and
   1−β come from the sim or package. `sunholo/relativity@0.3.0` already exports
   `gammaOf(phi)` and `oneMinusBeta(phi)` (V4), so the fix needs no new maths.
3. **The sim has no journey, Earth or log.** `Ship = { tick, motion, heading,
   origin, x0 }` (V5). M2 adds the journey and clocks; nothing anywhere models
   what happens at home, when news arrives, or what the voyage leaves behind.
4. **Nothing proves what's on screen.** The HUD is a free-form string built in
   `main.gd`. There is no check that a displayed number equals a sim value, and
   no headless run of a whole session.
5. **The destination breaks the starfield.** In the committed catalogue
   α Cen A and B (`Gl 559`) have *identical* positions at 0.01 ly precision
   (`x 1.5, y −4.09, z −0.05`; V6). 0.01 ly is 632 AU. Arriving within a few
   hundred AU, the two stars would coincide and sit hundreds of AU from where
   they really are, and a star at the ship's own position would give an
   inverse-square flux of 1/0. M1.2's tiers (CNS5 astrometry, float32 relative
   to a float64 rebase) fix the precision; M4 must also fix *where the ship
   stops*.
6. **The roadmap's interior is superseded.** It asked for "one painted image
   with a masked window". D-6 replaced that with Blender play areas, interior
   panoramas and the live sky through the panorama camera. The brief's bundle
   format (§9) exists, but no game code loads it.

## Goals

- **G1.** One continuous loop: bridge at Sol → galaxy map → pick α Cen →
  plan → commit → transit → arrival → news beat → galaxy map → commit Sol →
  transit → arrival home → news from home → legacy log.
- **G2.** Transit in the iso interior, with the live relativistic sky
  composited through the panorama camera (SubViewport), time warp, and a HUD
  with ship time and Earth time.
- **G3.** A consequence stub in the pure sim: Earth's clock, light-delayed
  news epochs, a news tier chosen by the time gap, an append-only legacy log.
- **G4.** Every number on screen is a formatted sim field, checked by an
  automated audit over a full headless playthrough.
- **G5.** The whole session replays byte-identically, including any AI
  results, on the VM and the interpreter.
- **G6.** A new player finishes in under 10 minutes: a deterministic proxy in
  `make test`, plus a scripted human playtest.

**Non-goals:**
- Crew events, voting, psychology, dialogue trees (R2).
- Live AI generation as a requirement. It is opt-in (D-8) and the slice must
  pass with no key and no network.
- Voice. Text-only is always available (D-8); M4 plays no audio.
- More than one play area. Lower decks, the garden cathedral and enclosed
  rooms are brief §7 steps 4–5.
- Planets, the destination system's bodies, Terrell rotation.
- A civilisation model. "Earth" is a clock plus a light-delay rule.
- Final art. Everything is placeholder grade until Mark signs off (S2).

## Design

The rule from ADR 0001 holds throughout. **The sim owns state and rules;
Godot owns presentation.** Godot does no arithmetic on physics or clock
values: it formats fields from the last state message.

### M4.0 Promote the spike: area bundles and the frame contract

- **Area bundle loader** (`interior/area_bundle.gd`). It reads the brief §9
  layout from `assets/areas/<area>/`: `manifest.json`, `cam_<area>.json`,
  `pano_<area>.png`, `play_<area>.glb`, `fg_<area>.png`. It validates the
  schema and refuses a bundle with a missing layer.
- **The placeholder bundle.** Copy the spike's bridge files
  (`spike/v2/bridge_slice.glb`, `cam_bridge.json`, `stapledon_pano_bridge.png`,
  `spike/v3/stapledon_fg_bridge.png`) from `origin/spike/iso-bridge` into
  `assets/areas/bridge/` under the brief's names, and add a hand-written
  `manifest.json` (parallax 0.15 / 1.6, `iso_pitch_deg −14`, `iso_yaw_deg 45`,
  `iso_size_m 16`, focus `[−8, 1, 9]`). The blockout has no `WALK_` collection,
  so the placeholder gets a flat walk disc and two `INTERACT_` stand-ins
  (navigation console, Archive terminal) added in Godot, flagged
  `placeholder: true` in the manifest. A delivered Blender bundle replaces the
  directory with no code change.
- **`make validate-areas`** (`tools/validate_area.py`): brief §9 checks on any
  bundle: alpha exactly 0 where space shows; the camera JSON schema; the camera
  round trip (project a manifest-named point, land within 1 px); the GLB
  re-imports Y-up in metres. It runs on the placeholder too.
- **Frame contract** (`interior/ship_frame.gd`, float64 scalars throughout):
  - Ship frame: +Z = direction of travel, origin = bubble centre, metres
    (brief §5.2).
  - `ship_basis(heading)`: the sim's unit heading (galactic frame, from M2)
    becomes ship +Z. Roll is fixed by projecting the north galactic pole onto
    the plane normal to the heading (fallback: galactic +X when the heading is
    within 1e-6 of a pole). This is a presentation convention, not physics, and
    it is deterministic.
  - The sky camera's orientation is `ship_basis(heading) × cam.forward/up`. The
    spike's `ship_to_star` axis swap is replaced by this one function, with
    CPU tests (orthonormal to 1e-12, heading → ship +Z, the pole fallback).

### M4.1 Sim: consequence stub and session extensions (pure core)

A new pure module `sim/consequence.ail`. Its state lives beside M2's journey
state. I/O stays in `sim/ship.ail`, and `make strict` gains a
`scriptedRoundTrip` entry.

- **Earth clock.** `earth.t` = galaxy coordinate time at Sol, which equals
  M2's world clock (flat space, Sol at rest in the galaxy frame). No new
  integration.
- **Light-delayed news epoch.** At an event at ship position `p` and galaxy
  time `t`, the newest Earth news receivable is from Earth time
  `t_e = t − |p − p_Sol|` (c = 1, ly, yr). At Sol, `t_e = t`. Closed-form
  tests: at α Cen arrival with the default stand-off, `t_e ≈ 1.632` Earth-yr
  after departure, although `t ≈ 5.986`.
- **Displayed quantities as fields.** The sim emits every number the UI shows,
  including derived ones: `gap_years = t − tau` ("home is N years older than
  you"), `news_epoch`, `news_age_years = t − t_e`, journey progress, and
  `one_minus_beta` from the package's `oneMinusBeta(phi)` (if M2's state does
  not already carry it). Godot never subtracts two fields.
- **News tier.** `newsTier(elapsed_since_departure_at_t_e)` maps to five
  buckets: `<1`, `1–5`, `5–15`, `15–50`, `≥50` Earth-years. Inside a tier, a
  template id is drawn from a named PCG stream (`"news"`, M2's generator), so
  the choice is seeded and replayable. The sim emits
  `news{tier, template_id, slots{...formatted numbers...}, ai_request_id}`.
  α Cen hits tier `1–5` and the return hits `5–15`. Fixtures cover all five.
- **Legacy log.** An append-only list in sim state. One entry per event:
  departure, commit, flip, arrival, news received, return. Each entry carries
  `{tick, kind, star_id, tau, t, gap_years}`. It is emitted as a change set
  and never rewritten (Pillar 1). The final screen renders it; nothing is
  scored (Pillar 2).
- **AI results are inputs.** A new input intent
  a `record{source: "ai", req, kind, sha256, body}` intent (M2 protocol 2.1) is accepted only for an open
  `ai_request_id`. Validation is pure: text containing any digit `[0-9]`, or
  longer than the template's `max_chars`, is rejected with reason
  `ai_numeral` / `ai_length`, and the template stands. That way an LLM cannot
  put an unaudited number on screen. Accepted text is stored in state and
  logged, so the replay contains it.
- **Arrival stand-off.** The journey target is the point at stand-off
  distance `s` short of the star along the approach line (default 1,000 AU =
  0.015813 ly; open question 2). With M2's 1 g flip-and-burn this gives
  d = 4.3542 ly: 3.5773 ship-yr, 5.9859 Earth-yr, peak β 0.95141 (package
  `flipAndBurn`; the roadmap's 3.582 / 6.003 / 0.9517 is the d = 4.37, s = 0
  case). α Cen A is then about magnitude −12, roughly a full Moon, and A and B
  are about 1.3° apart: finite and readable. If M2 already defines a stand-off,
  M4 uses M2's value and only checks that it is above 0.
- **Protocol.** These are additive change sets and one intent on M2's
  protocol. M2's version policy applies (a minor bump), and M2's old-message
  tests stay green unmodified.

### M4.2 The iso interior with the live sky (SubViewport compositing)

`interior/interior.tscn`, built from the spike's five layers, driven by the
bundle and the sim:

| # | Layer | Node | Pan factor |
|---|---|---|---|
| 1–2 | M1 background (if M1.4 landed) + M1 starfield | `SubViewport` (own World3D, HDR), sky camera = cam JSON × ship basis | 0 (at infinity) |
| 3 | Panorama | `TextureRect` on a CanvasLayer | 0.15 |
| 4 | Play area GLB | main viewport, orthographic camera, toon + ink (spike shaders) | 1 |
| 5 | Foreground plate | `TextureRect` | 1.6 |
| — | HUD | CanvasLayer, top | — |

- **One tonemap.** The sky SubViewport renders in float (HDR 2D on) and
  tonemaps once in its own Environment (AgX plus M1.5 exposure). The parent
  composites the result as already display-referred: the iso environment must
  not tonemap or glow the canvas background again. Golden case G-M4-2 checks
  this. The spike's `BG_CANVAS` and AgX parent environment is the suspect
  configuration.
- **Velocity from the sim only.** Every frame takes `heading`, `beta`,
  `gamma` and `one_minus_beta` from state into the starfield and background
  uniforms. The spike's `_set_speed` and the synthetic `galaxy_sky.gdshader`
  band are **not** ported: the band is painted content. Until M1.4 lands, the
  sky is catalogue stars only.
- **Walking.** Click to move on the walk disc (later the `WALK_` navmesh). The
  captain is a static placeholder avatar (a capsule with a facing marker),
  following ai-showcase §4 (static mini avatars, no animation). The camera
  follows the captain and pans the layers by their factors. Avatar position is
  client state and never goes to the sim.
- **Interactables.** The navigation console opens the M2 galaxy map. The
  Archive terminal opens the news panel and the legacy log. Both also have
  keyboard shortcuts (M, L), so the 10-minute path never depends on pathing.

### M4.3 Transit, time warp, HUD and arrival

- **Time warp** is a player intent recorded by the sim (M2's input log), in
  ship-years per real second: `0.02`, `0.05` (default), `0.2`. Godot's tick
  loop turns real time into `advance` inputs; the replay uses the logged
  inputs, never wall time. At the default warp a 3.58 ship-yr leg takes about
  72 s, and both legs together about 2.4 min. Warp is available only while
  committed. Pause is a warp of 0 (the clocks stop with it, so pausing hides
  nothing; Time pillar).
- **HUD** (`ui/journey_hud.tscn`), every value bound through `DisplayBinding`
  (M4.5):
  - **Ship** `τ` (years aboard, captain's age as M2's placeholder) and
    **Earth** `t`, the same size and side by side;
  - `gap_years`, phase (burn / flip / decelerate), β to 4 decimals, γ to 3,
    distance remaining, Earth-yr to arrival;
  - warp level.
- **Flip** at the midpoint: M2's phase change. A legacy entry and a one-line
  HUD notice. Orientation during deceleration follows open question 1. The
  default keeps up = direction of travel (D-6), so the starbow stays overhead
  and visibly relaxes.
- **Arrival.** As β falls to 0 the sky relaxes to the rest-frame sky through
  the same camera. When M2 reports `arrived`, an arrival card shows the
  journey summary (journey-system Part 4, phases 1 and 3 only): distance, ship
  years, Earth years, gap. α Cen A and B are visible overhead or beside the
  dome.

### M4.4 News from home and the legacy log

- **The news beat** opens automatically after the arrival card (and from the
  Archive terminal afterwards). It is a text panel, "Transmission received",
  with a header line from fields, for example *"Latest news from Earth:
  Earth-year +1.6, already 4.4 years old."* The body is one template paragraph
  from `data/news/templates.json` (id → text with `{slot}` placeholders;
  numerals allowed only in slots, which a test enforces), or the AI-supplied
  text when one was accepted.
- **Tiers set the tone,** facts only and no verdicts (Pillar 2): a few months
  is family news; 1–5 years is elections, a niece starting school; 5–15 is a
  parent's illness or death, a new technology; 15–50 is a generation turned
  over; ≥50 is names nobody remembers. The copy is written for M4 and reviewed
  by Mark (S4).
- **AI path (optional, D-7/D-8/D-9).** When the AI service is running and the
  player has opted in, Godot relays the sim's `ai_request` (kind `news`,
  tier, template id, canon snippet, `max_chars`, "no numerals"). On a result,
  Godot sends the result back as a `record` intent as an input. The panel shows the template
  immediately and swaps to the accepted AI text only if it arrives before the
  player closes the panel. Whatever happened is in the log, so the replay
  matches. With no service, no key or a failure, the template stands and the
  log records `status: "fallback"`.
- **Return trip.** From α Cen the navigation console opens the map with Sol
  highlighted. The player still plans and commits (Pillar 1: the commit stays
  a real, separate act).
- **Legacy log screen** (end of slice). A chronological list of the log
  entries, a closing line from fields ("You were away 7.15 years. Home is
  11.97 years older."), and "Begin again", which starts a **new** voyage with
  a new seed (no reload).

### M4.5 Verification harness: playthrough, display audit, replay, timing

- **Scripted playthrough** (`make playthrough`, headless, real sim). A bot
  script (`tests/playthrough_min.json`) drives the minimum path through
  Godot's input layer, not by calling sim functions, so the UI wiring is under
  test. It writes `$(SCRATCH)/session.ndjson` (M2's input log plus AI results)
  and `display_samples.ndjson`.
- **Display audit** (`tools/display_audit.py`). Every HUD/panel `Label` that
  shows a number is registered as a `DisplayBinding{node_path, field, format}`.
  Each sampled frame records every visible label's text and the state tick it
  was built from. The audit fails when:
  - a number in a label does not equal `format(state[field])` at that tick
    (exact string match: same format, same rounding);
  - a visible label contains a digit and has no binding;
  - a binding's field is missing from the state.
  Template slots are bindings too.
- **Replay.** `make replay SESSION=$(SCRATCH)/session.ndjson` (M2's harness)
  re-runs the M4 session and compares state streams with `cmp`. `make
  parity-m4` runs it on `--bytecode` and on the interpreter. During a replay
  the AI service is never spawned; the harness asserts the process count.
- **Ten-minute proxy** (`tools/playthrough_time.py`, deterministic). Modelled
  time = the sim ticks spent at default warp × the tick period, plus 1.5 s per
  required click or keypress, plus reading time for every text shown at 200
  words per minute, plus 20 s of walking for each interactable visit. The
  proxy must be ≤ 360 s, which leaves 4 minutes for exploration and confusion
  inside the 10-minute bar. Each leg's transit must be 45–120 s at default
  warp.
- **Human playtest protocol** (in `docs/m4-playtest.md`, written during M4.5
  and run at stop point S3):
  - **Participants:** 3 people who have not seen the game or its docs.
    macOS build from `make export-macos`. The facilitator says one sentence
    only: "You're the captain; take the ship to Alpha Centauri and back."
  - **No hints.** If the player asks, answer "what would you try?" A player
    stuck for 90 s counts as a hint and is recorded.
  - **Timing:** the clock runs from the first frame of the bridge scene to
    the legacy-log screen. The build writes wall-clock times per mode to
    `user://playtest_timing.json`. This file is outside the replay and never
    read by the sim.
  - **Recorded per player:** total time, time per mode, hints, the moment
    they first noticed the two clocks diverge, and a one-line quote on the
    news beat.
  - **Pass:** all 3 finish in under 10 min with 0 hints. Results go to
    `design_docs/implemented/r1/m4-playtest.json` and the M4 report.

### M4.6 Physics gates, renders and bench

No new formula, so no package release is needed. The visuals are new
compositions of SR rendering, so CLAUDE.md gate 2 applies in full.

- **CPU (`tests/test_physics.gd`):**
  - `ship_basis` cases (M4.0);
  - CPU projection of a galactic direction through `cam_bridge.json` ×
    ship basis to a pixel (the golden reference);
  - the α Cen trip values: package `flipAndBurn` mirrored in GDScript at
    d = 4.37 gives 3.5824 / 6.0025 / 0.95166, and the stand-off case agrees
    with the sim's planner fields;
  - starfield flux at the arrival stand-off is finite for every tier star
    (no star within 100 AU of any stop point; a table-range check per gate 5).
- **`make lint-precision`** (new, in `make test`). A grep fails on
  `sqrt(1.0 -`, `1.0 - beta`, `1.0 - b` and on `1.0/sqrt` near `beta` in
  game GDScript and shaders outside `physics/` and `tests/`. It has a positive
  control fixture that must fail.
- **GPU golden (`make golden`):**
  - **G-M4-1, composite position.** A synthetic star at 6 galactic directions
    × β ∈ {0, 0.5, 0.9, 0.99} × pan ∈ {−5, 0, +5} m lands within 0.75 px of
    the CPU projection *in the final composited frame*. Its pixel is
    identical across the three pans (the sky is at infinity).
  - **G-M4-2, one tonemap.** A sky-only pixel (panorama alpha 0) in the
    composite equals the same pixel of the sky SubViewport within 1/255 per
    channel.
  - **G-M4-3, forward pole.** With the heading toward α Cen (from the sim),
    the aberrated position of a star dead ahead lands at the CPU-predicted
    pixel (the dome's forward pole) within 0.75 px.
- **Reference renders (`make capture-m4`)** to `renders/m4/`: the bridge,
  docked; β 0.5, 0.9 and peak (0.951) outbound; mid-deceleration (β 0.5);
  arrived at α Cen; arrived home. Pans −5/0/+5 for each, plus one contact
  sheet. ⏸ **S1: Mark looks at them** before the M4.2/M4.3 PR merges
  (gate 2).
- **Bench.** `make bench SCENE=bridge`: p99 frame time under 16.7 ms at
  2560×1440 on M4 Max with the M1 medium tier, over a 30 s scripted transit.
  The sky SubViewport renders at window resolution, not the camera JSON's
  3840×2160.

## Interfaces assumed

**From M2** ([m2-journey-core.md](m2-journey-core.md)). If M2's names differ,
M4 adopts M2's; these are the capabilities M4 needs, not a counter-design.

| Capability | Assumed shape |
|---|---|
| Handshake | M2: `hello` → `proto: {major: 2, minor}`; then `new_game{seed, scenario, epoch, start_age}`. M4 needs minor ≥ 1 (`record`) for live AI, and runs on 2.0 with templates only |
| Input | M2 §M2.1: `{type: "input", tick, dtau, intents: [...]}` with intents tagged by `k`: `plan{target, profile}`, `commit{plan_id}`, `cancel`; time warp is Godot choosing `dtau` per tick (≤ 1 ship-yr). A rule refusal is listed in `refused: [{i, reason}]` and the rest of the tick proceeds; a malformed input changes nothing |
| State | Change sets `ship{beta, gamma, phi, tau, t, pos, heading}`, `clock{tau, t}`, `journey{phase ∈ docked/planned/committed/burn/flip/decel/arrived, origin_id, target_id, plan{ship_years, earth_years, peak_beta, arrival_t, crew_age}, progress, distance_remaining}` |
| Commit rule | After `commit`, `plan`, a second `commit` or `cancel` until arrival is refused `committed` (M2 AC4), journey unchanged |
| Determinism | Named PCG/SplitMix streams; M4 asks for a `"news"` stream |
| Replay | `make replay SESSION=<file>`: the input log → state stream, `cmp`-identical; VM vs interpreter |
| Galaxy map | A Godot scene that emits `target_selected(star_id)` and shows plan fields from state, with a Commit button that sends `commit{}`; it accepts a preselected star (Sol on the return) |
| Arrival point | The target is at rest at a stand-off from the star, or M4.1 adds it (open question 2) |

**From the AI service foundation** (queue row 2, D-9; design pending). M4
uses only the text path:

| Capability | Assumed shape |
|---|---|
| Process | A separate AILANG process; Godot spawns and relays it; the sim never talks to it |
| Request | `{req: "text", id, kind: "news", entity_id: "earth", context{tier, template_id, canon, max_chars, constraints: ["no_numerals"]}}` |
| Result | `{id, status: ok/stub/fallback/error, text, markers?, model, cache_key}`; Godot forwards it as M2's reserved `record` intent (`source: "ai"`, `req`, `kind`, `sha256`, `body`), enabled in protocol 2.1 |
| Modes | `--ai-stub` (deterministic, no key, no spend) for tests; no-key → `fallback` at once |
| Recording | The result is recorded via the sim's input log; replay never contacts the service |

**If the foundation slips:** M4 ships with no AI process. Godot never spawns
one, every news beat uses the template, and the log records `fallback`. AC6
still runs its `digits` case through a fake-result fixture injected as an
input, so the sim-side validation is tested regardless. Portraits, emotion
markers and voice are not on M4's critical path.

## Acceptance criteria (all checkable by command)

| # | Criterion | Check |
|---|---|---|
| AC1 | Consequence closed forms: round trip Sol ⇄ α Cen (1 g flip-and-burn, default stand-off) gives Earth elapsed = 2 × `flipAndBurn(d−s).galaxyTime` and ship elapsed = 2 × `.shipTime` within 1e-9; news epoch at α Cen arrival = `t − (d−s)` within 1e-9; `gap_years` = `t − tau` exactly; strict VM = interpreter | `make sim strict` (`scriptedRoundTrip`) |
| AC2 | News tiers: fixtures hit all five tiers; template choice is identical across two runs with the same seed and differs for at least one of 10 other seeds; every template's numerals appear only in slots | `make sim tools-test` |
| AC3 | Commit is final in the real UI: the adversarial playthrough tries re-plan, cancel and the map Commit button mid-transit; each gets `committed` with state unchanged; no save/load path exists (`grep -rniE "save_game\|load_game\|ResourceSaver" interior ui` returns nothing) | `make playthrough SCRIPT=adversarial` |
| AC4 | Display audit over the full minimum playthrough: 0 mismatches, 0 unbound numerals, ≥ 500 samples, including both clocks on every transit sample | `make playthrough && tools/display_audit.py $(SCRATCH)/display_samples.ndjson` |
| AC5 | Replay byte-identical: the playthrough session (including `record` intents) replays `cmp`-identical; VM = interpreter; the AI service process count during replay is 0 | `make replay SESSION=$(SCRATCH)/session.ndjson && make parity-m4` |
| AC6 | AI optionality: the loop completes with `AI=none` (all `fallback`), `AI=stub` (accepted results recorded and shown) and `AI=digits` (rejected `ai_numeral`, template shown); in all three the display audit passes | `make playthrough AI=none`, `AI=stub`, `AI=digits` |
| AC7 | Ten-minute proxy ≤ 360 s; each transit leg 45–120 s at default warp | `make playthrough && tools/playthrough_time.py` |
| AC8 | Human playtest per the M4.5 protocol: 3 new players, all under 10 min, 0 hints | `tools/playtest_summary.py design_docs/implemented/r1/m4-playtest.json` (exit 0) |
| AC9 | CPU physics: `ship_basis`, projection reference, α Cen trip mirror (3.5824 / 6.0025 / 0.95166 at d = 4.37), finite flux at stand-offs; no hand-computed γ or 1−β in game code | `make test` (`physics`, `lint-precision`) |
| AC10 | GPU golden G-M4-1 (≤ 0.75 px, pan-invariant), G-M4-2 (≤ 1/255), G-M4-3 (≤ 0.75 px) | `make golden` |
| AC11 | Reference renders committed in `renders/m4/` and reviewed by Mark (sign-off line in the M4 report) | `make capture-m4`; `grep -n "S1 sign-off" design_docs/implemented/r1/m4-report.md` |
| AC12 | Bench: p99 < 16.7 ms at 2560×1440, bridge transit, M1 medium tier, M4 Max | `make bench SCENE=bridge` |
| AC13 | Area bundles valid (placeholder and any delivered bundle): alpha 0 where space shows, camera round trip ≤ 1 px, GLB metres/Y-up | `make validate-areas` |
| AC14 | `make test` green locally and in CI; `make strict` and every parity target green; M2's old-message tests unmodified and green | GitHub Actions `CI` |

## Sub-milestones and estimates

| ID | Scope | LOC (code + tests) | Depends on |
|---|---|---|---|
| M4.0 | Area bundle loader, placeholder bundle, `validate-areas`, `ship_frame` | 250 + 150 | — |
| M4.1 | `sim/consequence.ail`: Earth clock, light-delay epoch, display fields, news tier and stream, legacy log, `record` (AI result) validation, stand-off; `scriptedRoundTrip` | 350 + 300 | M2 protocol and planner |
| M4.2 | Interior scene, SubViewport composite, walking, interactables ⏸ S2 art sign-off at start | 400 + 100 | M4.0, M1.3/M1.5 |
| M4.3 | Transit loop, warp, HUD, flip, arrival card | 250 + 100 | M4.1, M4.2, M2 map |
| M4.4 | News panel, templates, AI relay with fallback, return trip, legacy screen ⏸ S4 copy review | 250 + 100 | M4.1, M4.3; AI foundation optional |
| M4.5 | Playthrough bot, display audit, replay/parity targets, time proxy, playtest protocol ⏸ S3 playtest | 150 + 300 | M4.3, M4.4, M2 replay |
| M4.6 | CPU tests, `lint-precision`, golden G-M4-1..3, `capture-m4`, bench ⏸ S1 render review | 100 + 150 | M4.2, M1.6b |
| | **Total** | **1,750 + 1,200 ≈ 2,950** | |

Order: M4.0 ∥ M4.1 → M4.2 → M4.3 → M4.6 (S1) → M4.4 (S4) → M4.5 (S3).
M4.0 and M4.1 can start as soon as M2's protocol lands. M4.1 does not need
the art.

**Mark stop points:**
- **S1:** composited reference renders (physics gate 2).
- **S2:** art for the slice: the placeholder blockout or the delivered Blender
  style frame (open question 5).
- **S3:** the human playtest (AC8).
- **S4:** news template copy and tone.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| M2 lands with different names or a different arrival rule | M4 adopts M2's names; M4.1 and M4.0 start only after M2's protocol merges; the stand-off is added in M4.1 only if M2 lacks it |
| Double tonemap or an 8-bit clamp in the composite dims the starbow (spec §2 HDR) | G-M4-2 checks it; the sky SubViewport is HDR with its own single tonemap |
| The ship-frame mapping puts the starbow in the wrong place, as the spike's hand axis swap could | One `ship_basis` function with CPU tests, plus G-M4-3 on the real α Cen heading |
| The destination star blows up (1/r²) or coincides with its companion (Problem 5) | Stand-off ≥ 1,000 AU; depend on M1.2 tiers, not the committed `stars.json`; finite-flux test at every stop point |
| The arrival sun saturates auto-exposure, so the rest of the sky vanishes | Accepted as physical; M1.5's player clamp is the readability aid; S1 review looks at the arrival frame specifically |
| AI text slips a number or a verdict onto the screen | The sim rejects digits (`ai_numeral`); prompts carry "no numerals, no verdicts"; templates are the default; AC6 |
| AI result timing makes replays differ | Results enter only as logged inputs at a tick; replay never spawns the service (AC5) |
| Headless Godot can't render the SubViewport | The display audit and playthrough use only labels and state, which work headless; pixels are only in `make golden`/`capture-m4` on the GPU rig |
| The time proxy doesn't predict real players | It's a regression guard only; AC8 is the real check and blocks landing |
| Placeholder art reads badly and players get lost | Keyboard shortcuts for both interactables; the 90 s stuck rule in the playtest shows it; S2 can swap in the Blender bridge without code change |
| SubViewport plus 331k stars plus toon pass misses 60 fps | The sky renders at window resolution; bench uses the medium tier; the large tier is optional in the interior |

## Open questions (for the user)

1. **Orientation during deceleration.** At the flip, does the ship turn over
   (felt gravity stays "down" to the engines, so the bridge dome faces astern
   and the starbow sits under the ship), or does up stay the direction of
   travel all journey (D-6's literal wording; the bubble supplies the felt
   1 g)? **Recommendation:** up stays the direction of travel. The starbow
   stays overhead and visibly relaxes, which is the arrival beat the roadmap
   asks for. It needs one canon line in `vision/design-decisions.md`.
   **Default:** that.
2. **Arrival stand-off.** How far from the star does a journey end?
   **Recommendation:** 1,000 AU. α Cen A at about magnitude −12, A and B
   about 1.3° apart, finite flux; the trip is 4.354 ly instead of 4.37.
   **Default:** 1,000 AU, unless M2 has already fixed a value.
3. **Earth calendar.** Relative years ("Earth +6.0 yr") or an absolute date
   (CE year of departure)? The canon leaves Earth's reality ambiguous
   (design-decisions 2025-12-02). **Recommendation:** relative years in R1.
   **Default:** relative.
4. **A crew face in the news beat?** **Recommendation:** M4 shows the news as
   an Archive-terminal text panel only. If the AI foundation's (c) milestone
   (the Medic style frame) has been approved by M4.4, add one templated Medic
   reaction line with portrait swaps, text only, as a stretch. **Default:**
   panel only.
5. **Art for the slice (S2).** If the Blender bridge style frame (brief §7
   step 1) is not approved when M4.2 starts, ship the slice on the spike
   blockout, flagged placeholder? And bridge only, or a second area?
   **Recommendation:** yes, the blockout; bridge only. **Default:** that.
6. **Who runs the playtest (S3)?** It needs 3 people who have never seen the
   game, run by you or someone you pick, with the protocol in M4.5.
   **Recommendation:** you recruit 3; the loop prepares the build, the
   protocol and the summary tool. **Default:** everything else lands; AC8
   stays open and clause 4 stays UNMET until the playtest is run.
7. **Docked time.** In M4 no time passes while docked or planning, which the
   Time pillar excludes ("pausing the universe while you decide").
   **Recommendation:** accept for R1 as a slice simplification, and revisit
   when the civilisation sim exists. **Default:** accept, with a line in the
   M4 report.

## Deliverables

- Sim: `sim/consequence.ail` (pure, strict-VM), protocol additions in
  `sim/ship.ail`, `scriptedRoundTrip`, consequence and tier tests.
- Godot: `interior/` (`area_bundle.gd`, `ship_frame.gd`, `interior.tscn`,
  toon and outline shaders promoted from the spike), `ui/journey_hud.tscn`,
  news panel, arrival card, legacy log screen, `DisplayBinding`, the AI relay
  (optional path).
- Assets: `assets/areas/bridge/` (the placeholder bundle in brief §9 format),
  `data/news/templates.json`.
- Tools and targets: `make playthrough`, `parity-m4`, `capture-m4`,
  `validate-areas`, `lint-precision`, `bench SCENE=bridge`;
  `tools/display_audit.py`, `playthrough_time.py`, `playtest_summary.py`,
  `validate_area.py`; `tests/playthrough_min.json`, `adversarial.json`;
  `docs/m4-playtest.md`.
- Report: `design_docs/implemented/r1/m4-report.md` (renders with the S1
  sign-off, bench, proxy time, playtest results, upstream AILANG reports) and
  `m4-playtest.json`.

## Verification log

Run on 2026-10-01 at `e9d35c5` (main) and `fe16790`
(`origin/spike/iso-bridge`), read-only.

| # | Claim | Command | Observed | Verdict |
|---|---|---|---|---|
| V1 | `main` has no interior or compositing | `grep -rln SubViewport main.gd sky bridge tests`; `ls assets` | no hits; `assets` does not exist | True |
| V2 | The iso spike exists only on the branch, with fixed speeds and heading | `git show origin/spike/iso-bridge:spike/interior3.gd \| grep -n "HEADING :=\|SPEEDS"` | `:17 HEADING := Vector3(0, 0, -1)`, `SPEEDS := [0.0, 0.99]` | True |
| V3 | The spike computes γ in GDScript | same file, `grep -n "sqrt(1.0"` | `:176 var g := 1.0 / sqrt(1.0 - b * b)` | True: not ported |
| V4 | The package already has γ and 1−β from rapidity, and closed-form trips | `grep -n "export pure func" ~/.ailang/cache/registry/sunholo/relativity/0.3.0/{kinematics,journey}.ail` | `gammaOf(phi)`, `oneMinusBeta(phi)`; `flipAndBurn`, `burnCoastBurn`, `coastAt` | True: M4 needs no package release |
| V5 | The sim has no journey, Earth or log state | `grep -n "type Ship" sim/core.ail` | `Ship = { tick: int, motion: Motion, heading: Vec3, origin: Vec3, x0: float }` | True (M2 adds the journey) |
| V6 | α Cen A/B coincide in the committed catalogue | `python3` over `data/starmap/stars.json` for `Gl 559` | two rows, both `x 1.5, y −4.09, z −0.05, dist 4.35`, V 0.01 and 1.34 | True: M4 depends on M1.2 tiers |
| V7 | Trip numbers | `python3`, the `flipAndBurn` formula with g = 1.032295275553596 ly/yr² | d 4.37: 3.58239 / 6.00250 / 0.951656; d 4.354187 (1,000 AU stand-off): 3.57728 / 5.98588 / 0.951406; news epoch 1.6317; round trip Earth 11.9718, ship 7.1546, gap 4.8172 | Matches the roadmap example at d = 4.37 |
| V8 | The camera contract exists in the spike | `git show origin/spike/iso-bridge:spike/v2/cam_bridge.json` | `fov_vertical_deg 78`, ship frame "+Z = direction of travel", `resolution [1920, 1080]` | True (the brief asks for 3840×2160 deliveries; the loader reads either) |
