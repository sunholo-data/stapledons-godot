# Star colours in Auto view, and a longer approach to a giant

| Pillar | Alignment | Reason |
|---|---:|---|
| Choices Are Final | 0 | No change to commitment. |
| The Game Doesn't Judge | +1 | Auto view says what it changes; Realistic stays physical. |
| Time Has Emotional Weight | +1 | The giant grows over a minute and a half instead of appearing at once. |
| The Ship Is Home | 0 | No ship change. |
| Grounded Strangeness | +2 | Stars show the colour of their real temperature; the approach keeps the true kinematics. |
| We Are Not Built For This | +1 | The scale of a giant is felt on arrival. |

**Status:** Approved by Mark, attended 2026-10-07 (ledger D-49): "lets have auto mode dim enough to have pretty star colours, and yes lets make a longer approach for bigger stars".
**Release:** R1, dev.20. **Follows:** [finite-destination-stars.md](finite-destination-stars.md) (D-47/D-48), [m4-even-legs-and-approach.md](m4-even-legs-and-approach.md) (D-46), exposure views (D-38).

## Problem (dev.19 review)

1. Aldebaran (3,927 K) read white at 40°: the Auto fader aimed a star's disc centre at 16× mid-grey, where the AgX tone mapper desaturates every highlight.
2. Aldebaran is already 4° across 6 AU out, so the D-46 25 s approach had to start at γ ≈ 800: a starbow for 19 s, then the giant appeared in the last 6 s.

## Design

1. **Auto view star colours.** A star's disc centre aims at 1.2 (just above any lit body, 0.5 × texture peak 2) and, in Auto view only, its own blackbody tint is lifted 2.2× in chroma (`planet.gdshader` `star_saturation`). Realistic view is untouched. The HUD's Auto line adds "star colours enhanced". Measured centres at the stops: Aldebaran (234, 201, 128) golden orange, TRAPPIST-1 red-orange, the Sun a warm white (211, 207, 205). Trade-off: in Auto the Sun is no longer the single brightest pixel (the dev.15 rule); the GPU check now asserts a warm white with its tint order.
2. **A giant's approach.** `giantTiming()`: 30 s boost, about 60 s cruise, then a **90 s** approach from where the star is **25°** across. Entry is about 0.996c (γ ≈ 12) instead of γ ≈ 800; the apparent disc grows about 0.8° → 7° → 18° → 40° (offline model, rapidity form, aberration of the limb). Main-sequence stars and planets keep the 25 s / 4° rule.

## Acceptance

| ID | Check | Command |
|---|---|---|
| C1 | The Auto-view Sun is a warm white with R ≥ G ≥ B | `godot --path . --script tools/exposure_auto_view.gd` |
| C2 | Exposure behaviour otherwise unchanged | `make manual-exposure-test` |
| C3 | Aldebaran's plan has a 90 s approach and 30 s boost; the voyage flies it in real time (1,800 ticks) | `make solar-departure-test`, sim test `checkGiantApproach` |
| C4 | Renders: Aldebaran golden orange at its stop; the approach frames at 0, ½ and 0.85 of the approach show the disc growing | `godot --path . --script tools/real_time_tour_capture.gd`, inspected |
| C5 | Everything else green | `make test` |
