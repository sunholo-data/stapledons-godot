# M4: First journey, a vertical slice

**Status:** Planned (design, awaiting sprint plan). Revised 2026-10-01 for
Mark's attended rulings D-11, D-12 and D-14: boost → cruise → brake with no
flip, 0.99c default cruise, the ISM readout and forward glow, art stop S2 now
blocks the interior, the human playtest moves to R2, and the Archive codex
teaches the physics in-game. Revised 2026-10-03 (mission iteration 11) for
design quorum round 1 (BLOCKED 3/3): numbers re-pinned to named
`sunholo/relativity` 0.5.1 functions, design-repo premises verified at a
pinned sha, ε stated and gated, the AI fallback made player-visible, Python
tools replaced per the repo policy. See
[§Quorum round 1 response](#quorum-round-1-response).
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
  checks:` with `unlock` drawn from the README's hint vocabulary; V16):
  Mark's "physics education … available in-game lore" (D-11).
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
**Evidence:** codebase claims are in the [Verification log](#verification-log).
Rows V1–V11 are pinned to `e9d35c5` (main) and `fe16790`
(`origin/spike/iso-bridge`). Rows V12–V22 (quorum round 1) are pinned to game
`15cde03` (main), spike `4eda978` (contains `fe16790`), design repo
`1ef3bc9` (`origin/main`; contains `736db38`; `physics/higgs-bubble.md`
unchanged between them, sha256 `79505e26…`), and `sunholo/relativity`
**0.5.1**, the version `sim/ailang.toml` pins. **Instruments:** every
physics number in this doc is produced by the package through AILANG v0.51.0
(the probe in V12). A Python script is used only as an independent oracle
(V13), never as the source. V9–V11's scratchpad `m4.py` is retired as a
provenance.

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
  and refuses a bundle with a missing layer. **Schema = brief §9's
  `manifest.json`, field for field (V17):** `area`;
  `layers.panorama{file, parallax}`; `layers.play{file, iso_pitch_deg,
  iso_yaw_deg, iso_size_m}`; `layers.foreground{file, parallax}`; `camera`;
  `focus_m[3]`; `sky_visible`. All are required. The one game-side extension
  is an optional `placeholder` (bool, default false). Unknown keys are kept
  and ignored, so a richer brief revision does not break the loader. The
  brief's `preview_rest.png` and `preview_099c.png` are review-only and not
  required. The GLB collections are the brief's `WALK_`, `SPAWN_` and
  `INTERACT_`.
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
- **`make validate-areas`** (`tools/validate_area.gd`, run by Godot
  headless with `--script`; image and GLB I/O is Godot's job under the repo's
  Python policy): alpha exactly 0 where space shows; manifest and camera JSON
  schema; camera round trip within 1 px; GLB Y-up in metres with the three
  collections. Runs on the fixture and any delivered bundle.
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
  ship time, cruise, brake. **The trip function is the package's
  `journey.planBurnCoastBurn(distance, a, phiCruise)`** (relativity 0.5.1),
  which M2's planner already calls at `a = boost_g × standardGravity()`
  (`sim/core.ail:222`). D-15's default boost_g of 7.5 × 10⁵ g makes
  τ_b = φ/a = **1.80 min** per phase. **The τ_b → 0 reference is the
  package's `journey.coastAt(distance, beta)`** ("pure coast at constant beta,
  instant acceleration idealisation"); it is not the gameplay trip, so the
  sim never calls it, and AC1 uses it only as the limit check. For Sol → α Cen
  with the 1,000 AU stand-off, `s = 1000 × astronomicalUnitM() / lightYearM()`
  = 0.0158125 ly, so **d − s = 4.354187 ly** from HB-4's d = 4.37 ly. At the
  default **β = 0.99** (`gammaOf` 7.088812, `rapidityOfBeta` 2.646652), all
  from V12:

  | Per leg | Earth-yr | Ship-yr |
  |---|---|---|
  | `coastAt(4.354187, 0.99)`, the τ_b → 0 limit | 4.398169 | 0.620438 (226.6 d) |
  | `planBurnCoastBurn(4.354187, 7.5e5 g, φ)`, τ_b = 1.80 min | 4.398171 | 0.620443 |

  The boost offset is +2.24 × 10⁻⁶ Earth-yr and +4.60 × 10⁻⁶ ship-yr per leg,
  that is 2.56 × 10⁻⁶ ship-yr per minute of τ_b (both burns together; V9 and
  V12 agree). AC1's 1e-4 round-trip limit clause therefore holds for
  τ_b ≤ 19 min per phase. That bound is listed in
  [§Interfaces assumed](#interfaces-assumed). **Distance source:** the sim
  plans to the catalogue position. At `15cde03` that is α Cen A at `dist_ly`
  4.37 (V20), equal to HB-4. D-19 moves A and B to the CNS5 system distance
  4.32 ly when M1.2 lands. AC1 therefore runs on a scripted target pinned at
  4.37 ly on the α Cen approach line, as M2's `core_test.ail` already does
  (`planBurnCoastBurn(4.37, …)`). The catalogue playthrough asserts only the
  package relation at whatever d the catalogue gives (new open question 4).
  The first draft's 1 g flip-and-burn (3.5773 ship-yr, 5.9859 Earth-yr, peak
  β 0.95141; `planFlipAndBurn`) remains a package check value, not the
  gameplay profile.
- **Light-delayed news epoch.** At an event at ship position `p` and galaxy
  time `t`, the newest receivable Earth news is from `t_e = t − |p − p_Sol|`
  (c = 1). At α Cen arrival (zero dwell) the arrival time is the
  `planBurnCoastBurn` value `t = 4.398171` (V12, V24), so **`t_e` = 0.043984
  Earth-yr (16.1 days) after departure** and the news is 4.354 years old.
  The `coastAt` limit would give 4.398169 and 0.043982; that is the τ_b → 0
  reference only, not the arrival time (old: `t_e` 1.632, age 4.354).
- **Displayed quantities as fields.** The sim emits every number the UI
  shows: `gap_years = t − tau`, `news_epoch`, `news_age_years`, progress,
  `one_minus_beta` (package), and the ISM readout (below). Godot never
  subtracts two fields.
- **ISM readout (D-11).** The wall is an elastic mirror for massive
  particles (higgs-bubble.md §5). Inputs are the scenario parameters M2
  already carries (`sim/core.ail` `defaultParams`, V18): n = 0.1 cm⁻³ (HB-3),
  R = 100 m (HB-1), **ε = 1 × 10⁻⁹** (`glowEps`; D-15's attended default,
  inside HB-61's design-guide ceiling of 3.6 × 10⁻⁹), and **f_in = ½**
  (`glowFIn`; M2's default, the same assumption HB-61 states; no Mark ruling
  fixes f_in, and it stays a scenario parameter). Every readout is one named
  function of `sunholo/relativity/medium` 0.5.1:

  | Field | Package function | At 0.99c (V12) | HB row (V14) |
  |---|---|---|---|
  | `load_w_m2` | `loadScale(n, φ)` = n γ²β² m_p c³ | 2.21961 × 10⁵ W/m² (163.1 suns) | HB-40 2.22 × 10⁵, HB-41 163 |
  | `drag_n` | `mirrorDragForce(n, φ, R)` = n γ²β² m_p c² πR² (specular sphere) | 23.2598 N | HB-49 23.3 |
  | `drag_energy_j` (this leg) | `cruiseDragEnergy(n, φ, R, dCoast)` = n γβ m_p c² πR² d | 1.36530 × 10¹⁷ J (1.5191 kg) over dCoast = 4.354172 ly | HB-53 1.37 × 10¹⁷, HB-54 1.52 (at d = 4.37 ly: 1.37026 × 10¹⁷) |
  | `glow_w_m2` (mean inward) | `glowInwardFlux(n, φ, ε, f_in)` = ε f_in K / 4, K = `kineticFlux(n, φ)` | 2.40719 × 10⁻⁵ W/m² (K = 1.92576 × 10⁵) | HB-45 K 1.93 × 10⁵ |

  The glow is ε f_in K/4 of the **kinetic** flux K, as higgs-bubble.md §6
  states. The earlier draft's "ε × load" was wrong and is withdrawn. At the
  top of the range, 0.999999c, the default gives 0.2813 W/m², under HB-61's
  1 W/m² guide. M2's `journey.plan.ism` evaluates these at the plan's peak
  rapidity. M2's ledger (`sim/core.ail:106` `Ledger{…, dragJ}`, emitted as
  `ledger.drag_j` by `sim/protocol.ail:155`; V24, V25) accumulates drag on
  the autopilot path at `sim/core.ail:327`: only in cruise pieces, at the
  plan's peak rapidity, `mirrorDragPower × piece × julianYearS()`. Burn
  pieces add none, because the boost and brake drag terms cancel over the
  pair (package `tripEnergy`). **Measured semantics (V24):**
  `mirrorDragPower` = `mirrorDragForce × cSI()` = F·c (= `loadScale × πR²`),
  not F·v. `cruiseDragEnergy(n, φ, R, dCoast) / (mirrorDragPower × tauCoast
  × julianYearS())` = 0.9999999999999999. M2 already has the accumulator, so
  M4 adds no ledger scope. **M4.1 adds a live `ship.ism{load_w_m2, drag_n,
  glow_w_m2}` at the ship's current rapidity** (the same package calls), so
  the glow and the HUD relax through the brake. **`ship.ism` ships in two
  steps: load/drag/glow_w_m2 at pin 0.5.1; glow_pole_w_m2 is added only after
  M4.6a lands — the sim never computes 4 × glowInwardFlux itself.** It also
  adds `drag_energy_j`. **Window:** the ledger's `drag_j` minus its value at
  the commit tick, so since commit, for this leg only. **Error budget inside
  AC8's 1e-3:** the burn-phase contribution is 0 by construction, since M2
  omits burn drag. The reviewer estimated about 1.2 × 10⁻⁶ relative for
  that term; it is not measured here, and it is not part of `drag_j`. Tick
  discretisation is exact up to float summation, because the
  power is constant in cruise and M2 cuts pieces at the phase boundaries.
  The bound is (cruise ticks) × 2.2 × 10⁻¹⁶, which stays ≤ 1e-9 up to 10⁶
  ticks. M2's own test asserts the arrival ledger equals `tripEnergy(…).total`
  within 1e-9 (`sim/core_test.ail:602–615`). Boost energy per kg of m_eff, `photonDriveEnergy(1,
  φ)` = 2.3787 × 10¹⁷ J at 0.99c (HB-35), is on M2's planner. All of these
  are readouts; no budget is enforced (non-goal). **Check values:** ε
  (`m4:glow_eps`, 1e-9, source D-15), f_in (`m4:glow_f_in`, 0.5, source the
  M2 scenario default) and the 0.99c `glow_w_m2` above (`m4:glow_099`) are
  registered in `data/lore/check_values.json` (M4.7). The registry
  cross-checks ε ≤ HB-61.
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
  `archive: [{id, unlock}]` from the imported lore, where `unlock` is one of
  the design repo's hints (M4.7). The sim maps each hint to a predicate on
  its own state. When the predicate first holds, the sim appends the id to
  `archive.unlocked` (change set) and logs it. Unlock state is sim state, so
  it replays.
- **AI results are inputs (D-7, D-8, D-20, D-21).** A `record{source: "ai",
  req, kind, sha256, body}` intent (protocol 2.1, `sim/ai.ail`) is accepted
  only for an open `ai_request_id`. Text with any digit (D-21: no digits in
  any generated text) or longer than `maxCharsFor("news")` = 280 characters
  (D-21) is refused (`ai_numeral` / `ai_length`). The refusal closes the
  request with the existing `ai_fallback{req, reason}` event (V21). **The
  fallback is never silent.** The sim owns the news item's provenance:
  `news{…, body_source ∈ template | ai | fallback, fallback_reason}`.
  `fallback` means an AI request was opened for this item and closed without
  accepted text, and `fallback_reason` is the sim's reason code (`ai_numeral`,
  `ai_length`, `expired`, `offline`, `budget`, …). The template paragraph is
  then shown with a player-visible notice (M4.4). Like every other input,
  the outcome is recorded and replays. `template` means no request was made
  (`AI=none`, no key, text-only), which is the designed default under D-8 and
  not a failure.
- **Arrival stand-off: 1,000 AU** from the target star (D-14), on the
  approach line. α Cen A is then about magnitude −12; A and B about 1.3°
  apart. M2 as landed plans to the star's own position (`planIntent`,
  d = |target − here|; V18), so **M4.1 owns the stand-off**. It plans to
  d − s with s = 1,000 AU (HB-15) along the same heading.
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
  the tonemap) draws the wall's glow from the live `ship.ism.glow_w_m2`.
  **Profile, absolute:** a sphere in a forward beam receives kinetic flux
  K max(0, cos θ) at angle θ from the travel direction. The inward glow
  emittance there is ε f_in K max(0, cos θ) = **4 · `glow_w_m2` ·
  max(0, cos θ)** (W/m²). Its mean over the whole inner sphere is exactly
  `glow_w_m2`, since the mean of max(0, cos θ) over a sphere is ¼. So the
  pole value at 0.99c with the defaults is 9.6288 × 10⁻⁵ W/m². It is zero at
  β = 0. **Package first (gate 3):** the angular profile is a formula, and
  0.5.1 has only the mean (`glowInwardFlux`). So **M4.6a** adds
  `medium.glowEmittanceAt(n, phi, eps, fIn, cosTheta)` = ε f_in K max(0,
  cosθ) to `sunholo/relativity`, with tests, CHANGELOG and release, and
  `ailang pkg quality` clean. The sim pin, the lockfile and the bundled cache
  are bumped together. The release number is whatever the package's
  `[release] kind` assigns after 0.5.1, and V23 pins it. The test
  asserts that the function's sphere mean equals `glowInwardFlux` and that its
  value at cosθ = 1 is 4 × `glowInwardFlux`. The sim emits
  `ship.ism.glow_pole_w_m2` = `glowEmittanceAt(…, 1.0)`. The shader and the
  GDScript CPU reference `glow_profile(glow_pole_w_m2, cos_theta)` mirror the
  package. The spectrum follows higgs-bubble.md. The overlay converts W/m² to scene radiance with M1.5's
  photometric exposure, the one used for stars, so the glow's brightness
  follows from the physics plus the one shared exposure, not from a
  hand-tuned gain. It is faint by design (ε = 1e-9) and disappears as the
  ship brakes.
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
- **AI path (optional):** results return as `record` intents. The panel shows
  the paragraph the sim's `news.body_source` names; Godot never decides.
  - **`fallback`:** the template paragraph is shown under a visible notice
    line, *"Live transmission unavailable: archived text shown"*, followed by
    the reason in words from a fixed reason → phrase table with no digits,
    for example `ai_numeral` → "the generated text contained a numeral" and
    `expired` → "no reply in time". The same item appears in a diagnostics
    list on the Archive terminal's news tab.
  - **`template`** (no request was made) shows no notice. The HUD's AI
    indicator (ai-service-foundation (a5)) already says AI is off, and D-8
    makes templated text the designed default. Calling it "degraded" would
    mislabel every keyless game.
  - **`ai`:** a small "generated" tag.

  This is quorum round 1's proposed fix (an explicit in-game indicator),
  scoped to real failures. All three labels are fixed copy bound by a
  `DisplayBinding` to `body_source` and `fallback_reason`, so the display
  audit covers them, and AC6 checks them. **Return trip:** the map opens with Sol highlighted;
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
- **Display audit** (`tests/display_audit.gd`, Godot headless `--script`, run
  by `make display-audit`; it uses Godot because the format rules it checks
  are Godot's `DisplayBinding`; no Python): every numeric label is a
  `DisplayBinding{node_path, field, format}`; fails on a number ≠
  `format(state[field])` at that tick, an unbound digit, or a missing field.
  Codex text is a `LoreBinding{entry_id}`: the shown body must hash-equal the
  imported entry, whose numbers `make lore-check` vouches for.
- **Replay:** `make replay SESSION=…` compares state streams with `cmp`;
  `make parity-m4` on VM and interpreter; the AI service is never spawned.
- **Ten-minute proxy** (`sim/tools/session_audit.ail` entry `playthroughTime`,
  AILANG with FS caps over `session.ndjson`, run by `make playthrough-time`;
  deterministic; the R1 acceptance for the bar, D-14). Modelled time = sim ticks at default warp ×
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

**One new formula in M4, and it goes into the package first.** The trip,
ISM and mean-glow functions already exist in `sunholo/relativity` 0.5.1 and
are verified by name (V12, V15): `journey.planBurnCoastBurn`,
`journey.coastAt`, `kinematics.gammaOf` / `oneMinusBeta` /
`rapidityOfBeta`, `medium.loadScale`, `kineticFlux`, `mirrorDragForce`,
`mirrorDragPower`, `cruiseDragEnergy`, `glowInwardFlux` and
`photonDriveEnergy`. The glow's angular profile `medium.glowEmittanceAt`
(M4.2) is the one addition. It lands in the package as **M4.6a** (not art-gated; it blocks M4.1's `glow_pole_w_m2`) with its tests, before
M4.2's glow overlay merges (gate 3). The visuals compose SR rendering and
the glow is driven by a relativistic flux, so CLAUDE.md gate 2 applies in
full.

- **CPU (`tests/test_physics.gd`):** `ship_basis` cases; projection of a
  galactic direction through `cam_bridge.json` × ship basis; the α Cen cruise
  mirror (γ(0.99) = 7.088812050083356 from `gammaOf`; per leg 4.398169
  Earth-yr and 0.620438 ship-yr from `coastAt`, with the sim's
  `planBurnCoastBurn` 4.398171 / 0.620443 at D-15's boost); the ISM load at
  0.99c (2.21961 × 10⁵ W/m², `loadScale`, HB-40 at its 3 s.f.); the glow
  values: ε = 1e-9, `glow_w_m2` = 2.40719 × 10⁻⁵ W/m² at 0.99c and
  0.281271 W/m² at 0.999999c (≤ 1 W/m², HB-61), and the profile
  `glow_profile(glow_pole_w_m2, cos θ)` at θ = 0°, 45°, 80°, 90° and 120°
  against `glowEmittanceAt` within 1e-12 relative; finite flux at every stop
  point (no star within 100 AU; gate 5). Every expected value is copied from
  the AILANG probe (V12), not computed in GDScript.
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
  - **G-M4-4, glow.** (a) *Profile:* at β = 0.99 the overlay's radiance at
    θ = 0°, 45° and 80° matches the CPU profile within 1 %. At β = 0 it is
    exactly 0. (b) *Absolute (quorum round 1):* the overlay renders into a
    debug linear float target in W/m² units (unit gain, before exposure and
    tonemap). Its value at θ = 0 equals the sim's `glow_pole_w_m2` =
    4 × `glow_w_m2` within 1 %, at 0.99c (9.6288 × 10⁻⁵) and at 0.999999c
    (1.12508). So the glow's brightness is pinned to ε × the package flux by
    a gate, not only by Mark's eye at S1. The reviewer proposed "ε × load"
    for this case. It is replaced by the package's ε f_in K, because
    higgs-bubble.md §6 defines the glow on the kinetic flux K, not the load.
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
  (the entry files, not `README.md`), `physics/higgs-bubble.md` and
  `physics/relativity-spec.md` into **`data/lore/`**. The copy is shell glue;
  the manifest is written by `sim/tools/lore_import.ail` (AILANG, FS caps,
  `std/crypto.sha256Hex`) into `data/lore/manifest.json`, recording the
  design-repo commit sha and a sha256 per file. The game never reads the
  design repo at run time. `make lore-import CHECK=1` has two halves:
  (i) *self-consistency, fail-closed, everywhere including CI:* every vendored
  file hash-equals its manifest entry and no file is missing or extra;
  (ii) *cross-repo:* the sibling checkout's files at the recorded sha equal
  the vendored copy. Half (ii) runs wherever the sibling exists, which
  includes every mission-loop iteration and attended session. In CI it is
  skipped with a notice, because `sunholo-data/stapledons-design` is a
  **private** repository (V22) and CI holds no credential for it (new open
  question 5).
- **Format (V16, the design repo's `lore/archive/README.md`).** Front matter
  `id` (`archive.<name>`), `title`, `unlock`, `checks: [ids]`; the body is
  Markdown prose. **`unlock` is one of the README's hints**, and the game maps
  each hint to a sim predicate (M4.1):

  | Hint | Sim predicate (first time it holds) |
  |---|---|
  | `always` | `new_game` |
  | `first_commit` | journey enters `committed` |
  | `first_boost` | phase crossing into boost |
  | `cruise_above_0.9c` | phase crossing into cruise with `plan.cruise_beta > 0.9` |
  | `cruise_above_gamma_275` | phase crossing into cruise with `plan.cruise_gamma ≥ 275` |
  | `first_black_hole` | M3's first arrival near a black hole |

  An unknown hint fails `lore-check`. `checks` ids are HB-n
  (higgs-bubble.md) or RS-n (relativity-spec.md §7). At `1ef3bc9` the
  vocabulary is these six hints. The ten entries cite 60 distinct ids (48
  HB, 12 RS), and every one resolves to a registry row (V16). The previous draft's `start | event:<kind>[@<star_id>]`
  vocabulary was never what the design repo wrote, and is withdrawn.
- **Codex UI** (`ui/archive/codex.tscn`, `lore_loader.gd`): a third tab at
  the Archive terminal; locked entries show their title greyed; unlocked ones
  render a Markdown subset (headings, emphasis, lists, tables) into a
  `RichTextLabel`. A toast announces each unlock. Unlocks come only from the
  sim's `archive.unlocked` (M4.1), so they replay.
- **Expected slice unlocks** (the design repo owns the list; V16): at
  `always`, `archive.bubble`, `archive.one-g` and `archive.nothing-crosses`;
  at `first_commit`, `archive.two-clocks`; at `first_boost`,
  `archive.photon-drive`; at `cruise_above_0.9c` (the 0.99c default),
  `archive.ism-glow` and `archive.starbow`. `archive.cmb-forward` does not
  unlock at the slice default (γ 7.09 < 275). `archive.tides` and
  `archive.shadow-ring` unlock in the M3 demo. That gives seven entries on
  the minimum path, in that order (`tests/expected_unlocks.json`).
- **Check-value registry** (`make lore-values` → `data/lore/check_values.json`,
  each value with id, unit and source). Sources: (a)
  `sim/tools/lore_values.ail`, strict VM, which **evaluates the package's
  exported functions** directly for each registered value. **No `rel:check`
  registry exists** (V24): 0.5.1's `checkNN` functions are private
  `pure func … -> bool` test predicates in `*_test.ail`, not exported, and
  they carry no ids or values. Source (a) therefore registers ids of the form
  `pkg:<function>(<args>)`, for example `pkg:loadScale(1e5,φ0.99)`, plus the
  M4 values (`m4:glow_eps`, `m4:glow_f_in`, `m4:glow_099`; its seed is the V12
  probe); (b) the HB tables in the vendored `higgs-bubble.md`, ids `HB-n`;
  (b′) the RS table in the vendored `relativity-spec.md` §7, ids `RS-n`;
  (c) the `CHECKS` dictionary exported by `tests/test_physics.gd`, dumped
  headless (ids `phys:<name>`). Where an HB row has a package function, (a)
  and (b) must agree to the HB row's printed precision, so the design doc
  cannot drift from the package either. **At `1ef3bc9` they do** for the
  rows M4 shows: HB-16, HB-17, HB-35, HB-40, HB-41, HB-45, HB-49, HB-53,
  HB-54 and HB-61 (V12, V14). The registry also asserts `m4:glow_eps` ≤
  HB-61. **Provenance, stated plainly:** the HB rows are the design repo's
  numbers. The package and an independent Python oracle reproduce them
  (V12, V13), so AC8's "equal to the HB rows" compares two instruments, and
  is not circular.
- **`make lore-check`** (`sim/tools/lore_check.ail`, AILANG with FS caps,
  strict VM = interpreter, in `make test`; parsing and matching are the
  logic under test, so the policy rules out Python. Any AILANG gap, such as
  superscript parsing, is reported upstream and not worked around in
  Python). For every
  entry: front matter is valid; every `checks` id exists in the registry;
  `unlock` names a known event kind; and **every number in the body binds to
  one of the entry's listed checks**. A number (decimal, thousands separator,
  `× 10ⁿ`, `e±n`) matches when the check value rounded to the shown
  significant figures equals the shown number and the unit after it equals
  the check's unit, using **the README's unit-alias table** (V16). The table
  is textual only (yr ↔ years, min ↔ minutes, deg ↔ °, sun ↔ suns,
  M☉ ↔ solar masses, r_s ↔ horizon radii, K ↔ kelvin, c attached as in
  0.99c, — ↔ no unit or "a factor of"), with no numeric conversion. The
  registry carries separate rows where prose uses another unit (HB-21 yr and
  HB-22 days; HB-40 W/m² and HB-41 sun; HB-53 J and HB-54 kg). The previous
  draft's numeric conversion table (g ↔ m/s², J ↔ kg, ly ↔ AU, …) is
  withdrawn, because it could bind a number to the wrong row. A number with no
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
| State | `ship{beta, gamma, phi, one_minus_beta, tau, t, pos, heading}`, `journey{phase ∈ docked/planned/committed/boost/cruise/brake/arrived, plan{ship_years, earth_years, cruise_beta, gamma, energy_per_kg, ism_energy_j, arrival_t, crew_age}, progress, distance_remaining}`, `ism{n, load_w_m2, drag_n, drag_energy_j, glow_w_m2, glow_pole_w_m2}` |
| Commit rule | After `commit`, `plan`, a second `commit` or `cancel` are refused `committed` until arrival |
| Determinism / replay | Named PCG streams (M4 asks for `"news"`); `make replay SESSION=…`, VM vs interpreter |
| Galaxy map | Emits `target_selected(star_id)`, shows plan fields, cruise-speed control (0.9c–0.999999c, default 0.99c), the D-12 commit dialog; accepts a preselected star |
| Arrival point | At rest 1,000 AU short of the star (D-14). M2 as landed plans to the star itself, so M4.1 owns the stand-off (V18) |
| Trip function | `planBurnCoastBurn(d − s, boost_g × standardGravity(), φ)` from relativity 0.5.1 (as `sim/core.ail:222`); boost_g default 7.5 × 10⁵ g (D-15) → τ_b = 1.80 min. **Contract:** AC1's 1e-4 limit clause against `coastAt` holds for τ_b ≤ 19 min per phase (2.56 × 10⁻⁶ ship-yr per minute of τ_b per leg; V12). Above that, only the 1e-9 equality with `planBurnCoastBurn` applies |
| ISM and glow | `plan.ism` at peak φ (M2, landed); M4.1 adds live `ship.ism{load_w_m2, drag_n, glow_w_m2}` at pin 0.5.1, then `glow_pole_w_m2` after M4.6a (never 4 × glowInwardFlux in the sim), and `drag_energy_j` = ledger `drag_j` since commit (M2 ledger, `sim/core.ail:327`, F·c; V24, V25). Params `ism_n_cm3`, `bubble_radius_m`, `glow_eps` (1e-9, D-15) and `glow_f_in` (0.5) are already echoed by M2's protocol |

**From the AI service foundation** (text path only): a separate process
relayed by Godot; request `{req: "text", id, kind: "news", context{tier,
template_id, canon, max_chars: 280 (D-21), constraints: ["no_numerals"]}}`; result
forwarded as `record`; `--ai-stub` for tests. If it slips, M4 ships with no
AI process and AC6's `digits` case uses an injected fixture.

## Acceptance criteria (all checkable by command)

| # | Criterion | Check |
|---|---|---|
| AC1 | Round trip Sol ⇄ α Cen (scripted target pinned at HB-4's 4.37 ly; V20), boost → cruise 0.99c → brake, 1,000 AU stand-off, zero dwell, default boost_g: Earth elapsed = 2 × `planBurnCoastBurn(d − s, a, φ).trip.galaxyTime` (8.796343), ship = 2 × `.shipTime` (1.240885) within 1e-9, and within 1e-4 of 2 × `coastAt(d − s, 0.99)` = 8.796338 / 1.240876 (valid for τ_b ≤ 19 min; §Interfaces assumed); news epoch at α Cen = `t − (d−s)` within 1e-9; `gap_years` = `t − tau` exactly; dwell adds equally to τ and t; strict VM = interpreter | `make sim strict` (`scriptedRoundTrip`) |
| AC2 | News tiers: fixtures hit all five; α Cen is `<1`, the return `5–15`; template choice seeded and replayable; numerals only in slots | `make sim tools-test` |
| AC3 | Commit is final in the real UI: re-plan, cancel and Commit mid-transit each get `committed`, state unchanged; no save/load path | `make playthrough SCRIPT=adversarial`; `! grep -rniE "save_game\|load_game\|ResourceSaver" interior ui` |
| AC4 | Display audit over the full minimum playthrough on the approved bundle: 0 mismatches, 0 unbound numerals, ≥ 500 samples, both clocks and the ISM readout on every transit sample, codex bodies hash-equal | `make playthrough display-audit` (`tests/display_audit.gd`, Godot headless) |
| AC5 | Replay byte-identical incl. `record` intents and archive unlocks; VM = interpreter; AI process count during replay 0 | `make replay SESSION=$(SCRATCH)/session.ndjson && make parity-m4` |
| AC6 | AI optionality: `AI=none`, `AI=stub` and `AI=digits` all complete with the audit passing. With `AI=digits`, the session log holds `ai_fallback{reason: "ai_numeral"}`, the news item's `body_source` is `fallback`, and the panel shows the fallback notice with the `ai_numeral` phrase. With `AI=none`, `body_source` is `template` and there is no notice. With `AI=stub`, `body_source` is `ai` with the "generated" tag | `make playthrough AI=none`, `AI=stub`, `AI=digits` (each followed by `make display-audit`) |
| AC7 | Minimum-path proxy ≤ 360 s (the R1 bar per D-14); each leg 45–120 s at default warp (expected 62.0 s) | `make playthrough playthrough-time` (`sim/tools/session_audit.ail` `playthroughTime`, AILANG) |
| AC8 | ISM readout, live and plan, at 0.99c on the 4.37 ly scripted target: `load_w_m2` 2.21961e5, `drag_n` 23.2598, `glow_w_m2` 2.40719e-5 with ε = 1e-9 and f_in = 0.5, each within 1e-3 relative of the package value (V12). `drag_energy_j` at arrival (the ledger's `drag_j` since commit; M2 semantics F·c, V24) is 1.36530e17 within 1e-3, and the ledger integral equals `cruiseDragEnergy(n, φ, R, dCoast)` within 1e-9 (ratio 0.9999999999999999 in V24; burn contribution 0 by construction; tick bound ≤ 1e-9; M4.1). glow_pole_w_m2 = glowEmittanceAt(n, φ, ε, f_in, 1.0) from the package release carrying M4.6a; interim expectation 9.62878e-5 (= 4 × V12's glowInwardFlux, hand-derived, not a package value until M4.6a). Each value also equals its HB row (HB-40, HB-49, HB-53, HB-45 via K) at that row's printed significant figures (V14). At β = 0 all are 0 | `make sim` (ISM fixture) and `make lore-values` |
| AC9 | CPU physics: `ship_basis`, projection reference, α Cen cruise mirror (`coastAt` and `planBurnCoastBurn` values from V12), ISM load, glow values and the profile against `glowEmittanceAt`, finite flux at stand-offs; no hand-computed γ or 1−β | `make test` (`physics`, `lint-precision`) |
| AC10 | GPU golden G-M4-1 (≤ 0.75 px, pan-invariant), G-M4-2 (≤ 1/255), G-M4-3 (≤ 0.75 px, all three phases), G-M4-4 (profile and absolute pole value ≤ 1 %, 0 at rest) | `make golden` |
| AC11 | Reference renders in `renders/m4/` on the approved bundle, reviewed by Mark | `make capture-m4`; `grep -n "S1 sign-off" design_docs/implemented/r1/m4-report.md` |
| AC12 | Bench p99 < 16.7 ms at 2560×1440 | `make bench SCENE=bridge` |
| AC13 | Bundles valid (fixture and delivered): alpha, camera round trip ≤ 1 px, GLB metres/Y-up | `make validate-areas` |
| AC14 | Art is swappable data: replacing the area bundle (blockout ↔ bridge v1 fixture) needs no code change; `validate-areas` passes for both and the slice runs on each | `make validate-areas BUNDLE=tests/fixtures/areas/bridge_blockout && make validate-areas BUNDLE=assets/areas/bridge && make m4-smoke BUNDLE=tests/fixtures/areas/bridge_blockout` |
| AC15 | Lore numbers cannot drift: every entry's `unlock` is a known hint and every number binds to its listed checks (HB-n or RS-n); the HB rows with package functions agree with the package; `m4:glow_eps` ≤ HB-61; the drifted fixture fails; strict VM = interpreter | `make lore-values lore-check` and `make lore-check LORE=tests/fixtures/lore/drifted.md` exits non-zero |
| AC16 | Codex unlocks: the minimum playthrough unlocks the seven expected entries at their hints, in order (M4.7), and the codex shows only unlocked entries | `make playthrough codex-unlocks` (`sim/tools/session_audit.ail` `codexUnlocks` against `tests/expected_unlocks.json`, AILANG) |
| AC17 | The vendored lore matches its manifest (fail-closed, CI included) and, where the sibling checkout exists, the design repo at the manifest's sha | `make lore-import CHECK=1` |
| AC18 | `make test` green locally and in CI (incl. `lore-check`, `lint-precision`, and `python-guard` with no new `*.py`: M4 adds no Python); `make strict` and every parity target green; M2's old-message tests unmodified | GitHub Actions `CI` |

The first draft's AC8 (3-new-player playtest) is removed from R1 (D-14).

## Sub-milestones and estimates

| ID | Scope | LOC (code + tests) | Depends on | Art-gated |
|---|---|---|---|---|
| M4.0 | Bundle loader, blockout test fixture, `validate-areas`, `ship_frame` | 250 + 150 | — | no |
| M4.1 | `consequence.ail`: Earth clock, news epoch and tier, display fields, live `ship.ism` (M2 has the plan-view ISM), news `body_source`, legacy log, archive hint predicates, `record`, stand-off; `scriptedRoundTrip` | 380 + 320 | M2 protocol and planner; M4.6a (for glow_pole_w_m2) | no |
| M4.3a | Transit loop, warp, boost/brake pacing, HUD (incl. ISM), arrival card, on a sky-only harness scene | 200 + 80 | M4.1, M2 map | no |
| M4.4 | News panel, templates, AI relay, return trip, legacy screen ⏸ S4 | 250 + 100 | M4.1, M4.3a | no |
| M4.7 | Lore import, codex UI, unlocks, registry, `lore-check` (AILANG) | 180 + 140 | M4.1; design repo `lore/archive/`, `higgs-bubble.md`, `relativity-spec.md` §7 | no |
| M4.5 | Playthrough bot, display audit, replay/parity, time proxy | 120 + 230 | M4.3a, M4.4, M4.7, M2 replay | no (final run on the approved bundle) |
| M4.2 | Interior scene, composite, glow overlay, walking, interactables | 380 + 100 | M4.0, M1.3/M1.5 (any valid bundle) | **yes** |
| M4.3b | HUD and transit moved into the interior | 40 + 30 | M4.2, M4.3a | **yes** |
| M4.6a | `medium.glowEmittanceAt` in `sunholo/relativity`, with tests/CHANGELOG/release; sim pin + lockfile + bundled cache bumped together | 20 + 40 | — | no |
| M4.6 | CPU tests and `lint-precision` (not gated); golden G-M4-1..4, `capture-m4`, bench (gated) ⏸ S1 | 80 + 130 | M4.2, M1.6b | partly |
| | **Total** | **1,900 + 1,320 ≈ 3,200** | | |

**Order (review early, tweak as we go).** Track A (sim and UI) starts when M2's
protocol lands: M4.6a ∥ M4.0 ∥ M4.1 (M4.1's `glow_pole_w_m2` waits for M4.6a) → M4.3a → M4.4 ∥ M4.7 → M4.5, plus M4.6's CPU tests
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
| The glow is too faint to see, or reads as a heat bloom | ε = 1e-9 (D-15, a scenario parameter); G-M4-4 pins the profile, the absolute pole value and zero at rest; S1 looks at the cruise frame. At 0.99c the pole emits 9.6e-5 W/m²; whether that reads at the slice default follows from ε and M1.5's exposure alone, and a different look is a scenario ε, never a hidden gain |
| Double tonemap dims the starbow, or the starbow lands in the wrong place | G-M4-2 (single HDR tonemap); one `ship_basis` with CPU tests; G-M4-3 in every phase |
| The destination star blows up (1/r²) or merges with its companion; AI text slips a number on screen | 1,000 AU stand-off, M1.2 tiers, finite-flux test; `ai_numeral`, AC6 |
| Lore in the design repo changes after import | Vendored with sha; `lore-import CHECK=1` flags it; `lore-check` re-runs on every import |
| A lore number rounds differently from its check value | The match rule is defined on shown significant figures; the drifted fixture is the positive control |
| Headless rendering; 60 fps with the M1 medium tier (50,000 stars at `15cde03`, V20) + toon pass | Audits use labels and state only; window-resolution sky, medium tier |

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

**New questions raised by quorum round 1 (2026-10-03):**

4. **α Cen distance: HB-4 (4.37 ly) vs the catalogue after D-19 (4.32 ly).**
   The HB journey rows (HB-20 to HB-26, HB-51 to HB-58) and the Archive's
   `two-clocks` and `ism-glow` entries are computed at d = 4.37 ly, with no
   stand-off. Once M1.2 lands D-19, the HUD will show the catalogue's
   4.32 ly less 1,000 AU, about 1 % shorter. Archive prose and HUD would then
   disagree on "Sol → α Cen" in the third significant figure. Both are honest,
   but a player can see both. **Recommendation:** a design-repo change that
   sets HB-4 to the catalogue value and regenerates the dependent HB rows
   and entries from the package, with lore-check proving the entries.
   **Default (M4 proceeds):** M4 asserts AC1 and AC8 on a scripted 4.37 ly
   target, the catalogue playthrough asserts only the package relation, and
   the M4 report lists the gap. This is a canon change in the normative
   physics doc, so it is Mark's call. The loop does not edit it.
5. **CI access to the private design repo** for `lore-import CHECK=1`
   half (ii). **Recommendation:** a read-only deploy key for
   `sunholo-data/stapledons-design`, stored as a CI secret and recorded in
   `infra/gcp/setup.sh` alongside the other infrastructure. **Default:** CI
   runs the fail-closed self-consistency half only. The cross-repo half runs
   in every loop iteration and attended session, where the sibling exists.
   Adding a credential is an infrastructure decision, so it is Mark's.

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
  `lore-check`, `display-audit`, `playthrough-time`, `codex-unlocks`.
  **No Python** (CLAUDE.md "Python"; `make python-guard`): `sim/tools/{lore_import,
  lore_values, lore_check, session_audit}.ail` (AILANG; `session_audit` has
  the entries `playthroughTime` and `codexUnlocks`); `tools/validate_area.gd`
  and `tests/display_audit.gd` (Godot headless `--script`); the `lore-import`
  file copy is shell glue. The earlier draft's
  `tools/{display_audit, playthrough_time, validate_area, lore_check,
  codex_unlocks}.py` are withdrawn, since each held logic under test, which
  rules out the `harness` role. `tests/{playthrough_min, adversarial,
  expected_unlocks}.json`, `tests/fixtures/lore/drifted.md`.
- **Package (M4.6a):** `medium.glowEmittanceAt` in `sunholo/relativity` (the next
  release after 0.5.1, pinned in V23), with tests, CHANGELOG and `[release] kind`; the sim's
  pin, the lockfile and the bundled cache move together.
- **Report:** `design_docs/implemented/r1/m4-report.md` (S1/S2 sign-offs,
  renders, bench, proxy time, lore-check output, upstream AILANG reports).
- **At landing:** the R2 roadmap gains the human playtest (protocol from this
  doc's first draft); design-repo roadmap status; changelog entry.

## Verification log

Run on 2026-10-01 at `e9d35c5` (main) and `fe16790`
(`origin/spike/iso-bridge`), read-only. Rows V9–V11 added by the D-11/D-12/D-14
revision (scratchpad `m4.py`). **Superseded as provenance (quorum round 1):** V4 grepped 0.3.0, and the game now pins 0.5.1 (V15); V9–V11 came from an out-of-tree scratchpad. Their numbers are re-derived from the package in V12 (AILANG) and cross-checked in V13 (Python oracle). V11's verdict "matches D-11's worked estimates (2.7e17 J, 3 kg)" is corrected by V19: those were the brief's flat-mirror estimates, and D-11's ruling text has no numbers.

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

### Quorum round 1 and 2 rows (V12–V25)

Run on 2026-10-03, read-only. Game `15cde03`; spike `4eda978`; design repo
`1ef3bc9` (`origin/main`, which contains `736db38`); `sunholo/relativity`
0.5.1 from the bundled cache; AILANG v0.51.0 (`runtime/bin/ailang`). `P` is
`runtime/cache/registry/sunholo/relativity/0.5.1` and `D` is
`../stapledons-design`.

| # | Claim | Command | Observed | Verdict |
|---|---|---|---|---|
| V12 | The numeric backbone, from the pinned package by name | `ailang run --quiet --package-dir sim --caps IO --entry main probe.ail` (source below), with and without `--bytecode`; `sed -n 143p sim/protocol_test.ail` | φ 2.6466524123622457, γ 7.088812050083356, s 0.01581250740982066 ly, d−s 4.35418749259018; `planBurnCoastBurn`: galaxyTime 4.398171425676279, shipTime 0.6204427104843891, τ_b 1.7979782 min, dCoast 4.354171763726048; `coastAt`: 4.398169184434525 / 0.620438114787203; `loadScale` 221961.2727892787; `kineticFlux` 192575.53743413047; `mirrorDragForce` 23.25982143207345; `cruiseDragEnergy` 1.365299549837781e17 J (dCoast), 1.3702626714214504e17 J (4.37 ly), 1.519100620656987 kg; `glowInwardFlux` 2.407194217926631e-5 (0.99c), 0.2812710757682347 (0.999999c); 1/`glowInwardFlux`(ε=1, f_in=½, 0.999999c) = 3.555289e-9; `photonDriveEnergy(1, φ)` 2.3786925619268595e17 | True. VM = interpreter (`cmp`). The glow at 0.99c equals M2's own fixture value `0.000024071942179266308` (`sim/protocol_test.ail:143` reads `ism: {dragN: tiny(), holdW: 70791174749363.73, loadWM2: 2253353077.7286806, glowWM2: 0.000024071942179266308}, cmbForwardK: 3853.730994033574 }`) |
| V13 | Independent oracle (Python, a second language; not a source) | `python3 -c` with the closed forms of higgs-bubble.md §3, §5 and §6 (c, m_p, ly and AU as in `medium.ail`) | t 4.398169184434525, τ 0.6204381147872031, load 221961.2727892786, drag 23.25982143207344, E 1.3653044818001112e17 (over d−s), K 192575.53743413038, glow 2.40719421792663e-5 | Agrees with V12 to ≤ 1e-15 relative |
| V14 | higgs-bubble.md carries the sphere rows M4 depends on | `git -C $D show origin/main:physics/higgs-bubble.md \| grep -n 'HB-'` | `\| HB-40 \| Load scale at 0.99c \| 2.22 × 10⁵ \| W/m² \|`; `\| HB-41 \| … in suns \| 163 \| sun \|`; `\| HB-45 \| Kinetic-energy flux K if thermalised, at 0.99c \| 1.93 × 10⁵ \| W/m² \|`; `\| HB-49 \| Drag force on the sphere at 0.99c \| 23.3 \| N \|`; `\| HB-53 \| Ship-frame drag energy, α Cen at 0.99c \| 1.37 × 10¹⁷ \| J \|`; `\| HB-54 \| … E/c² \| 1.52 \| kg \|`; `\| HB-61 \| Design guide: largest ε for a mean inward glow ≤ 1 W/m² at 0.999999c with f_in = ½ \| 3.6 × 10⁻⁹ \| — \|`; also HB-1 100 m, HB-3 0.1 cm⁻³, HB-4 4.37 ly, HB-15 1,000 AU, HB-16 7.0888, HB-17 2.6467, HB-35 2.379 × 10¹⁷ J/kg | True. Each equals V12 at its printed s.f. (HB-53 and HB-54 are at d = 4.37 ly). The table holds the sphere values, not D-11's flat mirror |
| V15 | The package exports the functions named in this doc | `grep -n '^export' $P/journey.ail $P/medium.ail $P/kinematics.ail`; `sed -n 165,180p $P/journey.ail` | journey: `Trip`, `TripPlan`, `TripPhase`, `planFlipAndBurn`, `planBurnCoastBurn`, `phaseAt`, `motionAt`, `flipAndBurn`, `burnCoastBurn`, `coastAt`; medium: `cSI` … `astronomicalUnitM`, `photonDriveEnergy`, `loadScale`, `kineticFlux`, `mirrorDragForce`, `mirrorDragPower`, `cruiseDragEnergy`, `glowInwardFlux(n, phi, eps, fIn)`, `TripEnergy`, `tripEnergy`, `brakeHoldsAgainstDrag`; kinematics: `gammaOf`, `oneMinusBeta`, `rapidityOfBeta`, `standardGravity` 1.032295275553596. `coastAt(distance, beta) -> Trip`: "Pure coast at constant beta (instant acceleration idealisation)", shipTime = d/sinh φ, galaxyTime = d/β | True at 0.5.1. No angular glow function exists, hence `glowEmittanceAt` (M4.2, M4.6a). Once M4.6a lands, V23 supersedes this note with the new release and its export line. `sim/ailang.toml` pins `"sunholo/relativity" = "0.5.1"`, as does the lock |
| V16 | Lore entries exist with the front matter the importer reads; hint vocabulary; ids resolve | `git -C $D ls-tree -r --name-only origin/main lore`; per file `git show … \| awk` front matter; README "Unlock hints" and "Unit aliases"; every `checks` id grepped as `^\| ID \|` in higgs-bubble.md + relativity-spec.md | 10 entries + README (bubble, cmb-forward, ism-glow, nothing-crosses, one-g, photon-drive, shadow-ring, starbow, tides, two-clocks), each with `id, title, unlock, checks`. Unlocks: `always` ×3, `first_commit`, `first_boost`, `cruise_above_0.9c` ×2, `cruise_above_gamma_275`, `first_black_hole` ×2. 60 distinct ids (48 HB, 12 RS); 0 missing | True, but the old M4.7 hint grammar (`start`/`event:<kind>`) and the numeric unit table were wrong. Both are replaced by the README's (M4.7) |
| V17 | Brief §9 manifest fields vs the M4.0 loader | `git -C $D show origin/main:art/ship-interior-blender-brief.md \| awk '/^## 9/,/^## 10/'` | `area`; `layers.panorama{file, parallax 0.15}`; `layers.play{file, iso_pitch_deg −14, iso_yaw_deg 45, iso_size_m 16}`; `layers.foreground{file, parallax 1.6}`; `camera`; `focus_m [−8, 1, 9]`; `sky_visible`; files `play_/pano_/cam_/fg_<area>`, previews review-only; GLB collections `WALK_`, `SPAWN_`, `INTERACT_` | True. M4.0's schema now lists these field for field; `placeholder` is a declared game-side optional extension |
| V18 | What M2 (landed) already provides | `sed -n 99,102p;203,223p;405,437p sim/core.ail`; `sed -n 74,78p sim/protocol.ail` | `defaultParams`: `boostG 750000.0, mEffKg 1.0, ismNCm3 0.1, bubbleRadiusM 100.0, glowEps 0.000000001, glowFIn 0.5`; `planIntent`: d = norm(target − here), `planBurnCoastBurn(d, p.boostG * standardGravity(), rq.cruisePhi)`, no stand-off; `planView.ism` at peak φ from `mirrorDragForce`, `mirrorDragPower`, `loadScale`, `glowInwardFlux`; params echo includes `glow_eps`, `glow_f_in` | True. ε = 1e-9 is already the sim default (D-15). M4.1 owns the stand-off and the live ISM |
| V19 | "Drag numbers halved vs D-11" | `grep -n '^\| D-11 ' design_docs/stapledon-mission.md`; higgs-bubble.md §5 | The D-11 ruling text gives no drag numbers ("drag energy ~ gamma*d shown as a READOUT"). §5: "The 2026-10-01 brief's worked estimates used a flat face-on mirror, which doubles them. The values below are for the sphere, which is canon (design-decisions 2026-09-28)." | Not a divergence from an attended ruling. The sphere values are canon, and V12 reproduces them from the package |
| V20 | Catalogue, fixtures, PR and star-count claims | `grep -o '"Gl 559[^}]*}' data/starmap/stars.json`; `head -c 200 data/starmap/stars_medium.json`; `git ls-tree -r --name-only origin/spike/iso-bridge \| grep bridge`; `gh pr view 16` | α Cen A and B `dist_ly 4.37` (pre-M1.2; D-19 moves them to 4.32); medium tier `count 50000`; `spike/v2/{bridge_slice.glb, cam_bridge.json, stapledon_pano_bridge.png}`, `spike/v3/stapledon_fg_bridge.png` present at `4eda978` (descends from `fe16790`); PR #16 MERGED 2026-10-01 | True. The "331k stars" in the risks was stale and is corrected to the medium tier |
| V21 | The AI fallback is already a recorded sim event; news cap | `grep -n -i fallback sim/ai.ail`; `grep -n maxCharsFor sim/ai.ail` | `EFallback({req, reason})` → event `ai_fallback` on every refused `record`, `ai_cancel` and expiry (`sim/ai.ail:58,163–167,274,287`); `maxCharsFor(purpose) = if purpose == "archive" then 600 else 280` | True. M4 adds the player-visible `body_source` and `fallback_reason` on top of it (M4.1, M4.4) |
| V22 | Design-repo pin and visibility | `git -C $D rev-parse origin/main`; `git -C $D diff --stat 736db38 origin/main`; `git -C $D show origin/main:physics/higgs-bubble.md \| shasum -a 256`; `gh api repos/sunholo-data/stapledons-design --jq .visibility` | `1ef3bc96…`; only `journey-system.md` and `r1-foundations.md` changed since `736db38`; higgs-bubble.md sha256 `79505e263917810ff1142b786aadc4bab48a1eab63221893c7187a65789eb583`; `private` | True. CI cannot read the sibling without a credential (open question 5) |
| V23 | **PENDING until M4.6a lands.** The package release carrying `glowEmittanceAt` (kimi round 2) | Pin the new version in `sim/ailang.toml`, `sim/ailang.lock` and `runtime/cache`, then re-run the V12 probe extended with `glowEmittanceAt(n, phi, 1e-9, 0.5, 1.0)`; `grep -n '^export' $P/medium.ail` at the new version | Expected: `glowEmittanceAt(n, phi, 1e-9, 0.5, 1.0)` = 4 × `glowInwardFlux(n, phi, 1e-9, 0.5)` (interim hand-derived 9.62878e-5 at 0.99c); the sphere mean of `glowEmittanceAt` = `glowInwardFlux`; VM = interpreter | PENDING. Until then `glow_pole_w_m2` is not a package value, and V15's note stands |
| V24 | M2's drag ledger semantics vs the package closed form; the package check registry (glm round 2) | `grep -n drag sim/core.ail sim/protocol.ail`; `sed -n 77p $P/medium.ail`; `probe2.ail` = the V12 probe plus the lines below, run with and without `--bytecode`; `grep -n -E '^export' $P/*_test.ail \| wc -l`; `grep -n check51 $P/*.ail \| wc -l`; `grep -n -E 'pure func check[0-9]+' $P/*_test.ail \| wc -l` | `core.ail:106` `Ledger = { mEffKg, availableKg, boostJ, dragJ }`; `:165` (manual/diag tick path) and `:327` (autopilot: `if i == 1 then {l \| dragJ: l.dragJ + mirrorDragPower(ismPerM3(p), tp.phiPeak, p.bubbleRadiusM) * piece * julianYearS()}`, burns add `boostJ` only); `protocol.ail:155` emits `drag_j`; `medium.ail:77` `mirrorDragPower(n, phi, r) = mirrorDragForce(n, phi, r) * cSI()`. Probe: `mirrorDragPower` 6973119039.76238, `mirrorDragForce × cSI()` 6973119039.76238, × 0.99 = 6903387849.364756, `loadScale × πR²` 6973119039.76238; tauCoast 0.6204358735454498 yr; `cruiseDragEnergy / (mirrorDragPower × tauCoast × julianYearS())` = 0.9999999999999999; ledger closed form 1.3652995498377811e17; pole hand-derived 9.628776871706524e-5; planBurnCoastBurn t_e 0.043983933086098936 (coastAt 0.04398169184434497); VM = interpreter. Registry: 0 exported test symbols, 0 `check51`, 74 private `checkNN` predicates | True. The power is F·c (not F·v), so the ledger integral equals `cruiseDragEnergy` and AC8 keeps 1.36530e17. There is no `rel:check` registry, so M4.7 source (a) uses `pkg:<function>(<args>)` ids |
| V25 | M2 codebase claims cited in M4.1 (gemini round 2) | `grep -n drag_j sim/core.ail`; `grep -n dragJ sim/core.ail`; `grep -n 'planBurnCoastBurn(4.37' sim/core_test.ail`; `sed -n 600,603p sim/core_test.ail`; `sed -n 60p sim/core_test.ail`; `sed -n 143p sim/protocol_test.ail` | `drag_j` in `core.ail`: no hits (exit 1). The field is `dragJ` in the core (`:106, :135, :165, :327`) and is named `drag_j` only on the wire (`protocol.ail:155`). `core_test.ail:439` `let want = planBurnCoastBurn(4.37, a, phi099());` and `:615` `let tp = planBurnCoastBurn(4.37, 750000.0 * standardGravity(), phi099());`; `:600–602` "The ledger at arrival equals tripEnergy(plan, m_eff, n, R).total to 1e-9 relative"; `:60` `cruised.ledger.dragJ > 0.0`; `protocol_test.ail:143` `glowWM2: 0.000024071942179266308` | True. M2's ledger accumulates drag per tick, its tests pin a 4.37 ly target, and the glow fixture matches V12's 2.407194217926631e-5 |

**V12 probe** (`probe.ail`, sha256 `8e56e48f…`; kept here so anyone can rerun
it; the sprint lands it as the seed of `sim/tools/lore_values.ail`):

```ailang
module probe
import std/io (println)
import pkg/sunholo/relativity/journey (planBurnCoastBurn, coastAt)
import pkg/sunholo/relativity/kinematics (standardGravity, rapidityOfBeta, gammaOf)
import pkg/sunholo/relativity/medium (loadScale, kineticFlux, mirrorDragForce, cruiseDragEnergy, glowInwardFlux, photonDriveEnergy, astronomicalUnitM, lightYearM, cSI)

export func main() -> () ! {IO} {
  let phi = rapidityOfBeta(0.99);
  let s = 1000.0 * astronomicalUnitM() / lightYearM();
  let d = 4.37 - s;
  let a = 750000.0 * standardGravity();
  let p = planBurnCoastBurn(d, a, phi);
  let c0 = coastAt(d, 0.99);
  let n = 100000.0;
  let pmax = rapidityOfBeta(0.999999);
  println("phi=${phi} gamma=${gammaOf(phi)} s_ly=${s} d=${d}");
  println("plan galaxyTime=${p.trip.galaxyTime} shipTime=${p.trip.shipTime} tauBurn_min=${p.tauBurn * 525960.0} dCoast=${p.dCoast}");
  println("coastAt galaxyTime=${c0.galaxyTime} shipTime=${c0.shipTime}");
  println("load=${loadScale(n, phi)} K=${kineticFlux(n, phi)} drag=${mirrorDragForce(n, phi, 100.0)}");
  println("Edrag_dCoast=${cruiseDragEnergy(n, phi, 100.0, p.dCoast)} Edrag_437=${cruiseDragEnergy(n, phi, 100.0, 4.37)} kg=${cruiseDragEnergy(n, phi, 100.0, p.dCoast) / (cSI() * cSI())}");
  println("glow099=${glowInwardFlux(n, phi, 0.000000001, 0.5)} glow999999=${glowInwardFlux(n, pmax, 0.000000001, 0.5)} epsmax=${1.0 / glowInwardFlux(n, pmax, 1.0, 0.5)}");
  println("boostJperKg=${photonDriveEnergy(1.0, phi)}")
}
```

**V24 probe extension** (`probe2.ail`, sha256 `2778d668…`). It is the V12
probe with `mirrorDragPower` and `julianYearS` added to the `medium` import
and these lines appended to `main`:

```ailang
  let pw = mirrorDragPower(n, phi, 100.0);
  let fc = mirrorDragForce(n, phi, 100.0) * cSI();
  println("mirrorDragPower=${pw} FxC=${fc} FxCx099=${fc * 0.99} loadxpiR2=${loadScale(n, phi) * 3.141592653589793 * 10000.0}");
  println("tauCoast_yr=${p.tauCoast} ratio=${cruiseDragEnergy(n, phi, 100.0, p.dCoast) / (pw * p.tauCoast * julianYearS())} ledgerClosed=${pw * p.tauCoast * julianYearS()}");
  println("pole_handderived=${4.0 * glowInwardFlux(n, phi, 0.000000001, 0.5)} t_e=${p.trip.galaxyTime - d} t_e_coast=${c0.galaxyTime - d}")
```

**Which instrument produces which value:** every trip, ISM, glow and
energy number in M4.1, M4.6, AC1, AC8 and AC9 comes from V12 (the package
through AILANG, VM = interpreter). V13 (Python) is only a second-language
oracle. The HB rows (V14) are the design repo's canon, and the
registry checks them against V12-style package evaluation at their printed
precision (M4.7 source (a) vs (b)). The warp and proxy seconds are
arithmetic on V12's ship-years (0.620438 / 0.01 = 62.04 s). The CMB 38.4 K
is HB-62 and comes from M2's `cmbForwardK`.

## Quorum round 1 response

Artifact `.ailang/state/mission-quorum/m4-first-journey-2026-10-02T21-52-56Z.json`
(BLOCKED, 3/3 reject). For each objection: the surface, whether this
revision introduced it or it was pre-existing, what changed, and the evidence.

| Reviewer | Surface | Introduced or pre-existing | What changed | Evidence |
|---|---|---|---|---|
| gemini-3-1-pro | Silent fallback: rejected AI text, and "the template stands" with no player-visible sign (M4.1, M4.4) | **Pre-existing** (the first draft had the same wording; the sim already emits `ai_fallback`, so the gap was presentation only) | The sim owns `news.body_source ∈ template/ai/fallback` and `fallback_reason`. On `fallback` the panel shows a fixed notice plus the reason in words, and the item appears in the Archive news tab's diagnostics list. `template` (no request made: no key, AI off, text-only) shows no notice, because D-8 makes it the designed default and the HUD AI indicator already says AI is off. AC6 asserts all three paths. Consistent with D-7 (recorded inputs), D-8 (text-only), D-20 (AI intents while committed) and D-21 (no digits, 280 chars). No new ruling is assumed | V21; M4.1 "AI results are inputs"; M4.4 "AI path"; AC6 |
| oc-glm-5-3 | Design-repo premises unverified; ε unassigned; drag "halved vs D-11"; lore front matter; brief §9 schema | **Pre-existing** (V1–V11 stopped at the game repo). The doc's "ε × load" glow formula was also wrong against higgs-bubble.md §6, which defines the glow on K | Design repo pinned at `1ef3bc9`, with the HB rows quoted (V14, V22). ε = 1e-9 stated (D-15; the sim default; ≤ HB-61) and f_in = ½; both registered as check values. Glow corrected to `glowInwardFlux` = ε f_in K/4. G-M4-4 (b) adds an absolute pole-value gate: K-based, not the reviewer's "ε × load", for the reason just given. Drag: D-11 has no numbers, and HB §5 makes the sphere canon (V19). Lore front matter verified; the hint vocabulary and unit aliases now follow the README (V16). M4.0's schema follows brief §9 field for field (V17). AC8 says "at the HB row's printed s.f." | V14, V16, V17, V18, V19, V22; M4.0, M4.1 ISM, M4.2 glow, M4.6 G-M4-4, M4.7, AC8 |
| oc-kimi-k3 | Package functions asserted not verified (V4 grepped 0.3.0); goldens from scratchpad `m4.py`; `coastAt` unexplained; AC1's 1e-4 clause silently bounds τ_b; minor claims (fixtures, PR #16, 331k); CI skips the lore drift check | **Pre-existing** (V4 predates the 0.5.1 pin; `m4.py` was the iter-10 revision's instrument). The premise "no ISM export" is **stale at HEAD**: 0.5.1 `medium.ail` has them all (V15) | Numbers re-pinned to named 0.5.1 functions, produced by an AILANG probe (V12, VM = interpreter) with a Python oracle labelled as such (V13); `m4.py` retired. `coastAt` is the τ_b → 0 reference in AC1, and the sim does not use it as a trip. The τ_b bound is made contractual: τ_b = 1.80 min at D-15's boost, and the clause holds for τ_b ≤ 19 min (§Interfaces assumed). Fixtures, PR #16 and the star count verified, and 331k corrected to 50,000 (V20). `lore-import CHECK=1` now fails closed in CI on manifest self-consistency; cross-repo needs a credential (open question 5). One new package function (`glowEmittanceAt`) goes in package-first (gate 3) | V12, V13, V15, V20; M4.1 journey, §Interfaces assumed, AC1, M4.6, M4.7 Import |
| controller | AC4/AC7/AC15/AC16 and the deliverables named Python tools | **Pre-existing** | All five are replaced: `lore_check`, `playthrough_time` and `codex_unlocks` by AILANG (`sim/tools/lore_check.ail`, `session_audit.ail`); `validate_area` and `display_audit` by Godot headless scripts. None qualified as `harness`, because each holds logic under test. AC18 asserts `python-guard` with no new `*.py` | `tools/python-allowlist.txt` roles; M4.0, M4.5, M4.7, Deliverables, AC4, AC7, AC15, AC16, AC18 |

**Also found while verifying (pre-existing, fixed in this revision):** the
glow formula (above); the lore hint grammar and unit-conversion table
(V16); M2 has no stand-off, so M4.1 owns it (V18); the α Cen catalogue
distance will move under D-19 (V20, open question 4).

## Quorum round 2 response (narrow-refinement carve-out)

Artifact `.ailang/state/mission-quorum/m4-first-journey-2026-10-03T04-12-08Z.json`
(round 2, BLOCKED; round-1 revision committed as `474d261`). This revision
applies each reviewer's own `proposed_fix` text and invents no other
resolution. The design direction is unchanged. Both kimi and glm asked for a
row numbered "V23", so kimi's is V23, glm's is V24, and gemini's is V25.

| Reviewer | Fix applied (from the reviewer's proposed_fix) | Where | V row |
|---|---|---|---|
| oc-kimi-k3 | "Split M4.6: add row 'M4.6a: `medium.glowEmittanceAt` in `sunholo/relativity`, with tests/CHANGELOG/release; sim pin + lockfile + bundled cache bumped together — Depends on: — ; Art-gated: no'" | Sub-milestones table (M4.6a row; M4.6's LOC reduced by M4.6a's 20 + 40, total unchanged); M4.2 "Package first"; M4.6 intro; Order; Deliverables | V23 (PENDING) |
| oc-kimi-k3 | "Change M4.1's 'Depends on' to 'M2 protocol and planner; M4.6a (for glow_pole_w_m2)'" and "'ship.ism ships in two steps: load/drag/glow_w_m2 at pin 0.5.1; glow_pole_w_m2 is added only after M4.6a lands — the sim never computes 4 × glowInwardFlux itself.'" | M4.1 row; M4.1 ISM bullet (sentence verbatim); §Interfaces assumed "ISM and glow" | V23 |
| oc-kimi-k3 | AC8 pole row rewritten: "glow_pole_w_m2 = glowEmittanceAt(n, φ, ε, f_in, 1.0) from the package release carrying M4.6a; interim expectation 9.62878e-5 (= 4 × V12's glowInwardFlux, hand-derived, not a package value until M4.6a)" | AC8 | V23, V24 (prints the hand-derived 9.628776871706524e-5) |
| oc-kimi-k3 | "Add verification-log row V23 … re-running the V12 probe extended with `glowEmittanceAt(n, phi, 1e-9, 0.5, 1.0)`, asserting it equals 4 × `glowInwardFlux(n, phi, 1e-9, 0.5)` and that its sphere mean equals `glowInwardFlux`; update V15's note once the function exists" | V23 (PENDING); V15 note now says V23 supersedes it once M4.6a lands | V23 |
| gemini-3-1-pro | "Add a verification log row with commands to explicitly verify these codebase claims (e.g., `grep -n drag_j sim/core.ail` and `grep -n 'planBurnCoastBurn(4.37' sim/core_test.ail`)" | V25; M4.1 ledger prose cites the lines | V25 |
| gemini-3-1-pro | "add a command to V12 that legitimately extracts the value from `sim/protocol_test.ail:143`" | V12 command (`sed -n 143p sim/protocol_test.ail`) and its observed line | V12, V25 |
| oc-glm-5-3 | "commands grep -n drag sim/core.ail sim/protocol.ail, plus a probe extension printing mirrorDragPower(1e5, phi, 100.0), mirrorDragForce(1e5, phi, 100.0) * cSI(), that value times 0.99, and cruiseDragEnergy(1e5, phi, 100.0, dCoast) / (mirrorDragPower(1e5, phi, 100.0) * cruiseShipTime)" | V24 and the probe extension | V24 |
| oc-glm-5-3 | "if M2 has no drag_j ledger, add the accumulator to M4.1's scope" | **Not triggered.** The M2 ledger exists (`core.ail:106, :327`; `protocol.ail:155`), so no scope or LOC change | V24, V25 |
| oc-glm-5-3 | "state drag_energy_j's window explicitly (since commit, with the burn-phase contribution … and a tick-discretization bound declared inside the 1e-3 budget)" | M4.1 ISM bullet. The measured burn contribution to `drag_j` is 0 by construction (M2 omits it; the reviewer's ~1.2e-6 is noted as their estimate). Tick bound ≤ 1e-9 | V24 |
| oc-glm-5-3 | "Re-pin AC8 to the verified semantics: if mirrorDragPower = loadScale * pi * R^2, keep 1.36530e17 within 1e-3 and add the clause 'ledger integral equals cruiseDragEnergy within [stated bound]'" | AC8. Measured: F·c = `loadScale × πR²`, ratio 0.9999999999999999. Bound stated as 1e-9 | V24 |
| oc-glm-5-3 | "M4.1's news-epoch prose must use the planBurnCoastBurn arrival t = 4.398171 (t_e = 0.043984), not the coastAt limit" | M4.1 "Light-delayed news epoch" | V24 (t_e 0.043983933) |
| oc-glm-5-3 | "confirm the rel:check51-style package check registry actually exists" | **It does not.** M4.7 source (a) now registers `pkg:<function>(<args>)` ids evaluated from exported functions | V24 |
