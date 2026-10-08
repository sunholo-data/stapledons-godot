# Inspect the system you are in (I key)

| Pillar | Alignment | Reason |
|---|---:|---|
| Choices Are Final | 0 | Read-only inspection; nothing is planned or ticked. |
| The Game Doesn't Judge | +1 | Facts and their provenance (measured, assumed, source). |
| Time Has Emotional Weight | +1 | "The light you see left it … ago" at every body. |
| The Ship Is Home | 0 | No ship change. |
| Grounded Strangeness | +2 | Real sizes, distances and temperatures of the bodies around you. |
| We Are Not Built For This | 0 | |

**Status:** Requested by Mark, attended 2026-10-08: "when we click I can we also see the info for the systems we are close by to? … I button highlights background stars, but not the one we are orbiting".
**Release:** R1, dev.21. **Extends:** [m4-ship-star-identification.md](m4-ship-star-identification.md).

## Problem

Holding I rings and inspects catalogue stars only. Finite bodies are drawn by `SystemView`, not the starfield: the Sun, planets, moons, α Cen A/B, Aldebaran, TRAPPIST-1 and its planets were never offered, so the star you are orbiting was the one thing you could not inspect.

## Design

- `SystemView.last_system` keeps the system section it last drew.
- The I overlay adds each body at its drawn, aberrated centre (`StarLight.apparent_direction`, already cross-checked against the renderer), ringed at its apparent disc size (warm ring), hidden behind the ship and behind nearer bodies exactly as catalogue stars are.
- A click anywhere on a body's disc picks the nearest drawn body, not the catalogue stars around it.
- Planets and moons of a distant system (unresolved, beyond 1,000 AU) are not offered: at TRAPPIST-1 the Solar System's 18 invisible planets and moons do not clutter the Sun.
- The card (`ui/body_info.gd`): name; star, or planet/moon of its host; distance from the ship; radius (R☉, R♃ or R⊕) and apparent size; surface temperature for stars; how long ago the light left it; catalogue identity (with "Open in map"); the body's own source line.

## Acceptance

| ID | Check | Command |
|---|---|---|
| I1 | A planet ahead is a candidate at its drawn centre, sized by its disc; a click on the disc opens its card with the right distance; a body behind a nearer one is not offered; a star beside a planet is still the one clicked; card text units | `make ship-star-identification-test` |
| I2 | The card fits on screen | same |
| I3 | Every guided-tour stop: the stop's body is inspectable with its facts; at TRAPPIST-1 only visible bodies are offered | `godot --path . --script tools/inspect_bodies_capture.gd` (renders/inspect_bodies, inspected) |
| I4 | Everything else green | `make test` |
