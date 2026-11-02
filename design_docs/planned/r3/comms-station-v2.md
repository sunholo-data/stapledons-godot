# R3-COMMS-V2: the comms station v2 (feed history, the console moved closer, the signal's waterfall)

**Status:** Proposed 2026-11-02, **awaiting Mark** (the mock-ups first, then OQ1–OQ7). Design and mock-ups only; nothing is built. Execution waits for Mark's approval and for open PRs #374 (R3-TRUE-PROCESSED: `ui/earth_feed.gd`, `data/ui/comms_feed.json`), #375 (R2-SOUND S2: `audio/*`, `data/audio/*`, the exact home beacon) and #377 (AILANG v0.56.0) to land, because each sub-milestone below edits files those PRs hold.
**Release:** R3 (Signals and Contact), a follow-up to R3-EARTH-LINK's comms station (S1, K1, F6; [earth-link.md](../../implemented/r3/earth-link.md) EL3b).
**Priority:** P2. It deepens the crew's window home and puts the station where the captain works.
**Origin:** Mark, attended 2026-11-02: three asks. (1) The station shows only Earth's newest picture: show every frame the ship has received, as a filmstrip or wall. (2) Move the comms console closer: it is the furthest station from the chair. (3) "the spectrograph is cool on its own - maybe we can have that read out on the bridge somewhere" (on the sound agent's spectrogram MP4 of the home beacon, `refs/sound_s2/voyage_montage.mp4`, PR #375).

**Mock-ups (the main deliverable; Mark approves these before anything is built):** <https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/index.html> (33 images, listed in §Deliverables). They are throwaway renders from the real game and the real sim (protocol 2.16, seed 7). Their scripts lived in the scratch directory and are not committed.

**Implements** (design repo):
- [signals-and-instruments.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/signals-and-instruments.md) §2 (the light cone) and §3 (Earth's signal, the Earth rate): what has arrived, and at what rate.
- [contact-console.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/contact-console.md) §1, the Listen pane: what is arriving, "with Doppler, light age and SNR". The waterfall is the visual form of that Doppler.
- `vision/design-decisions.md`, three standing orders:
  - 2026-10-28, "Visual First, Words Last": a filmstrip and a waterfall, not sentences;
  - 2026-10-28, "the Archive Teaches the Real Physics" (§D5);
  - 2026-10-30, "No Compromises on the Physics; True and Processed Settings": the waterfall is always True, and the Receiver is the labelled instrument.
- **Physics spec** `physics/relativity-spec.md` §2, row "Light cone and Earth's link", **RS-26 to RS-30** (the Earth rates 0.070888, 0.022366, 7.0711 × 10⁻⁴, 14.107, 1414.2). No new formula; four new derived check values for the Archive entry (§D5) go into the spec first.
- Ledger:
  - D-21 (every number on screen is a sim field);
  - D-68 (never show what the ship cannot know: nothing from the future);
  - D-95 to D-97 and D-132 (the bow layout and the operator points);
  - D-144 (this run).

**Depends on:**
- PR #374, which leaves the feed with no tint (the decoded picture at every D) and changes `ui/earth_feed.gd`. The wall's thumbnails use its `picked_source` rule.
- PR #375, which adds the exact home beacon (True: `home_beacon` resampled at D; Receiver: `home_beacon_rx` generated at 400 Hz) and the code-built bus layout (`audio/sound_mix.gd` BUSES, with the Receiver bus's pitch correction). The waterfall listens to these.
- PR #377 (AILANG v0.56.0). The sim work (CV1) runs on whatever AILANG version main pins when it starts.
- `sunholo/observe` 0.1.0 `lightcone` (seenAt) and the existing `sim/earth_feed.ail` (`frameOf`, `feedAt`). No package change.
- The bow layout tooling of R2-DECK-LAYOUT: `tools/deck_layout.gd`, `tools/deck_walk_bake.gd`, `tools/deck_bow_metrics.gd`, `make deck-layout-eval`, the Blender generators in `~/dev/blender/scripts` (`stapledon_deck_layout_v2.py`, then `stapledon_bridge_props_v4.py` on its master).

**Estimated LOC:** about 1,450. Sim and protocol 380, bridge and the history wall 430, waterfall 300, console move 120 (plus regenerated GLBs), tests and captures 220.

## Game vision alignment

Scored with the `game-vision-designer` skill (feature-validation mode, against `vision/core-pillars.md` and the standing orders of 2026-10-28 and 2026-10-30), 2026-11-02. **ALIGNED.**

| Pillar | Score | Rationale |
|---|---|---|
| Choices Are Final | +1 | The wall is a permanent record of what each plan cost at home. A turn off Earth's beam leaves a band of static on it for the rest of the voyage, and nothing can fill it later. It shows only light that has arrived, so it never previews an outcome |
| The Game Doesn't Judge | 0 | Neutral. The wall shows the weeks that came and the static where none did, with no label |
| Time Has Emotional Weight | +2 | The core of it. Flying out at 0.99c the weeks of home arrive about 99 ship days apart: a few pictures far apart on an empty film. Flying home they pour in, two a ship day. The crew can scroll back through everything home has been since they left |
| The Ship Is Home | +1 | The station moves from the stern-port quadrant to the port wing beside the Voyage console. It is a 10 m walk from the chair (17 m today), its operator faces the bow, and the starbow is in its zoom. Its own desk screen shows the live waterfall, so the bridge can see home's signal from across the deck |
| Grounded Strangeness | +2 | The waterfall is the exact Doppler shift of Earth's carrier, measured from the real audio and never computed in Godot. It sits at 28 Hz outbound and 5.6 kHz homebound, against the Receiver's 400 Hz line. The wall is the light cone itself: its spacing is the integral of the Earth rate |
| We Are Not Built For This | +1 | Near the top speed toward home, the True carrier climbs out of human hearing and the waterfall shows it leave. Home's history arrives faster than anyone could look at it |
| **Net** | **+7** | **Go.** No pillar is negative. Risk to pillar 3: if the wall is presented as a log to scrub it becomes a resource screen. Mitigation: it is a film, with no counts and no totals, and its numbers are only the two stamps per picture (§D1) |

## Problem

- **The station forgets.** `ui/earth_feed.gd` shows one picture, the week of the newest light (`earth.feed`), and keeps two ghost textures for the fast bands (`history.resize(mini(history.size(), ghosts.size()))`, two ghosts). Everything else the ship has received is gone. In the recorded voyage (seed 7: Sol to Alpha Cen A, an off-ray leg, home) the ship receives **1,204 Earth weeks in 3.6 ship years**, and the station can show three of them.
- **The sim knows only "now".** `sim/protocol_earth.ail` sends `feed` (the newest week) and `last_feed` (the week of the last beamed light). Nothing records when each week arrived aboard or whether it came in beam, so the client could not draw a history without inventing one.
- **The station is the far corner of the bridge.** `console_decision_2` stands at ship metres (−13.2, −3.0) (glTF (−13.2, 3.0)), stern-port of the mast. Measured on the shipped bridge with the game's own router (`WalkArea.path`) and the bow evaluator (`DeckBowMetrics`):
  - **17.1 m** walk from the captain's chair (8 s at 2.2 m/s) and 20.9 m from the spawn, against 5.8 m to the Voyage console;
  - its operator stands on the starboard side **facing the rim**, the only active station that does not face the bow (`faces_bow false`);
  - its zoom does not frame the forward sky. The evaluator passes today only because it counts four stations (`active_stations: 4`; comms was added after R2-DECK-LAYOUT).
- **The beautiful spectrogram exists only offline.** The sound agent's review MP4 shows the beacon's carrier sliding with D and the Receiver holding it at 400 Hz. In the game the shift is only heard. In True at D > 50 it is silent, and nothing on screen says where the signal went.

## Goals and non-goals

**Goals**
- G1. **Every received week, oldest to newest,** on a filmstrip at the comms station. Each picture is stamped with its Earth date and the ship date it arrived (sim fields). There is static where light came without Earth's beam, and the spacing follows ship time, so the Earth-rate history shows.
- G2. **Nothing from the future.** Every frame on the wall is light that has reached the ship. The sim enforces this, not the client.
- G3. **The comms console moved** to a spot that faces the bow, frames the forward sky in its zoom, keeps every bow-evaluator threshold, and halves the walk from the chair (spot A, or B; OQ1).
- G4. **A live waterfall of the signal from home.** It is always True, as measured from the receiver's audio, with the Receiver's carrier line over it. The gap between them is the Doppler shift, and the True line visibly leaves the audible band. It appears at the station, and (OQ6) on the comms desk's own screen as the bridge readout.
- G5. **Determinism and purity hold.** The new log is pure, `sim/core.ail` passes `make strict`, the VM and the interpreter are bit-identical, and replays are byte-identical.

**Non-goals**
- New physics or a package change: the log is bookkeeping over `frameOf` and `inBeam`, both existing.
- A wideband (radio) instrument view of the carrier beyond hearing. This is OQ5, deferred; a Processed view needs its own design.
- Painting more AI frames for the wall. The wall shows what the station already has (library pictures and frames painted earlier) and never asks the AI for thumbnails.
- Moving any station other than comms, or reshaping its desk.
- Sound changes: the waterfall listens and never plays. Where it needs an analysis tap, it adds a silent bus (§D3).

## Design

### D0. The station at a glance (mock-ups)

![station homeward True](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/station_homeward_true.png)

The layout keeps today's pieces and adds two:
- **The feed** stays the largest thing, top left.
- **The right column**, top to bottom: the twin clocks (smaller dials), the **waterfall** (new), and the crew's faces in one row (smaller, no names until hover).
- **The history filmstrip** (new) runs full width under them.
- **The light strip** (EarthStrip) stays at the bottom, with each arrival drawn as a faint ray of Earth's light (§D1.4).
- Details and the words layer stay behind the Details button, unchanged.

What the player sees at a glance (visual first):
- Outbound: one picture, then a long empty film.
- At a port: pictures one after another.
- Off the beam: grey static growing.
- Homeward: a dense slit-scan flood.
- On the waterfall, the carrier's line sits far below or above the thin teal line where the receiver puts it.

Words are the two tiny coloured stamps per picture, plus the existing tags.

### D1. Feed history: the received-light log and the filmstrip

**D1.1 The sim keeps a log (pure, `sim/earth_link.ail`).** One record per ship day in which new weeks of Earth's light arrived:

```
Arrival = { fromFrame: int, toFrame: int, beamed: bool, tau: float, t: float, ly: float, day: int }
Link    = { ..., log: [Arrival] (newest first), lastFrame: int }   -- emptyLink: log [], lastFrame -1
```

`noteBeam` becomes `noteLight(l, t, tau, p, leg)` and is called each tick from `core.ail linkAfter` as today, with `after.ship.motion.tau` added:

1. `f = frameOf(seenAt(t, p, Sol))`, the week of the newest light, exactly as `earth.feed.frame` (`sim/earth_feed.ail`).
2. If `f > lastFrame`, the weeks `lastFrame+1 .. f` arrived in this tick. `beamed = inBeam(l, t, p, leg)`, the same rule as `earth.in_beam` at the tick's end; `day = floor(tau × 365.25)`.
3. If the newest record has the same `beamed` and the same `day`, extend its `toFrame`. Otherwise cons a new record. Then `lastFrame = f`.

**Why per ship day:** the bound and the stamp's precision.
- The log grows by at most one record per ship day, plus one per change of beam: about 11,000 records for a 30-ship-year voyage, however fast the Earth rate.
- A ship day is the precision the ship stamp shows.
- At 0.99c outbound each week is its own record, because the weeks come ~99 ship days apart (RS-26: 7 / 0.070888 = 98.7 days). Homebound at RS-29 a ship day carries two weeks (14.107 / 7). At the top speed toward home (RS-30) it carries 202.

**Determinism:** the log is a pure fold over the tick sequence. Same seed and inputs give a byte-identical log, on the VM and the interpreter.

**D1.2 Protocol 2.17 (`earthLogMinor`).** A new `earth_log` section, sent only at minor ≥ 17 and outside a black hole's scenario, as `earth` is:
- **full states:** `earth_log: {weeks_bin_years, records: [...]}`, oldest first;
- **ticks:** `earth_log_tail: [record]`, sent only when the newest record changed (one tick changes at most the newest record, or adds one).
- The bridge (`bridge/sim_bridge.gd`) replaces by `from_frame`. That is storage, not arithmetic.

A record:
```
{from_frame, to_frame, beamed, tau, ship_year, t, ly,
 earth_from_year, earth_to_year,        -- params.epoch + frame × feedBinYears (week start / end of to_frame)
 feed: {frame, kind, event: {id, category, words}, pick}}   -- feedAt(seed, to_frame × bin): the newest week's picture
```

Every number the wall shows is one of these fields (D-21): `earth_from_year`, `earth_to_year` and `ship_year`, through the existing `comms_clock` format ("+4.31 yr"). Godot formats and never adds.

**D1.3 The weeks inside a record (`earth_weeks`).** Tapping a stack asks for its weeks with a new intent, `{"k": "earth_weeks", "from": a, "to": b}`. It is read-only, like `echo`. The next state carries `earth_weeks: [{frame, earth_year, kind, event, pick}]`, at most 52 rows. The sim clips the request to beamed records and to `frame ≤ lastFrame`, so a client can never ask for a week that has not arrived (G2, D-68).

**D1.4 The filmstrip (`ui/earth_history.gd`, a new `EarthHistory` control in `CommsStation`).** Mock-ups: [whole voyage and zooms](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/history_wall_detail.png), and on every station frame.
- **x is ship time:** the left edge is departure (τ = 0) and the right edge is now (`clock.tau`, a teal marker). The gaps are the Earth-rate history. The first visible frames are week 0 at departure, week 1 at ship +0.27 yr, and week 2 at +0.54 yr.
- **Pictures:** each beamed record shows the newest week's picture (`EarthFeed.picked_source`: shipped library, painted frames from the AI cache, the sky). Where there is room, a full thumbnail, with faint offset frames behind it when the record holds more than one week (a stack). Where records crowd, a slit of each picture, so the homeward flood reads as a dense collage. Every week is on the film, either as a picture, a slit or a stack.
- **Static** fills the ship-time span of unbeamed records: the light came, and Earth's beam was not in it.
- **Stamps** under each full thumbnail:
  - the Earth date (ochre, the Earth clock's colour), `earth_from_year`;
  - the ship date (teal, the ship clock's colour), `ship_year`.
  - The ends of a flood get a pair too. There are no counts and no totals.
- **A thin cream line** across the film plots Earth time received against ship time. Its slope is the Earth rate: flat outbound, steep homebound.
- **Interaction:**
  - Hovering or tapping a picture shows it large in the feed frame, with its caption and stamps, until released.
  - The wheel or a pad zooms the ship-time axis about the pointer.
  - Tapping a stack opens its weeks (`earth_weeks`).
  - The newest picture is always the live feed.
- **Rays on the light strip:** `EarthStrip` draws each beamed record as a ray from Earth's line at the week's emission (`earth_to_year − epoch`) to the ship's line at `(t, ly)`.
  - Lone rays are visible; the homeward flood is a faint fan.
  - Outbound the rays run almost along the ship's own line: the light barely catches the ship.

**D1.5 Thumbnails and the AI.** The wall loads each library picture once (96 pictures, 48 events) and reuses its texture. It shows a painted frame only if the AI cache already holds it, and never opens an AI request. The station's existing `LIVE_PER_VISIT` budget (three per visit) is unchanged.

### D2. The comms console, moved closer

**How the bridge is authored:**
- **The layout** lives in `art/deck-layout-v2/bow_a.json` (schema `stapledons.deck.layout/1`, ship metres, Blender +Z up, glTF (x, z, −y)). Each prop group's pivot and yaw, and the stations' `use_m`, are recorded there.
- **The walk** is baked by `tools/deck_walk_bake.gd` (`DeckLayout.apply` on the pinned grounded v2 walk).
- **The Blender masters:** `stapledon_deck_layout_v2.py` rebuilds the master, and the props generator (`stapledon_bridge_props_v4.py`, R2-BRIDGE-STYLE ST3/ST5) dresses it. Both are pinned in `art/deck-layout-v2/asset-pins.json`.
- **Runtime points:** the manifest (`assets/ship_demo/manifest.json`) carries `stations.<id>.use_m` and `screen_ship_m`, which `ShipConsoles` reads.
- **Measurement:** the bow evaluator (`make deck-layout-eval`, thresholds `art/deck-layout-v2/thresholds.json`) measures every walk sample through the fixed Bow and Astern views (`data/camera/views.json` and the level manifest), plus the spawn, the stations and the console zooms. `make levels-regress` holds the bridge baseline.

**Candidates.** Eight spots were scored in-engine on the shipped deck: the base was the shipped layout, the comms desk the only thing moved, and every other station kept bow_a's authored use point. Each spot has the yaw of the Voyage console (−90°), so its operator stands 1.225 m stern of the desk facing the bow. The numbers below are from those runs ([plan](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/console_plan_compare.png), [probe.json](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/console_probe.json)).

| Spot | Ship m (glTF x, z) | Chair → comms walked | Spawn → comms | Comms → Voyage | Faces bow | Zoom frames the pole | Evaluator |
|---|---|---|---|---|---|---|---|
| Today | (−13.2, −3.0) (−13.2, 3.0) | 17.1 m | 20.9 m | 15.4 m | no (faces the rim) | no | ok (counts 4 stations) |
| **A (recommended)** | (−11.0, 8.0) (−11.0, −8.0) | **9.9 m** | 14.8 m | 5.7 m | yes | yes | ok |
| **B (alternative)** | (−5.6, 7.0) (−5.6, −7.0) | **5.8 m** | 9.7 m | 6.5 m | yes | yes | ok |
| rim, further bow | (−12.6, 11.0) | 10.3 m | 15.1 m | 5.2 m | yes | yes | ok, crowds the Voyage desk |
| helm's port wing | (−10.2, 14.6) | 9.1 m | 11.6 m | 3.8 m | yes | yes | ok, 3.8 m from the Voyage operator |
| rim, mid | (−13.4, 6.0) | 13.2 m | 18.0 m | 8.7 m | yes | yes | ok, barely closer |
| starboard, by the lift | (12.0, 9.5) | 16.5 m | 14.3 m | 22.3 m | yes | yes | ok, no gain, crowds the lift |
| starboard inboard | (4.5, 9.0) | 8.0 m | 7.3 m | 13.9 m | yes | yes | ok, but the spawn's near field rises 0.015 → 0.026 |

Every candidate keeps the bridge's metrics exactly: Bow fades 479, stop body blocked on both sides at 8 samples, Astern head blocked at 1, spawn open 3.50 m, near field Bow 0.015 and Astern 0.074. A desk 1 m tall under a 5.5 m eye blocks nothing.

**Spot A (recommended).** The same ring as today (radius 13.6 m, today 13.5 m), slid 11 m toward the bow, to the port wing beside the Voyage console.
- The desk sits on the inner edge of the rim walkway, so the open floor stays open.
- Comms and Voyage become a pair, the ship's "outside" stations: plans out, home in.
- In the zoom the starbow sits over the rail beyond the desk ([zoom](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/console_spot_a_console_comms.png)); today the zoom looks at the rail and the dark ([today](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/console_today_console_comms.png)).
- The Bow view at the desk frames the helm and the starbow ([0.99c](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/console_spot_a_bow_cruise_comms.png)).

**Spot B (alternative).** Inboard, at the chair's port shoulder, on the open floor between the chair and the mast.
- Half A's walk: 5.8 m, the same as the Voyage console.
- From its zoom the helm, the chair and the Voyage console are all in frame under the starbow ([zoom](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/console_spot_b_console_comms.png)): the station looks over the captain's shoulder.
- Costs: a free-standing desk on the open floor, over the floor conduits. In the Bow view at the desk the mast fills the right of the frame unfaded ([bow](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/console_spot_b_bow_rest_comms.png)). The open stage in front of the chair (D0 of deck-layout.md) gets busier.

**Neither spot is in the spawn's Bow frame,** and neither changes it ([today](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/console_today_bow_rest_spawn.png), [A](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/console_spot_a_bow_rest_spawn.png), [B](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/console_spot_b_bow_rest_spawn.png)). The station is found by the HUD's walk-to, as today.

**Build (CV4):**
1. Add `console_decision_2: {position_m: [−11.0, 8.0], yaw_deg: −90, use_m: [−11.0, 6.775]}` to `bow_a.json`. Its `about` gains the ruling.
2. Bake the walk.
3. Rebuild the master with `stapledon_deck_layout_v2.py`, then re-dress it with `stapledon_bridge_props_v4.py`, and export `ship.glb`, `bridge_props.glb` and `walk_bridge.glb`.
4. Set `stations.comms.use_m` and `screen_ship_m` in the manifest, from the generator's sidecar.
5. Repin `budgets.json` and `asset-pins.json`.
6. Evaluator updates:
   - `ZOOM_STATIONS` gains `comms`;
   - `thresholds.json` `active_stations` goes 4 → 5, so comms must face the bow and be clear like the others;
   - `make deck-layout-eval-test` gains a seeded "comms faces the rim" defect that must fail.
7. Re-pin the bridge level baseline only if `make levels-regress` moves, with the sha in `design_docs/levels/bridge.md`'s change log.
8. Camera tests derive their walk counts at test time (deck-layout §D2), so a count that moves is re-derived and stated in the commit, never re-recorded to pass.

### D3. The waterfall: the signal from home, True, with the Receiver's line

Mock-ups:
- [the five rates, True and Receiver](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/waterfall_rates.png);
- the station frames;
- [the desk screen](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/console_spot_a_idle_waterfall.png).

**What it shows.** A scrolling waterfall, ~20 s wide: time runs right to left (newest at the right edge), and frequency runs up on a log axis over human hearing, 20 Hz to 20 kHz.
- Gridlines at 100 Hz, 1 kHz and 10 kHz, labelled as axis constants.
- Colour: the magma ramp of the sound agent's MP4 (deep violet to red to cream), on the theme's ink.

**What it listens to (True, always).** The picture is the True signal from home whatever the station's setting: what arrives, shifted by D.
- **The tap:** an `Antenna` bus, added to `audio/sound_mix.gd` BUSES after #375 lands, with an `AudioEffectSpectrumAnalyzer`, its fader at −80 dB and sent nowhere audible.
- While the station is open and in beam, it carries the True rendition of what the receiver gets: the week's bed at speed and pitch × D, and the beacon's True row (`home_beacon` at pitch × D). That is the same plan `EarthFeed.receiver_plan(D, false)` already gives True, so no new rate code.
- **Drawing:** each frame the `Waterfall` control reads the analyser's magnitudes in ~96 log-spaced bands and pushes one column.
- **Out of band:** where True is outside `receiver.audible` (`data/ui/comms_feed.json`, D < 0.02 or D > 50), True plays nothing, and the tap carries nothing. The waterfall goes dark, which is the truth.

**The Receiver's line.** A thin teal line at the carrier's rest frequency, 400 Hz.
- It is a data constant, the beacon recipe's carrier, recorded in `comms_feed.json` as `waterfall.carrier_hz` beside the receiver's other constants.
- It is solid in the Receiver setting (what is heard) and dashed in True (where a receiver would put it).
- The Receiver setting is the Processed instrument, labelled "♪ receiver" as today.

**The gap is the Doppler shift.**
- A coral bracket runs from the measured True carrier (the analyser's peak on a second silent tap, `Carrier`, which carries only the True beacon) to the teal line, with `×D` from `earth.rate` (`sci`), as on the Earth clock.
- At D = 1 the two lines meet. At D = 0.0709 the carrier is at the floor of hearing, 28 Hz. At D = 14.1 it is at 5.6 kHz.
- **Off scale:** when the plan's `hearing` is `above` or `below` (receiver_plan's field), the bracket ends in an arrow at the edge with the station's existing words "above hearing" or "below hearing", and the line is gone from the picture. The arrow is driven by that field and by nothing computed.

**No physics in Godot.** The waterfall plots measured audio. Its only numbers are `earth.rate` and the axis constants. A source guard (`make comms-waterfall-test`) fails if `ui/comms_waterfall.gd` multiplies a rate into a frequency.

**On the bridge (OQ6).** The comms desk's idle screen (`ShipConsoles` `IdleScreen_comms`, today "Comms / Earth at +t") shows the same waterfall, live, whenever the ship is in beam: the readout Mark asked for, diegetic and visible across the deck. Out of beam it shows the static's waterfall, the receiver's own hiss. A strip on the Voyage console is an option, not recommended (OQ6).

### D4. Physics notes (no compromises)

- **The wall is exact.** Each week's arrival is the tick at which `frameOf(newest_light_t)` passed it (tick resolution, merged per ship day). Its beam state is the same `inBeam` rule as `earth.in_beam`. Nothing about arrival times is computed outside the sim.
- **Ship time on the x axis is the honest axis:** equal steps are equal lived time aboard. Earth time would make every week equal and hide the rate (OQ2).
- **The waterfall is exact within hearing** because it is the audio itself. The beacon's True row is measured at 400·D Hz within 1 % (PR #375's mixer measurement), and the waterfall's peak test repeats that measurement.
- **Beyond hearing it shows absence:** a dark band and an arrow, never a line drawn where no sound is. A wideband radio view would be a different, Processed instrument (OQ5).

### D5. The Archive (standing order 2026-10-28)

`archive.earths-carrier` ("Earth's Carrier"), in-world voice, unlocked the first time the waterfall is open at D ≠ 1. It explains:
- Earth keys a steady tone. The ship hears it shifted by the Earth rate.
- Flying away at 0.99c its 400 Hz is 28.355 Hz. Flying home it is 5,642.8 Hz. At the top speed toward home it is 565,680 Hz, far beyond hearing, so the receiver must correct it, as the Deep Space Network corrects the Voyagers' Doppler shift every day.

The check values are 400 × RS-26, RS-29, RS-30 and RS-28 (0.28284 Hz). They go into `physics/relativity-spec.md` §2 as **RS-xx** rows (design repo, first), with `tests/test_physics.gd` asserting them.

## Acceptance criteria

| # | Criterion | Check (command) |
|---|---|---|
| AC1 | The log: one record per ship day with new weeks, merged by `beamed` and `day`; `fromFrame` continues `lastFrame + 1`; a 30-ship-year synthetic voyage stays within days + beam changes; the merge, the beam split and departure (week 0) are tested with mutants | `ailang test --package sim` (new `earth_link_test.ail` checks) and `ailang check --package sim` |
| AC2 | Nothing from the future: every record's `to_frame ≤ frameOf(newest_light_t)` and `tau ≤ clock.tau` at every tick of a recorded voyage; `earth_weeks` beyond `lastFrame`, or inside an unbeamed record, returns no rows | `make comms-log-test` (new; VM and interpreter) |
| AC3 | Pure and deterministic: `noteLight` and the codec run on the strict VM; VM = interpreter on a 2.17 voyage; a new 2.17 replay case is byte-identical to its golden; every 2.16 golden unchanged | `make strict parity replay` |
| AC4 | Protocol 2.17: `earth_log` in full states, `earth_log_tail` only when the newest record changed, nothing below minor 17 or inside a black hole's scenario | `ailang test --package sim` (`protocol_test.ail` checks) and `make replay-compat` |
| AC5 | The filmstrip draws every received week (picture, slit or stack), static over unbeamed spans, x by `ship_year`; every digit on it is a binding to an `earth_log` field | `make comms-station-test` (new checks) and `make display-audit-comms` (extended playthrough, new = 0, failures = 0) |
| AC6 | The waterfall's measured True peak is within 1 % of 400·D at D = 0.070888, 1 and 14.107; the Receiver line is at `waterfall.carrier_hz`; at D = 60 and 1414.2 the picture is dark and the arrow reads "above hearing"; no rate × frequency in `ui/comms_waterfall.gd` (source guard) | `make comms-waterfall-test` (new) |
| AC7 | The comms console at the approved spot: the evaluator counts five stations (comms faces the bow, is clear, and its zoom frames the pole); a seeded "faces the rim" defect fails; every other metric unchanged | `make deck-layout-eval deck-layout-eval-test` |
| AC8 | The bridge's walk and level baselines hold (or are re-pinned with a stated reason); chair → comms walked ≤ 10.5 m (A) or ≤ 6.5 m (B) on the game's router | `make levels-regress deck-assets-check` and `make comms-walk-test` (new, prints `ShipConsoles.path_length`) |
| AC9 | Archive: `archive.earths-carrier` check values in the spec and asserted | `godot --headless --path . --script tests/test_physics.gd`, `make lore-values codex-test` |
| AC10 | Review renders from the real sim (outbound, port, off beam, homeward True/Receiver, home; console Bow, Astern and zoom at the spot), opened and looked at, uploaded | `make capture-comms-v2` (GPU window), then the refs URLs in the sprint report |
| AC11 | Gates: the theme, Python and `.uid` guards, the full suite on the rig | `make ui-theme-check python-guard uid-guard`, then `tools/rig_check.sh <PR> --golden` (`rig/full` green) |

## Sub-milestones and estimates

| ID | What | LOC | Depends on | Order |
|---|---|---|---|---|
| CV0 | Rebase on main after #374, #375 and #377 land; baseline captures of today's station and console | 0 | the three PRs | first |
| CV1 | Sim: the log in `earth_link.ail`, `noteLight` in `core.ail`, protocol 2.17 `earth_log`, `earth_log_tail`, `earth_weeks`; tests, strict, parity, replay case | 380 | CV0 | 1 |
| CV2 | Bridge storage; `EarthHistory` filmstrip; rays on `EarthStrip`; the v2 layout of `CommsStation`; display audit | 430 | CV1 | 2 |
| CV3 | Waterfall: `Antenna` and `Carrier` taps in `sound_mix.gd`, `ui/comms_waterfall.gd`, the receiver line and bracket, the desk screen (if OQ6); tests | 300 | CV0 (#375) | parallel with CV1–CV2 |
| CV4 | Console move: layout, walk bake, Blender regenerate, manifest, evaluator to five stations, baselines | 120 + GLBs | CV0, OQ1 | parallel |
| CV5 | Archive entry and spec rows (design repo first); review captures; **pause for Mark's review**; evaluation by the other family; landing | 220 | CV2, CV3, CV4 | last |

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| The spectrum analyser on a muted bus may not run headless (the Dummy driver), so a test sees no magnitudes | CV3 starts with a spike against PR #375's own mixer measurement path. If the analyser needs a real driver, the peak test runs where #375's beacon measurement runs, and the headless test checks the plumbing (the tap's routing and the plan) |
| Playing the True rendition on a silent tap doubles the receiver's decode cost | Only while the station or the desk screen is visible; the beds are already streamed; profile against `make bench SCENE=bridge` |
| The log grows over a long voyage and slows full states | Bounded per ship day (AC1). Full states only at start and load. Tick deltas carry one record |
| The wall becomes a scrubbable log (pillar 3) | No counts, no totals, a film not a table; words only as stamps; the newest picture stays the live feed |
| Regenerating the bridge GLBs drifts props other than the desk | The generator's `unmoved_objects_identical` check and `make deck-assets-check`; the identity layout must still reproduce today's exports byte for byte before the move |
| Static and the slit-scan flicker at the zoom limits | The slit width is clamped to ≥ 1 px; static is one stretched noise texture per span, not per record |
| Merge order with #374, #375 and #377 | CV0 waits for all three; nothing here edits their files before then |

## Open questions for Mark

1. **OQ1, where the console goes.** **Recommend A**: the port wing beside the Voyage console (−11.0, 8.0), a 9.9 m walk, with the open floor kept clear. B, inboard at the chair's shoulder (−5.6, 7.0), halves the walk again (5.8 m) and looks over the captain's shoulder, but puts a desk on the open stage.
2. **OQ2, the wall's axis.** **Recommend ship time**: the spacing is the physics, sparse outbound and a flood homebound. The alternative, Earth time with every week the same width, reads as a calendar and hides the rate.
3. **OQ3, out-of-beam light.** **Recommend showing it as static on the film** (the light came, the beam was not in it). The alternative collapses the gaps, which hides the cost of a turn.
4. **OQ4, what the waterfall hears.** **Recommend the whole signal from home** (the week's bed and the carrier) for the picture, with the bracket measured on the carrier alone. The alternative is the carrier only, cleaner but bare.
5. **OQ5, the carrier beyond hearing.** **Recommend True only for now**: the band goes dark and an arrow says "above hearing". A labelled Processed wideband view (the radio's own carrier track, 0.1 Hz to 1 MHz) can follow as its own design.
6. **OQ6, the bridge readout.** **Recommend the comms desk's own screen** showing the live waterfall (diegetic, seen across the deck, and beside the Voyage console at spot A). The alternative, a strip on the Voyage console as well, is not recommended: it splits the comms station's job across two desks.
7. **OQ7, stamp precision.** **Recommend one ship day per record** (the bound and the stamp agree). The alternative, every tick, gives finer stamps and an unbounded log.

## Deliverables

- **Mock-ups** (`gs://stapledons-voyage-assets/refs/comms_v2/`, index at `index.html`):
  - `station_outbound_true.png`, `station_outbound_receiver.png`: D 0.0709, the carrier at 28 Hz below the Receiver's line;
  - `station_rest_alpha_receiver.png`: D 1, the lines meet;
  - `station_off_ray_receiver.png`: out of beam, static growing, the receiver's hiss, no carrier;
  - `station_homeward_true.png`, `station_homeward_receiver.png`: D 14.1, the flood begins, the carrier at 5.6 kHz;
  - `station_arrived_home_receiver.png`: the whole voyage on the wall;
  - `history_wall_detail.png`: the whole voyage, the outbound zoom, the flood zoom, and the rays on the spacetime strip;
  - `waterfall_rates.png`: D 0.0709, 1, 14.1 and 1414, True and Receiver;
  - `console_plan_compare.png`: plans with the walked path;
  - `console_{today,spot_a,spot_b}_{bow_rest_comms,bow_cruise_comms,astern_rest_comms,console_comms,review,bow_rest_spawn,plan}.png`;
  - `console_spot_a_idle_waterfall.png`: the desk screen as the bridge readout;
  - `console_probe.json`.
- **This design doc,** the sprint plan `comms-station-v2-sprint.md` and `.ailang/state/sprints/sprint_R3-COMMS-V2.json`, all awaiting Mark.
- **After approval and execution:**
  - the sim log and protocol 2.17;
  - `ui/earth_history.gd` and `ui/comms_waterfall.gd`;
  - the moved console (GLBs and manifest);
  - `archive.earths-carrier` and its spec rows;
  - a changelog fragment and the review captures.
