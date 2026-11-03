# R3-TRUE-PROCESSED: the feed's colour and the ship's star light made exact

**Status:** Planned 2026-11-02, executing (attended parallel agent "Claude D", ledger D-144: "the True/Processed physics fixes (feed tint, ship star light) run now"). Visual landing stops for Mark's render review.
**Release:** R3. **Milestone:** the standing order of 2026-10-30 applied to the two compromises it names that are already built (the sound's was AR8b; the home beacon is R2-SOUND's).
**Priority:** P1. Both compromises are on screen today, and both teach the wrong thing.

**Implements:**
- stapledons-design `vision/design-decisions.md`, [2026-10-30] *Standing Order: No Compromises on the Physics; True and Processed Settings*, "Applies to": "the feed's tint bands (R3-EARTH-LINK EL3b.3)" and "the ship's star-light brightness mapping (R1-SHIP-STAR-LIGHT, log-compressed)". The template is D-38 (Realistic/Auto) and D-55 (Auto the players' default), as AR8b followed it for the sound.
- stapledons-design `features/next/signals-and-instruments.md` §3.1 (Earth's link, strictly: an optical laser link carrying data; wavelength 1/D, playback rate D, received power D²/d²).
- `physics/relativity-spec.md` §2: Doppler, point-source brightness F'/F = (Y(D·T)/Y(T))/D², colour by Planck × CIE; §7 RS-26..RS-30 (the Earth rate at the feed's bands). New qualitative check RS-Q5 (proposed, design-repo draft PR): a frame decoded from the link keeps its colours at every D.
- This repo: [earth-link.md](../../implemented/r3/earth-link.md) row "Doppler tint" (superseded here), [ship-star-light.md](../../implemented/r1/ship-star-light.md) goal 3 (the log map, superseded as the True rule; kept as Processed), [bridge-styling-pass.md](../../implemented/r2/bridge-styling-pass.md) (the spire keys the bridge in deep space, D-96/D-100).

**Depends on:** main at `6d92d2cb` (R3-EARTH-LINK and AR8b landed). The sim's `system` bodies (`e_v_lux`, `teff_k`) and `earth.rate`. No sim, protocol or package change.
**Estimated LOC:** about 650: star light 140, demo wiring 30, feed 40 (mostly removal), tests 260, capture tools 120, prose 60.

## Game vision alignment

Scored with the `game-vision-designer` skill (feature-validation mode) against `vision/core-pillars.md` (last changed 2026-09-27) and the standing orders of 2026-10-28 (visual first; the Archive teaches the real physics) and 2026-10-30. **ALIGNED.**

| Pillar | Score | Rationale |
|---|---|---|
| Choices Are Final | 0 | No change to any commit or decision |
| The Game Doesn't Judge | 0 | No new cue. The feed's warm/cool wash read as "leaving is sad, coming home is cold" more than as physics; it is gone |
| Time Has Emotional Weight | +1 | The feed now changes only where the physics changes it: home's time runs slow or fast (exact, unchanged), and the picture is home exactly as sent. The Sun's light shrinks by the inverse square as you leave, and the ship's own lamps take over |
| The Ship Is Home | +1 | In deep space the spire is the bridge's light (D-96); near a star the true sunlight floods the deck and the lamps fade beside it, as they would. The ship's controller can still balance the two (Processed) |
| Grounded Strangeness | +2 | The real numbers: sunlight at 1 AU is 1,600 times the bridge's lamps; at Neptune they are close to equal; the picture from home does not change colour, because colour is in the data, not in the carrier |
| We Are Not Built For This | +1 | The eye cannot hold sunlight and a lamp-lit room at once; the True view shows the eye adapting, and the Processed view is the ship's instrument doing what eyes cannot |
| **Net** | **+5** | **Go.** No pillar is negative |

## Problem

1. **The feed's tint is a cartoon.** `data/ui/comms_feed.json` `bands` lay a fixed wash over the picture by Earth rate D: `#F2967E` at alpha 0.24 (still, D < 0.01) and 0.14 (slow), none (real), `#7F9CFF` at 0.14 (fast) and 0.24 (torrent). `ui/earth_feed.gd` draws it as a `ColorRect`, and `tests/test_physics.gd` `test_earth_feed_bands` asserts "warm below 1, cool above". The canon link (signals §3.1) is an optical laser carrying data. A Doppler shift moves the carrier (1 µm arrives at 14 µm at D = 0.071) and the playback rate (D), but a frame decoded from that data has the colours Earth encoded. The wash shows a shift that does not happen, at a strength chosen by hand, and the label says so ("a stylized indicator, not a spectral render").
2. **The ship's star light is log-compressed.** `demos/ship_star_light.gd` computes the seen illuminance exactly (sim `e_v_lux` × the spec's point-source ratio × eclipse transmission), then maps it to energy by `2.5 × log10(E / 1 lx) / 5`. Decades become equal steps: the Sun at 1 AU (1.27 × 10⁵ lx) is 2.5, at Jupiter (4.7 × 10³ lx) 1.8, at Neptune (141 lx) 1.1, beside a spire of 8 that is itself dimmed by the star's "share". The deck at Neptune looks half sunlit; in truth the Sun there is as bright as the bridge's lamps. The ship's own lamps are dimmed as the star rises, with a 25% readability floor, which is a ship decision presented as lighting.

Measured on `main` (`6d92d2cb`, `make ship-star-light-capture`): the before renders are in the review set (Deliverables).

## Goals and non-goals

Goals:
1. **Feed, True:** the picture exactly as decoded, at every D. The tint is removed from the data, the code and the tests. The bands keep their time behaviour (jumble, drift, whirl, the babble), which is the exact Earth rate. RS-Q5 states the physics, and `tests/test_physics.gd` asserts it at the RS-26..RS-30 values.
2. **Feed, Processed:** none is needed for the picture, and none is invented. The station's existing True/Receiver setting (AR8b) stays the one setting; the receiver's correction applies to what is shifted in the signal, the sound. The doc says so, and so does the comms_feed.json `about`.
3. **Star light, True:** linear in the seen illuminance; the ship's lamps keep their own illuminance; the deck exposed for the eye adapted to it (the rule of `sky/exposure.gd` EYE mode: adapt only when the scene asks for less sensitivity than the lamp-lit deck). Direction, colour, Doppler, aberration and eclipses as today.
4. **Star light, Processed:** today's balance, kept to the last number, named honestly as the ship's light controller: its lamps follow the star's direction and colour at a level compressed to fit (log, 1 lx to 10⁵ lx), and it keeps its own lamps at a readable floor.
5. **One setting, the one players know:** the star light follows the view toggle (V): Realistic (D-38, true) shows the True star light, Auto (D-55, the players' default) the Processed one. The button and the HUD say which.
6. **Renders** for Mark: the feed at several D (before, after, and the option mock-ups), the star light at several distances (before, True, Processed), uploaded to `gs://stapledons-voyage-assets/refs/true_processed_v1/`.

Non-goals:
- The carrier's wavelength readout and the receiver comb (earth-link S2, signals §5).
- One exposure for the deck and the sky. The interior is a separate light study today (`ship_lighting.gd` header); in True the sky keeps its manual EV while the deck adapts. Open question 3.
- Global illumination. The star's bounce off the deck is a labelled ambient term (§D2.4).
- Option B below (the frame as Earth's light). It is mocked, not built: if Mark wants it, its matrix goes to `sunholo/relativity` first (gate 3).

## Design

### D1. Earth's feed

**D1.1 What would the ship actually see?** Earth's feed arrives as data on an optical carrier (signals §3.1, a comb of bands so that one lands in the receivers' range). Received at Earth rate D:

| In the signal | Changes with D | Exact in the game |
|---|---|---|
| Playback rate | × D | yes: the sim's `earth.feed` frame moves with t_e; the band picks jumble/drift/whirl by D (RS-26..RS-30) |
| Carrier wavelength | × 1/D | not shown (S2) |
| Received power | × D² / d² | not shown (S2: what the instruments can recover) |
| Sound content (a waveform) | pitch × D | yes: AR8b, True plays pitch × D, Receiver corrects it |
| **Picture content (pixel values)** | **none** | **after this sprint: the picture is drawn as decoded** |

A waveform's frequencies are times, so playing it at rate D shifts its pitch: that is why the sound has a True and a Receiver setting. A pixel's colour is a number in the frame, not a time: decoding at rate D changes when frames arrive, never what colour they are. So the True picture is the decoded picture, and there is nothing for an instrument to correct.

**D1.2 The options put to Mark** (mock-ups at D = 0.071, 0.5, 0.8, 1, 1.25, 2, 14.1 in the review set, made by a throwaway spike in the scratch directory, not in the tree):

| Option | What True shows | Physics | Recommendation |
|---|---|---|---|
| **A. Decoded (built)** | The frame as Earth sent it, at every D | Exact for the canon's data link | **Recommended.** It is the truth for the link the game has, and it costs nothing to read |
| B. The frame as Earth's light | Each pixel's visible spectrum (the minimum-norm spectrum S = cmf^T G^-1 XYZ) shifted by D, I_λ,rx(λ) = D⁵ I_λ(Dλ), so XYZ_rx = D⁴ [∫ cmf(μ/D) cmf(μ)^T dμ] G^-1 XYZ: a 3 × 3 matrix per D | Exact for a picture made of light (a telescope looking at Earth), not for a broadcast. Black outside about 0.6 < D < 1.7: at 0.99c the visible band came from 28–50 nm or 5.6–9.9 µm at Earth, which the frame does not hold | Not as the feed. Worth an Archive illustration ("if the ship could see Earth's own light"), with the matrix in `sunholo/relativity` |
| C. Today's tint | A hand-picked wash by band | None | Rejected by the standing order |

**D1.3 Built (option A).** `comms_feed.json` bands lose `tint` and `tint_alpha`; `EarthFeed` loses its `tint` ColorRect; the picture's `self_modulate` stays white in beam at every D (grey under static out of beam, unchanged). The `about` says the colour is exact and why. `test_earth_feed_bands` asserts: no band carries a colour, the band names at RS-26..RS-30 unchanged, and the picture drawn in beam is unmodulated at each of those D. `tests/test_earth_feed.gd` asserts the same through the real feed (no tint node; the picture's modulate white at fast and slow D). earth-link.md's "Doppler tint" row is marked superseded (as its sound row was by AR8b).

### D2. The ship's star light

**D2.1 Physical inputs (unchanged).** E, the seen illuminance at the ship (lx): sim `e_v_lux` (the star's luminosity at its distance, `sunholo/celestial`, checked by `checkSysSunLux`: 1.27 × 10⁵ lx × (1 AU / d)²) × the spec's point-source ratio (Y(D·T)/Y(T))/D² at the apparent angle (the sim's γ and 1 − β) × the renderer's own eclipse transmission. ŝ, the apparent (aberrated) direction in interior axes. The colour, blackbody at T·D.

**D2.2 The lamps' calibration (one constant; Mark chose 80 lx photometric on the review page, 2026-11-02).** Godot light energy is not a physical unit, and a light's photometric output is its energy × Y(its linear colour). The spire at its base (energy 8, D-100) has the warm colour (1, .80, .58), Y = 0.6658, so for it to light the bridge deck at 80 lx one unit of photometric energy at normal incidence is `LUX_PER_ENERGY = 80 / (8 × 0.6658) = 15.0185` lx (evaluation B7: round 2 used 10 lx per unit of raw energy, so the spire was really 53.3 lx and star : spire at 127,000 lx came out 2,384, not 1,587.5). The same constant calibrates every ship lamp and the star: the lower decks' broad key (1.5, colour (1, .82, .65), Y = 0.6966) is 15.7 lx; the fill, the practical and the Commons lamps follow it. E_ship is the deck's lamp illuminance, photometric (the spire's base on the bridge, the key's below). The GPU golden measures it: G-TL-1 (a unit of photometric energy renders a unit of deck luminance), G-TL-5 (an 80 lx True star and the production spire's energy and colour, on a directional surrogate at normal incidence, light the same deck equally, ratio 0.9997; the omni's range window is geometry, not calibration) and G-TL-N3 (the round-2 calibration fails, ratio 1.50). The star's bounce is mixed with the ship's ambient as linear radiance and encoded to sRGB for the Environment (evaluation B8: round 2 assigned the linear mix unencoded, so the ambient lost 12–39%); G-TL-6 checks it on the GPU at 2566, 5772 and 11544 K (ratio 0.9996–0.9999) and G-TL-N4 shows the round-2 mix fails (0.80). Not light sources, so not calibrated: the spire lamp's emissive glow (scene radiance under the exposure gain) and the console glow overlay (a display cue, display-referred).

**D2.3 True.**
- **Physical (the claim):** the star light's photometric output is E / `LUX_PER_ENERGY` at any colour: energy = E / `LUX_PER_ENERGY` / Y(colour), the colour at a unit max channel as in Processed (evaluation B1: dividing by the max channel alone gave 2566 K only 55.6% of the Sun's light at equal lux). Linear, so star : lamps = E / E_ship exactly in photometric light (1,587.5 at 127,000 lx against the spire's 80 lx, measured by the test).
- The lamps keep their base energies (no dimming, no floor: lamps do not dim because the Sun is up).
- **Presentation, not a physical claim (evaluation B4):** the exposure is an eye model on the deck, the display's choice, like the sky's `Exposure` meter (whose EYE rule is GDScript too). Meter E_meter = E_ship + E × f(y), y = ŝ·up, f(y) = (1 + y) / 2 for y ≥ 0 (1 overhead, 1/2 level with the deck, where the guided tour puts the Sun) and f(y) = (1 + y)/2 × max(0, 1 + y / 0.2) below the deck plane (cut off as the star sinks 11.5° below the rim). Adaptation x = E_ship / E_meter ≤ 1 (light-adapt only toward less sensitivity, `Exposure`'s EYE rule): 1 in deep space (today's look), about 1/795 at 1 AU with the Sun level with the deck. It makes no claim about light, so it stays in GDScript and needs no package (gate 3 applies to physics maths; the illuminance it exposes comes from the package mirrors). It is applied as one gain on all scene radiance the rig drives: the star, the lamps, the spire lamp's glow (evaluation B2: it had stayed at 2.5 beside sunlight), the fill, the practical and the ambient. **Display-referred, labelled Processed in every setting:** the captain's painted figure (unlit art; a tonemap exposure turned it black in the first trial render, and a Sprite3D modulate cannot lift it), the console screens and the markers keep their display level. The manifest (`display_referred`) and the HUD line say so. A lit captain and physically exposed screens are open question 5.
- Shadow ownership by the star's share of the direct light, E / (E + E_ship), on the existing handover ramp (exactly one shadow map).
- **Bounce (labelled, D2.4):** the star's light off the deck fills the shadows: ambient += `BOUNCE` × E × f(y) / `LUX_PER_ENERGY`, in the star's colour, with `BOUNCE = 0.1` (a deck of albedo about 0.3 seen over half the sky). Without it sunlit shadows would be black, which is the renderer's lack of global illumination, not physics.
- Eased as today (energy, colour, direction, TAU_S 0.5 s); the exposure follows the eased values. The Tab HUD line names the setting and the exemptions but shows no renderer-derived ratio or exposure numbers (evaluation B5, D-21); they stay in the manifest as diagnostics. The seen-illuminance number (lx) on the line predates this sprint.

**D2.4 What the numbers show** (True, the Sun straight overhead, `LUX_PER_ENERGY` 15.0185 lx per photometric unit, the spire 80 lx, bridge):

| Where | E (lx) | Star : lamps | Eye's adaptation x | What you see |
|---|---|---|---|---|
| Earth, 1 AU | 1.27 × 10⁵ | 1,588 : 1 | 1/1,589 | daylight; the spire's glow and the lamps vanish; hard shadows with bounce |
| Jupiter, 5.2 AU | 4.70 × 10³ | 59 : 1 | 1/60 | sunlit; the lamps a faint warmth in the shadows |
| Saturn, 9.6 AU | 1.38 × 10³ | 17 : 1 | 1/18 | sunlit, lamps visible in shade |
| Neptune, 30 AU | 141 | 1.8 : 1 | 1/2.8 | the Sun and the spire light the deck about equally |
| Interstellar | < 10⁻³ | 0 | 1 | the spire alone (D-96) |

**D2.5 Processed (the ship's light controller).** Today's mapping exactly: energy = 2.5 × log10(E / 1 lx) / 5 (0 at 1 lx, 2.5 at 10⁵ lx), lamps dimmed by the star's share down to the 25% floor, exposure 1. The manifest, the HUD line and the view button call it Processed: "the ship's lamps follow the star, brightness compressed to fit". It is an instrument a real ship could have (lamps that track the sun's direction and colour, like a heliostat-matched skylight), and it is the only setting where light on the deck is not the star's.

**D2.6 The setting.** `StarLight.mode` is `"true"` or `"processed"`, default `"processed"` for a bare StarLight (every existing direct test keeps its numbers). `ship_geometry_demo.set_auto_view(on)` sets it: Realistic → True, Auto → Processed, so D-55's player default (Auto) keeps today's look and developer/test launches (Realistic) show True. The visible label is the view tag ("REALISTIC" / "AUTO"), the Tab view button ("View: Realistic (True): one exposure, true starlight [V]" / "View: Auto (Processed): bodies faded to fit, ship lamps follow the star [V]"), and the star-light HUD line.

### D3. R3-TRUE-PROCESSED-b: the Doppler indicator (Processed, follow-up)

**Mark, 2026-11-03** (after approving #374 with option A): *"I like that the blue tint appears when we blueshift... we always want the 'real' view available, and then a visible auto adjustment, but that auto adjustment is indicative of what is happening."* So the cue returns as a Processed instrument indicator, never on the picture.

- **Where (an instrument overlay, Processed only):** the feed screen's bezel, a `bezel_px` (6 px) frame, and a soft edge overlay that bleeds in from it (Mark, 2026-11-03: "perhaps it can bleed in from the edge?"): a linear fade from opacity = the strength at the screen's edge to nothing at `vignette_frac` (10%) of the screen's short side, drawn above the picture and its ghosts. The picture, its ghosts and the static live in a fixed clipping `Screen` control inset by the bezel, so the slow band's drift and the torrent's jumbled ghosts never reach the bezel or cover the overlay (evaluation #384 B1). **RS-Q5 in the game:** the decoded picture is never altered in True; in Processed a labelled edge overlay sits above it (the decoded pixels underneath are unchanged, which is all RS-Q5 states about the physics, so the spec row needs no change).
- **When:** only in the station's Receiver (Processed) setting, in beam. Labelled at the top centre "Doppler ×D · shown", the number bound to `earth.rate`. The label is an instrument label over the overlay on its themed `HUDEarthFeed` backing, drawn above the overlay so it reads clearly (evaluation #384 B2: chosen over a reserved strip, because Mark asked for the cue to bleed into the picture's margin; the corner tags already sit over the picture the same way). True shows a plain ink bezel, no overlay and no label. The station's one setting (AR8b's True/Receiver button) switches sound and indicator together.
- **Mapping (data, `comms_feed.json` "doppler"; not hand-tuned):** a reference line at `lambda_ref_nm` 555 nm (the photopic peak) is seen at λ = 555 / D. The bezel and the overlay take the spectral colour of λ: the game's CIE 1931 fit (`Blackbody.cmf`), its out-of-gamut colour clipped to sRGB so the hue holds, unit max channel; clamped to `visible_nm` [400, 650], the indicator's limits (not the ends of human vision: the fit's far-red tail drifts orange beyond 650 nm). Strength |ln D| / ln(`d_max` 1414.2, RS-30): 0 at rest, 0.365 at 0.99c either way (RS-26, RS-29), 0.524 at 0.999c (RS-27), 1 at the top speed (RS-28, RS-30); D and 1/D are equally strong. The bezel is ink lerped to the colour by the strength; the overlay's edge opacity is the strength.
- **Gate 2:** `test_physics.gd` asserts λ = 555 / D and the strength at RS-26..RS-30 and rest, the red and violet ends and an in-band hue; `test_earth_feed.gd` asserts Receiver shows bezel, overlay and label (blue closing, red leaving; the overlay above the picture, ghosts and static; the picture in the clipping screen, untouched, also after the drift and the jumble are advanced) and True shows none of them. GPU golden G-EL-2b (`make earth-link-golden`, 25) reads the bezel pixel, an overlay pixel 1.5 px into the screen and the picture centre against an expected colour computed in the golden, independently of EarthFeed's helpers, at RS-26 and RS-29 in Receiver, both again after advancing (the drift, the jumbled ghosts), and in True (ink, no overlay). Disabling the screen's clipping fails the advanced RS-26 case (drilled).
- **Renders:** `make capture-doppler-indicator` (10 frames: RS-28, RS-26, rest, RS-29, RS-30 × Receiver/True), sheets in `refs/true_processed_v1/doppler/` (round 1, the bezel only) and `refs/true_processed_v1/doppler/r2/` (the bezel and the edge overlay).

## Acceptance criteria

| # | Criterion | Command |
|---|---|---|
| AC1 | No band in `comms_feed.json` carries a colour; `EarthFeed` has no tint node; in beam the picture is unmodulated at D = 7.0711e-4, 0.070888, 1, 14.107, 1414.2 | `make earth-feed-test` and `make physics` (`test_earth_feed_bands`) |
| AC2 | The bands' time behaviour is unchanged: the names at RS-26..RS-30, jumble, drift, whirl, the babble | `make earth-feed-test comms-station-test` |
| AC3 | True: the star light's photometric output (energy × Y(colour)) = E / `LUX_PER_ENERGY` × x at any colour (2566 K to 40 kK within 1e-5), lamps at base × x (star : lamps = E / E_ship), x = E_ship / E_meter, the spire lamp's glow under x, the tonemap untouched; share = E / (E + E_ship); bounce as D2.3; a 1 AU to 10⁵ AU sweep monotonic and finite with one shadow owner; TRAPPIST-1 (0.0235 AU, 984 lx) and Aldebaran (0.615 AU, 5.4 × 10⁷ lx) at their planned stops through the production path; production emitters at RS-3/RS-4 carry pointFluxRatio (a D² mutation fails) | `make ship-star-light-test` |
| AC4 | Processed reproduces today's energies, key floor and exposure 1 (every pre-existing assertion of `tests/test_ship_star_light.gd` passes unchanged in Processed) | `make ship-star-light-test` |
| AC5 | The view toggle sets the mode both ways in the real demo; the button and HUD line name it | `make ship-star-light-test` (demo section), `make bh-hud-test` |
| AC6 | Gate 2: the production `StarLight.seen_lux` at RS-3/RS-4 is the package pointFluxRatio (a D² mutation fails, drilled), True light output E / `LUX_PER_ENERGY` at any colour, the inverse square, asserted in `tests/test_physics.gd`; GPU vs CPU: `make true-light-golden` (G-TL-1 absolute within 2%, G-TL-2 equal light at 2566/3927/11544 K within 1%, G-TL-3 RS-3/RS-4 Doppler within 1%, G-TL-4 the gain, G-TL-5 an 80 lx star = the spire (directional surrogate), G-TL-6 the ambient bounce at three temperatures; negatives G-TL-N1 unit-max energy, G-TL-N2 D² mutant, G-TL-N3 round-2 calibration, G-TL-N4 unencoded ambient; 16 cases), in `make golden` | `make physics true-light-golden` |
| AC7 | Renders: the feed at D = 0.071, 1, 14.1 (before and after) and the option mock-ups; the star light at Earth, Jupiter, Saturn, the outbound cruise and the α Centauri approach (before, True, Processed; on main the capture stops at the α Centauri arrival, `capture-arrival-failed: CNS5:3627 ... phase braking`, so TRAPPIST-1 and Aldebaran are checked at their planned stops in `tests/test_ship_star_light.gd`); opened and looked at; uploaded (round 2 after the evaluation under `r2/`) | `make ship-star-light-capture capture-comms-station`; `gsutil ls gs://stapledons-voyage-assets/refs/true_processed_v1/` |
| AC8 | Hygiene | `make uid-guard python-guard ui-theme-check` |
| AC9 | The whole suite on the rig | `tools/rig_check.sh <PR>` posts `rig/full` success |

## Sub-milestones

| Id | Work | LOC | Depends |
|---|---|---|---|
| TP0 | This doc, the sprint plan and JSON; the before renders and the feed option mock-ups | docs | — |
| TP1 | The feed: tint removed (data, code, tests, about), earth-link row superseded | 120 | TP0 |
| TP2 | The star light: True and Processed (`ship_star_light.gd`, the lamps' ambient hooks in `ship_lighting.gd`), tests first | 330 | TP0 |
| TP3 | The setting on the view toggle, labels, `test_bh_hud` | 60 | TP2 |
| TP4 | Gate 2 rows in `test_physics.gd`; RS-Q5 design-repo draft PR | 60 | TP1, TP2 |
| TP5 | Captures in both modes, review set uploaded, draft PR, `rig/full` | 80 | TP1–TP4 |

## Risks and mitigations

- **Large energies in True** (1.27 × 10⁵ / 15.0185 ≈ 8,456 per unit luminance at 1 AU): Godot's lighting is float; the exposure brings the frame back. A shadow leak would show as a hot edge. Mitigation: the star holds the shadow map fully from a share of 0.4 (E = 2/3 E_ship) on the existing handover ramp, and the renders at 1 AU are inspected for leaks.
- **Goldens.** Developer launches are Realistic, so they now show True. Sky-only goldens (`m4_ship_golden` G-CAM-3, `interior_golden` G-M4-2) compare sky pixels and do not see the deck; at cruise no star is near and True equals today. `rig/full` with `--golden` checks it.
- **The lamp calibration is a judgement** (80 lx on the bridge). It changes where the lamps and the star balance (at 80 lx, near Neptune). Open question 2.

## Open questions for Mark

1. **The feed's True (D1.2): A (built, recommended) or B?** A: the picture is home exactly as sent; the shift shows in time (and later in the carrier, S2). B: the frame as Earth's own light, shifted and mostly black at speed; recommended only as an Archive illustration.
2. **The lamps' calibration:** the spire lights the bridge at 80 lx (recommended: a dim evening room, so the Sun and the spire balance near Neptune). 300 lx (an office) would balance near 20 AU.
3. **One eye for deck and sky in True?** When the Sun lights the deck, a real eye adapted to it would not see the stars through the dome. Today the sky keeps its manual EV (D-38) while the deck adapts. Recommendation: a follow-up that lets the Realistic sky follow the deck's adaptation while the star lights the deck, after these renders.
4. **The setting on V:** the star light follows Realistic/Auto (recommended: one setting players already know, and D-55's default keeps today's look for players). The alternative is a separate star-light toggle.
5. **Display-referred surfaces in True (evaluation B2).** The captain's painted figure, the console screens and the markers keep their display level in True and are labelled Processed. Recommendation: keep the labelled exemption now; a lit captain (the art pipeline's job) and screens exposed with the scene (unreadable near a star, which is true) are a follow-up once Mark has seen the True renders.

**Answered:** OQ2's lamp calibration, 80 lx (Mark, review page, 2026-11-02). BOUNCE (0.1) is still open with OQ2.

## Deliverables

- `design_docs/planned/r3/true-processed-fixes.md` (this doc), `-sprint.md`, `.ailang/state/sprints/sprint_R3-TRUE-PROCESSED.json`.
- `data/ui/comms_feed.json`, `ui/earth_feed.gd`, `tests/test_earth_feed.gd`, `tests/test_physics.gd`.
- `demos/ship_star_light.gd`, `demos/ship_lighting.gd`, `demos/ship_geometry_demo.gd`, `tests/test_ship_star_light.gd`, `tests/test_bh_hud.gd`, `tools/ship_star_light_capture.gd`.
- `changelogs/unreleased/2026-11-02-true-processed.md`.
- Review set `refs/true_processed_v1/` (before/after feed, option mock-ups, star light before/True/Processed).
- stapledons-design draft PR: RS-Q5.
