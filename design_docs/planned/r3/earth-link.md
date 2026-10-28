# R3-EARTH-LINK: Earth's signal, the live Earth rate, the comms station and Earth's beams

**Status:** Planned 2026-10-27; approved by Mark 2026-10-28 (OQ1–OQ5 as recommended). In progress.
**Release:** R3 (Signals and Contact), the roadmap's first step: milestones **S1**, **K1** and **F6**.
**Priority:** P1. It makes home the ship's anchor from the first leg, and every later R3 track (evidence, finder, contact) builds on its light cone.
**Origin:** Mark, attended 2026-10-27: "it will be crazy to receive updates from earth at different rates according to distance and speed traveling towards or away"; "it's only straight lines - so as soon as we change course the signal will be lost unless we say where we are going"; "we could then have a map graphic showing which direction earth is sending its signals as far as we know, and where they will point, I guess an important anchor for the ship." R3 approved the same day (stapledons-design #42).

**Implements** (design repo):
- [roadmap/r3-signals-and-contact.md](https://github.com/sunholo-data/stapledons-design/blob/main/roadmap/r3-signals-and-contact.md): rows S1, K1 and F6, and order-of-work step 1.
- [signals-and-instruments.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/signals-and-instruments.md):
  - §2 (the light cone);
  - §3 (Earth's signal, the Earth rate);
  - §3.1 (Earth's link, strictly: how it fails, the triangle excess);
  - ACs 1–2;
  - decision 3 (reception at any speed).
- [contact-console.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/contact-console.md) §1: the console's Listen and Exchange-log panes, Earth only.
- [destination-finder.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/destination-finder.md) §8 (Earth's beams on the map) and AC 7.
- design-decisions 2026-10-27, "Earth Aims Only at Plans It Has Heard" (the beam geometry) and "R3 Approved" (reception at any speed).
- **Physics spec:** `physics/relativity-spec.md` §2, row "Light cone and Earth's link", check values **RS-26 to RS-37** (stapledons-design branch `fix/catch-up-times`, merged before this sprint executes).
- Ledger (`design_docs/stapledon-mission.md`):
  - D-11 (only light crosses the wall);
  - D-15 (top speed 0.999999c);
  - D-21 (numbers on screen only from sim fields);
  - D-68 (never show what the ship cannot know).

**Depends on:**
- `sim/consequence.ail` `clocks` (the M4.4 news epoch, Sol at the origin, c = 1), which this generalises without changing its outputs.
- `sunholo/relativity` 0.12.0 `optics.doppler(n, heading, φ)` = γ(1 + β cos θ): the Earth rate is this factor for Sol's direction. No new Doppler formula.
- Protocol 2.15 (`archiveMinor`), the newest minor on main. This design takes **2.16**.
- The bridge's spare console `reserved_2` (`demos/ship_consoles.gd:37`, mesh `console_decision_2`, inactive today).
- The sound plan's home beacon (R2-SOUND OQ6, amended 2026-10-27), which waits for this design's `earth.rate` and `earth.in_beam`.

**Estimated LOC:** about 1,350 (the milestone table), plus renders.

## Game vision alignment

Scored with the `game-vision-designer` skill (feature-validation mode, against `vision/core-pillars.md`), 2026-10-27. **ALIGNED.**

| Pillar | Score | Rationale |
|---|---|---|
| Choices Are Final | +1 | A change of plan has a physical cost at home: the photons already aimed at the old plan are lost, and the new port waits for Earth's beam. The map shows the cost (the link window) before a commit, as the commit dialog already shows Earth years; it never previews an outcome |
| The Game Doesn't Judge | +1 | Silence is reported as a fact with its age ("no Earth light since 2731"), never as a failure |
| Time Has Emotional Weight | +2 | The core of it. Home's history plays aboard at the Earth rate: nearly frozen outbound at the top speed, a trickle at 0.99c, real time at a stop, fast-forward on the way home |
| The Ship Is Home | +1 | Earth's beams are the ship's anchor on the map, and the comms station is a place on the bridge where the crew listen for home. Crew reactions come later (K-track) |
| Grounded Strangeness | +2 | Strict light travel: the light cone, Doppler from the package, the triangle excess, pinned to RS-26..35. Nothing reaches the ship faster than light, and nothing is assumed about where Earth aims except the plans it has heard |
| We Are Not Built For This | +1 | "An hour of broadcast takes two months to arrive": the ship outruns its own news |
| **Net** | **+8** | **Go.** No pillar is negative. Risk to pillar 1: the link-window preview must stay a cost, not an outcome (AC12) |

## Problem

- **The light cone handles Sol only.** `sim/consequence.ail:29` `clocks(t, τ, p)` computes the news epoch as t − |p|, with Sol fixed at the origin. Nothing else in the sim asks what a source looked like when its light left. Every later R3 track (evidence, finder, hindsight) needs one function that does.
- **There is no Earth rate.**
  - The only Doppler value the sim exposes is `pass.d_at_pass` (`sim/navigation.ail:298`).
  - The wire carries β, 1 − β and γ, but not the rate at which Earth's history plays aboard.
  - The news panel shows how old the news is, never how fast it is arriving.
- **Earth's link is unconditional today.**
  - The ship hears Earth on every leg, wherever it goes.
  - Nothing records that the ship told Earth its plan, or when Earth heard it.
  - Nothing models Earth still aiming at a port the ship has left.

  This breaks the 2026-10-27 ruling, "Earth aims only at plans it has heard".
- **There is no comms station.** The bridge has two spare consoles (`reserved_2`, `reserved_3`), inactive.
- **The map does not show home's reach.** `ui/galaxy_map.gd` draws Sol, the route and the ship, but not where Earth's light is pointed.

## Goals and non-goals

**Goals:**
1. **The light cone, as a package function.** It is pure and deterministic, and the news epoch on the shipped α Cen plan stays byte-identical (t_e = 0.043984 yr).
2. **The Earth link in the sim:**
   - the ship sends its plan home at every commit;
   - Earth hears it a light time later and beams along the line to the port;
   - the ship is in Earth's beam, or not, by geometry alone;
   - the Earth rate D is a live value on every tick.
3. **A comms station** on the bridge, with two panes:
   - Listen: Earth's newest light, its age, the Earth rate, the in-beam state and the next link window;
   - Exchange log: the plans sent home, and when Earth hears each one.
4. **Earth's beams on the galaxy map:**
   - heard beams;
   - plans still in flight to Earth;
   - stale beams still aimed at ports the ship has left;
   - the link window at the current or planned port;
   - silence.
5. **Gate 2 met:** spec check values in `tests/test_physics.gd`, a golden, and renders that Mark has looked at.

**Non-goals (later R3 milestones):**
- Link budgets, SNR and the fraction of the signal the receivers can recover (S2, `sunholo/observe` budgets).
- Bands, the receiver comb and the carrier's wavelength readout (S2). Here the Listen pane shows the rate D only, at every speed, with no cut-off (decision 3).
- Earth falling silent through its own fate. In this sprint Earth always transmits; the sim carries `earth.sending` so the fate design can switch it later.
- The homecoming torrent as playback (signals decision 4), the home beacon's sound (R2-SOUND S2), other worlds' signals, and messages with content (crew-work W4 "Record messages home").
- Multi-leg itineraries. The sim holds one leg at a time; a plan is the leg being committed.

## Design

### EL1. The light cone and link geometry, package first (`sunholo/observe` 0.1.0)

The roadmap names `sunholo/observe` for S2's budgets. This design creates it now, with only the geometry. S2 adds the budgets as 0.2.0. Doppler stays in `sunholo/relativity` and is imported.

Let c = 1, with positions in light-years and times in years in the galaxy frame:

| Function | Meaning | Check |
|---|---|---|
| `seenAt(t, obs, src) -> float` | The emission time of the light from a **static** source reaching `obs` at galaxy time t: t − \|obs − src\| | α Cen news epoch 0.043984 (M4.4 AC1) |
| `catchUp(delta, oneMinusBeta) -> float` | The galaxy time after departure at which a signal sent `delta` after departure reaches a ship on a straight outbound cruise: delta / (1 − β). The caller passes 1 − β from `kinematics.oneMinusBeta`; it is never computed | RS-31 10 days, RS-32 2,737.9 yr |
| `triangleExcess(a, b) -> float` | The pure geometry, with Sol at the origin: \|a\| + \|b\| − \|b − a\|. It is ≥ 0, and 0 only when b lies on the far side of Sol from a | RS-33 60, RS-34 8.769, RS-35 0 (b opposite a through Sol) |
| `onBeamLine(port, p, angTol) -> bool` | p lies on the **ray** from Sol through `port` (Sol excluded; the far side of Sol is not on it): p · port > 0 and atan2(|p × port|, p · port) ≤ angTol. The atan2 form keeps full precision at angTol ≈ 1e-7 rad, where a cosine test (cos ≥ 1 − 5e-15) runs into float64 resolution | RS-36 (a point beyond the port and a point between Sol and the port are on it; the opposite point is not) |
| `linkWindow(a, b, legT, covered) -> float` | The wait at b after arrival for Earth's light aimed at the new plan: 0 when `covered` (b on a heard beam's ray), else max(0, \|a\| + \|b\| − legT). `legT` is the leg's galaxy-frame time from the journey core | RS-33 (legT = \|ab\|), RS-37 (covered → 0) |
| `earthRate(pos, heading, phi) -> float` | `relativity.optics.doppler(normalize(−pos), heading, φ)`: Earth-seconds per ship-second. At Sol (\|pos\| < 1e-12 ly) Sol's direction is taken as −heading, so leaving Sol at rate e^(−φ) is continuous and a ship at rest at Sol reads 1 | RS-26..30 (against the closed forms e^(∓φ), not the printed 5 digits) |

Package rules:
- tests are the RS rows;
- a `CHANGELOG`;
- `[release] kind`;
- `ailang pkg quality` with no gates;
- publish (standing approval for sunholo packages), then the sim pins it.

### EL2. The Earth link in the sim (`sim/earth_link.ail`, protocol 2.16)

A pure module with a new record in the World:

```
Message = { planId: int, from: Vec3, port: Vec3, sentT: float, sentTau: float, heardT: float }
Link    = { messages: [Message], sending: bool }
```

What it stores is only the messages. The ship's path comes from the journey core, as today: a commit happens only at rest at a port, and the leg runs straight from `from` to `port`.

- **Sending.**
  - At every commit the ship sends its plan home. The sim appends a `Message`: `sentT` is the commit's galaxy time, and `heardT = sentT + |from|`.
  - A commit from home (inside the Solar System, below) has `heardT = sentT` (the plan Earth had before departure).
- **Earth's aim at emission time t_e.** Earth aims at the plan of the newest message it had heard by t_e (`heardT ≤ t_e`), or nowhere if it had heard none. Each beam covers the ray from Sol through its port (stapledons-design 2026-10-27).
- **In beam.** At galaxy time t and position p, the Earth light reaching the ship left at t_e = t − |p| (`seenAt`). Let m be the newest message with `heardT ≤ t_e`. The ship is **in beam** iff Earth was sending at t_e and one of these holds:
  1. **At home:** inside the Solar System, |p| < 120 AU (`homeRadiusLy`, the heliopause). This includes the hold at Earth before any commit. Amended in EL3 (see "Home is the Solar System" below): the plan had |p| < 1e-12 ly, at Sol itself, but the voyage starts at Earth, 1 AU from the origin.
  2. **On the heard plan:** the ship's current leg is m's plan (`planId` equal) and that leg is committed or arrived. A plan that is only planned, not committed, never counts. Earth aims at the ship's predicted position on it. Cases 2 and 3 can both hold; either is enough.
  3. **On the heard beam's ray:** `onBeamLine(m.port, p, angTol)`. This covers a stop beyond m's port or between it and Sol.

  Otherwise the ship is out of beam: no message heard yet, or the ship is off the heard plan and off its ray. After a re-plan at A, the ship is therefore out of beam from the moment it leaves A's ray. That lasts through the transit, unless the leg is slow enough that t − |p| reaches the new `heardT` first. It ends when t − |p| ≥ `heardT` of the new message.
- **The link window at a port** (for a committed or planned leg from port A to port B, committed at galaxy time t₀): `wait_years = linkWindow(A, B, T, covered)`.
  - Earth's light for the new plan first reaches B at `heardT + |B|` = t₀ + |A| + |B|. The ship arrives at t₀ + T, where T ≥ |AB| is the leg's galaxy-frame time from the journey core.
  - Uncovered: `wait_years` = max(0, |A| + |B| − T). This is the triangle excess when T ≈ |AB| (high γ), and less on a slow leg.
  - `covered` = `onBeamLine(prevPort, B)`, where `prevPort` is the port of the newest message Earth had heard at commit time t₀ (the plan the ship is leaving). That is the beam Earth keeps aiming until it hears the new plan. Not the plan Earth aims at when the ship arrives: by then Earth has normally heard the new plan (`heardT` = t₀ + |A| comes before arrival), which would make every B look covered. When covered, `wait_years` is 0. The AC4 fixture's right-angle B must come out uncovered.
- **The preview** (a planned, uncommitted leg): the sim computes the same `linkWindow` for `journey.plan` and the stale beam the commit would create, and sends them as `earth.preview`. GDScript does no arithmetic on it.
  - The preview is a cost, like the commit dialog's Earth years: it uses the leg's T, which the dialog already shows.
  - It never carries any state of Earth or of the ship after the commit (pillar 1).
- **Stale beams.**
  - Until Earth hears a new plan, it keeps aiming at the old port. These are the photons the ship loses, exactly the ones aimed at a plan it abandoned.
  - The sim reports each stale beam with the galaxy time Earth stops aiming it (`heardT` of the next message).
- **The Earth rate.** `earthRate(position, heading, φ)` on every tick: 1 at rest; below 1 receding; above 1 approaching.
- **The news epoch is unchanged.** `consequence.clocks` calls `seenAt` and gives byte-identical results; M4.4 AC1 stays pinned.
- **Home is the Solar System (amended in EL3, 2026-10-28).** The light cone puts Earth at the origin, but the game starts the ship at Earth, 1 AU out (8.3 light-minutes), and the EL2 fixtures started it at the origin. Running the comms station in the game showed two faults:
  - before the first commit the ship read "out of beam, off the beam line", because the old case 1 (|p| < 1e-12 ly) never holds at Earth;
  - on a first leg from Earth near c, the light reaching the ship is older, measured from Sol, than the plan by up to 8.3 minutes, and t − |p| stays below `heardT` for years. At 0.999999c it gains only (1 − β) per year, so the ship read out of beam on its own first leg for about 15 years.

  The fix, in `sim/earth_link.ail`:
  - **at home** is |p| < 120 AU, the heliopause (Voyager 1 crossed it at 121.6 AU in 2012, Voyager 2 at 119 AU in 2018). Inside it Earth tracks the ship directly, as the Deep Space Network tracks the Voyagers;
  - a plan made at home is heard at once, and its leg is **covered** (no wait, no stale beam);
  - its beam is carried by Earth light from `beamFrom = sentT − |from|` (the earliest Sol-centred emission time of light from Earth at the commit: the ship riding Earth's own light outward). Every other message's beam starts at `heardT`.

  Stars are tens of light-years out, so nothing else moves. Checked by `checkHomeStart` in `earth_link_test.ail`, with mutants of both rules caught.

**Wire, 2.16, gated by `earthMinor()`.** The `earth` section:

| Field | Value |
|---|---|
| `rate` | D, float64 |
| `newest_light_t` | t_e, galaxy time |
| `rate_inverse` | 1 / D, ship-seconds per Earth-second (EL3: the "one Earth day every …" phrase) |
| `newest_light_year` | params.epoch + t_e, the Earth clock (the game's epoch is 0, so this reads as the HUD's "Earth +t"; every `*_year` below is the same) |
| `light_age_years` | \|p\| |
| `at_home` | inside the Solar System (EL3) |
| `in_beam` | in-beam state |
| `sending` | Earth is transmitting (true throughout this sprint) |
| `last_beam_t`, `last_beam_year` | when the newest beamed Earth light the ship received left Sol: the silence line (EL3; noted every tick in beam) |
| `out` | `{reason, port_id, due_t, due_year, due_in_years}` or null in beam (EL3): `silent`, `not_heard` (the newest plan's beam reaches its port at `due_t`, `due_in_years` from now) or `off_line` |
| `beam` | `{port_id, port, heard_t, heard_year}` or null |
| `stale` | `[{port_id, port, until_t, until_year}]` |
| `pending` | `[{port_id, port, sent_t, heard_t, heard_year}]`, plans still in flight to Earth |
| `window` | `{port, from_t, wait_years}` or null, for the committed or arrived leg |
| `preview` | `{port, wait_years, would_stale: {port_id, port, until_t, until_year} or null}` or null, for a planned, uncommitted leg (cost fields only) |
| `messages` | `[{plan_id, port_id, from, port, sent_t, sent_year, sent_tau, heard_t, heard_year, reply_t, reply_year}]`; `reply_t` = heard_t + \|port\|, Earth's reply at the port at the earliest (EL3) |

The minor's other required edits:
- `helloFor`;
- `sessionMinor`;
- `bridge/sim_bridge.gd` `EARTH_MINOR := 16`.

Streams below 2.16 carry no `earth` section and stay byte-identical; the replay goldens hold. Determinism: no Rng, no I/O; `make strict` and `make parity` include `earthLinkVm`.

### EL3. The comms station (K1)

- **The console.**
  - `reserved_2` becomes **Comms** (`STATIONS`, `ACTIONS`, `ui/ship_controls.gd` `CONSOLE`, the HUD's `WALK_TO`), with the existing SubViewport screen and panel pattern (`_build_screens`, `_open_panel`).
  - `reserved_3` stays spare.
- **Listen pane**, Earth only:
  - **Newest Earth light:** Earth's clock in it, and how old it is ("Newest light: Earth at +109.6 days, 4.32 yr old"). The game has no calendar (its epoch is 0), so times read as the HUD's Earth clock. Inside the Solar System: "Earth tracks the ship directly".
  - **The Earth rate, live:** the value of D and a phrase built only from it ("one Earth day every 3.9 ship-years"; "real time"; "two weeks of Earth per ship-day"), with the phrase thresholds in data.
  - **In beam or not**, and the reason when not, from the sim (`earth.out`): "the light reaching the ship left before Earth heard your plan for Proxima Centauri. Earth's beam reaches Proxima Centauri at Earth +12.60 yr, 8.30 yr from now", or "off the beam line".
  - **Silence:** when not in beam, the date of the last Earth light the ship received.
- **Exchange log:**
  - one row per plan sent home: sent (ship-year and galaxy year), heard at Earth (galaxy year), and Earth's reply reaching the port at the earliest (`heard_t + |port|`);
  - outbound messages draw as light-fronts on the map (EL4).
- **Numbers only from the wire** (D-21): every digit on the panes binds to an `earth.*` field. A new target `make display-audit-comms` (beside `display-audit-interlude` and `display-audit-crew`, and a prerequisite of `make test`) audits the new panes.

### EL3b. The comms station, visual (Mark 2026-10-28: "visual first, words last")

Mark on the EL3 panes: "the comms station is boring - this is the connection of the crew to home it should be a wash of images, text, emotions and feelings, and a good visual UI not lots of text". Then: "we can represent the earth updates with a stillness or fast flowing images of a jumbled video feed", and "we can have fun generating images for the feed based off of latest events on earth". That set a standing order (design-decisions 2026-10-28, "Visual First, Words Last"). Visual concept: [the mock-up artifact](https://claude.ai/artifact/EPLHuNZGskXjeeq9ngdtTQ), version 4. EL3's sentence panes stay as the words layer behind a Details tap.

What the player sees at a glance, and feels:

| Element | Shows | Driven by |
|---|---|---|
| **Earth's feed** (the centre, 16:9) | Home as of the newest light, one frame per moment of Earth's history. It plays at the Earth rate: near-still flying away near c, real time at rest, a jumbled torrent turning for home | `earth.feed` (below): the frame key advances with t_e, so the playback rate *is* D times the game's pacing. Godot never computes a rate |
| Doppler tint | The feed warms (receding) or cools (approaching) by the signal's real shift | `earth.rate`, through data thresholds. A stylized indicator, not a spectral render: gate 2 asserts the RS-26..RS-29 D values select the documented tint bands |
| Static and the ring | Out of beam, the last beamed frame (`last_beam_t`) freezes under static. A ring fills until Earth's voice arrives | `earth.in_beam`, `earth.out.due_in_years`, and the window or plan span |
| Live tag, corner clock | "live" inside the Solar System; otherwise the Earth clock in the newest light and its age | `earth.at_home`, `newest_light_year`, `light_age_years` (bound) |
| Twin clocks | The ship's hand and Earth's hand, Earth's turning D times as fast (a blur past a cap) | `earth.rate` |
| The crew at the console | Faces with feelings that follow home and the beam: glad, longing, cut off, waiting, home! | `crew_core` emotions (the R2 medic emotion work). Portrait variants per member and feeling (D-7 sets; today only the medic has them) |
| The exchange as light | A small spacetime strip: Earth's line, the ship's, each plan travelling home at light speed, Earth's reply, the wait at the port | `earth.messages` (sent, heard, reply), `t` and \|p\| |
| Words layer | EL3's panes, unchanged, behind Details | as EL3 |

**The feed's frames are Earth's recent events, at the scale a voyage actually receives.** The light the ship gets spans weeks to a few decades of Earth time in a session (the comms playthrough reaches Earth +8.7 yr), and up to about two centuries on the longest voyages. So a frame is one event in Earth's week, not an era. Mark, 2026-10-28: "those are very far apart eras not what we will use in the game - we are not streaming millions of years". The sim generates the chronicle deterministically, and Godot only shows it.
- `earth.feed = {frame, event, variant, context}`, where `context = {era_tier, era_word, years, heard: [{port_id, heard_t}]}` holds the sim fields a live frame's prompt reads (below):
  - `frame = floor(t_e / feedBinYears)`, with one bin per Earth week;
  - `event` is the chronicle's entry for that week: `mix(seed, frame)` draws a category and an event from `data/feed/events.json`;
  - `variant` picks among the event's pictures.
- Same seed, same feed. The frame key moves with t_e, so the stillness (one week held for days or months aboard) and the torrent (weeks flicking past) are both the physics.
- **The event catalogue** is everyday-to-world Earth news at the scale of weeks to decades:
  - family and friends: a birthday, a wedding, a new baby, a funeral;
  - home and town: seasons, a storm, a festival, a new building;
  - the nation and the world: an election, a treaty, a protest, a record heat year;
  - science and space: a launch, a telescope's first light, a message sent after the ship.

  Over decades the slow drift (the children grow up, the town changes) comes through the catalogue's later rows. It is written in the news voice, never judging (pillar 2), and is consistent with the news templates the Archive reads.
- **Live frames, painted each time the player looks: the main path** (Mark, 2026-10-28: "we can update as we go new images each time a user looks at it, using api keys etc and based on in game events and history in the right era").
  - When the station opens, or while the feed is on screen, the AI lane paints the next few frames for the weeks being received. It uses the player's own keys (the AI indicator, as for the news and the Archive; no key ships in the build).
  - Each frame's prompt is built in the AI lane (`ai/prompt.ail` `feedPrompt`) from sim fields only, carried in `earth.feed.context`:
    - **the week's chronicle event**;
    - **the right era**: Earth years since departure in the newest light, through the home-time ladder's words (`homeTier16` of t_e: launch, seasons, years, decade, decades, generation…). Fashion, technology, faces and the town drift with it: a frame twenty years on shows the niece grown and the street changed;
    - **the voyage as Earth knows it, by the light cone.** These are only the in-game events Earth had heard by t_e: the plans whose `heard_t ≤ t_e` (the ship turned for Sirius A), the ports reached and reported, the crew's names. Earth's pictures never know what Earth could not yet have heard. That is the game's physics showing up in the news.
  - Frames are cached by key (seed, week, event, era), so a revisit replays the same pictures. Every look adds new weeks; a returning player sees the frames already painted.
  - Spend-capped under the AI layer's ceiling (default $0.50, player-set): a few frames per look, never a burst. Images carry no text or digits (prompt rule, as the portraits).
  - When AI is off, the key is missing or a call fails, the frame comes from the shipped library at once, so the feed never waits on the network.
- **The feed is a mix, for variety and to spread the cost** (Mark, 2026-10-28: "we can mix it in with non-ai spend images and text/news/ etc to help spread the cost - variety is good"). Each week's frame has a *kind*, drawn by the sim with the event (`mix(seed, frame)`, shares in `data/feed/mix.json`), so the same voyage always mixes the same way:
  - **painted live** (AI): the minority share, and the only kind that spends;
  - **library pictures** (shipped, free): the event's pictures, so the event still reads as a picture;
  - **news cards** (free): a postcard of the week's news, an image with a few words. The words are the news templates' (or the accepted AI news text) with slots from sim fields, never digits outside a binding;
  - **home snapshots** (free): the crew's own pictures from before departure, a face or a kitchen, shown when the news touches someone they left;
  - **the sky over home** (free, procedural): Earth from the Moon, a launch plume, the town's night lights, drawn from the event's category.

  A painted-live slot that cannot paint (AI off, no key, the spend ceiling reached, a failure) falls back to the library kind, so the mix never stalls. Stillness and torrent apply to every kind alike.
- **The fallback library, generated once and shipped.**
  - About 8 events × 2 variants in each of about 6 categories (about 100 pictures).
  - Generated through the established home-art route: Codex imagegen, the home-tier style reference, no text or digits in frame, every picture inspected at 1:1 (as `data/interlude/home/generation_notes.md`), or through the AI lane's image slot (`gemini-2.5-flash-image`, $0.039 a call, unverified).
  - Pinned by sha256, with masters in the public bucket (D-18), fetched by `make feed-assets`.
  - The home-tier pictures are not feed frames: they summarise whole eras of home time, and stay on the crossing review.

Out of scope here: composing messages home (S-track), voices and audio from Earth (a later sound pass).

### EL4. Earth's beams on the galaxy map (F6)

A new 2D overlay layer `ui/earth_beams.gd`. It follows `ui/ism_layer.gd`'s pattern: `draw(overlay, camera, to_world)`, projected with `unproject_position` and skipped behind the camera.

| Element | Drawn as | From |
|---|---|---|
| Heard beam | a solid line from Sol through its port and beyond (the beam covers the line), with Earth's light-front marked along it at t − heard_t | `earth.beam` |
| Plan in flight to Earth | a dashed line Sol → port, plus the message's light-front crawling back towards Sol, labelled with its arrival year | `earth.pending` |
| Stale beam | a fading line to a port the ship left, labelled "aimed at empty space until 2,467" | `earth.stale` |
| Link window | a bar at the port: green when Earth's light arrives before the ship, otherwise "wait n years to hear Earth" | `earth.window` |
| Silence | the last received light-front, labelled with its age | `earth.newest_light_*` |
| Plan preview | with a destination selected and not yet committed, the dashed line plus that port's `wait_years` and the stale beam the commit would make, all from the sim (no arithmetic in GDScript) | `earth.preview` |

A legend toggle sits on the map's existing filter row, on by default. The colours are from the map palette.

### EL5. Gate 2: check values, a golden, renders

- **`tests/test_physics.gd`** asserts RS-26..RS-37 against the GDScript mirror (`physics/relativity.gd` `doppler`, plus a new `physics/observe.gd` mirror of the package's EL1 functions) and against the sim's `earth.rate` read from a fixture stream.
- **`make golden` gains `G-EL-1`.** No shader is involved, so the golden is the overlay's projected geometry: the endpoints and light-front positions of each beam element at three fixture states. GDScript's projection is compared with a CPU reference computed from the sim fixture to 0.5 px.
- **`make capture-earth-link`** renders the comms station and the map at five sim states:
  - (a) outbound to α Cen at 0.99c, in beam;
  - (b) at the top speed outbound, rate 7.07 × 10⁻⁴;
  - (c) a re-plan at a port 40 ly out with a 30 ly turn, out of beam, wait 60 years;
  - (d) a stale beam;
  - (e) heading home at 0.99c, rate 14.1.

  It produces a contact sheet. Mark opens them before merge.

## Acceptance criteria

Every new test is wired into `make test`, so `rig/full` runs it:
- `earth_link_test.ail` through `make sim`;
- `earthLinkVm` through `make strict` and `make parity`;
- `test_comms_station.gd` and `test_earth_beams.gd` through `make ui`;
- `display-audit-comms` as a new `make test` prerequisite;
- the RS rows through `make physics`.

`G-EL-1` runs in `make golden` (GPU shell, `rig_check.sh --golden`).

| # | Criterion | Command |
|---|---|---|
| AC1 | `sunholo/observe` 0.1.0 published: its tests assert RS-26..RS-37 and the α Cen epoch, and `ailang pkg quality` reports no gates. This runs in the packages clone, so AC1b repeats the values in this repo | `cd packages/observe && ailang test && ailang pkg quality` (ailang-packages clone) |
| AC1b | The sim asserts RS-31..RS-37 through the pinned package (`catchUp`, `triangleExcess`, `onBeamLine`, `linkWindow`) | `make sim` (`earth_link_test.ail`) |
| AC2 | The news epoch on the shipped α Cen plan is unchanged: t_e = 0.043984 yr, and M4.4 AC1 passes | `make sim` (`checkNewsEpoch`) |
| AC3 | The Earth rate matches the closed forms e^(∓φ) to 1e-9 relative at the RS-26..RS-30 speeds, from the sim and from the GDScript mirror. At rest at Sol it reads 1; just after leaving Sol it reads e^(−φ) | `make sim`, `make physics` |
| AC4 | In beam, on a synthetic catalogue: `Target` records built in the test, as `consequence_test.ail`'s `acenAt` does, with A at 40 ly and B 30 ly from A at a right angle. Fly Sol → A with `scriptedLeg` (arriving), then re-commit to B. Asserted: (i) in beam at Sol before any commit, and on every sampled tick of leg 1; (ii) out of beam from the first tick off A's ray, mid-transit, and on arrival; (iii) `wait_years` = \|A\| + \|B\| − T from the leg's T, to 1e-9 yr, and about 60 at the top speed (the RS-33 excess); (iv) back in beam once t − \|p\| ≥ the new `heard_t`, and not one sampled tick before | `make sim` |
| AC5 | Coverage: a re-plan from A to a port beyond A on A's ray, or between Sol and A, has `wait_years` 0, and the ship stays in beam throughout (RS-36, RS-37). A port on the far side of Sol has triangle excess 0 but is not covered: its `wait_years` = max(0, \|A\| + \|B\| − T) (RS-35) | `make sim` |
| AC6 | Stale beams: after a re-plan, the old port's beam is reported with `until_t` = the new message's `heard_t`, then dropped at that time | `make sim` |
| AC7 | Determinism: `earthLinkVm` gives the same result on the strict VM and the interpreter, and the 10k-tick replay at 2.16 is byte-identical on rerun | `make strict`, `make parity`, `make replay` |
| AC8 | Streams below 2.16 are byte-identical to today's goldens, with an assertion run right after the World gains `link`, and a 2.15 session prints no `earth` key | `make replay`, `make sim` |
| AC9 | Every digit on the Listen and Exchange-log panes binds to an `earth.*` field: 0 unbound | `make display-audit-comms` (new target, in `make test`) |
| AC10 | `G-EL-1`: the beam geometry is within 0.5 px of the CPU reference at three fixture states | `make golden` |
| AC11 | The renders of the five states exist, are neither blank nor duplicated, and Mark has looked at them; the review is recorded in the report | `make capture-earth-link`, plus Mark |
| AC12 | The plan preview comes from the sim's `earth.preview`, and the map reads no other `earth.*` field while a plan is uncommitted. The sim asserts that `earth.preview` equals the `earth.window` and `earth.stale` produced by the same plan once committed, and that `preview` has only its three keys | `make sim`, `make ui` (`test_earth_beams.gd`) |
| AC13 | `make test` is green on the rig (`rig/full`, with `--golden`), and the fast tier is green | `tools/rig_check.sh <PR> --golden` |

## Sub-milestones and estimates

| ID | What | LOC | Depends |
|---|---|---|---|
| EL0 | The spec rows RS-26..RS-37 merged in the design repo (done on branch `fix/catch-up-times`) | 0 | — |
| EL1 | `sunholo/observe` 0.1.0: the geometry, the tests, publish; the sim pin | 250 | EL0 |
| EL2 | `sim/earth_link.ail`, the World record, the commit hook, protocol 2.16, the tests, the strict and parity entries, the bridge constant | 400 | EL1 |
| EL3 | The comms station: the console, the Listen and Exchange-log panes, the copy data, `tests/test_comms_station.gd`, display-audit rows | 330 | EL2 |
| EL3b | The visual comms station: `earth.feed` in the sim, the feed with tint, static and ring, twin clocks, the crew's faces, the light strip, the event catalogue and the generated feed library | 650 + art | EL3 |
| EL4 | `ui/earth_beams.gd`, the map toggle, the plan preview, `tests/test_earth_beams.gd` | 270 | EL2 |
| EL5 | `physics/observe.gd` mirror, `test_physics.gd` rows, `G-EL-1`, `make capture-earth-link`, the report | 100 | EL3, EL4 |

EL3 and EL4 are independent once EL2 lands. EL1–EL2 are headless and could go to the loop. EL3–EL5 are visible and stay attended (mission-loop routing).

## Risks and mitigations

- **The beam ray is a thin target.**
  - A 10 m aperture's beam is about 15 AU across at 1,000 ly, so an exact "on the line" test is brittle at float precision.
  - Mitigation: `onBeamLine` takes an angular tolerance from data, set to the beam's physical half-angle (λ/D for the reference 1 µm, 10 m link); the tests cover both sides of it. The journey core flies each leg straight from `from` to `port` (boost, cruise and brake share one heading), so a ship on its plan never drifts off the ray; the in-beam rule tests the plan id first and the ray second.
- **Preview creep against pillar 1.** Showing the link window before a commit could slide into previewing outcomes. AC12 pins the preview to cost fields only.
- **Protocol minor collisions.** An open plan could also claim 2.16. Mitigation: check the free minor at execution time and record it, as R2-HOME-TIERS did.
- **"In beam" on the first leg.** The guided tour starts at Sol with the plan known before departure, so it never shows a gap. The re-plan fixture (AC4) exercises the gap headless; a dev build shows it only on a second leg.

## Archive entries (standing order, Mark 2026-10-28)

The real physics behind this feature, in the in-game Archive (stapledons-design `lore/archive/`, PR #45; imported at `0fedb48`):

| Entry | Unlock | Teaches | Check values |
|---|---|---|---|
| `archive.earths-voice` | `first_commit` | the light cone, the Earth rate astern and ahead, signals that chase a ship, the wait after a turn | RS-26, RS-28, RS-30..RS-33 |
| `archive.following-light` | `cruise_above_0.9c` | how Earth aims at a ship crossing its sky near c: a gentle swing, at most βγ/r, and aiming ahead along the heard course | RS-38..RS-40 |

## Decisions (Mark, attended 2026-10-28)

Mark approved the plan with every recommendation ("please merge in the plan", PR #340).

| # | Question | Decision |
|---|---|---|
| OQ1 | Put the comms station on the spare console `reserved_2` | **Yes**; `reserved_3` stays spare |
| OQ2 | The ship sends its plan home automatically at every commit, shown in the Exchange log; composing content comes later | **Yes, automatic** |
| OQ3 | Earth always transmits in this sprint (`earth.sending` true), with Earth's fate switching it off later | **Yes** |
| OQ4 | Gate 2's golden for a 2D overlay: the projected geometry against a CPU reference, since no shader is involved | **Yes** |
| OQ5 | Create `sunholo/observe` now for the geometry (S2 extends it), rather than putting the light cone in `sunholo/relativity` | **Yes**, as the roadmap names it |

## Deliverables

- `sunholo/observe` 0.1.0 (published), pinned in `sim/`.
- `sim/earth_link.ail`, `sim/earth_link_test.ail`, and protocol 2.16.
- The comms station, `ui/earth_beams.gd`, `physics/observe.gd`, and their tests.
- `G-EL-1` in `make golden`, `make capture-earth-link`, the renders, and `design_docs/implemented/r3/earth-link-report.md` at landing.
- The design repo's R3 roadmap marks S1, K1 and F6 done at landing.
