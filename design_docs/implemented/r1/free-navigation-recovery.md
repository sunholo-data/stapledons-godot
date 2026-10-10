# Free-navigation start, destinations and arrival recovery

| Pillar | Alignment | Reason |
|---|---:|---|
| Choices Are Final | 0 | Committed journeys retain the existing autopilot and refusal rules. |
| The Game Doesn't Judge | +1 | Refusals explain the concrete cause. |
| Time Has Emotional Weight | +1 | Live idle time advances in real time; arrival remains inspectable. |
| The Ship Is Home | +1 | The navigation list stays in place while the captain selects. |
| Grounded Strangeness | +1 | Start outside Earth; retain package ephemerides and inertial motion. |
| We Are Not Built For This | 0 | No safety checks or drive limits change. |

Net +4: aligned, go.

**Status:** Implemented in [PR #199](https://github.com/sunholo-data/stapledons-godot/pull/199); complete local and matching CI gates passed, independent evaluation 97/100. Native OS pointer capture remains unverified as documented in the [report](free-navigation-recovery-report.md). **Original approval:** Approved by Mark's attended 2026-10-10 request to fix free navigation: destinations swap, Sun/Earth/Mars refuse, moving initial view, Earth disappears after arrival. **Release:** R1. **Priority:** urgent defect. **Implements:** D-54 destinations and [journey planning](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/journey-planning-ui.md), [physics specification](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md). **Depends on:** existing body planner, Solar initialization and live map pacing. **Estimate:** 180 implementation/test LOC plus documentation.

The distance-sorted system list rebuilds when nearby bodies change order. Ordinary `sol` starts at the Sun's centre, so body collision checks correctly refuse destinations. Live idle ticks advance a day per wall second: Earth moves away from the inertial arrival point almost immediately. The review sky also defaults to a moving snapshot; the host milestone applies the new live world immediately.

Add an explicit `free_nav` scenario from protocol 2.7, using the existing safe Solar initializer at 50,000 km from Earth's centre, on its dayside, with zero initial velocity. Preserve historical `sol` and all recorded inputs. Keep fixed inventory order with moons beside their hosts; reuse button identities and refresh distance tooltips. Live map idle ticks use real time; the ordinary diagnostic map retains its established clock. A presentation pause sends pending intents with zero elapsed simulation time; committing resumes automatically. Explain committed, moving, collision, distance, speed and stale-plan refusals. Host integration selects the new scenario and labels inertial Earth standoff accurately.

Stops are inertial geometric clearance, not gravity-bound orbits. No attachment to the ephemeris, body teleport, instantaneous braking, new dynamics or physics formula is introduced. Long inertial dwell naturally changes body position; a 60-second live dwell must keep Earth resolved and safely outside its radius.

| AC | Evidence | Command |
|---|---|---|
| F1 | Explicit free start is at rest outside Earth; legacy sol origin unchanged; older minors refuse the new scenario | `cd sim && ailang test --strict-bytecode free_nav_test.ail` |
| F2 | Sun, Earth and Mars plan from the new initial state with unchanged clearance checks | same |
| F3 | Fixed hierarchy and button IDs survive changed body distances; live idle advances 60 seconds rather than 60 days | `godot --headless --path . --script tests/test_free_nav_recovery.gd` |
| F4 | Earth arrival remains resolved and outside its surface through 60 seconds of live idle; replan remains possible | same |
| F5 | New scenario stream matches strict VM/interpreter; existing protocol recordings remain compatible | focused protocol parity, followed by root `make test` |
| F6 | Actual map defaults to visible ISM; explicit checkbox and D stay synchronized; Local ISM frames Sol without intents | `godot --headless --path . --script tests/test_free_nav_recovery.gd` |
| F7 | Default unmodified mouse look; Tab, I, console, arrival, focus loss and exit release pointer; UI motion never turns view | `make ship-ui-test`; native `godot --path . --script tools/free_nav_review.gd` |
| F8 | Cloud depth construction guides off by default, optional in a visible control; shell outlines retained, no apparent rays from Sol | `make map-ism-test free-nav-recovery-test` |
| F9 | P and visible Pause/Resume freeze elapsed simulation time and preserve the committed course; pending intents still work and commitment resumes time | `make free-nav-recovery-test ship-ui-test` |

Mark's attended follow-up also requests the ISM map be visible and discoverable. The actual map enables the existing layer at load, labels its warm-cloud scope and light-year units, offers a checked **Interstellar medium [D]** control, and offers **Local ISM** to frame Sol at about 30 ly. The underlying generic helper still starts hidden for standalone callers. The existing source/assumption legend remains on the overlay. Only the LIC and Redfield–Linsky local warm clouds ship here; dense-cloud PR B remains deferred.

Implementation milestones and review are recorded in [the sprint](free-navigation-recovery-sprint.md). Root owns host input, pause/finish controls and initial live-view application; this independent milestone owns scenario, list, pacing and navigation regressions. Root integration and independent evaluator review passed before landing.
