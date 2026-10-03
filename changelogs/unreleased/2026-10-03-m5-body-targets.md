### Added

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

### Changed

- `core.ail` dispatches the body form to `sim/navigation.ail` (34 lines added). `Plan` gains `nav` (`None` for a star plan). A body plan goes stale at commit once the Earth clock has moved.
- Home is now the target id `"Sol"`, not catalogue index 0. The map's index 0 is Proxima Centauri, which therefore got no M4 stand-off (M4.2 finding). `standoffFor` takes the id.
- `protocolVm` now runs the four 2.3 checks on the strict VM too.
- From minor 4 the hello reports the pinned relativity release (0.7.0). Minors 0 to 3 keep the old string, "0.4.0", so that every recorded stream and golden stays byte-identical.
- Documented: the star's `sun_dir` is the zero vector (`celestial.ail`, the protocol notes, the bridge).
- Design `m5-planets.md` §M5.1 now matches the landed M5.1b: `systemAt(sys, jd, shipLy)`, `kind` and `ring_id`, `SimBridge.system`, and the Sun at 1.2706e5 lux. §M5.5 records the choices M5.5a made. In the sprint plan, M5.5b and M5.7 now depend on celestial 0.1.1 (the Earth-Moon barycentre split).
