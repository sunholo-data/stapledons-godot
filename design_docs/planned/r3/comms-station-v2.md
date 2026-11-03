# R3-COMMS-V2: the comms station v2 and the bridge as mission control

**Status:** Revision 2, 2026-11-03, **awaiting Mark** (approve the mock-ups first, then the open questions). Design and mock-ups only; nothing is built. Execution waits for Mark's approval and for open PRs #374 (R3-TRUE-PROCESSED: `ui/earth_feed.gd`, `data/ui/comms_feed.json`), #375 (R2-SOUND S2: `audio/*`, `data/audio/*`, the exact home beacon) and #377 (AILANG v0.56.0) to land, because the sub-milestones edit files those PRs hold.

**Revision history:**
- **Revision 1 (2026-11-02)** proposed the feed history, the console move and a waterfall at the station.
- **Revision 2 (2026-11-03)** follows two rulings by Mark on that draft (PR #379):
  - **Where the signal shows (the old OQ6, "cv2_where"), answered.** "the spectrum band I thought we could see as a display in the bridge itself, without needing to go to a console - its a readout on the controls we can see as we walk about - a new console perhaps that functions as a 'scanner' or TV monitor screen. We could do with more of those around to build up the bridge to be more like a mission control center, and when we go to the console we get the detail view." This revision adds **ambient bridge monitors** (§D3), a **mission-control set** of them (§D4) and their **placement** (§D5). The console keeps the detail view.
  - **The history wall, settled.** Mark likes it ("it's educational"). Clicking a picture shows the relative positions of Earth, the ship and the signal: the **frame diagram** (§D1.6). The received-frame record gains the send and arrival events it needs.
  - Every other open question stays open, each with its recommendation (§Open questions).

**Release:** R3 (Signals and Contact). It follows up R3-EARTH-LINK's comms station (S1, K1, F6; [earth-link.md](../../implemented/r3/earth-link.md) EL3b). It is also the first instance of the "deck layout after camera" work (bridge furniture placed for the fixed views).
**Priority:** P2. It deepens the crew's window home, and the bridge starts to read as a place where a voyage is run.
**Origin:** Mark, attended 2026-11-02 and 2026-11-03 (above).

**Mock-ups (the main deliverable; Mark approves these before anything is built):** throwaway renders from the real game and the real sim (protocol 2.16, seed 7). Their scripts lived in the scratch directory and are not committed.
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

**Estimated LOC:** about 2,150. Sim and protocol 440, the history wall and the frame diagram 580, the waterfall 300, the monitors and their four faces 480, the console move 120 (plus regenerated GLBs and one new Blender prop), tests and captures 230. Revision 1 was 1,450.

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
- G2. **The frame diagram.** Selecting a week shows where Earth was when it sent it, the light's path at c, where the ship was when it arrived and where it was when Earth sent it, the ship's track, and D at arrival. Every value comes from the received-frame record (protocol 2.17).
- G3. **Ambient bridge monitors:** a new class of furniture, readable from the walk and the fixed views with no interaction.
  - The first is the **signal from home** (the waterfall, True, with the Receiver's 400 Hz line and the ×D bracket).
  - Three more (§D4) make the bridge read as mission control.
- G4. **Placement measured.** Each monitor's readability is scored over every walk sample through the real Bow and Astern poses. Every bow-evaluator threshold holds.
- G5. **The comms console moved** to face the bow beside the Voyage console (spot A, OQ1). The monitors reconcile with it: the signal screen is visible from the chair, so the console is for detail.
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

**D1.2 Protocol 2.17.** `earth_log` goes in full states (oldest first) and `earth_log_tail` on ticks where the newest record changed. Both are sent at minor ≥ 17 only, and never inside a black hole's scenario. The bridge stores records by `from_frame`. A record:

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

### D2. The comms console, moved closer

Revision 1's analysis stands. Eight spots were scored in-engine; every bridge metric held at every spot. The table and pictures are in [revision 1](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/console_plan_compare.png) and [`console_probe.json`](https://storage.googleapis.com/stapledons-voyage-assets/refs/comms_v2/console_probe.json).

| Spot | Ship m | Chair → comms walked | Faces bow | Zoom frames the pole |
|---|---|---|---|---|
| Today | (−13.2, −3.0) | 17.1 m | no (faces the rim) | no |
| **A (recommended)** | (−11.0, 8.0) | 9.9 m | yes | yes |
| B | (−5.6, 7.0) | 5.8 m | yes | yes |

**Reconciled with the monitors.** With the signal on the front wall, the captain no longer walks to comms to see the signal, only for the detail. The move still matters:
- The station faces the rim today and misses the forward sky.
- At spot A it sits under the wall's port pair (clocks and signal). From the comms operator's place both are readable (59 px and 48 px tall at 720p, §D5).
- That makes the port wing the "Earth" corner: Voyage console, comms desk, Earth's clock and Earth's signal.

OQ1 keeps A as the recommendation and adds C (leave it where it is) as an option the monitors make viable. The build steps are those of revision 1, CV4.

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

**Three layouts scored** in-engine on the shipped deck (comms at spot A):
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
- **Unlock:** the first time the signal monitor is on screen at D ≠ 1.

`archive.earths-voice` gains one line on the frame diagram: "every picture from home is a ray of light that left Earth and caught you".

## Acceptance criteria

| # | Criterion | Check (command) |
|---|---|---|
| AC1 | The log: one record per ship day, merged by `beamed` and `day`; contiguous frames; the bound on a 30-ship-year synthetic voyage; departure week 0; mutants killed | `ailang test --package sim` and `ailang check --package sim` |
| AC2 | Nothing from the future: every record's `to_frame ≤ frameOf(newest_light_t)`, `arrived.tau ≤ clock.tau`; `earth_weeks` clipped | `make comms-log-test` (new; VM and interpreter) |
| AC3 | The diagram's events are exact: `sent.t = arrived.t − arrived.ly` to 1e-12; `ship_at_sent.t ≤ sent.t` and it is the newest such record; `arrived.rate` equals that tick's `earth.rate` | `make comms-log-test` |
| AC4 | Pure and deterministic: strict VM; VM = interpreter on a 2.17 voyage; the new replay case byte-identical; every 2.16 golden unchanged | `make strict parity replay replay-compat` |
| AC5 | The filmstrip covers every received week; static over unbeamed spans; every digit bound to `earth_log` | `make comms-station-test display-audit-comms` |
| AC6 | The frame diagram draws only record fields (send, light, arrival, ship then, track, ×D); light at 45° (equal axes); selecting and deselecting returns the strip | `make comms-station-test` (new diagram checks, binding audit) |
| AC7 | The waterfall: measured peak within 1 % of 400·D at D 0.070888, 1, 14.107; dark with "above hearing" at D 60 and 1414.2; source guard | `make comms-waterfall-test` (new) |
| AC8 | The monitors: four faces, every number bound (audit), visibility-gated refresh; wall R's readability ≥ the thresholds; the evaluator unchanged otherwise; a seeded on-walk monitor fails | `make bridge-monitors-test deck-layout-eval deck-layout-eval-test` |
| AC9 | The console at the approved spot: five stations face the bow; chair → comms ≤ 10.5 m (A) | `make deck-layout-eval comms-walk-test levels-regress deck-assets-check` |
| AC10 | Performance: the bridge with four live monitors | `make bench SCENE=bridge` (p99 < 16.7 ms at 2560 × 1440 on a quiet rig) |
| AC11 | Archive check values asserted | `godot --headless --path . --script tests/test_physics.gd`, `make lore-values codex-test` |
| AC12 | Review renders from the real sim (the wall from the walk and the fixed views, the faces at three moments, the frame diagram outbound and homebound, the console at its spot), opened and uploaded | `make capture-comms-v2` (GPU window) |
| AC13 | Gates and the rig | `make ui-theme-check python-guard uid-guard`, then `tools/rig_check.sh <PR> --golden` (`rig/full` green) |

## Sub-milestones and estimates

| ID | What | LOC | Depends on | Order |
|---|---|---|---|---|
| CV0 | Rebase after #374, #375, #377; baseline captures | 0 | the three PRs | first |
| CV1 | Sim: the log with send and arrival events, `noteLight`, protocol 2.17 `earth_log`, `earth_log_tail`, `earth_weeks`; `journey.ship_years_left` if OQ12; tests, strict, parity, replay | 440 | CV0 | 1 |
| CV2 | Bridge storage; the filmstrip; the frame diagram (the strip in frame mode, plus the plan inset); the station layout | 580 | CV1 | 2 |
| CV3 | The waterfall: the `Antenna` and `Carrier` taps, `ui/comms_waterfall.gd` (detail) and its bold face for the monitor | 300 | CV0 (#375) | parallel |
| CV4 | Console move (layout, walk bake, Blender, manifest, evaluator to five stations) | 120 + GLBs | CV0, OQ1 | parallel |
| CV6 | The monitor wall: the Blender `bridge_monitor` prop in CV4's generator run, the manifest `monitors`, `BridgeMonitor`, four faces, `monitor` occluders, the readability metric, bench | 480 + prop | CV3, CV4, OQ8–OQ11 | 3 |
| CV5 | Archive and spec rows; review captures; **pause for Mark**; evaluation by the other family; rig; landing | 230 | all | last |

**Duration:** about 7 to 8 attended days at about 300 counted LOC a day, plus the Blender prop, the rig's `rig/full` and Mark's reviews (after CV4+CV6, after CV5). Revision 1 was 5 days.

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

Settled in revision 2: **where the signal shows** (the old OQ6, "cv2_where": an ambient monitor plus the console's detail) and **the history-wall click diagram** (§D1.6). Every other question is open, each with its recommendation.

1. **OQ1, where the comms console goes.**
   - A, the port wing beside the Voyage console (9.9 m from the chair, faces the bow, under the wall's clocks and signal).
   - B, inboard at the chair's shoulder (5.8 m, puts a desk on the open stage).
   - C, leave it where it is (the monitors now carry the glance, but it still faces the rim).
   - **Recommend A.**
2. **OQ2, the wall's axis.** **Recommend ship time** (the spacing is the Earth-rate history). The alternative is Earth time.
3. **OQ3, out-of-beam light.** **Recommend static on the film.**
4. **OQ4, what the waterfall hears.** **Recommend the whole signal** (the True beacon and the week's bed) on the silent tap whenever in beam and on screen, with the bracket measured on the carrier alone.
5. **OQ5, the carrier beyond hearing.** **Recommend True only** (dark band and arrow). A labelled Processed wideband view can come later as its own design.
6. **OQ7, record precision.** **Recommend one record per ship day** (the bound; the stamps' precision; `ship_at_sent` at that resolution).
7. **OQ8, the screen set (new).** **Recommend the four:** signal, Earth vs ship clocks, course, crew. The strip folds into the signal screen and the console. Dust and exposure come later.
8. **OQ9, placement (new).** **Recommend wall R** on the bow rail outside the walk. W (a port-wing triptych) and F (on the rim walk) both failed the evaluator as tried.
9. **OQ10, a stern repeater (new).** One screen at the stern rail repeating the signal for the Astern view (Earth is astern when flying out). **Recommend not in this sprint;** it belongs to the deck-layout-after-camera pass.
10. **OQ11, the screens' look (new).** **Recommend Blender-authored grown frames** (D-104) in the same generator run as the console move. Plain boxes are used only in the dev-build review before art.
11. **OQ12, remaining ship time on the course screen (new).** **Recommend adding `journey.ship_years_left` to the sim** (one field). Otherwise the screen shows only the Earth year at arrival and γ, as in the mock-up; computing it in Godot would break D-21.

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
