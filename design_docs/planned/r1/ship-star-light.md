# Ship lit by the real star

| Pillar | Alignment | Reason |
|---|---:|---|
| Choices Are Final | 0 | No change to commitments. |
| The Game Doesn't Judge | +1 | The HUD and manifest say what is physical (direction, colour) and what is not (brightness, log-compressed). |
| Time Has Emotional Weight | +1 | The Sun's light fades from the bridge as you leave; interstellar cruise is lit only by the ship. |
| The Ship Is Home | +2 | The ship is a place in a sky: sunlight sweeps the bridge as it turns, a red dwarf's light is red on the deck. |
| Grounded Strangeness | +1 | Aberration and Doppler move and tint the light at speed, as they move and tint the star. |
| We Are Not Built For This | 0 | No change. |

Net +5: aligned, go.

**Status:** Approved by Mark for dev.20, 2026-10-07: "Ship lit by the real star — a sun/star-driven light on the ship: direction and colour from the actual star, compressed brightness, sun shadows on the bridge."
**Release:** R1, dev.20. Sprint `R1-SHIP-STAR-LIGHT` ([plan](ship-star-light-sprint.md)).
**Implements:** the follow-up named in `art/ship-lighting-v1/README.md` ("simulation-driven external sunlight on ship geometry") and goal 3, "moving-light shadows", of [m4-ship-lighting-and-solar-departure.md](m4-ship-lighting-and-solar-departure.md). Physics reused, none new: `relativity-spec.md` aberration and Doppler (package `optics.apparentDisc`, `doppler`, `pointFluxRatio`) as already mirrored in `physics/planets.gd` and `sky/sky_meter.gd`.
**Depends on:** the sim's `system` section (finite stars with `e_v_lux`, `teff_k`), `SystemView`'s apparent disc centres and occlusion, the ship attitude shared by the sky and interior cameras.
**Estimated LOC:** about 600 (module 190, test 250, tools 200, wiring 20).

## Problem

The ship's geometry is lit by a fixed study rig (`demos/ship_lighting.gd`): a warm broad key, a cool fill, ambient and the Commons practical. Its key "does not represent the Sun". Leaving Earth, passing Jupiter or arriving at Aldebaran looks the same inside the ship. The renderer already knows where each star is seen, its colour and its illuminance at the ship.

## Goals and non-goals

Goals:
1. A `DirectionalLight3D` "StarLight" from the dominant finite star's **apparent** direction, the disc centre the sky renderer draws, turned into ship-interior axes through the same attitude as the sky camera.
2. Colour: the renderer's blackbody lookup at T × D (Doppler factor at the apparent angle).
3. Energy: a documented logarithmic map of the seen illuminance at the ship, labelled as compressed on the HUD and in the manifest.
4. Smooth: eased energy, colour and direction; hysteresis on the dominant star; eclipses respected.
5. The moody ambient, fill and practicals stay. The broad key dims as the star light takes over, never below a 25% readability floor, and is fully back in interstellar space. Exactly one directional light casts shadows at any time.

Non-goals: physical interior exposure (a display cannot show 10⁵ lx next to a lamp), planetshine, GR, multiple simultaneous star lights, a new package function.

## Design

**Module.** `demos/ship_star_light.gd`, installed beside the rig by `ship_lighting.gd`'s host; `ship_geometry_demo.gd` updates it every frame after the sky's exposure frame.

**Which stars.** Every `system` body with `kind == "star"` and `e_v_lux > 0`, unless the ship is inside it.

**Direction.** `apparent_direction` mirrors `SystemView._draw_disc`: the cap centre from `Planets.apparent_disc64` (package `apparentDisc`) about the sim heading, rest direction at β = 0. Sky (SkyFrame world) → galactic (`SkyFrame.to_galactic64`) → ship (`ShipFrame.to_ship` with the sky's current attitude basis) → interior `(s.x, s.z, −s.y)`, the inverse of `ship_demo_camera.gd`'s `ship_vector`. The light's +Z is that direction, so it shines along −Z from the star.

**Colour.** `Blackbody.lut_rgb(T × D)`, the shaders' lookup, normalised to a unit max channel and converted to sRGB for `light_color`. `D = Planets.doppler_seen64` at the apparent direction with the sim's γ and 1 − β.

**Illuminance at the ship.** `E = e_v_lux × 10^(log Y(T·D) − log Y(T)) / D²` (`pointFluxRatio`, the same expression as `SkyMeter.seen_point`) × the renderer's own occlusion transmission along the apparent ray (`SystemView._directional_transmission`, skipping the star, counting only nearer bodies). The dominant star is the brightest E; another star takes over only when it is 1.5× brighter.

**Energy (not physical).**

```
level  = clamp(log10(E / 1 lx) / log10(1e5 lx / 1 lx), 0, 1)
energy = 2.5 × level          (the moody key is 1.5)
key    = key_base × max(0.25, 1 − level_eased)   (0.25 = KEY_FLOOR_SHARE)
```

| Where | E (lx) | level | star light | broad key |
|---|---:|---:|---:|---:|
| Earth, 1 AU | 1.27 × 10⁵ | 1.00 | 2.50 | 0.38 (floor) |
| Jupiter, 5.2 AU | 4.7 × 10³ | 0.73 | 1.84 | 0.41 |
| Saturn, 9.5 AU | 1.4 × 10³ | 0.63 | 1.57 | 0.56 |
| Interstellar | < 1 | 0 | off | 1.5 (moody) |

Every decade of real illuminance is an equal step. Shadows (`moody` profile only) use the key's tuned bias (0.04, normal 0.3, 100 m).

**Readability floor (ship light, not physical).** `KEY_FLOOR_SHARE = 0.25`: the broad key never drops below 25% of its moody energy, so the deck stays readable when the star is up but below the deck (Earth start, Jupiter arrival). The residual key casts no shadows while the star holds them (Mark's review of the first renders, 2026-10-07).

**Shadow ownership.** Exactly one directional light holds a shadow map. As the eased level rises from 0 to 0.2 the key's shadow opacity fades 1 → 0; at 0.2 the shadow map passes to the star light, whose opacity then fades 0 → 1 by 0.4. The swap happens where both opacities are zero, so nothing pops.

**Easing.** Energy, colour and direction approach their targets with τ = 0.5 s; direction is eased in the sky frame and rotated by the current attitude each frame, so attitude turns never lag the Sun's disc.

**Labels.** HUD details (Tab): "Starlight on ship: Sun · 127000 lx at the ship → 100% light (brightness log-compressed, 1–1.0×10^5 lx; direction and colour physical)". `lighting_manifest().star_light` carries the source, the rest-frame and seen illuminance, D, the transmission, and the three "physical / not physical" statements.

## Acceptance criteria

| # | Criterion | Command |
|---|---|---|
| A1 | Light direction equals the rendered disc centre at rest and at 0.6c (< 0.01°), the textbook aberration (< 0.02°) and D at the apparent angle | `make ship-star-light-test` |
| A2 | The interior and sky cameras put the Sun on the same pixel (< 0.5 px) in 5 attitudes × 2 views; a mirrored axis is caught | `make ship-star-light-test` |
| A3 | Energy zero at or below 1 lx, monotonic, bounded, logarithmic | `make ship-star-light-test` |
| A4 | Colour order by Teff: TRAPPIST-1 < Aldebaran < Sun (blue/red); D > 1 blueshifts | `make ship-star-light-test` |
| A5 | Smooth: fade < 4% of max per 60 Hz frame; a 40° jump turns < 2°/frame; a ±8% near-equal pair never switches | `make ship-star-light-test` |
| A6 | Dark interstellar cruise: no star light, moody key restored; an eclipse blocks the light; key ≥ 25% floor and exactly one shadow-casting directional light from 0.3 lx to 10⁶ lx, continuous handover | `make ship-star-light-test` |
| A7 | The demo installs and drives StarLight; the manifest and HUD label the compression | `make ship-star-light-test` |
| A8 | Inspected renders at Earth, during the departure turn, near Jupiter, Saturn, the outbound 0.999c cruise, the dark interstellar leg, TRAPPIST-1 and Aldebaran | `make ship-star-light-capture` → `renders/ship_star_light/` |
| A9 | Cost measured against the ship-only rig | `make ship-star-light-bench` → `renders/ship_star_light/benchmark-aggregate.json` |
| A10 | `make test` green (the new test runs in `ship-demo-ci`) | `make test AILANG=runtime/bin/ailang` |

## Risks and mitigations

- **Sun below the deck.** At most stops the star is low or behind the floors, so the bridge is in shadow. That is correct; the 25% key floor keeps it readable, and the departure turn shows the sweep.
- **Two shadowed directional lights** while both are partly on. Measured (A9); the key's shadow map is dropped below 2%.
- **Precision near c.** Only the sim's γ and 1 − β enter D; no `1 − β` is computed here.

## Open questions for Mark

1. Resolved: a 25% key floor without shadows (coordinator, from Mark's render review, 2026-10-07).
2. Is 1 lx (deep twilight) the right floor, so Neptune-distance sunlight (~150 lx) still casts faint shadows and α Cen seen from the Sun's side (~10⁻⁵ lx) casts none?

## Deliverables

`demos/ship_star_light.gd`, `demos/ship_lighting.gd` and `demos/ship_geometry_demo.gd` wiring, `tests/test_ship_star_light.gd`, `tools/ship_star_light_capture.gd`, `tools/ship_star_light_bench.gd`, Makefile targets, renders, CHANGELOG entry, `art/ship-lighting-v1/README.md` wording.
