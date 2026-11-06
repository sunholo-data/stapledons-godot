# R3-COMMS-V2: the comms station v2 and the bridge as mission control

**Status:** **Implemented 2026-11-06** (#379 with design #55; Codex evaluation 96 PASS, round 3, `.ailang/state/evaluations/eval_R3-COMMS-V2_round_3.json`; Mark's OK on dev build `v0.4.0-dev.37-living-bridge-331-g5de4a31a`). Approved by Mark, 2026-11-03 (revision 3). Mark reviewed revision 2 ("looks awesome") and approved it with every open question at its recommendation. He made one change: "can we move the consoles to be underneath the screens? yes will need model updates I guess." Revision 3 records that ruling (§D2). Execution starts with CV1 on this branch, now merged with main (AILANG v0.56.1, #374, #375 and #377 landed). It pauses for Mark at the mid-point review (CV4 + CV6, the bridge renders) and at the end.

**Revision history:**
- **Revision 1 (2026-11-02)** proposed the feed history, the console move and a waterfall at the station.
- **Revision 3 (2026-11-03): approved.** Mark approved revision 2 and its open questions at their recommendations, and ruled: **the consoles stand underneath the screens** (§D2).
- **Revision 2 (2026-11-03)** follows two rulings by Mark on that draft (PR #379):
  - **Where the signal shows (the old OQ6, "cv2_where"), answered.** "the spectrum band I thought we could see as a display in the bridge itself, without needing to go to a console - its a readout on the controls we can see as we walk about - a new console perhaps that functions as a 'scanner' or TV monitor screen. We could do with more of those around to build up the bridge to be more like a mission control center, and when we go to the console we get the detail view." This revision adds **ambient bridge monitors** (§D3), a **mission-control set** of them (§D4) and their **placement** (§D5). The console keeps the detail view.
  - **The history wall, settled.** Mark likes it ("it's educational"). Clicking a picture shows the relative positions of Earth, the ship and the signal: the **frame diagram** (§D1.6). The received-frame record gains the send and arrival events it needs.
  - Every other open question stays open, each with its recommendation (§Open questions).

**Release:** R3 (Signals and Contact). It follows up R3-EARTH-LINK's comms station (S1, K1, F6; [earth-link.md](../../implemented/r3/earth-link.md) EL3b). It is also the first instance of the "deck layout after camera" work (bridge furniture placed for the fixed views).
**Priority:** P2. It deepens the crew's window home, and the bridge starts to read as a place where a voyage is run.
**Origin:** Mark, attended 2026-11-02 and 2026-11-03 (above).

**Mock-ups (the main deliverable; Mark approves these before anything is built):** throwaway renders from the real game and the real sim (protocol 2.16, seed 7). Their scripts lived in the scratch directory and are not committed.
- **Revision 3 (the consoles under the screens):** <https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/r3/index.html>, 13 images.
- **Revision 2:** <https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/r2/index.html>, 23 images: the monitor wall, the screen faces, the frame diagram, and the alternatives scored.
- **Revision 1:** <https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/index.html>, 33 images: the station layout, the history wall, the waterfall rates, the console spots.

**Implements** (design repo):
- [signals-and-instruments.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/signals-and-instruments.md) §2 (the light cone) and §3 (Earth's signal, the Earth rate).
- [contact-console.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/contact-console.md) §1, the Listen pane: what is arriving, "with Doppler, light age and SNR". The waterfall is the visual form of that Doppler.
- `vision/design-decisions.md` standing orders:
  - 2026-10-28, "Visual First, Words Last": monitors, a film, a diagram;
  - 2026-10-28, "the Archive Teaches the Real Physics" (§D7);
  - 2026-10-30, "No Compromises on the Physics; True and Processed Settings": the waterfall is True, and the Receiver is the labelled instrument.
- [art/ship-interior-blender-brief.md](https://github.com/sunholo-data/stapledons-design/blob/main/art/ship-interior-blender-brief.md) §5, the physics contract ("never paint space"): the monitors stand below the horizon and leave the starbow clear.
- **Physics spec** `physics/relativity-spec.md` §2, row "Light cone and Earth's link", **RS-26 to RS-30**. No new formula. Four derived check values for the Archive entry (§D7) go into the spec first.
- Ledger:
  - D-21 (every number on screen is a sim field);
  - D-68 (never show what the ship cannot know);
  - D-91 to D-97 and D-132 (the fixed views, the bow layout, the operator points);
  - D-104 (the grown shape language for props);
  - D-144 (this run).

**Depends on:**
- PR #374: the feed with no tint; its `picked_source` rule feeds the wall's thumbnails.
- PR #375: the exact home beacon and the code-built buses in `audio/sound_mix.gd`, which the waterfall taps.
- PR #377: AILANG v0.56.0.
- `sunholo/observe` 0.1.0 (`seenAt`). No package change.
- The R2-DECK-LAYOUT tooling:
  - `tools/deck_layout.gd`, `tools/deck_walk_bake.gd`, `tools/deck_bow_metrics.gd`, `make deck-layout-eval`;
  - the Blender generators in `~/dev/blender/scripts`;
  - the camera occluder list in `assets/levels/bridge/manifest.json`.

**Estimated LOC:** about 2,250. Sim and protocol 440; the history wall and the frame diagram 580; the waterfall 300; the monitors and their four faces 480; the consoles under the screens 220 (three desks, a bench, the walk, the manifest points, the evaluator; plus regenerated GLBs and one new Blender prop); tests and captures 230. Revision 1 was 1,450 and revision 2 was 2,150.

## Game vision alignment

Scored with the `game-vision-designer` skill (feature-validation mode, against `vision/core-pillars.md` and the standing orders of 2026-10-28 and 2026-10-30): revision 1 on 2026-11-02, re-scored for revision 2 on 2026-11-03. **ALIGNED.**

| Pillar | Score | Rationale |
|---|---|---|
| Choices Are Final | +1 | The wall is a permanent record of what each plan cost at home: a turn off Earth's beam leaves static on it for the rest of the voyage. The course monitor shows the committed leg, never a preview of an outcome |
| The Game Doesn't Judge | 0 | Neutral. Facts on screens, no labels |
| Time Has Emotional Weight | +2 | The core of it. Earth's clock beside the ship's on the front wall: crawling outbound, whirling homebound. The weeks of home arrive far apart, then flood. A week's diagram shows the light chasing the ship |
| The Ship Is Home | +2 | The bridge gains a front wall of live screens that the crew work under: the place reads as mission control, not an empty deck with desks. The crew's faces are on the wall. The comms station moves beside the Voyage console, facing the bow |
| Grounded Strangeness | +2 | The waterfall is the exact Doppler shift, measured from the audio: 28 Hz outbound, 5.6 kHz homebound, against the Receiver's 400 Hz. The frame diagram draws real light at 45° from the sim's own events |
| We Are Not Built For This | +1 | Near the top speed toward home the True carrier leaves human hearing, and the monitor shows it go. Home's history arrives faster than anyone could watch it |
| **Net** | **+8** | **Go.** No pillar is negative. Risks: screens competing with the sky (Grounded Strangeness) and the wall turning into a log to scrub (pillar 3). Mitigations: the monitors stand below the horizon and off the helm's centre (§D5, measured), and the wall has no counts or totals |

## Problem

- **The station forgets.** `ui/earth_feed.gd` shows one picture, the week of the newest light, plus two ghost frames. In the recorded voyage (seed 7: Sol to Alpha Cen A, an off-ray leg, home) the ship receives **1,204 Earth weeks in 3.6 ship years**, and the station can show three.
- **The sim knows only "now".** `sim/protocol_earth.ail` sends `feed` and `last_feed`. Nothing records when a week arrived, whether it came in beam, or where the ship was.
- **The bridge is a deck with desks.**
  - Every live readout is inside a console panel or the HUD. Walking the bridge, the captain sees the sky, the props and four small idle screens (0.84 × 0.28 m) that are unreadable beyond a few metres.
  - In the Bow view from the spawn, a desk screen is 12–20 px tall.
  - There is nothing to glance at, so the room does not feel like a voyage is being run from it.
- **The comms station is the far corner of the bridge.** `console_decision_2` stands at ship metres (−13.2, −3.0), stern-port of the mast. It is a **17.1 m** walk from the chair (`WalkArea.path`), it is the only active station whose operator faces the rim, and its zoom misses the forward sky.
- **The spectrogram exists only offline,** in the sound agent's review MP4. In the game the shift is only heard, and in True at D > 50 it is silent with nothing on screen.

## Goals and non-goals

**Goals**
- G1. **Every received week,** oldest to newest, on the station's filmstrip, stamped with its Earth date and its ship arrival date (sim fields), with static where out of beam and spacing in ship time.
- G2. **The frame diagram.** Selecting a week shows where Earth was when it sent it, the light's path at c, where the ship was when it arrived and where it was when Earth sent it, the ship's track, and D at arrival. Every value comes from the received-frame record (protocol 2.18).
- G3. **Ambient bridge monitors:** a new class of furniture, readable from the walk and the fixed views with no interaction.
  - The first is the **signal from home** (the waterfall, True, with the Receiver's 400 Hz line and the ×D bracket).
  - Three more (§D4) make the bridge read as mission control.
- G4. **Placement measured.** Each monitor's readability is scored over every walk sample through the real Bow and Astern poses. Every bow-evaluator threshold holds.
- G5. **The consoles under the screens** (Mark's ruling, §D2): Voyage, comms and crew stand at the bow rail under their screens, facing them; the helm stays central. Every evaluator metric holds.
- G6. **Nothing from the future, determinism and purity** (the log is pure, strict VM, VM = interpreter, byte-identical replays).

**Non-goals**
- New physics or a package change.
- A wideband (radio) Processed view of the carrier beyond hearing (OQ5).
- More than four monitors in this sprint. The rest of the bridge's furniture belongs to the "deck layout after camera" pass, of which this is the first instance.
- Interaction with monitors. They are ambient; the consoles are where the captain acts.
- Asking the AI for wall thumbnails.

## Design

### D0. Two layers: the bridge glance and the console detail

| Layer | Where | What it shows | Interaction |
|---|---|---|---|
| **Glance** | the monitor wall on the bow rail (§D3–§D5) | the live signal from home; Earth's clock against the ship's; the course; the crew | none: seen while walking, from any station, and in the Bow view |
| **Detail** | the comms console (walk there, E) | the station of revision 1: the feed, the full waterfall with its axes and setting, the history wall, the frame diagram, the light strip, Details | select, zoom, the True/Receiver setting |

The waterfall appears in both layers: bold on the monitor, with its axes and the setting at the console. Both read the same silent tap, so they always agree.

### D1. Feed history: the received-frame log, the filmstrip and the frame diagram

**D1.1 The sim keeps a log (pure, `sim/earth_link.ail`).** One record per ship day in which new weeks of Earth's light arrived. Each record also carries the send and arrival events the frame diagram needs:

```
Arrival = { fromFrame, toFrame: int, beamed: bool, day: int,
            arrived: { t, tau, p: Vec3, ly, rate },      -- the ship at the tick the weeks arrived
            sent:    { t },                               -- the light-cone event: arrived.t - arrived.ly (= seenAt)
            shipAtSent: Option[{ t, tau, p: Vec3, ly }] } -- the ship's own logged state at sent.t
Link    = { ..., log: [Arrival] (newest first), lastFrame: int }   -- emptyLink: log [], lastFrame -1
```

`noteBeam` becomes `noteLight(l, t, tau, p, rate, leg)`. It is called each tick from `core.ail linkAfter` as today, adding `after.ship.motion.tau` and the tick's Earth rate:

1. `f = frameOf(seenAt(t, p, Sol))`, exactly `earth.feed.frame`.
2. If `f > lastFrame`, the weeks `lastFrame+1 .. f` arrived this tick. `beamed = inBeam(...)` (the `earth.in_beam` rule); `day = floor(tau × 365.25)`.
3. If the newest record has the same `beamed` and `day`, extend `toFrame` and update its `arrived`, `sent` and `shipAtSent` to this tick. Otherwise cons a new record. Then `lastFrame = f`.
4. `shipAtSent` is the newest earlier record whose `arrived.t ≤ sent.t`: the ship's logged position when Earth sent the light, at the log's resolution of one ship day. It is a short walk down a newest-first list, and `None` before the first record.

**The bound:** at most one record per ship day plus one per change of beam, about 11,000 for a 30-ship-year voyage, whatever the rate.
- Outbound at 0.99c each week is its own record: 7 / RS-26 = 98.7 ship days apart.
- Homebound at RS-29 a ship day carries two weeks. At RS-30 it carries 202.

**Determinism:** the log is a pure fold over the ticks, byte-identical on the VM and the interpreter.

**D1.2 Protocol 2.18.** `earth_log` goes in full states (oldest first) and `earth_log_tail` on ticks where the newest record changed. Both are sent at minor ≥ 17 only, and never inside a black hole's scenario. The bridge stores records by `from_frame`. A record:

```
{from_frame, to_frame, beamed,
 earth_from_year, earth_to_year,                         -- epoch + frame x feedBinYears
 sent: {t, year},                                        -- year = epoch + t
 arrived: {t, year, tau, ship_year, p: {x,y,z}, ly, rate},
 ship_at_sent: {t, tau, ship_year, p: {x,y,z}, ly} | null,
 feed: {frame, kind, event: {id, category, words}, pick}}   -- the newest week's picture
```

Every number on the wall and in the diagram is one of these fields (D-21). Godot places and formats, and never computes.

**D1.3 `earth_weeks`.** A read-only intent `{"k": "earth_weeks", "from": a, "to": b}` returns at most 52 rows `{frame, earth_year, kind, event, pick}` for a stack's weeks. The sim clips it to beamed, arrived weeks (D-68).

**D1.4 The filmstrip** (`ui/earth_history.gd`, unchanged from revision 1). x is ship time, with now at the right. Pictures appear in full where there is room, as slits where the weeks crowd, and as stacks where several weeks arrived together. Static fills the out-of-beam spans. Each picture carries two stamps: Earth date in ochre and ship date in teal. A thin line shows Earth time received, so its slope is the Earth rate. Each arrival is also drawn as a ray on the light strip. ([wall](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/history_wall_detail.png))

**D1.5 Thumbnails and the AI.** The wall loads each library picture once and shows a painted frame only if the AI cache already holds it. It never opens a request.

**D1.6 The frame diagram (settled by Mark, 2026-11-03).** Selecting a picture on the wall (or a week inside a stack) shows it large with its two stamps, beside its light-cone diagram. Mock-ups:
- [outbound week 1](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/r2/detail_frame_outbound.png);
- [homeward week 1,000](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/r2/detail_frame_homeward.png).

**The spacetime panel.** Galaxy time runs across and distance from Earth runs up, at **one year = one light-year**, so light always runs at 45°. It draws:
- Earth's line (ochre);
- the ship's track (teal): the polyline of the log's `arrived.{t, ly}`;
- the send event on Earth's line at `sent.t`, labelled with `earth_from_year`;
- the light's path at c (cream) from the send event to the arrival;
- the arrival on the track at `arrived.{t, ly}`, labelled with `ship_year` and `×` `arrived.rate`;
- "ship then": a hollow dot at `ship_at_sent`, the ship when Earth sent it.

**The plan inset** (from above). Sol, the ship's track (`arrived.p` of the log), the ship at arrival and at `ship_at_sent`, and the light's straight path from Sol.

**What it teaches, from the real sim:**
- **Outbound week 1** left Earth at +0.02 yr and caught the ship at ship +0.27 yr, 1.91 ly out, at ×0.0709. At 0.99c the light's path runs alongside the ship's track: it barely gains.
- **Homeward week 1,000** left at +19.20 yr, when the ship was 3.83 ly out. The ship and the light closed, and met at 1.92 ly, at ship +3.32 yr, at ×14.1.

**A stack's weeks** share their record's arrival. The diagram draws the record's ray (the weeks arrived within one ship day) and labels the selected week's own Earth date from `earth_weeks`.

**How it relates to the other two diagrams, so nothing is drawn twice:**
- **The galaxy map's beams** (R3-EARTH-LINK F6) show *Earth's aim now*: rays from Sol through the ports of plans Earth has heard, and stale beams. That is Earth's present intent, in space only.
- **The frame diagram** shows *one received week's past*: the light that actually reached the ship, in spacetime. It never draws Earth's current aim.
- Its plan inset uses the map's glyphs (Sol in ochre, the ship in teal), so the two read as one language.
- **The light strip** (EarthStrip) is already the station's spacetime picture of plans and replies. The frame diagram is the strip **in frame mode**: selecting a week turns the strip to that week's events, and deselecting returns it. It is one spacetime view, not a third diagram.

### D2. The consoles under the screens (Mark's ruling, revision 3)

**Ruling (Mark, 2026-11-03):** "can we move the consoles to be underneath the screens? yes will need model updates I guess." It supersedes revision 1's spot A/B question (the old OQ1).

**The layout.** Each console stands on the bow rail walkway under its screen, at radius 18.6 m, turned so its operator faces the screen and the rail. The operator stands 1.225 m inboard of the desk. The desk's yaw is −90° − bearing (the layout's yaw is counter-clockwise about +Z).

| Console | Screen above it | Bearing | Desk (ship m) | Yaw | Operator point (ship m) | Today |
|---|---|---|---|---|---|---|
| Voyage (`console_decision_0`) | Earth's clock | −48° | (−13.822, 12.446) | −42° | (−12.912, 11.626) | (−7.829, 12.207), yaw −90 |
| Comms (`console_decision_2`) | signal from home | −30° | (−9.300, 16.108) | −60° | (−8.687, 15.047) | (−13.2, −3.0), yaw 0 |
| Crew (`console_decision_1`) | crew faces | +48° | (13.822, 12.446) | −138° | (12.912, 11.626) | (8.479, 14.169), yaw −90 |
| Helm (`console_navigation_0..2`) | course (+24°, beside it; +30° until CV5) | −16 / 0 / +16° at 17.5 m | unchanged | unchanged | (0, 15) | unchanged |

- **The helm stays central** to keep the pole and starbow on its line (D-94). The course screen at +24° sits beside its starboard pod, so the helm serves it. (CV5 moved it from +30°: at +30° it stood on the forward-pole line of the physics golden's fixed captain eye, G-M4-S3 at ship (11, 4.8), and covered the pole; at +24° `make golden` is green and its Bow readability is unchanged, 0.346.)
- **The port wing is home:** the Voyage console under Earth's clock and comms under Earth's signal.
- **The starboard wing is the ship:** the course screen by the helm, and the crew console under the crew's faces.

**Measured** in-engine on the shipped deck: the three desks moved together with the four monitors of wall R as camera occluders, scored through the real Bow and Astern poses over all 4,783 walk samples ([`consoles_probe.json`](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/r3/consoles_probe.json)).
- **Every evaluator metric equals the shipped bridge:**
  - Bow fades 479, Bow head blocks 0, pole ray 0;
  - stop body 8 on both sides;
  - Astern head blocks 1;
  - spawn near field 0.015 (Bow) and 0.074 (Astern);
  - spawn open 3.50 m.
- **All five stations face the bow,** are clear in the Bow view with no fades, and keep the stop body clear. The Voyage, crew and comms zooms frame the forward pole.
- **Operator points:** every operator point is walkable and reachable on the game's router. Walking distances:

  | Station | From the chair | From the spawn |
  |---|---|---|
  | comms | 8.4 m (today 17.1 m) | 9.9 m |
  | Voyage | 11.4 m (today 5.8 m) | 15.2 m |
  | crew | 16.4 m (today 12.1 m) | 13.6 m |
  | helm | 6.8 m | 2.2 m |

- **The rim walk stays open.** The port quarter to the starboard quarter along the rail is 39.4 m on the router. The stretch behind the port desks is 14.6 m against a 13.9 m arc.
- **Monitor readability is unchanged** by the desks (the desk tops pass under the faces): signal 0.34, course 0.35, clocks 0.28, crew 0.28 Bow-readable share.
- A desk at radius 19.3 m measured the same but walks about 0.5 m longer, so the plan uses 18.6 m.

**What it looks like:**
- From the spawn ([0.99c](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/r3/bow_cruise_spawn.png), [rest](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/r3/bow_rest_spawn.png)): the wall with a desk under each port screen and the crew desk at the starboard edge.
- At the [comms desk](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/r3/console_comms.png) and the [crew desk](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/r3/console_crew.png), the operator's zoom frames the screen right above the desk, with the starbow beside it.
- The rest: [chair](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/r3/bow_cruise_chair.png), [comms operator](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/r3/bow_cruise_comms.png), [Voyage operator](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/r3/bow_cruise_voyage.png), [crew operator](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/r3/bow_cruise_crew.png), [Astern](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/r3/astern_cruise_spawn.png), [from above](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/r3/review.png), [plan](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/r3/plan.png).

**Costs, seen in the renders:**
- The Voyage console is further from the chair than today (11.4 m against 5.8 m).
- The port watch bench now stands between the Voyage and comms desks. CV4 moves it 2 m sternward along the rail (it is a movable group, `v2_bench_detail_*`) or drops it.

**Build (CV4, "consoles under the screens"):**
1. **Layout.** `art/deck-layout-v2/bow_a.json` gains the three desks above, with their `use_m` and the ruling in its `about`. The watch bench moves as noted.
2. **Walk.** Bake the walk with `tools/deck_walk_bake.gd`. The desks' collision comes from their walk holes, as for every moved group.
3. **Blender.** One generator run moves the desks and places the four monitor props: `stapledon_deck_layout_v2.py`, then `stapledon_bridge_props_v4.py` on its master. It re-exports `ship.glb`, `bridge_props.glb` and `walk_bridge.glb`, and the sidecar carries the `INTERACT_<station>_use` points and the monitor anchors. Before the move, the identity layout must reproduce today's exports byte for byte.
4. **Runtime and pins.**
   - Manifest: `stations.{voyage, crew, comms}.use_m` and `screen_ship_m` (the D-132 working points are re-derived).
   - Repin `budgets.json` and `asset-pins.json`.
5. **Camera and evaluator.**
   - `data/camera/views.json` and the bridge level manifest are unchanged. The Bow and Astern views need nothing new, and the console zooms are derived from the moved meshes.
   - The evaluator counts five active stations (`ZOOM_STATIONS` gains comms) and gets a seeded "faces the rim" defect.
6. **Validation:** `make deck-layout-eval deck-layout-eval-test deck-assets-check levels-regress comms-walk-test camera-test`, re-pinning the bridge baseline with the reason stated if `levels-regress` moves.

### D3. Ambient bridge monitors: a new class of furniture

**What a monitor is.** A framed 16:9 screen on a grown stand (D-104 shape language), 4.0 × 2.25 m. Its bottom edge is 1.0 m above the deck and its top 3.25 m, so its face is below the Bow eye's horizon and off the helm's centre.
- It shows a live face rendered from sim fields into a `SubViewport`.
- It refreshes only while it is on screen (`VisibleOnScreenNotifier3D`): the waterfall at 30 Hz, the others at ≤ 10 Hz.
- It never takes input.

**The ambient face rule** (measured on the 1440p crop below):
- **Big:** one idea per screen, the key value ≥ 40 px at the face's 960 × 540, lines ≥ 3 px.
- **Few words:** only labels (Earth, ship, no signal).
- **Bound:** every number is a `ComposedBinding` to a sim field (D-21), audited by `DisplayBinding.audit` like the consoles.
- **No physics in Godot:** the waterfall plots measured audio; the clocks turn by sim fields; the chart places sim positions.

**Building blocks:**
- **New code:** `interior/bridge_monitor.gd` (`BridgeMonitor`: the screen mesh, the viewport, visibility gating) and `ui/screens/*.gd` (one face per monitor).
- **Placement as data:** the level manifest gains `monitors: {<id>: {face, screen_ship_m, normal}}`, written from the Blender sidecar like `stations.<id>.screen_ship_m`.
- **Camera fades:** the camera occluder list gains `monitor`, so a monitor fades when it would hide the captain, like the rim fronds. Without this the Astern view was blocked at 103–120 samples; with it, at 1, the shipped value.

**Readable at a glance** ([chair, 1440p](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/r2/wall_hires_bow_cruise_chair.png), [signal crop](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/r2/wall_hires_signal_crop.png)):
- At 2560 × 1440 from the chair, the signal screen is about 115 px tall.
- The True carrier line, the Receiver's 400 Hz line, the bracket and "×14.11" all read.
- At the 720p of the measurements, readable means ≥ 40 px tall.

### D4. The mission-control set: four screens, ranked

Each candidate was weighed on three things: what it adds at a glance; whether every number is already a sim field (D-21); and how it stands under True and Processed.

| Rank | Screen | At a glance | Fields (all existing unless noted) | True / Processed | Verdict |
|---|---|---|---|---|---|
| 1 | **Signal from home** ([face](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/r2/screen_signal_homeward.png)) | The waterfall: True base, the Receiver's line at 400 Hz, the ×D bracket; the link bar (teal in beam, grey out); the light's age | `earth.rate`, `earth.in_beam`, `earth.light_age_years`; the carrier constant `waterfall.carrier_hz` (data) | True picture; the Receiver line is the labelled instrument; "above/below hearing" from the receiver plan | **Build** (Mark's ask) |
| 2 | **Earth's clock against the ship's** ([face](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/r2/screen_clocks_homeward.png)) | Two dials (Earth crawls outbound, whirls homebound), ×D, the Earth year in the newest light, the ship year | `clock.tau`, `earth.newest_light_t`, `earth.newest_light_year`, `earth.rate` | Exact in every setting (a rate cannot be processed) | **Build** |
| 3 | **Course and next waypoint** ([face](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/r2/screen_course_homeward.png)) | The leg on a chart (Sol, departure, target, the ship and its heading, Earth's beam ray), the phase (boost / cruise / brake), the target, the Earth year at arrival, γ | `journey.plan.{departure, target, arrive_year}`, `ship.{pos, phase, gamma}`, `earth.beam.port`; **new:** `journey.ship_years_left` if a remaining ship time is shown (OQ12) | Exact geometry | **Build** |
| 4 | **Crew** ([face](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/r2/screen_crew_homeward.png)) | The five faces at their home feeling, with names | `earth.crew.<i>.{id, name, feeling}` | Not applicable | **Build** |
| — | Light-cone / beam strip | Plans and replies as light | `earth.messages` | Exact | **Fold in:** the signal screen's link bar carries in beam / out; the strip stays at the console (§D1.6) and the beams on the map. A fourth copy would duplicate |
| — | Dust and ISM counter | Medium, flash rate | `ship.ism.*` | True (the flashes are what is seen) | **Later:** the HUD and the dust sound carry it; a candidate "weather between the stars" screen for the layout pass |
| — | Star light / exposure meter | True illuminance against the Processed exposure | the star light of #374, D-38 exposure | True + labelled Processed by nature | **Later:** a natural labelled-instrument screen once #374 lands its star-light settings |

**The set in other moments** (real sim, revision 2 mock-ups):
- the signal [outbound](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/r2/screen_signal_outbound.png): the carrier at 28 Hz, the bracket down, ×0.07089;
- the signal [off the beam](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/r2/screen_signal_off_ray.png): "no signal", the receiver's own hiss, the link bar grey.

### D5. Placement: the monitor wall on the bow rail

**The views decide it.** On the bridge the fixed views are Bow (the default) and Astern. The Bow eye stands 9 m stern of the captain and 5.5 m up, looking at the bow (D-93). So a screen read while walking must:
- stand bow-ward of where the captain works;
- face stern;
- sit below the horizon, where the starbow is centred;
- keep off the helm's centre line.

That is the front wall of a mission control room. The bow rail is the stage front (deck-layout §D0), with the consoles in rows facing it.

**Three layouts scored** in-engine on the shipped deck (revision 2, with comms at spot A; revision 3 re-scored wall R with the consoles under it, §D2, and every number held):
- **Readability:** each monitor scored over all 4,774 walk samples through the real Bow and Astern poses. Readable means in frame, facing the camera (cos ≥ 0.3), at least 40 px tall at 720p, and 2 of 3 probe rays to its face clear (a node the director fades counts as clear).
- **Bridge metrics:** the bow evaluator re-run with the monitors' colliders in the world.
- Data: [`monitors_probe.json`](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/r2/monitors_probe.json) (wall R).

| Layout | Where | Size | Bow readable share (each screen) | Evaluator | Verdict |
|---|---|---|---|---|---|
| **R (recommended)** | bow rail, r 21.1 m, outside the walk: clocks −48°, signal −30°, course +30°, crew +48°; camera occluders | 4.0 × 2.25 m | clocks 0.28, signal 0.34, course 0.35, crew 0.28 (mean 58–65 px when readable) | **ok**: every metric equals the shipped bridge (Bow head blocks 0, Astern 1, pole ray 0, stop body both sides 8, spawn near field 0.015 / 0.074) | the front wall |
| F | the same bearings ±30/±50, on the rim walk (r 19.9), not occluders | 3.2 × 1.8 m | 0.18–0.22 | **fail**: captain's head blocked at 17 Bow and 103 Astern samples | on the walk; too small |
| W | a port-wing triptych over the comms desk (−42, −56, −70°) + crew at +50° | 3.2 × 1.8 m | 0.16–0.20 | **fail**: 12 Bow, 58 Astern | only the signal shows at the spawn, at the frame's edge |

**Wall R from named places (Bow view):**

| Place | Clocks | Signal | Course | Crew |
|---|---|---|---|---|
| Spawn | out of frame | **67 px** | **67 px** | out of frame |
| Captain's chair | **74 px** | **57 px** | **57 px** | **75 px** |
| Comms desk (A) | **59 px** | **48 px** | **48 px** | out of frame |
| Voyage console | **78 px** | **59 px** | **60 px** | out of frame |
| Helm | out of frame | **78 px** | **78 px** | out of frame |
| Crew console | out of frame | **68 px** | **67 px** | **92 px** |
| Archive (stern, behind the mast) | 37 px | 32 px | 32 px | 37 px (all too small) |

- **The signal screen** reads from six of the seven places; the chair reads all four.
- **The stern half** (the Archive, the lift) sees the wall too small, and the Astern view sees almost none of it (≤ 3.5 % of samples). A stern repeater is OQ10.
- **The pictures:**
  - [spawn at 0.99c](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/r2/wall_bow_cruise_spawn.png) and [at rest](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/r2/wall_bow_rest_spawn.png);
  - [chair](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/r2/wall_bow_cruise_chair.png), [comms](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/r2/wall_bow_cruise_comms.png), [mid-deck](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/r2/wall_bow_cruise_middeck.png), [crew console](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/r2/wall_bow_cruise_crew.png);
  - [Astern](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/r2/wall_astern_cruise_spawn.png), [review view](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/r2/wall_review.png), [plan](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/r2/wall_plan_labelled.png).
- **Port is home, starboard is ship:** clocks and signal sit over the Voyage console and comms; course and crew sit over the helm's starboard side and the crew console.
- **The starbow stays clear:** at 0.99c it fills the frame above the helm, and the wall's faces sit under its flanks, never on its core or on the pole.

**Build (CV6):**
1. **The prop.** Author `bridge_monitor` in Blender (the grown frame and stand, D-104) with `monitor_<id>` instances at the four bearings, in the master that CV4 regenerates. One generator run covers both the console move and the monitors.
2. **Runtime.** The manifest's `monitors` section, then `BridgeMonitor`, the four faces, and `monitor` in `camera.occluders`.
3. **The evaluator gains a readability metric:**
   - each monitor's Bow readable share is ≥ 0.25;
   - the signal screen is readable from the spawn, the chair, comms and Voyage;
   - all existing thresholds are unchanged;
   - a seeded monitor on the walk must fail.

### D6. The waterfall (the signal from home)

This is revision 1's §D3. Its home is now the signal monitor, with the detail version at the console.

**Picture.** Always the True signal, read with an `AudioEffectSpectrumAnalyzer` on a silent `Antenna` tap (`audio/sound_mix.gd`, after #375), at −80 dB and sent nowhere audible.
- The tap carries the True beacon and the current week's bed at speed and pitch × D (`EarthFeed.receiver_plan(D, false)`) whenever the ship is in beam and the monitor or the station is on screen. So the monitor shows the signal even when no one is at the station.

**The Receiver's line:** a teal line at 400 Hz (`waterfall.carrier_hz`, data), solid in Receiver and dashed in True.

**The bracket:** it runs from the measured carrier peak (a second silent tap, `Carrier`, which carries only the True beacon) to the line, with `×` `earth.rate`.

**Off scale:** "above/below hearing" from the plan's `hearing` field, with the band dark.

**No rate × frequency** anywhere in the face (source guard).

**The comms desk's own idle screen** keeps today's text. The monitor is the bridge readout, so the earlier idea of a waterfall on the desk is superseded.

### D7. The Archive

`archive.earths-carrier` explains Earth's tone heard shifted by the Earth rate: 400 Hz is 28.355 Hz flying away at 0.99c, 5,642.8 Hz flying home, and 565,680 Hz at the top speed toward home, which is why a receiver must correct it, as the Deep Space Network does for the Voyagers.
- **Check values:** 400 × RS-26, RS-29, RS-30 and RS-28. The spec rows go in first.
- **Unlock:** the first time the signal monitor is on screen at D ≠ 1. **As built: `first_boost`** (the sim's first change of D; unlocks are sim events and the sim cannot see a monitor), a recorded deviation (Execution notes).

`archive.earths-voice` gains one line on the frame diagram: "every picture from home is a ray of light that left Earth and caught you".

## Acceptance criteria

| # | Criterion | Check (command) |
|---|---|---|
| AC1 | The log: one record per ship day, merged by `beamed` and `day`; contiguous frames; the bound on a 30-ship-year synthetic voyage; departure week 0; mutants killed | `ailang test --package sim` and `ailang check --package sim` |
| AC2 | Nothing from the future: every record's `to_frame ≤ frameOf(newest_light_t)`, `arrived.tau ≤ clock.tau`; `earth_weeks` clipped | `make comms-log-test` (new; VM and interpreter) |
| AC3 | The diagram's events are exact: `sent.t = arrived.t − arrived.ly` to 1e-12; `ship_at_sent.t ≤ sent.t` and it is the newest such record; `arrived.rate` equals that tick's `earth.rate` | `make comms-log-test` |
| AC4 | Pure and deterministic: strict VM; VM = interpreter on a 2.18 voyage; the new replay case byte-identical; every 2.16 golden unchanged | `make strict parity replay replay-compat` |
| AC5 | The filmstrip covers every received week; static over unbeamed spans; every digit bound to `earth_log` | `make comms-station-test display-audit-comms` |
| AC6 | The frame diagram draws only record fields (send, light, arrival, ship then, track, ×D); light at 45° (equal axes); selecting and deselecting returns the strip | `make comms-station-test` (new diagram checks, binding audit) |
| AC7 | The waterfall: measured peak within 1 % of 400·D at D 0.070888, 1, 14.107; dark with "above hearing" at D 60 and 1414.2; source guard | `make comms-waterfall-test` (new) |
| AC8 | The monitors: four faces, every number bound (audit), visibility-gated refresh; wall R's readability ≥ the thresholds; the evaluator unchanged otherwise; a seeded on-walk monitor fails | `make bridge-monitors-test deck-layout-eval deck-layout-eval-test` |
| AC9 | The consoles under the screens (§D2): five stations face the bow and are clear; every operator point walkable and reachable; chair → comms ≤ 9.0 m; the rim walk port to starboard ≤ 42 m; every other evaluator metric unchanged | `make deck-layout-eval deck-layout-eval-test comms-walk-test levels-regress deck-assets-check camera-test` |
| AC10 | Performance: the bridge with four live monitors | `make bench SCENE=bridge` (p99 < 16.7 ms at 2560 × 1440 on a quiet rig) |
| AC11 | Archive check values asserted | `godot --headless --path . --script tests/test_physics.gd`, `make lore-values codex-test` |
| AC12 | Review renders from the real sim (the wall from the walk and the fixed views, the faces at three moments, the frame diagram outbound and homebound, the console at its spot), opened and uploaded | `make capture-comms-v2` (GPU window) |
| AC13 | Gates and the rig | `make ui-theme-check python-guard uid-guard`, then `tools/rig_check.sh <PR> --golden` (`rig/full` green) |

## Sub-milestones and estimates

| ID | What | LOC | Depends on | Order |
|---|---|---|---|---|
| CV0 | Rebase after #374, #375, #377; baseline captures | 0 | the three PRs | first |
| CV1 | Sim: the log with send and arrival events, `noteLight`, protocol 2.18 `earth_log`, `earth_log_tail`, `earth_weeks`; `journey.ship_years_left` if OQ12; tests, strict, parity, replay | 440 | CV0 | 1 |
| CV2 | Bridge storage; the filmstrip; the frame diagram (the strip in frame mode, plus the plan inset); the station layout | 580 | CV1 | 2 |
| CV3 | The waterfall: the `Antenna` and `Carrier` taps, `ui/comms_waterfall.gd` (detail) and its bold face for the monitor | 300 | CV0 (#375) | parallel |
| CV4 | The consoles under the screens: three desks and a bench in the layout, walk bake, one Blender run with the CV6 monitor props, manifest points, evaluator to five stations | 220 + GLBs | CV0 | parallel |
| CV6 | The monitor wall: the Blender `bridge_monitor` prop in CV4's generator run, the manifest `monitors`, `BridgeMonitor`, four faces, `monitor` occluders, the readability metric, bench | 480 + prop | CV3, CV4 | 3 |
| CV5 | Archive and spec rows; review captures; **pause for Mark**; evaluation by the other family; rig; landing | 230 | all | last |

**Duration:** about 7.5 to 8.5 attended days at about 300 counted LOC a day, plus the Blender prop, the rig's `rig/full` and Mark's reviews (after CV4+CV6, after CV5). Revision 1 was 5 days.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Screens competing with the sky | Faces below the Bow horizon and off the helm's centre (measured: pole ray 0, stop body unchanged); the monitor fades as an occluder; the review renders at 0.99c |
| Too many screens turning the bridge into a dashboard | Four, ranked; one idea per face; no interaction; the rest waits for the layout pass |
| Four live viewports cost frame time | Refresh only on screen, ≤ 10 Hz (the waterfall 30 Hz); `make bench SCENE=bridge` gate |
| The spectrum analyser may not run headless | CV3 starts with a one-hour spike against #375's mixer measurement; the headless test checks the plumbing if needed |
| The log grows over a long voyage | Bounded per ship day; full states only at start and load; tick deltas carry one record |
| `ship_at_sent` at a ship day's resolution | Stated in the diagram's data. At 0.99c the ship moves about 0.02 ly per ship day (βγ / 365.25), 1–2 px on the panel |
| Regenerating the bridge GLBs drifts other props | Identity layout byte-for-byte first; `unmoved_objects_identical`; `make deck-assets-check` |
| Merge order with #374, #375, #377 | CV0 waits for all three |

## Open questions for Mark

**All answered (Mark, 2026-11-03):** he approved the revision 2 page, which listed every question, at its recommendation, and added one ruling.
- **The consoles stand under the screens** (§D2). This supersedes the old OQ1 (spot A/B/C).
- **Where the signal shows** (the old OQ6, "cv2_where"): an ambient monitor, plus the console's detail view.
- **The frame diagram** (§D1.6).

| Question | Approved answer |
|---|---|
| OQ2 | The wall's axis is ship time |
| OQ3 | Out-of-beam light shows as static |
| OQ4 | The waterfall shows the whole signal (the True beacon and the week's bed) on the silent tap, with the bracket on the carrier |
| OQ5 | True only beyond hearing |
| OQ7 | One record per ship day |
| OQ8 | Four screens: signal, Earth vs ship clocks, course, crew |
| OQ9 | Wall R on the bow rail |
| OQ10 | No stern repeater in this sprint |
| OQ11 | Blender grown frames |
| OQ12 | Add `journey.ship_years_left` to the sim |

New questions found while executing go here.

## Execution notes (CV5 and the Codex reviews, 2026-11-03)

- **Protocol 2.18.** R3-WORLDS (#371) merged first and took 2.17 (population and census), so the comms log, `course` and `earth_weeks` moved to **2.18** (`earthLogMinor() = worldsMinor() + 1`). A 2.17 session sees neither the log nor the course section and refuses `earth_weeks`; `earth_log_voyage` was re-recorded for the new hello. Codex round 3: 96 PASS.

- **Codex round 2: 88/100, pass**, with one blocker: weeks older than a long stack's newest 52 could not be reached. Fixed by paging (below); `make comms-history-test` opens the oldest week of a 53-week stack.

- **Mid-point accepted** (Mark, "continue"): OQ12 in CV5, the watch bench kept, the diagram taking the faces' row, the x86 golden copy.
- **Codex review (62/100, 9 blockers), all addressed on this branch:**
  - **lint-precision:** the waterfall's row index read like `1 - b`. It is now a named `row`; the lint is unchanged.
  - **Off-screen monitors do no work.** `BridgeMonitor.on_screen` drives `face.set_live`. Off screen, the signal face's waterfall draws no columns, takes no measurements and releases the shared taps (they stop once no waterfall wants them). On screen it refreshes at 30 Hz (`SIGNAL_HZ`, one column each) and the others at 10 Hz. `make bridge-monitors-test` counts refreshes, columns and taps off screen (0, 0, stopped) and on screen at 120 fps (61 in 2 s: 30 Hz plus the refresh on coming into view).
  - **The ambient bed comes from the sim's fields.** `EarthFeed.bed_of(view)` derives it from the frame alone, from the start and after the station closes. While the station is open, its held bed leads.
  - **The trace shows only current measurements.** Each column holds that frame's measurement or nothing; the median hold is gone.
  - **AC7 at 1 %, not one bin.** The analyser is Hann-windowed, with 4,096 bins over 0 to mix/2 (5.38 Hz at 44.1 kHz). A coarse pass finds the peak bin, then Grandke's two-point Hann estimator refines it: δ = (2r − 1)/(r + 1) toward the larger neighbour. Measured on the tap over 20 measurements each: 20 Hz within 0.028 %, 28.355 Hz within 0.012 %, 400 Hz within 0.005 %, 5,642.8 Hz within 0.005 %. The test's tolerance is now 1 % alone.
  - **The hearing floor is 20 Hz** (Mark, 2026-11-03: "sure 20hz"). `receiver.audible` is [0.05, 50], human hearing at the 400 Hz carrier, so the beacon's True setting is silent below D = 0.05 (8–20 Hz is infrasound, felt rather than heard at the beacon's level). RS-46 and `features/next/sound.md` say so in stapledons-design#55; the waterfall test checks 0.03 below and 0.05 at the floor; `test_sound` asserts the band is exactly 20 Hz to 20 kHz.
  - **Weeks inside a stack (D1.3) are built.** The read-only `earth_weeks` intent (core `IEarthWeeks`, an arm in every exhaustive match, the codec both ways, refused below 2.18) is answered on its tick with at most 52 beamed, arrived weeks, each `{frame, earth_year, kind, event, pick}`. Selecting a stack asks for its newest 52 weeks; a stack longer than that pages, with arrows at either end asking for the 52 before or after, and the row shows an answer only when it is for the range it asked for (Codex round 2). The station's stack row lets each week be picked; the feed, the row's stamp and the diagram's send label then carry that week's own Earth date. Records gained `earth_year`, the newest week's own date, which the wall's stamps now show. Tests: `earth_log_test` (wire, clipping, 2.16 refusal), `protocol_test` (codec round trip), `test_earth_history` (homebound stacks through the real sim), replay case `earth_log_voyage` (re-recorded with an `earth_weeks` tick).
  - **Monitor readability is in the evaluator.** `DeckBowMetrics.monitor_metrics` adds the Bow and Astern readable shares (in frame, facing, ≥ 40 px at 720p, 2 of 3 rays clear after fades), the named places, and whether a monitor stands on the walk. Thresholds: each monitor ≥ 0.25 (`monitor_readable_min`); the signal screen reads from the spawn, the chair, comms and Voyage; no monitor stands on the walk. The shipped deck: clocks 0.284, signal 0.342, course 0.349, crew 0.291. Negative controls in `make deck-layout-eval-test`: the signal monitor moved onto the walk fails `monitor-walk`, and turned to the stern it fails `monitor-readable` and `monitor-signal`.
  - **GPU golden G-CV** (`make comms-golden`, in `make golden`, 17 lines): the waterfall's trace, Receiver line, bracket foot and tip at D 0.070888 and 14.107, against the CPU rows (trace within 0.05 px; measured within 0.02 % of 400 × D); the frame diagram's send and arrival dots, the ship-when-sent ring and the ray (slope −1.0000, through the CPU send event), outbound and homebound, against the CPU light cone (t = arrived.t − arrived.ly) within 0.12 px.
  - **Captures:** `make capture-comms-v2` now also runs the station capture. It produces the four faces at three moments (`faces_home`, `faces_away`, `faces_homeward`), the frame diagram outbound and homebound, and a week inside a homebound stack (`frame_homebound_week`).
- **The rail through the screens** (Mark, 2026-11-03: "the ship railings around the bridge are going through the screens"). The screens now stand **above** the rail on a stalk **inside** it. Each face starts 1.55 m above the deck (it was 1.0 m), so the frame's bottom (1.39 m) clears the rail's top and lamps (1.27 m). The stalk stands at r 21.07 m, inside the rail's inner face at 21.30 m, with its leaf foot running along the rail. The rail itself is unchanged.
  - **Why this option:** it reads as designed, mission-control boards held over an unbroken railing. Mounting the screens outboard would need deck that is not there. Interrupting the rail would cut and re-bake the painted rail set (bridge_props.glb, at 179,000 of its 180,000 triangles).
  - **Readability is unchanged** (0.284 / 0.342 / 0.349 / 0.291), and every evaluator metric holds.
  - **The new check:** `make monitor-rail-test` tests every monitor triangle (frame, lip, stalk, face quad) against every bridge prop and ship.glb triangle near it, with exact segment-triangle tests. It passes on the new monitors and fails on the old ones. Its control, the clocks monitor pushed into the rail, is caught.
  - **The script:** v2 is `stapledon_bridge_monitors_v2.py` (deterministic). Its master is published.
- **Recorded deviations:**
  - (1) `archive.earths-carrier` unlocks at `first_boost`, not "the first time the signal monitor is on screen at D ≠ 1" (§D7). Unlocks are sim events, and the sim cannot see a monitor's visibility. `first_boost` is when D first leaves 1, so the entry is there by the time the screen shows a shift.
  - (2) `archive.earths-voice`'s frame-diagram line was missing at the first evaluation. It is now in #55 and vendored.
- **OQ12:** `course.ship_years_left` (protocol 2.18 `course` section, core `shipYearsLeft`) is on the course screen.
- **Archive:** `archive.earths-carrier` and spec rows RS-41..RS-47 are in stapledons-design#55. The game vendors that branch (`make lore-import`), and `tests/test_physics.gd` asserts all seven rows. The import also brought in `archive.colours-of-home`, design #51's entry, which was on design main but not yet vendored here; its missing README row is fixed in #55. The codex, the minimum-path unlocks and the session-audit mirrors now list 15 entries and 12 unlocks.
- **Bench:** `make bench SCENE=bridge` measured MISS under host load 24–31 (other agents' jobs). An A/B run without the monitors also missed: p99 31.6 ms without against 34.1 ms with, p50 9.90 against 9.96 ms. The absolute gate needs a quiet machine. The review's gating fix lowers the off-screen cost further.

## Deliverables

- **Revision 2 mock-ups** (`gs://stapledons-voyage-assets/refs/comms_v2/r2/`, index at `index.html`):
  - the wall in the Bow view: `wall_bow_cruise_spawn.png`, `wall_bow_rest_spawn.png`, `wall_bow_cruise_chair.png`, `wall_bow_cruise_comms.png`, `wall_bow_cruise_middeck.png`, `wall_bow_cruise_crew.png`;
  - the wall elsewhere: `wall_astern_cruise_spawn.png`, `wall_review.png`, `wall_plan_labelled.png`;
  - readability at 1440p: `wall_hires_bow_cruise_chair.png`, `wall_hires_signal_crop.png`;
  - the faces: `screen_signal_homeward.png`, `screen_signal_outbound.png`, `screen_signal_off_ray.png`, `screen_clocks_homeward.png`, `screen_course_homeward.png`, `screen_crew_homeward.png`;
  - the frame diagram: `detail_frame_outbound.png`, `detail_frame_homeward.png`;
  - the alternatives: `alt_F_on_walk_bow_cruise_spawn.png`, `alt_W_port_wing_bow_cruise_spawn.png`, `alt_W_port_wing_bow_cruise_chair.png`;
  - `monitors_probe.json`.
- **Revision 1 mock-ups** (`refs/comms_v2/`): the station, the history wall, the waterfall rates, the console spots.
- **This doc,** the sprint plan `comms-station-v2-sprint.md` and `.ailang/state/sprints/sprint_R3-COMMS-V2.json`, all awaiting Mark.
