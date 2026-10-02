# M4: First journey, a vertical slice

**Status:** Planned (design, awaiting sprint plan). Revised 2026-10-01 for
Mark's attended rulings D-11, D-12 and D-14: boost → cruise → brake with no
flip, 0.99c default cruise, the ISM readout and forward glow, art stop S2 now
blocks the interior, the human playtest moves to R2, and the Archive codex
teaches the physics in-game.
**Release:** r1 · **Milestone:** M4 of [R1 foundations](https://github.com/sunholo-data/stapledons-design/blob/main/roadmap/r1-foundations.md) (bar clause 4, as amended by D-14)
**Priority:** P0: the first time the game is a game
**Implements:**
- Roadmap §M4 items 1–5, with item 2 **superseded by ledger D-6**: the
  "placeholder painted deck scene" becomes the isometric three-layer interior
  ([ship-interior-blender-brief](https://github.com/sunholo-data/stapledons-design/blob/main/art/ship-interior-blender-brief.md) §2, §5, §9).
- [viewport-compositing](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase1-data-models/viewport-compositing.md)
  (the idea only; no Go port), [journey-system](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase3-gameplay/journey-system.md)
  Parts 3–4 stubbed, [ai-showcase](https://github.com/sunholo-data/stapledons-design/blob/main/features/ai-showcase.md)
  §2 "News from home" and §5 (AI results are recorded inputs; D-7, D-8).
- [higgs-bubble](https://github.com/sunholo-data/stapledons-design/blob/main/physics/higgs-bubble.md)
  (`../stapledons-design/physics/higgs-bubble.md`, check values **HB-n**),
  written from D-11: the journey profile, the elastic-mirror ISM model, the
  faint forward glow (inelastic fraction ε), the forward CMB.
- [Archive lore](https://github.com/sunholo-data/stapledons-design/tree/main/lore/archive)
  (`../stapledons-design/lore/archive/*.md`, front matter `id, title, unlock,
  checks:`): Mark's "physics education … available in-game lore" (D-11).
- [relativity spec](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md)
  §2 (HDR, float64 γ and 1−β, finite tables) and §4 (golden tests, reference
  renders), applied to the composited interior view.

**Depends on:**
- **M2** journey core ([m2-journey-core.md](../../implemented/r1/m2-journey-core.md), revised in
  parallel for D-11): boost → cruise at the chosen speed → brake, the plan
  intent carrying the cruise speed, planner energy/ISM/CMB readouts, protocol
  v2, the sim-owned commit rule, replay harness, galaxy map. Hard dependency;
  M4 extends it. See [§Interfaces assumed](#interfaces-assumed).
- **M1**: M1.2 tiers (α Cen A and B need real astrometry; Problem 5), M1.3
  rebasing, M1.5 exposure, M1.6b camera golden. M1.4 background landed
  2026-10-01 (PR #16).
- **Blender bridge style frame** (brief §7 step 1). **Hard dependency for the
  interior** (D-14): no interior ships on the spike blockout. Non-art work
  proceeds without it ([§Order](#sub-milestones-and-estimates)).
- **AI service foundation** (queue row 2, D-9). Soft: M4 is fully playable on
  templated text.

**Estimated:** ~3,200 LOC (≈1,900 code + 1,320 tests/tools), 9
sub-milestones (M4.3 splits into a/b). The human-playtest tooling leaves (−150); the codex and
lore check (+300) and ISM/glow (+50) arrive.
**Evidence:** codebase claims are in the [Verification log](#verification-log),
pinned to `e9d35c5` (main) and `fe16790` (`origin/spike/iso-bridge`); the
recomputed numbers are in rows V7, V9–V11.

## Game vision alignment

| Pillar | Relevance | Score | Notes |
|---|---|---|---|
| Choices Are Final | ++ | +2 | Commit is the centrepiece (D-12 ritual: both clocks, years left at home, 1.5 s hold); the sim rejects cancel mid-journey; no save/load |
| The Game Doesn't Judge | + | +1 | News, legacy log and lore state facts only; copy reviewed at S4 |
| Time Has Emotional Weight | ++ | +2 | Both clocks on screen all journey, and they run while docked (D-12). The crew ages 227 days per leg while home ages 4.4 years; news at α Cen is 4.35 years stale; home is 8.8 years older on return, 7.6 more than the crew |
| The Ship Is Home | + | +1 | The player walks the approved bridge under the forward pole; no crew dialogue keeps this at +1 |
| Grounded Strangeness | + | +1 | The starbow gathers overhead, the wall glows faintly forward, both relax on arrival |
| We Are Not Built For This | 0 | 0 | No crew psychology in R1. The ISM readout (163 suns of forward load, 1.5 kg of drag energy per leg) hints at it |
| Hard sci-fi authenticity (spec) | ++ | +2 | The bubble is the one admitted hand-wave (D-11); every number on screen and in the Archive is a sim field or a checked value |
| **Net** | | **+9** | **Go.** The first draft's docked-time tension is gone: D-12 runs the clock at rest |

## Problem

R1 has a sky (M1) and will have a journey core (M2), but nothing playable:

1. **No interior on `main`** (V1). The iso interior is only on
   `spike/iso-bridge` (V2), with hand-set speeds and heading.
2. **The spike breaks the precision gate:** `spike/interior3.gd:176` computes
   γ in GDScript (V3); the package already exports `gammaOf`/`oneMinusBeta` (V4).
3. **The sim has no Earth, news or log** (V5).
4. **Nothing proves what's on screen,** in the HUD or in explanatory text. The
   physics the bubble implies (D-11) has no in-game home, and nothing would
   stop lore numbers drifting from the package.
5. **The destination breaks the starfield:** α Cen A and B share one position
   at 0.01 ly (632 AU) precision (V6). M1.2 fixes precision; M4 fixes where
   the ship stops.
6. **The roadmap's painted interior is superseded** by D-6; no game code
   loads the brief's bundle format (§9).
7. **The first draft's journey is obsolete.** It assumed a 1 g flip-and-burn
   (3.58 ship-yr per leg) and a flip beat. Under D-11 the pocket's
   acceleration is not felt: boost (minutes) → cruise → brake, no flip.

## Goals

- **G1.** One loop: bridge at Sol → galaxy map → pick α Cen → plan (cruise
  0.99c by default) → commit → boost → cruise → brake → arrival → news →
  map → commit Sol → transit → home → news → legacy log.
- **G2.** Transit in the approved iso interior with the live relativistic
  sky composited through the panorama camera, time warp, and a HUD with ship
  time, Earth time and the ISM readout.
- **G3.** A consequence stub in the pure sim: Earth's clock, light-delayed
  news, a news tier, an append-only legacy log, archive unlocks.
- **G4.** Every number on screen is a formatted sim field (display audit),
  and every number in the Archive is a check value (`make lore-check`).
- **G5.** The session replays byte-identically, including AI results, on the
  VM and the interpreter.
- **G6.** The under-10-minutes bar is met by the deterministic minimum-path
  proxy in `make test` (D-14).
- **G7.** The Archive codex: the design repo's physics lore, imported into
  the game, unlocked by sim events.

**Non-goals:**
- **The 3-new-player human playtest. Moved to R2 (D-14)**, with its protocol
  (no hints, 90 s stuck rule, per-mode timing). Bar clause 4 is amended.
- Crew events, dialogue (R2); live AI as a requirement (D-8); voice; more
  than one play area; planets; Terrell rotation; a civilisation model.
- An enforced energy budget. Drag energy and boost energy are readouts
  (D-11); the budget comes later with M2's m_eff + energy ledger.
- The forward CMB disc. It is invisible at the slice default (38 K at
  γ 7.09) and visible only from γ ≈ 275; rendering it is a renderer gap
  (open question 2).
- Shipping any interior on the spike blockout (D-14).

## Design

ADR 0001 holds. **The sim owns state and rules; Godot owns presentation.**
Godot does no arithmetic on physics or clock values.

### M4.0 Area bundles and the frame contract

- **Area bundle loader** (`interior/area_bundle.gd`) reads brief §9 from
  `assets/areas/<area>/`: `manifest.json`, `cam_<area>.json`,
  `pano_<area>.png`, `play_<area>.glb`, `fg_<area>.png`; validates the schema
  and refuses a bundle with a missing layer.
- **Test fixture, not shipping art.** The spike's bridge files
  (`spike/v2/bridge_slice.glb`, `cam_bridge.json`,
  `stapledon_pano_bridge.png`, `spike/v3/stapledon_fg_bridge.png`) are copied
  from `origin/spike/iso-bridge` into **`tests/fixtures/areas/bridge_blockout/`**
  with a hand-written `manifest.json` (parallax 0.15 / 1.6, `iso_pitch_deg
  −14`, `iso_yaw_deg 45`, `iso_size_m 16`, focus `[−8, 1, 9]`, a flat walk
  disc, two `INTERACT_` stand-ins, `placeholder: true`). Loader, validator,
  walking and the playthrough bot are developed against it. `assets/areas/bridge/`
  holds the current bundle (blockout until the bridge v1 bundle arrives); a
  `placeholder: true` bundle shows a small "placeholder art" tag in the HUD so
  review builds say what they are.
- **`make validate-areas`** (`tools/validate_area.py`): alpha exactly 0
  where space shows; camera JSON schema; camera round trip within 1 px; GLB
  Y-up in metres. Runs on the fixture and any delivered bundle.
- **Frame contract** (`interior/ship_frame.gd`, float64): ship +Z = direction
  of travel, origin = bubble centre, metres (brief §5.2). **Up = direction of
  travel for the whole journey** (D-14): there is no flip, so the dome's
  forward pole always faces the heading. `ship_basis(heading)` maps the sim's
  unit heading to ship +Z; roll projects the north galactic pole onto the
  plane normal to the heading (fallback galactic +X within 1e-6 of a pole).
  The sky camera is `ship_basis(heading) × cam.forward/up`. CPU tests:
  orthonormal to 1e-12, heading → +Z, pole fallback.

### M4.1 Sim: consequence stub and session extensions (pure core)

A pure module `sim/consequence.ail` beside M2's journey state; I/O stays in
`sim/ship.ail`; `make strict` gains `scriptedRoundTrip`.

- **Earth clock.** `earth.t` = galaxy coordinate time at Sol = M2's world
  clock. While docked or planning the clock runs at rest at M2's fixed host
  rate, so τ and t advance together and the gap does not change (D-12).
- **The journey (from M2, D-11).** Boost to the cruise rapidity in minutes of
  ship time, cruise, brake. For Sol → α Cen with the 1,000 AU stand-off
  (d − s = 4.37 − 0.0158125 = **4.354187 ly**) at the default **β = 0.99**
  (γ = 7.088812, φ = 2.646652): **4.398169 Earth-yr and 0.620438 ship-yr
  (226.6 ship-days) per leg** in the τ_b → 0 limit. A boost of τ_b minutes
  covers (c/a)(γ − 1) ≈ 4.4 × 10⁻⁶ ly per minute and adds 1.25 × 10⁻⁶
  Earth-yr and 2.56 × 10⁻⁶ ship-yr per minute of τ_b (V9); the sim's numbers
  are the package trip function's, whatever τ_b M2 fixes. The first draft's
  1 g flip-and-burn (3.5773 ship-yr, 5.9859 Earth-yr, peak β 0.95141) remains
  a package check value, not the gameplay profile.
- **Light-delayed news epoch.** At an event at ship position `p` and galaxy
  time `t`, the newest receivable Earth news is from `t_e = t − |p − p_Sol|`
  (c = 1). At α Cen arrival (zero dwell) `t = 4.398169`, so **`t_e` =
  0.043982 Earth-yr (16.1 days) after departure** and the news is 4.354 years
  old (old: `t_e` 1.632, age 4.354).
- **Displayed quantities as fields.** The sim emits every number the UI
  shows: `gap_years = t − tau`, `news_epoch`, `news_age_years`, progress,
  `one_minus_beta` (package), and the ISM readout (below). Godot never
  subtracts two fields.
- **ISM readout (D-11; from M2's planner/state, else added here).** The wall
  is an elastic mirror for massive particles. The sim computes from a
  constant Local-Bubble density n = 0.1 cm⁻³ and bubble cross-section
  A = π (100 m)², using package functions whose values are HB rows: forward
  load n γ²β² m_p c³ (**2.22 × 10⁵ W/m², 163 suns at 0.99c**), drag force
  n γ²β² m_p c² A (23.26 N; a specular sphere, half a flat mirror, per higgs-bubble.md), drag energy accumulated this leg over the coast distance (**1.365 ×
  10¹⁷ J = 1.52 kg mass-energy per leg at 0.99c**), and `glow_w_m2` = ε ×
  load, ε being higgs-bubble.md's inelastic fraction. Boost energy per kg of
  m_eff, c²φ = 2.38 × 10¹⁷ J at 0.99c, is on M2's planner. All readouts; no
  budget is enforced (non-goal).
- **News tier.** `newsTier(elapsed since departure at t_e)` maps to `<1`,
  `1–5`, `5–15`, `15–50`, `≥50` Earth-years; a template id comes from the
  named PCG stream `"news"`. The sim emits `news{tier, template_id,
  slots{...}, ai_request_id}`. **α Cen now hits `<1`** (old `1–5`); the return
  hits `5–15` (unchanged: t = 8.796 at Sol, plus dwell). Fixtures cover all
  five.
- **Legacy log.** Append-only; entries `{tick, kind, star_id, tau, t,
  gap_years}` for departure, commit, boost, cruise, brake, arrival, news,
  archive unlock, return (no flip). Emitted as a change set, never rewritten
  (Pillar 1); rendered at the end, never scored (Pillar 2).
- **Archive unlocks (M4.7).** `new_game` carries the codex table
  `archive: [{id, unlock}]` from the imported lore. On each matching event
  the sim appends the id to `archive.unlocked` (change set) and logs it.
  Unlock state is sim state, so it replays.
- **AI results are inputs.** A `record{source: "ai", req, kind, sha256,
  body}` intent (M2 protocol 2.1) is accepted only for an open
  `ai_request_id`. Text with any digit or longer than `max_chars` is rejected
  (`ai_numeral` / `ai_length`) and the template stands.
- **Arrival stand-off: 1,000 AU** from the target star (D-14), on the
  approach line. α Cen A is then about magnitude −12; A and B about 1.3°
  apart. If M2 owns the stand-off, M4 checks its value is 1,000 AU.
- **Protocol.** Additive change sets and intents on M2's protocol (a minor
  bump); M2's old-message tests stay green unmodified.

### M4.2 The iso interior with the live sky (art is swappable data)

**Art is data, iterated in review** (D-16, and Mark 2026-10-01: "get something
up so I can review it, and then we can tweak as we go"). Bridge style frame v1
is approved for build-out (D-16). M4.2 is built and merged against whatever area
bundle is current: the spike blockout first, then the bridge v1 bundle, then
later revisions. Swapping a bundle is a data drop validated by
`make validate-areas`, never a code change. Each swap produces a review build
and captures for Mark.

| # | Layer | Node | Pan factor |
|---|---|---|---|
| 1–2 | M1 background + starfield | `SubViewport` (own World3D, HDR), sky camera = cam JSON × ship basis | 0 |
| 3 | Panorama | `TextureRect` on a CanvasLayer | 0.15 |
| 4 | Play area GLB | main viewport, orthographic, toon + ink | 1 |
| 5 | Foreground plate | `TextureRect` | 1.6 |
| — | HUD | CanvasLayer | — |

- **One tonemap.** The sky SubViewport renders in float and tonemaps once
  (AgX + M1.5 exposure); the parent must not tonemap or glow it again
  (G-M4-2).
- **Velocity from the sim only:** `heading`, `beta`, `gamma`,
  `one_minus_beta` from state each frame. The spike's `_set_speed` and painted
  galaxy band are not ported.
- **Forward glow.** A dome overlay (additive, in the sky SubViewport before
  the tonemap) draws the wall's glow from `glow_w_m2`. Profile: a sphere in a
  forward beam receives flux ∝ max(0, cos θ) from the travel direction, so
  radiance ∝ max(0, cos θ); zero at β = 0; spectrum per higgs-bubble.md. It is
  faint by design (small ε) and disappears as the ship brakes.
- **Walking** on the bundle's `WALK_` navmesh, static captain avatar
  (ai-showcase §4); avatar position never goes to the sim.
- **Interactables:** navigation console → M2 galaxy map; Archive terminal →
  news, legacy log, codex. Keyboard shortcuts M, L and K (codex) keep the
  minimum path independent of pathing.

### M4.3 Transit, time warp, HUD and arrival

- **Time warp** is a recorded intent (M2's input log) in ship-years per real
  second: `0.002`, **`0.01` (default)**, `0.05` (old default 0.05). A 0.99c
  leg takes **62.0 s** at the default (old: 71.5 s for a 3.58 ship-yr leg).
  Boost and brake last minutes of ship time, so Godot plays each over a fixed
  **3 s** of real time by choosing `dtau` (logged, so it replays). Warp exists
  only while committed. **No pause** (D-12): docked and planning time runs at
  M2's host rate.
- **HUD** (`ui/journey_hud.tscn`, every value through `DisplayBinding`):
  ship `τ` and Earth `t`, same size, side by side; `gap_years`; phase
  (boost / cruise / brake); β to 4 decimals, γ to 3; distance remaining;
  Earth-yr to arrival; **ISM**: forward load (W/m² and suns), drag energy
  this leg (J and kg), glow on/off; warp level.
- **Orientation:** up = direction of travel throughout (D-14). The starbow
  forms overhead during the boost, holds during cruise, and relaxes through
  the brake to the rest-frame sky. The brake is a legacy entry and a one-line
  HUD notice; there is no turnover.
- **Arrival.** On `arrived`, a card shows distance, ship years, Earth years,
  gap (journey-system Part 4, phases 1 and 3). α Cen A and B are overhead or
  beside the dome.

### M4.4 News from home and the legacy log

- **The news beat** is a text panel at the Archive terminal only (D-14),
  opened after the arrival card and later from the terminal: "Transmission
  received", a header from fields (*"Latest news from Earth: Earth-year
  +0.04, already 4.35 years old."*), and one template paragraph from
  `data/news/templates.json` (numerals only in slots), or accepted AI text.
- **Tiers set the tone,** facts only: under a year is family news; 1–5 is
  elections, a niece starting school; 5–15 a parent's illness or death, a new
  technology; 15–50 a generation turned over; ≥50 names nobody remembers.
  Copy reviewed by Mark (S4).
- **Calendar:** relative ("Earth +4.40 yr"); epoch and `start_age` (30) are
  scenario parameters (D-12).
- **AI path (optional):** results return as `record` intents; the panel swaps
  to accepted AI text only before close; otherwise the template stands
  (`fallback` logged). **Return trip:** the map opens with Sol highlighted;
  the player plans and commits through the D-12 ritual again.
- **Legacy log screen.** The entries, a closing line from fields ("You were
  away 1.24 years. Home is 8.80 years older." at zero dwell; old 7.15 /
  11.97), and "Begin again" (a new voyage, new seed, no reload).

### M4.5 Verification harness: playthrough, display audit, replay, timing

- **Scripted playthrough** (`make playthrough`, headless, real sim): a bot
  (`tests/playthrough_min.json`) drives the minimum path through Godot's
  input layer. Writes `$(SCRATCH)/session.ndjson` and
  `display_samples.ndjson`. Runs on the fixture bundle until S2, then on the
  approved bundle; landing needs the latter.
- **Display audit** (`tools/display_audit.py`): every numeric label is a
  `DisplayBinding{node_path, field, format}`; fails on a number ≠
  `format(state[field])` at that tick, an unbound digit, or a missing field.
  Codex text is a `LoreBinding{entry_id}`: the shown body must hash-equal the
  imported entry, whose numbers `make lore-check` vouches for.
- **Replay:** `make replay SESSION=…` compares state streams with `cmp`;
  `make parity-m4` on VM and interpreter; the AI service is never spawned.
- **Ten-minute proxy** (`tools/playthrough_time.py`, deterministic, the R1
  acceptance for the bar, D-14). Modelled time = sim ticks at default warp ×
  tick period + 1.5 s per click or key (the commit hold counts 1.5 s) +
  reading at 200 wpm for every text shown + 20 s walking per interactable
  visit. Budget at the defaults:

  | Item | Seconds |
  |---|---|
  | Two cruise legs at 0.01 ship-yr/s (2 × 62.04) | 124.1 |
  | Boost and brake, 4 × 3 s | 12.0 |
  | ~16 clicks/keys incl. two 1.5 s commit holds | 24 |
  | Reading ≤ 300 words (2 commit dialogs, 2 arrival cards, 2 news panels, unlock toasts, legacy screen) | ≤ 90 |
  | Walking, 4 interactable visits | 80 |
  | **Total** | **≤ 330 (limit 360)** |

  Codex entries are optional reading and are not on the minimum path. Each
  leg must be 45–120 s at default warp. The first draft's transit share was
  143.1 s (2 × 71.5).

### M4.6 Physics gates, renders and bench

No new formula in M4: trip, ISM and glow functions come from the package via
M2 and higgs-bubble.md. The visuals compose SR rendering and the glow is
driven by a relativistic load, so CLAUDE.md gate 2 applies in full.

- **CPU (`tests/test_physics.gd`):** `ship_basis` cases; projection of a
  galactic direction through `cam_bridge.json` × ship basis; the α Cen cruise
  mirror (γ(0.99) = 7.088812050083355; per leg 4.398169 Earth-yr, 0.620438
  ship-yr in the τ_b → 0 limit, the sim's planner within its boost
  correction); the ISM load at 0.99c (2.2196 × 10⁵ W/m², the HB row's value)
  and the glow profile function; finite flux at every stop point (no star
  within 100 AU; gate 5).
- **`make lint-precision`** (in `make test`): greps for `sqrt(1.0 -`,
  `1.0 - beta`, `1.0 - b` and `1.0/sqrt` near `beta` in game code outside
  `physics/` and `tests/`, with a positive-control fixture.
- **GPU golden (`make golden`):**
  - **G-M4-1, composite position.** A star at 6 directions × β ∈ {0, 0.5,
    0.9, 0.99} × pan ∈ {−5, 0, +5} m within 0.75 px of the CPU projection in
    the final frame, pan-invariant.
  - **G-M4-2, one tonemap.** A sky-only pixel equals the SubViewport's within
    1/255.
  - **G-M4-3, forward pole.** A star dead ahead on the α Cen heading lands on
    the dome's forward pole within 0.75 px, during boost, cruise and brake (no
    flip).
  - **G-M4-4, glow.** At β = 0.99 the overlay's radiance at θ = 0°, 45°, 80°
    matches the CPU profile within 1 %; at β = 0 it is exactly 0.
- **Reference renders (`make capture-m4`)** to `renders/m4/`: docked; boost
  through β 0.5 and 0.9; cruise at 0.99 (γ 7.09, with glow); brake at β 0.5;
  arrived at α Cen; arrived home. Pans −5/0/+5 and a contact sheet, on the
  approved bundle. ⏸ **S1: Mark looks at them** before M4.2/M4.3 merge.
- **Bench:** `make bench SCENE=bridge`, p99 < 16.7 ms at 2560×1440, M4 Max,
  M1 medium tier, 30 s scripted transit.

### M4.7 The Archive codex: physics as in-game lore

Mark (D-11): "physics education … available in-game lore". The Archive
explains the bubble and everything it implies, and its numbers cannot drift.

- **Import.** `make lore-import` copies `../stapledons-design/lore/archive/*.md`
  into **`data/lore/archive/`** and writes `data/lore/manifest.json` (design
  repo commit sha, per-file sha256). The game never reads the design repo at
  run time. `make lore-import CHECK=1` fails if the sibling checkout's files
  differ from the vendored copy at the recorded sha (skipped with a notice
  when the sibling is absent, as in CI).
- **Format.** Front matter `id, title, unlock, checks:`; body Markdown.
  `unlock` is `start` or `event:<kind>[@<star_id>]`, with kinds from the sim's
  legacy and archive events: `commit`, `boost`, `cruise`, `brake`, `arrival`,
  `news`, `return`, and M3's `bh_enter`, `bh_hover`, `bh_ring`. `checks` lists
  check-value ids.
- **Codex UI** (`ui/archive/codex.tscn`, `lore_loader.gd`): a third tab at
  the Archive terminal; locked entries show their title greyed; unlocked ones
  render a Markdown subset (headings, emphasis, lists, tables) into a
  `RichTextLabel`. A toast announces each unlock. Unlocks come only from the
  sim's `archive.unlocked` (M4.1), so they replay.
- **Expected slice unlocks** (the design repo owns the list): the bubble
  (start), photon drive (boost), starbow and ISM/glow (cruise), time
  dilation (arrival), light-delayed news (news); M3's black-hole entries
  unlock in the M3 demo.
- **Check-value registry** (`make lore-values` → `data/lore/check_values.json`,
  each value with id, unit and source). Three sources: (a)
  `sim/tools/lore_values.ail`, strict VM, which **evaluates the package
  functions** for each package check id (e.g. `rel:check51`); (b) the HB table
  in `../stapledons-design/physics/higgs-bubble.md` (vendored at import), ids
  `HB-n`; (c) the `CHECKS` dictionary exported by `tests/test_physics.gd`,
  dumped headless (ids `phys:<name>`). Where an HB row has a package
  function, (a) and (b) must agree to the HB row's printed precision, so the
  design doc cannot drift from the package either.
- **`make lore-check`** (`tools/lore_check.py`, in `make test`). For every
  entry: front matter is valid; every `checks` id exists in the registry;
  `unlock` names a known event kind; and **every number in the body binds to
  one of the entry's listed checks**. A number (decimal, thousands separator,
  `× 10ⁿ`, `e±n`) matches when the check value rounded to the shown
  significant figures equals the shown number and the unit after it equals
  the check's unit (with a fixed conversion table: g ↔ m/s², J ↔ kg
  mass-energy, yr ↔ days, ly ↔ AU, suns ↔ W/m² at 1361). A number with no
  binding fails, exactly like an unbound HUD numeral; non-physics counts are
  spelled out, and citation years sit inside `[cite: …]`, which is skipped. A
  positive-control fixture (`tests/fixtures/lore/drifted.md`, one number off
  in its last digit) must fail.

## Interfaces assumed

**From M2** ([m2-journey-core.md](../../implemented/r1/m2-journey-core.md)). If M2's names differ,
M4 adopts M2's.

| Capability | Assumed shape |
|---|---|
| Handshake | `hello` → `proto: {major: 2, minor}`; `new_game{seed, scenario, epoch, start_age, archive}`. Minor ≥ 1 (`record`) for live AI |
| Input | `{type: "input", tick, dtau, intents: [...]}`; intents `plan{target, profile{cruise_beta or cruise_phi}}`, `commit{plan_id}`, `cancel`; refusals in `refused: [{i, reason}]` |
| Clock at rest | While docked/planning, Godot sends `dtau` at M2's fixed host rate; no pause (D-12) |
| State | `ship{beta, gamma, phi, one_minus_beta, tau, t, pos, heading}`, `journey{phase ∈ docked/planned/committed/boost/cruise/brake/arrived, plan{ship_years, earth_years, cruise_beta, gamma, energy_per_kg, ism_energy_j, arrival_t, crew_age}, progress, distance_remaining}`, `ism{n, load_w_m2, drag_n, drag_energy_j, glow_w_m2}` |
| Commit rule | After `commit`, `plan`, a second `commit` or `cancel` are refused `committed` until arrival |
| Determinism / replay | Named PCG streams (M4 asks for `"news"`); `make replay SESSION=…`, VM vs interpreter |
| Galaxy map | Emits `target_selected(star_id)`, shows plan fields, cruise-speed control (0.9c–0.999999c, default 0.99c), the D-12 commit dialog; accepts a preselected star |
| Arrival point | At rest 1,000 AU short of the star (D-14) |

**From the AI service foundation** (text path only): a separate process
relayed by Godot; request `{req: "text", id, kind: "news", context{tier,
template_id, canon, max_chars, constraints: ["no_numerals"]}}`; result
forwarded as `record`; `--ai-stub` for tests. If it slips, M4 ships with no
AI process and AC6's `digits` case uses an injected fixture.

## Acceptance criteria (all checkable by command)

| # | Criterion | Check |
|---|---|---|
| AC1 | Round trip Sol ⇄ α Cen, boost → cruise 0.99c → brake, 1,000 AU stand-off, zero dwell: Earth elapsed = 2 × the package trip function's `galaxyTime`, ship = 2 × `shipTime` within 1e-9, and within 1e-4 of the τ_b → 0 values 8.796338 / 1.240876; news epoch at α Cen = `t − (d−s)` within 1e-9; `gap_years` = `t − tau` exactly; dwell adds equally to τ and t; strict VM = interpreter | `make sim strict` (`scriptedRoundTrip`) |
| AC2 | News tiers: fixtures hit all five; α Cen is `<1`, the return `5–15`; template choice seeded and replayable; numerals only in slots | `make sim tools-test` |
| AC3 | Commit is final in the real UI: re-plan, cancel and Commit mid-transit each get `committed`, state unchanged; no save/load path | `make playthrough SCRIPT=adversarial`; `! grep -rniE "save_game\|load_game\|ResourceSaver" interior ui` |
| AC4 | Display audit over the full minimum playthrough on the approved bundle: 0 mismatches, 0 unbound numerals, ≥ 500 samples, both clocks and the ISM readout on every transit sample, codex bodies hash-equal | `make playthrough && tools/display_audit.py $(SCRATCH)/display_samples.ndjson` |
| AC5 | Replay byte-identical incl. `record` intents and archive unlocks; VM = interpreter; AI process count during replay 0 | `make replay SESSION=$(SCRATCH)/session.ndjson && make parity-m4` |
| AC6 | AI optionality: `AI=none`, `AI=stub`, `AI=digits` all complete with the audit passing | `make playthrough AI=none`, `AI=stub`, `AI=digits` |
| AC7 | Minimum-path proxy ≤ 360 s (the R1 bar per D-14); each leg 45–120 s at default warp (expected 62.0 s) | `make playthrough && tools/playthrough_time.py` |
| AC8 | ISM readout: at 0.99c the sim reports load 2.2196e5 W/m², drag 23.26 N and 1.3653e17 J per α Cen leg (stand-off leg 4.354187 ly, coast distance) (±1e-3 relative), equal to the HB rows; at β = 0 all are 0 | `make sim` (ISM fixture) and `make lore-values` |
| AC9 | CPU physics: `ship_basis`, projection reference, α Cen cruise mirror, ISM load, glow profile, finite flux at stand-offs; no hand-computed γ or 1−β | `make test` (`physics`, `lint-precision`) |
| AC10 | GPU golden G-M4-1 (≤ 0.75 px, pan-invariant), G-M4-2 (≤ 1/255), G-M4-3 (≤ 0.75 px, all three phases), G-M4-4 (≤ 1 %, 0 at rest) | `make golden` |
| AC11 | Reference renders in `renders/m4/` on the approved bundle, reviewed by Mark | `make capture-m4`; `grep -n "S1 sign-off" design_docs/implemented/r1/m4-report.md` |
| AC12 | Bench p99 < 16.7 ms at 2560×1440 | `make bench SCENE=bridge` |
| AC13 | Bundles valid (fixture and delivered): alpha, camera round trip ≤ 1 px, GLB metres/Y-up | `make validate-areas` |
| AC14 | Art is swappable data: replacing the area bundle (blockout ↔ bridge v1 fixture) needs no code change; `validate-areas` passes for both and the slice runs on each | `make validate-areas BUNDLE=tests/fixtures/areas/bridge_blockout && make validate-areas BUNDLE=assets/areas/bridge && make m4-smoke BUNDLE=tests/fixtures/areas/bridge_blockout` |
| AC15 | Lore numbers cannot drift: every entry binds every number to its listed checks; HB rows with package functions agree with the package; the drifted fixture fails | `make lore-values lore-check` and `! tools/lore_check.py tests/fixtures/lore/drifted.md` |
| AC16 | Codex unlocks: the minimum playthrough unlocks the expected entries at the expected events, in order, and the codex shows only unlocked entries | `make playthrough && tools/codex_unlocks.py $(SCRATCH)/session.ndjson tests/expected_unlocks.json` |
| AC17 | The vendored lore matches the manifest's design-repo sha | `make lore-import CHECK=1` |
| AC18 | `make test` green locally and in CI (incl. `lore-check`, `lint-precision`); `make strict` and every parity target green; M2's old-message tests unmodified | GitHub Actions `CI` |

The first draft's AC8 (3-new-player playtest) is removed from R1 (D-14).

## Sub-milestones and estimates

| ID | Scope | LOC (code + tests) | Depends on | Art-gated |
|---|---|---|---|---|
| M4.0 | Bundle loader, blockout test fixture, `validate-areas`, `ship_frame` | 250 + 150 | — | no |
| M4.1 | `consequence.ail`: Earth clock, news epoch and tier, display fields, ISM fields if M2 lacks them, legacy log, archive unlocks, `record`, stand-off; `scriptedRoundTrip` | 380 + 320 | M2 protocol and planner | no |
| M4.3a | Transit loop, warp, boost/brake pacing, HUD (incl. ISM), arrival card, on a sky-only harness scene | 200 + 80 | M4.1, M2 map | no |
| M4.4 | News panel, templates, AI relay, return trip, legacy screen ⏸ S4 | 250 + 100 | M4.1, M4.3a | no |
| M4.7 | Lore import, codex UI, unlocks, registry, `lore-check` | 180 + 140 | M4.1; design repo `lore/archive/`, `higgs-bubble.md` | no |
| M4.5 | Playthrough bot, display audit, replay/parity, time proxy | 120 + 230 | M4.3a, M4.4, M4.7, M2 replay | no (final run on the approved bundle) |
| M4.2 | Interior scene, composite, glow overlay, walking, interactables | 380 + 100 | M4.0, M1.3/M1.5 (any valid bundle) | **yes** |
| M4.3b | HUD and transit moved into the interior | 40 + 30 | M4.2, M4.3a | **yes** |
| M4.6 | CPU tests and `lint-precision` (not gated); golden G-M4-1..4, `capture-m4`, bench (gated) ⏸ S1 | 100 + 170 | M4.2, M1.6b | partly |
| | **Total** | **1,900 + 1,320 ≈ 3,200** | | |

**Order (review early, tweak as we go).** Track A (sim and UI) starts when M2's
protocol lands: M4.0 ∥ M4.1 → M4.3a → M4.4 ∥ M4.7 → M4.5, plus M4.6's CPU tests
and lint. Track B (interior) runs in parallel from the start on the blockout
bundle: M4.2 → M4.3b → M4.6 goldens, renders, bench → ⏸ S1. A Blender agent
builds the bridge v1 bundle (ship-interior brief §7 step 2) at the same time,
and it drops in when delivered. **First review build:** as soon as M4.0 + M4.2
run end to end on the blockout (galaxy map → commit → transit view), the loop
publishes captures and a build for Mark, then keeps doing so at every
sub-milestone. Tweaks arrive as data (bundles, lore, news templates, scenario
parameters) wherever possible.

**Critical-path effect.** Nothing waits on art. M4 lands when both tracks and
S1 are done; if the bridge v1 bundle hasn't arrived by then, M4 lands on the
latest delivered bundle and the swap follows as a data change.

**Mark stop points:** **S1** composited reference renders (gate 2); **S2**
recurring art review of each delivered bundle (non-blocking since D-16); **S4**
news template copy. (S3, the human playtest, moved to R2.)

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| S2 approval or Blender delivery is late, stalling M4 | Track A proceeds; the blocker is logged; the bundle format is fixed (brief §9), so delivery needs no code change |
| M2 lands with different names, phases or a different stand-off | M4 adopts M2's names; AC1 asserts against M2's package trip function, not hard-coded numbers |
| The default warp gives sub-second legs at high γ (0.999999c: 0.0062 ship-yr, 0.6 s) | Accepted as the honest consequence; the proxy is defined at the slice default; open question 1 |
| The glow is too faint to see, or reads as a heat bloom | ε from higgs-bubble.md; G-M4-4 checks profile and zero at rest; S1 looks at the cruise frame |
| Double tonemap dims the starbow, or the starbow lands in the wrong place | G-M4-2 (single HDR tonemap); one `ship_basis` with CPU tests; G-M4-3 in every phase |
| The destination star blows up (1/r²) or merges with its companion; AI text slips a number on screen | 1,000 AU stand-off, M1.2 tiers, finite-flux test; `ai_numeral`, AC6 |
| Lore in the design repo changes after import | Vendored with sha; `lore-import CHECK=1` flags it; `lore-check` re-runs on every import |
| A lore number rounds differently from its check value | The match rule is defined on shown significant figures; the drifted fixture is the positive control |
| Headless rendering; 60 fps with 331k stars + toon pass | Audits use labels and state only; window-resolution sky, medium tier |

## Open questions (for the user)

The first draft's seven questions are resolved by the attended rulings of
2026-10-01 (D-11, D-12, D-14):
1. **RESOLVED (D-14, D-11): orientation.** No flip; up = direction of travel
   throughout; the starbow stays overhead and relaxes on arrival.
2. **RESOLVED (D-14): stand-off** 1,000 AU. Slice default cruise 0.99c, player can change it.
3. **RESOLVED (D-12, D-14): calendar** relative; epoch and start_age (30) are scenario parameters.
4. **RESOLVED (D-14): news beat** is an Archive-terminal text panel only.
5. **RESOLVED (D-14, superseded by D-16): art (S2).** Bridge style frame v1 is
   approved for build-out; art is swappable data reviewed as it arrives, and the
   slice runs on the current bundle. Bridge only.
6. **RESOLVED (D-14): playtest.** R1 uses the scripted proxy (≤ 360 s, legs
   45–120 s); the 3-new-player playtest moves to R2; bar clause 4 amended.
7. **RESOLVED (D-12, D-14): time while docked.** No pause; the clock runs at rest at a fixed host rate.

**New questions raised by this revision:**

1. **Warp units across cruise speeds.** Fixed ship-time rates make real
   transit time proportional to crew time: 62 s at 0.99c, 211 s at 0.9c,
   0.6 s at 0.999999c. The alternative is a leg-normalised default (every
   leg plays in ~60 s). **Recommendation:** fixed ship-time rates (0.002 /
   0.01 / 0.05 ship-yr/s), because real seconds then mean crew days and the
   high-γ choice feels like what it is. **Default:** that; the 45–120 s rule
   applies at the slice default.
2. **Who renders the forward CMB disc** (D-11 says it is real and must be
   rendered)? It is invisible at the slice default (38 K) and visible only
   from γ ≈ 275, which the planner allows. **Recommendation:** an M1 sky
   follow-up (a CMB term in `sky/background.gdshader` with its own golden)
   before R1 closes. **Default:** M4 does not render it; above γ 275 the
   planner shows "forward CMB not yet rendered", and the M4 report lists the
   gap.
3. **Lore vendoring.** **Recommendation:** a vendored copy in `data/lore/`
   with the design repo's sha (no submodule, CI needs no sibling checkout).
   **Default:** that.

## Deliverables

- **Sim:** `sim/consequence.ail`, protocol additions in `sim/ship.ail`,
  `scriptedRoundTrip`, `sim/tools/lore_values.ail`, consequence/tier/ISM/unlock tests.
- **Godot:** `interior/` (`area_bundle.gd`, `ship_frame.gd`, `interior.tscn`,
  glow overlay, toon/outline shaders), `ui/journey_hud.tscn`, news panel,
  arrival card, legacy screen, `ui/archive/codex.tscn`, `lore_loader.gd`,
  `DisplayBinding`, `LoreBinding`, the AI relay.
- **Data:** `assets/areas/bridge/` (approved Blender bundle),
  `tests/fixtures/areas/bridge_blockout/` (test only), `data/news/templates.json`,
  `data/lore/{archive/*.md, manifest.json, check_values.json}`.
- **Targets and tools:** `playthrough`, `parity-m4`, `capture-m4`,
  `validate-areas`, `lint-precision`, `bench`, `lore-import`, `lore-values`,
  `lore-check`; `tools/{display_audit, playthrough_time, validate_area,
  lore_check, codex_unlocks}.py`; `tests/{playthrough_min, adversarial,
  expected_unlocks}.json`, `tests/fixtures/lore/drifted.md`.
- **Report:** `design_docs/implemented/r1/m4-report.md` (S1/S2 sign-offs,
  renders, bench, proxy time, lore-check output, upstream AILANG reports).
- **At landing:** the R2 roadmap gains the human playtest (protocol from this
  doc's first draft); design-repo roadmap status; changelog entry.

## Verification log

Run on 2026-10-01 at `e9d35c5` (main) and `fe16790`
(`origin/spike/iso-bridge`), read-only. Rows V9–V11 added by the D-11/D-12/D-14
revision (scratchpad `m4.py`).

| # | Claim | Command | Observed | Verdict |
|---|---|---|---|---|
| V1 | `main` has no interior or compositing | `grep -rln SubViewport main.gd sky bridge tests`; `ls assets` | no hits; no `assets` | True |
| V2 | The iso spike is branch-only, fixed speeds and heading | `git show origin/spike/iso-bridge:spike/interior3.gd \| grep -n "HEADING :=\|SPEEDS"` | `:17 HEADING := Vector3(0, 0, -1)`, `SPEEDS := [0.0, 0.99]` | True |
| V3 | The spike computes γ in GDScript | same file, `grep -n "sqrt(1.0"` | `:176 var g := 1.0 / sqrt(1.0 - b * b)` | True: not ported |
| V4 | The package has γ and 1−β from rapidity, and closed-form trips | `grep -n "export pure func" ~/.ailang/cache/registry/sunholo/relativity/0.3.0/{kinematics,journey}.ail` | `gammaOf`, `oneMinusBeta`; `flipAndBurn`, `burnCoastBurn`, `coastAt` | True (the boost-cruise-brake trip function is M2's) |
| V5 | The sim has no journey, Earth or log | `grep -n "type Ship" sim/core.ail` | `Ship = { tick, motion, heading, origin, x0 }` | True |
| V6 | α Cen A/B coincide in the catalogue | `python3` over `data/starmap/stars.json` for `Gl 559` | both `x 1.5, y −4.09, z −0.05` | True: needs M1.2 |
| V7 | The old flip-and-burn numbers (now check values only) | `python3`, `flipAndBurn`, g = 1.032295275553596 ly/yr² | d 4.37: 3.58239 / 6.00250 / 0.951656; d 4.354187: 3.57728 / 5.98588 / 0.951406 | Superseded as gameplay by D-11 |
| V8 | The camera contract exists in the spike | `git show origin/spike/iso-bridge:spike/v2/cam_bridge.json` | `fov_vertical_deg 78`, "+Z = direction of travel" | True |
| V9 | Cruise trip at 0.99c with the 1,000 AU stand-off | `python3 m4.py` | s = 0.0158125 ly, d−s = 4.354187; γ 7.088812, φ 2.646652; per leg Earth 4.398169, ship 0.620438 yr (226.6 d); boost τ_b = 1/10/60 min: dist 4.37e-6/4.37e-5/2.62e-4 ly, ΔEarth 1.25e-6/1.25e-5/7.5e-5, Δship 2.56e-6/2.56e-5/1.53e-4 | Matches D-14 "~227 ship-days, ~4.4 Earth-years" |
| V10 | News and round trip (zero dwell) | `python3 m4.py` | t_e at α Cen 0.043982 yr (16.1 d), age 4.354187; round trip Earth 8.796338, ship 1.240876, gap 7.555462 (old 11.9718 / 7.1546 / 4.8172) | Tiers: α Cen `<1`, return `5–15` |
| V11 | Warp, ISM, CMB at 0.99c | `python3 m4.py`, n = 1e5 m⁻³, A = π·100², m_p = 1.67262192369e-27 | leg 310.2 / 62.04 / 12.41 s at 0.002 / 0.01 / 0.05 ship-yr/s (old 71.5 s at 0.05); load 2.2196e5 W/m² (163.1 suns); drag 23.26 N; 1.3653e17 J (1.519 kg) per leg (sphere drag, coast distance; was flat-mirror 46.52 N / 2.73e17 J before the higgs-bubble.md reconciliation); forward CMB 38.4 K; c²φ = 2.379e17 J/kg | Matches D-11's worked estimates (2.2e5; 2.7e17 J, 3 kg; 2.4e17 J/kg) |
