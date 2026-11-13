### The ship's detector and the evidence ledger (R3-REASONS RT2a, simulation only)

Nothing changes on screen or on the wire yet. The simulation can now work out what the ship's instruments record of each world from where the ship is: a 10 m coronagraphic telescope (zodiacal light included) and a 100 m radio dish, both from `sunholo/observe` 0.2.0's photon and link budgets. A record needs a signal-to-noise ratio of 5 ("a hint"); 10 is "strong".

- What a world shows follows from its true state when the light left it, never from its state now. A civilisation that ended after its light left still shows.
- Records: a planet seen directly or in transit, oxygen (with or without methane) and the vegetation red edge from a directly imaged planet, and radio leakage. Oxygen alone carries its false-positive note. A silence is recorded only for a world the ship already knows is there.
- Transits depend on where the ship is. A transit gives the planet's presence only: reading air in transit has no check values yet, so worlds too close to their star to image (TRAPPIST-1 e, for one) get no oxygen reading.
- At cruise only a coarse census runs: planets by direct imaging after a one-hour look, in directions where the Doppler shift keeps the light inside the instrument's design band.
- `make lore-values` now lists the 52 OB rows of `physics/observation.md`, and `make lore-check` binds Archive numbers to them.

Requires `sunholo/observe` 0.2.0, which is built but not yet published; until it is pinned, `make evidence-test` runs through `tools/observe_dev.sh`.
