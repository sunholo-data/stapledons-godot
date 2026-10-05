# Solar departure review

One explicit new demo session starts near Earth, makes physical stop intercepts
at Jupiter and Saturn, then travels to the catalogue's Alpha Centauri A with
a 1,000 AU stellar stand-off. Successive legs start at the previous endpoint;
there are no position resets between legs. Body positions come from the pinned
`sunholo/celestial` package. In-system cruise is 0.002c; the outbound leg uses
the simulation's default cruise rapidity. Each nonzero phase gets roughly
20 presentation seconds. At stops, one real second advances one ship second.

The Earth position is the published Earth–Moon barycentre approximation.
Stops are inertial, not gravity-bound orbits. GR is not implemented. These
limitations are shown in the demo and prevent close-orbit precision claims.

Use **New Solar departure** in the current ship. **Pause tour** lets you inspect
a stop; **Next stop** skips the stationary dwell. It cannot skip a committed
leg. **M** pauses guidance and opens the same map for browsing and framing;
guided mode blocks manual planning/commit/cancel. Resume using the ship button.
**7** looks forward/up; pan with Option-drag to compare other sky directions.

Reproduce with `make solar-departure-test solar-departure-capture`.
The normal controller checks actual endpoints, all phases, safe stand-offs and
both clocks. A strict-VM/interpreter trace independently checks four endpoints.
Resolved planets and rings use inverse aberration of each observed ray, with
package-backed radiometry, shared exposure and opaque-body star inspection masks.

Only selected, inspected native screenshots are published to the gallery.
Initial overexposed development captures were withheld until metering was fixed.
