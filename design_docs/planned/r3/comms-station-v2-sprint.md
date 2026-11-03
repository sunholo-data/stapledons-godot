# Sprint R3-COMMS-V2: plan (revision 2)

**Design:** [comms-station-v2.md](comms-station-v2.md) covers the history wall, the frame diagram, moving the comms console closer, the waterfall, and the bridge's monitor wall.

**Status: CV0–CV6 built (2026-11-03). Codex round 1 scored 62/100; round 2 passed at 88/100 with one blocker (paging stacks longer than 52 weeks), now fixed. Landing follows Mark's look.** The mid-point was accepted ("continue"). Landing (moving the docs to implemented/, the README row, the roadmap) follows the evaluation. Progress and gate results are in the sprint JSON.

**Approved, executing.** Mark approved revision 2 on 2026-11-03 ("looks awesome"), with every open question at its recommendation, and added one ruling: the consoles stand underneath the screens (revision 3, design §D2). Main is merged in (AILANG v0.56.1, with #374, #375 and #377 landed), so CV0's wait is over. Execution runs on this branch, `design/comms-station-v2`, under PR #379.

**Progress file:** `.ailang/state/sprints/sprint_R3-COMMS-V2.json`

**Branches:**
- This plan lives on `design/comms-station-v2`.
- Execution happens on the same branch (Mark's go-ahead, 2026-11-03), in the full clone `../stapledons-godot-comms-v2`, never a worktree.

**AILANG:**
- Pin v0.56.1 (main). Run `make runtime`, then `AILANG=runtime/bin/ailang`.
- Prompt version loaded: recorded in the sprint JSON at CV1.

## Summary

| | |
|---|---|
| Goal | The comms station keeps every week of Earth's signal it receives, as a filmstrip with sim-field stamps and static where out of beam. Selecting any week explains it as light: where Earth sent it, its path at c, and where it reached the ship. The bridge gains a front wall of four ambient monitors: the signal from home (a True waterfall with the Receiver's line), Earth's clock against the ship's, the course, and the crew. The comms console moves beside the Voyage console, facing the bow |
| Milestones | CV0–CV6 (7 milestones), about 2,250 LOC, plus regenerated bridge GLBs and one new Blender prop |
| Duration | About 7.5 to 8.5 attended days at the recent R3 rate (about 300 counted LOC a day), plus the rig's `rig/full` runs (66–77 min each) and two reviews by Mark |
| Risk | Medium. The main risks are the protocol minor (2.18), whether the spectrum analyser works headless (a CV3 spike comes first), a single Blender generator run that both moves the console and adds the monitor prop, and four live viewports (gated by the bench) |
| Critical path | CV0 → CV1 → CV2 → CV5. CV3 and CV4 run alongside, and CV6 needs both CV3 and CV4 |

## Registry reuse (planner step 0, re-checked 2026-11-03)

| Milestone | Package | Action | Reason |
|---|---|---|---|
| CV1 | `sunholo/observe` 0.1.0 | depend | `seenAt` gives the newest light, and the record's `sent.t` is that value. The log itself is bookkeeping over `frameOf` and `inBeam` |
| CV1 | `sunholo/relativity` | none | No new formula; the rate is an existing sim field |
| CV3 | `sunholo/audio` 0.6.0 | none | The waterfall listens through Godot's `AudioEffectSpectrumAnalyzer` on silent taps |
| CV2, CV4, CV5, CV6 | — | none | These are Godot UI, layout data, Blender exports and tests |

## AILANG syntax gate

**Modules edited:**
- `sim/earth_link.ail`: `Arrival` gains `arrived`, `sent` and `shipAtSent`; `noteLight` replaces `noteBeam`.
- `sim/core.ail`: the call site, plus `journey.ship_years_left` if OQ12 is accepted.
- `sim/protocol_earth.ail` and `sim/protocol.ail`.
- `sim/earth_link_test.ail` and `sim/protocol_test.ail`.

None of these is a showcase or demo module.

| Module | Contracts | Effects | Inline tests |
|---|---|---|---|
| `sim/earth_link` | skip: the sim's pure modules use `_test.ail` checks and strict-VM entries, not contracts (as `earth_link.ail` already does) | **include:** pure, `! {}`; I/O stays in `sim/ship.ail` (gate 4) | skip: `earth_link_test.ail` and `earthLogVm` cover it |
| `sim/protocol_earth` | skip: it is a codec, tested by goldens | **include:** pure | skip: `protocol_test.ail` and a 2.18 replay case cover it |

## Milestones

### CV0. Rebase and baseline (about 0 LOC) ✅

- **When:** after #374, #375 and #377 merge.
- **Setup:** make a fresh clone, then fetch the runtime and assets and run the import.
- **Baseline captures:**
  - `make capture-comms-station`;
  - `make deck-layout-capture TAG=cv0`.
- **Checks:**
  - `make deck-layout-eval` prints `bridge ok`;
  - `make comms-station-test sound-voyage-test` passes.
- **Acceptance:** each check above is green, and its numbers are recorded in the sprint JSON.

### CV1. Received-frame log and protocol 2.18 (about 440 LOC) ✅

The sim logs every received frame, together with its send and arrival events.

**Files:**
- `sim/earth_link.ail`:
  - `Arrival {fromFrame, toFrame, beamed, day, arrived {t, tau, p, ly, rate}, sent {t}, shipAtSent}`;
  - `Link.log` and `Link.lastFrame`;
  - `noteLight(l, t, tau, p, rate, leg)`, which replaces `noteBeam` and keeps all of its duties.
- `sim/core.ail`: `linkAfter` passes tau and the tick's Earth rate.
- `sim/protocol_earth.ail`: `encodeEarthLog`, `encodeEarthLogTail`, `encodeEarthWeeks`, using the record from design §D1.2.
- `sim/protocol.ail`:
  - `earthLogMinor()` (2.18), plus `helloFor` and `sessionMinor`;
  - `earth_log` in full states, and `earth_log_tail` when it changes;
  - a read-only `earth_weeks` intent, clipped to arrived beamed weeks and at most 52 rows.
- The journey section: `journey.ship_years_left`, if OQ12 is accepted.
- `bridge/sim_bridge.gd`: `EARTH_LOG_MINOR := 17`, with storage keyed by `from_frame`.
- Makefile: `strict` and `parity` entries for `earthLogVm`.
- `mk/earth-link.mk`: `comms-log-test`.

**First step:** add the fields, then run `make replay`. Stop if any golden recorded before 2.18 moves.

**Tests (written first):**
- Week 0 is logged at departure.
- Weeks merge per ship day, and a beam change splits a record.
- Frames are contiguous.
- The log stays within its bound over 30 ship years.
- Nothing is logged beyond `frameOf(newest light)`.
- `sent.t = arrived.t − arrived.ly`, to within 1e-12.
- `shipAtSent` is the newest record with `arrived.t ≤ sent.t`, and `None` before the first record.
- `arrived.rate` equals `earth.rate` at that tick.
- Mutants:
  - merging across a beam change;
  - dropping a week;
  - stamping tau with the galaxy clock;
  - taking `shipAtSent` from after `sent.t`.

**Replay:** a new case, `earth_log_voyage` (seed 7: Sol → α Cen → off-ray → home), recorded for both arm64 and x86_64.

**Gates:**
- `ailang check --package sim`;
- `ailang test --package sim`;
- `make strict parity replay replay-compat comms-log-test`.

**Acceptance:** design AC1–AC4.

### CV2. Filmstrip, frame diagram and station layout (about 580 LOC) ✅

**Files:**
- `ui/earth_history.gd` + `.uid`. The filmstrip:
  - film, pictures, slits, stacks and static;
  - stamps and the Earth-time line;
  - hover, zoom and select;
  - opening a stack through `earth_weeks`.
- `ui/earth_strip.gd`:
  - a ray per beamed record;
  - **frame mode**, drawn entirely from the selected week's record:
    - the send event;
    - the light, at 45° on equal axes;
    - the arrival;
    - "ship then";
    - the ship's track;
    - ×D.
  - deselecting returns the strip to normal.
- `ui/frame_inset.gd` + `.uid`. The plan inset, in the galaxy map's glyphs:
  - Sol;
  - the track, from `arrived.p`;
  - the arrival and "ship then";
  - the light.
- `ui/comms_station.gd`: the detail-view layout.
- `ui/earth_feed.gd`: expose `picked_source`.
- `data/ui/comms_feed.json`: the labels (Earth, sent, arrived, ship then, light).
- Tests: `tests/test_comms_station.gd` and `tests/playthrough_comms.json`.

**Tests (written first):**
- Every received week is represented on the filmstrip.
- Static covers exactly the unbeamed spans.
- Nothing is drawn past `clock.tau`.
- The diagram's points equal the record's fields.
- The light segment has slope 1 in diagram units.
- The inset never draws Earth's current beam (`earth.beam`).
- No AI request is opened.
- `DisplayBinding.audit` finds no unbound digit.

**Gates:** `make comms-station-test display-audit-comms ui-theme-check uid-guard`.

**Acceptance:** design AC5 and AC6.

### CV3. The waterfall (about 300 LOC) ✅

**Spike first** (at most one hour, in scratch): does the analyser return magnitudes headless, on a bus at −80 dB? Test it along #375's mixer measurement path, and record the answer in the sprint JSON.

**Files:**
- `audio/sound_mix.gd` BUSES, two silent taps:
  - `Antenna`: the True beacon plus the week's True bed;
  - `Carrier`: the True beacon only.
- `audio/sound_director.gd`: plays the True rows on the taps while the ship is in beam and either the signal monitor or the station is on screen.
- `ui/comms_waterfall.gd` + `.uid`: the detail view (axes and setting), plus a `bold` face for the monitor.
- `data/ui/comms_feed.json`: `waterfall {carrier_hz: 400, bands: 96, seconds: 20}`.
- Tests: `tests/test_comms_waterfall.gd` + `.uid`, run by `make comms-waterfall-test`.

**Tests:**
- The measured peak is within 1 % of 400·D at D = 0.070888, 1 and 14.107.
- At D = 60 and 1414.2 the picture is dark and reads "above hearing".
- At D = 0.01 it reads "below hearing".
- The carrier line sits at 400 Hz in both settings.
- Source guard: no rate × frequency.
- The taps never exceed −60 dBFS at Master.

**Gates:** `make comms-waterfall-test sound-voyage-test sound-levels ui-theme-check uid-guard`.

**Acceptance:** design AC7.

### CV4. The consoles under the screens (about 220 LOC, plus GLBs) ✅

Mark's ruling (design §D2): each console stands under its screen at radius 18.6 m, turned so its operator faces the screen. The helm stays central. Every number below was measured in revision 3.

**Layout** (`art/deck-layout-v2/bow_a.json`, with the ruling in its `about`):

| Console | Bearing | Desk (ship m) | Yaw | Operator point (ship m) |
|---|---|---|---|---|
| Voyage, `console_decision_0` | −48° | (−13.822, 12.446) | −42° | (−12.912, 11.626) |
| Comms, `console_decision_2` | −30° | (−9.300, 16.108) | −60° | (−8.687, 15.047) |
| Crew, `console_decision_1` | +48° | (13.822, 12.446) | −138° | (12.912, 11.626) |

The port watch bench (`v2_bench_detail_*`) moves 2 m sternward along the rail, or is dropped.

**Steps:**
1. **Identity check first:** the identity layout must reproduce today's `ship.glb`, `bridge_props.glb` and `walk_bridge.glb` byte for byte.
2. **Walk:** run `tools/deck_walk_bake.gd`. The desks' collision comes from their walk holes, and the props keep their colliders.
3. **Blender, one run for CV4 and CV6:** `stapledon_deck_layout_v2.py`, then `stapledon_bridge_props_v4.py` on its master. The same run places the `bridge_monitor` prop instances. Export the three GLBs, take the sidecar's `INTERACT_<station>_use` points and monitor anchors, and put the masters in the public bucket by sha256.
4. **Manifest:** update `stations.{voyage, crew, comms}.use_m` and `screen_ship_m` (re-derive the D-132 points), then repin `budgets.json` and `asset-pins.json`.
5. **Camera:** nothing changes in `data/camera/views.json` or the level's views. The console zooms are derived from the moved meshes, and `camera-test` re-derives its walk counts (any count that moves is stated in the commit).
6. **Evaluator:**
   - `ZOOM_STATIONS` gains comms, and `active_stations` becomes 5;
   - a seeded "faces the rim" defect and a seeded desk on the operator path must both fail;
   - `make comms-walk-test` checks that chair → comms is at most 9.0 m, that every operator point is walkable and reachable, and that the rim walk from port to starboard is at most 42 m.

**Gates:**
- `make deck-layout-eval deck-layout-eval-test deck-assets-check levels-regress comms-walk-test camera-test export-filter-audit`;
- re-pin the bridge level baseline, with its reason in `design_docs/levels/bridge.md`, if `levels-regress` moves.

**Acceptance:** design AC9.

### CV6. The monitor wall (about 480 LOC, plus one Blender prop) ✅

**Blender:**
- The prop `bridge_monitor`: a grown frame and stand (D-104), with a 4.0 × 2.25 m face whose bottom edge sits 1.0 m above the deck.
- Four instances: `monitor_{clocks, signal, course, crew}`.
  - bearings −48, −30, +30 and +48°;
  - radius 21.1 m;
  - each facing ship (0, 6).
- They are built in CV4's generator run. The sidecar writes `monitors.<id>.screen_ship_m` and each normal.

**Game:**
- `interior/bridge_monitor.gd` + `.uid` (`BridgeMonitor`):
  - the screen mesh, with its face rendered in a `SubViewport`;
  - gated by a `VisibleOnScreenNotifier3D`;
  - refreshing at 30 Hz for the signal face and at most 10 Hz for the others.
- The faces, each `.gd` + `.uid`:
  - `ui/screens/signal_screen.gd`: the bold waterfall from CV3, the link bar, and the age of the light;
  - `ui/screens/clocks_screen.gd`: built on `EarthClocks`;
  - `ui/screens/course_screen.gd`: the chart, the phase, the target, the Earth year at arrival, γ, and `ship_years_left` if OQ12 is accepted;
  - `ui/screens/crew_screen.gd`: built on `CrewFaces`.
- `assets/levels/bridge/manifest.json`: a `monitors` section, and `monitor` added to `camera.occluders`.

**Evaluator** (`tools/deck_bow_metrics.gd`, `thresholds.json`):
- Each monitor must be readable from at least 25 % of Bow-view samples. "Readable" means:
  - in frame and facing the camera;
  - at least 40 px tall at 720p;
  - 2 of 3 rays clear after fades.
- The signal monitor must be readable from four places: the spawn, the captain's chair, the comms station and the Voyage console.
- `test_deck_layout_eval.gd` gains a seeded monitor placed on the walk, which must fail.

**Tests:** `tests/test_bridge_monitors.gd` + `.uid`, run by `make bridge-monitors-test`. It checks that:
- every number on every face is bound (`DisplayBinding.audit`);
- the faces refresh only while visible;
- each face follows a recorded world (homeward, outbound, off the beam).

**Gates:**
- `make bridge-monitors-test deck-layout-eval deck-layout-eval-test levels-regress ui-theme-check uid-guard`;
- `make bench SCENE=bridge`, on a quiet rig.

**Pause point:** run `make capture-comms-v2 STAGE=wall`. It captures the wall at rest and at 0.99c from the spawn, the captain's chair, the comms station, mid-deck and the crew console, plus the Astern view. Open every frame and upload them to `refs/comms_v2/cv6/`.

**Acceptance:** design AC8 and AC10.

### CV5. Archive, review, evaluation and landing (about 230 LOC) (built; evaluation round 2 and landing pending)

1. **Design repo first:**
   - rows in `relativity-spec.md` for 400 × RS-26, RS-28, RS-29 and RS-30;
   - `lore/archive/earths-carrier.md`;
   - one line in `earths-voice`.
2. **Game:**
   - `tests/test_physics.gd`;
   - the `data/lore` registry;
   - `tests/expected_unlocks.json`, if needed.
3. **Captures:** `tools/comms_v2_capture.gd` + `.uid`. Open every frame and upload them to `refs/comms_v2/build/`.
4. **Changelog:** a fragment in `changelogs/unreleased/`.
5. **Pause for Mark:** the captures plus a dev build, with no `v*` tag.
6. **Evaluation** by the other model family. It must score at least 70/100 and is written to `.ailang/state/evaluations/eval_R3-COMMS-V2_round_1.json`.
7. **Rig:** `tools/rig_check.sh <PR> --golden`, one check at a time.
8. **Landing:**
   - move the design doc to `implemented/`;
   - write the report;
   - update the README row and the design repo's roadmap row.

**Gates:**
- `tests/test_physics.gd`;
- `make lore-values codex-test python-guard uid-guard`;
- `rig/full` green.

**Acceptance:** design AC11–AC13.

## Pause points

1. **Before anything:** Mark approves the mock-ups and answers the open questions.
2. **After CV4 and CV6:** Mark reviews the moved console and the monitor wall, since both change how the bridge looks.
3. **After CV5:** Mark reviews the station's capture frames and plays a voyage on a dev build.

## Questions for Mark

All answered on 2026-11-03: every recommendation was approved, plus the ruling that the consoles go under the screens. Questions found during execution are added here and in the design doc.

## Validation (focused; never the full suite in the executor)

Each milestone runs only the gates listed above. `make test` runs only on the rig, through `tools/rig_check.sh`.
