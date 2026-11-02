# Sprint R3-COMMS-V2: plan

**Design:** [comms-station-v2.md](comms-station-v2.md) (the history filmstrip, the console moved closer, the signal's waterfall).
**Status:** **Awaiting Mark.** Proposed 2026-11-02. Nothing executes until two things are true:
- Mark approves the mock-ups (<https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/index.html>) and rules on OQ1–OQ7. The doc's recommendations are the defaults the plan is written against.
- PRs #374, #375 and #377 have landed.

**Progress file:** `.ailang/state/sprints/sprint_R3-COMMS-V2.json`
**Branches:**
- this plan: `design/comms-station-v2`;
- execution: `feat/comms-station-v2`, in a full clone at origin/main after the three PRs land (`../stapledons-godot-comms-v2`, re-cloned), never a worktree.
- No package branch: no `sunholo/*` change.

**AILANG:**
- The pin is whatever main carries at CV0 (v0.54.18 today; v0.56.0 if #377 lands first). Every gate runs with `AILANG=runtime/bin/ailang`.
- AILANG prompt version loaded: v0.16.7 (`runtime/bin/ailang prompt`, 2026-11-02, v0.54.18). If the pin moves, reload the prompt at CV0 and record the new version.

## Summary

| | |
|---|---|
| Goal | The comms station keeps every Earth week the ship has received, as a filmstrip along ship time with sim-field stamps and static where out of beam. The console moves to the port wing, facing the bow. A live True waterfall of the signal from home, with the Receiver's 400 Hz line, appears at the station and on the comms desk's screen |
| Milestones | CV0–CV5 (6), about 1,450 LOC plus regenerated bridge GLBs |
| Duration | About 5 attended days at the recent R3 rate (about 300 counted LOC a day: R3-EARTH-LINK 1,350 LOC in about 4.5 days; R3-SUNHOLO-AUDIO-REALISM). Add the rig's `rig/full` (66–77 min a run) and Mark's render review |
| Risk | Medium. The protocol minor (2.17); the spectrum analyser headless (CV3 spike first); regenerating the bridge GLBs through two Blender generators |
| Critical path | CV0 → CV1 → CV2 → CV5; CV3 and CV4 run alongside CV1–CV2 |

## Registry reuse (planner step 0, 2026-11-02)

`ailang pkg search` was run for "spectrogram", "spectrum", "waterfall", "light cone" and "history log". Only `sunholo/relativity` matched ("spectrum" in its blackbody text).

| Milestone | Package | Action | Reason |
|---|---|---|---|
| CV1 | `sunholo/observe` 0.1.0 | depend | `lightcone.seenAt` already gives the newest light. The log is bookkeeping over the sim's `frameOf` and `inBeam`, with no new geometry |
| CV1 | `sunholo/relativity` | none | No new formula; the Earth rate is already a sim field |
| CV3 | `sunholo/audio` 0.6.0 | none | The waterfall listens through Godot's `AudioEffectSpectrumAnalyzer` on a silent tap. Nothing is synthesised, and no offline analysis ships |
| CV2, CV4, CV5 | — | none | Godot UI, layout data, Blender exports, tests |

## AILANG syntax gate

Edited `.ail` modules: `sim/earth_link.ail`, `sim/core.ail` (the call site), `sim/protocol_earth.ail`, `sim/protocol.ail`, `sim/earth_link_test.ail`, `sim/protocol_test.ail`. None is a showcase or demo module.

| Module | Contracts | Effects | Inline tests |
|---|---|---|---|
| `sim/earth_link` (`noteLight`, `Arrival`) | skip: the sim's pure modules use `_test.ail` checks and strict-VM entries, not contracts (the `earth_link.ail` precedent) | **include:** pure, `! {}`; I/O stays in `sim/ship.ail` (gate 4) | skip: `earth_link_test.ail` checks, plus a strict-VM entry `earthLogVm` |
| `sim/protocol_earth` (`encodeEarthLog`) | skip: codec, tested by goldens | **include:** pure | skip: `protocol_test.ail` checks and a 2.17 replay case |

## Milestones

### CV0. Rebase and baseline, about 0 LOC

- **Wait** for #374, #375 and #377 to merge. Re-clone at origin/main, `cp -cR` the runtime, fetch assets, and import.
- **Baseline captures** (opened, kept in `renders/`): `make capture-comms-station`, `make deck-layout-capture TAG=cv0`.
- **Checks:**
  - `make deck-layout-eval` prints `bridge ok` with comms at (−13.2, −3.0) and `faces_bow false`;
  - `make comms-station-test sound-voyage-test` are green.
- **Acceptance:** each baseline above is green, and its numbers are recorded in the sprint JSON notes.

### CV1. The received-light log in the sim, protocol 2.17, about 380 LOC (about 170 code, 210 tests)

- **Files:**
  - `sim/earth_link.ail`: `Arrival`, `Link.log` and `Link.lastFrame`, and `noteLight(l, t, tau, p, leg)`, which replaces `noteBeam` and keeps its `lastBeamT` and `lastInBeamAt` duties;
  - `sim/core.ail` `linkAfter`: pass `after.ship.motion.tau`;
  - `sim/protocol_earth.ail`: `encodeEarthLog`, `encodeEarthLogTail`, `encodeEarthWeeks`;
  - `sim/protocol.ail`: `earthLogMinor() = surfaceMinor() + 4` (2.17), `helloFor`, `sessionMinor`, the gated `earth_log` section in full states, `earth_log_tail` on ticks where the newest record changed, and the `earth_weeks` intent (read-only, clipped to arrived beamed weeks, ≤ 52 rows);
  - `bridge/sim_bridge.gd`: `EARTH_LOG_MINOR := 17` and storage by `from_frame`;
  - Makefile `strict` and `parity` entries `earthLogVm`;
  - `mk/earth-link.mk` `comms-log-test`.
- **First step:** add the `Link` fields and run `make replay`. **Stop if any pre-2.17 golden moves** (2.16 sessions must not see the log).
- **Tests, test-first** (`earth_link_test.ail`):
  - week 0 at departure;
  - the merge per ship day;
  - a split when `beamed` changes inside a day;
  - `fromFrame = previous toFrame + 1` over a recorded voyage;
  - the bound on a 30-ship-year synthetic voyage (records ≤ ship days + beam changes);
  - no record beyond `frameOf(newest light)`;
  - mutants: merging across a beam change, dropping a week, stamping tau with the galaxy clock.
- **Protocol tests** (`protocol_test.ail`): `earth_log` absent below 17 and inside a black hole's scenario; the tail sent only on change; `earth_weeks` beyond `lastFrame` empty.
- **Replay:** a new case `earth_log_voyage` (Sol → α Cen → off-ray → home, seed 7, the comms capture's voyage), recorded for arm64 and x86_64 by the existing `replay-record` route, reviewed diff only.
- **Gates:** `ailang check --package sim`, `ailang test --package sim`, `make strict parity replay replay-compat comms-log-test`.
- **Acceptance:** design AC1–AC4.

### CV2. The filmstrip, the rays and the station layout, about 430 LOC (about 300 code, 130 tests)

- **Files:**
  - `ui/earth_history.gd` + `.uid` (new `EarthHistory`): film, pictures, slits and stacks, static spans, stamps as `ComposedBinding`s on `earth_log.records.<i>.{earth_from_year, ship_year}` (`comms_clock`), the Earth-time line, hover-to-feed, zoom, tap-a-stack (`earth_weeks`);
  - `ui/earth_strip.gd`: rays per beamed record;
  - `ui/comms_station.gd`: the v2 layout (feed; clocks, waterfall slot and a faces row; filmstrip; strip; Details unchanged);
  - `ui/earth_feed.gd`: expose `picked_source` for the wall, with no behaviour change (after #374);
  - `data/ui/comms_feed.json`: the wall's words (none drawn, the hover caption only);
  - `tests/test_comms_station.gd` (new checks);
  - `tests/playthrough_comms.json` extended through the off-ray leg and home.
- **Tests, test-first:**
  - every received week is represented (pictures + slits + stacks cover `0..to_frame` of each beamed record);
  - static covers exactly the unbeamed spans;
  - x is monotone in `ship_year`;
  - nothing drawn past `clock.tau`;
  - the wall never opens an AI request (`AiRelay.open` count unchanged across a wall refresh);
  - `DisplayBinding.audit` finds no unbound digit.
- **Gates:** `make comms-station-test display-audit-comms ui-theme-check uid-guard`.
- **Acceptance:** design AC5.

### CV3. The waterfall, about 300 LOC (about 190 code, 110 tests)

- **Spike first (≤ 1 hour, scratch, not committed):** does `AudioEffectSpectrumAnalyzer` on a bus at −80 dB return magnitudes under `--headless` (Dummy driver)? Repeat PR #375's mixer measurement path. Record the answer in the sprint JSON. If the answer is no, the peak test runs where #375's beacon measurement runs, and the headless test checks routing and plan only (design §Risks).
- **Files:**
  - `audio/sound_mix.gd` BUSES: `Antenna` (the True rendition: bed and beacon) and `Carrier` (the True beacon only), each with a spectrum analyser, fader −80 dB, sent to no audible bus;
  - `audio/sound_director.gd`: plays the True rows on the taps while the station or the comms desk screen is visible and in beam, using `EarthFeed.receiver_plan(D, false)`;
  - `ui/comms_waterfall.gd` + `.uid` (new `CommsWaterfall`): 96 log bands, 20 Hz to 20 kHz, magma ramp from the theme, the Receiver line at `waterfall.carrier_hz`, the bracket to the measured carrier peak with `×` `earth.rate` (`sci`), the off-scale arrow from the plan's `hearing`;
  - `data/ui/comms_feed.json`: `waterfall: {carrier_hz: 400, bands: 96, seconds: 20}`;
  - `demos/ship_consoles.gd`: the comms idle screen hosts the waterfall in beam and the static's waterfall out of beam (OQ6);
  - `tests/test_comms_waterfall.gd` + `.uid`;
  - `mk/earth-link.mk` `comms-waterfall-test`.
- **Tests, test-first:**
  - the measured peak at D 0.070888, 1 and 14.107 is within 1 % of 400·D (the test computes 400·D as its oracle);
  - at D 60 and 1414.2 there is no magnitude above the floor and the arrow reads "above hearing"; at D 0.01, "below hearing";
  - the Receiver line sits at 400 Hz in both settings, solid or dashed;
  - source guard: no rate × frequency in `ui/comms_waterfall.gd`;
  - the taps never reach Master above −60 dBFS.
- **Gates:** `make comms-waterfall-test sound-voyage-test sound-levels ui-theme-check uid-guard`.
- **Acceptance:** design AC6.

### CV4. The console moved, about 120 LOC plus GLBs

- **Default spot A** (OQ1): `console_decision_2` at ship (−11.0, 8.0), yaw −90, use (−11.0, 6.775). Spot B (−5.6, 7.0) swaps in the same numbers if Mark picks it.
- **Steps** (design §D2):
  1. Amend `art/deck-layout-v2/bow_a.json`, with the ruling in its `about`.
  2. `tools/deck_walk_bake.gd`.
  3. `~/dev/blender/blender.sh -b --python scripts/stapledon_deck_layout_v2.py`, then `stapledon_bridge_props_v4.py` on its master.
  4. Export `ship.glb`, `bridge_props.glb`, `walk_bridge.glb`.
  5. Manifest `stations.comms.use_m` and `screen_ship_m`.
  6. Repin `budgets.json` and `asset-pins.json`. Masters go to the public bucket by sha256 (standing approval).
- **Before the move:** the identity layout must reproduce today's three GLBs byte for byte (generator determinism).
- **Evaluator:**
  - `tools/deck_bow_metrics.gd` `ZOOM_STATIONS` gains `comms`;
  - `thresholds.json` `active_stations` goes 4 → 5;
  - `tests/test_deck_layout_eval.gd` gains a seeded "comms faces the rim" defect that must fail.
- **New** `make comms-walk-test`: chair → comms walked ≤ 10.5 m (A) or ≤ 6.5 m (B).
- **Gates:**
  - `make deck-layout-eval deck-layout-eval-test deck-assets-check levels-regress comms-walk-test`;
  - the camera tests (`make camera-test` and its siblings);
  - `make export-filter-audit`.
- **Pause point:** `make deck-layout-capture TAG=cv4` (plan, Bow, Astern, the comms zoom at 0.99c), opened, uploaded to `refs/comms_v2/cv4/`.
- **Acceptance:** design AC7, AC8.

### CV5. The Archive, review, evaluation and landing, about 220 LOC

- **Design repo first** (fresh clone `stapledons-design-comms-carrier`):
  - `physics/relativity-spec.md` §2 rows for 400 × RS-26, RS-28, RS-29, RS-30 (28.355, 0.28284, 5,642.8, 565,680 Hz);
  - `lore/archive/earths-carrier.md`, unlocked on the first waterfall at D ≠ 1.
- **Then in the game:**
  - `tests/test_physics.gd` asserts the rows;
  - `data/lore` registry;
  - `tests/expected_unlocks.json` if the minimum path reaches it.
- **Captures:** `tools/comms_v2_capture.gd` + `.uid` and `make capture-comms-v2` (GPU window), from the real sim:
  - outbound, at port, off beam, homeward in True and Receiver, home;
  - the console Bow, Astern and zoom at the spot.
  - Every frame is opened, uploaded to `refs/comms_v2/build/`, and listed in the report.
- **Changelog** fragment `changelogs/unreleased/2026-11-xx-comms-station-v2.md`.
- **Pause for Mark** with the captures and a dev build (no `v*` tag).
- **Evaluation** by the other model family (`sprint-evaluator`, ≥ 70/100) into `.ailang/state/evaluations/eval_R3-COMMS-V2_round_1.json`.
- **Rig:** `tools/rig_check.sh <PR> --golden`, one rig check at a time (`pgrep -fl rig_check`).
- **Landing:** move the doc to `design_docs/implemented/r3/`, write the report, update the README row, and update the design repo roadmap row.
- **Gates:** `godot --headless --path . --script tests/test_physics.gd`, `make lore-values codex-test python-guard uid-guard`, `rig/full` green.
- **Acceptance:** design AC9–AC11.

## Pause points

1. **Before anything:** Mark approves the mock-ups and OQ1–OQ7 (this plan's status).
2. **After CV4:** the moved console's captures (a visual change to the bridge).
3. **After CV5:** the station's review captures and a dev build. Mark plays a voyage.

## Questions for Mark

The design doc's OQ1–OQ7, each with its recommendation: spot A; ship-time axis; static shown; the whole signal in the picture; True only beyond hearing; the comms desk's screen as the bridge readout (no Voyage strip); one record per ship day.

## Validation (focused, never the full suite in the executor)

Per milestone, the gates listed above. `make test` runs only on the rig through `tools/rig_check.sh`, never locally in the executor.
