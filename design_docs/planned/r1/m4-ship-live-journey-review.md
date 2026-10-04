# M4 live journey review

| Pillar | Score | Evidence |
|---|---:|---|
| Choices Are Final | +2 | Existing irreversible commit and refusal of cancellation retained. |
| The Game Doesn’t Judge | 0 | Factual phase and clocks, no outcome scoring. |
| Time Has Emotional Weight | +2 | Both clocks advance visibly with explicit compression. |
| The Ship Is Home | +2 | Navigation returns the captain to the bridge during flight. |
| Grounded Strangeness | +2 | Continuous AILANG states drive the audited SR sky. |
| We Are Not Built For This | +1 | Increasing sky distortion conveys the scale of travel. |

Status: Approved continuation (Mark's attended request, 2026-10-04: select and commit, speed up and slow down visibly from aboard ship). Release R1, priority high. Implements [journey design](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase3-gameplay/journey-system.md) and [SR specification](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md). Depends on existing journey autopilot and seven-tier demo. Estimate 250 LOC. Net +9, go.

The fixed 0.1 ship-year/real-second map rate skips minute-scale burns. Opt-in presentation pacing maps each positive burn/coast/brake duration to 20 real seconds, caps ticks at phase boundaries, and sends only proper-time increments to AILANG. No kinematics or sky equations change. Non-live captures and replay keep their current inputs. Demo navigation owns an isolated normal SimBridge session, child Window with its own 3D world, and the existing catalogue and hold ritual. Commit hides navigation automatically; the ship sky updates at 20 Hz. Snapshot shortcuts and benchmarks are unavailable during committed travel. Looking around changes camera attitude only. Arrival remains at rest; another leg starts at its own commit time.

| Acceptance criterion | Command |
|---|---|
| Normal simulator: two selected destinations, monotonic burns with multiple samples, clocks, endpoint, refusal of cancel, offset second leg | `AILANG_BIN=$PWD/runtime/bin/ailang godot --headless --path . --script tests/test_live_journey.gd` |
| Isolated normal demo session; automatic navigation close; sky mirroring; attitude retained; snapshot and benchmark lock | `AILANG_BIN=$PWD/runtime/bin/ailang godot --headless --path . --script tests/test_ship_demo_live.gd` |
| Sequential reachable captain-eye acceleration/coast/braking/arrival renders with metadata | `AILANG_BIN=$PWD/runtime/bin/ailang godot --path . --script tools/ship_demo_live_capture.gd` |
| Frozen-state compatibility | `godot --headless --path . --script tests/test_ship_demo_journey.gd` and `tests/test_ship_demo_input.gd` |
| Runtime cache responds to nested source and dependency changes | `godot --headless --path . --script tests/test_runtime_fingerprint.gd` |
| Native commit and hold controls visible at1280×800 and900×600; viewport click opens dialog | `AILANG_BIN=$PWD/runtime/bin/ailang godot --path . --script tools/ship_demo_live_capture.gd` |
| Native bundled runtime navigation, commit and arrival without PATH | Exported ship demo `-- --ship-demo-smoke` with empty PATH/AILANG_BIN |
| Shared physics regression and shader audit | `make test golden` |

Moving Solar System flyby remains future work.

Risk: variable compression can mislead; HUD names it explicitly and shows both clocks. Existing captures opt out. No open approval questions; this bounded scope was authorized explicitly. Deliverables: pacing, map integration, demo navigation, tests and reference capture.
