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

## dev11 review delivery

Runtime source: `0e91c712b1e3dbcf30ff6c64a1ab9ed62c111f96`.
Build: `v0.4.0-dev.11-solar-departure`.
ZIP SHA256: `4044bb76250f5120fb6accb8a5165d7e6b631d5836ffd8f582a75ebd8dfe51fb`.

Full local regression suite: 261/261 AILANG checks, plus the Godot/package
checks; final focused source checks and GPU planet/ring optics gates passed.
The exported app passed current startup, native exact-star map handoff, guided
Solar departure, all nine bundled planet textures, 49 sky captures and staged
bridge interior checks using fresh HOME and system-only PATH.
Independent bounded review evaluation: 94/100 PASS. Whole sprint remains in
progress: external simulation-driven sunlight on ship geometry, M2 Air
performance and further art remain pending. Native exit retains nonfatal
resource diagnostics; no zero-warning shutdown claim is made.

Selected final captures are on the [gallery](https://www.sunholo.com/stapledons-godot/gallery)
and [ship reference](https://www.sunholo.com/stapledons-godot/docs/ship-layer-reference).
`capture-manifest.json` contains 13 frozen observer/clock/exposure records.
`benchmark-aggregate.json` contains 1920×1080 stop comparisons (120 warmup,
300 samples). Studio wall intervals include vsync and do not establish Air
performance. Internal ship lighting remains a fixed warm-key/cool-fill study;
planet sunlight is separately package-driven.
